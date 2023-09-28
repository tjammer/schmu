module type S = sig
  open Cleaned_types
  open Llvm_types

  val gen_array_lit :
    Llvm_types.param ->
    Monomorph_tree.monod_tree list ->
    typ ->
    Monomorph_tree.alloca ->
    llvar

  val array_get : llvar list -> typ -> llvar
  val array_length : llvar list -> llvar
  val array_push : llvar list -> llvar
  val array_drop_back : param -> llvar list -> llvar
  val array_data : llvar list -> llvar

  val unsafe_array_create :
    param -> llvar list -> typ -> Monomorph_tree.alloca -> llvar

  val unsafe_array_set_length : llvar list -> llvar
  val item_type_head_size : typ -> typ * Llvm.lltype * int * int

  val iter_array_children :
    llvar -> Llvm.llvalue -> typ -> (llvar -> unit) -> unit

  val gen_functions : unit -> unit
end
