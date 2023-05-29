Copy string literal
  $ schmu --dump-llvm string_lit.smu && valgrind -q --leak-check=yes --show-reachable=yes ./string_lit
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr global { i64, i64, i64, [6 x i8] } { i64 2, i64 5, i64 5, [6 x i8] c"test \00" }
  @1 = private unnamed_addr global { i64, i64, i64, [7 x i8] } { i64 2, i64 6, i64 6, [7 x i8] c"%s%li\0A\00" }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** %str, align 8
    %0 = alloca i8*, align 8
    %1 = bitcast i8** %0 to i8*
    %2 = bitcast i8** %str to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    call void @__copy_ac(i8** %0)
    %3 = load i8*, i8** %0, align 8
    %4 = getelementptr i8, i8* %3, i64 24
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [7 x i8] }* @1 to i8*), i64 24), i8* %4, i64 1)
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
  ==8299== 30 bytes in 1 blocks are definitely lost in loss record 1 of 1
  ==8299==    at 0x484386F: malloc (vg_replace_malloc.c:393)
  ==8299==    by 0x4011DE: __copy_ac (in $TESTCASE_ROOT/string_lit)
  ==8299==    by 0x40118E: main (in $TESTCASE_ROOT/string_lit)
  ==8299== 

Copy array of strings
  $ schmu --dump-llvm arr_of_strings.smu && valgrind -q --leak-check=yes --show-reachable=yes ./arr_of_strings
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global i8** null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [5 x i8] } { i64 2, i64 4, i64 4, [5 x i8] c"test\00" }
  @1 = private unnamed_addr global { i64, i64, i64, [6 x i8] } { i64 2, i64 5, i64 5, [6 x i8] c"toast\00" }
  
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
    store i8* bitcast ({ i64, i64, i64, [5 x i8] }* @0 to i8*), i8** %data, align 8
    tail call void @__incr_rc_ac(i8* bitcast ({ i64, i64, i64, [5 x i8] }* @0 to i8*))
    %"1" = getelementptr i8*, i8** %data, i64 1
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @1 to i8*), i8** %"1", align 8
    tail call void @__incr_rc_ac(i8* bitcast ({ i64, i64, i64, [6 x i8] }* @1 to i8*))
    %4 = alloca i8**, align 8
    %5 = bitcast i8*** %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* bitcast (i8*** @schmu_a to i8*), i64 8, i1 false)
    call void @__copy_aac(i8*** %4)
    %6 = load i8**, i8*** %4, align 8
    %7 = bitcast i8** %6 to i8*
    %8 = getelementptr i8, i8* %7, i64 32
    %data1 = bitcast i8* %8 to i8**
    %9 = load i8*, i8** %data1, align 8
    call void @prelude_print(i8* %9)
    %10 = load i8**, i8*** @schmu_a, align 8
    call void @__decr_rc_aac(i8** %10)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__incr_rc_ac(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 8
    ret void
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
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__decr_rc_aac(i8** %0) {
  entry:
    %ref = bitcast i8** %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8** %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8** %0 to i64*
    %sz = getelementptr i64, i64* %5, i64 1
    %size = load i64, i64* %sz, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %6 = load i64, i64* %cnt, align 8
    %7 = icmp slt i64 %6, %size
    br i1 %7, label %child, label %cont
  
  child:                                            ; preds = %rec
    %8 = bitcast i8** %0 to i8*
    %9 = mul i64 8, %6
    %10 = add i64 24, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data = bitcast i8* %11 to i8**
    %12 = load i8*, i8** %data, align 8
    call void @__decr_rc_ac(i8* %12)
    %13 = add i64 %6, 1
    store i64 %13, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %14 = bitcast i8** %0 to i64*
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    br label %merge
  }
  
  define internal void @__decr_rc_ac(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  toast
  ==8310== 40 bytes in 1 blocks are definitely lost in loss record 1 of 2
  ==8310==    at 0x484386F: malloc (vg_replace_malloc.c:393)
  ==8310==    by 0x401277: __copy_aac (in $TESTCASE_ROOT/arr_of_strings)
  ==8310==    by 0x4011D0: main (in $TESTCASE_ROOT/arr_of_strings)
  ==8310== 
  ==8310== 59 bytes in 2 blocks are definitely lost in loss record 2 of 2
  ==8310==    at 0x484386F: malloc (vg_replace_malloc.c:393)
  ==8310==    by 0x40121E: __copy_ac (in $TESTCASE_ROOT/arr_of_strings)
  ==8310==    by 0x4012B3: __copy_aac (in $TESTCASE_ROOT/arr_of_strings)
  ==8310==    by 0x4011D0: main (in $TESTCASE_ROOT/arr_of_strings)
  ==8310== 

Copy records
  $ schmu --dump-llvm records.smu && valgrind -q --leak-check=yes --show-reachable=yes ./records
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %cont_t = type { %t }
  %t = type { double, i8*, i64, i64* }
  
  @schmu_a = global %cont_t zeroinitializer, align 32
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"lul\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store double 1.000000e+01, double* getelementptr inbounds (%cont_t, %cont_t* @schmu_a, i32 0, i32 0, i32 0), align 8
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    tail call void @__incr_rc_ac(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*))
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** getelementptr inbounds (%cont_t, %cont_t* @schmu_a, i32 0, i32 0, i32 1), align 8
    store i64 10, i64* getelementptr inbounds (%cont_t, %cont_t* @schmu_a, i32 0, i32 0, i32 2), align 8
    %0 = tail call i8* @malloc(i64 48)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 8
    %size = getelementptr i64, i64* %1, i64 1
    store i64 3, i64* %size, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 3, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %2 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    %"2" = getelementptr i64, i64* %data, i64 2
    store i64 30, i64* %"2", align 8
    store i64* %1, i64** getelementptr inbounds (%cont_t, %cont_t* @schmu_a, i32 0, i32 0, i32 3), align 8
    %3 = alloca %cont_t, align 8
    %4 = bitcast %cont_t* %3 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* bitcast (%cont_t* @schmu_a to i8*), i64 32, i1 false)
    call void @__copy_contt(%cont_t* %3)
    %5 = bitcast %cont_t* %3 to %t*
    %6 = getelementptr inbounds %t, %t* %5, i32 0, i32 1
    %7 = load i8*, i8** %6, align 8
    call void @prelude_print(i8* %7)
    call void @__decr_rc_contt(%cont_t* @schmu_a)
    ret i64 0
  }
  
  define internal void @__incr_rc_ac(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 8
    ret void
  }
  
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
  
  define internal void @__copy_contt(%cont_t* %0) {
  entry:
    %1 = bitcast %cont_t* %0 to %t*
    call void @__copy_t(%t* %1)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__decr_rc_contt(%cont_t* %0) {
  entry:
    %1 = bitcast %cont_t* %0 to %t*
    %2 = getelementptr inbounds %t, %t* %1, i32 0, i32 1
    %3 = load i8*, i8** %2, align 8
    %ref = bitcast i8* %3 to i64*
    %ref18 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref18, align 8
    %4 = icmp eq i64 %ref2, 1
    br i1 %4, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %5 = bitcast i8* %3 to i64*
    %6 = bitcast i64* %5 to i64*
    %7 = sub i64 %ref2, 1
    store i64 %7, i64* %6, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %8 = bitcast i8* %3 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    %10 = bitcast %cont_t* %0 to %t*
    %11 = getelementptr inbounds %t, %t* %10, i32 0, i32 3
    %12 = load i64*, i64** %11, align 8
    %ref39 = bitcast i64* %12 to i64*
    %ref4 = load i64, i64* %ref39, align 8
    %13 = icmp eq i64 %ref4, 1
    br i1 %13, label %free6, label %decr5
  
  decr5:                                            ; preds = %merge
    %14 = bitcast i64* %12 to i64*
    %15 = sub i64 %ref4, 1
    store i64 %15, i64* %14, align 8
    br label %merge7
  
  free6:                                            ; preds = %merge
    %16 = bitcast i64* %12 to i8*
    call void @free(i8* %16)
    br label %merge7
  
  merge7:                                           ; preds = %free6, %decr5
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  lul
  ==8321== 28 bytes in 1 blocks are definitely lost in loss record 1 of 2
  ==8321==    at 0x484386F: malloc (vg_replace_malloc.c:393)
  ==8321==    by 0x4012CE: __copy_ac (in $TESTCASE_ROOT/records)
  ==8321==    by 0x40124C: __copy_t (in $TESTCASE_ROOT/records)
  ==8321==    by 0x401305: __copy_contt (in $TESTCASE_ROOT/records)
  ==8321==    by 0x40120D: main (in $TESTCASE_ROOT/records)
  ==8321== 
  ==8321== 48 bytes in 1 blocks are definitely lost in loss record 2 of 2
  ==8321==    at 0x484386F: malloc (vg_replace_malloc.c:393)
  ==8321==    by 0x401282: __copy_ai (in $TESTCASE_ROOT/records)
  ==8321==    by 0x401258: __copy_t (in $TESTCASE_ROOT/records)
  ==8321==    by 0x401305: __copy_contt (in $TESTCASE_ROOT/records)
  ==8321==    by 0x40120D: main (in $TESTCASE_ROOT/records)
  ==8321== 

Copy variants
  $ schmu variants.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./variants
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %prelude.option_tuple_array_u8 = type { i32, %tuple_array_u8 }
  %tuple_array_u8 = type { i8* }
  
  @schmu_a = global %prelude.option_tuple_array_u8 zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [6 x i8] } { i64 2, i64 5, i64 5, [6 x i8] c"thing\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i32 0, i32* getelementptr inbounds (%prelude.option_tuple_array_u8, %prelude.option_tuple_array_u8* @schmu_a, i32 0, i32 0), align 4
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** %str, align 8
    tail call void @__incr_rc_ac(i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*))
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** getelementptr inbounds (%prelude.option_tuple_array_u8, %prelude.option_tuple_array_u8* @schmu_a, i32 0, i32 1, i32 0), align 8
    %0 = alloca %prelude.option_tuple_array_u8, align 8
    %1 = bitcast %prelude.option_tuple_array_u8* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* bitcast (%prelude.option_tuple_array_u8* @schmu_a to i8*), i64 16, i1 false)
    call void @__copy_prelude.optiontup-ac(%prelude.option_tuple_array_u8* %0)
    %tag1 = bitcast %prelude.option_tuple_array_u8* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_tuple_array_u8, %prelude.option_tuple_array_u8* %0, i32 0, i32 1
    %2 = bitcast %tuple_array_u8* %data to i8**
    %3 = load i8*, i8** %2, align 8
    call void @__incr_rc_ac(i8* %3)
    %4 = load i8*, i8** %2, align 8
    call void @prelude_print(i8* %4)
    %5 = load i8*, i8** %2, align 8
    call void @__decr_rc_ac(i8* %5)
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    call void @__decr_rc_prelude.optiontup-ac(%prelude.option_tuple_array_u8* @schmu_a)
    ret i64 0
  }
  
  define internal void @__incr_rc_ac(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 8
    ret void
  }
  
  define internal void @__copy_tup-ac(%tuple_array_u8* %0) {
  entry:
    %1 = bitcast %tuple_array_u8* %0 to i8**
    call void @__copy_ac(i8** %1)
    ret void
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
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__decr_rc_ac(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__decr_rc_prelude.optiontup-ac(%prelude.option_tuple_array_u8* %0) {
  entry:
    %tag3 = bitcast %prelude.option_tuple_array_u8* %0 to i32*
    %index = load i32, i32* %tag3, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %prelude.option_tuple_array_u8, %prelude.option_tuple_array_u8* %0, i32 0, i32 1
    %2 = bitcast %tuple_array_u8* %data to i8**
    %3 = load i8*, i8** %2, align 8
    %ref = bitcast i8* %3 to i64*
    %ref14 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref14, align 8
    %4 = icmp eq i64 %ref2, 1
    br i1 %4, label %free, label %decr
  
  cont:                                             ; preds = %decr, %free, %entry
    ret void
  
  decr:                                             ; preds = %match
    %5 = bitcast i8* %3 to i64*
    %6 = bitcast i64* %5 to i64*
    %7 = sub i64 %ref2, 1
    store i64 %7, i64* %6, align 8
    br label %cont
  
  free:                                             ; preds = %match
    %8 = bitcast i8* %3 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    br label %cont
  }
  
  declare void @free(i8* %0)
  
  declare i8* @malloc(i64 %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  thing
  ==8332== 30 bytes in 1 blocks are definitely lost in loss record 1 of 1
  ==8332==    at 0x484386F: malloc (vg_replace_malloc.c:393)
  ==8332==    by 0x40122E: __copy_ac (in $TESTCASE_ROOT/variants)
  ==8332==    by 0x401205: __copy_tup-ac (in $TESTCASE_ROOT/variants)
  ==8332==    by 0x401270: __copy_prelude.optiontup-ac (in $TESTCASE_ROOT/variants)
  ==8332==    by 0x4011B3: main (in $TESTCASE_ROOT/variants)
  ==8332== 
