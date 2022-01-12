open Types
module Vars = Map.Make (String)
module Set = Set.Make (String)

type const = Typing.const

let pp_const = Typing.pp_const

type expr =
  | Mvar of string
  | Mconst of const
  | Mbop of Ast.bop * monod_tree * monod_tree
  | Mif of ifexpr
  | Mlet of string * monod_tree * monod_tree
  | Mlambda of string * abstraction
  | Mfunction of string * abstraction * monod_tree
  | Mapp of { callee : monod_expr; args : monod_expr list; alloca : alloca }
  | Mrecord of (string * monod_tree) list * alloca
  | Mfield of (monod_tree * int)
  | Mseq of (monod_tree * monod_tree)
[@@deriving show]

and func = { params : typ list; ret : typ; kind : fun_kind }
and abstraction = { func : func; pnames : string list; body : monod_tree }
and call_name = Mono of string | Concrete of string | Default
and monod_expr = { ex : monod_tree; monomorph : call_name }
and monod_tree = { typ : typ; expr : expr; return : bool }
and alloca = bool ref
and ifexpr = { cond : monod_tree; e1 : monod_tree; e2 : monod_tree }

type to_gen_func = { abs : abstraction; name : string; recursive : bool }
(* [@@deriving show] *)

type monomorphized_tree = {
  externals : Typing.external_decl list;
  records : typ list;
  tree : monod_tree;
  funcs : to_gen_func list;
}

type to_gen_func_kind =
  | Concrete of to_gen_func * string
  | Polymorphic of to_gen_func
  | Forward_decl of string
  | No_function
(* [@@deriving show] *)

type alloc = Value of alloca | Two_values of alloc * alloc | No_value
type var = { fn : to_gen_func_kind; alloc : alloc }

type morph_param = {
  vars : var Vars.t;
  monomorphized : Set.t;
  funcs : to_gen_func list; (* to generate in codegen *)
  ret : bool;
      (* Marks an expression where an if is the last piece which returns a record.
         Needed for tail call elim *)
}

let no_var = { fn = No_function; alloc = No_value }

let rec extract_alloca = function
  | Value a -> Some a
  | Two_values (a, _) -> extract_alloca a
  | No_value -> None

let typ_of_abs abs = Tfun (abs.func.params, abs.func.ret, abs.func.kind)

let rec func_of_typ = function
  | Tvar { contents = Link t } -> func_of_typ t
  | Tfun (params, ret, kind) -> { params; ret; kind }
  | _ -> failwith "Internal Error: Not a function type"

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)

(* For named functions *)
let unique_name = function
  | name, None -> name
  | name, Some n -> name ^ "__" ^ string_of_int n

let lambda_name id = "__fun" ^ string_of_int id

let find_function_expr vars = function
  | Mvar id -> (
      match Vars.find_opt id vars with
      | Some thing -> thing.fn
      | None -> No_function)
  | Mconst _ | Mapp _ | Mrecord _ | Mfield _ | Mbop _ -> No_function
  | Mlambda _ -> (* Concrete type is already inferred *) No_function
  | e ->
      print_endline (show_expr e);
      "Not supported: " ^ show_expr e |> failwith

let get_mono_name name ~poly concrete =
  let rec str = function
    | Tint -> "i"
    | Tbool -> "b"
    | Tunit -> "u"
    | Tvar { contents = Link t } -> str t
    | Tfun (ps, r, _) ->
        Printf.sprintf "%s.%s" (String.concat "" (List.map str ps)) (str r)
    | Trecord (Some t, name, _) -> Printf.sprintf "%s%s" name (str t)
    | Trecord (_, name, _) -> name
    | Qvar _ | Tvar _ -> "g"
  in
  Printf.sprintf "__%s_%s_%s" (str poly) name (str concrete)

