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
  type index = Iconst of int | Idyn of Llvm.llvalue

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
    let item_sz, item_align = size_alignof_typ item_typ in

    let mut = false in
    let head_sz =
      sizeof_typ
        (Trecord
           ( [],
             None,
             [|
               { ftyp = Tint; mut }; { ftyp = Tint; mut }; { ftyp = Tint; mut };
             |] ))
    in
    assert (Int.equal head_sz 24);
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
    let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
    (* refcount of 1 *)
    ignore (Llvm.build_store (ci 1) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    ignore (Llvm.build_store (ci vec_sz) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
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

  let rec contains_refcount = function
    | Tarray _ | Tfun _ -> true
    | Trecord (_, _, fields) ->
        Array.fold_left
          (fun b f -> f.ftyp |> contains_refcount || b)
          false fields
    | Tvariant (_, _, ctors) ->
        Array.fold_left
          (fun b c ->
            (match c.ctyp with Some t -> contains_refcount t | None -> false)
            || b)
          false ctors
    | _ -> false

  let rec refcount_types ts = function
    | Tarray t -> t :: ts
    | Trecord (_, _, fields) ->
        Array.fold_left (fun ts f -> refcount_types ts f.ftyp) ts fields
    | Tvariant (_, _, ctors) ->
        Array.fold_left
          (fun ts c ->
            match c.ctyp with Some t -> refcount_types ts t | None -> ts)
          ts ctors
    | _ -> ts

  let rec iter_array fn v =
    match v.typ with
    | Tarray _ | Tfun _ -> fn v
    | Trecord (_, _, fields) ->
        Array.iteri
          (fun i f ->
            if contains_refcount f.ftyp then
              let value = Llvm.build_struct_gep v.value i "" builder in
              let lltyp = get_lltype_def f.ftyp in
              iter_array fn { value; lltyp; kind = Ptr; typ = f.ftyp })
          fields
    | Tvariant (_, _, ctors) ->
        if contains_refcount v.typ then
          (* We check again to guard against getting the tag without needing it *)
          let index = var_index v in
          Array.iteri
            (fun i c ->
              match c.ctyp with
              | None -> ()
              | Some typ ->
                  if contains_refcount typ then (
                    (* Compare to tag *)
                    let start_bb = Llvm.insertion_block builder in
                    let parent = Llvm.block_parent start_bb in

                    let match_bb = Llvm.append_block context "match" parent in
                    let cont_bb = Llvm.append_block context "cont" parent in

                    let cmp =
                      Llvm.(
                        build_icmp Icmp.Eq index.value (const_int i32_t i) "")
                        builder
                    in
                    ignore (Llvm.build_cond_br cmp match_bb cont_bb builder);

                    (* Get data and apply [fn] *)
                    Llvm.position_at_end match_bb builder;
                    let data = var_data v typ in
                    iter_array fn data;
                    ignore (Llvm.build_br cont_bb builder);

                    Llvm.position_at_end cont_bb builder))
            ctors
    | _ -> ()

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

  let make_rc_fn v kind =
    (* TODO use only type *)
    let name = "__" ^ name_of_func kind ^ "_" in
    let name = name ^ Monomorph_tree.short_name ~closure:false v.typ in
    match Hashtbl.find_opt func_tbl name with
    | Some (_, _, f) -> f
    | None ->
        let lltyp =
          match default_kind v.typ with
          | Const_ptr | Ptr -> get_lltype_def v.typ |> Llvm.pointer_type
          | Imm | Const -> get_lltype_def v.typ
        in
        let ft = Llvm.function_type unit_t [| lltyp |] in
        let f = Llvm.declare_function name ft the_module in
        Llvm.set_linkage Llvm.Linkage.Internal f;
        let v = { v with kind = default_kind v.typ } in
        Hashtbl.replace func_tbl name (kind, v, f);
        f

  let rc_fn v kind =
    if contains_refcount v.typ then
      let f = make_rc_fn v kind in
      let v = bring_default_var v |> func_to_closure no_param in

      Llvm.build_call f [| v.value |] "" builder |> ignore

  let incr_refcount v = rc_fn v Incr_rc

  let get_ref_ptr impl var =
    match var.typ with
    | Tarray _ -> impl (bring_default_var var)
    | Tfun _ ->
        let ptr = bring_default var in
        let ptr =
          Llvm.(build_bitcast ptr (pointer_type closure_t)) "" builder
        in
        let value = Llvm.build_struct_gep ptr 1 "" builder in
        let mb_null = Llvm.build_load value "" builder in

        (* Closures can have no env at all -> nullptr *)
        let start_bb = Llvm.insertion_block builder in
        let parent = Llvm.block_parent start_bb in

        let notnull_bb = Llvm.append_block context "nonnull" parent in
        let ret_bb = Llvm.append_block context "ret" parent in
        let nullptr = Llvm.(const_null (type_of mb_null)) in
        let cmp = Llvm.(build_icmp Icmp.Eq mb_null nullptr "") builder in
        ignore (Llvm.build_cond_br cmp ret_bb notnull_bb builder);

        Llvm.position_at_end notnull_bb builder;

        impl { var with value = mb_null };
        ignore (Llvm.build_br ret_bb builder);

        Llvm.position_at_end ret_bb builder
    | _ -> failwith "Internal Error: What kind of ref is this?"

  let incr_rc_impl v =
    let f v =
      let int_ptr =
        Llvm.build_bitcast v.value (Llvm.pointer_type int_t) "ref" builder
      in
      let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
      let value = Llvm.build_load dst "ref" builder in
      let added = Llvm.build_add value (Llvm.const_int int_t 1) "" builder in
      ignore (Llvm.build_store added dst builder)
    in
    iter_array (get_ref_ptr f) v

  let rec decl_decr_children pseudovar t =
    (* The normal free function navigates to array children, but we
       have to make sure the function for each type is available *)
    let ts = refcount_types [] t in
    let f typ =
      (* value will be set correctly at [gen_functions].
         Make sure the other field are correct *)
      if contains_refcount typ then (
        let kind = default_kind typ in
        let lltyp =
          match kind with
          | Const_ptr | Ptr -> get_lltype_def typ |> Llvm.pointer_type
          | Imm | Const -> get_lltype_def typ
        in
        let v = { pseudovar with typ; lltyp; kind } in
        ignore (make_rc_fn v Decr_rc);
        decl_decr_children pseudovar typ)
    in

    List.iter f ts

  let decl_incr_children pseudovar t =
    let ts = refcount_types [] t in
    let f typ =
      (* value will be set correctly at [gen_functions].
         Make sure the other field are correct *)
      if contains_refcount typ then
        let kind = default_kind typ in
        let lltyp =
          match kind with
          | Const_ptr | Ptr -> get_lltype_def typ |> Llvm.pointer_type
          | Imm | Const -> get_lltype_def typ
        in
        let v = { pseudovar with typ; lltyp; kind } in
        ignore (make_rc_fn v Incr_rc)
    in
    List.iter f ts

  let decr_refcount v =
    rc_fn v Decr_rc;
    (* Recursively declare children decr functions for freeing *)
    decl_decr_children v v.typ

  let decr_rc_impl v =
    let f v =
      let int_ptr =
        Llvm.build_bitcast v.value (Llvm.pointer_type int_t) "ref" builder
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
      (match v.typ with
      | Tarray _ ->
          let item_type = item_type v.typ in
          (if contains_refcount item_type then
             let sz = Llvm.build_gep int_ptr [| ci 1 |] "sz" builder in
             let sz = Llvm.build_load sz "size" builder in

             iter_array_children v sz item_type decr_refcount);

          ignore (free_var int_ptr)
      | Tfun _ ->
          (* Call dtor of closure if it exists *)
          let start_bb = Llvm.insertion_block builder in
          let parent = Llvm.block_parent start_bb in

          let dtor_bb = Llvm.append_block context "dtor" parent in
          let rly_free_bb = Llvm.append_block context "rly_free" parent in
          let nullptr = Llvm.(voidptr_t |> const_pointer_null) in
          let dtor_ptr = Llvm.build_gep int_ptr [| ci 1 |] "dtor" builder in
          let dtor_ptr =
            Llvm.build_bitcast dtor_ptr (Llvm.pointer_type voidptr_t) "" builder
          in
          let dtor_ptr = Llvm.build_load dtor_ptr "dtor" builder in

          let cmp = Llvm.(build_icmp Icmp.Eq dtor_ptr nullptr "") builder in
          ignore (Llvm.build_cond_br cmp rly_free_bb dtor_bb builder);

          Llvm.position_at_end dtor_bb builder;
          let dtor =
            Llvm.(build_bitcast dtor_ptr (pointer_type dtor_t)) "dtor" builder
          in
          let arg = [| Llvm.build_bitcast int_ptr voidptr_t "" builder |] in
          ignore (Llvm.build_call dtor arg "" builder);
          ignore (Llvm.build_br rly_free_bb builder);

          Llvm.position_at_end rly_free_bb builder;
          ignore (free_var int_ptr)
      | _ -> failwith "Internal Error: What kind of ref is this?");

      ignore (Llvm.build_br merge_bb builder);

      Llvm.position_at_end merge_bb builder
    in

    iter_array (get_ref_ptr f) v

  let modify_arr_fn kind orig =
    (match orig.kind with
    | Ptr | Const_ptr -> ()
    | _ -> failwith "Internal Error: Not passed as mutable");
    let pmoved = false in
    let poly =
      Tfun
        ( [ { pmut = true; pt = Tarray (Tpoly "0"); pmoved } ],
          Tarray (Tpoly "0"),
          Simple )
    in
    let typ =
      Tfun ([ { pmut = true; pt = orig.typ; pmoved } ], orig.typ, Simple)
    in
    let name =
      Monomorph_tree.get_mono_name (name_of_func kind) ~closure:false ~poly typ
    in
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

  let maybe_relocate orig =
    let call = modify_arr_fn Reloc orig in
    decl_incr_children orig orig.typ;
    call

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
    let itemscap = Llvm.build_mul cap (ci item_size) "" builder in
    (* Really capacity, not size *)
    let size = Llvm.build_add itemscap (ci head_size) "" builder in

    let lltyp = get_lltype_def orig.typ in
    let ptr =
      malloc ~size |> fun ptr -> Llvm.build_bitcast ptr lltyp "" builder
    in
    let itemssize = Llvm.build_mul sz (ci item_size) "" builder in
    let size = Llvm.build_add itemssize (ci head_size) "" builder in
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
    if contains_refcount item_type then
      iter_array_children v sz item_type incr_refcount;

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
    let value = data_get arr.value arr.typ (Idyn index) in
    { value; typ; lltyp; kind = Ptr }

  let array_set args =
    let arr, index, value =
      match args with
      | [ arr; index; value ] ->
          (arr, bring_default index, bring_default_var value)
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in
    let arr = maybe_relocate arr in
    let ptr = data_get arr.value arr.typ (Idyn index) in
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

    { value; typ = Tint; lltyp = int_t; kind = Ptr }

  let grow orig =
    let call = modify_arr_fn Grow orig in
    decl_incr_children orig orig.typ;
    call

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
    let itemscap = Llvm.build_mul new_cap (ci item_size) "" builder in
    let size = Llvm.build_add itemscap (ci head_size) "" builder in

    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let realloc_bb = Llvm.append_block context "realloc" parent in
    let malloc_bb = Llvm.append_block context "malloc" parent in
    let merge_bb = Llvm.append_block context "merge" parent in

    let cmp = Llvm.(build_icmp Icmp.Eq) rc (ci 1) "" builder in

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
    let itemssize = Llvm.build_mul sz (ci item_size) "" builder in
    let size = Llvm.build_add itemssize (ci head_size) "" builder in
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
    if contains_refcount item_type then
      iter_array_children v sz item_type incr_refcount;
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
    let arrtyp = arr.typ in
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
    let ptr = data_get arr arrtyp (Idyn sz) in

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
    let ptr = data_get arr.value arr.typ (Idyn index) in

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
    let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
    (* refcount of 1 *)
    ignore (Llvm.build_store (ci 1) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    ignore (Llvm.build_store sz dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
    ignore (Llvm.build_store sz dst builder);

    { value = arr; typ; lltyp; kind = Ptr }

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
