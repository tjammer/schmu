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
  val head : t -> Part_kind.t
  val head_tl : t -> Part_kind.t * t option
  val of_head : Part_kind.t -> t
  val ints : t -> int list
end = struct
  type t = { head : Part_kind.t; tl : Part_kind.t list } [@@deriving show]

  let add_part whole part = { whole with tl = whole.tl @ [ part ] }
  let head part = part.head

  let head_tl part =
    match part.tl with
    | [] -> (part.head, None)
    | head :: tl -> (part.head, Some { head; tl })

  let of_head head = { head; tl = [] }

  let ints { head; tl } =
    let rec aux acc = function
      | [] -> List.rev acc
      | hd :: tl -> (
          match hd with
          | Part_kind.Mvariant _ -> aux acc tl
          | Mindex i -> aux (i :: acc) tl)
    in
    match head with Mvariant _ -> aux [] tl | Mindex i -> aux [ i ] tl
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
  val find : t -> Part.t -> t
  val fold : (Part.t -> 'a -> 'a) -> t -> 'a -> 'a
  val move_add_head : t -> Part_kind.t -> t
  val ints : t -> int list Seq.t
  val split_variants : t -> t option * (Mid.t * t) list
  val show : t -> string
  val pp : Format.formatter -> t -> unit
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

  let rec show = function
    | Whole -> "Whole"
    | Parts map ->
        let map =
          Pmap.fold
            (fun kind set acc ->
              acc ^ " (" ^ Part_kind.show kind ^ ": " ^ show set ^ ")")
            map ""
        in
        "(Parts " ^ map ^ ")"

  let pp ppf p = Format.fprintf ppf "%s" (show p)

  let rec prune_variants = function
    | Whole -> Whole
    | Parts map ->
        let map =
          Pmap.filter_map
            (fun head set ->
              match head with
              | Mindex _ -> Some (prune_variants set)
              | Mvariant _ -> None)
            map
        in
        if Pmap.is_empty map then Whole else Parts map

  let rec diff a b =
    (* Which items would I need to add to [b] to get [a]? Also, remove
       intersection of [a] and [b] from [a] *)
    match (a, b) with
    | Whole, Whole -> Whole
    | Whole, Parts _ ->
        (* Don't take the complete part of [b], but only until next Mvariant
           (excluding). If a is Whole, it might not know about the variant, and in
           pattern matches, the a branch must not try to free a pattern matched in
           another branch. *)
        prune_variants b
    | Parts _, Whole -> a
    | Parts a, Parts b ->
        let map =
          Pmap.merge
            (fun _ a b ->
              match (a, b) with
              | Some _, None -> a
              | None, (Some _ | None) -> a
              | Some a, Some b -> (
                  match diff a b with
                  (* [Whole] means the diff is empty, so a and b are the same.
                     This is a diff, so we remove this case. *)
                  | Whole -> None
                  | Parts _ as diff -> Some diff))
            a b
        in
        Parts map

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

  let rec find set part =
    match set with
    | Whole -> set
    | Parts map -> (
        let hd, tl = Part.head_tl part in
        match Pmap.find_opt hd map with
        | None -> Whole
        | Some tail -> (
            match tl with Some part -> find tail part | None -> tail))

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

  let move_add_head set hd = Parts (Pmap.add hd set Pmap.empty)
  let ints set = fold (fun p seq -> Seq.cons (Part.ints p) seq) set Seq.empty

  let split_variants set =
    (* Pick out all paths of the set containing a variant and return the set
       without the variant (if there is anything left) and for each variant a
       new set with the variant Mid.t as a head. *)
    let rec aux found_variant variants = function
      | Whole -> (Whole, found_variant, variants)
      | Parts map ->
          let map, found, variants =
            Pmap.fold
              (fun head set (map, found_variant, variants) ->
                match head with
                | Mvariant mid ->
                    let set, found, vars = aux false variants set in
                    if found then
                      (* Don't add this one to the variants list, because
                         children have been added.*)
                      if is_empty set then
                        (* All children have been removed, do nothing *)
                        (map, true, vars)
                      else (Pmap.add head set map, true, vars)
                    else
                      (* No children variants were found, add this one. And
                         discard the item from the remaining map. *)
                      (map, found_variant, (mid, set) :: variants)
                | Mindex _ ->
                    let set, found, vars = aux false variants set in
                    if found && is_empty set then
                      (* All children have been removed, do nothing *)
                      let () = print_endline "children have been moved" in
                      (map, found, vars)
                    else (Pmap.add head set map, found_variant, variants))
              map
              (Pmap.empty, false, variants)
          in
          if Pmap.is_empty map then (Whole, found_variant || found, variants)
          else (Parts map, found_variant || found, variants)
    in
    let new_set, _, variants = aux false [] set in
    match (set, new_set) with
    | Whole, Whole -> (Some set, variants)
    | Parts _, Whole -> (None, variants)
    | _, Parts _ -> (Some set, variants)
end

module Malloc = struct
  type id_kind = Single | Param

  and t =
    | Whole of Mid.t * id_kind
    | No_malloc
    | Part of Mid.t * id_kind * Part.t
  [@@deriving show]
end

module Imap = Map.Make (Mid)

type pop_outcome = Not_excl | Excl | Followup of Part_set.t

let pop_index_pset pset index =
  (* There are three outcomes when an index is popped:
     1. The index isn't part of the path-set, hence we delete it normally
        Not_excl
     2. The path is exhausted, in which case we do nothing
        Exhaust
     3. There is a follow-up path, we need to recurse
        Followup *)
  let found, popped =
    Part_set.fold
      (fun part (found, popped) ->
        let hd, tl = Part.head_tl part in
        match hd with
        | Mvariant _ -> failwith "TODO variant"
        | Mindex i when Int.equal i index -> (
            match tl with
            | Some tl ->
                (* We move out the tail to make this a follow-up later. *)
                (true, Part_set.move_out popped tl)
            | None -> (true, popped))
        | Mindex _ -> (found, popped))
      pset (false, Part_set.empty)
  in
  if not found then Not_excl
  else if Part_set.is_empty popped then Excl
  else Followup popped

type malloc_id = { id : int; mtyp : Cleaned_types.typ; paths : Part_set.t }
[@@deriving show]

let () = ignore pp_malloc_id
