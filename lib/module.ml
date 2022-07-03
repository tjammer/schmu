open Types
module Sexp = Csexp.Make (Sexplib0.Sexp)

type item = Mfun of typ * string (* TODO lets and exprs *)

(* TODO we need a name for types, or support aliases *)
type t = { types : typ list; items : item list }

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

open Sexplib0.Sexp
open Sexplib0.Sexp_conv

let item_to_sexp item =
  match item with
  | Mfun (typ, name) -> List [ Atom "Mfun"; to_sexp typ; sexp_of_string name ]

let item_of_sexp s =
  match s with
  | List [ Atom "Mfun"; typ; name ] -> Mfun (of_sexp typ, string_of_sexp name)
  | s -> of_sexp_error "item_of_sexp" s

let t_to_sexp { types; items } =
  List [ sexp_of_list to_sexp types; sexp_of_list item_to_sexp items ]

let t_of_sexp s =
  match s with
  | List [ types; items ] ->
      let types = list_of_sexp of_sexp types in
      let items = list_of_sexp item_of_sexp items in
      { types; items }
  | s -> of_sexp_error "module_of_sexp" s

let of_typed_tree Typed_tree.{ typedefs; items; _ } =
  let is_polymorphic_func (f : Typed_tree.func) =
    is_polymorphic (Tfun (f.tparams, f.ret, f.kind))
  in

  let items =
    List.map
      (function
        | Typed_tree.Tl_let _ ->
            failwith "Lets in modules are not supported yet TODO"
        | Tl_expr _ -> failwith "exprs in modules are not supported yet TODO"
        | Tl_function (_, _, abs) when is_polymorphic_func abs.tp ->
            print_endline
              (show_typ (Tfun (abs.tp.tparams, abs.tp.ret, abs.tp.kind)));
            failwith
              "polymorphic functions in modules are not supported yet TODO"
        | Tl_function (name, uniq, abs) ->
            Mfun
              ( Tfun (abs.tp.tparams, abs.tp.ret, abs.tp.kind),
                unique_name (name, uniq) ))
      items
  in
  { types = typedefs; items }

let read_module ~regeneralize name =
  let c = open_in (String.lowercase_ascii (name ^ ".smi")) in
  let r =
    Result.map
      (fun m ->
        let m = t_of_sexp m in
        let types = List.map regeneralize m.types in
        let items =
          List.map (function Mfun (t, n) -> Mfun (regeneralize t, n)) m.items
        in
        { types; items })
      (Sexp.input c)
  in
  close_in c;
  r
