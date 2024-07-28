module Strtbl : Hashtbl.S
module Smap : Map.S with type key = string
module Sset : Set.S with type elt = string

type typ =
  | Tvar of tv ref
  | Qvar of string
  | Tfun of param list * typ * fun_kind
  | Ttuple of typ list
  | Tconstr of Path.t * typ list
  | Traw_ptr of typ
  | Tarray of typ
  | Tfixed_array of iv ref * typ
  | Trc of typ
[@@deriving show { with_path = false }, sexp]

and fun_kind = Simple | Closure of closed list
and tv = Unbound of string * int | Link of typ
and param = { pt : typ; pattr : Ast.decl_attr }
and field = { fname : string; ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }

and iv =
  | Unknown of string * int
  | Known of int
  | Generalized of string
  | Linked of iv ref

and closed = {
  clname : string;
  clmut : bool;
  cltyp : typ;
  clparam : bool;
  clmname : Path.t option;
  clcopy : bool; (* otherwise move *)
}

type type_decl = { params : typ list; kind : decl_kind; in_sgn : bool }

and decl_kind =
  | Drecord of field array
  | Dvariant of bool * ctor array
  | Dabstract of decl_kind option
  | Dalias of typ
[@@deriving sexp, show]

val tunit : typ
val tint : typ
val tfloat : typ
val ti32 : typ
val tf32 : typ
val tbool : typ
val tu8 : typ
val tu16 : typ

val repr : typ -> typ
(** Extract real type (follow links) and do path compression *)

val string_of_type : Path.t -> typ -> string
(** Normal version, will name type vars starting from 'a *)

val fold_builtins : ('a -> string -> type_decl -> 'a) -> 'a -> 'a
(** Fold over all special builtin types to add them to the typing env *)

val is_builtin : typ -> bool
val is_polymorphic : typ -> bool
val is_weak : sub:Sset.t -> typ -> bool
val mut_of_pattr : Ast.decl_attr -> bool
val add_closure_copy : closed list -> string -> closed list option
val is_clike_variant : ctor array -> bool
val is_unbound : typ -> (string * int) option
val subst_generic : id:string -> typ -> typ -> typ
val subst_name : Path.t -> with_:typ -> typ -> typ
val get_generic_ids : typ -> string list
val map_params : inst:typ list -> params:typ list -> typ Smap.t
val typ_of_decl : type_decl -> Path.t -> typ
val resolve_alias : (Path.t -> (type_decl * Path.t) option) -> typ -> typ

val recursion_allowed :
  params:typ list -> Path.t -> typ -> (typ option, string) result
