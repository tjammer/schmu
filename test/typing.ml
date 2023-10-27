open Alcotest
open Schmulang
open Error

let get_type src =
  let open Lexing in
  let lexbuf = from_string src in
  Parser.prog Lexer.read lexbuf |> Typing.typecheck |> fun t ->
  Types.string_of_type Typing.main_path t

let test a src = (check string) "" a (get_type src)

let test_exn msg src =
  (check string) "" msg
    (try
       ignore (get_type src);
       failwith "Expected an exception"
     with Error (_, msg) -> msg)

let tase descr msg src = test_case descr `Quick (fun () -> test msg src)
let tase_exn descr msg src = test_case descr `Quick (fun () -> test_exn msg src)

let wrap_fn ?(tl = None) t expect code =
  (* toplevel *)
  match tl with
  | None -> t expect code
  | Some msg ->
      test_exn msg code;
      (* function *)
      t expect ("(defn f [] " ^ code ^ ")")

let test_const_int () = test "int" "(def a 1) a"
let test_const_neg_int () = test "int" "(def a -1) a"

let test_const_neg_int_wrong () =
  test_exn "In unary - expecting [int or float] but found [bool]"
    "(def a -true) a"

let test_const_neg_int2 () = test "int" "(def a - 1) a"
let test_const_float () = test "float" "(def a 1.0) a"
let test_const_neg_float () = test "float" "(def a -1.0) a"

let test_const_neg_float_wrong () =
  test_exn "In unary -. expecting [float] but found [bool]" "(def a -.true) a"

let test_const_neg_float2 () = test "float" "(def a -.1.0) a"
let test_const_bool () = test "bool" "(def a true) a"
let test_const_u8 () = test "u8" "(def a 123u8) a"
let test_const_i32 () = test "i32" "(def a 123i32) a"
let test_const_neg_i32 () = test "i32" "(def a -123i32) a"
let test_const_f32 () = test "f32" "(def a 1.0f32) a"
let test_const_neg_f32 () = test "f32" "(def a -1.0f32) a"
let test_hint_int () = test "int" "(def (a int) 1) a"
let test_func_id () = test "(fun 'a 'a)" "(fn (a) (copy a))"
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

let test_func_capture_annot () =
  test "unit"
    "(external somefn (fun unit int)) (defn wrapper () (def a (somefn)) (defn \
     captured :copy a () (+ 1 a)) ()) ()"

let test_func_capture_annot_wrong () =
  test_exn "Value a is not captured, cannot copy" "(defn somefn :copy a () ())"

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
  test_exn "In record expression expecting [int] but found [bool]"
    "(type t {:x int}) {:x true}"

let test_record_wrong_choose () =
  test_exn "In record expression expecting [int] but found [bool]"
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
  test_exn "Field access of record t expecting [t] but found [int]"
    "(type t {:x int}) (def a 10) (.x a)"

let test_record_field_wrong_record () =
  test_exn "In application expecting (fun [t1] _) but found (fun [t2] _)"
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

let test_annot_mix () = test "(fun 'a! 'a)" "(defn pass [(x! 'b)] x) pass"

let test_annot_mix_fail () =
  test_exn "Var annotation: Expected type (fun 'b int) but got type (fun 'b 'b)"
    "(def (pass (fun 'b int)) (fn (x) (copy x))) pass"

let test_annot_generic () = test "(fun 'a! 'a)" "(defn pass [(x! 'b)] x) pass"

let test_annot_generic_fail () =
  test_exn "Var annotation: Expected type (fun 'a 'b) but got type (fun 'a 'a)"
    "(def (pass (fun 'a 'b)) (fn (x) (copy x))) pass"

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
  test "(array int)" "(defn foo [(a! (array 'a))] a) (foo ![10])"

let test_annot_tuple_generic () =
  test "{int bool}" "(defn hmm [(a! {int 'a})] a) (hmm !{1 true})"

let test_annot_fixed_size_array () =
  test "(array#32 int)" "(defn hmm [(a! (array#32 'a))] a) (hmm !#32[0])"

