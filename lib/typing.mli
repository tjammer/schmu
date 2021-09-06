type typ = TInt | TBool | TVar of tv ref | QVar of string | TFun of typ * typ

and tv = Unbound of string * int | Link of typ

exception Error of Ast.loc * string

val string_of_type : typ -> string

val typecheck : Ast.expr -> typ
