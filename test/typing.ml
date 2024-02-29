open Alcotest
open Schmulang
open Error

let prelude = {|let + = __addi
let - = __subi
let < = __lessi
let +. = __addf
|}

let prelude_linenum = 4
let ln fmt i = Printf.sprintf fmt (i + prelude_linenum)

let get_type src =
  let src =
    if String.starts_with ~prefix:"signature:" src then src else prelude ^ src
  in
  let open Lexing in
  let lexbuf = from_string src in
  Indent.reset ();
  Parser.prog Indent.insert_ends lexbuf |> Typing.typecheck |> fun t ->
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
  let toplevel = String.concat "\n" code in
  match tl with
  | None -> t expect toplevel
  | Some msg ->
      test_exn msg toplevel;
      let fn = "fun f():\n  " ^ String.concat "\n  " code in
      (* function *)
      t expect fn

let test_const_int () = test "int" "let a = 1\na"
let test_const_neg_int () = test "int" "let a = -1\na"

let test_const_neg_int_wrong () =
  test_exn "In unary - expecting [int or float] but found [bool]"
    "let a = - true"

let test_const_neg_int2 () = test "int" "let a = - 1\na"
let test_const_float () = test "float" "let a = 1.0\na"
let test_const_neg_float () = test "float" "let a = -1.0\na"

let test_const_neg_float_wrong () =
  test_exn "In unary -. expecting [float] but found [bool]" "let a = -. true"

let test_const_neg_float2 () = test "float" "let a = -.1.0\na"
let test_const_bool () = test "bool" "let a = true\na"
let test_const_u8 () = test "u8" "let a = 123u8\na"
let test_const_i32 () = test "i32" "let a = 123i32\na"
let test_const_neg_i32 () = test "i32" "let a = -123i32\na"
let test_const_f32 () = test "f32" "let a = 1.0f32\na"
let test_const_neg_f32 () = test "f32" "let a = -1.0f32\na"
let test_hint_int () = test "int" "let a : int = 1\na"
let test_func_id () = test "('a) -> 'a" "fun (a): copy(a)"
let test_func_id_hint () = test "(int) -> int" "fun (a : int): a"
let test_func_int () = test "(int) -> int" "fun (a): a + 1"
let test_func_bool () = test "(bool) -> int" "fun (a): if a: 1 else: 1"

let test_func_external () =
  test "(int) -> unit" "external func : (int) -> unit\nfunc"

let test_func_1st_class () =
  test "((int) -> 'a, int) -> 'a" "fun (func, arg : int): func(arg)"

let test_func_1st_hint () =
  test "((int) -> unit, int) -> unit" "fun (f : (int) -> unit, arg): f(arg)"

let test_func_1st_stay_general () =
  test "('a, ('a) -> 'b) -> 'b"
    "fun foo(x, f): f(x)\n\
     fun add1(x): x + 1\n\
     let a = foo(1, add1)\n\
     fun boolean(x : bool): x\n\
     let b = foo(true, boolean)\n\
     foo"

let test_func_recursive_if () =
  test "(int) -> unit"
    "external ext : () -> unit\n\
     fun foo(i): if i < 2: ext() else: foo(i - 1)\n\
     foo"

let test_func_generic_return () =
  test "int" "fun apply(f, x): f(x)\nfun add1(x): x + 1\napply(add1, 1)"

let test_func_capture_annot () =
  test "unit"
    "external somefn : () -> int\n\
     fun wrapper(s):\n\
    \  let a = somefn()\n\
    \  fun captured() [a]: a + 1\n\
    \  ()\n"

let test_func_capture_annot_wrong () =
  test_exn "Value a is not captured, cannot copy" "fun somefn () [a]: ()"

let test_record_clear () =
  test "t" "type t = { x : int, y : int }\n{x = 2, y = 2}"

let test_record_false () =
  test_exn "Unbound field z on record t"
    "type t = {x : int, y : int}\n{x = 2, z = 2}"

let test_record_trailing () =
  test "t" "type t = { x : int, y : int }\n{x = 2, y = 2,}"

let test_record_choose () =
  test "t1"
    "type t1 = { x : int, y : int }\n\
     type t2 = { x : int, z : int }\n\
     {x = 2, y = 2}"

let test_record_reorder () =
  test "t" "type t = {x : int, y : int}\n{y = 10, x = 2}"

let test_record_create_if () =
  test "t" "type t = {x : int}\n{x = if true: 1 else: 0}"

let test_record_create_return () =
  test "t" "type t = {x : int}\nfun a(): 10\n{x = a()}"

let test_record_wrong_type () =
  test_exn "In record expression expecting [int] but found [bool]"
    "type t = {x : int}\n{x = true}"

let test_record_wrong_choose () =
  test_exn "In record expression expecting [int] but found [bool]"
    "type t1 = {x : int, y : int}\n\
     type t2 = {x : int, z : int}\n\
     {x = 2, y = true}"

let test_record_field_simple () =
  test "int" "type t = {x :int}\nlet a = {x = 10}\na.x"

let test_record_field_infer () =
  test "(t) -> int" "type t = {x : int}\nfun a: a.x"

let test_record_same_field_infer () =
  test "a" "type a = {x : int}\ntype b = {x : int, y : int}\n{x = 12}"

let test_record_nested_field_infer () =
  test "c"
    "type a = {x :int}\n\
     type b = {x : int}\n\
     type c = { x : int, y : a }\n\
     {x = 12, y = {x = 12}}"

let test_record_nested_field_generic () =
  test "c(b)"
    "type a = {x : int}\n\
     type b = {x : int}\n\
     type c('a) = {x : int, y : 'a}\n\
     {x = 12, y = {x = 12}}"

let test_record_field_no_record () =
  test_exn "Field access of record t expecting [t] but found [int]"
    "type t = {x : int}\nlet a = 10\na.x"

let test_record_field_wrong_record () =
  test_exn "In application expecting ([t1]) -> _ but found ([t2]) -> _"
    "type t1 = {x : int}\n\
     type t2 = {y : int}\n\
     fun foo(a): a.x\n\
     let b = {y = 10}\n\
     foo(b)"

let test_record_update () =
  test "a"
    "type a = {x : int, y : int}\nlet a = {x = 10, y = 20}\n{a with y = 30}"

let test_record_update_poly_same () =
  test "a(int)"
    "type a('a) = {x : 'a, y : int}\nlet a = {x = 10, y = 20}\n{a with x = 20}"

let test_record_update_poly_change () =
  test "a(float)"
    "type a('a) = {x : 'a, y : int}\n\
     let a = {x = 10, y = 20}\n\
     {a with x = 20.0}"

