type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tpoly of string
  | Tfun of typ list * typ * fun_kind
  | Trecord of typ option * string * field array
  | Tptr of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list
and field = { name : string; typ : typ; mut : bool }

let is_type_polymorphic typ =
  let rec inner acc = function
    | Tpoly _ -> true
    | Trecord (Some t, _, _) -> inner acc t
    | Tfun (params, ret, _) ->
        let acc = List.fold_left inner acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Trecord _ | Tu8 -> acc
    | Tptr t -> inner acc t
  in
  inner false typ

let rec string_of_type = function
  | Tint -> "int"
  | Tbool -> "bool"
  | Tunit -> "unit"
  | Tu8 -> "u8"
  | Tfun (ts, t, _) -> (
      match ts with
      | [ p ] -> Printf.sprintf "%s -> %s" (string_of_type p) (string_of_type t)
      | ts ->
          let ts = String.concat ", " (List.map string_of_type ts) in
          Printf.sprintf "(%s) -> %s" ts (string_of_type t))
  | Tpoly str -> str
  | Trecord (param, str, _) ->
      str
      ^ Option.fold ~none:""
          ~some:(fun param -> Printf.sprintf "(%s)" (string_of_type param))
          param
  | Tptr t -> Printf.sprintf "ptr(%s)" (string_of_type t)
