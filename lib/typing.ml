type typ = TInt | TBool | TFun of typ * typ | TVar of string [@@deriving show { with_path = false }]

exception Error of Ast.loc * string

module Strmap = Map.Make (String)

module Strset = Set.Make (String)

type scheme = Strset.t * typ

module Varname = struct
  let state = ref 0

  let new_var () =
    let i = !state in
    incr state;
    TVar (string_of_int i)

  let reset () = state := 0
end



let rec subst_typ subst = function
  | TVar id -> (match Strmap.find_opt id subst with
      | None -> TVar id
      | Some typ -> typ  )
  | TFun (t1, t2) -> TFun (subst_typ subst t1, subst_typ subst t2)
  | typ -> typ

let subst_scheme subst (set, typ) = set, subst_typ (Strset.fold (Strmap.remove) set subst) typ


module Subst = struct
  type t = typ Strmap.t

  let empty = Strmap.empty

  let compose s1 s2 =
    Strmap.map (subst_typ s2) s1 |> Strmap.union ( fun _ typ _ -> Some typ ) s2
end

let rec free_type_var_typ = function
  | TVar id -> Strset.singleton id
  | TInt | TBool -> Strset.empty
  | TFun (t1, t2) ->  Strset.union (free_type_var_typ t1) (free_type_var_typ t2)

let free_type_var_scheme (set, typ) = Strset.diff (free_type_var_typ typ) set

module Context = struct
  type t = scheme Strmap.t

  let empty = Strmap.empty

  let lookup : string -> t -> scheme option = Strmap.find_opt

  let extend : string -> scheme -> t -> t = Strmap.add

  let free_type_var c =
    Strmap.fold (fun _ scheme acc -> Strset.union acc @@ free_type_var_scheme scheme)  c
    Strset.empty

  let generalize c typ =
    Strset.diff (free_type_var_typ typ) (free_type_var c), typ

      let subst c subst = Strmap.map (fun scheme -> subst_scheme subst scheme) c
end

let instantiate ((set, typ) : scheme) =
  let rec zip a b () =
    let open Seq in
    match a(), b() with
    | Nil, Nil -> Nil
  | Nil, _
  | _, Nil -> failwith "Internal error: Not same length"
  | Cons (x, a'), Cons (y, b') -> Cons ((x,y), zip a' b') in

  let nset = Strset.to_seq set |> Seq.map (fun _ -> Varname.new_var ())  in
  (* print_endline @@ "vars: " ^ String.concat ", " (Strset.to_seq set |> List.of_seq) ;
   * print_endline @@ "nvars: " ^ String.concat ", " ( List.of_seq nset |> List.map show_typ) ; *)
  zip (Strset.to_seq set) nset |> Strmap.of_seq |> fun map -> subst_typ map typ

let bind id = function
  | TVar id' when String.equal id id' -> Subst.empty
  | typ when Strset.mem id (free_type_var_typ typ) -> failwith (Printf.sprintf "Internal error: occur check failed: %s vs %s"
                                                                  id (show_typ typ))
  | typ -> Strmap.singleton id typ


let rec unify t1 t2 =
  match t1, t2 with
  | TFun (l, r), TFun (l', r') -> let s1 = unify l l' in let s2 = unify (subst_typ s1 r) (subst_typ s1 r') in
    Subst.compose s1 s2
  | TVar id, t | t, TVar id -> bind id t
  | TInt, TInt | TBool, TBool -> Subst.empty
  | t, t' -> failwith (Format.sprintf "Internal error: Types do not unify %s vs %s" (show_typ t) (show_typ t'))


(* let rec infer expr ctx =
 *   match expr with
 *   |  *)

(* old without inference *)
open Context

let rec typeof ctx = function
  | Ast.Var (loc, id) -> typeof_var ctx loc id
  | Int (_, _) -> Subst.empty,  TInt
  | Bool (_, _) -> Subst.empty, TBool
  (* | Bop (loc, op, left, right) -> typeof_bop ctx loc op left right *)
  (* | If (loc, pred, thn, els) -> typeof_if ctx loc pred thn els *)
  | Let (_, id, expr, next) -> typeof_let ctx id expr next
  | App (_, func, expr) -> typeof_app ctx func expr
  | Abs (_, id, expr) -> typeof_abs ctx id expr
  | _ -> failwith "TODO"

and typeof_var ctx loc id =
  match lookup id ctx with
  | Some scheme -> Subst.empty, instantiate scheme
  | None -> raise (Error (loc, "Could not find var " ^ id))

(* and typeof_bop ctx loc bop left right =
 *   let tl, tr = (typeof ctx left, typeof ctx right) in
 *   match (bop, tl, tr) with
 *   | Ast.Plus, TInt, TInt | Mult, TInt, TInt -> TInt
 *   | Less, TInt, TInt -> TBool
 *   | Equal, TInt, TInt -> TBool
 *   | _ -> raise (Error (loc, "Wrong types in binary op"))
 *
 * and typeof_if ctx loc pred thn els =
 *   match typeof ctx pred with
 *   | TBool ->
 *       let thn, els = (typeof ctx thn, typeof ctx els) in
 *       if equal_typ thn els then thn
 *       else raise (Error (loc, "Branches in if expr must have same type"))
 *   | _ -> raise (Error (loc, "If predicate must evaluate to bool")) *)

and typeof_let ctx id expr next =
  let s1, t1 = typeof ctx expr in
  let ctx1 = Strmap.remove id ctx in (* why? *)
  let t' = generalize (Context.subst ctx1 s1) t1 in (* or ctx1? *)
  let ctx2 = Context.extend id t' ctx1 in
  let s2, t2 = typeof (Context.subst ctx2 s1) next in
    Subst.compose s1 s2, t2
  (* let t = typeof ctx expr in
   * let ctx = extend id t ctx in
   * typeof ctx next *)

and typeof_app ctx  func expr =
  let tv = Varname.new_var () in
  let s1, t1 = typeof ctx func in
  let s2, t2 = typeof (Context.subst ctx s1) expr in
  let s3 = unify (subst_typ s2 t1) (TFun (t2, tv)) in
  Subst.(compose s3 (compose s2 s1)), subst_typ s3 tv

and typeof_abs ctx id expr =
  let tv = Varname.new_var () in
  let ctx1 = Strmap.remove id ctx in
  let ctx2 = Strmap.add  id (Strset.empty, tv) ctx1 in (* union seems strange *)
  let s1, t1 =  typeof ctx2 expr in
  s1, TFun ((subst_typ  s1 tv), t1)


(* let typecheck expr = typeof empty expr *)

let typecheck expr =
  Varname.reset () ;
  let s, typ = typeof empty expr in
  subst_typ s typ
