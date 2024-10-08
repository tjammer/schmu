module type Core = sig
  open Llvm_types

  val gen_expr : param -> Monomorph_tree.monod_tree -> llvar
  val gen_constexpr : param -> Monomorph_tree.monod_tree -> llvar
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
        (Trecord
           ([], Rec_not [| { ftyp = Tint; mut }; { ftyp = Tint; mut } |], None))
    in
    assert (Int.equal head_sz 16);
    let head_sz = alignup ~size:head_sz ~upto:item_align in

    (item_typ, llitem_typ, head_sz, item_sz)

  let data_ptr ptr arrtyp =
    let _, _, head_size, _ = item_type_head_size arrtyp in
    Llvm.build_gep u8_t ptr [| ci head_size |] "" builder

  let data_get ptr arrtyp index =
    let item_typ, llitem_typ, _, _ = item_type_head_size arrtyp in
    match item_typ with
    | Tunit -> dummy_fn_value.value
    | _ ->
        let ptr = data_ptr ptr arrtyp in
        let idx = match index with Iconst i -> ci i | Idyn i -> i in
        Llvm.build_gep llitem_typ ptr [| idx |] "" builder

  let gen_array_lit param exprs typ allocref =
    let vec_sz = List.length exprs in

    let item_typ, item_lltyp, head_size, item_size = item_type_head_size typ in
    let cap_sz = Int.max 1 vec_sz in
    let cap = head_size + (cap_sz * item_size) in

    let lltyp = get_lltype_def typ in
    let ptr = malloc ~size:(Llvm.const_int int_t cap) in

    let arr = get_prealloc !allocref param lltyp "arr" in
    ignore (Llvm.build_store ptr arr builder);

    (* Initialize counts *)
    let dst = Llvm.build_gep int_t ptr [| ci 0 |] "size" builder in
    ignore (Llvm.build_store (ci vec_sz) dst builder);
    let dst = Llvm.build_gep int_t ptr [| ci 1 |] "cap" builder in
    ignore (Llvm.build_store (ci cap_sz) dst builder);
    let ptr = data_ptr ptr typ in

    (* Initialize *)
    (match item_typ with
    | Tunit ->
        (* Generate expressions for side effects *)
        List.iter (fun expr -> gen_expr param expr |> ignore) exprs
    | _ ->
        List.iteri
          (fun i expr ->
            let dst =
              Llvm.build_gep item_lltyp ptr [| ci i |] (string_of_int i) builder
            in
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
          exprs);
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
    let cnt_loaded = Llvm.build_load int_t cnt "" builder in
    let cmp = Llvm.(build_icmp Icmp.Slt) cnt_loaded size "" builder in
    ignore (Llvm.build_cond_br cmp child_bb cont_bb builder);

    Llvm.position_at_end child_bb builder;
    (* The ptr has the correct type, no need to multiply size *)
    let value = data_get arr.value arr.typ (Idyn cnt_loaded) in
    let lltyp = get_lltype_def typ in
    let temp = { value; typ; lltyp; kind = Ptr } in
    f temp;

    let next = Llvm.build_add cnt_loaded (ci 1) "" builder in
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
    let value = Llvm.build_gep int_t arr.value [| ci 0 |] "len" builder in
    let value, kind =
      if unsafe then (value, Ptr)
      else (Llvm.build_load int_t value "" builder, Imm)
    in

    { value; typ = Tint; lltyp = int_t; kind }

  let array_capacity args =
    let arr =
      match args with
      | [ arr ] -> arr
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in
    let arr = bring_default_var arr in
    let value = Llvm.build_gep int_t arr.value [| ci 1 |] "capacity" builder in
    let value = Llvm.build_load int_t value "" builder in
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

    let new_dst = Llvm.build_gep int_t ptr [| ci 1 |] "newcap" builder in
    ignore (Llvm.build_store new_cap new_dst builder);

    { dummy_fn_value with lltyp = unit_t }

  let unsafe_array_pop_back param args allocref =
    (* We assume there is at least one item, and don't actually check the size.
       But we do decrease the size of the array by one. *)
    let arr =
      match args with
      | [ arr ] -> arr
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in
    let arr = bring_default_var arr in

    let dst = Llvm.build_gep int_t arr.value [| ci 0 |] "size" builder in
    let sz = Llvm.build_load int_t dst "size" builder in

    let index = Llvm.build_sub sz (ci 1) "" builder in
    ignore (Llvm.build_store index dst builder);

    let ptr = data_get arr.value arr.typ (Idyn index) in

    let item_typ = item_type arr.typ in
    let llitem_typ = get_lltype_def item_typ in

    let v = { value = ptr; kind = Ptr; lltyp = llitem_typ; typ = item_typ } in
    let src = bring_default_var v in

    let dst = get_prealloc !allocref param llitem_typ "" in

    store_or_copy ~src ~dst;
    { v with value = dst; kind = Ptr }

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
    let dst = Llvm.build_gep int_t ptr [| ci 0 |] "size" builder in
    ignore (Llvm.build_store sz dst builder);
    let dst = Llvm.build_gep int_t ptr [| ci 1 |] "cap" builder in
    ignore (Llvm.build_store sz dst builder);

    { value = arr; typ; lltyp; kind = Ptr }

  let gen_fixed_array_lit param exprs typ allocref const return =
    let lltyp = get_lltype_def typ in

    let value, kind =
      match typ with
      | Tfixed_array (_, Tunit) ->
          (* Generate the expressions for side effects *)
          List.iter (fun expr -> gen_expr param expr |> ignore) exprs;
          let v = dummy_fn_value in
          (v.value, v.kind)
      | Tfixed_array (_, t) -> (
          let item_size = sizeof_typ t in
          let item_lltyp =
            match typ with
            | Tfixed_array (_, t) -> get_lltype_def t
            | _ -> failwith "unreachable"
          in
          match const with
          | Monomorph_tree.Cnot ->
              let arr = get_prealloc !allocref param lltyp "arr" in
              let arrptr = Llvm.build_gep ptr_t arr [| ci 0 |] "" builder in

              List.iteri
                (fun i expr ->
                  let dst =
                    Llvm.build_gep item_lltyp arrptr [| ci i |] "" builder
                  in
                  let src =
                    gen_expr { param with alloca = Some dst } expr
                    |> func_to_closure param
                  in

                  match src.kind with
                  | Ptr | Const_ptr ->
                      if dst <> src.value then
                        memcpy ~dst ~src ~size:(Llvm.const_int int_t item_size)
                      else (* The record was constructed inplace *) ()
                  | Imm | Const ->
                      ignore (Llvm.build_store src.value dst builder))
                exprs;
              (arr, Ptr)
          | Const ->
              let values =
                List.map (fun expr -> (gen_constexpr param expr).value) exprs
                |> Array.of_list
              in
              let value = Llvm.(const_array item_lltyp values) in
              (* The value might be returned, thus boxed, so we wrap it in an automatic var *)
              if return then (
                let record = get_prealloc !allocref param item_lltyp "" in
                ignore (Llvm.build_store value record builder);
                (record, Const_ptr))
              else (value, Const))
      | _ -> failwith "Internal Error: Not a fixed array"
    in

    { value; typ; lltyp; kind }

  let iter_fixed_array_children arr size child_typ f =
    let arr = bring_default arr in
    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    (* Simply loop over array *)
    let cnt = Llvm.build_alloca int_t "cnt" builder in
    ignore (Llvm.build_store (Llvm.const_int int_t 0) cnt builder);

    let rec_bb = Llvm.append_block context "rec" parent in
    let child_bb = Llvm.append_block context "child" parent in
    let cont_bb = Llvm.append_block context "cont" parent in

    ignore (Llvm.build_br rec_bb builder);
    Llvm.position_at_end rec_bb builder;

    (* Check if we are done *)
    let cnt_loaded = Llvm.build_load int_t cnt "" builder in
    let cmp = Llvm.(build_icmp Icmp.Slt) cnt_loaded (ci size) "" builder in
    ignore (Llvm.build_cond_br cmp child_bb cont_bb builder);

    Llvm.position_at_end child_bb builder;
    (* The ptr has the correct type, no need to multiply size *)
    let lltyp = get_lltype_def child_typ in
    let arrptr = Llvm.build_gep ptr_t arr [| ci 0 |] "" builder in
    let value = Llvm.build_gep lltyp arrptr [| cnt_loaded |] "" builder in
    let temp = { value; typ = child_typ; lltyp; kind = Ptr } in
    f temp;

    let next = Llvm.build_add cnt_loaded (ci 1) "" builder in
    ignore (Llvm.build_store next cnt builder);
    ignore (Llvm.build_br rec_bb builder);

    Llvm.position_at_end cont_bb builder
end
