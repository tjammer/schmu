open Alcotest
open Schmulang

let get_type src =
  let open Lexing in
  let lexbuf = from_string src in
  Parser.prog Indent.insert_ends lexbuf
  |> Typing.typecheck |> Types.string_of_type

let test a src = (check string) "" a (get_type src)

let test_exn msg src =
  (check string) "" msg
    (try get_type src with Typed_tree.Error (_, msg) -> msg)

let test_const_int () = test "int" "a = 1 a"
let test_const_neg_int () = test "int" "a = -1 a"

let test_const_neg_int_wrong () =
  test_exn "Unary -: Expected types int or float but got type bool"
    "a = -true a"

let test_const_neg_int2 () = test "int" "a = - 1 a"
let test_const_float () = test "float" "a = 1.0 a"
let test_const_neg_float () = test "float" "a = -1.0 a"

let test_const_neg_float_wrong () =
  test_exn "Unary -.: Expected type float but got type bool" "a = -.true a"

let test_const_neg_float2 () = test "float" "a = -.1.0 a"
let test_const_bool () = test "bool" "a = true a"
let test_const_u8 () = test "u8" "a = 123u8 a"
let test_const_i32 () = test "i32" "a = 123i32 a"
let test_const_neg_i32 () = test "i32" "a = -123i32 a"
let test_const_f32 () = test "f32" "a = 1.0f32 a"
let test_const_neg_f32 () = test "f32" "a = -1.0f32 a"
let test_hint_int () = test "int" "a : int = 1 a"
let test_func_id () = test "'a -> 'a" "fun(a) -> a"
let test_func_id_hint () = test "int -> int" "fun(a : int) -> a"
let test_func_int () = test "int -> int" "fun(a) -> a + 1"
let test_func_bool () = test "bool -> int" "fun(a) -> if a then 1 else 1"

let test_func_external () =
  test "int -> unit" "external func : int -> unit func"

let test_func_1st_class () =
  test "(int -> 'a, int) -> 'a" "fun(func, arg : int) -> func(arg)"

let test_func_1st_hint () =
  test "(int -> unit, int) -> unit" "fun(f : int -> unit, arg) -> f(arg)"

let test_func_1st_stay_general () =
  test "('a, 'a -> 'b) -> 'b"
    "fun foo(x, f) = f(x) fun add1(x) = x + 1 a = foo(1, add1) fun boolean(x : \
     bool) = x b = foo(true, boolean) foo"

let test_func_recursive_if () =
  test "int -> unit"
    "external ext : unit -> unit fun foo(i) = if i < 2 then ext() else \
     foo(i-1) foo"

let test_func_generic_return () =
  test "int" "fun apply(f, x) = f(x) fun add1(x) = x + 1 apply(add1, 1)"

let test_record_clear () =
  test "t" "type t = { x : int, y : int } { x = 2, y = 2 }"

let test_record_false () =
  test_exn "Unbound field z on record t"
    "type t = { x : int, y : int } { x = 2, z = 2 }"

let test_record_choose () =
  test "t1"
    "type t1 = {x : int, y : int} type t2 = {x : int, z : int} {x = 2, y = 2}"

let test_record_reorder () =
  test "t" "type t = {x : int, y : int} { y = 10, x = 2 }"

let test_record_create_if () =
  test "t" "type t = {x : int} { x = if true then 1 else 0 }"

let test_record_create_return () =
  test "t" "type t = {x : int} fun a() =  10 { x = a() }"

let test_record_wrong_type () =
  test_exn "In record expression: Expected type int but got type bool"
    "type t = {x : int} {x = true}"

let test_record_wrong_choose () =
  test_exn "In record expression: Expected type int but got type bool"
    "type t1 = {x : int, y : int} type t2 = {x : int, z : int} {x = 2, y = \
     true}"

let test_record_field_simple () =
  test "int" "type t = {x : int} a = {x = 10} a.x"

let test_record_field_infer () =
  test "t -> int" "type t = {x : int} fun(a) -> a.x"

let test_record_same_field_infer () =
  test "a" "type a = { x : int } type b = { x : int, y : int } { x = 12 }"

let test_record_nested_field_infer () =
  test "c"
    "type a = { x : int } type b = { x : int } type c = { x : int, y : a } { x \
     = 12, y = { x = 12 } }"

let test_record_nested_field_generic () =
  test "c(b)"
    "type a = { x : int } type b = { x : int } type c('a) = { x : int, y : 'a \
     } { x = 12, y = { x = 12 } }"

let test_record_field_no_record () =
  test_exn "Field access of record t: Expected type t but got type int"
    "type t = {x : int} a = 10 a.x"

let test_record_field_wrong_record () =
  test_exn "Application: Expected type t1 -> int but got type t2 -> 'a"
    "type t1 = {x : int} type t2 = {y:int} fun foo(a) = a.x b = {y = 10} foo(b)"

