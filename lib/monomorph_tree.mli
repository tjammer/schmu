(* Basically the same as the typed tree, except the function calls at
   application carry info on which monomorphized instance to use.
   Also, the extraction of functions for code generation has already taken place *)

open Cleaned_types

type expr =
  | Mvar of string * var_kind
  | Mconst of const
  | Mbop of Ast.bop * monod_tree * monod_tree
  | Munop of Ast.unop * monod_tree
  | Mif of ifexpr
  | Mlet of
      string * monod_tree * let_kind * global_name * malloc_list * monod_tree
  | Mbind of string * monod_tree * monod_tree
  | Mlambda of string * fun_kind * typ * alloca
  | Mfunction of string * fun_kind * typ * monod_tree * alloca
  | Mapp of {
      callee : monod_expr;
      args : (monod_expr * bool) list;
      alloca : alloca;
      id : int; (* Internal id for nested monomorphization *)
      ms : malloc_list;
    }
  | Mrecord of (string * monod_tree) list * alloca * malloc_list
  | Mfield of (monod_tree * int)
  | Mset of (monod_tree * monod_tree * bool (* is moved *))
  | Mseq of (monod_tree * monod_tree)
  | Mctor of (string * int * monod_tree option) * alloca * malloc_list
  | Mvar_index of monod_tree
  | Mvar_data of monod_tree * int option
  | Mfmt of fmt list * alloca * int
  | Mprint_str of fmt list
  | Mfree_after of monod_tree * free_list
[@@deriving show]

and const =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Array of monod_tree list * alloca * int
  | Fixed_array of monod_tree list * alloca * int list
  | Unit
(* The int is the malloc id used for freeing later *)

and func = { params : param list; ret : typ; kind : fun_kind }

and abstraction = {
  func : func;
  pnames : (string * int option) list;
  body : monod_tree;
}

and call_name =
  | Mono of string (* Monomorphized fun call *)
  | Concrete of string (* Normal function call with unique name *)
  | Default (* std *)
  | Recursive of { nonmono : string; call : string }
  (* Recursive function call.
     The nonmono name is only for housekeeping *)
  | Builtin of Builtin.t * func
  | Inline of (string * int option) list * monod_tree
(* Builtin function with special codegen *)

and monod_expr = { ex : monod_tree; monomorph : call_name; mut : bool }

and monod_tree = {
  typ : typ;
  expr : expr;
  return : bool;
  loc : Ast.loc;
  const : const_kind;
}

and alloca = allocas ref
and request = { id : int; lvl : int }
and allocas = Preallocated | Request of request

and ifexpr = {
  cond : monod_tree;
  owning : int option;
  e1 : monod_tree;
  e2 : monod_tree;
}

and var_kind = Vnorm | Vconst | Vglobal of string
and global_name = string option
and fmt = Fstr of string | Fexpr of monod_tree
and copy_kind = Cglobal of string | Cnormal of bool
and malloc_list = int list

and free_list =
  | Except of Malloc_types.malloc_id list
  | Only of Malloc_types.malloc_id list

and let_kind = Lowned | Lborrow
and const_kind = Const | Cnot (* | Constexpr *)

type recurs = Rnormal | Rtail | Rnone
type func_name = { user : string; call : string }

type to_gen_func = {
  abs : abstraction;
  name : func_name;
  recursive : recurs;
  upward : unit -> bool;
  monomorphized : bool;
}

type external_decl = {
  ext_name : string;
  ext_typ : typ;
  cname : string;
  c_linkage : bool;
  closure : bool;
}

type monomorphized_tree = {
  constants : (string * monod_tree * bool) list; (* toplvl bool *)
  globals : (string * monod_tree * bool) list; (* toplvl bool *)
  externals : external_decl list;
  tree : monod_tree;
  funcs : to_gen_func list;
  frees : Malloc_types.malloc_id Seq.t;
}

val typ_of_abs : abstraction -> typ
val monomorphize : mname:Path.t -> Typed_tree.t -> monomorphized_tree
val get_mono_name : string -> poly:typ -> closure:bool -> typ -> string
val short_name : closure:bool -> typ -> string
