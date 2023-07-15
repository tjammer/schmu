Basic variant ctors
  $ schmu basic.smu --dump-llvm
  basic.smu:12:7: warning: Unused binding wrap_clike
  12 | (defn wrap_clike [] #c)
             ^^^^^^^^^^
  
  basic.smu:14:7: warning: Unused binding wrap_option
  14 | (defn wrap_option [] (#some "hello"))
             ^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %clike = type { i32 }
  %prelude.option_array_u8 = type { i32, i8* }
  %prelude.option_int = type { i32, i64 }
  %larger = type { i32, %foo }
  %foo = type { double, double }
  
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"hello\00" }
  
  define i32 @schmu_wrap_clike() {
  entry:
    %clike = alloca %clike, align 8
    %tag2 = bitcast %clike* %clike to i32*
    store i32 2, i32* %tag2, align 4
    ret i32 2
  }
  
  define void @schmu_wrap_option(%prelude.option_array_u8* %0) {
  entry:
    %tag1 = bitcast %prelude.option_array_u8* %0 to i32*
    store i32 0, i32* %tag1, align 4
    %data = getelementptr inbounds %prelude.option_array_u8, %prelude.option_array_u8* %0, i32 0, i32 1
    %1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*), i8** %1, align 8
    %2 = alloca i8*, align 8
    %3 = bitcast i8** %2 to i8*
    %4 = bitcast i8** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 8, i1 false)
    call void @__copy_ac(i8** %2)
    %5 = load i8*, i8** %2, align 8
    store i8* %5, i8** %data, align 8
    ret void
  }
  
  define internal void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz2 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %ref, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 16
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %option = alloca %prelude.option_int, align 8
    %tag5 = bitcast %prelude.option_int* %option to i32*
    store i32 0, i32* %tag5, align 4
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 8
    %larger = alloca %larger, align 8
    %tag16 = bitcast %larger* %larger to i32*
    store i32 2, i32* %tag16, align 4
    %data2 = getelementptr inbounds %larger, %larger* %larger, i32 0, i32 1
    %0 = bitcast %foo* %data2 to i64*
    store i64 3, i64* %0, align 8
    %clike = alloca %clike, align 8
    %tag47 = bitcast %clike* %clike to i32*
    store i32 2, i32* %tag47, align 4
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Basic pattern matching
  $ schmu match_option.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./match_option
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %prelude.option_int = type { i32, i64 }
  
  @schmu_none_int = global %prelude.option_int zeroinitializer, align 16
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @__prelude.optiong.i_schmu_none_all_prelude.optioni.i(%prelude.option_int* %p) {
  entry:
    %tag1 = bitcast %prelude.option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_match_opt(%prelude.option_int* %p) {
  entry:
    %tag1 = bitcast %prelude.option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_opt_match(%prelude.option_int* %p) {
  entry:
    %tag1 = bitcast %prelude.option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %0, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_some_all(%prelude.option_int* %p) {
  entry:
    %tag1 = bitcast %prelude.option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %option = alloca %prelude.option_int, align 8
    %tag16 = bitcast %prelude.option_int* %option to i32*
    store i32 0, i32* %tag16, align 4
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 8
    %0 = call i64 @schmu_match_opt(%prelude.option_int* %option)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %0)
    %option1 = alloca %prelude.option_int, align 8
    %tag217 = bitcast %prelude.option_int* %option1 to i32*
    store i32 1, i32* %tag217, align 4
    %1 = call i64 @schmu_match_opt(%prelude.option_int* %option1)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %1)
    %option3 = alloca %prelude.option_int, align 8
    %tag418 = bitcast %prelude.option_int* %option3 to i32*
    store i32 0, i32* %tag418, align 4
    %data5 = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option3, i32 0, i32 1
    store i64 1, i64* %data5, align 8
    %2 = call i64 @schmu_opt_match(%prelude.option_int* %option3)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %2)
    %option6 = alloca %prelude.option_int, align 8
    %tag719 = bitcast %prelude.option_int* %option6 to i32*
    store i32 1, i32* %tag719, align 4
    %3 = call i64 @schmu_opt_match(%prelude.option_int* %option6)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %3)
    %option8 = alloca %prelude.option_int, align 8
    %tag920 = bitcast %prelude.option_int* %option8 to i32*
    store i32 0, i32* %tag920, align 4
    %data10 = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option8, i32 0, i32 1
    store i64 1, i64* %data10, align 8
    %4 = call i64 @schmu_some_all(%prelude.option_int* %option8)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %4)
    %option11 = alloca %prelude.option_int, align 8
    %tag1221 = bitcast %prelude.option_int* %option11 to i32*
    store i32 1, i32* %tag1221, align 4
    %5 = call i64 @schmu_some_all(%prelude.option_int* %option11)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %5)
    %option13 = alloca %prelude.option_int, align 8
    %tag1422 = bitcast %prelude.option_int* %option13 to i32*
    store i32 0, i32* %tag1422, align 4
    %data15 = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option13, i32 0, i32 1
    store i64 1, i64* %data15, align 8
    %6 = call i64 @__prelude.optiong.i_schmu_none_all_prelude.optioni.i(%prelude.option_int* %option13)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %6)
    store i32 1, i32* getelementptr inbounds (%prelude.option_int, %prelude.option_int* @schmu_none_int, i32 0, i32 0), align 4
    %7 = call i64 @__prelude.optiong.i_schmu_none_all_prelude.optioni.i(%prelude.option_int* @schmu_none_int)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %7)
    ret i64 0
  }
  1
  0
  1
  0
  1
  0
  1
  0

