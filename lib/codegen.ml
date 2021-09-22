let context = Llvm.global_context ()

let the_module = Llvm.create_module context "context"

let builder = Llvm.builder context

let int_type = Llvm.i32_type context

let bool_type = Llvm.i1_type context

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

let extract expr =
  let rec inner acc = function
    | Typing.Var _ | Int _ | Bool _ -> acc
    | Bop (_, e1, e2) -> inner (inner acc e1.expr) e2.expr
    | If (cond, e1, e2) ->
        let acc = inner acc cond.expr in
        let acc = inner acc e1.expr in
        inner acc e2.expr
    | Let (id, { typ = _; expr = Abs ((_, _, body) as abs) }, e2) ->
        let acc = inner acc body.expr in
        inner ((id, abs) :: acc) e2.expr
    | Let (_, e1, e2) ->
        let acc = inner acc e1.expr in
        inner acc e2.expr
    | Abs ((_, _, expr) as abs) ->
        let acc = inner acc expr.expr in
        (genfun fun_gen_state, abs) :: acc
    | App (e1, e2) ->
        let acc = inner acc e1.expr in
        inner acc e2.expr
  in
  inner [] expr |> List.rev

let rec get_lltype = function
  | Typing.TInt -> int_type
  | TBool -> bool_type
  | TVar { contents = Link t } -> get_lltype t
  | t ->
      failwith (Printf.sprintf "Wrong type TODO: %s" (Typing.string_of_type t))

let rec gen_function funcs fun_name (arg_name, arg_type, body) =
  (* We only support one function arguments so far *)
  let return_t = get_lltype Typing.(body.typ) in
  let arg_t = Array.make 1 (get_lltype arg_type) in
  let ft = Llvm.function_type return_t arg_t in
  let func = Llvm.declare_function fun_name ft the_module in
  (* let vars = Vars.add id func vars in *)
  let param = (Llvm.params func).(0) in
  Llvm.set_value_name arg_name param;

  (* gen function body *)
  let bb = Llvm.append_block context "entry" func in
  Llvm.position_at_end bb builder;
  (* TODO not all vars can be accessed here *)
  let ret = gen_expr (Vars.add arg_name param funcs) body in
  (* we don't support closures yet *)
  ignore (Llvm.build_ret ret builder);
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
  | Var id -> Vars.find id vars
  (* If the variable isn't bound, something went wrong before *)
  | Let (id, { typ = _; expr = Abs _ }, let_ty) ->
      (* The functions are already generated *)
      ignore (get_generated_func vars id);
      gen_expr vars let_ty
  | Let (id, equals_ty, let_ty) ->
      let expr_val = gen_expr vars equals_ty in
      gen_expr (Vars.add id expr_val vars) let_ty
  | Abs _ -> get_generated_func vars (genfun fun_get_state)
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
  Llvm.build_call callee [| arg |] "calltmp" builder

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

let generate typed_expr =
  let open Typing in
  let funcs =
    extract typed_expr.expr
    |> List.fold_left
         (fun acc (name, abs) -> gen_function acc name abs)
         Vars.empty
  in
  (* Reset lambda counter *)
  reset fun_get_state;
  (* Add main *)
  gen_function funcs "main" ("", typed_expr.typ, typed_expr)
