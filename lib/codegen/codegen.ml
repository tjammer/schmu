open Cleaned_types
module Vars = Map.Make (String)
module Set = Set.Make (String)

external add_byval : Llvm.llvalue -> int -> Llvm.lltype -> unit
  = "LlvmAddByvalAttr"

module Strtbl = Hashtbl
module Ptrtbl = Hashtbl

type value_kind = Const | Const_ptr | Imm | Ptr
type mangle_kind = C | Schmu

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
}

type unboxed_atom = Ints of int | F32 | F32_vec | Float

type unboxed =
  | One_param of unboxed_atom
  | Two_params of unboxed_atom * unboxed_atom

type aggregate_param_kind = Boxed | Unboxed of unboxed

let ( ++ ) = Seq.append
let struct_tbl = Strtbl.create 32
let ptr_tbl = Ptrtbl.create 32
let const_tbl = Strtbl.create 64
let string_tbl = Strtbl.create 64
let const_pass = ref true
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

let string_t =
  Trecord
    ( [],
      Some "string",
      [| { ftyp = Traw_ptr Tu8; mut = false }; { ftyp = Tint; mut = false } |]
    )

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

let dummy_fn_value =
  (* When we need something in the env for a function which will only be called
     in a monomorphized version *)
  { typ = Tunit; value = Llvm.const_int i32_t (-1); lltyp = i32_t; kind = Ptr }

let no_param =
  { vars = Vars.empty; alloca = None; finalize = None; rec_block = None }

let default_kind = function
  | Tint | Tbool | Tfloat | Tu8 | Ti32 | Tf32 | Tunit | Traw_ptr _ -> Imm
  | Trecord _ | Tvariant _ | Tfun _ | Tpoly _ -> Ptr

(* Named structs for typedefs *)

let rec struct_name = function
  (* We match on each type here to allow for nested parametrization like [int foo bar].
     [poly] argument will create a name used for a poly var, ie spell out the generic name *)
  | Trecord (param, Some name, _) | Tvariant (param, name, _) ->
      let some t = match t with Tpoly _ -> "generic" | t -> struct_name t in
      String.concat "_" (name :: List.map some param)
  | Trecord (_, None, fs) ->
      let ts = Array.to_list fs |> List.map (fun f -> struct_name f.ftyp) in
      "tuple_" ^ String.concat "_" ts
  | t -> string_of_type t

(*
   Size and alignment.
*)

type size_pr = { size : int; align : int }

let alignup ~size ~upto =
  let modulo = size mod upto in
  if Int.equal modulo 0 then (* We are aligned *)
    size else size + (upto - modulo)

let add_size_align ~upto ~sz { size; align } =
  let size = alignup ~size ~upto + sz in
  let align = max align upto in
  { size; align }