let test_sequence () =
  test "int" "(external printi (fun int unit)) (printi 20) (+ 1 1)"

let test_sequence_fail () =
  test_exn
    "Left expression in sequence must be of type unit,\n\
     expecting [unit]\n\
     but found [int]" "(defn add1 (x) (+ x 1)) (add1 20) (+ 1 1)"

let test_para_instantiate () =
  test "(foo int)"
    "(type (foo 'a) { :first int :gen 'a }) (def foo { :first 10 :gen 20 }) foo"

let test_para_gen_fun () =
  test "(fun (foo 'a) int)"
    "(type (foo 'a) { :gen 'a :second int }) (defn get (foo) (copy (.second \
     foo))) get"

let test_para_gen_return () =
  test "(fun (foo 'a)! 'a)"
    "(type (foo 'a) { :gen 'a }) (defn get (foo!) (.gen foo)) get"

let test_para_multiple () =
  test "bool"
    "(type (foo 'a) { :gen 'a }) (defn get (foo) (copy (.gen foo))) (def a { \
     :gen 12 }) (def (b int) (get a)) (def c { :gen false }) (get c)"

let test_para_instance_func () =
  test "(fun (foo int) int)"
    "(type (foo 'a) { :gen 'a }) (defn use (foo) (+ (.gen foo) 17)) (def foo { \
     :gen 17 }) use"

let test_para_instance_wrong_func () =
  test_exn "In record expression expecting [int] but found [bool]"
    "(type (foo 'a) { :gen 'a }) (defn use (foo) (+ (.gen foo) 17)) (def foo { \
     :gen 17 }) (use { :gen true } )"

let test_pipe_head_single () = test "int" "(defn add1 (a) (+ a 1)) (-> 10 add1)"

let test_pipe_head_single_call () =
  test "int" "(defn add1 (a) (+ a 1)) (-> 10  (add1))"

let test_pipe_head_multi_call () =
  test "int" "(defn add1(a) (+ a 1)) (-> 10 add1 add1)"

let test_pipe_head_single_wrong_type () =
  test_exn "In application expecting [(fun int 'a)] but found [int]"
    "(def add1 1) (-> 10 add1)"

let test_pipe_head_mult () =
  test "int" "(defn add (a b) (+ a b)) (-> 10 (add 12))"

let test_pipe_head_mult_wrong_type () =
  test_exn "In application expecting (fun [int int] _) but found (fun [int] _)"
    "(defn add1(a) (+ a 1)) (-> 10 (add1 12))"

let test_pipe_tail_single () = test "int" "(defn add1(a) (+ a 1)) (->> 10 add1)"

let test_pipe_tail_single_call () =
  test "int" "(defn add1(a) (+ a 1)) (->> 10 (add1))"

let test_pipe_tail_single_wrong_type () =
  test_exn "In application expecting [(fun int 'a)] but found [int]"
    "(def add1 1) (->> 10 add1)"

let test_pipe_tail_mult () =
  test "int" "(defn add (a b) (+ a b)) (->> 10 (add 12))"

let test_pipe_tail_mult_wrong_type () =
  test_exn "In application expecting (fun [int int] _) but found (fun [int] _)"
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

let test_alias_labels () =
  test "(inner/t int)"
    {|(module inner
  (type (t 'a) {:a 'a :b int}))
(type (t 'a) (inner/t 'a))
{:a 20 :b 10}
|}

let test_alias_ctors () =
  test "(inner/t int)"
    {|(module inner
  (type (t 'a) (#noo (#yes 'a))))
