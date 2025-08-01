open Types
open Typed_tree
open Inference
open Error

module Col_path = struct
  type t = int list

  let compare a b =
    let a = Hashtbl.hash a and b = Hashtbl.hash b in
    Int.compare a b
end

module Cmap = Map.Make (Col_path)

module type Core = sig
  val convert : Env.t -> Ast.expr -> typed_expr
  val convert_var : Env.t -> Ast.loc -> Path.t -> typed_expr

  val convert_block :
    ?ret:bool -> pipe:bool -> Env.t -> Ast.block -> typed_expr * Env.t

  val pass_mut_helper :
    Env.t -> Ast.loc -> dattr -> (unit -> typed_expr) -> typed_expr
end

module type Recs = sig
  val get_record_type :
    Env.t -> Ast.loc -> string list -> Types.typ option -> Types.typ

  val fields_of_record :
    Ast.loc -> Path.t -> typ list option -> Env.t -> (field array, unit) result
end

module type S = sig
  val convert_ctor :
    Env.t ->
    Ast.loc ->
    Ast.loc * string ->
    Ast.expr option ->
    Types.typ option * Types.mode option ->
    Typed_tree.typed_expr

  val convert_match :
    Env.t ->
    Ast.loc ->
    Ast.decl_attr ->
    Ast.expr ->
    (Ast.clause * Ast.expr) list ->
    Typed_tree.typed_expr

  val pattern_id :
    int ->
    Ast.pattern ->
    string * Ast.loc * bool (* Is wildcard *) * Ast.decl_attr

  val convert_decl :
    Env.t -> Ast.decl list -> Env.t * (string * typed_expr) list
end

let ctor_name name = String.capitalize_ascii name

let array_assoc_opt name arr =
  let rec inner i =
    if i = Array.length arr then None
    else
      let ctor = arr.(i) in
      if String.equal ctor.cname name then Some ctor else inner (i + 1)
  in
  inner 0

let ctors_of_variant loc path params env =
  let decl, _ = Env.find_type loc path env in
  match decl.kind with
  | Dvariant (_, ctors) ->
      let sub =
        match params with
        | Some inst -> map_params ~inst ~params:decl.params
        | None -> Smap.empty
      in
      let _, ctors =
        Array.fold_left_map
          (fun sub ct ->
            let sub, ctyp =
              match ct.ctyp with
              | Some typ ->
                  let sub, typ = instantiate_sub sub typ in
                  (sub, Some typ)
              | None -> (sub, None)
            in
            (sub, { ct with ctyp }))
          sub ctors
      in
      Ok ctors
  | _ -> Error ()

let get_ctor env loc mode name =
  match Env.find_ctor_opt name mode env with
  | Some { index; typename } ->
      (* We get the ctor type from the variant *)
      let clike, ctor =
        match ctors_of_variant loc typename None env with
        | Ok ctors ->
            let ctor = ctors.(index) in
            ( is_clike_variant ctors,
              { ctor with ctyp = Option.map instantiate ctor.ctyp } )
        | Error () -> failwith "Internal Error: Not a variant"
      in
      Some (typename, clike, ctor)
  | None -> None

