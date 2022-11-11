Test simple setting of mutable variables
  $ schmu --dump-llvm simple_set.smu && valgrind -q --leak-check=yes ./simple_set
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @b = global i64 0, align 8
  @a = global i64** null, align 8
  @b__2 = global i64** null, align 8
  @c = global i64* null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @schmu_print(i8* %0)
  
  define i64 @schmu_hmm() {
  entry:
    %b = alloca i64, align 8
    store i64 10, i64* %b, align 4
    store i64 15, i64* %b, align 4
    ret i64 15
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 10, i64* @b, align 4
    store i64 14, i64* @b, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 14)
    %0 = add i32 %fmtsize, 32
    %1 = sext i32 %0 to i64
    %2 = tail call i8* @malloc(i64 %1)
    %3 = bitcast i8* %2 to i64*
    store i64 1, i64* %3, align 4
    %size = getelementptr i64, i64* %3, i64 1
    %4 = sext i32 %fmtsize to i64
    store i64 %4, i64* %size, align 4
    %cap = getelementptr i64, i64* %3, i64 2
    store i64 %4, i64* %cap, align 4
    %data = getelementptr i64, i64* %3, i64 3
    %5 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %1, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 14)
    %str = alloca i8*, align 8
    store i8* %2, i8** %str, align 8
    tail call void @schmu_print(i8* %2)
    %6 = tail call i64 @schmu_hmm()
    %fmtsize1 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %6)
    %7 = add i32 %fmtsize1, 32
    %8 = sext i32 %7 to i64
    %9 = tail call i8* @malloc(i64 %8)
    %10 = bitcast i8* %9 to i64*
    store i64 1, i64* %10, align 4
    %size3 = getelementptr i64, i64* %10, i64 1
    %11 = sext i32 %fmtsize1 to i64
    store i64 %11, i64* %size3, align 4
    %cap4 = getelementptr i64, i64* %10, i64 2
    store i64 %11, i64* %cap4, align 4
    %data5 = getelementptr i64, i64* %10, i64 3
    %12 = bitcast i64* %data5 to i8*
    %fmt6 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %8, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %6)
    %str7 = alloca i8*, align 8
    store i8* %9, i8** %str7, align 8
    tail call void @schmu_print(i8* %9)
    %13 = tail call i8* @malloc(i64 40)
    %14 = bitcast i8* %13 to i64**
    store i64** %14, i64*** @a, align 8
    %15 = bitcast i64** %14 to i64*
    store i64 1, i64* %15, align 4
    %size9 = getelementptr i64, i64* %15, i64 1
    store i64 2, i64* %size9, align 4
    %cap10 = getelementptr i64, i64* %15, i64 2
    store i64 2, i64* %cap10, align 4
    %data11 = getelementptr i64, i64* %15, i64 3
    %16 = bitcast i64* %data11 to i64**
    %17 = tail call i8* @malloc(i64 32)
    %18 = bitcast i8* %17 to i64*
    store i64* %18, i64** %16, align 8
    store i64 1, i64* %18, align 4
    %size13 = getelementptr i64, i64* %18, i64 1
    store i64 1, i64* %size13, align 4
    %cap14 = getelementptr i64, i64* %18, i64 2
    store i64 1, i64* %cap14, align 4
    %data15 = getelementptr i64, i64* %18, i64 3
    store i64 10, i64* %data15, align 4
    %"1" = getelementptr i64*, i64** %16, i64 1
    %19 = tail call i8* @malloc(i64 32)
    %20 = bitcast i8* %19 to i64*
    store i64* %20, i64** %"1", align 8
    store i64 1, i64* %20, align 4
    %size18 = getelementptr i64, i64* %20, i64 1
    store i64 1, i64* %size18, align 4
    %cap19 = getelementptr i64, i64* %20, i64 2
    store i64 1, i64* %cap19, align 4
    %data20 = getelementptr i64, i64* %20, i64 3
    store i64 20, i64* %data20, align 4
    %21 = load i64**, i64*** @a, align 8
    store i64** %21, i64*** @a, align 8
    tail call void @__g.u_incr_rc_aai.u(i64** %21)
    store i64** %21, i64*** @b__2, align 8
    %22 = tail call i8* @malloc(i64 32)
    %23 = bitcast i8* %22 to i64*
    store i64* %23, i64** @c, align 8
    store i64 1, i64* %23, align 4
    %size23 = getelementptr i64, i64* %23, i64 1
    store i64 1, i64* %size23, align 4
    %cap24 = getelementptr i64, i64* %23, i64 2
    store i64 1, i64* %cap24, align 4
    %data25 = getelementptr i64, i64* %23, i64 3
    store i64 30, i64* %data25, align 4
    %24 = load i64*, i64** @c, align 8
    store i64* %24, i64** @c, align 8
    %25 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @a)
    %26 = bitcast i64** %25 to i64*
    %data27 = getelementptr i64, i64* %26, i64 3
    %27 = bitcast i64* %data27 to i64**
    %28 = load i64*, i64** @c, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %28)
    %29 = load i64*, i64** %27, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %29)
    %30 = load i64*, i64** @c, align 8
    store i64* %30, i64** %27, align 8
    %31 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @a)
    %32 = bitcast i64** %31 to i64*
    %data28 = getelementptr i64, i64* %32, i64 3
    %33 = bitcast i64* %data28 to i64**
    %34 = tail call i8* @malloc(i64 32)
    %35 = bitcast i8* %34 to i64*
    %arr = alloca i64*, align 8
    store i64* %35, i64** %arr, align 8
    store i64 1, i64* %35, align 4
    %size30 = getelementptr i64, i64* %35, i64 1
    store i64 1, i64* %size30, align 4
    %cap31 = getelementptr i64, i64* %35, i64 2
    store i64 1, i64* %cap31, align 4
    %data32 = getelementptr i64, i64* %35, i64 3
    store i64 10, i64* %data32, align 4
    %36 = load i64*, i64** %33, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %36)
    store i64* %35, i64** %33, align 8
    %37 = load i64*, i64** @c, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %37)
    %38 = load i64**, i64*** @b__2, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %38)
    %39 = load i64**, i64*** @a, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %39)
    tail call void @__g.u_decr_rc_ac.u(i8* %9)
    %40 = load i8*, i8** %str, align 8
    tail call void @__g.u_decr_rc_ac.u(i8* %40)
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_incr_rc_aai.u(i64** %0) {
  entry:
    %ref = bitcast i64** %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 4
    ret void
  }
  
  define internal i64** @__ag.ag_reloc_aai.aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %ref17 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref17, align 4
    %2 = icmp sgt i64 %ref2, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %3 = bitcast i64** %1 to i64*
    %sz = getelementptr i64, i64* %3, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %3, i64 2
    %cap3 = load i64, i64* %cap, align 4
    %4 = mul i64 %cap3, 8
    %5 = add i64 %4, 24
    %6 = call i8* @malloc(i64 %5)
    %7 = bitcast i8* %6 to i64**
    %8 = mul i64 %size, 8
    %9 = add i64 %8, 24
    %10 = bitcast i64** %7 to i8*
    %11 = bitcast i64** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %11, i64 %9, i1 false)
    store i64** %7, i64*** %0, align 8
    %ref4 = bitcast i64** %7 to i64*
    %ref58 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref58, align 4
    call void @__g.u_decr_rc_aai.u(i64** %1)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  merge:                                            ; preds = %rec, %entry
    %12 = load i64**, i64*** %0, align 8
    ret i64** %12
  
  rec:                                              ; preds = %child, %relocate
    %13 = load i64, i64* %cnt, align 4
    %14 = icmp slt i64 %13, %size
    br i1 %14, label %child, label %merge
  
  child:                                            ; preds = %rec
    %sunkaddr = mul i64 %13, 8
    %15 = bitcast i64** %1 to i8*
    %sunkaddr9 = getelementptr i8, i8* %15, i64 %sunkaddr
    %sunkaddr10 = getelementptr i8, i8* %sunkaddr9, i64 24
    %16 = bitcast i8* %sunkaddr10 to i64**
    %17 = load i64*, i64** %16, align 8
    call void @__g.u_incr_rc_ai.u(i64* %17)
    %18 = add i64 %13, 1
    store i64 %18, i64* %cnt, align 4
    br label %rec
  }
  
  define internal void @__g.u_decr_rc_aai.u(i64** %0) {
  entry:
    %ref = bitcast i64** %0 to i64*
    %ref14 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref14, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64** %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i64** %0 to i64*
    %sz = getelementptr i64, i64* %5, i64 1
    %size = load i64, i64* %sz, align 4
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %6 = load i64, i64* %cnt, align 4
    %7 = icmp slt i64 %6, %size
    br i1 %7, label %child, label %cont
  
  child:                                            ; preds = %rec
    %sunkaddr = mul i64 %6, 8
    %8 = bitcast i64** %0 to i8*
    %sunkaddr5 = getelementptr i8, i8* %8, i64 %sunkaddr
    %sunkaddr6 = getelementptr i8, i8* %sunkaddr5, i64 24
    %9 = bitcast i8* %sunkaddr6 to i64**
    %10 = load i64*, i64** %9, align 8
    call void @__g.u_decr_rc_ai.u(i64* %10)
    %11 = add i64 %6, 1
    store i64 %11, i64* %cnt, align 4
    br label %rec
  
  cont:                                             ; preds = %rec
    %12 = bitcast i64** %0 to i64*
    %13 = bitcast i64* %12 to i8*
    call void @free(i8* %13)
    br label %merge
  }
  
  define internal void @__g.u_incr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 4
    ret void
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  14
  15