let test_record_update_useless () =
  test_exn "All fields are explicitely updated. Record update is useless"
    "type a = {x : int, y : int}\n\
     let a = {x = 10, y = 20}\n\
     {a with y = 30, x = 10}"

let test_record_update_expr () =
  test "a" "type a = {x : int, y : int}\n{{x = 10, y = 20} with y = 30}"

let test_record_update_wrong_field () =
  test_exn "Unbound field z on a"
    "type a('a) = {x : 'a, y : int}\nlet a = {x = 10, y = 20}\n{a with z = 20}"

let test_record_update_unknown_polymorphic () =
  test "unit"
    {|type record = {x : int, y : int}
fun update(record): {record with x = 10}
ignore(update)|}

let test_annot_concrete () = test "(int) -> bool" "fun foo(x): x < 3\nfoo"

let test_annot_concrete_fail () =
  test_exn
    "Var annotation expecting ([bool]) -> [int] but found ([int]) -> [bool]"
    "let foo : (bool) -> int = fun x: x < 3\nfoo"

let test_annot_mix () = test "('a!) -> 'a" "fun pass(x! : 'b): x\npass"

let test_annot_mix_fail () =
  test_exn "Var annotation expecting (_) -> [int] but found (_) -> ['a]"
    "let pass : ('b) -> int = fun x: copy(x)\npass"

let test_annot_generic () = test "('a!) -> 'a" "fun pass(x! : 'b): x\npass"

let test_annot_generic_fail () =
  test_exn "Var annotation expecting (_) -> ['b] but found (_) -> ['a]"
    "let pass : ('a) -> 'b = fun x: copy(x)\npass"

let test_annot_generic_mut () =
  test "('a&) -> 'a" "fun pass(x& : 'b): copy(x)\npass"

let test_annot_fun_mut_param () =
  test "(int&) -> unit"
    "external f : (int&) -> unit\nlet a : (int&) -> unit = f\na"

let test_annot_generic_fun_mut_param () =
  test "('a&) -> unit"
    "external f : ('a&) -> unit\nlet a : ('a&) -> unit = f\na"

let test_annot_record_simple () =
  test "a" "type a = {x : int}\ntype b = {x : int}\nlet a : a = {x = 12}\na"

let test_annot_record_generic () =
  test "a(bool)"
    "type a('a) = {x : 'a}\ntype b = {x : int}\nlet a : a(bool) = {x = true}\na"

let test_annot_record_generic_multiple () =
  test_exn "Type a expects 2 type parameters"
    "type a('a, 'b) = {x : 'a, y : 'b}\nlet a : a = {x = true}\na"

let test_annot_tuple_simple () =
  test "(int, bool)" "let a : (int, bool) = (1, true)\na"

let test_annot_array_arg_generic () =
  test "array(int)" "fun foo(a! : array('a)): a\nfoo(![10])"

let test_annot_tuple_generic () =
  test "(int, bool)" "fun hmm(a! : (int, 'a)): a\nhmm(!(1, true))"

let test_annot_fixed_size_array () =
  test "array#32(int)" "fun hmm(a! : array#32('a)): a\nhmm(!#32[0])"

let test_annot_fixed_unknown_size_array () =
  test "array#32(int)" "fun hmm(a! : array#?('a)): a\nhmm(!#32[0])"

let test_annot_fixed_unknown_size_array_fn () =
  (* The function is instantiated so the size is not generalized. That's why
     there are two question marks. *)
  test "(array#??('a)!) -> array#??('a)" "fun hmm(a! : array#?('a)): a\nhmm"

let test_sequence () =
  test "int" "external printi : (int) -> unit\nprinti(20)\n1 + 1"

let test_sequence_fail () =
  test_exn
    "Left expression in sequence must be of type unit,\n\
     expecting [unit]\n\
     but found [int]" "fun add1(x): x + 1\nadd1(20)\n1 + 1"

let test_para_instantiate () =
  test "foo(int)"
    "type foo('a) = {first : int, gen : 'a}\n\
     let foo = {first = 10, gen = 20}\n\
     foo"

let test_para_gen_fun () =
  test "(foo('a)) -> int"
    "type foo('a) = {gen : 'a, second : int}\n\
     fun get(foo): copy(foo.second)\n\
     get"

let test_para_gen_return () =
  test "(foo('a)!) -> 'a"
    "type foo('a) = {gen : 'a}\nfun get(foo!): foo.gen\nget"

let test_para_multiple () =
  test "bool"
    "type foo('a) = {gen : 'a}\n\
     fun get(foo): copy(foo.gen)\n\
     let a = {gen = 12}\n\
     let b : int = get(a)\n\
     let c = {gen = false}\n\
     get(c)"

let test_para_instance_func () =
  test "(foo(int)) -> int"
    "type foo('a) = {gen : 'a}\n\
     fun apply(foo): foo.gen + 17\n\
     let foo = {gen = 17}\n\
     apply"

let test_para_instance_wrong_func () =
  test_exn "In record expression expecting [int] but found [bool]"
    "type foo('a) = {gen : 'a}\n\
     fun apply(foo): foo.gen + 17\n\
     let foo = {gen = 17}\n\
     apply({gen = true})"

let test_pipe_head_single () = test "int" "fun add1(a): a + 1\n10.add1()"

let test_pipe_head_multi_call () =
  test "int" "fun add1(a): a + 1\n10.add1().add1()"

let test_pipe_head_single_wrong_type () =
  test_exn "In application expecting [(int) -> 'a] but found [int]"
    "let add1 = 1\n10.add1()"

let test_pipe_head_mult () = test "int" "fun add(a, b): a + b\n10.add(12)"

let test_pipe_head_mult_wrong_type () =
  test_exn "In application expecting ([int, int]) -> _ but found ([int]) -> _"
    "fun add1(a): a + 1\n10.add1(12)"

let test_pipe_tail_single () = test "int" "fun add1(a): a + 1\n10 |> add1"

let test_pipe_tail_single_call () =
  test "int" "fun add1(a): a + 1\n10 |> add1()"

let test_pipe_tail_single_wrong_type () =
  test_exn "In application expecting [(int) -> 'a] but found [int]"
    "let add1 = 1\n10 |> add1"

let test_pipe_tail_mult () = test "int" "fun add(a, b): a + b\n10 |> add(12)"

let test_pipe_tail_mult_wrong_type () =
  test_exn "In application expecting ([int, int]) -> _ but found ([int]) -> _"
    "fun add1(a): a + 1\n10 |> add1(12)"

let test_alias_simple () =
  test "(foo = int) -> unit" "type foo = int\nexternal f : (foo) -> unit\nf"

