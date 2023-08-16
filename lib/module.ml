open Types
module Sexp = Csexp.Make (Sexplib0.Sexp)
open Sexplib0.Sexp_conv
module S = Set.Make (Path)
module M = Map.Make (Path)

type loc = Typed_tree.loc [@@deriving sexp]
and name = { user : string; call : string; module_var : string }

and item =
  | Mtype of loc * typ
  | Mfun of loc * typ * name
  | Mext of loc * typ * name * bool (* is closure *)
  | Mpoly_fun of loc * Typed_tree.abstraction * string * int option
  | Mmutual_rec of loc * (loc * string * int option * typ) list
  | Mmodule of loc * string * t

and sg_kind = Stypedef | Svalue
and sig_item = string * loc * typ * sg_kind [@@deriving sexp]
and t = { s : sig_item list; i : item list }

type cache_kind = Cfile of string | Clocal of Path.t

let t_of_sexp s =
  pair_of_sexp (list_of_sexp sig_item_of_sexp) (list_of_sexp item_of_sexp) s
  |> fun (s, i) -> { s; i }

let sexp_of_t m =
  sexp_of_pair
    (sexp_of_list sexp_of_sig_item)
    (sexp_of_list sexp_of_item)
    (m.s, m.i)

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)

let empty = { s = []; i = [] }

(* For named functions *)
let unique_name ~mname name uniq =
  match uniq with
  | None -> Path.mod_name mname ^ "_" ^ name
  | Some n -> Path.mod_name mname ^ "_" ^ name ^ "__" ^ string_of_int n

let lambda_name ~mname id =
  "__fun" ^ "_" ^ Path.mod_name mname ^ string_of_int id

let absolute_module_name ~mname fname = "_" ^ Path.mod_name mname ^ "_" ^ fname

let is_polymorphic_func (f : Typed_tree.func) =
  is_polymorphic (Tfun (f.tparams, f.ret, f.kind))

let add_type_sig loc name t m = { m with s = (name, loc, t, Stypedef) :: m.s }
let add_value_sig loc name t m = { m with s = (name, loc, t, Svalue) :: m.s }
let add_type loc t m = { m with i = Mtype (loc, t) :: m.i }

let add_module loc id newm ~into =
  { into with i = Mmodule (loc, id, newm) :: into.i }

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

let module_cache = Hashtbl.create 64
let clear_cache () = Hashtbl.clear module_cache

(* Right now we only ever compile one module, so this can safely be global *)
let poly_funcs = ref []
let ext_funcs = ref []
let paths = ref [ "." ]
let append_externals l = List.rev_append !ext_funcs l

(* We cache the prelude path for later *)
let prelude_path = ref None

