module Loc = struct
  type t = Lexing.position = {
    pos_fname : string;
    pos_lnum : int;
    pos_bol : int;
    pos_cnum : int;
  }
  [@@deriving show { with_path = false }]
end

type bop = Plus | Mult | Less | Equal [@@deriving show { with_path = false }]

type expr =
  | Var of Loc.t * string
  | Int of Loc.t * int
  | Bool of Loc.t * bool
  | Bop of Loc.t * bop * expr * expr
  | If of Loc.t * expr * expr * expr
  | Let of Loc.t * string * expr * expr
[@@deriving show { with_path = false }]
