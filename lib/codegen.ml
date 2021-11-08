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

let generic_type = Llvm.named_struct_type context "generic"

let byte_type = Llvm.i8_type context

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
  | TFun (params, ret, kind) ->
      typeof_func ~param ~decl:false (params, ret, kind)
  | TRecord (_, labels) ->
      let t = typeof_aggregate labels in
      if param then t |> Llvm.pointer_type else t
  | QVar _ -> generic_type |> Llvm.pointer_type
  | TVar _ as t ->
      failwith (Printf.sprintf "Wrong type TODO: %s" (Typing.string_of_type t))

(* LLVM type of closure struct and records *)
and typeof_aggregate agg =
  List.map (fun (_, typ) -> get_lltype ~param:false typ) agg
  |> Array.of_list |> Llvm.struct_type context

and typeof_func ~param ~decl (params, t, kind) =
  if param then closure_type |> Llvm.pointer_type
  else
    (* When [get_lltype] is called on a function, we handle the dynamic case where
       a function or closure is being passed to another function.
       If a record is returned, we allocate it at the caller site and
       pass it as first argument to the function *)
    let prefix, ret_t =
      match t with
      | (TRecord _ as t) | (QVar _ as t) ->
          ([ get_lltype ~param:true t ], unit_type)
      | t -> ([], get_lltype ~param t)
    in
    let qvars = qvars_of_func params t |> List.map (Fun.const num_type) in
    let suffix =
      (* A closure needs an extra parameter for the environment  *)
      if decl then
        match kind with Closure _ -> voidptr_type :: qvars | _ -> qvars
      else voidptr_type :: qvars
    in
    let params_t =
      (* For the params, we want to produce the param type, hence ~param:true *)
      List.map (get_lltype ~param:true) params |> fun lst ->
      prefix @ lst @ suffix |> Array.of_list
    in
    let ft = Llvm.function_type ret_t params_t in
    ft

and qvars_of_func params ret =
  let qvars = match ret with QVar id -> [ id ] | _ -> [] in
  List.fold_left
    (fun qvars param ->
      match param with
      | QVar id when List.mem id qvars |> not -> id :: qvars
      | _ -> qvars)
    qvars params
  |> List.rev

let name_of_qvar qvar = "__" ^ qvar

type qvar_kind = Param of Llvm.llvalue | Local of typ

type fun_pieces = { parameters : typ list; ret : typ; kind : Types.fun_kind }

type generic_fun = { concrete : fun_pieces; generic : fun_pieces }

let name_of_generic { concrete; generic } =
  let rec str_of_typ = function
    | TInt -> "i"
    | TBool -> "b"
    | TUnit -> "u"
    | TVar { contents = Unbound _ } -> "g"
    | TVar { contents = Link t } -> str_of_typ t
    | QVar _ -> "g"
    | TFun (params, ret, _) ->
        "."
        ^ String.concat "" (List.map str_of_typ params)
        ^ "." ^ str_of_typ ret ^ "."
    | TRecord (name, _) -> name
  in

  (str_of_typ concrete.ret ^ str_of_typ generic.ret)
  :: List.map2
       (fun concrete generic -> str_of_typ concrete ^ str_of_typ generic)
       concrete.parameters generic.parameters
  |> String.concat "_" |> ( ^ ) "__"

let needs_generic_wrap _ _ = None

(* Given two ptr types (most likely to structs), copy src to dst *)
let memcpy ~dst ~src =
  (* let dst = Llvm.(params func.value).(0) in *)
  let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
  let retptr = Llvm.build_bitcast src.value voidptr_type "" builder in
  let size = Llvm.size_of (get_lltype ~param:false src.typ) in
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
        |> generic_parameters e1 args
    | Record labels ->
        List.fold_left (fun acc (_, e) -> inner acc Typing.(e.expr)) acc labels
    | Field (expr, _) -> inner acc expr.expr
  and generic_parameters fn args acc =
    match fn.typ with
    | TFun (params, _, _) ->
        List.fold_left2
          (fun acc param (arg : Typing.typed_expr) ->
            match (param, arg.typ) with
            | TFun (ps1, ret1, kind1), TFun (ps2, ret2, kind2) -> (
                let generic = { parameters = ps1; ret = ret1; kind = kind1 } in
                let concrete = { parameters = ps2; ret = ret2; kind = kind2 } in
                match needs_generic_wrap generic concrete with
                | Some name ->
                    ignore name;
                    acc
                | None -> acc)
            | _ -> acc)
          acc params args
    | _ -> acc
  in
  inner [] expr

