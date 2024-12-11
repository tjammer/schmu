open Types
open Error

type err = Ast.loc * string

let gensym_state = ref 0

let gensym () =
  let n = !gensym_state in
  incr gensym_state;
  string_of_int n

let current_level = ref 1
let reset_level () = current_level := 1
let enter_level () = incr current_level
let leave_level () = decr current_level
let newvar () = Tvar (ref (Unbound (gensym (), !current_level)))

let reset () =
  gensym_state := 0;
  reset_level ()

exception Occurs

let rec occurs tvr = function
  | Tvar tvr' when tvr == tvr' -> raise Occurs
  | Tvar ({ contents = Unbound (id, lvl') } as tv) ->
      let min_lvl =
        match !tvr with Unbound (_, lvl) -> min lvl lvl' | _ -> lvl'
      in
      tv := Unbound (id, min_lvl)
  | Tvar { contents = Link ty } -> occurs tvr ty
  | Tfun (param_ts, t, _) ->
      List.iter (fun p -> occurs tvr p.pt) param_ts;
      occurs tvr t
  | Tconstr (_, ts) | Ttuple ts -> List.iter (occurs tvr) ts
  | Tfixed_array (({ contents = Unknown (id, lvl) } as tv), t) ->
      (* Also adjust level of array size *)
      let min_lvl = match !tvr with Unbound (_, l) -> min lvl l | _ -> lvl in
      tv := Unknown (id, min_lvl);
      occurs tvr t
  | Tfixed_array (_, t) -> occurs tvr t
  | _ -> ()

exception Unify

let rec unify recurs t1 t2 =
  if t1 == t2 then ()
  else
    match (repr t1, repr t2) with
    | ( Tvar ({ contents = Unbound _ } as tv1),
        Tvar ({ contents = Unbound _ } as tv2) )
      when tv1 == tv2 ->
        ()
    | Tvar ({ contents = Unbound _ } as tv), t
    | t, Tvar ({ contents = Unbound _ } as tv) ->
        occurs tv t;
        tv := Link t
    | Tfun (params_l, l, _), Tfun (params_r, r, _) -> (
        try
          let attr_mismatch = ref false in
          unify recurs l r;
          List.iter2
            (fun left right ->
              (* Continue with unification to generate better type errors *)
              if not (left.pattr = right.pattr) then attr_mismatch := true;
              unify recurs left.pt right.pt)
            params_l params_r;
          if !attr_mismatch then raise Unify
        with Invalid_argument _ -> raise Unify)
    | Ttuple ls, Ttuple rs -> (
        try List.iter2 (unify recurs) ls rs
        with Invalid_argument _ -> raise Unify)
    | Tconstr (ln, ls), Tconstr (rn, rs) ->
        if Path.equal ln rn then
          try List.iter2 (unify recurs) ls rs
          with Invalid_argument _ -> raise Unify
        else raise Unify
    | Tfixed_array ({ contents = Linked l }, lt), (Tfixed_array _ as r) ->
        unify recurs (Tfixed_array (l, lt)) r
    | (Tfixed_array _ as l), Tfixed_array ({ contents = Linked r }, rt) ->
        unify recurs l (Tfixed_array (r, rt))
    | ( Tfixed_array (({ contents = Unknown (id, li) } as tv), l),
        Tfixed_array (other, r) )
    | ( Tfixed_array (other, l),
        Tfixed_array (({ contents = Unknown (id, li) } as tv), r) ) ->
        (* We need to find the minimum level, like in the occurs check *)
        (if not (other == tv) then
           match !other with
           | Unknown (_, lvl) -> other := Unknown (id, min lvl li)
           | _ ->
               ();
               tv := Linked other);
        unify recurs l r
    | ( Tfixed_array ({ contents = Known li }, l),
        Tfixed_array ({ contents = Known ri }, r) ) ->
        unify recurs l r;
        if not (Int.equal li ri) then raise Unify
    | Tfixed_array (li, l), Tfixed_array (ri, r) when li == ri ->
        unify recurs l r
    | l, r when l == r -> ()
    | _ -> raise Unify

let unify info t1 t2 env =
  let mn = Env.modpath env in
  let loc, pre = info in
  try unify Sset.empty t1 t2 with
  | Unify ->
      let msg = Error.format_type_err pre mn t1 t2 in
      raise (Error (loc, msg))
  | Occurs ->
      let msg = "Recursive types are not supported right now" in
      raise (Error (loc, msg))

let rec generalize = function
  | Tvar { contents = Unbound (id, l) } when l > !current_level -> Qvar id
  | Tvar { contents = Link t } -> generalize t
  | Tfun (t1, t2, k) ->
      let gen p = { p with pt = generalize p.pt } in
      Tfun (List.map gen t1, generalize t2, generalize_closure k)
  | Ttuple ts -> Ttuple (List.map generalize ts)
  | Tconstr (p, ps) -> Tconstr (p, List.map generalize ps)
  | Tfixed_array (({ contents = Unknown (id, li) } as tv), l)
    when li > !current_level ->
      tv := Generalized id;
      Tfixed_array (tv, generalize l)
  | Tfixed_array ({ contents = Linked l }, t) ->
      generalize (Tfixed_array (l, t))
  | Tfixed_array (i, t) -> Tfixed_array (i, generalize t)
  | t -> t

and generalize_closure = function
  | Simple -> Simple
  | Closure cls ->
      Closure (List.map (fun c -> { c with cltyp = generalize c.cltyp }) cls)

let rec inst_impl subst = function
  | Qvar id -> (
      match Smap.find_opt id subst with
      | Some t -> (subst, t)
      | None ->
          let tv = newvar () in
          (Smap.add id tv subst, tv))
  | Tvar { contents = Link t } -> inst_impl subst t
  | Ttuple ts ->
      let subst, ts = List.fold_left_map inst_impl subst ts in
      (subst, Ttuple ts)
  | Tconstr (p, ps) ->
      let subst, ps = List.fold_left_map inst_impl subst ps in
      (subst, Tconstr (p, ps))
  | Tfun (params_t, t, k) ->
      let subst, params_t =
        List.fold_left_map
          (fun subst param ->
            let subst, pt = inst_impl subst param.pt in
            (subst, { param with pt }))
          subst params_t
      in
      let subst, t = inst_impl subst t in
      let subst, k =
        match k with
        | Simple -> (subst, k)
        | Closure cls ->
            let subst, cls =
              List.fold_left_map
                (fun s c ->
                  let subst, cltyp = inst_impl s c.cltyp in
                  (subst, { c with cltyp }))
                subst cls
            in
            (subst, Closure cls)
      in
      (subst, Tfun (params_t, t, k))
  | Tfixed_array ({ contents = Generalized id }, t) -> (
      let subst, t = inst_impl subst t in
      match Smap.find_opt ("fa" ^ id) subst with
      | Some (Tfixed_array (i, _)) -> (subst, Tfixed_array (i, t))
      | Some _ -> failwith "Internal Error: What else?"
      | None ->
          let t = Tfixed_array (ref (Unknown (gensym (), !current_level)), t) in
          (Smap.add ("fa" ^ id) t subst, t))
  | Tfixed_array ({ contents = Linked l }, t) ->
      inst_impl subst (Tfixed_array (l, t))
  | Tfixed_array (i, t) ->
      let subst, t = inst_impl subst t in
      (subst, Tfixed_array (i, t))
  | t -> (subst, t)

let instantiate t = inst_impl Smap.empty t |> snd
let instantiate_sub sub t = inst_impl sub t

let regeneralize typ =
  enter_level ();
  let typ = instantiate typ in
  leave_level ();
  let typ = generalize typ in
  typ

module Pmap = Map.Make (Path)

(* Checks if types match. [~strict] means Unbound vars will not match everything.
   This is true for functions where we want to be as general as possible.
   We need to match everything for weak vars though *)
let types_match ?(abstracts_map = Pmap.empty) l r =
  let revmap = ref Smap.empty in
  let rec aux ~strict ~in_ps sub l r =
    if l == r then (r, sub, true)
    else
      match (l, r) with
      | ( Tvar { contents = Unbound (lid, _) },
          Tvar { contents = Unbound (rid, _) } )
      | Qvar lid, Qvar rid
      | Tvar { contents = Unbound (lid, _) }, Qvar rid -> (
          (* We always map from left to right *)
          match Smap.find_opt lid sub with
          | Some id when String.equal rid id -> (l, sub, true)
          | Some _ -> (l, sub, false)
          | None ->
              revmap := Smap.add rid l !revmap;
              (* We 'connect' left to right *)
              (l, Smap.add lid rid sub, true))
      | Tvar { contents = Unbound _ }, _ when not strict ->
          (* Unbound vars match every type *) (r, sub, true)
      | Tvar { contents = Link l }, r | l, Tvar { contents = Link r } ->
          aux ~strict ~in_ps sub l r
      | Tconstr (_, [ _ ]), Qvar q when in_ps -> (
          (* This case is allowed, but only if we don't violate matches we've
             seen before. See [test_signature_deep_qvar_sg] and
             [test_signature_dont_match_qvar] *)
          match Smap.find_opt q !revmap with
          | Some t ->
            (* Don't trigger this case again through [in_ps]. We want to see if
               the types really match. *)
            aux ~strict ~in_ps:false sub l t
          | None ->
              revmap := Smap.add q l !revmap;
              (l, sub, true))
      | Tconstr (pl, psl), Tconstr (pr, psr) when Path.equal pl pr ->
          let sub, mtch, revps =
            try
              List.fold_left2
                (fun (sub, mtch, ps) l r ->
                  let typ, sub, do_match = aux ~strict ~in_ps:true sub l r in
                  (sub, do_match && mtch, typ :: ps))
                (sub, true, []) psl psr
            with Invalid_argument _ -> (sub, false, List.rev psr)
          in
          (Tconstr (pl, List.rev revps), sub, mtch)
      | ( Tfixed_array (({ contents = Generalized lg } as rl), lt),
          Tfixed_array (({ contents = Generalized ri } as rr), rt) )
      | ( Tfixed_array (({ contents = Unknown (lg, _) } as rl), lt),
          Tfixed_array (({ contents = Generalized ri } as rr), rt) ) ->
          (* TODO check for same generalized things. Would be nice if something
             could be generalized. Prepend with fa for fixed array so not clash
             with Qvar strings *)
          let i, sub, pre = aux_sizes sub rl rr lg ri in
          if pre then
            let t, s, b = aux ~strict ~in_ps sub lt rt in
            (Tfixed_array (i, t), s, b)
          else (r, sub, false)
      | Tfixed_array ({ contents = Linked l }, lt), r ->
          aux ~strict ~in_ps sub (Tfixed_array (l, lt)) r
      | l, Tfixed_array ({ contents = Linked r }, rt) ->
          aux ~strict ~in_ps sub l (Tfixed_array (r, rt))
      | ( Tfixed_array ({ contents = Known ls }, lt),
          Tfixed_array (({ contents = Known rs } as i), rt) ) ->
          let t, sub, b = aux ~strict ~in_ps sub lt rt in
          (Tfixed_array (i, t), sub, b && Int.equal ls rs)
      | Ttuple ls, Ttuple rs ->
          let ts, sub, mtch =
            try
              List.fold_left2
                (fun (ts, sub, mtch) l r ->
                  let t, sub, b = aux ~strict ~in_ps sub l r in
                  (t :: ts, sub, mtch && b))
                ([], sub, true) ls rs
            with Invalid_argument _ -> (List.rev rs, sub, false)
          in
          (Ttuple (List.rev ts), sub, mtch)
      | Tfun (ps_l, l, _), Tfun (ps_r, r, kind) -> (
          try
            let ps, sub, acc =
              List.fold_left2
                (fun (ts, s, acc) pl pr ->
                  let pt, sub, b = aux ~strict:true ~in_ps s pl.pt pr.pt in
                  let b = b && pl.pattr = pr.pattr in
                  ({ pr with pt } :: ts, sub, acc && b))
                ([], sub, true) ps_l ps_r
            in
            let ps = List.rev ps in
            (* We don't shortcut here to match the annotations for the error message *)
            let ret, sub, b = aux ~strict:true ~in_ps sub l r in
            (Tfun (ps, ret, kind), sub, acc && b)
          with Invalid_argument _ -> (r, sub, false))
      | Tconstr (name, ps), r -> (
          match Pmap.find_opt name abstracts_map with
          | Some (Tconstr (n, _)) when Path.equal name n ->
              (* Guard for recursion *)
              (r, sub, false)
          | Some typ ->
              let typ, _ = transfer_params ps typ r in
              let _, _, b = aux ~strict ~in_ps sub typ r in
              if b then
                (* Use the abstract type here for interfaces *)
                (l, sub, b)
              else (r, sub, false)
          | None -> (r, sub, false))
      | _, _ -> (r, sub, false)
  and aux_sizes sub refl refr l r =
    if refl == refr then (refr, sub, true)
    else
      let sub, pre =
        match Smap.find_opt ("fa" ^ l) sub with
        | Some id when String.equal ("fa" ^ r) id -> (sub, true)
        | Some _ -> (sub, false)
        | None -> (Smap.add ("fa" ^ l) ("fa" ^ r) sub, true)
      in
      (refr, sub, pre)
  and transfer_params ops l r =
    (* This might break down on types with multiple params. For now it works *)
    match (l, r) with
    | Tconstr (pl, psl), Tconstr (pr, psr) when Path.equal pl pr ->
        let revps, ops =
          try
            List.fold_left2
              (fun (ps, ops) l r ->
                let typ, ops = transfer_params ops l r in
                (typ :: ps, ops))
              ([], ops) psl psr
          with Invalid_argument _ -> (List.rev psr, ops)
        in
        (Tconstr (pl, List.rev revps), ops)
    | Qvar _, _ -> ( match ops with t :: tl -> (t, tl) | [] -> (r, []))
    | l, _ ->
        (* If we don't enconter a Qvar, don't transfer *)
        (l, ops)
  and subst_closure = function
    | Simple -> Simple
    | Closure cls ->
        let cls =
          List.map
            (fun cl ->
              let cltyp = subst cl.cltyp in
              { cl with cltyp })
            cls
        in
        Closure cls
  and subst = function
    (* Substitute generic var [id] with [typ] *)
    | Tvar { contents = Link t } -> subst t
    | (Qvar id | Tvar { contents = Unbound (id, _) }) as t -> (
        match Smap.find_opt id !revmap with Some t -> t | None -> t)
    | Tfun (ps, ret, kind) ->
        let ps =
          List.map
            (fun p ->
              let pt = subst p.pt in
              { p with pt })
            ps
        in
        let ret = subst ret in
        let kind = subst_closure kind in
        Tfun (ps, ret, kind)
    | Ttuple ts -> Ttuple (List.map subst ts)
    | Tconstr (name, ps) ->
        let ps = List.map subst ps in
        Tconstr (name, ps)
    | Tfixed_array (i, t) -> Tfixed_array (i, subst t)
  in

  let typ, sub, b = aux Smap.empty ~strict:false ~in_ps:true l r in
  (* Wait until all substitutions are known, then substitute the type again.
     Needed for closures, because the signature type does not have a closure to
     substitute against. *)
  (subst typ, sub, b)
