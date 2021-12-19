open Types
module Vars = Map.Make (String)

module Str = struct
  type t = string

  let hash = Hashtbl.hash

  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)

let record_tbl = Strtbl.create 1

(* TODO This can be merged with TFun record *)
type user_func = {
  name : string * bool * int option;
  params : string list;
  typ : typ;
  body : Typing.typed_expr;
}

type func = User of user_func | Generic of string * Typing.generic_fun

type llvar = { value : Llvm.llvalue; typ : typ; lltyp : Llvm.lltype }

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

let unit_type = Llvm.void_type context

let voidptr_type = Llvm.(i8_type context |> pointer_type)

let closure_type =
  let t = Llvm.named_struct_type context "closure" in
  let typ = [| voidptr_type; voidptr_type |] in
  Llvm.struct_set_body t typ false;
  t

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

(* Named structs for records *)

let is_generic_record = function
  | TRecord (Some i, _, labels) -> (
      match labels.(i) |> snd with QVar _ -> true | _ -> false)
  | TRecord _ -> false
  | _ -> failwith "Internal Error: Not a record"

let rec record_name = function
  (* We match on each type here to allow for nested parametrization like [int foo bar] *)
  | TRecord (param, name, labels) ->
      let some p =
        let p = labels.(p) |> snd in
        (match p with QVar _ -> "generic" | t -> record_name t) ^ "_"
      in
      Printf.sprintf "%s%s" (Option.fold ~none:"" ~some param) name
  | t -> Typing.string_of_type t

(*
   Some other polymorphic utils
*)

let poly_name poly = "__" ^ poly