let test_alias_param_concrete () =
  test "(foo = raw_ptr(u8)) -> unit"
    "type foo = raw_ptr(u8)\nexternal f : (foo) -> unit\nf"

let test_alias_param_quant () =
  test "(foo = raw_ptr('a)) -> unit"
    "type foo('a) = raw_ptr('a)\nexternal f : (foo('a)) -> unit\nf"

let test_alias_param_missing () =
  test_exn "Type foo expects 1 type parameter"
    "type foo('a) = raw_ptr('a)\nexternal f : (foo) -> unit\nf"

let test_alias_of_alias () =
  test "(bar = int) -> foo = int"
    "type foo = int\ntype bar = foo\nexternal f : (bar) -> foo\nf"

let test_alias_labels () =
  test "inner/t(int)"
    {|module inner:
  type t('a) = {a : 'a, b : int}
type t('a) = inner/t('a)
{a = 20, b = 10}
|}

let test_alias_ctors () =
  test "inner/t(int)"
    {|module inner:
  type t('a) = #noo | #yes('a)
type t('a) = inner/t('a)
#yes(10)|}

let test_alias_ctors_dont_overwrite () =
  test "(option(item('a))) -> option('a)"
    {|type option('a) = #some('a) | #none
type item('a) = {value : 'a}
type slot('a) = option(item('a))

fun get_item(slot):
    match slot:
      #some(item): #some(copy(item.value))
      #none: #none
get_item|}

let test_array_lit () = test "array(int)" "[0, 1]"
let test_array_lit_trailing () = test "array(int)" "[0, 1,]"

let test_array_var () = test "array(int)" {|let a = [0, 1]
a|}

