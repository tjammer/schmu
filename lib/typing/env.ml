open Types

module Type_key = struct
  (* We have to remember the order of type declaration *)
  let state = ref 0

  type t = { key : string; ord : int }

  let equal a b = String.equal a.key b.key
  let hash a = Hashtbl.hash a.key
  let cmp_map_sort (a, _) (b, _) = Int.compare a.ord b.ord

  let create key =
    let ord = !state in
    incr state;
    { key; ord }
end

module Labelset = Set.Make (String)
module Lmap = Map.Make (Labelset)
module Tmap = Map.Make (Path)
module Etbl = Hashtbl.Make (Type_key)
module Map = Map.Make (String)
module Set = Set.Make (String)

type key = string

type label = {
  index : int; (* index of laber in record labels array *)
  typename : Path.t;
}

type imported = string * [ `C | `Schmu ]

type value = {
  typ : typ;
  param : bool;
  const : bool;
  global : bool;
  imported : imported option;
  mut : bool;
}

type usage = {
  loc : Ast.loc;
  used : bool ref;
  imported : bool;
  mutated : bool ref;
}

type return = {
  typ : typ;
  const : bool;
  global : bool;
  mut : bool;
  imported : string option;
}

type ext = {
  ext_name : string;
  ext_typ : typ;
  ext_cname : string option;
  imported : imported option;
  used : bool ref;
  closure : bool;
}

type usage_tbl = (Path.t, usage) Hashtbl.t
type module_usage = { name : string; loc : Ast.loc; used : bool ref }

type scope_kind =
  | Sfunc of usage_tbl
  | Smodule of module_usage
  | Sfunc_cont of usage_tbl

(* function scope *)
type scope = {
  valmap : value Map.t;
  closed : Set.t ref;
  labels : label Map.t; (* For single labels (field access) *)
  labelsets : Path.t Lmap.t; (* For finding the type of a record expression *)
  ctors : label Map.t; (* Variant constructors *)
  types : (typ * bool) Tmap.t;
  kind : scope_kind; (* Another list for local scopes (like in if) *)
}

(* Reference types make it easy to track usage. As a consequence we have to keep the scopes themselves
   in another structure. Ie. the scope list. Labelset etc data is immutable and goes out of scope
   naturally, so no extra handling is needed there. *)

