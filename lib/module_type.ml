open Types
module Smap = Map.Make (String)
module Pmap = Map.Make (Path)

type psub = Path.t Pmap.t
type tsub = Types.typ Smap.t

type item_kind = Mtypedef of type_decl | Mvalue of typ * string option
and item = string * Ast.loc * item_kind
and t = item list

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
    | (Tvar { contents = Unbound _ } | Qvar _ | Tprim _) as t -> t
  in
  aux typ

let adjust_for_checking ~base ~with_ mtype =
  List.map
    (fun (name, loc, kind) ->
      match kind with
      | Mvalue (typ, cn) ->
          let typ = apply_pathsub ~base ~with_ typ in
          (name, loc, Mvalue (typ, cn))
      | Mtypedef _ as t -> (name, loc, t))
    mtype
