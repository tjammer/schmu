module type S = sig
  open Llvm_types

  val copy : llvar -> llvar
  val free : llvar -> unit
  val gen_functions : unit -> unit
end