let test_annot_concrete () = test "int -> bool" "fun foo(x) -> bool = x < 3 foo"

let test_annot_concrete_fail () =
  test_exn "Var annotation: Expected type bool -> int but got type int -> bool"
    "foo : bool -> int = fun(x) -> x < 3 foo"

let test_annot_mix () = test "'a -> 'a" "fun pass(x : 'b) -> 'b = x pass"

let test_annot_mix_fail () =
  test_exn "Var annotation: Expected type 'b -> int but got type 'b -> 'b"
    "pass : 'b -> int = fun(x) -> x pass"

let test_annot_generic () = test "'a -> 'a" "fun pass(x : 'b) -> 'b = x pass"

let test_annot_generic_fail () =
  test_exn "Var annotation: Expected type 'a -> 'b but got type 'a -> 'a"
    "pass : 'a -> 'b = fun(x) -> x pass"

let test_annot_record_simple () =
  test "a" "type a = { x : int } type b = { x : int } a : a = { x = 12 } a"

let test_annot_record_generic () =
  test "a(bool)"
    "type a('a) = { x : 'a } type b = { x : int } a : a(bool) = { x = true } a"

let test_sequence () =
  test "int" "external printi : int -> unit printi(20) 1 + 1"

let test_sequence_fail () =
  test_exn
    "Left expression in sequence must be of type unit: Expected type unit but \
     got type int"
    "fun add1(x) = x + 1 add1(20) 1 + 1"

let test_para_instantiate () =
  test "foo(int)"
    "type foo('a) = { first : int, gen : 'a } foo = { first = 10, gen = 20 } \
     foo"

let test_para_gen_fun () =
  test "foo('a) -> int"
    "type foo('a) = { gen : 'a, second : int } fun get(foo) = foo.second get"

let test_para_gen_return () =
  test "foo('a) -> 'a" "type foo('a) = { gen : 'a } fun get(foo) = foo.gen get"

let test_para_multiple () =
  test "bool"
    "type foo('a) = { gen : 'a } fun get(foo) = foo.gen a = { gen = 12 } b : \
     int = get(a) c = { gen = false } get(c)"

let test_para_instance_func () =
  test "foo(int) -> int"
    "type foo('a) = { gen : 'a } fun use(foo) = foo.gen + 17 foo = { gen = 17 \
     } use"

let test_para_instance_wrong_func () =
  test_exn
    "Application: Expected type foo(int) -> int but got type foo(bool) -> 'a"
    "type foo('a) = { gen : 'a } fun use(foo) = foo.gen + 17 foo = { gen = 17 \
     } use( { gen = true } )"

let test_pipe_head_single () = test "int" "fun add1(a) = a + 1 10|.add1"
let test_pipe_head_single_call () = test "int" "fun add1(a) = a + 1 10|.add1()"

let test_pipe_head_multi_call () =
  test "int" "fun add1(a) = a + 1 10 |. add1 |. add1"

let test_pipe_head_single_wrong_type () =
  test_exn "Application: Expected type int -> 'a but got type int"
    "add1 = 1 10|.add1"

let test_pipe_head_mult () = test "int" "fun add(a, b) = a + b 10|.add(12)"

let test_pipe_head_mult_wrong_type () =
  test_exn "Application: Wrong arity for function: Expected 1 but got 2"
    "fun add1(a) = a + 1 10|.add1(12)"

let test_pipe_tail_single () = test "int" "fun add1(a) = a + 1 10|>add1"
let test_pipe_tail_single_call () = test "int" "fun add1(a) = a + 1 10|>add1()"

let test_pipe_tail_single_wrong_type () =
  test_exn "Application: Expected type int -> 'a but got type int"
    "add1 = 1 10|>add1"

let test_pipe_tail_mult () = test "int" "fun add(a, b) = a + b 10|>add(12)"

let test_pipe_tail_mult_wrong_type () =
  test_exn "Application: Wrong arity for function: Expected 1 but got 2"
    "fun add1(a) = a + 1 10|>add1(12)"

let test_alias_simple () =
  test "foo = int -> unit" "type foo = int external f : foo -> unit f"

let test_alias_param_concrete () =
  test "foo = ptr(u8) -> unit" "type foo = ptr(u8) external f : foo -> unit f"

let test_alias_param_quant () =
  test "foo = ptr('a) -> unit"
    "type foo('a) = ptr('a) external f : foo('a) -> unit f"

let test_alias_param_missing () =
  test_exn "Type foo needs a type parameter"
    "type foo('a) = ptr('a) external f : foo -> unit f"

let test_alias_of_alias () =
  test "bar = int -> foo = int"
    "type foo = int type bar = foo external f : bar -> foo f"

