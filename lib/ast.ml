type loc = Lexing.position * Lexing.position

type bop =
  | Plus_i
  | Mult_i
  | Div_i
  | Less_i
  | Greater_i
  | Equal_i
  | Minus_i
  | Plus_f
  | Mult_f
  | Div_f
  | Less_f
  | Greater_f
  | Equal_f
  | Minus_f
  | And
  | Or
[@@deriving show]
(* Eventually, this will be handled differently, hopefully not as hardcoded *)

type unop = Uminus_i | Uminus_f [@@deriving show]

type type_spec =
  | Ty_id of string
  | Ty_var of string
  | Ty_list of type_spec list
  | Ty_func of type_spec list

type type_expr = type_spec list
and decl = loc * (loc * string) * type_expr option

type func = {
  name : loc * string;
  params : decl list;
  return_annot : type_spec option;
  body : block;
}

and expr =
  | Var of loc * string
  | Lit of loc * literal
  | Bop of loc * bop * expr * expr
  | Unop of loc * unop * expr
  | If of loc * expr * block * block option
  | Lambda of loc * decl list * block
  | App of loc * expr * expr list
  | Record of loc * (string * expr) list
  | Field of loc * expr * string
  | Field_set of loc * expr * string * expr
  | Pipe_head of loc * expr * expr
  | Pipe_tail of loc * expr * expr
  | Ctor of loc * (loc * string) * expr option
  | Match of loc * expr list * (loc * pattern * block) list

and pattern =
  | Pctor of (loc * string) * pattern option
  | Pvar of loc * string
  | Ptup of loc * pattern list
  | Pwildcard of loc

and literal =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Vector of expr list
  | Unit

and stmt =
  | Let of loc * decl * block
  | Function of loc * func
  | Expr of (loc * expr)

and block = stmt list

type external_decl = loc * (loc * string) * type_expr * string option
type typename = { name : string; poly_param : string option }
type record = { name : typename; labels : (bool * string * type_expr) array }
type ctor = { name : loc * string; typ_annot : type_spec option }
type variant = { name : typename; ctors : ctor list }

type typedef =
  | Trecord of record
  | Talias of typename * type_spec
  | Tvariant of variant

type top_item =
  | Block of block
  | Ext_decl of external_decl
  | Typedef of loc * typedef

type prog = top_item list
