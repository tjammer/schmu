open Types
open Typed_tree
open Inference
open Error

type msg_fn = string -> Ast.loc -> string -> string

module Strset = Set.Make (String)

module Str = struct
  type t = string

  let hash = Hashtbl.hash
  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)
module Smap = Types.Smap
module Set = Set.Make (String)
module Recs = Records
module Pm = Patternmatching

(*
   Module state
 *)

let fmt_msg_fn : msg_fn option ref = ref None
let uniq_tbl = ref (Strtbl.create 64)

let uniq_name name =
  match Strtbl.find_opt !uniq_tbl name with
  | None ->
      Strtbl.add !uniq_tbl name 1;
      None
  | Some n ->
      Strtbl.replace !uniq_tbl name (n + 1);
      Some (n + 1)

let lambda_id_state = ref 0
let reset state = state := 0

let lambda_id () =
  let id = !lambda_id_state in
  incr lambda_id_state;
  id

let reset_type_vars () =
  Inference.reset ();
  reset lambda_id_state;
  (* Not a type var, but needs resetting as well *)
  Strtbl.clear !uniq_tbl;
  Module.clear_cache ()

let last_loc = ref (Lexing.dummy_pos, Lexing.dummy_pos)

(*
  Helper functions
*)

let check_annot env loc l r =
  let mn = Env.modpath env in
  let subst, b = Inference.types_match Smap.empty l r in
  if b then ()
  else
    let msg =
      Printf.sprintf "Var annotation: Expected type %s but got type %s"
        (string_of_type_lit r mn)
        (string_of_type_subst subst l mn)
    in
    raise (Error (loc, msg))

let main_path = Path.Pid "schmu"
let is_module = function Path.Pid "schmu" -> false | Pid _ | Pmod _ -> true

let check_unused env = function
  | Ok () -> ()
  | Error errors ->
      let err (name, kind, loc) =
        let warn_kind =
          match kind with
          | Env.Unused -> "Unused binding "
          | Unmutated -> "Unmutated mutable binding "
          | Unused_mod -> "Unused module open "
        in
        (Option.get !fmt_msg_fn) "warning" loc
          (warn_kind ^ Path.(rm_name (Env.modpath env) name |> show))
        |> print_endline
      in
      List.iter err errors

let string_of_bop = function
  | Ast.Plus_i -> "+"
  | Mult_i -> "*"
  | Div_i -> "/"
  | Less_i -> "<"
  | Greater_i -> ">"
  | Less_eq_i -> "<="
  | Greater_eq_i -> ">="
  | Equal_i -> ""
  | Minus_i -> "-"
  | Ast.Plus_f -> "+."
  | Mult_f -> "*."
  | Div_f -> ">."
  | Less_f -> "<."
  | Greater_f -> ">."
  | Less_eq_f -> "<=."
  | Greater_eq_f -> ">=."
  | Equal_f -> "=."
  | Minus_f -> "-."
  | And -> "and"
  | Or -> "or"

let rec subst_generic ~id typ = function
  (* Substitute generic var [id] with [typ] *)
  | Tvar { contents = Link t } -> subst_generic ~id typ t
  | (Qvar id' | Tvar { contents = Unbound (id', _) }) when String.equal id id'
    ->
      typ
  | Tfun (ps, ret, kind) ->
      let ps =
        List.map
          (fun p ->
            let pt = subst_generic ~id typ p.pt in
            { p with pt })
          ps
      in
      let ret = subst_generic ~id typ ret in
      Tfun (ps, ret, kind)
  | Trecord (ps, name, labels) ->
      let ps = List.map (subst_generic ~id typ) ps in
      let f f = Types.{ f with ftyp = subst_generic ~id typ f.ftyp } in
      let labels = Array.map f labels in
      Trecord (ps, name, labels)
  | Tvariant (ps, name, ctors) ->
      let ps = List.map (subst_generic ~id typ) ps in
      let f c =
        Types.{ c with ctyp = Option.map (subst_generic ~id typ) c.ctyp }
      in
      let ctors = Array.map f ctors in
      Tvariant (ps, name, ctors)
  | Tabstract (ps, name, t) ->
      let ps = List.map (subst_generic ~id typ) ps in
      let t = subst_generic ~id typ t in
      Tabstract (ps, name, t)
  | Traw_ptr t -> Traw_ptr (subst_generic ~id typ t)
  | Tarray t -> Tarray (subst_generic ~id typ t)
  | Talias (name, t) -> Talias (name, subst_generic ~id typ t)
  | t -> t

and get_generic_ids = function
  | Qvar id | Tvar { contents = Unbound (id, _) } -> [ id ]
  | Tvar { contents = Link t } | Talias (_, t) -> get_generic_ids t
  | Trecord (ps, _, _) | Tvariant (ps, _, _) | Tabstract (ps, _, _) ->
      List.map get_generic_ids ps |> List.concat
  | Tarray t | Traw_ptr t -> get_generic_ids t
  | _ -> []

