type msg_fn = string -> Ast.loc -> string -> string

val typecheck : Ast.prog -> Types.typ

val to_typed :
  ?check_ret:bool -> msg_fn -> prelude:Ast.prog -> Ast.prog -> Typed_tree.t
