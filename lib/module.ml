open Types
open Error
module S = Set.Make (Path)
module M = Map.Make (Path)
module Pmap = Inference.Pmap
module Sset = Set.Make (String)

type loc = Module_common.loc
type t = Module_common.t

open Module_common

type cache_kind = Cfile of string * bool | Clocal of Path.t

type cached =
  | Located of string * Ast.loc * (typ -> typ)
  | Cached of cache_kind * Env.scope * t
  | Functor of
      Env.scope
      * Path.t
      * (string * intf) list
      * Typed_tree.toplevel_item list
      * t

let module_cache : (Path.t, cached) Hashtbl.t = Hashtbl.create 64
let object_cache = ref Sset.empty
let clear_cache () = Hashtbl.clear module_cache

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)

let empty = { s = []; i = []; objects = [] }

(* For named functions *)
let unique_name = unique_name
let absolute_module_name = absolute_module_name

let lambda_name ~mname id =
  "__fun" ^ "_" ^ Path.mod_name mname ^ string_of_int id

let add_type_sig loc name decl m =
  { m with s = (name, loc, Mtypedef decl) :: m.s }

let add_value_sig loc name t m =
  { m with s = (name, loc, Mvalue (t, None)) :: m.s }

let add_type loc name decl m = { m with i = Mtype (loc, name, decl) :: m.i }

let add_local_module loc id newm ~into =
  { into with i = Mlocal_module (loc, id, newm) :: into.i }

let add_module_alias loc key mname ~into =
  let filename =
    match Hashtbl.find_opt module_cache mname with
    | None | Some (Cached (Clocal _, _, _) | Functor _) -> None
    | Some (Cached (Cfile (f, _), _, _) | Located (f, _, _)) -> Some f
  in
  { into with i = Mmodule_alias (loc, key, mname, filename) :: into.i }

let add_module_type loc id mtype m =
  { m with i = Mmodule_type (loc, id, mtype) :: m.i }

let add_functor loc id params body m ~into =
  { into with i = Mfunctor (loc, id, params, body, m) :: into.i }

let add_applied_functor loc id mname m ~into =
  { into with i = Mapplied_functor (loc, id, mname, m) :: into.i }

let add_fun loc ~mname name uniq abs m =
  { m with i = make_fun loc ~mname name uniq abs :: m.i }

