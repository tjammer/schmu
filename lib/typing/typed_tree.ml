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
  | If of typed_expr * bool option * typed_expr * typed_expr
  | Let of let_data
  | Bind of string * typed_expr * typed_expr
  | Lambda of int * abstraction
  | Function of string * int option * abstraction * typed_expr
  | Mutual_rec_decls of (string * int option * typ) list * typed_expr
  | App of { callee : typed_expr; args : arg list }
  | Record of (string * typed_expr) list
  | Field of (typed_expr * int * string)
  | Set of (typed_expr * typed_expr)
  | Sequence of (typed_expr * typed_expr)
  | Ctor of (string * int * typed_expr option)
  | Variant_index of typed_expr
  | Variant_data of typed_expr
  | Fmt of fmt list
  | Move of typed_expr
[@@deriving show, sexp]

and typed_expr = { typ : typ; expr : expr; attr : attr; loc : loc }
and fmt = Fstr of string | Fexpr of typed_expr

and let_data = {
  id : string;
  uniq : int option;
  rmut : bool; (* is mutable generally *)
  pass : dattr; (* is passed mutably *)
  rhs : typed_expr;
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
  | Tl_let of {
      loc : loc;
      id : string;
      uniq : int option;
      rmut : bool;
      pass : dattr;
      lhs : typed_expr;
    }
  | Tl_bind of string * typed_expr
  | Tl_function of loc * string * int option * abstraction
  | Tl_expr of typed_expr
  | Tl_mutual_rec_decls of (string * int option * typ) list
  | Tl_module of (Path.t option * toplevel_item) list

and touched_kind = Env.touched_kind = Tnone | Tconst | Tglobal | Timported

and touched = Env.touched = {
  tname : string;
  ttyp : typ;
  tattr : dattr;
  tattr_loc : loc option;
  tkind : touched_kind;
}

and func = {
  tparams : param list;
  ret : typ;
  kind : fun_kind;
  touched : touched list;
      (* Like closed variables but also includes globals, consts *)
}

and dattr = Ast.decl_attr = Dmut | Dmove | Dnorm | Dset
and arg = typed_expr * dattr

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

type t = {
  externals : Env.ext list;
  items : (Path.t option * toplevel_item) list;
}
