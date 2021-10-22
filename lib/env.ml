open Types
module Map = Map.Make (String)

type key = string

type label = { typ : typ; record : string }

type t = {
  values : (typ Map.t * string list ref) list;
  labels : label Map.t;
  records : typ Map.t;
}

let empty =
  { values = [ (Map.empty, ref []) ]; labels = Map.empty; records = Map.empty }

let add_value key vl env =
  match env.values with
  | [] -> failwith "Internal error: Env empty"
  | (hd, cls) :: tl -> { env with values = (Map.add key vl hd, cls) :: tl }

let add_type record ~labels env =
  let typ = TRecord (record, labels) in
  let labels =
    List.fold_left
      (fun labels (lname, typ) -> Map.add lname { typ; record } labels)
      env.labels labels
  in
  let records = Map.add record typ env.records in
  { env with labels; records }

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

let find_type_opt key env = Map.find_opt key env.records

let find_type key env = Map.find key env.records

let find_label_opt key env = Map.find_opt key env.labels
