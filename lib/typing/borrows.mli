val check_expr :
  mname:Path.t ->
  params:(Types.param * string * Ast.loc) list ->
  Typed_tree.typed_expr ->
  unit

val check_items : mname:Path.t -> Typed_tree.toplevel_item list -> unit
