module Strtbl : Hashtbl.S
module Smap : Map.S with type key = string
module Sset : Set.S with type elt = string

type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tfloat
  | Ti32
  | Tf32
  | Tvar of tv ref
  | Qvar of string
  | Tfun of param list * typ * fun_kind
  | Talias of Path.t * typ
  | Trecord of typ list * Path.t option * field array
  | Tvariant of typ list * Path.t * ctor array
  | Traw_ptr of typ
  | Tarray of typ
[@@deriving show { with_path = false }, sexp]

and fun_kind = Simple | Closure of closed list
and tv = Unbound of string * int | Link of typ
and param = { pt : typ; pmut : bool }
and field = { fname : string; ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }
and closed = { clname : string; clmut : bool; cltyp : typ }

val clean : typ -> typ
(** Follows links and aliases *)

val is_struct : typ -> bool
(** Same as [Cleaned_types.is_struct] *)

val string_of_type : typ -> string
(** Normal version, will name type vars starting from 'a *)

val string_of_type_lit : typ -> string
(** Version with literal type vars (for annotations) *)

val string_of_type_subst : string Smap.t -> typ -> string
(** Version using the subst table created during comparison with annot *)

val is_polymorphic : typ -> bool
val is_weak : sub:Sset.t -> typ -> bool
