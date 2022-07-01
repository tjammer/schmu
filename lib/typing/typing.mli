type external_decl = string * Types.typ * string option

type codegen_tree = {
  externals : external_decl list;
  typedefs : Types.typ list;
  typeinsts : Types.typ list;
  items : Typed_tree.toplevel_item list;
}

type msg_fn = string -> Ast.loc -> string -> string

val typecheck : Ast.prog -> Types.typ

val to_typed :
  ?check_ret:bool -> msg_fn -> prelude:Ast.prog -> Ast.prog -> codegen_tree
