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

  type func = Incr_rc | Decr_rc | Reloc | Grow

  let name_of_func = function
    | Incr_rc -> "incr_rc"
    | Decr_rc -> "decr_rc"
    | Reloc -> "reloc"
    | Grow -> "grow"

  let func_tbl = Hashtbl.create 64
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
    (item_typ, llitem_typ, head_sz, item_sz)

  let gen_array_lit param exprs typ allocref =
    let vec_sz = List.length exprs in

    let _, llitem_typ, head_size, item_size = item_type_head_size typ in
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
    let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
    (* refcount of 1 *)
    ignore (Llvm.build_store (ci 1) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    ignore (Llvm.build_store (ci vec_sz) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
    ignore (Llvm.build_store (ci cap_sz) dst builder);
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

  let iter_array_children data size typ f =
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
    let value = Llvm.build_gep data [| cnt_loaded |] "" builder in
    let lltyp = get_lltype_def typ in
    let temp = { value; typ; lltyp; kind = Ptr } in
    f temp;

    let one = Llvm.const_int int_t 1 in
    let next = Llvm.build_add cnt_loaded one "" builder in
    ignore (Llvm.build_store next cnt builder);
    ignore (Llvm.build_br rec_bb builder);

    Llvm.position_at_end cont_bb builder

  let make_rc_fn v kind =
    let name = name_of_func kind in
    let poly = Tfun ([ { pmut = false; pt = Tpoly "0" } ], Tunit, Simple) in
    let typ = Tfun ([ { pmut = false; pt = v.typ } ], Tunit, Simple) in
    let name = Monomorph_tree.get_mono_name name ~poly typ in
    match Hashtbl.find_opt func_tbl name with
    | Some (_, _, f) -> f
    | None ->
        let ps =
          match default_kind v.typ with
          | Const_ptr | Ptr -> get_lltype_def v.typ |> Llvm.pointer_type
          | Imm | Const -> get_lltype_def v.typ
        in
        let ft = Llvm.function_type unit_t [| ps |] in
        let f = Llvm.declare_function name ft the_module in
        Llvm.set_linkage Llvm.Linkage.Internal f;
        let v = bring_default_var v in
        Hashtbl.replace func_tbl name (kind, v, f);
        f

  let rc_fn v kind =
    if contains_array v.typ then
      let f = make_rc_fn v kind in
      let v =
        match v.kind with
        | Ptr | Const_ptr -> bring_default v
        | Imm | Const -> v.value
      in

      ignore (Llvm.build_call f [| v |] "" builder)

  let incr_refcount v = rc_fn v Incr_rc

  let incr_rc_impl v =
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

  let decr_refcount v = rc_fn v Decr_rc

  let decr_rc_impl v =
    let f var =
      (* Load ref *)
      let v = bring_default var in
      let int_ptr =
        Llvm.build_bitcast v (Llvm.pointer_type int_t) "ref" builder
      in
      let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
      let rc = Llvm.build_load dst "ref" builder in

      (* Get current block *)
      let start_bb = Llvm.insertion_block builder in
      let parent = Llvm.block_parent start_bb in

      let decr_bb = Llvm.append_block context "decr" parent in
      let free_bb = Llvm.append_block context "free" parent in
      let merge_bb = Llvm.append_block context "merge" parent in

      let cmp =
        Llvm.(build_icmp Icmp.Eq) rc (Llvm.const_int int_t 1) "" builder
      in
      ignore (Llvm.build_cond_br cmp free_bb decr_bb builder);

      (* decr *)
      Llvm.position_at_end decr_bb builder;
      let added = Llvm.build_sub rc (Llvm.const_int int_t 1) "" builder in
      ignore (Llvm.build_store added dst builder);
      ignore (Llvm.build_br merge_bb builder);

      (* free *)
      Llvm.position_at_end free_bb builder;
      let item_type = item_type var.typ in
      (if contains_array item_type then
       let sz = Llvm.build_gep int_ptr [| ci 1 |] "sz" builder in
       let sz = Llvm.build_load sz "size" builder in

       let data =
         Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
         Llvm.build_bitcast ptr
           (get_lltype_def item_type |> Llvm.pointer_type)
           "data" builder
       in
       iter_array_children data sz item_type decr_refcount);

      ignore (free int_ptr);
      ignore (Llvm.build_br merge_bb builder);

      Llvm.position_at_end merge_bb builder
    in

    iter_array f v

  let modify_arr_fn kind orig =
    (match orig.kind with
    | Ptr | Const_ptr -> ()
    | _ -> failwith "Internal Error: Not passed as mutable");
    let poly =
      Tfun
        ( [ { pmut = true; pt = Tarray (Tpoly "0") } ],
          Tarray (Tpoly "0"),
          Simple )
    in
    let typ = Tfun ([ { pmut = true; pt = orig.typ } ], orig.typ, Simple) in
    let name = Monomorph_tree.get_mono_name (name_of_func kind) ~poly typ in
    let f =
      match Hashtbl.find_opt func_tbl name with
      | Some (_, _, f) -> f
      | None ->
          let ret = get_lltype_def orig.typ in
          let ps = ret |> Llvm.pointer_type in
          let ft = Llvm.function_type ret [| ps |] in
          let f = Llvm.declare_function name ft the_module in
          Llvm.set_linkage Llvm.Linkage.Internal f;
          Hashtbl.replace func_tbl name (kind, orig, f);
          f
    in
    (* We need to decrease inside relocate impl *)
    let tmp = { orig with kind = Imm } in
    ignore (make_rc_fn tmp Decr_rc);
    let value = Llvm.build_call f [| orig.value |] "" builder in
    (* For some reason, we default? *)
    { orig with value; kind = Imm }

  let maybe_relocate orig = modify_arr_fn Reloc orig

  let relocate_impl orig =
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
      (* Ptr is needed here to get a copy *)
      (let src = { value = v.value; typ = orig.typ; kind = Ptr; lltyp } in
       memcpy ~src ~dst:ptr ~size);
    (* set orig pointer to new ptr *)
    ignore (Llvm.build_store ptr orig.value builder);

    (* We copied orig including refcount. Reset to 1 *)
    let new_int_ptr =
      Llvm.build_bitcast ptr (Llvm.pointer_type int_t) "ref" builder
    in
    let new_dst = Llvm.build_gep new_int_ptr [| ci 0 |] "ref" builder in
    ignore (Llvm.build_store (ci 1) new_dst builder);

    (* Decrease orig refcount  *)
    decr_refcount v;

    (* Increase member refcount *)
    (if contains_array item_type then
     let data =
       Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
       Llvm.build_bitcast ptr
         (get_lltype_def item_type |> Llvm.pointer_type)
         "data" builder
     in
     iter_array_children data sz item_type incr_refcount);

    ignore (Llvm.build_br merge_bb builder);

    Llvm.position_at_end merge_bb builder;
    bring_default_var orig

  let array_get ~in_set args typ =
    let arr, index =
      match args with
      | [ arr; index ] -> (arr, bring_default index)
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    (* If we are being set, it's similar to array_set *)
    let arr = if in_set then maybe_relocate arr else bring_default_var arr in

    let lltyp = get_lltype_def typ in
    let int_ptr =
      Llvm.build_bitcast arr.value (Llvm.pointer_type int_t) "" builder
    in
    let ptr =
      Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
      Llvm.build_bitcast ptr (Llvm.pointer_type lltyp) "" builder
    in

    let value = Llvm.build_gep ptr [| index |] "" builder in
    let v = { value; typ; lltyp; kind = Ptr } in
    if not in_set then incr_refcount v;
    v

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
    decr_refcount { value with value = ptr; kind = Ptr };

    set_struct_field value ptr;
    { dummy_fn_value with lltyp = unit_t }

  let array_length args =
    let arr =
      match args with
      | [ arr ] -> arr
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in
    let arr = bring_default_var arr in
    let int_ptr =
      Llvm.build_bitcast arr.value (Llvm.pointer_type int_t) "" builder
    in
    let value = Llvm.build_gep int_ptr [| ci 1 |] "len" builder in
    let value = Llvm.build_load value "" builder in

    { value; typ = Tint; lltyp = int_t; kind = Imm }

  let grow orig = modify_arr_fn Grow orig

  let grow_impl orig =
    let v = bring_default_var orig in
    let int_ptr =
      Llvm.build_bitcast v.value (Llvm.pointer_type int_t) "" builder
    in
    let dst = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
    let old_cap = Llvm.build_load dst "cap" builder in
    let new_cap = Llvm.build_mul old_cap (ci 2) "" builder in

    let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
    let rc = Llvm.build_load dst "ref" builder in

    let item_type, _, head_size, item_size = item_type_head_size orig.typ in
    let itemscap =
      Llvm.build_mul new_cap (Llvm.const_int int_t item_size) "" builder
    in
    let size =
      Llvm.build_add itemscap (Llvm.const_int int_t head_size) "" builder
    in

    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let realloc_bb = Llvm.append_block context "realloc" parent in
    let malloc_bb = Llvm.append_block context "malloc" parent in
    let merge_bb = Llvm.append_block context "merge" parent in

    let cmp =
      Llvm.(build_icmp Icmp.Eq) rc (Llvm.const_int int_t 1) "" builder
    in

    ignore (Llvm.build_cond_br cmp realloc_bb malloc_bb builder);

    (* Realloc *)
    Llvm.position_at_end realloc_bb builder;

    let rptr = realloc (bring_default orig) ~size in
    ignore (Llvm.build_store rptr orig.value builder);
    ignore (Llvm.build_br merge_bb builder);
    let realloc_bb = Llvm.insertion_block builder in

    (* malloc *)
    Llvm.position_at_end malloc_bb builder;

    let lltyp = get_lltype_def orig.typ in
    let ptr =
      malloc ~size |> fun ptr -> Llvm.build_bitcast ptr lltyp "" builder
    in

    let dst = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    let sz = Llvm.build_load dst "size" builder in
    let itemssize =
      Llvm.build_mul sz (Llvm.const_int int_t item_size) "" builder
    in
    let size =
      Llvm.build_add itemssize (Llvm.const_int int_t head_size) "" builder
    in
    ignore
      (* Ptr is needed here to get a copy *)
      (let src = { value = v.value; typ = orig.typ; kind = Ptr; lltyp } in
       memcpy ~src ~dst:ptr ~size);
    (* set orig pointer to new ptr *)
    ignore (Llvm.build_store ptr orig.value builder);

    (* We copied orig including refcount. Reset to 1 *)
    let new_int_ptr =
      Llvm.build_bitcast ptr (Llvm.pointer_type int_t) "ref" builder
    in
    let new_dst = Llvm.build_gep new_int_ptr [| ci 0 |] "ref" builder in
    ignore (Llvm.build_store (ci 1) new_dst builder);

    (* Decrease orig refcount  *)
    decr_refcount v;

    (* Increase member refcount *)
    (if contains_array item_type then
     let data =
       Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
       Llvm.build_bitcast ptr
         (get_lltype_def item_type |> Llvm.pointer_type)
         "data" builder
     in
     iter_array_children data sz item_type incr_refcount);
    let malloc_bb = Llvm.insertion_block builder in

    ignore (Llvm.build_br merge_bb builder);

    (* Merge *)
    Llvm.position_at_end merge_bb builder;

    let ptr =
      Llvm.build_phi [ (rptr, realloc_bb); (ptr, malloc_bb) ] "" builder
    in
    let new_int_ptr =
      Llvm.build_bitcast ptr (Llvm.pointer_type int_t) "newcap" builder
    in
    let new_dst = Llvm.build_gep new_int_ptr [| ci 2 |] "newcap" builder in
    ignore (Llvm.build_store new_cap new_dst builder);
    bring_default_var orig

  let array_push args =
    let arr, value =
      match args with
      | [ arr; value ] -> (arr, bring_default_var value)
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    let v = bring_default arr in
    let int_ptr = Llvm.build_bitcast v (Llvm.pointer_type int_t) "" builder in
    let dst = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    let sz = Llvm.build_load dst "size" builder in
    let dst = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
    let cap = Llvm.build_load dst "cap" builder in

    (* Get current block *)
    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let keep_bb = Llvm.append_block context "keep" parent in
    let grow_bb = Llvm.append_block context "grow" parent in
    let merge_bb = Llvm.append_block context "merge" parent in

    let cmp = Llvm.(build_icmp Icmp.Eq) cap sz "" builder in
    ignore (Llvm.build_cond_br cmp grow_bb keep_bb builder);

    (* There is enough capacity *)
    Llvm.position_at_end keep_bb builder;
    let keep_arr = maybe_relocate arr in
    ignore (Llvm.build_br merge_bb builder);

    (* Not enough capacity, grow the array *)
    Llvm.position_at_end grow_bb builder;
    let grow_arr = grow arr in
    ignore (Llvm.build_br merge_bb builder);

    (* Merge *)
    Llvm.position_at_end merge_bb builder;
    let arr =
      Llvm.build_phi
        [ (keep_arr.value, keep_bb); (grow_arr.value, grow_bb) ]
        "" builder
    in
    let int_ptr = Llvm.build_bitcast arr (Llvm.pointer_type int_t) "" builder in
    let ptr =
      Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
      Llvm.build_bitcast ptr grow_arr.lltyp "" builder
    in
    let ptr = Llvm.build_gep ptr [| sz |] "" builder in

    set_struct_field value ptr;

    let szptr = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    let new_sz = Llvm.build_add sz (ci 1) "" builder in
    ignore (Llvm.build_store new_sz szptr builder);

    { dummy_fn_value with lltyp = unit_t }

  let array_drop_back args =
    let arr =
      match args with
      | [ arr ] -> arr
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

    let dst = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    let sz = Llvm.build_load dst "size" builder in

    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let drop_last_bb = Llvm.append_block context "drop_last" parent in
    let cont_bb = Llvm.append_block context "cont" parent in

    let cmp = Llvm.(build_icmp Icmp.Sgt) sz (ci 0) "" builder in
    ignore (Llvm.build_cond_br cmp drop_last_bb cont_bb builder);

    Llvm.position_at_end drop_last_bb builder;
    let index = Llvm.build_sub sz (ci 1) "" builder in
    let ptr = Llvm.build_gep ptr [| index |] "" builder in

    let item_typ = item_type arr.typ in
    let llitem_typ = get_lltype_def item_typ in

    decr_refcount
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
    let lltyp = get_lltype_def itemtyp in
    let int_ptr =
      Llvm.build_bitcast arr.value (Llvm.pointer_type int_t) "" builder
    in
    let ptr =
      Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
      Llvm.build_bitcast ptr (Llvm.pointer_type lltyp) "" builder
    in

    let valueptr = Llvm.build_gep ptr [| ci 0 |] "" builder in
    let typ = Traw_ptr itemtyp in
    let lltyp = get_lltype_def typ in
    let v = { value = valueptr; typ; lltyp; kind = Imm } in
    v

  let gen_functions () =
    Hashtbl.iter
      (fun _ (kind, v, ft) ->
        let bb = Llvm.append_block context "entry" ft in
        Llvm.position_at_end bb builder;

        let value = Llvm.param ft 0 in
        (* We saved typ and kind *)
        let v = { v with value } in
        match kind with
        | Incr_rc ->
            incr_rc_impl v;
            ignore (Llvm.build_ret_void builder)
        | Decr_rc ->
            decr_rc_impl v;
            ignore (Llvm.build_ret_void builder)
        | Reloc ->
            let v = relocate_impl v in
            ignore (Llvm.build_ret v.value builder)
        | Grow ->
            let v = grow_impl v in
            ignore (Llvm.build_ret v.value builder))
      func_tbl
end
