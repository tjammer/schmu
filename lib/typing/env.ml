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

type key = string

type label = {
  index : int; (* index of laber in record labels array *)
  typename : Path.t;
}

type imported = Path.t * [ `C | `Schmu ]

type value = {
  typ : typ;
  param : bool;
  const : bool;
  global : bool;
  imported : imported option;
  mut : bool;
}

module Used_value = struct
  type t = key * value

  let compare (ak, av) (bk, bv) =
    let p s = match s with Some (p, _) -> Path.show p | None -> "" in
    String.compare (p av.imported ^ ak) (p bv.imported ^ bk)
end

module Closed_set = Set.Make (Used_value)
module Set = Set.Make (String)

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
  imported : Path.t option;
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

type touched_kind = Tnone | Tconst | Tglobal | Timported of Path.t

and touched = {
  tname : string;
  ttyp : typ;
  tattr : Ast.decl_attr;
  tattr_loc : Ast.loc option;
  tkind : touched_kind;
}

type scope_kind =
  | Sfunc of usage_tbl
  | Smodule of module_usage
  | Sfunc_cont of usage_tbl

(* function scope *)
type scope = {
  valmap : value Map.t;
  closed : Closed_set.t ref;
  labels : label Map.t; (* For single labels (field access) *)
  labelsets : Path.t Lmap.t; (* For finding the type of a record expression *)
  ctors : label Map.t; (* Variant constructors *)
  types : (typ * bool) Map.t;
  kind : scope_kind; (* Another list for local scopes (like in if) *)
  modules : cached_module Map.t; (* Locally declared modules *)
}

and cached_module = Cm_located of Path.t | Cm_cached of Path.t * scope

(* Reference types make it easy to track usage. As a consequence we have to keep the scopes themselves
   in another structure. Ie. the scope list. Labelset etc data is immutable and goes out of scope
   naturally, so no extra handling is needed there. *)

type t = {
  values : scope list;
  externals : ext Etbl.t;
      (* externals won't collide between scopes and modules, thus we keep a reference type here *)
  in_mut : int ref;
  modpath : Path.t;
  find_module : t -> Ast.loc -> string -> cached_module;
  scope_of_located : t -> Path.t -> scope;
}

type warn_kind = Unused | Unmutated | Unused_mod
type unused = (unit, (Path.t * warn_kind * Ast.loc) list) result

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
    closed = ref Closed_set.empty;
    labels = Map.empty;
    labelsets = Lmap.empty;
    ctors = Map.empty;
    types = Map.empty;
    kind;
    modules = Map.empty;
  }

