module Make (T : Lltypes_intf.S) : Abi_intf.S = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open Abi_intf

  (* Classification happens in two steps. A per-ABI classifier (the [Sysv] and
     [Arm64] modules) maps a type to [pieces]: either [Pboxed] (passed or
     returned through memory) or one piece per register it occupies. The pieces
     are then mapped to the public [unboxed] shape (one or two params, an array,
     or a return-only specialization). *)

  (* For passing arguments *)
  type reg_pool = { int : int; sse : int }

  (* Internal classification result: [Parray] is an aggregate passed as a
     single array parameter (arm64) rather than split into word params.
     [Preturn] is a return-only shape with no parameter equivalent *)
  type pieces =
    | Pboxed
    | Punboxed of unboxed_atom list
    | Parray of unboxed_atom * int
    | Preturn of unboxed

  let atom_lltype = function
    | Ints 1 -> u8_t
    | Ints 2 -> i16_t
    | Ints 4 -> i32_t
    | Ints 8 -> int_t
    | F32 -> f32_t
    | F32_vec -> Llvm.vector_type f32_t 2
    | Float -> float_t
    | Ints i ->
        "unsupported size for unboxed struct: " ^ string_of_int i |> failwith

  let atom_typ = function
    | Ints 1 -> Tu8
    | Ints 2 -> Tu16
    | Ints 4 -> Ti32
    | Ints 8 -> Tint
    | F32 -> Tf32
    | F32_vec | Float -> Tfloat
    | Ints i ->
        "unsupported size for unboxed struct: " ^ string_of_int i |> failwith

  (* The scalar leaves of an aggregate together with their absolute byte
     offsets *)
  let leaf_offsets types =
    (* [aux off acc t] appends the (offset, leaf) pairs of [t], laid out
       starting at the (already aligned) [off], to [acc]. *)
    let rec aux off acc t =
      match t with
      | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
          snd
            (Array.fold_left
               (fun (off, acc) (f : field) ->
                 let _, align = size_alignof_typ f.ftyp in
                 let off = alignup ~size:off ~upto:align in
                 (off + sizeof_typ f.ftyp, aux off acc f.ftyp))
               (off, acc) fields)
      | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) -> (
          (* The tag (i32) at the start, then the largest payload *)
          let acc = (off, Ti32) :: acc in
          let off = off + 4 in
          match variant_get_largest ctors with
          | Some typ ->
              let _, align = size_alignof_typ typ in
              aux (alignup ~size:off ~upto:align) acc typ
          | None -> acc)
      | Tfixed_array (n, t) ->
          let _, align = size_alignof_typ t in
          let rec rep off acc n =
            if n = 0 then acc
            else
              let off = alignup ~size:off ~upto:align in
              rep (off + sizeof_typ t) (aux off acc t) (n - 1)
          in
          rep off acc n
      | _ -> (off, t) :: acc
    in
    let rec collect off acc = function
      | [] -> List.rev acc
      | t :: tl ->
          let _, align = size_alignof_typ t in
          let off = alignup ~size:off ~upto:align in
          collect (off + sizeof_typ t) (aux off acc t) tl
    in
    collect 0 [] types

  (* The immediate field types an aggregate is classified from *)
  let fields_of = function
    | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
        Array.map (fun (field : field) -> field.ftyp) fields |> Array.to_list
    | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) -> (
        match variant_get_largest ctors with
        | Some typ -> [ Ti32; typ ]
        | None -> [ Ti32 ])
    | Tfixed_array (i, t) -> List.init i (fun _ -> t)
    | _ -> []

  let classifiable = function
    | Trecord (_, (Rec_not _ | Rec_top _), _)
    | Tvariant (_, (Rec_not _ | Rec_top _), _)
    | Tfixed_array _ ->
        true
    | _ -> false

  module type Abi = sig
    val pool : reg_pool
    val byval_aggregate : bool
    val sret_attribute : bool
    val classify : ret:bool -> typ -> pieces
    val alloc : reg_pool -> unboxed_atom list -> reg_pool option
  end

  module Sysv : Abi = struct
    (* The SysV ABI classifies the recursively flattened sequence of scalar
       fields in words of 8 byte. A word is an integer of some width, a double,
       or a vector of two floats. If a leaf straddles a word boundary the whole
       aggregate is passed by stack ptr. *)

    let classify_word ~used ~is_last ~align leaves =
      match List.map snd leaves with
      | [ Tf32; Tf32 ] -> F32_vec
      | [ Tf32 ] -> F32
      | [ Tfloat ] -> Float
      | [ single ] when not (is_aggregate single) ->
          (* A lone scalar field keeps its natural width even in a wider, padded
             word *)
          let _, a = size_alignof_typ single in
          Ints (match a with 1 -> 1 | 2 -> 2 | 4 -> 4 | _ -> 8)
      | _ ->
          (* A word of several fields, or a single aggregate field, occupies the
             whole (padded) word *)
          let size =
            if is_last then min 8 (alignup ~size:used ~upto:align) else 8
          in
          Ints (match size with 1 -> 1 | 2 -> 2 | 3 | 4 -> 4 | _ -> 8)

    let classify ~ret:_ typ =
      if not (classifiable typ) then Pboxed
      else
        let size = sizeof_typ typ in
        if size > 16 || size = 0 then Pboxed
        else
          let leaves = leaf_offsets (fields_of typ) in
          (* Split the scalar leaves into the two eightbyte words by offset. A
             leaf which straddles the boundary forces the struct into memory *)
          let in_word w (off, t) =
            if (off mod 8) + sizeof_typ t > 8 then raise Exit (* straddles *)
            else off / 8 = w
          in
          match
            try
              Some
                (List.filter (in_word 0) leaves, List.filter (in_word 1) leaves)
            with Exit -> None
          with
          | None -> Pboxed
          | Some (w0, w1) -> (
              let _, align = size_alignof_typ typ in
              let classify leaves is_last =
                match leaves with
                | [] -> None
                | _ ->
                    let used =
                      List.fold_left
                        (fun m (off, t) -> max m ((off mod 8) + sizeof_typ t))
                        0 leaves
                    in
                    Some (classify_word ~used ~is_last ~align leaves)
              in
              match (classify w0 (List.is_empty w1), classify w1 true) with
              | Some a, Some b -> Punboxed [ a; b ]
              | Some a, None -> Punboxed [ a ]
              | None, Some b -> Punboxed [ b ]
              | None, None -> Pboxed)

    (* Registers a piece occupies: (int, sse) *)
    let regs_of = function Ints _ -> (1, 0) | F32 | F32_vec | Float -> (0, 1)

    (* [None] if the aggregate does not fit *)
    let alloc pool pieces =
      let need_i, need_s =
        List.fold_left
          (fun (i, s) a ->
            let i', s' = regs_of a in
            (i + i', s + s'))
          (0, 0) pieces
      in
      match pieces with
      | [ a ] ->
          let i, s = regs_of a in
          Some { int = max 0 (pool.int - i); sse = max 0 (pool.sse - s) }
      | _ when need_i <= pool.int && need_s <= pool.sse ->
          Some { int = pool.int - need_i; sse = pool.sse - need_s }
      | _ -> None

    let byval_aggregate = true
    let sret_attribute = false
    let pool = { int = 6; sse = 8 }
  end

  module Arm64 : Abi = struct
    (* On arm64 a homogeneous float aggregate (HFA) is a struct of up to 4
       members all of the same float type and is passed and returned as a array
       of that type. Nested structs of floats still count as homogeneous, so we
       look at the flattened scalar leaves. Any other aggregate up to 16 bytes
       is passed as one or two full integer words. Larger ones per ptr *)

    let hfa types =
      match List.map snd (leaf_offsets types) with
      | [] | _ :: _ :: _ :: _ :: _ :: _ -> None
      | fst :: _ as leaves -> (
          match fst with
          | Tfloat when List.for_all (( = ) Tfloat) leaves ->
              Some (Float, List.length leaves)
          | Tf32 when List.for_all (( = ) Tf32) leaves ->
              Some (F32, List.length leaves)
          | _ -> None)

    let classify ~ret typ =
      if not (classifiable typ) then Pboxed
      else
        match hfa (fields_of typ) with
        | Some (a, n) -> if ret then Preturn (Hfa_ret (a, n)) else Parray (a, n)
        | None ->
            let size = sizeof_typ typ in
            if size > 16 || size = 0 then Pboxed
            else if size <= 8 then
              if ret then Preturn (Int_ret size) else Parray (Ints 8, 1)
            else Parray (Ints 8, 2)

    let alloc pool n = Some { pool with int = max 0 (pool.int - List.length n) }
    let byval_aggregate = false
    let sret_attribute = true
    let pool = { int = max_int; sse = max_int }
  end

  (* global state for current abi *)
  type abi_kind = SysV | Arm64

  let abi = ref SysV
  let pool = ref { int = max_int; sse = max_int }
  let set_pool p = pool := p

  let pool_of_triple triple =
    if String.starts_with ~prefix:"x86_64" triple then (
      abi := SysV;
      Sysv.pool)
    else if String.starts_with ~prefix:"arm64" triple then (
      abi := Arm64;
      Arm64.pool)
    else (
      abi := SysV;
      { int = max_int; sse = max_int })

  let byval_aggregate () =
    match !abi with
    | SysV -> Sysv.byval_aggregate
    | Arm64 -> Arm64.byval_aggregate

  let sret_attribute () =
    match !abi with
    | SysV -> Sysv.sret_attribute
    | Arm64 -> Arm64.sret_attribute

  (* Pieces a type is passed/returned as, for the current abi. [ret] selects
     the return convention, which differs from the passing one on arm64 *)
  let pieces_of_typ ~ret mut typ =
    if mut then Pboxed
    else
      match !abi with
      | SysV -> Sysv.classify ~ret typ
      | Arm64 -> Arm64.classify ~ret typ

  (* Map pieces to the public [unboxed] shape *)
  let shape_of_pieces = function
    | [ a ] -> One_param a
    | [ a; b ] -> Two_params (a, b)
    | atoms -> Arr (List.hd atoms, List.length atoms)

  let kind_of_pieces = function
    | Pboxed -> Boxed
    | Punboxed pieces -> Unboxed (shape_of_pieces pieces)
    | Parray ((Ints _ as a), 1) -> Unboxed (One_param a)
    | Parray (a, n) -> Unboxed (Arr (a, n))
    | Preturn kind -> Unboxed kind

  let pkind_of_typ mut typ = pieces_of_typ ~ret:false mut typ |> kind_of_pieces

  (* return kind *)
  let rkind_of_typ mut typ = pieces_of_typ ~ret:true mut typ |> kind_of_pieces

  let classify_param pool p =
    let typ = p.Cleaned_types.pt in
    match pieces_of_typ ~ret:false p.pmut typ with
    | Pboxed -> (
        match typ with
        | t when is_aggregate t -> (pool, Boxed)
        | Tfloat | Tf32 -> ({ pool with sse = max 0 (pool.sse - 1) }, Boxed)
        | _ -> ({ pool with int = max 0 (pool.int - 1) }, Boxed))
    | (Punboxed _ | Parray _) as plan -> (
        let pieces =
          match plan with
          | Punboxed p -> p
          | Parray (a, n) -> List.init n (fun _ -> a)
          | Pboxed | Preturn _ -> failwith "unreachable"
        in
        let alloc =
          match !abi with
          | SysV -> Sysv.alloc pool pieces
          | Arm64 -> Arm64.alloc pool pieces
        in
        match alloc with
        | None -> (pool, Boxed)
        | Some pool -> (pool, kind_of_pieces plan))
    | Preturn _ -> failwith "unreachable"

  (* [sret] is true if a struct return pointer sits in the first reg *)
  let classify_params ~sret params =
    let start =
      let i = if sret then 1 else 0 in
      ({ !pool with int = !pool.int - i }, i, [])
    in
    let _, _, res =
      List.fold_left
        (fun (pool, idx, acc) p ->
          let pool, kind = classify_param pool p in
          let width =
            match (p.Cleaned_types.pt, kind) with
            | Cleaned_types.Tunit, _ -> 0
            | _, Unboxed (Two_params _) -> 2
            | _ -> 1
          in
          (pool, idx + width, (p, kind, idx, width) :: acc))
        start params
    in
    List.rev res

  let lltype_unbox = atom_lltype

  (* The LLVM type of the lowered form. [ret_typ] is the record type being
     lowered, needed because an arm64 HFA return uses the struct type itself *)
  let lltype_unboxed kind ret_typ =
    match kind with
    | One_param a -> atom_lltype a
    | Two_params (a, b) ->
        Llvm.struct_type context [| atom_lltype a; atom_lltype b |]
    | Arr (a, n) -> Llvm.array_type (atom_lltype a) n
    | Hfa_ret _ -> T.get_lltype_def ret_typ
    | Int_ret size -> Llvm.integer_type context (size * 8)

  let type_unboxed kind =
    let anon_field_of_typ ftyp = { mut = false; ftyp } in
    match kind with
    | One_param a -> atom_typ a
    | Two_params (a, b) ->
        (* We need a tuple here *)
        Trecord
          ( [],
            Rec_not
              [|
                anon_field_of_typ (atom_typ a); anon_field_of_typ (atom_typ b);
              |],
            Some "param_tup" )
    | Arr (a, n) -> Tfixed_array (n, atom_typ a)
    (* For tailrec bookkeeping the HFA return flows through an alloca, where
       the array form is fine (same size as the struct) *)
    | Hfa_ret (a, n) -> Tfixed_array (n, atom_typ a)
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
     classified passing kind, when [Boxed] the value already is a pointer to the
     record *)
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
    (* Whether the record has a nested aggregate as a direct field, in which
       case we cannot extract scalars directly and go through memory *)
    let has_nested_agg =
      Llvm.struct_element_types value.lltyp
      |> Array.exists (fun t ->
          match Llvm.classify_type t with
          | Llvm.TypeKind.Struct | Llvm.TypeKind.Array -> true
          | _ -> false)
    in
    let via_mem () =
      let ptr = Llvm.build_alloca value.lltyp "" builder in
      Llvm.build_store value.value ptr builder |> ignore;
      Llvm.build_load target_type ptr "" builder
    in
    match kind with
    | Two_params _ ->
        failwith "Internal Error: Cannot deal with const two types yet"
    | One_param (Ints _) ->
        let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
        let field0_t = (Llvm.struct_element_types value.lltyp).(0) in
        if
          pieces > 1 || not (Llvm.classify_type field0_t = Llvm.TypeKind.Integer)
        then via_mem ()
        else
          let field = Llvm.build_extractvalue value.value 0 "" builder in
          let field_bits = Llvm.integer_bitwidth (Llvm.type_of field) in
          let target_bits = Llvm.integer_bitwidth target_type in
          (* A small struct is rounded up to a full word on arm64, so the field
             may be narrower than the target integer *)
          if field_bits < target_bits then
            Llvm.build_zext field target_type "" builder
          else if field_bits > target_bits then
            Llvm.build_trunc field target_type "" builder
          else Llvm.const_bitcast field target_type
    | One_param (F32 | Float) ->
        let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
        if pieces > 1 || has_nested_agg then via_mem ()
        else
          let value = Llvm.build_extractvalue value.value 0 "" builder in
          Llvm.const_bitcast value target_type
    | One_param F32_vec ->
        let pieces = Llvm.struct_element_types value.lltyp |> Array.length in
        if pieces <> 2 || has_nested_agg then via_mem ()
        else
          let v1 = Llvm.build_extractvalue value.value 0 "" builder in
          let v2 = Llvm.build_extractvalue value.value 1 "" builder in
          Llvm.const_vector [| v1; v2 |]
    | Arr _ | Hfa_ret _ | Int_ret _ -> via_mem ()

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
        (* Single lowered value (scalar, array or integer), load it from the
           record's memory. A small struct rounded up to a wider integer word
           (arm64) is loaded at its own size and extended, to avoid reading past
           the record *)
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
