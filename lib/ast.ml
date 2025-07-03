type loc = (Lexing.position * Lexing.position[@opaque]) [@@deriving show]

type ident = loc * string
and mode = ident option

type bop = Equal_i | And | Or [@@deriving show, sexp]
(* Equal_i is used in pattern matches, so we keep it even though it is also
   defined as a builtin function *)

type unop = Uminus_i | Uminus_f [@@deriving show, sexp]

type type_spec =
  | Ty_id of ident
  | Ty_var of ident
  | Ty_applied of type_spec list
  | Ty_func of (mode * type_spec * decl_attr) list
  | Ty_use_id of loc * Path.t
  | Ty_tuple of type_spec list

and decl = {
  loc : loc;
  pattern : pattern;
  annot : type_spec option;
  mode : mode;
}

and decl_attr = Dmut | Dmove | Dnorm | Dset
and func_attr = Fa_single of ident | Fa_param of ident * ident list

and func = {
  name : ident;
  is_rec : bool;
  params : decl list;
  return_annot : (type_spec * loc) option;
  body : block;
  attr : func_attr list;
}

and argument = { apass : decl_attr; aloc : loc; aexpr : expr }
and passed_expr = { pattr : decl_attr; pexpr : expr }

and expr =
  | Var of ident
  | Lit of loc * literal
  | Bop of loc * bop * expr * expr
  | Unop of loc * ident * expr
  | If of loc * expr * expr * expr option
  | Lambda of
      loc * decl list * func_attr list * (type_spec * loc) option * block
  | App of loc * expr * argument list
  | Record of loc * (ident * expr) list
  | Tuple of loc * expr list
  | Record_update of loc * expr * (ident * expr) list
  | Field of loc * expr * string
  | Set of loc * (loc * expr) * expr
  | Do_block of block
  | Pipe of loc * argument * expr * bool (* pipe last *)
  | Ctor of loc * ident * expr option
  | Match of loc * decl_attr * expr * (clause * expr) list
  | Local_use of loc * string * expr

and clause = {
  cloc : loc;
  cpath : Path.t option;
  cpat : pattern;
  guard : (loc * expr) option;
}

and pattern =
  | Pctor of ident * pattern option
  | Pvar of ident * decl_attr
  | Ptup of loc * (loc * pattern) list * decl_attr
  | Pwildcard of loc * decl_attr
  | Precord of loc * (ident * pattern option) list * decl_attr
  | Plit_int of loc * int64
  | Plit_char of loc * char
  | Por of loc * pattern list

and literal =
  | Int of int64
  | Bool of bool
  | U8 of char
  | U16 of int
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Array of expr list
  | Fixed_array of expr list
  | Fixed_array_num of int * expr
  | Unit

and stmt =
  | Let of loc * decl * passed_expr * bool (* is borrow call *)
  | Function of loc * func
  | Expr of loc * expr
  | Rec of loc * (loc * func) list
  | Use of loc * Path.t

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
  | Module of module_decl * top_item list
  | Functor of module_decl * functor_param list * top_item list
  | Module_alias of module_decl * alias_kind
  | Module_type of ident * signature list
  | Signature of loc * signature list
  | Import of ident

and module_decl = loc * string * Path.t option
and functor_param = loc * string * Path.t
and alias_kind = Amodule of path | Afunctor_app of path * path list
and path = loc * Path.t

and signature =
  | Stypedef of loc * typedef
  | Svalue of loc * (ident * type_spec)

and prog = top_item list
