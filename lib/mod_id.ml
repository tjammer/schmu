(* TODO rename once the other malloc types aren't used anymore *)
(* type t = { path : Path.t; id : int } [@@deriving show] *)

(* let equal a b = Int.equal a.id b.id && Path.equal a.path b.path *)
(* let compare = Stdlib.compare *)
(* let hash = Hashtbl.hash *)
(* let whatever = { path = Path.Pid "whatever"; id = -1 } *)

type t = int [@@deriving show]

let equal = Int.equal
let compare = Int.compare
let hash = Int.hash
let whatever = -1