let add_rec_block loc ~mname funs m =
  let m's =
    List.filter_map
      (fun (loc, name, uniq, (abs : Typed_tree.abstraction)) ->
        let typ = type_of_func abs.func in
        if is_polymorphic typ then Some (loc, name, uniq, typ) else None)
      funs
  in
  let i = Mmutual_rec (loc, m's) :: m.i in
  List.fold_left
    (fun m (loc, n, u, abs) -> add_fun ~mname loc n u abs m)
    { m with i } funs

let add_external loc t name call ~closure m =
  let closure = match repr t with Tfun _ -> closure | _ -> false in
  let name = { user = name; call } in
  { m with i = Mext (loc, t, name, closure) :: m.i }

let add_alias loc name tree m = { m with i = Malias (loc, name, tree) :: m.i }

(* Right now we only ever compile one module, so this can safely be global *)
let poly_funcs = ref []
let ext_funcs = ref []
let paths = ref [ "." ]
let append_externals l = List.rev_append !ext_funcs l
let allow_transitive_deps = ref false

let find_file ~name ~suffix =
  let fname = String.lowercase_ascii (name ^ suffix) in
  let ( // ) = Filename.concat in
  let rec path = function
    | p :: tl ->
        let file = p // fname in
        let dir = p // name in
        (* Trim prefix "./" *)
        if Sys.file_exists file then if String.equal p "." then fname else file
        else if
          Sys.file_exists dir && Sys.is_directory dir
          && Sys.file_exists (dir // fname)
        then dir // fname
        else path tl
    | [] -> raise Not_found
  in
  let file = path !paths in
  file

(* Number qvars from 0 and change names of Var-nodes to their unique form.
   _<module_name>_name*)
module Map_canon : Map_module.Map_tree = struct
  type sub = string Smap.t

  let empty_sub () = Smap.empty

  let eagerly_load m =
    match Hashtbl.find_opt module_cache m with
    | None | Some (Located _ | Functor _) ->
        failwith "unreachable what is this module's path?"
    | Some (Cached (Cfile (_, true), _, _)) -> ()
    | Some (Cached (Clocal _, _, _)) ->
        (* NOTE: This should mark its parent somehow, but does not
           currently. *)
        ()
    | Some (Cached (Cfile (name, false), scope, md)) ->
        Hashtbl.replace module_cache m (Cached (Cfile (name, true), scope, md))

  let change_var ~mname id m _ =
    (match m with
    | Some m when not (Path.share_base mname m) ->
        (* Make sure this is eagerly loaded on use *)
        eagerly_load m
    | None | Some _ -> ());
    (id, m)

  let load_type ~mname typ =
    let rec load_type = function
      | Tconstr (name, _) -> (
          match Path.rm_head name with
          | Some m when not (Path.share_base mname m) -> eagerly_load m
          | None | Some _ -> ())
      | Tvar { contents = Link t } | Tfixed_array (_, t) -> load_type t
      | Qvar _ | Tvar { contents = Unbound _ } -> ()
      | Tfun (ps, ret, _) ->
          List.iter (fun p -> load_type p.pt) ps;
          load_type ret
      | Ttuple ts -> List.iter load_type ts
    in
    load_type typ

  let map_decl ~mname _ sub decl =
    let load_type = load_type ~mname in

    let rec map_kind = function
      | Dalias typ -> load_type typ
      | Drecord (_, fields) -> Array.iter (fun f -> load_type f.ftyp) fields
      | Dvariant (_, ctors) ->
          Array.iter (fun ct -> Option.map load_type ct.ctyp |> ignore) ctors
      | Dabstract (Some kind) -> map_kind kind
      | Dabstract _ -> ()
    in

    map_kind decl.kind;
    (sub, decl)

  let absolute_module_name = absolute_module_name

  let map_type ~mname sub typ =
    load_type ~mname typ;
    Map_module.Canonize.canonize sub typ

  let map_callname name _ = name
end

module Canon = Map_module.Make (Map_canon)

let add_ext_item ~mname t n c =
  ext_funcs :=
    Env.
      {
        ext_name = n.user;
        ext_typ = t;
        ext_cname = n.call;
        used = ref false;
        closure = c;
        imported = Some (mname, `C);
      }
    :: !ext_funcs

let rec map_item ~mname ~f = function
  | Mtype (l, n, decl) -> Mtype (l, n, decl)
  | Mfun (l, t, n) ->
      let t = f t in
      ext_funcs :=
        Env.
          {
            ext_name = n.user;
            ext_typ = t;
            ext_cname = n.call;
            used = ref false;
            closure = false;
            imported = Some (mname, `Schmu);
          }
        :: !ext_funcs;
      Mfun (l, t, n)
  | Mext (l, t, n, c) ->
      add_ext_item ~mname t n c;
      let t = f t in
      Mext (l, f t, n, c)
  | Mpoly_fun (l, abs, n, u) ->
      let item = (mname, Typed_tree.Tl_function (l, n, u, abs)) in
      poly_funcs := item :: !poly_funcs;
      (* This will be ignored in [add_to_env] *)
      Mpoly_fun (l, abs, n, u)
  | Mmutual_rec (l, decls) ->
      let decls = List.map (fun (l, n, u, t) -> (l, n, u, f t)) decls in
      let mname_decls = List.map (fun (_, n, u, t) -> (n, u, t)) decls in
      let item = (mname, Typed_tree.Tl_mutual_rec_decls mname_decls) in
      poly_funcs := item :: !poly_funcs;
      Mmutual_rec (l, decls)
  | Malias (l, n, tree) ->
      let item = (mname, Typed_tree.Tl_bind (n, tree)) in
      poly_funcs := item :: !poly_funcs;
      Malias (l, n, tree)
  | Mlocal_module (l, name, t) ->
      Mlocal_module (l, name, map_t ~mname:(Path.append name mname) ~f t)
  | Mapplied_functor (l, n, mname, t) ->
      Mapplied_functor (l, n, mname, map_t ~mname ~f t)
  | Mfunctor (l, name, ps, t, m) ->
      let ps = List.map (fun (n, intf) -> (n, map_intf ~f intf)) ps in
      (* Regeneralize on substitution with correct module *)
      (* Mapping here isn't needed. The correct values will be filled when the functor is applied *)
      (* let m = map_t ~mname:(Path.append name mname) ~f m in *)
      Mfunctor (l, name, ps, t, m)
  | Mmodule_alias _ as m -> m
  | Mmodule_type (l, name, intf) -> Mmodule_type (l, name, map_intf ~f intf)

and map_t ~mname ~f m =
  { m with s = map_intf ~f m.s; i = List.map (map_item ~mname ~f) m.i }

and map_intf ~f intf =
  List.map
    (fun (n, l, k) ->
      let k =
        match k with
        | Mvalue (t, n) -> Mvalue (f t, n)
        | Mtypedef _ as decl -> decl
      in
      (n, l, k))
    intf

let modpath_of_kind = function
  | Clocal p -> p
  | Cfile (name, _) -> Path.Pid name

let envmodule_of_cached path = function
  | Located _ -> Env.Cm_located path
  | Cached (_, scope, _) -> Cm_cached (path, scope)
  | Functor (scope, _, _, _, _) -> Cm_cached (path, scope)

let sep =
  if String.length Filename.dir_sep = 1 then String.get Filename.dir_sep 0
  else failwith "What kind of dir sep is this?"

let normalize_path path =
  let rec normalize acc = function
    | [] -> String.concat Filename.dir_sep (List.rev acc)
    | ".." :: tl -> (
        match acc with
        | [] -> failwith "TODO start with relative up"
        | _ :: acctl -> normalize acctl tl)
    | "." :: tl -> normalize acc tl
    | hd :: tl -> normalize (hd :: acc) tl
  in
  normalize [] (String.split_on_char sep path)

let make_path parent_mod_fname alias_fname =
  (* Make path from parent module filename and (relative) alias filename *)
  if Filename.is_relative alias_fname then
    Filename.(concat (dirname parent_mod_fname) alias_fname) |> normalize_path
  else alias_fname

let load_foreign loc foreign fname mname =
  match (foreign, fname) with
  | Some (mod_fname, regeneralize), Some fname ->
      let fname = make_path mod_fname fname in
      Hashtbl.add module_cache mname (Located (fname, loc, regeneralize))
  | _ -> failwith "Internal Error: Cannot read foreign module"

let rec add_to_env env foreign (mname, m) =
  allow_transitive_deps := true;
  let def_val = Env.def_mname mname in
  let cname name = function
    | Some cname -> cname
    | None -> (name, None, None)
  in
  let env =
    match m.s with
    | [] ->
        List.fold_left
          (fun env item ->
            match item with
            | Mtype (_, name, decl) -> Env.add_type name decl env
            | Mfun (l, typ, n) ->
                Env.(
                  add_value n.user { def_val with typ; global = true } l env
                  |> add_callname ~key:n.user (cname n.user n.call))
            | Mpoly_fun (l, abs, n, _) ->
                Env.(
                  add_value n { def_val with typ = type_of_func abs.func } l env)
            | Mext (l, typ, n, _) ->
                let const =
                  match repr typ with Tfun (_, _, Simple) -> true | _ -> false
                in
                Env.(
                  add_value n.user
                    { def_val with typ; global = true; const }
                    l env
                  |> add_callname ~key:n.user (cname n.user n.call))
            | Mmutual_rec (_, ds) ->
                List.fold_left
                  (fun env (l, name, _, typ) ->
                    Env.(add_value name { def_val with typ } l env))
                  env ds
            | Malias (loc, n, tree) ->
                Env.(
                  add_value n
                    { def_val with typ = tree.typ; global = true }
                    loc env)
            | Mlocal_module (loc, key, m) -> (
                let mname = Path.append key mname in
                match Hashtbl.find_opt module_cache mname with
                | None -> (
                    (* Add to cache *)
                    match register_module env loc mname m with
                    | Ok env -> env
                    | Error () -> raise (Error (loc, "Cannot add module")))
                | Some cached ->
                    Env.add_module ~key (envmodule_of_cached mname cached) env)
            | Mapplied_functor (loc, key, p, m) -> (
                match register_applied_functor env loc key p m with
                | Ok env -> env
                | Error () -> raise (Error (loc, "Cannot apply functor")))
            | Mfunctor (loc, key, ps, items, m) -> (
                let mname = Path.append key mname in
                match register_functor env loc mname ps items m with
                | Ok env -> env
                | Error () -> raise (Error (loc, "Cannot add functor")))
            | Mmodule_alias (loc, key, mname, fname) -> (
                match Hashtbl.find_opt module_cache mname with
                | None ->
                    load_foreign loc foreign fname mname;
                    Env.add_module ~key (Env.Cm_located mname) env
                | Some cached ->
                    Env.add_module ~key (envmodule_of_cached mname cached) env)
            | Mmodule_type (_, name, intf) -> Env.add_module_type name intf env)
          env m.i
    | l ->
        let env =
          List.fold_left
            (fun env (name, loc, kind) ->
              match kind with
              (* Not in the signature of the module we add it to *)
              | Mtypedef decl -> Env.add_type name decl env
              | Mvalue (typ, cn) -> (
                  Env.(add_value name { def_val with typ } loc env)
                  |> fun env ->
                  match cn with
                  | None -> env
                  | Some cn -> Env.add_callname ~key:name cn env))
            env l
        in
        List.iter
          (function
            (* Add hidden types to the env so they are readable later on *)
            | Mtype (_, name, decl) ->
                let tbl = Env.decl_tbl env and name = Path.append name mname in
                if not (Hashtbl.mem tbl name) then
                  (* Add decl to table *)
                  Hashtbl.add tbl name decl
            | Mapplied_functor (loc, key, p, m) -> (
                (* [register_applied_functor] adds the types to the decl table
                   so they are readable later on *)
                match register_applied_functor env loc key p m with
                | Ok _ -> ()
                | Error () -> raise (Error (loc, "Cannot apply functor")))
            | _ -> ())
          m.i;
        env
  in
  allow_transitive_deps := false;
  env

and make_scope env loc foreign mname m =
  let env = Env.open_module_scope env loc mname in
  let env = add_to_env env foreign (mname, m) in
  Env.pop_scope env

and import_module env loc ~regeneralize name =
  let mname = Path.Pid name in
  (* Find file first to ensure importing the file is even allowed. It could be
     in the [module_cache] as a transitive dependency and not be accessible to
     the current scope. *)
  let _raise () = raise (Error (loc, "Cannot find module: " ^ name)) in
  let filename =
    try find_file ~name ~suffix:".smi" with Not_found -> _raise ()
  in
  match Hashtbl.find_opt module_cache mname with
  | Some cached ->
      Env.add_module ~key:name (envmodule_of_cached mname cached) env
  | None -> (
      try
        let filename = Filename.remove_extension filename in
        let cached = Located (filename, loc, regeneralize) in
        Hashtbl.add module_cache mname cached;
        Env.add_module ~key:name (envmodule_of_cached mname cached) env
      with Not_found -> _raise ())

and module_name_of_path p =
  match String.split_on_char sep p with [] -> p | l -> List.rev l |> List.hd

and load_dep_modules env fname loc objects ~regeneralize =
  List.iter
    (fun (name, load) ->
      if load then
        let mname = Path.Pid (module_name_of_path name) in
        match Hashtbl.find_opt module_cache mname with
        | None | Some (Located _) ->
            (* Being located isn't enough, we need the module to be loaded *)
            let filename = make_path fname name in
            read_module env filename loc ~regeneralize mname |> ignore
        | Some (Cached _ | Functor _) -> ()
      else ())
    objects

and read_module env filename loc ~regeneralize mname =
  let c = open_in (filename ^ ".smi") in
  try
    match Sexp.input c |> Result.map t_of_sexp with
    | Ok t ->
        close_in c;
        (* Load transitive modules. The interface files are the same as object files *)
        load_dep_modules env filename loc t.objects ~regeneralize;
        add_object_names filename t.objects;
        let kind, m =
          (Cfile (filename, false), map_t ~mname ~f:regeneralize t)
        in
        (* Make module scope *)
        let scope =
          make_scope env loc (Some (filename, regeneralize)) mname m
        in
        Hashtbl.add module_cache mname (Cached (kind, scope, m));
        Ok scope
    | Error _ ->
        close_in c;
        Error ("Could not deserialize module: " ^ filename)
  with _ ->
    close_in c;
    Error ("Could not deserialize module: " ^ filename)

and add_object_names fname objects =
  let objs =
    List.fold_left
      (fun set (name, _) ->
        let o = make_path fname name ^ ".o" in
        Sset.add o set)
      Sset.empty objects
  in
  object_cache := Sset.union objs !object_cache

and register_module env loc mname modul =
  (* Modules must be unique *)
  if Hashtbl.mem module_cache mname then Error ()
  else
    let scope = make_scope env loc None mname modul in
    let cached = Cached (Clocal mname, scope, modul) in
    Hashtbl.add module_cache mname cached;
    let key = Path.get_hd mname in
    let env = Env.add_module ~key (envmodule_of_cached mname cached) env in
    Ok env

and rev { s; i; objects } =
  let i =
    List.rev_map
      (function
        | Mlocal_module (loc, s, t) -> Mlocal_module (loc, s, rev t)
        | item -> item)
      i
  in
  { s = List.rev s; i; objects }

and register_functor env loc mname params body modul : (Env.t, unit) Result.t =
  if Hashtbl.mem module_cache mname then Error ()
  else
    (* Make an empty scope *)
    let scope = Env.open_module_scope env loc mname |> Env.pop_scope in
    let cached = Functor (scope, mname, params, body, rev modul) in
    Hashtbl.add module_cache mname cached;
    let key = Path.get_hd mname in
    (* Use located here, so the scope isn't accessed in env *)
    let env = Env.add_module ~key (Cm_located mname) env in
    Ok env

and register_applied_functor env loc key mname modul =
  (* Modules must be unique *)
  if Hashtbl.mem module_cache mname then Error ()
  else
    let cached =
      let scope = make_scope env loc None mname modul in
      (* Externals need to be added again with the correct user name *)
      List.iter
        (function Mext (_, t, n, c) -> add_ext_item ~mname t n c | _ -> ())
        modul.i;
      let cached = Cached (Clocal mname, scope, modul) in
      Hashtbl.add module_cache mname cached;
      envmodule_of_cached mname cached
    in
    Ok (Env.add_module ~key cached env)

let find_module env loc name =
  (* We first search the env for local modules. Then we try read the module the normal way *)
  let r =
    match Env.find_module_opt ~query:true loc (Path.Pid name) env with
    | Some name -> (
        match Hashtbl.find_opt module_cache name with
        | Some (Cached (kind, scope, _)) ->
            Ok
              Env.(
                Cm_cached (modpath_of_kind kind, Env.fix_scope_loc scope loc))
        | Some ((Located _ | Functor _) as cached) ->
            Ok (envmodule_of_cached name cached)
        | None ->
            let msg =
              Printf.sprintf "Module %s should be local but cannot be found"
                (Path.show name)
            in
            raise (Error (loc, msg)))
    | None -> (
        (* Check if we have imported the module before *)
        let m =
          if !allow_transitive_deps then
            let mname = Path.Pid name in
            match Hashtbl.find_opt module_cache mname with
            | Some r -> Ok (envmodule_of_cached mname r)
            | None -> Error ()
          else Error ()
        in
        match m with
        | Ok m -> Ok m
        | Error () ->
            let msg = Printf.sprintf "Module %s has not been imported" name in
            raise (Error (loc, msg)))
  in

  match r with
  | Ok m -> m
  | Error s ->
      let msg = Printf.sprintf "Module %s: %s" name s in
      raise (Error (loc, msg))

let functor_msg path =
  Printf.sprintf "The module %s is a functor. It cannot be accessed directly"
    (Path.get_hd path)

let scope_of_located env path =
  match Hashtbl.find module_cache path with
  | Functor _ -> Result.Error (functor_msg path)
  | Cached (_, scope, _) -> Ok scope
  | Located (filename, loc, regeneralize) ->
      read_module env filename loc ~regeneralize path

let scope_of_functor_param env loc ~param mt =
  (* A part of add_to_env for intf is copied here *)
  let env = Env.open_module_scope env loc param in
  let env =
    List.fold_left
      (fun env (name, loc, kind) ->
        match kind with
        (* Not in the signature of the module we add it to *)
        | Mtypedef decl -> Env.add_type name decl env
        | Mvalue (typ, _) ->
            Env.(add_value name { (def_mname param) with typ } loc env))
      env (List.rev mt)
  in
  let scope = Env.pop_scope env in
  Env.Cm_cached (param, scope)

let rec of_located env path =
  match Hashtbl.find module_cache path with
  | Functor _ -> Result.Error (functor_msg path)
  | Cached (_, _, m) -> Ok m
  | Located (filename, loc, regeneralize) ->
      ignore (read_module env filename loc ~regeneralize path);
      of_located env path

type functor_data =
  Path.t * (string * Module_type.t) list * Typed_tree.toplevel_item list * t

let functor_data env loc mname =
  match Env.find_module_opt ~query:true loc mname env with
  | Some name -> (
      match Hashtbl.find_opt module_cache name with
      | Some (Functor (_, mname, params, body, modul)) ->
          Ok (mname, params, body, modul)
      | Some _ -> Error ("Module " ^ Path.show mname ^ " is not a functor")
      | None -> Error ("Module " ^ Path.show mname ^ " cannot be found"))
  | None -> Error ("Module " ^ Path.show mname ^ " cannot be found")

let object_names () =
  let ours =
    Hashtbl.fold
      (fun _ cached set ->
        match cached with
        | Cached (Cfile (name, _), _, _) ->
            Sset.add (normalize_path (name ^ ".o")) set
        | Cached (Clocal _, _, _) | Functor _ -> set
        | Located _ -> set)
      module_cache Sset.empty
  in
  Sset.union ours !object_cache |> Sset.to_seq |> List.of_seq

let uses_args () =
  object_names ()
  |> List.find_opt (String.ends_with ~suffix:"/std/std/sys.o")
  |> Option.is_some

let to_channel c ~outname m =
  let module Smap = Map.Make (String) in
  let _, m =
    rev m |> Canon.map_module (Path.Pid outname) (Map_canon.empty_sub ())
  in
  (* Correct objects only exist after [canonize_t] *)
  let objects =
    Hashtbl.fold
      (fun _ cached set ->
        match cached with
        | Cached (Cfile (name, load), _, _) ->
            if String.ends_with ~suffix:"std" name then set
            else Smap.add (normalize_path name) load set
        | _ -> set)
      module_cache Smap.empty
    |> Smap.to_seq |> List.of_seq
  in
  { m with objects } |> sexp_of_t |> Sexp.to_channel c

let with_transitive_deps f =
  if !allow_transitive_deps then f ()
  else (
    allow_transitive_deps := true;
    let ret = f () in
    allow_transitive_deps := false;
    ret)

let is_type = function Mtypedef _ -> true | _ -> false

let find_item name kind = function
  | Mtype (_, n, decl) ->
      if is_type kind && String.equal name n then Some (Mtypedef decl) else None
  | Mpoly_fun (_, abs, n, _) ->
      if (not (is_type kind)) && String.equal name n then
        let typ = type_of_func abs.func in
        Some (Mvalue (typ, None))
      else None
  | Malias (_, n, expr) ->
      if (not (is_type kind)) && String.equal name n then
        Some (Mvalue (expr.typ, None))
      else None
  | Mfun (_, typ, n) | Mext (_, typ, n, _) ->
      if (not (is_type kind)) && String.equal name n.user then
        Some (Mvalue (typ, n.call))
      else None
  | Mmutual_rec _ | Mlocal_module _ | Mfunctor _ | Mapplied_functor _
  | Mmodule_alias _ | Mmodule_type _ ->
      None

let decls_match name ~sgn impl =
  match (sgn.kind, impl.kind) with
  | Drecord (_, s), Drecord (_, i) -> (
      try
        Array.iter2
          (fun s i ->
            let _, _, b = Inference.types_match s.ftyp i.ftyp in
            if not b then raise (Invalid_argument ""))
          s i;
        Ok None
      with Invalid_argument _ ->
        let to_tup fs =
          let ts = Array.map (fun f -> f.ftyp) fs |> Array.to_list in
          Ttuple ts
        in
        Error (Some (to_tup s, to_tup i)))
  | Dvariant (_, s), Dvariant (_, i) -> (
      try
        Array.iter2
          (fun s i ->
            let b =
              match (s.ctyp, i.ctyp) with
              | Some s, Some i ->
                  let _, _, b = Inference.types_match s i in
                  b
              | None, None -> true
              | _ -> false
            in
            if not b then raise (Invalid_argument ""))
          s i;
        Ok None
      with Invalid_argument _ -> Error None)
  | Dalias s, Dalias i ->
      let _, _, b = Inference.types_match s i in
      if b then Ok None else Error (Some (s, i))
  | Dabstract (Some _), _ ->
      failwith "Internal Error: Abstract type is not abstract"
  | Dabstract None, kind -> Ok (Some (kind, typ_of_decl impl name))
  | _ -> Error None

let validate_module_type env ~mname find mtype =
  (* Go through signature and check that the implemented types match.
     Implementation is appended to a list, so the most current bindings are the ones we pick.
     That's exactly what we want. Also, set correct unique name to signature binding. *)
  let mn = mname in
  let com = "Signatures don't match" in
  let f (name, loc, kind) (sub, acc) =
    match (find name kind, kind) with
    | Some (Mtypedef idecl), Mtypedef sdecl ->
        let path = Path.append name mn in
        let sub, kind =
          match decls_match path ~sgn:sdecl idecl with
          | Ok None -> (sub, kind)
          | Ok (Some (dkind, typ)) ->
              (* If the decl was an abstract type, we have to add the
                 implementation of the abstract type to the signature. *)
              let kind =
                match sdecl.kind with
                | Dabstract None ->
                    Mtypedef { sdecl with kind = Dabstract (Some dkind) }
                | _ -> kind
              in
              (Pmap.add path typ sub, kind)
          | Error None ->
              let msg = com ^ " for type " ^ name in
              raise (Error (loc, msg))
          | Error (Some (s, i)) ->
              let msg = Error.format_type_err (com ^ ":") mn s i in
              raise (Error (loc, msg))
        in
        (sub, (name, loc, kind) :: acc)
    | Some (Mvalue (ityp, callname)), Mvalue (styp, _) ->
        let typ, _, b = Inference.types_match ~abstracts_map:sub styp ityp in
        if b then
          let acc =
            ((* Query value to mark it as used in the env *)
             ignore (Env.query_val_opt loc (Path.Pid name) env);
             (name, loc, Mvalue (typ, callname)))
            :: acc
          in
          (sub, acc)
        else
          let msg =
            Error.format_type_err
              (com ^ " for value " ^ name ^ ":")
              mn styp ityp
          in
          raise (Error (loc, msg))
    | (None | Some (Mvalue _)), Mtypedef decl -> (
        (* Typedefs don't have to be given a second time. Except: When the
           initial type is abstract *)
        match decl.kind with
        | Dabstract _ ->
            raise (Error (loc, com ^ ": Type " ^ name ^ " is missing"))
        | _ ->
            (* These types are only present in the signature. For applying
               functors, we need to check each type for aliases. A type defined
               in the impl might refer to this signature type. Thus, the
               signature types need to be manually placed into the decl map
               which keeps track of in-module type declarations. *)
            (sub, (name, loc, kind) :: acc))
    | (None | Some (Mtypedef _)), Mvalue (typ, _) ->
        let msg =
          Printf.sprintf
            "Mismatch between implementation and signature: Missing \
             implementation of %s %s"
            (string_of_type mn typ) name
        in
        raise (Error (loc, msg))
  in
  List.fold_right f mtype (Pmap.empty, []) |> snd

let validate_signature env m =
  match m.s with
  | [] -> m
  | s ->
      let find name kind = List.find_map (find_item name kind) m.i in
      let mname = Env.modpath env in
      let s = validate_module_type ~mname env find s in
      { m with s }

let validate_intf env ~mname intf m =
  match m.s with
  | [] ->
      let find name kind = List.find_map (find_item name kind) m.i in
      ignore (validate_module_type ~mname env find intf)
  | s ->
      let find name kind =
        List.find_map
          (fun (n, _, k) ->
            match k with
            | Mtypedef _ ->
                if is_type kind && String.equal name n then Some k else None
            | Mvalue _ ->
                if (not (is_type kind)) && String.equal name n then Some k
                else None)
          s
      in
      ignore (validate_module_type ~mname env find intf)

let to_module_type { s; i; _ } =
  match (s, i) with
  | [], _ -> failwith "Internal Error: Module type is empty"
  | items, [] -> items
  | _ -> failwith "Internal Error: Module type has an implementation"
