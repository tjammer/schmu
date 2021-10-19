type bop = Plus | Mult | Less | Equal | Minus

type loc = Lexing.position

(* optional type identifier
   So far only bool and ints and functions *)
type type_expr = string list

type decl = string * type_expr option

type func = { name : decl; params : decl list; body : expr; cont : expr }

and expr =
  | Var of loc * string
  | Int of loc * int
  | Bool of loc * bool
  | Bop of loc * bop * expr * expr
  | If of loc * expr * expr * expr
  | Let of loc * decl * expr * expr
  | Lambda of loc * decl list * expr
  | Function of loc * func
  | App of loc * expr * expr list
[@@deriving show { with_path = false }]

type external_decl = loc * string * type_expr

(* Only records *)
type typedef = { name : string; labels : (string * type_expr) list }

type prog = {
  external_decls : external_decl list;
  typedefs : typedef list;
  expr : expr;
}
