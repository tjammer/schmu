module type S = sig
  open Llvm_types
  open Cleaned_types

  val dummy_fn_value : llvar
  val declare_function : c_linkage:bool -> string -> typ -> llvar
  val add_closure : llvar Vars.t -> llvar -> bool -> fun_kind -> llvar Vars.t

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
    Llvm_types.param ->
    closed list ->
    llvar ->
    string ->
    Monomorph_tree.alloca ->
    llvar

  val bring_default : llvar -> Llvm.llvalue
  val bring_default_var : llvar -> llvar
  val store_or_copy : src:llvar -> dst:Llvm.llvalue -> unit
  val is_prealloc : Monomorph_tree.allocas ref -> bool
  val no_prealloc : Monomorph_tree.allocas ref

  val get_mono_func :
    llvar -> Llvm_types.param -> Monomorph_tree.call_name -> llvar

  val box_const : Llvm_types.param -> llvar -> llvar
  val pass_value : bool -> llvar -> Llvm.llvalue * Llvm.llvalue option
  val func_to_closure : Llvm_types.param -> llvar -> llvar
  val get_closure_item : closed -> Llvm.llvalue -> bool -> llvar

  val get_prealloc :
    Monomorph_tree.allocas ->
    Llvm_types.param ->
    Llvm.lltype ->
    string ->
    Llvm.llvalue

  val default_kind : typ -> value_kind
  val get_index : int -> bool -> typ -> int
  val name_of_alloc_param : int -> string
  val name_of_alloc_cookie : int -> string
  val tailrec_store : src:llvar -> dst:Llvm.llvalue -> unit
  val set_struct_field : llvar -> Llvm.llvalue -> unit
  val realloc : Llvm.llvalue -> size:Llvm.llvalue -> Llvm.llvalue
  val malloc : size:Llvm.llvalue -> Llvm.llvalue
  val alloca : Llvm_types.param -> Llvm.lltype -> string -> Llvm.llvalue
  val get_const_string : string -> Llvm.llvalue
  val free_var : Llvm.llvalue -> Llvm.llvalue
  val fmt_str : llvar -> string * Llvm.llvalue
  val set_in_init : bool -> unit

  val assert_fail :
    text:string -> file:string -> line:int -> func:string -> Llvm.llvalue

  val get_snippet : Ast.loc -> string

  (* For reuse in arr.ml *)
  val var_index : llvar -> llvar
  val var_data : llvar -> typ -> llvar
  val tail_decr_param : Llvm_types.param -> llvar -> int -> bool -> unit
  val tail_return : Llvm_types.param -> param list -> int -> unit
end

module Make
    (T : Lltypes_intf.S)
    (A : Abi_intf.S)
    (Arr : Arr_intf.S)
    (Auto : Autogen_intf.S) =
