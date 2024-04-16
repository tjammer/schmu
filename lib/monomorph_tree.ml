open Cleaned_types
open Malloc_types
module Iset = Set.Make (Int)

module Mtree = struct
  type expr =
    | Mvar of string * var_kind
    | Mconst of const
    | Mbop of Ast.bop * monod_tree * monod_tree
    | Munop of Ast.unop * monod_tree
    | Mif of ifexpr
    | Mlet of
        string * monod_tree * let_kind * global_name * malloc_list * monod_tree
    | Mbind of string * monod_tree * monod_tree
    | Mlambda of string * fun_kind * typ * alloca
    | Mfunction of string * fun_kind * typ * monod_tree * alloca
    | Mapp of {
        callee : monod_expr;
        args : (monod_expr * bool) list;
        alloca : alloca;
        id : int;
        ms : malloc_list;
      }
    | Mrecord of (string * monod_tree) list * alloca * malloc_list
    | Mfield of (monod_tree * int)
    | Mset of (monod_tree * monod_tree * bool)
    | Mseq of (monod_tree * monod_tree)
    | Mctor of (string * int * monod_tree option) * alloca * malloc_list
    | Mvar_index of monod_tree
    | Mvar_data of monod_tree * int option
    | Mfmt of fmt list * alloca * int
    | Mprint_str of fmt list
    | Mfree_after of monod_tree * free_list
  [@@deriving show]

  and const =
    | Int of int
    | Bool of bool
    | U8 of char
    | U16 of int
    | Float of float
    | I32 of int
    | F32 of float
    | String of string
    | Array of monod_tree list * alloca * int
    | Fixed_array of monod_tree list * alloca * int list
    | Unit

  and func = { params : param list; ret : typ; kind : fun_kind }

  and abstraction = {
    func : func;
    pnames : (string * int) list;
    body : monod_tree;
  }

  and call_name =
    | Mono of string
    | Concrete of string
    | Default
    | Recursive of { nonmono : string; call : string }
    | Builtin of Builtin.t * func
    | Inline of (string * int) list * monod_tree

  and monod_expr = { ex : monod_tree; monomorph : call_name; mut : bool }

  and monod_tree = {
    typ : typ;
    expr : expr;
    return : bool;
    loc : Ast.loc;
    const : const_kind;
  }

  and alloca = allocas ref
  and request = { id : int; lvl : int }
  and allocas = Preallocated | Request of request

  and ifexpr = {
    cond : monod_tree;
    owning : int option;
    e1 : monod_tree;
    e2 : monod_tree;
  }

  and var_kind = Vnorm | Vconst | Vglobal of string
  and global_name = string option
  and fmt = Fstr of string | Fexpr of monod_tree
  and copy_kind = Cglobal of string | Cnormal of bool
  and malloc_list = int list
  and free_list = Except of malloc_id list | Only of malloc_id list
  and let_kind = Lowned | Lborrow
  and const_kind = Const | Cnot (* | Constexpr *)

  type recurs = Rnormal | Rtail | Rnone
  type func_name = { user : string; call : string }

  type external_decl = {
    ext_name : string;
    ext_typ : typ;
    cname : string;
    c_linkage : bool;
    closure : bool;
  }

  type to_gen_func = {
    abs : abstraction;
    name : func_name;
    recursive : recurs;
    upward : unit -> bool;
    monomorphized : bool;
  }

  type monomorphized_tree = {
    constants : (string * monod_tree * bool) list;
    globals : (string * monod_tree * bool) list;
    externals : external_decl list;
    tree : monod_tree;
    funcs : to_gen_func list;
    frees : malloc_id Seq.t;
  }
end

include Mtree
module Monomorph_impl = Monomorph.Make (Mtree)
open Monomorph_impl
open Monomorph_impl.Mallocs_ipml

(* Re-exports from monomorph *)
let typ_of_abs = typ_of_abs
let structural_name = structural_name
let nominal_name = nominal_name "" ~closure:false ~poly:(Tpoly "-")

let no_var =
  { fn = No_function; alloc = No_value; malloc = No_malloc; tailrec = false }

let extract_callname default vars expr =
  match find_function_expr vars expr with
  | Builtin _ | Inline _ ->
      failwith "Internal error: Builtin or inline function captured in closure"
  | Mutual_rec _ -> failwith "TODO mutual rec"
  | Forward_decl (call, _) | Polymorphic call -> call
  | Concrete (func, _) -> func.name.call
  | No_function -> default

let reconstr_module_username ~mname ~mainmod username =
  (* Values queried from an imported module have a special name so they don't
     clash with user-defined values. This name is calculated in
     [Module.absolute_module_name]. For functions, polymorphic the [unique_name]
     also prepends the module. Their username will stay intact so we don't
     create names like prelude_prelude_thing. In order to match their queried
     name, we convert to the absolute_module_name before adding them to the
     environment. *)
  let imported = Path.equal mname mainmod |> not in
  if imported then Module.absolute_module_name ~mname username else username

let rec cln p = function
  | Types.Tvar { contents = Link t } | Talias (_, t) -> cln p t
  | Tint -> Tint
  | Tbool -> Tbool
  | Tunit -> Tunit
  | Tu8 -> Tu8
  | Tu16 -> Tu16
  | Tfloat -> Tfloat
  | Ti32 -> Ti32
  | Tf32 -> Tf32
  | Qvar id | Tvar { contents = Unbound (id, _) } -> Tpoly id
  | Tfun (params, ret, kind) ->
      Tfun (List.map (cln_param p) params, cln p ret, cln_kind p kind)
  | Trecord (ps, name, fields) ->
      let ps = List.map (cln p) ps in
      let fields =
        Array.map
          (fun field -> { ftyp = cln p Types.(field.ftyp); mut = field.mut })
          fields
      in
      let name = Option.map Path.type_name name in
      Trecord (ps, name, fields)
  | Tvariant (ps, name, ctors) ->
      let ps = List.map (cln p) ps in
      let ctors =
        Array.map
          (fun ctor ->
            {
              cname = Types.(ctor.cname);
              ctyp = Option.map (cln p) ctor.ctyp;
              index = ctor.index;
            })
          ctors
      in
      Tvariant (ps, Path.type_name name, ctors)
  | Traw_ptr t -> Traw_ptr (cln p t)
  | Tarray t -> Tarray (cln p t)
  | Tfixed_array ({ contents = Unknown (i, _) | Generalized i }, t) ->
      (* That's a hack. We know the unknown number is a string of an int. This is
         due to an implementation detail in [gen_var] in inference. We need a
         proper size here, but for these types we don't know yet. The type will be
         substituted though. So we use the negative of the string-number as a way
         to mark this case. Luckily, a negative number will raise expcetions or
         even segfault in codegen. If we don't substitute, it won't go unnoticed.
         Furthermore, fixed-size arrays with negative indices must recognized as
         polymorphic*)
      Tfixed_array (-int_of_string i, cln p t)
  | Tfixed_array ({ contents = Known i }, t) -> Tfixed_array (i, cln p t)
  | Tfixed_array ({ contents = Linked iv }, t) ->
      cln p Types.(Tfixed_array (iv, t))
  | Tabstract (_, _, Tvar { contents = Unbound _ }) as t ->
      print_endline (Types.show_typ t);
      failwith "Internal Error: How did this come through?"
  | Tabstract (_, _, t) ->
      (* Turn abstract type into its real representation for codegen *)
      cln p t

