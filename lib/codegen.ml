open Types
module Vars = Map.Make (String)
module Set = Set.Make (String)

module Str = struct
  type t = string

  let hash = Hashtbl.hash
  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)

type llvar = { value : Llvm.llvalue; typ : typ; lltyp : Llvm.lltype }

type param = {
  vars : llvar Vars.t;
  alloca : Llvm.llvalue option;
  finalize : (llvar -> unit) option;
  rec_block : Llvm.llbasicblock option;
}

let ( ++ ) = Seq.append
let record_tbl = Strtbl.create 32
let context = Llvm.global_context ()
let the_module = Llvm.create_module context "context"
let fpm = Llvm.PassManager.create_function the_module
let _ = Llvm.PassManager.initialize fpm

(* Segfaults on my fedora box!? *)
(* let () = Llvm_scalar_opts.add_instruction_combination fpm *)

(* let () = Llvm_scalar_opts.add_reassociation fpm *)

(* Is somehow needed to make tail call optimization work *)
let () = Llvm_scalar_opts.add_gvn fpm

(* let () = Llvm_scalar_opts.add_cfg_simplification fpm *)

let () = Llvm_scalar_opts.add_tail_call_elimination fpm
let builder = Llvm.builder context
let int_type = Llvm.i32_type context
let num_type = Llvm.i64_type context
let bool_type = Llvm.i1_type context
let char_type = Llvm.i8_type context
let unit_type = Llvm.void_type context
let voidptr_type = Llvm.(i8_type context |> pointer_type)

let closure_type =
  let t = Llvm.named_struct_type context "closure" in
  let typ = [| voidptr_type; voidptr_type |] in
  Llvm.struct_set_body t typ false;
  t

let generic_type = Llvm.named_struct_type context "generic"

let dummy_fn_value =
  (* When we need something in the env for a function which will only be called
     in a monomorphized version *)
  { typ = Tunit; value = Llvm.const_int int_type (-1); lltyp = int_type }

let sret_attrib = Llvm.create_enum_attr context "sret" Int64.zero

let memcpy_decl =
  lazy
    (let open Llvm in
    (* llvm.memcpy.inline.p0i8.p0i8.i64 *)
    let ft =
      function_type unit_type
        [| voidptr_type; voidptr_type; num_type; bool_type |]
    in
    declare_function "llvm.memcpy.p0i8.p0i8.i64" ft the_module)

(* Named structs for records *)

let rec record_name = function
  (* We match on each type here to allow for nested parametrization like [int foo bar].
     [poly] argument will create a name used for a poly var, ie spell out the generic name *)
  | Trecord (param, name, _) ->
      let some p =
        "_" ^ match p with Qvar _ -> "generic" | t -> record_name t
      in
      Printf.sprintf "%s%s" name (Option.fold ~none:"" ~some param)
  | t -> Typing.string_of_type t

let rec get_lltype ?(param = true) ?(field = false) = function
  (* For functions, when passed as parameter, we convert it to a closure ptr
     to later cast to the correct types. At the application, we need to
     get the correct type though to cast it back. All this is handled by [param]. *)
  | Tint -> int_type
  | Tbool -> bool_type
  | Tchar -> char_type
  | Tvar { contents = Link t } -> get_lltype ~param t
  | Tunit -> unit_type
  | Tfun (params, ret, kind) ->
      typeof_func ~param ~field ~decl:false (params, ret, kind)
  | Trecord _ as t -> (
      let name = record_name t in
      match Strtbl.find_opt record_tbl name with
      | Some t -> if param then t |> Llvm.pointer_type else t
      | None ->
          failwith (Printf.sprintf "Record struct not found for type %s" name))
  | Qvar _ -> generic_type |> Llvm.pointer_type
  | Tvar _ as t ->
      failwith (Printf.sprintf "Wrong type TODO: %s" (Typing.string_of_type t))
  | Tptr t -> get_lltype ~param:false ~field t |> Llvm.pointer_type

