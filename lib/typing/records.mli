module type Core = sig
  val convert : Env.t -> Ast.expr -> Typed_tree.typed_expr

  type context

  val no_ctx : context

  val convert_annot :
    Env.t ->
    Types.typ option * Types.mode option ->
    context ->
    Ast.expr ->
    Typed_tree.typed_expr
end

module type S = sig
  val convert_record :
    Env.t ->
    Ast.loc ->
    Types.typ option * Types.mode option ->
    (Ast.borrow_pass * Ast.ident * Ast.expr) list ->
    Typed_tree.typed_expr

  val convert_record_update :
    Env.t ->
    Ast.loc ->
    Types.typ option * Types.mode option ->
    Ast.expr ->
    (Ast.borrow_pass * Ast.ident * Ast.expr) list ->
    Typed_tree.typed_expr

  val convert_field :
    Env.t ->
    Lexing.position * Lexing.position ->
    Ast.expr ->
    string ->
    Typed_tree.typed_expr

  val get_record_type :
    Env.t -> Ast.loc -> string list -> Types.typ option -> Types.typ

  val fields_of_record :
    Ast.loc ->
    Path.t ->
    Types.typ list option ->
    Env.t ->
    (Types.field array, unit) result
end

module Make (C : Core) : S
