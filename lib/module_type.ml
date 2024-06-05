open Types
module Smap = Map.Make (String)
module Pmap = Map.Make (Path)

type psub = Path.t Pmap.t
type tsub = Types.typ Smap.t
type item_kind = Mtypedef | Mvalue of string option
type item = string * Ast.loc * typ * item_kind
type t = item list

let gensym newvar =
  match newvar () with
  | Tvar { contents = Unbound (sym, _) } -> sym
  | _ -> failwith "unreachable"

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

let apply_subs (psub, tsub) typ =
  let subst p = match Pmap.find_opt p psub with Some p -> p | None -> p in
  let rec aux = function
    | Tabstract (ps, p, t) -> (
        match is_unbound t with
        | Some (sym, _) -> (
            match Smap.find_opt sym tsub with
            | Some t -> t
            | None -> failwith "unreachable")
        | None -> Tabstract (List.map aux ps, subst p, aux t))
    | Talias (p, t) -> Talias (subst p, aux t)
    | Trecord (ps, p, fs) ->
        let ps = List.map aux ps in
        let fs = Array.map (fun f -> { f with ftyp = aux f.ftyp }) fs in
        Trecord (ps, Option.map subst p, fs)
    | Tvariant (ps, p, cts) ->
        let ps = List.map aux ps in
        let cts =
          Array.map (fun c -> { c with ctyp = Option.map aux c.ctyp }) cts
        in
        Tvariant (ps, subst p, cts)
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

let adjust_type ~mname ~newvar pathsub ubsub inner typ =
  let rec aux pathsub ubsub inner = function
    | Tabstract (ps, p, ub) -> (
        match is_unbound ub with
        | Some (sym, l) ->
            let ubsub, t =
              match Smap.find_opt sym ubsub with
              | Some t -> (ubsub, t)
              | None ->
                  (* Generate a new type *)
                  let t = Tvar (ref (Unbound (gensym newvar, l))) in
                  (Smap.add sym t ubsub, t)
            in
            (* [ps] will be matched later in [match_type_params] *)
            (* NOTE I'm note sure if we should apply name substitutions to [ps] also *)
            let pathsub, newp = subst_name ~mname pathsub p inner in
            (pathsub, ubsub, Tabstract (ps, newp, t))
        | None -> failwith "What is this?")
    | Talias (p, t) ->
        let pathsub, newp = subst_name ~mname pathsub p inner in
        let pathsub, ubsub, t = aux pathsub ubsub true t in
        (pathsub, ubsub, Talias (newp, t))
    | Trecord (ps, p, fs) ->
        let pathsub, newp =
          match p with
          | Some p ->
              let pathsub, p = subst_name ~mname pathsub p inner in
              (pathsub, Some p)
          | None -> (pathsub, None)
        in
        let (pathsub, ubsub), fs =
          Array.fold_left_map
            (fun (pathsub, ubsub) f ->
              let pathsub, ubsub, ftyp = aux pathsub ubsub true f.ftyp in
              ((pathsub, ubsub), { f with ftyp }))
            (pathsub, ubsub) fs
        in
        (pathsub, ubsub, Trecord (ps, newp, fs))
    | Tvariant (ps, p, cts) ->
        let pathsub, newp = subst_name ~mname pathsub p inner in
        let (pathsub, ubsub), cts =
          Array.fold_left_map
            (fun (pathsub, ubsub) c ->
              let pathsub, ubsub, ctyp =
                match c.ctyp with
                | Some t ->
                    let p, u, t = aux pathsub ubsub true t in
                    (p, u, Some t)
                | None -> (pathsub, ubsub, None)
              in
              ((pathsub, ubsub), { c with ctyp }))
            (pathsub, ubsub) cts
        in
        (pathsub, ubsub, Tvariant (ps, newp, cts))
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

let adjust_for_checking ~mname ~newvar mtype =
  List.fold_left_map
    (fun (pathsub, ubsub) (name, loc, typ, kind) ->
      let pathsub, ubsub, typ =
        adjust_type ~mname ~newvar pathsub ubsub false typ
      in
      ((pathsub, ubsub), (name, loc, typ, kind)))
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