let subst_type ~concrete poly =
  let rec inner subst = function
    | l, Tvar { contents = Link r } -> inner subst (l, r)
    | Tvar { contents = Link l }, r -> inner subst (l, r)
    | Qvar id, t | Tvar { contents = Unbound (id, _) }, t -> (
        match Vars.find_opt id subst with
        | Some _ -> (* Already in tbl*) (subst, t)
        | None -> (Vars.add id t subst, t))
    | Tfun (ps1, r1, kind), Tfun (ps2, r2, _) ->
        let subst, ps =
          List.fold_left_map
            (fun subst (l, r) -> inner subst (l, r))
            subst (List.combine ps1 ps2)
        in
        let subst, r = inner subst (r1, r2) in
        (subst, Tfun (ps, r, kind))
    | (Trecord (Some i, record, l1) as l), Trecord (Some j, _, l2)
      when Typing.is_type_polymorphic l ->
        let labels = Array.copy l1 in
        let f (subst, i) (ls, lt) =
          let _, r = l2.(i) in
          let subst, t = inner subst (lt, r) in
          labels.(i) <- (ls, t);
          (subst, i + 1)
        in
        let subst, _ = Array.fold_left f (subst, 0) l1 in
        let subst, param = inner subst (i, j) in
        (subst, Trecord (Some param, record, labels))
    | t, _ -> (subst, t)
  in
  let vars, typ = inner Vars.empty (poly, concrete) in

  let rec subst = function
    | Tvar { contents = Link l } -> subst l
    | (Qvar id as old) | (Tvar { contents = Unbound (id, _) } as old) -> (
        match Vars.find_opt id vars with Some t -> t | None -> old)
    | Tfun (ps, r, kind) ->
        let ps = List.map subst ps in
        Tfun (ps, subst r, kind)
    | Trecord (Some p, record, labels) as t when Typing.is_type_polymorphic t ->
        let f (name, t) = (name, subst t) in
        let labels = Array.map f labels in
        Trecord (Some (subst p), record, labels)
    | t -> t
  in

  (subst, typ)

