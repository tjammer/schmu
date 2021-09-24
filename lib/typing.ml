type typ =
  | TInt
  | TBool
  | TUnit
  | TVar of tv ref
  | QVar of string
  | TFun of typ * typ

and tv = Unbound of string * int | Link of typ

type abstraction = { name : string; a_typ : typ; body : typed_expr }

and expr =
  | Var of string
  | Int of int
  | Bool of bool
  | Bop of Ast.bop * typed_expr * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of string * typed_expr * typed_expr
  | Lambda of abstraction
  | Function of string * int option * abstraction * typed_expr
  | App of typed_expr * typed_expr

and typed_expr = { typ : typ; expr : expr }

type external_decl = string * typ

exception Error of Ast.loc * string

exception Unify

module Strmap = Map.Make (String)
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

let rec string_of_type = function
  | TInt -> "int"
  | TBool -> "bool"
  | TUnit -> "unit"
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
  | Ast.Atom_type t -> atom_type t
  | Fun_type (t1, t2) -> TFun (atom_type t1, atom_type t2)

let rec typeof env = function
  | Ast.Var (loc, v) -> typeof_var env loc v
  | Int (_, _) -> TInt
  | Bool (_, _) -> TBool
  | Let (loc, x, e1, e2) -> typeof_let env loc x e1 e2
  | Lambda (loc, id, e) -> typeof_abs env loc id e
  | Function (loc, { name; param; body; cont }) ->
      typeof_function env loc name param body cont
  | App (_, e1, e2) -> typeof_app env e1 e2
  | If (loc, cond, e1, e2) -> typeof_if env loc cond e1 e2
  | Bop (loc, bop, e1, e2) -> typeof_bop env loc bop e1 e2

and typeof_var env loc v =
  match Strmap.find_opt v env with
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
  typeof (Strmap.add id type_e env) e2

and typeof_abs env loc (id, type_annot) e =
  let type_id =
    match type_annot with
    | None -> newvar ()
    | Some annot -> typeof_annot loc annot
  in
  let type_e = typeof (Strmap.add id type_id env) e in
  TFun (type_id, type_e)

and typeof_function env loc name param body cont =
  (* this loc might not be correct *)
  typeof_let env loc name (Lambda (loc, param, body)) cont

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
    with Unify -> bop_error loc bop t1 t2
  in
  match bop with
  | Plus | Mult | Minus ->
      check ();
      TInt
  | Less | Equal ->
      check ();
      TBool

let typecheck expr =
  reset_type_vars ();
  typeof Strmap.empty expr

let rec convert env = function
  | Ast.Var (loc, id) -> convert_var env loc id
  | Int (_, i) -> { typ = TInt; expr = Int i }
  | Bool (_, b) -> { typ = TBool; expr = Bool b }
  | Let (loc, x, e1, e2) -> convert_let env loc x e1 e2
  | Lambda (loc, id, e) -> convert_lambda env loc id e
  | Function (loc, func) -> convert_function env loc func
  | App (_, e1, e2) -> convert_app env e1 e2
  | Bop (loc, bop, e1, e2) -> convert_bop env loc bop e1 e2
  | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2

and convert_var env loc id =
  match Strmap.find_opt id env with
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

  let typ2 = convert (Strmap.add id typ1.typ env) e2 in
  { typ = typ2.typ; expr = Let (id, typ1, typ2) }

and convert_lambda env loc (name, type_annot) e =
  let a_typ =
    match type_annot with
    | None -> newvar ()
    | Some annot -> typeof_annot loc annot
  in
  let body = convert (Strmap.add name a_typ env) e in
  let expr = Lambda { name; a_typ; body } in
  { typ = TFun (a_typ, body.typ); expr }

and convert_function env loc { name; param; body; cont } =
  (* Create a fresh type var for the function name
     and use it in the function body *)
  let unique = next_func (fst name) func_tbl in
  let env =
    match snd name with
    | None -> Strmap.add (fst name) (newvar ()) env
    | Some t -> Strmap.add (fst name) (typeof_annot loc t) env
  in
  (* We duplicate some lambda code due to naming *)
  let a_typ =
    match snd param with
    | None -> newvar ()
    | Some annot -> typeof_annot loc annot
  in
  let body = convert (Strmap.add (fst param) a_typ env) body in
  let lambda = { name = fst param; a_typ; body } in
  let lambda_typ = TFun (a_typ, body.typ) in

  (* Make sure the types match *)
  unify (Strmap.find (fst name) env) lambda_typ;
  (* Continue, see let *)
  let typ2 = convert env cont in
  { typ = typ2.typ; expr = Function (fst name, unique, lambda, typ2) }

and convert_app env e1 e2 =
  let type_fun = convert env e1 in
  let type_arg = convert env e2 in
  let type_res = newvar () in
  unify type_fun.typ (TFun (type_arg.typ, type_res));
  { typ = type_res; expr = App (type_fun, type_arg) }

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

let to_typed external_decls expr =
  reset_type_vars ();
  let externals =
    List.map
      (fun (loc, name, typ) -> (name, typeof_annot loc typ))
      external_decls
  in

  let vars =
    List.fold_left
      (fun vars (name, typ) -> Strmap.add name typ vars)
      Strmap.empty externals
  in
  (externals, convert vars expr)
