open Types

type expr =
  | Var of string
  | Const of const
  | Bop of Ast.bop * typed_expr * typed_expr
  | If of typed_expr * typed_expr * typed_expr
  | Let of string * typed_expr * typed_expr
  | Lambda of int * abstraction
  | Function of string * int option * abstraction * typed_expr
  | App of { callee : typed_expr; args : typed_expr list }
  | Record of (string * typed_expr) list
  | Field of (typed_expr * int)
  | Sequence of (typed_expr * typed_expr)
[@@deriving show]

and typed_expr = { typ : typ; expr : expr }
and const = Int of int | Bool of bool | Unit
and fun_pieces = { tparams : typ list; ret : typ; kind : fun_kind }
and abstraction = { nparams : string list; body : typed_expr; tp : fun_pieces }
and generic_fun = { concrete : fun_pieces; generic : fun_pieces }

type external_decl = string * typ

type codegen_tree = {
  externals : external_decl list;
  records : typ list;
  tree : typed_expr;
}

exception Error of Ast.loc * string

module Strset = Set.Make (String)

module Str = struct
  type t = string

  let hash = Hashtbl.hash
  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)

(*
   Module state
 *)

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
    | Tvar { contents = Link t } -> inner acc t
    | Tvar _ -> failwith "annot should not be here"
    | Trecord (Some t, _, _) -> inner acc t
    | Tfun (params, ret, _) ->
        let acc = List.fold_left inner acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Trecord _ -> acc
  in
  inner false typ

(* Bring type vars into canonical form so the first one is "'a" etc.
   Only used for printing purposes *)
let canonize tbl typ =
  (* To have type variables starting from 'a' *)
  let max_in_tbl =
    Strtbl.fold (fun _ v acc -> v |> int_of_string |> max acc) tbl 0
  in
  let tname = ref max_in_tbl in
  let names = Strtbl.create 4 in
  let num_to_char num =
    let id = int_of_string num in
    id + Char.code 'a' |> Char.chr |> String.make 1
  in
  let get_name str =
    match Strtbl.find_opt names str with
    | Some name -> Char.chr (name + Char.code 'a') |> String.make 1
    | None ->
        let name = !tname in
        incr tname;
        Strtbl.add names str name;
        Char.chr (name + Char.code 'a') |> String.make 1
  in

  let rec inner = function
    | Qvar str -> (
        match Strtbl.find_opt tbl str with
        | Some id -> Qvar (num_to_char id)
        | None -> Qvar (get_name str))
    | Tvar { contents = Unbound (str, lvl) } ->
        Tvar { contents = Unbound (get_name str, lvl) }
    | Tvar { contents = Link t } -> Tvar { contents = Link (inner t) }
    | Tvar { contents = Qannot id } -> (
        (* We see if there exists a Qvar linked to our annotation *)
        let qid =
          Strtbl.fold
            (fun key v acc -> if String.equal v id then Some key else acc)
            tbl None
        in
        match qid with
        | Some t -> inner (Qvar t)
        | None -> Tvar { contents = Qannot (num_to_char id) })
    | Tfun (ts, t, kind) ->
        (* Evaluate parameters first *)
        let ts = List.map inner ts in
        Tfun (ts, inner t, kind)
    | Trecord (Some p, name, labels) ->
        let labels =
          Array.map (fun (label, typ) -> (label, inner typ)) labels
        in
        Trecord (Some (inner p), name, labels)
    | t -> t
  in
  inner typ

let string_of_type typ =
  (* To deal with brackets for functions *)
  let to_name name = "'" ^ name in
  let rec string_of_type = function
    | Tint -> "int"
    | Tbool -> "bool"
    | Tunit -> "unit"
    | Tfun (ts, t, _) -> (
        match ts with
        | [ p ] ->
            Printf.sprintf "%s -> %s" (string_of_type p) (string_of_type t)
        | ts ->
            let ts = String.concat ", " (List.map string_of_type ts) in
            Printf.sprintf "(%s) -> %s" ts (string_of_type t))
    | Tvar { contents = Unbound (str, _) } -> to_name str
    | Tvar { contents = Link t } -> string_of_type t
    | Tvar { contents = Qannot id } -> Printf.sprintf "'%s" id
    | Qvar str -> to_name str
    | Trecord (param, str, _) ->
        str
        ^ Option.fold ~none:""
            ~some:(fun param -> Printf.sprintf "(%s)" (string_of_type param))
            param
  in

  string_of_type typ

