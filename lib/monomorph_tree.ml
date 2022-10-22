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
  | Mvar of string * var_kind
  | Mconst of const
  | Mbop of Ast.bop * monod_tree * monod_tree
  | Munop of Ast.unop * monod_tree
  | Mif of ifexpr
  | Mlet of string * monod_tree * global_name * monod_tree
  | Mlambda of string * abstraction
  | Mfunction of string * abstraction * monod_tree
  | Mapp of {
      callee : monod_expr;
      args : monod_expr list;
      alloca : alloca;
      malloc : int option;
      id : int;
    }
  | Mrecord of (string * monod_tree) list * alloca * bool
  | Mfield of (monod_tree * int)
  | Mset of (monod_tree * monod_tree)
  | Mseq of (monod_tree * monod_tree)
  | Mfree_after of monod_tree * int
  | Mctor of (string * int * monod_tree option) * alloca * bool
  | Mvar_index of monod_tree
  | Mvar_data of monod_tree
  | Mfmt of fmt list * alloca * int
  | Mcopy of { kind : copy_kind; expr : monod_tree; nm : string }
[@@deriving show]

and const =
  | Int of int
  | Bool of bool
  | U8 of char
  | Float of float
  | I32 of int
  | F32 of float
  | String of string * alloca
  | Vector of int * monod_tree list * alloca
  | Array of monod_tree list * alloca
  | Unit

and func = { params : param list; ret : typ; kind : fun_kind }
and abstraction = { func : func; pnames : string list; body : monod_tree }

and call_name =
  | Mono of string
  | Concrete of string
  | Default
  | Recursive of string
  | Builtin of Builtin.t * func
  | Inline of string list * monod_tree

and monod_expr = { ex : monod_tree; monomorph : call_name; mut : bool }
and monod_tree = { typ : typ; expr : expr; return : bool }
and alloca = allocas ref
and request = { id : int; lvl : int }
and allocas = Preallocated | Request of request
and ifexpr = { cond : monod_tree; e1 : monod_tree; e2 : monod_tree }
and var_kind = Vnorm | Vconst | Vglobal
and global_name = string option
and fmt = Fstr of string | Fexpr of monod_tree

and copy_kind =
  | Cglobal of string
  | Cnormal of { temporary : bool; mut : bool }

type recurs = Rnormal | Rtail | Rnone
type func_name = { user : string; call : string }
type to_gen_func = { abs : abstraction; name : func_name; recursive : recurs }

type external_decl = {
  ext_name : string;
  ext_typ : typ;
  cname : string;
  c_linkage : bool;
}

type monomorphized_tree = {
  constants : (string * monod_tree * bool) list;
  globals : (string * typ * bool) list;
  externals : external_decl list;
  tree : monod_tree;
  frees : int list;
  funcs : to_gen_func list;
}

type to_gen_func_kind =
  (* TODO use a prefix *)
  | Concrete of to_gen_func * string
  | Polymorphic of to_gen_func
  | Forward_decl of string
  | Builtin of Builtin.t
  | Inline of string list * typ * monod_tree
  | No_function

type alloc = Value of alloca | Two_values of alloc * alloc | No_value
type malloc = { id : int; mlvl : int ref }
(* type malloc = Atom of malloc_item | Collection of malloc_item list *)

type var_normal = {
  fn : to_gen_func_kind;
  alloc : alloc;
  malloc : malloc option;
}

(* TODO could be used for Builtin as well *)
type var =
  | Normal of var_normal
  | Const of string
  | Global of string * var_normal * bool ref

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

let rec cln = function
  | Types.Tvar { contents = Link t } | Talias (_, t) -> cln t
  | Tint -> Tint
  | Tbool -> Tbool
  | Tunit -> Tunit
  | Tu8 -> Tu8
  | Tfloat -> Tfloat
  | Ti32 -> Ti32
  | Tf32 -> Tf32
  | Qvar id | Tvar { contents = Unbound (id, _) } -> Tpoly id
  | Tfun (params, ret, kind) ->
      Tfun (List.map cln_param params, cln ret, cln_kind kind)
  | Trecord (ps, name, fields) ->
      let ps = List.map cln ps in
      let fields =
        Array.map
          (fun field -> { ftyp = cln Types.(field.ftyp); mut = field.mut })
          fields
      in
      Trecord (ps, name, fields)
  | Tvariant (ps, name, ctors) ->
      let ps = List.map cln ps in
      let ctors =
        Array.map
          (fun ctor ->
            {
              cname = Types.(ctor.cname);
              ctyp = Option.map cln ctor.ctyp;
              index = ctor.index;
            })
          ctors
      in
      Tvariant (ps, name, ctors)
  | Traw_ptr t -> Traw_ptr (cln t)
  | Tarray t -> Tarray (cln t)

