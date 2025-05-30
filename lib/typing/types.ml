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
  | Tvar of tv ref
  | Qvar of string
  | Tfun of param list * typ * fun_kind
  | Ttuple of typ list
  | Tconstr of
      Path.t
      * typ list
      * bool (* contains allocations in unparameterized parts *)
  | Tfixed_array of iv ref * typ
[@@deriving show { with_path = false }, sexp]

and fun_kind = Simple | Closure of closed list
and tv = Unbound of string * int | Link of typ
and param = { pt : typ; pattr : dattr; pmode : mode }
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
and mode = Many | Once

type type_decl = {
  params : typ list;
  kind : decl_kind;
  in_sgn : bool;
  contains_alloc : bool;
}

and recursive = {
  is_recursive : bool;
  has_base : bool;
  params_behind_ptr : bool;
}

and decl_kind =
  | Drecord of recursive * field array
  | Dvariant of recursive * ctor array
  | Dabstract of decl_kind option
  | Dalias of typ
[@@deriving sexp, show]

let tunit = Tconstr (Pid "unit", [], false)
and tint = Tconstr (Pid "int", [], false)
and tfloat = Tconstr (Pid "float", [], false)
and ti32 = Tconstr (Pid "i32", [], false)
and tu32 = Tconstr (Pid "u32", [], false)
and tf32 = Tconstr (Pid "f32", [], false)
and tbool = Tconstr (Pid "bool", [], false)
and tu8 = Tconstr (Pid "u8", [], false)
and ti8 = Tconstr (Pid "i8", [], false)
and tu16 = Tconstr (Pid "u16", [], false)
and ti16 = Tconstr (Pid "i16", [], false)
and tarray typ = Tconstr (Pid "array", [ typ ], true)
and traw_ptr typ = Tconstr (Pid "raw_ptr", [ typ ], false)
and trc typ = Tconstr (Pid "rc", [ typ ], true)
and tweak_rc typ = Tconstr (Pid "weak_rc", [ typ ], true)

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
        Printf.sprintf "fun (%s) -> %s" ps (string_of_type t)
    | Tvar { contents = Link t } -> string_of_type t
    | Ttuple ts ->
        let lst = List.map string_of_type ts in
        Printf.sprintf "(%s)" (String.concat ", " lst)
    | Tconstr (name, ps, _) -> begin
        match ps with
        | [] -> Path.(rm_name mname name |> show)
        | l ->
            let arg = String.concat ", " (List.map string_of_type l) in
            Printf.sprintf "%s[%s]" Path.(rm_name mname name |> show) arg
      end
    | Qvar str | Tvar { contents = Unbound (str, _) } -> get_name str
    | Tfixed_array ({ contents = sz }, t) ->
        let rec size = function
          | Unknown _ -> "??"
          | Generalized _ -> "?"
          | Known i -> string_of_int i
          | Linked iv -> size !iv
        in
        sprintf "array#%s[%s]" (size sz) (string_of_type t)
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

let fold_builtins f init =
  List.fold_left
    (fun acc -> function
      | Tconstr (Pid name, params, contains_alloc) ->
          f acc name
            { params; in_sgn = false; kind = Dabstract None; contains_alloc }
      | _ -> failwith "unreachable")
    init
    [
      tint;
      tbool;
      tunit;
      tfloat;
      ti8;
      tu8;
      ti16;
      tu16;
      ti32;
      tu32;
      tf32;
      tarray (Qvar "0");
      traw_ptr (Qvar "0");
      trc (Qvar "0");
      tweak_rc (Qvar "0");
    ]

let is_builtin = function
  | Tconstr
      ( Pid
          ( "int" | "bool" | "unit" | "float" | "u8" | "u16" | "i32" | "f32"
          | "i8" | "i16" | "u32" | "array" | "raw_ptr" | "rc" | "weak_rc" ),
        _,
        _ ) ->
      true
  | _ -> false

let is_polymorphic typ =
  let rec inner acc = function
    | Qvar _ | Tvar { contents = Unbound _ } -> true
    | Tvar { contents = Link t } -> inner acc t
    | Ttuple ts | Tconstr (_, ts, _) -> List.fold_left inner acc ts
    | Tfun (params, ret, _) ->
        let acc = List.fold_left (fun b p -> inner b p.pt) acc params in
        inner acc ret
    | Tfixed_array ({ contents = Unknown _ | Generalized _ }, _) -> true
    | Tfixed_array ({ contents = Known _ }, t) -> inner acc t
    | Tfixed_array ({ contents = Linked iv }, t) ->
        inner acc (Tfixed_array (iv, t))
  in
  inner false typ

let rec is_weak ~sub = function
  | Qvar _ -> false
  | Tvar { contents = Link t } -> is_weak ~sub t
  | Tvar { contents = Unbound (id, _) } -> not (Sset.mem id sub)
  | Ttuple ts | Tconstr (_, ts, _) ->
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