Nested pattern matching
  $ schmu match_nested.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./match_nested
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %prelude.option_test = type { i32, %test }
  %test = type { i32, double }
  
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_doo(%prelude.option_test* %m) {
  entry:
    %tag17 = bitcast %prelude.option_test* %m to i32*
    %index = load i32, i32* %tag17, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont15
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_test, %prelude.option_test* %m, i32 0, i32 1
    %tag118 = bitcast %test* %data to i32*
    %index2 = load i32, i32* %tag118, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %0 = bitcast %prelude.option_test* %m to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %1 = bitcast i8* %sunkaddr to double*
    %2 = load double, double* %1, align 8
    %3 = fptosi double %2 to i64
    br label %ifcont15
  
  else:                                             ; preds = %then
    %eq8 = icmp eq i32 %index2, 1
    br i1 %eq8, label %then9, label %ifcont15
  
  then9:                                            ; preds = %else
    %4 = bitcast %prelude.option_test* %m to i8*
    %sunkaddr19 = getelementptr inbounds i8, i8* %4, i64 16
    %5 = bitcast i8* %sunkaddr19 to i64*
    %6 = load i64, i64* %5, align 8
    br label %ifcont15
  
  ifcont15:                                         ; preds = %entry, %then4, %else, %then9
    %iftmp16 = phi i64 [ %3, %then4 ], [ %6, %then9 ], [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp16
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %option = alloca %prelude.option_test, align 8
    %tag15 = bitcast %prelude.option_test* %option to i32*
    store i32 0, i32* %tag15, align 4
    %data = getelementptr inbounds %prelude.option_test, %prelude.option_test* %option, i32 0, i32 1
    %tag116 = bitcast %test* %data to i32*
    store i32 0, i32* %tag116, align 4
    %data2 = getelementptr inbounds %test, %test* %data, i32 0, i32 1
    store double 3.000000e+00, double* %data2, align 8
    %0 = call i64 @schmu_doo(%prelude.option_test* %option)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %0)
    %option3 = alloca %prelude.option_test, align 8
    %tag417 = bitcast %prelude.option_test* %option3 to i32*
    store i32 0, i32* %tag417, align 4
    %data5 = getelementptr inbounds %prelude.option_test, %prelude.option_test* %option3, i32 0, i32 1
    %tag618 = bitcast %test* %data5 to i32*
    store i32 1, i32* %tag618, align 4
    %data7 = getelementptr inbounds %test, %test* %data5, i32 0, i32 1
    %1 = bitcast double* %data7 to i64*
    store i64 2, i64* %1, align 8
    %2 = call i64 @schmu_doo(%prelude.option_test* %option3)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %2)
    %option9 = alloca %prelude.option_test, align 8
    %tag1019 = bitcast %prelude.option_test* %option9 to i32*
    store i32 0, i32* %tag1019, align 4
    %data11 = getelementptr inbounds %prelude.option_test, %prelude.option_test* %option9, i32 0, i32 1
    %tag1220 = bitcast %test* %data11 to i32*
    store i32 2, i32* %tag1220, align 4
    %3 = call i64 @schmu_doo(%prelude.option_test* %option9)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %3)
    %option13 = alloca %prelude.option_test, align 8
    %tag1421 = bitcast %prelude.option_test* %option13 to i32*
    store i32 1, i32* %tag1421, align 4
    %4 = call i64 @schmu_doo(%prelude.option_test* %option13)
    call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %4)
    ret i64 0
  }
  3
  2
  1
  0

