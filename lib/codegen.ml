open Types
module Vars = Map.Make (String)

type llvar = { value : Llvm.llvalue; typ : typ; lltyp : Llvm.lltype }

let context = Llvm.global_context ()

let the_module = Llvm.create_module context "context"

let builder = Llvm.builder context

let int_type = Llvm.i32_type context

let num_type = Llvm.i64_type context

let bool_type = Llvm.i1_type context

let unit_type = Llvm.void_type context

let voidptr_type = Llvm.(i8_type context |> pointer_type)

let closure_type = Llvm.(struct_type context [| voidptr_type; voidptr_type |])

let memcpy_decl =
  lazy
    (let open Llvm in
    (* llvm.memcpy.inline.p0i8.p0i8.i64 *)
    let ft =
      function_type unit_type
        [| voidptr_type; voidptr_type; num_type; bool_type |]
    in
    declare_function "llvm.memcpy.p0i8.p0i8.i64" ft the_module)

let rec get_lltype ?(param = true) = function
  (* For functions, when passed as parameter, we convert it to a closure ptr
     to later cast to the correct types. At the application, we need to
     get the correct type though to cast it back. All this is handled by [param]. *)
  | TInt -> int_type
  | TBool -> bool_type
  | TVar { contents = Link t } -> get_lltype ~param t
  | TUnit -> unit_type
  | TFun (params, t, _) ->
      if param then closure_type |> Llvm.pointer_type
      else
        let ret_t = get_lltype t in
        let params_t =
          List.map get_lltype params |> fun lst ->
          lst @ [ voidptr_type ] |> Array.of_list
        in
        Llvm.function_type ret_t params_t |> Llvm.pointer_type
  | TRecord (_, labels) -> typeof_aggregate labels
  | (TVar _ | QVar _) as t ->
      failwith (Printf.sprintf "Wrong type TODO: %s" (Typing.string_of_type t))

(* LLVM type of closure struct and records *)
and typeof_aggregate agg =
  List.map (fun (_, typ) -> get_lltype typ) agg
  |> Array.of_list |> Llvm.struct_type context

(* Given two ptr types (most likely to structs), copy src to dst *)
let memcpy ~dst ~src =
  (* let dst = Llvm.(params func.value).(0) in *)
  let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
  let retptr = Llvm.build_bitcast src.value voidptr_type "" builder in
  let size = Llvm.size_of (get_lltype src.typ) in
  let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
  ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder)

(* Used to generate lambdas *)
let fun_gen_state = ref 0

(* Used to query lambdas *)
let fun_get_state = ref 0

let lambda_name state =
  let n = !state in
  incr state;
  "__fun" ^ string_of_int n

(* for named functions *)
let unique_name = function
  | name, None -> name
  | name, Some n -> name ^ "__" ^ string_of_int n

let reset state = state := 0

type func = {
  name : string * bool * int option;
  params : string list;
  typ : typ;
  body : Typing.typed_expr;
}

(* Transforms abs into a TFun and cleans all types (resolves links) *)
let split_abs abs =
  let nparams, tparams = List.split Typing.(abs.params) in
  let params = List.map clean tparams in
  (TFun (params, clean abs.body.typ, abs.kind), nparams)

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)
let extract expr =
  let rec inner acc = function
    | Typing.Var _ | Const _ -> acc
    | Bop (_, e1, e2) -> inner (inner acc e1.expr) e2.expr
    | If (cond, e1, e2) ->
        let acc = inner acc cond.expr in
        let acc = inner acc e1.expr in
        inner acc e2.expr
    | Function (name, uniq, abs, cont) ->
        let acc = inner acc abs.body.expr in
        let name = (name, true, uniq) in
        let typ, params = split_abs abs in
        inner ({ name; params; typ; body = abs.body } :: acc) cont.expr
    | Let (_, e1, e2) ->
        let acc = inner acc e1.expr in
        inner acc e2.expr
    | Lambda abs ->
        let acc = inner acc abs.body.expr in
        let name = (lambda_name fun_gen_state, false, None) in
        let typ, params = split_abs abs in
        { name; params; typ; body = abs.body } :: acc
    | App (e1, args) ->
        let acc = inner acc e1.expr in
        List.fold_left (fun acc arg -> inner acc Typing.(arg.expr)) acc args
    | Record labels ->
        List.fold_left (fun acc (_, e) -> inner acc Typing.(e.expr)) acc labels
    | Field (expr, _) -> inner acc expr.expr
  in
  inner [] expr

