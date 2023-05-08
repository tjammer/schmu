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
  | Trecord (ps, _, fs) ->
      List.iter (occurs tvr) ps;
      Array.iter (fun f -> occurs tvr f.ftyp) fs
  | Tvariant (ps, _, cs) ->
      List.iter (occurs tvr) ps;
      Array.iter
        (fun c -> match c.ctyp with None -> () | Some t -> occurs tvr t)
        cs
  | Tabstract (ps, _, t) ->
      List.iter (occurs tvr) ps;
      occurs tvr t
  | Traw_ptr t | Tarray t -> occurs tvr t
  | _ -> ()

let arity (loc, pre) thing la lb =
  let msg =
    Printf.sprintf "%s Wrong arity for %s: Expected %i but got %i" pre thing lb
      la
  in
  raise (Error (loc, msg))

exception Unify of (typ * typ) option
exception Arity of string * int * int

let mut_equal l r =
  match (l, r) with
  | Some Ast.Dmut, Some Ast.Dmut -> true
  | Some Ast.Dmut, _ | _, Some Ast.Dmut -> false
  | _ -> true

let rec unify down t1 t2 =
  if t1 == t2 then ()
  else
    match (t1, t2) with
    | Tvar { contents = Link t1 }, t2
    | t1, Tvar { contents = Link t2 }
    | Talias (_, t1), t2
    | t1, Talias (_, t2) ->
        unify true t1 t2
    | Tvar ({ contents = Unbound _ } as tv), t
    | t, Tvar ({ contents = Unbound _ } as tv) ->
        occurs tv t;
        tv := Link t
    | Tfun (params_l, l, _), Tfun (params_r, r, _) -> (
        try
          List.iter2
            (fun left right ->
              if not (mut_equal left.pattr right.pattr) then raise (Unify None);
              unify true left.pt right.pt)
            params_l params_r;
          unify true l r
        with Invalid_argument _ ->
          raise (Arity ("function", List.length params_l, List.length params_r))
        )
    | Trecord (_, None, labels1), Trecord (_, None, labels2) -> (
        try
          Array.iter2
            (fun a b -> Types.(unify true a.ftyp b.ftyp))
            labels1 labels2
        with Invalid_argument _ ->
          raise (Arity ("tuple", Array.length labels1, Array.length labels2)))
    | Trecord (ps1, Some n1, labels1), Trecord (ps2, Some n2, labels2) ->
        if Path.equal n1 n2 then
          try
            List.iter2 (unify true) ps1 ps2;
            (* We ignore the label names for now *)
            Array.iter2
              (fun a b -> Types.(unify true a.ftyp b.ftyp))
              labels1 labels2
          with Invalid_argument _ ->
            raise (Arity ("record", Array.length labels1, Array.length labels2))
        else raise (Unify None)
    | Tvariant (ps1, n1, ctors1), Tvariant (ps2, n2, ctors2) ->
        if Path.equal n1 n2 then
          try
            List.iter2 (unify true) ps1 ps2;
            (* We ignore the ctor names for now *)
            Array.iter2
              (fun a b ->
                match (a.ctyp, b.ctyp) with
                | Some a, Some b -> unify true a b
                | None, None -> ()
                | Some _, None | None, Some _ -> raise (Unify None))
              ctors1 ctors2
          with Invalid_argument _ -> raise (Unify None)
        else raise (Unify None)
    | Tabstract (psl, nl, l), Tabstract (psr, nr, r) ->
        if Path.equal nl nr then
          try
            List.iter2 (unify true) psl psr;
            unify true l r
          with Invalid_argument _ -> raise (Unify None)
        else raise (Unify None)
    | Traw_ptr l, Traw_ptr r -> unify true l r
    | Tarray l, Tarray r -> unify true l r
    | Qvar a, Qvar b when String.equal a b ->
        (* We should not need this. Anyway *)
        ()
    | _ -> if down then raise (Unify (Some (t1, t2))) else raise (Unify None)

