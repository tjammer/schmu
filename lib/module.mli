open Types
module S : Set.S with type elt = Path.t

type t = Module_common.t
type loc = Ast.loc

val empty : t
val unique_name : mname:Path.t -> string -> int option -> string
val lambda_name : mname:Path.t -> int -> string
val absolute_module_name : mname:Path.t -> string -> string
val add_type_sig : loc -> string -> type_decl -> t -> t
val add_value_sig : loc -> string -> typ -> t -> t
val add_type : loc -> string -> type_decl -> t -> t

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
  loc -> typ -> string -> string option -> closure:bool -> t -> t

val add_alias : loc -> string -> Typed_tree.typed_expr -> t -> t
val add_local_module : loc -> string -> t -> into:t -> t
val add_module_alias : loc -> string -> Path.t -> into:t -> t
val add_module_type : loc -> string -> Module_type.t -> t -> t
val add_applied_functor : loc -> string -> Path.t -> t -> into:t -> t

val add_functor :
  loc ->
  string ->
  (string * Module_type.t) list ->
  Typed_tree.toplevel_item list ->
  t ->
  into:t ->
  t

val clear_cache : unit -> unit
val object_names : unit -> string list
val register_module : Env.t -> Ast.loc -> Path.t -> t -> (Env.t, unit) result

val register_functor :
  Env.t ->
  Ast.loc ->
  Path.t ->
  (string * Module_type.t) list ->
  Typed_tree.toplevel_item list ->
  t ->
  (Env.t, unit) result

val register_applied_functor :
  Env.t -> Ast.loc -> string -> Path.t -> t -> Env.t

val poly_funcs : (Path.t * Typed_tree.toplevel_item) list ref
val paths : string list ref
val find_module : Env.t -> Ast.loc -> string -> Env.cached_module

val scope_of_functor_param :
  Env.t -> loc -> param:Path.t -> Module_type.t -> Env.cached_module
(** Make scopes out of a functor param to add it to the env *)

val import_module :
  Env.t -> Ast.loc -> regeneralize:(typ -> typ) -> string -> Env.t

val scope_of_located : Env.t -> Path.t -> (Env.scope, string) Result.t
val of_located : Env.t -> Path.t -> (t, string) Result.t

type functor_data =
  Path.t * (string * Module_type.t) list * Typed_tree.toplevel_item list * t

val functor_data : Env.t -> loc -> Path.t -> (functor_data, string) result
val to_channel : out_channel -> outname:string -> t -> unit
val append_externals : Env.ext list -> Env.ext list
val validate_intf : Env.t -> mname:Path.t -> Module_type.t -> t -> unit
val validate_signature : Env.t -> t -> t

val to_module_type : t -> Module_type.t
(** Throws if [t] isn't a pure module type *)
