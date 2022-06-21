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

type pattern_data = { loc : Ast.loc; ret_expr : Ast.stmt list; row : int }

module Tup = struct
  type payload = {
    index : int;
    loc : Ast.loc;
    name : string;
    d : pattern_data;
    patterns : (int * Ast.pattern) list;
  }

  type ret = Var of payload | Ctor of payload | Bare of pattern_data

  let choose_next (patterns, d) =
    (* We choose a column based on precedence.
       [Pwildcard] is dropped
       1: [Pvar] needs to be bound,
       2: Otherwise, we choose a ctor. For simplicity, we choose the first *)
    let score_patterns pattern =
      match snd pattern with
      | Ast.Pctor _ -> 2
      | Pvar _ -> 1
      | Pwildcard _ -> failwith "Internal Error: Should have been dropped"
      | Ptup _ -> failwith "Internal Error: Unexpected tup pattern"
    in
    let sort_patterns a b = Int.compare (score_patterns a) (score_patterns b) in
    let filter_patterns p =
      match snd p with Ast.Pwildcard _ -> false | _ -> true
    in
    let sorted =
      List.filter filter_patterns patterns |> List.sort sort_patterns
    in

    match sorted with
    | (index, Ast.Pctor ((loc, name), _)) :: _ ->
        Ctor { index; loc; name; d; patterns = sorted }
    | (index, Pvar (loc, name)) :: patterns ->
        (* Drop var from patterns list *)
        Var { index; loc; name; d; patterns }
    | (_, Pwildcard _ | _, Ptup _) :: _ ->
        failwith "Internal Error: Unexpected tup pattern"
    | [] -> Bare d
end

