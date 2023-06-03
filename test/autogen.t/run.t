Copy string literal
  $ schmu --dump-llvm string_lit.smu && valgrind -q --leak-check=yes --show-reachable=yes ./string_lit
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant { i64, i64, i64, [6 x i8] } { i64 1, i64 5, i64 5, [6 x i8] c"test \00" }
  @1 = private unnamed_addr constant { i64, i64, i64, [7 x i8] } { i64 1, i64 6, i64 6, [7 x i8] c"%s%li\0A\00" }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac(i8** %1)
    %4 = load i8*, i8** %1, align 8
    %5 = getelementptr i8, i8* %4, i64 24
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [7 x i8] }* @1 to i8*), i64 24), i8* %5, i64 1)
    ret i64 0
  }
  
  define internal void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %ref, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 25
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 24
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(i8* %0, ...)
  
  declare i8* @malloc(i64 %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  test 1
  ==16649== 30 bytes in 1 blocks are definitely lost in loss record 1 of 1
  ==16649==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16649==    by 0x4011DE: __copy_ac (in $TESTCASE_ROOT/string_lit)
  ==16649==    by 0x40118E: main (in $TESTCASE_ROOT/string_lit)
  ==16649== 

Copy array of strings
  $ schmu --dump-llvm arr_of_strings.smu && valgrind -q --leak-check=yes --show-reachable=yes ./arr_of_strings
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global i8** null, align 8
  @0 = private unnamed_addr constant { i64, i64, i64, [5 x i8] } { i64 1, i64 4, i64 4, [5 x i8] c"test\00" }
  @1 = private unnamed_addr constant { i64, i64, i64, [6 x i8] } { i64 1, i64 5, i64 5, [6 x i8] c"toast\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i8**
    store i8** %1, i8*** @schmu_a, align 8
    %2 = bitcast i8** %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %3 to i8**
    %4 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [5 x i8] }* @0 to i8*), i8** %4, align 8
    %5 = bitcast i8** %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %5, i64 8, i1 false)
    tail call void @__copy_ac(i8** %data)
    %"1" = getelementptr i8*, i8** %data, i64 1
    %6 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @1 to i8*), i8** %6, align 8
    %7 = bitcast i8** %"1" to i8*
    %8 = bitcast i8** %6 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* %8, i64 8, i1 false)
    tail call void @__copy_ac(i8** %"1")
    %9 = alloca i8**, align 8
    %10 = bitcast i8*** %9 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* bitcast (i8*** @schmu_a to i8*), i64 8, i1 false)
    call void @__copy_aac(i8*** %9)
    %11 = load i8**, i8*** %9, align 8
    %12 = bitcast i8** %11 to i8*
    %13 = getelementptr i8, i8* %12, i64 32
    %data1 = bitcast i8* %13 to i8**
    %14 = load i8*, i8** %data1, align 8
    call void @prelude_print(i8* %14)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %ref, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 25
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 24
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__copy_aac(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %ref, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 24
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i8**
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 24
    %8 = bitcast i8** %5 to i8*
    %9 = bitcast i8** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i8** %5, i8*** %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %10 = load i64, i64* %cnt, align 8
    %11 = icmp slt i64 %10, %size
    br i1 %11, label %child, label %cont
  
  child:                                            ; preds = %rec
    %12 = bitcast i8** %1 to i8*
    %13 = mul i64 8, %10
    %14 = add i64 24, %13
    %15 = getelementptr i8, i8* %12, i64 %14
    %data = bitcast i8* %15 to i8**
    call void @__copy_ac(i8** %data)
    %16 = add i64 %10, 1
    store i64 %16, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  toast
  ==16660== 29 bytes in 1 blocks are indirectly lost in loss record 1 of 5
  ==16660==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16660==    by 0x40120E: __copy_ac (in $TESTCASE_ROOT/arr_of_strings)
  ==16660==    by 0x4011AD: main (in $TESTCASE_ROOT/arr_of_strings)
  ==16660== 
  ==16660== 30 bytes in 1 blocks are indirectly lost in loss record 2 of 5
  ==16660==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16660==    by 0x40120E: __copy_ac (in $TESTCASE_ROOT/arr_of_strings)
  ==16660==    by 0x4011C9: main (in $TESTCASE_ROOT/arr_of_strings)
  ==16660== 
  ==16660== 40 bytes in 1 blocks are still reachable in loss record 3 of 5
  ==16660==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16660==    by 0x401170: main (in $TESTCASE_ROOT/arr_of_strings)
  ==16660== 
  ==16660== 59 bytes in 2 blocks are still reachable in loss record 4 of 5
  ==16660==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16660==    by 0x40120E: __copy_ac (in $TESTCASE_ROOT/arr_of_strings)
  ==16660==    by 0x4012A3: __copy_aac (in $TESTCASE_ROOT/arr_of_strings)
  ==16660==    by 0x4011D8: main (in $TESTCASE_ROOT/arr_of_strings)
  ==16660== 
  ==16660== 99 (40 direct, 59 indirect) bytes in 1 blocks are definitely lost in loss record 5 of 5
  ==16660==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16660==    by 0x401267: __copy_aac (in $TESTCASE_ROOT/arr_of_strings)
  ==16660==    by 0x4011D8: main (in $TESTCASE_ROOT/arr_of_strings)
  ==16660== 

Copy records
  $ schmu --dump-llvm records.smu && valgrind -q --leak-check=yes --show-reachable=yes ./records
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %cont_t = type { %t }
  %t = type { double, i8*, i64, i64* }
  
  @schmu_a = global %cont_t zeroinitializer, align 32
  @0 = private unnamed_addr constant { i64, i64, i64, [4 x i8] } { i64 1, i64 3, i64 3, [4 x i8] c"lul\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store double 1.000000e+01, double* getelementptr inbounds (%cont_t, %cont_t* @schmu_a, i32 0, i32 0, i32 0), align 8
    %0 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac(i8** %1)
    %4 = load i8*, i8** %1, align 8
    store i8* %4, i8** getelementptr inbounds (%cont_t, %cont_t* @schmu_a, i32 0, i32 0, i32 1), align 8
    store i64 10, i64* getelementptr inbounds (%cont_t, %cont_t* @schmu_a, i32 0, i32 0, i32 2), align 8
    %5 = call i8* @malloc(i64 48)
    %6 = bitcast i8* %5 to i64*
    %arr = alloca i64*, align 8
    store i64* %6, i64** %arr, align 8
    store i64 1, i64* %6, align 8
    %size = getelementptr i64, i64* %6, i64 1
    store i64 3, i64* %size, align 8
    %cap = getelementptr i64, i64* %6, i64 2
    store i64 3, i64* %cap, align 8
    %7 = getelementptr i8, i8* %5, i64 24
    %data = bitcast i8* %7 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    %"2" = getelementptr i64, i64* %data, i64 2
    store i64 30, i64* %"2", align 8
    store i64* %6, i64** getelementptr inbounds (%cont_t, %cont_t* @schmu_a, i32 0, i32 0, i32 3), align 8
    %8 = alloca %cont_t, align 8
    %9 = bitcast %cont_t* %8 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* bitcast (%cont_t* @schmu_a to i8*), i64 32, i1 false)
    call void @__copy_contt(%cont_t* %8)
    %10 = bitcast %cont_t* %8 to %t*
    %11 = getelementptr inbounds %t, %t* %10, i32 0, i32 1
    %12 = load i8*, i8** %11, align 8
    call void @prelude_print(i8* %12)
    ret i64 0
  }
  
  define internal void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %ref, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 25
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 24
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__copy_t(%t* %0) {
  entry:
    %1 = getelementptr inbounds %t, %t* %0, i32 0, i32 1
    call void @__copy_ac(i8** %1)
    %2 = getelementptr inbounds %t, %t* %0, i32 0, i32 3
    call void @__copy_ai(i64** %2)
    ret void
  }
  
  define internal void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 24
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 24
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define internal void @__copy_contt(%cont_t* %0) {
  entry:
    %1 = bitcast %cont_t* %0 to %t*
    call void @__copy_t(%t* %1)
    ret void
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  lul
  ==16671== 28 bytes in 1 blocks are still reachable in loss record 1 of 4
  ==16671==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16671==    by 0x40123E: __copy_ac (in $TESTCASE_ROOT/records)
  ==16671==    by 0x401193: main (in $TESTCASE_ROOT/records)
  ==16671== 
  ==16671== 28 bytes in 1 blocks are definitely lost in loss record 2 of 4
  ==16671==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16671==    by 0x40123E: __copy_ac (in $TESTCASE_ROOT/records)
  ==16671==    by 0x40127C: __copy_t (in $TESTCASE_ROOT/records)
  ==16671==    by 0x4012E5: __copy_contt (in $TESTCASE_ROOT/records)
  ==16671==    by 0x40120A: main (in $TESTCASE_ROOT/records)
  ==16671== 
  ==16671== 48 bytes in 1 blocks are still reachable in loss record 3 of 4
  ==16671==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16671==    by 0x4011AE: main (in $TESTCASE_ROOT/records)
  ==16671== 
  ==16671== 48 bytes in 1 blocks are definitely lost in loss record 4 of 4
  ==16671==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16671==    by 0x4012B2: __copy_ai (in $TESTCASE_ROOT/records)
  ==16671==    by 0x401288: __copy_t (in $TESTCASE_ROOT/records)
  ==16671==    by 0x4012E5: __copy_contt (in $TESTCASE_ROOT/records)
  ==16671==    by 0x40120A: main (in $TESTCASE_ROOT/records)
  ==16671== 

Copy variants
  $ schmu variants.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./variants
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %prelude.option_tuple_array_u8 = type { i32, %tuple_array_u8 }
  %tuple_array_u8 = type { i8* }
  
  @schmu_a = global %prelude.option_tuple_array_u8 zeroinitializer, align 16
  @0 = private unnamed_addr constant { i64, i64, i64, [6 x i8] } { i64 1, i64 5, i64 5, [6 x i8] c"thing\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i32 0, i32* getelementptr inbounds (%prelude.option_tuple_array_u8, %prelude.option_tuple_array_u8* @schmu_a, i32 0, i32 0), align 4
    %0 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac(i8** %1)
    %4 = load i8*, i8** %1, align 8
    store i8* %4, i8** getelementptr inbounds (%prelude.option_tuple_array_u8, %prelude.option_tuple_array_u8* @schmu_a, i32 0, i32 1, i32 0), align 8
    %5 = alloca %prelude.option_tuple_array_u8, align 8
    %6 = bitcast %prelude.option_tuple_array_u8* %5 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* bitcast (%prelude.option_tuple_array_u8* @schmu_a to i8*), i64 16, i1 false)
    call void @__copy_prelude.optiontup-ac(%prelude.option_tuple_array_u8* %5)
    %tag1 = bitcast %prelude.option_tuple_array_u8* %5 to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_tuple_array_u8, %prelude.option_tuple_array_u8* %5, i32 0, i32 1
    %7 = bitcast %tuple_array_u8* %data to i8**
    %8 = load i8*, i8** %7, align 8
    call void @prelude_print(i8* %8)
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret i64 0
  }
  
  define internal void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %ref, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 25
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 24
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__copy_tup-ac(%tuple_array_u8* %0) {
  entry:
    %1 = bitcast %tuple_array_u8* %0 to i8**
    call void @__copy_ac(i8** %1)
    ret void
  }
  
  define internal void @__copy_prelude.optiontup-ac(%prelude.option_tuple_array_u8* %0) {
  entry:
    %tag1 = bitcast %prelude.option_tuple_array_u8* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %prelude.option_tuple_array_u8, %prelude.option_tuple_array_u8* %0, i32 0, i32 1
    call void @__copy_tup-ac(%tuple_array_u8* %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  thing
  ==16682== 30 bytes in 1 blocks are still reachable in loss record 1 of 2
  ==16682==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16682==    by 0x4011EE: __copy_ac (in $TESTCASE_ROOT/variants)
  ==16682==    by 0x40118C: main (in $TESTCASE_ROOT/variants)
  ==16682== 
  ==16682== 30 bytes in 1 blocks are definitely lost in loss record 2 of 2
  ==16682==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16682==    by 0x4011EE: __copy_ac (in $TESTCASE_ROOT/variants)
  ==16682==    by 0x401225: __copy_tup-ac (in $TESTCASE_ROOT/variants)
  ==16682==    by 0x401240: __copy_prelude.optiontup-ac (in $TESTCASE_ROOT/variants)
  ==16682==    by 0x4011B0: main (in $TESTCASE_ROOT/variants)
  ==16682== 

Copy closures
  $ schmu --dump-llvm closure.smu && valgrind -q --leak-check=yes --show-reachable=yes ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %tuple_int = type { i64 }
  %tuple_fn_.int = type { %closure }
  %closure = type { i8*, i8* }
  
  @schmu___expr0 = internal constant %tuple_int { i64 1 }
  @schmu___expr0__2 = global %tuple_fn_.int zeroinitializer, align 16
  @schmu_c = global %closure zeroinitializer, align 16
  @0 = private unnamed_addr constant { i64, i64, i64, [6 x i8] } { i64 1, i64 5, i64 5, [6 x i8] c"hello\00" }
  
  declare void @prelude_print(i8* %0)
  
  define void @__fun_schmu0(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i8** }*
    %a = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr, i32 0, i32 2
    %a1 = load i8**, i8*** %a, align 8
    %1 = bitcast i8** %a1 to i8*
    %2 = getelementptr i8, i8* %1, i64 24
    %data = bitcast i8* %2 to i8**
    %3 = load i8*, i8** %data, align 8
    tail call void @prelude_print(i8* %3)
    ret void
  }
  
  define i64 @schmu_capture(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64 }*
    %a = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr, i32 0, i32 2
    %a1 = load i64, i64* %a, align 8
    %add = add i64 %a1, 1
    ret i64 %add
  }
  
  define void @schmu_hmm(%closure* %0) {
  entry:
    %funptr1 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i8*)* @schmu_capture to i8*), i8** %funptr1, align 8
    %1 = tail call i8* @malloc(i64 ptrtoint ({ i8*, i8*, i64 }* getelementptr ({ i8*, i8*, i64 }, { i8*, i8*, i64 }* null, i32 1) to i64))
    %clsr_schmu_capture = bitcast i8* %1 to { i8*, i8*, i64 }*
    %a = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr_schmu_capture, i32 0, i32 2
    store i64 1, i64* %a, align 8
    %ctor2 = bitcast { i8*, i8*, i64 }* %clsr_schmu_capture to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-i to i8*), i8** %ctor2, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr_schmu_capture, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %1, i8** %envptr, align 8
    ret void
  }
  
  define void @schmu_test(%closure* %0) {
  entry:
    %1 = tail call i8* @malloc(i64 32)
    %2 = bitcast i8* %1 to i8**
    %arr = alloca i8**, align 8
    store i8** %2, i8*** %arr, align 8
    %3 = bitcast i8** %2 to i64*
    store i64 1, i64* %3, align 8
    %size = getelementptr i64, i64* %3, i64 1
    store i64 1, i64* %size, align 8
    %cap = getelementptr i64, i64* %3, i64 2
    store i64 1, i64* %cap, align 8
    %4 = getelementptr i8, i8* %1, i64 24
    %data = bitcast i8* %4 to i8**
    %5 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** %5, align 8
    %6 = bitcast i8** %5 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %6, i64 8, i1 false)
    tail call void @__copy_ac(i8** %data)
    %funptr1 = bitcast %closure* %0 to i8**
    store i8* bitcast (void (i8*)* @__fun_schmu0 to i8*), i8** %funptr1, align 8
    %7 = tail call i8* @malloc(i64 ptrtoint ({ i8*, i8*, i8** }* getelementptr ({ i8*, i8*, i8** }, { i8*, i8*, i8** }* null, i32 1) to i64))
    %clsr___fun_schmu0 = bitcast i8* %7 to { i8*, i8*, i8** }*
    %8 = alloca i8**, align 8
    %9 = bitcast i8*** %8 to i8*
    %10 = bitcast i8*** %arr to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 8, i1 false)
    call void @__copy_aac(i8*** %8)
    %a = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr___fun_schmu0, i32 0, i32 2
    %11 = load i8**, i8*** %8, align 8
    store i8** %11, i8*** %a, align 8
    %ctor2 = bitcast { i8*, i8*, i8** }* %clsr___fun_schmu0 to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-aac to i8*), i8** %ctor2, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr___fun_schmu0, i32 0, i32 1
    store i8* bitcast (void (i8*)* @__dtor_tup-aac to i8*), i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %7, i8** %envptr, align 8
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal i8* @__ctor_tup-i(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64 }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, i64 }*
    %4 = bitcast { i8*, i8*, i64 }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64 }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %6 = bitcast { i8*, i8*, i64 }* %3 to i8*
    ret i8* %6
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %ref, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 25
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 24
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  define internal void @__copy_aac(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %ref, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 24
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i8**
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 24
    %8 = bitcast i8** %5 to i8*
    %9 = bitcast i8** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i8** %5, i8*** %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %10 = load i64, i64* %cnt, align 8
    %11 = icmp slt i64 %10, %size
    br i1 %11, label %child, label %cont
  
  child:                                            ; preds = %rec
    %12 = bitcast i8** %1 to i8*
    %13 = mul i64 8, %10
    %14 = add i64 24, %13
    %15 = getelementptr i8, i8* %12, i64 %14
    %data = bitcast i8* %15 to i8**
    call void @__copy_ac(i8** %data)
    %16 = add i64 %10, 1
    store i64 %16, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define internal i8* @__ctor_tup-aac(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i8** }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, i8** }*
    %4 = bitcast { i8*, i8*, i8** }* %3 to i8*
    %5 = bitcast { i8*, i8*, i8** }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %a = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %3, i32 0, i32 2
    call void @__copy_aac(i8*** %a)
    %6 = bitcast { i8*, i8*, i8** }* %3 to i8*
    ret i8* %6
  }
  
  define internal void @__dtor_tup-aac(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i8** }*
    %a = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %1, i32 0, i32 2
    call void @__free_aac(i8*** %a)
    call void @free(i8* %0)
    ret void
  }
  
  define internal void @__free_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define internal void @__free_aac(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast i8** %1 to i8*
    %5 = mul i64 8, %2
    %6 = add i64 24, %5
    %7 = getelementptr i8, i8* %4, i64 %6
    %data = bitcast i8* %7 to i8**
    call void @__free_ac(i8** %data)
    %8 = add i64 %2, 1
    store i64 %8, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %9 = bitcast i8** %1 to i64*
    %10 = bitcast i64* %9 to i8*
    call void @free(i8* %10)
    ret void
  }
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %ret = alloca %closure, align 8
    call void @schmu_hmm(%closure* %ret)
    %0 = bitcast %closure* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%tuple_fn_.int* @schmu___expr0__2 to i8*), i8* %0, i64 16, i1 false)
    call void @__copy_.i(%closure* getelementptr inbounds (%tuple_fn_.int, %tuple_fn_.int* @schmu___expr0__2, i32 0, i32 0))
    call void @schmu_test(%closure* @schmu_c)
    %1 = alloca %closure, align 8
    %2 = bitcast %closure* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* bitcast (%closure* @schmu_c to i8*), i64 16, i1 false)
    call void @__copy_.u(%closure* %1)
    %funcptr2 = bitcast %closure* %1 to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %1, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    call void %casttmp(i8* %loadtmp1)
    ret i64 0
  }
  
  define internal void @__copy_.i(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define internal void @__copy_.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  hello
  ==16693== 24 bytes in 1 blocks are still reachable in loss record 1 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x40127D: __ctor_tup-i (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x40149E: __copy_.i (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x40145B: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 24 bytes in 1 blocks are still reachable in loss record 2 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x40122C: schmu_test (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x40146A: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 24 bytes in 1 blocks are definitely lost in loss record 3 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x4011A7: schmu_hmm (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x40143E: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 30 bytes in 1 blocks are still reachable in loss record 4 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x4012BE: __copy_ac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x401353: __copy_aac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x4013A2: __ctor_tup-aac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x4014BE: __copy_.u (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x401479: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 30 bytes in 1 blocks are indirectly lost in loss record 5 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x4012BE: __copy_ac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x401218: schmu_test (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x40146A: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 30 bytes in 1 blocks are indirectly lost in loss record 6 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x4012BE: __copy_ac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x401353: __copy_aac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x401240: schmu_test (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x40146A: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 32 bytes in 1 blocks are still reachable in loss record 7 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x401317: __copy_aac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x401240: schmu_test (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x40146A: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 32 bytes in 1 blocks are indirectly lost in loss record 8 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x401317: __copy_aac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x4013A2: __ctor_tup-aac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x4014BE: __copy_.u (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x401479: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 62 (32 direct, 30 indirect) bytes in 1 blocks are definitely lost in loss record 9 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x4011E3: schmu_test (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x40146A: main (in $TESTCASE_ROOT/closure)
  ==16693== 
  ==16693== 86 (24 direct, 62 indirect) bytes in 1 blocks are definitely lost in loss record 10 of 10
  ==16693==    at 0x484382F: malloc (vg_replace_malloc.c:431)
  ==16693==    by 0x401380: __ctor_tup-aac (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x4014BE: __copy_.u (in $TESTCASE_ROOT/closure)
  ==16693==    by 0x401479: main (in $TESTCASE_ROOT/closure)
  ==16693== 

Copy string literal on move
  $ schmu copy_string_lit.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global i8** null, align 8
  @0 = private unnamed_addr constant { i64, i64, i64, [5 x i8] } { i64 1, i64 4, i64 4, [5 x i8] c"aoeu\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i8**
    store i8** %1, i8*** @schmu_a, align 8
    %2 = bitcast i8** %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %3 to i8**
    %4 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [5 x i8] }* @0 to i8*), i8** %4, align 8
    %5 = bitcast i8** %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %5, i64 8, i1 false)
    tail call void @__copy_ac(i8** %data)
    %6 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [5 x i8] }* @0 to i8*), i8** %6, align 8
    %7 = alloca i8*, align 8
    %8 = bitcast i8** %7 to i8*
    %9 = bitcast i8** %6 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 8, i1 false)
    call void @__copy_ac(i8** %7)
    %10 = load i8*, i8** %7, align 8
    %11 = getelementptr i8, i8* %10, i64 24
    %12 = getelementptr inbounds i8, i8* %11, i64 1
    store i8 105, i8* %12, align 1
    %13 = load i8*, i8** %7, align 8
    call void @prelude_print(i8* %13)
    call void @prelude_print(i8* bitcast ({ i64, i64, i64, [5 x i8] }* @0 to i8*))
    %14 = load i8**, i8*** @schmu_a, align 8
    %15 = bitcast i8** %14 to i8*
    %16 = getelementptr i8, i8* %15, i64 24
    %data1 = bitcast i8* %16 to i8**
    %17 = load i8*, i8** %data1, align 8
    call void @prelude_print(i8* %17)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz = getelementptr i64, i64* %ref, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %ref, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 25
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 24
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
