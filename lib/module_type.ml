open Types
module Smap = Map.Make (String)
module Pmap = Map.Make (Path)

type psub = Path.t Pmap.t
type tsub = Types.typ Smap.t
type callname = string * Path.t option * int option

type item_kind = Mtypedef of type_decl | Mvalue of typ * callname option
and item = string * Ast.loc * item_kind
and t = item list

let apply_pathsub ~base ~with_ typ =
  let subst p = Path.subst_base ~base ~with_ p in
  let rec aux = function
    | Tconstr (p, ps, ca) -> Tconstr (subst p, List.map aux ps, ca)
    | Ttuple ts -> Ttuple (List.map aux ts)
    | Tfun (ps, r, kind) ->
        let ps = List.map (fun p -> { p with pt = aux p.pt }) ps in
        let kind =
          match kind with
          | Simple -> kind
          | Closure cls ->
              let cls =
                List.map
                  (fun c ->
                    (* The module name might als be part of the functor *)
                    let clmname = Option.map subst c.clmname in
                    { c with cltyp = aux c.cltyp; clmname })
                  cls
              in
              Closure cls
        in
        Tfun (ps, aux r, kind)
    | Tfixed_array (iv, t) -> Tfixed_array (iv, aux t)
    | Tvar { contents = Link t } -> aux t
    | (Tvar { contents = Unbound _ } | Qvar _) as t -> t
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
