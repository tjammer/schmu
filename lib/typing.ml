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
and const = Int of int | Bool of bool | Unit | Char of char | String of string
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
    | Tbool | Tunit | Tint | Trecord _ | Tchar -> acc
    | Tptr t -> inner acc t
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
    | Tchar -> "char"
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
    | Tptr t -> Printf.sprintf "ptr(%s)" (string_of_type t)
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
      | Tptr l, Tptr r -> unify l r
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
    | Ty_id "char" -> Tchar
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
    | lst -> container_t lst
  and container_t lst =
    match lst with
    | [] -> failwith "Internal Error: Type record list should not be empty"
    | [ t ] -> concrete_type t
    | Ty_id "ptr" :: tl ->
        let nested = container_t tl in
        Tptr nested
    | hd :: tl -> (
        match concrete_type hd with
        | (Trecord (Some (Qvar id), _, _) as t)
        | (Trecord (Some (Tvar { contents = Unbound (id, _) }), _, _) as t) ->
            let nested = container_t tl in
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

let array_assoc_opt name arr =
  let rec inner i =
    if i = Array.length arr then None
    else
      let nm, value = arr.(i) in
      if String.equal nm name then Some value else inner (i + 1)
  in
  inner 0

let assoc_opti qkey arr =
  let rec aux i =
    if i < Array.length arr then
      let key, value = arr.(i) in
      if String.equal qkey key then Some (i, value) else aux (i + 1)
    else None
  in
  aux 0

let get_record_type env labels annot =
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
          | Some t -> Env.query_type ~instantiate t.record env
          | None ->
              "Internal Error: Something went very wrong in record creation"
              |> failwith))

let rec typeof env expr = typeof_annotated env None expr

and typeof_annotated env annot = function
  | Ast.Var (loc, v) -> typeof_var env loc v
  | Lit (_, Int _) -> Tint
  | Lit (_, Bool _) -> Tbool
  | Lit (_, Char _) -> Tchar
  | Lit (_, String _) -> Tptr Tchar
  | Lambda (loc, id, ret_annot, e) -> typeof_abs env loc id ret_annot e
  | App (loc, e1, e2) -> typeof_app ~switch_uni:false env loc e1 e2
  | If (loc, cond, e1, e2) -> typeof_if env loc cond e1 e2
  | Bop (loc, bop, e1, e2) -> typeof_bop env loc bop e1 e2
  | Record (loc, labels) -> typeof_record env loc annot labels
  | Field (loc, expr, id) -> typeof_field env loc expr id
  | Pipe_head (loc, e1, e2) -> typeof_pipe_head env loc e1 e2
  | Pipe_tail (loc, e1, e2) -> typeof_pipe_tail env loc e1 e2

and typeof_var env loc v =
  (* find_opt would work here, but we use query for consistency with convert_var *)
  match Env.query_opt v env with
  | Some t -> instantiate t
  | None -> raise (Error (loc, "No var named " ^ v))

and typeof_let env loc (id, type_annot) e1 =
  enter_level ();
  let type_e =
    match type_annot with
    | None ->
        let type_e = typeof env e1 in
        leave_level ();
        generalize type_e
    | Some annot ->
        let type_annot = typeof_annot env loc annot in
        let type_e = typeof_annotated env (Some type_annot) e1 in
        leave_level ();
        unify (loc, "") type_annot type_e;
        type_annot
  in
  Env.add_value id type_e env

and typeof_abs env loc params ret_annot body =
  enter_level ();
  let env, params_t, qparams, ret_annot =
    handle_params env loc params ret_annot
  in
  let type_e = typeof_block env body in
  leave_level ();

  match Tfun (params_t, type_e, Simple) with
  | Tfun (_, ret, kind) as typ ->
      let ret = match ret_annot with Some ret -> ret | None -> ret in
      let qtyp = Tfun (qparams, ret, kind) in
      unify (loc, "Function annot") typ qtyp;
      typ
  | _ -> failwith "Internal Error Tfun not Tfun"

and typeof_function env loc Ast.{ name; params; return_annot; body } =
  (* this loc might not be correct *)
  (* typeof_let env loc name (Lambda (loc, param, body)) cont *)
  enter_level ();

  (* Recursion allowed for named funcs *)
  let env = Env.add_value name (newvar ()) env in
  let body_env, params_t, qparams, ret_annot =
    handle_params env loc params return_annot
  in
  let bodytype = typeof_block body_env body in
  leave_level ();
  Tfun (params_t, bodytype, Simple) |> generalize |> function
  | Tfun (_, ret, kind) as typ ->
      unify (loc, "") (Env.find name env) typ;
      let ret = match ret_annot with Some ret -> ret | None -> ret in
      let qtyp = Tfun (qparams, ret, kind) |> generalize in
      unify (loc, "Function annot") typ qtyp;
      env
  | _ -> failwith "Internal Error: Tfun not Tfun"

