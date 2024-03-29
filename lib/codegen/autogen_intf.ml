module type S = sig
  open Llvm_types

  val copy : param -> Monomorph_tree.alloca -> llvar -> llvar
  val free : param -> llvar -> unit
  val free_except : param -> Malloc_types.Pset.t -> llvar -> unit
  val gen_functions : unit -> unit

  (* Closures *)
  val get_ctor :
    Llvm.lltype ->
    Cleaned_types.closed list ->
    bool (* upward *) ->
    Llvm.llvalue

  val get_dtor : Llvm.lltype -> Cleaned_types.closed list -> Llvm.llvalue
end