module Exhaustiveness = struct
  module Set = Set.Make (String)

  type wip_kind = New_column | Specialization
  type exhaustive = Exh | Wip of wip_kind * Ast.pattern list list
  type ctorset = Ctors of ctor list | Inf

  let ctorset_of_variant = function
    | Tvariant (_, _, ctors) -> Ctors (Array.to_list ctors)
    | _ -> Inf

  (* [pattern] has a complete signature on first column *)
  type signature = Complete of ctor list | Missing of string list | Infi

  let sig_complete typ patterns =
    match ctorset_of_variant (clean typ) with
    | Ctors ctors ->
        let set =
          ctors |> List.map (fun ctor -> ctor.ctorname) |> Set.of_list
        in
        let sigs =
          List.fold_left
            (fun set patterns ->
              match patterns with
              | Ast.Pctor ((_, name), _) :: _ -> Set.remove name set
              | _ -> set)
            set patterns
        in
        if Set.is_empty sigs then Complete ctors
        else Missing (Set.elements sigs)
    | Inf -> Infi

  (* Always on first column *)
  let default patterns =
    let rows_empty = ref true in
    let new_col = ref false in
    let patterns =
      List.filter_map
        (function
          | Ast.Pctor (_, _) :: _ ->
              (* Drop row *)
              rows_empty := false;
              None
          | (Pwildcard _ | Pvar _) :: tl ->
              (* Discard head element *)
              new_col := true;
              rows_empty := false;
              Some tl
          | Ptup _ :: _ -> failwith "No tuple here"
          | [] -> (* Empty row *) Some [])
        patterns
    in

    let new_col = if !new_col then New_column else Specialization in
    if !rows_empty then Exh else Wip (new_col, patterns)

  let args_to_list = function
    | Some (Ast.Ptup (_, pats)) -> pats
    | Some p -> [ p ]
    | None -> []

  let arg_to_num = function Some _ -> 1 | None -> 0

  let rec to_n_list x n lst =
    if n = 0 then lst else to_n_list x (n - 1) (x :: lst)

  (* Specialize first column for [case] *)
  let specialize case num_args patterns =
    let rows_empty = ref true in
    let new_col = ref false in
    let patterns =
      List.filter_map
        (function
          | Ast.Pctor (name, args) :: tl when String.equal (snd name) case ->
              rows_empty := false;
              let lst =
                match args_to_list args with
                | [] ->
                    new_col := true;
                    tl
                | lst -> lst @ tl
              in
              Some lst
          | Pctor (_, _) :: _ ->
              (* Drop row *)
              rows_empty := false;
              None
          | (Pwildcard loc | Pvar (loc, _)) :: tl ->
              rows_empty := false;
              let lst =
                match num_args with
                | 0 ->
                    new_col := true;
                    tl
                | _ -> to_n_list (Ast.Pwildcard loc) num_args [] @ tl
              in
              Some lst
          | Ptup _ :: _ -> failwith "No tuple here"
          | [] -> (* Empty row *) Some [])
        patterns
    in

    let new_col = if !new_col then New_column else Specialization in
    if !rows_empty then Exh else Wip (new_col, patterns)

  let check_empty patterns =
    let rows_empty = ref true in
    List.iter
      (function
        | (Ast.Pctor _ | Pwildcard _ | Pvar _) :: _ -> rows_empty := false
        | Ptup _ :: _ -> failwith "No tuple here"
        | [] -> ())
      patterns;
    if !rows_empty then Ok ()
    else failwith "Internal Error: No matching type expression"

  let keep_new_col kind (other, str) =
    match (kind, other) with
    | New_column, _ | _, New_column -> (New_column, str)
    | Specialization, Specialization -> (Specialization, str)

  let rec is_exhaustive types patterns : (unit, wip_kind * string list) result =
    match (types, patterns) with
    | _, [] -> Error (Specialization, [])
    | [], patterns -> check_empty patterns
    | typ :: typstl, patterns -> (
        match sig_complete typ patterns with
        | Complete ctors ->
            let exhs =
              List.map
                (fun { ctorname; ctortyp } ->
                  let num = arg_to_num ctortyp in
                  ( ctorname,
                    match specialize ctorname num patterns with
                    | Exh -> Ok ()
                    | Wip (kind, patterns) ->
                        (* In case specializion adds a ctor, we elimate these first *)
                        (* Right now, the argument arity is 1 at most *)
                        let ret =
                          if num = 1 then
                            let typ = Option.get ctortyp in
                            is_exhaustive (typ :: typstl) patterns
                          else is_exhaustive typstl patterns
                        in
                        ret |> Result.map_error (keep_new_col kind) ))
                ctors
            in

            if List.for_all (fun i -> snd i |> Result.is_ok) exhs then Ok ()
            else
              let ctor, err =
                List.find (fun i -> snd i |> Result.is_error) exhs
              in
              let kind, strs = Result.get_error err in
              let strs =
                match kind with
                | New_column ->
                    List.map (fun str -> Printf.sprintf "%s, %s" ctor str) strs
                | Specialization ->
                    List.map (fun str -> Printf.sprintf "%s(%s)" ctor str) strs
              in

              Error (kind, strs)
        | Missing ctors -> (
            match default patterns with
            | Exh -> Ok ()
            | Wip (kind, patterns) -> (
                (* The default matrix only removes ctors and does not add
                   temporary ones. So we can continue with exprstl *)
                match is_exhaustive typstl patterns with
                | Ok () -> Ok ()
                | Error _ -> Error (kind, ctors)))
        | Infi -> (
            match default patterns with
            | Exh -> Ok ()
            | Wip (kind, patterns) ->
                is_exhaustive typstl patterns
                |> Result.map_error (keep_new_col kind)))
end

