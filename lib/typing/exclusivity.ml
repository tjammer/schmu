(* Implements a borrow checker.
   We have to know the last usage for each binding. Instead of traversing once
   and using post processing, assume each binding is correct and unify
   binding-kind after the fact.*)

(* TODO handle projections / parts *)

module Usage = struct
  type t = Uread | Umut | Umove [@@deriving show]

  let of_mut b = if b then Umut else Uread
end

type borrow = { ord : int; loc : Ast.loc; borrowed : string }

and binding =
  | Bown of string
  | Borrow of borrow
  | Borrow_mut of borrow
  | Bmove of borrow
  | Bmulti of binding * binding
[@@deriving show]

let rec is_borrow = function
  | Bown _ | Bmove _ -> false
  | Borrow _ | Borrow_mut _ -> true
  | Bmulti (a, b) -> is_borrow a && is_borrow b

module Map = Map.Make (String)

let rec check_exclusivity loc borrow borrows =
  let p = Printf.sprintf in
  match (borrow, borrows) with
  (* TODO only check String.equal once *)
  | _, [] -> failwith "Internal Error: Should never be empty"
  | Bown _, _ -> ()
  | Bmulti (a, b), _ ->
      check_exclusivity loc a borrows;
      check_exclusivity loc b borrows
  | _, Bmulti (a, b) :: tl ->
      check_exclusivity loc borrow (a :: tl);
      check_exclusivity loc borrow (b :: tl)
  | (Borrow b | Borrow_mut b | Bmove b), Bown name :: _
    when String.equal b.borrowed name ->
      ()
  | Borrow l, Borrow r :: tl when String.equal l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then () else check_exclusivity loc borrow tl
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
      else check_exclusivity loc borrow tl
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
      raise (Typed_tree.Error (loc, msg))
  | Bmove m, (Borrow b | Borrow_mut b) :: _
    when String.equal m.borrowed b.borrowed ->
      (* The moving value was borrowed correctly before *)
      ()
  | _, _ :: tl -> check_exclusivity loc borrow tl

let borrow_state = ref 0

(* For now, throw everything into one list of bindings.
   In the future, each owning binding could have its own list *)

let mb_add v bs = match v with None -> bs | Some b -> b :: bs

let rec new_elems nu keep old =
  match (nu, old) with
  | _, [] -> nu
  | a :: _, b :: _ when a == b -> List.rev keep
  | a :: tl, [ _ ] -> new_elems tl (a :: keep) old
  | _ -> failwith "Internal Error: Impossible"

let rec check_excl_chain loc env borrow borrows =
  match borrow with
  | Bown _ -> ()
  | Borrow b | Borrow_mut b | Bmove b -> (
      check_exclusivity loc borrow borrows;
      match Map.find_opt b.borrowed env with
      | Some b -> check_excl_chain loc env b borrows
      | None -> ())
  | Bmulti (a, b) ->
      check_excl_chain loc env a borrows;
      check_excl_chain loc env b borrows

