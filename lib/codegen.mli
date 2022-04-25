val the_module : Llvm.llmodule

val generate :
  target:string option ->
  outname:string ->
  release:bool ->
  Monomorph_tree.monomorphized_tree ->
  unit
