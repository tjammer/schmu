open Alcotest
open Schmulang

let get_type src =
  let open Lexing in
  let lexbuf = from_string src in
  Parser.prog Lexer.read lexbuf |> Typing.typecheck |> Types.string_of_type

let test a src = (check string) "" a (get_type src)

let test_exn msg src =
  (check string) "" msg
    (try get_type src with Typed_tree.Error (_, msg) -> msg)

let test_const_int () = test "int" "(val a 1) a"
let test_const_neg_int () = test "int" "(val a -1) a"

let test_const_neg_int_wrong () =
  test_exn "Unary -: Expected types int or float but got type bool"
    "(val a -true) a"

let test_const_neg_int2 () = test "int" "(val a - 1) a"
let test_const_float () = test "float" "(val a 1.0) a"
let test_const_neg_float () = test "float" "(val a -1.0) a"

let test_const_neg_float_wrong () =
  test_exn "Unary -.: Expected type float but got type bool" "(val a -.true) a"

let test_const_neg_float2 () = test "float" "(val a -.1.0) a"
let test_const_bool () = test "bool" "(val a true) a"
let test_const_u8 () = test "u8" "(val a 123u8) a"
let test_const_i32 () = test "i32" "(val a 123i32) a"
let test_const_neg_i32 () = test "i32" "(val a -123i32) a"
let test_const_f32 () = test "f32" "(val a 1.0f32) a"
let test_const_neg_f32 () = test "f32" "(val a -1.0f32) a"
let test_hint_int () = test "int" "(val (a int) 1) a"
let test_func_id () = test "'a -> 'a" "(fun (a) a)"
let test_func_id_hint () = test "int -> int" "(fun ((a int)) a)"
let test_func_int () = test "int -> int" "(fun (a) (+ a 1))"
let test_func_bool () = test "bool -> int" "(fun (a) (if a 1  1))"

let test_func_external () =
  test "int -> unit" "(external func (fun int unit)) func"

let test_func_1st_class () =
  test "(int -> 'a, int) -> 'a" "(fun (func (arg int)) (func arg))"

let test_func_1st_hint () =
  test "(int -> unit, int) -> unit" "(fun [(f (fun int unit)) arg] (f arg))"

let test_func_1st_stay_general () =
  test "('a, 'a -> 'b) -> 'b"
    "(fun foo [x f] (f x)) (fun add1 [x] (+ x 1)) (val a (foo 1 add1)) (fun \
     boolean [(x bool)] x) (val b (foo true boolean)) foo"

let test_func_recursive_if () =
  test "int -> unit"
    "(external ext (fun unit unit)) (fun foo [i] (if (< i 2) (ext)  (foo (- i \
     1)))) foo"

let test_func_generic_return () =
  test "int" "(fun apply [f x] (f x)) (fun add1 [x] (+ x 1)) (apply add1 1)"

let test_record_clear () = test "t" "(record t { :x int :y int }) { :x 2 :y 2 }"

let test_record_false () =
  test_exn "Unbound field z on record t"
    "(record t { :x int :y int }) { :x 2 :z 2 }"

let test_record_choose () =
  test "t1"
    "(record t1 {:x int :y int}) (record t2 {:x int :z int}) {:x 2 :y 2}"

let test_record_reorder () =
  test "t" "(record t {:x int :y int}) { :y 10 :x 2 }"

let test_record_create_if () =
  test "t" "(record t {:x int}) { :x (if true 1 0) }"

let test_record_create_return () =
  test "t" "(record t {:x int}) (fun a [] 10) { :x (a) }"

let test_record_wrong_type () =
  test_exn "In record expression: Expected type int but got type bool"
    "(record t {:x int}) {:x true}"

let test_record_wrong_choose () =
  test_exn "In record expression: Expected type int but got type bool"
    "(record t1 {:x int :y int}) (record t2 {:x int :z int}) {:x 2 :y true}"

let test_record_field_simple () =
  test "int" "(record t {:x int}) (val a {:x 10}) (.x a)"

