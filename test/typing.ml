open Alcotest
open Schmulang

let get_type src =
  let open Lexing in
  let lexbuf = from_string src in
  Parser.prog Lexer.read lexbuf |> Typing.typecheck |> Types.string_of_type

let test a src = (check string) "" a (get_type src)

let test_exn msg src =
  (check string) "" msg
    (try
       ignore (get_type src);
       failwith "Expected an exception"
     with Typed_tree.Error (_, msg) -> msg)

let tase descr msg src = test_case descr `Quick (fun () -> test msg src)
let tase_exn descr msg src = test_case descr `Quick (fun () -> test_exn msg src)

let wrap_fn ?(proj = false) t expect code =
  (* toplevel *)
  if not proj then t expect code
  else test_exn "Cannot use projection at top level" code;
  (* function *)
  t expect ("(defn f [] " ^ code ^ ")")

let test_const_int () = test "int" "(def a 1) a"
let test_const_neg_int () = test "int" "(def a -1) a"

let test_const_neg_int_wrong () =
  test_exn "Unary -: Expected types int or float but got type bool"
    "(def a -true) a"

let test_const_neg_int2 () = test "int" "(def a - 1) a"
let test_const_float () = test "float" "(def a 1.0) a"
let test_const_neg_float () = test "float" "(def a -1.0) a"

let test_const_neg_float_wrong () =
  test_exn "Unary -.: Expected type float but got type bool" "(def a -.true) a"

let test_const_neg_float2 () = test "float" "(def a -.1.0) a"
let test_const_bool () = test "bool" "(def a true) a"
let test_const_u8 () = test "u8" "(def a 123u8) a"
let test_const_i32 () = test "i32" "(def a 123i32) a"
let test_const_neg_i32 () = test "i32" "(def a -123i32) a"
let test_const_f32 () = test "f32" "(def a 1.0f32) a"
let test_const_neg_f32 () = test "f32" "(def a -1.0f32) a"
let test_hint_int () = test "int" "(def (a int) 1) a"
let test_func_id () = test "(fun 'a 'a)" "(fn (a) a)"
let test_func_id_hint () = test "(fun int int)" "(fn ((a int)) a)"
let test_func_int () = test "(fun int int)" "(fn (a) (+ a 1))"
let test_func_bool () = test "(fun bool int)" "(fn (a) (if a 1  1))"

let test_func_external () =
  test "(fun int unit)" "(external func (fun int unit)) func"

let test_func_1st_class () =
  test "(fun (fun int 'a) int 'a)" "(fn (func (arg int)) (func arg))"

let test_func_1st_hint () =
  test "(fun (fun int unit) int unit)" "(fn [(f (fun int unit)) arg] (f arg))"

let test_func_1st_stay_general () =
  test "(fun 'a (fun 'a 'b) 'b)"
    "(defn foo [x f] (f x)) (defn add1 [x] (+ x 1)) (def a (foo 1 add1)) (defn \
     boolean [(x bool)] x) (def b (foo true boolean)) foo"

let test_func_recursive_if () =
  test "(fun int unit)"
    "(external ext (fun unit unit)) (defn foo [i] (if (< i 2) (ext)  (foo (- i \
     1)))) foo"

let test_func_generic_return () =
  test "int" "(defn apply [f x] (f x)) (defn add1 [x] (+ x 1)) (apply add1 1)"

let test_record_clear () = test "t" "(type t { :x int :y int }) { :x 2 :y 2 }"

let test_record_false () =
  test_exn "Unbound field :z on record t"
    "(type t { :x int :y int }) { :x 2 :z 2 }"

let test_record_choose () =
  test "t1" "(type t1 {:x int :y int}) (type t2 {:x int :z int}) {:x 2 :y 2}"

let test_record_reorder () = test "t" "(type t {:x int :y int}) { :y 10 :x 2 }"
let test_record_create_if () = test "t" "(type t {:x int}) { :x (if true 1 0) }"

let test_record_create_return () =
  test "t" "(type t {:x int}) (defn a [] 10) { :x (a) }"

let test_record_wrong_type () =
  test_exn "In record expression: Expected type int but got type bool"
    "(type t {:x int}) {:x true}"

let test_record_wrong_choose () =
  test_exn "In record expression: Expected type int but got type bool"
    "(type t1 {:x int :y int}) (type t2 {:x int :z int}) {:x 2 :y true}"

let test_record_field_simple () =
  test "int" "(type t {:x int}) (def a {:x 10}) (.x a)"

