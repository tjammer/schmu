open Types
open Typed_tree
open Inference

module type Core = sig
  val convert : Env.t -> Ast.expr -> typed_expr
  val convert_var : Env.t -> Ast.loc -> string -> typed_expr
  val convert_block : ?ret:bool -> Env.t -> Ast.block -> typed_expr * Env.t
end

module type S = sig
  val convert_ctor :
    Env.t ->
    Ast.loc ->
    Ast.loc * string ->
    Ast.expr option ->
    Types.typ option ->
    Typed_tree.typed_expr

  val convert_match :
    Env.t ->
    Ast.loc ->
    Ast.expr list ->
    (Ast.loc * Ast.pattern * Ast.block) list ->
    Typed_tree.typed_expr
end

module Match = struct
  module Iset = Set.Make (Int)

  type t =
    | Exhaustive of int
    (* Matchalls get a level so that we can distinguish matches from outside a ctor *)
    | Partial of int * string list * t Smap.t

  type tee = t
  type err = Redundant

  exception Err of err

  module Item = struct
    type t = int * Ast.loc * tee

    let compare (a, _, _) (b, _, _) = Int.compare a b
  end

  module Item_set = Set.Make (Item)

  (* Merge partial matches if they share the ctor  *)
  let rec merge other this =
    match (other, this) with
    | Exhaustive other, Exhaustive this when other < this -> Exhaustive other
    | _, Exhaustive _ ->
        (* We are already exhaustive, everything else
           is redundant *)
        raise (Err Redundant)
    | Exhaustive other, _ ->
        (* If it's exhaustive, we are done *)
        Exhaustive other
    | Partial (lvl, other_list, other), Partial (_, this_list, this) ->
        (* TODO delete this *)
        assert (other_list = this_list);
        let length = ref 0 in
        let f _ other this =
          incr length;
          match (other, this) with
          | None, Some a | Some a, None -> Some a
          | None, None -> failwith "lol"
          | Some other, Some this -> Some (merge other this)
        in
        let this = Smap.merge f other this in
        if !length = List.length this_list then Exhaustive lvl
        else Partial (lvl, this_list, this)

  let rec is_exhaust_impl = function
    | Exhaustive _ -> Ok ()
    | Partial (_, cases, map) ->
        (* Add missing cases *)
        let cmap =
          List.fold_left (fun map case -> Smap.add case [] map) Smap.empty cases
          |> ref
        in

        Smap.iter
          (fun key t ->
            match is_exhaust_impl t with
            | Ok () -> cmap := Smap.remove key !cmap
            | Error lst -> cmap := Smap.add key lst !cmap)
          map;

        (* Only missing cases remain *)
        if not (Smap.is_empty !cmap) then
          let lst =
            Smap.to_seq !cmap |> List.of_seq
            |> List.fold_left
                 (* We add for each missing case the current ctor *)
                   (fun acc (a, lst) ->
                   match lst with
                   | [] -> [ a ] :: acc
                   | lst ->
                       List.fold_left (fun acc lst -> (a :: lst) :: acc) acc lst)
                 []
          in

          Error lst
        else Ok ()

  let insert other_ctors ctor lvl lst =
    let aux = function
      | line, loc, Exhaustive l when l <= lvl -> (line, loc, Exhaustive l)
      | line, loc, mtch ->
          (line, loc, Partial (lvl, other_ctors, Smap.add ctor mtch Smap.empty))
    in
    List.map aux lst

  let rec cases_to_string = function
    | [] -> ""
    | [ case ] -> case
    | case :: tail -> Printf.sprintf "%s(%s)" case (cases_to_string tail)

  let is_exhaustive (matches : (int * Ast.loc * t) list) =
    (* Dedup and sort *)
    let dedup = Item_set.of_list matches |> Item_set.elements in
    (* Merge and check redundant cases *)
    (match dedup with
    | [] -> failwith "Internal Error: Pattern match empty"
    | (_, _, hd) :: tl ->
        List.fold_left
          (fun merged (_, loc, item) ->
            try merge item merged
            with Err Redundant ->
              raise (Error (loc, "Pattern match case is redundant")))
          hd tl)
    |> (* Check exhaustiveness *)
    is_exhaust_impl
end

let get_variant env loc name annot =
  match Env.find_ctor_opt (snd name) env with
  | Some { index; typename } ->
      (* We get the ctor type from the variant *)
      let ctor, variant =
        match Env.query_type ~instantiate typename env with
        | Tvariant (_, _, ctors) as typ -> (ctors.(index), typ)
        | _ -> failwith "Internal Error: Not a variant"
      in

      (match annot with
      | Some t -> unify (loc, "In constructor " ^ snd name ^ ":") t variant
      | None -> ());
      (Env.{ index; typename }, ctor, variant)
  | None ->
      let msg = "Unbound constructor " ^ snd name in
      raise (Error (loc, msg))

(* module Tup = struct *)
(*   let choose_col patterns = *)
(*     (\* We choose the column based on precedence. *)
(*        A [Pvar] needs to be bound, *)
(*        [Pwildcard] is ignored. *)
(*        Otherwise, we choose a ctor. For simplicity, we choose the first *\) *)
(*     let rec aux ctor = function *)
(*       | Ast.Pctor _ as ct :: tl->  ( *)
(*           match ctor with *)
(*           | Some _ ->  aux ctor tl *)
(*           | None -> (\* Use this ctor *\) *)
(*             aux (Some ct) tl *)
(*         ) *)
(*       | Pvar _ -> *)
(* end *)

module Make (C : Core) = struct
  open C

  type pattern_data = {
    loc : Ast.loc;
    ret_expr : Ast.stmt list;
    lvl : int;
    index : int;
  }

  let gen_cmp expr const_index =
    let index = { typ = Ti32; expr = Variant_index expr; is_const = false } in
    let cind =
      { typ = Ti32; expr = Const (I32 const_index); is_const = true }
    in
    let cmpexpr = Bop (Ast.Equal_i, index, cind) in
    { typ = Tbool; expr = cmpexpr; is_const = false }

  let convert_ctor env loc name arg annot =
    let Env.{ index; typename }, ctor, variant =
      get_variant env loc name annot
    in
    match (ctor.ctortyp, arg) with
    | Some typ, Some expr ->
        let texpr = convert env expr in
        unify (loc, "In constructor " ^ snd name ^ ":") typ texpr.typ;
        let expr = Ctor (typename, index, Some texpr) in

        Env.maybe_add_type_instance (string_of_type variant) variant env;
        { typ = variant; expr; is_const = false }
    | None, None ->
        let expr = Ctor (typename, index, None) in
        (* NOTE: Const handling for ctors is disabled, see #23 *)
        { typ = variant; expr; is_const = true }
    | None, Some _ ->
        let msg =
          Printf.sprintf
            "The constructor %s expects 0 arguments, but an argument is \
             provided"
            (snd name)
        in
        raise (Error (fst name, msg))
    | Some _, None ->
        let msg =
          Printf.sprintf
            "The constructor %s expects arguments, but none are provided"
            (snd name)
        in
        raise (Error (fst name, msg))

  (* We want to be able to reference the exprs in the pattern match without
     regenerating it, so we use a migic identifier *)
  let expr_name i = "__expr" ^ string_of_int i
  let arg_opt loc = function None -> Ast.Pwildcard loc | Some p -> p

  let rec convert_match env loc exprs cases =
    let (_, env), exprs =
      List.fold_left_map
        (fun (i, env) expr ->
          let e = convert env expr in
          (* Make the expr available in the patternmatch *)
          let env = Env.add_value (expr_name i) e.typ loc env in
          ((i + 1, env), (i, e)))
        (0, env) exprs
    in

    (* TODO error if we have multiple exprs but no tup pattern *)

    (* TODO Should we enter a level here? *)
    let ret = newvar () in

    let some_cases =
      List.mapi
        (fun i (loc, p, expr) ->
          (p, { loc; ret_expr = expr; lvl = 0; index = i }))
        cases
    in
    (* If it's a tuple, the index is passed recursively. Otherwise use 0 *)
    let tup_index = 0 in
    let matchexpr, matches = compile_matches env loc tup_index some_cases ret in

    (* Check for exhaustiveness *)
    (match Match.is_exhaustive matches with
    | Ok () -> ()
    | Error cases ->
        let cases = String.concat ", " (List.map Match.cases_to_string cases) in
        let msg =
          Printf.sprintf "Pattern match is not exhaustive. Missing cases: %s"
            cases
        in
        raise (Error (loc, msg)));

    let rec build_expr = function
      | [] -> matchexpr
      | (i, expr) :: tl ->
          { matchexpr with expr = Let (expr_name i, expr, build_expr tl) }
    in

    build_expr exprs

  and ctornames_of_variant = function
    | Tvariant (_, _, ctors) ->
        Array.to_list ctors |> List.map (fun ctor -> ctor.ctorname)
    | _ -> failwith "Internal Error: Not a variant"

  and compile_matches env all_loc ti cases ret_typ =
    (* We build the decision tree here.
       [match_cases] splits cases into ones that match and ones that don't.
       [compile_matches] then generates the tree for the cases.
       This boils down to a chain of if-then-else exprs. A heuristic for
       choosing the ctor to check first in a case is not needed right now,
       since we have neither tuples nor literals in matches, but it will
       be part of [compile_matches] eventually *)

    (* Magic value, see above *)
    let expr = convert_var env all_loc (expr_name ti) in

    let ctorexpr ctor =
      match ctor.ctortyp with
      (* TODO is this instantiated? *)
      | Some typ -> { typ; expr = Variant_data expr; is_const = false }
      | None -> expr
    in

    match cases with
    | [ (Ast.Pctor (name, arg), d) ] ->
        (* Selecting the last case like this only works if we are sure
           that we have exhausted all cases *)
        let _, ctor, variant = get_variant env d.loc name None in
        unify (d.loc, "Variant pattern has unexpected type:") expr.typ variant;

        let names = ctornames_of_variant variant in

        let argexpr = ctorexpr ctor in
        let env = Env.add_value (expr_name ti) argexpr.typ d.loc env in

        let arg = arg_opt (fst name) arg in
        let cont, matches =
          compile_matches env d.loc ti
            [ (arg, { d with lvl = d.lvl + 1 }) ]
            ret_typ
        in
        ( { cont with expr = Let (expr_name ti, argexpr, cont) },
          Match.insert names (snd name) d.lvl matches )
    | (Ast.Pctor (name, _), d) :: _ ->
        let a, b = match_cases (snd name) cases [] [] in

        let l, ctor, variant = get_variant env d.loc name None in
        unify (d.loc, "Variant pattern has unexpected type:") expr.typ variant;

        let names = ctornames_of_variant variant in

        let cmp = gen_cmp expr l.index in

        let data = ctorexpr ctor in
        let ifenv = Env.add_value (expr_name ti) data.typ d.loc env in

        let cont, ifmatch = compile_matches ifenv d.loc ti a ret_typ in
        let ifexpr = Let (expr_name ti, data, cont) in

        let matches = Match.insert names (snd name) d.lvl ifmatch in

        (* This is either an if-then-else or just an if with one ctor,
           depending on whether [b] is empty *)
        let expr, matches =
          match b with
          | [] -> (ifexpr, matches)
          | b ->
              let if_ = { cont with expr = ifexpr } in
              let else_, elsematch = compile_matches env d.loc ti b ret_typ in
              let matches = matches @ elsematch in
              (If (cmp, if_, else_), matches)
        in

        ({ typ = ret_typ; expr; is_const = false }, matches)
    | (Pvar (loc, name), d) :: tl ->
        (* Bind the variable *)
        let env = Env.add_value name expr.typ ~is_const:false d.loc env in
        (* Continue with expression *)
        let ret, matches =
          compile_matches env loc ti ((Pwildcard loc, d) :: tl) ret_typ
        in

        ( {
            typ = ret.typ;
            expr = Let (name, expr, ret);
            is_const = ret.is_const;
          },
          matches )
    | (Ptup _, _) :: _ ->
        failwith "TODO tup"
        (* For simplicity, this duplicates some code of the other patterns.
           When the algo works, this can probably be cleaned up ab it *)
    | (Pwildcard _, d) :: tl ->
        let ret, _ = convert_block env d.ret_expr in

        (* This is already exhaustive but we do the tail here as well for errors *)
        let matches =
          List.fold_left
            (fun acc item ->
              ((snd item).index, (snd item).loc, fill_matches env item) :: acc)
            [ (d.index, d.loc, Match.Exhaustive d.lvl) ]
            tl
        in
        unify (d.loc, "Match expression does not match:") ret_typ ret.typ;
        (ret, matches)
    | [] -> failwith "Internal Error: Pattern match failed"

  and match_cases case cases if_ else_ =
    match cases with
    | (Ast.Pctor ((loc, name), arg), d) :: tl when String.equal case name ->
        let arg = arg_opt loc arg in
        match_cases case tl ((arg, { d with lvl = d.lvl + 1 }) :: if_) else_
    | ((Pctor _, _) as thing) :: tl -> match_cases case tl if_ (thing :: else_)
    | [ ((Pvar _, _) as thing) ] ->
        (* If the last item is a catchall we can stuff it into the else branch.
           This gets rid off a duplication and also fixes a redundancy check bug *)
        match_cases case [] if_ (thing :: else_)
    | ((Pvar _, _) as thing) :: tl | ((Pwildcard _, _) as thing) :: tl ->
        match_cases case tl (thing :: if_) (thing :: else_)
    | (Ptup _, _) :: _ -> failwith "TODO"
    | [] -> (List.rev if_, List.rev else_)

  and fill_matches env = function
    | Ast.Pctor (name, arg), d ->
        let _, _, variant = get_variant env d.loc name None in
        let names = ctornames_of_variant variant in
        let arg = arg_opt (fst name) arg in

        let map = Smap.add (snd name) (fill_matches env (arg, d)) Smap.empty in
        Match.Partial (d.lvl, names, map)
    | Ptup _, _ -> failwith "TODO"
    | Pvar _, d | Pwildcard _, d -> Exhaustive d.lvl

  (* and compile_tup_matches env all_loc ret_typ = *)
  (*   (\* Similar as above for the single case. *\) *)
end
