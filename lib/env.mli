open Types

type key = string
type label = { typ : typ; index : int; record : string }
type t

val empty : t
val add_value : key -> typ -> t -> t
val add_type : key -> typ -> t -> t

val add_record :
  key -> param:int option -> labels:(string * typ) array -> t -> t
(** [add record record_name ~param ~labels env] returns an env with anadded record named [record_name]
     optionally parametrized by [param] with typed [labels] *)

val maybe_add_record_instance : key -> typ -> t -> unit
(** [maybe_add_record_instance record_name ~param typ] mutably adds a concrete parametrization
         of a record if [param] is Some type and the same instance has not already been added  *)

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

val query_type : newvar:(unit -> typ) -> key -> t -> typ
(** [query_type name env] is like [find_type], but instantiates new types for parametrized types*)

val find_label_opt : key -> t -> label option

val records : t -> typ list
(** [records env] returns a list of all named records for codegen *)
