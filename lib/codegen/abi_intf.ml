type unboxed_atom = Ints of int | F32 | F32_vec | Float

type unboxed =
  | One_param of unboxed_atom
  | Two_params of unboxed_atom * unboxed_atom
  | Arr of unboxed_atom * int
  | Hfa_ret of unboxed_atom * int
  | Int_ret of int

type aggregate_param_kind = Boxed | Unboxed of unboxed

module type S = sig
  open Cleaned_types

  (* Register pools available for argument passing in the active ABI *)
  type reg_pool = { int : int; sse : int }

  val set_pool : reg_pool -> unit
  val pool_of_triple : string -> reg_pool
  val byval_aggregate : unit -> bool
  (* for current abi *)

  val sret_attribute : unit -> bool
  (* for current abi *)

  val pkind_of_typ : bool -> typ -> aggregate_param_kind
  (* param kind *)

  val rkind_of_typ : bool -> typ -> aggregate_param_kind
  (* return kind *)

  (* For each param returns the passing kind, its llvm index, how many params it
     expands to *)
  val classify_params :
    sret:bool -> param list -> (param * aggregate_param_kind * int * int) list

  val lltype_unbox : unboxed_atom -> Llvm.lltype
  val lltype_unboxed : unboxed -> typ -> Llvm.lltype

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

  val maybe_box_record_kind :
    aggregate_param_kind ->
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