(* LLVM type of closure struct and records *)
and typeof_aggregate agg =
  Array.map (fun (_, typ) -> get_lltype ~param:false ~field:true typ) agg
  |> Llvm.struct_type context

and typeof_func ~param ?(field = false) ~decl (params, ret, kind) =
  if param || field then closure_type |> Llvm.pointer_type
  else
    (* When [get_lltype] is called on a function, we handle the dynamic case where
       a function or closure is being passed to another function.
       If a record is returned, we allocate it at the caller site and
       pass it as first argument to the function *)
    let prefix, ret_t =
      match ret with
      | (Trecord _ as t) | (Qvar _ as t) ->
          (Seq.return (get_lltype ~param:true t), unit_type)
      | t -> (Seq.empty, get_lltype ~param t)
    in

    let suffix =
      (* A closure needs an extra parameter for the environment  *)
      if decl then
        match kind with Closure _ -> Seq.return voidptr_type | _ -> Seq.empty
      else Seq.return voidptr_type
    in
    let params_t =
      (* For the params, we want to produce the param type, hence ~param:true *)
      List.to_seq params |> Seq.map (get_lltype ~param:true) |> fun seq ->
      prefix ++ seq ++ suffix |> Array.of_seq
    in
    let ft = Llvm.function_type ret_t params_t in
    ft

let to_named_records = function
  | Trecord (_, _, labels) as t ->
      let name = record_name t in
      let t = Llvm.named_struct_type context name in
      let lltyp = typeof_aggregate labels |> Llvm.struct_element_types in
      Llvm.struct_set_body t lltyp false;

      if Strtbl.mem record_tbl name then
        failwith "Internal Error: Type shadowing not supported in codegen TODO";
      Strtbl.add record_tbl name t
  | _ -> failwith "Internal Error: Only records should be here"

(*
   Size and alignment.
*)

type size_pr = { size : int; align : int }

let alignup ~size ~upto =
  let modulo = size mod upto in
  if Int.equal modulo 0 then (* We are aligned *)
    size else size + (upto - modulo)

let add_size_align ~upto ~sz { size; align } =
  let size = alignup ~size ~upto + sz in
  let align = max align upto in
  { size; align }

(* Returns the size in bytes *)
let sizeof_typ typ =
  let rec inner size_pr typ =
    match typ with
    | Tint -> add_size_align ~upto:4 ~sz:4 size_pr
    | Tbool | Tchar ->
        (* No need to align one byte *)
        { size_pr with size = size_pr.size + 1 }
    | Tunit -> failwith "Does this make sense?"
    | Tvar { contents = Link t } -> inner size_pr t
    | Tfun _ ->
        (* Just a ptr? Or a closure, 2 ptrs. Assume 64bit *)
        add_size_align ~upto:8 ~sz:8 size_pr
    | Trecord (_, _, labels) ->
        Array.fold_left (fun pr (_, t) -> inner pr t) size_pr labels
    | Qvar _ | Tvar _ ->
        Llvm.dump_module the_module;
        failwith "too generic for a size"
    | Tptr _ ->
        (* TODO pass in triple. Until then, assume 64bit *)
        add_size_align ~upto:8 ~sz:8 size_pr
  in
  let { size; align = upto } = inner { size = 0; align = 1 } typ in
  alignup ~size ~upto

let llval_of_size size = Llvm.const_int num_type size

(* Given two ptr types (most likely to structs), copy src to dst *)
let memcpy ~dst ~src ~size =
  let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
  let retptr = Llvm.build_bitcast src.value voidptr_type "" builder in
  let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
  ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder)

let set_record_field value ptr =
  match value.typ with
  | Trecord _ ->
      if value.value <> ptr then
        let size = sizeof_typ value.typ |> llval_of_size in
        memcpy ~dst:ptr ~src:value ~size
  | _ -> ignore (Llvm.build_store value.value ptr builder)

