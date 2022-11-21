open Types

type t = item list [@@deriving sexp]

and item =
  | Mtype of typ
  | Mfun of typ * string
  | Mext of typ * string * string option
  | Mpoly_fun of Typed_tree.abstraction * string

val unique_name : string -> int option -> string
val lambda_name : int -> string
val add_type : typ -> t -> t
val add_fun : string -> int option -> Typed_tree.abstraction -> t -> t
val add_external : typ -> string -> string option -> t -> t
val module_cache : (string, (t, string) result) Hashtbl.t
val poly_funcs : Typed_tree.toplevel_item list ref
val paths : string list ref
val prelude_path : string option ref
val find_file : string -> string -> string
val read_exn : regeneralize:(typ -> typ) -> string -> Ast.loc -> t
val add_to_env : Env.t -> string option -> t -> Env.t
val to_channel : out_channel -> string -> t -> unit