type t = {
  values : scope list;
  externals : ext Etbl.t;
      (* externals won't collide between scopes and modules, thus we keep a reference type here *)
  in_mut : int ref;
}

type warn_kind = Unused | Unmutated | Unused_mod
type unused = (unit, (Path.t * warn_kind * Ast.loc) list) result
type add_kind = Aimpl | Asignature | Amodule of string

let def_value =
  {
    typ = Tunit;
    param = false;
    const = false;
    global = false;
    imported = None;
    mut = false;
  }

let empty_scope kind =
  {
    valmap = Map.empty;
    closed = ref Set.empty;
    labels = Map.empty;
    labelsets = Lmap.empty;
    ctors = Map.empty;
    types = Tmap.empty;
    kind;
  }

let empty () =
  {
    values = [ empty_scope (Sfunc (Hashtbl.create 64)) ];
    externals = Etbl.create 64;
    in_mut = ref 0;
  }

let decap_exn env =
  match env.values with
  | [] -> failwith "Internal Error: Env empty"
  | scope :: tl -> (scope, tl)

let add_value key value loc env =
  match env.values with
  | [] -> failwith "Internal Error: Env empty"
  | scope :: tl ->
      let valmap = Map.add key value scope.valmap in

      (* Shadowed bindings stay in the Hashtbl, but are not reachable.
         Thus, warning for unused shadowed bindings works *)
      (match scope.kind with
      | Sfunc tbl | Sfunc_cont tbl ->
          let mutated = if value.mut then ref false else ref true in
          Hashtbl.add tbl (Path.Pid key)
            {
              loc;
              used = ref false;
              imported = Option.is_some value.imported;
              mutated;
            }
      | Smodule _ -> assert (Option.is_some value.imported));

      { env with values = { scope with valmap } :: tl }

let add_external ext_name ~cname typ ~imported ~closure loc env =
  let env, used =
    match env.values with
    | [] -> failwith "Internal Error: Env empty"
    | scope :: tl ->
        let valmap =
          Map.add ext_name
            { def_value with typ; imported; global = true }
            scope.valmap
        in

        let used = ref false in
        (match scope.kind with
        | Sfunc tbl | Sfunc_cont tbl ->
            (* external things cannot be mutated right now *)
            let mutated = ref true in
            Hashtbl.add tbl (Path.Pid ext_name)
              { loc; used; imported = Option.is_some imported; mutated }
        | Smodule _ -> assert (Option.is_some imported));

        ({ env with values = { scope with valmap } :: tl }, used)
  in
  let tkey = Type_key.create ext_name in
  let vl =
    { ext_name; ext_typ = typ; ext_cname = cname; imported; used; closure }
  in
  Etbl.add env.externals tkey vl;
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

let add_record record add_kind ~params ~labels env =
  let scope, tl = decap_exn env in
  let typ = Trecord (params, Some record, labels) in
  let name, in_sig =
    match add_kind with
    | Aimpl -> (record, false)
    | Asignature -> (record, true)
    | Amodule m -> (Path.rm_name m record, false)
  in

  let labelset =
    Array.to_seq labels |> Seq.map (fun f -> f.fname) |> Labelset.of_seq
  in

  let labelsets = Lmap.add labelset name scope.labelsets in

  let _, labels =
    Array.fold_left
      (fun (index, labels) field ->
        (index + 1, Map.add field.fname { index; typename = name } labels))
      (0, scope.labels) labels
  in
  let types = Tmap.add name (typ, in_sig) scope.types in
  { env with values = { scope with labels; types; labelsets } :: tl }

let add_variant variant add_kind ~params ~ctors env =
  let scope, tl = decap_exn env in
  let typ = Tvariant (params, variant, ctors) in
  let name, in_sig =
    match add_kind with
    | Aimpl -> (variant, false)
    | Asignature -> (variant, true)
    | Amodule m -> (Path.rm_name m variant, false)
  in

  let _, ctors =
    Array.fold_left
      (fun (index, ctors) (ctor : ctor) ->
        (index + 1, Map.add ctor.cname { index; typename = name } ctors))
      (0, scope.ctors) ctors
  in
  let types = Tmap.add name (typ, in_sig) scope.types in
  { env with values = { scope with ctors; types } :: tl }

let add_alias alias add_kind typ env =
  let scope, tl = decap_exn env in
  let name, in_sig =
    match add_kind with
    | Aimpl -> (alias, false)
    | Asignature -> (alias, true)
    | Amodule m -> (Path.rm_name m alias, false)
  in
  let typ = Talias (alias, typ) in
  let types = Tmap.add name (typ, in_sig) scope.types in
  { env with values = { scope with types } :: tl }

let add_type name add_kind typ env =
  match typ with
  | Trecord (params, Some n, labels) ->
      add_record n add_kind ~params ~labels env
  | Tvariant (params, n, ctors) -> add_variant n add_kind ~params ~ctors env
  | Talias (n, t) -> add_alias n add_kind t env
  | t ->
      let in_sig =
        match add_kind with Aimpl | Amodule _ -> false | Asignature -> true
      in
      let scope, tl = decap_exn env in
      let types = Tmap.add name (t, in_sig) scope.types in
      { env with values = { scope with types } :: tl }

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
  (match env.values with
  | { kind = Sfunc _ | Sfunc_cont _; _ } :: _ -> ()
  | _ -> failwith "Internal Error: Module not finished in env (function)");
  { env with values = empty_scope (Sfunc (Hashtbl.create 64)) :: env.values }

let open_module env loc name =
  let used = ref false in
  (match env.values with
  | { kind = Sfunc _ | Sfunc_cont _; _ } :: _ -> ()
  | _ -> failwith "Internal Error: Module not finished in env");
  { env with values = empty_scope (Smodule { name; loc; used }) :: env.values }

let finish_module env =
  (match env.values with
  | { kind = Smodule _; _ } :: _ -> ()
  | _ -> failwith "Internal Error: Module not opened in env (cont)");
  let scope = empty_scope (Sfunc_cont (Hashtbl.create 64)) in
  { env with values = scope :: env.values }

let close_module env =
  (match env.values with
  | { kind = Sfunc _ | Sfunc_cont _; _ } :: _ -> ()
  | _ -> failwith "Internal Error: Module not opened in env (close)");
  let rec aux before = function
    | { kind = Smodule _; _ } :: tl ->
        (* Found the module *)
        (* TODO check for unused *)
        List.rev_append before tl
    | ({ kind = Sfunc _ | Sfunc_cont _; _ } as scope) :: tl ->
        aux (scope :: before) tl
    | [] -> failwith "Internal Error: Empty scope on close_module"
  in
  { env with values = aux [] env.values }

let find_unused ret tbl =
  Hashtbl.fold
    (fun name (used : usage) acc ->
      if used.imported then acc
      else if not !(used.used) then (name, Unused, used.loc) :: acc
      else if not !(used.mutated) then (name, Unmutated, used.loc) :: acc
      else acc)
    tbl ret

let sort_unused = function
  | [] -> Ok ()
  | some ->
      (* Sort the warnings so the ones form the start of file are printed first *)
      let s =
        List.sort
          (fun (_, _, ((lhs : Lexing.position), _)) (_, _, (rhs, _)) ->
            if lhs.pos_lnum <> rhs.pos_lnum then
              Int.compare lhs.pos_lnum rhs.pos_lnum
            else Int.compare lhs.pos_cnum rhs.pos_cnum)
          some
      in
      Error s

let close_function env =
  (* Close scopes up to next function scope *)
  let rec aux old_closed unused = function
    | [] -> failwith "Internal Error: Env empty"
    | scope :: tl -> (
        let closed =
          !(scope.closed) |> Set.to_seq |> List.of_seq
          |> List.filter_map (fun clname ->
                 (* We only add functions to the closure if they are params
                    Or: if they are closures *)
                 let { typ; param; const; global; imported; mut = clmut } =
                   find_val_raw clname env
                 in
                 (* Const values (and imported ones) are not closed over, they exist module-wide *)
                 if const || global || Option.is_some imported then None
                 else
                   match clean typ with
                   | Tfun (_, _, Closure _) ->
                       Some { clname; cltyp = typ; clmut; clparam = param }
                   | Tfun _ when not param -> None
                   | _ -> Some { clname; cltyp = typ; clmut; clparam = param })
        in

        match scope.kind with
        | Sfunc usage ->
            let unused = find_unused unused usage in
            ({ env with values = tl }, closed @ old_closed, sort_unused unused)
        | Sfunc_cont usage ->
            let unused = find_unused unused usage in
            aux (closed @ old_closed) unused tl
        | Smodule { name; loc; used } ->
            let unused =
              if !used then unused
              else (Path.Pid name, Unused_mod, loc) :: unused
            in
            aux (closed @ old_closed) unused tl)
  in
  aux [] [] env.values

let find_val_opt key env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.valmap with
        | None -> aux tl
        | Some vl ->
            let imported = Option.map fst vl.imported in
            Some
              {
                typ = vl.typ;
                const = vl.const;
                global = vl.global;
                mut = vl.mut;
                imported;
              })
  in
  aux env.values

