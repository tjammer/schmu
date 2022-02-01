type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tvar of tv ref
  | Talias of string * typ
  | Qvar of string
  | Tfun of typ list * typ * fun_kind
  | Trecord of typ option * string * (string * typ) array
  | Tptr of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list
and tv = Unbound of string * int | Link of typ

(* Follow links and aliases *)
let rec clean = function
  | Tvar { contents = Link t } -> clean t
  | Tfun (params, ret, Closure vals) ->
      let vals = List.map (fun (name, typ) -> (name, clean typ)) vals in
      Tfun (List.map clean params, clean ret, Closure vals)
  | Tfun (params, ret, kind) -> Tfun (List.map clean params, clean ret, kind)
  | Trecord (param, name, fields) ->
      Trecord
        (param, name, Array.map (fun (name, typ) -> (name, clean typ)) fields)
  | Talias (_, t) -> clean t
  | t -> t
