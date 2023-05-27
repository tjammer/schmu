module Make (T : Lltypes_intf.S) (H : Helpers.S) (Arr : Arr_intf.S) = struct
  open Cleaned_types
  open Llvm_types
  open T
  open H
  open Arr

  type func = Copy

  let func_tbl = Hashtbl.create 64
  let ci i = Llvm.const_int int_t i

  let rec alloc_types ts = function
    | Tarray t -> t :: ts
    | Trecord (_, _, fields) ->
        Array.fold_left (fun ts f -> alloc_types ts f.ftyp) ts fields
    | Tvariant (_, _, ctors) ->
        Array.fold_left
          (fun ts c ->
            match c.ctyp with Some t -> alloc_types ts t | None -> ts)
          ts ctors
    | _ -> ts

  let make_copy_fn v =
    let name = "__copy_" ^ Monomorph_tree.short_name ~closure:false v.typ in
    print_endline ("root: " ^ name);
    match Hashtbl.find_opt func_tbl name with
    | Some (_, _, f) -> f
    | None ->
        (* For simplicity, we pass everything as ptr *)
        let lltyp =
          match v.kind with
          | Const_ptr | Ptr -> get_lltype_def v.typ |> Llvm.pointer_type
          | Imm | Const -> failwith "TODO nonptr copy fn"
        in
        let ft = Llvm.function_type unit_t [| lltyp; lltyp |] in
        let f = Llvm.declare_function name ft the_module in
        Llvm.set_linkage Llvm.Linkage.Internal f;
        Hashtbl.replace func_tbl name (Copy, v, f);
        f

  let copy_root_call v =
    let f = make_copy_fn v in

    let value = Llvm.build_alloca (get_lltype_def v.typ) "" builder in
    Llvm.build_call f [| value; v.value |] "" builder |> ignore;
    { v with value; kind = Ptr }

  let copy_inner_call v =
    let f = make_copy_fn v in
    Llvm.build_call f [| v.value; v.value |] "" builder |> ignore

  let make_ptr v =
    let v = func_to_closure no_param v in
    match v.kind with
    | Const_ptr | Ptr -> v
    | Imm | Const ->
        let value = Llvm.build_alloca (get_lltype_def v.typ) "" builder in
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

  let copy v =
    if contains_allocation v.typ then
      let () = decl_copy_children v v.typ in
      (* TODO empty closures should not need to be copied *)
      make_ptr v |> copy_root_call
    else v

  let copy_impl src dst =
    (* For nested types, we don't have to copy at every level.
       It's enough to copy the top level type and then copy every array
       and its members. That way, we copy as little as possible.
       This can be done by re-using [iter_array] and [iter_children]
       (or copying) from the Array module. *)
    match src.typ with
    | Tarray t ->
        let v = bring_default_var src in
        let int_ptr =
          Llvm.build_bitcast v.value (Llvm.pointer_type int_t) "ref" builder
        in
        let sz = Llvm.build_gep int_ptr [| ci 1 |] "sz" builder in
        let sz = Llvm.build_load sz "size" builder in
        let cap = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
        let cap = Llvm.build_load cap "cap" builder in

        let item_type, _, head_size, item_size = item_type_head_size src.typ in
        let itemscap = Llvm.build_mul cap (ci item_size) "" builder in
        (* Really capacity, not size *)
        let size = Llvm.build_add itemscap (ci head_size) "" builder in

        let lltyp = get_lltype_def src.typ in
        let ptr =
          malloc ~size |> fun ptr -> Llvm.build_bitcast ptr lltyp "" builder
        in
        let itemssize = Llvm.build_mul sz (ci item_size) "" builder in
        let size = Llvm.build_add itemssize (ci head_size) "" builder in
        ignore
          (* Ptr is needed here to get a copy *)
          (let src = { value = v.value; typ = src.typ; kind = Ptr; lltyp } in
           memcpy ~src ~dst:ptr ~size);
        (* set orig pointer to new ptr *)
        ignore (Llvm.build_store ptr dst.value builder);

        assert (item_type = t);
        if contains_allocation t then iter_array_children v sz t copy_inner_call
    | _ -> failwith "TODO"

  let free v = ignore v

  let gen_functions () =
    Hashtbl.iter
      (fun _ (_, v, ft) ->
        let bb = Llvm.append_block context "entry" ft in
        Llvm.position_at_end bb builder;

        let src = { v with value = Llvm.param ft 1 } in
        let dst = { v with value = Llvm.param ft 0 } in

        copy_impl src dst;
        Llvm.build_ret_void builder |> ignore)
      func_tbl
end