let empty ~find_module ~scope_of_located modpath =
  {
    values = [ empty_scope (Sfunc (Hashtbl.create 64)) ];
    externals = Etbl.create 64;
    in_mut = ref 0;
    modpath;
    find_module;
    scope_of_located;
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

let add_labels typename labelset labels scope =
  let labelsets = Lmap.add labelset typename scope.labelsets in

  let _, labels =
    Array.fold_left
      (fun (index, labels) field ->
        (index + 1, Map.add field.fname { index; typename } labels))
      (0, scope.labels) labels
  in

  (labelsets, labels)

let add_ctors typename ctors scope =
  let _, ctors =
    Array.fold_left
      (fun (index, ctors) (ctor : ctor) ->
        (index + 1, Map.add ctor.cname { index; typename } ctors))
      (0, scope.ctors) ctors
  in
  ctors

let add_record name record in_sig ~params ~labels env =
  let scope, tl = decap_exn env in
  let typ = Trecord (params, Some record, labels) in

  let labelset =
    Array.to_seq labels |> Seq.map (fun f -> f.fname) |> Labelset.of_seq
  in

  let labelsets, labels = add_labels record labelset labels scope in

  let types = Map.add name (typ, in_sig) scope.types in
  { env with values = { scope with labels; types; labelsets } :: tl }

let add_variant name variant in_sig ~params ~ctors env =
  let scope, tl = decap_exn env in
  let typ = Tvariant (params, variant, ctors) in

  let ctors = add_ctors variant ctors scope in
  let types = Map.add name (typ, in_sig) scope.types in
  { env with values = { scope with ctors; types } :: tl }

let add_module ~key cached_module env =
  let scope, tl = decap_exn env in
  let modules = Map.add key cached_module scope.modules in
  { env with values = { scope with modules } :: tl }

let get_module env = function
  | Cm_cached (path, scope) -> (path, scope)
  | Cm_located path ->
      let scope = env.scope_of_located env path in
      (path, scope)

let add_module_alias loc ~key ~mname env =
  let rs key =
    let msg = "Cannot finde module: " ^ key ^ " in " ^ Path.show mname in
    raise (Error.Error (loc, msg))
  in
  let rec start env = function
    | Path.Pid key -> env.find_module env loc key
    | Pmod (key, tl) ->
        let scope = env.find_module env loc key |> get_module env |> snd in
        add scope tl
  and add scope = function
    | Path.Pid key -> (
        match Map.find_opt key scope.modules with Some m -> m | None -> rs key)
    | Pmod (key, tl) -> (
        match Map.find_opt key scope.modules with
        | Some cached ->
            let scope = get_module env cached |> snd in
            add scope tl
        | None -> rs key)
  in
  let cached_module = start env mname in
  add_module ~key cached_module env

let open_function env =
  (* Due to the ref, we have to create a new object every time *)
  (match env.values with
  | { kind = Sfunc _ | Sfunc_cont _; _ } :: _ -> ()
  | _ -> failwith "Internal Error: Module not finished in env (function)");
  { env with values = empty_scope (Sfunc (Hashtbl.create 64)) :: env.values }

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
  let usage_kind_of_value ~global ~const imported =
    if global then Tglobal
    else if const then Tconst
    else match imported with Some (p, _) -> Timported p | None -> Tnone
  in

  (* Close scopes up to next function scope *)
  let rec aux old_closed old_touched unused = function
    | [] -> failwith "Internal Error: Env empty"
    | scope :: tl -> (
        let closed_touched =
          !(scope.closed) |> Closed_set.to_seq |> List.of_seq
          |> List.map
               (fun
                 (clname, { typ; param; const; global; imported; mut = clmut })
               ->
                 (* We only add functions to the closure if they are params
                    Or: if they are closures *)
                 (* Const values (and imported ones) are not closed over, they exist module-wide *)
                 let cl =
                   if const || global || Option.is_some imported then None
                   else
                     match clean typ with
                     | Tfun (_, _, Closure _) ->
                         Some { clname; cltyp = typ; clmut; clparam = param }
                     | Tfun _ when not param -> None
                     | _ -> Some { clname; cltyp = typ; clmut; clparam = param }
                 in
                 let tkind = usage_kind_of_value ~global ~const imported in
                 let t =
                   {
                     tname = clname;
                     ttyp = typ;
                     tattr = Dnorm;
                     tkind;
                     tattr_loc = None;
                   }
                 in
                 (cl, t))
        in
        let closed, touched = List.split closed_touched in
        let closed = List.filter_map Fun.id closed in

        match scope.kind with
        | Sfunc usage ->
            let unused = find_unused unused usage in
            ( { env with values = tl },
              closed @ old_closed,
              touched @ old_touched,
              sort_unused unused )
        | Sfunc_cont usage ->
            let unused = find_unused unused usage in
            aux (closed @ old_closed) (touched @ old_touched) unused tl
        | Smodule { name; loc; used } ->
            let unused =
              if !used then unused
              else (Path.Pid name, Unused_mod, loc) :: unused
            in
            aux (closed @ old_closed) (touched @ old_touched) unused tl)
  in
  aux [] [] [] env.values

let find_general ~(find : key -> scope -> 'a option) ~(found : 'a -> 'b) loc key
    env =
  (* Find the start of the path in some scope. Then traverse modules until we find the type *)
  let key = Path.rm_name env.modpath key in
  let rec aux scopes = function
    | Path.Pid key -> find_value key scopes
    | Pmod (hd, tl) ->
        let scope = env.find_module env loc hd |> get_module env |> snd in
        traverse_module scope tl
  and find_value key = function
    | [] -> None
    | scope :: tl -> (
        match find key scope with
        | Some t -> Some (found t)
        | None -> find_value key tl)
  and traverse_module scope = function
    | Path.Pid key -> Option.map found (find key scope)
    | Pmod (hd, tl) -> (
        match Map.find_opt hd scope.modules with
        | Some cached ->
            let scope = get_module env cached |> snd in
            traverse_module scope tl
        | None -> None)
  in
  aux env.values key

let find_val_opt loc key env =
  find_general
    ~find:(fun key scope -> Map.find_opt key scope.valmap)
    ~found:(fun vl ->
      let imported = Option.map fst vl.imported in

      {
        typ = vl.typ;
        const = vl.const;
        global = vl.global;
        mut = vl.mut;
        imported;
      })
    loc key env

let find_val loc key env =
  match find_val_opt loc key env with Some vl -> vl | None -> raise Not_found

let mark_used name kind mut =
  match kind with
  | Sfunc tbl | Sfunc_cont tbl -> (
      match Hashtbl.find_opt tbl name with
      | Some (used : usage) ->
          if !mut > 0 then used.mutated := true;
          used.used := true
      | None -> ())
  | Smodule usage -> usage.used := true

let query_val_opt loc key env =
  (* Copies some code from [find_general] *)
  let rec add lvl value values =
    match values with
    | scope :: tl when lvl > 0 -> (
        match scope.kind with
        | Sfunc _ ->
            scope.closed := Closed_set.add value !(scope.closed);
            add (lvl - 1) value tl
        | Sfunc_cont _ | Smodule _ -> add lvl value tl)
    | _ -> ()
  in

  let found key lvl kind ({ typ; const; imported; global; mut; param = _ } as v)
      =
    let in_module =
      match kind with Smodule _ -> true | Sfunc _ | Sfunc_cont _ -> false
    in
    if lvl > 0 then add lvl (key, v) env.values
    else if (* Add values in modules to scope list *)
            in_module then add 1 (key, v) env.values;
    (* Mark value used, if it's not imported *)
    mark_used (Path.Pid key) kind env.in_mut;
    let imported = Option.map fst imported in
    Some { typ; const; global; mut; imported }
  in

  let continue key lvl kind tl cont =
    match kind with
    | Sfunc _ ->
        (* Increase scope level normally *)
        cont (lvl + 1) key tl
    | Sfunc_cont _ | Smodule _ ->
        (* We are still in the same functionlike scope *)
        cont lvl key tl
  in

  let key = Path.rm_name env.modpath key in
  let rec aux lvl scopes = function
    | Path.Pid key -> find_value lvl key scopes
    | Pmod (hd, tl) -> (
        match find_module lvl hd scopes with
        | Some scope -> traverse_module lvl scope tl
        | None ->
            let scope = env.find_module env loc hd |> get_module env |> snd in
            traverse_module lvl scope tl)
  and find_value lvl key = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.valmap with
        | Some t -> found key lvl scope.kind t
        | None -> continue key lvl scope.kind tl find_value)
  and find_module lvl key = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.modules with
        | Some cached ->
            let scope = get_module env cached |> snd in
            Some scope
        | None -> continue key lvl scope.kind tl find_module)
  and traverse_module lvl scope = function
    | Path.Pid key -> (
        match Map.find_opt key scope.valmap with
        | Some t -> found key lvl scope.kind t
        | None -> None)
    | Pmod (hd, tl) -> (
        match Map.find_opt hd scope.modules with
        | Some cached ->
            let scope = get_module env cached |> snd in
            traverse_module lvl scope tl
        | None -> None)
  in

  aux 0 env.values key

let find_type_opt loc key env =
  find_general
    ~find:(fun key scope -> Map.find_opt key scope.types)
    ~found:Fun.id loc key env

let find_type loc key env = find_type_opt loc key env |> Option.get

let find_type_same_module key env =
  (* Similar to [find_type_opt] but when we reach a Smodule scope and haven't found anything,
     we return None. This only works because the toplevel has Sfunc instead of Smodule *)
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match (Map.find_opt key scope.types, scope.kind) with
        | None, Sfunc _ -> None
        | None, _ -> aux tl
        | Some t, _ -> Some t)
  in
  aux env.values

