open Types
open Typed_tree
open Inference

module Col_path = struct
  type t = int list

  let compare a b =
    let a = Hashtbl.hash a and b = Hashtbl.hash b in
    Int.compare a b
end

module Cmap = Map.Make (Col_path)

module type Core = sig
  val convert : Env.t -> Ast.expr -> typed_expr
  val convert_var : Env.t -> Ast.loc -> string -> typed_expr
  val convert_block : ?ret:bool -> Env.t -> Ast.block -> typed_expr * Env.t
end

module type Recs = sig
  val get_record_type :
    Env.t -> Ast.loc -> string list -> Types.typ option -> Types.typ
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
    (Ast.loc * Ast.pattern * Ast.expr) list ->
    Typed_tree.typed_expr
end

let array_assoc_opt name arr =
  let rec inner i =
    if i = Array.length arr then None
    else
      let ctor = arr.(i) in
      if String.equal ctor.cname name then Some ctor else inner (i + 1)
  in
  inner 0

let get_variant env loc (_, name) annot =
  (* Don't use clean directly, to keep integrity of link *)
  match annot with
  | Some variant -> (
      match clean variant with
      | Tvariant (_, typename, ctors) ->
          let ctor =
            match array_assoc_opt name ctors with
            | Some ctor -> ctor
            | None ->
                let msg =
                  Printf.sprintf "Unbound constructor %s on variant %s" name
                    typename
                in
                raise (Error (loc, msg))
          in
          (typename, ctor, variant)
      | t ->
          let msg =
            Printf.sprintf "Expecting a variant type, not %s" (string_of_type t)
          in
          raise (Error (loc, msg)))
  | None -> (
      match Env.find_ctor_opt name env with
      | Some { index; typename } ->
          (* We get the ctor type from the variant *)
          let ctor, variant =
            match Env.query_type ~instantiate typename env with
            | Tvariant (_, _, ctors) as typ -> (ctors.(index), typ)
            | _ -> failwith "Internal Error: Not a variant"
          in

          (match annot with
          | Some t -> unify (loc, "In constructor " ^ name ^ ":") t variant
          | None -> ());
          (typename, ctor, variant)
      | None ->
          let msg = "Unbound constructor " ^ name in
          raise (Error (loc, msg)))

type pattern_data = { loc : Ast.loc; ret_expr : Ast.expr; row : int }

type typed_pattern = { ptyp : typ; pat : tpat }
and pathed_pattern = int list * typed_pattern

and tpat =
  | Tp_ctor of Ast.loc * string * ctor_param
  | Tp_var of Ast.loc * string
  | Tp_wildcard of Ast.loc
  | Tp_record of Ast.loc * index_field list

and ctor_param = { cindex : int; cpat : pathed_pattern option }

and index_field = {
  floc : Ast.loc;
  name : string;
  index : int;
  iftyp : typ;
  fpat : pathed_pattern option;
}

module Tup = struct
  type payload = {
    path : int list;
        (* Records need a path instead of just a column. {:a} in 1st column might be [0;0] *)
    loc : Ast.loc;
    name : string;
    d : pattern_data;
    patterns : pathed_pattern list;
    pltyp : typ;
  }

  type ret =
    | Var of payload
    | Ctor of payload * ctor_param
    | Bare of pattern_data
    | Record of index_field list * payload

  let choose_column ctors tl =
    (* Count wildcards and vars per column. They lead to duplicated branches *)
    (* TODO special handling for record pattern. This needs to be destructored
       and the wildcards and vars counted *)
    let dummy_loc = (Lexing.dummy_pos, Lexing.dummy_pos) in
    let dummy_pattern = { ptyp = Tunit; pat = Tp_wildcard dummy_loc } in
    let m =
      List.fold_left
        (fun acc (l, _) ->
          List.fold_left
            (fun acc (col, pat) ->
              match pat.pat with
              | Tp_wildcard _ | Tp_var _ ->
                  (* increase count *)
                  Cmap.update col
                    (function None -> Some 1 | Some a -> Some (a + 1))
                    acc
              | _ -> acc)
            acc l)
        Cmap.empty tl
    in
    (* Choose column with smallest count *)
    let (col, pat), _ =
      List.fold_left
        (fun ((acol, apat), acnt) (col, pat) ->
          let cnt = match Cmap.find_opt col m with Some c -> c | None -> 0 in
          if cnt < acnt then ((col, pat), cnt) else ((acol, apat), acnt))
        (([ -1 ], dummy_pattern), Int.max_int)
        ctors
    in
    assert (match col with [] -> false | hd :: _ -> hd >= 0);
    (col, pat)

  let choose_next (patterns, d) tl =
    (* We choose a column based on precedence.
       [Pwildcard] is dropped
       1: [Pvar] needs to be bound,
       2: Otherwise, we choose a ctor, using [choose_column] *)
    let score_patterns pattern =
      match (snd pattern).pat with
      | Tp_record _ ->
          3 (* Records have highest prio, as they get destructored *)
      | Tp_ctor _ -> 2
      | Tp_var _ -> 1
      | Tp_wildcard _ -> failwith "Internal Error: Should have been dropped"
    in
    let sort_patterns a b = Int.compare (score_patterns a) (score_patterns b) in
    let filter_patterns p =
      match (snd p).pat with Tp_wildcard _ -> false | _ -> true
    in
    let sorted =
      List.filter filter_patterns patterns |> List.sort sort_patterns
    in

    match sorted with
    | [ (path, { pat = Tp_ctor (loc, name, param); ptyp }) ] ->
        Ctor ({ path; loc; name; d; patterns = sorted; pltyp = ptyp }, param)
    | (_, { pat = Tp_ctor _; ptyp }) :: _ -> (
        let path, pat = choose_column sorted tl in
        match pat.pat with
        | Tp_ctor (loc, name, param) ->
            Ctor ({ path; loc; name; d; patterns = sorted; pltyp = ptyp }, param)
        | _ -> failwith "Internal Error: Not a constructor")
    | (path, { pat = Tp_var (loc, name); ptyp }) :: patterns ->
        (* Drop var from patterns list *)
        Var { path; loc; name; d; patterns; pltyp = ptyp }
    | (_, { pat = Tp_wildcard _; _ }) :: _ ->
        failwith "Internal Error: Unexpected sorted pattern"
    | (path, { pat = Tp_record (loc, fields); ptyp }) :: patterns ->
        (* Drop record from patterns list *)
        Record (fields, { path; loc; name = ""; d; patterns; pltyp = ptyp })
    | [] -> Bare d
end

module Exhaustiveness = struct
  module Set = Set.Make (String)

  type wip_kind = New_column | Specialization
  type exhaustive = Exh | Wip of wip_kind * typed_pattern list list
  type ctorset = Ctors of ctor list | Inf | Record of field list

  let ctorset_of_variant = function
    | Tvariant (_, _, ctors) -> Ctors (Array.to_list ctors)
    | Trecord (_, _, fields) -> Record (Array.to_list fields)
    | _ -> Inf

  (* [pattern] has a complete signature on first column *)
  type signature =
    | Complete of ctor list
    | Missing of string list
    | Infi
    | Maybe_red of Ast.loc * ctor list
    | Expand_record of field list
    | Empty

  (** Check if ctorset is complete or some ctor is missing. Might also be infinite *)
  let sig_complete fstcl patterns =
    match List.(hd patterns) with
    | [] -> Empty
    | p :: _ -> (
        let typ = p.ptyp in
        match ctorset_of_variant (clean typ) with
        | Ctors ctors ->
            let set =
              ctors |> List.map (fun ctor -> ctor.cname) |> Set.of_list
            in

            let rec fold f lwild last acc = function
              (* Special case if the last case is a wildcard. Here, we might have a complete
                 ctor set before and the wildcard is redundant *)
              | [] -> last acc
              | [ { pat = Tp_wildcard loc; _ } :: _ ] -> lwild loc acc
              | hd :: tl -> fold f lwild last (f acc hd) tl
            in
            let f set = function
              | { pat = Tp_ctor (_, name, _); _ } :: _ ->
                  Set.remove name set (* TODO wildcard *)
              | _ -> set
            in
            let last set =
              if Set.is_empty set then Complete ctors
              else Missing (Set.elements set)
            in
            let last_wc =
              if fstcl then fun loc set ->
                if Set.is_empty set then
                  (* The last row is a wildcard, but all ctors are there before.
                     Might be a redundant case (see "redundant_all_cases" test case) *)
                  Maybe_red (loc, ctors)
                else f set [ { pat = Tp_wildcard loc; ptyp = typ } ] |> last
              else fun _ set -> last set
            in

            fold f last_wc last set patterns
        | Record fields -> Expand_record fields
        | Inf -> Infi)

  (* Always on first column *)
  let default patterns =
    let rows_empty = ref true in
    let new_col = ref false in
    let patterns =
      List.filter_map
        (function
          | { pat = Tp_ctor _; _ } :: _ ->
              (* Drop row *)
              rows_empty := false;
              None
          | { pat = Tp_wildcard _ | Tp_var _ | Tp_record _; _ } :: tl ->
              (* Discard head element *)
              new_col := true;
              rows_empty := false;
              Some tl
          | [] -> (* Empty row *) Some [])
        patterns
    in

    let new_col = if !new_col then New_column else Specialization in
    if !rows_empty then Exh else Wip (new_col, patterns)

  let args_to_list a = match a.cpat with Some p -> [ snd p ] | None -> []
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
          | { pat = Tp_ctor (_, name, args); _ } :: tl
            when String.equal name case ->
              rows_empty := false;
              let lst =
                match args_to_list args with
                | [] ->
                    new_col := true;
                    tl
                | lst -> lst @ tl
              in
              Some lst
          | { pat = Tp_ctor _; _ } :: _ ->
              (* Drop row *)
              rows_empty := false;
              None
          | {
              pat = Tp_wildcard loc | Tp_var (loc, _) | Tp_record (loc, _);
              ptyp;
            }
            :: tl ->
              rows_empty := false;
              let lst =
                match num_args with
                | 0 ->
                    new_col := true;
                    tl
                | _ ->
                    to_n_list { pat = Tp_wildcard loc; ptyp } num_args [] @ tl
              in
              Some lst
          | [] -> (* Empty row *) Some [])
        patterns
    in

    let new_col = if !new_col then New_column else Specialization in
    if !rows_empty then Exh else Wip (new_col, patterns)

  let keep_new_col kind (other, str) =
    match (kind, other) with
    | New_column, _ | _, New_column -> (New_column, str)
    | Specialization, Specialization -> (Specialization, str)

  (* We add an extra redundancy check for first column *)
  let rec is_exhaustive fstcl patterns : (unit, wip_kind * string list) result =
    match patterns with
    | [] -> Error (Specialization, [])
    | patterns -> (
        match sig_complete fstcl patterns with
        | Empty -> Ok ()
        | Maybe_red (loc, ctors) -> maybe_red loc patterns ctors
        | Complete ctors -> complete_sig fstcl patterns ctors
        | Missing ctors -> (
            match default patterns with
            | Exh -> Ok ()
            | Wip (kind, patterns) -> (
                (* The default matrix only removes ctors and does not add
                   temporary ones. So we can continue with exprstl *)
                match is_exhaustive false patterns with
                | Ok () -> Ok ()
                | Error _ -> Error (kind, List.map (fun s -> "#" ^ s) ctors)))
        | Expand_record fields ->
            ignore fields;
            failwith "TODO"
        | Infi -> (
            match default patterns with
            | Exh -> Ok ()
            | Wip (kind, patterns) ->
                is_exhaustive false patterns
                |> Result.map_error (keep_new_col kind)))

  and complete_sig fstcl patterns ctors =
    let exhs =
      List.map
        (fun { cname; ctyp; index = _ } ->
          let num = arg_to_num ctyp in
          ( cname,
            match specialize cname num patterns with
            | Exh -> Ok ()
            | Wip (kind, patterns) ->
                (* In case specializion adds a ctor, we elimate these first *)
                (* Right now, the argument arity is 1 at most *)
                let ret =
                  if num = 1 then is_exhaustive fstcl patterns
                  else is_exhaustive false patterns
                in
                ret |> Result.map_error (keep_new_col kind) ))
        ctors
    in

    if List.for_all (fun i -> snd i |> Result.is_ok) exhs then Ok ()
    else
      let ctor, err = List.find (fun i -> snd i |> Result.is_error) exhs in
      let kind, strs = Result.get_error err in
      let strs =
        match kind with
        | New_column ->
            List.map (fun str -> Printf.sprintf "%s, %s" ctor str) strs
        | Specialization ->
            List.map (fun str -> Printf.sprintf "(#%s %s)" ctor str) strs
      in

      Error (kind, strs)

  and maybe_red loc patterns ctors =
    (* String last entry (a wildcard) from patterns and see if all is exhaustive
       If so, the wildcard is useless *)
    (* We have to do better here in the future. This works, but is wasteful *)
    let stripped = List.rev patterns |> List.tl |> List.rev in
    match complete_sig true stripped ctors with
    | Ok () -> raise (Error (loc, "Pattern match case is redundant"))
    | Error _ -> complete_sig true patterns ctors