let declare_function fun_name = function
  | TFun (params, ret, kind) as typ ->
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

(* TODO put below gen_expr *)
let rec gen_function funcs ?(linkage = Llvm.Linkage.Private)
    { name = name, named, uniq; params; typ; body } =
  (* Llvm.dump_module the_module; *)
  let fun_name = if named then unique_name (name, uniq) else name in
  match typ with
  | TFun (tparams, ret_t, kind) as typ ->
      let func = declare_function fun_name typ in
      Llvm.set_linkage linkage func.value;

      (* If we return a struct, the first parameter is the ptr to it *)
      let start_index = match ret_t with TRecord _ | QVar _ -> 1 | _ -> 0 in

      (* We traverse the list once here and another time at the bottom. We do this because we need
         the closure index for the closure vars, but want function params to have higher precedence *)
      let closure_index = List.length params + start_index in

      (* gen function body *)
      let bb = Llvm.append_block context "entry" func.value in
      Llvm.position_at_end bb builder;

      (* Add params from closure *)
      (* We both generate the code for extracting the closure and add the vars to the environment *)
      let temp_funcs =
        match kind with
        | Simple -> funcs
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
                (funcs, 0) assoc
            in
            env
      in

      let temp_funcs, qvar_index =
        List.fold_left2
          (fun (env, i) name typ ->
            let value = (Llvm.params func.value).(i) in
            let param =
              { value; typ = clean typ; lltyp = Llvm.type_of value }
            in
            Llvm.set_value_name name value;
            (Vars.add name param env, i + 1))
          (temp_funcs, start_index) params tparams
      in

      let qvars = qvars_of_func tparams ret_t in
      let temp_funcs, _ =
        List.fold_left
          (fun (env, i) qvar ->
            let value = (Llvm.params func.value).(i) in
            let param = { value; typ = QVar qvar; lltyp = num_type } in
            let name = name_of_qvar qvar in
            Llvm.set_value_name name value;
            (Vars.add name param env, i + 1))
          (temp_funcs, qvar_index) qvars
      in

      (* If the function is named, we allow recursion *)
      let temp_funcs =
        if named then Vars.add fun_name func temp_funcs else temp_funcs
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
          let size = Llvm.size_of (get_lltype ~param:false ret.typ) in
          let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
          ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder);
          ignore (Llvm.build_ret_void builder)
      | QVar id ->
          let dst = Llvm.(params func.value).(0) in
          let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
          let retptr = Llvm.build_bitcast ret.value voidptr_type "" builder in

          let size = (Vars.find (name_of_qvar id) temp_funcs).value in
          let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
          ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder);
          ignore (Llvm.build_ret_void builder)
      | _ ->
          (* TODO pattern match on unit *)
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
      | Simple -> func
      | Closure assoc -> gen_closure_obj assoc func vars name)
  | App (callee, arg) -> gen_app vars callee arg
  | If (cond, e1, e2) -> gen_if vars cond e1 e2
  | Record labels -> codegen_record vars (clean typed_expr.typ) labels
  | Field (expr, index) -> codegen_field vars expr index

