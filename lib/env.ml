open Types

module TypeKey = struct
  (* We have to remember the order of type declaration *)
  let state = ref 0

  type t = { key : string; ord : int }

  let compare a b = String.compare a.key b.key

  let cmp_sort (a, _) (b, _) = Int.compare a.ord b.ord

  let create key =
    let ord = !state in
    incr state;
    { key; ord }
end

module TMap = Map.Make (TypeKey)
module Map = Map.Make (String)

type key = string

type label = { typ : typ; index : int; record : string }

type t = {
  values : (typ Map.t * string list ref) list;
  labels : label Map.t;
  types : typ TMap.t;
  (* The record types are saved in their most general form.
     For codegen, we also save the instances of generics. This
     probably should go into another pass once we add it *)
  instances : typ Map.t ref;
}

let empty =
  {
    values = [ (Map.empty, ref []) ];
    labels = Map.empty;
    types = TMap.empty;
    instances = ref Map.empty;
  }

let add_value key vl env =
  match env.values with
  | [] -> failwith "Internal error: Env empty"
  | (hd, cls) :: tl -> { env with values = (Map.add key vl hd, cls) :: tl }

let add_type key t env =
  let key = TypeKey.create key in
  let types = TMap.add key t env.types in
  { env with types }

let add_record record ~param ~labels env =
  let typ = Trecord (param, record, labels) in
  let _, labels =
    Array.fold_left
      (fun (index, labels) (lname, typ) ->
        (index + 1, Map.add lname { typ; index; record } labels))
      (0, env.labels) labels
  in
  let record = TypeKey.create record in
  let types = TMap.add record typ env.types in
  { env with labels; types }

let maybe_add_record_instance key typ env =
  (* We reject generic records with unbound variables *)
  let is_unbound i labels =
    match labels.(i) |> snd with
    | Tvar { contents = Unbound _ } -> true
    | _ -> false
  in
  match (Map.find_opt key !(env.instances), typ) with
  | None, Trecord (Some i, _, labels) when is_unbound i labels -> ()
  | None, Trecord (Some _, _, _) ->
      env.instances := Map.add key typ !(env.instances)
  | Some _, _ | None, _ -> ()

let new_scope env =
  (* Due to the ref, we have to create a new object every time *)
  let empty = [ (Map.empty, ref []) ] in
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

let find_type_opt key env = TMap.find_opt (TypeKey.create key) env.types

let find_type key env = TMap.find (TypeKey.create key) env.types

let query_type ~newvar key env =
  match TMap.find (TypeKey.create key) env.types with
  | Trecord (Some i, name, labels) ->
      let labels = Array.copy labels in
      let lname, _ = labels.(i) in
      labels.(i) <- (lname, newvar ());
      Trecord (Some i, name, labels)
  | t -> t

let find_label_opt key env = Map.find_opt key env.labels

let records env =
  TMap.filter
    (fun _ typ -> match typ with Trecord _ -> true | _ -> false)
    env.types
  |> TMap.bindings |> List.sort TypeKey.cmp_sort
  |> List.map (fun ({ TypeKey.key; ord = _ }, v) -> (key, v))
  |> List.split |> snd
  |> (* Add instances *)
  fun generics ->
  let instances = Map.fold (fun _ t acc -> t :: acc) !(env.instances) [] in
  generics @ List.rev instances
