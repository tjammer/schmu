module type S = sig
  open Llvm_types
  open Cleaned_types

  val dummy_fn_value : llvar
  val declare_function : c_linkage:bool -> string -> typ -> llvar

  val add_closure :
    llvar Vars.t ->
    llvar ->
    closed list ->
    (Mod_id.t, llvar) Hashtbl.t ->
    bool ->
    llvar Vars.t

  val add_params :
    Llvm_types.param ->
    llvar ->
    Monomorph_tree.func_name ->
    (string * Mod_id.t) list ->
    param list ->
    int ->
    Monomorph_tree.recurs ->
    (Mod_id.t, llvar) Hashtbl.t ->
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
    bool ->
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
  val get_const_string : string -> llvar
  val free_var : Llvm.llvalue -> Llvm.llvalue
  val set_in_init : bool -> unit
  val is_in_init : unit -> bool

  val assert_fail :
    text:string ->
    file:string ->
    line:int ->
    func:string ->
    Llvm.llmetadata ->
    Llvm.llvalue

  val get_snippet : Ast.loc -> string

  (* For reuse in arr.ml *)
  val var_index : llvar -> llvar
  val var_data : llvar -> typ -> llvar
  val tail_decr_param : Llvm_types.param -> llvar -> int -> bool -> unit
  val tail_return : Llvm_types.param -> param list -> int -> unit
  val follow_field : llvar -> int -> llvar
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
    { typ = Tunit; value = Llvm.const_null u8_t; lltyp = unit_t; kind = Imm }

  let default_kind = function
    | t when is_struct t -> Ptr
    | Tint | Tbool | Tfloat | Tu8 | Tu16 | Ti32 | Tf32 | Ti8 | Ti16 | Tu32
    | Tunit | Traw_ptr _ | Tarray _ | Trc _ ->
        Imm
    | Trecord _ | Tvariant _ | Tfun _ | Tpoly _ | Tfixed_array _ ->
        failwith "unreachable"

  let bring_default value =
    if is_struct value.typ then value.value
    else
      match value.kind with
      | Const_ptr ->
          assert (Llvm.is_global_constant value.value);
          Llvm.global_initializer value.value |> Option.get
      | Ptr -> Llvm.build_load value.lltyp value.value "" builder
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
        let memcpy =
          lazy
            Llvm.(
              (* llvm.memcpy.inline.p0.p0.i64 *)
              let ft = function_type unit_t [| ptr_t; ptr_t; int_t; bool_t |] in
              (ft, declare_function "llvm.memcpy.p0.p0.i64" ft the_module))
        in
        let args = [| dst; src.value; size; Llvm.const_int bool_t 0 |] in
        let ft, decl = Lazy.force memcpy in
        ignore (Llvm.build_call ft decl args "" builder)

  let malloc ~size =
    let malloc =
      lazy
        Llvm.(
          let ft = function_type ptr_t [| int_t |] in
          (ft, declare_function "malloc" ft the_module))
    in
    let ft, decl = Lazy.force malloc in
    Llvm.build_call ft decl [| size |] "" builder

  let realloc ptr ~size =
    let realloc =
      lazy
        Llvm.(
          let ft = function_type ptr_t [| ptr_t; int_t |] in
          (ft, declare_function "realloc" ft the_module))
    in
    let ft, decl = Lazy.force realloc in
    Llvm.build_call ft decl [| ptr; size |] "" builder

  (* Frees a single pointer *)
  let free_var ptr =
    let free =
      lazy
        Llvm.(
          let ft = function_type unit_t [| ptr_t |] in
          (ft, declare_function "free" ft the_module))
    in
    let ft, decl = Lazy.force free in
    Llvm.build_call ft decl [| ptr |] "" builder

  let get_const_string s =
    let ptr =
      match Strtbl.find_opt string_tbl s with
      | Some ptr -> ptr
      | None ->
          let content = Llvm.const_stringz context s in

          let ptr = Llvm.define_global "" content the_module in
          Llvm.set_global_constant true ptr;
          Llvm.set_linkage Llvm.Linkage.Private ptr;
          Llvm.set_unnamed_addr true ptr;

          Strtbl.add string_tbl s ptr;
          ptr
    in
    let ci = Llvm.const_int int_t in
    (* Negative capacity to signal a borrow value *)
    let value =
      Llvm.const_struct context [| ptr; ci (String.length s); ci (-1) |]
    in
    { value; typ = Tarray Tu8; lltyp = array_t; kind = Const }

  (* use [__assert_fail] from libc *)
  let assert_fail ~text ~file ~line ~func md =
    let assert_fail =
      lazy
        Llvm.(
          let ft = function_type unit_t [| ptr_t; ptr_t; i32_t; ptr_t |] in
          (ft, declare_function "prelude_assert_fail" ft the_module))
    in

    let d txt =
      let value = get_const_string txt in
      Arr.array_data [ value ] |> bring_default
    in
    let args = [| d text; d file; Llvm.const_int i32_t line; d func |] in
    let ft, decl = Lazy.force assert_fail in
    let call = Llvm.build_call ft decl args "" builder in
    Debug.instr_set_debug_loc call (Some md);
    Llvm.build_unreachable builder

  let get_snippet (lbeg, lend) =
    let open Lexing in
    (* Don't print the string 'assert ' *)
    let start = lbeg.pos_cnum + 7 in
    match Hashtbl.find_opt src_tbl lbeg.pos_fname with
    | Some (Some str) -> String.sub str start (lend.pos_cnum - start - 1)
    | Some None -> "file not found"
    | None -> (
        (* Try to open file and read into lexbuf *)
        try
          let ic = In_channel.open_bin lbeg.pos_fname in
          let str = In_channel.input_all ic in
          In_channel.close ic;
          Hashtbl.add src_tbl lbeg.pos_fname (Some str);
          String.sub str start (lend.pos_cnum - start - 1)
        with _ ->
          Hashtbl.replace src_tbl lbeg.pos_fname None;
          "file not found")

  let llval_of_size size = Llvm.const_int int_t size

  let set_struct_field value ptr =
    match value.typ with
    | t when is_struct t ->
        if value.value <> ptr then
          let size = sizeof_typ value.typ |> llval_of_size in
          memcpy ~dst:ptr ~src:value ~size
    | Tunit -> ()
    | _ -> ignore (Llvm.build_store (bring_default value) ptr builder)

  let mangle name = function C -> name | Schmu n -> n ^ "_" ^ name
  let noalias_attr = lazy (Llvm.create_enum_attr context "noalias" 0L)

  let declare_function ~c_linkage name = function
    | Tfun (params, ret, kind) as typ ->
        let ft, byvals, noaliases =
          typeof_func ~decl:true (params, ret, kind)
        in
        let value = Llvm.declare_function name ft the_module in
        if c_linkage then
          List.iter
            (fun (i, typ) -> add_byval value i (get_lltype_def typ))
            byvals;
        (* Hopefully [noalias] on return param does not mess with C ABI *)
        List.iter
          (fun i ->
            Llvm.(
              add_function_attr value (Lazy.force noalias_attr)
                (AttrIndex.Param i)))
          noaliases;
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
      if is_struct typ && cl.clmut && not upward then
        (* Mutable records are passed as pointers into the env *)
        let value = Llvm.build_load ptr_t item_ptr cl.clname builder in

        (value, get_lltype_def typ)
      else if is_struct typ then
        (* For records we want a ptr so that gep and memcpy work *)
        (item_ptr, get_lltype_def typ)
      else if cl.clmut && upward then
        (* For upward closures, the mutable value is stored inside the closure
           directly and does not point to some outer value. *)
        (item_ptr, get_lltype_def typ)
      else
        let lltyp = get_lltype_def typ in
        let load_type = if cl.clmut then ptr_t else lltyp in
        let value = Llvm.build_load load_type item_ptr cl.clname builder in
        (value, lltyp)
    in
    let kind = if cl.clmut then Ptr else default_kind typ in
    { value; typ; lltyp; kind }

  let no_prealloc = Monomorph_tree.(ref (Request { id = -1; lvl = -1 }))

  let gen_closure_obj param assoc func name allocref upward =
    let clsr_struct = get_prealloc !allocref param closure_t name in

    (* Add function ptr *)
    let fun_ptr =
      Llvm.build_struct_gep closure_t clsr_struct 0 "funptr" builder
    in
    ignore (Llvm.build_store func.value fun_ptr builder);

    let store_closed_var lltyp clsr_ptr i cl =
      match cl.cltyp with
      | Tunit -> i
      | _ ->
          let src =
            match Vars.find_opt cl.clname param.vars with
            | Some v -> (
                (* Copied from gen_var. Not all closures might be created yet *)
                match (v.kind, v.typ) with
                | Imm, Tfun (_, _, Closure) ->
                    failwith "this case. Don't know the closure env"
                    (* gen_closure_obj param assoc v "monoclstmp" no_prealloc *)
                    (*   upward *)
                | _ -> v)
            | None ->
                Llvm.dump_module the_module;
                failwith
                  ("Internal Error: Cannot find closed variable: " ^ cl.clname)
          in
          let dst = Llvm.build_struct_gep lltyp clsr_ptr i cl.clname builder in
          let src =
            if upward && cl.clcopy then
              Auto.copy { no_param with alloca = Some dst } allocref src
            else src
          in
          if is_struct cl.cltyp && cl.clmut && not upward then
            ignore (Llvm.build_store src.value dst builder)
          else if is_struct cl.cltyp then
            (* For records, we just memcpy *)
            let size = sizeof_typ cl.cltyp |> Llvm.const_int int_t in
            memcpy ~src ~dst ~size
          else if cl.clmut && not upward then
            ignore (Llvm.build_store src.value dst builder)
          else ignore (Llvm.build_store (bring_default src) dst builder);
          i + 1
    in

    (* Add closed over vars. If the environment is empty, we pass nullptr *)
    let clsr_ptr =
      match assoc with
      | [] -> Llvm.const_pointer_null ptr_t
      | assoc when is_only_units assoc -> Llvm.const_pointer_null ptr_t
      | assoc ->
          let assoc_type = lltypeof_closure assoc upward in
          let clsr_ptr =
            if upward then
              let size =
                sizeof_typ (typeof_closure assoc) |> Llvm.const_int int_t
              in
              malloc ~size
            else alloca param assoc_type ("clsr_" ^ name)
          in
          (* [2] as starting index, because [0] is ctor, and [1] is dtor *)
          ignore (List.fold_left (store_closed_var assoc_type clsr_ptr) 2 assoc);

          (* Add ctor function *)
          let ctor_ptr =
            Llvm.build_struct_gep assoc_type clsr_ptr 0 "ctor" builder
          in
          let ctor = Auto.get_ctor assoc_type assoc upward in
          Llvm.build_store ctor ctor_ptr builder |> ignore;

          (* Create dtor function if it does not exist yet *)
          let dtor =
            if assoc_contains_ref assoc && upward then
              Auto.get_dtor assoc_type assoc
            else Llvm.(const_pointer_null ptr_t)
          in

          (* Add dtor *)
          let dtor_ptr =
            Llvm.build_struct_gep assoc_type clsr_ptr 1 "dtor" builder
          in
          ignore (Llvm.(build_store dtor dtor_ptr) builder);

          clsr_ptr
    in

    (* Add closure env to struct *)
    let env_ptr =
      Llvm.build_struct_gep closure_t clsr_struct 1 "envptr" builder
    in
    ignore (Llvm.build_store clsr_ptr env_ptr builder);

    (* Turn simple functions into empty closures, so they are handled correctly
       when passed *)
    { value = clsr_struct; typ = func.typ; lltyp = func.lltyp; kind = Ptr }

  let add_closure vars func closed free_tbl upward =
    match closed with
    | [] -> vars
    | assoc when is_only_units assoc ->
        List.fold_left
          (fun vars cl -> Vars.add cl.clname dummy_fn_value vars)
          vars assoc
    | assoc ->
        let closure_index = (Llvm.params func.value |> Array.length) - 1 in
        let clsr_param = (Llvm.params func.value).(closure_index) in
        let clsr_type = lltypeof_closure assoc upward in

        let add_closure (env, i) cl =
          match cl.cltyp with
          | Tunit ->
              (* Unit types are not part of the closure struct *)
              (Vars.add cl.clname dummy_fn_value env, i)
          | _ ->
              let item_ptr =
                Llvm.build_struct_gep clsr_type clsr_param i cl.clname builder
              in
              let item = get_closure_item cl item_ptr upward in

              (* Add moved closed variables to free table so we can properly
                 free them. *)
              (match cl.clmoved with
              | Some id -> Hashtbl.replace free_tbl id item
              | None -> ());
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
      match src.typ with
      | Tunit -> ()
      | _ ->
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
  let add_params param f fname names params start_index recursive free_tbl =
    let vars = param.vars in
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
        (fun (env, i) (name, id) p ->
          let typ = p.pt in
          match typ with
          | Tunit -> (Vars.add name dummy_fn_value env, i)
          | _ ->
              let value, i = get_value i p.pmut typ in
              let kind = if p.pmut then Ptr else default_kind typ in
              let param = { value; typ; lltyp = get_lltype_def typ; kind } in
              Llvm.set_value_name name value;
              (* Add mallocs to free tbl so we can find them for freeing *)
              Hashtbl.replace free_tbl id param;
              (Vars.add name param env, i + 1))
        (vars, start_index) names params
      |> fst
    in

    let alloca_copy mut src =
      let m t = if mut then ptr_t else t in
      let store dst =
        if mut then tailrec_store ~src ~dst else store_or_copy ~src ~dst
      in
      let typ = get_lltype_def src.typ |> m in
      let dst = Llvm.build_alloca typ "" builder in
      store dst;
      dst
    in

    (* If the function is named, we allow recursion *)
    match recursive with
    | Monomorph_tree.Rnone -> (add_simple vars, None)
    | Rnormal ->
        (* If the recursive function is an env, we construct the closure for
           potential recursive calls. *)
        let f =
          match f.typ with
          | Tfun (_, _, Closure) ->
              let clsr_struct = alloca param closure_t "reccls" in
              let fun_ptr =
                Llvm.build_struct_gep closure_t clsr_struct 0 "funptr" builder
              in
              ignore (Llvm.build_store f.value fun_ptr builder);
              let closure_index = (Llvm.params f.value |> Array.length) - 1 in
              let clsr_param = (Llvm.params f.value).(closure_index) in
              let env_ptr =
                Llvm.build_struct_gep closure_t clsr_struct 1 "envptr" builder
              in
              ignore (Llvm.build_store clsr_param env_ptr builder);

              (* The closure was just alloca'd so it's a pointer *)
              { f with value = clsr_struct; kind = Ptr }
          | _ -> f
        in
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
            (fun (env, i) (name, _) p ->
              let typ = p.pt in
              match typ with
              | Tunit -> (env, i)
              | _ ->
                  let value, i = get_value i p.pmut typ in
                  Llvm.set_value_name name value;
                  let kind = if p.pmut then Ptr else default_kind typ in
                  let value =
                    { value; typ; lltyp = get_lltype_def typ; kind }
                  in
                  let alloc =
                    { value with value = alloca_copy p.pmut value; kind = Ptr }
                  in
                  let env = Vars.add (name_of_alloc_param i) alloc env in
                  let env =
                    if contains_allocation typ then (
                      (* Create flag to see if it was set to a temp value *)
                      let cookie = Llvm.build_alloca bool_t "" builder in
                      ignore
                        (Llvm.build_store (Llvm.const_int bool_t 0) cookie
                           builder);
                      let value = cookie and lltyp = bool_t in
                      let llvar = { value; lltyp; typ = Tbool; kind = Ptr } in
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
            (fun (env, i) (name, _) p ->
              let typ = p.pt in
              match typ with
              | Tunit -> (Vars.add name dummy_fn_value env, i)
              | _ ->
                  let i = get_index i p.pmut typ in
                  let llvar = Vars.find (name_of_alloc_param i) env in
                  let value =
                    if p.pmut then
                      (* Mutable values point to another pointer *)
                      Llvm.build_load ptr_t llvar.value name builder
                    else llvar.value
                  in
                  (Vars.add name { llvar with value } env, i + 1))
            (vars, start_index) names params
        in

        (vars, Some { rec_; entry })

  let pass_function param llvar kind =
    match kind with
    | Simple ->
        (* If a function is passed into [func] we convert it to a closure
           and pass nullptr to env*)
        gen_closure_obj param [] llvar "clstmp" no_prealloc false
    | Closure ->
        (* This closure is a struct and has an env *)
        llvar

  let func_to_closure vars llvar =
    match (llvar.kind, llvar.typ) with
    | Imm, Tfun (_, _, kind) -> pass_function vars llvar kind
    | _ -> llvar

  (* Get monomorphized function *)
  let get_mono_func func param = function
    | Monomorph_tree.Mono (name, _upward) -> (
        let func = Vars.find name param.vars in
        (* Monomorphized functions are not yet converted to closures *)
        match (func.kind, func.typ) with
        | Imm, Tfun (_, _, Closure) ->
            failwith "monoclstmp again"
            (* gen_closure_obj param assoc func "monoclstmp" no_prealloc !upward *)
        | _ -> func)
    | Concrete name -> Vars.find name param.vars
    | Recursive name -> Vars.find name.call param.vars
    | Default -> func
    | Builtin _ -> failwith "Internal Error: Normally calling a builtin"
    | Inline _ -> failwith "Internal Error: Normally calling an inline func"

  let fun_return name ret =
    match ret.typ with
    | Tpoly id when String.equal id "tail" ->
        (* This magic id is used to mark a tailrecursive call *)
        Llvm.build_ret_void builder
    | Tpoly _ -> failwith "Internal Error: Generic return"
    | t when is_struct t -> (
        match pkind_of_typ false t with
        | Boxed -> (* Default record case *) Llvm.build_ret_void builder
        | Unboxed kind ->
            let unboxed, _ = unbox_record ~kind ~ret:true ret in
            Llvm.build_ret unboxed builder)
    | Tunit ->
        if String.equal name "main" then
          Llvm.(build_ret (const_int int_t 0)) builder
        else Llvm.build_ret_void builder
    | _ ->
        let value =
          match ret.kind with
          | Const_ptr | Ptr -> Llvm.build_load ret.lltyp ret.value "" builder
          | _ -> ret.value
        in
        Llvm.build_ret value builder

  let tail_decr_param param alloca i mut =
    if contains_allocation alloca.typ then (
      (* Set param to new value, deref the old one if the cookie was set *)
      let v = Vars.find (name_of_alloc_cookie i) param.vars in
      let cookie = Llvm.build_load v.lltyp v.value "" builder in

      let start_bb = Llvm.insertion_block builder in
      let parent = Llvm.block_parent start_bb in

      let decr_bb = Llvm.append_block context "call_decr" parent in
      let cookie_bb = Llvm.append_block context "cookie" parent in
      let cont_bb = Llvm.append_block context "cont" parent in
      ignore (Llvm.build_cond_br cookie decr_bb cookie_bb builder);

      Llvm.position_at_end decr_bb builder;
      let value =
        (* Mutable values are always pointed to *)
        if mut then Llvm.build_load ptr_t alloca.value "" builder
        else alloca.value
      in
      (* let kind = if mut then Ptr else default_kind alloca.typ in *)
      (match alloca.typ with
      | Tfun _ ->
          (* Function parameters which originate from the function cannot be
             'upward' and thus have their env allocated on the stack. We must not
             try to free them. *)
          ()
      | _ -> Auto.free param { alloca with value });
      ignore (Llvm.build_br cont_bb builder);

      Llvm.position_at_end cookie_bb builder;
      ignore (Llvm.build_store (Llvm.const_int bool_t 1) v.value builder);
      ignore (Llvm.build_br cont_bb builder);

      Llvm.position_at_end cont_bb builder)

  let tail_return param params start_index =
    let f i p =
      match p.pt with
      | Tunit -> i
      | _ ->
          let i = get_index i p.pmut p.pt in
          let alloca = Vars.find (name_of_alloc_param i) param.vars in

          if not p.pmoved then tail_decr_param param alloca i p.pmut;
          i + 1
    in
    ignore (List.fold_left f start_index params)

  let var_index var =
    let value =
      match var.kind with
      | Const_ptr | Ptr ->
          let tagptr =
            Llvm.build_struct_gep var.lltyp var.value 0 "tag" builder
          in
          Llvm.build_load i32_t tagptr "index" builder
      | Const -> Llvm.(const_extractelement var.value (const_int i32_t 0))
      | Imm -> failwith "Did not expect Imm in var_index"
    in
    { value; typ = Ti32; lltyp = i32_t; kind = Imm }

  let var_data var typ =
    match typ with
    | Tunit -> dummy_fn_value
    | _ ->
        let value =
          Llvm.build_struct_gep var.lltyp var.value 1 "data" builder
        in
        { value; typ; lltyp = get_lltype_def typ; kind = Ptr }

  let set_in_init b = in_init := b
  let is_in_init () = !in_init

  let follow_field value index =
    let find_real_index fs =
      (* Without unit fields *)
      let i = ref None in
      Array.fold_left
        (fun (acc, tempi) f ->
          if tempi = index then i := Some acc;
          ((match f.ftyp with Tunit -> acc | _ -> acc + 1), tempi + 1))
        (0, 0) fs
      |> ignore;
      Option.get !i
    in

    let typ, index =
      match value.typ with
      | Trecord (_, Rec_folded, _) -> failwith "unreachable"
      | Trecord (_, (Rec_not fields | Rec_top fields), _) ->
          (fields.(index).ftyp, find_real_index fields)
      | _ ->
          print_endline (show_typ value.typ);
          failwith "Internal Error: No record in fields"
    in

    match typ with
    | Tunit -> dummy_fn_value
    | typ ->
        let lltyp = get_lltype_def value.typ in
        let value, kind =
          match value.kind with
          | Const_ptr | Ptr ->
              let p =
                Llvm.build_struct_gep lltyp value.value index "" builder
              in
              (* In case we return a record, we don't load, but return the pointer.
                 The idea is that this will be used either as a return value for a function (where it is copied),
                 or for another field, where the pointer is needed.
                 We should distinguish between structs and pointers somehow *)
              (p, Ptr)
          | Const ->
              (* If the record is const, we use extractvalue and propagate the constness *)
              let p =
                Llvm.(const_extractelement value.value (const_int i32_t index))
              in
              (p, Const)
          | Imm -> failwith "Internal Error: Did not expect Imm in field"
        in

        { value; typ; lltyp = get_lltype_def typ; kind }
end
