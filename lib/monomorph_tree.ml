open Cleaned_types
open Malloc_types
module Vars = Map.Make (String)
module Iset = Set.Make (Int)
module Apptbl = Hashtbl

type expr =
  | Mvar of string * var_kind
  | Mconst of const
  | Mbop of Ast.bop * monod_tree * monod_tree
  | Munop of Ast.unop * monod_tree
  | Mif of ifexpr
  | Mlet of
      string * monod_tree * let_kind * global_name * malloc_list * monod_tree
  | Mbind of string * monod_tree * monod_tree
  | Mlambda of string * abstraction * alloca
  | Mfunction of string * abstraction * monod_tree * alloca
  | Mapp of {
      callee : monod_expr;
      args : (monod_expr * bool) list;
      alloca : alloca;
      id : int;
      ms : malloc_list;
    }
  | Mrecord of (string * monod_tree) list * alloca * malloc_list * bool
  | Mfield of (monod_tree * int)
  | Mset of (monod_tree * monod_tree * bool)
  | Mseq of (monod_tree * monod_tree)
  | Mctor of (string * int * monod_tree option) * alloca * malloc_list * bool
  | Mvar_index of monod_tree
  | Mvar_data of monod_tree * int option
  | Mfmt of fmt list * alloca * int
  | Mprint_str of fmt list
  | Mfree_after of monod_tree * free_list
[@@deriving show]

and const =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Array of monod_tree list * alloca * int
  | Unit

and func = { params : param list; ret : typ; kind : fun_kind }

and abstraction = {
  func : func;
  pnames : (string * int option) list;
  body : monod_tree;
}

and call_name =
  | Mono of string
  | Concrete of string
  | Default
  | Recursive of { nonmono : string; call : string }
  | Builtin of Builtin.t * func
  | Inline of (string * int option) list * monod_tree

and monod_expr = { ex : monod_tree; monomorph : call_name; mut : bool }
and monod_tree = { typ : typ; expr : expr; return : bool; loc : Ast.loc }
and alloca = allocas ref
and request = { id : int; lvl : int }
and allocas = Preallocated | Request of request

and ifexpr = {
  cond : monod_tree;
  owning : int option;
  e1 : monod_tree;
  e2 : monod_tree;
}

and var_kind = Vnorm | Vconst | Vglobal of string
and global_name = string option
and fmt = Fstr of string | Fexpr of monod_tree
and copy_kind = Cglobal of string | Cnormal of bool
and malloc_list = int list
and free_list = Except of malloc_id list | Only of malloc_id list
and let_kind = Lowned | Lborrow

type recurs = Rnormal | Rtail | Rnone
type func_name = { user : string; call : string }

type external_decl = {
  ext_name : string;
  ext_typ : typ;
  cname : string;
  c_linkage : bool;
  closure : bool;
}

type to_gen_func = {
  abs : abstraction;
  name : func_name;
  recursive : recurs;
  upward : unit -> bool;
  monomorphized : bool;
}

module To_gen_func = struct
  type t = to_gen_func

  let compare a b = String.compare a.name.call b.name.call
end

module Fset = Set.Make (To_gen_func)
module Sset = Set.Make (String)

type monomorphized_tree = {
  constants : (string * monod_tree * bool) list;
  globals : (string * typ * bool) list;
  externals : external_decl list;
  tree : monod_tree;
  funcs : To_gen_func.t list;
  frees : malloc_id Seq.t;
}

type to_gen_func_kind =
  (* TODO use a prefix *)
  | Concrete of To_gen_func.t * string
  | Polymorphic of string (* call name *)
  | Forward_decl of string * typ
  | Mutual_rec of string * typ
  | Builtin of Builtin.t
  | Inline of (string * int option) list * typ * monod_tree
  | No_function

type alloc = Value of alloca | Two_values of alloc * alloc | No_value
type malloc_scope = Mfunc | Mlocal

let malloc_add_index index = function
  | Malloc.No_malloc -> Malloc.No_malloc
  | Path (m, p) -> Path (m, p @ [ index ])
  | (Single _ | Branch _) as m -> Path (m, [ index ])

let m_to_list = function
  | Malloc.No_malloc -> []
  | Single i -> [ i.mid ]
  | Branch _ ->
      (* Handled in If *)
      []
  | Path _ -> failwith "Internal Error: Path not supported here"

type pmap = Pset.t Imap.t

let mlist_of_pmap m =
  Imap.to_rev_seq m
  |> Seq.map (fun ((id : Mid.t), paths) ->
         { id = id.mid; mtyp = id.typ; paths })
  |> List.of_seq

let show_pmap m =
  Imap.to_seq m
  |> Seq.map (fun ((i : Mid.t), set) ->
         Printf.sprintf "%i: (%s)" i.mid (show_pset set))
  |> List.of_seq |> String.concat "\n"

let mapdiff ?(flip = true) a b =
  ignore show_pmap;
  Imap.merge
    (fun _ a b ->
      match (a, b) with
      | Some a, Some b ->
          if Pset.is_empty b then None
          else
            (* The order here is switched, we want new moved things to appear *)
            let diff = if flip then Pset.diff b a else Pset.diff a b in
            if Pset.is_empty diff then None else Some diff
      | None, Some _ | None, None -> None
      | Some v, None -> Some v)
    a b

let mapdiff_flip a b = mapdiff ~flip:false a b

let mapunion a b =
  Imap.merge
    (fun _ a b ->
      match (a, b) with
      | Some a, Some b -> Some (Pset.union a b)
      | Some a, None -> Some a
      | None, Some b -> Some b
      | None, None -> None)
    a b

let mk_free_after expr frees =
  (* Delete paths if all allocating members are excluded *)
  let rec is_excluded frees typ =
    if Pset.is_empty frees then (false, frees)
    else
      match typ with
      | Trecord (_, _, fs) ->
          let _, excluded, pset =
            Array.fold_left
              (fun (i, exh, pset) f ->
                if contains_allocation f.ftyp then
                  match pop_index_pset frees i with
                  | Not_excl -> (i + 1, false, pset)
                  | Excl -> (i + 1, exh && true, Pset.add [ i ] pset)
                  | Followup frees ->
                      let nexcluded, npset = is_excluded frees f.ftyp in
                      let npset =
                        if nexcluded then pset
                        else Pset.map (fun l -> i :: l) npset
                      in
                      (i + 1, exh && nexcluded, npset)
                else (i + 1, exh, pset))
              (0, true, Pset.empty) fs
          in
          (excluded, pset)
      | _ -> failwith "todo exh"
  in
  let frees =
    List.filter_map
      (fun free ->
        let excluded, paths = is_excluded free.paths free.mtyp in
        if excluded then None else Some { free with paths })
      frees
  in
  match frees with
  | [] -> expr
  | frees -> { expr with expr = Mfree_after (expr, Except frees) }

module Mallocs : sig
  type t

  val empty : malloc_scope -> t
  val push : malloc_scope -> t -> t
  val pop : t -> malloc_id list * t
  val mem : Malloc.t -> t -> bool
  val add : Malloc.t -> t -> t
  val remove : Malloc.t -> t -> t
  val reenter : Malloc.t -> t -> t
  val remove_local : Malloc.t -> t -> t
  val empty_func : monod_tree -> t -> t * monod_tree
  val diff_func : t -> t -> Pset.t Imap.t
