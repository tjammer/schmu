module Borrow = struct
  type action = Read | Write
  type action_location = Foreign | Local

  type borrow_state =
    | Reserved
    | Unique
    | Frozen
    | Disabled
    | Reserved_im
    | Owned of { tl : bool; mutated : bool }

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
    | Owned t, (Write, (Local | Foreign)) ->
        Ok (Owned { t with mutated = true }, loc)
    | Owned t, _ -> Ok (Owned t, loc)
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
  val fmt : t -> mname:Path.t -> backup:(t * string) option -> string -> string

  module Pathid : Pathid

  val fst : Pathid.t -> t
  val shadowed : Pathid.t -> int -> t
end

module Make_tree (Id : Id_t) = struct
  type part_kind = Pfield of string | Parr of Typed_tree.expr | Prc
  type part = part_kind list
  type access = { id : Id.t; part : part }
  type loc_info = { lid : access; loc : Ast.loc }
  type mov = Not_moved | Reset | Moved of loc_info

  type mode =
    | (* TODO infer for function types *) Many
    | Once_notused
    | Once_used
    | Unknown of int * bool ref (* Instantiate the bool with true to enable *)

  let rec aux_fmt = function
    | [] -> ""
    | Pfield f :: tl -> "." ^ f ^ aux_fmt tl
    | Parr (Const (Int i)) :: tl -> ".[" ^ Int64.to_string i ^ "]" ^ aux_fmt tl
    | Parr (Var (s, _)) :: tl -> ".[" ^ s ^ "]" ^ aux_fmt tl
    | Parr _ :: tl -> ".[<expr>]" ^ aux_fmt tl
    | Prc :: tl -> ".*" ^ aux_fmt tl

  let string_of_access a mname =
    Id.fmt a.id ~mname ~backup:None (aux_fmt a.part)

  let str_backup access mname backup =
    Id.fmt access.id ~mname
      ~backup:(Some (backup.id, aux_fmt backup.part))
      (aux_fmt access.part)

  type whole = {
    bor : borrow_state * loc_info;
    mov : mov; (* loc: location where the binding was moved *)
    id : access;
    bind_loc : loc_info;
    mode : mode;
    children : whole list;
  }

  and parts = { rest : whole; parts : whole list }
  and t = Twhole of whole | Tparts of parts

  module Path = struct
    type t = { ids : Id.t list; part : part }

    let singleton id = { ids = [ id ]; part = [] }
    let append p id = { p with ids = p.ids @ [ id ] }
  end

  type access_path = { ac : Typed_tree.dattr; path : Path.t }

  let transition_exn bor id bind_loc acc location loc =
    match transition bor (acc, location) loc with
    | Ok state -> state
    | Error `Disabled ->
        let msg =
          Format.sprintf "%s was borrowed in line %i, cannot mutate" id
            (fst bind_loc.loc).pos_lnum
        in
        raise (Error.Error ((snd bor).loc, msg))
    | Error `Frozen ->
        let msg =
          Format.sprintf "%s was borrowed in line %i, cannot mutate frozen" id
            (fst bind_loc.loc).pos_lnum
        in
        raise (Error.Error ((snd bor).loc, msg))

  type contains = Other | Super of part | Sub of part

  let does_contain = function Other -> false | Super _ | Sub _ -> true

  let rec contains_part ~target ~other =
    match (target, other) with
    | [], _ ->
        (* Whole contains all parts *)
        Super target
    | _, [] -> Sub target
    | Pfield t :: target, Pfield o :: other ->
        if String.equal t o then contains_part ~target ~other else Other
    | Parr t :: target, Parr o :: other ->
        if t = o then contains_part ~target ~other else Other
    | Prc :: target, Prc :: other -> contains_part ~target ~other
    | Parr _ :: _, (Pfield _ | Prc) :: _
    | Pfield _ :: _, (Parr _ | Prc) :: _
    | Prc :: _, (Parr _ | Pfield _) :: _ ->
        Other

  let rec part_distance ~target ~other =
    match (target, other) with
    | [], [] -> 0
    | [], _ -> -1 (* Negative means no match *)
    | l, [] -> List.length l
    | Pfield t :: target, Pfield o :: other ->
        if String.equal t o then part_distance ~target ~other else -1
    | Parr t :: target, Parr o :: other ->
        if t = o then part_distance ~target ~other else -1
    | Prc :: target, Prc :: other -> part_distance ~target ~other
    | Parr _ :: _, (Pfield _ | Prc) :: _
    | Pfield _ :: _, (Parr _ | Prc) :: _
    | Prc :: _, (Parr _ | Pfield _) :: _ ->
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
            Tparts { rest; parts = { candidate with id } :: parts }
    in

    (* Second, we need to traverse all paths. Local borrows are only the correct
       part. *)
    let rec traverse correct_part contains_part path acc whole =
      if does_contain contains_part then
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
                ~contains_part ~correct_part acc whole
        | _ ->
            foreign
              ~down:(traverse correct_part contains_part [])
              ~contains_part ~correct_part acc whole
      else (acc, whole)
    in

    let dist item = part_distance ~target:path.part ~other:item.id.part in
    let contains item = contains_part ~target:path.part ~other:item.id.part in
    match tree with
    | Twhole item ->
        let acc, item = traverse true (Super []) path.ids acc item in
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

  let borrow access loc use_mode mname tree =
    let foreign ~down ~contains_part ~correct_part found item =
      let mov =
        match contains_part with
        | Super part | Sub part -> (
            let rs lc =
              let access = { id = item.id.id; part } in
              let msg =
                Format.sprintf "%s was moved in line %i, cannot use %s"
                  (str_backup item.id mname lc.lid)
                  (fst lc.loc).pos_lnum
                  (str_backup access mname lc.lid)
              in
              raise (Error.Error (loc.loc, msg))
            in
            match (item.mov, access.ac) with
            | Moved lc, (Ast.Dmove | Dmut | Dnorm) ->
                (* Our item has been moved *)
                rs lc
            | Moved lc, Dset -> (
                if correct_part then Reset
                else
                  match contains_part with
                  | Sub _ -> rs lc
                  | Super _ | Other -> Reset)
            | (Not_moved | Reset), _ -> item.mov)
        | Other -> item.mov
      in

      let bor =
        (* Needed for tracking mutations *)
        let is_owned = match fst item.bor with Owned _ -> true | _ -> false in
        if correct_part || is_owned then
          let access =
            match access.ac with Dmove | Dnorm -> Read | Dmut | Dset -> Write
          in
          let id = string_of_access item.bind_loc.lid mname in
          transition_exn item.bor id item.bind_loc access Foreign loc
        else item.bor
      in
      let found, children =
        List.fold_left_map
          (fun found tree -> down found tree)
          found item.children
      in
      (found, { item with bor; children; mov })
    in

    let local ~down ~ends found item =
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
        | (Not_moved | Reset), Dmove -> (Moved loc, Read)
      in
      let id = string_of_access item.bind_loc.lid mname in
      let bor = transition_exn item.bor id item.bind_loc access Local loc in
      let mode =
        if ends then
          match item.mode with
          | Once_notused ->
              (match use_mode with
              | Types.Many ->
                  let id = string_of_access item.id mname in
                  let msg = "Cannot pass once value " ^ id ^ " as many" in
                  raise (Error.Error (loc.loc, msg))
              | Once -> ());
              Once_used
          | Once_used ->
              let msg =
                Format.sprintf "Cannot use %s more than once"
                  (string_of_access { item.id with part = [] } mname)
              in
              raise (Error.Error (loc.loc, msg))
          | Many -> Many
          | Unknown (i, rf) -> (
              match use_mode with
              | Many ->
                  (* Ensure the value is used more than once *)
                  Unknown (i + 2, rf)
              | Once -> Unknown (i + 1, rf))
        else item.mode
      in
      let found, children =
        List.fold_left_map
          (fun found tree -> down found tree)
          (ends || found) item.children
      in
      (found, { item with bor; children; mov; mode })
    in

    fold ~local ~foreign access.path false tree

  let bind id bind_loc lmut mov mode path tree =
    (* Only bind, i.e. add the child to the bound thing. Checking if the binding
       is legal has to have happened before. *)
    let foreign ~down:_ ~contains_part:_ ~correct_part:_ found item =
      (found, item)
    in
    let local ~down ~ends found item =
      let found, children =
        if ends then
          let bor = if lmut then (Reserved, bind_loc) else (Frozen, bind_loc)
          and id = { id; part = [] }
          and children = [] in

          (true, { bor; mov; id; bind_loc; children; mode } :: item.children)
        else
          List.fold_left_map
            (fun found tree -> down found tree)
            found item.children
      in
      (found, { item with children })
    in

    fold ~local ~foreign path false tree

  module Whole_key = struct
    type t = access

    let compare l r = Stdlib.compare l r
  end

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
        | Owned _ -> -1
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
      let base =
        match pick_mov l.mov r.mov with
        | `Left -> l
        | `Right -> r
        | `Either -> (
            match pick_bor l.bor r.bor with `Left -> l | `Right -> r)
      in
      let mode =
        match (l.mode, r.mode) with
        | Unknown (l, lrf), Unknown (r, rrf) ->
            assert (lrf == rrf);
            let i =
              (* If the value has been moved more than once it cannot be Once.
                 Keep this state *)
              if l > 1 then l else if r > 1 then r else Int.min l r
            in
            Unknown (i, lrf)
        | Once_notused, Once_notused | Once_used, Once_used | Many, Many ->
            l.mode
        | _ -> failwith "Internal Error: Unexpected mode mismatch"
      in
      { base with mode }
    in
    match (l, r) with
    | Twhole l, Twhole r ->
        assert (Id.equal l.id.id r.id.id);
        Twhole (merge_whole l r)
    | Twhole l, Tparts { rest; parts } ->
        Tparts { rest = merge_whole l rest; parts }
    | Tparts { rest; parts }, Twhole l ->
        Tparts { rest = merge_whole rest l; parts }
    | Tparts l, Tparts r ->
        let module Wholemap = Map.Make (Whole_key) in
        let ml =
          List.to_seq l.parts
          |> Seq.map (fun whole -> (whole.id, whole))
          |> Wholemap.of_seq
        in
        let mr =
          List.to_seq r.parts
          |> Seq.map (fun whole -> (whole.id, whole))
          |> Wholemap.of_seq
        in

        let merged =
          Wholemap.merge
            (fun _ l r ->
              match (l, r) with
              | Some _, None -> l
              | None, Some _ -> r
              | None, None -> failwith "unreachable"
              | Some l, Some r -> Some (merge_whole l r))
            ml mr
        in
        let parts = Wholemap.to_seq merged |> Seq.map snd |> List.of_seq in
        Tparts { rest = merge_whole l.rest r.rest; parts }
end

module Make_storage (Id : Id_t) = struct
  module Id = Id
  module Id_map = Map.Make (Id)
  module Index_map = Map.Make (Int)
  module Tree = Make_tree (Id)

  type on_call = {
    attr : Ast.decl_attr;
    on_move : Types.closed option;
        (* Either Dnorm or moved with variable info to build a move expression.
           Dmove is implicit, then *)
  }

  type borrowed = {
    id : Id.t;
    part : Tree.part;
    oncall : on_call option;
    cond_borrow : bool;
  }

  type index = { ipath : Tree.Path.t; index : int; call_attr : on_call option }
  type indices = { is : index list; cond_borrow : bool }
  type t = { indices : indices Id_map.t; trees : Tree.t Index_map.t }

  let empty = { indices = Id_map.empty; trees = Index_map.empty }
  let id = ref 0
  let reset () = id := 0

  let fresh () =
    incr id;
    !id

  let get_mode = function
    | `Once -> Tree.Once_notused
    | `Many -> Many
    | `Unknown rf -> Unknown (0, rf)

  let insert id bind_loc bor mode st =
    (* assert (Id_map.mem id st.indices |> not); *)
    let i = fresh () in
    let loc_info = { Tree.lid = { id; part = [] }; loc = bind_loc } in
    let bor = (bor, loc_info) and mov = Tree.Not_moved in
    let mode = get_mode mode in

    let trees =
      let id = Tree.{ id; part = [] } and bind_loc = loc_info in
      Index_map.add i
        (Tree.Twhole { bor; mov; id; bind_loc; children = []; mode })
        st.trees
    in
    let index =
      let ipath = Tree.Path.singleton id and call_attr = None in
      { is = [ { ipath; index = i; call_attr } ]; cond_borrow = false }
    in
    let indices = Id_map.add id index st.indices in
    { trees; indices }

  let oncall_ac ~oncall ac =
    match ac with
    | Ast.Dnorm -> `Other oncall.attr
    | Dmove -> `Moved oncall.on_move
    | Dset | Dmut -> failwith "unreachable"

  let rec borrow id loc mname (ac, mode) part st =
    match Id_map.find_opt id st.indices with
    | Some inds ->
        (* forbid conditional borrow (see unit test) *)
        (match ac with
        | Ast.Dmove when inds.cond_borrow ->
            let msg =
              "Cannot move conditional borrow. Either copy or directly move \
               conditional without borrowing"
            in
            raise (Error.Error (loc, msg))
        | _ -> ());
        (* borrow *)
        let found, moved, trees =
          List.fold_left
            (fun (found, moved, trees) { ipath; index; call_attr } ->
              let ac, moved =
                match call_attr with
                | Some oncall -> (
                    match oncall_ac ~oncall ac with
                    | `Moved None -> (Ast.Dnorm, moved)
                    | `Moved (Some c) -> (Dmove, c :: moved)
                    | `Other ac -> (ac, moved))
                | None -> (ac, moved)
              in
              let path = Tree.Path.{ ipath with part = ipath.part @ part } in
              let nfound, tree =
                Tree.borrow { ac; path }
                  { lid = { id; part = [] }; loc }
                  mode mname
                  (Index_map.find index trees)
              in
              (found && nfound, moved, Index_map.add index tree st.trees))
            (true, [], st.trees) inds.is
        in
        (found, moved, { st with trees })
    | None ->
        (* If the item has not been found, add it as a new, borrowed item. This will
           cause it to not be moved. *)
        insert id loc Frozen `Many st |> borrow id loc mname (ac, mode) part

  let lmut_of_attr = function
    | { attr = Ast.Dmut | Dset; _ } -> true
    | { attr = Dnorm | Dmove; _ } -> false

  let bind id loc lmut mode bounds st =
    let bind_inner bound part attr (found, trees) { ipath; index; call_attr } =
      let loc = { Tree.lid = { id = bound; part }; loc } in
      let path = Tree.Path.{ ipath with part = ipath.part @ part } in
      let lmut, call_attr, mov =
        match attr with
        (* If there is an attribute, it's from a touched variable of a
           function. We use this to set the correct borrow state for
           this borrow. *)
        (* Any borrowed function will get the Reset move state so it's not
           reported as not mutated. *)
        | Some attr' -> (lmut_of_attr attr', attr, Tree.Reset)
        | None -> (
            match call_attr with
            | Some attr -> (lmut_of_attr attr, call_attr, Reset)
            | None -> (lmut, call_attr, Not_moved))
      in
      let mode = get_mode mode in
      let nfound, tree =
        Tree.bind id loc lmut mov mode path (Index_map.find index trees)
      in
      let trees = Index_map.add index tree trees
      and ipath = Tree.Path.append path id in
      ((found && nfound, trees), { ipath; index; call_attr })
    in

    let add_indices id indices st_indices =
      match Id_map.find_opt id st_indices with
      | None -> Id_map.add id indices st_indices
      | Some other ->
          let cond_borrow = other.cond_borrow || indices.cond_borrow in
          Id_map.add id { is = other.is @ indices.is; cond_borrow } st_indices
    in

    let aux { id = bound; part; oncall; cond_borrow } st =
      match Id_map.find_opt bound st.indices with
      | Some inds ->
          let (found, trees), is =
            List.fold_left_map
              (bind_inner bound part oncall)
              (true, st.trees) inds.is
          in
          let indices = add_indices id { is; cond_borrow } st.indices in
          (found, { indices; trees })
      | None -> (false, st)
    in

    (* We are not allowed to touch existing bindings, so we remove every old
       one. Due to the fact that we push trees with their id entries upward but
       keep the shadow ids lexical, we see entries which don't belong to the
       current scope. To remedy this, let's just remove the current bind target
       before writing. A nicer solution would be keepeing a lexical discipline
       for the id part of this tree storage also, but this would require
       changing all expressions. *)
    let st = { st with indices = Id_map.remove id st.indices } in

    match bounds with
    | [] ->
        let bor = if lmut then Reserved else Frozen in
        (true, insert id loc bor mode st)
    | bounds ->
        List.fold_left
          (fun (found, st) bound ->
            let nfound, st = aux bound st in
            (found && nfound, st))
          (true, st) bounds

  let insert_string_literal id bind_loc bor st =
    (* If it doesn't exist then insert. Else update bind_loc *)
    match Id_map.find_opt id st.indices with
    | Some { is = [ _ ]; _ } ->
        let indices = Id_map.remove id st.indices in
        insert id bind_loc bor `Many { st with indices }
    | Some _ -> failwith "Is this not a string lateral"
    | None -> insert id bind_loc bor `Many st

  let rec part_contains_array = function
    | [] -> false
    | Tree.(Pfield _ | Prc) :: tl -> part_contains_array tl
    | Parr _ :: _ -> true

  let check_moves st mname =
    let unmutated = ref [] in
    let rec check_move ~owned ~tl id loc tree =
      (* Catch unmutated bindings *)
      (match Tree.(tree.bor) |> fst with
      | Owned { mutated = false; _ } ->
          unmutated := tree.bind_loc.loc :: !unmutated
      | Reserved -> (
          match tree.mov with
          | Reset -> ()
          | Moved _ | Not_moved -> unmutated := tree.bind_loc.loc :: !unmutated)
      | _ -> ());

      (match tree.mode with
      | Tree.Once_notused ->
          let msg =
            Format.sprintf "Value %s has not been used once"
              Tree.(string_of_access tree.id mname)
          in
          raise (Error.Error (loc, msg))
      | Once_used | Many -> ()
      | Unknown (1, _) -> ()
      | Unknown (_, rf) -> rf := false);

      match Tree.(tree.mov) with
      | Moved l -> (
          let r msg = raise (Error.Error (loc, msg)) in
          if owned && tl then r "Cannot move top level binding"
          else if part_contains_array tree.id.part then
            r "Cannot move out of array without re-setting"
          else if not owned then
            let pos = Tree.(fst l.loc).pos_lnum in
            match Tree.string_of_access id mname with
            | "string literal" as s ->
                r (Format.sprintf "Borrowed %s has been moved in line %i" s pos)
            | s ->
                r
                  (Format.sprintf "Borrowed value %s has been moved in line %i"
                     s pos))
      | Not_moved | Reset ->
          List.iter (check_move ~tl ~owned id loc) tree.children
    in
    Index_map.iter
      (fun _ -> function
        | Tree.Twhole tree -> (
            match tree.bor |> fst with
            | Owned { tl; mutated = _ } (* top level *) ->
                (check_move ~owned:true ~tl tree.id tree.bind_loc.loc) tree
            | _ ->
                (check_move ~owned:false ~tl:false tree.id tree.bind_loc.loc)
                  tree)
        | Tparts { rest; parts } -> (
            match rest.bor |> fst with
            | Owned { tl; mutated = _ } (* top level *) ->
                (check_move ~owned:true ~tl rest.id rest.bind_loc.loc) rest;
                List.iter
                  (fun (tree : Tree.whole) ->
                    (check_move ~owned:true ~tl tree.id tree.bind_loc.loc) tree)
                  parts
            | _ ->
                (check_move ~owned:false ~tl:false rest.id rest.bind_loc.loc)
                  rest;
                List.iter
                  (fun (tree : Tree.whole) ->
                    (check_move ~owned:false ~tl:false tree.id tree.bind_loc.loc)
                      tree)
                  parts))
      st.trees;
    !unmutated

  let find_touched_attr id st =
    let attr_of_item (i : Tree.whole) =
      match i.mov with
      | Moved loc -> (Ast.Dmove, loc.loc)
      | Reset -> (Dset, (snd i.bor).loc)
      | _ -> (
          match fst i.bor with
          | Reserved -> (Dnorm, (snd i.bor).loc)
          | Unique -> (Dmut, (snd i.bor).loc)
          | _ -> failwith "Internal Error: What is this touched")
    in

    let merge_attr a b =
      match (fst a, fst b) with
      | Ast.Dmove, _ -> a
      | _, Ast.Dmove -> b
      | Dset, _ -> a
      | _, Dset -> b
      | Dmut, _ -> a
      | _, Dmut -> b
      | _, _ -> a
    in

    let index = Id_map.find id st.indices in
    match index with
    | { is = { index; _ } :: []; _ } -> (
        match Index_map.find index st.trees with
        | Tree.Twhole w -> attr_of_item w
        | Tparts { rest; parts } ->
            List.fold_left
              (fun attr item -> merge_attr attr (attr_of_item item))
              (attr_of_item rest) parts)
    | _ -> failwith "Internal Error: Touched thing has mutiple borrows"

  let mem id st = Id_map.mem id st.indices

  let merge l r =
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
    { l with trees }

  let update ~old nu = { old with trees = nu.trees }
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
    | None -> Id.shadowed id 0
    | Some 1 -> Id.fst id
    | Some i -> Id.shadowed id (i - 1)
end

module Id = struct
  module Pathid = struct
    type t = string * Path.t option

    let create s p = (s, p)

    let show (s, p) =
      match p with Some p -> Path.show (Path.append s p) | None -> s

    let pp ppf p = Format.fprintf ppf "%s" (show p)

    let equal (a, ap) (b, bp) =
      match (ap, bp) with
      | Some ap, Some bp -> String.equal a b && Path.equal ap bp
      | None, None -> String.equal a b
      | None, Some _ | Some _, None -> false

    let compare (a, ap) (b, bp) =
      match (ap, bp) with
      | Some ap, Some bp ->
          let c = String.compare a b in
          if c == 0 then Path.compare ap bp else c
      | None, None -> String.compare a b
      | None, Some _ | Some _, None -> Stdlib.compare (a, ap) (b, bp)

    let startswith ~prefix (a, _) = String.starts_with ~prefix a
  end

  type t = Fst of Pathid.t | Shadowed of Pathid.t * int [@@deriving show]

  let fst id = Fst id
  let shadowed id i = Shadowed (id, i)
  let compare a b = Stdlib.compare a b

  let equal a b =
    match (a, b) with
    | Fst a, Fst b -> Pathid.equal a b
    | Shadowed (a, ai), Shadowed (b, bi) ->
        let c = Pathid.equal a b in
        if c then Int.equal ai bi else c
    | Fst _, Shadowed _ | Shadowed _, Fst _ -> false

  let rec fmt s ~mname ~backup part =
    let name = match s with Fst s -> s | Shadowed (s, _) -> s in
    let f (name, p) =
      match p with
      | Some p -> Path.(rm_name mname (append name p) |> show)
      | None -> name
    in
    match backup with
    | Some (id, bkpart) ->
        if Pathid.startswith ~prefix:"__expr" name then
          fmt id ~mname ~backup:None bkpart
        else f name ^ part
    | None -> f name ^ part

  let only_id = function Fst (id, _) -> id | Shadowed ((id, _), _) -> id
end

(* Tree storage *)
module Trst = Make_storage (Id)

(* Id storage *)
module Idst = Make_ids (Id)
open Types
open Typed_tree
open Error

type state = { trees : Trst.t; ids : Idst.t; mname : Path.t }
type let_context = Cexpr | Clet | Ctl_let

let state_empty mname loc =
  let id = Idst.get "string literal" (Some mname) Idst.empty in
  let trees = Trst.insert id loc Frozen `Many Trst.empty in
  { trees; ids = Idst.empty; mname }

type borrowed = Trst.borrowed = {
  id : Trst.Id.t;
  part : Trst.Tree.part;
  oncall : Trst.on_call option;
  cond_borrow : bool;
}

type borrow_ids = Owned | Borrowed of borrowed list

let was_moved bs st =
  let open Trst in
  match bs with
  | Owned -> Snot_moved
  | Borrowed [ { id; part; _ } ] ->
      let open Tree in
      let foreign ~down ~contains_part ~correct_part:_ moved item =
        let moved =
          match contains_part with
          | Super _ -> (
              match item.mov with
              | Moved _ ->
                  let moved =
                    match moved with
                    | Snot_moved | Spartially_moved -> Spartially_moved
                    | Smoved -> Smoved
                  in
                  List.fold_left
                    (fun moved tree -> down moved tree |> fst)
                    moved item.children
              | _ -> moved)
          | Sub _ -> (
              match item.mov with
              | Moved _ -> (
                  match moved with
                  | Snot_moved -> Smoved
                  | Smoved | Spartially_moved -> Smoved)
              | _ -> moved)
          | Other -> moved
        in
        (moved, item)
      in
      let local ~down ~ends:_ moved item =
        let moved =
          match (item.mov, moved) with
          | Moved _, _ -> Smoved
          | _, Smoved -> Smoved
          | _ ->
              List.fold_left
                (fun moved tree -> down moved tree |> fst)
                moved item.children
        in
        (moved, item)
      in
      let indices = Id_map.find id st.indices in
      List.fold_left
        (fun acc idx ->
          match acc with
          | Smoved -> acc
          | _ ->
              let path = { idx.ipath with part = idx.ipath.part @ part } in
              let tree = Index_map.find idx.index st.trees in
              fold ~foreign ~local path acc tree |> fst)
        Snot_moved indices.is
  | Borrowed _ -> failwith "TODO multiple borrows"

let own_local_borrow ~local old_tree =
  (* local borrow means it's actually owned *)
  (* Open questions: *)
  (* What about string literals *)
  (* What about new borrow ids to old items? Could check not id directly but
     id's tree*)
  let rec aux = function
    | [] -> local
    | { id; _ } :: tl -> if Trst.mem id old_tree then aux tl else Owned
  in
  match local with Owned -> Owned | Borrowed bs -> aux bs

let cond_move typ = if Types.contains_allocation typ then Dmove else Dnorm

let get_closed_usage kind (touched : touched) =
  let on_move =
    match kind with
    | Closure cls -> (
        match
          List.find_opt (fun c -> String.equal c.clname touched.tname) cls
        with
        | Some c -> (
            if c.clcopy then None
            else if c.clmut then Some c
            else
              (* Move the closed variable into the closure *)
              match cond_move c.cltyp with Dmove -> Some c | _ -> None)
        | None ->
            (* Touched bit not closed? Let's read it *)
            None)
    | Simple -> None
  in
  Trst.{ attr = touched.tattr; on_move }

let let_mode_borrow = function
  | `Many -> Types.Many
  | `Once -> Once
  | `Arg -> Once

let let_mode_bind = function `Many -> `Many | `Once -> `Once | `Arg -> `Many
let let_mode = function Types.Many -> `Many | Once -> `Once

let rec move_closure ex = function
  | [] -> ex
  | c :: tl ->
      let var =
        {
          loc = ex.loc;
          typ = c.cltyp;
          attr = no_attr;
          expr = Var (c.clname, c.clmname);
        }
      in
      let move = { var with expr = Move var } in
      move_closure { ex with expr = Sequence (move, ex) } tl

let rec check_expr st ac part ctx tyex =
  (* Pass trees back up the typed tree, because we need to maintain its state.
     Ids on the other hand follow lexical scope *)
  match tyex.expr with
  | Const (String _) ->
      let id = Idst.get "string literal" (Some st.mname) st.ids in
      let trees = Trst.insert_string_literal id tyex.loc Frozen st.trees in
      let found, _, trees = Trst.borrow id tyex.loc st.mname ac [] trees in
      assert found;
      let part = [] and oncall = None and cond_borrow = false in
      (tyex, Borrowed [ { id; part; oncall; cond_borrow } ], trees)
  | Const (Array items) ->
      let trees, items =
        List.fold_left_map
          (fun trees e ->
            let e, _, trees =
              check_expr { st with trees } (cond_move e.typ, snd ac) [] Cexpr e
            in
            (trees, { e with expr = Move e }))
          st.trees items
      in
      let expr = Const (Array items) in
      ({ tyex with expr }, Owned, trees)
  | Const (Fixed_array es) ->
      let trees, es =
        List.fold_left_map
          (fun trees e ->
            let e, _, trees =
              check_expr { st with trees } (cond_move e.typ, snd ac) [] Cexpr e
            in

            (trees, { e with expr = Move e }))
          st.trees es
      in
      let expr = Const (Fixed_array es) in
      ({ tyex with expr }, Owned, trees)
  | Const _ -> (tyex, Owned, st.trees)
  | Var (str, mname) ->
      let id = Idst.get str mname st.ids in
      let ac =
        match ac with Dmove, _ -> (cond_move tyex.typ, snd ac) | _ -> ac
      in
      let found, moved, trees =
        Trst.borrow id tyex.loc st.mname ac part st.trees
      in

      let ex = move_closure tyex moved in

      (* Moved borrows don't return a borrow id *)
      if not (fst ac = Dmove && found) then
        let oncall = None and cond_borrow = false in
        (ex, Borrowed [ { id; part; oncall; cond_borrow } ], trees)
      else (ex, Owned, trees)
  | App
      {
        callee =
          { expr = Var (("__array_get" | "__fixed_array_get"), _); _ } as callee;
        args = [ arr; idx ];
      } ->
      let callee, _, trees = check_expr st (Dnorm, Once) [] Cexpr callee in
      let fidx, _, trees =
        check_expr { st with trees } (snd idx, Once) [] Cexpr (fst idx)
      in
      let farr, bs, trees =
        check_expr { st with trees } ac
          (Parr (fst idx).expr :: part)
          Cexpr (fst arr)
      in
      let expr = App { callee; args = [ (farr, snd arr); (fidx, snd idx) ] } in
      ({ tyex with expr }, bs, trees)
  | App
      {
        callee =
          ( { expr = Var ("__unsafe_ptr_get", _); _ }
          | { expr = Var ("get", Some (Path.Pid "unsafe")); _ } ) as callee;
        args = [ arr; idx ];
      } ->
      let _, _, trees = check_expr st (Dnorm, Once) [] Cexpr callee in
      let _, _, trees =
        check_expr { st with trees } (snd idx, Once) [] Cexpr (fst idx)
      in
      let _, bs, trees = check_expr { st with trees } ac part Cexpr (fst arr) in
      (tyex, bs, trees)
  | App
      {
        callee =
          ( { expr = Var ("__unsafe_rc_get", _); _ }
          | { expr = Var ("get", Some (Pid "rc")); _ } ) as callee;
        args = [ arg ];
      } ->
      let callee, _, trees = check_expr st (Dnorm, Once) [] Cexpr callee in
      let farg, bs, trees =
        check_expr { st with trees } ac (Prc :: part) Cexpr (fst arg)
      in
      let expr = App { callee; args = [ (farg, snd arg) ] } in
      ({ tyex with expr }, bs, trees)
  | App { callee; args } ->
      (* Borrow-returns are only allowed in expression context *)
      (match ctx with
      | Clet when Subscript.is_borrow_call callee.expr ->
          raise
            (Error
               ( tyex.loc,
                 "Cannot borrow from function call in let binding. Use let \
                  borrow form (let _ <- app)" ))
      | Ctl_let when Subscript.is_borrow_call callee.expr ->
          raise (Error (tyex.loc, "Cannot return borrow at top level"))
      | _ -> ());

      let ncallee, _, callee_trees =
        check_expr st (Dnorm, Once) [] Cexpr callee
      in
      let args =
        (* Add modes to args *)
        match repr callee.typ with
        | Tfun (ps, _, _) ->
            List.map2 (fun p (arg, attr) -> (arg, attr, p.pmode)) ps args
        | _ -> failwith "Internal Error: Unexpected non-function"
      in

      (* Create temporary bindings for each passed thing *)
      (* No kebab-case allowed for user code, no clashes *)
      let id_i i = "borrow-arg-" ^ string_of_int i in
      let var st arg i = { arg with expr = Var (id_i i, Some st.mname) } in
      (* While inferring the mode, we simple use [Many] for unknown modes *)
      let rec use_mode attr mode =
        match (mode, attr) with
        | _, Dmove -> Many
        | Iknown m, _ -> m
        | Iunknown, _ -> Once
        | Ilinked { contents = m }, _ -> use_mode attr m
      in
      let (_, tmpstate, trees), nargs =
        List.fold_left_map
          (fun (i, tmpstate, trees) (arg, attr, mode) ->
            let mode = use_mode attr !mode in
            let ac =
              match attr with
              | Dmove -> (cond_move arg.typ, mode)
              | _ -> (attr, mode)
            in
            let narg, _bs, trees =
              check_expr { st with trees } ac [] Cexpr arg
            in
            let narg =
              match fst ac with
              | Dmove -> { narg with expr = Move narg }
              | _ -> narg
            in
            let id = id_i i in

            let lmut =
              match attr with Dmut | Dset -> true | Dnorm | Dmove -> false
            in
            let _, _, tmpstate =
              check_let tmpstate ~toplevel:false id arg.loc attr lmut `Arg arg
            in
            ((i + 1, tmpstate, trees), (narg, attr)))
          (0, st, callee_trees) args
      in
      (* Borrow callee + args again *)
      let _, _, tmptrees = check_expr tmpstate (Dnorm, Once) [] Cexpr callee in
      let _ =
        List.fold_left
          (fun (i, trees) (arg, attr, mode) ->
            let mode = use_mode attr !mode in
            let st = { tmpstate with trees } in
            let _, _, trees =
              check_expr st (attr, mode) [] Cexpr (var st arg i)
            in
            (i + 1, trees))
          (0, tmptrees) args
      in
      let expr = App { callee = ncallee; args = nargs } in
      ({ tyex with expr }, Owned, trees)
  | Set (expr, value, _) ->
      let value, _, trees =
        check_expr st (cond_move value.typ, Once) [] Cexpr value
      in
      let expr, bs, rettrees =
        check_expr { st with trees } (Dset, Once) [] Cexpr expr
      in
      let value = { value with expr = Move value } in
      let was_moved = was_moved bs trees in
      ({ tyex with expr = Set (expr, value, was_moved) }, Owned, rettrees)
  | Let ({ id; lmut; pass; rhs; cont; id_loc; mode; _ } as lt) ->
      let rhs, pass, st =
        check_let st ~toplevel:false id id_loc pass lmut (let_mode mode) rhs
      in
      let cont, bs, trees = check_expr st ac part ctx cont in
      let expr = Let { lt with rhs; cont; pass } in
      ({ tyex with expr }, bs, trees)
  | Sequence (fst, snd) ->
      let fst, _, trees = check_expr st (Dnorm, Once) [] Cexpr fst in
      let trees = Trst.update ~old:st.trees trees in
      let snd, bs, trees = check_expr { st with trees } ac part ctx snd in
      ({ tyex with expr = Sequence (fst, snd) }, bs, trees)
  | Record es ->
      let trees, es =
        List.fold_left_map
          (fun trees (s, e) ->
            let e, _, trees =
              check_expr { st with trees } (cond_move e.typ, snd ac) [] Cexpr e
            in
            (trees, (s, { e with expr = Move e })))
          st.trees es
      in
      ({ tyex with expr = Record es }, Owned, trees)
  | If (cond, _, t, f) ->
      let cond, _, trees = check_expr st (Dnorm, Once) [] Cexpr cond in
      let t, tb, ttrees = check_expr { st with trees } ac part ctx t in
      let f, fb, ftrees = check_expr { st with trees } ac part ctx f in
      let prefix = "Branches have different ownership: " in
      (* We could also deal with frees right here *)
      let owning, borrow =
        match
          (own_local_borrow ~local:tb trees, own_local_borrow ~local:fb trees)
        with
        | Borrowed t, Borrowed f ->
            (* dedup? *)
            let bs =
              List.map
                (fun { id; part; oncall; _ } ->
                  { id; part; oncall; cond_borrow = true })
                (t @ f)
            in
            (false, Borrowed bs)
        | Owned, Owned -> (true, Owned)
        | Borrowed _, Owned ->
            if contains_allocation t.typ then
              raise (Error (cond.loc, prefix ^ "borrowed vs owned"))
            else (true, Owned)
        | Owned, Borrowed _ ->
            if contains_allocation f.typ then
              raise (Error (cond.loc, prefix ^ "owned vs borrowed"))
            else (true, Owned)
      in
      let trees = Trst.(update ~old:st.trees (merge ttrees ftrees)) in
      let expr = If (cond, Some owning, t, f) in
      ({ tyex with expr }, borrow, trees)
  | Field (e, i, name) ->
      (match fst ac with
      | Dmove when e.attr.const ->
          raise (Error (tyex.loc, "Cannot move out of constant"))
      | _ -> ());
      let e, bs, trees = check_expr st ac (Pfield name :: part) Cexpr e in
      ({ tyex with expr = Field (e, i, name) }, bs, trees)
  | Function (name, i, abs, cont) ->
      let st = check_abs tyex.loc name abs false st in
      let cont, bs, trees = check_expr st ac part ctx cont in
      let expr = Function (name, i, abs, cont) in
      ({ tyex with expr }, bs, trees)
  | Lambda (_, abs) -> (
      let touched = bids_of_touched abs.func.touched abs.func.kind st in
      match fst ac with
      | Dmove ->
          let trees, moved =
            List.fold_left
              (fun (trees, moved) { id; oncall = usage; _ } ->
                let ac, moved =
                  match usage with
                  | Some oncall -> (
                      match Trst.(oncall.on_move) with
                      | Some c -> (Dmove, c :: moved)
                      | None -> (Dnorm, moved))
                  | None -> (Dmove, moved)
                in
                let found, _, trees =
                  Trst.borrow id tyex.loc st.mname (ac, Once) [] trees
                in
                assert found;
                (trees, moved))
              (st.trees, []) touched
          in
          let ex = move_closure tyex moved in
          let trees = Trst.update ~old:st.trees trees in
          (ex, Owned, trees)
      | _ -> (tyex, Borrowed touched, st.trees))
  | Ctor (s, i, e) -> (
      match e with
      | Some e ->
          let e, _, trees =
            check_expr st (cond_move e.typ, snd ac) [] Cexpr e
          in
          let e = { e with expr = Move e } in
          ({ tyex with expr = Ctor (s, i, Some e) }, Owned, trees)
      | None -> (tyex, Owned, st.trees))
  | Variant_index e ->
      let e, _, trees = check_expr st ac part Cexpr e in
      (* Returns an int, so owned value *)
      ({ tyex with expr = Variant_index e }, Owned, trees)
  | Variant_data e ->
      let e, bs, trees = check_expr st ac part Cexpr e in
      ({ tyex with expr = Variant_data e }, bs, trees)
  | Bind (name, expr, cont) ->
      (* In Let expressions, the mut attribute indicates whether the binding is
         mutable. In all other uses (including this one) it refers to the expression.
         Change it to mut = false to be consistent with read only Binds *)
      let bid, ids = Idst.insert name (Some st.mname) st.ids in
      let expr, trees =
        match check_expr st (Dnorm, Once) [] Cexpr expr with
        | expr, Owned, trees ->
            ( expr,
              Trst.insert bid expr.loc
                (Owned { tl = false; mutated = false })
                `Many trees )
        | expr, Borrowed rhs_ids, trees ->
            let lmut = expr.attr.mut in
            let found, trees =
              Trst.bind bid expr.loc lmut `Many rhs_ids trees
            in
            assert found;
            (expr, trees)
      in
      let cont, bs, trees =
        check_expr { st with trees; ids } ac part Cexpr cont
      in
      ({ tyex with expr = Bind (name, expr, cont) }, bs, trees)
  | Bop (op, fst, snd) ->
      let fst, _, trees = check_expr st (Dnorm, Once) [] Cexpr fst in
      let snd, _, trees =
        check_expr { st with trees } (Dnorm, Once) [] Cexpr snd
      in
      ({ tyex with expr = Bop (op, fst, snd) }, Owned, trees)
  | Unop (op, e) ->
      let e, _, trees = check_expr st (Dnorm, Once) [] Cexpr e in
      ({ tyex with expr = Unop (op, e) }, Owned, trees)
  | Mutual_rec_decls (ds, cont) ->
      let cont, bs, trees = check_expr st ac part ctx cont in
      ({ tyex with expr = Mutual_rec_decls (ds, cont) }, bs, trees)
  | Move _ -> failwith "Internal Error: Move in borrows"

and check_let st ~toplevel str loc pass lmut mode rhs =
  let tl = toplevel in
  (match pass with
  | Dmut when toplevel -> raise (Error (rhs.loc, "Cannot project at top level"))
  | Dmut when not rhs.attr.mut ->
      raise (Error (rhs.loc, "Cannot project immutable binding"))
  | _ -> ());
  let bid, ids = Idst.insert str (Some st.mname) st.ids in
  let ctx = if toplevel then Ctl_let else Clet in
  let rhs, pass, trees =
    match check_expr st (pass, let_mode_borrow mode) [] ctx rhs with
    | rhs, Owned, trees ->
        (* Nothing is borrowed, we own this *)
        let pass =
          match pass with
          | Dmut when lmut ->
              (* This one is subtle. Function calls return on owned value. For
                 our special cases like __unsafe_ptr_get that's true as well.
                 However, we cannot [Dmove] the return value of __unsafe_ptr_get
                 in the case of lmut = true because it might be a projection.
                 This special case here is okay because the builtin_hack
                 function in typing.ml ensures projecting these values is only
                 valid for our special cased functions. *)
              pass
          | _ -> if lmut then Dmove else pass
        in
        ( rhs,
          pass,
          Trst.insert bid loc
            (Owned { tl; mutated = not lmut })
            (let_mode_bind mode) trees )
    | rhs, Borrowed _, trees when pass = Dmove ->
        (* Transfer ownership *)
        ( rhs,
          Dmove,
          Trst.insert bid loc
            (Owned { tl; mutated = not lmut })
            (let_mode_bind mode) trees )
    | _, Borrowed _, _trees when pass = Dnorm && lmut ->
        let msg =
          "Specify how rhs expression is passed. Either by move '!' or mutably \
           '&'"
        in
        raise (Error (rhs.loc, msg))
    | rhs, Borrowed ids, trees ->
        if toplevel && rhs.attr.mut then
          raise (Error (rhs.loc, "Cannot borrow mutable binding at top level"))
        else
          let _, trees =
            Trst.bind bid loc lmut (let_mode_bind mode) ids trees
          in
          (* assert found; *)
          (rhs, pass, trees)
  in

  let rhs =
    match pass with Dmove -> { rhs with expr = Move rhs } | _ -> rhs
  in

  (rhs, pass, { st with ids; trees })

and bids_of_touched touched kind st =
  List.map
    (fun touched ->
      let id = Idst.get touched.tname touched.tmname st.ids
      and usage = get_closed_usage kind touched in
      let part = [] and oncall = Some usage and cond_borrow = false in
      { id; part; oncall; cond_borrow })
    touched

and check_abs loc name abs tl st =
  let touched = bids_of_touched abs.func.touched abs.func.kind st in
  let bid, ids = Idst.insert name (Some st.mname) st.ids in

  let trees =
    match touched with
    | [] -> Trst.insert bid loc (Owned { tl; mutated = true }) `Many st.trees
    | touched ->
        let _, trees = Trst.bind bid loc false `Many touched st.trees in
        trees
  in

  { st with trees; ids }

let check_item st = function
  | Tl_let ({ id; pass; rhs; lmut; loc; _ } as tl) ->
      let rhs, pass, st =
        check_let ~toplevel:true st id loc pass lmut `Many rhs
      in
      (st, Tl_let { tl with rhs; pass })
  | Tl_expr e ->
      let e, _, trees = check_expr st (Dnorm, Once) [] Cexpr e in
      let trees = Trst.update ~old:st.trees trees in
      ({ st with trees }, Tl_expr e)
  | Tl_function (loc, id, _, abs) as e -> (check_abs loc id abs true st, e)
  | Tl_bind (str, e) ->
      let bid, ids = Idst.insert str (Some st.mname) st.ids in
      let e, trees =
        match check_expr st (Dnorm, Once) [] Cexpr e with
        | e, Owned, trees ->
            ( e,
              Trst.insert bid e.loc
                (Owned { tl = true; mutated = true })
                `Many trees )
        | e, Borrowed rhs_ids, trees ->
            let found, trees = Trst.bind bid e.loc false `Many rhs_ids trees in
            assert found;
            (e, trees)
      in
      ({ st with ids; trees }, Tl_bind (str, e))
  | (Tl_mutual_rec_decls _ | Tl_module _ | Tl_module_alias _) as e -> (st, e)

let add_touched state loc touched =
  List.fold_left
    (fun st touched ->
      let bid, ids = Idst.insert touched.tname touched.tmname st.ids in
      assert (
        Idst.Id.equal bid
          Idst.Id.(fst (Pathid.create touched.tname touched.tmname)));
      let trees = Trst.insert bid loc Reserved `Many st.trees in
      { st with trees; ids })
    state touched

let check_expr ~mname ~params ~touched expr =
  Trst.reset ();

  let state = add_touched (state_empty mname expr.loc) expr.loc touched in

  let state, rfs =
    List.fold_left_map
      (fun st (p, id, loc) ->
        let bid, ids = Idst.insert id None st.ids in
        let bstate =
          match p.pattr with
          | Dnorm (* borrowed *) -> Frozen
          | Dmut (* borrowed mut *) -> Reserved
          | Dset -> failwith "unreachable"
          | Dmove -> Owned { tl = false; mutated = true }
        in
        let mode, infer =
          match (repr p.pt, !(p.pmode)) with
          | _, Iknown Once -> (`Once, None)
          | _, Iknown Many -> (`Many, None)
          | Tfun _, _ ->
              let rf = ref true in
              (`Unknown rf, Some rf)
          | _ -> (
              match repr_mode !(p.pmode) with
              | Iknown Many -> (`Many, None)
              | Iknown Once -> (`Once, None)
              | Iunknown ->
                  (* Not a function, don't try to infer, use Many *)
                  (`Many, None)
              | Ilinked _ -> failwith "unreachable")
        in
        let trees = Trst.insert bid loc bstate mode st.trees in
        ({ st with ids; trees }, (p, infer)))
      state params
  in

  let expr, ret, trees =
    check_expr state (cond_move expr.typ, Many) [] Cexpr expr
  in
  let expr = { expr with expr = Move expr } in
  let trees =
    match ret with
    | Owned -> trees
    | Borrowed ids ->
        let bid = Idst.get "return" None state.ids in
        let _, trees = Trst.bind bid expr.loc false `Many ids trees in
        let _, _, trees =
          Trst.borrow bid expr.loc mname (cond_move expr.typ, Many) [] trees
        in
        trees
  in

  (* Ensure no parameter (or any other borrow) has been moved *)
  let unmutated = Trst.check_moves trees mname in

  List.iter
    (fun (p, rf) ->
      match rf with
      | None | Some { contents = false } -> (
          match repr_mode !(p.pmode) with
          | Iunknown -> p.pmode := Iknown Many
          | _ -> ())
      | Some { contents = true } ->
          (* Not setting to [Once] makes it a weak type in practice. Can be used
             as either Many or Once *)
          ())
    rfs;

  (* Update attribute of touched *)
  let touched =
    List.map
      (fun touched ->
        let bid = Idst.Id.(fst (Pathid.create touched.tname touched.tmname)) in
        let tattr, tattr_loc = Trst.find_touched_attr bid trees in
        (match tattr with
        | Dmove ->
            let loc = tattr_loc and name = touched.tname in
            raise
              (Error (loc, "Cannot move value " ^ name ^ " from outer scope"))
        | Dset | Dmut | Dnorm -> ());
        { touched with tattr; tattr_loc = Some tattr_loc })
      touched
  in
  (unmutated, expr, touched)

let check_items ~mname loc ~touched items =
  Trst.reset ();
  let state = add_touched (state_empty mname loc) loc touched in
  List.fold_left_map (fun st item -> check_item st item) state items
  |> fun (st, items) ->
  (* Ensure no parameter or outer value has been moved *)
  let unmutated = Trst.check_moves st.trees mname in
  (unmutated, items)
