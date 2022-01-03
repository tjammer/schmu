open Types
module Vars = Map.Make (String)
module Set = Set.Make (String)

type const = Typing.const

let pp_const = Typing.pp_const

type expr =
  | Mvar of string
  | Mconst of const
  | Mbop of Ast.bop * monod_tree * monod_tree
  | Mif of monod_tree * monod_tree * monod_tree
  | Mlet of string * monod_tree * monod_tree
  | Mlambda of string * abstraction
  | Mfunction of string * abstraction * monod_tree
  | Mapp of { callee : monod_expr; args : monod_expr list }
  | Mrecord of (string * monod_tree) list
  | Mfield of (monod_tree * int)
  | Mseq of (monod_tree * monod_tree)
[@@deriving show]

and func = { params : typ list; ret : typ; kind : fun_kind }

and abstraction = { func : func; pnames : string list; body : monod_tree }

and monod_expr = monod_tree * string option

and monod_tree = { typ : typ; expr : expr }

type to_gen_func = { abs : abstraction; name : string; recursive : bool }

type monomorphized_tree = {
  externals : Typing.external_decl list;
  records : typ list;
  tree : monod_tree;
  funcs : to_gen_func list;
}

type to_gen_func_kind =
  | Concrete of to_gen_func
  | Polymorphic of to_gen_func
  | Forward_decl of string
  | No_function

type morph_param = {
  vars : to_gen_func_kind Vars.t;
  monomorphized : Set.t;
  funcs : to_gen_func list; (* to generate in codegen *)
}

let recursion_stack = ref []

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

let is_type_polymorphic typ =
  let rec inner acc = function
    | Qvar _ | Tvar { contents = Unbound _ } -> true
    | Tvar { contents = Link t } -> inner acc t
    | Tvar _ -> failwith "annot should not be here"
    | Trecord (Some i, _, labels) -> inner acc (labels.(i) |> snd)
    | Tfun (params, ret, _) ->
        let acc = List.fold_left inner acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Trecord _ -> acc
  in
  inner false typ