let declare_function fun_name = function
  | Tfun (params, ret, kind) as typ ->
      let ft = typeof_func ~param:false ~decl:true (params, ret, kind) in
      let llvar =
        {
          value = Llvm.declare_function fun_name ft the_module;
          typ;
          lltyp = ft;
        }
      in
      llvar
  | _ ->
      prerr_endline fun_name;
      failwith "Internal Error: declaring non-function"

(* [func_to_closure] but for function types *)
let tfun_to_closure = function
  | Tfun (ps, ret, Simple) -> Tfun (ps, ret, Closure [])
  | t -> t

let gen_closure_obj assoc func vars name =
  let clsr_struct = Llvm.build_alloca closure_type name builder in

  (* Add function ptr *)
  let fun_ptr = Llvm.build_struct_gep clsr_struct 0 "funptr" builder in
  let fun_casted = Llvm.build_bitcast func.value voidptr_type "func" builder in
  ignore (Llvm.build_store fun_casted fun_ptr builder);

  let store_closed_var clsr_ptr i (name, _) =
    let var = Vars.find name vars in
    let ptr = Llvm.build_struct_gep clsr_ptr i name builder in
    ignore (Llvm.build_store var.value ptr builder);
    i + 1
  in

  (* Add closed over vars. If the environment is empty, we pass nullptr *)
  let clsr_ptr =
    match assoc with
    | [] -> Llvm.const_pointer_null voidptr_type
    | assoc ->
        let assoc_type = typeof_aggregate (Array.of_list assoc) in
        let clsr_ptr = Llvm.build_alloca assoc_type ("clsr_" ^ name) builder in
        ignore (List.fold_left (store_closed_var clsr_ptr) 0 assoc);

        let clsr_casted =
          Llvm.build_bitcast clsr_ptr voidptr_type "env" builder
        in
        clsr_casted
  in

  (* Add closure env to struct *)
  let env_ptr = Llvm.build_struct_gep clsr_struct 1 "envptr" builder in
  ignore (Llvm.build_store clsr_ptr env_ptr builder);

  (* Turn simple functions into empty closures, so they are handled correctly
     when passed *)
  let typ = tfun_to_closure func.typ in

  { value = clsr_struct; typ; lltyp = func.lltyp }

let add_closure vars func = function
  | Simple -> vars
  | Closure assoc ->
      let closure_index = (Llvm.params func.value |> Array.length) - 1 in
      let clsr_param = (Llvm.params func.value).(closure_index) in
      let clsr_type =
        typeof_aggregate (Array.of_list assoc) |> Llvm.pointer_type
      in
      let clsr_ptr = Llvm.build_bitcast clsr_param clsr_type "clsr" builder in

      let env, _ =
        List.fold_left
          (fun (env, i) (name, typ) ->
            let item_ptr = Llvm.build_struct_gep clsr_ptr i name builder in
            let value = Llvm.build_load item_ptr name builder in
            let item = { value; typ; lltyp = Llvm.type_of value } in
            (Vars.add name item env, i + 1))
          (vars, 0) assoc
      in
      env

let store_alloca ~src ~dst =
  match src.typ with
  | Trecord _ as r -> memcpy ~dst ~src ~size:(sizeof_typ r |> llval_of_size)
  | Tfun _ as f -> memcpy ~dst ~src ~size:(sizeof_typ f |> llval_of_size)
  | Tptr _ -> failwith "TODO"
  | _ ->
      (* Simple type *)
      ignore (Llvm.build_store src.value dst builder)

let name_of_alloc_param i = "__" ^ string_of_int i ^ "_alloc"

(* This adds the function parameters to the env.
   In case the function is tailrecursive, it allocas each parameter in
   the entry block and creates a recursion block which starts off by loading
   each parameter. *)
