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
    Monomorph_tree.const_kind ->
    bool ->
    llvar

  val data_ptr : Llvm.llvalue -> Llvm.llvalue
  val len_ptr : Llvm.llvalue -> Llvm.llvalue
  val cap_ptr : Llvm.llvalue -> Llvm.llvalue
  val item_type : typ -> typ
  val array_get : llvar list -> typ -> llvar
  val array_length : unsafe:bool -> llvar list -> llvar
  val array_capacity : unsafe:bool -> llvar list -> llvar

  val unsafe_array_pop_back :
    param -> llvar list -> Monomorph_tree.alloca -> llvar

  val array_data : llvar list -> llvar
  val unsafe_array_create : param -> typ -> Monomorph_tree.alloca -> llvar

  val iter_array_children :
    llvar -> Llvm.llvalue -> typ -> (llvar -> unit) -> unit

  val iter_fixed_array_children : llvar -> int -> typ -> (llvar -> unit) -> unit

  val create_stringlit : Llvm_types.param -> Llvm.llvalue -> int -> llvar
end
