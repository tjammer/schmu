open Types
open Typed_tree
open Inference
open Error

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
    (Ast.ident * Ast.expr) list ->
    Typed_tree.typed_expr

  val convert_record_update :
    Env.t ->
    Ast.loc ->
    Types.typ option ->
    Ast.expr ->
    (Ast.ident * Ast.expr) list ->
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
        match Env.find_labelset_opt loc labelset env with
        | Some t -> instantiate t
        | None -> (
            (* There is a wrong label somewhere. We get the type of the first label and let
               it fail below.
               The list can never be empty due to the grammar *)
            match Env.find_label_opt (List.hd labelset) env with
            | Some t -> Env.query_type ~instantiate loc t.typename env
            | None ->
                let msg =
                  Printf.sprintf "Cannot find record with label %s"
                    (List.hd labelset)
                in
                raise (Error (loc, msg))))

  let rec convert_record env loc annot labels =
    let raise_ msg lname rname =
      let msg = Printf.sprintf "%s field %s on record %s" msg lname rname in
      raise (Error (loc, msg))
    in

    let labelset = List.map (fun (id, _) -> snd id) labels in
    let t = get_record_type env loc labelset annot in

    let (param, name, labels), labels_expr =
      match t with
      | Trecord (param, Some name, ls)
      | Talias (_, Trecord (param, Some name, ls)) ->
          let f ((loc, lname), expr) =
            let typ, expr =
              match array_assoc_opt lname ls with
              | None ->
                  raise_ "Unbound" lname
                    Path.(rm_name (Env.modpath env) name |> show)
              | Some (Tvar { contents = Unbound _ } as typ) ->
                  (* If the variable is generic, we figure the type out normally
                     and then unify for the later fields *)
                  (typ, convert_annot env None expr)
              | Some (Tvar { contents = Link typ })
              | Some (Talias (_, typ))
              | Some typ ->
                  (typ, convert_annot env (Some typ) expr)
            in
            unify (loc, "In record expression") typ expr.typ env;
            (lname, expr)
          in
          let labels_expr = List.map f labels in
          ((param, name, ls), labels_expr)
      | t ->
          let msg =
            "Expected a record type, not " ^ string_of_type (Env.modpath env) t
          in
          raise (Error (loc, msg))
    in

    (* We sort the labels to appear in the defined order *)
    let const, sorted_labels =
      List.fold_left_map
        (fun is_const field ->
          let expr =
            match List.assoc_opt field.fname labels_expr with
            | Some thing -> thing
            | None ->
                raise_ "Missing" field.fname
                  Path.(rm_name (Env.modpath env) name |> show)
          in
          let const =
            (* There's a special case for string literals.
               They will get copied here which makes them not const.
               NOTE copy in convert_tuple *)
            match expr.expr with
            | Const (String _) -> false
            | _ -> expr.attr.const
          in
          (* Records with mutable fields cannot be const *)
          (is_const && (not field.mut) && const, (field.fname, expr)))
        true (labels |> Array.to_list)
    in
    let typ = Trecord (param, Some name, labels) |> generalize in
    { typ; expr = Record sorted_labels; attr = { no_attr with const }; loc }

  and convert_record_update env loc annot record_arg
      (items : (Ast.ident * Ast.expr) list) =
    (* Implemented in terms of [convert_record] *)
    let record = convert env record_arg in

    let updated =
      List.to_seq items
      |> Seq.map (fun ((loc, key), value) -> (key, (loc, value)))
      |> Hashtbl.of_seq
    in

    let all_new = ref true in
    let name = ref (Path.Pid "") in
    let get_fields n fields =
      name := n;
      Array.map
        (fun field ->
          match Hashtbl.find_opt updated field.fname with
          | Some (loc, expr) ->
              Hashtbl.remove updated field.fname;
              ((loc, field.fname), expr)
          | None ->
              (* There are some old fields. *)
              all_new := false;
              let expr = Ast.Field (loc, record_arg, field.fname) in
              ((loc, field.fname), expr))
        fields
    in

    let fields =
      match clean record.typ with
      | Trecord (_, Some n, fields) -> get_fields n fields
      | Qvar _ | Tvar { contents = Unbound _ } -> (
          (* Take first updated field to figure out the correct record type *)
          let loc, label = List.hd items |> fst in
          match Env.find_label_opt label env with
          | Some t -> (
              match Env.query_type ~instantiate loc t.typename env with
              | Trecord (_, Some n, fields) -> get_fields n fields
              | _ -> failwith "Internal Error: Unreachable")
          | None ->
              raise (Error (loc, "Cannot not find record for label " ^ label)))
      | t ->
          let msg =
            "Expected a record type, not " ^ string_of_type (Env.modpath env) t
          in
          raise (Error (loc, msg))
    in

    if !all_new then
      raise
        (Error
           (loc, "All fields are explicitely updated. Record update is useless"));

    Hashtbl.iter
      (fun field _ ->
        raise
          (Error
             ( loc,
               "Unbound field " ^ field ^ " on "
               ^ Path.(rm_name (Env.modpath env) !name |> show) )))
      updated;

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
              | Some n -> "record " ^ Path.(rm_name (Env.modpath env) n |> show)
              | None -> Printf.sprintf "tuple of size %i" (Array.length labels)
            in
            raise (Error (loc, "Unbound field " ^ id ^ " on " ^ name)))
    | _ -> (
        match Env.find_label_opt id env with
        | Some { index; typename } ->
            let record_t = Env.query_type ~instantiate loc typename env in
            unify
              ( loc,
                "Field access of record "
                ^ string_of_type (Env.modpath env) record_t )
              record_t expr.typ env;
            let labels = get_labels record_t in
            (labels.(index), expr, index)
        | None -> raise (Error (loc, "Unbound field " ^ id)))

  and get_labels = function
    | Trecord (_, _, labels) -> labels
    | Talias (_, t) | Tabstract (_, _, t) | Tvar { contents = Link t } ->
        get_labels t
    | t ->
        print_endline (show_typ t);
        failwith "nope"

  and convert_field env loc expr id =
    let field, expr, index = get_field env loc expr id in
    let mut = expr.attr.mut && field.mut in
    let attr = { no_attr with const = expr.attr.const; mut } in
    { typ = field.ftyp; expr = Field (expr, index, id); attr; loc }
end
