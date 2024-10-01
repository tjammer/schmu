open Types
module Sexp = Csexp.Make (Sexplib0.Sexp)
open Sexplib0.Sexp_conv

type loc = Typed_tree.loc [@@deriving sexp, show]

type name = { user : string; call : callname option }
and callname = string * Path.t option * int option

and item =
  | Mtype of loc * string * type_decl
  | Mfun of loc * typ * name
  | Mext of loc * typ * name * bool (* is closure *)
  | Mpoly_fun of loc * Typed_tree.abstraction * string * int option
  | Mmutual_rec of loc * (loc * string * int option * typ) list
  | Malias of loc * string * Typed_tree.typed_expr
  | Mlocal_module of loc * string * t
  | Mfunctor of
      loc * string * (string * intf) list * Typed_tree.toplevel_item list * t
  | Mapplied_functor of loc * string * Path.t * t
    (* Special treatment as the name is a path, not a string.
       Theoretically, this could be merged with local_module if we convert the name
       in the correct places *)
  | Mmodule_alias of loc * string * Path.t * string option (* filename option *)
  | Mmodule_type of loc * string * intf

and sg_kind = Module_type.item_kind =
  | Mtypedef of type_decl
  | Mvalue of typ * callname option

and sig_item = string * loc * sg_kind [@@deriving sexp, show]
and intf = sig_item list
and impl = item list

and t = {
  s : intf;
  i : impl;
  objects : (string * bool (* transitive dep needs load *)) list;
}

let t_of_sexp s =
  triple_of_sexp
    (list_of_sexp sig_item_of_sexp)
    (list_of_sexp item_of_sexp)
    (list_of_sexp (pair_of_sexp string_of_sexp bool_of_sexp))
    s
  |> fun (s, i, objects) -> { s; i; objects }

let sexp_of_t m =
  sexp_of_triple
    (sexp_of_list sexp_of_sig_item)
    (sexp_of_list sexp_of_item)
    (sexp_of_list (sexp_of_pair sexp_of_string sexp_of_bool))
    (m.s, m.i, m.objects)

let absolute_module_name ~mname fname = "_" ^ Path.mod_name mname ^ "_" ^ fname

let unique_name ~mname name uniq =
  match uniq with
  | None -> Path.mod_name mname ^ "_" ^ name
  | Some n -> Path.mod_name mname ^ "_" ^ name ^ "__" ^ string_of_int n

let callname call =
  Option.map
    (fun (name, mname, uniq) ->
      match mname with
      | Some mname -> unique_name ~mname name uniq
      | None ->
          assert (Option.is_none uniq);
          name)
    call

let is_polymorphic_func (f : Typed_tree.func) =
  is_polymorphic (Tfun (f.tparams, f.ret, f.kind))

let type_of_func (func : Typed_tree.func) =
  Tfun (func.tparams, func.ret, func.kind)

let make_fun loc ~mname name uniq (abs : Typed_tree.abstraction) =
  if is_polymorphic_func abs.func then Mpoly_fun (loc, abs, name, uniq)
  else
    let name = { user = name; call = Some (name, Some mname, uniq) } in
    Mfun (loc, type_of_func abs.func, name)
