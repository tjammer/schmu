open Types
open Error
module Sexp = Csexp.Make (Sexplib0.Sexp)
open Sexplib0.Sexp_conv
module S = Set.Make (Path)
module M = Map.Make (Path)
module Sset = Set.Make (String)

type loc = Typed_tree.loc [@@deriving sexp]
and name = { user : string; call : string; module_var : string }

and item =
  | Mtype of loc * typ
  | Mfun of loc * typ * name
  | Mext of loc * typ * name * bool (* is closure *)
  | Mpoly_fun of loc * Typed_tree.abstraction * string * int option
  | Mmutual_rec of loc * (loc * string * int option * typ) list
  | Mlocal_module of loc * string * t
  | Mfunctor of
      loc * string * (string * intf) list * Typed_tree.toplevel_item list
  | Mmodule_alias of loc * string * Path.t * string option (* filename option *)
  | Mmodule_type of loc * string * intf

and sg_kind = Module_type.item_kind = Mtypedef | Mvalue
and sig_item = string * loc * typ * sg_kind [@@deriving sexp]
and intf = sig_item list
and impl = item list

and t = {
  s : intf;
  i : impl;
  objects : (string * bool (* transitive dep needs load *)) list;
}

type cache_kind = Cfile of string * bool | Clocal of Path.t

let t_of_sexp s =
  triple_of_sexp
    (list_of_sexp sig_item_of_sexp)
    (list_of_sexp item_of_sexp)
    (list_of_sexp (pair_of_sexp string_of_sexp bool_of_sexp))
    s
  |> fun (s, i, objects) -> { s; i; objects }

let sexp_of_t m =
  sexp_of_triple
    (sexp_of_list sexp_of_sig_item)
    (sexp_of_list sexp_of_item)
    (sexp_of_list (sexp_of_pair sexp_of_string sexp_of_bool))
    (m.s, m.i, m.objects)

type cached =
  | Located of string * Ast.loc * (typ -> typ)
  | Cached of cache_kind * Env.scope * t
  | Functor of
      Env.scope * Path.t * (string * intf) list * Typed_tree.toplevel_item list

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
let unique_name ~mname name uniq =
  match uniq with
  | None -> Path.mod_name mname ^ "_" ^ name
  | Some n -> Path.mod_name mname ^ "_" ^ name ^ "__" ^ string_of_int n

let lambda_name ~mname id =
  "__fun" ^ "_" ^ Path.mod_name mname ^ string_of_int id

let absolute_module_name ~mname fname = "_" ^ Path.mod_name mname ^ "_" ^ fname

let functor_param_name ~mname name =
  Path.append_path (Pmod ("fparam", Pid name)) mname

let is_polymorphic_func (f : Typed_tree.func) =
  is_polymorphic (Tfun (f.tparams, f.ret, f.kind))

let add_type_sig loc name t m = { m with s = (name, loc, t, Mtypedef) :: m.s }
let add_value_sig loc name t m = { m with s = (name, loc, t, Mvalue) :: m.s }
let add_type loc t m = { m with i = Mtype (loc, t) :: m.i }

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

let add_functor loc id params body ~into =
  { into with i = Mfunctor (loc, id, params, body) :: into.i }

let type_of_func (func : Typed_tree.func) =
  Tfun (func.tparams, func.ret, func.kind)

let add_fun loc ~mname name uniq (abs : Typed_tree.abstraction) m =
  if is_polymorphic_func abs.func then
    { m with i = Mpoly_fun (loc, abs, name, uniq) :: m.i }
  else
    let call = unique_name ~mname name uniq in
    let module_var = absolute_module_name ~mname name in
    let name = { user = name; call; module_var } in
    { m with i = Mfun (loc, type_of_func abs.func, name) :: m.i }

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

let add_external loc t name ~mname cname ~closure m =
  let closure = match clean t with Tfun _ -> closure | _ -> false in
  let call = match cname with Some s -> s | None -> name in
  let module_var = absolute_module_name ~mname name in
  let name = { user = name; call; module_var } in
  { m with i = Mext (loc, t, name, closure) :: m.i }

(* Right now we only ever compile one module, so this can safely be global *)
let poly_funcs = ref []
let ext_funcs = ref []
let paths = ref [ "." ]
let append_externals l = List.rev_append !ext_funcs l