let test_record_field_infer () =
  test "(fun t int)" "(type t {:x int}) (fn (a) (.x a))"

let test_record_same_field_infer () =
  test "a" "(type a { :x int }) (type b { :x int :y int }) { :x 12 }"

let test_record_nested_field_infer () =
  test "c"
    "(type a { :x int }) (type b { :x int }) (type c { :x int :y a }) { :x 12 \
     :y { :x 12 } }"

let test_record_nested_field_generic () =
  test "(c b)"
    "(type a { :x int }) (type b { :x int }) (type (c 'a) { :x int :y 'a }) { \
     :x 12 :y { :x 12 } }"

let test_record_field_no_record () =
  test_exn "Field access of record t: Expected type t but got type int"
    "(type t {:x int}) (def a 10) (.x a)"

let test_record_field_wrong_record () =
  test_exn "Application: Expected type (fun t1 int) but got type (fun t2 'a)"
    "(type t1 {:x int}) (type t2 {:y int}) (defn foo (a) (.x a)) (def b {:y \
     10}) (foo b)"

let test_record_update () =
  test "a" "(type a {:x int :y int}) (def a {:x 10 :y 20}) {@a :y 30}"

let test_record_update_poly_same () =
  test "(a int)" "(type (a 'a) {:x 'a :y int}) (def a {:x 10 :y 20}) {@a :x 20}"

let test_record_update_poly_change () =
  test "(a float)"
    "(type (a 'a) {:x 'a :y int}) (def a {:x 10 :y 20}) {@a :x 20.0}"

let test_record_update_useless () =
  test_exn "All fields are explicitely updated. Record update is useless"
    "(type a {:x int :y int}) (def a {:x 10 :y 20}) {@a :y 30 :x 10}"

let test_record_update_expr () =
  test "a" "(type a {:x int :y int}) {@{:x 10 :y 20} :y 30}"

let test_record_update_wrong_field () =
  test_exn "Unbound field :z on a"
    "(type (a 'a) {:x 'a :y int}) (def a {:x 10 :y 20}) {@a :z 20}"

let test_annot_concrete () = test "(fun int bool)" "(defn foo (x) (< x 3)) foo"

let test_annot_concrete_fail () =
  test_exn
    "Var annotation: Expected type (fun bool int) but got type (fun int bool)"
    "(def (foo (fun bool int)) (fn (x) (< x 3))) foo"

let test_annot_mix () = test "(fun 'a^ 'a)" "(defn pass [(x^ 'b)] x) pass"

let test_annot_mix_fail () =
  test_exn "Var annotation: Expected type (fun 'b int) but got type (fun 'b 'b)"
    "(def (pass (fun 'b int)) (fn (x) x)) pass"

let test_annot_generic () = test "(fun 'a^ 'a)" "(defn pass [(x^ 'b)] x) pass"

let test_annot_generic_fail () =
  test_exn "Var annotation: Expected type (fun 'a 'b) but got type (fun 'a 'a)"
    "(def (pass (fun 'a 'b)) (fn (x) x)) pass"

let test_annot_generic_mut () =
  test "(fun 'a& 'a)" "(defn pass [(x& 'b)] (copy x)) pass"

let test_annot_fun_mut_param () =
  test "(fun int& unit)"
    "(external f (fun int& unit)) (def (a (fun int& unit)) f) a"

let test_annot_generic_fun_mut_param () =
  test "(fun 'a& unit)"
    "(external f (fun 'a& unit)) (def (a (fun 'a& unit)) f) a"

let test_annot_record_simple () =
  test "a" "(type a { :x int }) (type b { :x int }) (def (a a) { :x 12 }) a"

let test_annot_record_generic () =
  test "(a bool)"
    "(type (a 'a) { :x 'a }) (type b { :x int }) (def (a (a bool)) { :x true \
     }) a"

let test_annot_record_generic_multiple () =
  test_exn "Type a expects 2 type parameters"
    "(type (a 'a 'b) { :x 'a :y 'b }) (def (a a) { :x true }) a"

let test_annot_tuple_simple () =
  test "{int bool}" "(def (a {int bool}) {1 true}) a"

let test_annot_array_arg_generic () =
  test "(array int)" "(defn foo [(a^ (array 'a))] a) (foo [10])"

let test_annot_tuple_generic () =
  test "{int bool}" "(defn hmm [(a^ {int 'a})] a) (hmm {1 true})"

let test_sequence () =
  test "int" "(external printi (fun int unit)) (printi 20) (+ 1 1)"