and typeof_app ~switch_uni env loc e1 args =
  let type_fun = typeof env e1 in
  let type_args = List.map (typeof env) args in
  let type_res = newvar () in
  if switch_uni then
    unify (loc, "") (Tfun (type_args, type_res, Simple)) type_fun
  else unify (loc, "") type_fun (Tfun (type_args, type_res, Simple));
  type_res

and typeof_if env loc cond e1 e2 =
  (* We can assume pred evaluates to bool and both
     branches need to evaluate to the some type *)
  let type_cond = typeof env cond in
  unify (loc, "In condition") type_cond Tbool;

  let type_e1 = typeof_block env e1 in
  let type_e2 = typeof_block env e2 in
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

and typeof_record env loc annot labels =
  let raise_ msg lname rname =
    let msg = Printf.sprintf "%s field %s on record %s" msg lname rname in
    raise (Error (loc, msg))
  in

  let t = get_record_type env labels annot in

  let typ =
    (* NOTE this is copied from convert_record below. We don't find out missing fields here *)
    match t with
    | Trecord (param, name, ls) ->
        let f (lname, expr) =
          let typ, expr =
            match array_assoc_opt lname ls with
            | None -> raise_ "Unbound" lname name
            | Some (Tvar { contents = Unbound _ } as typ) ->
                (* If the variable is generic, we figure the type out normally and the
                   unify for the later fields *)
                (typ, typeof_annotated env None expr)
            | Some (Tvar { contents = Link typ }) | Some typ ->
                (typ, typeof_annotated env (Some typ) expr)
          in
          unify (loc, "In record expression:") typ expr;
          (lname, expr)
        in
        ignore (List.map f labels);
        Trecord (param, name, ls)
    | t ->
        "Internal Error: Expected a record type, not " ^ string_of_type t
        |> failwith
  in
  typ |> generalize

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
      | Some { record; index } -> (
          let record_t = Env.find_type record env |> instantiate in
          unify (loc, "Field access of record " ^ record ^ ":") record_t t;
          match record_t with
          | Trecord (_, _, labels) ->
              let ret = labels.(index) |> snd in
              ret
          | _ -> failwith "nope")
      | None -> raise (Error (loc, "Unbound field " ^ id)))

and typeof_pipe_head env loc e1 e2 =
  let switch_uni = true in
  match e2 with
  | App (_, callee, args) ->
      (* Add e1 to beginnig of args *)
      typeof_app ~switch_uni env loc callee (e1 :: args)
  | _ ->
      (* Should be a lone id, if not we let it fail in _app *)
      typeof_app ~switch_uni env loc e2 [ e1 ]

and typeof_pipe_tail env loc e1 e2 =
  let switch_uni = true in
  match e2 with
  | App (_, callee, args) ->
      (* Add e1 to beginnig of args *)
      typeof_app ~switch_uni env loc callee (args @ [ e1 ])
  | _ ->
      (* Should be a lone id, if not we let it fail in _app *)
      typeof_app ~switch_uni env loc e2 [ e1 ]

and typeof_block env (loc, stmts) =
  let check (loc, typ) =
    unify (loc, "Left expression in sequence must be of type unit:") Tunit typ
  in

  let rec to_expr env old_type = function
    | [ Ast.Let (loc, _, _) ] | [ Function (loc, _) ] ->
        raise (Error (loc, "Block must end with an expression"))
    | Let (loc, decl, expr) :: tl ->
        let env = typeof_let env loc decl expr in
        to_expr env old_type tl
    | Function (loc, func) :: tl ->
        let env = typeof_function env loc func in
        to_expr env old_type tl
    | [ Expr (_, e) ] ->
        check old_type;
        typeof env e
    | Expr (loc, e) :: tl ->
        check old_type;
        to_expr env (loc, typeof env e) tl
    | [] -> raise (Error (loc, "Block cannot be empty"))
  in
  to_expr env (loc, Tunit) stmts

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
  typeof_block env prog.block |> canonize (Strtbl.create 16)

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

let rec convert env expr = convert_annot env None expr

and convert_annot env annot = function
  | Ast.Var (loc, id) -> convert_var env loc id
  | Lit (_, Int i) -> { typ = Tint; expr = Const (Int i) }
  | Lit (_, Bool b) -> { typ = Tbool; expr = Const (Bool b) }
  | Lit (_, Char c) -> { typ = Tchar; expr = Const (Char c) }
  | Lit (_, String s) -> { typ = Tptr Tchar; expr = Const (String s) }
  | Lambda (loc, id, ret_annot, e) -> convert_lambda env loc id ret_annot e
  | App (loc, e1, e2) -> convert_app ~switch_uni:false env loc e1 e2
  | Bop (loc, bop, e1, e2) -> convert_bop env loc bop e1 e2
  | If (loc, cond, e1, e2) -> convert_if env loc cond e1 e2
  | Record (loc, labels) -> convert_record env loc annot labels
  | Field (loc, expr, id) -> convert_field env loc expr id
  | Pipe_head (loc, e1, e2) -> convert_pipe_head env loc e1 e2
  | Pipe_tail (loc, e1, e2) -> convert_pipe_tail env loc e1 e2

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
      let t = convert_annot env (Some t_annot) expr in
      leave_level ();
      unify (loc, "In let binding:") t_annot t.typ;
      { t with typ = t_annot }