and cln_kind p = function
  | Simple -> Simple
  | Closure vals ->
      let vals =
        List.map
          (fun (cl : Types.closed) ->
            let typ = cln p cl.cltyp in
            let modded_name =
              match cl.clmname with
              | Some mname ->
                  reconstr_module_username ~mname ~mainmod:p.mainmodule
                    cl.clname
              | None -> cl.clname
            in
            let clname =
              if not cl.clparam then
                extract_callname modded_name p.vars (Mvar (cl.clname, Vnorm))
              else modded_name
            in
            {
              clname;
              cltyp = typ;
              clmut = cl.clmut;
              clparam = cl.clparam;
              clcopy = cl.clcopy;
            })
          vals
      in
      Closure vals

and cln_param param p =
  let pt = cln param Types.(p.pt) in
  let pmut, pmoved =
    match p.pattr with
    | Dset | Dmut -> (true, false)
    | Dmove -> (false, true)
    | Dnorm -> (false, false)
  in
  { pt; pmut; pmoved }

(* State *)

let alloc_id = ref 1
let malloc_id = ref 1

let new_id id =
  let ret_id = !id in
  incr id;
  ret_id

let enter_level p = { p with alloc_lvl = p.alloc_lvl + 1 }
let leave_level p = { p with alloc_lvl = p.alloc_lvl - 1 }
let request p = Request { id = new_id alloc_id; lvl = p.alloc_lvl }

let reset () =
  alloc_id := 1;
  malloc_id := 1

let rec set_alloca p = function
  | Value ({ contents = Request req } as a) when req.lvl >= p.alloc_lvl ->
      a := Preallocated
  | Two_values (a, b) ->
      set_alloca p a;
      set_alloca p b
  | Value _ | No_value -> ()

let mb_malloc parent ids typ =
  if contains_allocation typ then
    let mid = new_id malloc_id in
    let id = Malloc.Single { mid; typ; parent } in
    let mallocs = Mallocs.add id ids in
    (Some mid, id, mallocs)
  else (None, No_malloc, ids)

let malloc_id_of_param mid p = { Mid.mid; typ = p.pt; parent = None }

let add_params vars mallocs pnames params =
  (* Add parameters to the env and create malloc ids if they have been moved *)
  List.fold_left2
    (fun (vars, mallocs) (name, mid) p ->
      let var, mallocs =
        let id = malloc_id_of_param mid p in
        let malloc = if p.pmoved then Malloc.Single id else Param id in
        (Normal { no_var with malloc }, Mallocs.add malloc mallocs)
      in
      let vars = Vars.add name var vars in
      (vars, mallocs))
    (vars, mallocs) pnames params

let constant_uniq_state = ref 1
let constant_tbl = Hashtbl.create 64
let global_tbl = Hashtbl.create 64

let pop_recursion_stack p =
  match p.recursion_stack with
  | hd :: _ -> snd hd
  | [] -> failwith "Internal Error: Recursion stack empty (pop)"

let set_tailrec p name =
  match p.recursion_stack with
  (* We have to check the name (of the function) here, because a nested function
     could call recursively its parent *)
  | (nm, _) :: tl when String.equal name nm ->
      { p with recursion_stack = (nm, Rtail) :: tl }
  | _ :: _ -> p
  | [] -> failwith "Internal Error: Recursion stack empty (set)"

let rec_fs_to_env p (username, uniq, typ) =
  let ftyp = cln p typ in

  let call = Module.unique_name ~mname:p.mname username uniq in
  let fn = Mutual_rec (call, ftyp) in
  let username =
    reconstr_module_username ~mname:p.mname ~mainmod:p.mainmodule username
  in
  let vars = Vars.add username (Normal { no_var with fn }) p.vars in
  { p with vars }

let let_kind pass =
  match pass with
  | Ast.Dmut | Dnorm -> Lborrow
  | Dmove -> Lowned
  | Dset -> failwith "Internal Error: no set here"

let const (e : Typed_tree.typed_expr) = if not e.attr.const then Cnot else Const

let is_ctor_check = function
  | Mbop (Ast.Equal_i, { expr = Mvar_index expr; _ }, _) ->
      (* This depends on the fact that in pattern matching we always construct the
         check with the current pattern path. This path can be used to query the
         alloca and malloc ids. *)
      Some expr
  | _ -> None

let find_var v vars =
  match Vars.find_opt v vars with
  | Some (Normal ({ fn = Concrete (_, callname); _ } as thing)) ->
      ((callname, Vnorm), thing)
  | Some (Normal thing) -> ((v, Vnorm), thing)
  | Some (Const thing) -> ((thing, Vconst), no_var)
  | Some (Global (id, thing, used)) ->
      used := true;
      ((id, Vglobal v), thing)
  | None -> ((v, Vnorm), no_var)

let rec equal_alloc a b =
  match (a, b) with
  | Value a, Value b -> a == b
  | Two_values (lfst, lsnd), Two_values (rfst, rsnd) ->
      equal_alloc lfst rfst && equal_alloc lsnd rsnd
  | No_value, No_value -> false
  | _ -> false

