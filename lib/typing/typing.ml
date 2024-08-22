open Types
open Typed_tree
open Inference
open Error

type msg_fn = string -> Ast.loc -> string -> string

type converted_prog = {
  last_type : typ;
  env : Env.t;
  items : toplevel_item list;
  m : Module_common.t;
  sgn_env : Env.t;
  sgn : Ast.signature list;
}

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
  let typ, _, b = Inference.types_match l r in
  if b then typ
  else
    let mn = Env.modpath env in
    let msg = Error.format_type_err "Var annotation" mn r l in
    raise (Error (loc, msg))

let main_path = Path.Pid "schmu"
let is_module = function Path.Pid "schmu" -> false | Pid _ | Pmod _ -> true

let loc_equal (af, asnd) (bf, bsnd) =
  (* Exclusivity uses location of the whole expression, because it doesn't have
     access to the pattern id location. Thus, [a] must include [b] *)
  let open Lexing in
  String.equal af.pos_fname bf.pos_fname
  && Int.equal af.pos_lnum bf.pos_lnum
  && Int.equal af.pos_cnum bf.pos_cnum
  && Int.equal asnd.pos_cnum bsnd.pos_cnum

let check_unused env unused unmutated =
  let err (name, kind, loc) =
    let warn_kind =
      match kind with
      | Env.Unused -> "Unused binding "
      | Unmutated -> "Unmutated mutable binding "
      | Unused_mod -> "Unused module 'use' declaration "
    in

    (* We need to use the location to match the errors because the two systems
       deal with shadowing in a different way *)
    let print =
      match kind with
      | Env.Unmutated -> List.exists (fun l -> loc_equal l loc) unmutated
      | Unused | Unused_mod -> true
    in
    if print then
      (Option.get !fmt_msg_fn) "warning" loc
        (warn_kind ^ Path.(rm_name (Env.modpath env) name |> show))
      |> print_endline
  in
  List.iter err unused

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

let typeof_annot ?(typedef = false) ?(param = false) env loc annot =
  let fn_kind = if param then Closure [] else Simple in

  let find env t tick =
    match Env.find_type_opt loc t env with
    | Some (decl, path) -> (
        match decl.kind with
        | Dalias typ -> typ
        | Dabstract _ | Drecord _ | Dvariant _ -> Tconstr (path, decl.params))
    | None ->
        raise
          (Error
             ( loc,
               "Unbound type " ^ tick
               ^ Path.(rm_name (Env.modpath env) t |> show)
               ^ "." ))
  in

  let rec is_quantified = function
    | Tconstr (_, []) -> None
    | Tconstr (name, params) ->
        let len = List.filter is_polymorphic params |> List.length in
        if len == 0 then None else Some (name, len)
    | Tfixed_array (_, t) ->
        if is_polymorphic t then Some (Path.Pid "array#?", 1) else None
    | Tvar { contents = Link t } -> is_quantified t
    | Tfun _ as t -> (
        let ts = get_generic_ids t in
        match ts with [] -> None | ts -> Some (Path.Pid "fun", List.length ts))
    | _ -> None
  in

  let rec concrete_type in_list env = function
    | Ast.Ty_id "array#?" ->
        if not in_list then
          raise (Error (loc, "Type array#? expects 1 type parameter"));
        Tfixed_array (ref (Generalized "u"), Qvar "o")
    | Ty_id id when String.starts_with ~prefix:"array#" id ->
        let size = String.sub id 6 (String.length id - 6) |> int_of_string in
        if not in_list then
          raise (Error (loc, "Type " ^ id ^ " expects 1 type parameter"));
        Tfixed_array (ref (Known size), Qvar "o")
    | Ty_id t ->
        let t = find env (Path.Pid t) "" in
        (if not in_list then
           match is_quantified t with
           | Some (name, n) ->
               let msg =
                 Printf.sprintf "Type %s expects %i type parameter%s"
                   Path.(rm_name (Env.modpath env) name |> show)
                   n
                   (if n <> 1 then "s" else "")
               in
               raise (Error (loc, msg))
           | None -> ());
        t
    | Ty_var id when typedef -> find env (Path.Pid id) "'"
    | Ty_var id ->
        (* Type annotation in function *)
        Qvar id
    | Ty_func l -> handle_func env l
    | Ty_applied l -> type_list env l
    | Ty_use_id (_, path) -> find env path ""
    | Ty_tuple ts ->
        let ts = List.map (fun t -> concrete_type false env t) ts in
        Ttuple ts
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
                    ^ string_of_type (Env.modpath env) t
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
        | None ->
            print_endline (show_typ t);
            failwith "Internal Error: Not sure, this shouldn't happen")
  and handle_func env = function
    | [] -> failwith "Internal Error: Type annot list should not be empty"
    | [ (t, _) ] -> concrete_type false env t
    | [ (Ast.Ty_id "unit", _); (t, _) ] ->
        Tfun ([], concrete_type false env t, fn_kind)
    | [ (Ast.Ty_applied [ Ast.Ty_id "unit" ], _); (t, _) ] ->
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
    match repr t with
    | Qvar _ | Tvar { contents = Unbound _ } -> None
    | _ -> Some t
  in
  (* We don't clean here, because it might mess with links *)
  match t with
  | Tvar { contents = Link t } -> param_annots t
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
    (fun (env, i) { Ast.loc; pattern; annot } ->
      let id, idloc, _, pattr = pattern_id i pattern in
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
              mut = mut_of_pattr pattr;
              mname = None;
            }
            idloc env,
          i + 1 ),
        ({ pt = type_id; pattr }, { pt = qparams; pattr }) ))
    (env, 0) params
  |> fun ((env, _), lst) ->
  let ids, qparams = List.split lst in
  let ret = Option.map (fun t -> typeof_annot env loc t) ret in
  (env, ids, qparams, ret)

let check_type_unique env loc ~in_sgn name =
  match Env.find_type_same_module name env with
  (* It's ok to have a type both in signature and impl *)
  | Some (decl, _) when Bool.equal in_sgn decl.in_sgn ->
      let msg =
        Printf.sprintf
          "Type names in a module must be unique. %s exists already" name
      in
      raise (Error (loc, msg))
  | Some _ | None -> ()

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
      let decl = { params = []; kind = Dalias t; in_sgn = false } in

      (Env.add_type name decl env, t))
    env ts

let add_self_recursion env name =
  let decl = { params = []; kind = Dabstract None; in_sgn = false } in
  Env.add_type name decl env

let type_record env loc ~in_sgn Ast.{ name = { poly_param; name }; labels } =
  let labels, params, recurs =
    (* Temporarily add polymorphic type name to env *)
    let temp_env, params =
      let tmp = add_self_recursion env name in
      add_type_param tmp poly_param
    in
    let recurs = ref false in
    let absolute_path = Path.append name (Env.modpath env) in
    let labels =
      Array.map
        (fun (mut, fname, type_expr) ->
          (* The base case handling here does not make sense. Whenever a
             recursive occurence is behind a type with a base case (like
             option), then the recursion is bound, i.e. we allow it. *)
          let typ = typeof_annot ~typedef:true temp_env loc type_expr in
          let ftyp =
            let get_decl = Hashtbl.find (Env.decl_tbl env) in
            match
              recursion_allowed get_decl instantiate_sub ~params absolute_path
                typ
            with
            | Ok (Some (typ, has_base)) ->
                if not has_base then
                  raise (Error (loc, "Recursive type has no base case"));
                recurs := true;
                typ
            | Ok None -> typ
            | Error msg -> raise (Error (loc, msg))
          in
          { fname; ftyp; mut })
        labels
    in

    (labels, params, !recurs)
  in

  let decl = { params; kind = Drecord (recurs, labels); in_sgn } in
  (* Make sure that each type name only appears once per module *)
  check_type_unique ~in_sgn env loc name;
  (Env.add_type name decl env, decl)

