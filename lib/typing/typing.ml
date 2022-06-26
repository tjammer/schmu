open Types
open Typed_tree
open Inference

type external_decl = string * Types.typ * string option

type codegen_tree = {
  externals : external_decl list;
  typedefs : Types.typ list;
  items : Typed_tree.toplevel_item list;
}

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
let func_tbl = Strtbl.create 1

let next_func name tbl =
  match Strtbl.find_opt tbl name with
  | None ->
      Strtbl.add tbl name 1;
      None
  | Some n ->
      Strtbl.replace tbl name (n + 1);
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
  Strtbl.clear func_tbl

let last_loc = ref (Lexing.dummy_pos, Lexing.dummy_pos)

(*
  Helper functions
*)

let is_type_polymorphic typ =
  let rec inner acc = function
    | Qvar _ | Tvar { contents = Unbound _ } -> true
    | Tvar { contents = Link t } | Talias (_, t) -> inner acc t
    | Trecord (Some t, _, _) | Tvariant (Some t, _, _) -> inner acc t
    | Tfun (params, ret, _) ->
        let acc = List.fold_left inner acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Trecord _ | Tvariant _ | Tu8 | Tfloat | Ti32 | Tf32
      ->
        acc
    | Tptr t -> inner acc t
  in
  inner false typ

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
      let err (name, loc) =
        (Option.get !fmt_msg_fn) "warning" loc ("Unused binding " ^ name)
        |> print_endline
      in
      List.iter err errors

let string_of_bop = function
  | Ast.Plus_i -> "+"
  | Mult_i -> "*"
  | Div_i -> "/"
  | Less_i -> "<"
  | Greater_i -> ">"
  | Equal_i -> "=="
  | Minus_i -> "-"
  | Ast.Plus_f -> "+."
  | Mult_f -> "*."
  | Div_f -> ">."
  | Less_f -> "<."
  | Greater_f -> ">."
  | Equal_f -> "==."
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
      let ps = List.map (subst_generic ~id typ) ps in
      let ret = subst_generic ~id typ ret in
      Tfun (ps, ret, kind)
  | Trecord (Some p, name, labels) ->
      let f f = Types.{ f with typ = subst_generic ~id typ f.typ } in
      let labels = Array.map f labels in
      Trecord (Some (subst_generic ~id typ p), name, labels)
  | Tvariant (Some p, name, ctors) ->
      let f c =
        Types.{ c with ctortyp = Option.map (subst_generic ~id typ) c.ctortyp }
      in
      let ctors = Array.map f ctors in
      Tvariant (Some (subst_generic ~id typ p), name, ctors)
  | Tptr t -> Tptr (subst_generic ~id typ t)
  | Talias (name, t) -> Talias (name, subst_generic ~id typ t)
  | t -> t

and get_generic_id loc = function
  | Tvar { contents = Link t } | Talias (_, t) -> get_generic_id loc t
  | Trecord (Some (Qvar id), _, _)
  | Trecord (Some (Tvar { contents = Unbound (id, _) }), _, _)
  | Tvariant (Some (Qvar id), _, _)
  | Tvariant (Some (Tvar { contents = Unbound (id, _) }), _, _)
  | Tptr (Qvar id)
  | Tptr (Tvar { contents = Unbound (id, _) }) ->
      id
  | t ->
      raise
        (Error (loc, "Expected a parametrized type, not " ^ string_of_type t))

