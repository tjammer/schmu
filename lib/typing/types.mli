module Strtbl : Hashtbl.S
module Smap : Map.S with type key = string
module Sset : Set.S with type elt = string

type typ =
  | Tvar of tv ref
  | Qvar of string
  | Tfun of param list * typ * fun_kind
  | Ttuple of typ list
  | Tconstr of
      Path.t
      * typ list
      * bool (* contains allocations in unparameterized parts *)
  | Tfixed_array of iv ref * typ
[@@deriving show { with_path = false }, sexp]

and fun_kind = Simple | Closure
and tv = Unbound of string * int | Link of typ
and param = { pt : typ; pattr : Ast.decl_attr; pmode : inferred_mode ref }
and field = { fname : string; ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }

and iv =
  | Unknown of string * int
  | Known of int
  | Generalized of string
  | Linked of iv ref

and mode = Many | Once

and inferred_mode =
  | Iunknown (* TODO use levels *)
  | Iknown of mode
  | Ilinked of inferred_mode ref

type type_decl = {
  params : typ list;
  kind : decl_kind;
  in_sgn : bool;
  contains_alloc : bool;
}

and recursive = {
  is_recursive : bool;
  has_base : bool;
  params_behind_ptr : bool;
}

and decl_kind =
  | Drecord of recursive * field array
  | Dvariant of recursive * ctor array
  | Dabstract of decl_kind option
  | Dalias of typ
[@@deriving sexp, show]

val tunit : typ
val tint : typ
val tfloat : typ
val ti32 : typ
val tu32 : typ
val tf32 : typ
val tbool : typ
val ti8 : typ
val tu8 : typ
val ti16 : typ
val tu16 : typ
val tarray : typ -> typ
val traw_ptr : typ -> typ
val trc : typ -> typ
val tweak_rc : typ -> typ

val repr : typ -> typ
(** Extract real type (follow links) and do path compression *)

val string_of_type : Path.t -> typ -> string
(** Normal version, will name type vars starting from 'a *)

val fold_builtins : ('a -> string -> type_decl -> 'a) -> 'a -> 'a
(** Fold over all special builtin types to add them to the typing env *)

val is_builtin : typ -> bool
val get_builtin : Path.t -> type_decl option
val is_polymorphic : typ -> bool
val is_unit : typ -> bool
val is_weak : sub:Sset.t -> typ -> bool
val is_poly_orphan : sub:Sset.t -> typ -> bool
val mut_of_pattr : Ast.decl_attr -> bool
val is_clike_variant : ctor array -> bool
val is_unbound : typ -> (string * int) option
val subst_generic : id:string -> typ -> typ -> typ
val get_generic_ids : fixed:bool -> typ -> string list
val map_params : inst:typ list -> params:typ list -> typ Smap.t
val map_lazy : inst:typ list -> typ Smap.t -> typ -> typ list * typ Smap.t
val typ_of_decl : type_decl -> Path.t -> typ
val resolve_alias : (Path.t -> (type_decl * Path.t) option) -> typ -> typ

val contains_allocation : ?poly:bool -> typ -> bool
(** Polymorphic types will return true *)

val recursion_allowed :
  (Path.t -> type_decl) ->
  params:typ list ->
  Path.t ->
  typ ->
  (recursive * typ option, string) result

val string_of_mode : inferred_mode -> string
val repr_mode : inferred_mode -> inferred_mode