let test_record_field_infer () =
  test "t -> int" "(record t {:x int}) (fun (a) (.x a))"

let test_record_same_field_infer () =
  test "a" "(record a { :x int }) (record b { :x int :y int }) { :x 12 }"

let test_record_nested_field_infer () =
  test "c"
    "(record a { :x int }) (record b { :x int }) (record c { :x int :y a }) { \
     :x 12 :y { :x 12 } }"

let test_record_nested_field_generic () =
  test "c(b)"
    "(record a { :x int }) (record b { :x int }) (record (c 'a) { :x int :y 'a \
     }) { :x 12 :y { :x 12 } }"

let test_record_field_no_record () =
  test_exn "Field access of record t: Expected type t but got type int"
    "(record t {:x int}) (val a 10) (.x a)"

let test_record_field_wrong_record () =
  test_exn "Application: Expected type t1 -> int but got type t2 -> 'a"
    "(record t1 {:x int}) (record t2 {:y int}) (fun foo (a) (.x a)) (val b {:y \
     10}) (foo b)"

let test_annot_concrete () = test "int -> bool" "(fun foo (x) (< x 3)) foo"

let test_annot_concrete_fail () =
  test_exn "Var annotation: Expected type bool -> int but got type int -> bool"
    "(val (foo (fun bool int)) (fun (x) (< x 3))) foo"

let test_annot_mix () = test "'a -> 'a" "(fun pass [(x 'b)] x) pass"

let test_annot_mix_fail () =
  test_exn "Var annotation: Expected type 'b -> int but got type 'b -> 'b"
    "(val (pass (fun 'b int)) (fun (x) x)) pass"

let test_annot_generic () = test "'a -> 'a" "(fun pass [(x 'b)] x) pass"

let test_annot_generic_fail () =
  test_exn "Var annotation: Expected type 'a -> 'b but got type 'a -> 'a"
    "(val (pass (fun 'a 'b)) (fun (x) x)) pass"

let test_annot_record_simple () =
  test "a" "(record a { :x int }) (record b { :x int }) (val (a a) { :x 12 }) a"

let test_annot_record_generic () =
  test "a(bool)"
    "(record (a 'a) { :x 'a }) (record b { :x int }) (val (a (a bool)) { :x \
     true }) a"

let test_sequence () =
  test "int" "(external printi (fun int unit)) (printi 20) (+ 1 1)"

let test_sequence_fail () =
  test_exn
    "Left expression in sequence must be of type unit: Expected type unit but \
     got type int"
    "(fun add1 (x) (+ x 1)) (add1 20) (+ 1 1)"

let test_para_instantiate () =
  test "foo(int)"
    "(record (foo 'a) { :first int :gen 'a }) (val foo { :first 10 :gen 20 }) \
     foo"

let test_para_gen_fun () =
  test "foo('a) -> int"
    "(record (foo 'a) { :gen 'a :second int }) (fun get (foo) (.second foo)) \
     get"

let test_para_gen_return () =
  test "foo('a) -> 'a"
    "(record (foo 'a) { :gen 'a }) (fun get (foo) (.gen foo)) get"

let test_para_multiple () =
  test "bool"
    "(record (foo 'a) { :gen 'a }) (fun get (foo) (.gen foo)) (val a { :gen 12 \
     }) (val (b int) (get a)) (val c { :gen false }) (get c)"

let test_para_instance_func () =
  test "foo(int) -> int"
    "(record (foo 'a) { :gen 'a }) (fun use (foo) (+ (.gen foo) 17)) (val foo \
     { :gen 17 }) use"

let test_para_instance_wrong_func () =
  test_exn
    "Application: Expected type foo(int) -> int but got type foo(bool) -> 'a"
    "(record (foo 'a) { :gen 'a }) (fun use (foo) (+ (.gen foo) 17)) (val foo \
     { :gen 17 }) (use { :gen true } )"

