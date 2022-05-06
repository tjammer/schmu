type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tfloat
  | Ti32
  | Tf32
  | Tvar of tv ref
  | Qvar of string
  | Tfun of typ list * typ * fun_kind
  | Talias of string * typ
  | Trecord of typ option * string * field array
  | Tvariant of typ option * string * ctor array
  | Tptr of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list
and tv = Unbound of string * int | Link of typ
and field = { name : string; typ : typ; mut : bool }
and ctor = { ctorname : string; ctortyp : typ option }

(* Follow links and aliases *)
let rec clean = function
  | Tvar { contents = Link t } -> clean t
  | Tfun (params, ret, Closure vals) ->
      let vals = List.map (fun (name, typ) -> (name, clean typ)) vals in
      Tfun (List.map clean params, clean ret, Closure vals)
  | Tfun (params, ret, kind) -> Tfun (List.map clean params, clean ret, kind)
  | Trecord (param, name, fields) ->
      let param = Option.map clean param in
      Trecord
        ( param,
          name,
          Array.map (fun field -> { field with typ = clean field.typ }) fields
        )
  | Talias (_, t) -> clean t
  | Tptr t -> Tptr (clean t)
  | t -> t

(* Same as [Cleaned_types.is_struct] *)
let rec is_struct = function
  | Tvar { contents = Link t } | Talias (_, t) -> is_struct t
  | Trecord _ | Tvariant _ | Tfun _ | Qvar _ | Tvar { contents = Unbound _ } ->
      true
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Tptr _ -> false
