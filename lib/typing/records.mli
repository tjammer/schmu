module type Core = sig
  val convert : Env.t -> Ast.expr -> Typed_tree.typed_expr

  val convert_annot :
    Env.t -> Types.typ option -> Ast.expr -> Typed_tree.typed_expr
end

module type S = sig
  val convert_record :
    Env.t ->
    Ast.loc ->
    Types.typ option ->
    (string * Ast.expr) list ->
    Typed_tree.typed_expr

  val convert_field :
    Env.t ->
    Lexing.position * Lexing.position ->
    Ast.expr ->
    string ->
    Typed_tree.typed_expr

  val convert_field_set :
    Env.t -> Ast.loc -> Ast.expr -> string -> Ast.expr -> Typed_tree.typed_expr
end

module Make (C : Core) : S
