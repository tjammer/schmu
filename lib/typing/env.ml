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

type value = {
  typ : typ;
  param : bool;
  (* More like force-capture *)
  const : bool;
  global : bool;
  mut : bool;
  mname : Path.t option;
}

module Used_value = struct
  type t = key * value

  let compare (ak, av) (bk, bv) =
    let p s = match s with Some p -> Path.show p | None -> "" in
    String.compare (p av.mname ^ ak) (p bv.mname ^ bk)
end

module Closed_set = Set.Make (Used_value)
module Set = Set.Make (String)

type usage = {
  loc : Ast.loc;
  used : bool ref;
  imported : bool;
  mutated : bool ref;
}

type ext = {
  ext_name : string;
  ext_typ : typ;
  ext_cname : string option;
  imported : (Path.t * [ `C | `Schmu ]) option;
  used : bool ref;
  closure : bool;
}

type usage_tbl = (Path.t, usage) Hashtbl.t

type module_usage = { name : Path.t; loc : Ast.loc; used : bool ref }

and touched = {
  tname : string;
  ttyp : typ;
  tattr : Ast.decl_attr;
  tattr_loc : Ast.loc option;
  tmname : Path.t option;
}

type scope_kind =
  | Stoplevel of usage_tbl
  | Sfunc of usage_tbl
  | Smodule of module_usage
  | Scont of usage_tbl

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
  module_types : Module_type.t Map.t;
  cnames : string Map.t; (* callnames for functions *)
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
  scope_of_located : t -> Path.t -> (scope, string) result;
}

type warn_kind = Unused | Unmutated | Unused_mod
type unused = (Path.t * warn_kind * Ast.loc) list

let def_value env =
  {
    typ = Tunit;
    param = false;
    const = false;
    global = false;
    mut = false;
    mname = Some env.modpath;
  }

