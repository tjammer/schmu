type msg_fn = string -> Ast.loc -> string -> string

val main_path : Path.t
val typecheck : Ast.prog -> Types.typ

val to_typed :
  ?check_ret:bool ->
  mname:Path.t ->
  msg_fn ->
  prelude:bool ->
  Ast.prog ->
  Typed_tree.t * Module.t
