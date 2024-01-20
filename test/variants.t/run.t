Basic variant ctors
  $ schmu basic.smu --dump-llvm
  basic.smu:12.5-15: warning: Unused binding wrap_clike.
  
  12 | fun wrap_clike(): C
           ^^^^^^^^^^
  
  basic.smu:14.5-16: warning: Unused binding wrap_option.
  
  14 | fun wrap_option(): Some("hello")
           ^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %clike = type { i32 }
  %option.tac = type { i32, i8* }
  
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"hello\00" }
  
  define i32 @schmu_wrap_clike() {
  entry:
    %clike = alloca %clike, align 8
    store %clike { i32 2 }, %clike* %clike, align 4
    %unbox = bitcast %clike* %clike to i32*
    %unbox1 = load i32, i32* %unbox, align 4
    ret i32 %unbox1
  }
  
  define void @schmu_wrap_option(%option.tac* noalias %0) {
  entry:
    %tag1 = bitcast %option.tac* %0 to i32*
    store i32 0, i32* %tag1, align 4
    %data = getelementptr inbounds %option.tac, %option.tac* %0, i32 0, i32 1
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
  
  define linkonce_odr void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %newref = bitcast i8* %3 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Match option
  $ schmu match_option.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./match_option
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.ti = type { i32, i64 }
  
  @schmu_none_int = constant %option.ti { i32 1, i64 undef }
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define linkonce_odr i64 @__schmu_none_all_option.ti.i(%option.ti* %p) {
  entry:
    %tag1 = bitcast %option.ti* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_match_opt(%option.ti* %p) {
  entry:
    %tag1 = bitcast %option.ti* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.ti, %option.ti* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_opt_match(%option.ti* %p) {
  entry:
    %tag1 = bitcast %option.ti* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %data = getelementptr inbounds %option.ti, %option.ti* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %0, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_some_all(%option.ti* %p) {
  entry:
    %tag1 = bitcast %option.ti* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.ti, %option.ti* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 1 }, %option.ti* %boxconst, align 8
    %1 = call i64 @schmu_match_opt(%option.ti* %boxconst)
    call void @printf(i8* %0, i64 %1)
    %2 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst1 = alloca %option.ti, align 8
    store %option.ti { i32 1, i64 undef }, %option.ti* %boxconst1, align 8
    %3 = call i64 @schmu_match_opt(%option.ti* %boxconst1)
    call void @printf(i8* %2, i64 %3)
    %4 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst2 = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 1 }, %option.ti* %boxconst2, align 8
    %5 = call i64 @schmu_opt_match(%option.ti* %boxconst2)
    call void @printf(i8* %4, i64 %5)
    %6 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst3 = alloca %option.ti, align 8
    store %option.ti { i32 1, i64 undef }, %option.ti* %boxconst3, align 8
    %7 = call i64 @schmu_opt_match(%option.ti* %boxconst3)
    call void @printf(i8* %6, i64 %7)
    %8 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst4 = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 1 }, %option.ti* %boxconst4, align 8
    %9 = call i64 @schmu_some_all(%option.ti* %boxconst4)
    call void @printf(i8* %8, i64 %9)
    %10 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst5 = alloca %option.ti, align 8
    store %option.ti { i32 1, i64 undef }, %option.ti* %boxconst5, align 8
    %11 = call i64 @schmu_some_all(%option.ti* %boxconst5)
    call void @printf(i8* %10, i64 %11)
    %12 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst6 = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 1 }, %option.ti* %boxconst6, align 8
    %13 = call i64 @__schmu_none_all_option.ti.i(%option.ti* %boxconst6)
    call void @printf(i8* %12, i64 %13)
    %14 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %15 = call i64 @__schmu_none_all_option.ti.i(%option.ti* @schmu_none_int)
    call void @printf(i8* %14, i64 %15)
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
  
  %option.ttest = type { i32, %test }
  %test = type { i32, double }
  
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_doo(%option.ttest* %m) {
  entry:
    %tag17 = bitcast %option.ttest* %m to i32*
    %index = load i32, i32* %tag17, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont15
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.ttest, %option.ttest* %m, i32 0, i32 1
    %tag118 = bitcast %test* %data to i32*
    %index2 = load i32, i32* %tag118, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %0 = bitcast %option.ttest* %m to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %1 = bitcast i8* %sunkaddr to double*
    %2 = load double, double* %1, align 8
    %3 = fptosi double %2 to i64
    br label %ifcont15
  
  else:                                             ; preds = %then
    %eq8 = icmp eq i32 %index2, 1
    br i1 %eq8, label %then9, label %ifcont15
  
  then9:                                            ; preds = %else
    %4 = bitcast %option.ttest* %m to i8*
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
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst = alloca %option.ttest, align 8
    store %option.ttest { i32 0, %test { i32 0, double 3.000000e+00 } }, %option.ttest* %boxconst, align 8
    %1 = call i64 @schmu_doo(%option.ttest* %boxconst)
    call void @printf(i8* %0, i64 %1)
    %2 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst1 = alloca %option.ttest, align 8
    store %option.ttest { i32 0, %test { i32 1, double 9.881310e-324 } }, %option.ttest* %boxconst1, align 8
    %3 = call i64 @schmu_doo(%option.ttest* %boxconst1)
    call void @printf(i8* %2, i64 %3)
    %4 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst2 = alloca %option.ttest, align 8
    store %option.ttest { i32 0, %test { i32 2, double undef } }, %option.ttest* %boxconst2, align 8
    %5 = call i64 @schmu_doo(%option.ttest* %boxconst2)
    call void @printf(i8* %4, i64 %5)
    %6 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst3 = alloca %option.ttest, align 8
    store %option.ttest { i32 1, %test undef }, %option.ttest* %boxconst3, align 8
    %7 = call i64 @schmu_doo(%option.ttest* %boxconst3)
    call void @printf(i8* %6, i64 %7)
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
  
  %option.ti = type { i32, i64 }
  %tup-option.ti-option.ti = type { %option.ti, %option.ti }
  
  @schmu_none_int = constant %option.ti { i32 1, i64 undef }
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define void @schmu_doo(%option.ti* %a, %option.ti* %b) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %1 = alloca %tup-option.ti-option.ti, align 8
    %"017" = bitcast %tup-option.ti-option.ti* %1 to %option.ti*
    %2 = bitcast %option.ti* %"017" to i8*
    %3 = bitcast %option.ti* %a to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 16, i1 false)
    %"1" = getelementptr inbounds %tup-option.ti-option.ti, %tup-option.ti-option.ti* %1, i32 0, i32 1
    %4 = bitcast %option.ti* %"1" to i8*
    %5 = bitcast %option.ti* %b to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 16, i1 false)
    %tag18 = bitcast %option.ti* %"1" to i32*
    %index = load i32, i32* %tag18, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else6
  
  then:                                             ; preds = %entry
    %6 = bitcast %tup-option.ti-option.ti* %1 to %option.ti*
    %tag119 = bitcast %option.ti* %6 to i32*
    %index2 = load i32, i32* %tag119, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %7 = bitcast %tup-option.ti-option.ti* %1 to %option.ti*
    %data5 = getelementptr inbounds %option.ti, %option.ti* %7, i32 0, i32 1
    %8 = load i64, i64* %data5, align 8
    %9 = bitcast %tup-option.ti-option.ti* %1 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %9, i64 24
    %10 = bitcast i8* %sunkaddr to i64*
    %11 = load i64, i64* %10, align 8
    %add = add i64 %8, %11
    br label %ifcont15
  
  else:                                             ; preds = %then
    %12 = bitcast %tup-option.ti-option.ti* %1 to i8*
    %sunkaddr20 = getelementptr inbounds i8, i8* %12, i64 24
    %13 = bitcast i8* %sunkaddr20 to i64*
    %14 = load i64, i64* %13, align 8
    br label %ifcont15
  
  else6:                                            ; preds = %entry
    %15 = bitcast %tup-option.ti-option.ti* %1 to %option.ti*
    %tag721 = bitcast %option.ti* %15 to i32*
    %index8 = load i32, i32* %tag721, align 4
    %eq9 = icmp eq i32 %index8, 0
    br i1 %eq9, label %then10, label %ifcont15
  
  then10:                                           ; preds = %else6
    %16 = bitcast %tup-option.ti-option.ti* %1 to %option.ti*
    %data11 = getelementptr inbounds %option.ti, %option.ti* %16, i32 0, i32 1
    %17 = load i64, i64* %data11, align 8
    br label %ifcont15
  
  ifcont15:                                         ; preds = %then10, %else6, %then4, %else
    %iftmp16 = phi i64 [ %add, %then4 ], [ %14, %else ], [ %17, %then10 ], [ 0, %else6 ]
    tail call void @printf(i8* %0, i64 %iftmp16)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %boxconst = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 1 }, %option.ti* %boxconst, align 8
    %boxconst1 = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 2 }, %option.ti* %boxconst1, align 8
    call void @schmu_doo(%option.ti* %boxconst, %option.ti* %boxconst1)
    %boxconst2 = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 2 }, %option.ti* %boxconst2, align 8
    call void @schmu_doo(%option.ti* @schmu_none_int, %option.ti* %boxconst2)
    %boxconst3 = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 1 }, %option.ti* %boxconst3, align 8
    %boxconst4 = alloca %option.ti, align 8
    store %option.ti { i32 1, i64 undef }, %option.ti* %boxconst4, align 8
    call void @schmu_doo(%option.ti* %boxconst3, %option.ti* %boxconst4)
    %boxconst5 = alloca %option.ti, align 8
    store %option.ti { i32 1, i64 undef }, %option.ti* %boxconst5, align 8
    call void @schmu_doo(%option.ti* @schmu_none_int, %option.ti* %boxconst5)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  3
  2
  1
  0

  $ schmu custom_tag_reuse.smu
  custom_tag_reuse.smu:1.27-28: error: Tag 1 already used for constructor A.
  
  1 | type tags = A(1) | B(0) | C(int)
                                ^
  
  [1]

