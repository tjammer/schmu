open Cleaned_types
module Vars = Map.Make (String)
module Set = Set.Make (String)

module Hint = struct
  type t = int

  let equal = Int.equal
  let hash x = x
end

module Apptbl = Hashtbl.Make (Hint)

type expr =
  | Mvar of string
  | Mconst of const
  | Mbop of Ast.bop * monod_tree * monod_tree
  | Mif of ifexpr
  | Mlet of string * monod_tree * monod_tree
  | Mlambda of string * abstraction
  | Mfunction of string * abstraction * monod_tree
  | Mapp of {
      callee : monod_expr;
      args : monod_expr list;
      alloca : alloca;
      malloc : int option;
      id : int;
    }
  | Mrecord of (string * monod_tree) list * alloca
  | Mfield of (monod_tree * int)
  | Mfield_set of (monod_tree * int * monod_tree)
  | Mseq of (monod_tree * monod_tree)
  | Mfree_after of monod_tree * int
[@@deriving show]

and const =
  | Int of int
  | Bool of bool
  | Unit
  | U8 of char
  | String of string * alloca
  | Vector of int * monod_tree list * alloca

and func = { params : typ list; ret : typ; kind : fun_kind }
and abstraction = { func : func; pnames : string list; body : monod_tree }

and call_name =
  | Mono of string
  | Concrete of string
  | Default
  | Recursive of string
  | Builtin of Builtin.t * func

and monod_expr = { ex : monod_tree; monomorph : call_name }
and monod_tree = { typ : typ; expr : expr; return : bool }
and alloca = allocas ref
and allocas = Preallocated | Request of int
and ifexpr = { cond : monod_tree; e1 : monod_tree; e2 : monod_tree }

type recurs = Rnormal | Rtail | Rnone
type func_name = { user : string; call : string }
type to_gen_func = { abs : abstraction; name : func_name; recursive : recurs }
type external_decl = string * typ

type monomorphized_tree = {
  externals : external_decl list;
  records : typ list;
  tree : monod_tree;
  funcs : to_gen_func list;
}

type to_gen_func_kind =
  | Concrete of to_gen_func * string
  | Polymorphic of to_gen_func
  | Forward_decl of string
  | Builtin of Builtin.t
  | No_function

type alloc = Value of alloca | Two_values of alloc * alloc | No_value
type malloc_kind = Return_value | Local
type malloc = { id : int; kind : malloc_kind ref }
type var = { fn : to_gen_func_kind; alloc : alloc; malloc : malloc option }

type morph_param = {
  vars : var Vars.t;
  monomorphized : Set.t;
  funcs : to_gen_func list; (* to generate in codegen *)
  ret : bool;
  (* Marks an expression where an if is the last piece which returns a record.
     Needed for tail call elim *)
  mallocs : malloc list;
      (* Tracks all heap allocations in a scope.
         If a value with allocation is returned, they are marked for the parent scope.
         Otherwise freed *)
}

let no_var = { fn = No_function; alloc = No_value; malloc = None }
let apptbl = Apptbl.create 64

let rec extract_alloca = function
  | Value a -> Some a
  | Two_values (a, _) -> extract_alloca a
  | No_value -> None

let rec cln = function
  | Types.Tvar { contents = Link t } | Talias (_, t) -> cln t
  | Tint -> Tint
  | Tbool -> Tbool
  | Tunit -> Tunit
  | Tu8 -> Tu8
  | Qvar id | Tvar { contents = Unbound (id, _) } -> Tpoly id
  | Tfun (params, ret, kind) ->
      Tfun (List.map cln params, cln ret, cln_kind kind)
  | Trecord (param, name, fields) ->
      let param = Option.map cln param in
      let fields =
        Array.map
          (fun field ->
            { name = Types.(field.name); typ = cln field.typ; mut = field.mut })
          fields
      in
      Trecord (param, name, fields)
  | Tptr t -> Tptr (cln t)

and cln_kind = function
  | Simple -> Simple
  | Closure vals ->
      let vals = List.map (fun (name, typ) -> (name, cln typ)) vals in
      Closure vals

let typ_of_abs abs = Tfun (abs.func.params, abs.func.ret, abs.func.kind)

let func_of_typ = function
  | Tfun (params, ret, kind) -> { params; ret; kind }
  | _ -> failwith "Internal Error: Not a function type"

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)

