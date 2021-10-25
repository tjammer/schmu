open Alcotest
open Schmulang

let get_type src =
  let open Lexing in
  let lexbuf = from_string src in
  Parser.prog Lexer.read lexbuf |> Typing.typecheck |> Typing.string_of_type

let test a src = (check string) "" a (get_type src)

let test_exn msg src =
  (check string) "" msg (try get_type src with Typing.Error (_, msg) -> msg)

let test_exn_unify src =
  check_raises "" Typing.Unify (fun () -> ignore @@ get_type src)

let test_const_int () = test "int" "a = 1 a"

let test_const_bool () = test "bool" "a = true a"

let test_hint_int () = test "int" "a : int = 1 a"

let test_func_id () = test "a -> a" "function (a) a"

let test_func_id_hint () = test "int -> int" "function (a : int) a"

let test_func_int () = test "int -> int" "function (a) a + 1"

let test_func_bool () = test "bool -> int" "function (a) if a then 1 else 1"

let test_func_external () =
  test "int -> unit" "external func : int -> unit func"

let test_func_1st_class () =
  test "(int -> b) -> int -> b" "function (func, arg : int) func(arg)"

let test_func_1st_hint () =
  test "(int -> unit) -> int -> unit" "function (f : int -> unit, arg) f(arg)"

let test_func_recursive_if () =
  test "int -> unit"
    "external ext : unit -> unit function foo(i) if i < 2 then ext() else \
     foo(i-1) foo"

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

let test_record_wrong_type () = test_exn_unify "type t = {x : int} {x = true}"

let test_record_wrong_choose () =
  test_exn_unify
    "type t1 = {x : int, y : int} type t2 = {x : int, z : int} {x = 2, y = \
     true}"

let test_record_field_simple () =
  test "int" "type t = {x : int} a = {x = 10} a.x"

let test_record_field_infer () =
  test "t -> int" "type t = {x : int} function (a) a.x"

let test_record_field_no_record () =
  test_exn_unify "type t = {x : int} a = 10 a.x"

let test_record_field_wrong_record () =
  test_exn_unify
    "type t1 = {x : int} type t2 = {y:int} function foo(a) a.x b = {y = 10} \
     foo(b)"

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
          case "1st-class" test_func_1st_class;
          case "1st-hint" test_func_1st_hint;
          case "recursive_if" test_func_recursive_if;
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
    ]