let test_vector_lit () =
  test "vector(int)"
    {|type vector('a) = { data : ptr('a), length : int }
    [0,1]|}

let test_vector_var () =
  test "vector(int)"
    {|type vector('a) = { data : ptr('a), length : int }
    a = [0,1]
    a|}

let test_vector_weak () =
  test "vector(int)"
    {|type vector('a) = { data : ptr('a), length : int }
    external set : (vector('a), 'a) -> unit
    a = []
    set(a, 2)
    a|}

let test_vector_different_types () =
  test_exn "In vector literal: Expected type int but got type bool"
    {|type vector('a) = { data : ptr('a), length : int }
    [0,true]|}

let test_vector_different_annot () =
  test_exn "Var annotation: Expected type vector(bool) but got type vector(int)"
    {|type vector('a) = { data : ptr('a), length : int }
    a : vector(bool) = [0,1]
    a|}

let test_vector_different_annot_weak () =
  test_exn
    "Application: Expected type (vector(bool), bool) -> unit but got type \
     (vector(bool), int) -> 'a"
    {|type vector('a) = { data : ptr('a), length : int }
    external set : (vector('a), 'a) -> unit
    a : vector(bool) = []
    set(a, 2)|}

let test_vector_different_weak () =
  test_exn
    "Application: Expected type (vector(int), int) -> unit but got type \
     (vector(int), bool) -> 'a"
    {|type vector('a) = { data : ptr('a), length : int }
    external set : (vector('a), 'a) -> unit
    a =[]
    set(a, 2)
    set(a, true)|}

let test_mutable_declare () = test "int" "type foo = { mutable x : int } 0"

let test_mutable_set () =
  test "unit" "type foo = { mutable x : int } foo = { x = 12 } foo.x <- 13"

let test_mutable_set_wrong_type () =
  test_exn "Mutate field x: Expected type int but got type bool"
    "type foo = { mutable x : int } foo = { x = 12 } foo.x <- true"

let test_mutable_set_non_mut () =
  test_exn "Cannot mutate non-mutable field x"
    "type foo = { x : int } foo = { x = 12} foo.x <- 13"

let test_variants_option_none () =
  test "option('a)" "type option('a) = None | Some('a) None"

let test_variants_option_some () =
  test "option(int)" "type option('a) = None | Some('a) Some(1)"

let test_variants_option_some_some () =
  test "option(option(float))"
    "type option('a) = None | Some('a) a = Some(1.0) Some(a)"

let test_variants_option_annot () =
  test "option(option(float))"
    "type option('a) = None | Some('a) a : option(float) = None Some(a)"

let test_variants_option_none_arg () =
  test_exn
    "The constructor None expects 0 arguments, but an argument is provided"
    "type option('a) = None | Some('a) None(1)"

let test_variants_option_some_arg () =
  test_exn "The constructor Some expects arguments, but none are provided"
    "type option('a) = None | Some('a) Some"

let test_match_all () =
  test "int"
    "type option('a) = Some('a) | None match Some(1) with\n\
    \  Some(a) -> a\n\
    \  None -> -1\n"

let test_match_redundant () =
  test_exn "Pattern match case is redundant"
    "type option('a) = Some('a) | None match Some(1) with\n\
    \  a -> a\n\
    \  None -> -1\n"

let test_match_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: Some"
    "type option('a) = Some('a) | None match Some(1) with\n  None -> -1\n"

let test_match_missing_nested () =
  test_exn
    "Pattern match is not exhaustive. Missing cases: Some(Int) | Some(Non)"
    {|
type option('a) = Some('a) | None
type test = Float(float) | Int(int) | Non

match None with
  Some(Float(f)) -> f |. int_of_float
  -- Some(Int(i)) -> i
  -- Some(Non) -> 1
  None -> 0
|}

let test_match_all_after_ctor () =
  test "int"
    {|
type option('a) = Some('a) | None
match Some(1) with
  None -> -1
  a -> 0
|}

let test_match_all_before_ctor () =
  test_exn "Pattern match case is redundant"
    {|
type option('a) = Some('a) | None
match Some(1) with
  a -> 0
  None -> -1
|}

let test_match_redundant_all_cases () =
  test_exn "Pattern match case is redundant"
    {|
type option('a) = Some('a) | None
type test = Float(float) | Int(int) | Non

match None with
  Some(Float(f)) -> f |. int_of_float
  Some(Int(i)) -> i
  Some(Non) -> 1
  None -> 0
  a -> -1
|}

let test_match_wildcard () =
  test_exn "Pattern match case is redundant"
    {|type option('a) = Some('a) | None
match Some(1) with
  _ -> 0
  None -> -1
|}

