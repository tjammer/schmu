module Make (T : Lltypes_intf.S) (H : Helpers.S) (Arr : Arr_intf.S) (Rc : Rc.S) =
struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open T
  open H
  open Arr
  open Malloc_types

  type func = Copy | Free | Free_except of Pset.t

  let func_tbl = Hashtbl.create 64
  let cls_func_tbl = Hashtbl.create 64
  let ci i = Llvm.const_int int_t i

  let alloc_types ts = function
    | Tarray t -> t :: ts
    | Trc (_, t) -> t :: ts
    | Trecord (_, Rec_folded, _) -> ts
    | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
        Array.fold_left
          (fun ts f -> if contains_allocation f.ftyp then f.ftyp :: ts else ts)
          ts fields
    | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) ->
        Array.fold_left
          (fun ts c ->
            match c.ctyp with
            | Some t -> if contains_allocation t then t :: ts else ts
            | None -> ts)
          ts ctors
    | Tvariant (_, Rec_folded, _) -> ts
    | Tfixed_array (_, t) -> if contains_allocation t then t :: ts else ts
    | _ -> ts

  let path_name pset =
    let show_path path = String.concat "-" (List.map string_of_int path) in
    String.concat "." (Pset.to_seq pset |> Seq.map show_path |> List.of_seq)

  let name typ = function
    | Copy -> "__copy_" ^ Monomorph_tree.nominal_name typ
    | Free -> "__free_" ^ Monomorph_tree.nominal_name typ
    | Free_except pset ->
        "__free_except" ^ path_name pset ^ "_" ^ Monomorph_tree.nominal_name typ

  let make_fn kind v =
    let name = name v.typ kind in
    match Hashtbl.find_opt func_tbl name with
    | Some (_, _, f) -> f
    | None ->
        (* For simplicity, we pass everything as ptr *)
        let lltyp =
          match v.kind with
          | Const_ptr | Ptr -> ptr_t
          | Imm | Const -> failwith "TODO nonptr copy fn"
        in
        let ft = Llvm.function_type unit_t [| lltyp |] in
        let f = Llvm.declare_function name ft the_module in
        Llvm.set_linkage Llvm.Linkage.Link_once_odr f;
        Hashtbl.replace func_tbl name (kind, v, (ft, f));
        (ft, f)

  let copy_root_call param allocref v =
    let ft, f = make_fn Copy v in

    let value = get_prealloc allocref param (get_lltype_def v.typ) "" in
    (* Copy the inline part here. Recurse for allocations *)
    memcpy ~src:v ~dst:value ~size:(ci (sizeof_typ v.typ));
    Llvm.build_call ft f [| value |] "" builder |> ignore;
    { v with value; kind = Ptr }

  let copy_inner_call v =
    let ft, f = make_fn Copy v in
    Llvm.build_call ft f [| v.value |] "" builder |> ignore

  let make_ptr param v =
    let v = func_to_closure no_param v in
    match v.kind with
    | Const_ptr | Ptr -> v
    | Imm | Const ->
        let value = alloca param (get_lltype_def v.typ) "" in
        Llvm.build_store v.value value builder |> ignore;
        { v with value; kind = Ptr }

  let rec decl_children kind pseudovar t =
    (* The copy function navigates to allocated children, but we
       have to make sure the function for each type is available *)
    let ts = alloc_types [] t in
    let f typ =
      (* Value will be set correctly at [gen_functions].
         Make sure other fields are correct *)
      if contains_allocation typ && not (is_folded typ) then (
        make_fn kind { pseudovar with typ; kind = Ptr } |> ignore;
        decl_children kind pseudovar typ)
    in
    List.iter f ts

  let rec decl_children_exc pset pseudovar typ =
    match typ with
    | Trecord (_, Rec_folded, _) -> failwith "unreachable"
    | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
        Array.iteri
          (fun i f ->
            if contains_allocation f.ftyp then
              match pop_index_pset pset i with
              | Not_excl ->
                  make_fn Free { pseudovar with typ = f.ftyp; kind = Ptr }
                  |> ignore;
                  decl_children Free pseudovar f.ftyp
              | Excl -> ()
              | Followup pset ->
                  make_fn (Free_except pset)
                    { pseudovar with typ = f.ftyp; kind = Ptr }
                  |> ignore;
                  decl_children_exc pset pseudovar f.ftyp)
          fields
    | Trc _ ->
        (* This is a rc where the payload has been moved out and the refcount
           still needs freeing. There is no need to declare anything, because we
           won't free the payload. *)
        ()
    | t ->
        print_endline (show_typ t);
        failwith "TODO decl free or not supported"

  let copy param allocref v =
    if contains_allocation v.typ then
      let () = decl_children Copy v v.typ in
      (* TODO empty closures should not need to be copied *)
      make_ptr param v |> copy_root_call param !allocref
    else
      match v.kind with
      | Ptr ->
          let dst = get_prealloc !allocref param (get_lltype_def v.typ) "" in
          store_or_copy ~src:v ~dst;
          { v with value = dst; kind = Ptr }
      | Const ->
          let dst = get_prealloc !allocref param (get_lltype_def v.typ) "" in
          Llvm.build_store v.value dst builder |> ignore;
          { v with value = dst; kind = Ptr }
      | Const_ptr ->
          let dst = get_prealloc !allocref param (get_lltype_def v.typ) "" in
          Llvm.build_store
            (Llvm.global_initializer v.value |> Option.get)
            dst builder
          |> ignore;
          { v with value = dst; kind = Ptr }
      | _ -> v

  (* Copy for closures *)
  let cls_fn_name kind assoc =
    let pre = match kind with `Dtor -> "__dtor_" | `Ctor -> "__ctor_" in
    let fs = List.map (fun cl -> { ftyp = cl.cltyp; mut = cl.clmut }) assoc in
    let typ = Trecord ([], Rec_not (fs |> Array.of_list), None) in
    pre ^ Monomorph_tree.nominal_name typ

  let get_ctor assoc_type assoc upward =
    ignore upward;
    let name = cls_fn_name `Ctor assoc in
    match Hashtbl.find_opt cls_func_tbl name with
    | Some f -> f
    | None ->
        (* Create ctor function *)
        let curr_bb = Llvm.insertion_block builder in

        let func = Llvm.declare_function name ctor_t the_module in
        Llvm.(set_linkage Linkage.Link_once_odr) func;
        let bblk = Llvm.append_block context "entry" func in
        Llvm.position_at_end bblk builder;

        (* Allocate new env ptr *)
        let p0 = Llvm.param func 0 in
        let typ = typeof_closure assoc in
        let size = sizeof_typ typ |> ci in
        let newptr = malloc ~size in

        (* Copy old env to new env *)
        let src = { value = p0; kind = Ptr; lltyp = assoc_type; typ } in
        memcpy ~src ~dst:newptr ~size;

        (* Copy inner allocations *)
        (* TODO declare inner copy functions *)
        let f i cl =
          if contains_allocation cl.cltyp then (
            let value =
              Llvm.build_struct_gep assoc_type newptr i cl.clname builder
            in
            let lltyp = get_lltype_def cl.cltyp in
            let item = { value; typ = cl.cltyp; kind = Ptr; lltyp } in
            decl_children Copy item item.typ;
            copy_inner_call item);
          i + 1
        in
        (* [2] as starting index, because [0] is ctor, and [1] is dtor *)
        List.fold_left f 2 assoc |> ignore;

        Llvm.build_ret newptr builder |> ignore;
        Llvm.position_at_end curr_bb builder;

        Hashtbl.add cls_func_tbl name func;
        func

  let copy_impl dst =
    (* For nested types, we don't have to copy at every level.
       It's enough to copy the top level type and then copy every array
       and its members. That way, we copy as little as possible.
       This can be done by re-using [iter_array] and [iter_children]
       (or copying) from the Array module. *)
    match dst.typ with
    | Tarray t ->
        let v = bring_default_var dst in
        let sz = Llvm.build_gep int_t v.value [| ci 0 |] "sz" builder in
        let sz = Llvm.build_load int_t sz "size" builder in

        let item_type, _, head_size, item_size = item_type_head_size dst.typ in
        let is_string = match t with Tu8 -> true | _ -> false in
        (* It's a string, so we add a null terminator for C usage *)
        let cap_size = if is_string then head_size + 1 else head_size in

        let itemscap =
          (* Don't multiply by 1 *)
          if item_size <> 1 then Llvm.build_mul sz (ci item_size) "" builder
          else sz
        in
        (* Really capacity, not size *)
        let size = Llvm.build_add itemscap (ci cap_size) "" builder in

        let lltyp = get_lltype_def dst.typ in
        let ptr = malloc ~size in

        (* Don't write to null terminator *)
        let size =
          if is_string then Llvm.build_sub size (ci 1) "" builder else size
        in
        ignore
          (* Ptr is needed here to get a copy *)
          (let src = { value = v.value; typ = dst.typ; kind = Ptr; lltyp } in
           memcpy ~src ~dst:ptr ~size);

        (* Set new capacity since we only malloced [size] *)
        let cap = Llvm.build_gep int_t ptr [| ci 1 |] "newcap" builder in
        Llvm.build_store sz cap builder |> ignore;

        (if is_string then
           (* Set null terminator *)
           let last = Llvm.build_gep u8_t ptr [| size |] "" builder in
           Llvm.(build_store (const_int u8_t 0) last) builder |> ignore);
        (* set orig pointer to new ptr *)
        ignore (Llvm.build_store ptr dst.value builder);

        assert (item_type = t);
        if contains_allocation t then iter_array_children v sz t copy_inner_call
    | Trc _ ->
        let v = bring_default_var dst in

        let rf = Llvm.build_gep int_t v.value [| ci 0 |] "ref" builder in
        (* Increase refcount *)
        (* TODO make this atomic *)
        let added =
          let rc = Llvm.build_load int_t rf "refc" builder in
          Llvm.build_add rc (ci 1) "" builder
        in
        ignore (Llvm.(build_store added rf) builder)
    | Trecord (_, Rec_folded, _) -> failwith "unreachable"
    | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
        Array.iteri
          (fun i f ->
            if contains_allocation f.ftyp then
              (* Copy allocation part *)
              let v = follow_field dst i in
              copy_inner_call v)
          fields
    | Tvariant (_, Rec_folded, _) -> failwith "unreachable"
    | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) ->
        let index = var_index dst in
        let f i c =
          match c.ctyp with
          | None -> ()
          | Some t ->
              if contains_allocation t then (
                (* Compare to tag *)
                let start_bb = Llvm.insertion_block builder in
                let parent = Llvm.block_parent start_bb in

                let match_bb = Llvm.append_block context "match" parent in
                let cont_bb = Llvm.append_block context "cont" parent in

                let cmp =
                  Llvm.(build_icmp Icmp.Eq index.value (const_int i32_t i) "")
                    builder
                in
                ignore (Llvm.build_cond_br cmp match_bb cont_bb builder);

                (* Get data and apply [fn] *)
                Llvm.position_at_end match_bb builder;
                let data = var_data dst t in
                copy_inner_call data;
                ignore (Llvm.build_br cont_bb builder);

                Llvm.position_at_end cont_bb builder)
        in
        Array.iteri f ctors
    | Tfun _ ->
        (* We can assume this is a closure structure. The global function case
           has been filtered in [copy] above. *)
        let v = bring_default_var dst in
        (* Pointer to environment *)
        let env = Llvm.build_struct_gep closure_t v.value 1 "" builder in
        let mb_null = Llvm.build_load ptr_t env "" builder in

        (* Check for nullptr *)
        let start_bb = Llvm.insertion_block builder in
        let parent = Llvm.block_parent start_bb in

        let notnull_bb = Llvm.append_block context "notnull" parent in
        let ret_bb = Llvm.append_block context "ret" parent in
        let nullptr = Llvm.(const_null (type_of mb_null)) in
        let cmp = Llvm.(build_icmp Icmp.Eq mb_null nullptr "") builder in
        Llvm.build_cond_br cmp ret_bb notnull_bb builder |> ignore;

        Llvm.position_at_end notnull_bb builder;

        (* We don't have to check if a ctor exists. If the env exists, the ctor must also exist *)
        (* let env = bb mb_null voidptr_t "env" builder in *)
        let ctor_ptr = Llvm.build_gep ptr_t mb_null [| ci 0 |] "ctor" builder in
        let ctor = Llvm.build_load ptr_t ctor_ptr "ctor" builder in

        let newenv = Llvm.build_call ctor_t ctor [| mb_null |] "" builder in
        Llvm.build_store newenv env builder |> ignore;

        Llvm.build_br ret_bb builder |> ignore;
        Llvm.position_at_end ret_bb builder
    | Tfixed_array (i, t) ->
        if contains_allocation t then
          iter_fixed_array_children dst i t copy_inner_call
    | _ -> failwith "Internal Error: What are we copying?"

  let free_call v =
    let ft, f = make_fn Free v in
    Llvm.build_call ft f [| v.value |] "" builder |> ignore

  let free_call_only v =
    let name = name v.typ Free in
    match Hashtbl.find_opt func_tbl name with
    | Some (_, _, (ft, f)) ->
        Llvm.build_call ft f [| v.value |] "" builder |> ignore
    | None -> ()

  let free_except_call pset v =
    let ft, f = make_fn (Free_except pset) v in
    Llvm.build_call ft f [| v.value |] "" builder |> ignore

  let free param v =
    if contains_allocation v.typ then
      let () = decl_children Free v v.typ in
      make_ptr param v |> free_call

  let free_except param pset v =
    if Pset.is_empty pset then free param v
    else if contains_allocation v.typ then
      let () = decl_children_exc pset v v.typ in
      make_ptr param v |> free_except_call pset

  let get_dtor assoc_type assoc =
    let name = cls_fn_name `Dtor assoc in
    match Hashtbl.find_opt cls_func_tbl name with
    | Some f -> f
    | None ->
        (* Create dtor function *)
        let curr_bb = Llvm.insertion_block builder in

        let func = Llvm.declare_function name dtor_t the_module in
        Llvm.set_linkage Llvm.Linkage.Link_once_odr func;
        let bblk = Llvm.append_block context "entry" func in
        Llvm.position_at_end bblk builder;

        let p0 = Llvm.param func 0 in
        let f i cl =
          if contains_allocation cl.cltyp then (
            let value =
              Llvm.build_struct_gep assoc_type p0 i cl.clname builder
            in
            let lltyp = get_lltype_def cl.cltyp in
            let item = { value; typ = cl.cltyp; kind = Ptr; lltyp } in
            decl_children Free item item.typ;
            free_call item);
          i + 1
        in
        (* [2] as starting index, because [0] is ctor, and [1] is dtor *)
        List.fold_left f 2 assoc |> ignore;
        free_var p0 |> ignore;
        Llvm.build_ret_void builder |> ignore;

        Llvm.position_at_end curr_bb builder;

        Hashtbl.add cls_func_tbl name func;
        func

  let free_rc v item_typ =
    let v = bring_default_var v in

    let rf = Llvm.build_gep int_t v.value [| ci 0 |] "ref" builder in
    let rc = Llvm.build_load int_t rf "refc" builder in

    (* Get current block *)
    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let decr_bb = Llvm.append_block context "decr" parent in
    let free_payload_bb = Llvm.append_block context "free_payload" parent in
    let free_rc_bb = Llvm.append_block context "free_rc" parent in
    let decr_weak_bb = Llvm.append_block context "decr_weak" parent in
    let merge_bb = Llvm.append_block context "merge" parent in

    let cmp =
      Llvm.(build_icmp Icmp.Eq) rc (Llvm.const_int int_t 1) "" builder
    in
    (* Always decrease even if we free. Otherwise weak_ptrs cannot know if
       payload is still reachable. *)
    let subbed = Llvm.build_sub rc (Llvm.const_int int_t 1) "" builder in
    ignore (Llvm.build_store subbed rf builder);
    ignore (Llvm.build_cond_br cmp free_payload_bb decr_bb builder);

    (* decr *)
    Llvm.position_at_end decr_bb builder;
    ignore (Llvm.build_br merge_bb builder);

    (* free *)
    Llvm.position_at_end free_payload_bb builder;
    let value = Llvm.build_gep int_t v.value [| ci 2 |] "vl" builder in
    (match item_typ with
    | Some item_typ ->
        free_call_only
          { value; typ = item_typ; lltyp = get_lltype_def item_typ; kind = Ptr }
    | None -> ());

    (* Only free rc if there are no weak pointers as well. Since one single weak
       ptr count is kept for all owning references, we check for 1 weak ref
       count. If the count is above 1 there are weak pointers still, and we
       decrease the weak count by one to account for all owning pointers. *)
    let weakrf = Llvm.build_gep int_t v.value [| ci 1 |] "weakref" builder in
    let weakrc = Llvm.build_load int_t weakrf "weakrefc" builder in

    let cmp =
      Llvm.(build_icmp Icmp.Eq) weakrc (Llvm.const_int int_t 1) "" builder
    in
    ignore (Llvm.build_cond_br cmp free_rc_bb decr_weak_bb builder);

    (* decr weak *)
    Llvm.position_at_end decr_weak_bb builder;
    let wsubbed = Llvm.build_sub weakrc (Llvm.const_int int_t 1) "" builder in
    ignore (Llvm.build_store wsubbed weakrf builder);
    ignore (Llvm.build_br merge_bb builder);

    (* free rc *)
    Llvm.position_at_end free_rc_bb builder;
    free_var v.value |> ignore;
    ignore (Llvm.build_br merge_bb builder);

    Llvm.position_at_end merge_bb builder

  let free_weak_rc v =
    let v = bring_default_var v in

    let weakrf = Llvm.build_gep int_t v.value [| ci 1 |] "weakref" builder in
    let weakrc = Llvm.build_load int_t weakrf "refc" builder in

    (* If the weak count is 1 before we have decreased it, free rc value *)
    (* Get current block *)
    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let decr_bb = Llvm.append_block context "decr" parent in
    let free_rc_bb = Llvm.append_block context "free_rc" parent in
    let merge_bb = Llvm.append_block context "merge" parent in

    let cmp =
      Llvm.(build_icmp Icmp.Eq) weakrc (Llvm.const_int int_t 1) "" builder
    in
    ignore (Llvm.build_cond_br cmp free_rc_bb decr_bb builder);

    (* free *)
    Llvm.position_at_end free_rc_bb builder;
    ignore (free_var v.value);
    ignore (Llvm.build_br merge_bb builder);

    (* decr *)
    Llvm.position_at_end decr_bb builder;
    let subbed = Llvm.build_sub weakrc (Llvm.const_int int_t 1) "" builder in
    ignore (Llvm.build_store subbed weakrf builder);
    ignore (Llvm.build_br merge_bb builder);

    Llvm.position_at_end merge_bb builder

  let free_impl v =
    match v.typ with
    | Tarray t ->
        let v = bring_default_var v in
        (if contains_allocation t then
           let sz = Llvm.build_gep int_t v.value [| ci 0 |] "sz" builder in
           let sz = Llvm.build_load int_t sz "size" builder in

           iter_array_children v sz t free_call_only);

        free_var v.value |> ignore
    | Trc (Strong, item_typ) -> free_rc v (Some item_typ)
    | Trc (Weak, _) -> free_weak_rc v
    | Trecord (_, Rec_folded, _) -> failwith "unreachable"
    | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
        Array.iteri
          (fun i f ->
            if contains_allocation f.ftyp then
              let v = follow_field v i in
              free_call_only v)
          fields
    | Tvariant (_, Rec_folded, _) -> failwith "unreachable"
    | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) ->
        let index = var_index v in
        let f i c =
          match c.ctyp with
          | None -> ()
          | Some t ->
              if contains_allocation t then (
                (* Compare to tag *)
                let start_bb = Llvm.insertion_block builder in
                let parent = Llvm.block_parent start_bb in

                let match_bb = Llvm.append_block context "match" parent in
                let cont_bb = Llvm.append_block context "cont" parent in

                let cmp =
                  Llvm.(build_icmp Icmp.Eq index.value (const_int i32_t i) "")
                    builder
                in
                ignore (Llvm.build_cond_br cmp match_bb cont_bb builder);

                (* Get data and apply [fn] *)
                Llvm.position_at_end match_bb builder;
                let data = var_data v t in
                free_call_only data;
                ignore (Llvm.build_br cont_bb builder);

                Llvm.position_at_end cont_bb builder)
        in
        Array.iteri f ctors
    | Tfun _ ->
        let v = bring_default_var v in
        (* Pointer to environment *)
        let env = Llvm.build_struct_gep closure_t v.value 1 "envptr" builder in
        let mb_null = Llvm.build_load ptr_t env "env" builder in

        (* Check for nullptr *)
        let start_bb = Llvm.insertion_block builder in
        let parent = Llvm.block_parent start_bb in

        let notnull_bb = Llvm.append_block context "notnull" parent in
        let ret_bb = Llvm.append_block context "ret" parent in
        let nullptr = Llvm.(const_null (type_of mb_null)) in
        let cmp = Llvm.(build_icmp Icmp.Eq mb_null nullptr "") builder in
        Llvm.build_cond_br cmp ret_bb notnull_bb builder |> ignore;

        Llvm.position_at_end notnull_bb builder;

        (* Check if a dtor exists *)
        let dtor_bb = Llvm.append_block context "dtor" parent in
        let just_free_bb = Llvm.append_block context "just_free" parent in

        let cls_t = lltypeof_closure [] true in
        let dtor_ptr = Llvm.build_struct_gep cls_t mb_null 1 "" builder in
        let dtor = Llvm.build_load ptr_t dtor_ptr "dtor" builder in
        let cmp = Llvm.(build_icmp Icmp.Eq dtor nullptr "") builder in
        Llvm.build_cond_br cmp just_free_bb dtor_bb builder |> ignore;

        Llvm.position_at_end dtor_bb builder;
        Llvm.build_call dtor_t dtor [| mb_null |] "" builder |> ignore;
        Llvm.build_br ret_bb builder |> ignore;

        (* The dtor cleans up recursively.
           If there is no dtor, we have to free the closure *)
        Llvm.position_at_end just_free_bb builder;
        free_var mb_null |> ignore;
        Llvm.build_br ret_bb builder |> ignore;

        Llvm.position_at_end ret_bb builder
    | Tfixed_array (i, t) ->
        if contains_allocation t then
          iter_fixed_array_children v i t free_call_only
    | _ ->
        print_endline (show_typ v.typ);
        failwith "Internal Error: What are we freeing?"

  let free_impl_except pset v =
    match v.typ with
    | Trecord (_, Rec_folded, _) -> failwith "unreachable"
    | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
        Array.iteri
          (fun i f ->
            if contains_allocation f.ftyp then
              match pop_index_pset pset i with
              | Not_excl ->
                  (* Copy from [free_impl] *)
                  let v = follow_field v i in
                  free_call_only v
              | Excl -> (* field is excluded, do nothing *) ()
              | Followup pset ->
                  let v = follow_field v i in
                  free_except_call pset v)
          fields
    | Trc _ ->
        (* Only free refcount ptr. Same as free above, but without the payload *)
        free_rc v None
    | _ -> failwith "TODO free or not supported"

  let gen_functions () =
    Hashtbl.iter
      (fun _ (kind, v, (_, f)) ->
        let bb = Llvm.append_block context "entry" f in
        Llvm.position_at_end bb builder;

        let lltyp = get_lltype_def v.typ and typ = v.typ in
        let v = { typ; value = Llvm.param f 0; kind = Ptr; lltyp } in
        match kind with
        | Copy ->
            copy_impl v;
            Llvm.build_ret_void builder |> ignore
        | Free ->
            free_impl v;
            Llvm.build_ret_void builder |> ignore
        | Free_except pset ->
            free_impl_except pset v;
            Llvm.build_ret_void builder |> ignore)
      func_tbl
end
