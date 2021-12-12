type typ =
  | TInt
  | TBool
  | TUnit
  | TVar of tv ref
  | QVar of string
  | TFun of typ list * typ * fun_kind
  | TRecord of typ option * string * (string * typ) list
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list

and tv = Unbound of string * int | Link of typ | Qannot of string

let rec clean = function
  | TVar { contents = Link t } -> clean t
  | TFun (params, ret, Closure vals) ->
      let vals = List.map (fun (name, typ) -> (name, clean typ)) vals in
      TFun (List.map clean params, clean ret, Closure vals)
  | TFun (params, ret, kind) -> TFun (List.map clean params, clean ret, kind)
  | TRecord (param, name, fields) ->
      let param = Option.map clean param in
      TRecord
        (param, name, List.map (fun (name, typ) -> (name, clean typ)) fields)
  | t -> t

let rec freeze = function
  | TVar { contents = Unbound (str, _) } -> QVar str
  | TVar { contents = Link t } -> freeze t
  | TFun (params, ret, kind) -> TFun (List.map freeze params, freeze ret, kind)
  | TRecord (param, name, fields) ->
      let param = Option.map freeze param in
      let fields = List.map (fun (name, typ) -> (name, freeze typ)) fields in
      TRecord (param, name, fields)
  | t -> t