let find_function_expr vars = function
  | Mvar id -> (
      match Vars.find_opt id vars with
      | Some thing -> thing
      | None ->
          (* print_endline ("Probably a parameter: " ^ id); *)
          No_function)
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
    | Trecord (Some i, name, labels) ->
        Printf.sprintf "%s%s" name (labels.(i) |> snd |> str)
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
      when is_type_polymorphic l ->
        assert (i = j);
        (* No Array.fold_left_map for pre 4.13? *)
        let labels = Array.copy l1 in
        let f (subst, i) (ls, lt) =
          let _, r = l2.(i) in
          let subst, t = inner subst (lt, r) in
          labels.(i) <- (ls, t);
          (subst, i + 1)
        in
        let subst, _ = Array.fold_left f (subst, 0) l1 in
        (subst, Trecord (Some i, record, labels))
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
    | Trecord (Some i, record, l1) as t when is_type_polymorphic t ->
        let labels = Array.copy l1 in
        let name, typ = l1.(i) in
        labels.(i) <- (name, subst typ);

        Trecord (Some i, record, labels)
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
    | Mif (cond, e1, e2) ->
        let cond = inner cond in
        let e1 = sub e1 in
        let e2 = sub e2 in
        { typ = e1.typ; expr = Mif (cond, e1, e2) }
    | Mlet (id, expr, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { typ = cont.typ; expr = Mlet (id, expr, cont) }
    | Mlambda (name, abs) ->
        let abs =
          { abs with func = subst_func abs.func; body = sub abs.body }
        in
        let typ = typ_of_abs abs in
        { typ; expr = Mlambda (name, abs) }
    | Mfunction (name, abs, cont) ->
        let abs =
          { abs with func = subst_func abs.func; body = sub abs.body }
        in
        let cont = { (inner cont) with typ = subst cont.typ } in
        { typ = cont.typ; expr = Mfunction (name, abs, cont) }
    | Mapp { callee; args } ->
        let callee = (sub (fst callee), snd callee) in

        let args = List.map (fun (a, mono) -> (sub a, mono)) args in
        let func = func_of_typ (fst callee).typ in
        { typ = func.ret; expr = Mapp { callee; args } }
    | Mrecord labels ->
        let labels = List.map (fun (name, expr) -> (name, sub expr)) labels in
        { typ = subst tree.typ; expr = Mrecord labels }
    | Mfield (expr, index) ->
        { typ = subst tree.typ; expr = Mfield (sub expr, index) }
    | Mseq (expr, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { typ = cont.typ; expr = Mseq (expr, cont) }
  in
  inner tree

let monomorphize_call p expr =
  if is_type_polymorphic expr.typ then (p, None)
  else
    match find_function_expr p.vars expr.expr with
    | Concrete _ -> (* All good *) (p, None)
    | Polymorphic func ->
        let typ = typ_of_abs func.abs in
        let name = get_mono_name func.name ~poly:typ expr.typ in

        if Set.mem name p.monomorphized then
          (* The function exists, we don't do anything right now *)
          (p, Some name)
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
          ({ p with funcs; monomorphized }, Some name)
    | No_function -> (p, None)
    | Forward_decl _ ->
        (* We don't have to do anything, because the correct function will be called in the first place.
           Except when it is called with different types recursively. We'll see *)
        (p, None)

let rec morph_expr param (texpr : Typing.typed_expr) =
  let make expr = { typ = texpr.typ; expr } in
  match texpr.expr with
  | Typing.Var v -> (param, make (Mvar v))
  | Const c -> (param, make (Mconst c))
  | Bop (bop, e1, e2) -> morph_bop make param bop e1 e2
  | If (cond, e1, e2) -> morph_if make param cond e1 e2
  | Let (id, e1, e2) -> morph_let make param id e1 e2
  | Record labels -> morph_record make param labels
  | Field (expr, index) -> morph_field make param expr index
  | Sequence (expr, cont) -> morph_seq make param expr cont
  | Function (name, uniq, abs, cont) -> morph_func param (name, uniq, abs, cont)
  | Lambda (id, abs) -> morph_lambda texpr.typ param id abs
  | App { callee; args } -> morph_app make param callee args

and morph_bop mk p bop e1 e2 =
  let p, e1 = morph_expr p e1 in
  let p, e2 = morph_expr p e2 in
  (p, mk (Mbop (bop, e1, e2)))

and morph_if mk p cond e1 e2 =
  let p, cond = morph_expr p cond in
  let p, e1 = morph_expr p e1 in
  let p, e2 = morph_expr p e2 in
  (p, mk (Mif (cond, e1, e2)))

and morph_let mk p id e1 e2 =
  let p, e1 = morph_expr p e1 in
  let p, e2 = morph_expr p e2 in
  (p, mk (Mlet (id, e1, e2)))

and morph_record mk p labels =
  let f param (id, e) =
    let p, e = morph_expr param e in
    (p, (id, e))
  in
  let p, labels = List.fold_left_map f p labels in
  (p, mk (Mrecord labels))

and morph_field mk p expr index =
  let p, e = morph_expr p expr in
  (p, mk (Mfield (e, index)))

and morph_seq mk p expr cont =
  let p, expr = morph_expr p expr in
  let p, cont = morph_expr p cont in
  (p, mk (Mseq (expr, cont)))

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

  (* Make sure recursion works and the current function can be used in its body *)
  let temp_p =
    if recursive then (
      recursion_stack := Vars.empty :: !recursion_stack;
      let vars = Vars.add username (Forward_decl name) p.vars in
      { p with vars })
    else p
  in

  let temp_p, body = morph_expr temp_p abs.body in

  let abs = { func; pnames; body } in
  let gen_func = { abs; name; recursive } in

  let p =
    { p with monomorphized = temp_p.monomorphized; funcs = temp_p.funcs }
  in
  let p =
    if is_type_polymorphic ftyp then
      let vars = Vars.add username (Polymorphic gen_func) p.vars in
      { p with vars }
    else
      let vars = Vars.add username (Concrete gen_func) p.vars in
      let funcs = gen_func :: p.funcs in
      { p with vars; funcs }
  in

  (* TODO handle recursion stack *)
  (match !recursion_stack with
  | _ :: stack -> recursion_stack := stack
  | [] -> failwith "Internal Error: Stack in monomorphization");

  let p, cont = morph_expr p cont in
  (p, { typ = cont.typ; expr = Mfunction (name, abs, cont) })

and morph_lambda typ p id abs =
  let name = lambda_name id in
  let recursive = false in
  let func =
    { params = Typing.(abs.tp.tparams); ret = abs.tp.ret; kind = abs.tp.kind }
  in
  let pnames = abs.nparams in

  let vars = p.vars in
  let p, body = morph_expr p abs.body in

  let abs = { func; pnames; body } in
  let gen_func = { abs; name; recursive } in

  let p = { p with vars } in
  let p =
    if is_type_polymorphic typ then p
    else
      let funcs = gen_func :: p.funcs in
      { p with funcs }
  in
  (p, { typ; expr = Mlambda (name, abs) })

and morph_app mk p callee args =
  let p, callee = morph_expr p callee in
  let p, mono_name = monomorphize_call p callee in

  let f p arg =
    let p, a = morph_expr p arg in
    let p, mono_name = monomorphize_call p a in
    (p, (a, mono_name))
  in
  let p, args = List.fold_left_map f p args in
  (p, mk (Mapp { callee = (callee, mono_name); args }))

let monomorphize { Typing.externals; records; tree } =
  let param = { vars = Vars.empty; monomorphized = Set.empty; funcs = [] } in
  let p, tree = morph_expr param tree in
  { externals; records; tree; funcs = p.funcs }