let def_mname mname =
  {
    typ = Tunit;
    param = false;
    const = false;
    global = false;
    mut = false;
    mname = Some mname;
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
    module_types = Map.empty;
    cnames = Map.empty;
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

let is_imported modpath = function
  | None -> false
  | Some mname -> Path.share_base mname modpath |> not

let add_value key value loc env =
  match env.values with
  | [] -> failwith "Internal Error: Env empty"
  | scope :: tl ->
      let valmap = Map.add key value scope.valmap in

      (* Shadowed bindings stay in the Hashtbl, but are not reachable.
         Thus, warning for unused shadowed bindings works *)
      (match scope.kind with
      | Stoplevel tbl | Sfunc tbl | Scont tbl ->
          let mutated = if value.mut then ref false else ref true in
          Hashtbl.add tbl (Path.Pid key)
            {
              loc;
              used = ref false;
              imported = is_imported env.modpath value.mname;
              mutated;
            }
      | Smodule _ -> assert (Option.is_some value.mname));

      { env with values = { scope with valmap } :: tl }

let add_external ext_name ~cname typ loc env =
  let env, used =
    match env.values with
    | [] -> failwith "Internal Error: Env empty"
    | scope :: tl ->
        let value =
          {
            typ;
            mname = Some env.modpath;
            (* Give externals a modpath for name resolution across modules *)
            global = true;
            const = false;
            mut = false;
            param = false;
          }
        in
        let valmap = Map.add ext_name value scope.valmap in

        let used = ref false in
        (match scope.kind with
        | Stoplevel tbl | Sfunc tbl | Scont tbl ->
            (* external things cannot be mutated right now *)
            let mutated = ref true in
            Hashtbl.add tbl (Path.Pid ext_name)
              { loc; used; imported = false; mutated }
        | Smodule _ -> failwith "Internal Error: add_external on Smodule");

        ({ env with values = { scope with valmap } :: tl }, used)
  in
  let tkey = Type_key.create ext_name in
  let vl =
    {
      ext_name;
      ext_typ = typ;
      ext_cname = cname;
      imported = None;
      used;
      closure = false;
    }
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

let mark_unused key env =
  match env.values with
  | [] -> failwith "Internal Error: Env empty"
  | scope :: _ -> (
      match scope.kind with
      | Stoplevel tbl | Sfunc tbl | Scont tbl -> (
          match Hashtbl.find_opt tbl (Path.Pid key) with
          | Some usage -> usage.used := false
          | None ->
              "Internal Error: Missing key for unmarking used " ^ key
              |> failwith)
      | Smodule _ ->
          failwith "Internal Error: Should not be module for unmarking function"
      )

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

let get_module env loc = function
  | Cm_cached (path, scope) -> (path, scope)
  | Cm_located path -> (
      match env.scope_of_located env path with
      | Ok scope -> (path, scope)
      | Error s -> raise (Error.Error (loc, s)))

let add_module_alias loc ~key ~mname env =
  let rs key =
    let msg = "Cannot find module: " ^ key ^ " in " ^ Path.show mname in
    raise (Error.Error (loc, msg))
  in
  let rec start env = function
    | Path.Pid key -> env.find_module env loc key
    | Pmod (key, tl) ->
        let scope = env.find_module env loc key |> get_module env loc |> snd in
        add scope tl
  and add scope = function
    | Path.Pid key -> (
        match Map.find_opt key scope.modules with Some m -> m | None -> rs key)
    | Pmod (key, tl) -> (
        match Map.find_opt key scope.modules with
        | Some cached ->
            let scope = get_module env loc cached |> snd in
            add scope tl
        | None -> rs key)
  in
  let cached_module = start env mname in
  add_module ~key cached_module env

let add_module_type key mtype env =
  let scope, tl = decap_exn env in
  let module_types = Map.add key mtype scope.module_types in
  { env with values = { scope with module_types } :: tl }

let open_thing thing modpath env =
  (* Due to the ref, we have to create a new object every time *)
  (match env.values with
  | { kind = Sfunc _ | Scont _ | Stoplevel _; _ } :: _ -> ()
  | _ -> failwith "Internal Error: Module not finished in env (function)");
  { env with values = empty_scope thing :: env.values; modpath }

let open_function env = open_thing (Sfunc (Hashtbl.create 64)) env.modpath env

let open_toplevel modpath env =
  open_thing (Stoplevel (Hashtbl.create 64)) modpath env

let find_unused ret tbl =
  Hashtbl.fold
    (fun name (used : usage) acc ->
      if used.imported then acc
      else if not !(used.used) then (name, Unused, used.loc) :: acc
      else if not !(used.mutated) then (name, Unmutated, used.loc) :: acc
      else acc)
    tbl ret

let rec is_module_used modules =
  Map.fold
    (fun _ kind used ->
      match kind with
      | Cm_located _ -> used
      | Cm_cached (_, scope) -> (
          if used then used
          else
            match scope.kind with
            | Smodule usage ->
                if !(usage.used) then true else is_module_used scope.modules
            | _ -> failwith "unreachable"))
    modules false

let sort_unused unused =
  (* Sort the warnings so the ones form the start of file are printed first *)
  List.sort
    (fun (_, _, ((lhs : Lexing.position), _)) (_, _, (rhs, _)) ->
      if lhs.pos_lnum <> rhs.pos_lnum then Int.compare lhs.pos_lnum rhs.pos_lnum
      else Int.compare lhs.pos_cnum rhs.pos_cnum)
    unused

let close_thing is_same modpath env =
  (* Close scopes up to next function scope *)
  let rec aux old_closed old_touched unused = function
    | [] -> failwith "Internal Error: Env empty"
    | scope :: tl -> (
        let closed_touched =
          !(scope.closed) |> Closed_set.to_seq |> List.of_seq
          |> List.map
               (fun
                 (clname, { typ; param; const; global; mname; mut = clmut }) ->
                 (* We only add functions to the closure if they are params
                    Or: if they are closures *)
                 (* Const values (and imported ones) are not closed over, they exist module-wide *)
                 let is_imported = is_imported env.modpath mname in
                 let cleantyp = clean typ in
                 let cl =
                   if (const && not clmut) || global || is_imported then None
                   else
                     let cltyp = typ
                     and clparam = param
                     and clmname = mname
                     and clcopy = false in
                     (* clcopy will be changed it typing *)
                     match cleantyp with
                     | Tfun (_, _, Closure _) ->
                         Some { clname; cltyp; clmut; clparam; clmname; clcopy }
                     | Tfun _ when not param -> None
                     | _ ->
                         Some { clname; cltyp; clmut; clparam; clmname; clcopy }
                 in

                 let t =
                   let t =
                     {
                       tname = clname;
                       ttyp = typ;
                       tattr = Dnorm;
                       tattr_loc = None;
                       tmname = mname;
                     }
                   in
                   match cleantyp with
                   | Tfun (_, _, Closure _) -> Some t
                   | Tfun _ when not param -> None
                   | _ -> Some t
                 in

                 (cl, t))
        in
        let closed, touched = List.split closed_touched in
        let closed = List.filter_map Fun.id closed in
        let touched = List.filter_map Fun.id touched in

        match scope.kind with
        | (Stoplevel usage | Sfunc usage) when is_same scope.kind ->
            let unused = find_unused unused usage in
            ( { env with values = tl; modpath },
              closed @ old_closed,
              touched @ old_touched,
              sort_unused unused )
        | Stoplevel _ | Sfunc _ ->
            failwith "Internal Error: Unexpected scope type"
        | Scont usage ->
            let unused = find_unused unused usage in
            aux (closed @ old_closed) (touched @ old_touched) unused tl
        | Smodule { name; loc; used } ->
            let unused =
              if !used || is_module_used scope.modules then unused
              else (name, Unused_mod, loc) :: unused
            in
            aux (closed @ old_closed) (touched @ old_touched) unused tl)
  in
  aux [] [] [] env.values

let close_function env =
  close_thing
    (fun thing -> match thing with Sfunc _ -> true | _ -> false)
    env.modpath env

let close_toplevel env =
  close_thing
    (fun thing -> match thing with Stoplevel _ -> true | _ -> false)
    (Path.pop env.modpath) env

let find_general ~(find : key -> scope -> 'a option)
    ~(found : scope_kind -> 'a -> 'b) loc key env =
  (* Find the start of the path in some scope. Then traverse modules until we
     find the type. If we remove the modpath we make sure to not find the value
     in a imported module *)
  let of_base, key = Path.rm_path env.modpath key in
  let rec aux scopes = function
    | Path.Pid key -> find_value ~of_base key scopes
    | Pmod (hd, tl) -> (
        match find_module hd scopes with
        | Some scope -> traverse_module scope tl
        | None ->
            let scope =
              env.find_module env loc hd |> get_module env loc |> snd
            in
            traverse_module scope tl)
  and find_value ~of_base key = function
    | [] -> None
    | scope :: tl -> (
        match find key scope with
        | Some t -> (
            (* If the value comes from base module, we must not find it in a
               module type scope *)
            match scope.kind with
            | Smodule _ when of_base -> find_value ~of_base key tl
            | _ -> Some (found scope.kind t))
        | None -> find_value ~of_base key tl)
  and find_module key = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.modules with
        | Some cached ->
            let scope = get_module env loc cached |> snd in
            Some scope
        | None -> find_module key tl)
  and traverse_module scope = function
    | Path.Pid key -> Option.map (found scope.kind) (find key scope)
    | Pmod (hd, tl) -> (
        match Map.find_opt hd scope.modules with
        | Some cached ->
            let scope = get_module env loc cached |> snd in
            traverse_module scope tl
        | None -> None)
  in
  aux env.values key

let find_val_opt loc key env =
  find_general
    ~find:(fun key scope -> Map.find_opt key scope.valmap)
    ~found:(fun _ vl ->
      let mname = if vl.param then None else vl.mname in
      {
        typ = vl.typ;
        const = vl.const;
        global = vl.global;
        mut = vl.mut;
        mname;
        param = vl.param;
      })
    loc key env

let find_val loc key env =
  match find_val_opt loc key env with Some vl -> vl | None -> raise Not_found

let mark_used name kind mut =
  match kind with
  | Stoplevel tbl | Sfunc tbl | Scont tbl -> (
      match Hashtbl.find_opt tbl name with
      | Some (used : usage) ->
          if !mut > 0 then used.mutated := true;
          used.used := true
      | None -> ())
  | Smodule usage -> usage.used := true

let query_val_opt loc pkey env =
  (* Copies some code from [find_general] *)
  let rec add lvl value values =
    match values with
    | scope :: tl when lvl > 0 -> (
        match scope.kind with
        | Stoplevel _ ->
            scope.closed := Closed_set.add value !(scope.closed);
            add (lvl - 1) value tl
        | Sfunc _ ->
            scope.closed := Closed_set.add value !(scope.closed);
            add (lvl - 1) value tl
        | Scont _ | Smodule _ -> add lvl value tl)
    | _ -> ()
  in

  let found key lvl kind ({ typ; const; mname; global; mut; param } as v) =
    let in_module =
      match kind with
      | Smodule _ -> true
      | Stoplevel _ | Sfunc _ | Scont _ -> false
    in
    if lvl > 0 then add lvl (key, v) env.values
    else if (* Add values in modules to scope list *)
            in_module then add 1 (key, v) env.values;
    (* Mark value used, if it's not imported *)
    mark_used (Path.Pid key) kind env.in_mut;
    Some { typ; const; global; mut; mname; param }
  in

  let continue key lvl kind tl cont =
    match kind with
    | Stoplevel _ | Sfunc _ ->
        (* Increase scope level normally *)
        cont (lvl + 1) key tl
    | Scont _ | Smodule _ ->
        (* We are still in the same functionlike scope *)
        cont lvl key tl
  in

  let rec aux lvl scopes = function
    | Path.Pid key -> find_value lvl key scopes
    | Pmod (hd, tl) -> (
        match find_module lvl hd scopes with
        | Some scope -> traverse_module lvl scope tl
        | None ->
            let scope =
              env.find_module env loc hd |> get_module env loc |> snd
            in
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
            let scope = get_module env loc cached |> snd in
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
            let scope = get_module env loc cached |> snd in
            traverse_module lvl scope tl
        | None -> None)
  in

  aux 0 env.values pkey

let find_type_opt loc key env =
  find_general
    ~find:(fun key scope -> Map.find_opt key scope.types)
    ~found:(fun _ f -> f)
    loc key env

let find_type loc key env = find_type_opt loc key env |> Option.get

let find_type_same_module key env =
  (* Similar to [find_type_opt] but when we reach a Sfunc scope and haven't found
     anything,we return None. This only works because the toplevel has Sfunc
     instead of Smodule, and type declarations are only allowed at toplevel so no
     function scope can be introduced*)
  let full_name = Path.append key env.modpath in
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match (Map.find_opt key scope.types, scope.kind) with
        | None, Sfunc _ -> None
        | None, _ -> aux tl
        | Some t, _ ->
            (* Only named types are in the env. Extracting names of named types should never fail *)
            let path = extract_name_path (fst t) |> Option.get in
            if Path.equal full_name path then Some t else aux tl)
  in
  aux env.values

let mark_module_used = function Smodule usage -> usage.used := true | _ -> ()

let query_type ~instantiate loc key env =
  find_general
    ~find:(fun key scope ->
      match (Map.find_opt key scope.types, scope.kind) with
      | Some t, Smodule { used; _ } ->
          used := true;
          Some (fst t)
      | Some t, (Stoplevel _ | Sfunc _ | Scont _) -> Some (fst t)
      | None, _ -> None)
    ~found:(fun kind f ->
      mark_module_used kind;
      f)
    loc key env
  |> Option.get |> instantiate

let find_module_opt ?(query = false) loc name env =
  find_general
    ~find:(fun key scope -> Map.find_opt key scope.modules)
    ~found:(fun scope kind ->
      if query then mark_module_used scope;
      match kind with Cm_located path | Cm_cached (path, _) -> path)
    loc name env

let find_module_type_opt loc name env =
  find_general
    ~find:(fun key scope -> Map.find_opt key scope.module_types)
    ~found:(fun scope mtype ->
      mark_module_used scope;
      mtype)
    loc name env

let find_label_opt key env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt key scope.labels with
        | Some l ->
            mark_module_used scope.kind;
            Some l
        | None -> aux tl)
  in
  aux env.values

