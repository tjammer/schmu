open Types
module Sexp = Csexp.Make (Sexplib0.Sexp)
open Sexplib0.Sexp_conv

type t = item list [@@deriving sexp]

and item =
  | Mtype of typ
  | Mfun of typ * string
  | Mext_fun of typ * string * string option

(* Functions must be unique, so we add a number to each function if
   it already exists in the global scope.
   In local scope, our Map.t will resolve to the correct function.
   E.g. 'foo' will be 'foo' in global scope, but 'foo__<n>' in local scope
   if the global function exists. *)

(* For named functions *)
let unique_name name = function
  | None -> name
  | Some n -> name ^ "__" ^ string_of_int n

let lambda_name id = "__fun" ^ string_of_int id

let is_polymorphic_func (f : Typed_tree.func) =
  is_polymorphic (Tfun (f.tparams, f.ret, f.kind))

let add_type t m = Mtype t :: m

let add_fun name uniq (func : Typed_tree.func) m =
  if is_polymorphic_func func then
    (* failwith "polymorphic functions in modules are not supported yet TODO" *)
    m
  else
    Mfun (Tfun (func.tparams, func.ret, func.kind), unique_name name uniq) :: m

let add_external t name cname m = Mext_fun (t, name, cname) :: m

let read_module ~regeneralize name =
  let c = open_in (String.lowercase_ascii (name ^ ".smi")) in
  let r =
    Result.map t_of_sexp (Sexp.input c)
    |> Result.map
         (List.map (function
           | Mtype t -> Mtype (regeneralize t)
           | Mfun (t, n) -> Mfun (regeneralize t, n)
           | Mext_fun (t, n, cn) -> Mext_fun (regeneralize t, n, cn)))
  in
  close_in c;
  r

let add_to_env env m =
  let dummy_loc = Lexing.(dummy_pos, dummy_pos) in
  List.fold_left
    (fun env item ->
      match item with
      | Mtype (Trecord (param, name, labels)) ->
          Env.add_record name ~param ~labels env
      | Mtype (Tvariant (param, name, ctors)) ->
          Env.add_variant name ~param ~ctors env
      | Mtype (Talias (name, _) as t) -> Env.add_alias name t env
      | Mtype t ->
          failwith ("Internal Error: Unexpected type in module: " ^ show_typ t)
      | Mfun (t, n) ->
          Env.add_external ~imported:true n
            ~cname:(Some ("schmu_" ^ n))
            t dummy_loc env
      | Mext_fun (t, n, cname) ->
          Env.add_external ~imported:true n ~cname t dummy_loc env)
    env m