let find_val key env =
  match find_val_opt key env with Some vl -> vl | None -> raise Not_found

let mark_used name kind mut =
  match kind with
  | Sfunc tbl | Sfunc_cont tbl -> (
      match Hashtbl.find_opt tbl name with
      | Some (used : usage) ->
          if !mut > 0 then used.mutated := true;
          used.used := true
      | None -> ())
  | Smodule usage -> usage.used := true

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
        | None -> (
            match scope.kind with
            | Sfunc _ ->
                (* Increase scope level normally *)
                aux (scope_lvl + 1) tl
            | Sfunc_cont _ | Smodule _ ->
                (* We are still in the same functionlike scope *)
                aux scope_lvl tl)
        | Some { typ; const; imported; global; mut; param = _ } ->
            (* If something is closed over, add to all env above (if scope_lvl > 0) *)
            (match scope_lvl with 0 -> () | _ -> add scope_lvl key env.values);
            (* Mark value used, if it's not imported *)
            mark_used (Path.Pid key) scope.kind env.in_mut;
            let imported = Option.map fst imported in
            Some { typ; const; global; mut; imported })
  in
  aux 0 env.values

let find_type_opt key env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Tmap.find_opt key scope.types with
        | Some t -> Some t
        | None -> aux tl)
  in
  aux env.values

let find_type key env = find_type_opt key env |> Option.get
let query_type ~instantiate key env = find_type key env |> fst |> instantiate

let find_label_opt key env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.labels with
        | Some l -> Some l
        | None -> aux tl)
  in
  aux env.values

let find_labelset_opt labels env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Lmap.find_opt (Labelset.of_list labels) scope.labelsets with
        | Some name -> Some (find_type name env |> fst)
        | None -> aux tl)
  in
  aux env.values

let find_ctor_opt name env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt name scope.ctors with
        | Some c -> Some c
        | None -> aux tl)
  in
  aux env.values

let externals env =
  Etbl.to_seq env.externals |> List.of_seq
  |> List.sort Type_key.cmp_map_sort
  |> List.map snd

let open_mutation env = incr env.in_mut
let close_mutation env = decr env.in_mut
