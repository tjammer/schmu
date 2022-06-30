module Strtbl : Hashtbl.S
module Smap : Map.S with type key = string

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
  | Tfun of typ list * typ * fun_kind
  | Talias of string * typ
  | Trecord of typ option * string * field array
  | Tvariant of typ option * string * ctor array
  | Tptr of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list
and tv = Unbound of string * int | Link of typ
and field = { name : string; typ : typ; mut : bool }
and ctor = { ctorname : string; ctortyp : typ option }

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
val to_sexp : typ -> Sexplib0.Sexp.t
val of_sexp : Sexplib0.Sexp.t -> typ
