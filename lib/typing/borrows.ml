module Borrow = struct
  type action = Read | Write [@@deriving show]
  type action_location = Foreign | Local [@@deriving show]

  type borrow_state =
    | Reserved
    | Unique
    | Frozen
    | Disabled
    | Reserved_im
    | Owned
  [@@deriving show]

  let transition curr action action_loc =
    (* Keep location next to state to remember the location of whatever brought
       us into the current state. If a transition is invalid, we can point to
       whatever brought us here. If the state doesn't change, keep the first
       location.*)
    let curr, loc = curr in
    match (curr, action) with
    | Reserved, (Read, (Foreign | Local)) -> Ok (Reserved, loc)
    | Reserved, (Write, Local) -> Ok (Unique, action_loc)
    | Reserved, (Write, Foreign) -> Ok (Disabled, action_loc)
    | Unique, ((Read | Write), Local) -> Ok (Unique, loc)
    | Unique, (Read, Foreign) -> Ok (Frozen, action_loc)
    | Unique, (Write, Foreign) -> Ok (Disabled, action_loc)
    | Frozen, (Read, (Local | Foreign)) -> Ok (Frozen, loc)
    | Frozen, (Write, Local) -> Error `Frozen
    | Frozen, (Write, Foreign) -> Ok (Disabled, action_loc)
    | Reserved_im, (Read, (Local | Foreign) | Write, Foreign) ->
        Ok (Reserved_im, loc)
    | Reserved_im, (Write, Local) -> Ok (Unique, action_loc)
    | Disabled, ((Read | Write), Foreign) -> Ok (Disabled, loc)
    | Disabled, ((Read | Write), Local) -> Error `Disabled
    | Owned, _ -> Ok (Owned, loc)
end

open Borrow

module type Pathid = sig
  include Map.OrderedType

  val create : string -> Path.t option -> t
end

module type Id_t = sig
  type t

  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val equal : t -> t -> bool
  val compare : t -> t -> int
  val only_id : t -> string

  module Pathid : Pathid

  val fst : Pathid.t -> t
  val shadowed : Pathid.t -> int -> t
end