let test_match_wildcard_nested () =
  test_exn "Pattern match case is redundant"
    {|
type option('a) = Some('a) | None
type test = Float(float) | Int(int) | Non

match None with
  Some(Float(f)) -> f |. int_of_float
  Some(_) -> -2
  Some(Non) -> 1
  None -> 0
|}

let test_match_column_arity () =
  test_exn "Expected 2 patterns, but found 1"
    {|
type option('a) = Some('a) | None
match 1, 2 with
  a -> a
|}

let case str test = test_case str `Quick test

(* Run it *)
let () =
  run "Typing"
    [
      ( "consts",
        [
          case "int" test_const_int;
          case "neg_int" test_const_neg_int;
          case "neg_int2" test_const_neg_int2;
          case "neg_int_wrong" test_const_neg_int_wrong;
          case "float" test_const_float;
          case "-float" test_const_neg_float;
          case "-.float" test_const_neg_float2;
          case "-.float_wrong" test_const_neg_float_wrong;
          case "bool" test_const_bool;
          case "u8" test_const_u8;
          case "i32" test_const_i32;
          case "-i32" test_const_neg_i32;
          case "f32" test_const_f32;
          case "-f32" test_const_neg_f32;
        ] );
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
          case "same_field_infer" test_record_same_field_infer;
          case "nested_field_infer" test_record_nested_field_infer;
          case "nested_field_infer_generic" test_record_nested_field_generic;
          case "field_no_record" test_record_field_no_record;
          case "field_wrong_record" test_record_field_wrong_record;
        ] );
      ( "annotations",
        [
          case "concrete" test_annot_concrete;
          case "concrete_fail" test_annot_concrete_fail;
          case "mix" test_annot_mix;
          case "mix_fail" test_annot_mix_fail;
          case "generic" test_annot_generic;
          case "generic_fail" test_annot_generic_fail;
          case "record_let" test_annot_record_simple;
          case "record_let_gen" test_annot_record_generic;
        ] );
      ( "function sequencing",
        [
          case "sequence" test_sequence; case "sequence_fail" test_sequence_fail;
        ] );
      ( "parametric record",
        [
          case "instantiate" test_para_instantiate;
          case "gen_fun" test_para_gen_fun;
          case "gen_return" test_para_gen_return;
          case "multiple" test_para_multiple;
          case "instance_func" test_para_instance_func;
          case "instance_wrong_func" test_para_instance_wrong_func;
        ] );
      ( "piping",
        [
          case "head_single" test_pipe_head_single;
          case "head_single_call" test_pipe_head_single_call;
          case "head_multi_call" test_pipe_head_multi_call;
          case "head_single_wrong_type" test_pipe_head_single_wrong_type;
          case "head_mult" test_pipe_head_mult;
          case "head_mult_wrong_type" test_pipe_head_mult_wrong_type;
          case "tail_single" test_pipe_tail_single;
          case "tail_single_call" test_pipe_tail_single_call;
          case "tail_single_wrong_type" test_pipe_tail_single_wrong_type;
          case "tail_mult" test_pipe_tail_mult;
          case "tail_mult_wrong_type" test_pipe_tail_mult_wrong_type;
        ] );
      ( "aliasing",
        [
          case "simple" test_alias_simple;
          case "param_concrete" test_alias_param_concrete;
          case "param_quant" test_alias_param_quant;
          case "param_missing" test_alias_param_missing;
          case "of_alias" test_alias_of_alias;
        ] );
      ( "vector",
        [
          case "literal" test_vector_lit;
          case "var" test_vector_var;
          case "weak" test_vector_weak;
          case "different_types" test_vector_different_types;
          case "different_annot" test_vector_different_annot;
          case "different_annot_weak" test_vector_different_annot_weak;
          case "different_weak" test_vector_different_weak;
        ] );
      ( "mutable",
        [
          case "declare" test_mutable_declare;
          case "set" test_mutable_set;
          case "set_wrong_type" test_mutable_set_wrong_type;
          case "set_non_mut" test_mutable_set_non_mut;
        ] );
      ( "variants",
        [
          case "option_none" test_variants_option_none;
          case "option_some" test_variants_option_some;
          case "option_some_some" test_variants_option_some_some;
          case "option_annot" test_variants_option_annot;
          case "option_none_arg" test_variants_option_none_arg;
          case "option_some_arg" test_variants_option_some_arg;
        ] );
      ( "match",
        [
          case "all" test_match_all;
          case "redundant" test_match_redundant;
          case "missing" test_match_missing;
          case "missing nested" test_match_missing_nested;
          case "all_after_ctor" test_match_all_after_ctor;
          case "all_before_ctor" test_match_all_before_ctor;
          case "redundant_all_cases" test_match_redundant_all_cases;
          case "wildcard" test_match_wildcard;
          case "wildcard_nested" test_match_wildcard_nested;
          case "column arity" test_match_column_arity;
        ] );
    ]
