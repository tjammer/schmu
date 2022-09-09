module Str = struct
  type t = string

  let hash = Hashtbl.hash
  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)
module Smap = Map.Make (String)
open Sexplib0.Sexp_conv

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
  | Trecord of typ list * string option * field array
  | Tvariant of typ list * string * ctor array
  | Traw_ptr of typ
[@@deriving show { with_path = false }, sexp]

and fun_kind = Simple | Closure of (string * typ) list
and tv = Unbound of string * int | Link of typ
and field = { fname : string; ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }

let rec clean = function
  | Tvar { contents = Link t } -> clean t
  | Tfun (params, ret, Closure vals) ->
      let vals = List.map (fun (name, typ) -> (name, clean typ)) vals in
      Tfun (List.map clean params, clean ret, Closure vals)
  | Tfun (params, ret, kind) -> Tfun (List.map clean params, clean ret, kind)
  | Trecord (params, name, fields) ->
      let params = List.map clean params in
      Trecord
        ( params,
          name,
          Array.map (fun field -> { field with ftyp = clean field.ftyp }) fields
        )
  | Tvariant (params, name, ctors) ->
      let params = List.map clean params in
      Tvariant
        ( params,
          name,
          Array.map
            (fun ctor -> { ctor with ctyp = Option.map clean ctor.ctyp })
            ctors )
  | Talias (_, t) -> clean t
  | Traw_ptr t -> Traw_ptr (clean t)
  | t -> t

let rec is_struct = function
  | Tvar { contents = Link t } | Talias (_, t) -> is_struct t
  | Trecord _ | Tvariant _ | Tfun _ | Qvar _ | Tvar { contents = Unbound _ } ->
      true
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Traw_ptr _ -> false

let pp_to_name name = "'" ^ name

let string_of_type_raw get_name typ =
  let rec string_of_type = function
    | Tint -> "int"
    | Tbool -> "bool"
    | Tunit -> "unit"
    | Tfloat -> "float"
    | Tu8 -> "u8"
    | Ti32 -> "i32"
    | Tf32 -> "f32"
    | Tfun (ts, t, _) ->
        let ps = String.concat " " (List.map string_of_type ts) in
        Printf.sprintf "(fun %s %s)" ps (string_of_type t)
    | Tvar { contents = Link t } -> string_of_type t
    | Talias (name, t) ->
        Printf.sprintf "%s = %s" name (clean t |> string_of_type)
    | Qvar str | Tvar { contents = Unbound (str, _) } -> get_name str
    | Trecord (_, None, fs) ->
        let lst =
          Array.to_list fs |> List.map (fun f -> string_of_type f.ftyp)
        in
        Printf.sprintf "{%s}" (String.concat " " lst)
    | Trecord (ps, Some str, _) | Tvariant (ps, str, _) -> (
        match ps with
        | [] -> str
        | l ->
            let arg = String.concat " " (List.map string_of_type l) in
            Printf.sprintf "(%s %s)" str arg)
    | Traw_ptr t -> Printf.sprintf "(raw_ptr %s)" (string_of_type t)
  in

  string_of_type typ

(* Bring type vars into canonical form so the first one is "'a" etc.
   Only used for printing purposes *)
let string_of_type_get_name subst =
  let find_next_letter tbl =
    (* Find greatest letter *)
    Strtbl.fold
      (fun _ s acc ->
        let code = String.get s 0 |> Char.code in
        if code > acc then code else acc)
      tbl
      (Char.code 'a' |> fun i -> i - 1)
    |> (* Pick next letter *)
    ( + ) 1 |> Char.chr |> String.make 1
  in

  let tbl = Strtbl.of_seq (Smap.to_seq subst) in
  fun name ->
    match Strtbl.find_opt tbl name with
    | Some s -> pp_to_name s
    | None ->
        let s = find_next_letter tbl in
        Strtbl.add tbl name s;
        pp_to_name s

let string_of_type typ =
  string_of_type_raw (string_of_type_get_name Smap.empty) typ

let string_of_type_lit typ = string_of_type_raw pp_to_name typ

let string_of_type_subst subst typ =
  string_of_type_raw (string_of_type_get_name subst) typ

let is_polymorphic typ =
  let rec inner acc = function
    | Qvar _ | Tvar { contents = Unbound _ } -> true
    | Tvar { contents = Link t } | Talias (_, t) -> inner acc t
    | Trecord (ps, _, _) | Tvariant (ps, _, _) -> List.fold_left inner acc ps
    | Tfun (params, ret, _) ->
        let acc = List.fold_left inner acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Tu8 | Tfloat | Ti32 | Tf32 -> acc
    | Traw_ptr t -> inner acc t
  in
  inner false typ
