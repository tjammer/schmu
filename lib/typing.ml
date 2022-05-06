open Types

type expr =
  | Var of string
  | Const of const
  | Bop of Ast.bop * typed_expr * typed_expr
  | Unop of Ast.unop * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of string * typed_expr * typed_expr
  | Lambda of int * abstraction
  | Function of string * int option * abstraction * typed_expr
  | App of { callee : typed_expr; args : typed_expr list }
  | Record of (string * typed_expr) list
  | Field of (typed_expr * int)
  | Field_set of (typed_expr * int * typed_expr)
  | Sequence of (typed_expr * typed_expr)
  | Ctor of (string * int * typed_expr option)
[@@deriving show]

and typed_expr = { typ : typ; expr : expr; is_const : bool }

and const =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string
  | Vector of typed_expr list
  | Unit

and func = { tparams : typ list; ret : typ; kind : fun_kind }
and abstraction = { nparams : string list; body : typed_expr; tp : func }
and generic_fun = { concrete : func; generic : func }

type external_decl = string * typ * string option

type codegen_tree = {
  externals : external_decl list;
  typedefs : typ list;
  tree : typed_expr;
}

type msg_fn = string -> Ast.loc -> string -> string

exception Error of Ast.loc * string

module Strset = Set.Make (String)

module Str = struct
  type t = string

  let hash = Hashtbl.hash
  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)
module Map = Map.Make (String)

(*
   Module state
 *)

let fmt_msg_fn : msg_fn option ref = ref None
let func_tbl = Strtbl.create 1

let next_func name tbl =
  match Strtbl.find_opt tbl name with
  | None ->
      Strtbl.add tbl name 1;
      None
  | Some n ->
      Strtbl.replace tbl name (n + 1);
      Some (n + 1)

let gensym_state = ref 0
let lambda_id_state = ref 0
let reset state = state := 0

let gensym () =
  let n = !gensym_state in
  incr gensym_state;
  string_of_int n

let lambda_id () =
  let id = !lambda_id_state in
  incr lambda_id_state;
  id

let current_level = ref 1
let reset_level () = current_level := 1

let reset_type_vars () =
  reset gensym_state;
  reset_level ();
  reset lambda_id_state

let enter_level () = incr current_level
let leave_level () = decr current_level
let newvar () = Tvar (ref (Unbound (gensym (), !current_level)))

(*
  Helper functions
*)

let is_type_polymorphic typ =
  let rec inner acc = function
    | Qvar _ | Tvar { contents = Unbound _ } -> true
    | Tvar { contents = Link t } | Talias (_, t) -> inner acc t
    | Trecord (Some t, _, _) | Tvariant (Some t, _, _) -> inner acc t
    | Tfun (params, ret, _) ->
        let acc = List.fold_left inner acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Trecord _ | Tvariant _ | Tu8 | Tfloat | Ti32 | Tf32
      ->
        acc
    | Tptr t -> inner acc t
  in
  inner false typ

let pp_to_name name = "'" ^ name

let string_of_type_raw get_name typ =
  let rec string_of_type = function
    | Tint -> "int"
    | Tbool -> "bool"
    | Tunit -> "unit"
    | Tfloat -> "float"
    | Tu8 -> "u8"
    | Ti32 -> "i32"
    | Tf32 -> "f32"
    | Tfun (ts, t, _) -> (
        match ts with
        | [ p ] ->
            Printf.sprintf "%s -> %s" (string_of_type p) (string_of_type t)
        | ts ->
            let ts = String.concat ", " (List.map string_of_type ts) in
            Printf.sprintf "(%s) -> %s" ts (string_of_type t))
    | Tvar { contents = Link t } -> string_of_type t
    | Talias (name, t) ->
        Printf.sprintf "%s = %s" name (clean t |> string_of_type)
    | Qvar str | Tvar { contents = Unbound (str, _) } -> get_name str
    | Trecord (param, str, _) | Tvariant (param, str, _) ->
        str
        ^ Option.fold ~none:""
            ~some:(fun param -> Printf.sprintf "(%s)" (string_of_type param))
            param
    | Tptr t -> Printf.sprintf "ptr(%s)" (string_of_type t)
  in

  string_of_type typ

(* Bring type vars into canonical form so the first one is "'a" etc.
   Only used for printing purposes *)
let string_of_type_get_name subst =
  let find_next_letter tbl =
    (* Find greatest letter *)
    Strtbl.fold
      (fun _ s acc ->
        let code = String.get s 0 |> Char.code in
        if code > acc then code else acc)
      tbl
      (Char.code 'a' |> fun i -> i - 1)
    |> (* Pick next letter *)
    ( + ) 1 |> Char.chr |> String.make 1
  in

  let tbl = Strtbl.of_seq (Map.to_seq subst) in
  fun name ->
    match Strtbl.find_opt tbl name with
    | Some s -> pp_to_name s
    | None ->
        let s = find_next_letter tbl in
        Strtbl.add tbl name s;
        pp_to_name s

