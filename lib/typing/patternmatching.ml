open Types
open Typed_tree
open Inference
module Map = Map.Make (Int)

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

type pattern_data = {
  loc : Ast.loc;
  ret_expr : Ast.stmt list;
  lvl : int Map.t;
  index : int;
}

module Tup = struct
  type ret_pattern =
    | Tvar of int * Ast.loc * string
    | Tctor of int * Ast.loc * string
    | Tnothing

  type payload = {
    index : int;
    loc : Ast.loc;
    name : string;
    d : pattern_data;
    patterns : (int * Ast.pattern) list;
  }

  type ret = Var of payload | Ctor of payload | Bare of pattern_data

  let choose_next (patterns, d) =
    (* We choose teh column based on precedence.
       A [Pvar] needs to be bound,
       [Pwildcard] is filtered.
       Otherwise, we choose a ctor. For simplicity, we choose the first *)
    let rec aux pattern ret_patterns = function
      | ((i, Ast.Pctor ((loc, name), _)) as thing) :: tl ->
          let pattern =
            match pattern with
            | Tvar _ | Tctor _ -> pattern
            | Tnothing ->
                (* Use this pattern *)
                Tctor (i, loc, name)
          in
          aux pattern (thing :: ret_patterns) tl
      | (i, Pvar (loc, name)) :: tl ->
          let pattern =
            match pattern with
            | Tvar _ -> pattern
            | Tnothing | Tctor _ -> Tvar (i, loc, name)
          in
          (* Var dos not have children *)
          aux pattern ret_patterns tl
      | (_, Pwildcard _) :: tl ->
          (* We drop wildcard patterns *)
          aux pattern ret_patterns tl
      | (_, Ptup _) :: _ -> failwith "Internal Error: Unexpected tup pattern"
      | [] -> (pattern, List.rev ret_patterns)
    in
    let ret, patterns = aux Tnothing [] patterns in
    match ret with
    | Tnothing ->
        assert (List.length patterns = 0);
        Bare d
    | Tvar (index, loc, name) -> Var { index; loc; name; d; patterns }
    | Tctor (index, loc, name) -> Ctor { index; loc; name; d; patterns }
end

