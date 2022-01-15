type loc = Lexing.position * Lexing.position
type bop = Plus | Mult | Less | Equal | Minus [@@deriving show]

type type_spec =
  | Ty_id of string
  | Ty_var of string
  | Ty_list of type_spec list
  | Ty_func of type_spec list

type type_expr = type_spec list
and decl = string * type_expr option

type func = {
  name : string;
  params : decl list;
  return_annot : type_spec option;
  body : expr;
  cont : expr;
}

and expr =
  | Var of loc * string
  | Lit of loc * literal
  | Bop of loc * bop * expr * expr
  | If of loc * expr * expr * expr
  | Let of loc * decl * expr * expr
  | Lambda of loc * decl list * type_spec option * expr
  | Function of loc * func
  | App of loc * expr * expr list
  | Record of loc * (string * expr) list
  | Field of loc * expr * string
  | Sequence of loc * expr * expr
  | Pipe_head of loc * expr * expr
  | Pipe_tail of loc * expr * expr

and literal = Int of int | Bool of bool | Char of char | String of string

(* Hopefully temporary *)
type external_decl = loc * string * type_expr

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
