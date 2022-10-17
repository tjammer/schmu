module Make (A : Abi_intf.S) = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open A
  module Strtbl = Hashtbl

  let struct_tbl = Strtbl.create 32
  let ( ++ ) = Seq.append

  (* Named structs for typedefs *)

  let rec struct_name = function
    (* We match on each type here to allow for nested parametrization like [int foo bar].
       [poly] argument will create a name used for a poly var, ie spell out the generic name *)
    | Trecord (param, Some name, _) | Tvariant (param, name, _) ->
        let some t = match t with Tpoly _ -> "generic" | t -> struct_name t in
        String.concat "_" (name :: List.map some param)
    | Trecord (_, None, fs) ->
        let ts = Array.to_list fs |> List.map (fun f -> struct_name f.ftyp) in
        "tuple_" ^ String.concat "_" ts
    | t -> string_of_type t

  (** For functions, when passed as parameter, we convert it to a closure ptr
   to later cast to the correct types. At the application, we need to
   get the correct type though to cast it back. *)
  let rec get_lltype_def = function
    | Tint -> int_t
    | Tbool -> bool_t
    | Tu8 -> u8_t
    | Tfloat -> float_t
    | Ti32 -> i32_t
    | Tf32 -> f32_t
    | Tunit -> unit_t
    | Tpoly _ -> generic_t |> Llvm.pointer_type
    | (Trecord _ as t) | (Tvariant _ as t) -> get_struct t
    | Tfun (params, ret, kind) ->
        typeof_func ~param:false ~decl:false (params, ret, kind) |> fst
    | Traw_ptr t | Tarray t -> get_lltype_def t |> Llvm.pointer_type

  and get_lltype_param mut = function
    | ( Tint | Tbool | Tu8 | Tfloat | Ti32 | Tf32 | Tunit | Tpoly _ | Traw_ptr _
      | Tarray _ ) as t ->
        let t = get_lltype_def t in
        if mut then t |> Llvm.pointer_type else t
    | Tfun (params, ret, kind) ->
        typeof_func ~param:true ~decl:false (params, ret, kind) |> fst
    | (Trecord _ | Tvariant _) as t -> (
        match pkind_of_typ mut t with
        | Boxed -> get_lltype_def t |> Llvm.pointer_type
        | Unboxed size -> lltype_unboxed size)

  and get_lltype_field = function
    | ( Tint | Tbool | Tu8 | Tfloat | Ti32 | Tf32 | Tunit | Tpoly _ | Traw_ptr _
      | Tarray _ | Trecord _ | Tvariant _ ) as t ->
        get_lltype_def t
    | Tfun (params, ret, kind) ->
        (* Not really a paramater, but is treated equally (ptr to closure struct) *)
        typeof_func ~param:true ~decl:false (params, ret, kind) |> fst

  and get_lltype_global = function
    | ( Tint | Tbool | Tu8 | Tfloat | Ti32 | Tf32 | Tunit | Tpoly _ | Traw_ptr _
      | Tarray _ | Trecord _ | Tvariant _ ) as t ->
        get_lltype_def t
    | Tfun _ -> closure_t

  (* LLVM type of closure struct and records *)
  and typeof_aggregate agg =
    Array.map get_lltype_field agg |> Llvm.struct_type context

  and typeof_closure agg =
    Array.map
      (fun cl ->
        match cl.cltyp with
        | (Trecord _ | Tvariant _) when cl.clmut ->
            get_lltype_field cl.cltyp |> Llvm.pointer_type
        | typ -> get_lltype_field typ)
      agg
    |> Llvm.struct_type context

  and typeof_func ~param ~decl (params, ret, kind) =
    if param then closure_t |> fun t -> (Llvm.pointer_type t, [])
    else
      (* When [get_lltype] is called on a function, we handle the dynamic case where
         a function or closure is being passed to another function.
         If a record is returned, we allocate it at the caller site and
         pass it as first argument to the function *)
      let prefix, ret_t =
        if is_struct ret then
          match pkind_of_typ false ret with
          | Boxed -> (Seq.return (get_lltype_param false ret), unit_t)
          | Unboxed size -> (Seq.empty, lltype_unboxed size)
        else (Seq.empty, get_lltype_param false ret)
      in

      let suffix =
        (* A closure needs an extra parameter for the environment  *)
        if decl then
          match kind with Closure _ -> Seq.return voidptr_t | _ -> Seq.empty
        else Seq.return voidptr_t
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
            incr i;
            match pkind_of_typ p.pmut typ with
            | Unboxed (Two_params (fst, snd)) ->
                (* snd before fst b/c we rev later *)
                lltype_unbox snd :: lltype_unbox fst :: ps
            | Boxed when is_aggregate typ ->
                if not p.pmut then byvals := (!i, typ) :: !byvals;
                get_lltype_param p.pmut typ :: ps
            | _ -> get_lltype_param p.pmut typ :: ps)
          [] params
        |> List.rev |> List.to_seq
        |> fun seq -> prefix ++ seq ++ suffix |> Array.of_seq
      in
      let ft = Llvm.function_type ret_t params_t in
      (ft, !byvals)

  and to_named_typedefs name = function
    | Trecord (_, _, labels) ->
        let t = Llvm.named_struct_type context name in
        let lltyp =
          Array.map (fun (f : field) -> f.ftyp) labels
          |> typeof_aggregate |> Llvm.struct_element_types
        in
        Llvm.struct_set_body t lltyp false;
        Strtbl.replace struct_tbl name t;
        t
    | Tvariant (_, _, ctors) -> (
        (* We loop throug each ctor and then we use the largest one as a
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
end