let rec morph_expr param (texpr : Typed_tree.typed_expr) =
  let make expr return =
    let (const : const_kind) = if texpr.attr.const then Const else Cnot in
    { typ = cln param texpr.typ; expr; return; loc = texpr.loc; const }
  in
  match texpr.expr with
  | Typed_tree.Var (v, mname) -> morph_var make param v mname
  | Const (String s) -> morph_string make param s
  | Const (Array a) -> morph_array make param a (cln param texpr.typ)
  | Const (Fixed_array a) ->
      morph_fixed_array make param a (cln param texpr.typ)
  | Const c -> (param, make (Mconst (morph_const c)) false, no_var)
  | Bop (bop, e1, e2) -> morph_bop make param bop e1 e2
  | Unop (unop, expr) -> morph_unop make param unop expr
  | If (_, None, _, _) -> failwith "Internal Error: Unset if owning"
  | If (cond, Some owning, e1, e2) -> morph_if make param cond owning e1 e2
  | Let { id; uniq; rhs; cont; pass; rmut = _; id_loc = _ } ->
      let kind = let_kind pass in
      let un, p, e1, gn, ms = prep_let param id uniq rhs pass false in
      let p, e2, func = morph_expr { p with ret = param.ret } cont in
      (p, { e2 with expr = Mlet (un, e1, kind, gn, ms, e2) }, func)
  | Bind (id, lhs, ocont) ->
      let id =
        reconstr_module_username ~mname:param.mname ~mainmod:param.mainmodule id
      in
      let p, lhs, func = morph_expr { param with ret = false } lhs in
      (* top level function aliases *)
      let var =
        match lhs.expr with
        | Mvar (id, Vglobal _) ->
            (* It's already used, we don't care about the actual value *)
            Global (id, func, ref false)
        | _ -> Normal func
      in
      let vars = Vars.add id var p.vars in
      let p, cont, func = morph_expr { p with ret = param.ret; vars } ocont in
      ( p,
        {
          typ = cont.typ;
          expr = Mbind (id, lhs, cont);
          return = param.ret;
          loc = texpr.loc;
          const = const ocont;
        },
        func )
  | Record labels -> morph_record make param labels (cln param texpr.typ)
  | Field (expr, index, _) -> morph_field make param expr index
  | Set (expr, value, moved) -> morph_set make param expr value moved
  | Sequence (expr, cont) -> morph_seq make param expr cont
  | Function (name, uniq, abs, ocont) ->
      let p, (call, kind, ftyp, alloca) = prep_func param (name, uniq, abs) in
      let p, cont, func = morph_expr { p with ret = param.ret } ocont in
      ( p,
        {
          typ = cont.typ;
          expr = Mfunction (call, kind, ftyp, cont, alloca);
          return = param.ret;
          loc = texpr.loc;
          const = const ocont;
        },
        func )
  | Mutual_rec_decls (decls, cont) ->
      let p = List.fold_left rec_fs_to_env param decls in
      morph_expr p cont
  | Lambda (id, abs) -> morph_lambda make texpr.typ param id abs
  | App
      {
        callee = { expr = Var ("print", Some (Path.Pid "std")); _ };
        args = [ ({ expr = Fmt es; _ }, _) ];
      } ->
      morph_print_str make param es
  | App { callee; args } ->
      morph_app make param callee args (cln param texpr.typ)
  | Ctor (variant, index, dataexpr) ->
      morph_ctor make param variant index dataexpr (cln param texpr.typ)
  | Variant_index expr -> morph_var_index make param expr
  | Variant_data expr -> morph_var_data make param expr (cln param texpr.typ)
  | Fmt exprs -> morph_fmt make param exprs
  | Move e ->
      let p, e, func = morph_expr param e in
      let mallocs =
        if contains_allocation e.typ then Mallocs.remove func.malloc p.mallocs
        else p.mallocs
      in
      ({ p with mallocs }, e, { func with malloc = No_malloc })

and morph_var mk p v mname =
  let (v, kind), var =
    let v =
      match mname with
      | Some mname -> reconstr_module_username ~mname ~mainmod:p.mainmodule v
      | None -> v
    in
    match v with
    | "__malloc" ->
        let var = { no_var with fn = Builtin Malloc } in
        ((v, Vnorm), var)
    | v -> find_var v p.vars
  in
  let ex = mk (Mvar (v, kind)) p.ret in
  (p, ex, var)

and morph_string mk p s =
  ( p,
    mk (Mconst (String s)) p.ret,
    { no_var with fn = No_function; malloc = No_malloc } )

and morph_array mk p a typ =
  let ret = p.ret in
  (* TODO save id list and pass empty one. Destroy temporary objects not
     directly used as member *)
  let p = { p with ret = false } in

  (* ret = false is threaded through p *)
  let p = enter_level p in
  let f param e =
    let p, e, var = morph_expr param e in
    (* (In codegen), we provide the data ptr to the initializers to construct inplace *)
    set_alloca p var.alloc;
    (* Should have been moved *)
    assert (var.malloc = No_malloc);
    (p, e)
  in
  let p, a = List.fold_left_map f p a in
  let p = leave_level p in
  let alloca = ref (request p) in
  let mid = new_id malloc_id in
  let id = { Mid.mid; typ; parent = None } in
  let mallocs = Mallocs.add (Single id) p.mallocs in

  ( { p with ret; mallocs },
    mk (Mconst (Array (a, alloca, mid))) p.ret,
    { no_var with fn = No_function; alloc = Value alloca; malloc = Single id }
  )

and morph_fixed_array mk p a typ =
  let ret = p.ret in
  let p = { p with ret = false } in

  let p = enter_level p in
  let f param e =
    let p, e, var = morph_expr param e in
    set_alloca p var.alloc;
    (* Should have been moved *)
    assert (var.malloc = No_malloc);
    (p, e)
  in
  let p, a = List.fold_left_map f p a in
  let p = leave_level p in

  let _, malloc, mallocs = mb_malloc None p.mallocs typ in
  let ms = m_to_list malloc in

  let alloca = ref (request p) in
  ( { p with ret; mallocs },
    mk (Mconst (Fixed_array (a, alloca, ms))) p.ret,
    { no_var with fn = No_function; alloc = Value alloca; malloc } )

and morph_const = function
  | String _ | Array _ | Fixed_array _ ->
      failwith "Internal Error: Const should be extra case"
  | Int i -> Int i
  | Bool b -> Bool b
  | Float f -> Float f
  | Unit -> Unit
  | U8 c -> U8 c
  | U16 s -> U16 s
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

