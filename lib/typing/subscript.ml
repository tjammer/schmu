open Types
open Typed_tree

let typ_of_one_param_fun t =
  match repr t with
  | Tfun ([ p ], ret, _) when is_unit ret -> Some p.pt
  | _ -> None

let get_callee callee =
  (* Precondition: length params - length args == 1 *)
  (* A call is eligible for a subscript if 1. the last parameter is a
     function 2. that function is once 3. the function only has one
     paramer, 4. the return type of the callee is unit and 5. the
     callee expression is just a variable. Otherwise we can't
     substitute the correct functions. *)
  match repr callee.typ with
  | Tfun (ps, ret, kind) -> (
      match List.rev ps with
      | last :: tl ->
          if !(last.pmode) = Iknown Once && is_unit ret then
            (* The callee has te be a simple Var expression, for substitution *)
            match (typ_of_one_param_fun last.pt, callee.expr) with
            | Some ret, Var (name, modul) ->
                (* This is a subscript. Substitute the correct name *)
                (* TODO check mut attribute *)
                let typ = Tfun (List.rev tl, ret, kind) in
                { callee with expr = Var ("__pre-" ^ name, modul); typ }
            | _ -> callee
          else callee
      | _ -> callee)
  | _ -> callee