let test_sequence_fail () =
  test_exn
    "Left expression in sequence must be of type unit: Expected type unit but \
     got type int"
    "(defn add1 (x) (+ x 1)) (add1 20) (+ 1 1)"

let test_para_instantiate () =
  test "(foo int)"
    "(type (foo 'a) { :first int :gen 'a }) (def foo { :first 10 :gen 20 }) foo"

let test_para_gen_fun () =
  test "(fun (foo 'a) int)"
    "(type (foo 'a) { :gen 'a :second int }) (defn get (foo) (copy (.second \
     foo))) get"

let test_para_gen_return () =
  test "(fun (foo 'a)^ 'a)"
    "(type (foo 'a) { :gen 'a }) (defn get (foo^) (.gen foo)) get"

let test_para_multiple () =
  test "bool"
    "(type (foo 'a) { :gen 'a }) (defn get (foo^) (.gen foo)) (def a { :gen 12 \
     }) (def (b int) (get a)) (def c { :gen false }) (get c)"

let test_para_instance_func () =
  test "(fun (foo int) int)"
    "(type (foo 'a) { :gen 'a }) (defn use (foo) (+ (.gen foo) 17)) (def foo { \
     :gen 17 }) use"

let test_para_instance_wrong_func () =
  test_exn "In record expression: Expected type int but got type bool"
    "(type (foo 'a) { :gen 'a }) (defn use (foo) (+ (.gen foo) 17)) (def foo { \
     :gen 17 }) (use { :gen true } )"

let test_pipe_head_single () = test "int" "(defn add1 (a) (+ a 1)) (-> 10 add1)"

let test_pipe_head_single_call () =
  test "int" "(defn add1 (a) (+ a 1)) (-> 10  (add1))"

let test_pipe_head_multi_call () =
  test "int" "(defn add1(a) (+ a 1)) (-> 10 add1 add1)"

let test_pipe_head_single_wrong_type () =
  test_exn "Application: Expected type (fun int 'a) but got type int"
    "(def add1 1) (-> 10 add1)"

let test_pipe_head_mult () =
  test "int" "(defn add (a b) (+ a b)) (-> 10 (add 12))"

let test_pipe_head_mult_wrong_type () =
  test_exn "Application: Wrong arity for function: Expected 1 but got 2"
    "(defn add1(a) (+ a 1)) (-> 10 (add1 12))"

let test_pipe_tail_single () = test "int" "(defn add1(a) (+ a 1)) (->> 10 add1)"

let test_pipe_tail_single_call () =
  test "int" "(defn add1(a) (+ a 1)) (->> 10 (add1))"

let test_pipe_tail_single_wrong_type () =
  test_exn "Application: Expected type (fun int 'a) but got type int"
    "(def add1 1) (->> 10 add1)"

let test_pipe_tail_mult () =
  test "int" "(defn add (a b) (+ a b)) (->> 10 (add 12))"

let test_pipe_tail_mult_wrong_type () =
  test_exn "Application: Wrong arity for function: Expected 1 but got 2"
    "(defn add1(a) (+ a 1)) (->> 10 (add1 12))"

let test_alias_simple () =
  test "(fun foo = int unit)" "(type foo int) (external f (fun foo unit)) f"

let test_alias_param_concrete () =
  test "(fun foo = (raw_ptr u8) unit)"
    "(type foo (raw_ptr u8)) (external f (fun foo unit)) f"

let test_alias_param_quant () =
  test "(fun foo = (raw_ptr 'a) unit)"
    "(type (foo 'a) (raw_ptr 'a)) (external f (fun (foo 'a) unit)) f"

let test_alias_param_missing () =
  test_exn "Type foo expects 1 type parameter"
    "(type (foo 'a) (raw_ptr 'a)) (external f (fun foo unit)) f"

let test_alias_of_alias () =
  test "(fun bar = int foo = int)"
    "(type foo int) (type bar foo) (external f (fun bar foo)) f"

let test_array_lit () = test "(array int)" "[0 1]"

let test_array_var () = test "(array int)" {|(def a [0 1])
    a|}

