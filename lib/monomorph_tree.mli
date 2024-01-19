(* Basically the same as the typed tree, except the function calls at
   application carry info on which monomorphized instance to use.
   Also, the extraction of functions for code generation has already taken place *)

open Cleaned_types
include Monomorph_tree_intf.S

val typ_of_abs : abstraction -> typ
val monomorphize : mname:Path.t -> Typed_tree.t -> monomorphized_tree
val get_mono_name : string -> poly:typ -> closure:bool -> typ -> string
val short_name : closure:bool -> typ -> string
