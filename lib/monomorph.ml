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

    let equal a b = String.equal a.name.call b.name.call
    let hash s = String.hash s.name.call
    let compare a b = String.compare a.name.call b.name.call
  end

  module Functbl = Hashtbl.Make (To_gen_func)
  module Sset = Set.Make (String)

  type upward = bool ref

  type to_gen_func_kind =
    (* TODO use a prefix *)
    | Concrete of To_gen_func.t * string * upward
    | Polymorphic of string * upward (* call name *)
    | Forward_decl of func_name * typ * upward
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

  (* Global tables *)
  let param_tbl : (string, morph_param) Hashtbl.t = Apptbl.create 512
  let missing_polys_tbl = Hashtbl.create 512
  let poly_funcs_tbl : (string, to_gen_func) Hashtbl.t = Hashtbl.create 512

  (* Keeps polymorphic function which haven't been traversed. We don't want to
     traverse everything up front *)
  let deferredfunc_tbl : (string, unit -> morph_param) Hashtbl.t =
    Hashtbl.create 512

  let polyschemes_tbl : (string, typ * Sset.t) Hashtbl.t = Hashtbl.create 512
  let monomorphed_tbl : (string, unit) Hashtbl.t = Hashtbl.create 512
  let generate_funcs_tbl : unit Functbl.t = Functbl.create 512

  let ty_name ty =
    let open Printf in
    let rec aux = function
      | Tint -> "l"
      | Tbool -> "b"
      | Tunit -> "u"
      | Tu8 | Ti8 -> "c"
      | Tu16 | Ti16 -> "s"
      | Tfloat -> "d"
      | Ti32 | Tu32 -> "i"
      | Tf32 -> "f"
      | Tpoly _ -> "g"
      | Tfun (ps, r, _) ->
          let ps = String.concat "" (List.map (fun p -> aux p.pt) ps) in
          let r = sprintf "r%s" (aux r) in
          sprintf "%s%s" ps r
      | Trecord (ps, _, Some n) | Tvariant (ps, _, n) -> (
          match ps with
          | [] -> n
          | ps -> sprintf "%s.%s" n (String.concat "" (List.map aux ps)))
      | Trecord (_, (Rec_not fs | Rec_top fs), None) ->
          "tp."
          ^ String.concat ""
              (Array.map (fun f -> aux f.ftyp) fs |> Array.to_list)
      | Trecord (_, Rec_folded, None) -> failwith "unreachable"
      | Traw_ptr t -> sprintf "p.%s" (aux t)
      | Tarray t -> sprintf "a.%s" (aux t)
      | Trc (Strong, t) -> sprintf "R.%s" (aux t)
      | Trc (Weak, t) -> sprintf "w.%s" (aux t)
      | Tfixed_array (i, t) -> sprintf "A%i.%s" i (aux t)
    in
    aux ty

  let rec subst_until_mono id subst =
    match Vars.find id subst with
    | Tpoly id -> subst_until_mono id subst
    | t -> t

  let construct_mono_name name scheme subst =
    if Sset.is_empty scheme then name
    else
      let suffix =
        Sset.fold
          (fun id acc ->
            let ty = subst_until_mono id subst in
            (match ty with Tpoly _ -> assert false | _ -> ());
            acc ^ ty_name ty)
          scheme ""
      in
      let name = name ^ "_" ^ suffix in
      if String.starts_with ~prefix:"__" name then name else "__" ^ name

  let collect_poly_params typ closed =
    let oftyp params t =
      let strings = extract_params t in
      List.fold_left (fun acc s -> Sset.add s acc) params strings
    in

    List.fold_left
      (fun params c ->
        match c.cltyp with
        | Tfun _ as t when c.clparam ->
            (* Params don't hove known closures *)
            oftyp params t
        | Tfun _ ->
            (* Get it from our polyschemes tbl *)
            Sset.union params (Hashtbl.find polyschemes_tbl c.clname |> snd)
        | t -> oftyp params t)
      (oftyp Sset.empty typ) closed

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

  let is_actually_recursive p typ name =
    let rec aux first stack =
      match (stack, typ) with
      | (call, _) :: _, _ when String.equal call name -> Some first
      | _ :: tail, Tfun (_, _, Closure) ->
          (* We are not actually recursive but in an inner function. Generate a
             non-recursive call *)
          aux false tail
      | _ when first -> Some first
      | _ -> None
    in
    aux true p.recursion_stack

  let subst_ty subst ty =
    let rec aux = function
      | Tpoly id ->
          (* subst was built from polyschemes, everything can be substituted *)
          subst_until_mono id subst
      | Tfun (ps, r, k) ->
          Tfun (List.map (fun p -> { p with pt = aux p.pt }) ps, aux r, k)
      | Trecord (ps, ((Rec_not l | Rec_top l) as kind), record) ->
          let l = Array.map (fun l -> { l with ftyp = aux l.ftyp }) l in
          let ps = List.map aux ps in
          let kind =
            match kind with
            | Rec_not _ -> Rec_not l
            | Rec_top _ -> Rec_top l
            | Rec_folded -> failwith "unreachable"
          in
          Trecord (ps, kind, record)
      | Trecord (ps, Rec_folded, record) ->
          Trecord (List.map aux ps, Rec_folded, record)
      | Tvariant (ps, ((Rec_not cs | Rec_top cs) as kind), variant) ->
          let cs =
            Array.map (fun cs -> { cs with ctyp = Option.map aux cs.ctyp }) cs
          in
          let ps = List.map aux ps in
          let kind =
            match kind with
            | Rec_not _ -> Rec_not cs
            | Rec_top _ -> Rec_top cs
            | Rec_folded -> failwith "unreachable"
          in
          Tvariant (ps, kind, variant)
      | Tvariant (ps, Rec_folded, variant) ->
          Tvariant (List.map aux ps, Rec_folded, variant)
      | Traw_ptr t -> Traw_ptr (aux t)
      | Tarray t -> Tarray (aux t)
      | Trc (k, t) -> Trc (k, aux t)
      | Tfixed_array (i, t) ->
          let i =
            if i < 0 then
              let id = "fa" ^ string_of_int i in
              match Vars.find id subst with
              | Tfixed_array (i, _) -> i
              | _ -> failwith "Internal Error: What else? in subst"
            else i
          in
          Tfixed_array (i, aux t)
      | ( Tint | Tbool | Tunit | Ti8 | Tu8 | Ti16 | Tu16 | Tfloat | Ti32 | Tu32
        | Tf32 ) as t ->
          t
    in
    aux ty

  let build_subst ~poly ~typ =
    let rec inner subst = function
      | Tpoly id, t -> (
          match Vars.find_opt id subst with
          | Some _ -> (* Already in subst *) subst
          | None -> Vars.add id t subst)
      | Tfun (ps1, r1, _), Tfun (ps2, r2, _) ->
          let subst =
            List.fold_left
              (fun subst (l, r) ->
                let s = inner subst (l.pt, r.pt) in
                s)
              subst (List.combine ps1 ps2)
          in
          let subst = inner subst (r1, r2) in
          subst
      | ( Trecord (i, (Rec_not l1 | Rec_top l1), _),
          Trecord (j, (Rec_not l2 | Rec_top l2), _) ) ->
          let f (subst, i) (label : Cleaned_types.field) =
            let subst = inner subst (label.ftyp, l2.(i).ftyp) in
            (subst, i + 1)
          in
          let subst, _ = Array.fold_left f (subst, 0) l1 in
          let subst =
            List.fold_left
              (fun subst (l, r) -> inner subst (l, r))
              subst (List.combine i j)
          in
          subst
      | Trecord (i, Rec_folded, _), Trecord (j, Rec_folded, _) ->
          let subst =
            List.fold_left
              (fun subst (l, r) -> inner subst (l, r))
              subst (List.combine i j)
          in
          subst
      | ( Tvariant (i, (Rec_not l1 | Rec_top l1), _),
          Tvariant (j, (Rec_not l2 | Rec_top l2), _) ) ->
          let f (subst, i) (ctor : Cleaned_types.ctor) =
            let subst =
              match (ctor.ctyp, l2.(i).ctyp) with
              | Some l, Some r ->
                  let subst = (inner subst) (l, r) in
                  subst
              | _ -> subst
            in
            (subst, i + 1)
          in
          let subst, _ = Array.fold_left f (subst, 0) l1 in
          let subst =
            List.fold_left
              (fun subst (l, r) -> inner subst (l, r))
              subst (List.combine i j)
          in
          subst
      | Tvariant (i, Rec_folded, _), Tvariant (j, Rec_folded, _) ->
          let subst =
            List.fold_left
              (fun subst (l, r) -> inner subst (l, r))
              subst (List.combine i j)
          in
          subst
      | Traw_ptr l, Traw_ptr r ->
          let subst = inner subst (l, r) in
          subst
      | Tarray l, Tarray r ->
          let subst = inner subst (l, r) in
          subst
      | Trc (kl, l), Trc (kr, r) when kl = kr ->
          let subst = inner subst (l, r) in
          subst
      | Tfixed_array (i, l), Tfixed_array (j, r) ->
          let subst =
            if i < 0 then
              let id = "fa" ^ string_of_int i in
              match Vars.find_opt id subst with
              | Some (Tfixed_array _) -> subst
              | Some _ -> failwith "Internal Error: What else? in monomorph"
              | None ->
                  let t = Tfixed_array (j, Tunit) in
                  Vars.add id t subst
            else subst
          in
          let subst = inner subst (l, r) in
          subst
      | _, _ -> subst
    in
    inner Vars.empty (poly, typ)

  let subst_scheme scheme subst =
    Sset.filter
      (fun id ->
        match Vars.find_opt id subst with
        | Some t -> (
            (* Ensure our substituted type is not polymorphic itself *)
            match extract_params t with
            | [] ->
                (* We throw out every concrete type *)
                false
            | _ -> true)
        | None ->
            (* Cannot find substitute for this parameter, don't filter *)
            true)
      scheme

  let merge_subst subst child_subst =
    Vars.merge
      (fun _ l r ->
        match (l, r) with
        | Some _, None -> l
        | None, Some _ -> r
        | None, None -> None
        | Some l, Some r ->
            let t =
              match (l, r) with
              | Tpoly _, Tpoly _ -> (* Prefer child? *) r
              | Tpoly _, t -> t
              | t, Tpoly _ -> t
              | l, r ->
                  assert (String.equal (string_of_type l) (string_of_type r));
                  r
            in
            Some t)
      subst child_subst

  let subst_closed subst cls =
    List.fold_left_map
      (fun subst cl ->
        let is_function = match cl.cltyp with Tfun _ -> true | _ -> false in
        let subst, clname =
          if is_function && not cl.clparam then
            let poly, scheme = Hashtbl.find polyschemes_tbl cl.clname in
            if Sset.is_empty scheme then (subst, cl.clname)
            else
              (* For some reason, the cltyp can be more specific than the type
                 scheme. To deal with this, we enrich out subst with the one from
                 the poly scheme and return it for subsequent substitutions to be
                 used. *)
              let child_subst = build_subst ~poly ~typ:cl.cltyp in
              let subst = merge_subst subst child_subst in
              (subst, construct_mono_name cl.clname scheme subst)
          else (subst, cl.clname)
        in
        let cltyp = subst_ty subst cl.cltyp in
        (subst, { cl with cltyp; clname }))
      subst cls

  let get_poly_func callname =
    match Hashtbl.find_opt poly_funcs_tbl callname with
    | Some func -> func
    | None -> (
        match Hashtbl.find_opt deferredfunc_tbl callname with
        | Some make_func ->
            (* Which param do we want to use? The original *)
            let _ = make_func () in
            (* Should exist now *)
            let func = Hashtbl.find poly_funcs_tbl callname in
            func
        | None -> failwith "Internal Error: Poly function not registered yet")

  let func_of_typ closed = function
    | Tfun (params, ret, Simple) -> { params; ret; closed = [] }
    | Tfun (params, ret, Closure) -> { params; ret; closed }
    | _ -> failwith "Internal Error: Not a function type"

  let rec monomorph_call p expr subst : call_name =
    match find_function_expr p.vars expr.expr with
    | Builtin b -> Builtin (b, func_of_typ [] expr.typ)
    | Inline _ -> failwith "unused"
    | Forward_decl (name, typ, _) -> (
        (* Generate the correct call name. If its mono, we have to recalculate it.
           Closures are tricky, as the arguments are generally not closures, but
           the typ might. We try to subst the (potential) closure by using the
           subst if its available. *)
        match is_actually_recursive p typ name.call with
        | Some true ->
            let scheme = Hashtbl.find polyschemes_tbl name.call |> snd in
            if Sset.is_empty scheme then
              (* Not monomorphized, use callname *)
              Recursive { nonmono = name.call; call = name.call }
            else
              let call = construct_mono_name name.call scheme subst in
              Recursive { nonmono = name.call; call }
        | Some false ->
            let scheme = Hashtbl.find polyschemes_tbl name.call |> snd in
            let call = construct_mono_name name.call scheme subst in
            Mono (call, ref false)
        | None ->
            (* The inner function which is indirectly recursive closes over this
               one. Just get it from the env *)
            failwith "still" (* Default *))
    | Mutual_rec (callname, _, upward) ->
        (* Is the scheme forward-declared as well? Probably not. Fix this later *)
        let poly, scheme = Hashtbl.find polyschemes_tbl callname in
        if Sset.is_empty scheme then Concrete callname
        else
          (* Treat it like a poly func, only with deferred function
             generation *)
          let child_subst = build_subst ~poly ~typ:expr.typ in
          let subst = merge_subst subst child_subst in
          (* The function doesn't exist yet, will it ever exist? *)
          if not (Hashtbl.mem missing_polys_tbl callname) then
            Hashtbl.add missing_polys_tbl callname (p, subst);
          let call = construct_mono_name callname scheme subst in
          Mono (call, upward)
    | Concrete (func, _username, _) -> Concrete func.name.call
    | Polymorphic (callname, _) ->
        (* Our subst is formulated in terms of the parent call in
           monomorphize_call. Build a new subst for this call (using the
           concrete type) and merge it with the parent subst *)
        let poly = Hashtbl.find polyschemes_tbl callname |> fst in
        let child_subst = build_subst ~poly ~typ:expr.typ in
        let subst = merge_subst subst child_subst in
        let func = get_poly_func callname in
        do_monomorphize p func subst
    | No_function -> Default

  and do_monomorphize p func subst =
    let typ, scheme = Hashtbl.find polyschemes_tbl func.name.call in
    let callname = construct_mono_name func.name.call scheme subst in

    if Hashtbl.mem monomorphed_tbl callname then Mono (callname, func.upward)
    else
      let typ = subst_ty subst typ in

      let subst, closed = subst_closed subst func.abs.func.closed in
      let body = subst_body p subst func.abs.body in
      let fnc = { (func_of_typ closed typ) with closed } in
      let name = { func.name with call = callname } in
      let abs = { func.abs with func = fnc; body } in
      let monomorphized = true in
      Functbl.add generate_funcs_tbl { func with abs; name; monomorphized } ();
      Hashtbl.add monomorphed_tbl callname ();
      Mono (callname, func.upward)

  and subst_body p subst body =
    let rec aux tree =
      let t = { tree with typ = subst_ty subst tree.typ } in
      match tree.expr with
      | Mvar (_, _, None) -> t
      | Mvar (id, _, Some mid) as var ->
          (* TODO here check the type *)
          let old_p =
            match Hashtbl.find_opt param_tbl (string_of_int mid) with
            | Some p -> p
            | None -> failwith "Internal Error: No old param"
          in
          let expr =
            match monomorph_call old_p t subst with
            | Default | Builtin _ | Inline _ -> var
            | Concrete name -> Mvar (name, Vnorm, None)
            | Recursive r -> Mvar (id, Vrecursive r.call, Some mid)
            | Mono (name, upward) -> Mvar (name, Vmono !upward, None)
          in
          { t with expr }
      | Mconst (Array (es, a, i)) ->
          { t with expr = Mconst (Array (List.map aux es, a, i)) }
      | Mconst (Fixed_array (es, a, i)) ->
          { t with expr = Mconst (Fixed_array (List.map aux es, a, i)) }
      | Mconst _ -> t
      | Mbop (bop, l, r) -> { t with expr = Mbop (bop, aux l, aux r) }
      | Munop (unop, e) -> { t with expr = Munop (unop, aux e) }
      | Mif expr ->
          let cond = aux expr.cond in
          let e1 = aux expr.e1 in
          let e2 = aux expr.e2 in
          { t with expr = Mif { expr with cond; e1; e2 } }
      | Mlet (id, expr, proj, gn, vid, cont) ->
          let expr = aux expr in
          let cont = aux cont in
          { t with expr = Mlet (id, expr, proj, gn, vid, cont) }
      | Mbind (id, lhs, cont) ->
          let lhs = aux lhs in
          let cont = aux cont in
          { t with expr = Mbind (id, lhs, cont) }
      | Mlambda (name, closed, typ, alloca, upward) ->
          let typ = subst_ty subst typ
          and subst, closed = subst_closed subst closed in
          (* We may have to monomorphize. For instance if the lambda returned from
               a polymorphic function *)
          let old_p =
            match Hashtbl.find_opt param_tbl name with
            | Some p -> p
            | None -> failwith "Internal Error: No param in lambda"
          in
          let name =
            match monomorph_call old_p t subst with
            | Mono (name, _) -> name
            | Concrete name -> name
            | _ -> name
          in
          { t with expr = Mlambda (name, closed, typ, alloca, upward) }
      | Mfunction (name, closed, typ, cont, alloca, upward) ->
          (* This function can define its own poly types which are not capture
             by subst. In this case, we don't do anything and wait for it to be
             called with a concrete type. *)
          let scheme = Hashtbl.find polyschemes_tbl name |> snd in

          if Sset.is_empty scheme then
            (* This function is monomorphic, no need to do anything *)
            let cont = aux cont in
            {
              t with
              expr = Mfunction (name, closed, typ, cont, alloca, upward);
            }
          else
            (* Check if we can monomorphize with current subst *)
            let subst_scheme = subst_scheme scheme subst in
            if Sset.is_empty subst_scheme then
              let typ = subst_ty subst typ
              and subst, closed = subst_closed subst closed in
              (* Treat it as a poly func *)
              let func = get_poly_func name in

              let name =
                match do_monomorphize p func subst with
                | Mono (call, _) -> call
                | Concrete name -> name
                | _ -> failwith "Internal Error: What else"
              in
              let cont = aux cont in
              {
                t with
                expr = Mfunction (name, closed, typ, cont, alloca, upward);
              }
            else
              (* Return as is *)
              let cont = aux cont in
              {
                t with
                expr = Mfunction (name, closed, typ, cont, alloca, upward);
              }
      | Mapp { callee; args; alloca; id; ms } ->
          (* TODO there's room for saving here. Maybe the call is already mono? *)
          let ex = aux callee.ex in

          let old_p =
            match Hashtbl.find_opt param_tbl (string_of_int id) with
            | Some p -> p
            | None ->
                print_endline (show_expr callee.ex.expr);
                failwith "Internal Error: No param in function"
          in

          let monomorph = monomorph_call old_p ex subst in
          let callee = { callee with ex; monomorph } in

          let args =
            List.map
              (fun (arg, a) ->
                let ex = aux arg.ex in

                let monomorph = monomorph_call old_p ex subst in
                ({ arg with ex; monomorph }, a))
              args
          in
          { t with expr = Mapp { callee; args; alloca; id; ms } }
      | Mrecord (labels, alloca, id) ->
          let labels = List.map (fun (name, expr) -> (name, aux expr)) labels in
          { t with expr = Mrecord (labels, alloca, id) }
      | Mctor ((var, index, expr), alloca, id) ->
          let expr = Mctor ((var, index, Option.map aux expr), alloca, id) in
          { t with expr }
      | Mfield (expr, index) -> { t with expr = Mfield (aux expr, index) }
      | Mvar_index expr -> { t with expr = Mvar_index (aux expr) }
      | Mvar_data (expr, mid) -> { t with expr = Mvar_data (aux expr, mid) }
      | Mset (expr, value, moved) ->
          { t with expr = Mset (aux expr, aux value, moved) }
      | Mseq (expr, cont) -> { t with expr = Mseq (aux expr, aux cont) }
      | Mfree_after (expr, fs) -> { t with expr = Mfree_after (aux expr, fs) }
    in

    aux body

  (* This is the entry point from monomorph_tree *)
  let monomorphize_call p ex =
    (* find callname, inlined from extract_callname *)
    let callname =
      match find_function_expr p.vars ex.expr with
      | Builtin b -> Some (`Builtin (b, func_of_typ [] ex.typ))
      | Inline _ -> None
      | No_function -> None
      | Mutual_rec (name, _, _) ->
          (* Might not really be poly, but that's checked in the poly case
             below. Will become concrete or poly. *)
          Some (`Poly name)
      | Forward_decl (name, typ, _) -> (
          (* Indirectly recursive functions live in the closure env *)
          match is_actually_recursive p typ name.call with
          | Some true -> Some (`Recursive name.call)
          | Some false -> Some (`Poly name.call)
          | None -> None)
      | Polymorphic (call, _) -> Some (`Poly call)
      | Concrete (func, _, _) -> Some (`Concrete func.name.call)
    in
    match callname with
    | None -> Default
    | Some (`Concrete callname) -> Concrete callname
    | Some (`Builtin (b, f)) -> Builtin (b, f)
    | Some ((`Poly callname | `Recursive callname) as kind) -> (
        let poly, scheme = Hashtbl.find polyschemes_tbl callname in
        match kind with
        | `Poly _ when Sset.is_empty scheme ->
            (* For our second case in recursive above we don't
               know if the poly is actually polymorphic. Could
               be monomorphic as well*)
            Concrete callname
        | _ -> (
            let subst =
              (* Compare type of expression with polymorphic type  *)
              build_subst ~poly ~typ:ex.typ
            in
            let subst_scheme = subst_scheme scheme subst in
            if Sset.is_empty subst_scheme then
              (* We found a concrete type, monomorph the body *)
              monomorph_call p ex subst
            else
              match kind with
              | `Recursive _ ->
                  (* We have to set Recursive for recursive calls even though it
                     could be that the correct monomorphized callname is not yet
                     available. Still, it's used for marking tail recursion. *)
                  Recursive { nonmono = callname; call = callname }
              | _ -> Default))
end
