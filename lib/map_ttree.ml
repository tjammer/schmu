open Types

module type Map_tree = sig
  val change_var : mname:Path.t -> Path.t option -> unit
  val absolute_module_name : mname:Path.t -> string -> string
end

module Make (C : Map_tree) = struct
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
              failwith
                "Internal Error: Should this not have been caught before?"
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
    | Typed_tree.Var (id, m) ->
        let id = change_name id nsub in
        C.change_var ~mname m;
        (sub, Var (id, m))
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
        let nsub = Smap.add d.id (C.absolute_module_name ~mname d.id) nsub in
        let sub, cont = (canonbody mname nsub) sub d.cont in
        (sub, Let { d with rhs; cont })
    | Bind (id, lhs, cont) ->
        let sub, lhs = (canonbody mname nsub) sub lhs in
        let nsub = Smap.add id (C.absolute_module_name ~mname id) nsub in
        let sub, cont = (canonbody mname nsub) sub cont in
        (sub, Bind (id, lhs, cont))
    | Lambda (i, abs) ->
        let sub, abs = canonabs mname sub nsub abs in
        (sub, Lambda (i, abs))
    | Function (n, u, abs, cont) ->
        let nsub = Smap.add n (C.absolute_module_name ~mname n) nsub in
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

  and canon_tl_items mname nsub sub items =
    let (_, sub), items =
      List.fold_left_map
        (fun (nsub, sub) item -> canon_tl_item mname nsub sub item)
        (nsub, sub) items
    in
    (sub, items)

  and canon_tl_item mname nsub sub = function
    | Typed_tree.Tl_let d ->
        let sub, lhs = (canonbody mname nsub) sub d.lhs in
        (* Change binding name *)
        (* Is absolute module name correct for functor bodies? *)
        let nsub = Smap.add d.id (C.absolute_module_name ~mname d.id) nsub in
        ((nsub, sub), Typed_tree.Tl_let { d with lhs })
    | Tl_bind (id, rhs) ->
        let sub, rhs = (canonbody mname nsub) sub rhs in
        let nsub = Smap.add id (C.absolute_module_name ~mname id) nsub in
        ((nsub, sub), Tl_bind (id, rhs))
    | Tl_function (loc, n, u, abs) ->
        let nsub' = Smap.add n (C.absolute_module_name ~mname n) nsub in
        let sub, abs = canonabs mname sub nsub' abs in
        ((nsub, sub), Tl_function (loc, n, u, abs))
    | Tl_expr e ->
        let sub, e = canonbody mname nsub sub e in
        ((nsub, sub), Tl_expr e)
    | (Tl_mutual_rec_decls _ | Tl_module _ | Tl_module_alias _) as todo ->
        ((nsub, sub), todo)
end
