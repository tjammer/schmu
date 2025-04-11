module Borrow = struct
  type action = Read | Write
  type action_location = Foreign | Local
  type state = Reserved | Unique | Frozen | Disabled | Reserved_im | Owned

  let transition curr action =
    match (curr, action) with
    | Reserved, (Read, (Foreign | Local)) -> Ok Reserved
    | Reserved, (Write, Local) -> Ok Unique
    | Reserved, (Write, Foreign) -> Ok Disabled
    | Unique, ((Read | Write), Local) -> Ok Unique
    | Unique, (Read, Foreign) -> Ok Frozen
    | Unique, (Write, Foreign) -> Ok Disabled
    | Frozen, (Read, (Local | Foreign)) -> Ok Frozen
    | Frozen, (Write, Local) -> Error ()
    | Frozen, (Write, Foreign) -> Ok Disabled
    | Reserved_im, (Read, (Local | Foreign) | Write, Foreign) -> Ok Reserved_im
    | Reserved_im, (Write, Local) -> Ok Unique
    | Disabled, (Read, (Local | Foreign)) -> Ok Disabled
    | Disabled, (Write, (Local | Foreign)) -> Error ()
    | Owned, _ -> Ok Owned
end

open Borrow

module type Pathid = sig
  include Map.OrderedType

  val create : string -> Path.t option -> t
end

module type Id_t = sig
  type t

  val equal : t -> t -> bool
  val compare : t -> t -> int

  module Pathid : Pathid

  val fst : Pathid.t -> t
  val shadowed : Pathid.t -> int -> t
end

module Make_tree (Id : Id_t) = struct
  type id = Id.t
  type t = { state : state; id : id; children : t list }
  type path = id list
  type access = { ac : action; path : path }

  let transition_exn state acc location =
    match transition state (acc, location) with
    | Ok state -> state
    | Error () -> failwith "err"

  let borrow access tree =
    let rec aux found path item =
      match path with
      | p :: ptl when Id.equal item.id p ->
          let state = transition_exn item.state access.ac Local in
          let found = match ptl with [] -> true | _ -> found in
          let found, children =
            List.fold_left_map
              (fun found tree -> aux found ptl tree)
              found item.children
          in
          (found, { item with state; children })
      | _ ->
          let state = transition_exn item.state access.ac Foreign in
          let found, children =
            List.fold_left_map
              (fun found tree -> aux found path tree)
              found item.children
          in
          (found, { item with state; children })
    in
    aux false access.path tree

  let bind id access tree =
    (* Similar to borrow, but we don't transition and instead add a node if we
       find the access node *)
    let rec aux found path item =
      match path with
      | p :: ptl when Id.equal item.id p ->
          let found, children =
            match ptl with
            | [] ->
                let state =
                  match access.ac with Read -> Frozen | Write -> Reserved
                in
                (true, { state; id; children = [] } :: item.children)
            | _ ->
                List.fold_left_map
                  (fun found tree -> aux found ptl tree)
                  found item.children
          in
          (found, { item with children })
      | _ ->
          (* Add to another branch. No need to do anything *)
          (found, item)
    in

    aux false access.path tree
end

module Make_storage (Id : Id_t) = struct
  module Id_map = Map.Make (Id)
  module Index_map = Map.Make (Int)
  module Tree = Make_tree (Id)

  type t = { indices : (Tree.path * int) Id_map.t; trees : Tree.t Index_map.t }

  let empty = { indices = Id_map.empty; trees = Index_map.empty }
  let id = ref 0

  let fresh () =
    incr id;
    !id

  let borrow id ac st =
    match Id_map.find_opt id st.indices with
    | Some (path, i) ->
        let found, tree =
          Tree.borrow { ac; path } (Index_map.find i st.trees)
        in
        (found, { st with trees = Index_map.add i tree st.trees })
    | None -> (false, st)

  let bind id ac bound st =
    match Id_map.find_opt bound st.indices with
    | Some (path, i) ->
        let found, tree =
          Tree.bind id { ac; path } (Index_map.find i st.trees)
        in
        (found, { st with trees = Index_map.add i tree st.trees })
    | None -> (false, st)

  let insert id state st =
    assert (Id_map.mem id st.indices |> not);
    let i = fresh () in
    let trees = Index_map.add i Tree.{ state; id; children = [] } st.trees in
    let indices = Id_map.add id ([ id ], i) st.indices in
    { trees; indices }
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

(* open Types *)
open Typed_tree
open Error

type state = { trees : Trst.t; ids : Idst.t; mname : Path.t }

let state_empty mname = { trees = Trst.empty; ids = Idst.empty; mname }

let rec check_expr st tyex =
  (* Pass trees back up the typed tree, because we need to maintain its state.
     Ids on the other hand follow lexical scope *)
  match tyex.expr with
  | Const _ -> (None, st.trees)
  | Var (str, mname) ->
      let id = Idst.get str mname st.ids in
      let found, trees = Trst.borrow id Read st.trees in
      if found then (Some id, trees) else (None, trees)
  | App { callee; args } ->
      let _, trees = check_expr st callee in
      let trees =
        List.fold_left
          (fun trees (arg, _attr) ->
            let _, trees = check_expr { st with trees } arg in
            trees)
          trees args
      in
      (None, trees)
  | _ -> (None, st.trees)

let check_let st ~toplevel str pass lmut rhs =
  print_endline (string_of_bool toplevel);
  if toplevel && pass = Dmut then
    raise (Error (rhs.loc, "Cannot project at top level"))
  else if toplevel && lmut then
    raise (Error (rhs.loc, "Cannot borrow mutable binding at top level"))
  else
    let bid, ids = Idst.insert str (Some st.mname) st.ids in
    let trees =
      match check_expr st rhs with
      | None, trees ->
          (* Nothing is borrowed, we own this *)
          Trst.insert bid Owned trees
      | Some rhs_id, trees ->
          (* Even if we borrow mutably, we don't write here yet *)
          let found, trees = Trst.bind bid Read rhs_id trees in
          assert found;
          trees
    in

    { st with ids; trees }

let check_item st = function
  | Tl_let { id; pass; rhs; lmut; _ } ->
      check_let ~toplevel:true st id pass lmut rhs
  | Tl_expr e ->
      let _, trees = check_expr st e in
      { st with trees }
  | Tl_function _ -> st
  | Tl_bind (str, e) ->
      let bid, ids = Idst.insert str (Some st.mname) st.ids in
      let trees =
        match check_expr st e with
        | None, trees -> Trst.insert bid Frozen trees
        | Some rhs_id, trees ->
            let found, trees = Trst.bind bid Read rhs_id trees in
            assert found;
            trees
      in
      { st with ids; trees }
  | _ -> failwith "TODO"

let check_expr ~mname expr =
  check_expr (state_empty mname) expr |> ignore

let check_items ~mname items =
  ignore Write;
  List.fold_left (fun st item -> check_item st item) (state_empty mname) items
  |> ignore
