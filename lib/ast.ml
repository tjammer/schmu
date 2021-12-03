module Loc = struct
  type t = Lexing.position = {
    pos_fname : string;
    pos_lnum : int;
    pos_bol : int;
    pos_cnum : int;
  }
end

type loc = Loc.t

type bop = Plus | Mult | Less | Equal | Minus

type type_spec = Ty_id of string | Ty_var of string

type type_expr = type_spec list

and decl = string * type_expr option [@@deriving show]

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
  | Record of loc * (string * expr) list
  | Field of loc * expr * string
[@@deriving show { with_path = false }]

(* Hopefully temporary *)
type external_decl = loc * string * type_expr

type typedef = { name : string; labels : (string * type_expr) list; loc : loc }

type prog = {
  external_decls : external_decl list;
  typedefs : typedef list;
  expr : expr;
}
