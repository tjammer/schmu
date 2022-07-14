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
  | Trecord of typ option * string * field array
  | Tvariant of typ option * string * ctor array
  | Tptr of typ
[@@deriving show { with_path = false }, sexp]

and fun_kind = Simple | Closure of (string * typ) list
and tv = Unbound of string * int | Link of typ
and field = { name : string; typ : typ; mut : bool }
and ctor = { ctorname : string; ctortyp : typ option }

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
  | Tvariant (param, name, ctors) ->
      let param = Option.map clean param in
      Tvariant
        ( param,
          name,
          Array.map
            (fun ctor -> { ctor with ctortyp = Option.map clean ctor.ctortyp })
            ctors )
  | Talias (_, t) -> clean t
  | Tptr t -> Tptr (clean t)
  | t -> t

let rec is_struct = function
  | Tvar { contents = Link t } | Talias (_, t) -> is_struct t
  | Trecord _ | Tvariant _ | Tfun _ | Qvar _ | Tvar { contents = Unbound _ } ->
      true
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Tptr _ -> false

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
    | Tfun (ts, t, _) -> (
        match ts with
        | [ p ] ->
            Printf.sprintf "%s -> %s" (string_of_type p) (string_of_type t)
        | ts ->
            let ts = String.concat ", " (List.map string_of_type ts) in
            Printf.sprintf "(%s) -> %s" ts (string_of_type t))
    | Tvar { contents = Link t } -> string_of_type t
    | Talias (name, t) ->
        Printf.sprintf "%s = %s" name (clean t |> string_of_type)
    | Qvar str | Tvar { contents = Unbound (str, _) } -> get_name str
    | Trecord (param, str, _) | Tvariant (param, str, _) ->
        str
        ^ Option.fold ~none:""
            ~some:(fun param -> Printf.sprintf "(%s)" (string_of_type param))
            param
    | Tptr t -> Printf.sprintf "ptr(%s)" (string_of_type t)
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
    | Trecord (Some t, _, _) | Tvariant (Some t, _, _) -> inner acc t
    | Tfun (params, ret, _) ->
        let acc = List.fold_left inner acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Trecord _ | Tvariant _ | Tu8 | Tfloat | Ti32 | Tf32
      ->
        acc
    | Tptr t -> inner acc t
  in
  inner false typ
