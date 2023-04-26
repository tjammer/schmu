(* Implements a borrow checker.
   We have to know the last usage for each binding. Instead of traversing once
   and using post processing, assume each binding is correct and unify
   binding-kind after the fact.*)

(* TODO handle projections / parts *)

type borrow = { ord : int; loc : Ast.loc; borrowed : string }

and binding_kind =
  | Bown of Ast.loc * string
  | Borrow of borrow
  | Borrow_mut of borrow
[@@deriving show]

module Map = Map.Make (String)

let rec check_exclusivity borrow borrows =
  let p = Printf.sprintf in
  match (borrow, borrows) with
  | _, [] -> failwith "Internal Error: Should never be empty"
  | Bown _, _ -> ()
  | (Borrow b | Borrow_mut b), Bown (_, name) :: _
    when String.equal b.borrowed name ->
      ()
  | Borrow l, Borrow r :: tl when String.equal l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then () else check_exclusivity borrow tl
  | Borrow_mut l, Borrow_mut r :: tl when String.equal l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then () else check_exclusivity borrow tl
  | Borrow l, Borrow_mut r :: _ when String.equal l.borrowed r.borrowed ->
      (* TODO check if the cond is even meaningful here *)
      if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was borrowed in line %i, cannot be mutated" r.borrowed
            (fst l.loc).pos_lnum
        in
        raise (Typed_tree.Error (r.loc, msg))
      else failwith "Internal Error: Unexpected borrow order"
  | Borrow_mut l, (Borrow r | Borrow_mut r) :: _
    when String.equal l.borrowed r.borrowed ->
      if l.ord < r.ord then
        (* Mutable borrow still active while borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot be borrowed" r.borrowed
            (fst l.loc).pos_lnum
        in
        raise (Typed_tree.Error (r.loc, msg))
      else failwith "Internal Error: Unexpected mutable borrom order"
  | _, _ :: tl -> check_exclusivity borrow tl

let borrow_state = ref 0

(* For now, throw everything into one list of bindings.
   In the future, each owning binding could have its own list *)

let rec check_tree env mut tree borrows =
  match Typed_tree.(tree.expr) with
  | Typed_tree.Var id ->
      (* This is no rvalue, we borrow *)
      let borrow =
        match Map.find_opt id env with
        | Some (Bown _) ->
            incr borrow_state;
            let borrow =
              { ord = !borrow_state; loc = tree.loc; borrowed = id }
            in
            (* Assmue it's the only borrow. This works because if it isn't a borrowed binding
               will be used later and thin fail the check. Extra care has to be taken for
               arguments to functions *)
            if mut then Some (Borrow_mut borrow) else Some (Borrow borrow)
        | Some ((Borrow_mut _ | Borrow _) as b) ->
            check_exclusivity b borrows;
            Some b
        | None -> None
      in
      (* Don't add to borrows here. Other expressions where the value is used
         will take care of this *)
      (borrow, borrows)
  | Let { id; lhs; cont; _ } ->
      let rval, bs = check_tree env lhs.attr.mut lhs borrows in
      let b =
        match rval with
        | None ->
            (* No borrow, original, owned value *)
            Bown (tree.loc, id)
        | Some b -> b
      in
      let env = Map.add id b env in
      check_tree env false cont (b :: bs)
  | Const (Array _) -> failwith "TODO"
  | Const _ -> (None, borrows)
  | Record fs -> (
      (* TODO this currently only works for single field records, since we can
         only return one borrow. The correct way would probably be to use a list
         of borrows for each value *)
      match fs with
      | (_, f) :: [] -> check_tree env (mut && f.attr.mut) f borrows
      | _ -> failwith "TODO record fields")
  | Field (tree, _) ->
      (* Currently, borrow the whole thing *)
      check_tree env mut tree borrows
  | Set (thing, value) ->
      let _, bs = check_tree env false value borrows in
      (* TODO do something with value here! *)
      let thing, bs = check_tree env true thing bs in
      (thing, Option.get thing :: bs)
  | Sequence (fst, snd) ->
      let _, bs = check_tree env false fst borrows in
      check_tree env false snd bs
  | App { callee; args } ->
      (* The callee itself can be borrowed *)
      let _, bs = check_tree env false callee borrows in
      let bs =
        List.fold_left
          (fun bs (arg, mut) ->
            let v, bs = check_tree env mut arg bs in
            match v with None -> bs | Some b -> b :: bs)
          bs args
      in
      (* A function cannot return a borrowed value *)
      (None, bs)
  | _ -> failwith "TODO"

(* Returns whether the expr is an rvalue *)
(* let rec check_tree env mut tree = *)
(*   match Typed_tree.(tree.expr) with *)
(*   | Typed_tree.Var id -> *)
(*       (\* This is no rvalue, we borrow *\) *)
(*       let next = if mut then Borrow_mut else Borrow in *)
(*       let uniq = Map.find id env in *)
(*       check_exclusivity id (Hashtbl.find bindings uniq) ~next; *)
(*       print_endline ("Change " ^ id ^ " to " ^ show_binding_kind next); *)
(*       Hashtbl.add bindings uniq (next, tree.loc, id); *)
(*       false *)
(*   | Let { id; uniq; lhs; cont; _ } -> *)
(*       let rval = check_tree env lhs.attr.mut lhs in *)
(*       let binding = *)
(*         match (lhs.attr.mut, rval) with *)
(*         | _, true -> Bown *)
(*         | true, false -> Borrow_mut *)
(*         | false, false -> Borrow *)
(*       in *)
(*       let uniq = Module.unique_name ~mname:None id uniq in *)
(*       Hashtbl.add bindings uniq (binding, tree.loc, id); *)
(*       print_endline ("Introduce " ^ id ^ " as " ^ show_binding_kind binding); *)
(*       check_tree (Map.add id uniq env) cont.attr.mut cont *)
(*   | Const (Array _) -> false *)
(*   | Const _ -> true *)
(*   | Record fs -> *)
(*       List.fold_left *)
(*         (fun rvalue (_, tree) -> *)
(*           rvalue && check_tree env Typed_tree.(tree.attr.mut) tree) *)
(*         true fs *)
(*   | Field (tree, _) -> *)
(*       ignore (check_tree env mut tree); *)
(*       false *)
(*   | Set (thing, value) -> *)
(*       ignore (check_tree env mut value); *)
(*       ignore (check_tree env true thing); *)
(*       false *)
(*   | Sequence (fst, snd) -> *)
(*       ignore (check_tree env fst.attr.mut fst); *)
(*       check_tree env mut snd *)
(*   | App { callee; args } -> *)
(*       ignore (check_tree env callee.attr.mut callee); *)
(*       List.fold_left *)
(*   | _ -> false *)
