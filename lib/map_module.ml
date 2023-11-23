open Types

module type Map_tree = sig
  type sub

  val empty_sub : sub

  val change_var :
    mname:Path.t ->
    string ->
    Path.t option ->
    string Smap.t ->
    sub ->
    string * Path.t option

  val absolute_module_name : mname:Path.t -> string -> string
  val map_type : sub -> typ -> sub * typ
end

module Canonize = struct
  (* This is the original conanize impl from old module.ml *)
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
    | Tfixed_array (iv, t) ->
        let sub, t = canonize sub t in
        (sub, Tfixed_array (iv, t))
    | Tabstract (ps, n, t) ->
        let sub, ps = List.fold_left_map (fun sub t -> canonize sub t) sub ps in
        let sub, t =
          match t with
          | Tvar { contents = Unbound (sym, l) } -> (
              (* If it's still unbound, then it belongs to a module-type.
                 Use the same mechanism as for Qvar ids to create something sensible *)
              match Smap.find_opt sym sub with
              | Some s -> (sub, Tvar (ref (Unbound (s, l))))
              | None ->
                  let ns = string_of_int !c in
                  incr c;
                  (Smap.add sym ns sub, Tvar (ref (Unbound (ns, l)))))
          | t ->
              let sub, t = canonize sub t in
              (sub, t)
        in
        (sub, Tabstract (ps, n, t))
end