let query_type ~instantiate loc key env =
  find_type loc key env |> fst |> instantiate

let find_module_opt loc name env =
  find_general
    ~find:(fun key scope -> Map.find_opt key scope.modules)
    ~found:(function Cm_located path | Cm_cached (path, _) -> path)
    loc name env

let find_label_opt key env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.labels with
        | Some l -> Some l
        | None -> aux tl)
  in
  aux env.values

let find_labelset_opt loc labels env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Lmap.find_opt (Labelset.of_list labels) scope.labelsets with
        | Some name -> Some (find_type loc name env |> fst)
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

let rec make_alias_usable name scope = function
  | Trecord (_, _, labels) ->
      let labelset =
        Array.to_seq labels |> Seq.map (fun f -> f.fname) |> Labelset.of_seq
      in
      let labelsets, labels = add_labels name labelset labels scope in
      { scope with labelsets; labels }
  | Tvariant (_, _, ctors) ->
      let ctors = add_ctors name ctors scope in
      { scope with ctors }
  | Talias (_, typ) -> make_alias_usable name scope typ
  | _ -> scope

let add_alias name alias in_sig typ env =
  let scope, tl = decap_exn env in

  let scope = make_alias_usable (Path.Pid name) scope typ in
  let typ = Talias (alias, typ) in
  let types = Map.add name (typ, in_sig) scope.types in
  { env with values = { scope with types } :: tl }