let typeof_annot ?(typedef = false) ?(param = false) env loc annot =
  let fn_kind = if param then Closure [] else Simple in

  let find env t tick =
    match Env.find_type_opt loc t env with
    | Some t -> fst t
    | None ->
        raise
          (Error
             ( loc,
               "Unbound type " ^ tick
               ^ Path.(rm_name (Env.modpath env) t |> show)
               ^ "." ))
  in

  let rec is_quantified = function
    | Trecord ([], _, _) | Tvariant ([], _, _) -> None
    | Trecord (ts, Some name, _)
    | Tvariant (ts, name, _)
    | Tabstract (ts, name, _) ->
        Some (name, List.length ts)
    | Traw_ptr _ -> Some (Path.Pid "raw_ptr", 1)
    | Tarray _ -> Some (Path.Pid "array", 1)
    | Talias (name, t) -> (
        let cleaned = clean t in
        match is_quantified cleaned with
        | Some (_, n) when is_polymorphic cleaned -> Some (name, n)
        | Some _ | None -> (* When can alias a concrete type *) None)
    | Tvar { contents = Link t } -> is_quantified t
    | _ -> None
  in

  let rec concrete_type in_list env = function
    | Ast.Ty_id "int" -> Tint
    | Ty_id "bool" -> Tbool
    | Ty_id "unit" -> Tunit
    | Ty_id "u8" -> Tu8
    | Ty_id "float" -> Tfloat
    | Ty_id "i32" -> Ti32
    | Ty_id "f32" -> Tf32
    | Ty_id "array" ->
        if not in_list then
          raise (Error (loc, "Type array expects 1 type parameter"));
        Tarray (Qvar "o")
        (* Use a letter care so we don't clash with a real value *)
    | Ty_id "raw_ptr" ->
        if not in_list then
          raise (Error (loc, "Type raw_ptr expects 1 type parameter"));
        Traw_ptr (Qvar "o")
    | Ty_id t ->
        let t = find env (Path.Pid t) "" in
        (if not in_list then
           match is_quantified t with
           | Some (name, n) ->
               let msg =
                 Printf.sprintf "Type %s expects %i type parameter%s"
                   Path.(rm_name (Env.modpath env) name |> show)
                   n
                   (if n > 1 then "s" else "")
               in
               raise (Error (loc, msg))
           | None -> ());
        t
    | Ty_var id when typedef -> find env (Path.Pid id) "'"
    | Ty_var id ->
        (* Type annotation in function *)
        Qvar id
    | Ty_func l -> handle_func env l
    | Ty_list l -> type_list env l
    | Ty_open_id (_, path) -> find env path ""
    | Ty_tuple ts ->
        let fields =
          List.mapi
            (fun i t ->
              let fname = string_of_int i in
              let ftyp = concrete_type false env t in
              { fname; ftyp; mut = false })
            ts
        in
        Trecord ([], None, Array.of_list fields)
  and type_list env = function
    | [] -> failwith "Internal Error: Type param list should not be empty"
    | t :: tl -> (
        let t = concrete_type true env t in
        match is_quantified t with
        | Some (name, n) -> (
            try
              match get_generic_ids t with
              | [] ->
                  let msg =
                    "Expected a parametrized type, not "
                    ^ string_of_type t (Env.modpath env)
                  in
                  raise (Error (loc, msg))
              | l ->
                  List.fold_left2
                    (fun parent child id ->
                      let t = concrete_type false env child in
                      subst_generic ~id t parent)
                    t tl l
            with Invalid_argument _ ->
              let msg =
                Printf.sprintf "Type %s expects %i type parameter%s"
                  Path.(rm_name (Env.modpath env) name |> show)
                  n
                  (if n > 1 then "s" else "")
              in
              raise (Error (loc, msg)))
        | None -> failwith "Internal Error: Not sure, this shouldn't happen")
  and handle_func env = function
    | [] -> failwith "Internal Error: Type annot list should not be empty"
    | [ (t, _) ] -> concrete_type false env t
    | [ (Ast.Ty_id "unit", _); (t, _) ] ->
        Tfun ([], concrete_type false env t, fn_kind)
    | [ (Ast.Ty_list [ Ast.Ty_id "unit" ], _); (t, _) ] ->
        Tfun ([], concrete_type false env t, fn_kind)
    (* For function definiton and application, 'unit' means an empty list.
       It's easier for typing and codegen to treat unit as a special case here *)
    | l -> (
        (* We reverse the list times :( *)
        match List.rev l with
        | (last, _) :: head ->
            Tfun
              ( List.map
                  (fun (s, pattr) -> { pt = concrete_type false env s; pattr })
                  (List.rev head),
                concrete_type false env last,
                fn_kind )
        | [] -> failwith ":)")
  in
  concrete_type false env annot

let rec param_annots t =
  let annot t =
    match clean t with
    | Qvar _ | Tvar { contents = Unbound _ } -> None
    | _ -> Some t
  in
  (* We don't clean here, because it might mess with links *)
  match t with
  | Talias (_, t) | Tvar { contents = Link t } -> param_annots t
  | Qvar _ | Tvar { contents = Unbound _ } -> [||]
  | Tfun (typs, _, _) -> List.map (fun p -> annot p.pt) typs |> Array.of_list
  | _ -> [||]

let param_annot annots i =
  if Array.length annots > i then Array.get annots i else None

let handle_params env loc (params : Ast.decl list) pattern_id ret =
  (* return updated env with bindings for parameters and types of parameters *)
  let rec handle = function
    | Qvar _ as t -> (newvar (), t)
    | Tfun (params, ret, kind) ->
        let params, qparams =
          List.map
            (fun p ->
              let a, b = handle p.pt in
              ({ p with pt = a }, { p with pt = b }))
            params
          |> List.split
        in
        let ret, qret = handle ret in
        (Tfun (params, ret, kind), Tfun (qparams, qret, kind))
    | t -> (t, t)
  in

  List.fold_left_map
    (fun (env, i) { Ast.loc; pattern; dattr; annot } ->
      let id, idloc = pattern_id i pattern in
      let type_id, qparams =
        match annot with
        | None ->
            let t = newvar () in
            (t, t)
        | Some annot ->
            let t, q = handle (typeof_annot ~param:true env loc annot) in
            (instantiate t, q)
      in
      (* Might be const, but not important here *)
      ( ( Env.add_value id
            {
              typ = type_id;
              const = false;
              param = true;
              global = false;
              mut = mut_of_pattr dattr;
            }
            idloc env,
          i + 1 ),
        ({ pt = type_id; pattr = dattr }, { pt = qparams; pattr = dattr }) ))
    (env, 0) params
  |> fun ((env, _), lst) ->
  let ids, qparams = List.split lst in
  let ret = Option.map (fun t -> typeof_annot env loc t) ret in
  (env, ids, qparams, ret)

let check_type_unique env loc ~in_sig name typ =
  match Env.find_type_same_module name env with
  (* It's ok to have a type both in signature and impl *)
  | Some (_, insig) when Bool.equal in_sig insig ->
      let msg =
        Printf.sprintf
          "Type names in a module must be unique. %s exists already" name
      in
      raise (Error (loc, msg))
  | Some (Tabstract (ps, _, Tvar ({ contents = Unbound _ } as t)), _) ->
      assert (not in_sig);
      (* We have a concrete implemantion of an abstract type. Change the abstract one to carry its impl *)
      (* Also adjust type params to match between abstract type and carried type *)
      let typ = match_type_params loc ps typ in
      t := Link typ;
      typ
  | Some _ | None -> typ

let make_type_param () =
  enter_level ();
  let typ = newvar () in
  leave_level ();
  generalize typ

let add_type_param env ts =
  List.fold_left_map
    (fun env name ->
      (* Create general type *)
      let t = make_type_param () in

      (Env.add_type name ~in_sig:false t env, t))
    env ts

let type_record env loc ~in_sig Ast.{ name = { poly_param; name }; labels } =
  let record = Path.append name (Env.modpath env) in
  let labels, params =
    (* Temporarily add polymorphic type name to env *)
    let env, param = add_type_param env poly_param in
    let labels =
      Array.map
        (fun (mut, fname, type_expr) ->
          let ftyp = typeof_annot ~typedef:true env loc type_expr in
          { fname; ftyp; mut })
        labels
    in
    (labels, param)
  in

  let typ = Trecord (params, Some record, labels) in
  (* Make sure that each type name only appears once per module *)
  let typ = check_type_unique ~in_sig env loc name typ in
  (Env.add_type name ~in_sig typ env, typ)

let type_alias env loc ~in_sig { Ast.poly_param; name } type_spec =
  let alias = Path.append name (Env.modpath env) in
  (* Temporarily add polymorphic type name to env *)
  let temp_env, _ = add_type_param env poly_param in
  let typ = typeof_annot ~typedef:true temp_env loc type_spec in

  let alias = Talias (alias, typ) in
  (* Make sure that each type name only appears once per module *)
  let typ = check_type_unique ~in_sig env loc name alias in
  (Env.add_type name ~in_sig typ env, alias)

let type_abstract env loc { Ast.poly_param; name } =
  let tname = Path.append name (Env.modpath env) in
  (* Make sure that each type name only appears once per module *)
  (* Abstract types are only allowed in signatures *)
  ignore (check_type_unique ~in_sig:true env loc name Tunit);
  (* Tunit because we need to pass some type *)
  (* Temporarily add polymorphic type name to env *)
  let params = List.map (fun _ -> make_type_param ()) poly_param in
  let typ = Tabstract (params, tname, newvar ()) in

  (* TODO make abstract type unbound and bind correct type in impl.
     We can check this with check_type_unique *)
  (Env.add_type name ~in_sig:true typ env, typ)

let type_variant env loc ~in_sig { Ast.name = { poly_param; name }; ctors } =
  let variant = Path.append name (Env.modpath env) in
  (* Temporarily add polymorphic type name to env *)
  let temp_env, params = add_type_param env poly_param in

  (* We follow the C way for C-style enums. At the same time, we forbid
     tag clashes for constructors with payload *)
  let next = ref (-1) in
  let indices = Hashtbl.create 32 in
  let nexti ~has_payload loc name =
    incr next;
    match Hashtbl.find_opt indices !next with
    | Some (name, pl) when has_payload || pl ->
        let msg =
          Printf.sprintf "Tag %i already used for constructor %s" !next name
        in
        raise (Error (loc, msg))
    | Some _ | None ->
        Hashtbl.replace indices !next (name, has_payload);
        !next
  in
  let maybe_add_index has_payload loc name = function
    | Some i ->
        (* We set the index to one lower, as it increases on call to [nexti] *)
        next := i - 1;
        nexti ~has_payload loc name
    | None -> nexti ~has_payload loc name
  in

  let ctors =
    List.map
      (fun { Ast.name = loc, cname; typ_annot; index } ->
        match typ_annot with
        | None ->
            (* Just a ctor, without data *)
            {
              cname;
              ctyp = None;
              index = maybe_add_index false loc cname index;
            }
        | Some annot ->
            let typ = typeof_annot ~typedef:true temp_env loc annot in
            {
              cname;
              ctyp = Some typ;
              index = maybe_add_index true loc cname index;
            })
      ctors
    |> Array.of_list
  in

  let typ = Tvariant (params, variant, ctors) in
  (* Make sure that each type name only appears once per module *)
  let typ = check_type_unique ~in_sig env loc name typ in
  (Env.add_type name ~in_sig typ env, typ)

let rec param_funcs_as_closures = function
  (* Functions passed as parameters need to have an empty closure, otherwise they cannot
     be captured (see above). Kind of sucks *)
  | Tvar { contents = Link t } | Talias (_, t) ->
      (* This shouldn't break type inference *) param_funcs_as_closures t
  | Tfun (_, _, Closure _) as t -> t
  | Tfun (params, ret, _) -> Tfun (params, ret, Closure [])
  | t -> t

let convert_simple_lit loc typ expr =
  { typ; expr = Const expr; attr = { no_attr with const = true }; loc }

let rec builtins_hack callee args =
  (* return of __unsafe_ptr_get should be marked mut, otherwise it won't be copied
     correctly later in codegen. *)
  (* NOTE is_temporary is monomorph_tree also needs to be updated *)
  match callee with
  | Ast.Var (_, id) -> (
      match id with
      | "__unsafe_ptr_get" -> { no_attr with mut = true }
      | "array-get" | "array-data" | "array-length" ->
          let mut =
            match args with
            (* We only care about the first arg, ie the array *)
            | (_, _, mut) :: _ -> mut
            | _ -> false
          in
          { no_attr with mut }
      | _ -> no_attr)
  | Let_e (__, _, _, cont) -> builtins_hack cont args
  | _ -> no_attr

let fold_decl cont (id, e) = { cont with expr = Bind (id, e, cont) }

let rec is_poly_call texpr =
  match texpr.expr with
  | Var _ | Const _ | Bop _ | Unop _ | If _ | Lambda _ | Record _ | Field _
  | Set _ | Ctor _ | Variant_index _ | Variant_data _ | Fmt _ ->
      false
  | App _ when is_polymorphic texpr.typ -> (
      match clean texpr.typ with Tfun _ -> true | _ -> false)
  | App _ -> false
  | Let d -> is_poly_call d.cont
  | Bind (_, _, cont)
  | Function (_, _, _, cont)
  | Sequence (_, cont)
  | Mutual_rec_decls (_, cont)
  | Move cont ->
      is_poly_call cont

let rec wrap_in_lambda texpr = function
  | Tfun (tparams, ret, kind) ->
      let func = { tparams; ret; kind; touched = [] } in
      let pn i _ = "_" ^ string_of_int i in
      let nparams = List.mapi pn tparams in
      let args =
        List.mapi
          (fun i p ->
            let mut = mut_of_pattr p.pattr in
            let texpr =
              {
                typ = p.pt;
                expr = Var (pn i 0, None);
                attr = { no_attr with mut };
                loc = texpr.loc;
              }
            in
            (texpr, p.pattr))
          tparams
      in
      let body =
        { texpr with expr = App { callee = texpr; args }; typ = ret }
      in
      let abs = { nparams; body; func; inline = false } in
      { texpr with expr = Lambda (lambda_id (), abs) }
  | Tvar { contents = Link t } -> wrap_in_lambda texpr t
  | _ -> failwith "Internal Error: Not a function for wrapping"

module rec Core : sig
  val convert : Env.t -> Ast.expr -> typed_expr

  val convert_annot :
    Env.t -> Types.typ option -> Ast.expr -> Typed_tree.typed_expr

  val convert_var : Env.t -> Ast.loc -> Path.t -> typed_expr
  val convert_block : ?ret:bool -> Env.t -> Ast.block -> typed_expr * Env.t

  val convert_let :
    global:bool ->
    Env.t ->
    Ast.loc ->
    Ast.decl ->
    Ast.passed_expr ->
    Env.t * string * typed_expr * bool * (string * typed_expr) list

  val convert_function :
    Env.t ->
    Ast.loc ->
    Ast.func ->
    bool ->
    Env.t * (string * int option * abstraction)
end = struct
  open Records
  open Patternmatch

  let string_typ = Talias (Path.Pid "string", Tarray Tu8)

  let rec convert env expr = convert_annot env None expr

  and convert_annot env annot = function
    | Ast.Var (loc, id) -> convert_var env loc (Path.Pid id)
    | Lit (loc, Int i) -> convert_simple_lit loc Tint (Int i)
    | Lit (loc, Bool b) -> convert_simple_lit loc Tbool (Bool b)
    | Lit (loc, U8 c) -> convert_simple_lit loc Tu8 (U8 c)
    | Lit (loc, Float f) -> convert_simple_lit loc Tfloat (Float f)
    | Lit (loc, I32 i) -> convert_simple_lit loc Ti32 (I32 i)
    | Lit (loc, F32 i) -> convert_simple_lit loc Tf32 (F32 i)
    | Lit (loc, String s) ->
        let typ = string_typ in
        (* The string literal itself is const, not handled within the const table *)
        let attr = { no_attr with const = true } in
        { typ; expr = Const (String s); attr; loc }
    | Lit (loc, Array arr) -> convert_array_lit env loc arr
    | Lit (loc, Unit) ->
        let attr = { no_attr with const = true } in
        { typ = Tunit; expr = Const Unit; attr; loc }
    | Lambda (loc, id, e) -> convert_lambda env loc id e
    | Let_e (loc, decl, expr, cont) -> convert_let_e env loc decl expr cont
    | App (loc, e1, e2) -> convert_app ~switch_uni:false env loc e1 e2
    | Bop (loc, bop, es) -> convert_bop env loc bop es
    | Unop (loc, unop, expr) -> convert_unop env loc unop expr
    | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
    | Record (loc, labels) -> convert_record env loc annot labels
    | Tuple (loc, exprs) -> convert_tuple env loc exprs
    | Record_update (loc, record, items) ->
        convert_record_update env loc annot record items
    | Field (loc, expr, id) -> convert_field env loc expr id
    | Set (loc, expr, value) -> convert_set env loc expr value
    | Do_block stmts -> convert_block env stmts |> fst
    | Pipe_head (loc, e1, e2) -> convert_pipe_head env loc e1 e2
    | Pipe_tail (loc, e1, e2) -> convert_pipe_tail env loc e1 e2
    | Ctor (loc, name, args) -> convert_ctor env loc name args annot
    | Match (loc, exprs, cases) -> convert_match env loc exprs cases
    | Local_open (loc, name, expr) ->
        disambiguate_opens env loc (Path.Pid name) expr
    | Fmt (loc, exprs) -> convert_fmt env loc exprs

  and convert_var env loc id =
    match Env.query_val_opt loc id env with
    | Some (t, id) ->
        let typ = instantiate t.typ in
        let attr = { const = t.const; global = t.global; mut = t.mut } in
        { typ; expr = Var (id, t.imported); attr; loc }
    | None ->
        let suff =
          match Env.find_module_opt loc id env with
          | Some _ -> ", but a module with the name exists"
          | None -> ""
        in
        let msg = "No var named " ^ Path.show id ^ suff in
        raise (Error (loc, msg))

  and convert_array_lit env loc arr =
    let f typ expr =
      let expr = convert env expr in
      unify (loc, "In array literal:") typ expr.typ env;
      (typ, expr)
    in
    let typ, exprs = List.fold_left_map f (newvar ()) arr in

    let typ = Tarray typ in
    { typ; expr = Const (Array exprs); attr = no_attr; loc }

  and typeof_annot_decl env loc annot block =
    enter_level ();
    let expr =
      match annot with
      | None ->
          let t = convert env block in
          leave_level ();
          (* We generalize functions, but allow weak variables for value types *)
          let typ =
            match clean t.typ with Tfun _ -> generalize t.typ | _ -> t.typ
          in
          { t with typ }
      | Some annot ->
          let t_annot = typeof_annot env loc annot in
          let t = convert_annot env (Some t_annot) block in
          leave_level ();

          (match clean t.typ with
          | Tfun _ -> check_annot env loc t.typ t_annot
          | _ -> unify (loc, "In let binding:") t.typ t_annot env);

          { t with typ = t_annot }
    in
    if is_poly_call expr then wrap_in_lambda expr expr.typ else expr

  and convert_let ~global env loc (decl : Ast.decl)
      { Ast.pattr = _; pexpr = block } =
    let id, idloc = pattern_id 0 decl.pattern in
    let e1 = typeof_annot_decl env loc decl.annot block in
    let mut = mut_of_pattr decl.dattr in
    let const = e1.attr.const && not mut in
    let env =
      Env.add_value id
        { Env.def_value with typ = e1.typ; const; global; mut }
        idloc env
    in
    let env, pat_exprs = convert_decl env [ decl ] in
    let expr = { e1 with attr = { global; const; mut } } in
    (env, id, expr, e1.attr.mut, pat_exprs)

  and convert_let_e env loc decl expr cont =
    let env, id, rhs, rmut, pats =
      convert_let ~global:false env loc decl expr
    in
    let cont = convert env cont in
    let cont = List.fold_left fold_decl cont pats in
    let uniq = if rhs.attr.const then uniq_name id else None in
    let expr = Let { id; uniq; rmut; pass = expr.pattr; rhs; cont } in
    { typ = cont.typ; expr; attr = cont.attr; loc }

  and convert_lambda env loc params body =
    let env = Env.open_function env in
    enter_level ();
    let env, params_t, qparams, ret_annot =
      handle_params env loc params pattern_id None
    in
    let nparams =
      List.mapi (fun i (d : Ast.decl) -> fst (pattern_id i d.pattern)) params
    in

    let env, param_exprs = convert_decl env params in

    let body = convert_block env body |> fst in
    let body = List.fold_left fold_decl body param_exprs in

    leave_level ();
    let _, closed_vars, touched, unused = Env.close_function env in

    let touched, body =
      Exclusivity.check_tree params_t
        (List.map2 (fun n (d : Ast.decl) -> (n, d.loc)) nparams params)
        touched body
    in

    let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
    check_unused env unused;

    (* For codegen: Mark functions in parameters closures *)
    let params_t =
      List.map (fun p -> { p with pt = param_funcs_as_closures p.pt }) params_t
    in

    let typ = Tfun (params_t, body.typ, kind) in
    match typ with
    | Tfun (tparams, ret, kind) ->
        let ret = match ret_annot with Some ret -> ret | None -> ret in
        let qtyp = Tfun (qparams, ret, kind) in
        check_annot env loc typ qtyp;

        let func = { tparams; ret; kind; touched } in
        let abs =
          { nparams; body = { body with typ = ret }; func; inline = false }
        in
        let expr = Lambda (lambda_id (), abs) in
        { typ; expr; attr = no_attr; loc }
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and convert_function env loc
      Ast.{ name = nameloc, name; params; return_annot; body; attr } inrec =
    (* Create a fresh type var for the function name
       and use it in the function body *)
    let unique = uniq_name name in

    let inline =
      match attr with
      | Some (_, "inline") -> true
      | Some (loc, attr) -> raise (Error (loc, "Unknown attribute: " ^ attr))
      | None -> false
    in

    enter_level ();
    let env =
      if inrec then
        (* Function is already part of env with a fresh variable *)
        env
      else
        (* Recursion allowed for named funcs *)
        let ps =
          List.map (fun p -> Ast.{ pattr = p.dattr; pt = newvar () }) params
        in
        let typ = Tfun (ps, newvar (), Simple) in
        Env.(add_value name { def_value with typ } nameloc env)
    in

    (* We duplicate some lambda code due to naming *)
    let env = Env.open_function env in
    let body_env, params_t, qparams, ret_annot =
      handle_params env loc params pattern_id return_annot
    in
    let nparams =
      List.mapi (fun i (d : Ast.decl) -> fst (pattern_id i d.pattern)) params
    in

    let body_env, param_exprs = convert_decl body_env params in

    let body = convert_block body_env body |> fst in
    (* Add bindings from patterns *)
    let body = List.fold_left fold_decl body param_exprs in
    leave_level ();

    let env, closed_vars, touched, unused = Env.close_function env in

    let touched, body =
      Exclusivity.check_tree params_t
        (List.map2 (fun n (d : Ast.decl) -> (n, d.loc)) nparams params)
        touched body
    in

    let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
    check_unused env unused;

    (* For codegen: Mark functions in parameters closures *)
    let params_t =
      List.map (fun p -> { p with pt = param_funcs_as_closures p.pt }) params_t
    in

    let typ =
      Tfun (params_t, body.typ, kind)
      |>
      (* For mutually recursive functions, we generalize at the end of the rec block.
         Otherwise calls to the not-last function in the set will not work*)
      fun t -> if inrec then t else generalize t
    in

    match typ with
    | Tfun (tparams, ret, kind) ->
        (* Make sure the types match *)
        unify (loc, "Function") (Env.find_val loc (Path.Pid name) env).typ typ
          env;

        (* Add the generalized type to the env to keep the closure there *)
        let env = Env.change_type name typ env in

        let ret = match ret_annot with Some ret -> ret | None -> ret in
        let qtyp = Tfun (qparams, ret, kind) |> generalize in
        check_annot env loc typ qtyp;

        let func = { tparams; ret; kind; touched } in
        let lambda =
          { nparams; body = { body with typ = ret }; func; inline }
        in

        (env, (name, unique, lambda))
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and convert_app ~switch_uni env loc e1 args =
    let callee = convert env e1 in

    let annots = param_annots callee.typ in
    let typed_exprs =
      List.mapi
        (fun i (a : Ast.argument) ->
          let e =
            (match a.apass with
            | Dmut | Dset -> Env.open_mutation env
            | Dnorm | Dmove -> ());
            let e = convert_annot env (param_annot annots i) a.aexpr in
            (match a.apass with
            | Dmut | Dset ->
                Env.close_mutation env;
                if not e.attr.mut then
                  raise
                    (Error (a.aloc, "Mutably passed expression is not mutable"))
            | Dmove | Dnorm -> ());
            e
          in
          (* We also care about whether the argument _can_ be mutable, for array-get *)
          (e, a.apass, e.attr.mut))
        args
    in
    let args_t =
      List.map (fun (a, pattr, _) -> { pattr; pt = a.typ }) typed_exprs
    in
    let res_t = newvar () in
    if switch_uni then
      unify (loc, "Application:") (Tfun (args_t, res_t, Simple)) callee.typ env
    else
      unify (loc, "Application:") callee.typ (Tfun (args_t, res_t, Simple)) env;

    let apply param (texpr, _, _) =
      ({ texpr with typ = param.pt }, param.pattr)
    in
    let targs = List.map2 apply args_t typed_exprs in

    let attr = builtins_hack e1 typed_exprs in

    (* Extract the returning type from the callee, because it's properly
       generalized and linked. This way, everything in a function body
       should be generalized and we can easily catch weak type variables *)
    let typ =
      let rec extract_typ = function
        | Tfun (_, t, _) -> t
        | Talias (_, t) | Tvar { contents = Link t } -> extract_typ t
        | t -> t
      in
      extract_typ callee.typ
    in

    (* For now, we don't support const functions *)
    { typ; expr = App { callee; args = targs }; attr; loc }

  and convert_bop_impl env loc bop e1 e2 =
    let check typ =
      let t1 = convert env e1 in
      let t2 = convert env e2 in

      unify (loc, "Binary " ^ string_of_bop bop) typ t1.typ env;
      unify (loc, "Binary " ^ string_of_bop bop) t1.typ t2.typ env;
      (t1, t2, t1.attr.const && t2.attr.const)
    in

    let typ, (t1, t2, const) =
      match bop with
      | Ast.Plus_i | Mult_i | Minus_i | Div_i -> (Tint, check Tint)
      | Less_i | Equal_i | Greater_i | Less_eq_i | Greater_eq_i ->
          (Tbool, check Tint)
      | Plus_f | Mult_f | Minus_f | Div_f -> (Tfloat, check Tfloat)
      | Less_f | Equal_f | Greater_f | Less_eq_f | Greater_eq_f ->
          (Tbool, check Tfloat)
      | And | Or -> (Tbool, check Tbool)
    in
    { typ; expr = Bop (bop, t1, t2); attr = { no_attr with const }; loc }

  and convert_bop env loc bop es =
    let rec build = function
      | [ _ ] | [] ->
          raise (Error (loc, "Binary operator needs at least two operands"))
      | [ a; b ] -> convert_bop_impl env loc bop a b
      | a :: tl ->
          let tl = build tl in
          { tl with expr = Bop (bop, tl, convert env a) }
    in
    build es

  and convert_unop env loc unop expr =
    match unop with
    | Uminus_f ->
        let e = convert env expr in
        unify (loc, "Unary -.:") Tfloat e.typ env;
        { typ = Tfloat; expr = Unop (unop, e); attr = e.attr; loc }
    | Uminus_i -> (
        let e = convert env expr in
        let msg = "Unary -:" in
        let expr = Unop (unop, e) in

        try
          (* We allow '-' to also work on float expressions *)
          unify (loc, msg) Tfloat e.typ env;
          { typ = Tfloat; expr; attr = e.attr; loc }
        with Error _ -> (
          try
            unify (loc, msg) Tint e.typ env;
            { typ = Tint; expr; attr = e.attr; loc }
          with Error (loc, errmsg) ->
            let pos = String.length msg + String.length ": Expected type int" in
            let post = String.sub errmsg pos (String.length errmsg - pos) in
            raise (Error (loc, "Unary -: Expected types int or float " ^ post)))
        )

  and convert_if env loc cond e1 e2 =
    (* We can assume pred evaluates to bool and both
       branches need to evaluate to the some type *)
    let type_cond = convert env cond in
    unify (loc, "In condition") type_cond.typ Tbool env;
    let type_e1 = convert env e1 in
    let type_e2 =
      (* We unify in the pattern match to have different messages and unification order *)
      match e2 with
      | Some e2 ->
          let msg = "Branches have different type:" in
          let e2 = convert env e2 in
          unify (loc, msg) type_e1.typ e2.typ env;
          e2
      | None ->
          let msg =
            "A conditional without else branch should evaluato to type unit."
          in
          let e2 =
            let attr = { no_attr with const = true } in
            { typ = Tunit; expr = Const Unit; attr; loc }
          in
          unify (loc, msg) e2.typ type_e1.typ env;
          e2
    in

    (* We don't support polymorphic lambdas in if-exprs in the monomorph backend yet *)
    (match type_e2.typ with
    | Tfun (_, _, _) as t when is_polymorphic t ->
        raise
          (Error
             ( loc,
               "Returning polymorphic anonymous function in if expressions is \
                not supported (yet). Sorry. You can type the function \
                concretely though." ))
    | _ -> ());

    (* Would be interesting to evaluate this at compile time,
       but I think it's not that important right now *)
    let attr = { no_attr with mut = type_e1.attr.mut && type_e2.attr.mut } in
    let expr = If (type_cond, None, type_e1, type_e2) in
    { typ = type_e2.typ; expr; attr; loc }

  and pipe_ctor_msg =
    "Constructor already has an argument, cannot pipe a second one"

  and convert_set env loc (eloc, expr) value =
    Env.open_mutation env;
    let toset = convert env expr in
    Env.close_mutation env;
    let valexpr = convert env value in

    (if not toset.attr.mut then
       let msg = Printf.sprintf "Cannot mutate non-mutable binding" in
       raise (Error (eloc, msg)));
    unify (loc, "Mutate:") toset.typ valexpr.typ env;
    { typ = Tunit; expr = Set (toset, valexpr); attr = no_attr; loc }

  and convert_pipe_head env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | Pip_expr (App (loc, callee, args)) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (e1 :: args)
    | Pip_expr (Ctor (loc, name, expr)) ->
        if Option.is_some expr then raise (Error (loc, pipe_ctor_msg));
        convert_ctor env loc name (Some e1.aexpr) None
    | Pip_expr (Bop (loc, op, exprs)) ->
        convert_bop env loc op (e1.aexpr :: exprs)
    | Pip_expr (Fmt (loc, l)) -> convert_fmt env loc (e1.aexpr :: l)
    | Pip_expr e2 ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]
    | Pip_field field -> convert_field env loc e1.aexpr field

  and convert_pipe_tail env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | Pip_expr (App (loc, callee, args)) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (args @ [ e1 ])
    | Pip_expr (Ctor (loc, name, expr)) ->
        if Option.is_some expr then raise (Error (loc, pipe_ctor_msg));
        convert_ctor env loc name (Some e1.aexpr) None
    | Pip_expr (Bop (loc, op, exprs)) ->
        convert_bop env loc op (exprs @ [ e1.aexpr ])
    | Pip_expr (Fmt (loc, l)) -> convert_fmt env loc (l @ [ e1.aexpr ])
    | Pip_expr e2 ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]
    | Pip_field field -> convert_field env loc e1.aexpr field

  and convert_tuple env loc exprs =
    let (_, const), exprs =
      List.fold_left_map
        (fun (i, const) expr ->
          let expr = convert env expr in
          let expr_const =
            (* There's a special case for string literals.
               They will get copied here which makes them not const.
               NOTE copy in convert_record *)
            match expr.expr with
            | Const (String _) -> false
            | _ -> expr.attr.const
          in
          let const = const && expr_const in
          ((i + 1, const), (string_of_int i, expr)))
        (0, true) exprs
    in
    let fields =
      List.map (fun (fname, e) -> { fname; ftyp = e.typ; mut = false }) exprs
    in
    let typ = Trecord ([], None, Array.of_list fields) in
    let attr = { const; global = false; mut = false } in
    { typ; expr = Record exprs; attr; loc }

  and convert_fmt env loc exprs =
    let f expr =
      let e = convert env expr in
      match (e.expr, clean e.typ) with
      | Const (String s), _ -> Fstr s
      | _, Tarray Tu8 -> Fexpr e
      | _, (Tint | Tfloat | Tbool | Tu8 | Ti32 | Tf32) -> Fexpr e
      | _, Tvar { contents = Unbound _ } ->
          Fexpr e (* Might be the right type later *)
      | _, Tarray (Tvar { contents = Unbound _ }) ->
          Fexpr e (* Might be string later *)
      | _, _ ->
          raise
            (Error
               ( e.loc,
                 "Don't know how to format "
                 ^ string_of_type e.typ (Env.modpath env) ))
    in
    let exprs = List.map f exprs in
    let typ = string_typ in
    { typ; expr = Fmt exprs; attr = no_attr; loc }

  and convert_block_annot ~ret env annot stmts =
    let loc = Lexing.(dummy_pos, dummy_pos) in

    let check env (loc, typ) =
      unify
        (loc, "Left expression in sequence must be of type unit:")
        Tunit typ env
    in

    let rec to_expr env old_type = function
      | [
          ( Ast.Let (loc, _, _)
          | Function (loc, _)
          | Rec (loc, _)
          | Open (loc, _) );
        ]
        when ret ->
          raise (Error (loc, "Block must end with an expression"))
      | [] when ret -> raise (Error (loc, "Block cannot be empty"))
      | [] -> ({ typ = Tunit; expr = Const Unit; attr = no_attr; loc }, env)
      | Let (loc, decl, block) :: tl ->
          let env, id, rhs, rmut, pats =
            convert_let ~global:false env loc decl block
          in
          let cont, env = to_expr env old_type tl in
          let cont = List.fold_left fold_decl cont pats in
          let uniq = if rhs.attr.const then uniq_name id else None in
          let expr = Let { id; uniq; rmut; pass = block.pattr; rhs; cont } in
          ({ typ = cont.typ; expr; attr = cont.attr; loc }, env)
      | Function (loc, func) :: tl ->
          let env, (name, unique, abs) = convert_function env loc func false in
          let cont, env = to_expr env old_type tl in
          let expr = Function (name, unique, abs, cont) in
          ({ typ = cont.typ; expr; attr = cont.attr; loc }, env)
      | Rec (loc, funcs) :: tl ->
          (* Collect function names *)
          let collect env (_, (func : Ast.func)) =
            let nameloc, name = func.name in
            enter_level ();
            let typ = newvar () in
            leave_level ();
            Env.(add_value name { def_value with typ } nameloc env)
          in
          let env = List.fold_left collect env funcs in
          let f env (loc, func) =
            let env, f = convert_function env loc func true in
            (env, (loc, f))
          in
          let env, funcs = List.fold_left_map f env funcs in
          let cont, env = to_expr env old_type tl in

          let rec aux = function
            | (loc, (n, u, abs)) :: tl ->
                let t = Env.find_val loc (Path.Pid n) env in
                let decls, cont = aux tl in
                let expr = Function (n, u, abs, cont) in
                ( (n, u, t.typ) :: decls,
                  { typ = cont.typ; expr; attr = cont.attr; loc } )
            | [] -> ([], cont)
          in
          let decls, cont = aux funcs in
          let expr = Mutual_rec_decls (decls, cont) in
          ({ typ = cont.typ; expr; attr = cont.attr; loc }, env)
      | [ Expr (loc, e) ] ->
          last_loc := loc;
          check env old_type;
          (convert_annot env annot e, env)
      | Expr (l1, e1) :: tl ->
          check env old_type;
          let expr = convert env e1 in
          let cont, env = to_expr env (l1, expr.typ) tl in
          let expr = Sequence (expr, cont) in
          ({ typ = cont.typ; expr; attr = cont.attr; loc }, env)
      | Open (loc, mname) :: tl ->
          let env = Env.open_module env loc mname in
          let cont, env = to_expr env old_type tl in
          (cont, env)
    in
    to_expr env (loc, Tunit) stmts

  and convert_block ?(ret = true) env stmts =
    convert_block_annot ~ret env None stmts

  and disambiguate_opens env loc path = function
    | Ast.Local_open (_, id, tl) ->
        disambiguate_opens env loc (Path.append id path) tl
    | Var (_, id) -> convert_var env loc (Path.append id path)
    | expr ->
        let env =
          Path.fold_mod_left
            (fun env name -> Env.open_module env loc name)
            env path
        in
        convert env expr
end

and Records : Recs.S = Recs.Make (Core)
and Patternmatch : Pm.S = Pm.Make (Core) (Records)

let block_external_name loc ~cname id =
  (* We have to deal with shadowing:
     If there is no function with the same name, we make sure
     all future function use different names internally (via [uniq_tbl]).
     If there already is a function, there is nothing we can do right now,
     so we error *)
  let name = match cname with Some name -> name | None -> id in
  match Strtbl.find_opt !uniq_tbl name with
  | None ->
      (* Good, block this name. NOTE see [uniq_name] *)
      Strtbl.add !uniq_tbl name 1;
      Some name
  | Some _ ->
      let msg =
        Printf.sprintf
          "External function name %s already in use. This is not supported \
           yet, make sure to define the external function first"
          name
      in
      raise (Error (loc, msg))

let add_signature_types (env, m) = function
  | Ast.Stypedef (loc, Trecord t) ->
      let env, typ = type_record ~in_sig:true env loc t in
      let m = Module.add_type_sig loc t.name.name typ m in
      (env, m)
  | Stypedef (loc, Talias (name, type_spec)) ->
      let env, typ = type_alias ~in_sig:true env loc name type_spec in
      let m = Module.add_type_sig loc name.name typ m in
      (env, m)
  | Stypedef (loc, Tvariant v) ->
      let env, typ = type_variant ~in_sig:true env loc v in
      let m = Module.add_type_sig loc v.name.name typ m in
      (env, m)
  | Stypedef (loc, Tabstract a) ->
      let env, typ = type_abstract env loc a in
      let m = Module.add_type_sig loc a.name typ m in
      (env, m)
  | Svalue _ -> (env, m)

let add_signature_vals env m = function
  | Ast.Svalue (loc, ((l, n), type_spec)) ->
      (* Here, we don't add to env. We later check that the declaration is implemented correctly,
         in [validate_signature] *)
      let typ = typeof_annot env l type_spec in
      let m = Module.add_value_sig loc n typ m in
      m
  | Stypedef _ -> m

let rec catch_weak_vars env = function
  | Tl_let { lhs = e; _ } | Tl_bind (_, e) | Tl_expr e ->
      catch_weak_expr env Sset.empty e
  | Tl_function (_, _, _, abs) -> catch_weak_body env Sset.empty abs
  | Tl_mutual_rec_decls _ | Tl_module_alias _ -> ()
  | Tl_module _ ->
      (* Module already checks this *)
      ()

and catch_weak_body env sub abs =
  (* Allow the types present in the function signature *)
  let ret = get_generic_ids abs.func.ret in
  let l =
    List.fold_left (fun s p -> get_generic_ids p.pt @ s) ret abs.func.tparams
  in
  let sub = Sset.union sub (Sset.of_list l) in
  catch_weak_expr env sub abs.body

and catch_weak_expr env sub e =
  let _raise () =
    (* print_endline (show_expr e.expr); *)
    (* print_endline (show_typ e.typ); *)
    raise
      (Error
         ( e.loc,
           "Expression contains weak type variables: "
           ^ string_of_type e.typ (Env.modpath env) ))
  in
  if is_weak ~sub e.typ then _raise ();
  match e.expr with
  | Var _ | Const _ | Lambda _ -> ()
  | Bop (_, e1, e2) | Set (e1, e2) | Sequence (e1, e2) ->
      catch_weak_expr env sub e1;
      catch_weak_expr env sub e2
  | Unop (_, e)
  | Field (e, _, _)
  | Ctor (_, _, Some e)
  | Variant_index e
  | Variant_data e
  | Move e
  | Mutual_rec_decls (_, e) ->
      catch_weak_expr env sub e
  | Function (_, _, abs, e) ->
      catch_weak_body env sub abs;
      catch_weak_expr env sub e
  | If (cond, _, e1, e2) ->
      catch_weak_expr env sub cond;
      catch_weak_expr env sub e1;
      catch_weak_expr env sub e2
  | Let { rhs; cont; _ } | Bind (_, rhs, cont) ->
      catch_weak_expr env sub rhs;
      catch_weak_expr env sub cont
  | App { callee; args } ->
      catch_weak_expr env sub callee;
      List.iter (fun a -> catch_weak_expr env sub (fst a)) args
  | Record fs -> List.iter (fun f -> catch_weak_expr env sub (snd f)) fs
  | Ctor _ -> ()
  | Fmt fmt ->
      List.iter
        (function Fstr _ -> () | Fexpr e -> catch_weak_expr env sub e)
        fmt

let rec convert_module env mname sign prog check_ret =
  (* We create a new scope so we don't warn on unused imports *)
  let env = Env.open_toplevel mname env in

  (* Add types from signature for two reasons:
     1. In contrast to OCaml, we don't need to declare them two types,
        so they have to be in env
     2. We don't add vals because the implementation of abstract types is not
        known at this point. Since we substitute generics naively in annots
        (which val decls essentially are), we have to make sure the complete
        implementation is available before. *)
  let sigenv, m = List.fold_left add_signature_types (env, Module.empty) sign in
  let last_type, env, items, m = convert_prog sigenv prog m in
  let externals = Module.append_externals (Env.externals env) in
  (* Make sure to chose the signature env, not the impl one. Abstract types are
     magically made complete by references. *)
  let m = List.fold_left (add_signature_vals sigenv) m sign in
  let m = Module.validate_signature env m in

  (* Catch weak type variables *)
  List.iter (catch_weak_vars env) items;

  let _, _, touched, unused = Env.close_toplevel env in
  let has_sign = match sign with [] -> false | _ -> true in
  if (not (is_module (Env.modpath env))) || has_sign then
    check_unused env unused;

  let items = Exclusivity.check_items touched items in

  (* Program must evaluate to either int or unit *)
  (if check_ret then
     match clean last_type with
     | Tunit | Tint -> ()
     | _ ->
         let msg =
           "Module must return type int or unit, not "
           ^ string_of_type last_type (Env.modpath env)
         in
         raise (Error (!last_loc, msg)));
  (externals, items, m)

and convert_prog env items modul =
  let old = ref (Lexing.(dummy_pos, dummy_pos), Tunit) in

  let rec aux (env, items, m) = function
    | Ast.Stmt stmt ->
        let old', env, items, m = aux_stmt (!old, env, items, m) stmt in
        old := old';
        (env, items, m)
    | Ext_decl (loc, (idloc, id), typ, cname) ->
        let typ = typeof_annot env loc typ in
        (* Make cname explicit to link the correct name even if schmu identifier
           has the module name prepended *)
        let cname = block_external_name loc ~cname id in
        let m =
          Module.add_external ~mname:(Env.modpath env) loc typ id cname
            ~closure:false m
        in
        (Env.add_external id ~cname typ idloc env, items, m)
    | Typedef (loc, Trecord t) ->
        let env, typ = type_record ~in_sig:false env loc t in
        let m = Module.add_type loc typ m in
        (env, items, m)
    | Typedef (loc, Talias (name, type_spec)) ->
        let env, typ = type_alias ~in_sig:false env loc name type_spec in
        let m = Module.add_type loc typ m in
        (env, items, m)
    | Typedef (loc, Tvariant v) ->
        let env, typ = type_variant ~in_sig:false env loc v in
        let m = Module.add_type loc typ m in
        (env, items, m)
    | Typedef (loc, Tabstract _) ->
        raise (Error (loc, "Abstract types need a concrete implementation"))
    | Module ((loc, id), sign, prog) ->
        (* External function are added as side-effects, can be discarded here *)
        let open Module in
        let mname = Path.append id (Env.modpath env) in

        (* Save uniq_tbl state as well as lambda state *)
        let uniq_tbl_bk = !uniq_tbl in
        uniq_tbl := Strtbl.create 64;
        let lambda_id_state_bk = !lambda_id_state in
        reset lambda_id_state;

        let _, moditems, newm = convert_module env mname sign prog true in

        uniq_tbl := uniq_tbl_bk;
        lambda_id_state := lambda_id_state_bk;

        let env =
          match register_module env loc mname newm with
          | Ok env -> env
          | Error () ->
              let msg =
                Printf.sprintf "Module names must be unique. %s exists already"
                  id
              in
              raise (Error (loc, msg))
        in
        let m = add_local_module loc id newm ~into:m in

        let moditems = List.map (fun item -> (mname, item)) moditems in
        let items = Tl_module moditems :: items in
        (env, items, m)
    | Module_alias ((loc, key), mname) ->
        let env = Env.add_module_alias loc ~key ~mname env in
        let mname = Env.find_module_opt loc (Path.Pid key) env |> Option.get in
        let m = Module.add_module_alias loc key mname ~into:m in
        (env, items, m)
    | Module_type _ -> failwith "TODO module type"
  and aux_stmt (old, env, items, m) = function
    (* TODO dedup *)
    | Ast.Let (loc, decl, block) ->
        let env, id, lhs, rmut, pats =
          Core.convert_let ~global:true env loc decl block
        in
        let uniq = uniq_name id in
        (* Make string option out of int option for unique name *)
        let uniq_name =
          Some (Module.unique_name ~mname:(Env.modpath env) id uniq)
        in
        (* TODO special handling for lambdas *)
        let m =
          Module.add_external ~mname:(Env.modpath env) loc lhs.typ id uniq_name
            ~closure:true m
        in
        let expr =
          let expr = Tl_let { loc; id; uniq; lhs; rmut; pass = block.pattr } in
          match pats with
          (* Maybe add pattern expressions *)
          | [] -> [ expr ]
          | ps -> List.map (fun (id, e) -> Tl_bind (id, e)) ps @ [ expr ]
        in
        (old, env, expr @ items, m)
    | Function (loc, func) ->
        let env, (name, unique, abs) =
          Core.convert_function env loc func false
        in
        let m = Module.add_fun ~mname:(Env.modpath env) loc name unique abs m in
        (old, env, Tl_function (loc, name, unique, abs) :: items, m)
    | Rec (loc, funcs) ->
        (* Collect function names *)
        let collect env (_, (func : Ast.func)) =
          let nameloc, name = func.name in
          enter_level ();
          let typ = newvar () in
          leave_level ();
          Env.(add_value name { def_value with typ } nameloc env)
        in
        let env = List.fold_left collect env funcs in
        let f env (loc, func) =
          let env, (n, u, abs) = Core.convert_function env loc func true in
          (env, (loc, n, u, abs))
        in
        let env, funcs = List.fold_left_map f env funcs in
        let rec aux env = function
          | (l, n, u, abs) :: tl ->
              let t = Env.find_val loc (Path.Pid n) env in
              (* Generalize the functions *)
              let typ = generalize t.typ in
              let env = Env.change_type n typ env in

              let decls, fitems, env = aux env tl in
              ((n, u, t.typ) :: decls, Tl_function (l, n, u, abs) :: fitems, env)
          | [] -> ([], [], env)
        in
        let decls, fitems, env = aux env (List.rev funcs) in
        let m = Module.add_rec_block ~mname:(Env.modpath env) loc funcs m in
        (old, env, fitems @ (Tl_mutual_rec_decls decls :: items), m)
    | Expr (loc, expr) ->
        let expr = Core.convert env expr in
        (* Only the last expression is allowed to return something *)
        unify
          (fst old, "Left expression in sequence must be of type unit:")
          Tunit (snd old) env;
        ((loc, expr.typ), env, Tl_expr expr :: items, m)
    | Open (loc, mname) ->
        let env = Env.open_module env loc mname in
        (old, env, items, m)
  in

  let env, items, m = List.fold_left aux (env, [], modul) items in
  (snd !old, env, List.rev items, m)

(* Conversion to Typing.exr below *)
let to_typed ?(check_ret = true) ~mname msg_fn ~std (sign, prog) =
  fmt_msg_fn := Some msg_fn;
  reset_type_vars ();

  let loc = Lexing.(dummy_pos, dummy_pos) in
  (* Add builtins to env *)
  let find_module = Module.find_module ~regeneralize in
  let scope_of_located = Module.scope_of_located in
  let abs_module_name = Module.absolute_module_name in

  let env =
    Builtin.(
      fold (fun env (_, typ, str) ->
          enter_level ();
          let typ = instantiate typ in
          leave_level ();
          Env.(add_value str { def_value with typ = generalize typ } loc env)))
      (Env.empty ~find_module ~scope_of_located ~abs_module_name mname)
  in

  (* Open prelude *)
  let env = if std then Env.open_module env loc "std" else env in

  let externals, items, m = convert_module env mname sign prog check_ret in

  (* Add polymorphic functions from imported modules *)
  let items = List.map (fun item -> (mname, item)) items in
  let items = List.rev !Module.poly_funcs @ items in

  (* print_endline (String.concat ", " (List.map string_of_type typeinsts)); *)
  ({ externals; items }, m)

let typecheck (prog : Ast.prog) =
  let rec get_last_type = function
    | (_, Tl_expr expr) :: _ -> expr.typ
    | ( _,
        ( Tl_function _ | Tl_let _ | Tl_bind _ | Tl_mutual_rec_decls _
        | Tl_module_alias _ | Tl_module _ ) )
      :: tl ->
        get_last_type tl
    | [] -> Tunit
  in

  (* Ignore unused binding warnings *)
  let msg_fn _ _ _ = "" in
  let mname = main_path in
  let tree, _ = to_typed ~mname ~check_ret:false msg_fn ~std:false prog in
  let typ = get_last_type (List.rev tree.items) in
  print_endline (show_typ typ);
  typ
