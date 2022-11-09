module type S = sig
  open Cleaned_types
  open Llvm_types

  val gen_array_lit :
    Llvm_types.param ->
    Monomorph_tree.monod_tree list ->
    typ ->
    Monomorph_tree.alloca ->
    llvar

  val array_get : in_set:bool -> llvar list -> typ -> llvar
  val array_set : llvar list -> llvar
  val array_length : llvar list -> llvar
  val array_push : llvar list -> llvar
  val array_drop_back : llvar list -> llvar
  val array_data : llvar list -> llvar
  val incr_refcount : llvar -> unit
  val decr_refcount : llvar -> unit
  val gen_functions : unit -> unit
  val contains_array : typ -> bool
end
