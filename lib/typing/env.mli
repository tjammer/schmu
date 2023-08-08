open Types

type key = string
type label = { index : int; typename : Path.t }
type t
type imported = Path.t * [ `C | `Schmu ]

type value = {
  typ : typ;
  param : bool;
  const : bool;
  global : bool;
  imported : imported option;
  mut : bool;
}

type warn_kind = Unused | Unmutated | Unused_mod
type unused = (unit, (Path.t * warn_kind * Ast.loc) list) result

type touched_kind = Tnone | Tconst | Tglobal | Timported of Path.t

and touched = {
  tname : string;
  ttyp : typ;
  tattr : Ast.decl_attr;
  tattr_loc : Ast.loc option;
  tkind : touched_kind;
}

type return = {
  typ : typ;
  const : bool;
  global : bool;
  mut : bool;
  imported : Path.t option;
}

type ext = {
  ext_name : string;
  ext_typ : typ;
  ext_cname : string option;
  imported : imported option;
  used : bool ref;
  closure : bool;
}
(* return type for values *)

val def_value : value
(** Default value, everything is false *)

val empty : Path.t -> t

val add_value : key -> value -> Ast.loc -> t -> t
(** [add_value key value loc] add value [key] defined at [loc] with type [typ] to env *)

val add_external :
  key ->
  cname:string option ->
  typ ->
  imported:imported option ->
  closure:bool ->
  Ast.loc ->
  t ->
  t
(** like [add_value], but keeps track of external declarations *)

val change_type : key -> typ -> t -> t
(** To give the generalized type with closure for functions *)

val add_type : string -> in_sig:bool -> typ -> t -> t
val add_module : key:string -> mname:Path.t -> t -> t
val open_function : t -> t

val close_function : t -> t * closed list * touched list * unused
(** Returns the variables captured in the closed function scope, and first unused var  *)

val open_module : t -> Ast.loc -> string -> t
(** Doesn't actually open the module, but makes the env ready for matching the following adds to a module *)

val finish_module : t -> t
val close_module : t -> t
val find_val : key -> t -> return
val find_val_opt : key -> t -> return option

val query_val_opt : key -> t -> return option
(** [query_opt key env] is like find_val_opt, but marks [key] as
     being used in the current scope (e.g. a closure) *)

val open_mutation : t -> unit
val close_mutation : t -> unit

(* bool: in signature *)
val find_type_opt : Path.t -> t -> (typ * bool) option
val find_type : Path.t -> t -> typ * bool
val find_type_same_module : string -> t -> (typ * bool) option

val query_type : instantiate:(typ -> typ) -> Path.t -> t -> typ
(** [query_type name env] is like [find_type], but instantiates new types for parametrized types*)

val find_module_opt : string -> t -> Path.t option

val find_label_opt : key -> t -> label option
(** [find_label_opt labelname env] returns the name of first record with a matching label *)

val find_labelset_opt : string list -> t -> typ option
(** [find_labelset_opt labelnames env] returns the first record type with a matching labelset *)

val find_ctor_opt : key -> t -> label option
(** [find_ctor_opt cname env] returns the variant of which the ctor is part of
    as well as the type of the ctor if it has data *)

val externals : t -> ext list
(** [externals env] returns a list of all external function declarations *)

val open_module_scope : string -> t -> t
val close_module_scope : t -> t
val modpath : t -> Path.t
