(* Implements a borrow checker.
   We have to know the last usage for each binding. Instead of traversing once
   and using post processing, assume each binding is correct and unify
   binding-kind after the fact.*)

(* TODO handle projections / parts *)

module Usage = struct
  type t = Uread | Umut | Umove

  let of_mut b = if b then Umut else Uread
end

type borrow = { ord : int; loc : Ast.loc; borrowed : string }

and binding =
  | Bown of Ast.loc * string
  | Borrow of borrow
  | Borrow_mut of borrow
  | Bmove of borrow
[@@deriving show]

module Map = Map.Make (String)

let rec check_exclusivity borrow borrows =
  let p = Printf.sprintf in
  match (borrow, borrows) with
  (* TODO only check String.equal once *)
  | _, [] -> failwith "Internal Error: Should never be empty"
  | Bown _, _ -> ()
  | (Borrow b | Borrow_mut b | Bmove b), Bown (_, name) :: _
    when String.equal b.borrowed name ->
      ()
  | Borrow l, Borrow r :: tl when String.equal l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then () else check_exclusivity borrow tl
  | Borrow_mut l, Borrow_mut r :: tl when String.equal l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then ()
      else if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow" r.borrowed
            (fst l.loc).pos_lnum
        in
        raise (Typed_tree.Error (r.loc, msg))
      else check_exclusivity borrow tl
  | Borrow l, Borrow_mut r :: _ when String.equal l.borrowed r.borrowed ->
      (* TODO check if the cond is even meaningful here *)
      if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was borrowed in line %i, cannot mutate" r.borrowed
            (fst l.loc).pos_lnum
        in
        raise (Typed_tree.Error (r.loc, msg))
      else () (* failwith "Internal Error: Unexpected borrow order" *)
  | Borrow_mut l, Borrow r :: _ when String.equal l.borrowed r.borrowed ->
      if l.ord < r.ord then
        (* Mutable borrow still active while borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow" r.borrowed
            (fst l.loc).pos_lnum
        in
        raise (Typed_tree.Error (r.loc, msg))
      else () (* failwith "Internal Error: Unexpected mutable borrow order" *)
  | (Borrow b | Bmove b | Borrow_mut b), Bmove m :: _
    when String.equal b.borrowed m.borrowed ->
      (* Accessing a moved value *)
      let msg =
        p "%s was moved in line %i, cannot use" b.borrowed (fst m.loc).pos_lnum
      in
      raise (Typed_tree.Error (b.loc, msg))
  | Bmove m, (Borrow b | Borrow_mut b) :: _
    when String.equal m.borrowed b.borrowed ->
      (* The moving value was borrewed correctly before *)
      ()
  | _, _ :: tl -> check_exclusivity borrow tl

let borrow_state = ref 0

(* For now, throw everything into one list of bindings.
   In the future, each owning binding could have its own list *)

let mb_add v bs = match v with None -> bs | Some b -> b :: bs

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
            (* Assmue it's the only borrow. This works because if it isn't, a borrowed binding
               will be used later and thin fail the check. Extra care has to be taken for
               arguments to functions *)
            (* TODO, moved bindings won't be detected *)
            let b =
              match mut with
              | Usage.Uread -> Borrow borrow
              | Umut -> Borrow_mut borrow
              | Umove -> Bmove borrow
            in
            check_exclusivity b borrows;
            Some b
        | Some ((Borrow_mut _ | Borrow _) as b) ->
            check_exclusivity b borrows;
            Some b
        | Some (Bmove m) ->
            assert (String.equal m.borrowed id);
            let msg =
              Printf.sprintf "%s was moved in line %i, cannot borrow" id
                (fst m.loc).pos_lnum
            in
            raise (Typed_tree.Error (m.loc, msg))
        | None -> None
      in
      (* Don't add to borrows here. Other expressions where the value is used
         will take care of this *)
      (borrow, borrows)
  | Let { id; lhs; cont; _ } ->
      let mut = if lhs.attr.mut then Usage.Umove else Uread in
      let rval, bs =
        check_tree env (* Usage.(of_mut lhs.attr.mut) *) mut lhs borrows
      in
      let b, bs =
        match rval with
        | Some (Bmove _ as b) -> (Bown (tree.loc, id), b :: bs)
        | None ->
            (* No borrow, original, owned value *)
            (Bown (tree.loc, id), bs)
        | Some b -> (b, bs)
      in
      let env = Map.add id b env in
      check_tree env Uread cont (b :: bs)
  | Const (Array _) -> failwith "TODO"
  | Const _ -> (None, borrows)
  | Record fs ->
      (* TODO this currently only works for single field records, since we can
         only return one borrow. The correct way would probably be to use a list
         of borrows for each value *)
      let bs =
        List.fold_left
          (fun bs (_, field) ->
            let v, bs = check_tree env Umove field bs in
            mb_add v bs)
          borrows fs
      in
      (None, bs)
  | Field (tree, _) ->
      (* Currently, borrow the whole thing *)
      check_tree env mut tree borrows
  | Set (thing, value) ->
      let v, bs = check_tree env Uread value borrows in
      let bs = mb_add v bs in
      (* TODO do something with value here!
         Track usage of values, but not the one being mutated. Actually, might already be fine *)
      let thing, bs = check_tree env Umut thing bs in
      (thing, Option.get thing :: bs)
  | Sequence (fst, snd) ->
      let _, bs = check_tree env Uread fst borrows in
      check_tree env Uread snd bs
  | App { callee; args } ->
      (* The callee itself can be borrowed *)
      let _, bs = check_tree env Uread callee borrows in
      let bs =
        List.fold_left
          (fun bs (arg, mut) ->
            let v, bs = check_tree env (Usage.of_mut mut) arg bs in
            mb_add v bs)
          bs args
      in
      (* A function cannot return a borrowed value *)
      (None, bs)
  | Bop (_, fst, snd) ->
      let v, bs = check_tree env Uread fst borrows in
      let v, bs = check_tree env Uread snd (mb_add v bs) in
      (None, mb_add v bs)
  | _ -> failwith "TODO"
