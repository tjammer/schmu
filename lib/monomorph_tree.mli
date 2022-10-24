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
  | Mlet of string * monod_tree * global_name * monod_tree
  | Mlambda of string * abstraction
  | Mfunction of string * abstraction * monod_tree
  | Mapp of {
      callee : monod_expr;
      args : monod_expr list;
      alloca : alloca;
      malloc : int option;
      (* Mallocs have to go through a call to get propagated.
         Codegen must check if there are nested allocations *)
      id : int; (* Internal id for nested monomorphization *)
    }
  | Mrecord of (string * monod_tree) list * alloca * bool (* bool: is_const *)
  | Mfield of (monod_tree * int)
  | Mset of (monod_tree * monod_tree)
  | Mseq of (monod_tree * monod_tree)
  | Mfree_after of monod_tree * int
  | Mctor of (string * int * monod_tree option) * alloca * bool
  | Mvar_index of monod_tree
  | Mvar_data of monod_tree
  | Mfmt of fmt list * alloca * int
  | Mcopy of {
      kind : copy_kind;
      temporary : bool;
      expr : monod_tree;
      nm : string;
    }

and const =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string * alloca
  | Vector of int * monod_tree list * alloca
  | Array of monod_tree list * alloca
  | Unit
(* The int is the malloc id used for freeing later *)

and func = { params : param list; ret : typ; kind : fun_kind }
and abstraction = { func : func; pnames : string list; body : monod_tree }

and call_name =
  | Mono of string (* Monomorphized fun call *)
  | Concrete of string (* Normal function call with unique name *)
  | Default (* std *)
  | Recursive of string
  (* Recursive function call.
     The function name is only for housekeeping *)
  | Builtin of Builtin.t * func
  | Inline of string list * monod_tree
(* Builtin function with special codegen *)

and monod_expr = { ex : monod_tree; monomorph : call_name; mut : bool }
and monod_tree = { typ : typ; expr : expr; return : bool }
and alloca = allocas ref
and request = { id : int; lvl : int }
and allocas = Preallocated | Request of request
and ifexpr = { cond : monod_tree; e1 : monod_tree; e2 : monod_tree }
and var_kind = Vnorm | Vconst | Vglobal
and global_name = string option
and fmt = Fstr of string | Fexpr of monod_tree
and copy_kind = Cglobal of string | Cnormal of bool

type recurs = Rnormal | Rtail | Rnone
type func_name = { user : string; call : string }
type to_gen_func = { abs : abstraction; name : func_name; recursive : recurs }

type external_decl = {
  ext_name : string;
  ext_typ : typ;
  cname : string;
  c_linkage : bool;
}

type monomorphized_tree = {
  constants : (string * monod_tree * bool) list; (* toplvl bool *)
  globals : (string * typ * bool) list; (* toplvl bool *)
  externals : external_decl list;
  tree : monod_tree;
  frees : int list;
  funcs : to_gen_func list;
}

val typ_of_abs : abstraction -> typ
val monomorphize : Typed_tree.t -> monomorphized_tree
