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
  body : block;
}

and expr =
  | Var of loc * string
  | Lit of loc * literal
  | Bop of loc * bop * expr * expr
  | If of loc * expr * block * block
  | Lambda of loc * decl list * type_spec option * block
  | App of loc * expr * expr list
  | Record of loc * (string * expr) list
  | Field of loc * expr * string
  | Pipe_head of loc * expr * expr
  | Pipe_tail of loc * expr * expr

and literal =
  | Int of int
  | Bool of bool
  | U8 of char
  | String of string
  | Vector of expr list

and stmt =
  | Let of loc * decl * block
  | Function of loc * func
  | Expr of (loc * expr)

and block = loc * stmt list

type external_decl = loc * string * type_expr
type typename = { name : string; poly_param : string option }
type record = { name : typename; labels : (string * type_expr) array }
type typedef = Trecord of record | Talias of typename * type_spec
type preface = Ext_decl of external_decl | Typedef of loc * typedef
type prog = { preface : preface list; block : block }