and cln_kind = function
  | Simple -> Simple
  | Closure vals ->
      let vals =
        List.map
          (fun (cl : Types.closed) ->
            { clname = cl.clname; cltyp = cln cl.cltyp; clmut = cl.clmut })
          vals
      in
      Closure vals

and cln_param p =
  let pt = cln Types.(p.pt) in
  { pt; pmut = p.pmut }

let typ_of_abs abs = Tfun (abs.func.params, abs.func.ret, abs.func.kind)

let func_of_typ = function
  | Tfun (params, ret, kind) -> { params; ret; kind }
  | _ -> failwith "Internal Error: Not a function type"

let find_function_expr vars = function
  | Mvar (id, _) -> (
      match Vars.find_opt id vars with
      | Some (Normal thing) -> thing.fn
      | Some (Global (_, thing, used)) ->
          used := true;
          thing.fn
      | Some (Const _) -> No_function
      | None -> (
          match Builtin.of_string id with
          | Some b -> Builtin b
          | None -> No_function))
  | Mconst _ | Mapp _ | Mrecord _ | Mfield _ | Mbop _ | Munop _ | Mctor _ ->
      No_function
  | Mif _ ->
      (* We are not allowing to return functions in ifs,
         b/c we cannot codegen anyway *)
      No_function
  | Mlambda _ -> (* Concrete type is already inferred *) No_function
  | Mlet _ -> No_function
  | Mfmt _ -> No_function
  | e ->
      print_endline (show_expr e);
      "Not supported: " ^ show_expr e |> failwith

let get_mono_name name ~poly concrete =
  let open Printf in
  let rec str = function
    | Tint -> "i"
    | Tbool -> "b"
    | Tunit -> "u"
    | Tu8 -> "c"
    | Tfloat -> "f"
    | Ti32 -> "i32"
    | Tf32 -> "f32"
    | Tfun (ps, r, _) ->
        sprintf "%s.%s"
          (String.concat "" (List.map (fun p -> str p.pt) ps))
          (str r)
    | Trecord (ps, Some name, _) | Tvariant (ps, name, _) ->
        sprintf "%s%s" name (String.concat "" (List.map str ps))
    | Trecord (_, None, fs) ->
        Array.to_list fs |> List.map (fun f -> str f.ftyp) |> String.concat "-"
    | Tpoly _ -> "g"
    | Traw_ptr t -> sprintf "p%s" (str t)
    | Tarray t -> sprintf "a%s" (str t)
  in
  sprintf "__%s_%s_%s" (str poly) name (str concrete)

