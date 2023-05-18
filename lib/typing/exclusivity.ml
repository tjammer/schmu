open Types
open Typed_tree
(* Implements a borrow checker.
   We have to know the last usage for each binding. Instead of traversing once
   and using post processing, assume each binding is correct and unify
   binding-kind after the fact.*)

module Usage = struct
  type t = Uread | Umut | Umove | Uset [@@deriving show]
  type set = Set | Dont_set [@@deriving show]

  let of_attr = function
    | Ast.Dnorm -> Uread
    | Dmut -> Umut
    | Dmove -> Umove
    | Dset -> Uset
end

module Id = struct
  type t = Fst of string | Shadowed of string * int [@@deriving show]

  let compare a b =
    match (a, b) with
    | Fst a, Fst b -> String.compare a b
    | Shadowed (a, ai), Shadowed (b, bi) ->
        let c = String.compare a b in
        if c == 0 then Int.compare ai bi else c
    | Fst a, Shadowed (b, bi) ->
        let c = String.compare a b in
        if c == 0 then bi else c
    | Shadowed (a, ai), Fst b ->
        let c = String.compare a b in
        if c == 0 then ai else c

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
and borrow_kind = Default | Application

and binding =
  | Bown of Id.t
  | Borrow of borrow
  | Borrow_mut of borrow * Usage.set
  | Bmove of borrow * Ast.loc option

and part_access = (int * string) list [@@deriving show]

let parts_match a wth =
  let rec parts_match = function
    | (i, _) :: tl, (j, _) :: tr ->
        if Int.equal i j then parts_match (tl, tr)
        else (* Borrows concern different parts *) false
    | [], _ -> true
    | _, [] -> (* Borrows are not mutually exclusive *) false
  in
  assert (Id.equal (fst a) (fst wth));
  parts_match (snd a, snd wth)

let are_borrow bs =
  let is_borrow = function
    | Bown _ | Bmove _ -> false
    | Borrow _ | Borrow_mut _ -> true
  in
  match bs with
  | [] -> false
  | bs -> List.fold_left (fun is b -> is && is_borrow b) true bs

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

