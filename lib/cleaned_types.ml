type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tu16
  | Tfloat
  | Ti32
  | Tf32
  | Tpoly of string
  | Tfun of param list * typ * fun_kind
  | Trecord of typ list * field recurs_kind * string option
  | Tvariant of typ list * ctor recurs_kind * string
  | Traw_ptr of typ
  | Tarray of typ
  | Tfixed_array of int * typ
  | Trc of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of closed list
and param = { pt : typ; pmut : bool; pmoved : bool }
and field = { ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }
and 'a recurs_kind = Rec_not of 'a array | Rec_top of 'a array | Rec_folded

and closed = {
  clname : string;
  clmut : bool;
  cltyp : typ;
  clparam : bool;
  clcopy : bool;
}

let is_type_polymorphic typ =
  let rec inner acc = function
    | Tpoly _ -> true
    | Trecord (_, Rec_not fs, None) ->
        Array.fold_left (fun acc f -> inner acc f.ftyp) acc fs
    | Trecord (ps, _, _) | Tvariant (ps, _, _) -> List.fold_left inner acc ps
    | Tfun (params, ret, kind) ->
        let acc = List.fold_left (fun b p -> inner b p.pt) acc params in
        let acc =
          match kind with
          | Simple -> acc
          | Closure cls ->
              List.fold_left (fun acc cl -> inner acc cl.cltyp) acc cls
        in
        inner acc ret
    | Tbool | Tunit | Tint | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 -> acc
    | Tfixed_array (i, _) when i < 0 -> true
    | Traw_ptr t | Tarray t | Tfixed_array (_, t) | Trc t -> inner acc t
  in
  inner false typ

let rec string_of_type = function
  | Tint -> "int"
  | Tbool -> "bool"
  | Tunit -> "unit"
  | Tu8 -> "u8"
  | Tu16 -> "u16"
  | Tfloat -> "float"
  | Ti32 -> "i32"
  | Tf32 -> "f32"
  | Tfun (ts, t, _) ->
      let ps =
        String.concat " "
          (List.map
             (fun p -> string_of_type p.pt ^ if p.pmut then "&" else "")
             ts)
      in
      Printf.sprintf "(fun %s %s)" ps (string_of_type t)
  | Tpoly str -> str
  | Trecord (_, Rec_not fs, None) ->
      let lst = Array.to_list fs |> List.map (fun f -> string_of_type f.ftyp) in
      Printf.sprintf "{%s}" (String.concat " " lst)
  | Trecord (_, _, None) -> failwith "unreachable"
  | Trecord (ps, _, Some str) | Tvariant (ps, _, str) -> (
      match ps with
      | [] -> str
      | l ->
          let arg = String.concat " " (List.map string_of_type l) in
          Printf.sprintf "(%s %s)" str arg)
  | Traw_ptr t -> Printf.sprintf "(raw_ptr %s)" (string_of_type t)
  | Tarray t -> Printf.sprintf "(array %s)" (string_of_type t)
  | Tfixed_array (i, t) -> Printf.sprintf "(array#%i %s)" i (string_of_type t)
  | Trc t -> Printf.sprintf "(rc %s)" (string_of_type t)

let is_struct = function
  | Trecord _ | Tvariant _ | Tfun _ | Tpoly _ | Tfixed_array _ -> true
  | Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 | Traw_ptr _
  | Tarray _ | Trc _ ->
      false

let is_aggregate = function
  | Trecord _ | Tvariant _ | Tfixed_array _ -> true
  | Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 | Traw_ptr _
  | Tfun _ | Tpoly _ | Tarray _ | Trc _ ->
      false

let rec contains_allocation = function
  | Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 -> false
  | Tpoly _ | Tfun _ -> true
  | Trecord (_, Rec_not fs, _) ->
      Array.fold_left (fun ca f -> ca || contains_allocation f.ftyp) false fs
  | Tvariant (_, (Rec_folded | Rec_top _), _)
  | Trecord (_, (Rec_folded | Rec_top _), _) ->
      (* If the type is recursive there must be pointers involved, thus allocations *)
      true
  | Tvariant (_, Rec_not ctors, _) ->
      Array.fold_left
        (fun ca c ->
          match c.ctyp with Some t -> ca || contains_allocation t | None -> ca)
        false ctors
  | Traw_ptr _ -> false
  | Tarray _ | Trc _ -> true
  | Tfixed_array (_, t) -> contains_allocation t

let is_folded = function
  | Tvariant (_, Rec_folded, _) | Trecord (_, Rec_folded, _) -> true
  | _ -> false
