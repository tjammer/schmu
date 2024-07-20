open Types
module Smap = Map.Make (String)
module Pmap = Map.Make (Path)

type psub = Path.t Pmap.t
type tsub = Types.typ Smap.t
type item_kind = Mtypedef of type_decl | Mvalue of typ * string option
and item = string * Ast.loc * item_kind
and t = item list [@@deriving show]

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

let apply_pathsub ~base ~with_ typ =
  let subst p = Path.subst_base ~base ~with_ p in
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

let adjust_for_checking ~base ~with_ mtype =
  print_endline ("adjust: " ^ Path.show base ^ " to " ^ Path.show with_);
  List.map
    (fun (name, loc, kind) ->
      match kind with
      | Mvalue (typ, cn) ->
          let typ = apply_pathsub ~base ~with_ typ in
          (name, loc, Mvalue (typ, cn))
      | Mtypedef _ as t -> (name, loc, t))
    mtype

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
