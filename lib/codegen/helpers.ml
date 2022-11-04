module type S = sig
  open Llvm_types
  open Cleaned_types

  val ptr_tbl : (int, Llvm.llvalue * typ) Hashtbl.t
  val dummy_fn_value : llvar
  val declare_function : c_linkage:bool -> mangle_kind -> string -> typ -> llvar
  val add_closure : llvar Vars.t -> llvar -> fun_kind -> llvar Vars.t

  val add_params :
    llvar Vars.t ->
    llvar ->
    Monomorph_tree.func_name ->
    string list ->
    param list ->
    int ->
    Monomorph_tree.recurs ->
    llvar Vars.t * rec_block option

  val llval_of_size : int -> Llvm.llvalue
  val memcpy : dst:Llvm.llvalue -> src:llvar -> size:Llvm.llvalue -> unit
  val fun_return : string -> llvar -> Llvm.llvalue

  val gen_closure_obj :
    Llvm_types.param -> closed list -> llvar -> string -> llvar

  val bring_default : llvar -> Llvm.llvalue
  val bring_default_var : llvar -> llvar
  val store_or_copy : src:llvar -> dst:Llvm.llvalue -> unit

  val get_mono_func :
    llvar -> Llvm_types.param -> Monomorph_tree.call_name -> llvar

  val box_const : Llvm_types.param -> llvar -> llvar
  val pass_value : bool -> llvar -> Llvm.llvalue * Llvm.llvalue option
  val func_to_closure : Llvm_types.param -> llvar -> llvar
  val unmangle : mangle_kind -> string -> string

  val get_prealloc :
    Monomorph_tree.allocas ->
    Llvm_types.param ->
    Llvm.lltype ->
    string ->
    Llvm.llvalue

  val default_kind : typ -> value_kind
  val get_index : int -> bool -> typ -> int
  val name_of_alloc_param : int -> string
  val tailrec_store : src:llvar -> dst:Llvm.llvalue -> unit
  val set_struct_field : llvar -> Llvm.llvalue -> unit
  val realloc : Llvm.llvalue -> size:Llvm.llvalue -> Llvm.llvalue
  val malloc : size:Llvm.llvalue -> Llvm.llvalue
  val alloca : Llvm_types.param -> Llvm.lltype -> string -> Llvm.llvalue
  val get_const_string : string -> Llvm.llvalue
  val free_id : int -> unit
  val free : Llvm.llvalue -> Llvm.llvalue
  val fmt_str : llvar -> string * Llvm.llvalue

  (* For reuse in arr.ml *)
  val var_index : llvar -> llvar
  val var_data : llvar -> typ -> llvar
end

