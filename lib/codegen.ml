open Types
module Vars = Map.Make (String)
module PMap = Polyvars.PolyMap
module PVars = Polyvars.PolyLvls
module Set = Set.Make (String)

module Str = struct
  type t = string

  let hash = Hashtbl.hash

  let equal = String.equal
end

module Strtbl = Hashtbl.Make (Str)

type monomorphized = { subst : typ Vars.t; func_uname : string }

(* TODO This can be merged with Tfun record *)
type user_func = {
  name : string * bool;
  params : string list;
  typ : typ;
  body : Typing.typed_expr;
  mono : monomorphized option;
}

type llvar = { value : Llvm.llvalue; typ : typ; lltyp : Llvm.lltype }

let ( ++ ) = Seq.append

let record_tbl = Strtbl.create 32

let mono_tbl = Strtbl.create 32

let context = Llvm.global_context ()

let the_module = Llvm.create_module context "context"

let fpm = Llvm.PassManager.create_function the_module

let _ = Llvm.PassManager.initialize fpm

(* Segfaults on my fedora box!? *)
(* let () = Llvm_scalar_opts.add_instruction_combination fpm *)

(* let () = Llvm_scalar_opts.add_reassociation fpm *)

(* Is somehow needed to make tail call optimization work *)
let () = Llvm_scalar_opts.add_gvn fpm

(* let () = Llvm_scalar_opts.add_cfg_simplification fpm *)

let () = Llvm_scalar_opts.add_tail_call_elimination fpm

let builder = Llvm.builder context

let int_type = Llvm.i32_type context

let num_type = Llvm.i64_type context

let bool_type = Llvm.i1_type context

let unit_type = Llvm.void_type context

let voidptr_type = Llvm.(i8_type context |> pointer_type)

let poly_var_type = Llvm.(num_type |> pointer_type)

let closure_type =
  let t = Llvm.named_struct_type context "closure" in
  let typ = [| voidptr_type; voidptr_type |] in
  Llvm.struct_set_body t typ false;
  t

let generic_type = Llvm.named_struct_type context "generic"

let byte_type = Llvm.i8_type context

let memcpy_decl =
  lazy
    (let open Llvm in
    (* llvm.memcpy.inline.p0i8.p0i8.i64 *)
    let ft =
      function_type unit_type
        [| voidptr_type; voidptr_type; num_type; bool_type |]
    in
    declare_function "llvm.memcpy.p0i8.p0i8.i64" ft the_module)

(* Named structs for records *)

let is_generic_record = function
  (* TODO recurse *)
  | Trecord (Some i, _, labels) -> (
      match labels.(i) |> snd with Qvar _ -> true | _ -> false)
  | Trecord _ -> false
  | _ -> failwith "Internal Error: Not a record"

let rec record_name ?(poly = false) = function
  (* We match on each type here to allow for nested parametrization like [int foo bar].
     [poly] argument will create a name used for a poly var, ie spell out the generic name *)
  | Trecord (param, name, labels) ->
      let some p =
        let p = labels.(p) |> snd in
        (match p with
        | Qvar id -> if poly then id else "generic"
        | t -> record_name t)
        ^ "_"
      in
      Printf.sprintf "%s%s" (Option.fold ~none:"" ~some param) name
  | t -> Typing.string_of_type t

let record_poly_ids typ =
  let rec inner acc = function
    | Trecord (Some i, _, labels) as t ->
        inner (record_name ~poly:true t :: acc) (labels.(i) |> snd)
    | Qvar id -> id :: acc
    | _ -> acc
  in
  inner [] typ |> List.rev

(*
   Polymorphism util functions
*)

let poly_name poly = "__" ^ poly

let poly_param_name name = "__p_" ^ name

let get_poly_size name index var =
  let ptr = Llvm.(build_gep var [| const_int int_type index |]) "" builder in
  Llvm.build_load ptr ("_" ^ name) builder

let poly_arg_of_size sz =
  let arg = Llvm.build_alloca num_type "" builder in
  let ptr = Llvm.(build_gep arg [| const_int int_type 0 |]) "" builder in
  ignore (Llvm.build_store sz ptr builder);
  arg

