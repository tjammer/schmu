type typ = TInt | TBool | TFun of typ * typ | TVar of string [@@deriving show]

exception Error of Ast.loc * string

type scheme

module Subst : sig
  type t

  val empty : t

  val compose : t -> t -> t
end

module Context : sig
  type t

  val empty : t

  val lookup : string -> t -> scheme option

  val extend : string -> scheme -> t -> t

  val generalize : t -> typ -> scheme
end

val instantiate : scheme -> typ



val typecheck : Ast.expr -> typ