(* Normal version, will name type vars starting from 'a *)
let string_of_type typ =
  string_of_type_raw (string_of_type_get_name Map.empty) typ

(* Version with literal type vars (for annotations) *)
let string_of_type_lit typ = string_of_type_raw pp_to_name typ

(* Version using the subst table created during comparison with annot *)
let string_of_type_subst subst typ =
  string_of_type_raw (string_of_type_get_name subst) typ

let rec occurs tvr = function
  | Tvar tvr' when tvr == tvr' -> failwith "Internal error: Occurs check failed"
  | Tvar ({ contents = Unbound (id, lvl') } as tv) ->
      let min_lvl =
        match !tvr with Unbound (_, lvl) -> min lvl lvl' | _ -> lvl'
      in
      tv := Unbound (id, min_lvl)
  | Tvar { contents = Link ty } | Talias (_, ty) -> occurs tvr ty
  | Tfun (param_ts, t, _) ->
      List.iter (occurs tvr) param_ts;
      occurs tvr t
  | _ -> ()

let arity (loc, pre) thing la lb =
  let msg =
    Printf.sprintf "%s Wrong arity for %s: Expected %i but got %i" pre thing lb
      la
  in
  raise (Error (loc, msg))

exception Unify
exception Arity of string * int * int

let rec unify t1 t2 =
  if t1 == t2 then ()
  else
    match (t1, t2) with
    | Tvar { contents = Link t1 }, t2
    | t1, Tvar { contents = Link t2 }
    | Talias (_, t1), t2
    | t1, Talias (_, t2) ->
        unify t1 t2
    | Tvar ({ contents = Unbound _ } as tv), t
    | t, Tvar ({ contents = Unbound _ } as tv) ->
        occurs tv t;
        tv := Link t
    | Tfun (params_l, l, _), Tfun (params_r, r, _) -> (
        try
          List.iter2 (fun left right -> unify left right) params_l params_r;
          unify l r
        with Invalid_argument _ ->
          raise (Arity ("function", List.length params_l, List.length params_r))
        )
    | Trecord (param1, n1, labels1), Trecord (param2, n2, labels2) ->
        if String.equal n1 n2 then
          let () =
            match (param1, param2) with
            | Some param1, Some param2 -> unify param1 param2
            | None, None -> ()
            | None, Some p2 | Some p2, None ->
                ignore p2;
                raise Unify
          in

          (* We ignore the label names for now *)
          try Array.iter2 (fun a b -> Types.(unify a.typ b.typ)) labels1 labels2
          with Invalid_argument _ ->
            raise (Arity ("record", Array.length labels1, Array.length labels2))
        else raise Unify
    | Tvariant (p1, n1, ctors1), Tvariant (p2, n2, ctors2) ->
        if String.equal n1 n2 then
          let () =
            match (p1, p2) with
            | Some param1, Some param2 -> unify param1 param2
            | None, None -> ()
            | None, Some p2 | Some p2, None ->
                ignore p2;
                raise Unify
          in

          (* We ignore the label names for now *)
          try
            Array.iter2
              (fun a b ->
                match (a.ctortyp, b.ctortyp) with
                | Some a, Some b -> unify a b
                | None, None -> ()
                | Some _, None | None, Some _ -> raise Unify)
              ctors1 ctors2
          with Invalid_argument _ ->
            raise (Arity ("variant", Array.length ctors1, Array.length ctors2))
        else raise Unify
    | Tptr l, Tptr r -> unify l r
    | Qvar a, Qvar b when String.equal a b ->
        (* We should not need this. Record instantiation? *) ()
    | _ -> raise Unify

let unify info t1 t2 =
  try unify t1 t2 with
  | Unify ->
      let loc, pre = info in
      let msg =
        Printf.sprintf "%s Expected type %s but got type %s" pre
          (string_of_type t1) (string_of_type t2)
      in
      raise (Error (loc, msg))
  | Arity (thing, l1, l2) -> arity info thing l1 l2

let rec generalize = function
  | Tvar { contents = Unbound (id, l) } when l > !current_level -> Qvar id
  | Tvar { contents = Link t } | Talias (_, t) -> generalize t
  | Tfun (t1, t2, k) -> Tfun (List.map generalize t1, generalize t2, k)
  | Trecord (Some t, name, labels) ->
      (* Hopefully the param type is the same reference throughout the record *)
      let param = Some (generalize t) in
      let f f = Types.{ f with typ = generalize f.typ } in
      let labels = Array.map f labels in
      Trecord (param, name, labels)
  | Tptr t -> Tptr (generalize t)
  | t -> t

(* TODO sibling functions *)
let instantiate t =
  let rec aux subst = function
    | Qvar id -> (
        match Map.find_opt id subst with
        | Some t -> (t, subst)
        | None ->
            let tv = newvar () in
            (tv, Map.add id tv subst))
    | Tvar { contents = Link t } -> aux subst t
    | Talias (name, t) ->
        let t, subst = aux subst t in
        (Talias (name, t), subst)
    | Tfun (params_t, t, k) ->
        let subst, params_t =
          List.fold_left_map
            (fun subst param ->
              let t, subst = aux subst param in
              (subst, t))
            subst params_t
        in
        let t, subst = aux subst t in
        (Tfun (params_t, t, k), subst)
    | Trecord (Some param, name, labels) ->
        let subst = ref subst in
        let labels =
          Array.map
            (fun f ->
              let t, subst' = aux !subst Types.(f.typ) in
              subst := subst';
              { f with typ = t })
            labels
        in
        let param, subst = aux !subst param in
        (Trecord (Some param, name, labels), subst)
    | Tvariant (Some param, name, ctors) ->
        let subst = ref subst in
        let ctors =
          Array.map
            (fun ctor ->
              let ctortyp =
                Option.map
                  (fun typ ->
                    let t, subst' = aux !subst typ in
                    subst := subst';
                    t)
                  ctor.ctortyp
              in
              { ctor with ctortyp })
            ctors
        in
        let param, subst = aux !subst param in
        (Tvariant (Some param, name, ctors), subst)
    | Tptr t ->
        let t, subst = aux subst t in
        (Tptr t, subst)
    | t -> (t, subst)
  in
  aux Map.empty t |> fst

(* Checks if types match. [~strict] means Unbound vars will not match everything.
   This is true for functions where we want to be as general as possible.
   We need to match everything for weak vars though *)
let rec types_match ?(strict = false) subst l r =
  if l == r then (subst, true)
  else
    match (l, r) with
    | Tvar { contents = Unbound _ }, _ when not strict ->
        (* Unbound vars match every type *) (subst, true)
    | Qvar l, Qvar r | Tvar { contents = Unbound (l, _) }, Qvar r -> (
        (* We always map from left to right *)
        match Map.find_opt l subst with
        | Some id when String.equal r id -> (subst, true)
        | Some _ -> (subst, false)
        | None ->
            (* We 'connect' left to right *)
            (Map.add l r subst, true))
    | Tvar { contents = Link l }, r
    | l, Tvar { contents = Link r }
    | Talias (_, l), r
    | l, Talias (_, r) ->
        types_match ~strict subst l r
    | _, Tvar { contents = Unbound _ } ->
        failwith "Internal Error: Type comparison for non-generalized types"
    | Tfun (ps_l, l, _), Tfun (ps_r, r, _) -> (
        try
          let subst, acc =
            List.fold_left2
              (fun (s, acc) l r ->
                let subst, b = types_match ~strict:true s l r in
                (subst, acc && b))
              (subst, true) ps_l ps_r
          in
          (* We don't shortcut here to match the annotations for the error message *)
          let subst, b = types_match ~strict:true subst l r in
          (subst, acc && b)
        with Invalid_argument _ -> (subst, false))
    | Trecord (pl, nl, _), Trecord (pr, nr, _)
    | Tvariant (pl, nl, _), Tvariant (pr, nr, _) ->
        (* It should be enough to compare the name (rather, the name's repr)
           and the param type *)
        if String.equal nl nr then
          match (pl, pr) with
          | Some pl, Some pr -> types_match ~strict subst pl pr
          | None, None -> (subst, true)
          | None, Some _ | Some _, None -> (subst, false)
        else (subst, false)
    | Tptr l, Tptr r -> types_match ~strict subst l r
    | _ -> (subst, false)

let check_annot loc l r =
  let subst, b = types_match Map.empty l r in
  if b then ()
  else
    let msg =
      Printf.sprintf "Var annotation: Expected type %s but got type %s"
        (string_of_type_lit r)
        (string_of_type_subst subst l)
    in
    raise (Error (loc, msg))

let check_unused = function
  | Ok () -> ()
  | Error errors ->
      let err (name, loc) =
        (Option.get !fmt_msg_fn) "warning" loc ("Unused binding " ^ name)
        |> print_endline
      in
      List.iter err errors

let string_of_bop = function
  | Ast.Plus_i -> "+"
  | Mult_i -> "*"
  | Div_i -> "/"
  | Less_i -> "<"
  | Greater_i -> ">"
  | Equal_i -> "=="
  | Minus_i -> "-"
  | Ast.Plus_f -> "+."
  | Mult_f -> "*."
  | Div_f -> ">."
  | Less_f -> "<."
  | Greater_f -> ">."
  | Equal_f -> "==."
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
      let ps = List.map (subst_generic ~id typ) ps in
      let ret = subst_generic ~id typ ret in
      Tfun (ps, ret, kind)
  | Trecord (Some p, name, labels) ->
      let f f = Types.{ f with typ = subst_generic ~id typ f.typ } in
      let labels = Array.map f labels in
      Trecord (Some (subst_generic ~id typ p), name, labels)
  | Tvariant (Some p, name, ctors) ->
      let f c =
        Types.{ c with ctortyp = Option.map (subst_generic ~id typ) c.ctortyp }
      in
      let ctors = Array.map f ctors in
      Tvariant (Some (subst_generic ~id typ p), name, ctors)
  | Tptr t -> Tptr (subst_generic ~id typ t)
  | Talias (name, t) -> Talias (name, subst_generic ~id typ t)
  | t -> t

and get_generic_id loc = function
  | Tvar { contents = Link t } | Talias (_, t) -> get_generic_id loc t
  | Trecord (Some (Qvar id), _, _)
  | Trecord (Some (Tvar { contents = Unbound (id, _) }), _, _)
  | Tvariant (Some (Qvar id), _, _)
  | Tvariant (Some (Tvar { contents = Unbound (id, _) }), _, _)
  | Tptr (Qvar id)
  | Tptr (Tvar { contents = Unbound (id, _) }) ->
      id
  | t ->
      raise
        (Error (loc, "Expected a parametrized type, not " ^ string_of_type t))

let typeof_annot ?(typedef = false) ?(param = false) env loc annot =
  let fn_kind = if param then Closure [] else Simple in

  let find t tick =
    match Env.find_type_opt t env with
    | Some t -> t
    | None -> raise (Error (loc, "Unbound type " ^ tick ^ t ^ "."))
  in

  let rec is_quantified = function
    | Trecord (Some _, name, _) -> Some name
    | Tptr _ -> Some "ptr"
    | Talias (name, t) -> (
        let cleaned = clean t in
        match is_quantified cleaned with
        | Some _ when is_type_polymorphic cleaned -> Some name
        | Some _ | None -> (* When can alias a concrete type *) None)
    | Tvar { contents = Link t } -> is_quantified t
    | _ -> None
  in

  let rec concrete_type = function
    | Ast.Ty_id "int" -> Tint
    | Ty_id "bool" -> Tbool
    | Ty_id "unit" -> Tunit
    | Ty_id "u8" -> Tu8
    | Ty_id "float" -> Tfloat
    | Ty_id "i32" -> Ti32
    | Ty_id "f32" -> Tf32
    | Ty_id t -> find t ""
    | Ty_var id when typedef -> find id "'"
    | Ty_var id ->
        (* Type annotation in function *)
        Qvar id
    | Ty_func l -> handle_annot l
    | Ty_list l -> type_list l
  and type_list = function
    | [] -> failwith "Internal Error: Type param list should not be empty"
    | [ Ty_id "ptr" ] -> raise (Error (loc, "Type ptr needs a type parameter"))
    | [ t ] -> (
        let t = concrete_type t in
        match is_quantified t with
        | Some name ->
            raise (Error (loc, "Type " ^ name ^ " needs a type parameter"))
        | None -> t)
    | lst -> container_t lst
  and container_t lst =
    match lst with
    | [] -> failwith "Internal Error: Type record list should not be empty"
    | [ t ] -> concrete_type t
    | Ty_id "ptr" :: tl ->
        let nested = container_t tl in
        Tptr nested
    | hd :: tl ->
        let t = concrete_type hd in
        let nested = container_t tl in
        let subst = subst_generic ~id:(get_generic_id loc t) nested t in

        (* Add record instance.
           A new instance could be introduced here, we have to make sure it's added b/c
           codegen struct generation depends on order *)
        (match t with
        | Trecord (Some _, _, _) | Tvariant (Some _, _, _) ->
            Env.maybe_add_type_instance (string_of_type subst) subst env
        | _ -> ());
        subst
  and handle_annot = function
    | [] -> failwith "Internal Error: Type annot list should not be empty"
    | [ t ] -> concrete_type t
    | [ Ast.Ty_id "unit"; t ] -> Tfun ([], concrete_type t, fn_kind)
    | [ Ast.Ty_list [ Ast.Ty_id "unit" ]; t ] ->
        Tfun ([], concrete_type t, fn_kind)
    (* For function definiton and application, 'unit' means an empty list.
       It's easier for typing and codegen to treat unit as a special case here *)
    | l -> (
        (* We reverse the list times :( *)
        match List.rev l with
        | last :: head ->
            Tfun
              ( List.map concrete_type (List.rev head),
                concrete_type last,
                fn_kind )
        | [] -> failwith ":)")
  in
  handle_annot annot

let handle_params env loc params ret =
  (* return updated env with bindings for parameters and types of parameters *)
  let rec handle = function
    | Qvar _ as t -> (newvar (), t)
    | Tfun (params, ret, kind) ->
        let params, qparams = List.map handle params |> List.split in
        let ret, qret = handle ret in
        (Tfun (params, ret, kind), Tfun (qparams, qret, kind))
    | t -> (t, t)
  in

  List.fold_left_map
    (fun env (loc, (idloc, id), type_annot) ->
      let type_id, qparams =
        match type_annot with
        | None ->
            let t = newvar () in
            (t, t)
        | Some annot -> handle (typeof_annot ~param:true env loc annot)
      in
      (* Might be const, but not important here *)
      ( Env.add_value id type_id ~is_const:false ~is_param:true idloc env,
        (type_id, qparams) ))
    env params
  |> fun (env, lst) ->
  let ids, qparams = List.split lst in
  let ret = Option.map (fun t -> typeof_annot env loc [ t ]) ret in
  (env, ids, qparams, ret)

let array_assoc_opt name arr =
  let rec inner i =
    if i = Array.length arr then None
    else
      let field = arr.(i) in
      if String.equal field.name name then Some field.typ else inner (i + 1)
  in
  inner 0

let assoc_opti qkey arr =
  let rec aux i =
    if i < Array.length arr then
      let field = arr.(i) in
      if String.equal qkey field.name then Some (i, field) else aux (i + 1)
    else None
  in
  aux 0

let get_record_type env loc labels annot =
  match annot with
  | Some t -> t
  | None -> (
      let labelset = List.map fst labels in
      match Env.find_labelset_opt labelset env with
      | Some t -> instantiate t
      | None -> (
          (* There is a wrong label somewhere. We get the type of the first label and let
             it fail below.
             The list can never be empty due to the grammar *)
          match Env.find_label_opt (List.hd labels |> fst) env with
          | Some t -> Env.query_type ~instantiate t.typename env
          | None ->
              let msg =
                Printf.sprintf "Cannot find record with label %s"
                  (List.hd labels |> fst)
              in
              raise (Error (loc, msg))))

let get_prelude env loc name =
  let typ =
    match Env.find_type_opt name env with
    | Some t -> t
    | None -> raise (Error (loc, "Cannot find type string. Prelude is missing"))
  in
  typ

let check_type_unique env loc name =
  match Env.find_type_opt name env with
  | Some _ ->
      let msg =
        Printf.sprintf
          "Type names in a module must be unique. %s exists already" name
      in
      raise (Error (loc, msg))
  | None -> ()

let add_type_param env = function
  | Some name ->
      let t = Qvar (gensym ()) in
      (Env.add_type name t env, Some t)
  | None -> (env, None)

let type_record env loc Ast.{ name = { poly_param; name }; labels } =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
  let labels, param =
    (* Temporarily add polymorphic type name to env *)
    let env, param = add_type_param env poly_param in
    let labels =
      Array.map
        (fun (mut, name, type_expr) ->
          let typ = typeof_annot ~typedef:true env loc type_expr in
          { name; typ; mut })
        labels
    in
    (labels, param)
  in
  Env.add_record name ~param ~labels env

let type_alias env loc { Ast.poly_param; name } type_spec =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
  (* Temporarily add polymorphic type name to env *)
  let temp_env, _ = add_type_param env poly_param in
  let typ = typeof_annot ~typedef:true temp_env loc [ type_spec ] in
  Env.add_alias name typ env

let type_variant env loc { Ast.name = { poly_param; name }; ctors } =
  (* Make sure that each type name only appears once per module *)
  check_type_unique env loc name;
  (* Temporarily add polymorphic type name to env *)
  let temp_env, param = add_type_param env poly_param in
  let ctors =
    List.map
      (fun { Ast.name = _, ctorname; typ_annot } ->
        match typ_annot with
        | None ->
            (* Just a ctor, without data *)
            { ctorname; ctortyp = None }
        | Some annot ->
            let typ = typeof_annot ~typedef:true temp_env loc [ annot ] in
            { ctorname; ctortyp = Some typ })
      ctors
    |> Array.of_list
  in
  Env.add_variant name ~param ~ctors env

let dont_allow_closure_return loc fn =
  let rec error_on_closure = function
    | Tfun (_, _, Closure _) ->
        raise (Error (loc, "Cannot (yet) return a closure"))
    | Tvar { contents = Link typ } | Talias (_, typ) -> error_on_closure typ
    | _ -> ()
  in
  error_on_closure fn

let rec param_funcs_as_closures = function
  (* Functions passed as parameters need to have an empty closure, otherwise they cannot
     be captured (see above). Kind of sucks *)
  | Tvar { contents = Link t } | Talias (_, t) ->
      (* This shouldn't break type inference *) param_funcs_as_closures t
  | Tfun (_, _, Closure _) as t -> t
  | Tfun (params, ret, _) -> Tfun (params, ret, Closure [])
  | t -> t

let convert_simple_lit typ expr = { typ; expr = Const expr; is_const = true }

let rec convert env expr = convert_annot env None expr

and convert_annot env annot = function
  | Ast.Var (loc, id) -> convert_var env loc id
  | Lit (_, Int i) -> convert_simple_lit Tint (Int i)
  | Lit (_, Bool b) -> convert_simple_lit Tbool (Bool b)
  | Lit (_, U8 c) -> convert_simple_lit Tu8 (U8 c)
  | Lit (_, Float f) -> convert_simple_lit Tfloat (Float f)
  | Lit (_, I32 i) -> convert_simple_lit Ti32 (I32 i)
  | Lit (_, F32 i) -> convert_simple_lit Tf32 (F32 i)
  | Lit (loc, String s) ->
      let typ = get_prelude env loc "string" in
      (* TODO is const, but handled differently right now *)
      { typ; expr = Const (String s); is_const = false }
  | Lit (loc, Vector vec) -> convert_vector_lit env loc vec
  | Lit (_, Unit) -> { typ = Tunit; expr = Const Unit; is_const = true }
  | Lambda (loc, id, ret_annot, e) -> convert_lambda env loc id ret_annot e
  | App (loc, e1, e2) -> convert_app ~switch_uni:false env loc e1 e2
  | Bop (loc, bop, e1, e2) -> convert_bop env loc bop e1 e2
  | Unop (loc, unop, expr) -> convert_unop env loc unop expr
  | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
  | Record (loc, labels) -> convert_record env loc annot labels
  | Field (loc, expr, id) -> convert_field env loc expr id
  | Field_set (loc, expr, id, value) -> convert_field_set env loc expr id value
  | Pipe_head (loc, e1, e2) -> convert_pipe_head env loc e1 e2
  | Pipe_tail (loc, e1, e2) -> convert_pipe_tail env loc e1 e2
  | Ctor (loc, name, args) -> convert_ctor env loc name args annot

and convert_var env loc id =
  match Env.query_val_opt id env with
  | Some t ->
      let typ = instantiate t.typ in
      { typ; expr = Var id; is_const = t.is_const }
  | None -> raise (Error (loc, "No var named " ^ id))

and convert_vector_lit env loc vec =
  let f typ expr =
    let expr = convert env expr in
    unify (loc, "In vector literal:") typ expr.typ;
    (typ, expr)
  in
  let typ, exprs = List.fold_left_map f (newvar ()) vec in

  let vector = get_prelude env loc "vector" in
  let typ = subst_generic ~id:(get_generic_id loc vector) typ vector in
  Env.maybe_add_type_instance (string_of_type typ) typ env;
  { typ; expr = Const (Vector exprs); is_const = false }

and typeof_annot_decl env loc annot block =
  enter_level ();
  match annot with
  | None ->
      let t = convert_block env block |> fst in
      leave_level ();
      (* We generalize functions, but allow weak variables for value types *)
      let typ =
        match clean t.typ with Tfun _ -> generalize t.typ | _ -> t.typ
      in
      { t with typ }
  | Some annot ->
      let t_annot = typeof_annot env loc annot in
      let t = convert_block_annot ~ret:true env (Some t_annot) block |> fst in
      leave_level ();
      (* TODO 'In let binding' *)
      check_annot loc t.typ t_annot;
      { t with typ = t_annot }

and convert_let env loc (_, (idloc, id), type_annot) block =
  let e1 = typeof_annot_decl env loc type_annot block in
  (Env.add_value id e1.typ ~is_const:e1.is_const idloc env, e1)

and convert_lambda env loc params ret_annot body =
  let env = Env.open_function env in
  enter_level ();
  ignore ret_annot;
  let env, params_t, qparams, ret_annot =
    handle_params env loc params ret_annot
  in

  let body = convert_block env body |> fst in
  leave_level ();
  let _, closed_vars, unused = Env.close_function env in
  let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
  dont_allow_closure_return loc body.typ;
  check_unused unused;

  (* For codegen: Mark functions in parameters closures *)
  let params_t = List.map param_funcs_as_closures params_t in

  let typ = Tfun (params_t, body.typ, kind) in
  match typ with
  | Tfun (tparams, ret, kind) ->
      let ret = match ret_annot with Some ret -> ret | None -> ret in
      let qtyp = Tfun (qparams, ret, kind) in
      check_annot loc typ qtyp;

      let nparams = List.map (fun (_, name, _) -> snd name) params in
      let tp = { tparams; ret; kind } in
      let abs = { nparams; body = { body with typ = ret }; tp } in
      let expr = Lambda (lambda_id (), abs) in
      { typ; expr; is_const = false }
  | _ -> failwith "Internal Error: generalize produces a new type?"

and convert_function env loc
    Ast.{ name = nameloc, name; params; return_annot; body } =
  (* Create a fresh type var for the function name
     and use it in the function body *)
  let unique = next_func name func_tbl in

  enter_level ();
  let env =
    (* Recursion allowed for named funcs *)
    Env.add_value name (newvar ()) nameloc env
  in

  (* We duplicate some lambda code due to naming *)
  let env = Env.open_function env in
  let body_env, params_t, qparams, ret_annot =
    handle_params env loc params return_annot
  in

  let body = convert_block body_env body |> fst in
  leave_level ();

  let env, closed_vars, unused = Env.close_function env in

  let kind = match closed_vars with [] -> Simple | lst -> Closure lst in
  dont_allow_closure_return loc body.typ;
  check_unused unused;

  (* For codegen: Mark functions in parameters closures *)
  let params_t = List.map param_funcs_as_closures params_t in

  let typ = Tfun (params_t, body.typ, kind) |> generalize in

  match typ with
  | Tfun (tparams, ret, kind) ->
      (* Make sure the types match *)
      unify (loc, "Function") (Env.find_val name env).typ typ;

      (* Add the generalized type to the env to keep the closure there *)
      let env = Env.change_type name typ env in

      let ret = match ret_annot with Some ret -> ret | None -> ret in
      let qtyp = Tfun (qparams, ret, kind) |> generalize in
      check_annot loc typ qtyp;

      let nparams = List.map (fun (_, name, _) -> snd name) params in
      let tp = { tparams; ret; kind } in
      let lambda = { nparams; body = { body with typ = ret }; tp } in

      (env, (name, unique, lambda))
  | _ -> failwith "Internal Error: generalize produces a new type?"

and convert_app ~switch_uni env loc e1 args =
  let callee = convert env e1 in

  let typed_exprs = List.map (convert env) args in
  let args_t = List.map (fun a -> a.typ) typed_exprs in
  let res_t = newvar () in
  if switch_uni then
    unify (loc, "Application:") (Tfun (args_t, res_t, Simple)) callee.typ
  else unify (loc, "Application:") callee.typ (Tfun (args_t, res_t, Simple));

  let apply typ texpr = { texpr with typ } in
  let targs = List.map2 apply args_t typed_exprs in

  (* For now, we don't support const functions *)
  { typ = res_t; expr = App { callee; args = targs }; is_const = false }

and convert_bop env loc bop e1 e2 =
  let check typ =
    let t1 = convert env e1 in
    let t2 = convert env e2 in

    unify (loc, "Binary " ^ string_of_bop bop) t1.typ t2.typ;
    unify (loc, "Binary " ^ string_of_bop bop) typ t1.typ;
    (t1, t2, t1.is_const && t2.is_const)
  in

  let typ, (t1, t2, is_const) =
    match bop with
    | Ast.Plus_i | Mult_i | Minus_i | Div_i -> (Tint, check Tint)
    | Less_i | Equal_i | Greater_i -> (Tbool, check Tint)
    | Plus_f | Mult_f | Minus_f | Div_f -> (Tfloat, check Tfloat)
    | Less_f | Equal_f | Greater_f -> (Tbool, check Tfloat)
    | And | Or -> (Tbool, check Tbool)
  in
  { typ; expr = Bop (bop, t1, t2); is_const }

and convert_unop env loc unop expr =
  match unop with
  | Uminus_f ->
      let e = convert env expr in
      unify (loc, "Unary -.:") Tfloat e.typ;
      { typ = Tfloat; expr = Unop (unop, e); is_const = e.is_const }
  | Uminus_i -> (
      let e = convert env expr in
      let msg = "Unary -:" in
      let expr = Unop (unop, e) in

      try
        (* We allow '-' to also work on float expressions *)
        unify (loc, msg) Tfloat e.typ;
        { typ = Tfloat; expr; is_const = e.is_const }
      with Error _ -> (
        try
          unify (loc, msg) Tint e.typ;
          { typ = Tint; expr; is_const = e.is_const }
        with Error (loc, errmsg) ->
          let pos = String.length msg + String.length ": Expected type int" in
          let post = String.sub errmsg pos (String.length errmsg - pos) in
          raise (Error (loc, "Unary -: Expected types int or float " ^ post))))

and convert_if env loc cond e1 e2 =
  (* We can assume pred evaluates to bool and both
     branches need to evaluate to the some type *)
  let type_cond = convert env cond in
  unify (loc, "In condition") type_cond.typ Tbool;
  let type_e1 = convert_block env e1 |> fst in
  let type_e2 = convert_block env e2 |> fst in
  unify (loc, "Branches have different type") type_e1.typ type_e2.typ;

  (* We don't support polymorphic lambdas in if-exprs in the monomorph backend yet *)
  (match type_e2.typ with
  | Tfun (_, _, _) as t when is_type_polymorphic t ->
      raise
        (Error
           ( loc,
             "Returning polymorphic anonymous function in if expressions is \
              not supported (yet). Sorry. You can type the function concretely \
              though." ))
  | _ -> ());

  (* Would be interesting to evaluate this at compile time,
     but I think it's not that important right now *)
  {
    typ = type_e2.typ;
    expr = If (type_cond, type_e1, type_e2);
    is_const = false;
  }

and convert_record env loc annot labels =
  let raise_ msg lname rname =
    let msg = Printf.sprintf "%s field %s on record %s" msg lname rname in
    raise (Error (loc, msg))
  in

  let t = get_record_type env loc labels annot in

  let (param, name, labels), labels_expr =
    match t with
    | Trecord (param, name, ls) ->
        let f (lname, expr) =
          let typ, expr =
            match array_assoc_opt lname ls with
            | None -> raise_ "Unbound" lname name
            | Some (Tvar { contents = Unbound _ } as typ) ->
                (* If the variable is generic, we figure the type out normally
                   and then unify for the later fields *)
                (typ, convert_annot env None expr)
            | Some (Tvar { contents = Link typ })
            | Some (Talias (_, typ))
            | Some typ ->
                (typ, convert_annot env (Some typ) expr)
          in
          unify (loc, "In record expression:") typ expr.typ;
          (lname, expr)
        in
        let labels_expr = List.map f labels in
        ((param, name, ls), labels_expr)
    | t ->
        let msg = "Expected a record type, not " ^ string_of_type t in
        raise (Error (loc, msg))
  in

  (* We sort the labels to appear in the defined order *)
  let is_const, sorted_labels =
    List.fold_left_map
      (fun is_const field ->
        let expr =
          match List.assoc_opt field.name labels_expr with
          | Some thing -> thing
          | None -> raise_ "Missing" field.name name
        in
        (* Records with mutable fields cannot be const *)
        (is_const && (not field.mut) && expr.is_const, (field.name, expr)))
      true (labels |> Array.to_list)
  in
  let typ = Trecord (param, name, labels) |> generalize in
  Env.maybe_add_type_instance (string_of_type typ) typ env;
  { typ; expr = Record sorted_labels; is_const }

and get_field env loc expr id =
  let expr = convert env expr in
  match clean expr.typ with
  | Trecord (_, name, labels) -> (
      match assoc_opti id labels with
      | Some (index, field) -> (field, expr, index)
      | None ->
          raise (Error (loc, "Unbound field " ^ id ^ " on record " ^ name)))
  | t -> (
      match Env.find_label_opt id env with
      | Some { index; typename } -> (
          let record_t = Env.find_type typename env |> instantiate in
          unify
            (loc, "Field access of record " ^ string_of_type record_t ^ ":")
            record_t t;
          match record_t with
          | Trecord (_, _, labels) -> (labels.(index), expr, index)
          | _ -> failwith "nope")
      | None -> raise (Error (loc, "Unbound field " ^ id)))

and convert_field env loc expr id =
  let field, expr, index = get_field env loc expr id in
  { typ = field.typ; expr = Field (expr, index); is_const = expr.is_const }

and convert_field_set env loc expr id value =
  let field, expr, index = get_field env loc expr id in
  let valexpr = convert env value in

  (if not field.mut then
   let msg = Printf.sprintf "Cannot mutate non-mutable field %s" field.name in
   raise (Error (loc, msg)));
  unify (loc, "Mutate field " ^ field.name ^ ":") field.typ valexpr.typ;
  { typ = Tunit; expr = Field_set (expr, index, valexpr); is_const = false }

and convert_pipe_head env loc e1 e2 =
  let switch_uni = true in
  match e2 with
  | App (_, callee, args) ->
      (* Add e1 to beginnig of args *)
      convert_app ~switch_uni env loc callee (e1 :: args)
  | _ ->
      (* Should be a lone id, if not we let it fail in _app *)
      convert_app ~switch_uni env loc e2 [ e1 ]

and convert_pipe_tail env loc e1 e2 =
  let switch_uni = true in
  match e2 with
  | App (_, callee, args) ->
      (* Add e1 to beginnig of args *)
      convert_app ~switch_uni env loc callee (args @ [ e1 ])
  | _ ->
      (* Should be a lone id, if not we let it fail in _app *)
      convert_app ~switch_uni env loc e2 [ e1 ]

and convert_ctor env loc name arg annot =
  (* This doesn't handle annotations like the record function does,
     but it's also much simpler, so we maybe don't need to. *)
  match Env.find_ctor_opt (snd name) env with
  | Some { index; typename } -> (
      (* We get the ctor type from the variant *)
      let ctor, variant =
        match Env.query_type ~instantiate typename env with
        | Tvariant (_, _, ctors) as typ -> (ctors.(index), typ)
        | _ -> failwith "Internal Error: Not a variant"
      in

      (match annot with
      | Some t -> unify (loc, "In constructor " ^ snd name ^ ":") t variant
      | None -> ());

      match (ctor.ctortyp, arg) with
      | Some typ, Some expr ->
          let texpr = convert env expr in
          unify (loc, "In constructor " ^ snd name ^ ":") typ texpr.typ;
          let expr = Ctor (typename, index, Some texpr) in

          Env.maybe_add_type_instance (string_of_type variant) variant env;
          { typ = variant; expr; is_const = texpr.is_const }
      | None, None ->
          let expr = Ctor (typename, index, None) in
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
          raise (Error (fst name, msg)))
  | None ->
      let msg = "Unbound constructor " ^ snd name in
      raise (Error (loc, msg))

and convert_block_annot ~ret env annot stmts =
  let loc = Lexing.(dummy_pos, dummy_pos) in

  let check (loc, typ) =
    unify (loc, "Left expression in sequence must be of type unit:") Tunit typ
  in

  let rec to_expr env old_type = function
    | ([ Ast.Let (loc, _, _) ] | [ Function (loc, _) ]) when ret ->
        raise (Error (loc, "Block must end with an expression"))
    | [] when ret -> raise (Error (loc, "Block cannot be empty"))
    | [] -> ({ typ = Tunit; expr = Const Unit; is_const = false }, env)
    | Let (loc, decl, block) :: tl ->
        let env, texpr = convert_let env loc decl block in
        let cont, env = to_expr env old_type tl in
        let decl = (fun (_, a, b) -> (snd a, b)) decl in
        let expr = Let (fst decl, texpr, cont) in
        ({ typ = cont.typ; expr; is_const = cont.is_const }, env)
    | Function (loc, func) :: tl ->
        let env, (name, unique, lambda) = convert_function env loc func in
        let cont, env = to_expr env old_type tl in
        let expr = Function (name, unique, lambda, cont) in
        ({ typ = cont.typ; expr; is_const = false }, env)
    | [ Expr (_, e) ] ->
        check old_type;
        (convert_annot env annot e, env)
    | Expr (l1, e1) :: tl ->
        check old_type;
        let expr = convert env e1 in
        let cont, env = to_expr env (l1, expr.typ) tl in
        ( {
            typ = cont.typ;
            expr = Sequence (expr, cont);
            is_const = cont.is_const;
          },
          env )
  in
  to_expr env (loc, Tunit) stmts

and convert_block ?(ret = true) env stmts =
  convert_block_annot ~ret env None stmts

let convert_prog ~ret prev_exprs env items =
  let rec aux expr env = function
    | [] -> (expr, env)
    | [ Ast.Block block ] -> aux_block expr env block [] ret
    | Ast.Block block :: tl -> aux_block expr env block tl false
    | Ext_decl (loc, (idloc, id), typ, cname) :: tl ->
        let typ = typeof_annot env loc typ in
        aux expr (Env.add_external id ~cname typ idloc env) tl
    | Typedef (loc, Trecord t) :: tl ->
        let env = type_record env loc t in
        aux expr env tl
    | Typedef (loc, Talias (name, type_spec)) :: tl ->
        let env = type_alias env loc name type_spec in
        aux expr env tl
    | Typedef (loc, Tvariant v) :: tl ->
        let env = type_variant env loc v in
        aux expr env tl
  and aux_block expr env block tl ret =
    (* If we are in main, we want to return a value so the outer [ret] is true.
       However, blocks before the last block cannot return so we set it to
       false temporarily *)
    let cont, env = convert_block ~ret env block in
    let expr =
      match expr with
      | None -> Some cont
      | Some expr ->
          Some
            {
              typ = cont.typ;
              expr = Sequence (expr, cont);
              is_const = cont.is_const;
            }
    in
    aux expr env tl
  in

  aux prev_exprs env items |> fun (expr, env) ->
  match expr with
  | None when ret ->
      (* If there is nothing in the program, should we error or not? *)
      (Some { typ = Tunit; expr = Const Unit; is_const = false }, env)
  | rest -> (rest, env)

(* Conversion to Typing.exr below *)
let to_typed msg_fn ~prelude (prog : Ast.prog) =
  fmt_msg_fn := Some msg_fn;
  reset_type_vars ();

  let loc = Lexing.(dummy_pos, dummy_pos) in
  (* Add builtins to env *)
  let env =
    Builtin.(
      fold (fun env b ->
          enter_level ();
          let typ = to_type b |> instantiate in
          leave_level ();
          Env.add_value (to_string b) (generalize typ) loc env))
      (Env.empty string_of_type)
  in

  (* Add prelude *)
  let prelude, env = convert_prog ~ret:false None env prelude in

  (* We create a new scope so we don't warn on unused imports *)
  let env = Env.open_function env in

  let tree, env = convert_prog ~ret:true prelude env prog in
  let typedefs = Env.typedefs env and externals = Env.externals env in

  let _, _, unused = Env.close_function env in
  check_unused unused;

  (* print_endline (String.concat ", " (List.map string_of_type typedefs)); *)
  { externals; typedefs; tree = Option.get tree }

let typecheck (prog : Ast.prog) =
  (* Ignore unused binding warnings *)
  let msg_fn _ _ _ = "" in
  let tree = to_typed msg_fn ~prelude:[] prog in
  print_endline (show_typ tree.tree.typ);
  tree.tree.typ
