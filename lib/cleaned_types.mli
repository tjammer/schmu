type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tfloat
  | Ti32
  | Tf32
  | Tpoly of string
  | Tfun of typ list * typ * fun_kind
  | Trecord of typ option * string * field array
  | Tvariant of typ option * string * ctor array
  | Tptr of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list
and field = { ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }

val is_type_polymorphic : typ -> bool
val string_of_type : typ -> string

val is_struct : typ -> bool
(** [is_struct typ] returns whether the type is implemented as a struct in codegen  *)

val is_aggregate : typ -> bool
