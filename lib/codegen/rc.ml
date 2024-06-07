module type Core = sig
  open Llvm_types

  val gen_expr : param -> Monomorph_tree.monod_tree -> llvar
  val gen_constexpr : param -> Monomorph_tree.monod_tree -> llvar
end

module type S = sig
  open Cleaned_types
  open Llvm_types

  val item_type_size : typ -> typ * Llvm.lltype * int
  val data : llvar -> llvar

  val gen_rc :
    param ->
    Monomorph_tree.monod_expr ->
    typ ->
    Monomorph_tree.allocas ref ->
    llvar
end

module Make (C : Core) (T : Lltypes_intf.S) (H : Helpers.S) = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open C
  open T
  open H

  let ci = Llvm.const_int int_t

  let item_type = function
    | Trc t -> t
    | t ->
        print_endline (show_typ t);
        failwith "Internal Error: No rc type"

  let item_type_size typ =
    let item_typ = item_type typ in
    let item_size, item_align = size_alignof_typ item_typ in

    let head_size =
      let size = sizeof_typ typ in
      alignup ~size ~upto:item_align
    in
    (item_typ, get_lltype_def item_typ, head_size + item_size)

  let data v =
    let typ = item_type v.typ in
    let lltyp = get_lltype_def typ in

    let value = Llvm.build_gep int_t v.value [| ci 1 |] "data" builder in
    { value; typ; lltyp; kind = Ptr }

  let gen_rc param expr typ allocref =
    let item_typ, item_lltyp, size = item_type_size typ in

    let lltyp = get_lltype_def typ in

    let ptr = malloc ~size:(ci size) in
    let rc = get_prealloc !allocref param lltyp "rc" in
    ignore (Llvm.build_store ptr rc builder);

    let dst = Llvm.build_gep int_t ptr [| ci 0 |] "ref" builder in
    (* refcount of 1 *)
    ignore (Llvm.build_store (ci 1) dst builder);

    (* Initialize rc *)
    (match item_typ with
    | Tunit ->
        (* Generate the expression for side effects *)
        gen_expr param Monomorph_tree.(expr.ex) |> ignore
    (* TODO specialize for array *)
    | _ -> (
        let dst = Llvm.build_gep item_lltyp ptr [| ci 1 |] "item" builder in

        let src =
          let arg = gen_expr { param with alloca = Some dst } expr.ex in
          get_mono_func arg param expr.monomorph
          |> func_to_closure param |> bring_default_var
        in

        match src.kind with
        | Ptr | Const_ptr ->
            if dst <> src.value then
              memcpy ~dst ~src ~size:(Llvm.const_int int_t size)
            else (* The record was constructed inplace *) ()
        | Imm | Const -> ignore (Llvm.build_store src.value dst builder)));

    { value = rc; typ; lltyp; kind = Ptr }
end