end

module Make (C : Core) (R : Recs) = struct
  open C
  open R

  (* Internal expression values in codegen shouldn't trigger unused binding warnings.
     `imported = true` makes sure no warning is issued *)
  let exprval = Env.{ def_value with imported = true }

  module Row = struct
    type t = { loc : Ast.loc; cnt : int }

    let compare a b = Int.compare a.cnt b.cnt
  end

  module Row_set = Set.Make (Row)

  let make_annot t =
    match clean t with
    | Qvar _ | Tvar { contents = Unbound _ } -> None
    | _ -> Some t

  (* List.Assoc.set taken from containers *)
  let rec search_set acc l x ~f =
    match l with
    | [] -> f x None acc
    | (x', y') :: l' ->
        if x = x' then f x (Some y') (List.rev_append acc l')
        else search_set ((x', y') :: acc) l' x ~f

  let assoc_set x y l = search_set [] l x ~f:(fun x _ l -> (x, y) :: l)

  let assoc_remove x l =
    search_set [] l x ~f:(fun _ opt_y rest ->
        match opt_y with None -> l (* keep as is *) | Some _ -> rest)

  let gen_cmp expr const_index =
    let index = { typ = Ti32; expr = Variant_index expr; attr = no_attr } in
    let cind =
      {
        typ = Ti32;
        expr = Const (I32 const_index);
        attr = { no_attr with const = true };
      }
    in
    let cmpexpr = Bop (Ast.Equal_i, index, cind) in
    { typ = Tbool; expr = cmpexpr; attr = no_attr }

  let mismatch_err loc name ctor arg =
    match (ctor, arg) with
    | None, Some _ ->
        let msg =
          Printf.sprintf
            "The constructor %s expects 0 arguments, but an argument is \
             provided"
            name
        in
        raise (Error (loc, msg))
    | Some _, None ->
        let msg =
          Printf.sprintf
            "The constructor %s expects arguments, but none are provided" name
        in
        raise (Error (loc, msg))
    | _ -> failwith "Internal Error: Not a mismatch"

  let convert_ctor env loc name arg annot =
    let typename, ctor, variant = get_variant env loc name annot in
    match (ctor.ctyp, arg) with
    | Some typ, Some expr ->
        let texpr = convert env expr in
        unify (loc, "In constructor " ^ snd name ^ ":") typ texpr.typ;
        let expr = Ctor (typename, ctor.index, Some texpr) in

        { typ = variant; expr; attr = no_attr }
    | None, None ->
        let expr = Ctor (typename, ctor.index, None) in
        (* NOTE: Const handling for ctors is disabled, see #23 *)
        { typ = variant; expr; attr = no_attr }
    | _ -> mismatch_err (fst name) (snd name) ctor.ctyp arg

  (* We want to be able to reference the exprs in the pattern match without
     regenerating it, so we use a magic identifier *)
  let expr_name is = "__expr" ^ String.concat "_" (List.map string_of_int is)

  let arg_opt ptyp loc = function
    | None -> { pat = Tp_wildcard loc; ptyp }
    | Some p -> snd p

  let calc_index_fields loc fields t =
    let module Set = Set.Make (String) in
    let rfields =
      match clean t with
      | Trecord (_, _, rfields) -> rfields
      | _ -> failwith "Internal Error: How is this not a record?"
    in

    let fset =
      ref (Array.to_seq rfields |> Seq.map (fun f -> f.fname) |> Set.of_seq)
    in

    let find_name loc name =
      let rec inner i =
        if i = Array.length rfields then None
        else
          let field = rfields.(i) in
          if String.equal field.fname name then
            if (* Make sure we use each field only once *)
               Set.mem name !fset
            then (
              fset := Set.remove name !fset;
              Some (field, i))
            else
              let msg =
                Printf.sprintf
                  "Field :%s appears multiple times in record pattern" name
              in
              raise (Error (loc, msg))
          else inner (i + 1)
      in
      inner 0
    in

    (* Bind all field variables *)
    (* Loop names list for better errors *)
    let index_fields =
      List.map
        (fun (loc, name, pat) ->
          let field, index =
            match find_name loc name with
            | Some f -> f
            | None ->
                let msg =
                  Printf.sprintf "Unbound field :%s on record %s" name
                    (string_of_type t)
                in
                raise (Error (loc, msg))
          in
          (field, index, loc, name, pat))
        fields
    in

    (* Make sure no fields are missing *)
    (if not (Set.is_empty !fset) then
     let missing = Set.choose !fset in
     let msg =
       Printf.sprintf
         "There are missing fields in record pattern, for instance :%s" missing
     in
     raise (Error (loc, msg)));
    index_fields

  let path_typ env p = Env.(find_val (expr_name p) env).typ

  let rec type_pattern env (path, pat) =
    match pat with
    (* Convert pattern into typed patterns. By typechecking the pattern before
       building the decision tree, record patterns (which add new columns) can
       be visited more efficiently *)
    | Ast.Pctor ((loc, name), payload) ->
        let annot = make_annot (path_typ env path) in
        let _, ctor, variant = get_variant env loc (loc, name) annot in
        unify
          (loc, "Variant pattern has unexpected type:")
          (path_typ env path) variant;
        let cpat =
          match (ctor.ctyp, payload) with
          | Some typ, Some p ->
              let env =
                Env.(add_value (expr_name path) { exprval with typ } loc env)
              in
              (* Inherit ctor path, and specialize *)
              Some (type_pattern env (path, p))
          | None, None -> None
          | _ -> mismatch_err loc name ctor.ctyp payload
        in
        let pat = Tp_ctor (loc, name, { cindex = ctor.index; cpat }) in
        (path, { ptyp = variant; pat })
    | Pvar (loc, name) ->
        let ptyp = path_typ env path in
        let pat = Tp_var (loc, name) in
        (path, { ptyp; pat })
    | Pwildcard loc ->
        let ptyp = path_typ env path in
        let pat = Tp_wildcard loc in
        (path, { ptyp; pat })
    | Ptup _ -> failwith "Internal Error: Unexpected tup"
    | Precord (loc, pats) ->
        let labelset = List.map (fun (_, a, _) -> a) pats in
        let annot = make_annot (path_typ env path) in
        let ptyp = get_record_type env loc labelset annot in
        unify
          (loc, "Record pattern has unexpected type:")
          (path_typ env path) ptyp;

        let index_fields = calc_index_fields loc pats ptyp in
        let fields =
          List.map
            (fun (field, index, floc, name, pat) ->
              let path = index :: path in
              let env =
                Env.(
                  add_value (expr_name path)
                    { exprval with typ = field.ftyp }
                    loc env)
              in
              let fpat =
                Option.map (fun pat -> type_pattern env (path, pat)) pat
              in
              { floc; name; index; iftyp = field.ftyp; fpat })
            index_fields
        in
        let pat = Tp_record (loc, fields) in
        (path, { ptyp; pat })

  let rec convert_match env loc exprs cases =
    let (columns, env), exprs =
      List.fold_left_map
        (fun (i, env) expr ->
          let e = convert env expr in
          (* Make the expr available in the patternmatch *)
          let env =
            Env.(add_value (expr_name [ i ]) { exprval with typ = e.typ })
              loc env
          in
          ((i + 1, env), ([ i ], e)))
        (0, env) exprs
    in

    let ret = newvar () in

    let used_rows = ref Row_set.empty in
    let some_cases =
      List.mapi
        (fun i (loc, p, expr) ->
          used_rows := Row_set.add Row.{ loc; cnt = i } !used_rows;
          let cols, pat =
            (* convert into typed pattern *)
            match p with
            | Ast.Ptup (_, pats) ->
                (* We track the depth (lvl) for each column separately *)
                let _, pat =
                  List.fold_left_map
                    (fun i p -> (i + 1, type_pattern env ([ i ], p)))
                    0 pats
                in
                (List.length pats, pat)
            | p -> (1, [ type_pattern env ([ 0 ], p) ])
          in
          (if cols <> columns then
           let msg =
             Printf.sprintf "Expecting %i patterns, but found %i" columns cols
           in
           raise (Error (loc, msg)));
          (pat, { loc; ret_expr = expr; row = i }))
        cases
    in

    let matchexpr = compile_matches env loc used_rows some_cases ret in

    (* Check for exhaustiveness *)
    (let patterns =
       List.map (fun p -> List.map (fun p -> snd p) (fst p)) some_cases
     in
     match Exhaustiveness.is_exhaustive true patterns with
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
          { matchexpr with expr = Let (expr_name i, None, expr, build_expr tl) }
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
      match ctor with
      | Some p ->
          let typ = (snd p).ptyp and expr = Variant_data (expr i) in
          let data = { typ; expr; attr = no_attr } in
          ( data,
            Env.(
              add_value (expr_name i) { exprval with typ = data.typ } loc env)
          )
      | None -> (expr i, env)
    in

    match cases with
    | hd :: tl -> (
        match Tup.choose_next hd tl with
        | Bare d ->
            (* Mark row as used *)
            rows := Row_set.remove { cnt = d.row; loc = d.loc } !rows;

            let ret = convert env d.ret_expr in

            unify (d.loc, "Match expression does not match:") ret_typ ret.typ;
            ret
        | Var { path; loc; name; d; patterns; pltyp } ->
            (* Bind the variable *)
            let env =
              Env.(add_value name { def_value with typ = pltyp } loc env)
            in
            (* Continue with expression *)
            let ret =
              compile_matches env loc rows ((patterns, d) :: tl) ret_typ
            in

            {
              typ = ret.typ;
              expr = Let (name, None, expr path, ret);
              attr = ret.attr;
            }
        | Ctor ({ path; loc; name; d; patterns; pltyp = _ }, param) ->
            let a, b = match_cases (path, name) ((patterns, d) :: tl) [] [] in

            let data, ifenv = ctorenv env param.cpat path loc in
            let cont = compile_matches ifenv d.loc rows a ret_typ in
            (* Make expr available in codegen *)
            let ifexpr = Let (expr_name path, None, data, cont) in

            (* This is either an if-then-else or just an one ctor,
               depending on whether [b] is empty *)
            let expr =
              match b with
              | [] -> ifexpr
              | b ->
                  let cmp = gen_cmp (expr path) param.cindex in
                  let if_ = { cont with expr = ifexpr } in
                  let else_ = compile_matches env d.loc rows b ret_typ in
                  If (cmp, if_, else_)
            in

            { typ = ret_typ; expr; attr = no_attr }
        | Record (fields, { path; loc; d; patterns; _ }) ->
            let env =
              List.fold_left
                (fun env field ->
                  let col = field.index :: path in
                  let env =
                    Env.(
                      add_value (expr_name col)
                        { exprval with typ = field.iftyp }
                        loc env)
                  in
                  env)
                env fields
            in

            (* Since we have all neccessary data in place, we do this row here *)
            let patterns = expand_record path fields patterns in
            (* Expand in all rows down from here. Replace record pattern with expanded fields *)
            let tl = expand_records path tl [] in

            let ret =
              compile_matches env loc rows ((patterns, d) :: tl) ret_typ
            in
            let expr =
              List.fold_left
                (fun ret { index; iftyp; _ } ->
                  let newcol = index :: path in
                  let expr =
                    {
                      typ = iftyp;
                      expr = Field (expr path, index);
                      attr = no_attr;
                    }
                  in

                  { ret with expr = Let (expr_name newcol, None, expr, ret) })
                ret fields
            in
            expr)
    | [] -> failwith "Internal Error: Empty match"

  and match_cases (i, case) cases if_ else_ =
    match cases with
    | (clauses, d) :: tl -> (
        match List.assoc_opt i clauses with
        | Some { pat = Tp_ctor (loc, name, arg); ptyp }
          when String.equal case name ->
            (* We found the [case] ctor, thus we extract the argument and insert
               it at the ctor's place to the [if_] list. Since we are one level
               deeper, we replace [i]'s [lvl] with [lvl + 1] *)
            let arg = arg_opt ptyp loc arg.cpat in
            let clauses = assoc_set i arg clauses in
            match_cases (i, case) tl ((clauses, d) :: if_) else_
        | Some { pat = Tp_ctor _ | Tp_record _; _ } ->
            (* We found a ctor, but it does not match. Add to [else_].
               This works for record patterns as well. We are searching for a ctor,
               a record is surely not the ctor we are searching for *)
            match_cases (i, case) tl if_ ((clauses, d) :: else_)
        | Some { pat = Tp_var _ | Tp_wildcard _; _ } | None ->
            (* These match all, so we add them to both [if_] and [else_] *)
            (* We can also end up here if a record was not expanded.
               Treat like wildcard or var *)
            match_cases (i, case) tl ((clauses, d) :: if_)
              ((clauses, d) :: else_))
    | [] -> (List.rev if_, List.rev else_)

  and expand_record path fields patterns =
    List.fold_left
      (fun pats { floc; name; index; iftyp; fpat } ->
        let col = index :: path in
        (* If there is no extra pattern provided, the field name
           functions as a variable pattern *)
        let pat =
          match fpat with
          | Some p -> snd p
          | None -> { ptyp = iftyp; pat = Tp_var (floc, name) }
        in
        (col, pat) :: pats)
      patterns fields

  and expand_records path patterns expanded =
    match patterns with
    | (patterns, d) :: tl -> (
        match List.assoc_opt path patterns with
        | Some { pat = Tp_record (_, fields); _ } ->
            (* First, remove current record pattern *)
            let patterns =
              assoc_remove path patterns |> expand_record path fields
            in
            expand_records path tl ((patterns, d) :: expanded)
        | Some _ ->
            (* If there is another pattern, the record is not expanded, thus not expandable *)
            expand_records path tl ((patterns, d) :: expanded)
        | None ->
            (* Nothing is found here, this is an error, or a nested pattern.
               We throw first to have a look TODO *)
            failwith "Internal Error: Maybe? Nested record?")
    | [] -> List.rev expanded
end
