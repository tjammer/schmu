open Alcotest
open Schmulang

let get_type src =
  let open Lexing in
  let lexbuf = from_string src in
  Parser.prog Lexer.read lexbuf |> Typing.typecheck |> Typing.string_of_type

let test a src = (check string) "" a (get_type src)

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

let case str test = test_case str `Quick test

(* Run it *)
let () =
  run "Utils"
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
        ] );
    ]
