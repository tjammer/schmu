open Types
open Typed_tree

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

let rec occurs tvr = function
  | Tvar tvr' when tvr == tvr' -> failwith "Internal error: Occurs check failed"
  | Tvar ({ contents = Unbound (id, lvl') } as tv) ->
      let min_lvl =
        match !tvr with Unbound (_, lvl) -> min lvl lvl' | _ -> lvl'
      in
      tv := Unbound (id, min_lvl)
  | Tvar { contents = Link ty } | Talias (_, ty) -> occurs tvr ty
  | Tfun (param_ts, t, _) ->
      List.iter (fun p -> occurs tvr p.pt) param_ts;
      occurs tvr t
  | _ -> ()

let arity (loc, pre) thing la lb =
  let msg =
    Printf.sprintf "%s Wrong arity for %s: Expected %i but got %i" pre thing lb
      la
  in
  raise (Error (loc, msg))

exception Unify
exception Arity of string * int * int

let rec unify t1 t2 =
  if t1 == t2 then ()
  else
    match (t1, t2) with
    | Tvar { contents = Link t1 }, t2
    | t1, Tvar { contents = Link t2 }
    | Talias (_, t1), t2
    | t1, Talias (_, t2) ->
        unify t1 t2
    | Tvar ({ contents = Unbound _ } as tv), t
    | t, Tvar ({ contents = Unbound _ } as tv) ->
        occurs tv t;
        tv := Link t
    | Tfun (params_l, l, _), Tfun (params_r, r, _) -> (
        try
          List.iter2
            (fun left right ->
              if not (Bool.equal left.pmut right.pmut) then raise Unify;
              unify left.pt right.pt)
            params_l params_r;
          unify l r
        with Invalid_argument _ ->
          raise (Arity ("function", List.length params_l, List.length params_r))
        )
    | Trecord (_, None, labels1), Trecord (_, None, labels2) -> (
        try Array.iter2 (fun a b -> Types.(unify a.ftyp b.ftyp)) labels1 labels2
        with Invalid_argument _ ->
          raise (Arity ("tuple", Array.length labels1, Array.length labels2)))
    | Trecord (ps1, Some n1, labels1), Trecord (ps2, Some n2, labels2) ->
        if Path.equal n1 n2 then
          try
            List.iter2 unify ps1 ps2;
            (* We ignore the label names for now *)
            Array.iter2 (fun a b -> Types.(unify a.ftyp b.ftyp)) labels1 labels2
          with Invalid_argument _ ->
            raise (Arity ("record", Array.length labels1, Array.length labels2))
        else raise Unify
    | Tvariant (ps1, n1, ctors1), Tvariant (ps2, n2, ctors2) ->
        if Path.equal n1 n2 then
          try
            List.iter2 unify ps1 ps2;
            (* We ignore the ctor names for now *)
            Array.iter2
              (fun a b ->
                match (a.ctyp, b.ctyp) with
                | Some a, Some b -> unify a b
                | None, None -> ()
                | Some _, None | None, Some _ -> raise Unify)
              ctors1 ctors2
          with Invalid_argument _ -> raise Unify
        else raise Unify
    | Traw_ptr l, Traw_ptr r -> unify l r
    | Tarray l, Tarray r -> unify l r
    | Qvar a, Qvar b when String.equal a b ->
        (* We should not need this. Anyway *)
        ()
    | _ -> raise Unify

let unify info t1 t2 =
  try unify t1 t2 with
  | Unify ->
      let loc, pre = info in
      let msg =
        Printf.sprintf "%s Expected type %s but got type %s" pre
          (string_of_type t1) (string_of_type t2)
      in
      raise (Error (loc, msg))
  | Arity (thing, l1, l2) -> arity info thing l1 l2

let rec generalize = function
  | Tvar { contents = Unbound (id, l) } when l > !current_level -> Qvar id
  | Tvar ({ contents = Link t } as tv) ->
      tv := Link (generalize t);
      Tvar tv
  | Talias (n, t) -> Talias (n, generalize t)
  | Tfun (t1, t2, k) ->
      let gen p = { p with pt = generalize p.pt } in
      Tfun (List.map gen t1, generalize t2, k)
  | Trecord (ps, name, labels) ->
      (* Hopefully the param type is the same reference throughout the record *)
      let ps = List.map generalize ps in
      let f f = Types.{ f with ftyp = generalize f.ftyp } in
      let labels = Array.map f labels in
      Trecord (ps, name, labels)
  | Tvariant (ps, name, ctors) ->
      (* Hopefully the param type is the same reference throughout the variant *)
      let ps = List.map generalize ps in
      let f c = Types.{ c with ctyp = Option.map generalize c.ctyp } in
      let ctors = Array.map f ctors in
      Tvariant (ps, name, ctors)
  | Traw_ptr t -> Traw_ptr (generalize t)
  | Tarray t -> Tarray (generalize t)
  | t -> t

(* TODO sibling functions *)
let instantiate t =
  let rec aux subst = function
    | Qvar id -> (
        match Smap.find_opt id subst with
        | Some t -> (t, subst)
        | None ->
            let tv = newvar () in
            (tv, Smap.add id tv subst))
    | Tvar { contents = Link t } -> aux subst t
    | Talias (name, t) ->
        let t, subst = aux subst t in
        (Talias (name, t), subst)
    | Tfun (params_t, t, k) ->
        let subst, params_t =
          List.fold_left_map
            (fun subst param ->
              let pt, subst = aux subst param.pt in
              (subst, { param with pt }))
            subst params_t
        in
        let t, subst = aux subst t in
        (Tfun (params_t, t, k), subst)
    | Trecord (ps, name, labels) ->
        let subst = ref subst in
        let ps =
          List.map
            (fun t ->
              let t, subst' = aux !subst t in
              subst := subst';
              t)
            ps
        in
        let labels =
          Array.map
            (fun f ->
              let t, subst' = aux !subst Types.(f.ftyp) in
              subst := subst';
              { f with ftyp = t })
            labels
        in
        (Trecord (ps, name, labels), !subst)
    | Tvariant (ps, name, ctors) ->
        let subst = ref subst in
        let ps =
          List.map
            (fun t ->
              let t, subst' = aux !subst t in
              subst := subst';
              t)
            ps
        in
        let ctors =
          Array.map
            (fun ctor ->
              let ctyp =
                Option.map
                  (fun typ ->
                    let t, subst' = aux !subst typ in
                    subst := subst';
                    t)
                  ctor.ctyp
              in
              { ctor with ctyp })
            ctors
        in
        (Tvariant (ps, name, ctors), !subst)
    | Traw_ptr t ->
        let t, subst = aux subst t in
        (Traw_ptr t, subst)
    | Tarray t ->
        let t, subst = aux subst t in
        (Tarray t, subst)
    | t -> (t, subst)
  in
  aux Smap.empty t |> fst

let regeneralize typ =
  enter_level ();
  let typ = instantiate typ in
  leave_level ();
  let typ = generalize typ in
  typ

(* Checks if types match. [~strict] means Unbound vars will not match everything.
   This is true for functions where we want to be as general as possible.
   We need to match everything for weak vars though *)
let rec types_match ?(strict = false) subst l r =
  if l == r then (subst, true)
  else
    match (l, r) with
    | Tvar { contents = Unbound _ }, _ when not strict ->
        (* Unbound vars match every type *) (subst, true)
    | Qvar l, Qvar r | Tvar { contents = Unbound (l, _) }, Qvar r -> (
        (* We always map from left to right *)
        match Smap.find_opt l subst with
        | Some id when String.equal r id -> (subst, true)
        | Some _ -> (subst, false)
        | None ->
            (* We 'connect' left to right *)
            (Smap.add l r subst, true))
    | Tvar { contents = Link l }, r
    | l, Tvar { contents = Link r }
    | Talias (_, l), r
    | l, Talias (_, r) ->
        types_match ~strict subst l r
    | _, Tvar { contents = Unbound _ } ->
        failwith "Internal Error: Type comparison for non-generalized types"
    | Tfun (ps_l, l, _), Tfun (ps_r, r, _) -> (
        try
          let subst, acc =
            List.fold_left2
              (fun (s, acc) l r ->
                let subst, b = types_match ~strict:true s l.pt r.pt in
                let b = b && Bool.equal l.pmut r.pmut in
                (subst, acc && b))
              (subst, true) ps_l ps_r
          in
          (* We don't shortcut here to match the annotations for the error message *)
          let subst, b = types_match ~strict:true subst l r in
          (subst, acc && b)
        with Invalid_argument _ -> (subst, false))
    | Trecord (_, None, l), Trecord (_, None, r) -> (
        let l = Array.to_list l and r = Array.to_list r in
        try
          List.fold_left2
            (fun (s, acc) l r ->
              let subst, b = types_match s l.ftyp r.ftyp in
              (subst, acc && b))
            (subst, true) l r
        with Invalid_argument _ -> (subst, false))
    | Trecord (pl, Some nl, _), Trecord (pr, Some nr, _)
    | Tvariant (pl, nl, _), Tvariant (pr, nr, _) ->
        (* It should be enough to compare the name (rather, the name's repr)
           and the param type *)
        if Path.equal nl nr then
          List.fold_left2
            (fun (s, acc) l r ->
              let subst, b = types_match ~strict s l r in
              (subst, acc && b))
            (subst, true) pl pr
        else (subst, false)
    | Traw_ptr l, Traw_ptr r | Tarray l, Tarray r ->
        types_match ~strict subst l r
    | _ -> (subst, false)
