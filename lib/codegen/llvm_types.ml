open Cleaned_types
module Vars = Map.Make (String)
module Debug = Llvm_debuginfo

type value_kind = Const | Const_ptr | Imm | Ptr [@@deriving show]
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
  scope : Llvm.llmetadata;
}

let no_param =
  {
    vars = Vars.empty;
    alloca = None;
    finalize = None;
    rec_block = None;
    scope = Debug.llmetadata_null ();
  }

let context = Llvm.global_context ()

let the_module =
  let m = Llvm.create_module context "context" in
  (* Llvm.add_module_flag m Llvm.ModuleFlagBehavior.Warning "schmu-module" *)
  (*   (Debug.llmetadata_null ()); *)
  m

let dibuilder = Debug.dibuilder the_module
let di_comp_unit = ref None
let di_file = ref None
let di_filetbl = Hashtbl.create 64

let set_di_comp_unit ~filename ~directory ~is_optimized =
  let file_ref = Debug.dibuild_create_file ~filename ~directory dibuilder in
  di_file := Some file_ref;
  let unit =
    Debug.dibuild_create_compile_unit dibuilder Debug.DWARFSourceLanguageKind.C
      ~file_ref ~producer:"schmu 0.1x" ~is_optimized ~flags:"" ~runtime_ver:0
      ~split_name:"" Debug.DWARFEmissionKind.Full ~dwoid:0 ~di_inlining:true
      ~di_profiling:false ~sys_root:"" ~sdk:""
  in
  di_comp_unit := Some unit

let di_comp_unit () = Option.get !di_comp_unit

let di_file loc =
  (* We don't have accurate [directory] information for polymorphic functions
     from other modules. Ignore it for now *)
  let filename = Lexing.((fst loc).pos_fname) in
  match Hashtbl.find_opt di_filetbl filename with
  | Some file_ref -> file_ref
  | None ->
      let file_ref =
        Debug.dibuild_create_file ~filename ~directory:"" dibuilder
      in
      Hashtbl.add di_filetbl filename file_ref;
      file_ref

let di_loc param loc =
  let line = Lexing.((fst loc).pos_lnum) in
  let column = Lexing.((fst loc).pos_cnum - (fst loc).pos_bol) in
  Debug.dibuild_create_debug_location ~scope:param.scope ~line ~column context

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
let u16_t = Llvm.i16_type context
let i16_t = Llvm.i16_type context
let i32_t = Llvm.i32_type context
let float_t = Llvm.double_type context
let f32_t = Llvm.float_type context
let unit_t = Llvm.void_type context
let ptr_t = Llvm.pointer_type context

let closure_t =
  let t = Llvm.named_struct_type context "closure" in
  let typ = [| ptr_t; ptr_t |] in
  Llvm.struct_set_body t typ false;
  t

let generic_t = Llvm.named_struct_type context "generic"
let global_t = Llvm.(struct_type context [| i32_t; ptr_t; ptr_t |])

(* For closures. Ctor parameter is nonnull env ptr *)
let ctor_t = Llvm.(function_type ptr_t [| ptr_t |])
let dtor_t = Llvm.(function_type unit_t [| ptr_t |])
