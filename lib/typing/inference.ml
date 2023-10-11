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

exception Unify

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
          let attr_mismatch = ref false in
          List.iter2
            (fun left right ->
              (* Continue with unification to generate better type errors *)
              if not (left.pattr = right.pattr) then attr_mismatch := true;
              unify left.pt right.pt)
            params_l params_r;
          unify l r;
          if !attr_mismatch then raise Unify
        with Invalid_argument _ -> raise Unify)
    | Trecord (_, None, labels1), Trecord (_, None, labels2) -> (
        try Array.iter2 (fun a b -> Types.(unify a.ftyp b.ftyp)) labels1 labels2
        with Invalid_argument _ -> raise Unify)
    | Trecord (ps1, Some n1, labels1), Trecord (ps2, Some n2, labels2) ->
        if Path.equal n1 n2 then
          try
            List.iter2 unify ps1 ps2;
            (* We ignore the label names for now *)
            Array.iter2 (fun a b -> Types.(unify a.ftyp b.ftyp)) labels1 labels2
          with Invalid_argument _ -> raise Unify
        else raise Unify
    | Tvariant (ps1, n1, ctors1), Tvariant (ps2, n2, ctors2) ->
        if Path.equal n1 n2 then
          try
            let err = ref false in
            List.iter2 unify ps1 ps2;
            (* We ignore the ctor names for now *)
            Array.iter2
              (fun a b ->
                match (a.ctyp, b.ctyp) with
                | Some a, Some b -> unify a b
                | None, None -> ()
                | Some _, None | None, Some _ ->
                    (* Continue with unification to generate better type errors *)
                    err := true)
              ctors1 ctors2;
            if !err then raise Unify
          with Invalid_argument _ -> raise Unify
        else raise Unify
    | Tabstract (psl, nl, l), Tabstract (psr, nr, r) ->
        if Path.equal nl nr then
          try
            List.iter2 unify psl psr;
            unify l r
          with Invalid_argument _ -> raise Unify
        else raise Unify
    | Traw_ptr l, Traw_ptr r -> unify l r
    | Tarray l, Tarray r -> unify l r
    | _ -> raise Unify

let unify info t1 t2 env =
  let mn = Env.modpath env in
  let loc, pre = info in
  try unify t1 t2
  with Unify ->
    let msg = Error.format_type_err pre mn t1 t2 in
    raise (Error (loc, msg))

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

module Nameset = Set.Make (Path)

(* Checks if types match. [~strict] means Unbound vars will not match everything.
   This is true for functions where we want to be as general as possible.
   We need to match everything for weak vars though *)