and morph_if mk p cond owning e1 e2 =
  let ret = p.ret in
  let p, cond, _ = morph_expr { p with ret = false } cond in
  let oldmallocs = p.mallocs and vars = p.vars in

  (* TODO update this comment *)
  (* If a malloc from a branch is local it is unique. We can savely add it to
     mallocs and return it. For mallocs from the outer scope (function scope),
     we need to be more careful. If outer scope mallocs are involved, we don't
     add to mallocs to prevent aliasing, but return Oneof _. If such an
     expression is returned from a function, we cannot be sure what to free in
     codegen. *)
  (* There are two cases to distinguish:
     1. The borrows are moved (owning = true), which means all unused branches
     can be freed immediately. We still keep track of the Oneofs for nested ifs
     so we prevent double-freeing an already freed branch. Local allocation are
     treated as No_malloc, so they aren't freed from the other branch.
     2. The borrows are not moved (owning = false). In this case, we don't know
     if the borrows are returned later, so we (could) keep an extra bool per
     taken branch in codegen which can be queried to delete the correct things.
     For now we prevent this situation completely with a check in exclusivity
     and force a copy *)
  let p, e1, a =
    morph_expr { p with ret; mallocs = Mallocs.push Mlocal oldmallocs } e1
  in
  let e1, a, amallocs =
    (* For tailrecursive calls, every ref is already decreased in [morph_app].
       Furthermore, if both branches are tailrecursive, calling decr_ref might
       destroy a basic block in codegen. That's due to no merge blocks being
       created in that case *)
    if a.tailrec then
      let _, mallocs = Mallocs.pop p.mallocs in
      (e1, { a with malloc = No_malloc }, mallocs)
    else
      (* Remove returning malloc *)
      let mallocs =
        if owning then Mallocs.remove a.malloc p.mallocs
        else Mallocs.remove_local a.malloc p.mallocs
      in
      let frees, mallocs = Mallocs.pop mallocs in
      (mk_free_after e1 frees, a, mallocs)
  in

  let p, e2, b =
    morph_expr { p with ret; mallocs = Mallocs.push Mlocal oldmallocs; vars } e2
  in
  let e2, b, bmallocs =
    if b.tailrec then
      let _, mallocs = Mallocs.pop p.mallocs in
      (e2, { b with malloc = No_malloc }, mallocs)
    else
      let mallocs =
        if owning then Mallocs.remove b.malloc p.mallocs
        else Mallocs.remove_local b.malloc p.mallocs
      in
      let frees, mallocs = Mallocs.pop mallocs in
      (mk_free_after e2 frees, b, mallocs)
  in

  let tailrec = a.tailrec && b.tailrec in

  (* Find out what's local and what isn't *)
  let amoved = Mallocs.diff_func oldmallocs amallocs in
  let bmoved = Mallocs.diff_func oldmallocs bmallocs in

  let mallocs = oldmallocs in
  (* Free what can be freed *)
  let e1, e2, malloc, mallocs =
    (* Mallocs which were moved in one branch need to be freed in the other *)
    let frees_a = mapdiff_flip bmoved amoved |> mlist_of_pmap in
    let frees_b = mapdiff_flip amoved bmoved |> mlist_of_pmap in

    let rm_path m path ms = Mallocs.remove (Path (Single m, path)) ms in
    let mallocs =
      Imap.fold
        (fun m pset ms ->
          if Pset.is_empty pset then
            (* Remove the whole malloc, not just a part *)
            Mallocs.remove (Single m) ms
          else Pset.fold (rm_path m) pset ms)
        (mapunion amoved bmoved) mallocs
    in
    let e1 =
      if a.tailrec then e1
      else
        let frees =
          match is_ctor_check cond.expr with
          (* Special case for pattern matches where the last clause is a let
             that returns the matched value as a whole. If the if-expression
             is moved, we would free the matched value here. Freeing isn't
             necessary, because we are in another branch here, meaning another
             ctor. Calling the free function is thus redundant. If,
             additionally, the if-expression is pre-allocated then we would
             free the returned-to value, which is a bug. This only happens if
             the condition is a ctor check and the 'b' clause returns the same
             value which is matched. We can check this using the alloc
             values. *)
          | Some expr ->
              let id =
                match expr.expr with
                | Mvar (id, _) -> id
                | _ -> failwith "Intenal Error: Not a variable expression"
              in
              let _, func = find_var id p.vars in
              if equal_alloc func.alloc b.alloc then
                match func.malloc with
                | Single a | Param a ->
                    List.filter (fun (i : malloc_id) -> i.id <> a.mid) frees_a
                | No_malloc -> frees_a
                | Path _ -> failwith "TODO path case"
              else frees_a
          | None -> frees_a
        in
        { e1 with expr = Mfree_after (e1, Only frees) }
    in
    let e2 =
      if b.tailrec then e2
      else { e2 with expr = Mfree_after (e2, Only frees_b) }
    in

    if owning && contains_allocation e1.typ then
      let mid = new_id malloc_id in
      let id = { Mid.mid; typ = e1.typ; parent = None } in
      let mallocs = Mallocs.add (Single id) mallocs in
      let mallocs =
        Mallocs.remove a.malloc mallocs |> Mallocs.remove b.malloc
      in
      (e1, e2, Malloc.Single id, mallocs)
    else (e1, e2, No_malloc, mallocs)
  in

  let owning =
    if owning then
      match malloc with
      | Single id -> Some id.mid
      | No_malloc | Param _ -> None
      | Path _ -> failwith "todo path"
    else None
  in
  ( { p with mallocs; vars },
    mk (Mif { cond; owning; e1; e2 }) ret,
    { a with alloc = Two_values (a.alloc, b.alloc); malloc; tailrec } )

