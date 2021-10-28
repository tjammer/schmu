type typ =
  | TInt
  | TBool
  | TUnit
  | TVar of tv ref
  | QVar of string
  | TFun of typ list * typ * fun_kind
  | TRecord of string * (string * typ) list

and fun_kind = Simple | Anon | Closure of (string * typ) list

and tv = Unbound of string * int | Link of typ

let rec clean = function
  | TVar { contents = Link t } -> clean t
  | QVar _ -> failwith "TODO think about this"
  | TFun (params, ret, Closure vals) ->
      let vals = List.map (fun (name, typ) -> (name, clean typ)) vals in
      TFun (List.map clean params, clean ret, Closure vals)
  | TFun (params, ret, kind) -> TFun (List.map clean params, clean ret, kind)
  | TRecord (name, fields) ->
      TRecord (name, List.map (fun (name, typ) -> (name, clean typ)) fields)
  | t -> t
