open Types
open Typed_tree
open Inference

let typ_of_one_param_fun t =
  match repr t with
  | Tfun ([ p ], _, _) -> Some p.pt
  | Tfun ([], _, _) -> Some tunit
  | _ -> None

let is_borrow_callable callee =
  (* Precondition: length params - length args == 1 *)
  (* A call is eligible for a subscript if 1. the last parameter is a function
     2. that function is once 3. the function only has one paramer and 4. the
     callee expression is just a variable. Otherwise we can't substitute the
     correct functions. *)
  match repr callee.typ with
  | Tfun (ps, return, kind) as orig_callee -> (
      match List.rev ps with
      | last :: tl -> (
          match typ_of_one_param_fun last.pt with
          | Some bind_param ->
              (* A Var expression is not enough, we have to know it's
                 real callname. It can't work with a passed higher order
                 function *)
              (* TODO check mut attribute *)
              let tmp_fun = Tfun (List.rev tl, bind_param, kind) in
              let tmp_callee = { callee with typ = tmp_fun } in
              let fn_param = List.rev ps |> List.hd in
              Some ({ bind_param; return; fn_param; orig_callee }, tmp_callee)
          | _ -> None)
      | _ -> None)
  | _ -> None

let make_lambda env loc (decl : Ast.decl) typ pattern_id add_param convert_decl
    make_cont post_lambda =
  (* TODO mode and qparam *)
  let env = Env.open_function env in
  enter_level ();

  (* add 'param' to env *)
  let id, idloc, _, pattr = pattern_id 0 decl.pattern in
  let body_env = add_param env id idloc typ pattr in
  let body_env, param_exprs = convert_decl body_env [ decl ] in

  let body = make_cont body_env in

  let params_t = [ { pt = typ; pattr; pmode = ref (Iknown Many) } ]
  and nparams = [ id ] in
  post_lambda env loc body param_exprs params_t nparams [ decl ] [] None
    params_t None