let type_alias env loc ~in_sgn { Ast.poly_param; name } type_spec =
  (* Temporarily add polymorphic type name to env *)
  let temp_env, params = add_type_param env poly_param in
  let typ = typeof_annot ~typedef:true temp_env loc type_spec in

  let decl = { params; kind = Dalias typ; in_sgn } in
  (* Make sure that each type name only appears once per module *)
  check_type_unique ~in_sgn env loc name;
  (Env.add_type name decl env, decl)

let type_abstract env loc { Ast.poly_param; name } =
  (* Make sure that each type name only appears once per module *)
  (* Abstract types are only allowed in signatures *)
  check_type_unique ~in_sgn:true env loc name;
  (* Tunit because we need to pass some type *)
  (* Temporarily add polymorphic type name to env *)
  let params = List.map (fun _ -> make_type_param ()) poly_param in

  let decl = { params; kind = Dabstract None; in_sgn = true } in
  (Env.add_type name decl env, decl)

let type_variant env loc ~in_sgn { Ast.name = { poly_param; name }; ctors } =
  (* Temporarily add polymorphic type name to env *)
  let temp_env, params =
    let tmp = add_self_recursion env name in
    add_type_param tmp poly_param
  in

  (* We follow the C way for C-style enums. At the same time, we forbid
     tag clashes for constructors with payload *)
  let next = ref (-1) in
  let indices = Hashtbl.create 32 in
  let nexti ~has_payload loc name =
    incr next;
    match Hashtbl.find_opt indices !next with
    | Some (name, pl) when has_payload || pl ->
        let msg =
          Printf.sprintf "Tag %i already used for constructor #%s" !next name
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

  let recurs = ref false in
  let has_base = ref false in
  let absolute_path = Path.append name (Env.modpath env) in
  let ctors =
    List.map
      (fun { Ast.name = loc, cname; typ_annot; index } ->
        match typ_annot with
        | None ->
            (* Just a ctor, without data *)
            has_base := true;
            {
              cname;
              ctyp = None;
              index = maybe_add_index false loc cname index;
            }
        | Some annot ->
            let typ = typeof_annot ~typedef:true temp_env loc annot in
            let typ =
              let get_decl = Hashtbl.find (Env.decl_tbl env) in
              match
                recursion_allowed get_decl instantiate_sub ~params absolute_path
                  typ
              with
              | Ok (Some (typ, hasbase)) ->
                  if hasbase then has_base := true;
                  recurs := true;
                  typ
              | Ok None ->
                  has_base := true;
                  typ
              | Error msg -> raise (Error (loc, msg))
            in
            {
              cname;
              ctyp = Some typ;
              index = maybe_add_index true loc cname index;
            })
      ctors
    |> Array.of_list
  in
  if !recurs && not !has_base then
    raise (Error (loc, "Recursive type has no base case"));

  let decl = { params; kind = Dvariant (!recurs, ctors); in_sgn } in
  (* Make sure that each type name only appears once per module *)
  check_type_unique ~in_sgn env loc name;
  (Env.add_type name decl env, decl)

let convert_simple_lit loc typ expr =
  { typ; expr = Const expr; attr = { no_attr with const = true }; loc }

let builtins_hack callee args =
  (* return of __unsafe_ptr_get should be marked mut, otherwise it won't be copied
     correctly later in codegen. *)
  let mut =
    match args with
    (* We only care about the first arg, ie the array *)
    | (_, _, mut) :: _ -> mut
    | _ -> false
  in
  match Typed_tree.follow_expr callee.expr with
  | Some (Var (id, None)) -> (
      match id with
      | "__unsafe_ptr_get" -> { no_attr with mut }
      | "__array_get" | "__fixed_array_get" | "__array_data"
      | "__unsafe_array_length" | "__unsafe_addr" | "__rc_get" ->
          { no_attr with mut }
      | _ -> no_attr (* stdlib re-exports *))
  | Some (Var (id, Some (Path.Pid "array"))) -> (
      match id with "data" -> { no_attr with mut } | _ -> no_attr)
  | Some (Var (("get" | "+>" | "addr"), Some (Path.Pid "unsafe"))) ->
      { no_attr with mut }
  | Some (Var ("get", Some Path.(Pmod ("std", Pid "rc")))) ->
      { no_attr with mut }
  | Some _ | None -> no_attr

let fold_decl cont (id, e) = { cont with expr = Bind (id, e, cont) }

let rec is_poly_call texpr =
  match texpr.expr with
  | Var _ | Const _ | Bop _ | Unop _ | If _ | Lambda _ | Record _ | Field _
  | Set _ | Ctor _ | Variant_index _ | Variant_data _ | Fmt _ ->
      false
  | App _ when is_polymorphic texpr.typ -> (
      match repr texpr.typ with Tfun _ -> true | _ -> false)
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
      let abs = { nparams; body; func; inline = false; is_rec = false } in
      { texpr with expr = Lambda (lambda_id (), abs) }
  | Tvar { contents = Link t } -> wrap_in_lambda texpr t
  | _ -> failwith "Internal Error: Not a function for wrapping"

module rec Core : sig
  val convert : Env.t -> Ast.expr -> typed_expr

  val convert_annot :
    Env.t -> Types.typ option -> Ast.expr -> Typed_tree.typed_expr

  val convert_var : Env.t -> Ast.loc -> Path.t -> typed_expr
  val convert_block : ?ret:bool -> Env.t -> Ast.block -> typed_expr * Env.t

  val pass_mut_helper :
    Env.t -> Ast.loc -> dattr -> (unit -> typed_expr) -> typed_expr

  val convert_let :
    global:bool ->
    Env.t ->
    Ast.loc ->
    Ast.decl ->
    Ast.passed_expr ->
    Env.t * string * loc * typed_expr * bool * (string * typed_expr) list

  val convert_function :
    Env.t ->
    Ast.loc ->
    Ast.func ->
    bool ->
    Env.t * (string * int option * abstraction)
