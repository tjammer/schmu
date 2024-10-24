val the_module : Llvm.llmodule

val generate :
  target:string option ->
  outname:string ->
  release:bool ->
  modul:bool ->
  args:bool ->
  start_loc:Ast.loc ->
  Monomorph_tree.monomorphized_tree ->
  unit
