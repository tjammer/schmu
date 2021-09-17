type typ = TInt | TBool | TVar of tv ref | QVar of string | TFun of typ * typ

and tv = Unbound of string * int | Link of typ

exception Error of Ast.loc * string

val string_of_type : typ -> string

type expr =
  | Var of string
  | Int of int
  | Bool of bool
  | Bop of Ast.bop * typed_expr * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of string * typed_expr * typed_expr
  | Abs of string * typ * typed_expr
  | App of typed_expr * typed_expr

and typed_expr = { typ : typ; expr : expr }

val typecheck : Ast.expr -> typ

val to_typed : Ast.expr -> typed_expr
