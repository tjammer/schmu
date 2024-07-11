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
  | Traw_ptr t | Tarray t | Trc t -> occurs tvr t
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
    | Traw_ptr l, Traw_ptr r -> unify recurs l r
    | Tarray l, Tarray r -> unify recurs l r
    | Trc l, Trc r -> unify recurs l r
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
    | Tprim l, Tprim r when l == r -> ()
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
  | Traw_ptr t -> Traw_ptr (generalize t)
  | Tarray t -> Tarray (generalize t)
  | Trc t -> Trc (generalize t)
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
  | Traw_ptr t ->
      let subst, t = inst_impl subst t in
      (subst, Traw_ptr t)
  | Tarray t ->
      let subst, t = inst_impl subst t in
      (subst, Tarray t)
  | Trc t ->
      let subst, t = inst_impl subst t in
      (subst, Trc t)
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

module Nameset = Set.Make (Path)

(* Checks if types match. [~strict] means Unbound vars will not match everything.
   This is true for functions where we want to be as general as possible.
   We need to match everything for weak vars though *)
let types_match ~in_functor l r =
  ignore in_functor;
  ignore r;
  (l, Smap.empty, true)

and match_type_params ~in_functor params typ =
  ignore in_functor;
  ignore params;
  ignore typ;
  Result.Error "TODO"