let test_array_weak () =
  test "array(int)"
    {|external setf : (array('a), 'a) -> unit
let a = []
setf(a, 2)
a|}

let test_array_different_types () =
  test_exn "In array literal expecting [int] but found [bool]" "[0, true]"

let test_array_different_annot () =
  test_exn "In let binding expecting array([int]) but found array([bool])"
    "let a : array(bool) = [0, 1]\na"

let test_array_different_annot_weak () =
  test_exn "In application expecting (_, [bool]) -> _ but found (_, [int]) -> _"
    "external setf : (array('a), 'a) -> unit\n\
     let a : array(bool) = []\n\
     setf(a, 2)"

let test_array_different_weak () =
  test_exn "In application expecting (_, [int]) -> _ but found (_, [bool]) -> _"
    {|external setf : (array('a), 'a) -> unit
let a = []
setf(a, 2)
setf(a, true)|}

let test_mutable_declare () = test "int" "type foo = { x& : int }\n0"

let test_mutable_set () =
  test "unit" "type foo = { x& : int }\nlet foo& = {x = 12}\n&foo.x <- 13"

let test_mutable_set_wrong_type () =
  test_exn "In mutation expecting [int] but found [bool]"
    "type foo = {x& : int}\nlet foo& = {x = 12}\n&foo.x <- true"

let test_mutable_set_non_mut () =
  test_exn "Cannot mutate non-mutable binding"
    "type foo = {x : int}\nlet foo = {x = 12}\n&foo.x <- 13"

let test_mutable_value () = test "int" "let b& = 10\n&b <- 14\nb"

let test_mutable_nonmut_value () =
  test_exn "Cannot mutate non-mutable binding" "let b = 10\n&b <- 14\nb"

let test_mutable_nonmut_transitive () =
  test_exn "Cannot mutate non-mutable binding"
    "type foo = { x& : int }\nlet foo = {x = 12}\n&foo.x <- 13"

let test_mutable_nonmut_transitive_inv () =
  test_exn "Cannot mutate non-mutable binding"
    "type foo = {x : int}\nlet foo& = {x = 12}\n&foo.x <- 13"

let test_mutable_track_ptr_nonmut () =
  test_exn "Cannot project immutable binding"
    "type thing = { ptr : raw_ptr(u8) }\n\
     do:\n\
    \  let thing = { ptr = __unsafe_nullptr() }\n\
    \  let proj& = &(__unsafe_ptr_get(thing.ptr, 0))\n\
    \  0"

let test_mutable_track_ptr_mut () =
  test "int"
    "type thing = { ptr& : raw_ptr(u8) }\n\
     do:\n\
    \  let thing& = { ptr = __unsafe_nullptr() }\n\
    \  let proj& = &(__unsafe_ptr_get(thing.ptr, 0))\n\
    \  0"

let test_variants_option_none () =
  test_exn "Expression contains weak type variables: option('a)"
    "type option('a) = #none | #some('a)\n#none"

let test_variants_option_some () =
  test "option(int)" "type option('a) = #none | #some('a)\n#some(1)"

let test_variants_option_some_some () =
  test "option(option(float))"
    "type option('a) = #none | #some('a)\nlet a = #some(1.0)\n#some(copy(a))"

let test_variants_option_annot () =
  test "option(option(float))"
    "type option('a) = #none | #some('a)\n\
     let a : option(float) = #none\n\
     #some(a)"

let test_variants_option_none_arg () =
  test_exn
    "The constructor none expects 0 arguments, but an argument is provided"
    "type option('a) = #none | #some('a)\n#none(1)"

let test_variants_option_some_arg () =
  test_exn "The constructor some expects arguments, but none are provided"
    "type option('a) = #none | #some('a)\n#some"

let test_variants_correct_inference () =
  test "unit"
    {|type view = {start : int, len : int}
type success('a) = {rem : view, mtch : int}
type parse_result('a) = #ok(success('a)) | #err(view)
fun map(p, f, buf, view):
  match p(buf, view):
    #ok(ok): #ok({ok with mtch = f(ok.mtch)})
    #err(view): #err(view)
|}

let test_lor_clike_variant () = test "int" "type clike = #a | #b\n#b.lor(#a)"

let test_lor_other_variant () =
  test_exn "Expecting int, not a variant type"
    "type clike = #a(int) | #b\n#b.lor(#a)"

let test_match_all () =
  test "int"
    "type option('a) = #none | #some('a)\n\
     match #some(1): #some(a): a | #none: -1"

let test_match_redundant () =
  test_exn "Pattern match case is redundant"
    "type option('a) = #none | #some('a)\nmatch #some(1): a: a | #none: -1"

let test_match_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: #some"
    "type option('a) = #none | #some('a)\nmatch #some(1): #none: -1"

let test_match_missing_nested () =
  test_exn
    "Pattern match is not exhaustive. Missing cases: #some(#int) | #some(#non)"
    {|type option('a) = #none | #some('a)
type test = #float(float) | #int(int) | #non
match #none:
  #some(#float(f)): f.int_of_float()
  -- #some(#int(i))
  -- #some #non
  #none: 0
|}

let test_match_all_after_ctor () =
  test "int"
    {|type option('a) = #none | #some('a)
match #some(1): #none: -1 | a: 0|}

let test_match_all_before_ctor () =
  test_exn "Pattern match case is redundant"
    {|type option('a) = #none | #some('a)
match #some(1): a: 0 | #none: -1|}

let test_match_redundant_all_cases () =
  test_exn "Pattern match case is redundant"
    {|type option('a) = #none | #some('a)
type test = #float(float) | #int(int) | #non
match #none:
  #some(#float(f)): f.int_of_float()
  #some(#int(i)): i
  #some(#non): 1
  #none: 0
  a: -1
|}

let test_match_wildcard () =
  test_exn "Pattern match case is redundant"
    {|type option('a) = #none | #some('a)
match #some(1): _: 0 | #none: -1|}

let test_match_wildcard_nested () =
  test_exn "Pattern match case is redundant"
    {|type option('a) = #none | #some('a)
type test = #float(float) | #int(int) | #non
match #none:
  #some(#float(f)): f.int_of_float()
  #some(_): -2
  #some(#non): 1
  #none: 0
|}

let test_match_column_arity () =
  test_exn
    "Tuple pattern has unexpected type:\n\
     expecting [(int, int)]\n\
     but found [('a, 'b, 'c)]"
    {|type option('a) = #none | #some('a)
match (1, 2):
  (a, b, c): a
|}

let test_match_record () =
  test "int"
    {|type option('a) = #none | #some('a)
type foo = {a : int, b : float}
match #some({a = 12, b = 53.0}):
  #some({a, b}): a
  #none: 0
|}

let test_match_record_field_missing () =
  test_exn "There are missing fields in record pattern, for instance b"
    {|type option('a) = #none | #some('a)
type foo = {a : int, b : float}
match #some({a = 12, b = 53.0}):
  #some({a}): a
  #none: 0
|}

let test_match_record_field_twice () =
  test_exn "Field a appears multiple times in record pattern"
    {|type option('a) = #none | #some('a)
type foo = {a : int, b : float}
match #some({a = 12, b = 53.0}):
  #some({a, a}): a
  #none: 0
|}

let test_match_record_field_wrong () =
  test_exn "Unbound field c on record foo"
    {|type option('a) = #none | #some('a)
type foo = {a : int, b : float}
match #some({a = 12, b = 53.0}):
  #some({a, c}): a
  #none: 0
|}

let test_match_record_case_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: #some(#none)"
    {|
type option('a) = #none | #some('a)
type foo('a) = {a : 'a, b : float}
match #some({a = #some(2), b = 53.0}):
  #some({a = #some(a), b}): a
  #none: 0|}

let test_match_int () =
  test "int"
    {|type option('a) = #none | #some('a)
match #some(10): #some(1): 1 | #some(10): 10 | #some(_): 0 | #none: -1
|}

let test_match_int_wildcard_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: "
    {|type option('a) = #none | #some('a)
match #some(10): #some(1): 1 | #some(10): 10 | #none: -1|}

let test_match_int_twice () =
  test_exn "Pattern match case is redundant"
    {|
type option('a) = #none | #some('a)
match #some(10): #some(1): 1 | #some(10): 10 | #some(10): 10 | #some(_): 0 | #none: -1
|}

let test_match_int_after_catchall () =
  test_exn "Pattern match case is redundant"
    {|
type option('a) = #none | #some('a)
match #some(10): #some(1): 1 | #some(_): 10 | #some(10): 10 | #none: -1
|}

let test_match_or () = test "int" "match (1, 2): (a, 1) | (a, 2): a | _: -1"

let test_match_or_missing_var () =
  test_exn "No var named a" "match (1, 2): (a, 1) | (b, 2): a | _: -1"

let test_match_or_redundant () =
  test_exn "Pattern match case is redundant"
    "match (1, 2): (a, 1) | (a, 2) | (a, 1): a | _: -1"

let test_multi_record2 () =
  test "foo(int, bool)"
    "type foo('a, 'b) = {a : 'a, b : 'b}\n{a = 0, b = false}"

let test_multi_variant2 () =
  test_exn "Expression contains weak type variables: foo(int, 'a)"
    "type foo('a, 'b) = #some('a) | #other('b)\n#some(1)"

let test_tuple () = test "(int, float)" "( 1, 2.0 )"
let test_pattern_decl_var () = test "int" "let a = 123\na"
let test_pattern_decl_wildcard () = test "int" "let _ = 123\n0"

let test_pattern_decl_record () =
  test "float"
    "type foo = {i : int, f : float}\nlet {i, f} = {i = 12, f = 5.0}\nf"

let test_pattern_decl_record_wrong_field () =
  test_exn "Unbound field y on record foo"
    "type foo = {i : int, f : float}\nlet {y, f} = {i = 12, f = 5.0}\nf"

let test_pattern_decl_record_missing () =
  test_exn "There are missing fields in record pattern, for instance i"
    "type foo = {i : int, f : float}\nlet {f} = {i = 12, f = 5.0}\nf"

let test_pattern_decl_tuple () = test "float" "let i, f = (12, 5.0)\nf"

let test_pattern_decl_tuple_missing () =
  test_exn
    "Tuple pattern has unexpected type:\n\
     expecting [(int, float, int)]\n\
     but found [('a, 'b)]" "let x, f = (12, 5.0, 20)\nf"

let test_pattern_decl_wildcard_move () =
  test "('a, 'b!) -> unit" "fun func(_, _!): ()\nfunc"

let test_pattern_decl_tuple_move () =
  test "('a, ('b, 'c)!) -> unit" "fun func(_, (a, b)!): ()\nfunc"

let test_signature_only () = test "unit" "signature:\n  type t = int\n"

let test_signature_simple () =
  test "unit" "signature:\n  type t = int\ntype t = int"

let test_signature_wrong_typedef () =
  test_exn
    "Mismatch between implementation and signature\n\
     expecting [t = int]\n\
     but found [t = float]" {|signature:
  type t = int
type t = float|}

let test_signature_generic () =
  test "unit"
    {|signature:
  type t('a)
  val create : ('a!) -> t('a)
  val create_int : (int) -> t(int)

type t('a) = {x : 'a}

fun create(x!): {x}
fun create_int(x : int): {x}|}

let test_signature_param_mismatch () =
  test_exn
    "Mismatch between implementation and signature\n\
     expecting (_) -> [t(int)]\n\
     but found (_) -> [t('a)]"
    {|signature:
  type t('a)
  val create_int : (int) -> t(int)
type t('a) = {x : int}
fun create_int(x : int): {x}|}

let test_signature_unparam_type () =
  test_exn "Primitive type has no type parameter"
    {|signature:
  type t('a)
type t('a) = int|}

let local_module =
  {|type t = float
type global = int
module nosig:
  type t = {a : int}
  type other = int
  module nested:
    type t = u8
|}

let test_local_modules_find_local () =
  test "unit" (local_module ^ "let test : nosig/t = { a = 10 }")

let test_local_modules_find_nested () =
  test "unit" (local_module ^ "let test : nosig/nested/t = 0u8")

let test_local_modules_miss_local () =
  test_exn "In let binding expecting [float] but found [nosig/t]"
    (local_module ^ "let test : nosig/t = 10.0")

let test_local_modules_miss_nested () =
  test_exn "Expected a record type, not nosig/nested/t = u8"
    (local_module ^ "let test : nosig/nested/t = {a = 10}")

let test_local_modules_miss_local_dont_find_global () =
  test_exn "Unbound type nosig/global."
    (local_module ^ "let test : nosig/global = { a = 10 }")

let test_local_module_unique_names () =
  test_exn "Module names must be unique. nosig exists already"
    (local_module ^ "module nosig:\n   type t = int")

let test_local_module_nested_module_alias () =
  test "nosig/nested/t"
    {|module nosig:
  type t = { a : int, b : int }
  let _ = { a = 10, b = 20 }
  module nested:
    type t = {a : int, b : int, c : int}
    let t = {a = 10, b = 20, c = 30}
module mm = nosig/nested
nosig/nested/t|}

let test_local_module_alias_dont () =
  test_exn "Cannot find module: nested in nosig/nested"
    {|
-- this shouln't be found
module nested:
  type t = {a : int, b : int, c : int}
  let t = { a = 11, b = 21, c = 31 }

module nosig:
  type t = {a : int, b : int}
  let _ = {a = 10, b = 20}
  module notnested:
    type t = {a : int, b : int, c : int}
    let t = {a = 10, b = 20, c = 30}

module mm = nosig/nested
|}

let own = "let x& = 10"
let tl = Some "Cannot borrow mutable binding at top level"

let test_excl_borrow () =
  wrap_fn ~tl test "unit" [ own; "let y = x"; "ignore(x)"; "ignore(y)" ]

let test_excl_borrow_use_early () =
  wrap_fn ~tl test_exn
    (ln "x was borrowed in line %i, cannot mutate" 3)
    [ own; "let y = x"; "ignore(x)"; "&x <- 11"; "ignore(y)" ]

let tl = Some "Cannot move top level binding"

let test_excl_move_mut () =
  wrap_fn ~tl test "unit" [ own; "let y& = !x"; "&y <- 11"; "ignore(y)" ]

let test_excl_move_mut_use_after () =
  wrap_fn test_exn
    (ln "x was moved in line %i, cannot use" 2)
    [ own; "let y& = !x"; "ignore(x)" ]

let test_excl_move_record () =
  wrap_fn test "unit" [ own; "let y = (x, 0)"; "ignore(y)" ]

let test_excl_move_record_use_after () =
  wrap_fn test_exn
    (ln "x was moved in line %i, cannot use" 2)
    [ "let x& =[10]"; "let y = (x, 0)"; "ignore(x)" ]

let test_excl_borrow_then_move () =
  wrap_fn test_exn
    (ln "x was moved in line %i, cannot use" 3)
    [ "let x = [10]"; "let y = x"; "ignore((y, 0))"; "x" ]

let test_excl_if_move_lit () =
  wrap_fn ~tl test "unit"
    [ "let x = 10"; "let y& = !if true: x else: 10"; "ignore(y)" ]

let test_excl_if_borrow_borrow () =
  wrap_fn test "unit"
    [ "let x = 10"; "let y = 10"; "ignore(if true: x else: y)" ]

let test_excl_if_lit_borrow () =
  wrap_fn test_exn "Branches have different ownership: owned vs borrowed"
    [ "let x = [10]"; "ignore(if true: [10] else: x)" ]

let proj_msg = Some "Cannot project at top level"

let test_excl_proj () =
  wrap_fn ~tl:proj_msg test "unit"
    [ own; "let y& = &x"; "&y <- 11"; "ignore(x)" ]

let test_excl_proj_immutable () =
  wrap_fn ~tl:proj_msg test_exn "Cannot project immutable binding"
    [ "let x = 10"; "let y& = &x"; "x" ]

let test_excl_proj_use_orig () =
  wrap_fn ~tl:proj_msg test_exn
    (ln "x was mutably borrowed in line %i, cannot borrow" 3)
    [ own; "let y& = &x"; "ignore(x)"; "ignore(y)"; "x" ]

let test_excl_proj_move_after () =
  wrap_fn ~tl:proj_msg test_exn
    (ln "x was mutably borrowed in line %i, cannot borrow" 3)
    [ own; "let y& = &x"; "ignore(x)"; "(y, 0)" ]

let test_excl_proj_nest () =
  wrap_fn ~tl:proj_msg test_exn
    (ln "x was mutably borrowed as y in line %i, cannot borrow" 4)
    [ own; "let y& = &x"; "let z& = &y"; "ignore(y)"; "z" ]

let test_excl_proj_nest_orig () =
  wrap_fn ~tl:proj_msg test_exn
    (ln "x was mutably borrowed in line %i, cannot borrow" 4)
    [ own; "let y& = &x"; "let z& = &y"; "ignore(x)"; "z" ]

let test_excl_proj_nest_closed () =
  wrap_fn ~tl:proj_msg test "unit"
    [ own; "let y& = &x"; "let z& = &y"; "ignore(z)"; "y" ]

let test_excl_moved_param () =
  test_exn "Borrowed parameter x is moved" "fun meh(x): x"

let test_excl_set_moved () =
  test "unit" "fun meh(a&):\n  ignore((a, 0))\n  &a <- 10"

let test_excl_binds () =
  test "unit"
    {|type ease_kind = #linear | #circ_in

fun ease_circ_in(_): 0.0
fun ease_linear(_): 0.0

fun ease(anim): match anim:
  #linear: ease_linear(anim)
  #circ_in: ease_circ_in(anim)|}

let test_excl_shadowing () =
  test_exn "Borrowed parameter a is moved" "fun thing(a):\n  let a = a\n  a"

let typ = "type string = array(u8)\ntype t = {a : string, b : string}\n"

let test_excl_parts_success () =
  test "unit" (typ ^ "fun meh(a!): {a = a.a, b = a.b}")

let test_excl_parts_return_part () =
  test "unit" (typ ^ "fun meh(a!):\n let c& = !a.a\n a.b")

let test_excl_parts_return_whole () =
  test_exn
    (ln "a.a was moved in line %i, cannot use" 4)
    (typ ^ "fun meh(a!):\n let c& = !a.a\n a")

let test_excl_lambda_copy_capture () =
  test "unit" "fun alt(alts): fun () [alts]: ignore(alts.[0])"

let test_excl_lambda_copy_capture_nonalloc () =
  test "unit" "fun alt(alts): fun () [alts]: ignore(1 + alts)"

let test_excl_lambda_not_copy_capture () =
  test_exn "Borrowed parameter alts is moved"
    "fun alt(alts): fun (): ignore(alts.[0])"

let test_excl_fn_copy_capture () =
  test "unit" "fun alt(alts):\n fun named() [alts]:\n  ignore(alts.[0])\n named"

let test_excl_fn_not_copy_capture () =
  test_exn "Borrowed parameter alts is moved"
    "fun alt(alts):\n fun named():\n  ignore(alts.[0])\n named"

let test_excl_partial_move_reset () =
  test_exn "Cannot move top level binding"
    {|type tt = {a& : array(int), b & : array(int)}
let a& = {a = [], b = []}
let _ = !a.a
let _ = !a.b
&a.b <- []|}

let test_excl_projections_partial_moves () =
  test "array(int)"
    {|type t = {a& : array(int), b& : array(int)}
let a& = {a = [], b = []}
do:
  let a& = &a
  let tmp = !a.a
  let tmp2 = !a.b
  &a.a <- tmp2
  &a.b <- tmp
  ignore(a.a)
  a.a|}

let test_excl_array_move_const () =
  test "unit" {|let a& = [0]
let _ = !a.[1]
&a.[1] <- 1|}

let test_excl_array_move_var () =
  test "unit" {|let a& = [0]
let index = 1
let _ = !a.[index]
&a.[index] <- 1|}

let test_excl_array_move_mixed () =
  test_exn "Cannot move out of array without re-setting"
    {|let a& = [0]
let index = 1
let _ = !a.[1]
&a.[index] <- 1|}

let test_excl_array_move_wrong_index () =
  test_exn "Cannot move out of array with this index"
    {|let a& = [0]
fun index(): 1
let _ = !a.[index()]
&a.[index()] <- 1|}

let test_excl_array_move_dyn_index () =
  test_exn "Cannot move out of array without re-setting"
    {|let a& = [0]
do:
  let tmp = !a.[0]
  &a.[0 + 0] <- 0|}

let test_type_decl_not_unique () =
  test_exn "Type names in a module must be unique. t exists already"
    "type t = int\ntype t = float"

let test_type_decl_use_before () =
  test "unit" "module m:\n  type t = int\nuse m\ntype t = float"

let test_mtype_define () =
  test "unit" {|module type tt:
  type t
  val random : () -> int|}

let test_mtype_no_match () =
  test_exn "Signatures don't match: Type test/t is missing"
    {|
module type tt:
  type t

module test : tt:
  type a = unit
|}

let test_mtype_no_match_alias () =
  test_exn "Signatures don't match: Type test/t is missing"
    {|module type tt:
  type t

module test:
  type a = unit

module other : tt = test
|}

let test_mtype_no_match_sign () =
  test_exn "Signatures don't match: Type test/t is missing"
    {|module type tt:
  type t
module test : tt:
  signature:
    type a
  type a = unit|}

let test_mtype_abstracts () =
  test "unit"
    {|module outer:
  type t = {i : int}

module type sig:
  type t
  val add : (t, t) -> t

functor make(m : sig):
  fun add_twice(a, b):
    m/add(m/add(a, b), b)

module outa : sig:
  type t = outer/t
  fun add(a, b): {i = a.i + b.i}

module inta : sig:
  type t = int
  fun add(a, b): a + b

module floata : sig:
  signature:
    type t
    val add : (t, t) -> t
  type t = float
  fun add(a, b): a +. b

module somerec : sig:
  type t = {a : int, b : int}
  fun add(a, b): {a = a.a + a.b, b = a.b + b.b}
|}

let test_functor_define () =
  test "unit" "module type mt:\n type t\nfunctor f(p : mt):\n ()"

let test_functor_module_type_not_found () =
  test_exn "Cannot find module type mt" "functor f(p : mt):\n ()"

let test_functor_direct_access () =
  test_exn "The module f is a functor. It cannot be accessed directly"
    "module type mt:\n type t\nfunctor f(p : mt):\n type a = unit\nignore(f/a)"

let test_functor_checked_alias () =
  test_exn "The module f is a functor. It cannot be accessed directly"
    "module type mt:\n\
    \ type t\n\
     functor f(p : mt):\n\
    \ type a = unit\n\
     module hmm : mt = f"

let test_functor_wrong_arity () =
  test_exn "Wrong arity for functor f: Expecting 1 but got 2"
    "module type mt:\n\
    \ type t\n\
     functor f(p : mt):\n\
    \ ()\n\
     module a:\n\
    \ type t = unit\n\
     module hmm = f(a, a)"

let test_functor_wrong_module_type () =
  test_exn "Signatures don't match: Type a/t is missing"
    "module type mt:\n\
    \ type t\n\
     functor f(p : mt):\n\
    \ ()\n\
     module a:\n\
    \ ()\n\
     module hmm = f(a)"

let test_functor_no_var_param () =
  test_exn "No var named p/a"
    "module type mt:\n type t\nfunctor f(p : mt):\n let _ = ignore(p/a)"

let test_functor_apply_use () =
  test "inta/t = int"
    {|module type sig:
  type t
  val add : (t, t) -> t
functor make(m : sig):
  fun add_twice(a, b):
    m/add(m/add(a, b), b)
module inta : sig:
  type t = int
  fun add(a, b): a + b
module intadder = make(inta)
intadder/add_twice(1, 2)|}

let test_functor_abstract_param () =
  test_exn
    "In application\n\
     expecting ([inta/t], [inta/t]) -> _\n\
     but found ([int], [int]) -> _"
    {|module type sig:
  type t
  val add : (t, t) -> t

functor make(m : sig):
  fun add_twice(a, b): m/add(m/add(a, b), b)

module inta : sig:
  signature:
    type t
    val add : (t, t) -> t
  type t = int
  fun add(a, b): a + b

module intadder = make(inta)
intadder/add_twice(1, 2)|}

let test_functor_use_param_type () =
  test "unit"
    {|module type sig:
  type t

functor make(m : sig):
  type t = m/t|}

let test_functor_poly_function () =
  test "unit"
    {|
module type poly:
  val id : ('a!) -> 'a

functor makeid(m : poly):
  fun newid(p!): m/id(!p)

module some:
  fun id(p!): p

module polyappl = makeid(some)

ignore(polyappl/newid(!1))
ignore(polyappl/newid(!1.2))|}

let test_functor_poly_mismatch () =
  test_exn
    "Signatures don't match for id\n\
     expecting (['a]!) -> ['a]\n\
     but found ([int]!) -> [int]"
    {|module type poly:
  val id : ('a!) -> 'a

functor makeid(m : poly):
  fun newid(p!): m/id(!p)

module someint:
  fun id(p! : int): p

module intappl = makeid(someint)|}

(* Copied from hashtbl *)
let check_sig_test thing =
  {|module type key:
  type t

module type sig:
  type key
  type t('value)

  val create : (int) -> t(|}
  ^ thing
  ^ {|)
functor make : sig (m : key):
  type key = m/t
  type item('a) = {key : m/t, value : 'a}
  type slot('a) = #empty | #tombstone | #item(item('a))
  type t('a) = {data& : array(slot('a)), nitems& : int}

  fun create(size : int):
    ignore(size)
    let data = []
    {data, nitems = 0}|}

let test_functor_check_sig () = test "unit" (check_sig_test "'value")

let test_functor_check_param () =
  test_exn
    "Signatures don't match for create\n\
     expecting (_) -> [sig/t(sig/key)]\n\
     but found (_) -> [make/t('a)]" (check_sig_test "key")

let test_functor_check_concrete () =
  test_exn
    "Signatures don't match for create\n\
     expecting (_) -> [sig/t(int)]\n\
     but found (_) -> [make/t('a)]" (check_sig_test "int")

let test_farray_lit () = test "unit" "let arr = #[1, 2, 3]"
let test_farray_lit_trailing () = test "unit" "let arr = #[1, 2, 3,]"

let test_farray_nested_lit () =
  test "unit" "let arr = #[#[1, 2, 3], #[3, 4, 5]]"

let test_farray_inference () =
  test "unit"
    "fun print_snd(arr):\n\
    \ ignore(fmt(arr#[1]))\n\
     print_snd(#[1, 2, 3])\n\
     print_snd(#[\"hey\", \"hi\"])"

let test_partial_move_outer_imm () =
  test_exn "Cannot move string literal. Use `copy`"
    "(def a \"hii\") (defn move-a (_ a!) a) (ignore ((move-a 0) !a))"

let test_partial_move_outer_delayed () =
  test_exn "Cannot move string literal. Use `copy`"
    "(def a \"hii\") (defn move-a (a! _) a) (ignore ((move-a !a) 0))"

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
          case "id hint" test_func_id_hint;
          case "int" test_func_int;
          case "bool" test_func_bool;
          case "ext" test_func_external;
          case "1st class" test_func_1st_class;
          case "1st hint" test_func_1st_hint;
          case "1st stay gen" test_func_1st_stay_general;
          case "recursive if" test_func_recursive_if;
          case "generic return" test_func_generic_return;
          case "capture annot" test_func_capture_annot;
          case "capture annot wrong" test_func_capture_annot_wrong;
        ] );
      ( "records",
        [
          case "clear" test_record_clear;
          case "false" test_record_false;
          case "trailing" test_record_trailing;
          case "choose" test_record_choose;
          case "reorder" test_record_reorder;
          case "create if" test_record_create_if;
          case "create return" test_record_create_return;
          case "wrong type" test_record_wrong_type;
          case "wrong choose" test_record_wrong_choose;
          case "field simple" test_record_field_simple;
          case "field infer" test_record_field_infer;
          case "same field_infer" test_record_same_field_infer;
          case "nested field infer" test_record_nested_field_infer;
          case "nested field infer generic" test_record_nested_field_generic;
          case "field no record" test_record_field_no_record;
          case "field wrong record" test_record_field_wrong_record;
          case "update" test_record_update;
          case "update poly" test_record_update_poly_same;
          case "update poly_change" test_record_update_poly_change;
          case "update useless" test_record_update_useless;
          case "update expr" test_record_update_expr;
          case "update wrong field" test_record_update_wrong_field;
          case "update unknown polymorphic"
            test_record_update_unknown_polymorphic;
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
          case "record_multiple" test_annot_record_generic_multiple;
          case "tuple simple" test_annot_tuple_simple;
          case "array arg generic" test_annot_array_arg_generic;
          case "tuple generic" test_annot_tuple_generic;
          case "fixed-size array" test_annot_fixed_size_array;
          case "fixed-size unknown array" test_annot_fixed_unknown_size_array;
          case "fixed-size unknown array fn"
            test_annot_fixed_unknown_size_array_fn;
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
          case "usable ctors dont overwrite" test_alias_ctors_dont_overwrite;
        ] );
      ( "array",
        [
          case "literal" test_array_lit;
          case "literal trailing" test_array_lit_trailing;
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
          case "ptr track mutability" test_mutable_track_ptr_nonmut;
          case "ptr track mutability correct" test_mutable_track_ptr_mut;
        ] );
      ( "variants",
        [
          case "option_none" test_variants_option_none;
          case "option_some" test_variants_option_some;
          case "option_some_some" test_variants_option_some_some;
          case "option_annot" test_variants_option_annot;
          case "option_none_arg" test_variants_option_none_arg;
          case "option_some_arg" test_variants_option_some_arg;
          case "correct inference" test_variants_correct_inference;
          case "lor clike variant" test_lor_clike_variant;
          case "lor other variant" test_lor_other_variant;
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
      ("tuples", [ case "tuple" test_tuple ]);
      ( "pattern decl",
        [
          case "var" test_pattern_decl_var;
          case "wildcard" test_pattern_decl_wildcard;
          case "record" test_pattern_decl_record;
          case "record wrong field" test_pattern_decl_record_wrong_field;
          case "record missing" test_pattern_decl_record_missing;
          case "tuple" test_pattern_decl_tuple;
          case "tuple missing" test_pattern_decl_tuple_missing;
          case "wildcard move" test_pattern_decl_wildcard_move;
          case "tuple move" test_pattern_decl_tuple_move;
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
          tase_exn "func mut borrow"
            (ln "a was borrowed in line %i, cannot mutate" 5)
            {|let a& = 10
fun set_a():
  &a <- 11
do:
  let b = a
  set_a()
  ignore(b)|};
          tase_exn "func move" "Cannot move value a from outer scope"
            {|fun hmm():
  let a& = [10]
  fun move_a(): a
  ignore(a)
  ignore(move_a)
  ignore(a)|};
          tase_exn "closure mut borrow"
            (ln "a was mutably borrowed in line %i, cannot borrow" 3)
            {|fun hmm():
  let a& = 10
  let set_a = fun (): &a <- 11
  &a <- 11
  set_a()
  &a <- 11|};
          tase_exn "closure carry set"
            (ln "a was mutably borrowed in line %i, cannot borrow" 3)
            (* If the 'set' attribute isn't carried, (set-a) cannot be called
               and a different error occurs *)
            {|fun hmm():
  let a& = [10]
  let set_a = fun (): &a <- [11]
  &a <- [11]
  let x& = !a
  set_a()|};
          tase_exn "excl 1"
            (ln "a was mutably borrowed in line %i, cannot borrow" 4)
            "let a& = [10]\nfun f(a&, b):\n &a <- [11]\nf(&a, a)";
          tase "excl 1 nonalloc" "unit"
            "let a& = 10\nfun f(a&, b): &a <- 11\nf(&a, a)";
          tase_exn "excl 2"
            (ln "a was borrowed in line %i, cannot mutate" 4)
            "let a& = [10]\n\
             fun f(a&, b): &a <- [11]\n\
             do:\n\
            \ let b = a\n\
            \ f(&a, b)";
          tase_exn "excl 3"
            (ln "a was borrowed in line %i, cannot mutate" 3)
            "let a& = [10]\nfun f(a, b&): &b <- [11]\nf(a, &a)";
          tase_exn "excl 4"
            (ln "a was borrowed in line %i, cannot mutate" 5)
            "let a& = [10]\n\
             fun f(a, b&): &b <- [11]\n\
             do:\n\
            \ let b = a\n\
            \ f(b, &a)";
          tase "excl 5" "unit" "let a& = [10]\nfun f(a, b): ()\nf(a, a)";
          tase_exn "excl 6"
            (ln "a was mutably borrowed in line %i, cannot borrow" 3)
            "let a& = [10]\nfun f(a&, b&): ()\nf(&a, &a)";
          tase_exn "excl env"
            (ln "a was mutably borrowed in line %i, cannot borrow" 3)
            {|let a& = [10]
fun set_a(b&): &a <- [11]
set_a(&a)|};
          tase_exn "follow string literal"
            "Cannot move string literal. Use `copy`"
            "let c = \"aoeu\"\nlet d = c\nlet e& = d";
          tase_exn "move local borrows"
            "Branches have different ownership: owned vs borrowed"
            {|let a = [10]
let c = do:
  if true:
    let a = [10]
    a
  else:
    a|};
          tase_exn "forbid move of cond borrow"
            "Cannot move conditional borrow. Either copy or directly move \
             conditional without borrowing"
            {|fun test():
  let ai = [10]
  let bi = [11]
  let c = if false: ai else:
      if true: bi else:
        if true: ai else: bi
  c|};
          tase_exn "specify mut passing"
            "Specify how rhs expression is passed. Either by move '!' or \
             mutably '&'"
            "let a& = [10]\nlet b& = a";
          tase_exn "partially set moved"
            (ln "a was moved in line %i, cannot set a.[0]" 2)
            "let a& = [10]\nlet b = (a, 0)\n&a.[0] <- 10";
          tase_exn "track moved multi-borrow param"
            "Borrowed parameter s is moved"
            {|fun test(s&):
  let a = s
  let c = a
  ignore((c, 0))|};
          tase_exn "move binds individual"
            (ln "thing.value was moved in line %i, cannot use" 6)
            {|type data = {key : array(u8), value : array(u8)}
type data_container = #empty | #item(data)
fun hmm(thing&): match thing:
  #item({key, value}):
    ignore((key, 0))
    ignore((value, 0))
    ignore((value, 0))
  #empty: ()|};
          tase_exn "move binds param" "Borrowed parameter thing is moved"
            {|type data = {key : array(u8), value : array(u8)}
type data_container = #empty | #item(data)
fun hmm(thing&): match thing:
  #item({key, value}):
    ignore((key, 0))
    ignore((value, 0))
  #empty: ()|};
          tase_exn "let pattern name"
            (ln "key was moved in line %i, cannot use" 4)
            {|type data = {key : array(u8), value : array(u8)}
fun hmm():
  let {key, value} = !{key = ['k', 'e', 'y'], value = ['v', 'a', 'l', 'u', 'e']}
  ignore((key, 0))
  ignore((key, 0))|};
          tase_exn "track module outer toplevel" "Cannot move top level binding"
            "let a = [10]\nmodule inner:\n let _ = (a, 0)";
          tase_exn "track vars from inner module"
            "Cannot move top level binding"
            "module fst:\n let a = [20]\nignore([fst/a])";
          tase_exn "track vars from inner module use after move"
            (ln "fst/a was moved in line %i, cannot use" 3)
            "module fst:\n let a = [20]\nignore([fst/a])\nignore(fst/a.[0])";
          tase_exn "always borrow field"
            (ln "sm.free_hd was borrowed in line %i, cannot mutate" 7)
            {|type key = {idx : int, gen : int}
type t = {slots& : array(key), data& : array(int), free_hd& : int, erase& : array(int)}

do:
  let sm& = {slots = [], data = [], free_hd = -1, erase = []}
  let idx = 0
  let slot_idx = sm.free_hd
  let free_key = sm.slots.[slot_idx]
  let free_hd = copy(free_key.idx)
  let nextgen = free_key.gen + 1
  &sm.slots.[slot_idx] <- {idx, gen = nextgen}
  &sm.free_hd <- free_hd
  ignore({gen = nextgen, idx = slot_idx})|};
          case "lambda copy capture" test_excl_lambda_copy_capture;
          case "lambda copy capture nonalloc"
            test_excl_lambda_copy_capture_nonalloc;
          case "lambda not copy capture" test_excl_lambda_not_copy_capture;
          case "fn copy capture" test_excl_fn_copy_capture;
          case "fn not copy capture" test_excl_fn_not_copy_capture;
          case "partial move re-set" test_excl_partial_move_reset;
          case "projections partial moves" test_excl_projections_partial_moves;
          case "array move const" test_excl_array_move_const;
          case "array move var" test_excl_array_move_var;
          case "array move mixed" test_excl_array_move_mixed;
          case "array move wrong index" test_excl_array_move_wrong_index;
          case "array move dyn index" test_excl_array_move_dyn_index;
        ] );
      ( "type decl",
        [
          case "not unique" test_type_decl_not_unique;
          case "use before" test_type_decl_use_before;
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
          case "lit trailing" test_farray_lit_trailing;
          case "nested lit" test_farray_nested_lit;
          case "generalize / instantiate" test_farray_inference;
        ] );
    ]
