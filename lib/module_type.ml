type item_kind = Mtypedef | Mvalue
type item = string * Ast.loc * Types.typ * item_kind
type t = item list