let subst_type ~concrete poly parent =
  let rec inner subst = function
    | Tpoly id, t -> (
        match Vars.find_opt id subst with
        | Some _ -> (* Already in tbl*) (subst, t)
        | None -> (Vars.add id t subst, t))
    | Tfun (ps1, r1, kind), Tfun (ps2, r2, _) ->
        let subst, ps =
          List.fold_left_map
            (fun subst (l, r) ->
              let s, pt = inner subst (l.pt, r.pt) in
              (s, { l with pt }))
            subst (List.combine ps1 ps2)
        in
        let subst, r = inner subst (r1, r2) in
        (subst, Tfun (ps, r, kind))
    | (Trecord (i, record, l1) as l), Trecord (j, _, l2)
      when is_type_polymorphic l ->
        let labels = Array.copy l1 in
        let f (subst, i) (label : Cleaned_types.field) =
          let subst, ftyp = inner subst (label.ftyp, l2.(i).ftyp) in
          labels.(i) <- Cleaned_types.{ (labels.(i)) with ftyp };
          (subst, i + 1)
        in
        let subst, _ = Array.fold_left f (subst, 0) l1 in
        let subst, ps =
          List.fold_left_map
            (fun subst (l, r) -> inner subst (l, r))
            subst (List.combine i j)
        in
        (subst, Trecord (ps, record, labels))
    | (Tvariant (i, variant, l1) as l), Tvariant (j, _, l2)
      when is_type_polymorphic l ->
        let ctors = Array.copy l1 in
        let f (subst, i) (ctor : Cleaned_types.ctor) =
          let subst, ctyp =
            match (ctor.ctyp, l2.(i).ctyp) with
            | Some l, Some r ->
                let subst, t = (inner subst) (l, r) in
                (subst, Some t)
            | _ -> (subst, None)
          in
          ctors.(i) <- Cleaned_types.{ (ctors.(i)) with ctyp };
          (subst, i + 1)
        in
        let subst, _ = Array.fold_left f (subst, 0) l1 in
        let subst, ps =
          List.fold_left_map
            (fun subst (l, r) -> inner subst (l, r))
            subst (List.combine i j)
        in
        (subst, Tvariant (ps, variant, ctors))
    | Traw_ptr l, Traw_ptr r ->
        let subst, t = inner subst (l, r) in
        (subst, Traw_ptr t)
    | Tarray l, Tarray r ->
        let subst, t = inner subst (l, r) in
        (subst, Tarray t)
    | t, _ -> (subst, t)
  in
  let vars, typ = inner Vars.empty (poly, concrete) in

  let rec subst = function
    | Tpoly id as old -> (
        match Vars.find_opt id vars with Some t -> t | None -> old)
    | Tfun (ps, r, kind) ->
        let ps = List.map (fun p -> { p with pt = subst p.pt }) ps in
        let kind =
          match kind with
          | Simple -> Simple
          | Closure cls ->
              Closure
                (List.map (fun cl -> { cl with cltyp = subst cl.cltyp }) cls)
        in
        Tfun (ps, subst r, kind)
    | Trecord (ps, record, labels) as t when is_type_polymorphic t ->
        let ps = List.map subst ps in
        let f field = Cleaned_types.{ field with ftyp = subst field.ftyp } in
        let labels = Array.map f labels in
        Trecord (ps, record, labels)
    | Tvariant (ps, variant, ctors) as t when is_type_polymorphic t ->
        let ps = List.map subst ps in
        let f ctor =
          Cleaned_types.{ ctor with ctyp = Option.map subst ctor.ctyp }
        in
        let ctors = Array.map f ctors in
        Tvariant (ps, variant, ctors)
    | Traw_ptr t -> Traw_ptr (subst t)
    | Tarray t -> Tarray (subst t)
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
    let params = List.map (fun p -> { p with pt = subst p.pt }) params in
    let ret = subst ret in
    let kind =
      match kind with
      | Simple -> Simple
      | Closure cls ->
          Closure (List.map (fun cl -> { cl with cltyp = subst cl.cltyp }) cls)
    in
    { params; ret; kind }
  in

  let rec inner tree =
    let sub t = { (inner t) with typ = subst t.typ } in
    match tree.expr with
    | Mvar _ -> { tree with typ = subst tree.typ }
    | Mconst _ -> tree
    | Mbop (bop, l, r) -> { tree with expr = Mbop (bop, sub l, sub r) }
    | Munop (unop, e) -> { tree with expr = Munop (unop, sub e) }
    | Mif expr ->
        let cond = sub expr.cond in
        let e1 = sub expr.e1 in
        let e2 = sub expr.e2 in
        { tree with typ = e1.typ; expr = Mif { cond; e1; e2 } }
    | Mlet (id, expr, gn, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { tree with typ = cont.typ; expr = Mlet (id, expr, gn, cont) }
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

        let callee = { callee with ex; monomorph } in
        p := { !p with funcs = p2.funcs; monomorphized = p2.monomorphized };

        let args = List.map (fun arg -> { arg with ex = sub arg.ex }) args in
        let func = func_of_typ callee.ex.typ in
        {
          tree with
          typ = func.ret;
          expr = Mapp { callee; args; alloca; malloc; id };
        }
    | Mrecord (labels, alloca, const) ->
        let labels = List.map (fun (name, expr) -> (name, sub expr)) labels in
        {
          tree with
          typ = subst tree.typ;
          expr = Mrecord (labels, alloca, const);
        }
    | Mctor ((var, index, expr), alloca, const) ->
        let expr = Mctor ((var, index, Option.map sub expr), alloca, const) in
        { tree with typ = subst tree.typ; expr }
    | Mfield (expr, index) ->
        { tree with typ = subst tree.typ; expr = Mfield (sub expr, index) }
    | Mvar_index expr ->
        { tree with typ = subst tree.typ; expr = Mvar_index (sub expr) }
    | Mvar_data expr ->
        { tree with typ = subst tree.typ; expr = Mvar_data (sub expr) }
    | Mset (expr, value) ->
        { tree with typ = subst tree.typ; expr = Mset (sub expr, sub value) }
    | Mseq (expr, cont) ->
        let expr = sub expr in
        let cont = sub cont in
        { tree with typ = cont.typ; expr = Mseq (expr, cont) }
    | Mfree_after (expr, id) ->
        let expr = sub expr in
        { tree with typ = expr.typ; expr = Mfree_after (expr, id) }
    | Mfmt (fmts, alloca, id) ->
        let fmts =
          List.map (function Fexpr e -> Fexpr (sub e) | Fstr s -> Fstr s) fmts
        in
        { tree with expr = Mfmt (fmts, alloca, id) }
    | Mcopy c -> { tree with expr = Mcopy { c with expr = sub c.expr } }
  in
  (!p, inner tree)

and monomorphize_call p expr parent_sub : morph_param * call_name =
  match find_function_expr p.vars expr.expr with
  | Builtin b -> (p, Builtin (b, func_of_typ expr.typ))
  | Inline (ps, typ, tree) ->
      (* Copied from Polymorphic below *)
      (* The parent substitution is threaded through to its children.
         This deals with nested closures *)
      let subst, typ = subst_type ~concrete:expr.typ typ parent_sub in

      (* If the type is still polymorphic, we cannot generate it *)
      if is_type_polymorphic typ then (p, Default)
      else let p, tree = subst_body p subst tree in

           (p, Inline (ps, tree))
  | Forward_decl name ->
      (* We don't have to do anything, because the correct function will be called in the first place.
         Except when it is called with different types recursively. We'll see *)
      (p, Recursive name)
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

(* State *)

let alloc_lvl = ref 1
let alloc_id = ref 1
let malloc_id = ref 1

let new_id id =
  let ret_id = !id in
  incr id;
  ret_id

let enter_level () = incr alloc_lvl
let leave_level () = decr alloc_lvl
let request () = Request { id = new_id alloc_id; lvl = !alloc_lvl }

let reset () =
  alloc_lvl := 1;
  alloc_id := 1;
  malloc_id := 1

let rec set_alloca = function
  | Value ({ contents = Request req } as a) when req.lvl >= !alloc_lvl ->
      a := Preallocated
  | Two_values (a, b) ->
      set_alloca a;
      set_alloca b
  | Value _ | No_value -> ()

let propagate_malloc = function
  | Some { id = _; mlvl } -> mlvl := !mlvl - 1
  | None -> ()

let free_mallocs body mallocs =
  (* Filter out the returned alloc (if it exists), free the rest
     then mark returned one local for next scope *)
  let f { id; mlvl } body =
    if !mlvl > !alloc_lvl then
      (* The tree should behave the same to the outer world, so we copy type and return field *)
      { body with expr = Mfree_after (body, id) }
    else body
  in

  List.fold_right f mallocs body

let recursion_stack = ref []
let constant_uniq_state = ref 1
let constant_tbl = Hashtbl.create 64
let global_tbl = Hashtbl.create 64

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

let rec is_temporary = function
  | Mvar _ | Mfield _ | Mvar_data _ -> false
  | Mconst _ | Mbop _ | Mlambda _ | Mrecord _ | Mctor _ | Mvar_index _ | Mfmt _
  | Mcopy _ ->
      true
  | Mapp { callee; _ } -> (
      match callee.monomorph with
      | Inline (_, e) -> is_temporary e.expr
      | Builtin (Unsafe_ptr_get, _) -> false
      | Builtin (Array_get, _) -> false
      | _ -> true)
  | Munop (_, t) -> is_temporary t.expr
  | Mif { e1; e2; _ } -> is_temporary e1.expr && is_temporary e2.expr
  | Mlet (_, _, _, cont)
  | Mfunction (_, _, cont)
  | Mseq (_, cont)
  | Mfree_after (cont, _) ->
      is_temporary cont.expr
  | Mset _ -> failwith "Internal Error: Trying to copy unit"

let copy_let lhs lmut rmut nm =
  match (lmut, rmut) with
  | false, false ->
      (* We don't need to copy *)
      lhs
  | _ ->
      let temporary = is_temporary lhs.expr in
      let kind = Cnormal { temporary; mut = lmut } in
      let expr = Mcopy { kind; expr = lhs; nm } in
      { lhs with expr }

let make_e2 e1 e2 id gn lmut rmut =
  match gn with
  | Some n ->
      let expr = Mcopy { kind = Cglobal n; expr = e1; nm = id } in
      let e1 = { e1 with expr } in
      { e2 with expr = Mlet (id, e1, gn, e2) }
  | None ->
      let e1 = copy_let e1 lmut rmut id in
      { e2 with expr = Mlet (id, e1, gn, e2) }

let rec morph_expr param (texpr : Typed_tree.typed_expr) =
  let make expr return = { typ = cln texpr.typ; expr; return } in
  match texpr.expr with
  | Typed_tree.Var v -> morph_var make param v
  | Const (String s) -> morph_string make param s
  | Const (Vector v) -> morph_vector make param v
  | Const (Array a) -> morph_array make param a
  | Const c -> (param, make (Mconst (morph_const c)) false, no_var)
  | Bop (bop, e1, e2) -> morph_bop make param bop e1 e2
  | Unop (unop, expr) -> morph_unop make param unop expr
  | If (cond, e1, e2) -> morph_if make param cond e1 e2
  | Let { id; uniq; rmut; lhs; cont } ->
      let p, e1, gn = prep_let param id uniq lhs false in
      let p, e2, func = morph_expr { p with ret = param.ret } cont in
      let e2 = make_e2 e1 e2 id gn lhs.attr.mut rmut in
      (p, e2, func)
  | Record labels -> morph_record make param labels texpr.attr
  | Field (expr, index) -> morph_field make param expr index
  | Set (expr, value) -> morph_set make param expr value
  | Sequence (expr, cont) -> morph_seq make param expr cont
  | Function (name, uniq, abs, cont) ->
      let p, call, abs = prep_func param (name, uniq, abs) in
      let p, cont, func = morph_expr { p with ret = param.ret } cont in
      ( p,
        {
          typ = cont.typ;
          expr = Mfunction (call, abs, cont);
          return = param.ret;
        },
        func )
  | Lambda (id, abs) -> morph_lambda texpr.typ param id abs
  | App { callee; args } -> morph_app make param callee args
  | Ctor (variant, index, dataexpr) ->
      morph_ctor make param variant index dataexpr texpr.attr
  | Variant_index expr -> morph_var_index make param expr
  | Variant_data expr -> morph_var_data make param expr
  | Fmt exprs -> morph_fmt make param exprs

and morph_var mk p v =
  let (v, kind), alloca =
    match v with
    | "__malloc" ->
        let malloc = { id = new_id malloc_id; mlvl = ref !alloc_lvl } in
        let var =
          { fn = Builtin Malloc; alloc = No_value; malloc = Some malloc }
        in
        ((v, Vnorm), var)
    | v -> (
        match Vars.find_opt v p.vars with
        | Some (Normal thing) -> ((v, Vnorm), thing)
        | Some (Const thing) -> ((thing, Vconst), no_var)
        | Some (Global (id, thing, used)) ->
            used := true;
            ((id, Vglobal), thing)
        | None -> ((v, Vnorm), no_var))
  in
  (p, mk (Mvar (v, kind)) p.ret, alloca)

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
  (* vectors are freed recursively, we don't need to track the items here *)
  let f param e =
    let p, e, var = morph_expr param e in
    (* (In codegen), we provide the data ptr to the initializers to construct inplace *)
    set_alloca var.alloc;
    (p, e)
  in
  let p, v = List.fold_left_map f p v in
  leave_level ();
  let alloca = ref (request ()) in

  let id = new_id malloc_id in
  let malloc = { id; mlvl = ref !alloc_lvl } in
  let mallocs = malloc :: old_mallocs in

  ( { p with ret; mallocs },
    mk (Mconst (Vector (id, v, alloca))) p.ret,
    { fn = No_function; alloc = Value alloca; malloc = Some malloc } )

and morph_array mk p a =
  let ret = p.ret in
  let p = { p with ret = false } in

  (* ret = false is threaded through p *)
  enter_level ();
  (* vectors are freed recursively, we don't need to track the items here *)
  let f param e =
    let p, e, var = morph_expr param e in
    (* (In codegen), we provide the data ptr to the initializers to construct inplace *)
    set_alloca var.alloc;
    (p, e)
  in
  let p, a = List.fold_left_map f p a in
  leave_level ();
  let alloca = ref (request ()) in

  ( { p with ret },
    mk (Mconst (Array (a, alloca))) p.ret,
    { fn = No_function; alloc = Value alloca; malloc = None } )

and morph_const = function
  | String _ | Vector _ | Array _ ->
      failwith "Internal Error: Const should be extra case"
  | Int i -> Int i
  | Bool b -> Bool b
  | Float f -> Float f
  | Unit -> Unit
  | U8 c -> U8 c
  | I32 i -> I32 i
  | F32 f -> F32 f

and morph_bop mk p bop e1 e2 =
  let ret = p.ret in
  (* The returning expr is bop, not one of the operands *)
  let p, e1, _ = morph_expr { p with ret = false } e1 in
  let p, e2, _ = morph_expr { p with ret = false } e2 in
  ({ p with ret }, mk (Mbop (bop, e1, e2)) ret, no_var)

and morph_unop mk p unop expr =
  let ret = p.ret in
  let p, e, _ = morph_expr { p with ret = false } expr in
  ({ p with ret }, mk (Munop (unop, e)) ret, no_var)

and morph_if mk p cond e1 e2 =
  let ret = p.ret in
  let p, cond, _ = morph_expr { p with ret = false } cond in
  let p, e1, a = morph_expr { p with ret } e1 in
  let p, e2, b = morph_expr { p with ret } e2 in
  ( p,
    mk (Mif { cond; e1; e2 }) ret,
    { a with alloc = Two_values (a.alloc, b.alloc) } )

and prep_let p id uniq e toplvl =
  let p, e1, func = morph_expr { p with ret = false } e in
  (* We add constants to the constant table, not the current env *)
  let p, gn =
    match e.attr with
    | { const = true; _ } ->
        let uniq = Module.unique_name id uniq in
        (* Maybe we have to generate a new name here *)
        let cnt = new_id constant_uniq_state in
        Hashtbl.add constant_tbl uniq (cnt, e1, toplvl);
        ({ p with vars = Vars.add id (Const uniq) p.vars }, None)
    | { global = true; _ } ->
        (* Globals are 'preallocated' at module level *)
        set_alloca func.alloc;
        let uniq = Module.unique_name id uniq in
        let cnt = new_id constant_uniq_state in
        Hashtbl.add global_tbl uniq (cnt, e1.typ, toplvl);
        ( { p with vars = Vars.add id (Global (uniq, func, ref false)) p.vars },
          Some uniq )
    | _ -> ({ p with vars = Vars.add id (Normal func) p.vars }, None)
  in
  (p, e1, gn)

and morph_record mk p labels is_const =
  let ret = p.ret in
  let p = { p with ret = false } in

  (* ret = false is threaded through p *)
  enter_level ();

  (* We only need to track if there are some mallocs, not each one individually *)
  let fst_malloc other = function Some m -> Some m | None -> other in

  (* Collect mallocs in initializer *)
  let f (param, malloc) (id, e) =
    let p, e, var = morph_expr param e in
    if is_struct e.typ then set_alloca var.alloc;
    ((p, fst_malloc var.malloc malloc), (id, e))
  in
  let (p, malloc), labels = List.fold_left_map f (p, None) labels in
  leave_level ();

  (* mallocs were generated at a lower level, we increase to current level (or decrease :)) *)
  (match malloc with None -> () | Some m -> m.mlvl := !alloc_lvl);

  let alloca = ref (request ()) in
  ( { p with ret },
    mk (Mrecord (labels, alloca, is_const.const)) ret,
    { fn = No_function; alloc = Value alloca; malloc } )

and morph_field mk p expr index =
  let ret = p.ret in
  let p, e, func = morph_expr { p with ret = false } expr in
  (* Field should not inherit alloca of its parent.
     Otherwise codegen might use a nested type as its parent *)
  ({ p with ret }, mk (Mfield (e, index)) ret, { func with alloc = No_value })

and morph_set mk p expr value =
  let ret = p.ret in
  let p, e, _ = morph_expr { p with ret = false } expr in
  let p, v, func = morph_expr p value in

  (* TODO handle this in morph_call, where realloc drops the old ptr and adds the new one to the free list *)
  (* If we mutate a ptr with realloced ptr, the old one is already freed and we drop it from
     the free list *)
  ({ p with ret }, mk (Mset (e, v)) ret, func)

and morph_seq mk p expr cont =
  let ret = p.ret in
  let p, expr, _ = morph_expr { p with ret = false } expr in
  let p, cont, func = morph_expr { p with ret } cont in
  (p, mk (Mseq (expr, cont)) ret, func)

and prep_func p (username, uniq, abs) =
  (* If the function is concretely typed, we add it to the function list and
     add the usercode name to the bound variables. In the polymorphic case,
     we add the function to the bound variables, but not to the function list.
     Instead, the monomorphized instance will be added later *)
  let ftyp =
    Types.(Tfun (abs.func.tparams, abs.func.ret, abs.func.kind)) |> cln
  in

  let call = Module.unique_name username uniq in
  let recursive = Rnormal in
  let inline = abs.inline in

  let func =
    {
      params = List.map cln_param abs.func.tparams;
      ret = cln abs.func.ret;
      kind = cln_kind abs.func.kind;
    }
  in
  let pnames = abs.nparams in

  (* Make sure recursion works and the current function can be used in its body *)
  let temp_p =
    recursion_stack := (call, recursive) :: !recursion_stack;
    let alloc =
      if Types.is_struct abs.func.ret then Value (ref (request ()))
      else No_value
    in
    (* TODO make it impossible to recursively call an inline function *)
    let value = { no_var with fn = Forward_decl call; alloc } in
    let vars = Vars.add username (Normal value) p.vars in

    (* Add parameters to env as normal values.
       The existing values might not be 'normal' *)
    let vars =
      List.fold_left
        (fun vars name -> Vars.add name (Normal no_var) vars)
        vars pnames
    in

    { p with vars; ret = (if not inline then true else p.ret); mallocs = [] }
  in

  enter_level ();
  let temp_p, body, var = morph_expr temp_p abs.body in
  leave_level ();

  if is_struct body.typ then (
    set_alloca var.alloc;
    propagate_malloc var.malloc);

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
    if inline then
      let fn = Inline (pnames, ftyp, body) in
      let vars = Vars.add username (Normal { var with fn }) p.vars in
      { p with vars }
    else if is_type_polymorphic ftyp then
      let fn = Polymorphic gen_func in
      let vars = Vars.add username (Normal { var with fn }) p.vars in
      { p with vars }
    else
      let fn = Concrete (gen_func, username) in
      let vars = Vars.add username (Normal { var with fn }) p.vars in
      let funcs = gen_func :: p.funcs in
      { p with vars; funcs }
  in
  (p, call, abs)

and morph_lambda typ p id abs =
  let typ = cln typ in

  let name = Module.lambda_name id in
  let recursive = Rnone in
  let func =
    {
      params = List.map cln_param abs.func.tparams;
      ret = cln abs.func.ret;
      kind = cln_kind abs.func.kind;
    }
  in
  let pnames = abs.nparams in

  let ret = p.ret in
  let vars = p.vars in
  (* lambdas don't recurse, but functions inside the body might *)
  recursion_stack := (name, recursive) :: !recursion_stack;
  let temp_p =
    (* Add parameters to env as normal values.
       The existing values might not be 'normal' *)
    let vars =
      List.fold_left
        (fun vars name -> Vars.add name (Normal no_var) vars)
        vars pnames
    in
    { p with vars; ret = true; mallocs = [] }
  in

  let tmp, body, var = morph_expr temp_p abs.body in

  (* Collect functions from body *)
  enter_level ();
  let p = { p with monomorphized = tmp.monomorphized; funcs = tmp.funcs } in
  leave_level ();

  if is_struct body.typ then (
    set_alloca var.alloc;
    propagate_malloc var.malloc);
  let body = free_mallocs body temp_p.mallocs in

  (* Why do we need this again in lambda? They can't recurse. *)
  (* But functions on the lambda body might *)
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
  let id = new_id malloc_id in
  Apptbl.add apptbl id p;

  let ret = p.ret in
  let p, ex, var = morph_expr { p with ret = false } callee in
  let p, monomorph = monomorphize_call p ex None in
  let callee = { ex; monomorph; mut = false } in

  let malloc, p =
    match var.malloc with
    | Some _ ->
        let malloc = { id = new_id malloc_id; mlvl = ref !alloc_lvl } in
        (Some malloc, { p with mallocs = malloc :: p.mallocs })
    | None -> (None, p)
  in

  (if ret then
   match callee.monomorph with Recursive name -> set_tailrec name | _ -> ());

  let f p (arg, mut) =
    let p, ex, _ = morph_expr p arg in
    let p, monomorph = monomorphize_call p ex None in
    (p, { ex; monomorph; mut })
  in
  let p, args = List.fold_left_map f p args in

  let alloc, alloc_ref =
    if is_struct callee.ex.typ then
      (* For every call, we make a new request. If the call is the return
         value of a function, the request will be change to [Preallocated]
         in [morph_func] or [morph_lambda] above. *)
      let req = ref (request ()) in
      (Value req, req)
    else (No_value, ref (request ()))
  in

  let app =
    let malloc = Option.map (fun m -> m.id) malloc in
    Mapp { callee; args; alloca = alloc_ref; malloc; id }
  in
  ({ p with ret }, mk app ret, { no_var with alloc; malloc })

and morph_ctor mk p variant index expr is_const =
  let ret = p.ret in
  let p = { p with ret = false } in

  enter_level ();

  let p, malloc, ctor =
    match expr with
    | Some expr ->
        (* We only need to track if there are some mallocs, not each one individually *)
        let fst_malloc other = function Some m -> Some m | None -> other in

        (* Similar to [morph_record], collect mallocs in data *)
        let p, e, var = morph_expr p expr in
        (* TODO We should now handle not only records, but all types which are
           automatically allocated: Variants *)
        if is_struct e.typ then set_alloca var.alloc;
        let malloc = fst_malloc var.malloc None in
        (p, malloc, (variant, index, Some e))
    | None -> (p, None, (variant, index, None))
  in

  leave_level ();

  let alloca = ref (request ()) in
  ( { p with ret },
    mk (Mctor (ctor, alloca, is_const.const)) ret,
    { fn = No_function; alloc = Value alloca; malloc } )

(* Both variant exprs are as default as possible.
   We handle everything in codegen *)
and morph_var_index mk p expr =
  let ret = p.ret in
  (* False because we only use it interally in if expr? *)
  let p, e, func = morph_expr { p with ret = false } expr in
  ({ p with ret }, mk (Mvar_index e) ret, { func with alloc = No_value })

and morph_var_data mk p expr =
  let ret = p.ret in
  (* False because we only use it interally in if expr? *)
  let p, e, func = morph_expr { p with ret = false } expr in
  ({ p with ret }, mk (Mvar_data e) ret, func)

and morph_fmt mk p exprs =
  let ret = p.ret in
  let p = { p with ret = false } in

  let f p = function
    | Typed_tree.Fexpr e ->
        let p, e, _ = morph_expr p e in
        (p, Fexpr e)
    | Fstr s -> (p, Fstr s)
  in
  enter_level ();
  let p, es = List.fold_left_map f p exprs in
  leave_level ();

  let alloca = ref (request ()) in
  let id = new_id malloc_id in
  let malloc = { id; mlvl = ref !alloc_lvl } in
  let mallocs = malloc :: p.mallocs in

  ( { p with ret; mallocs },
    mk (Mfmt (es, alloca, id)) ret,
    { no_var with alloc = Value alloca; malloc = Some malloc } )

let morph_toplvl param items =
  let rec aux param = function
    | [] -> (param, { typ = Tunit; expr = Mconst Unit; return = true }, no_var)
    | Typed_tree.Tl_let (id, uniq, expr) :: tl ->
        let p, e1, gn = prep_let param id uniq expr true in
        let p, e2, func = aux { p with ret = param.ret } tl in
        let e2 = make_e2 e1 e2 id gn expr.attr.mut false in
        (p, e2, func)
    | Tl_function (name, uniq, abs) :: tl ->
        let p, call, abs = prep_func param (name, uniq, abs) in
        let p, cont, func = aux { p with ret = param.ret } tl in
        ( p,
          {
            typ = cont.typ;
            expr = Mfunction (call, abs, cont);
            return = param.ret;
          },
          func )
    | [ Tl_expr e ] -> morph_expr param e
    | Tl_expr e :: tl ->
        let p, e, _ = morph_expr param e in
        let p, cont, func = aux { p with ret = param.ret } tl in
        (p, { typ = cont.typ; expr = Mseq (e, cont); return = param.ret }, func)
  in
  aux param items

let monomorphize { Typed_tree.externals; items; _ } =
  reset ();

  (* External are globals. By marking them [Global] here, we don't have to
     introduce a special case in codegen, or mark them Const_ptr when they are not *)
  let vars =
    List.fold_left
      (fun vars { Env.imported = _; ext_name; ext_typ = _; ext_cname; used } ->
        let cname =
          match ext_cname with None -> ext_name | Some cname -> cname
        in
        Vars.add ext_name (Global (cname, no_var, used)) vars)
      Vars.empty externals
  in

  let param =
    { vars; monomorphized = Set.empty; funcs = []; ret = false; mallocs = [] }
  in
  let p, tree, _ = morph_toplvl param items in

  let frees =
    List.filter_map
      (function { id; mlvl } when !mlvl >= !alloc_lvl -> Some id | _ -> None)
      p.mallocs
  in

  let externals =
    List.filter_map
      (fun { Env.imported; ext_name; ext_typ = t; ext_cname; used } ->
        if not !used then None
        else
          let cname =
            match ext_cname with None -> ext_name | Some cname -> cname
          in
          let c_linkage =
            match imported with None | Some `C -> true | Some `Schmu -> false
          in
          Some { ext_name; ext_typ = cln t; c_linkage; cname })
      externals
  in

  let sort_const (_, (lid, _, _)) (_, (rid, _, _)) = Int.compare lid rid in
  let constants =
    Hashtbl.to_seq constant_tbl
    |> List.of_seq |> List.sort sort_const
    |> List.map (fun (name, (id, tree, toplvl)) ->
           ignore id;
           (name, tree, toplvl))
  in
  let globals =
    Hashtbl.to_seq global_tbl |> List.of_seq |> List.sort sort_const
    |> List.map (fun (name, (id, typ, toplvl)) ->
           ignore id;
           (name, typ, toplvl))
  in

  (* TODO maybe try to catch memory leaks? *)
  { constants; globals; externals; tree; frees; funcs = p.funcs }
