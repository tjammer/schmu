open Types
module Map = Map.Make (String)

type key = string

type label = { typ : typ; index : int; record : string }

type t = {
  values : (typ Map.t * string list ref) list;
  labels : label Map.t;
  types : typ Map.t;
  (* The record types are saved in their most general form.
     For codegen, we also save the instances of generics. This
     probably should go into another pass once we add it *)
  instances : typ Map.t ref;
}

let empty =
  {
    values = [ (Map.empty, ref []) ];
    labels = Map.empty;
    types = Map.empty;
    instances = ref Map.empty;
  }

let add_value key vl env =
  match env.values with
  | [] -> failwith "Internal error: Env empty"
  | (hd, cls) :: tl -> { env with values = (Map.add key vl hd, cls) :: tl }

let add_type key t env =
  let types = Map.add key t env.types in
  { env with types }

let add_record record ~param ~labels env =
  let typ = TRecord (param, record, labels) in
  let _, labels =
    Array.fold_left
      (fun (index, labels) (lname, typ) ->
        (index + 1, Map.add lname { typ; index; record } labels))
      (0, env.labels) labels
  in
  let types = Map.add record typ env.types in
  { env with labels; types }

let maybe_add_record_instance key ~(param : int option) typ env =
  match (Map.find_opt key !(env.instances), param) with
  | Some _, _ | None, None -> ()
  | None, Some _ -> env.instances := Map.add key typ !(env.instances)

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

let find_type_opt key env = Map.find_opt key env.types

let find_type key env = Map.find key env.types

let query_type ~newvar key env =
  match Map.find key env.types with
  | TRecord (Some i, name, labels) ->
      let labels = Array.copy labels in
      let lname, _ = labels.(i) in
      labels.(i) <- (lname, newvar ());
      TRecord (Some i, name, labels)
  | t -> t

let find_label_opt key env = Map.find_opt key env.labels

let records env =
  Map.filter
    (fun _ typ -> match typ with TRecord _ -> true | _ -> false)
    env.types
  |> Map.bindings |> List.split |> snd
  |> (* Add instances *)
  fun generics ->
  Map.fold
    (fun _ t acc -> t :: acc)
    !(env.instances)
    (* We reverse to preserve the declaration order *) (List.rev generics)
