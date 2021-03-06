open Types

type key = string
type label = { index : int; typename : string }
type t

type value = {
  typ : typ;
  param : bool;
  const : bool;
  global : bool;
  imported : bool;
}

type unused = (unit, (string * Ast.loc) list) result
type return = { typ : typ; const : bool; global : bool }
type imported = [ `C | `Schmu ]

type ext = {
  ext_name : string;
  ext_typ : typ;
  ext_cname : string option;
  imported : imported option;
}
(* return type for values *)

val def_value : value
(** Default value, everything is false *)

val empty : unit -> t

val add_value : key -> value -> Ast.loc -> t -> t
(** [add_value key value loc] add value [key] defined at [loc] with type [typ] to env *)

val add_external :
  key ->
  cname:string option ->
  typ ->
  imported:imported option ->
  Ast.loc ->
  t ->
  t
(** like [add_value], but keeps track of external declarations *)

val change_type : key -> typ -> t -> t
(** To give the generalized type with closure for functions *)

val add_type : key -> typ -> t -> t

val add_record : key -> param:typ option -> labels:field array -> t -> t
(** [add record record_name ~param ~labels env] returns an env with an added record named [record_name]
     optionally parametrized by [param] with typed [labels] *)

val add_variant : key -> param:typ option -> ctors:ctor array -> t -> t
(** [add_variant variant_name ~param ~ctors env] returns an env with an added variant named [variant_name]
    optionally parametrized by [param] with [ctors] *)

val maybe_add_type_instance : typ -> t -> unit
(** [maybe_add_type_instance record_name ~param typ] mutably adds a concrete parametrization
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

val find_ctor_opt : key -> t -> label option
(** [find_ctor_opt cname env] returns the variant of which the ctor is part of
    as well as the type of the ctor if it has data *)

val typedefs : t -> typ list
(** [typedefs env] returns a list of all named typedefs for module exporting *)

val typeinstances : t -> typ list
(** [typeinstances env] return a list of all instanced types for codegen*)

val externals : t -> ext list
(** [externals env] returns a list of all external function declarations *)
