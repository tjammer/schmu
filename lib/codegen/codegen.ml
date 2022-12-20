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
let const_pass = ref true

module rec Core : sig
  val gen_expr : param -> Monomorph_tree.monod_tree -> llvar

  val gen_function :
    param -> mangle:mangle_kind -> Monomorph_tree.to_gen_func -> param
end = struct
  open T
  open A
  open H
  open Ar

  let decr_tbl = Strtbl.create 64

  let rec gen_function vars ~mangle
      { Monomorph_tree.abs; name; recursive; upward } =
    let typ = Monomorph_tree.typ_of_abs abs in

    match typ with
    | Tfun (tparams, ret_t, kind) as typ ->
        let func = declare_function ~c_linkage:false mangle name.call typ in

        let start_index, alloca =
          match ret_t with
          | (Trecord _ | Tvariant _ | Tfun _) as t -> (
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
        let tvars = add_closure vars.vars func (upward ()) kind in

        (* Add parameters to env *)
        let tvars, rec_block =
          add_params tvars func name abs.pnames tparams start_index recursive
        in

        let fun_finalize ret =
          (* If we want to return a struct, we copy the struct to
              its ptr (1st parameter) and return void *)
          match ret.typ with
          | (Trecord _ | Tvariant _ | Tfun _) as t -> (
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
          { vars = tvars; alloca; finalize; rec_block; in_set = false }
        in
        let ret = gen_expr param abs.body in

        (match recursive with
        | Rtail -> tail_return param tparams start_index
        | Rnone | Rnormal -> ());
        ignore (fun_return name.call ret);

        (* if Llvm_analysis.verify_function func.value |> not then ( *)
        (*   Llvm.dump_module the_module; *)
        (*   (\* To generate the report *\) *)
        (*   Llvm_analysis.assert_valid_function func.value); *)
        let _ = Llvm.PassManager.run_function func.value fpm in
        { vars with vars = Vars.add name.call func vars.vars }
    | _ ->
        prerr_endline name.call;
        failwith "Interal Error: generating non-function"

  and gen_expr param typed_expr =
    let fin e =
      match (typed_expr.return, param.finalize) with
      | true, Some f ->
          f e;
          e
      | true, None | false, _ -> e
    in

    match typed_expr.expr with
    | Mconst (String (s, allocref, rf)) ->
        gen_string_lit param s typed_expr.typ allocref rf
    | Mconst (Array (arr, allocref, id)) ->
        let v = gen_array_lit param arr typed_expr.typ allocref in
        Hashtbl.replace decr_tbl id v;
        v
    | Mconst c -> gen_const c |> fin
    | Mbop (bop, e1, e2) -> gen_bop param e1 e2 bop |> fin
    | Munop (_, e) -> gen_unop param e |> fin
    | Mvar (id, kind) -> gen_var param.vars typed_expr.typ id kind |> fin
    | Mfunction (name, abs, cont, allocref) ->
        (* The functions are already generated *)
        let func =
          match Vars.find_opt name param.vars with
          | Some func -> (
              match abs.func.kind with
              | Closure assoc -> gen_closure_obj param assoc func name allocref
              | Simple when is_prealloc allocref ->
                  gen_closure_obj param [] func name allocref
              | Simple -> func)
          | None ->
              (* The function is polymorphic and monomorphized versions are generated. *)
              (* We just return some bogus value, it will never be applied anyway
                 (and if it will, LLVM will fail) *)
              dummy_fn_value
        in

        gen_expr { param with vars = Vars.add name func param.vars } cont
    | Mlet (id, equals, _, vid, let') -> gen_let param id equals let' vid
    | Mlambda (name, abs, allocref) ->
        let func =
          match Vars.find_opt name param.vars with
          | Some func -> (
              match abs.func.kind with
              | Closure assoc -> gen_closure_obj param assoc func name allocref
              | Simple when is_prealloc allocref ->
                  gen_closure_obj param [] func name allocref
              | Simple -> func)
          | None ->
              (* The function is polymorphic and monomorphized versions are generated. *)
              (* We just return some bogus value, it will never be applied anyway
                 (and if it will, LLVM will fail) *)
              dummy_fn_value
        in
        func |> fin
    | Mapp { callee; args; alloca; id = _; vid } ->
        let value =
          match (typed_expr.return, callee.monomorph, param.rec_block) with
          | true, Recursive _, Some block ->
              gen_app_tailrec param callee args block typed_expr.typ
          | _, Builtin (b, bfn), _ -> gen_app_builtin param (b, bfn) args alloca
          | _, Inline (pnames, tree), _ -> gen_app_inline param args pnames tree
          | _ -> gen_app param callee args alloca typed_expr.typ
        in
        (match vid with
        | Some id -> Strtbl.replace decr_tbl id value
        | None -> ());
        fin value
    | Mif expr -> gen_if param expr typed_expr.return
    | Mrecord (labels, allocref, id, const) ->
        gen_record param typed_expr.typ labels allocref id const
          typed_expr.return
        |> fin
    | Mfield (expr, index) -> gen_field param expr index |> fin
    | Mset (expr, value) -> gen_set param expr value |> fin
    | Mseq (expr, cont) -> gen_chain param expr cont
    | Mctor (ctor, allocref, id, const) ->
        gen_ctor param ctor typed_expr.typ allocref id const
    | Mvar_index expr -> gen_var_index param expr |> fin
    | Mvar_data expr -> gen_var_data param expr typed_expr.typ |> fin
    | Mfmt (fmts, allocref, id) ->
        gen_fmt_str param fmts typed_expr.typ allocref id |> fin
    | Mcopy { kind; temporary; expr; nm } ->
        (match kind with
        | Cglobal gn -> gen_copy_global param temporary gn expr
        | Cnormal mut -> gen_copy param temporary mut expr nm)
        |> fin
    | Mincr_ref expr -> gen_incr_ref param expr |> fin
    | Mdecr_ref (id, expr) -> gen_decr_ref param id expr |> fin

  and gen_let param id equals cont vid =
    let expr_val = gen_expr param equals in
    (match vid with
    | Some id -> Strtbl.replace decr_tbl id expr_val
    | None -> ());
    gen_expr { param with vars = Vars.add id expr_val param.vars } cont

  and gen_const = function
    | Int i ->
        let value = Llvm.const_int int_t i in
        { value; typ = Tint; lltyp = int_t; kind = Const }
    | Bool b ->
        let value = Llvm.const_int bool_t (Bool.to_int b) in
        { value; typ = Tbool; lltyp = bool_t; kind = Const }
    | U8 c ->
        let value = Llvm.const_int u8_t (Char.code c) in
        { value; typ = Tu8; lltyp = u8_t; kind = Const }
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
    | String _ | Array _ -> failwith "In other branch"

  and gen_var vars typ id kind =
    match kind with
    | Vnorm -> (
        match Vars.find_opt id vars with
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
    | Vconst | Vglobal -> Strtbl.find const_tbl id

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
    | Plus_i ->
        { value = bld build_add "add"; typ = Tint; lltyp = int_t; kind = Imm }
    | Minus_i ->
        { value = bld build_sub "sub"; typ = Tint; lltyp = int_t; kind = Imm }
    | Mult_i ->
        { value = bld build_mul "mul"; typ = Tint; lltyp = int_t; kind = Imm }
    | Div_i ->
        { value = bld build_sdiv "div"; typ = Tint; lltyp = int_t; kind = Imm }
    | Less_i ->
        let value = bld (build_icmp Icmp.Slt) "lt" in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | Greater_i ->
        let value = bld (build_icmp Icmp.Sgt) "gt" in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | Equal_i ->
        let value = bld (build_icmp Icmp.Eq) "eq" in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | Plus_f ->
        let value = bld build_fadd "add" in
        { value; typ = Tfloat; lltyp = float_t; kind = Imm }
    | Minus_f ->
        let value = bld build_fsub "sub" in
        { value; typ = Tfloat; lltyp = float_t; kind = Imm }
    | Mult_f ->
        let value = bld build_fmul "mul" in
        { value; typ = Tfloat; lltyp = float_t; kind = Imm }
    | Div_f ->
        let value = bld build_fdiv "div" in
        { value; typ = Tfloat; lltyp = float_t; kind = Imm }
    | Less_f ->
        let value = bld (build_fcmp Fcmp.Olt) "lt" in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | Greater_f ->
        let value = bld (build_fcmp Fcmp.Ogt) "gt" in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }
    | Equal_f ->
        let value = bld (build_fcmp Fcmp.Oeq) "eq" in
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

          (* In case the record passed is constant, we allocate it here to pass
             a pointer. This isn't pretty, but will do for now. For the single
             param, unboxed case we can skip boxing *)
          let arg =
            match (arg'.typ, pkind_of_typ oarg.mut arg'.typ, arg'.kind) with
            (* The [Two_params] case is tricky to do using only consts,
               so we box and use the standard runtime version *)
            | (Trecord _ | Tvariant _), Boxed, Const
            | (Trecord _ | Tvariant _), Unboxed (Two_params _), Const ->
                box_const param arg'
            | _ -> get_mono_func arg' param oarg.monomorph
          in

          match pass_value oarg.mut arg with
          | fst, Some snd ->
              (* We can skip [func_to_closure] in this case *)
              (* snd before fst, b/c we rev at the end *)
              snd :: fst :: args
          | value, None ->
              let arg = { arg with value } in
              (func_to_closure param arg).value :: args)
        [] args
      |> List.rev |> List.to_seq
    in

    (* No names here, might be void/unit *)
    let funcval, envarg =
      if Llvm.type_of func.value = (closure_t |> Llvm.pointer_type) then
        (* Function to call is a closure (or a function passed into another one).
           We get the funptr from the first field, cast to the correct type,
           then get env ptr (as voidptr) from the second field and pass it as last argument *)
        let funcp = Llvm.build_struct_gep func.value 0 "funcptr" builder in
        let funcp = Llvm.build_load funcp "loadtmp" builder in
        let typ = typeof_funclike func.typ |> Llvm.pointer_type in
        let funcp = Llvm.build_bitcast funcp typ "casttmp" builder in

        let env_ptr = Llvm.build_struct_gep func.value 1 "envptr" builder in
        let env_ptr = Llvm.build_load env_ptr "loadtmp" builder in
        (funcp, Seq.return env_ptr)
      else
        match kind with
        | Simple -> (func.value, Seq.empty)
        | Closure _ -> (
            (* In this case we are in a recursive closure function.
               We get the closure env and add it to the arguments we pass *)
            match
              Vars.find_opt
                (Llvm.value_name func.value |> unmangle (Schmu ""))
                param.vars
            with
            | Some func ->
                (* We do this to make sure it's a recursive function.
                   If we cannot find something. there is an error somewhere *)
                let closure_index =
                  (Llvm.params func.value |> Array.length) - 1
                in

                let env_ptr = (Llvm.params func.value).(closure_index) in
                (func.value, Seq.return env_ptr)
            | None ->
                failwith "Internal Error: Not a recursive closure application")
    in

    let value, lltyp =
      match ret_t with
      | (Trecord _ | Tvariant _ | Tfun _) as t -> (
          let lltyp = get_lltype_def ret_t in
          match pkind_of_typ false t with
          | Boxed ->
              let retval = get_prealloc !allocref param lltyp "ret" in
              let ret' = Seq.return retval in
              let args = ret' ++ args ++ envarg |> Array.of_seq in
              ignore (Llvm.build_call funcval args "" builder);
              (retval, lltyp)
          | Unboxed size ->
              (* Boxed representation *)
              let retval = get_prealloc !allocref param lltyp "ret" in
              let args = args ++ envarg |> Array.of_seq in
              (* Unboxed representation *)
              let tempval = Llvm.build_call funcval args "" builder in
              let ret =
                box_record ~size ~alloc:(Some retval) ~snd_val:None t tempval
              in
              (ret, lltyp))
      | t ->
          let args = args ++ envarg |> Array.of_seq in
          let retval = Llvm.build_call funcval args "" builder in
          (retval, get_lltype_param false t)
    in

    { value; typ = ret; lltyp; kind = default_kind ret }

  and gen_app_tailrec param callee args rec_block ret_t =
    (* We evaluate, there might be side-effects *)
    let func = gen_expr param callee.ex in

    let start_index, ret =
      match func.typ with
      | Tfun (_, (Trecord _ as r), _) | Tfun (_, (Tvariant _ as r), _) -> (
          match pkind_of_typ false r with
          | Boxed -> (1, r)
          | Unboxed size -> (0, type_unboxed size))
      | Tfun (_, ret, _) -> (0, ret)
      | Tunit ->
          failwith "Internal Error: Probably cannot find monomorphized function"
      | _ -> failwith "Internal Error: Not a func in gen app tailrec"
    in

    let handle_arg i (oarg, is_arg) =
      let arg' = gen_expr param Monomorph_tree.(oarg.ex) in
      let arg = get_mono_func arg' param oarg.monomorph in
      let llvar = func_to_closure param arg in

      let i = get_index i oarg.mut arg.typ in
      let alloca = Vars.find (name_of_alloc_param i) param.vars in

      if not is_arg then tail_decr_param param alloca i oarg.mut;

      (* We store the params in pre-allocated variables *)
      (if llvar.value <> alloca.value then
       let store = if oarg.mut then tailrec_store else store_or_copy in
       store ~src:llvar ~dst:alloca.value);
      i + 1
    in

    ignore (List.fold_left handle_arg start_index args);

    let lltyp =
      (* TODO record *)
      match ret with
      | Trecord _ | Tvariant _ -> get_lltype_def ret_t
      | t -> get_lltype_param false t
    in

    let value = Llvm.build_br rec_block.rec_ builder in
    { value; typ = Tpoly "tail"; lltyp; kind = default_kind ret }

  and gen_app_builtin param (b, fnc) args allocref =
    let handle_arg (arg, _) =
      let arg' = gen_expr param Monomorph_tree.(arg.ex) in
      let arg = get_mono_func arg' param arg.monomorph in

      (* For [ignore], we don't really need to generate the closure objects here *)
      match b with Ignore -> arg | _ -> func_to_closure param arg
    in
    let args = List.map handle_arg args in

    let cast f lltyp typ =
      match args with
      | [ value ] ->
          let value = f (bring_default value) lltyp "" builder in
          (* TODO Not always int. That's a bug *)
          { value; typ; lltyp; kind = Imm }
      | _ -> failwith "Internal Error: Arity mismatch in builtin"
    in

    match b with
    | Builtin.Unsafe_ptr_get ->
        let ptr, index =
          match args with
          | [ ptr; index ] -> (bring_default ptr, bring_default index)
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        let value = Llvm.build_in_bounds_gep ptr [| index |] "" builder in
        { value; typ = fnc.ret; lltyp = get_lltype_def fnc.ret; kind = Ptr }
    | Unsafe_ptr_set ->
        let ptr, index, value =
          match args with
          | [ ptr; index; value ] ->
              (bring_default ptr, bring_default index, bring_default_var value)
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        let ptr = Llvm.build_in_bounds_gep ptr [| index |] "" builder in

        set_struct_field value ptr;
        { dummy_fn_value with lltyp = unit_t }
    | Unsafe_ptr_at ->
        let ptr, index =
          match args with
          | [ ptr; index ] -> (bring_default ptr, bring_default index)
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        let value = Llvm.build_in_bounds_gep ptr [| index |] "" builder in
        { value; typ = fnc.ret; lltyp = get_lltype_def fnc.ret; kind = Imm }
    | Mod -> (
        match args with
        | [ value; md ] ->
            let value =
              Llvm.build_srem (bring_default value) (bring_default md) "mod"
                builder
            in
            { value; typ = Tint; lltyp = int_t; kind = Imm }
        | _ -> failwith "Internal Error: Arity mismatch in builtin")
    | Array_get -> array_get ~in_set:param.in_set args fnc.ret
    | Array_set -> array_set args
    | Array_length -> array_length args
    | Array_push -> array_push args
    | Array_drop_back -> array_drop_back args
    | Array_data -> array_data args
    | Unsafe_array_create -> unsafe_array_create param args fnc.ret allocref
    | Unsafe_nullptr ->
        let value = Llvm.const_null voidptr_t in
        { value; typ = Traw_ptr Tunit; lltyp = voidptr_t; kind = Const }
    | Realloc ->
        let ptr, size =
          match args with
          | [ ptr; size ] ->
              let item_size =
                match ptr.typ with
                | Traw_ptr t -> sizeof_typ t |> Llvm.const_int int_t
                | _ ->
                    print_endline (show_typ ptr.typ);
                    failwith "Internal Error: Nonptr return of alloc"
              in
              let size = Llvm.build_mul size.value item_size "" builder in
              (ptr, size)
          | _ -> failwith "Internal Error: Arity mismatch in builtin"
        in
        let value = realloc (bring_default ptr) ~size in
        ignore (Llvm.build_store value ptr.value builder);
        { dummy_fn_value with lltyp = unit_t }
    | Malloc ->
        let item_size =
          match fnc.ret with
          | Traw_ptr t -> sizeof_typ t |> Llvm.const_int int_t
          | _ -> failwith "Internal Error: Nonptr return of alloc"
        in

        let size =
          match args with
          | [ size ] -> Llvm.build_mul size.value item_size "" builder
          | _ -> failwith "Internal Error: Arity mismatch in builder"
        in
        let ptr_typ = get_lltype_def fnc.ret in
        let value = malloc ~size in
        let value = Llvm.build_bitcast value ptr_typ "" builder in

        { value; typ = fnc.ret; lltyp = get_lltype_def fnc.ret; kind = Ptr }
    | Ignore -> dummy_fn_value
    | Int_of_float | Int_of_f32 -> cast Llvm.build_fptosi int_t Tint
    | Int_of_i32 -> cast Llvm.build_intcast int_t Tint
    | Float_of_int | Float_of_i32 -> cast Llvm.build_sitofp float_t Tfloat
    | Float_of_f32 -> cast Llvm.build_fpcast float_t Tfloat
    | I32_of_float | I32_of_f32 -> cast Llvm.build_fptosi i32_t Ti32
    | I32_of_int -> cast Llvm.build_intcast i32_t Ti32
    | F32_of_int | F32_of_i32 -> cast Llvm.build_sitofp f32_t Tf32
    | F32_of_float -> cast Llvm.build_fpcast f32_t Tf32
    | U8_of_int -> cast Llvm.build_intcast u8_t Tu8
    | U8_to_int -> cast Llvm.build_intcast int_t Tu8
    | Not ->
        let value =
          match args with
          | [ value ] -> value.value
          | _ -> failwith "Interal Error: Arity mismatch in builder"
        in

        let true_value = Llvm.const_int bool_t (Bool.to_int true) in
        let value = Llvm.build_xor value true_value "" builder in
        { value; typ = Tbool; lltyp = bool_t; kind = Imm }

  and gen_app_inline param args names tree =
    (* Identify args to param names *)
    let f env (arg, _) param =
      let arg' = gen_expr env Monomorph_tree.(arg.ex) in
      let arg = get_mono_func arg' env arg.monomorph in

      let vars = Vars.add param arg env.vars in
      { env with vars }
    in
    let env = List.fold_left2 f param args names in
    gen_expr env tree

  and gen_if param expr return =
    (* If a function ends in a if expression (and returns a struct),
       we pass in the finalize step. This allows us to handle the branches
       differently and enables tail call elimination *)
    ignore return;

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
                    Llvm.position_at_end then_bb builder;
                    let value = alloca param e1.lltyp "" in
                    ignore (Llvm.build_store (bring_default e1) value builder);
                    ({ e1 with value; kind = Const_ptr }, e2)
                | (Const | Imm), (Ptr | Const_ptr) ->
                    (e1, { e2 with value = bring_default e2; kind = e1.kind })
                | (Ptr | Const_ptr), Const when is_struct e2.typ ->
                    let value = alloca param e2.lltyp "" in
                    ignore (Llvm.build_store (bring_default e2) value builder);
                    (e1, { e2 with value; kind = Const_ptr })
                | (Ptr | Const_ptr), (Const | Imm) ->
                    Llvm.position_at_end then_bb builder;
                    ({ e1 with value = bring_default e1; kind = e2.kind }, e2)
                | _, _ -> (e1, e2)
              in

              if e1.value <> e2.value then (
                Llvm.position_at_end (Lazy.force merge_bb) builder;
                let incoming = [ (e1.value, e1_bb); (e2.value, e2_bb) ] in
                let value = Llvm.build_phi incoming "iftmp" builder in
                { value; typ = e1.typ; lltyp = e2.lltyp; kind = e1.kind })
              else e1)
    in

    Llvm.position_at_end start_bb builder;
    ignore (Llvm.build_cond_br cond then_bb else_bb builder);

    if not (is_tailcall e1) then (
      Llvm.position_at_end e1_bb builder;
      ignore (Llvm.build_br (Lazy.force merge_bb) builder));
    if not (is_tailcall e2) then (
      Llvm.position_at_end e2_bb builder;
      ignore (Llvm.build_br (Lazy.force merge_bb) builder));

    if Lazy.is_val merge_bb then
      Llvm.position_at_end (Lazy.force merge_bb) builder;
    (match expr.iid with
    | Some id -> Strtbl.replace decr_tbl id llvar
    | None -> ());
    llvar

  and gen_record param typ labels allocref id const return =
    let lltyp = get_lltype_def typ in

    let value, kind =
      match const with
      | false ->
          let record = get_prealloc !allocref param lltyp "" in

          List.iteri
            (fun i (name, expr) ->
              let ptr = Llvm.build_struct_gep record i name builder in
              let value =
                gen_expr { param with alloca = Some ptr } expr
                |> (* Const records will stay const, no allocation done to lift
                      it to Ptr. Thus, it stays Const*)
                bring_default_var |> func_to_closure param
              in
              set_struct_field value ptr)
            labels;
          (record, Ptr)
      | true when not !const_pass ->
          (* We generate the const for runtime use. An addition to
             re-generating the constants, there are immediate literals.
             We have to take care that some global constants are pointers now *)
          let value =
            let f (_, expr) =
              let e = gen_expr param expr in
              match e.kind with
              | Const_ptr ->
                  (* The global value is a ptr, we need to 'deref' it *)
                  Llvm.global_initializer e.value |> Option.get
              | _ -> e.value
            in
            let values = List.map f labels |> Array.of_list in
            Llvm.const_named_struct lltyp values
          in
          (* The value might be returned, thus boxed, so we wrap it in an automatic var *)
          if return then (
            let record = get_prealloc !allocref param lltyp "" in
            ignore (Llvm.build_store value record builder);
            (record, Const_ptr))
          else (value, Const)
      | true ->
          let values =
            List.map (fun (_, expr) -> (gen_expr param expr).value) labels
            |> Array.of_list
          in
          let ret = Llvm.const_named_struct lltyp values in
          (ret, Const)
    in

    let v = { value; typ; lltyp; kind } in
    (match id with Some id -> Strtbl.replace decr_tbl id v | None -> ());
    v

  and gen_field param expr index =
    let typ =
      match expr.typ with
      | Trecord (_, _, fields) -> fields.(index).ftyp
      | _ ->
          print_endline (show_typ expr.typ);
          failwith "Internal Error: No record in fields"
    in

    let value = gen_expr param expr in

    let value, kind =
      match value.kind with
      | Const_ptr | Ptr ->
          let p = Llvm.build_struct_gep value.value index "" builder in
          (* In case we return a record, we don't load, but return the pointer.
             The idea is that this will be used either as a return value for a function (where it is copied),
             or for another field, where the pointer is needed.
             We should distinguish between structs and pointers somehow *)
          (p, Ptr)
      | Const ->
          (* If the record is const, we use extractvalue and propagate the constness *)
          let p = Llvm.(const_extractvalue value.value [| index |]) in
          (p, Const)
      | Imm -> failwith "Internal Error: Did not expect Imm in field"
    in

    { value; typ; lltyp = get_lltype_def typ; kind }

  and gen_set param expr valexpr =
    let ptr = gen_expr { param with in_set = true } expr in
    let value = gen_expr param valexpr in
    decr_refcount ptr;
    (* We know that ptr cannot be a constant record, but value might *)
    set_struct_field value ptr.value;
    { dummy_fn_value with lltyp = unit_t }

  and gen_chain param expr cont =
    ignore (gen_expr param expr);
    gen_expr param cont

  and gen_string_lit param s typ allocref rf =
    let lltyp = get_lltype_def typ in
    let ptr = get_const_string ~rf:(Some rf) s in

    (* Check for preallocs *)
    let string = get_prealloc !allocref param lltyp "str" in

    ignore (Llvm.build_store ptr string builder);
    { value = string; typ; lltyp; kind = Ptr }

  and gen_ctor param (variant, tag, expr) typ allocref id const =
    ignore const;

    (* This approach means we alloca every time, even if the enum
       ends up being a clike constant. There's room for improvement here *)
    let lltyp = get_struct typ in
    let var = get_prealloc !allocref param lltyp variant in

    (* Set tag *)
    let tagptr = Llvm.build_struct_gep var 0 "tag" builder in
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
        let dataptr = Llvm.build_struct_gep var 1 "data" builder in
        let ptr_t = get_lltype_def expr.typ |> Llvm.pointer_type in
        let ptr = Llvm.build_bitcast dataptr ptr_t "" builder in
        let data =
          gen_expr { param with alloca = Some ptr } expr |> bring_default_var
        in

        let dataptr =
          Llvm.build_bitcast dataptr
            (data.lltyp |> Llvm.pointer_type)
            "data" builder
        in
        set_struct_field data dataptr
    | None -> ());
    let v = { value = var; typ; lltyp; kind = Ptr } in
    (match id with Some id -> Strtbl.replace decr_tbl id v | None -> ());
    v

  and gen_var_index param expr =
    let var = gen_expr param expr in
    var_index var

  and gen_var_data param expr typ =
    let var = gen_expr param expr in
    var_data var typ

  and gen_fmt_str param exprs typ allocref id =
    let snprintf_decl =
      lazy
        Llvm.(
          let ft =
            var_arg_function_type i32_t [| voidptr_t; int_t; voidptr_t |]
          in
          declare_function "snprintf" ft the_module)
    in
    let lltyp = get_lltype_def typ in

    let f (fmtstr, args) expr =
      match expr with
      | Monomorph_tree.Fstr s -> (fmtstr ^ s, args)
      | Fexpr e ->
          let value = gen_expr param e in
          let str, value = fmt_str value in
          (fmtstr ^ str, value :: args)
    in
    let fmt, args = List.fold_left f ("", []) exprs in
    (* Calculate size *)
    let fmtptr =
      get_const_string fmt |> fun value ->
      array_data [ { value; kind = Imm; typ; lltyp } ]
    in
    let itemargs = List.rev args in
    let args =
      Llvm.const_pointer_null voidptr_t
      :: Llvm.const_int int_t 0 :: fmtptr.value :: itemargs
      |> Array.of_list
    in
    let ssize =
      Llvm.build_call (Lazy.force snprintf_decl) args "fmtsize" builder
    in
    (* Add null terminator (and rc head) *)
    let _, llitem_typ, head_size, _ = item_type_head_size typ in
    let size =
      Llvm.build_add ssize (Llvm.const_int i32_t (head_size + 1)) "" builder
    in
    let size = Llvm.build_intcast size int_t "" builder in
    let arr_ptr =
      malloc ~size |> fun ptr -> Llvm.build_bitcast ptr lltyp "" builder
    in

    (* Initialize counts *)
    let ci i = Llvm.const_int int_t i in
    let int_ptr =
      Llvm.build_bitcast arr_ptr (Llvm.pointer_type int_t) "" builder
    in
    let dst = Llvm.build_gep int_ptr [| ci 0 |] "ref" builder in
    (* refcount of 1 *)
    ignore (Llvm.build_store (ci 1) dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 1 |] "size" builder in
    let ssize = Llvm.build_intcast ssize int_t "" builder in
    ignore (Llvm.build_store ssize dst builder);
    let dst = Llvm.build_gep int_ptr [| ci 2 |] "cap" builder in
    ignore (Llvm.build_store ssize dst builder);
    let ptr =
      Llvm.build_gep int_ptr [| ci 3 |] "data" builder |> fun ptr ->
      Llvm.build_bitcast ptr (Llvm.pointer_type llitem_typ) "" builder
    in

    (* Format string *)
    (* [size] argument here is not really correct (head_size is added),
       but we made sure it's enough *)
    let args = ptr :: size :: fmtptr.value :: itemargs |> Array.of_list in
    ignore (Llvm.build_call (Lazy.force snprintf_decl) args "fmt" builder);

    (* Build string record *)
    let string = get_prealloc !allocref param lltyp "str" in
    ignore (Llvm.build_store arr_ptr string builder);

    let v = { value = string; typ; lltyp; kind = Ptr } in
    Hashtbl.replace decr_tbl id v;
    v

  and gen_copy param temp mut expr nm =
    let v = gen_expr param expr in
    if not temp then incr_refcount v;
    if is_struct v.typ then
      if not temp then (
        let dst = alloca param (get_lltype_def v.typ) nm in
        memcpy ~src:v ~dst ~size:(sizeof_typ v.typ |> llval_of_size);
        { v with value = dst })
      else v
    else
      match v.kind with
      | Const_ptr | Ptr ->
          if mut && not temp then (
            let dst = alloca param (get_lltype_def v.typ) nm in
            memcpy ~src:v ~dst ~size:(sizeof_typ v.typ |> llval_of_size);
            { v with value = dst })
          else if mut then v
          else
            let value = Llvm.build_load v.value nm builder in
            { v with value; kind = Imm }
      | Const | Imm ->
          if mut then (
            let dst = alloca param (get_lltype_def v.typ) nm in
            ignore (Llvm.build_store v.value dst builder);
            { v with value = dst; kind = Ptr })
          else v

  and gen_copy_global param temporary gn expr =
    let dst = Strtbl.find const_tbl gn in
    let v = gen_expr { param with alloca = Some dst.value } expr in
    (* Bandaid for polymorphic first class functions. In monomorph pass, the
       global is ignored. TODO. Here, we make sure that the dummy_fn_value is
       not set to the global. The global will stay 0 forever *)
    match v.typ with
    | Tunit -> v
    | _ ->
        let src = bring_default_var v in
        if not temporary then incr_refcount src;

        (* Only copy if the alloca was not used
           (for whatever reason; it should have been used) *)
        if v.value <> dst.value then store_or_copy ~src ~dst:dst.value;
        let v = { v with value = dst.value; kind = Ptr } in
        Strtbl.replace const_tbl gn v;
        v

  and gen_incr_ref param expr =
    let v = gen_expr param expr in
    incr_refcount v;
    v

  and gen_decr_ref param id expr =
    let v = gen_expr param expr in
    match Hashtbl.find_opt decr_tbl id with
    | Some id ->
        decr_refcount id;
        v
    | None ->
        print_int id;
        print_newline ();
        failwith "Internal Error: Nothing to decr"
end

and T : Lltypes_intf.S = Lltypes.Make (A)
and A : Abi_intf.S = Abi.Make (T)
and H : Helpers.S = Helpers.Make (T) (A) (Ar)
and Ar : Arr_intf.S = Arr.Make (T) (H) (Core)

let fill_constants constants =
  let f (name, tree, toplvl) =
    let init = Core.gen_expr no_param tree in
    (* We only add records to the global table, because they are expected as ptrs.
       For ints or floats, we just return the immediate value *)
    let value = Llvm.define_global name init.value the_module in
    Llvm.set_global_constant true value;
    if not toplvl then Llvm.set_linkage Llvm.Linkage.Internal value;
    Strtbl.add const_tbl name { init with value; kind = Const_ptr }
  in
  List.iter f constants

let def_globals globals =
  let f (name, typ, toplvl) =
    let lltyp = T.get_lltype_def typ in
    let null = Llvm.const_int int_t 0 in
    let value =
      Llvm.define_global name (Llvm.const_bitcast null lltyp) the_module
    in
    Llvm.set_alignment (sizeof_typ typ) value;
    if not toplvl then Llvm.set_linkage Llvm.Linkage.Internal value;
    Strtbl.add const_tbl name { value; lltyp; typ; kind = Ptr }
  in
  List.iter f globals

let decl_external ~c_linkage ~closure cname = function
  | Tfun _ as t when (not (is_type_polymorphic t)) && not closure ->
      H.declare_function ~c_linkage C cname t
  | typ ->
      let lltyp = T.get_lltype_def typ in
      let value = Llvm.declare_global lltyp cname the_module in
      (* TODO constness in module *)
      { value; typ; lltyp; kind = Ptr }

let has_init_code tree =
  let rec aux = function
    (* We have to deal with 'toplevel' type nodes only *)
    (* TODO toplevel let expressions do not produce globals *)
    | Monomorph_tree.Mlet (name, _, gname, _, cont) -> (
        let name = match gname with Some name -> name | None -> name in
        match Strtbl.find_opt const_tbl name with
        | Some thing -> (
            match thing.kind with
            | Const | Const_ptr ->
                (* is const, so no need to initialize *)
                aux cont.expr
            | Ptr | Imm -> true)
        | None -> failwith "Internal Error: global value not found")
    | Mfunction (_, _, cont, _) -> aux cont.expr
    | Mconst Unit -> false
    | _ -> true
  in
  aux Monomorph_tree.(tree.expr)

let add_global_init funcs outname kind body =
  let fname, glname =
    match kind with
    | `Ctor -> ("__" ^ outname ^ "_init", "llvm.global_ctors")
    | `Dtor -> ("__" ^ outname ^ "_deinit", "llvm.global_dtors")
  in
  let p =
    let upward () = false in
    Core.gen_function funcs ~mangle:C
      {
        name = { Monomorph_tree.user = fname; call = fname };
        recursive = Rnone;
        upward;
        abs =
          {
            func = { params = []; ret = Tunit; kind = Simple };
            pnames = [];
            body;
          };
      }
  in
  let init = Vars.find fname p.vars in
  let open Llvm in
  set_linkage Linkage.Internal init.value;
  set_section ".text.startup" init.value;

  let init =
    [| const_int i32_t 65535; init.value; const_pointer_null voidptr_t |]
  in
  let global = const_array global_t [| const_struct context init |] in
  let global = define_global glname global the_module in
  set_linkage Appending global

let generate ~target ~outname ~release ~modul
    { Monomorph_tree.constants; globals; externals; tree; funcs; decrs } =
  let mangle = match modul with None -> Schmu "schmu" | Some m -> Schmu m in
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

  (* Fill const_tbl *)
  fill_constants constants;
  def_globals globals;
  const_pass := false;

  (* External declarations *)
  List.iter
    (fun { Monomorph_tree.ext_name = _; ext_typ; cname; c_linkage; closure } ->
      let v = decl_external cname ext_typ ~closure ~c_linkage in
      Strtbl.add const_tbl cname v)
    externals;

  (* Factor out functions for llvm *)
  let funcs =
    let vars =
      List.fold_left
        (fun acc (func : Monomorph_tree.to_gen_func) ->
          let typ =
            Tfun (func.abs.func.params, func.abs.func.ret, func.abs.func.kind)
          in
          let fnc =
            H.declare_function ~c_linkage:false mangle func.name.call typ
          in

          (* Add to the normal variable environment *)
          Vars.add func.name.call fnc acc)
        Vars.empty funcs
    in

    (* Generate functions *)
    List.fold_left
      (fun acc func -> Core.gen_function ~mangle acc func)
      { vars; alloca = None; finalize = None; rec_block = None; in_set = false }
      funcs
  in

  let decr_refs tree =
    Seq.fold_left
      (fun tree id -> Monomorph_tree.{ tree with expr = Mdecr_ref (id, tree) })
      tree
  in

  (match modul with
  | None ->
      (* Add main *)
      let tree = decr_refs tree decrs in
      let upward () = false in
      Core.gen_function funcs ~mangle:C
        {
          name = { Monomorph_tree.user = "main"; call = "main" };
          recursive = Rnone;
          upward;
          abs =
            {
              func =
                {
                  params = [ { pt = Tint; pmut = false } ];
                  ret = Tint;
                  kind = Simple;
                };
              pnames = [ "arg" ];
              body = { tree with typ = Tint };
            };
        }
      |> ignore
  | Some _ when has_init_code tree ->
      (* Or module init *)
      H.set_in_init true;
      add_global_init funcs outname `Ctor tree;

      (* Add frees to global dctors in reverse order *)
      if not (Seq.is_empty decrs) then
        let body =
          Monomorph_tree.{ typ = Tunit; expr = Mconst Unit; return = true }
        in
        add_global_init no_param outname `Dtor (decr_refs body decrs)
  | Some _ -> ());
  (* Generate internal helper functions for arrays *)
  Ar.gen_functions ();

  (match Llvm_analysis.verify_module the_module with
  | Some output -> print_endline output
  | None -> ());

  (* Emit code to file *)
  if release then (
    let pm = Llvm.PassManager.create () in
    let bldr = Llvm_passmgr_builder.create () in
    Llvm_passmgr_builder.set_opt_level 2 bldr;
    Llvm_passmgr_builder.populate_lto_pass_manager ~internalize:true
      ~run_inliner:true pm bldr;
    Llvm.PassManager.run_module the_module pm |> ignore);

  TargetMachine.emit_to_file the_module CodeGenFileType.ObjectFile
    (outname ^ ".o") machine
