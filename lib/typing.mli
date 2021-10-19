type typ =
  | TInt
  | TBool
  | TUnit
  | TVar of tv ref
  | QVar of string
  | TFun of typ list * typ * fun_kind

and fun_kind = Simple | Anon | Closure of (string * typ) list

and tv = Unbound of string * int | Link of typ

exception Error of Ast.loc * string

val string_of_type : typ -> string

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

and typed_expr = { typ : typ; expr : expr }

type external_decl = string * typ

val typecheck : Ast.prog -> typ

val to_typed : Ast.prog -> external_decl list * typed_expr