let find_labelset_opt loc labels env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Lmap.find_opt (Labelset.of_list labels) scope.labelsets with
        | Some name ->
            mark_module_used scope.kind;
            Some (find_type loc name env |> fst)
        | None -> aux tl)
  in
  aux env.values

let find_ctor_opt name env =
  let rec aux = function
    | [] -> None
    | scope :: tl -> (
        match Map.find_opt name scope.ctors with
        | Some c ->
            mark_module_used scope.kind;
            Some c
        | None -> aux tl)
  in
  aux env.values

let rec make_alias_usable scope = function
  | Trecord (_, Some name, labels) ->
      let labelset =
        Array.to_seq labels |> Seq.map (fun f -> f.fname) |> Labelset.of_seq
      in
      let labelsets, labels = add_labels name labelset labels scope in
      { scope with labelsets; labels }
  | Tvariant (_, name, ctors) ->
      let ctors = add_ctors name ctors scope in
      { scope with ctors }
  | Talias (_, typ) -> make_alias_usable scope typ
  | _ -> scope

let add_alias name alias in_sig typ env =
  let scope, tl = decap_exn env in

  let scope = make_alias_usable scope typ in
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
let modpath env = env.modpath

let open_module_scope env loc name =
  let used = ref false in
  {
    env with
    values = empty_scope (Smodule { name; loc; used }) :: env.values;
    modpath = name;
  }

