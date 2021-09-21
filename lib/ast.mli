type bop = Plus | Mult | Less | Equal | Minus [@@deriving show]

type loc = Lexing.position

type expr =
  | Var of loc * string
  | Int of loc * int
  | Bool of loc * bool
  | Bop of loc * bop * expr * expr
  | If of loc * expr * expr * expr
  | Let of loc * string * expr * expr
  | Abs of loc * string * expr
  | App of loc * expr * expr
[@@deriving show { with_path = false }]