let find_file name suffix =
  let name = String.lowercase_ascii (name ^ suffix) in
  let ( // ) = Filename.concat in
  let rec path = function
    | p :: tl ->
        let file = p // name in
        if Sys.file_exists file then file else path tl
    | [] ->
        print_endline name;
        raise Not_found
  in
  let file = path !paths in
  if String.starts_with ~prefix:"prelude" name then prelude_path := Some file;
  file

let c = ref 1

let rec canonize sub = function
  | Qvar id -> (
      match Smap.find_opt id sub with
      | Some s -> (sub, Qvar s)
      | None ->
          let ns = string_of_int !c in
          incr c;
          (Smap.add id ns sub, Qvar ns))
  | Tvar { contents = Unbound (id, _) } -> (
      match Smap.find_opt id sub with
      | Some s -> (sub, Qvar s)
      | None ->
          let ns = string_of_int !c in
          incr c;
          (Smap.add id ns sub, Qvar ns))
  | (Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32) as t -> (sub, t)
  | Tvar { contents = Link t } -> canonize sub t
  | Tfun (ps, r, k) ->
      let sub, ps =
        List.fold_left_map
          (fun sub p ->
            let sub, pt = canonize sub p.pt in
            (sub, { p with pt }))
          sub ps
      in
      let sub, r = canonize sub r in
      let sub, k =
        match k with
        | Simple -> (sub, k)
        | Closure cl ->
            let sub, cl =
              List.fold_left_map
                (fun sub c ->
                  let sub, cltyp = canonize sub c.cltyp in
                  (sub, { c with cltyp }))
                sub cl
            in
            (sub, Closure cl)
      in
      (sub, Tfun (ps, r, k))
  | Talias (n, t) ->
      let sub, t = canonize sub t in
      (sub, Talias (n, t))
  | Trecord (ts, n, fs) ->
      let sub, ts = List.fold_left_map (fun sub t -> canonize sub t) sub ts in
      let sub, fs =
        Array.fold_left_map
          (fun sub f ->
            let sub, ftyp = canonize sub f.ftyp in
            (sub, { f with ftyp }))
          sub fs
      in
      (sub, Trecord (ts, n, fs))
  | Tvariant (ts, n, cs) ->
      let sub, ts = List.fold_left_map (fun sub t -> canonize sub t) sub ts in
      let sub, cs =
        Array.fold_left_map
          (fun sub c ->
            let sub, ctyp =
              match c.ctyp with
              | Some t ->
                  let sub, t = canonize sub t in
                  (sub, Some t)
              | None -> (sub, None)
            in
            (sub, { c with ctyp }))
          sub cs
      in
      (sub, Tvariant (ts, n, cs))
  | Traw_ptr t ->
      let sub, t = canonize sub t in
      (sub, Traw_ptr t)
  | Tarray t ->
      let sub, t = canonize sub t in
      (sub, Tarray t)
  | Tabstract (ps, n, t) ->
      let sub, ps = List.fold_left_map (fun sub t -> canonize sub t) sub ps in
      let sub, t =
        match t with
        | Tvar { contents = Unbound _ } ->
            (* If it's still unbound, then there is no matching impl *)
            failwith "Internal Error: Should this not have been caught before?"
        | t ->
            let sub, t = canonize sub t in
            (sub, t)
      in
      (sub, Tabstract (ps, n, t))

let rec canonbody mname nsub sub (e : Typed_tree.typed_expr) =
  let sub, typ = canonize sub e.typ in
  let sub, expr = canonexpr mname nsub sub e.expr in
  (sub, Typed_tree.{ e with typ; expr })

and change_name id nsub =
  match Smap.find_opt id nsub with None -> id | Some name -> name

and canonexpr mname nsub sub = function
  | Typed_tree.Var id ->
      let id = change_name id nsub in
      (sub, Var id)
  | Const (Array a) ->
      let sub, a = List.fold_left_map (canonbody mname nsub) sub a in
      (sub, Const (Array a))
  | Const c -> (sub, Const c)
  | Bop (op, e1, e2) ->
      let sub, e1 = (canonbody mname nsub) sub e1 in
      let sub, e2 = (canonbody mname nsub) sub e2 in
      (sub, Bop (op, e1, e2))
  | Unop (op, e) ->
      let sub, e = (canonbody mname nsub) sub e in
      (sub, Unop (op, e))
  | If (cond, o, e1, e2) ->
      let sub, cond = (canonbody mname nsub) sub cond in
      let sub, e1 = (canonbody mname nsub) sub e1 in
      let sub, e2 = (canonbody mname nsub) sub e2 in
      (sub, If (cond, o, e1, e2))
  | Let d ->
      let sub, rhs = (canonbody mname nsub) sub d.rhs in
      (* Change binding name as well *)
      let nsub = Smap.add d.id (absolute_module_name ~mname d.id) nsub in
      let sub, cont = (canonbody mname nsub) sub d.cont in
      (sub, Let { d with rhs; cont })
  | Bind (id, lhs, cont) ->
      let sub, lhs = (canonbody mname nsub) sub lhs in
      let nsub = Smap.remove id nsub in
      let sub, cont = (canonbody mname nsub) sub cont in
      (sub, Bind (id, lhs, cont))
  | Lambda (i, abs) ->
      let sub, abs = canonabs mname sub nsub abs in
      (sub, Lambda (i, abs))
  | Function (n, u, abs, cont) ->
      let nsub = Smap.add n (absolute_module_name ~mname n) nsub in
      let sub, abs = canonabs mname sub nsub abs in
      let sub, cont = (canonbody mname nsub) sub cont in
      (sub, Function (n, u, abs, cont))
  | Mutual_rec_decls (fs, cont) ->
      let sub, fs =
        List.fold_left_map
          (fun sub (n, u, t) ->
            let sub, t = canonize sub t in
            (sub, (n, u, t)))
          sub fs
      in
      let sub, cont = (canonbody mname nsub) sub cont in
      (sub, Mutual_rec_decls (fs, cont))
  | App { callee; args } ->
      let sub, callee = (canonbody mname nsub) sub callee in
      let sub, args =
        List.fold_left_map
          (fun sub (e, mut) ->
            let sub, e = (canonbody mname nsub) sub e in
            (sub, (e, mut)))
          sub args
      in
      (sub, App { callee; args })
  | Record fs ->
      let sub, fs =
        List.fold_left_map
          (fun sub (n, e) ->
            let sub, e = (canonbody mname nsub) sub e in
            (sub, (n, e)))
          sub fs
      in
      (sub, Record fs)
  | Field (e, i, n) ->
      let sub, e = (canonbody mname nsub) sub e in
      (sub, Field (e, i, n))
  | Set (a, b) ->
      let sub, a = (canonbody mname nsub) sub a in
      let sub, b = (canonbody mname nsub) sub b in
      (sub, Set (a, b))
  | Sequence (a, b) ->
      let sub, a = (canonbody mname nsub) sub a in
      let sub, b = (canonbody mname nsub) sub b in
      (sub, Sequence (a, b))
  | Ctor (n, i, e) ->
      let sub, e =
        match e with
        | Some e ->
            let sub, e = (canonbody mname nsub) sub e in
            (sub, Some e)
        | None -> (sub, None)
      in
      (sub, Ctor (n, i, e))
  | Variant_index e ->
      let sub, e = (canonbody mname nsub) sub e in
      (sub, Variant_index e)
  | Variant_data e ->
      let sub, e = (canonbody mname nsub) sub e in
      (sub, Variant_data e)
  | Fmt fs ->
      let sub, fs =
        List.fold_left_map
          Typed_tree.(
            fun sub e ->
              match e with
              | Fstr s -> (sub, Fstr s)
              | Fexpr e ->
                  let sub, e = (canonbody mname nsub) sub e in
                  (sub, Fexpr e))
          sub fs
      in
      (sub, Fmt fs)
  | Move e ->
      let sub, e = (canonbody mname nsub) sub e in
      (sub, Move e)

and canonabs mname sub nsub abs =
  let sub, tparams =
    List.fold_left_map
      (fun sub p ->
        let sub, pt = canonize sub p.pt in
        (sub, { p with pt }))
      sub abs.func.tparams
  in
  let sub, ret = canonize sub abs.func.ret in
  let sub, kind =
    match abs.func.kind with
    | Simple -> (sub, Simple)
    | Closure l ->
        let sub, l =
          List.fold_left_map
            (fun sub c ->
              let sub, cltyp = canonize sub c.cltyp in
              let clname = change_name c.clname nsub in
              (sub, { c with cltyp; clname }))
            sub l
        in
        (sub, Closure l)
  in
  let sub, touched =
    List.fold_left_map
      (fun sub t ->
        let sub, ttyp = canonize sub Typed_tree.(t.ttyp) in
        (sub, { t with ttyp }))
      sub abs.func.touched
  in
  let func = { Typed_tree.tparams; ret; kind; touched } in
  let sub, body = (canonbody mname nsub) sub abs.body in
  (sub, { abs with func; body })

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
  | Mmodule (l, name, t) ->
      Mmodule (l, name, map_t ~mname:(Path.append name mname) ~f t)

and map_t ~mname ~f m =
  {
    s = List.map (fun (n, l, t, k) -> (n, l, f t, k)) m.s;
    i = List.map (map_item ~mname ~f) m.i;
  }

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
      (* We ought to f here. Not only the type, but
         the body as well? *)
      (* Change Var-nodes in body here *)
      let s = Smap.add n (absolute_module_name ~mname n) nsub in
      let a, abs = canonabs mname ts_sub s abs in
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
  | Mmodule (loc, n, t) ->
      let t = canonize_t (Path.append n mname) t in
      ((ts_sub, nsub), Mmodule (loc, n, t))

and canonize_t mname m =
  let (ts_sub, _), i =
    List.fold_left_map (fold_canonize_item mname)
      (Types.Smap.empty, Smap.empty)
      m.i
  in
  let _, s =
    List.fold_left_map
      (fun sub (key, l, t, k) ->
        let sub, t = canonize sub t in
        (sub, (key, l, t, k)))
      ts_sub m.s
  in
  { s; i }

let modpath_of_kind = function Clocal p -> p | Cfile name -> Path.Pid name

let rec add_to_env env (mname, m) =
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
              let imported = Some (mname, `Schmu) in
              Env.(add_value n.user { def_value with typ; imported } l env)
          | Mpoly_fun (l, abs, n, _) ->
              let imported = Some (mname, `Schmu) in
              Env.(
                add_value n
                  { def_value with typ = type_of_func abs.func; imported }
                  l env)
          | Mext (l, typ, n, _) ->
              let imported = Some (mname, `C) in
              Env.(add_value n.user { def_value with typ; imported } l env)
          | Mmutual_rec (_, ds) ->
              List.fold_left
                (fun env (l, name, _, typ) ->
                  Env.(
                    add_value name
                      { def_value with typ; imported = Some (mname, `Schmu) }
                      l env))
                env ds
          | Mmodule (loc, key, m) -> (
              let mname = Path.append key mname in
              match Hashtbl.find_opt module_cache mname with
              | None -> (
                  (* Add to cache *)
                  match register_module env loc mname (Clocal mname, m) with
                  | Ok env -> env
                  | Error () ->
                      raise (Typed_tree.Error (loc, "Cannot add module")))
              | Some (_, scope, _) -> Env.add_module ~key ~mname scope env))
        env m.i
  | l ->
      List.fold_left
        (fun env (name, loc, typ, kind) ->
          match kind with
          (* Not in the signature of the module we add it to *)
          | Stypedef -> Env.add_type name ~in_sig:false typ env
          | Svalue ->
              (* The import kind (`C | `Schmu) is currently not used in the env implementation.
                 This is good for us, so we don't have to keep track of what's external (C linkage)
                 vs internal (Schmu linkage) here. Once the env implementation does something with this
                 info, we have to change this here. This means tracking the origin of the value more
                 precisely. *)
              let imported = Some (mname, `Schmu) in
              Env.(add_value name { def_value with typ; imported } loc env))
        env l

and make_scope env loc mname m =
  let env = Env.open_module_scope env loc (Path.get_hd mname) in
  let env = add_to_env env (mname, m) in
  Env.pop_scope env

and read_module env loc ~regeneralize name =
  let mname = Path.Pid name in
  match Hashtbl.find_opt module_cache mname with
  | Some r -> Ok r
  | None -> (
      (* TODO figure out nested local opens *)
      try
        let c = open_in (find_file name ".smi") in
        let m =
          match Sexp.input c |> Result.map t_of_sexp with
          | Ok t ->
              close_in c;
              let mname = Path.Pid name in
              let kind, m = (Cfile name, map_t ~mname ~f:regeneralize t) in
              (* Make module scope *)
              let scope = make_scope env loc mname m in
              Hashtbl.add module_cache mname (kind, scope, m);
              Ok (kind, scope, m)
          | Error _ ->
              close_in c;
              Error ("Could not deserialize file: " ^ name)
        in
        m
      with Not_found -> Error ("Could not open file: " ^ name))

and register_module env loc mname (kind, modul) =
  (* Modules must be unique *)
  if Hashtbl.mem module_cache mname then Error ()
  else
    let scope = make_scope env loc mname modul in
    Hashtbl.add module_cache mname (kind, scope, modul);
    let key = Path.get_hd mname in
    let env = Env.add_module ~key ~mname scope env in
    Ok env

let find_module env loc ~regeneralize name =
  (* We first search the env for local modules. Then we try read the module the normal way *)
  let r =
    match Env.find_module_opt name env with
    | Some name -> (
        match Hashtbl.find_opt module_cache name with
        | Some (kind, scope, m) -> Ok (kind, Env.fix_scope_loc scope loc, m)
        | None ->
            let msg =
              Printf.sprintf "Module %s should be local but cannot be found"
                (Path.show name)
            in
            raise (Typed_tree.Error (loc, msg)))
    | None -> read_module env loc ~regeneralize name
  in
  match r with
  | Ok (kind, scope, m) -> (modpath_of_kind kind, scope, m)
  | Error s ->
      let msg = Printf.sprintf "Module %s: %s" name s in
      raise (Typed_tree.Error (loc, msg))

let rev { s; i } = { s = List.rev s; i = List.rev i }

let to_channel c ~outname m =
  rev m |> canonize_t (Path.Pid outname) |> sexp_of_t |> Sexp.to_channel c

let extract_name_type env = function
  | Mtype (l, t) -> (
      match t with
      | Trecord (_, Some n, _) | Tvariant (_, n, _) | Talias (n, _) ->
          Some (Path.get_hd n, l, t, Stypedef)
      | t ->
          print_endline (string_of_type t (Env.modpath env));
          failwith "Internal Error: Type does not have a name")
  | Mfun (l, t, n) | Mext (l, t, n, _) -> Some (n.user, l, t, Svalue)
  | Mpoly_fun (l, abs, n, _) -> Some (n, l, type_of_func abs.func, Svalue)
  | Mmutual_rec _ -> None
  | Mmodule (l, n, _) ->
      (* Do we have to deal with this? *)
      Some (n, l, Tunit, Svalue)

let find_item name kind (n, _, _, tkind) =
  match (kind, tkind) with
  | (Svalue, Svalue | Stypedef, Stypedef) when String.equal name n -> true
  | _ -> false

open Typed_tree

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
            let subst, b =
              Inference.types_match ~match_abstract:true Smap.empty styp ityp
            in
            if b then (
              (* Query value to mark it as used in the env *)
              (match ikind with
              | Svalue -> ignore (Env.query_val_opt loc (Path.Pid n) env)
              | Stypedef -> ());
              (* Use implementation type to retain closures *)
              (name, loc, ityp, kind))
            else
              let msg =
                Printf.sprintf
                  "Mismatch between implementation and signature: Expected \
                   type %s but got type %s"
                  (string_of_type_lit styp mn)
                  (string_of_type_subst subst ityp mn)
              in
              raise (Error (loc, msg))
        | None, Stypedef -> (
            (* Typedefs don't have to be given a second time. Except: When the initial type is abstract *)
            match clean styp with
            | Tabstract _ ->
                raise
                  (Error
                     ( loc,
                       "Abstract type " ^ string_of_type styp mn
                       ^ " not implemented" ))
            | _ -> (name, loc, styp, kind))
        | None, Svalue ->
            let msg =
              Printf.sprintf
                "Mismatch between implementation and signature: Missing \
                 implementation of %s %s"
                (string_of_type styp mn) name
            in
            raise (Error (loc, msg))
      in
      { m with s = List.map f m.s }
