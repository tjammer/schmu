open Types
open Typed_tree
open Inference

type msg_fn = string -> Ast.loc -> string -> string

module Strset = Set.Make (String)

module Str = struct
  type t = string

  let hash = Hashtbl.hash
  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)
module Smap = Types.Smap
module Set = Set.Make (String)
module Recs = Records
module Pm = Patternmatching

(*
   Module state
 *)

let fmt_msg_fn : msg_fn option ref = ref None
let uniq_tbl = Strtbl.create 1

let uniq_name name =
  match Strtbl.find_opt uniq_tbl name with
  | None ->
      Strtbl.add uniq_tbl name 1;
      None
  | Some n ->
      Strtbl.replace uniq_tbl name (n + 1);
      Some (n + 1)

let lambda_id_state = ref 0
let reset state = state := 0

let lambda_id () =
  let id = !lambda_id_state in
  incr lambda_id_state;
  id

let reset_type_vars () =
  Inference.reset ();
  reset lambda_id_state;
  (* Not a type var, but needs resetting as well *)
  Strtbl.clear uniq_tbl

let last_loc = ref (Lexing.dummy_pos, Lexing.dummy_pos)

(*
  Helper functions
*)

let check_annot loc l r =
  let subst, b = Inference.types_match Smap.empty l r in
  if b then ()
  else
    let msg =
      Printf.sprintf "Var annotation: Expected type %s but got type %s"
        (string_of_type_lit r)
        (string_of_type_subst subst l)
    in
    raise (Error (loc, msg))

let check_unused = function
  | Ok () -> ()
  | Error errors ->
      let err (name, kind, loc) =
        let warn_kind =
          match kind with
          | Env.Unused -> "Unused binding "
          | Unmutated -> "Unmutated mutable binding "
          | Unused_mod -> "Unused module open "
        in
        (Option.get !fmt_msg_fn) "warning" loc (warn_kind ^ Path.show name)
        |> print_endline
      in
      List.iter err errors

let string_of_bop = function
  | Ast.Plus_i -> "+"
  | Mult_i -> "*"
  | Div_i -> "/"
  | Less_i -> "<"
  | Greater_i -> ">"
  | Less_eq_i -> "<="
  | Greater_eq_i -> ">="
  | Equal_i -> ""
  | Minus_i -> "-"
  | Ast.Plus_f -> "+."
  | Mult_f -> "*."
  | Div_f -> ">."
  | Less_f -> "<."
  | Greater_f -> ">."
  | Less_eq_f -> "<=."
  | Greater_eq_f -> ">=."
  | Equal_f -> "=."
  | Minus_f -> "-."
  | And -> "and"
  | Or -> "or"

let rec subst_generic ~id typ = function
  (* Substitute generic var [id] with [typ] *)
  | Tvar { contents = Link t } -> subst_generic ~id typ t
  | (Qvar id' | Tvar { contents = Unbound (id', _) }) when String.equal id id'
    ->
      typ
  | Tfun (ps, ret, kind) ->
      let ps =
        List.map
          (fun p ->
            let pt = subst_generic ~id typ p.pt in
            { p with pt })
          ps
      in
      let ret = subst_generic ~id typ ret in
      Tfun (ps, ret, kind)
  | Trecord (ps, name, labels) ->
      let ps = List.map (subst_generic ~id typ) ps in
      let f f = Types.{ f with ftyp = subst_generic ~id typ f.ftyp } in
      let labels = Array.map f labels in
      Trecord (ps, name, labels)
  | Tvariant (ps, name, ctors) ->
      let ps = List.map (subst_generic ~id typ) ps in
      let f c =
        Types.{ c with ctyp = Option.map (subst_generic ~id typ) c.ctyp }
      in
      let ctors = Array.map f ctors in
      Tvariant (ps, name, ctors)
  | Traw_ptr t -> Traw_ptr (subst_generic ~id typ t)
  | Tarray t -> Tarray (subst_generic ~id typ t)
  | Talias (name, t) -> Talias (name, subst_generic ~id typ t)
  | t -> t

and get_generic_ids = function
  | Qvar id | Tvar { contents = Unbound (id, _) } -> [ id ]
  | Tvar { contents = Link t } | Talias (_, t) -> get_generic_ids t
  | Trecord (ps, _, _) | Tvariant (ps, _, _) ->
      List.map get_generic_ids ps |> List.concat
  | Tarray t | Traw_ptr t -> get_generic_ids t
  | _ -> []

