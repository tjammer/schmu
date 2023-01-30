type t = Pid of string | Pmod of string * t

let rec show = function Pid s -> s | Pmod (n, p) -> n ^ "/" ^ show p
let pp ppf p = Format.fprintf ppf "%s" (show p)

(* Using "." here makes sure there is no clash to a user defined type which (by accident)
   has matches a module type. "." is not allowed in type names *)
let rec type_name = function Pid s -> s | Pmod (n, p) -> n ^ "." ^ type_name p

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
let rm_mod = function Pmod (_, t) -> t | Pid t -> Pid t
let rm_name name = function Pmod (s, t) when String.equal s name -> t | p -> p
