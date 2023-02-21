open Types
module Sexp = Csexp.Make (Sexplib0.Sexp)
open Sexplib0.Sexp_conv
module S = Set.Make (Path)

type loc = Typed_tree.loc [@@deriving sexp]

type t = item list [@@deriving sexp]
and name = { user : string; call : string }

and item =
  | Mtype of Typed_tree.loc * typ
  | Mfun of Typed_tree.loc * typ * name
  | Mext of Typed_tree.loc * typ * name * bool (* is closure *)
  | Mpoly_fun of Typed_tree.loc * Typed_tree.abstraction * string * int option
  | Mmutual_rec of loc * (loc * string * int option * typ) list
(* TODO pattern binds *)

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)

(* For named functions *)
let unique_name name = function
  | None -> name
  | Some n -> name ^ "__" ^ string_of_int n

let lambda_name mn id =
  (match mn with Some mname -> "__" ^ mname | None -> "")
  ^ "__fun" ^ string_of_int id

let is_polymorphic_func (f : Typed_tree.func) =
  is_polymorphic (Tfun (f.tparams, f.ret, f.kind))

let add_type loc t m = Mtype (loc, t) :: m

let type_of_func (func : Typed_tree.func) =
  Tfun (func.tparams, func.ret, func.kind)

let add_fun loc name uniq (abs : Typed_tree.abstraction) m =
  let call = unique_name name uniq in
  if is_polymorphic_func abs.func then
    (* failwith "polymorphic functions in modules are not supported yet TODO" *)
    Mpoly_fun (loc, abs, name, uniq) :: m
  else Mfun (loc, type_of_func abs.func, { user = name; call }) :: m

let add_rec_block loc funs m =
  let ms =
    List.filter_map
      (fun (loc, name, uniq, (abs : Typed_tree.abstraction)) ->
        let typ = type_of_func abs.func in
        if is_polymorphic typ then Some (loc, name, uniq, typ) else None)
      funs
  in
  let m = Mmutual_rec (loc, ms) :: m in
  List.fold_left (fun m (loc, n, u, abs) -> add_fun loc n u abs m) m funs

let add_external loc t name cname ~closure m =
  let closure = match clean t with Tfun _ -> closure | _ -> false in
  let call = match cname with Some s -> s | None -> name in
  Mext (loc, t, { user = name; call }, closure) :: m

let module_cache = Hashtbl.create 64
(* TODO sort by insertion order *)

(* Right now we only ever compile one module, so this can safely be global *)
let poly_funcs = ref []
let paths = ref [ "." ]

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
      let nsub = Smap.add n (Env.mod_fn_name ~mname n) nsub in
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
  | Mfun (l, t, n) -> Mfun (l, f t, n)
  | Mext (l, t, n, c) when c -> Mext (l, f t, n, c)
  | Mext (l, t, n, c) -> Mext (l, f t, n, c)
  | Mpoly_fun (l, abs, n, u) ->
      (* We ought to f here. Not only the type, but
         the body as well? *)
      poly_funcs :=
        (* Change name of poly func to module-unique name to prevent name clashes from
           different modules *)
        Typed_tree.Tl_function (Env.mod_fn_name ~mname n, u, abs) :: !poly_funcs;
      (* This will be ignored in [add_to_env] *)
      Mpoly_fun (l, abs, n, u)
  | Mmutual_rec (l, decls) ->
      let decls = List.map (fun (l, n, u, t) -> (l, n, u, f t)) decls in
      let mname_decls =
        List.map
          (fun (_, n, u, t) ->
            let nn = Env.mod_fn_name ~mname n in
            (nn, u, t))
          decls
      in
      poly_funcs := Typed_tree.Tl_mutual_rec_decls mname_decls :: !poly_funcs;
      Mmutual_rec (l, decls)

(* Number qvars from 0 and change names of Var-nodes to their unique form.
   _<module_name>_name*)
let fold_canonize mname (ts_sub, nsub) = function
  | Mtype (l, t) ->
      let a, t = canonize ts_sub t in
      ((a, nsub), Mtype (l, t))
  | Mfun (l, t, n) ->
      let a, t = canonize ts_sub t in
      let s = Smap.add n.user (Env.mod_fn_name ~mname n.user) nsub in
      ((a, s), Mfun (l, t, n))
  | Mext (l, t, n, c) ->
      let a, t = canonize ts_sub t in
      let s = Smap.add n.user (Env.mod_fn_name ~mname n.user) nsub in
      ((a, s), Mext (l, t, n, c))
  | Mpoly_fun (l, abs, n, u) ->
      (* We ought to f here. Not only the type, but
         the body as well? *)
      (* Change Var-nodes in body here *)
      let s = Smap.add n (Env.mod_fn_name ~mname n) nsub in
      let a, abs = canonabs mname ts_sub s abs in
      (* This will be ignored in [add_to_env] *)
      ((a, s), Mpoly_fun (l, abs, n, u))
  | Mmutual_rec (l, decls) ->
      let (a, nsub), decls =
        List.fold_left_map
          (fun (ts_sub, nsub) (l, n, u, t) ->
            let a, t = canonize ts_sub t in
            let s = Smap.add n (Env.mod_fn_name ~mname n) nsub in
            ((a, s), (l, n, u, t)))
          (ts_sub, nsub) decls
      in
      ((a, nsub), Mmutual_rec (l, decls))

let read_module ~regeneralize name =
  match Hashtbl.find_opt module_cache name with
  | Some r -> r
  | None -> (
      try
        let c = open_in (find_file name ".smi") in
        let r =
          Result.map t_of_sexp (Sexp.input c)
          |> Result.map (List.map (map_item ~mname:name ~f:regeneralize))
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
  let modul = Some mname in
  List.fold_left
    (fun env item ->
      match item with
      | Mtype (_, Trecord (params, Some name, labels)) ->
          Env.add_record name ~modul ~params ~labels env
      | Mtype (_, Tvariant (params, name, ctors)) ->
          Env.add_variant name ~modul ~params ~ctors env
      | Mtype (_, Talias (name, t)) -> Env.add_alias ~modul name t env
      | Mtype (_, t) ->
          failwith ("Internal Error: Unexpected type in module: " ^ show_typ t)
      | Mfun (l, t, n) ->
          Env.add_external
            ~imported:(Some (mname, `Schmu))
            n.user
            ~cname:(Some (mname ^ "_" ^ n.call))
            ~closure:false t l env
      | Mpoly_fun (l, abs, n, _) ->
          let imported = Some (mname, `Schmu) in
          let env =
            Env.(
              add_value n
                { def_value with typ = type_of_func abs.func; imported }
                l env)
          in
          env
      | Mext (l, t, n, closure) ->
          Env.add_external ~closure
            ~imported:(Some (mname, `C))
            n.user ~cname:(Some n.call) t l env
      | Mmutual_rec (_, ds) ->
          List.fold_left
            (fun env (l, name, _, typ) ->
              Env.(
                add_value name
                  { def_value with typ; imported = Some (mname, `Schmu) }
                  l env))
            env ds)
    env m

let make_module sub name m =
  let s t =
    match extr_name t with Some p -> sub := S.add p !sub | None -> ()
  in
  match m with
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
      Mmutual_rec (l, ds)

let to_channel c ~outname m =
  let s = ref S.empty in
  m |> List.rev
  |> List.map (make_module s outname)
  |> List.fold_left_map (fold_canonize outname) (Types.Smap.empty, Smap.empty)
  |> snd |> sexp_of_t |> Sexp.to_channel c
