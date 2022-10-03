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

  val convert_record_update :
    Env.t ->
    Ast.loc ->
    Types.typ option ->
    Ast.loc * string ->
    (string * Ast.expr) list ->
    Typed_tree.typed_expr

  val convert_field :
    Env.t ->
    Lexing.position * Lexing.position ->
    Ast.expr ->
    string ->
    Typed_tree.typed_expr

  val get_record_type :
    Env.t -> Ast.loc -> string list -> Types.typ option -> Types.typ
end

let array_assoc_opt name arr =
  let rec inner i =
    if i = Array.length arr then None
    else
      let field = arr.(i) in
      if String.equal field.fname name then Some field.ftyp else inner (i + 1)
  in
  inner 0

let assoc_opti qkey arr =
  let rec aux i =
    if i < Array.length arr then
      let field = arr.(i) in
      if String.equal qkey field.fname then Some (i, field) else aux (i + 1)
    else None
  in
  aux 0

module Make (C : Core) = struct
  open C

  let get_record_type env loc labelset annot =
    match annot with
    | Some t -> t
    | None -> (
        match Env.find_labelset_opt labelset env with
        | Some t -> instantiate t
        | None -> (
            (* There is a wrong label somewhere. We get the type of the first label and let
               it fail below.
               The list can never be empty due to the grammar *)
            match Env.find_label_opt (List.hd labelset) env with
            | Some t -> Env.query_type ~instantiate t.typename env
            | None ->
                let msg =
                  Printf.sprintf "Cannot find record with label %s"
                    (List.hd labelset)
                in
                raise (Error (loc, msg))))

  let rec convert_record env loc annot labels =
    let raise_ msg lname rname =
      let msg = Printf.sprintf "%s field :%s on record %s" msg lname rname in
      raise (Error (loc, msg))
    in

    let labelset = List.map fst labels in
    let t = get_record_type env loc labelset annot in

    let (param, name, labels), labels_expr =
      match t with
      | Trecord (param, Some name, ls) ->
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
    let const, sorted_labels =
      List.fold_left_map
        (fun is_const field ->
          let expr =
            match List.assoc_opt field.fname labels_expr with
            | Some thing -> thing
            | None -> raise_ "Missing" field.fname name
          in
          (* Records with mutable fields cannot be const *)
          (is_const && (not field.mut) && expr.attr.const, (field.fname, expr)))
        true (labels |> Array.to_list)
    in
    let typ = Trecord (param, Some name, labels) |> generalize in
    { typ; expr = Record sorted_labels; attr = { no_attr with const } }

  and convert_record_update env loc annot (rloc, rid) items =
    (* Implemented in terms of [convert_record] *)
    let record_var = Ast.Var (rloc, rid) in
    let record = convert env record_var in

    let updated = List.to_seq items |> Smap.of_seq in

    let all_new = ref true in
    let fields =
      match record.typ with
      | Trecord (_, _, fields) ->
          Array.map
            (fun field ->
              match Smap.find_opt field.fname updated with
              | Some expr -> (field.fname, expr)
              | None ->
                  (* There are some old fields. *)
                  all_new := false;
                  let expr = Ast.Field (loc, record_var, field.fname) in
                  (field.fname, expr))
            fields
      | t ->
          let msg = "Expected a record type, not " ^ string_of_type t in
          raise (Error (loc, msg))
    in

    if !all_new then
      raise
        (Error
           (loc, "All fields are explicitely updated. Record update is useless"));

    convert_record env loc annot (Array.to_list fields)

  and get_field env loc expr id =
    let expr = convert env expr in
    match clean expr.typ with
    | Trecord (_, name, labels) -> (
        match assoc_opti id labels with
        | Some (index, field) -> (field, expr, index)
        | None ->
            let name =
              match name with
              | Some n -> "record " ^ n
              | None -> Printf.sprintf "tuple of size %i" (Array.length labels)
            in
            raise (Error (loc, "Unbound field :" ^ id ^ " on " ^ name)))
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
        | None -> raise (Error (loc, "Unbound field :" ^ id)))

  and convert_field env loc expr id =
    let field, expr, index = get_field env loc expr id in
    {
      typ = field.ftyp;
      expr = Field (expr, index);
      attr = { no_attr with const = expr.attr.const; mut = field.mut };
    }
end
