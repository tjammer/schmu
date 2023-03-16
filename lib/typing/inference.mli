open Types

type err = Ast.loc * string

val reset : unit -> unit
val newvar : unit -> typ
val enter_level : unit -> unit
val leave_level : unit -> unit
val unify : err -> typ -> typ -> unit
val generalize : typ -> typ
val instantiate : typ -> typ
val regeneralize : typ -> typ

val types_match :
  ?strict:bool ->
  ?match_abstract:bool ->
  string Smap.t ->
  typ ->
  typ ->
  string Smap.t * bool
(** Checks if types match. [~strict] means Unbound vars will not match everything.
   This is true for functions where we want to be as general as possible.
       We need to match everything for weak vars though *)

val match_type_params : Ast.loc -> typ list -> typ -> typ
