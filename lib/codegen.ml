let context = Llvm.global_context ()

let the_module = Llvm.create_module context "context"

let builder = Llvm.builder context

let int_type = Llvm.i32_type context

let bool_type = Llvm.i1_type context

let unit_type = Llvm.void_type context

module Vars = Map.Make (String)

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

(* let unique_name ~name vars =
 *   match Vars.find_opt name vars with
 *   | None -> name
 *   | Some _ -> gen_unique ~name fun_gen_state *)

type func = { name : string * bool * int option; abs : Typing.abstraction }

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. Note that the counter is global among all
   functions *)
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
        inner ({ name; abs } :: acc) cont.expr
    | Let (_, e1, e2) ->
        let acc = inner acc e1.expr in
        inner acc e2.expr
    | Lambda abs ->
        let acc = inner acc abs.body.expr in
        { name = (lambda_name fun_gen_state, false, None); abs } :: acc
    | App (e1, args) ->
        let acc = inner acc e1.expr in
        List.fold_left (fun acc arg -> inner acc Typing.(arg.expr)) acc args
  in
  inner [] expr

let rec get_lltype = function
  | Typing.TInt -> int_type
  | TBool -> bool_type
  | TVar { contents = Link t } -> get_lltype t
  | TUnit -> unit_type
  | TFun (params, t) ->
      let ret_t = get_lltype t in
      let params_t = List.map get_lltype params |> Array.of_list in
      Llvm.function_type ret_t params_t |> Llvm.pointer_type
  | (TVar _ | QVar _) as t ->
      failwith (Printf.sprintf "Wrong type TODO: %s" (Typing.string_of_type t))

let declare_function fun_name args_t body =
  (* We only support one function arguments so far *)
  let return_t = get_lltype Typing.(body.typ) in
  let ll_args_t =
    List.map (fun (_, arg) -> get_lltype arg) args_t |> Array.of_list
  in
  let ft = Llvm.function_type return_t ll_args_t in
  Llvm.declare_function fun_name ft the_module

let get_generated_func vars name =
  match Vars.find_opt name vars with
  | Some v -> v
  | None ->
      prerr_endline ("Could not find function : " ^ name);
      Vars.iter (fun key _ -> prerr_endline ("in: " ^ key)) vars;
      failwith "Internal error"

let rec gen_function funcs fun_name ~named ?(linkage = Llvm.Linkage.Private)
    Typing.{ params; body } =
  let func = declare_function fun_name params body in
  Llvm.set_linkage linkage func;
  let temp_funcs, _ =
    List.fold_left
      (fun (env, i) (name, _) ->
        let param = (Llvm.params func).(i) in
        Llvm.set_value_name name param;
        (Vars.add name param env, i + 1))
      (funcs, 0) params
  in

  (* If the function is named, we allow recursion *)
  let temp_funcs =
    if named then Vars.add fun_name func temp_funcs else temp_funcs
  in

  (* gen function body *)
  let bb = Llvm.append_block context "entry" func in
  Llvm.position_at_end bb builder;
  (* No closures yet, so it might be dangerous to just pass in the whole env.
     We have to separate functions (which are global) and variables *)
  let ret = gen_expr temp_funcs body in

  (* Don't return a void type *)
  ignore
    (match Llvm.(type_of ret |> classify_type) with
    | Void ->
        (* Bit of a hack, but whatever *)
        if String.equal fun_name "main" then
          Llvm.(build_ret (const_int int_type 0)) builder
        else Llvm.build_ret_void builder
    | _ -> Llvm.build_ret ret builder);
  Llvm_analysis.assert_valid_function func;
  Vars.add fun_name func funcs

and gen_expr vars typed_expr =
  match Typing.(typed_expr.expr) with
  | Typing.Const (Int i) -> Llvm.const_int int_type i
  | Const (Bool b) -> Llvm.const_int bool_type (Bool.to_int b)
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
          failwith
            ("Internal Error: Could not find " ^ id
           ^ " in codegen. No closures yet"))
  | Function (name, uniq, _, cont) ->
      (* The functions are already generated *)
      let func = get_generated_func vars (unique_name (name, uniq)) in
      gen_expr (Vars.add name func vars) cont
  | Let (id, equals_ty, let_ty) ->
      let expr_val = gen_expr vars equals_ty in
      gen_expr (Vars.add id expr_val vars) let_ty
  | Lambda _ -> get_generated_func vars (lambda_name fun_get_state)
  | App (callee, arg) ->
      (* Let's first of all not care about anonymous functions *)
      gen_app vars callee arg
  | If (cond, e1, e2) -> gen_if vars cond e1 e2

and gen_bop e1 e2 = function
  | Plus -> Llvm.build_add e1 e2 "addtmp" builder
  | Mult -> Llvm.build_mul e1 e2 "multmp" builder
  | Less -> Llvm.(build_icmp Icmp.Slt) e1 e2 "lesstmp" builder
  | Equal -> Llvm.(build_icmp Icmp.Eq) e1 e2 "eqtmp" builder
  | Minus -> Llvm.build_sub e1 e2 "subtmp" builder

and gen_app vars callee args =
  let callee = gen_expr vars callee in
  let args = List.map (gen_expr vars) args |> Array.of_list in
  (* No names here, might be void/unit *)
  Llvm.build_call callee args "" builder

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
  let incoming = [ (e1, e1_bb); (e2, e2_bb) ] in
  let phi = Llvm.build_phi incoming "iftmp" builder in
  Llvm.position_at_end start_bb builder;
  Llvm.build_cond_br cond then_bb else_bb builder |> ignore;

  Llvm.position_at_end e1_bb builder;
  ignore (Llvm.build_br merge_bb builder);
  Llvm.position_at_end e2_bb builder;
  ignore (Llvm.build_br merge_bb builder);

  Llvm.position_at_end merge_bb builder;
  phi

let decl_external (name, typ) =
  match typ with
  | Typing.TFun (ts, t) ->
      let return_t = get_lltype t in
      let arg_t = List.map get_lltype ts |> Array.of_list in
      let ft = Llvm.function_type return_t arg_t in
      Llvm.declare_function name ft the_module
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
        (fun acc { name = name, named, uniq; abs } ->
          let name = if named then unique_name (name, uniq) else name in
          Vars.add name (declare_function name abs.params abs.body) acc)
        vars lst
    in
    List.fold_left
      (fun acc { name = name, named, uniq; abs } ->
        let name = if named then unique_name (name, uniq) else name in
        gen_function ~named acc name abs)
      vars lst
  in
  (* Reset lambda counter *)
  reset fun_get_state;
  (* Add main *)
  let linkage = Llvm.Linkage.External in
  ignore
  @@ gen_function funcs ~linkage ~named:false "main"
       { params = [ ("", TInt) ]; body = { typed_expr with typ = Typing.TInt } };

  (* Emit code to file *)
  Llvm_all_backends.initialize ();
  let open Llvm_target in
  let triple = Target.default_triple () in
  print_endline triple;
  let machine = TargetMachine.create ~triple (Target.by_triple triple) in
  TargetMachine.emit_to_file the_module CodeGenFileType.ObjectFile "out.o"
    machine
