type typ =
  | TInt
  | TBool
  | TUnit
  | TVar of tv ref
  | QVar of string
  | TFun of typ list * typ * fun_kind

and fun_kind = Simple | Anon | Closure of (string * typ) list

and tv = Unbound of string * int | Link of typ

type abstraction = {
  params : (string * typ) list;
  body : typed_expr;
  kind : fun_kind;
}

and const = Int of int | Bool of bool | Unit

and expr =
  | Var of string
  | Const of const
  | Bop of Ast.bop * typed_expr * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of string * typed_expr * typed_expr
  | Lambda of abstraction
  | Function of string * int option * abstraction * typed_expr
  | App of typed_expr * typed_expr list

and typed_expr = { typ : typ; expr : expr }

type external_decl = string * typ

exception Error of Ast.loc * string

exception Unify

module Env = Typing_env.Env
module Strset = Set.Make (String)

module Str = struct
  type t = string

  let hash = Hashtbl.hash

  let equal = String.equal
end

module Functbl = Hashtbl.Make (Str)

let func_tbl = Functbl.create 1

let next_func name tbl =
  match Functbl.find_opt tbl name with
  | None ->
      Functbl.add tbl name 1;
      None
  | Some n ->
      Functbl.replace tbl name (n + 1);
      Some (n + 1)

let string_of_type typ =
  let lvl = ref 0 in
  let rec string_of_type = function
    | TInt -> "int"
    | TBool -> "bool"
    | TUnit -> "unit"
    | TFun (ts, t, _) ->
        let lvl_cpy = !lvl in
        incr lvl;
        let func =
          String.concat " -> "
            (List.map string_of_type ts @ [ string_of_type t ])
        in
        if lvl_cpy = 0 then func else "(" ^ func ^ ")"
    | TVar { contents = Unbound (str, _) } ->
        Char.chr (int_of_string str + Char.code 'a') |> String.make 1
    | TVar { contents = Link t } -> string_of_type t
    | QVar str -> str ^ "12"
  in
  string_of_type typ

let gensym_state = ref 0

let reset_gensym () = gensym_state := 0

let gensym () =
  let n = !gensym_state in
  incr gensym_state;
  string_of_int n

let current_level = ref 1

let reset_level () = current_level := 1

let reset_type_vars () =
  reset_gensym ();
  reset_level ()

let enter_level () = incr current_level

let leave_level () = decr current_level

let newvar () = TVar (ref (Unbound (gensym (), !current_level)))