module Make (C : Core) = struct
  open C

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
    let ret = newvar () in

    let some_cases =
      List.mapi
        (fun i (loc, p, expr) ->
          let pat, lvl =
            match p with
            | Ast.Ptup (_, pats) ->
                (* TODO see above check arity *)
                (* We track the depth (lvl) for each column separately *)
                let (_, lvl), pat =
                  List.fold_left_map
                    (fun (i, lvl) p -> ((i + 1, Map.add i 0 lvl), (i, p)))
                    (0, Map.empty) pats
                in
                (pat, lvl)
            | p -> ([ (0, p) ], Map.add 0 0 Map.empty)
          in
          (pat, { loc; ret_expr = expr; lvl; index = i }))
        cases
    in

    let matchexpr, matches = compile_matches env loc some_cases ret in

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

  (* TODO remove  *)
  and fake_depth m = Map.min_binding m |> snd

  and compile_matches env all_loc cases ret_typ =
    (* We build the decision tree here.
       [match_cases] splits cases into ones that match and ones that don't.
       [compile_matches] then generates the tree for the cases.
       This boils down to a chain of if-then-else exprs. A heuristic for
       choosing the ctor to check first in a case is not needed right now,
       since we have neither tuples nor literals in matches, but it will
       be part of [compile_matches] eventually *)

    (* Magic value, see above *)
    let expr i = convert_var env all_loc (expr_name i) in

    let ctorenv env ctor i loc =
      match ctor.ctortyp with
      (* TODO is this instantiated? *)
      | Some typ ->
          let data = { typ; expr = Variant_data (expr i); is_const = false } in
          (data, Env.add_value (expr_name i) data.typ loc env)
      | None -> (expr i, env)
    in

    match cases with
    | hd :: tl -> (
        match Tup.choose_next hd with
        | Bare d ->
            let ret, _ = convert_block env d.ret_expr in

            (* TODO move the [expr i] function to other branch only *)
            (* (\* Use expr. Otherwise we get unused binding error *\) *)
            (* ignore (expr i); *)

            (* This is already exhaustive but we do the tail here as well for errors *)
            let matches =
              List.fold_left
                (fun acc item ->
                  ((snd item).index, (snd item).loc, fill_matches env item)
                  :: acc)
                [ (d.index, d.loc, Match.Exhaustive (fake_depth d.lvl)) ]
                tl
            in
            unify (d.loc, "Match expression does not match:") ret_typ ret.typ;
            (ret, matches)
        | Var { index; loc; name; d; patterns } ->
            (* Bind the variable *)
            let env =
              Env.add_value name (expr index).typ ~is_const:false d.loc env
            in
            (* Continue with expression *)
            let ret, matches =
              compile_matches env loc ((patterns, d) :: tl) ret_typ
            in

            ( {
                typ = ret.typ;
                expr = Let (name, expr index, ret);
                is_const = ret.is_const;
              },
              matches )
        | Ctor { index; loc; name; d; patterns } ->
            let a, b = match_cases name ((patterns, d) :: tl) [] [] in

            let l, ctor, variant = get_variant env d.loc (loc, name) None in
            unify
              (d.loc, "Variant pattern has unexpected type:")
              (expr index).typ variant;

            let names = ctornames_of_variant variant in

            let data, ifenv = ctorenv env ctor index d.loc in
            let cont, ifmatch = compile_matches ifenv d.loc a ret_typ in
            (* Make expr available in codegen *)
            let ifexpr = Let (expr_name index, data, cont) in

            let matches = Match.insert names name (fake_depth d.lvl) ifmatch in

            (* This is either an if-then-else or just an one ctor,
               depending on whether [b] is empty *)
            let expr, matches =
              match b with
              | [] -> (ifexpr, matches)
              | b ->
                  let cmp = gen_cmp (expr index) l.index in
                  let if_ = { cont with expr = ifexpr } in
                  let else_, elsematch = compile_matches env d.loc b ret_typ in
                  let matches = matches @ elsematch in
                  (If (cmp, if_, else_), matches)
            in

            ({ typ = ret_typ; expr; is_const = false }, matches))
    | [] -> failwith "Internal Error: Empty match"

  (* and match_cases (i, case) cases if_ else_ = *)
  (* (\* TODO function *\) *)
  (* match cases with *)
  (*   | (clauses, d) :: tl -> *)
  (*     ( *)
  (*       match List.assoc_opt i clauses with *)
  (*       | Some (Ast.Pctor ((loc, name), arg)) when *)
  (*           String.equal case name -> *)
  (*         (\* TODO the levels can't be in [d] because different clauses can now have *)
  (*            different levels. Instead, we have to put the levels next to the clause*\) *)
  (*         let arg = arg_opt loc arg in *)
  (*         (\* TODO assoc set *\) *)
  (*         let clauses = List. *)
  (*     match_cases (i, case) tl *)
  (*       (([ (i, arg) ], { d with lvl = [ (0, fake_depth d.lvl + 1) ] }) :: if_) *)
  (*       else_ *)

  (*       | (_, Ast.Pctor ((loc, name), arg)) *)
  (*     ) *)
  and match_cases case cases if_ else_ =
    match cases with
    | ([ (i, Ast.Pctor ((loc, name), arg)) ], d) :: tl
      when String.equal case name ->
        let arg = arg_opt loc arg in
        let lvl = Map.find 0 d.lvl in
        match_cases case tl
          (([ (i, arg) ], { d with lvl = Map.add i (lvl + 1) d.lvl }) :: if_)
          else_
    | (([ (_, Pctor _) ], _) as thing) :: tl ->
        match_cases case tl if_ (thing :: else_)
    | [ (([ (_, Pvar _) ], _) as thing) ] ->
        (* If the last item is a catchall we can stuff it into the else branch.
           This gets rid off a duplication and also fixes a redundancy check bug *)
        match_cases case [] if_ (thing :: else_)
    | (([ (_, Pvar _) ], _) as thing) :: tl
    | (([ (_, Pwildcard _) ], _) as thing) :: tl ->
        match_cases case tl (thing :: if_) (thing :: else_)
    | [] ->
        (List.rev if_, List.rev else_)
        (* | (Ptup _, _) :: _ -> failwith "TODO" *)
    | _ -> failwith "Internal Error: Something is wrong 1"

  and fill_matches env = function
    (* This is not yet implemented for tuples *)
    | [ (i, Ast.Pctor (name, arg)) ], d ->
        let _, _, variant = get_variant env d.loc name None in
        let names = ctornames_of_variant variant in
        let arg = arg_opt (fst name) arg in

        let map =
          Smap.add (snd name) (fill_matches env ([ (i, arg) ], d)) Smap.empty
        in
        Match.Partial (fake_depth d.lvl, names, map)
    | [ (_, Pvar _) ], d | [ (_, Pwildcard _) ], d ->
        Exhaustive (fake_depth d.lvl)
        (* | [ (_, Ptup _) ], _ -> failwith "TODO" *)
    | _ -> failwith "Internal Error: Something is wrong here"

  (* and compile_tup_matches env all_loc ret_typ = *)
  (*   (\* Similar as above for the single case. *\) *)
end