Warn on unneeded mutable bindings
  $ schmu unneeded_mut.smu
  unneeded_mut.smu:1:18: warning: Unmutated mutable binding a
  1 | (fun do_nothing [a&]
                       ^
  
  unneeded_mut.smu:1:6: warning: Unused binding do_nothing
  1 | (fun do_nothing [a&]
           ^^^^^^^^^^
  
  unneeded_mut.smu:7:6: warning: Unmutated mutable binding b
  7 | (val b& 0)
           ^
  
Use mutable values as ptrs to C code
  $ schmu -c --dump-llvm ptr_to_c.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  
  @i = global i64 0, align 8
  @foo = global %foo zeroinitializer, align 8
  
  declare void @mutate_int(i64* %0)
  
  declare void @mutate_foo(%foo* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* @i, align 4
    tail call void @mutate_int(i64* @i)
    store i64 0, i64* getelementptr inbounds (%foo, %foo* @foo, i32 0, i32 0), align 4
    tail call void @mutate_foo(%foo* @foo)
    ret i64 0
  }

Check aliasing
  $ schmu --dump-llvm mut_alias.smu && valgrind -q --leak-check=yes ./mut_alias
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  
  @f = global %foo zeroinitializer, align 8
  @fst = global %foo zeroinitializer, align 8
  @snd = global %foo zeroinitializer, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @schmu_print(i8* %0)
  
  define void @schmu_new-fun() {
  entry:
    %0 = alloca %foo, align 8
    %a15 = bitcast %foo* %0 to i64*
    store i64 0, i64* %a15, align 4
    %fst = alloca %foo, align 8
    %1 = bitcast %foo* %fst to i8*
    %2 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    %snd = alloca %foo, align 8
    %3 = bitcast %foo* %snd to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 8, i1 false)
    %4 = bitcast %foo* %fst to i64*
    store i64 1, i64* %4, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 1)
    %5 = add i32 %fmtsize, 32
    %6 = sext i32 %5 to i64
    %7 = tail call i8* @malloc(i64 %6)
    %8 = bitcast i8* %7 to i64*
    store i64 1, i64* %8, align 4
    %size = getelementptr i64, i64* %8, i64 1
    %9 = sext i32 %fmtsize to i64
    store i64 %9, i64* %size, align 4
    %cap = getelementptr i64, i64* %8, i64 2
    store i64 %9, i64* %cap, align 4
    %data = getelementptr i64, i64* %8, i64 3
    %10 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %10, i64 %6, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 1)
    %str = alloca i8*, align 8
    store i8* %7, i8** %str, align 8
    tail call void @schmu_print(i8* %7)
    %fmtsize1 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 0)
    %11 = add i32 %fmtsize1, 32
    %12 = sext i32 %11 to i64
    %13 = tail call i8* @malloc(i64 %12)
    %14 = bitcast i8* %13 to i64*
    store i64 1, i64* %14, align 4
    %size3 = getelementptr i64, i64* %14, i64 1
    %15 = sext i32 %fmtsize1 to i64
    store i64 %15, i64* %size3, align 4
    %cap4 = getelementptr i64, i64* %14, i64 2
    store i64 %15, i64* %cap4, align 4
    %data5 = getelementptr i64, i64* %14, i64 3
    %16 = bitcast i64* %data5 to i8*
    %fmt6 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %16, i64 %12, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 0)
    %str7 = alloca i8*, align 8
    store i8* %13, i8** %str7, align 8
    tail call void @schmu_print(i8* %13)
    %17 = bitcast %foo* %snd to i64*
    %18 = load i64, i64* %17, align 4
    %fmtsize8 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %18)
    %19 = add i32 %fmtsize8, 32
    %20 = sext i32 %19 to i64
    %21 = tail call i8* @malloc(i64 %20)
    %22 = bitcast i8* %21 to i64*
    store i64 1, i64* %22, align 4
    %size10 = getelementptr i64, i64* %22, i64 1
    %23 = sext i32 %fmtsize8 to i64
    store i64 %23, i64* %size10, align 4
    %cap11 = getelementptr i64, i64* %22, i64 2
    store i64 %23, i64* %cap11, align 4
    %data12 = getelementptr i64, i64* %22, i64 3
    %24 = bitcast i64* %data12 to i8*
    %fmt13 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %24, i64 %20, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %18)
    %str14 = alloca i8*, align 8
    store i8* %21, i8** %str14, align 8
    tail call void @schmu_print(i8* %21)
    tail call void @__g.u_decr_rc_ac.u(i8* %21)
    tail call void @__g.u_decr_rc_ac.u(i8* %13)
    tail call void @__g.u_decr_rc_ac.u(i8* %7)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* getelementptr inbounds (%foo, %foo* @f, i32 0, i32 0), align 4
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%foo* @fst to i8*), i8* bitcast (%foo* @f to i8*), i64 8, i1 false)
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%foo* @snd to i8*), i8* bitcast (%foo* @fst to i8*), i64 8, i1 false)
    store i64 1, i64* getelementptr inbounds (%foo, %foo* @fst, i32 0, i32 0), align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 1)
    %0 = add i32 %fmtsize, 32
    %1 = sext i32 %0 to i64
    %2 = tail call i8* @malloc(i64 %1)
    %3 = bitcast i8* %2 to i64*
    store i64 1, i64* %3, align 4
    %size = getelementptr i64, i64* %3, i64 1
    %4 = sext i32 %fmtsize to i64
    store i64 %4, i64* %size, align 4
    %cap = getelementptr i64, i64* %3, i64 2
    store i64 %4, i64* %cap, align 4
    %data = getelementptr i64, i64* %3, i64 3
    %5 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %1, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 1)
    %str = alloca i8*, align 8
    store i8* %2, i8** %str, align 8
    tail call void @schmu_print(i8* %2)
    %6 = load i64, i64* getelementptr inbounds (%foo, %foo* @f, i32 0, i32 0), align 4
    %fmtsize1 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %6)
    %7 = add i32 %fmtsize1, 32
    %8 = sext i32 %7 to i64
    %9 = tail call i8* @malloc(i64 %8)
    %10 = bitcast i8* %9 to i64*
    store i64 1, i64* %10, align 4
    %size3 = getelementptr i64, i64* %10, i64 1
    %11 = sext i32 %fmtsize1 to i64
    store i64 %11, i64* %size3, align 4
    %cap4 = getelementptr i64, i64* %10, i64 2
    store i64 %11, i64* %cap4, align 4
    %data5 = getelementptr i64, i64* %10, i64 3
    %12 = bitcast i64* %data5 to i8*
    %fmt6 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %8, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %6)
    %str7 = alloca i8*, align 8
    store i8* %9, i8** %str7, align 8
    tail call void @schmu_print(i8* %9)
    %13 = load i64, i64* getelementptr inbounds (%foo, %foo* @snd, i32 0, i32 0), align 4
    %fmtsize8 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %13)
    %14 = add i32 %fmtsize8, 32
    %15 = sext i32 %14 to i64
    %16 = tail call i8* @malloc(i64 %15)
    %17 = bitcast i8* %16 to i64*
    store i64 1, i64* %17, align 4
    %size10 = getelementptr i64, i64* %17, i64 1
    %18 = sext i32 %fmtsize8 to i64
    store i64 %18, i64* %size10, align 4
    %cap11 = getelementptr i64, i64* %17, i64 2
    store i64 %18, i64* %cap11, align 4
    %data12 = getelementptr i64, i64* %17, i64 3
    %19 = bitcast i64* %data12 to i8*
    %fmt13 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %19, i64 %15, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %13)
    %str14 = alloca i8*, align 8
    store i8* %16, i8** %str14, align 8
    tail call void @schmu_print(i8* %16)
    tail call void @schmu_new-fun()
    tail call void @__g.u_decr_rc_ac.u(i8* %16)
    tail call void @__g.u_decr_rc_ac.u(i8* %9)
    tail call void @__g.u_decr_rc_ac.u(i8* %2)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  1
  0
  0
  1
  0
  0

  $ schmu --dump-llvm const_let.smu && valgrind -q --leak-check=yes ./const_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @v = global i64* null, align 8
  @const = global i64 0, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @schmu_print(i8* %0)
  
  define void @schmu_in-fun() {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 0, i64* %data, align 4
    %2 = load i64*, i64** %arr, align 8
    %data1 = getelementptr i64, i64* %2, i64 3
    %const = load i64, i64* %data1, align 4
    %3 = call i64* @__ag.ag_reloc_ai.ai(i64** %arr)
    %data2 = getelementptr i64, i64* %3, i64 3
    store i64 1, i64* %data2, align 4
    %4 = load i64*, i64** %arr, align 8
    %data3 = getelementptr i64, i64* %4, i64 3
    %5 = load i64, i64* %data3, align 4
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %5)
    %6 = add i32 %fmtsize, 32
    %7 = sext i32 %6 to i64
    %8 = call i8* @malloc(i64 %7)
    %9 = bitcast i8* %8 to i64*
    store i64 1, i64* %9, align 4
    %size5 = getelementptr i64, i64* %9, i64 1
    %10 = sext i32 %fmtsize to i64
    store i64 %10, i64* %size5, align 4
    %cap6 = getelementptr i64, i64* %9, i64 2
    store i64 %10, i64* %cap6, align 4
    %data7 = getelementptr i64, i64* %9, i64 3
    %11 = bitcast i64* %data7 to i8*
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %7, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %5)
    %str = alloca i8*, align 8
    store i8* %8, i8** %str, align 8
    call void @schmu_print(i8* %8)
    %fmtsize8 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %const)
    %12 = add i32 %fmtsize8, 32
    %13 = sext i32 %12 to i64
    %14 = call i8* @malloc(i64 %13)
    %15 = bitcast i8* %14 to i64*
    store i64 1, i64* %15, align 4
    %size10 = getelementptr i64, i64* %15, i64 1
    %16 = sext i32 %fmtsize8 to i64
    store i64 %16, i64* %size10, align 4
    %cap11 = getelementptr i64, i64* %15, i64 2
    store i64 %16, i64* %cap11, align 4
    %data12 = getelementptr i64, i64* %15, i64 3
    %17 = bitcast i64* %data12 to i8*
    %fmt13 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %17, i64 %13, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %const)
    %str14 = alloca i8*, align 8
    store i8* %14, i8** %str14, align 8
    call void @schmu_print(i8* %14)
    call void @__g.u_decr_rc_ac.u(i8* %14)
    call void @__g.u_decr_rc_ac.u(i8* %8)
    %18 = load i64*, i64** %arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %18)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 4
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %3 = mul i64 %cap2, 8
    %4 = add i64 %3, 24
    %5 = call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    %7 = mul i64 %size, 8
    %8 = add i64 %7, 24
    %9 = bitcast i64* %6 to i8*
    %10 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 %8, i1 false)
    store i64* %6, i64** %0, align 8
    %ref35 = bitcast i64* %6 to i64*
    store i64 1, i64* %ref35, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @v, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 0, i64* %data, align 4
    %2 = load i64*, i64** @v, align 8
    store i64* %2, i64** @v, align 8
    %data1 = getelementptr i64, i64* %2, i64 3
    %3 = load i64, i64* %data1, align 4
    store i64 %3, i64* @const, align 4
    %4 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @v)
    %data2 = getelementptr i64, i64* %4, i64 3
    store i64 1, i64* %data2, align 4
    %5 = load i64*, i64** @v, align 8
    %data3 = getelementptr i64, i64* %5, i64 3
    %6 = load i64, i64* %data3, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %6)
    %7 = add i32 %fmtsize, 32
    %8 = sext i32 %7 to i64
    %9 = tail call i8* @malloc(i64 %8)
    %10 = bitcast i8* %9 to i64*
    store i64 1, i64* %10, align 4
    %size5 = getelementptr i64, i64* %10, i64 1
    %11 = sext i32 %fmtsize to i64
    store i64 %11, i64* %size5, align 4
    %cap6 = getelementptr i64, i64* %10, i64 2
    store i64 %11, i64* %cap6, align 4
    %data7 = getelementptr i64, i64* %10, i64 3
    %12 = bitcast i64* %data7 to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %8, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %6)
    %str = alloca i8*, align 8
    store i8* %9, i8** %str, align 8
    tail call void @schmu_print(i8* %9)
    %13 = load i64, i64* @const, align 4
    %fmtsize8 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %13)
    %14 = add i32 %fmtsize8, 32
    %15 = sext i32 %14 to i64
    %16 = tail call i8* @malloc(i64 %15)
    %17 = bitcast i8* %16 to i64*
    store i64 1, i64* %17, align 4
    %size10 = getelementptr i64, i64* %17, i64 1
    %18 = sext i32 %fmtsize8 to i64
    store i64 %18, i64* %size10, align 4
    %cap11 = getelementptr i64, i64* %17, i64 2
    store i64 %18, i64* %cap11, align 4
    %data12 = getelementptr i64, i64* %17, i64 3
    %19 = bitcast i64* %data12 to i8*
    %fmt13 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %19, i64 %15, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %13)
    %str14 = alloca i8*, align 8
    store i8* %16, i8** %str14, align 8
    tail call void @schmu_print(i8* %16)
    tail call void @schmu_in-fun()
    tail call void @__g.u_decr_rc_ac.u(i8* %16)
    tail call void @__g.u_decr_rc_ac.u(i8* %9)
    %20 = load i64*, i64** @v, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %20)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  1
  0
  1
  0


