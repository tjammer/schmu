open Types
module Sexp = Csexp.Make (Sexplib0.Sexp)
open Sexplib0.Sexp_conv
module S = Set.Make (Path)
module M = Map.Make (Path)

type loc = Typed_tree.loc [@@deriving sexp]
and name = { user : string; call : string }

and item =
  | Mtype of loc * typ
  | Mfun of loc * typ * name
  | Mext of loc * typ * name * bool (* is closure *)
  | Mpoly_fun of loc * Typed_tree.abstraction * string * int option
  | Mmutual_rec of loc * (loc * string * int option * typ) list

and sg_kind = Stypedef | Svalue
and sig_item = Path.t * loc * typ * sg_kind [@@deriving sexp]

type t = { s : sig_item list; i : item list }

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
let unique_name name = function
  | None -> name
  | Some n -> name ^ "__" ^ string_of_int n

let lambda_name mn id =
  (match mn with Some mname -> "__" ^ mname | None -> "")
  ^ "__fun" ^ string_of_int id

let is_polymorphic_func (f : Typed_tree.func) =
  is_polymorphic (Tfun (f.tparams, f.ret, f.kind))

let add_type_sig loc name t m = { m with s = (name, loc, t, Stypedef) :: m.s }
let add_value_sig loc name t m = { m with s = (name, loc, t, Svalue) :: m.s }
let add_type loc t m = { m with i = Mtype (loc, t) :: m.i }

let type_of_func (func : Typed_tree.func) =
  Tfun (func.tparams, func.ret, func.kind)

let add_fun loc name uniq (abs : Typed_tree.abstraction) m =
  let call = unique_name name uniq in
  if is_polymorphic_func abs.func then
    { m with i = Mpoly_fun (loc, abs, name, uniq) :: m.i }
  else
    {
      m with
      i = Mfun (loc, type_of_func abs.func, { user = name; call }) :: m.i;
    }

