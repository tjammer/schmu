type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tvar of tv ref
  | Qvar of string
  | Tfun of typ list * typ * fun_kind
  | Trecord of typ option * string * (string * typ) array
  | Tptr of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list
and tv = Unbound of string * int | Link of typ | Qannot of string

let rec clean = function
  | Tvar { contents = Link t } -> clean t
  | Tfun (params, ret, Closure vals) ->
      let vals = List.map (fun (name, typ) -> (name, clean typ)) vals in
      Tfun (List.map clean params, clean ret, Closure vals)
  | Tfun (params, ret, kind) -> Tfun (List.map clean params, clean ret, kind)
  | Trecord (param, name, fields) ->
      Trecord
        (param, name, Array.map (fun (name, typ) -> (name, clean typ)) fields)
  | t -> t

let rec freeze = function
  | Tvar { contents = Unbound (str, _) } -> Qvar str
  | Tvar { contents = Link t } -> freeze t
  | Tfun (params, ret, kind) -> Tfun (List.map freeze params, freeze ret, kind)
  | Trecord (param, name, fields) ->
      let fields = Array.map (fun (name, typ) -> (name, freeze typ)) fields in
      Trecord (param, name, fields)
  | t -> t
