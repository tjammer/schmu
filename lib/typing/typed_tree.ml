open Types
open Sexplib0.Sexp_conv

module Show = struct
  type pos = Lexing.position = {
    pos_fname : string;
    pos_lnum : int;
    pos_bol : int;
    pos_cnum : int;
  }
  [@@deriving show, sexp]
end

type loc = Show.pos * Show.pos [@@deriving show, sexp]

type expr =
  | Var of string
  | Const of const
  | Bop of Ast.bop * typed_expr * typed_expr
  | Unop of Ast.unop * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of let_data
  | Lambda of int * abstraction
  | Function of string * int option * abstraction * typed_expr
  | Rec of (string * int option * abstraction) list * typed_expr
  | App of { callee : typed_expr; args : arg list }
  | Record of (string * typed_expr) list
  | Field of (typed_expr * int)
  | Set of (typed_expr * typed_expr)
  | Sequence of (typed_expr * typed_expr)
  | Ctor of (string * int * typed_expr option)
  | Variant_index of typed_expr
  | Variant_data of typed_expr
  | Fmt of fmt list
[@@deriving show, sexp]

and typed_expr = { typ : typ; expr : expr; attr : attr; loc : loc }
and fmt = Fstr of string | Fexpr of typed_expr

and let_data = {
  id : string;
  uniq : int option;
  rmut : bool;
  lhs : typed_expr;
  cont : typed_expr;
}

and const =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Array of typed_expr list
  | Unit

and toplevel_item =
  | Tl_let of string * int option * typed_expr
  | Tl_function of string * int option * abstraction
  | Tl_expr of typed_expr
  | Tl_rec of (string * int option * abstraction) list

and func = { tparams : param list; ret : typ; kind : fun_kind }
and arg = typed_expr * bool

and abstraction = {
  nparams : string list;
  body : typed_expr;
  func : func;
  inline : bool;
}

(* TODO function data *)
and generic_fun = { concrete : func; generic : func }
and attr = { const : bool; global : bool; mut : bool }

let no_attr = { const = false; global = false; mut = false }

exception Error of Ast.loc * string

type t = { externals : Env.ext list; items : toplevel_item list }