let subst_body subst tree =
  let subst_func { params; ret; kind } =
    let params = List.map subst params in
    let ret = subst ret in
    { params; ret; kind }
  in

  let rec inner tree =
    let sub t = { (inner t) with typ = subst t.typ } in
    match tree.expr with
    | Mvar _ -> { tree with typ = subst tree.typ }
    | Mconst _ -> tree
    | Mbop _ -> tree
    | Mif expr ->
        let cond = inner expr.cond in
        let e1 = sub expr.e1 in
        let e2 = sub expr.e2 in
        { tree with typ = e1.typ; expr = Mif { cond; e1; e2 } }
    | Mlet (id, expr, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { tree with typ = cont.typ; expr = Mlet (id, expr, cont) }
    | Mlambda (name, abs) ->
        let abs =
          { abs with func = subst_func abs.func; body = sub abs.body }
        in
        let typ = typ_of_abs abs in
        { tree with typ; expr = Mlambda (name, abs) }
    | Mfunction (name, abs, cont) ->
        let abs =
          { abs with func = subst_func abs.func; body = sub abs.body }
        in
        let cont = { (inner cont) with typ = subst cont.typ } in
        { tree with typ = cont.typ; expr = Mfunction (name, abs, cont) }
    | Mapp { callee; args; alloca } ->
        let callee = { callee with ex = sub callee.ex } in

        let args = List.map (fun arg -> { arg with ex = sub arg.ex }) args in
        let func = func_of_typ callee.ex.typ in
        { tree with typ = func.ret; expr = Mapp { callee; args; alloca } }
    | Mrecord (labels, alloca) ->
        let labels = List.map (fun (name, expr) -> (name, sub expr)) labels in
        { tree with typ = subst tree.typ; expr = Mrecord (labels, alloca) }
    | Mfield (expr, index) ->
        { tree with typ = subst tree.typ; expr = Mfield (sub expr, index) }
    | Mseq (expr, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { tree with typ = cont.typ; expr = Mseq (expr, cont) }
  in
  inner tree

let monomorphize_call p expr =
  if Typing.is_type_polymorphic expr.typ then (p, Default)
  else
    match find_function_expr p.vars expr.expr with
    | Concrete (func, username) ->
        (* If a named function gets a generated name, the call site has to be made aware *)
        if not (String.equal func.name username) then (p, Concrete func.name)
        else (p, Default)
    | Polymorphic func ->
        let typ = typ_of_abs func.abs in
        let name = get_mono_name func.name ~poly:typ expr.typ in

        if Set.mem name p.monomorphized then
          (* The function exists, we don't do anything right now *)
          (p, Mono name)
        else
          (* We generate the function *)
          let subst, typ = subst_type ~concrete:expr.typ typ in
          let body = subst_body subst func.abs.body in

          let fnc = func_of_typ typ in
          let funcs =
            { func with abs = { func.abs with func = fnc; body }; name }
            :: p.funcs
          in
          let monomorphized = Set.add name p.monomorphized in
          ({ p with funcs; monomorphized }, Mono name)
    | No_function -> (p, Default)
    | Forward_decl _ ->
        (* We don't have to do anything, because the correct function will be called in the first place.
           Except when it is called with different types recursively. We'll see *)
        (p, Default)

let rec set_alloca = function
  | Value a -> a := true
  | Two_values (a, b) ->
      set_alloca a;
      set_alloca b
  | No_value -> ()

let rec morph_expr param (texpr : Typing.typed_expr) =
  let make expr return = { typ = texpr.typ; expr; return } in
  match texpr.expr with
  | Typing.Var v -> morph_var make param v
  | Const c -> (param, make (Mconst c) false, no_var)
  | Bop (bop, e1, e2) -> morph_bop make param bop e1 e2
  | If (cond, e1, e2) -> morph_if make param cond e1 e2
  | Let (id, e1, e2) -> morph_let make param id e1 e2
  | Record labels -> morph_record make param labels
  | Field (expr, index) -> morph_field make param expr index
  | Sequence (expr, cont) -> morph_seq make param expr cont
  | Function (name, uniq, abs, cont) -> morph_func param (name, uniq, abs, cont)
  | Lambda (id, abs) -> morph_lambda texpr.typ param id abs
  | App { callee; args } -> morph_app make param callee args

and morph_var mk p v =
  let alloca =
    match Vars.find_opt v p.vars with Some thing -> thing | None -> no_var
  in
  (p, mk (Mvar v) p.ret, alloca)

and morph_bop mk p bop e1 e2 =
  let ret = p.ret in
  (* The returning expr is bop, not one of the operands *)
  let p, e1, _ = morph_expr { p with ret = false } e1 in
  let p, e2, _ = morph_expr { p with ret = false } e2 in
  ({ p with ret }, mk (Mbop (bop, e1, e2)) ret, no_var)

and morph_if mk p cond e1 e2 =
  let ret = p.ret in
  let p, cond, _ = morph_expr { p with ret = false } cond in
  let p, e1, a = morph_expr { p with ret } e1 in
  let p, e2, b = morph_expr { p with ret } e2 in
  ( p,
    mk (Mif { cond; e1; e2 }) ret,
    { a with alloc = Two_values (a.alloc, b.alloc) } )

and morph_let mk p id e1 e2 =
  let ret = p.ret in
  let p, e1, func = morph_expr { p with ret = false } e1 in
  let p = { p with vars = Vars.add id func p.vars } in
  let p, e2, func = morph_expr { p with ret } e2 in
  (p, mk (Mlet (id, e1, e2)) ret, func)

and morph_record mk p labels =
  let ret = p.ret in
  let p = { p with ret = false } in
  (* ret = false is threaded through p *)
  let f param (id, e) =
    let p, e, _ = morph_expr param e in
    (p, (id, e))
  in
  let p, labels = List.fold_left_map f p labels in
  let alloca = ref false in
  ( { p with ret },
    mk (Mrecord (labels, alloca)) ret,
    { fn = No_function; alloc = Value alloca } )

and morph_field mk p expr index =
  let ret = p.ret in
  let p, e, func = morph_expr { p with ret = false } expr in
  ({ p with ret }, mk (Mfield (e, index)) ret, func)

and morph_seq mk p expr cont =
  let ret = p.ret in
  let p, expr, _ = morph_expr { p with ret = false } expr in
  let p, cont, func = morph_expr { p with ret } cont in
  (p, mk (Mseq (expr, cont)) ret, func)

and morph_func p (username, uniq, abs, cont) =
  (* If the function is concretely typed, we add it to the function list and
     add the usercode name to the bound variables. In the polymorphic case,
     we add the function to the bound variables, but not to the function list.
     Instead, the monomorphized instance will be added later *)
  let ftyp = Typing.(Tfun (abs.tp.tparams, abs.tp.ret, abs.tp.kind)) in

  let name = unique_name (username, uniq) in
  let recursive = true in
  let func =
    { params = abs.tp.tparams; ret = abs.tp.ret; kind = abs.tp.kind }
  in
  let pnames = abs.nparams in

  let ret = p.ret in
  (* Make sure recursion works and the current function can be used in its body *)
  let temp_p =
    match abs.tp.ret with
    | Trecord _ ->
        let value = { fn = Forward_decl name; alloc = Value (ref false) } in
        let vars = Vars.add username value p.vars in
        { p with vars; ret = true }
        (* ret = true because this is used in the body of a new function *)
    | _ -> { p with ret = true }
  in

  let temp_p, body, { fn = _; alloc } = morph_expr temp_p abs.body in

  (* print_endline (show_expr body.expr); *)
  (match body.typ with Trecord _ -> set_alloca alloc | _ -> ());

  let abs = { func; pnames; body } in
  let gen_func = { abs; name; recursive } in

  (* Collect functions from body *)
  let p =
    { p with monomorphized = temp_p.monomorphized; funcs = temp_p.funcs }
  in
  let p =
    if Typing.is_type_polymorphic ftyp then
      let vars =
        Vars.add username { fn = Polymorphic gen_func; alloc } p.vars
      in
      { p with vars }
    else
      let vars =
        Vars.add username { fn = Concrete (gen_func, username); alloc } p.vars
      in
      let funcs = gen_func :: p.funcs in
      { p with vars; funcs }
  in

  let p, cont, func = morph_expr { p with ret } cont in
  (p, { typ = cont.typ; expr = Mfunction (name, abs, cont); return = ret }, func)

and morph_lambda typ p id abs =
  let name = lambda_name id in
  let recursive = false in
  let func =
    { params = Typing.(abs.tp.tparams); ret = abs.tp.ret; kind = abs.tp.kind }
  in
  let pnames = abs.nparams in

  let ret = p.ret in
  let vars = p.vars in
  let tmp, body, { fn = _; alloc } =
    morph_expr { p with ret = true } abs.body
  in

  (* Collect functions from body *)
  let p = { p with monomorphized = tmp.monomorphized; funcs = tmp.funcs } in

  (match abs.tp.ret with Trecord _ -> set_alloca alloc | _ -> ());

  let abs = { func; pnames; body } in
  let gen_func = { abs; name; recursive } in

  let p = { p with vars } in
  let p, fn =
    if Typing.is_type_polymorphic typ then (p, Polymorphic gen_func)
    else
      let funcs = gen_func :: p.funcs in
      ({ p with funcs }, Concrete (gen_func, name))
  in
  ( { p with ret },
    { typ; expr = Mlambda (name, abs); return = ret },
    { fn; alloc } )

and morph_app mk p callee args =
  let ret = p.ret in
  let p, ex, { fn = _; alloc } = morph_expr { p with ret = false } callee in
  let p, monomorph = monomorphize_call p ex in

  let f p arg =
    let p, ex, _ = morph_expr p arg in
    let p, monomorph = monomorphize_call p ex in
    (p, { ex; monomorph })
  in
  let p, args = List.fold_left_map f p args in

  let alloc, alloc_ref =
    match clean ex.typ with
    | Tfun (_, Trecord _, _) -> (
        ( alloc,
          match extract_alloca alloc with
          | Some alloca -> alloca
          | None -> ref false ))
    | _ -> (No_value, ref false)
  in

  ( { p with ret },
    mk (Mapp { callee = { ex; monomorph }; args; alloca = alloc_ref }) ret,
    { no_var with alloc } )

let monomorphize { Typing.externals; records; tree } =
  let param =
    { vars = Vars.empty; monomorphized = Set.empty; funcs = []; ret = false }
  in
  let p, tree, _ = morph_expr param tree in
  { externals; records; tree; funcs = p.funcs }