(* For named functions *)
let unique_name = function
  | name, None -> name
  | name, Some n -> name ^ "__" ^ string_of_int n

let lambda_name id = "__fun" ^ string_of_int id

let find_function_expr vars = function
  | Mvar id -> (
      match Vars.find_opt id vars with
      | Some thing -> thing.fn
      | None -> (
          match Builtin.of_string id with
          | Some b -> Builtin b
          | None -> No_function))
  | Mconst _ | Mapp _ | Mrecord _ | Mfield _ | Mbop _ -> No_function
  | Mlambda _ -> (* Concrete type is already inferred *) No_function
  | e ->
      print_endline (show_expr e);
      "Not supported: " ^ show_expr e |> failwith

let get_mono_name name ~poly concrete =
  let rec str = function
    | Tint -> "i"
    | Tbool -> "b"
    | Tunit -> "u"
    | Tu8 -> "c"
    | Tfun (ps, r, _) ->
        Printf.sprintf "%s.%s" (String.concat "" (List.map str ps)) (str r)
    | Trecord (Some t, name, _) -> Printf.sprintf "%s%s" name (str t)
    | Trecord (_, name, _) -> name
    | Tpoly _ -> "g"
    | Tptr t -> Printf.sprintf "p%s" (str t)
  in
  Printf.sprintf "__%s_%s_%s" (str poly) name (str concrete)

let subst_type ~concrete poly parent =
  let rec inner subst = function
    | Tpoly id, t -> (
        match Vars.find_opt id subst with
        | Some _ -> (* Already in tbl*) (subst, t)
        | None -> (Vars.add id t subst, t))
    | Tfun (ps1, r1, kind), Tfun (ps2, r2, _) ->
        let subst, ps =
          List.fold_left_map
            (fun subst (l, r) -> inner subst (l, r))
            subst (List.combine ps1 ps2)
        in
        let subst, r = inner subst (r1, r2) in
        (subst, Tfun (ps, r, kind))
    | (Trecord (Some i, record, l1) as l), Trecord (Some j, _, l2)
      when is_type_polymorphic l ->
        let labels = Array.copy l1 in
        let f (subst, i) (label : Cleaned_types.field) =
          let subst, t = inner subst (label.typ, l2.(i).typ) in
          labels.(i) <- Cleaned_types.{ (labels.(i)) with typ = t };
          (subst, i + 1)
        in
        let subst, _ = Array.fold_left f (subst, 0) l1 in
        let subst, param = inner subst (i, j) in
        (subst, Trecord (Some param, record, labels))
    | Tptr l, Tptr r ->
        let subst, t = inner subst (l, r) in
        (subst, Tptr t)
    | t, _ -> (subst, t)
  in
  let vars, typ = inner Vars.empty (poly, concrete) in

  let rec subst = function
    | Tpoly id as old -> (
        match Vars.find_opt id vars with Some t -> t | None -> old)
    | Tfun (ps, r, kind) ->
        let ps = List.map subst ps in
        let kind =
          match kind with
          | Simple -> Simple
          | Closure cls -> Closure (List.map (fun (nm, t) -> (nm, subst t)) cls)
        in
        Tfun (ps, subst r, kind)
    | Trecord (Some p, record, labels) as t when is_type_polymorphic t ->
        let f field = Cleaned_types.{ field with typ = subst field.typ } in
        let labels = Array.map f labels in
        Trecord (Some (subst p), record, labels)
    | Tptr t -> Tptr (subst t)
    | t -> t
  in

  (* We might have to substitute other types (in closures) from an outer scope *)
  let subst, typ =
    match parent with
    | Some sub -> ((fun t -> subst t |> sub), sub typ)
    | None -> (subst, typ)
  in

  (subst, typ)