let add_type name ~in_sig typ env =
  match typ with
  | Trecord (params, Some n, labels) ->
      add_record name n in_sig ~params ~labels env
  | Tvariant (params, n, ctors) -> add_variant name n in_sig ~params ~ctors env
  | Talias (n, typ) -> add_alias name n in_sig typ env
  | t ->
      let scope, tl = decap_exn env in
      let types = Map.add name (t, in_sig) scope.types in
      { env with values = { scope with types } :: tl }

let externals env =
  Etbl.to_seq env.externals |> List.of_seq
  |> List.sort Type_key.cmp_map_sort
  |> List.map snd

let open_mutation env = incr env.in_mut
let close_mutation env = decr env.in_mut

let append_modpath name env =
  { env with modpath = Path.append name env.modpath }

let pop_modpath env = { env with modpath = Path.pop env.modpath }
let modpath env = env.modpath

let open_module_scope env loc name =
  let used = ref false in
  { env with values = empty_scope (Smodule { name; loc; used }) :: env.values }

let pop_scope env =
  match env.values with
  | ({ kind = Smodule _; _ } as hd) :: _ -> hd
  | _ -> failwith "Internal Error: Not a module scope in [pop_scope]"

let open_module env loc name =
  let scope = env.find_module env loc name |> get_module env |> snd in
  let cont = empty_scope (Sfunc_cont (Hashtbl.create 64)) in
  { env with values = cont :: scope :: env.values }

let fix_scope_loc scope loc =
  let kind =
    match scope.kind with
    | Smodule usage -> Smodule { usage with loc }
    | (Sfunc _ | Sfunc_cont _) as kind -> kind
  in
  { scope with kind }