and prep_let p id uniq e pass toplvl =
  (* username *)
  let un = reconstr_module_username ~mname:p.mname ~mainmod:p.mainmodule id in

  (* For owned values, increase alloc level so they get preallocated correctly.
     It's important we don't do this for borrowed values, because a borrowed
     value might be (partly) owned later, for instance in a ctor pattern. There,
     the level must not be increased, otherwise this borrowed value will be
     preallocated at its creation. *)
  let p = match pass with Dmove -> enter_level p | Dset | Dmut | Dnorm -> p in
  let vars = p.vars in
  let p, e1, func = morph_expr { p with ret = false } e in
  let ms, malloc, mallocs =
    match pass with
    | Dmove ->
        let mid = new_id malloc_id in
        let id = Mid.{ mid; typ = e1.typ; parent = None } in
        ([ mid ], Malloc.Single id, Mallocs.add (Single id) p.mallocs)
    | Dset | Dmut | Dnorm -> ([], func.malloc, p.mallocs)
  in

  let p, func = ({ p with mallocs; vars }, { func with malloc }) in

  let p, gn =
    match e.attr with
    | { const = true; mut = false; _ } ->
        let uniq = Module.unique_name ~mname:p.mname id uniq in
        (* Maybe we have to generate a new name here *)
        let cnt = new_id constant_uniq_state in
        Hashtbl.add constant_tbl uniq (cnt, e1, toplvl);
        ({ p with vars = Vars.add un (Const uniq) p.vars }, Some uniq)
    | ({ global = true; _ } | { const = true; _ }) when toplvl ->
        (* Globals are 'preallocated' at module level *)
        set_alloca p func.alloc;
        let uniq = Module.unique_name ~mname:p.mname id uniq in
        let cnt = new_id constant_uniq_state in
        Hashtbl.add global_tbl uniq (cnt, e1, toplvl);
        let used = ref false in
        let vars = Vars.add un (Global (uniq, func, used)) p.vars in
        (* Add global values to env with global id. That's how they might be
           queried, and the function information is needed for
           monomorphization *)
        let vars = Vars.add uniq (Global (uniq, func, used)) vars in
        ({ p with vars }, Some uniq)
    | _ ->
        (match pass with
        | Dmove -> set_alloca p func.alloc
        | Dset | Dmut | Dnorm -> ());
        ({ p with vars = Vars.add un (Normal func) p.vars }, None)
  in
  let p = match pass with Dmove -> leave_level p | Dset | Dmut | Dnorm -> p in
  (un, p, e1, gn, ms)

and morph_record mk p labels typ =
  let ret = p.ret in
  let p = { p with ret = false } in

  (* ret = false is threaded through p *)
  let p = enter_level p in

  (* Collect mallocs in initializer *)
  let f param (id, e) =
    let p, e, var = morph_expr param e in
    if is_struct e.typ then set_alloca p var.alloc;
    (* Should have been moved *)
    assert (var.malloc = No_malloc);
    (p, (id, e))
  in
  let p, labels = List.fold_left_map f p labels in
  let p = leave_level p in

  let _, malloc, mallocs = mb_malloc None p.mallocs typ in
  let ms = m_to_list malloc in

  let alloca = ref (request p) in
  ( { p with ret; mallocs },
    mk (Mrecord (labels, alloca, ms)) ret,
    { no_var with fn = No_function; alloc = Value alloca; malloc } )

and morph_field mk p expr index =
  let ret = p.ret in
  let p, e, func = morph_expr { p with ret = false } expr in
  let malloc = malloc_add_index index func.malloc in
  (* Field should not inherit alloca of its parent. Otherwise codegen might use
     a nested type as its parent *)
  ( { p with ret },
    mk (Mfield (e, index)) ret,
    { func with alloc = No_value; malloc } )

and morph_set mk p expr value moved =
  let ret = p.ret in
  (* We don't track allocations in the to-set expr. This helps with nested
     allocated things. If we do, there are additional relocations happening and
     the wrong things are freed. If one were to force an allocation here, that's
     a leak *)
  let mallocs = p.mallocs in
  let p, e, vfunc = morph_expr { p with ret = false } expr in
  let p, v, _ =
    morph_expr p (* { p with mallocs = Mallocs.empty Mlocal } *) value
  in

  (* For codegen, we report partial moves as not moved, because we generate the
     freeing code here. It's possibly to also generate the freeing code in the
     front end, but the way parts are tracked makes it a bit cumbersome: Parts
     track what is moved and here we want to free the inverse of that. *)
  let codegen_moved, v =
    match moved with
    | Snot_moved -> (false, v)
    | Spartially_moved -> (
        match Mallocs.find vfunc.malloc mallocs with
        | Some pmap ->
            let frees = mlist_of_pmap pmap in
            (true, mk_free_after v frees)
        | None -> (true, v))
    | Smoved -> (true, v)
  in

  let mallocs =
    match moved with
    | Smoved | Spartially_moved -> Mallocs.reenter vfunc.malloc p.mallocs
    | Snot_moved -> p.mallocs
  in

  let tree = mk (Mset (e, v, codegen_moved)) ret in

  (* TODO free the thing. This is right now done in codegen by calling free
     manually. Could also be added to the tree *)
  ({ p with ret; mallocs }, tree, no_var)

and morph_seq mk p expr cont =
  let ret = p.ret in
  let p, expr, _ = morph_expr { p with ret = false } expr in
  let p, cont, func = morph_expr { p with ret } cont in
  (p, mk (Mseq (expr, cont)) ret, func)

