(* Implements a borrow checker.
   We have to know the last usage for each binding. Instead of traversing once
   and using post processing, assume each binding is correct and unify
   binding-kind after the fact.*)

module Usage = struct
  type t = Uread | Umut | Umove | Uset [@@deriving show]
  type set = Set | Dont_set [@@deriving show]

  let of_attr = function Ast.Dnorm -> Uread | Dmut -> Umut | Dmove -> Umove
end

module Id = struct
  type t = Fst of string | Shadowed of string * int [@@deriving show]

  let compare a b =
    match (a, b) with
    | Fst a, Fst b -> String.compare a b
    | Shadowed (a, ai), Shadowed (b, bi) ->
        let c = String.compare a b in
        if c == 0 then Int.compare ai bi else c
    | Fst a, Shadowed (b, bi) | Shadowed (b, bi), Fst a ->
        let c = String.compare a b in
        if c == 0 then bi else c

  let equal a b =
    match (a, b) with
    | Fst a, Fst b -> String.equal a b
    | Shadowed (a, ai), Shadowed (b, bi) ->
        let c = String.equal a b in
        if c then Int.equal ai bi else c
    | Fst _, Shadowed _ | Shadowed _, Fst _ -> false

  let is_string s =
    match fst s with
    | Fst s | Shadowed (s, _) -> String.starts_with ~prefix:"__string" s

  let s (s, part) =
    let name = match s with Fst s -> s | Shadowed (s, _) -> s in
    match part with
    | [] -> name
    | l -> name ^ "." ^ String.concat "." (List.map snd l)
end

type borrow = { ord : int; loc : Ast.loc; borrowed : Id.t * part_access }

and binding =
  | Bown of Id.t
  | Borrow of borrow
  | Borrow_mut of borrow * Usage.set
  | Bmove of borrow
  | Bmulti of binding * binding

and part_access = (int * string) list [@@deriving show]

let id_matches a wth =
  let rec parts_match = function
    | (i, _) :: tl, (j, _) :: tr ->
        if Int.equal i j then parts_match (tl, tr)
        else (* Borrows concern different parts *) false
    | [], _ -> true
    | _, [] -> (* Borrows are not mutually exclusive *) false
  in
  if not (Id.equal (fst a) (fst wth)) then false
  else parts_match (snd a, snd wth)

let rec is_borrow = function
  | Bown _ | Bmove _ -> false
  | Borrow _ | Borrow_mut _ -> true
  | Bmulti (a, b) -> is_borrow a && is_borrow b

type bopt = binding option [@@deriving show]

module Map = Map.Make (Id)

let borrow_state = ref 0
let param_pass = ref false
let shadow_tbl = Hashtbl.create 64

let new_id str =
  match Hashtbl.find_opt shadow_tbl str with
  | Some i ->
      Hashtbl.replace shadow_tbl str (i + 1);
      Id.Shadowed (str, i)
  | None ->
      Hashtbl.replace shadow_tbl str 1;
      Id.Fst str

let get_id str =
  match Hashtbl.find_opt shadow_tbl str with
  | None | Some 1 -> Id.Fst str
  | Some i -> Id.Shadowed (str, i - 1)

let reset () =
  borrow_state := 0;
  param_pass := false;
  Hashtbl.clear shadow_tbl