let declare_function fun_name = function
  | TFun (params, ret, kind) as typ ->
      let return_t = get_lltype ret in
      (* If a record is returned, we allocate it at the caller site and
         pass it as first argument to the function *)
      (* TODO Do a pass for all these special cases? *)
      let prefix, return_t =
        match ret with
        | TRecord _ -> ([ Llvm.pointer_type return_t ], unit_type)
        | _ -> ([], return_t)
      in

      let ll_params_t =
        let param_lst =
          List.map
            (function
              | TRecord _ as arg -> get_lltype arg |> Llvm.pointer_type
              | arg -> get_lltype arg)
            params
          |> fun l -> prefix @ l
        in
        (match kind with
        | Simple | Anon -> param_lst
        | Closure _ ->
            (* In the closure case, we add a voidptr for the closure *)
            param_lst @ [ voidptr_type ])
        |> Array.of_list
      in
      let ft = Llvm.function_type return_t ll_params_t in
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

let gen_closure_obj assoc func vars name =
  let clsr_struct = Llvm.build_alloca closure_type name builder in

  (* Add function ptr *)
  let fun_ptr = Llvm.build_struct_gep clsr_struct 0 "funptr" builder in
  let fun_casted = Llvm.build_bitcast func.value voidptr_type "func" builder in
  ignore (Llvm.build_store fun_casted fun_ptr builder);

  (* Add closed over vars *)
  let clsr_ptr =
    Llvm.build_alloca (typeof_aggregate assoc) ("clsr_" ^ name) builder
  in
  ignore
    (List.fold_left
       (fun i (name, _) ->
         let var = Vars.find name vars in
         let ptr = Llvm.build_struct_gep clsr_ptr i name builder in
         ignore (Llvm.build_store var.value ptr builder);
         i + 1)
       0 assoc);

  (* Add closure env to struct *)
  let env_ptr = Llvm.build_struct_gep clsr_struct 1 "envptr" builder in
  let clsr_casted = Llvm.build_bitcast clsr_ptr voidptr_type "env" builder in
  ignore (Llvm.build_store clsr_casted env_ptr builder);

  { value = clsr_struct; typ = func.typ; lltyp = func.lltyp }

let rec gen_function funcs ?(linkage = Llvm.Linkage.Private)
    { name = name, named, uniq; params; typ; body } =
  let fun_name = if named then unique_name (name, uniq) else name in
  match typ with
  | TFun (tparams, ret_t, kind) as typ ->
      let func = declare_function fun_name typ in
      Llvm.set_linkage linkage func.value;

      (* If we return a struct, the first parameter is the ptr to it *)
      let start_index = match ret_t with TRecord _ -> 1 | _ -> 0 in

      let temp_funcs, closure_index =
        List.fold_left2
          (fun (env, i) name typ ->
            let value = (Llvm.params func.value).(i) in
            let param =
              { value; typ = clean typ; lltyp = Llvm.type_of value }
            in
            Llvm.set_value_name name value;
            (Vars.add name param env, i + 1))
          (funcs, start_index) params tparams
      in

      (* If the function is named, we allow recursion *)
      let temp_funcs =
        if named then Vars.add fun_name func temp_funcs else temp_funcs
      in

      (* gen function body *)
      let bb = Llvm.append_block context "entry" func.value in
      Llvm.position_at_end bb builder;

      (* Add params from closure *)
      (* We both generate the code for extracting the closure and add the vars to the environment *)
      let temp_funcs =
        match kind with
        | Simple | Anon -> temp_funcs
        | Closure assoc ->
            let clsr_param = (Llvm.params func.value).(closure_index) in
            let clsr_type = typeof_aggregate assoc |> Llvm.pointer_type in
            let clsr_ptr =
              Llvm.build_bitcast clsr_param clsr_type "clsr" builder
            in

            let env, _ =
              List.fold_left
                (fun (env, i) (name, typ) ->
                  let item_ptr =
                    Llvm.build_struct_gep clsr_ptr i name builder
                  in
                  let value = Llvm.build_load item_ptr name builder in
                  let item = { value; typ; lltyp = Llvm.type_of value } in
                  (Vars.add name item env, i + 1))
                (temp_funcs, 0) assoc
            in
            env
      in

      let ret = gen_expr temp_funcs body in

      (* If we want to return a struct, we copy the struct to
          its ptr (1st parameter) and return void *)
      (match ret_t with
      | TRecord _ ->
          (* TODO Use this return struct for creation in the first place *)
          (* Since we only have POD records, we can safely memcpy here *)
          let dst = Llvm.(params func.value).(0) in
          let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
          let retptr = Llvm.build_bitcast ret.value voidptr_type "" builder in
          let size = Llvm.size_of (get_lltype ret.typ) in
          let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
          ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder);
          ignore (Llvm.build_ret_void builder)
      | _ ->
          (* Don't return void type *)
          ignore
            (match ret.typ with
            | TUnit ->
                (* If we are in main, we return 0. Bit of a hack, but whatever *)
                if String.equal fun_name "main" then
                  Llvm.(build_ret (const_int int_type 0)) builder
                else Llvm.build_ret_void builder
            | _ -> Llvm.build_ret ret.value builder));

      Llvm_analysis.assert_valid_function func.value;

      Vars.add fun_name func funcs
  | _ ->
      prerr_endline fun_name;
      failwith "Interal Error: generating non-function"

