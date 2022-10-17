module type S = sig
  open Cleaned_types

  val get_lltype_def : typ -> Llvm.lltype

  val typeof_func :
    param:bool ->
    decl:bool ->
    param list * typ * fun_kind ->
    Llvm.lltype * (int * typ) list

  val typeof_closure : closed array -> Llvm.lltype
  val get_lltype_global : typ -> Llvm.lltype
  val get_lltype_param : bool -> typ -> Llvm.lltype
  val get_lltype_field : typ -> Llvm.lltype
  val get_struct : typ -> Llvm.lltype
end
