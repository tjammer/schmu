type bop = Plus | Mult | Less | Equal | Minus [@@deriving show]

type loc = Lexing.position

(* optional type identifier
   So far only bool and ints and functions with arity 1 *)
type type_expr = Atom_type of string | Fun_type of string * string

type decl = string * type_expr option

type expr =
  | Var of loc * string
  | Int of loc * int
  | Bool of loc * bool
  | Bop of loc * bop * expr * expr
  | If of loc * expr * expr * expr
  | Let of loc * decl * expr * expr
  | Abs of loc * decl * expr
  | App of loc * expr * expr
[@@deriving show { with_path = false }]

type external_decl = loc * string * type_expr

type prog = external_decl list * expr
