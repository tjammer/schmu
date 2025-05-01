val check_expr :
  mname:Path.t ->
  params:(Types.param * string * Ast.loc) list ->
  touched:Typed_tree.touched list ->
  Typed_tree.typed_expr ->
  Typed_tree.touched list

val check_items : mname:Path.t -> Typed_tree.toplevel_item list -> unit
