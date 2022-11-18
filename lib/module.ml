open Types
module Sexp = Csexp.Make (Sexplib0.Sexp)
open Sexplib0.Sexp_conv
module S = Set.Make (Path)

type t = item list [@@deriving sexp]

and item =
  | Mtype of typ
  | Mfun of typ * string
  | Mext of typ * string * string option
  | Mpoly_fun of Typed_tree.abstraction * string

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)

(* For named functions *)
let unique_name name = function
  | None -> name
  | Some n -> name ^ "__" ^ string_of_int n

let lambda_name id = "__fun" ^ string_of_int id

let is_polymorphic_func (f : Typed_tree.func) =
  is_polymorphic (Tfun (f.tparams, f.ret, f.kind))

let add_type t m = Mtype t :: m

let type_of_func (func : Typed_tree.func) =
  Tfun (func.tparams, func.ret, func.kind)

let add_fun name uniq (abs : Typed_tree.abstraction) m =
  if is_polymorphic_func abs.func then
    (* failwith "polymorphic functions in modules are not supported yet TODO" *)
    Mpoly_fun (abs, unique_name name uniq) :: m
  else Mfun (type_of_func abs.func, unique_name name uniq) :: m

let add_external t name cname m = Mext (t, name, cname) :: m
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
  | Tvar { contents = Unbound (id, i) } -> (
      match Smap.find_opt id sub with
      | Some s -> (sub, Tvar (ref (Unbound (s, i))))
      | None ->
          let ns = string_of_int !c in
          incr c;
          (Smap.add id ns sub, Tvar (ref (Unbound (ns, i)))))
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

let rec canonbody sub (e : Typed_tree.typed_expr) =
  let sub, typ = canonize sub e.typ in
  let sub, expr = canonexpr sub e.expr in
  (sub, Typed_tree.{ e with typ; expr })

and canonexpr sub = function
  | Typed_tree.Var _ as v -> (sub, v)
  | Const (Array a) ->
      let sub, a = List.fold_left_map canonbody sub a in
      (sub, Const (Array a))
  | Const c -> (sub, Const c)
  | Bop (op, e1, e2) ->
      let sub, e1 = canonbody sub e1 in
      let sub, e2 = canonbody sub e2 in
      (sub, Bop (op, e1, e2))
  | Unop (op, e) ->
      let sub, e = canonbody sub e in
      (sub, Unop (op, e))
  | If (cond, e1, e2) ->
      let sub, cond = canonbody sub cond in
      let sub, e1 = canonbody sub e1 in
      let sub, e2 = canonbody sub e2 in
      (sub, If (cond, e1, e2))
  | Let d ->
      let sub, lhs = canonbody sub d.lhs in
      let sub, cont = canonbody sub d.cont in
      (sub, Let { d with lhs; cont })
  | Lambda (i, abs) ->
      let sub, abs = canonabs sub abs in
      (sub, Lambda (i, abs))
  | Function (n, u, abs, cont) ->
      let sub, abs = canonabs sub abs in
      let sub, cont = canonbody sub cont in
      (sub, Function (n, u, abs, cont))
  | App { callee; args } ->
      let sub, callee = canonbody sub callee in
      let sub, args =
        List.fold_left_map
          (fun sub (e, mut) ->
            let sub, e = canonbody sub e in
            (sub, (e, mut)))
          sub args
      in
      (sub, App { callee; args })
  | Record fs ->
      let sub, fs =
        List.fold_left_map
          (fun sub (n, e) ->
            let sub, e = canonbody sub e in
            (sub, (n, e)))
          sub fs
      in
      (sub, Record fs)
  | Field (e, i) ->
      let sub, e = canonbody sub e in
      (sub, Field (e, i))
  | Set (a, b) ->
      let sub, a = canonbody sub a in
      let sub, b = canonbody sub b in
      (sub, Set (a, b))
  | Sequence (a, b) ->
      let sub, a = canonbody sub a in
      let sub, b = canonbody sub b in
      (sub, Sequence (a, b))
  | Ctor (n, i, e) ->
      let sub, e =
        match e with
        | Some e ->
            let sub, e = canonbody sub e in
            (sub, Some e)
        | None -> (sub, None)
      in
      (sub, Ctor (n, i, e))
  | Variant_index e ->
      let sub, e = canonbody sub e in
      (sub, Variant_index e)
  | Variant_data e ->
      let sub, e = canonbody sub e in
      (sub, Variant_data e)
  | Fmt fs ->
      let sub, fs =
        List.fold_left_map
          Typed_tree.(
            fun sub e ->
              match e with
              | Fstr s -> (sub, Fstr s)
              | Fexpr e ->
                  let sub, e = canonbody sub e in
                  (sub, Fexpr e))
          sub fs
      in
      (sub, Fmt fs)

and canonabs sub abs =
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
              (sub, { c with cltyp }))
            sub l
        in
        (sub, Closure l)
  in
  let func = { Typed_tree.tparams; ret; kind } in
  let sub, body = canonbody sub abs.body in
  (sub, { abs with func; body })

