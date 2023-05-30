module type S = sig
  open Llvm_types

  val copy : param -> Monomorph_tree.alloca -> llvar -> llvar
  val free : llvar -> unit
  val gen_functions : unit -> unit
end
