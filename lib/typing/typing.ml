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
          | Env.Unused -> "Unused"
          | Unmutated -> "Unmutated mutable"
        in
        (Option.get !fmt_msg_fn) "warning" loc (warn_kind ^ " binding " ^ name)
        |> print_endline
      in
      List.iter err errors

let string_of_bop = function
  | Ast.Plus_i -> "+"
  | Mult_i -> "*"
  | Div_i -> "/"
  | Less_i -> "<"
  | Greater_i -> ">"
  | Equal_i -> ""
  | Minus_i -> "-"
  | Ast.Plus_f -> "+."
  | Mult_f -> "*."
  | Div_f -> ">."
  | Less_f -> "<."
  | Greater_f -> ">."
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

and get_generic_id loc = function
  | Tvar { contents = Link t } | Talias (_, t) -> get_generic_id loc t
  | Trecord (Qvar id :: _, _, _)
  | Trecord (Tvar { contents = Unbound (id, _) } :: _, _, _)
  | Tvariant (Qvar id :: _, _, _)
  | Tvariant (Tvar { contents = Unbound (id, _) } :: _, _, _)
  | Traw_ptr (Qvar id)
  | Traw_ptr (Tvar { contents = Unbound (id, _) })
  | Tarray (Qvar id)
  | Tarray (Tvar { contents = Unbound (id, _) }) ->
      id
  | Trecord (_ :: tl, _, _) | Tvariant (_ :: tl, _, _) ->
      get_generic_id loc (Trecord (tl, Some "", [||]))
  | t ->
      raise
        (Error (loc, "Expected a parametrized type, not " ^ string_of_type t))

