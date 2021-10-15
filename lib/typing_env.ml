module Env : sig
  type key = string

  type 'a t

  val empty : 'a t

  val add : key -> 'a -> 'a t -> 'a t

  val new_scope : 'a t -> 'a t

  val close_scope : 'a t -> 'a t * string list

  val find_opt : key -> 'a t -> 'a option

  val find : key -> 'a t -> 'a
end = struct
  module Map = Map.Make (String)

  type key = string

  type 'a t = ('a Map.t * string list ref) list

  let empty = [ (Map.empty, ref []) ]

  let add key vl = function
    | [] -> failwith "Internal error: Env empty"
    | (hd, cls) :: tl -> (Map.add key vl hd, cls) :: tl

  let new_scope env = empty @ env

  let close_scope = function
    | [] -> failwith "Internal error: Env empty"
    | (_, cls) :: tl -> (tl, !cls |> List.rev)

  let find_opt key env =
    let cls = List.hd env |> snd in
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
    aux 0 env

  let rec find key = function
    | [] -> raise Not_found
    | (hd, _) :: tl -> (
        match Map.find_opt key hd with None -> find key tl | Some vl -> vl)
end