let add_params vars f fname names types start_index recursive =
  let add_simple () =
    (* We simply add to env, no special handling due to tailrecursion *)
    List.fold_left2
      (fun (env, i) name typ ->
        let value = (Llvm.params f.value).(i) in
        let param = { value; typ = clean typ; lltyp = Llvm.type_of value } in
        Llvm.set_value_name name value;
        (Vars.add name param env, i + 1))
      (vars, start_index) names types
    |> fst
  in

  let alloca_copy src =
    match src.typ with
    | Trecord _ as r ->
        let typ = get_lltype ~param:false r in
        let dst = Llvm.build_alloca typ "" builder in
        store_alloca ~src ~dst;
        dst
    | Tfun _ ->
        let typ = closure_type in
        let dst = Llvm.build_alloca typ "" builder in
        store_alloca ~src ~dst;
        dst
    | Tptr _ -> failwith "TODO"
    | t ->
        (* Simple type *)
        let typ = get_lltype ~param:false t in
        let dst = Llvm.build_alloca typ "" builder in
        store_alloca ~src ~dst;
        dst
  in

  let load value name =
    match value.typ with
    | Trecord _ -> value.value
    | Tfun _ -> value.value
    | Tptr _ -> failwith "TODO"
    | _ -> Llvm.build_load value.value name builder
  in

  (* If the function is named, we allow recursion *)
  match recursive with
  | Monomorph_tree.Rnone -> (add_simple (), None)
  | Rnormal -> (add_simple () |> Vars.add fname f, None)
  | Rtail ->
      (* In the entry block, we create a alloca for each parameter.
         These can be set later in tail recursion scenarios.
         Then in a new block, we load from those alloca and set the
         real parameters *)
      let vars =
        List.fold_left2
          (fun (env, i) name typ ->
            let value = (Llvm.params f.value).(i) in
            Llvm.set_value_name name value;
            let value =
              { value; typ = clean typ; lltyp = Llvm.type_of value }
            in
            let alloc = { value with value = alloca_copy value } in
            (Vars.add (name_of_alloc_param i) alloc env, i + 1))
          (vars, start_index) names types
        |> fst
      in
      (* Recursion block*)
      let bb = Llvm.append_block context "rec" f.value in
      ignore (Llvm.build_br bb builder);
      Llvm.position_at_end bb builder;

      let vars, _ =
        List.fold_left
          (fun (env, i) name ->
            let llvar = Vars.find (name_of_alloc_param i) env in
            let value = load llvar name in
            (Vars.add name { llvar with value } env, i + 1))
          (vars, start_index) names
      in
      (vars, Some bb)

let pass_function vars llvar kind =
  match kind with
  | Simple ->
      (* If a function is passed into [func] we convert it to a closure
         and pass nullptr to env*)
      gen_closure_obj [] llvar vars "clstmp"
  | Closure _ ->
      (* This closure is a struct and has an env *)
      llvar

