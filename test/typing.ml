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
    if String.starts_with ~prefix:"signature" src then src else prelude ^ src
  in
  let open Lexing in
  let lexbuf = from_string src in
  Semicolons.reset ();
  Parser.prog Semicolons.read lexbuf |> Typing.typecheck |> fun t ->
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
  print_endline toplevel;
  match tl with
  | None -> t expect toplevel
  | Some msg ->
      test_exn msg toplevel;
      let fn = "fun f() {\n" ^ String.concat "\n" code ^ "}" in
      (* function *)
      t expect fn

let test_const_int () = test "int" "let a = 1; a"
let test_const_neg_int () = test "int" "let a = -1; a"

let test_const_neg_int_wrong () =
  test_exn "In unary - expecting int or float but found bool" "let a = - true"

let test_const_neg_int2 () = test "int" "let a = - 1; a"
let test_const_float () = test "float" "let a = 1.0; a"
let test_const_neg_float () = test "float" "let a = -1.0; a"

let test_const_neg_float_wrong () =
  test_exn "In unary -. expecting float but found bool" "let a = -. true"

let test_const_neg_float2 () = test "float" "let a = -.1.0; a"
let test_const_bool () = test "bool" "let a = true; a"
let test_const_u8 () = test "u8" "let a = 123u8; a"
let test_const_i32 () = test "i32" "let a = 123i32; a"
let test_const_neg_i32 () = test "i32" "let a = -123i32; a"
let test_const_f32 () = test "f32" "let a = 1.0f32; a"
let test_const_neg_f32 () = test "f32" "let a = -1.0f32; a"

let test_const_string_ansi () =
  test "string/t" "let s = \"\\027[2K\ram idling: \"; s"

let test_hint_int () = test "int" "let a : int = 1; a"
let test_func_id () = test "fun ('a) -> 'a" "fun (a) {copy(a)}"
let test_func_id_hint () = test "fun (int) -> int" "fun (a : int) {a}"
let test_func_int () = test "fun (int) -> int" "fun (a) {a + 1}"
let test_func_bool () = test "fun (bool) -> int" "fun (a) {if a {1} else {1}}"

let test_func_external () =
  test "fun (int) -> unit" "external func : fun (int) -> unit; func"

let test_func_1st_class () =
  test "fun (fun (int) -> 'a, int) -> 'a" "fun (func, arg : int) {func(arg)}"

let test_func_1st_hint () =
  test "fun (fun (int) -> unit, int) -> unit"
    "fun (f : fun (int) -> unit, arg) {f(arg)}"

let test_func_1st_stay_general () =
  test "fun ('a, fun ('a) -> 'b) -> 'b"
    "fun foo(x, f) {f(x)}; fun add1(x) {x + 1}; let a = foo(1, add1); fun \
     boolean(x : bool) {x}; let b = foo(true, boolean); foo"

let test_func_recursive_if () =
  test "fun (int) -> unit"
    "external ext : fun () -> unit; fun rec foo(i) {if i < 2 {ext()} else \
     {foo(i - 1)}}; foo"

let test_func_generic_return () =
  test "int" "fun apply(f, x) {f(x)}; fun add1(x) {x + 1}; apply(add1, 1)"

let test_func_capture_annot () =
  test "unit"
    "external somefn : fun () -> int; fun wrapper(s) {let a = somefn();   fun \
     captured() [a] {a + 1};   ()}"

let test_func_capture_annot_wrong () =
  test_exn "Value a is not captured, cannot copy" "fun somefn () [a] {()}"

let test_func_unused_rec () =
  test_exn "Unused rec flag" "fun rec add(a) {a + 1}"

let test_func_missing_move_known () =
  test "unit" "fun move(mov a) { ignore(a) };move([0])"

let test_func_missing_move_unknown () =
  test_exn
    "In application\n\
     expecting fun (fun (array[int]) -> _) -> _\n\
     but found fun (fun (mov array[int]) -> _) -> _"
    {|fun move(mov a) { ignore(a) }
fun apply_move(move) { move([0]) }
apply_move(move)
|}

let test_func_orphan_poly () =
  test_exn
    "Expression cannot be monomorphized, it contains orphan polymorphic types"
    {|fun id(mov x) { x }
fun add_final() { copy(id) }
(id, 0)|}

let test_record_clear () =
  test "t" "type t = { x : int, y : int }; {x = 2, y = 2}"

let test_record_false () =
  test_exn "Unbound field z on record t"
    "type t = {x : int, y : int}; {x = 2, z = 2}"

let test_record_trailing () =
  test "t" "type t = { x : int, y : int }; {x = 2, y = 2,}"

let test_record_choose () =
  test "t1"
    "type t1 = { x : int, y : int }; type t2 = { x : int, z : int }; {x = 2, y \
     = 2}"

let test_record_reorder () =
  test "t" "type t = {x : int, y : int}; {y = 10, x = 2}"

let test_record_create_if () =
  test "t" "type t = {x : int}; {x = if true {1} else {0}}"

let test_record_create_return () =
  test "t" "type t = {x : int}; fun a() {10}; {x = a()}"

let test_record_wrong_type () =
  test_exn "In record expression expecting int but found bool"
    "type t = {x : int}; {x = true}"

let test_record_wrong_choose () =
  test_exn "In record expression expecting int but found bool"
    "type t1 = {x : int, y : int}; type t2 = {x : int, z : int}; {x = 2, y = \
     true}"

let test_record_field_simple () =
  test "int" "type t = {x :int}; let a = {x = 10}; a.x"

let test_record_field_infer () =
  test "fun (t) -> int" "type t = {x : int}; fun a {a.x}"

let test_record_same_field_infer () =
  test "a" "type a = {x : int}; type b = {x : int, y : int}; {x = 12}"

let test_record_nested_field_infer () =
  test "c"
    "type a = {x :int}; type b = {x : int}; type c = { x : int, y : a }; {x = \
     12, y = {x = 12}}"

let test_record_nested_field_generic () =
  test "c[b]"
    "type a = {x : int}; type b = {x : int}; type c['a] = {x : int, y : 'a}; \
     {x = 12, y = {x = 12}}"

let test_record_field_no_record () =
  test_exn "Field access of record t expecting t but found int"
    "type t = {x : int}; let a = 10; a.x"

let test_record_field_wrong_record () =
  test_exn "In application expecting fun (t1) -> _ but found fun (t2) -> _"
    "type t1 = {x : int}; type t2 = {y : int}; fun foo(a) {a.x}; let b = {y = \
     10}; foo(b)"

let test_record_update () =
  test "a"
    "type a = {x : int, y : int}; let a = {x = 10, y = 20}; {a with y = 30}"

let test_record_update_poly_same () =
  test "a[int]"
    "type a['a] = {x : 'a, y : int}; let a = {x = 10, y = 20}; {a with x = 20}"

let test_record_update_poly_change () =
  test "a[float]"
    "type a['a] = {x : 'a, y : int}; let a = {x = 10, y = 20}; {a with x = \
     20.0}"

let test_record_update_useless () =
  test_exn "All fields are explicitely updated. Record update is useless"
    "type a = {x : int, y : int}; let a = {x = 10, y = 20}; {a with y = 30, x \
     = 10}"

let test_record_update_expr () =
  test "a" "type a = {x : int, y : int}; {{x = 10, y = 20} with y = 30}"

let test_record_update_wrong_field () =
  test_exn "Unbound field z on a"
    "type a['a] = {x : 'a, y : int}; let a = {x = 10, y = 20}; {a with z = 20}"

let test_record_update_unknown_polymorphic () =
  test "unit"
    {|type record = {x : int, y : int}
fun update(record) {{record with x = 10}}
ignore(update)|}

let test_annot_concrete () = test "fun (int) -> bool" "fun foo(x) {x < 3}; foo"

let test_annot_rc () =
  test "fun (rc[array[int]]) -> unit" "fun foo(x : rc[array[int]]) {()}; foo"

let test_annot_concrete_fail () =
  test_exn
    "Var annotation expecting fun (bool) -> int but found fun (int) -> bool"
    "let foo : fun (bool) -> int = fun x {x < 3}; foo"

let test_annot_mix () =
  test "fun (mov 'a) -> 'a" "fun pass(mov x : 'b) {x}; pass"

let test_annot_mix_fail () =
  test_exn "Var annotation expecting fun (_) -> int but found fun (_) -> 'a"
    "let pass : fun ('b) -> int = fun x {copy(x)}; pass"

let test_annot_generic () =
  test "fun (mov 'a) -> 'a" "fun pass(mov x : 'b) {x}; pass"

let test_annot_generic_fail () =
  test_exn "Var annotation expecting fun (_) -> 'b but found fun (_) -> 'a"
    "let pass : fun ('a) -> 'b = fun x {copy(x)}; pass"

let test_annot_generic_mut () =
  test "fun (mut 'a) -> 'a" "fun pass(mut x : 'b) {copy(x)}; pass"

let test_annot_fun_mut_param () =
  test "fun (mut int) -> unit"
    "external f : fun (mut int) -> unit; let a : fun (mut int) -> unit = f; a"

let test_annot_generic_fun_mut_param () =
  test "fun (mut 'a) -> unit"
    "external f : fun (mut 'a) -> unit; let a : fun (mut 'a) -> unit = f; a"

let test_annot_record_simple () =
  test "a" "type a = {x : int}; type b = {x : int}; let a : a = {x = 12}; a"

let test_annot_record_generic () =
  test "a[bool]"
    "type a['a] = {x : 'a}; type b = {x : int}; let a : a[bool] = {x = true}; a"

