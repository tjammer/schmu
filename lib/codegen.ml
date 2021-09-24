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

let genfun state =
  let n = !state in
  incr state;
  "__fun" ^ string_of_int n

let reset state = state := 0

type func = { name : string; abs : Typing.abstraction; named : bool }

let extract expr =
  let rec inner acc = function
    | Typing.Var _ | Int _ | Bool _ -> acc
    | Bop (_, e1, e2) -> inner (inner acc e1.expr) e2.expr
    | If (cond, e1, e2) ->
        let acc = inner acc cond.expr in
        let acc = inner acc e1.expr in
        inner acc e2.expr
    | Function (name, ((_, _, body) as abs), cont) ->
        let acc = inner acc body.expr in
        inner ({ name; abs; named = true } :: acc) cont.expr
    | Let (_, e1, e2) ->
        let acc = inner acc e1.expr in
        inner acc e2.expr
    | Lambda ((_, _, expr) as abs) ->
        let acc = inner acc expr.expr in
        { name = genfun fun_gen_state; abs; named = false } :: acc
    | App (e1, e2) ->
        let acc = inner acc e1.expr in
        inner acc e2.expr
  in
  inner [] expr |> List.rev

let rec get_lltype = function
  | Typing.TInt -> int_type
  | TBool -> bool_type
  | TVar { contents = Link t } -> get_lltype t
  | TUnit -> unit_type
  | (TVar _ | QVar _ | TFun _) as t ->
      failwith (Printf.sprintf "Wrong type TODO: %s" (Typing.string_of_type t))

let declare_function fun_name arg_type body =
  (* We only support one function arguments so far *)
  let return_t = get_lltype Typing.(body.typ) in
  let arg_t = Array.make 1 (get_lltype arg_type) in
  let ft = Llvm.function_type return_t arg_t in
  Llvm.declare_function fun_name ft the_module

let rec gen_function funcs fun_name ~named ?(linkage = Llvm.Linkage.Private)
    (arg_name, arg_type, body) =
  let func = declare_function fun_name arg_type body in
  Llvm.set_linkage linkage func;
  (* let vars = Vars.add id func vars in *)
  let param = (Llvm.params func).(0) in
  Llvm.set_value_name arg_name param;

  (* If the function is named, we allow recursion *)
  let temp_funcs = if named then Vars.add fun_name func funcs else funcs in

  (* gen function body *)
  let bb = Llvm.append_block context "entry" func in
  Llvm.position_at_end bb builder;
  (* TODO not all vars can be accessed here *)
  let ret = gen_expr (Vars.add arg_name param temp_funcs) body in

  (* we don't support closures yet *)

  (* Don't return a void type *)
  ignore
    (match Llvm.(type_of ret |> classify_type) with
    | Void -> Llvm.build_ret_void builder
    | _ -> Llvm.build_ret ret builder);
  Llvm_analysis.assert_valid_function func;
  Vars.add fun_name func funcs

and gen_expr vars typed_expr =
  match Typing.(typed_expr.expr) with
  | Typing.Int i -> Llvm.const_int int_type i
  | Bool b -> Llvm.const_int bool_type (Bool.to_int b)
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
  | Function (name, _, cont) ->
      (* The functions are already generated *)
      ignore (get_generated_func vars name);
      gen_expr vars cont
  | Let (id, equals_ty, let_ty) ->
      let expr_val = gen_expr vars equals_ty in
      gen_expr (Vars.add id expr_val vars) let_ty
  | Lambda _ -> get_generated_func vars (genfun fun_get_state)
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

and get_generated_func vars name =
  match Vars.find_opt name vars with
  | Some v -> v
  | None ->
      prerr_endline ("Could not find function : " ^ name);
      Vars.iter (fun key _ -> prerr_endline ("in: " ^ key)) vars;
      failwith "Internal error"

and gen_app vars callee arg =
  let callee = gen_expr vars callee in
  let arg = gen_expr vars arg in
  (* No names here, might be void/unit *)
  Llvm.build_call callee [| arg |] "" builder

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
  | Typing.TFun (t1, t2) ->
      let return_t = get_lltype t2 in
      let arg_t = Array.make 1 @@ get_lltype t1 in
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
        (fun acc { name; abs = _, arg_type, body; named = _ } ->
          Vars.add name (declare_function name arg_type body) acc)
        vars lst
    in
    List.fold_left
      (fun acc { name; abs; named } -> gen_function ~named acc name abs)
      vars lst
  in
  (* Reset lambda counter *)
  reset fun_get_state;
  (* Add main *)
  let linkage = Llvm.Linkage.External in
  ignore
  @@ gen_function funcs ~linkage ~named:false "main" ("", TInt, typed_expr);

  (* Emit code to file *)
  Llvm_all_backends.initialize ();
  let open Llvm_target in
  let triple = Target.default_triple () in
  print_endline triple;
  let machine = TargetMachine.create ~triple (Target.by_triple triple) in
  TargetMachine.emit_to_file the_module CodeGenFileType.ObjectFile "out.o"
    machine
