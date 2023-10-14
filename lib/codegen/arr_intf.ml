module type S = sig
  open Cleaned_types
  open Llvm_types

  val gen_array_lit :
    Llvm_types.param ->
    Monomorph_tree.monod_tree list ->
    typ ->
    Monomorph_tree.alloca ->
    llvar

  val gen_fixed_array_lit :
    Llvm_types.param ->
    Monomorph_tree.monod_tree list ->
    typ ->
    Monomorph_tree.allocas ref ->
    llvar

  val array_get : llvar list -> typ -> llvar
  val array_length : unsafe:bool -> llvar list -> llvar
  val array_capacity : llvar list -> llvar
  val array_realloc : llvar list -> llvar
  val array_drop_back : param -> llvar list -> llvar
  val array_data : llvar list -> llvar

  val unsafe_array_create :
    param -> llvar list -> typ -> Monomorph_tree.alloca -> llvar

  val item_type_head_size : typ -> typ * Llvm.lltype * int * int

  val iter_array_children :
    llvar -> Llvm.llvalue -> typ -> (llvar -> unit) -> unit

  val iter_fixed_array_children : llvar -> int -> typ -> (llvar -> unit) -> unit
end