let func_to_closure vars llvar =
  (* TODO somewhere we don't convert into closure correctly *)
  if Llvm.type_of llvar.value = (closure_type |> Llvm.pointer_type) then llvar
  else
    match llvar.typ with
    | Tfun (_, _, kind) -> pass_function vars.vars llvar kind
    | _ -> llvar

(* Get monomorphized function *)
let get_mono_func func param = function
  | Monomorph_tree.Mono name ->
      let func = Vars.find name param.vars in
      (* Monomorphized functions are not yet converted to closures *)
      let func =
        match func.typ with
        | Tfun (_, _, Closure assoc) ->
            gen_closure_obj assoc func param.vars "monoclstmp"
        | Tfun (_, _, Simple) -> func
        | _ -> failwith "Internal Error: What are we applying?"
      in
      func
  | Concrete name -> Vars.find name param.vars
  | Default | Recursive _ -> func

let fun_return name ret =
  match ret.typ with
  | Trecord _ -> Llvm.build_ret_void builder
  | Qvar id when String.equal id "tail" ->
      (* This magic id is used to mark a tailrecursive call *)
      Llvm.build_ret_void builder
  | Qvar _ -> failwith "Internal Error: Generic return"
  | Tunit ->
      if String.equal name "main" then
        Llvm.(build_ret (const_int int_type 0)) builder
      else Llvm.build_ret_void builder
  | _ -> Llvm.build_ret ret.value builder

let rec gen_function vars ?(linkage = Llvm.Linkage.Private)
    { Monomorph_tree.abs; name; recursive } =
  let typ = Monomorph_tree.typ_of_abs abs in

  match typ with
  | Tfun (tparams, ret_t, kind) as typ ->
      let func = declare_function name typ in
      Llvm.set_linkage linkage func.value;

      let start_index, alloca =
        match ret_t with
        | Trecord _ ->
            Llvm.(add_function_attr func.value sret_attrib (AttrIndex.Param 0));
            (1, Some (Llvm.params func.value).(0))
        | Qvar _ -> failwith "qvar should not be returned"
        | _ -> (0, None)
      in

      (* gen function body *)
      let bb = Llvm.append_block context "entry" func.value in
      Llvm.position_at_end bb builder;

      (* Add params from closure *)
      (* We generate both the code for extracting the closure and add the vars to the environment *)
      let tvars = add_closure vars.vars func kind in

      (* Add parameters to env *)
      let tvars, rec_block =
        add_params tvars func name abs.pnames tparams start_index recursive
      in

      let fun_finalize ret =
        (* If we want to return a struct, we copy the struct to
            its ptr (1st parameter) and return void *)
        match ret.typ with
        | Trecord _ ->
            (* Since we only have POD records, we can safely memcpy here *)
            let dst = Llvm.(params func.value).(0) in
            if ret.value <> dst then
              let size = sizeof_typ ret_t |> llval_of_size in
              memcpy ~dst ~src:ret ~size
            else ()
        | _ -> ()
      in

      let finalize = Some fun_finalize in
      let ret =
        gen_expr { vars = tvars; alloca; finalize; rec_block } abs.body
      in

      ignore (fun_return name ret);

      if Llvm_analysis.verify_function func.value |> not then (
        Llvm.dump_module the_module;
        (* To generate the report *)
        Llvm_analysis.assert_valid_function func.value);

      let _ = Llvm.PassManager.run_function func.value fpm in
      { vars with vars = Vars.add name func vars.vars }
  | _ ->
      prerr_endline name;
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
  | Monomorph_tree.Mconst (Int i) ->
      { value = Llvm.const_int int_type i; typ = Tint; lltyp = int_type } |> fin
  | Mconst (Bool b) ->
      {
        value = Llvm.const_int bool_type (Bool.to_int b);
        typ = Tbool;
        lltyp = bool_type;
      }
      |> fin
  | Mconst (Char c) ->
      {
        value = Llvm.const_int char_type (Char.code c);
        typ = Tchar;
        lltyp = char_type;
      }
  | Mconst (String s) -> codegen_string_lit s
  | Mconst Unit -> failwith "TODO"
  | Mbop (bop, e1, e2) ->
      let e1 = gen_expr param e1 in
      let e2 = gen_expr param e2 in
      gen_bop e1 e2 bop |> fin
  | Mvar id -> gen_var param.vars typed_expr.typ id |> fin
  | Mfunction (name, abs, cont) ->
      (* The functions are already generated *)
      let func =
        match Vars.find_opt name param.vars with
        | Some func -> (
            match abs.func.kind with
            | Simple -> func
            | Closure assoc -> gen_closure_obj assoc func param.vars name)
        | None ->
            (* The function is polymorphic and monomorphized versions are generated. *)
            (* We just return some bogus value, it will never be applied anyway
               (and if it will, LLVM will fail) *)
            dummy_fn_value
      in

      gen_expr { param with vars = Vars.add name func param.vars } cont
  | Mlet (id, equals_ty, let_ty) ->
      let expr_val = gen_expr param equals_ty in
      gen_expr { param with vars = Vars.add id expr_val param.vars } let_ty
  | Mlambda (name, abs) ->
      let func =
        match Vars.find_opt name param.vars with
        | Some func -> (
            match abs.func.kind with
            | Simple -> func
            | Closure assoc -> gen_closure_obj assoc func param.vars name)
        | None ->
            (* The function is polymorphic and monomorphized versions are generated. *)
            (* We just return some bogus value, it will never be applied anyway
               (and if it will, LLVM will fail) *)
            dummy_fn_value
      in
      func
  | Mapp { callee; args; alloca } -> (
      match (typed_expr.return, callee.monomorph, param.rec_block) with
      | true, Recursive _, Some block ->
          gen_app_tailrec param callee args block (clean typed_expr.typ)
      | _ -> gen_app param callee args alloca (clean typed_expr.typ) |> fin)
  | Mif expr -> gen_if param expr typed_expr.return
  | Mrecord (labels, allocref) ->
      codegen_record param (clean typed_expr.typ) labels allocref |> fin
  | Mfield (expr, index) -> codegen_field param expr index |> fin
  | Mseq (expr, cont) -> codegen_chain param expr cont

and gen_var vars typ id =
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
          failwith ("Internal Error: Could not find " ^ id ^ " in codegen"))

