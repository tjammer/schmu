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
    Ast.expr ->
    (Ast.loc * Ast.pattern * Ast.expr) list ->
    Typed_tree.typed_expr

  val pattern_id : int -> Ast.pattern -> string * Ast.loc

  val convert_decl :
    Env.t -> Ast.decl list -> Env.t * (string * typed_expr) list
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
                    (Path.show typename)
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

type pattern_data = {
  loc : Ast.loc;
  ret_expr : Ast.expr;
  row : int;
  ret_env : Env.t;
}

type typed_pattern = { ptyp : typ; pat : tpat }
and pathed_pattern = int list * typed_pattern

and tpat =
  | Tp_ctor of Ast.loc * ctor_param
  | Tp_var of Ast.loc * string
  | Tp_wildcard of Ast.loc
  | Tp_record of Ast.loc * record_field list
  | Tp_tuple of Ast.loc * tuple_field list
  | Tp_int of Ast.loc * int
  | Tp_char of Ast.loc * char

and ctor_param = { cindex : int; cpat : pathed_pattern option; ctname : string }

and record_field = {
  floc : Ast.loc;
  name : string;
  index : int;
  iftyp : typ;
  fpat : pathed_pattern option;
}

and tuple_field = {
  tloc : Ast.loc;
  tindex : int;
  ttyp : typ;
  tpat : pathed_pattern;
}

let loc_of_pat = function
  | Tp_wildcard loc
  | Tp_var (loc, _)
  | Tp_record (loc, _)
  | Tp_tuple (loc, _)
  | Tp_ctor (loc, _)
  | Tp_int (loc, _)
  | Tp_char (loc, _) ->
      loc

module Tup = struct
  type payload = {
    path : int list;
        (* Records need a path instead of just a column. {:a} in 1st column might be [0;0] *)
    loc : Ast.loc;
    d : pattern_data;
    patterns : pathed_pattern list;
    pltyp : typ;
  }

  (* TODO use payload *)
  type 'a ret =
    | Var of 'a * string
    | Ctor of 'a * ctor_param
    | Lit_int of 'a * int
    | Lit_char of 'a * char
    | Bare of pattern_data
    | Record of record_field list * 'a
    | Tuple of tuple_field list * 'a

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
      | Tp_record _ | Tp_tuple _ ->
          1 (* Records have highest prio, as they get destructored *)
      | Tp_ctor _ -> 3
      | Tp_int _ | Tp_char _ -> 3
      | Tp_var _ -> 2
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
    | [ (path, { pat = Tp_ctor (loc, param); ptyp }) ] ->
        Ctor ({ path; loc; d; patterns = sorted; pltyp = ptyp }, param)
    | [ (path, { pat = Tp_int (loc, i); ptyp }) ] ->
        Lit_int ({ path; loc; d; patterns = sorted; pltyp = ptyp }, i)
    | [ (path, { pat = Tp_char (loc, c); ptyp }) ] ->
        Lit_char ({ path; loc; d; patterns = sorted; pltyp = ptyp }, c)
    | (_, { pat = Tp_ctor _; ptyp }) :: _ -> (
        let path, pat = choose_column sorted tl in
        match pat.pat with
        | Tp_ctor (loc, param) ->
            Ctor ({ path; loc; d; patterns = sorted; pltyp = ptyp }, param)
        | _ -> failwith "Internal Error: Not a constructor")
    | (_, { pat = Tp_int _; ptyp }) :: _ -> (
        let path, pat = choose_column sorted tl in
        match pat.pat with
        | Tp_int (loc, i) ->
            Lit_int ({ path; loc; d; patterns = sorted; pltyp = ptyp }, i)
        | _ -> failwith "Internal Error: Not an int pattern")
    | (_, { pat = Tp_char _; ptyp }) :: _ -> (
        let path, pat = choose_column sorted tl in
        match pat.pat with
        | Tp_char (loc, c) ->
            Lit_char ({ path; loc; d; patterns = sorted; pltyp = ptyp }, c)
        | _ -> failwith "Internal Error: Not an int pattern")
    | (path, { pat = Tp_var (loc, name); ptyp }) :: patterns ->
        (* Drop var from patterns list *)
        Var ({ path; loc; d; patterns; pltyp = ptyp }, name)
    | (_, { pat = Tp_wildcard _; _ }) :: _ ->
        failwith "Internal Error: Unexpected sorted pattern"
    | (path, { pat = Tp_record (loc, fields); ptyp }) :: patterns ->
        (* Drop record from patterns list *)
        Record (fields, { path; loc; d; patterns; pltyp = ptyp })
    | (path, { pat = Tp_tuple (loc, fields); ptyp }) :: patterns ->
        (* Drop tuple from patterns list *)
        Tuple (fields, { path; loc; d; patterns; pltyp = ptyp })
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
              | { pat = Tp_ctor (_, p); _ } :: _ ->
                  Set.remove p.ctname set (* TODO wildcard *)
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
          | { pat = Tp_ctor _ | Tp_int _ | Tp_char _; _ } :: _ ->
              (* Drop row *)
              rows_empty := false;
              None
          | { pat = Tp_wildcard _ | Tp_var _ | Tp_record _ | Tp_tuple _; _ }
            :: tl ->
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
          | { pat = Tp_ctor (_, param); _ } :: tl
            when String.equal param.ctname case ->
              rows_empty := false;
              let lst =
                match args_to_list param with
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
          | { pat; ptyp } :: tl ->
              rows_empty := false;
              let lst =
                match num_args with
                | 0 ->
                    new_col := true;
                    tl
                | _ ->
                    let loc = loc_of_pat pat in
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
        | Expand_record fields -> expand_record fields patterns
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

  and expand_record fields patterns =
    (* The pattern in the first column is a record pattern. We replace it by
       the expanded record pattern instead. If there is an actual record pattern
       we can use it as is. Otherwise we fill the fields with wildcards *)
    let wc_field loc ptyp = { pat = Tp_wildcard loc; ptyp } in

    let f = function
      | [] -> failwith "Internal Error: There are so empty records"
      | { pat = Tp_record (_, fields); _ } :: tl ->
          let fields =
            List.map
              (fun f ->
                match f.fpat with
                | Some p -> snd p
                | None -> wc_field f.floc f.iftyp)
              fields
          in
          fields @ tl
      | p :: tl ->
          let fields =
            List.map (fun f -> wc_field (loc_of_pat p.pat) f.ftyp) fields
          in
          fields @ tl
    in
    is_exhaustive false (List.map f patterns)
