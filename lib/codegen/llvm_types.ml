open Cleaned_types
module Vars = Map.Make (String)

type value_kind = Const | Const_ptr | Imm | Ptr
type mangle_kind = C | Schmu of string

type llvar = {
  value : Llvm.llvalue;
  typ : typ;
  lltyp : Llvm.lltype;
  kind : value_kind;
}

type rec_block = { rec_ : Llvm.llbasicblock; entry : Llvm.llbuilder }

type param = {
  vars : llvar Vars.t;
  alloca : Llvm.llvalue option;
  finalize : (llvar -> unit) option;
  rec_block : rec_block option;
  in_set : bool;
}

let context = Llvm.global_context ()
let the_module = Llvm.create_module context "context"
let fpm = Llvm.PassManager.create_function the_module
let _ = Llvm.PassManager.initialize fpm

(* Segfaults on my fedora box!? *)
(* let () = Llvm_scalar_opts.add_instruction_combination fpm *)

(* let () = Llvm_scalar_opts.add_reassociation fpm *)

(* Is somehow needed to make tail call optimization work *)
let () = Llvm_scalar_opts.add_gvn fpm

(* let () = Llvm_scalar_opts.add_cfg_simplification fpm *)

let () = Llvm_scalar_opts.add_tail_call_elimination fpm
let builder = Llvm.builder context
let int_t = Llvm.i64_type context
let bool_t = Llvm.i1_type context
let u8_t = Llvm.i8_type context
let i16_t = Llvm.i16_type context
let i32_t = Llvm.i32_type context
let float_t = Llvm.double_type context
let f32_t = Llvm.float_type context
let unit_t = Llvm.void_type context
let voidptr_t = Llvm.(i8_type context |> pointer_type)

let closure_t =
  let t = Llvm.named_struct_type context "closure" in
  let typ = [| voidptr_t; voidptr_t |] in
  Llvm.struct_set_body t typ false;
  t

let generic_t = Llvm.named_struct_type context "generic"

let global_t =
  Llvm.(
    struct_type context
      [| i32_t; function_type unit_t [||] |> pointer_type; voidptr_t |])