let typeof_annot ?(typedef = false) ?(param = false) env loc annot =
  let fn_kind = if param then Closure [] else Simple in

  let find env t tick =
    match Env.find_type_opt t env with
    | Some t -> fst t
    | None -> raise (Error (loc, "Unbound type " ^ tick ^ Path.show t ^ "."))
  in

  let rec is_quantified = function
    | Trecord ([], _, _) | Tvariant ([], _, _) -> None
    | Trecord (ts, Some name, _) | Tvariant (ts, name, _) ->
        Some (name, List.length ts)
    | Traw_ptr _ -> Some (Path.Pid "raw_ptr", 1)
    | Tarray _ -> Some (Path.Pid "array", 1)
    | Talias (name, t) -> (
        let cleaned = clean t in
        match is_quantified cleaned with
        | Some (_, n) when is_polymorphic cleaned -> Some (name, n)
        | Some _ | None -> (* When can alias a concrete type *) None)
    | Tvar { contents = Link t } -> is_quantified t
    | _ -> None
  in

  let rec concrete_type in_list env = function
    | Ast.Ty_id "int" -> Tint
    | Ty_id "bool" -> Tbool
    | Ty_id "unit" -> Tunit
    | Ty_id "u8" -> Tu8
    | Ty_id "float" -> Tfloat
    | Ty_id "i32" -> Ti32
    | Ty_id "f32" -> Tf32
    | Ty_id "array" ->
        if not in_list then
          raise (Error (loc, "Type array expects 1 type parameter"));
        Tarray (Qvar "o")
        (* Use a letter care so we don't clash with a real value *)
    | Ty_id "raw_ptr" ->
        if not in_list then
          raise (Error (loc, "Type raw_ptr expects 1 type parameter"));
        Traw_ptr (Qvar "o")
    | Ty_id t ->
        let t = find env (Path.Pid t) "" in
        (if not in_list then
         match is_quantified t with
         | Some (name, n) ->
             let msg =
               Printf.sprintf "Type %s expects %i type parameter%s"
                 (Path.show name) n
                 (if n > 1 then "s" else "")
             in
             raise (Error (loc, msg))
         | None -> ());
        t
    | Ty_var id when typedef -> find env id "'"
    | Ty_var id ->
        (* Type annotation in function *)
        Qvar (Path.get_hd id)
    | Ty_func l -> handle_func env l
    | Ty_list l -> type_list env l
    | Ty_open_id (loc, path) -> import_path loc env path
    | Ty_tuple ts ->
        let fields =
          List.mapi
            (fun i t ->
              let fname = string_of_int i in
              let ftyp = concrete_type false env t in
              { fname; ftyp; mut = false })
            ts
        in
        Trecord ([], None, Array.of_list fields)
  and import_path loc env = function
    | Path.Pid _ as id -> find env id ""
    | Path.Pmod (md, tl) ->
        let modul = Module.read_exn ~regeneralize md loc in
        let env = Module.add_to_env env md modul in
        import_path loc env tl
  and type_list env = function
    | [] -> failwith "Internal Error: Type param list should not be empty"
    | t :: tl -> (
        let t = concrete_type true env t in
        match is_quantified t with
        | Some (name, n) -> (
            try
              match get_generic_ids t with
              | [] ->
                  let msg =
                    "Expected a parametrized type, not " ^ string_of_type t
                  in
                  raise (Error (loc, msg))
              | l ->
                  List.fold_left2
                    (fun parent child id ->
                      let t = concrete_type false env child in
                      subst_generic ~id t parent)
                    t tl l
            with Invalid_argument _ ->
              let msg =
                Printf.sprintf "Type %s expects %i type parameter%s"
                  (Path.show name) n
                  (if n > 1 then "s" else "")
              in
              raise (Error (loc, msg)))
        | None -> failwith "Internal Error: Not sure, this shouldn't happen")
  and handle_func env = function
    | [] -> failwith "Internal Error: Type annot list should not be empty"
    | [ (t, _) ] -> concrete_type false env t
    | [ (Ast.Ty_id "unit", _); (t, _) ] ->
        Tfun ([], concrete_type false env t, fn_kind)
    | [ (Ast.Ty_list [ Ast.Ty_id "unit" ], _); (t, _) ] ->
        Tfun ([], concrete_type false env t, fn_kind)
    (* For function definiton and application, 'unit' means an empty list.
       It's easier for typing and codegen to treat unit as a special case here *)
    | l -> (
        (* We reverse the list times :( *)
        match List.rev l with
        | (last, _) :: head ->
            Tfun
              ( List.map
                  (fun (s, pmut) -> { pt = concrete_type false env s; pmut })
                  (List.rev head),
                concrete_type false env last,
                fn_kind )
        | [] -> failwith ":)")
  in
  concrete_type false env annot

let rec param_annots t =
  let annot t =
    match clean t with
    | Qvar _ | Tvar { contents = Unbound _ } -> None
    | _ -> Some t
  in
  (* We don't clean here, because it might mess with links *)
  match t with
  | Talias (_, t) | Tvar { contents = Link t } -> param_annots t
  | Qvar _ | Tvar { contents = Unbound _ } -> [||]
  | Tfun (typs, _, _) -> List.map (fun p -> annot p.pt) typs |> Array.of_list
  | _ -> [||]

let param_annot annots i =
  if Array.length annots > i then Array.get annots i else None

let handle_params env loc (params : Ast.decl list) pattern_id ret =
  (* return updated env with bindings for parameters and types of parameters *)
  let rec handle = function
    | Qvar _ as t -> (newvar (), t)
    | Tfun (params, ret, kind) ->
        let params, qparams =
          List.map
            (fun p ->
              let a, b = handle p.pt in
              ({ p with pt = a }, { p with pt = b }))
            params
          |> List.split
        in
        let ret, qret = handle ret in
        (Tfun (params, ret, kind), Tfun (qparams, qret, kind))
    | t -> (t, t)
  in

  List.fold_left_map
    (fun (env, i) { Ast.loc; pattern; mut; annot } ->
      let id, idloc = pattern_id i pattern in
      let type_id, qparams =
        match annot with
        | None ->
            let t = newvar () in
            (t, t)
        | Some annot ->
            let t, q = handle (typeof_annot ~param:true env loc annot) in
            (instantiate t, q)
      in
      (* Might be const, but not important here *)
      ( ( Env.add_value id
            {
              typ = type_id;
              const = false;
              param = true;
              global = false;
              imported = None;
              mut;
            }
            idloc env,
          i + 1 ),
        ({ pt = type_id; pmut = mut }, { pt = qparams; pmut = mut }) ))
    (env, 0) params
  |> fun ((env, _), lst) ->
  let ids, qparams = List.split lst in
  let ret = Option.map (fun t -> typeof_annot env loc t) ret in
  (env, ids, qparams, ret)

let check_type_unique env loc ~in_sig name =
  match Env.find_type_opt name env with
  (* It's ok to have a type both in signature and impl *)
  | Some (_, insig) when Bool.equal in_sig insig ->
      let msg =
        Printf.sprintf
          "Type names in a module must be unique. %s exists already"
          (Path.show name)
      in
      raise (Error (loc, msg))
  | Some _ | None -> ()

let add_type_param env ts =
  List.fold_left_map
    (fun env name ->
      (* Create general type *)
      enter_level ();
      let typ = newvar () in
      leave_level ();
      let t = generalize typ in

      let in_sig = false in
      (Env.add_type name ~in_sig t env, t))
    env ts

let type_record env loc ~in_sig Ast.{ name = { poly_param; name }; labels } =
  (* Make sure that each type name only appears once per module *)
  check_type_unique ~in_sig env loc name;
  let labels, params =
    (* Temporarily add polymorphic type name to env *)
    let env, param = add_type_param env poly_param in
    let labels =
      Array.map
        (fun (mut, fname, type_expr) ->
          let ftyp = typeof_annot ~typedef:true env loc type_expr in
          { fname; ftyp; mut })
        labels
    in
    (labels, param)
  in
  let kind = if in_sig then Env.Asignature else Aimpl in
  Env.add_record name kind ~params ~labels env

let type_alias env loc ~in_sig { Ast.poly_param; name } type_spec =
  (* Make sure that each type name only appears once per module *)
  check_type_unique ~in_sig env loc name;
  (* Temporarily add polymorphic type name to env *)
  let temp_env, _ = add_type_param env poly_param in
  let typ = typeof_annot ~typedef:true temp_env loc type_spec in
  let kind = if in_sig then Env.Asignature else Aimpl in
  Env.add_alias name kind typ env

let type_variant env loc ~in_sig { Ast.name = { poly_param; name }; ctors } =
  (* Make sure that each type name only appears once per module *)
  check_type_unique ~in_sig env loc name;
  (* Temporarily add polymorphic type name to env *)
  let temp_env, params = add_type_param env poly_param in

  (* We follow the C way for C-style enums. At the same time, we forbid
     tag clashes for constructors with payload *)
  let next = ref (-1) in
  let indices = Hashtbl.create 32 in
  let nexti ~has_payload loc name =
    incr next;
    match Hashtbl.find_opt indices !next with
    | Some (name, pl) when has_payload || pl ->
        let msg =
          Printf.sprintf "Tag %i already used for constructor %s" !next name
        in
        raise (Error (loc, msg))
    | Some _ | None ->
        Hashtbl.replace indices !next (name, has_payload);
        !next
  in
  let maybe_add_index has_payload loc name = function
    | Some i ->
        (* We set the index to one lower, as it increases on call to [nexti] *)
        next := i - 1;
        nexti ~has_payload loc name
    | None -> nexti ~has_payload loc name
  in

  let ctors =
    List.map
      (fun { Ast.name = loc, cname; typ_annot; index } ->
        match typ_annot with
        | None ->
            (* Just a ctor, without data *)
            {
              cname;
              ctyp = None;
              index = maybe_add_index false loc cname index;
            }
        | Some annot ->
            let typ = typeof_annot ~typedef:true temp_env loc annot in
            {
              cname;
              ctyp = Some typ;
              index = maybe_add_index true loc cname index;
            })
      ctors
    |> Array.of_list
  in
  let kind = if in_sig then Env.Asignature else Aimpl in
  Env.add_variant name kind ~params ~ctors env

let rec param_funcs_as_closures = function
  (* Functions passed as parameters need to have an empty closure, otherwise they cannot
     be captured (see above). Kind of sucks *)
  | Tvar { contents = Link t } | Talias (_, t) ->
      (* This shouldn't break type inference *) param_funcs_as_closures t
  | Tfun (_, _, Closure _) as t -> t
  | Tfun (params, ret, _) -> Tfun (params, ret, Closure [])
  | t -> t

let convert_simple_lit loc typ expr =
  { typ; expr = Const expr; attr = { no_attr with const = true }; loc }

let rec builtins_hack callee args =
  (* return of __unsafe_ptr_get should be marked mut, otherwise it won't be copied
     correctly later in codegen. *)
  (* NOTE is_temporary is monomorph_tree also needs to be updated *)
  match callee with
  | Ast.Var (_, id) -> (
      match id with
      | "__unsafe_ptr_get" -> { no_attr with mut = true }
      | "array-get" | "array-data" | "array-length" ->
          let mut =
            match args with
            (* We only care about the first arg, ie the array *)
            | (_, _, mut) :: _ -> mut
            | _ -> false
          in
          { no_attr with mut }
      | _ -> no_attr)
  | Let_e (__, _, _, cont) -> builtins_hack cont args
  | _ -> no_attr

let fold_decl cont (id, e) = { cont with expr = Bind (id, None, e, cont) }

module rec Core : sig
  val convert : Env.t -> Ast.expr -> typed_expr

  val convert_annot :
    Env.t -> Types.typ option -> Ast.expr -> Typed_tree.typed_expr

  val convert_var : Env.t -> Ast.loc -> string -> typed_expr
  val convert_block : ?ret:bool -> Env.t -> Ast.block -> typed_expr * Env.t

  val convert_let :
    global:bool ->
    Env.t ->
    Ast.loc ->
    Ast.decl ->
    Ast.expr ->
    Env.t * string * typed_expr * bool * (string * typed_expr) list

  val convert_function :
    Env.t ->
    Ast.loc ->
    Ast.func ->
    bool ->
    Env.t * (string * int option * abstraction)
end = struct
  open Records
  open Patternmatch

  let string_typ = Talias (Path.Pid "string", Tarray Tu8)

  let rec convert env expr = convert_annot env None expr

  and convert_annot env annot = function
    | Ast.Var (loc, id) -> convert_var env loc id
    | Lit (loc, Int i) -> convert_simple_lit loc Tint (Int i)
    | Lit (loc, Bool b) -> convert_simple_lit loc Tbool (Bool b)
    | Lit (loc, U8 c) -> convert_simple_lit loc Tu8 (U8 c)
    | Lit (loc, Float f) -> convert_simple_lit loc Tfloat (Float f)
    | Lit (loc, I32 i) -> convert_simple_lit loc Ti32 (I32 i)
    | Lit (loc, F32 i) -> convert_simple_lit loc Tf32 (F32 i)
    | Lit (loc, String s) ->
        let typ = string_typ in
        (* TODO is const, but handled differently right now *)
        { typ; expr = Const (String s); attr = no_attr; loc }
    | Lit (loc, Array arr) -> convert_array_lit env loc arr
    | Lit (loc, Unit) ->
        let attr = { no_attr with const = true } in
        { typ = Tunit; expr = Const Unit; attr; loc }
    | Lambda (loc, id, e) -> convert_lambda env loc id e
    | Let_e (loc, decl, expr, cont) -> convert_let_e env loc decl expr cont
    | App (loc, e1, e2) -> convert_app ~switch_uni:false env loc e1 e2
    | Bop (loc, bop, es) -> convert_bop env loc bop es
    | Unop (loc, unop, expr) -> convert_unop env loc unop expr
    | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
    | Record (loc, labels) -> convert_record env loc annot labels
    | Tuple (loc, exprs) -> convert_tuple env loc exprs
    | Record_update (loc, record, items) ->
        convert_record_update env loc annot record items
    | Field (loc, expr, id) -> convert_field env loc expr id
    | Set (loc, expr, value) -> convert_set env loc expr value
    | Do_block stmts -> convert_block env stmts |> fst
    | Pipe_head (loc, e1, e2) -> convert_pipe_head env loc e1 e2
    | Pipe_tail (loc, e1, e2) -> convert_pipe_tail env loc e1 e2
    | Ctor (loc, name, args) -> convert_ctor env loc name args annot
    | Match (loc, exprs, cases) -> convert_match env loc exprs cases
    | Local_open (loc, modul, blk) -> convert_open env loc modul blk
    | Fmt (loc, exprs) -> convert_fmt env loc exprs

  and convert_var env loc id =
    match Env.query_val_opt id env with
    | Some t ->
        let typ = instantiate t.typ in
        let attr = { const = t.const; global = t.global; mut = t.mut } in
        let id =
          match t.imported with
          | Some mname -> Env.mod_fn_name ~mname id
          | _ -> id
        in
        { typ; expr = Var id; attr; loc }
    | None -> raise (Error (loc, "No var named " ^ id))

  and convert_array_lit env loc arr =
    let f typ expr =
      let expr = convert env expr in
      unify (loc, "In array literal:") typ expr.typ;
      (typ, expr)
    in
    let typ, exprs = List.fold_left_map f (newvar ()) arr in

    let typ = Tarray typ in
    { typ; expr = Const (Array exprs); attr = no_attr; loc }

  and typeof_annot_decl env loc annot block =
    enter_level ();
    match annot with
    | None ->
        let t = convert env block in
        leave_level ();
        (* We generalize functions, but allow weak variables for value types *)
        let typ =
          match clean t.typ with Tfun _ -> generalize t.typ | _ -> t.typ
        in
        { t with typ }
    | Some annot ->
        let t_annot = typeof_annot env loc annot in
        let t = convert_annot env (Some t_annot) block in
        leave_level ();

        (match clean t.typ with
        | Tfun _ -> check_annot loc t.typ t_annot
        | _ -> unify (loc, "In let binding:") t.typ t_annot);

        { t with typ = t_annot }

  and convert_let ~global env loc (decl : Ast.decl) block =
    let id, idloc = pattern_id 0 decl.pattern in
    let e1 = typeof_annot_decl env loc decl.annot block in
    let mut = decl.mut in
    let const = e1.attr.const && not mut in
    let env =
      Env.add_value id
        { Env.def_value with typ = e1.typ; const; global; mut }
        idloc env
    in
    let env, pat_exprs = convert_decl env [ decl ] in
    let expr = { e1 with attr = { global; const; mut } } in
    (env, id, expr, e1.attr.mut, pat_exprs)

  and convert_let_e env loc decl expr cont =
    let env, id, lhs, rmut, pats =
      convert_let ~global:false env loc decl expr
    in
    let cont = convert env cont in
    let cont = List.fold_left fold_decl cont pats in
    let uniq = if lhs.attr.const then uniq_name id else None in
    let expr = Let { id; uniq; rmut; lhs; cont } in
    { typ = cont.typ; expr; attr = cont.attr; loc }

  and convert_lambda env loc params body =
    let env = Env.open_function env in
    enter_level ();
    let env, params_t, qparams, ret_annot =
      handle_params env loc params pattern_id None
    in

    let env, param_exprs = convert_decl env params in

    let body = convert_block env body |> fst in
    let body = List.fold_left fold_decl body param_exprs in

    leave_level ();
    let _, closed_vars, unused = Env.close_function env in
    let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
    check_unused unused;

    (* For codegen: Mark functions in parameters closures *)
    let params_t =
      List.map (fun p -> { p with pt = param_funcs_as_closures p.pt }) params_t
    in

    let typ = Tfun (params_t, body.typ, kind) in
    match typ with
    | Tfun (tparams, ret, kind) ->
        let ret = match ret_annot with Some ret -> ret | None -> ret in
        let qtyp = Tfun (qparams, ret, kind) in
        check_annot loc typ qtyp;

        let nparams =
          List.mapi
            (fun i (d : Ast.decl) -> fst (pattern_id i d.pattern))
            params
        in
        let func = { tparams; ret; kind } in
        let abs =
          { nparams; body = { body with typ = ret }; func; inline = false }
        in
        let expr = Lambda (lambda_id (), None, abs) in
        { typ; expr; attr = no_attr; loc }
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and convert_function env loc
      Ast.{ name = nameloc, name; params; return_annot; body; attr } inrec =
    (* Create a fresh type var for the function name
       and use it in the function body *)
    let unique = uniq_name name in

    let inline =
      match attr with
      | Some (_, "inline") -> true
      | Some (loc, attr) -> raise (Error (loc, "Unknown attribute: " ^ attr))
      | None -> false
    in

    enter_level ();
    let env =
      if inrec then
        (* Function is already part of env with a fresh variable *)
        env
      else
        (* Recursion allowed for named funcs *)
        let ps =
          List.map (fun p -> Ast.{ pmut = p.mut; pt = newvar () }) params
        in
        let typ = Tfun (ps, newvar (), Simple) in
        Env.(add_value name { def_value with typ } nameloc env)
    in

    (* We duplicate some lambda code due to naming *)
    let env = Env.open_function env in
    let body_env, params_t, qparams, ret_annot =
      handle_params env loc params pattern_id return_annot
    in

    let body_env, param_exprs = convert_decl body_env params in

    let body = convert_block body_env body |> fst in
    let body = List.fold_left fold_decl body param_exprs in
    leave_level ();

    let env, closed_vars, unused = Env.close_function env in

    let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
    check_unused unused;

    (* For codegen: Mark functions in parameters closures *)
    let params_t =
      List.map (fun p -> { p with pt = param_funcs_as_closures p.pt }) params_t
    in

    let typ =
      Tfun (params_t, body.typ, kind)
      |>
      (* For mutually recursive functions, we generalize at the end of the rec block.
         Otherwise calls to the not-last function in the set will not work*)
      fun t -> if inrec then t else generalize t
    in

    match typ with
    | Tfun (tparams, ret, kind) ->
        (* Make sure the types match *)
        unify (loc, "Function") (Env.find_val name env).typ typ;

        (* Add the generalized type to the env to keep the closure there *)
        let env = Env.change_type name typ env in

        let ret = match ret_annot with Some ret -> ret | None -> ret in
        let qtyp = Tfun (qparams, ret, kind) |> generalize in
        check_annot loc typ qtyp;

        let nparams =
          List.mapi
            (fun i (d : Ast.decl) -> fst (pattern_id i d.pattern))
            params
        in
        let func = { tparams; ret; kind } in
        let lambda =
          { nparams; body = { body with typ = ret }; func; inline }
        in

        (env, (name, unique, lambda))
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and convert_app ~switch_uni env loc e1 args =
    let callee = convert env e1 in

    let annots = param_annots callee.typ in
    let typed_exprs =
      List.mapi
        (fun i (a : Ast.argument) ->
          let e =
            if a.amut then Env.open_mutation env;
            let e = convert_annot env (param_annot annots i) a.aexpr in
            if a.amut then (
              Env.close_mutation env;
              if not e.attr.mut then
                raise
                  (Error (a.aloc, "Mutably passed expression is not mutable")));
            e
          in
          (* We also care about whether the argument _can_ be mutable, for array-get *)
          (e, a.amut, e.attr.mut))
        args
    in
    let args_t =
      List.map (fun (a, pmut, _) -> { pmut; pt = a.typ }) typed_exprs
    in
    let res_t = newvar () in
    if switch_uni then
      unify (loc, "Application:") (Tfun (args_t, res_t, Simple)) callee.typ
    else unify (loc, "Application:") callee.typ (Tfun (args_t, res_t, Simple));

    let apply param (texpr, mut, _) = ({ texpr with typ = param.pt }, mut) in
    let targs = List.map2 apply args_t typed_exprs in

    let attr = builtins_hack e1 typed_exprs in

    (* Extract the returning type from the callee, because it's properly
       generalized and linked. This way, everything in a function body
       should be generalized and we can easily catch weak type variables *)
    let typ =
      let rec extract_typ = function
        | Tfun (_, t, _) -> t
        | Talias (_, t) | Tvar { contents = Link t } -> extract_typ t
        | t -> t
      in
      extract_typ callee.typ
    in

    (* For now, we don't support const functions *)
    { typ; expr = App { callee; args = targs }; attr; loc }

  and convert_bop_impl env loc bop e1 e2 =
    let check typ =
      let t1 = convert env e1 in
      let t2 = convert env e2 in

      unify (loc, "Binary " ^ string_of_bop bop) typ t1.typ;
      unify (loc, "Binary " ^ string_of_bop bop) t1.typ t2.typ;
      (t1, t2, t1.attr.const && t2.attr.const)
    in

    let typ, (t1, t2, const) =
      match bop with
      | Ast.Plus_i | Mult_i | Minus_i | Div_i -> (Tint, check Tint)
      | Less_i | Equal_i | Greater_i | Less_eq_i | Greater_eq_i ->
          (Tbool, check Tint)
      | Plus_f | Mult_f | Minus_f | Div_f -> (Tfloat, check Tfloat)
      | Less_f | Equal_f | Greater_f | Less_eq_f | Greater_eq_f ->
          (Tbool, check Tfloat)
      | And | Or -> (Tbool, check Tbool)
    in
    { typ; expr = Bop (bop, t1, t2); attr = { no_attr with const }; loc }

  and convert_bop env loc bop es =
    let rec build = function
      | [ _ ] | [] ->
          raise (Error (loc, "Binary operator needs at least two operands"))
      | [ a; b ] -> convert_bop_impl env loc bop a b
      | a :: tl ->
          let tl = build tl in
          { tl with expr = Bop (bop, tl, convert env a) }
    in
    build es

  and convert_unop env loc unop expr =
    match unop with
    | Uminus_f ->
        let e = convert env expr in
        unify (loc, "Unary -.:") Tfloat e.typ;
        { typ = Tfloat; expr = Unop (unop, e); attr = e.attr; loc }
    | Uminus_i -> (
        let e = convert env expr in
        let msg = "Unary -:" in
        let expr = Unop (unop, e) in

        try
          (* We allow '-' to also work on float expressions *)
          unify (loc, msg) Tfloat e.typ;
          { typ = Tfloat; expr; attr = e.attr; loc }
        with Error _ -> (
          try
            unify (loc, msg) Tint e.typ;
            { typ = Tint; expr; attr = e.attr; loc }
          with Error (loc, errmsg) ->
            let pos = String.length msg + String.length ": Expected type int" in
            let post = String.sub errmsg pos (String.length errmsg - pos) in
            raise (Error (loc, "Unary -: Expected types int or float " ^ post)))
        )

  and convert_if env loc cond e1 e2 =
    (* We can assume pred evaluates to bool and both
       branches need to evaluate to the some type *)
    let type_cond = convert env cond in
    unify (loc, "In condition") type_cond.typ Tbool;
    let type_e1 = convert env e1 in
    let type_e2 =
      (* We unify in the pattern match to have different messages and unification order *)
      match e2 with
      | Some e2 ->
          let msg = "Branches have different type:" in
          let e2 = convert env e2 in
          unify (loc, msg) type_e1.typ e2.typ;
          e2
      | None ->
          let msg =
            "A conditional without else branch should evaluato to type unit."
          in
          let e2 =
            let attr = { no_attr with const = true } in
            { typ = Tunit; expr = Const Unit; attr; loc }
          in
          unify (loc, msg) e2.typ type_e1.typ;
          e2
    in

    (* We don't support polymorphic lambdas in if-exprs in the monomorph backend yet *)
    (match type_e2.typ with
    | Tfun (_, _, _) as t when is_polymorphic t ->
        raise
          (Error
             ( loc,
               "Returning polymorphic anonymous function in if expressions is \
                not supported (yet). Sorry. You can type the function \
                concretely though." ))
    | _ -> ());

    (* Would be interesting to evaluate this at compile time,
       but I think it's not that important right now *)
    {
      typ = type_e2.typ;
      expr = If (type_cond, type_e1, type_e2);
      attr = no_attr;
      loc;
    }

  and pipe_ctor_msg =
    "Constructor already has an argument, cannot pipe a second one"

  and convert_set env loc (eloc, expr) value =
    Env.open_mutation env;
    let toset = convert env expr in
    Env.close_mutation env;
    let valexpr = convert env value in

    (if not toset.attr.mut then
     let msg = Printf.sprintf "Cannot mutate non-mutable binding" in
     raise (Error (eloc, msg)));
    unify (loc, "Mutate:") toset.typ valexpr.typ;
    { typ = Tunit; expr = Set (toset, valexpr); attr = no_attr; loc }

  and convert_pipe_head env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | Pip_expr (App (loc, callee, args)) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (e1 :: args)
    | Pip_expr (Ctor (loc, name, expr)) ->
        if Option.is_some expr then raise (Error (loc, pipe_ctor_msg));
        convert_ctor env loc name (Some e1.aexpr) None
    | Pip_expr (Bop (loc, op, exprs)) ->
        convert_bop env loc op (e1.aexpr :: exprs)
    | Pip_expr (Fmt (loc, l)) -> convert_fmt env loc (e1.aexpr :: l)
    | Pip_expr e2 ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]
    | Pip_field field -> convert_field env loc e1.aexpr field

  and convert_pipe_tail env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | Pip_expr (App (loc, callee, args)) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (args @ [ e1 ])
    | Pip_expr (Ctor (loc, name, expr)) ->
        if Option.is_some expr then raise (Error (loc, pipe_ctor_msg));
        convert_ctor env loc name (Some e1.aexpr) None
    | Pip_expr (Bop (loc, op, exprs)) ->
        convert_bop env loc op (exprs @ [ e1.aexpr ])
    | Pip_expr (Fmt (loc, l)) -> convert_fmt env loc (l @ [ e1.aexpr ])
    | Pip_expr e2 ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]
    | Pip_field field -> convert_field env loc e1.aexpr field

  and convert_open env loc md expr =
    let modul = Module.read_exn ~regeneralize md loc in
    let env =
      Module.add_to_env (Env.open_module env loc md) md modul
      |> Env.finish_module
    in
    let r = convert env expr in
    ignore (Env.close_module env);
    r

  and convert_tuple env loc exprs =
    let (_, const), exprs =
      List.fold_left_map
        (fun (i, const) expr ->
          let expr = convert env expr in
          let const = const && expr.attr.const in
          ((i + 1, const), (string_of_int i, expr)))
        (0, true) exprs
    in
    let fields =
      List.map (fun (fname, e) -> { fname; ftyp = e.typ; mut = false }) exprs
    in
    let typ = Trecord ([], None, Array.of_list fields) in
    let attr = { const; global = false; mut = false } in
    { typ; expr = Record exprs; attr; loc }

  and convert_fmt env loc exprs =
    let f expr =
      let e = convert env expr in
      match (e.expr, clean e.typ) with
      | Const (String s), _ -> Fstr s
      | _, Tarray Tu8 -> Fexpr e
      | _, (Tint | Tfloat | Tbool | Tu8 | Ti32 | Tf32) -> Fexpr e
      | _, Tvar { contents = Unbound _ } ->
          Fexpr e (* Might be the right type later *)
      | _, Tarray (Tvar { contents = Unbound _ }) ->
          Fexpr e (* Might be string later *)
      | _, _ ->
          print_string (show_typ e.typ);
          failwith "TODO not implemented yet "
    in
    let exprs = List.map f exprs in
    let typ = string_typ in
    { typ; expr = Fmt exprs; attr = no_attr; loc }

  and convert_block_annot ~ret env annot stmts =
    let loc = Lexing.(dummy_pos, dummy_pos) in

    let check (loc, typ) =
      unify (loc, "Left expression in sequence must be of type unit:") Tunit typ
    in

    let rec to_expr env old_type = function
      | [
          ( Ast.Let (loc, _, _)
          | Function (loc, _)
          | Rec (loc, _)
          | Open (loc, _) );
        ]
        when ret ->
          raise (Error (loc, "Block must end with an expression"))
      | [] when ret -> raise (Error (loc, "Block cannot be empty"))
      | [] -> ({ typ = Tunit; expr = Const Unit; attr = no_attr; loc }, env)
      | Let (loc, decl, block) :: tl ->
          let env, id, lhs, rmut, pats =
            convert_let ~global:false env loc decl block
          in
          let cont, env = to_expr env old_type tl in
          let cont = List.fold_left fold_decl cont pats in
          let uniq = if lhs.attr.const then uniq_name id else None in
          let expr = Let { id; uniq; rmut; lhs; cont } in
          ({ typ = cont.typ; expr; attr = cont.attr; loc }, env)
      | Function (loc, func) :: tl ->
          let env, (name, unique, abs) = convert_function env loc func false in
          let cont, env = to_expr env old_type tl in
          let expr = Function (name, unique, abs, cont) in
          ({ typ = cont.typ; expr; attr = cont.attr; loc }, env)
      | Rec (loc, funcs) :: tl ->
          (* Collect function names *)
          let collect env (_, (func : Ast.func)) =
            let nameloc, name = func.name in
            enter_level ();
            let typ = newvar () in
            leave_level ();
            Env.(add_value name { def_value with typ } nameloc env)
          in
          let env = List.fold_left collect env funcs in
          let f env (loc, func) =
            let env, f = convert_function env loc func true in
            (env, (loc, f))
          in
          let env, funcs = List.fold_left_map f env funcs in
          let cont, env = to_expr env old_type tl in

          let rec aux = function
            | (loc, (n, u, abs)) :: tl ->
                let t = Env.find_val n env in
                let decls, cont = aux tl in
                let expr = Function (n, u, abs, cont) in
                ( (n, u, t.typ) :: decls,
                  { typ = cont.typ; expr; attr = cont.attr; loc } )
            | [] -> ([], cont)
          in
          let decls, cont = aux funcs in
          let expr = Mutual_rec_decls (decls, cont) in
          ({ typ = cont.typ; expr; attr = cont.attr; loc }, env)
      | [ Expr (loc, e) ] ->
          last_loc := loc;
          check old_type;
          (convert_annot env annot e, env)
      | Expr (l1, e1) :: tl ->
          check old_type;
          let expr = convert env e1 in
          let cont, env = to_expr env (l1, expr.typ) tl in
          let expr = Sequence (expr, cont) in
          ({ typ = cont.typ; expr; attr = cont.attr; loc }, env)
      | Open (loc, mname) :: tl ->
          let modul = Module.read_exn ~regeneralize mname loc in
          let env =
            Module.add_to_env (Env.open_module env loc mname) mname modul
          in
          let cont, env = to_expr (Env.finish_module env) old_type tl in
          (cont, Env.close_module env)
    in
    to_expr env (loc, Tunit) stmts

  and convert_block ?(ret = true) env stmts =
    convert_block_annot ~ret env None stmts
end

and Records : Recs.S = Recs.Make (Core)
and Patternmatch : Pm.S = Pm.Make (Core) (Records)

let block_external_name loc ~cname id =
  (* We have to deal with shadowing:
     If there is no function with the same name, we make sure
     all future function use different names internally (via [uniq_tbl]).
     If there already is a function, there is nothing we can do right now,
     so we error *)
  let name = match cname with Some name -> name | None -> id in
  match Strtbl.find_opt uniq_tbl name with
  | None ->
      (* Good, block this name. NOTE see [uniq_name] *)
      Strtbl.add uniq_tbl name 1
  | Some _ ->
      let msg =
        Printf.sprintf
          "External function name %s already in use. This is not supported \
           yet, make sure to define the external function first"
          name
      in
      raise (Error (loc, msg))

let convert_prog env items modul =
  let old = ref (Lexing.(dummy_pos, dummy_pos), Tunit) in

  let rec aux (env, items, m) = function
    | Ast.Stmt stmt ->
        let old', env, items, m = aux_stmt (!old, env, items, m) stmt in
        old := old';
        (env, items, m)
    | Ext_decl (loc, (idloc, id), typ, cname) ->
        let typ = typeof_annot env loc typ in
        block_external_name loc ~cname id;
        let m = Module.add_external loc typ id cname ~closure:false m in
        ( Env.add_external id ~cname typ ~imported:None idloc ~closure:false env,
          items,
          m )
    | Typedef (loc, Trecord t) ->
        let env, typ = type_record ~in_sig:false env loc t in
        let m = Module.add_type loc typ m in
        (env, items, m)
    | Typedef (loc, Talias (name, type_spec)) ->
        let env, typ = type_alias ~in_sig:false env loc name type_spec in
        let m = Module.add_type loc typ m in
        (env, items, m)
    | Typedef (loc, Tvariant v) ->
        let env, typ = type_variant ~in_sig:false env loc v in
        let m = Module.add_type loc typ m in
        (env, items, m)
  and aux_stmt (old, env, items, m) = function
    (* TODO dedup *)
    | Ast.Let (loc, decl, block) ->
        let env, id, lhs, _, pats =
          Core.convert_let ~global:true env loc decl block
        in
        let uniq = uniq_name id in
        (* Make string option out of int option for unique name *)
        let uniq_name =
          match uniq with
          | None -> None
          | Some i -> Some (Module.unique_name id (Some i))
        in
        let m = Module.add_external loc lhs.typ id uniq_name ~closure:true m in
        let expr =
          let expr = Tl_let (id, uniq, lhs) in
          match pats with
          (* Maybe add pattern expressions *)
          | [] -> [ expr ]
          | ps -> List.map (fun (id, e) -> Tl_bind (id, e)) ps @ [ expr ]
        in
        (old, env, expr @ items, m)
    | Function (loc, func) ->
        let env, (name, unique, abs) =
          Core.convert_function env loc func false
        in
        let m = Module.add_fun loc name unique abs m in
        (old, env, Tl_function (loc, name, unique, abs) :: items, m)
    | Rec (loc, funcs) ->
        (* Collect function names *)
        let collect env (_, (func : Ast.func)) =
          let nameloc, name = func.name in
          enter_level ();
          let typ = newvar () in
          leave_level ();
          Env.(add_value name { def_value with typ } nameloc env)
        in
        let env = List.fold_left collect env funcs in
        let f env (loc, func) =
          let env, (n, u, abs) = Core.convert_function env loc func true in
          (env, (loc, n, u, abs))
        in
        let env, funcs = List.fold_left_map f env funcs in
        let rec aux env = function
          | (l, n, u, abs) :: tl ->
              let t = Env.find_val n env in
              (* Generalize the functions *)
              let typ = generalize t.typ in
              let env = Env.change_type n typ env in

              let decls, fitems, env = aux env tl in
              ((n, u, t.typ) :: decls, Tl_function (l, n, u, abs) :: fitems, env)
          | [] -> ([], [], env)
        in
        let decls, fitems, env = aux env (List.rev funcs) in
        let m = Module.add_rec_block loc funcs m in
        (old, env, fitems @ (Tl_mutual_rec_decls decls :: items), m)
    | Expr (loc, expr) ->
        let expr = Core.convert env expr in
        (* Only the last expression is allowed to return something *)
        unify
          (fst old, "Left expression in sequence must be of type unit:")
          Tunit (snd old);
        ((loc, expr.typ), env, Tl_expr expr :: items, m)
    | Open (loc, mname) ->
        let modul = Module.read_exn ~regeneralize mname loc in
        let env =
          Module.add_to_env (Env.open_module env loc mname) mname modul
        in
        (old, Env.finish_module env, items, m)
  in

  let env, items, m = List.fold_left aux (env, [], modul) items in
  (snd !old, env, List.rev items, m)

let add_signature (env, m) = function
  | Ast.Stypedef (loc, Trecord t) ->
      let env, typ = type_record ~in_sig:true env loc t in
      let m = Module.add_type_sig loc t.name.name typ m in
      (env, m)
  | Stypedef (loc, Talias (name, type_spec)) ->
      let env, typ = type_alias ~in_sig:true env loc name type_spec in
      let m = Module.add_type_sig loc name.name typ m in
      (env, m)
  | Stypedef (loc, Tvariant v) ->
      let env, typ = type_variant ~in_sig:true env loc v in
      let m = Module.add_type_sig loc v.name.name typ m in
      (env, m)
  | Svalue (loc, ((l, n), type_spec)) ->
      (* Here, we don't add to env. We later check that the declaration is implemented correctly,
         in [validate_signatur] *)
      let typ = typeof_annot env l type_spec in
      let m = Module.add_value_sig loc (Path.Pid n) typ m in
      (env, m)

let rec catch_weak_vars = function
  | Tl_let (_, _, e) | Tl_bind (_, e) | Tl_expr e ->
      catch_weak_expr Sset.empty e
  | Tl_function (_, _, _, abs) -> catch_weak_body Sset.empty abs
  | Tl_mutual_rec_decls _ -> ()

and catch_weak_body sub abs =
  (* Allow the types present in the function signature *)
  let ret = get_generic_ids abs.func.ret in
  let l =
    List.fold_left (fun s p -> get_generic_ids p.pt @ s) ret abs.func.tparams
  in
  let sub = Sset.union sub (Sset.of_list l) in
  catch_weak_expr sub abs.body

and catch_weak_expr sub e =
  let _raise () =
    (* print_endline (show_expr e.expr); *)
    (* print_endline (show_typ e.typ); *)
    raise
      (Error
         ( e.loc,
           "Expression contains weak type variables: " ^ string_of_type e.typ ))
  in
  if is_weak ~sub e.typ then _raise ();
  match e.expr with
  | Var _ | Const _ | Lambda _ -> ()
  | Bop (_, e1, e2) | Set (e1, e2) | Sequence (e1, e2) ->
      catch_weak_expr sub e1;
      catch_weak_expr sub e2
  | Unop (_, e)
  | Field (e, _)
  | Ctor (_, _, Some e)
  | Variant_index e
  | Variant_data e
  | Mutual_rec_decls (_, e) ->
      catch_weak_expr sub e
  | Function (_, _, abs, e) ->
      catch_weak_body sub abs;
      catch_weak_expr sub e
  | If (cond, e1, e2) ->
      catch_weak_expr sub cond;
      catch_weak_expr sub e1;
      catch_weak_expr sub e2
  | Let { lhs; cont; _ } | Bind (_, _, lhs, cont) ->
      catch_weak_expr sub lhs;
      catch_weak_expr sub cont
  | App { callee; args } ->
      catch_weak_expr sub callee;
      List.iter (fun a -> catch_weak_expr sub (fst a)) args
  | Record fs -> List.iter (fun f -> catch_weak_expr sub (snd f)) fs
  | Ctor _ -> ()
  | Fmt fmt ->
      List.iter (function Fstr _ -> () | Fexpr e -> catch_weak_expr sub e) fmt

(* Conversion to Typing.exr below *)
let to_typed ?(check_ret = true) ~modul msg_fn ~prelude (sign, prog) =
  fmt_msg_fn := Some msg_fn;
  reset_type_vars ();

  let loc = Lexing.(dummy_pos, dummy_pos) in
  (* Add builtins to env *)
  let env =
    Builtin.(
      fold (fun env (_, typ, str) ->
          enter_level ();
          let typ = instantiate typ in
          leave_level ();
          Env.(add_value str { def_value with typ = generalize typ } loc env)))
      (Env.empty ())
  in

  (* Open prelude *)
  let env =
    if prelude then
      let prelude = Module.read_exn ~regeneralize "prelude" loc in
      Module.add_to_env env "prelude" prelude
    else env
  in

  (* We create a new scope so we don't warn on unused imports *)
  let env = Env.open_function env in

  let env, m = List.fold_left add_signature (env, Module.empty) sign in
  let last_type, env, items, m = convert_prog env prog m in
  let externals = Module.append_externals (Env.externals env) in
  let m = Module.validate_signature env m in

  (* Catch weak type variables *)
  List.iter catch_weak_vars items;

  (* Add polymorphic functions from imported modules *)
  let items = List.rev !Module.poly_funcs @ items in

  let _, _, unused = Env.close_function env in
  if not modul then check_unused unused;

  (* Program must evaluate to either int or unit *)
  (if check_ret then
   match clean last_type with
   | Tunit | Tint -> ()
   | _ ->
       let msg =
         "Program must return type int or unit, not " ^ string_of_type last_type
       in
       raise (Error (!last_loc, msg)));

  (* print_endline (String.concat ", " (List.map string_of_type typeinsts)); *)
  let m = if modul then Some m else None in
  ({ externals; items }, m)

let typecheck (prog : Ast.prog) =
  let rec get_last_type = function
    | Tl_expr expr :: _ -> expr.typ
    | (Tl_function _ | Tl_let _ | Tl_bind _ | Tl_mutual_rec_decls _) :: tl ->
        get_last_type tl
    | [] -> Tunit
  in

  (* Ignore unused binding warnings *)
  let msg_fn _ _ _ = "" in
  let modul = false in
  let tree, _ = to_typed ~modul ~check_ret:false msg_fn ~prelude:false prog in
  let typ = get_last_type (List.rev tree.items) in
  print_endline (show_typ typ);
  typ
