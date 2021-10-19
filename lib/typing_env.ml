module Env : sig
  type key = string

  type 'a t

  val empty : 'a t

  val add_value : key -> 'a -> 'a t -> 'a t

  val new_scope : 'a t -> 'a t

  val close_scope : 'a t -> 'a t * string list

  val find_opt : key -> 'a t -> 'a option

  val query_opt : key -> 'a t -> 'a option
  (** [query_opt key env] is like find_opt, but marks [key] as
      being used in the current scope (e.g. a closure) *)

  val find : key -> 'a t -> 'a
end = struct
  module Map = Map.Make (String)

  type key = string

  type 'a t = { values : ('a Map.t * string list ref) list; labels : 'a Map.t }

  let empty = { values = [ (Map.empty, ref []) ]; labels = Map.empty }

  let add_value key vl env =
    match env.values with
    | [] -> failwith "Internal error: Env empty"
    | (hd, cls) :: tl -> { env with values = (Map.add key vl hd, cls) :: tl }

  let new_scope env =
    let empty = empty.values in
    { env with values = empty @ env.values }

  let close_scope env =
    match env.values with
    | [] -> failwith "Internal error: Env empty"
    | (_, cls) :: tl -> ({ env with values = tl }, !cls |> List.rev)

  let find_opt key env =
    let rec aux = function
      | [] -> None
      | (hd, _) :: tl -> (
          match Map.find_opt key hd with None -> aux tl | Some vl -> Some vl)
    in
    aux env.values

  let query_opt key env =
    let cls = List.hd env.values |> snd in
    let add str = cls := str :: !cls in

    let rec aux closed = function
      | [] -> None
      | (hd, _) :: tl -> (
          match Map.find_opt key hd with
          | None -> aux (closed + 1) tl
          | Some value ->
              (match closed with 0 -> () | _ -> add key);
              Some value)
    in
    aux 0 env.values

  let find key env =
    let rec aux = function
      | [] -> raise Not_found
      | (hd, _) :: tl -> (
          match Map.find_opt key hd with None -> aux tl | Some vl -> vl)
    in
    aux env.values
end
