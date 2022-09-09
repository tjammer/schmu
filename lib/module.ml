open Types
module Sexp = Csexp.Make (Sexplib0.Sexp)
open Sexplib0.Sexp_conv

type t = item list [@@deriving sexp]

and item =
  | Mtype of typ
  | Mfun of typ * string
  | Mext of typ * string * string option
  | Mpoly_fun of Typed_tree.abstraction * string

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

let type_of_func (func : Typed_tree.func) =
  Tfun (func.tparams, func.ret, func.kind)

let add_fun name uniq (abs : Typed_tree.abstraction) m =
  if is_polymorphic_func abs.func then
    (* failwith "polymorphic functions in modules are not supported yet TODO" *)
    Mpoly_fun (abs, unique_name name uniq) :: m
  else Mfun (type_of_func abs.func, unique_name name uniq) :: m

let add_external t name cname m = Mext (t, name, cname) :: m
let module_cache = Hashtbl.create 64

(* Right now we only ever compile one module, so this can safely be global *)
let poly_funcs = ref []
let paths = ref [ "." ]

(* We cache the prelude path for later *)
let prelude_path = ref None

let find_file name =
  let name = String.lowercase_ascii (name ^ ".smi") in
  let ( // ) = Filename.concat in
  let rec path = function
    | p :: tl ->
        let file = p // name in
        if Sys.file_exists file then file else path tl
    | [] -> raise Not_found
  in
  let file = path !paths in
  if String.starts_with ~prefix:"prelude" name then prelude_path := Some file;
  file

let read_module ~regeneralize name =
  match Hashtbl.find_opt module_cache name with
  | Some r -> r
  | None -> (
      try
        let c = open_in (find_file name) in
        let r =
          Result.map t_of_sexp (Sexp.input c)
          |> Result.map
               (List.map (function
                 | Mtype t -> Mtype (regeneralize t)
                 | Mfun (t, n) -> Mfun (regeneralize t, n)
                 | Mext (t, n, cn) -> Mext (regeneralize t, n, cn)
                 | Mpoly_fun (abs, n) ->
                     (* We ought to regeneralize here. Not only the type, but
                        the body as well? *)
                     poly_funcs :=
                       Typed_tree.Tl_function (n, None, abs) :: !poly_funcs;
                     (* This will be ignored in [add_to_env] *)
                     Mpoly_fun (abs, n)))
        in
        close_in c;
        Hashtbl.add module_cache name r;
        r
      with Not_found -> Error ("Could not open file: " ^ name))

let read_exn ~regeneralize name loc =
  match read_module ~regeneralize name with
  | Ok modul -> modul
  | Error s ->
      let msg = Printf.sprintf "Module %s: %s" name s in
      raise (Typed_tree.Error (loc, msg))

let add_to_env env m =
  let dummy_loc = Lexing.(dummy_pos, dummy_pos) in
  List.fold_left
    (fun env item ->
      match item with
      | Mtype (Trecord (params, Some name, labels)) ->
          Env.add_record name ~params ~labels env
      | Mtype (Tvariant (params, name, ctors)) ->
          Env.add_variant name ~params ~ctors env
      | Mtype (Talias (name, t)) -> Env.add_alias name t env
      | Mtype t ->
          failwith ("Internal Error: Unexpected type in module: " ^ show_typ t)
      | Mfun (t, n) ->
          Env.add_external ~imported:(Some `Schmu) n
            ~cname:(Some ("schmu_" ^ n))
            t dummy_loc env
      | Mpoly_fun (abs, n) ->
          let env =
            Env.(
              add_value n
                { def_value with typ = type_of_func abs.func; imported = true }
                dummy_loc env)
          in
          env
      | Mext (t, n, cname) ->
          Env.add_external ~imported:(Some `C) n ~cname t dummy_loc env)
    env m
