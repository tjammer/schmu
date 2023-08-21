open Types
module S : Set.S with type elt = Path.t

type t
type loc = Ast.loc

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

val add_local_module : loc -> string -> t -> into:t -> t
val add_module_alias : loc -> string -> Path.t -> into:t -> t
val clear_cache : unit -> unit
val object_names : unit -> string list
val register_module : Env.t -> Ast.loc -> Path.t -> t -> (Env.t, unit) result
val poly_funcs : (Path.t * Typed_tree.toplevel_item) list ref
val paths : string list ref

val find_module :
  Env.t -> Ast.loc -> regeneralize:(typ -> typ) -> string -> Env.cached_module

val scope_of_located : Env.t -> Path.t -> Env.scope
val to_channel : out_channel -> outname:string -> t -> unit
val append_externals : Env.ext list -> Env.ext list
val validate_signature : Env.t -> t -> t
