type typ =
  | Tint
  | Tbool
  | Tunit
  | Ti8
  | Tu8
  | Ti16
  | Tu16
  | Tfloat
  | Ti32
  | Tu32
  | Tf32
  | Tpoly of string
  | Tfun of param list * typ * fun_kind
  | Trecord of typ list * field recurs_kind * string option
  | Tvariant of typ list * ctor recurs_kind * string
  | Traw_ptr of typ
  | Tarray of typ
  | Tfixed_array of int * typ
  | Trc of rc_kind * typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure
and param = { pt : typ; pmut : bool; pmoved : bool }
and field = { ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }
and 'a recurs_kind = Rec_not of 'a array | Rec_top of 'a array | Rec_folded

and closed = {
  clname : string;
  clmut : bool;
  cltyp : typ;
  clparam : bool;
  clcopy : bool;
  clmoved : Mod_id.t option;
}

and rc_kind = Strong | Weak

val is_type_polymorphic : typ -> bool
val string_of_type : typ -> string

val is_struct : typ -> bool
(** [is_struct typ] returns whether the type is implemented as a struct in codegen  *)

val is_aggregate : typ -> bool
val contains_allocation : typ -> bool
val is_folded : typ -> bool

val of_typ : Types.typ -> typ
(** Only works for primitive types *)

val is_int : typ -> bool
val is_float : typ -> bool

val is_signed : typ -> bool
(** Only works for ints *)