module Make_tree (Id : Id_t) = struct
  type loc_info = { lid : Id.t; loc : Ast.loc } [@@deriving show]
  type mov = loc_info option [@@deriving show]
  type part = string list [@@deriving show]

  type access = { id : string; part : part }
  (* Only record parts, for now *) [@@deriving show]

  let string_of_access a =
    match a.part with [] -> a.id | part -> a.id ^ "." ^ String.concat "." part

  type whole = {
    bor : borrow_state * loc_info;
    mov : mov; (* loc: location where the binding was moved *)
    id : access;
    bind_loc : loc_info;
    children : t list;
  }

  and parts = { rest : whole; parts : whole list }
  and t = Twhole of whole | Tparts of parts [@@deriving show]

  module Path = struct
    type t = { ids : string list; part : part } [@@deriving show]

    let singleton id = { ids = [ Id.only_id id ]; part = [] }
    let append p id = { p with ids = p.ids @ [ Id.only_id id ] }
    let empty = { ids = []; part = [] }
  end

  type access_path = { ac : Ast.decl_attr; path : Path.t }

  let transition_exn bor bind_loc acc location loc =
    match transition bor (acc, location) loc with
    | Ok state -> state
    | Error `Disabled ->
        let msg =
          Format.sprintf "%s was borrowed in line %i, cannot mutate"
            (Id.only_id bind_loc.lid) (fst bind_loc.loc).pos_lnum
        in
        raise (Error.Error (loc.loc, msg))
    | Error `Frozen -> failwith "not yet frozen"

  let rec contains_part ~target ~other =
    match (target, other) with
    | [], _ ->
        (* Whole contains all parts *)
        true
    | _, [] -> true
    | t :: target, o :: other ->
        if String.equal t o then contains_part ~target ~other else false

  let rec fold ~foreign ~local path acc tree =
    let down_ = fold ~foreign ~local in
    let foreign_ = foreign ~down:(down_ Path.empty) in
    match (Path.(path.ids), tree) with
    | p :: ids, Twhole item when String.equal p item.id.id -> (
        let ends = match ids with [] -> true | _ -> false in
        match path.part with
        | [] ->
            (* Whole borrowed as whole *)
            let acc, item =
              local ~down:(down_ { path with ids }) ~ends acc item
            in
            (acc, Twhole item)
        | part ->
            (* Split whole into parts. Borrow rest as foreign and recurs into
               matching part.*)
            let contains_part = contains_part ~target:part ~other:[] in
            assert contains_part;
            let acc, rest = foreign_ ~contains_part acc item in

            let id = { item.id with part } in
            let acc, part =
              local ~down:(down_ { ids; part = [] }) ~ends acc { item with id }
            in
            assert (part.id = id);
            (acc, Tparts { rest; parts = [ part ] }))
    | p :: ids, Tparts { rest; parts } when String.equal p rest.id.id -> (
        let ends = match ids with [] -> true | _ -> false in
        match path.part with
        | [] ->
            (* rest is borrowed local, parts are foreign *)
            let acc, rest =
              let path = Path.{ ids; part = [] } in
              local ~down:(down_ path) ~ends acc rest
            in

            let acc, parts =
              List.fold_left_map
                (fun acc item ->
                  (* parts must not have empty part *)
                  assert (not (item.id = { id = p; part = [] }));
                  let contains_part =
                    contains_part ~target:[] ~other:item.id.part
                  in
                  let acc, item =
                    foreign
                      ~down:(down_ { ids = []; part = item.id.part })
                      ~contains_part acc item
                  in
                  (acc, item))
                acc parts
            in
            (acc, Tparts { rest; parts })
        | part ->
            (* rest is foreign *)
            assert (contains_part ~target:part ~other:[]);
            let acc, rest = foreign_ ~contains_part:true acc rest in

            (* Add this part if it doesn't exist yet *)
            let this_access = { id = p; part } in
            let parts =
              match List.find_opt (fun item -> item.id = this_access) parts with
              | None ->
                  let id = { rest.id with part } in
                  { rest with id } :: parts
              | Some _ -> parts
            in
            let acc, parts =
              List.fold_left_map
                (fun acc item ->
                  if item.id = this_access then
                    let acc, item =
                      local ~down:(down_ { ids; part = [] }) ~ends acc item
                    in
                    (acc, item)
                  else
                    let contains_part =
                      contains_part ~target:part ~other:item.id.part
                    in
                    let acc, item = foreign_ ~contains_part acc item in
                    (acc, item))
                acc parts
            in
            (acc, Tparts { rest; parts }))
    | _, Twhole item ->
        let acc, item = foreign_ ~contains_part:false acc item in
        (acc, Twhole item)
    | _, Tparts { rest; parts } ->
        (* All foreign *)
        let acc, rest = foreign_ ~contains_part:false acc rest in
        let acc, parts =
          List.fold_left_map
            (fun acc item ->
              let acc, item = foreign_ ~contains_part:false acc item in
              (acc, item))
            acc parts
        in
        (acc, Tparts { rest; parts })

  let borrow access loc tree =
    let foreign ~down ~contains_part found item =
      print_endline (string_of_access item.id ^ " foreign");
      (if contains_part then
         match (item.mov, access.ac) with
         | Some lc, (Ast.Dmove | Dmut | Dnorm) ->
             (* Our item has been moved *)
             let msg =
               Format.sprintf "%s was moved in line %i, cannot use"
                 (string_of_access item.id) (fst lc.loc).pos_lnum
             in
             raise (Error.Error (loc.loc, msg))
         | Some _, Dset -> ()
         | None, _ -> ());
      let access =
        match access.ac with Dmove | Dnorm -> Read | Dmut | Dset -> Write
      in
      let bor = transition_exn item.bor item.bind_loc access Foreign loc in
      let found, children =
        List.fold_left_map
          (fun found tree -> down found tree)
          found item.children
      in
      (found, { item with bor; children })
    in

    let local ~down ~ends found item =
      print_endline (string_of_access item.id ^ " local");
      let mov, access =
        match (item.mov, access.ac) with
        | Some lc, (Ast.Dmove | Dmut | Dnorm) ->
            (* Our item has been moved *)
            let msg =
              Format.sprintf "%s was moved in line %i, cannot use"
                (string_of_access item.id) (fst lc.loc).pos_lnum
            in
            raise (Error.Error (loc.loc, msg))
        | Some _, Dset -> (None, Write)
        | None, (Dset | Dmut) -> (None, Write)
        | None, Dnorm -> (None, Read)
        | None, Dmove ->
            print_endline
              ("moved " ^ string_of_access item.id ^ " in line "
              ^ ((fst loc.loc).pos_lnum |> string_of_int));
            (Some loc, Read)
      in
      let bor = transition_exn item.bor item.bind_loc access Local loc in
      let found, children =
        List.fold_left_map
          (fun found tree -> down found tree)
          (ends || found) item.children
      in
      (found, { item with bor; children; mov })
    in

    fold ~local ~foreign access.path false tree

  let bind id bind_loc lmut path tree =
    (* Only bind, i.e. add the child to the bound thing. Checking if the binding
       is legal has to have happened before. *)
    let foreign ~down:_ ~contains_part:_ found item = (found, item) in
    let local ~down ~ends found item =
      let found, children =
        if ends then
          let bor = if lmut then (Reserved, bind_loc) else (Frozen, bind_loc)
          and mov = None
          and id = { id; part = [] } in
          ( true,
            Twhole { bor; mov; id; bind_loc; children = [] } :: item.children )
        else
          List.fold_left_map
            (fun found tree -> down found tree)
            found item.children
      in
      (found, { item with children })
    in

    fold ~local ~foreign path false tree
end

module Make_storage (Id : Id_t) = struct
  module Id = Id
  module Id_map = Map.Make (Id)
  module Index_map = Map.Make (Int)
  module Tree = Make_tree (Id)

  type index = {
    ipath : Tree.Path.t;
    index : int;
    call_attr : Ast.decl_attr option;
  }

  type indices = index list
  type t = { indices : indices Id_map.t; trees : Tree.t Index_map.t }

  let empty = { indices = Id_map.empty; trees = Index_map.empty }
  let id = ref 0
  let reset () = id := 0

  let fresh () =
    incr id;
    !id

  let borrow lid loc ac part st =
    match Id_map.find_opt lid st.indices with
    | Some inds ->
        (* borrow *)
        let found, trees =
          List.fold_left
            (fun (found, trees) { ipath; index; call_attr } ->
              let ac = match call_attr with Some ac -> ac | None -> ac in
              let path = Tree.Path.{ ipath with part = ipath.part @ part } in
              let nfound, tree =
                Tree.borrow { ac; path } { lid; loc }
                  (Index_map.find index trees)
              in
              (found && nfound, Index_map.add index tree st.trees))
            (true, st.trees) inds
        in
        (found, { st with trees })
    | None -> (false, st)

  let bind id loc lmut bounds st =
    let aux (bound, part, attr) st =
      match Id_map.find_opt bound st.indices with
      | Some inds ->
          let (found, trees), indices =
            List.fold_left_map
              (fun (found, trees) { ipath; index; call_attr } ->
                let loc = { Tree.lid = bound; loc } in
                let path = Tree.Path.{ ipath with part } in
                let lmut, call_attr =
                  match attr with
                  (* If there is an attribute, it's from a touched variable of a
                     function. We use this to set the correct borrow state for
                     this borrow. *)
                  | Some (Ast.Dmut | Dset) -> (true, attr)
                  | Some (Dnorm | Dmove) -> (false, attr)
                  | None -> (lmut, call_attr)
                in
                let nfound, tree =
                  Tree.bind (Id.only_id id) loc lmut path
                    (Index_map.find index trees)
                in
                let trees = Index_map.add index tree trees
                and ipath = Tree.Path.append path id in
                ((found && nfound, trees), { ipath; index; call_attr }))
              (true, st.trees) inds
          in
          (* inherit [ioncall] from inds *)
          let indices = Id_map.add id indices st.indices in
          (found, { indices; trees })
      | None -> (false, st)
    in
    List.fold_left
      (fun (found, st) bound ->
        let nfound, st = aux bound st in
        (found && nfound, st))
      (true, st) bounds

  let insert id bind_loc bor st =
    assert (Id_map.mem id st.indices |> not);
    let i = fresh () in
    let loc_info = { Tree.lid = id; loc = bind_loc } in
    let bor = (bor, loc_info) and mov = None in
    let trees =
      let id = Tree.{ id = Id.only_id id; part = [] } in
      Index_map.add i
        (Tree.Twhole { bor; mov; id; bind_loc = loc_info; children = [] })
        st.trees
    in
    let index =
      [ { ipath = Tree.Path.singleton id; index = i; call_attr = None } ]
    in
    let indices = Id_map.add id index st.indices in
    { trees; indices }

  let print st =
    print_endline "******************";
    String.concat ", "
      (Id_map.to_seq st.indices
      |> Seq.map (fun (id, inds) ->
             Id.show id ^ ": ^ ["
             ^ String.concat "; "
                 (List.map
                    (fun { ipath = path; index; call_attr } ->
                      let acc =
                        match call_attr with
                        | Some acc -> "(some " ^ Typed_tree.show_dattr acc ^ ")"
                        | None -> "none"
                      in
                      "(" ^ Tree.Path.show path ^ ", " ^ string_of_int index
                      ^ ", " ^ acc ^ ")")
                    inds))
      |> List.of_seq)
    |> print_endline;
    let spaces i = String.make i ' ' in
    let rec show_tree sp t =
      let shtr t =
        spaces sp
        ^ Tree.(string_of_access t.id)
        ^ "= "
        ^ show_borrow_state (fst t.bor)
        ^ " mov: " ^ Tree.show_mov t.mov
        |> print_endline;
        List.iter (fun t -> show_tree (sp + 2) t) Tree.(t.children)
      in
      match t with
      | Tree.Twhole t -> shtr t
      | Tparts { rest; parts } ->
          print_endline (spaces sp ^ "{ rest: ");
          shtr rest;
          print_endline (spaces sp ^ "parts:");
          List.iter (fun t -> shtr t) parts
    in
    Index_map.iter
      (fun i t ->
        print_endline ("t " ^ string_of_int i);
        show_tree 2 t)
      st.trees

  let check_borrow_moves st =
    let rec check_move id loc tree =
      match Tree.(tree.mov) with
      | Some l ->
          let msg =
            Format.sprintf "Borrowed value %s has been moved in line %i"
              (Tree.string_of_access id) Tree.(fst l.loc).pos_lnum
          in
          raise (Error.Error (loc, msg))
      | None ->
          List.iter
            (function
              | Tree.Twhole tree -> check_move id loc tree
              | Tparts { rest; parts } ->
                  check_move id loc rest;
                  List.iter (fun tree -> check_move id loc tree) parts)
            tree.children
    in
    Index_map.iter
      (fun _ -> function
        | Tree.Twhole tree -> (
            print_endline ("check: " ^ Tree.(string_of_access tree.id));
            match tree.bor |> fst with
            | Owned -> ()
            | _ -> (check_move tree.id tree.bind_loc.loc) tree)
        | Tparts { rest; parts } -> (
            match rest.bor |> fst with
            | Owned -> ()
            | _ ->
                (check_move rest.id rest.bind_loc.loc) rest;
                List.iter
                  (fun (tree : Tree.whole) ->
                    (check_move tree.id tree.bind_loc.loc) tree)
                  parts))
      st.trees

  let find_touched_attr id st =
    let index = Id_map.find id st.indices in
    match index with
    | { index; _ } :: [] -> (
        match Index_map.find index st.trees with
        | Tree.Twhole w -> (
            match w.mov with
            | Some loc -> (Ast.Dmove, loc.loc)
            | _ -> (
                match fst w.bor with
                | Reserved -> (Dnorm, (snd w.bor).loc)
                | Unique -> (Dmut, (snd w.bor).loc)
                | _ -> failwith "Internal Error: What is this touched"))
        | _ -> failwith "TODO part touched")
    | _ -> failwith "Internal Error: Touched thing has mutiple borrows"
end

module Make_ids (Id : Id_t) = struct
  module Shadowmap = Map.Make (Id.Pathid)
  module Id = Id

  type t = int Shadowmap.t

  let empty = Shadowmap.empty

  let insert str mname smap =
    let id = Id.Pathid.create str mname in
    match Shadowmap.find_opt id smap with
    | Some i -> (Id.shadowed id i, Shadowmap.add id (i + 1) smap)
    | None -> (Id.fst id, Shadowmap.add id 1 smap)

  let get str mname smap =
    let id = Id.Pathid.create str mname in
    match Shadowmap.find_opt id smap with
    | None | Some 1 -> Id.fst id
    | Some i -> Id.shadowed id (i - 1)
end

(* Tree storage *)
module Trst = Make_storage (Exclusivity.Id)

(* Id storage *)
module Idst = Make_ids (Exclusivity.Id)
open Types
open Typed_tree
open Error

type state = { trees : Trst.t; ids : Idst.t; mname : Path.t }

let state_empty mname = { trees = Trst.empty; ids = Idst.empty; mname }

type borrow_ids = Owned | Borrowed of (Trst.Id.t * Trst.Tree.part) list

let rec check_expr st ac part tyex =
  (* Pass trees back up the typed tree, because we need to maintain its state.
     Ids on the other hand follow lexical scope *)
  Trst.print st.trees;
  match tyex.expr with
  | Const _ -> (Owned, st.trees)
  | Var (str, mname) ->
      print_endline ("var " ^ str ^ ", " ^ show_dattr ac);
      let id = Idst.get str mname st.ids in
      let found, trees = Trst.borrow id tyex.loc ac part st.trees in
      (* Moved borrows don't return a borrow id *)
      print_endline ("found: " ^ string_of_bool found);
      if found && not (ac = Dmove) then (
        print_endline "borrowed";
        (Borrowed [ (id, part) ], trees))
      else (
        print_endline "owned";
        (Owned, trees))
  | App { callee; args } ->
      print_endline "call";
      let _, trees = check_expr st Dnorm [] callee in
      let trees =
        List.fold_left
          (fun trees (arg, attr) ->
            let _, trees = check_expr { st with trees } attr [] arg in
            trees)
          trees args
      in
      (* For now, functions always return an owned value *)
      (Owned, trees)
  | Set (expr, value, _moved) ->
      print_endline "set";
      let _, trees = check_expr st Dmove [] value in
      let _, trees = check_expr { st with trees } Dset [] expr in
      (Owned, trees)
  | Let { id; lmut; pass; rhs; cont; id_loc; _ } ->
      print_endline ("let, line " ^ string_of_int (fst id_loc).pos_lnum);
      let st = check_let st ~toplevel:false id id_loc pass lmut rhs in
      check_expr st ac part cont
  | Sequence (fst, snd) ->
      let _, trees = check_expr st Dnorm [] fst in
      check_expr { st with trees } ac part snd
  | Record es ->
      let trees =
        List.fold_left
          (fun trees (_, e) ->
            let _, trees = check_expr { st with trees } Dmove [] e in
            trees)
          st.trees es
      in
      (Owned, trees)
  | If (cond, _, t, f) ->
      let _, trees = check_expr st Dnorm [] cond in
      let tb, ttrees = check_expr { st with trees } ac part t in
      let fb, ftrees = check_expr { st with trees } ac part f in
      let prefix = "Branches have different ownership: " in
      let _owning, borrow =
        match (tb, fb) with
        | Borrowed t, Borrowed f ->
            (* dedup? *)
            (false, Borrowed (t @ f))
        | Owned, Owned -> (true, Owned)
        | Borrowed _, Owned ->
            raise (Error (cond.loc, prefix ^ "borrowed vs owned"))
        | Owned, Borrowed _ ->
            raise (Error (cond.loc, prefix ^ "owned vs borrowed"))
      in
      (* TODO merge trees *)
      ignore ttrees;
      ignore ftrees;
      (borrow, trees)
  | Field (e, _, name) ->
      (match ac with
      | Dmove when e.attr.const ->
          raise (Error (tyex.loc, "Cannot move out of constant"))
      | _ -> ());
      check_expr st ac (name :: part) e
  | Function (name, _, abs, cont) ->
      let st = check_abs tyex.loc name abs st in
      check_expr st ac part cont
  | _ ->
      (* print_endline ("none: " ^ show_typed_expr tyex); *)
      (Owned, st.trees)

and check_let st ~toplevel str loc pass lmut rhs =
  print_endline (string_of_bool toplevel);
  (match pass with
  | Dmut when toplevel -> raise (Error (rhs.loc, "Cannot project at top level"))
  | Dmut when not rhs.attr.mut ->
      raise (Error (rhs.loc, "Cannot project immutable binding"))
  | Dmove when toplevel ->
      raise (Error (rhs.loc, "Cannot move top level binding"))
  | _ when toplevel && rhs.attr.mut ->
      raise (Error (rhs.loc, "Cannot borrow mutable binding at top level"))
  | _ -> ());
  let bid, ids = Idst.insert str (Some st.mname) st.ids in
  let trees =
    match check_expr st pass [] rhs with
    | Owned, trees ->
        (* Nothing is borrowed, we own this *)
        Trst.insert bid loc Owned trees
    | Borrowed _, _trees when pass = Dmove ->
        failwith "how?"
        (* Transfer ownership *)
        (* Trst.insert bid loc Owned trees *)
    | Borrowed ids, trees ->
        let ids = List.map (fun (a, b) -> (a, b, None)) ids in
        let found, trees = Trst.bind bid loc lmut ids trees in
        assert found;
        trees
  in

  { st with ids; trees }

and check_abs loc name abs st =
  let touched =
    List.map
      (fun touched ->
        print_endline ("touched: " ^ Typed_tree.show_touched touched);
        let bid = Idst.get touched.tname touched.tmname st.ids in
        (bid, [] (* no part *), Some touched.tattr))
      abs.func.touched
  in
  let bid, ids = Idst.insert name (Some st.mname) st.ids in
  let _, trees = Trst.bind bid loc false touched st.trees in

  { st with trees; ids }

let check_item st = function
  | Tl_let { id; pass; rhs; lmut; loc; _ } ->
      print_endline ("tl let " ^ id);
      check_let ~toplevel:true st id loc pass lmut rhs
  | Tl_expr e ->
      let _, trees = check_expr st Dnorm [] e in
      { st with trees }
  | Tl_function (loc, id, _, abs) ->
      print_endline ("tl function: " ^ id);
      check_abs loc id abs st
  | Tl_bind (str, e) ->
      let bid, ids = Idst.insert str (Some st.mname) st.ids in
      let trees =
        match check_expr st Dnorm [] e with
        | Owned, trees -> Trst.insert bid e.loc Frozen trees
        | Borrowed rhs_ids, trees ->
            let ids = List.map (fun (a, b) -> (a, b, None)) rhs_ids in
            let found, trees = Trst.bind bid e.loc false ids trees in
            assert found;
            trees
      in
      { st with ids; trees }
  | _ -> failwith "TODO"

let check_expr ~mname ~params ~touched expr =
  Trst.reset ();

  let state =
    List.fold_left
      (fun st touched ->
        let bid, ids = Idst.insert touched.tname touched.tmname st.ids in
        assert (
          Idst.Id.equal bid
            Idst.Id.(fst (Pathid.create touched.tname touched.tmname)));
        let trees = Trst.insert bid expr.loc Reserved st.trees in
        { st with trees; ids })
      (state_empty mname) touched
  in

  let state =
    List.fold_left
      (fun st (p, id, loc) ->
        let bid, ids = Idst.insert id None st.ids in
        let bstate =
          match p.pattr with
          | Dnorm (* borrowed *) -> Frozen
          | Dmut (* borrowed mut *) -> Reserved
          | Dset -> failwith "unreachable"
          | Dmove -> Owned
        in
        let trees = Trst.insert bid loc bstate st.trees in
        print_endline ("add param " ^ id ^ " as " ^ show_borrow_state bstate);
        { st with ids; trees })
      state params
  in

  let _, trees = check_expr state Dmove [] expr in
  Trst.print trees;

  (* Ensure no parameter has been moved *)
  Trst.check_borrow_moves trees;

  (* Update attribute of touched *)
  List.map
    (fun touched ->
      let bid = Idst.Id.(fst (Pathid.create touched.tname touched.tmname)) in
      let tattr, tattr_loc = Trst.find_touched_attr bid trees in
      { touched with tattr; tattr_loc = Some tattr_loc })
    touched

let check_items ~mname items =
  Trst.reset ();
  List.fold_left (fun st item -> check_item st item) (state_empty mname) items
  |> ignore
