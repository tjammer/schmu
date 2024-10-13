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
  
  %clike_ = type { i32 }
  %option.tac__ = type { i32, ptr }
  
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"hello\00" }
  
  define i32 @schmu_wrap_clike() {
  entry:
    %clike = alloca %clike_, align 8
    store %clike_ { i32 2 }, ptr %clike, align 4
    %unbox = load i32, ptr %clike, align 4
    ret i32 %unbox
  }
  
  define { i32, i64 } @schmu_wrap_option() {
  entry:
    %t = alloca %option.tac__, align 8
    store i32 1, ptr %t, align 4
    %data = getelementptr inbounds %option.tac__, ptr %t, i32 0, i32 1
    %0 = alloca ptr, align 8
    store ptr @0, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    store ptr %2, ptr %data, align 8
    %unbox = load { i32, i64 }, ptr %t, align 8
    ret { i32, i64 } %unbox
  }
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }

Match option
  $ schmu match_option.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./match_option
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tl_ = type { i32, i64 }
  
  @schmu_none_int = constant %option.tl_ { i32 0, i64 undef }
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define linkonce_odr i64 @__schmu_none_all_vl__(i32 %0, i64 %1) {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_match_opt(i32 %0, i64 %1) {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_opt_match(i32 %0, i64 %1) {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_some_all(i32 %0, i64 %1) {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %boxconst = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %0 = tail call i64 @schmu_match_opt(i32 %fst1, i64 %snd2)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %boxconst3 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst3, align 8
    %fst5 = load i32, ptr %boxconst3, align 4
    %snd6 = getelementptr inbounds { i32, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    %1 = tail call i64 @schmu_match_opt(i32 %fst5, i64 %snd7)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    %boxconst8 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst8, align 8
    %fst10 = load i32, ptr %boxconst8, align 4
    %snd11 = getelementptr inbounds { i32, i64 }, ptr %boxconst8, i32 0, i32 1
    %snd12 = load i64, ptr %snd11, align 8
    %2 = tail call i64 @schmu_opt_match(i32 %fst10, i64 %snd12)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %2)
    %boxconst13 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst13, align 8
    %fst15 = load i32, ptr %boxconst13, align 4
    %snd16 = getelementptr inbounds { i32, i64 }, ptr %boxconst13, i32 0, i32 1
    %snd17 = load i64, ptr %snd16, align 8
    %3 = tail call i64 @schmu_opt_match(i32 %fst15, i64 %snd17)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %3)
    %boxconst18 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst18, align 8
    %fst20 = load i32, ptr %boxconst18, align 4
    %snd21 = getelementptr inbounds { i32, i64 }, ptr %boxconst18, i32 0, i32 1
    %snd22 = load i64, ptr %snd21, align 8
    %4 = tail call i64 @schmu_some_all(i32 %fst20, i64 %snd22)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %4)
    %boxconst23 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst23, align 8
    %fst25 = load i32, ptr %boxconst23, align 4
    %snd26 = getelementptr inbounds { i32, i64 }, ptr %boxconst23, i32 0, i32 1
    %snd27 = load i64, ptr %snd26, align 8
    %5 = tail call i64 @schmu_some_all(i32 %fst25, i64 %snd27)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %5)
    %boxconst28 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst28, align 8
    %fst30 = load i32, ptr %boxconst28, align 4
    %snd31 = getelementptr inbounds { i32, i64 }, ptr %boxconst28, i32 0, i32 1
    %snd32 = load i64, ptr %snd31, align 8
    %6 = tail call i64 @__schmu_none_all_vl__(i32 %fst30, i64 %snd32)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %6)
    %7 = tail call i64 @__schmu_none_all_vl__(i32 0, i64 undef)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %7)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
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
  
  %option.tvdl__ = type { i32, %test_ }
  %test_ = type { i32, double }
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @schmu_doo(ptr %m) {
  entry:
    %index = load i32, ptr %m, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont15
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tvdl__, ptr %m, i32 0, i32 1
    %index2 = load i32, ptr %data, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %sunkaddr = getelementptr inbounds i8, ptr %m, i64 16
    %0 = load double, ptr %sunkaddr, align 8
    %1 = fptosi double %0 to i64
    br label %ifcont15
  
  else:                                             ; preds = %then
    %eq8 = icmp eq i32 %index2, 1
    br i1 %eq8, label %then9, label %ifcont15
  
  then9:                                            ; preds = %else
    %sunkaddr17 = getelementptr inbounds i8, ptr %m, i64 16
    %2 = load i64, ptr %sunkaddr17, align 8
    br label %ifcont15
  
  ifcont15:                                         ; preds = %entry, %then4, %else, %then9
    %iftmp16 = phi i64 [ %1, %then4 ], [ %2, %then9 ], [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp16
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %boxconst = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 1, %test_ { i32 0, double 3.000000e+00 } }, ptr %boxconst, align 8
    %0 = call i64 @schmu_doo(ptr %boxconst)
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %boxconst1 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 1, %test_ { i32 1, double 9.881310e-324 } }, ptr %boxconst1, align 8
    %1 = call i64 @schmu_doo(ptr %boxconst1)
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    %boxconst2 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 1, %test_ { i32 2, double undef } }, ptr %boxconst2, align 8
    %2 = call i64 @schmu_doo(ptr %boxconst2)
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %2)
    %boxconst3 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 0, %test_ undef }, ptr %boxconst3, align 8
    %3 = call i64 @schmu_doo(ptr %boxconst3)
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %3)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  3
  2
  1
  0

