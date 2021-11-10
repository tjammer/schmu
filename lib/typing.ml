open Types

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
  | Record of (string * typed_expr) list
  | Field of (typed_expr * int)

and typed_expr = { typ : typ; expr : expr }

type external_decl = string * typ

exception Error of Ast.loc * string

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
  (* To deal with brackets for functions *)
  let lvl = ref 0 in
  (* To have type variables staring from 'a' *)
  let tname = ref 0 in
  let names = ref [] in
  let get_name str =
    match List.assoc_opt str !names with
    | Some name -> name
    | None ->
        let name = Char.chr (!tname + Char.code 'a') |> String.make 1 in
        incr tname;
        names := (str, name) :: !names;
        name
  in
  let rec string_of_type = function
    | TInt -> "int"
    | TBool -> "bool"
    | TUnit -> "unit"
    | TFun (ts, t, _) ->
        let lvl_cpy = !lvl in
        incr lvl;
        let func =
          String.concat " -> "
            (* Make sure parameters are evaluated first *)
            (let l = List.map string_of_type ts in
             l @ [ string_of_type t ])
        in
        if lvl_cpy = 0 then func else "(" ^ func ^ ")"
    | TVar { contents = Unbound (str, _) } -> get_name str
    | TVar { contents = Link t } -> string_of_type t
    | QVar str -> get_name str
    | TRecord (str, _) -> str
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

let arity (loc, pre) thing a b =
  let msg =
    Printf.sprintf "%s Arity in %s: Expected %i but got %i" pre thing
      (List.length a) (List.length b)
  in
  raise (Error (loc, msg))

let rec unify info t1 t2 =
  if t1 == t2 then ()
  else
    match (t1, t2) with
    | TVar { contents = Link t1 }, t2 | t2, TVar { contents = Link t1 } ->
        unify info t1 t2
    | TVar ({ contents = Unbound _ } as tv), t
    | t, TVar ({ contents = Unbound _ } as tv) ->
        occurs tv t;
        tv := Link t
    | TFun (params_l, l, _), TFun (params_r, r, _) ->
        (try
           List.iter2
             (fun left right -> unify info left right)
             params_l params_r
         with Invalid_argument _ -> arity info "function" params_l params_r);
        unify info l r
    | TRecord (n1, labels1), TRecord (n2, labels2) ->
        if String.equal n1 n2 then
          (* We ignore the label names for now *)
          try List.iter2 (fun a b -> unify info (snd a) (snd b)) labels1 labels2
          with Invalid_argument _ -> arity info "record" labels1 labels2
        else
          let loc, pre = info in
          let msg =
            Printf.sprintf "%s Expected %s but got %s" pre (string_of_type t1)
              (string_of_type t2)
          in
          raise (Error (loc, msg))
    | _ ->
        let loc, pre = info in
        let msg =
          Printf.sprintf "%s Expected %s but got %s" pre (string_of_type t1)
            (string_of_type t2)
        in
        raise (Error (loc, msg))

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

let string_of_bop = function
  | Ast.Plus -> "+"
  | Mult -> "*"
  | Less -> "<"
  | Equal -> "=="
  | Minus -> "-"

