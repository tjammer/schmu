open Types

type t
type loc = Typed_tree.loc

val empty : t
val unique_name : string -> int option -> string
val lambda_name : string option -> int -> string
val add_type : loc -> typ -> t -> t
val add_fun : loc -> string -> int option -> Typed_tree.abstraction -> t -> t

val add_rec_block :
  loc -> (loc * string * int option * Typed_tree.abstraction) list -> t -> t

val add_external :
  loc -> typ -> string -> string option -> closure:bool -> t -> t

val module_cache : (string, (t, string) result) Hashtbl.t
val poly_funcs : Typed_tree.toplevel_item list ref
val paths : string list ref
val prelude_path : string option ref
val find_file : string -> string -> string
val read_exn : regeneralize:(typ -> typ) -> string -> Ast.loc -> t
val add_to_env : Env.t -> string -> t -> Env.t
val to_channel : out_channel -> outname:string -> t -> unit
val append_externals : Env.ext list -> Env.ext list