Copies, but with ref-counted arrays
  $ schmu array_copies.smu --dump-llvm && ./array_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @a = global i64* null, align 8
  @b = global i64* null, align 8
  @c = global i64* null, align 8
  @d = global i64* null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [7 x i8] } { i64 2, i64 6, i64 6, [7 x i8] c"in fun\00" }
  @1 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @schmu_print(i8* %0)
  
  define void @schmu_in-fun() {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [7 x i8] }* @0 to i8*), i8** %str, align 8
    tail call void @schmu_print(i8* bitcast ({ i64, i64, i64, [7 x i8] }* @0 to i8*))
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 10, i64* %data, align 4
    %2 = load i64*, i64** %arr, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %2)
    tail call void @__g.u_incr_rc_ai.u(i64* %2)
    %c = alloca i64*, align 8
    %3 = bitcast i64** %c to i8*
    %4 = bitcast i64** %arr to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 8, i1 false)
    tail call void @__g.u_incr_rc_ai.u(i64* %2)
    %5 = call i64* @__ag.ag_reloc_ai.ai(i64** %arr)
    %data1 = getelementptr i64, i64* %5, i64 3
    store i64 12, i64* %data1, align 4
    %6 = load i64*, i64** %arr, align 8
    call void @schmu___ag.u_print-0th_ai.u(i64* %6)
    %7 = call i64* @__ag.ag_reloc_ai.ai(i64** %c)
    %data2 = getelementptr i64, i64* %7, i64 3
    store i64 15, i64* %data2, align 4
    %8 = load i64*, i64** %arr, align 8
    call void @schmu___ag.u_print-0th_ai.u(i64* %8)
    call void @schmu___ag.u_print-0th_ai.u(i64* %2)
    %9 = load i64*, i64** %c, align 8
    call void @schmu___ag.u_print-0th_ai.u(i64* %9)
    call void @schmu___ag.u_print-0th_ai.u(i64* %2)
    call void @__g.u_decr_rc_ai.u(i64* %2)
    %10 = load i64*, i64** %c, align 8
    call void @__g.u_decr_rc_ai.u(i64* %10)
    call void @__g.u_decr_rc_ai.u(i64* %2)
    %11 = load i64*, i64** %arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %11)
    ret void
  }
  
  define void @schmu___ag.u_print-0th_ai.u(i64* %a) {
  entry:
    %data = getelementptr i64, i64* %a, i64 3
    %0 = load i64, i64* %data, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @1, i32 0, i32 0), i64 3) to i8*), i64 %0)
    %1 = add i32 %fmtsize, 32
    %2 = sext i32 %1 to i64
    %3 = tail call i8* @malloc(i64 %2)
    %4 = bitcast i8* %3 to i64*
    store i64 1, i64* %4, align 4
    %size = getelementptr i64, i64* %4, i64 1
    %5 = sext i32 %fmtsize to i64
    store i64 %5, i64* %size, align 4
    %cap = getelementptr i64, i64* %4, i64 2
    store i64 %5, i64* %cap, align 4
    %data1 = getelementptr i64, i64* %4, i64 3
    %6 = bitcast i64* %data1 to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %2, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @1, i32 0, i32 0), i64 3) to i8*), i64 %0)
    %str = alloca i8*, align 8
    store i8* %3, i8** %str, align 8
    tail call void @schmu_print(i8* %3)
    tail call void @__g.u_decr_rc_ac.u(i8* %3)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_incr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 4
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 4
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %3 = mul i64 %cap2, 8
    %4 = add i64 %3, 24
    %5 = call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    %7 = mul i64 %size, 8
    %8 = add i64 %7, 24
    %9 = bitcast i64* %6 to i8*
    %10 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 %8, i1 false)
    store i64* %6, i64** %0, align 8
    %ref35 = bitcast i64* %6 to i64*
    store i64 1, i64* %ref35, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @a, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 10, i64* %data, align 4
    %2 = load i64*, i64** @a, align 8
    store i64* %2, i64** @a, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %2)
    store i64* %2, i64** @b, align 8
    %3 = load i64*, i64** @a, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %3)
    store i64* %3, i64** @c, align 8
    %4 = load i64*, i64** @b, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %4)
    store i64* %4, i64** @d, align 8
    %5 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @a)
    %data1 = getelementptr i64, i64* %5, i64 3
    store i64 12, i64* %data1, align 4
    %6 = load i64*, i64** @a, align 8
    tail call void @schmu___ag.u_print-0th_ai.u(i64* %6)
    %7 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @c)
    %data2 = getelementptr i64, i64* %7, i64 3
    store i64 15, i64* %data2, align 4
    %8 = load i64*, i64** @a, align 8
    tail call void @schmu___ag.u_print-0th_ai.u(i64* %8)
    %9 = load i64*, i64** @b, align 8
    tail call void @schmu___ag.u_print-0th_ai.u(i64* %9)
    %10 = load i64*, i64** @c, align 8
    tail call void @schmu___ag.u_print-0th_ai.u(i64* %10)
    %11 = load i64*, i64** @d, align 8
    tail call void @schmu___ag.u_print-0th_ai.u(i64* %11)
    tail call void @schmu_in-fun()
    %12 = load i64*, i64** @d, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %12)
    %13 = load i64*, i64** @c, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %13)
    %14 = load i64*, i64** @b, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %14)
    %15 = load i64*, i64** @a, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %15)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  12
  12
  10
  15
  10
  in fun
  12
  12
  10
  15
  10


  $ schmu array_in_record_copies.smu --dump-llvm && ./array_in_record_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %arrec = type { i64* }
  
  @a = global %arrec zeroinitializer, align 8
  @b = global %arrec zeroinitializer, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  @1 = private unnamed_addr global { i64, i64, i64, [7 x i8] } { i64 2, i64 6, i64 6, [7 x i8] c"in fun\00" }
  
  declare void @schmu_print(i8* %0)
  
  define void @schmu_in-fun() {
  entry:
    %0 = alloca %arrec, align 8
    %a5 = bitcast %arrec* %0 to i64**
    %1 = tail call i8* @malloc(i64 32)
    %2 = bitcast i8* %1 to i64*
    %arr = alloca i64*, align 8
    store i64* %2, i64** %arr, align 8
    store i64 1, i64* %2, align 4
    %size = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %2, i64 3
    store i64 10, i64* %data, align 4
    store i64* %2, i64** %a5, align 8
    call void @__g.u_incr_rc_arrec.u(%arrec* %0)
    %b = alloca %arrec, align 8
    %3 = bitcast %arrec* %b to i8*
    %4 = bitcast %arrec* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 8, i1 false)
    %5 = call i64* @__ag.ag_reloc_ai.ai(i64** %a5)
    %data1 = getelementptr i64, i64* %5, i64 3
    store i64 12, i64* %data1, align 4
    %unbox = bitcast %arrec* %0 to i64*
    %unbox2 = load i64, i64* %unbox, align 4
    call void @schmu_print-thing(i64 %unbox2)
    %unbox3 = bitcast %arrec* %b to i64*
    %unbox4 = load i64, i64* %unbox3, align 4
    call void @schmu_print-thing(i64 %unbox4)
    call void @__g.u_decr_rc_arrec.u(%arrec* %b)
    call void @__g.u_decr_rc_arrec.u(%arrec* %0)
    ret void
  }
  
  define void @schmu_print-thing(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %1 = inttoptr i64 %0 to i64*
    %data = getelementptr i64, i64* %1, i64 3
    %2 = load i64, i64* %data, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %2)
    %3 = add i32 %fmtsize, 32
    %4 = sext i32 %3 to i64
    %5 = tail call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    store i64 1, i64* %6, align 4
    %size = getelementptr i64, i64* %6, i64 1
    %7 = sext i32 %fmtsize to i64
    store i64 %7, i64* %size, align 4
    %cap = getelementptr i64, i64* %6, i64 2
    store i64 %7, i64* %cap, align 4
    %data2 = getelementptr i64, i64* %6, i64 3
    %8 = bitcast i64* %data2 to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %8, i64 %4, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %2)
    %str = alloca i8*, align 8
    store i8* %5, i8** %str, align 8
    tail call void @schmu_print(i8* %5)
    tail call void @__g.u_decr_rc_ac.u(i8* %5)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_incr_rc_arrec.u(%arrec* %0) {
  entry:
    %1 = bitcast %arrec* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %ref2 = bitcast i64* %2 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %3 = add i64 %ref1, 1
    store i64 %3, i64* %ref2, align 4
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 4
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %3 = mul i64 %cap2, 8
    %4 = add i64 %3, 24
    %5 = call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    %7 = mul i64 %size, 8
    %8 = add i64 %7, 24
    %9 = bitcast i64* %6 to i8*
    %10 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 %8, i1 false)
    store i64* %6, i64** %0, align 8
    %ref35 = bitcast i64* %6 to i64*
    store i64 1, i64* %ref35, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_arrec.u(%arrec* %0) {
  entry:
    %1 = bitcast %arrec* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %ref2 = bitcast i64* %2 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %3 = icmp eq i64 %ref1, 1
    br i1 %3, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %4 = bitcast i64* %2 to i64*
    %5 = sub i64 %ref1, 1
    store i64 %5, i64* %4, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %6 = bitcast i64* %2 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 10, i64* %data, align 4
    store i64* %1, i64** getelementptr inbounds (%arrec, %arrec* @a, i32 0, i32 0), align 8
    tail call void @__g.u_incr_rc_arrec.u(%arrec* @a)
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%arrec* @b to i8*), i8* bitcast (%arrec* @a to i8*), i64 8, i1 false)
    %2 = tail call i64* @__ag.ag_reloc_ai.ai(i64** getelementptr inbounds (%arrec, %arrec* @a, i32 0, i32 0))
    %data1 = getelementptr i64, i64* %2, i64 3
    store i64 12, i64* %data1, align 4
    %unbox = load i64, i64* bitcast (%arrec* @a to i64*), align 4
    tail call void @schmu_print-thing(i64 %unbox)
    %unbox2 = load i64, i64* bitcast (%arrec* @b to i64*), align 4
    tail call void @schmu_print-thing(i64 %unbox2)
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [7 x i8] }* @1 to i8*), i8** %str, align 8
    tail call void @schmu_print(i8* bitcast ({ i64, i64, i64, [7 x i8] }* @1 to i8*))
    tail call void @schmu_in-fun()
    tail call void @__g.u_decr_rc_arrec.u(%arrec* @b)
    tail call void @__g.u_decr_rc_arrec.u(%arrec* @a)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  12
  10
  in fun
  12
  10


  $ schmu nested_array.smu --dump-llvm && ./nested_array
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @a = global i64** null, align 8
  @b = global i64** null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [9 x i8] } { i64 2, i64 8, i64 8, [9 x i8] c"%li, %li\00" }
  
  declare void @schmu_print(i8* %0)
  
  define void @schmu___aag.u_prnt_aai.u(i64** %a) {
  entry:
    %0 = bitcast i64** %a to i64*
    %data = getelementptr i64, i64* %0, i64 3
    %1 = bitcast i64* %data to i64**
    %2 = load i64*, i64** %1, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %2)
    %3 = load i64*, i64** %1, align 8
    %data1 = getelementptr i64, i64* %3, i64 3
    %4 = load i64, i64* %data1, align 4
    %5 = getelementptr i64*, i64** %1, i64 1
    %6 = load i64*, i64** %5, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %6)
    %7 = load i64*, i64** %5, align 8
    %data3 = getelementptr i64, i64* %7, i64 3
    %8 = load i64, i64* %data3, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [9 x i8] }, { i64, i64, i64, [9 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %4, i64 %8)
    %9 = add i32 %fmtsize, 32
    %10 = sext i32 %9 to i64
    %11 = tail call i8* @malloc(i64 %10)
    %12 = bitcast i8* %11 to i64*
    store i64 1, i64* %12, align 4
    %size = getelementptr i64, i64* %12, i64 1
    %13 = sext i32 %fmtsize to i64
    store i64 %13, i64* %size, align 4
    %cap = getelementptr i64, i64* %12, i64 2
    store i64 %13, i64* %cap, align 4
    %data4 = getelementptr i64, i64* %12, i64 3
    %14 = bitcast i64* %data4 to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %14, i64 %10, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [9 x i8] }, { i64, i64, i64, [9 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %4, i64 %8)
    %str = alloca i8*, align 8
    store i8* %11, i8** %str, align 8
    tail call void @schmu_print(i8* %11)
    tail call void @__g.u_decr_rc_ac.u(i8* %11)
    %15 = load i64*, i64** %5, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %15)
    %16 = load i64*, i64** %1, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %16)
    ret void
  }
  
  define internal void @__g.u_incr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 4
    ret void
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64**
    store i64** %1, i64*** @a, align 8
    %2 = bitcast i64** %1 to i64*
    store i64 1, i64* %2, align 4
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 4
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 4
    %data = getelementptr i64, i64* %2, i64 3
    %3 = bitcast i64* %data to i64**
    %4 = tail call i8* @malloc(i64 32)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %3, align 8
    store i64 1, i64* %5, align 4
    %size2 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %size2, align 4
    %cap3 = getelementptr i64, i64* %5, i64 2
    store i64 1, i64* %cap3, align 4
    %data4 = getelementptr i64, i64* %5, i64 3
    store i64 10, i64* %data4, align 4
    %"1" = getelementptr i64*, i64** %3, i64 1
    %6 = tail call i8* @malloc(i64 32)
    %7 = bitcast i8* %6 to i64*
    store i64* %7, i64** %"1", align 8
    store i64 1, i64* %7, align 4
    %size7 = getelementptr i64, i64* %7, i64 1
    store i64 1, i64* %size7, align 4
    %cap8 = getelementptr i64, i64* %7, i64 2
    store i64 1, i64* %cap8, align 4
    %data9 = getelementptr i64, i64* %7, i64 3
    store i64 20, i64* %data9, align 4
    %8 = load i64**, i64*** @a, align 8
    store i64** %8, i64*** @a, align 8
    tail call void @__g.u_incr_rc_aai.u(i64** %8)
    store i64** %8, i64*** @b, align 8
    %9 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @a)
    %10 = bitcast i64** %9 to i64*
    %data11 = getelementptr i64, i64* %10, i64 3
    %11 = bitcast i64* %data11 to i64**
    %12 = tail call i64* @__ag.ag_reloc_ai.ai(i64** %11)
    %data12 = getelementptr i64, i64* %12, i64 3
    store i64 15, i64* %data12, align 4
    %13 = load i64**, i64*** @a, align 8
    tail call void @schmu___aag.u_prnt_aai.u(i64** %13)
    %14 = load i64**, i64*** @b, align 8
    tail call void @schmu___aag.u_prnt_aai.u(i64** %14)
    %15 = load i64**, i64*** @b, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %15)
    %16 = load i64**, i64*** @a, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %16)
    ret i64 0
  }
  
  define internal void @__g.u_incr_rc_aai.u(i64** %0) {
  entry:
    %ref = bitcast i64** %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 4
    ret void
  }
  
  define internal i64** @__ag.ag_reloc_aai.aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %ref17 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref17, align 4
    %2 = icmp sgt i64 %ref2, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %3 = bitcast i64** %1 to i64*
    %sz = getelementptr i64, i64* %3, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %3, i64 2
    %cap3 = load i64, i64* %cap, align 4
    %4 = mul i64 %cap3, 8
    %5 = add i64 %4, 24
    %6 = call i8* @malloc(i64 %5)
    %7 = bitcast i8* %6 to i64**
    %8 = mul i64 %size, 8
    %9 = add i64 %8, 24
    %10 = bitcast i64** %7 to i8*
    %11 = bitcast i64** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %11, i64 %9, i1 false)
    store i64** %7, i64*** %0, align 8
    %ref4 = bitcast i64** %7 to i64*
    %ref58 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref58, align 4
    call void @__g.u_decr_rc_aai.u(i64** %1)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  merge:                                            ; preds = %rec, %entry
    %12 = load i64**, i64*** %0, align 8
    ret i64** %12
  
  rec:                                              ; preds = %child, %relocate
    %13 = load i64, i64* %cnt, align 4
    %14 = icmp slt i64 %13, %size
    br i1 %14, label %child, label %merge
  
  child:                                            ; preds = %rec
    %sunkaddr = mul i64 %13, 8
    %15 = bitcast i64** %1 to i8*
    %sunkaddr9 = getelementptr i8, i8* %15, i64 %sunkaddr
    %sunkaddr10 = getelementptr i8, i8* %sunkaddr9, i64 24
    %16 = bitcast i8* %sunkaddr10 to i64**
    %17 = load i64*, i64** %16, align 8
    call void @__g.u_incr_rc_ai.u(i64* %17)
    %18 = add i64 %13, 1
    store i64 %18, i64* %cnt, align 4
    br label %rec
  }
  
  define internal void @__g.u_decr_rc_aai.u(i64** %0) {
  entry:
    %ref = bitcast i64** %0 to i64*
    %ref14 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref14, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64** %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i64** %0 to i64*
    %sz = getelementptr i64, i64* %5, i64 1
    %size = load i64, i64* %sz, align 4
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %6 = load i64, i64* %cnt, align 4
    %7 = icmp slt i64 %6, %size
    br i1 %7, label %child, label %cont
  
  child:                                            ; preds = %rec
    %sunkaddr = mul i64 %6, 8
    %8 = bitcast i64** %0 to i8*
    %sunkaddr5 = getelementptr i8, i8* %8, i64 %sunkaddr
    %sunkaddr6 = getelementptr i8, i8* %sunkaddr5, i64 24
    %9 = bitcast i8* %sunkaddr6 to i64**
    %10 = load i64*, i64** %9, align 8
    call void @__g.u_decr_rc_ai.u(i64* %10)
    %11 = add i64 %6, 1
    store i64 %11, i64* %cnt, align 4
    br label %rec
  
  cont:                                             ; preds = %rec
    %12 = bitcast i64** %0 to i64*
    %13 = bitcast i64* %12 to i8*
    call void @free(i8* %13)
    br label %merge
  }
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 4
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %3 = mul i64 %cap2, 8
    %4 = add i64 %3, 24
    %5 = call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    %7 = mul i64 %size, 8
    %8 = add i64 %7, 24
    %9 = bitcast i64* %6 to i8*
    %10 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 %8, i1 false)
    store i64* %6, i64** %0, align 8
    %ref35 = bitcast i64* %6 to i64*
    store i64 1, i64* %ref35, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  15, 20
  10, 20


  $ schmu --dump-llvm modify_in_fn.smu && valgrind -q --leak-check=yes ./modify_in_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %f = type { i64 }
  
  @a = global %f zeroinitializer, align 8
  @b = global i64* null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @schmu_print(i8* %0)
  
  define void @schmu_mod2(i64** %a) {
  entry:
    %0 = load i64*, i64** %a, align 8
    %size = getelementptr i64, i64* %0, i64 1
    %size1 = load i64, i64* %size, align 4
    %cap = getelementptr i64, i64* %0, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %1 = icmp eq i64 %cap2, %size1
    br i1 %1, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %2 = tail call i64* @__ag.ag_reloc_ai.ai(i64** %a)
    br label %merge
  
  grow:                                             ; preds = %entry
    %3 = tail call i64* @__ag.ag_grow_ai.ai(i64** %a)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %4 = phi i64* [ %2, %keep ], [ %3, %grow ]
    %data = getelementptr i64, i64* %4, i64 3
    %5 = getelementptr i64, i64* %data, i64 %size1
    store i64 20, i64* %5, align 4
    %size3 = getelementptr i64, i64* %4, i64 1
    %6 = add i64 %size1, 1
    store i64 %6, i64* %size3, align 4
    ret void
  }
  
  define void @schmu_modify(%f* %r) {
  entry:
    %0 = bitcast %f* %r to i64*
    store i64 30, i64* %0, align 4
    ret void
  }
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 4
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %3 = mul i64 %cap2, 8
    %4 = add i64 %3, 24
    %5 = call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    %7 = mul i64 %size, 8
    %8 = add i64 %7, 24
    %9 = bitcast i64* %6 to i8*
    %10 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 %8, i1 false)
    store i64* %6, i64** %0, align 8
    %ref35 = bitcast i64* %6 to i64*
    store i64 1, i64* %ref35, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal i64* @__ag.ag_grow_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap1 = load i64, i64* %cap, align 4
    %2 = mul i64 %cap1, 2
    %ref5 = bitcast i64* %1 to i64*
    %ref2 = load i64, i64* %ref5, align 4
    %3 = mul i64 %2, 8
    %4 = add i64 %3, 24
    %5 = icmp eq i64 %ref2, 1
    br i1 %5, label %realloc, label %malloc
  
  realloc:                                          ; preds = %entry
    %6 = load i64*, i64** %0, align 8
    %7 = bitcast i64* %6 to i8*
    %8 = call i8* @realloc(i8* %7, i64 %4)
    %9 = bitcast i8* %8 to i64*
    store i64* %9, i64** %0, align 8
    br label %merge
  
  malloc:                                           ; preds = %entry
    %10 = call i8* @malloc(i64 %4)
    %11 = bitcast i8* %10 to i64*
    %size = getelementptr i64, i64* %1, i64 1
    %size3 = load i64, i64* %size, align 4
    %12 = mul i64 %size3, 8
    %13 = add i64 %12, 24
    %14 = bitcast i64* %11 to i8*
    %15 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %14, i8* %15, i64 %13, i1 false)
    store i64* %11, i64** %0, align 8
    %ref46 = bitcast i64* %11 to i64*
    store i64 1, i64* %ref46, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %malloc, %realloc
    %16 = phi i64* [ %9, %realloc ], [ %11, %malloc ]
    %newcap = getelementptr i64, i64* %16, i64 2
    store i64 %2, i64* %newcap, align 4
    %17 = load i64*, i64** %0, align 8
    ret i64* %17
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 20, i64* getelementptr inbounds (%f, %f* @a, i32 0, i32 0), align 4
    tail call void @schmu_modify(%f* @a)
    %0 = load i64, i64* getelementptr inbounds (%f, %f* @a, i32 0, i32 0), align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %0)
    %1 = add i32 %fmtsize, 32
    %2 = sext i32 %1 to i64
    %3 = tail call i8* @malloc(i64 %2)
    %4 = bitcast i8* %3 to i64*
    store i64 1, i64* %4, align 4
    %size = getelementptr i64, i64* %4, i64 1
    %5 = sext i32 %fmtsize to i64
    store i64 %5, i64* %size, align 4
    %cap = getelementptr i64, i64* %4, i64 2
    store i64 %5, i64* %cap, align 4
    %data = getelementptr i64, i64* %4, i64 3
    %6 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %2, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %0)
    %str = alloca i8*, align 8
    store i8* %3, i8** %str, align 8
    tail call void @schmu_print(i8* %3)
    %7 = tail call i8* @malloc(i64 32)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** @b, align 8
    store i64 1, i64* %8, align 4
    %size2 = getelementptr i64, i64* %8, i64 1
    store i64 1, i64* %size2, align 4
    %cap3 = getelementptr i64, i64* %8, i64 2
    store i64 1, i64* %cap3, align 4
    %data4 = getelementptr i64, i64* %8, i64 3
    store i64 10, i64* %data4, align 4
    %9 = load i64*, i64** @b, align 8
    store i64* %9, i64** @b, align 8
    tail call void @schmu_mod2(i64** @b)
    %10 = load i64*, i64** @b, align 8
    %len = getelementptr i64, i64* %10, i64 1
    %11 = load i64, i64* %len, align 4
    %fmtsize5 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %11)
    %12 = add i32 %fmtsize5, 32
    %13 = sext i32 %12 to i64
    %14 = tail call i8* @malloc(i64 %13)
    %15 = bitcast i8* %14 to i64*
    store i64 1, i64* %15, align 4
    %size7 = getelementptr i64, i64* %15, i64 1
    %16 = sext i32 %fmtsize5 to i64
    store i64 %16, i64* %size7, align 4
    %cap8 = getelementptr i64, i64* %15, i64 2
    store i64 %16, i64* %cap8, align 4
    %data9 = getelementptr i64, i64* %15, i64 3
    %17 = bitcast i64* %data9 to i8*
    %fmt10 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %17, i64 %13, i8* bitcast (i64* getelementptr (i64, i64* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i32 0, i32 0), i64 3) to i8*), i64 %11)
    %str11 = alloca i8*, align 8
    store i8* %14, i8** %str11, align 8
    tail call void @schmu_print(i8* %14)
    tail call void @__g.u_decr_rc_ac.u(i8* %14)
    %18 = load i64*, i64** @b, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %18)
    tail call void @__g.u_decr_rc_ac.u(i8* %3)
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 4
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 4
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
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  30
  2

