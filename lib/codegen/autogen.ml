module Make (T : Lltypes_intf.S) (H : Helpers.S) (Arr : Arr_intf.S) = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open T
  open H
  open Arr

  type func = Copy | Free

  let func_tbl = Hashtbl.create 64
  let cls_func_tbl = Hashtbl.create 64
  let ci i = Llvm.const_int int_t i
  let bb = Llvm.build_bitcast

  let alloc_types ts = function
    | Tarray t -> t :: ts
    | Trecord (_, _, fields) ->
        Array.fold_left
          (fun ts f -> if contains_allocation f.ftyp then f.ftyp :: ts else ts)
          ts fields
    | Tvariant (_, _, ctors) ->
        Array.fold_left
          (fun ts c ->
            match c.ctyp with
            | Some t -> if contains_allocation t then t :: ts else ts
            | None -> ts)
          ts ctors
    | _ -> ts

  let name typ = function
    | Copy -> "__copy_" ^ Monomorph_tree.short_name ~closure:false typ
    | Free -> "__free_" ^ Monomorph_tree.short_name ~closure:false typ

  let make_fn kind v =
    let name = name v.typ kind in
    match Hashtbl.find_opt func_tbl name with
    | Some (_, _, f) -> f
    | None ->
        (* For simplicity, we pass everything as ptr *)
        let lltyp =
          match v.kind with
          | Const_ptr | Ptr -> get_lltype_def v.typ |> Llvm.pointer_type
          | Imm | Const -> failwith "TODO nonptr copy fn"
        in
        let ft = Llvm.function_type unit_t [| lltyp |] in
        let f = Llvm.declare_function name ft the_module in
        Llvm.set_linkage Llvm.Linkage.Internal f;
        Hashtbl.replace func_tbl name (kind, v, f);
        f

  let copy_root_call param allocref v =
    let f = make_fn Copy v in

    let value = get_prealloc allocref param (get_lltype_def v.typ) "" in
    (* Copy the inline part here. Recurse for allocations *)
    memcpy ~src:v ~dst:value ~size:(ci (sizeof_typ v.typ));
    Llvm.build_call f [| value |] "" builder |> ignore;
    { v with value; kind = Ptr }

  let copy_inner_call v =
    let f = make_fn Copy v in
    Llvm.build_call f [| v.value |] "" builder |> ignore

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
      if contains_allocation typ then (
        make_fn kind { pseudovar with typ; kind = Ptr } |> ignore;
        decl_children kind pseudovar typ)
    in
    List.iter f ts

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
    let typ = Trecord ([], None, fs |> Array.of_list) in
    pre ^ Monomorph_tree.short_name ~closure:false typ

  let get_ctor assoc_type assoc =
    let name = cls_fn_name `Ctor assoc in
    match Hashtbl.find_opt cls_func_tbl name with
    | Some f -> f
    | None ->
        (* Create ctor function *)
        let curr_bb = Llvm.insertion_block builder in

        let func = Llvm.declare_function name ctor_t the_module in
        Llvm.(set_linkage Linkage.Internal) func;
        let bblk = Llvm.append_block context "entry" func in
        Llvm.position_at_end bblk builder;

        (* Allocate new env ptr *)
        let p0 = Llvm.param func 0 in
        let env_ptr = (bb p0 (Llvm.pointer_type assoc_type)) "" builder in
        let typ = typeof_closure assoc in
        let size = sizeof_typ typ |> ci in
        let newptr = malloc ~size in
        let newptr = (bb newptr (Llvm.pointer_type assoc_type)) "" builder in

        (* Copy old env to new env *)
        let src = { value = env_ptr; kind = Ptr; lltyp = assoc_type; typ } in
        memcpy ~src ~dst:newptr ~size;

        (* Copy inner allocations *)
        (* TODO declare inner copy functions *)
        let f i cl =
          (if contains_allocation cl.cltyp then
             let value = Llvm.build_struct_gep newptr i cl.clname builder in
             let lltyp = get_lltype_def cl.cltyp in
             let item = { value; typ = cl.cltyp; kind = Ptr; lltyp } in
             copy_inner_call item);
          i + 1
        in
        (* [2] as starting index, because [0] is ctor, and [1] is dtor *)
        List.fold_left f 2 assoc |> ignore;

        let ret_ptr = bb newptr voidptr_t "" builder in
        Llvm.build_ret ret_ptr builder |> ignore;
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
        let int_ptr = bb v.value (Llvm.pointer_type int_t) "ref" builder in
        let sz = Llvm.build_gep int_ptr [| ci 1 |] "sz" builder in
        let sz = Llvm.build_load sz "size" builder in
        let cap = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
        let cap = Llvm.build_load cap "cap" builder in

        let item_type, _, head_size, item_size = item_type_head_size dst.typ in
        let is_string = match t with Tu8 -> true | _ -> false in
        (* It's a string, so we add a null terminator for C usage *)
        let cap_size = if is_string then head_size + 1 else head_size in

        let itemscap =
          (* Don't multiply by 1 *)
          if item_size <> 1 then Llvm.build_mul cap (ci item_size) "" builder
          else cap
        in
        (* Really capacity, not size *)
        let size = Llvm.build_add itemscap (ci cap_size) "" builder in

        let lltyp = get_lltype_def dst.typ in
        let ptr = malloc ~size |> fun ptr -> bb ptr lltyp "" builder in
        let itemssize =
          (* Don't multiply by 1 *)
          if item_size <> 1 then Llvm.build_mul sz (ci item_size) "" builder
          else sz
        in
        let size = Llvm.build_add itemssize (ci head_size) "" builder in
        ignore
          (* Ptr is needed here to get a copy *)
          (let src = { value = v.value; typ = dst.typ; kind = Ptr; lltyp } in
           memcpy ~src ~dst:ptr ~size);
        (if is_string then
           (* Set null terminator *)
           let last = Llvm.build_gep ptr [| size |] "" builder in
           Llvm.(build_store (const_int u8_t 0) last) builder |> ignore);
        (* set orig pointer to new ptr *)
        ignore (Llvm.build_store ptr dst.value builder);

        assert (item_type = t);
        if contains_allocation t then iter_array_children v sz t copy_inner_call
    | Trecord (_, _, fs) ->
        Array.iteri
          (fun i f ->
            if contains_allocation f.ftyp then
              (* Copy allocation part *)
              let value = Llvm.build_struct_gep dst.value i "" builder in
              let lltyp = get_lltype_def f.ftyp in
              let v = { value; typ = f.ftyp; lltyp; kind = Ptr } in
              copy_inner_call v)
          fs
    | Tvariant (_, _, ctors) ->
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
        (* We can assume this is a closure structure.
             The global function case has been filtered in [copy] above. *)
        let v = bring_default_var dst in
        let ptr = bb v.value (Llvm.pointer_type closure_t) "" builder in
        (* Pointer to environment *)
        let env = Llvm.build_struct_gep ptr 1 "" builder in
        let mb_null = Llvm.build_load env "" builder in

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
        let ctor_ptr = Llvm.build_gep mb_null [| ci 0 |] "ctor" builder in
        let ctor_ptr = bb ctor_ptr (Llvm.pointer_type voidptr_t) "" builder in
        let ctor_ptr = Llvm.build_load ctor_ptr "ctor" builder in
        let ctor = (bb ctor_ptr (Llvm.pointer_type ctor_t)) "ctor" builder in

        let newenv = Llvm.build_call ctor [| mb_null |] "" builder in
        Llvm.build_store newenv env builder |> ignore;

        Llvm.build_br ret_bb builder |> ignore;
        Llvm.position_at_end ret_bb builder
    | _ -> failwith "Internal Error: What are we copying?"

  let free_call v =
    let f = make_fn Free v in
    Llvm.build_call f [| v.value |] "" builder |> ignore

  let free param v =
    if contains_allocation v.typ then
      let () = decl_children Free v v.typ in
      make_ptr param v |> free_call

  let get_dtor assoc_type assoc =
    let name = cls_fn_name `Dtor assoc in
    match Hashtbl.find_opt cls_func_tbl name with
    | Some f -> f
    | None ->
        (* Create dtor function *)
        let curr_bb = Llvm.insertion_block builder in

        let func = Llvm.declare_function name dtor_t the_module in
        Llvm.set_linkage Llvm.Linkage.Internal func;
        let bblk = Llvm.append_block context "entry" func in
        Llvm.position_at_end bblk builder;

        let p0 = Llvm.param func 0 in
        let clsr_ptr = (bb p0 (Llvm.pointer_type assoc_type)) "" builder in
        let f i cl =
          (if contains_allocation cl.cltyp then
             let value = Llvm.build_struct_gep clsr_ptr i cl.clname builder in
             let lltyp = get_lltype_def cl.cltyp in
             let item = { value; typ = cl.cltyp; kind = Ptr; lltyp } in
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

  let free_impl v =
    match v.typ with
    | Tarray t ->
        let v = bring_default_var v in
        let int_ptr =
          Llvm.build_bitcast v.value (Llvm.pointer_type int_t) "ref" builder
        in
        (if contains_allocation t then
           let sz = Llvm.build_gep int_ptr [| ci 1 |] "sz" builder in
           let sz = Llvm.build_load sz "size" builder in

           iter_array_children v sz t free_call);

        free_var int_ptr |> ignore
    | Trecord (_, _, fs) ->
        Array.iteri
          (fun i f ->
            if contains_allocation f.ftyp then
              let value = Llvm.build_struct_gep v.value i "" builder in
              let lltyp = get_lltype_def f.ftyp in
              let v = { value; typ = f.ftyp; lltyp; kind = Ptr } in
              free_call v)
          fs
    | Tvariant (_, _, ctors) ->
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
                free_call data;
                ignore (Llvm.build_br cont_bb builder);

                Llvm.position_at_end cont_bb builder)
        in
        Array.iteri f ctors
    | Tfun _ ->
        let v = bring_default_var v in
        let ptr = bb v.value (Llvm.pointer_type closure_t) "" builder in
        (* Pointer to environment *)
        let env = Llvm.build_struct_gep ptr 1 "envptr" builder in
        let mb_null = Llvm.build_load env "env" builder in

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
        let env = bb mb_null (Llvm.pointer_type cls_t) "" builder in
        let dtor_ptr = Llvm.build_struct_gep env 1 "" builder in
        let dtor_ptr = bb dtor_ptr (Llvm.pointer_type voidptr_t) "" builder in
        let dtor_ptr = Llvm.build_load dtor_ptr "dtor" builder in
        let cmp = Llvm.(build_icmp Icmp.Eq dtor_ptr nullptr "") builder in
        Llvm.build_cond_br cmp just_free_bb dtor_bb builder |> ignore;

        Llvm.position_at_end dtor_bb builder;
        let dtor = (bb dtor_ptr (Llvm.pointer_type dtor_t)) "dtor" builder in
        Llvm.build_call dtor [| mb_null |] "" builder |> ignore;
        Llvm.build_br ret_bb builder |> ignore;

        (* The dtor cleans up recursively.
           If there is no dtor, we have to free the closure *)
        Llvm.position_at_end just_free_bb builder;
        free_var mb_null |> ignore;
        Llvm.build_br ret_bb builder |> ignore;

        Llvm.position_at_end ret_bb builder
    | _ ->
        print_endline (show_typ v.typ);
        failwith "Internal Error: What are we freeing?"

  let gen_functions () =
    Hashtbl.iter
      (fun _ (kind, v, ft) ->
        let bb = Llvm.append_block context "entry" ft in
        Llvm.position_at_end bb builder;

        let v = { v with value = Llvm.param ft 0; kind = Ptr } in
        match kind with
        | Copy ->
            copy_impl v;
            Llvm.build_ret_void builder |> ignore
        | Free ->
            free_impl v;
            Llvm.build_ret_void builder |> ignore)
      func_tbl
end
