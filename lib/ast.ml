module Loc = struct
  type t = Lexing.position = {
    pos_fname : string;
    pos_lnum : int;
    pos_bol : int;
    pos_cnum : int;
  }
  [@@deriving show { with_path = false }]
end

type loc = Loc.t [@@deriving show]

type bop = Plus | Mult | Less | Equal | Minus
[@@deriving show { with_path = false }]

type type_expr = Atom_type of string | Fun_type of string * string

and decl = string * type_expr option [@@deriving show]

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

(* Hopefully temporary *)
type external_decl = loc * string * type_expr

type prog = external_decl list * expr
