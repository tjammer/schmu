module rec Mid : sig
  type t = { mid : int; typ : Cleaned_types.typ } [@@deriving show]

  val compare : t -> t -> int
end = struct
  type t = { mid : int; typ : Cleaned_types.typ } [@@deriving show]

  let compare a b = Int.compare a.mid b.mid
end

and Part_kind : sig
  type t = Mvariant of Mid.t | Mindex of int [@@deriving show]
end = struct
  type t = Mvariant of Mid.t | Mindex of int [@@deriving show]
end

module Part : sig
  type t [@@deriving show]

  val add_part : t -> Part_kind.t -> t
  val append : t -> next:t -> t
  val head : t -> Part_kind.t
  val head_tl : t -> Part_kind.t * t option
  val of_head : Part_kind.t -> t
end = struct
  type t = { head : Part_kind.t; tl : Part_kind.t list } [@@deriving show]

  let add_part whole part = { whole with tl = whole.tl @ [ part ] }
  let head part = part.head

  let head_tl part =
    match part.tl with
    | [] -> (part.head, None)
    | head :: tl -> (part.head, Some { head; tl })

  let rec append old ~next =
    let hd, tl = head_tl next in
    let old = { old with tl = old.tl @ [ hd ] } in
    match tl with Some next -> append old ~next | None -> old

  let of_head head = { head; tl = [] }
end

module Part_set : sig
  type t

  val move_out : t -> Part.t -> t
  val reenter : t -> Part.t -> t
  val is_empty : t -> bool
  val empty : t
  val diff : t -> t -> t
  val union : t -> t -> t
  val mem : t -> Part.t -> bool
  val fold : (Part.t -> 'a -> 'a) -> t -> 'a -> 'a
end = struct
  module Head = struct
    type t = Part_kind.t

    let compare a b =
      (* Only compare head because we want to save the root of the tree *)
      Stdlib.compare a b
  end

  module Pmap = Map.Make (Head)
  (* An empty set means the whole. Parts in the set are the parts which have
     been moved. So [move_out] adds parts to the set and [reenter] removes
     them. *)

  type t = Whole | Parts of t Pmap.t

  let rec move_out set part =
    let hd, tl = Part.head_tl part in
    match set with
    | Whole -> (
        match tl with
        | None -> Parts (Pmap.add hd Whole Pmap.empty)
        | Some tl -> Parts (Pmap.add hd (move_out Whole tl) Pmap.empty))
    | Parts headset -> (
        match Pmap.find_opt hd headset with
        | None -> (
            match tl with
            | None -> Parts (Pmap.add hd Whole headset)
            | Some tl -> Parts (Pmap.add hd (move_out Whole tl) headset))
        | Some set -> (
            match tl with
            | None ->
                (* Move out everything under this head *)
                Parts (Pmap.add hd Whole headset)
            | Some tl ->
                (* Integrate tl into set *)
                Parts (Pmap.add hd (move_out set tl) headset)))

  let rec reenter set part =
    let hd, tl = Part.head_tl part in
    match set with
    | Whole -> Whole
    | Parts headset -> (
        match Pmap.find_opt hd headset with
        | None -> (* Nothing to do *) set
        | Some Whole ->
            (* Is functionally the same as the [None] case, we can remove the
               item. *)
            let ret = Pmap.remove hd headset in
            if Pmap.is_empty ret then Whole else Parts ret
        | Some set -> (
            match tl with
            | None ->
                (* Reenter only [hd] without tail. This make the subset [Whole].
                   Like above, the [Whole] can be deleted from the map. *)
                let ret = Pmap.remove hd headset in
                if Pmap.is_empty ret then Whole else Parts ret
            | Some tl -> (
                match reenter set tl with
                | Whole ->
                    (* [Whole] case again *)
                    let ret = Pmap.remove hd headset in
                    if Pmap.is_empty ret then Whole else Parts ret
                | Parts _ as p -> Parts (Pmap.add hd p headset))))

  let is_empty set = match set with Whole -> true | Parts p -> Pmap.is_empty p
  let empty = Whole

  let rec diff a b =
    (* Which items would I need to add to [b] to get [a]? Also, remove
       intersection of [a] and [b] from [a] *)
    match (a, b) with
    | Whole, (Parts _ | Whole) -> Whole
    | Parts _, Whole -> a
    | Parts a, Parts b ->
        Parts
          (Pmap.merge
             (fun _ a b ->
               match (a, b) with
               | Some _, None -> a
               | None, (Some _ | None) -> a
               | Some a, Some b -> Some (diff a b))
             a b)

  let rec union a b =
    match (a, b) with
    | Whole, Whole -> Whole
    | Whole, Parts _ -> b
    | Parts _, Whole -> a
    | Parts a, Parts b ->
        Parts
          (Pmap.merge
             (fun _ a b ->
               match (a, b) with
               | None, None -> None
               | Some _, None -> a
               | None, Some _ -> b
               | Some a, Some b -> Some (union a b))
             a b)

  let rec mem set part =
    match set with
    | Whole -> false
    | Parts map -> (
        let hd, tl = Part.head_tl part in
        match Pmap.find_opt hd map with
        | None -> false
        | Some tail -> (
            match tl with
            | Some part -> mem tail part
            | None -> ( match tail with Whole -> true | Parts _ -> false)))

  let fold f set acc =
    let rec aux path acc set =
      match set with
      | Whole -> ( match path with None -> acc | Some path -> f path acc)
      | Parts map ->
          Pmap.fold
            (fun kind set acc ->
              match path with
              | None -> aux (Some (Part.of_head kind)) acc set
              | Some path -> aux (Some (Part.add_part path kind)) acc set)
            map acc
    in
    aux None acc set
end

module Malloc = struct
  type t = Single of Mid.t | Param of Mid.t | No_malloc | Part of t * Part.t
  [@@deriving show]
end

module Imap = Map.Make (Mid)

(* type pop_outcome = Not_excl | Excl | Followup of Pset.t *)

(* let pop_index_pset pset index = *)
(*   (\* There are three outcomes when an index is popped: *)
(*      1. The index isn't part of the path-set, hence we delete it normally *)
(*         Not_excl *)
(*      2. The path is exhausted, in which case we do nothing *)
(*         Exhaust *)
(*      3. There is a follow-up path, we need to recurse *)
(*         Followup *\) *)
(*   let found, popped *)

(*   let found, popped = *)
(*     Pset.fold *)
(*       (fun path (found, popped) -> *)
(*         match path with *)
(*         | Mindex (i, Mno_part) when Int.equal i index -> (true, popped) *)
(*         | Mindex (i, tl) when Int.equal i index -> (true, Pset.add tl popped) *)
(*         | Mno_part -> failwith "Internal Error: Empty part" *)
(*         | _ -> (found, popped)) *)
(*       pset (false, Pset.empty) *)
(*   in *)
(*   if not found then Not_excl *)
(*   else if Pset.is_empty popped then Excl *)
(*   else Followup popped *)

type malloc_id = {
  id : int;
  mtyp : Cleaned_types.typ;
  paths : Part_set.t; [@opaque]
}
[@@deriving show]

let () = ignore pp_malloc_id
