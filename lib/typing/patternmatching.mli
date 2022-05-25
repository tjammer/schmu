module type Core = sig
  val convert : Env.t -> Ast.expr -> Typed_tree.typed_expr
  val convert_var : Env.t -> Ast.loc -> string -> Typed_tree.typed_expr

  val convert_block :
    ?ret:bool -> Env.t -> Ast.block -> Typed_tree.typed_expr * Env.t
end

module type S = sig
  val convert_ctor :
    Env.t ->
    Ast.loc ->
    Ast.loc * string ->
    Ast.expr option ->
    Types.typ option ->
    Typed_tree.typed_expr

  val convert_match :
    Env.t ->
    Ast.loc ->
    Ast.expr ->
    (Ast.loc * Ast.pattern * Ast.block) list ->
    Typed_tree.typed_expr
end

module Make (C : Core) : S