and gen_generic funcs ({ concrete; generic } as gen) =
  (* Lots copied from gen_function. See comments there *)
  (* Simplest solution, no closures or something *)
  let name = name_of_generic gen in
  match Vars.find_opt name funcs with
  | Some _ -> funcs
  | None ->
      (* If the function does not yet exist, we generate it *)

      (* For params, extract out the correct type *)
      let func_typ = TFun (generic.parameters, generic.ret, Closure []) in
      let gen_func = declare_function name func_typ in

      let bb = Llvm.append_block context "entry" gen_func.value in
      Llvm.position_at_end bb builder;

      let start_index =
        match generic.ret with TRecord _ | QVar _ -> 1 | _ -> 0
      in
      let closure_index = List.length generic.parameters + start_index in

      (* Get wrapped function *)
      let func =
        let typ = TFun (concrete.parameters, concrete.ret, concrete.kind) in
        let lltyp = typ |> get_lltype ~param:false in
        let func_type = lltyp |> Llvm.pointer_type in

        let clsr_param = (Llvm.params gen_func.value).(closure_index) in
        print_endline "before cast";
        (* The env is not an env here, but a whole closure *)
        let clsr_ptr =
          Llvm.build_bitcast clsr_param
            (closure_type |> Llvm.pointer_type)
            "" builder
        in
        print_endline "after cast";
        let funcp = Llvm.build_struct_gep clsr_ptr 0 "funcptr" builder in
        let funcp = Llvm.build_load funcp "loadtmp" builder in
        let funcp = Llvm.build_bitcast funcp func_type "casttmp" builder in

        (* TODO there is a bug here for non-closure funcs (or closure funcs) *)
        (* let env_ptr = Llvm.build_struct_gep clsr_ptr 1 "envptr" builder in *)
        (* let env_ptr = Llvm.build_load env_ptr "loadtmp" builder in *)
        { value = funcp; typ; lltyp }
      in

      let i = ref start_index in

      let args_llvars =
        List.map2
          (fun concrete generic ->
            let value =
              match (generic, concrete) with
              | QVar _, (TBool as typ) | QVar _, (TInt as typ) ->
                  let lltyp = get_lltype typ |> Llvm.pointer_type in
                  let ptr =
                    Llvm.build_bitcast
                      (Llvm.params func.value).(!i)
                      lltyp "" builder
                  in
                  { value = Llvm.build_load ptr "" builder; typ; lltyp }
              | QVar _, (TRecord _ as typ) ->
                  let lltyp = get_lltype typ in
                  let value =
                    Llvm.build_bitcast
                      (Llvm.params func.value).(!i)
                      lltyp "" builder
                  in
                  { value; typ; lltyp }
              | _, typ ->
                  let lltyp = get_lltype typ in
                  { value = (Llvm.params func.value).(!i); typ; lltyp }
            in
            incr i;
            value
            (* TODO what about function params here? *))
          concrete.parameters generic.parameters
      in

      let (vars, _), exprs =
        List.fold_left_map
          (fun (vars, i) (llvar : llvar) ->
            (* We introduce some unique names for the vars and make them available through Var name *)
            let name = "___" ^ string_of_int i in
            ( (Vars.add name llvar vars, i + 1),
              { Typing.typ = llvar.typ; expr = Var name } ))
          (funcs, 0) args_llvars
      in

      let typed_expr = { Typing.typ = TUnit; expr = Var name } in
      let ret = gen_app (Vars.add name func vars) typed_expr exprs in

      let () =
        ignore
          (match (generic.ret, concrete.ret) with
          | QVar _, (TBool as typ) | QVar _, (TInt as typ) ->
              let lltyp = get_lltype typ |> Llvm.pointer_type in
              let ptr = Llvm.build_bitcast ret.value lltyp "" builder in
              let ret = Llvm.build_load ptr "" builder in
              Llvm.build_ret ret builder
          | QVar _, (TRecord _ as typ) ->
              let lltyp = get_lltype typ in
              Llvm.build_bitcast ret.value lltyp "" builder
          | QVar _, QVar _
          | QVar _, TVar { contents = Unbound _ }
          | TUnit, TUnit
          | _, TRecord _ ->
              (* void return *)
              Llvm.build_ret_void builder
          | _, _ -> (* normal return *) Llvm.build_ret ret.value builder)
      in

      Vars.add name gen_func funcs

