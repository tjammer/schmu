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

module Imap = Map.Make (Int)
module Pset = Set.Make (Mpath)

type pset = Pset.t

let show_pset s =
  "("
  ^ (Pset.to_seq s |> Seq.map Mpath.show |> List.of_seq |> String.concat ", ")
  ^ ")"

let pp_pset ppf s = Format.fprintf ppf "(%s)" (show_pset s)

type malloc_id = { id : int; paths : pset } [@@deriving show]

let () = ignore pp_malloc_id