let rec add_poly_vars poly_vars = function
  | QVar id when List.mem id poly_vars |> not ->
      (* Later, this will be poly_name. I don't want to change everything now *)
      id :: poly_vars
  | TFun (ps, r, _) ->
      let poly_vars = List.fold_left add_poly_vars poly_vars ps in
      add_poly_vars poly_vars r
  | TVar { contents = Link t } -> add_poly_vars poly_vars t
  | _ -> (* We don't care about records for now *) poly_vars

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
  | TRecord _ as t -> (
      let name = record_name t in
      match Strtbl.find_opt record_tbl name with
      | Some t -> if param then t |> Llvm.pointer_type else t
      | None ->
          failwith (Printf.sprintf "Record struct not found for type %s" name))
  | QVar _ -> generic_type |> Llvm.pointer_type
  | TVar _ as t ->
      failwith (Printf.sprintf "Wrong type TODO: %s" (Typing.string_of_type t))

(* LLVM type of closure struct and records *)
and typeof_aggregate agg =
  Array.map (fun (_, typ) -> get_lltype ~param:false typ) agg
  |> Llvm.struct_type context

and typeof_func ~param ~decl (params, ret, kind) =
  if param then closure_type |> Llvm.pointer_type
  else
    (* When [get_lltype] is called on a function, we handle the dynamic case where
       a function or closure is being passed to another function.
       If a record is returned, we allocate it at the caller site and
       pass it as first argument to the function *)
    let prefix, ret_t =
      match ret with
      | (TRecord _ as t) | (QVar _ as t) ->
          ([ get_lltype ~param:true t ], unit_type)
      | t -> ([], get_lltype ~param t)
    in
    let t = TFun (params, ret, kind) in
    let pvars = add_poly_vars [] t |> List.map (Fun.const num_type) in
    let suffix =
      (* A closure needs an extra parameter for the environment  *)
      if decl then
        match kind with Closure _ -> pvars @ [ voidptr_type ] | _ -> pvars
      else pvars @ [ voidptr_type ]
    in
    let params_t =
      (* For the params, we want to produce the param type, hence ~param:true *)
      List.map (get_lltype ~param:true) params |> fun lst ->
      prefix @ lst @ suffix |> Array.of_list
    in
    let ft = Llvm.function_type ret_t params_t in
    ft

type poly_var_kind = Param | Local of typ

let to_named_records = function
  | TRecord (_, name, _) as r when is_generic_record r ->
      let name = Printf.sprintf "generic_%s" name in
      let t = Llvm.named_struct_type context name in
      if Strtbl.mem record_tbl name then
        failwith ("Internal Error: Type shadowing for generic" ^ name);
      Strtbl.add record_tbl name t
  | TRecord (_, _, labels) as t ->
      let name = record_name t in
      let t = Llvm.named_struct_type context name in
      let lltyp = typeof_aggregate labels |> Llvm.struct_element_types in
      Llvm.struct_set_body t lltyp false;

      if Strtbl.mem record_tbl name then
        failwith "Internal Error: Type shadowing not supported in codegen TODO";
      Strtbl.add record_tbl name t
  | _ -> failwith "Internal Error: Only records should be here"

let alignup ~size ~upto =
  let modulo = size mod upto in
  if Int.equal modulo 0 then (* We are aligned *)
    size else size + (upto - modulo)

let sizeof_typ typ =
  let rec inner ~size = function
    | TInt -> alignup ~size ~upto:4 + 4
    | TBool -> alignup ~size ~upto:1 + 1
    | TUnit -> failwith "Does this make sense?"
    | TVar { contents = Link t } -> inner ~size t
    | TFun _ -> (* Just a ptr? Assume 64bit *) alignup ~size ~upto:8 + 8
    | TRecord _ as t when is_generic_record t -> failwith "TODO gen rec size"
    | TRecord (_, _, labels) ->
        Array.fold_left (fun size (_, t) -> inner ~size t) size labels
    | QVar _ | TVar _ -> failwith "too generic for a size"
  in
  inner ~size:0 typ

(* Returns offset to [label] at [index] in byte *)
let offset_of ~labels index =
  let rec inner i ~size =
    if i < index then
      let labelsize = sizeof_typ (labels.(i) |> snd) in
      let size = alignup ~size ~upto:labelsize + labelsize in
      inner (i + 1) ~size
    else size
  in
  inner 0 ~size:0

(* Given two ptr types (most likely to structs), copy src to dst *)
let memcpy ~dst ~src =
  let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
  let retptr = Llvm.build_bitcast src.value voidptr_type "" builder in
  let size = Llvm.const_int num_type (sizeof_typ src.typ) in
  let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
  ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder)

(*
   Module state
*)

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

(* Transforms abs into a TFun and cleans all types (resolves links) *)
let split_abs (abs : Typing.abstraction) =
  let params = List.map clean abs.tp.tparams in
  (TFun (params, clean abs.body.typ, abs.tp.kind), abs.nparams)

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
        inner (User { name; params; typ; body = abs.body } :: acc) cont.expr
    | Let (_, e1, e2) ->
        let acc = inner acc e1.expr in
        inner acc e2.expr
    | Lambda abs ->
        let acc = inner acc abs.body.expr in
        let name = (lambda_name fun_gen_state, false, None) in
        let typ, params = split_abs abs in
        User { name; params; typ; body = abs.body } :: acc
    | App { callee; args } ->
        let acc = inner acc callee.expr in
        List.fold_left
          (fun acc { Typing.arg; gen_fun } ->
            let acc = inner acc Typing.(arg.expr) in
            match gen_fun with
            | Some (name, gen) -> generic_parameter name gen acc
            | None -> acc)
          acc args
    | Record labels ->
        List.fold_left (fun acc (_, e) -> inner acc Typing.(e.expr)) acc labels
    | Field (expr, _) -> inner acc expr.expr
    | Sequence (expr, cont) ->
        let acc = inner acc expr.expr in
        inner acc cont.expr
  and generic_parameter name gen acc =
    let exists = function
      | Generic (n, _) -> String.equal name n
      | User _ -> false
    in
    if List.exists exists acc then acc else Generic (name, gen) :: acc
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

  { value = clsr_struct; typ = func.typ; lltyp = func.lltyp }

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

(*
   Polymorphism util functions
*)

let is_polymorphic = function
  | QVar _ | TVar { contents = Unbound (_, _) } -> true
  | _ -> false

let pass_generic_wrap vars llvar kind name =
  let closure_struct = Llvm.build_alloca closure_type "clstmp" builder in
  let fp = Llvm.build_struct_gep closure_struct 0 "funptr" builder in
  let gen_fp = Vars.find name vars in
  let ptr = Llvm.build_bitcast gen_fp.value voidptr_type "" builder in
  ignore (Llvm.build_store ptr fp builder);

  (* Store the actual function in the env *)
  (* The env here is a complete closure again *)
  let envptr = Llvm.build_struct_gep closure_struct 1 "envptr" builder in

  (* The closure can be stored as is. Far a simple function we have to wrap *)
  let clsr_obj =
    match kind with
    | Simple ->
        let clsr_obj = (gen_closure_obj [] llvar vars "wrapped").value in
        clsr_obj
    | Closure _ -> llvar.value
  in
  let clsr_casted = Llvm.build_bitcast clsr_obj voidptr_type "" builder in

  ignore (Llvm.build_store clsr_casted envptr builder);
  closure_struct

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
  match llvar.typ with
  | TFun (_, _, kind) -> pass_function vars llvar kind
  | _ -> llvar

(* Make polymorphic argument ouf of [var] to be passed at its location.
   This does not create a poly_var! *)
let make_poly_arg_local var =
  let gen_ptr = generic_type |> Llvm.pointer_type in
  match var.typ with
  | TInt | TBool ->
      let ptr = Llvm.build_alloca var.lltyp "gen" builder in
      ignore (Llvm.build_store var.value ptr builder);
      Llvm.build_bitcast ptr gen_ptr "" builder
  | TRecord _ | TFun _ -> Llvm.build_bitcast var.value gen_ptr "" builder
  | _ ->
      failwith
        ("Internal Error: Cannot make poly var out of "
        ^ Typing.string_of_type var.typ)

let add_poly_arg vars name mkvar =
  (* Add a poly var to the list if it is not already present.
     This list is used to pass poly vars as arguments, so it is important that its impl
     stays in sync with [add_poly_vars] *)
  match List.assoc_opt name vars with
  | Some _ -> vars
  | None ->
      (* This will get more complicated once we have containers of polymorphic variables *)
      (* let poly_var =  Llvm.const_int num_type (sizeof_typ var.typ) in *)
      (name, mkvar ()) :: vars

let rec add_poly_args vars poly_args param arg =
  match (param, arg) with
  | t, TVar { contents = Link link } -> add_poly_args vars poly_args t link
  | QVar id, QVar _ | QVar id, TVar { contents = Unbound (_, _) } ->
      (* Param poly var *)
      let name = poly_name id in
      let mkvar () =
        match Vars.find_opt name vars with
        | Some v -> (v.value, Param)
        | None ->
            failwith
              (Printf.sprintf "Internal Error: poly var should be in env: %s"
                 name)
      in
      add_poly_arg poly_args name mkvar
  | QVar id, t ->
      (* Local poly var *)
      let name = poly_name id in
      let mkvar () = (sizeof_typ t |> Llvm.const_int num_type, Local t) in
      add_poly_arg poly_args name mkvar
  | TFun (p1, r1, _), TFun (p2, r2, _) ->
      let f = add_poly_args vars in
      let poly_args = List.fold_left2 f poly_args p1 p2 in
      add_poly_args vars poly_args r1 r2
  | TVar _, _ -> failwith "Internal Error: How is this not generalized?"
  | _, _ -> poly_args

let handle_generic_arg vars poly_args param (arg, gen_fun) =
  (* Generic func is only needed in the case of both param ond arg not being
     fully polymorphic *)
  let poly_args = add_poly_args vars poly_args param arg.typ in
  match (param, arg.typ) with
  | QVar _, arg' when is_polymorphic arg' ->
      (* We don't have to do anything else, as the poly var is already present *)
      (poly_args, arg.value)
  | QVar _, _ ->
      (* The argument is generic and does not exist yet.
         We have to convert a local value to a generic one *)
      let value_to_pass = func_to_closure vars arg |> make_poly_arg_local in
      (poly_args, value_to_pass)
  | TFun _, TFun (_, _, kind) when Option.is_some gen_fun ->
      (* There might be poly vars in the param function, but how can we access them?
         Do we even have to? *)
      let name, _ = Option.get gen_fun in
      (poly_args, pass_generic_wrap vars arg kind name)
  | _, _ ->
      (* No polymorphism involved *)
      let arg = func_to_closure vars arg in
      (poly_args, arg.value)

let handle_generic_ret vars flltyp poly_vars (funcval, args, envarg) ret params
    =
  let t = TFun (params, ret, Simple) in
  let poly_args =
    add_poly_vars [] t
    |> List.map (fun id ->
           let name = poly_name id in
           (match List.assoc_opt name poly_vars with
           | Some s -> s
           | None ->
               let v =
                 match Vars.find_opt name vars with
                 | Some v -> v.value
                 | None ->
                     Printf.sprintf "Could not find %s in var" name |> failwith
               in
               (v, Param))
           |> fst)
  in

  (* Mostly copied from the [gen_app] inline code before  *)
  match ret with
  | TRecord _ ->
      let lltyp = get_lltype ~param:false ret in
      let retval = Llvm.build_alloca lltyp "ret" builder in
      (* TODO pass poly args? *)
      let args = Array.of_list ([ retval ] @ args @ envarg) in
      ignore (Llvm.build_call funcval args "" builder);
      (retval, ret, lltyp)
  | QVar id as t ->
      (* Conceptually, this works like the record case. The only difference is that we need to get
            the size of variable from somewhere. We can look up the size in the type parameter *)
      (* This is a bit messy, can we clean this up somehow? *)
      let name = poly_name id in
      let size = List.assoc name poly_vars |> fst in

      (* What about alignment? *)
      let ret = Llvm.build_array_alloca byte_type size "ret" builder in
      Llvm.set_alignment 16 ret;

      let gen_ptr_t = generic_type |> Llvm.pointer_type in
      let ret = Llvm.build_bitcast ret gen_ptr_t "ret" builder in

      ignore
        (Llvm.build_call funcval
           (Array.of_list ((ret :: args) @ poly_args @ envarg))
           "" builder);

      (* If it's a local type, we reconstruct it *)
      let retval, typ =
        match List.assoc name poly_vars |> snd with
        | Local (TBool as t) | Local (TInt as t) ->
            let ptr_t = get_lltype ~param:false t |> Llvm.pointer_type in
            let cast = Llvm.build_bitcast ret ptr_t "" builder in
            (Llvm.build_load cast "realret" builder, t)
        | Local (TRecord _ as t) ->
            (Llvm.build_bitcast ret (get_lltype ~param:true t) "" builder, t)
        | _ -> (ret, t)
      in
      (retval, typ, gen_ptr_t)
  | t ->
      let retval =
        Llvm.build_call funcval (Array.of_list (args @ envarg)) "" builder
      in
      (* TODO use concrete return type *)
      (retval, t, flltyp |> Llvm.return_type)

(* TODO put below gen_expr *)
let rec gen_function funcs ?(linkage = Llvm.Linkage.Private)
    { name = name, named, uniq; params; typ; body } =
  let fun_name = if named then unique_name (name, uniq) else name in
  match typ with
  | TFun (tparams, ret_t, kind) as typ ->
      let func = declare_function fun_name typ in
      Llvm.set_linkage linkage func.value;

      let start_index = match ret_t with TRecord _ | QVar _ -> 1 | _ -> 0 in

      let pvars = add_poly_vars [] typ in

      (* gen function body *)
      let bb = Llvm.append_block context "entry" func.value in
      Llvm.position_at_end bb builder;

      (* Add params from closure *)
      (* We generate both the code for extracting the closure and add the vars to the environment *)
      let temp_funcs = add_closure funcs func kind in

      let temp_funcs, pvar_index =
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

      let temp_funcs, _ =
        List.fold_left
          (fun (env, i) pvar ->
            let value = (Llvm.params func.value).(i) in
            let param = { value; typ = QVar pvar; lltyp = num_type } in
            let name = poly_name pvar in
            Llvm.set_value_name name value;
            (Vars.add name param env, i + 1))
          (temp_funcs, pvar_index) pvars
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
          let size = Llvm.const_int num_type (sizeof_typ ret.typ) in
          let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
          ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder);
          ignore (Llvm.build_ret_void builder)
      | QVar id ->
          let dst = Llvm.(params func.value).(0) in
          let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
          let retptr = Llvm.build_bitcast ret.value voidptr_type "" builder in

          let size =
            match Vars.find_opt (poly_name id) temp_funcs with
            | Some v -> v.value
            | None ->
                failwith "TODO Internal Error: Unknown size of generic type"
          in
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

      if Llvm_analysis.verify_function func.value |> not then
        Llvm.dump_module the_module;

      Llvm_analysis.assert_valid_function func.value;
      let _ = Llvm.PassManager.run_function func.value fpm in

      (* Printf.printf "Modified: %b\n" modified; *)
      Vars.add fun_name func funcs
  | _ ->
      prerr_endline fun_name;
      failwith "Interal Error: generating non-function"

and gen_expr vars typed_expr =
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
        match abs.tp.kind with
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
      match abs.tp.kind with
      | Simple -> func
      | Closure assoc -> gen_closure_obj assoc func vars name)
  | App { callee; args } -> gen_app vars callee args
  | If (cond, e1, e2) -> gen_if vars cond e1 e2
  | Record labels -> codegen_record vars (clean typed_expr.typ) labels
  | Field (expr, index) -> codegen_field vars expr index
  | Sequence (expr, cont) -> codegen_chain vars expr cont

and gen_generic funcs name { Typing.concrete; generic } =
  (* Lots copied from gen_function. See comments there *)
  (* Simplest solution, no closures or something *)

  (* We make sure in [extract] that only the functions are unique *)

  (* If the function does not yet exist, we generate it *)

  (* For params, extract out the correct type *)
  let func_typ = TFun (generic.tparams, generic.ret, Closure []) in
  let gen_func = declare_function name func_typ in

  let bb = Llvm.append_block context "entry" gen_func.value in
  Llvm.position_at_end bb builder;

  let start_index = match generic.ret with TRecord _ | QVar _ -> 1 | _ -> 0 in
  let closure_index = (Llvm.params gen_func.value |> Array.length) - 1 in

  (* Get wrapped function *)
  let wrapped_func =
    let typ = TFun (concrete.tparams, concrete.ret, concrete.kind) in
    let lltyp =
      typeof_func ~param:false ~decl:true
        (concrete.tparams, concrete.ret, concrete.kind)
    in

    (* We always pass the function as closures, even when they are not.
       The C calling convention apparently allows this and this makes it
       easier for us to reuse the generic function. If we ever need to
       optimize hard, we can make the generic function closure-aware *)
    let clsr_param = (Llvm.params gen_func.value).(closure_index) in

    let clsr_ptr =
      Llvm.build_bitcast clsr_param
        (closure_type |> Llvm.pointer_type)
        "" builder
    in
    { value = clsr_ptr; typ; lltyp }
  in

  let i = ref start_index in

  let args_llvars =
    List.map2
      (fun concrete generic ->
        let value =
          match (generic, concrete) with
          | QVar _, (TBool as typ) | QVar _, (TInt as typ) ->
              let lltyp = get_lltype typ |> Llvm.pointer_type in
              (* let ptr = Llvm.build_alloca lltyp "" builder in
               * ignore (Llvm.build_store (Llvm.params gen_func.value).(!i) ptr builder); *)
              let ptr =
                Llvm.build_bitcast
                  (Llvm.params gen_func.value).(!i)
                  lltyp "" builder
              in
              { value = Llvm.build_load ptr "" builder; typ; lltyp }
          | QVar _, (TRecord _ as typ) ->
              let lltyp = get_lltype typ in
              let value =
                Llvm.build_bitcast
                  (Llvm.params gen_func.value).(!i)
                  lltyp "" builder
              in
              { value; typ; lltyp }
          | QVar _, (TFun _ as typ) ->
              (* If the closure was passed as a generic param, we need to cast to closure *)
              let lltyp = closure_type |> Llvm.pointer_type in
              let value =
                Llvm.build_bitcast
                  (Llvm.params gen_func.value).(!i)
                  lltyp "" builder
              in
              { value; typ; lltyp }
          | _, typ ->
              let lltyp = get_lltype typ in
              (* TODO what's going on here? *)
              { value = (Llvm.params gen_func.value).(!i); typ; lltyp }
        in
        incr i;
        value)
      concrete.tparams generic.tparams
  in

  let (vars, _), exprs =
    List.fold_left_map
      (fun (vars, i) llvar ->
        (* We introduce some unique names for the vars and make them available through Var name *)
        let name = "___" ^ string_of_int i in
        ( (Vars.add name llvar vars, i + 1),
          (* We assume the generic fun itself has no generic fun param *)
          let arg = { Typing.typ = llvar.typ; expr = Var name } in
          { Typing.arg; gen_fun = None } ))
      (funcs, 0) args_llvars
  in

  let typed_expr = { Typing.typ = TUnit; expr = Var name } in
  let ret = gen_app (Vars.add name wrapped_func vars) typed_expr exprs in

  let () =
    ignore
      (match (generic.ret, concrete.ret) with
      | QVar _, (TBool as typ) | QVar _, (TInt as typ) ->
          let lltyp = get_lltype typ |> Llvm.pointer_type in
          (* Store int in return param *)
          let ret_param = (Llvm.params gen_func.value).(0) in
          let ptr = Llvm.build_bitcast ret_param lltyp "" builder in
          ignore (Llvm.build_store ret.value ptr builder);
          Llvm.build_ret_void builder
      | QVar _, TRecord _ | _, TRecord _ ->
          (* memcpy record and return void *)
          let dst = Llvm.(params gen_func.value).(0) in
          let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
          let retptr = Llvm.build_bitcast ret.value voidptr_type "" builder in

          let size = Llvm.const_int num_type (sizeof_typ concrete.ret) in
          let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
          ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder);
          Llvm.build_ret_void builder
      | QVar _, QVar id | QVar _, TVar { contents = Unbound (id, _) } ->
          print_endline @@ "generic return in gen with id: " ^ id;
          let dst = Llvm.(params gen_func.value).(0) in
          let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
          let retptr = Llvm.build_bitcast ret.value voidptr_type "" builder in

          let size =
            match Vars.find_opt (poly_name id) funcs with
            | Some v -> v.value
            | None ->
                failwith "TODO Internal Error: Unknown size of generic type"
          in
          let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
          ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder);
          Llvm.build_ret_void builder
      | TUnit, TUnit ->
          (* void return *)
          Llvm.build_ret_void builder
      | _, _ -> (* normal return *) Llvm.build_ret ret.value builder)
  in

  Llvm_analysis.assert_valid_function gen_func.value;
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
  let func = gen_expr vars callee in

  let params, ret, kind =
    match func.typ with
    | TFun (params, ret, kind) -> (params, ret, kind)
    | _ -> failwith "Internal Error: Not a func in gen app"
  in

  (* TODO args not vars *)
  let poly_args, args =
    List.fold_left_map
      (fun poly_vars (param, { Typing.arg; gen_fun }) ->
        (* let before_t = arg.typ in *)
        let typ = arg.typ in
        (* We have to preserve the concrete type. Otherwise we get the generalized one *)
        let arg = gen_expr vars arg in
        let arg = { arg with typ } in
        let argtup = (arg, gen_fun) in
        (* let after_t = (fst argtup).typ in *)
        (* Printf.printf "before: %s\nafter: %s\n%!" (show_typ before_t) (show_typ after_t); *)
        handle_generic_arg vars poly_vars param argtup)
      [] (List.combine params args)
  in

  (* Add return poly var *)
  let poly_args = add_poly_args vars poly_args ret ret in

  (* No names here, might be void/unit *)
  let callee =
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
      (funcp, args, [ env_ptr ])
    else
      match kind with
      | Simple -> (func.value, args, [])
      | Closure _ -> (
          (* In this case we are in a recursive closure function.
             We get the closure env and add it to the arguments we pass *)
          match Vars.find_opt (Llvm.value_name func.value) vars with
          | Some func ->
              (* We do this to make sure it's a recursive function.
                 If we cannot find something. there is an error somewhere *)
              let closure_index =
                (Llvm.params func.value |> Array.length) - 1
              in

              let env_ptr = (Llvm.params func.value).(closure_index) in
              (func.value, args, [ env_ptr ])
          | None ->
              failwith "Internal Error: Not a recursive closure application")
  in

  let value, typ, lltyp =
    handle_generic_ret vars func.lltyp poly_args callee ret params
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
  (* print_endline (show_typ typ); *)
  (* Strtbl.iter (fun key _ -> Printf.printf "%s\n" key) record_tbl; *)
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

  (* print_endline "in field";
   * Printf.printf "%b\n" (value.lltyp = (generic_type |> Llvm.pointer_type));
   * Printf.printf "%s\n%!" (show_typ value.typ); *)
  (* Llvm.dump_module the_module; *)
  let typ =
    match value.typ with
    | TRecord (_, _, fields) -> fields.(index) |> snd
    | _ -> failwith "Internal Error: No record in fields"
  in

  let ptr =
    if is_generic_record value.typ then (
      (* We treat the whole structure as a byte array and then calculate the offset by hand *)
      (* TODO we can't yet know the generic size, so we just assume some bogus size for testing *)
      (* let size = Llvm.const_int num_type 200 in *)
      let byte_ptr = byte_type |> Llvm.pointer_type in
      let byte_array = Llvm.build_bitcast value.value byte_ptr "" builder in
      let offset =
        match value.typ with
        | TRecord (_, _, labels) -> offset_of ~labels index
        | _ -> failwith "Internal Error: No record for offset"
      in
      let const i = Llvm.const_int num_type i in
      let gep_indices = [| const offset |] in
      print_endline "before gep";
      Llvm.dump_module the_module;
      let ptr = Llvm.build_gep byte_array gep_indices "" builder in
      print_endline "after gep";

      Llvm.build_bitcast ptr
        (get_lltype ~param:false typ |> Llvm.pointer_type)
        "" builder
      (* let byte_ptr = Llvm.build_bitcast value.value *)
      (* failwith "TODO generic indexing" *))
    else Llvm.build_struct_gep value.value index "" builder
  in

  (* In case we return a record, we don't load, but return the pointer.
     The idea is that this will be used either as a return value for a function (where it is copied),
     or for another field, where the pointer is needed.
     We should distinguish between structs and pointers somehow *)
  let value =
    match typ with TRecord _ -> ptr | _ -> Llvm.build_load ptr "" builder
  in
  { value; typ; lltyp = Llvm.type_of value }

and codegen_chain vars expr cont =
  ignore (gen_expr vars expr);
  gen_expr vars cont

let decl_external (name, typ) =
  match typ with
  | TFun (ts, t, _) as typ ->
      let return_t = get_lltype t in
      let arg_t = List.map get_lltype ts |> Array.of_list in
      let ft = Llvm.function_type return_t arg_t in
      { value = Llvm.declare_function name ft the_module; typ; lltyp = ft }
  | _ -> failwith "TODO external symbols"

let generate { Typing.externals; records; tree } =
  let open Typing in
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
    let lst = extract tree.expr in
    let vars =
      List.fold_left
        (fun acc func ->
          match func with
          | User { name = name, named, uniq; params = _; typ; body = _ } ->
              let name = if named then unique_name (name, uniq) else name in
              Vars.add name (declare_function name typ) acc
          | Generic (name, gen) ->
              (* type_of_generic?? *)
              let typ =
                TFun (gen.generic.tparams, gen.generic.ret, Closure [])
              in
              Vars.add name (declare_function name typ) acc)
        vars lst
    in

    (* Generate functions *)
    List.fold_left
      (fun acc func ->
        match func with
        | User func -> gen_function acc func
        | Generic (name, gen) -> gen_generic acc name gen)
      vars lst
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
         body = { tree with typ = TInt };
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