let rec occurs tvr = function
  | Tvar tvr' when tvr == tvr' -> failwith "Internal error: Occurs check failed"
  | Tvar ({ contents = Unbound (id, lvl') } as tv) ->
      let min_lvl =
        match !tvr with Unbound (_, lvl) -> min lvl lvl' | _ -> lvl'
      in
      tv := Unbound (id, min_lvl)
  | Tvar { contents = Link ty } -> occurs tvr ty
  | Tfun (param_ts, t, _) ->
      List.iter (occurs tvr) param_ts;
      occurs tvr t
  | _ -> ()

let arity (loc, pre) thing la lb =
  let msg =
    Printf.sprintf "%s Arity in %s: Expected type %i but got type %i" pre thing
      la lb
  in
  raise (Error (loc, msg))

exception Unify
exception Arity of string * int * int

let unify_raw tbl t1 t2 =
  let rec unify t1 t2 =
    if t1 == t2 then ()
    else
      match (t1, t2) with
      | Tvar { contents = Link t1 }, t2 | t2, Tvar { contents = Link t1 } ->
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
            raise
              (Arity ("function", List.length params_l, List.length params_r)))
      | Trecord (param1, n1, labels1), Trecord (param2, n2, labels2) ->
          if String.equal n1 n2 then
            let () =
              match (param1, param2) with
              | Some param1, Some param2 ->
                  ignore param1;
                  ignore param2;
                  ()
              | None, None -> ()
              | None, Some p2 | Some p2, None ->
                  ignore p2;
                  raise Unify
            in

            (* We ignore the label names for now *)
            try Array.iter2 (fun a b -> unify (snd a) (snd b)) labels1 labels2
            with Invalid_argument _ ->
              raise
                (Arity ("record", Array.length labels1, Array.length labels2))
          else raise Unify
      | (Qvar id as t), Tvar ({ contents = Qannot a_id } as tv)
      | Tvar ({ contents = Qannot a_id } as tv), (Qvar id as t) -> (
          match Strtbl.find_opt tbl id with
          | Some annot_id ->
              (* [Qvar id] has already been part of annotating. We make sure the annotation was the same *)
              if String.equal annot_id a_id then (
                occurs tv t;
                tv := Link t)
              else raise Unify
          | None ->
              (* We see [Qvar id] for the first time and link our [a_id] to it *)
              Strtbl.add tbl id a_id;
              occurs tv t;
              tv := Link t)
      | Qvar id1, Qvar id2 when String.equal id1 id2 ->
          (* We need this for annotation unification *)
          ()
      | _ -> raise Unify
  in
  unify t1 t2

let unify info t1 t2 =
  (* print_endline (show_typ t1); *)
  (* print_endline (show_typ t2); *)
  (* print_newline (); *)
  let annot_tbl = Strtbl.create 1 in
  try unify_raw annot_tbl t1 t2 with
  | Unify ->
      let loc, pre = info in
      let msg =
        Printf.sprintf "%s Expected type %s but got type %s" pre
          (string_of_type (canonize annot_tbl t1))
          (string_of_type (canonize annot_tbl t2))
      in
      raise (Error (loc, msg))
  | Arity (thing, l1, l2) -> arity info thing l1 l2

let rec generalize = function
  | Tvar { contents = Unbound (id, l) } when l > !current_level -> Qvar id
  | Tvar { contents = Link t } -> generalize t
  | Tfun (t1, t2, k) -> Tfun (List.map generalize t1, generalize t2, k)
  | Trecord (Some t, name, labels) ->
      (* Hopefully the param type is the same reference throughout the record *)
      let param = Some (generalize t) in
      let f (name, typ) = (name, generalize typ) in
      let labels = Array.map f labels in
      Trecord (param, name, labels)
  | t -> t

let instantiate t =
  let rec aux subst = function
    | Qvar id -> (
        match Env.find_opt id subst with
        | Some t -> (t, subst)
        | None ->
            let tv = newvar () in
            (tv, Env.add_value id tv subst))
    | Tvar { contents = Link t } -> aux subst t
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
            (fun (name, t) ->
              let t, subst' = aux !subst t in
              subst := subst';
              (name, t))
            labels
        in
        let param, subst = aux !subst param in
        (Trecord (Some param, name, labels), subst)
    | t -> (t, subst)
  in
  aux Env.empty t |> fst

let string_of_bop = function
  | Ast.Plus -> "+"
  | Mult -> "*"
  | Less -> "<"
  | Equal -> "=="
  | Minus -> "-"

let typeof_annot ?(typedef = false) env loc annot =
  let find t tick =
    match Env.find_type_opt t env with
    | Some t -> t
    | None -> raise (Error (loc, "Unbound type " ^ tick ^ t ^ "."))
  in
  let str_id_to_int str =
    let id = str.[0] |> Char.code in
    id - Char.code 'a' |> string_of_int
  in

  let rec subst ~id typ = function
    | Tvar { contents = Link t } -> subst ~id typ t
    | (Qvar id' | Tvar { contents = Unbound (id', _) }) when String.equal id id'
      ->
        typ
    | Tfun (ps, ret, kind) ->
        let ps = List.map (subst ~id typ) ps in
        let ret = subst ~id typ ret in
        Tfun (ps, ret, kind)
    | Trecord (Some p, name, labels) ->
        let f (name, t) = (name, subst ~id typ t) in
        let labels = Array.map f labels in
        Trecord (Some (subst ~id typ p), name, labels)
    | t -> t
  in

  let rec concrete_type = function
    | Ast.Ty_id "int" -> Tint
    | Ty_id "bool" -> Tbool
    | Ty_id "unit" -> Tunit
    | Ty_id t -> find t ""
    | Ty_var id when typedef -> find id "'"
    | Ty_var id ->
        (* I'm not sure what this should be. For the whole function annotations,
           Qannot worked, but does not for param ones *)
        Tvar (ref (Qannot (str_id_to_int id)))
    | Ty_func l -> handle_annot l
    | Ty_list l -> type_list l
  and type_list = function
    | [] -> failwith "Internal Error: Type param list should not be empty"
    | [ t ] -> (
        match concrete_type t with
        | Trecord (Some (Qvar _), name, _) ->
            raise (Error (loc, "Type " ^ name ^ " needs a type parameter"))
        | t -> t)
    | lst -> nested_record lst
  and nested_record lst =
    match lst with
    | [] -> failwith "Internal Error: Type record list should not be empty"
    | [ t ] -> concrete_type t
    | hd :: tl -> (
        match concrete_type hd with
        | (Trecord (Some (Qvar id), _, _) as t)
        | (Trecord (Some (Tvar { contents = Unbound (id, _) }), _, _) as t) ->
            let nested = nested_record tl in
            subst ~id nested t
        | t ->
            raise
              (Error
                 (loc, "Expected a parametrized type, not " ^ string_of_type t))
        )
  and handle_annot = function
    | [] -> failwith "Internal Error: Type annot list should not be empty"
    | [ t ] -> concrete_type t
    | [ Ast.Ty_id "unit"; t ] -> Tfun ([], concrete_type t, Simple)
    | [ Ast.Ty_list [ Ast.Ty_id "unit" ]; t ] ->
        Tfun ([], concrete_type t, Simple)
    (* TODO 'Simple' here is not always true *)
    (* For function definiton and application, 'unit' means an empty list.
       It's easier for typing and codegen to treat unit as a special case here *)
    | l -> (
        (* We reverse the list times :( *)
        match List.rev l with
        | last :: head ->
            Tfun
              ( List.map concrete_type (List.rev head),
                concrete_type last,
                Simple )
        | [] -> failwith ":)")
  in
  handle_annot annot

let handle_params env loc params ret =
  (* return updated env with bindings for parameters and types of parameters *)
  let rec handle = function
    | Tvar { contents = Qannot _ } as t -> (newvar (), t)
    | Tfun (params, ret, kind) ->
        let params, qparams = List.map handle params |> List.split in
        let ret, qret = handle ret in
        (Tfun (params, ret, kind), Tfun (qparams, qret, kind))
    | t -> (t, t)
  in

  List.fold_left_map
    (fun env (id, type_annot) ->
      let type_id, qparams =
        match type_annot with
        | None ->
            let t = newvar () in
            (t, t)
        | Some annot -> handle (typeof_annot env loc annot)
      in
      (Env.add_value id type_id env, (type_id, qparams)))
    env params
  |> fun (env, lst) ->
  let ids, qparams = List.split lst in
  let ret = Option.map (fun t -> typeof_annot env loc [ t ]) ret in
  (env, ids, qparams, ret)

let get_record_type env loc typed_labels =
  (* TODO rewrite this whole thing to make it more workable *)
  let possible_records =
    List.fold_left
      (fun set (label, _) ->
        match Env.find_label_opt label env with
        | Some lbl ->
            (* We try to unify later, not here *)
            Strset.add lbl.record set
        | None -> raise (Error (loc, "Unbound record field " ^ label)))
      Strset.empty typed_labels
  in

  (* And get specialized type out if it exists *)
  let unify_labels labels name =
    Array.iter
      (fun (rlabel, rtype) ->
        let ltype =
          let msg =
            Printf.sprintf "Missing field %s on record %s" rlabel name
          in
          match List.assoc_opt rlabel typed_labels with
          | Some thing -> thing
          | None -> raise (Error (loc, msg))
        in

        unify (loc, "") rtype ltype)
      labels
  in
  let get_record_content = function
    | Trecord (param, name, labels) -> (param, name, labels)
    | _ -> failwith "Internal Error not a record"
  in

  match Strset.elements possible_records with
  | [] -> failwith "Internal Error not a record"
  | [ record ] ->
      let record = Env.query_type ~instantiate record env in
      let param, name, labels = get_record_content record in
      unify_labels labels name;
      (param, name, labels)
  | lst ->
      (* We choose the correct one by finding the first record where all labels fit  *)
      (* There must be better ways to do this *)
      let record =
        List.fold_left
          (fun chosen record ->
            let record = Env.query_type ~instantiate record env in
            let all_match =
              match record with
              | Trecord (_, _, labels) ->
                  Array.fold_left
                    (fun mtch (lname, _) ->
                      mtch
                      && List.exists
                           (fun (tlname, _) -> String.equal lname tlname)
                           typed_labels)
                    true labels
              | _ -> failwith "Internal Error in typeof_record"
            in
            if all_match then Some record else chosen)
          None lst
        |> Option.get
      in
      let param, name, labels = get_record_content record in
      unify_labels labels name;
      (param, name, labels)

let assoc_opti qkey arr =
  let rec aux i =
    if i < Array.length arr then
      let key, value = arr.(i) in
      if String.equal qkey key then Some (i, value) else aux (i + 1)
    else None
  in
  aux 0

let rec typeof env = function
  | Ast.Var (loc, v) -> typeof_var env loc v
  | Int (_, _) -> Tint
  | Bool (_, _) -> Tbool
  | Let (loc, x, e1, e2) -> typeof_let env loc x e1 e2
  | Lambda (loc, id, ret_annot, e) -> typeof_abs env loc id ret_annot e
  | Function (loc, { name; params; return_annot; body; cont }) ->
      typeof_function env loc name params return_annot body cont
  | App (loc, e1, e2) -> typeof_app env loc e1 e2
  | If (loc, cond, e1, e2) -> typeof_if env loc cond e1 e2
  | Bop (loc, bop, e1, e2) -> typeof_bop env loc bop e1 e2
  | Record (loc, labels) -> typeof_record env loc labels
  | Field (loc, expr, id) -> typeof_field env loc expr id
  | Sequence (loc, expr, cont) -> typeof_sequence env loc expr cont

and typeof_var env loc v =
  (* find_opt would work here, but we use query for consistency with convert_var *)
  match Env.query_opt v env with
  | Some t -> instantiate t
  | None -> raise (Error (loc, "No var named " ^ v))

and typeof_let env loc (id, type_annot) e1 e2 =
  enter_level ();
  let type_e =
    match type_annot with
    | None ->
        let type_e = typeof env e1 in
        leave_level ();
        generalize type_e
    | Some annot ->
        let type_annot = typeof_annot env loc annot in
        let type_e = typeof env e1 in
        leave_level ();
        unify (loc, "") type_annot type_e;
        type_annot
  in
  typeof (Env.add_value id type_e env) e2

and typeof_abs env loc params ret_annot e =
  enter_level ();
  let env, params_t, qparams, ret_annot =
    handle_params env loc params ret_annot
  in
  let type_e = typeof env e in
  leave_level ();

  match Tfun (params_t, type_e, Simple) with
  | Tfun (_, ret, kind) as typ ->
      let ret = match ret_annot with Some ret -> ret | None -> ret in
      let qtyp = Tfun (qparams, ret, kind) in
      unify (loc, "Function annot") typ qtyp;
      typ
  | _ -> failwith "Internal Error Tfun not Tfun"

and typeof_function env loc name params ret_annot body cont =
  (* this loc might not be correct *)
  (* typeof_let env loc name (Lambda (loc, param, body)) cont *)
  enter_level ();

  (* Recursion allowed for named funcs *)
  let env = Env.add_value name (newvar ()) env in
  ignore ret_annot;
  let body_env, params_t, qparams, ret_annot =
    handle_params env loc params ret_annot
  in
  let bodytype = typeof body_env body in
  leave_level ();
  Tfun (params_t, bodytype, Simple) |> generalize |> function
  | Tfun (_, ret, kind) as typ ->
      unify (loc, "") (Env.find name env) typ;
      let ret = match ret_annot with Some ret -> ret | None -> ret in
      let qtyp = Tfun (qparams, ret, kind) |> generalize in
      unify (loc, "Function annot") typ qtyp;
      typeof env cont
  | _ -> failwith "Internal Error: Tfun not Tfun"

and typeof_app env loc e1 args =
  let type_fun = typeof env e1 in
  let type_args = List.map (typeof env) args in
  let type_res = newvar () in
  unify (loc, "") type_fun (Tfun (type_args, type_res, Simple));
  type_res

and typeof_if env loc cond e1 e2 =
  (* We can assume pred evaluates to bool and both
     branches need to evaluate to the some type *)
  let type_cond = typeof env cond in
  unify (loc, "In condition") type_cond Tbool;

  let type_e1 = typeof env e1 in
  let type_e2 = typeof env e2 in
  let type_res = newvar () in

  unify (loc, "Branches have different type") type_e1 type_e2;
  unify (loc, "") type_res type_e2;
  type_res

and typeof_bop env loc bop e1 e2 =
  let check () =
    (* both exprs must be Int, not Bool *)
    let t1 = typeof env e1 in
    let t2 = typeof env e2 in
    unify (loc, "Binary " ^ string_of_bop bop) t1 Tint;
    unify (loc, "Binary " ^ string_of_bop bop) t2 Tint
  in

  match bop with
  | Plus | Mult | Minus ->
      check ();
      Tint
  | Less | Equal ->
      check ();
      Tbool

and typeof_record env loc labels =
  (* TODO pass in expected type? *)
  (* We build a list of possible records by label and type.
     If we're lucky, there's only one left *)
  let typed_labels =
    List.map (fun (label, expr) -> (label, typeof env expr)) labels
  in
  let param, name, labels = get_record_type env loc typed_labels in
  Trecord (param, name, labels) |> generalize

and typeof_field env loc expr id =
  let typ = typeof env expr in
  (* This expr could be a fresh var, in which case we take the record type from the label,
     or it could be a specific record type in which case we have to get that certain record *)
  match typ with
  | Trecord (_, name, labels) -> (
      (* This is a poor replacement for List.assoc_opt *)
      let find_id acc (name, t) =
        if String.equal id name then Some t else acc
      in
      match Array.fold_left find_id None labels with
      | Some t -> t
      | None ->
          raise (Error (loc, "Unbound field " ^ id ^ " on record " ^ name)))
  | t -> (
      match Env.find_label_opt id env with
      | Some { typ = _; record; index } -> (
          (* TODO typ above could link straight to the record label? *)
          let record_t = Env.find_type record env |> instantiate in
          unify (loc, "Field access of record " ^ record ^ ":") record_t t;
          match record_t with
          | Trecord (_, _, labels) ->
              let ret = labels.(index) |> snd in
              ret
          | _ -> failwith "nope")
      | None -> raise (Error (loc, "Unbound field " ^ id)))

and typeof_sequence env loc expr cont =
  let t1 = typeof env expr in
  unify (loc, "Left expression in sequence must be type unit:") Tunit t1;
  typeof env cont

let extern_vars decls =
  let externals =
    List.map
      (fun (loc, name, typ) -> (name, typeof_annot Env.empty loc typ))
      decls
  in
  List.fold_left
    (fun vars (name, typ) -> Env.add_value name typ vars)
    Env.empty externals

let typedefs typedefs env =
  List.fold_left
    (fun env Ast.{ poly_param; name; labels; loc } ->
      let labels, param =
        let env, param =
          match poly_param with
          | Some name ->
              (* TODO get rid off this and move to add_record *)
              let t = Qvar (gensym ()) in
              (Env.add_type name t env, Some t)
          | None -> (env, None)
        in
        (* TODO we need to make sure all parametrized vars are the same as the parent's *)
        let labels =
          Array.map
            (fun (lbl, type_expr) ->
              let t = typeof_annot ~typedef:true env loc type_expr in
              (* Does this work? *)
              (lbl, t))
            labels
        in
        (labels, param)
      in
      Env.add_record name ~param ~labels env)
    env typedefs

let typecheck (prog : Ast.prog) =
  reset_type_vars ();
  let env = extern_vars prog.external_decls |> typedefs prog.typedefs in
  typeof env prog.expr |> canonize (Strtbl.create 1)

(* Conversion to Typing.exr below *)

(* TODO Error handling sucks right now *)
let dont_allow_closure_return loc fn =
  let rec error_on_closure = function
    | Tfun (_, _, Closure _) ->
        raise (Error (loc, "Cannot (yet) return a closure"))
    | Tvar { contents = Link typ } -> error_on_closure typ
    | _ -> ()
  in
  error_on_closure fn

let needs_capture env var =
  let rec aux = function
    | Tfun (_, _, Simple) -> None
    | Tvar { contents = Link typ } -> aux typ
    | t -> Some (var, t)
  in
  aux (Env.find var env)

let rec param_funcs_as_closures = function
  | Tvar { contents = Link t } ->
      (* This shouldn't break type inference *) param_funcs_as_closures t
  | Tfun (_, _, Closure _) as t -> t
  | Tfun (params, ret, _) -> Tfun (params, ret, Closure [])
  | t -> t

let rec convert env = function
  | Ast.Var (loc, id) -> convert_var env loc id
  | Int (_, i) -> { typ = Tint; expr = Const (Int i) }
  | Bool (_, b) -> { typ = Tbool; expr = Const (Bool b) }
  | Let (loc, x, e1, e2) -> convert_let env loc x e1 e2
  | Lambda (loc, id, ret_annot, e) -> convert_lambda env loc id ret_annot e
  | Function (loc, func) -> convert_function env loc func
  | App (loc, e1, e2) -> convert_app env loc e1 e2
  | Bop (loc, bop, e1, e2) -> convert_bop env loc bop e1 e2
  | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
  | Record (loc, labels) -> convert_record env loc labels
  | Field (loc, expr, id) -> convert_field env loc expr id
  | Sequence (loc, expr, cont) -> convert_sequence env loc expr cont

and convert_var env loc id =
  match Env.query_opt id env with
  | Some t ->
      let typ = instantiate t in
      { typ; expr = Var id }
  | None -> raise (Error (loc, "No var named " ^ id))

and typeof_annot_decl env loc annot expr =
  enter_level ();
  match annot with
  | None ->
      let t = convert env expr in
      leave_level ();
      { t with typ = generalize t.typ }
  | Some annot ->
      let t_annot = typeof_annot env loc annot in
      let t = convert env expr in
      leave_level ();
      unify (loc, "") t_annot t.typ;
      { t with typ = t_annot }

and convert_let env loc (id, type_annot) e1 e2 =
  let typ1 = typeof_annot_decl env loc type_annot e1 in

  let typ2 = convert (Env.add_value id typ1.typ env) e2 in
  { typ = typ2.typ; expr = Let (id, typ1, typ2) }

and convert_lambda env loc params ret_annot e =
  let env = Env.new_scope env in
  enter_level ();
  ignore ret_annot;
  let env, params_t, qparams, ret_annot =
    handle_params env loc params ret_annot
  in

  let body = convert env e in
  leave_level ();
  let env, closed_vars = Env.close_scope env in
  let kind =
    match List.filter_map (needs_capture env) closed_vars with
    | [] -> Simple
    | lst -> Closure lst
  in
  dont_allow_closure_return loc body.typ;

  (* For codegen: Mark functions in parameters closures *)
  let params_t = List.map param_funcs_as_closures params_t in

  let typ = Tfun (params_t, body.typ, kind) in
  match typ with
  | Tfun (tparams, ret, kind) ->
      let ret = match ret_annot with Some ret -> ret | None -> ret in
      let qtyp = Tfun (qparams, ret, kind) in
      unify (loc, "Function annot") typ qtyp;

      let nparams = List.map fst params in
      let tp = { tparams; ret; kind } in
      let abs = { nparams; body = { body with typ = ret }; tp } in
      let expr = Lambda (lambda_id (), abs) in
      { typ; expr }
  | _ -> failwith "Internal Error: generalize produces a new type?"

and convert_function env loc { name; params; return_annot; body; cont } =
  (* Create a fresh type var for the function name
     and use it in the function body *)
  let unique = next_func name func_tbl in

  enter_level ();
  let env =
    (* Recursion allowed for named funcs *)
    Env.add_value name (newvar ()) env
  in

  (* We duplicate some lambda code due to naming *)
  let env = Env.new_scope env in
  ignore return_annot;
  let body_env, params_t, qparams, ret_annot =
    handle_params env loc params return_annot
  in
  let body = convert body_env body in
  leave_level ();

  let env, closed_vars = Env.close_scope env in
  let kind =
    match List.filter_map (needs_capture env) closed_vars with
    | [] -> Simple
    | lst -> Closure lst
  in
  dont_allow_closure_return loc body.typ;

  (* For codegen: Mark functions in parameters closures *)
  let params_t = List.map param_funcs_as_closures params_t in

  let typ = Tfun (params_t, body.typ, kind) |> generalize in

  match typ with
  | Tfun (tparams, ret, kind) ->
      (* Make sure the types match *)
      unify (loc, "Function") (Env.find name env) typ;
      let ret = match ret_annot with Some ret -> ret | None -> ret in
      let qtyp = Tfun (qparams, ret, kind) |> generalize in
      unify (loc, "Function annot") typ qtyp;

      let nparams = List.map fst params in
      let tp = { tparams; ret; kind } in
      let lambda = { nparams; body = { body with typ = ret }; tp } in
      (* Continue, see let *)
      let typ2 = convert env cont in
      { typ = typ2.typ; expr = Function (name, unique, lambda, typ2) }
  | _ -> failwith "Internal Error: generalize produces a new type?"

and convert_app env loc e1 args =
  let callee = convert env e1 in

  let typed_exprs = List.map (convert env) args in
  let args_t = List.map (fun a -> a.typ) typed_exprs in
  let res_t = newvar () in
  unify (loc, "Application") callee.typ (Tfun (args_t, res_t, Simple));

  let apply typ texpr = { texpr with typ } in
  let targs = List.map2 apply args_t typed_exprs in

  { typ = res_t; expr = App { callee; args = targs } }

and convert_bop env loc bop e1 e2 =
  let check () =
    let t1 = convert env e1 in
    let t2 = convert env e2 in

    unify (loc, "Binary " ^ string_of_bop bop) t1.typ Tint;
    unify (loc, "Binary " ^ string_of_bop bop) t2.typ Tint;
    (t1, t2)
  in

  match bop with
  | Ast.Plus | Mult | Minus ->
      let t1, t2 = check () in
      { typ = Tint; expr = Bop (bop, t1, t2) }
  | Less | Equal ->
      let t1, t2 = check () in
      { typ = Tbool; expr = Bop (bop, t1, t2) }

and convert_if env loc cond e1 e2 =
  (* We can assume pred evaluates to bool and both
     branches need to evaluate to the some type *)
  let type_cond = convert env cond in
  unify (loc, "In condition") type_cond.typ Tbool;
  let type_e1 = convert env e1 in
  let type_e2 = convert env e2 in
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

  { typ = type_e2.typ; expr = If (type_cond, type_e1, type_e2) }

and convert_record env loc labels =
  let typed_expr_labels =
    List.map (fun (label, expr) -> (label, convert env expr)) labels
  in
  let typed_labels =
    List.map (fun (label, texp) -> (label, texp.typ)) typed_expr_labels
  in
  let param, name, labels = get_record_type env loc typed_labels in
  (* We sort the labels to appear in the defined order *)
  let sorted_labels =
    List.map
      (fun (lname, _) ->
        ( lname,
          match List.assoc_opt lname typed_expr_labels with
          | Some thing -> thing
          | None ->
              let msg =
                Printf.sprintf "Missing field %s on record %s" lname name
              in
              raise (Error (loc, msg)) ))
      (labels |> Array.to_list)
  in
  let typ = Trecord (param, name, labels) |> generalize in
  Env.maybe_add_record_instance (string_of_type typ) typ env;
  { typ; expr = Record sorted_labels }

and convert_field env loc expr id =
  let expr = convert env expr in
  match expr.typ with
  | Trecord (_, name, labels) -> (
      match assoc_opti id labels with
      | Some (index, typ) -> { typ; expr = Field (expr, index) }
      | None ->
          raise (Error (loc, "Unbound field " ^ id ^ " on record " ^ name)))
  | t -> (
      match Env.find_label_opt id env with
      | Some { typ = _; index; record } -> (
          let record_t = Env.find_type record env |> instantiate in
          unify (loc, "Field access of " ^ string_of_type record_t) record_t t;
          match record_t with
          | Trecord (_, _, labels) ->
              let typ = labels.(index) |> snd in

              { typ; expr = Field (expr, index) }
          | _ -> failwith "nope")
      | None -> raise (Error (loc, "Unbound field " ^ id)))

and convert_sequence env loc expr cont =
  let expr = convert env expr in
  unify (loc, "Left expression in sequence must be type unit:") Tunit expr.typ;
  let cont = convert env cont in
  { typ = cont.typ; expr = Sequence (expr, cont) }

let to_typed (prog : Ast.prog) =
  reset_type_vars ();
  let externals =
    let empty = Env.empty in
    List.map
      (fun (loc, name, typ) -> (name, typeof_annot empty loc typ))
      prog.external_decls
  in

  let vars =
    List.fold_left
      (fun vars (name, typ) -> Env.add_value name typ vars)
      Env.empty externals
    |> typedefs prog.typedefs
  in

  let tree = convert vars prog.expr in
  let records = Env.records vars in

  (* print_endline (String.concat ", " (List.map string_of_type records)); *)
  { externals; records; tree }
