open Types
open Typed_tree
open Inference
open Error

module type Core = sig
  val convert : Env.t -> Ast.expr -> Typed_tree.typed_expr

  val convert_annot :
    Env.t ->
    Types.typ option * Types.mode option ->
    bool ->
    Ast.expr ->
    Typed_tree.typed_expr
end

module type S = sig
  val convert_record :
    Env.t ->
    Ast.loc ->
    Types.typ option * Types.mode option ->
    (bool * Ast.ident * Ast.expr) list ->
    Typed_tree.typed_expr

  val convert_record_update :
    Env.t ->
    Ast.loc ->
    Types.typ option * Types.mode option ->
    Ast.expr ->
    (bool * Ast.ident * Ast.expr) list ->
    Typed_tree.typed_expr

  val convert_field :
    Env.t ->
    Lexing.position * Lexing.position ->
    Ast.expr ->
    string ->
    Typed_tree.typed_expr

  val get_record_type :
    Env.t -> Ast.loc -> string list -> Types.typ option -> Types.typ

  val fields_of_record :
    Ast.loc -> Path.t -> typ list option -> Env.t -> (field array, unit) result
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

  let instantiate_record loc path env =
    let decl, path = Env.find_type loc path env in
    let params = List.map instantiate decl.params in
    Tconstr (path, params, decl.contains_alloc)

  let get_record_type env loc labelset annot =
    match annot with
    | Some t -> t
    | None -> (
        match Env.find_labelset_opt loc labelset env with
        | Some t -> instantiate t
        | None -> (
            (* There is a wrong label somewhere. We get the type of the first
               label and let it fail below. The list can never be empty due to
               the grammar *)
            match Env.find_label_opt (List.hd labelset) env with
            | Some t -> instantiate_record loc t.typename env
            | None ->
                let msg =
                  Printf.sprintf "Cannot find record with label %s"
                    (List.hd labelset)
                in
                raise (Error (loc, msg))))

  let fields_of_record loc path params env =
    let decl, _ = Env.find_type loc path env in
    let sub =
      match params with
      | Some params -> map_params ~inst:params ~params:decl.params
      | None -> Smap.empty
    in
    match decl.kind with
    | Drecord (_, fields) ->
        let _, fields =
          Array.fold_left_map
            (fun sub f ->
              let sub, ftyp = instantiate_sub sub f.ftyp in
              (sub, { f with ftyp }))
            sub fields
        in
        Ok fields
    | _ -> Error ()

  let rec convert_record env loc (annot, _) labels =
    let raise_ msg lname rname =
      let msg = Printf.sprintf "%s field %s on record %s" msg lname rname in
      raise (Error (loc, msg))
    in

    let labelset = List.map (fun (_, id, _) -> snd id) labels in
    let t = get_record_type env loc labelset annot in

    let (params, name, labels, ca), labels_expr =
      match repr t with
      | Tconstr (path, ps, ca) as t when not (is_builtin t) ->
          let ls =
            (match fields_of_record loc path (Some ps) env with
            | Ok labels -> labels
            | Error () ->
                raise
                  (Error
                     ( loc,
                       "Not a record type: "
                       ^ string_of_type (Env.modpath env) t )))
            |> Array.map (fun f -> { f with ftyp = instantiate f.ftyp })
          in
          let labels_expr =
            let f (bor, (loc, label), expr) =
              let typ =
                match array_assoc_opt label ls with
                | None ->
                    raise_ "Unbound" label
                      Path.(rm_name (Env.modpath env) path |> show)
                | Some typ -> typ
              in
              let annot =
                match typ with
                | Tvar { contents = Unbound _ } -> (None, None)
                | Qvar _ -> failwith "unreachable"
                | _ -> (Some typ, None)
              in
              let expr = convert_annot env annot false expr in
              unify (loc, "In record expression") typ expr.typ env;
              (label, (bor, expr))
            in
            List.map f labels
          in
          ((ps, path, ls, ca), labels_expr)
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
          let bor, expr =
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
          (is_const && (not field.mut) && const, (bor, field.fname, expr)))
        true (labels |> Array.to_list)
    in
    let typ = Tconstr (name, params, ca) |> generalize in
    { typ; expr = Record sorted_labels; attr = { no_attr with const }; loc }

  and convert_record_update env loc annot record_arg
      (items : (bool * Ast.ident * Ast.expr) list) =
    (* Implemented in terms of [convert_record] *)
    let record = convert env record_arg in

    let updated =
      List.to_seq items
      |> Seq.map (fun (bor, (loc, key), value) -> (key, (bor, loc, value)))
      |> Hashtbl.of_seq
    in

    let all_new = ref true in
    let name = ref (Path.Pid "") in
    let get_fields loc path ps env =
      name := path;
      let fields =
        match fields_of_record loc path ps env with
        | Error _ ->
            let msg = "Expecting a record type" in
            raise (Error (loc, msg))
        | Ok fs -> fs
      in
      Array.map
        (fun field ->
          match Hashtbl.find_opt updated field.fname with
          | Some (bor, loc, expr) ->
              Hashtbl.remove updated field.fname;
              (bor, (loc, field.fname), expr)
          | None ->
              (* There are some old fields. *)
              all_new := false;
              let expr = Ast.Field (loc, record_arg, field.fname)
              and bor = false (* No field updates for borrowed fields *) in
              (bor, (loc, field.fname), expr))
        fields
    in

    let fields =
      match repr record.typ with
      | Tconstr (path, ps, _) -> get_fields loc path (Some ps) env
      | Qvar _ | Tvar { contents = Unbound _ } -> (
          (* Take first updated field to figure out the correct record type *)
          let _bor, (loc, label), _ = List.hd items in
          match Env.find_label_opt label env with
          | Some t -> get_fields loc t.typename None env
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
    match repr expr.typ with
    (* Builtins are also constructors, but are not records *)
    | Tconstr (path, ps, _) as t when not (is_builtin t) -> (
        let labels =
          match fields_of_record loc path (Some ps) env with
          | Ok labels -> labels
          | Error () ->
              raise
                (Error
                   ( loc,
                     "Not a record type: " ^ string_of_type (Env.modpath env) t
                   ))
        in
        match assoc_opti id labels with
        | Some (index, field) -> (field, expr, index)
        | None ->
            let name = Path.(rm_name (Env.modpath env) path |> show) in
            raise (Error (loc, "Unbound field " ^ id ^ " on " ^ name)))
    | _ -> (
        match Env.find_label_opt id env with
        | Some { index; typename } ->
            let record_t = instantiate_record loc typename env in
            unify
              ( loc,
                "Field access of record "
                ^ string_of_type (Env.modpath env) record_t )
              record_t expr.typ env;
            let labels =
              (match repr record_t with
              | Tconstr (_, ps, _) ->
                  fields_of_record loc typename (Some ps) env
              | _ -> failwith "Internal Error: Does this happen?")
              |> Result.get_ok
            in
            (labels.(index), expr, index)
        | None -> raise (Error (loc, "Unbound field " ^ id)))

  and convert_field env loc expr id =
    let field, expr, index = get_field env loc expr id in
    let mut = expr.attr.mut && field.mut in
    let attr = { no_attr with const = expr.attr.const; mut } in
    { typ = field.ftyp; expr = Field (expr, index, id); attr; loc }
end