let test_array_weak () =
  test "(array int)"
    {|(external setf (fun (array 'a) 'a unit))
    (def a [])
    (setf a  2)
    a|}

let test_array_different_types () =
  test_exn
    "In array literal: Expected type int but got type bool.\n\
     Cannot unify types int and bool" "[0 true]"

let test_array_different_annot () =
  test_exn
    "In let binding: Expected type (array int) but got type (array bool).\n\
     Cannot unify types int and bool"
    {|(def (a (array bool)) [0 1])
    a|}

let test_array_different_annot_weak () =
  test_exn
    "Application: Expected type (fun (array bool) bool unit) but got type (fun \
     (array bool) int 'a).\n\
     Cannot unify types bool and int"
    {|(external setf (fun (array 'a) 'a unit))
    (def (a (array bool)) [])
    (setf a 2)|}

let test_array_different_weak () =
  test_exn
    "Application: Expected type (fun (array int) int unit) but got type (fun \
     (array int) bool 'a).\n\
     Cannot unify types int and bool"
    {|(external setf (fun (array 'a) 'a unit))
    (def a [])
    (setf a 2)
    (setf a true)|}

let test_mutable_declare () = test "int" "(type foo { :x& int }) 0"

let test_mutable_set () =
  test "unit" "(type foo { :x& int }) (def foo& { :x 12 }) (set &(.x foo) 13)"

let test_mutable_set_wrong_type () =
  test_exn "Mutate: Expected type int but got type bool"
    "(type foo { :x& int }) (def foo& { :x 12 }) (set &(.x foo) true)"

let test_mutable_set_non_mut () =
  test_exn "Cannot mutate non-mutable binding"
    "(type foo { :x int }) (def foo { :x 12}) (set &(.x foo) 13)"

let test_mutable_value () = test "int" "(def b& 10) (set &b 14) b"

let test_mutable_nonmut_value () =
  test_exn "Cannot mutate non-mutable binding" "(def b 10) (set &b 14) b"

let test_mutable_nonmut_transitive () =
  test_exn "Cannot mutate non-mutable binding"
    "(type foo { :x& int }) (def foo { :x 12 }) (set &(.x foo) 13)"

let test_mutable_nonmut_transitive_inv () =
  test_exn "Cannot mutate non-mutable binding"
    "(type foo { :x int }) (def foo& { :x 12 }) (set &(.x foo) 13)"

let test_variants_option_none () =
  test_exn "Expression contains weak type variables: (option 'a)"
    "(type (option 'a) (#none (#some 'a))) #none"

let test_variants_option_some () =
  test "(option int)" "(type (option 'a) (#none (#some 'a))) (#some 1)"

let test_variants_option_some_some () =
  test "(option (option float))"
    "(type (option 'a) (#none (#some 'a))) (def a (#some 1.0)) (#some a)"

let test_variants_option_annot () =
  test "(option (option float))"
    "(type (option 'a) (#none (#some 'a))) (def (a (option float)) #none) \
     (#some a)"

let test_variants_option_none_arg () =
  test_exn
    "The constructor none expects 0 arguments, but an argument is provided"
    "(type (option 'a) (#none (#some 'a))) (#none 1)"

let test_variants_option_some_arg () =
  test_exn "The constructor some expects arguments, but none are provided"
    "(type (option 'a) (#none (#some 'a))) #some"

let test_match_all () =
  test "int"
    "(type (option 'a) (#none (#some 'a))) (match (#some 1) ((#some a) a)  \
     (#none -1))"

let test_match_redundant () =
  test_exn "Pattern match case is redundant"
    "(type (option 'a) (#none (#some 'a))) (match (#some 1) (a a) (#none -1))"

let test_match_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: #some"
    "(type (option 'a) (#none (#some 'a))) (match (#some 1) (#none -1))"

let test_match_missing_nested () =
  test_exn
    "Pattern match is not exhaustive. Missing cases: (#some #int) | (#some \
     #non)"
    {|(type (option 'a) (#none (#some 'a)))
    (type test ((#float float) (#int int) #non))
    (match #none
      ((#some (#float f)) (-> f int_of_float))
      -- ((#some (#int i)) i)
      -- ((#some #non) 1)
      (#none 0))
|}

let test_match_all_after_ctor () =
  test "int"
    {|(type (option 'a) (#none (#some 'a)))
(match (#some 1)
    (#none -1)
    (a 0))
|}

let test_match_all_before_ctor () =
  test_exn "Pattern match case is redundant"
    {|(type (option 'a) (#none (#some 'a)))
    (match (#some 1)
      (a 0)
      (#none -1))
|}

let test_match_redundant_all_cases () =
  test_exn "Pattern match case is redundant"
    {|(type (option 'a) (#none (#some 'a)))
    (type test ((#float float) (#int int) #non))
    (match #none
      ((#some (#float f)) (-> f int_of_float))
      ((#some (#int i)) i)
      ((#some #non) 1)
      (#none 0)
      (a -1))
|}

let test_match_wildcard () =
  test_exn "Pattern match case is redundant"
    {|(type (option 'a) (#none (#some 'a)))
    (match (#some 1)
      (_ 0)
      (#none -1))
|}

let test_match_wildcard_nested () =
  test_exn "Pattern match case is redundant"
    {|(type (option 'a) (#none (#some 'a)))
    (type test ((#float float) (#int int) #non))
    (match #none
      ((#some (#float f)) (-> f int_of_float))
      ((#some _) -2)
      ((#some #non) 1)
      (#none 0))
|}

let test_match_column_arity () =
  test_exn
    "Tuple pattern has unexpected type: Wrong arity for tuple: Expected 2 but \
     got 3"
    {|(type (option 'a) (#none (#some 'a)))
    (match {1 2}
      ({a b c} a))
|}

let test_match_record () =
  test "int"
    "(type (option 'a) ((#some 'a) #none)) (type foo {:a int :b float}) (match \
     (#some {:a 12 :b 53.0}) ((#some {:a :b}) a) (#none 0))"

let test_match_record_field_missing () =
  test_exn "There are missing fields in record pattern, for instance :b"
    "(type (option 'a) ((#some 'a) #none)) (type foo {:a int :b float}) (match \
     (#some {:a 12 :b 53.0}) ((#some {:a}) a) (#none 0))"

let test_match_record_field_twice () =
  test_exn "Field :a appears multiple times in record pattern"
    "(type (option 'a) ((#some 'a) #none)) (type foo {:a int :b float}) (match \
     (#some {:a 12 :b 53.0}) ((#some {:a :a}) a) (#none 0))"

let test_match_record_field_wrong () =
  test_exn "Unbound field :c on record foo"
    "(type (option 'a) ((#some 'a) #none)) (type foo {:a int :b float}) (match \
     (#some {:a 12 :b 53.0}) ((#some {:a :c}) a) (#none 0))"

let test_match_record_case_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: (#some #none)"
    "(type (option 'a) ((#some 'a) #none)) (type (foo 'a) {:a 'a :b float}) \
     (match (#some {:a (#some 2) :b 53.0}) ((#some {:a (#some a) :b}) a) \
     (#none 0))"

let test_match_int () =
  test "int"
    "(type (option 'a) ((#some 'a) #none)) (match (#some 10)  ((#some 1) 1) \
     ((#some 10) 10) ((#some _) 0) (#none -1))"

let test_match_int_wildcard_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: "
    "(type (option 'a) ((#some 'a) #none)) (match (#some 10)  ((#some 1) 1) \
     ((#some 10) 10) (#none -1))"

let test_match_int_twice () =
  test_exn "Pattern match case is redundant"
    "(type (option 'a) ((#some 'a) #none)) (match (#some 10)  ((#some 1) 1) \
     ((#some 10) 10) ((#some 10) 10) ((#some _) 0) (#none -1))"

let test_match_int_after_catchall () =
  test_exn "Pattern match case is redundant"
    "(type (option 'a) ((#some 'a) #none)) (match (#some 10)  ((#some 1) 1) \
     ((#some _) 0) ((#some 10) 10) (#none -1))"

let test_match_or () = test "int" "(match {1 2} ((or {a 1} {a 2}) a) (_ -1))"

let test_match_or_missing_var () =
  test_exn "No var named a" "(match {1 2} ((or {a 1} {b 2}) a) (_ -1))"

let test_match_or_redundant () =
  test_exn "Pattern match case is redundant"
    "(match {1 2} ((or {a 1} {a 2} {a 1}) a) (_ -1))"

let test_multi_record2 () =
  test "(foo int bool)" "(type (foo 'a 'b) {:a 'a :b 'b}) {:a 0 :b false}"

let test_multi_variant2 () =
  test_exn "Expression contains weak type variables: (foo int 'a)"
    "(type (foo 'a 'b) ((#some 'a) (#other 'b))) (#some 1)"

let test_tuple () = test "{int float}" "{1 2.0}"
let test_tuple_access () = test "int" "(.0 {1 2.0})"

let test_tuple_access_out_of_bound () =
  test_exn "Unbound field :2 on tuple of size 2" "(.2 {1 2.0})"

let test_pattern_decl_var () = test "int" "(def a 123) a"
let test_pattern_decl_wildcard () = test "int" "(def _ 123) 0"

let test_pattern_decl_record () =
  test "float" "(type foo {:i int :f float})(def {:i :f} {:i 12 :f 5.0}) f"

let test_pattern_decl_record_wrong_field () =
  test_exn "Unbound field :y on record foo"
    "(type foo {:i int :f float})(def {:y :f} {:i 12 :f 5.0}) f"

let test_pattern_decl_record_missing () =
  test_exn "There are missing fields in record pattern, for instance :i"
    "(type foo {:i int :f float})(def {:f} {:i 12 :f 5.0}) f"

let test_pattern_decl_record_exhaust () =
  test_exn "Pattern match is not exhaustive. Missing cases: "
    "(type foo {:i int :f float})(def {:i 1 :f} {:i 12 :f 5.0}) f"

let test_pattern_decl_tuple () = test "float" "(def {i f} {12 5.0}) f"

let test_pattern_decl_tuple_missing () =
  test_exn
    "Tuple pattern has unexpected type: Wrong arity for tuple: Expected 3 but \
     got 2"
    "(type foo {:i int :f float})(def {x f} {12 5.0 20}) f"

let test_pattern_decl_tuple_exhaust () =
  test_exn "Pattern match is not exhaustive. Missing cases: "
    "(def {1 f} {12 5.0}) f"

let test_signature_only () = test "unit" "(signature (type t int))"

let test_signature_simple () =
  test "unit" "(signature (type t int)) (type t int)"

let test_signature_wrong_typedef () =
  test_exn
    "Mismatch between implementation and signature: Expected type t = int but \
     got type t = float"
    "(signature (type t int)) (type t float)"

let test_signature_generic () =
  test "unit"
    {|(signature
  (type (t 'a))
  (def create (fun 'a^ (t 'a)))
  (def create-int (fun int (t int))))

(type (t 'a) {:x 'a})

(defn create [x^] {:x})
(defn create-int [(x int)] {:x})
|}

let test_signature_param_mismatch () =
  test_exn
    "Mismatch between implementation and signature: Expected type (fun int (t \
     int)) but got type (fun int (t 'a))"
    {|(signature
  (type (t 'a))
  (def create-int (fun int (t int))))
(type (t 'a) {:x int})
(defn create-int [(x int)] {:x})|}

let test_signature_unparam_type () =
  test_exn "Unparamatrized type in module implementation"
    {|(signature
  (type (t 'a)))
(type (t 'a) int)|}

let local_module =
  "(type t float) (type global int) (module nosig (type t {:a int}) (type \
   other int) (module nested (type t u8)))"

let test_local_modules_find_local () =
  test "unit" (local_module ^ " (def (test nosig/t) {:a 10})")

let test_local_modules_find_nested () =
  test "unit" (local_module ^ " (def (test nosig/nested/t) 0u8)")

let test_local_modules_miss_local () =
  test_exn "In let binding: Expected type float but got type nosig/t"
    (local_module ^ " (def (test nosig/t) 10.0)")

let test_local_modules_miss_nested () =
  test_exn "Expected a record type, not nosig/nested/t = u8"
    (local_module ^ " (def (test nosig/nested/t) {:a 10})")

let test_local_modules_miss_local_dont_find_global () =
  test_exn "Unbound type nosig/global."
    (local_module ^ " (def (test nosig/global) {:a 10})")

let test_local_module_unique_names () =
  test_exn "Module names must be unique. nosig exists already"
    (local_module ^ "(module nosig)")

let own = "(def x& 10)\n"

let test_excl_borrow () =
  wrap_fn test "unit" (own ^ "(def y x) (ignore x) (ignore y)")

let test_excl_borrow_use_early () =
  wrap_fn test_exn "x was borrowed in line 2, cannot mutate"
    (own ^ "(def y x)\n (ignore x)\n (set &x 11)\n (ignore y)")

let test_excl_move_mut () =
  wrap_fn test "unit" (own ^ "(def y& x) (set &y 11) (ignore y)")

let test_excl_move_mut_use_after () =
  wrap_fn test_exn "x was moved in line 2, cannot use"
    (own ^ "(def y& x) (ignore x)")

let test_excl_move_record () =
  wrap_fn test "unit" (own ^ "(def y {x}) (ignore y)")

let test_excl_move_record_use_after () =
  wrap_fn test_exn "x was moved in line 2, cannot use"
    "(def x& [10])\n (def y {x}) (ignore x)"

let test_excl_borrow_then_move () =
  wrap_fn test_exn "x was moved in line 3, cannot use"
    "(def x [10])\n (def y x)\n (ignore {y})\n x"

let test_excl_if_move_lit () =
  wrap_fn test "unit" "(def x 10) (def y& (if true x 10)) (ignore y)"

let test_excl_if_borrow_borrow () =
  wrap_fn test "unit" "(def x 10) (def y 10) (ignore (if true x y))"

let test_excl_if_lit_borrow () =
  wrap_fn test_exn "Branches have different ownership: owned vs borrowed"
    "(def x [10]) (ignore (if true [10] x))"

let test_excl_proj () =
  wrap_fn ~proj:true test "unit" (own ^ "(def y& &x) (set &y 11) (ignore x)")

let test_excl_proj_immutable () =
  wrap_fn ~proj:true test_exn "Cannot project unmutable binding"
    "(def x 10) (def y& &x) x"

let test_excl_proj_use_orig () =
  wrap_fn ~proj:true test_exn "x was mutably borrowed in line 2, cannot borrow"
    (own ^ "(def y& &x)\n (ignore x)\n (ignore y)\n x")

let test_excl_proj_move_after () =
  wrap_fn ~proj:true test_exn "x was mutably borrowed in line 2, cannot borrow"
    (own ^ "(def y& &x)\n (ignore x)\n {y}")

let test_excl_proj_nest () =
  wrap_fn ~proj:true test_exn "y was mutably borrowed in line 3, cannot borrow"
    (own ^ "(def y& &x)\n (def z& &y)\n (ignore y)\n z")

let test_excl_proj_nest_orig () =
  wrap_fn ~proj:true test_exn "x was mutably borrowed in line 2, cannot borrow"
    (own ^ "(def y& &x)\n (def z& &y)\n (ignore x)\n z")

let test_excl_proj_nest_closed () =
  wrap_fn ~proj:true test "unit"
    (own ^ "(def y& &x)\n (def z& &y)\n (ignore z)\n y")

let test_excl_moved_param () =
  test_exn "Borrowed parameter x is moved" "(defn meh [x] x)"

let test_excl_set_moved () =
  test "unit" "(defn meh [a&] (ignore {a}) (set &a 10))"

let test_excl_binds () =
  test "unit"
    {|
(type ease-kind (#linear #circ-in))

(defn ease-circ-in [_] 0.0)
(defn ease-linear [_] 0.0)

(defn ease [anim]
  (match anim
    (#linear (ease-linear anim))
    (#circ-in (ease-circ-in anim))))|}

let test_excl_shadowing () =
  test_exn "Borrowed parameter a is moved" "(defn thing [a] (def a a) a)"

let typ = "(type string (array u8))\n (type t {:a string :b string})\n"

let test_excl_parts_success () =
  test "unit" (typ ^ "(defn meh [a!]\n {:a a.a :b a.b})")

let test_excl_parts_return_part () =
  test "unit" (typ ^ "(defn meh [a!]\n (def c& a.a)\n a.b)")

let test_excl_parts_return_whole () =
  test_exn "a.a was moved in line 4, cannot use"
    (typ ^ "(defn meh [a!]\n (def c& a.a)\n a)")

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
          (* case "recursive_if" test_func_recursive_if; *)
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
          case "update" test_record_update;
          case "update poly" test_record_update_poly_same;
          case "update poly_change" test_record_update_poly_change;
          case "update useless" test_record_update_useless;
          case "update expr" test_record_update_expr;
          case "update wrong field" test_record_update_wrong_field;
        ] );
      ( "annotations",
        [
          case "concrete" test_annot_concrete;
          case "concrete_fail" test_annot_concrete_fail;
          case "mix" test_annot_mix;
          case "mix_fail" test_annot_mix_fail;
          case "generic" test_annot_generic;
          case "generic_fail" test_annot_generic_fail;
          case "generic mut" test_annot_generic_mut;
          case "fun mut param" test_annot_fun_mut_param;
          case "generic fun mut param" test_annot_generic_fun_mut_param;
          case "record_let" test_annot_record_simple;
          case "record_let_gen" test_annot_record_generic;
          case "record_muliple" test_annot_record_generic_multiple;
          case "tuple simple" test_annot_tuple_simple;
          case "array arg generic" test_annot_array_arg_generic;
          case "tuple generic" test_annot_tuple_generic;
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
      ( "array",
        [
          case "literal" test_array_lit;
          case "var" test_array_var;
          case "weak" test_array_weak;
          case "different_types" test_array_different_types;
          case "different_annot" test_array_different_annot;
          case "different_annot_weak" test_array_different_annot_weak;
          case "different_weak" test_array_different_weak;
        ] );
      ( "mutable",
        [
          case "declare" test_mutable_declare;
          case "set" test_mutable_set;
          case "set_wrong_type" test_mutable_set_wrong_type;
          case "set_non_mut" test_mutable_set_non_mut;
          case "value" test_mutable_value;
          case "nonmut value" test_mutable_nonmut_value;
          case "nonmut transitive" test_mutable_nonmut_transitive;
          case "nonmut transitive inversed" test_mutable_nonmut_transitive_inv;
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
          case "record" test_match_record;
          case "record field missing" test_match_record_field_missing;
          case "record field twice" test_match_record_field_twice;
          case "record field wrong" test_match_record_field_wrong;
          case "record case missing" test_match_record_case_missing;
          case "int" test_match_int;
          case "int wildcard missing" test_match_int_wildcard_missing;
          case "int twice" test_match_int_twice;
          case "int after catchall" test_match_int_after_catchall;
          case "or" test_match_or;
          case "or missing var" test_match_or_missing_var;
          case "or redundant" test_match_or_redundant;
        ] );
      ( "multi params",
        [
          case "record 2" test_multi_record2;
          case "variant 2" test_multi_variant2;
        ] );
      ( "tuples",
        [
          case "tuple" test_tuple;
          case "tuple access" test_tuple_access;
          case "tuple access out of bound" test_tuple_access_out_of_bound;
        ] );
      ( "pattern decl",
        [
          case "var" test_pattern_decl_var;
          case "wildcard" test_pattern_decl_wildcard;
          case "record" test_pattern_decl_record;
          case "record wrong field" test_pattern_decl_record_wrong_field;
          case "record missing" test_pattern_decl_record_missing;
          case "record exhaust" test_pattern_decl_record_exhaust;
          case "tuple" test_pattern_decl_tuple;
          case "tuple missing" test_pattern_decl_tuple_missing;
          case "tuple exhaust" test_pattern_decl_tuple_exhaust;
        ] );
      ( "signature",
        [
          case "only" test_signature_only;
          case "simple" test_signature_simple;
          case "wrong type" test_signature_wrong_typedef;
          case "generic" test_signature_generic;
          case "param mismatch" test_signature_param_mismatch;
          case "unparam type" test_signature_unparam_type;
        ] );
      ( "local modules",
        [
          case "find local" test_local_modules_find_local;
          case "find nested" test_local_modules_find_nested;
          case "miss local" test_local_modules_miss_local;
          case "miss nested" test_local_modules_miss_nested;
          case "miss local don't find global"
            test_local_modules_miss_local_dont_find_global;
          case "unique names" test_local_module_unique_names;
        ] );
      ( "exclusivity",
        [
          case "borrow" test_excl_borrow;
          case "borrow use early" test_excl_borrow_use_early;
          case "move mut" test_excl_move_mut;
          case "move mut use after" test_excl_move_mut_use_after;
          case "move record" test_excl_move_record;
          case "move record use after" test_excl_move_record_use_after;
          case "borrow then move" test_excl_borrow_then_move;
          case "if move lit" test_excl_if_move_lit;
          case "if borrow borrow" test_excl_if_borrow_borrow;
          case "if lit borrow" test_excl_if_lit_borrow;
          case "project" test_excl_proj;
          case "project immutable" test_excl_proj_immutable;
          case "proj use orig" test_excl_proj_use_orig;
          case "proj use orig move" test_excl_proj_move_after;
          case "proj nest" test_excl_proj_nest;
          case "proj nest access orig" test_excl_proj_nest_orig;
          case "proj nest close" test_excl_proj_nest_closed;
          case "moved parameter" test_excl_moved_param;
          case "set moved" test_excl_set_moved;
          case "binds" test_excl_binds;
          case "shadowing" test_excl_shadowing;
          case "parts update" test_excl_parts_success;
          case "parts return part" test_excl_parts_return_part;
          case "parts return whole after part move" test_excl_parts_return_whole;
          tase_exn "func mut borrow"
            "a was mutably borrowed in line 4, cannot borrow"
            {|
(defn hmm []
 (def a& 10)
  (defn set-a []
    (set &a 11))
  (set &a 11)
  (set-a)
  (set &a 11))
|};
          tase_exn "func move"
            "a was moved in line 4, cannot use. Hint: Move occurs in line 5"
            {|
(defn hmm []
  (def a& 10)
  (defn move-a []
    a)
  (ignore a)
  (ignore (move-a))
  (ignore a))|};
        ] );
    ]