Match multiple columns
  $ schmu tuple_match.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./tuple_match
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tl_ = type { i32, i64 }
  %vl_vl2_ = type { %option.tl_, %option.tl_ }
  
  @schmu_none_int = constant %option.tl_ { i32 0, i64 undef }
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define void @schmu_doo(i32 %0, i64 %1, i32 %2, i64 %3) {
  entry:
    %a = alloca { i32, i64 }, align 8
    store i32 %0, ptr %a, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %a, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %b = alloca { i32, i64 }, align 8
    store i32 %2, ptr %b, align 4
    %snd2 = getelementptr inbounds { i32, i64 }, ptr %b, i32 0, i32 1
    store i64 %3, ptr %snd2, align 8
    %4 = alloca %vl_vl2_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 %a, i64 16, i1 false)
    %"1" = getelementptr inbounds %vl_vl2_, ptr %4, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %"1", ptr align 8 %b, i64 16, i1 false)
    %index = load i32, ptr %"1", align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else8
  
  then:                                             ; preds = %entry
    %index4 = load i32, ptr %4, align 4
    %eq5 = icmp eq i32 %index4, 1
    br i1 %eq5, label %then6, label %else
  
  then6:                                            ; preds = %then
    %data7 = getelementptr inbounds %option.tl_, ptr %4, i32 0, i32 1
    %sunkaddr = getelementptr inbounds i8, ptr %4, i64 24
    %5 = load i64, ptr %sunkaddr, align 8
    %6 = load i64, ptr %data7, align 8
    %add = add i64 %6, %5
    br label %ifcont17
  
  else:                                             ; preds = %then
    %sunkaddr19 = getelementptr inbounds i8, ptr %4, i64 24
    %7 = load i64, ptr %sunkaddr19, align 8
    br label %ifcont17
  
  else8:                                            ; preds = %entry
    %index10 = load i32, ptr %4, align 4
    %eq11 = icmp eq i32 %index10, 1
    br i1 %eq11, label %then12, label %ifcont17
  
  then12:                                           ; preds = %else8
    %data13 = getelementptr inbounds %option.tl_, ptr %4, i32 0, i32 1
    %8 = load i64, ptr %data13, align 8
    br label %ifcont17
  
  ifcont17:                                         ; preds = %then12, %else8, %then6, %else
    %iftmp18 = phi i64 [ %add, %then6 ], [ %7, %else ], [ %8, %then12 ], [ 0, %else8 ]
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %iftmp18)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(ptr %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    %boxconst = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %boxconst3 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 2 }, ptr %boxconst3, align 8
    %fst5 = load i32, ptr %boxconst3, align 4
    %snd6 = getelementptr inbounds { i32, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    tail call void @schmu_doo(i32 %fst1, i64 %snd2, i32 %fst5, i64 %snd7)
    %boxconst10 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 2 }, ptr %boxconst10, align 8
    %fst12 = load i32, ptr %boxconst10, align 4
    %snd13 = getelementptr inbounds { i32, i64 }, ptr %boxconst10, i32 0, i32 1
    %snd14 = load i64, ptr %snd13, align 8
    tail call void @schmu_doo(i32 0, i64 undef, i32 %fst12, i64 %snd14)
    %boxconst15 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst15, align 8
    %fst17 = load i32, ptr %boxconst15, align 4
    %snd18 = getelementptr inbounds { i32, i64 }, ptr %boxconst15, i32 0, i32 1
    %snd19 = load i64, ptr %snd18, align 8
    %boxconst20 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst20, align 8
    %fst22 = load i32, ptr %boxconst20, align 4
    %snd23 = getelementptr inbounds { i32, i64 }, ptr %boxconst20, i32 0, i32 1
    %snd24 = load i64, ptr %snd23, align 8
    tail call void @schmu_doo(i32 %fst17, i64 %snd19, i32 %fst22, i64 %snd24)
    %boxconst27 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst27, align 8
    %fst29 = load i32, ptr %boxconst27, align 4
    %snd30 = getelementptr inbounds { i32, i64 }, ptr %boxconst27, i32 0, i32 1
    %snd31 = load i64, ptr %snd30, align 8
    tail call void @schmu_doo(i32 0, i64 undef, i32 %fst29, i64 %snd31)
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  3
  2
  1
  0

  $ schmu custom_tag_reuse.smu
  custom_tag_reuse.smu:1.27-28: error: Tag 1 already used for constructor a.
  
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
  
  %var_ = type { i32, %thing_ }
  %thing_ = type { i64, %"5l_" }
  %"5l_" = type { i64, i64, i64, i64, i64 }
  
  @schmu_var = constant %var_ { i32 0, { double, [40 x i8] } { double 1.000000e+01, [40 x i8] undef } }
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"float\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"thing\00" }
  
  declare void @string_println(ptr %0)
  
  define void @schmu_dynamic(ptr %var) {
  entry:
    %index = load i32, ptr %var, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %var_, ptr %var, i32 0, i32 1
    tail call void @string_println(ptr @0)
    ret void
  
  else:                                             ; preds = %entry
    %data1 = getelementptr inbounds %var_, ptr %var, i32 0, i32 1
    tail call void @string_println(ptr @1)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @string_println(ptr @0)
    tail call void @schmu_dynamic(ptr @schmu_var)
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

Basic recursive types
  $ schmu recursive.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./recursive

Support path prefixes in match patterns
  $ schmu path_prefix.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./path_prefix
