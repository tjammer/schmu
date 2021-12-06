open Alcotest
open Schmulang

let get_type src =
  let open Lexing in
  let lexbuf = from_string src in
  Parser.prog Lexer.read lexbuf |> Typing.typecheck |> Typing.string_of_type

let test a src = (check string) "" a (get_type src)

let test_exn msg src =
  (check string) "" msg (try get_type src with Typing.Error (_, msg) -> msg)

let test_const_int () = test "int" "a = 1 a"

let test_const_bool () = test "bool" "a = true a"

let test_hint_int () = test "int" "a : int = 1 a"

let test_func_id () = test "'a -> 'a" "function (a) a"

let test_func_id_hint () = test "int -> int" "function (a : int) a"

let test_func_int () = test "int -> int" "function (a) a + 1"

let test_func_bool () = test "bool -> int" "function (a) if a then 1 else 1"

let test_func_external () =
  test "int -> unit" "external func : int -> unit func"

let test_func_1st_class () =
  test "(int -> 'a) -> int -> 'a" "function (func, arg : int) func(arg)"

let test_func_1st_hint () =
  test "(int -> unit) -> int -> unit" "function (f : int -> unit, arg) f(arg)"

let test_func_1st_stay_general () =
  test "'a -> ('a -> 'b) -> 'b"
    "function foo(x, f) f(x) function add1(x) x + 1 a = foo(1, add1) function \
     boolean(x : bool) x b = foo(true, boolean) foo"

let test_func_recursive_if () =
  test "int -> unit"
    "external ext : unit -> unit function foo(i) if i < 2 then ext() else \
     foo(i-1) foo"

let test_func_generic_return () =
  test "int" "function apply(f, x) f(x) function add1(x) x + 1 apply(add1, 1)"

let test_record_clear () =
  test "t" "type t = { x : int, y : int } { x = 2, y = 2 }"

let test_record_false () =
  test_exn "Unbound record field z"
    "type t = { x : int, y : int } { x = 2, z = 2 }"

let test_record_choose () =
  test "t1"
    "type t1 = {x : int, y : int} type t2 = {x : int, z : int} {x = 2, y = 2}"

let test_record_reorder () =
  test "t" "type t = {x : int, y : int} { y = 10, x = 2 }"

let test_record_create_if () =
  test "t" "type t = {x : int} { x = if true then 1 else 0 }"

let test_record_create_return () =
  test "t" "type t = {x : int} function a () 10 { x = a() }"

let test_record_wrong_type () =
  test_exn " Expected type int but got type bool"
    "type t = {x : int} {x = true}"

let test_record_wrong_choose () =
  test_exn " Expected type int but got type bool"
    "type t1 = {x : int, y : int} type t2 = {x : int, z : int} {x = 2, y = \
     true}"

let test_record_field_simple () =
  test "int" "type t = {x : int} a = {x = 10} a.x"

let test_record_field_infer () =
  test "t -> int" "type t = {x : int} function (a) a.x"

let test_record_field_no_record () =
  test_exn "Field access of record t: Expected type t but got type int"
    "type t = {x : int} a = 10 a.x"

let test_record_field_wrong_record () =
  test_exn " Expected type t1 -> int but got type t2 -> 'a"
    "type t1 = {x : int} type t2 = {y:int} function foo(a) a.x b = {y = 10} \
     foo(b)"

let dummy_info = (Lexing.dummy_pos, "")

let get_type src =
  let open Lexing in
  let lexbuf = from_string src in
  Parser.prog Lexer.read lexbuf |> Typing.typecheck |> Typing.string_of_type

let test a src = (check string) "" a (get_type src)

let test_exn msg src =
  (check string) "" msg (try get_type src with Typing.Error (_, msg) -> msg)

let test_unify msg t1 t2 =
  (check string) "" msg
    (try
       let () = Typing.unify dummy_info t1 t2 in
       ""
     with Typing.Error (_, msg) -> msg)

let test_unify_trivial () =
  test_unify " Expected type int but got type bool" TInt TBool

let test_unify_poly_fun_match () =
  test_unify ""
    (TFun ([ QVar "a" ], TBool, Simple))
    (TFun ([ QVar "a" ], TBool, Simple))

let test_unify_poly_fun_fail_not () =
  test_unify " Expected type 'a -> bool but got type 'b -> bool"
    (TFun ([ QVar "a" ], TBool, Simple))
    (TFun ([ QVar "b" ], TBool, Simple))

let test_unify_poly_fun_unify () =
  test_unify ""
    (TFun ([ TVar (ref (Types.Unbound ("a", 1))) ], TBool, Simple))
    (TFun ([ QVar "b" ], TBool, Simple))

let test_unify_poly_fun_unify2 () =
  test_unify ""
    (TFun ([ TVar (ref (Types.Unbound ("1", 1))) ], TBool, Simple))
    (TFun ([ TInt ], TBool, Simple))

let test_unify_poly_fun_fail () =
  test_unify " Expected type 'a -> 'b -> 'a but got type 'a -> 'b -> 'c"
    (Types.TFun
       ([ QVar "a"; QVar "b" ], TVar (ref (Types.Link (QVar "a"))), Simple)
    |> Typing.canonize)
    (Types.TFun ([ QVar "e"; QVar "f" ], QVar "a", Simple) |> Typing.canonize)

let case str test = test_case str `Quick test

(* Run it *)
let () =
  run "Typing"
    [
      ("consts", [ case "int" test_const_int; case "bool" test_const_bool ]);
      ("hints", [ case "int" test_hint_int ]);
      ( "funcs",
        [
          case "id" test_func_id;
          case "id_hint" test_func_id_hint;
          case "int" test_func_int;
          case "bool" test_func_bool;
          case "ext" test_func_external;
          case "1st_class" test_func_1st_class;
          case "1st_hint" test_func_1st_hint;
          case "1st_stay_gen" test_func_1st_stay_general;
          case "recursive_if" test_func_recursive_if;
          case "generic_return" test_func_generic_return;
        ] );
      ( "records",
        [
          case "clear" test_record_clear;
          case "false" test_record_false;
          case "choose" test_record_choose;
          case "reorder" test_record_reorder;
          case "create_if" test_record_create_if;
          case "create_return" test_record_create_return;
          case "wrong_type" test_record_wrong_type;
          case "wrong_choose" test_record_wrong_choose;
          case "field_simple" test_record_field_simple;
          case "field_infer" test_record_field_infer;
          case "field_no_record" test_record_field_no_record;
          case "field_wrong_record" test_record_field_wrong_record;
        ] );
      ( "unification",
        [
          case "trivial" test_unify_trivial;
          case "poly_fun_match" test_unify_poly_fun_match;
          (* case "poly_fun_fail" test_unify_poly_fun_fail_not; *)
          case "poly_fun_unify" test_unify_poly_fun_unify;
          case "poly_fun_unify2" test_unify_poly_fun_unify2;
          case "poly_fun_unify_fail" test_unify_poly_fun_fail;
        ] );
    ]
