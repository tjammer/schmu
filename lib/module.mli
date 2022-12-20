open Types

type t = item list [@@deriving sexp]
and name = { user : string; call : string }

and item =
  | Mtype of typ
  | Mfun of typ * name
  | Mext of typ * name * bool (* is closure *)
  | Mpoly_fun of Typed_tree.abstraction * string * int option
  | Mmutual_rec of (string * int option * typ) list

val unique_name : string -> int option -> string
val lambda_name : int -> string
val add_type : typ -> t -> t
val add_fun : string -> int option -> Typed_tree.abstraction -> t -> t

val add_rec_block :
  (string * int option * Typed_tree.abstraction) list -> t -> t

val add_external : typ -> string -> string option -> closure:bool -> t -> t
val module_cache : (string, (t, string) result) Hashtbl.t
val poly_funcs : Typed_tree.toplevel_item list ref
val paths : string list ref
val prelude_path : string option ref
val find_file : string -> string -> string
val read_exn : regeneralize:(typ -> typ) -> string -> Ast.loc -> t
val add_to_env : Env.t -> string -> t -> Env.t
val to_channel : out_channel -> outname:string -> t -> unit
