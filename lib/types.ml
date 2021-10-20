type typ =
  | TInt
  | TBool
  | TUnit
  | TVar of tv ref
  | QVar of string
  | TFun of typ list * typ * fun_kind

and fun_kind = Simple | Anon | Closure of (string * typ) list

and tv = Unbound of string * int | Link of typ