and prep_func p (usrname, uniq, abs) =
  (* If the function is concretely typed, we add it to the function list and add
     the usercode name to the bound variables. In the polymorphic case, we add
     the function to the bound variables, but not to the function list. Instead,
     the monomorphized instance will be added later *)
  let ftyp =
    Types.(Tfun (abs.func.tparams, abs.func.ret, abs.func.kind)) |> cln p
  in

  let call = Module.unique_name ~mname:p.mname usrname uniq in
  let username =
    reconstr_module_username ~mname:p.mname ~mainmod:p.mainmodule usrname
  in

  let alloca = ref (request p) in
  let alloc = Value alloca in

  let kind = cln_kind p abs.func.kind in
  if (not p.gen_poly_bodies) && is_type_polymorphic ftyp then (
    let fn = Polymorphic call in
    let vars = Vars.add username (Normal { no_var with fn; alloc }) p.vars in
    let fn () =
      let p = { p with gen_poly_bodies = true } in
      let p, _ = prep_func p (usrname, uniq, abs) in
      p
    in
    Hashtbl.add deferredfunc_tbl call fn;
    ({ p with vars }, (call, kind, ftyp, alloca)))
  else
    let recursive = if abs.is_rec then Rnormal else Rnone in
    let inline = abs.inline in

    let func =
      {
        params = List.map (cln_param p) abs.func.tparams;
        ret = cln p abs.func.ret;
        kind;
      }
    in
    let pnames =
      List.map
        (fun n ->
          let malloc = new_id malloc_id in
          (n, malloc))
        abs.nparams
    in

    (* Make sure recursion works and the current function can be used in its body *)
    let temp_p =
      let alloc =
        if is_struct func.ret then Value (ref (request p)) else No_value
      in
      (* TODO make it impossible to recursively call an inline function *)
      let value = { no_var with fn = Forward_decl (call, ftyp); alloc } in
      let vars = Vars.add username (Normal value) p.vars in

      (* Add parameters to env as normal values.
         The existing values might not be 'normal' *)
      let mallocs = Mallocs.push Mfunc p.mallocs in
      let vars, mallocs = add_params vars mallocs pnames func.params
      and recursion_stack = (call, recursive) :: p.recursion_stack in

      {
        p with
        vars;
        ret = (if not inline then true else p.ret);
        mallocs;
        toplvl = false;
        recursion_stack;
      }
    in

    let temp_p = enter_level temp_p in
    let temp_p, body, var = morph_expr temp_p abs.body in
    (* Set alloca in lower level. This deals with closed over allocas which are returned *)
    if is_struct body.typ then set_alloca p var.alloc;
    let temp_p = leave_level temp_p in

    (* Remove parameters from malloc list. We need them temporarily for freeing in Set *)
    let tmp_mallocs =
      List.fold_left2
        (fun acc (_, mid) p ->
          let id = malloc_id_of_param mid p in
          if not p.pmoved then Mallocs.remove (Param id) acc else acc)
        temp_p.mallocs pnames func.params
    in

    let frees = Mallocs.pop tmp_mallocs |> fst in
    let body = mk_free_after body frees in
    let recursive = pop_recursion_stack temp_p in

    (* Collect functions from body *)
    let p =
      { p with monomorphized = temp_p.monomorphized; funcs = temp_p.funcs }
    in
    let upward () = match !alloca with Preallocated -> true | _ -> false in

    let abs = { func; pnames; body } in
    let name = { user = username; call } in
    let gen_func = { abs; name; recursive; upward; monomorphized = false } in

    let p =
      if inline then
        let fn = Inline (pnames, ftyp, body) in
        let vars =
          Vars.add username (Normal { no_var with fn; alloc }) p.vars
        in
        { p with vars }
      else if is_type_polymorphic ftyp then (
        let fn = Polymorphic call in
        let vars =
          Vars.add username (Normal { no_var with fn; alloc }) p.vars
        in
        Hashtbl.add poly_funcs_tbl call gen_func;
        { p with vars })
      else
        let fn = Concrete (gen_func, call) in
        let vars =
          Vars.add username (Normal { no_var with fn; alloc }) p.vars
        in
        let funcs = Fset.add gen_func p.funcs in
        { p with vars; funcs }
    in
    (p, (call, func.kind, ftyp, alloca))