end

module Make (C : Core) (R : Recs) = struct
  open C
  open R

  (* Internal expression values in codegen shouldn't trigger unused binding warnings.
     `imported = true` makes sure no warning is issued *)
  let exprval = Env.def_value

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

  let gen_cmp loc index cind =
    let cmpexpr = Bop (Ast.Equal_i, index, cind) in
    { typ = Tbool; expr = cmpexpr; attr = no_attr; loc }

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
        let expr = Ctor (Path.get_hd typename, ctor.index, Some texpr) in

        { typ = variant; expr; attr = no_attr; loc }
    | None, None ->
        let expr = Ctor (Path.get_hd typename, ctor.index, None) in
        (* NOTE: Const handling for ctors is disabled, see #23 *)
        { typ = variant; expr; attr = no_attr; loc }
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
      let rec inner = function
        | Trecord (_, _, rfields) -> rfields
        | Talias (_, t) | Tvar { contents = Link t } -> inner t
        | t ->
            raise
              (Error
                 (loc, "Record pattern has unexpected type " ^ string_of_type t))
      in
      inner t
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

  (* from containers *)
  let cartesian_product l =
    (* [left]: elements picked so far
       [right]: sets to pick elements from
       [acc]: accumulator for the result, to pass to continuation
       [k]: continuation *)
    let rec prod_rec left right k acc =
      match right with
      | [] -> k acc (List.rev left)
      | l1 :: tail ->
          List.fold_left (fun acc x -> prod_rec (x :: left) tail k acc) acc l1
    in
    prod_rec [] l (fun acc l' -> l' :: acc) []

  let add_ignore name value loc env =
    let env = Env.(add_value name value loc env) in
    ignore (Env.query_val_opt name env);
    env

  let path_typ env p = Env.(find_val (expr_name p) env).typ

  let rec type_pattern env (path, pat) =
    (* This function got a little more complicated since we expand or-patterns
       inplace. *)
    match pat with
    (* Convert pattern into typed patterns. By typechecking the pattern before
       building the decision tree, record patterns (which add new columns) can
       be visited more efficiently *)
    | Ast.Pctor ((loc, name), payload) -> (
        let annot = make_annot (path_typ env path) in
        let _, ctor, variant = get_variant env loc (loc, name) annot in
        unify
          (loc, "Variant pattern has unexpected type:")
          (path_typ env path) variant;
        match (ctor.ctyp, payload) with
        | Some typ, Some p ->
            let env =
              add_ignore (expr_name path) { exprval with typ } loc env
            in
            (* Inherit ctor path, and specialize *)
            let lst = type_pattern env (path, p) in
            let f cpat =
              let pat =
                Tp_ctor
                  (loc, { cindex = ctor.index; cpat = Some cpat; ctname = name })
              in
              (path, { ptyp = variant; pat })
            in
            List.map f lst
        | None, None ->
            let pat =
              Tp_ctor (loc, { cindex = ctor.index; cpat = None; ctname = name })
            in
            [ (path, { ptyp = variant; pat }) ]
        | _ -> mismatch_err loc name ctor.ctyp payload)
    | Pvar (loc, name) ->
        let ptyp = path_typ env path in
        let pat = Tp_var (loc, name) in
        [ (path, { ptyp; pat }) ]
    | Pwildcard loc ->
        let ptyp = path_typ env path in
        let pat = Tp_wildcard loc in
        [ (path, { ptyp; pat }) ]
    | Ptup (loc, pats) ->
        let typ = path_typ env path in
        let pats =
          List.mapi
            (fun i (tloc, pat) ->
              let path = i :: path in
              let env =
                add_ignore (expr_name path)
                  { exprval with typ = newvar () }
                  loc env
              in
              let tpats = type_pattern env (path, pat) in
              let fields =
                List.map
                  (fun tpat ->
                    { tloc; tindex = i; ttyp = (snd tpat).ptyp; tpat })
                  tpats
              in
              fields)
            pats
        in
        let fields =
          List.map
            (fun p ->
              let p = List.hd p in
              let ftyp = p.ttyp in
              { fname = string_of_int p.tindex; ftyp; mut = false })
            pats
          |> Array.of_list
        in
        unify
          (loc, "Tuple pattern has unexpected type:")
          (Trecord ([], None, fields))
          typ;
        cartesian_product pats
        |> List.map (fun pats ->
               let pat = Tp_tuple (loc, pats) in
               (path, { ptyp = typ; pat }))
    | Precord (loc, pats) ->
        let labelset = List.map (fun (_, name, _) -> name) pats in
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
                add_ignore (expr_name path)
                  { exprval with typ = field.ftyp }
                  loc env
              in
              match pat with
              | None ->
                  [ { floc; name; index; iftyp = field.ftyp; fpat = None } ]
              | Some pat ->
                  let pats = type_pattern env (path, pat) in
                  List.map
                    (fun fpat ->
                      {
                        floc;
                        name;
                        index;
                        iftyp = field.ftyp;
                        fpat = Some fpat;
                      })
                    pats)
            index_fields
        in
        cartesian_product fields
        |> List.map (fun fields ->
               let pat = Tp_record (loc, fields) in
               (path, { ptyp; pat }))
    | Plit_int (loc, i) ->
        unify (loc, "Int pattern has unexpected type:") (path_typ env path) Tint;
        [ (path, { ptyp = Tint; pat = Tp_int (loc, i) }) ]
    | Plit_char (loc, c) ->
        unify (loc, "Char pattern has unexpected type:") (path_typ env path) Tu8;
        [ (path, { ptyp = Tu8; pat = Tp_char (loc, c) }) ]
    | Por (_, pats) ->
        (* Don't add to pattern *)
        let pats = List.map (fun p -> type_pattern env (path, p)) pats in
        cartesian_product pats |> List.concat

  let rec convert_match env loc expr cases =
    let path = [ 0 ] in
    let env, expr =
      let e = convert env expr in
      (add_ignore (expr_name path) { exprval with typ = e.typ } loc env, e)
    in

    let ret = newvar () in

    let exp_rows = ref 0 in
    (* expanded rows *)
    let used_rows = ref Row_set.empty in
    let typed_cases =
      List.map
        (fun (_, p, ret_expr) ->
          (* TODO use 2 params *)
          type_pattern env ([ 0 ], p)
          |> List.map (fun pat ->
                 incr exp_rows;
                 let loc = loc_of_pat (snd pat).pat in
                 used_rows :=
                   Row_set.add Row.{ loc; cnt = !exp_rows } !used_rows;
                 ([ pat ], { loc; ret_expr; row = !exp_rows; ret_env = env })))
        cases
    in
    let typed_cases = List.concat typed_cases in

    let cont = compile_matches env loc used_rows typed_cases ret in

    (* Check for exhaustiveness *)
    (let patterns =
       List.map (fun p -> List.map (fun p -> snd p) (fst p)) typed_cases
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

    let expr = Bind (expr_name path, None, expr, cont) in
    { cont with expr }

  and compile_matches env all_loc used_rows cases ret_typ =
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
          let data = { typ; expr; attr = no_attr; loc } in
          let env =
            add_ignore (expr_name i) { exprval with typ = data.typ } loc env
          in
          (data, env)
      | None -> (expr i, env)
    in

    match cases with
    | hd :: tl -> (
        match Tup.choose_next hd tl with
        | Bare d ->
            (* Mark row as used *)
            used_rows := Row_set.remove { cnt = d.row; loc = d.loc } !used_rows;

            let ret = convert d.ret_env d.ret_expr in

            unify (d.loc, "Match expression does not match:") ret_typ ret.typ;
            ret
        | Var ({ path; loc; d; patterns; pltyp }, id) ->
            (* Bind the variable *)
            let ret_env =
              Env.(
                add_value id
                  (* The value here is not a function parameter. But like a parameter,
                     it needs to be captured in closures and cannot be called directly,
                     because it might be a record field. Marking it param works fine
                     in this case *)
                  { def_value with typ = pltyp; param = true }
                  loc d.ret_env)
            in
            (* Continue with expression *)
            let d = { d with ret_env } in
            let cont =
              compile_matches env loc used_rows ((patterns, d) :: tl) ret_typ
            in

            let lhs = expr path in
            let expr = Let { id; uniq = None; rmut = false; lhs; cont } in
            { typ = cont.typ; expr; attr = cont.attr; loc }
        | Ctor ({ path; loc; d; patterns; pltyp = _ }, param) ->
            let a, b =
              match_cases (path, param.ctname) ((patterns, d) :: tl) [] []
            in

            let data, ifenv = ctorenv env param.cpat path loc in
            let cont = compile_matches ifenv d.loc used_rows a ret_typ in
            (* Make expr available in codegen *)
            let ifexpr =
              let id = expr_name path in
              Bind (id, None, data, cont)
            in

            (* This is either an if-then-else or just an one ctor,
               depending on whether [b] is empty *)
            let expr =
              match b with
              | [] -> ifexpr
              | b ->
                  let index =
                    let expr = Variant_index (expr path) in
                    { typ = Ti32; expr; attr = no_attr; loc }
                  in
                  let cind =
                    let attr = { no_attr with const = true } in
                    { typ = Ti32; expr = Const (I32 param.cindex); attr; loc }
                  in
                  let cmp = gen_cmp loc index cind in
                  let if_ = { cont with expr = ifexpr } in
                  let else_ = compile_matches env d.loc used_rows b ret_typ in
                  If (cmp, if_, else_)
            in

            { typ = ret_typ; expr; attr = no_attr; loc }
        | Lit_int ({ path; d; patterns; loc; _ }, i) ->
            let a, b = match_int (path, i) ((patterns, d) :: tl) [] [] in

            let cont = compile_matches env d.loc used_rows a ret_typ in

            let expr =
              match b with
              | [] -> cont.expr
              | b ->
                  let cind =
                    let attr = { no_attr with const = true } in
                    { typ = Tint; expr = Const (Int i); attr; loc }
                  in
                  let cmp = gen_cmp loc (expr path) cind in
                  let else_ = compile_matches env d.loc used_rows b ret_typ in
                  If (cmp, cont, else_)
            in
            { typ = ret_typ; expr; attr = no_attr; loc }
        | Lit_char ({ path; d; patterns; loc; _ }, c) ->
            let a, b = match_char (path, c) ((patterns, d) :: tl) [] [] in

            let cont = compile_matches env d.loc used_rows a ret_typ in

            let expr =
              match b with
              | [] -> cont.expr
              | b ->
                  let cind =
                    let attr = { no_attr with const = true } in
                    { typ = Tu8; expr = Const (U8 c); attr; loc }
                  in
                  (* i64 and u8 equal compare call the same llvm functions *)
                  let cmp = gen_cmp loc (expr path) cind in
                  let else_ = compile_matches env d.loc used_rows b ret_typ in
                  If (cmp, cont, else_)
            in
            { typ = ret_typ; expr; attr = no_attr; loc }
        | Record (fields, { path; loc; d; patterns; _ }) ->
            let env =
              List.fold_left
                (fun env field ->
                  let col = field.index :: path in
                  add_ignore (expr_name col)
                    { exprval with typ = field.iftyp }
                    loc env)
                env fields
            in

            (* Since we have all neccessary data in place, we do this row here *)
            let patterns = expand_record path fields patterns in
            (* Expand in all rows down from here. Replace record pattern with expanded fields *)
            let tl = expand_records path tl [] in

            let ret =
              compile_matches env loc used_rows ((patterns, d) :: tl) ret_typ
            in
            let expr =
              List.fold_left
                (fun cont { index; iftyp; _ } ->
                  let newcol = index :: path in
                  let expr = Field (expr path, index) in
                  let expr = { typ = iftyp; expr; attr = no_attr; loc } in

                  let expr =
                    let id = expr_name newcol in
                    Bind (id, None, expr, cont)
                  in
                  { cont with expr })
                ret fields
            in
            expr
        | Tuple (fields, { path; loc; d; patterns; _ }) ->
            let env =
              List.fold_left
                (fun env pat ->
                  let col = pat.tindex :: path in
                  add_ignore (expr_name col)
                    { exprval with typ = pat.ttyp }
                    loc env)
                env fields
            in

            (* Since we have all neccessary data in place, we do this row here *)
            let patterns = expand_tuple path fields patterns in
            (* Expand in all rows down from here. Replace tuple pattern with expanded fields *)
            let tl = expand_tuples path tl [] in

            let ret =
              compile_matches env loc used_rows ((patterns, d) :: tl) ret_typ
            in
            let expr =
              List.fold_left
                (fun cont pat ->
                  let newcol = pat.tindex :: path in
                  let expr = Field (expr path, pat.tindex) in
                  let expr = { typ = pat.ttyp; expr; attr = no_attr; loc } in
                  let expr =
                    let id = expr_name newcol in
                    Bind (id, None, expr, cont)
                  in
                  { cont with expr })
                ret fields
            in
            expr)
    | [] -> failwith "Internal Error: Empty match"

  and match_cases (i, case) cases if_ else_ =
    match cases with
    | (clauses, d) :: tl -> (
        match List.assoc_opt i clauses with
        | Some { pat = Tp_ctor (loc, param); ptyp }
          when String.equal case param.ctname ->
            (* We found the [case] ctor, thus we extract the argument and insert
               it at the ctor's place to the [if_] list. Since we are one level
               deeper, we replace [i]'s [lvl] with [lvl + 1] *)
            let arg = arg_opt ptyp loc param.cpat in
            let clauses = assoc_set i arg clauses in
            match_cases (i, case) tl ((clauses, d) :: if_) else_
        | Some
            {
              pat = Tp_ctor _ | Tp_record _ | Tp_tuple _ | Tp_int _ | Tp_char _;
              _;
            } ->
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

  and match_int (path, int) cases if_ else_ =
    match cases with
    | (clauses, d) :: tl -> (
        match List.assoc_opt path clauses with
        | Some { pat = Tp_int (_, i); _ } when Int.equal int i ->
            let clauses = assoc_remove path clauses in
            match_int (path, int) tl ((clauses, d) :: if_) else_
        | Some
            {
              pat = Tp_ctor _ | Tp_record _ | Tp_tuple _ | Tp_int _ | Tp_char _;
              _;
            } ->
            match_int (path, int) tl if_ ((clauses, d) :: else_)
        | Some { pat = Tp_var _ | Tp_wildcard _; _ } | None ->
            match_int (path, int) tl ((clauses, d) :: if_)
              ((clauses, d) :: else_))
    | [] -> (List.rev if_, List.rev else_)

  and match_char (path, char) cases if_ else_ =
    match cases with
    | (clauses, d) :: tl -> (
        match List.assoc_opt path clauses with
        | Some { pat = Tp_char (_, c); _ } when Char.equal char c ->
            let clauses = assoc_remove path clauses in
            match_char (path, char) tl ((clauses, d) :: if_) else_
        | Some
            {
              pat = Tp_ctor _ | Tp_record _ | Tp_tuple _ | Tp_int _ | Tp_char _;
              _;
            } ->
            match_char (path, char) tl if_ ((clauses, d) :: else_)
        | Some { pat = Tp_var _ | Tp_wildcard _; _ } | None ->
            match_char (path, char) tl ((clauses, d) :: if_)
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

  and expand_tuple path fields patterns =
    List.fold_left
      (fun pats { tindex; tpat; _ } ->
        let col = tindex :: path in
        assert (col = fst tpat);
        tpat :: pats)
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

  and expand_tuples path patterns expanded =
    match patterns with
    | (patterns, d) :: tl -> (
        match List.assoc_opt path patterns with
        | Some { pat = Tp_tuple (_, fields); _ } ->
            (* First, remove current record pattern *)
            let patterns =
              assoc_remove path patterns |> expand_tuple path fields
            in
            expand_tuples path tl ((patterns, d) :: expanded)
        | Some _ ->
            (* If there is another pattern, the record is not expanded, thus not expandable *)
            expand_tuples path tl ((patterns, d) :: expanded)
        | None ->
            (* Nothing is found here, this is an error, or a nested pattern.
               We throw first to have a look TODO *)
            failwith "Internal Error: Maybe? Nested record?")
    | [] -> List.rev expanded

  let pattern_id i = function
    | Ast.Pvar (loc, id) -> (id, loc)
    | Ptup (loc, _) | Pwildcard loc | Precord (loc, _) -> (expr_name [ i ], loc)
    | Pctor ((loc, _), _) | Plit_int (loc, _) | Plit_char (loc, _) | Por (loc, _)
      ->
        raise (Error (loc, "Unexpected pattern in declaration"))

  (* Magic value, see above *)
  let expr env i loc = convert_var env loc (expr_name i)

  let bind_pattern env loc i p =
    let typed = type_pattern env ([ i ], p) in
    let pts = List.map snd typed in
    (match Exhaustiveness.is_exhaustive true [ pts ] with
    | Ok () -> ()
    | Error (_, cases) ->
        let msg =
          Printf.sprintf "Pattern match is not exhaustive. Missing cases: %s"
            (String.concat " | " cases)
        in
        raise (Error (loc, msg)));

    let rec loop (env, binds) = function
      | (path, pat) :: tl -> (
          match pat.pat with
          | Tp_record (loc, fields) ->
              let env, nbinds =
                List.fold_left_map
                  (fun env f ->
                    let col = f.index :: path in

                    let expr = Field (expr env path f.floc, f.index) in
                    let expr =
                      { typ = f.iftyp; expr; attr = no_attr; loc = f.floc }
                    in
                    let id = expr_name col in

                    ( add_ignore (expr_name col)
                        { exprval with typ = f.iftyp }
                        loc env,
                      (id, expr) ))
                  env fields
              in
              let pats = expand_record path fields tl in
              loop (env, nbinds @ binds) pats
          | Tp_tuple (loc, fields) ->
              let env, nbinds =
                List.fold_left_map
                  (fun env f ->
                    let col = f.tindex :: path in

                    let expr = Field (expr env path f.tloc, f.tindex) in
                    let expr =
                      { typ = f.ttyp; expr; attr = no_attr; loc = f.tloc }
                    in
                    let id = expr_name col in

                    ( add_ignore (expr_name col)
                        { exprval with typ = f.ttyp }
                        loc env,
                      (id, expr) ))
                  env fields
              in
              let pats = expand_tuple path fields tl in
              loop (env, nbinds @ binds) pats
          | Tp_var (loc, id) ->
              let env =
                Env.(add_value id { def_value with typ = pat.ptyp } loc env)
              in
              loop (env, (id, expr env path loc) :: binds) tl
          | Tp_wildcard _ -> loop (env, binds) tl
          | Tp_ctor _ | Tp_int _ | Tp_char _ ->
              failwith
                "Internal Error: Should have been filtered in [convert_decl]")
      | [] -> (env, binds)
    in
    loop (env, []) typed

  let convert_decl env pats =
    let f (env, i, ret) decl =
      match Ast.(decl.pattern) with
      | Ast.Pvar _ -> (env, i + 1, ret)
      | Pwildcard _ ->
          (* expr_name was added before to env in [handle_param].
             Make sure it's marked as used *)
          ignore (Env.query_val_opt (expr_name [ i ]) env);
          (env, i + 1, ret)
      | (Ptup (loc, _) | Precord (loc, _)) as p ->
          let env, binds = bind_pattern env loc i p in
          (env, i + 1, binds)
      | Pctor ((loc, _), _)
      | Plit_int (loc, _)
      | Plit_char (loc, _)
      | Por (loc, _) ->
          raise (Error (loc, "Unexpected pattern in declaration"))
    in

    let env, _, binds = List.fold_left f (env, 0, []) pats in
    (env, binds)
end
