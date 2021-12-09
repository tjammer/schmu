open Types

type key = string

type label = { typ : typ; index : int; record : string }

type t

val empty : t

val add_value : key -> typ -> t -> t

val add_type : key -> typ -> t -> t

val add_record : key -> labels:(string * typ) list -> t -> t

val new_scope : t -> t

val close_scope : t -> t * string list
(** Returns the variables captured in the closed scope  *)

val find_opt : key -> t -> typ option

val query_opt : key -> t -> typ option
(** [query_opt key env] is like find_opt, but marks [key] as
      being used in the current scope (e.g. a closure) *)

val find : key -> t -> typ

val find_type_opt : key -> t -> typ option

val find_type : key -> t -> typ

val find_label_opt : key -> t -> label option
