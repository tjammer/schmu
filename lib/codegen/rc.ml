module type Core = sig
  open Llvm_types

  val gen_expr : param -> Monomorph_tree.monod_tree -> llvar
  val gen_constexpr : param -> Monomorph_tree.monod_tree -> llvar
end

module type S = sig
  open Cleaned_types
  open Llvm_types

  val gen_rc :
    param ->
    Monomorph_tree.monod_expr ->
    typ ->
    Monomorph_tree.allocas ref ->
    llvar

  val get : llvar -> llvar
  val to_weak : llvar -> llvar
  val unsafe_of_weak : llvar -> llvar
  val cnt : llvar -> llvar
  val unsafe_addr : llvar -> llvar
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
    | Trc (_, t) -> t
    | t ->
        print_endline (show_typ t);
        failwith "Internal Error: No rc type"

  let item_type_size item_typ =
    let item_size, item_align = size_alignof_typ item_typ in

    let head_size =
      let size =
        (* Two ints, for strong and weak ref count *)
        2 * sizeof_typ Tint
      in
      alignup ~size ~upto:item_align
    in
    (item_typ, item_size, head_size + item_size)

  let get v =
    let item_typ = item_type v.typ in
    let lltyp = get_lltype_def item_typ in

    let value = Llvm.build_gep int_t v.value [| ci 2 |] "data" builder in
    { value; typ = item_typ; lltyp; kind = Ptr }

  let to_weak v =
    let def = bring_default v in

    let weakrf = Llvm.build_gep int_t def [| ci 1 |] "weakref" builder in
    let weakrc = Llvm.build_load int_t weakrf "weakrc" builder in
    let added = Llvm.build_add weakrc (Llvm.const_int int_t 1) "" builder in
    ignore (Llvm.build_store added weakrf builder);

    let typ = Trc (Weak, item_type v.typ) in
    { v with typ }

  let unsafe_of_weak v =
    let def = bring_default v in

    let rf = Llvm.build_gep int_t def [| ci 0 |] "ref" builder in
    let rc = Llvm.build_load int_t rf "refc" builder in
    let added = Llvm.build_add rc (Llvm.const_int int_t 1) "" builder in
    ignore (Llvm.build_store added rf builder);

    let typ = Trc (Strong, item_type v.typ) in
    { v with typ }

  let unsafe_addr v =
    let value = bring_default_var v in

    let typ = Traw_ptr (item_type value.typ) in
    { value with kind = Imm; typ; lltyp = ptr_t }

  let cnt v =
    let def = bring_default v in

    let value = Llvm.build_gep int_t def [| ci 0 |] "ref" builder in
    { value; typ = Tint; lltyp = get_lltype_def Tint; kind = Ptr }

  let gen_rc param expr typ allocref =
    let item_typ, item_size, size =
      item_type_size Monomorph_tree.(expr.ex.typ)
    in

    let lltyp = get_lltype_def typ in

    let ptr = malloc ~size:(ci size) in
    let rc = get_prealloc !allocref param lltyp "rc" in
    ignore (Llvm.build_store ptr rc builder);

    let dst = Llvm.build_gep int_t ptr [| ci 0 |] "ref" builder in
    (* refcount of 1 *)
    ignore (Llvm.build_store (ci 1) dst builder);

    let dst = Llvm.build_gep int_t ptr [| ci 1 |] "weakref" builder in
    (* refcount of 1 *)
    ignore (Llvm.build_store (ci 1) dst builder);

    (* Initialize rc *)
    (match item_typ with
    | Tunit ->
        (* Generate the expression for side effects *)
        gen_expr param Monomorph_tree.(expr.ex) |> ignore
    (* TODO specialize for array *)
    | _ -> (
        let dst = Llvm.build_gep int_t ptr [| ci 2 |] "item" builder in

        let src =
          let arg = gen_expr { param with alloca = Some dst } expr.ex in
          get_mono_func arg param expr.monomorph
          |> func_to_closure param |> bring_default_var
        in

        match src.kind with
        | Ptr | Const_ptr ->
            if dst <> src.value then
              memcpy ~dst ~src ~size:(Llvm.const_int int_t item_size)
            else (* The record was constructed inplace *) ()
        | Imm | Const -> ignore (Llvm.build_store src.value dst builder)));

    { value = rc; typ; lltyp; kind = Ptr }
end
