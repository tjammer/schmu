module type S = sig
  open Cleaned_types

  val get_lltype_def : typ -> Llvm.lltype
  val typeof_funclike : typ -> Llvm.lltype

  val typeof_func :
    decl:bool ->
    param list * typ * fun_kind ->
    Llvm.lltype * (int * typ) list * int list

  val lltypeof_closure : closed list -> bool -> Llvm.lltype
  val typeof_closure : closed list -> typ
  val is_only_units : closed list -> bool
  val get_lltype_param : bool -> typ -> Llvm.lltype
  val get_struct : typ -> Llvm.lltype
  val struct_name : typ -> string
end