struct
  open Cleaned_types
  open Llvm_types
  open Size_align
  open T
  open A
  module Strtbl = Hashtbl

  external add_byval : Llvm.llvalue -> int -> Llvm.lltype -> unit
    = "LlvmAddByvalAttr"

  let string_tbl = Strtbl.create 64
  let src_tbl = Hashtbl.create 64
  let in_init = ref false

  let dummy_fn_value =
    (* When we need something in the env for a function which will only be called
       in a monomorphized version *)
    {
      typ = Tunit;
      value = Llvm.const_int i32_t (-1);
      lltyp = i32_t;
      kind = Ptr;
    }

  let bb = Llvm.build_bitcast

  let default_kind = function
    | Tint | Tbool | Tfloat | Tu8 | Ti32 | Tf32 | Tunit | Traw_ptr _ | Tarray _
      ->
        Imm
    | Trecord _ | Tvariant _ | Tfun _ | Tpoly _ -> Ptr

  let bring_default value =
    if is_struct value.typ then value.value
    else
      match value.kind with
      | Const_ptr ->
          assert (Llvm.is_global_constant value.value);
          Llvm.global_initializer value.value |> Option.get
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
        let dstptr = bb dst voidptr_t "" builder in
        let retptr = bb src.value voidptr_t "" builder in
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
    let voidptr = bb ptr voidptr_t "" builder in
    let ret =
      Llvm.build_call (Lazy.force realloc_decl) [| voidptr; size |] "" builder
    in
    bb ret (Llvm.type_of ptr) "" builder

  (* Frees a single pointer *)
  let free_var ptr =
    let free_decl =
      lazy
        Llvm.(
          let ft = function_type unit_t [| voidptr_t |] in
          declare_function "free" ft the_module)
    in

    let ptr = bb ptr voidptr_t "" builder in

    Llvm.build_call (Lazy.force free_decl) [| ptr |] "" builder

  let get_const_string s =
    match Strtbl.find_opt string_tbl s with
    | Some ptr -> ptr
    | None ->
        let u8 i = Llvm.const_int u8_t i in
        let thing =
          String.to_seq s |> Seq.map Char.code |> fun sq ->
          Seq.append sq (Seq.return 0)
          |> Seq.map u8 |> Array.of_seq
          |> Llvm.const_array (Llvm.array_type u8_t (String.length s + 1))
        in
        let rf = 1 in
        let arr =
          List.to_seq [ rf; String.length s; Int.max 1 (String.length s) ]
          |> Seq.map (Llvm.const_int int_t)
          |> (fun s -> Seq.append s (Seq.return thing))
          |> Array.of_seq
        in

        let content = Llvm.const_struct context arr in
        let value = Llvm.define_global "" content the_module in
        Llvm.set_global_constant true value;
        Llvm.set_linkage Llvm.Linkage.Private value;
        Llvm.set_unnamed_addr true value;
        let lltyp = get_lltype_def (Tarray Tu8) in
        let ptr = Llvm.const_bitcast value lltyp in

        Strtbl.add string_tbl s ptr;
        ptr

  let fmt_str value =
    let v = bring_default_var value in
    match value.typ with
    | Tint -> ("%li", v.value)
    | Tfloat -> ("%.9g", v.value)
    | Tarray Tu8 ->
        let ptr = Arr.array_data [ v ] in
        ("%s", ptr.value)
    | Tbool ->
        let start_bb = Llvm.insertion_block builder in
        let parent = Llvm.block_parent start_bb in

        let false_bb = Llvm.append_block context "free" parent in
        let cont_bb = Llvm.append_block context "cont" parent in

        ignore (Llvm.build_cond_br v.value cont_bb false_bb builder);

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
        let typ = Tarray Tu8 in
        let lltyp = get_lltype_def typ in
        let v = { value; typ; lltyp; kind = Imm } in
        let ptr = Arr.array_data [ v ] in
        ("%s", ptr.value)
    | Tu8 -> ("%c", v.value)
    | Ti32 -> ("%i", v.value)
    | Tf32 -> (".9gf", v.value)
    | _ ->
        print_endline (show_typ value.typ);
        failwith "Internal Error: Impossible string format"

  (* use [__assert_fail] from libc *)
  let assert_fail ~text ~file ~line ~func =
    let assert_fail_decl =
      lazy
        Llvm.(
          let cptr = u8_t |> pointer_type in
          let ft = function_type unit_t [| cptr; cptr; i32_t; cptr |] in
          declare_function "__assert_fail" ft the_module)
    in

    let typ = Tarray Tu8 in
    let lltyp = get_lltype_def typ in
    let d txt =
      let value = get_const_string txt in
      (Arr.array_data [ { value; kind = Imm; typ; lltyp } ]).value
    in
    let args = [| d text; d file; Llvm.const_int i32_t line; d func |] in
    ignore (Llvm.build_call (Lazy.force assert_fail_decl) args "" builder);
    Llvm.build_unreachable builder

  let get_snippet (lbeg, lend) =
    let open Lexing in
    (* Don't print the string 'assert ' *)
    let start = lbeg.pos_cnum + 7 in
    match Hashtbl.find_opt src_tbl lbeg.pos_fname with
    | Some (Some str) -> String.sub str start (lend.pos_cnum - start)
    | Some None -> "file not found"
    | None -> (
        (* Try to open file and read into lexbuf *)
        try
          let ic = In_channel.open_bin lbeg.pos_fname in
          let str = In_channel.input_all ic in
          In_channel.close ic;
          Hashtbl.add src_tbl lbeg.pos_fname (Some str);
          String.sub str start (lend.pos_cnum - start)
        with _ ->
          Hashtbl.replace src_tbl lbeg.pos_fname None;
          "file not found")

  let llval_of_size size = Llvm.const_int int_t size

  let set_struct_field value ptr =
    match value.typ with
    | Trecord _ | Tvariant _ | Tfun _ ->
        if value.value <> ptr then
          let size = sizeof_typ value.typ |> llval_of_size in
          memcpy ~dst:ptr ~src:value ~size
    | _ -> ignore (Llvm.build_store (bring_default value) ptr builder)

  let mangle name = function C -> name | Schmu n -> n ^ "_" ^ name

  let declare_function ~c_linkage name = function
    | Tfun (params, ret, kind) as typ ->
        let ft, byvals = typeof_func ~decl:true (params, ret, kind) in
        let value = Llvm.declare_function name ft the_module in
        if c_linkage then
          List.iter
            (fun (i, typ) -> add_byval value i (get_lltype_def typ))
            byvals;
        let llvar = { value; typ; lltyp = ft; kind = Imm } in
        llvar
    | _ ->
        prerr_endline name;
        failwith "Internal Error: declaring non-function"

  let alloca param typ str =
    (* If a builder is present, the alloca will be moved out of a loop,
       so we don't blow up the stack *)
    let builder =
      match param.rec_block with Some r -> r.entry | _ -> builder
    in
    if !in_init then (
      let null = Llvm.const_int int_t 0 in
      let value =
        Llvm.define_global "" (Llvm.const_bitcast null typ) the_module
      in
      Llvm.(set_linkage Linkage.Internal value);
      value)
    else Llvm.build_alloca typ str builder

  let get_prealloc allocref param lltyp str =
    match (allocref, param.alloca) with
    | Monomorph_tree.Preallocated, Some value -> value
    | _ -> alloca param lltyp str

  let box_const param var =
    let value = alloca param (get_lltype_def var.typ) "boxconst" in
    ignore (Llvm.build_store var.value value builder);
    { var with value }

  let is_prealloc allocref =
    match !allocref with Monomorph_tree.Preallocated -> true | _ -> false

  let assoc_contains_ref assoc =
    List.fold_left (fun b c -> b || contains_allocation c.cltyp) false assoc

  let get_closure_item cl item_ptr upward =
    let typ = cl.cltyp in
    let value, lltyp =
      match typ with
      (* No need for C interop with closures *)
      | (Trecord _ | Tvariant _ | Tfun _) when cl.clmut && not upward ->
          (* Mutable records are passed as pointers into the env *)
          let value = Llvm.build_load item_ptr cl.clname builder in

          (value, get_lltype_def typ |> Llvm.pointer_type)
      | Trecord _ | Tvariant _ | Tfun _ ->
          (* For records we want a ptr so that gep and memcpy work *)
          (item_ptr, get_lltype_def typ |> Llvm.pointer_type)
      | _ when cl.clmut && upward ->
          (item_ptr, get_lltype_def typ |> Llvm.pointer_type)
      | _ ->
          let value = Llvm.build_load item_ptr cl.clname builder in
          (value, get_lltype_def typ)
    in
    let kind = if cl.clmut then Ptr else default_kind typ in
    { value; typ; lltyp; kind }

  let gen_closure_obj param assoc func name allocref =
    let clsr_struct = get_prealloc !allocref param closure_t name in

    let upward = is_prealloc allocref in

    (* Add function ptr *)
    let fun_ptr = Llvm.build_struct_gep clsr_struct 0 "funptr" builder in
    let fun_casted = bb func.value voidptr_t "func" builder in
    ignore (Llvm.build_store fun_casted fun_ptr builder);

    let store_closed_var clsr_ptr i cl =
      let src =
        match Vars.find_opt cl.clname param.vars with
        | Some v -> v
        | None ->
            Llvm.dump_module the_module;
            failwith
              ("Internal Error: Cannot find closed variable: " ^ cl.clname)
      in
      (* TODO use dst as prealloc *)
      let src = if upward then Auto.copy no_param allocref src else src in
      let dst = Llvm.build_struct_gep clsr_ptr i cl.clname builder in
      (match cl.cltyp with
      | (Trecord _ | Tvariant _ | Tfun _) when cl.clmut && not upward ->
          ignore (Llvm.build_store src.value dst builder)
      | Trecord _ | Tvariant _ | Tfun _ ->
          (* For records, we just memcpy
             TODO don't use types here, but type kinds*)
          let size = sizeof_typ cl.cltyp |> Llvm.const_int int_t in
          memcpy ~src ~dst ~size
      | _ when cl.clmut && not upward ->
          ignore (Llvm.build_store src.value dst builder)
      | _ -> ignore (Llvm.build_store (bring_default src) dst builder));
      i + 1
    in

    (* Add closed over vars. If the environment is empty, we pass nullptr *)
    let clsr_ptr =
      match assoc with
      | [] -> Llvm.const_pointer_null voidptr_t
      | assoc ->
          let assoc_type = lltypeof_closure assoc upward in
          let clsr_ptr =
            if upward then
              let size =
                sizeof_typ (typeof_closure assoc) |> Llvm.const_int int_t
              in
              let ptr = malloc ~size in
              bb ptr (Llvm.pointer_type assoc_type) ("clsr_" ^ name) builder
            else alloca param assoc_type ("clsr_" ^ name)
          in
          (* [2] as starting index, because [0] is ctor, and [1] is dtor *)
          ignore (List.fold_left (store_closed_var clsr_ptr) 2 assoc);

          (* Add ctor function *)
          let ctor_ptr = Llvm.build_struct_gep clsr_ptr 0 "ctor" builder in
          let ctor = bb (Auto.get_ctor assoc_type assoc) voidptr_t "" builder in
          Llvm.build_store ctor ctor_ptr builder |> ignore;

          (* Create dtor function if it does not exist yet *)
          let dtor =
            if assoc_contains_ref assoc && upward then
              bb (Auto.get_dtor assoc_type assoc) voidptr_t "" builder
            else Llvm.(const_pointer_null voidptr_t)
          in

          (* Add dtor *)
          let dtor_ptr = Llvm.build_struct_gep clsr_ptr 1 "dtor" builder in
          ignore (Llvm.(build_store dtor dtor_ptr) builder);

          let clsr_casted = bb clsr_ptr voidptr_t "env" builder in
          clsr_casted
    in

    (* Add closure env to struct *)
    let env_ptr = Llvm.build_struct_gep clsr_struct 1 "envptr" builder in
    ignore (Llvm.build_store clsr_ptr env_ptr builder);

    (* Turn simple functions into empty closures, so they are handled correctly
       when passed *)
    { value = clsr_struct; typ = func.typ; lltyp = func.lltyp; kind = Ptr }

  let add_closure vars func upward = function
    | Simple -> vars
    | Closure assoc ->
        let closure_index = (Llvm.params func.value |> Array.length) - 1 in
        let clsr_param = (Llvm.params func.value).(closure_index) in
        let clsr_type = lltypeof_closure assoc upward |> Llvm.pointer_type in
        let clsr_ptr = bb clsr_param clsr_type "clsr" builder in

        let add_closure (env, i) cl =
          let item_ptr = Llvm.build_struct_gep clsr_ptr i cl.clname builder in
          let item = get_closure_item cl item_ptr upward in
          (Vars.add cl.clname item env, i + 1)
        in
        (* [2] as starting index, because [0] is ref count, and [1] is dtor *)
        let env, _ = List.fold_left add_closure (vars, 2) assoc in
        env

  let store_or_copy ~src ~dst =
    if is_struct src.typ then
      if src.value = dst then ()
      else memcpy ~dst ~src ~size:(sizeof_typ src.typ |> llval_of_size)
    else
      (* Simple type *)
      ignore (Llvm.build_store (bring_default src) dst builder)

  let tailrec_store ~src ~dst =
    (* Used to have special handling for mutable vars,
       now we use the same strategy (modify a ptr) for every struct type *)
    ignore (Llvm.build_store src.value dst builder)

  let name_of_alloc_param i = "__" ^ string_of_int i ^ "_alloc"
  let name_of_alloc_cookie i = "__" ^ string_of_int i ^ "_alloc_cookie"

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
      let store dst =
        if mut then tailrec_store ~src ~dst else store_or_copy ~src ~dst
      in
      match src.typ with
      | Trecord _ | Tvariant _ | Tfun _ ->
          let typ = get_lltype_def src.typ |> m in
          let dst = Llvm.build_alloca typ "" builder in
          store dst;
          dst
      | Traw_ptr _ -> failwith "TODO"
      | t ->
          (* Simple type *)
          let typ = get_lltype_def t |> m in
          let dst = Llvm.build_alloca typ "" builder in
          store dst;
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
              let kind = if p.pmut then Ptr else default_kind typ in
              let value = { value; typ; lltyp = get_lltype_def typ; kind } in
              let alloc =
                { value with value = alloca_copy p.pmut value; kind = Ptr }
              in
              let env = Vars.add (name_of_alloc_param i) alloc env in
              let env =
                if contains_allocation typ then (
                  (* Create flag to see if it was set to a temp value *)
                  let cookie = Llvm.build_alloca bool_t "" builder in
                  ignore
                    (Llvm.build_store (Llvm.const_int bool_t 0) cookie builder);
                  let llvar =
                    { value = cookie; lltyp = bool_t; typ = Tbool; kind = Ptr }
                  in
                  Vars.add (name_of_alloc_cookie i) llvar env)
                else env
              in
              (env, i + 1))
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
              let value =
                if p.pmut then Llvm.build_load llvar.value name builder
                else llvar.value
              in
              (* let kind = if p.pmut then Ptr else default_kind typ in *)
              (Vars.add name { llvar with value } env, i + 1))
            (vars, start_index) names params
        in

        (vars, Some { rec_; entry })

  let no_prealloc = Monomorph_tree.(ref (Request { id = -1; lvl = -1 }))

  let pass_function param llvar kind =
    match kind with
    | Simple ->
        (* If a function is passed into [func] we convert it to a closure
           and pass nullptr to env*)
        gen_closure_obj param [] llvar "clstmp" no_prealloc
    | Closure _ ->
        (* This closure is a struct and has an env *)
        llvar

  let func_to_closure vars llvar =
    match (llvar.kind, llvar.typ) with
    | Imm, Tfun (_, _, kind) -> pass_function vars llvar kind
    | _ -> llvar

  (* Get monomorphized function *)
  let get_mono_func func param = function
    | Monomorph_tree.Mono name -> (
        let func = Vars.find name param.vars in
        (* Monomorphized functions are not yet converted to closures *)
        match (func.kind, func.typ) with
        | Imm, Tfun (_, _, Closure assoc) ->
            gen_closure_obj param assoc func "monoclstmp" no_prealloc
        | _ -> func)
    | Concrete name -> Vars.find name param.vars
    | Recursive name -> Vars.find name.call param.vars
    | Default -> func
    | Builtin _ -> failwith "Internal Error: Normally calling a builtin"
    | Inline _ -> failwith "Internal Error: Normally calling an inline func"

  let fun_return name ret =
    match ret.typ with
    | (Trecord _ | Tvariant _ | Tfun _) as t -> (
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

  let tail_decr_param param alloca i mut =
    if contains_allocation alloca.typ then (
      (* Set param to new value, deref the old one if the cookie was set *)
      let v = Vars.find (name_of_alloc_cookie i) param.vars in
      let cookie = Llvm.build_load v.value "" builder in

      let start_bb = Llvm.insertion_block builder in
      let parent = Llvm.block_parent start_bb in

      let decr_bb = Llvm.append_block context "call_decr" parent in
      let cookie_bb = Llvm.append_block context "cookie" parent in
      let cont_bb = Llvm.append_block context "cont" parent in
      ignore (Llvm.build_cond_br cookie decr_bb cookie_bb builder);

      Llvm.position_at_end decr_bb builder;
      let value =
        if mut then Llvm.build_load alloca.value "" builder else alloca.value
      in
      (* let kind = if mut then Ptr else default_kind alloca.typ in *)
      Arr.decr_refcount { alloca with value };
      ignore (Llvm.build_br cont_bb builder);

      Llvm.position_at_end cookie_bb builder;
      ignore (Llvm.build_store (Llvm.const_int bool_t 1) v.value builder);
      ignore (Llvm.build_br cont_bb builder);

      Llvm.position_at_end cont_bb builder)

  let tail_return param params start_index =
    let f i p =
      let i = get_index i p.pmut p.pt in
      let alloca = Vars.find (name_of_alloc_param i) param.vars in

      tail_decr_param param alloca i p.pmut;
      i + 1
    in
    ignore (List.fold_left f start_index params)

  let var_index var =
    let tagptr = Llvm.build_struct_gep var.value 0 "tag" builder in
    let value = Llvm.build_load tagptr "index" builder in
    { value; typ = Ti32; lltyp = i32_t; kind = Imm }

  let var_data var typ =
    let dataptr = Llvm.build_struct_gep var.value 1 "data" builder in
    let ptr_t = get_lltype_def typ |> Llvm.pointer_type in
    let value = bb dataptr ptr_t "" builder in
    { value; typ; lltyp = get_lltype_def typ; kind = Ptr }

  let set_in_init b = in_init := b
end
