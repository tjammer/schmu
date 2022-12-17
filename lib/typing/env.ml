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
end

module Labelset = Set.Make (String)
module Lmap = Map.Make (Labelset)
module Tmap = Map.Make (Path)
module Emap = Map.Make (Type_key)

(* TODO ord map  *)
module Map = Map.Make (String)
module Set = Set.Make (String)

type key = string

type label = {
  index : int; (* index of laber in record labels array *)
  typename : Path.t;
}

type value = {
  typ : typ;
  param : bool;
  const : bool;
  global : bool;
  imported : bool;
  mut : bool;
}

type usage = {
  loc : Ast.loc;
  used : bool ref;
  imported : bool;
  mutated : bool ref;
}

type return = { typ : typ; const : bool; global : bool; mut : bool }
type imported = [ `C | `Schmu ]

type ext = {
  ext_name : string;
  ext_typ : typ;
  ext_cname : string option;
  imported : imported option;
  used : bool ref;
  closure : bool;
}

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
  labelsets : Path.t Lmap.t; (* For finding the type of a record expression *)
  ctors : label Map.t; (* Variant constructors *)
  types : typ Tmap.t;
  (* The record types are saved in their most general form.
     For codegen, we also save the instances of generics. This
     probably should go into another pass once we add it *)
  externals : ext Emap.t ref;
  in_mut : int ref;
}

type warn_kind = Unused | Unmutated
type unused = (unit, (string * warn_kind * Ast.loc) list) result

let def_value =
  {
    typ = Tunit;
    param = false;
    const = false;
    global = false;
    imported = false;
    mut = false;
  }

let empty () =
  {
    values =
      [
        { valmap = Map.empty; closed = ref Set.empty; used = Hashtbl.create 64 };
      ];
    labels = Map.empty;
    labelsets = Lmap.empty;
    ctors = Map.empty;
    types = Tmap.empty;
    externals = ref Emap.empty;
    in_mut = ref 0;
  }

let add_value key value loc env =
  match env.values with
  | [] -> failwith "Internal Error: Env empty"
  | scope :: tl ->
      let valmap = Map.add key value scope.valmap in

      (* Shadowed bindings stay in the Hashtbl, but are not reachable (I think).
         Thus, warning for unused shadowed bindings works *)
      (if not value.imported then
       let tbl = scope.used in
       (* If the value is not mutable, we set it to mutated to let the later check pass *)
       let mutated = if value.mut then ref false else ref true in
       Hashtbl.add tbl key
         { loc; used = ref false; imported = value.imported; mutated });

      { env with values = { scope with valmap } :: tl }

let add_external ext_name ~cname typ ~imported ~closure loc env =
  let env, used =
    match env.values with
    | [] -> failwith "Internal Error: Env empty"
    | scope :: tl ->
        let valmap =
          Map.add ext_name
            {
              def_value with
              typ;
              imported = Option.is_some imported;
              global = true;
            }
            scope.valmap
        in

        let used = ref false in
        (* external things cannot be mutated right now *)
        let mutated = ref true in
        let tbl = scope.used in
        Hashtbl.add tbl ext_name
          { loc; used; imported = Option.is_some imported; mutated };

        ({ env with values = { scope with valmap } :: tl }, used)
  in
  let tkey = Type_key.create ext_name in
  let vl =
    { ext_name; ext_typ = typ; ext_cname = cname; imported; used; closure }
  in
  env.externals := Emap.add tkey vl !(env.externals);
  env

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
  let types = Tmap.add key t env.types in
  { env with types }

let add_record record ~params ~labels env =
  let typ = Trecord (params, Some record, labels) in

  let labelset =
    Array.to_seq labels |> Seq.map (fun f -> f.fname) |> Labelset.of_seq
  in
  let labelsets = Lmap.add labelset record env.labelsets in

  let _, labels =
    Array.fold_left
      (fun (index, labels) field ->
        (index + 1, Map.add field.fname { index; typename = record } labels))
      (0, env.labels) labels
  in
  let types = Tmap.add record typ env.types in
  { env with labels; types; labelsets }

let add_variant variant ~params ~ctors env =
  let typ = Tvariant (params, variant, ctors) in

  let _, ctors =
    Array.fold_left
      (fun (index, ctors) (ctor : ctor) ->
        (index + 1, Map.add ctor.cname { index; typename = variant } ctors))
      (0, env.ctors) ctors
  in
  let types = Tmap.add variant typ env.types in
  { env with ctors; types }

let add_alias name typ env =
  let types = Tmap.add name (Talias (name, typ)) env.types in
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
        if used.imported then acc
        else if not !(used.used) then (name, Unused, used.loc) :: acc
        else if not !(used.mutated) then (name, Unmutated, used.loc) :: acc
        else acc)
      tbl ret
  in
  match ret with
  | [] -> Ok ()
  | some ->
      (* Sort the warnings so the ones form the start of file are printed first *)
      let some =
        List.sort
          (fun (_, _, ((lhs : Lexing.position), _)) (_, _, (rhs, _)) ->
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
        |> List.filter_map (fun clname ->
               (* We only add functions to the closure if they are params
                  Or: if they are closures *)
               let { typ; param; const; global; imported; mut = clmut } =
                 find_val_raw clname env
               in
               (* Const values (and imported ones) are not closed over, they exist module-wide *)
               if const || global || imported then None
               else
                 match clean typ with
                 | Tfun (_, _, Closure _) -> Some { clname; cltyp = typ; clmut }
                 | Tfun _ when not param -> None
                 | _ -> Some { clname; cltyp = typ; clmut })
      in

      let unused = find_unused [] scope.used in
      ({ env with values = tl }, closed, unused)

let find_val_opt key env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.valmap with
        | None -> aux tl
        | Some vl ->
            Some
              {
                typ = vl.typ;
                const = vl.const;
                global = vl.global;
                mut = vl.mut;
              })
  in
  aux env.values

let find_val key env =
  match find_val_opt key env with Some vl -> vl | None -> raise Not_found

let mark_used name tbl mut =
  match Hashtbl.find_opt tbl name with
  | Some (used : usage) ->
      if !mut > 0 then used.mutated := true;
      used.used := true
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
        | Some { typ; const; imported; global; mut; param = _ } ->
            (* If something is closed over, add to all env above (if scope_lvl > 0) *)
            (match scope_lvl with 0 -> () | _ -> add scope_lvl key env.values);
            (* Mark value used, if it's not imported *)
            if not imported then mark_used key scope.used env.in_mut;
            Some { typ; const; global; mut })
  in
  aux 0 env.values

let find_type_opt key env = Tmap.find_opt key env.types
let find_type key env = Tmap.find key env.types
let query_type ~instantiate key env = Tmap.find key env.types |> instantiate
let find_label_opt key env = Map.find_opt key env.labels

let find_labelset_opt labels env =
  match Lmap.find_opt (Labelset.of_list labels) env.labelsets with
  | Some name -> Some (find_type name env)
  | None -> None

let find_ctor_opt name env = Map.find_opt name env.ctors

let externals env =
  Emap.bindings !(env.externals)
  |> List.sort Type_key.cmp_map_sort
  |> List.map snd

let open_mutation env = incr env.in_mut
let close_mutation env = decr env.in_mut