let find_file ~name ~suffix =
  let fname = String.lowercase_ascii (name ^ suffix) in
  let ( // ) = Filename.concat in
  let rec path = function
    | p :: tl ->
        let file = p // fname in
        let dir = p // name in
        if Sys.file_exists file then file
        else if
          Sys.file_exists dir && Sys.is_directory dir
          && Sys.file_exists (dir // fname)
        then dir // fname
        else path tl
    | [] ->
        print_endline fname;
        raise Not_found
  in
  let file = path !paths in
  file

module Map_canon : Map_ttree.Map_tree = struct
  type sub = string Smap.t

  let empty_sub = Smap.empty

  let change_name id nsub =
    match Smap.find_opt id nsub with None -> id | Some name -> name

  let change_var ~mname id m nsub _ =
    let id = change_name id nsub in
    (match m with
    | Some m when not (Path.share_base mname m) -> (
        (* Make sure this is eagerly loaded on use *)
        match Hashtbl.find_opt module_cache m with
        | None | Some (Located _ | Cached (Clocal _, _, _) | Functor _) ->
            failwith "unreachable what is this module's path?"
        | Some (Cached (Cfile (_, true), _, _)) -> ()
        | Some (Cached (Cfile (name, false), scope, md)) ->
            Hashtbl.replace module_cache m
              (Cached (Cfile (name, true), scope, md)))
    | None | Some _ -> ());
    id

  let absolute_module_name = absolute_module_name
  let change_type = Map_ttree.Canonize.canonize
end

module Canon = Map_ttree.Make (Map_canon)

let rec map_item ~mname ~f = function
  | Mtype (l, t) -> Mtype (l, f t)
  | Mfun (l, t, n) ->
      let t = f t in
      ext_funcs :=
        Env.
          {
            ext_name = absolute_module_name ~mname n.user;
            ext_typ = t;
            ext_cname = Some n.call;
            used = ref false;
            closure = false;
            imported = Some (mname, `Schmu);
          }
        :: !ext_funcs;
      Mfun (l, t, n)
  | Mext (l, t, n, c) ->
      let t = f t in
      ext_funcs :=
        Env.
          {
            ext_name = absolute_module_name ~mname n.user;
            ext_typ = t;
            ext_cname = Some n.call;
            used = ref false;
            closure = c;
            imported = Some (mname, `C);
          }
        :: !ext_funcs;
      Mext (l, f t, n, c)
  | Mpoly_fun (l, abs, n, u) ->
      (* We ought to f here. Not only the type, but
         the body as well? *)
      (* Change name of poly func to module-unique name to prevent name clashes from
         different modules *)
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
  | Mlocal_module (l, name, t) ->
      Mlocal_module (l, name, map_t ~mname:(Path.append name mname) ~f t)
  | Mfunctor (l, name, ps, t) ->
      let ps = List.map (fun (n, intf) -> (n, map_intf ~f intf)) ps in
      (* let mname = Path.append name mname in *)
      (* Regeneralize on substitution with correct module *)
      Mfunctor (l, name, ps, t)
  | Mmodule_alias _ as m -> m
  | Mmodule_type (l, name, intf) -> Mmodule_type (l, name, map_intf ~f intf)

and map_t ~mname ~f m =
  { m with s = map_intf ~f m.s; i = List.map (map_item ~mname ~f) m.i }

and map_intf ~f intf = List.map (fun (n, l, t, k) -> (n, l, f t, k)) intf

let canonize = Canon.canonize

(* Number qvars from 0 and change names of Var-nodes to their unique form.
   _<module_name>_name*)
let rec fold_canonize_item mname (ts_sub, nsub) = function
  | Mtype (l, t) ->
      let a, t = canonize ts_sub t in
      ((a, nsub), Mtype (l, t))
  | Mfun (l, t, n) ->
      let a, t = canonize ts_sub t in
      let s = Smap.add n.user (absolute_module_name ~mname n.user) nsub in
      ((a, s), Mfun (l, t, n))
  | Mext (l, t, n, c) ->
      let a, t = canonize ts_sub t in
      let s = Smap.add n.user (absolute_module_name ~mname n.user) nsub in
      ((a, s), Mext (l, t, n, c))
  | Mpoly_fun (l, abs, n, u) ->
      (* Change Var-nodes in body here *)
      let s = Smap.add n (absolute_module_name ~mname n) nsub in
      let a, abs = Canon.canonabs mname ts_sub s abs in
      (* This will be ignored in [add_to_env] *)
      ((a, s), Mpoly_fun (l, abs, n, u))
  | Mmutual_rec (l, decls) ->
      let (a, nsub), decls =
        List.fold_left_map
          (fun (ts_sub, nsub) (l, n, u, t) ->
            let a, t = canonize ts_sub t in
            let s = Smap.add n (absolute_module_name ~mname n) nsub in
            ((a, s), (l, n, u, t)))
          (ts_sub, nsub) decls
      in
      ((a, nsub), Mmutual_rec (l, decls))
  | Mlocal_module (loc, n, t) ->
      let t = canonize_t (Path.append n mname) t in
      ((ts_sub, nsub), Mlocal_module (loc, n, t))
  | Mfunctor (loc, n, ps, t) ->
      let f (n, intf) = (n, canonize_intf Map_canon.empty_sub intf) in
      let ps = List.map f ps in
      let ts_sub, t =
        Canon.canon_tl_items (Path.append n mname) nsub ts_sub t
      in
      ((ts_sub, nsub), Mfunctor (loc, n, ps, t))
  | Mmodule_alias _ as m -> ((ts_sub, nsub), m)
  | Mmodule_type (loc, n, intf) ->
      let intf = canonize_intf Map_canon.empty_sub intf in
      ((ts_sub, nsub), Mmodule_type (loc, n, intf))

and canonize_t mname m =
  let (ts_sub, _), i =
    List.fold_left_map (fold_canonize_item mname)
      (Map_canon.empty_sub, Smap.empty)
      m.i
  in
  let s = canonize_intf ts_sub m.s in
  { m with s; i }

and canonize_intf ts_sub intf =
  List.fold_left_map
    (fun sub (key, l, t, k) ->
      let sub, t = canonize sub t in
      (sub, (key, l, t, k)))
    ts_sub intf
  |> snd

let modpath_of_kind = function
  | Clocal p -> p
  | Cfile (name, _) -> Path.Pid name

let envmodule_of_cached path = function
  | Located _ -> Env.Cm_located path
  | Cached (_, scope, _) -> Cm_cached (path, scope)
  | Functor (scope, _, _, _) -> Cm_cached (path, scope)

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
  match m.s with
  | [] ->
      List.fold_left
        (fun env item ->
          match item with
          | Mtype
              ( _,
                (( Trecord (_, Some name, _)
                 | Tvariant (_, name, _)
                 | Talias (name, _) ) as t) ) ->
              Env.add_type (Path.get_hd name) ~in_sig:false t env
          | Mtype (_, t) ->
              failwith
                ("Internal Error: Unexpected type in module: " ^ show_typ t)
          | Mfun (l, typ, n) ->
              Env.(add_value n.user { def_value with typ } l env)
          | Mpoly_fun (l, abs, n, _) ->
              Env.(
                add_value n { def_value with typ = type_of_func abs.func } l env)
          | Mext (l, typ, n, _) ->
              Env.(add_value n.user { def_value with typ } l env)
          | Mmutual_rec (_, ds) ->
              List.fold_left
                (fun env (l, name, _, typ) ->
                  Env.(add_value name { def_value with typ } l env))
                env ds
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
          | Mfunctor (loc, key, ps, m) ->
              ignore loc;
              ignore key;
              ignore ps;
              ignore m;
              failwith "TODO add functor to env"
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
      List.fold_left
        (fun env (name, loc, typ, kind) ->
          match kind with
          (* Not in the signature of the module we add it to *)
          | Mtypedef -> Env.add_type name ~in_sig:false typ env
          | Mvalue -> Env.(add_value name { def_value with typ } loc env))
        env l

and make_scope env loc foreign mname m =
  let env = Env.open_module_scope env loc mname in
  let env = add_to_env env foreign (mname, m) in
  Env.pop_scope env

and locate_module loc ~regeneralize name =
  let mname = Path.Pid name in
  match Hashtbl.find_opt module_cache mname with
  | Some r -> Ok (envmodule_of_cached mname r)
  | None -> (
      try
        let filename = find_file ~name ~suffix:".smi" in
        let filename = Filename.remove_extension filename in
        Hashtbl.add module_cache mname (Located (filename, loc, regeneralize));
        Ok (Env.Cm_located mname)
      with Not_found -> Error ("Could not open file: " ^ name))

and module_name_of_path p =
  match String.split_on_char sep p with [] -> p | l -> List.rev l |> List.hd

and load_dep_modules env fname loc objects ~regeneralize =
  List.iter
    (fun (name, load) ->
      if load then
        let mname = Path.Pid (module_name_of_path name) in
        if Hashtbl.mem module_cache mname then ()
        else
          let filename = make_path fname name in
          read_module env filename loc ~regeneralize mname |> ignore
      else ())
    objects

and read_module env filename loc ~regeneralize mname =
  let c = open_in (filename ^ ".smi") in
  match Sexp.input c |> Result.map t_of_sexp with
  | Ok t ->
      close_in c;
      (* Load transitive modules. The interface files are the same as object files *)
      load_dep_modules env filename loc t.objects ~regeneralize;
      add_object_names filename t.objects;
      let kind, m = (Cfile (filename, false), map_t ~mname ~f:regeneralize t) in
      (* Make module scope *)
      let scope = make_scope env loc (Some (filename, regeneralize)) mname m in
      Hashtbl.add module_cache mname (Cached (kind, scope, m));
      Ok scope
  | Error _ ->
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

and register_functor env loc mname params body : (Env.t, unit) Result.t =
  if Hashtbl.mem module_cache mname then Error ()
  else
    (* Make an empty scope *)
    let scope = Env.open_module_scope env loc mname |> Env.pop_scope in
    let cached = Functor (scope, mname, params, body) in
    Hashtbl.add module_cache mname cached;
    let key = Path.get_hd mname in
    (* Use located here, so the scope isn't accessed in env *)
    let env = Env.add_module ~key (Cm_located mname) env in
    Ok env

let find_module env loc ~regeneralize name =
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
    | None -> locate_module loc ~regeneralize name
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

let scope_of_functor_param env loc (path, mt) =
  (* A part of add_to_env for intf is copied here *)
  let env = Env.open_module_scope env loc path in
  let env =
    List.fold_left
      (fun env (name, loc, typ, kind) ->
        match kind with
        (* Not in the signature of the module we add it to *)
        | Mtypedef -> Env.add_type name ~in_sig:false typ env
        | Mvalue -> Env.(add_value name { def_value with typ } loc env))
      env mt
  in
  let scope = Env.pop_scope env in
  Env.Cm_cached (path, scope)

let rec of_located env path =
  match Hashtbl.find module_cache path with
  | Functor _ -> Result.Error (functor_msg path)
  | Cached (_, _, m) -> Ok m
  | Located (filename, loc, regeneralize) ->
      ignore (read_module env filename loc ~regeneralize path);
      of_located env path

let functor_data env loc mname =
  match Env.find_module_opt ~query:true loc mname env with
  | Some name -> (
      match Hashtbl.find_opt module_cache name with
      | Some (Functor (_, mname, params, body)) -> Ok (mname, params, body)
      | Some _ -> Error ("Module " ^ Path.show mname ^ " is not a functor")
      | None -> Error ("Module " ^ Path.show mname ^ " cannot be found"))
  | None -> Error ("Module " ^ Path.show mname ^ " cannot be found")

let object_names () =
  let ours =
    Hashtbl.fold
      (fun _ cached set ->
        match cached with
        | Cached (Cfile (name, _), _, _) -> Sset.add (name ^ ".o") set
        | Cached (Clocal _, _, _) | Functor _ -> set
        | Located _ -> set)
      module_cache Sset.empty
  in
  Sset.union ours !object_cache |> Sset.to_seq |> List.of_seq

let rec rev { s; i; objects } =
  let i =
    List.rev_map
      (function
        | Mlocal_module (loc, s, t) -> Mlocal_module (loc, s, rev t)
        | item -> item)
      i
  in
  { s = List.rev s; i; objects }

let to_channel c ~outname m =
  let module Smap = Map.Make (String) in
  let m = rev m |> canonize_t (Path.Pid outname) in
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

let extract_name_type env = function
  | Mtype (l, t) -> (
      match t with
      | Trecord (_, Some n, _) | Tvariant (_, n, _) | Talias (n, _) ->
          Some (Path.get_hd n, l, t, Mtypedef)
      | t ->
          print_endline (string_of_type t (Env.modpath env));
          failwith "Internal Error: Type does not have a name")
  | Mfun (l, t, n) | Mext (l, t, n, _) -> Some (n.user, l, t, Mvalue)
  | Mpoly_fun (l, abs, n, _) -> Some (n, l, type_of_func abs.func, Mvalue)
  | Mmutual_rec _ -> None
  | Mlocal_module (l, n, _) ->
      (* Do we have to deal with this? *)
      Some (n, l, Tunit, Mvalue)
  | Mmodule_alias _ | Mmodule_type _ | Mfunctor _ -> None

let find_item name kind (n, _, _, tkind) =
  match (kind, tkind) with
  | (Mvalue, Mvalue | Mtypedef, Mtypedef) when String.equal name n -> true
  | _ -> false

let validate_intf env loc (name, _, styp, kind) rhs =
  let mn = Env.modpath env in
  match (List.find_opt (find_item name kind) rhs, kind) with
  | Some (_, _, ityp, _), _ ->
      (match styp with
      | Tabstract (ps, _, Tvar ({ contents = Unbound _ } as t)) ->
          (* Match abstract type *)
          let typ = Inference.match_type_params loc ps ityp in
          t := Link typ
      | _ -> ());
      let subst, b = Inference.types_match styp ityp in
      if b then ()
      else
        let msg =
          Printf.sprintf
            "Signatures don't match for %s: Expected type %s but got type %s"
            name
            (string_of_type_lit styp mn)
            (string_of_type_subst subst ityp mn)
        in
        raise (Error (loc, msg))
  | None, kind ->
      let msg =
        Printf.sprintf "Signatures don't match: %s %s is missing"
          (match kind with Mtypedef -> "Type" | Mvalue -> "Value " ^ name)
          (string_of_type styp mn)
      in
      raise (Error (loc, msg))

let validate_signature env m =
  (* Go through signature and check that the implemented types match.
     Implementation is appended to a list, so the most current bindings are the ones we pick.
     That's exactly what we want. Also, set correct unique name to signature binding. *)
  let mn = Env.modpath env in
  match m.s with
  | [] -> m
  | _ ->
      let impl = List.filter_map (extract_name_type env) m.i in
      let f (name, loc, styp, kind) =
        match (List.find_opt (find_item name kind) impl, kind) with
        | Some (n, loc, ityp, ikind), _ ->
            let subst, b = Inference.types_match styp ityp in
            if b then (
              (* Query value to mark it as used in the env *)
              (match ikind with
              | Mvalue -> ignore (Env.query_val_opt loc (Path.Pid n) env)
              | Mtypedef -> ());
              (* Use implementation type to retain closures, but only if the type
                 is not abstract. Otherwise, the abstract type goes away. *)
              let typ =
                match clean styp with Tabstract _ -> styp | _ -> ityp
              in
              (name, loc, typ, kind))
            else
              let msg =
                Printf.sprintf
                  "Mismatch between implementation and signature: Expected \
                   type %s but got type %s"
                  (string_of_type_lit styp mn)
                  (string_of_type_subst subst ityp mn)
              in
              raise (Error (loc, msg))
        | None, Mtypedef -> (
            (* Typedefs don't have to be given a second time. Except: When the initial type is abstract *)
            match clean styp with
            | Tabstract _ ->
                raise
                  (Error
                     ( loc,
                       "Abstract type " ^ string_of_type styp mn
                       ^ " not implemented" ))
            | _ -> (name, loc, styp, kind))
        | None, Mvalue ->
            let msg =
              Printf.sprintf
                "Mismatch between implementation and signature: Missing \
                 implementation of %s %s"
                (string_of_type styp mn) name
            in
            raise (Error (loc, msg))
      in
      let s = List.rev_map f (List.rev m.s) in
      { m with s }

let validate_intf env loc intf m =
  match m.s with
  | [] ->
      let impl = List.filter_map (extract_name_type env) m.i in
      List.iter (fun item -> validate_intf env loc item impl) (List.rev intf)
  | s -> List.iter (fun item -> validate_intf env loc item s) (List.rev intf)

let to_module_type { s; i; _ } =
  match (s, i) with
  | [], _ -> failwith "Internal Error: Module type is empty"
  | items, [] -> items
  | _ -> failwith "Internal Error: Module type has an implementation"
