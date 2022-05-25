open Types

type expr =
  | Var of string
  | Const of const
  | Bop of Ast.bop * typed_expr * typed_expr
  | Unop of Ast.unop * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of string * typed_expr * typed_expr
  | Lambda of int * abstraction
  | Function of string * int option * abstraction * typed_expr
  | App of { callee : typed_expr; args : typed_expr list }
  | Record of (string * typed_expr) list
  | Field of (typed_expr * int)
  | Field_set of (typed_expr * int * typed_expr)
  | Sequence of (typed_expr * typed_expr)
  | Ctor of (string * int * typed_expr option)
  | Variant_index of typed_expr
  | Variant_data of typed_expr
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

exception Error of Ast.loc * string
