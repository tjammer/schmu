module Make (Mtree : Monomorph_tree_intf.S) = struct
  open Cleaned_types
  open Mtree
  open Malloc_types
  module Vars = Map.Make (String)
  module Apptbl = Hashtbl
  module Mallocs_ipml = Mallocs.Make (Mtree)
  open Mallocs_ipml

  module To_gen_func = struct
    type t = to_gen_func

    let compare a b = String.compare a.name.call b.name.call
  end

  module Fset = Set.Make (To_gen_func)
  module Sset = Set.Make (String)

  type upward = bool ref

  type to_gen_func_kind =
    (* TODO use a prefix *)
    | Concrete of To_gen_func.t * string * upward
    | Polymorphic of string * upward (* call name *)
    | Forward_decl of string * typ * upward
    | Mutual_rec of string * typ * upward
    | Builtin of Builtin.t
    | Inline of (string * Mod_id.t) list * typ * monod_tree
    | No_function

  type alloc = Value of alloca | Two_values of alloc * alloc | No_value

  type var_normal = {
    fn : to_gen_func_kind;
    alloc : alloc;
    malloc : Malloc.t;
    tailrec : bool;
  }

  (* TODO could be used for Builtin as well *)
  type var =
    | Normal of var_normal
    | Const of string
    | Global of string * var_normal * bool ref

  type morph_param = {
    vars : var Vars.t;
    monomorphized : Sset.t;
    funcs : Fset.t; (* to generate in codegen *)
    ret : bool;
    (* Marks an expression where an if is the last piece which returns a record.
       Needed for tail call elim *)
    mallocs : Mallocs.t;
        (* Tracks all heap allocations in a scope. If a value with allocation is
           returned, they are marked for the parent scope. Otherwise freed *)
    toplvl : bool;
    mname : Path.t; (* Module name *)
    mainmodule : Path.t;
    alloc_lvl : int;
    recursion_stack : (string * recurs) list;
    gen_poly_bodies : bool;
    remove_from_closure : Sset.t;
  }

  let apptbl = Apptbl.create 64
  let missing_polys_tbl = Hashtbl.create 64
  let poly_funcs_tbl = Hashtbl.create 64
  let deferredfunc_tbl = Hashtbl.create 64
  let typ_of_abs abs = Tfun (abs.func.params, abs.func.ret, abs.func.kind)

  let func_of_typ = function
    | Tfun (params, ret, kind) -> { params; ret; kind }
    | _ -> failwith "Internal Error: Not a function type"

  let rec find_function_expr vars = function
    | Mvar (_, Vglobal id, _) -> (
        (* Use the id saved in Vglobal. The usual id is the call name / unique
           global name *)
        match Vars.find_opt id vars with
        | Some (Global (_, thing, used)) ->
            used := true;
            thing.fn
        | Some _ -> failwith "Internal Error: Unexpected nonglobal"
        | None -> No_function)
    | Mvar (id, _, _) -> (
        match Vars.find_opt id vars with
        | Some (Normal thing) -> thing.fn
        | Some (Global (_, thing, _)) ->
            (* Usually globals should be read as Vglobal, but for constexprs it
               might be different *)
            thing.fn
        | Some (Const _) -> No_function
        | None -> (
            match Builtin.of_string id with
            | Some b -> Builtin b
            | None -> No_function))
    | Mconst _ | Mapp _ | Mrecord _ | Mfield _ | Mbop _ | Munop _ | Mctor _ ->
        No_function
    | Mif _ ->
        (* We are not allowing to return functions in ifs, b/c we cannot codegen
           anyway *)
        No_function
    | Mlambda (name, _, _, _, _) -> (
        match Vars.find_opt name vars with
        | Some (Normal thing) -> thing.fn
        | _ -> No_function)
    | Mlet _ | Mbind _ -> No_function (* TODO cont? Didn't work on quick test *)
    | Mfree_after (e, _) | Mseq (_, e) -> find_function_expr vars e.expr
    | e ->
        print_endline (show_expr e);
        failwith "Unsupported expression for find_function"

  let nominal_name name ~closure ~poly concrete =
    let open Printf in
    let rec aux ~poly = function
      | Tint -> "l"
      | Tbool -> "b"
      | Tunit -> "u"
      | Tu8 | Ti8 -> "c"
      | Tu16 | Ti16 -> "s"
      | Tfloat -> "d"
      | Ti32 | Tu32 -> "i"
      | Tf32 -> "f"
      | Tpoly _ -> "g"
      | Tfun (ps, r, k) -> (
          match poly with
          | Tfun (pps, pr, _) -> (
              let k =
                match k with
                | Closure c when closure -> (
                    match c with
                    | [] -> ""
                    | c ->
                        "C"
                        ^ String.concat ""
                            (List.map (fun c -> aux ~poly:Tbool c.cltyp) c))
                | Closure _ | Simple -> ""
              in
              try
                let ps =
                  List.fold_left2
                    (fun acc poly concrete ->
                      if is_type_polymorphic poly.pt then
                        acc ^ (aux ~poly:poly.pt) concrete.pt
                      else acc)
                    "" pps ps
                in
                let r =
                  if is_type_polymorphic pr then
                    sprintf "r%s" ((aux ~poly:pr) r)
                  else ""
                in
                (* Only put '_' between name and rest if there is a rest *)
                if
                  String.length k == 0
                  && String.length ps == 0
                  && String.length r == 0
                then name
                else sprintf "%s_%s%s%s" name ps r k
              with Invalid_argument _ ->
                failwith "Internal Error: param count does not match")
          | _ ->
              let k =
                match k with
                | Closure c when closure -> (
                    match c with
                    | [] -> ""
                    | c ->
                        "C"
                        ^ String.concat ""
                            (List.map (fun c -> aux ~poly:Tbool c.cltyp) c))
                | Closure _ | Simple -> ""
              in
              let ps =
                List.fold_left (fun acc p -> acc ^ (aux ~poly:Tbool) p.pt) "" ps
              in
              let r = sprintf "r%s" (aux ~poly:Tbool r) in
              sprintf "%s_%s%s%s" name ps r k)
      | Trecord (ps, _, Some n) | Tvariant (ps, _, n) -> (
          match ps with
          | [] -> n
          | ps ->
              sprintf "%s.%s" n
                (String.concat "" (List.map (aux ~poly:Tbool) ps)))
      | Trecord (_, (Rec_not fs | Rec_top fs), None) ->
          "tp."
          ^ String.concat ""
              (Array.map (fun f -> aux ~poly:Tbool f.ftyp) fs |> Array.to_list)
      | Trecord (_, Rec_folded, None) -> failwith "unreachable"
      | Traw_ptr t ->
          sprintf "p.%s"
            (match poly with
            | Traw_ptr poly -> aux ~poly t
            | _ -> (aux ~poly:Tbool) t)
      | Tarray t ->
          sprintf "a.%s"
            (match poly with
            | Tarray poly -> aux ~poly t
            | _ -> (aux ~poly:Tbool) t)
      | Trc (Strong, t) ->
          sprintf "R.%s"
            (match poly with
            | Trc (Strong, poly) -> aux ~poly t
            | _ -> (aux ~poly:Tbool) t)
      | Trc (Weak, t) ->
          sprintf "w.%s"
            (match poly with
            | Trc (Weak, poly) -> aux ~poly t
            | _ -> (aux ~poly:Tbool) t)
      | Tfixed_array (i, t) ->
          sprintf "A%i.%s" i
            (match poly with
            | Tfixed_array (_, poly) -> aux ~poly t
            | _ -> (aux ~poly:Tbool) t)
    in
    aux ~poly concrete

  let is_actually_recursive p typ name =
    match (p.recursion_stack, typ) with
    | (call, _) :: _, _ when String.equal call name -> true
    | _, Tfun (_, _, Closure _) ->
        (* We are not actually recursive but in an inner function. Generate a
           non-mono call *)
        false
    | _ -> true

  let get_mono_name name ~closure ~poly concrete =
    let name = nominal_name name ~closure ~poly concrete in
    if String.starts_with ~prefix:"__" name then name else "__" ^ name

  let rec subst_type ~concrete poly parent =
    let rec inner subst = function
      | Tpoly id, t -> (
          match Vars.find_opt id subst with
          | Some _ -> (* Already in tbl*) (subst, t)
          | None -> (Vars.add id t subst, t))
      | Tfun (ps1, r1, k1), Tfun (ps2, r2, k2) ->
          let subst, ps =
            List.fold_left_map
              (fun subst (l, r) ->
                let s, pt = inner subst (l.pt, r.pt) in
                (s, { l with pt }))
              subst (List.combine ps1 ps2)
          in
          let subst, r = inner subst (r1, r2) in
          let subst, kind =
            match (k1, k2) with
            | Simple, Simple -> (subst, Simple)
            | Closure c1, Closure c2 ->
                let s, c =
                  List.fold_left_map
                    (fun subst (l, r) ->
                      let s, cltyp = inner subst (l.cltyp, r.cltyp) in
                      (* Copied from [subst_kind] *)
                      let is_function =
                        match cltyp with Tfun _ -> true | _ -> false
                      in
                      let clname =
                        if
                          is_function && (not l.clparam)
                          && is_type_polymorphic l.cltyp
                          && not (is_type_polymorphic cltyp)
                        then
                          get_mono_name l.clname ~closure:true ~poly:l.cltyp
                            cltyp
                        else l.clname
                      in
                      (s, { l with cltyp; clname }))
                    subst (List.combine c1 c2)
                in
                (s, Closure c)
            | _ ->
                failwith "Internal Error: Unexpected Simple-Closure combination"
          in
          (subst, Tfun (ps, r, kind))
      | ( (Trecord (i, ((Rec_not l1 | Rec_top l1) as kind), record) as l),
          Trecord (j, (Rec_not l2 | Rec_top l2), _) )
        when is_type_polymorphic l ->
          let labels = Array.copy l1 in
          let f (subst, i) (label : Cleaned_types.field) =
            let subst, ftyp = inner subst (label.ftyp, l2.(i).ftyp) in
            labels.(i) <- Cleaned_types.{ (labels.(i)) with ftyp };
            (subst, i + 1)
          in
          let subst, _ = Array.fold_left f (subst, 0) l1 in
          let subst, ps =
            List.fold_left_map
              (fun subst (l, r) -> inner subst (l, r))
              subst (List.combine i j)
          in
          let kind =
            match kind with
            | Rec_not _ -> Rec_not labels
            | Rec_top _ -> Rec_top labels
            | Rec_folded -> failwith "unreachable"
          in

          (subst, Trecord (ps, kind, record))
      | (Trecord (i, Rec_folded, record) as t), Trecord (j, Rec_folded, _)
        when is_type_polymorphic t ->
          let subst, ps =
            List.fold_left_map
              (fun subst (l, r) -> inner subst (l, r))
              subst (List.combine i j)
          in
          (subst, Trecord (ps, Rec_folded, record))
      | ( (Tvariant (i, ((Rec_not l1 | Rec_top l1) as kind), variant) as l),
          Tvariant (j, (Rec_not l2 | Rec_top l2), _) )
        when is_type_polymorphic l ->
          let ctors = Array.copy l1 in
          let f (subst, i) (ctor : Cleaned_types.ctor) =
            let subst, ctyp =
              match (ctor.ctyp, l2.(i).ctyp) with
              | Some l, Some r ->
                  let subst, t = (inner subst) (l, r) in
                  (subst, Some t)
              | _ -> (subst, None)
            in
            ctors.(i) <- Cleaned_types.{ (ctors.(i)) with ctyp };
            (subst, i + 1)
          in
          let subst, _ = Array.fold_left f (subst, 0) l1 in
          let subst, ps =
            List.fold_left_map
              (fun subst (l, r) -> inner subst (l, r))
              subst (List.combine i j)
          in
          let kind =
            match kind with
            | Rec_not _ -> Rec_not ctors
            | Rec_top _ -> Rec_top ctors
            | Rec_folded -> failwith "unreachable"
          in
          (subst, Tvariant (ps, kind, variant))
      | (Tvariant (i, Rec_folded, variant) as t), Tvariant (j, Rec_folded, _)
        when is_type_polymorphic t ->
          let subst, ps =
            List.fold_left_map
              (fun subst (l, r) -> inner subst (l, r))
              subst (List.combine i j)
          in
          (subst, Tvariant (ps, Rec_folded, variant))
      | Traw_ptr l, Traw_ptr r ->
          let subst, t = inner subst (l, r) in
          (subst, Traw_ptr t)
      | Tarray l, Tarray r ->
          let subst, t = inner subst (l, r) in
          (subst, Tarray t)
      | Trc (kl, l), Trc (kr, r) when kl = kr ->
          let subst, t = inner subst (l, r) in
          (subst, Trc (kl, t))
      | Tfixed_array (i, l), Tfixed_array (j, r) ->
          let i, subst =
            if i < 0 then
              let id = "fa" ^ string_of_int i in
              match Vars.find_opt id subst with
              | Some (Tfixed_array (i, _)) -> (i, subst)
              | Some _ -> failwith "Internal Error: What else? in monomorph"
              | None ->
                  let t = Tfixed_array (j, Tunit) in
                  (j, Vars.add id t subst)
            else (i, subst)
          in
          let subst, t = inner subst (l, r) in
          (subst, Tfixed_array (i, t))
      | t, _ -> (subst, t)
    in
    let vars, typ = inner Vars.empty (poly, concrete) in

    let rec subst = function
      | Tpoly id as old -> (
          match Vars.find_opt id vars with Some t -> t | None -> old)
      | Tfun (ps, r, kind) ->
          let ps = List.map (fun p -> { p with pt = subst p.pt }) ps in
          let kind = subst_kind subst kind in
          Tfun (ps, subst r, kind)
      | Trecord (ps, Rec_folded, record) as t when is_type_polymorphic t ->
          let ps = List.map subst ps in
          Trecord (ps, Rec_folded, record)
      | Trecord (ps, ((Rec_not fields | Rec_top fields) as recurs), record) as t
        when is_type_polymorphic t ->
          let ps = List.map subst ps in
          let f field = Cleaned_types.{ field with ftyp = subst field.ftyp } in
          let fields = Array.map f fields in
          let recurs =
            match recurs with
            | Rec_top _ -> Rec_top fields
            | Rec_not _ -> Rec_not fields
            | _ -> failwith "unreachable"
          in
          Trecord (ps, recurs, record)
      | Tvariant (ps, Rec_folded, variant) as t when is_type_polymorphic t ->
          let ps = List.map subst ps in
          Tvariant (ps, Rec_folded, variant)
      | Tvariant (ps, ((Rec_not ctors | Rec_top ctors) as recurs), variant) as t
        when is_type_polymorphic t ->
          let ps = List.map subst ps in
          let f ctor =
            Cleaned_types.{ ctor with ctyp = Option.map subst ctor.ctyp }
          in
          let ctors = Array.map f ctors in
          let recurs =
            match recurs with
            | Rec_top _ -> Rec_top ctors
            | Rec_not _ -> Rec_not ctors
            | _ -> failwith "unreachable"
          in
          Tvariant (ps, recurs, variant)
      | Traw_ptr t -> Traw_ptr (subst t)
      | Tarray t -> Tarray (subst t)
      | Trc (k, t) -> Trc (k, subst t)
      | Tfixed_array (i, t) ->
          let i =
            match Vars.find_opt ("fa" ^ string_of_int i) vars with
            | Some (Tfixed_array (i, _)) -> i
            | Some _ -> failwith "Internal Error: What else? in monomorph"
            | None -> i
          in
          Tfixed_array (i, subst t)
      | t -> t
    in

    (* We might have to substitute other types (in closures) from an outer scope *)
    let subst, typ =
      match parent with
      | Some sub -> ((fun t -> sub t |> subst), sub typ |> subst)
      | None -> (subst, subst typ)
    in

    (subst, typ)

  and subst_kind subst = function
    | Simple -> Simple
    | Closure cls ->
        let cls =
          List.map
            (fun cl ->
              let cltyp = subst cl.cltyp in
              let is_function =
                match cltyp with Tfun _ -> true | _ -> false
              in
              let clname =
                if
                  is_function && (not cl.clparam)
                  && is_type_polymorphic cl.cltyp
                  && not (is_type_polymorphic cltyp)
                then get_mono_name cl.clname ~closure:true ~poly:cl.cltyp cltyp
                else cl.clname
              in
              { cl with cltyp; clname })
            cls
        in
        Closure cls

  and subst_body p subst tree =
    let p = ref p in

    let rec inner tree =
      let sub t = { (inner t) with typ = subst t.typ } in
      match tree.expr with
      | Mvar (_, _, None) -> { tree with typ = subst tree.typ }
      | Mvar (id, _, Some mid) as var ->
          let ex = { tree with typ = subst tree.typ } in
          (* We use the parameters at function creation time to deal with scope *)
          let old_p =
            match Apptbl.find_opt apptbl (string_of_int mid) with
            | Some old ->
                { old with funcs = !p.funcs; monomorphized = !p.monomorphized }
            | None -> failwith "Internal Error: No old param"
          in

          let p2, monomorph = monomorphize_call old_p ex (Some subst) in

          p :=
            {
              !p with
              funcs = Fset.union !p.funcs p2.funcs;
              monomorphized = Sset.union !p.monomorphized p2.monomorphized;
            };

          let expr =
            match monomorph with
            | Default | Builtin _ | Inline _ -> var
            | Concrete name -> Mvar (name, Vnorm, Some mid)
            | Recursive r ->
                (* TODO could this be Vnorm? *)
                Mvar (id, Vrecursive r.call, Some mid)
            | Mono (name, upwardr) -> Mvar (name, Vmono !upwardr, Some mid)
          in

          { ex with expr }
      | Mconst (Array (es, a, i)) ->
          { tree with expr = Mconst (Array (List.map sub es, a, i)) }
      | Mconst (Fixed_array (es, a, i)) ->
          { tree with expr = Mconst (Fixed_array (List.map sub es, a, i)) }
      | Mconst _ -> tree
      | Mbop (bop, l, r) -> { tree with expr = Mbop (bop, sub l, sub r) }
      | Munop (unop, e) -> { tree with expr = Munop (unop, sub e) }
      | Mif expr ->
          let cond = sub expr.cond in
          let e1 = sub expr.e1 in
          let e2 = sub expr.e2 in
          { tree with typ = e1.typ; expr = Mif { expr with cond; e1; e2 } }
      | Mlet (id, expr, proj, gn, vid, cont) ->
          let expr = sub expr in
          let cont = sub cont in
          {
            tree with
            typ = cont.typ;
            expr = Mlet (id, expr, proj, gn, vid, cont);
          }
      | Mbind (id, lhs, cont) ->
          let lhs = sub lhs in
          let cont = sub cont in
          { tree with typ = cont.typ; expr = Mbind (id, lhs, cont) }
      | Mlambda (name, kind, typ, alloca, upward) ->
          let styp = subst typ and kind = subst_kind subst kind in

          (* We may have to monomorphize. For instance if the lambda returned from
             a polymorphic function *)
          let name = mono_callable name styp tree in

          { tree with typ; expr = Mlambda (name, kind, styp, alloca, upward) }
      | Mfunction (name, kind, typ, cont, alloca, upward) ->
          let styp = subst typ and kind = subst_kind subst kind in
          (* We may have to monomorphize. For instance if the lambda returned from
             a polymorphic function *)
          let name = mono_callable name styp { tree with typ } in
          let cont = { (inner cont) with typ = subst cont.typ } in
          {
            tree with
            typ = cont.typ;
            expr = Mfunction (name, kind, styp, cont, alloca, upward);
          }
      | Mapp { callee; args; alloca; id; ms } ->
          let ex = sub callee.ex in

          (* We use the parameters at function creation time to deal with scope *)
          let old_p =
            match Apptbl.find_opt apptbl (string_of_int id) with
            | Some old ->
                { old with funcs = !p.funcs; monomorphized = !p.monomorphized }
            | None -> failwith "Internal Error: No old param"
          in

          let p2, monomorph = monomorphize_call old_p ex (Some subst) in

          let callee = { callee with ex; monomorph } in

          let p2, args =
            List.fold_left_map
              (fun p2 (arg, a) ->
                let ex = sub arg.ex in
                let p2, monomorph = monomorphize_call p2 ex (Some subst) in
                (p2, ({ arg with ex; monomorph }, a)))
              p2 args
          in
          p :=
            {
              !p with
              funcs = Fset.union !p.funcs p2.funcs;
              monomorphized = Sset.union !p.monomorphized p2.monomorphized;
            };

          let func = func_of_typ callee.ex.typ in
          {
            tree with
            typ = func.ret;
            expr = Mapp { callee; args; alloca; id; ms };
          }
      | Mrecord (labels, alloca, id) ->
          let labels = List.map (fun (name, expr) -> (name, sub expr)) labels in
          {
            tree with
            typ = subst tree.typ;
            expr = Mrecord (labels, alloca, id);
          }
      | Mctor ((var, index, expr), alloca, id) ->
          let expr = Mctor ((var, index, Option.map sub expr), alloca, id) in
          { tree with typ = subst tree.typ; expr }
      | Mfield (expr, index) ->
          { tree with typ = subst tree.typ; expr = Mfield (sub expr, index) }
      | Mvar_index expr ->
          { tree with typ = subst tree.typ; expr = Mvar_index (sub expr) }
      | Mvar_data (expr, mid) ->
          { tree with typ = subst tree.typ; expr = Mvar_data (sub expr, mid) }
      | Mset (expr, value, moved) ->
          let expr = Mset (sub expr, sub value, moved) in
          { tree with typ = subst tree.typ; expr }
      | Mseq (expr, cont) ->
          let expr = sub expr in
          let cont = sub cont in
          { tree with typ = cont.typ; expr = Mseq (expr, cont) }
      | Mfree_after (e, fs) ->
          let e = sub e in
          { tree with expr = Mfree_after (e, fs) }
    and mono_callable name typ tree =
      if is_type_polymorphic tree.typ then (
        match Apptbl.find_opt apptbl name with
        | Some old ->
            let old =
              { old with funcs = !p.funcs; monomorphized = !p.monomorphized }
            in
            let p2, monomorph =
              monomorphize_call old { tree with typ } (Some subst)
            in
            let name =
              match monomorph with Mono (name, _) -> name | _ -> name
            in
            p :=
              {
                !p with
                funcs = Fset.union !p.funcs p2.funcs;
                monomorphized = Sset.union !p.monomorphized p2.monomorphized;
              };
            name
        | None ->
            (* Partly copied from [monomorphize_call] *)
            if is_type_polymorphic typ then name
            else
              let p2, monomorph =
                let p, func = get_poly_func !p name in
                monomorphize p tree.typ typ func (Some subst)
              in

              let name =
                match monomorph with Mono (name, _) -> name | _ -> name
              in
              p :=
                {
                  !p with
                  funcs = Fset.union !p.funcs p2.funcs;
                  monomorphized = Sset.union !p.monomorphized p2.monomorphized;
                };

              (* It's concrete, all good *) name)
      else name
    in

    (!p, inner tree)

  and monomorphize_call p expr parent_sub : morph_param * call_name =
    match find_function_expr p.vars expr.expr with
    | Builtin b -> (p, Builtin (b, func_of_typ expr.typ))
    | Inline (ps, typ, tree) ->
        (* Copied from Polymorphic below *)
        (* The parent substitution is threaded through to its children. This deals
           with nested closures *)
        let subst, typ = subst_type ~concrete:expr.typ typ parent_sub in

        (* If the type is still polymorphic, we cannot generate it *)
        if is_type_polymorphic typ then (p, Default)
        else let p, tree = subst_body p subst tree in

             (p, Inline (ps, tree))
    | Forward_decl (name, typ, _) ->
        (* Generate the correct call name. If its mono, we have to recalculate it.
           Closures are tricky, as the arguments are generally not closures, but
           the typ might. We try to subst the (potential) closure by using the
           parent_sub if its available *)
        let actually_recursive = is_actually_recursive p typ name in

        if actually_recursive then
          if is_type_polymorphic typ then
            (* Instead of directly generating the mono name from concrete type and
               expr, we substitute the poly type and use the substituted one. This
               helps with some closures *)
            let call =
              match parent_sub with
              | Some sub ->
                  let concrete = sub typ in
                  get_mono_name name ~closure:true ~poly:typ concrete
              | None -> get_mono_name name ~closure:true ~poly:typ expr.typ
            in
            (* We still need to use the un-monomorphized callname for marking recursion *)
            (p, Recursive { nonmono = name; call })
            (* Make the name concrete so the correct call name is used *)
          else (p, Recursive { nonmono = name; call = name })
            (* The inner function which is indirectly recursive closes over this
               one. Just get it from the env *)
        else (p, Default)
    | Mutual_rec (name, typ, upward) ->
        if is_type_polymorphic typ then (
          let call = get_mono_name name ~closure:true ~poly:typ expr.typ in
          if not (Sset.mem call p.monomorphized) then
            (* The function doesn't exist yet, will it ever exist? *)
            if not (Hashtbl.mem missing_polys_tbl call) then
              Hashtbl.add missing_polys_tbl name (p, expr.typ, parent_sub);
          (p, Mono (call, upward))
          (* Make the name concrete so the correct call name is used *))
        else (p, Concrete name)
    | _ when is_type_polymorphic expr.typ -> (p, Default)
    | Concrete (func, username, _) ->
        (* If a named function gets a generated name, the call site has to be made aware *)
        if not (String.equal func.name.call username) then
          (p, Concrete func.name.call)
        else (p, Default)
    | Polymorphic (call, _) ->
        let p, func = get_poly_func p call in
        let typ = typ_of_abs func.abs in
        monomorphize p typ expr.typ func parent_sub
    | No_function -> (p, Default)

  and get_poly_func p callname =
    match Hashtbl.find_opt poly_funcs_tbl callname with
    | Some func -> (p, func)
    | None -> (
        match Hashtbl.find_opt deferredfunc_tbl callname with
        | Some make_func ->
            (* Which param do we want to use? The original *)
            let np = make_func () in
            (* Should exist now *)
            let func = Hashtbl.find poly_funcs_tbl callname in
            let funcs = Fset.union np.funcs p.funcs
            and monomorphized = Sset.union np.monomorphized p.monomorphized in
            let p = { p with funcs; monomorphized } in
            (p, func)
        | None -> failwith "Internal Error: Poly function not registered yet")

  and monomorphize p typ concrete func parent_sub =
    let call = get_mono_name func.name.call ~closure:true ~poly:typ concrete in

    if Sset.mem call p.monomorphized then
      (* The function exists, we don't do anything right now *)
      (p, Mono (call, func.upward))
    else
      (* We generate the function *)
      (* The parent substitution is threaded through to its children. This deals
         with nested closures *)
      let subst, typ = subst_type ~concrete typ parent_sub in

      (* If the type is still polymorphic, we cannot generate it *)
      if is_type_polymorphic typ then (p, Default)
      else
        let p, body = subst_body p subst func.abs.body in

        let kind = subst_kind subst func.abs.func.kind in
        let fnc = { (func_of_typ typ) with kind } in
        let name = { func.name with call } in
        let abs = { func.abs with func = fnc; body } in
        let monomorphized = true in
        let funcs = Fset.add { func with abs; name; monomorphized } p.funcs in
        let monomorphized = Sset.add call p.monomorphized in
        ({ p with funcs; monomorphized }, Mono (call, func.upward))
end
