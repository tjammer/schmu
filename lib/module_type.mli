type item_kind = Mtypedef | Mvalue
type item = string * Ast.loc * Types.typ * item_kind
type t = item list

module Pmap : Map.S with type key = Path.t
module Smap : Map.S with type key = string

type psub = Path.t Pmap.t
type tsub = Types.typ Smap.t

val adjust_for_checking :
  mname:Path.t -> newvar:(unit -> Types.typ) -> t -> (psub * tsub) * t
(** [adjust_for_checking ~mname mtype] changes the type paths in [mtype] to [mname]
    such that they nominally can be the same type. It also generates a new unbound
    symbol for abstract types such that we can use linking correctly without
    interfering with later checks. *)

val apply_subs : psub * tsub -> Types.typ -> Types.typ
val merge_subs : psub * tsub -> psub * tsub -> (psub * tsub, string) result