let unify info t1 t2 =
  try unify false t1 t2 with
  | Unify ts ->
      let loc, pre = info in
      let msg =
        Printf.sprintf "%s Expected type %s but got type %s" pre
          (string_of_type t1) (string_of_type t2)
      in
      let suffix =
        match ts with
        | Some (a, b) ->
            Printf.sprintf ".\nCannot unify types %s and %s" (string_of_type a)
              (string_of_type b)
        | None -> ""
      in
      raise (Error (loc, msg ^ suffix))
  | Arity (thing, l1, l2) -> arity info thing l1 l2

let rec generalize = function
  | Tvar { contents = Unbound (id, l) } when l > !current_level -> Qvar id
  | Tvar ({ contents = Link t } as tv) ->
      tv := Link (generalize t);
      Tvar tv
  | Talias (n, t) -> Talias (n, generalize t)
  | Tfun (t1, t2, k) ->
      let gen p = { p with pt = generalize p.pt } in
      Tfun (List.map gen t1, generalize t2, generalize_closure k)
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
  | Tabstract (ps, name, t) ->
      let ps = List.map generalize ps in
      Tabstract (ps, name, generalize t)
  | Traw_ptr t -> Traw_ptr (generalize t)
  | Tarray t -> Tarray (generalize t)
  | t -> t

