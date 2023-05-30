module Make (T : Lltypes_intf.S) (H : Helpers.S) (Arr : Arr_intf.S) = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open T
  open H
  open Arr

  type func = Copy

  let func_tbl = Hashtbl.create 64
  let ci i = Llvm.const_int int_t i

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

  let make_copy_fn v =
    let name = "__copy_" ^ Monomorph_tree.short_name ~closure:false v.typ in
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
        Hashtbl.replace func_tbl name (Copy, v, f);
        f

  let copy_root_call param allocref v =
    let f = make_copy_fn v in

    let value = get_prealloc allocref param (get_lltype_def v.typ) "" in
    (* Copy the inline part here. Recurse for allocations *)
    memcpy ~src:v ~dst:value ~size:(ci (sizeof_typ v.typ));
    Llvm.build_call f [| value |] "" builder |> ignore;
    { v with value; kind = Ptr }

  let copy_inner_call v =
    let f = make_copy_fn v in
    Llvm.build_call f [| v.value |] "" builder |> ignore

  let make_ptr param v =
    let v = func_to_closure no_param v in
    match v.kind with
    | Const_ptr | Ptr -> v
    | Imm | Const ->
        let value = alloca param (get_lltype_def v.typ) "" in
        { v with value; kind = Ptr }

  let rec decl_copy_children pseudovar t =
    (* The copy function navigates to allocated children, but we
       have to make sure the function for each type is available *)
    let ts = alloc_types [] t in
    let f typ =
      (* Value will be set correctly at [gen_functions].
         Make sure other fields are correct *)
      if contains_allocation typ then (
        make_copy_fn { pseudovar with typ; kind = Ptr } |> ignore;
        decl_copy_children pseudovar typ)
    in
    List.iter f ts

  let copy param allocref v =
    if contains_allocation v.typ then
      let () = decl_copy_children v v.typ in
      (* TODO empty closures should not need to be copied *)
      make_ptr param v |> copy_root_call param !allocref
    else v

  let copy_impl dst =
    (* For nested types, we don't have to copy at every level.
       It's enough to copy the top level type and then copy every array
       and its members. That way, we copy as little as possible.
       This can be done by re-using [iter_array] and [iter_children]
       (or copying) from the Array module. *)
    match dst.typ with
    | Tarray t ->
        let v = bring_default_var dst in
        let int_ptr =
          Llvm.build_bitcast v.value (Llvm.pointer_type int_t) "ref" builder
        in
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
        let ptr =
          malloc ~size |> fun ptr -> Llvm.build_bitcast ptr lltyp "" builder
        in
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
    | _ -> failwith "Internal Error: What are we copying?"

  let free v = ignore v

  let gen_functions () =
    Hashtbl.iter
      (fun _ (_, v, ft) ->
        let bb = Llvm.append_block context "entry" ft in
        Llvm.position_at_end bb builder;

        let v = { v with value = Llvm.param ft 0 } in
        copy_impl v;
        Llvm.build_ret_void builder |> ignore)
      func_tbl
end