(* Returns the size in bytes *)
let rec sizeof_typ typ =
  let rec inner size_pr typ =
    match typ with
    | Tint | Tfloat -> add_size_align ~upto:8 ~sz:8 size_pr
    | Ti32 | Tf32 -> add_size_align ~upto:4 ~sz:4 size_pr
    | Tbool | Tu8 ->
        (* No need to align one byte *)
        { size_pr with size = size_pr.size + 1 }
    | Tunit -> failwith "Does this make sense?"
    | Tfun _ ->
        (* Just a ptr? Or a closure, 2 ptrs. Assume 64bit *)
        add_size_align ~upto:8 ~sz:8 size_pr
    | Trecord (_, _, labels) ->
        let { size; align = upto } =
          Array.fold_left
            (fun pr (f : field) -> inner pr f.ftyp)
            { size = 0; align = 1 } labels
        in
        let sz = alignup ~size ~upto in
        add_size_align ~upto ~sz size_pr
    | Tvariant (_, _, ctors) ->
        (* For simplicity, we use i32 for the tag. If the variant contains no data
           i.e. is a C enum, we want to use i32 anyway, since that's what C uses.
           And then we don't have to worry about the size *)
        let init = inner { size = 0; align = 1 } Ti32 in
        let final =
          match variant_get_largest ctors with
          | Some typ -> inner init typ
          | None -> init
        in
        let sz = alignup ~size:final.size ~upto:final.align in
        add_size_align ~upto:final.align ~sz size_pr
    | Tpoly _ ->
        Llvm.dump_module the_module;
        failwith "too generic for a size"
    | Traw_ptr _ ->
        (* TODO pass in triple. Until then, assume 64bit *)
        add_size_align ~upto:8 ~sz:8 size_pr
  in
  let { size; align = upto } = inner { size = 0; align = 1 } typ in
  alignup ~size ~upto

and variant_get_largest ctors =
  let largest, _ =
    Array.fold_left
      (fun (largest, size) ctor ->
        match ctor.ctyp with
        | None -> (largest, size)
        | Some typ ->
            let sz = sizeof_typ typ in
            if sz > size then (Some typ, sz) else (largest, size))
      (None, 0) ctors
  in
  largest

let llval_of_size size = Llvm.const_int int_t size

(*
   ABI handling
*)

let rec get_word ~size items = function
  | [] -> (List.rev items, [], size)
  | typ :: tl ->
      let typ_size = sizeof_typ typ in
      let size = alignup ~size ~upto:typ_size + typ_size in
      if size > 8 then
        (* Straddles the 8 byte boundary.
           Will be boxed in [pkind_of_typ] *)
        ([], [], 0)
      else if size = 8 then
        (* We are at a word boundary. Return what we have so far *)
        (List.rev (typ :: items), tl, size)
      else get_word ~size (typ :: items) tl

and extract_word ~size = function
  | [ Tf32; Tf32 ] -> Some F32_vec
  | [ Tf32 ] -> Some F32
  | [ Tfloat ] -> Some Float
  | [] -> None
  | _ ->
      let size = match size with 1 -> 1 | 2 -> 2 | 3 | 4 -> 4 | _ -> 8 in
      Some (Ints size)

and pkind_of_typ mut typ =
  (* We destruct the type into words of 8 byte.
     A word is then either a double, an int (containing different types)
     or a vector of float (for x86_64-linux-gnu). If a type straddles
     the 8 byte boundary, we have to box it.
     Depending on the size, we end up with one ([One_param]) or
     two ([Two_params]) parameters.
     Still missing: A 'short' type to unbox e.g. 2 bools.
     And obviously all of this is hardcoded for x86_64-linux-gnu *)
  let aux typ types =
    let size = sizeof_typ typ in
    if size > 16 then Boxed
    else
      let fst, tail, size = get_word ~size:0 [] types in
      let fst = extract_word ~size fst in
      let snd, _, size = get_word ~size:0 [] tail in
      let snd = extract_word ~size snd in
      match (fst, snd) with
      | Some a, Some b -> Unboxed (Two_params (a, b))
      | Some atom, None -> Unboxed (One_param atom)
      | None, _ -> Boxed
  in
  match typ with
  | Trecord (_, _, fields) when not mut ->
      let types =
        Array.map (fun (field : Cleaned_types.field) -> field.ftyp) fields
        |> Array.to_list
      in
      aux typ types
  | Tvariant (_, _, ctors) when not mut ->
      let types =
        match variant_get_largest ctors with
        | Some typ -> [ Ti32; typ ]
        | None -> [ Ti32 ]
      in
      aux typ types
  | _ -> Boxed

let lltype_unbox = function
  | Ints 1 -> u8_t
  | Ints 2 -> i16_t
  | Ints 4 -> i32_t
  | Ints 8 -> int_t
  | F32 -> f32_t
  | F32_vec -> Llvm.vector_type f32_t 2
  | Float -> float_t
  | Ints i ->
      "unsupported size for unboxed struct: " ^ string_of_int i |> failwith

let lltype_unboxed kind =
  match kind with
  | One_param a -> lltype_unbox a
  | Two_params (a, b) ->
      Llvm.struct_type context [| lltype_unbox a; lltype_unbox b |]

let type_unboxed kind =
  let helper = function
    | Ints 1 -> Tu8
    | Ints 2 -> Tu8 (* Not really, but there is no i16 type yet *)
    | Ints 4 -> Ti32
    | Ints 8 -> Tint
    | F32 -> Tf32
    | F32_vec -> Tfloat
    | Float -> Tfloat
    | Ints i ->
        "unsupported size for unboxed struct: " ^ string_of_int i |> failwith
  in
  let anon_field_of_typ typ = { mut = false; ftyp = helper typ } in

  match kind with
  | One_param a -> helper a
  | Two_params (a, b) ->
      (* We need a tuple here *)
      Trecord
        ([], Some "param_tup", [| anon_field_of_typ a; anon_field_of_typ b |])

(** For functions, when passed as parameter, we convert it to a closure ptr
   to later cast to the correct types. At the application, we need to
   get the correct type though to cast it back. *)
let rec get_lltype_def = function
  | Tint -> int_t
  | Tbool -> bool_t
  | Tu8 -> u8_t
  | Tfloat -> float_t
  | Ti32 -> i32_t
  | Tf32 -> f32_t
  | Tunit -> unit_t
  | Tpoly _ -> generic_t |> Llvm.pointer_type
  | (Trecord _ as t) | (Tvariant _ as t) -> get_struct t
  | Tfun (params, ret, kind) ->
      typeof_func ~param:false ~decl:false (params, ret, kind) |> fst
  | Traw_ptr t -> get_lltype_def t |> Llvm.pointer_type

and get_lltype_param mut = function
  | (Tint | Tbool | Tu8 | Tfloat | Ti32 | Tf32 | Tunit | Tpoly _ | Traw_ptr _)
    as t ->
      get_lltype_def t
  | Tfun (params, ret, kind) ->
      typeof_func ~param:true ~decl:false (params, ret, kind) |> fst
  | (Trecord _ as typ) | (Tvariant _ as typ) -> (
      let t = get_struct typ in
      match pkind_of_typ mut typ with
      | Boxed -> t |> Llvm.pointer_type
      | Unboxed size -> lltype_unboxed size)

and get_lltype_field = function
  | ( Tint | Tbool | Tu8 | Tfloat | Ti32 | Tf32 | Tunit | Tpoly _ | Traw_ptr _
    | Trecord _ | Tvariant _ ) as t ->
      get_lltype_def t
  | Tfun (params, ret, kind) ->
      (* Not really a paramater, but is treated equally (ptr to closure struct) *)
      typeof_func ~param:true ~decl:false (params, ret, kind) |> fst

and get_lltype_global = function
  | ( Tint | Tbool | Tu8 | Tfloat | Ti32 | Tf32 | Tunit | Tpoly _ | Traw_ptr _
    | Trecord _ | Tvariant _ ) as t ->
      get_lltype_def t
  | Tfun _ -> closure_t

(* LLVM type of closure struct and records *)
and typeof_aggregate agg =
  Array.map get_lltype_field agg |> Llvm.struct_type context

and typeof_closure agg =
  Array.map
    (fun cl ->
      match cl.cltyp with
      | (Trecord _ | Tvariant _) when cl.clmut ->
          get_lltype_field cl.cltyp |> Llvm.pointer_type
      | typ -> get_lltype_field typ)
    agg
  |> Llvm.struct_type context

and typeof_func ~param ~decl (params, ret, kind) =
  if param then closure_t |> fun t -> (Llvm.pointer_type t, [])
  else
    (* When [get_lltype] is called on a function, we handle the dynamic case where
       a function or closure is being passed to another function.
       If a record is returned, we allocate it at the caller site and
       pass it as first argument to the function *)
    let prefix, ret_t =
      if is_struct ret then
        match pkind_of_typ false ret with
        | Boxed -> (Seq.return (get_lltype_param false ret), unit_t)
        | Unboxed size -> (Seq.empty, lltype_unboxed size)
      else (Seq.empty, get_lltype_param false ret)
    in

    let suffix =
      (* A closure needs an extra parameter for the environment  *)
      if decl then
        match kind with Closure _ -> Seq.return voidptr_t | _ -> Seq.empty
      else Seq.return voidptr_t
    in

    (* Index 0 is return type *)
    let start_idx = if Seq.is_empty prefix then 0 else 1 in
    let byvals = ref [] in
    let i = ref start_idx in
    let params_t =
      (* For the params, we want to produce the param type.
         There is a special case for records which are splint into two words. *)
      List.fold_left
        (fun ps p ->
          let typ = p.pt in
          incr i;
          match pkind_of_typ p.pmut typ with
          | Unboxed (Two_params (fst, snd)) ->
              (* snd before fst b/c we rev later *)
              lltype_unbox snd :: lltype_unbox fst :: ps
          | Boxed when is_aggregate typ ->
              byvals := (!i, typ) :: !byvals;
              get_lltype_param p.pmut typ :: ps
          | _ -> get_lltype_param p.pmut typ :: ps)
        [] params
      |> List.rev |> List.to_seq
      |> fun seq -> prefix ++ seq ++ suffix |> Array.of_seq
    in
    let ft = Llvm.function_type ret_t params_t in
    (ft, !byvals)

and to_named_typedefs name = function
  | Trecord (_, _, labels) ->
      let t = Llvm.named_struct_type context name in
      let lltyp =
        Array.map (fun (f : field) -> f.ftyp) labels
        |> typeof_aggregate |> Llvm.struct_element_types
      in
      Llvm.struct_set_body t lltyp false;
      Strtbl.replace struct_tbl name t;
      t
  | Tvariant (_, _, ctors) -> (
      (* We loop throug each ctor and then we use the largest one as a
         typedef for the whole type *)
      let tag = i32_t in
      let largest = variant_get_largest ctors |> Option.map get_lltype_def in
      let t = Llvm.named_struct_type context name in
      match largest with
      | Some lltyp ->
          Llvm.struct_set_body t [| tag; lltyp |] false;
          Strtbl.replace struct_tbl name t;
          t
      | None ->
          (* C style enum, no data, just tag *)
          Llvm.struct_set_body t [| tag |] false;
          Strtbl.replace struct_tbl name t;
          t)
  | _ -> failwith "Internal Error: Only records and variants should be here"

and get_struct t =
  let name = struct_name t in
  match Strtbl.find_opt struct_tbl name with
  | Some t -> t
  | None ->
      (* Add struct to struct tbl *)
      to_named_typedefs name t

let box_record typ ~size ?(alloc = None) ~snd_val value =
  (* From int to record *)
  (* If [snd_val] is present, the value was passed as two params
     and we construct the struct from both *)
  let intptr =
    match alloc with
    | None -> Llvm.build_alloca (lltype_unboxed size) "box" builder
    | Some alloc ->
        Llvm.build_bitcast alloc
          (Llvm.pointer_type (lltype_unboxed size))
          "box" builder
  in

  (match snd_val with
  | None -> ignore (Llvm.build_store value intptr builder)
  | Some v2 ->
      let ptr = Llvm.build_struct_gep intptr 0 "fst" builder in
      ignore (Llvm.build_store value ptr builder);
      let ptr = Llvm.build_struct_gep intptr 1 "snd" builder in
      ignore (Llvm.build_store v2 ptr builder));

  Llvm.build_bitcast intptr
    (get_lltype_def typ |> Llvm.pointer_type)
    "box" builder

(* Checks the param kind before calling [box_record] *)
let maybe_box_record mut typ ?(alloc = None) ?(snd_val = None) value =
  (* From int to record *)
  match pkind_of_typ mut typ with
  | Unboxed size -> box_record typ ~size ~alloc ~snd_val value
  | Boxed -> value

let unbox_const_record kind value =
  (* TODO Implement for two params and check why it's unreachable right now *)
  let target_type = lltype_unboxed kind in
  match kind with
  | Two_params _ ->
      failwith "Internal Error: Cannot deal with const two types yet"
  | One_param (Ints _) ->
      let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
      if pieces > 1 then failwith "Int of pieces TODO"
      else
        let is_signed =
          match value.typ with
          | Trecord (_, _, fields) -> (
              match fields.(0).ftyp with Tbool -> false | _ -> true)
          | _ -> failwith "Internal Error: Not a record to unbox"
        in
        let value = Llvm.const_extractvalue value.value [| 0 |] in
        Llvm.const_intcast ~is_signed value target_type
  | One_param (F32 | Float) ->
      let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
      if pieces > 1 then failwith "Float of pieces TODO"
      else
        let value = Llvm.const_extractvalue value.value [| 0 |] in
        Llvm.const_fpcast value target_type
  | One_param F32_vec ->
      let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
      if pieces <> 2 then failwith "F32_vec of pieces TODO"
      else
        let v1 = Llvm.const_extractvalue value.value [| 0 |] in
        let v2 = Llvm.const_extractvalue value.value [| 1 |] in
        Llvm.const_vector [| v1; v2 |]

let unbox_record ~kind ~ret value =
  let structptr =
    lazy
      (Llvm.build_bitcast value.value
         (Llvm.pointer_type (lltype_unboxed kind))
         "unbox" builder)
  in

  let is_const =
    match value.kind with Const -> true | Ptr | Const_ptr | Imm -> false
  in

  (* If this is a return value, we unbox it as a struct every time *)
  match (ret, kind) with
  | (true, _ | _, One_param _) when is_const ->
      (unbox_const_record kind value, None)
  | true, _ | _, One_param _ ->
      (Llvm.build_load (Lazy.force structptr) "unbox" builder, None)
  | _, Two_params _ ->
      (* We load the two arguments from the struct type *)
      let ptr = Llvm.build_struct_gep (Lazy.force structptr) 0 "fst" builder in
      let v1 = Llvm.build_load ptr "fst" builder in
      let ptr = Llvm.build_struct_gep (Lazy.force structptr) 1 "snd" builder in
      let v2 = Llvm.build_load ptr "snd" builder in
      (v1, Some v2)

let bring_default value =
  if is_struct value.typ then value.value
  else
    match value.kind with
    | Const_ptr -> Llvm.global_initializer value.value |> Option.get
    | Ptr -> Llvm.build_load value.value "" builder
    | Const | Imm -> value.value

let bring_default_var v =
  let kind = if is_struct v.typ then v.kind else default_kind v.typ in
  { v with value = bring_default v; kind }

(* Checks the param kind before calling [unbox_record] *)
let pass_value mut value =
  (* From record to int *)
  if is_struct value.typ then
    match pkind_of_typ mut value.typ with
    | Unboxed kind -> unbox_record ~kind ~ret:false value
    | Boxed -> (value.value, None)
  else (bring_default value, None)

(* Given two ptr types (most likely to structs), copy src to dst *)
let memcpy ~dst ~src ~size =
  match src.kind with
  | Const | Imm -> ignore (Llvm.build_store src.value dst builder)
  | Ptr | Const_ptr ->
      let memcpy_decl =
        lazy
          Llvm.(
            (* llvm.memcpy.inline.p0i8.p0i8.i64 *)
            let ft =
              function_type unit_t [| voidptr_t; voidptr_t; int_t; bool_t |]
            in
            declare_function "llvm.memcpy.p0i8.p0i8.i64" ft the_module)
      in
      let dstptr = Llvm.build_bitcast dst voidptr_t "" builder in
      let retptr = Llvm.build_bitcast src.value voidptr_t "" builder in
      let args = [| dstptr; retptr; size; Llvm.const_int bool_t 0 |] in
      ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder)

let malloc ~size =
  let malloc_decl =
    lazy
      Llvm.(
        let ft = function_type voidptr_t [| int_t |] in
        declare_function "malloc" ft the_module)
  in
  Llvm.build_call (Lazy.force malloc_decl) [| size |] "" builder

let realloc ptr ~size =
  let realloc_decl =
    lazy
      Llvm.(
        let ft = function_type voidptr_t [| voidptr_t; int_t |] in
        declare_function "realloc" ft the_module)
  in
  let voidptr = Llvm.build_bitcast ptr voidptr_t "" builder in
  let ret =
    Llvm.build_call (Lazy.force realloc_decl) [| voidptr; size |] "" builder
  in
  Llvm.build_bitcast ret (Llvm.type_of ptr) "" builder

(* Frees a single pointer *)
let free ptr =
  let free_decl =
    lazy
      Llvm.(
        let ft = function_type unit_t [| voidptr_t |] in
        declare_function "free" ft the_module)
  in

  let ptr = Llvm.build_bitcast ptr voidptr_t "" builder in

  Llvm.build_call (Lazy.force free_decl) [| ptr |] "" builder

(* Recursively frees a record (which can contain vector and other records) *)
let rec free_value value = function
  | Trecord ([ t ], Some name, _) when String.equal name "owned_ptr" ->
      (* Free nested owned_ptrs *)
      let ptr = Llvm.build_struct_gep value 0 "" builder in
      let ptr = Llvm.build_load ptr "" builder in

      (if contains_owned_ptr t then
       let len_ptr = Llvm.build_struct_gep value 1 "lenptr" builder in
       (* This should be num_t also, at some point *)
       let len = Llvm.build_load len_ptr "leni" builder in
       let len = Llvm.build_intcast len int_t "len" builder in
       free_owned_ptr_children ptr len t);
      ignore (free ptr)
  | Trecord (_, Some name, _) when String.equal name "string" ->
      let start_bb = Llvm.insertion_block builder in
      let parent = Llvm.block_parent start_bb in

      let owned_bb = Llvm.append_block context "free" parent in
      let cont_bb = Llvm.append_block context "cont" parent in

      let lengthptr = Llvm.build_struct_gep value 1 "" builder in
      let length = Llvm.build_load lengthptr "" builder in
      let cond =
        Llvm.(build_icmp Icmp.Slt length (const_null int_t) "owned") builder
      in
      ignore (Llvm.build_cond_br cond owned_bb cont_bb builder);

      Llvm.position_at_end owned_bb builder;
      let ptr = Llvm.build_struct_gep value 0 "" builder in
      let ptr = Llvm.build_load ptr "" builder in
      ignore (free ptr);
      ignore (Llvm.build_br cont_bb builder);

      Llvm.position_at_end cont_bb builder
  | Trecord (_, Some name, _) when String.equal name "owned_ptr" ->
      failwith "Internal Error: On free: owned_ptr has no type"
  | Trecord (_, _, fields) ->
      Array.iteri
        (fun i (f : field) ->
          if contains_owned_ptr f.ftyp then
            let ptr = Llvm.build_struct_gep value i "" builder in
            free_value ptr f.ftyp)
        fields
  | t ->
      print_endline (show_typ t);
      failwith "freeing records other than owned_ptr TODO"

and contains_owned_ptr = function
  | Trecord (_, Some name, _) when String.equal name "owned_ptr" -> true
  | Trecord (_, Some name, _) when String.equal name "string" -> true
  | Trecord (_, _, fields) ->
      Array.fold_left
        (fun b (f : field) -> f.ftyp |> contains_owned_ptr || b)
        false fields
  | _ -> false

and free_owned_ptr_children value len = function
  | Trecord _ as typ ->
      let start_bb = Llvm.insertion_block builder in
      let parent = Llvm.block_parent start_bb in

      (* Simple loop, start at 0 *)
      let cnt = Llvm.build_alloca int_t "cnt" builder in
      ignore (Llvm.build_store (Llvm.const_int int_t 0) cnt builder);

      let rec_bb = Llvm.append_block context "rec" parent in
      let free_bb = Llvm.append_block context "free" parent in
      let cont_bb = Llvm.append_block context "cont" parent in

      ignore (Llvm.build_br rec_bb builder);
      Llvm.position_at_end rec_bb builder;

      (* Check if we are done *)
      let cnt_loaded = Llvm.build_load cnt "" builder in
      let cmp = Llvm.(build_icmp Icmp.Slt) cnt_loaded len "" builder in
      ignore (Llvm.build_cond_br cmp free_bb cont_bb builder);

      Llvm.position_at_end free_bb builder;
      (* The ptr has the correct type, no need to multiply size *)
      let ptr = Llvm.build_gep value [| cnt_loaded |] "" builder in

      free_value ptr typ;
      let one = Llvm.const_int int_t 1 in
      let next = Llvm.build_add cnt_loaded one "" builder in
      ignore (Llvm.build_store next cnt builder);
      ignore (Llvm.build_br rec_bb builder);

      Llvm.position_at_end cont_bb builder
  | t ->
      print_endline (show_typ t);
      failwith "Internal Error: Freeing this type is not supported"

let free_id id =
  (match Ptrtbl.find_opt ptr_tbl id with
  | Some (value, typ) ->
      (* For propagated mallocs, we don't get the ptr directly but get the struct instead.
         Here, we hardcode for owned_ptr, b/c it's the only thing allocating right now. *)

      (* Free nested owned_ptrs *)
      free_value value typ
  | None ->
      "Internal Error: Cannot find ptr for id " ^ string_of_int id |> failwith);
  Ptrtbl.remove ptr_tbl id

let get_const_string s =
  match Strtbl.find_opt string_tbl s with
  | Some ptr -> ptr
  | None ->
      let ptr = Llvm.build_global_stringptr s "" builder in
      Strtbl.add string_tbl s ptr;
      ptr

let fmt_str value =
  let v = bring_default value in
  match value.typ with
  | Tint -> ("%li", v)
  | Tfloat -> ("%.9g", v)
  | Trecord (_, Some name, _) when String.equal name "string" ->
      let ptr = Llvm.build_struct_gep value.value 0 "" builder in
      ("%s", Llvm.build_load ptr "" builder)
  | Tbool ->
      let start_bb = Llvm.insertion_block builder in
      let parent = Llvm.block_parent start_bb in

      let false_bb = Llvm.append_block context "free" parent in
      let cont_bb = Llvm.append_block context "cont" parent in

      ignore (Llvm.build_cond_br v cont_bb false_bb builder);

      Llvm.position_at_end false_bb builder;
      ignore (Llvm.build_br cont_bb builder);
      Llvm.position_at_end cont_bb builder;
      let value =
        Llvm.build_phi
          [
            (get_const_string "true", start_bb);
            (get_const_string "false", false_bb);
          ]
          "" builder
      in
      ("%s", value)
  | Tu8 -> ("%hhi", v)
  | Ti32 -> ("%i", v)
  | Tf32 -> (".9gf", v)
  | _ ->
      print_endline (show_typ value.typ);
      failwith "Internal Error: Impossible string format"

let set_struct_field value ptr =
  match value.typ with
  | Trecord _ | Tvariant _ ->
      if value.value <> ptr then
        let size = sizeof_typ value.typ |> llval_of_size in
        memcpy ~dst:ptr ~src:value ~size
  | _ -> ignore (Llvm.build_store value.value ptr builder)

let mangle name = function C -> name | Schmu -> "schmu_" ^ name

let unmangle kind name =
  match kind with
  | C -> name
  | Schmu ->
      let open String in
      let len = length "schmu_" in
      sub name len (length name - len)

let declare_function ~c_linkage mangle_kind fun_name = function
  | Tfun (params, ret, kind) as typ ->
      let ft, byvals =
        typeof_func ~param:false ~decl:true (params, ret, kind)
      in
      let name = mangle fun_name mangle_kind in
      let value = Llvm.declare_function name ft the_module in
      if c_linkage then
        List.iter
          (fun (i, typ) -> add_byval value i (get_lltype_def typ))
          byvals;
      let llvar = { value; typ; lltyp = ft; kind = Imm } in
      llvar
  | _ ->
      prerr_endline fun_name;
      failwith "Internal Error: declaring non-function"

let alloca param typ str =
  (* If a builder is present, the alloca will be moved out of a loop,
     so we don't blow up the stack *)
  let builder = match param.rec_block with Some r -> r.entry | _ -> builder in
  Llvm.build_alloca typ str builder

let box_const param var =
  let value = alloca param (get_lltype_def var.typ) "boxconst" in
  ignore (Llvm.build_store var.value value builder);
  { var with value }

(* [func_to_closure] but for function types *)
let tfun_to_closure = function
  | Tfun (ps, ret, Simple) -> Tfun (ps, ret, Closure [])
  | t -> t

let gen_closure_obj param assoc func name =
  let clsr_struct = alloca param closure_t name in

  (* Add function ptr *)
  let fun_ptr = Llvm.build_struct_gep clsr_struct 0 "funptr" builder in
  let fun_casted = Llvm.build_bitcast func.value voidptr_t "func" builder in
  ignore (Llvm.build_store fun_casted fun_ptr builder);

  let store_closed_var clsr_ptr i cl =
    let src = Vars.find cl.clname param.vars in
    let dst = Llvm.build_struct_gep clsr_ptr i cl.clname builder in
    (match cl.cltyp with
    | (Trecord _ | Tvariant _) when cl.clmut ->
        ignore (Llvm.build_store src.value dst builder)
    | Trecord _ | Tvariant _ ->
        (* For records, we just memcpy
           TODO don't use types here, but type kinds*)
        let size = sizeof_typ cl.cltyp |> Llvm.const_int int_t in
        memcpy ~src ~dst ~size
    | _ -> ignore (Llvm.build_store src.value dst builder));
    i + 1
  in

  (* Add closed over vars. If the environment is empty, we pass nullptr *)
  let clsr_ptr =
    match assoc with
    | [] -> Llvm.const_pointer_null voidptr_t
    | assoc ->
        let assoc_type = typeof_closure (Array.of_list assoc) in
        let clsr_ptr = alloca param assoc_type ("clsr_" ^ name) in
        ignore (List.fold_left (store_closed_var clsr_ptr) 0 assoc);

        let clsr_casted = Llvm.build_bitcast clsr_ptr voidptr_t "env" builder in
        clsr_casted
  in

  (* Add closure env to struct *)
  let env_ptr = Llvm.build_struct_gep clsr_struct 1 "envptr" builder in
  ignore (Llvm.build_store clsr_ptr env_ptr builder);

  (* Turn simple functions into empty closures, so they are handled correctly
     when passed *)
  let typ = tfun_to_closure func.typ in

  { value = clsr_struct; typ; lltyp = func.lltyp; kind = Imm }

let add_closure vars func = function
  | Simple -> vars
  | Closure assoc ->
      let closure_index = (Llvm.params func.value |> Array.length) - 1 in
      let clsr_param = (Llvm.params func.value).(closure_index) in
      let clsr_type =
        typeof_closure (Array.of_list assoc) |> Llvm.pointer_type
      in
      let clsr_ptr = Llvm.build_bitcast clsr_param clsr_type "clsr" builder in

      let add_closure (env, i) cl =
        let item_ptr = Llvm.build_struct_gep clsr_ptr i cl.clname builder in
        let typ = cl.cltyp in
        let value, lltyp =
          match typ with
          (* No need for C interop with closures *)
          | (Trecord _ | Tvariant _) when cl.clmut ->
              (* Mutable records are passed as pointers into the env *)
              let value = Llvm.build_load item_ptr cl.clname builder in

              (value, get_lltype_def typ |> Llvm.pointer_type)
          | Trecord _ | Tvariant _ ->
              (* For records we want a ptr so that gep and memcpy work *)
              (item_ptr, get_lltype_def typ |> Llvm.pointer_type)
          | _ ->
              let value = Llvm.build_load item_ptr cl.clname builder in
              (value, Llvm.type_of value)
        in
        let item = { value; typ; lltyp; kind = default_kind typ } in
        (Vars.add cl.clname item env, i + 1)
      in
      let env, _ = List.fold_left add_closure (vars, 0) assoc in
      env

let store_or_copy ~src ~dst =
  if is_struct src.typ then
    if src.value = dst then ()
    else memcpy ~dst ~src ~size:(sizeof_typ src.typ |> llval_of_size)
  else (* Simple type *)
    ignore (Llvm.build_store src.value dst builder)

let tailrec_store ~src ~dst =
  (* Used to have special handling for mutable vars,
     now we use the same strategy (modify a ptr) for every struct type *)
  ignore (Llvm.build_store src.value dst builder)

let name_of_alloc_param i = "__" ^ string_of_int i ^ "_alloc"

let get_prealloc allocref param lltyp str =
  match (allocref, param.alloca) with
  | Monomorph_tree.Preallocated, Some value -> value
  | _ -> alloca param lltyp str

(* We need to handle the index the same way as [get_value] below *)
let get_index i mut typ =
  match pkind_of_typ mut typ with Unboxed (Two_params _) -> i + 1 | _ -> i

(* This adds the function parameters to the env.
   In case the function is tailrecursive, it allocas each parameter in
   the entry block and creates a recursion block which starts off by loading
   each parameter. *)
let add_params vars f fname names params start_index recursive =
  (* We specially treat the case where a record is passed as two params *)
  let get_value i mut typ =
    match pkind_of_typ mut typ with
    | Unboxed (Two_params _) ->
        let v1 = (Llvm.params f.value).(i) in
        let v2 = (Llvm.params f.value).(i + 1) in
        (maybe_box_record ~snd_val:(Some v2) mut typ v1, i + 1)
    | _ -> ((Llvm.params f.value).(i) |> maybe_box_record mut typ, i)
  in

  let add_simple vars =
    (* We simply add to env, no special handling for tailrecursion *)
    List.fold_left2
      (fun (env, i) name p ->
        let typ = p.pt in
        let value, i = get_value i p.pmut typ in
        let kind = default_kind typ in
        let param = { value; typ; lltyp = Llvm.type_of value; kind } in
        Llvm.set_value_name name value;
        (Vars.add name param env, i + 1))
      (vars, start_index) names params
    |> fst
  in

  let alloca_copy src =
    match src.typ with
    | Tfun _ ->
        let typ = Llvm.pointer_type closure_t in
        let dst = Llvm.build_alloca typ "" builder in
        tailrec_store ~src ~dst;
        dst
    | (Trecord _ | Tvariant _) as r ->
        let typ = Llvm.pointer_type (get_lltype_def r) in
        let dst = Llvm.build_alloca typ "" builder in
        tailrec_store ~src ~dst;
        dst
    | Traw_ptr _ -> failwith "TODO"
    | t ->
        (* Simple type *)
        let typ = get_lltype_def t in
        let dst = Llvm.build_alloca typ "" builder in
        tailrec_store ~src ~dst;
        dst
  in

  (* If the function is named, we allow recursion *)
  match recursive with
  | Monomorph_tree.Rnone -> (add_simple vars, None)
  | Rnormal ->
      ( Vars.add Monomorph_tree.(fname.call) f vars
        |> (* We also add the user name. This is needed for polymorphic nested functions.
              At the monomorphization stage, the codegen isn't rewritten to it's call name.
           *)
        Vars.add Monomorph_tree.(fname.user) f
        |> add_simple,
        None )
  | Rtail ->
      (* In the entry block, we create a alloca for each parameter.
         These can be set later in tail recursion scenarios.
         Then in a new block, we load from those alloca and set the
         real parameters *)
      let vars =
        List.fold_left2
          (fun (env, i) name p ->
            let typ = p.pt in
            let value, i = get_value i p.pmut typ in
            Llvm.set_value_name name value;
            let value =
              { value; typ; lltyp = Llvm.type_of value; kind = Ptr }
            in
            let alloc = { value with value = alloca_copy value } in
            (Vars.add (name_of_alloc_param i) alloc env, i + 1))
          (vars, start_index) names params
        |> fst
      in
      (* Recursion block*)
      let rec_ = Llvm.append_block context "rec" f.value in
      let entry = Llvm.build_br rec_ builder in
      let entry = Llvm.builder_before context entry in
      Llvm.position_at_end rec_ builder;

      (* Add the function itself to env with username *)
      let vars = Vars.add Monomorph_tree.(fname.user) f vars in

      let vars, _ =
        List.fold_left2
          (fun (env, i) name p ->
            let typ = p.pt in
            let i = get_index i p.pmut typ in
            let llvar = Vars.find (name_of_alloc_param i) env in
            let value =
              if is_struct typ then Llvm.build_load llvar.value name builder
              else llvar.value
            in
            (Vars.add name { llvar with value } env, i + 1))
          (vars, start_index) names params
      in

      (vars, Some { rec_; entry })

let pass_function param llvar kind =
  match kind with
  | Simple ->
      (* If a function is passed into [func] we convert it to a closure
         and pass nullptr to env*)
      gen_closure_obj param [] llvar "clstmp"
  | Closure _ ->
      (* This closure is a struct and has an env *)
      llvar

let func_to_closure vars llvar =
  (* TODO somewhere we don't convert into closure correctly. *)
  if Llvm.type_of llvar.value = (closure_t |> Llvm.pointer_type) then llvar
  else if
    (* Ugly :( *)
    Llvm.type_of llvar.value = Llvm.(closure_t |> pointer_type |> pointer_type)
  then
    let value = Llvm.build_load llvar.value "loadfn" builder in
    { llvar with value; kind = Imm }
  else
    match llvar.typ with
    | Tfun (_, _, kind) -> pass_function vars llvar kind
    | _ -> llvar

(* Get monomorphized function *)
let get_mono_func func param = function
  | Monomorph_tree.Mono name -> (
      let func = Vars.find name param.vars in
      (* Monomorphized functions are not yet converted to closures *)
      match func.typ with
      | Tfun (_, _, Closure assoc) ->
          gen_closure_obj param assoc func "monoclstmp"
      | Tfun (_, _, Simple) -> func
      | _ -> failwith "Internal Error: What are we applying?")
  | Concrete name -> Vars.find name param.vars
  | Default | Recursive _ -> func
  | Builtin _ -> failwith "Internal Error: Normally calling a builtin"
  | Inline _ -> failwith "Internal Error: Normally calling an inline func"

let fun_return name ret =
  match ret.typ with
  | (Trecord _ | Tvariant _) as t -> (
      match pkind_of_typ false t with
      | Boxed -> (* Default record case *) Llvm.build_ret_void builder
      | Unboxed kind ->
          let unboxed, _ = unbox_record ~kind ~ret:true ret in
          Llvm.build_ret unboxed builder)
  | Tpoly id when String.equal id "tail" ->
      (* This magic id is used to mark a tailrecursive call *)
      Llvm.build_ret_void builder
  | Tpoly _ -> failwith "Internal Error: Generic return"
  | Tunit ->
      if String.equal name "main" then
        Llvm.(build_ret (const_int int_t 0)) builder
      else Llvm.build_ret_void builder
  | _ ->
      let value =
        match ret.kind with
        | Const_ptr | Ptr -> Llvm.build_load ret.value "" builder
        | _ -> ret.value
      in
      Llvm.build_ret value builder

let rec gen_function vars ?(mangle = Schmu)
    { Monomorph_tree.abs; name; recursive } =
  let typ = Monomorph_tree.typ_of_abs abs in

  match typ with
  | Tfun (tparams, ret_t, kind) as typ ->
      let func = declare_function ~c_linkage:false mangle name.call typ in

      let start_index, alloca =
        match ret_t with
        | (Trecord _ | Tvariant _) as t -> (
            match pkind_of_typ false t with
            | Boxed ->
                (* Whenever the return type is boxed, we add the prealloc to the environment *)
                (* The call site has to decide if the prealloc is used or not *)
                (1, Some (Llvm.params func.value).(0))
            | Unboxed _ -> (* Record is returned as int *) (0, None))
        | Tpoly _ -> failwith "poly var should not be returned"
        | _ -> (0, None)
      in

      (* gen function body *)
      let bb = Llvm.append_block context "entry" func.value in
      Llvm.position_at_end bb builder;

      (* Add params from closure *)
      (* We generate both the code for extracting the closure and add the vars to the environment *)
      let tvars = add_closure vars.vars func kind in

      (* Add parameters to env *)
      let tvars, rec_block =
        add_params tvars func name abs.pnames tparams start_index recursive
      in

      let fun_finalize ret =
        (* If we want to return a struct, we copy the struct to
            its ptr (1st parameter) and return void *)
        match ret.typ with
        | (Trecord _ | Tvariant _) as t -> (
            match pkind_of_typ false t with
            | Boxed ->
                (* Since we only have POD records, we can safely memcpy here *)
                let dst = Llvm.(params func.value).(0) in
                if ret.value <> dst then
                  let size = sizeof_typ ret_t |> llval_of_size in
                  memcpy ~dst ~src:ret ~size
                else ()
            | Unboxed _ -> (* Is returned as int not preallocated *) ())
        | _ -> ()
      in

      let finalize = Some fun_finalize in
      let ret =
        gen_expr { vars = tvars; alloca; finalize; rec_block } abs.body
      in

      ignore (fun_return name.call ret);

      (* if Llvm_analysis.verify_function func.value |> not then ( *)
      (*   Llvm.dump_module the_module; *)
      (*   (\* To generate the report *\) *)
      (*   Llvm_analysis.assert_valid_function func.value); *)
      let _ = Llvm.PassManager.run_function func.value fpm in
      { vars with vars = Vars.add name.call func vars.vars }
  | _ ->
      prerr_endline name.call;
      failwith "Interal Error: generating non-function"

and gen_expr param typed_expr =
  let fin e =
    match (typed_expr.return, param.finalize) with
    | true, Some f ->
        f e;
        e
    | true, None | false, _ -> e
  in

  match typed_expr.expr with
  | Mconst (String (s, allocref)) ->
      codegen_string_lit param s typed_expr.typ allocref
  | Mconst (Vector (id, es, allocref)) ->
      codegen_vector_lit param id es typed_expr.typ allocref
  | Mconst c -> gen_const c |> fin
  | Mbop (bop, e1, e2) -> gen_bop param e1 e2 bop |> fin
  | Munop (_, e) -> gen_unop param e |> fin
  | Mvar (id, kind) -> gen_var param.vars typed_expr.typ id kind |> fin
  | Mfunction (name, abs, cont) ->
      (* The functions are already generated *)
      let func =
        match Vars.find_opt name param.vars with
        | Some func -> (
            match abs.func.kind with
            | Simple -> func
            | Closure assoc -> gen_closure_obj param assoc func name)
        | None ->
            (* The function is polymorphic and monomorphized versions are generated. *)
            (* We just return some bogus value, it will never be applied anyway
               (and if it will, LLVM will fail) *)
            dummy_fn_value
      in

      gen_expr { param with vars = Vars.add name func param.vars } cont
  | Mlet (mut, id, equals, gn, let') -> gen_let param id equals gn let' mut
  | Mlambda (name, abs) ->
      let func =
        match Vars.find_opt name param.vars with
        | Some func -> (
            match abs.func.kind with
            | Simple -> func
            | Closure assoc -> gen_closure_obj param assoc func name)
        | None ->
            (* The function is polymorphic and monomorphized versions are generated. *)
            (* We just return some bogus value, it will never be applied anyway
               (and if it will, LLVM will fail) *)
            dummy_fn_value
      in
      func
  | Mapp { callee; args; alloca; malloc; id = _ } -> (
      match (typed_expr.return, callee.monomorph, param.rec_block) with
      | true, Recursive _, Some block ->
          gen_app_tailrec param callee args block typed_expr.typ
      | _, Builtin (b, bfn), _ -> gen_app_builtin param (b, bfn) args |> fin
      | _, Inline (pnames, tree), _ ->
          gen_app_inline param args pnames tree |> fin
      | _ -> gen_app param callee args alloca typed_expr.typ malloc |> fin)
  | Mif expr -> gen_if param expr typed_expr.return
  | Mrecord (labels, allocref, const) ->
      codegen_record param typed_expr.typ labels allocref const
        typed_expr.return
      |> fin
  | Mfield (expr, index) -> codegen_field param expr index |> fin
  | Mset (expr, value) -> codegen_set param expr value |> fin
  | Mseq (expr, cont) -> codegen_chain param expr cont
  | Mfree_after (expr, id) -> gen_free param expr id
  | Mctor (ctor, allocref, const) ->
      gen_ctor param ctor typed_expr.typ allocref const
  | Mvar_index expr -> gen_var_index param expr |> fin
  | Mvar_data expr -> gen_var_data param expr typed_expr.typ |> fin
  | Mfmt (fmts, allocref, id) ->
      gen_fmt_str param fmts typed_expr.typ allocref id

and gen_let param id equals gn let' mut =
  let expr_val =
    match gn with
    | Some n -> (
        let dst = Strtbl.find const_tbl n in
        let v = gen_expr { param with alloca = Some dst.value } equals in
        let v = { v with value = bring_default v } in
        (* Bandaid for polymorphic first class functions. In monomorph pass, the
           global is ignored. TODO. Here, we make sure that the dummy_fn_value is
           not set to the global. The global will stay 0 forever *)
        match equals.typ with
        | Tfun _ when is_type_polymorphic equals.typ -> v
        | _ ->
            store_or_copy ~src:v ~dst:dst.value;
            let v = { v with value = dst.value; kind = Ptr } in
            Strtbl.replace const_tbl n v;
            v)
    | None ->
        let v = gen_expr param equals in
        if mut && not (is_struct v.typ) then (
          let value = Llvm.build_alloca v.lltyp id builder in
          ignore (Llvm.build_store v.value value builder);
          { v with value; kind = Ptr })
        else v
  in
  gen_expr { param with vars = Vars.add id expr_val param.vars } let'

and gen_const = function
  | Int i ->
      let value = Llvm.const_int int_t i in
      { value; typ = Tint; lltyp = int_t; kind = Const }
  | Bool b ->
      let value = Llvm.const_int bool_t (Bool.to_int b) in
      { value; typ = Tbool; lltyp = bool_t; kind = Const }
  | U8 c ->
      let value = Llvm.const_int u8_t (Char.code c) in
      { value; typ = Tu8; lltyp = u8_t; kind = Const }
  | Float f ->
      let value = Llvm.const_float float_t f in
      { value; typ = Tfloat; lltyp = float_t; kind = Const }
  | I32 i ->
      let value = Llvm.const_int i32_t i in
      { value; typ = Ti32; lltyp = i32_t; kind = Const }
  | F32 f ->
      let value = Llvm.const_float f32_t f in
      { value; typ = Tf32; lltyp = f32_t; kind = Const }
  | Unit -> dummy_fn_value
  | String _ | Vector _ -> failwith "In other branch"

and gen_var vars typ id kind =
  match kind with
  | Vnorm -> (
      match Vars.find_opt id vars with
      | Some v -> v
      | None -> (
          match typ with
          | Tfun _ ->
              (* If a function is polymorphic then its original value might not be bound
                 when we generate other function. In this case, we can just return a
                 dummy value *)
              dummy_fn_value
          | _ ->
              (* If the variable isn't bound, something went wrong before *)
              failwith ("Internal Error: Could not find " ^ id ^ " in codegen"))
      )
  | Vconst | Vglobal -> Strtbl.find const_tbl id

and gen_bop param e1 e2 bop =
  let gen = gen_expr param in
  let bldr = builder in
  let bld f str =
    let e1 = gen e1 |> bring_default in
    let e2 = gen e2 |> bring_default in
    f e1 e2 str builder
  in
  let open Llvm in
  match bop with
  | Plus_i ->
      { value = bld build_add "add"; typ = Tint; lltyp = int_t; kind = Imm }
  | Minus_i ->
      { value = bld build_sub "sub"; typ = Tint; lltyp = int_t; kind = Imm }
  | Mult_i ->
      { value = bld build_mul "mul"; typ = Tint; lltyp = int_t; kind = Imm }
  | Div_i ->
      { value = bld build_sdiv "div"; typ = Tint; lltyp = int_t; kind = Imm }
  | Less_i ->
      let value = bld (build_icmp Icmp.Slt) "lt" in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }
  | Greater_i ->
      let value = bld (build_icmp Icmp.Sgt) "gt" in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }
  | Equal_i ->
      let value = bld (build_icmp Icmp.Eq) "eq" in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }
  | Plus_f ->
      let value = bld build_fadd "add" in
      { value; typ = Tfloat; lltyp = float_t; kind = Imm }
  | Minus_f ->
      let value = bld build_fsub "sub" in
      { value; typ = Tfloat; lltyp = float_t; kind = Imm }
  | Mult_f ->
      let value = bld build_fmul "mul" in
      { value; typ = Tfloat; lltyp = float_t; kind = Imm }
  | Div_f ->
      let value = bld build_fdiv "div" in
      { value; typ = Tfloat; lltyp = float_t; kind = Imm }
  | Less_f ->
      let value = bld (build_fcmp Fcmp.Olt) "lt" in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }
  | Greater_f ->
      let value = bld (build_fcmp Fcmp.Ogt) "gt" in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }
  | Equal_f ->
      let value = bld (build_fcmp Fcmp.Oeq) "eq" in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }
  | And ->
      let cond1 = gen e1 |> bring_default in

      (* Current block *)
      let start_bb = insertion_block bldr in
      let parent = block_parent start_bb in

      let true1_bb = append_block context "true1" parent in
      let true2_bb = append_block context "true2" parent in
      let continue_bb = append_block context "cont" parent in

      ignore (build_cond_br cond1 true1_bb continue_bb bldr);

      position_at_end true1_bb bldr;
      let cond2 = gen e2 |> bring_default in
      (* Codegen can change the current bb *)
      let t1_bb = insertion_block bldr in
      ignore (build_cond_br cond2 true2_bb continue_bb bldr);

      position_at_end true2_bb bldr;
      ignore (build_br continue_bb bldr);

      position_at_end continue_bb bldr;

      let true_value = Llvm.const_int bool_t (Bool.to_int true) in
      let false_value = const_int bool_t (Bool.to_int false) in

      let incoming =
        [
          (false_value, start_bb); (false_value, t1_bb); (true_value, true2_bb);
        ]
      in
      let value = build_phi incoming "andtmp" bldr in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }
  | Or ->
      let cond1 = gen e1 |> bring_default in

      (* Current block *)
      let start_bb = insertion_block bldr in
      let parent = block_parent start_bb in

      let false1_bb = append_block context "false1" parent in
      let false2_bb = append_block context "false2" parent in
      let continue_bb = append_block context "cont" parent in

      ignore (build_cond_br cond1 continue_bb false1_bb bldr);

      position_at_end false1_bb bldr;
      let cond2 = gen e2 |> bring_default in
      (* Codegen can change the current bb *)
      let f1_bb = insertion_block bldr in
      ignore (build_cond_br cond2 continue_bb false2_bb bldr);

      position_at_end false2_bb bldr;
      ignore (build_br continue_bb bldr);

      position_at_end continue_bb bldr;

      let true_value = Llvm.const_int bool_t (Bool.to_int true) in
      let false_value = const_int bool_t (Bool.to_int false) in

      let incoming =
        [
          (true_value, start_bb); (true_value, f1_bb); (false_value, false2_bb);
        ]
      in
      let value = build_phi incoming "andtmp" bldr in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }

and gen_unop param e =
  let expr = gen_expr param e in
  let value =
    match expr.typ with
    | Tint -> Llvm.build_neg (bring_default expr) "neg" builder
    | Tfloat -> Llvm.build_fneg (bring_default expr) "neg" builder
    | _ -> failwith "Internal Error: Unsupported unary op"
  in
  { expr with value; kind = Imm }

and gen_app param callee args allocref ret_t malloc =
  let func = gen_expr param callee.ex in

  let func = get_mono_func func param callee.monomorph in

  let ret, kind =
    match func.typ with
    | Tfun (_, ret, kind) -> (ret, kind)
    | Tunit ->
        failwith
          "Internal Error: Probably cannot find monomorphized function in \
           gen_app"
    | _ -> failwith "Internal Error: Not a func in gen app"
  in

  let args =
    List.fold_left
      (fun args oarg ->
        let arg' = gen_expr param Monomorph_tree.(oarg.ex) in

        (* In case the record passed is constant, we allocate it here to pass
           a pointer. This isn't pretty, but will do for now. For the single
           param, unboxed case we can skip boxing *)
        let arg =
          match (arg'.typ, pkind_of_typ oarg.mut arg'.typ, arg'.kind) with
          (* The [Two_params] case is tricky to do using only consts,
             so we box and use the standard runtime version *)
          | (Trecord _ | Tvariant _), Boxed, Const
          | (Trecord _ | Tvariant _), Unboxed (Two_params _), Const ->
              box_const param arg'
          | _ -> get_mono_func arg' param oarg.monomorph
        in

        match pass_value oarg.mut arg with
        | fst, Some snd ->
            (* We can skip [func_to_closure] in this case *)
            (* snd before fst, b/c we rev at the end *)
            snd :: fst :: args
        | value, None ->
            let arg = { arg with value } in
            (func_to_closure param arg).value :: args)
      [] args
    |> List.rev |> List.to_seq
  in

  (* No names here, might be void/unit *)
  let func =
    (* TODO closure fields might not be loaded. We need to handle this in monomorph,
       possibly with a new function type *)
    if
      Llvm.type_of func.value = Llvm.(closure_t |> pointer_type |> pointer_type)
    then
      let value = Llvm.build_load func.value "loadfn" builder in
      { func with value; kind = Imm }
    else func
  in

  let funcval, envarg =
    if Llvm.type_of func.value = (closure_t |> Llvm.pointer_type) then
      (* Function to call is a closure (or a function passed into another one).
         We get the funptr from the first field, cast to the correct type,
         then get env ptr (as voidptr) from the second field and pass it as last argument *)
      let funcp = Llvm.build_struct_gep func.value 0 "funcptr" builder in
      let funcp = Llvm.build_load funcp "loadtmp" builder in
      let typ = get_lltype_def func.typ |> Llvm.pointer_type in
      let funcp = Llvm.build_bitcast funcp typ "casttmp" builder in

      let env_ptr = Llvm.build_struct_gep func.value 1 "envptr" builder in
      let env_ptr = Llvm.build_load env_ptr "loadtmp" builder in
      (funcp, Seq.return env_ptr)
    else
      match kind with
      | Simple -> (func.value, Seq.empty)
      | Closure _ -> (
          (* In this case we are in a recursive closure function.
             We get the closure env and add it to the arguments we pass *)
          match
            Vars.find_opt
              (Llvm.value_name func.value |> unmangle Schmu)
              param.vars
          with
          | Some func ->
              (* We do this to make sure it's a recursive function.
                 If we cannot find something. there is an error somewhere *)
              let closure_index =
                (Llvm.params func.value |> Array.length) - 1
              in

              let env_ptr = (Llvm.params func.value).(closure_index) in
              (func.value, Seq.return env_ptr)
          | None ->
              failwith "Internal Error: Not a recursive closure application")
  in

  let value, lltyp =
    match ret_t with
    | (Trecord _ | Tvariant _) as t -> (
        let lltyp = get_lltype_def ret_t in
        match pkind_of_typ false t with
        | Boxed ->
            let retval = get_prealloc !allocref param lltyp "ret" in
            let ret' = Seq.return retval in
            let args = ret' ++ args ++ envarg |> Array.of_seq in
            ignore (Llvm.build_call funcval args "" builder);
            (retval, lltyp)
        | Unboxed size ->
            (* Boxed representation *)
            let retval = get_prealloc !allocref param lltyp "ret" in
            let args = args ++ envarg |> Array.of_seq in
            (* Unboxed representation *)
            let tempval = Llvm.build_call funcval args "" builder in
            let ret =
              box_record ~size ~alloc:(Some retval) ~snd_val:None t tempval
            in
            (ret, lltyp))
    | t ->
        let args = args ++ envarg |> Array.of_seq in
        let retval = Llvm.build_call funcval args "" builder in
        (retval, get_lltype_param false t)
  in

  (* For freeing propagated mallocs *)
  (match malloc with
  | Some id -> Ptrtbl.add ptr_tbl id (value, ret)
  | None -> ());

  { value; typ = ret; lltyp; kind = default_kind ret }

and gen_app_tailrec param callee args rec_block ret_t =
  (* We evaluate, there might be side-effects *)
  let func = gen_expr param callee.ex in

  let start_index, ret =
    match func.typ with
    | Tfun (_, (Trecord _ as r), _) | Tfun (_, (Tvariant _ as r), _) -> (
        match pkind_of_typ false r with
        | Boxed -> (1, r)
        | Unboxed size -> (0, type_unboxed size))
    | Tfun (_, ret, _) -> (0, ret)
    | Tunit ->
        failwith "Internal Error: Probably cannot find monomorphized function"
    | _ -> failwith "Internal Error: Not a func in gen app tailrec"
  in

  let handle_arg i oarg =
    let arg' = gen_expr param Monomorph_tree.(oarg.ex) in
    let arg = get_mono_func arg' param oarg.monomorph in
    let llvar = func_to_closure param arg in

    let i = get_index i oarg.mut arg.typ in
    let alloca = Vars.find (name_of_alloc_param i) param.vars in

    (* We store the params in pre-allocated variables *)
    if llvar.value <> alloca.value then
      tailrec_store ~src:llvar ~dst:alloca.value;
    i + 1
  in

  ignore (List.fold_left handle_arg start_index args);

  let lltyp =
    (* TODO record *)
    match ret with
    | Trecord _ | Tvariant _ -> get_lltype_def ret_t
    | t -> get_lltype_param false t
  in

  let value = Llvm.build_br rec_block.rec_ builder in
  { value; typ = Tpoly "tail"; lltyp; kind = default_kind ret }

and gen_app_builtin param (b, fnc) args =
  let handle_arg arg =
    let arg' = gen_expr param Monomorph_tree.(arg.ex) in
    let arg = get_mono_func arg' param arg.monomorph in

    (* For [ignore], we don't really need to generate the closure objects here *)
    match b with Ignore -> arg | _ -> func_to_closure param arg
  in
  let args = List.map handle_arg args in

  let cast f lltyp typ =
    match args with
    | [ value ] ->
        let value = f (bring_default value) lltyp "" builder in
        (* TODO Not always int. That's a bug *)
        { value; typ; lltyp; kind = Imm }
    | _ -> failwith "Internal Error: Arity mismatch in builtin"
  in

  match b with
  | Builtin.Unsafe_ptr_get ->
      let ptr, index =
        match args with
        | [ ptr; index ] -> (bring_default ptr, bring_default index)
        | _ -> failwith "Internal Error: Arity mismatch in builtin"
      in
      let value = Llvm.build_in_bounds_gep ptr [| index |] "" builder in
      { value; typ = fnc.ret; lltyp = Llvm.type_of value; kind = Ptr }
  | Unsafe_ptr_set ->
      let ptr, index, value =
        match args with
        | [ ptr; index; value ] ->
            (bring_default ptr, bring_default index, bring_default_var value)
        | _ -> failwith "Internal Error: Arity mismatch in builtin"
      in
      let ptr = Llvm.build_in_bounds_gep ptr [| index |] "" builder in
      let value = { value with typ = (List.nth fnc.params 2).pt } in

      set_struct_field value ptr;
      { dummy_fn_value with lltyp = unit_t }
  | Realloc ->
      let item_size =
        match fnc.ret with
        | Traw_ptr t -> sizeof_typ t |> Llvm.const_int int_t
        | _ -> failwith "Internal Error: Nonptr return of alloc"
      in

      let ptr, size =
        match args with
        | [ ptr; size ] ->
            let size = Llvm.build_mul size.value item_size "" builder in
            (bring_default ptr, size)
        | _ -> failwith "Internal Error: Arity mismatch in builtin"
      in
      let value = realloc ptr ~size in
      let kind = default_kind fnc.ret in
      { value; typ = fnc.ret; lltyp = Llvm.type_of value; kind }
  | Malloc ->
      let item_size =
        match fnc.ret with
        | Traw_ptr t -> sizeof_typ t |> Llvm.const_int int_t
        | _ -> failwith "Internal Error: Nonptr return of alloc"
      in

      let size =
        match args with
        | [ size ] -> Llvm.build_mul size.value item_size "" builder
        | _ -> failwith "Internal Error: Arity mismatch in builder"
      in
      let ptr_typ = get_lltype_def fnc.ret in
      let value = malloc ~size in
      let value = Llvm.build_bitcast value ptr_typ "" builder in

      { value; typ = fnc.ret; lltyp = Llvm.type_of value; kind = Ptr }
  | Ignore -> dummy_fn_value
  | Int_of_float | Int_of_f32 -> cast Llvm.build_fptosi int_t Tint
  | Int_of_i32 -> cast Llvm.build_intcast int_t Tint
  | Float_of_int | Float_of_i32 -> cast Llvm.build_sitofp float_t Tfloat
  | Float_of_f32 -> cast Llvm.build_fpcast float_t Tfloat
  | I32_of_float | I32_of_f32 -> cast Llvm.build_fptosi i32_t Ti32
  | I32_of_int -> cast Llvm.build_intcast i32_t Ti32
  | F32_of_int | F32_of_i32 -> cast Llvm.build_sitofp f32_t Tf32
  | F32_of_float -> cast Llvm.build_fpcast f32_t Tf32
  | U8_of_int -> cast Llvm.build_intcast u8_t Tu8
  | U8_to_int -> cast Llvm.build_intcast int_t Tu8
  | Not ->
      let value =
        match args with
        | [ value ] -> value.value
        | _ -> failwith "Interal Error: Arity mismatch in builder"
      in

      let true_value = Llvm.const_int bool_t (Bool.to_int true) in
      let value = Llvm.build_xor value true_value "" builder in
      { value; typ = Tbool; lltyp = bool_t; kind = Imm }

and gen_app_inline param args names tree =
  (* Identify args to param names *)
  let f env arg param =
    let arg' = gen_expr env Monomorph_tree.(arg.ex) in
    let arg = get_mono_func arg' env arg.monomorph in

    let vars = Vars.add param arg env.vars in
    { env with vars }
  in
  let env = List.fold_left2 f param args names in
  gen_expr env tree

and gen_if param expr return =
  (* If a function ends in a if expression (and returns a struct),
     we pass in the finalize step. This allows us to handle the branches
     differently and enables tail call elimination *)
  ignore return;

  let is_tailcall e =
    match e.typ with Tpoly id when String.equal "tail" id -> true | _ -> false
  in

  let cond = gen_expr param expr.cond |> bring_default in

  (* Get current block *)
  let start_bb = Llvm.insertion_block builder in
  let parent = Llvm.block_parent start_bb in

  let then_bb = Llvm.append_block context "then" parent in
  Llvm.position_at_end then_bb builder;
  let e1 = gen_expr param expr.e1 in

  (* Codegen can change the current bb *)
  let e1_bb = Llvm.insertion_block builder in

  let else_bb = Llvm.append_block context "else" parent in
  Llvm.position_at_end else_bb builder;
  let e2 = gen_expr param expr.e2 in

  let e2_bb = Llvm.insertion_block builder in
  (* We don't want a merge_bb if both branches are tailcalls, so lazy it *)
  let merge_bb = lazy (Llvm.append_block context "ifcont" parent) in

  let llvar =
    (* Small optimization: If we happen to end up with the same value,
       we don't generate a phi node (can happen in recursion) *)
    match (is_tailcall e1, is_tailcall e2) with
    | true, true ->
        (* No need for the whole block, we just return some value *)
        e1
    | true, false -> e2
    | false, true -> e1
    | false, false -> (
        match e2.typ with
        (* If the else evaluates to void, we don't do anything.
           Void will be added eventually *)
        | Tunit -> e1
        | _ ->
            let e1, e2 =
              (* Both values have to either be ptrs or const literals *)
              match (e1.kind, e2.kind) with
              | Const, (Ptr | Const_ptr) when is_struct e1.typ ->
                  Llvm.position_at_end then_bb builder;
                  let value = alloca param e1.lltyp "" in
                  ignore (Llvm.build_store (bring_default e1) value builder);
                  ({ e1 with value; kind = Const_ptr }, e2)
              | (Const | Imm), (Ptr | Const_ptr) ->
                  (e1, { e2 with value = bring_default e2; kind = e1.kind })
              | (Ptr | Const_ptr), Const when is_struct e2.typ ->
                  let value = alloca param e2.lltyp "" in
                  ignore (Llvm.build_store (bring_default e2) value builder);
                  (e1, { e2 with value; kind = Const_ptr })
              | (Ptr | Const_ptr), (Const | Imm) ->
                  Llvm.position_at_end then_bb builder;
                  ({ e1 with value = bring_default e1; kind = e2.kind }, e2)
              | _, _ -> (e1, e2)
            in

            if e1.value <> e2.value then (
              Llvm.position_at_end (Lazy.force merge_bb) builder;
              let incoming = [ (e1.value, e1_bb); (e2.value, e2_bb) ] in
              let value = Llvm.build_phi incoming "iftmp" builder in
              { value; typ = e1.typ; lltyp = e2.lltyp; kind = e1.kind })
            else e1)
  in

  Llvm.position_at_end start_bb builder;
  ignore (Llvm.build_cond_br cond then_bb else_bb builder);

  if not (is_tailcall e1) then (
    Llvm.position_at_end e1_bb builder;
    ignore (Llvm.build_br (Lazy.force merge_bb) builder));
  if not (is_tailcall e2) then (
    Llvm.position_at_end e2_bb builder;
    ignore (Llvm.build_br (Lazy.force merge_bb) builder));

  if Lazy.is_val merge_bb then
    Llvm.position_at_end (Lazy.force merge_bb) builder;
  llvar

and codegen_record param typ labels allocref const return =
  let lltyp = get_lltype_field typ in

  let value, kind =
    match const with
    | false ->
        let record = get_prealloc !allocref param lltyp "" in

        List.iteri
          (fun i (name, expr) ->
            let ptr = Llvm.build_struct_gep record i name builder in
            let value =
              gen_expr { param with alloca = Some ptr } expr
              |> (* Const records will stay const, no allocation done to lift
                    it to Ptr. Thus, it stays Const*)
              bring_default_var |> func_to_closure param
            in
            set_struct_field value ptr)
          labels;
        (record, Ptr)
    | true when not !const_pass ->
        (* We generate the const for runtime use. An addition to
           re-generating the constants, there are immediate literals.
           We have to take care that some global constants are pointers now *)
        let value =
          let f (_, expr) =
            let e = gen_expr param expr in
            match e.kind with
            | Const_ptr ->
                (* The global value is a ptr, we need to 'deref' it *)
                Llvm.global_initializer e.value |> Option.get
            | _ -> e.value
          in
          let values = List.map f labels |> Array.of_list in
          Llvm.const_named_struct lltyp values
        in
        (* The value might be returned, thus boxed, so we wrap it in an automatic var *)
        if return then (
          let record = get_prealloc !allocref param lltyp "" in
          ignore (Llvm.build_store value record builder);
          (record, Const_ptr))
        else (value, Const)
    | true ->
        let values =
          List.map (fun (_, expr) -> (gen_expr param expr).value) labels
          |> Array.of_list
        in
        let ret = Llvm.const_named_struct lltyp values in
        (ret, Const)
  in

  { value; typ; lltyp = Llvm.type_of value; kind }

and codegen_field param expr index =
  let typ =
    match expr.typ with
    | Trecord (_, _, fields) -> fields.(index).ftyp
    | _ ->
        print_endline (show_typ expr.typ);
        failwith "Internal Error: No record in fields"
  in

  let value = gen_expr param expr in

  let value, kind =
    match value.kind with
    | Const_ptr | Ptr ->
        let p = Llvm.build_struct_gep value.value index "" builder in
        (* In case we return a record, we don't load, but return the pointer.
           The idea is that this will be used either as a return value for a function (where it is copied),
           or for another field, where the pointer is needed.
           We should distinguish between structs and pointers somehow *)
        (p, Ptr)
    | Const ->
        (* If the record is const, we use extractvalue and propagate the constness *)
        let p = Llvm.(const_extractvalue value.value [| index |]) in
        (p, Const)
    | Imm -> failwith "Internal Error: Did not expect Imm in field"
  in

  { value; typ; lltyp = get_lltype_def typ; kind }

and codegen_set param expr valexpr =
  let ptr = gen_expr param expr in
  let value = gen_expr param valexpr in
  (* We know that ptr cannot be a constant record, but value might *)
  set_struct_field value ptr.value;
  { dummy_fn_value with lltyp = unit_t }

and codegen_chain param expr cont =
  ignore (gen_expr param expr);
  gen_expr param cont

and codegen_string_lit param s typ allocref =
  let lltyp = get_struct string_t in
  let ptr = get_const_string s in

  (* Check for preallocs *)
  let string = get_prealloc !allocref param lltyp "str" in

  let cstr = Llvm.build_struct_gep string 0 "cstr" builder in
  ignore (Llvm.build_store ptr cstr builder);
  let len = Llvm.build_struct_gep string 1 "length" builder in
  ignore (Llvm.build_store (Llvm.const_int int_t (String.length s)) len builder);

  { value = string; typ; lltyp; kind = Const_ptr }

and codegen_vector_lit param id es typ allocref =
  let lltyp = get_struct typ in
  let item_typ =
    match typ with
    | Trecord ([ t ], _, _) -> t
    | _ ->
        print_endline (show_typ typ);
        failwith "Internal Error: No record in vector"
  in
  let item_size = sizeof_typ item_typ in
  let cap =
    match es with
    | [] ->
        (* TODO nullptr *)
        (* Empty list so far. We allocate 1 item to get an address *)
        1
    | es -> List.length es
  in
  let ptr_typ = get_lltype_def item_typ |> Llvm.pointer_type in
  let ptr =
    malloc ~size:(cap * item_size |> Llvm.const_int int_t) |> fun ptr ->
    Llvm.build_bitcast ptr ptr_typ "" builder
  in

  (* Check for preallocs *)
  let vec = get_prealloc !allocref param lltyp "vec" in

  (* Add ptr to vector struct *)
  let owned_ptr = Llvm.build_struct_gep vec 0 "owned_ptr" builder in
  let data = Llvm.build_struct_gep owned_ptr 0 "data" builder in

  ignore (Llvm.build_store ptr data builder);

  (* Initialize *)
  let len =
    List.fold_left
      (fun i expr ->
        let index = [| Llvm.const_int int_t i |] in
        let dst = Llvm.build_gep ptr index "" builder in
        let src = gen_expr { param with alloca = Some dst } expr in

        (match src.typ with
        | Trecord _ | Tvariant _ ->
            if dst <> src.value then
              memcpy ~dst ~src ~size:(Llvm.const_int int_t item_size)
            else (* The record was constructed inplace *) ()
        | _ -> ignore (Llvm.build_store src.value dst builder));
        i + 1)
      0 es
  in

  let lenptr = Llvm.build_struct_gep owned_ptr 1 "len" builder in
  ignore (Llvm.(build_store (const_int int_t len) lenptr) builder);

  let capptr = Llvm.build_struct_gep vec 1 "cap" builder in
  ignore (Llvm.(build_store (const_int int_t cap) capptr) builder);

  Ptrtbl.add ptr_tbl id (vec, typ);

  { value = vec; typ; lltyp; kind = Ptr }

and gen_free param expr id =
  let ret = gen_expr param expr in
  ignore (free_id id);
  ret

and gen_ctor param (variant, tag, expr) typ allocref const =
  ignore const;

  (* This approach means we alloca every time, even if the enum
     ends up being a clike constant. There's room for improvement here *)
  let lltyp = get_struct typ in
  let var = get_prealloc !allocref param lltyp variant in

  (* Set tag *)
  let tagptr = Llvm.build_struct_gep var 0 "tag" builder in
  let tag =
    {
      value = Llvm.const_int i32_t tag;
      typ = Ti32;
      lltyp = i32_t;
      kind = Const;
    }
  in
  set_struct_field tag tagptr;

  (* Set data *)
  (match expr with
  | Some expr ->
      let dataptr = Llvm.build_struct_gep var 1 "data" builder in
      let ptr_t = get_lltype_def expr.typ |> Llvm.pointer_type in
      let ptr = Llvm.build_bitcast dataptr ptr_t "" builder in
      let data =
        gen_expr { param with alloca = Some ptr } expr |> bring_default_var
      in

      let dataptr =
        Llvm.build_bitcast dataptr
          (data.lltyp |> Llvm.pointer_type)
          "data" builder
      in
      set_struct_field data dataptr
  | None -> ());
  { value = var; typ; lltyp; kind = Ptr }

and gen_var_index param expr =
  let var = gen_expr param expr in
  let tagptr = Llvm.build_struct_gep var.value 0 "tag" builder in
  let value = Llvm.build_load tagptr "index" builder in
  { value; typ = Ti32; lltyp = i32_t; kind = Imm }

and gen_var_data param expr typ =
  let var = gen_expr param expr in
  let dataptr = Llvm.build_struct_gep var.value 1 "data" builder in
  let ptr_t = get_lltype_def typ |> Llvm.pointer_type in
  let value = Llvm.build_bitcast dataptr ptr_t "" builder in
  { value; typ; lltyp = Llvm.type_of value; kind = Ptr }

and gen_fmt_str param exprs typ allocref id =
  let snprintf_decl =
    lazy
      Llvm.(
        let ft =
          var_arg_function_type i32_t [| voidptr_t; int_t; voidptr_t |]
        in
        declare_function "snprintf" ft the_module)
  in
  let lltyp = get_struct string_t in

  let f (fmtstr, args) expr =
    match expr with
    | Monomorph_tree.Fstr s -> (fmtstr ^ s, args)
    | Fexpr e ->
        let value = gen_expr param e in
        let str, value = fmt_str value in
        (fmtstr ^ str, value :: args)
  in
  let fmt, args = List.fold_left f ("", []) exprs in
  (* Calculate size *)
  let fmtptr = get_const_string fmt in
  let itemargs = List.rev args in
  let args =
    Llvm.const_pointer_null voidptr_t
    :: Llvm.const_int int_t 0 :: fmtptr :: itemargs
    |> Array.of_list
  in
  let size =
    Llvm.build_call (Lazy.force snprintf_decl) args "fmtsize" builder
  in
  (* Add null terminator *)
  let size = Llvm.build_add size (Llvm.const_int i32_t 1) "" builder in
  let size = Llvm.build_intcast size int_t "" builder in
  let ptr = malloc ~size in

  (* Format string *)
  let args = ptr :: size :: fmtptr :: itemargs |> Array.of_list in
  ignore (Llvm.build_call (Lazy.force snprintf_decl) args "fmt" builder);

  (* Build string record *)
  let string = get_prealloc !allocref param lltyp "str" in

  let cstr = Llvm.build_struct_gep string 0 "cstr" builder in
  ignore (Llvm.build_store ptr cstr builder);
  let len = Llvm.build_struct_gep string 1 "length" builder in
  (* Flip sign bit to mark as owned string which needs to be freed *)
  let size = Llvm.build_mul size (Llvm.const_int int_t (-1)) "" builder in
  ignore (Llvm.build_store size len builder);

  Ptrtbl.add ptr_tbl id (string, typ);

  { value = string; typ; lltyp; kind = Ptr }

let fill_constants constants =
  let f (name, tree, toplvl) =
    let init = gen_expr no_param tree in
    (* We only add records to the global table, because they are expected as ptrs.
       For ints or floats, we just return the immediate value *)
    let value = Llvm.define_global name init.value the_module in
    Llvm.set_global_constant true value;
    if not toplvl then Llvm.set_linkage Llvm.Linkage.Internal value;
    Strtbl.add const_tbl name { init with value; kind = Const_ptr }
  in
  List.iter f constants

let def_globals globals =
  let f (name, typ, toplvl) =
    let lltyp = get_lltype_global typ in
    let null = Llvm.const_int int_t 0 in
    let value =
      Llvm.define_global name (Llvm.const_bitcast null lltyp) the_module
    in
    Llvm.set_alignment (sizeof_typ typ) value;
    if not toplvl then Llvm.set_linkage Llvm.Linkage.Internal value;
    Strtbl.add const_tbl name { value; lltyp; typ; kind = Ptr }
  in
  List.iter f globals

let decl_external ~c_linkage cname = function
  | Tfun _ as t when not (is_type_polymorphic t) ->
      declare_function ~c_linkage C cname t
  | typ ->
      let lltyp = get_lltype_global typ in
      let value = Llvm.declare_global lltyp cname the_module in
      (* TODO constness in module *)
      { value; typ; lltyp; kind = Ptr }

let has_init_code tree =
  let rec aux = function
    (* We have to deal with 'toplevel' type nodes only *)
    | Monomorph_tree.Mlet (_, name, _, gname, cont) -> (
        let name = match gname with Some name -> name | None -> name in
        match Strtbl.find_opt const_tbl name with
        | Some thing -> (
            match thing.kind with
            | Const | Const_ptr ->
                (* is const, so no need to initialize *)
                aux cont.expr
            | Ptr | Imm -> true)
        | None -> failwith "Internal Error: global value not found")
    | Mfunction (_, _, cont) -> aux cont.expr
    | Mconst Unit -> false
    | _ -> true
  in
  aux Monomorph_tree.(tree.expr)

let add_frees tree frees =
  List.fold_left
    (fun tree id -> Monomorph_tree.{ tree with expr = Mfree_after (tree, id) })
    tree frees

let add_global_init funcs outname kind body =
  let fname, glname =
    match kind with
    | `Ctor -> ("__" ^ outname ^ "_init", "llvm.global_ctors")
    | `Dtor -> ("__" ^ outname ^ "_deinit", "llvm.global_dtors")
  in
  let p =
    gen_function funcs ~mangle:C
      {
        name = { Monomorph_tree.user = fname; call = fname };
        recursive = Rnone;
        abs =
          {
            func = { params = []; ret = Tunit; kind = Simple };
            pnames = [];
            body;
          };
      }
  in
  let init = Vars.find fname p.vars in
  let open Llvm in
  set_linkage Linkage.Internal init.value;
  set_section ".text.startup" init.value;

  let init =
    [| const_int i32_t 65535; init.value; const_pointer_null voidptr_t |]
  in
  let global = const_array global_t [| const_struct context init |] in
  let global = define_global glname global the_module in
  set_linkage Appending global

let generate ~target ~outname ~release ~modul
    { Monomorph_tree.constants; globals; externals; tree; frees; funcs } =
  (* Fill const_tbl *)
  fill_constants constants;
  def_globals globals;
  const_pass := false;

  (* External declarations *)
  List.iter
    (fun { Monomorph_tree.ext_name = _; ext_typ; cname; c_linkage } ->
      let v = decl_external cname ext_typ ~c_linkage in
      Strtbl.add const_tbl cname v)
    externals;

  (* Factor out functions for llvm *)
  let funcs =
    let vars =
      List.fold_left
        (fun acc (func : Monomorph_tree.to_gen_func) ->
          let typ =
            Tfun (func.abs.func.params, func.abs.func.ret, func.abs.func.kind)
          in
          let fnc =
            declare_function ~c_linkage:false Schmu func.name.call typ
          in

          (* Add to the normal variable environment *)
          Vars.add func.name.call fnc acc)
        Vars.empty funcs
    in

    (* Generate functions *)
    List.fold_left
      (fun acc func -> gen_function acc func)
      { vars; alloca = None; finalize = None; rec_block = None }
      funcs
  in

  if not modul then
    (* Add main *)
    let tree = add_frees tree frees in
    gen_function funcs ~mangle:C
      {
        name = { Monomorph_tree.user = "main"; call = "main" };
        recursive = Rnone;
        abs =
          {
            func =
              {
                params = [ { pt = Tint; pmut = false } ];
                ret = Tint;
                kind = Simple;
              };
            pnames = [ "arg" ];
            body = { tree with typ = Tint };
          };
      }
    |> ignore
  else if has_init_code tree then (
    (* Or module init *)
    add_global_init funcs outname `Ctor tree;

    match frees with
    | [] -> ()
    | frees ->
        (* Add frees to global dctors in reverse order *)
        let body =
          Monomorph_tree.{ typ = Tunit; expr = Mconst Unit; return = true }
        in
        add_global_init no_param outname `Dtor (add_frees body frees));

  (match Llvm_analysis.verify_module the_module with
  | Some output -> print_endline output
  | None -> ());

  if release then (
    let pm = Llvm.PassManager.create () in
    let bldr = Llvm_passmgr_builder.create () in
    Llvm_passmgr_builder.set_opt_level 2 bldr;
    Llvm_passmgr_builder.populate_lto_pass_manager ~internalize:true
      ~run_inliner:true pm bldr;
    Llvm.PassManager.run_module the_module pm |> ignore);

  (* Emit code to file *)
  Llvm_all_backends.initialize ();
  let open Llvm_target in
  let triple =
    match target with Some target -> target | None -> Target.default_triple ()
  in
  let reloc_mode = RelocMode.PIC in
  let target = Target.by_triple triple in

  let machine = TargetMachine.create ~triple target ~reloc_mode in
  TargetMachine.emit_to_file the_module CodeGenFileType.ObjectFile
    (outname ^ ".o") machine
