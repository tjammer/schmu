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

type label = {
  index : int; (* index of laber in record labels array *)
  typename : string;
}

type value = { typ : typ; is_param : bool; is_const : bool }
type usage = { loc : Ast.loc; used : bool ref }
type return = { typ : typ; is_const : bool }

(* function scope *)
type scope = {
  valmap : value Map.t;
  closed : Set.t ref;
  used : (string, usage) Hashtbl.t;
      (* Another list for local scopes (like in if) *)
}

type t = {
  values : scope list;
  labels : label Map.t; (* For single labels (field access) *)
  labelsets : string Lmap.t; (* For finding the type of a record expression *)
  ctors : label Map.t; (* Variant constructors *)
  types : typ Tmap.t;
  (* The record types are saved in their most general form.
     For codegen, we also save the instances of generics. This
     probably should go into another pass once we add it *)
  instances : typ Tmap.t ref;
  (* Instantiations for both records and variants *)
  externals : (typ * string option) Tmap.t;
  print_fn : typ -> string;
}

type unused = (unit, (string * Ast.loc) list) result

let empty print_fn =
  {
    values =
      [
        { valmap = Map.empty; closed = ref Set.empty; used = Hashtbl.create 64 };
      ];
    labels = Map.empty;
    labelsets = Lmap.empty;
    ctors = Map.empty;
    types = Tmap.empty;
    instances = ref Tmap.empty;
    externals = Tmap.empty;
    print_fn;
  }

let add_value key typ loc ?(is_const = false) ?(is_param = false) env =
  match env.values with
  | [] -> failwith "Internal Error: Env empty"
  | scope :: tl ->
      let valmap = Map.add key { typ; is_param; is_const } scope.valmap in

      (* Shadowed bindings stay in the Hashtbl, but are not reachable (I think).
         Thus, warning for unused shadowed bindings works *)
      let tbl = scope.used in
      Hashtbl.add tbl key { loc; used = ref false };

      { env with values = { scope with valmap } :: tl }

let add_external key ~cname typ loc env =
  let env = add_value key typ loc env in
  let tkey = Type_key.create key in
  let externals = Tmap.add tkey (typ, cname) env.externals in
  { env with externals }

let change_type key typ env =
  match env.values with
  | [] -> failwith "Internal Error: Env empty"
  | scope :: tl -> (
      match Map.find_opt key scope.valmap with
      | Some value ->
          let valmap = Map.add key { value with typ } scope.valmap in
          { env with values = { scope with valmap } :: tl }
      | None -> "Internal Error: Missing key for changing " ^ key |> failwith)

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
        (index + 1, Map.add field.name { index; typename = record } labels))
      (0, env.labels) labels
  in
  let record = Type_key.create record in
  let types = Tmap.add record typ env.types in
  { env with labels; types; labelsets }

let add_variant variant ~param ~ctors env =
  let typ = Tvariant (param, variant, ctors) in

  let _, ctors =
    Array.fold_left
      (fun (index, ctors) ctor ->
        (index + 1, Map.add ctor.ctorname { index; typename = variant } ctors))
      (0, env.ctors) ctors
  in
  let variant = Type_key.create variant in
  let types = Tmap.add variant typ env.types in
  { env with ctors; types }

let is_unbound = function
  | Qvar _ | Tvar { contents = Unbound _ } -> true
  | _ -> false

let maybe_add_type_instance key typ env =
  (* We reject generic records with unbound variables *)
  let key = Type_key.create key in

  match clean typ with
  | (Trecord (Some t, _, _) | Tvariant (Some t, _, _)) when not (is_unbound t)
    -> (
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
    | scope :: tl -> (
        match Map.find_opt key scope.valmap with
        | None -> aux tl
        | Some vl -> vl)
  in
  aux env.values

let open_function env =
  (* Due to the ref, we have to create a new object every time *)
  let empty =
    [ { valmap = Map.empty; closed = ref Set.empty; used = Hashtbl.create 64 } ]
  in
  { env with values = empty @ env.values }

let find_unused ret tbl =
  let ret =
    Hashtbl.fold
      (fun name (used : usage) acc ->
        if not !(used.used) then (name, used.loc) :: acc else acc)
      tbl ret
  in
  match ret with
  | [] -> Ok ()
  | some ->
      (* Sort the warnings so the ones form the start of file are printed first *)
      let some =
        List.sort
          (fun (_, ((lhs : Lexing.position), _)) (_, (rhs, _)) ->
            if lhs.pos_lnum <> rhs.pos_lnum then
              Int.compare lhs.pos_lnum rhs.pos_lnum
            else Int.compare lhs.pos_cnum rhs.pos_cnum)
          some
      in
      Error some

let close_function env =
  match env.values with
  | [] -> failwith "Internal Error: Env empty"
  | scope :: tl ->
      let closed =
        !(scope.closed) |> Set.to_seq |> List.of_seq
        |> List.filter_map (fun k ->
               (* We only add functions to the closure if they are params
                  Or: if they are closures *)
               let k = Type_key.key k in
               let { typ; is_param; is_const } = find_val_raw k env in
               (* Const values are not closed over, they exist module-wide *)
               if is_const then None
               else
                 match clean typ with
                 | Tfun (_, _, Closure _) -> Some (k, typ)
                 | Tfun _ when not is_param -> None
                 | _ -> Some (k, typ))
      in

      let unused = find_unused [] scope.used in
      ({ env with values = tl }, closed, unused)

let find_val_opt key env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.valmap with
        | None -> aux tl
        | Some vl -> Some { typ = vl.typ; is_const = vl.is_const })
  in
  aux env.values

let find_val key env =
  match find_val_opt key env with Some vl -> vl | None -> raise Not_found

let mark_used name tbl =
  match Hashtbl.find_opt tbl name with
  | Some (used : usage) -> used.used := true
  | None -> ()

let query_val_opt key env =
  (* Add str to closures, up to the level where the value originates from *)
  let rec add lvl str values =
    match values with
    | scope :: tl when lvl > 0 ->
        scope.closed := Set.add str !(scope.closed);
        add (lvl - 1) str tl
    | _ -> ()
  in

  let rec aux scope_lvl = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.valmap with
        | None -> aux (scope_lvl + 1) tl
        | Some { typ; is_param = _; is_const } ->
            (* If something is closed over, add to all env above (if scope_lvl > 0) *)
            (match scope_lvl with
            | 0 -> ()
            | _ -> add scope_lvl (Type_key.create key) env.values);
            (* Mark value used *)
            mark_used key scope.used;
            (* It might be expensive to call this on each query, but we need to make sure we
               pick up every used record instance *)
            maybe_add_type_instance (env.print_fn typ) typ env;
            Some { typ; is_const })
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

let find_ctor_opt name env = Map.find_opt name env.ctors

let typedefs env =
  let values ({ Type_key.key = _; ord = _ }, v) = v in
  Tmap.filter
    (fun _ typ ->
      match typ with
      | Trecord (Some (Qvar _), _, _) | Tvariant (Some (Qvar _), _, _) ->
          (* We don't want to add generic records *)
          false
      | Trecord _ | Tvariant _ -> true
      | _ -> false)
    env.types
  |> Tmap.bindings
  |> (* Add instances *)
  fun simple_records ->
  simple_records @ Tmap.bindings !(env.instances)
  |> List.sort Type_key.cmp_map_sort
  |> List.map values

let externals env =
  Tmap.bindings env.externals
  |> List.sort Type_key.cmp_map_sort
  |> List.map (fun (key, (typ, cname)) -> (Type_key.key key, typ, cname))