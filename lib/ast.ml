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
[@@deriving show, sexp]
(* Eventually, this will be handled differently, hopefully not as hardcoded *)

type unop = Uminus_i | Uminus_f [@@deriving show, sexp]

type type_spec =
  | Ty_id of string
  | Ty_var of string
  | Ty_list of type_spec list
  | Ty_func of (type_spec * bool) list
  | Ty_open_id of loc * type_spec * string

and decl = {
  loc : loc;
  ident : loc * string;
  mut : bool;
  annot : type_spec option;
}

type func = {
  name : loc * string;
  params : decl list;
  return_annot : type_spec option;
  body : block;
  attr : (loc * string) option;
}

and argument = { amut : bool; aloc : loc; aexpr : expr }

and expr =
  | Var of loc * string
  | Lit of loc * literal
  | Bop of loc * bop * expr list
  | Unop of loc * unop * expr
  | If of loc * expr * expr * expr option
  | Let_e of loc * decl * expr * expr
  | Lambda of loc * decl list * block
  | App of loc * expr * argument list
  | Record of loc * (string * expr) list
  | Tuple of loc * expr list
  | Record_update of loc * expr * (string * expr) list
  | Field of loc * expr * string
  | Set of loc * (loc * expr) * expr
  | Do_block of block
  | Pipe_head of loc * argument * pipeable
  | Pipe_tail of loc * argument * pipeable
  | Ctor of loc * (loc * string) * expr option
  | Match of loc * expr * (loc * pattern * expr) list
  | Local_open of loc * string * expr
  | Fmt of loc * expr list

and pipeable = Pip_expr of expr | Pip_field of string

and pattern =
  | Pctor of (loc * string) * pattern option
  | Pvar of loc * string
  | Ptup of loc * (loc * pattern) list
  | Pwildcard of loc
  | Precord of loc * (loc * string * pattern option) list
  | Plit_int of loc * int
  | Por of pattern list

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
  | Let of loc * decl * expr
  | Function of loc * func
  | Expr of (loc * expr)

and block = stmt list

type external_decl = loc * (loc * string) * type_spec * string option
type typename = { name : string; poly_param : string list }
type record = { name : typename; labels : (bool * string * type_spec) array }

type ctor = {
  name : loc * string;
  typ_annot : type_spec option;
  index : int option;
}

type variant = { name : typename; ctors : ctor list }

type typedef =
  | Trecord of record
  | Talias of typename * type_spec
  | Tvariant of variant

type top_item =
  | Stmt of stmt
  | Ext_decl of external_decl
  | Typedef of loc * typedef
  | Open of loc * string

type prog = top_item list
