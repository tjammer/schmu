type loc = (Lexing.position * Lexing.position[@opaque]) [@@deriving show]
type ident = loc * string

type bop =
  | Plus_i
  | Mult_i
  | Div_i
  | Less_i
  | Greater_i
  | Less_eq_i
  | Greater_eq_i
  | Equal_i
  | Minus_i
  | Plus_f
  | Mult_f
  | Div_f
  | Less_f
  | Greater_f
  | Less_eq_f
  | Greater_eq_f
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
  | Ty_func of (type_spec * decl_attr) list
  | Ty_import_id of loc * Path.t
  | Ty_tuple of type_spec list

and decl = {
  loc : loc;
  pattern : pattern;
  dattr : decl_attr;
  annot : type_spec option;
}

and decl_attr = Dmut | Dmove | Dnorm | Dset
and func_attr = Fa_single of ident | Fa_param of ident * ident list

and func = {
  name : ident;
  params : decl list;
  return_annot : type_spec option;
  body : block;
  attr : func_attr list;
}

and argument = { apass : decl_attr; aloc : loc; aexpr : expr }
and passed_expr = { pattr : decl_attr; pexpr : expr }

and expr =
  | Var of ident
  | Lit of loc * literal
  | Bop of loc * bop * expr list
  | Unop of loc * unop * expr
  | If of loc * expr * expr * expr option
  | Let_e of loc * decl * passed_expr * expr
  | Lambda of loc * decl list * func_attr list * block
  | App of loc * expr * argument list
  | Record of loc * (string * expr) list
  | Tuple of loc * expr list
  | Record_update of loc * expr * (string * expr) list
  | Field of loc * expr * string
  | Set of loc * (loc * expr) * expr
  | Do_block of block
  | Pipe_head of loc * argument * pipeable
  | Pipe_tail of loc * argument * pipeable
  | Ctor of loc * ident * expr option
  | Match of loc * expr * (loc * pattern * expr) list
  | Local_import of loc * string * expr
  | Fmt of loc * expr list

and pipeable = Pip_expr of expr | Pip_field of string

and pattern =
  | Pctor of ident * pattern option
  | Pvar of ident
  | Ptup of loc * (loc * pattern) list
  | Pwildcard of loc
  | Precord of loc * (ident * pattern option) list
  | Plit_int of loc * int
  | Plit_char of loc * char
  | Por of loc * pattern list

and literal =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Array of expr list
  | Fixed_array of expr list
  | Fixed_array_num of int * expr
  | Unit

and stmt =
  | Let of loc * decl * passed_expr
  | Function of loc * func
  | Expr of loc * expr
  | Rec of loc * (loc * func) list
  | Import of loc * Path.t

and block = stmt list

type external_decl = loc * ident * type_spec * string option
type typename = { name : string; poly_param : string list }
type record = { name : typename; labels : (bool * string * type_spec) array }
type ctor = { name : ident; typ_annot : type_spec option; index : int option }
type variant = { name : typename; ctors : ctor list }

type typedef =
  | Trecord of record
  | Talias of typename * type_spec
  | Tvariant of variant
  | Tabstract of typename

type top_item =
  | Stmt of stmt
  | Ext_decl of external_decl
  | Typedef of loc * typedef
  | Module of module_decl * signature list * top_item list
  | Functor of module_decl * functor_param list * signature list * top_item list
  | Module_alias of module_decl * alias_kind
  | Module_type of ident * signature list

and module_decl = loc * string * Path.t option
and functor_param = loc * string * Path.t
and alias_kind = Amodule of path | Afunctor_app of path * path list
and path = loc * Path.t

and signature =
  | Stypedef of loc * typedef
  | Svalue of loc * (ident * type_spec)

and prog = signature list * top_item list
