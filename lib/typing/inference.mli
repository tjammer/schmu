open Types

type err = Ast.loc * string

val reset : unit -> unit
val newvar : unit -> typ
val enter_level : unit -> unit
val leave_level : unit -> unit
val unify : err -> typ -> typ -> Env.t -> unit
val generalize : typ -> typ
val instantiate : typ -> typ
val instantiate_sub : typ Smap.t -> typ -> typ Smap.t * typ
val regeneralize : typ -> typ

val types_match : in_functor:bool -> typ -> typ -> typ * string Smap.t * bool
(** Checks if types match. [~strict] means Unbound vars will not match everything.
   This is true for functions where we want to be as general as possible.
       We need to match everything for weak vars though *)
