open Types

type key = string
type label = { index : int; typename : Path.t }
type t

type value = {
  typ : typ;
  param : bool;
  const : bool;
  global : bool;
  mut : bool;
  mname : Path.t option;
}

type warn_kind = Unused | Unmutated | Unused_mod | Unconstructed | Unused_ctor

type unused = (key * warn_kind * Ast.loc) list

and touched = {
  tname : string;
  ttyp : typ;
  tattr : Ast.decl_attr;
  tattr_loc : Ast.loc option;
  tmname : Path.t option;
  tusage : mode; (* Set by borrowing pass. [Many] before *)
  tmut : bool;
  tcopy : bool;
  tcaptured : bool;
  tparam : bool;
}

type callname = string * Path.t option * int option

type ext = {
  ext_name : string;
  ext_typ : typ;
  ext_cname : callname option;
  imported : (Path.t * [ `C | `Schmu ]) option;
  used : bool ref;
  closure : bool;
}
(* return type for values *)

type scope
type cached_module = Cm_located of Path.t | Cm_cached of Path.t * scope

val def_value : t -> value
(** Default value, everything is false *)

val def_mname : Path.t -> value
(** Default value, everything is false with Path arg is mname *)

val empty :
  find_module:(Ast.loc -> Path.t -> cached_module) ->
  scope_of_located:(t -> Path.t -> (scope, string) result) ->
  Path.t ->
  t

val add_value : key -> value -> Ast.loc -> t -> t
(** [add_value key value loc] add value [key] defined at [loc] with type [typ] to env *)

val add_external : key -> cname:callname option -> typ -> Ast.loc -> t -> t
(** like [add_value], but keeps track of external declarations *)

val change_type : key -> typ -> t -> t
(** To give the generalized type with closure for functions *)

val get_used : key -> t -> bool

val set_used : key -> t -> bool -> bool
(** Returns if the usage value was changed. To not mark internal recursive calls as used *)

val add_type :
  Ast.loc option -> ?append_module:bool -> string -> type_decl -> t -> t

val add_module : key:string -> cached_module -> t -> t
val add_module_alias : Ast.loc -> key:string -> mname:Path.t -> t -> t
val add_module_type : string -> Module_type.t -> t -> t
val open_function : t -> t
val open_toplevel : Path.t -> t -> t
val close_function : t -> t * touched list * unused

val close_toplevel : t -> t * touched list * unused
(** Returns the variables captured in the closed function scope, and first unused var  *)

val use_module : t -> Ast.loc -> Path.t -> t
(** Like OCaml open *)

val find_val : Ast.loc -> Path.t -> t -> value
val find_val_opt : Ast.loc -> Path.t -> t -> value option

val query_val_opt :
  Ast.loc -> Path.t -> instantiate:(typ -> typ) -> t -> value option
(** [query_opt key env] is like find_val_opt, but marks [key] as
     being used in the current scope (e.g. a closure) *)

val open_mutation : t -> unit
val close_mutation : t -> unit
val find_type_opt : Ast.loc -> Path.t -> t -> (type_decl * Path.t) option

val find_type_absolute_opt :
  Ast.loc -> Path.t -> t -> (type_decl * Path.t) option
(** Like [find_type_opt], but will correctly handle builtins *)

val find_type : Ast.loc -> Path.t -> t -> type_decl * Path.t
val find_type_same_module : string -> t -> (type_decl * Path.t) option
val find_module_opt : ?query:bool -> Ast.loc -> Path.t -> t -> Path.t option

val find_module_type_opt :
  Ast.loc -> Path.t -> t -> (Path.t * Module_type.t) option

val find_label_opt : key -> t -> label option
(** [find_label_opt labelname env] returns the name of first record with a matching label *)

val find_labelset_opt : Ast.loc -> string list -> t -> typ option
(** [find_labelset_opt labelnames env] returns the first record type with a matching labelset *)

val find_ctor_opt : key -> [< `Construct | `Match ] -> t -> label option
(** [find_ctor_opt cname env] returns the variant of which the ctor is part of
    as well as the type of the ctor if it has data *)

val add_ctor_loc : key -> Ast.loc -> t -> t
(** [add_ctor_loc cname loc env] returns the env with the added location to the ctor *)

val construct_ctor_of_variant :
  key -> Path.t -> [< `Construct | `Match ] -> t -> unit

val externals : t -> ext list
(** [externals env] returns a list of all external function declarations *)

val modpath : t -> Path.t
val open_module_scope : t -> Ast.loc -> Path.t -> t
val pop_scope : t -> scope
val fix_scope_loc : scope -> Ast.loc -> scope

(* Call names*)
val add_callname : key:string -> callname -> t -> t

val find_callname : Ast.loc -> key -> Path.t -> t -> callname option
(** Don't return option because if a callname isn't found it's an internal error *)

val decl_tbl : t -> (Path.t, type_decl) Hashtbl.t