let test_pipe_head_single () = test "int" "(fun add1 (a) (+ a 1)) (-> 10 add1)"

let test_pipe_head_single_call () =
  test "int" "(fun add1 (a) (+ a 1)) (-> 10  (add1))"

let test_pipe_head_multi_call () =
  test "int" "(fun add1(a) (+ a 1)) (-> 10 add1 add1)"

let test_pipe_head_single_wrong_type () =
  test_exn "Application: Expected type int -> 'a but got type int"
    "(val add1 1) (-> 10 add1)"

let test_pipe_head_mult () =
  test "int" "(fun add (a b) (+ a b)) (-> 10 (add 12))"

let test_pipe_head_mult_wrong_type () =
  test_exn "Application: Wrong arity for function: Expected 1 but got 2"
    "(fun add1(a) (+ a 1)) (-> 10 (add1 12))"

let test_pipe_tail_single () = test "int" "(fun add1(a) (+ a 1)) (->> 10 add1)"

let test_pipe_tail_single_call () =
  test "int" "(fun add1(a) (+ a 1)) (->> 10 (add1))"

let test_pipe_tail_single_wrong_type () =
  test_exn "Application: Expected type int -> 'a but got type int"
    "(val add1 1) (->> 10 add1)"

let test_pipe_tail_mult () =
  test "int" "(fun add (a b) (+ a b)) (->> 10 (add 12))"

let test_pipe_tail_mult_wrong_type () =
  test_exn "Application: Wrong arity for function: Expected 1 but got 2"
    "(fun add1(a) (+ a 1)) (->> 10 (add1 12))"

let test_alias_simple () =
  test "foo = int -> unit" "(alias foo int) (external f (fun foo unit)) f"

let test_alias_param_concrete () =
  test "foo = raw_ptr(u8) -> unit"
    "(alias foo (raw_ptr u8)) (external f (fun foo unit)) f"

let test_alias_param_quant () =
  test "foo = raw_ptr('a) -> unit"
    "(alias (foo 'a) (raw_ptr 'a)) (external f (fun (foo 'a) unit)) f"

let test_alias_param_missing () =
  test_exn "Type foo needs a type parameter"
    "(alias (foo 'a) (raw_ptr 'a)) (external f (fun foo unit)) f"

let test_alias_of_alias () =
  test "bar = int -> foo = int"
    "(alias foo int) (alias bar foo) (external f (fun bar foo)) f"

let test_vector_lit () =
  test "vector(int)"
    {|(record (vector 'a) { :data (raw_ptr 'a) :length int })
    [0 1]|}

let test_vector_var () =
  test "vector(int)"
    {|(record (vector 'a) { :data (raw_ptr 'a) :length int })
    (val a [0 1])
    a|}

let test_vector_weak () =
  test "vector(int)"
    {|(record (vector 'a) { :data (raw_ptr 'a) :length int })
    (external set (fun (vector 'a) 'a unit))
    (val a [])
    (set a  2)
    a|}

let test_vector_different_types () =
  test_exn "In vector literal: Expected type int but got type bool"
    {|(record (vector 'a) { :data (raw_ptr 'a) :length int })
    [0 true]|}

let test_vector_different_annot () =
  test_exn "Var annotation: Expected type vector(bool) but got type vector(int)"
    {|(record (vector 'a) { :data (raw_ptr 'a) :length int })
    (val (a (vector bool)) [0 1])
    a|}

let test_vector_different_annot_weak () =
  test_exn
    "Application: Expected type (vector(bool), bool) -> unit but got type \
     (vector(bool), int) -> 'a"
    {|(record (vector 'a) { :data (raw_ptr 'a) :length int })
    (external set (fun (vector 'a) 'a unit))
    (val (a (vector bool)) [])
    (set a 2)|}

let test_vector_different_weak () =
  test_exn
    "Application: Expected type (vector(int), int) -> unit but got type \
     (vector(int), bool) -> 'a"
    {|(record (vector 'a) { :data (raw_ptr 'a) :length int })
    (external set (fun (vector 'a) 'a unit))
    (val a [])
    (set a 2)
    (set a true)|}