and gen_expr (vars : llvar Vars.t) typed_expr : llvar =
  match Typing.(typed_expr.expr) with
  | Typing.Const (Int i) ->
      { value = Llvm.const_int int_type i; typ = TInt; lltyp = int_type }
  | Const (Bool b) ->
      {
        value = Llvm.const_int bool_type (Bool.to_int b);
        typ = TBool;
        lltyp = bool_type;
      }
  | Const Unit -> failwith "TODO"
  | Bop (bop, e1, e2) ->
      let e1 = gen_expr vars e1 in
      let e2 = gen_expr vars e2 in
      gen_bop e1 e2 bop
  | Var id -> (
      match Vars.find_opt id vars with
      | Some v -> v
      | None ->
          (* If the variable isn't bound, something went wrong before *)
          failwith ("Internal Error: Could not find " ^ id ^ " in codegen"))
  | Function (name, uniq, abs, cont) ->
      (* The functions are already generated *)
      let name = unique_name (name, uniq) in
      let func = Vars.find name vars in
      let func =
        match abs.kind with
        | Simple -> func
        | Anon -> failwith "Internal Error: Anonymous named function"
        | Closure assoc -> gen_closure_obj assoc func vars name
      in
      gen_expr (Vars.add name func vars) cont
  | Let (id, equals_ty, let_ty) ->
      let expr_val = gen_expr vars equals_ty in
      gen_expr (Vars.add id expr_val vars) let_ty
  | Lambda abs -> (
      let name = lambda_name fun_get_state in
      let func = Vars.find name vars in
      match abs.kind with
      | Simple -> failwith "Internal Error: Named anonymous function"
      | Anon -> func
      | Closure assoc -> gen_closure_obj assoc func vars name)
  | App (callee, arg) -> gen_app vars callee arg
  | If (cond, e1, e2) -> gen_if vars cond e1 e2
  | Record labels -> codegen_record vars (clean typed_expr.typ) labels
  | Field (expr, index) -> codegen_field vars expr index

and gen_bop e1 e2 = function
  | Plus ->
      let value = Llvm.build_add e1.value e2.value "addtmp" builder in
      { value; typ = TInt; lltyp = int_type }
  | Mult ->
      let value = Llvm.build_mul e1.value e2.value "multmp" builder in
      { value; typ = TInt; lltyp = int_type }
  | Less ->
      let value =
        Llvm.(build_icmp Icmp.Slt) e1.value e2.value "lesstmp" builder
      in
      { value; typ = TBool; lltyp = bool_type }
  | Equal ->
      let value = Llvm.(build_icmp Icmp.Eq) e1.value e2.value "eqtmp" builder in
      { value; typ = TBool; lltyp = bool_type }
  | Minus ->
      let value = Llvm.build_sub e1.value e2.value "subtmp" builder in
      { value; typ = TInt; lltyp = int_type }

and gen_app vars callee args =
  let func = gen_expr vars callee in

  let funcs_to_ptr v =
    match Llvm.classify_value v.value with
    | Function ->
        (* If a function is passed into [func] we convert it to a closure
           closures are already closures with an env *)
        let closure_struct = Llvm.build_alloca closure_type "clstmp" builder in
        let fp = Llvm.build_struct_gep closure_struct 0 "funptr" builder in
        let ptr = Llvm.build_bitcast v.value voidptr_type "" builder in
        ignore (Llvm.build_store ptr fp builder);

        let envptr = Llvm.build_struct_gep closure_struct 1 "envptr" builder in
        let nullptr = Llvm.const_pointer_null voidptr_type in
        ignore (Llvm.build_store nullptr envptr builder);
        closure_struct
    | _ -> v.value
  in
  let args = List.map (fun e -> gen_expr vars e |> funcs_to_ptr) args in

  (* No names here, might be void/unit *)
  let funcval, args =
    if Llvm.type_of func.value = (closure_type |> Llvm.pointer_type) then
      (* Function to call is a closure (or a function passed into another one).
         We get the funptr from the first field, cast to the correct type,
         then get env ptr (as voidptr) from the second field and pass it as last argument *)
      let funcp = Llvm.build_struct_gep func.value 0 "funcptr" builder in
      let funcp = Llvm.build_load funcp "loadtmp" builder in
      let typ = get_lltype ~param:false func.typ in
      let funcp = Llvm.build_bitcast funcp typ "casttmp" builder in

      let env_ptr = Llvm.build_struct_gep func.value 1 "envptr" builder in
      let env_ptr = Llvm.build_load env_ptr "loadtmp" builder in
      (funcp, args @ [ env_ptr ])
    else (func.value, args)
  in

  let value, typ, lltyp =
    match func.typ with
    | TFun (_, (TRecord _ as typ), _) ->
        let lltyp = get_lltype typ in
        let ret = Llvm.build_alloca lltyp "ret" builder in
        ignore
          (Llvm.build_call funcval (Array.of_list ([ ret ] @ args)) "" builder);
        (ret, typ, lltyp)
    | TFun (_, t, _) ->
        ( Llvm.build_call funcval (Array.of_list args) "" builder,
          t,
          func.lltyp |> Llvm.return_type )
    | _ -> failwith "Internal Error not a fun in gen_app"
  in

  { value; typ; lltyp }

and gen_if vars cond e1 e2 =
  let cond = gen_expr vars cond in

  let start_bb = Llvm.insertion_block builder in
  let parent = Llvm.block_parent start_bb in
  let then_bb = Llvm.append_block context "then" parent in
  Llvm.position_at_end then_bb builder;
  let e1 = gen_expr vars e1 in
  (* Codegen can change the current bb *)
  let e1_bb = Llvm.insertion_block builder in

  let else_bb = Llvm.append_block context "else" parent in
  Llvm.position_at_end else_bb builder;
  let e2 = gen_expr vars e2 in

  let e2_bb = Llvm.insertion_block builder in
  let merge_bb = Llvm.append_block context "ifcont" parent in

  Llvm.position_at_end merge_bb builder;
  let phi =
    (* If the else evaluates to void, we don't do anything.
       Void will be added eventually *)
    match e1.typ with
    | TUnit -> e1.value
    | _ ->
        let incoming = [ (e1.value, e1_bb); (e2.value, e2_bb) ] in
        Llvm.build_phi incoming "iftmp" builder
  in
  Llvm.position_at_end start_bb builder;
  Llvm.build_cond_br cond.value then_bb else_bb builder |> ignore;

  Llvm.position_at_end e1_bb builder;
  ignore (Llvm.build_br merge_bb builder);
  Llvm.position_at_end e2_bb builder;
  ignore (Llvm.build_br merge_bb builder);

  Llvm.position_at_end merge_bb builder;
  { value = phi; typ = e1.typ; lltyp = e1.lltyp }

and codegen_record vars typ labels =
  let lltyp = get_lltype typ in
  let record = Llvm.build_alloca lltyp "" builder in
  List.iteri
    (fun i (name, expr) ->
      let ptr = Llvm.build_struct_gep record i name builder in
      let value = gen_expr vars expr in
      match value.typ with
      | TRecord _ -> memcpy ~dst:ptr ~src:value
      | _ -> ignore (Llvm.build_store value.value ptr builder))
    labels;
  { value = record; typ; lltyp }

and codegen_field vars expr index =
  let value = gen_expr vars expr in
  let ptr = Llvm.build_struct_gep value.value index "" builder in

  let typ =
    match value.typ with
    | TRecord (_, fields) -> List.nth fields index |> snd
    | _ -> failwith "Internal Error: No record in fields"
  in
  (* In case we return a record, we don't load, but return the pointer.
     The idea is that this will be used either as a return value for a function (where it is copied),
     or for another field, where the pointer is needed.
     We should distinguish between structs and pointern somehow *)
  let value =
    match typ with TRecord _ -> ptr | _ -> Llvm.build_load ptr "" builder
  in
  { value; typ; lltyp = Llvm.type_of value }

let decl_external (name, typ) =
  match typ with
  | TFun (ts, t, _) as typ ->
      let return_t = get_lltype t in
      let arg_t = List.map get_lltype ts |> Array.of_list in
      let ft = Llvm.function_type return_t arg_t in
      { value = Llvm.declare_function name ft the_module; typ; lltyp = ft }
  | _ -> failwith "TODO external symbols"

let generate externals typed_expr =
  let open Typing in
  (* External declarations *)
  let vars =
    List.fold_left
      (fun vars (name, typ) -> Vars.add name (decl_external (name, typ)) vars)
      Vars.empty externals
  in

  (* Factor out functions for llvm *)
  let funcs =
    let lst = extract typed_expr.expr in
    let vars =
      List.fold_left
        (fun acc { name = name, named, uniq; params = _; typ; body = _ } ->
          let name = if named then unique_name (name, uniq) else name in
          Vars.add name (declare_function name typ) acc)
        vars lst
    in
    List.fold_left (fun acc func -> gen_function acc func) vars lst
  in
  (* Reset lambda counter *)
  reset fun_get_state;
  (* Add main *)
  let linkage = Llvm.Linkage.External in
  ignore
  @@ gen_function funcs ~linkage
       {
         name = ("main", false, None);
         params = [ "" ];
         typ = TFun ([ TInt ], TInt, Simple);
         body = { typed_expr with typ = TInt };
       };

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