module Make (C : Map_tree) = struct
  let rec map_body mname nsub sub (e : Typed_tree.typed_expr) =
    let sub, typ = C.map_type sub e.typ in
    let sub, expr = map_expr mname nsub sub e.expr in
    (sub, Typed_tree.{ e with typ; expr })

  and map_expr mname nsub sub = function
    | Typed_tree.Var (id, m) ->
        let id, m = C.change_var ~mname id m nsub sub in
        (sub, Var (id, m))
    | Const (Array a) ->
        let sub, a = List.fold_left_map (map_body mname nsub) sub a in
        (sub, Const (Array a))
    | Const c -> (sub, Const c)
    | Bop (op, e1, e2) ->
        let sub, e1 = (map_body mname nsub) sub e1 in
        let sub, e2 = (map_body mname nsub) sub e2 in
        (sub, Bop (op, e1, e2))
    | Unop (op, e) ->
        let sub, e = (map_body mname nsub) sub e in
        (sub, Unop (op, e))
    | If (cond, o, e1, e2) ->
        let sub, cond = (map_body mname nsub) sub cond in
        let sub, e1 = (map_body mname nsub) sub e1 in
        let sub, e2 = (map_body mname nsub) sub e2 in
        (sub, If (cond, o, e1, e2))
    | Let d ->
        let sub, rhs = (map_body mname nsub) sub d.rhs in
        (* Change binding name as well *)
        let sub, cont = (map_body mname nsub) sub d.cont in
        (sub, Let { d with rhs; cont })
    | Bind (id, lhs, cont) ->
        let sub, lhs = (map_body mname nsub) sub lhs in
        let sub, cont = (map_body mname nsub) sub cont in
        (sub, Bind (id, lhs, cont))
    | Lambda (i, abs) ->
        let sub, abs = map_abs mname sub nsub abs in
        (sub, Lambda (i, abs))
    | Function (n, u, abs, cont) ->
        let sub, abs = map_abs mname sub nsub abs in
        let sub, cont = (map_body mname nsub) sub cont in
        (sub, Function (n, u, abs, cont))
    | Mutual_rec_decls (fs, cont) ->
        let sub, fs =
          List.fold_left_map
            (fun sub (n, u, t) ->
              let sub, t = C.map_type sub t in
              (sub, (n, u, t)))
            sub fs
        in
        let sub, cont = (map_body mname nsub) sub cont in
        (sub, Mutual_rec_decls (fs, cont))
    | App { callee; args } ->
        let sub, callee = (map_body mname nsub) sub callee in
        let sub, args =
          List.fold_left_map
            (fun sub (e, mut) ->
              let sub, e = (map_body mname nsub) sub e in
              (sub, (e, mut)))
            sub args
        in
        (sub, App { callee; args })
    | Record fs ->
        let sub, fs =
          List.fold_left_map
            (fun sub (n, e) ->
              let sub, e = (map_body mname nsub) sub e in
              (sub, (n, e)))
            sub fs
        in
        (sub, Record fs)
    | Field (e, i, n) ->
        let sub, e = (map_body mname nsub) sub e in
        (sub, Field (e, i, n))
    | Set (a, b, m) ->
        let sub, a = (map_body mname nsub) sub a in
        let sub, b = (map_body mname nsub) sub b in
        (sub, Set (a, b, m))
    | Sequence (a, b) ->
        let sub, a = (map_body mname nsub) sub a in
        let sub, b = (map_body mname nsub) sub b in
        (sub, Sequence (a, b))
    | Ctor (n, i, e) ->
        let sub, e =
          match e with
          | Some e ->
              let sub, e = (map_body mname nsub) sub e in
              (sub, Some e)
          | None -> (sub, None)
        in
        (sub, Ctor (n, i, e))
    | Variant_index e ->
        let sub, e = (map_body mname nsub) sub e in
        (sub, Variant_index e)
    | Variant_data e ->
        let sub, e = (map_body mname nsub) sub e in
        (sub, Variant_data e)
    | Fmt fs ->
        let sub, fs =
          List.fold_left_map
            Typed_tree.(
              fun sub e ->
                match e with
                | Fstr s -> (sub, Fstr s)
                | Fexpr e ->
                    let sub, e = (map_body mname nsub) sub e in
                    (sub, Fexpr e))
            sub fs
        in
        (sub, Fmt fs)
    | Move e ->
        let sub, e = (map_body mname nsub) sub e in
        (sub, Move e)

  and map_abs mname sub nsub abs =
    let sub, tparams =
      List.fold_left_map
        (fun sub p ->
          let sub, pt = C.map_type sub p.pt in
          (sub, { p with pt }))
        sub abs.func.tparams
    in
    let sub, ret = C.map_type sub abs.func.ret in
    let sub, kind =
      match abs.func.kind with
      | Simple -> (sub, Simple)
      | Closure l ->
          let sub, l =
            List.fold_left_map
              (fun sub c ->
                let sub, cltyp = C.map_type sub c.cltyp in
                let clname, clmname =
                  C.change_var ~mname c.clname c.clmname nsub sub
                in
                (sub, { c with cltyp; clname; clmname }))
              sub l
          in
          (sub, Closure l)
    in
    let sub, touched =
      List.fold_left_map
        (fun sub t ->
          let sub, ttyp = C.map_type sub Typed_tree.(t.ttyp) in
          (sub, { t with ttyp }))
        sub abs.func.touched
    in
    let func = { Typed_tree.tparams; ret; kind; touched } in
    let sub, body = (map_body mname nsub) sub abs.body in
    (sub, { abs with func; body })

  and map_tl_items mname nsub sub items =
    let (_, sub), items =
      List.fold_left_map
        (fun (nsub, sub) item -> map_tl_item mname nsub sub item)
        (nsub, sub) items
    in
    (sub, items)

  and map_tl_item mname nsub sub = function
    | Typed_tree.Tl_let d ->
        let sub, lhs = (map_body mname nsub) sub d.lhs in
        (* Change binding name *)
        (* Is absolute module name correct for functor bodies? *)
        ((nsub, sub), Typed_tree.Tl_let { d with lhs })
    | Tl_bind (id, rhs) ->
        let sub, rhs = (map_body mname nsub) sub rhs in
        ((nsub, sub), Tl_bind (id, rhs))
    | Tl_function (loc, n, u, abs) ->
        let sub, abs = map_abs mname sub nsub abs in
        ((nsub, sub), Tl_function (loc, n, u, abs))
    | Tl_expr e ->
        let sub, e = map_body mname nsub sub e in
        ((nsub, sub), Tl_expr e)
    | Tl_mutual_rec_decls decls ->
        let sub, decls =
          List.fold_left_map
            (fun sub (n, u, t) ->
              let sub, t = C.map_type sub t in
              (sub, (n, u, t)))
            sub decls
        in
        ((nsub, sub), Tl_mutual_rec_decls decls)
    | (Tl_module _ | Tl_module_alias _) as todo -> ((nsub, sub), todo)

  open Module_common

  let rec fold_map_type_item mname (sub, nsub) = function
    | Mtype (l, t) ->
        let a, t = C.map_type sub t in
        ((a, nsub), Mtype (l, t))
    | Mfun (l, t, n) ->
        let a, t = C.map_type sub t in
        ((a, nsub), Mfun (l, t, n))
    | Mext (l, t, n, c) ->
        let a, t = C.map_type sub t in
        ((a, nsub), Mext (l, t, n, c))
    | Mpoly_fun (l, abs, n, u) ->
        (* Change Var-nodes in body here *)
        let a, abs = map_abs mname sub nsub abs in
        (* This allows changes from poly fun to concrete fun for functors *)
        let fun_ = make_fun l ~mname n u abs in
        (* This will be ignored in [add_to_env] *)
        ((a, nsub), fun_)
    | Mmutual_rec (l, decls) ->
        let (a, nsub), decls =
          List.fold_left_map
            (fun (sub, nsub) (l, n, u, t) ->
              let a, t = C.map_type sub t in
              ((a, nsub), (l, n, u, t)))
            (sub, nsub) decls
        in
        ((a, nsub), Mmutual_rec (l, decls))
    | Malias (l, n, tree) ->
        let sub, tree = map_body mname nsub sub tree in
        ((sub, nsub), Malias (l, n, tree))
    (* Substitutions from inner modules shouldn't be carried outward *)
    | Mlocal_module (loc, n, t) ->
        let _, t = map_module (Path.append n mname) sub t in
        ((sub, nsub), Mlocal_module (loc, n, t))
    | Mapplied_functor (loc, n, p, t) ->
        let _, t = map_module p sub t in
        ((sub, nsub), Mapplied_functor (loc, n, p, t))
    | Mfunctor (loc, n, ps, t, m) ->
        let mname = Path.append n mname in
        let f sub (n, intf) =
          let sub, intf = map_intf sub intf in
          (sub, (n, intf))
        in
        let osub = sub in
        let sub, ps = List.fold_left_map f sub ps in
        let sub, t = map_tl_items mname nsub sub t in
        let _, m = map_module mname sub m in
        ((osub, nsub), Mfunctor (loc, n, ps, t, m))
    | Mmodule_alias _ as m -> ((sub, nsub), m)
    | Mmodule_type (loc, n, intf) ->
        let _, intf = map_intf sub intf in
        ((sub, nsub), Mmodule_type (loc, n, intf))

  and map_module mname sub m =
    let (sub, _), i =
      List.fold_left_map (fold_map_type_item mname) (sub, Smap.empty) m.i
    in
    let sub, s = map_intf sub m.s in
    (sub, { m with s; i })

  and map_intf sub intf =
    List.fold_left_map
      (fun sub (key, l, t, k) ->
        let sub, t = C.map_type sub t in
        (sub, (key, l, t, k)))
      sub intf
end