let rec subst_body p subst tree =
  let p = ref p in

  let subst_func { params; ret; kind } =
    let params = List.map subst params in
    let ret = subst ret in
    let kind =
      match kind with
      | Simple -> Simple
      | Closure cls -> Closure (List.map (fun (nm, typ) -> (nm, subst typ)) cls)
    in
    { params; ret; kind }
  in

  let rec inner tree =
    let sub t = { (inner t) with typ = subst t.typ } in
    match tree.expr with
    | Mvar _ -> { tree with typ = subst tree.typ }
    | Mconst _ -> tree
    | Mbop (bop, l, r) -> { tree with expr = Mbop (bop, sub l, sub r) }
    | Mif expr ->
        let cond = sub expr.cond in
        let e1 = sub expr.e1 in
        let e2 = sub expr.e2 in
        { tree with typ = e1.typ; expr = Mif { cond; e1; e2 } }
    | Mlet (id, expr, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { tree with typ = cont.typ; expr = Mlet (id, expr, cont) }
    | Mlambda (name, abs) ->
        let abs =
          { abs with func = subst_func abs.func; body = sub abs.body }
        in
        let typ = typ_of_abs abs in
        { tree with typ; expr = Mlambda (name, abs) }
    | Mfunction (name, abs, cont) ->
        let abs =
          { abs with func = subst_func abs.func; body = sub abs.body }
        in
        let cont = { (inner cont) with typ = subst cont.typ } in
        { tree with typ = cont.typ; expr = Mfunction (name, abs, cont) }
    | Mapp { callee; args; alloca; malloc; id } ->
        let ex = sub callee.ex in

        (* We use the parametrs at function creation time to deal with scope *)
        let old_p =
          match Apptbl.find_opt apptbl id with
          | Some old ->
              { old with funcs = !p.funcs; monomorphized = !p.monomorphized }
          | None -> failwith "Internal Error: No old param"
        in

        let p2, monomorph = monomorphize_call old_p ex (Some subst) in

        let callee = { ex; monomorph } in
        p := { !p with funcs = p2.funcs; monomorphized = p2.monomorphized };

        let args = List.map (fun arg -> { arg with ex = sub arg.ex }) args in
        let func = func_of_typ callee.ex.typ in
        {
          tree with
          typ = func.ret;
          expr = Mapp { callee; args; alloca; malloc; id };
        }
    | Mrecord (labels, alloca) ->
        let labels = List.map (fun (name, expr) -> (name, sub expr)) labels in
        { tree with typ = subst tree.typ; expr = Mrecord (labels, alloca) }
    | Mfield (expr, index) ->
        { tree with typ = subst tree.typ; expr = Mfield (sub expr, index) }
    | Mfield_set (expr, index, value) ->
        {
          tree with
          typ = subst tree.typ;
          expr = Mfield_set (sub expr, index, sub value);
        }
    | Mseq (expr, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { tree with typ = cont.typ; expr = Mseq (expr, cont) }
    | Mfree_after (expr, id) ->
        let expr = sub expr in
        { tree with typ = expr.typ; expr = Mfree_after (expr, id) }
  in
  (!p, inner tree)

and monomorphize_call p expr parent_sub : morph_param * call_name =
  match find_function_expr p.vars expr.expr with
  | Builtin b -> (p, Builtin (b, func_of_typ expr.typ))
  | _ when is_type_polymorphic expr.typ -> (p, Default)
  | Concrete (func, username) ->
      (* If a named function gets a generated name, the call site has to be made aware *)
      if not (String.equal func.name.call username) then
        (p, Concrete func.name.call)
      else (p, Default)
  | Polymorphic func ->
      let typ = typ_of_abs func.abs in
      let call = get_mono_name func.name.call ~poly:typ expr.typ in

      if Set.mem call p.monomorphized then
        (* The function exists, we don't do anything right now *)
        (p, Mono call)
      else
        (* We generate the function *)

        (* The parent substitution is threaded through to its children.
           This deals with nested closures *)
        let subst, typ = subst_type ~concrete:expr.typ typ parent_sub in

        (* If the type is still polymorphic, we cannot generate it *)
        if is_type_polymorphic typ then (p, Default)
        else
          let p, body = subst_body p subst func.abs.body in

          let fnc = func_of_typ typ in
          let name = { func.name with call } in
          let funcs =
            { func with abs = { func.abs with func = fnc; body }; name }
            :: p.funcs
          in
          let monomorphized = Set.add call p.monomorphized in
          ({ p with funcs; monomorphized }, Mono call)
  | No_function -> (p, Default)
  | Forward_decl name ->
      (* We don't have to do anything, because the correct function will be called in the first place.
         Except when it is called with different types recursively. We'll see *)
      (p, Recursive name)

(* State *)

let alloc_lvl = ref 1
let enter_level () = incr alloc_lvl
let leave_level () = decr alloc_lvl
let request () = Request !alloc_lvl
let malloc_id = ref 1

let new_id () =
  let id = !malloc_id in
  incr malloc_id;
  id

let reset () =
  alloc_lvl := 1;
  malloc_id := 1

let rec set_alloca = function
  | Value ({ contents = Request lvl } as a) when lvl >= !alloc_lvl ->
      a := Preallocated
  | Two_values (a, b) ->
      set_alloca a;
      set_alloca b
  | Value _ | No_value -> ()

let propagate_malloc = function
  | Some { id = _; kind } -> kind := Return_value
  | None -> ()

let free_mallocs body mallocs =
  (* Filter out the returned alloc (if it exists), free the rest
     then mark returned one local for next scope *)
  let f { id; kind } body =
    match kind with
    | { contents = Local } ->
        (* The tree should behave the same to the outer world, so we copy type and return field *)
        { body with expr = Mfree_after (body, id) }
    | { contents = Return_value } -> body
  in

  List.fold_right f mallocs body

let recursion_stack = ref []

let pop_recursion_stack () =
  match !recursion_stack with
  | hd :: tl ->
      recursion_stack := tl;
      snd hd
  | [] -> failwith "Internal Error: Recursion stack empty (pop)"

let set_tailrec name =
  match !recursion_stack with
  (* We have to check the name (of the function) here, because
     a nested function could call recursively its parent *)
  | (nm, _) :: tl when String.equal name nm ->
      recursion_stack := (nm, Rtail) :: tl
  | _ :: _ -> ()
  | [] -> failwith "Internal Error: Recursion stack empty (set)"

let rec morph_expr param (texpr : Typing.typed_expr) =
  let make expr return = { typ = cln texpr.typ; expr; return } in
  match texpr.expr with
  | Typing.Var v -> morph_var make param v
  | Const (String s) -> morph_string make param s
  | Const (Vector v) -> morph_vector make param v
  | Const c -> (param, make (Mconst (morph_const c)) false, no_var)
  | Bop (bop, e1, e2) -> morph_bop make param bop e1 e2
  | If (cond, e1, e2) -> morph_if make param cond e1 e2
  | Let (id, e1, e2) -> morph_let make param id e1 e2
  | Record labels -> morph_record make param labels
  | Field (expr, index) -> morph_field make param expr index
  | Field_set (expr, index, value) ->
      morph_field_set make param expr index value
  | Sequence (expr, cont) -> morph_seq make param expr cont
  | Function (name, uniq, abs, cont) -> morph_func param (name, uniq, abs, cont)
  | Lambda (id, abs) -> morph_lambda texpr.typ param id abs
  | App { callee; args } -> morph_app make param callee args

and morph_var mk p v =
  let alloca =
    match Vars.find_opt v p.vars with Some thing -> thing | None -> no_var
  in
  (p, mk (Mvar v) p.ret, alloca)

and morph_string mk p s =
  let alloca = ref (request ()) in
  ( p,
    mk (Mconst (String (s, alloca))) p.ret,
    { no_var with fn = No_function; alloc = Value alloca } )

and morph_vector mk p v =
  let ret = p.ret in
  (* We want to discard any inner mallocs.
     They will be cleaned up when this vector is freed at runtime *)
  let old_mallocs = p.mallocs in
  let p = { p with ret = false } in

  (* ret = false is threaded through p *)
  enter_level ();
  (* vectors are free recursively, we don't need to track the items here *)
  let f param e =
    let p, e, var = morph_expr param e in
    (* (In codegen), we provide the data ptr to the initializers to construct inplace *)
    set_alloca var.alloc;
    (p, e)
  in
  let p, v = List.fold_left_map f p v in
  leave_level ();
  let alloca = ref (request ()) in

  let id = new_id () in
  let malloc = { id; kind = ref Local } in
  let mallocs = malloc :: old_mallocs in

  ( { p with ret; mallocs },
    mk (Mconst (Vector (id, v, alloca))) p.ret,
    { fn = No_function; alloc = Value alloca; malloc = Some malloc } )

and morph_const = function
  | String _ | Vector _ -> failwith "Internal Error: Const should be extra case"
  | Int i -> Int i
  | Bool b -> Bool b
  | Unit -> Unit
  | U8 c -> U8 c

and morph_bop mk p bop e1 e2 =
  let ret = p.ret in
  (* The returning expr is bop, not one of the operands *)
  let p, e1, _ = morph_expr { p with ret = false } e1 in
  let p, e2, _ = morph_expr { p with ret = false } e2 in
  ({ p with ret }, mk (Mbop (bop, e1, e2)) ret, no_var)

and morph_if mk p cond e1 e2 =
  let ret = p.ret in
  let p, cond, _ = morph_expr { p with ret = false } cond in
  let p, e1, a = morph_expr { p with ret } e1 in
  let p, e2, b = morph_expr { p with ret } e2 in
  ( p,
    mk (Mif { cond; e1; e2 }) ret,
    { a with alloc = Two_values (a.alloc, b.alloc) } )

and morph_let mk p id e1 e2 =
  let ret = p.ret in
  let p, e1, func = morph_expr { p with ret = false } e1 in
  let p = { p with vars = Vars.add id func p.vars } in
  let p, e2, func = morph_expr { p with ret } e2 in
  (p, mk (Mlet (id, e1, e2)) ret, func)

and morph_record mk p labels =
  let ret = p.ret in
  let p = { p with ret = false } in

  (* ret = false is threaded through p *)
  enter_level ();

  (* We only need to track if there are some mallocs, not each one individually *)
  let fst_malloc other = function Some m -> Some m | None -> other in

  (* Collect mallocs in initializer *)
  let f (param, malloc) (id, e) =
    let p, e, var = morph_expr param e in
    (match e.typ with Trecord _ -> set_alloca var.alloc | _ -> ());
    ((p, fst_malloc var.malloc malloc), (id, e))
  in
  let (p, malloc), labels = List.fold_left_map f (p, None) labels in
  leave_level ();

  let alloca = ref (request ()) in
  ( { p with ret },
    mk (Mrecord (labels, alloca)) ret,
    { fn = No_function; alloc = Value alloca; malloc } )

and morph_field mk p expr index =
  let ret = p.ret in
  let p, e, func = morph_expr { p with ret = false } expr in
  ({ p with ret }, mk (Mfield (e, index)) ret, func)

and morph_field_set mk p expr index value =
  let ret = p.ret in
  let p, e, _ = morph_expr { p with ret = false } expr in
  let p, v, func = morph_expr p value in

  (* TODO handle this in morph_call, where realloc drops the old ptr and adds the new one to the free list *)
  (* If we mutate a ptr with realloced ptr, the old one is already freed and we drop it from
     the free list *)
  ({ p with ret }, mk (Mfield_set (e, index, v)) ret, func)

and morph_seq mk p expr cont =
  let ret = p.ret in
  let p, expr, _ = morph_expr { p with ret = false } expr in
  let p, cont, func = morph_expr { p with ret } cont in
  (p, mk (Mseq (expr, cont)) ret, func)

and morph_func p (username, uniq, abs, cont) =
  (* If the function is concretely typed, we add it to the function list and
     add the usercode name to the bound variables. In the polymorphic case,
     we add the function to the bound variables, but not to the function list.
     Instead, the monomorphized instance will be added later *)
  let ftyp = Types.(Tfun (abs.tp.tparams, abs.tp.ret, abs.tp.kind)) |> cln in

  let call = unique_name (username, uniq) in
  let recursive = Rnormal in

  let func =
    {
      params = List.map cln abs.tp.tparams;
      ret = cln abs.tp.ret;
      kind = cln_kind abs.tp.kind;
    }
  in
  let pnames = abs.nparams in

  let ret = p.ret in
  (* Make sure recursion works and the current function can be used in its body *)
  let temp_p =
    recursion_stack := (call, recursive) :: !recursion_stack;
    let alloc =
      match abs.tp.ret with
      | Trecord _ -> Value (ref (request ()))
      | _ -> No_value
    in
    let value = { no_var with fn = Forward_decl call; alloc } in
    let vars = Vars.add username value p.vars in
    { p with vars; ret = true; mallocs = [] }
  in

  enter_level ();
  let temp_p, body, var = morph_expr temp_p abs.body in
  leave_level ();

  (match body.typ with
  | Trecord _ ->
      set_alloca var.alloc;
      propagate_malloc var.malloc
  | _ -> ());

  let body = free_mallocs body temp_p.mallocs in

  let recursive = pop_recursion_stack () in

  let abs = { func; pnames; body } in
  let name = { user = username; call } in
  let gen_func = { abs; name; recursive } in

  (* Collect functions from body *)
  let p =
    { p with monomorphized = temp_p.monomorphized; funcs = temp_p.funcs }
  in
  let p =
    if is_type_polymorphic ftyp then
      let fn = Polymorphic gen_func in
      let vars = Vars.add username { var with fn } p.vars in
      { p with vars }
    else
      let fn = Concrete (gen_func, username) in
      let vars = Vars.add username { var with fn } p.vars in
      let funcs = gen_func :: p.funcs in
      { p with vars; funcs }
  in

  let p, cont, func = morph_expr { p with ret } cont in
  (p, { typ = cont.typ; expr = Mfunction (call, abs, cont); return = ret }, func)

and morph_lambda typ p id abs =
  let typ = cln typ in

  let name = lambda_name id in
  let recursive = Rnone in
  let func =
    {
      params = List.map cln abs.tp.tparams;
      ret = cln abs.tp.ret;
      kind = cln_kind abs.tp.kind;
    }
  in
  let pnames = abs.nparams in

  let ret = p.ret in
  let vars = p.vars in
  recursion_stack := (name, recursive) :: !recursion_stack;
  let tmp, body, var = morph_expr { p with ret = true } abs.body in

  (* Collect functions from body *)
  enter_level ();
  let p = { p with monomorphized = tmp.monomorphized; funcs = tmp.funcs } in
  leave_level ();

  (match abs.tp.ret with Trecord _ -> set_alloca var.alloc | _ -> ());

  (* Why do we need this again in lambda? They can't recurse. TODO answer *)
  ignore (pop_recursion_stack ());

  let abs = { func; pnames; body } in
  (* lambdas have no username, so we just repeat the call name *)
  let names = { call = name; user = name } in
  let gen_func = { abs; name = names; recursive } in

  let p = { p with vars } in
  let p, fn =
    if is_type_polymorphic typ then (p, Polymorphic gen_func)
    else
      let funcs = gen_func :: p.funcs in
      ({ p with funcs }, Concrete (gen_func, name))
  in
  ( { p with ret },
    { typ; expr = Mlambda (name, abs); return = ret },
    { var with fn } )

and morph_app mk p callee args =
  (* Save env for later monomorphization *)
  let id = new_id () in
  Apptbl.add apptbl id p;

  let ret = p.ret in
  let p, ex, var = morph_expr { p with ret = false } callee in
  let p, monomorph = monomorphize_call p ex None in
  let callee = { ex; monomorph } in

  let malloc, p =
    match var.malloc with
    | Some _ ->
        let malloc = { id = new_id (); kind = ref Local } in
        (Some malloc, { p with mallocs = malloc :: p.mallocs })
    | None -> (None, p)
  in

  (if ret then
   match callee.monomorph with Recursive name -> set_tailrec name | _ -> ());

  let f p arg =
    let p, ex, _ = morph_expr p arg in
    let p, monomorph = monomorphize_call p ex None in
    (p, { ex; monomorph })
  in
  let p, args = List.fold_left_map f p args in

  let alloc, alloc_ref =
    match callee.ex.typ with
    | Tfun (_, Trecord _, _) -> (
        ( var.alloc,
          match extract_alloca var.alloc with
          | Some alloca -> alloca
          | None -> ref (request ()) ))
    | _ -> (No_value, ref (request ()))
  in

  let app =
    let malloc = Option.map (fun m -> m.id) malloc in
    Mapp { callee; args; alloca = alloc_ref; malloc; id }
  in
  ({ p with ret }, mk app ret, { no_var with alloc; malloc })

let monomorphize { Typing.externals; records; tree } =
  reset ();
  let param =
    {
      vars = Vars.empty;
      monomorphized = Set.empty;
      funcs = [];
      ret = false;
      mallocs = [];
    }
  in
  let p, tree, _ = morph_expr param tree in

  let tree = free_mallocs tree p.mallocs in

  let externals = List.map (fun (n, t) -> (n, cln t)) externals in
  let records = List.map cln records in

  (* TODO maybe try to catch memory leaks? *)
  { externals; records; tree; funcs = p.funcs }
