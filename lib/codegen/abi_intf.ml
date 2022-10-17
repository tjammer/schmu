module type S = sig
  open Cleaned_types

  type unboxed_atom = Ints of int | F32 | F32_vec | Float

  type unboxed =
    | One_param of unboxed_atom
    | Two_params of unboxed_atom * unboxed_atom

  type aggregate_param_kind = Boxed | Unboxed of unboxed

  val pkind_of_typ : bool -> typ -> aggregate_param_kind
  val lltype_unbox : unboxed_atom -> Llvm.lltype
  val lltype_unboxed : unboxed -> Llvm.lltype

  val unbox_record :
    kind:unboxed ->
    ret:bool ->
    Llvm_types.llvar ->
    Llvm.llvalue * Llvm.llvalue option

  val maybe_box_record :
    bool ->
    typ ->
    ?alloc:Llvm.llvalue option ->
    ?snd_val:Llvm.llvalue option ->
    Llvm.llvalue ->
    Llvm.llvalue

  val box_record :
    typ ->
    size:unboxed ->
    ?alloc:Llvm.llvalue option ->
    snd_val:Llvm.llvalue option ->
    Llvm.llvalue ->
    Llvm.llvalue

  val type_unboxed : unboxed -> typ
end
