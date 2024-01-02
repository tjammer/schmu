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
  | Tabstract of typ list * Path.t * typ
  | Tfixed_array of iv ref * typ
[@@deriving show { with_path = false }, sexp]

and fun_kind = Simple | Closure of closed list
and tv = Unbound of string * int | Link of typ
and param = { pt : typ; pattr : dattr }
and field = { fname : string; ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }

and iv =
  | Unknown of string * int
  | Known of int
  | Generalized of string
  | Linked of iv ref

and closed = {
  clname : string;
  clmut : bool;
  cltyp : typ;
  clparam : bool;
  clmname : Path.t option;
  clcopy : bool; (* otherwise move *)
}

and dattr = Ast.decl_attr = Dmut | Dmove | Dnorm | Dset

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
  | Tabstract (ps, n, t) -> Tabstract (List.map clean ps, n, clean t)
  | Tarray t -> Tarray (clean t)
  | Tfixed_array (n, t) -> Tfixed_array (n, clean t)
  | (Tvar _ | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Qvar _) as t
    ->
      t

let pp_to_name name = "'" ^ name

let string_of_type_raw get_name typ mname =
  let open Printf in
  let rec string_of_type = function
    | Tint -> "int"
    | Tbool -> "bool"
    | Tunit -> "unit"
    | Tfloat -> "float"
    | Tu8 -> "u8"
    | Ti32 -> "i32"
    | Tf32 -> "f32"
    | Tfun (ts, t, _) ->
        let pattr = function
          | Dnorm -> ""
          | Dmut -> "&"
          | Dmove -> "!"
          | Dset -> "&"
        in
        let ps =
          match ts with
          | [] -> "unit"
          | ts ->
              String.concat ", "
                (List.map (fun p -> string_of_type p.pt ^ pattr p.pattr) ts)
        in
        Printf.sprintf "(%s) -> %s" ps (string_of_type t)
    | Tvar { contents = Link t } -> string_of_type t
    | Talias (name, t) ->
        Printf.sprintf "%s = %s"
          Path.(rm_name mname name |> show)
          (clean t |> string_of_type)
    | Qvar str | Tvar { contents = Unbound (str, _) } -> get_name str
    | Trecord (_, None, fs) ->
        let lst =
          Array.to_list fs |> List.map (fun f -> string_of_type f.ftyp)
        in
        Printf.sprintf "(%s)" (String.concat ", " lst)
    | Trecord (ps, Some str, _) | Tvariant (ps, str, _) -> (
        match ps with
        | [] -> Path.(rm_name mname str |> show)
        | l ->
            let arg = String.concat " " (List.map string_of_type l) in
            Printf.sprintf "%s(%s)" Path.(rm_name mname str |> show) arg)
    | Traw_ptr t -> Printf.sprintf "raw_ptr (%s)" (string_of_type t)
    | Tarray t -> Printf.sprintf "array(%s)" (string_of_type t)
    | Tfixed_array ({ contents = sz }, t) ->
        let rec size = function
          | Unknown _ -> "??"
          | Generalized _ -> "?"
          | Known i -> string_of_int i
          | Linked iv -> size !iv
        in
        sprintf "array#%s(%s)" (size sz) (string_of_type t)
    | Tabstract (ps, name, _) -> (
        match ps with
        | [] -> Path.(rm_name mname name |> show)
        | l ->
            let arg = String.concat " " (List.map string_of_type l) in
            Printf.sprintf "%s(%s)" Path.(rm_name mname name |> show) arg)
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

let string_of_type mname typ =
  string_of_type_raw (string_of_type_get_name Smap.empty) typ mname

let string_of_type_lit mname typ = string_of_type_raw pp_to_name typ mname

let string_of_type_subst subst mname typ =
  string_of_type_raw (string_of_type_get_name subst) typ mname

let create_string_of_type mname =
  let subst = string_of_type_get_name Smap.empty in
  fun typ -> string_of_type_raw subst typ mname

let is_polymorphic typ =
  let rec inner acc = function
    | Qvar _ | Tvar { contents = Unbound _ } -> true
    | Tvar { contents = Link t } | Talias (_, t) -> inner acc t
    | Trecord (_, None, fs) ->
        Array.fold_left (fun acc f -> inner acc f.ftyp) acc fs
    | Trecord (ps, _, _) | Tvariant (ps, _, _) | Tabstract (ps, _, _) ->
        List.fold_left inner acc ps
    | Tfun (params, ret, _) ->
        let acc = List.fold_left (fun b p -> inner b p.pt) acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Tu8 | Tfloat | Ti32 | Tf32 -> acc
    | Traw_ptr t | Tarray t -> inner acc t
    | Tfixed_array ({ contents = Unknown _ | Generalized _ }, _) -> true
    | Tfixed_array ({ contents = Known _ }, t) -> inner acc t
    | Tfixed_array ({ contents = Linked iv }, t) ->
        inner acc (Tfixed_array (iv, t))
  in
  inner false typ

let rec is_weak ~sub = function
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 | Qvar _ -> false
  | Tvar { contents = Link t } | Talias (_, t) | Tarray t | Traw_ptr t ->
      is_weak ~sub t
  | Tvar { contents = Unbound (id, _) } ->
      if Sset.mem id sub then false else true
  | Trecord (ps, _, _) | Tvariant (ps, _, _) | Tabstract (ps, _, _) ->
      List.fold_left (fun b t -> is_weak ~sub t || b) false ps
  | Tfixed_array ({ contents = Unknown _ }, _) -> true
  | Tfixed_array ({ contents = Linked l }, t) ->
      is_weak ~sub (Tfixed_array (l, t))
  | Tfixed_array (_, t) -> is_weak ~sub t
  | Tfun _ ->
      (* Function types can contain weak vars which will reify on call.
         Thus we skip functions here.
         I'm not sure if this leaves some weak variables undetected, but
         at least some are caught *)
      false

let rec extract_name_path = function
  | Trecord (_, Some n, _)
  | Tvariant (_, n, _)
  | Talias (n, _)
  | Tabstract (_, n, _) ->
      Some n
  | Tvar { contents = Link t } -> extract_name_path t
  | _ -> None

let rec contains_allocation = function
  | Tvar { contents = Link t } | Traw_ptr t | Talias (_, t) | Tabstract (_, _, t)
    ->
      contains_allocation t
  | Tarray _ -> true
  | Trecord (_, _, fs) ->
      Array.fold_left (fun ca f -> ca || contains_allocation f.ftyp) false fs
  | Tvariant (_, _, ctors) ->
      Array.fold_left
        (fun ca c ->
          match c.ctyp with Some t -> ca || contains_allocation t | None -> ca)
        false ctors
  | Tint | Tbool | Tunit | Tu8 | Tfloat | Ti32 | Tf32 -> false
  | Qvar _ | Tvar { contents = Unbound _ } ->
      (* We don't know yet *)
      true
  | Tfixed_array (_, t) -> contains_allocation t
  | Tfun _ ->
      (* TODO *)
      true

let mut_of_pattr = function Dmut | Dset -> true | Dnorm | Dmove -> false

let add_closure_copy clsd id =
  let changed, clsd =
    List.fold_left_map
      (fun changed c ->
        if String.equal c.clname id then (true, { c with clcopy = true })
        else (changed, c))
      false clsd
  in
  if changed then Some clsd else None