let pop_scope env =
  match env.values with
  | ({ kind = Smodule _; _ } as hd) :: _ -> hd
  | _ -> failwith "Internal Error: Not a module scope in [pop_scope]"

let fix_scope_loc scope loc =
  let kind =
    match scope.kind with
    | Smodule usage -> Smodule { usage with loc; used = ref false }
    | (Stoplevel _ | Sfunc _ | Scont _) as kind -> kind
  in
  { scope with kind }

let import_module env loc name =
  let scope =
    find_general
      ~find:(fun key scope -> Map.find_opt key scope.modules)
      ~found:(fun scope cached_module ->
        mark_module_used scope;
        cached_module)
      loc name env
    |> (function
         | Some m -> m | None -> env.find_module env loc (Path.get_hd name))
    |> get_module env loc |> snd
    |> fun scope -> fix_scope_loc scope loc
  in

  let cont = empty_scope (Scont (Hashtbl.create 64)) in
  { env with values = cont :: scope :: env.values }

let add_callname ~key cname env =
  let scope, tl = decap_exn env in
  let cnames = Map.add key cname scope.cnames in
  { env with values = { scope with cnames } :: tl }

let find_callname loc path env =
  find_general
    ~find:(fun key scope -> Map.find_opt key scope.cnames)
    ~found:(fun _ cname -> cname)
    loc path env
  |> function
  | None -> failwith "Internal Error: Could not find callname"
  | Some cname -> cname
