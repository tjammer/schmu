module Str = struct
  type t = string

  let hash = Hashtbl.hash
  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)
module Smap = Map.Make (String)
module Sset = Set.Make (String)
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
  | Tfun of param list * typ * fun_kind
  | Talias of Path.t * typ
  | Trecord of typ list * Path.t option * field array
  | Tvariant of typ list * Path.t * ctor array
  | Traw_ptr of typ
  | Tarray of typ
[@@deriving show { with_path = false }, sexp]

and fun_kind = Simple | Closure of closed list
and tv = Unbound of string * int | Link of typ
and param = { pt : typ; pmut : bool }
and field = { fname : string; ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }
and closed = { clname : string; clmut : bool; cltyp : typ; clparam : bool }

let rec clean = function
  | Tvar { contents = Link t } -> clean t
  | Tfun (params, ret, Closure vals) ->
      let vals = List.map (fun cl -> { cl with cltyp = clean cl.cltyp }) vals in
      Tfun
        ( List.map (fun p -> { p with pt = clean p.pt }) params,
          clean ret,
          Closure vals )
  | Tfun (params, ret, kind) ->
      Tfun
        (List.map (fun p -> { p with pt = clean p.pt }) params, clean ret, kind)
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
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Traw_ptr _ | Tarray _ ->
      false

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
        let ps =
          String.concat " "
            (List.map
               (fun p -> string_of_type p.pt ^ if p.pmut then "&" else "")
               ts)
        in
        Printf.sprintf "(fun %s %s)" ps (string_of_type t)
    | Tvar { contents = Link t } -> string_of_type t
    | Talias (name, t) ->
        Printf.sprintf "%s = %s" (Path.show name) (clean t |> string_of_type)
    | Qvar str | Tvar { contents = Unbound (str, _) } -> get_name str
    | Trecord (_, None, fs) ->
        let lst =
          Array.to_list fs |> List.map (fun f -> string_of_type f.ftyp)
        in
        Printf.sprintf "{%s}" (String.concat " " lst)
    | Trecord (ps, Some str, _) | Tvariant (ps, str, _) -> (
        match ps with
        | [] -> Path.show str
        | l ->
            let arg = String.concat " " (List.map string_of_type l) in
            Printf.sprintf "(%s %s)" (Path.show str) arg)
    | Traw_ptr t -> Printf.sprintf "(raw_ptr %s)" (string_of_type t)
    | Tarray t -> Printf.sprintf "(array %s)" (string_of_type t)
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
    | Trecord (_, None, fs) ->
        Array.fold_left (fun acc f -> inner acc f.ftyp) acc fs
    | Trecord (ps, _, _) | Tvariant (ps, _, _) -> List.fold_left inner acc ps
    | Tfun (params, ret, _) ->
        let acc = List.fold_left (fun b p -> inner b p.pt) acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Tu8 | Tfloat | Ti32 | Tf32 -> acc
    | Traw_ptr t | Tarray t -> inner acc t
  in
  inner false typ

let rec is_weak ~sub = function
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Qvar _ -> false
  | Tvar { contents = Link t } | Talias (_, t) | Tarray t | Traw_ptr t ->
      is_weak ~sub t
  | Tvar { contents = Unbound (id, _) } ->
      if Sset.mem id sub then false else true
  | Trecord (ps, _, _) | Tvariant (ps, _, _) ->
      List.fold_left (fun b t -> is_weak ~sub t || b) false ps
  | Tfun _ ->
      (* Function types can contain weak vars which will reify on call.
         Thus we skip functions here.
         I'm not sure if this leaves some weak variables undetected, but
         at least some are caught *)
      false
