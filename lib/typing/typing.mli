type msg_fn = string -> Ast.loc -> string -> string

val typecheck : Ast.prog -> Types.typ

val to_typed :
  ?check_ret:bool ->
  mname:Path.t option ->
  msg_fn ->
  prelude:bool ->
  Ast.prog ->
  Typed_tree.t * Module.t option