let test_annot_record_generic_multiple () =
  test_exn "Type a expects 2 type parameters"
    "type a['a, 'b] = {x : 'a, y : 'b}; let a : a = {x = true}; a"

let test_annot_tuple_simple () =
  test "(int, bool)" "let a : (int, bool) = (1, true); a"

let test_annot_array_arg_generic () =
  test "array[int]" "fun foo(mov a : array['a]) {a}; foo(mov [10])"

let test_annot_tuple_generic () =
  test "(int, bool)" "fun hmm(mov a : (int, 'a)) {a}; hmm(mov (1, true))"

let test_annot_fixed_size_array () =
  test "array#32[int]" "fun hmm(mov a : array#32['a]) {a}; hmm(mov #32[0])"

let test_annot_fixed_unknown_size_array () =
  test "array#32[int]" "fun hmm(mov a : array#?['a]) {a}; hmm(mov #32[0])"

let test_annot_fixed_unknown_size_array_fn () =
  (* The function is instantiated so the size is not generalized. That's why
     there are two question marks. *)
  test "fun (mov array#??['a]) -> array#??['a]"
    "fun hmm(mov a : array#?['a]) {a}; hmm"

let test_sequence () =
  test "int" "external printi : fun (int) -> unit; printi(20); 1 + 1"

let test_sequence_fail () =
  test_exn
    "Left expression in sequence must be of type unit,\n\
     expecting unit\n\
     but found int" "fun add1(x) {x + 1}; add1(20); 1 + 1"

let test_para_instantiate () =
  test "foo[int]"
    "type foo['a] = {first : int, gen : 'a}; let foo = {first = 10, gen = 20}; \
     foo"

let test_para_gen_fun () =
  test "fun (foo['a]) -> int"
    "type foo['a] = {gen : 'a, second : int}; fun get(foo) {copy(foo.second)}; \
     get"

let test_para_gen_return () =
  test "fun (mov foo['a]) -> 'a"
    "type foo['a] = {gen : 'a}; fun get(mov foo) {foo.gen}; get"

let test_para_multiple () =
  test "bool"
    "type foo['a] = {gen : 'a}; fun get(foo) {copy(foo.gen)}; let a = {gen = \
     12}; let b : int = get(a); let c = {gen = false}; get(c)"

let test_para_instance_func () =
  test "fun (foo[int]) -> int"
    "type foo['a] = {gen : 'a}; fun apply(foo) {foo.gen + 17}; let foo = {gen \
     = 17}; apply"

let test_para_instance_wrong_func () =
  test_exn "In record expression expecting int but found bool"
    "type foo['a] = {gen : 'a}; fun apply(foo) {foo.gen + 17}; let foo = {gen \
     = 17}; apply({gen = true})"

let test_pipe_head_single () = test "int" "fun add1(a) {a + 1}; 10 |> add1"

let test_pipe_head_single_call () =
  test "int" "fun add1(a) {a + 1}; 10 |> add1()"

let test_pipe_head_multi_call () =
  test "int" "fun add1(a) {a + 1}; 10 |> add1 |> add1"

let test_pipe_head_single_wrong_type () =
  test_exn "In application expecting fun (int) -> 'a but found int"
    "let add1 = 1; 10 |> add1"

let test_pipe_head_mult () = test "int" "fun add(a, b) {a + b}; 10 |> add(12)"

let test_pipe_head_mult_wrong_type () =
  test_exn
    "In application expecting fun (int, int) -> _ but found fun (int) -> _"
    "fun add1(a) {a + 1}; 10 |> add1(12)"

let test_alias_simple () =
  test "fun (int) -> unit" "type foo = int; external f : fun (foo) -> unit; f"

let test_alias_param_concrete () =
  test "fun (raw_ptr[u8]) -> unit"
    "type foo = raw_ptr[u8]; external f : fun (foo) -> unit; f"

let test_alias_param_quant () =
  test "fun (raw_ptr['a]) -> unit"
    "type foo['a] = raw_ptr['a]; external f : fun (foo['a]) -> unit; f"

let test_alias_param_missing () =
  test_exn "Type raw_ptr expects 1 type parameter"
    "type foo['a] = raw_ptr['a]; external f : fun (foo) -> unit; f"

let test_alias_of_alias () =
  test "fun (int) -> int"
    "type foo = int; type bar = foo; external f : fun (bar) -> foo; f"

let test_alias_labels () =
  test "inner/t[int]"
    {|module inner {
  type t['a] = {a : 'a, b : int}}
type t['a] = inner/t['a]
{a = 20, b = 10}
|}

let test_alias_ctors () =
  test "inner/t[int]"
    {|module inner {
  type t['a] = Noo | Yes('a)}
type t['a] = inner/t['a]
Yes(10)|}

let test_alias_ctors_dont_overwrite () =
  test "fun (option[item['a]]) -> option['a]"
    {|type option['a] = Some('a) | None
type item['a] = {value : 'a}
type slot['a] = option[item['a]]

fun get_item(slot) {
    match slot {
      Some(item) -> Some(copy(item.value))
      None -> None}}
get_item|}

let test_array_lit () = test "array[int]" "[0, 1]"
let test_array_lit_trailing () = test "array[int]" "[0, 1,]"

let test_array_var () = test "array[int]" {|let a = [0, 1]
a|}

