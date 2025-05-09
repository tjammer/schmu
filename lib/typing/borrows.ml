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
  val fmt : t -> mname:Path.t -> backup:t option -> string -> string

  module Pathid : Pathid

  val fst : Pathid.t -> t
  val shadowed : Pathid.t -> int -> t
end

module Make_tree (Id : Id_t) = struct
  type loc_info = { lid : Id.t; loc : Ast.loc } [@@deriving show]
  type mov = Not_moved | Reset | Moved of loc_info [@@deriving show]

  type part_kind = Pfield of string | Parr_access of Typed_tree.expr
  [@@deriving show]

  type part = part_kind list [@@deriving show]

  type access = { id : Id.t; part : part }
  (* Only record parts, for now *) [@@deriving show]

  let rec aux_fmt = function
    | [] -> ""
    | Pfield f :: tl -> "." ^ f ^ aux_fmt tl
    | Parr_access (Const (Int i)) :: tl ->
        ".[" ^ Int64.to_string i ^ "]" ^ aux_fmt tl
    | Parr_access (Var (s, _)) :: tl -> ".[" ^ s ^ "]" ^ aux_fmt tl
    | Parr_access _ :: tl -> ".[<expr>]" ^ aux_fmt tl

  let string_of_access a mname =
    Id.fmt a.id ~mname ~backup:None (aux_fmt a.part)

  let str_backup access mname backup =
    Id.fmt access.id ~mname ~backup:(Some backup) (aux_fmt access.part)

  type whole = {
    bor : borrow_state * loc_info;
    mov : mov; (* loc: location where the binding was moved *)
    id : access;
    bind_loc : loc_info;
    children : whole list;
  }

  and parts = { rest : whole; parts : whole list }
  and t = Twhole of whole | Tparts of parts [@@deriving show]

  (* TODO delete, this was just for debugging *)
  let mn = Path.Pid ""

  module Path = struct
    type t = { ids : Id.t list; part : part } [@@deriving show]

    let singleton id = { ids = [ id ]; part = [] }
    let append p id = { p with ids = p.ids @ [ id ] }
  end

  type access_path = { ac : Ast.decl_attr; path : Path.t }

  let transition_exn bor id bind_loc acc location loc =
    match transition bor (acc, location) loc with
    | Ok state -> state
    | Error `Disabled ->
        let msg =
          Format.sprintf "%s was borrowed in line %i, cannot mutate" id
            (fst bind_loc.loc).pos_lnum
        in
        raise (Error.Error (loc.loc, msg))
    | Error `Frozen -> failwith "not yet frozen"

  let rec contains_part ~target ~other =
    match (target, other) with
    | [], _ ->
        (* Whole contains all parts *)
        Some target
    | _, [] -> Some target
    | Pfield t :: target, Pfield o :: other ->
        if String.equal t o then contains_part ~target ~other else None
    | Parr_access t :: target, Parr_access o :: other ->
        if t = o then contains_part ~target ~other else None
    | Parr_access _ :: _, Pfield _ :: _ | Pfield _ :: _, Parr_access _ :: _ ->
        None

  let rec part_distance ~target ~other =
    match (target, other) with
    | [], [] -> 0
    | [], _ -> -1 (* Negative means no match *)
    | l, [] -> List.length l
    | Pfield t :: target, Pfield o :: other ->
        if String.equal t o then part_distance ~target ~other else -1
    | Parr_access t :: target, Parr_access o :: other ->
        if t = o then part_distance ~target ~other else -1
    | Parr_access _ :: _, Pfield _ :: _ | Pfield _ :: _, Parr_access _ :: _ ->
        -1

  let fold ~foreign ~local (path : Path.t) acc tree =
    (* First, find out the correct path (without the current added part) and, if
       needed, modify the tree to add the current part. It's important we add
       the part to the correct sub-part so that the correct children are
       availabe. For instance, let c = a.b; d = c.e; When borrowing c.e we want
       to add .e to the a.b part such that we can find the child c. *)
    let tree =
      match (tree, path.part) with
      | tree, [] -> tree
      | Twhole rest, part ->
          (* Split part from rest *)
          let id = { rest.id with part } in
          Tparts { rest; parts = [ { rest with id } ] }
      | Tparts { rest; parts }, part ->
          let candidate, num =
            List.fold_left
              (fun (best, num) item ->
                let n = part_distance ~target:part ~other:item.id.part in
                if n >= 0 && n < num then (item, n) else (best, num))
              (rest, Int.max_int) parts
          in
          if num = 0 then (* Found our candidate *) tree
          else
            let id = { candidate.id with part } in
            print_endline ("copy candidate: " ^ string_of_access id mn ^ " for " ^ show_part part);
            Tparts { rest; parts = { candidate with id } :: parts }
    in

    (* Second, we need to traverse all paths. Local borrows are only the correct
       part. *)
    let rec traverse correct_part contains_part path acc whole =
      match path with
      | p :: ids when Id.equal p whole.id.id ->
          if correct_part then
            let ends = match ids with [] -> true | _ -> false in
            local
              ~down:(traverse correct_part contains_part ids)
              ~ends acc whole
          else
            foreign
              ~down:(traverse correct_part contains_part [])
              ~contains_part acc whole
      | _ ->
          foreign
            ~down:(traverse correct_part contains_part [])
            ~contains_part acc whole
    in

    let dist item = part_distance ~target:path.part ~other:item.id.part in
    let contains item = contains_part ~target:path.part ~other:item.id.part in
    match tree with
    | Twhole item ->
        let acc, item = traverse true (Some []) path.ids acc item in
        (acc, Twhole item)
    | Tparts { rest; parts } ->
        let acc, rest =
          traverse (dist rest = 0) (contains rest) path.ids acc rest
        in
        let acc, parts =
          List.fold_left_map
            (fun acc item ->
              traverse (dist item = 0) (contains item) path.ids acc item)
            acc parts
        in
        (acc, Tparts { rest; parts })

  let borrow access loc mname tree =
    let foreign ~down ~contains_part found item =
      print_endline (string_of_access item.id mname ^ " foreign");
      (match contains_part with
      | Some part -> (
          match (item.mov, access.ac) with
          | Moved lc, (Ast.Dmove | Dmut | Dnorm) ->
              (* Our item has been moved *)
              let access = { id = item.id.id; part } in
              let msg =
                Format.sprintf "%s was moved in line %i, cannot use %s"
                  (str_backup item.id mname lc.lid)
                  (fst lc.loc).pos_lnum
                  (string_of_access access mname)
              in
              raise (Error.Error (loc.loc, msg))
          | Moved _, Dset -> ()
          | (Not_moved | Reset), _ -> ())
      | None -> ());

      let access =
        match access.ac with Dmove | Dnorm -> Read | Dmut | Dset -> Write
      in
      let id = string_of_access item.id mname in
      let bor = transition_exn item.bor id item.bind_loc access Foreign loc in
      print_endline ("foreign children: " ^ string_of_int (List.length item.children));
      let found, children =
        List.fold_left_map
          (fun found tree -> down found tree)
          found item.children
      in
      (found, { item with bor; children })
    in

    let local ~down ~ends found item =
      print_endline (string_of_access item.id mname ^ " local");
      let mov, access =
        match (item.mov, access.ac) with
        | Moved lc, (Ast.Dmove | Dmut | Dnorm) ->
            (* Our item has been moved *)
            let msg =
              Format.sprintf "%s was moved in line %i, cannot use"
                (str_backup item.id mname lc.lid)
                (fst lc.loc).pos_lnum
            in
            raise (Error.Error (loc.loc, msg))
        | Moved _, Dset -> (Reset, Write)
        | Reset, (Dset | Dmut) -> (Reset, Write)
        | Not_moved, Dset -> (Reset, Write)
        | Not_moved, Dmut -> (Not_moved, Write)
        | (Not_moved | Reset), Dnorm -> (Not_moved, Read)
        | (Not_moved | Reset), Dmove ->
            print_endline
              ("moved "
              ^ string_of_access item.id mname
              ^ " in line "
              ^ ((fst loc.loc).pos_lnum |> string_of_int));
            (Moved loc, Read)
      in
      let tmpac = { item.id with id = item.bind_loc.lid } in
      let id = string_of_access tmpac mname in
      let bor = transition_exn item.bor id item.bind_loc access Local loc in
      print_endline ("local children: " ^ string_of_int (List.length item.children));
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
      print_endline "in local";
      print_endline (string_of_access item.id mn);
      let found, children =
        if ends then (
          let bor = if lmut then (Reserved, bind_loc) else (Frozen, bind_loc)
          and mov = Not_moved
          and id = { id; part = [] } in
          print_endline "ends";
          (true, { bor; mov; id; bind_loc; children = [] } :: item.children))
        else
          let () = print_endline "childeren" in
          List.fold_left_map
            (fun found tree ->
              print_endline ("child: " ^ Id.show tree.id.id);
              down found tree)
            found item.children
      in
      (found, { item with children })
    in

    fold ~local ~foreign path false tree

  let merge (l : t) (r : t) =
    (* We don't merge the whole two trees together. Instead, we pick the most
       interesting of the two and make it the main one. 'Interesting' is picked
       based on scores below. Moved > Borrowed. Added parts are also taken. *)
    let pick_bor l r =
      let score = function
        | Reserved -> 0
        | Reserved_im -> 1
        | Unique -> 2
        | Frozen -> 3
        | Disabled -> 4
        | Owned -> -1
      in
      if score (fst l) >= score (fst r) then `Left else `Right
    in

    let pick_mov l r =
      match (l, r) with
      | Moved _, Moved _ -> `Either
      | Moved _, _ -> `Left
      | _, Moved _ -> `Right
      | _, _ -> `Either
    in

    let merge_whole l r =
      match pick_mov l.mov r.mov with
      | `Left -> l
      | `Right -> r
      | `Either -> ( match pick_bor l.bor r.bor with `Left -> l | `Right -> r)
    in
    match (l, r) with
    | Twhole l, Twhole r ->
        assert (Id.equal l.id.id r.id.id);
        Twhole (merge_whole l r)
    | Twhole l, Tparts { rest; parts } ->
        Tparts { rest = merge_whole l rest; parts }
    | Tparts { rest; parts }, Twhole l ->
        Tparts { rest = merge_whole rest l; parts }
    | Tparts _, Tparts _ -> failwith "TODO parts and properly merge"
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

  let insert id bind_loc bor st =
    print_endline ("add index: " ^ Id.show id);
    assert (Id_map.mem id st.indices |> not);
    let i = fresh () in
    let loc_info = { Tree.lid = id; loc = bind_loc } in
    let bor = (bor, loc_info) and mov = Tree.Not_moved in
    let trees =
      let id = Tree.{ id; part = [] } in
      Index_map.add i
        (Tree.Twhole { bor; mov; id; bind_loc = loc_info; children = [] })
        st.trees
    in
    let index =
      [ { ipath = Tree.Path.singleton id; index = i; call_attr = None } ]
    in
    let indices = Id_map.add id index st.indices in
    { trees; indices }

  let rec borrow lid loc mname ac part st =
    match Id_map.find_opt lid st.indices with
    | Some inds ->
        (* forbid conditional borrow (see unit test) *)
        (match (ac, inds) with
        | Ast.Dmove, ([] | [ _ ]) -> ()
        | Dmove, _ ->
            let msg =
              "Cannot move conditional borrow. Either copy or directly move \
               conditional without borrowing"
            in
            raise (Error.Error (loc, msg))
        | _, _ -> ());
        (* borrow *)
        let found, trees =
          List.fold_left
            (fun (found, trees) { ipath; index; call_attr } ->
              let ac = match call_attr with Some ac -> ac | None -> ac in
              let path = Tree.Path.{ ipath with part = ipath.part @ part } in
              let nfound, tree =
                Tree.borrow { ac; path } { lid; loc } mname
                  (Index_map.find index trees)
              in
              (found && nfound, Index_map.add index tree st.trees))
            (true, st.trees) inds
        in
        (found, { st with trees })
    | None ->
        (* If the item has not been found, add it as a new, borrowed item. This will
           cause it to not be moved. *)
        insert lid loc Reserved st |> borrow lid loc mname ac part

  let bind id loc lmut bounds st =
    let bind_inner bound part attr (found, trees) { ipath; index; call_attr } =
      let loc = { Tree.lid = bound; loc } in
      let path = Tree.Path.{ ipath with part = ipath.part @ part } in
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
        Tree.bind id loc lmut path (Index_map.find index trees)
      in
      let trees = Index_map.add index tree trees
      and ipath = Tree.Path.append path id in
      ((found && nfound, trees), { ipath; index; call_attr })
    in

    let add_indices id indices st_indices =
      (* TODO dedup *)
      print_endline ("add indices: " ^ Id.show id);
      match Id_map.find_opt id st_indices with
      | None -> Id_map.add id indices st_indices
      | Some other -> Id_map.add id (other @ indices) st_indices
    in

    let aux (bound, part, attr) st =
      match Id_map.find_opt bound st.indices with
      | Some inds ->
          let (found, trees), indices =
            List.fold_left_map
              (bind_inner bound part attr)
              (true, st.trees) inds
          in
          let indices = add_indices id indices st.indices in
          (found, { indices; trees })
      | None -> (false, st)
    in
    List.fold_left
      (fun (found, st) bound ->
        let nfound, st = aux bound st in
        (found && nfound, st))
      (true, st) bounds

  let insert_string_literal id bind_loc bor st =
    (* If it doesn't exist then insert. Else update bind_loc *)
    match Id_map.find_opt id st.indices with
    | Some [ _ ] ->
        let indices = Id_map.remove id st.indices in
        insert id bind_loc bor { st with indices }
    | Some _ -> failwith "Is this not a string lateral"
    | None -> insert id bind_loc bor st

  let print st mname =
    print_endline "******************";
    String.concat ",\n"
      (Id_map.to_seq st.indices
      |> Seq.map (fun (id, inds) ->
             Id.show id ^ ": ["
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
        ^ Tree.(string_of_access t.id mname)
        ^ "= "
        ^ show_borrow_state (fst t.bor)
        ^ " mov: " ^ Tree.show_mov t.mov
        |> print_endline;
        List.iter (fun t -> show_tree (sp + 2) t) Tree.(t.children)
      in
      shtr t
    in
    Index_map.iter
      (fun i t ->
        print_endline ("t " ^ string_of_int i);
        match t with
        | Tree.Twhole t -> show_tree 2 t
        | Tparts { rest; parts } ->
            print_endline (spaces 2 ^ "{ rest: ");
            show_tree 2 rest;
            print_endline (spaces 2 ^ "parts:");
            List.iter (fun t -> show_tree 2 t) parts)
      st.trees

  let check_borrow_moves st mname =
    let rec check_move id loc tree =
      match Tree.(tree.mov) with
      | Moved l ->
          let msg =
            match Tree.string_of_access id mname with
            | "string literal" as s ->
                Format.sprintf "Borrowed %s has been moved in line %i" s
            | s ->
                Format.sprintf "Borrowed value %s has been moved in line %i" s
          in
          raise (Error.Error (loc, msg Tree.(fst l.loc).pos_lnum))
      | Not_moved | Reset -> List.iter (check_move id loc) tree.children
    in
    Index_map.iter
      (fun _ -> function
        | Tree.Twhole tree -> (
            print_endline ("check: " ^ Tree.(string_of_access tree.id mname));
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
            | Moved loc -> (Ast.Dmove, loc.loc)
            | Reset -> (Dset, (snd w.bor).loc)
            | _ -> (
                match fst w.bor with
                | Reserved -> (Dnorm, (snd w.bor).loc)
                | Unique -> (Dmut, (snd w.bor).loc)
                | _ -> failwith "Internal Error: What is this touched"))
        | _ -> failwith "TODO part touched")
    | _ -> failwith "Internal Error: Touched thing has mutiple borrows"

  let mem id st = Id_map.mem id st.indices

  let merge l r =
    let indices =
      Id_map.merge
        (fun _id l r ->
          match (l, r) with
          | None, Some _ -> r
          | Some _, None -> l
          | None, None -> None
          | Some l, Some r -> Some (List.merge Stdlib.compare l r))
        l.indices r.indices
    in
    let trees =
      Index_map.merge
        (fun _id l r ->
          match (l, r) with
          | None, Some _ -> r
          | Some _, None -> l
          | None, None -> None
          | Some l, Some r -> Some (Tree.merge l r))
        l.trees r.trees
    in
    { indices; trees }
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

type borrow_ids =
  | Owned
  | Borrowed of (Trst.Id.t * Trst.Tree.part * Ast.decl_attr option) list

let own_local_borrow ~local old_tree =
  (* local borrow means it's actually owned *)
  (* Open questions: *)
  (* What about string literals *)
  (* What about new borrow ids to old items? Could check not id directly but
     id's tree*)
  let rec aux = function
    | [] -> local
    | (id, _part, _attr) :: tl -> if Trst.mem id old_tree then aux tl else Owned
  in
  match local with Owned -> Owned | Borrowed bs -> aux bs

let rec check_expr st ac part tyex =
  (* Pass trees back up the typed tree, because we need to maintain its state.
     Ids on the other hand follow lexical scope *)
  Trst.print st.trees st.mname;
  match tyex.expr with
  | Const (String _) ->
      let id = Idst.get "string literal" (Some st.mname) st.ids in
      let trees = Trst.insert_string_literal id tyex.loc Frozen st.trees in
      (Borrowed [ (id, [], None) ], trees)
  | Const (Array items) ->
      let trees =
        List.fold_left
          (fun trees e ->
            let _, trees = check_expr { st with trees } Dmove [] e in
            trees)
          st.trees items
      in
      (Owned, trees)
  | Const _ -> (Owned, st.trees)
  | Var (str, mname) ->
      print_endline ("var " ^ str ^ ", " ^ show_dattr ac);
      let id = Idst.get str mname st.ids in
      let found, trees = Trst.borrow id tyex.loc st.mname ac part st.trees in
      (* Moved borrows don't return a borrow id *)
      print_endline ("found: " ^ string_of_bool found);
      if not (ac = Dmove && found) then (
        print_endline "borrowed";
        (Borrowed [ (id, part, None) ], trees))
      else (
        print_endline "owned";
        (Owned, trees))
  | App
      {
        callee = { expr = Var ("__array_get", _); _ } as callee;
        args = [ arr; idx ];
      } ->
      let _, trees = check_expr st Dnorm [] callee in
      let _, trees = check_expr { st with trees } (snd idx) [] (fst idx) in
      check_expr { st with trees } (snd arr)
        (Parr_access (fst idx).expr :: part)
        (fst arr)
  | App { callee; args } ->
      print_endline "call";
      let _, trees = check_expr st Dnorm [] callee in

      (* Create temporary bindings for each passed thing *)
      (* No kebab-case allowed for user code, no clashes *)
      let id_i i = "borrow-arg-" ^ string_of_int i in
      let var st arg i = { arg with expr = Var (id_i i, Some st.mname) } in
      let _, tmpstate, trees =
        List.fold_left
          (fun (i, tmpstate, trees) (arg, attr) ->
            let _, trees = check_expr { st with trees } attr [] arg in
            let id = id_i i in

            let lmut =
              match attr with Dmut | Dset -> true | Dnorm | Dmove -> false
            in
            let tmpstate =
              check_let tmpstate ~toplevel:false id arg.loc attr lmut arg
            in
            (i + 1, tmpstate, trees))
          (0, { st with trees }, trees)
          args
      in
      (* Borrow callee + args again *)
      let _, tmptrees = check_expr tmpstate Dnorm [] callee in
      let _ =
        List.fold_left
          (fun (i, trees) (arg, attr) ->
            let st = { st with trees } in
            let _, trees = check_expr st attr [] (var st arg i) in
            (i + 1, trees))
          (0, tmptrees) args
      in
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
      (* We could also deal with frees right here *)
      let _owning, borrow =
        match
          (own_local_borrow ~local:tb trees, own_local_borrow ~local:fb trees)
        with
        | Borrowed t, Borrowed f ->
            (* dedup? *)
            (false, Borrowed (t @ f))
        | Owned, Owned -> (true, Owned)
        | Borrowed _, Owned ->
            raise (Error (cond.loc, prefix ^ "borrowed vs owned"))
        | Owned, Borrowed _ ->
            raise (Error (cond.loc, prefix ^ "owned vs borrowed"))
      in
      let trees = Trst.merge ttrees ftrees in
      (borrow, trees)
  | Field (e, _, name) ->
      (match ac with
      | Dmove when e.attr.const ->
          raise (Error (tyex.loc, "Cannot move out of constant"))
      | _ -> ());
      check_expr st ac (Pfield name :: part) e
  | Function (name, _, abs, cont) ->
      let st = check_abs tyex.loc name abs st in
      check_expr st ac part cont
  | Lambda (_, abs) ->
      let touched = bids_of_touched abs.func.touched st in
      (Borrowed touched, st.trees)
  | Variant_index e ->
      let _, trees = check_expr st ac part e in
      (* Returns an int, so owned value *)
      (Owned, trees)
  | Variant_data e -> check_expr st ac part e
  | Bind (name, expr, cont) ->
      (* In Let expressions, the mut attribute indicates whether the binding is
         mutable. In all other uses (including this one) it refers to the expression.
         Change it to mut = false to be consistent with read only Binds *)
      let bid, ids = Idst.insert name (Some st.mname) st.ids in
      print_endline ("bound bid: " ^ Trst.Id.show bid);
      let trees =
        match check_expr st Dnorm [] expr with
        | Owned, trees -> Trst.insert bid expr.loc Frozen trees
        | Borrowed rhs_ids, trees ->
            let found, trees = Trst.bind bid expr.loc false rhs_ids trees in
            assert found;
            trees
      in
      check_expr { st with trees; ids } ac part cont
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
    | Borrowed _, _trees when pass = Dnorm && lmut ->
        let msg =
          "Specify how rhs expression is passed. Either by move '!' or mutably \
           '&'"
        in
        raise (Error (rhs.loc, msg))
    | Borrowed ids, trees ->
        print_endline
          ("let: " ^ Trst.Id.show bid ^ ": "
          ^ String.concat ", "
              (List.map
                 (fun (id, part, _) ->
                   "(" ^ Trst.Id.show id ^ "@" ^ Trst.Tree.show_part part ^ ")")
                 ids));
        let found, trees = Trst.bind bid loc lmut ids trees in
        assert found;
        trees
  in

  { st with ids; trees }

and bids_of_touched touched st =
  List.map
    (fun touched ->
      print_endline ("touched: " ^ Typed_tree.show_touched touched);
      let bid = Idst.get touched.tname touched.tmname st.ids in
      (bid, [] (* no part *), Some touched.tattr))
    touched

and check_abs loc name abs st =
  let touched = bids_of_touched abs.func.touched st in
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
            let found, trees = Trst.bind bid e.loc false rhs_ids trees in
            assert found;
            trees
      in
      { st with ids; trees }
  | Tl_mutual_rec_decls _ | Tl_module _ | Tl_module_alias _ -> st

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
  Trst.print trees mname;

  (* Ensure no parameter has been moved *)
  Trst.check_borrow_moves trees mname;

  (* Update attribute of touched *)
  List.map
    (fun touched ->
      let bid = Idst.Id.(fst (Pathid.create touched.tname touched.tmname)) in
      let tattr, tattr_loc = Trst.find_touched_attr bid trees in
      (match tattr with
      | Dmove ->
          let loc = tattr_loc and name = touched.tname in
          raise (Error (loc, "Cannot move value " ^ name ^ " from outer scope"))
      | Dset | Dmut | Dnorm -> print_endline "no other");
      { touched with tattr; tattr_loc = Some tattr_loc })
    touched

let check_items ~mname items =
  Trst.reset ();
  List.fold_left (fun st item -> check_item st item) (state_empty mname) items
  |> fun st ->
  (* Ensure no parameter or outer value has been moved *)
  Trst.check_borrow_moves st.trees mname