let rec check_exclusivity loc borrow hist =
  let p = Printf.sprintf in
  match (borrow, hist) with
  (* TODO only check String.equal once *)
  | _, [] ->
      print_endline (show_binding borrow);
      failwith "Internal Error: Should never be empty"
  | Bown _, _ -> ()
  | (Borrow b | Borrow_mut (b, _) | Bmove (b, _)), _
    when Id.is_string b.borrowed ->
      (* Strings literals can always be borrowed. For now also moved *)
      ()
  | (Borrow b | Borrow_mut (b, _) | Bmove (b, _)), Bown name :: _
    when Id.equal (fst b.borrowed) name ->
      ()
  | Borrow l, Borrow r :: tl when parts_match l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then () else check_exclusivity loc borrow tl
  | Borrow_mut (l, _), Borrow_mut (r, _) :: tl
    when parts_match l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then ()
      else if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow"
            (Id.s r.borrowed) (fst l.loc).pos_lnum
        in
        raise (Error (r.loc, msg))
      else check_exclusivity loc borrow tl
  | Borrow l, Borrow_mut (r, _) :: _ when parts_match l.borrowed r.borrowed ->
      if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was borrowed in line %i, cannot mutate" (Id.s r.borrowed)
            (fst l.loc).pos_lnum
        in
        raise (Error (r.loc, msg))
      else ()
  | Borrow_mut (l, _), Borrow r :: _ when parts_match l.borrowed r.borrowed ->
      if l.ord < r.ord then
        (* Mutable borrow still active while borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow"
            (Id.s r.borrowed) (fst l.loc).pos_lnum
        in
        raise (Error (r.loc, msg))
      else ()
  | (Borrow b | Bmove (b, _) | Borrow_mut (b, Dont_set)), Bmove (m, l) :: _
  (* Allow mutable borrow for setting new values *)
    when parts_match b.borrowed m.borrowed ->
      (* Accessing a moved value *)
      let loc, msg =
        if not !param_pass then
          let hint =
            match l with
            | Some (l, _) -> p ". Move occurs in line %i" l.pos_lnum
            | None -> ""
          in
          ( loc,
            p "%s was moved in line %i, cannot use%s" (Id.s m.borrowed)
              (fst m.loc).pos_lnum hint )
        else (m.loc, p "Borrowed parameter %s is moved" (Id.s b.borrowed))
      in
      raise (Error (loc, msg))
  | Bmove (m, _), (Borrow b | Borrow_mut (b, _)) :: _
    when parts_match m.borrowed b.borrowed ->
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
      Bmove ({ ord = !borrow_state; loc; borrowed }, None)
  | Umut | Uset -> failwith "Internal Error: Mutating string"

(* For now, throw everything into one list of bindings.
   In the future, each owning binding could have its own list *)

let add_binding b hist =
  let bind_name = function
    | Bown n -> n
    | Borrow b | Borrow_mut (b, _) | Bmove (b, _) -> fst b.borrowed
  in
  let name = bind_name b in
  match Map.find_opt name hist with
  | Some l -> Map.add name (b :: l) hist
  | None -> Map.add name (b :: []) hist

let mb_add v hs =
  match v with
  | [] -> hs
  | hist -> List.fold_left (fun hs b -> add_binding b hs) hs hist

let rec new_elems nu keep old =
  match (nu, old) with
  | _, [] -> nu
  | a :: _, b :: _ when a == b -> List.rev keep
  | a :: tl, _ -> new_elems tl (a :: keep) old
  | _ -> failwith "Internal Error: Impossible"

let integrate_new_elems nu old integrated =
  Map.fold
    (fun id borrows integrated ->
      match Map.find_opt id old with
      | None -> (
          (* everything is new *)
          match Map.find_opt id integrated with
          | None -> Map.add id borrows integrated
          | Some l -> Map.add id (borrows @ l) integrated)
      | Some bs ->
          let nu = new_elems borrows [] bs in
          let toadd = nu @ Map.find id integrated in
          Map.add id toadd integrated)
    nu integrated

let rec check_excl_chain loc env borrow hist =
  match borrow with
  | Bown _ -> ()
  | Borrow b | Borrow_mut (b, _) | Bmove (b, _) -> (
      (* print_endline "---------------"; *)
      (* print_endline (show_binding borrow); *)
      (* print_newline (); *)
      (* print_endline (String.concat "\n" (List.map show_binding hist)); *)
      check_exclusivity loc borrow (Map.find (fst b.borrowed) hist);
      match Map.find_opt (fst b.borrowed) env with
      | Some ((Default | Application), b) -> check_excl_chains loc env b hist
      | None -> ())

and check_excl_chains loc env borrow hist =
  List.iter (fun b -> check_excl_chain loc env b hist) borrow

let make_var loc name typ = { typ; expr = Var name; attr = no_attr; loc }

let binding_of_borrow borrow = function
  | Usage.Uread -> Borrow borrow
  | Umut -> Borrow_mut (borrow, Dont_set)
  | Uset -> Borrow_mut (borrow, Set)
  | Umove -> Bmove (borrow, None)

let rec check_tree env bind mut part tree hist =
  match tree.expr with
  | Var borrowed ->
      (* This is no rvalue, we borrow *)
      let borrowed = (get_id borrowed, part) in
      let loc = tree.loc in
      let borrow = function
        | Bown b ->
            (* For Binds, it's imported that we take the owned name, and not the one from Var.
               Otherwise, the Bind name might be borrowed *)
            incr borrow_state;
            let borrow = { ord = !borrow_state; loc; borrowed = (b, part) } in
            (* Assmue it's the only borrow. This works because if it isn't, a borrowed binding
               will be used later and thin fail the check. Extra care has to be taken for
               arguments to functions *)
            let b = binding_of_borrow borrow mut in
            check_excl_chain loc env b hist;
            b
        | Borrow_mut (b', _) as b -> (
            match mut with
            | Usage.Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b hist;
                Bmove ({ b' with loc }, None)
            | Umut | Uread ->
                check_excl_chain loc env b hist;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Dont_set)
            | Uset ->
                check_excl_chain loc env b hist;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Set))
        | Borrow b' as b -> (
            match mut with
            | Usage.Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b hist;
                Bmove ({ b' with loc }, None)
            | Umut ->
                check_excl_chain loc env (Borrow_mut (b', Dont_set)) hist;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Dont_set)
            | Uset ->
                check_excl_chain loc env (Borrow_mut (b', Set)) hist;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Set)
            | Uread ->
                check_excl_chain loc env b hist;
                incr borrow_state;
                Borrow { loc; ord = !borrow_state; borrowed })
        | Bmove (m, l) as b ->
            (* The binding is about to be moved for the first time, e.g. in a function *)
            check_excl_chain loc env b hist;
            Bmove (m, l)
      in

      let borrow =
        match Map.find_opt (fst borrowed) env with
        | Some (Default, bs) when bind -> bs
        | Some (Default, bs) -> List.map borrow bs
        | Some (Application, _) when bind ->
            failwith "Internal Error: Unexpcted bind"
        | Some (Application, bs) ->
            (* Increase borrow order as it's a new borrow *)
            let update b =
              incr borrow_state;
              { b with ord = !borrow_state; loc }
            in
            let f b =
              let b =
                match b with
                | Bmove (b, l) ->
                    (* We keep the current location for the move *)
                    Bmove (update b, l)
                | Borrow b -> Borrow (update b)
                | Borrow_mut (b, s) -> Borrow_mut (update b, s)
                | Bown _ ->
                    failwith "Internal Error: A borrowed thing isn't owned"
              in
              check_excl_chain loc env b hist;
              b
            in
            List.map f bs
        | None -> []
      in
      (* Don't add to hist here. Other expressions where the value is used
         will take care of this *)
      (borrow, hist)
  | Let { id; lhs; cont; mutly; rmut; _ } ->
      let env, b, hs =
        check_let tree.loc env id lhs rmut mutly ~tl:false hist
      in
      check_tree env bind mut part cont (mb_add b hs)
  | Const (Array es) ->
      let hs =
        List.fold_left
          (fun hs e ->
            let v, hs = check_tree env false Umove [] e hs in
            mb_add v hs)
          hist es
      in
      ([], hs)
  | Const (String _) -> ([ string_lit_borrow tree.loc mut ], hist)
  | Const _ -> ([], hist)
  | Record fs ->
      let hs =
        List.fold_left
          (fun hs (_, (field : typed_expr)) ->
            let usage =
              if contains_allocation field.typ then Usage.Umove else Uread
            in
            let v, hs = check_tree env false usage [] field hs in
            mb_add v hs)
          hist fs
      in
      ([], hs)
  | Field (tree, i, name) ->
      let b, hs = check_tree env bind mut ((i, name) :: part) tree hist in
      if contains_allocation tree.typ then (b, hs) else ([], hs)
  | Set (thing, value) ->
      let v, hs = check_tree env false Uread [] value hist in
      let hs = mb_add v hs in
      (* Track usage of values, but not the one being mutated *)
      let thing, hs = check_tree env bind Uset [] thing hs in
      (thing, mb_add thing hs)
  | Sequence (fst, snd) ->
      let _, hs = check_tree env false Uread [] fst hist in
      check_tree env bind mut part snd hs
  | App { callee; args } ->
      (* The callee itself can be borrowed *)
      let b, hs = check_tree env false Uread [] callee hist in
      let _, tmp, hs =
        List.fold_left
          (fun (i, tmp, hs) (arg, attr) ->
            let v, hs = check_tree env false (Usage.of_attr attr) [] arg hs in
            let tmp = Map.add (Fst ("_" ^ string_of_int i)) (Default, v) tmp in
            (i + 1, tmp, mb_add v hs))
          (0, env, mb_add b hs)
          args
      in
      (* Check again to ensure exclusivity of arguments *)
      List.iteri
        (fun i (arg, attr) ->
          match Usage.of_attr attr with
          | Umove ->
              (* Moved values can't have been used later *)
              ()
          | u ->
              let arg = { arg with expr = Var ("_" ^ string_of_int i) } in
              check_tree tmp false u [] arg hs |> ignore)
        args;
      (* A function cannot return a borrowed value *)
      ([], hs)
  | Bop (_, fst, snd) ->
      let v, hs = check_tree env false Uread [] fst hist in
      let v, hs = check_tree env false Uread [] snd (mb_add v hs) in
      ([], mb_add v hs)
  | Unop (_, e) ->
      let v, hs = check_tree env false Uread [] e hist in
      ([], mb_add v hs)
  | If (cond, ae, be) ->
      let v, hs = check_tree env false Uread [] cond hist in
      let hs = mb_add v hs in
      let a, abs = check_tree env bind mut part ae hs in
      let b, bbs = check_tree env bind mut part be hs in
      (* Make sure borrow kind of both branches matches *)
      let _raise msg = raise (Error (tree.loc, msg)) in
      let v =
        match (a, b) with
        (* Ignore Bown _ cases, as it can't be returned. Would be borrowed *)
        (* Owning *)
        | [], [] -> []
        | [], b when are_borrow b ->
            if contains_allocation be.typ then
              _raise "Branches have different ownership: owned vs borrowed"
            else []
        | b, [] when are_borrow b ->
            if contains_allocation ae.typ then
              _raise "Branches have different ownership: borrowed vs owned"
            else []
        | [], a | a, [] -> a
        (* If both branches are (Some _), they have to be both the same kind,
           because it was applied in Var.. above*)
        | a, b ->
            assert (are_borrow a == are_borrow b);
            a @ b
      in
      (v, integrate_new_elems abs hs bbs)
  | Ctor (_, _, e) -> (
      match e with
      | Some e ->
          let usage =
            if contains_allocation e.typ then Usage.Umove else Uread
          in
          let v, hs = check_tree env false usage [] e hist in
          ([], mb_add v hs)
      | None -> ([], hist))
  | Variant_index e | Variant_data e -> check_tree env bind mut part e hist
  | Fmt fs ->
      let hs =
        List.fold_left
          (fun hs -> function
            | Fstr _ -> hs
            | Fexpr e ->
                let v, hs = check_tree env false Uread [] e hs in
                mb_add v hs)
          hist fs
      in
      ([], hs)
  | Mutual_rec_decls (_, cont) -> check_tree env bind mut part cont hist
  | Lambda _ ->
      (* TODO *)
      ([], hist)
  | Function (name, _, abs, cont) ->
      let bindings, hist =
        check_abstraction ~lambda:false env tree.loc abs.func.touched hist
      in
      let env =
        match List.rev bindings with
        | [] -> env
        | bs -> Map.add (Fst name) (Application, bs) env
      in
      check_tree env bind mut part cont hist
  | Bind (name, expr, cont) ->
      let env, hist = check_bind env name expr hist in
      check_tree env bind mut part cont hist

and check_let ~tl loc env id lhs rmut mutly hist =
  let nmut =
    match (lhs.attr.mut, mutly) with
    | true, true when not rmut ->
        raise (Error (lhs.loc, "Cannot project unmutable binding"))
    | true, true -> Usage.Umut
    | true, false -> Umove
    | false, false ->
        if rmut && tl then
          raise (Error (lhs.loc, "Cannot borrow mutable binding at top level"));
        Uread
    | false, true -> failwith "unreachable"
  in
  let rval, hs = check_tree env false nmut [] lhs hist in
  let loc = loc in
  let neword () =
    incr borrow_state;
    !borrow_state
  in
  let id = new_id id in
  let borrow hs = function
    | Bmove _ as b -> (Bown id, mb_add [ b ] hs)
    | Borrow b -> (Borrow { b with loc; ord = neword () }, hs)
    | Borrow_mut (b, _) ->
        (Borrow_mut ({ b with loc; ord = neword () }, Dont_set), hs)
    | Bown _ -> failwith "Internal Error: A borrowed thing isn't owned"
  in
  let b, hs =
    match rval with
    | [] ->
        (* No borrow, original, owned value *)
        ([ Bown id ], hs)
    | b ->
        (* Switch order so that first move appears near the head of borrow list.
             This way, the first move is reported first (if both move the same thing) *)
        let bindings, hist =
          List.fold_right
            (fun b (bindings, hist) ->
              let b, hist = borrow hist b in
              (b :: bindings, hist))
            b ([], hs)
        in
        (bindings, hist)
  in
  let env = Map.add id (Default, b) env in
  (env, b, hs)

and check_bind env name expr hist =
  let b, hist = check_tree env true Uread [] expr hist in
  let id = new_id name in
  let env = match b with [] -> env | bs -> Map.add id (Default, bs) env in
  (env, hist)

and check_abstraction env loc ~lambda touched hist =
  List.fold_left
    (fun (bindings, hist) (use : touched) ->
      (* For moved values, don't check touched here. Instead, add them as
         bindings later so they get moved on first use *)
      let touched = Usage.of_attr use.tattr in
      let var = make_var loc use.tname use.ttyp in
      let b, nhist = check_tree env false touched [] var hist in
      (b @ bindings, if lambda then nhist else hist))
    ([], hist) touched

let check_item (env, bind, mut, part, hist) = function
  | Tl_let { loc; id; rmut; mutly; lhs; uniq = _ } ->
      if mutly then raise (Error (lhs.loc, "Cannot project at top level"))
      else
        let env, b, hs = check_let loc env id lhs rmut mutly ~tl:true hist in
        (env, bind, mut, part, mb_add b hs)
  | Tl_bind (name, expr) ->
      let env, hist = check_bind env name expr hist in
      (env, bind, mut, part, hist)
  | Tl_expr e ->
      (* Basically a sequence *)
      let b, hs = check_tree env false Uread [] e hist in
      (env, bind, mut, part, mb_add b hs)
  | Tl_function (loc, name, _, abs) ->
      let bindings, hist =
        check_abstraction ~lambda:false env loc abs.func.touched hist
      in
      let env =
        match List.rev bindings with
        | [] -> env
        | bs -> Map.add (Fst name) (Application, bs) env
      in
      (env, bind, mut, part, hist)
  | Tl_mutual_rec_decls _ | Tl_module _ -> (env, bind, mut, part, hist)

let find_usage id hist =
  (* The hierarchy is move > mut > read. Since we read from the end,
     the first borrow means the binding was not moved *)
  let rec aux = function
    | [ Bown _ ] -> (Ast.Dnorm, None)
    | Borrow_mut (b, Dont_set) :: _ -> (Dmut, Some b.loc)
    | Borrow_mut (b, Set) :: _ -> (Dset, Some b.loc)
    | Bmove (b, _) :: _ -> (Dmove, Some b.loc)
    | Borrow _ :: tl -> aux tl
    | Bown _ :: _ -> failwith "Internal Error: Owned later?"
    | [] -> failwith "Internal Error: Should have been added as owned"
  in
  Map.find id hist |> aux

let check_tree pts pns touched body =
  (* Add parameters to initial environment *)
  reset ();
  let borrow_of_param borrowed loc =
    incr borrow_state;
    { ord = !borrow_state; loc; borrowed }
  in

  (* Shadowing between touched variables and parameters is impossible. If a parameter
     exists with the same name, the variable would not have been closed over / touched *)
  (* touched variables *)
  let env, hist =
    List.fold_left
      (fun (map, hs) t ->
        let id = new_id t.tname in
        assert (Id.equal id (Fst t.tname));
        let b = [ Bown id ] in
        (Map.add id (Default, b) map, mb_add b hs))
      (Map.empty, Map.empty) touched
  in

  (* parameters *)
  let env, hist =
    List.fold_left
      (fun (map, hs) (n, _) ->
        (* Parameters are not owned, but using them as owned here makes it easier for
           borrow checking. Correct usage of mutable parameters is already handled in typing.ml *)
        let id = new_id n in
        assert (Id.equal id (Fst n));
        let b = [ Bown id ] in
        (Map.add id (Default, b) map, mb_add b hs))
      (env, hist) pns
  in

  (* [Umove] because we want to move return values *)
  let usage = if contains_allocation body.typ then Usage.Umove else Uread in
  let v, hist = check_tree env false usage [] body hist in

  (* Try to borrow the params again to make sure they haven't been moved *)
  let hist = mb_add v hist in
  param_pass := true;
  List.iter2
    (fun p (n, loc) ->
      (* If there's no allocation, we copying and moving are the same thing *)
      if contains_allocation p.pt then
        let borrow = borrow_of_param (Fst n, []) loc in
        match p.pattr with
        | Dnorm -> check_excl_chain loc env (Borrow borrow) hist
        | Dmut -> check_excl_chain loc env (Borrow_mut (borrow, Dont_set)) hist
        | Dset -> check_excl_chain loc env (Borrow_mut (borrow, Set)) hist
        | Dmove -> ())
    pts pns;

  List.map
    (fun t ->
      let tattr, tattr_loc = find_usage (Fst t.tname) hist in
      (match tattr with
      | Dmove ->
          let loc = Option.get tattr_loc in
          raise (Error (loc, "Cannot move values from outer scope"))
      | Dset | Dmut | Dnorm -> ());
      { t with tattr; tattr_loc })
    touched

let check_items items =
  reset ();
  let env, _, _, _, hist =
    List.fold_left check_item
      (Map.empty, false, Usage.Uread, [], Map.empty)
      items
  in

  (* No moves at top level *)
  Map.iter
    (fun id (k, _) ->
      match k with
      | Default -> (
          let tattr, tattr_loc = find_usage id hist in
          match tattr with
          | Dmove ->
              let loc = Option.get tattr_loc in
              raise (Error (loc, "Cannot move top level binding"))
          | Dset | Dmut | Dnorm -> ())
      | Application -> ())
    env