let test_array_weak () =
  test "array[int]"
    {|external setf : fun (array['a], 'a) -> unit
let a = []
setf(a, 2)
a|}

let test_array_different_types () =
  test_exn "In array literal expecting int but found bool" "[0, true]"

let test_array_different_annot () =
  test_exn "In let binding expecting array[int] but found array[bool]"
    "let a : array[bool] = [0, 1]; a"

let test_array_different_annot_weak () =
  test_exn
    "In application expecting fun (_, bool) -> _ but found fun (_, int) -> _"
    "external setf : fun (array['a], 'a) -> unit; let a : array[bool] = []; \
     setf(a, 2)"

let test_array_different_weak () =
  test_exn
    "In application expecting fun (_, int) -> _ but found fun (_, bool) -> _"
    {|external setf : fun (array['a], 'a) -> unit
let a = []
setf(a, 2)
setf(a, true)|}

let test_mutable_declare () = test "int" "type foo = { mut x : int }; 0"

let test_mutable_set () =
  test "unit"
    "type foo = { mut x : int }; let mut foo = {x = 12}; mut foo.x = 13"

let test_mutable_set_wrong_type () =
  test_exn "In mutation expecting int but found bool"
    "type foo = {mut x : int}; let mut foo = {x = 12}; mut foo.x = true"

let test_mutable_set_non_mut () =
  test_exn "Cannot mutate non-mutable binding"
    "type foo = {x : int}; let foo = {x = 12}; mut foo.x = 13"

let test_mutable_value () = test "int" "let mut b = 10; mut b = 14; b"

let test_mutable_nonmut_value () =
  test_exn "Cannot mutate non-mutable binding" "let b = 10; mut b = 14; b"

let test_mutable_nonmut_transitive () =
  test_exn "Cannot mutate non-mutable binding"
    "type foo = { mut x : int }; let foo = {x = 12}; mut foo.x = 13"

let test_mutable_nonmut_transitive_inv () =
  test_exn "Cannot mutate non-mutable binding"
    "type foo = {x : int}; let mut foo = {x = 12}; mut foo.x = 13"

let test_mutable_track_ptr_nonmut () =
  test_exn "Cannot project immutable binding"
    "type thing = { ptr : raw_ptr[u8] }; {  let thing = { ptr = \
     __unsafe_nullptr() };   let mut proj = mut (__unsafe_ptr_get(thing.ptr, \
     0));   0}"

let test_mutable_track_ptr_mut () =
  test "int"
    "type thing = { mut ptr : raw_ptr[u8] }; {let mut thing = { ptr = \
     __unsafe_nullptr() };   let mut proj = mut (__unsafe_ptr_get(thing.ptr, \
     0));   0}"

let test_variants_option_none () =
  test_exn "Expression contains weak type variables: option['a]"
    "type option['a] = None | Some('a); None"

let test_variants_option_some () =
  test "option[int]" "type option['a] = None | Some('a); Some(1)"

let test_variants_option_some_some () =
  test "option[option[float]]"
    "type option['a] = None | Some('a); let a = Some(1.0); Some(copy(a))"

let test_variants_option_annot () =
  test "option[option[float]]"
    "type option['a] = None | Some('a); {let a : option[float] = None; Some(a)}"

let test_variants_option_none_arg () =
  test_exn
    "The constructor None expects 0 arguments, but an argument is provided"
    "type option['a] = None | Some('a); None(1)"

let test_variants_option_some_arg () =
  test_exn "The constructor Some expects arguments, but none are provided"
    "type option['a] = None | Some('a); Some"

let test_variants_correct_inference () =
  test "unit"
    {|type view = {start : int, len : int}
type success['a] = {rem : view, mtch : int}
type parse_result['a] = Ok(success['a]) | Err(view)
fun map(p, f, buf, view){
  match p(buf, view){
    Ok(ok) -> Ok({ok with mtch = f(ok.mtch)})
    Err(view) -> Err(view)
  }
}|}

let test_variants_nameclash () =
  test_exn "Two constructors are named None" "type t = None | Some | None"

let test_lor_clike_variant () = test "int" "type clike = A | B; B |> lor(A)"

let test_lor_other_variant () =
  test_exn "Expecting int, not a variant type"
    "type clike = A(int) | B; B |> lor(A)"

let test_match_all () =
  test "int"
    "type option['a] = None | Some('a); match Some(1) { Some(a) -> a; None -> \
     -1}"

let test_match_redundant () =
  test_exn "Pattern match case is redundant"
    "type option['a] = None | Some('a); match Some(1) { a -> a | None -> -1}"

let test_match_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: Some"
    "type option['a] = None | Some('a); match Some(1) { None -> -1}"

let test_match_missing_nested () =
  test_exn
    "Pattern match is not exhaustive. Missing cases: Some(Int) | Some(Non)"
    {|type option['a] = None | Some('a)
type test = Float(float) | Int(int) | Non
match None {
  Some(Float(f)) -> f |> int_of_float
  -- Some(Int(i))
  -- Some Non
  None -> 0
}|}

let test_match_all_after_ctor () =
  test "int"
    {|type option['a] = None | Some('a)
match Some(1) {None -> -1 | a -> 0}|}

let test_match_all_before_ctor () =
  test_exn "Pattern match case is redundant"
    {|type option['a] = None | Some('a)
match Some(1) {a -> 0 | None -> -1}|}

let test_match_redundant_all_cases () =
  test_exn "Pattern match case is redundant"
    {|type option['a] = None | Some('a)
type test = Float(float) | Int(int) | Non
match None {
  Some(Float(f)) -> f |> int_of_float
  Some(Int(i)) -> i
  Some(Non) -> 1
  None -> 0
  a -> -1
}|}

let test_match_wildcard () =
  test_exn "Pattern match case is redundant"
    {|type option['a] = None | Some('a)
match Some(1) {_ -> 0 | None -> -1}|}

let test_match_wildcard_nested () =
  test_exn "Pattern match case is redundant"
    {|type option['a] = None | Some('a)
type test = Float(float) | Int(int) | Non
match None {
  Some(Float(f)) -> f |> int_of_float
  Some(_) -> -2
  Some(Non) -> 1
  None -> 0
}|}

let test_match_column_arity () =
  test_exn
    "Tuple pattern has unexpected type:\n\
     expecting (int, int)\n\
     but found (int, int, 'a)"
    {|type option['a] = None | Some('a)
match (1, 2) {
  (a, b, c) -> a
}|}

let test_match_record () =
  test "int"
    {|type option['a] = None | Some('a)
type foo = {a : int, b : float}
match Some({a = 12, b = 53.0}) {
  Some({a, b}) -> a
  None -> 0
}|}

let test_match_record_field_missing () =
  test_exn "There are missing fields in record pattern, for instance b"
    {|type option['a] = None | Some('a)
type foo = {a : int, b : float}
match Some({a = 12, b = 53.0}) {
  Some({a}) -> a
  None -> 0
}|}

let test_match_record_field_twice () =
  test_exn "Field a appears multiple times in record pattern"
    {|type option['a] = None | Some('a)
type foo = {a : int, b : float}
match Some({a = 12, b = 53.0}) {
  Some({a, a}) -> a
  None -> 0
}|}

let test_match_record_field_wrong () =
  test_exn "Unbound field c on record foo"
    {|type option['a] = None | Some('a)
type foo = {a : int, b : float}
match Some({a = 12, b = 53.0}) {
  Some({a, c}) -> a
  None -> 0
}|}

let test_match_record_case_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: Some(None)"
    {|
type option['a] = None | Some('a)
type foo['a] = {a : 'a, b : float}
match Some({a = Some(2), b = 53.0}) {
  Some({a = Some(a), b}) -> a
  None -> 0}|}

let test_match_int () =
  test "int"
    {|type option['a] = None | Some('a)
match Some(10) {Some(1) -> 1; Some(10) -> 10; Some(_) -> 0; None -> -1}
|}

let test_match_int_wildcard_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: Some"
    {|type option['a] = None | Some('a)
match Some(10) {Some(1) -> 1; Some(10) -> 10; None -> -1}|}

let test_match_int_twice () =
  test_exn "Pattern match case is redundant"
    {|
type option['a] = None | Some('a)
match Some(10) {Some(1) -> 1; Some(10) -> 10; Some(10) -> 10; Some(_) -> 0; None -> -1}
|}

let test_match_int_after_catchall () =
  test_exn "Pattern match case is redundant"
    {|
type option['a] = None | Some('a)
match Some(10) {Some(1) -> 1; Some(_) -> 10; Some(10) -> 10; None -> -1}
|}

let test_match_or () =
  test "int" "match (1, 2) {(a, 1) | (a, 2) -> a;  _ -> -1}"

let test_match_or_missing_var () =
  test_exn "No var named a" "match (1, 2) {(a, 1) | (b, 2) -> a; _ -> -1}"

let test_match_or_redundant () =
  test_exn "Pattern match case is redundant"
    "match (1, 2) { (a, 1) | (a, 2) | (a, 1) -> a; _ -> {-1}}"

let test_match_guard_positive () =
  test "unit"
    {|type option['a] = None | Some('a)
match Some(0) {
  Some(_) and true -> { () }
  Some(_) -> { () }
  None -> { () }
}|}

let test_match_guard_after () =
  test_exn "Pattern match case is redundant"
    {|type option['a] = None | Some('a)
match Some(0) {
  Some(_) -> { () }
  Some(_) and true -> { () }
  None -> { () }
}|}

let test_match_guard_missing () =
  test_exn "Pattern match is not exhaustive. Missing cases: Some"
    {|type option['a] = None | Some('a)
match Some(0) {
  Some(_) and true -> { () }
  None -> { () }
}|}

let test_match_guard_missing_spec () =
  test_exn "Pattern match is not exhaustive. Missing cases: Some"
    {|type option['a] = None | Some('a)
match Some(0) {
  Some(_) and true -> { () }
  Some(1) -> { () }
  None -> { () }
}|}

let test_match_guard_dont_leak_vars () =
  test_exn "No var named a"
    {|type option['a] = None | Some('a)
match Some(0) {
  Some(a) and true -> { ignore(a) }
  Some(_) -> a
  None -> { println("none") }
}|}

let test_match_unit () = test "unit" {|match () {
  () -> ()
}|}

let test_match_unit_redundant () =
  test_exn "Pattern match case is redundant"
    {|match () {
  () -> ()
  () -> ()
}|}

let test_multi_record2 () =
  test "foo[int, bool]"
    "type foo['a, 'b] = {a : 'a, b : 'b}; {a = 0, b = false}"

let test_multi_variant2 () =
  test_exn "Expression contains weak type variables: foo[int, 'a]"
    "type foo['a, 'b] = Some('a) | Other('b); Some(1)"

let test_tuple () = test "(int, float)" "( 1, 2.0 )"
let test_pattern_decl_var () = test "int" "let a = 123; a"
let test_pattern_decl_wildcard () = test "int" "let _ = 123; 0"

let test_pattern_decl_record () =
  test "float"
    "type foo = {i : int, f : float}; let {i, f} = {i = 12, f = 5.0}; f"

let test_pattern_decl_record_wrong_field () =
  test_exn "Unbound field y on record foo"
    "type foo = {i : int, f : float}; let {y, f} = {i = 12, f = 5.0}; f"

let test_pattern_decl_record_missing () =
  test_exn "There are missing fields in record pattern, for instance i"
    "type foo = {i : int, f : float}; let {f} = {i = 12, f = 5.0}; f"

let test_pattern_decl_tuple () = test "float" "let i, f = (12, 5.0); f"

let test_pattern_decl_tuple_missing () =
  test_exn
    "Tuple pattern has unexpected type:\n\
     expecting (int, float, int)\n\
     but found (int, float)" "let x, f = (12, 5.0, 20); f"

let test_pattern_decl_wildcard_move () =
  test "fun ('a, mov 'b) -> unit" "fun func(_, mov _) {()}; func"

let test_pattern_decl_tuple_move () =
  test "fun ('a, mov ('b, 'c)) -> unit" "fun func(_, mov (a, b)) {()}; func"

let test_signature_only () = test "unit" "signature { type t = int}"

let test_signature_simple () =
  test "unit" "signature{ type t = int }; type t = int"

let test_signature_wrong_typedef () =
  test_exn "Signatures don't match: expecting int but found float"
    {|signature{
  type t = int}
type t = float|}

let test_signature_generic () =
  test "unit"
    {|signature{
  type t['a]
  val create : fun (mov 'a) -> t['a]
  val create_int : fun (int) -> t[int]
}
type t['a] = {x : 'a}

fun create(mov x) {{x}}
fun create_int(x : int) {{x}}|}

let test_signature_param_mismatch () =
  test_exn
    "Signatures don't match for value create_int:\n\
     expecting fun (_) -> t[int]\n\
     but found fun (_) -> t['a]"
    {|signature{
  type t['a]
  val create_int : fun (int) -> t[int]}
type t['a] = {x : int}
fun create_int(x : int) {{x}}|}

let test_signature_unparam_type () =
  test "unit" {|signature{
  type t['a]}
type t['a] = int|}

let test_signature_abstract () =
  test "unit"
    {|signature {
  type t
  val len : fun (t) -> int
}
type t = array[u8]
fun len(str : t) {__unsafe_array_length(str)}|}

let test_signature_namespaces () =
  test "unit" {|signature {
  type t
}
type t = int

let t = 200|}

let local_module =
  {|type t = float
type global = int
module nosig {
  type t = {a : int}
  type other = int
  module nested {
    type t = u8
  }
}
|}

let test_signature_after_statement () =
  test_exn "Module signature must be declared at the top"
    {|let _ = 12
signature {
  type t}|}

let test_signature_not_unique () =
  test_exn "Module signature must be unique"
    {|signature {
  type t }
signature {
  type t}|}

let test_signature_concrete_of_generic_alias () =
  test "unit"
    {|signature {
  type option['a] = None | Some('a)
  type thing['a]
  val use_thing : fun (thing[unit]) -> unit
}

type thing['a] = array[option['a]]

fun use_thing(a : thing[unit]) {
  ignore(a.[0])
}|}

let test_signature_generic_of_generic_alias () =
  test_exn
    "Signatures don't match for value use_generic:\n\
     expecting fun (thing['a]) -> _\n\
     but found fun (array[option[unit]]) -> _"
    {|signature {
  type option['a] = None | Some('a)
  type thing['a]
  val use_thing : fun (thing[unit]) -> unit
  val use_generic : fun (thing['a]) -> unit
}

type thing['a] = array[option['a]]

fun use_thing(a : thing[unit]) {
  ignore(a.[0])
}
fun use_generic(a : thing[unit]) {
  ignore(a.[0])
}
|}

let test_signature_deep_qvar_sg () =
  test "unit"
    {|type option['a] = None | Some('a)
module nullvec {
  signature {
    type t['a]
    val of_array : fun (mov array['a]) -> t['a]
  }

  type t['a] = option[array['a]]

  fun of_array(mov arr) { Some(arr) }
}

fun find_missing_deps(_ : array[unit]) { () }
fun enqueue(mov _ : nullvec/t[unit]) { 0 }

fun mov deps {
  find_missing_deps(deps)
  enqueue(nullvec/of_array(deps))
}
|> ignore
|}

let test_signature_dont_match_qvar () =
  test_exn
    "Signatures don't match for value run:\n\
     expecting fun (_) -> option['a]\n\
     but found fun (_) -> 'a"
    {|type option['a] = None | Some('a)
module async {
  signature {
    type promise['a]
    type future['a]

    val extract_maybe : fun (mov future['a]) -> option['a]
  }

  type prom_state['a] =
  | Pending
  | Resolved('a)

  type promise['a] = prom_state['a]
  type future['a] = promise['a]

  fun extract_maybe(mov fut) {
    match fut {
      Resolved(v) -> Some(v)
      Pending -> None
    }
  }
}

module auv {
  signature {
    val run : fun (mov async/future['a]) -> option['a]
  }

  fun run(mov fut) {
    match async/extract_maybe(fut) {
      Some(v) -> v
      None -> __any_abort()
    }
  }
}
|}

let test_local_modules_find_local () =
  test "unit" (local_module ^ "let test : nosig/t = { a = 10 }")

let test_local_modules_find_nested () =
  test "unit" (local_module ^ "let test : nosig/nested/t = 0u8")

let test_local_modules_miss_local () =
  test_exn "In let binding expecting float but found nosig/t"
    (local_module ^ "let test : nosig/t = 10.0")

let test_local_modules_miss_nested () =
  test_exn "Expected a record type, not u8"
    (local_module ^ "let test : nosig/nested/t = {a = 10}")

let test_local_modules_miss_local_dont_find_global () =
  test_exn "Unbound type nosig/global."
    (local_module ^ "let test : nosig/global = { a = 10 }")

let test_local_module_unique_names () =
  test_exn "Module names must be unique. nosig exists already"
    (local_module ^ "module nosig {type t = int}")

let test_local_module_nested_module_alias () =
  test "nosig/nested/t"
    {|module nosig {
  type t = { a : int, b : int }
  let _ = { a = 10, b = 20 }
  module nested {
    type t = {a : int, b : int, c : int}
    let t = {a = 10, b = 20, c = 30}
  }
}
module mm = nosig/nested
nosig/nested/t|}

let test_local_module_alias_dont () =
  test_exn "Cannot find module: nested in nosig/nested"
    {|
-- this shouln't be found
module nested {
  type t = {a : int, b : int, c : int}
  let t = { a = 11, b = 21, c = 31 }
}
module nosig {
  type t = {a : int, b : int}
  let _ = {a = 10, b = 20}
  module notnested {
    type t = {a : int, b : int, c : int}
    let t = {a = 10, b = 20, c = 30}
  }
}
module mm = nosig/nested
|}

let own = "let mut x = [10]"
let tl = Some "Cannot borrow mutable binding at top level"

let test_excl_borrow () =
  wrap_fn ~tl test "unit" [ own; "let y = x"; "ignore(x)"; "ignore(y)" ]

let test_excl_borrow_use_early () =
  wrap_fn ~tl test_exn
    (ln "x was borrowed in line %i, cannot mutate" 3)
    [ own; "let y = x"; "ignore(x)"; "mut x = [11]"; "ignore(y)" ]

let tl = Some "Cannot move top level binding"

let test_excl_move_mut () =
  wrap_fn ~tl test "unit"
    [ own; "let mut y = mov x"; "mut y = [11]"; "ignore(y)" ]

let test_excl_move_mut_use_after () =
  wrap_fn test_exn
    (ln "x was moved in line %i, cannot use" 2)
    [ own; "let mut y = mov x"; "ignore(x)" ]

let test_excl_move_record () =
  wrap_fn ~tl test "unit" [ own; "let y = (x, 0)"; "ignore(y)" ]

let test_excl_move_record_use_after () =
  wrap_fn test_exn
    (ln "x was moved in line %i, cannot use" 2)
    [ "let mut x =[10]"; "let y = (x, 0)"; "ignore(x)" ]

let test_excl_borrow_then_move () =
  wrap_fn test_exn
    (ln "x was moved in line %i, cannot use" 3)
    [ "let x = [10]"; "let y = x"; "ignore((y, 0))"; "x" ]

let test_excl_if_move_lit () =
  wrap_fn ~tl test "unit"
    [ "let x = [10]"; "let mut y = mov if true {x} else {[10]}"; "ignore(y)" ]

let test_excl_if_borrow_borrow () =
  wrap_fn test "unit"
    [ "let x = 10"; "let y = 10"; "ignore(if true {x} else {y})" ]

let test_excl_if_lit_borrow () =
  wrap_fn test_exn "Branches have different ownership: owned vs borrowed"
    [ "let x = [10]"; "ignore(if true {[10]} else {x})" ]

let proj_msg = Some "Cannot project at top level"

let test_excl_proj () =
  wrap_fn ~tl:proj_msg test "unit"
    [ own; "let mut y = mut x"; "mut y = [11]"; "ignore(x)" ]

let test_excl_proj_immutable () =
  wrap_fn ~tl:proj_msg test_exn "Cannot project immutable binding"
    [ "let x = 10"; "let mut y = mut x"; "x" ]

let test_excl_proj_use_orig () =
  wrap_fn ~tl:proj_msg test_exn
    (ln "x was borrowed in line %i, cannot mutate" 3)
    [
      own; "let mut y = mut x"; "ignore(__unsafe_addr(mut x))"; "ignore(y)"; "x";
    ]

let test_excl_proj_move_after () =
  wrap_fn ~tl:proj_msg test_exn
    (ln "x was borrowed in line %i, cannot mutate" 3)
    [ own; "let mut y = mut x"; "ignore(__unsafe_addr(mut x))"; "(y, 0)" ]

let test_excl_proj_nest () =
  wrap_fn ~tl:proj_msg test_exn
    (ln "y was borrowed in line %i, cannot mutate" 4)
    [
      own;
      "let mut y = mut x";
      "let mut z = mut y";
      "ignore(__unsafe_addr(mut y))";
      "z";
    ]

let test_excl_proj_nest_orig () =
  wrap_fn ~tl:proj_msg test_exn
    (ln "x was borrowed in line %i, cannot mutate" 3)
    [
      own;
      "let mut y = mut x";
      "let mut z = mut y";
      "ignore(__unsafe_addr(mut x))";
      "z";
    ]

let test_excl_proj_nest_closed () =
  wrap_fn ~tl:proj_msg test "unit"
    [ own; "let mut y = mut x"; "let mut z = mut y"; "ignore(z)"; "y" ]

let test_excl_moved_param () =
  test_exn "Borrowed value x has been moved in line 5" "fun meh(x) {x}"

let test_excl_set_moved () =
  test "unit" "fun meh(mut a) {ignore((a, 0));   mut a = 10}"

let test_excl_binds () =
  test "unit"
    {|type ease_kind = Linear | Circ_in

fun ease_circ_in(_) {0.0}
fun ease_linear(_) {0.0}

fun ease(anim){ match anim {
  Linear -> ease_linear(anim)
  Circ_in -> ease_circ_in(anim)}}|}

let test_excl_shadowing () =
  test_exn "Borrowed value a has been moved in line 5"
    "fun thing(a){ let a = a; a}"

let typ = "type string = array[u8]\n type t = {mut a : string, b : string}\n"

let test_excl_parts_success () =
  test "unit" (typ ^ "fun meh(mov a) {{a = a.a, b = a.b}}")

let test_excl_parts_return_part () =
  test "unit" (typ ^ "fun meh(mov a){ let mut c = mov a.a;  a.b}")

let test_excl_parts_dont_reset_part () =
  test_exn "a.a was moved in line 7, cannot use a"
    (typ
   ^ "fun meh(mov a) { let mut a = mov a; let mut c = mut a.a; \
      __unsafe_leak(mov c); a }")

let test_excl_parts_reset_part () =
  test "unit"
    (typ
   ^ "fun meh(mov a) { let mut a = mov a; let mut c = mut a.a; \
      __unsafe_leak(mov c); mut c = [];  a }")

let test_excl_parts_return_whole () =
  test_exn
    (ln "a.a was moved in line %i, cannot use a" 4)
    (typ ^ "fun meh(mov a){\n let mut c = mov a.a\n  a}")

let test_excl_lambda_copy_capture () =
  test "unit" "fun alt(alts) {fun () [alts] {ignore(alts.[0])}}"

let test_excl_lambda_copy_capture_nonalloc () =
  test "unit" "fun alt(alts) {fun () [alts] {ignore(1 + alts)}}"

let test_excl_lambda_not_copy_capture () =
  test_exn "Borrowed value alts has been moved in line 5"
    "fun alt(alts) {fun () {ignore(alts.[0])}}"

let test_excl_fn_copy_capture () =
  test "unit" "fun alt(alts) {fun named() [alts] {  ignore(alts.[0])};  named}"

let test_excl_fn_not_copy_capture () =
  test_exn "Borrowed value alts has been moved in line 5"
    "fun alt(alts) {fun named() {ignore(alts.[0])};  named}"

let test_excl_partial_move_reset () =
  test_exn "Cannot move top level binding"
    {|type tt = {mut a : array[int], mut b : array[int]}
let mut a = {a = [], b = []}
let _ = mov a.a
let _ = mov a.b
mut a.b = []|}

let test_excl_projections_partial_moves () =
  test "array[int]"
    {|type t = {mut a : array[int], mut b : array[int]}
let mut a = {a = [], b = []}

{  let mut a = mut a
  let tmp = mov a.a
  let tmp2 = mov a.b
  mut a.a = tmp2
  mut a.b = tmp
  ignore(a.a)
  a.a}|}

let test_excl_array_move_const () =
  test "unit" {|let mut a = [0]
let _ = mov a.[1]
mut a.[1] = 1|}

let test_excl_array_move_var () =
  test "unit"
    {|let mut a = [0]
let index = 1
let _ = mov a.[index]
mut a.[index] = 1|}

let test_excl_array_move_mixed () =
  test_exn "Cannot move out of array without re-setting"
    {|{let mut a = [0]
let index = 1
let _ = mov a.[1]
mut a.[index] = 1}|}

let test_excl_array_move_wrong_index () =
  test_exn "Cannot move out of array without re-setting"
    {|{let mut a = [0]
fun index() { 1 }
let _ = mov a.[index()]
mut a.[index()] = 1}|}

let test_excl_array_move_dyn_index () =
  test_exn "Cannot move out of array without re-setting"
    {|{let mut a = [0]

  let tmp = mov a.[0]
  mut a.[0 + 0] = 0}|}

let test_excl_array_mutate_part () =
  (* 'a' is touched and by setting a 'part', the 'rest' should not be borrowed
     as foreign, i.e. should not end up is 'Disabled' state. *)
  test "fun (unit) -> unit" {|let mut a = [10]

fun () {
    mut a.[0] = 12
}|}

let test_excl_move_lambda () =
  test_exn "Borrowed value a has been moved in line 5"
    "fun copy_param(mut a) { fun () { mut a = 12 } }"

let test_excl_move_fun () =
  test_exn "Borrowed value a has been moved in line 5"
    "fun copy_param(mut a) {fun f () { mut a = 12 }; f}"

let test_excl_move_outer_branch () =
  test_exn "Borrowed value str has been moved in line 13"
    {|type option['a] = None | Some('a)
fun mutt(mut thing) { ignore(thing) }
fun move(mov thing) { ignore(thing) }

let mut str = mov Some([])

fun capture() {
  match str {
    Some(a) -> move(mov a)
    None -> mutt(mut str)
  }
}
|}

let test_excl_move_outer_branch_else () =
  test_exn "Borrowed value str has been moved in line 14"
    {|type option['a] = None | Some('a)
fun mutt(mut thing) { ignore(thing) }
fun move(mov thing) { ignore(thing) }

let mut str = mov Some([])

fun capture() {
  match str {
    None -> mutt(mut str)
    Some(a) -> move(mov a)
  }
}|}

let test_excl_shadowing_bug () =
  test "fun (array['a]) -> unit"
    {|
    let length = __array_length
fun (arr) {
    let length = length(arr)
    ()
}|}

let test_excl_variant_data () =
  test "fun (mut array[option[value['a]]], int, fun (mut 'a) -> unit) -> unit"
    {|type option['a] = None | Some('a)
type data['a] = { mut data : 'a }
type value['a] = { mut value : 'a }
fun find (mut a, i, f) {
    match mut a.[i] {
      Some(mut item) -> f(mut item.value)
      None -> ()
   }
}
find|}

let test_excl_raw_ptr () =
  test "unit"
    {|fun raw_ptr(ptr) {
    let mut ptr = mov ptr
    __unsafe_ptr_get(ptr, 0)
 }|}

let test_excl_partial_move_set () =
  test "unit"
    {|type rr = {a : array[int], b : array[int]}

let mut a = {a = [], b = []}
ignore((a.a, 0))
mut a = {a = [], b = []}

fun hmm(mut a) {
  ignore((a.b, 0))
  mut a = {a = [], b = []}
}
hmm(mut a)
|}

let test_excl_mutate_shadow () =
  test "unit"
    {|type option['a] = None | Some('a)
let mut a = 10
match mut a {
  mut b -> mut b = 11
}
ignore(a)

type record = {mut a : int, b : float}
let mut a = Some(10)
match mut a {
  Some(mut b) -> mut b = 12
  None -> ()
}|}

let test_excl_regression_assert_on_insert () =
  test "unit"
    {|type option['a] = None | Some('a)
external println : fun ('a) -> unit
type tok = A | B | C(int)

fun infun(tok) {
  let mut delim = None
  (fun tok {
    match tok { C(_) -> println("c") | _ -> () }
    match (delim, tok) {
      (Some(A), A) -> println("some a")
      (Some(B), B) -> println("some b")
      (Some(_), _) -> println("some other")
      (None, tk) -> {
        println("none")
        mut delim = Some(tk)
      }
    }
  })(tok)
}

infun(C(0))
|}

let test_excl_pass_mutating_function () =
  test "unit"
    {|let mut pr = [0]
fun aux() { mut pr = [] }
ignore(aux)
ignore(aux)
|}

let test_excl_not_unchecked () =
  test_exn "Cannot move out of array without re-setting"
    {|type option['a] = None | Some('a)
type inrecord = { str : array[int], other : int }
let arr = [None, Some({ str = [], other = 0})]

fun borrow(arr, i, fn) {
  match arr.[i] {
    None -> fn(None)
    Some(r) -> {
      fn(Some(r.str))
    }
  }
}|}

let test_excl_unchecked () =
  test "unit"
    {|type option['a] = None | Some('a)
type inrecord = { str : array[int], other : int }
let arr = [None, Some({ str = [], other = 0})]

fun borrow(arr, i, fn) {
  match arr.[i] {
    None -> fn(None)
    Some(r) -> {
      let tmp = __unsafe_unchecked(Some(r.str))
      fn(tmp)
      __unsafe_leak(tmp)
    }
  }
}|}

let test_type_decl_not_unique () =
  test_exn "Type names in a module must be unique. t exists already"
    "type t = int; type t = float"

let test_type_decl_use_before () =
  test "unit" "module m {type t = int}; use m; type t = float"

let test_mtype_define () =
  test "unit" {|module type tt {
  type t
  val random : fun () -> int}|}

let test_mtype_no_match () =
  test_exn "Signatures don't match: Type t is missing"
    {|
module type tt {
  type t
}
module test : tt {
  type a = unit
}|}

let test_mtype_no_match_alias () =
  test_exn "Signatures don't match: Type t is missing"
    {|module type tt {
  type t
}
module test {
  type a = unit
}
module other : tt = test
|}

let test_mtype_no_match_sign () =
  test_exn "Signatures don't match: Type t is missing"
    {|module type tt {
  type t}
module test : tt {
  signature {
    type a}
  type a = unit}|}

let test_mtype_abstracts () =
  test "unit"
    {|module outer {
  type t = {i : int}
}
module type sig {
  type t
  val add : fun (t, t) -> t
}
functor make(m : sig){
  fun add_twice(a, b) {
    m/add(m/add(a, b), b)
  }
}
module outa : sig {
  type t = outer/t
  fun add(a, b) {{i = a.i + b.i}}
}
module inta : sig {
  type t = int
  fun add(a, b) {a + b}
}
module floata : sig {
  signature {
    type t
    val add : fun (t, t) -> t}
  type t = float
  fun add(a, b) {a +. b}
}
module somerec : sig {
  type t = {a : int, b : int}
  fun add(a, b) {{a = a.a + a.b, b = a.b + b.b}}
}|}

let test_functor_define () =
  test "unit" "module type mt {type t}; functor f(p : mt) {()}"

let test_functor_module_type_not_found () =
  test_exn "Cannot find module type mt" "functor f(p : mt) {()}"

let test_functor_direct_access () =
  test_exn "The module f is a functor. It cannot be accessed directly"
    "module type mt {type t}; functor f(p : mt) {type a = unit}; ignore(f/a)"

let test_functor_checked_alias () =
  test_exn "The module f is a functor. It cannot be accessed directly"
    "module type mt {type t}; functor f(p : mt) {type a = unit}; module hmm : \
     mt = f"

let test_functor_wrong_arity () =
  test_exn "Wrong arity for functor f: Expecting 1 but got 2"
    "module type mt {type t}; functor f(p : mt) {()}; module a {type t = \
     unit}; module hmm = f(a, a)"

let test_functor_wrong_module_type () =
  test_exn "Signatures don't match: Type t is missing"
    "module type mt {type t}; functor f(p : mt) {()}; module a {()}; module \
     hmm = f(a)"

let test_functor_no_var_param () =
  test_exn "No var named p/a"
    "module type mt {type t}; functor f(p : mt) {let _ = ignore(p/a)}"

let test_functor_apply_use () =
  test "int"
    {|module type sig {
  type t
  val add : fun (t, t) -> t}
functor make(m : sig) {
  fun add_twice(a, b) {
    m/add(m/add(a, b), b)}}
module inta : sig {
  type t = int
  fun add(a, b) {a + b}}
module intadder = make(inta)
intadder/add_twice(1, 2)|}

let test_functor_apply_use_sgn () =
  test_exn
    "In application\n\
     expecting fun (inta/t, inta/t) -> _\n\
     but found fun (int, int) -> _"
    {|module type sig {
  type t
  val add : fun (t, t) -> t}
functor make(m : sig) {
  fun add_twice(a, b) {
    m/add(m/add(a, b), b)}}
module inta : sig {
  signature {
    type t
    val add : fun (t, t) -> t}
  type t = int
  fun add(a, b) {a + b}}
module intadder = make(inta)
intadder/add_twice(1, 2)|}

let test_functor_abstract_param () =
  test_exn
    "In application\n\
     expecting fun (inta/t, inta/t) -> _\n\
     but found fun (int, int) -> _"
    {|module type sig {
  type t
  val add : fun (t, t) -> t}

functor make(m : sig) {
  fun add_twice(a, b) {m/add(m/add(a, b), b)}}

module inta : sig {
  signature {
    type t
    val add : fun (t, t) -> t}
  type t = int
  fun add(a, b) {a + b}}

module intadder = make(inta)
intadder/add_twice(1, 2)|}

let test_functor_use_param_type () =
  test "unit"
    {|module type sig {
  type t
}
functor make(m : sig) {
  type t = m/t}|}

let test_functor_poly_function () =
  test "unit"
    {|
module type poly {
  val id : fun (mov 'a) -> 'a}

functor makeid(m : poly) {
  fun newid(mov p) {m/id(mov p)}}

module some {
  fun id(mov p) {p}}

module polyappl = makeid(some)

ignore(polyappl/newid(mov 1))
ignore(polyappl/newid(mov 1.2))|}

let test_functor_poly_mismatch () =
  test_exn
    "Signatures don't match for value id:\n\
     expecting fun (mov 'a) -> 'a\n\
     but found fun (mov int) -> int"
    {|module type poly {
  val id : fun (mov 'a) -> 'a}

functor makeid(m : poly) {
  fun newid(mov p) {m/id(mov p)}}

module someint {
  fun id(mov p : int) {p}}

module intappl = makeid(someint)|}

(* Copied from hashtbl *)
let check_sig_test thing =
  {|module type key {
  type t}

module type sig {
  type key
  type t['value]

  val create : fun (int) -> t[|}
  ^ thing
  ^ {|]}
functor make : sig (m : key) {
  type key = m/t
  type item['a] = {key : m/t, value : 'a}
  type slot['a] = Empty | Tombstone | Item(item['a])
  type t['a] = {mut data : array[slot['a]], mut nitems : int}

  fun create(size : int) {
    ignore(size)
    let data = []
    {data, nitems = 0}}}|}

let test_functor_check_sig () = test "unit" (check_sig_test "'value")

let test_functor_check_param () =
  test_exn
    "Signatures don't match for value create:\n\
     expecting fun (_) -> t[key]\n\
     but found fun (_) -> t['a]" (check_sig_test "key")

let test_functor_check_concrete () =
  test_exn
    "Signatures don't match for value create:\n\
     expecting fun (_) -> t[int]\n\
     but found fun (_) -> t['a]" (check_sig_test "int")

let test_functor_sgn_only_type () =
  test "unit"
    {|
module type any {
  type t}

functor use_types(m : any) {
  signature {
    type result = { code : int }
    type other_sgn = result}

  type other = int
  type using_result = { res : result }}

module whatev {
  type t = int}

module applied = use_types(whatev)
|}

let test_functor_sgn_reorder () =
  test "unit"
    {|
module type any {
  type t}

functor use_types(m : any) {
  signature {
    type state
    type result = { code : int }}

  type state = result}

module whatev {
  type t = int}

module applied = use_types(whatev)
|}

let test_farray_lit () = test "unit" "let arr = #[1, 2, 3]"
let test_farray_lit_trailing () = test "unit" "let arr = #[1, 2, 3,]"

let test_farray_nested_lit () =
  test "unit" "let arr = #[#[1, 2, 3], #[3, 4, 5]]"

let test_farray_inference () =
  test "unit"
    (* We cannot use string here, otherwise we would try to import the string
       module in type checking. *)
    "fun print_snd(arr) {ignore(arr#[1])}; print_snd(#[1, 2, 3]); \
     print_snd(#[['h', 'e', 'y'], ['h', 'i']])"

let test_syntax_elseif_no_else () =
  test "unit" "if false {()} else if false {()} else if true {()}"

let test_syntax_let_block () = test "unit" "let a = {let b = 0;   ()}"
let test_syntax_let_block_move () = test "unit" "let a = mov {let b = 0;   ()}"

let test_syntax_let_block_other_equal () =
  test "unit" "type record = {a : int}; let {a = b} = {let b = 0;   {a = 10}}"

let test_syntax_double_semicolon () = test "int" "let a = 1;\n ; a"

let test_syntax_multiline_variant () = test "unit" {|
type t =
  | A
  | B
|}

let test_syntax_multiline_variant_ctor_after () =
  test "t" {|
type t =
  | A
  | B

A
|}

let test_syntax_noparens_tuple () = test "(float, int)" "1.0, 1"

let test_syntax_minus_field () =
  test "int" "type a = { a : int }; let a = { a = 10 }; -a.a"

let test_syntax_pipe_curry_right () =
  test "int"
    {|fun four(a, b, c, d) {
  a + b + c + d
}

(10 |> four(12))(1, 2)|}

let test_syntax_pipe_curry_left () =
  test "int"
    {|fun cont(a, b) { a + b }
fun call(k, a) { k(a) }

cont(10) |> call(11)
|}

let test_rec_type_pos () =
  test "unit" "type list['a] = Nil | Cons('a, rc[list])"

let test_rec_type_pos_array () =
  test "unit" "type list['a] = Nil | Cons('a, array[list])"

let test_rec_type_noptr () =
  test_exn "Infinite type" "type list['a] = Cons('a, list)"

let test_rec_type_noptr_array () =
  test_exn "Infinite type" "type list['a] = Cons('a, array#1[list])"

let test_rec_type_nobase () =
  test_exn "Recursive type has no base case"
    "type list['a] = Cons('a, rc[list])"

let test_rec_type_record_param () =
  test "unit"
    {|type container['a] = { a : 'a }
type state = { data : container[fun (mut state) -> unit]}
let _ = { data = {a = fun(mut state) {ignore(state)}} }|}

let test_rec_type_record_param_nobase () =
  test_exn "Recursive type has no base case"
    {|type container['a] = { a : 'a }
type data['a] = { cb : 'a }
type state = { data : container[data[rc[state]]] }|}

let test_rec_type_record_fnreturn () =
  test "unit" "type t = { works : fun () -> t }"

let test_rec_type_record_fnboth () =
  test "unit" "type t = { works : fun (t) -> t }"

let test_rec_type_record_some_nobase () =
  test_exn "Recursive type has no base case"
    "type t = { works : fun () -> t, doesnt : rc[t]}"

let test_rec_type_record_variant_base () =
  test "unit"
    {|type option['a] = None | Some('a)
type t = { a : rc[option[t]] }|}

let test_rec_type_record_wrap () =
  test "unit"
    {|type option['a] = None | Some('a)
type wrap['a] = { a : option['a] }
type t = { a : rc[wrap[t]] }|}

let test_rec_type_record_wrap_norc () =
  test_exn "Infinite type"
    {|type option['a] = None | Some('a)
type wrap['a] = { a : option['a] }
type t = { a : option[wrap[t]] }|}

let test_rec_type_record_wrap_twice () =
  test "unit"
    {|type option['a] = None | Some('a)
type wrap['a] = { a : option['a] }
type t = { a : rc[wrap[wrap[t]]] }|}

let test_once_decl_let () =
  test "unit" "{let once foo = 10; __ignore_once(foo)}"

let test_once_decl_param () = test "unit" "fun foo (once p) {__ignore_once(p)}"

let test_once_wrong_mode_let () =
  test_exn "Unknown mode, expecting 'once', not 'nonce'"
    "{let nonce foo = 10; ()}"

let test_once_wrong_mode_param () =
  test_exn "Unknown mode, expecting 'once', not 'nonce'"
    "fun foo (nonce p) {()}"

let test_once_let_use_twice () =
  test_exn "Cannot use foo more than once"
    "{let once foo = 10; __ignore_once(foo); __ignore_once(foo)}"

let test_once_param_use_twice () =
  test_exn "Cannot use p more than once"
    "fun foo (once p) {__ignore_once(p); __ignore_once(p)}"

let test_once_use_once_borrows () =
  test "int" "{let once foo = 10; let once a = foo; a}"

let test_once_use_twice_borrows () =
  test_exn "Cannot use a more than once"
    "{let once foo = 10; let once a = foo; __ignore_once(a); a}"

let test_once_use_borrows_twice () =
  test_exn "Cannot pass once value a as many"
    "{let once foo = 10; let once a = foo; let b = a; ignore(b)}"

let test_once_use_twice_borrows_twice () =
  test_exn "Cannot use b more than once"
    "{let once foo = 10; let once a = foo; let once b = a; __ignore_once(b); b}"

let test_once_decl_unused_let () =
  test_exn "Value foo has not been used once" "{let once foo = 10; ()}"

let test_once_decl_unused_param () =
  test_exn "Value p has not been used once" "fun foo (once p) {()}"

let test_once_unused_borrow () =
  test_exn "Value b has not been used once"
    "{let once foo = 10; let once a = foo; let once b = a; ()}"

let test_once_print () =
  test "fun (once 'a) -> unit" "fun foo (once p) {__ignore_once(p)}; {(); foo}"

let test_once_pass () =
  test_exn "Cannot pass once value foo as many"
    {|{
fun ignore(many p) { ignore(p) }
  let once foo = 10
  ignore(foo)
}|}

let test_once_toplevel () =
  test_exn "Cannot declare once value at toplevel" "let once foo = 10"

let test_once_apply_fun_annot () =
  test "fun (once fun ('a) -> 'b, 'a) -> 'b" "fun (once f, arg) {f(arg)}"

let test_once_apply_func_annot_many () =
  test "fun (fun ('a) -> 'b, 'a) -> 'b" "fun (many func, arg) { func(arg) }"

let test_once_move_function () =
  test "fun (mov fun ('a) -> unit) -> t['a]"
    "type t['a] = { fn : fun ('a) -> unit }; fun (mov fn) { { fn } }"

let test_once_if () =
  test "fun (t, fun (int) -> int) -> int"
    {|type t = None | Some(int)
fun(v, f) {
  match v {
    None -> -1
    Some(i) -> f(i)
  }
}|}

let test_once_if_flipped () =
  test "fun (t, fun (int) -> int) -> int"
    {|type t = None | Some(int)
fun(v, f) {
  match v {
    Some(i) -> f(i)
    None -> -1
  }
}|}

let test_once_lambda_argument () =
  test "unit"
    {|fun apply(many f : fun (fun (once 'a) -> unit) -> unit) {
  f(fun (once i) {__ignore_once(i)})
}
apply(fun cb { cb(1) })|}

let test_once_signature_weak () =
  test "unit"
    {|signature {
  val f : fun(int, once fun (int) -> unit) -> unit
}
fun f(i : int, f) { -- TODO cannot just use return annotation
  f(i); ()
}|}

let test_once_recursive () =
  (* i cannot be once *)
  test_exn "Cannot pass once value i as many"
    {|fun rec foo(once i) {
  if true {
    foo(i)
  }
  else {
    __ignore_once(i)
  }
}
foo|}

let test_once_use_weak_once () =
  test "int" {|fun f(i, once f) { f(i) }
fun once(i) { i + 1 }
f(0, once)|}

let test_once_use_weak_many () =
  test "int" {|fun f(i, many f) { f(i) }
fun many(i) { i + 1 }
f(0, many)|}

let test_once_lambda_decl () =
  test_exn "Cannot pass once value func as many"
    {|{
  fun f(i, many f) { f(i) }
  let once func = fun i { i + 1 }
  let i = 0
  f(i, func)
}|}

let subs = {|fun subs(borrow, once f) {
  f(borrow)
  ()
}
|}

let test_subs_parse () =
  test_exn
    "Cannot borrow from function call in let binding. Use let borrow form (let \
     _ <- expr())"
    ("{" ^ subs ^ "let a = subs(2); ()}; ()")

let test_subs_wrong_expr () =
  test_exn "Cannot use expression as borrow call"
    ("{ " ^ subs ^ "let a <- 12; () }; ()")

let test_subs_parse_tl () =
  (* This will fail in the future *)
  test_exn "Cannot return borrow at top level" (subs ^ "let a <- subs(2); ()")

let test_subs_borrow_bind () = test "unit" (subs ^ "{ let a <- subs(2); () }")

let test_subs_borrow_return_param () =
  test_exn "In borrow call expecting fun (_) -> int but found fun (_) -> unit"
    (subs ^ "{ let a <- subs(2); a }")

let test_subs_no_unit_param () =
  (* We get a borrow check error, not a parameter type or fn type error *)
  test "unit"
    {|fun higher_order(once fn) { fn(); () }
fun test(mov a) {
  let _ <- higher_order(); ()
}|}

let test_subs_no_unit_param_lit () =
  (* We get a borrow check error, not a parameter type or fn type error *)
  test "unit"
    {|fun higher_order(once fn) { fn(()); () }
fun test(mov a) {
  let () <- higher_order(); ()
}|}

let test_subs_move_once_fn () =
  test "unit"
    {|fun higher_order(once fn) { fn(); () }
fun test(mov a) {
  higher_order (fun () { __unsafe_leak(a) })
}
|}

let test_subs_move_once_fn_use_after () =
  test_exn "a was moved in line 7, cannot use"
    {|fun higher_order(once fn) { fn(); () }
fun test(mov a) {
  higher_order (fun () { __unsafe_leak(a) })
  ignore(a)
}
|}

let test_subs_move_once_borrowcall () =
  test "unit"
    {|fun higher_order(once fn) { fn(); () }
fun test(mov a) {
  let () <- higher_order()
  __unsafe_leak(a)
}
|}

let test_subs_move_once_borrowcall_use_after () =
  test_exn "a was moved in line 8, cannot use"
    {|fun higher_order(once fn) { fn(); () }
fun test(mov a) {
  let () <- higher_order()
  __unsafe_leak(a)
  ignore(a)
}
|}

let test_subs_return_from_call () =
  test "unit"
    {|fun higher_order(once fn) { fn() }
let returned = {
  let () <- higher_order()
  12
}
|}

let test_subs_use_in_expr () =
  test_exn
    "In application\n\
     expecting fun (once fun (unit) -> unit) -> _\n\
     but found fun () -> _"
    {|fun higher_order(once fn) { fn(); () }
ignore(higher_order())|}

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
          case "string ansi" test_const_string_ansi;
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
          case "unused rec" test_func_unused_rec;
          case "missing move known" test_func_missing_move_known;
          case "missing move unknown" test_func_missing_move_unknown;
          case "orphan poly" test_func_orphan_poly;
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
          case "rc" test_annot_rc;
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
          case "head_single call" test_pipe_head_single_call;
          case "head_multi_call" test_pipe_head_multi_call;
          case "head_single_wrong_type" test_pipe_head_single_wrong_type;
          case "head_mult" test_pipe_head_mult;
          case "head_mult_wrong_type" test_pipe_head_mult_wrong_type;
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
          case "nameclash" test_variants_nameclash;
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
          case "guard positive" test_match_guard_positive;
          case "guard after" test_match_guard_after;
          case "guard missing" test_match_guard_missing;
          case "guard missing spec" test_match_guard_missing_spec;
          case "guard no var leak" test_match_guard_dont_leak_vars;
          case "unit" test_match_unit;
          case "unit redundant" test_match_unit_redundant;
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
          case "abstract" test_signature_abstract;
          case "namespaces" test_signature_namespaces;
          case "after statement" test_signature_after_statement;
          case "not unique" test_signature_not_unique;
          case "concrete of generic alias"
            test_signature_concrete_of_generic_alias;
          case "generic of generic alias"
            test_signature_generic_of_generic_alias;
          case "deep_qvar_sg" test_signature_deep_qvar_sg;
          case "don't match qvar" test_signature_dont_match_qvar;
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
          case "parts don't reset part" test_excl_parts_dont_reset_part;
          case "parts reset part" test_excl_parts_reset_part;
          case "parts return whole after part move" test_excl_parts_return_whole;
          tase_exn "func mut borrow"
            (ln "a was borrowed in line %i, cannot mutate" 5)
            {|let mut a = 10
fun set_a(){
  mut a = 11}
{
  let b = a
  set_a()
  ignore(b)}|};
          tase_exn "func move" "Borrowed value a has been moved in line 7"
            {|fun hmm(){
  let mut a = [10]
  fun move_a(){ a }
  ignore(a)
  ignore(move_a)
  ignore(a)}|};
          tase_exn "closure mut borrow"
            (ln "a was borrowed in line %i, cannot mutate" 3)
            {|fun hmm() {
  let mut a = 10
  let set_a = fun (){ mut a = 11}
  mut a = 11
  set_a()
  mut a = 11}|};
          tase_exn "closure carry set"
            (ln "a was borrowed in line %i, cannot mutate" 3)
            (* If the 'set' attribute isn't carried, (set-a) cannot be called
               and a different error occurs *)
            {|fun hmm() {
  let mut a = [10]
  let set_a = fun () {mut a = [11]}
  mut a = [11]
  let mut x = mov a
  set_a()}|};
          tase_exn "excl 1"
            (ln "a was borrowed in line %i, cannot mutate" 4)
            "let mut a = [10]\n fun f(mut a, b) {mut \na = [11]}\n f(mut a, a)";
          tase "excl 1 nonalloc" "unit"
            "let mut a = 10\n\
            \ fun f(mut a, b) {mut \n\
             a = 11}\n\
            \ f(mut a, copy(a))";
          tase_exn "excl 2"
            (ln "a was borrowed in line %i, cannot mutate" 4)
            "let mut a = [10]\n\
            \ fun f(mut a, b) {mut a = [11]}\n\
            \ {\n\
            \  let b = a\n\
            \  f(mut a, b)}";
          tase_exn "excl 3"
            (ln "a was borrowed in line %i, cannot mutate" 3)
            "let mut a = [10]\n fun f(a, mut b) {mut b = [11]}\n f(a, mut a)";
          tase_exn "excl 4"
            (ln "a was borrowed in line %i, cannot mutate" 4)
            "let mut a = [10]\n\
            \ fun f(a, mut b) {mut b = [11]}\n\
            \ {\n\
            \  let b = a\n\
            \  f(b, mut a)}";
          tase "excl 5" "unit" "let mut a = [10]\n fun f(a, b) {()}\n f(a, a)";
          tase_exn "excl 6"
            (ln "a was borrowed in line %i, cannot mutate" 3)
            "let mut a = [10]\n fun f(mut a, mut b) {()}\n f(mut a, mut a)";
          tase_exn "excl env"
            (ln "a was borrowed in line %i, cannot mutate" 2)
            {|let mut a = [10]
fun set_a(mut b) {mut a = [11]}
set_a(mut a)|};
          tase "excl two phase" "unit"
            {|let mut a = [10]
fun push(mut a, mov b) {__unsafe_ptr_set(mut __array_data(a), 0, b)}
push(mut a, __array_length(a))|};
          tase_exn "follow string literal"
            "Borrowed string literal has been moved in line 5"
            "{let c = \"aoeu\"; let d = c; let mut e = mov d; ()}; ()";
          tase_exn "move local borrows"
            "Branches have different ownership: owned vs borrowed"
            {|let a = [10]
let c = {
  if true {
    let a = [10]
    a
  }else {
    a}}|};
          tase_exn "forbid move of cond borrow"
            "Cannot move conditional borrow. Either copy or directly move \
             conditional without borrowing"
            {|fun test() {
  let ai = [10]
  let bi = [11]
  let c = if false {ai} else {
      if true {bi} else {
        if true {ai} else {bi}}}
  c}|};
          tase_exn "specify mut passing"
            "Specify how rhs expression is passed. Either by move 'mov' or \
             mutably 'mut'"
            "{let mut a = [10]; let mut b = a; ()}";
          tase_exn "partially set moved"
            (ln "a was moved in line %i, cannot use a.[0]" 2)
            "let mut a = [10]\n let b = (a, 0); mut a.[0] = 10";
          tase_exn "track moved multi-borrow param"
            "Borrowed value s has been moved in line 8"
            {|fun test(mut s) {
  let a = s
  let c = a
  ignore((c, 0))}|};
          tase_exn "move binds individual"
            (ln "thing.value was moved in line %i, cannot use" 6)
            {|type data = {key : array[u8], value : array[u8]}
type data_container = Empty | Item(data)
fun hmm(mut thing) { match thing {
  Item({key, value}) -> {
    ignore((key, 0))
    ignore((value, 0))
    ignore((value, 0))}
  Empty -> ()}}|};
          tase_exn "move binds param"
            "Borrowed value thing.key has been moved in line 9"
            {|type data = {key : array[u8], value : array[u8]}
type data_container = Empty | Item(data)
fun hmm(mut thing) { match thing {
  Item({key, value}) -> {
    ignore((key, 0))
    ignore((value, 0))}
  Empty -> ()}}|};
          tase_exn "let pattern name"
            (ln "kee was moved in line %i, cannot use" 4)
            {|type data = {key : array[u8], value : array[u8]}
fun hmm() {
  let {key = kee, value} = mov {key = ['k', 'e', 'y'], value = ['v', 'a', 'l', 'u', 'e']}
  ignore((kee, 0))
  ignore((kee, 0))}|};
          tase_exn "track module outer toplevel"
            "Borrowed value a has been moved in line 5"
            "let a = [10]; module inner {let _ = (a, 0)}";
          tase_exn "track vars from inner module"
            "Borrowed value fst/a has been moved in line 5"
            "module fst {let a = [20]}; ignore([fst/a])";
          (* tase_exn "track vars from inner module use after move" *)
          (*   (ln "fst/a was moved in line %i, cannot use fst/a.[0]." 3) *)
          (*   "module fst {let a = [20]\n}\nignore([fst/a])\nignore(fst/a.[0])"; *)
          tase_exn "always borrow field"
            (ln "sm.free_hd was borrowed in line %i, cannot mutate" 7)
            {|type key = {idx : int, gen : int}
type t = {mut slots : array[key], mut data : array[int], mut free_hd : int, mut erase : array[int]}

{
  let mut sm = {slots = [], data = [], free_hd = -1, erase = []}
  let idx = 0
  let slot_idx = sm.free_hd
  let free_key = sm.slots.[slot_idx]
  let free_hd = copy(free_key.idx)
  let nextgen = free_key.gen + 1
  mut sm.slots.[slot_idx] = {idx, gen = nextgen}
  mut sm.free_hd = free_hd
  ignore({gen = nextgen, idx = slot_idx})}|};
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
          case "array mutate part" test_excl_array_mutate_part;
          case "move mut param lambda" test_excl_move_lambda;
          case "move mut param fun" test_excl_move_fun;
          case "move outer branch" test_excl_move_outer_branch;
          case "move outer branch else" test_excl_move_outer_branch_else;
          case "shadowing bug" test_excl_shadowing_bug;
          case "variant data" test_excl_variant_data;
          case "raw ptr" test_excl_raw_ptr;
          case "partial move set" test_excl_partial_move_set;
          case "mutate shadow" test_excl_mutate_shadow;
          case "nameclash" test_excl_regression_assert_on_insert;
          case "pass mutating function" test_excl_pass_mutating_function;
          case "not unchecked" test_excl_not_unchecked;
          case "unchecked" test_excl_unchecked;
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
          case "apply use sgn" test_functor_apply_use_sgn;
          case "abstract param" test_functor_abstract_param;
          case "use param type" test_functor_use_param_type;
          case "poly function" test_functor_poly_function;
          case "poly mismatch" test_functor_poly_mismatch;
          case "check sig" test_functor_check_sig;
          case "check sig param" test_functor_check_param;
          case "check sig concrete" test_functor_check_concrete;
          case "sgn-only type" test_functor_sgn_only_type;
          case "sgn reorder" test_functor_sgn_reorder;
        ] );
      ( "fixed-size array",
        [
          case "lit" test_farray_lit;
          case "lit trailing" test_farray_lit_trailing;
          case "nested lit" test_farray_nested_lit;
          case "generalize / instantiate" test_farray_inference;
        ] );
      ( "other syntax",
        [
          case "elseif no else" test_syntax_elseif_no_else;
          case "let block" test_syntax_let_block;
          case "let block move" test_syntax_let_block_move;
          case "let block other equal" test_syntax_let_block_other_equal;
          case "double semicolon" test_syntax_double_semicolon;
          case "multiline variant" test_syntax_multiline_variant;
          case "multiline variant ctor after"
            test_syntax_multiline_variant_ctor_after;
          case "noparens tuple" test_syntax_noparens_tuple;
          case "minus field" test_syntax_minus_field;
          case "pipe curry right" test_syntax_pipe_curry_right;
          case "pipe curry left" test_syntax_pipe_curry_left;
        ] );
      ( "recursive types",
        [
          case "pos" test_rec_type_pos;
          case "pos array" test_rec_type_pos_array;
          case "noptr" test_rec_type_noptr;
          case "noptr fixed array" test_rec_type_noptr_array;
          case "nobase" test_rec_type_nobase;
          case "record param" test_rec_type_record_param;
          case "record param nobase" test_rec_type_record_param_nobase;
          case "record fn return" test_rec_type_record_fnreturn;
          case "record fn both" test_rec_type_record_fnboth;
          case "record some nobase" test_rec_type_record_some_nobase;
          case "record variant base" test_rec_type_record_variant_base;
          case "record wrap" test_rec_type_record_wrap;
          case "record wrap no rc" test_rec_type_record_wrap_norc;
          case "record wrap twice" test_rec_type_record_wrap_twice;
        ] );
      ( "once",
        [
          case "decl let" test_once_decl_let;
          case "decl param" test_once_decl_param;
          case "wrong mode let" test_once_wrong_mode_let;
          case "wrong mode param" test_once_wrong_mode_param;
          case "let use twice" test_once_let_use_twice;
          case "param use twice" test_once_param_use_twice;
          case "once borrows" test_once_use_once_borrows;
          case "twice borrows" test_once_use_twice_borrows;
          case "borrows twice" test_once_use_borrows_twice;
          case "twice borrows twice" test_once_use_twice_borrows_twice;
          case "unused let" test_once_decl_unused_let;
          case "unused param" test_once_decl_unused_param;
          case "unused borrow" test_once_unused_borrow;
          case "print" test_once_print;
          case "pass" test_once_pass;
          case "toplevel" test_once_toplevel;
          case "apply fun annot" test_once_apply_fun_annot;
          case "apply fun annot many" test_once_apply_func_annot_many;
          case "move function" test_once_move_function;
          case "if" test_once_if;
          case "if flipped" test_once_if_flipped;
          case "lambda argument" test_once_lambda_argument;
          case "signature weak" test_once_signature_weak;
          case "use weak once" test_once_use_weak_once;
          case "use weak many" test_once_use_weak_many;
          case "lambda decl" test_once_lambda_decl;
        ] );
      ( "subscripts",
        [
          case "parse" test_subs_parse;
          case "parse toplevel" test_subs_parse_tl;
          case "wrong expr" test_subs_wrong_expr;
          case "borrow bind" test_subs_borrow_bind;
          case "borrow return param" test_subs_borrow_return_param;
          case "no/unit param" test_subs_no_unit_param;
          case "no/unit param lit" test_subs_no_unit_param_lit;
          case "move once fn" test_subs_move_once_fn;
          case "move once fn use after" test_subs_move_once_fn_use_after;
          case "move once borrowcall" test_subs_move_once_borrowcall;
          case "move once borrowcall use after"
            test_subs_move_once_borrowcall_use_after;
          case "return from call" test_subs_return_from_call;
          case "use in expr" test_subs_use_in_expr;
        ] );
    ]
