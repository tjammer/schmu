type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tfloat
  | Ti32
  | Tf32
  | Tpoly of string
  | Tfun of typ list * typ * fun_kind
  | Trecord of typ list * string * field array
  | Tvariant of typ list * string * ctor array
  | Traw_ptr of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of (string * typ) list
and field = { ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }

let is_type_polymorphic typ =
  let rec inner acc = function
    | Tpoly _ -> true
    | Trecord (ps, _, _) | Tvariant (ps, _, _) -> List.fold_left inner acc ps
    | Tfun (params, ret, kind) ->
        let acc = List.fold_left inner acc params in
        let acc =
          match kind with
          | Simple -> acc
          | Closure cls ->
              List.fold_left (fun acc (_, t) -> inner acc t) acc cls
        in
        inner acc ret
    | Tbool | Tunit | Tint | Tu8 | Tfloat | Ti32 | Tf32 -> acc
    | Traw_ptr t -> inner acc t
  in
  inner false typ

let rec string_of_type = function
  | Tint -> "int"
  | Tbool -> "bool"
  | Tunit -> "unit"
  | Tu8 -> "u8"
  | Tfloat -> "float"
  | Ti32 -> "i32"
  | Tf32 -> "f32"
  | Tfun (ts, t, _) -> (
      match ts with
      | [ p ] -> Printf.sprintf "%s -> %s" (string_of_type p) (string_of_type t)
      | ts ->
          let ts = String.concat ", " (List.map string_of_type ts) in
          Printf.sprintf "(%s) -> %s" ts (string_of_type t))
  | Tpoly str -> str
  | Trecord (ps, str, _) | Tvariant (ps, str, _) -> (
      match ps with
      | [] -> str
      | l ->
          let arg = String.concat ", " (List.map string_of_type l) in
          Printf.sprintf "%s(%s)" str arg)
  | Traw_ptr t -> Printf.sprintf "raw_ptr(%s)" (string_of_type t)

let is_struct = function
  | Trecord _ | Tvariant _ | Tfun _ | Tpoly _ -> true
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Traw_ptr _ -> false

let is_aggregate = function
  | Trecord _ | Tvariant _ -> true
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Traw_ptr _ | Tfun _
  | Tpoly _ ->
      false