module Make (T : Lltypes_intf.S) (A : Abi_intf.S) = struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open T
  open A
  module Strtbl = Hashtbl
  module Ptrtbl = Hashtbl

  external add_byval : Llvm.llvalue -> int -> Llvm.lltype -> unit
    = "LlvmAddByvalAttr"

  let string_tbl = Strtbl.create 64
  let ptr_tbl = Ptrtbl.create 32

  let dummy_fn_value =
    (* When we need something in the env for a function which will only be called
       in a monomorphized version *)
    {
      typ = Tunit;
      value = Llvm.const_int i32_t (-1);
      lltyp = i32_t;
      kind = Ptr;
    }

  let default_kind = function
    | Tint | Tbool | Tfloat | Tu8 | Ti32 | Tf32 | Tunit | Traw_ptr _ | Tarray _
      ->
        Imm
    | Trecord _ | Tvariant _ | Tfun _ | Tpoly _ -> Ptr

  let bring_default value =
    if is_struct value.typ then value.value
    else
      match value.kind with
      | Const_ptr -> Llvm.global_initializer value.value |> Option.get
      | Ptr -> Llvm.build_load value.value "" builder
      | Const | Imm -> value.value

  let bring_default_var v =
    let kind = if is_struct v.typ then v.kind else default_kind v.typ in
    { v with value = bring_default v; kind }

  (* Checks the param kind before calling [unbox_record] *)
  let pass_value mut value =
    (* From record to int *)
    if is_struct value.typ then
      match pkind_of_typ mut value.typ with
      | Unboxed kind -> unbox_record ~kind ~ret:false value
      | Boxed -> (value.value, None)
    else if mut then (value.value, None)
    else (bring_default value, None)

  (* Given two ptr types (most likely to structs), copy src to dst *)
  let memcpy ~dst ~src ~size =
    match src.kind with
    | Const | Imm -> ignore (Llvm.build_store src.value dst builder)
    | Ptr | Const_ptr ->
        let memcpy_decl =
          lazy
            Llvm.(
              (* llvm.memcpy.inline.p0i8.p0i8.i64 *)
              let ft =
                function_type unit_t [| voidptr_t; voidptr_t; int_t; bool_t |]
              in
              declare_function "llvm.memcpy.p0i8.p0i8.i64" ft the_module)
        in
        let dstptr = Llvm.build_bitcast dst voidptr_t "" builder in
        let retptr = Llvm.build_bitcast src.value voidptr_t "" builder in
        let args = [| dstptr; retptr; size; Llvm.const_int bool_t 0 |] in
        ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder)

  let malloc ~size =
    let malloc_decl =
      lazy
        Llvm.(
          let ft = function_type voidptr_t [| int_t |] in
          declare_function "malloc" ft the_module)
    in
    Llvm.build_call (Lazy.force malloc_decl) [| size |] "" builder

  let realloc ptr ~size =
    let realloc_decl =
      lazy
        Llvm.(
          let ft = function_type voidptr_t [| voidptr_t; int_t |] in
          declare_function "realloc" ft the_module)
    in
    let voidptr = Llvm.build_bitcast ptr voidptr_t "" builder in
    let ret =
      Llvm.build_call (Lazy.force realloc_decl) [| voidptr; size |] "" builder
    in
    Llvm.build_bitcast ret (Llvm.type_of ptr) "" builder

  (* Frees a single pointer *)
  let free ptr =
    let free_decl =
      lazy
        Llvm.(
          let ft = function_type unit_t [| voidptr_t |] in
          declare_function "free" ft the_module)
    in

    let ptr = Llvm.build_bitcast ptr voidptr_t "" builder in

    Llvm.build_call (Lazy.force free_decl) [| ptr |] "" builder

  (* Recursively frees a record (which can contain vector and other records) *)
  let rec free_value value = function
    | Trecord ([ t ], Some name, _) when String.equal name "owned_ptr" ->
        (* Free nested owned_ptrs *)
        let ptr = Llvm.build_struct_gep value 0 "" builder in
        let ptr = Llvm.build_load ptr "" builder in

        (if contains_owned_ptr t then
         let len_ptr = Llvm.build_struct_gep value 1 "lenptr" builder in
         (* This should be num_t also, at some point *)
         let len = Llvm.build_load len_ptr "leni" builder in
         let len = Llvm.build_intcast len int_t "len" builder in
         free_owned_ptr_children ptr len t);
        ignore (free ptr)
    | Trecord (_, Some name, _) when String.equal name "string" ->
        let start_bb = Llvm.insertion_block builder in
        let parent = Llvm.block_parent start_bb in

        let owned_bb = Llvm.append_block context "free" parent in
        let cont_bb = Llvm.append_block context "cont" parent in

        let lengthptr = Llvm.build_struct_gep value 1 "" builder in
        let length = Llvm.build_load lengthptr "" builder in
        let cond =
          Llvm.(build_icmp Icmp.Slt length (const_null int_t) "owned") builder
        in
        ignore (Llvm.build_cond_br cond owned_bb cont_bb builder);

        Llvm.position_at_end owned_bb builder;
        let ptr = Llvm.build_struct_gep value 0 "" builder in
        let ptr = Llvm.build_load ptr "" builder in
        ignore (free ptr);
        ignore (Llvm.build_br cont_bb builder);

        Llvm.position_at_end cont_bb builder
    | Trecord (_, Some name, _) when String.equal name "owned_ptr" ->
        failwith "Internal Error: On free: owned_ptr has no type"
    | Trecord (_, _, fields) ->
        Array.iteri
          (fun i (f : field) ->
            if contains_owned_ptr f.ftyp then
              let ptr = Llvm.build_struct_gep value i "" builder in
              free_value ptr f.ftyp)
          fields
    | t ->
        print_endline (show_typ t);
        failwith "freeing records other than owned_ptr TODO"

  and contains_owned_ptr = function
    | Trecord (_, Some name, _) when String.equal name "owned_ptr" -> true
    | Trecord (_, Some name, _) when String.equal name "string" -> true
    | Trecord (_, _, fields) ->
        Array.fold_left
          (fun b (f : field) -> f.ftyp |> contains_owned_ptr || b)
          false fields
    | _ -> false

  and free_owned_ptr_children value len = function
    | Trecord _ as typ ->
        let start_bb = Llvm.insertion_block builder in
        let parent = Llvm.block_parent start_bb in

        (* Simple loop, start at 0 *)
        let cnt = Llvm.build_alloca int_t "cnt" builder in
        ignore (Llvm.build_store (Llvm.const_int int_t 0) cnt builder);

        let rec_bb = Llvm.append_block context "rec" parent in
        let free_bb = Llvm.append_block context "free" parent in
        let cont_bb = Llvm.append_block context "cont" parent in

        ignore (Llvm.build_br rec_bb builder);
        Llvm.position_at_end rec_bb builder;

        (* Check if we are done *)
        let cnt_loaded = Llvm.build_load cnt "" builder in
        let cmp = Llvm.(build_icmp Icmp.Slt) cnt_loaded len "" builder in
        ignore (Llvm.build_cond_br cmp free_bb cont_bb builder);

        Llvm.position_at_end free_bb builder;
        (* The ptr has the correct type, no need to multiply size *)
        let ptr = Llvm.build_gep value [| cnt_loaded |] "" builder in

        free_value ptr typ;
        let one = Llvm.const_int int_t 1 in
        let next = Llvm.build_add cnt_loaded one "" builder in
        ignore (Llvm.build_store next cnt builder);
        ignore (Llvm.build_br rec_bb builder);

        Llvm.position_at_end cont_bb builder
    | t ->
        print_endline (show_typ t);
        failwith "Internal Error: Freeing this type is not supported"

  let free_id id =
    (match Ptrtbl.find_opt ptr_tbl id with
    | Some (value, typ) ->
        (* For propagated mallocs, we don't get the ptr directly but get the struct instead.
           Here, we hardcode for owned_ptr, b/c it's the only thing allocating right now. *)

        (* Free nested owned_ptrs *)
        free_value value typ
    | None ->
        "Internal Error: Cannot find ptr for id " ^ string_of_int id |> failwith);
    Ptrtbl.remove ptr_tbl id

  let get_const_string s =
    match Strtbl.find_opt string_tbl s with
    | Some ptr -> ptr
    | None ->
        let ptr = Llvm.build_global_stringptr s "" builder in
        Strtbl.add string_tbl s ptr;
        ptr

  let fmt_str value =
    let v = bring_default value in
    match value.typ with
    | Tint -> ("%li", v)
    | Tfloat -> ("%.9g", v)
    | Trecord (_, Some name, _) when String.equal name "string" ->
        let ptr = Llvm.build_struct_gep value.value 0 "" builder in
        ("%s", Llvm.build_load ptr "" builder)
    | Tbool ->
        let start_bb = Llvm.insertion_block builder in
        let parent = Llvm.block_parent start_bb in

        let false_bb = Llvm.append_block context "free" parent in
        let cont_bb = Llvm.append_block context "cont" parent in

        ignore (Llvm.build_cond_br v cont_bb false_bb builder);

        Llvm.position_at_end false_bb builder;
        ignore (Llvm.build_br cont_bb builder);
        Llvm.position_at_end cont_bb builder;
        let value =
          Llvm.build_phi
            [
              (get_const_string "true", start_bb);
              (get_const_string "false", false_bb);
            ]
            "" builder
        in
        ("%s", value)
    | Tu8 -> ("%hhi", v)
    | Ti32 -> ("%i", v)
    | Tf32 -> (".9gf", v)
    | _ ->
        print_endline (show_typ value.typ);
        failwith "Internal Error: Impossible string format"

  let llval_of_size size = Llvm.const_int int_t size

  let set_struct_field value ptr =
    match value.typ with
    | Trecord _ | Tvariant _ ->
        if value.value <> ptr then
          let size = sizeof_typ value.typ |> llval_of_size in
          memcpy ~dst:ptr ~src:value ~size
    | _ -> ignore (Llvm.build_store (bring_default value) ptr builder)

  let mangle name = function C -> name | Schmu -> "schmu_" ^ name

  let unmangle kind name =
    match kind with
    | C -> name
    | Schmu ->
        let open String in
        let len = length "schmu_" in
        sub name len (length name - len)

  let declare_function ~c_linkage mangle_kind fun_name = function
    | Tfun (params, ret, kind) as typ ->
        let ft, byvals =
          typeof_func ~param:false ~decl:true (params, ret, kind)
        in
        let name = mangle fun_name mangle_kind in
        let value = Llvm.declare_function name ft the_module in
        if c_linkage then
          List.iter
            (fun (i, typ) -> add_byval value i (get_lltype_def typ))
            byvals;
        let llvar = { value; typ; lltyp = ft; kind = Imm } in
        llvar
    | _ ->
        prerr_endline fun_name;
        failwith "Internal Error: declaring non-function"

  let alloca param typ str =
    (* If a builder is present, the alloca will be moved out of a loop,
       so we don't blow up the stack *)
    let builder =
      match param.rec_block with Some r -> r.entry | _ -> builder
    in
    Llvm.build_alloca typ str builder

  let box_const param var =
    let value = alloca param (get_lltype_def var.typ) "boxconst" in
    ignore (Llvm.build_store var.value value builder);
    { var with value }

  (* [func_to_closure] but for function types *)
  let tfun_to_closure = function
    | Tfun (ps, ret, Simple) -> Tfun (ps, ret, Closure [])
    | t -> t

  let gen_closure_obj param assoc func name =
    let clsr_struct = alloca param closure_t name in

    (* Add function ptr *)
    let fun_ptr = Llvm.build_struct_gep clsr_struct 0 "funptr" builder in
    let fun_casted = Llvm.build_bitcast func.value voidptr_t "func" builder in
    ignore (Llvm.build_store fun_casted fun_ptr builder);

    let store_closed_var clsr_ptr i cl =
      let src = Vars.find cl.clname param.vars in
      let dst = Llvm.build_struct_gep clsr_ptr i cl.clname builder in
      (match cl.cltyp with
      | (Trecord _ | Tvariant _) when cl.clmut ->
          ignore (Llvm.build_store src.value dst builder)
      | Trecord _ | Tvariant _ ->
          (* For records, we just memcpy
             TODO don't use types here, but type kinds*)
          let size = sizeof_typ cl.cltyp |> Llvm.const_int int_t in
          memcpy ~src ~dst ~size
      | _ -> ignore (Llvm.build_store src.value dst builder));
      i + 1
    in

    (* Add closed over vars. If the environment is empty, we pass nullptr *)
    let clsr_ptr =
      match assoc with
      | [] -> Llvm.const_pointer_null voidptr_t
      | assoc ->
          let assoc_type = typeof_closure (Array.of_list assoc) in
          let clsr_ptr = alloca param assoc_type ("clsr_" ^ name) in
          ignore (List.fold_left (store_closed_var clsr_ptr) 0 assoc);

          let clsr_casted =
            Llvm.build_bitcast clsr_ptr voidptr_t "env" builder
          in
          clsr_casted
    in

    (* Add closure env to struct *)
    let env_ptr = Llvm.build_struct_gep clsr_struct 1 "envptr" builder in
    ignore (Llvm.build_store clsr_ptr env_ptr builder);

    (* Turn simple functions into empty closures, so they are handled correctly
       when passed *)
    let typ = tfun_to_closure func.typ in

    { value = clsr_struct; typ; lltyp = func.lltyp; kind = Imm }

  let add_closure vars func = function
    | Simple -> vars
    | Closure assoc ->
        let closure_index = (Llvm.params func.value |> Array.length) - 1 in
        let clsr_param = (Llvm.params func.value).(closure_index) in
        let clsr_type =
          typeof_closure (Array.of_list assoc) |> Llvm.pointer_type
        in
        let clsr_ptr = Llvm.build_bitcast clsr_param clsr_type "clsr" builder in

        let add_closure (env, i) cl =
          let item_ptr = Llvm.build_struct_gep clsr_ptr i cl.clname builder in
          let typ = cl.cltyp in
          let value, lltyp =
            match typ with
            (* No need for C interop with closures *)
            | (Trecord _ | Tvariant _) when cl.clmut ->
                (* Mutable records are passed as pointers into the env *)
                let value = Llvm.build_load item_ptr cl.clname builder in

                (value, get_lltype_def typ |> Llvm.pointer_type)
            | Trecord _ | Tvariant _ ->
                (* For records we want a ptr so that gep and memcpy work *)
                (item_ptr, get_lltype_def typ |> Llvm.pointer_type)
            | _ ->
                let value = Llvm.build_load item_ptr cl.clname builder in
                (value, get_lltype_def typ)
          in
          let item = { value; typ; lltyp; kind = default_kind typ } in
          (Vars.add cl.clname item env, i + 1)
        in
        let env, _ = List.fold_left add_closure (vars, 0) assoc in
        env

  let store_or_copy ~src ~dst =
    if is_struct src.typ then
      if src.value = dst then ()
      else memcpy ~dst ~src ~size:(sizeof_typ src.typ |> llval_of_size)
    else (* Simple type *)
      ignore (Llvm.build_store src.value dst builder)

  let tailrec_store ~src ~dst =
    (* Used to have special handling for mutable vars,
       now we use the same strategy (modify a ptr) for every struct type *)
    ignore (Llvm.build_store src.value dst builder)

  let name_of_alloc_param i = "__" ^ string_of_int i ^ "_alloc"

  let get_prealloc allocref param lltyp str =
    match (allocref, param.alloca) with
    | Monomorph_tree.Preallocated, Some value -> value
    | _ -> alloca param lltyp str

  (* We need to handle the index the same way as [get_value] below *)
  let get_index i mut typ =
    match pkind_of_typ mut typ with Unboxed (Two_params _) -> i + 1 | _ -> i

  (* This adds the function parameters to the env.
     In case the function is tailrecursive, it allocas each parameter in
     the entry block and creates a recursion block which starts off by loading
     each parameter. *)
  let add_params vars f fname names params start_index recursive =
    (* We specially treat the case where a record is passed as two params *)
    let get_value i mut typ =
      match pkind_of_typ mut typ with
      | Unboxed (Two_params _) ->
          let v1 = (Llvm.params f.value).(i) in
          let v2 = (Llvm.params f.value).(i + 1) in
          (maybe_box_record ~snd_val:(Some v2) mut typ v1, i + 1)
      | _ -> (Llvm.param f.value i |> maybe_box_record mut typ, i)
    in

    let add_simple vars =
      (* We simply add to env, no special handling for tailrecursion *)
      List.fold_left2
        (fun (env, i) name p ->
          let typ = p.pt in
          let value, i = get_value i p.pmut typ in
          let kind = if p.pmut then Ptr else default_kind typ in
          let param = { value; typ; lltyp = get_lltype_def typ; kind } in
          Llvm.set_value_name name value;
          (Vars.add name param env, i + 1))
        (vars, start_index) names params
      |> fst
    in

    let alloca_copy mut src =
      let m t = if mut then Llvm.pointer_type t else t in
      match src.typ with
      | Tfun _ ->
          let typ = Llvm.pointer_type closure_t in
          let dst = Llvm.build_alloca typ "" builder in
          tailrec_store ~src ~dst;
          dst
      | (Trecord _ | Tvariant _) as r ->
          let typ = Llvm.pointer_type (get_lltype_def r) in
          let dst = Llvm.build_alloca typ "" builder in
          tailrec_store ~src ~dst;
          dst
      | Traw_ptr _ -> failwith "TODO"
      | t ->
          (* Simple type *)
          let typ = get_lltype_def t |> m in
          let dst = Llvm.build_alloca typ "" builder in
          tailrec_store ~src ~dst;
          dst
    in

    (* If the function is named, we allow recursion *)
    match recursive with
    | Monomorph_tree.Rnone -> (add_simple vars, None)
    | Rnormal ->
        ( Vars.add Monomorph_tree.(fname.call) f vars
          |> (* We also add the user name. This is needed for polymorphic nested functions.
                At the monomorphization stage, the codegen isn't rewritten to it's call name.
             *)
          Vars.add Monomorph_tree.(fname.user) f
          |> add_simple,
          None )
    | Rtail ->
        (* In the entry block, we create a alloca for each parameter.
           These can be set later in tail recursion scenarios.
           Then in a new block, we load from those alloca and set the
           real parameters *)
        let vars =
          List.fold_left2
            (fun (env, i) name p ->
              let typ = p.pt in
              let value, i = get_value i p.pmut typ in
              Llvm.set_value_name name value;
              let value =
                { value; typ; lltyp = get_lltype_def typ; kind = Ptr }
              in
              let alloc = { value with value = alloca_copy p.pmut value } in
              (Vars.add (name_of_alloc_param i) alloc env, i + 1))
            (vars, start_index) names params
          |> fst
        in
        (* Recursion block*)
        let rec_ = Llvm.append_block context "rec" f.value in
        let entry = Llvm.build_br rec_ builder in
        let entry = Llvm.builder_before context entry in
        Llvm.position_at_end rec_ builder;

        (* Add the function itself to env with username *)
        let vars = Vars.add Monomorph_tree.(fname.user) f vars in

        let vars, _ =
          List.fold_left2
            (fun (env, i) name p ->
              let typ = p.pt in
              let i = get_index i p.pmut typ in
              let llvar = Vars.find (name_of_alloc_param i) env in
              let value = Llvm.build_load llvar.value name builder in
              let kind = if p.pmut then Ptr else default_kind typ in
              (Vars.add name { llvar with value; kind } env, i + 1))
            (vars, start_index) names params
        in

        (vars, Some { rec_; entry })

  let pass_function param llvar kind =
    match kind with
    | Simple ->
        (* If a function is passed into [func] we convert it to a closure
           and pass nullptr to env*)
        gen_closure_obj param [] llvar "clstmp"
    | Closure _ ->
        (* This closure is a struct and has an env *)
        llvar

  let func_to_closure vars llvar =
    (* TODO somewhere we don't convert into closure correctly. *)
    if Llvm.type_of llvar.value = (closure_t |> Llvm.pointer_type) then llvar
    else if
      (* Ugly :( *)
      Llvm.type_of llvar.value
      = Llvm.(closure_t |> pointer_type |> pointer_type)
    then
      let value = Llvm.build_load llvar.value "loadfn" builder in
      { llvar with value; kind = Imm }
    else
      match llvar.typ with
      | Tfun (_, _, kind) -> pass_function vars llvar kind
      | _ -> llvar

  (* Get monomorphized function *)
  let get_mono_func func param = function
    | Monomorph_tree.Mono name -> (
        let func = Vars.find name param.vars in
        (* Monomorphized functions are not yet converted to closures *)
        match func.typ with
        | Tfun (_, _, Closure assoc) ->
            gen_closure_obj param assoc func "monoclstmp"
        | Tfun (_, _, Simple) -> func
        | _ -> failwith "Internal Error: What are we applying?")
    | Concrete name -> Vars.find name param.vars
    | Default | Recursive _ -> func
    | Builtin _ -> failwith "Internal Error: Normally calling a builtin"
    | Inline _ -> failwith "Internal Error: Normally calling an inline func"

  let fun_return name ret =
    match ret.typ with
    | (Trecord _ | Tvariant _) as t -> (
        match pkind_of_typ false t with
        | Boxed -> (* Default record case *) Llvm.build_ret_void builder
        | Unboxed kind ->
            let unboxed, _ = unbox_record ~kind ~ret:true ret in
            Llvm.build_ret unboxed builder)
    | Tpoly id when String.equal id "tail" ->
        (* This magic id is used to mark a tailrecursive call *)
        Llvm.build_ret_void builder
    | Tpoly _ -> failwith "Internal Error: Generic return"
    | Tunit ->
        if String.equal name "main" then
          Llvm.(build_ret (const_int int_t 0)) builder
        else Llvm.build_ret_void builder
    | _ ->
        let value =
          match ret.kind with
          | Const_ptr | Ptr -> Llvm.build_load ret.value "" builder
          | _ -> ret.value
        in
        Llvm.build_ret value builder

  let var_index var =
    let tagptr = Llvm.build_struct_gep var.value 0 "tag" builder in
    let value = Llvm.build_load tagptr "index" builder in
    { value; typ = Ti32; lltyp = i32_t; kind = Imm }

  let var_data var typ =
    let dataptr = Llvm.build_struct_gep var.value 1 "data" builder in
    let ptr_t = get_lltype_def typ |> Llvm.pointer_type in
    let value = Llvm.build_bitcast dataptr ptr_t "" builder in
    { value; typ; lltyp = get_lltype_def typ; kind = Ptr }
end
