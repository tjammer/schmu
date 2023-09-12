type item_kind = Mtypedef | Mvalue
type item = string * Ast.loc * Types.typ * item_kind
type t = item list

val adjust_for_checking : mname:Path.t -> newvar:(unit -> Types.typ) -> t -> t
(** [adjust_for_checking ~mname mtype] changes the type paths in [mtype] to [mname]
    such that they nominally can be the same type. It also generates a new unbound
    symbol for abstract types such that we can use linking correctly without
    interfering with later checks. *)
