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
  | Var of string * Path.t option
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
  | Set of (typed_expr * typed_expr * set_move_kind)
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
  id_loc : loc;
  uniq : int option;
  rmut : bool; (* is mutable generally *)
  pass : dattr; (* is passed mutably on the rhs (def b& -> &a) *)
  rhs : typed_expr; (* attr.mut is the passing on the binder site (def b& <-) *)
  cont : typed_expr;
}

and const =
  | Int of int
  | Bool of bool
  | U8 of char
  | U16 of int
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Array of typed_expr list
  | Fixed_array of typed_expr list
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
  | Tl_module of (Path.t * toplevel_item) list
  | Tl_module_alias of (loc * string) * Path.t

and touched = Env.touched = {
  tname : string;
  ttyp : typ;
  tattr : dattr;
  tattr_loc : loc option;
  tmname : Path.t option;
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
  is_rec : bool;
}

(* TODO function data *)
and generic_fun = { concrete : func; generic : func }
and attr = { const : bool; global : bool; mut : bool }
and set_move_kind = Snot_moved | Spartially_moved | Smoved

let no_attr = { const = false; global = false; mut = false }

type t = { externals : Env.ext list; items : (Path.t * toplevel_item) list }

let rec follow_expr = function
  | ( Var _ | Const _ | Bop _ | Unop _ | Lambda _ | App _ | Record _ | Field _
    | Set _ | Ctor _ | Variant_index _ | Variant_data _ | Fmt _ | Move _ ) as e
    ->
      Some e
  | If _ -> None
  | Let l -> follow_expr l.cont.expr
  | Bind (_, _, cont)
  | Function (_, _, _, cont)
  | Mutual_rec_decls (_, cont)
  | Sequence (_, cont) ->
      follow_expr cont.expr
