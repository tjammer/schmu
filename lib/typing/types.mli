module Strtbl : Hashtbl.S
module Smap : Map.S with type key = string
module Sset : Set.S with type elt = string

type typ =
  | Tprim of primitive
  | Tvar of tv ref
  | Qvar of string
  | Tfun of param list * typ * fun_kind
  | Talias of Path.t * typ
  | Trecord of typ list * Path.t option * field array
  | Tvariant of typ list * typ option * Path.t * ctor array
  | Traw_ptr of typ
  | Tarray of typ
  | Tabstract of typ list * Path.t * typ
  | Tfixed_array of iv ref * typ
  | Trc of typ
[@@deriving show { with_path = false }, sexp]

and primitive = Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32
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

val tunit : typ
val tint : typ
val tfloat : typ
val ti32 : typ
val tf32 : typ
val tbool : typ
val tu8 : typ
val tu16 : typ

val clean : typ -> typ
(** Follows links and aliases *)

val string_of_type : Path.t -> typ -> string
(** Normal version, will name type vars starting from 'a *)

val string_of_type_lit : Path.t -> typ -> string
(** Version with literal type vars (for annotations) *)

val string_of_type_subst : string Smap.t -> Path.t -> typ -> string
(** Version using the subst table created during comparison with annot *)

val create_string_of_type : Path.t -> typ -> string
(** Used for creating the subst function, for printing error messages *)

val is_polymorphic : typ -> bool
val is_weak : sub:Sset.t -> typ -> bool
val extract_name_path : typ -> Path.t option
val contains_allocation : typ -> bool
val mut_of_pattr : Ast.decl_attr -> bool
val add_closure_copy : closed list -> string -> closed list option
val is_clike_variant : typ -> bool
val is_unbound : typ -> (string * int) option
val subst_generic : id:string -> typ -> typ -> typ
val get_generic_ids : typ -> string list
val unfold : typ -> typ
val allowed_recursion : recurs:typ -> typ -> (bool, string) result
