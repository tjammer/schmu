type typ = TInt | TBool [@@deriving show]

exception Error of Ast.Loc.t * string

module Context : sig
  type t

  val empty : t

  val lookup : string -> t -> typ option

  val extend : string -> typ -> t -> t
end

val typecheck : Ast.expr -> typ
