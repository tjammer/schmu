(* Basically the same as the typed tree, except the function calls at
   application carry info on which monomorphized instance to use.
   Also, the extraction of functions for code generation has already taken place *)

open Types

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

val monomorphize : Typing.codegen_tree -> monomorphized_tree