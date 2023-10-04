module type Core = sig
  open Llvm_types

  val gen_expr : param -> Monomorph_tree.monod_tree -> llvar
end

module Make
    (T : Lltypes_intf.S)
    (H : Helpers.S)
    (C : Core)
    (Auto : Autogen_intf.S) =
struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open T
  open H
  open C

  type index = Iconst of int | Idyn of Llvm.llvalue

  let ci i = Llvm.const_int int_t i

  let item_type = function
    | Tarray t -> t
    | t ->
        print_endline (show_typ t);
        failwith "Internal Error: No array in array"

  let item_type_head_size typ =
    (* Return pair lltyp, size of head *)
    let item_typ = item_type typ in
    let llitem_typ = get_lltype_def item_typ in
    let item_sz, item_align = size_alignof_typ item_typ in

    let mut = false in
    let head_sz =
      sizeof_typ
        (Trecord ([], None, [| { ftyp = Tint; mut }; { ftyp = Tint; mut } |]))
    in
    assert (Int.equal head_sz 16);
    let head_sz = alignup ~size:head_sz ~upto:item_align in

    (item_typ, llitem_typ, head_sz, item_sz)

  let data_ptr ptr arrtyp =
    let _, llitem_typ, head_size, _ = item_type_head_size arrtyp in
    Llvm.build_bitcast ptr (Llvm.pointer_type u8_t) "" builder |> fun ptr ->
    Llvm.build_gep ptr [| ci head_size |] "" builder |> fun ptr ->
    Llvm.build_bitcast ptr (Llvm.pointer_type llitem_typ) "data" builder

  let data_get ptr arrtyp index =
    let _, llitem_typ, head_size, item_sz = item_type_head_size arrtyp in
    let ptr = Llvm.build_bitcast ptr (Llvm.pointer_type u8_t) "" builder in
    let idx =
      match index with
      | Iconst i -> (i * item_sz) + head_size |> ci
      | Idyn i ->
          let items = Llvm.build_mul (ci item_sz) i "" builder in
          Llvm.build_add (ci head_size) items "" builder
    in
    let data = Llvm.build_gep ptr [| idx |] "" builder in
    Llvm.build_bitcast data (Llvm.pointer_type llitem_typ) "data" builder

  let gen_array_lit param exprs typ allocref =
    let vec_sz = List.length exprs in

    let _, _, head_size, item_size = item_type_head_size typ in
    let cap_sz = Int.max 1 vec_sz in
    let cap = head_size + (cap_sz * item_size) in

    let lltyp = get_lltype_def typ in
    let ptr =
      malloc ~size:(Llvm.const_int int_t cap) |> fun ptr ->
      Llvm.build_bitcast ptr lltyp "" builder
    in

    let arr = get_prealloc !allocref param lltyp "arr" in
    ignore (Llvm.build_store ptr arr builder);

    (* Initialize counts *)
    let int_ptr = Llvm.build_bitcast ptr (Llvm.pointer_type int_t) "" builder in
    let dst = Llvm.build_gep int_ptr [| ci 0 |] "size" builder in
    ignore (Llvm.build_store (ci vec_sz) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 1 |] "cap" builder in
    ignore (Llvm.build_store (ci cap_sz) dst builder);
    let ptr = data_ptr ptr typ in

    (* Initialize *)
    List.iteri
      (fun i expr ->
        let dst = Llvm.build_gep ptr [| ci i |] (string_of_int i) builder in
        let src =
          gen_expr { param with alloca = Some dst } expr
          |> func_to_closure param
        in

        match src.kind with
        | Ptr | Const_ptr ->
            if dst <> src.value then
              memcpy ~dst ~src ~size:(Llvm.const_int int_t item_size)
            else (* The record was constructed inplace *) ()
        | Imm | Const -> ignore (Llvm.build_store src.value dst builder))
      exprs;
    { value = arr; typ; lltyp; kind = Ptr }

  let iter_array_children arr size typ f =
    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    (* Simple loop, start at 0 *)
    let cnt = Llvm.build_alloca int_t "cnt" builder in
    ignore (Llvm.build_store (Llvm.const_int int_t 0) cnt builder);

    let rec_bb = Llvm.append_block context "rec" parent in
    let child_bb = Llvm.append_block context "child" parent in
    let cont_bb = Llvm.append_block context "cont" parent in

    ignore (Llvm.build_br rec_bb builder);
    Llvm.position_at_end rec_bb builder;

    (* Check if we are done *)
    let cnt_loaded = Llvm.build_load cnt "" builder in
    let cmp = Llvm.(build_icmp Icmp.Slt) cnt_loaded size "" builder in
    ignore (Llvm.build_cond_br cmp child_bb cont_bb builder);

    Llvm.position_at_end child_bb builder;
    (* The ptr has the correct type, no need to multiply size *)
    let value = data_get arr.value arr.typ (Idyn cnt_loaded) in
    let lltyp = get_lltype_def typ in
    let temp = { value; typ; lltyp; kind = Ptr } in
    f temp;

    let one = Llvm.const_int int_t 1 in
    let next = Llvm.build_add cnt_loaded one "" builder in
    ignore (Llvm.build_store next cnt builder);
    ignore (Llvm.build_br rec_bb builder);

    Llvm.position_at_end cont_bb builder

  let array_get args typ =
    let arr, index =
      match args with
      | [ arr; index ] -> (arr, bring_default index)
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    (* If we are being set, it's similar to array_set *)
    let arr = bring_default_var arr in

    let lltyp = get_lltype_def typ in
    let value = data_get arr.value arr.typ (Idyn index) in
    { value; typ; lltyp; kind = Ptr }

  let array_length ~unsafe args =
    let arr =
      match args with
      | [ arr ] -> arr
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in
    let arr = bring_default_var arr in
    let int_ptr =
      Llvm.build_bitcast arr.value (Llvm.pointer_type int_t) "" builder
    in
    let value = Llvm.build_gep int_ptr [| ci 0 |] "len" builder in
    let value, kind =
      if unsafe then (value, Ptr) else (Llvm.build_load value "" builder, Imm)
    in

    { value; typ = Tint; lltyp = int_t; kind }

  let array_capacity args =
    let arr =
      match args with
      | [ arr ] -> arr
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in
    let arr = bring_default_var arr in
    let int_ptr =
      Llvm.build_bitcast arr.value (Llvm.pointer_type int_t) "" builder
    in
    let value = Llvm.build_gep int_ptr [| ci 1 |] "capacity" builder in
    let value = Llvm.build_load value "" builder in
    { value; typ = Tint; lltyp = int_t; kind = Imm }

  let array_realloc args =
    let orig, new_cap =
      match args with
      | [ arr; value ] -> (arr, bring_default value)
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    let _, _, head_size, item_size = item_type_head_size orig.typ in
    let itemscap = Llvm.build_mul new_cap (ci item_size) "" builder in
    let size = Llvm.build_add itemscap (ci head_size) "" builder in

    let ptr = realloc (bring_default orig) ~size in
    ignore (Llvm.build_store ptr orig.value builder);

    let new_int_ptr =
      Llvm.build_bitcast ptr (Llvm.pointer_type int_t) "newcap" builder
    in
    let new_dst = Llvm.build_gep new_int_ptr [| ci 1 |] "newcap" builder in
    ignore (Llvm.build_store new_cap new_dst builder);

    { dummy_fn_value with lltyp = unit_t }

  let array_drop_back param args =
    let arr =
      match args with
      | [ arr ] -> arr
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in
    let arr = bring_default_var arr in
    let int_ptr =
      Llvm.build_bitcast arr.value (Llvm.pointer_type int_t) "" builder
    in

    let dst = Llvm.build_gep int_ptr [| ci 0 |] "size" builder in
    let sz = Llvm.build_load dst "size" builder in

    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let drop_last_bb = Llvm.append_block context "drop_last" parent in
    let cont_bb = Llvm.append_block context "cont" parent in

    let cmp = Llvm.(build_icmp Icmp.Sgt) sz (ci 0) "" builder in
    ignore (Llvm.build_cond_br cmp drop_last_bb cont_bb builder);

    Llvm.position_at_end drop_last_bb builder;
    let index = Llvm.build_sub sz (ci 1) "" builder in
    let ptr = data_get arr.value arr.typ (Idyn index) in

    let item_typ = item_type arr.typ in
    let llitem_typ = get_lltype_def item_typ in

    Auto.free param
      { value = ptr; kind = Ptr; typ = item_typ; lltyp = llitem_typ };

    ignore (Llvm.build_store index dst builder);
    ignore (Llvm.build_br cont_bb builder);

    Llvm.position_at_end cont_bb builder;

    { dummy_fn_value with lltyp = unit_t }

  let array_data args =
    let arr =
      match args with
      | [ arr ] -> bring_default_var arr
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    let itemtyp = item_type arr.typ in
    let valueptr = data_get arr.value arr.typ (Iconst 0) in
    let typ = Traw_ptr itemtyp in
    let lltyp = get_lltype_def typ in
    let v = { value = valueptr; typ; lltyp; kind = Imm } in
    v

  let unsafe_array_create param args typ allocref =
    let sz =
      match args with
      | [ sz ] -> bring_default sz
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    (* array initialization code is copied from [gen_array_lit] a bit *)
    let _, _, head_size, item_size = item_type_head_size typ in
    (* [sz] passed here could be anything. It's unsafe alright *)
    let itemscap = Llvm.build_mul sz (ci item_size) "" builder in
    let size = Llvm.build_add (ci head_size) itemscap "" builder in

    let lltyp = get_lltype_def typ in
    let ptr =
      malloc ~size |> fun ptr -> Llvm.build_bitcast ptr lltyp "" builder
    in

    let arr = get_prealloc !allocref param lltyp "arr" in
    ignore (Llvm.build_store ptr arr builder);

    (* Initialize counts *)
    let int_ptr = Llvm.build_bitcast ptr (Llvm.pointer_type int_t) "" builder in
    let dst = Llvm.build_gep int_ptr [| ci 0 |] "size" builder in
    ignore (Llvm.build_store sz dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 1 |] "cap" builder in
    ignore (Llvm.build_store sz dst builder);

    { value = arr; typ; lltyp; kind = Ptr }
end
