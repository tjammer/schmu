open Types
module S : Set.S with type elt = Path.t

type t
type loc = Typed_tree.loc

val empty : t
val unique_name : mname:Path.t -> string -> int option -> string
val lambda_name : mname:Path.t -> int -> string
val absolute_module_name : mname:Path.t -> string -> string
val add_type_sig : loc -> string -> typ -> t -> t
val add_value_sig : loc -> string -> typ -> t -> t
val add_type : loc -> typ -> t -> t

val add_fun :
  loc ->
  mname:Path.t ->
  string ->
  int option ->
  Typed_tree.abstraction ->
  t ->
  t

val add_rec_block :
  loc ->
  mname:Path.t ->
  (loc * string * int option * Typed_tree.abstraction) list ->
  t ->
  t

val add_external :
  loc ->
  typ ->
  string ->
  mname:Path.t ->
  string option ->
  closure:bool ->
  t ->
  t

val add_module : loc -> string -> t -> into:t -> t

type cache_kind = Cfile of string | Clocal of Path.t

val module_cache : (Path.t, cache_kind * Env.scope * t) Hashtbl.t
val clear_cache : unit -> unit

val register_module :
  Env.t -> Ast.loc -> Path.t -> cache_kind * t -> (Env.t, unit) result

val poly_funcs : (Path.t * Typed_tree.toplevel_item) list ref
val paths : string list ref
val prelude_path : string option ref
val find_file : string -> string -> string

val find_module :
  Env.t ->
  Ast.loc ->
  regeneralize:(typ -> typ) ->
  string ->
  Path.t * Env.scope * t

val to_channel : out_channel -> outname:string -> t -> unit
val append_externals : Env.ext list -> Env.ext list
val validate_signature : Env.t -> t -> t