Make sure variable ids are correctly propagated
  $ schmu --dump-llvm varid_propagate.smu && valgrind -q --leak-check=yes ./varid_propagate
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64* @schmu___agg.ag_f1_aii.ai(i64* %acc, i64 %v) {
  entry:
    tail call void @__g.u_incr_rc_ai.u(i64* %acc)
    %tmp = alloca i64*, align 8
    store i64* %acc, i64** %tmp, align 8
    %size = getelementptr i64, i64* %acc, i64 1
    %size1 = load i64, i64* %size, align 4
    %cap = getelementptr i64, i64* %acc, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %0 = icmp eq i64 %cap2, %size1
    br i1 %0, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %1 = call i64* @__ag.ag_reloc_ai.ai(i64** %tmp)
    br label %merge
  
  grow:                                             ; preds = %entry
    %2 = call i64* @__ag.ag_grow_ai.ai(i64** %tmp)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %3 = phi i64* [ %1, %keep ], [ %2, %grow ]
    %data = getelementptr i64, i64* %3, i64 3
    %4 = getelementptr i64, i64* %data, i64 %size1
    store i64 %v, i64* %4, align 4
    %size3 = getelementptr i64, i64* %3, i64 1
    %5 = add i64 %size1, 1
    store i64 %5, i64* %size3, align 4
    %6 = load i64*, i64** %tmp, align 8
    ret i64* %6
  }
  
  define internal void @__g.u_incr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 4
    ret void
  }
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 4
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %3 = mul i64 %cap2, 8
    %4 = add i64 %3, 24
    %5 = call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    %7 = mul i64 %size, 8
    %8 = add i64 %7, 24
    %9 = bitcast i64* %6 to i8*
    %10 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 %8, i1 false)
    store i64* %6, i64** %0, align 8
    %ref35 = bitcast i64* %6 to i64*
    store i64 1, i64* %ref35, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal i64* @__ag.ag_grow_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap1 = load i64, i64* %cap, align 4
    %2 = mul i64 %cap1, 2
    %ref5 = bitcast i64* %1 to i64*
    %ref2 = load i64, i64* %ref5, align 4
    %3 = mul i64 %2, 8
    %4 = add i64 %3, 24
    %5 = icmp eq i64 %ref2, 1
    br i1 %5, label %realloc, label %malloc
  
  realloc:                                          ; preds = %entry
    %6 = load i64*, i64** %0, align 8
    %7 = bitcast i64* %6 to i8*
    %8 = call i8* @realloc(i8* %7, i64 %4)
    %9 = bitcast i8* %8 to i64*
    store i64* %9, i64** %0, align 8
    br label %merge
  
  malloc:                                           ; preds = %entry
    %10 = call i8* @malloc(i64 %4)
    %11 = bitcast i8* %10 to i64*
    %size = getelementptr i64, i64* %1, i64 1
    %size3 = load i64, i64* %size, align 4
    %12 = mul i64 %size3, 8
    %13 = add i64 %12, 24
    %14 = bitcast i64* %11 to i8*
    %15 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %14, i8* %15, i64 %13, i1 false)
    store i64* %11, i64** %0, align 8
    %ref46 = bitcast i64* %11 to i64*
    store i64 1, i64* %ref46, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %malloc, %realloc
    %16 = phi i64* [ %9, %realloc ], [ %11, %malloc ]
    %newcap = getelementptr i64, i64* %16, i64 2
    store i64 %2, i64* %newcap, align 4
    %17 = load i64*, i64** %0, align 8
    ret i64* %17
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 0, i64* %data, align 4
    %2 = tail call i64* @schmu___agg.ag_f1_aii.ai(i64* %1, i64 0)
    tail call void @__g.u_decr_rc_ai.u(i64* %2)
    tail call void @__g.u_decr_rc_ai.u(i64* %1)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Free array params correctly if they are returned
  $ schmu --dump-llvm pass_array_param.smu && valgrind -q --leak-check=yes ./pass_array_param
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64* @schmu_create() {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 10, i64* %data, align 4
    %2 = tail call i64* @schmu___g.g_pass_ai.ai(i64* %1)
    tail call void @__g.u_decr_rc_ai.u(i64* %1)
    ret i64* %2
  }
  
  define i64* @schmu___g.g_pass_ai.ai(i64* %x) {
  entry:
    tail call void @__g.u_incr_rc_ai.u(i64* %x)
    ret i64* %x
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_incr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 4
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64* @schmu_create()
    tail call void @__g.u_decr_rc_ai.u(i64* %0)
    ret i64 0
  }
  
  declare void @free(i8* %0)