Match multiple columns
  $ schmu tuple_match.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./tuple_match
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %prelude.option_int = type { i32, i64 }
  %tuple_prelude.option_int_prelude.option_int = type { %prelude.option_int, %prelude.option_int }
  
  @schmu_none_int = global %prelude.option_int zeroinitializer, align 16
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define void @schmu_doo(%prelude.option_int* %a, %prelude.option_int* %b) {
  entry:
    %0 = alloca %tuple_prelude.option_int_prelude.option_int, align 8
    %"017" = bitcast %tuple_prelude.option_int_prelude.option_int* %0 to %prelude.option_int*
    %1 = bitcast %prelude.option_int* %"017" to i8*
    %2 = bitcast %prelude.option_int* %a to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 16, i1 false)
    %"1" = getelementptr inbounds %tuple_prelude.option_int_prelude.option_int, %tuple_prelude.option_int_prelude.option_int* %0, i32 0, i32 1
    %3 = bitcast %prelude.option_int* %"1" to i8*
    %4 = bitcast %prelude.option_int* %b to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 16, i1 false)
    %tag18 = bitcast %prelude.option_int* %"1" to i32*
    %index = load i32, i32* %tag18, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else6
  
  then:                                             ; preds = %entry
    %5 = bitcast %tuple_prelude.option_int_prelude.option_int* %0 to %prelude.option_int*
    %tag119 = bitcast %prelude.option_int* %5 to i32*
    %index2 = load i32, i32* %tag119, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %6 = bitcast %tuple_prelude.option_int_prelude.option_int* %0 to %prelude.option_int*
    %data5 = getelementptr inbounds %prelude.option_int, %prelude.option_int* %6, i32 0, i32 1
    %7 = load i64, i64* %data5, align 8
    %8 = bitcast %tuple_prelude.option_int_prelude.option_int* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %8, i64 24
    %9 = bitcast i8* %sunkaddr to i64*
    %10 = load i64, i64* %9, align 8
    %add = add i64 %7, %10
    br label %ifcont15
  
  else:                                             ; preds = %then
    %11 = bitcast %tuple_prelude.option_int_prelude.option_int* %0 to i8*
    %sunkaddr20 = getelementptr inbounds i8, i8* %11, i64 24
    %12 = bitcast i8* %sunkaddr20 to i64*
    %13 = load i64, i64* %12, align 8
    br label %ifcont15
  
  else6:                                            ; preds = %entry
    %14 = bitcast %tuple_prelude.option_int_prelude.option_int* %0 to %prelude.option_int*
    %tag721 = bitcast %prelude.option_int* %14 to i32*
    %index8 = load i32, i32* %tag721, align 4
    %eq9 = icmp eq i32 %index8, 0
    br i1 %eq9, label %then10, label %ifcont15
  
  then10:                                           ; preds = %else6
    %15 = bitcast %tuple_prelude.option_int_prelude.option_int* %0 to %prelude.option_int*
    %data11 = getelementptr inbounds %prelude.option_int, %prelude.option_int* %15, i32 0, i32 1
    %16 = load i64, i64* %data11, align 8
    br label %ifcont15
  
  ifcont15:                                         ; preds = %then10, %else6, %then4, %else
    %iftmp16 = phi i64 [ %add, %then4 ], [ %13, %else ], [ %16, %then10 ], [ 0, %else6 ]
    tail call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %iftmp16)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    store i32 1, i32* getelementptr inbounds (%prelude.option_int, %prelude.option_int* @schmu_none_int, i32 0, i32 0), align 4
    %option = alloca %prelude.option_int, align 8
    %tag14 = bitcast %prelude.option_int* %option to i32*
    store i32 0, i32* %tag14, align 4
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 8
    %option1 = alloca %prelude.option_int, align 8
    %tag215 = bitcast %prelude.option_int* %option1 to i32*
    store i32 0, i32* %tag215, align 4
    %data3 = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option1, i32 0, i32 1
    store i64 2, i64* %data3, align 8
    call void @schmu_doo(%prelude.option_int* %option, %prelude.option_int* %option1)
    %option4 = alloca %prelude.option_int, align 8
    %tag516 = bitcast %prelude.option_int* %option4 to i32*
    store i32 0, i32* %tag516, align 4
    %data6 = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option4, i32 0, i32 1
    store i64 2, i64* %data6, align 8
    call void @schmu_doo(%prelude.option_int* @schmu_none_int, %prelude.option_int* %option4)
    %option7 = alloca %prelude.option_int, align 8
    %tag817 = bitcast %prelude.option_int* %option7 to i32*
    store i32 0, i32* %tag817, align 4
    %data9 = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option7, i32 0, i32 1
    store i64 1, i64* %data9, align 8
    %option10 = alloca %prelude.option_int, align 8
    %tag1118 = bitcast %prelude.option_int* %option10 to i32*
    store i32 1, i32* %tag1118, align 4
    call void @schmu_doo(%prelude.option_int* %option7, %prelude.option_int* %option10)
    %option12 = alloca %prelude.option_int, align 8
    %tag1319 = bitcast %prelude.option_int* %option12 to i32*
    store i32 1, i32* %tag1319, align 4
    call void @schmu_doo(%prelude.option_int* @schmu_none_int, %prelude.option_int* %option12)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  3
  2
  1
  0

  $ schmu custom_tag_reuse.smu
  custom_tag_reuse.smu:1:28: error: Tag 1 already used for constructor a
  1 | (type tags ((#a 1) (#b 0) (#c int)))
                                 ^^
  
  [1]

Record literals in pattern matches
  $ schmu match_record.smu && valgrind -q --leak-check=yes --show-reachable=yes ./match_record
  match_record.smu:5:35: warning: Unused binding b
  5 |             ((#some {:a (#some a) :b}) a)
                                        ^^
  
  match_record.smu:6:31: warning: Unused binding b
  6 |             ((#some {:a #none :b}) -1)
                                    ^^
  
  10
  -1
  20
  -2
