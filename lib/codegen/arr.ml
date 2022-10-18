module type S = sig
  open Cleaned_types
  open Llvm_types

  val gen_array_lit :
    Llvm_types.param ->
    Monomorph_tree.monod_tree list ->
    typ ->
    Monomorph_tree.alloca ->
    llvar
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

  let gen_array_lit param exprs typ allocref =
    let item_typ =
      match typ with
      | Tarray t -> t
      | _ ->
          print_endline (show_typ typ);
          failwith "Internal Error: No array in array"
    in
    let llitem_typ = get_lltype_def item_typ in
    let vec_sz = List.length exprs in

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
    in
    let cap = head_sz + ((vec_sz - 1) * item_sz) in

    let lltyp = get_lltype_def typ in
    let ptr =
      malloc ~size:(Llvm.const_int int_t cap) |> fun ptr ->
      Llvm.build_bitcast ptr lltyp "" builder
    in

    let arr = get_prealloc !allocref param lltyp "arr" in
    ignore (Llvm.build_store ptr arr builder);

    (* Initialize counts *)
    let ci i = Llvm.const_int int_t i in
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

        match src.typ with
        | Trecord _ | Tvariant _ ->
            if dst <> src.value then
              memcpy ~dst ~src ~size:(Llvm.const_int int_t item_sz)
            else (* The record was constructed inplace *) ()
        | _ -> ignore (Llvm.build_store src.value dst builder))
      exprs;
    { value = arr; typ; lltyp; kind = Ptr }
end
