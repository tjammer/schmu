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

type decl = string * string option [@@deriving show]

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