let test_mutable_declare () = test "int" "(record foo { :x (mutable int) }) 0"

let test_mutable_set () =
  test "unit"
    "(record foo { :x (mutable int) }) (val foo { :x 12 }) (setf foo .x 13)"

let test_mutable_set_wrong_type () =
  test_exn "Mutate field x: Expected type int but got type bool"
    "(record foo { :x (mutable int) }) (val foo { :x 12 }) (setf foo .x true)"

let test_mutable_set_non_mut () =
  test_exn "Cannot mutate non-mutable field x"
    "(record foo { :x int }) (val foo { :x 12}) (setf foo .x 13)"

let test_variants_option_none () =
  test "option('a)" "(variant (option 'a) (#none (#some 'a))) #none"

let test_variants_option_some () =
  test "option(int)" "(variant (option 'a) (#none (#some 'a))) (#some 1)"

let test_variants_option_some_some () =
  test "option(option(float))"
    "(variant (option 'a) (#none (#some 'a))) (val a (#some 1.0)) (#some a)"

let test_variants_option_annot () =
  test "option(option(float))"
    "(variant (option 'a) (#none (#some 'a))) (val (a (option float)) #none) \
     (#some a)"

let test_variants_option_none_arg () =
  test_exn
    "The constructor none expects 0 arguments, but an argument is provided"
    "(variant (option 'a) (#none (#some 'a))) (#none 1)"

let test_variants_option_some_arg () =
  test_exn "The constructor some expects arguments, but none are provided"
    "(variant (option 'a) (#none (#some 'a))) #some"

let test_match_all () =
  test "int"
    "(variant (option 'a) (#none (#some 'a))) (match (#some 1) (#some a) a  \
     #none -1)"

let test_match_redundant () =
  test_exn "Pattern match case is redundant"
    "(variant (option 'a) (#none (#some 'a))) (match (#some 1) a a #none -1)"

let test_match_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: some"
    "(variant (option 'a) (#none (#some 'a))) (match (#some 1) #none -1)"

let test_match_missing_nested () =
  test_exn
    "Pattern match is not exhaustive. Missing cases: some(int) | some(non)"
    {|(variant (option 'a) (#none (#some 'a)))
    (variant test ((#float float) (#int int) #non))
    (match #none
      (#some (#float f)) (-> f int_of_float)
      -- (#some (#int i)) i
      -- (#some #non) 1
      #none 0)
|}

let test_match_all_after_ctor () =
  test "int"
    {|(variant (option 'a) (#none (#some 'a)))
(match (#some 1)
    #none -1
    a 0)
|}

let test_match_all_before_ctor () =
  test_exn "Pattern match case is redundant"
    {|(variant (option 'a) (#none (#some 'a)))
    (match (#some 1)
      a 0
      #none -1)
|}

let test_match_redundant_all_cases () =
  test_exn "Pattern match case is redundant"
    {|(variant (option 'a) (#none (#some 'a)))
    (variant test ((#float float) (#int int) #non))
    (match #none
      (#some (#float f)) (-> f int_of_float)
      (#some (#int i)) i
      (#some #non) 1
      #none 0
      a -1)
|}

let test_match_wildcard () =
  test_exn "Pattern match case is redundant"
    {|(variant (option 'a) (#none (#some 'a)))
    (match (#some 1)
      _ 0
      #none -1)
|}

let test_match_wildcard_nested () =
  test_exn "Pattern match case is redundant"
    {|(variant (option 'a) (#none (#some 'a)))
    (variant test ((#float float) (#int int) #non))
    (match #none
      (#some (#float f)) (-> f int_of_float)
      (#some _) -2
      (#some #non) 1
      #none 0)
|}

let test_match_column_arity () =
  test_exn "Expected 2 patterns, but found 1"
    {|(variant (option 'a) (#none (#some 'a)))
    (match '(1 2)
      a a)
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
