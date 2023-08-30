module type Core = sig
  val convert : Env.t -> Ast.expr -> Typed_tree.typed_expr
  val convert_var : Env.t -> Ast.loc -> Path.t -> Typed_tree.typed_expr

  val convert_block :
    ?ret:bool -> Env.t -> Ast.block -> Typed_tree.typed_expr * Env.t
end

module type Recs = sig
  val get_record_type :
    Env.t -> Ast.loc -> string list -> Types.typ option -> Types.typ
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
    (Ast.loc * Ast.pattern * Ast.expr) list ->
    Typed_tree.typed_expr

  val pattern_id : int -> Ast.pattern -> string * Ast.loc * bool

  val convert_decl :
    Env.t -> Ast.decl list -> Env.t * (string * Typed_tree.typed_expr) list
end

module Make (C : Core) (R : Recs) : S
