open Types

exception Error of Ast.loc * string

val string_of_type : typ -> string

type expr =
  | Var of string
  | Const of const
  | Bop of Ast.bop * typed_expr * typed_expr
  | Unop of Ast.unop * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of string * typed_expr * typed_expr
  | Lambda of int * abstraction (* strictly increasing lambda id *)
  | Function of string * int option * abstraction * typed_expr
  | App of { callee : typed_expr; args : typed_expr list }
  | Record of (string * typed_expr) list
  | Field of (typed_expr * int)
  | Field_set of (typed_expr * int * typed_expr)
  | Sequence of (typed_expr * typed_expr)
[@@deriving show]

and typed_expr = { typ : typ; expr : expr; is_const : bool }

and const =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Vector of typed_expr list
  | Unit

and func = { tparams : typ list; ret : typ; kind : fun_kind }
and abstraction = { nparams : string list; body : typed_expr; tp : func }
and generic_fun = { concrete : func; generic : func }

type external_decl = string * typ * string option
(* The option is the real c name if the value was renamed for schmu usage *)

val typecheck : Ast.prog -> typ

type codegen_tree = {
  externals : external_decl list;
  records : typ list;
  tree : typed_expr;
}

type msg_fn = string -> Ast.loc -> string -> string

val to_typed : msg_fn -> prelude:Ast.prog -> Ast.prog -> codegen_tree
