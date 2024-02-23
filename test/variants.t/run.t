Basic variant ctors
  $ schmu basic.smu --dump-llvm
  basic.smu:12.5-15: warning: Unused binding wrap_clike.
  
  12 | fun wrap_clike(): #c
           ^^^^^^^^^^
  
  basic.smu:14.5-16: warning: Unused binding wrap_option.
  
  14 | fun wrap_option(): #some("hello")
           ^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %clike_ = type { i32 }
  %option.tac__ = type { i32, i8* }
  
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"hello\00" }
  
  define i32 @schmu_wrap_clike() {
  entry:
    %clike = alloca %clike_, align 8
    store %clike_ { i32 2 }, %clike_* %clike, align 4
    %unbox = bitcast %clike_* %clike to i32*
    %unbox1 = load i32, i32* %unbox, align 4
    ret i32 %unbox1
  }
  
  define { i32, i64 } @schmu_wrap_option() {
  entry:
    %t = alloca %option.tac__, align 8
    %tag2 = bitcast %option.tac__* %t to i32*
    store i32 0, i32* %tag2, align 4
    %data = getelementptr inbounds %option.tac__, %option.tac__* %t, i32 0, i32 1
    %0 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*), i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac_(i8** %1)
    %4 = load i8*, i8** %1, align 8
    store i8* %4, i8** %data, align 8
    %unbox = bitcast %option.tac__* %t to { i32, i64 }*
    %unbox1 = load { i32, i64 }, { i32, i64 }* %unbox, align 8
    ret { i32, i64 } %unbox1
  }
  
  define linkonce_odr void @__copy_ac_(i8** %0) {
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
  
  %option.tl_ = type { i32, i64 }
  
  @schmu_none_int = constant %option.tl_ { i32 1, i64 undef }
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define linkonce_odr i64 @__schmu_none_all_vl__(i32 %0, i64 %1) {
  entry:
    %box = alloca { i32, i64 }, align 8
    %fst2 = bitcast { i32, i64 }* %box to i32*
    store i32 %0, i32* %fst2, align 4
    %snd = getelementptr inbounds { i32, i64 }, { i32, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_match_opt(i32 %0, i64 %1) {
  entry:
    %box = alloca { i32, i64 }, align 8
    %fst2 = bitcast { i32, i64 }* %box to i32*
    store i32 %0, i32* %fst2, align 4
    %snd = getelementptr inbounds { i32, i64 }, { i32, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %2 = bitcast { i32, i64 }* %box to %option.tl_*
    %data = getelementptr inbounds %option.tl_, %option.tl_* %2, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %1, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_opt_match(i32 %0, i64 %1) {
  entry:
    %box = alloca { i32, i64 }, align 8
    %fst2 = bitcast { i32, i64 }* %box to i32*
    store i32 %0, i32* %fst2, align 4
    %snd = getelementptr inbounds { i32, i64 }, { i32, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %2 = bitcast { i32, i64 }* %box to %option.tl_*
    %data = getelementptr inbounds %option.tl_, %option.tl_* %2, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_some_all(i32 %0, i64 %1) {
  entry:
    %box = alloca { i32, i64 }, align 8
    %fst2 = bitcast { i32, i64 }* %box to i32*
    store i32 %0, i32* %fst2, align 4
    %snd = getelementptr inbounds { i32, i64 }, { i32, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %2 = bitcast { i32, i64 }* %box to %option.tl_*
    %data = getelementptr inbounds %option.tl_, %option.tl_* %2, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %1, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 1 }, %option.tl_* %boxconst, align 8
    %unbox = bitcast %option.tl_* %boxconst to { i32, i64 }*
    %fst41 = bitcast { i32, i64 }* %unbox to i32*
    %fst1 = load i32, i32* %fst41, align 4
    %snd = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox, i32 0, i32 1
    %snd2 = load i64, i64* %snd, align 8
    %1 = tail call i64 @schmu_match_opt(i32 %fst1, i64 %snd2)
    tail call void @printf(i8* %0, i64 %1)
    %2 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst3 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 undef }, %option.tl_* %boxconst3, align 8
    %unbox4 = bitcast %option.tl_* %boxconst3 to { i32, i64 }*
    %fst542 = bitcast { i32, i64 }* %unbox4 to i32*
    %fst6 = load i32, i32* %fst542, align 4
    %snd7 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox4, i32 0, i32 1
    %snd8 = load i64, i64* %snd7, align 8
    %3 = tail call i64 @schmu_match_opt(i32 %fst6, i64 %snd8)
    tail call void @printf(i8* %2, i64 %3)
    %4 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst9 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 1 }, %option.tl_* %boxconst9, align 8
    %unbox10 = bitcast %option.tl_* %boxconst9 to { i32, i64 }*
    %fst1143 = bitcast { i32, i64 }* %unbox10 to i32*
    %fst12 = load i32, i32* %fst1143, align 4
    %snd13 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox10, i32 0, i32 1
    %snd14 = load i64, i64* %snd13, align 8
    %5 = tail call i64 @schmu_opt_match(i32 %fst12, i64 %snd14)
    tail call void @printf(i8* %4, i64 %5)
    %6 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst15 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 undef }, %option.tl_* %boxconst15, align 8
    %unbox16 = bitcast %option.tl_* %boxconst15 to { i32, i64 }*
    %fst1744 = bitcast { i32, i64 }* %unbox16 to i32*
    %fst18 = load i32, i32* %fst1744, align 4
    %snd19 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox16, i32 0, i32 1
    %snd20 = load i64, i64* %snd19, align 8
    %7 = tail call i64 @schmu_opt_match(i32 %fst18, i64 %snd20)
    tail call void @printf(i8* %6, i64 %7)
    %8 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst21 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 1 }, %option.tl_* %boxconst21, align 8
    %unbox22 = bitcast %option.tl_* %boxconst21 to { i32, i64 }*
    %fst2345 = bitcast { i32, i64 }* %unbox22 to i32*
    %fst24 = load i32, i32* %fst2345, align 4
    %snd25 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox22, i32 0, i32 1
    %snd26 = load i64, i64* %snd25, align 8
    %9 = tail call i64 @schmu_some_all(i32 %fst24, i64 %snd26)
    tail call void @printf(i8* %8, i64 %9)
    %10 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst27 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 undef }, %option.tl_* %boxconst27, align 8
    %unbox28 = bitcast %option.tl_* %boxconst27 to { i32, i64 }*
    %fst2946 = bitcast { i32, i64 }* %unbox28 to i32*
    %fst30 = load i32, i32* %fst2946, align 4
    %snd31 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox28, i32 0, i32 1
    %snd32 = load i64, i64* %snd31, align 8
    %11 = tail call i64 @schmu_some_all(i32 %fst30, i64 %snd32)
    tail call void @printf(i8* %10, i64 %11)
    %12 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst33 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 1 }, %option.tl_* %boxconst33, align 8
    %unbox34 = bitcast %option.tl_* %boxconst33 to { i32, i64 }*
    %fst3547 = bitcast { i32, i64 }* %unbox34 to i32*
    %fst36 = load i32, i32* %fst3547, align 4
    %snd37 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox34, i32 0, i32 1
    %snd38 = load i64, i64* %snd37, align 8
    %13 = tail call i64 @__schmu_none_all_vl__(i32 %fst36, i64 %snd38)
    tail call void @printf(i8* %12, i64 %13)
    %14 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %15 = tail call i64 @__schmu_none_all_vl__(i32 1, i64 undef)
    tail call void @printf(i8* %14, i64 %15)
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
  
  %option.tvdl__ = type { i32, %test_ }
  %test_ = type { i32, double }
  
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_doo(%option.tvdl__* %m) {
  entry:
    %tag17 = bitcast %option.tvdl__* %m to i32*
    %index = load i32, i32* %tag17, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont15
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tvdl__, %option.tvdl__* %m, i32 0, i32 1
    %tag118 = bitcast %test_* %data to i32*
    %index2 = load i32, i32* %tag118, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %0 = bitcast %option.tvdl__* %m to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %1 = bitcast i8* %sunkaddr to double*
    %2 = load double, double* %1, align 8
    %3 = fptosi double %2 to i64
    br label %ifcont15
  
  else:                                             ; preds = %then
    %eq8 = icmp eq i32 %index2, 1
    br i1 %eq8, label %then9, label %ifcont15
  
  then9:                                            ; preds = %else
    %4 = bitcast %option.tvdl__* %m to i8*
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
    %boxconst = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 0, %test_ { i32 0, double 3.000000e+00 } }, %option.tvdl__* %boxconst, align 8
    %1 = call i64 @schmu_doo(%option.tvdl__* %boxconst)
    call void @printf(i8* %0, i64 %1)
    %2 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst1 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 0, %test_ { i32 1, double 9.881310e-324 } }, %option.tvdl__* %boxconst1, align 8
    %3 = call i64 @schmu_doo(%option.tvdl__* %boxconst1)
    call void @printf(i8* %2, i64 %3)
    %4 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst2 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 0, %test_ { i32 2, double undef } }, %option.tvdl__* %boxconst2, align 8
    %5 = call i64 @schmu_doo(%option.tvdl__* %boxconst2)
    call void @printf(i8* %4, i64 %5)
    %6 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst3 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 1, %test_ undef }, %option.tvdl__* %boxconst3, align 8
    %7 = call i64 @schmu_doo(%option.tvdl__* %boxconst3)
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
  
  %option.tl_ = type { i32, i64 }
  %vl_vl2_ = type { %option.tl_, %option.tl_ }
  
  @schmu_none_int = constant %option.tl_ { i32 1, i64 undef }
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define void @schmu_doo(i32 %0, i64 %1, i32 %2, i64 %3) {
  entry:
    %box = alloca { i32, i64 }, align 8
    %fst22 = bitcast { i32, i64 }* %box to i32*
    store i32 %0, i32* %fst22, align 4
    %snd = getelementptr inbounds { i32, i64 }, { i32, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %a = bitcast { i32, i64 }* %box to %option.tl_*
    %box2 = alloca { i32, i64 }, align 8
    %fst323 = bitcast { i32, i64 }* %box2 to i32*
    store i32 %2, i32* %fst323, align 4
    %snd4 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %box2, i32 0, i32 1
    store i64 %3, i64* %snd4, align 8
    %b = bitcast { i32, i64 }* %box2 to %option.tl_*
    %4 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %5 = alloca %vl_vl2_, align 8
    %"024" = bitcast %vl_vl2_* %5 to %option.tl_*
    %6 = bitcast %option.tl_* %"024" to i8*
    %7 = bitcast %option.tl_* %a to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 16, i1 false)
    %"1" = getelementptr inbounds %vl_vl2_, %vl_vl2_* %5, i32 0, i32 1
    %8 = bitcast %option.tl_* %"1" to i8*
    %9 = bitcast %option.tl_* %b to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 16, i1 false)
    %tag25 = bitcast %option.tl_* %"1" to i32*
    %index = load i32, i32* %tag25, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else11
  
  then:                                             ; preds = %entry
    %10 = bitcast %vl_vl2_* %5 to %option.tl_*
    %tag626 = bitcast %option.tl_* %10 to i32*
    %index7 = load i32, i32* %tag626, align 4
    %eq8 = icmp eq i32 %index7, 0
    br i1 %eq8, label %then9, label %else
  
  then9:                                            ; preds = %then
    %11 = bitcast %vl_vl2_* %5 to %option.tl_*
    %data10 = getelementptr inbounds %option.tl_, %option.tl_* %11, i32 0, i32 1
    %12 = bitcast %vl_vl2_* %5 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %12, i64 24
    %13 = bitcast i8* %sunkaddr to i64*
    %14 = load i64, i64* %13, align 8
    %15 = load i64, i64* %data10, align 8
    %add = add i64 %15, %14
    br label %ifcont20
  
  else:                                             ; preds = %then
    %16 = bitcast %vl_vl2_* %5 to i8*
    %sunkaddr27 = getelementptr inbounds i8, i8* %16, i64 24
    %17 = bitcast i8* %sunkaddr27 to i64*
    %18 = load i64, i64* %17, align 8
    br label %ifcont20
  
  else11:                                           ; preds = %entry
    %19 = bitcast %vl_vl2_* %5 to %option.tl_*
    %tag1228 = bitcast %option.tl_* %19 to i32*
    %index13 = load i32, i32* %tag1228, align 4
    %eq14 = icmp eq i32 %index13, 0
    br i1 %eq14, label %then15, label %ifcont20
  
  then15:                                           ; preds = %else11
    %20 = bitcast %vl_vl2_* %5 to %option.tl_*
    %data16 = getelementptr inbounds %option.tl_, %option.tl_* %20, i32 0, i32 1
    %21 = load i64, i64* %data16, align 8
    br label %ifcont20
  
  ifcont20:                                         ; preds = %then15, %else11, %then9, %else
    %iftmp21 = phi i64 [ %add, %then9 ], [ %18, %else ], [ %21, %then15 ], [ 0, %else11 ]
    tail call void @printf(i8* %4, i64 %iftmp21)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %boxconst = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 1 }, %option.tl_* %boxconst, align 8
    %unbox = bitcast %option.tl_* %boxconst to { i32, i64 }*
    %fst37 = bitcast { i32, i64 }* %unbox to i32*
    %fst1 = load i32, i32* %fst37, align 4
    %snd = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox, i32 0, i32 1
    %snd2 = load i64, i64* %snd, align 8
    %boxconst3 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 2 }, %option.tl_* %boxconst3, align 8
    %unbox4 = bitcast %option.tl_* %boxconst3 to { i32, i64 }*
    %fst538 = bitcast { i32, i64 }* %unbox4 to i32*
    %fst6 = load i32, i32* %fst538, align 4
    %snd7 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox4, i32 0, i32 1
    %snd8 = load i64, i64* %snd7, align 8
    tail call void @schmu_doo(i32 %fst1, i64 %snd2, i32 %fst6, i64 %snd8)
    %boxconst11 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 2 }, %option.tl_* %boxconst11, align 8
    %unbox12 = bitcast %option.tl_* %boxconst11 to { i32, i64 }*
    %fst1339 = bitcast { i32, i64 }* %unbox12 to i32*
    %fst14 = load i32, i32* %fst1339, align 4
    %snd15 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox12, i32 0, i32 1
    %snd16 = load i64, i64* %snd15, align 8
    tail call void @schmu_doo(i32 1, i64 undef, i32 %fst14, i64 %snd16)
    %boxconst17 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 1 }, %option.tl_* %boxconst17, align 8
    %unbox18 = bitcast %option.tl_* %boxconst17 to { i32, i64 }*
    %fst1940 = bitcast { i32, i64 }* %unbox18 to i32*
    %fst20 = load i32, i32* %fst1940, align 4
    %snd21 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox18, i32 0, i32 1
    %snd22 = load i64, i64* %snd21, align 8
    %boxconst23 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 undef }, %option.tl_* %boxconst23, align 8
    %unbox24 = bitcast %option.tl_* %boxconst23 to { i32, i64 }*
    %fst2541 = bitcast { i32, i64 }* %unbox24 to i32*
    %fst26 = load i32, i32* %fst2541, align 4
    %snd27 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox24, i32 0, i32 1
    %snd28 = load i64, i64* %snd27, align 8
    tail call void @schmu_doo(i32 %fst20, i64 %snd22, i32 %fst26, i64 %snd28)
    %boxconst31 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 undef }, %option.tl_* %boxconst31, align 8
    %unbox32 = bitcast %option.tl_* %boxconst31 to { i32, i64 }*
    %fst3342 = bitcast { i32, i64 }* %unbox32 to i32*
    %fst34 = load i32, i32* %fst3342, align 4
    %snd35 = getelementptr inbounds { i32, i64 }, { i32, i64 }* %unbox32, i32 0, i32 1
    %snd36 = load i64, i64* %snd35, align 8
    tail call void @schmu_doo(i32 1, i64 undef, i32 %fst34, i64 %snd36)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  3
  2
  1
  0

  $ schmu custom_tag_reuse.smu
  custom_tag_reuse.smu:1.29-31: error: Tag 1 already used for constructor #a.
  
  1 | type tags = #a(1) | #b(0) | #c(int)
                                  ^^
  
  [1]

Record literals in pattern matches
  $ schmu match_record.smu
  match_record.smu:5.26-27: warning: Unused binding b.
  
  5 |     #some({a = #some(a), b}): a
                               ^
  
  match_record.smu:6.23-24: warning: Unused binding b.
  
  6 |     #some({a = #none, b}): -1
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
  
  declare void @string_print(i8* %0)
  
  define void @schmu_dynamic(%var_* %var) {
  entry:
    %tag2 = bitcast %var_* %var to i32*
    %index = load i32, i32* %tag2, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %var_, %var_* %var, i32 0, i32 1
    tail call void @string_print(i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*))
    ret void
  
  else:                                             ; preds = %entry
    %data1 = getelementptr inbounds %var_, %var_* %var, i32 0, i32 1
    tail call void @string_print(i8* bitcast ({ i64, i64, [6 x i8] }* @1 to i8*))
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*))
    tail call void @schmu_dynamic(%var_* @schmu_var)
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