let map_item ~f = function
  | Mtype t -> Mtype (f t)
  | Mfun (t, n) -> Mfun (f t, n)
  | Mext (t, n, cn) -> Mext (f t, n, cn)
  | Mpoly_fun (abs, n) ->
      (* We ought to f here. Not only the type, but
         the body as well? *)
      poly_funcs := Typed_tree.Tl_function (n, None, abs) :: !poly_funcs;
      (* This will be ignored in [add_to_env] *)
      Mpoly_fun (abs, n)

let fold_canonize sub = function
  | Mtype t ->
      let a, t = canonize sub t in
      (a, Mtype t)
  | Mfun (t, n) ->
      let a, t = canonize sub t in
      (a, Mfun (t, n))
  | Mext (t, n, cn) ->
      let a, t = canonize sub t in
      (a, Mext (t, n, cn))
  | Mpoly_fun (abs, n) ->
      (* We ought to f here. Not only the type, but
         the body as well? *)
      let sub, abs = canonabs sub abs in
      poly_funcs := Typed_tree.Tl_function (n, None, abs) :: !poly_funcs;
      (* This will be ignored in [add_to_env] *)
      (sub, Mpoly_fun (abs, n))

let read_module ~regeneralize name =
  match Hashtbl.find_opt module_cache name with
  | Some r -> r
  | None -> (
      try
        let c = open_in (find_file name ".smi") in
        let r =
          Result.map t_of_sexp (Sexp.input c)
          |> Result.map (List.map (map_item ~f:regeneralize))
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

let add_to_env env m =
  let dummy_loc = Lexing.(dummy_pos, dummy_pos) in
  List.fold_left
    (fun env item ->
      match item with
      | Mtype (Trecord (params, Some name, labels)) ->
          Env.add_record (Path.get_hd name) ~params ~labels env
      | Mtype (Tvariant (params, name, ctors)) ->
          Env.add_variant (Path.get_hd name) ~params ~ctors env
      | Mtype (Talias (name, t)) -> Env.add_alias (Path.get_hd name) t env
      | Mtype t ->
          failwith ("Internal Error: Unexpected type in module: " ^ show_typ t)
      | Mfun (t, n) ->
          Env.add_external ~imported:(Some `Schmu) n
            ~cname:(Some ("schmu_" ^ n))
            t dummy_loc env
      | Mpoly_fun (abs, n) ->
          let env =
            Env.(
              add_value n
                { def_value with typ = type_of_func abs.func; imported = true }
                dummy_loc env)
          in
          env
      | Mext (t, n, cname) ->
          Env.add_external ~imported:(Some `C) n ~cname t dummy_loc env)
    env m

let rec mod_t sub name t =
  let nm p = if S.mem p sub then Path.Pmod (name, p) else p in
  match t with
  | Talias (p, t) -> Talias (nm p, mod_t sub name t)
  | Trecord (ps, n, fields) ->
      let ps = List.map (mod_t sub name) ps in
      let n = Option.map nm n in
      let fields =
        Array.map (fun f -> { f with ftyp = mod_t sub name f.ftyp }) fields
      in
      Trecord (ps, n, fields)
  | Tvariant (ps, n, ctors) ->
      let ps = List.map (mod_t sub name) ps in
      let n = nm n in
      let ctors =
        Array.map
          (fun c -> { c with ctyp = Option.map (mod_t sub name) c.ctyp })
          ctors
      in
      Tvariant (ps, n, ctors)
  | Traw_ptr t -> Traw_ptr (mod_t sub name t)
  | Tarray t -> Tarray (mod_t sub name t)
  | Tfun (ps, r, kind) ->
      let ps = List.map (fun p -> { p with pt = mod_t sub name p.pt }) ps in
      let r = mod_t sub name r in
      let kind =
        match kind with
        | Simple -> kind
        | Closure c ->
            let c =
              List.map (fun c -> { c with cltyp = mod_t sub name c.cltyp }) c
            in
            Closure c
      in
      Tfun (ps, r, kind)
  | Tvar { contents = Link t } -> Tvar { contents = Link (mod_t sub name t) }
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
  | Lambda (i, abs) -> Lambda (i, mod_abs f abs)
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

let make_module sub name m =
  let s t =
    match extr_name t with Some p -> sub := S.add p !sub | None -> ()
  in
  match m with
  | Mtype t ->
      s t;
      Mtype (mod_t !sub name t)
  | Mfun (t, n) ->
      sub := S.add (Path.Pid n) !sub;
      Mfun (mod_t !sub name t, n)
  | Mext (t, n, cn) ->
      sub := S.add (Path.Pid n) !sub;
      Mext (mod_t !sub name t, n, cn)
  | Mpoly_fun (abs, n) ->
      sub := S.add (Path.Pid n) !sub;
      Mpoly_fun (mod_abs (mod_t !sub name) abs, n)

let to_channel c name m =
  let s = ref S.empty in
  m |> List.rev
  |> List.map (make_module s name)
  |> List.fold_left_map fold_canonize Types.Smap.empty
  |> snd |> sexp_of_t |> Sexp.to_channel c