let add_rec_block loc funs m =
  let m's =
    List.filter_map
      (fun (loc, name, uniq, (abs : Typed_tree.abstraction)) ->
        let typ = type_of_func abs.func in
        if is_polymorphic typ then Some (loc, name, uniq, typ) else None)
      funs
  in
  let i = Mmutual_rec (loc, m's) :: m.i in
  List.fold_left
    (fun m (loc, n, u, abs) -> add_fun loc n u abs m)
    { m with i } funs

let add_external loc t name cname ~closure m =
  let closure = match clean t with Tfun _ -> closure | _ -> false in
  let call = match cname with Some s -> s | None -> name in
  { m with i = Mext (loc, t, { user = name; call }, closure) :: m.i }

let module_cache = Hashtbl.create 64
(* TODO sort by insertion order *)

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
    | [] -> raise Not_found
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

let absolute_module_name ~mname fname = "_" ^ mname ^ "_" ^ fname

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
  | If (cond, e1, e2) ->
      let sub, cond = (canonbody mname nsub) sub cond in
      let sub, e1 = (canonbody mname nsub) sub e1 in
      let sub, e2 = (canonbody mname nsub) sub e2 in
      (sub, If (cond, e1, e2))
  | Let d ->
      let sub, lhs = (canonbody mname nsub) sub d.lhs in
      (* Remove [id] from names map. If there is a function named [id],
         we don't want to rename accesses to the here named variable. *)
      let nsub = Smap.remove d.id nsub in
      let sub, cont = (canonbody mname nsub) sub d.cont in
      (sub, Let { d with lhs; cont })
  | Bind (id, un, lhs, cont) ->
      let sub, lhs = (canonbody mname nsub) sub lhs in
      let nsub = Smap.remove id nsub in
      let sub, cont = (canonbody mname nsub) sub cont in
      (sub, Bind (id, un, lhs, cont))
  | Lambda (i, _, abs) ->
      let sub, abs = canonabs mname sub nsub abs in
      (sub, Lambda (i, Some mname, abs))
  | Function (n, u, abs, cont) ->
      let nsub = Smap.add n (absolute_module_name ~mname n) nsub in
      let sub, abs = canonabs mname sub nsub abs in
      let sub, cont = (canonbody mname nsub) sub cont in
      (sub, Function (change_name n nsub, u, abs, cont))
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
  | Field (e, i) ->
      let sub, e = (canonbody mname nsub) sub e in
      (sub, Field (e, i))
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
  let func = { Typed_tree.tparams; ret; kind } in
  let sub, body = (canonbody mname nsub) sub abs.body in
  (sub, { abs with func; body })

let map_item ~mname ~f = function
  | Mtype (l, t) -> Mtype (l, f t)
  | Mfun (l, t, n) ->
      let t = f t in
      ext_funcs :=
        Env.
          {
            ext_name = absolute_module_name ~mname n.user;
            ext_typ = t;
            ext_cname = Some (mname ^ "_" ^ n.call);
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
      poly_funcs :=
        (* Change name of poly func to module-unique name to prevent name clashes from
           different modules *)
        Typed_tree.Tl_function (l, absolute_module_name ~mname n, u, abs)
        :: !poly_funcs;
      (* This will be ignored in [add_to_env] *)
      Mpoly_fun (l, abs, n, u)
  | Mmutual_rec (l, decls) ->
      let decls = List.map (fun (l, n, u, t) -> (l, n, u, f t)) decls in
      let mname_decls =
        List.map
          (fun (_, n, u, t) ->
            let nn = absolute_module_name ~mname n in
            (nn, u, t))
          decls
      in
      poly_funcs := Typed_tree.Tl_mutual_rec_decls mname_decls :: !poly_funcs;
      Mmutual_rec (l, decls)

let map_t ~mname ~f m =
  {
    s = List.map (fun (n, l, t, k) -> (n, l, f t, k)) m.s;
    i = List.map (map_item ~mname ~f) m.i;
  }

(* Number qvars from 0 and change names of Var-nodes to their unique form.
   _<module_name>_name*)
let fold_canonize_item mname (ts_sub, nsub) = function
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

let canonize_t mname m =
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

let read_module ~regeneralize name =
  match Hashtbl.find_opt module_cache name with
  | Some r -> r
  | None -> (
      try
        let c = open_in (find_file name ".smi") in
        let r =
          Result.map t_of_sexp (Sexp.input c)
          |> Result.map (map_t ~mname:name ~f:regeneralize)
        in
        close_in c;
        Hashtbl.add module_cache name r;
        r
      with Not_found -> Error ("Could not open file: " ^ name))

let read_exn ~regeneralize name loc =
  match read_module ~regeneralize name with
  | Ok modul -> modul
  | Error s ->
      let msg = Printf.sprintf "Module %s: %s" name s in
      raise (Typed_tree.Error (loc, msg))

type modif_kind = Add of string * S.t

let modif = function
  | Add (name, sub) -> fun p -> if S.mem p sub then Path.Pmod (name, p) else p

let rec mod_t mkind t =
  let nm = modif mkind in
  match t with
  | Talias (p, t) -> Talias (nm p, mod_t mkind t)
  | Trecord (ps, n, fields) ->
      let ps = List.map (mod_t mkind) ps in
      let n = Option.map nm n in
      let fields =
        Array.map (fun f -> { f with ftyp = mod_t mkind f.ftyp }) fields
      in
      Trecord (ps, n, fields)
  | Tvariant (ps, n, ctors) ->
      let ps = List.map (mod_t mkind) ps in
      let n = nm n in
      let ctors =
        Array.map
          (fun c -> { c with ctyp = Option.map (mod_t mkind) c.ctyp })
          ctors
      in
      Tvariant (ps, n, ctors)
  | Traw_ptr t -> Traw_ptr (mod_t mkind t)
  | Tarray t -> Tarray (mod_t mkind t)
  | Tfun (ps, r, kind) ->
      let ps = List.map (fun p -> { p with pt = mod_t mkind p.pt }) ps in
      let r = mod_t mkind r in
      let kind =
        match kind with
        | Simple -> kind
        | Closure c ->
            let c =
              List.map (fun c -> { c with cltyp = mod_t mkind c.cltyp }) c
            in
            Closure c
      in
      Tfun (ps, r, kind)
  | Tvar { contents = Link t } -> Tvar { contents = Link (mod_t mkind t) }
  | Tabstract (ps, n, t) ->
      Tabstract (List.map (mod_t mkind) ps, nm n, mod_t mkind t)
  | t -> t

let extr_name = function
  | Trecord (_, n, _) -> n
  | Talias (n, _) | Tvariant (_, n, _) -> Some n
  | _ -> None

let rec mod_expr f e =
  Typed_tree.{ e with typ = f e.typ; expr = mod_body f e.expr }

and mod_body f e =
  let m = mod_expr f in
  match e with
  | Const (Array ts) -> Const (Array (List.map m ts))
  | Bop (b, l, r) -> Bop (b, m l, m r)
  | Unop (u, e) -> Unop (u, m e)
  | If (c, l, r) -> If (m c, m l, m r)
  | Let l -> Let { l with lhs = m l.lhs; cont = m l.cont }
  | Bind (n, u, e, cont) -> Bind (n, u, m e, m cont)
  | Lambda (i, mn, abs) -> Lambda (i, mn, mod_abs f abs)
  | Function (n, i, abs, cont) -> Function (n, i, mod_abs f abs, m cont)
  | App { callee; args } ->
      App
        { callee = m callee; args = List.map (fun (e, mut) -> (m e, mut)) args }
  | Record ts -> Record (List.map (fun (n, e) -> (n, m e)) ts)
  | Field (t, i) -> Field (m t, i)
  | Set (l, r) -> Set (m l, m r)
  | Sequence (l, r) -> Sequence (m l, m r)
  | Ctor (n, i, t) -> Ctor (n, i, Option.map m t)
  | Variant_index t -> Variant_index (m t)
  | Variant_data t -> Variant_data (m t)
  | Fmt fs ->
      let f = function Typed_tree.Fstr _ as f -> f | Fexpr t -> Fexpr (m t) in
      Fmt (List.map f fs)
  | e -> e

and mod_abs f abs =
  let body = mod_expr f abs.body in
  let func =
    let tparams = List.map (fun p -> { p with pt = f p.pt }) abs.func.tparams in
    let ret = f abs.func.ret in
    let kind =
      match abs.func.kind with
      | Simple -> Simple
      | Closure c ->
          let c = List.map (fun c -> { c with cltyp = f c.cltyp }) c in
          Closure c
    in
    Typed_tree.{ tparams; ret; kind }
  in
  { abs with body; func }

let add_to_env env mname m =
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
              Env.add_type name (Amodule mname) t env
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
                env ds)
        env m.i
  | l ->
      List.fold_left
        (fun env (name, loc, typ, kind) ->
          match kind with
          | Stypedef -> Env.add_type name (Amodule mname) typ env
          | Svalue ->
              (* The import kind (`C | `Schmu) is currently not used in the env implementation.
                 This is good for us, so we don't have to keep track of what's external (C linkage)
                 vs internal (Schmu linkage) here. Once the env implementation does something with this
                 info, we have to change this here. This means tracking the origin of the value more
                 precisely. *)
              let imported = Some (mname, `Schmu) in
              Env.(
                add_value (Path.get_hd name)
                  { def_value with typ; imported }
                  loc env))
        env l

let make_module sub name m =
  let s t =
    match extr_name t with Some p -> sub := S.add p !sub | None -> ()
  in
  let i =
    (* Don't try to use rev_map. It won't work *)
    List.rev m.i
    |> List.map (function
         | Mtype (l, t) ->
             s t;
             Mtype (l, mod_t (Add (name, !sub)) t)
         | Mfun (l, t, n) ->
             sub := S.add (Path.Pid n.user) !sub;
             Mfun (l, mod_t (Add (name, !sub)) t, n)
         | Mext (l, t, n, c) ->
             sub := S.add (Path.Pid n.user) !sub;
             Mext (l, mod_t (Add (name, !sub)) t, n, c)
         | Mpoly_fun (l, abs, n, u) ->
             sub := S.add (Path.Pid n) !sub;
             Mpoly_fun (l, mod_abs (mod_t (Add (name, !sub))) abs, n, u)
         | Mmutual_rec (l, ds) ->
             let ds =
               List.map
                 (fun (l, n, u, t) ->
                   sub := S.add (Path.Pid n) !sub;
                   (l, n, u, mod_t (Add (name, !sub)) t))
                 ds
             in
             Mmutual_rec (l, ds))
  in
  let s =
    List.rev m.s
    |> List.map (fun (n, l, t, k) ->
           s t;
           (n, l, mod_t (Add (name, !sub)) t, k))
  in
  { s; i }

let to_channel c ~outname m =
  let s = ref S.empty in
  m |> make_module s outname |> canonize_t outname |> sexp_of_t
  |> Sexp.to_channel c

let extract_name_type = function
  | Mtype (l, t) -> (
      match t with
      | Trecord (_, Some n, _) | Tvariant (_, n, _) | Talias (n, _) ->
          (Path.get_hd n, l, t, Stypedef)
      | t ->
          print_endline (string_of_type t);
          failwith "Internal Error: Type does not have a name")
  | Mfun (l, t, n) | Mext (l, t, n, _) -> (n.user, l, t, Svalue)
  | Mpoly_fun (l, abs, n, _) -> (n, l, type_of_func abs.func, Svalue)
  | Mmutual_rec _ -> failwith "Internal Error: How are mutual recs here?"

let find_item name kind (n, _, _, tkind) =
  match (kind, tkind) with
  | (Svalue, Svalue | Stypedef, Stypedef) when String.equal name n -> true
  | _ -> false

open Typed_tree

let validate_signature env m =
  (* Go through signature and check that the implemented types match.
     Implementation is appended to a list, so the most current bindings are the ones we pick.
     That's exactly what we want. Also, set correct unique name to signature binding. *)
  match m.s with
  | [] -> m
  | _ ->
      let impl = List.map extract_name_type m.i in
      let f (name, loc, styp, kind) =
        match
          (List.find_opt (find_item (Path.get_hd name) kind) impl, kind)
        with
        | Some (n, _, ityp, ikind), _ ->
            let subst, b =
              Inference.types_match ~match_abstract:true Smap.empty styp ityp
            in
            if b then (
              (* Query value to mark it as used in the env *)
              (match ikind with
              | Svalue -> ignore (Env.query_val_opt n env)
              | Stypedef -> ());
              (name, loc, styp, kind))
            else
              let msg =
                Printf.sprintf
                  "Mismatch between implementation and signature: Expected \
                   type %s but got type %s"
                  (string_of_type_lit styp)
                  (string_of_type_subst subst ityp)
              in
              raise (Error (loc, msg))
        | None, Stypedef -> (
            (* Typedefs don't have to be given a second time. Except: When the initial type is abstract *)
            match clean styp with
            | Tabstract _ ->
                raise
                  (Error
                     ( loc,
                       "Abstract type " ^ string_of_type styp
                       ^ " not implemented" ))
            | _ -> (name, loc, styp, kind))
        | None, Svalue ->
            let msg =
              Printf.sprintf
                "Mismatch between implementation and signature: Missing \
                 implementation of %s %s"
                (string_of_type styp) (Path.show name)
            in
            raise (Error (loc, msg))
      in
      { m with s = List.map f m.s }
