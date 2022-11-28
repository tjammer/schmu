Basic variant ctors
  $ schmu basic.smu --dump-llvm
  basic.smu:12:6: warning: Unused binding wrap_clike
  12 | (fun wrap_clike [] #c)
            ^^^^^^^^^^
  
  basic.smu:14:6: warning: Unused binding wrap_option
  14 | (fun wrap_option [] (#some "hello"))
            ^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %clike = type { i32 }
  %option_array_u8 = type { i32, i8* }
  %option_int = type { i32, i64 }
  %larger = type { i32, %foo }
  %foo = type { double, double }
  
  @0 = private unnamed_addr global { i64, i64, i64, [6 x i8] } { i64 2, i64 5, i64 5, [6 x i8] c"hello\00" }
  
  define i32 @schmu_wrap_clike() {
  entry:
    %clike = alloca %clike, align 8
    %tag2 = bitcast %clike* %clike to i32*
    store i32 2, i32* %tag2, align 4
    ret i32 2
  }
  
  define void @schmu_wrap_option(%option_array_u8* %0) {
  entry:
    %tag1 = bitcast %option_array_u8* %0 to i32*
    store i32 0, i32* %tag1, align 4
    %data = getelementptr inbounds %option_array_u8, %option_array_u8* %0, i32 0, i32 1
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** %str, align 8
    tail call void @__g.u_incr_rc_ac.u(i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*))
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** %data, align 8
    ret void
  }
  
  define internal void @__g.u_incr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 4
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %option = alloca %option_int, align 8
    %tag5 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag5, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 4
    %larger = alloca %larger, align 8
    %tag16 = bitcast %larger* %larger to i32*
    store i32 2, i32* %tag16, align 4
    %data2 = getelementptr inbounds %larger, %larger* %larger, i32 0, i32 1
    %0 = bitcast %foo* %data2 to i64*
    store i64 3, i64* %0, align 4
    %clike = alloca %clike, align 8
    %tag47 = bitcast %clike* %clike to i32*
    store i32 2, i32* %tag47, align 4
    ret i64 0
  }

Basic pattern matching
  $ schmu match_option.smu --dump-llvm && ./match_option
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_int = type { i32, i64 }
  
  @none_int = global %option_int zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 9, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu___optiong.i_none_all_optioni.i(%option_int* %p) {
  entry:
    %tag1 = bitcast %option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_match_opt(%option_int* %p) {
  entry:
    %tag1 = bitcast %option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_opt_match(%option_int* %p) {
  entry:
    %tag1 = bitcast %option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %0, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_some_all(%option_int* %p) {
  entry:
    %tag1 = bitcast %option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %option = alloca %option_int, align 8
    %tag23 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag23, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 4
    %0 = call i64 @schmu_match_opt(%option_int* %option)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str1, align 8
    %option2 = alloca %option_int, align 8
    %tag324 = bitcast %option_int* %option2 to i32*
    store i32 1, i32* %tag324, align 4
    %1 = call i64 @schmu_match_opt(%option_int* %option2)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    %str4 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str4, align 8
    %option5 = alloca %option_int, align 8
    %tag625 = bitcast %option_int* %option5 to i32*
    store i32 0, i32* %tag625, align 4
    %data7 = getelementptr inbounds %option_int, %option_int* %option5, i32 0, i32 1
    store i64 1, i64* %data7, align 4
    %2 = call i64 @schmu_opt_match(%option_int* %option5)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %2)
    %str8 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str8, align 8
    %option9 = alloca %option_int, align 8
    %tag1026 = bitcast %option_int* %option9 to i32*
    store i32 1, i32* %tag1026, align 4
    %3 = call i64 @schmu_opt_match(%option_int* %option9)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %3)
    %str11 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str11, align 8
    %option12 = alloca %option_int, align 8
    %tag1327 = bitcast %option_int* %option12 to i32*
    store i32 0, i32* %tag1327, align 4
    %data14 = getelementptr inbounds %option_int, %option_int* %option12, i32 0, i32 1
    store i64 1, i64* %data14, align 4
    %4 = call i64 @schmu_some_all(%option_int* %option12)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %4)
    %str15 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str15, align 8
    %option16 = alloca %option_int, align 8
    %tag1728 = bitcast %option_int* %option16 to i32*
    store i32 1, i32* %tag1728, align 4
    %5 = call i64 @schmu_some_all(%option_int* %option16)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %5)
    %str18 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str18, align 8
    %option19 = alloca %option_int, align 8
    %tag2029 = bitcast %option_int* %option19 to i32*
    store i32 0, i32* %tag2029, align 4
    %data21 = getelementptr inbounds %option_int, %option_int* %option19, i32 0, i32 1
    store i64 1, i64* %data21, align 4
    %6 = call i64 @schmu___optiong.i_none_all_optioni.i(%option_int* %option19)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %6)
    store i32 1, i32* getelementptr inbounds (%option_int, %option_int* @none_int, i32 0, i32 0), align 4
    %str22 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str22, align 8
    %7 = call i64 @schmu___optiong.i_none_all_optioni.i(%option_int* @none_int)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %7)
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
  $ schmu match_nested.smu --dump-llvm && ./match_nested
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_test = type { i32, %test }
  %test = type { i32, double }
  
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 5, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_doo(%option_test* %m) {
  entry:
    %tag17 = bitcast %option_test* %m to i32*
    %index = load i32, i32* %tag17, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont15
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_test, %option_test* %m, i32 0, i32 1
    %tag118 = bitcast %test* %data to i32*
    %index2 = load i32, i32* %tag118, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %0 = bitcast %option_test* %m to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %1 = bitcast i8* %sunkaddr to double*
    %2 = load double, double* %1, align 8
    %3 = fptosi double %2 to i64
    br label %ifcont15
  
  else:                                             ; preds = %then
    %eq8 = icmp eq i32 %index2, 1
    br i1 %eq8, label %then9, label %ifcont15
  
  then9:                                            ; preds = %else
    %4 = bitcast %option_test* %m to i8*
    %sunkaddr19 = getelementptr inbounds i8, i8* %4, i64 16
    %5 = bitcast i8* %sunkaddr19 to i64*
    %6 = load i64, i64* %5, align 4
    br label %ifcont15
  
  ifcont15:                                         ; preds = %entry, %then4, %else, %then9
    %iftmp16 = phi i64 [ %3, %then4 ], [ %6, %then9 ], [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp16
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %option = alloca %option_test, align 8
    %tag18 = bitcast %option_test* %option to i32*
    store i32 0, i32* %tag18, align 4
    %data = getelementptr inbounds %option_test, %option_test* %option, i32 0, i32 1
    %tag119 = bitcast %test* %data to i32*
    store i32 0, i32* %tag119, align 4
    %data2 = getelementptr inbounds %test, %test* %data, i32 0, i32 1
    store double 3.000000e+00, double* %data2, align 8
    %0 = call i64 @schmu_doo(%option_test* %option)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str3 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str3, align 8
    %option4 = alloca %option_test, align 8
    %tag520 = bitcast %option_test* %option4 to i32*
    store i32 0, i32* %tag520, align 4
    %data6 = getelementptr inbounds %option_test, %option_test* %option4, i32 0, i32 1
    %tag721 = bitcast %test* %data6 to i32*
    store i32 1, i32* %tag721, align 4
    %data8 = getelementptr inbounds %test, %test* %data6, i32 0, i32 1
    %1 = bitcast double* %data8 to i64*
    store i64 2, i64* %1, align 4
    %2 = call i64 @schmu_doo(%option_test* %option4)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %2)
    %str10 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str10, align 8
    %option11 = alloca %option_test, align 8
    %tag1222 = bitcast %option_test* %option11 to i32*
    store i32 0, i32* %tag1222, align 4
    %data13 = getelementptr inbounds %option_test, %option_test* %option11, i32 0, i32 1
    %tag1423 = bitcast %test* %data13 to i32*
    store i32 2, i32* %tag1423, align 4
    %3 = call i64 @schmu_doo(%option_test* %option11)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %3)
    %str15 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str15, align 8
    %option16 = alloca %option_test, align 8
    %tag1724 = bitcast %option_test* %option16 to i32*
    store i32 1, i32* %tag1724, align 4
    %4 = call i64 @schmu_doo(%option_test* %option16)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %4)
    ret i64 0
  }
  3
  2
  1
  0