let typeof_annot ?(typedef = false) ?(param = false) env loc annot =
  let fn_kind = if param then Closure [] else Simple in

  let find t tick =
    match Env.find_type_opt t env with
    | Some t -> t
    | None -> raise (Error (loc, "Unbound type " ^ tick ^ t ^ "."))
  in

  let rec is_quantified = function
    | Trecord (Some _, name, _) -> Some name
    | Tptr _ -> Some "ptr"
    | Talias (name, t) -> (
        let cleaned = clean t in
        match is_quantified cleaned with
        | Some _ when is_type_polymorphic cleaned -> Some name
        | Some _ | None -> (* When can alias a concrete type *) None)
    | Tvar { contents = Link t } -> is_quantified t
    | _ -> None
  in

  let rec concrete_type = function
    | Ast.Ty_id "int" -> Tint
    | Ty_id "bool" -> Tbool
    | Ty_id "unit" -> Tunit
    | Ty_id "u8" -> Tu8
    | Ty_id "float" -> Tfloat
    | Ty_id "i32" -> Ti32
    | Ty_id "f32" -> Tf32
    | Ty_id t -> find t ""
    | Ty_var id when typedef -> find id "'"
    | Ty_var id ->
        (* Type annotation in function *)
        Qvar id
    | Ty_func l -> handle_annot l
    | Ty_list l -> type_list l
  and type_list = function
    | [] -> failwith "Internal Error: Type param list should not be empty"
    | [ Ty_id "ptr" ] -> raise (Error (loc, "Type ptr needs a type parameter"))
    | [ t ] -> (
        let t = concrete_type t in
        match is_quantified t with
        | Some name ->
            raise (Error (loc, "Type " ^ name ^ " needs a type parameter"))
        | None -> t)
    | lst -> container_t lst
  and container_t lst =
    match lst with
    | [] -> failwith "Internal Error: Type record list should not be empty"
    | [ t ] -> concrete_type t
    | Ty_id "ptr" :: tl ->
        let nested = container_t tl in
        Tptr nested
    | hd :: tl ->
        let t = concrete_type hd in
        let nested = container_t tl in
        let subst = subst_generic ~id:(get_generic_id loc t) nested t in

        (* Add record instance.
           A new instance could be introduced here, we have to make sure it's added b/c
           codegen struct generation depends on order *)
        (match t with
        | Trecord (Some _, _, _) | Tvariant (Some _, _, _) ->
            Env.maybe_add_type_instance (string_of_type subst) subst env
        | _ -> ());
        subst
  and handle_annot = function
    | [] -> failwith "Internal Error: Type annot list should not be empty"
    | [ t ] -> concrete_type t
    | [ Ast.Ty_id "unit"; t ] -> Tfun ([], concrete_type t, fn_kind)
    | [ Ast.Ty_list [ Ast.Ty_id "unit" ]; t ] ->
        Tfun ([], concrete_type t, fn_kind)
    (* For function definiton and application, 'unit' means an empty list.
       It's easier for typing and codegen to treat unit as a special case here *)
    | l -> (
        (* We reverse the list times :( *)
        match List.rev l with
        | last :: head ->
            Tfun
              ( List.map concrete_type (List.rev head),
                concrete_type last,
                fn_kind )
        | [] -> failwith ":)")
  in
  handle_annot annot

let handle_params env loc params ret =
  (* return updated env with bindings for parameters and types of parameters *)
  let rec handle = function
    | Qvar _ as t -> (newvar (), t)
    | Tfun (params, ret, kind) ->
        let params, qparams = List.map handle params |> List.split in
        let ret, qret = handle ret in
        (Tfun (params, ret, kind), Tfun (qparams, qret, kind))
    | t -> (t, t)
  in

  List.fold_left_map
    (fun env (loc, (idloc, id), type_annot) ->
      let type_id, qparams =
        match type_annot with
        | None ->
            let t = newvar () in
            (t, t)
        | Some annot -> handle (typeof_annot ~param:true env loc annot)
      in
      (* Might be const, but not important here *)
      ( Env.add_value id type_id ~is_const:false ~is_param:true idloc env,
        (type_id, qparams) ))
    env params
  |> fun (env, lst) ->
  let ids, qparams = List.split lst in
  let ret = Option.map (fun t -> typeof_annot env loc [ t ]) ret in
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

let add_type_param env = function
  | Some name ->
      (* Create general type *)
      enter_level ();
      let typ = newvar () in
      leave_level ();
      let t = generalize typ in

      (Env.add_type name t env, Some t)
  | None -> (env, None)

let type_record env loc Ast.{ name = { poly_param; name }; labels } =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
  let labels, param =
    (* Temporarily add polymorphic type name to env *)
    let env, param = add_type_param env poly_param in
    let labels =
      Array.map
        (fun (mut, name, type_expr) ->
          let typ = typeof_annot ~typedef:true env loc type_expr in
          { name; typ; mut })
        labels
    in
    (labels, param)
  in
  Env.add_record name ~param ~labels env

let type_alias env loc { Ast.poly_param; name } type_spec =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
  (* Temporarily add polymorphic type name to env *)
  let temp_env, _ = add_type_param env poly_param in
  let typ = typeof_annot ~typedef:true temp_env loc [ type_spec ] in
  Env.add_alias name typ env

let type_variant env loc { Ast.name = { poly_param; name }; ctors } =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
  (* Temporarily add polymorphic type name to env *)
  let temp_env, param = add_type_param env poly_param in
  let ctors =
    List.map
      (fun { Ast.name = _, ctorname; typ_annot } ->
        match typ_annot with
        | None ->
            (* Just a ctor, without data *)
            { ctorname; ctortyp = None }
        | Some annot ->
            let typ = typeof_annot ~typedef:true temp_env loc [ annot ] in
            { ctorname; ctortyp = Some typ })
      ctors
    |> Array.of_list
  in
  Env.add_variant name ~param ~ctors env

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

let convert_simple_lit typ expr = { typ; expr = Const expr; is_const = true }

module rec Core : sig
  val convert : Env.t -> Ast.expr -> typed_expr

  val convert_annot :
    Env.t -> Types.typ option -> Ast.expr -> Typed_tree.typed_expr

  val convert_var : Env.t -> Ast.loc -> string -> typed_expr
  val convert_block : ?ret:bool -> Env.t -> Ast.block -> typed_expr * Env.t

  val convert_let :
    Env.t -> Ast.loc -> Ast.decl -> Ast.block -> Env.t * typed_expr

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
        { typ; expr = Const (String s); is_const = false }
    | Lit (loc, Vector vec) -> convert_vector_lit env loc vec
    | Lit (_, Unit) -> { typ = Tunit; expr = Const Unit; is_const = true }
    | Lambda (loc, id, e) -> convert_lambda env loc id e
    | App (loc, e1, e2) -> convert_app ~switch_uni:false env loc e1 e2
    | Bop (loc, bop, e1, e2) -> convert_bop env loc bop e1 e2
    | Unop (loc, unop, expr) -> convert_unop env loc unop expr
    | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
    | Record (loc, labels) -> convert_record env loc annot labels
    | Field (loc, expr, id) -> convert_field env loc expr id
    | Field_set (loc, expr, id, value) ->
        convert_field_set env loc expr id value
    | Pipe_head (loc, e1, e2) -> convert_pipe_head env loc e1 e2
    | Pipe_tail (loc, e1, e2) -> convert_pipe_tail env loc e1 e2
    | Ctor (loc, name, args) -> convert_ctor env loc name args annot
    | Match (loc, exprs, cases) -> convert_match env loc exprs cases

  and convert_var env loc id =
    match Env.query_val_opt id env with
    | Some t ->
        let typ = instantiate t.typ in
        { typ; expr = Var id; is_const = t.is_const }
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
    Env.maybe_add_type_instance (string_of_type typ) typ env;
    { typ; expr = Const (Vector exprs); is_const = false }

  and typeof_annot_decl env loc annot block =
    enter_level ();
    match annot with
    | None ->
        let t = convert_block env block |> fst in
        leave_level ();
        (* We generalize functions, but allow weak variables for value types *)
        let typ =
          match clean t.typ with Tfun _ -> generalize t.typ | _ -> t.typ
        in
        { t with typ }
    | Some annot ->
        let t_annot = typeof_annot env loc annot in
        let t = convert_block_annot ~ret:true env (Some t_annot) block |> fst in
        leave_level ();
        (* TODO 'In let binding' *)
        check_annot loc t.typ t_annot;
        { t with typ = t_annot }

  and convert_let env loc (_, (idloc, id), type_annot) block =
    let e1 = typeof_annot_decl env loc type_annot block in
    (Env.add_value id e1.typ ~is_const:e1.is_const idloc env, e1)

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
    let params_t = List.map param_funcs_as_closures params_t in

    let typ = Tfun (params_t, body.typ, kind) in
    match typ with
    | Tfun (tparams, ret, kind) ->
        let ret = match ret_annot with Some ret -> ret | None -> ret in
        let qtyp = Tfun (qparams, ret, kind) in
        check_annot loc typ qtyp;

        let nparams = List.map (fun (_, name, _) -> snd name) params in
        let tp = { tparams; ret; kind } in
        let abs = { nparams; body = { body with typ = ret }; tp } in
        let expr = Lambda (lambda_id (), abs) in
        { typ; expr; is_const = false }
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and convert_function env loc
      Ast.{ name = nameloc, name; params; return_annot; body } =
    (* Create a fresh type var for the function name
       and use it in the function body *)
    let unique = next_func name func_tbl in

    enter_level ();
    let env =
      (* Recursion allowed for named funcs *)
      Env.add_value name (newvar ()) nameloc env
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
    let params_t = List.map param_funcs_as_closures params_t in

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

        let nparams = List.map (fun (_, name, _) -> snd name) params in
        let tp = { tparams; ret; kind } in
        let lambda = { nparams; body = { body with typ = ret }; tp } in

        (env, (name, unique, lambda))
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and convert_app ~switch_uni env loc e1 args =
    let callee = convert env e1 in

    let typed_exprs = List.map (convert env) args in
    let args_t = List.map (fun a -> a.typ) typed_exprs in
    let res_t = newvar () in
    if switch_uni then
      unify (loc, "Application:") (Tfun (args_t, res_t, Simple)) callee.typ
    else unify (loc, "Application:") callee.typ (Tfun (args_t, res_t, Simple));

    let apply typ texpr = { texpr with typ } in
    let targs = List.map2 apply args_t typed_exprs in

    (* For now, we don't support const functions *)
    { typ = res_t; expr = App { callee; args = targs }; is_const = false }

  and convert_bop env loc bop e1 e2 =
    let check typ =
      let t1 = convert env e1 in
      let t2 = convert env e2 in

      unify (loc, "Binary " ^ string_of_bop bop) typ t1.typ;
      unify (loc, "Binary " ^ string_of_bop bop) t1.typ t2.typ;
      (t1, t2, t1.is_const && t2.is_const)
    in

    let typ, (t1, t2, is_const) =
      match bop with
      | Ast.Plus_i | Mult_i | Minus_i | Div_i -> (Tint, check Tint)
      | Less_i | Equal_i | Greater_i -> (Tbool, check Tint)
      | Plus_f | Mult_f | Minus_f | Div_f -> (Tfloat, check Tfloat)
      | Less_f | Equal_f | Greater_f -> (Tbool, check Tfloat)
      | And | Or -> (Tbool, check Tbool)
    in
    { typ; expr = Bop (bop, t1, t2); is_const }

  and convert_unop env loc unop expr =
    match unop with
    | Uminus_f ->
        let e = convert env expr in
        unify (loc, "Unary -.:") Tfloat e.typ;
        { typ = Tfloat; expr = Unop (unop, e); is_const = e.is_const }
    | Uminus_i -> (
        let e = convert env expr in
        let msg = "Unary -:" in
        let expr = Unop (unop, e) in

        try
          (* We allow '-' to also work on float expressions *)
          unify (loc, msg) Tfloat e.typ;
          { typ = Tfloat; expr; is_const = e.is_const }
        with Error _ -> (
          try
            unify (loc, msg) Tint e.typ;
            { typ = Tint; expr; is_const = e.is_const }
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
    let type_e1 = convert_block env e1 |> fst in
    let type_e2 =
      (* We unify in the pattern match to have different messages and unification order *)
      match e2 with
      | Some e2 ->
          let msg = "Branches have different type:" in
          let e2 = convert_block env e2 |> fst in
          unify (loc, msg) type_e1.typ e2.typ;
          e2
      | None ->
          let msg =
            "A conditional without else branch should evaluato to type unit."
          in
          let e2 = { typ = Tunit; expr = Const Unit; is_const = true } in
          unify (loc, msg) e2.typ type_e1.typ;
          e2
    in

    (* We don't support polymorphic lambdas in if-exprs in the monomorph backend yet *)
    (match type_e2.typ with
    | Tfun (_, _, _) as t when is_type_polymorphic t ->
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
      is_const = false;
    }

  and convert_pipe_head env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | App (_, callee, args) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (e1 :: args)
    | _ ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]

  and convert_pipe_tail env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | App (_, callee, args) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (args @ [ e1 ])
    | _ ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]

  and convert_block_annot ~ret env annot stmts =
    let loc = Lexing.(dummy_pos, dummy_pos) in

    let check (loc, typ) =
      unify (loc, "Left expression in sequence must be of type unit:") Tunit typ
    in

    let rec to_expr env old_type = function
      | ([ Ast.Let (loc, _, _) ] | [ Function (loc, _) ]) when ret ->
          raise (Error (loc, "Block must end with an expression"))
      | [] when ret -> raise (Error (loc, "Block cannot be empty"))
      | [] -> ({ typ = Tunit; expr = Const Unit; is_const = false }, env)
      | Let (loc, decl, block) :: tl ->
          let env, texpr = convert_let env loc decl block in
          let cont, env = to_expr env old_type tl in
          let decl = (fun (_, a, b) -> (snd a, b)) decl in
          let expr = Let (fst decl, texpr, cont) in
          ({ typ = cont.typ; expr; is_const = cont.is_const }, env)
      | Function (loc, func) :: tl ->
          let env, (name, unique, lambda) = convert_function env loc func in
          let cont, env = to_expr env old_type tl in
          let expr = Function (name, unique, lambda, cont) in
          ({ typ = cont.typ; expr; is_const = false }, env)
      | [ Expr (loc, e) ] ->
          last_loc := loc;
          check old_type;
          (convert_annot env annot e, env)
      | Expr (l1, e1) :: tl ->
          check old_type;
          let expr = convert env e1 in
          let cont, env = to_expr env (l1, expr.typ) tl in
          ( {
              typ = cont.typ;
              expr = Sequence (expr, cont);
              is_const = cont.is_const;
            },
            env )
    in
    to_expr env (loc, Tunit) stmts

  and convert_block ?(ret = true) env stmts =
    convert_block_annot ~ret env None stmts
end

and Records : Recs.S = Recs.Make (Core)
and Patternmatch : Pm.S = Pm.Make (Core)

let block_external_name loc ~cname id =
  (* We have to deal with shadowing:
     If there is no function with the same name, we make sure
     all future function use different names internally (via [func_tbl]).
     If there already is a function, there is nothing we can do right now,
     so we error *)
  let name = match cname with Some name -> name | None -> id in
  match Strtbl.find_opt func_tbl name with
  | None ->
      (* Good, block this name. NOTE see [next_func] *)
      Strtbl.add func_tbl name 1
  | Some _ ->
      let msg =
        Printf.sprintf
          "External function name %s already in use. This is not supported \
           yet, make sure to define the external function first"
          name
      in
      raise (Error (loc, msg))

let convert_prog env ~prelude items =
  let old = ref (Lexing.(dummy_pos, dummy_pos), Tunit) in

  let rec aux (env, items) = function
    | Ast.Block block ->
        let old', env, items =
          List.fold_left aux_block (!old, env, items) block
        in
        old := old';
        (env, items)
    | Ext_decl (loc, (idloc, id), typ, cname) ->
        let typ = typeof_annot env loc typ in
        block_external_name loc ~cname id;
        (Env.add_external id ~cname typ idloc env, items)
    | Typedef (loc, Trecord t) -> (type_record env loc t, items)
    | Typedef (loc, Talias (name, type_spec)) ->
        (type_alias env loc name type_spec, items)
    | Typedef (loc, Tvariant v) -> (type_variant env loc v, items)
  and aux_block (old, env, items) = function
    (* TODO dedup *)
    | Ast.Let (loc, decl, block) ->
        let env, texpr = Core.convert_let env loc decl block in
        let decl = (fun (_, a, b) -> (snd a, b)) decl in
        (old, env, Tl_let (fst decl, texpr) :: items)
    | Function (loc, func) ->
        let env, (name, unique, lambda) = Core.convert_function env loc func in
        (old, env, Tl_function (name, unique, lambda) :: items)
    | Expr (loc, expr) ->
        let expr = Core.convert env expr in
        (* Only the last expression is allowed to return something *)
        unify
          (fst old, "Left expression in sequence must be of type unit:")
          Tunit (snd old);
        ((loc, expr.typ), env, Tl_expr expr :: items)
  in

  let env, items = List.fold_left aux (env, prelude) items in
  (snd !old, env, List.rev items)

(* Conversion to Typing.exr below *)
let to_typed ?(check_ret = true) msg_fn ~prelude (prog : Ast.prog) =
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
          Env.add_value str (generalize typ) loc env))
      (Env.empty string_of_type)
  in

  (* Add prelude *)
  let _, env, prelude = convert_prog env ~prelude:[] prelude in

  (* We create a new scope so we don't warn on unused imports *)
  let env = Env.open_function env in

  let last_type, env, items = convert_prog env ~prelude prog in
  (* TODO test wrong return type *)
  let typedefs = Env.typedefs env and externals = Env.externals env in

  let _, _, unused = Env.close_function env in
  check_unused unused;

  (* Program must evaluate to either int or unit *)
  (if check_ret then
   match clean last_type with
   | Tunit | Tint -> ()
   | t ->
       let msg =
         "Program must return type int or unit, not " ^ string_of_type t
       in
       raise (Error (!last_loc, msg)));

  (* print_endline (String.concat ", " (List.map string_of_type typedefs)); *)
  { externals; typedefs; items }

let typecheck (prog : Ast.prog) =
  let rec get_last_type = function
    | Tl_expr expr :: _ -> expr.typ
    | (Tl_function _ | Tl_let _) :: tl -> get_last_type tl
    | [] -> Tunit
  in

  (* Ignore unused binding warnings *)
  let msg_fn _ _ _ = "" in
  let tree = to_typed ~check_ret:false msg_fn ~prelude:[] prog in
  let typ = get_last_type (List.rev tree.items) in
  print_endline (show_typ typ);
  typ