let typeof_annot ?(typedef = false) ?(param = false) env loc annot =
  let fn_kind = if param then Closure [] else Simple in

  let find env t tick =
    match Env.find_type_opt t env with
    | Some t -> t
    | None -> raise (Error (loc, "Unbound type " ^ tick ^ t ^ "."))
  in

  let rec is_quantified = function
    | Trecord ([], _, _) | Tvariant ([], _, _) -> None
    | Trecord (_, Some name, _) | Tvariant (_, name, _) -> Some name
    | Traw_ptr _ -> Some "raw_ptr"
    | Tarray _ -> Some "array"
    | Talias (name, t) -> (
        let cleaned = clean t in
        match is_quantified cleaned with
        | Some _ when is_polymorphic cleaned -> Some name
        | Some _ | None -> (* When can alias a concrete type *) None)
    | Tvar { contents = Link t } -> is_quantified t
    | _ -> None
  in

  let rec concrete_type env = function
    | Ast.Ty_id "int" -> Tint
    | Ty_id "bool" -> Tbool
    | Ty_id "unit" -> Tunit
    | Ty_id "u8" -> Tu8
    | Ty_id "float" -> Tfloat
    | Ty_id "i32" -> Ti32
    | Ty_id "f32" -> Tf32
    | Ty_id t -> find env t ""
    | Ty_var id when typedef -> find env id "'"
    | Ty_var id ->
        (* Type annotation in function *)
        Qvar id
    | Ty_func l -> handle_func env l
    | Ty_list l -> type_list env l
    | Ty_open_id (loc, spec, modul) ->
        let modul = Module.read_exn ~regeneralize modul loc in
        let env = Module.add_to_env env modul in
        concrete_type env spec
  and type_list env = function
    | [] -> failwith "Internal Error: Type param list should not be empty"
    | [ Ty_id "raw_ptr" ] ->
        raise (Error (loc, "Type raw_ptr needs a type parameter"))
    | [ Ty_id "array" ] ->
        raise (Error (loc, "Type array needs a type parameter"))
    | [ t ] -> (
        let t = concrete_type env t in
        match is_quantified t with
        | Some name ->
            raise (Error (loc, "Type " ^ name ^ " needs a type parameter"))
        | None -> t)
    | lst -> container_t env lst
  and container_t env lst =
    match lst with
    | [] -> failwith "Internal Error: Type record list should not be empty"
    | [ t ] -> concrete_type env t
    | Ty_id "raw_ptr" :: tl ->
        let nested = container_t env tl in
        Traw_ptr nested
    | Ty_id "array" :: tl ->
        let nested = container_t env tl in
        Tarray nested
    | hd :: tl ->
        let t = concrete_type env hd in
        let nested = container_t env tl in
        let subst = subst_generic ~id:(get_generic_id loc t) nested t in
        subst
  and handle_func env = function
    | [] -> failwith "Internal Error: Type annot list should not be empty"
    | [ (t, _) ] -> concrete_type env t
    | [ (Ast.Ty_id "unit", _); (t, _) ] ->
        Tfun ([], concrete_type env t, fn_kind)
    | [ (Ast.Ty_list [ Ast.Ty_id "unit" ], _); (t, _) ] ->
        Tfun ([], concrete_type env t, fn_kind)
    (* For function definiton and application, 'unit' means an empty list.
       It's easier for typing and codegen to treat unit as a special case here *)
    | l -> (
        (* We reverse the list times :( *)
        match List.rev l with
        | (last, _) :: head ->
            Tfun
              (* TODO figure out type spec syntax for mutability *)
              ( List.map
                  (fun (s, pmut) -> { pt = concrete_type env s; pmut })
                  (List.rev head),
                concrete_type env last,
                fn_kind )
        | [] -> failwith ":)")
  in
  concrete_type env annot

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

let handle_params env loc (params : Ast.decl list) ret =
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
    (fun env { Ast.loc; ident = idloc, id; mut; annot } ->
      let type_id, qparams =
        match annot with
        | None ->
            let t = newvar () in
            (t, t)
        | Some annot -> handle (typeof_annot ~param:true env loc annot)
      in
      (* Might be const, but not important here *)
      ( Env.add_value id
          {
            typ = type_id;
            const = false;
            param = true;
            global = false;
            imported = false;
            mut;
          }
          idloc env,
        ({ pt = type_id; pmut = mut }, { pt = qparams; pmut = mut }) ))
    env params
  |> fun (env, lst) ->
  let ids, qparams = List.split lst in
  let ret = Option.map (fun t -> typeof_annot env loc t) ret in
  (env, ids, qparams, ret)

let get_prelude env loc name =
  let typ =
    match Env.find_type_opt name env with
    | Some t -> t
    | None -> raise (Error (loc, "Cannot find type string. Prelude is missing"))
  in
  typ

let check_type_unique env loc name =
  match Env.find_type_opt name env with
  | Some _ ->
      let msg =
        Printf.sprintf
          "Type names in a module must be unique. %s exists already" name
      in
      raise (Error (loc, msg))
  | None -> ()

let add_type_param env ts =
  List.fold_left_map
    (fun env name ->
      (* Create general type *)
      enter_level ();
      let typ = newvar () in
      leave_level ();
      let t = generalize typ in

      (Env.add_type name t env, t))
    env ts

let type_record env loc Ast.{ name = { poly_param; name }; labels } =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
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
  Env.add_record name ~params ~labels env

let type_alias env loc { Ast.poly_param; name } type_spec =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
  (* Temporarily add polymorphic type name to env *)
  let temp_env, _ = add_type_param env poly_param in
  let typ = typeof_annot ~typedef:true temp_env loc type_spec in
  Env.add_alias name typ env

let type_variant env loc { Ast.name = { poly_param; name }; ctors } =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
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
  Env.add_variant name ~params ~ctors env

let dont_allow_closure_return loc fn =
  let rec error_on_closure = function
    | Tfun (_, _, Closure _) ->
        raise (Error (loc, "Cannot (yet) return a closure"))
    | Tvar { contents = Link typ } | Talias (_, typ) -> error_on_closure typ
    | _ -> ()
  in
  error_on_closure fn

let rec param_funcs_as_closures = function
  (* Functions passed as parameters need to have an empty closure, otherwise they cannot
     be captured (see above). Kind of sucks *)
  | Tvar { contents = Link t } | Talias (_, t) ->
      (* This shouldn't break type inference *) param_funcs_as_closures t
  | Tfun (_, _, Closure _) as t -> t
  | Tfun (params, ret, _) -> Tfun (params, ret, Closure [])
  | t -> t

let convert_simple_lit typ expr =
  { typ; expr = Const expr; attr = { no_attr with const = true } }

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
    Env.t * typed_expr * bool

  val convert_function :
    Env.t -> Ast.loc -> Ast.func -> Env.t * (string * int option * abstraction)
end = struct
  open Records
  open Patternmatch

  let rec convert env expr = convert_annot env None expr

  and convert_annot env annot = function
    | Ast.Var (loc, id) -> convert_var env loc id
    | Lit (_, Int i) -> convert_simple_lit Tint (Int i)
    | Lit (_, Bool b) -> convert_simple_lit Tbool (Bool b)
    | Lit (_, U8 c) -> convert_simple_lit Tu8 (U8 c)
    | Lit (_, Float f) -> convert_simple_lit Tfloat (Float f)
    | Lit (_, I32 i) -> convert_simple_lit Ti32 (I32 i)
    | Lit (_, F32 i) -> convert_simple_lit Tf32 (F32 i)
    | Lit (loc, String s) ->
        let typ = get_prelude env loc "string" in
        (* TODO is const, but handled differently right now *)
        { typ; expr = Const (String s); attr = no_attr }
    | Lit (loc, Vector vec) -> convert_vector_lit env loc vec
    | Lit (_, Unit) ->
        { typ = Tunit; expr = Const Unit; attr = { no_attr with const = true } }
    | Lambda (loc, id, e) -> convert_lambda env loc id e
    | Let_e (loc, decl, expr, cont) -> convert_let_e env loc decl expr cont
    | App (loc, e1, e2) -> convert_app ~switch_uni:false env loc e1 e2
    | Bop (loc, bop, es) -> convert_bop env loc bop es
    | Unop (loc, unop, expr) -> convert_unop env loc unop expr
    | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
    | Record (loc, labels) -> convert_record env loc annot labels
    | Tuple (_, exprs) -> convert_tuple env exprs
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
        { typ; expr = Var id; attr }
    | None -> raise (Error (loc, "No var named " ^ id))

  and convert_vector_lit env loc vec =
    let f typ expr =
      let expr = convert env expr in
      unify (loc, "In vector literal:") typ expr.typ;
      (typ, expr)
    in
    let typ, exprs = List.fold_left_map f (newvar ()) vec in

    let vector = get_prelude env loc "vector" in
    let typ = subst_generic ~id:(get_generic_id loc vector) typ vector in
    { typ; expr = Const (Vector exprs); attr = no_attr }

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
        (* TODO 'In let binding' *)
        check_annot loc t.typ t_annot;
        { t with typ = t_annot }

  and convert_let ~global env loc { Ast.loc = _; ident = idloc, id; mut; annot }
      block =
    let e1 = typeof_annot_decl env loc annot block in
    let const = e1.attr.const && not mut in
    ( Env.add_value id
        { Env.def_value with typ = e1.typ; const; global; mut }
        idloc env,
      { e1 with attr = { global; const; mut } },
      e1.attr.mut )

  and convert_let_e env loc decl expr cont =
    let env, lhs, rmut = convert_let ~global:false env loc decl expr in
    let cont = convert env cont in
    let id = snd decl.ident in
    let uniq = if lhs.attr.const then uniq_name id else None in
    let expr = Let { id; uniq; rmut; lhs; cont } in
    { typ = cont.typ; expr; attr = cont.attr }

  and convert_lambda env loc params body =
    let env = Env.open_function env in
    enter_level ();
    let env, params_t, qparams, ret_annot = handle_params env loc params None in

    let body = convert_block env body |> fst in
    leave_level ();
    let _, closed_vars, unused = Env.close_function env in
    let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
    dont_allow_closure_return loc body.typ;
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

        let nparams = List.map (fun (d : Ast.decl) -> snd d.ident) params in
        let func = { tparams; ret; kind } in
        let abs =
          { nparams; body = { body with typ = ret }; func; inline = false }
        in
        let expr = Lambda (lambda_id (), abs) in
        { typ; expr; attr = no_attr }
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and convert_function env loc
      Ast.{ name = nameloc, name; params; return_annot; body; attr } =
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
      (* Recursion allowed for named funcs *)
      Env.(add_value name { def_value with typ = newvar () } nameloc env)
    in

    (* We duplicate some lambda code due to naming *)
    let env = Env.open_function env in
    let body_env, params_t, qparams, ret_annot =
      handle_params env loc params return_annot
    in

    let body = convert_block body_env body |> fst in
    leave_level ();

    let env, closed_vars, unused = Env.close_function env in

    let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
    dont_allow_closure_return loc body.typ;
    check_unused unused;

    (* For codegen: Mark functions in parameters closures *)
    let params_t =
      List.map (fun p -> { p with pt = param_funcs_as_closures p.pt }) params_t
    in

    let typ = Tfun (params_t, body.typ, kind) |> generalize in

    match typ with
    | Tfun (tparams, ret, kind) ->
        (* Make sure the types match *)
        unify (loc, "Function") (Env.find_val name env).typ typ;

        (* Add the generalized type to the env to keep the closure there *)
        let env = Env.change_type name typ env in

        let ret = match ret_annot with Some ret -> ret | None -> ret in
        let qtyp = Tfun (qparams, ret, kind) |> generalize in
        check_annot loc typ qtyp;

        let nparams = List.map (fun (d : Ast.decl) -> snd d.ident) params in
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
          (e, a.amut))
        args
    in
    let args_t = List.map (fun (a, pmut) -> { pmut; pt = a.typ }) typed_exprs in
    let res_t = newvar () in
    if switch_uni then
      unify (loc, "Application:") (Tfun (args_t, res_t, Simple)) callee.typ
    else unify (loc, "Application:") callee.typ (Tfun (args_t, res_t, Simple));

    let apply param (texpr, mut) = ({ texpr with typ = param.pt }, mut) in
    let targs = List.map2 apply args_t typed_exprs in

    (* For now, we don't support const functions *)
    { typ = res_t; expr = App { callee; args = targs }; attr = no_attr }

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
      | Less_i | Equal_i | Greater_i -> (Tbool, check Tint)
      | Plus_f | Mult_f | Minus_f | Div_f -> (Tfloat, check Tfloat)
      | Less_f | Equal_f | Greater_f -> (Tbool, check Tfloat)
      | And | Or -> (Tbool, check Tbool)
    in
    { typ; expr = Bop (bop, t1, t2); attr = { no_attr with const } }

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
        { typ = Tfloat; expr = Unop (unop, e); attr = e.attr }
    | Uminus_i -> (
        let e = convert env expr in
        let msg = "Unary -:" in
        let expr = Unop (unop, e) in

        try
          (* We allow '-' to also work on float expressions *)
          unify (loc, msg) Tfloat e.typ;
          { typ = Tfloat; expr; attr = e.attr }
        with Error _ -> (
          try
            unify (loc, msg) Tint e.typ;
            { typ = Tint; expr; attr = e.attr }
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
            {
              typ = Tunit;
              expr = Const Unit;
              attr = { no_attr with const = true };
            }
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
    { typ = Tunit; expr = Set (toset, valexpr); attr = no_attr }

  and convert_pipe_head env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | Pip_expr (App (_, callee, args)) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (e1 :: args)
    | Pip_expr (Ctor (_, name, expr)) ->
        if Option.is_some expr then raise (Error (loc, pipe_ctor_msg));
        convert_ctor env loc name (Some e1.aexpr) None
    | Pip_expr (Bop (_, op, exprs)) -> convert_bop env loc op (e1.aexpr :: exprs)
    | Pip_expr e2 ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]
    | Pip_field field -> convert_field env loc e1.aexpr field

  and convert_pipe_tail env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | Pip_expr (App (_, callee, args)) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (args @ [ e1 ])
    | Pip_expr (Ctor (_, name, expr)) ->
        if Option.is_some expr then raise (Error (loc, pipe_ctor_msg));
        convert_ctor env loc name (Some e1.aexpr) None
    | Pip_expr (Bop (_, op, exprs)) ->
        convert_bop env loc op (exprs @ [ e1.aexpr ])
    | Pip_expr e2 ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]
    | Pip_field field -> convert_field env loc e1.aexpr field

  and convert_open env loc modul expr =
    let modul = Module.read_exn ~regeneralize modul loc in
    let env = Module.add_to_env env modul in
    convert env expr

  and convert_tuple env exprs =
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
    let typs = List.map (fun e -> (snd e).typ) exprs in
    let typ = Trecord (typs, None, Array.of_list fields) in
    let attr = { const; global = false; mut = false } in
    { typ; expr = Record exprs; attr }

  and convert_fmt env loc exprs =
    let f expr =
      let e = convert env expr in
      match (e.expr, clean e.typ) with
      | Const (String s), _ -> Fstr s
      | _, Trecord (_, Some name, _) when String.equal name "string" -> Fexpr e
      | _, (Tint | Tfloat | Tbool | Tu8 | Ti32 | Tf32) -> Fexpr e
      | _, Tvar { contents = Unbound _ } ->
          Fexpr e (* Might be the right type later *)
      | _, _ ->
          print_string (show_typ e.typ);
          failwith "TODO not implemented yet "
    in
    let exprs = List.map f exprs in
    let typ = get_prelude env loc "string" in
    { typ; expr = Fmt exprs; attr = no_attr }

  and convert_block_annot ~ret env annot stmts =
    let loc = Lexing.(dummy_pos, dummy_pos) in

    let check (loc, typ) =
      unify (loc, "Left expression in sequence must be of type unit:") Tunit typ
    in

    let rec to_expr env old_type = function
      | ([ Ast.Let (loc, _, _) ] | [ Function (loc, _) ]) when ret ->
          raise (Error (loc, "Block must end with an expression"))
      | [] when ret -> raise (Error (loc, "Block cannot be empty"))
      | [] -> ({ typ = Tunit; expr = Const Unit; attr = no_attr }, env)
      | Let (loc, decl, block) :: tl ->
          let env, lhs, rmut = convert_let ~global:false env loc decl block in
          let cont, env = to_expr env old_type tl in
          let id = snd decl.ident in
          let uniq = if lhs.attr.const then uniq_name id else None in
          let expr = Let { id; uniq; rmut; lhs; cont } in
          ({ typ = cont.typ; expr; attr = cont.attr }, env)
      | Function (loc, func) :: tl ->
          let env, (name, unique, lambda) = convert_function env loc func in
          let cont, env = to_expr env old_type tl in
          let expr = Function (name, unique, lambda, cont) in
          ({ typ = cont.typ; expr; attr = cont.attr }, env)
      | [ Expr (loc, e) ] ->
          last_loc := loc;
          check old_type;
          (convert_annot env annot e, env)
      | Expr (l1, e1) :: tl ->
          check old_type;
          let expr = convert env e1 in
          let cont, env = to_expr env (l1, expr.typ) tl in
          ( { typ = cont.typ; expr = Sequence (expr, cont); attr = cont.attr },
            env )
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
        let m = Module.add_external typ id cname m in
        (Env.add_external id ~cname typ ~imported:None idloc env, items, m)
    | Typedef (loc, Trecord t) ->
        let env = type_record env loc t in
        let m = Module.add_type (Env.find_type t.name.name env) m in
        (env, items, m)
    | Typedef (loc, Talias (name, type_spec)) ->
        let env = type_alias env loc name type_spec in
        let m = Module.add_type (Env.find_type name.name env) m in
        (env, items, m)
    | Typedef (loc, Tvariant v) ->
        let env = type_variant env loc v in
        let m = Module.add_type (Env.find_type v.name.name env) m in
        (env, items, m)
    | Open (loc, modul) ->
        let modul = Module.read_exn ~regeneralize modul loc in
        let env = Module.add_to_env env modul in
        (env, items, m)
  and aux_stmt (old, env, items, m) = function
    (* TODO dedup *)
    | Ast.Let (loc, decl, block) ->
        let env, lhs, _ = Core.convert_let ~global:true env loc decl block in
        let id = snd decl.ident in
        let uniq = uniq_name id in
        (* Make string option out of int option for unique name *)
        let uniq_name =
          match uniq with
          | None -> None
          | Some i -> Some (Module.unique_name id (Some i))
        in
        let m = Module.add_external lhs.typ id uniq_name m in
        (old, env, Tl_let (id, uniq, lhs) :: items, m)
    | Function (loc, func) ->
        let env, (name, unique, abs) = Core.convert_function env loc func in
        let m = Module.add_fun name unique abs m in
        (old, env, Tl_function (name, unique, abs) :: items, m)
    | Expr (loc, expr) ->
        let expr = Core.convert env expr in
        (* Only the last expression is allowed to return something *)
        unify
          (fst old, "Left expression in sequence must be of type unit:")
          Tunit (snd old);
        ((loc, expr.typ), env, Tl_expr expr :: items, m)
  in

  let env, items, m = List.fold_left aux (env, [], modul) items in
  (snd !old, env, List.rev items, m)

(* Conversion to Typing.exr below *)
let to_typed ?(check_ret = true) ~modul msg_fn ~prelude (prog : Ast.prog) =
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
      Module.add_to_env env prelude
    else env
  in

  (* We create a new scope so we don't warn on unused imports *)
  let env = Env.open_function env in

  let last_type, env, items, m = convert_prog env prog [] in
  (* TODO test wrong return type *)
  let externals = Env.externals env in

  (* Add polymorphic functions from imported modules *)
  let items = List.rev !Module.poly_funcs @ items in

  let _, _, unused = Env.close_function env in
  if not modul then check_unused unused;

  (* Program must evaluate to either int or unit *)
  (if check_ret then
   match clean last_type with
   | Tunit | Tint -> ()
   | t ->
       let msg =
         "Program must return type int or unit, not " ^ string_of_type t
       in
       raise (Error (!last_loc, msg)));

  (* print_endline (String.concat ", " (List.map string_of_type typeinsts)); *)
  let m = if modul then Some m else None in
  ({ externals; items }, m)

let typecheck (prog : Ast.prog) =
  let rec get_last_type = function
    | Tl_expr expr :: _ -> expr.typ
    | (Tl_function _ | Tl_let _) :: tl -> get_last_type tl
    | [] -> Tunit
  in

  (* Ignore unused binding warnings *)
  let msg_fn _ _ _ = "" in
  let modul = false in
  let tree, _ = to_typed ~modul ~check_ret:false msg_fn ~prelude:false prog in
  let typ = get_last_type (List.rev tree.items) in
  print_endline (show_typ typ);
  typ