and convert_let env loc (id, type_annot) e1 =
  let e1 = typeof_annot_decl env loc type_annot e1 in
  (Env.add_value id e1.typ env, e1)

and convert_lambda env loc params ret_annot body =
  let env = Env.new_scope env in
  enter_level ();
  ignore ret_annot;
  let env, params_t, qparams, ret_annot =
    handle_params env loc params ret_annot
  in

  let body = convert_block env body in
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

and convert_function env loc Ast.{ name; params; return_annot; body } =
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
  let body = convert_block body_env body in
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

      (env, (name, unique, lambda))
  | _ -> failwith "Internal Error: generalize produces a new type?"

and convert_app ~switch_uni env loc e1 args =
  let callee = convert env e1 in

  let typed_exprs = List.map (convert env) args in
  let args_t = List.map (fun a -> a.typ) typed_exprs in
  let res_t = newvar () in
  if switch_uni then
    unify (loc, "Application:") callee.typ (Tfun (args_t, res_t, Simple))
  else unify (loc, "Application:") (Tfun (args_t, res_t, Simple)) callee.typ;

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
  let type_e1 = convert_block env e1 in
  let type_e2 = convert_block env e2 in
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

and convert_record env loc annot labels =
  let raise_ msg lname rname =
    let msg = Printf.sprintf "%s field %s on record %s" msg lname rname in
    raise (Error (loc, msg))
  in

  let t = get_record_type env labels annot in

  let (param, name, labels), labels_expr =
    match t with
    | Trecord (param, name, ls) ->
        let f (lname, expr) =
          let typ, expr =
            match array_assoc_opt lname ls with
            | None -> raise_ "Unbound" lname name
            | Some (Tvar { contents = Unbound _ } as typ) ->
                (* If the variable is generic, we figure the type out normally and the
                   unify for the later fields *)
                (typ, convert_annot env None expr)
            | Some (Tvar { contents = Link typ }) | Some typ ->
                (typ, convert_annot env (Some typ) expr)
          in
          unify (loc, "In record expression:") typ expr.typ;
          (lname, expr)
        in
        let labels_expr = List.map f labels in
        ((param, name, ls), labels_expr)
    | t ->
        "Internal Error: Expected a record type, not " ^ string_of_type t
        |> failwith
  in

  (* We sort the labels to appear in the defined order *)
  let sorted_labels =
    List.map
      (fun (lname, _) ->
        ( lname,
          match List.assoc_opt lname labels_expr with
          | Some thing -> thing
          | None -> raise_ "Missing" lname name ))
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
      | Some { index; record } -> (
          let record_t = Env.find_type record env |> instantiate in
          unify (loc, "Field access of " ^ string_of_type record_t) record_t t;
          match record_t with
          | Trecord (_, _, labels) ->
              let typ = labels.(index) |> snd in

              { typ; expr = Field (expr, index) }
          | _ -> failwith "nope")
      | None -> raise (Error (loc, "Unbound field " ^ id)))

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

and convert_block env (loc, stmts) =
  let check (loc, typ) =
    unify (loc, "Left expression in sequence must be of type unit:") Tunit typ
  in

  let rec to_expr env old_type = function
    | [ Ast.Let (loc, _, _) ] | [ Function (loc, _) ] ->
        raise (Error (loc, "Block must end with an expression"))
    | Let (loc, decl, expr) :: tl ->
        let env, texpr = convert_let env loc decl expr in
        let cont = to_expr env old_type tl in
        { typ = cont.typ; expr = Let (fst decl, texpr, cont) }
    | Function (loc, func) :: tl ->
        let env, (name, unique, lambda) = convert_function env loc func in
        let cont = to_expr env old_type tl in
        { typ = cont.typ; expr = Function (name, unique, lambda, cont) }
    | [ Expr (_, e) ] ->
        check old_type;
        convert env e
    | Expr (l1, e1) :: tl ->
        check old_type;
        let expr = convert env e1 in
        let cont = to_expr env (l1, expr.typ) tl in
        { typ = cont.typ; expr = Sequence (expr, cont) }
    | [] -> raise (Error (loc, "Block cannot be empty"))
  in
  to_expr env (loc, Tunit) stmts

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

  let tree = convert_block vars prog.block in
  let records = Env.records vars in

  (* print_endline (String.concat ", " (List.map string_of_type records)); *)
  { externals; records; tree }