module Make (C : Core) = struct
  open C

  module Row = struct
    type t = { loc : Ast.loc; cnt : int }

    let compare a b = Int.compare a.cnt b.cnt
  end

  module Row_set = Set.Make (Row)

  (* List.Assoc.set taken from containers *)
  let rec search_set acc l x ~f =
    match l with
    | [] -> f x None acc
    | (x', y') :: l' ->
        if x = x' then f x (Some y') (List.rev_append acc l')
        else search_set ((x', y') :: acc) l' x ~f

  let assoc_set x y l = search_set [] l x ~f:(fun x _ l -> (x, y) :: l)

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
        { typ = variant; expr; is_const = false }
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
     regenerating it, so we use a magic identifier *)
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

    let used_rows = ref Row_set.empty in
    let some_cases =
      List.mapi
        (fun i (loc, p, expr) ->
          used_rows := Row_set.add Row.{ loc; cnt = i } !used_rows;
          let pat =
            match p with
            | Ast.Ptup (_, pats) ->
                (* TODO see above check arity *)
                (* We track the depth (lvl) for each column separately *)
                let _, pat =
                  List.fold_left_map (fun i p -> (i + 1, (i, p))) 0 pats
                in
                pat
            | p -> [ (0, p) ]
          in
          (pat, { loc; ret_expr = expr; row = i }))
        cases
    in

    let matchexpr = compile_matches env loc used_rows some_cases ret in

    (* Check for exhaustiveness *)
    (let types = List.map (fun e -> (snd e).typ |> clean) exprs
     and patterns = List.map (fun (p, _) -> List.map snd p) some_cases in
     match Exhaustiveness.is_exhaustive types patterns with
     | Ok () -> ()
     | Error (_, cases) ->
         let msg =
           Printf.sprintf "Pattern match is not exhaustive. Missing cases: %s"
             (String.concat " | " cases)
         in
         raise (Error (loc, msg)));

    (* Find redundant cases *)
    (match Row_set.min_elt_opt !used_rows with
    | None -> ()
    | Some { loc; cnt = _ } ->
        raise (Error (loc, "Pattern match case is redundant")));

    let rec build_expr = function
      | [] -> matchexpr
      | (i, expr) :: tl ->
          { matchexpr with expr = Let (expr_name i, expr, build_expr tl) }
    in

    build_expr exprs

  and compile_matches env all_loc rows cases ret_typ =
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
      | Some typ ->
          let data = { typ; expr = Variant_data (expr i); is_const = false } in
          (data, Env.add_value (expr_name i) data.typ loc env)
      | None -> (expr i, env)
    in

    match cases with
    | hd :: tl -> (
        match Tup.choose_next hd with
        | Bare d ->
            (* Mark row as used *)
            rows := Row_set.remove { cnt = d.row; loc = d.loc } !rows;

            let ret, _ = convert_block env d.ret_expr in

            (* TODO move the [expr i] function to other branch only *)
            (* (\* Use expr. Otherwise we get unused binding error *\) *)
            (* ignore (expr i); *)
            unify (d.loc, "Match expression does not match:") ret_typ ret.typ;
            ret
        | Var { index; loc; name; d; patterns } ->
            (* Bind the variable *)
            let env =
              Env.add_value name (expr index).typ ~is_const:false d.loc env
            in
            (* Continue with expression *)
            let ret =
              compile_matches env loc rows ((patterns, d) :: tl) ret_typ
            in

            {
              typ = ret.typ;
              expr = Let (name, expr index, ret);
              is_const = ret.is_const;
            }
        | Ctor { index; loc; name; d; patterns } ->
            let a, b = match_cases (index, name) ((patterns, d) :: tl) [] [] in

            let l, ctor, variant = get_variant env d.loc (loc, name) None in
            unify
              (d.loc, "Variant pattern has unexpected type:")
              (expr index).typ variant;

            let data, ifenv = ctorenv env ctor index d.loc in
            let cont = compile_matches ifenv d.loc rows a ret_typ in
            (* Make expr available in codegen *)
            let ifexpr = Let (expr_name index, data, cont) in

            (* This is either an if-then-else or just an one ctor,
               depending on whether [b] is empty *)
            let expr =
              match b with
              | [] -> ifexpr
              | b ->
                  let cmp = gen_cmp (expr index) l.index in
                  let if_ = { cont with expr = ifexpr } in
                  let else_ = compile_matches env d.loc rows b ret_typ in
                  If (cmp, if_, else_)
            in

            { typ = ret_typ; expr; is_const = false })
    | [] -> failwith "Internal Error: Empty match"

  and match_cases (i, case) cases if_ else_ =
    match cases with
    | (clauses, d) :: tl -> (
        match List.assoc_opt i clauses with
        | Some (Ast.Pctor ((loc, name), arg)) when String.equal case name ->
            (* We found the [case] ctor, thus we extract the argument and insert
               it at the ctor's place to the [if_] list. Since we are one level
               deeper, we replace [i]'s [lvl] with [lvl + 1] *)
            let arg = arg_opt loc arg in
            let clauses = assoc_set i arg clauses in
            match_cases (i, case) tl ((clauses, d) :: if_) else_
        | Some (Ast.Pctor (_, _)) ->
            (* We found a ctor, but it does not match. Add to [else_] *)
            match_cases (i, case) tl if_ ((clauses, d) :: else_)
        | Some (Pvar _ | Pwildcard _) ->
            (* These match all, so we add them to both [if_] and [else_] *)
            match_cases (i, case) tl ((clauses, d) :: if_)
              ((clauses, d) :: else_)
        | Some (Ptup _) -> failwith "Internal Error: Unexpected tup"
        | None -> failwith "Internal Error: Column does not exist")
    | [] -> (List.rev if_, List.rev else_)
end
