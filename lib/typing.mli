type typ =
  | TInt
  | TBool
  | TUnit
  | TVar of tv ref
  | QVar of string
  | TFun of typ * typ

and tv = Unbound of string * int | Link of typ

exception Error of Ast.loc * string

val string_of_type : typ -> string

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

val typecheck : Ast.expr -> typ

val to_typed :
  Ast.external_decl list -> Ast.expr -> external_decl list * typed_expr