let is_poly_orphan ~sub t =
  let rec aux contained = function
    | Qvar id | Tvar { contents = Unbound (id, _) } ->
        contained && not (Sset.mem id sub)
    | Tvar { contents = Link t } -> aux contained t
    | Ttuple ts | Tconstr (_, ts, _) ->
        List.fold_left (fun b t -> b || aux true t) false ts
    | Tfixed_array (_, t) -> aux true t
    | Tfun (ps, ret, _) when contained ->
        aux contained ret
        || List.fold_left (fun b p -> b || aux contained p.pt) false ps
    | Tfun _ -> false
  in
  aux false t

let map_params ~inst ~params =
  try
    List.fold_left2
      (fun sub inst q ->
        let str =
          match q with
          | Qvar s -> s
          | t ->
              print_endline (show_typ t);
              failwith "Internal Error: Not a qvara"
        in
        Smap.add str inst sub)
      Smap.empty inst params
  with Invalid_argument _ -> failwith "Internal Error: Params don't match"

let rec map_lazy ~inst sub typ =
  let rec map ~inst sub ps =
    match (inst, ps) with
    | [], _ -> ([], sub)
    | inst, Tvar { contents = Link t } :: tl -> map ~inst sub (t :: tl)
    | t :: inst, (Tvar { contents = Unbound (id, _) } | Qvar id) :: tl ->
        map ~inst (Smap.add id t sub) tl
    | inst, (Tconstr _ as t) :: tl ->
        let inst, sub = map_lazy ~inst sub t in
        map ~inst sub tl
    | inst, [] -> (inst, sub)
    | inst, _ :: tl -> map ~inst sub tl
  in

  match repr typ with Tconstr (_, ps, _) -> map ~inst sub ps | _ -> (inst, sub)

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
  | Tconstr (name, ps, alloc) ->
      let ps = List.map (subst_generic ~id typ) ps in
      Tconstr (name, ps, alloc)
  | Tfixed_array (i, t) -> Tfixed_array (i, subst_generic ~id typ t)
  | t -> t

let rec get_generic_ids = function
  | Qvar id | Tvar { contents = Unbound (id, _) } -> [ id ]
  | Tconstr (_, ts, _) | Ttuple ts -> List.map get_generic_ids ts |> List.concat
  | Tvar { contents = Link t } -> get_generic_ids t
  | Tfixed_array (_, t) -> get_generic_ids t
  | Tfun (ps, ret, _) ->
      (* Use set to dedup *)
      let s =
        List.fold_left
          (fun l p -> Sset.union l (Sset.of_list (get_generic_ids p.pt)))
          (Sset.of_list (get_generic_ids ret))
          ps
      in
      Sset.to_seq s |> List.of_seq

let typ_of_decl decl name =
  match decl.kind with
  | Drecord _ | Dvariant _ | Dabstract _ ->
      Tconstr (name, decl.params, decl.contains_alloc)
  | Dalias typ -> typ

let resolve_alias find_decl typ =
  let rec aux = function
    | (Tvar { contents = Unbound _ } | Qvar _) as t -> t
    | Ttuple ts -> Ttuple (List.map aux ts)
    | Tfun (ps, ret, kind) ->
        let ps = List.map (fun p -> { p with pt = aux p.pt }) ps in
        let ret = aux ret in
        let kind =
          match kind with
          | Simple -> kind
          | Closure cls ->
              Closure (List.map (fun c -> { c with cltyp = aux c.cltyp }) cls)
        in
        Tfun (ps, ret, kind)
    | Tconstr (name, ps, alloc) -> (
        match find_decl name with
        | Some ({ kind = Dalias typ; _ }, _) ->
            (* We still have to deal with params *)
            typ
        | _ ->
            let ps = List.map aux ps in
            Tconstr (name, ps, alloc))
    | Tfixed_array (s, t) -> Tfixed_array (s, aux t)
    | Tvar ({ contents = Link typ } as tv) as t ->
        let typ = aux typ in
        tv := Link typ;
        t
  in
  aux typ

let merge_rec a b =
  (* Merge is_recursive info, otherwise take b *)
  match (a, b) with
  | Ok a, Ok b ->
      let is_recursive = a.is_recursive || b.is_recursive in
      Ok { b with is_recursive }
  | Error _, _ -> a
  | _, Error _ -> b

let combine a b =
  match (a, b) with
  | Ok a, Ok b ->
      let is_recursive = a.is_recursive || b.is_recursive
      and has_base = a.has_base && b.has_base
      and params_behind_ptr = a.params_behind_ptr && b.params_behind_ptr in
      Ok { is_recursive; has_base; params_behind_ptr }
  | Error _, _ -> a
  | _, Error _ -> b

