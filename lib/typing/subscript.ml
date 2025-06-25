open Types
open Typed_tree

let typ_of_one_param_fun t =
  match repr t with
  | Tfun ([ p ], ret, _) when is_unit ret -> Some p.pt
  | _ -> None

let prefix = "__pre-"

let get_callee env loc callee =
  (* Precondition: length params - length args == 1 *)
  (* A call is eligible for a subscript if 1. the last parameter is a function
     2. that function is once 3. the function only has one paramer, 4. the
     return type of the callee is unit and 5. the callee expression is just a
     variable. Otherwise we can't substitute the correct functions. *)
  match repr callee.typ with
  | Tfun (ps, ret, kind) -> (
      match List.rev ps with
      | last :: tl ->
          if !(last.pmode) = Iknown Once && is_unit ret then
            (* The callee has te be a simple Var expression, for substitution *)
            match (typ_of_one_param_fun last.pt, callee.expr) with
            | Some ret, Var (name, modul) ->
                (* A Var expression is not enough, we have to know it's
                   real callname. It can't work with a passed higher order
                   function *)
                (match
                   Option.map
                     (fun modul -> Env.find_callname loc name modul env)
                     modul
                 with
                | Some _ -> ()
                | None ->
                    (* This is a subscript in everything but callname. Raise a
                       subscript-specific error. *)
                    raise
                      (Error.Error (loc, "Cannot find call name for subscript")));
                (* This is a subscript. Substitute the correct name *)
                (* TODO check mut attribute *)
                let typ = Tfun (List.rev tl, ret, kind) in
                { callee with expr = Var (prefix ^ name, modul); typ }
            | _ -> callee
          else callee
      | _ -> callee)
  | _ -> callee

let is_borrow_call = function
  | Var (n, _) -> String.starts_with ~prefix n
  | _ -> false
