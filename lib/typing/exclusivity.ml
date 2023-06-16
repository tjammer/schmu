open Types
open Typed_tree
(* Implements a borrow checker.
   We have to know the last usage for each binding. Instead of traversing once
   and using post processing, assume each binding is correct and unify
   binding-kind after the fact.*)

module Usage = struct
  type t = Uread | Umut | Umove | Uset [@@deriving show]
  type set = Set | Dont_set [@@deriving show]

  let of_attr = function
    | Ast.Dnorm -> Uread
    | Dmut -> Umut
    | Dmove -> Umove
    | Dset -> Uset
end

module Id = struct
  type t = Fst of string | Shadowed of string * int [@@deriving show]

  let compare a b =
    match (a, b) with
    | Fst a, Fst b -> String.compare a b
    | Shadowed (a, ai), Shadowed (b, bi) ->
        let c = String.compare a b in
        if c == 0 then Int.compare ai bi else c
    | Fst a, Shadowed (b, bi) ->
        let c = String.compare a b in
        if c == 0 then bi else c
    | Shadowed (a, ai), Fst b ->
        let c = String.compare a b in
        if c == 0 then ai else c

  let equal a b =
    match (a, b) with
    | Fst a, Fst b -> String.equal a b
    | Shadowed (a, ai), Shadowed (b, bi) ->
        let c = String.equal a b in
        if c then Int.equal ai bi else c
    | Fst _, Shadowed _ | Shadowed _, Fst _ -> false

  let is_string s =
    match fst s with
    | Fst s | Shadowed (s, _) -> String.starts_with ~prefix:"__string" s

  let s (s, part) =
    let name = match s with Fst s -> s | Shadowed (s, _) -> s in
    match part with
    | [] -> name
    | l -> name ^ "." ^ String.concat "." (List.map snd l)
end

type borrow = { ord : int; loc : Ast.loc; borrowed : Id.t * part_access }
and env_item = { imm : binding list; delayed : binding list }

and binding =
  | Bown of Id.t
  | Borrow of borrow
  | Borrow_mut of borrow * Usage.set
  | Bmove of borrow * Ast.loc option

and part_access = (int * string) list [@@deriving show]

let imm imm = { imm; delayed = [] }

let parts_match a wth =
  let rec parts_match = function
    | (i, _) :: tl, (j, _) :: tr ->
        if Int.equal i j then parts_match (tl, tr)
        else (* Borrows concern different parts *) false
    | [], _ -> true
    | _, [] -> (* Borrows are not mutually exclusive *) false
  in
  assert (Id.equal (fst a) (fst wth));
  parts_match (snd a, snd wth)

let are_borrow bs =
  let is_borrow = function
    | Bown _ | Bmove _ -> false
    | Borrow _ | Borrow_mut _ -> true
  in
  match bs with
  | [] -> false
  | bs -> List.fold_left (fun is b -> is && is_borrow b) true bs

type bopt = binding option [@@deriving show]

module Smap = Map.Make (String)
module Map = Map.Make (Id)

let borrow_state = ref 0
let param_pass = ref false
let shadowmap = ref Smap.empty

let rec is_string b env =
  if Id.is_string b then true
  else
    match Map.find_opt (fst b) env with
    | Some { imm; _ } ->
        List.fold_left
          (fun str -> function
            | Bown _ -> false
            | Borrow b | Borrow_mut (b, _) | Bmove (b, _) ->
                str || is_string b.borrowed env)
          false imm
    | None -> false

let new_id str =
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

let reset () =
  borrow_state := 0;
  param_pass := false;
  shadowmap := Smap.empty

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