and gen_bop e1 e2 bop =
  let bld f str = f e1.value e2.value str builder in
  let open Llvm in
  match bop with
  | Plus -> { value = bld build_add "addtmp"; typ = Tint; lltyp = int_type }
  | Mult -> { value = bld build_mul "multmp"; typ = Tint; lltyp = int_type }
  | Less ->
      let value = bld (build_icmp Icmp.Slt) "lesstmp" in
      { value; typ = Tbool; lltyp = bool_type }
  | Equal ->
      let value = bld (build_icmp Icmp.Eq) "eqtmp" in
      { value; typ = Tbool; lltyp = bool_type }
  | Minus -> { value = bld build_sub "subtmp"; typ = Tint; lltyp = int_type }

and gen_app param callee args allocref ret_t =
  let func = gen_expr param callee.ex in

  let func = get_mono_func func param callee.monomorph in

  let ret, kind =
    match func.typ with
    | Tfun (_, ret, kind) -> (ret, kind)
    | Tunit ->
        failwith "Internal Error: Probably cannot find monomorphized function"
    | _ -> failwith "Internal Error: Not a func in gen app"
  in

  let handle_arg arg =
    let arg' = gen_expr param Monomorph_tree.(arg.ex) in
    let arg = get_mono_func arg' param arg.monomorph in
    (func_to_closure param arg).value
  in
  let args = List.map handle_arg args in

  (* No names here, might be void/unit *)
  let funcval, args, envarg =
    if Llvm.type_of func.value = (closure_type |> Llvm.pointer_type) then
      (* Function to call is a closure (or a function passed into another one).
         We get the funptr from the first field, cast to the correct type,
         then get env ptr (as voidptr) from the second field and pass it as last argument *)
      let funcp = Llvm.build_struct_gep func.value 0 "funcptr" builder in
      let funcp = Llvm.build_load funcp "loadtmp" builder in
      let typ = get_lltype ~param:false func.typ |> Llvm.pointer_type in
      let funcp = Llvm.build_bitcast funcp typ "casttmp" builder in

      let env_ptr = Llvm.build_struct_gep func.value 1 "envptr" builder in
      let env_ptr = Llvm.build_load env_ptr "loadtmp" builder in
      (funcp, List.to_seq args, Seq.return env_ptr)
    else
      match kind with
      | Simple -> (func.value, List.to_seq args, Seq.empty)
      | Closure _ -> (
          (* In this case we are in a recursive closure function.
             We get the closure env and add it to the arguments we pass *)
          match Vars.find_opt (Llvm.value_name func.value) param.vars with
          | Some func ->
              (* We do this to make sure it's a recursive function.
                 If we cannot find something. there is an error somewhere *)
              let closure_index =
                (Llvm.params func.value |> Array.length) - 1
              in

              let env_ptr = (Llvm.params func.value).(closure_index) in
              (func.value, List.to_seq args, Seq.return env_ptr)
          | None ->
              failwith "Internal Error: Not a recursive closure application")
  in

  let value, lltyp, call =
    match ret_t with
    | Trecord _ ->
        let lltyp = get_lltype ~param:false ret_t in
        let retval =
          match (!allocref, param.alloca) with
          | true, Some value -> value
          | true, None -> Llvm.build_alloca lltyp "ret" builder
          | false, _ -> Llvm.build_alloca lltyp "ret" builder
        in
        let ret' = Seq.return retval in
        let args = ret' ++ args ++ envarg |> Array.of_seq in
        let call = Llvm.build_call funcval args "" builder in
        (retval, lltyp, call)
    | t ->
        let args = args ++ envarg |> Array.of_seq in
        let retval = Llvm.build_call funcval args "" builder in
        (retval, get_lltype t, retval)
  in

  ignore call;

  { value; typ = ret; lltyp }

