(* TODO check_unused fn *)
open Types

type key = string
type label = { index : int; record : string }
type t
type unused = (unit, (string * Ast.loc) list) result
type return = { typ : typ; is_const : bool } (* return type for values *)

val empty : (typ -> string) -> t

val add_value :
  key -> typ -> Ast.loc -> ?is_const:bool -> ?is_param:bool -> t -> t
(** [add_value key typ loc ~is_param] add value [key] defined at [loc] with type [typ] to env.
    [is_param] defaults to false *)

val change_type : key -> typ -> t -> t
(** To give the generalized type with closure for functions *)

val add_type : key -> typ -> t -> t

val add_record : key -> param:typ option -> labels:field array -> t -> t
(** [add record record_name ~param ~labels env] returns an env with anadded record named [record_name]
     optionally parametrized by [param] with typed [labels] *)

val maybe_add_record_instance : key -> typ -> t -> unit
(** [maybe_add_record_instance record_name ~param typ] mutably adds a concrete parametrization
         of a record if [param] is Some type and the same instance has not already been added  *)

val add_alias : key -> typ -> t -> t
val open_function : t -> t

val close_function : t -> t * (string * typ) list * unused
(** Returns the variables captured in the closed function scope, and first unused var  *)

val find_val : key -> t -> return
val find_val_opt : key -> t -> return option

val query_val_opt : key -> t -> return option
(** [query_opt key env] is like find_val_opt, but marks [key] as
     being used in the current scope (e.g. a closure) *)

val find_type_opt : key -> t -> typ option
val find_type : key -> t -> typ

val query_type : instantiate:(typ -> typ) -> key -> t -> typ
(** [query_type name env] is like [find_type], but instantiates new types for parametrized types*)

val find_label_opt : key -> t -> label option
(** [find_label_opt labelname env] returns the name of first record with a matching label *)

val find_labelset_opt : string list -> t -> typ option
(** [find_labelset_opt labelnames env] returns the first record type with a matching labelset *)

val records : t -> typ list
(** [records env] returns a list of all named records for codegen *)
