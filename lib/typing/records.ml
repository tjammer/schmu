open Types
open Typed_tree
open Inference

module type Core = sig
  val convert : Env.t -> Ast.expr -> Typed_tree.typed_expr

  val convert_annot :
    Env.t -> Types.typ option -> Ast.expr -> Typed_tree.typed_expr
end

module type S = sig
  val convert_record :
    Env.t ->
    Ast.loc ->
    Types.typ option ->
    (string * Ast.expr) list ->
    Typed_tree.typed_expr

  val convert_field :
    Env.t ->
    Lexing.position * Lexing.position ->
    Ast.expr ->
    string ->
    Typed_tree.typed_expr

  val convert_field_set :
    Env.t -> Ast.loc -> Ast.expr -> string -> Ast.expr -> Typed_tree.typed_expr
end

let array_assoc_opt name arr =
  let rec inner i =
    if i = Array.length arr then None
    else
      let field = arr.(i) in
      if String.equal field.name name then Some field.typ else inner (i + 1)
  in
  inner 0

let assoc_opti qkey arr =
  let rec aux i =
    if i < Array.length arr then
      let field = arr.(i) in
      if String.equal qkey field.name then Some (i, field) else aux (i + 1)
    else None
  in
  aux 0

let get_record_type env loc labels annot =
  match annot with
  | Some t -> t
  | None -> (
      let labelset = List.map fst labels in
      match Env.find_labelset_opt labelset env with
      | Some t -> instantiate t
      | None -> (
          (* There is a wrong label somewhere. We get the type of the first label and let
             it fail below.
             The list can never be empty due to the grammar *)
          match Env.find_label_opt (List.hd labels |> fst) env with
          | Some t -> Env.query_type ~instantiate t.typename env
          | None ->
              let msg =
                Printf.sprintf "Cannot find record with label %s"
                  (List.hd labels |> fst)
              in
              raise (Error (loc, msg))))

module Make (C : Core) = struct
  open C

  let rec convert_record env loc annot labels =
    let raise_ msg lname rname =
      let msg = Printf.sprintf "%s field %s on record %s" msg lname rname in
      raise (Error (loc, msg))
    in

    let t = get_record_type env loc labels annot in

    let (param, name, labels), labels_expr =
      match t with
      | Trecord (param, name, ls) ->
          let f (lname, expr) =
            let typ, expr =
              match array_assoc_opt lname ls with
              | None -> raise_ "Unbound" lname name
              | Some (Tvar { contents = Unbound _ } as typ) ->
                  (* If the variable is generic, we figure the type out normally
                     and then unify for the later fields *)
                  (typ, convert_annot env None expr)
              | Some (Tvar { contents = Link typ })
              | Some (Talias (_, typ))
              | Some typ ->
                  (typ, convert_annot env (Some typ) expr)
            in
            unify (loc, "In record expression:") typ expr.typ;
            (lname, expr)
          in
          let labels_expr = List.map f labels in
          ((param, name, ls), labels_expr)
      | t ->
          let msg = "Expected a record type, not " ^ string_of_type t in
          raise (Error (loc, msg))
    in

    (* We sort the labels to appear in the defined order *)
    let is_const, sorted_labels =
      List.fold_left_map
        (fun is_const field ->
          let expr =
            match List.assoc_opt field.name labels_expr with
            | Some thing -> thing
            | None -> raise_ "Missing" field.name name
          in
          (* Records with mutable fields cannot be const *)
          (is_const && (not field.mut) && expr.is_const, (field.name, expr)))
        true (labels |> Array.to_list)
    in
    let typ = Trecord (param, name, labels) |> generalize in
    Env.maybe_add_type_instance typ env;
    { typ; expr = Record sorted_labels; is_const }

  and get_field env loc expr id =
    let expr = convert env expr in
    match clean expr.typ with
    | Trecord (_, name, labels) -> (
        match assoc_opti id labels with
        | Some (index, field) -> (field, expr, index)
        | None ->
            raise (Error (loc, "Unbound field " ^ id ^ " on record " ^ name)))
    | t -> (
        match Env.find_label_opt id env with
        | Some { index; typename } -> (
            let record_t = Env.find_type typename env |> instantiate in
            unify
              (loc, "Field access of record " ^ string_of_type record_t ^ ":")
              record_t t;
            match record_t with
            | Trecord (_, _, labels) -> (labels.(index), expr, index)
            | _ -> failwith "nope")
        | None -> raise (Error (loc, "Unbound field " ^ id)))

  and convert_field env loc expr id =
    let field, expr, index = get_field env loc expr id in
    { typ = field.typ; expr = Field (expr, index); is_const = expr.is_const }

  and convert_field_set env loc expr id value =
    let field, expr, index = get_field env loc expr id in
    let valexpr = convert env value in

    (if not field.mut then
     let msg = Printf.sprintf "Cannot mutate non-mutable field %s" field.name in
     raise (Error (loc, msg)));
    unify (loc, "Mutate field " ^ field.name ^ ":") field.typ valexpr.typ;
    { typ = Tunit; expr = Field_set (expr, index, valexpr); is_const = false }
end