and generalize_closure = function
  | Simple -> Simple
  | Closure cls ->
      Closure (List.map (fun c -> { c with cltyp = generalize c.cltyp }) cls)

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
        let k, subst =
          match k with
          | Simple -> (k, subst)
          | Closure cls ->
              let subst, cls =
                List.fold_left_map
                  (fun s c ->
                    let cltyp, subst = aux s c.cltyp in
                    (subst, { c with cltyp }))
                  subst cls
              in
              (Closure cls, subst)
        in
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
    | Tabstract (ps, name, t) ->
        let subst = ref subst in
        let ps =
          List.map
            (fun t ->
              let t, subst' = aux !subst t in
              subst := subst';
              t)
            ps
        in
        let t, subst = aux !subst t in
        (Tabstract (ps, name, t), subst)
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
let rec types_match ?(strict = false) ?(match_abstract = false) subst l r =
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
        types_match ~match_abstract ~strict subst l r
    | _, Tvar { contents = Unbound _ } ->
        failwith "Internal Error: Type comparison for non-generalized types"
    | Tfun (ps_l, l, _), Tfun (ps_r, r, _) -> (
        try
          let subst, acc =
            List.fold_left2
              (fun (s, acc) l r ->
                let subst, b =
                  types_match ~match_abstract ~strict:true s l.pt r.pt
                in
                let b = b && l.pattr = r.pattr in
                (subst, acc && b))
              (subst, true) ps_l ps_r
          in
          (* We don't shortcut here to match the annotations for the error message *)
          let subst, b = types_match ~match_abstract ~strict:true subst l r in
          (subst, acc && b)
        with Invalid_argument _ -> (subst, false))
    | Trecord (_, None, l), Trecord (_, None, r) -> (
        let l = Array.to_list l and r = Array.to_list r in
        try
          List.fold_left2
            (fun (s, acc) l r ->
              let subst, b = types_match ~match_abstract s l.ftyp r.ftyp in
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
              let subst, b = types_match ~match_abstract ~strict s l r in
              (subst, acc && b))
            (subst, true) pl pr
        else (subst, false)
    | Traw_ptr l, Traw_ptr r | Tarray l, Tarray r ->
        types_match ~match_abstract ~strict subst l r
    | Tabstract (_, l, lt), Tabstract (_, r, rt) ->
        if Path.equal l r then
          types_match ~strict:true ~match_abstract subst lt rt
        else (subst, false)
    | (Tabstract (_, _, l), r | l, Tabstract (_, _, r)) when match_abstract ->
        types_match ~strict ~match_abstract subst l r
    | _ -> (subst, false)

let rec match_type_params loc params typ =
  (* Take qvars from [params] and match them to the one found in [typ].
     Assume they appear in the same order. E.g. If params = [A, B] and typ [C, B]
     it probably won't work *)
  let buildup_subst subst l r =
    match (l, r) with
    (* Qvar l, Qvar r when String.equal l r -> subst *)
    | Qvar l, Qvar r -> (
        match Smap.find_opt l subst with
        | Some id when String.equal r id -> subst
        | Some _ -> failwith "Internal Error: No substitution"
        | None ->
            (* We 'connect' right to left *)
            Smap.add r l subst)
    | _ -> failwith "Internal Error: Strange type param"
  in

  let rec replace_qvar subst = function
    | (Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32) as t -> t
    | Qvar s -> (
        match Smap.find_opt s subst with
        | None -> failwith "Internal Error: Expected a substitution"
        | Some str -> Qvar str)
    | Tvar ({ contents = Link t } as l) as tvar ->
        let t = replace_qvar subst t in
        l := Link t;
        tvar
    | Tvar { contents = Unbound _ } ->
        failwith "Internal Error: Type is unbound in impl"
    | Trecord (ps, n, fs) ->
        let ps = List.map (replace_qvar subst) ps in
        let fs =
          Array.map
            (fun f ->
              let ftyp = (replace_qvar subst) f.ftyp in
              { f with ftyp })
            fs
        in
        Trecord (ps, n, fs)
    | Tvariant (ps, n, cs) ->
        let ps = List.map (replace_qvar subst) ps in
        let cs =
          Array.map
            (fun c ->
              let ctyp = Option.map (replace_qvar subst) c.ctyp in
              { c with ctyp })
            cs
        in
        Tvariant (ps, n, cs)
    | Talias (n, t) -> Talias (n, replace_qvar subst t)
    | Traw_ptr t -> Traw_ptr (replace_qvar subst t)
    | Tarray t -> Tarray (replace_qvar subst t)
    | Tabstract (ps, n, t) ->
        let ps = List.map (replace_qvar subst) ps in
        Tabstract (ps, n, replace_qvar subst t)
    | Tfun (ps, r, kind) ->
        let ps =
          List.map
            (fun p ->
              let pt = replace_qvar subst p.pt in
              { p with pt })
            ps
        in
        let r = replace_qvar subst r in
        let kind =
          match kind with
          | Simple -> Simple
          | Closure cls ->
              let cls =
                List.map
                  (fun c ->
                    let cltyp = (replace_qvar subst) c.cltyp in
                    { c with cltyp })
                  cls
              in
              Closure cls
        in
        Tfun (ps, r, kind)
  in

  let msg i =
    Printf.sprintf "Type parameters don't match: Expected %i, got %i"
      (List.length params) i
  in

  match typ with
  | Trecord (ps, _, _) | Tvariant (ps, _, _) | Tabstract (ps, _, _) -> (
      try
        let subst = List.fold_left2 buildup_subst Smap.empty params ps in
        replace_qvar subst typ
      with Invalid_argument _ -> raise (Error (loc, msg (List.length ps))))
  | Talias (n, t) -> Talias (n, match_type_params loc params t)
  | (Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32) as t -> (
      match params with
      | [] -> t
      | _ -> raise (Error (loc, "Unparamatrized type in module implementation"))
      )
  | Tvar { contents = Unbound _ } ->
      failwith "Internal Error: how is this unbound"
  | Qvar _ -> (
      match params with
      | [ Qvar other ] -> Qvar other
      | _ -> failwith "Internal Error: Type param is not qvar")
  | Tvar ({ contents = Link t } as rf) ->
      rf := Link (match_type_params loc params t);
      typ
  | Tarray t -> Tarray (match_type_params loc params t)
  | Traw_ptr t -> Traw_ptr (match_type_params loc params t)
  | Tfun _ -> failwith "TODO abstract function types"
