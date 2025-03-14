module Make (T : Lltypes_intf.S) : Abi_intf.S = struct
  open Cleaned_types
  open Llvm_types
  open Size_align

  type unboxed_atom = Ints of int | F32 | F32_vec | Float

  type unboxed =
    | One_param of unboxed_atom
    | Two_params of unboxed_atom * unboxed_atom

  type aggregate_param_kind = Boxed | Unboxed of unboxed

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
        else if
          let align = align_tail size tl in
          align = 8
        then
          (* We could be less than 8 bypes but hit 8 with alignment to the next
             type *)
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

  and align_tail size = function
    | [] -> 0
    | t :: _ ->
        let _, upto = size_alignof_typ t in
        alignup ~size ~upto

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
      if size > 16 || size = 0 then Boxed
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
    | Trecord (_, Rec_folded, _) when not mut -> failwith "unreachable"
    | Trecord (_, (Rec_not fields | Rec_top fields), _) when not mut ->
        let types =
          Array.map (fun (field : Cleaned_types.field) -> field.ftyp) fields
          |> Array.to_list
        in
        aux typ types
    | Tvariant (_, Rec_folded, _) when not mut -> failwith "unreachable"
    | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) when not mut ->
        let types =
          match variant_get_largest ctors with
          | Some typ -> [ Ti32; typ ]
          | None -> [ Ti32 ]
        in
        aux typ types
    | Tfixed_array (i, t) when not mut -> aux typ (List.init i (fun _ -> t))
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
      | Ints 2 -> Tu16
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
          ( [],
            Rec_not [| anon_field_of_typ a; anon_field_of_typ b |],
            Some "param_tup" )

  let box_record typ ~size ?(alloc = None) ~snd_val value =
    ignore typ;
    (* From int to record *)
    (* If [snd_val] is present, the value was passed as two params
       and we construct the struct from both *)
    let box_t = lltype_unboxed size in
    let intptr =
      match alloc with
      | None -> Llvm.build_alloca box_t "box" builder
      | Some alloc -> alloc
    in

    (match snd_val with
    | None -> ignore (Llvm.build_store value intptr builder)
    | Some v2 ->
        let ptr = Llvm.build_struct_gep box_t intptr 0 "fst" builder in
        ignore (Llvm.build_store value ptr builder);
        let ptr = Llvm.build_struct_gep box_t intptr 1 "snd" builder in
        ignore (Llvm.build_store v2 ptr builder));
    intptr

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
        if pieces > 1 then
          Llvm.const_intcast value.value target_type ~is_signed:false
        else
          let is_signed =
            match value.typ with
            | Trecord (_, Rec_folded, _) -> failwith "unreachable"
            | Trecord (_, (Rec_not fields | Rec_top fields), _) -> (
                match fields.(0).ftyp with Tbool -> false | _ -> true)
            | Tvariant _ -> true
            | _ -> failwith "Internal Error: Not a record to unbox"
          in
          let value = Llvm.build_extractvalue value.value 0 "" builder in
          Llvm.const_intcast ~is_signed value target_type
    | One_param (F32 | Float) ->
        let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
        if pieces > 1 then failwith "Float of pieces TODO"
        else
          let value = Llvm.build_extractvalue value.value 0 "" builder in
          Llvm.const_fpcast value target_type
    | One_param F32_vec ->
        let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
        if pieces <> 2 then failwith "F32_vec of pieces TODO"
        else
          let v1 = Llvm.build_extractvalue value.value 0 "" builder in
          let v2 = Llvm.build_extractvalue value.value 1 "" builder in
          Llvm.const_vector [| v1; v2 |]

  let unbox_record ~kind ~ret value =
    let struct_t = lazy (lltype_unboxed kind) in

    let is_const =
      match value.kind with Const -> true | Ptr | Const_ptr | Imm -> false
    in

    (* If this is a return value, we unbox it as a struct every time *)
    match (ret, kind) with
    | (true, _ | _, One_param _) when is_const ->
        (unbox_const_record kind value, None)
    | true, _ | _, One_param _ ->
        (Llvm.build_load (Lazy.force struct_t) value.value "unbox" builder, None)
    | _, Two_params (a, b) ->
        (* We load the two arguments from the struct type *)
        let ptr =
          Llvm.build_struct_gep (Lazy.force struct_t) value.value 0 "fst"
            builder
        in
        let v1 = Llvm.build_load (lltype_unbox a) ptr "fst" builder in
        let ptr =
          Llvm.build_struct_gep (Lazy.force struct_t) value.value 1 "snd"
            builder
        in
        let v2 = Llvm.build_load (lltype_unbox b) ptr "snd" builder in
        (v1, Some v2)
end
