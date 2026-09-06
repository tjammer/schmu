module Make (T : Lltypes_intf.S) : Abi_intf.S = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open Abi_intf

  (* For passing arguments *)
  type reg_pool = { int : int; sse : int }
  type abi_kind = SysV | Arm64

  (* global state for current abi *)
  let abi = ref SysV
  let pool = ref { int = max_int; sse = max_int }
  let set_pool p = pool := p

  let pool_of_triple triple =
    if String.starts_with ~prefix:"x86_64" triple then (
      abi := SysV;
      { int = 6; sse = 8 })
    else if String.starts_with ~prefix:"arm64" triple then (
      abi := Arm64;
      { int = max_int; sse = max_int })
    else (
      abi := SysV;
      { int = max_int; sse = max_int })

  let byval_aggregate () = match !abi with SysV -> true | Arm64 -> false
  let sret_attribute () = match !abi with SysV -> false | Arm64 -> true

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
          (* We could be less than 8 bytes but hit 8 with alignment to the next
           type *)
          (List.rev (typ :: items), tl, 8)
        else get_word ~size (typ :: items) tl

  and extract_word ~size = function
    | [ Tf32; Tf32 ] -> Some F32_vec
    | [ Tf32 ] -> Some F32
    | [ Tfloat ] -> Some Float
    | [ single ] ->
        (* A lone field keeps its natural width even in a wider, padded word *)
        let _, align = size_alignof_typ single in
        let size = match align with 1 -> 1 | 2 -> 2 | 4 -> 4 | _ -> 8 in
        Some (Ints size)
    | [] -> None
    | _ ->
        let size = match size with 1 -> 1 | 2 -> 2 | 3 | 4 -> 4 | _ -> 8 in
        Some (Ints size)

  and align_tail size = function
    | [] -> 0
    | t :: _ ->
        let _, upto = size_alignof_typ t in
        alignup ~size ~upto

  and pkind_of_typ_sysv mut typ =
    (* We destruct the type into words of 8 byte.
       A word is then either a double, an int (containing different types)
       or a vector of float (for x86_64-linux-gnu). If a type straddles
       the 8 byte boundary, we have to box it.
       Depending on the size, we end up with one ([One_param]) or
       two ([Two_params]) parameters.
       Still missing: A 'short' type to unbox e.g. 2 bools. *)
    let aux typ types =
      let size = sizeof_typ typ in
      if size > 16 || size = 0 then Boxed
      else
        let _, align = size_alignof_typ typ in
        (* A word which is padded out to its tail alignment occupies the whole
           padded region in its register, so we widen it *)
        let tail_size size = min 8 (alignup ~size ~upto:align) in
        let fst, tail, size = get_word ~size:0 [] types in
        let size = if List.is_empty tail then size else 8 in
        let fst = extract_word ~size fst in
        let snd, rest, size = get_word ~size:0 [] tail in
        let size = if List.is_empty rest then tail_size size else 8 in
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

  (* A homogeneous float aggregate (HFA) is a struct of 1-4 members all of the
     same float type. On arm64 those are passed and returned as a homogeneous
     array of that float type *)
  let hfa_of_fields types =
    match types with
    | [] | _ :: _ :: _ :: _ :: _ :: _ -> None
    | fst :: rest -> (
        let atom =
          match fst with Tfloat -> Some Float | Tf32 -> Some F32 | _ -> None
        in
        match atom with
        | Some a when List.for_all (fun t -> t = fst) rest ->
            Some (Arr (a, List.length types))
        | _ -> None)

  let pkind_of_typ_arm64 mut types typ =
    if mut then Boxed
    else
      (* A homogeneous float aggregate is passed as an array of its float type
         even if it exceeds 16 bytes *)
      match hfa_of_fields types with
      | Some arr -> Unboxed arr
      | None ->
          let size = sizeof_typ typ in
          if size > 16 || size = 0 then Boxed
          else if
            (* Plain structs are passed as one or two integer words, rounded
               up to a full word *)
            size <= 8
          then Unboxed (One_param (Ints 8))
          else Unboxed (Arr (Ints 8, 2))

  let pkind_of_typ mut typ =
    let fields_of typ =
      match typ with
      | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
          Array.map (fun (field : Cleaned_types.field) -> field.ftyp) fields
          |> Array.to_list
      | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) -> (
          match variant_get_largest ctors with
          | Some typ -> [ Ti32; typ ]
          | None -> [ Ti32 ])
      | Tfixed_array (i, t) -> List.init i (fun _ -> t)
      | _ -> []
    in
    match !abi with
    | SysV -> pkind_of_typ_sysv mut typ
    | Arm64 -> (
        match typ with
        | Trecord (_, (Rec_not _ | Rec_top _), _)
        | Tvariant (_, (Rec_not _ | Rec_top _), _)
        | Tfixed_array _ ->
            pkind_of_typ_arm64 mut (fields_of typ) typ
        | _ -> Boxed)

  (* return kind *)
  let rkind_of_typ mut typ =
    match !abi with
    | SysV -> pkind_of_typ_sysv mut typ
    | Arm64 -> (
        match pkind_of_typ mut typ with
        | Unboxed (Arr (((Float | F32) as a), n)) -> Unboxed (Hfa_ret (a, n))
        | Unboxed (One_param (Ints _)) ->
            (* Returned as an exact-width integer, not rounded up to i64 *)
            Unboxed (Int_ret (sizeof_typ typ))
        | kind -> kind)

  (* How many registers of each pool an unboxed aggregate occupies *)
  let atom_regs = function Ints _ -> (1, 0) | F32 | F32_vec | Float -> (0, 1)

  let unboxed_regs = function
    | One_param a -> atom_regs a
    | Two_params (a, b) ->
        let gi, si = atom_regs a and gj, sj = atom_regs b in
        (gi + gj, si + sj)
    | Arr (atom, n) ->
        let gi, si = atom_regs atom in
        (gi * n, si * n)
    | Hfa_ret (atom, n) ->
        let gi, si = atom_regs atom in
        (gi * n, si * n)
    | Int_ret _ -> (1, 0)

  let scalar_regs typ = match typ with Tfloat | Tf32 -> (0, 1) | _ -> (1, 0)

  let classify_param (int_left, sse_left) p =
    let typ = p.Cleaned_types.pt in
    match pkind_of_typ p.pmut typ with
    | Unboxed (One_param (Ints _)) as kind ->
        ((max 0 (int_left - 1), sse_left), kind)
    | Unboxed u when is_aggregate typ ->
        let need_i, need_s = unboxed_regs u in
        if need_i <= int_left && need_s <= sse_left then
          ((int_left - need_i, sse_left - need_s), Unboxed u)
        else ((int_left, sse_left), Boxed)
    | kind ->
        let use_i, use_s =
          if is_aggregate typ then (0, 0) else scalar_regs typ
        in
        ((max 0 (int_left - use_i), max 0 (sse_left - use_s)), kind)

  (* [sret] is true if a struct return pointer sits in the first reg *)
  let classify_params ~sret params =
    let start =
      let i = if sret then 1 else 0 in
      (!pool.int - i, !pool.sse)
    in
    let _, _, res =
      List.fold_left
        (fun (pools, idx, acc) p ->
          let pools, kind = classify_param pools p in
          let width =
            match (p.Cleaned_types.pt, kind) with
            | Cleaned_types.Tunit, _ -> 0
            | _, Unboxed (Two_params _) -> 2
            | _ -> 1
          in
          (pools, idx + width, (p, kind, idx, width) :: acc))
        (start, (if sret then 1 else 0), [])
        params
    in
    List.rev res

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

  (* The LLVM type of the lowered form. [ret_typ] is the record type being
     lowered, needed because an arm64 HFA return uses the struct type itself *)
  let lltype_unboxed kind ret_typ =
    match kind with
    | One_param a -> lltype_unbox a
    | Two_params (a, b) ->
        Llvm.struct_type context [| lltype_unbox a; lltype_unbox b |]
    | Arr (a, n) -> Llvm.array_type (lltype_unbox a) n
    | Hfa_ret _ -> T.get_lltype_def ret_typ
    | Int_ret size -> Llvm.integer_type context (size * 8)

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
    | Arr (a, n) -> Tfixed_array (n, helper a)
    (* For tailrec bookkeeping the HFA return flows through an alloca, where
       the array form is fine (same size as the struct) *)
    | Hfa_ret (a, n) -> Tfixed_array (n, helper a)
    | Int_ret size -> (
        match size with
        | 1 -> Tu8
        | 2 -> Tu16
        | 4 -> Tu32
        | 8 -> Tint
        | i ->
            "unsupported size for unboxed struct return: " ^ string_of_int i
            |> failwith)

  let box_record typ ~size ?(alloc = None) ~snd_val value =
    (* From int to record *)
    (* If [snd_val] is present, the value was passed as two params
       and we construct the struct from both *)
    let box_t = lltype_unboxed size typ in
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

  (* Boxes a value which was passed unboxed back into a record. [kind] is the
     classified passing kind, when [Boxed] the value already is a pointer to
     the record *)
  let maybe_box_record_kind kind mut typ ?(alloc = None) ?(snd_val = None) value
      =
    ignore mut;
    (* From int to record *)
    match kind with
    | Unboxed size -> box_record typ ~size ~alloc ~snd_val value
    | Boxed -> value

  (* Checks the param kind before calling [box_record] *)
  let maybe_box_record mut typ ?(alloc = None) ?(snd_val = None) value =
    maybe_box_record_kind (pkind_of_typ mut typ) mut typ ~alloc ~snd_val value

  let unbox_const_record kind value =
    (* TODO Implement for two params and check why it's unreachable right now *)
    let target_type = lltype_unboxed kind value.typ in
    match kind with
    | Two_params _ ->
        failwith "Internal Error: Cannot deal with const two types yet"
    | One_param (Ints _) ->
        let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
        if pieces > 1 then (
          let ptr = Llvm.build_alloca value.lltyp "" builder in
          Llvm.build_store value.value ptr builder |> ignore;
          Llvm.build_load target_type ptr "" builder)
        else
          let field = Llvm.build_extractvalue value.value 0 "" builder in
          let field_bits = Llvm.integer_bitwidth (Llvm.type_of field) in
          let target_bits = Llvm.integer_bitwidth target_type in
          (* A small struct is rounded up to a full word on arm64, so the
             field may be narrower than the target integer *)
          if field_bits < target_bits then
            Llvm.build_zext field target_type "" builder
          else if field_bits > target_bits then
            Llvm.build_trunc field target_type "" builder
          else Llvm.const_bitcast field target_type
    | One_param (F32 | Float) ->
        let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
        if pieces > 1 then failwith "Float of pieces TODO"
        else
          let value = Llvm.build_extractvalue value.value 0 "" builder in
          Llvm.const_bitcast value target_type
    | One_param F32_vec ->
        let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
        if pieces <> 2 then failwith "F32_vec of pieces TODO"
        else
          let v1 = Llvm.build_extractvalue value.value 0 "" builder in
          let v2 = Llvm.build_extractvalue value.value 1 "" builder in
          Llvm.const_vector [| v1; v2 |]
    | Arr _ | Hfa_ret _ | Int_ret _ ->
        (* Go through memory to reinterpret the record as the array/integer *)
        let ptr = Llvm.build_alloca value.lltyp "" builder in
        Llvm.build_store value.value ptr builder |> ignore;
        Llvm.build_load target_type ptr "" builder

  let unbox_record ~kind ~ret value =
    let struct_t = lazy (lltype_unboxed kind value.typ) in

    let is_const =
      match value.kind with Const -> true | Ptr | Const_ptr | Imm -> false
    in

    (* If this is a return value, we unbox it as a struct every time *)
    match (ret, kind) with
    | (true, _ | _, (One_param _ | Arr _ | Hfa_ret _ | Int_ret _)) when is_const
      ->
        (unbox_const_record kind value, None)
    | true, _ | _, (One_param _ | Arr _ | Hfa_ret _ | Int_ret _) ->
        (* Single lowered value (scalar, array or integer): load it from the
           record's memory. A small struct rounded up to a wider integer word
           (arm64) is loaded at its own size and extended, to avoid reading
           past the record *)
        let lowered = Lazy.force struct_t in
        let rec_size = sizeof_typ value.typ in
        let lowered_size =
          match kind with
          | One_param (Ints n) -> n
          | Int_ret n -> n
          | _ -> rec_size
        in
        if lowered_size > rec_size then
          (* Load the record's bytes as an integer of its own width, then
             widen to the target word *)
          let rec_int = Llvm.integer_type context (rec_size * 8) in
          let v = Llvm.build_load rec_int value.value "unbox" builder in
          (Llvm.build_zext v lowered "unbox" builder, None)
        else (Llvm.build_load lowered value.value "unbox" builder, None)
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