end = struct
  open Records
  open Patternmatch

  let string_typ = Tconstr (Path.Pmod ("string", Path.Pid "t"), [])

  let rec convert env expr = convert_annot env None expr

  and convert_annot env annot = function
    | Ast.Var (loc, id) -> convert_var env loc (Path.Pid id)
    | Lit (loc, Int i) -> convert_simple_lit loc tint (Int i)
    | Lit (loc, Bool b) -> convert_simple_lit loc tbool (Bool b)
    | Lit (loc, U8 c) -> convert_simple_lit loc tu8 (U8 c)
    | Lit (loc, U16 s) -> convert_simple_lit loc tu16 (U16 s)
    | Lit (loc, Float f) -> convert_simple_lit loc tfloat (Float f)
    | Lit (loc, I32 i) -> convert_simple_lit loc ti32 (I32 i)
    | Lit (loc, F32 i) -> convert_simple_lit loc tf32 (F32 i)
    | Lit (loc, String s) ->
        let typ = string_typ in
        (* The string literal itself is const, not handled within the const table *)
        let attr = { no_attr with const = true } in
        { typ; expr = Const (String s); attr; loc }
    | Lit (loc, Array arr) -> convert_array_lit env loc arr
    | Lit (loc, Fixed_array arr) -> convert_fixed_array_lit env loc arr
    | Lit (loc, Fixed_array_num (num, item)) ->
        convert_fixed_array_num_lit env loc num item
    | Lit (loc, Unit) ->
        let attr = { no_attr with const = true } in
        { typ = tunit; expr = Const Unit; attr; loc }
    | Lambda (loc, id, attr, ret, e) -> convert_lambda env loc id attr ret e
    | Let_e (loc, decl, expr, cont) -> convert_let_e env loc decl expr cont
    | App (loc, e1, e2) -> convert_app ~switch_uni:false env loc e1 e2
    | Bop (loc, bop, e1, e2) -> convert_bop env loc bop e1 e2
    | Unop (loc, unop, expr) -> convert_unop env loc unop expr
    | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
    | Record (loc, labels) -> convert_record env loc annot labels
    | Tuple (loc, exprs) -> convert_tuple env loc exprs
    | Record_update (loc, record, items) ->
        convert_record_update env loc annot record items
    | Field (loc, expr, id) -> convert_field env loc expr id
    | Set (loc, expr, value) -> convert_set env loc expr value
    | Do_block stmts -> convert_block_annot ~ret:true env annot stmts |> fst
    | Pipe_head (loc, e1, e2) -> convert_pipe_head env loc e1 e2
    | Pipe_tail (loc, e1, e2) -> convert_pipe_tail env loc e1 e2
    | Ctor (loc, name, args) -> convert_ctor env loc name args annot
    | Match (loc, pass, expr, cases) -> convert_match env loc pass expr cases
    | Local_use (loc, name, expr) ->
        disambiguate_uses env loc annot (Path.Pid name) expr
    | Fmt (loc, exprs) -> convert_fmt env loc exprs

  and convert_var env loc id =
    match Env.query_val_opt loc id env with
    | Some t ->
        let typ = instantiate t.typ in
        let attr = { const = t.const; global = t.global; mut = t.mut } in
        { typ; expr = Var (Path.get_hd id, t.mname); attr; loc }
    | None ->
        (* Functor parameters are not local modules and will raise an [Error] in
           module.ml. That's by accident, and the error message is abysmal and
           mentions internals, thus we catch this [Error] and print the proper
           error. If we are here, it's an error anyway, so fishing for
           exceptions is ok in this case. *)
        let suff =
          try
            match Env.find_module_opt loc id env with
            | Some _ -> ", but a module with the name exists"
            | None -> ""
          with Error _ -> ""
        in
        let msg = "No var named " ^ Path.show id ^ suff in
        raise (Error (loc, msg))

  and convert_array_lit env loc arr =
    let f typ expr =
      let expr = convert env expr in
      unify (loc, "In array literal") typ expr.typ env;
      (typ, expr)
    in
    let typ, exprs = List.fold_left_map f (newvar ()) arr in

    let typ = tarray typ in
    { typ; expr = Const (Array exprs); attr = no_attr; loc }

  and convert_fixed_array_lit env loc arr =
    let f (typ, const) expr =
      let expr = convert env expr in
      unify (loc, "In fixed-size array literal") typ expr.typ env;
      let const =
        const
        &&
        (* There's a special case for string literals.
           They will get copied here which makes them not const.
           NOTE copy in convert_tuple *)
        match expr.expr with Const (String _) -> false | _ -> expr.attr.const
      in
      ((typ, const), expr)
    in
    let (typ, const), exprs = List.fold_left_map f (newvar (), true) arr in

    let typ = Tfixed_array (ref (Known (List.length arr)), typ) in
    (* TODO check mut for const and introduce constexpr *)
    let attr = { no_attr with const } in
    { typ; expr = Const (Fixed_array exprs); attr; loc }

  and convert_fixed_array_num_lit env loc num item =
    let exprs = List.init num (fun _ -> convert env item) in
    let expr = List.hd exprs in
    let typ = Tfixed_array (ref (Known num), expr.typ) in
    let attr = { no_attr with const = expr.attr.const } in
    { typ; expr = Const (Fixed_array exprs); attr; loc }

  and typeof_annot_decl env loc annot block =
    enter_level ();
    let expr =
      match annot with
      | None ->
          let t = convert env block in
          leave_level ();
          (* We generalize functions, but allow weak variables for value types *)
          let typ =
            match repr t.typ with Tfun _ -> generalize t.typ | _ -> t.typ
          in
          { t with typ }
      | Some annot ->
          let t_annot = typeof_annot env loc annot in
          let t = convert_annot env (Some t_annot) block in
          leave_level ();

          let typ =
            match repr t.typ with
            | Tfun _ -> check_annot env loc t.typ t_annot
            | _ ->
                unify (loc, "In let binding") t.typ t_annot env;
                t_annot
          in

          { t with typ }
    in
    if is_poly_call expr then wrap_in_lambda expr expr.typ else expr

  and convert_let ~global env loc (decl : Ast.decl) { Ast.pattr; pexpr = block }
      =
    let id, idloc, has_exprname, attr = pattern_id 0 decl.pattern in
    let e1 = typeof_annot_decl env loc decl.annot block in
    let mut = mut_of_pattr attr in
    let projected = mut && mut_of_pattr pattr in
    let const =
      if has_exprname then false
      else e1.attr.const && (not projected) && not e1.attr.mut
    in
    let global = if has_exprname then false else global in
    let mname = Some (Env.modpath env) in
    let env =
      Env.add_value id
        { (Env.def_value env) with typ = e1.typ; const; global; mut; mname }
        idloc env
    in
    let env, pat_exprs = convert_decl env [ decl ] in
    let expr = { e1 with attr = { global; const; mut } } in
    (env, id, idloc, expr, e1.attr.mut, pat_exprs)

  and convert_let_e env loc decl expr cont =
    let env, id, id_loc, rhs, rmut, pats =
      convert_let ~global:false env loc decl expr
    in
    let cont = convert env cont in
    let cont = List.fold_left fold_decl cont pats in
    let uniq = if rhs.attr.const then uniq_name id else None in
    let expr = Let { id; id_loc; uniq; rmut; pass = expr.pattr; rhs; cont } in
    { typ = cont.typ; expr; attr = cont.attr; loc }

  and convert_lambda env loc params attr ret_annot body =
    let env = Env.open_function env in
    enter_level ();
    let env, params_t, qparams, ret_annot =
      handle_params env loc params pattern_id ret_annot
    in
    let nparams =
      List.mapi
        (fun i (d : Ast.decl) ->
          let id, _, _, _ = pattern_id i d.pattern in
          id)
        params
    in

    let env, param_exprs = convert_decl env params in

    let body = convert_block env body |> fst in
    let body = List.fold_left fold_decl body param_exprs in

    leave_level ();
    let _, closed_vars, touched, unused = Env.close_function env in

    let unmutated, touched, body =
      let get_decl = Hashtbl.find (Env.decl_tbl env) in
      Exclusivity.check_tree get_decl params_t ~mname:(Env.modpath env)
        (List.map2 (fun n (d : Ast.decl) -> (n, d.loc)) nparams params)
        touched body
    in

    (* Copied from function below *)
    let closed_vars =
      List.fold_left
        (fun clsd -> function
          | Ast.Fa_single (loc, attr) ->
              raise (Error (loc, "Unknown attribute: " ^ attr))
          | Fa_param ((_, "copy"), lst) ->
              List.fold_left
                (fun clsd (loc, id) ->
                  match add_closure_copy clsd id with
                  | Some c -> c
                  | None ->
                      let msg =
                        "Value " ^ id ^ " is not captured, cannot copy"
                      in
                      raise (Error (loc, msg)))
                clsd lst
          | Fa_param ((loc, attr), _) ->
              raise (Error (loc, "Unknown attribute: " ^ attr)))
        closed_vars attr
    in

    let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
    check_unused env unused unmutated;

    let typ = Tfun (params_t, body.typ, kind) in
    match typ with
    | Tfun (tparams, ret, kind) ->
        let ret = match ret_annot with Some ret -> ret | None -> ret in
        let qtyp = Tfun (qparams, ret, kind) in
        let typ = check_annot env loc typ qtyp in

        let func = { tparams; ret; kind; touched } in
        let inline = false and is_rec = false in
        let abs =
          { nparams; body = { body with typ = ret }; func; inline; is_rec }
        in
        let expr = Lambda (lambda_id (), abs) in
        { typ; expr; attr = no_attr; loc }
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and convert_function env loc
      Ast.{ name = nameloc, name; params; return_annot; body; attr; is_rec }
      inrec =
    (* Create a fresh type var for the function name
       and use it in the function body *)
    let unique = uniq_name name in

    let used = if inrec then Env.get_used name env else false in
    enter_level ();
    let env, nparams =
      if inrec || not is_rec then
        (* Function is already part of env with a fresh variable *)
        ( env,
          List.mapi
            (fun i (d : Ast.decl) ->
              let id, _, _, _ = pattern_id i d.pattern in
              id)
            params )
      else
        (* Recursion allowed for named funcs *)
        let ps, nparams =
          List.mapi
            (fun i p ->
              let id, _, _, pattr = pattern_id i Ast.(p.pattern) in
              ({ pattr; pt = newvar () }, id))
            params
          |> List.split
        in
        let typ = Tfun (ps, newvar (), Simple) in
        ( Env.(
            add_value name { (def_value env) with typ } nameloc env
            |> add_callname ~key:name
                 (Module_common.unique_name ~mname:(modpath env) name unique)),
          nparams )
    in

    (* We duplicate some lambda code due to naming *)
    let env = Env.open_function env in
    let body_env, params_t, qparams, ret_annot =
      handle_params env loc params pattern_id return_annot
    in

    let body_env, param_exprs = convert_decl body_env params in

    let body = convert_block body_env body |> fst in
    (* Add bindings from patterns *)
    let body = List.fold_left fold_decl body param_exprs in
    leave_level ();

    let env, closed_vars, touched, unused = Env.close_function env in

    let unmutated, touched, body =
      let get_decl = Hashtbl.find (Env.decl_tbl env) in
      Exclusivity.check_tree get_decl params_t ~mname:(Env.modpath env)
        (List.map2 (fun n (d : Ast.decl) -> (n, d.loc)) nparams params)
        touched body
    in

    let inline, closed_vars =
      List.fold_left
        (fun (inl, clsd) -> function
          | Ast.Fa_single (_, "inline") -> (true, clsd)
          | Fa_single (loc, attr) ->
              raise (Error (loc, "Unknown attribute: " ^ attr))
          | Fa_param ((_, "copy"), lst) ->
              ( inl,
                List.fold_left
                  (fun clsd (loc, id) ->
                    match add_closure_copy clsd id with
                    | Some c -> c
                    | None ->
                        let msg =
                          "Value " ^ id ^ " is not captured, cannot copy"
                        in
                        raise (Error (loc, msg)))
                  clsd lst )
          | Fa_param ((loc, attr), _) ->
              raise (Error (loc, "Unknown attribute: " ^ attr)))
        (false, closed_vars) attr
    in

    let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
    check_unused env unused unmutated;

    let typ = Tfun (params_t, body.typ, kind) in

    (* Make sure the types match *)
    if inrec || is_rec then
      unify (loc, "Function") (Env.find_val loc (Path.Pid name) env).typ typ env;

    (* For mutually recursive functions, we generalize at the end of the rec
       block. Otherwise calls to the not-last function in the set will not
       work*)
    let typ = if inrec then typ else generalize typ in

    match typ with
    | Tfun (tparams, ret, kind) ->
        (* Add the generalized type to the env to keep the closure there *)
        let env =
          if inrec || is_rec then Env.change_type name typ env
          else
            Env.(
              add_value name { (def_value env) with typ } nameloc env
              |> add_callname ~key:name
                   (Module_common.unique_name ~mname:(modpath env) name unique))
        in
        (* Discard usage of internal recursive calls *)
        let used = Env.set_used name env used in
        if (not used) && is_rec && not inrec then
          raise (Error (nameloc, "Unused rec flag"));

        let ret = match ret_annot with Some ret -> ret | None -> ret in
        let qtyp = Tfun (qparams, ret, kind) |> generalize in
        check_annot env loc typ qtyp |> ignore;

        let func = { tparams; ret; kind; touched } in
        let lambda =
          { nparams; body = { body with typ = ret }; func; inline; is_rec }
        in

        (env, (name, unique, lambda))
    | _ -> failwith "Internal Error: generalize produces a new type?"

  and pass_mut_helper env loc pass convert =
    (match pass with
    | Dmut | Dset -> Env.open_mutation env
    | Dnorm | Dmove -> ());
    let e = convert () in
    (match pass with
    | Dmut | Dset ->
        Env.close_mutation env;
        if not e.attr.mut then
          raise (Error (loc, "Mutably passed expression is not mutable"))
    | Dmove | Dnorm -> ());
    e

  and convert_app ~switch_uni env loc e1 args =
    let callee = convert env e1 in

    let annots = param_annots callee.typ in
    let typed_exprs =
      List.mapi
        (fun i (a : Ast.argument) ->
          let e =
            pass_mut_helper env a.aloc a.apass (fun () ->
                convert_annot env (param_annot annots i) a.aexpr)
          in
          (* We also care about whether the argument _can_ be mutable, for array-get *)
          (e, a.apass, e.attr.mut))
        args
    in

    let args =
      List.map (fun (a, pattr, _) -> { pattr; pt = a.typ }) typed_exprs
    in
    let apply param (texpr, _, _) =
      ({ texpr with typ = param.pt }, param.pattr)
    in
    let targs = List.map2 apply args typed_exprs in

    let res_t = newvar () in
    if switch_uni then
      unify (loc, "In application") (Tfun (args, res_t, Simple)) callee.typ env
    else
      unify (loc, "In application") callee.typ (Tfun (args, res_t, Simple)) env;

    (* Extract the returning type from the callee, because it's properly
       generalized and linked. This way, everything in a function body should be
       generalized and we can easily catch weak type variables *)
    let rec extract_typ = function
      | Tfun (_, t, _) -> t
      | Tvar { contents = Link t } -> extract_typ t
      | t -> t
    in
    let typ = extract_typ callee.typ in
    let attr = builtins_hack callee typed_exprs in

    (* For now, we don't support const functions *)
    { typ; expr = App { callee; args = targs }; attr; loc }

  and convert_bop env loc bop e1 e2 =
    let check typ =
      let t1 = convert env e1 in
      let t2 = convert env e2 in

      unify (loc, "Binary " ^ string_of_bop bop) typ t1.typ env;
      unify (loc, "Binary " ^ string_of_bop bop) t1.typ t2.typ env;
      (t1, t2, t1.attr.const && t2.attr.const)
    in

    let typ, (t1, t2, const) =
      match bop with
      | Ast.Plus_i | Mult_i | Minus_i | Div_i -> (tint, check tint)
      | Less_i | Equal_i | Greater_i | Less_eq_i | Greater_eq_i ->
          (tbool, check tint)
      | Plus_f | Mult_f | Minus_f | Div_f -> (tfloat, check tfloat)
      | Less_f | Equal_f | Greater_f | Less_eq_f | Greater_eq_f ->
          (tbool, check tfloat)
      | And | Or -> (tbool, check tbool)
    in
    { typ; expr = Bop (bop, t1, t2); attr = { no_attr with const }; loc }

  and convert_unop env loc unop expr =
    match snd unop with
    | "-." ->
        let e = convert env expr in
        unify (loc, "In unary -.") tfloat e.typ env;
        { typ = tfloat; expr = Unop (Uminus_f, e); attr = e.attr; loc }
    | "-" -> (
        let e = convert env expr in
        let msg = "In unary -" in
        let expr = Unop (Uminus_i, e) in

        try
          (* We allow '-' to also work on float expressions *)
          unify (loc, msg) tfloat e.typ env;
          { typ = tfloat; expr; attr = e.attr; loc }
        with Error _ -> (
          try
            unify (loc, msg) tint e.typ env;
            { typ = tint; expr; attr = e.attr; loc }
          with Error _ ->
            unify (loc, msg) (Tconstr (Path.Pid "int or float", [])) e.typ env;
            failwith "unreachable"))
    | _ -> raise (Error (fst unop, "Custom unary operators are not supported"))

  and convert_if env loc cond e1 e2 =
    (* We can assume pred evaluates to bool and both branches need to evaluate
       to the some type *)
    let type_cond = convert env cond in
    unify (loc, "In condition") type_cond.typ tbool env;
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
            { typ = tunit; expr = Const Unit; attr; loc }
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

    (* Would be interesting to evaluate this at compile time, but I think it's
       not that important right now *)
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
    unify (loc, "In mutation") toset.typ valexpr.typ env;
    let moved = Snot_moved (* will be set in excl pass *) in
    { typ = tunit; expr = Set (toset, valexpr, moved); attr = no_attr; loc }

  and convert_pipe_head env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | Pip_expr (App (loc, callee, args)) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (e1 :: args)
    | Pip_expr (Ctor (loc, name, expr)) ->
        if Option.is_some expr then raise (Error (loc, pipe_ctor_msg));
        convert_ctor env loc name (Some e1.aexpr) None
    | Pip_expr (Fmt (loc, l)) -> convert_fmt env loc (e1.aexpr :: l)
    | Pip_expr e2 ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]

  and convert_pipe_tail env loc e1 e2 =
    let switch_uni = true in
    match e2 with
    | Pip_expr (App (loc, callee, args)) ->
        (* Add e1 to beginnig of args *)
        convert_app ~switch_uni env loc callee (args @ [ e1 ])
    | Pip_expr (Ctor (loc, name, expr)) ->
        if Option.is_some expr then raise (Error (loc, pipe_ctor_msg));
        convert_ctor env loc name (Some e1.aexpr) None
    | Pip_expr (Fmt (loc, l)) -> convert_fmt env loc (l @ [ e1.aexpr ])
    | Pip_expr e2 ->
        (* Should be a lone id, if not we let it fail in _app *)
        convert_app ~switch_uni env loc e2 [ e1 ]

  and convert_tuple env loc exprs =
    let (_, const), exprs =
      List.fold_left_map
        (fun (i, const) expr ->
          let expr = convert env expr in
          let expr_const =
            (* There's a special case for string literals. They will get copied
               here which makes them not const. NOTE copy in convert_record *)
            match expr.expr with
            | Const (String _) -> false
            | _ -> expr.attr.const
          in
          let const = const && expr_const in
          ((i + 1, const), (string_of_int i, expr)))
        (0, true) exprs
    in
    let ts = List.map (fun (_, e) -> e.typ) exprs in
    let typ = Ttuple ts in
    let attr = { const; global = false; mut = false } in
    { typ; expr = Record exprs; attr; loc }

  and convert_fmt env loc exprs =
    let f expr =
      let e = convert env expr in
      match (e.expr, repr e.typ) with
      | Const (String s), _ -> Fstr s
      | ( _,
          Tconstr
            ( Pid "array",
              [
                ( Tconstr (Pid "u8", _)
                (* Might be a string later *)
                | Tvar { contents = Unbound _ } );
              ] ) ) ->
          Fexpr e
      | _, Tconstr (p, [])
        when Path.equal p (Path.Pmod ("string", Path.Pid "t")) ->
          Fexpr e
      | _, Tconstr (Pid ("int" | "bool" | "float" | "u8" | "i32" | "f32"), _) ->
          Fexpr e
      | _, Tvar { contents = Unbound _ } ->
          Fexpr e (* Might be the right type later *)
      | _, _ ->
          raise
            (Error
               ( e.loc,
                 "Don't know how to format "
                 ^ string_of_type (Env.modpath env) e.typ ))
    in
    let exprs = List.map f exprs in
    let typ = string_typ in
    { typ; expr = Fmt exprs; attr = no_attr; loc }

  and convert_block_annot ~ret env annot stmts =
    let loc = Lexing.(dummy_pos, dummy_pos) in

    let check env (loc, typ) =
      unify
        (loc, "Left expression in sequence must be of type unit,")
        tunit typ env
    in

    let rec to_expr env old_type = function
      | [
          (Ast.Let (loc, _, _) | Function (loc, _) | Rec (loc, _) | Use (loc, _));
        ]
        when ret ->
          raise (Error (loc, "Block must end with an expression"))
      | [] when ret -> raise (Error (loc, "Block cannot be empty"))
      | [] -> ({ typ = tunit; expr = Const Unit; attr = no_attr; loc }, env)
      | Let (loc, decl, block) :: tl ->
          let env, id, id_loc, rhs, rmut, pats =
            convert_let ~global:false env loc decl block
          in
          let cont, env = to_expr env old_type tl in
          let cont = List.fold_left fold_decl cont pats in
          let uniq = if rhs.attr.const then uniq_name id else None
          and pass = block.pattr in
          let expr = Let { id; id_loc; uniq; rmut; pass; rhs; cont } in
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
            Env.(add_value name { (def_value env) with typ } nameloc env)
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
      | Use (loc, mname) :: tl ->
          let env = Env.use_module env loc mname in
          let cont, env = to_expr env old_type tl in
          (cont, env)
    in
    to_expr env (loc, tunit) stmts

  and convert_block ?(ret = true) env stmts =
    convert_block_annot ~ret env None stmts

  and disambiguate_uses env loc annot path = function
    | Ast.Local_use (_, id, tl) ->
        disambiguate_uses env loc annot (Path.append id path) tl
    | Var (_, id) -> convert_var env loc (Path.append id path)
    | expr ->
        let env = Env.use_module env loc path in
        convert_annot env annot expr
