open Types

module Type_key = struct
  (* We have to remember the order of type declaration *)
  let state = ref 0

  type t = { key : string; ord : int }

  let compare a b = String.compare a.key b.key
  let cmp_map_sort (a, _) (b, _) = Int.compare a.ord b.ord

  let create key =
    let ord = !state in
    incr state;
    { key; ord }

  let key { key; ord = _ } = key
end

module Labelset = Set.Make (String)
module Lmap = Map.Make (Labelset)
module Tmap = Map.Make (Type_key)
module Map = Map.Make (String)
module Set = Set.Make (Type_key)

type key = string
type label = { index : int; record : string }
type value = { typ : typ; is_param : bool }

type t = {
  values : (value Map.t * Set.t ref) list;
  labels : label Map.t; (* For single labels (field access) *)
  labelsets : string Lmap.t; (* For finding the type of a record expression *)
  types : typ Tmap.t;
  (* The record types are saved in their most general form.
     For codegen, we also save the instances of generics. This
     probably should go into another pass once we add it *)
  instances : typ Tmap.t ref;
  print_fn : typ -> string;
}

let empty print_fn =
  {
    values = [ (Map.empty, ref Set.empty) ];
    labels = Map.empty;
    labelsets = Lmap.empty;
    types = Tmap.empty;
    instances = ref Tmap.empty;
    print_fn;
  }

let add_value key typ ?(is_param = false) env =
  match env.values with
  | [] -> failwith "Internal error: Env empty"
  | (hd, cls) :: tl ->
      { env with values = (Map.add key { typ; is_param } hd, cls) :: tl }

let add_type key t env =
  let key = Type_key.create key in
  let types = Tmap.add key t env.types in
  { env with types }

let add_record record ~param ~labels env =
  let typ = Trecord (param, record, labels) in

  let labelset =
    Array.to_seq labels |> Seq.map (fun f -> f.name) |> Labelset.of_seq
  in
  let labelsets = Lmap.add labelset record env.labelsets in

  let _, labels =
    Array.fold_left
      (fun (index, labels) field ->
        (index + 1, Map.add field.name { index; record } labels))
      (0, env.labels) labels
  in
  let record = Type_key.create record in
  let types = Tmap.add record typ env.types in
  { env with labels; types; labelsets }

let is_unbound = function
  | Qvar _ | Tvar { contents = Unbound _ } -> true
  | _ -> false

let maybe_add_record_instance key typ env =
  (* We reject generic records with unbound variables *)
  let key = Type_key.create key in

  match clean typ with
  | Trecord (Some t, _, _) when not (is_unbound t) -> (
      match Tmap.find_opt key !(env.instances) with
      | None -> env.instances := Tmap.add key typ !(env.instances)
      | Some _ -> ())
  | _ -> ()

let add_alias name typ env =
  let key = Type_key.create name in
  let types = Tmap.add key (Talias (name, typ)) env.types in
  { env with types }

let find_val_raw key env =
  let rec aux = function
    | [] -> raise Not_found
    | (hd, _) :: tl -> (
        match Map.find_opt key hd with None -> aux tl | Some vl -> vl)
  in
  aux env.values

let new_scope env =
  (* Due to the ref, we have to create a new object every time *)
  let empty = [ (Map.empty, ref Set.empty) ] in
  { env with values = empty @ env.values }

let close_scope env =
  match env.values with
  | [] -> failwith "Internal error: Env empty"
  | (_, cls) :: tl ->
      ( { env with values = tl },
        !cls |> Set.to_seq |> List.of_seq
        |> List.filter_map (fun k ->
               (* We only add functions to the closure if they are params *)
               let k = Type_key.key k in
               let { typ; is_param } = find_val_raw k env in
               match clean typ with
               | Tfun _ when not is_param -> None
               | _ -> Some (k, typ)) )

let find_val key env =
  let rec aux = function
    | [] -> raise Not_found
    | (hd, _) :: tl -> (
        match Map.find_opt key hd with None -> aux tl | Some vl -> vl.typ)
  in
  aux env.values

let find_val_opt key env =
  let rec aux = function
    | [] -> None
    | (hd, _) :: tl -> (
        match Map.find_opt key hd with None -> aux tl | Some vl -> Some vl.typ)
  in
  aux env.values

let query_val_opt key env =
  (* Add str to closures, up to the level where the value originates from *)
  let rec add lvl str values =
    match values with
    | (_, closed_vars) :: tl when lvl > 0 ->
        closed_vars := Set.add str !closed_vars;
        add (lvl - 1) str tl
    | _ -> ()
  in

  let rec aux closed = function
    | [] -> None
    | (hd, _) :: tl -> (
        match Map.find_opt key hd with
        | None -> aux (closed + 1) tl
        | Some { typ; is_param = _ } ->
            (* If something is closed over, add to all env above (if closed > 0) *)
            (match closed with
            | 0 -> ()
            | _ -> add closed (Type_key.create key) env.values);
            (* It might be expensive to call this on each query, but we need to make sure we
               pick up every used record instance *)
            maybe_add_record_instance (env.print_fn typ) typ env;
            Some typ)
  in
  aux 0 env.values

let find_type_opt key env = Tmap.find_opt (Type_key.create key) env.types
let find_type key env = Tmap.find (Type_key.create key) env.types

let query_type ~instantiate key env =
  Tmap.find (Type_key.create key) env.types |> instantiate

let find_label_opt key env = Map.find_opt key env.labels

let find_labelset_opt labels env =
  match Lmap.find_opt (Labelset.of_list labels) env.labelsets with
  | Some name -> Some (find_type name env)
  | None -> None

let records env =
  let values ({ Type_key.key = _; ord = _ }, v) = v in
  Tmap.filter
    (fun _ typ ->
      match typ with
      | Trecord (Some (Qvar _), _, _) ->
          (* We don't want to add generic records *)
          false
      | Trecord _ -> true
      | _ -> false)
    env.types
  |> Tmap.bindings
  |> (* Add instances *)
  fun simple_records ->
  simple_records @ Tmap.bindings !(env.instances)
  |> List.sort Type_key.cmp_map_sort
  |> List.map values