Record literals in pattern matches
  $ schmu match_record.smu
  match_record.smu:5.24-25: warning: Unused binding b.
  
  5 |     Some({a = Some(a), b}): a
                             ^
  
  match_record.smu:6.21-22: warning: Unused binding b.
  
  6 |     Some({a = None, b}): -1
                          ^
  
  match_record.smu:15.18-19: warning: Unused binding b.
  
  15 |     {a = {a = c, b}, b = _}: c
                        ^
  
  $ valgrind -q --leak-check=yes --show-reachable=yes ./match_record
  10
  -1
  20
  -2

Const ctors
  $ schmu const_ctor_issue.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %var = type { i32, %thing }
  %thing = type { i64, %tup-i-i-i-i-i }
  %tup-i-i-i-i-i = type { i64, i64, i64, i64, i64 }
  
  @schmu_var = constant %var { i32 0, { double, [40 x i8] } { double 1.000000e+01, [40 x i8] undef } }
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"float\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"thing\00" }
  
  declare void @string_print(i8* %0)
  
  define void @schmu_dynamic(%var* %var) {
  entry:
    %tag2 = bitcast %var* %var to i32*
    %index = load i32, i32* %tag2, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %var, %var* %var, i32 0, i32 1
    tail call void @string_print(i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*))
    ret void
  
  else:                                             ; preds = %entry
    %data1 = getelementptr inbounds %var, %var* %var, i32 0, i32 1
    tail call void @string_print(i8* bitcast ({ i64, i64, [6 x i8] }* @1 to i8*))
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*))
    tail call void @schmu_dynamic(%var* @schmu_var)
    ret i64 0
  }
  $ valgrind -q --leak-check=yes --show-reachable=yes ./const_ctor_issue
  float
  float

Mutate in pattern matches
  $ schmu mutate.smu
  $ ./mutate
  11
  12

Don't free catchall let pattern in other branch
  $ schmu dont_free_catchall_let_pattern.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./dont_free_catchall_let_pattern
