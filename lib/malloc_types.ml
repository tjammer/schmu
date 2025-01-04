module Mpath = struct
  type t = int list [@@deriving show]

  let rec compare a b =
    match (a, b) with
    | i :: _, [] | [], i :: _ -> i
    | [], [] -> 0
    | a :: atl, b :: btl ->
        let cmp = Int.compare a b in
        if cmp = 0 then compare atl btl else cmp

  let () = ignore pp
end

module rec Malloc : sig
  type t = Single of Mid.t | Param of Mid.t | No_malloc | Path of t * Mpath.t
  [@@deriving show]
end = struct
  type t = Single of Mid.t | Param of Mid.t | No_malloc | Path of t * Mpath.t
  [@@deriving show]
end

and Mid : sig
  type t = { mid : int; typ : Cleaned_types.typ; parent : Malloc.t option }
  [@@deriving show]

  val compare : t -> t -> int
end = struct
  type t = { mid : int; typ : Cleaned_types.typ; parent : Malloc.t option }
  [@@deriving show]

  let compare a b = Int.compare a.mid b.mid
end

let rec get_parent = function
  | Malloc.Single { parent; _ } -> parent
  | Param { parent; _ } -> parent
  | No_malloc -> None
  | Path (p, _) -> get_parent p

let rec mid_of_malloc = function
  | Malloc.Single m | Param m -> Some m
  | Path (p, _) -> mid_of_malloc p
  | No_malloc -> None

module Imap = Map.Make (Mid)
module Pset = Set.Make (Mpath)

type pset = Pset.t

let show_pset s =
  "("
  ^ (Pset.to_seq s |> Seq.map Mpath.show |> List.of_seq |> String.concat ", ")
  ^ ")"

let pp_pset ppf s = Format.fprintf ppf "(%s)" (show_pset s)

type pop_outcome = Not_excl | Excl | Followup of Pset.t

let pop_index_pset pset index =
  (* There are three outcomes when an index is popped:
     1. The index isn't part of the path-set, hence we delete it normally
        Not_excl
     2. The path is exhausted, in which case we do nothing
        Exhaust
     3. There is a follow-up path, we need to recurse
        Followup *)
  let found, popped =
    Pset.fold
      (fun path (found, popped) ->
        match path with
        | [ i ] when Int.equal i index -> (true, popped)
        | i :: tl when Int.equal i index -> (true, Pset.add tl popped)
        | [] -> failwith "Internal Error: Empty path"
        | _ -> (found, popped))
      pset (false, Pset.empty)
  in
  if not found then Not_excl
  else if Pset.is_empty popped then Excl
  else Followup popped

type malloc_id = { id : int; mtyp : Cleaned_types.typ; paths : pset }
[@@deriving show]

let () = ignore pp_malloc_id
