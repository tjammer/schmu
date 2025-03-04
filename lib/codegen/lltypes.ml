module Make (A : Abi_intf.S) = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open A
  module Strtbl = Hashtbl

  let struct_tbl = Strtbl.create 32
  let ( ++ ) = Seq.append

  (* Named structs for typedefs *)

  let struct_name t = Monomorph_tree.nominal_name t

  (** For functions, when passed as parameter, we convert it to a closure ptr
   to later cast to the correct types. At the application, we need to
   get the correct type though to cast it back. *)
  let rec get_lltype_def = function
    | Tint -> int_t
    | Tbool -> bool_t
    | Ti8 | Tu8 -> u8_t
    | Ti16 | Tu16 -> u16_t
    | Tfloat -> float_t
    | Ti32 | Tu32 -> i32_t
    | Tf32 -> f32_t
    | Tunit -> unit_t
    | Tpoly _ -> ptr_t
    | (Trecord _ as t) | (Tvariant _ as t) -> get_struct t
    | Tfun _ -> closure_t
    | Traw_ptr Tunit | Tarray Tunit -> ptr_t
    | Traw_ptr _ | Tarray _ | Trc _ -> ptr_t
    | Tfixed_array (i, t) -> Llvm.array_type (get_lltype_def t) i

  and get_lltype_param mut = function
    | ( Tint | Tbool | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 | Tunit | Tpoly _
      | Traw_ptr _ | Tarray _ | Ti8 | Ti16 | Tu32 ) as t ->
        let t = get_lltype_def t in
        if mut then ptr_t else t
    | Tfun _ -> ptr_t
    | (Trecord _ | Tvariant _ | Tfixed_array _ | Trc _) as t -> (
        match pkind_of_typ mut t with
        | Boxed -> ptr_t
        | Unboxed size -> lltype_unboxed size)

  (* LLVM type of closure struct and records *)
  and typeof_aggregate agg =
    List.filter_map
      (function Tunit -> None | t -> Some (get_lltype_def t))
      agg
    |> Array.of_list |> Llvm.struct_type context

  and prepend_closure_env agg =
    let fs =
      List.filter_map
        (fun cl ->
          match cl.cltyp with
          | Tunit -> None
          | _ -> Some { ftyp = cl.cltyp; mut = cl.clmut })
        agg
    in
    { mut = false; ftyp = Traw_ptr Tu8 }
    :: { mut = false; ftyp = Traw_ptr Tu8 }
    :: fs

  and lltypeof_closure agg upward =
    List.map
      (fun f -> if f.mut && not upward then ptr_t else get_lltype_def f.ftyp)
      (prepend_closure_env agg)
    |> Array.of_list |> Llvm.struct_type context

  and typeof_closure agg =
    Trecord ([], Rec_not (prepend_closure_env agg |> Array.of_list), None)

  and typeof_funclike = function
    (* Returns a LLVM function type to use far calling a closure *)
    | Tfun (ps, ret, kind) ->
        let f, _, _ = typeof_func ~decl:false (ps, ret, kind) in
        f
    | t -> failwith ("Internal Error: Cannot call " ^ string_of_type t)

  and typeof_func ~decl (params, ret, kind) =
    (* When [get_lltype] is called on a function, we handle the dynamic case where
       a function or closure is being passed to another function.
       If a record is returned, we allocate it at the caller site and
       pass it as first argument to the function *)
    let noaliases = ref [] in
    let prefix, ret_t =
      if is_struct ret then
        match pkind_of_typ false ret with
        | Boxed ->
            noaliases := [ 0 ];
            (Seq.return (get_lltype_param false ret), unit_t)
        | Unboxed size -> (Seq.empty, lltype_unboxed size)
      else (Seq.empty, get_lltype_param false ret)
    in

    let suffix =
      (* A closure needs an extra parameter for the environment  *)
      if decl then
        match kind with Closure _ -> Seq.return ptr_t | _ -> Seq.empty
      else Seq.return ptr_t
    in

    (* Index 0 is return type *)
    let start_idx = if Seq.is_empty prefix then 0 else 1 in
    let byvals = ref [] in
    let i = ref start_idx in
    let params_t =
      (* For the params, we want to produce the param type.
         There is a special case for records which are splint into two words. *)
      List.fold_left
        (fun ps p ->
          let typ = p.pt in
          match typ with
          | Tunit -> ps
          | _ -> (
              if p.pmut then noaliases := !i :: !noaliases;
              incr i;
              match pkind_of_typ p.pmut typ with
              | Unboxed (Two_params (fst, snd)) ->
                  (* Two parameters so we have to increase the param count. *)
                  incr i;
                  (* snd before fst b/c we rev later *)
                  lltype_unbox snd :: lltype_unbox fst :: ps
              | Boxed when is_aggregate typ ->
                  if not p.pmut then byvals := (!i, typ) :: !byvals;
                  get_lltype_param p.pmut typ :: ps
              | _ -> get_lltype_param p.pmut typ :: ps))
        [] params
      |> List.rev |> List.to_seq
      |> fun seq -> prefix ++ seq ++ suffix |> Array.of_seq
    in
    let ft = Llvm.function_type ret_t params_t in
    (ft, !byvals, !noaliases)

  and to_named_typedefs name = function
    | Trecord (_, Rec_folded, _) -> failwith "unreachable"
    | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
        let t = Llvm.named_struct_type context name in
        let lltyp =
          Array.to_list fields
          |> List.map (fun (f : field) -> f.ftyp)
          |> typeof_aggregate |> Llvm.struct_element_types
        in
        Llvm.struct_set_body t lltyp false;
        Strtbl.replace struct_tbl name t;
        t
    | Tvariant (_, Rec_folded, _) -> failwith "unreachable"
    | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) -> (
        (* We loop through each ctor and then we use the largest one as a
           typedef for the whole type *)
        let tag = i32_t in
        let largest = variant_get_largest ctors |> Option.map get_lltype_def in
        let t = Llvm.named_struct_type context name in
        match largest with
        | Some lltyp ->
            Llvm.struct_set_body t [| tag; lltyp |] false;
            Strtbl.replace struct_tbl name t;
            t
        | None ->
            (* C style enum, no data, just tag *)
            Llvm.struct_set_body t [| tag |] false;
            Strtbl.replace struct_tbl name t;
            t)
    | _ -> failwith "Internal Error: Only records and variants should be here"

  and get_struct t =
    let name = struct_name t in
    match Strtbl.find_opt struct_tbl name with
    | Some t -> t
    | None ->
        (* Add struct to struct tbl *)
        to_named_typedefs name t

  let is_only_units cls =
    List.fold_left
      (fun acc cl -> match cl.cltyp with Tunit -> acc | _ -> false)
      true cls
end
