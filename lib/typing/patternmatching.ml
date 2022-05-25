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
    Ast.expr ->
    (Ast.loc * Ast.pattern * Ast.block) list ->
    Typed_tree.typed_expr
end

module Match = struct
  type t = Exhaustive | Partial of string list * t Smap.t
  type err = Redundant

  exception Err of err

  (* Merge partial matches if they share the ctor  *)
  let rec merge other this =
    match (other, this) with
    | _, Exhaustive ->
        (* We are already exhaustive, everything else
           is redundant *)
        raise (Err Redundant)
    | Exhaustive, _ ->
        (* If it's exhaustive, we are done *)
        Exhaustive
    | Partial (_, other), Partial (this_list, this) ->
        let f _ other this =
          match (other, this) with
          | None, Some a | Some a, None -> Some a
          | None, None -> failwith "lol"
          | Some other, Some this -> Some (merge other this)
        in
        let this = Smap.merge f other this in
        Partial (this_list, this)

  let rec is_exhaustive = function
    | Exhaustive -> Ok ()
    | Partial (cases, map) ->
        (* Add missing cases *)
        let cmap =
          List.fold_left (fun map case -> Smap.add case [] map) Smap.empty cases
          |> ref
        in

        Smap.iter
          (fun key t ->
            match is_exhaustive t with
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

  let rec cases_to_string = function
    | [] -> ""
    | [ case ] -> case
    | case :: tail -> Printf.sprintf "%s(%s)" case (cases_to_string tail)
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

module Make (C : Core) = struct
  open C

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

  let rec convert_match env loc expr cases =
    (* Magical identifier to read pattern expr.
       There must be a better solution, but my brain doesn't seem to work *)
    let expr_name = "__expr" in

    let expr = convert env expr in
    (* Make the expr available in the patternmatch *)
    let env = Env.add_value expr_name expr.typ loc env in

    (* TODO Should we enter a level here? *)
    let ret = newvar () in

    let some_cases =
      List.map (fun (loc, p, expr) -> (loc, Some p, expr)) cases
    in
    let matchexpr, mtch = select_ctor env loc some_cases ret in

    (* Check for exhaustiveness *)
    (match Match.is_exhaustive mtch with
    | Ok () -> ()
    | Error cases ->
        let cases = String.concat ", " (List.map Match.cases_to_string cases) in
        let msg =
          Printf.sprintf "Pattern match is not exhaustive. Missing cases: %s"
            cases
        in
        raise (Error (loc, msg)));

    { matchexpr with expr = Let (expr_name, expr, matchexpr) }

  and ctornames_of_variant = function
    | Tvariant (_, _, ctors) ->
        Array.to_list ctors |> List.map (fun ctor -> ctor.ctorname)
    | _ -> failwith "Internal Error: Not a variant"

  and select_ctor env all_loc cases ret_typ =
    (* We build the decision tree here.
       [match_cases] splits cases into ones that match and ones that don't.
       [select_ctor] then generates the tree for the cases.
       This boils down to a chain of if-then-else exprs. A heuristic for
       choosing the ctor to check first in a case is not needed right now,
       since we have neither tuples nor literals in matches, but it will
       be part of [select_ctor] eventually *)

    (* Magic value, see above *)
    let expr_name = "__expr" in
    let expr = convert_var env all_loc expr_name in

    let check_redundant init lst =
      List.fold_left
        (fun mtch ((loc, _, _) as item) ->
          try Match.merge (fill_matches env item) mtch
          with Match.Err Redundant ->
            raise (Error (loc, "Pattern match case is redundant")))
        init lst
    in

    let ctorexpr ctor =
      match ctor.ctortyp with
      (* TODO is this instantiated? *)
      | Some typ -> { typ; expr = Variant_data expr; is_const = false }
      | None -> expr
    in

    match cases with
    | [ (loc, Some (Ast.Pctor (name, arg)), ret_expr) ] ->
        (* Selecting the last case like this only works if we are sure
           that we have exhausted all cases *)
        let _, ctor, variant = get_variant env loc name None in
        unify (loc, "Variant pattern has unexpected type:") expr.typ variant;

        let names = ctornames_of_variant variant in

        let argexpr = ctorexpr ctor in
        let env = Env.add_value expr_name argexpr.typ loc env in
        let cont, matches =
          select_ctor env loc [ (loc, arg, ret_expr) ] ret_typ
        in
        ( { cont with expr = Let (expr_name, argexpr, cont) },
          Match.Partial (names, Smap.add (snd name) matches Smap.empty) )
    | (loc, Some (Ast.Pctor (name, _)), _) :: _ ->
        let a, b = match_cases (snd name) cases [] [] in

        let l, ctor, variant = get_variant env loc name None in
        unify (loc, "Variant pattern has unexpected type:") expr.typ variant;

        let names = ctornames_of_variant variant in

        let index =
          { typ = Ti32; expr = Variant_index expr; is_const = false }
        in
        let cind =
          { typ = Ti32; expr = Const (I32 l.index); is_const = true }
        in
        let cmpexpr = Bop (Ast.Equal_i, index, cind) in
        let cmp = { typ = Tbool; expr = cmpexpr; is_const = false } in

        let data = ctorexpr ctor in
        let ifenv = Env.add_value expr_name data.typ loc env in

        let cont, ifmatch = select_ctor ifenv loc a ret_typ in

        let ifexpr = Let (expr_name, data, cont) in

        let mtch =
          Match.Partial (names, Smap.add (snd name) ifmatch Smap.empty)
        in
        (* The tail isn't used in the decision tree,
           but is needed for case analysis *)
        (* Discard first item as it's processes in select_ctor *)
        let mtch =
          match a with [] -> mtch | _ :: tl -> check_redundant mtch tl
        in

        (* This is either an if-then-else or just an if with one ctor,
           depending on whether [b] is empty *)
        let expr, matches =
          match b with
          | [] -> (ifexpr, mtch)
          | b ->
              let if_ = { cont with expr = ifexpr } in
              let else_, elsematch = select_ctor env loc b ret_typ in
              let matches = Match.merge elsematch mtch in
              (If (cmp, if_, else_), matches)
        in

        ({ typ = ret_typ; expr; is_const = false }, matches)
    | (loc, Some (Pvar (_, name)), ret_expr) :: tl ->
        (* Bind the variable *)
        let env = Env.add_value name expr.typ ~is_const:false loc env in
        let ret, _ = convert_block env ret_expr in

        (* This is already exhaustive but we do the tail here as well for errors *)
        check_redundant Exhaustive tl |> ignore;

        unify (loc, "Match expression does not match:") ret_typ ret.typ;
        ( {
            typ = ret.typ;
            expr = Let (name, expr, ret);
            is_const = ret.is_const;
          },
          Exhaustive )
    | (_, Some (Ptup _), _) :: _ -> failwith "TODO"
    | (loc, None, ret_expr) :: _ ->
        let ret, _ = convert_block env ret_expr in
        unify (loc, "Match expression does not match:") ret_typ ret.typ;
        (ret, Exhaustive)
    | [] -> failwith "Internal Error: Pattern match failed"

  and match_cases case cases if_ else_ =
    match cases with
    | (loc, Some (Ast.Pctor ((_, name), arg)), expr) :: tl
      when String.equal case name ->
        match_cases case tl ((loc, arg, expr) :: if_) else_
    | ((_, Some (Pctor _), _) as thing) :: tl ->
        match_cases case tl if_ (thing :: else_)
    | ((_, Some (Pvar _), _) as thing) :: tl ->
        match_cases case tl (thing :: if_) (thing :: else_)
    | (_, None, _) :: tl ->
        (* TODO correctly handle this case *)
        print_endline "this strange case";
        match_cases case tl if_ else_
    | (_, Some (Ptup _), _) :: _ -> failwith "TODO"
    | [] -> (List.rev if_, List.rev else_)

  and fill_matches env = function
    | loc, Some (Ast.Pctor (name, arg)), expr ->
        let _, _, variant = get_variant env loc name None in
        let names = ctornames_of_variant variant in

        let map =
          Smap.add (snd name) (fill_matches env (loc, arg, expr)) Smap.empty
        in
        Match.Partial (names, map)
    | _, Some (Ptup _), _ -> failwith "TODO"
    | _, Some (Pvar _), _ -> Exhaustive
    | _, None, _ -> Exhaustive
end