let lor_clike_hack env loc name annot =
  (* We allow clike variants in [lor] for the C flags use case *)
  match annot with
  | Some variant -> (
      match repr variant with
      | Tconstr (Path.Pid "int", _, _) -> (
          match get_ctor env loc `Construct name with
          | Some (_, clike, ctor) ->
              if clike then
                let attr = { no_attr with const = true } in
                Some
                  {
                    typ = tint;
                    expr = Const (Int (Int64.of_int ctor.index));
                    attr;
                    loc;
                  }
              else None
          | None -> None)
      | _ -> None)
  | None -> None

let get_variant env loc mode (_, name) annot =
  (* Don't use clean directly, to keep integrity of link *)
  let raise_ t =
    let msg =
      Printf.sprintf "Expecting %s, not a variant type"
        (string_of_type (Env.modpath env) t)
    in
    raise (Error (loc, msg))
  in
  match annot with
  | Some variant -> (
      let find path = Env.find_type_opt loc path env in
      match resolve_alias find variant |> repr with
      (* Builtins are also constructors, but are not variants *)
      | Tconstr (path, params, _) as t when not (is_builtin t) ->
          let ctors =
            match ctors_of_variant loc path (Some params) env with
            | Ok ctors -> ctors
            | Error () -> raise_ t
          in
          let ctor =
            match array_assoc_opt name ctors with
            | Some ctor ->
                Env.construct_ctor_of_variant name path mode env;
                ctor
            | None ->
                let msg =
                  Printf.sprintf "Unbound constructor %s on variant %s"
                    (ctor_name name)
                    Path.(rm_name (Env.modpath env) path |> show)
                in
                raise (Error (loc, msg))
          in
          (path, ctor, variant)
      | t -> raise_ t)
  | None -> (
      (* There is some overlap with [get_ctor] *)
      match Env.find_ctor_opt name mode env with
      | Some { index; typename } ->
          let decl, path = Env.find_type loc typename env in
          let ctors =
            match decl.kind with
            | Dvariant (_, ctors) -> ctors
            | _ -> failwith "Internal Error: Not a variant"
          in
          let ctor = ctors.(index) in
          let typ, ctyp =
            let sub, typ =
              instantiate_sub Smap.empty
                (Tconstr (path, decl.params, decl.contains_alloc))
            in
            let ctyp =
              Option.map (fun t -> instantiate_sub sub t |> snd) ctor.ctyp
            in
            (typ, ctyp)
          in
          (typename, { ctor with ctyp }, typ)
      | None ->
          let msg = "Unbound constructor " ^ ctor_name name in
          raise (Error (loc, msg)))

type guard = (Ast.loc * Ast.expr) option
type attr = Ast.decl_attr = Dmut | Dmove | Dnorm | Dset

type pattern_data = {
  loc : Ast.loc;
  ret_expr : Ast.expr;
  row : int;
  ret_env : Env.t;
  guard : guard;
}

type typed_pattern = { ptyp : typ; pat : tpat }
and pathed_pattern = int list * typed_pattern

and tpat =
  | Tp_ctor of Ast.loc * ctor_param
  | Tp_var of Ast.loc * string * attr
  | Tp_wildcard of Ast.loc
  | Tp_record of Ast.loc * record_field list * attr
  | Tp_int of Ast.loc * int64
  | Tp_char of Ast.loc * char
  | Tp_unit of Ast.loc

and ctor_param = { cindex : int; cpat : pathed_pattern option; ctname : string }

and record_field = {
  floc : Ast.loc;
  name : string;
  index : int;
  iftyp : typ;
  fpat : pathed_pattern option;
}

let tuple_field_name i = "<" ^ string_of_int i ^ ">"

let loc_of_pat = function
  | Tp_wildcard loc
  | Tp_var (loc, _, _)
  | Tp_record (loc, _, _)
  | Tp_ctor (loc, _)
  | Tp_int (loc, _)
  | Tp_char (loc, _)
  | Tp_unit loc ->
      loc

module Tup = struct
  (* Here, we decide which part of which clause to check first. We compile the
     pattern matches assuming no duplicate clauses. If there are no duplicates,
     there is a clear path to choose, see
     https://julesjacobs.com/notes/patternmatching/patternmatching.pdf *)

  type payload = {
    path : int list;
        (* Records need a path instead of just a column. {:a} in 1st column might be [0;0] *)
    loc : Ast.loc;
    d : pattern_data;
    patterns : pathed_pattern list;
    pltyp : typ;
  }

  type ret =
    | Var of payload * string * Ast.decl_attr
    | Ctor of payload * ctor_param
    | Lit_int of payload * int64
    | Lit_char of payload * char
    | Bare of pattern_data
    | Record of record_field list * payload * Ast.decl_attr

  let choose_column ctors tl =
    (* Count wildcards and vars per column. They lead to duplicated branches *)
    (* TODO special handling for record pattern. This needs to be destructored
       and the wildcards and vars counted *)
    let dummy_loc = (Lexing.dummy_pos, Lexing.dummy_pos) in
    let dummy_pattern = { ptyp = tunit; pat = Tp_wildcard dummy_loc } in
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
          1 (* Records have highest prio, as they get destructored *)
      | Tp_ctor _ -> 3
      | Tp_int _ | Tp_char _ -> 3
      | Tp_var _ -> 2
      | Tp_wildcard _ | Tp_unit _ ->
          failwith "Internal Error: Should have been dropped"
    in
    let sort_patterns a b = Int.compare (score_patterns a) (score_patterns b) in
    let filter_patterns p =
      match (snd p).pat with Tp_wildcard _ | Tp_unit _ -> false | _ -> true
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
        | _ -> failwith "Internal Error: Not an char pattern")
    | (path, { pat = Tp_var (loc, name, dattr); ptyp }) :: patterns ->
        (* Drop var from patterns list *)
        Var ({ path; loc; d; patterns; pltyp = ptyp }, name, dattr)
    | (_, { pat = Tp_wildcard _ | Tp_unit _; _ }) :: _ ->
        failwith "Internal Error: Unexpected sorted pattern"
    | (path, { pat = Tp_record (loc, fields, dattr); ptyp }) :: patterns ->
        (* Drop record from patterns list *)
        Record (fields, { path; loc; d; patterns; pltyp = ptyp }, dattr)
    | [] -> Bare d
end

module Exhaustiveness = struct
  module Set = Set.Make (String)

  type wip_kind = New_column | Specialization
  type exhaustive = Exh | Wip of wip_kind * (typed_pattern list * guard) list
  type ctorset = Ctors of ctor list | Inf | Record of field list

  let ctorset_of_variant loc env typ =
    match repr typ with
    | Tconstr (path, inst, _) -> (
        match Env.find_type_opt loc path env with
        | Some (decl, _) -> (
            let sub = map_params ~inst ~params:decl.params in
            match decl.kind with
            | Drecord (_, fields) ->
                Record
                  (Array.to_list fields
                  |> List.map (fun f ->
                         let _, ftyp = instantiate_sub sub f.ftyp in
                         { f with ftyp }))
            | Dvariant (_, ctors) ->
                Ctors
                  (Array.to_list ctors
                  |> List.map (fun ct ->
                         let ctyp =
                           match ct.ctyp with
                           | Some typ -> Some (instantiate_sub sub typ |> snd)
                           | None -> None
                         in
                         { ct with ctyp }))
            | Dabstract _ | Dalias _ -> Inf)
        | None -> Inf)
    | Ttuple ts ->
        Record
          (List.mapi
             (fun i ftyp -> { fname = tuple_field_name i; ftyp; mut = false })
             ts)
    | _ -> Inf

  (* [pattern] has a complete signature on first column *)
  type signature =
    | Complete of ctor list
    | Missing of string list
    | Infi
    | Maybe_red of Ast.loc * ctor list
    | Expand_record of field list
    | Empty

  (** Check if ctorset is complete or some ctor is missing. Might also be
      infinite *)
  let sig_complete env fstcl patterns =
    match List.(hd patterns) with
    | [], _ -> Empty
    | p :: _, _ -> (
        let typ = p.ptyp and loc = loc_of_pat p.pat in
        match ctorset_of_variant loc env typ with
        | Ctors ctors ->
            let set =
              ctors |> List.map (fun ctor -> ctor.cname) |> Set.of_list
            in

            let rec fold f lwild last acc = function
              (* Special case if the last case is a wildcard. Here, we might have a complete
                 ctor set before and the wildcard is redundant *)
              | [] -> last acc
              | [ ({ pat = Tp_wildcard loc; _ } :: _, _) ] -> lwild loc acc
              | hd :: tl -> fold f lwild last (f acc hd) tl
            in
            let f set = function
              | { pat = Tp_ctor (_, p); _ } :: _, guard -> (
                  match guard with
                  | Some _ -> set
                  | None -> Set.remove p.ctname set (* TODO wildcard *))
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
                else
                  f set ([ { pat = Tp_wildcard loc; ptyp = typ } ], None)
                  |> last
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
          | { pat = Tp_ctor _ | Tp_int _ | Tp_char _; _ } :: _, _ ->
              (* Drop row *)
              rows_empty := false;
              None
          | ( { pat = Tp_wildcard _ | Tp_var _ | Tp_unit _ | Tp_record _; _ }
              :: tl,
              guard ) ->
              (* Discard head element *)
              new_col := true;
              rows_empty := false;
              Some (tl, guard)
          | [], guard -> (* Empty row *) Some ([], guard))
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
          | p :: tl, (Some _ as guard) ->
              (* Pattern guard *)
              rows_empty := false;
              new_col := true;
              let loc = loc_of_pat p.pat in
              (* Each pattern guard is identified by the index of its row TODO *)
              Some ({ pat = Tp_int (loc, 0L); ptyp = tint } :: p :: tl, guard)
          | { pat = Tp_ctor (_, param); _ } :: tl, guard
            when String.equal param.ctname case ->
              rows_empty := false;
              let lst =
                match args_to_list param with
                | [] ->
                    new_col := true;
                    tl
                | lst -> lst @ tl
              in
              Some (lst, guard)
          | { pat = Tp_ctor _; _ } :: _, _ ->
              (* Drop row *)
              rows_empty := false;
              None
          | { pat; ptyp } :: tl, guard ->
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
              Some (lst, guard)
          | [], guard -> (* Empty row *) Some ([], guard))
        patterns
    in

    let new_col = if !new_col then New_column else Specialization in
    if !rows_empty then Exh else Wip (new_col, patterns)

  let keep_new_col kind (other, str) =
    match (kind, other) with
    | New_column, _ | _, New_column -> (New_column, str)
    | Specialization, Specialization -> (Specialization, str)

  (* We add an extra redundancy check for first column *)
  let rec is_exhaustive env fstcl (patterns : (typed_pattern list * guard) list)
      : (unit, wip_kind * string list) result =
    match patterns with
    | [] -> Error (Specialization, [])
    | patterns -> (
        match sig_complete env fstcl patterns with
        | Empty -> Ok ()
        | Maybe_red (loc, ctors) -> maybe_red env loc patterns ctors
        | Complete ctors -> complete_sig env fstcl patterns ctors
        | Missing ctors -> (
            match default patterns with
            | Exh -> Ok ()
            | Wip (kind, patterns) -> (
                (* The default matrix only removes ctors and does not add
                   temporary ones. So we can continue with exprstl *)
                match is_exhaustive env false patterns with
                | Ok () -> Ok ()
                | Error _ -> Error (kind, ctors)))
        | Expand_record fields -> expand_record env fields patterns
        | Infi -> (
            match default patterns with
            | Exh -> Ok ()
            | Wip (kind, patterns) ->
                is_exhaustive env false patterns
                |> Result.map_error (keep_new_col kind)))

  and complete_sig env fstcl patterns ctors =
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
                  if num = 1 then is_exhaustive env fstcl patterns
                  else is_exhaustive env false patterns
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
        | New_column -> (
            match strs with
            | [] -> [ ctor_name ctor ]
            | strs ->
                List.map
                  (fun str ->
                    Printf.sprintf "%s, %s" (ctor_name ctor) (ctor_name str))
                  strs)
        | Specialization -> (
            match strs with
            | [] -> [ ctor_name ctor ]
            | strs ->
                List.map
                  (fun str ->
                    Printf.sprintf "%s(%s)" (ctor_name ctor) (ctor_name str))
                  strs)
      in

      Error (kind, strs)

  and maybe_red env loc patterns ctors =
    (* String last entry (a wildcard) from patterns and see if all is exhaustive
       If so, the wildcard is useless *)
    (* We have to do better here in the future. This works, but is wasteful *)
    let stripped = List.rev patterns |> List.tl |> List.rev in
    match complete_sig env true stripped ctors with
    | Ok () -> raise (Error (loc, "Pattern match case is redundant"))
    | Error _ -> complete_sig env true patterns ctors

  and expand_record env fields patterns =
    (* The pattern in the first column is a record pattern. We replace it by
       the expanded record pattern instead. If there is an actual record pattern
       we can use it as is. Otherwise we fill the fields with wildcards *)
    let wc_field loc ptyp = { pat = Tp_wildcard loc; ptyp } in

    let f = function
      | [], _ -> failwith "Internal Error: There are so empty records"
      | { pat = Tp_record (_, fields, _); _ } :: tl, guard ->
          let fields =
            List.map
              (fun f ->
                match f.fpat with
                | Some p -> snd p
                | None -> wc_field f.floc f.iftyp)
              fields
          in
          (fields @ tl, guard)
      | p :: tl, guard ->
          let fields =
            List.map (fun f -> wc_field (loc_of_pat p.pat) f.ftyp) fields
          in
          (fields @ tl, guard)
    in
    is_exhaustive env false (List.map f patterns)
end

module Make (C : Core) (R : Recs) = struct
  open C
  open R

  let exprval env = Env.def_value env

  module Row = struct
    type t = { loc : Ast.loc; cnt : int }

    let compare a b = Int.compare a.cnt b.cnt
  end

  module Row_set = Set.Make (Row)

  let make_annot t =
    match repr t with
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
    { typ = tbool; expr = cmpexpr; attr = no_attr; loc }

  let mismatch_err loc name ctor arg =
    match (ctor, arg) with
    | None, Some _ ->
        let msg =
          Printf.sprintf
            "The constructor %s expects 0 arguments, but an argument is \
             provided"
            (ctor_name name)
        in
        raise (Error (loc, msg))
    | Some _, None ->
        let msg =
          Printf.sprintf
            "The constructor %s expects arguments, but none are provided"
            (ctor_name name)
        in
        raise (Error (loc, msg))
    | _ -> failwith "Internal Error: Not a mismatch"

  let convert_ctor env loc name arg (annot, _) =
    match lor_clike_hack env loc (snd name) annot with
    | Some expr -> expr
    | None -> (
        let typename, ctor, variant =
          get_variant env loc `Construct name annot
        in
        match (ctor.ctyp, arg) with
        | Some typ, Some expr ->
            let texpr = convert env expr in
            unify
              (loc, "In constructor " ^ ctor_name (snd name) ^ ":")
              typ texpr.typ env;
            let expr = Ctor (Path.get_hd typename, ctor.index, Some texpr)
            and const =
              (* There's a special case for string literals.
                 They will get copied here which makes them not const.
                 NOTE copy in convert_tuple *)
              match texpr.expr with
              | Const (String _) -> false
              | _ -> texpr.attr.const
            in
            let attr = { no_attr with const } in
            { typ = variant; expr; attr; loc }
        | None, None ->
            let expr = Ctor (Path.get_hd typename, ctor.index, None)
            and attr = { no_attr with const = true } in
            { typ = variant; expr; attr; loc }
        | _ -> mismatch_err (fst name) (snd name) ctor.ctyp arg)

  (* We want to be able to reference the exprs in the pattern match without
     regenerating it, so we use a magic identifier *)
  let expr_name is = "__expr" ^ String.concat "_" (List.map string_of_int is)

  let arg_opt ptyp loc = function
    | None -> { pat = Tp_wildcard loc; ptyp }
    | Some p -> snd p

  let calc_index_fields env loc fields t =
    let module Set = Set.Make (String) in
    let mn = Env.modpath env in
    let rfields =
      (match repr t with
      | Tconstr (path, ps, _) -> fields_of_record loc path (Some ps) env
      | _ -> Result.Error ())
      |> function
      | Ok fields -> fields
      | Error () ->
          raise
            (Error
               (loc, "Record pattern has unexpected type " ^ string_of_type mn t))
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
                  "Field %s appears multiple times in record pattern" name
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
        (fun ((loc, name), pat) ->
          let field, index =
            match find_name loc name with
            | Some f -> f
            | None ->
                let msg =
                  Printf.sprintf "Unbound field %s on record %s" name
                    (string_of_type mn t)
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
           "There are missing fields in record pattern, for instance %s" missing
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
    ignore (Env.query_val_opt ~instantiate:Fun.id loc (Path.Pid name) env);
    env

  let path_typ loc env p = Env.(find_val loc (Path.Pid (expr_name p)) env).typ

  let rec type_pattern env (path, pat) =
    (* This function got a little more complicated since we expand or-patterns
       inplace. Because of this, a list must be returned instead of a single pattern *)
    match pat with
    (* Convert pattern into typed patterns. By typechecking the pattern before
       building the decision tree, record patterns (which add new columns) can
       be visited more efficiently *)
    | Ast.Pctor ((loc, name), payload) -> (
        let annot = make_annot (path_typ loc env path) in
        let _, ctor, variant = get_variant env loc `Match (loc, name) annot in
        unify
          (loc, "Variant pattern has unexpected type:")
          (path_typ loc env path) variant env;
        match (ctor.ctyp, payload) with
        | Some typ, Some p ->
            let env =
              add_ignore (expr_name path) { (exprval env) with typ } loc env
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
    | Pvar ((loc, name), dattr) ->
        let ptyp = path_typ loc env path in
        let pat = Tp_var (loc, name, dattr) in
        [ (path, { ptyp; pat }) ]
    | Pwildcard (loc, _) ->
        let ptyp = path_typ loc env path in
        let pat = Tp_wildcard loc in
        [ (path, { ptyp; pat }) ]
    | Ptup (loc, pats, dattr) ->
        let ptyp = path_typ loc env path in
        let pats =
          List.mapi
            (fun i (floc, pat) ->
              let path = i :: path in
              let typ = newvar () in
              let env =
                add_ignore (expr_name path) { (exprval env) with typ } loc env
              in
              let tpats = type_pattern env (path, pat) in
              let fields =
                List.map
                  (fun fpat ->
                    let name = tuple_field_name i
                    and iftyp = typ
                    and fpat = Some fpat in
                    { floc; name; index = i; iftyp; fpat })
                  tpats
              in
              fields)
            pats
        in
        let ts =
          List.map
            (fun p ->
              let p = List.hd p in
              p.iftyp)
            pats
        in
        unify (loc, "Tuple pattern has unexpected type:") ptyp (Ttuple ts) env;
        cartesian_product pats
        |> List.map (fun fields ->
               let pat = Tp_record (loc, fields, dattr) in
               (path, { ptyp; pat }))
    | Precord (loc, pats, dattr) ->
        let labelset = List.map (fun ((_, name), _) -> name) pats in
        let annot = make_annot (path_typ loc env path) in
        let ptyp = get_record_type env loc labelset annot in
        unify
          (loc, "Record pattern has unexpected type:")
          (path_typ loc env path) ptyp env;

        let index_fields = calc_index_fields env loc pats ptyp in
        let fields =
          List.map
            (fun (field, index, floc, name, pat) ->
              let path = index :: path in
              let env =
                add_ignore (expr_name path)
                  { (exprval env) with typ = field.ftyp }
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
               let pat = Tp_record (loc, fields, dattr) in
               (path, { ptyp; pat }))
    | Plit_int (loc, i) ->
        unify
          (loc, "Int pattern has unexpected type:")
          (path_typ loc env path) tint env;
        [ (path, { ptyp = tint; pat = Tp_int (loc, i) }) ]
    | Plit_char (loc, c) ->
        unify
          (loc, "Char pattern has unexpected type:")
          (path_typ loc env path) tu8 env;
        [ (path, { ptyp = tu8; pat = Tp_char (loc, c) }) ]
    | Plit_unit loc ->
        unify
          (loc, "Unit pattern has unexpected type:")
          (path_typ loc env path) tunit env;
        [ (path, { ptyp = tunit; pat = Tp_unit loc }) ]
    | Por (_, pats) ->
        (* Don't add to pattern *)
        let pats = List.map (fun p -> type_pattern env (path, p)) pats in
        cartesian_product pats |> List.concat

  let make_var_expr_fn env loc i = convert_var env loc (Path.Pid (expr_name i))

  let rec convert_match env loc pass expr cases =
    let path = [ 0 ] in
    let env, expr =
      let e = pass_mut_helper env loc pass (fun () -> convert env expr) in
      ( add_ignore (expr_name path)
          { (exprval env) with typ = e.typ; mut = e.attr.mut }
          loc env,
        e )
    in

    let ret = newvar () in

    let exp_rows = ref 0 in
    (* expanded rows *)
    let used_rows = ref Row_set.empty in
    let typed_cases =
      List.map
        (fun ({ Ast.cloc = _; cpath; cpat = p; guard }, ret_expr) ->
          let env =
            match cpath with
            | Some path -> Env.use_module env loc path
            | None -> env
          in
          type_pattern env ([ 0 ], p)
          |> List.map (fun pat ->
                 incr exp_rows;
                 let loc = loc_of_pat (snd pat).pat in
                 used_rows :=
                   Row_set.add Row.{ loc; cnt = !exp_rows } !used_rows;
                 ( [ pat ],
                   { loc; ret_expr; row = !exp_rows; ret_env = env; guard } )))
        cases
    in
    let typed_cases = List.concat typed_cases in

    let cont =
      compile_matches env loc used_rows typed_cases ret expr.attr.mut pass
    in

    (* Check for exhaustiveness *)
    (let patterns =
       List.map
         (fun (pl, pd) -> (List.map (fun p -> snd p) pl, pd.guard))
         typed_cases
     in
     match Exhaustiveness.is_exhaustive env true patterns with
     | Ok () -> ()
     | Error (_, cases) ->
         let msg =
           Printf.sprintf "Pattern match is not exhaustive. Missing cases: %s"
             (String.concat " | " (List.map ctor_name cases))
         in
         raise (Error (loc, msg)));

    (* Find redundant cases *)
    (match Row_set.min_elt_opt !used_rows with
    | None -> ()
    | Some { loc; cnt = _ } ->
        raise (Error (loc, "Pattern match case is redundant")));

    let expr = Bind (expr_name path, expr, cont) in
    { cont with expr }

  and compile_matches env all_loc used_rows cases ret_typ rmut pass =
    (* We build the decision tree here. [match_cases] splits cases into ones
       that match and ones that don't. [compile_matches] then generates the tree
       for the cases. This boils down to a chain of if-then-else exprs. A
       heuristic for choosing the ctor to check first in a case is part of
       [Tup.choose_next]. *)

    (* Magic value, see above *)
    let expr i loc = make_var_expr_fn env loc i in

    let ctorenv env ctor i loc =
      match ctor with
      | Some p ->
          let oexpr = expr i loc in
          let typ = (snd p).ptyp and expr = Variant_data oexpr in
          let data = { typ; expr; attr = oexpr.attr; loc } in
          let env =
            add_ignore (expr_name i)
              { (exprval env) with typ = data.typ }
              loc env
          in
          (data, env)
      | None -> (expr i loc, env)
    in

    match cases with
    | hd :: tl -> (
        match Tup.choose_next hd tl with
        | Bare d -> (
            (* Mark row as used *)
            used_rows := Row_set.remove { cnt = d.row; loc = d.loc } !used_rows;

            (* If there is a pattern guard, there are multiple paths with the
               same checks we have just done. The already checked ctors are part
               of [tl]. If we don't match the guard, we can continue with the
               unguarded cases in [tl] (or with additional guards). *)
            match d.guard with
            | Some (loc, guard) ->
                let then_ = convert d.ret_env d.ret_expr in
                unify
                  (d.loc, "Match expression does not match:")
                  ret_typ then_.typ env;

                let else_ =
                  compile_matches env d.loc used_rows tl ret_typ rmut pass
                in
                let cond = convert d.ret_env guard in
                unify (loc, "In pattern guard") tbool cond.typ d.ret_env;
                let expr = If (cond, None, then_, else_) in
                { typ = ret_typ; expr; attr = no_attr; loc }
            | None ->
                let ret = convert d.ret_env d.ret_expr in
                unify
                  (d.loc, "Match expression does not match:")
                  ret_typ ret.typ env;
                ret)
        | Var ({ path; loc; d; patterns; pltyp }, id, dattr) ->
            (* Bind the variable *)
            let lmut = mut_of_pattr dattr in
            let ret_env =
              Env.(
                add_value id
                  (* The value here is not a function parameter. But like a parameter,
                     it needs to be captured in closures and cannot be called directly,
                     because it might be a record field. Marking it param works fine
                     in this case *)
                  { (def_value env) with typ = pltyp; param = true; mut = lmut }
                  loc d.ret_env)
            in
            (* Continue with expression *)
            let d = { d with ret_env } in
            let cont =
              compile_matches env loc used_rows ((patterns, d) :: tl) ret_typ
                rmut pass
            in

            let rhs = expr path loc in
            let rhs = { rhs with attr = { rhs.attr with mut = rmut } } in
            (* If the value we pattern match on is mutable, we have to mentio this
               here in order to increase rc correctly. Otherwise, we had reference semantics*)
            let id_loc = loc
            and uniq = None
            and mode = Many
            and borrow_app = false in
            let expr =
              Let { id; id_loc; uniq; lmut; pass; rhs; cont; mode; borrow_app }
            in
            { typ = cont.typ; expr; attr = cont.attr; loc }
        | Ctor ({ path; loc; d; patterns; pltyp = _ }, param) ->
            let a, b =
              match_cases (path, param.ctname) ((patterns, d) :: tl) [] []
            in

            let data, ifenv = ctorenv env param.cpat path loc in
            let cont =
              compile_matches ifenv d.loc used_rows a ret_typ rmut pass
            in
            (* Make expr available in codegen *)
            let ifexpr =
              let id = expr_name path in
              Bind (id, data, cont)
            in

            (* This is either an if-then-else or just an one ctor,
               depending on whether [b] is empty *)
            let expr =
              match b with
              | [] -> ifexpr
              | b ->
                  let index =
                    let expr = Variant_index (expr path loc) in
                    { typ = ti32; expr; attr = no_attr; loc }
                  in
                  let cind =
                    let attr = { no_attr with const = true } in
                    { typ = ti32; expr = Const (I32 param.cindex); attr; loc }
                  in
                  let cmp = gen_cmp loc index cind in
                  let if_ = { cont with expr = ifexpr } in
                  let else_ =
                    compile_matches env d.loc used_rows b ret_typ rmut pass
                  in
                  If (cmp, None, if_, else_)
            in

            { typ = ret_typ; expr; attr = no_attr; loc }
        | Lit_int ({ path; d; patterns; loc; _ }, i) ->
            let a, b = match_int (path, i) ((patterns, d) :: tl) [] [] in

            let cont =
              compile_matches env d.loc used_rows a ret_typ rmut pass
            in

            let expr =
              match b with
              | [] -> cont.expr
              | b ->
                  let cind =
                    let attr = { no_attr with const = true } in
                    { typ = tint; expr = Const (Int i); attr; loc }
                  in
                  let cmp = gen_cmp loc (expr path loc) cind in
                  let else_ =
                    compile_matches env d.loc used_rows b ret_typ rmut pass
                  in
                  If (cmp, None, cont, else_)
            in
            { typ = ret_typ; expr; attr = no_attr; loc }
        | Lit_char ({ path; d; patterns; loc; _ }, c) ->
            let a, b = match_char (path, c) ((patterns, d) :: tl) [] [] in

            let cont =
              compile_matches env d.loc used_rows a ret_typ rmut pass
            in

            let expr =
              match b with
              | [] -> cont.expr
              | b ->
                  let cind =
                    let attr = { no_attr with const = true } in
                    { typ = tu8; expr = Const (U8 c); attr; loc }
                  in
                  (* i64 and u8 equal compare call the same llvm functions *)
                  let cmp = gen_cmp loc (expr path loc) cind in
                  let else_ =
                    compile_matches env d.loc used_rows b ret_typ rmut pass
                  in
                  If (cmp, None, cont, else_)
            in
            { typ = ret_typ; expr; attr = no_attr; loc }
        | Record (fields, { path; loc; d; patterns; _ }, dattr) ->
            let mut = mut_of_pattr dattr in
            let env =
              List.fold_left
                (fun env field ->
                  let col = field.index :: path in
                  add_ignore (expr_name col)
                    { (exprval env) with typ = field.iftyp; mut }
                    loc env)
                env fields
            in

            (* Since we have all neccessary data in place, we do this row here *)
            let patterns = expand_record path fields patterns in
            (* Expand in all rows down from here. Replace record pattern with expanded fields *)
            let tl = expand_records path tl [] in

            let ret =
              compile_matches env loc used_rows ((patterns, d) :: tl) ret_typ
                rmut pass
            in
            let expr =
              List.fold_left
                (fun cont { index; iftyp; name; _ } ->
                  let newcol = index :: path in
                  let expr = Field (expr path loc, index, name) in
                  let expr = { typ = iftyp; expr; attr = no_attr; loc } in

                  let expr =
                    let id = expr_name newcol in
                    Bind (id, expr, cont)
                  in
                  { cont with expr })
                ret fields
            in
            expr)
    | [] ->
        (* This can happen if there are pattern guards and the fallback case is
           missing. Generate some expression and let it fail later in the
           redundancy check. *)
        { typ = ret_typ; expr = Const Unit; attr = no_attr; loc = all_loc }

  and match_cases (i, case) cases if_ else_ =
    (* The result of match cases are two pattern lists. The first one will
       contain remaining clauses if the pattern was matched. The remaining
       clauses will have specialized the current check so that we don't have to
       check the same pattern multiple times. E.g. if we match Some(1) in one
       clause and Some(2) in the next, the remaining list will now contain only
       Int(1) and Int(2). The second pattern list will contain the "else" case
       where we haven't matched Some (in this example). *)
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
        | Some { pat = Tp_ctor _ | Tp_record _ | Tp_int _ | Tp_char _; _ } ->
            (* We found a ctor, but it does not match. Add to [else_].
               This works for record patterns as well. We are searching for a ctor,
               a record is surely not the ctor we are searching for *)
            match_cases (i, case) tl if_ ((clauses, d) :: else_)
        | Some { pat = Tp_var _ | Tp_wildcard _ | Tp_unit _; _ } | None ->
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
        | Some { pat = Tp_int (_, i); _ } when Int64.equal int i ->
            let clauses = assoc_remove path clauses in
            match_int (path, int) tl ((clauses, d) :: if_) else_
        | Some { pat = Tp_ctor _ | Tp_record _ | Tp_int _ | Tp_char _; _ } ->
            match_int (path, int) tl if_ ((clauses, d) :: else_)
        | Some { pat = Tp_var _ | Tp_wildcard _ | Tp_unit _; _ } | None ->
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
        | Some { pat = Tp_ctor _ | Tp_record _ | Tp_int _ | Tp_char _; _ } ->
            match_char (path, char) tl if_ ((clauses, d) :: else_)
        | Some { pat = Tp_var _ | Tp_wildcard _ | Tp_unit _; _ } | None ->
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
          | None -> { ptyp = iftyp; pat = Tp_var (floc, name, Dnorm) }
        in
        (col, pat) :: pats)
      patterns fields

  and expand_records path patterns expanded =
    match patterns with
    | (patterns, d) :: tl -> (
        match List.assoc_opt path patterns with
        | Some { pat = Tp_record (_, fields, _); _ } ->
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

  let pattern_id i = function
    | Ast.Pvar ((loc, id), dattr) -> (id, loc, false, dattr)
    | Plit_unit loc -> (expr_name [ i ], loc, true, Ast.Dnorm)
    | Ptup (loc, _, dattr) | Precord (loc, _, dattr) ->
        (expr_name [ i ], loc, true, dattr)
    | Pwildcard (loc, dattr) -> (expr_name [ i ], loc, true, dattr)
    | Pctor ((loc, _), _) | Plit_int (loc, _) | Plit_char (loc, _) | Por (loc, _)
      ->
        raise (Error (loc, "Unexpected pattern in declaration"))

  (* Magic value, see above *)
  let expr env i loc = make_var_expr_fn env loc i

  let bind_pattern env loc i p =
    let typed = type_pattern env ([ i ], p) in
    let pts = List.map snd typed in
    (match Exhaustiveness.is_exhaustive env true [ (pts, None) ] with
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
          | Tp_record (loc, fields, dattr) ->
              let env, nbinds =
                (match dattr with
                | Dnorm | Dmove -> ()
                | Dset | Dmut ->
                    raise (Error (loc, "Mutation not supported here yet")));
                let mut = mut_of_pattr dattr in
                List.fold_left_map
                  (fun env f ->
                    let col = f.index :: path in

                    let expr = Field (expr env path f.floc, f.index, f.name)
                    and attr = { no_attr with mut } in
                    let expr = { typ = f.iftyp; expr; attr; loc = f.floc } in
                    let id = expr_name col in

                    ( add_ignore (expr_name col)
                        { (exprval env) with typ = f.iftyp; mut }
                        loc env,
                      (id, expr) ))
                  env fields
              in
              let pats = expand_record path fields tl in
              loop (env, nbinds @ binds) pats
          | Tp_var (loc, id, dattr) ->
              (match dattr with
              | Dnorm -> ()
              | Dset | Dmut | Dmove ->
                  raise (Error (loc, "Mutation not supported here yet")));
              let env =
                Env.(
                  add_value id
                    { (def_value env) with typ = pat.ptyp; param = true }
                    loc env)
              in
              loop (env, (id, expr env path loc) :: binds) tl
          | Tp_wildcard _ | Tp_unit _ -> loop (env, binds) tl
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
      | Pwildcard (loc, _) | Plit_unit loc ->
          (* expr_name was added before to env in [handle_param].
             Make sure it's marked as used *)
          ignore
            (Env.query_val_opt ~instantiate:Fun.id loc
               (Path.Pid (expr_name [ i ]))
               env);
          (env, i + 1, ret)
      | (Ptup (loc, _, _) | Precord (loc, _, _)) as p ->
          let env, binds = bind_pattern env loc i p in
          (env, i + 1, binds @ ret)
      | Pctor ((loc, _), _)
      | Plit_int (loc, _)
      | Plit_char (loc, _)
      | Por (loc, _) ->
          raise (Error (loc, "Unexpected pattern in declaration"))
    in

    let env, _, binds = List.fold_left f (env, 0, []) pats in
    (env, binds)
end