end

and Records : Recs.S = Recs.Make (Core)
and Patternmatch : Pm.S = Pm.Make (Core) (Records)

let block_external_name loc ~cname id =
  (* We have to deal with shadowing: If there is no function with the same name,
     we make sure all future function use different names internally (via
     [uniq_tbl]). If there already is a function, there is nothing we can do
     right now, so we error *)
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
      let env, typ = type_record ~in_sgn:true env loc t in
      let m = Module.add_type_sig loc t.name.name typ m in
      (env, m)
  | Stypedef (loc, Talias (name, type_spec)) ->
      let env, typ = type_alias ~in_sgn:true env loc name type_spec in
      let m = Module.add_type_sig loc name.name typ m in
      (env, m)
  | Stypedef (loc, Tvariant v) ->
      let env, typ = type_variant ~in_sgn:true env loc v in
      let m = Module.add_type_sig loc v.name.name typ m in
      (env, m)
  | Stypedef (loc, Tabstract a) ->
      let env, typ = type_abstract env loc a in
      let m = Module.add_type_sig loc a.name typ m in
      (env, m)
  | Svalue _ -> (env, m)

let add_signature_vals env m = function
  | Ast.Svalue (loc, ((l, n), type_spec)) ->
      (* Here, we don't add to env. We later check that the declaration is
         implemented correctly, in [validate_signature] *)
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
           ^ string_of_type (Env.modpath env) e.typ ))
  in
  if is_weak ~sub e.typ then _raise ();
  match e.expr with
  | Var _ | Const _ | Lambda _ -> ()
  | Bop (_, e1, e2) | Set (e1, e2, _) | Sequence (e1, e2) ->
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
      (* Check that argument to [funptr] or [clsptr] is a function type. We
         cannot test this in [convert_app], because typechecking isn't done
         there yet. An unbound type var might be a function later. *)
      (match Typed_tree.follow_expr callee.expr with
      | Some
          ( Var (("__unsafe_funptr" | "__unsafe_clsptr"), None)
          | Var (("funptr" | "clsptr"), Some (Path.Pid "unsafe")) ) -> (
          let fst_arg = List.hd args |> fst in
          match repr fst_arg.typ with
          | Tfun _ -> ()
          | t ->
              print_endline ("t: " ^ show_typ t);
              raise (Error (fst_arg.loc, "Expecting a function type")))
      | _ -> ());
      catch_weak_expr env sub callee;
      List.iter (fun a -> catch_weak_expr env sub (fst a)) args
  | Record fs -> List.iter (fun f -> catch_weak_expr env sub (snd f)) fs
  | Ctor _ -> ()
  | Fmt fmt ->
      List.iter
        (function Fstr _ -> () | Fexpr e -> catch_weak_expr env sub e)
        fmt

