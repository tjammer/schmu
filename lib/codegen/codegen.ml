open Cleaned_types
open Llvm_types
open Size_align
module Vars = Map.Make (String)
module Set = Set.Make (String)
module Strtbl = Hashtbl
module Ptrtbl = Hashtbl

let the_module = Llvm_types.the_module
let ( ++ ) = Seq.append
let const_tbl = Strtbl.create 64

module rec Core : sig
  val gen_expr : param -> Monomorph_tree.monod_tree -> llvar
  val gen_constexpr : param -> Monomorph_tree.monod_tree -> llvar
  val gen_function : param -> Monomorph_tree.to_gen_func -> param
end = struct
  open T
  open A
  open H
  open Ar

  external finalize_sp : Debug.lldibuilder -> Llvm.llmetadata -> unit
    = "LlvmFinalizeSp"

  let free_tbl = Hashtbl.create 64

  let rec gen_function vars
      { Monomorph_tree.abs; name; recursive; upward; monomorphized; func_loc } =
    let typ = Monomorph_tree.typ_of_abs abs in

    match typ with
    | Tfun (tparams, ret_t, kind) as typ ->
        let func = declare_function ~c_linkage:false name.call typ in

        (if monomorphized then
           Llvm.(set_linkage Linkage.Link_once_odr func.value));

        (* Add debug information *)
        let debug_func =
          (* Create unspecified type for now *)
          (* Set no flags for now *)
          let flags = Debug.(diflags_get DIFlag.Prototyped) in
          let param_types = [||] in
          let ty =
            Debug.dibuild_create_subroutine_type dibuilder flags
              ~file:(di_file func_loc) ~param_types
          in
          let line = Lexing.((fst func_loc).pos_lnum) in
          Debug.dibuild_create_function dibuilder ~scope:(di_file func_loc)
            ~name:name.user ~linkage_name:name.call ~file:(di_file func_loc)
            ~line_no:line ~ty ~is_local_to_unit:false ~is_definition:true
            ~scope_line:line ~flags ~is_optimized:true
        in
        finalize_sp dibuilder debug_func;
        Debug.set_subprogram func.value debug_func;

        let vars = { vars with scope = debug_func; rec_block = None } in

        let start_index, alloca =
          match ret_t with
          | t when is_struct t -> (
              match pkind_of_typ false t with
              | Boxed ->
                  (* Whenever the return type is boxed, we add the prealloc to the environment *)
                  (* The call site has to decide if the prealloc is used or not *)
                  (1, Some (Llvm.params func.value).(0))
              | Unboxed _ -> (* Record is returned as int *) (0, None))
          | Tpoly _ -> failwith "poly var should not be returned"
          | _ -> (0, None)
        in

        (* gen function body *)
        let bb = Llvm.append_block context "entry" func.value in
        Llvm.position_at_end bb builder;

        (* Add params from closure *)
        (* We generate both the code for extracting the closure and add the vars to the environment *)
        let tvars = add_closure vars.vars func free_tbl !upward kind in

        (* Add parameters to env *)
        let tvars, rec_block =
          add_params { vars with vars = tvars } func name abs.pnames tparams
            start_index recursive free_tbl
        in

        let fun_finalize ret =
          (* If we want to return a struct, we copy the struct to
              its ptr (1st parameter) and return void *)
          match ret.typ with
          | Tpoly _ -> ()
          | t when is_struct t -> (
              match pkind_of_typ false t with
              | Boxed ->
                  (* Since we only have POD records, we can safely memcpy here *)
                  let dst = Llvm.(params func.value).(0) in
                  if ret.value <> dst then
                    let size = sizeof_typ ret_t |> llval_of_size in
                    memcpy ~dst ~src:ret ~size
                  else ()
              | Unboxed _ -> (* Is returned as int not preallocated *) ())
          | _ -> ()
        in

        let finalize = Some fun_finalize in
        let param =
          { vars = tvars; alloca; finalize; rec_block; scope = debug_func }
        in
        let ret = gen_expr param abs.body in

        (match recursive with
        | Rtail -> tail_return param tparams start_index
        | Rnone | Rnormal -> ());
        ignore (fun_return name.call ret);

        (* Make sure we don't try to free values of other functions *)
        (* Save allocations in init for later freeing *)
        if not (H.is_in_init ()) then Hashtbl.clear free_tbl;

        if Llvm_analysis.verify_function func.value |> not then (
          Llvm.dump_module the_module;
          (* To generate the report *)
          Llvm_analysis.assert_valid_function func.value);
        let _ = Llvm.PassManager.run_function func.value fpm in

        { vars with vars = Vars.add name.call func vars.vars }
    | _ ->
        prerr_endline name.call;
        failwith "Interal Error: generating non-function"

  and gen_constexpr param expr =
    let e = gen_expr param expr in
    match e.kind with
    | Const_ptr ->
        (* The global value is a ptr, we need to 'deref' it *)
        let value = Llvm.global_initializer e.value |> Option.get in
        { e with value; kind = Const }
    | _ -> e

  and gen_expr param typed_expr =
    let fin e =
      match (typed_expr.return, param.finalize) with
      | true, Some f ->
          f e;
          e
      | true, None | false, _ -> e
    in

    match typed_expr.expr with
    | Mconst (String s) -> gen_string_lit s typed_expr.typ
    | Mconst (Array (arr, allocref, id)) ->
        let v = gen_array_lit param arr typed_expr.typ allocref in
        Hashtbl.replace free_tbl id v;
        v
    | Mconst (Fixed_array (arr, allocref, ms)) ->
        let v =
          gen_fixed_array_lit param arr typed_expr.typ allocref typed_expr.const
            typed_expr.return
        in
        List.iter (fun id -> Strtbl.replace free_tbl id v) ms;
        v
    | Mconst c -> gen_const c |> fin
    | Mbop (bop, e1, e2) -> gen_bop param e1 e2 bop |> fin
    | Munop (_, e) -> gen_unop param e |> fin
    | Mvar (id, kind, _) -> gen_var param typed_expr.typ id kind |> fin
    | Mfunction (name, kind, _, cont, allocref, upward) -> (
        (* The functions are already generated *)
        match Vars.find_opt name param.vars with
        | Some func ->
            let func =
              match kind with
              | Closure assoc ->
                  gen_closure_obj param assoc func name allocref !upward
              | Simple when is_prealloc allocref ->
                  gen_closure_obj param [] func name allocref false
              | Simple -> func
            in
            gen_expr { param with vars = Vars.add name func param.vars } cont
        | None ->
            (* The function is polymorphic and monomorphized versions are generated. *)
            (* We just return some bogus value, it will never be applied anyway
               (and if it will, LLVM will fail) *)
            gen_expr param cont)
    | Mlet (id, rhs, proj, gn, ms, cont) -> gen_let param id rhs proj gn ms cont
    | Mbind (id, equals, cont) -> gen_bind param id equals cont
    | Mlambda (name, kind, _, allocref, upward) ->
        let func =
          match Vars.find_opt name param.vars with
          | Some func -> (
              match kind with
              | Closure assoc ->
                  gen_closure_obj param assoc func name allocref !upward
              | Simple when is_prealloc allocref ->
                  gen_closure_obj param [] func name allocref false
              | Simple -> func)
          | None ->
              (* The function is polymorphic and monomorphized versions are generated. *)
              (* We just return some bogus value, it will never be applied anyway
                 (and if it will, LLVM will fail) *)
              dummy_fn_value
        in
        func |> fin
    | Mapp { callee; args; alloca; id = _; ms } ->
        let value =
          match (typed_expr.return, callee.monomorph, param.rec_block) with
          | true, Recursive _, Some block ->
              gen_app_tailrec param callee args block typed_expr.typ
          | _, Builtin (b, bfn), _ ->
              gen_app_builtin param (b, bfn) args alloca typed_expr
          | _, Inline (pnames, tree), _ -> gen_app_inline param args pnames tree
          | _ -> gen_app param callee args alloca typed_expr.typ
        in

        (match callee.monomorph with
        | Builtin (Unsafe_rc_get, _) ->
            (* Don't add frees. They would overwrite the rc frees. Think record
               field: We don't add the child frees either. *)
            ()
        | _ -> List.iter (fun id -> Strtbl.replace free_tbl id value) ms);
        fin value
    | Mif expr -> gen_if param expr
    | Mrecord (labels, allocref, id) ->
        gen_record param typed_expr.typ labels allocref id typed_expr.const
          typed_expr.return
        |> fin
    | Mfield (expr, index) -> gen_field param expr index |> fin
    | Mset (expr, value, moved) -> gen_set param expr value moved
    | Mseq (expr, cont) -> gen_chain param expr cont
    | Mctor (ctor, allocref, id) -> (
        match typed_expr.const with
        | Cnot -> gen_ctor param ctor typed_expr.typ allocref id
        | Const ->
            gen_ctor_const param ctor typed_expr.typ allocref typed_expr.return)
    | Mvar_index expr -> gen_var_index param expr |> fin
    | Mvar_data (expr, mid) -> gen_var_data param expr mid typed_expr.typ |> fin
    | Mfree_after (expr, fs) -> gen_free param expr fs

  and gen_let param id rhs kind gn ms cont =
    let expr_val =
      match gn with
      | Some n -> (
          let dst = Strtbl.find const_tbl n in
          match rhs.const with
          | Cnot -> (
              let v = gen_expr { param with alloca = Some dst.value } rhs in
              (* Bandaid for polymorphic first class functions. In monomorph pass, the
                 global is ignored. TODO. Here, we make sure that the dummy_fn_value is
                 not set to the global. The global will stay 0 forever *)
              match (v.typ, dst.kind) with
              | Tunit, _ | _, Const_ptr -> v
              | _ ->
                  let src = bring_default_var v in

                  (* Only copy if the alloca was not used
                     (for whatever reason; it should have been used) *)
                  if v.value <> dst.value then store_or_copy ~src ~dst:dst.value;
                  let v = { v with value = dst.value; kind = Ptr } in
                  Strtbl.replace const_tbl n v;
                  v)
          | Const -> dst)
      | None -> (
          match (kind, rhs.typ) with
          | Lborrow, _ -> gen_expr param rhs
          | Lowned, Tunit -> gen_expr param rhs
          | Lowned, _ ->
              let dst = alloca param (get_lltype_def rhs.typ) "" in
              let v = gen_expr { param with alloca = Some dst } rhs in
              let src = bring_default_var v in

              if v.value <> dst then store_or_copy ~src ~dst;
              { v with value = dst; kind = Ptr })
    in
    List.iter (fun id -> Strtbl.replace free_tbl id expr_val) ms;
    gen_expr { param with vars = Vars.add id expr_val param.vars } cont

  and gen_bind param id equals cont =
    let lhs = gen_expr param equals in
    gen_expr { param with vars = Vars.add id lhs param.vars } cont

  and gen_const = function
    | Int i ->
        let value = Llvm.const_of_int64 int_t i true in
        { value; typ = Tint; lltyp = int_t; kind = Const }
    | Bool b ->
        let value = Llvm.const_int bool_t (Bool.to_int b) in
        { value; typ = Tbool; lltyp = bool_t; kind = Const }
    | U8 c ->
        let value = Llvm.const_int u8_t (Char.code c) in
        { value; typ = Tu8; lltyp = u8_t; kind = Const }
    | U16 s ->
        let value = Llvm.const_int u16_t s in
        { value; typ = Tu16; lltyp = u16_t; kind = Const }
    | Float f ->
        let value = Llvm.const_float float_t f in
        { value; typ = Tfloat; lltyp = float_t; kind = Const }
    | I32 i ->
        let value = Llvm.const_int i32_t i in
        { value; typ = Ti32; lltyp = i32_t; kind = Const }
    | F32 f ->
        let value = Llvm.const_float f32_t f in
        { value; typ = Tf32; lltyp = f32_t; kind = Const }
    | Unit -> dummy_fn_value
    | String _ | Array _ | Fixed_array _ -> failwith "In other branch"

  and gen_var param typ id kind =
    match kind with
    | Vnorm -> (
        match Vars.find_opt id param.vars with
        | Some v -> v
        | None -> (
            match typ with
            | Tfun _ ->
                (* If a function is polymorphic then its original value might not be bound
                   when we generate other function. In this case, we can just return a
                   dummy value *)
                dummy_fn_value
            | _ ->
                (* If the variable isn't bound, something went wrong before *)
                failwith ("Internal Error: Could not find " ^ id ^ " in codegen")
            ))
    | Vconst | Vglobal _ -> Strtbl.find const_tbl id
    | Vmono upward -> (
        let func =
          match Vars.find_opt id param.vars with
          | Some v -> v
          | None ->
              (* If the variable isn't bound, something went wrong before *)
              failwith
                ("Internal Error: Could not find mono " ^ id ^ " in codegen")
        in
        match (func.kind, func.typ) with
        | Imm, Tfun (_, _, Closure assoc) ->
            gen_closure_obj param assoc func "monoclstmp" no_prealloc upward
        | _ -> func)
    | Vrecursive call -> Vars.find call param.vars

  and gen_bop param e1 e2 bop =
    let gen = gen_expr param in
    let bldr = builder in
    let bld f str =
      let e1 = gen e1 |> bring_default in
      let e2 = gen e2 |> bring_default in
      f e1 e2 str builder
    in
    let open Llvm in
    match bop with
    | Equal_i ->
        let value = bld (build_icmp Icmp.Eq) "eq" in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | And ->
        let cond1 = gen e1 |> bring_default in

        (* Current block *)
        let start_bb = insertion_block bldr in
        let parent = block_parent start_bb in

        let true1_bb = append_block context "true1" parent in
        let true2_bb = append_block context "true2" parent in
        let continue_bb = append_block context "cont" parent in

        ignore (build_cond_br cond1 true1_bb continue_bb bldr);

        position_at_end true1_bb bldr;
        let cond2 = gen e2 |> bring_default in
        (* Codegen can change the current bb *)
        let t1_bb = insertion_block bldr in
        ignore (build_cond_br cond2 true2_bb continue_bb bldr);

        position_at_end true2_bb bldr;
        ignore (build_br continue_bb bldr);

        position_at_end continue_bb bldr;

        let true_value = Llvm.const_int bool_t (Bool.to_int true) in
        let false_value = const_int bool_t (Bool.to_int false) in

        let incoming =
          [
            (false_value, start_bb); (false_value, t1_bb); (true_value, true2_bb);
          ]
        in
        let value = build_phi incoming "andtmp" bldr in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | Or ->
        let cond1 = gen e1 |> bring_default in

        (* Current block *)
        let start_bb = insertion_block bldr in
        let parent = block_parent start_bb in

        let false1_bb = append_block context "false1" parent in
        let false2_bb = append_block context "false2" parent in
        let continue_bb = append_block context "cont" parent in

        ignore (build_cond_br cond1 continue_bb false1_bb bldr);

        position_at_end false1_bb bldr;
        let cond2 = gen e2 |> bring_default in
        (* Codegen can change the current bb *)
        let f1_bb = insertion_block bldr in
        ignore (build_cond_br cond2 continue_bb false2_bb bldr);

        position_at_end false2_bb bldr;
        ignore (build_br continue_bb bldr);

        position_at_end continue_bb bldr;

        let true_value = Llvm.const_int bool_t (Bool.to_int true) in
        let false_value = const_int bool_t (Bool.to_int false) in

        let incoming =
          [
            (true_value, start_bb); (true_value, f1_bb); (false_value, false2_bb);
          ]
        in
        let value = build_phi incoming "andtmp" bldr in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }

  and gen_unop param e =
    let expr = gen_expr param e in
    let value =
      match expr.typ with
      | Tint -> Llvm.build_neg (bring_default expr) "neg" builder
      | Tfloat -> Llvm.build_fneg (bring_default expr) "neg" builder
      | _ -> failwith "Internal Error: Unsupported unary op"
    in
    { expr with value; kind = Imm }

  and gen_app param callee args allocref ret_t =
    let func = gen_expr param callee.ex in
    let loc = callee.ex.loc in
    let func = get_mono_func func param callee.monomorph in

    let ret, kind =
      match func.typ with
      | Tfun (_, ret, kind) -> (ret, kind)
      | Tunit ->
          print_endline (Monomorph_tree.show_expr callee.ex.expr);
          print_endline (Monomorph_tree.show_call_name callee.monomorph);
          failwith
            "Internal Error: Probably cannot find monomorphized function in \
             gen_app"
      | _ -> failwith "Internal Error: Not a func in gen app"
    in

    let args =
      List.fold_left
        (fun args (oarg, _) ->
          let arg' = gen_expr param Monomorph_tree.(oarg.ex) in
          let arg' = { arg' with typ = Monomorph_tree.(oarg.ex.typ) } in

          (* In case the record passed is constant, we allocate it here to pass
             a pointer. This isn't pretty, but will do for now. For the single
             param, unboxed case we can skip boxing *)
          let arg =
            match (pkind_of_typ oarg.mut arg'.typ, arg'.kind) with
            (* The [Two_params] case is tricky to do using only consts, so
               we box and use the standard runtime version *)
            | (Boxed, Const | Unboxed (Two_params _), Const)
              when is_struct arg'.typ ->
                box_const param arg'
            | _ -> get_mono_func arg' param oarg.monomorph
          in

          match arg.typ with
          | Tunit -> args
          | _ -> (
              match pass_value oarg.mut arg with
              | fst, Some snd ->
                  (* We can skip [func_to_closure] in this case *)
                  (* snd before fst, b/c we rev at the end *)
                  snd :: fst :: args
              | value, None ->
                  let arg = { arg with value } in
                  (func_to_closure param arg).value :: args))
        [] args
      |> List.rev |> List.to_seq
    in

    (* No names here, might be void/unit *)
    let funcval, ft, envarg =
      match func.kind with
      | Ptr ->
          (* Function to call is a closure (or a function passed into another one).
             We get the funptr from the first field, cast to the correct type,
             then get env ptr (as voidptr) from the second field and pass it as last argument *)
          let funcp =
            Llvm.build_struct_gep closure_t func.value 0 "funcptr" builder
          in
          let funcp = Llvm.build_load ptr_t funcp "loadtmp" builder in
          let ftyp = typeof_funclike func.typ in

          let env_ptr =
            Llvm.build_struct_gep closure_t func.value 1 "envptr" builder
          in
          let env_ptr = Llvm.build_load ptr_t env_ptr "loadtmp" builder in
          (funcp, ftyp, Seq.return env_ptr)
      | _ -> (
          match kind with
          | Simple -> (func.value, func.lltyp, Seq.empty)
          | Closure _ ->
              (* In this case we are in a recursive closure function.
                 We get the closure env and add it to the arguments we pass *)
              let closure_index =
                (Llvm.params func.value |> Array.length) - 1
              in

              let env_ptr = (Llvm.params func.value).(closure_index) in
              (func.value, func.lltyp, Seq.return env_ptr))
    in

    let value, lltyp, kind =
      let lltyp = get_lltype_def ret_t in
      match ret_t with
      | t when is_struct t -> (
          match pkind_of_typ false t with
          | Boxed ->
              let retval = get_prealloc !allocref param lltyp "ret" in
              let ret' = Seq.return retval in
              let args = ret' ++ args ++ envarg |> Array.of_seq in
              let call = Llvm.build_call ft funcval args "" builder in
              Debug.instr_set_debug_loc call (Some (di_loc param loc));
              ignore loc;
              ignore call;
              (retval, lltyp, default_kind t)
          | Unboxed size ->
              (* Boxed representation *)
              let retval = get_prealloc !allocref param lltyp "ret" in
              let args = args ++ envarg |> Array.of_seq in
              (* Unboxed representation *)
              let call = Llvm.build_call ft funcval args "" builder in
              Debug.instr_set_debug_loc call (Some (di_loc param loc));
              let ret =
                box_record ~size ~alloc:(Some retval) ~snd_val:None t call
              in
              (ret, lltyp, default_kind t))
      | t when H.is_in_init () && contains_allocation t ->
          (* We have to [alloca] these types, because otherwise, when adding to
             the free_tbl, we would add function-local variables which we cannot
             refer to in deinit. *)
          let args = args ++ envarg |> Array.of_seq in
          let retval = get_prealloc !allocref param lltyp "ret" in
          let call = Llvm.build_call ft funcval args "" builder in
          Debug.instr_set_debug_loc call (Some (di_loc param loc));
          (* No struct, must be a simple type *)
          ignore (Llvm.build_store call retval builder);
          (retval, get_lltype_param false t, Ptr)
      | t ->
          let args = args ++ envarg |> Array.of_seq in
          let retval = Llvm.build_call ft funcval args "" builder in
          Debug.instr_set_debug_loc retval (Some (di_loc param loc));
          (retval, get_lltype_param false t, default_kind t)
    in

    { value; typ = ret; lltyp; kind }

  and gen_app_tailrec param callee args rec_block ret_t =
    (* We evaluate, there might be side-effects *)
    let func = gen_expr param callee.ex in

    let start_index, ret =
      match func.typ with
      | Tfun (_, r, _) when is_struct r -> (
          match pkind_of_typ false r with
          | Boxed -> (1, r)
          | Unboxed size -> (0, type_unboxed size))
      | Tfun (_, ret, _) -> (0, ret)
      | Tunit ->
          failwith "Internal Error: Probably cannot find monomorphized function"
      | _ -> failwith "Internal Error: Not a func in gen app tailrec"
    in

    let calculate_arg i (oarg, is_arg) =
      let arg' = gen_expr param Monomorph_tree.(oarg.ex) in
      let arg = get_mono_func arg' param oarg.monomorph in
      match arg.typ with
      | Tunit -> (i, None)
      | _ ->
          let llvar = func_to_closure param arg in

          let i = get_index i oarg.mut arg.typ in
          let alloca = Vars.find (name_of_alloc_param i) param.vars in
          (i + 1, Some (i, oarg.mut, alloca, llvar, is_arg))
    in

    let store_arg (i, mut, alloca, value, is_arg) =
      if not is_arg then tail_decr_param param alloca i mut;

      (* We store the params in pre-allocated variables *)
      if value.value <> alloca.value then
        let store = if mut then tailrec_store else store_or_copy in
        store ~src:value ~dst:alloca.value
    in

    let margs =
      List.fold_left_map calculate_arg start_index args
      |> snd |> List.filter_map Fun.id
    in
    List.iter store_arg margs;

    let lltyp =
      if is_struct ret then get_lltype_def ret_t else get_lltype_param false ret
    in

    let value = Llvm.build_br rec_block.rec_ builder in
    { value; typ = Tpoly "tail"; lltyp; kind = default_kind ret }

  and gen_app_builtin param (b, fnc) oargs allocref tyexpr =
    let handle_arg (arg, _) =
      let arg' = gen_expr param Monomorph_tree.(arg.ex) in

      (* For [ignore], we don't really need to generate the closure objects here *)
      match b with
      | Ignore -> arg'
      | Copy | Unsafe_funptr | Unsafe_clsptr ->
          get_mono_func arg' param arg.monomorph
      | _ ->
          let arg = get_mono_func arg' param arg.monomorph in
          func_to_closure param arg
    in
    let args =
      match b with
      | Rc_create ->
          (* Handle [gen_expr] in rc function for pre-allocation *)
          []
      | _ -> List.map handle_arg oargs
    in
    let binary () =
      match args with
      | [ a; b ] -> (bring_default a, bring_default b)
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    let cast f typ =
      match args with
      | [ value ] ->
          let lltyp = get_lltype_def typ in
          let value = f (bring_default value) lltyp "" builder in
          { value; typ; lltyp; kind = Imm }
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    match b with
    | Builtin.Unsafe_ptr_get -> (
        match fnc.ret with
        | Tunit -> dummy_fn_value
        | _ ->
            let ptr, index =
              match args with
              | [ ptr; index ] -> (bring_default ptr, bring_default index)
              | _ -> failwith "Internal Error: Arity mismatch in builtin"
            in
            let lltyp = get_lltype_def fnc.ret in
            let value =
              Llvm.build_in_bounds_gep lltyp ptr [| index |] "" builder
            in
            { value; typ = fnc.ret; lltyp; kind = Ptr })
    | Unsafe_ptr_set -> (
        match args with
        | [ ptr; index; value ] -> (
            match value.typ with
            | Tunit -> { dummy_fn_value with lltyp = unit_t }
            | t ->
                let ptr = bring_default ptr
                and index = bring_default index
                and value = bring_default_var value in
                let lltyp = get_lltype_def t in
                let ptr =
                  Llvm.build_in_bounds_gep lltyp ptr [| index |] "" builder
                in

                set_struct_field value ptr;
                { dummy_fn_value with lltyp = unit_t })
        | _ -> failwith "Internal Error: Arity mismatch in builtin")
    | Unsafe_ptr_at ->
        let ptr, index =
          match args with
          | [ ptr; index ] -> (bring_default ptr, bring_default index)
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        let lltyp = get_lltype_def fnc.ret in
        let item_lltyp =
          match fnc.ret with
          | Traw_ptr t -> get_lltype_def t
          | _ -> failwith "unreachable"
        in
        (* Use item type to get the correct offset into the ptr *)
        let value =
          Llvm.build_in_bounds_gep item_lltyp ptr [| index |] "" builder
        in
        { value; typ = fnc.ret; lltyp; kind = Imm }
    | Unsafe_ptr_reinterpret ->
        let value =
          match args with
          | [ ptr ] -> bring_default ptr
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        let lltyp = get_lltype_def fnc.ret in
        { value; lltyp; typ = fnc.ret; kind = Imm }
    | Unsafe_funptr -> (
        let fn =
          match args with
          | [ fn ] -> bring_default_var fn
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        match fn.typ with
        | Tfun (_, _, kind) ->
            (* See [gen_app] *)
            let value =
              match fn.kind with
              | Ptr ->
                  let funcp =
                    Llvm.build_struct_gep closure_t fn.value 0 "funcptr" builder
                  in
                  Llvm.build_load ptr_t funcp "loadtmp" builder
              | _ -> (
                  match kind with
                  | Simple -> fn.value
                  | Closure _ ->
                      failwith
                        "Internal Error: Recursive function case, see [gen_app]"
                  )
            in
            let lltyp = get_lltype_def fnc.ret in
            { value; lltyp; typ = fnc.ret; kind = Imm }
        | t ->
            print_endline (show_typ t);
            failwith "Internal Error: Not a function for funptr")
    | Unsafe_clsptr -> (
        let fn =
          match args with
          | [ fn ] -> bring_default_var fn
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        match fn.typ with
        | Tfun (_, _, kind) ->
            (* See [gen_app] *)
            let value =
              match fn.kind with
              | Ptr ->
                  let funcp =
                    Llvm.build_struct_gep closure_t fn.value 1 "clsptr" builder
                  in
                  Llvm.build_load ptr_t funcp "loadtmp" builder
              | _ -> (
                  match kind with
                  | Simple -> Llvm.const_null ptr_t
                  | Closure _ ->
                      failwith
                        "Internal Error: Recursive function case, see [gen_app]"
                  )
            in
            let lltyp = get_lltype_def fnc.ret in
            { value; lltyp; typ = fnc.ret; kind = Imm }
        | t ->
            print_endline (show_typ t);
            failwith "Internal Error: Not a function for clsptr")
    | Unsafe_leak -> dummy_fn_value
    | Unsafe_addr ->
        let value = List.hd args in
        { value with kind = Imm; typ = Traw_ptr value.typ; lltyp = ptr_t }
    | Unsafe_unchecked -> (* Do nothing at all *) List.hd args
    | Mod -> (
        match args with
        | [ value; md ] ->
            let value =
              Llvm.build_srem (bring_default value) (bring_default md) "mod"
                builder
            in
            { value; typ = Tint; lltyp = int_t; kind = Imm }
        | _ -> failwith "Internal Error: Arity mismatch in builtin")
    | Array_get -> array_get args fnc.ret
    | Array_length -> array_length ~unsafe:false args
    | Unsafe_array_length -> array_length ~unsafe:true args
    | Unsafe_array_pop_back -> unsafe_array_pop_back param args allocref
    | Array_data -> array_data args
    | Array_capacity -> array_capacity args
    | Fixed_array_get -> (
        match args with
        | [ arr; idx ] -> (
            match arr.typ with
            | Tfixed_array (_, Tunit) -> dummy_fn_value
            | _ ->
                let lltyp = get_lltype_def fnc.ret in
                let value =
                  Llvm.build_gep lltyp arr.value
                    [| bring_default idx |]
                    "" builder
                in
                { value; typ = fnc.ret; lltyp; kind = Ptr })
        | _ -> failwith "Internal Error: Arity mismatch in builtin")
    | Fixed_array_length -> (
        match args with
        | [ arr ] -> (
            match arr.typ with
            | Tfixed_array (i, _) ->
                assert (i > 0);
                let value = Llvm.const_int int_t i in
                { value; typ = Tint; lltyp = int_t; kind = Const }
            | _ -> failwith "Internal Error: Not a fixed-size array")
        | _ -> failwith "Internal Error: Arity mismatch in builtin")
    | Fixed_array_data -> (
        match args with
        | [ arr ] -> (
            match (arr.kind, arr.typ) with
            | _, Tfixed_array (_, Tunit) ->
                let value = Llvm.const_null ptr_t in
                { value; kind = Imm; typ = Traw_ptr Tunit; lltyp = ptr_t }
            | (Ptr | Const_ptr), Tfixed_array (_, t) ->
                let lltyp = ptr_t in
                { value = arr.value; kind = Imm; typ = Traw_ptr t; lltyp }
            | (Ptr | Const_ptr), _ ->
                failwith "Internal Error: Not a fixed-size array"
            | (Const | Imm), _ ->
                failwith "Internal Error: Taking address of immediate")
        | _ -> failwith "Internal Error: Arity mismatch in builtin")
    | Unsafe_array_realloc -> array_realloc args
    | Unsafe_array_create -> unsafe_array_create param args fnc.ret allocref
    | Unsafe_nullptr ->
        let value = Llvm.const_null ptr_t in
        { value; typ = Traw_ptr Tunit; lltyp = ptr_t; kind = Const }
    | Ignore -> dummy_fn_value
    | Cast (to_, from_) ->
        let to_ = of_typ to_ and from_ = of_typ from_ in
        if is_int to_ then
          if is_float from_ then
            if is_signed to_ then cast Llvm.build_fptosi to_
            else cast Llvm.build_fptoui to_
          else if sizeof_typ to_ > sizeof_typ from_ then
            if is_signed from_ then cast Llvm.build_sext to_
            else cast Llvm.build_zext to_
          else cast Llvm.build_trunc_or_bitcast to_
        else if is_int from_ then
          if is_signed from_ then cast Llvm.build_sitofp to_
          else cast Llvm.build_uitofp to_
        else cast Llvm.build_fpcast to_
    | Not ->
        let value =
          match args with
          | [ value ] -> bring_default value
          | _ -> failwith "Interal Error: Arity mismatch in builder"
        in

        let true_value = Llvm.const_int bool_t (Bool.to_int true) in
        let value = Llvm.build_xor value true_value "" builder in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | Is_nullptr ->
        let ptr =
          match args with
          | [ ptr ] -> bring_default ptr
          | _ -> failwith "Internal Error: Arity mismatch in builder"
        in
        let value =
          Llvm.(build_icmp Icmp.Eq) ptr (Llvm.const_null ptr_t) "" builder
        in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | Assert ->
        let cond =
          match args with
          | [ cond ] -> bring_default cond
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        let start_bb = Llvm.insertion_block builder in
        let parent = Llvm.block_parent start_bb in
        let func = Llvm.value_name parent in
        let text = get_snippet tyexpr.loc in

        let success_bb = Llvm.append_block context "success" parent in
        let fail_bb = Llvm.append_block context "fail" parent in

        let br = Llvm.build_cond_br cond success_bb fail_bb builder in
        Debug.instr_set_debug_loc br (Some (di_loc param tyexpr.loc));

        Llvm.position_at_end fail_bb builder;
        let md = di_loc param tyexpr.loc in
        let loc = fst tyexpr.loc in
        ignore
          (assert_fail ~text ~file:loc.pos_fname ~line:loc.pos_lnum ~func md);

        Llvm.position_at_end success_bb builder;

        { dummy_fn_value with lltyp = unit_t }
    | Copy -> Auto.copy param allocref (List.hd args)
    | Land ->
        let a, b = binary () in
        let value = Llvm.build_and a b "land" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Lor ->
        let a, b = binary () in
        let value = Llvm.build_or a b "lor" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Lxor ->
        let a, b = binary () in
        let value = Llvm.build_xor a b "lxor" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Lshl ->
        let a, b = binary () in
        let value = Llvm.build_shl a b "lshl" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Lshr ->
        let a, b = binary () in
        let value = Llvm.build_lshr a b "lshr" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Ashr ->
        let a, b = binary () in
        let value = Llvm.build_ashr a b "ashr" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Addi ->
        let a, b = binary () in
        let value = Llvm.build_add a b "add" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Subi ->
        let a, b = binary () in
        let value = Llvm.build_sub a b "sub" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Multi ->
        let a, b = binary () in
        let value = Llvm.build_mul a b "mul" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Divi ->
        let a, b = binary () in
        let value = Llvm.build_sdiv a b "div" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Diviu ->
        let a, b = binary () in
        let value = Llvm.build_udiv a b "divu" builder in
        { value; lltyp = int_t; typ = Tint; kind = Imm }
    | Addf ->
        let a, b = binary () in
        let value = Llvm.build_fadd a b "add" builder in
        { value; lltyp = float_t; typ = Tfloat; kind = Imm }
    | Subf ->
        let a, b = binary () in
        let value = Llvm.build_fsub a b "sub" builder in
        { value; lltyp = float_t; typ = Tfloat; kind = Imm }
    | Mulf ->
        let a, b = binary () in
        let value = Llvm.build_fmul a b "mul" builder in
        { value; lltyp = float_t; typ = Tfloat; kind = Imm }
    | Divf ->
        let a, b = binary () in
        let value = Llvm.build_fdiv a b "div" builder in
        { value; lltyp = float_t; typ = Tfloat; kind = Imm }
    | Lessi ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Slt) a b "lt" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Greateri ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Sgt) a b "gt" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Lesseqi ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Sle) a b "le" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Greatereqi ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Sge) a b "ge" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Lessiu ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Ult) a b "ltu" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Greateriu ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Ugt) a b "gtu" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Lesseqiu ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Ule) a b "leu" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Greatereqiu ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Uge) a b "geu" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Equali ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Eq) a b "eq" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Nequali ->
        let a, b = binary () in
        let value = Llvm.(build_icmp Icmp.Ne) a b "ne" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Lessf ->
        let a, b = binary () in
        let value = Llvm.(build_fcmp Fcmp.Olt) a b "lt" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Greaterf ->
        let a, b = binary () in
        let value = Llvm.(build_fcmp Fcmp.Ogt) a b "gt" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Lesseqf ->
        let a, b = binary () in
        let value = Llvm.(build_fcmp Fcmp.Ole) a b "le" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Greatereqf ->
        let a, b = binary () in
        let value = Llvm.(build_fcmp Fcmp.Oge) a b "ge" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Equalf ->
        let a, b = binary () in
        let value = Llvm.(build_fcmp Fcmp.Oeq) a b "eq" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Nequalf ->
        let a, b = binary () in
        let value = Llvm.(build_fcmp Fcmp.One) a b "ne" builder in
        { value; lltyp = bool_t; typ = Tbool; kind = Imm }
    | Rc_create ->
        let e =
          match oargs with
          | [ e ] -> fst e
          | _ -> failwith "Internal Error: Arity mismatch in builder"
        in
        R.gen_rc param e fnc.ret allocref
    | Unsafe_rc_get ->
        List.hd args |> bring_default_var |> fun llvar -> R.get llvar
    | Rc_to_weak ->
        List.hd args |> bring_default_var |> fun llvar -> R.to_weak llvar
    | Unsafe_rc_of_weak ->
        List.hd args |> bring_default_var |> fun llvar -> R.unsafe_of_weak llvar
    | Rc_cnt | Rc_wcnt ->
        List.hd args |> bring_default_var |> fun llvar -> R.cnt llvar
    | Any_abort -> (
        let ft, abort =
          Llvm.(
            let ft = function_type unit_t [||] in
            (ft, declare_function "abort" ft the_module))
        in
        ignore (Llvm.build_call ft abort [||] "" builder);
        let typ = tyexpr.typ in
        let lltyp = get_lltype_param false typ in
        match typ with
        | Tunit -> { dummy_fn_value with typ = Tunit }
        | _ ->
            let value = alloca param lltyp "failwith" in
            { value; typ; lltyp; kind = Ptr })
    | Any_exit -> (
        let ft, exit' =
          Llvm.(
            let ft = function_type unit_t [| i32_t |] in
            (ft, declare_function "exit" ft the_module))
        in
        let value =
          match args with
          | [ value ] -> bring_default value
          | _ -> failwith "Interal Error: Arity mismatch in builder"
        in
        ignore (Llvm.build_call ft exit' [| value |] "" builder);
        let typ = tyexpr.typ in
        let lltyp = get_lltype_param false typ in
        match typ with
        | Tunit -> { dummy_fn_value with typ = Tunit }
        | _ ->
            let value = alloca param lltyp "exit" in
            { value; typ; lltyp; kind = Ptr })

  and gen_app_inline param args names tree =
    (* Identify args to param names *)
    let f env (arg, _) (param, _) =
      let arg' = gen_expr env Monomorph_tree.(arg.ex) in
      let arg = get_mono_func arg' env arg.monomorph in
      match arg.typ with
      | Tunit -> env
      | _ ->
          let vars = Vars.add param arg env.vars in
          { env with vars }
    in
    let env = List.fold_left2 f param args names in
    gen_expr env tree

  and gen_if param expr =
    (* If a function ends in a if expression (and returns a struct),
       we pass in the finalize step. This allows us to handle the branches
       differently and enables tail call elimination *)
    let is_tailcall e =
      match e.typ with
      | Tpoly id when String.equal "tail" id -> true
      | _ -> false
    in

    let cond = gen_expr param expr.cond |> bring_default in

    (* Get current block *)
    let start_bb = Llvm.insertion_block builder in
    let parent = Llvm.block_parent start_bb in

    let then_bb = Llvm.append_block context "then" parent in
    Llvm.position_at_end then_bb builder;
    let e1 = gen_expr param expr.e1 in

    (* Codegen can change the current bb *)
    let e1_bb = Llvm.insertion_block builder in

    let else_bb = Llvm.append_block context "else" parent in
    Llvm.position_at_end else_bb builder;
    let e2 = gen_expr param expr.e2 in

    let e2_bb = Llvm.insertion_block builder in
    (* We don't want a merge_bb if both branches are tailcalls, so lazy it *)
    let merge_bb = lazy (Llvm.append_block context "ifcont" parent) in

    let llvar =
      (* Small optimization: If we happen to end up with the same value,
         we don't generate a phi node (can happen in recursion) *)
      match (is_tailcall e1, is_tailcall e2) with
      | true, true ->
          (* No need for the whole block, we just return some value *)
          e1
      | true, false -> e2
      | false, true -> e1
      | false, false -> (
          match e2.typ with
          (* If the else evaluates to void, we don't do anything.
             Void will be added eventually *)
          | Tunit -> e1
          | _ ->
              let e1, e2 =
                (* Both values have to either be ptrs or const literals *)
                match (e1.kind, e2.kind) with
                | Const, (Ptr | Const_ptr) when is_struct e1.typ ->
                    Llvm.position_at_end e1_bb builder;
                    let value = alloca param e1.lltyp "" in
                    ignore (Llvm.build_store (bring_default e1) value builder);
                    ({ e1 with value; kind = Const_ptr }, e2)
                | (Const | Imm), (Ptr | Const_ptr) ->
                    Llvm.position_at_end e2_bb builder;
                    (e1, { e2 with value = bring_default e2; kind = e1.kind })
                | (Ptr | Const_ptr), Const when is_struct e2.typ ->
                    Llvm.position_at_end e2_bb builder;
                    let value = alloca param e2.lltyp "" in
                    ignore (Llvm.build_store (bring_default e2) value builder);
                    (e1, { e2 with value; kind = Const_ptr })
                | (Ptr | Const_ptr), (Const | Imm) ->
                    Llvm.position_at_end e1_bb builder;
                    ({ e1 with value = bring_default e1; kind = e2.kind }, e2)
                | _, _ -> (e1, e2)
              in

              if e1.value <> e2.value then (
                Llvm.position_at_end (Lazy.force merge_bb) builder;
                let incoming = [ (e1.value, e1_bb); (e2.value, e2_bb) ] in
                let value = Llvm.build_phi incoming "iftmp" builder in

                let ret =
                  { value; typ = e1.typ; lltyp = e2.lltyp; kind = e1.kind }
                in
                (* If a phi node is const, turn it into an actual value. We
                   cannot deal with the phi node otherwise, e.g. for
                   [const_extractelement]. It's only needed if the type is a
                   record or variant. *)
                match e1.kind with
                | Const when is_struct e2.typ ->
                    let alloca = alloca param e2.lltyp "" in
                    Llvm.build_store value alloca builder |> ignore;
                    { ret with value = alloca; kind = Ptr }
                | _ -> ret)
              else e1)
    in

    Llvm.position_at_end start_bb builder;
    let br = Llvm.build_cond_br cond then_bb else_bb builder in

    Debug.instr_set_debug_loc br (Some (di_loc param expr.cond.loc));

    if not (is_tailcall e1) then (
      Llvm.position_at_end e1_bb builder;
      ignore (Llvm.build_br (Lazy.force merge_bb) builder));
    if not (is_tailcall e2) then (
      Llvm.position_at_end e2_bb builder;
      ignore (Llvm.build_br (Lazy.force merge_bb) builder));

    if Lazy.is_val merge_bb then
      Llvm.position_at_end (Lazy.force merge_bb) builder;

    (match expr.owning with
    | Some id -> Strtbl.replace free_tbl id llvar
    | None -> ());
    llvar

  and gen_record param typ labels allocref ms const return =
    let lltyp = get_lltype_def typ in

    let value, kind =
      match const with
      | Cnot ->
          let record = get_prealloc !allocref param lltyp "" in

          List.fold_left
            (fun i (name, expr) ->
              match Monomorph_tree.(expr.typ) with
              | Tunit ->
                  gen_expr param expr |> ignore;
                  i
              | _ ->
                  let ptr = Llvm.build_struct_gep lltyp record i name builder in
                  let value =
                    gen_expr { param with alloca = Some ptr } expr
                    |> (* Const records will stay const, no allocation done to lift
                          it to Ptr. Thus, it stays Const*)
                    bring_default_var |> func_to_closure param
                  in
                  set_struct_field value ptr;
                  i + 1)
            0 labels
          |> ignore;
          (record, Ptr)
      | Const ->
          (* We generate the const for runtime use. An addition to
             re-generating the constants, there are immediate literals.
             We have to take care that some global constants are pointers now *)
          let value =
            let f (_, expr) =
              match Monomorph_tree.(expr.typ) with
              | Tunit ->
                  (* The expression is const, so cannot have side-effects. No
                     need to evaluate it *)
                  None
              | _ -> Some (gen_constexpr param expr).value
            in
            let values = List.filter_map f labels |> Array.of_list in
            Llvm.const_named_struct lltyp values
          in
          (* The value might be returned, thus boxed, so we wrap it in an automatic var *)
          if return then (
            let record = get_prealloc !allocref param lltyp "" in
            ignore (Llvm.build_store value record builder);
            (record, Const_ptr))
          else (value, Const)
    in

    let v = { value; typ; lltyp; kind } in
    List.iter (fun id -> Strtbl.replace free_tbl id v) ms;
    v

  and gen_field param expr index =
    let value = gen_expr param expr in
    (* This expression has the correct, unfolded type. This is somehow lost when
       we generate the expression. *)
    follow_field { value with typ = expr.typ } index

  and gen_set param expr valexpr moved =
    let ptr = gen_expr param expr in
    let value = gen_expr param valexpr in
    if not moved then Auto.free param ptr;
    (* We know that ptr cannot be a constant record, but value might *)
    set_struct_field value ptr.value;
    { dummy_fn_value with lltyp = unit_t }

  and gen_chain param expr cont =
    ignore (gen_expr param expr);
    gen_expr param cont

  and gen_string_lit s typ =
    let lltyp = get_lltype_def typ in
    let ptr = get_const_string s in
    { value = ptr; typ; lltyp; kind = Const }

  and gen_ctor param (variant, tag, expr) typ allocref ms =
    let lltyp = get_struct typ in
    let var = get_prealloc !allocref param lltyp variant in

    (* Set tag *)
    let tagptr = Llvm.build_struct_gep lltyp var 0 "tag" builder in
    let tag =
      {
        value = Llvm.const_int i32_t tag;
        typ = Ti32;
        lltyp = i32_t;
        kind = Const;
      }
    in
    set_struct_field tag tagptr;

    (* Set data *)
    (match expr with
    | Some expr ->
        if sizeof_typ expr.typ = 0 then
          (* Generate the expression for side effects *)
          gen_expr param expr |> ignore
        else
          let dataptr = Llvm.build_struct_gep lltyp var 1 "data" builder in
          let data =
            gen_expr { param with alloca = Some dataptr } expr
            |> bring_default_var |> func_to_closure param
          in

          set_struct_field data dataptr
    | None -> ());
    let v = { value = var; typ; lltyp; kind = Ptr } in
    List.iter (fun id -> Strtbl.replace free_tbl id v) ms;
    v

  and gen_ctor_const param (variant, tag, expr) typ allocref return =
    let lltyp = get_struct typ in
    let elems = Llvm.struct_element_types lltyp in

    let tag = Llvm.const_int i32_t tag in
    let value =
      match expr with
      | Some expr ->
          (* Get largest ctor to figure out the size of the variant and pad
             accordingly *)
          let largestsize =
            match typ with
            | Tvariant (_, Rec_folded, _) -> failwith "unreachable"
            | Tvariant (_, (Rec_not ctors | Rec_top ctors), _) -> (
                match variant_get_largest ctors with
                | Some typ -> sizeof_typ typ
                | None -> 0)
            | _ -> failwith "unreachable"
          in
          let data = gen_constexpr param expr in
          (* Change to the type of the greatest payload, or construct a type
             with needed padding *)
          let oursize = sizeof_typ data.typ in
          if largestsize = 0 then Llvm.const_named_struct lltyp [| tag |]
          else if largestsize > oursize then
            let padding =
              let padtype = Llvm.array_type u8_t (largestsize - oursize) in
              Llvm.undef padtype
            in
            let value = Llvm.(const_struct context [| data.value; padding |]) in
            Llvm.const_named_struct lltyp [| tag; value |]
          else
            let data = Llvm.const_bitcast data.value elems.(1) in
            Llvm.const_named_struct lltyp [| tag; data |]
      | None ->
          (* We might need a payload type *)
          if Array.length elems > 1 then
            let null = Llvm.undef elems.(1) in
            Llvm.const_named_struct lltyp [| tag; null |]
          else Llvm.const_named_struct lltyp [| tag |]
    in
    let value, kind =
      if return then (
        let variant = get_prealloc !allocref param lltyp variant in
        ignore (Llvm.build_store value variant builder);
        (variant, Const_ptr))
      else (value, Const)
    in
    { value; typ; lltyp; kind }

  and gen_var_index param expr =
    let var = gen_expr param expr in
    var_index var

  and gen_var_data param expr mid typ =
    let var = gen_expr param expr in
    let llvar = var_data var typ in
    (match mid with Some id -> Hashtbl.replace free_tbl id llvar | None -> ());
    llvar

  and gen_free param expr fs =
    let open Malloc_types in
    let expr = gen_expr param expr in
    let get_path path init =
      List.fold_right
        (fun index expr ->
          match index with
          | -1 ->
              (* Special case for rc get *)
              R.get expr
          | _ -> follow_field expr index)
        path init
    in
    (match fs with
    | Except fs ->
        List.iter
          (fun i ->
            (* Printf.printf "freeing except %i with paths %s, is %b\n" i.id *)
            (*   (show_pset i.paths) *)
            (*   (Option.is_some (Hashtbl.find_opt free_tbl i.id)); *)
            Option.iter
              (Auto.free_except param i.paths)
              (Hashtbl.find_opt free_tbl i.id))
          fs
    | Only fs ->
        List.iter
          (fun i ->
            (* Printf.printf "freeing only %i with paths %s\n" i.id *)
            (*   (show_pset i.paths); *)
            Option.iter
              (fun init ->
                (* TODO check for empty in monomorph_tree *)
                if Pset.is_empty i.paths then Auto.free param init
                else
                  Pset.iter
                    (fun path -> get_path path init |> Auto.free param)
                    i.paths)
              (Hashtbl.find_opt free_tbl i.id))
          fs);

    expr
end

and T : Lltypes_intf.S = Lltypes.Make (A)
and A : Abi_intf.S = Abi.Make (T)
and H : Helpers.S = Helpers.Make (T) (A) (Ar) (Auto)
and Ar : Arr_intf.S = Arr.Make (T) (H) (Core) (Auto)
and Auto : Autogen_intf.S = Autogen.Make (T) (H) (Ar) (R)
and R : Rc.S = Rc.Make (Core) (T) (H)

let fill_constants constants =
  let f (name, tree, toplvl) =
    let init = Core.gen_expr no_param tree in
    (* We only add records to the global table, because they are expected as ptrs.
       For ints or floats, we just return the immediate value *)
    let init =
      match init.kind with
      | Const_ptr ->
          (* Don't store ptr to another global *)
          let value = Llvm.global_initializer init.value |> Option.get in
          { init with value; kind = Const }
      | _ -> init
    in
    let value = Llvm.define_global name init.value the_module in
    Llvm.set_global_constant true value;
    if not toplvl then Llvm.set_linkage Llvm.Linkage.Internal value;
    Strtbl.add const_tbl name { init with value; kind = Const_ptr }
  in
  List.iter f constants

let def_globals globals =
  let f (name, expr, toplvl) =
    let typ = Monomorph_tree.(expr.typ) in
    let lltyp = T.get_lltype_def typ in
    let value =
      match expr.const with
      | Cnot -> (
          match typ with
          | Tunit -> H.dummy_fn_value.value
          | _ -> Llvm.const_bitcast (Llvm.const_int int_t 0) lltyp)
      | Const -> (
          let v = Core.gen_expr no_param expr in
          match v.kind with
          (* A global might point to another global or const. In this case, we
             don't want to global ptr to point to another pointer. Instead, we
             use the const value directly *)
          | Const_ptr -> Llvm.global_initializer v.value |> Option.get
          | _ -> v.value)
    in
    let value = Llvm.define_global name value the_module in
    Llvm.set_alignment (size_alignof_typ expr.typ |> snd) value;
    if not toplvl then Llvm.set_linkage Llvm.Linkage.Internal value;
    Strtbl.add const_tbl name { value; lltyp; typ = expr.typ; kind = Ptr }
  in
  List.iter f globals

let decl_external ~c_linkage ~closure cname = function
  | Tfun _ as t when (not (is_type_polymorphic t)) && not closure ->
      H.declare_function ~c_linkage cname t
  | typ ->
      let lltyp = T.get_lltype_def typ in
      let value = Llvm.declare_global lltyp cname the_module in
      (* TODO constness in module *)
      { value; typ; lltyp; kind = Ptr }

let has_init_code tree =
  let rec aux = function
    (* We have to deal with 'toplevel' type nodes only *)
    (* TODO toplevel let expressions do not produce globals *)
    | Monomorph_tree.Mlet (name, e, _, gname, _, cont) -> (
        let name = match gname with Some name -> name | None -> name in
        match Strtbl.find_opt const_tbl name with
        | Some thing -> (
            match thing.kind with
            | Const | Const_ptr ->
                (* is const, so no need to initialize *)
                aux cont.expr
            | Ptr | Imm -> ( match e.const with Cnot -> true | Const -> false))
        | None -> failwith "Internal Error: global value not found")
    | Mfunction (_, _, _, cont, _, _) -> aux cont.expr
    | Mconst Unit -> false
    | Mbind (_, _, cont) ->
        (* Bind itself does not need init *)
        aux cont.expr
    | _ -> true
  in
  aux Monomorph_tree.(tree.expr)

let add_global_init funcs outname start_loc kind body =
  let fname, glname =
    match kind with
    | `Ctor -> ("__" ^ outname ^ "_init", "llvm.global_ctors")
    | `Dtor -> ("__" ^ outname ^ "_deinit", "llvm.global_dtors")
  in
  let p =
    let upward = ref false in
    let func = Monomorph_tree.{ params = []; ret = Tunit; kind = Simple } in
    Core.gen_function funcs
      {
        name = { Monomorph_tree.user = fname; call = fname };
        recursive = Rnone;
        upward;
        abs = { func; pnames = []; body };
        monomorphized = false;
        func_loc = start_loc;
      }
  in
  let init = Vars.find fname p.vars in
  let open Llvm in
  set_linkage Linkage.Internal init.value;
  set_section ".text.startup" init.value;

  let init =
    [| const_int i32_t 65535; init.value; const_pointer_null ptr_t |]
  in
  let global = const_array global_t [| const_struct context init |] in
  let global = define_global glname global the_module in
  set_linkage Appending global

let declare_args () =
  let name = "__schmu_argv" and lltyp = ptr_t in
  let value = Llvm.const_null ptr_t in
  let value = Llvm.define_global name value the_module in
  Strtbl.add const_tbl name { value; lltyp; typ = Traw_ptr Tu8; kind = Ptr };

  let name = "__schmu_argc" and lltyp = int_t in
  let value = Llvm.const_null int_t in
  let value = Llvm.define_global name value the_module in
  Strtbl.add const_tbl name { value; lltyp; typ = Tint; kind = Ptr }

let add_args body ~loc =
  let open Monomorph_tree in
  let expr = Mvar ("__argv", Vnorm, None) in
  let var = { typ = Traw_ptr Tu8; expr; return = false; loc; const = Cnot } in
  let expr = Mlet ("", var, Lowned, Some "__schmu_argv", [], body) in
  let cont = { body with expr } in
  let expr = Mvar ("__argc", Vnorm, None) in
  let var = { typ = Tint; expr; return = false; loc; const = Cnot } in
  let expr = Mlet ("", var, Lowned, Some "__schmu_argc", [], cont) in
  { body with expr }

let generate ~target ~outname ~release ~modul ~args ~start_loc
    { Monomorph_tree.constants; globals; externals; tree; funcs; frees } =
  set_di_comp_unit ~filename:(outname ^ ".smu") ~directory:(Sys.getcwd ())
    ~is_optimized:release;

  let open Llvm_target in
  let triple =
    match target with
    | Some target -> target
    | None -> Llvm_target.Target.default_triple ()
  in
  Llvm_all_backends.initialize ();

  let target = Llvm_target.Target.by_triple triple in
  let reloc_mode = Llvm_target.RelocMode.PIC in
  let machine = TargetMachine.create ~triple target ~reloc_mode in
  let layout = DataLayout.as_string (TargetMachine.data_layout machine) in

  Llvm.set_data_layout layout the_module;

  (* Declare args up front if needed, that they are not declared as external *)
  if (not modul) && args then declare_args ();

  (* External declarations *)
  List.iter
    (fun { Monomorph_tree.ext_name = _; ext_typ; cname; c_linkage; closure } ->
      let v = decl_external cname ext_typ ~closure ~c_linkage in
      Strtbl.add const_tbl cname v)
    externals;

  (* Fill const_tbl *)
  fill_constants constants;
  def_globals globals;

  let funcs =
    let vars =
      List.fold_left
        (fun acc (func : Monomorph_tree.to_gen_func) ->
          let typ =
            Tfun (func.abs.func.params, func.abs.func.ret, func.abs.func.kind)
          in
          let fnc = H.declare_function ~c_linkage:false func.name.call typ in

          (* Add to the normal variable environment *)
          Vars.add func.name.call fnc acc)
        Vars.empty funcs
    in

    (* Generate functions *)
    List.fold_left
      (fun acc func -> Core.gen_function acc func)
      { no_param with vars } funcs
  in

  let free_mallocs tree frees =
    Monomorph_tree.
      { tree with expr = Mfree_after (tree, Except (List.of_seq frees)) }
  in

  if not modul then
    (* Add main *)
    let tree = free_mallocs tree frees in
    let upward = ref false in
    let body =
      if args then { (add_args tree ~loc:start_loc) with typ = Tint }
      else { tree with typ = Tint }
    in

    Core.gen_function funcs
      {
        name = { Monomorph_tree.user = "main"; call = "main" };
        recursive = Rnone;
        upward;
        abs =
          {
            func =
              {
                params =
                  [
                    { pt = Tint; pmut = false; pmoved = false };
                    { pt = Traw_ptr Tu8; pmut = false; pmoved = false };
                  ];
                ret = Tint;
                kind = Simple;
              };
            pnames = Mod_id.[ ("__argc", whatever); ("__argv", whatever) ];
            body;
          };
        monomorphized = false;
        func_loc = start_loc;
      }
    |> ignore
  else if has_init_code tree then (
    (* Or module init *)
    H.set_in_init true;
    add_global_init funcs outname start_loc `Ctor tree;

    (* Add frees to global dctors in reverse order *)
    if not (Seq.is_empty frees) then
      let loc = (Lexing.dummy_pos, Lexing.dummy_pos) in
      let body =
        Monomorph_tree.
          { typ = Tunit; expr = Mconst Unit; return = true; loc; const = Cnot }
      in
      add_global_init no_param outname start_loc `Dtor (free_mallocs body frees));
  (* Generate internal helper functions for arrays *)
  Auto.gen_functions ();

  Debug.dibuild_finalize dibuilder;

  (match Llvm_analysis.verify_module the_module with
  | Some output -> print_endline output
  | None -> ());

  (* Emit code to file *)
  if release then (
    let pm = Llvm.PassManager.create () in

    Llvm_ipo.add_function_inlining pm;
    Llvm_ipo.add_dead_arg_elimination pm;
    Llvm_ipo.add_constant_merge pm;
    Llvm_ipo.add_global_optimizer pm;
    Llvm_ipo.add_function_attrs pm;

    let bldr = Llvm_passmgr_builder.create () in
    Llvm_passmgr_builder.set_opt_level 2 bldr;
    Llvm_passmgr_builder.populate_module_pass_manager pm bldr;

    (* if not modul then Llvm_ipo.add_internalize pm ~all_but_main:true; *)
    for _ = 0 to 4 do
      Llvm.PassManager.run_module the_module pm |> ignore
    done);

  TargetMachine.emit_to_file the_module CodeGenFileType.ObjectFile
    (outname ^ ".o") machine