Match multiple columns
  $ schmu tuple_match.smu --dump-llvm && ./tuple_match
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_int = type { i32, i64 }
  %tuple_option_int_option_int = type { %option_int, %option_int }
  
  @none_int = global %option_int zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define void @schmu_doo(%option_int* %a, %option_int* %b) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %0 = alloca %tuple_option_int_option_int, align 8
    %"017" = bitcast %tuple_option_int_option_int* %0 to %option_int*
    %1 = bitcast %option_int* %"017" to i8*
    %2 = bitcast %option_int* %a to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 16, i1 false)
    %"1" = getelementptr inbounds %tuple_option_int_option_int, %tuple_option_int_option_int* %0, i32 0, i32 1
    %3 = bitcast %option_int* %"1" to i8*
    %4 = bitcast %option_int* %b to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 16, i1 false)
    %tag18 = bitcast %option_int* %"1" to i32*
    %index = load i32, i32* %tag18, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else6
  
  then:                                             ; preds = %entry
    %5 = bitcast %tuple_option_int_option_int* %0 to %option_int*
    %tag119 = bitcast %option_int* %5 to i32*
    %index2 = load i32, i32* %tag119, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %6 = bitcast %tuple_option_int_option_int* %0 to %option_int*
    %data5 = getelementptr inbounds %option_int, %option_int* %6, i32 0, i32 1
    %7 = load i64, i64* %data5, align 4
    %8 = bitcast %tuple_option_int_option_int* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %8, i64 24
    %9 = bitcast i8* %sunkaddr to i64*
    %10 = load i64, i64* %9, align 4
    %add = add i64 %7, %10
    br label %ifcont15
  
  else:                                             ; preds = %then
    %11 = bitcast %tuple_option_int_option_int* %0 to i8*
    %sunkaddr20 = getelementptr inbounds i8, i8* %11, i64 24
    %12 = bitcast i8* %sunkaddr20 to i64*
    %13 = load i64, i64* %12, align 4
    br label %ifcont15
  
  else6:                                            ; preds = %entry
    %14 = bitcast %tuple_option_int_option_int* %0 to %option_int*
    %tag721 = bitcast %option_int* %14 to i32*
    %index8 = load i32, i32* %tag721, align 4
    %eq9 = icmp eq i32 %index8, 0
    br i1 %eq9, label %then10, label %ifcont15
  
  then10:                                           ; preds = %else6
    %15 = bitcast %tuple_option_int_option_int* %0 to %option_int*
    %data11 = getelementptr inbounds %option_int, %option_int* %15, i32 0, i32 1
    %16 = load i64, i64* %data11, align 4
    br label %ifcont15
  
  ifcont15:                                         ; preds = %then10, %else6, %then4, %else
    %iftmp16 = phi i64 [ %add, %then4 ], [ %13, %else ], [ %16, %then10 ], [ 0, %else6 ]
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %iftmp16)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    store i32 1, i32* getelementptr inbounds (%option_int, %option_int* @none_int, i32 0, i32 0), align 4
    %option = alloca %option_int, align 8
    %tag14 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag14, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 4
    %option1 = alloca %option_int, align 8
    %tag215 = bitcast %option_int* %option1 to i32*
    store i32 0, i32* %tag215, align 4
    %data3 = getelementptr inbounds %option_int, %option_int* %option1, i32 0, i32 1
    store i64 2, i64* %data3, align 4
    call void @schmu_doo(%option_int* %option, %option_int* %option1)
    %option4 = alloca %option_int, align 8
    %tag516 = bitcast %option_int* %option4 to i32*
    store i32 0, i32* %tag516, align 4
    %data6 = getelementptr inbounds %option_int, %option_int* %option4, i32 0, i32 1
    store i64 2, i64* %data6, align 4
    call void @schmu_doo(%option_int* @none_int, %option_int* %option4)
    %option7 = alloca %option_int, align 8
    %tag817 = bitcast %option_int* %option7 to i32*
    store i32 0, i32* %tag817, align 4
    %data9 = getelementptr inbounds %option_int, %option_int* %option7, i32 0, i32 1
    store i64 1, i64* %data9, align 4
    %option10 = alloca %option_int, align 8
    %tag1118 = bitcast %option_int* %option10 to i32*
    store i32 1, i32* %tag1118, align 4
    call void @schmu_doo(%option_int* %option7, %option_int* %option10)
    %option12 = alloca %option_int, align 8
    %tag1319 = bitcast %option_int* %option12 to i32*
    store i32 1, i32* %tag1319, align 4
    call void @schmu_doo(%option_int* @none_int, %option_int* %option12)
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
  $ schmu match_record.smu && ./match_record
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