let typeof_annot env loc annot =
  let concrete_type = function
    | "int" -> TInt
    | "bool" -> TBool
    | "unit" -> TUnit
    | t -> (
        match Env.find_type_opt t env with
        | Some t -> t
        | None -> raise (Error (loc, "Unknown type: " ^ t ^ ".")))
  in

  match annot with
  | [] -> failwith "Internal Error: Type annot list should not be empty"
  | [ t ] -> concrete_type t
  | [ "unit"; t ] -> TFun ([], concrete_type t, Simple)
  (* For function definiton and application, 'unit' means an empty list.
     It's easier for typing and codegen to treat unit as a special case here *)
  | l -> (
      (* We reverse the list times :( *)
      match List.rev l with
      | last :: head ->
          TFun
            (List.map concrete_type (List.rev head), concrete_type last, Simple)
      | [] -> failwith ":)")

let handle_params env loc params =
  (* return updated env with bindings for parameters and types of parameters *)
  List.fold_left_map
    (fun env (id, type_annot) ->
      let type_id =
        match type_annot with
        | None -> newvar ()
        | Some annot -> typeof_annot env loc annot
      in
      (Env.add_value id type_id env, type_id))
    env params

let get_record_type env loc typed_labels =
  let possible_records =
    List.fold_left
      (fun set (label, _) ->
        match Env.find_label_opt label env with
        | Some lbl ->
            (* We try to unify later, not here *)
            Strset.add lbl.record set
        | None -> raise (Error (loc, "Unbound record field " ^ label)))
      Strset.empty typed_labels
  in

  let unify_labels labels =
    List.iter
      (fun (rlabel, rtype) ->
        let ltype = List.assoc rlabel typed_labels in
        unify (loc, "") rtype ltype)
      labels
  in
  let get_name_labels = function
    | TRecord (name, labels) -> (name, labels)
    | _ -> failwith "Internal Error not a record"
  in
  match Strset.elements possible_records with
  | [] -> failwith "Internal Error not a record"
  | [ record ] ->
      let record = Env.find_type record env in
      let name, labels = get_name_labels record in
      unify_labels labels;
      (name, labels)
  | lst ->
      (* We choose the correct one by finding the first record where all labels fit  *)
      (* There must be better ways to do this *)
      let record =
        List.fold_left
          (fun chosen record ->
            let record = Env.find_type_opt record env in
            let all_match =
              match Option.get record with
              | TRecord (_, labels) ->
                  List.fold_left
                    (fun mtch (lname, _) ->
                      mtch
                      && List.exists
                           (fun (tlname, _) -> String.equal lname tlname)
                           typed_labels)
                    true labels
              | _ -> failwith "Internal Error in typeof_record"
            in
            if all_match then record else chosen)
          None lst
        |> Option.get
      in
      let name, labels = get_name_labels record in
      unify_labels labels;
      (name, labels)

let assoc_opti qkey =
  let rec aux i = function
    | (key, v) :: _ when String.equal qkey key -> Some (i, v)
    | _ :: tl -> aux (i + 1) tl
    | [] -> None
  in
  aux 0

let rec typeof env = function
  | Ast.Var (loc, v) -> typeof_var env loc v
  | Int (_, _) -> TInt
  | Bool (_, _) -> TBool
  | Let (loc, x, e1, e2) -> typeof_let env loc x e1 e2
  | Lambda (loc, id, e) -> typeof_abs env loc id e
  | Function (loc, { name; params; body; cont }) ->
      typeof_function env loc name params body cont
  | App (loc, e1, e2) -> typeof_app env loc e1 e2
  | If (loc, cond, e1, e2) -> typeof_if env loc cond e1 e2
  | Bop (loc, bop, e1, e2) -> typeof_bop env loc bop e1 e2
  | Record (loc, labels) -> typeof_record env loc labels
  | Field (loc, expr, id) -> typeof_field env loc expr id

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
        let type_annot = typeof_annot env loc annot in
        let type_e = typeof env e1 in
        leave_level ();
        unify (loc, "") type_annot type_e;
        type_annot
  in
  typeof (Env.add_value id type_e env) e2

and typeof_abs env loc params e =
  enter_level ();
  let env, params_t = handle_params env loc params in
  let type_e = typeof env e in
  leave_level ();

  TFun (params_t, type_e, Simple) |> generalize

and typeof_function env loc name params body cont =
  (* this loc might not be correct *)
  (* typeof_let env loc name (Lambda (loc, param, body)) cont *)
  enter_level ();

  (* Recursion allowed for named funcs *)
  let env =
    match snd name with
    (* Check type annotations *)
    | None -> Env.add_value (fst name) (newvar ()) env
    | Some t -> Env.add_value (fst name) (typeof_annot env loc t) env
  in
  let body_env, params_t = handle_params env loc params in
  let bodytype = typeof body_env body in
  leave_level ();
  let funtype = TFun (params_t, bodytype, Simple) |> generalize in
  unify (loc, "") (Env.find (fst name) env) funtype;
  typeof env cont

and typeof_app env loc e1 args =
  let type_fun = typeof env e1 in
  let type_args = List.map (typeof env) args in
  let type_res = newvar () in
  unify (loc, "") type_fun (TFun (type_args, type_res, Simple));
  type_res

and typeof_if env loc cond e1 e2 =
  (* We can assume pred evaluates to bool and both
     branches need to evaluate to the some type *)
  let type_cond = typeof env cond in
  unify (loc, "In condition") type_cond TBool;
  (* TODO catch *)
  let type_e1 = typeof env e1 in
  let type_e2 = typeof env e2 in
  let type_res = newvar () in

  unify (loc, "Branches have different type") type_e1 type_e2;
  unify (loc, "") type_res type_e2;
  type_res

and typeof_bop env loc bop e1 e2 =
  let check () =
    (* both exprs must be Int, not Bool *)
    let t1 = typeof env e1 in
    let t2 = typeof env e2 in
    unify (loc, "Binary " ^ string_of_bop bop) t1 TInt;
    unify (loc, "Binary " ^ string_of_bop bop) t2 TInt
  in

  match bop with
  | Plus | Mult | Minus ->
      check ();
      TInt
  | Less | Equal ->
      check ();
      TBool

and typeof_record env loc labels =
  (* TODO pass in expected type? *)
  (* We build a list of possible records by label and type.
     If we're lucky, there's only one left *)
  let typed_labels =
    List.map (fun (label, expr) -> (label, typeof env expr)) labels
  in
  let name, labels = get_record_type env loc typed_labels in
  TRecord (name, labels)

and typeof_field env loc expr id =
  let typ = typeof env expr in
  (* This expr could be a fresh var, in which case we take the record type from the label,
     or it could be a specific record type in which case we have to get that certain record *)
  match clean typ with
  | TRecord (name, labels) -> (
      match List.assoc_opt id labels with
      | Some t -> t
      | None ->
          raise (Error (loc, "Unbound field " ^ id ^ " on record " ^ name)))
  | t -> (
      match Env.find_label_opt id env with
      | Some { typ; record; index = _ } ->
          unify
            (loc, "Field access of " ^ string_of_type typ)
            (Env.find_type record env) t;
          typ
      | None -> raise (Error (loc, "Unbound field " ^ id)))

let extern_vars decls =
  let externals =
    List.map
      (fun (loc, name, typ) -> (name, typeof_annot Env.empty loc typ))
      decls
  in
  List.fold_left
    (fun vars (name, typ) -> Env.add_value name typ vars)
    Env.empty externals

let typedefs typedefs env =
  List.fold_left
    (fun env Ast.{ name; labels; loc } ->
      let labels =
        List.map
          (fun (lbl, type_expr) -> (lbl, typeof_annot env loc type_expr))
          labels
      in
      Env.add_type name ~labels env)
    env typedefs

let typecheck (prog : Ast.prog) =
  reset_type_vars ();
  let env = extern_vars prog.external_decls |> typedefs prog.typedefs in
  typeof env prog.expr

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

let rec param_funcs_as_closures = function
  | TVar { contents = Link t } ->
      (* This shouldn't break type inference *) param_funcs_as_closures t
  | TFun (_, _, Closure _) as t -> t
  | TFun (params, ret, _) -> TFun (params, ret, Closure [])
  | t -> t

let rec convert env = function
  | Ast.Var (loc, id) -> convert_var env loc id
  | Int (_, i) -> { typ = TInt; expr = Const (Int i) }
  | Bool (_, b) -> { typ = TBool; expr = Const (Bool b) }
  | Let (loc, x, e1, e2) -> convert_let env loc x e1 e2
  | Lambda (loc, id, e) -> convert_lambda env loc id e
  | Function (loc, func) -> convert_function env loc func
  | App (loc, e1, e2) -> convert_app env loc e1 e2
  | Bop (loc, bop, e1, e2) -> convert_bop env loc bop e1 e2
  | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
  | Record (loc, labels) -> convert_record env loc labels
  | Field (loc, expr, id) -> convert_field env loc expr id

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
      let t_annot = typeof_annot env loc annot in
      let t = convert env expr in
      leave_level ();
      unify (loc, "") t_annot t.typ;
      { t with typ = t_annot }

and convert_let env loc (id, type_annot) e1 e2 =
  let typ1 = typeof_annot_decl env loc type_annot e1 in

  let typ2 = convert (Env.add_value id typ1.typ env) e2 in
  { typ = typ2.typ; expr = Let (id, typ1, typ2) }

and convert_lambda env loc params e =
  let env = Env.new_scope env in
  enter_level ();
  let env, params_t = handle_params env loc params in

  let body = convert env e in
  leave_level ();
  let env, closed_vars = Env.close_scope env in
  let kind =
    match List.filter_map (needs_capture env) closed_vars with
    | [] -> Simple
    | lst ->
        (* List.map fst lst |> String.concat ", " |> print_endline; *)
        Closure lst
  in
  dont_allow_closure_return loc body.typ;

  (* For codegen: Mark functions in parameters closures *)
  let params_t = List.map param_funcs_as_closures params_t in

  let named_params (name, _) typ = (name, typ) in
  let typ = TFun (params_t, body.typ, kind) |> generalize in
  match typ with
  | TFun (tparams, ret, kind) ->
      let params = List.map2 named_params params tparams in
      let expr = Lambda { params; body = { body with typ = ret }; kind } in
      { typ; expr }
  | _ -> failwith "Internal Error: generalize produces a new type?"

and convert_function env loc { name; params; body; cont } =
  (* Create a fresh type var for the function name
     and use it in the function body *)
  let unique = next_func (fst name) func_tbl in

  enter_level ();
  let env =
    (* Recursion allowed for named funcs *)
    match snd name with
    (* We check if there are type annotations *)
    | None -> Env.add_value (fst name) (newvar ()) env
    | Some t -> Env.add_value (fst name) (typeof_annot env loc t) env
  in

  (* We duplicate some lambda code due to naming *)
  let env = Env.new_scope env in
  let body_env, params_t = handle_params env loc params in
  let body = convert body_env body in
  leave_level ();

  let env, closed_vars = Env.close_scope env in
  let kind =
    match List.filter_map (needs_capture env) closed_vars with
    | [] -> Simple
    | lst ->
        (* List.map fst lst |> String.concat ", " |> print_endline; *)
        Closure lst
  in
  dont_allow_closure_return loc body.typ;

  (* For codegen: Mark functions in parameters closures *)
  let params_t = List.map param_funcs_as_closures params_t in

  let named_params (name, _) typ = (name, typ) in
  let typ = TFun (params_t, body.typ, kind) |> generalize in

  match typ with
  | TFun (tparams, ret, kind) ->
      (* Make sure the types match *)
      unify (loc, "Function") (Env.find (fst name) env) typ;

      let params = List.map2 named_params params tparams in
      let lambda = { params; body = { body with typ = ret }; kind } in
      (* Continue, see let *)
      let typ2 = convert env cont in
      { typ = typ2.typ; expr = Function (fst name, unique, lambda, typ2) }
  | _ -> failwith "Internal Error: generalize produces a new type?"

and convert_app env loc e1 args =
  let type_fun = convert env e1 in
  (* let saved = freeze type_fun.typ in *)
  let typed_expr_args = List.map (convert env) args in
  let args_t = List.map (fun a -> a.typ) typed_expr_args in
  let res_t = newvar () in
  unify (loc, "Application") type_fun.typ (TFun (args_t, res_t, Simple));
  let targs =
    List.map2 (fun typ texpr -> { texpr with typ }) args_t typed_expr_args
  in
  { typ = res_t; expr = App (type_fun, targs) }

and convert_bop env loc bop e1 e2 =
  let check () =
    let t1 = convert env e1 in
    let t2 = convert env e2 in

    unify (loc, "Binary " ^ string_of_bop bop) t1.typ TInt;
    unify (loc, "Binary " ^ string_of_bop bop) t2.typ TInt;
    (t1, t2)
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
  unify (loc, "In condition") type_cond.typ TBool;
  let type_e1 = convert env e1 in
  let type_e2 = convert env e2 in
  let typ = newvar () in
  unify (loc, "Branches have different type") type_e1.typ type_e2.typ;
  unify (loc, "") typ type_e2.typ;
  { typ; expr = If (type_cond, type_e1, type_e2) }

and convert_record env loc labels =
  let typed_expr_labels =
    List.map (fun (label, expr) -> (label, convert env expr)) labels
  in
  let typed_labels =
    List.map (fun (label, texp) -> (label, texp.typ)) typed_expr_labels
  in
  let name, labels = get_record_type env loc typed_labels in
  (* We sort the labels to appear in the defined order *)
  let sorted_labels =
    List.map (fun (name, _) -> (name, List.assoc name typed_expr_labels)) labels
  in
  { typ = TRecord (name, labels); expr = Record sorted_labels }

and convert_field env loc expr id =
  let expr = convert env expr in
  match clean expr.typ with
  | TRecord (name, labels) -> (
      match assoc_opti id labels with
      | Some (index, typ) -> { typ; expr = Field (expr, index) }
      | None ->
          raise (Error (loc, "Unbound field " ^ id ^ " on record " ^ name)))
  | t -> (
      match Env.find_label_opt id env with
      | Some { typ; index; record } ->
          unify
            (loc, "Field access of " ^ string_of_type typ)
            (Env.find_type record env) t;
          { typ; expr = Field (expr, index) }
      | None -> raise (Error (loc, "Unbound field " ^ id)))

let to_typed (prog : Ast.prog) =
  reset_type_vars ();
  let externals =
    let empty = Env.empty in
    List.map
      (fun (loc, name, typ) -> (name, typeof_annot empty loc typ))
      prog.external_decls
  in

  let vars =
    List.fold_left
      (fun vars (name, typ) -> Env.add_value name typ vars)
      Env.empty externals
    |> typedefs prog.typedefs
  in

  (externals, convert vars prog.expr)