and morph_lambda mk typ p id abs =
  let ftyp = cln p typ in

  (* TODO fix lambdas for nested modules *)
  let name = Module.lambda_name ~mname:p.mname id in

  (* Function can be returned themselves. In that case, a closure object will be
     generated, so treat it the same as any local allocation *)
  let alloca = ref (request p) in
  let ret = p.ret in

  let kind = cln_kind p abs.func.kind in
  if (not p.gen_poly_bodies) && is_type_polymorphic ftyp then (
    let fn = Polymorphic name in
    let vars = Vars.add name (Normal { no_var with fn }) p.vars in
    let genfn () =
      let p = { p with gen_poly_bodies = true } in
      let p, _, _ = morph_lambda mk typ p id abs in
      p
    in
    Hashtbl.add deferredfunc_tbl name genfn;
    ( { p with vars; ret },
      mk (Mlambda (name, kind, ftyp, alloca)) ret,
      { no_var with fn; alloc = Value alloca } ))
  else
    let recursive = Rnone in
    let func =
      {
        params = List.map (cln_param p) abs.func.tparams;
        ret = cln p abs.func.ret;
        kind;
      }
    in
    let pnames =
      List.map
        (fun n ->
          let malloc = new_id malloc_id in
          (n, malloc))
        abs.nparams
    in

    let vars = p.vars in
    (* lambdas don't recurse, but functions inside the body might *)
    let recursion_stack = (name, recursive) :: p.recursion_stack in
    let temp_p =
      (* Add parameters to env as normal values.
         The existing values might not be 'normal' *)
      let mallocs = Mallocs.push Mfunc p.mallocs in
      let vars, mallocs = add_params vars mallocs pnames func.params in

      { p with vars; ret = true; mallocs; toplvl = false; recursion_stack }
    in

    let temp_p = enter_level temp_p in
    let temp_p, body, var = morph_expr temp_p abs.body in
    (* Set alloca in lower level. This deals with closed over allocas which are returned *)
    if is_struct body.typ then set_alloca p var.alloc;
    let temp_p = leave_level temp_p in

    (* Collect functions from body *)
    let p =
      { p with monomorphized = temp_p.monomorphized; funcs = temp_p.funcs }
    in

    (* Remove parameters from malloc list. We need them temporarily for freeing in Set *)
    let tmp_mallocs =
      List.fold_left2
        (fun acc (_, mid) p ->
          let id = malloc_id_of_param mid p in
          if not p.pmoved then Mallocs.remove (Param id) acc else acc)
        temp_p.mallocs pnames func.params
    in

    let frees = Mallocs.pop tmp_mallocs |> fst in
    let body = mk_free_after body frees in

    let upward () = match !alloca with Preallocated -> true | _ -> false in

    let abs = { func; pnames; body } in
    (* lambdas have no username, so we just repeat the call name *)
    let names = { call = name; user = name } in
    let monomorphized = false in
    let gen_func = { abs; name = names; recursive; upward; monomorphized } in

    let p = { p with vars } in
    let p, fn =
      if is_type_polymorphic ftyp then (
        (* Add fun to env so we can query it later for monomorphization *)
        let fn = Polymorphic name in
        let vars = Vars.add name (Normal { no_var with fn }) p.vars in
        Hashtbl.add poly_funcs_tbl name gen_func;
        ({ p with vars }, Polymorphic name))
      else
        let funcs = Fset.add gen_func p.funcs in
        ({ p with funcs }, Concrete (gen_func, name))
    in

    (* Save fake env with call name for monomorphization *)
    Apptbl.add apptbl name p;

    ( { p with ret },
      mk (Mlambda (name, func.kind, ftyp, alloca)) ret,
      { no_var with fn; alloc = Value alloca } )

and morph_app mk p callee args ret_typ =
  (* Save env for later monomorphization *)
  let id = new_id malloc_id in

  let ret = p.ret in
  let p, ex, _ = morph_expr { p with ret = false } callee in
  let p, monomorph = monomorphize_call p ex None in
  let callee = { ex; monomorph; mut = false } in

  let tailrec, p =
    if ret then
      match callee.monomorph with
      | Recursive name ->
          let p = set_tailrec p name.nonmono in
          (true, p)
      | _ -> (false, p)
    else (false, p)
  in

  let f p (arg, attr) =
    let is_arg = function
      | Malloc.No_malloc -> false
      | Param _ -> true
      | Single _ -> false
      | Path _ -> (* A path cannot be a passed argument *) false
    in
    let ret = p.ret in
    let p, ex, var = morph_expr { p with ret = false } arg in
    let is_moved =
      match attr with Typed_tree.Dmove -> true | Dset | Dmut | Dnorm -> false
    in
    let mallocs, ex =
      if tailrec then (Mallocs.remove var.malloc p.mallocs, ex)
      else (p.mallocs, ex)
    in
    let p, monomorph = monomorphize_call { p with mallocs } ex None in
    ( { p with ret },
      ex,
      monomorph,
      (* If an argument is passed by move this means the parameter is also owned
         and will be freed in a tailrec call *)
      is_arg var.malloc || is_moved )
  in

  let rec fold_decr_last p args = function
    | [ (arg, attr) ] ->
        let mut = Types.mut_of_pattr attr in
        let p, ex, monomorph, arg = f p (arg, attr) in
        let _, ex =
          if tailrec then Mallocs.empty_func ex p.mallocs else (p.mallocs, ex)
        in
        (p, ({ ex; monomorph; mut }, arg) :: args)
    | (arg, attr) :: tl ->
        let mut = Types.mut_of_pattr attr in
        let p, ex, monomorph, arg = f p (arg, attr) in
        fold_decr_last p (({ ex; monomorph; mut }, arg) :: args) tl
    | [] -> (p, [])
  in
  let p, args = fold_decr_last p [] args in
  let args = List.rev args in
  let p, callee =
    match args with
    | [] when tailrec ->
        (* We haven't decreased references yet, because there is no last
           argument. Essentially, we do the same work as in the last arg of
           [fold_decr_last]*)
        (* Note that we use the original p.ids for [decr_refs] *)
        let _, ex = Mallocs.empty_func callee.ex p.mallocs in
        (p, { callee with ex })
    | _ -> (p, callee)
  in

  Apptbl.add apptbl (string_of_int id) p;

  let alloc, alloc_ref =
    if is_struct callee.ex.typ then
      (* For every call, we make a new request. If the call is the return value
         of a function, the request will be change to [Preallocated] in
         [morph_func] or [morph_lambda] above. *)
      let req = ref (request p) in
      (Value req, req)
    else (No_value, ref (request p))
  in

  let malloc, mallocs =
    (* array-get does not return a temporary. If its value is returned in a
       function, increase value's refcount so that it's really a temporary *)
    match callee.monomorph with
    | Builtin ((Array_get | Fixed_array_get), _) -> (Malloc.No_malloc, p.mallocs)
    | _ ->
        let _, malloc, mallocs = mb_malloc None p.mallocs ret_typ in
        (malloc, mallocs)
  in

  let ms = m_to_list malloc in

  let app = Mapp { callee; args; alloca = alloc_ref; id; ms } in

  ({ p with ret; mallocs }, mk app ret, { no_var with alloc; malloc; tailrec })

and morph_ctor mk p variant index expr typ =
  let ret = p.ret in
  let p = { p with ret = false } in

  let p = enter_level p in

  let p, ctor =
    match expr with
    | Some expr ->
        (* Similar to [morph_record], collect mallocs in data *)
        let p, e, var = morph_expr p expr in
        if is_struct e.typ then set_alloca p var.alloc;
        (* Should have been moved *)
        assert (var.malloc = No_malloc);
        (p, (variant, index, Some e))
    | None -> (p, (variant, index, None))
  in

  let p = leave_level p in

  let _, malloc, mallocs = mb_malloc None p.mallocs typ in
  let ms = m_to_list malloc in

  let alloca = ref (request p) in
  ( { p with ret; mallocs },
    mk (Mctor (ctor, alloca, ms)) ret,
    { no_var with fn = No_function; alloc = Value alloca; malloc } )

(* Both variant exprs are as default as possible.
   We handle everything in codegen *)
and morph_var_index mk p expr =
  let ret = p.ret in
  (* False because we only use it interally in if expr? *)
  let p, e, func = morph_expr { p with ret = false } expr in
  ({ p with ret }, mk (Mvar_index e) ret, { func with alloc = No_value })

and morph_var_data mk p expr typ =
  let ret = p.ret in
  (* False because we only use it interally in if expr? *)
  let p, e, func = morph_expr { p with ret = false } expr in
  let mid, malloc =
    if contains_allocation typ then
      let mid = new_id malloc_id in
      let id = Malloc.Single { mid; typ; parent = Some func.malloc } in
      (Some mid, id)
    else (None, No_malloc)
  in
  let func =
    (* Since we essentially change the datatype here, we have to be sure that
       the variant was allocated before. Usually it is, but in the case of toplevel
       lets it might not. For instance if we have an (option t) which is matched on
       at assignment. Then, the global value is t, but if we propagate the alloc,
       the parent (option t) will try to initialize into the global value, which is t,
       another type.*)
    if p.toplvl then
      let alloc = Value (ref (request p)) in
      { func with alloc }
    else func
  in
  ({ p with ret }, mk (Mvar_data (e, mid)) ret, { func with malloc })

and morph_fmt mk p exprs =
  let ret = p.ret in
  let p = { p with ret = false } in

  let f p = function
    | Typed_tree.Fexpr e ->
        let p, e, _ = morph_expr p e in
        (p, Fexpr e)
    | Fstr s -> (p, Fstr s)
  in
  let p = enter_level p in
  let p, es = List.fold_left_map f p exprs in
  let p = leave_level p in

  let alloca = ref (request p) in
  let mid = new_id malloc_id in
  let malloc = Malloc.Single { mid; typ = Tarray Tu8; parent = None } in
  let mallocs = Mallocs.add malloc p.mallocs in

  ( { p with ret; mallocs },
    mk (Mfmt (es, alloca, mid)) ret,
    { no_var with alloc = Value alloca; malloc } )

and morph_print_str mk p exprs =
  let ret = p.ret in
  let p = { p with ret = false } in

  let f p = function
    | Typed_tree.Fexpr e ->
        let p, e, _ = morph_expr p e in
        (p, Fexpr e)
    | Fstr s -> (p, Fstr s)
  in
  let p = enter_level p in
  let p, es = List.fold_left_map f p exprs in
  let p = leave_level p in

  ({ p with ret }, mk (Mprint_str es) ret, no_var)

let rec morph_toplvl param items =
  let rec aux param = function
    | [] ->
        let loc = (Lexing.dummy_pos, Lexing.dummy_pos) in
        ( param,
          { typ = Tunit; expr = Mconst Unit; return = true; loc; const = Cnot },
          no_var )
    | [ (mname, Typed_tree.Tl_expr e) ] ->
        let param = { param with mname } in
        morph_expr param e
    | (mname, item) :: tl ->
        let param = { param with mname } in
        aux_impl param tl item
  and aux_impl param tl = function
    | Typed_tree.Tl_let { id; uniq; lhs = expr; pass; _ } ->
        let kind = let_kind pass in
        let un, p, e1, gn, ms = prep_let param id uniq expr pass true in
        let p, e2, func = aux { p with ret = param.ret } tl in
        (p, { e2 with expr = Mlet (un, e1, kind, gn, ms, e2) }, func)
    | Tl_function (loc, name, uniq, abs) ->
        let p, (call, kind, ftyp, alloca) = prep_func param (name, uniq, abs) in
        let p, cont, func = aux { p with ret = param.ret } tl in
        ( p,
          {
            typ = cont.typ;
            expr = Mfunction (call, kind, ftyp, cont, alloca);
            return = param.ret;
            loc;
            const = Cnot;
          },
          func )
    | Tl_bind (id, expr) ->
        let id =
          reconstr_module_username ~mname:param.mname ~mainmod:param.mainmodule
            id
        in
        let p, e1, func = morph_expr { param with ret = false } expr in
        (* top level function aliases *)
        let var =
          match e1.expr with
          | Mvar (id, Vglobal _) ->
              (* It's already used, we don't care about the actual value *)
              Global (id, func, ref false)
          | _ -> Normal func
        in
        let p, e2, func = aux { p with vars = Vars.add id var p.vars } tl in
        (p, { e2 with expr = Mbind (id, e1, e2) }, func)
    | Tl_mutual_rec_decls decls ->
        let p = List.fold_left rec_fs_to_env param decls in
        aux { p with ret = param.ret } tl
    | Tl_expr e ->
        let p, e, _ = morph_expr param e in
        let p, cont, func = aux { p with ret = param.ret } tl in
        ( p,
          {
            typ = cont.typ;
            expr = Mseq (e, cont);
            return = param.ret;
            loc = e.loc;
            const = Cnot;
          },
          func )
    | Tl_module mitems ->
        let p, e, _ = morph_toplvl param mitems in
        let p, cont, func = aux { p with ret = param.ret } tl in
        ( p,
          {
            typ = cont.typ;
            expr = Mseq (e, cont);
            return = param.ret;
            loc = e.loc;
            const = Cnot;
          },
          func )
    | Tl_module_alias _ -> aux param tl
  in
  aux param items

let monomorphize ~mname { Typed_tree.externals; items; _ } =
  reset ();

  let vars =
    Builtin.(
      fold (fun str (kind, _) vars ->
          Vars.add str (Normal { no_var with fn = Builtin kind }) vars))
      Vars.empty
  in

  (* External are globals. By marking them [Global] here, we don't have to
     introduce a special case in codegen, or mark them Const_ptr when they are not *)
  let vars =
    List.fold_left
      (fun vars { Env.ext_cname; ext_name; used; imported; _ } ->
        let cname =
          match ext_cname with None -> ext_name | Some cname -> cname
        in
        let ext_name =
          match imported with
          | Some (mname', _) ->
              reconstr_module_username ~mname:mname' ~mainmod:mname ext_name
          | None -> ext_name
        in
        Vars.add ext_name (Global (cname, no_var, used)) vars)
      vars externals
  in

  let param =
    let () = assert (!malloc_id = 1) in
    {
      vars;
      monomorphized = Sset.empty;
      funcs = Fset.empty;
      ret = false;
      mallocs = Mallocs.empty Mfunc;
      toplvl = true;
      mname;
      mainmodule = mname;
      alloc_lvl = 1;
      recursion_stack = [];
      gen_poly_bodies = false;
    }
  in
  let p, tree, _ = morph_toplvl param items in

  (* Add missing monomorphized functions from rec blocks *)
  let p =
    Hashtbl.fold
      (fun call (p, concrete, parent_sub) realp ->
        let p =
          { p with funcs = realp.funcs; monomorphized = realp.monomorphized }
        in
        let p, _ =
          match Hashtbl.find_opt poly_funcs_tbl call with
          | Some func ->
              let typ = typ_of_abs func.abs in
              monomorphize p typ concrete func parent_sub
          | None ->
              failwith
                ("Internal Error: Poly function not registered yet: " ^ call)
        in
        {
          realp with
          funcs = Fset.union p.funcs realp.funcs;
          monomorphized = Sset.union p.monomorphized realp.monomorphized;
        })
      missing_polys_tbl p
  in

  let frees =
    match Mallocs.pop p.mallocs |> fst with
    | [] -> Seq.empty
    | mallocs -> List.to_seq mallocs
  in

  let externals =
    List.filter_map
      (fun { Env.imported; ext_name; ext_typ = t; ext_cname; used; closure } ->
        if not !used then None
        else
          let cname =
            match ext_cname with None -> ext_name | Some cname -> cname
          in
          let c_linkage =
            match imported with
            (* A value is either imported or a real external decl (eg C function) *)
            | None | Some (_, `C) -> true
            | Some (_, `Schmu) -> false
          in
          Some { ext_name; ext_typ = cln p t; c_linkage; cname; closure })
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

  let funcs = Fset.to_seq p.funcs |> List.of_seq in
  { constants; globals; externals; tree; funcs; frees }
