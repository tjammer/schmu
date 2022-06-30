open Types

type item = Mfun of typ * string * int option (* TODO lets and exprs *)
type t = { types : typ list; items : item list }

let item_to_sexp item =
  let open Sexplib0.Sexp in
  let open Sexplib0.Sexp_conv in
  match item with
  | Mfun (typ, name, uniq) ->
      List
        [
          Atom "Mfun";
          to_sexp typ;
          sexp_of_string name;
          sexp_of_option sexp_of_int uniq;
        ]

let item_of_sexp s =
  let open Sexplib0.Sexp in
  let open Sexplib0.Sexp_conv in
  match s with
  | List [ Atom "Mfun"; typ; name; uniq ] ->
      Mfun (of_sexp typ, string_of_sexp name, option_of_sexp int_of_sexp uniq)
  | s -> of_sexp_error "item_of_sexp" s

let t_to_sexp { types; items } =
  let open Sexplib0.Sexp in
  let open Sexplib0.Sexp_conv in
  List [ sexp_of_list to_sexp types; sexp_of_list item_to_sexp items ]

let t_of_sexp s =
  let open Sexplib0.Sexp in
  let open Sexplib0.Sexp_conv in
  match s with
  | List [ types; items ] ->
      let types = list_of_sexp of_sexp types in
      let items = list_of_sexp item_of_sexp items in
      { types; items }
  | s -> of_sexp_error "module_of_sexp" s

let of_codegen_tree Typing.{ typedefs; items; _ } =
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
            failwith
              "polymorphic functions in modules are not supported yet TODO"
        | Tl_function (name, uniq, abs) ->
            Mfun (Tfun (abs.tp.tparams, abs.tp.ret, abs.tp.kind), name, uniq))
      items
  in
  { types = typedefs; items }

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
