open Types
open Typed_tree

let typ_of_one_param_fun t =
  match repr t with Tfun ([ p ], return, _) -> Some (p.pt, return) | _ -> None

let is_borrow_callable env loc callee =
  (* Precondition: length params - length args == 1 *)
  (* A call is eligible for a subscript if 1. the last parameter is a function
     2. that function is once 3. the function only has one paramer and 4. the
     callee expression is just a variable. Otherwise we can't substitute the
     correct functions. *)
  match repr callee.typ with
  | Tfun (ps, ret, kind) -> (
      match List.rev ps with
      | last :: tl ->
          if !(last.pmode) = Iknown Once && is_unit ret then
            (* The callee has te be a simple Var expression, for substitution *)
            match (typ_of_one_param_fun last.pt, callee.expr) with
            | Some (bind_param, return), Var (name, modul) ->
                (* A Var expression is not enough, we have to know it's
                   real callname. It can't work with a passed higher order
                   function *)
                (match
                   Option.bind modul (fun modul ->
                       Env.find_callname loc name modul env)
                 with
                | Some _ -> ()
                | None ->
                    (* This is a subscript in everything but callname. Raise a
                       subscript-specific error. *)
                    raise
                      (Error.Error (loc, "Cannot find call name for subscript")));
                (* This is a subscript. Substitute the correct name *)
                (* TODO check mut attribute *)
                let tmp_fun = Tfun (List.rev tl, bind_param, kind) in
                let tmp_callee = { callee with typ = tmp_fun } in
                Some
                  ({ bind_param; return; orig_callee = callee.typ }, tmp_callee)
            | _ -> None
          else None
      | _ -> None)
  | _ -> None

let is_borrow_call = function Ast.App_borrow _ -> true | _ -> false
