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
  | Tprim of primitive
  | Tvar of tv ref
  | Qvar of string
  | Tfun of param list * typ * fun_kind
  | Ttuple of typ list
  | Tconstr of Path.t * typ list
  | Traw_ptr of typ
  | Tarray of typ
  | Tfixed_array of iv ref * typ
  | Trc of typ
[@@deriving show { with_path = false }, sexp]

and primitive = Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32
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

type type_decl = { params : typ list; kind : decl_kind; in_sgn : bool }

and decl_kind =
  | Drecord of field array
  | Dvariant of typ option * ctor array
  | Dabstract of typ option
  | Dalias of typ
[@@deriving sexp]

let tunit = Tprim Tunit
and tint = Tprim Tint
and tfloat = Tprim Tfloat
and ti32 = Tprim Ti32
and tf32 = Tprim Tf32
and tbool = Tprim Tbool
and tu8 = Tprim Tu8
and tu16 = Tprim Tu16

let rec repr = function
  (* Do path compression *)
  | Tvar ({ contents = Link t } as tvr) ->
      let t = repr t in
      tvr := Link t;
      t
  | t -> t

let pp_to_name name = "'" ^ name

let string_of_type_raw get_name typ mname =
  let open Printf in
  let rec string_of_type = function
    | Tprim Tint -> "int"
    | Tprim Tbool -> "bool"
    | Tprim Tunit -> "unit"
    | Tprim Tfloat -> "float"
    | Tprim Tu8 -> "u8"
    | Tprim Tu16 -> "u16"
    | Tprim Ti32 -> "i32"
    | Tprim Tf32 -> "f32"
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
    | Ttuple ts ->
        let lst = List.map string_of_type ts in
        Printf.sprintf "(%s)" (String.concat ", " lst)
    | Tconstr (name, ps) -> begin
        match ps with
        | [] -> Path.(rm_name mname name |> show)
        | l ->
            let arg = String.concat ", " (List.map string_of_type l) in
            Printf.sprintf "%s(%s)" Path.(rm_name mname name |> show) arg
      end
    | Qvar str | Tvar { contents = Unbound (str, _) } -> get_name str
    | Traw_ptr t -> Printf.sprintf "raw_ptr(%s)" (string_of_type t)
    | Tarray t -> Printf.sprintf "array(%s)" (string_of_type t)
    | Tfixed_array ({ contents = sz }, t) ->
        let rec size = function
          | Unknown _ -> "??"
          | Generalized _ -> "?"
          | Known i -> string_of_int i
          | Linked iv -> size !iv
        in
        sprintf "array#%s(%s)" (size sz) (string_of_type t)
    | Trc t -> Printf.sprintf "rc(%s)" (string_of_type t)
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

let string_of_type mname =
  let subst = string_of_type_get_name Smap.empty in
  (* Returning a closure makes it possible to create the substitution and use it
     multiple times for different types. This is used in [format_type_err] *)
  fun typ -> string_of_type_raw subst typ mname

let is_polymorphic typ =
  let rec inner acc = function
    | Qvar _ | Tvar { contents = Unbound _ } -> true
    | Tvar { contents = Link t } -> inner acc t
    | Ttuple ts | Tconstr (_, ts) -> List.fold_left inner acc ts
    | Tfun (params, ret, _) ->
        let acc = List.fold_left (fun b p -> inner b p.pt) acc params in
        inner acc ret
    | Tprim _ -> acc
    | Traw_ptr t | Tarray t | Trc t -> inner acc t
    | Tfixed_array ({ contents = Unknown _ | Generalized _ }, _) -> true
    | Tfixed_array ({ contents = Known _ }, t) -> inner acc t
    | Tfixed_array ({ contents = Linked iv }, t) ->
        inner acc (Tfixed_array (iv, t))
  in
  inner false typ

let rec is_weak ~sub = function
  | Tprim _ | Qvar _ -> false
  | Tvar { contents = Link t } | Tarray t | Traw_ptr t | Trc t -> is_weak ~sub t
  | Tvar { contents = Unbound (id, _) } ->
      if Sset.mem id sub then false else true
  | Ttuple ts | Tconstr (_, ts) ->
      List.fold_left (fun b t -> is_weak ~sub t || b) false ts
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

let rec contains_allocation = function
  | Tvar { contents = Link t } | Traw_ptr t -> contains_allocation t
  | Tarray _ | Trc _ -> true
  | Ttuple ts | Tconstr (_, ts) ->
      List.fold_left (fun ca t -> ca || contains_allocation t) false ts
  | Tprim _ -> false
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

let is_clike_variant ctors =
  Array.fold_left
    (fun clike ctor -> if Option.is_some ctor.ctyp then false else clike)
    true ctors

let is_unbound t =
  match repr t with
  | Tvar { contents = Unbound (sym, l) } -> Some (sym, l)
  | _ -> None

let rec subst_generic ~id typ = function
  (* Substitute generic var [id] with [typ] *)
  | Tvar { contents = Link t } -> subst_generic ~id typ t
  | (Qvar id' | Tvar { contents = Unbound (id', _) }) when String.equal id id'
    ->
      typ
  | Tfun (ps, ret, kind) ->
      let ps =
        List.map
          (fun p ->
            let pt = subst_generic ~id typ p.pt in
            { p with pt })
          ps
      in
      let ret = subst_generic ~id typ ret in
      Tfun (ps, ret, kind)
  | Ttuple ts -> Ttuple (List.map (subst_generic ~id typ) ts)
  | Tconstr (name, ps) ->
      let ps = List.map (subst_generic ~id typ) ps in
      Tconstr (name, ps)
  | Traw_ptr t -> Traw_ptr (subst_generic ~id typ t)
  | Tarray t -> Tarray (subst_generic ~id typ t)
  | Trc t -> Trc (subst_generic ~id typ t)
  | Tfixed_array (i, t) -> Tfixed_array (i, subst_generic ~id typ t)
  | t -> t

let rec get_generic_ids = function
  | Qvar id | Tvar { contents = Unbound (id, _) } -> [ id ]
  | Tconstr (_, ts) | Ttuple ts -> List.map get_generic_ids ts |> List.concat
  | Tvar { contents = Link t } -> get_generic_ids t
  | Tarray t | Traw_ptr t | Trc t | Tfixed_array (_, t) -> get_generic_ids t
  | Tfun (ps, ret, _) ->
      List.fold_left
        (fun l p -> get_generic_ids p.pt @ l)
        (get_generic_ids ret) ps
  | _ -> []
