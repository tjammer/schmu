type typ = TInt | TBool | TVar of tv ref | QVar of string | TFun of typ * typ

and tv = Unbound of string * int | Link of typ

exception Error of Ast.loc * string

exception Unify

module Strmap = Map.Make (String)
module Strset = Set.Make (String)

let rec string_of_type = function
  | TInt -> "int"
  | TBool -> "bool"
  | TFun (ty1, ty2) ->
      "("
      ^ String.concat " -> " [ string_of_type ty1; string_of_type ty2 ]
      ^ ")"
  | TVar { contents = Unbound (str, _) } ->
      Char.chr (int_of_string str + Char.code 'a') |> String.make 1
  | TVar { contents = Link t } -> string_of_type t
  | QVar str -> str ^ "12"

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
  | TFun (t1, t2) ->
      occurs tvr t1;
      occurs tvr t2
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
    | TFun (l1, l2), TFun (r1, r2) ->
        unify l1 r1;
        unify l2 r2
    | _ -> raise Unify

let rec generalize = function
  | TVar { contents = Unbound (id, l) } when l > !current_level -> QVar id
  | TVar { contents = Link t } -> generalize t
  | TFun (t1, t2) -> TFun (generalize t1, generalize t2)
  | t -> t

let instantiate t =
  let rec aux subst = function
    | QVar id -> (
        match Strmap.find_opt id subst with
        | Some t -> (t, subst)
        | None ->
            let tv = newvar () in
            (tv, Strmap.add id tv subst))
    | TVar { contents = Link t } -> aux subst t
    | TFun (t1, t2) ->
        let t1, subst = aux subst t1 in
        let t2, subst = aux subst t2 in
        (TFun (t1, t2), subst)
    | t -> (t, subst)
  in
  aux Strmap.empty t |> fst

let rec typeof env = function
  | Ast.Var (loc, v) -> typeof_var loc env v
  | Int (_, _) -> TInt
  | Bool (_, _) -> TBool
  | Let (_, x, e1, e2) -> typeof_let env x e1 e2
  | Abs (_, id, e) -> typeof_abs env id e
  | App (_, e1, e2) -> typeof_app env e1 e2
  | If (loc, cond, e1, e2) -> typeof_if env loc cond e1 e2
  | Bop (loc, bop, e1, e2) -> typeof_bop env loc bop e1 e2

and typeof_var loc env v =
  match Strmap.find_opt v env with
  | Some t -> instantiate t
  | None -> raise (Error (loc, "No var named " ^ v))

and typeof_let env id e1 e2 =
  enter_level ();
  let type_e = typeof env e1 in
  leave_level ();
  typeof (Strmap.add id (generalize type_e) env) e2

and typeof_abs env id e =
  let type_id = newvar () in
  let type_e = typeof (Strmap.add id type_id env) e in
  TFun (type_id, type_e)

and typeof_app env e1 e2 =
  let type_fun = typeof env e1 in
  let type_arg = typeof env e2 in
  let type_res = newvar () in
  unify type_fun (TFun (type_arg, type_res));
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
    with Unify ->
      let op =
        match bop with Plus -> "+" | Mult -> "*" | Less -> "<" | Equal -> "=="
      in
      raise
        (Error
           ( loc,
             "Expressions in binary op '" ^ op ^ "' must be both int " ^ "not: "
             ^ string_of_type t1 ^ " vs " ^ string_of_type t2 ))
  in
  match bop with
  | Plus | Mult ->
      check ();
      TInt
  | Less | Equal ->
      check ();
      TBool

let typecheck expr =
  reset_type_vars ();
  typeof Strmap.empty expr
