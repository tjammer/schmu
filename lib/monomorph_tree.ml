open Types
module Vars = Map.Make (String)
module Set = Set.Make (String)

type const = Typing.const

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

and func = { params : typ list; ret : typ; kind : fun_kind }

and abstraction = { func : func; pnames : string list; body : monod_tree }

and monod_expr = monod_tree * string option

and monod_tree = { typ : typ; expr : expr }

(* type subst = typ Vars.t *)

type to_gen_func = {
  abs : abstraction;
  name : string;
  recursive : bool; (* subst : subst option; *)
}

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
(* | No_function *)

type morph_param = {
  vars : to_gen_func_kind Vars.t;
  monomorphized : Set.t;
  funcs : to_gen_func list; (* to generate in codegen *)
}

let recursion_stack = ref []

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
  | Function (name, uniq, abs, cont) ->
      morph_func texpr.typ param (name, uniq, abs, cont)
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

and morph_func typ p (username, uniq, abs, cont) =
  (* If the function is concretely typed, we add it to the function list and
           add the usercode name to the bound variables. In the polymorphic case,
           we add the function to the bound variables, but not to the function list.
     Instead, the monomorphized instance will be added later *)
  Printf.printf "typ in function: %s\n%!" (show_typ typ);

  let name = unique_name (username, uniq) in
  let recursive = true in
  let func =
    { params = Typing.(abs.tp.tparams); ret = abs.tp.ret; kind = abs.tp.kind }
  in
  let pnames = abs.nparams in

  (* Make sure recursion works and the current function can be used in its body *)
  let p =
    if recursive then (
      recursion_stack := Vars.empty :: !recursion_stack;
      let vars = Vars.add username (Forward_decl name) p.vars in
      { p with vars })
    else p
  in

  let p, body = morph_expr p abs.body in

  let abs = { func; pnames; body } in
  let gen_func = { abs; name; recursive (* subst = None *) } in

  let p =
    if is_type_polymorphic typ then (
      Printf.printf "Polymoric function: %s\n%!" name;
      let vars = Vars.add username (Polymorphic gen_func) p.vars in
      { p with vars })
    else (
      Printf.printf "Concrete function: %s\n%!" name;
      let vars = Vars.add username (Concrete gen_func) p.vars in
      let funcs = gen_func :: p.funcs in
      { p with vars; funcs })
  in

  (* TODO handle recursion stack *)
  (match !recursion_stack with
  | _ :: stack -> recursion_stack := stack
  | [] -> failwith "Internal Error: Stack in monomorphization");

  let p, cont = morph_expr p cont in
  (p, { typ; expr = Mfunction (name, abs, cont) })

and morph_lambda typ p id abs =
  (* TODO *)
  let name = lambda_name id in
  let recursive = false in
  let func =
    { params = Typing.(abs.tp.tparams); ret = abs.tp.ret; kind = abs.tp.kind }
  in
  let pnames = abs.nparams in

  let p, body = morph_expr p abs.body in

  let abs = { func; pnames; body } in
  let gen_func = { abs; name; recursive (* subst = None *) } in

  let p =
    if is_type_polymorphic typ then (
      Printf.printf "Polymorphic lambda: %s\n%!" name;
      p)
    else (
      Printf.printf "Concrete function: %s\n%!" name;
      let funcs = gen_func :: p.funcs in
      { p with funcs })
  in
  (p, { typ; expr = Mlambda (name, abs) })

and morph_app mk p callee args =
  let p, callee = morph_expr p callee in
  Printf.printf "In App: callee typ: %s\n%!" (show_typ callee.typ);

  let f p arg =
    let p, a = morph_expr p arg in
    (p, (a, None))
  in
  let p, args = List.fold_left_map f p args in
  (p, mk (Mapp { callee = (callee, None); args }))

let monomorphize { Typing.externals; records; tree } =
  let param = { vars = Vars.empty; monomorphized = Set.empty; funcs = [] } in
  let p, tree = morph_expr param tree in
  { externals; records; tree; funcs = p.funcs }