let rec types_match ~in_functor l r =
  let rec collect_names acc = function
    | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Qvar _ | Tfun _
    | Traw_ptr _ | Tarray _
    | Tvar { contents = Unbound _ }
    | Trecord (_, None, _) ->
        acc
    | Talias (p, t) | Tabstract (_, p, t) -> collect_names (Nameset.add p acc) t
    | Trecord (_, Some p, _) | Tvariant (_, p, _) -> Nameset.add p acc
    | Tvar { contents = Link t } -> collect_names acc t
  in

  let nss_of_types l r =
    let lns = collect_names Nameset.empty l
    and rns = collect_names Nameset.empty r in
    ((lns, l), (rns, r))
  in

  let rec aux ~strict qsubst (lns, l) (rns, r) =
    if l == r then (qsubst, true)
    else
      match (l, r) with
      | Tvar { contents = Unbound (l, _) }, Tvar { contents = Unbound (r, _) }
      | Qvar l, Tvar { contents = Unbound (r, _) }
        when in_functor -> (
          (* We always map from left to right *)
          match Smap.find_opt l qsubst with
          | Some id when String.equal r id -> (qsubst, true)
          | Some _ -> (qsubst, false)
          | None ->
              (* We 'connect' left to right *)
              (Smap.add l r qsubst, true))
      | Qvar l, Qvar r | Tvar { contents = Unbound (l, _) }, Qvar r -> (
          (* We always map from left to right *)
          match Smap.find_opt l qsubst with
          | Some id when String.equal r id -> (qsubst, true)
          | Some _ -> (qsubst, false)
          | None ->
              (* We 'connect' left to right *)
              (Smap.add l r qsubst, true))
      | Tvar { contents = Unbound _ }, _ when not strict ->
          (* Unbound vars match every type *) (qsubst, true)
      | Tvar { contents = Link l }, r
      | l, Tvar { contents = Link r }
      | Talias (_, l), r
      | l, Talias (_, r) ->
          aux ~strict qsubst (lns, l) (rns, r)
      | _, Tvar { contents = Unbound _ } when not in_functor -> (qsubst, false)
      | Tfun (ps_l, l, _), Tfun (ps_r, r, _) -> (
          try
            let qsubst, acc =
              List.fold_left2
                (fun (s, acc) pl pr ->
                  let l, r = nss_of_types pl.pt pr.pt in
                  let qsubst, b = aux ~strict:true s l r in
                  let b = b && pl.pattr = pr.pattr in
                  (qsubst, acc && b))
                (qsubst, true) ps_l ps_r
            in
            (* We don't shortcut here to match the annotations for the error message *)
            let l, r = nss_of_types l r in
            let qsubst, b = aux ~strict:true qsubst l r in
            (qsubst, acc && b)
          with Invalid_argument _ -> (qsubst, false))
      | Trecord (_, None, l), Trecord (_, None, r) -> (
          let l = Array.to_list l and r = Array.to_list r in
          try
            List.fold_left2
              (fun (s, acc) l r ->
                let l, r = nss_of_types l.ftyp r.ftyp in
                let qsubst, b = aux ~strict s l r in
                (qsubst, acc && b))
              (qsubst, true) l r
          with Invalid_argument _ -> (qsubst, false))
      | Trecord (pl, Some _, _), Trecord (pr, Some _, _)
      | Tvariant (pl, _, _), Tvariant (pr, _, _) ->
          (* It should be enough to compare the name (rather, the name's repr)
             and the param type *)
          if not (Nameset.disjoint lns rns) then
            List.fold_left2
              (fun (s, acc) l r ->
                let l, r = nss_of_types l r in
                let qsubst, b = aux ~strict s l r in
                (qsubst, acc && b))
              (qsubst, true) pl pr
          else (qsubst, false)
      | Traw_ptr l, Traw_ptr r | Tarray l, Tarray r ->
          let l, r = nss_of_types l r in
          aux ~strict qsubst l r
      | Tabstract (_, _, lt), Tabstract (_, _, rt) ->
          if not (Nameset.disjoint lns rns) then
            aux ~strict:true qsubst (lns, lt) (rns, rt)
          else (qsubst, false)
      | Tabstract (ps, _, l), r -> (
          match match_type_params ~in_functor ps l with
          | Ok l -> aux ~strict qsubst (lns, l) (rns, r)
          | Error _ -> (qsubst, false))
      | l, Tabstract (ps, _, r) -> (
          match match_type_params ~in_functor ps r with
          | Ok r -> aux ~strict qsubst (lns, l) (rns, r)
          | Error _ -> (qsubst, false))
      | _ -> (qsubst, false)
  in
  let l, r = nss_of_types l r in
  aux ~strict:false Smap.empty l r

and match_type_params ~in_functor params typ =
  (* Take qvars from [params] and match them to the one found in [typ].
     Assume they appear in the same order. E.g. If params = [A, B] and typ [C, B]
     it probably won't work *)
  let buildup_subst subst l r =
    let smap, mtch = types_match ~in_functor:false r l in
    if mtch then
      Smap.merge
        (fun _ a b ->
          match (a, b) with
          | Some a, None -> Some a
          | None, None -> None
          | None, Some b -> Some b
          | Some a, Some b when String.equal a b -> Some a
          | Some a, Some b -> failwith (a ^ " vs " ^ b))
        subst smap
    else raise (Invalid_argument "")
  in

  let rec replace_qvar subst = function
    | (Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32) as t -> t
    | Qvar s -> (
        match Smap.find_opt s subst with
        | None -> Qvar s
        (*   print_endline ("search for: " ^ s); *)
        (* failwith "Internal Error: Expected a substitution" *)
        | Some str -> Qvar str)
    | Tvar ({ contents = Link t } as l) as tvar ->
        let t = replace_qvar subst t in
        l := Link t;
        tvar
    | Tvar { contents = Unbound _ } when not in_functor ->
        failwith "Internal Error: Type is unbound in impl"
    | Tvar { contents = Unbound _ } as t -> t
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

  let ( let* ) = Result.bind in
  match typ with
  | Trecord (ps, _, _) | Tvariant (ps, _, _) | Tabstract (ps, _, _) -> (
      try
        let subst = List.fold_left2 buildup_subst Smap.empty params ps in
        Ok (replace_qvar subst typ)
      with Invalid_argument _ -> Error ())
  | Talias (n, t) ->
      let* t = match_type_params ~in_functor params t in
      Ok (Talias (n, t))
  | (Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32) as t -> (
      match params with [] -> Ok t | _ -> Error ())
  | Tvar { contents = Unbound _ } as t ->
      (* failwith "Internal Error: how is this unbound" *) Ok t
  | Qvar _ -> (
      match params with
      | [ Qvar other ] -> Ok (Qvar other)
      | _ -> failwith "Internal Error: Type param is not qvar")
  | Tvar ({ contents = Link t } as rf) ->
      let* t = match_type_params ~in_functor params t in
      rf := Link t;
      Ok typ
  | Tarray t ->
      let* t = match_type_params ~in_functor params t in
      Ok (Tarray t)
  | Traw_ptr t ->
      let* t = match_type_params ~in_functor params t in
      Ok (Traw_ptr t)
  | Tfun _ -> failwith "TODO abstract function types"