let check_module_annot env loc ~mname m annot =
  match annot with
  | Some path -> (
      match Env.find_module_type_opt loc path env with
      | Some (base, mtype) ->
          let mtype =
            Module_type.adjust_for_checking ~base ~with_:mname mtype
          in
          Module.validate_intf env ~mname mtype m
      | None -> raise (Error (loc, "Cannot find module type " ^ Path.show path))
      )
  | None -> ()

(* These different functors exist to factor out the [map_decl] function, which
   is used by both modules. The reason for having two (very similar) modules is
   that for [resolve_alias], we need all declarations to be present. The
   declarations are collected in the first module, and are not guarenteed to
   arrive in the order they are used. For instance, a type in a signature might
   be the first type declared, but in the module the last type defined. Hence,
   there are two split modules. One for renaming and the other one for resolving
   alisases. *)
module Sub_def = struct
  open Module_type

  type mapping = { base : Path.t; with_ : Path.t }
  type decl_map = (type_decl * Path.t) Pmap.t

  type sub =
    (decl_map -> Path.t -> (type_decl * Path.t) option)
    * mapping list
    * decl_map

  let find_function find_type declsub path =
    match Pmap.find_opt path declsub with
    | Some decl -> Some decl
    | None -> find_type path
end

module Map_decl (Subst : Map_module.Map_tree with type sub = Sub_def.sub) =
struct
  open Module_type
  include Subst

  let rec map_decl ~mname id sub decl =
    let (find, subs, dmap), kind =
      match Types.(decl.kind) with
      | Drecord (recurs, fields) ->
          let sub, fields =
            Array.fold_left_map
              (fun sub f ->
                let sub, ftyp = map_type sub f.ftyp in
                (sub, { f with ftyp }))
              sub fields
          in
          (sub, Drecord (recurs, fields))
      | Dvariant (recurs, ctors) ->
          let sub, ctors =
            Array.fold_left_map
              (fun sub ct ->
                match ct.ctyp with
                | Some typ ->
                    let sub, ctyp = map_type sub typ in
                    (sub, { ct with ctyp = Some ctyp })
                | None -> (sub, ct))
              sub ctors
          in
          (sub, Dvariant (recurs, ctors))
      | Dabstract (Some kind) ->
          let sub, decl =
            map_decl ~mname id sub
              (* Fill a dummy decl *)
              { params = []; in_sgn = true; kind }
          in
          (sub, Dabstract (Some Types.(decl.kind)))
      | Dalias typ ->
          let sub, typ = map_type sub typ in
          (sub, Dalias typ)
      | Dabstract None -> (sub, Dabstract None)
    in
    let decl = { decl with kind } in
    let path = Path.append id mname in
    let dmap = Pmap.add path (decl, path) dmap in
    ((find, subs, dmap), decl)
