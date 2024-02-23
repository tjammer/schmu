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
let is_local = function Pid _ -> true | Pmod _ -> false

let only_hd = function
  | Pid s -> s
  | Pmod _ -> raise (Invalid_argument "not a local binding")

let rec get_hd = function Pid s -> s | Pmod (_, p) -> get_hd p

let rec rm_name modpath to_rm =
  match (modpath, to_rm) with
  | Pid m, Pmod (s, t) when String.equal s m -> t
  | Pmod (m, tl), Pmod (s, t) when String.equal m s -> rm_name tl t
  | _, p -> p

(* Like rm_name but report of something was removed *)
let rm_path modpath to_rm =
  let rec inner found modpath to_rm =
    match (modpath, to_rm) with
    | Pid m, Pmod (s, t) when String.equal s m -> (true, t)
    | Pmod (m, tl), Pmod (s, t) when String.equal m s -> inner true tl t
    | _, p -> (found, p)
  in
  inner false modpath to_rm

let rec mod_name = function Pid s -> s | Pmod (n, p) -> n ^ "_" ^ mod_name p

let rec add_left p = function
  | Pid n -> Pmod (n, p)
  | Pmod (n, tl) -> Pmod (n, add_left p tl)

let rec append_path p = function
  | Pid n -> Pmod (n, p)
  | Pmod (n, tl) -> Pmod (n, append_path p tl)

let append name = append_path (Pid name)

let share_base l r =
  match (l, r) with
  | Pid l, Pid r
  | Pmod (l, _), Pid r
  | Pmod (l, _), Pmod (r, _)
  | Pid l, Pmod (r, _) ->
      String.equal l r

let rec pop = function
  | Pid _ as p -> p
  | Pmod (n, Pid _) -> Pid n
  | Pmod (n, p) -> Pmod (n, pop p)

let rec match_until_pid l r =
  match (l, r) with
  | Pid _, Pid _ -> true
  | Pmod (nl, pl), Pmod (nr, pr) when String.equal nl nr ->
      match_until_pid pl pr
  | Pmod _, Pmod _ | Pid _, Pmod _ | Pmod _, Pid _ -> false

(*  Fold over mod part, excluding Pid *)
let fold_mod_left f init p =
  let rec aux acc = function
    | Pid last -> f acc last
    | Pmod (s, tl) -> aux (f acc s) tl
  in
  aux init p
