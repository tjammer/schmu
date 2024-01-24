type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tu16
  | Tfloat
  | Ti32
  | Tf32
  | Tpoly of string
  | Tfun of param list * typ * fun_kind
  | Trecord of typ list * string option * field array
  | Tvariant of typ list * string * ctor array
  | Traw_ptr of typ
  | Tarray of typ
  | Tfixed_array of int * typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of closed list
and param = { pt : typ; pmut : bool; pmoved : bool }
and field = { ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }

and closed = {
  clname : string;
  clmut : bool;
  cltyp : typ;
  clparam : bool;
  clcopy : bool;
}

val is_type_polymorphic : typ -> bool
val string_of_type : typ -> string

val is_struct : typ -> bool
(** [is_struct typ] returns whether the type is implemented as a struct in codegen  *)

val is_aggregate : typ -> bool
val contains_allocation : typ -> bool
