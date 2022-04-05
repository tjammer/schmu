type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tfloat
  | Tvar of tv ref
  | Talias of string * typ
  | Qvar of string
  | Tfun of typ list * typ * fun_kind
  | Trecord of typ option * string * field array
  | Tptr of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list
and tv = Unbound of string * int | Link of typ
and field = { name : string; typ : typ; mut : bool }

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
