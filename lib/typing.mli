open Types

exception Error of Ast.loc * string

val string_of_type : typ -> string

type expr =
  | Var of string
  | Const of const
  | Bop of Ast.bop * typed_expr * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of string * typed_expr * typed_expr
  | Lambda of int * abstraction (* strictly increasing lambda id *)
  | Function of string * int option * abstraction * typed_expr
  | App of { callee : typed_expr; args : typed_expr list }
  | Record of (string * typed_expr) list
  | Field of (typed_expr * int)
  | Sequence of (typed_expr * typed_expr)
[@@deriving show]

and typed_expr = { typ : typ; expr : expr }
and const = Int of int | Bool of bool | Unit | U8 of char | String of string

(* TODO use some type as in monomorphization *)
and fun_pieces = { tparams : typ list; ret : typ; kind : fun_kind }
and abstraction = { nparams : string list; body : typed_expr; tp : fun_pieces }
and generic_fun = { concrete : fun_pieces; generic : fun_pieces }

type external_decl = string * typ

val typecheck : Ast.prog -> typ

type codegen_tree = {
  externals : external_decl list;
  records : typ list;
  tree : typed_expr;
}

val to_typed : Ast.prog -> codegen_tree
val is_type_polymorphic : typ -> bool
