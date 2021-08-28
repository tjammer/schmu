type typ = TInt | TBool [@@deriving show { with_path = false }, eq]

exception Error of Ast.Loc.t * string

module Strmap = Map.Make (String)

module Context = struct
  type t = typ Strmap.t

  let empty = Strmap.empty

  let lookup = Strmap.find_opt

  let extend = Strmap.add
end

open Context

let rec typeof ctx = function
  | Ast.Var (loc, id) -> typeof_var ctx loc id
  | Int (_, _) -> TInt
  | Bool (_, _) -> TBool
  | Bop (loc, op, left, right) -> typeof_bop ctx loc op left right
  | If (loc, pred, thn, els) -> typeof_if ctx loc pred thn els
  | Let (_, id, expr, next) -> typeof_let ctx id expr next

and typeof_var ctx loc id =
  match lookup id ctx with
  | Some typ -> typ
  | None -> raise (Error (loc, "Could not find var " ^ id))

and typeof_bop ctx loc bop left right =
  let tl, tr = (typeof ctx left, typeof ctx right) in
  match (bop, tl, tr) with
  | Ast.Plus, TInt, TInt | Mult, TInt, TInt -> TInt
  | Less, TInt, TInt -> TBool
  | Equal, TInt, TInt -> TBool
  | _ -> raise (Error (loc, "Wrong types in binary op"))

and typeof_if ctx loc pred thn els =
  match typeof ctx pred with
  | TBool ->
      let thn, els = (typeof ctx thn, typeof ctx els) in
      if equal_typ thn els then thn
      else raise (Error (loc, "Branches in if expr must have same type"))
  | _ -> raise (Error (loc, "If predicate must evaluate to bool"))

and typeof_let ctx id expr next =
  let t = typeof ctx expr in
  let ctx = extend id t ctx in
  typeof ctx next

let typecheck expr = typeof empty expr
