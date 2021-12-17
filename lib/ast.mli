type bop = Plus | Mult | Less | Equal | Minus

type loc = Lexing.position * Lexing.position

(* optional type identifier
   So far only bool and ints and functions *)
type type_spec =
  | Ty_id of string
  | Ty_var of string
  | Ty_expr of type_spec list

type type_expr = type_spec list

type decl = string * type_expr option

type func = {
  name : string;
  params : decl list;
  return_annot : type_spec option;
  body : expr;
  cont : expr;
}

and expr =
  | Var of loc * string
  | Int of loc * int
  | Bool of loc * bool
  | Bop of loc * bop * expr * expr
  | If of loc * expr * expr * expr
  | Let of loc * decl * expr * expr
  | Lambda of loc * decl list * type_spec option * expr
  | Function of loc * func
  | App of loc * expr * expr list
  | Record of loc * (string * expr) list
  | Field of loc * expr * string
  | Sequence of loc * expr * expr

type external_decl = loc * string * type_expr

(* Only records *)
type typedef = {
  poly_param : string option;
  name : string;
  labels : (string * type_expr) array;
  loc : loc;
}

type prog = {
  external_decls : external_decl list;
  typedefs : typedef list;
  expr : expr;
}