and gen_app_tailrec param callee args rec_block ret_t =
  (* We evaluate, there might be side-effects *)
  let func = gen_expr param callee.ex in
  ignore func;

  let start_index, ret =
    match func.typ with
    | Tfun (_, (Trecord _ as r), _) -> (1, r)
    | Tfun (_, ret, _) -> (0, ret)
    | Tunit ->
        failwith "Internal Error: Probably cannot find monomorphized function"
    | _ -> failwith "Internal Error: Not a func in gen app"
  in

  let handle_arg i arg =
    let arg' = gen_expr param Monomorph_tree.(arg.ex) in
    let arg = get_mono_func arg' param arg.monomorph in
    let llvar = func_to_closure param arg in

    let alloca = Vars.find (name_of_alloc_param i) param.vars in

    if llvar.value <> alloca.value then
      store_alloca ~src:llvar ~dst:alloca.value;
    i + 1
  in

  ignore (List.fold_left handle_arg start_index args);

  let lltyp =
    match ret with
    | Trecord _ -> get_lltype ~param:false ret_t
    | t -> get_lltype t
  in

  let value = Llvm.build_br rec_block builder in
  { value; typ = Qvar "tail"; lltyp }

and gen_if param expr return =
  (* If a function ends in a if expression (and returns a struct),
     we pass in the finalize step. This allows us to handle the branches
     differently and enables tail call elimination *)
  ignore return;

  let is_tailcall e =
    match e.typ with Qvar id when String.equal "tail" id -> true | _ -> false
  in

  let cond = gen_expr param expr.cond in

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
  let merge_bb = Llvm.append_block context "ifcont" parent in
  Llvm.position_at_end merge_bb builder;

  let phi =
    (* If the else evaluates to void, we don't do anything.
       Void will be added eventually *)
    match e2.typ with
    | Tunit -> e1.value
    | _ -> (
        (* Small optimization: If we happen to end up with the same value,
           we don't generate a phi node (can happen in recursion) *)
        match (is_tailcall e1, is_tailcall e2) with
        | true, true ->
            (* No need for the whole block, we just return some value *)
            print_endline "we are here";
            e1.value
        | true, false -> e2.value
        | false, true -> e1.value
        | false, false ->
            if e1.value <> e2.value then
              let incoming = [ (e1.value, e1_bb); (e2.value, e2_bb) ] in
              Llvm.build_phi incoming "iftmp" builder
            else e1.value)
  in

  Llvm.position_at_end start_bb builder;
  ignore (Llvm.build_cond_br cond.value then_bb else_bb builder);

  if not (is_tailcall e1) then (
    Llvm.position_at_end e1_bb builder;
    ignore (Llvm.build_br merge_bb builder));
  if not (is_tailcall e2) then (
    Llvm.position_at_end e2_bb builder;
    ignore (Llvm.build_br merge_bb builder));

  Llvm.position_at_end merge_bb builder;
  (* TODO The return type here must be checked for tailrecs? *)
  { value = phi; typ = e2.typ; lltyp = e2.lltyp }

and codegen_record param typ labels allocref =
  let lltyp = get_lltype ~param:false ~field:true typ in

  let record =
    match (!allocref, param.alloca) with
    | true, Some value -> value
    | true, None | false, _ -> Llvm.build_alloca lltyp "" builder
  in

  List.iteri
    (fun i (name, expr) ->
      let ptr = Llvm.build_struct_gep record i name builder in
      let value =
        gen_expr { param with alloca = Some ptr } expr |> func_to_closure param
      in
      set_record_field value ptr)
    labels;

  { value = record; typ; lltyp }

and codegen_field param expr index =
  let value = gen_expr param expr in

  let typ =
    match value.typ with
    | Trecord (_, _, fields) -> fields.(index) |> snd
    | _ -> failwith "Internal Error: No record in fields"
  in

  let ptr = Llvm.build_struct_gep value.value index "" builder in

  (* In case we return a record, we don't load, but return the pointer.
     The idea is that this will be used either as a return value for a function (where it is copied),
     or for another field, where the pointer is needed.
     We should distinguish between structs and pointers somehow *)
  let value =
    match typ with
    | Trecord _ | Qvar _ -> ptr
    | _ -> Llvm.build_load ptr "" builder
  in
  { value; typ; lltyp = Llvm.type_of value }

and codegen_chain param expr cont =
  ignore (gen_expr param expr);
  gen_expr param cont

and codegen_string_lit s =
  let lltyp = get_lltype (Tptr Tchar) in
  let typ = Llvm.array_type char_type (String.length s + 1) in
  let arr = Llvm.build_alloca typ "" builder in
  let string = Llvm.const_stringz context s in
  ignore (Llvm.build_store string arr builder);
  let value = Llvm.build_bitcast arr lltyp "" builder in
  { value; typ = Tptr Tchar; lltyp }

let decl_external (name, typ) =
  match typ with
  | Tfun (ts, t, _) as typ ->
      let return_t = get_lltype t in
      let arg_t = List.map get_lltype ts |> Array.of_list in
      let ft = Llvm.function_type return_t arg_t in
      { value = Llvm.declare_function name ft the_module; typ; lltyp = ft }
  | _ -> failwith "TODO external symbols"

let generate { Monomorph_tree.externals; records; tree; funcs } =
  (* External declarations *)
  let vars =
    List.fold_left
      (fun vars (name, typ) -> Vars.add name (decl_external (name, typ)) vars)
      Vars.empty externals
  in

  (* Add record types *)
  List.iter to_named_records records;

  (* Factor out functions for llvm *)
  let funcs =
    let vars =
      List.fold_left
        (fun acc (func : Monomorph_tree.to_gen_func) ->
          let typ =
            Tfun (func.abs.func.params, func.abs.func.ret, func.abs.func.kind)
          in
          let fnc = declare_function func.name typ in

          (* Add to the normal variable environment *)
          Vars.add func.name fnc acc)
        vars funcs
    in

    (* Generate functions *)
    List.fold_left
      (fun acc func -> gen_function acc func)
      { vars; alloca = None; finalize = None; rec_block = None }
      funcs
  in

  (* Add main *)
  let linkage = Llvm.Linkage.External in

  ignore
  @@ gen_function funcs ~linkage
       {
         name = "main";
         recursive = Rnone;
         abs =
           {
             func = { params = [ Tint ]; ret = Tint; kind = Simple };
             pnames = [ "arg" ];
             body = { tree with typ = Tint };
           };
       };

  (match Llvm_analysis.verify_module the_module with
  | Some output -> print_endline output
  | None -> ());

  (* Emit code to file *)
  Llvm_all_backends.initialize ();
  let open Llvm_target in
  let triple = Target.default_triple () in
  let reloc_mode = RelocMode.PIC in
  print_endline triple;
  let machine =
    TargetMachine.create ~triple (Target.by_triple triple) ~reloc_mode
  in
  TargetMachine.emit_to_file the_module CodeGenFileType.ObjectFile "out.o"
    machine