end

module Subst_functor_impl (* : Map_module.Map_tree *) = struct
  open Module_type
  open Sub_def

  type sub = Sub_def.sub

  let empty_sub () =
    (* Make sure the empty env is never used. We want to pass the actual env to
       look up declarations. *)
    failwith "unreachable"

  let change_var ~mname id m (_, subs, _) =
    ignore mname;
    match m with
    | Some m ->
        let p =
          List.fold_left
            (fun p { base; with_ } -> Path.subst_base ~base ~with_ p)
            m subs
        in
        (id, Some p)
    | None -> (id, m)

  let absolute_module_name = Module.absolute_module_name

  let map_type (find_type, subs, decls) typ =
    let typ =
      List.fold_left
        (fun typ { base; with_ } -> apply_pathsub ~base ~with_ typ)
        typ subs
    in
    ((find_type, subs, decls), typ)

  let map_decl ~mname id sub decl =
    ignore mname;
    ignore id;
    ignore sub;
    ignore decl;
    failwith "unreachable"
end

module Resolve_aliases_impl (* : Map_module.Map_tree *) = struct
  type sub = Sub_def.sub

  let empty_sub () =
    (* Make sure the empty env is never used. We want to pass the actual env to
       look up declarations. *)
    failwith "unreachable"

  let change_var ~mname id m _ =
    ignore mname;
    (id, m)

  let absolute_module_name = Module.absolute_module_name

  let map_type (find_type, subs, decls) typ =
    (* Use aliases if they are available *)
    let typ = resolve_alias (find_type decls) typ in
    ((find_type, subs, decls), typ)

  let map_decl ~mname id sub decl =
    ignore mname;
    ignore id;
    ignore sub;
    ignore decl;
    failwith "unreachable"
end

module Subst_functor = Map_decl (Subst_functor_impl)
module Subst = Map_module.Make (Subst_functor)
module Resolve_aliases = Map_decl (Resolve_aliases_impl)
module Aliases = Map_module.Make (Resolve_aliases)

type fn_let_kind =
  | Callname of string * bool
  (* is closure *)
  | Alias
  | Not

let let_fn_alias env loc expr =
  let mname = Env.modpath env in
  match expr.typ with
  | Tfun (_, _, Simple) -> (
      match Typed_tree.follow_expr expr.expr with
      | Some (Var (id, Some md)) -> (
          if is_polymorphic expr.typ then Alias
          else
            match Env.find_callname loc (Path.append id md) env with
            | Some callname -> Callname (callname, false)
            | None ->
                (* No callname here means it's an alias (of an alias). We
                   continue the alias chain. These aliases are binds to
                   the expression of the last alias, which eventually
                   resolve to the real thing (in monomorph_tree). *)
                Alias)
      | Some (Var (id, None)) ->
          (* Treat builtins as aliases *)
          if Builtin.of_string id |> Option.is_some then Alias else Not
      | Some (Lambda (uniq, _)) ->
          Callname (Module.lambda_name ~mname uniq, false)
      | _ -> Not)
  | Tfun (_, _, Closure _) -> (
      (* Maybe alias could also be used here. Check with other special case *)
      (* If the closure is from a different module, we can use it directly *)
      match follow_expr expr.expr with
      | Some (Var (id, Some md)) ->
          if (not (is_polymorphic expr.typ)) && not (Path.share_base md mname)
          then
            match Env.find_callname loc (Path.append id md) env with
            | Some callname -> Callname (callname, true)
            | None -> Not
          else Not
      | _ -> Not)
  | _ -> Not