(type (t 'a) (inner/t 'a))
(#yes 10)|}

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
  test_exn "In array literal expecting [int] but found [bool]" "[0 true]"

let test_array_different_annot () =
  test_exn "In let binding expecting (array [int]) but found (array [bool])"
    {|(def (a (array bool)) [0 1])
    a|}

let test_array_different_annot_weak () =
  test_exn "In application expecting (fun _ [bool] _) but found (fun _ [int] _)"
    {|(external setf (fun (array 'a) 'a unit))
    (def (a (array bool)) [])
    (setf a 2)|}

let test_array_different_weak () =
  test_exn "In application expecting (fun _ [int] _) but found (fun _ [bool] _)"
    {|(external setf (fun (array 'a) 'a unit))
    (def a [])
    (setf a 2)
    (setf a true)|}

let test_mutable_declare () = test "int" "(type foo { :x& int }) 0"

let test_mutable_set () =
  test "unit" "(type foo { :x& int }) (def foo& { :x 12 }) (set &(.x foo) !13)"

let test_mutable_set_wrong_type () =
  test_exn "In mutation expecting [int] but found [bool]"
    "(type foo { :x& int }) (def foo& { :x 12 }) (set &(.x foo) !true)"

let test_mutable_set_non_mut () =
  test_exn "Cannot mutate non-mutable binding"
    "(type foo { :x int }) (def foo { :x 12}) (set &(.x foo) !13)"

let test_mutable_value () = test "int" "(def b& 10) (set &b !14) b"

let test_mutable_nonmut_value () =
  test_exn "Cannot mutate non-mutable binding" "(def b 10) (set &b !14) b"

let test_mutable_nonmut_transitive () =
  test_exn "Cannot mutate non-mutable binding"
    "(type foo { :x& int }) (def foo { :x 12 }) (set &(.x foo) !13)"

let test_mutable_nonmut_transitive_inv () =
  test_exn "Cannot mutate non-mutable binding"
    "(type foo { :x int }) (def foo& { :x 12 }) (set &(.x foo) !13)"

let test_variants_option_none () =
  test_exn "Expression contains weak type variables: (option 'a)"
    "(type (option 'a) (#none (#some 'a))) #none"

let test_variants_option_some () =
  test "(option int)" "(type (option 'a) (#none (#some 'a))) (#some 1)"

let test_variants_option_some_some () =
  test "(option (option float))"
    "(type (option 'a) (#none (#some 'a))) (def a (#some 1.0)) (#some (copy a))"

let test_variants_option_annot () =
  test "(option (option float))"
    "(type (option 'a) (#none (#some 'a))) (let [(a (option float)) #none] \
     (#some a))"

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
    "Tuple pattern has unexpected type:\n\
     expecting [{int int}]\n\
     but found [{'a 'a 'a}]"
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
    "Tuple pattern has unexpected type:\n\
     expecting [{int float int}]\n\
     but found [{'a 'a}]"
    "(type foo {:i int :f float})(def {x f} {12 5.0 20}) f"

let test_pattern_decl_tuple_exhaust () =
  test_exn "Pattern match is not exhaustive. Missing cases: "
    "(def {1 f} {12 5.0}) f"

let test_signature_only () = test "unit" "(signature (type t int))"

let test_signature_simple () =
  test "unit" "(signature (type t int)) (type t int)"

let test_signature_wrong_typedef () =
  test_exn
    "Mismatch between implementation and signature\n\
     expecting [t = int]\n\
     but found [t = float]" "(signature (type t int)) (type t float)"

let test_signature_generic () =
  test "unit"
    {|(signature
  (type (t 'a))
  (def create (fun 'a! (t 'a)))
  (def create-int (fun int (t int))))

(type (t 'a) {:x 'a})

(defn create [x!] {:x})
(defn create-int [(x int)] {:x})
|}

let test_signature_param_mismatch () =
  test_exn
    "Mismatch between implementation and signature\n\
     expecting (fun _ [(t int)])\n\
     but found (fun _ [(t 'a)])"
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
  test_exn "In let binding expecting [float] but found [nosig/t]"
    (local_module ^ " (def (test nosig/t) 10.0)")

let test_local_modules_miss_nested () =
  test_exn "Expected a record type, not nosig/nested/t = u8"
    (local_module ^ " (def (test nosig/nested/t) {:a 10})")

let test_local_modules_miss_local_dont_find_global () =
  test_exn "Unbound type nosig/global."
    (local_module ^ " (def (test nosig/global) {:a 10})")

let test_local_module_unique_names () =
  test_exn "Module names must be unique. nosig exists already"
    (local_module ^ "(module nosig ())")

let test_local_module_nested_module_alias () =
  test "nosig/nested/t"
    {|(module nosig
  (type t {:a int :b int})
  (def _ {:a 10 :b 20})
  (module nested
    (type t {:a int :b int :c int})
    (def t {:a 10 :b 20 :c 30})))

(module mm nosig/nested)
nosig/nested/t|}

let test_local_module_alias_dont () =
  test_exn "Cannot find module: nested in nosig/nested"
    {|-- this shouldn't be found
(module nested
  (type t {:a int :b int :c int})
    (def t {:a 11 :b 21 :c 31}))

(module nosig
  (type t {:a int :b int})
  (def _ {:a 10 :b 20})
  (module not-nested
    (type t {:a int :b int :c int})
    (def t {:a 10 :b 20 :c 30})))

(module mm nosig/nested)
nosig/nested.t|}

let own = "(def x& 10)\n"
let tl = Some "Cannot borrow mutable binding at top level"

let test_excl_borrow () =
  wrap_fn ~tl test "unit" (own ^ "(def y x) (ignore x) (ignore y)")

let test_excl_borrow_use_early () =
  wrap_fn ~tl test_exn "x was borrowed in line 2, cannot mutate"
    (own ^ "(def y x)\n (ignore x)\n (set &x !11)\n (ignore y)")

let tl = Some "Cannot move top level binding"

let test_excl_move_mut () =
  wrap_fn ~tl test "unit" (own ^ "(def y& !x) (set &y !11) (ignore y)")

let test_excl_move_mut_use_after () =
  wrap_fn test_exn "x was moved in line 2, cannot use"
    (own ^ "(def y& !x) (ignore x)")

let test_excl_move_record () =
  wrap_fn test "unit" (own ^ "(def y {x}) (ignore y)")

let test_excl_move_record_use_after () =
  wrap_fn test_exn "x was moved in line 2, cannot use"
    "(def x& [10])\n (def y {x}) (ignore x)"

let test_excl_borrow_then_move () =
  wrap_fn test_exn "x was moved in line 3, cannot use"
    "(def x [10])\n (def y x)\n (ignore {y})\n x"

let test_excl_if_move_lit () =
  wrap_fn ~tl test "unit" "(def x 10) (def y& !(if true x 10)) (ignore y)"

let test_excl_if_borrow_borrow () =
  wrap_fn test "unit" "(def x 10) (def y 10) (ignore (if true x y))"

let test_excl_if_lit_borrow () =
  wrap_fn test_exn "Branches have different ownership: owned vs borrowed"
    "(def x [10]) (ignore (if true [10] x))"

let proj_msg = Some "Cannot project at top level"

let test_excl_proj () =
  wrap_fn ~tl:proj_msg test "unit" (own ^ "(def y& &x) (set &y !11) (ignore x)")

let test_excl_proj_immutable () =
  wrap_fn ~tl:proj_msg test_exn "Cannot project immutable binding"
    "(def x 10) (def y& &x) x"

let test_excl_proj_use_orig () =
  wrap_fn ~tl:proj_msg test_exn
    "x was mutably borrowed in line 2, cannot borrow"
    (own ^ "(def y& &x)\n (ignore x)\n (ignore y)\n x")

let test_excl_proj_move_after () =
  wrap_fn ~tl:proj_msg test_exn
    "x was mutably borrowed in line 2, cannot borrow"
    (own ^ "(def y& &x)\n (ignore x)\n {y}")

let test_excl_proj_nest () =
  wrap_fn ~tl:proj_msg test_exn
    "y was mutably borrowed in line 3, cannot borrow"
    (own ^ "(def y& &x)\n (def z& &y)\n (ignore y)\n z")

let test_excl_proj_nest_orig () =
  wrap_fn ~tl:proj_msg test_exn
    "x was mutably borrowed in line 2, cannot borrow"
    (own ^ "(def y& &x)\n (def z& &y)\n (ignore x)\n z")

let test_excl_proj_nest_closed () =
  wrap_fn ~tl:proj_msg test "unit"
    (own ^ "(def y& &x)\n (def z& &y)\n (ignore z)\n y")

let test_excl_moved_param () =
  test_exn "Borrowed parameter x is moved" "(defn meh [x] x)"

let test_excl_set_moved () =
  test "unit" "(defn meh [a&] (ignore {a}) (set &a !10))"

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
  test "unit" (typ ^ "(defn meh [a!]\n (def c& !a.a)\n a.b)")

let test_excl_parts_return_whole () =
  test_exn "a.a was moved in line 4, cannot use"
    (typ ^ "(defn meh [a!]\n (def c& !a.a)\n a)")

let test_excl_lambda_copy_capture () =
  test "unit" "(defn alt [alts] (fn :copy alts () (ignore alts.[0])))"

let test_excl_lambda_copy_capture_nonalloc () =
  test "unit" "(defn alt [alts] (fn :copy alts () (ignore (+ 1 alts))))"

let test_excl_lambda_not_copy_capture () =
  test_exn "Borrowed parameter alts is moved"
    "(defn alt [alts] (fn () (ignore alts.[0])))"

let test_excl_fn_copy_capture () =
  test "unit"
    "(defn alt (alts) (defn named :copy alts () (ignore alts.[0])) named)"

let test_excl_fn_not_copy_capture () =
  test_exn "Borrowed parameter alts is moved"
    "(defn alt (alts) (defn named () (ignore alts.[0])) named)"

let test_type_decl_not_unique () =
  test_exn "Type names in a module must be unique. t exists already"
    "(type t int) (type t float)"

let test_type_decl_open_before () =
  test "unit" "(module m (type t int)) (open m) (type t float)"

let test_mtype_define () =
  test "unit" "(module-type tt (type t) (def random (fun unit int)))"

let test_mtype_no_match () =
  test_exn "Signatures don't match: Type test/t is missing"
    {|(module-type tt (type t))
(module (test tt)
 (type a unit))|}

let test_mtype_no_match_alias () =
  test_exn "Signatures don't match: Type test/t is missing"
    {|(module-type tt (type t))
(module test
 (type a unit))
(module (other tt) test)|}

let test_mtype_no_match_sign () =
  test_exn "Signatures don't match: Type test/t is missing"
    {|(module-type tt (type t))
(module (test tt)
 (signature
    (type a))
 (type a unit))|}

let test_mtype_abstracts () =
  test "unit"
    {|(module outer
  (type t {:i int}))

(module-type sig
  (type t)
  (def add (fun t t t)))

(functor make [(m sig)]
  (defn add-twice (a b)
    (m/add (m/add a b) b)))

(module (outa sig)
  (type t outer/t)
  (defn add (a b) {:i (+ a.i b.i)}))

(module (inta sig)
  (type t int)
  (defn add (a b) (+ a b)))

(module (floata sig)
  (signature
    (type t)
    (def add (fun t t t)))
  (type t float)
  (defn add (a b) (+. a b)))

(module (somerec sig)
  (type t {:a int :b int})
  (defn add (a b) {:a (+ a.a b.a) :b (+ a.b b.b)}))
|}

let test_functor_define () =
  test "unit" "(module-type mt (type t)) (functor f [(p mt)] ())"

let test_functor_module_type_not_found () =
  test_exn "Cannot find module type mt" "(functor f [(p mt)] ())"

let test_functor_direct_access () =
  test_exn "The module f is a functor. It cannot be accessed directly"
    "(module-type mt (type t)) (functor f [(p mt)] (type a unit)) (ignore f/a)"

let test_functor_checked_alias () =
  test_exn "The module f is a functor. It cannot be accessed directly"
    "(module-type mt (type t)) (functor f [(p mt)] (type a unit)) (module (hmm \
     mt) f)"

let test_functor_wrong_arity () =
  test_exn "Wrong arity for functor f: Expecting 1 but got 2"
    "(module-type mt (type t)) (functor f [(p mt)] ()) (module a (type t \
     unit)) (module hmm (f a a))"

let test_functor_wrong_module_type () =
  test_exn "Signatures don't match: Type a/t is missing"
    "(module-type mt (type t)) (functor f [(p mt)] ()) (module a ()) (module \
     hmm (f a))"

let test_functor_no_var_param () =
  test_exn "No var named p/a"
    "(module-type mt (type t)) (functor f [(p mt)] (def _ (ignore p/a)))"

let test_functor_apply_use () =
  test "inta/t = int"
    {|(module-type sig
  (type t)
  (def add (fun t t t)))

(functor make [(m sig)]
  (defn add-twice (a b)
    (m/add (m/add a b) b)))

(module (inta sig)
  (type t int)
  (defn add (a b) (+ a b)))

(module intadder (make inta))
(intadder/add-twice 1 2)
|}

let test_functor_abstract_param () =
  test_exn
    "In application\n\
     expecting (fun [inta/t] [inta/t] _)\n\
     but found (fun [int] [int] _)"
    {|(module-type sig
  (type t)
  (def add (fun t t t)))

(functor make [(m sig)]
  (defn add-twice (a b)
    (m/add (m/add a b) b)))

(module (inta sig)
  (signature
    (type t)
    (def add (fun t t t)))
  (type t int)
  (defn add (a b) (+ a b)))

(module intadder (make inta))
(intadder/add-twice 1 2)
|}

let test_functor_use_param_type () =
  test "unit"
    {|(module-type sig
  (type t))

(functor make [(m sig)]
  (type t m/t))|}

let test_functor_poly_function () =
  test "unit"
    {|(module-type poly
  (def id (fun 'a! 'a)))

(functor makeid [(m poly)]
  (defn newid (p!) (m/id !p)))

(module some
  (defn id [p!] p))

(module polyappl (makeid some))

(ignore (polyappl/newid !1))
(ignore (polyappl/newid !1.2))|}

let test_functor_poly_mismatch () =
  test_exn
    "Signatures don't match for id\n\
     expecting (fun ['a]! ['a])\n\
     but found (fun [int]! [int])"
    {|(module-type poly
  (def id (fun 'a! 'a)))

(functor makeid [(m poly)]
  (defn newid (p!) (m/id !p)))

(module someint
  (defn id [(p! int)] p))

(module intappl (makeid someint))|}

(* Copied from hashtbl *)
let check_sig_test thing =
  {|(module-type key
  (type t))

(module-type sig
  (type key)
  (type (t 'value))

  (def create (fun int (t |}
  ^ thing
  ^ {|))))

(functor (make sig) [(m key)]
 (type key m/t)
 (type (item 'a) {:key m/t :value 'a})
 (type (slot 'a) (#empty #tombstone (#item (item 'a))))
 (type (t 'a) {:data& (array (slot 'a)) :nitems& int})

  (defn create [(size int)]
    (ignore size)
    (def data [])
    {:data :nitems 0}))|}

let test_functor_check_sig () = test "unit" (check_sig_test "'value")

let test_functor_check_param () =
  test_exn
    "Signatures don't match for create\n\
     expecting (fun _ [(sig/t sig/key)])\n\
     but found (fun _ [(make/t 'a)])" (check_sig_test "key")

let test_functor_check_concrete () =
  test_exn
    "Signatures don't match for create\n\
     expecting (fun _ [(sig/t int)])\n\
     but found (fun _ [(make/t 'a)])" (check_sig_test "int")

let test_farray_lit () = test "unit" "(def arr #[1 2 3])"
let test_farray_nested_lit () = test "unit" "(def arr #[#[1 2 3] #[3 4 5]])"

let test_farray_inference () =
  test "unit"
    "(defn print-snd [arr] (ignore (fmt-str arr.(1)))) (print-snd #[1 3 2]) \
     (print-snd #[\"hey\" \"hi\"])"

let test_partial_move_outer_imm () =
  test_exn "Cannot move string literal. Use `copy`"
    "(def a \"hii\") (defn move-a [_ a!] a) (ignore ((move-a 0) !a))"

let test_partial_move_outer_delayed () =
  test_exn "Cannot move string literal. Use `copy`"
    "(def a \"hii\") (defn move-a [a! _] a) (ignore ((move-a !a) 0))"

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
          case "capture annot" test_func_capture_annot;
          case "capture annot wrong" test_func_capture_annot_wrong;
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
          case "fixed-size array" test_annot_fixed_size_array;
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
          case "usable labels" test_alias_labels;
          case "usable ctors" test_alias_ctors;
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
          case "nested module alias" test_local_module_nested_module_alias;
          case "alias don't find outer" test_local_module_alias_dont;
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
          tase_exn "func mut borrow" "a was borrowed in line 5, cannot mutate"
            {|
(def a& 10)
(defn set-a []
  (set &a !11))
(let [b a]
  (set-a)
  (ignore b))|};
          tase_exn "func move" "Cannot move value a from outer scope"
            {|
(defn hmm []
  (def a& [10])
  (defn move-a []
    a)
  (ignore a)
  (ignore (move-a))
  (ignore a))|};
          tase_exn "closure mut borrow"
            "a was mutably borrowed in line 3, cannot borrow"
            {|(defn hmm []
              (def a& 10)
               (def set-a (fn [] (set &a !11)))
               (set &a !11)
               (set-a)
               (set &a !11))
             |};
          tase_exn "closure carry set"
            "a was mutably borrowed in line 3, cannot borrow"
            (* If the 'set' attribute isn't carried, (set-a) cannot be called
               and a different error occurs *)
            {|(defn hmm []
  (def a& [10])
  (def set-a (fn [] (set &a ![11])))
  (set &a ![11])
  (def x& !a)
  (set-a))|};
          tase_exn "excl 1" "a was mutably borrowed in line 1, cannot borrow"
            "(def a& 10)(defn f [a& b] (set &a !11))(f &a a)";
          tase_exn "excl 2" "a was borrowed in line 1, cannot mutate"
            "(def a& 10)(defn f [a& b] (set &a !11))(let [b a] (f &a b))";
          tase_exn "excl 3" "a was borrowed in line 1, cannot mutate"
            "(def a& 10) (defn f [a b&] (set &b !11))(f a &a)";
          tase_exn "excl 4" "a was borrowed in line 1, cannot mutate"
            "(def a& 10)(defn f [a b&] (set &b !11)) (let [b a] (f b &a))";
          tase "excl 5" "unit" "(def a& 10) (defn f [a b] ()) (f a a)";
          tase_exn "excl 6" "a was mutably borrowed in line 1, cannot borrow"
            "(def a& 10) (defn f [a& b&] ()) (f &a &a)";
          tase_exn "excl env" "a was mutably borrowed in line 4, cannot borrow"
            {|(def a& [10])
(defn set-a [b&]
  (set &a ![11]))
(set-a &a)|};
          tase_exn "follow string literal"
            "Cannot move string literal. Use `copy`"
            "(def c \"aoeu\") (def d c) (def e& !d)";
          tase_exn "move local borrows"
            "Branches have different ownership: owned vs borrowed"
            "(def a [10]) (def c (if true (let [a [10]] a) a))";
          tase_exn "forbid move of cond borrow"
            "Cannot move conditional borrow. Either copy or directly move \
             conditional without borrowing"
            "(defn test [] (def ai [10]) (def bi [11]) (def c (if false ai (if \
             true bi (if true ai bi)))) c)";
          tase_exn "specify mut passing"
            "Specify how rhs expression is passed. Either by move '!' or \
             mutably '&'"
            "(def a& [10]) (def b& a)";
          tase_exn "partially set moved"
            "a was moved in line 2, cannot set a.[0]"
            "(def a& [10])\n(def b {a})\n(set &a.[0] !10)";
          tase_exn "forbid move out of array"
            "Cannot move out of array. Use `copy`"
            "(defn set-moved ()\n\
             (def a& [\"a\" \"b\"])\n\
             (def b a.[0])\n\
             (ignore {b})\n\
             (set &a.[0] !\"!c\"))";
          tase_exn "track moved multi-borrow param"
            "Borrowed parameter s is moved"
            {|(defn test (s&)
  (def a s)
  (def c a)
  (ignore {c}))|};
          tase_exn "move binds individual"
            "thing.value was moved in line 6, cannot use"
            {|(type data {:key (array u8) :value (array u8)})
(type data-container (#empty (#item data)))
(defn hmm (thing&)
  (match thing
    ((#item {:key :value})
     (do (ignore {key}) (ignore {value}) (ignore {value})
         -- (set &thing !#!empty)
         ))
    (#empty ())))
|};
          tase_exn "move binds param" "Borrowed parameter thing is moved"
            {|(type data {:key (array u8) :value (array u8)})
(type data-container (#empty (#item data)))
(defn hmm (thing&)
  (match thing
    ((#item {:key :value})
     (do (ignore {key}) (ignore {value})
         -- (set &thing !#!empty)
         ))
    (#empty ())))
|};
          tase_exn "let pattern name" "key was moved in line 4, cannot use"
            {|(type data {:key (array u8) :value (array u8)})
(defn hmm ()
  (def {:key :value} !{:key "key" :value "value"})
  (ignore {key})
  (ignore {key}))|};
          tase_exn "track module outer toplevel" "Cannot move top level binding"
            "(def a [10]) (module inner (def _ {a}))";
          tase_exn "track vars from inner module"
            "Cannot move top level binding"
            "(module fst (def a [20])) (ignore [fst/a])";
          tase_exn "track vars from inner module use after move"
            "fst/a was moved in line 1, cannot use"
            "(module fst (def a [20])) (ignore [fst/a]) (ignore fst/a.[0])";
          tase_exn "always borrow field"
            "sm.free-hd was borrowed in line 6, cannot mutate"
            {|(type key {:idx int :gen int})
(type t {:slots& (array key) :data& (array int) :free-hd& int :erase& (array int)})

(let [sm& {:slots [] :data [] :free-hd -1 :erase []}
      idx 0
      slot-idx sm.free-hd
      free-key sm.slots.[slot-idx]
      free-hd (copy free-key.idx)
      nextgen (+ free-key.gen 1)]
  (set &sm.slots.[slot-idx] !{:idx :gen nextgen})
  (set &sm.free-hd !free-hd)
  (ignore {:gen nextgen :idx slot-idx}))|};
          case "lambda copy capture" test_excl_lambda_copy_capture;
          case "lambda copy capture nonalloc"
            test_excl_lambda_copy_capture_nonalloc;
          case "lambda not copy capture" test_excl_lambda_not_copy_capture;
          case "fn copy capture" test_excl_fn_copy_capture;
          case "fn not copy capture" test_excl_fn_not_copy_capture;
        ] );
      ( "type decl",
        [
          case "not unique" test_type_decl_not_unique;
          case "open before" test_type_decl_open_before;
        ] );
      ( "module type",
        [
          case "define" test_mtype_define;
          case "no match" test_mtype_no_match;
          case "no match alias" test_mtype_no_match_alias;
          case "no match sign" test_mtype_no_match_sign;
          case "abstracts" test_mtype_abstracts;
        ] );
      ( "functor",
        [
          case "define" test_functor_define;
          case "module type not found" test_functor_module_type_not_found;
          case "direct access" test_functor_direct_access;
          case "checked alias" test_functor_checked_alias;
          case "wrong arity" test_functor_wrong_arity;
          case "wrong module type" test_functor_wrong_module_type;
          case "no var param" test_functor_no_var_param;
          case "apply use" test_functor_apply_use;
          case "abstract param" test_functor_abstract_param;
          case "use param type" test_functor_use_param_type;
          case "poly function" test_functor_poly_function;
          case "poly mismatch" test_functor_poly_mismatch;
          case "check sig" test_functor_check_sig;
          case "check sig param" test_functor_check_param;
          case "check sig concrete" test_functor_check_concrete;
        ] );
      ( "fixed-size array",
        [
          case "lit" test_farray_lit;
          case "nested lit" test_farray_nested_lit;
          case "generalize / instantiate" test_farray_inference;
        ] );
      ( "partial application",
        [
          case "move outer imm" test_partial_move_outer_imm;
          case "move outer delayed" test_partial_move_outer_delayed;
        ] );
    ]