let rec check_exclusivity loc borrow borrows =
  let p = Printf.sprintf in
  match (borrow, borrows) with
  (* TODO only check String.equal once *)
  | _, [] ->
      print_endline (show_binding borrow);
      failwith "Internal Error: Should never be empty"
  | Bown _, _ -> ()
  | (Borrow b | Borrow_mut (b, _) | Bmove b), _ when Id.is_string b.borrowed ->
      (* Strings literals can always be borrowed. For now also moved *)
      ()
  | Bmulti (a, b), _ ->
      check_exclusivity loc a borrows;
      check_exclusivity loc b borrows
  | _, Bmulti (a, b) :: tl ->
      check_exclusivity loc borrow (a :: tl);
      check_exclusivity loc borrow (b :: tl)
  | (Borrow b | Borrow_mut (b, _) | Bmove b), Bown name :: _
    when Id.equal (fst b.borrowed) name ->
      ()
  | Borrow l, Borrow r :: tl when id_matches l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then () else check_exclusivity loc borrow tl
  | Borrow_mut (l, _), Borrow_mut (r, _) :: tl
    when id_matches l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then ()
      else if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow"
            (Id.s r.borrowed) (fst l.loc).pos_lnum
        in
        raise (Typed_tree.Error (r.loc, msg))
      else check_exclusivity loc borrow tl
  | Borrow l, Borrow_mut (r, _) :: _ when id_matches l.borrowed r.borrowed ->
      if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was borrowed in line %i, cannot mutate" (Id.s r.borrowed)
            (fst l.loc).pos_lnum
        in
        raise (Typed_tree.Error (r.loc, msg))
      else ()
  | Borrow_mut (l, _), Borrow r :: _ when id_matches l.borrowed r.borrowed ->
      if l.ord < r.ord then
        (* Mutable borrow still active while borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow"
            (Id.s r.borrowed) (fst l.loc).pos_lnum
        in
        raise (Typed_tree.Error (r.loc, msg))
      else ()
  | (Borrow b | Bmove b | Borrow_mut (b, Dont_set)), Bmove m :: _
  (* Allow mutable borrow for setting new values *)
    when id_matches b.borrowed m.borrowed ->
      (* Accessing a moved value *)
      let loc, msg =
        if not !param_pass then
          ( loc,
            p "%s was moved in line %i, cannot use" (Id.s m.borrowed)
              (fst m.loc).pos_lnum )
        else (m.loc, p "Borrowed parameter %s is moved" (Id.s b.borrowed))
      in
      raise (Typed_tree.Error (loc, msg))
  | Bmove m, (Borrow b | Borrow_mut (b, _)) :: _
    when id_matches m.borrowed b.borrowed ->
      (* The moving value was borrowed correctly before *)
      ()
  | _, _ :: tl -> check_exclusivity loc borrow tl

let string_lit_borrow loc mut =
  let borrowed = (new_id "__string", []) in
  match mut with
  | Usage.Uread ->
      incr borrow_state;
      Borrow { ord = !borrow_state; loc; borrowed }
  | Umove ->
      incr borrow_state;
      Bmove { ord = !borrow_state; loc; borrowed }
  | Umut | Uset -> failwith "Internal Error: Mutating string"

(* For now, throw everything into one list of bindings.
   In the future, each owning binding could have its own list *)

let mb_add v bs = match v with None -> bs | Some b -> b :: bs

let rec new_elems nu keep old =
  match (nu, old) with
  | _, [] -> nu
  | a :: _, b :: _ when a == b -> List.rev keep
  | a :: tl, _ -> new_elems tl (a :: keep) old
  | _ -> failwith "Internal Error: Impossible"

let rec check_excl_chain loc env borrow borrows =
  match borrow with
  | Bown _ -> ()
  | Borrow b | Borrow_mut (b, _) | Bmove b -> (
      (* print_endline "---------------"; *)
      (* print_endline (show_binding borrow); *)
      (* print_newline (); *)
      (* print_endline (String.concat "\n" (List.map show_binding borrows)); *)
      check_exclusivity loc borrow borrows;
      match Map.find_opt (fst b.borrowed) env with
      | Some b -> check_excl_chain loc env b borrows
      | None -> ())
  | Bmulti (a, b) ->
      check_excl_chain loc env a borrows;
      check_excl_chain loc env b borrows

let rec check_tree env bind mut part tree borrows =
  match Typed_tree.(tree.expr) with
  | Typed_tree.Var borrowed ->
      (* This is no rvalue, we borrow *)
      let borrowed = (get_id borrowed, part) in
      let loc = tree.loc in
      let rec borrow = function
        | Bown b ->
            (* For Binds, it's imported that we take the owned name, and not the one from Var.
               Otherwise, the Bind name might be borrowed *)
            incr borrow_state;
            let borrow = { ord = !borrow_state; loc; borrowed = (b, part) } in
            (* Assmue it's the only borrow. This works because if it isn't, a borrowed binding
               will be used later and thin fail the check. Extra care has to be taken for
               arguments to functions *)
            let b =
              match mut with
              | Usage.Uread -> Borrow borrow
              | Umut -> Borrow_mut (borrow, Dont_set)
              | Uset -> Borrow_mut (borrow, Set)
              | Umove -> Bmove borrow
            in
            check_excl_chain loc env b borrows;
            b
        | Borrow_mut (b', _) as b -> (
            match mut with
            | Usage.Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b borrows;
                Bmove { b' with loc }
            | Umut | Uread ->
                check_excl_chain loc env b borrows;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Dont_set)
            | Uset ->
                check_excl_chain loc env b borrows;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Set))
        | Borrow b' as b -> (
            match mut with
            | Usage.Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b borrows;
                Bmove { b' with loc }
            | Umut ->
                check_excl_chain loc env (Borrow_mut (b', Dont_set)) borrows;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Dont_set)
            | Uset ->
                check_excl_chain loc env (Borrow_mut (b', Set)) borrows;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Set)
            | Uread ->
                check_excl_chain loc env b borrows;
                incr borrow_state;
                Borrow { loc; ord = !borrow_state; borrowed })
        | Bmove m ->
            assert (id_matches m.borrowed borrowed);
            let msg =
              Printf.sprintf "%s was moved in line %i, cannot borrow"
                (Id.s borrowed) (fst m.loc).pos_lnum
            in
            raise (Typed_tree.Error (m.loc, msg))
        | Bmulti (a, b) -> Bmulti (borrow a, borrow b)
      in
      let borrow =
        match Map.find_opt (fst borrowed) env with
        | Some b when bind -> Some b
        | Some b -> Some (borrow b)
        | None -> None
      in
      (* Don't add to borrows here. Other expressions where the value is used
         will take care of this *)
      (borrow, borrows)
  | Let { id; lhs; cont; mutly; rmut; _ } ->
      let env, b, bs = check_let tree.loc env id lhs rmut mutly borrows in
      check_tree env bind mut part cont (b :: bs)
  | Const (Array es) ->
      let bs =
        List.fold_left
          (fun bs e ->
            let v, bs = check_tree env false Umove [] e bs in
            mb_add v bs)
          borrows es
      in
      (None, bs)
  | Const (String _) -> (Some (string_lit_borrow tree.loc mut), borrows)
  | Const _ -> (None, borrows)
  | Record fs ->
      let bs =
        List.fold_left
          (fun bs (_, (field : Typed_tree.typed_expr)) ->
            let usage =
              if Types.contains_allocation field.typ then Usage.Umove else Uread
            in
            let v, bs = check_tree env false usage [] field bs in
            mb_add v bs)
          borrows fs
      in
      (None, bs)
  | Field (tree, i, name) ->
      let b, bs = check_tree env bind mut ((i, name) :: part) tree borrows in
      if Types.contains_allocation tree.typ then (b, bs) else (None, bs)
  | Set (thing, value) ->
      let v, bs = check_tree env false Uread [] value borrows in
      let bs = mb_add v bs in
      (* Track usage of values, but not the one being mutated *)
      let thing, bs = check_tree env bind Uset [] thing bs in
      (thing, mb_add thing bs)
  | Sequence (fst, snd) ->
      let _, bs = check_tree env false Uread [] fst borrows in
      check_tree env bind mut part snd bs
  | App { callee; args } ->
      (* The callee itself can be borrowed *)
      let _, bs = check_tree env false Uread [] callee borrows in
      let bs =
        List.fold_left
          (fun bs (arg, attr) ->
            let v, bs = check_tree env false (Usage.of_attr attr) [] arg bs in
            mb_add v bs)
          bs args
      in
      (* A function cannot return a borrowed value *)
      (None, bs)
  | Bop (_, fst, snd) ->
      let v, bs = check_tree env false Uread [] fst borrows in
      let v, bs = check_tree env false Uread [] snd (mb_add v bs) in
      (None, mb_add v bs)
  | Unop (_, e) ->
      let v, bs = check_tree env false Uread [] e borrows in
      (None, mb_add v bs)
  | If (cond, ae, be) ->
      let v, bs = check_tree env false Uread [] cond borrows in
      let bs = mb_add v bs in
      let a, abs = check_tree env bind mut part ae bs in
      let b, bbs = check_tree env bind mut part be bs in
      (* Make sure borrow kind of both branches matches *)
      let _raise msg = raise (Typed_tree.Error (tree.loc, msg)) in
      let v =
        match (a, b) with
        (* Ignore Bown _ cases, as it can't be returned. Would be borrowed *)
        (* Owning *)
        | None, None -> None
        | None, Some b when is_borrow b ->
            if Types.contains_allocation be.typ then
              _raise "Branches have different ownership: owned vs borrowed"
            else None
        | Some b, None when is_borrow b ->
            if Types.contains_allocation ae.typ then
              _raise "Branches have different ownership: borrowed vs owned"
            else None
        | None, a | a, None -> a
        (* If both branches are (Some _), they have to be both the same kind,
           because it was applied in Var.. above*)
        | Some a, Some b ->
            assert (is_borrow a == is_borrow b);
            Some (Bmulti (a, b))
      in
      let abs = new_elems abs [] bs in
      let bbs = new_elems bbs [] bs in
      (v, abs @ bbs @ bs)
  | Ctor (_, _, e) -> (
      match e with
      | Some e ->
          let v, bs = check_tree env false Umove [] e borrows in
          (None, mb_add v bs)
      | None -> (None, borrows))
  | Variant_index e | Variant_data e -> check_tree env bind mut part e borrows
  | Fmt fs ->
      let bs =
        List.fold_left
          (fun bs -> function
            | Typed_tree.Fstr _ -> bs
            | Fexpr e ->
                let v, bs = check_tree env false Uread [] e bs in
                mb_add v bs)
          borrows fs
      in
      (None, bs)
  | Mutual_rec_decls (_, cont) -> check_tree env bind mut part cont borrows
  | Lambda _ ->
      (* TODO deal with captures *)
      (None, borrows)
  | Function _ ->
      (* TODO deal with captures *)
      (None, borrows)
  | Bind (name, expr, cont) ->
      let env, borrows = check_bind env name expr borrows in
      check_tree env bind mut part cont borrows

and check_let loc env id lhs rmut mutly borrows =
  let nmut =
    match Typed_tree.(lhs.attr.mut, mutly) with
    | true, true when not rmut ->
        raise (Typed_tree.Error (lhs.loc, "Cannot project unmutable binding"))
    | true, true -> Usage.Umut
    | true, false -> Umove
    | false, false -> Uread
    | false, true -> failwith "unreachable"
  in
  let rval, bs = check_tree env false nmut [] lhs borrows in
  let loc = loc in
  let neword () =
    incr borrow_state;
    !borrow_state
  in
  let id = new_id id in
  let rec borrow bs = function
    | Bmove _ as b -> (Bown id, b :: bs)
    | Bmulti (a, b) ->
        (* Switch order so that first move appears near the head of borrow list.
           This way, the first move is reported first (if both move the same thing) *)
        let b, bs = borrow bs b in
        let a, bs = borrow bs a in
        (Bmulti (a, b), bs)
    | Borrow b -> (Borrow { b with loc; ord = neword () }, bs)
    | Borrow_mut (b, _) ->
        (Borrow_mut ({ b with loc; ord = neword () }, Dont_set), bs)
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
  (env, b, bs)

and check_bind env name expr borrows =
  let b, borrows = check_tree env true Uread [] expr borrows in
  let id = new_id name in
  let env = match b with Some b -> Map.add id b env | None -> env in
  (env, borrows)

let check_item (env, bind, mut, part, borrows) = function
  | Typed_tree.Tl_let { loc; id; rmut; mutly; lhs; uniq = _ } ->
      if mutly then
        raise (Typed_tree.Error (lhs.loc, "Cannot use projection at top level"))
      else
        let env, b, bs = check_let loc env id lhs rmut mutly borrows in
        (env, bind, mut, part, b :: bs)
  | Tl_bind (name, expr) ->
      let env, borrows = check_bind env name expr borrows in
      (env, bind, mut, part, borrows)
  | Tl_expr e ->
      (* Basically a sequence *)
      let b, bs = check_tree env false Uread [] e borrows in
      (env, bind, mut, part, mb_add b bs)
  | Tl_function _ | Tl_mutual_rec_decls _ | Tl_module _ ->
      (env, bind, mut, part, borrows)

let check_tree pts pns body =
  (* Add parameters to initial environment *)
  reset ();
  let borrow_of_param borrowed loc =
    incr borrow_state;
    { ord = !borrow_state; loc; borrowed }
  in
  let env, borrows =
    List.fold_left
      (fun (map, bs) (n, _) ->
        (* Parameters are not owned, but using them as owned here makes it easier for
           borrow checking. Correct usage of mutable parameters is already handled in typing.ml *)
        let id = new_id n in
        assert (Id.equal id (Fst n));
        let b = Bown id in
        (Map.add id b map, b :: bs))
      (Map.empty, []) pns
  in

  (* [Umove] because we want to move return values *)
  let v, borrows = check_tree env false Umove [] body borrows in

  (* Try to borrow the params again to make sure they haven't been moved *)
  let borrows = mb_add v borrows in
  param_pass := true;
  List.iter2
    (fun p (n, loc) ->
      (* If there's no allocation, we copying and moving are the same thing *)
      if Types.(contains_allocation p.pt) then
        let borrow = borrow_of_param (Fst n, []) loc in
        match Types.(p.pattr) with
        | Dnorm -> check_excl_chain loc env (Borrow borrow) borrows
        | Dmut ->
            check_excl_chain loc env (Borrow_mut (borrow, Dont_set)) borrows
        | Dmove -> ())
    pts pns

let check_items items =
  reset ();
  List.fold_left check_item (Map.empty, false, Usage.Uread, [], []) items
  |> ignore