let rec check_exclusivity loc borrow hist =
  let p = Printf.sprintf in
  match (borrow, hist) with
  (* TODO only check String.equal once *)
  | _, [] ->
      print_endline (show_binding borrow);
      failwith "Internal Error: Should never be empty"
  | Bown _, _ -> ()
  | (Borrow b | Borrow_mut (b, _) | Bmove (b, _)), Bown name :: _
    when Id.equal (fst b.borrowed) name ->
      ()
  | Borrow l, Borrow r :: tl when parts_match l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then () else check_exclusivity loc borrow tl
  | Borrow_mut (l, _), Borrow_mut (r, _) :: tl
    when parts_match l.borrowed r.borrowed ->
      (* Continue until we find our same ord. Don't check further because that's already been checked *)
      if Int.equal l.ord r.ord then ()
      else if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow"
            (Id.s r.borrowed) (fst l.loc).pos_lnum
        in
        raise (Error (r.loc, msg))
      else check_exclusivity loc borrow tl
  | Borrow l, Borrow_mut (r, _) :: _ when parts_match l.borrowed r.borrowed ->
      if l.ord < r.ord then
        (* Borrow is still active while mutable borrow occured *)
        let msg =
          p "%s was borrowed in line %i, cannot mutate" (Id.s r.borrowed)
            (fst l.loc).pos_lnum
        in
        raise (Error (r.loc, msg))
      else ()
  | Borrow_mut (l, _), Borrow r :: _ when parts_match l.borrowed r.borrowed ->
      if l.ord < r.ord then
        (* Mutable borrow still active while borrow occured *)
        let msg =
          p "%s was mutably borrowed in line %i, cannot borrow"
            (Id.s r.borrowed) (fst l.loc).pos_lnum
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
            p "%s was moved in line %i, cannot use%s" (Id.s m.borrowed)
              (fst m.loc).pos_lnum hint )
        else (m.loc, p "Borrowed parameter %s is moved" (Id.s b.borrowed))
      in
      raise (Error (loc, msg))
  | Bmove (m, _), (Borrow b | Borrow_mut (b, _)) :: _
    when parts_match m.borrowed b.borrowed ->
      (* The moving value was borrowed correctly before *)
      ()
  | _, _ :: tl -> check_exclusivity loc borrow tl

let make_copy_call loc tree =
  let typ = Tfun ([ { pattr = Dnorm; pt = tree.typ } ], tree.typ, Simple) in
  let callee = { typ; attr = no_attr; loc; expr = Var "__copy" } in
  let expr = App { callee; args = [ (tree, Dnorm) ] } in
  { tree with attr = { tree.attr with const = false }; expr }

let string_lit_borrow tree mut =
  let loc = Typed_tree.(tree.loc) in
  let copy tree = make_copy_call loc tree in
  let borrowed = (new_id "__string", []) in
  match mut with
  | Usage.Uread ->
      incr borrow_state;
      (tree, Borrow { ord = !borrow_state; loc; borrowed })
  | Umove ->
      incr borrow_state;
      (copy tree, Bmove ({ ord = !borrow_state; loc; borrowed }, None))
  | Umut | Uset -> failwith "Internal Error: Mutating string"

(* For now, throw everything into one list of bindings.
   In the future, each owning binding could have its own list *)

let add_binding b hist =
  let bind_name = function
    | Bown n -> n
    | Borrow b | Borrow_mut (b, _) | Bmove (b, _) -> fst b.borrowed
  in
  let name = bind_name b in
  match Map.find_opt name hist with
  | Some l -> Map.add name (b :: l) hist
  | None -> Map.add name (b :: []) hist

let add_hist v hs =
  match v.imm with
  | [] -> hs
  | hist -> List.fold_left (fun hs b -> add_binding b hs) hs hist

let rec new_elems nu keep old =
  match (nu, old) with
  | _, [] -> nu
  | a :: _, b :: _ when a == b -> List.rev keep
  | a :: tl, _ -> new_elems tl (a :: keep) old
  | _ -> failwith "Internal Error: Impossible"

let integrate_new_elems nu old integrated =
  Map.fold
    (fun id borrows integrated ->
      match Map.find_opt id old with
      | None -> (
          (* everything is new *)
          match Map.find_opt id integrated with
          | None -> Map.add id borrows integrated
          | Some l -> Map.add id (borrows @ l) integrated)
      | Some bs ->
          let nu = new_elems borrows [] bs in
          let toadd = nu @ Map.find id integrated in
          Map.add id toadd integrated)
    nu integrated