let rec add_poly_vars poly_vars = function
  | Qvar id ->
      (* Later, this will be poly_name. I don't want to change everything now *)
      (* Will only be added if the level is lower *)
      PVars.add_single id poly_vars
  | Tfun (ps, r, _) ->
      let poly_vars = List.fold_left add_poly_vars poly_vars ps in
      add_poly_vars poly_vars r
  | Tvar { contents = Link t } -> add_poly_vars poly_vars t
  | Trecord (Some _, _, _) as t when is_generic_record t ->
      (* For generic records, we add both the size of the generic record as a whole,
         as wenll as the poly var it contains *)
      let ids = record_poly_ids t in
      PVars.add_container ids poly_vars
  | _ -> poly_vars

let rec get_lltype ?(param = true) = function
  (* For functions, when passed as parameter, we convert it to a closure ptr
     to later cast to the correct types. At the application, we need to
     get the correct type though to cast it back. All this is handled by [param]. *)
  | Tint -> int_type
  | Tbool -> bool_type
  | Tvar { contents = Link t } -> get_lltype ~param t
  | Tunit -> unit_type
  | Tfun (params, ret, kind) ->
      typeof_func ~param ~decl:false (params, ret, kind)
  | Trecord _ as t -> (
      let name = record_name t in
      match Strtbl.find_opt record_tbl name with
      | Some t -> if param then t |> Llvm.pointer_type else t
      | None ->
          failwith (Printf.sprintf "Record struct not found for type %s" name))
  | Qvar _ -> generic_type |> Llvm.pointer_type
  | Tvar _ as t ->
      failwith (Printf.sprintf "Wrong type TODO: %s" (Typing.string_of_type t))

(* LLVM type of closure struct and records *)
and typeof_aggregate agg =
  Array.map (fun (_, typ) -> get_lltype ~param:false typ) agg
  |> Llvm.struct_type context

and typeof_func ~param ~decl (params, ret, kind) =
  if param then closure_type |> Llvm.pointer_type
  else
    (* When [get_lltype] is called on a function, we handle the dynamic case where
       a function or closure is being passed to another function.
       If a record is returned, we allocate it at the caller site and
       pass it as first argument to the function *)
    let prefix, ret_t =
      match ret with
      | (Trecord _ as t) | (Qvar _ as t) ->
          (Seq.return (get_lltype ~param:true t), unit_type)
      | t -> (Seq.empty, get_lltype ~param t)
    in
    let t = Tfun (params, ret, kind) in
    let pvars =
      add_poly_vars PVars.empty t
      |> PVars.to_params
      |> Seq.map (Fun.const poly_var_type)
    in
    let suffix =
      (* A closure needs an extra parameter for the environment  *)
      if decl then
        match kind with
        | Closure _ -> pvars ++ Seq.return voidptr_type
        | _ -> pvars
      else pvars ++ Seq.return voidptr_type
    in
    let params_t =
      (* For the params, we want to produce the param type, hence ~param:true *)
      List.to_seq params |> Seq.map (get_lltype ~param:true) |> fun seq ->
      prefix ++ seq ++ suffix |> Array.of_seq
    in
    let ft = Llvm.function_type ret_t params_t in
    ft

type poly_var_kind = Param | Local of typ

let to_named_records = function
  | Trecord (_, name, _) as r when is_generic_record r ->
      let name = Printf.sprintf "generic_%s" name in
      let t = Llvm.named_struct_type context name in
      (if Strtbl.mem record_tbl name then
       let records =
         Strtbl.fold (fun key _ acc -> key :: acc) record_tbl []
         |> String.concat ", "
       in
       let () = print_endline records in

       failwith ("Internal Error: Type shadowing for generic " ^ name));
      Strtbl.add record_tbl name t
  | Trecord (_, _, labels) as t ->
      let name = record_name t in
      let t = Llvm.named_struct_type context name in
      let lltyp = typeof_aggregate labels |> Llvm.struct_element_types in
      Llvm.struct_set_body t lltyp false;

      if Strtbl.mem record_tbl name then
        failwith "Internal Error: Type shadowing not supported in codegen TODO";
      Strtbl.add record_tbl name t
  | _ -> failwith "Internal Error: Only records should be here"

(*
   Size and alignment.
   For generic records, we calculate a lot of stuff at runtime, which might be slow.
   For now, it's fine, but this should be improved somewhere in the future
*)

type 'a size_pr = { size : 'a; align : 'a }

type size = Static of int size_pr | Dynamic of Llvm.llvalue size_pr

type upto = Static' of int | Dynamic' of Llvm.llvalue

(* TODO size and alignment calculations are broken
   1. A function passed as a closure is not 8 bytes, but 16 (2 * 8 bytes)
   2. The alignment is different from the size. We have to keep align and size separate in [upto] *)

let build_dynamic_alignup ~size ~upto =
  let sum = Llvm.build_add size upto "sum" builder in
  let sub = Llvm.build_sub sum (Llvm.const_int num_type 1) "sub" builder in
  let div = Llvm.build_udiv sub upto "div" builder in
  Llvm.build_mul div upto "alignup" builder

let build_dynamic_size_align { size; align } ~upto =
  let alignedup = build_dynamic_alignup ~size ~upto in
  let size = Llvm.build_add upto alignedup "size" builder in

  let cmp = Llvm.(build_icmp Icmp.Slt align upto "cmp") builder in
  let align = Llvm.build_select cmp upto align "align" builder in
  { size; align }

let alignup_static ~size ~upto =
  let modulo = size mod upto in
  if Int.equal modulo 0 then (* We are aligned *)
    size else size + (upto - modulo)

let add_size_align ~upto size =
  match (size, upto) with
  | Static { size; align }, Static' upto ->
      let size = alignup_static ~size ~upto + upto in
      let align = max align upto in
      Static { size; align }
  | Dynamic pair, Dynamic' upto -> Dynamic (build_dynamic_size_align ~upto pair)
  | Static _, Dynamic' _ | Dynamic _, Static' _ ->
      failwith "Internal Error: Mismatch in size calculation"

let make_upto upto = function
  | Static _ -> Static' upto
  | Dynamic _ -> Dynamic' (Llvm.const_int num_type upto)

let alignup ~upto size =
  match (size, upto) with
  | Static' size, Static' upto ->
      let size = alignup_static ~size ~upto in
      Static' size
  | Dynamic' size, Dynamic' upto -> Dynamic' (build_dynamic_alignup ~size ~upto)
  | Static' _, Dynamic' _ | Dynamic' _, Static' _ ->
      failwith "Internal Error: Mismatch in align calculation"

let add_uptos ~upto size =
  match (size, upto) with
  | Static' size, Static' upto -> Static' (size + upto)
  | Dynamic' size, Dynamic' upto ->
      Dynamic' (Llvm.build_add size upto "addtmp" builder)
  | Static' _, Dynamic' _ | Dynamic' _, Static' _ ->
      failwith "Internal Error: Mismatch in size addition"

(* Returns the size pair, so we can continue statically below in [offset_of] *)
let sizeof_typ vars typ =
  let rec inner size_pr typ =
    let size_from_vars name =
      match (Vars.find_opt name vars, size_pr) with
      | Some upto, Static { size; align } ->
          let upto = upto.value in
          (* We need to change size and align to llvalues, then continue dynamically *)
          if size = 0 then
            (* If we are at the beginning of a structure, we are already aligned *)
            Dynamic { size = upto; align = upto }
          else
            let size = Llvm.const_int num_type size in
            let align = Llvm.const_int num_type align in

            add_size_align ~upto:(Dynamic' upto) (Dynamic { size; align })
      | Some upto, Dynamic _ ->
          (* Carry on *)
          let upto = upto.value in
          add_size_align ~upto:(Dynamic' upto) size_pr
      | None, _ ->
          print_string "env: ";
          print_endline
            (String.concat ", "
               (List.map (fun a -> "'" ^ fst a ^ "'") (Vars.bindings vars)));
          Llvm.dump_module the_module;

          failwith ("Cannot find Qvar id: " ^ name)
    in

    match typ with
    | Tint ->
        let upto = make_upto 4 size_pr in
        add_size_align ~upto size_pr
    | Tbool -> (
        (* No need to align one byte *)
        match size_pr with
        | Static { size; align } -> Static { size = size + 1; align }
        | Dynamic { size; align } ->
            let byte_size = Llvm.const_int num_type 1 in
            let size = Llvm.build_add size byte_size "add" builder in
            Dynamic { size; align })
    | Tunit -> failwith "Does this make sense?"
    | Tvar { contents = Link t } -> inner size_pr t
    | Tfun _ ->
        (* Just a ptr? Assume 64bit *)
        let upto = make_upto 8 size_pr in
        add_size_align ~upto size_pr
    | Trecord _ as t when is_generic_record t ->
        size_from_vars (record_name ~poly:true t |> poly_name)
    | Trecord (_, _, labels) ->
        Array.fold_left (fun pr (_, t) -> inner pr t) size_pr labels
    | Qvar id -> size_from_vars (poly_name id)
    | Tvar _ ->
        Llvm.dump_module the_module;
        failwith "too generic for a size"
  in
  match inner (Static { size = 0; align = 1 }) typ with
  | Static { size; align = upto } -> Static' (alignup_static ~size ~upto)
  | Dynamic { size; align = upto } ->
      (* If there is only one (dynamic) item, we are already aligned *)
      if size <> upto then Dynamic' (build_dynamic_alignup ~size ~upto)
      else Dynamic' size

let llval_of_upto = function
  | Static' size -> Llvm.const_int num_type size
  | Dynamic' size -> size

let match_size ~upto size =
  match (upto, size) with
  | Dynamic' _, Dynamic' _ | Static' _, Static' _ -> (upto, size)
  | Dynamic' _, Static' size ->
      let size = Llvm.const_int num_type size in
      (upto, Dynamic' size)
  | Static' upto, Dynamic' _ -> (Dynamic' (Llvm.const_int num_type upto), size)

(* Returns offset to [label] at [index] in byte *)
(* TODO we don't neccessarily need to carry the alignment with us *)
let offset_of ?(start = (0, Static' 0)) vars ~labels index =
  let rec inner i ~size =
    if i < index then
      let upto = sizeof_typ vars (labels.(i) |> snd) in
      let upto, size = match_size ~upto size in
      let align = alignup ~upto size in
      let size = add_uptos ~upto align in
      inner (i + 1) ~size
    else if i = 0 then (* We are aligned *) size
    else
      (* We have to align from current size *)
      let upto = sizeof_typ vars (labels.(i) |> snd) in
      let upto, size = match_size ~upto size in
      alignup ~upto size
  in
  let start, size = start in
  match inner start ~size with
  | Static' size -> Llvm.const_int num_type size
  | Dynamic' size -> size

(* Given two ptr types (most likely to structs), copy src to dst *)
let memcpy ~dst ~src ~size =
  let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
  let retptr = Llvm.build_bitcast src.value voidptr_type "" builder in
  let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
  ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder)

let set_record_field vars value ptr =
  match value.typ with
  | Trecord _ ->
      let size = sizeof_typ vars value.typ |> llval_of_upto in
      memcpy ~dst:ptr ~src:value ~size
  | _ -> ignore (Llvm.build_store value.value ptr builder)

(*
   Module state
*)

let lambda_name id = "__fun" ^ string_of_int id

(* for named functions *)
let unique_name = function
  | name, None -> name
  | name, Some n -> name ^ "__" ^ string_of_int n

(* Transforms abs into a Tfun and cleans all types (resolves links) *)
let split_abs (abs : Typing.abstraction) =
  let params = List.map clean abs.tp.tparams in
  (Tfun (params, clean abs.body.typ, abs.tp.kind), abs.nparams)

let is_type_generic typ =
  let rec inner acc = function
    | Qvar _ | Tvar { contents = Unbound _ } -> true
    | Tvar { contents = Link t } -> inner acc t
    | Tvar _ -> failwith "annot should not be here"
    | Trecord (Some i, _, labels) -> inner acc (labels.(i) |> snd)
    | Tfun (params, ret, _) ->
        let acc = List.fold_left inner acc params in
        inner acc ret
    | Tbool | Tunit | Tint | Trecord _ -> acc
  in
  inner false typ

let get_mono_name (name, is_named) ~poly concrete =
  let rec str = function
    | Tint -> "i"
    | Tbool -> "b"
    | Tunit -> "u"
    | Tvar { contents = Link t } -> str t
    | Tfun (ps, r, _) ->
        Printf.sprintf "%s.%s" (String.concat "" (List.map str ps)) (str r)
    | Trecord (Some i, name, labels) ->
        Printf.sprintf "%s%s" name (labels.(i) |> snd |> str)
    | Trecord (_, name, _) -> name
    | Qvar _ | Tvar _ -> "g"
  in
  (Printf.sprintf "__%s_%s_%s" (str poly) name (str concrete), is_named)

let subst_type ~poly concrete =
  (* let subst = Strtbl.create 16 in *)
  let rec inner subst = function
    | l, Tvar { contents = Link r } -> inner subst (l, r)
    | Qvar id, t -> (
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
      when is_generic_record l ->
        assert (i = j);
        (* No Array.fold_left_map for pre 4.13? *)
        let labels = Array.copy l1 in
        let f (subst, i) (ls, lt) =
          let _, r = l2.(i) in
          let subst, t = inner subst (lt, r) in
          labels.(i) <- (ls, t);
          (subst, i + 1)
        in
        let subst, _ = Array.fold_left f (subst, 0) l1 in
        (subst, Trecord (Some i, record, labels))
    | t, _ -> (subst, t)
  in
  inner Vars.empty (poly, concrete)

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)
(* TODO make a whole AST pass out of this. This also makes gen_app
   easier with less code duplication *)
let extract expr =
  let rec inner param = function
    | Typing.Var _ | Const _ -> param
    | Bop (_, e1, e2) -> inner (inner param e1.expr) e2.expr
    | If (cond, e1, e2) ->
        let param = inner param cond.expr in
        let param = inner param e1.expr in
        inner param e2.expr
    | Function (name', uniq, abs, cont) ->
        (* If the function is concretely typed, we add it to the function list and
           add the usercode name to the bound variables. In the polymorphic case,
           we add the function to the bound variables *)
        let name = (unique_name (name', uniq), true) in
        let typ, params = split_abs abs in
        let func = { name; params; typ; body = abs.body; mono = None } in

        let bound, monos, acc = param in
        (* We do not add functions passed as parameters. They will get their correct type at the outer
           function application *)
        let param =
          if is_type_generic typ then (
            Printf.printf "Polymoric function: %s\n%!"
              (unique_name (name', uniq));
            let bound = Vars.add name' (`Poly func) bound in
            (bound, monos, acc))
          else (
            Printf.printf "Normal function: %s\n%!" (unique_name (name', uniq));
            let bound = Vars.add name' (`Concrete func) bound in
            (bound, monos, func :: acc))
        in

        let param = inner param abs.body.expr in

        inner param cont.expr
    | Let (_, e1, e2) ->
        let param = inner param e1.expr in
        inner param e2.expr
    | Lambda (id, abs) ->
        let bound, monos, acc = inner param abs.body.expr in
        let name = (lambda_name id, false) in
        let typ, params = split_abs abs in
        ( bound,
          monos,
          { name; params; typ; body = abs.body; mono = None } :: acc )
    | App { callee; args } ->
        let bound, monos, acc = param in
        let acc, monos =
          if is_type_generic callee.typ then (acc, monos)
          else (
            Printf.printf "callee: %s\n" (show_typ (clean callee.typ));

            match find_function bound callee.expr with
            | `Concrete _ -> (* All good *) (acc, monos)
            | `Poly func ->
                let name = get_mono_name func.name ~poly:func.typ callee.typ in

                if Set.mem (fst name) monos then
                  (* The function exists, we don't do anything right now *)
                  (acc, monos)
                else
                  (* We generate the function *)
                  let () = Printf.printf "mono name: %s\n" (fst name) in

                  let subst, typ = subst_type ~poly:func.typ callee.typ in
                  ( {
                      name;
                      params = func.params;
                      typ;
                      body = func.body;
                      mono = Some { subst; func_uname = func.name |> fst };
                    }
                    :: acc,
                    Set.add (fst name) monos )
            | `None -> (acc, monos))
        in
        let param = inner (bound, monos, acc) callee.expr in
        List.fold_left
          (fun acc { Typing.arg; gen_fun = _ } -> inner acc Typing.(arg.expr))
          param args
    | Record labels ->
        List.fold_left
          (fun acc (_, e) -> inner acc Typing.(e.expr))
          param labels
    | Field (expr, _) -> inner param expr.expr
    | Sequence (expr, cont) ->
        let param = inner param expr.expr in
        inner param cont.expr
  and find_function vars = function
    | Typing.Var id -> (
        match Vars.find_opt id vars with
        | Some thing -> thing
        | None ->
            print_endline ("Probably a parameter: " ^ id);
            `None)
    | e -> "not supported: " ^ Typing.show_expr e |> failwith
  in

  let _, _, funs = inner (Vars.empty, Set.empty, []) expr in
  funs

let declare_function fun_name = function
  | Tfun (params, ret, kind) as typ ->
      let ft = typeof_func ~param:false ~decl:true (params, ret, kind) in
      let llvar =
        {
          value = Llvm.declare_function fun_name ft the_module;
          typ;
          lltyp = ft;
        }
      in
      llvar
  | _ ->
      prerr_endline fun_name;
      failwith "Internal Error: declaring non-function"

let gen_closure_obj assoc func vars name =
  let clsr_struct = Llvm.build_alloca closure_type name builder in

  (* Add function ptr *)
  let fun_ptr = Llvm.build_struct_gep clsr_struct 0 "funptr" builder in
  let fun_casted = Llvm.build_bitcast func.value voidptr_type "func" builder in
  ignore (Llvm.build_store fun_casted fun_ptr builder);

  let store_closed_var clsr_ptr i (name, _) =
    print_endline "before clsr";
    let var = Vars.find name vars in
    print_endline "after clsr";
    let ptr = Llvm.build_struct_gep clsr_ptr i name builder in
    ignore (Llvm.build_store var.value ptr builder);
    i + 1
  in

  (* Add closed over vars. If the environment is empty, we pass nullptr *)
  let clsr_ptr =
    match assoc with
    | [] -> Llvm.const_pointer_null voidptr_type
    | assoc ->
        let assoc_type = typeof_aggregate (Array.of_list assoc) in
        let clsr_ptr = Llvm.build_alloca assoc_type ("clsr_" ^ name) builder in
        ignore (List.fold_left (store_closed_var clsr_ptr) 0 assoc);

        let clsr_casted =
          Llvm.build_bitcast clsr_ptr voidptr_type "env" builder
        in
        clsr_casted
  in

  (* Add closure env to struct *)
  let env_ptr = Llvm.build_struct_gep clsr_struct 1 "envptr" builder in
  ignore (Llvm.build_store clsr_ptr env_ptr builder);

  { value = clsr_struct; typ = func.typ; lltyp = func.lltyp }

let add_closure vars func = function
  | Simple -> vars
  | Closure assoc ->
      let closure_index = (Llvm.params func.value |> Array.length) - 1 in
      let clsr_param = (Llvm.params func.value).(closure_index) in
      let clsr_type =
        typeof_aggregate (Array.of_list assoc) |> Llvm.pointer_type
      in
      let clsr_ptr = Llvm.build_bitcast clsr_param clsr_type "clsr" builder in

      let env, _ =
        List.fold_left
          (fun (env, i) (name, typ) ->
            let item_ptr = Llvm.build_struct_gep clsr_ptr i name builder in
            let value = Llvm.build_load item_ptr name builder in
            let item = { value; typ; lltyp = Llvm.type_of value } in
            (Vars.add name item env, i + 1))
          (vars, 0) assoc
      in
      env

(*
   More polymorphism util functions
*)

let is_polymorphic = function
  | Qvar _ | Tvar { contents = Unbound (_, _) } -> true
  | _ -> false

let pass_function vars llvar kind =
  match kind with
  | Simple ->
      (* If a function is passed into [func] we convert it to a closure
         and pass nullptr to env*)
      gen_closure_obj [] llvar vars "clstmp"
  | Closure _ ->
      (* This closure is a struct and has an env *)
      llvar

let func_to_closure vars llvar =
  match llvar.typ with
  | Tfun (_, _, kind) -> pass_function vars llvar kind
  | _ -> llvar

(* Make polymorphic argument ouf of [var] to be passed at its location.
   This does not create a poly_var! *)
let make_poly_arg_local var =
  let gen_ptr = generic_type |> Llvm.pointer_type in
  match var.typ with
  | Tint | Tbool ->
      let ptr = Llvm.build_alloca var.lltyp "gen" builder in
      ignore (Llvm.build_store var.value ptr builder);
      Llvm.build_bitcast ptr gen_ptr "" builder
  | Trecord _ | Tfun _ -> Llvm.build_bitcast var.value gen_ptr "" builder
  | _ ->
      failwith
        ("Internal Error: Cannot make poly var out of "
        ^ Typing.string_of_type var.typ)

let make_generic_record ~generic arg =
  let lltyp = get_lltype ~param:true generic in
  Llvm.build_bitcast arg.value lltyp "gencast" builder

let rec add_poly_args vars poly_args param arg =
  let mkvar_param name () =
    let name = poly_param_name name in
    match Vars.find_opt name vars with
    | Some v -> (v.value, Param)
    | None ->
        print_string "env: ";
        print_endline
          (String.concat ", "
             (List.map (fun a -> "'" ^ fst a ^ "'") (Vars.bindings vars)));
        Llvm.dump_module the_module;
        failwith
          (Printf.sprintf "Internal Error: poly var should be in env: %s" name)
  in
  let mkvar_generic_record name index labels () =
    (* TODO recurse correctly *)
    let arr =
      Llvm.(build_array_alloca num_type (const_int int_type 2) name) builder
    in
    let p0 = Llvm.build_gep arr [| Llvm.const_int int_type 0 |] "p0" builder in
    let rec_size = sizeof_typ vars arg |> llval_of_upto in
    ignore (Llvm.build_store rec_size p0 builder);
    let p1 = Llvm.build_gep arr [| Llvm.const_int int_type 1 |] "p1" builder in
    let inner_size = sizeof_typ vars (labels.(index) |> snd) |> llval_of_upto in
    ignore (Llvm.build_store inner_size p1 builder);
    (arr, Local arg)
  in

  match (param, arg) with
  | t, Tvar { contents = Link link } -> add_poly_args vars poly_args t link
  | Qvar id, Qvar _ | Qvar id, Tvar { contents = Unbound (_, _) } ->
      (* Param poly var *)
      (* let name = poly_name id in *)
      let name = id in
      PMap.add_single name (mkvar_param name) poly_args
  | Qvar id, t ->
      (* Local poly var *)
      (* let name = poly_name id in *)
      let name = id in
      let mkvar () =
        (* TODO Check if an arg with the same type exists and reuse the ptr.
           This should save a couple of redundant alloctations. *)
        (sizeof_typ vars t |> llval_of_upto |> poly_arg_of_size, Local t)
      in
      PMap.add_single name mkvar poly_args
  | Tfun (p1, r1, _), Tfun (p2, r2, _) ->
      let f = add_poly_args vars in
      let poly_args = List.fold_left2 f poly_args p1 p2 in
      add_poly_args vars poly_args r1 r2
  | Tvar _, _ -> failwith "Internal Error: How is this not generalized?"
  | Trecord (Some _, _, _), Trecord (Some i2, _, l2)
    when is_generic_record param ->
      let name = record_name ~poly:true param |> poly_param_name in
      (* We use the param to get the poly vars *)
      let ids = record_poly_ids param in
      if is_generic_record arg then
        (* We can add the generic_t from params *)
        PMap.add_container ids (mkvar_param name) poly_args
      else
        (* We construct a generic arg from concrete typ *)
        (* TODO recurse correctly here *)
        PMap.add_container ids (mkvar_generic_record name i2 l2) poly_args
  | _, _ -> poly_args

let handle_generic_arg vars poly_args param (arg, _) =
  (* Generic func is only needed in the case of both param ond arg not being
     fully polymorphic *)
  let poly_args = add_poly_args vars poly_args param arg.typ in
  match (param, arg.typ) with
  | Qvar _, arg' when is_polymorphic arg' ->
      (* We don't have to do anything else, as the poly var is already present *)
      (poly_args, arg.value)
  | Qvar _, _ ->
      (* The argument is generic and does not exist yet.
         We have to convert a local value to a generic one *)
      let value_to_pass = func_to_closure vars arg |> make_poly_arg_local in
      (poly_args, value_to_pass)
  | (Trecord _ as generic), Trecord _ when is_generic_record param ->
      if is_generic_record arg.typ then (* Nothing to do *)
        (poly_args, arg.value)
      else
        let arg = make_generic_record ~generic arg in
        (poly_args, arg)
  | _, _ ->
      (* No polymorphism involved *)
      let arg = func_to_closure vars arg in
      (poly_args, arg.value)

let handle_generic_ret vars poly_vars (funcval, args, envarg) ret concrete_ret =
  (* TODO verify args *)
  let poly_args = poly_vars |> PMap.to_args |> Seq.map fst in

  (* Mostly copied from the [gen_app] inline code before  *)
  match (ret, concrete_ret) with
  | Trecord _, Trecord _ ->
      let lltyp = get_lltype ~param:false concrete_ret in
      let retval = Llvm.build_alloca lltyp "ret" builder in
      let retval =
        if is_generic_record ret then
          let lltyp = get_lltype ~param:true ret in
          Llvm.build_bitcast retval lltyp "" builder
        else retval
      in
      let ret' = Seq.return retval in
      let args = ret' ++ args ++ poly_args ++ envarg |> Array.of_seq in
      ignore (Llvm.build_call funcval args "" builder);
      let retval =
        if is_generic_record ret then
          Llvm.build_bitcast retval (lltyp |> Llvm.pointer_type) "" builder
        else retval
      in

      (retval, concrete_ret, lltyp)
  | (Qvar id as t), _ ->
      (* Conceptually, this works like the record case.
          The only difference is that we need to get the size of variable
          from somewhere. We can look up the size in the type parameter *)
      (* This is a bit messy, can we clean this up somehow? *)
      let name = id in

      let poly_var = PMap.find_opt name poly_vars |> Option.get in
      (* If we are a local poly var, we don't use the poly var for the size
         b/c we can easily calculate it and thus save one (two) loads *)
      let poly_var, size =
        let extract_static t =
          match sizeof_typ vars t with
          | Static' _ as upto -> llval_of_upto upto
          | Dynamic' _ ->
              failwith "Internal Error: Assumption about locality does not hold"
        in
        match poly_var with
        | ( (lazy (_, Local (Trecord (Some i, _, labels)))),
            { PMap.name = _; lvl } )
          when lvl > 0 ->
            (* The type is not t, but the qvar inside the type. *)
            (* TODO how does this nest? Factor out *)
            let t = labels.(i) |> snd in
            (Local t, extract_static t)
        | (lazy (_, Local t)), _ -> (Local t, extract_static t)
        | (lazy (value, Param)), { name; lvl } ->
            (Param, get_poly_size name lvl value)
      in

      (* What about alignment? *)
      let ret = Llvm.build_array_alloca byte_type size "ret" builder in
      Llvm.set_alignment 16 ret;

      let gen_ptr_t = generic_type |> Llvm.pointer_type in
      let ret = Llvm.build_bitcast ret gen_ptr_t "ret" builder in

      let args =
        Seq.return ret ++ args ++ poly_args ++ envarg |> Array.of_seq
      in
      ignore (Llvm.build_call funcval args "" builder);

      (* If it's a local type, we reconstruct it *)
      let retval, typ =
        match poly_var with
        | Local (Tbool as t) | Local (Tint as t) ->
            let ptr_t = get_lltype ~param:false t |> Llvm.pointer_type in
            let cast = Llvm.build_bitcast ret ptr_t "" builder in
            (Llvm.build_load cast "realret" builder, t)
        | Local (Trecord _ as t) ->
            (Llvm.build_bitcast ret (get_lltype ~param:true t) "" builder, t)
        | _ -> (ret, t)
      in
      (retval, typ, gen_ptr_t)
  | t, _ ->
      let args = args ++ poly_args ++ envarg |> Array.of_seq in
      let retval = Llvm.build_call funcval args "" builder in
      (* TODO use concrete return type *)
      (retval, t, get_lltype t)

(* TODO put below gen_expr *)
let rec gen_function funcs ?(linkage = Llvm.Linkage.Private)
    { name = fun_name, named; params; typ; body; mono = _ } =
  match typ with
  | Tfun (tparams, ret_t, kind) as typ ->
      let func = declare_function fun_name typ in
      Llvm.set_linkage linkage func.value;

      let start_index = match ret_t with Trecord _ | Qvar _ -> 1 | _ -> 0 in

      let pvars = add_poly_vars PVars.empty typ in

      (* gen function body *)
      let bb = Llvm.append_block context "entry" func.value in
      Llvm.position_at_end bb builder;

      (* Add params from closure *)
      (* We generate both the code for extracting the closure and add the vars to the environment *)
      let temp_funcs = add_closure funcs func kind in

      let temp_funcs, pvar_index =
        List.fold_left2
          (fun (env, i) name typ ->
            let value = (Llvm.params func.value).(i) in
            let param =
              { value; typ = clean typ; lltyp = Llvm.type_of value }
            in
            Llvm.set_value_name name value;
            (Vars.add name param env, i + 1))
          (temp_funcs, start_index) params tparams
      in

      let temp_funcs, _ =
        PVars.fold
          (fun pvar locs (env, i) ->
            let var = (Llvm.params func.value).(i) in
            let pname = poly_param_name pvar in
            Llvm.set_value_name pname var;
            let env =
              List.fold_left
                (fun vars { PVars.name; lvl } ->
                  let value = get_poly_size name lvl var in
                  let param = { value; typ = Qvar name; lltyp = num_type } in
                  let name = poly_name name in
                  Vars.add name param vars)
                env locs
            in
            (* Also add the parameter value for passing to other functions *)
            let var =
              {
                value = var;
                typ = Qvar pname;
                lltyp = num_type |> Llvm.pointer_type;
              }
            in
            let env = Vars.add pname var env in

            (env, i + 1))
          pvars (temp_funcs, pvar_index)
      in

      (* If the function is named, we allow recursion *)
      let temp_funcs =
        if named then Vars.add fun_name func temp_funcs else temp_funcs
      in

      let ret = gen_expr temp_funcs body in

      (* If we want to return a struct, we copy the struct to
          its ptr (1st parameter) and return void *)
      (match ret_t with
      | Trecord _ ->
          (* TODO Use this return struct for creation in the first place *)
          (* Since we only have POD records, we can safely memcpy here *)
          let dst = Llvm.(params func.value).(0) in
          let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
          let retptr = Llvm.build_bitcast ret.value voidptr_type "" builder in
          let size = sizeof_typ temp_funcs ret.typ |> llval_of_upto in
          let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
          ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder);
          ignore (Llvm.build_ret_void builder)
      | Qvar id ->
          let dst = Llvm.(params func.value).(0) in
          let dstptr = Llvm.build_bitcast dst voidptr_type "" builder in
          let retptr = Llvm.build_bitcast ret.value voidptr_type "" builder in

          let size =
            match Vars.find_opt (poly_name id) temp_funcs with
            | Some v -> v.value
            | None ->
                failwith "TODO Internal Error: Unknown size of generic type"
          in
          let args = [| dstptr; retptr; size; Llvm.const_int bool_type 0 |] in
          ignore (Llvm.build_call (Lazy.force memcpy_decl) args "" builder);
          ignore (Llvm.build_ret_void builder)
      | _ ->
          (* TODO pattern match on unit *)
          (* Don't return void type *)
          ignore
            (match ret.typ with
            | Tunit ->
                (* If we are in main, we return 0. Bit of a hack, but whatever *)
                if String.equal fun_name "main" then
                  Llvm.(build_ret (const_int int_type 0)) builder
                else Llvm.build_ret_void builder
            | _ -> Llvm.build_ret ret.value builder));

      if Llvm_analysis.verify_function func.value |> not then (
        Llvm.dump_module the_module;
        (* To generate the report *)
        Llvm_analysis.assert_valid_function func.value);

      let _ = Llvm.PassManager.run_function func.value fpm in

      (* Printf.printf "Modified: %b\n" modified; *)
      Vars.add fun_name func funcs
  | _ ->
      prerr_endline fun_name;
      failwith "Interal Error: generating non-function"

and gen_expr vars typed_expr =
  match Typing.(typed_expr.expr) with
  | Typing.Const (Int i) ->
      { value = Llvm.const_int int_type i; typ = Tint; lltyp = int_type }
  | Const (Bool b) ->
      {
        value = Llvm.const_int bool_type (Bool.to_int b);
        typ = Tbool;
        lltyp = bool_type;
      }
  | Const Unit -> failwith "TODO"
  | Bop (bop, e1, e2) ->
      let e1 = gen_expr vars e1 in
      let e2 = gen_expr vars e2 in
      gen_bop e1 e2 bop
  | Var id -> (
      match Vars.find_opt id vars with
      | Some v -> v
      | None ->
          (* If the variable isn't bound, something went wrong before *)
          failwith ("Internal Error: Could not find " ^ id ^ " in codegen"))
  | Function (name, uniq, abs, cont) ->
      (* The functions are already generated *)
      let name = unique_name (name, uniq) in
      let func =
        match Vars.find_opt name vars with
        | Some func -> func
        | None ->
            (* The function is polymorphic and monomorphized versions are generated. *)
            (* TODO remove hack: If there is only one item, we replace it, otherwise fail *)
            let monos =
              match Strtbl.find_opt mono_tbl name with
              | Some m -> m
              | None -> "Could not find monos for: " ^ name |> failwith
            in
            let len = Vars.fold (fun _ _ i -> i + 1) monos 0 in
            if len = 1 then Vars.min_binding monos |> snd
            else "Could not find generated function: " ^ name |> failwith
      in

      let func =
        match abs.tp.kind with
        | Simple -> func
        | Closure assoc -> gen_closure_obj assoc func vars name
      in
      gen_expr (Vars.add name func vars) cont
  | Let (id, equals_ty, let_ty) ->
      let expr_val = gen_expr vars equals_ty in
      gen_expr (Vars.add id expr_val vars) let_ty
  | Lambda (id, abs) -> (
      let name = lambda_name id in
      let func = Vars.find name vars in
      match abs.tp.kind with
      | Simple -> func
      | Closure assoc -> gen_closure_obj assoc func vars name)
  | App { callee; args } -> gen_app vars callee args (clean typed_expr.typ)
  | If (cond, e1, e2) -> gen_if vars cond e1 e2
  | Record labels -> codegen_record vars (clean typed_expr.typ) labels
  | Field (expr, index) -> codegen_field vars expr index
  | Sequence (expr, cont) -> codegen_chain vars expr cont

and gen_bop e1 e2 bop =
  let bld f str = f e1.value e2.value str builder in
  let open Llvm in
  match bop with
  | Plus -> { value = bld build_add "addtmp"; typ = Tint; lltyp = int_type }
  | Mult -> { value = bld build_mul "multmp"; typ = Tint; lltyp = int_type }
  | Less ->
      let value = bld (build_icmp Icmp.Slt) "lesstmp" in
      { value; typ = Tbool; lltyp = bool_type }
  | Equal ->
      let value = bld (build_icmp Icmp.Eq) "eqtmp" in
      { value; typ = Tbool; lltyp = bool_type }
  | Minus -> { value = bld build_sub "subtmp"; typ = Tint; lltyp = int_type }

and gen_app vars callee args ret_t =
  let func = gen_expr vars callee in

  let params, ret, kind =
    match func.typ with
    | Tfun (params, ret, kind) -> (params, ret, kind)
    | _ -> failwith "Internal Error: Not a func in gen app"
  in

  let poly_args, args =
    List.fold_left_map
      (fun poly_vars (param, { Typing.arg; gen_fun }) ->
        (* let before_t = arg.typ in *)
        let typ = arg.typ in
        (* We have to preserve the concrete type. Otherwise we get the generalized one *)
        let arg = gen_expr vars arg in
        let arg = { arg with typ } in
        let argtup = (arg, gen_fun) in
        (* let after_t = (fst argtup).typ in *)
        (* Printf.printf "before: %s\nafter: %s\n%!" (show_typ before_t) (show_typ after_t); *)
        handle_generic_arg vars poly_vars param argtup)
      PMap.empty (List.combine params args)
  in
  let args = List.to_seq args in

  (* Add return poly var *)
  let poly_args = add_poly_args vars poly_args ret ret_t in

  (* No names here, might be void/unit *)
  let callee =
    if Llvm.type_of func.value = (closure_type |> Llvm.pointer_type) then
      (* Function to call is a closure (or a function passed into another one).
         We get the funptr from the first field, cast to the correct type,
         then get env ptr (as voidptr) from the second field and pass it as last argument *)
      let funcp = Llvm.build_struct_gep func.value 0 "funcptr" builder in
      let funcp = Llvm.build_load funcp "loadtmp" builder in
      let typ = get_lltype ~param:false func.typ |> Llvm.pointer_type in
      let funcp = Llvm.build_bitcast funcp typ "casttmp" builder in

      let env_ptr = Llvm.build_struct_gep func.value 1 "envptr" builder in
      let env_ptr = Llvm.build_load env_ptr "loadtmp" builder in
      (funcp, args, Seq.return env_ptr)
    else
      match kind with
      | Simple -> (func.value, args, Seq.empty)
      | Closure _ -> (
          (* In this case we are in a recursive closure function.
             We get the closure env and add it to the arguments we pass *)
          match Vars.find_opt (Llvm.value_name func.value) vars with
          | Some func ->
              (* We do this to make sure it's a recursive function.
                 If we cannot find something. there is an error somewhere *)
              let closure_index =
                (Llvm.params func.value |> Array.length) - 1
              in

              let env_ptr = (Llvm.params func.value).(closure_index) in
              (func.value, args, Seq.return env_ptr)
          | None ->
              failwith "Internal Error: Not a recursive closure application")
  in

  let value, _, lltyp = handle_generic_ret vars poly_args callee ret ret_t in

  { value; typ = ret_t; lltyp }

and gen_if vars cond e1 e2 =
  let cond = gen_expr vars cond in

  let start_bb = Llvm.insertion_block builder in
  let parent = Llvm.block_parent start_bb in
  let then_bb = Llvm.append_block context "then" parent in
  Llvm.position_at_end then_bb builder;
  let e1 = gen_expr vars e1 in
  (* Codegen can change the current bb *)
  let e1_bb = Llvm.insertion_block builder in

  let else_bb = Llvm.append_block context "else" parent in
  Llvm.position_at_end else_bb builder;
  let e2 = gen_expr vars e2 in

  let e2_bb = Llvm.insertion_block builder in
  let merge_bb = Llvm.append_block context "ifcont" parent in

  Llvm.position_at_end merge_bb builder;
  let phi =
    (* If the else evaluates to void, we don't do anything.
       Void will be added eventually *)
    match e1.typ with
    | Tunit -> e1.value
    | _ ->
        let incoming = [ (e1.value, e1_bb); (e2.value, e2_bb) ] in
        Llvm.build_phi incoming "iftmp" builder
  in
  Llvm.position_at_end start_bb builder;
  Llvm.build_cond_br cond.value then_bb else_bb builder |> ignore;

  Llvm.position_at_end e1_bb builder;
  ignore (Llvm.build_br merge_bb builder);
  Llvm.position_at_end e2_bb builder;
  ignore (Llvm.build_br merge_bb builder);

  Llvm.position_at_end merge_bb builder;
  { value = phi; typ = e1.typ; lltyp = e1.lltyp }

and codegen_record vars typ labels =
  print_endline (show_typ typ);
  Strtbl.iter (fun key _ -> Printf.printf "%s\n" key) record_tbl;
  let lltyp = get_lltype ~param:false typ in
  if is_generic_record typ then (
    let lbls =
      match typ with
      | Trecord (_, _, labels) -> labels
      | _ -> failwith "Not a record lol"
    in
    (* The size of the record has to come from the environment *)
    let pname = record_name ~poly:true typ |> poly_name in
    let size = (Vars.find pname vars).value in
    let record = Llvm.build_array_alloca byte_type size "record" builder in
    (* What about alignment? *)
    ignore
      (List.fold_left
         (fun (index, size) (_, expr) ->
           let typ = lbls.(index) |> snd in

           print_string "inn ";
           print_endline (show_typ typ);
           let upto = sizeof_typ vars typ in
           let upto, size = match_size ~upto size in
           let offset = alignup ~upto size in
           let ofs = llval_of_upto offset in
           let value = gen_expr vars expr in
           let dst = Llvm.build_in_bounds_gep record [| ofs |] "ptr" builder in
           (* copy *)
           ignore
             (match typ with
             | Trecord _ | Qvar _ ->
                 memcpy ~dst ~src:value ~size:(llval_of_upto upto)
             | _ ->
                 let ptr =
                   Llvm.build_bitcast dst
                     (value.lltyp |> Llvm.pointer_type)
                     "" builder
                 in
                 ignore (Llvm.build_store value.value ptr builder));

           (index + 1, add_uptos ~upto offset))
         (0, Static' 0) labels);
    let value =
      Llvm.build_bitcast record (lltyp |> Llvm.pointer_type) "record" builder
    in
    { value; typ; lltyp })
  else
    let record = Llvm.build_alloca lltyp "" builder in
    List.iteri
      (fun i (name, expr) ->
        let ptr = Llvm.build_struct_gep record i name builder in
        let value = gen_expr vars expr in
        set_record_field vars value ptr)
      labels;
    { value = record; typ; lltyp }

and codegen_field vars expr index =
  let value = gen_expr vars expr in

  let typ =
    match value.typ with
    | Trecord (_, _, fields) -> fields.(index) |> snd
    | _ -> failwith "Internal Error: No record in fields"
  in

  let ptr =
    if is_generic_record value.typ then
      (* We treat the whole structure as a byte array and then calculate the offset by hand *)
      (* TODO we can't yet know the generic size, so we just assume some bogus size for testing *)
      (* let size = Llvm.const_int num_type 200 in *)
      let byte_ptr = byte_type |> Llvm.pointer_type in
      let byte_array = Llvm.build_bitcast value.value byte_ptr "" builder in
      let offset =
        match value.typ with
        | Trecord (_, _, labels) -> offset_of vars ~labels index
        | _ -> failwith "Internal Error: No record for offset"
      in
      let gep_indices = [| offset |] in
      let ptr = Llvm.build_in_bounds_gep byte_array gep_indices "" builder in

      Llvm.build_bitcast ptr
        (get_lltype ~param:false typ |> Llvm.pointer_type)
        "" builder
      (* let byte_ptr = Llvm.build_bitcast value.value *)
      (* failwith "TODO generic indexing" *)
    else Llvm.build_struct_gep value.value index "" builder
  in

  (* In case we return a record, we don't load, but return the pointer.
     The idea is that this will be used either as a return value for a function (where it is copied),
     or for another field, where the pointer is needed.
     We should distinguish between structs and pointers somehow *)
  let value =
    match typ with
    | Trecord _ | Qvar _ -> ptr
    | _ -> Llvm.build_load ptr "" builder
  in
  { value; typ; lltyp = Llvm.type_of value }

and codegen_chain vars expr cont =
  ignore (gen_expr vars expr);
  gen_expr vars cont

let decl_external (name, typ) =
  match typ with
  | Tfun (ts, t, _) as typ ->
      let return_t = get_lltype t in
      let arg_t = List.map get_lltype ts |> Array.of_list in
      let ft = Llvm.function_type return_t arg_t in
      { value = Llvm.declare_function name ft the_module; typ; lltyp = ft }
  | _ -> failwith "TODO external symbols"

let generate { Typing.externals; records; tree } =
  let open Typing in
  (* External declarations *)
  let vars =
    List.fold_left
      (fun vars (name, typ) -> Vars.add name (decl_external (name, typ)) vars)
      Vars.empty externals
  in

  (* Add record types *)
  List.iter to_named_records records;

  (* Factor out functions for llvm *)
  let funcs =
    let lst = extract tree.expr in
    let vars =
      List.fold_left
        (fun acc func ->
          let name = func.name |> fst in
          let fnc = declare_function name func.typ in

          (* Add to the monomorphization table for func's parent *)
          (match func.mono with
          | Some { subst = _; func_uname } -> (
              match Strtbl.find_opt mono_tbl func_uname with
              | Some map ->
                  Strtbl.replace mono_tbl func_uname (Vars.add name fnc map)
              | None ->
                  Strtbl.add mono_tbl func_uname (Vars.add name fnc Vars.empty))
          | None -> ());

          (* Add to the normal variable environment *)
          Vars.add name (declare_function name func.typ) acc)
        vars lst
    in

    (* Generate functions *)
    List.fold_left (fun acc func -> gen_function acc func) vars lst
  in

  (* Add main *)
  let linkage = Llvm.Linkage.External in
  ignore
  @@ gen_function funcs ~linkage
       {
         name = ("main", false);
         params = [ "" ];
         typ = Tfun ([ Tint ], Tint, Simple);
         body = { tree with typ = Tint };
         mono = None;
       };

  (match Llvm_analysis.verify_module the_module with
  | Some output -> print_endline output
  | None -> ());

  (* Emit code to file *)
  Llvm_all_backends.initialize ();
  let open Llvm_target in
  let triple = Target.default_triple () in
  let reloc_mode = RelocMode.PIC in
  print_endline triple;
  let machine =
    TargetMachine.create ~triple (Target.by_triple triple) ~reloc_mode
  in
  TargetMachine.emit_to_file the_module CodeGenFileType.ObjectFile "out.o"
    machine
