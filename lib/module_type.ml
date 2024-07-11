open Types
module Smap = Map.Make (String)
module Pmap = Map.Make (Path)

type psub = Path.t Pmap.t
type tsub = Types.typ Smap.t
type item_kind = Mtypedef of type_decl | Mvalue of typ * string option
type item = string * Ast.loc * item_kind
type t = item list

let subst_name ~mname pathsub p inner =
  if inner then
    match Pmap.find_opt p pathsub with
    | Some p -> (pathsub, p)
    | None -> (pathsub, p)
  else
    (* This path needs to be substituted *)
    let newp = Path.append (Path.get_hd p) mname in
    let pathsub = Pmap.add p newp pathsub in
    (pathsub, newp)

let apply_subs (psub, _) typ =
  let subst p = match Pmap.find_opt p psub with Some p -> p | None -> p in
  let rec aux = function
    | Tconstr (p, ps) -> Tconstr (subst p, List.map aux ps)
    | Ttuple ts -> Ttuple (List.map aux ts)
    | Tfun (ps, r, kind) ->
        let ps = List.map (fun p -> { p with pt = aux p.pt }) ps in
        let kind =
          match kind with
          | Simple -> kind
          | Closure cls ->
              let cls =
                List.map (fun c -> { c with cltyp = aux c.cltyp }) cls
              in
              Closure cls
        in
        Tfun (ps, aux r, kind)
    | Tarray t -> Tarray (aux t)
    | Traw_ptr t -> Traw_ptr (aux t)
    | Trc t -> Trc (aux t)
    | Tfixed_array (iv, t) -> Tfixed_array (iv, aux t)
    | Tvar { contents = Link t } -> aux t
    | t -> t
  in
  aux typ

let adjust_type ~mname pathsub ubsub inner typ =
  let rec aux pathsub ubsub inner = function
    | Tconstr (p, ps) ->
        let pathsub, p = subst_name ~mname pathsub p inner in
        let (pathsub, ubsub), ps =
          List.fold_left_map
            (fun (pathsub, ubsub) t ->
              let pathsub, ubsub, t = aux pathsub ubsub true t in
              ((pathsub, ubsub), t))
            (pathsub, ubsub) ps
        in
        (pathsub, ubsub, Tconstr (p, ps))
    | Ttuple ts ->
        let (pathsub, ubsub), ts =
          List.fold_left_map
            (fun (pathsub, ubsub) t ->
              let pathsub, ubsub, t = aux pathsub ubsub true t in
              ((pathsub, ubsub), t))
            (pathsub, ubsub) ts
        in
        (pathsub, ubsub, Ttuple ts)
    | Tfun (ps, r, kind) ->
        (match kind with
        | Simple -> ()
        | Closure _ ->
            (* Module types should not specify closures *)
            failwith "Unexpected closure");
        let (pathsub, ubsub), ps =
          List.fold_left_map
            (fun (pathsub, ubsub) p ->
              let pathsub, ubsub, pt = aux pathsub ubsub true p.pt in
              ((pathsub, ubsub), { p with pt }))
            (pathsub, ubsub) ps
        in
        let pathsub, ubsub, r = aux pathsub ubsub true r in
        (pathsub, ubsub, Tfun (ps, r, kind))
    | Tarray t ->
        let pathsub, ubsub, t = aux pathsub ubsub true t in
        (pathsub, ubsub, Tarray t)
    | Traw_ptr t ->
        let pathsub, ubsub, t = aux pathsub ubsub true t in
        (pathsub, ubsub, Traw_ptr t)
    | Trc t ->
        let pathsub, ubsub, t = aux pathsub ubsub true t in
        (pathsub, ubsub, Trc t)
    | Tfixed_array (iv, t) ->
        let pathsub, ubsub, t = aux pathsub ubsub true t in
        (pathsub, ubsub, Tfixed_array (iv, t))
    | t -> (pathsub, ubsub, t)
  in
  aux pathsub ubsub inner typ

let adjust_for_checking ~mname mtype =
  List.fold_left_map
    (fun (pathsub, ubsub) (name, loc, kind) ->
      let pathsub, ubsub, kind =
        match kind with
        | Mvalue (typ, n) ->
            let pathsub, ubsub, typ =
              adjust_type ~mname pathsub ubsub false typ
            in
            (pathsub, ubsub, Mvalue (typ, n))
        | Mtypedef _ as t -> (pathsub, ubsub, t)
      in
      ((pathsub, ubsub), (name, loc, kind)))
    (Pmap.empty, Smap.empty) mtype

exception Merge_error of string

let merge_subs (ap, at) (bp, bt) =
  let merge pp p a b =
    match (a, b) with
    | Some _, Some _ -> raise (Merge_error (pp p))
    | None, Some t | Some t, None -> Some t
    | None, None -> None
  in

  try Ok (Pmap.merge (merge Path.show) ap bp, Smap.merge (merge Fun.id) at bt)
  with Merge_error s -> Error s