let rec check_tree env mut tree borrows =
  match Typed_tree.(tree.expr) with
  | Typed_tree.Var borrowed ->
      (* This is no rvalue, we borrow *)
      let loc = tree.loc in
      let rec borrow = function
        | Bown _ ->
            incr borrow_state;
            let borrow = { ord = !borrow_state; loc; borrowed } in
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
            check_excl_chain loc env b borrows;
            b
        | Borrow_mut b' as b -> (
            match mut with
            | Usage.Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b borrows;
                Bmove { b' with loc }
            | Umut | Uread ->
                check_excl_chain loc env b borrows;
                incr borrow_state;
                Borrow_mut { loc; ord = !borrow_state; borrowed })
        | Borrow b' as b -> (
            match mut with
            | Usage.Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b borrows;
                Bmove { b' with loc }
            | Umut ->
                check_excl_chain loc env (Borrow_mut b') borrows;
                incr borrow_state;
                Borrow_mut { loc; ord = !borrow_state; borrowed }
            | Uread ->
                check_excl_chain loc env b borrows;
                incr borrow_state;
                Borrow { loc; ord = !borrow_state; borrowed })
        | Bmove m ->
            assert (String.equal m.borrowed borrowed);
            let msg =
              Printf.sprintf "%s was moved in line %i, cannot borrow" borrowed
                (fst m.loc).pos_lnum
            in
            raise (Typed_tree.Error (m.loc, msg))
        | Bmulti (a, b) -> Bmulti (borrow a, borrow b)
      in
      let borrow =
        match Map.find_opt borrowed env with
        | Some b -> Some (borrow b)
        | None -> None
      in
      (* Don't add to borrows here. Other expressions where the value is used
         will take care of this *)
      (borrow, borrows)
  | Let { id; lhs; cont; mutly; rmut; _ } ->
      let nmut =
        match (lhs.attr.mut, mutly) with
        | true, true when not rmut ->
            raise
              (Typed_tree.Error (lhs.loc, "Cannot project unmutable binding"))
        | true, true -> Usage.Umut
        | true, false -> Umove
        | false, false -> Uread
        | false, true -> failwith "unreachable"
      in
      let rval, bs = check_tree env nmut lhs borrows in
      let loc = tree.loc in
      let neword () =
        incr borrow_state;
        !borrow_state
      in
      let rec borrow bs = function
        | Bmove _ as b -> (Bown id, b :: bs)
        | Bmulti (a, b) ->
            (* Switch order so that first move appears near the head of borrow list.
               This way, the first move is reported first (if both move the same thing) *)
            let b, bs = borrow bs b in
            let a, bs = borrow bs a in
            (Bmulti (a, b), bs)
        | Borrow b -> (Borrow { b with loc; ord = neword () }, bs)
        | Borrow_mut b -> (Borrow_mut { b with loc; ord = neword () }, bs)
        | Bown _ -> failwith "Internal Error: A borrowed thing isn't owned"
      in
      let b, bs =
        match rval with
        | None ->
            (* No borrow, original, owned value *)
            (Bown id, bs)
        | Some b -> borrow bs b
      in
      let env = Map.add id b env in
      check_tree env mut cont (b :: bs)
  | Const (Array es) ->
      let bs =
        List.fold_left
          (fun bs e ->
            let v, bs = check_tree env Umove e bs in
            mb_add v bs)
          borrows es
      in
      (None, bs)
  | Const _ -> (None, borrows)
  | Record fs ->
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
      check_tree env mut snd bs
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
  | If (cond, a, b) ->
      let v, bs = check_tree env Uread cond borrows in
      let bs = mb_add v bs in
      let a, abs = check_tree env mut a bs in
      let b, bbs = check_tree env mut b bs in
      (* Make sure borrow kind of both branches matches *)
      let _raise msg = raise (Typed_tree.Error (tree.loc, msg)) in
      let v =
        match (a, b) with
        (* Ignore Bown _ cases, as it can't be returned. Would be borrowed *)
        (* Owning *)
        | None, None -> None
        | None, Some b when is_borrow b ->
            _raise "Branches have different ownership: owned vs borrowed"
        | Some b, None when is_borrow b ->
            _raise "Branches have different ownership: borrowed vs owned"
        | None, a | a, None -> a
        (* If both branches are (Some _), they have to be both the same kind,
           because it was applied in Var.. above*)
        | Some a, Some b ->
            assert (is_borrow a == is_borrow b);
            Some (Bmulti (a, b))
      in
      let abs = new_elems abs [] bs in
      let bbs = new_elems bbs [] bs in
      (* TODO mutable borrows on both branches trigger an error. But only when mutable,
         which we don't have in the grammar right nom *)
      (v, abs @ bbs @ bs)
  | _ -> failwith "TODO"
