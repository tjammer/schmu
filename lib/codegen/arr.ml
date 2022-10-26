module type S = sig
  open Cleaned_types
  open Llvm_types

  val gen_array_lit :
    Llvm_types.param ->
    Monomorph_tree.monod_tree list ->
    typ ->
    Monomorph_tree.alloca ->
    llvar

  val array_get : llvar list -> typ -> llvar
  val array_set : llvar list -> llvar
  val incr_refcount : llvar -> unit
  val decr_refcount : llvar -> unit
end

module type Core = sig
  open Llvm_types

  val gen_expr : param -> Monomorph_tree.monod_tree -> llvar
end

module Make (T : Lltypes_intf.S) (H : Helpers.S) (C : Core) = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open T
  open H
  open C

  let ci i = Llvm.const_int int_t i

  let item_type_head_size typ =
    (* Return pair lltyp, size of head *)
    let item_typ =
      match typ with
      | Tarray t -> t
      | _ ->
          print_endline (show_typ typ);
          failwith "Internal Error: No array in array"
    in
    let llitem_typ = get_lltype_def item_typ in
    let item_sz = sizeof_typ item_typ in

    let mut = false in
    let head_sz =
      sizeof_typ
        (Trecord
           ( [],
             None,
             [|
               { ftyp = Tint; mut };
               { ftyp = Tint; mut };
               { ftyp = Tint; mut };
               { ftyp = item_typ; mut };
             |] ))
      - item_sz
    in
    (llitem_typ, head_sz, item_sz)

  let gen_array_lit param exprs typ allocref =
    let vec_sz = List.length exprs in

    let llitem_typ, head_size, item_size = item_type_head_size typ in
    let cap = head_size + (vec_sz * item_size) in

    let lltyp = get_lltype_def typ in
    let ptr =
      malloc ~size:(Llvm.const_int int_t cap) |> fun ptr ->
      Llvm.build_bitcast ptr lltyp "" builder
    in

    let arr = get_prealloc !allocref param lltyp "arr" in
    ignore (Llvm.build_store ptr arr builder);

    (* Initialize counts *)
    let int_ptr = Llvm.build_bitcast ptr (Llvm.pointer_type int_t) "" builder in
    let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
    (* refcount of 1 *)
    ignore (Llvm.build_store (ci 1) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    ignore (Llvm.build_store (ci vec_sz) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
    ignore (Llvm.build_store (ci vec_sz) dst builder);
    let ptr =
      Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
      Llvm.build_bitcast ptr (Llvm.pointer_type llitem_typ) "" builder
    in

    (* Initialize *)
    List.iteri
      (fun i expr ->
        let dst = Llvm.build_gep ptr [| ci i |] (string_of_int i) builder in
        let src = gen_expr { param with alloca = Some dst } expr in

        match src.kind with
        | Ptr | Const_ptr ->
            if dst <> src.value then
              memcpy ~dst ~src ~size:(Llvm.const_int int_t item_size)
            else (* The record was constructed inplace *) ()
        | Imm | Const -> ignore (Llvm.build_store src.value dst builder))
      exprs;
    { value = arr; typ; lltyp; kind = Ptr }

  let array_get args typ =
    let arr, index =
      match args with
      | [ arr; index ] -> (bring_default_var arr, bring_default index)
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    let lltyp = get_lltype_def typ in
    let int_ptr =
      Llvm.build_bitcast arr.value (Llvm.pointer_type int_t) "" builder
    in
    let ptr =
      Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
      Llvm.build_bitcast ptr (Llvm.pointer_type lltyp) "" builder
    in

    let value = Llvm.build_gep ptr [| index |] "" builder in
    { value; typ; lltyp; kind = Ptr }

  let rec contains_array = function
    | Tarray _ -> true
    | Trecord (_, _, fields) ->
        Array.fold_left (fun b f -> f.ftyp |> contains_array || b) false fields
    | Tvariant (_, _, ctors) ->
        Array.fold_left
          (fun b c ->
            (match c.ctyp with Some t -> contains_array t | None -> false)
            || b)
          false ctors
    | _ -> false

  let rec iter_array fn v =
    match v.typ with
    | Tarray _ -> fn v
    | Trecord (_, _, fields) ->
        Array.iteri
          (fun i f ->
            if contains_array f.ftyp then
              let value = Llvm.build_struct_gep v.value i "" builder in
              let lltyp = get_lltype_def f.ftyp in
              iter_array fn { value; lltyp; kind = Ptr; typ = f.ftyp }
            else ())
          fields
    | Tvariant _ -> (* TODO? *) ()
    | _ -> ()

  let incr_refcount v =
    let f v =
      let v = bring_default v in
      let int_ptr =
        Llvm.build_bitcast v (Llvm.pointer_type int_t) "ref" builder
      in
      let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
      let value = Llvm.build_load dst "ref" builder in
      let added = Llvm.build_add value (Llvm.const_int int_t 1) "" builder in
      ignore (Llvm.build_store added dst builder)
    in
    iter_array f v

  let decr_refcount v =
    let f v =
      let v = bring_default v in
      let int_ptr =
        Llvm.build_bitcast v (Llvm.pointer_type int_t) "ref" builder
      in
      let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
      let value = Llvm.build_load dst "ref" builder in
      let added = Llvm.build_sub value (Llvm.const_int int_t 1) "" builder in
      ignore (Llvm.build_store added dst builder)
    in
    iter_array f v

  let maybe_relocate orig =
    (match orig.kind with
    | Ptr | Const_ptr -> ()
    | _ -> failwith "Internal Error: Not passed as mutable");
    (* Get current block *)
    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let reloc_bb = Llvm.append_block context "relocate" parent in
    let merge_bb = Llvm.append_block context "merge" parent in

    let v = bring_default_var orig in
    let int_ptr =
      Llvm.build_bitcast v.value (Llvm.pointer_type int_t) "ref" builder
    in
    let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
    let rc = Llvm.build_load dst "ref" builder in
    let cmp =
      Llvm.(build_icmp Icmp.Sgt) rc (Llvm.const_int int_t 1) "" builder
    in

    ignore (Llvm.build_cond_br cmp reloc_bb merge_bb builder);

    Llvm.position_at_end reloc_bb builder;
    (* Get new ptr *)
    let sz = Llvm.build_gep int_ptr [| ci 1 |] "sz" builder in
    let sz = Llvm.build_load sz "size" builder in

    let cap = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
    let cap = Llvm.build_load cap "cap" builder in

    let item_type, _, head_size, item_size = item_type_head_size orig.typ in
    let itemscap =
      Llvm.build_mul cap (Llvm.const_int int_t item_size) "" builder
    in
    (* Really capacity, not size *)
    let size =
      Llvm.build_add itemscap (Llvm.const_int int_t head_size) "" builder
    in

    let lltyp = get_lltype_def orig.typ in
    let ptr =
      malloc ~size |> fun ptr -> Llvm.build_bitcast ptr lltyp "" builder
    in
    let itemssize =
      Llvm.build_mul sz (Llvm.const_int int_t item_size) "" builder
    in
    let size =
      Llvm.build_add itemssize (Llvm.const_int int_t head_size) "" builder
    in
    ignore
      (let src = { value = v.value; typ = orig.typ; kind = Ptr; lltyp } in
       memcpy ~src ~dst:ptr ~size);
    (* set orig pointer to new ptr *)
    ignore (Llvm.build_store ptr orig.value builder);

    (* Decrease orig refcount  *)
    decr_refcount v;

    ignore (Llvm.build_br merge_bb builder);

    Llvm.position_at_end merge_bb builder;
    bring_default_var orig

  let array_set args =
    let arr, index, value =
      match args with
      | [ arr; index; value ] ->
          (arr, bring_default index, bring_default_var value)
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in
    let arr = maybe_relocate arr in
    let int_ptr =
      Llvm.build_bitcast arr.value (Llvm.pointer_type int_t) "" builder
    in
    let ptr =
      Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
      Llvm.build_bitcast ptr arr.lltyp "" builder
    in
    let ptr = Llvm.build_gep ptr [| index |] "" builder in

    set_struct_field value ptr;
    { dummy_fn_value with lltyp = unit_t }
end
