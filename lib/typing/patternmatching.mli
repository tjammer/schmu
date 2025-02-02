module type Core = sig
  val convert : Env.t -> Ast.expr -> Typed_tree.typed_expr
  val convert_var : Env.t -> Ast.loc -> Path.t -> Typed_tree.typed_expr

  val convert_block :
    ?ret:bool ->
    pipe:bool ->
    Env.t ->
    Ast.block ->
    Typed_tree.typed_expr * Env.t

  val pass_mut_helper :
    Env.t ->
    Ast.loc ->
    Ast.decl_attr ->
    (unit -> Typed_tree.typed_expr) ->
    Typed_tree.typed_expr
end

module type Recs = sig
  val get_record_type :
    Env.t -> Ast.loc -> string list -> Types.typ option -> Types.typ

  val fields_of_record :
    Ast.loc ->
    Path.t ->
    Types.typ list option ->
    Env.t ->
    (Types.field array, unit) result
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
    Ast.decl_attr ->
    Ast.expr ->
    (Ast.clause * Ast.expr) list ->
    Typed_tree.typed_expr

  val pattern_id : int -> Ast.pattern -> string * Ast.loc * bool * Ast.decl_attr

  val convert_decl :
    Env.t -> Ast.decl list -> Env.t * (string * Typed_tree.typed_expr) list
end

module Make (C : Core) (R : Recs) : S