end = struct
  (* type pmap = Pset.t Imap.t *)
  open Malloc

  type t = (malloc_scope * pmap) list

  let empty scope = [ (scope, Imap.empty) ]
  let push kind ms = (kind, Imap.empty) :: ms
  let pop = function (_, ms) :: tl -> (mlist_of_pmap ms, tl) | [] -> ([], [])

  let mem a ms =
    let rec aux a ms path =
      match (a, ms) with
      | _, [] -> false
      | Branch { fst; snd }, _ -> aux fst ms path && aux snd ms path
      | Single i, (_, ms) :: tl ->
          let mem =
            match Imap.find_opt i ms with
            | Some pset -> (
                match path with [] -> true | path -> Pset.mem path pset |> not)
            | None -> false
          in
          mem || aux a tl path
      | No_malloc, _ -> false
      | Path (a, l), _ ->
          (* Order of appending paths is important *)
          aux a ms (l @ path)
    in
    aux a ms []

  let add a ms =
    match (a, ms) with
    | _, [] -> failwith "Internal Error: Empty ids"
    | Branch { fst; snd }, _ ->
        (* These are for borrowed values. Borrowed values should already be part of the
           mallocs env. There maybe is a special case for string literals here *)
        assert (mem fst ms);
        assert (mem snd ms);
        ms
    | Single a, (scope, ms) :: tl -> (scope, Imap.add a Pset.empty ms) :: tl
    | No_malloc, _ -> ms
    | Path _, _ -> failwith "Internal Error: Trying to add pathed malloc"

  let reenter a ms =
    let rec aux a ms =
      match (a, ms) with
      | _, [] -> []
      | Branch _, _ -> failwith "Internal Error: Reenter branch"
      | Single a, (scope, ms) :: tl -> (scope, Imap.add a Pset.empty ms) :: tl
      | No_malloc, _ -> ms
      | Path (Single i, p), (scope, ms) :: tl ->
          let found, ms =
            match Imap.find_opt i ms with
            | Some pset -> (true, Imap.add i (Pset.remove p pset) ms)
            | None -> (false, ms)
          in
          if found then (scope, ms) :: tl else (scope, ms) :: aux a tl
      | Path _, _ -> failwith "Internal Error: Unexpected path"
    in
    aux a ms

  let remove a ms =
    let rec aux a path ms =
      match (a, ms) with
      | _, [] -> []
      | Branch { fst; snd }, _ -> aux fst path ms |> aux snd path
      | Single { parent = Some par; _ }, _
        when (not (mem par ms)) && not (mem a ms) ->
          (* Except when it has a parent and the parent is still part of the tail.
             Then it's about to be removed and the child part has to be added here. *)
          aux a path (add a ms)
      | Single i, (scope, ms) :: tl ->
          let ms =
            match path with
            | [] -> Imap.remove i ms
            | p -> (
                match Imap.find_opt i ms with
                | Some pset ->
                    (* Malloc id was found, mark path as moved in set *)
                    Imap.add i (Pset.add p pset) ms
                | None ->
                    (* Malloc id isn't part of this scope, do nothing *)
                    ms)
          in
          (* If the malloc has a parent, it's a variant.
             The variant must be removed as a whole from the tail *)
          let tl =
            match i.parent with Some par -> aux par [] tl | None -> tl
          in
          (scope, ms) :: aux a path tl
      | No_malloc, _ -> ms
      | Path (a, l), _ -> aux a (l @ path) ms
    in
    aux a [] ms

  let rec remove_local a ms =
    let rec aux a path ms =
      match (a, ms) with
      | _, [] -> []
      | Branch { fst; snd }, _ -> remove_local fst ms |> remove_local snd
      | Single ({ parent = Some par; _ } as i), (_, ms') :: _
        when (not (mem par ms)) && not (Imap.mem i ms') ->
          (* Except when it has a parent and the parent is still part of the tail.
             Then it's about to be removed and the child part has to be added here. *)
          aux a path (add a ms)
      | Single i, (scope, ms) :: tl ->
          let ms =
            match path with
            | [] -> Imap.remove i ms
            | p -> (
                match Imap.find_opt i ms with
                | Some pset -> Imap.add i (Pset.add p pset) ms
                | None -> ms)
          in
          let tl =
            match i.parent with Some par -> aux par [] tl | None -> tl
          in
          (scope, ms) :: tl
      | No_malloc, _ -> ms
      | Path (a, l), _ -> aux a (l @ path) ms
    in
    aux a [] ms

  let rec empty_func body = function
    | [] -> ([], body)
    | (Mlocal, s) :: tl ->
        let frees = mlist_of_pmap s in
        let tl, body = empty_func (mk_free_after body frees) tl in
        ((Mlocal, Imap.empty) :: tl, body)
    | (Mfunc, s) :: tl ->
        let frees = mlist_of_pmap s in
        ((Mfunc, Imap.empty) :: tl, mk_free_after body frees)

  let diff_func a b =
    (* TODO take paths into account *)
    let rec aux acc a b =
      match (a, b) with
      | (Mlocal, a) :: atl, (Mlocal, b) :: btl ->
          aux (mapunion acc (mapdiff a b)) atl btl
      | (Mfunc, a) :: _, (Mfunc, b) :: _ -> mapunion acc (mapdiff a b)
      | _ -> failwith "Internal Error: Mismatch in scope"
    in
    aux Imap.empty a b
end

type var_normal = {
  fn : to_gen_func_kind;
  alloc : alloc;
  malloc : Malloc.t;
  tailrec : bool;
}

(* TODO could be used for Builtin as well *)
type var =
  | Normal of var_normal
  | Const of string
  | Global of string * var_normal * bool ref
  | Param of var_normal

type morph_param = {
  vars : var Vars.t;
  monomorphized : Sset.t;
  funcs : Fset.t; (* to generate in codegen *)
  ret : bool;
  (* Marks an expression where an if is the last piece which returns a record.
     Needed for tail call elim *)
  mallocs : Mallocs.t;
      (* Tracks all heap allocations in a scope.
         If a value with allocation is returned, they are marked for the parent scope.
         Otherwise freed *)
  toplvl : bool;
  mname : Path.t; (* Module name *)
  mainmodule : Path.t;
}

let no_var =
  { fn = No_function; alloc = No_value; malloc = No_malloc; tailrec = false }

let apptbl = Apptbl.create 64
let poly_funcs_tbl = Hashtbl.create 64
let missing_polys_tbl = Hashtbl.create 64

(* Monomorphization *)

let typ_of_abs abs = Tfun (abs.func.params, abs.func.ret, abs.func.kind)

let func_of_typ = function
  | Tfun (params, ret, kind) -> { params; ret; kind }
  | _ -> failwith "Internal Error: Not a function type"

let rec find_function_expr vars = function
  | Mvar (_, Vglobal id) -> (
      (* Use the id saved in Vglobal. The usual id is the call name / unique global name *)
      match Vars.find_opt id vars with
      | Some (Global (_, thing, used)) ->
          used := true;
          thing.fn
      | Some _ -> failwith "Internal Error: Unexpected nonglobal"
      | None -> No_function)
  | Mvar (id, _) -> (
      match Vars.find_opt id vars with
      | Some (Normal thing | Param thing) -> thing.fn
      | Some (Global _) -> failwith "Internal Error: Unused global?"
      | Some (Const _) -> No_function
      | None -> (
          match Builtin.of_string id with
          | Some b -> Builtin b
          | None -> No_function))
  | Mconst _ | Mapp _ | Mrecord _ | Mfield _ | Mbop _ | Munop _ | Mctor _ ->
      No_function
  | Mif _ ->
      (* We are not allowing to return functions in ifs,
         b/c we cannot codegen anyway *)
      No_function
  | Mlambda (name, _, _) -> (
      match Vars.find_opt name vars with
      | Some (Normal thing) -> thing.fn
      | _ -> No_function)
  | Mlet _ | Mbind _ -> No_function (* TODO cont? Didn't work on quick test *)
  | Mfmt _ -> No_function
  | Mfree_after (e, _) -> find_function_expr vars e.expr
  | e ->
      print_endline (show_expr e);
      "Not supported: " ^ show_expr e |> failwith

let rec short_name ~closure t =
  let str = short_name ~closure in
  let open Printf in
  match t with
  | Tint -> "i"
  | Tbool -> "b"
  | Tunit -> "u"
  | Tu8 -> "c"
  | Tfloat -> "f"
  | Ti32 -> "i32"
  | Tf32 -> "f32"
  | Tfun (ps, r, k) ->
      let k =
        match k with
        | Closure c when closure -> (
            match c with
            | [] -> ""
            | c -> "-" ^ String.concat "-" (List.map (fun c -> str c.cltyp) c))
        | Closure _ | Simple -> ""
      in
      sprintf "%s.%s%s"
        (String.concat "" (List.map (fun p -> str p.pt) ps))
        (str r) k
  | Trecord (ps, Some name, _) | Tvariant (ps, name, _) ->
      sprintf "%s%s" name (String.concat "" (List.map str ps))
  | Trecord (_, None, fs) ->
      "tup-"
      ^ (Array.to_list fs |> List.map (fun f -> str f.ftyp) |> String.concat "-")
  | Tpoly _ -> "g"
  | Traw_ptr t -> sprintf "p%s" (str t)
  | Tarray t -> sprintf "a%s" (str t)

let get_mono_name name ~poly ~closure concrete =
  let open Printf in
  let str = short_name ~closure in
  sprintf "__%s_%s_%s" (str poly) name (str concrete)

let rec subst_type ~concrete poly parent =
  let rec inner subst = function
    | Tpoly id, t -> (
        match Vars.find_opt id subst with
        | Some _ -> (* Already in tbl*) (subst, t)
        | None -> (Vars.add id t subst, t))
    | Tfun (ps1, r1, k1), Tfun (ps2, r2, k2) ->
        let subst, ps =
          List.fold_left_map
            (fun subst (l, r) ->
              let s, pt = inner subst (l.pt, r.pt) in
              (s, { l with pt }))
            subst (List.combine ps1 ps2)
        in
        let subst, r = inner subst (r1, r2) in
        let subst, kind =
          match (k1, k2) with
          | Simple, Simple -> (subst, Simple)
          | Closure c1, Closure c2 ->
              let s, c =
                List.fold_left_map
                  (fun subst (l, r) ->
                    let s, cltyp = inner subst (l.cltyp, r.cltyp) in
                    (* Copied from [subst_kind] *)
                    let is_function =
                      match cltyp with Tfun _ -> true | _ -> false
                    in
                    let clname =
                      if
                        is_function && (not l.clparam)
                        && is_type_polymorphic l.cltyp
                        && not (is_type_polymorphic cltyp)
                      then
                        get_mono_name l.clname ~closure:true ~poly:l.cltyp cltyp
                      else l.clname
                    in
                    (s, { l with cltyp; clname }))
                  subst (List.combine c1 c2)
              in
              (s, Closure c)
          | _ ->
              failwith "Internal Error: Unexpected Simple-Closure combination"
        in
        (subst, Tfun (ps, r, kind))
    | (Trecord (i, record, l1) as l), Trecord (j, _, l2)
      when is_type_polymorphic l ->
        let labels = Array.copy l1 in
        let f (subst, i) (label : Cleaned_types.field) =
          let subst, ftyp = inner subst (label.ftyp, l2.(i).ftyp) in
          labels.(i) <- Cleaned_types.{ (labels.(i)) with ftyp };
          (subst, i + 1)
        in
        let subst, _ = Array.fold_left f (subst, 0) l1 in
        let subst, ps =
          List.fold_left_map
            (fun subst (l, r) -> inner subst (l, r))
            subst (List.combine i j)
        in
        (subst, Trecord (ps, record, labels))
    | (Tvariant (i, variant, l1) as l), Tvariant (j, _, l2)
      when is_type_polymorphic l ->
        let ctors = Array.copy l1 in
        let f (subst, i) (ctor : Cleaned_types.ctor) =
          let subst, ctyp =
            match (ctor.ctyp, l2.(i).ctyp) with
            | Some l, Some r ->
                let subst, t = (inner subst) (l, r) in
                (subst, Some t)
            | _ -> (subst, None)
          in
          ctors.(i) <- Cleaned_types.{ (ctors.(i)) with ctyp };
          (subst, i + 1)
        in
        let subst, _ = Array.fold_left f (subst, 0) l1 in
        let subst, ps =
          List.fold_left_map
            (fun subst (l, r) -> inner subst (l, r))
            subst (List.combine i j)
        in
        (subst, Tvariant (ps, variant, ctors))
    | Traw_ptr l, Traw_ptr r ->
        let subst, t = inner subst (l, r) in
        (subst, Traw_ptr t)
    | Tarray l, Tarray r ->
        let subst, t = inner subst (l, r) in
        (subst, Tarray t)
    | t, _ -> (subst, t)
  in
  let vars, typ = inner Vars.empty (poly, concrete) in

  let rec subst = function
    | Tpoly id as old -> (
        match Vars.find_opt id vars with Some t -> t | None -> old)
    | Tfun (ps, r, kind) ->
        let ps = List.map (fun p -> { p with pt = subst p.pt }) ps in
        let kind = subst_kind subst kind in
        Tfun (ps, subst r, kind)
    | Trecord (ps, record, labels) as t when is_type_polymorphic t ->
        let ps = List.map subst ps in
        let f field = Cleaned_types.{ field with ftyp = subst field.ftyp } in
        let labels = Array.map f labels in
        Trecord (ps, record, labels)
    | Tvariant (ps, variant, ctors) as t when is_type_polymorphic t ->
        let ps = List.map subst ps in
        let f ctor =
          Cleaned_types.{ ctor with ctyp = Option.map subst ctor.ctyp }
        in
        let ctors = Array.map f ctors in
        Tvariant (ps, variant, ctors)
    | Traw_ptr t -> Traw_ptr (subst t)
    | Tarray t -> Tarray (subst t)
    | t -> t
  in

  (* We might have to substitute other types (in closures) from an outer scope *)
  let subst, typ =
    match parent with
    | Some sub -> ((fun t -> sub t |> subst), sub typ)
    | None -> (subst, typ)
  in

  (subst, typ)

and subst_kind subst = function
  | Simple -> Simple
  | Closure cls ->
      let cls =
        List.map
          (fun cl ->
            let cltyp = subst cl.cltyp in
            let is_function = match cltyp with Tfun _ -> true | _ -> false in
            let clname =
              if
                is_function && (not cl.clparam)
                && is_type_polymorphic cl.cltyp
                && not (is_type_polymorphic cltyp)
              then get_mono_name cl.clname ~closure:true ~poly:cl.cltyp cltyp
              else cl.clname
            in
            { cl with cltyp; clname })
          cls
      in
      Closure cls

and subst_body p subst tree =
  let p = ref p in

  let subst_func { params; ret; kind } =
    let params = List.map (fun p -> { p with pt = subst p.pt }) params in
    let ret = subst ret in
    let kind = subst_kind subst kind in
    { params; ret; kind }
  in

  let rec inner tree =
    let sub t = { (inner t) with typ = subst t.typ } in
    match tree.expr with
    | Mvar _ -> { tree with typ = subst tree.typ }
    | Mconst _ -> tree
    | Mbop (bop, l, r) -> { tree with expr = Mbop (bop, sub l, sub r) }
    | Munop (unop, e) -> { tree with expr = Munop (unop, sub e) }
    | Mif expr ->
        let cond = sub expr.cond in
        let e1 = sub expr.e1 in
        let e2 = sub expr.e2 in
        { tree with typ = e1.typ; expr = Mif { expr with cond; e1; e2 } }
    | Mlet (id, expr, proj, gn, vid, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        {
          tree with
          typ = cont.typ;
          expr = Mlet (id, expr, proj, gn, vid, cont);
        }
    | Mbind (id, lhs, cont) ->
        let lhs = sub lhs in
        let cont = sub cont in
        { tree with typ = cont.typ; expr = Mbind (id, lhs, cont) }
    | Mlambda (name, abs, alloca) ->
        let abs =
          { abs with func = subst_func abs.func; body = sub abs.body }
        in
        let typ = typ_of_abs abs in

        (* We may have to monomorphize. For instance if the lambda returned
           from a polymorphic function *)
        let name = mono_callable name typ tree in

        { tree with typ; expr = Mlambda (name, abs, alloca) }
    | Mfunction (name, abs, cont, alloca) ->
        let typ = typ_of_abs abs in
        let abs =
          { abs with func = subst_func abs.func; body = sub abs.body }
        in
        (* We may have to monomorphize. For instance if the lambda returned
           from a polymorphic function *)
        let name = mono_callable name (typ_of_abs abs) { tree with typ } in

        let cont = { (inner cont) with typ = subst cont.typ } in
        { tree with typ = cont.typ; expr = Mfunction (name, abs, cont, alloca) }
    | Mapp { callee; args; alloca; id; ms } ->
        let ex = sub callee.ex in

        (* We use the parameters at function creation time to deal with scope *)
        let old_p =
          match Apptbl.find_opt apptbl (string_of_int id) with
          | Some old ->
              { old with funcs = !p.funcs; monomorphized = !p.monomorphized }
          | None -> failwith "Internal Error: No old param"
        in

        let p2, monomorph = monomorphize_call old_p ex (Some subst) in

        let callee = { callee with ex; monomorph } in

        let p2, args =
          List.fold_left_map
            (fun p2 (arg, a) ->
              let ex = sub arg.ex in
              let p2, monomorph = monomorphize_call p2 ex (Some subst) in
              (p2, ({ arg with ex; monomorph }, a)))
            p2 args
        in
        p :=
          {
            !p with
            funcs = Fset.union !p.funcs p2.funcs;
            monomorphized = Sset.union !p.monomorphized p2.monomorphized;
          };

        let func = func_of_typ callee.ex.typ in
        {
          tree with
          typ = func.ret;
          expr = Mapp { callee; args; alloca; id; ms };
        }
    | Mrecord (labels, alloca, id, const) ->
        let labels = List.map (fun (name, expr) -> (name, sub expr)) labels in
        {
          tree with
          typ = subst tree.typ;
          expr = Mrecord (labels, alloca, id, const);
        }
    | Mctor ((var, index, expr), alloca, id, const) ->
        let expr =
          Mctor ((var, index, Option.map sub expr), alloca, id, const)
        in
        { tree with typ = subst tree.typ; expr }
    | Mfield (expr, index) ->
        { tree with typ = subst tree.typ; expr = Mfield (sub expr, index) }
    | Mvar_index expr ->
        { tree with typ = subst tree.typ; expr = Mvar_index (sub expr) }
    | Mvar_data (expr, mid) ->
        { tree with typ = subst tree.typ; expr = Mvar_data (sub expr, mid) }
    | Mset (expr, value, moved) ->
        let expr = Mset (sub expr, sub value, moved) in
        { tree with typ = subst tree.typ; expr }
    | Mseq (expr, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { tree with typ = cont.typ; expr = Mseq (expr, cont) }
    | Mfmt (fmts, alloca, id) ->
        let fmts =
          List.map (function Fexpr e -> Fexpr (sub e) | Fstr s -> Fstr s) fmts
        in
        { tree with expr = Mfmt (fmts, alloca, id) }
    | Mprint_str fmts ->
        let fmts =
          List.map (function Fexpr e -> Fexpr (sub e) | Fstr s -> Fstr s) fmts
        in
        { tree with expr = Mprint_str fmts }
    | Mfree_after (e, fs) ->
        let e = sub e in
        { tree with expr = Mfree_after (e, fs) }
  and mono_callable name typ tree =
    if is_type_polymorphic tree.typ then (
      match Apptbl.find_opt apptbl name with
      | Some old ->
          let old =
            { old with funcs = !p.funcs; monomorphized = !p.monomorphized }
          in
          let p2, monomorph =
            monomorphize_call old { tree with typ } (Some subst)
          in
          let name = match monomorph with Mono name -> name | _ -> name in
          p :=
            {
              !p with
              funcs = Fset.union !p.funcs p2.funcs;
              monomorphized = Sset.union !p.monomorphized p2.monomorphized;
            };
          name
      | None ->
          (* Partly copied from [monomorphize_call] *)
          if is_type_polymorphic typ then name
          else
            let p2, monomorph =
              match Hashtbl.find_opt poly_funcs_tbl name with
              | Some func -> monomorphize !p tree.typ typ func (Some subst)
              | None ->
                  failwith "Internal Error: Poly function not registered yet"
            in

            let name = match monomorph with Mono name -> name | _ -> name in
            p :=
              {
                !p with
                funcs = Fset.union !p.funcs p2.funcs;
                monomorphized = Sset.union !p.monomorphized p2.monomorphized;
              };

            (* It's concrete, all good *) name)
    else name
  in

  (!p, inner tree)

and monomorphize_call p expr parent_sub : morph_param * call_name =
  match find_function_expr p.vars expr.expr with
  | Builtin b -> (p, Builtin (b, func_of_typ expr.typ))
  | Inline (ps, typ, tree) ->
      (* Copied from Polymorphic below *)
      (* The parent substitution is threaded through to its children.
         This deals with nested closures *)
      let subst, typ = subst_type ~concrete:expr.typ typ parent_sub in

      (* If the type is still polymorphic, we cannot generate it *)
      if is_type_polymorphic typ then (p, Default)
      else let p, tree = subst_body p subst tree in

           (p, Inline (ps, tree))
  | Forward_decl (name, typ) ->
      (* Generate the correct call name. If its mono, we have to recalculate it.
         Closures are tricky, as the arguments are generally not closures, but the typ might.
         We try to subst the (potential) closure by using the parent_sub if its available *)
      if is_type_polymorphic typ then
        (* Instead of directly generating the mono name from concrete type and expr,
           we substitute the poly type and use the substituted one. This helps with some closures *)
        let call =
          match parent_sub with
          | Some sub ->
              let concrete = sub typ in
              get_mono_name name ~closure:true ~poly:typ concrete
          | None -> get_mono_name name ~closure:true ~poly:typ expr.typ
        in
        (* We still need to use the un-monomorphized callname for marking recursion *)
        (p, Recursive { nonmono = name; call })
        (* Make the name concrete so the correct call name is used *)
      else (p, Recursive { nonmono = name; call = name })
  | Mutual_rec (name, typ) ->
      if is_type_polymorphic typ then (
        let call = get_mono_name name ~closure:true ~poly:typ expr.typ in
        if not (Sset.mem call p.monomorphized) then
          (* The function doesn't exist yet, will it ever exist? *)
          if not (Hashtbl.mem missing_polys_tbl call) then
            Hashtbl.add missing_polys_tbl name (p, expr.typ, parent_sub);
        (p, Mono call)
        (* Make the name concrete so the correct call name is used *))
      else (p, Concrete name)
  | _ when is_type_polymorphic expr.typ -> (p, Default)
  | Concrete (func, username) ->
      (* If a named function gets a generated name, the call site has to be made aware *)
      if not (String.equal func.name.call username) then
        (p, Concrete func.name.call)
      else (p, Default)
  | Polymorphic call -> (
      match Hashtbl.find_opt poly_funcs_tbl call with
      | Some func ->
          let typ = typ_of_abs func.abs in
          monomorphize p typ expr.typ func parent_sub
      | None -> failwith "Internal Error: Poly function not registered yet")
  | No_function -> (p, Default)

and monomorphize p typ concrete func parent_sub =
  let call = get_mono_name func.name.call ~closure:true ~poly:typ concrete in

  if Sset.mem call p.monomorphized then
    (* The function exists, we don't do anything right now *)
    (p, Mono call)
  else
    (* We generate the function *)

    (* The parent substitution is threaded through to its children.
       This deals with nested closures *)
    let subst, typ = subst_type ~concrete typ parent_sub in

    (* If the type is still polymorphic, we cannot generate it *)
    if is_type_polymorphic typ then (p, Default)
    else
      let p, body = subst_body p subst func.abs.body in

      let kind = subst_kind subst func.abs.func.kind in
      let fnc = { (func_of_typ typ) with kind } in
      let name = { func.name with call } in
      let abs = { func.abs with func = fnc; body } in
      let monomorphized = true in
      let funcs = Fset.add { func with abs; name; monomorphized } p.funcs in
      let monomorphized = Sset.add call p.monomorphized in
      ({ p with funcs; monomorphized }, Mono call)

let extract_callname default vars expr =
  match find_function_expr vars expr with
  | Builtin _ | Inline _ ->
      failwith "Internal error: Builtin or inline function captured in closure"
  | Mutual_rec _ -> failwith "TODO mutual rec"
  | Forward_decl (call, _) | Polymorphic call -> call
  | Concrete (func, _) -> func.name.call
  | No_function -> default

let rec cln p = function
  | Types.Tvar { contents = Link t } | Talias (_, t) -> cln p t
  | Tint -> Tint
  | Tbool -> Tbool
  | Tunit -> Tunit
  | Tu8 -> Tu8
  | Tfloat -> Tfloat
  | Ti32 -> Ti32
  | Tf32 -> Tf32
  | Qvar id | Tvar { contents = Unbound (id, _) } -> Tpoly id
  | Tfun (params, ret, kind) ->
      Tfun (List.map (cln_param p) params, cln p ret, cln_kind p kind)
  | Trecord (ps, name, fields) ->
      let ps = List.map (cln p) ps in
      let fields =
        Array.map
          (fun field -> { ftyp = cln p Types.(field.ftyp); mut = field.mut })
          fields
      in
      let name = Option.map Path.type_name name in
      Trecord (ps, name, fields)
  | Tvariant (ps, name, ctors) ->
      let ps = List.map (cln p) ps in
      let ctors =
        Array.map
          (fun ctor ->
            {
              cname = Types.(ctor.cname);
              ctyp = Option.map (cln p) ctor.ctyp;
              index = ctor.index;
            })
          ctors
      in
      Tvariant (ps, Path.type_name name, ctors)
  | Traw_ptr t -> Traw_ptr (cln p t)
  | Tarray t -> Tarray (cln p t)
  | Tabstract (_, _, Tvar { contents = Unbound _ }) ->
      failwith "Internal Error: How did this come through?"
  | Tabstract (_, _, t) ->
      (* Turn abstract type into its real representation for codegen *)
      cln p t

and cln_kind p = function
  | Simple -> Simple
  | Closure vals ->
      let vals =
        List.map
          (fun (cl : Types.closed) ->
            let typ = cln p cl.cltyp in
            let clname =
              if not cl.clparam then
                extract_callname cl.clname p.vars (Mvar (cl.clname, Vnorm))
              else cl.clname
            in
            { clname; cltyp = typ; clmut = cl.clmut; clparam = cl.clparam })
          vals
      in
      Closure vals

and cln_param param p =
  let pt = cln param Types.(p.pt) in
  let pmut, pmoved =
    match p.pattr with
    | Dset | Dmut -> (true, false)
    | Dmove -> (false, true)
    | Dnorm -> (false, false)
  in
  { pt; pmut; pmoved }

(* State *)

let alloc_lvl = ref 1
let alloc_id = ref 1
let malloc_id = ref 1

let new_id id =
  let ret_id = !id in
  incr id;
  ret_id

let enter_level () = incr alloc_lvl
let leave_level () = decr alloc_lvl
let request () = Request { id = new_id alloc_id; lvl = !alloc_lvl }

let reset () =
  alloc_lvl := 1;
  alloc_id := 1;
  malloc_id := 1

let rec set_alloca = function
  | Value ({ contents = Request req } as a) when req.lvl >= !alloc_lvl ->
      a := Preallocated
  | Two_values (a, b) ->
      set_alloca a;
      set_alloca b
  | Value _ | No_value -> ()

let mb_malloc parent ids typ =
  if contains_allocation typ then
    let mid = new_id malloc_id in
    let id = Malloc.Single { mid; typ; parent } in
    let mallocs = Mallocs.add id ids in
    (Some mid, id, mallocs)
  else (None, No_malloc, ids)

let add_params vars mallocs pnames params =
  (* Add parameters to the env and create malloc ids if they have been moved *)
  List.fold_left2
    (fun (vars, mallocs) (name, malloc) p ->
      let var, mallocs =
        match malloc with
        | Some mid ->
            let id = { Mid.mid; typ = p.pt; parent = None } in
            ( Normal { no_var with malloc = Single id },
              Mallocs.add (Single id) mallocs )
        | None -> (Param no_var, mallocs)
      in
      let vars = Vars.add name var vars in
      (vars, mallocs))
    (vars, mallocs) pnames params

let recursion_stack = ref []
let constant_uniq_state = ref 1
let constant_tbl = Hashtbl.create 64
let global_tbl = Hashtbl.create 64

let pop_recursion_stack () =
  match !recursion_stack with
  | hd :: tl ->
      recursion_stack := tl;
      snd hd
  | [] -> failwith "Internal Error: Recursion stack empty (pop)"

let set_tailrec name =
  match !recursion_stack with
  (* We have to check the name (of the function) here, because
     a nested function could call recursively its parent *)
  | (nm, _) :: tl when String.equal name nm ->
      recursion_stack := (nm, Rtail) :: tl
  | _ :: _ -> ()
  | [] -> failwith "Internal Error: Recursion stack empty (set)"

let reconstr_module_username ~mname ~mainmodule username =
  (* Values queried from an imported module have a special name so they don't clash with
     user-defined values. This name is calculated in [Module.absolute_module_name]. For functions,
     polymorphic the [unique_name] also prepends the module. Their username will stay intact so we
     don't create names like prelude_prelude_thing. In order to match their queried name, we
     convert to the absolute_module_name before adding them to the environment. *)
  let imported = Path.equal mname mainmodule |> not in
  if imported then Module.absolute_module_name ~mname username else username

let rec_fs_to_env p (username, uniq, typ) =
  let ftyp = cln p typ in

  let call = Module.unique_name ~mname:p.mname username uniq in
  let fn = Mutual_rec (call, ftyp) in
  let username =
    reconstr_module_username ~mname:p.mname ~mainmodule:p.mainmodule username
  in
  let vars = Vars.add username (Normal { no_var with fn }) p.vars in
  { p with vars }

let let_kind pass =
  match pass with
  | Ast.Dmut | Dnorm -> Lborrow
  | Dmove -> Lowned
  | Dset -> failwith "Internal Error: no set here"

let rec morph_expr param (texpr : Typed_tree.typed_expr) =
  let make expr return =
    { typ = cln param texpr.typ; expr; return; loc = texpr.loc }
  in
  match texpr.expr with
  | Typed_tree.Var (v, _) -> morph_var make param v
  | Const (String s) -> morph_string make param s
  | Const (Array a) -> morph_array make param a (cln param texpr.typ)
  | Const c -> (param, make (Mconst (morph_const c)) false, no_var)
  | Bop (bop, e1, e2) -> morph_bop make param bop e1 e2
  | Unop (unop, expr) -> morph_unop make param unop expr
  | If (_, None, _, _) -> failwith "Internal Error: Unset if owning"
  | If (cond, Some owning, e1, e2) -> morph_if make param cond owning e1 e2
  | Let { id; uniq; rhs; cont; pass; rmut = _ } ->
      let kind = let_kind pass in
      let un, p, e1, gn, ms = prep_let param id uniq rhs pass false in
      let p, e2, func = morph_expr { p with ret = param.ret } cont in
      (p, { e2 with expr = Mlet (un, e1, kind, gn, ms, e2) }, func)
  | Bind (id, lhs, cont) ->
      let p, lhs, func = morph_expr { param with ret = false } lhs in
      let vars = Vars.add id (Normal func) p.vars in
      let p, cont, func = morph_expr { p with ret = param.ret; vars } cont in
      ( p,
        {
          typ = cont.typ;
          expr = Mbind (id, lhs, cont);
          return = param.ret;
          loc = texpr.loc;
        },
        func )
  | Record labels ->
      morph_record make param labels texpr.attr (cln param texpr.typ)
  | Field (expr, index, _) -> morph_field make param expr index
  | Set (expr, value) -> morph_set make param expr value
  | Sequence (expr, cont) -> morph_seq make param expr cont
  | Function (name, uniq, abs, cont) ->
      let p, call, abs, alloca = prep_func param (name, uniq, abs) in
      let p, cont, func = morph_expr { p with ret = param.ret } cont in
      ( p,
        {
          typ = cont.typ;
          expr = Mfunction (call, abs, cont, alloca);
          return = param.ret;
          loc = texpr.loc;
        },
        func )
  | Mutual_rec_decls (decls, cont) ->
      let p = List.fold_left rec_fs_to_env param decls in
      morph_expr p cont
  | Lambda (id, abs) -> morph_lambda make texpr.typ param id abs
  | App
      {
        callee = { expr = Var (id, _); _ };
        args = [ ({ expr = Fmt es; _ }, _) ];
      }
    when String.equal id
           (Module.absolute_module_name ~mname:(Path.Pid "std") "print") ->
      morph_print_str make param es
  | App { callee; args } ->
      morph_app make param callee args (cln param texpr.typ)
  | Ctor (variant, index, dataexpr) ->
      morph_ctor make param variant index dataexpr texpr.attr
        (cln param texpr.typ)
  | Variant_index expr -> morph_var_index make param expr
  | Variant_data expr -> morph_var_data make param expr (cln param texpr.typ)
  | Fmt exprs -> morph_fmt make param exprs
  | Move e ->
      let p, e, func = morph_expr param e in
      let mallocs = Mallocs.remove func.malloc p.mallocs in
      ({ p with mallocs }, e, { func with malloc = No_malloc })

and morph_var mk p v =
  let (v, kind), var =
    match v with
    | "__malloc" ->
        let var = { no_var with fn = Builtin Malloc } in
        ((v, Vnorm), var)
    | v -> (
        match Vars.find_opt v p.vars with
        | Some (Normal ({ fn = Concrete (_, callname); _ } as thing)) ->
            ((callname, Vnorm), thing)
        | Some (Normal thing) -> ((v, Vnorm), thing)
        | Some (Param thing) ->
            if p.ret then ((v, Vnorm), thing)
            else
              (* Mark argument with a bogus id *)
              let malloc =
                Malloc.Single { mid = -1; typ = Tunit; parent = None }
              in
              ((v, Vnorm), { thing with malloc })
        | Some (Const thing) -> ((thing, Vconst), no_var)
        | Some (Global (id, thing, used)) ->
            used := true;
            ((id, Vglobal v), thing)
        | None -> ((v, Vnorm), no_var))
  in
  let ex = mk (Mvar (v, kind)) p.ret in
  (p, ex, var)

and morph_string mk p s =
  ( p,
    mk (Mconst (String s)) p.ret,
    { no_var with fn = No_function; malloc = No_malloc } )

and morph_array mk p a typ =
  let ret = p.ret in
  (* TODO save id list and pass empty one. Destroy temporary objects not directly used as member *)
  let p = { p with ret = false } in

  (* ret = false is threaded through p *)
  enter_level ();
  let f param e =
    let p, e, var = morph_expr param e in
    (* (In codegen), we provide the data ptr to the initializers to construct inplace *)
    set_alloca var.alloc;
    (* Should have been moved *)
    assert (var.malloc = No_malloc);
    (p, e)
  in
  let p, a = List.fold_left_map f p a in
  leave_level ();
  let alloca = ref (request ()) in
  let mid = new_id malloc_id in
  let id = { Mid.mid; typ; parent = None } in
  let mallocs = Mallocs.add (Single id) p.mallocs in

  ( { p with ret; mallocs },
    mk (Mconst (Array (a, alloca, mid))) p.ret,
    { no_var with fn = No_function; alloc = Value alloca; malloc = Single id }
  )

and morph_const = function
  | String _ | Array _ -> failwith "Internal Error: Const should be extra case"
  | Int i -> Int i
  | Bool b -> Bool b
  | Float f -> Float f
  | Unit -> Unit
  | U8 c -> U8 c
  | I32 i -> I32 i
  | F32 f -> F32 f

and morph_bop mk p bop e1 e2 =
  let ret = p.ret in
  (* The returning expr is bop, not one of the operands *)
  let p, e1, _ = morph_expr { p with ret = false } e1 in
  let p, e2, _ = morph_expr { p with ret = false } e2 in
  ({ p with ret }, mk (Mbop (bop, e1, e2)) ret, no_var)

and morph_unop mk p unop expr =
  let ret = p.ret in
  let p, e, _ = morph_expr { p with ret = false } expr in
  ({ p with ret }, mk (Munop (unop, e)) ret, no_var)

and morph_if mk p cond owning e1 e2 =
  let ret = p.ret in
  let p, cond, _ = morph_expr { p with ret = false } cond in
  let oldmallocs = p.mallocs in

  (* TODO update this comment *)
  (* If a malloc from a branch is local it is unique. We can savely add it
     to mallocs and return it. For mallocs from the outer scope (function scope),
     we need to be more careful. If outer scope mallocs are involved, we don't add
     to mallocs to prevent aliasing, but return Oneof _. If such an expression
     is returned from a function, we cannot be sure what to free in codegen. *)
  (* There are two cases to distinguish:
     1. The borrows are moved (owning = true), which means all unused branches
     can be freed immediately. We still keep track of the Oneofs for nested ifs so
     we prevent double-freeing an already freed branch. Local allocation are treated
     as No_malloc, so they aren't freed from the other branch.
     2. The borrows are not moved (owning = false). In this case, we don't know if
     the borrows are returned later, so we (could) keep an extra bool per taken
     branch in codegen which can be queried to delete the correct things.
     For now we prevent this situation completely with a check in exclusivity and
     force a copy *)
  let p, e1, a =
    morph_expr { p with ret; mallocs = Mallocs.push Mlocal oldmallocs } e1
  in
  let e1, a, amallocs =
    (* For tailrecursive calls, every ref is already decreased in [morph_app].
           Furthermore, if both branches are tailrecursive, calling decr_ref might
           destroy a basic block in codegen. That's due to no merge blocks being
           created in that case *)
    if a.tailrec then
      let _, mallocs = Mallocs.pop p.mallocs in
      (e1, { a with malloc = No_malloc }, mallocs)
    else
      (* Remove returning malloc *)
      let mallocs =
        if owning then Mallocs.remove a.malloc p.mallocs
        else Mallocs.remove_local a.malloc p.mallocs
      in
      let frees, mallocs = Mallocs.pop mallocs in
      (mk_free_after e1 frees, a, mallocs)
  in

  let p, e2, b =
    morph_expr { p with ret; mallocs = Mallocs.push Mlocal oldmallocs } e2
  in
  let e2, b, bmallocs =
    if b.tailrec then
      let _, mallocs = Mallocs.pop p.mallocs in
      (e2, { b with malloc = No_malloc }, mallocs)
    else
      let mallocs =
        if owning then Mallocs.remove b.malloc p.mallocs
        else Mallocs.remove_local b.malloc p.mallocs
      in
      let frees, mallocs = Mallocs.pop mallocs in
      (mk_free_after e2 frees, b, mallocs)
  in

  let tailrec = a.tailrec && b.tailrec in

  (* Find out what's local and what isn't *)
  let amoved = Mallocs.diff_func oldmallocs amallocs in
  let bmoved = Mallocs.diff_func oldmallocs bmallocs in

  let mallocs = oldmallocs in
  (* Free what can be freed *)
  let e1, e2, malloc, mallocs =
    (* Mallocs which were moved in one branch need to be freed in the other *)
    let frees_a = mapdiff_flip bmoved amoved |> mlist_of_pmap in
    let frees_b = mapdiff_flip amoved bmoved |> mlist_of_pmap in

    let rm_path m path ms = Mallocs.remove (Path (Single m, path)) ms in
    let mallocs =
      Imap.fold
        (fun m pset ms ->
          if Pset.is_empty pset then
            (* Remove the whole malloc, not just a part *)
            Mallocs.remove (Single m) ms
          else Pset.fold (rm_path m) pset ms)
        (mapunion amoved bmoved) mallocs
    in
    let e1 =
      if a.tailrec then e1
      else { e1 with expr = Mfree_after (e1, Only frees_a) }
    in
    let e2 =
      if b.tailrec then e2
      else { e2 with expr = Mfree_after (e2, Only frees_b) }
    in

    if owning && contains_allocation e1.typ then
      let mid = new_id malloc_id in
      let id = { Mid.mid; typ = e1.typ; parent = None } in
      let mallocs = Mallocs.add (Single id) mallocs in
      let mallocs =
        Mallocs.remove a.malloc mallocs |> Mallocs.remove b.malloc
      in
      (e1, e2, Malloc.Single id, mallocs)
    else (e1, e2, Branch { fst = a.malloc; snd = b.malloc }, mallocs)
  in

  let owning =
    if owning then
      match malloc with
      | Single id -> Some id.mid
      | No_malloc | Branch _ -> None
      | Path _ -> failwith "todo path"
    else None
  in
  ( { p with mallocs },
    mk (Mif { cond; owning; e1; e2 }) ret,
    { a with alloc = Two_values (a.alloc, b.alloc); malloc; tailrec } )

and prep_let p id uniq e pass toplvl =
  (* username *)
  let un =
    reconstr_module_username ~mname:p.mname ~mainmodule:p.mainmodule id
  in

  let p, e1, func = morph_expr { p with ret = false } e in
  let ms, malloc, mallocs =
    match pass with
    | Dmove ->
        let mid = new_id malloc_id in
        let id = Mid.{ mid; typ = e1.typ; parent = None } in
        ([ mid ], Malloc.Single id, Mallocs.add (Single id) p.mallocs)
    | Dset | Dmut | Dnorm -> ([], func.malloc, p.mallocs)
  in

  let p, func = ({ p with mallocs }, { func with malloc }) in

  let p, gn =
    match e.attr with
    | { const = true; _ } ->
        let uniq = Module.unique_name ~mname:p.mname id uniq in
        (* Maybe we have to generate a new name here *)
        let cnt = new_id constant_uniq_state in
        Hashtbl.add constant_tbl uniq (cnt, e1, toplvl);
        ({ p with vars = Vars.add un (Const uniq) p.vars }, Some uniq)
    | { global = true; _ } ->
        (* Globals are 'preallocated' at module level *)
        set_alloca func.alloc;
        let uniq = Module.unique_name ~mname:p.mname id uniq in
        let cnt = new_id constant_uniq_state in
        Hashtbl.add global_tbl uniq (cnt, e1.typ, toplvl);
        let used = ref false in
        let vars = Vars.add un (Global (uniq, func, used)) p.vars in
        (* Add global values to env with global id. That's how they might be queried,
           and the function information is needed for monomorphization *)
        let vars = Vars.add uniq (Global (uniq, func, used)) vars in
        ({ p with vars }, Some uniq)
    | _ ->
        let kind = let_kind pass in
        (match kind with Lborrow -> () | Lowned -> set_alloca func.alloc);
        ({ p with vars = Vars.add un (Normal func) p.vars }, None)
  in
  (un, p, e1, gn, ms)

and morph_record mk p labels is_const typ =
  let ret = p.ret in
  let p = { p with ret = false } in

  (* ret = false is threaded through p *)
  enter_level ();

  (* Collect mallocs in initializer *)
  let f param (id, e) =
    let p, e, var = morph_expr param e in
    if is_struct e.typ then set_alloca var.alloc;
    (* Should have been moved *)
    assert (var.malloc = No_malloc);
    (p, (id, e))
  in
  let p, labels = List.fold_left_map f p labels in
  leave_level ();

  let _, malloc, mallocs = mb_malloc None p.mallocs typ in
  let ms = m_to_list malloc in

  let alloca = ref (request ()) in
  ( { p with ret; mallocs },
    mk (Mrecord (labels, alloca, ms, is_const.const)) ret,
    { no_var with fn = No_function; alloc = Value alloca; malloc } )

and morph_field mk p expr index =
  let ret = p.ret in
  let p, e, func = morph_expr { p with ret = false } expr in
  let malloc = malloc_add_index index func.malloc in
  (* Field should not inherit alloca of its parent.
     Otherwise codegen might use a nested type as its parent *)
  ( { p with ret },
    mk (Mfield (e, index)) ret,
    { func with alloc = No_value; malloc } )

and morph_set mk p expr value =
  let ret = p.ret in
  (* We don't track allocations in the to-set expr.
     This helps with nested allocated things.
     If we do, there are additional relocations happening and the wrong
     things are freed. If one were to force an allocation here,
     that's a leak *)
  let mallocs = p.mallocs in
  let p, e, vfunc = morph_expr { p with ret = false } expr in
  let p, v, _ =
    morph_expr p (* { p with mallocs = Mallocs.empty Mlocal } *) value
  in

  (* TODO remove local allocs *)
  let moved =
    match vfunc.malloc with
    | No_malloc -> false
    | malloc -> Mallocs.mem malloc mallocs |> not
  in

  let mallocs =
    (* ignore func; *)
    (* let mallocs = Mallocs.remove func.malloc p.mallocs in *)
    if moved then Mallocs.reenter vfunc.malloc p.mallocs else p.mallocs
  in

  let tree = mk (Mset (e, v, moved)) ret in

  (* TODO free the thing. This is right now done in codegen by calling free manually.
     Could also be added to the tree *)
  ({ p with ret; mallocs }, tree, no_var)

and morph_seq mk p expr cont =
  let ret = p.ret in
  let p, expr, _ = morph_expr { p with ret = false } expr in
  let p, cont, func = morph_expr { p with ret } cont in
  (p, mk (Mseq (expr, cont)) ret, func)

and prep_func p (username, uniq, abs) =
  (* If the function is concretely typed, we add it to the function list and
     add the usercode name to the bound variables. In the polymorphic case,
     we add the function to the bound variables, but not to the function list.
     Instead, the monomorphized instance will be added later *)
  let ftyp =
    Types.(Tfun (abs.func.tparams, abs.func.ret, abs.func.kind)) |> cln p
  in

  let call = Module.unique_name ~mname:p.mname username uniq in
  let username =
    reconstr_module_username ~mname:p.mname ~mainmodule:p.mainmodule username
  in
  let recursive = Rnormal in
  let inline = abs.inline in

  let func =
    {
      params = List.map (cln_param p) abs.func.tparams;
      ret = cln p abs.func.ret;
      kind = cln_kind p abs.func.kind;
    }
  in
  let pnames =
    List.map2
      (fun n p ->
        let malloc = if p.pmoved then Some (new_id malloc_id) else None in
        (n, malloc))
      abs.nparams func.params
  in

  (* Make sure recursion works and the current function can be used in its body *)
  let temp_p =
    recursion_stack := (call, recursive) :: !recursion_stack;
    let alloc =
      if is_struct func.ret then Value (ref (request ())) else No_value
    in
    (* TODO make it impossible to recursively call an inline function *)
    let value = { no_var with fn = Forward_decl (call, ftyp); alloc } in
    let vars = Vars.add username (Normal value) p.vars in

    (* Add parameters to env as normal values.
       The existing values might not be 'normal' *)
    let mallocs = Mallocs.push Mfunc p.mallocs in
    let vars, mallocs = add_params vars mallocs pnames func.params in

    {
      p with
      vars;
      ret = (if not inline then true else p.ret);
      mallocs;
      toplvl = false;
    }
  in

  enter_level ();
  let temp_p, body, var = morph_expr temp_p abs.body in
  (* Set alloca in lower level. This deals with closed over allocas which are returned *)
  if is_struct body.typ then set_alloca var.alloc;
  leave_level ();

  let frees = Mallocs.pop temp_p.mallocs |> fst in
  let body = mk_free_after body frees in
  let recursive = pop_recursion_stack () in

  (* Collect functions from body *)
  let p =
    { p with monomorphized = temp_p.monomorphized; funcs = temp_p.funcs }
  in
  let alloca = ref (request ()) in
  let alloc = Value alloca in
  let upward () = match !alloca with Preallocated -> true | _ -> false in

  let abs = { func; pnames; body } in
  let name = { user = username; call } in
  let gen_func = { abs; name; recursive; upward; monomorphized = false } in

  let p =
    if inline then
      let fn = Inline (pnames, ftyp, body) in
      let vars = Vars.add username (Normal { no_var with fn; alloc }) p.vars in
      { p with vars }
    else if is_type_polymorphic ftyp then (
      let fn = Polymorphic call in
      let vars = Vars.add username (Normal { no_var with fn; alloc }) p.vars in
      Hashtbl.add poly_funcs_tbl call gen_func;
      { p with vars })
    else
      let fn = Concrete (gen_func, call) in
      let vars = Vars.add username (Normal { no_var with fn; alloc }) p.vars in
      let funcs = Fset.add gen_func p.funcs in
      { p with vars; funcs }
  in
  (p, call, abs, alloca)

and morph_lambda mk typ p id abs =
  let typ = cln p typ in

  (* TODO fix lambdas for nested modules *)
  let name = Module.lambda_name ~mname:p.mname id in
  let recursive = Rnone in
  let func =
    {
      params = List.map (cln_param p) abs.func.tparams;
      ret = cln p abs.func.ret;
      kind = cln_kind p abs.func.kind;
    }
  in
  let pnames =
    List.map2
      (fun n p ->
        let malloc = if p.pmoved then Some (new_id malloc_id) else None in
        (n, malloc))
      abs.nparams func.params
  in

  let ret = p.ret in
  let vars = p.vars in
  (* lambdas don't recurse, but functions inside the body might *)
  recursion_stack := (name, recursive) :: !recursion_stack;
  let temp_p =
    (* Add parameters to env as normal values.
       The existing values might not be 'normal' *)
    let mallocs = Mallocs.push Mfunc p.mallocs in
    let vars, mallocs = add_params vars mallocs pnames func.params in

    { p with vars; ret = true; mallocs; toplvl = false }
  in

  enter_level ();
  let temp_p, body, var = morph_expr temp_p abs.body in
  (* Set alloca in lower level. This deals with closed over allocas which are returned *)
  if is_struct body.typ then set_alloca var.alloc;
  leave_level ();

  (* Collect functions from body *)
  let p =
    { p with monomorphized = temp_p.monomorphized; funcs = temp_p.funcs }
  in

  let frees = Mallocs.pop temp_p.mallocs |> fst in
  let body = mk_free_after body frees in

  (* Why do we need this again in lambda? They can't recurse. *)
  (* But functions on the lambda body might *)
  ignore (pop_recursion_stack ());

  (* Function can be returned themselves. In that case, a closure object will be generated,
     so treat it the same as any local allocation *)
  let alloca = ref (request ()) in
  let upward () = match !alloca with Preallocated -> true | _ -> false in

  let abs = { func; pnames; body } in
  (* lambdas have no username, so we just repeat the call name *)
  let names = { call = name; user = name } in
  let monomorphized = false in
  let gen_func = { abs; name = names; recursive; upward; monomorphized } in

  let p = { p with vars } in
  let p, fn =
    if is_type_polymorphic typ then (
      (* Add fun to env so we can query it later for monomorphization *)
      let fn = Polymorphic name in
      let vars = Vars.add name (Normal { no_var with fn }) p.vars in
      Hashtbl.add poly_funcs_tbl name gen_func;
      ({ p with vars }, Polymorphic name))
    else
      let funcs = Fset.add gen_func p.funcs in
      ({ p with funcs }, Concrete (gen_func, name))
  in

  (* Save fake env with call name for monomorphization *)
  Apptbl.add apptbl name p;

  ( { p with ret },
    mk (Mlambda (name, abs, alloca)) ret,
    { no_var with fn; alloc = Value alloca } )

and morph_app mk p callee args ret_typ =
  (* Save env for later monomorphization *)
  let id = new_id malloc_id in

  let ret = p.ret in
  let p, ex, _ = morph_expr { p with ret = false } callee in
  let p, monomorph = monomorphize_call p ex None in
  let callee = { ex; monomorph; mut = false } in

  let tailrec =
    if ret then
      match callee.monomorph with
      | Recursive name ->
          set_tailrec name.nonmono;
          true
      | _ -> false
    else false
  in

  let f p (arg, attr) =
    let rec is_arg = function
      | Malloc.No_malloc -> false
      | Single { mid = -1; _ } -> true
      | Branch { fst; snd } -> is_arg fst || is_arg snd
      | Single _ -> false
      | Path _ -> (* A path cannot be a passed argument *) false
    in
    let ret = p.ret in
    let p, ex, var = morph_expr { p with ret = false } arg in
    let is_moved =
      match attr with Typed_tree.Dmove -> true | Dset | Dmut | Dnorm -> false
    in
    let mallocs, ex =
      if tailrec then (Mallocs.remove var.malloc p.mallocs, ex)
      else (p.mallocs, ex)
    in
    let p, monomorph = monomorphize_call { p with mallocs } ex None in
    ( { p with ret },
      ex,
      monomorph,
      (* If an argument is passed by move this means the parameter is also owned
         and will be freed in a tailrec call *)
      is_arg var.malloc || is_moved )
  in

  let rec fold_decr_last p args = function
    | [ (arg, attr) ] ->
        let mut = Types.mut_of_pattr attr in
        let p, ex, monomorph, arg = f p (arg, attr) in
        let _, ex =
          if tailrec then Mallocs.empty_func ex p.mallocs else (p.mallocs, ex)
        in
        (p, ({ ex; monomorph; mut }, arg) :: args)
    | (arg, attr) :: tl ->
        let mut = Types.mut_of_pattr attr in
        let p, ex, monomorph, arg = f p (arg, attr) in
        fold_decr_last p (({ ex; monomorph; mut }, arg) :: args) tl
    | [] -> (p, [])
  in
  let p, args = fold_decr_last p [] args in
  let args = List.rev args in
  let p, callee =
    match args with
    | [] when tailrec ->
        (* We haven't decreased references yet, because there is no last argument.
           Essentially, we do the same work as in the last arg of [fold_decr_last]*)
        (* Note that we use the original p.ids for [decr_refs] *)
        let _, ex = Mallocs.empty_func callee.ex p.mallocs in
        (p, { callee with ex })
    | _ -> (p, callee)
  in

  Apptbl.add apptbl (string_of_int id) p;

  let alloc, alloc_ref =
    if is_struct callee.ex.typ then
      (* For every call, we make a new request. If the call is the return
         value of a function, the request will be change to [Preallocated]
         in [morph_func] or [morph_lambda] above. *)
      let req = ref (request ()) in
      (Value req, req)
    else (No_value, ref (request ()))
  in

  let malloc, mallocs =
    (* array-get does not return a temporary. If its value is returned in a function,
       increase value's refcount so that it's really a temporary *)
    match callee.monomorph with
    | Builtin (Array_get, _) -> (Malloc.No_malloc, p.mallocs)
    | _ ->
        let _, malloc, mallocs = mb_malloc None p.mallocs ret_typ in
        (malloc, mallocs)
  in

  let ms = m_to_list malloc in

  let app = Mapp { callee; args; alloca = alloc_ref; id; ms } in

  ({ p with ret; mallocs }, mk app ret, { no_var with alloc; malloc; tailrec })

and morph_ctor mk p variant index expr is_const typ =
  let ret = p.ret in
  let p = { p with ret = false } in

  enter_level ();

  let p, ctor =
    match expr with
    | Some expr ->
        (* Similar to [morph_record], collect mallocs in data *)
        let p, e, var = morph_expr p expr in
        if is_struct e.typ then set_alloca var.alloc;
        (* Should have been moved *)
        assert (var.malloc = No_malloc);
        (p, (variant, index, Some e))
    | None -> (p, (variant, index, None))
  in

  leave_level ();

  let _, malloc, mallocs = mb_malloc None p.mallocs typ in
  let ms = m_to_list malloc in

  let alloca = ref (request ()) in
  ( { p with ret; mallocs },
    mk (Mctor (ctor, alloca, ms, is_const.const)) ret,
    { no_var with fn = No_function; alloc = Value alloca; malloc } )

(* Both variant exprs are as default as possible.
   We handle everything in codegen *)
and morph_var_index mk p expr =
  let ret = p.ret in
  (* False because we only use it interally in if expr? *)
  let p, e, func = morph_expr { p with ret = false } expr in
  ({ p with ret }, mk (Mvar_index e) ret, { func with alloc = No_value })

and morph_var_data mk p expr typ =
  let ret = p.ret in
  (* False because we only use it interally in if expr? *)
  let p, e, func = morph_expr { p with ret = false } expr in
  let mid, malloc =
    if contains_allocation typ then
      let mid = new_id malloc_id in
      let id = Malloc.Single { mid; typ; parent = Some func.malloc } in
      (Some mid, id)
    else (None, No_malloc)
  in
  let func =
    (* Since we essentially change the datatype here, we have to be sure that
       the variant was allocated before. Usually it is, but in the case of toplevel
       lets it might not. For instance if we have an (option t) which is matched on
       at assignment. Then, the global value is t, but if we propagate the alloc,
       the parent (option t) will try to initialize into the global value, which is t,
       another type.*)
    if p.toplvl then
      let alloc = Value (ref (request ())) in
      { func with alloc }
    else func
  in
  ({ p with ret }, mk (Mvar_data (e, mid)) ret, { func with malloc })

and morph_fmt mk p exprs =
  let ret = p.ret in
  let p = { p with ret = false } in

  let f p = function
    | Typed_tree.Fexpr e ->
        let p, e, _ = morph_expr p e in
        (p, Fexpr e)
    | Fstr s -> (p, Fstr s)
  in
  enter_level ();
  let p, es = List.fold_left_map f p exprs in
  leave_level ();

  let alloca = ref (request ()) in
  let mid = new_id malloc_id in
  let malloc = Malloc.Single { mid; typ = Tarray Tu8; parent = None } in
  let mallocs = Mallocs.add malloc p.mallocs in

  ( { p with ret; mallocs },
    mk (Mfmt (es, alloca, mid)) ret,
    { no_var with alloc = Value alloca; malloc } )

and morph_print_str mk p exprs =
  let ret = p.ret in
  let p = { p with ret = false } in

  let f p = function
    | Typed_tree.Fexpr e ->
        let p, e, _ = morph_expr p e in
        (p, Fexpr e)
    | Fstr s -> (p, Fstr s)
  in
  enter_level ();
  let p, es = List.fold_left_map f p exprs in
  leave_level ();

  ({ p with ret }, mk (Mprint_str es) ret, no_var)

let rec morph_toplvl param items =
  let rec aux param = function
    | [] ->
        let loc = (Lexing.dummy_pos, Lexing.dummy_pos) in
        (param, { typ = Tunit; expr = Mconst Unit; return = true; loc }, no_var)
    | [ (mname, Typed_tree.Tl_expr e) ] ->
        let param = { param with mname } in
        morph_expr param e
    | (mname, item) :: tl ->
        let param = { param with mname } in
        aux_impl param tl item
  and aux_impl param tl = function
    | Typed_tree.Tl_let { id; uniq; lhs = expr; pass; _ } ->
        let kind = let_kind pass in
        let un, p, e1, gn, ms = prep_let param id uniq expr pass true in
        let p, e2, func = aux { p with ret = param.ret } tl in
        (p, { e2 with expr = Mlet (un, e1, kind, gn, ms, e2) }, func)
    | Tl_function (loc, name, uniq, abs) ->
        let p, call, abs, alloca = prep_func param (name, uniq, abs) in
        let p, cont, func = aux { p with ret = param.ret } tl in
        ( p,
          {
            typ = cont.typ;
            expr = Mfunction (call, abs, cont, alloca);
            return = param.ret;
            loc;
          },
          func )
    | Tl_bind (id, expr) ->
        let p, e1, func = morph_expr { param with ret = false } expr in
        let p, e2, func =
          aux { p with vars = Vars.add id (Normal func) p.vars } tl
        in
        (p, { e2 with expr = Mbind (id, e1, e2) }, func)
    | Tl_mutual_rec_decls decls ->
        let p = List.fold_left rec_fs_to_env param decls in
        aux { p with ret = param.ret } tl
    | Tl_expr e ->
        let p, e, _ = morph_expr param e in
        let p, cont, func = aux { p with ret = param.ret } tl in
        ( p,
          {
            typ = cont.typ;
            expr = Mseq (e, cont);
            return = param.ret;
            loc = e.loc;
          },
          func )
    | Tl_module mitems ->
        let p, e, _ = morph_toplvl param mitems in
        let p, cont, func = aux { p with ret = param.ret } tl in
        ( p,
          {
            typ = cont.typ;
            expr = Mseq (e, cont);
            return = param.ret;
            loc = e.loc;
          },
          func )
    | Tl_module_alias _ -> aux param tl
  in
  aux param items

let monomorphize ~mname { Typed_tree.externals; items; _ } =
  reset ();

  (* External are globals. By marking them [Global] here, we don't have to
     introduce a special case in codegen, or mark them Const_ptr when they are not *)
  let vars =
    List.fold_left
      (fun vars { Env.ext_cname; ext_name; used; _ } ->
        let cname =
          match ext_cname with None -> ext_name | Some cname -> cname
        in
        Vars.add ext_name (Global (cname, no_var, used)) vars)
      Vars.empty externals
  in

  let param =
    let () = assert (!malloc_id = 1) in
    {
      vars;
      monomorphized = Sset.empty;
      funcs = Fset.empty;
      ret = false;
      mallocs = Mallocs.empty Mfunc;
      toplvl = true;
      mname;
      mainmodule = mname;
    }
  in
  let p, tree, _ = morph_toplvl param items in

  (* Add missing monomorphized functions from rec blocks *)
  let p =
    Hashtbl.fold
      (fun call (p, concrete, parent_sub) realp ->
        let p =
          { p with funcs = realp.funcs; monomorphized = realp.monomorphized }
        in
        let p, _ =
          match Hashtbl.find_opt poly_funcs_tbl call with
          | Some func ->
              let typ = typ_of_abs func.abs in
              monomorphize p typ concrete func parent_sub
          | None ->
              failwith
                ("Internal Error: Poly function not registered yet: " ^ call)
        in
        {
          realp with
          funcs = Fset.union p.funcs realp.funcs;
          monomorphized = Sset.union p.monomorphized realp.monomorphized;
        })
      missing_polys_tbl p
  in

  let frees =
    match Mallocs.pop p.mallocs |> fst with
    | [] -> Seq.empty
    | mallocs -> List.to_seq mallocs
  in

  let externals =
    List.filter_map
      (fun { Env.imported; ext_name; ext_typ = t; ext_cname; used; closure } ->
        if not !used then None
        else
          let cname =
            match ext_cname with None -> ext_name | Some cname -> cname
          in
          let c_linkage =
            match imported with
            (* A value is either imported or a real external decl (eg C function) *)
            | None | Some (_, `C) -> true
            | Some (_, `Schmu) -> false
          in
          Some { ext_name; ext_typ = cln p t; c_linkage; cname; closure })
      externals
  in

  let sort_const (_, (lid, _, _)) (_, (rid, _, _)) = Int.compare lid rid in
  let constants =
    Hashtbl.to_seq constant_tbl
    |> List.of_seq |> List.sort sort_const
    |> List.map (fun (name, (id, tree, toplvl)) ->
           ignore id;
           (name, tree, toplvl))
  in
  let globals =
    Hashtbl.to_seq global_tbl |> List.of_seq |> List.sort sort_const
    |> List.map (fun (name, (id, typ, toplvl)) ->
           ignore id;
           (name, typ, toplvl))
  in

  let funcs = Fset.to_seq p.funcs |> List.of_seq in
  { constants; globals; externals; tree; funcs; frees }