and gen_bop e1 e2 bop =
  let bld f str = f e1.value e2.value str builder in
  let open Llvm in
  match bop with
  | Plus -> { value = bld build_add "addtmp"; typ = TInt; lltyp = int_type }
  | Mult -> { value = bld build_mul "multmp"; typ = TInt; lltyp = int_type }
  | Less ->
      let value = bld (build_icmp Icmp.Slt) "lesstmp" in
      { value; typ = TBool; lltyp = bool_type }
  | Equal ->
      let value = bld (build_icmp Icmp.Eq) "eqtmp" in
      { value; typ = TBool; lltyp = bool_type }
  | Minus -> { value = bld build_sub "subtmp"; typ = TInt; lltyp = int_type }

and gen_app vars callee args =
  ignore gen_generic;
  let func = gen_expr vars callee in

  (* We need to extract the qvars in the form of Param of llvalue | Local of typ *)
  let qvars = ref [] in

  let rec aux param arg =
    match (param, arg) with
    | TVar _, _ -> failwith "Should not happen"
    | TFun (params1, ret1, _), TFun (params2, ret2, _) ->
        Printf.printf "funs: %s, %s\n%!"
          (Typing.string_of_type param)
          (Typing.string_of_type arg);
        List.iter2 aux params1 params2;
        aux ret1 ret2;
        ()
    | TFun _, t ->
        Printf.printf "fun left: %s, %s\n%!"
          (Typing.string_of_type param)
          (Typing.string_of_type t);
        ()
    | QVar id, QVar id2 | QVar id, TVar { contents = Unbound (id2, _) } -> (
        Printf.printf "Param: %s, %s\n%!" id id2;
        match List.assoc_opt id !qvars with
        | Some (Param _) -> ()
        | Some (Local _) -> failwith "Unexpected local and param"
        | None ->
            let qvar = (Vars.find (name_of_qvar id) vars).value in
            qvars := (id, Param qvar) :: !qvars)
    | QVar id, t -> (
        match List.assoc_opt id !qvars with
        | Some (Param _) -> failwith "Unexpected local and param"
        | Some (Local _) -> ()
        | None ->
            let typ = t in
            qvars := (id, Local typ) :: !qvars)
    | t1, t2 ->
        ignore t1;
        ignore t2;
        ()
  in

  let params =
    match func.typ with
    | TFun (params, _, _) ->
        List.iter2 aux params
          (List.map (fun (arg : Typing.typed_expr) -> arg.typ) args);
        params
    | _ -> failwith "Internal Error: Not a func in gen app"
  in

  let funcs_to_ptr param (v : llvar) =
    match v.typ with
    | TFun _ when false -> (* TODO of the function has qvars *) failwith "TODO"
    | TFun (_, _, Closure _) ->
        (* This closure is a struct and has an env *)
        v.value
    | TFun _ ->
        (* If a function is passed into [func] we convert it to a closure
           and pass nullptr to env*)
        let closure_struct = Llvm.build_alloca closure_type "clstmp" builder in
        let fp = Llvm.build_struct_gep closure_struct 0 "funptr" builder in
        let ptr = Llvm.build_bitcast v.value voidptr_type "" builder in
        ignore (Llvm.build_store ptr fp builder);

        let envptr = Llvm.build_struct_gep closure_struct 1 "envptr" builder in
        let nullptr = Llvm.const_pointer_null voidptr_type in
        ignore (Llvm.build_store nullptr envptr builder);
        closure_struct
    | QVar id | TVar { contents = Unbound (id, _) } -> (
        match List.assoc_opt id !qvars with
        | Some (Param _) ->
            (* the value already exists?? *)
            v.value
        | Some (Local (TInt as typ)) | Some (Local (TBool as typ)) ->
            let typ = get_lltype ~param:false typ |> Llvm.pointer_type in
            (* TODO differentiate between records and  *)
            let ptr = Llvm.build_alloca typ "gen" builder in
            (* let ptr = Llvm.build_struct_gep ptr 0 "" builder in *)
            ignore (Llvm.build_store v.value ptr builder);
            Llvm.build_bitcast ptr generic_type "" builder
        | Some (Local (TRecord _)) ->
            Llvm.build_bitcast v.value generic_type "" builder
        | Some (Local t) ->
            print_endline @@ "local " ^ Typing.string_of_type t;
            v.value
        | None -> v.value)
    | _ -> (
        match param with
        | QVar id -> (
            (* Local generic argument *)
            let gen_ptr = generic_type |> Llvm.pointer_type in
            match List.assoc_opt id !qvars with
            | Some (Local (TInt as typ)) | Some (Local (TBool as typ)) ->
                let typ = get_lltype ~param:false typ in
                (* TODO differentiate between records and  *)
                let ptr = Llvm.build_alloca typ "gen" builder in
                (* let ptr = Llvm.build_struct_gep ptr 0 "" builder in *)
                ignore (Llvm.build_store v.value ptr builder);
                Llvm.build_bitcast ptr gen_ptr "" builder
            | Some (Local (TRecord _)) ->
                Llvm.build_bitcast v.value gen_ptr "" builder
            | Some (Local t) ->
                print_endline @@ "local " ^ Typing.string_of_type t;
                v.value
            | None | Some (Param _) -> v.value)
        | _ -> v.value)
  in

  let args =
    List.map2 (fun p e -> gen_expr vars e |> funcs_to_ptr p) params args
  in

  (* No names here, might be void/unit *)
  let funcval, args =
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
      (funcp, args @ [ env_ptr ])
    else (func.value, args)
  in

  let get_qval id =
    match List.assoc_opt id !qvars with
    | Some (Param value) -> value
    | Some (Local typ) -> get_lltype ~param:false typ |> Llvm.size_of
    | None ->
        (* print_endline "don't know qvar"; *)
        (Vars.find (name_of_qvar id) vars).value
  in

  (* Llvm.dump_module the_module; *)
  (* Printf.printf "In gen app: %s\n%!" (Typing.string_of_type func.typ); *)
  let value, typ, lltyp =
    match func.typ with
    | TFun (_, (TRecord _ as typ), _) ->
        let lltyp = get_lltype ~param:false typ in
        let ret = Llvm.build_alloca lltyp "ret" builder in
        ignore
          (Llvm.build_call funcval (Array.of_list ([ ret ] @ args)) "" builder);
        (ret, typ, lltyp)
    | TFun (params, (QVar id as typ), _) ->
        (* Conceptually, this works like the record case. The only difference is that we need to get
           the size of variable from somewhere. We can look up the size in the type parameter *)
        let qargs =
          qvars_of_func params typ |> List.map (fun id -> get_qval id)
        in
        let size = get_qval id in

        (* What about alignment? *)
        let ret = Llvm.build_array_alloca byte_type size "ret" builder in
        Llvm.set_alignment 16 ret;

        let gen_ptr_t = generic_type |> Llvm.pointer_type in
        let ret = Llvm.build_bitcast ret gen_ptr_t "ret" builder in
        (* Llvm.dump_module the_module; *)
        ignore
          (Llvm.build_call funcval
             (Array.of_list ((ret :: args) @ qargs))
             "" builder);

        (* If it's a local type, we reconstruct it *)
        let ret, typ =
          match List.assoc_opt id !qvars with
          | Some (Local (TBool as typ)) | Some (Local (TInt as typ)) ->
              let cast =
                Llvm.build_bitcast ret
                  (get_lltype ~param:false typ |> Llvm.pointer_type)
                  "" builder
              in
              (Llvm.build_load cast "realret" builder, typ)
          | Some (Local (TRecord _ as typ)) ->
              ( Llvm.build_bitcast ret (get_lltype ~param:true typ) "" builder,
                typ )
          | _ -> (ret, typ)
        in
        (ret, typ, generic_type)
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
  let lltyp = get_lltype ~param:false typ in
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
