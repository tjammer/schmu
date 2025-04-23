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
    | Frozen, (Write, Local) -> Error `None
    | Frozen, (Write, Foreign) -> Ok (Disabled, action_loc)
    | Reserved_im, (Read, (Local | Foreign) | Write, Foreign) ->
        Ok (Reserved_im, loc)
    | Reserved_im, (Write, Local) -> Ok (Unique, action_loc)
    | Disabled, ((Read | Write), Foreign) -> Ok (Disabled, loc)
    | Disabled, ((Read | Write), Local) -> Error (`Disabled (loc, action_loc))
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
  type access = Awhole of Id.t [@@deriving show]

  type whole = {
    bor : borrow_state * loc_info;
    mov : mov; (* loc: location where the binding was moved *)
    id : Id.t;
    bind_loc : loc_info;
    children : t list;
  }

  and t = Twhole of whole [@@deriving show]

  type path = access list [@@deriving show]
  type access_path = { ac : Ast.decl_attr; path : path }

  let transition_exn bor bind_loc acc location loc =
    match transition bor (acc, location) loc with
    | Ok state -> state
    | Error (`Disabled ({ lid; loc = _ }, action)) ->
        let msg =
          Format.sprintf "%s was borrowed in line %i, cannot mutate"
            (Id.only_id lid) (fst bind_loc.loc).pos_lnum
        in
        raise (Error.Error (action.loc, msg))
    | Error `None -> failwith "not yet none"

  let access_eq tree r =
    match (tree, r) with Twhole l, Awhole r -> Id.equal l.id r

  let rec fold ~foreign ~local path acc tree =
    match (path, tree) with
    | p :: ptl, Twhole item when access_eq tree p ->
        let ends = match ptl with [] -> true | _ -> false in
        let acc, item = local ~down:(fold ~foreign ~local ptl) ~ends acc item in
        (acc, Twhole item)
    | _, Twhole item ->
        let acc, item = foreign ~down:(fold ~foreign ~local path) acc item in
        (acc, Twhole item)

  let borrow access loc tree =
    let foreign ~down found item =
      print_endline (Id.show item.id ^ " foreign");
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
      print_endline (Id.show item.id ^ " local");
      let mov, access =
        match (item.mov, access.ac) with
        | Some lc, (Ast.Dmove | Dmut | Dnorm) ->
            (* Our item has been moved *)
            let msg =
              Format.sprintf "%s was moved in line %i, cannot use"
                (Id.only_id item.id) (fst lc.loc).pos_lnum
            in
            raise (Error.Error (loc.loc, msg))
        | Some _, Dset -> (None, Write)
        | None, (Dset | Dmut) -> (None, Write)
        | None, Dnorm -> (None, Read)
        | None, Dmove ->
            print_endline
              ("moved " ^ Id.show item.id ^ " in line "
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
    let foreign ~down:_ found item = (found, item) in
    let local ~down ~ends found item =
      let found, children =
        if ends then
          let bor = if lmut then (Reserved, bind_loc) else (Frozen, bind_loc)
          and mov = None in
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

  type t = {
    indices : (Tree.path * int) list Id_map.t;
    trees : Tree.t Index_map.t;
  }

  let empty = { indices = Id_map.empty; trees = Index_map.empty }
  let id = ref 0
  let reset () = id := 0

  let fresh () =
    incr id;
    !id

  let borrow lid loc ac st =
    match Id_map.find_opt lid st.indices with
    | Some inds ->
        let found, trees =
          List.fold_left
            (fun (found, trees) (path, i) ->
              let nfound, tree =
                Tree.borrow { ac; path } { lid; loc } (Index_map.find i trees)
              in
              (found && nfound, Index_map.add i tree st.trees))
            (true, st.trees) inds
        in
        (found, { st with trees })
    | None -> (false, st)

  let bind id loc lmut bounds st =
    let aux bound st =
      match Id_map.find_opt bound st.indices with
      | Some inds ->
          let (found, trees), indices =
            List.fold_left_map
              (fun (found, trees) (path, i) ->
                let loc = { Tree.lid = bound; loc } in
                let nfound, tree =
                  Tree.bind id loc lmut path (Index_map.find i trees)
                in
                let trees = Index_map.add i tree trees in
                ((found && nfound, trees), (path @ [ Awhole id ], i)))
              (true, st.trees) inds
          in
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
      Index_map.add i
        (Tree.Twhole { bor; mov; id; bind_loc = loc_info; children = [] })
        st.trees
    in
    let indices = Id_map.add id [ ([ Tree.Awhole id ], i) ] st.indices in
    { trees; indices }

  let print st =
    print_endline "******************";
    String.concat ", "
      (Id_map.to_seq st.indices
      |> Seq.map (fun (id, inds) ->
             Id.show id ^ ": ^ ["
             ^ String.concat "; "
                 (List.map
                    (fun (path, i) ->
                      "(" ^ Tree.show_path path ^ ", " ^ string_of_int i ^ ")")
                    inds))
      |> List.of_seq)
    |> print_endline;
    let spaces i = String.make i ' ' in
    let rec show_tree sp t =
      let t = match t with Tree.Twhole t -> t in
      spaces sp
      ^ Tree.(Id.show t.id)
      ^ "= "
      ^ show_borrow_state (fst t.bor)
      ^ " mov: " ^ Tree.show_mov t.mov
      |> print_endline;
      List.iter (fun t -> show_tree (sp + 2) t) Tree.(t.children)
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
              (Id.only_id id) Tree.(fst l.loc).pos_lnum
          in
          raise (Error.Error (loc, msg))
      | None ->
          List.iter
            (function Tree.Twhole tree -> check_move id loc tree)
            tree.children
    in
    Index_map.iter
      (fun _ -> function
        | Tree.Twhole tree -> (
            print_endline ("check: " ^ Tree.(Id.show tree.id));
            match tree.bor |> fst with
            | Owned -> ()
            | _ -> (check_move tree.id tree.bind_loc.loc) tree))
      st.trees
end

module Make_ids (Id : Id_t) = struct
  module Shadowmap = Map.Make (Id.Pathid)

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

type borrow_ids = Owned | Borrowed of Trst.Id.t list

let rec check_expr st ac tyex =
  (* Pass trees back up the typed tree, because we need to maintain its state.
     Ids on the other hand follow lexical scope *)
  Trst.print st.trees;
  match tyex.expr with
  | Const _ -> (Owned, st.trees)
  | Var (str, mname) ->
      print_endline ("var " ^ str ^ ", " ^ show_dattr ac);
      let id = Idst.get str mname st.ids in
      let found, trees = Trst.borrow id tyex.loc ac st.trees in
      (* Moved borrows don't return a borrow id *)
      print_endline ("found: " ^ string_of_bool found);
      if found && not (ac = Dmove) then (
        print_endline "borrowed";
        (Borrowed [ id ], trees))
      else (
        print_endline "owned";
        (Owned, trees))
  | App { callee; args } ->
      print_endline "call";
      let _, trees = check_expr st Dnorm callee in
      let trees =
        List.fold_left
          (fun trees (arg, attr) ->
            let _, trees = check_expr { st with trees } attr arg in
            trees)
          trees args
      in
      (* For now, functions always return an owned value *)
      (Owned, trees)
  | Set (expr, value, _moved) ->
      print_endline "set";
      let _, trees = check_expr st Dmove value in
      let _, trees = check_expr { st with trees } Dset expr in
      (Owned, trees)
  | Let { id; lmut; pass; rhs; cont; id_loc; _ } ->
      print_endline ("let, line " ^ string_of_int (fst id_loc).pos_lnum);
      let st = check_let st ~toplevel:false id id_loc pass lmut rhs in
      check_expr st ac cont
  | Sequence (fst, snd) ->
      let _, trees = check_expr st Dnorm fst in
      check_expr { st with trees } ac snd
  | Record es ->
      let trees =
        List.fold_left
          (fun trees (_, e) ->
            let _, trees = check_expr { st with trees } Dmove e in
            trees)
          st.trees es
      in
      (Owned, trees)
  | If (cond, _, t, f) ->
      let _, trees = check_expr st Dnorm cond in
      let tb, ttrees = check_expr { st with trees } ac t in
      let fb, ftrees = check_expr { st with trees } ac f in
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
    (* TODO [Read] is not always true here *)
    match check_expr st pass rhs with
    | Owned, trees ->
        (* Nothing is borrowed, we own this *)
        Trst.insert bid loc Owned trees
    | Borrowed _, _trees when pass = Dmove ->
        failwith "how?"
        (* Transfer ownership *)
        (* Trst.insert bid loc Owned trees *)
    | Borrowed ids, trees ->
        let found, trees = Trst.bind bid loc lmut ids trees in
        assert found;
        trees
  in

  { st with ids; trees }

let check_item st = function
  | Tl_let { id; pass; rhs; lmut; loc; _ } ->
      check_let ~toplevel:true st id loc pass lmut rhs
  | Tl_expr e ->
      let _, trees = check_expr st Dnorm e in
      { st with trees }
  | Tl_function _ -> st
  | Tl_bind (str, e) ->
      let bid, ids = Idst.insert str (Some st.mname) st.ids in
      let trees =
        match check_expr st Dnorm e with
        | Owned, trees -> Trst.insert bid e.loc Frozen trees
        | Borrowed rhs_ids, trees ->
            let found, trees = Trst.bind bid e.loc false rhs_ids trees in
            assert found;
            trees
      in
      { st with ids; trees }
  | _ -> failwith "TODO"

let check_expr ~mname ~params expr =
  Trst.reset ();
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
      (state_empty mname) params
  in

  let _, trees = check_expr state Dmove expr in
  Trst.print trees;

  (* Ensure no parameter has been moved *)
  Trst.check_borrow_moves trees

let check_items ~mname items =
  Trst.reset ();
  List.fold_left (fun st item -> check_item st item) (state_empty mname) items
  |> ignore