let rec occurs tvr = function
  | TVar tvr' when tvr == tvr' -> failwith "Internal error: Occurs check failed"
  | TVar ({ contents = Unbound (id, lvl') } as tv) ->
      let min_lvl =
        match !tvr with Unbound (_, lvl) -> min lvl lvl' | _ -> lvl'
      in
      tv := Unbound (id, min_lvl)
  | TVar { contents = Link ty } -> occurs tvr ty
  | TFun (param_ts, t, _) ->
      List.iter (occurs tvr) param_ts;
      occurs tvr t
  | _ -> ()

let rec unify t1 t2 =
  if t1 == t2 then ()
  else
    match (t1, t2) with
    | TVar { contents = Link t1 }, t2 | t2, TVar { contents = Link t1 } ->
        unify t1 t2
    | TVar ({ contents = Unbound _ } as tv), t
    | t, TVar ({ contents = Unbound _ } as tv) ->
        occurs tv t;
        tv := Link t
    | TFun (params_l, l, _), TFun (params_r, r, _) ->
        (* TODO deal with different lengths *)
        List.iter2 (fun left right -> unify left right) params_l params_r;
        unify l r
    | _ -> raise Unify

let rec generalize = function
  | TVar { contents = Unbound (id, l) } when l > !current_level -> QVar id
  | TVar { contents = Link t } -> generalize t
  | TFun (t1, t2, k) -> TFun (List.map generalize t1, generalize t2, k)
  | t -> t

let instantiate t =
  let rec aux subst = function
    | QVar id -> (
        match Env.find_opt id subst with
        | Some t -> (t, subst)
        | None ->
            let tv = newvar () in
            (tv, Env.add_value id tv subst))
    | TVar { contents = Link t } -> aux subst t
    | TFun (params_t, t, k) ->
        let subst, params_t =
          List.fold_left_map
            (fun subst param ->
              let t, subst = aux subst param in
              (subst, t))
            subst params_t
        in
        let t, subst = aux subst t in
        (TFun (params_t, t, k), subst)
    | t -> (t, subst)
  in
  aux Env.empty t |> fst

let bop_error loc bop t1 t2 =
  let op =
    match bop with
    | Ast.Plus -> "+"
    | Mult -> "*"
    | Less -> "<"
    | Equal -> "=="
    | Minus -> "-"
  in
  raise
    (Error
       ( loc,
         "Expressions in binary op '" ^ op ^ "' must be both int " ^ "not: "
         ^ string_of_type t1 ^ " vs " ^ string_of_type t2 ))

let typeof_annot loc annot =
  let atom_type = function
    | "int" -> TInt
    | "bool" -> TBool
    | "unit" -> TUnit
    | t ->
        raise (Error (loc, "Unknown type: " ^ t ^ ". Expected 'int' or 'bool'"))
  in
  match annot with
  | [] -> failwith "Internal Error: Type annot list should not be empty"
  | [ t ] -> atom_type t
  | [ "unit"; t ] -> TFun ([], atom_type t, Simple)
  (* For function definiton and application, 'unit' means an empty list.
     It's easier for typing and codegen to treat unit as a special case here *)
  | l -> (
      (* We reverse the list times :( *)
      match List.rev l with
      | last :: head ->
          TFun (List.map atom_type (List.rev head), atom_type last, Simple)
      | [] -> failwith ":)")

let handle_params env loc params =
  (* return updated env with bindings for parameters and types of parameters *)
  List.fold_left_map
    (fun env (id, type_annot) ->
      let type_id =
        match type_annot with
        | None -> newvar ()
        | Some annot -> typeof_annot loc annot
      in
      (Env.add_value id type_id env, type_id))
    env params

let rec typeof env = function
  | Ast.Var (loc, v) -> typeof_var env loc v
  | Int (_, _) -> TInt
  | Bool (_, _) -> TBool
  | Let (loc, x, e1, e2) -> typeof_let env loc x e1 e2
  | Lambda (loc, id, e) -> typeof_abs env loc id e
  | Function (loc, { name; params; body; cont }) ->
      typeof_function env loc name params body cont
  | App (_, e1, e2) -> typeof_app env e1 e2
  | If (loc, cond, e1, e2) -> typeof_if env loc cond e1 e2
  | Bop (loc, bop, e1, e2) -> typeof_bop env loc bop e1 e2

and typeof_var env loc v =
  (* find_opt would work here, but we use query for consistency with convert_var *)
  match Env.query_opt v env with
  | Some t -> instantiate t
  | None -> raise (Error (loc, "No var named " ^ v))

and typeof_let env loc (id, type_annot) e1 e2 =
  enter_level ();
  let type_e =
    match type_annot with
    | None ->
        let type_e = typeof env e1 in
        leave_level ();
        generalize type_e
    | Some annot ->
        let type_annot = typeof_annot loc annot in
        let type_e = typeof env e1 in
        leave_level ();
        unify type_annot type_e;
        type_annot
  in
  typeof (Env.add_value id type_e env) e2

and typeof_abs env loc params e =
  let env, params_t = handle_params env loc params in
  let type_e = typeof env e in
  TFun (params_t, type_e, Anon)

and typeof_function env loc name param body cont =
  (* this loc might not be correct *)
  typeof_let env loc name (Lambda (loc, param, body)) cont

and typeof_app env e1 args =
  let type_fun = typeof env e1 in
  let type_args = List.map (typeof env) args in
  let type_res = newvar () in
  unify type_fun (TFun (type_args, type_res, Simple));
  type_res

and typeof_if env loc cond e1 e2 =
  (* We can assume pred evaluates to bool and both
     branches need to evaluate to the some type *)
  let type_cond = typeof env cond in
  unify type_cond TBool;
  (* TODO catch *)
  let type_e1 = typeof env e1 in
  let type_e2 = typeof env e2 in
  let type_res = newvar () in
  (try unify type_e1 type_e2
   with Unify ->
     raise
       (Error
          ( loc,
            "Branches in if: " ^ string_of_type type_e1 ^ " vs "
            ^ string_of_type type_e2 )));
  unify type_res type_e2;
  type_res

and typeof_bop env loc bop e1 e2 =
  let check () =
    (* both exprs must be Int, not Bool *)
    let t1 = typeof env e1 in
    let t2 = typeof env e2 in
    try
      unify t1 TInt;
      unify t2 TInt
    with Unify -> bop_error loc bop t1 t2
  in
  match bop with
  | Plus | Mult | Minus ->
      check ();
      TInt
  | Less | Equal ->
      check ();
      TBool

let extern_vars decls =
  let externals =
    List.map (fun (loc, name, typ) -> (name, typeof_annot loc typ)) decls
  in
  List.fold_left
    (fun vars (name, typ) -> Env.add_value name typ vars)
    Env.empty externals

let typecheck (prog : Ast.prog) =
  reset_type_vars ();
  typeof (extern_vars prog.external_decls) prog.expr

(* Conversion to Typing.exr below *)

(* TODO Error handling sucks right now *)
let dont_allow_closure_return loc fn =
  let rec error_on_closure = function
    | TFun (_, _, Closure _) ->
        raise (Error (loc, "Cannot (yet) return a closure"))
    | TVar { contents = Link typ } -> error_on_closure typ
    | _ -> ()
  in
  error_on_closure fn

let needs_capture env var =
  let rec aux = function
    | TFun (_, _, Simple) -> None
    | TVar { contents = Link typ } -> aux typ
    | t -> Some (var, t)
  in
  aux (Env.find var env)

let rec convert env = function
  | Ast.Var (loc, id) -> convert_var env loc id
  | Int (_, i) -> { typ = TInt; expr = Const (Int i) }
  | Bool (_, b) -> { typ = TBool; expr = Const (Bool b) }
  | Let (loc, x, e1, e2) -> convert_let env loc x e1 e2
  | Lambda (loc, id, e) -> convert_lambda env loc id e
  | Function (loc, func) -> convert_function env loc func
  | App (_, e1, e2) -> convert_app env e1 e2
  | Bop (loc, bop, e1, e2) -> convert_bop env loc bop e1 e2
  | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2

and convert_var env loc id =
  match Env.query_opt id env with
  | Some t ->
      let typ = instantiate t in
      { typ; expr = Var id }
  | None -> raise (Error (loc, "No var named " ^ id))

and typeof_annot_decl env loc annot expr =
  enter_level ();
  match annot with
  | None ->
      let t = convert env expr in
      leave_level ();
      { t with typ = generalize t.typ }
  | Some annot ->
      let t_annot = typeof_annot loc annot in
      let t = convert env expr in
      leave_level ();
      unify t_annot t.typ;
      { t with typ = t_annot }

and convert_let env loc (id, type_annot) e1 e2 =
  let typ1 = typeof_annot_decl env loc type_annot e1 in

  let typ2 = convert (Env.add_value id typ1.typ env) e2 in
  { typ = typ2.typ; expr = Let (id, typ1, typ2) }

and convert_lambda env loc params e =
  let env = Env.new_scope env in
  let env, params_t = handle_params env loc params in

  let body = convert env e in
  let env, closed_vars = Env.close_scope env in
  let kind =
    match List.filter_map (needs_capture env) closed_vars with
    | [] -> Anon
    | lst ->
        (* List.map fst lst |> String.concat ", " |> print_endline; *)
        Closure lst
  in
  dont_allow_closure_return loc body.typ;

  let params = List.map2 (fun (name, _) typ -> (name, typ)) params params_t in
  let expr = Lambda { params; body; kind } in
  { typ = TFun (params_t, body.typ, kind); expr }

and convert_function env loc { name; params; body; cont } =
  (* Create a fresh type var for the function name
     and use it in the function body *)
  let unique = next_func (fst name) func_tbl in
  let env =
    match snd name with
    | None -> Env.add_value (fst name) (newvar ()) env
    | Some t -> Env.add_value (fst name) (typeof_annot loc t) env
  in
  (* We duplicate some lambda code due to naming *)
  let env = Env.new_scope env in
  let body_env, params_t = handle_params env loc params in
  let body = convert body_env body in
  let env, closed_vars = Env.close_scope env in
  let kind =
    match List.filter_map (needs_capture env) closed_vars with
    | [] -> Simple
    | lst ->
        (* List.map fst lst |> String.concat ", " |> print_endline; *)
        Closure lst
  in
  dont_allow_closure_return loc body.typ;

  let params = List.map2 (fun (name, _) typ -> (name, typ)) params params_t in
  let lambda = { params; body; kind } in
  let lambda_typ = TFun (params_t, body.typ, kind) in

  (* Make sure the types match *)
  unify (Env.find (fst name) env) lambda_typ;
  (* Continue, see let *)
  let typ2 = convert env cont in
  { typ = typ2.typ; expr = Function (fst name, unique, lambda, typ2) }

and convert_app env e1 args =
  let type_fun = convert env e1 in
  let typed_expr_args = List.map (convert env) args in
  let args_t = List.map (fun a -> a.typ) typed_expr_args in
  let res_t = newvar () in
  unify type_fun.typ (TFun (args_t, res_t, Simple));
  { typ = res_t; expr = App (type_fun, typed_expr_args) }

and convert_bop env loc bop e1 e2 =
  let check () =
    let t1 = convert env e1 in
    let t2 = convert env e2 in
    try
      unify t1.typ TInt;
      unify t2.typ TInt;
      (t1, t2)
    with Unify -> bop_error loc bop t1.typ t2.typ
  in
  match bop with
  | Ast.Plus | Mult | Minus ->
      let t1, t2 = check () in
      { typ = TInt; expr = Bop (bop, t1, t2) }
  | Less | Equal ->
      let t1, t2 = check () in
      { typ = TBool; expr = Bop (bop, t1, t2) }

and convert_if env loc cond e1 e2 =
  (* We can assume pred evaluates to bool and both
     branches need to evaluate to the some type *)
  let type_cond = convert env cond in
  (try unify type_cond.typ TBool
   with Unify ->
     raise
       (Error
          ( loc,
            "Condition in if must evaluate to bool, not: "
            ^ string_of_type type_cond.typ )));
  let type_e1 = convert env e1 in
  let type_e2 = convert env e2 in
  let typ = newvar () in
  (try unify type_e1.typ type_e2.typ
   with Unify ->
     raise
       (Error
          ( loc,
            "Branches in if: " ^ string_of_type type_e1.typ ^ " vs "
            ^ string_of_type type_e2.typ )));
  unify typ type_e2.typ;
  { typ; expr = If (type_cond, type_e1, type_e2) }

let to_typed (prog : Ast.prog) =
  reset_type_vars ();
  let externals =
    List.map
      (fun (loc, name, typ) -> (name, typeof_annot loc typ))
      prog.external_decls
  in

  let vars =
    List.fold_left
      (fun vars (name, typ) -> Env.add_value name typ vars)
      Env.empty externals
  in
  (externals, convert vars prog.expr)
