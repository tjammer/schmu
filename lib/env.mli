open Types

type key = string

type t

val empty : t

val add_value : key -> typ -> t -> t

val new_scope : t -> t

val close_scope : t -> t * string list
(** Returns the variables captured in the closed scope  *)

val find_opt : key -> t -> typ option

val query_opt : key -> t -> typ option
(** [query_opt key env] is like find_opt, but marks [key] as
      being used in the current scope (e.g. a closure) *)

val find : key -> t -> typ