let add a b =
  match (a, b) with
  | Ok a, Ok b ->
      let is_recursive = a.is_recursive || b.is_recursive
      and has_base = a.has_base || b.has_base
      and params_behind_ptr = a.params_behind_ptr || b.params_behind_ptr in
      Ok { is_recursive; has_base; params_behind_ptr }
  | Error _, _ -> a
  | _, Error _ -> b

let set_behind_ptr res =
  Result.map (fun st -> { st with params_behind_ptr = true }) res

let set_allowed res =
  Result.map
    (fun st -> { st with params_behind_ptr = true; has_base = true })
    res

(* There are two aspects needed for recursion to be allowed: *)
(* 1. The type most have a base case. Either the type itself has it (option) or
   it in inherited from used types. *)
(* 2. The recursion happens behind a pointer *)
let recursion_allowed (get_decl : Path.t -> type_decl) ~params name typ =
  let rec aux res = function
    | Ttuple ts ->
        let nres, ts =
          List.fold_left_map
            (fun accres t ->
              let nres, typ = aux res t in
              if is_polymorphic t then
                (* We only need to combine if the type is actually polymorphic *)
                (combine nres accres, typ)
              else (merge_rec accres nres, typ))
            res ts
        in
        (nres, Ttuple ts)
    | Tfun (ps, ret, kind) ->
        let nres, ps =
          List.fold_left_map
            (fun res p ->
              let nres, pt = aux res p.pt in
              (nres, { p with pt }))
            (set_allowed res) ps
        in
        let res, ret = aux nres ret in
        (res, Tfun (ps, ret, kind))
    | (Qvar _ | Tvar { contents = Unbound _ }) as t -> (res, t)
    | Tvar ({ contents = Link t } as rf) as tvr ->
        let nres, t = aux res t in
        rf := Link t;
        (nres, tvr)
    | Tfixed_array (sz, t) ->
        let nres, t = aux res t in
        (nres, Tfixed_array (sz, t))
    | Tconstr ((Pid ("array" | "raw_ptr") as name), [ t ], alloc) ->
        let nres, t = aux (set_allowed res) t in
        (nres, Tconstr (name, [ t ], alloc))
    | Tconstr ((Pid "rc" as name), [ t ], alloc) ->
        let nres, t = aux (set_behind_ptr res) t in
        (nres, Tconstr (name, [ t ], alloc))
    | Tconstr ((Pid "weak_rc" as name), [ t ], alloc) ->
        let nres, t = aux (set_behind_ptr res) t in
        (nres, Tconstr (name, [ t ], alloc))
    | Tconstr (n, ps, alloc) as t ->
        if Path.equal n name then
          match res with
          | Ok ({ params_behind_ptr = true; _ } as res) ->
              (Ok { res with is_recursive = true }, Tconstr (n, params, alloc))
          | _ -> (Error "Infinite type", t)
        else
          let base_res =
            let decl = get_decl n in
            let sub = map_params ~inst:ps ~params:decl.params in
            decl_allowed ~sub res decl.kind
          in
          let res, ps =
            List.fold_left_map
              (fun res t ->
                let newres, typ = aux base_res t in
                if is_polymorphic t then (combine res newres, typ)
                else (merge_rec res newres, typ))
              base_res ps
          in
          (res, Tconstr (n, ps, alloc))
  and decl_allowed ~sub res = function
    | Dalias typ -> aux res typ |> fst
    | Dabstract None -> res
    | Dabstract (Some kind) -> decl_allowed ~sub res kind
    | Drecord (meta, _) ->
        (* These are further down than [res], so we don't combine, but add. For
           instance, a rc[option[t]] is valid, even though option itself isn't
           behind a ptr.*)
        add (Ok meta) res
    | Dvariant (meta, _) -> add (Ok meta) res
  in

  let res, typ =
    aux
      (Ok { is_recursive = false; has_base = false; params_behind_ptr = false })
      typ
  in
  match res with
  | Ok ({ is_recursive = true; _ } as meta) -> Ok (meta, Some typ)
  | Ok ({ is_recursive = false; _ } as meta) -> Ok (meta, None)
  | Error _ as err -> err

let rec contains_allocation ?(poly = true) t =
  let rec aux = function
    | [] -> false
    | t :: tl -> if contains_allocation t then true else aux tl
  in
  match repr t with
  | Tvar { contents = Link t } ->
      (* Should be unreachable, but w/e *)
      contains_allocation t
  | Tvar { contents = Unbound _ } | Qvar _ -> poly
  | Tfun _ -> true
  | Ttuple ts -> aux ts
  | Tconstr (Pid "raw_ptr", _, _) -> false
  | Tconstr (_, ts, contains_alloc) -> contains_alloc || aux ts
  | Tfixed_array (_, t) -> contains_allocation t