let move_local_borrow bs env =
  let rec aux = function
    | [] -> bs
    | (Borrow b | Borrow_mut (b, _)) :: tl ->
        if Map.mem (fst b.borrowed) env |> not then imm [] else aux tl
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
      (*      |> List.map (fun (id, l) -> Id.show id ^ ": " ^ *)
      (*           String.concat ", " (List.map show_binding l)))); *)
      check_exclusivity loc borrow (Map.find (fst b.borrowed) hist);
      match Map.find_opt (fst b.borrowed) env with
      | Some { imm; delayed = _ } -> check_excl_chains loc env imm hist
      | None -> ())

and check_excl_chains loc env borrow hist =
  List.iter (fun b -> check_excl_chain loc env b hist) borrow

let make_var loc name typ = { typ; expr = Var name; attr = no_attr; loc }

let binding_of_borrow borrow = function
  | Usage.Uread -> Borrow borrow
  | Umut -> Borrow_mut (borrow, Dont_set)
  | Uset -> Borrow_mut (borrow, Set)
  | Umove -> Bmove (borrow, None)

let rec check_tree env bind mut part tree hist =
  match tree.expr with
  | Var borrowed ->
      (* This is no rvalue, we borrow *)
      let borrowed = (get_id borrowed, part) in
      let loc = tree.loc in
      let borrow mut = function
        | Bown b ->
            (* For Binds, it's imported that we take the owned name, and not the one from Var.
               Otherwise, the Bind name might be borrowed *)
            incr borrow_state;
            let borrow = { ord = !borrow_state; loc; borrowed = (b, part) } in
            (* Assmue it's the only borrow. This works because if it isn't, a borrowed binding
               will be used later and thin fail the check. Extra care has to be taken for
               arguments to functions *)
            let b = binding_of_borrow borrow mut in
            check_excl_chain loc env b hist;
            b
        | Borrow_mut (b', s) as b -> (
            match mut with
            | Usage.Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b hist;
                Bmove ({ b' with loc }, None)
            | Umut | Uread ->
                check_excl_chain loc env b hist;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, s)
            | Uset ->
                check_excl_chain loc env b hist;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Set))
        | Borrow b' as b -> (
            match mut with
            | Usage.Umove when is_string b'.borrowed env ->
                raise (Error (b'.loc, "Cannot move string literal. Use `copy`"))
            | (Uset | Umut) when is_string b'.borrowed env ->
                raise
                  (Error (b'.loc, "Cannot mutate string literal. Use `copy`"))
            | Umove ->
                (* Before moving, make sure the value was used correctly *)
                check_excl_chain loc env b hist;
                Bmove ({ b' with loc }, None)
            | Umut ->
                check_excl_chain loc env (Borrow_mut (b', Dont_set)) hist;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Dont_set)
            | Uset ->
                check_excl_chain loc env (Borrow_mut (b', Set)) hist;
                incr borrow_state;
                Borrow_mut ({ loc; ord = !borrow_state; borrowed }, Set)
            | Uread ->
                check_excl_chain loc env b hist;
                incr borrow_state;
                Borrow { loc; ord = !borrow_state; borrowed })
        | Bmove (m, l) as b ->
            (* The binding is about to be moved for the first time, e.g. in a function *)
            check_excl_chain loc env b hist;
            Bmove (m, l)
      in

      let borrow_delayed delayed =
        let find_borrow usage b =
          match Map.find_opt (fst b.borrowed) env with
          | Some b when bind -> b.imm
          | Some { imm; delayed = _ } -> List.map (borrow usage) imm
          | None -> []
        in
        let f acc binding =
          let bs =
            match binding with
            | Bmove (b, _) -> find_borrow Umove b
            | Borrow b -> find_borrow Uread b
            | Borrow_mut (b, Set) -> find_borrow Uset b
            | Borrow_mut (b, Dont_set) -> find_borrow Umut b
            | Bown _ -> failwith "Internal Error: A borrowed thing isn't owned"
          in
          List.rev_append bs acc
        in
        List.fold_left f [] delayed
      in

      let borrow =
        match Map.find_opt (fst borrowed) env with
        | Some b when bind -> b
        | Some { imm; delayed } ->
            let delayed = borrow_delayed delayed in
            forbid_conditional_borrow loc imm mut;
            let imm = List.map (borrow mut) imm @ delayed in
            { imm; delayed = [] }
        | None -> imm []
      in
      (* Don't add to hist here. Other expressions where the value is used
         will take care of this *)
      (tree, borrow, hist)
  | Let { id; rhs; cont; mutly; rmut; uniq } ->
      let rhs, env, b, hs =
        check_let tree.loc env id rhs rmut mutly ~tl:false hist
      in
      let cont, v, hs = check_tree env bind mut part cont (add_hist b hs) in
      let expr = Let { id; rhs; cont; mutly; rmut; uniq } in
      ({ tree with expr }, v, hs)
  | Const (Array es) ->
      let hs, es =
        List.fold_left_map
          (fun hs e ->
            let expr, v, hs = check_tree env false Umove [] e hs in
            let expr = { expr with expr = Move expr } in
            (add_hist v hs, expr))
          hist es
      in
      let expr = Const (Array es) in
      ({ tree with expr }, imm [], hs)
  | Const (String _) ->
      let tree, b = string_lit_borrow tree mut in
      (tree, imm [ b ], hist)
  | Const _ -> (tree, imm [], hist)
  | Record fs ->
      let hs, fs =
        List.fold_left_map
          (fun hs (n, (field : typed_expr)) ->
            let usage =
              if contains_allocation field.typ then Usage.Umove else Uread
            in
            let field, v, hs = check_tree env false usage [] field hs in
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
      let t, b, hs = check_tree env bind mut ((i, name) :: part) t hist in
      let tree = { tree with expr = Field (t, i, name) } in
      if contains_allocation tree.typ then (tree, b, hs) else (tree, imm [], hs)
  | Set (thing, value) ->
      let value, v, hs = check_tree env false Umove [] value hist in
      let hs = add_hist v hs in
      (* Track usage of values, but not the one being mutated *)
      let thing, t, hs = check_tree env bind Uset [] thing hs in
      let expr = Set (thing, value) in
      ({ tree with expr }, t, add_hist t hs)
  | Sequence (fst, snd) ->
      let fst, _, hs = check_tree env false Uread [] fst hist in
      let snd, v, hs = check_tree env bind mut part snd hs in
      let expr = Sequence (fst, snd) in
      ({ tree with expr }, v, hs)
  | App
      { callee = { expr = Var "array-get"; _ } as callee; args = [ arr; idx ] }
    ->
      (* Special case for array-get *)
      let callee, b, hs = check_tree env false Uread [] callee hist in
      let hs = add_hist b hs in
      (* We don't check for exclusivity, because there are only two arguments
           and the second is an int *)
      let part, idx, hs =
        match (fst idx).expr with
        | Const (Int i) ->
            let part = (i, Printf.sprintf "[%i]" i) :: part in
            (part, idx, hs)
        | _ ->
            let usage = Usage.of_attr (snd idx) in
            let arg, v, hs = check_tree env false usage [] (fst idx) hs in
            (part, (arg, snd idx), add_hist v hs)
      in
      let ar, b, hs = check_tree env bind mut part (fst arr) hs in
      let tree =
        { tree with expr = App { callee; args = [ (ar, snd arr); idx ] } }
      in
      if contains_allocation tree.typ then (tree, b, hs) else (tree, imm [], hs)
  | App { callee; args } ->
      (* The callee itself can be borrowed *)
      let callee, b, hs = check_tree env false Uread [] callee hist in
      let tmp = Map.add (Fst "_env") b env in
      let (_, tmp, hs), args =
        List.fold_left_map
          (fun (i, tmp, hs) (arg, attr) ->
            let usage = Usage.of_attr attr in
            let arg, v, hs = check_tree env false usage [] arg hs in
            let arg =
              match usage with
              | Umove -> { arg with expr = Move arg }
              | Uread | Umut | Uset -> arg
            in
            let tmp = Map.add (Fst ("_" ^ string_of_int i)) v tmp in
            ((i + 1, tmp, add_hist v hs), (arg, attr)))
          (0, tmp, add_hist b hs)
          args
      in
      (* Check again to ensure exclusivity of arguments and closure *)
      let c = { callee with expr = Var "_env" } in
      check_tree tmp false Uread [] c hs |> ignore;
      List.iteri
        (fun i (arg, attr) ->
          match Usage.of_attr attr with
          | Umove ->
              (* Moved values can't have been used later *)
              ()
          | u ->
              let arg = { arg with expr = Var ("_" ^ string_of_int i) } in
              check_tree tmp false u [] arg hs |> ignore)
        args;
      let expr = App { callee; args } in
      (* A function cannot return a borrowed value *)
      ({ tree with expr }, imm [], hs)
  | Bop (op, fst, snd) ->
      let fst, v, hs = check_tree env false Uread [] fst hist in
      let snd, v, hs = check_tree env false Uread [] snd (add_hist v hs) in
      let expr = Bop (op, fst, snd) in
      ({ tree with expr }, imm [], add_hist v hs)
  | Unop (op, e) ->
      let e, v, hs = check_tree env false Uread [] e hist in
      let expr = Unop (op, e) in
      ({ tree with expr }, imm [], add_hist v hs)
  | If (cond, _, ae, be) ->
      let cond, v, hs = check_tree env false Uread [] cond hist in
      let hs = add_hist v hs in
      let shadows = !shadowmap in
      let ae, a, abs = check_tree env bind mut part ae hs in
      let a = move_local_borrow a env in

      shadowmap := shadows;
      let be, b, bbs = check_tree env bind mut part be hs in
      shadowmap := shadows;
      let b = move_local_borrow b env in
      (* Make sure borrow kind of both branches matches *)
      let _raise msg = raise (Error (tree.loc, msg)) in
      let imm =
        match (a.imm, b.imm) with
        (* Ignore Bown _ cases, as it can't be returned. Would be borrowed *)
        (* Owning *)
        | [], [] -> []
        | [], b when are_borrow b ->
            if contains_allocation be.typ then
              _raise "Branches have different ownership: owned vs borrowed"
            else []
        | b, [] when are_borrow b ->
            if contains_allocation ae.typ then
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
      ({ tree with expr }, { imm; delayed }, integrate_new_elems abs hs bbs)
  | Ctor (name, i, e) -> (
      match e with
      | Some e ->
          let usage =
            if contains_allocation e.typ then Usage.Umove else Uread
          in
          let e, v, hs = check_tree env false usage [] e hist in
          let e = { e with expr = Move e } in
          let expr = Ctor (name, i, Some e) in
          ({ tree with expr }, imm [], add_hist v hs)
      | None -> (tree, imm [], hist))
  | Variant_index e ->
      let e, v, hs = check_tree env bind mut part e hist in
      let expr = Variant_index e in
      ({ tree with expr }, v, hs)
  | Variant_data e ->
      let e, v, hs = check_tree env bind mut part e hist in
      let expr = Variant_data e in
      ({ tree with expr }, v, hs)
  | Fmt fs ->
      let hs, fs =
        List.fold_left_map
          (fun hs -> function
            | Fstr _ as str -> (hs, str)
            | Fexpr e ->
                let e, v, hs = check_tree env false Uread [] e hs in
                (add_hist v hs, Fexpr e))
          hist fs
      in
      let expr = Fmt fs in
      ({ tree with expr }, imm [], hs)
  | Mutual_rec_decls (decls, cont) ->
      let cont, v, hs = check_tree env bind mut part cont hist in
      let expr = Mutual_rec_decls (decls, cont) in
      ({ tree with expr }, v, hs)
  | Lambda (_, abs) ->
      let imm = check_abstraction env tree.loc abs.func.touched hist in
      (tree, { imm; delayed = [] }, hist)
  | Function (name, u, abs, cont) ->
      let bindings = check_abstraction env tree.loc abs.func.touched hist in
      let env =
        match List.rev bindings with
        | [] -> env
        | bs -> Map.add (Fst name) { imm = []; delayed = bs } env
      in
      let cont, v, hs = check_tree env bind mut part cont hist in
      let expr = Function (name, u, abs, cont) in
      ({ tree with expr }, v, hs)
  | Bind (name, expr, cont) ->
      let e, env, hist = check_bind env name expr hist in
      let cont, v, hs = check_tree env bind mut part cont hist in
      let expr = Bind (name, e, cont) in
      ({ tree with expr }, v, hs)
  | Move _ -> failwith "Internal Error: Nothing should have been moved here"

and check_let ~tl loc env id lhs rmut mutly hist =
  let nmut, tlborrow =
    match (lhs.attr.mut, mutly) with
    | true, true when not rmut ->
        raise (Error (lhs.loc, "Cannot project immutable binding"))
    | true, true -> (Usage.Umut, false)
    | true, false -> (Umove, false)
    | false, false ->
        (* Cannot borrow mutable bindings at top level. We defer error generation until
           we are sure the rhs is really borrowed *)
        (Uread, rmut && tl)
    | false, true -> failwith "unreachable"
  in
  let rhs, rval, hs = check_tree env false nmut [] lhs hist in
  let loc = loc in
  let neword () =
    incr borrow_state;
    !borrow_state
  in
  let id = new_id id in
  let borrow hs = function
    | Bmove _ as b -> (Bown id, add_hist (imm [ b ]) hs)
    | (Borrow _ | Borrow_mut _) when tlborrow ->
        raise (Error (lhs.loc, "Cannot borrow mutable binding at top level"))
    | Borrow b -> (Borrow { b with loc; ord = neword () }, hs)
    | Borrow_mut (b, s) -> (Borrow_mut ({ b with loc; ord = neword () }, s), hs)
    | Bown _ -> failwith "Internal Error: A borrowed thing isn't owned"
  in
  let imm, hs =
    match rval.imm with
    | [] ->
        (* No borrow, original, owned value *)
        ([ Bown id ], hs)
    | b ->
        (* Switch order so that first move appears near the head of borrow list.
             This way, the first move is reported first (if both move the same thing) *)
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
  let env = Map.add id b env in
  (rhs, env, b, hs)

and check_bind env name expr hist =
  let e, b, hist = check_tree env true Uread [] expr hist in
  let id = new_id name in
  let env = match b.imm with [] -> env | bs -> Map.add id (imm bs) env in
  (e, env, hist)

and check_abstraction env loc touched hist =
  List.fold_left
    (fun bindings (use : touched) ->
      (* For moved values, don't check touched here. Instead, add them as
         bindings later so they get moved on first use *)
      let usage = Usage.of_attr use.tattr in
      let var = make_var loc use.tname use.ttyp in
      let _, b, _ = check_tree env false usage [] var hist in
      b.imm @ bindings)
    [] touched

let check_item (env, bind, mut, part, hist) = function
  | Tl_let ({ loc; id; rmut; mutly; lhs; uniq = _ } as e) ->
      if mutly then raise (Error (lhs.loc, "Cannot project at top level"))
      else
        let lhs, env, b, hs =
          check_let loc env id lhs rmut mutly ~tl:true hist
        in
        ((env, bind, mut, part, add_hist b hs), Tl_let { e with lhs })
  | Tl_bind (name, expr) ->
      let e, env, hist = check_bind env name expr hist in
      ((env, bind, mut, part, hist), Tl_bind (name, e))
  | Tl_expr e ->
      (* Basically a sequence *)
      let e, b, hs = check_tree env false Uread [] e hist in
      ((env, bind, mut, part, add_hist b hs), Tl_expr e)
  | Tl_function (loc, name, _, abs) as f ->
      let bindings = check_abstraction env loc abs.func.touched hist in
      let env =
        match List.rev bindings with
        | [] -> env
        | bs -> Map.add (Fst name) { imm = []; delayed = bs } env
      in
      ((env, bind, mut, part, hist), f)
  | (Tl_mutual_rec_decls _ | Tl_module _) as item ->
      ((env, bind, mut, part, hist), item)

let find_usage id hist =
  (* The hierarchy is move > mut > read. Since we read from the end,
     the first borrow means the binding was not moved *)
  let rec aux = function
    | [ Bown _ ] -> (Ast.Dnorm, None)
    | [ Borrow _ ] -> (* String literals are owned by noone *) (Ast.Dnorm, None)
    | Borrow_mut (b, Dont_set) :: _ -> (Dmut, Some b.loc)
    | Borrow_mut (b, Set) :: _ -> (Dset, Some b.loc)
    | Bmove (b, _) :: _ -> (Dmove, Some b.loc)
    | Borrow _ :: tl -> aux tl
    | Bown _ :: _ -> failwith "Internal Error: Owned later?"
    | [] -> failwith "Internal Error: Should have been added as owned"
  in
  match Map.find_opt id hist with
  | Some hist -> aux hist
  | None ->
      (* The binding was not used *)
      (Ast.Dnorm, None)

let check_tree pts pns touched body =
  (* Add parameters to initial environment *)
  reset ();
  let borrow_of_param borrowed loc =
    incr borrow_state;
    { ord = !borrow_state; loc; borrowed }
  in

  (* Shadowing between touched variables and parameters is impossible. If a parameter
     exists with the same name, the variable would not have been closed over / touched *)
  (* touched variables *)
  let env, hist =
    List.fold_left
      (fun (map, hs) t ->
        let id = new_id t.tname in
        assert (Id.equal id (Fst t.tname));
        let b = [ Bown id ] in
        (Map.add id (imm b) map, add_hist (imm b) hs))
      (Map.empty, Map.empty) touched
  in

  (* parameters *)
  let env, hist =
    List.fold_left
      (fun (map, hs) (n, _) ->
        (* Parameters are not owned, but using them as owned here makes it easier for
           borrow checking. Correct usage of mutable parameters is already handled in typing.ml *)
        let id = new_id n in
        assert (Id.equal id (Fst n));
        let b = [ Bown id ] in
        (Map.add id (imm b) map, add_hist (imm b) hs))
      (env, hist) pns
  in

  (* [Umove] because we want to move return values *)
  let usage = if contains_allocation body.typ then Usage.Umove else Uread in
  let body, v, hist = check_tree env false usage [] body hist in
  let body = { body with expr = Move body } in

  (* Try to borrow the params again to make sure they haven't been moved *)
  let hist = add_hist v hist in
  param_pass := true;
  List.iter2
    (fun p (n, loc) ->
      (* If there's no allocation, we copying and moving are the same thing *)
      if contains_allocation p.pt then
        let borrow = borrow_of_param (Fst n, []) loc in
        match p.pattr with
        | Dnorm -> check_excl_chain loc env (Borrow borrow) hist
        | Dmut -> check_excl_chain loc env (Borrow_mut (borrow, Dont_set)) hist
        | Dset -> check_excl_chain loc env (Borrow_mut (borrow, Set)) hist
        | Dmove -> ())
    pts pns;

  let touched =
    List.map
      (fun t ->
        let tattr, tattr_loc = find_usage (Fst t.tname) hist in
        (match tattr with
        | Dmove ->
            let loc = Option.get tattr_loc in
            raise (Error (loc, "Cannot move values from outer scope"))
        | Dset | Dmut | Dnorm -> ());
        { t with tattr; tattr_loc })
      touched
  in
  (touched, body)

let check_items items =
  reset ();
  let (env, _, _, _, hist), items =
    List.fold_left_map check_item
      (Map.empty, false, Usage.Uread, [], Map.empty)
      items
  in

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

  items
