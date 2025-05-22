val check_expr :
  mname:Path.t ->
  params:(Types.param * string * Ast.loc) list ->
  touched:Typed_tree.touched list ->
  Typed_tree.typed_expr ->
  Typed_tree.typed_expr * Typed_tree.touched list

val check_items :
  mname:Path.t ->
  Ast.loc ->
  touched:Typed_tree.touched list ->
  Typed_tree.toplevel_item list ->
  Typed_tree.toplevel_item list
