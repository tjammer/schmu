type t = Pid of string | Pmod of string * t

let rec show = function Pid s -> s | Pmod (n, p) -> n ^ "/" ^ show p
let pp ppf p = Format.fprintf ppf "%s" (show p)

(* Using "." here makes sure there is no clash to a user defined type which (by accident)
   has matches a module type. "." is not allowed in type names *)
let rec type_name = function
  | Pid s -> s
  | Pmod ("schmu", p) ->
      (* Don't prefix everything from the main module with "schmu" *)
      type_name p
  | Pmod (n, p) -> n ^ "." ^ type_name p

open Sexplib0

let sexp_of_t p = Sexp.Atom (show p)

let t_of_sexp p =
  match p with
  | Sexp.Atom p ->
      let parts = String.split_on_char '/' p in
      let rec build = function
        | [ s ] -> Pid s
        | n :: tl -> Pmod (n, build tl)
        | [] -> failwith "Internal Error: Empty atom"
      in
      build parts
  | List _ -> failwith "Internal Error: Why list?"

let rec equal l r =
  match (l, r) with
  | Pid l, Pid r -> String.equal l r
  | Pmod (nl, pl), Pmod (nr, pr) -> String.equal nl nr && equal pl pr
  | Pid _, Pmod _ | Pmod _, Pid _ -> false

let compare l r = Stdlib.compare l r
let imported = function Pid _ -> false | Pmod _ -> true
let local = function Pid _ -> true | Pmod _ -> false

let only_hd = function
  | Pid s -> s
  | Pmod _ -> raise (Invalid_argument "not a local binding")

let rec get_hd = function Pid s -> s | Pmod (_, p) -> get_hd p
let rm_hd = function Pmod (_, t) -> t | Pid t -> Pid t

let rec rm_name modpath to_rm =
  match (modpath, to_rm) with
  | Pid m, Pmod (s, t) when String.equal s m -> t
  | Pmod (m, tl), Pmod (s, t) when String.equal m s -> rm_name tl t
  | _, p -> p

let remove_prefix ~without ~with_prefix =
  let rec aux wo wp =
    match (wo, wp) with
    | Pid w, Pid p when not (String.equal w p) -> with_prefix
    | Pid _, Pid _ -> wo
    | Pmod (w, _), (Pmod (wp', _) | Pid wp') when String.equal w wp' -> wp
    | Pmod _, Pid _ -> with_prefix
    | (Pmod _ | Pid _), Pmod (_, tl) -> aux wo tl
  in
  aux without with_prefix

let rec mod_name = function Pid s -> s | Pmod (n, p) -> n ^ "_" ^ mod_name p

let rec add_left p = function
  | Pid n -> Pmod (n, p)
  | Pmod (n, tl) -> Pmod (n, add_left p tl)

let rec append name = function
  | Pid n -> Pmod (n, Pid name)
  | Pmod (n, tl) -> Pmod (n, append name tl)

let rec match_until_pid l r =
  match (l, r) with
  | Pid _, Pid _ -> true
  | Pmod (nl, pl), Pmod (nr, pr) when String.equal nl nr ->
      match_until_pid pl pr
  | Pmod _, Pmod _ | Pid _, Pmod _ | Pmod _, Pid _ -> false

(*  Fold over mod part, excluding Pid *)
let fold_mod_left f init p =
  let rec aux acc = function
    | Pid _ -> acc
    | Pmod (s, tl) -> aux (f acc s) tl
  in
  aux init p

let fold_mod_right f init p =
  let rec aux p acc =
    match p with Pmod (s, tl) -> f s (aux tl acc) | Pid _ -> acc
  in
  aux p init

(* let () = *)
(*   let v = Pmod ("a", Pmod ("b", Pmod ("c", Pid "pid"))) in *)
(*   let left = fold_mod_left (fun acc s -> acc ^ s) "" v in *)
(*   assert (left = "abc"); *)
(*   let right = fold_mod_right (fun s acc -> acc ^ s) "" v in *)
(*   assert (right = "cba") *)