let rec convert_module env mname prog check_ret =
  (* We create a new scope so we don't warn on unused uses *)
  let env = Env.open_toplevel mname env in

  (* Add types from signature for two reasons:
     1. In contrast to OCaml, we don't need to declare them two types, so they
     have to be in env
     2. We don't add vals because the implementation of abstract types is not
     known at this point. Since we substitute generics naively in annots (which
     val decls essentially are), we have to make sure the complete
     implementation is available before. *)
  let prog = convert_prog env prog Module.empty in
  let externals = Module.append_externals (Env.externals prog.env) in
  (* Make sure to chose the signature env, not the impl one. Abstract types are
     magically made complete by references. *)
  let m = List.fold_left (add_signature_vals prog.sgn_env) prog.m prog.sgn in
  let m = Module.validate_signature prog.env m in

  (* Catch weak type variables *)
  List.iter (catch_weak_vars prog.env) prog.items;

  let _, _, touched, unused = Env.close_toplevel prog.env in

  let unmutated, items =
    let get_decl = Hashtbl.find (Env.decl_tbl prog.env) in
    Exclusivity.check_items ~mname get_decl touched prog.items
  in

  let has_sign = match prog.sgn with [] -> false | _ -> true in
  if (not (is_module (Env.modpath prog.env))) || has_sign then
    check_unused prog.env unused unmutated;

  (* Program must evaluate to either int or unit *)
  (if check_ret then
     match repr prog.last_type with
     | Tconstr (Pid ("int" | "unit"), _) -> ()
     | _ ->
         let msg =
           "Module must return type int or unit, not "
           ^ string_of_type (Env.modpath prog.env) prog.last_type
         in
         raise (Error (!last_loc, msg)));
  (externals, items, m)

and convert_prog env items modul =
  let old = ref (Lexing.(dummy_pos, dummy_pos), tunit) in
  let before_stmt = ref true in
  let sgnrf = ref ([], env) in

  let rec aux (env, items, m) = function
    | Ast.Stmt stmt ->
        before_stmt := false;
        let old', env, items, m = aux_stmt (!old, env, items, m) stmt in
        old := old';
        (env, items, m)
    | Ext_decl (loc, (idloc, id), typ, cname) ->
        let typ = typeof_annot env loc typ in
        (* Make cname explicit to link the correct name even if schmu identifier
           has the module name prepended *)
        let cname = block_external_name loc ~cname id in
        let m = Module.add_external loc typ id cname ~closure:false m in
        let env =
          Env.add_external id ~cname typ idloc env
          |> Env.add_callname ~key:id (Option.get cname)
        in
        (env, items, m)
    | Typedef (loc, Trecord t) ->
        let env, typ = type_record ~in_sgn:false env loc t in
        let m = Module.add_type loc t.name.name typ m in
        (env, items, m)
    | Typedef (loc, Talias (name, type_spec)) ->
        let env, typ = type_alias ~in_sgn:false env loc name type_spec in
        let m = Module.add_type loc name.name typ m in
        (env, items, m)
    | Typedef (loc, Tvariant v) ->
        let env, typ = type_variant ~in_sgn:false env loc v in
        let m = Module.add_type loc v.name.name typ m in
        (env, items, m)
    | Typedef (loc, Tabstract _) ->
        raise (Error (loc, "Abstract types need a concrete implementation"))
    | Module ((loc, id, annot), prog) ->
        (* External function are added as side-effects, can be discarded here *)
        let open Module in
        let mname = Path.append id (Env.modpath env) in

        (* Save uniq_tbl state as well as lambda state *)
        let uniq_tbl_bk = !uniq_tbl in
        uniq_tbl := Strtbl.create 64;
        let lambda_id_state_bk = !lambda_id_state in
        reset lambda_id_state;

        let _, moditems, newm = convert_module env mname prog true in

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
        check_module_annot env loc ~mname newm annot;
        let m = add_local_module loc id newm ~into:m in

        let moditems = List.map (fun item -> (mname, item)) moditems in
        let items = Tl_module moditems :: items in
        (env, items, m)
    | Functor ((loc, id, annot), params, prog) ->
        let open Module in
        let mname = Path.append id (Env.modpath env) in

        (* Save uniq_tbl state as well as lambda state *)
        let uniq_tbl_bk = !uniq_tbl in
        uniq_tbl := Strtbl.create 64;
        let lambda_id_state_bk = !lambda_id_state in
        reset lambda_id_state;

        let params =
          List.map
            (fun (loc, id, path) ->
              match Env.find_module_type_opt loc path env with
              | Some (path, mtype) -> (id, mtype, path)
              | None ->
                  raise
                    (Error (loc, "Cannot find module type " ^ Path.show path)))
            params
        in
        let tmpenv, params =
          List.fold_left_map
            (fun env (key, mt, mtyp) ->
              let param = Path.append key mname in
              let mt =
                Module_type.adjust_for_checking ~base:mtyp ~with_:param mt
              in
              let cm = scope_of_functor_param env loc ~param mt in
              (Env.add_module ~key cm env, (key, mt)))
            env params
        in
        let _, functor_items, newm = convert_module tmpenv mname prog true in

        uniq_tbl := uniq_tbl_bk;
        lambda_id_state := lambda_id_state_bk;

        let env =
          match register_functor env loc mname params functor_items newm with
          | Ok env -> env
          | Error () ->
              let msg =
                Printf.sprintf "Module names must be unique. %s exists already"
                  id
              in
              raise (Error (loc, msg))
        in
        check_module_annot env loc ~mname newm annot;
        let m = add_functor loc id params functor_items newm ~into:m in

        (* Don't add moditems to items here. We add items of the applied functor *)
        (env, items, m)
    | Module_alias ((loc, key, annot), Amodule (aloc, mname)) ->
        let env = Env.add_module_alias loc ~key ~mname env in
        let mname = Env.find_module_opt loc (Path.Pid key) env |> Option.get in
        (if Option.is_some annot then
           match Module.of_located env mname with
           | Ok m -> check_module_annot env aloc ~mname m annot
           | Error s -> raise (Error (loc, s)));
        let m = Module.add_module_alias loc key mname ~into:m in
        (env, items, m)
    | Module_alias ((loc, id, annot), Afunctor_app ((floc, ftor), args)) -> (
        match Module.functor_data env floc ftor with
        | Ok (mname, params, body, modul) ->
            let param_arg_map = ref Module_type.Pmap.empty in
            begin
              try
                List.iter2
                  (fun (aloc, arg) param ->
                    let key = Path.append (fst param) mname in
                    match Env.find_module_opt aloc arg env with
                    | Some mname -> (
                        match Module.of_located env mname with
                        | Ok m ->
                            param_arg_map :=
                              Module_type.Pmap.add key mname !param_arg_map;
                            let mtype =
                              Module_type.adjust_for_checking ~base:key
                                ~with_:mname (snd param)
                            in
                            Module.validate_intf env ~mname mtype m
                        | Error s -> raise (Error (loc, s)))
                    | None ->
                        raise
                          (Error (aloc, "Cannot find module " ^ Path.show arg)))
                  args params
              with Invalid_argument _ ->
                let msg =
                  Printf.sprintf
                    "Wrong arity for functor %s: Expecting %i but got %i"
                    (Path.show ftor) (List.length params) (List.length args)
                in
                raise (Error (loc, msg))
            end;

            let applied_name = Path.append id (Env.modpath env) in
            (* There are two substitutions we need to make: From the functor
               parameter(s) to the actual implementation modules, e.g. from
               [make/m] to [int]. And from the functor name to the applied
               functor name, e.g. [make] to [make/int]. The two paths overlap
               (make is contained in make/m), so order is important. We first
               want to apply the paramater sub, then the functor name sub. To
               make this explicit, we are using a list. *)
            (* Add functor -> applied functor mapping *)
            let subs = { Sub_def.base = mname; with_ = applied_name } :: [] in

            let subs =
              Module_type.Pmap.fold
                (fun key value acc ->
                  Sub_def.{ base = key; with_ = value } :: acc)
                !param_arg_map subs
            in
            (* Type declarations which are defined in this functor won't be
               accessible to the [find] function. For these, we send an extra
               data structure to the mapping function to sub in the correct
               type. *)
            let find =
              let find path = Env.find_type_opt loc path env in
              Sub_def.find_function find
            in
            let subs = (find, subs, Module_type.Pmap.empty) in

            let modul, body =
              Module.with_transitive_deps (fun () ->
                  (* Split name substitution and alias resolving into separate
                     passes, because not all decls are available in order. *)
                  let subs, modul = Subst.map_module applied_name subs modul in
                  let _, modul = Aliases.map_module applied_name subs modul in
                  let body =
                    Subst.map_tl_items applied_name Smap.empty subs body |> snd
                  in
                  let body =
                    Aliases.map_tl_items applied_name Smap.empty subs body
                    |> snd
                  in
                  (modul, body))
            in
            let moditems = List.map (fun item -> (applied_name, item)) body in
            let items = Tl_module moditems :: items in
            let env =
              Module.register_applied_functor env loc id applied_name modul
            in

            check_module_annot env loc ~mname:applied_name modul annot;
            let m =
              Module.add_applied_functor loc id applied_name modul ~into:m
            in

            (env, items, m)
        | Error s -> raise (Error (loc, s)))
    | Module_type ((loc, id), vals) ->
        (* This look a bit awkward for this use case. The split of adding first
           signature types and values after is from the way module signatures
           are used. That is, the types don't need to be duplictated in the
           module proper. *)
        let mname = Path.append id (Env.modpath env) in
        let tmpenv = Env.open_toplevel mname env in
        let sigenv, tmpm =
          List.fold_left add_signature_types (tmpenv, Module.empty) vals
        in
        let tmpm = List.fold_left (add_signature_vals sigenv) tmpm vals in
        let _ = Env.close_toplevel tmpenv in
        let mt = Module.to_module_type tmpm in
        let m = Module.add_module_type loc id mt m in
        let env = Env.add_module_type id mt env in
        (env, items, m)
    | Signature (loc, sgn) ->
        if not !before_stmt then
          raise (Error (loc, "Module signature must be declared at the top"));
        (match !sgnrf |> fst with
        | [] -> ()
        | _ -> raise (Error (loc, "Module signature must be unique")));

        let env, m = List.fold_left add_signature_types (env, m) sgn in
        sgnrf := (sgn, env);
        (env, items, m)
    | Import (loc, name) ->
        let env = Module.import_module env loc ~regeneralize name in
        (env, items, m)
  and aux_stmt (old, env, items, m) = function
    | Ast.Let (loc, decl, block) ->
        let env, id, id_loc, lhs, rmut, pats =
          Core.convert_let ~global:true env loc decl block
        in
        if is_module (Env.modpath env) && lhs.attr.mut then
          raise
            (Error (loc, "Mutable top level bindings are not allowed in modules"));
        let uniq = uniq_name id in
        let env, expr, m =
          match let_fn_alias env loc lhs with
          | Callname (callname, closure) ->
              let m =
                Module.add_external loc lhs.typ id (Some callname) ~closure m
              in
              let expr =
                match block.pattr with
                | Dnorm -> Tl_bind (id, lhs)
                | Dset | Dmut | Dmove ->
                    (* We are using another module's toplevel binding. All of
                       this should be forbidden. So we set let and let it fail
                       in the exclusivity check *)
                    Tl_let { loc; id; uniq; lhs; rmut; pass = block.pattr }
              in
              let env = Env.add_callname ~key:id callname env in
              (env, expr, m)
          | Alias ->
              let m = Module.add_alias loc id lhs m in
              (env, Tl_bind (id, lhs), m)
          | Not ->
              let uniq_name =
                Some (Module.unique_name ~mname:(Env.modpath env) id uniq)
              in
              let m =
                Module.add_external loc lhs.typ id uniq_name ~closure:true m
              in
              let pass = block.pattr in
              (env, Tl_let { loc = id_loc; id; uniq; lhs; rmut; pass }, m)
        in
        let expr =
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
          Env.(add_value name { (def_value env) with typ } nameloc env)
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
              let func =
                match typ with
                | Tfun (tparams, ret, kind) ->
                    (* Use the generalized types for the abstraction *)
                    { abs.func with tparams; ret; kind }
                | _ -> failwith "Internal Error: Is this not a function?"
              in
              let abs = { abs with func } in

              let decls, fitems, env = aux env tl in
              ((n, u, t.typ) :: decls, (l, n, u, abs) :: fitems, env)
          | [] -> ([], [], env)
        in
        let decls, fitems, env = aux env (List.rev funcs) in
        let m = Module.add_rec_block ~mname:(Env.modpath env) loc fitems m in
        let fitems =
          List.map (fun (l, n, u, abs) -> Tl_function (l, n, u, abs)) fitems
        in
        (old, env, fitems @ (Tl_mutual_rec_decls decls :: items), m)
    | Expr (loc, expr) ->
        last_loc := loc;
        let expr = Core.convert env expr in
        (* Only the last expression is allowed to return something *)
        unify
          (fst old, "Left expression in sequence must be of type unit,")
          tunit (snd old) env;
        ((loc, expr.typ), env, Tl_expr expr :: items, m)
    | Use (loc, mname) ->
        let env = Env.use_module env loc mname in
        (old, env, items, m)
  in

  let env, items, m = List.fold_left aux (env, [], modul) items in
  let sgn, sgn_env = !sgnrf in
  { last_type = snd !old; env; items = List.rev items; m; sgn; sgn_env }

(* Conversion to Typing.exr below *)
let to_typed ?(check_ret = true) ~mname msg_fn ~std prog =
  fmt_msg_fn := Some msg_fn;
  reset_type_vars ();

  let loc = Lexing.(dummy_pos, dummy_pos) in
  (* Add builtins to env *)
  let find_module = Module.find_module in
  let scope_of_located = Module.scope_of_located in

  let env =
    fold_builtins
      (fun env name decl ->
        let params = List.map regeneralize decl.params in
        Env.add_type ~append_module:false name { decl with params } env)
      (Env.empty ~find_module ~scope_of_located mname)
  in

  let env =
    Builtin.(
      fold (fun str (_, typ) env ->
          Env.(
            add_value str
              { (def_value env) with typ = regeneralize typ; mname = None }
              loc env)))
      env
  in

  (* Use prelude *)
  let env =
    if std then
      let env = Module.import_module env loc ~regeneralize "std" in
      Env.use_module env loc (Path.Pid "std")
    else env
  in

  let externals, items, m = convert_module env mname prog check_ret in

  (* Add polymorphic functions from useed modules *)
  let items = List.map (fun item -> (mname, item)) items in
  let items = List.rev !Module.poly_funcs @ items in

  let decls = Env.decl_tbl env in

  ({ externals; items; decls }, m)

let typecheck (prog : Ast.prog) =
  let rec get_last_type = function
    | (_, Tl_expr expr) :: _ -> expr.typ
    | ( _,
        ( Tl_function _ | Tl_let _ | Tl_bind _ | Tl_mutual_rec_decls _
        | Tl_module_alias _ | Tl_module _ ) )
      :: tl ->
        get_last_type tl
    | [] -> tunit
  in

  (* Ignore unused binding warnings *)
  let msg_fn _ _ _ = "" in
  let mname = main_path in
  let tree, _ = to_typed ~mname ~check_ret:false msg_fn ~std:false prog in
  let typ = get_last_type (List.rev tree.items) in
  print_endline (show_typ typ);
  typ
