open Types
open Typed_tree
open Error
(* Implements a borrow checker.
   We have to know the last usage for each binding. Instead of traversing once
   and using post processing, assume each binding is correct and unify
   binding-kind after the fact.*)

module Contains_allocation = struct
  let rec contains_allocation (get_decl : Path.t -> type_decl) = function
    | Tvar { contents = Link t } -> contains_allocation get_decl t
    | Ttuple ts ->
        List.fold_left
          (fun ca t -> ca || contains_allocation get_decl t)
          false ts
    | Tconstr (Pid name, _) as t when is_builtin t -> (
        match name with "array" | "rc" -> true | _ -> false)
    | Tconstr (name, ts) ->
        if
          not
            (List.fold_left
               (fun ca t -> ca || contains_allocation get_decl t)
               false ts)
        then
          (* Unparameterized types can also contain allocations *)
          let decl = get_decl name in
          let sub = map_params ~inst:ts ~params:decl.params in
          let rec check_decl decl_kind =
            match decl_kind with
            | Drecord (_, fs) ->
                Array.fold_left
                  (fun (ca, sub) f ->
                    let sub, typ = Inference.instantiate_sub sub f.ftyp in
                    (ca || contains_allocation get_decl typ, sub))
                  (false, sub) fs
                |> fst
            | Dvariant (_, cts) ->
                Array.fold_left
                  (fun (ca, sub) ct ->
                    match ct.ctyp with
                    | Some typ ->
                        let sub, typ = Inference.instantiate_sub sub typ in
                        (ca || contains_allocation get_decl typ, sub)
                    | None -> (ca, sub))
                  (false, sub) cts
                |> fst
            | Dalias typ ->
                let _, typ = Inference.instantiate_sub sub typ in
                contains_allocation get_decl typ
            | Dabstract None ->
                (* We already checked the params, but the type is still abstract
                   and could contain an allocation. *)
                true
            | Dabstract (Some kind) -> check_decl kind
          in
          check_decl decl.kind
        else true
    | Qvar _ | Tvar { contents = Unbound _ } ->
        (* We don't know yet *)
        true
    | Tfixed_array (_, t) -> contains_allocation get_decl t
    | Tfun _ ->
        (* TODO *)
        true
end

open Contains_allocation

module Usage = struct
  type t = Uread | Umut | Umove | Uset [@@deriving show]
  type set = Set | Dont_set [@@deriving show]

  let of_attr = function
    | Ast.Dnorm -> Uread
    | Dmut -> Umut
    | Dmove -> Umove
    | Dset -> Uset
end

let is_mut_param p =
  match p.pattr with Dmut -> true | Dnorm | Dset | Dmove -> false

let current_module = ref None

module Id = struct
  module Pathid = struct
    type t = string * Path.t option

    let show (s, p) =
      match p with Some p -> Path.show (Path.append s p) | None -> s

    let pp ppf p = Format.fprintf ppf "%s" (show p)

    let equal (a, ap) (b, bp) =
      match (ap, bp) with
      | Some ap, Some bp -> String.equal a b && Path.equal ap bp
      | None, None -> String.equal a b
      | None, Some _ | Some _, None -> false

    let compare (a, ap) (b, bp) =
      match (ap, bp) with
      | Some ap, Some bp ->
          let c = String.compare a b in
          if c == 0 then Path.compare ap bp else c
      | None, None -> String.compare a b
      | None, Some _ | Some _, None -> Stdlib.compare (a, ap) (b, bp)

    let startswith ~prefix (a, _) = String.starts_with ~prefix a
  end

  type t = Fst of Pathid.t | Shadowed of Pathid.t * int [@@deriving show]

  let compare a b = Stdlib.compare a b

  let equal a b =
    match (a, b) with
    | Fst a, Fst b -> Pathid.equal a b
    | Shadowed (a, ai), Shadowed (b, bi) ->
        let c = Pathid.equal a b in
        if c then Int.equal ai bi else c
    | Fst _, Shadowed _ | Shadowed _, Fst _ -> false

  let is_string s =
    match fst s with
    | Fst s | Shadowed (s, _) -> Pathid.startswith ~prefix:"__string" s

  let s (s, part) =
    let name = match s with Fst s -> s | Shadowed (s, _) -> s in
    let fmt (name, p) =
      match p with
      | Some p ->
          let mname = Option.get !current_module in
          Path.(rm_name mname (append name p) |> show)
      | None -> name
    in
    match part with
    | [] -> fmt name
    | l when Pathid.startswith ~prefix:"__expr" name ->
        (* Special case for pattern matches in lets *)
        String.concat "." (List.map snd l)
    | l -> fmt name ^ "." ^ String.concat "." (List.map snd l)

  let only_id = function Fst (id, _) -> id | Shadowed ((id, _), _) -> id
end

type borrow = {
  ord : int;
  loc : Ast.loc;
  borrowed : borrowed;
  repr : Id.t;
  repr_ord : int;
  special : special_case;
}

and borrowed = { id : Id.t; bpart : part_access; borrows : borrows }

(* Each original value has a tbl of borrowed bindings. This is used to count
   borrows and give each borrowed variable a single integer identifier. To
   support inner borrows not affecting outer borrows, the borrow checker only
   has to take into account borrows with less-equal id, see [is_relevant]. *)
and borrows = ((Id.t, int) Hashtbl.t[@opaque])
and env_item = { imm : binding list; delayed : binding list }

and binding =
  | Bown of Id.t * borrows
  | Borrow of borrow
  | Borrow_mut of borrow * Usage.set
  | Bmove of borrow * Ast.loc option

and part_access = (access_kind * string) list
and access_kind = Aconst of int | Avar of Id.t | Adyn of int
and special_case = Sp_no | Sp_string | Sp_array_get [@@deriving show]

let imm imm = { imm; delayed = [] }

let part_equal a b =
  match (a, b) with
  | Aconst a, Aconst b -> Int.equal a b
  | Avar a, Avar b -> Id.equal a b
  | Adyn a, Adyn b -> Int.equal a b
  | _ -> false

let parts_match a wth =
  let rec parts_match = function
    | (i, _) :: tl, (j, _) :: tr ->
        if part_equal i j then parts_match (tl, tr)
        else (* Borrows concern different parts *) false
    | [], _ -> true
    | _, [] -> (* Borrows are not mutually exclusive *) true
  in
  assert (Id.equal a.id wth.id);
  (* New parts are added via List cons, thus new items are at the front of the
     list. We want to compare matching parts, so we need to reverse. *)
  parts_match (List.rev a.bpart, List.rev wth.bpart)

let is_relevant a wth = a.repr_ord >= wth.repr_ord && a.ord < wth.ord

let parts_is_sub a wth =
  (* Part goes deeper than the [wth] structure *)
  let rec parts_sub = function
    | (i, _) :: tl, (j, _) :: tr ->
        if part_equal i j then parts_sub (tl, tr)
        else (* Borrows concern different parts *) false
    | [], _ -> false
    | _, [] -> (* Borrows are not mutually exclusive *) true
  in
  assert (Id.equal a.id wth.id);
  parts_sub (a.bpart, wth.bpart)

let are_borrow bs =
  let is_borrow = function
    | Bown _ | Bmove _ -> false
    | Borrow _ | Borrow_mut _ -> true
  in
  match bs with
  | [] -> false
  | bs -> List.fold_left (fun is b -> is && is_borrow b) true bs

type bopt = binding option [@@deriving show]

module Smap = Map.Make (Id.Pathid)
module Map = Map.Make (Id)
module Iset = Set.Make (Int)
module Idset = Set.Make (Id)

let borrow_state = ref 0
let param_pass = ref false
let shadowmap = ref Smap.empty
let array_bindings = ref Idset.empty
let mutables = ref Map.empty
let global_get_decl = ref None

let gg_decl () =
  (* get_get_decl *)
  Option.get !global_get_decl

let is_string = function Sp_string -> true | Sp_no | Sp_array_get -> false

let new_id str mname =
  let str = (str, mname) in
  match Smap.find_opt str !shadowmap with
  | Some i ->
      shadowmap := Smap.add str (i + 1) !shadowmap;
      Id.Shadowed (str, i)
  | None ->
      shadowmap := Smap.add str 1 !shadowmap;
      Id.Fst str

let get_id str =
  match Smap.find_opt str !shadowmap with
  | None | Some 1 -> Id.Fst str
  | Some i -> Id.Shadowed (str, i - 1)

let reset get_decl =
  borrow_state := 0;
  param_pass := false;
  shadowmap := Smap.empty;
  array_bindings := Idset.empty;
  mutables := Map.empty;
  global_get_decl := Some get_decl

let forbid_conditional_borrow loc imm mut =
  let msg =
    "Cannot move conditional borrow. Either copy or directly move conditional \
     without borrowing"
  in
  match mut with
  | Usage.Umove -> (
      match imm with
      | [] | [ _ ] -> ()
      | _ :: _ ->
          (* If it contains multiple borrows (from an if), we
             don't know which one to free *)
          if are_borrow imm then raise (Error (loc, msg)))
  | _ -> ()

let dont_surface_internals id part =
  let s = Id.s (id, part) in
  if String.starts_with ~prefix:"__" s then "" else s

let rec check_exclusivity loc borrow hist =
  let p = Printf.sprintf in
  match (borrow, hist) with
  (* TODO only check String.equal once *)
  | _, [] ->
      print_endline (show_binding borrow);
      failwith "Internal Error: Should never be empty"
  | Bown _, _ -> ()
  | (Borrow b | Borrow_mut (b, _) | Bmove (b, _)), Bown (name, _) :: _
    when Id.equal b.borrowed.id name ->
      ()
  | Borrow l, Borrow r :: tl when parts_match l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then () else check_exclusivity loc borrow tl
  | Borrow_mut (l, _), Borrow_mut (r, _) :: _
    when parts_match l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if is_relevant l r then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was mutably borrowed %sin line %i, cannot borrow"
            (Id.s (r.borrowed.id, r.borrowed.bpart))
            (* r- and l.borrowed.id are the same *)
            (if not (Id.equal l.borrowed.id l.repr) then
               let repr = dont_surface_internals l.repr l.borrowed.bpart in
               if String.length repr = 0 then " "
               else "as " ^ Id.s (l.repr, []) ^ " "
             else "")
            (fst l.loc).pos_lnum
        in
        raise (Error (r.loc, msg))
      else ()
  | Borrow l, Borrow_mut (r, _) :: _ when parts_match l.borrowed r.borrowed ->
      if is_relevant l r then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was borrowed in line %i, cannot mutate"
            (Id.s (r.repr, r.borrowed.bpart))
            (fst l.loc).pos_lnum
        in
        raise (Error (r.loc, msg))
      else ()
  | Borrow_mut (l, _), Borrow r :: _ when parts_match l.borrowed r.borrowed ->
      if is_relevant l r then
        (* Mutable borrow still active while borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow"
            (Id.s (r.repr, r.borrowed.bpart))
            (fst l.loc).pos_lnum
        in
        raise (Error (r.loc, msg))
      else ()
  | (Borrow b | Bmove (b, _) | Borrow_mut (b, Dont_set)), Bmove (m, l) :: _
  (* Allow mutable borrow for setting new values *)
    when parts_match b.borrowed m.borrowed ->
      (* Accessing a moved value *)
      let loc, msg =
        if not !param_pass then
          let hint =
            match l with
            | Some (l, _) -> p ". Move occurs in line %i" l.pos_lnum
            | None -> ""
          in
          ( loc,
            p "%s was moved %sin line %i, cannot use%s"
              (Id.s (m.borrowed.id, m.borrowed.bpart))
              (let repr = dont_surface_internals m.repr []
               and id = Id.s (m.borrowed.id, []) in
               if not (String.equal id repr || String.length repr = 0) then
                 "as " ^ repr ^ " "
               else "")
              (fst m.loc).pos_lnum hint )
        else
          ( m.loc,
            p "Borrowed parameter %s is moved"
              (dont_surface_internals b.borrowed.id b.borrowed.bpart) )
      in
      raise (Error (loc, msg))
  | Borrow_mut (b, Set), Bmove (m, l) :: _
    when parts_is_sub b.borrowed m.borrowed ->
      let loc, msg =
        if not !param_pass then
          let hint =
            match l with
            | Some (l, _) -> p ". Move occurs in line %i" l.pos_lnum
            | None -> ""
          in
          ( loc,
            p "%s was moved in line %i, cannot set %s%s"
              (Id.s (m.borrowed.id, m.borrowed.bpart))
              (fst m.loc).pos_lnum
              (Id.s (b.borrowed.id, b.borrowed.bpart))
              hint )
        else
          ( m.loc,
            p "Borrowed parameter %s is moved, cannot set"
              (dont_surface_internals b.borrowed.id b.borrowed.bpart) )
      in
      raise (Error (loc, msg))
  | Bmove (m, _), (Borrow b | Borrow_mut (b, _)) :: _
    when parts_match m.borrowed b.borrowed ->
      (* The moving value was borrowed correctly before *)
      ()
  | _, _ :: tl -> check_exclusivity loc borrow tl

let make_copy_call loc tree =
  let typ = Tfun ([ { pattr = Dnorm; pt = tree.typ } ], tree.typ, Simple) in
  let callee = { typ; attr = no_attr; loc; expr = Var ("__copy", None) } in
  let expr = App { callee; args = [ (tree, Dnorm) ] } in
  { tree with attr = { tree.attr with const = false }; expr }

let string_lit_borrow tree mut =
  let loc = Typed_tree.(tree.loc) in
  let copy tree = make_copy_call loc tree and borrows = Hashtbl.create 1 in
  let borrowed = { id = new_id "__string" None; bpart = []; borrows } in
  let repr = borrowed.id in
  match mut with
  | Usage.Uread ->
      incr borrow_state;
      let ord = !borrow_state and special = Sp_string and repr_ord = 1 in
      let b = Borrow { ord; loc; borrowed; repr; special; repr_ord } in
      (tree, imm [ b ])
  | Umove -> (copy tree, imm [])
  | Umut | Uset -> failwith "Internal Error: Mutating string"

(* For now, throw everything into one list of bindings.
   In the future, each owning binding could have its own list *)

let add_binding b hist =
  let bind_name = function
    | Bown (n, _) -> n
    | Borrow b | Borrow_mut (b, _) | Bmove (b, _) -> b.borrowed.id
  in
  let name = bind_name b in
  match Map.find_opt name hist with
  | Some l -> Map.add name (b :: l) hist
  | None -> Map.add name (b :: []) hist

let add_hist v hs =
  match v.imm with
  | [] -> hs
  | hist -> List.fold_left (fun hs b -> add_binding b hs) hs hist

let rec find_usage_inner ?(partial = false) parts_set = function
  | [ Bown _ ] -> (Ast.Dnorm, None)
  | [ Borrow _ ] -> (* String literals are owned by noone *) (Ast.Dnorm, None)
  | Borrow_mut (b, Dont_set) :: _ -> (Dmut, Some b.loc)
  | Borrow_mut (b, Set) :: tl -> (
      match b.borrowed.bpart with
      | [] ->
          (* Set the whole thing, that's our usage *)
          (Dset, Some b.loc)
      | part ->
          (* Only parts are set, other parts could still be moved *)
          find_usage_inner ~partial (Iset.add (Hashtbl.hash part) parts_set) tl)
  | Bmove (b, _) :: tl -> (
      match b.borrowed.bpart with
      | [] -> (* Moved the whole thing *) (Dmove, Some b.loc)
      | part -> (
          let hash = Hashtbl.hash part in
          match Iset.find_opt hash parts_set with
          | Some hash ->
              (* This has been re-set after, we continue *)
              find_usage_inner ~partial (Iset.remove hash parts_set) tl
          | None -> (* Moved and never was re-set *) (Dmove, Some b.loc)))
  | Borrow _ :: tl -> find_usage_inner ~partial parts_set tl
  | Bown _ :: tl -> find_usage_inner ~partial parts_set tl (* binds? *)
  | [] when partial -> (Dnorm, None)
  | [] -> failwith "Internal Error: Should have been added as owned"

let rec new_elems nu keep old =
  match (nu, old) with
  | _, [] -> nu
  | a :: _, b :: _ when a == b -> List.rev keep
  | a :: tl, _ -> new_elems tl (a :: keep) old
  | _ -> failwith "Internal Error: Impossible"

let integrate_new_elems ~a ~b ~old =
  (* For each id, find the new items in [a] and [b] with respect to [old]. The
     add them. When adding them, we prioritize the side which has [Dmove] usage.
     Otherwise, we might miss moves of outer scope variables because we report a
     usage other than [Dmove]. *)
  let integrated = ref old in
  Map.merge
    (fun id a b ->
      let old = match Map.find_opt id old with Some l -> l | None -> [] in
      let merged =
        match (a, b) with
        | Some a, None -> a
        | None, Some b -> b
        | Some a, Some b -> (
            let a = new_elems a [] old in
            let b = new_elems b [] old in
            match
              ( fst (find_usage_inner ~partial:true Iset.empty a),
                fst (find_usage_inner ~partial:true Iset.empty b) )
            with
            | Dmove, _ -> a @ b
            | _, Dmove -> b @ a
            | _ -> a @ b)
        | None, None -> failwith "unreachable"
      in
      integrated := Map.add id (merged @ old) !integrated;
      None)
    a b
  |> ignore;
  !integrated

let move_local_borrow bs env =
  let rec aux = function
    | [] -> bs
    | Borrow b :: _ when is_string b.special -> bs
    | (Borrow b | Borrow_mut (b, _)) :: tl ->
        if Map.mem b.borrowed.id env |> not then imm [] else aux tl
    | (Bown _ | Bmove _) :: tl -> aux tl
  in
  aux bs.imm

let rec check_excl_chain loc env borrow hist =
  match borrow with
  | Bown _ -> ()
  | Borrow b | Borrow_mut (b, _) | Bmove (b, _) -> (
      (* print_endline "---------------"; *)
      (* print_endline (show_binding borrow); *)
      (* print_newline (); *)
      (* print_endline *)
      (*   (String.concat "\n" *)
      (*      (Map.to_seq hist |> List.of_seq *)
      (*      |> List.map (fun (id, l) -> *)
      (*             Id.show id ^ ": " *)
      (*             ^ String.concat ", " (List.map show_binding l)))); *)
      check_exclusivity loc borrow (Map.find b.borrowed.id hist);
      match Map.find_opt b.borrowed.id env with
      | Some { imm; delayed = _ } -> check_excl_chains loc env imm hist
      | None -> ())

and check_excl_chains loc env borrow hist =
  List.iter (fun b -> check_excl_chain loc env b hist) borrow

let make_var loc name mname typ =
  { typ; expr = Var (name, mname); attr = no_attr; loc }

let binding_of_borrow borrow = function
  | Usage.Uread -> Borrow borrow
  | Umut -> Borrow_mut (borrow, Dont_set)
  | Uset -> Borrow_mut (borrow, Set)
  | Umove -> Bmove (borrow, None)

let no_bdata = ([], Sp_no)

let check_special loc usage special =
  match (usage, special) with
  | Usage.Umove, Sp_string ->
      raise (Error (loc, "Cannot move string literal. Use `copy`"))
  | (Uset | Umut), Sp_string ->
      raise (Error (loc, "Cannot mutate string literal. Use `copy`"))
  | _, _ -> ()

let move_b loc special b =
  let special =
    match (special, b.special) with
    | Sp_array_get, Sp_string -> failwith "Internal Error: string lit array get"
    | Sp_array_get, _ -> special
    | _ -> b.special
  in
  { b with loc; special }

let move_closed (tree : Typed_tree.typed_expr) c =
  (* Prepend a move of closure [c] to [tree] *)
  let var = make_var tree.loc c.clname c.clmname c.cltyp in
  let move = { var with expr = Move var } in
  { tree with expr = Sequence (move, tree) }

let get_closed_make_usage usage tree (use : touched) =
  match usage with
  | Usage.Uread -> (tree, Usage.of_attr use.tattr)
  | Umove -> (
      match repr tree.typ with
      | Tfun (_, _, Closure cls) -> (
          match
            List.find_opt (fun c -> String.equal c.clname use.tname) cls
          with
          | Some c ->
              if c.clcopy then (tree, Uread)
              else
                (* Move the closed variable into the closure *)
                (move_closed tree c, Umove)
          | None -> (* Touched but not closed? Let's read it *) (tree, Uread))
      | Tfun _ -> (tree, Uread)
      | _ -> failwith "Internal Error: Not a function type")
  | Uset | Umut -> failwith "unreachable"

let get_closed_make_usage_delayed tree b =
  (* Compared to above, we are implicitly in the [Umove] usage *)
  match repr tree.typ with
  | Tfun (_, _, Closure cls) -> (
      let id = Id.only_id b.borrowed.id in
      match List.find_opt (fun c -> String.equal c.clname id) cls with
      | Some c ->
          if c.clcopy then (tree, Usage.Uread)
          else
            (* Move the closed variable into the closure *)
            (move_closed tree c, Umove)
      | None -> (* Touched but not closed? Let's read it *) (tree, Uread))
  | Tfun _ -> failwith "Oh really?!"
  | _ -> failwith "Internal Error: Not a function type"

let make_usage tree (use : touched) = (tree, Usage.of_attr use.tattr)

let cond_usage typ then_ else_ =
  if contains_allocation (gg_decl ()) typ then then_ else else_

let get_repr_ord ~borrows repr =
  match Hashtbl.find_opt borrows repr with
  | Some ctr -> ctr
  | None ->
      let ctr = Hashtbl.length borrows in
      Hashtbl.replace borrows repr ctr;
      ctr

let mark_mutated env_item =
  let rec mark_mutated id =
    match Map.find_opt id !mutables with
    | Some parent ->
        (match parent with Some p, _ -> mark_mutated p | None, _ -> ());
        mutables := Map.remove id !mutables
    | None ->
        (* It has already been marked as mutated. Nothing more to do *)
        ()
  in

  match env_item.imm with
  | [] -> ()
  | items ->
      List.iter
        (function
          | Borrow_mut (b, _) -> mark_mutated b.repr
          | Bmove _ | Borrow _ | Bown _ -> ())
        items

let check_mutated () =
  Map.fold
    (fun _ (_, loc) acc ->
      (* Mutated bindings have been removed. All remaining ones have not been mutated. *)
      loc :: acc)
    !mutables []
  |> List.rev

let get_moved_in_set env_item hist =
  let rec usage b = function
    | [ (Bown _ | Borrow _) ] -> Snot_moved
    | (Borrow_mut (other, _) | Borrow other) :: tl ->
        (* Either it has been set, so not moved, or used thus not moved *)
        if parts_match b.borrowed other.borrowed then Snot_moved else usage b tl
    | Bmove (other, _) :: tl ->
        if parts_match b.borrowed other.borrowed then
          if parts_is_sub other.borrowed b.borrowed then Spartially_moved
          else Smoved
        else usage b tl
    | Bown _ :: _ | [] -> failwith "unreachable"
  in

  match env_item.imm with
  | [] -> Snot_moved
  | [ Borrow_mut (b, Set) ] -> usage b (Map.find b.borrowed.id hist)
  | _ ->
      print_endline (show_env_item env_item);
      failwith "Internal Error: What happened here?"

let collect_array_move env_item =
  match env_item.imm with
  | [] -> failwith "unreachable"
  | [ Bmove (b, _) ] ->
      array_bindings := Idset.add b.borrowed.id !array_bindings
  | _ -> failwith "what else?!"

let add_part part b =
  let borrowed = { b.borrowed with bpart = part @ b.borrowed.bpart } in
  { b with borrowed }

let rec check_tree env mut ((bpart, special) as bdata) tree hist =
  match tree.expr with
  | Var (borrowed, mname) ->
      (* This is no rvalue, we borrow *)
      let repr = get_id (borrowed, mname) in
      let loc = tree.loc in
      let make b =
        let repr_ord = get_repr_ord ~borrows:b.borrowed.borrows repr in
        { b with loc; ord = !borrow_state; repr; repr_ord }
      in
      (* TODO add parts to checks *)
      let borrow mut = function
        | Bown (id, borrows) ->
            incr borrow_state;
            let borrow =
              let borrowed = { id; bpart; borrows }
              and ord = !borrow_state
              and repr_ord = get_repr_ord ~borrows id in
              { ord; loc; borrowed; repr = id; special; repr_ord }
            in
            (* Assume it's the only borrow. This works because if it isn't, a borrowed binding
               will be used later and thin fail the check. Extra care has to be taken for
               arguments to functions *)
            let b = binding_of_borrow borrow mut in
            check_excl_chain loc env b hist;
            b
        | Borrow_mut (b, s) -> (
            check_special tree.loc mut b.special;
            let b' = add_part bpart b in
            let b = Borrow_mut (b', s) in
            match mut with
            | Usage.Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b hist;
                Bmove (move_b loc special b', None)
            | Umut | Uread ->
                check_excl_chain loc env b hist;
                incr borrow_state;
                Borrow_mut (make b', s)
            | Uset ->
                check_excl_chain loc env (Borrow_mut (b', Set)) hist;
                incr borrow_state;
                Borrow_mut (make b', Set))
        | Borrow b -> (
            check_special tree.loc mut b.special;
            let b = add_part bpart b in
            match mut with
            | Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env (Borrow b) hist;
                Bmove (move_b loc special b, None)
            | Umut ->
                check_excl_chain loc env (Borrow_mut (b, Dont_set)) hist;
                incr borrow_state;
                Borrow_mut (make b, Dont_set)
            | Uset ->
                check_excl_chain loc env (Borrow_mut (b, Set)) hist;
                incr borrow_state;
                Borrow_mut (make b, Set)
            | Uread ->
                check_excl_chain loc env (Borrow b) hist;
                incr borrow_state;
                Borrow (make b))
        | Bmove (m, l) ->
            (* The binding is about to be moved for the first time, e.g. in a function *)
            let m = add_part bpart m in
            check_excl_chain loc env (Bmove (m, l)) hist;
            Bmove (m, l)
      in

      let borrow_delayed delayed tree usage =
        let find_borrow usage b =
          match Map.find_opt b.borrowed.id env with
          | Some { imm; delayed = _ } -> List.map (fun b -> borrow usage b) imm
          | None -> []
        in
        (* Delayed things only appear in functions. And functions are either
           used = Uread or moved = Umove. They should never be mutated. We
           mutate the [tree] to add the moves of moved bindings captured by the
           closure which is being read *)
        let f (tree, acc) binding =
          let tree, bs =
            match usage with
            | Usage.Uread ->
                ( tree,
                  match binding with
                  | Bmove (b, _) -> find_borrow Umove b
                  | Borrow b -> find_borrow Uread b
                  | Borrow_mut (b, Set) -> find_borrow Uset b
                  | Borrow_mut (b, Dont_set) -> find_borrow Umut b
                  | Bown _ ->
                      failwith "Internal Error: A borrowed thing isn't owned" )
            | Umove -> (
                match binding with
                | Bmove (b, _) | Borrow b | Borrow_mut (b, _) ->
                    let tree, usage = get_closed_make_usage_delayed tree b in
                    (tree, find_borrow usage b)
                | Bown _ ->
                    failwith "Internal Error: A borrowed thing isn't owned")
            | Uset | Umut -> failwith "hmm"
          in
          (tree, List.rev_append bs acc)
        in
        List.fold_left f (tree, []) delayed
      in

      let tree, borrow =
        match Map.find_opt repr env with
        | Some { imm; delayed } ->
            let tree, delayed = borrow_delayed delayed tree mut in
            forbid_conditional_borrow loc imm mut;
            let imm = List.map (borrow mut) imm @ delayed in
            (tree, { imm; delayed = [] })
        | None -> (tree, imm [])
      in
      (* Don't add to hist here. Other expressions where the value is used
         will take care of this *)
      (tree, borrow, hist)
  | Let { id; id_loc; rhs; cont; pass; rmut; uniq } ->
      let rhs, env, b, hs, pass =
        check_let id_loc env id rhs rmut pass ~tl:false hist
      in
      let cont, v, hs = check_tree env mut bdata cont (add_hist b hs) in
      let expr = Let { id; id_loc; rhs; cont; pass; rmut; uniq } in
      ({ tree with expr }, v, hs)
  | Const (Array es) ->
      let hs, es =
        List.fold_left_map
          (fun hs e ->
            let usage = cond_usage e.typ Usage.Umove Uread in
            let expr, v, hs = check_tree env usage no_bdata e hs in
            let expr = { expr with expr = Move expr } in
            (add_hist v hs, expr))
          hist es
      in
      let expr = Const (Array es) in
      ({ tree with expr }, imm [], hs)
  | Const (Fixed_array es) ->
      let hs, es =
        List.fold_left_map
          (fun hs e ->
            let usage = cond_usage e.typ Usage.Umove Uread in
            let expr, v, hs = check_tree env usage no_bdata e hs in
            let expr = { expr with expr = Move expr } in
            (add_hist v hs, expr))
          hist es
      in
      let expr = Const (Fixed_array es) in
      ({ tree with expr }, imm [], hs)
  | Const (String _) ->
      let tree, b = string_lit_borrow tree mut in
      (tree, b, hist)
  | Const _ -> (tree, imm [], hist)
  | Record fs ->
      let hs, fs =
        List.fold_left_map
          (fun hs (n, (field : typed_expr)) ->
            let usage = cond_usage field.typ Usage.Umove Uread in
            let field, v, hs = check_tree env usage no_bdata field hs in
            let field = { field with expr = Move field } in
            (add_hist v hs, (n, field)))
          hist fs
      in
      let expr = Record fs in
      ({ tree with expr }, imm [], hs)
  | Field (t, i, name) ->
      (match mut with
      | Umove when t.attr.const ->
          raise (Error (tree.loc, "Cannot move out of constant"))
      | _ -> ());
      let t, b, hs =
        check_tree env mut ((Aconst i, name) :: bpart, special) t hist
      in
      let tree = { tree with expr = Field (t, i, name) } in
      (tree, b, hs)
  | Set (thing, value, _) ->
      let usage = cond_usage value.typ Usage.Umove Uread in
      let value, v, hs = check_tree env usage no_bdata value hist in
      let value = { value with expr = Move value } in
      let hs = add_hist v hs in
      (* Track usage of values, but not the one being mutated *)
      let thing, t, hs = check_tree env Uset no_bdata thing hs in
      let moved = get_moved_in_set t hs in
      mark_mutated t;
      let expr = Set (thing, value, moved) in
      ({ tree with expr }, t, add_hist t hs)
  | Sequence (fst, snd) ->
      let fst, _, hs = check_tree env Uread no_bdata fst hist in
      let snd, v, hs = check_tree env mut bdata snd hs in
      let expr = Sequence (fst, snd) in
      ({ tree with expr }, v, hs)
  | App
      {
        callee =
          ( { expr = Var ("__rc_get", _); _ }
          | { expr = Var ("get", Some (Pmod ("std", Pid "rc"))); _ } ) as callee;
        args = [ arg ];
      } ->
      (* Special case for rc_get. It effectively returns the same allocation as
         its first argument and thus needs special handling. *)
      let bdata = ((Aconst (-1), "payload") :: bpart, special) in
      let t, b, hs = check_tree env mut bdata (fst arg) hist in
      let tree = { tree with expr = App { callee; args = [ (t, snd arg) ] } } in
      (tree, b, hs)
  | App
      {
        callee =
          ( {
              expr =
                Var
                  (("__array_get" | "__fixed_array_get" | "__unsafe_ptr_get"), _);
              _;
            }
          | { expr = Var ("get", Some (Path.Pid "unsafe")); _ } ) as callee;
        args = [ arr; idx ];
      } ->
      (* Special case for __array_get *)
      (* Partial moves for arrays are only supported in a very limited way.
         Either by a constant index or by a variable. The same index or variable
         needs to be used to re-set the item otherwise it won't compile. In
         contrast to partial moves in records, arrays need to be re-set at the
         end of scope. This is because we cannot partially free them. *)
      let callee, b, hs = check_tree env Uread no_bdata callee hist in
      let hs = add_hist b hs in
      (* We don't check for exclusivity, because there are only two arguments
           and the second is an int *)
      let bpart, idx, hs, is_part =
        match (fst idx).expr with
        | Const (Int i) ->
            let part = (Aconst i, Printf.sprintf "[%i]" i) :: bpart in
            (part, idx, hs, true)
        | Var (name, mname) ->
            let part_id = get_id (name, mname) in
            let part = (Avar part_id, Printf.sprintf "[%s]" name) :: bpart in
            let usage = Usage.of_attr (snd idx) in
            let arg, v, hs = check_tree env usage no_bdata (fst idx) hs in
            (part, (arg, snd idx), add_hist v hs, true)
        | e ->
            (* Depending on hashes here is bound to break sometime *)
            let part =
              (Adyn (Hashtbl.hash e), Printf.sprintf "[<expr>]") :: bpart
            in
            let usage = Usage.of_attr (snd idx) in
            let arg, v, hs = check_tree env usage no_bdata (fst idx) hs in
            (part, (arg, snd idx), add_hist v hs, false)
      in
      let ar, b, hs = check_tree env mut (bpart, Sp_array_get) (fst arr) hs in
      (match mut with
      | Umove when is_part -> collect_array_move b
      | Umove ->
          raise (Error (tree.loc, "Cannot move out of array with this index"))
      | Uset | Uread | Umut -> ());
      let tree =
        { tree with expr = App { callee; args = [ (ar, snd arr); idx ] } }
      in
      (tree, b, hs)
  | App { callee; args } ->
      (* The callee itself can be borrowed *)
      let callee, b, hs = check_tree env Uread no_bdata callee hist in
      let tmp = Map.add (Fst ("_env", None)) b env in
      let (_, tmp, hs), args =
        List.fold_left_map
          (fun (i, tmp, hs) (arg, attr) ->
            let usage = cond_usage arg.typ (Usage.of_attr attr) Uread in
            let arg, v, hs = check_tree env usage no_bdata arg hs in
            let arg =
              match usage with
              | Umove -> { arg with expr = Move arg }
              | Uread | Umut | Uset -> arg
            in
            let tmp = Map.add (Fst ("_" ^ string_of_int i, None)) v tmp in
            ((i + 1, tmp, add_hist v hs), (arg, attr)))
          (0, tmp, add_hist b hs)
          args
      in
      (* Check again to ensure exclusivity of arguments and closure *)
      let c = { callee with expr = Var ("_env", None) } in
      check_tree tmp Uread no_bdata c hs |> ignore;
      List.iteri
        (fun i (arg, attr) ->
          let usage = cond_usage arg.typ (Usage.of_attr attr) Uread in
          match usage with
          | Umove ->
              (* Moved values can't have been used later *)
              ()
          | u ->
              let expr = Var ("_" ^ string_of_int i, None) in
              let arg = { arg with expr } in
              check_tree tmp u no_bdata arg hs |> ignore)
        args;
      let expr = App { callee; args } in
      (* A function cannot return a borrowed value *)
      ({ tree with expr }, imm [], hs)
  | Bop (op, fst, snd) ->
      let fst, v, hs = check_tree env Uread no_bdata fst hist in
      let snd, v, hs = check_tree env Uread no_bdata snd (add_hist v hs) in
      let expr = Bop (op, fst, snd) in
      ({ tree with expr }, imm [], add_hist v hs)
  | Unop (op, e) ->
      let e, v, hs = check_tree env Uread no_bdata e hist in
      let expr = Unop (op, e) in
      ({ tree with expr }, imm [], add_hist v hs)
  | If (cond, _, ae, be) ->
      let cond, v, hs = check_tree env Uread no_bdata cond hist in
      let hs = add_hist v hs in
      let shadows = !shadowmap in
      let ae, a, ahs = check_tree env mut bdata ae hs in
      let a = move_local_borrow a env in

      shadowmap := shadows;
      let be, b, bhs = check_tree env mut bdata be hs in
      let b = move_local_borrow b env in
      shadowmap := shadows;

      (* Make sure borrow kind of both branches matches *)
      let _raise msg = raise (Error (tree.loc, msg)) in
      let imm =
        match (a.imm, b.imm) with
        (* Ignore Bown _ cases, as it can't be returned. Would be borrowed *)
        (* Owning *)
        | [], [] -> []
        | [], b when are_borrow b ->
            if contains_allocation (gg_decl ()) be.typ then
              _raise "Branches have different ownership: owned vs borrowed"
            else []
        | a, [] when are_borrow a ->
            if contains_allocation (gg_decl ()) ae.typ then
              _raise "Branches have different ownership: borrowed vs owned"
            else []
        | [], a | a, [] -> a
        (* If both branches are (Some _), they have to be both the same kind,
           because it was applied in Var.. above*)
        | a, b ->
            assert (are_borrow a == are_borrow b);
            a @ b
      in
      let owning = are_borrow a.imm |> not in
      let delayed = a.delayed @ b.delayed in
      let expr = If (cond, Some owning, ae, be) in
      let hs = integrate_new_elems ~a:ahs ~b:bhs ~old:hs in
      ({ tree with expr }, { imm; delayed }, hs)
  | Ctor (name, i, e) -> (
      match e with
      | Some e ->
          let usage = cond_usage e.typ Usage.Umove Uread in
          let e, v, hs = check_tree env usage no_bdata e hist in
          let e = { e with expr = Move e } in
          let expr = Ctor (name, i, Some e) in
          ({ tree with expr }, imm [], add_hist v hs)
      | None -> (tree, imm [], hist))
  | Variant_index e ->
      let e, v, hs = check_tree env mut bdata e hist in
      let expr = Variant_index e in
      ({ tree with expr }, v, hs)
  | Variant_data e ->
      let e, v, hs = check_tree env mut bdata e hist in
      let expr = Variant_data e in
      ({ tree with expr }, v, hs)
  | Fmt fs ->
      let hs, fs =
        List.fold_left_map
          (fun hs -> function
            | Fstr _ as str -> (hs, str)
            | Fexpr e ->
                let e, v, hs = check_tree env Uread no_bdata e hs in
                (add_hist v hs, Fexpr e))
          hist fs
      in
      let expr = Fmt fs in
      ({ tree with expr }, imm [], hs)
  | Mutual_rec_decls (decls, cont) ->
      let cont, v, hs = check_tree env mut bdata cont hist in
      let expr = Mutual_rec_decls (decls, cont) in
      ({ tree with expr }, v, hs)
  | Lambda (_, abs) ->
      let usage = get_closed_make_usage mut in
      (* Lambdas immediately borrow (and capture) their closed objects, so we
         return a modified [tree] here which contains the needed moves *)
      let tree, imm = check_abstraction env tree usage abs.func.touched hist in
      (tree, { imm; delayed = [] }, hist)
  | Function (name, u, abs, cont) ->
      (* Uread means it's not moved. The function is defined here, it might be
         moved later, but not here *)
      let _, bindings =
        check_abstraction env tree make_usage abs.func.touched hist
      in
      let env =
        match List.rev bindings with
        | [] -> env
        | bs ->
            Map.add (Fst (name, !current_module)) { imm = []; delayed = bs } env
      in
      let cont, v, hs = check_tree env mut bdata cont hist in
      let expr = Function (name, u, abs, cont) in
      ({ tree with expr }, v, hs)
  | Bind (name, expr, cont) ->
      (* In Let expressions, the mut attribute indicates whether the binding is
         mutable. In all other uses (including this one) it refers to the expression.
         Change it to mut = false to be consistent with read only Binds *)
      let e, b, env, hist = check_bind env name expr hist in
      let cont, v, hs = check_tree env mut bdata cont (add_hist b hist) in
      let expr = Bind (name, e, cont) in
      ({ tree with expr }, v, hs)
  | Move _ -> failwith "Internal Error: Nothing should have been moved here"

and check_let ~tl loc env id rhs rmut pass hist =
  let nmut, tlborrow, unspec_passing =
    match (rhs.attr.mut, pass) with
    | _, Dset -> failwith "unreachable"
    | true, Dmut when not rmut ->
        raise (Error (rhs.loc, "Cannot project immutable binding"))
    | true, Dmut -> (Usage.Umut, false, false)
    | true, Dmove -> (Umove, false, false)
    | true, Dnorm -> (* For rvalues, default to move *) (Umove, false, true)
    | false, Dnorm ->
        (* Cannot borrow mutable bindings at top level. We defer error
           generation until we are sure the rhs is really borrowed *)
        (Uread, rmut && tl, false)
    | false, Dmove -> (Umove, false, false)
    | false, Dmut ->
        (* This is actually reachable in pattern matches. Treat it as read-only *)
        (Uread, false, false)
  in
  let rhs, rval, hs = check_tree env nmut no_bdata rhs hist in
  let neword () =
    incr borrow_state;
    !borrow_state
  in
  let id = new_id id !current_module in
  let borrow hs = function
    | Bmove _ when unspec_passing ->
        raise
          (Error
             ( rhs.loc,
               "Specify how rhs expression is passed. Either by move '!' or \
                mutably '&'" ))
    | Bmove _ as b ->
        if rhs.attr.mut then mutables := Map.add id (None, loc) !mutables;
        (Bown (id, Hashtbl.create 32), add_hist (imm [ b ]) hs)
    | (Borrow _ | Borrow_mut _) when tlborrow ->
        raise (Error (rhs.loc, "Cannot borrow mutable binding at top level"))
    | Borrow b -> (Borrow { b with loc; ord = neword () }, hs)
    | Borrow_mut (b, s) ->
        mutables := Map.add id (Some b.repr, loc) !mutables;
        (Borrow_mut ({ b with loc; ord = neword () }, s), hs)
    | Bown _ -> failwith "Internal Error: A borrowed thing isn't owned"
  in
  let imm, hs =
    match rval.imm with
    | [] ->
        if rhs.attr.mut then mutables := Map.add id (None, loc) !mutables;
        (* No borrow, original, owned value *)
        ([ Bown (id, Hashtbl.create 32) ], hs)
    | b ->
        (* Switch order so that first move appears near the head of borrow list.
           This way, the first move is reported first (if both move the same
           thing) *)
        let bindings, hist =
          List.fold_right
            (fun b (bindings, hist) ->
              let b, hist = borrow hist b in
              (b :: bindings, hist))
            b ([], hs)
        in
        (bindings, hist)
  in
  let b = { rval with imm } in
  (* Add borrow to env for both the new id *)
  let env = Map.add id b env in
  let rhs, pass =
    match nmut with
    | Umove ->
        (* Literals are moved without having to specify move passing. To ensure
           that mallocs are tracked correctly we change the passing to move to
           match the tree with reality *)
        ({ rhs with expr = Move rhs }, Dmove)
    | Umut | Uset | Uread -> (rhs, pass)
  in
  (rhs, env, b, hs, pass)

and check_bind env name expr hist =
  let e, b, hist = check_tree env Uread no_bdata expr hist in
  let id = new_id name !current_module in
  let env =
    match b.imm with [] -> env | imm -> Map.add id { imm; delayed = [] } env
  in
  (e, b, env, hist)

and check_abstraction env tree usage touched hist =
  List.fold_left
    (fun (tree, bindings) (use : touched) ->
      (* For moved values, don't check touched here. Instead, add them as
         bindings later so they get moved on first use *)
      let tree, usage = usage tree use in
      let var = make_var tree.loc use.tname use.tmname use.ttyp in
      let _, b, _ = check_tree env usage no_bdata var hist in
      (tree, b.imm @ bindings))
    (tree, []) touched

let check_item (env, bind, mut, part, hist) = function
  | Tl_let ({ loc; id; rmut; pass; lhs; uniq = _ } as e) ->
      if pass = Dmut then raise (Error (lhs.loc, "Cannot project at top level"))
      else
        let lhs, env, b, hs, pass =
          check_let loc env id lhs rmut pass ~tl:true hist
        in
        ((env, bind, mut, part, add_hist b hs), Tl_let { e with lhs; pass })
  | Tl_bind (name, expr) ->
      let e, _, env, hist = check_bind env name expr hist in
      ((env, bind, mut, part, hist), Tl_bind (name, e))
  | Tl_expr e ->
      (* Basically a sequence *)
      let e, b, hs = check_tree env Uread no_bdata e hist in
      ((env, bind, mut, part, add_hist b hs), Tl_expr e)
  | Tl_function (_, name, _, abs) as f ->
      (* Functions don't caputure on definition, but on first usage. This comes
         in handy here as we don't have a correct tree to pass to
         [check_abstraction]. Passing [abs.body] doesn't make any sense here.
         The returned modified tree is discareded anyway so no harm is done. But
         this only works if the assumption holds that capture happens later,
         through the delayed bindings. See also [Function] above *)
      let _, bindings =
        check_abstraction env abs.body make_usage abs.func.touched hist
      in
      let env =
        match List.rev bindings with
        | [] -> env
        | bs ->
            (* Mark mutated bindings in function as mutated *)
            mark_mutated { imm = bs; delayed = [] };
            Map.add (Fst (name, !current_module)) { imm = []; delayed = bs } env
      in
      ((env, bind, mut, part, hist), f)
  | (Tl_mutual_rec_decls _ | Tl_module _ | Tl_module_alias _) as item ->
      ((env, bind, mut, part, hist), item)

let find_usage id hist =
  (* The hierarchy is move > mut > read. Since we read from the end,
     the first borrow means the binding was not moved *)
  match Map.find_opt id hist with
  | Some hist -> find_usage_inner Iset.empty hist
  | None ->
      (* The binding was not used *)
      (Ast.Dnorm, None)

let check_array_moves hist =
  Idset.iter
    (fun b ->
      let attr, loc = find_usage b hist in
      match attr with
      | Dmove ->
          let loc = Option.get loc in
          raise (Error (loc, "Cannot move out of array without re-setting"))
      | Dset | Dmut | Dnorm -> ())
    !array_bindings

let check_tree ~mname get_decl pts pns touched body =
  reset get_decl;
  current_module := Some mname;

  (* Add parameters to initial environment *)
  let borrow_of_param id loc borrows =
    incr borrow_state;
    let borrowed = { id; bpart = []; borrows }
    and repr_ord = get_repr_ord ~borrows id in
    { ord = !borrow_state; loc; borrowed; repr = id; special = Sp_no; repr_ord }
  in

  (* Shadowing between touched variables and parameters is impossible. If a
     parameter exists with the same name, the variable would not have been
     closed over / touched *)
  (* touched variables *)
  let env, hist =
    List.fold_left
      (fun (map, hs) t ->
        let id = new_id t.tname t.tmname in
        assert (Id.equal id (Fst (t.tname, t.tmname)));
        let b = [ Bown (id, Hashtbl.create 32) ] in
        (Map.add id (imm b) map, add_hist (imm b) hs))
      (Map.empty, Map.empty) touched
  in

  let param_borrows = List.map (fun _ -> Hashtbl.create 32) pns in
  (* parameters *)
  let i = ref 0 in
  let env, hist =
    List.fold_left2
      (fun (map, hs) p (n, loc) ->
        (* Parameters are not owned, but using them as owned here makes it
           easier for borrow checking. Correct usage of mutable parameters is
           already handled in typing.ml *)
        let id = new_id n None in
        (* Parameters get no mname *)
        assert (Id.equal id (Fst (n, None)));
        (* Register mutable variables *)
        (match p.pattr with
        | Dmut -> mutables := Map.add id (None, loc) !mutables
        | _ -> ());
        let b = [ Bown (id, List.nth param_borrows !i) ] in
        incr i;
        (Map.add id (imm b) map, add_hist (imm b) hs))
      (env, hist) pts pns
  in

  (* [Umove] because we want to move return values *)
  let usage = cond_usage body.typ Usage.Umove Uread in
  let body, v, hist = check_tree env usage no_bdata body hist in
  let body = { body with expr = Move body } in

  check_array_moves hist;
  (* Try to borrow the params again to make sure they haven't been moved *)
  let hist = add_hist v hist in
  param_pass := true;
  i := 0;
  List.iter2
    (fun p (n, loc) ->
      let n = (n, None) in
      (* If there's no allocation, copying and moving are the same thing.
         However, for mutable parameters, we need to check as well, because we
         don't want to silently copy a mutable parameter into a closure.
         Silently copying would lead to the closure mutating a copy, which is
         not expected from the call site. *)
      if contains_allocation (gg_decl ()) p.pt || is_mut_param p then
        let borrows = List.nth param_borrows !i in
        let borrow = borrow_of_param (Fst n) loc borrows in
        match p.pattr with
        | Dnorm -> check_excl_chain loc env (Borrow borrow) hist
        | Dmut -> check_excl_chain loc env (Borrow_mut (borrow, Dont_set)) hist
        | Dset -> check_excl_chain loc env (Borrow_mut (borrow, Set)) hist
        | Dmove -> ())
    pts pns;

  let touched =
    List.map
      (fun t ->
        let tattr, tattr_loc = find_usage (Fst (t.tname, t.tmname)) hist in
        (match tattr with
        | Dmove ->
            let loc = Option.get tattr_loc in
            raise
              (Error (loc, "Cannot move value " ^ t.tname ^ " from outer scope"))
        | Dset | Dmut | Dnorm -> ());
        { t with tattr; tattr_loc })
      touched
  in
  (check_mutated (), touched, body)

let check_items ~mname get_decl touched items =
  reset get_decl;
  current_module := Some mname;

  (* touched variables *)
  let env, hist =
    List.fold_left
      (fun (map, hs) t ->
        let id = new_id t.tname t.tmname in
        let b = [ Bown (id, Hashtbl.create 32) ] in
        (Map.add id (imm b) map, add_hist (imm b) hs))
      (Map.empty, Map.empty) touched
  in

  let (env, _, _, _, hist), items =
    List.fold_left_map check_item (env, false, Usage.Uread, [], hist) items
  in

  let unmutated = check_mutated () in

  check_array_moves hist;
  (* No moves at top level *)
  Map.iter
    (fun id b ->
      match b.imm with
      | [] -> ()
      | _ -> (
          let tattr, tattr_loc = find_usage id hist in
          match tattr with
          | Dmove ->
              let loc = Option.get tattr_loc in
              raise (Error (loc, "Cannot move top level binding"))
          | Dset | Dmut | Dnorm -> ()))
    env;

  reset get_decl;
  List.iter
    (fun t ->
      let tattr, tattr_loc = find_usage (Fst (t.tname, t.tmname)) hist in
      match tattr with
      | Dmove ->
          let loc = Option.get tattr_loc in
          raise
            (Error (loc, "Cannot move value " ^ t.tname ^ " from outer scope"))
      | Dset | Dmut | Dnorm -> ())
    touched;

  (unmutated, items)
