Test simple setting of mutable variables
  $ schmu --dump-llvm simple_set.smu && valgrind -q --leak-check=yes ./simple_set
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @b = global i64 0, align 8
  @a = global i64** null, align 8
  @b__2 = global i64** null, align 8
  @c = global i64* null, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
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
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 14)
    %0 = add i32 %fmtsize, 1
    %1 = sext i32 %0 to i64
    %2 = tail call i8* @malloc(i64 %1)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %2, i64 %1, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 14)
    %str = alloca %string, align 8
    %cstr38 = bitcast %string* %str to i8**
    store i8* %2, i8** %cstr38, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %3 = mul i64 %1, -1
    store i64 %3, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %4 = ptrtoint i8* %2 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %4, i64 %3)
    %5 = tail call i64 @schmu_hmm()
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %5)
    %6 = add i32 %fmtsize3, 1
    %7 = sext i32 %6 to i64
    %8 = tail call i8* @malloc(i64 %7)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %8, i64 %7, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %5)
    %str5 = alloca %string, align 8
    %cstr640 = bitcast %string* %str5 to i8**
    store i8* %8, i8** %cstr640, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %9 = mul i64 %7, -1
    store i64 %9, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %10 = ptrtoint i8* %8 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %10, i64 %9)
    %11 = tail call i8* @malloc(i64 40)
    %12 = bitcast i8* %11 to i64**
    store i64** %12, i64*** @a, align 8
    %13 = bitcast i64** %12 to i64*
    store i64 1, i64* %13, align 4
    %size = getelementptr i64, i64* %13, i64 1
    store i64 2, i64* %size, align 4
    %cap = getelementptr i64, i64* %13, i64 2
    store i64 2, i64* %cap, align 4
    %data = getelementptr i64, i64* %13, i64 3
    %14 = bitcast i64* %data to i64**
    %15 = tail call i8* @malloc(i64 32)
    %16 = bitcast i8* %15 to i64*
    store i64* %16, i64** %14, align 8
    store i64 1, i64* %16, align 4
    %size14 = getelementptr i64, i64* %16, i64 1
    store i64 1, i64* %size14, align 4
    %cap15 = getelementptr i64, i64* %16, i64 2
    store i64 1, i64* %cap15, align 4
    %data16 = getelementptr i64, i64* %16, i64 3
    store i64 10, i64* %data16, align 4
    %"1" = getelementptr i64*, i64** %14, i64 1
    %17 = tail call i8* @malloc(i64 32)
    %18 = bitcast i8* %17 to i64*
    store i64* %18, i64** %"1", align 8
    store i64 1, i64* %18, align 4
    %size19 = getelementptr i64, i64* %18, i64 1
    store i64 1, i64* %size19, align 4
    %cap20 = getelementptr i64, i64* %18, i64 2
    store i64 1, i64* %cap20, align 4
    %data21 = getelementptr i64, i64* %18, i64 3
    store i64 20, i64* %data21, align 4
    %19 = load i64**, i64*** @a, align 8
    store i64** %19, i64*** @a, align 8
    tail call void @__g.u_incr_rc_aai.u(i64** %19)
    store i64** %19, i64*** @b__2, align 8
    %20 = tail call i8* @malloc(i64 32)
    %21 = bitcast i8* %20 to i64*
    store i64* %21, i64** @c, align 8
    store i64 1, i64* %21, align 4
    %size24 = getelementptr i64, i64* %21, i64 1
    store i64 1, i64* %size24, align 4
    %cap25 = getelementptr i64, i64* %21, i64 2
    store i64 1, i64* %cap25, align 4
    %data26 = getelementptr i64, i64* %21, i64 3
    store i64 30, i64* %data26, align 4
    %22 = load i64*, i64** @c, align 8
    store i64* %22, i64** @c, align 8
    %23 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @a)
    %24 = bitcast i64** %23 to i64*
    %data28 = getelementptr i64, i64* %24, i64 3
    %25 = bitcast i64* %data28 to i64**
    %26 = load i64*, i64** %25, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %26)
    %27 = load i64*, i64** @c, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %27)
    %28 = load i64*, i64** @c, align 8
    store i64* %28, i64** %25, align 8
    %29 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @a)
    %30 = bitcast i64** %29 to i64*
    %data29 = getelementptr i64, i64* %30, i64 3
    %31 = bitcast i64* %data29 to i64**
    %32 = load i64*, i64** %31, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %32)
    %33 = tail call i8* @malloc(i64 32)
    %34 = bitcast i8* %33 to i64*
    %arr = alloca i64*, align 8
    store i64* %34, i64** %arr, align 8
    store i64 1, i64* %34, align 4
    %size31 = getelementptr i64, i64* %34, i64 1
    store i64 1, i64* %size31, align 4
    %cap32 = getelementptr i64, i64* %34, i64 2
    store i64 1, i64* %cap32, align 4
    %data33 = getelementptr i64, i64* %34, i64 3
    store i64 10, i64* %data33, align 4
    store i64* %34, i64** %31, align 8
    %35 = load i64**, i64*** @b__2, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %35)
    %36 = load i64*, i64** @c, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %36)
    %37 = load i64**, i64*** @a, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %37)
    %owned = icmp slt i64 %9, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %8)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %38 = bitcast %string* %str to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %38, i64 8
    %39 = bitcast i8* %sunkaddr to i64*
    %40 = load i64, i64* %39, align 4
    %owned37 = icmp slt i64 %40, 0
    br i1 %owned37, label %free35, label %cont36
  
  free35:                                           ; preds = %cont
    %41 = bitcast %string* %str to i8**
    %42 = load i8*, i8** %41, align 8
    tail call void @free(i8* %42)
    br label %cont36
  
  cont36:                                           ; preds = %free35, %cont
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
  
  declare void @free(i8* %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
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

Make sure there is no aliasing here
  $ schmu --dump-llvm copies.smu && valgrind -q --leak-check=yes ./copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { %owned_ptr_int, i64 }
  %owned_ptr_int = type { i64*, i64 }
  %vector_foo = type { %owned_ptr_foo, i64 }
  %owned_ptr_foo = type { %foo*, i64 }
  %foo = type { i64 }
  %string = type { i8*, i64 }
  
  @v = global %vector_int zeroinitializer, align 16
  @fst = global i64 0, align 8
  @v__2 = global %vector_foo zeroinitializer, align 16
  @fst__2 = global %foo zeroinitializer, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  @1 = private unnamed_addr constant [7 x i8] c"record\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_in-fun__2() {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to %foo*
    %vec = alloca %vector_foo, align 8
    %owned_ptr20 = bitcast %vector_foo* %vec to %owned_ptr_foo*
    %data21 = bitcast %owned_ptr_foo* %owned_ptr20 to %foo**
    store %foo* %1, %foo** %data21, align 8
    %a22 = bitcast %foo* %1 to i64*
    store i64 0, i64* %a22, align 4
    %len = getelementptr inbounds %owned_ptr_foo, %owned_ptr_foo* %owned_ptr20, i32 0, i32 1
    store i64 1, i64* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 1
    store i64 1, i64* %cap, align 4
    %ret = alloca %foo, align 8
    %2 = call i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* %vec, i64 0)
    %box = bitcast %foo* %ret to i64*
    store i64 %2, i64* %box, align 4
    %3 = bitcast %foo* %ret to i64*
    store i64 1, i64* %3, align 4
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %4 = add i32 %fmtsize, 1
    %5 = sext i32 %4 to i64
    %6 = call i8* @malloc(i64 %5)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %5, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr23 = bitcast %string* %str to i8**
    store i8* %6, i8** %cstr23, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %7 = mul i64 %5, -1
    store i64 %7, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %8 = ptrtoint i8* %6 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %8, i64 %7)
    %ret4 = alloca %foo, align 8
    %9 = call i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* %vec, i64 0)
    %box5 = bitcast %foo* %ret4 to i64*
    store i64 %9, i64* %box5, align 4
    %fmtsize7 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %9)
    %10 = add i32 %fmtsize7, 1
    %11 = sext i32 %10 to i64
    %12 = call i8* @malloc(i64 %11)
    %fmt8 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %11, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %9)
    %str9 = alloca %string, align 8
    %cstr1025 = bitcast %string* %str9 to i8**
    store i8* %12, i8** %cstr1025, align 8
    %length11 = getelementptr inbounds %string, %string* %str9, i32 0, i32 1
    %13 = mul i64 %11, -1
    store i64 %13, i64* %length11, align 4
    %unbox12 = bitcast %string* %str9 to { i64, i64 }*
    %14 = ptrtoint i8* %12 to i64
    %snd15 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox12, i32 0, i32 1
    call void @schmu_print(i64 %14, i64 %13)
    %15 = load %foo*, %foo** %data21, align 8
    %16 = bitcast %foo* %15 to i8*
    call void @free(i8* %16)
    %owned = icmp slt i64 %7, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    call void @free(i8* %6)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned19 = icmp slt i64 %13, 0
    br i1 %owned19, label %free17, label %cont18
  
  free17:                                           ; preds = %cont
    call void @free(i8* %12)
    br label %cont18
  
  cont18:                                           ; preds = %free17, %cont
    ret void
  }
  
  define i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* %vec, i64 %i) {
  entry:
    %0 = bitcast %vector_foo* %vec to %owned_ptr_foo*
    %1 = bitcast %owned_ptr_foo* %0 to %foo**
    %2 = load %foo*, %foo** %1, align 8
    %3 = getelementptr inbounds %foo, %foo* %2, i64 %i
    %unbox = bitcast %foo* %3 to i64*
    %unbox1 = load i64, i64* %unbox, align 4
    ret i64 %unbox1
  }
  
  define void @schmu_in-fun() {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    %vec = alloca %vector_int, align 8
    %owned_ptr17 = bitcast %vector_int* %vec to %owned_ptr_int*
    %data18 = bitcast %owned_ptr_int* %owned_ptr17 to i64**
    store i64* %1, i64** %data18, align 8
    store i64 0, i64* %1, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr17, i32 0, i32 1
    store i64 1, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 1, i64* %cap, align 4
    %2 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    %fst = alloca i64, align 8
    store i64 %2, i64* %fst, align 4
    store i64 1, i64* %fst, align 4
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %3 = add i32 %fmtsize, 1
    %4 = sext i32 %3 to i64
    %5 = call i8* @malloc(i64 %4)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %4, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr19 = bitcast %string* %str to i8**
    store i8* %5, i8** %cstr19, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %6 = mul i64 %4, -1
    store i64 %6, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %7 = ptrtoint i8* %5 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %7, i64 %6)
    %8 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    %fmtsize4 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %8)
    %9 = add i32 %fmtsize4, 1
    %10 = sext i32 %9 to i64
    %11 = call i8* @malloc(i64 %10)
    %fmt5 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %8)
    %str6 = alloca %string, align 8
    %cstr721 = bitcast %string* %str6 to i8**
    store i8* %11, i8** %cstr721, align 8
    %length8 = getelementptr inbounds %string, %string* %str6, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length8, align 4
    %unbox9 = bitcast %string* %str6 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd12 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox9, i32 0, i32 1
    call void @schmu_print(i64 %13, i64 %12)
    %14 = load i64*, i64** %data18, align 8
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    %owned = icmp slt i64 %6, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    call void @free(i8* %5)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned16 = icmp slt i64 %12, 0
    br i1 %owned16, label %free14, label %cont15
  
  free14:                                           ; preds = %cont
    call void @free(i8* %11)
    br label %cont15
  
  cont15:                                           ; preds = %free14, %cont
    ret void
  }
  
  define i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 %i) {
  entry:
    %0 = bitcast %vector_int* %vec to %owned_ptr_int*
    %1 = bitcast %owned_ptr_int* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %3 = getelementptr inbounds i64, i64* %2, i64 %i
    %4 = load i64, i64* %3, align 4
    ret i64 %4
  }
  
  declare i8* @malloc(i64 %0)
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 0), align 8
    store i64 0, i64* %1, align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 1), align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 1), align 4
    %2 = tail call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* @v, i64 0)
    store i64 %2, i64* @fst, align 4
    store i64 1, i64* @fst, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %3 = add i32 %fmtsize, 1
    %4 = sext i32 %3 to i64
    %5 = tail call i8* @malloc(i64 %4)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %4, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr51 = bitcast %string* %str to i8**
    store i8* %5, i8** %cstr51, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %6 = mul i64 %4, -1
    store i64 %6, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %7 = ptrtoint i8* %5 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %7, i64 %6)
    %8 = tail call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* @v, i64 0)
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %8)
    %9 = add i32 %fmtsize3, 1
    %10 = sext i32 %9 to i64
    %11 = tail call i8* @malloc(i64 %10)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %8)
    %str5 = alloca %string, align 8
    %cstr653 = bitcast %string* %str5 to i8**
    store i8* %11, i8** %cstr653, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %13, i64 %12)
    tail call void @schmu_in-fun()
    %str13 = alloca %string, align 8
    %cstr1455 = bitcast %string* %str13 to i8**
    store i8* getelementptr inbounds ([7 x i8], [7 x i8]* @1, i32 0, i32 0), i8** %cstr1455, align 8
    %length15 = getelementptr inbounds %string, %string* %str13, i32 0, i32 1
    store i64 6, i64* %length15, align 4
    %unbox16 = bitcast %string* %str13 to { i64, i64 }*
    %snd19 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox16, i32 0, i32 1
    tail call void @schmu_print(i64 ptrtoint ([7 x i8]* @1 to i64), i64 6)
    %14 = tail call i8* @malloc(i64 8)
    %15 = bitcast i8* %14 to %foo*
    store %foo* %15, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @v__2, i32 0, i32 0, i32 0), align 8
    %a57 = bitcast %foo* %15 to i64*
    store i64 0, i64* %a57, align 4
    store i64 1, i64* getelementptr inbounds (%vector_foo, %vector_foo* @v__2, i32 0, i32 0, i32 1), align 4
    store i64 1, i64* getelementptr inbounds (%vector_foo, %vector_foo* @v__2, i32 0, i32 1), align 4
    %16 = tail call i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* @v__2, i64 0)
    store i64 %16, i64* getelementptr inbounds (%foo, %foo* @fst__2, i32 0, i32 0), align 4
    store i64 1, i64* getelementptr inbounds (%foo, %foo* @fst__2, i32 0, i32 0), align 4
    %fmtsize21 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %17 = add i32 %fmtsize21, 1
    %18 = sext i32 %17 to i64
    %19 = tail call i8* @malloc(i64 %18)
    %fmt22 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %19, i64 %18, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str23 = alloca %string, align 8
    %cstr2458 = bitcast %string* %str23 to i8**
    store i8* %19, i8** %cstr2458, align 8
    %length25 = getelementptr inbounds %string, %string* %str23, i32 0, i32 1
    %20 = mul i64 %18, -1
    store i64 %20, i64* %length25, align 4
    %unbox26 = bitcast %string* %str23 to { i64, i64 }*
    %21 = ptrtoint i8* %19 to i64
    %snd29 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox26, i32 0, i32 1
    tail call void @schmu_print(i64 %21, i64 %20)
    %ret = alloca %foo, align 8
    %22 = tail call i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* @v__2, i64 0)
    %box = bitcast %foo* %ret to i64*
    store i64 %22, i64* %box, align 4
    %fmtsize32 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %22)
    %23 = add i32 %fmtsize32, 1
    %24 = sext i32 %23 to i64
    %25 = tail call i8* @malloc(i64 %24)
    %fmt33 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %25, i64 %24, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %22)
    %str34 = alloca %string, align 8
    %cstr3560 = bitcast %string* %str34 to i8**
    store i8* %25, i8** %cstr3560, align 8
    %length36 = getelementptr inbounds %string, %string* %str34, i32 0, i32 1
    %26 = mul i64 %24, -1
    store i64 %26, i64* %length36, align 4
    %unbox37 = bitcast %string* %str34 to { i64, i64 }*
    %27 = ptrtoint i8* %25 to i64
    %snd40 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox37, i32 0, i32 1
    tail call void @schmu_print(i64 %27, i64 %26)
    tail call void @schmu_in-fun__2()
    %owned = icmp slt i64 %26, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %25)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned44 = icmp slt i64 %20, 0
    br i1 %owned44, label %free42, label %cont43
  
  free42:                                           ; preds = %cont
    tail call void @free(i8* %19)
    br label %cont43
  
  cont43:                                           ; preds = %free42, %cont
    %28 = load %foo*, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @v__2, i32 0, i32 0, i32 0), align 8
    %29 = bitcast %foo* %28 to i8*
    tail call void @free(i8* %29)
    %owned47 = icmp slt i64 %12, 0
    br i1 %owned47, label %free45, label %cont46
  
  free45:                                           ; preds = %cont43
    tail call void @free(i8* %11)
    br label %cont46
  
  cont46:                                           ; preds = %free45, %cont43
    %owned50 = icmp slt i64 %6, 0
    br i1 %owned50, label %free48, label %cont49
  
  free48:                                           ; preds = %cont46
    tail call void @free(i8* %5)
    br label %cont49
  
  cont49:                                           ; preds = %free48, %cont46
    %30 = load i64*, i64** getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 0), align 8
    %31 = bitcast i64* %30 to i8*
    tail call void @free(i8* %31)
    ret i64 0
  }
  1
  0
  1
  0
  record
  1
  0
  1
  0

  $ schmu --dump-llvm mut_alias.smu && valgrind -q --leak-check=yes ./mut_alias
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %string = type { i8*, i64 }
  
  @f = global %foo zeroinitializer, align 8
  @fst = global %foo zeroinitializer, align 8
  @snd = global %foo zeroinitializer, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_new-fun() {
  entry:
    %0 = alloca %foo, align 8
    %a31 = bitcast %foo* %0 to i64*
    store i64 0, i64* %a31, align 4
    %fst = alloca %foo, align 8
    %1 = bitcast %foo* %fst to i8*
    %2 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    %snd = alloca %foo, align 8
    %3 = bitcast %foo* %snd to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 8, i1 false)
    %4 = bitcast %foo* %fst to i64*
    store i64 1, i64* %4, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %5 = add i32 %fmtsize, 1
    %6 = sext i32 %5 to i64
    %7 = tail call i8* @malloc(i64 %6)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %7, i64 %6, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr32 = bitcast %string* %str to i8**
    store i8* %7, i8** %cstr32, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %8 = mul i64 %6, -1
    store i64 %8, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %9 = ptrtoint i8* %7 to i64
    %snd3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %9, i64 %8)
    %fmtsize5 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 0)
    %10 = add i32 %fmtsize5, 1
    %11 = sext i32 %10 to i64
    %12 = tail call i8* @malloc(i64 %11)
    %fmt6 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %11, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 0)
    %str7 = alloca %string, align 8
    %cstr834 = bitcast %string* %str7 to i8**
    store i8* %12, i8** %cstr834, align 8
    %length9 = getelementptr inbounds %string, %string* %str7, i32 0, i32 1
    %13 = mul i64 %11, -1
    store i64 %13, i64* %length9, align 4
    %unbox10 = bitcast %string* %str7 to { i64, i64 }*
    %14 = ptrtoint i8* %12 to i64
    %snd13 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox10, i32 0, i32 1
    tail call void @schmu_print(i64 %14, i64 %13)
    %15 = bitcast %foo* %snd to i64*
    %16 = load i64, i64* %15, align 4
    %fmtsize15 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %16)
    %17 = add i32 %fmtsize15, 1
    %18 = sext i32 %17 to i64
    %19 = tail call i8* @malloc(i64 %18)
    %fmt16 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %19, i64 %18, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %16)
    %str17 = alloca %string, align 8
    %cstr1836 = bitcast %string* %str17 to i8**
    store i8* %19, i8** %cstr1836, align 8
    %length19 = getelementptr inbounds %string, %string* %str17, i32 0, i32 1
    %20 = mul i64 %18, -1
    store i64 %20, i64* %length19, align 4
    %unbox20 = bitcast %string* %str17 to { i64, i64 }*
    %21 = ptrtoint i8* %19 to i64
    %snd23 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox20, i32 0, i32 1
    tail call void @schmu_print(i64 %21, i64 %20)
    %owned = icmp slt i64 %8, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %7)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned27 = icmp slt i64 %13, 0
    br i1 %owned27, label %free25, label %cont26
  
  free25:                                           ; preds = %cont
    tail call void @free(i8* %12)
    br label %cont26
  
  cont26:                                           ; preds = %free25, %cont
    %owned30 = icmp slt i64 %20, 0
    br i1 %owned30, label %free28, label %cont29
  
  free28:                                           ; preds = %cont26
    tail call void @free(i8* %19)
    ret void
  
  cont29:                                           ; preds = %cont26
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* getelementptr inbounds (%foo, %foo* @f, i32 0, i32 0), align 4
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%foo* @fst to i8*), i8* bitcast (%foo* @f to i8*), i64 8, i1 false)
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%foo* @snd to i8*), i8* bitcast (%foo* @fst to i8*), i64 8, i1 false)
    store i64 1, i64* getelementptr inbounds (%foo, %foo* @fst, i32 0, i32 0), align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %0 = add i32 %fmtsize, 1
    %1 = sext i32 %0 to i64
    %2 = tail call i8* @malloc(i64 %1)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %2, i64 %1, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr29 = bitcast %string* %str to i8**
    store i8* %2, i8** %cstr29, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %3 = mul i64 %1, -1
    store i64 %3, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %4 = ptrtoint i8* %2 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %4, i64 %3)
    %5 = load i64, i64* getelementptr inbounds (%foo, %foo* @f, i32 0, i32 0), align 4
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %5)
    %6 = add i32 %fmtsize3, 1
    %7 = sext i32 %6 to i64
    %8 = tail call i8* @malloc(i64 %7)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %8, i64 %7, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %5)
    %str5 = alloca %string, align 8
    %cstr631 = bitcast %string* %str5 to i8**
    store i8* %8, i8** %cstr631, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %9 = mul i64 %7, -1
    store i64 %9, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %10 = ptrtoint i8* %8 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %10, i64 %9)
    %11 = load i64, i64* getelementptr inbounds (%foo, %foo* @snd, i32 0, i32 0), align 4
    %fmtsize13 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %11)
    %12 = add i32 %fmtsize13, 1
    %13 = sext i32 %12 to i64
    %14 = tail call i8* @malloc(i64 %13)
    %fmt14 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %14, i64 %13, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %11)
    %str15 = alloca %string, align 8
    %cstr1633 = bitcast %string* %str15 to i8**
    store i8* %14, i8** %cstr1633, align 8
    %length17 = getelementptr inbounds %string, %string* %str15, i32 0, i32 1
    %15 = mul i64 %13, -1
    store i64 %15, i64* %length17, align 4
    %unbox18 = bitcast %string* %str15 to { i64, i64 }*
    %16 = ptrtoint i8* %14 to i64
    %snd21 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox18, i32 0, i32 1
    tail call void @schmu_print(i64 %16, i64 %15)
    tail call void @schmu_new-fun()
    %owned = icmp slt i64 %15, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %14)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned25 = icmp slt i64 %9, 0
    br i1 %owned25, label %free23, label %cont24
  
  free23:                                           ; preds = %cont
    tail call void @free(i8* %8)
    br label %cont24
  
  cont24:                                           ; preds = %free23, %cont
    %owned28 = icmp slt i64 %3, 0
    br i1 %owned28, label %free26, label %cont27
  
  free26:                                           ; preds = %cont24
    tail call void @free(i8* %2)
    br label %cont27
  
  cont27:                                           ; preds = %free26, %cont24
    ret i64 0
  }
  
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
  
  %vector_int = type { %owned_ptr_int, i64 }
  %owned_ptr_int = type { i64*, i64 }
  %string = type { i8*, i64 }
  
  @v = global %vector_int zeroinitializer, align 16
  @const = global i64 0, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_in-fun__2() {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    %vec = alloca %vector_int, align 8
    %owned_ptr16 = bitcast %vector_int* %vec to %owned_ptr_int*
    %data17 = bitcast %owned_ptr_int* %owned_ptr16 to i64**
    store i64* %1, i64** %data17, align 8
    store i64 0, i64* %1, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr16, i32 0, i32 1
    store i64 1, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 1, i64* %cap, align 4
    %2 = load i64*, i64** %data17, align 8
    %const = load i64, i64* %2, align 4
    call void @schmu___vectorgig.u_vector-set_vectoriii.u(%vector_int* %vec, i64 0, i64 1)
    %3 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %4 = add i32 %fmtsize, 1
    %5 = sext i32 %4 to i64
    %6 = call i8* @malloc(i64 %5)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %5, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %str = alloca %string, align 8
    %cstr18 = bitcast %string* %str to i8**
    store i8* %6, i8** %cstr18, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %7 = mul i64 %5, -1
    store i64 %7, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %8 = ptrtoint i8* %6 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %8, i64 %7)
    %fmtsize3 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %const)
    %9 = add i32 %fmtsize3, 1
    %10 = sext i32 %9 to i64
    %11 = call i8* @malloc(i64 %10)
    %fmt4 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %const)
    %str5 = alloca %string, align 8
    %cstr620 = bitcast %string* %str5 to i8**
    store i8* %11, i8** %cstr620, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    call void @schmu_print(i64 %13, i64 %12)
    %14 = load i64*, i64** %data17, align 8
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    %owned = icmp slt i64 %7, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    call void @free(i8* %6)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned15 = icmp slt i64 %12, 0
    br i1 %owned15, label %free13, label %cont14
  
  free13:                                           ; preds = %cont
    call void @free(i8* %11)
    br label %cont14
  
  cont14:                                           ; preds = %free13, %cont
    ret void
  }
  
  define void @schmu_in-fun() {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    %vec = alloca %vector_int, align 8
    %owned_ptr16 = bitcast %vector_int* %vec to %owned_ptr_int*
    %data17 = bitcast %owned_ptr_int* %owned_ptr16 to i64**
    store i64* %1, i64** %data17, align 8
    store i64 0, i64* %1, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr16, i32 0, i32 1
    store i64 1, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 1, i64* %cap, align 4
    %2 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    call void @schmu___vectorgig.u_vector-set_vectoriii.u(%vector_int* %vec, i64 0, i64 1)
    %3 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %4 = add i32 %fmtsize, 1
    %5 = sext i32 %4 to i64
    %6 = call i8* @malloc(i64 %5)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %5, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %str = alloca %string, align 8
    %cstr18 = bitcast %string* %str to i8**
    store i8* %6, i8** %cstr18, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %7 = mul i64 %5, -1
    store i64 %7, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %8 = ptrtoint i8* %6 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %8, i64 %7)
    %fmtsize3 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %2)
    %9 = add i32 %fmtsize3, 1
    %10 = sext i32 %9 to i64
    %11 = call i8* @malloc(i64 %10)
    %fmt4 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %2)
    %str5 = alloca %string, align 8
    %cstr620 = bitcast %string* %str5 to i8**
    store i8* %11, i8** %cstr620, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    call void @schmu_print(i64 %13, i64 %12)
    %14 = load i64*, i64** %data17, align 8
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    %owned = icmp slt i64 %7, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    call void @free(i8* %6)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned15 = icmp slt i64 %12, 0
    br i1 %owned15, label %free13, label %cont14
  
  free13:                                           ; preds = %cont
    call void @free(i8* %11)
    br label %cont14
  
  cont14:                                           ; preds = %free13, %cont
    ret void
  }
  
  define void @schmu___vectorgig.u_vector-set_vectoriii.u(%vector_int* %vec, i64 %i, i64 %v) {
  entry:
    %0 = bitcast %vector_int* %vec to %owned_ptr_int*
    %1 = bitcast %owned_ptr_int* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %3 = getelementptr inbounds i64, i64* %2, i64 %i
    store i64 %v, i64* %3, align 4
    ret void
  }
  
  define i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 %i) {
  entry:
    %0 = bitcast %vector_int* %vec to %owned_ptr_int*
    %1 = bitcast %owned_ptr_int* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %3 = getelementptr inbounds i64, i64* %2, i64 %i
    %4 = load i64, i64* %3, align 4
    ret i64 %4
  }
  
  declare i8* @malloc(i64 %0)
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 0), align 8
    store i64 0, i64* %1, align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 1), align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 1), align 4
    %2 = tail call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* @v, i64 0)
    store i64 %2, i64* @const, align 4
    tail call void @schmu___vectorgig.u_vector-set_vectoriii.u(%vector_int* @v, i64 0, i64 1)
    %3 = tail call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* @v, i64 0)
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %4 = add i32 %fmtsize, 1
    %5 = sext i32 %4 to i64
    %6 = tail call i8* @malloc(i64 %5)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %5, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %str = alloca %string, align 8
    %cstr16 = bitcast %string* %str to i8**
    store i8* %6, i8** %cstr16, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %7 = mul i64 %5, -1
    store i64 %7, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %8 = ptrtoint i8* %6 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %8, i64 %7)
    %9 = load i64, i64* @const, align 4
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %9)
    %10 = add i32 %fmtsize3, 1
    %11 = sext i32 %10 to i64
    %12 = tail call i8* @malloc(i64 %11)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %11, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %9)
    %str5 = alloca %string, align 8
    %cstr618 = bitcast %string* %str5 to i8**
    store i8* %12, i8** %cstr618, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %13 = mul i64 %11, -1
    store i64 %13, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %14 = ptrtoint i8* %12 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %14, i64 %13)
    tail call void @schmu_in-fun()
    tail call void @schmu_in-fun__2()
    %owned = icmp slt i64 %13, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %12)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned15 = icmp slt i64 %7, 0
    br i1 %owned15, label %free13, label %cont14
  
  free13:                                           ; preds = %cont
    tail call void @free(i8* %6)
    br label %cont14
  
  cont14:                                           ; preds = %free13, %cont
    %15 = load i64*, i64** getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 0), align 8
    %16 = bitcast i64* %15 to i8*
    tail call void @free(i8* %16)
    ret i64 0
  }
  1
  0
  1
  0
  1
  0


Copies, but with ref-counted arrays
  $ schmu array_copies.smu --dump-llvm && ./array_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @a = global i64* null, align 8
  @b = global i64* null, align 8
  @c = global i64* null, align 8
  @d = global i64* null, align 8
  @0 = private unnamed_addr constant [7 x i8] c"in fun\00", align 1
  @1 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_in-fun() {
  entry:
    %str = alloca %string, align 8
    %cstr5 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([7 x i8], [7 x i8]* @0, i32 0, i32 0), i8** %cstr5, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 6, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 ptrtoint ([7 x i8]* @0 to i64), i64 6)
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
    %data3 = getelementptr i64, i64* %5, i64 3
    store i64 12, i64* %data3, align 4
    %6 = load i64*, i64** %arr, align 8
    call void @schmu___ag.u_print-0th_ai.u(i64* %6)
    %7 = call i64* @__ag.ag_reloc_ai.ai(i64** %c)
    %data4 = getelementptr i64, i64* %7, i64 3
    store i64 15, i64* %data4, align 4
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
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %0)
    %1 = add i32 %fmtsize, 1
    %2 = sext i32 %1 to i64
    %3 = tail call i8* @malloc(i64 %2)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %3, i64 %2, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %0)
    %str = alloca %string, align 8
    %cstr3 = bitcast %string* %str to i8**
    store i8* %3, i8** %cstr3, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %4 = mul i64 %2, -1
    store i64 %4, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %5 = ptrtoint i8* %3 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %5, i64 %4)
    %owned = icmp slt i64 %4, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %3)
    ret void
  
  cont:                                             ; preds = %entry
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
  
  declare void @free(i8* %0)
  
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
    %12 = load i64*, i64** @b, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %12)
    %13 = load i64*, i64** @c, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %13)
    %14 = load i64*, i64** @d, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %14)
    %15 = load i64*, i64** @a, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %15)
    ret i64 0
  }
  
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
  %string = type { i8*, i64 }
  
  @a = global %arrec zeroinitializer, align 8
  @b = global %arrec zeroinitializer, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  @1 = private unnamed_addr constant [7 x i8] c"in fun\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
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
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %2)
    %3 = add i32 %fmtsize, 1
    %4 = sext i32 %3 to i64
    %5 = tail call i8* @malloc(i64 %4)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %4, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %2)
    %str = alloca %string, align 8
    %cstr4 = bitcast %string* %str to i8**
    store i8* %5, i8** %cstr4, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %6 = mul i64 %4, -1
    store i64 %6, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %7 = ptrtoint i8* %5 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %7, i64 %6)
    %owned = icmp slt i64 %6, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %5)
    ret void
  
  cont:                                             ; preds = %entry
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
  
  declare void @free(i8* %0)
  
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
    %str = alloca %string, align 8
    %cstr6 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([7 x i8], [7 x i8]* @1, i32 0, i32 0), i8** %cstr6, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 6, i64* %length, align 4
    %unbox3 = bitcast %string* %str to { i64, i64 }*
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox3, i32 0, i32 1
    tail call void @schmu_print(i64 ptrtoint ([7 x i8]* @1 to i64), i64 6)
    tail call void @schmu_in-fun()
    tail call void @__g.u_decr_rc_arrec.u(%arrec* @b)
    tail call void @__g.u_decr_rc_arrec.u(%arrec* @a)
    ret i64 0
  }
  
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
  
  %string = type { i8*, i64 }
  
  @a = global i64** null, align 8
  @b = global i64** null, align 8
  @0 = private unnamed_addr constant [9 x i8] c"%li, %li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
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
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @0, i32 0, i32 0), i64 %4, i64 %8)
    %9 = add i32 %fmtsize, 1
    %10 = sext i32 %9 to i64
    %11 = tail call i8* @malloc(i64 %10)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @0, i32 0, i32 0), i64 %4, i64 %8)
    %str = alloca %string, align 8
    %cstr6 = bitcast %string* %str to i8**
    store i8* %11, i8** %cstr6, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %13, i64 %12)
    %owned = icmp slt i64 %12, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %11)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %14 = bitcast i64** %a to i8*
    %sunkaddr = getelementptr i8, i8* %14, i64 32
    %15 = bitcast i8* %sunkaddr to i64**
    %16 = load i64*, i64** %15, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %16)
    %17 = bitcast i64** %a to i8*
    %sunkaddr8 = getelementptr i8, i8* %17, i64 24
    %18 = bitcast i8* %sunkaddr8 to i64**
    %19 = load i64*, i64** %18, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %19)
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
  
  declare void @free(i8* %0)
  
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
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  15, 20
  10, 20


  $ schmu --dump-llvm modify_in_fn.smu && valgrind -q --leak-check=yes ./modify_in_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %f = type { i64 }
  %string = type { i8*, i64 }
  
  @a = global %f zeroinitializer, align 8
  @b = global i64* null, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
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
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    %1 = add i32 %fmtsize, 1
    %2 = sext i32 %1 to i64
    %3 = tail call i8* @malloc(i64 %2)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %3, i64 %2, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    %str = alloca %string, align 8
    %cstr16 = bitcast %string* %str to i8**
    store i8* %3, i8** %cstr16, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %4 = mul i64 %2, -1
    store i64 %4, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %5 = ptrtoint i8* %3 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %5, i64 %4)
    %6 = tail call i8* @malloc(i64 32)
    %7 = bitcast i8* %6 to i64*
    store i64* %7, i64** @b, align 8
    store i64 1, i64* %7, align 4
    %size = getelementptr i64, i64* %7, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %7, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %7, i64 3
    store i64 10, i64* %data, align 4
    %8 = load i64*, i64** @b, align 8
    store i64* %8, i64** @b, align 8
    tail call void @schmu_mod2(i64** @b)
    %9 = load i64*, i64** @b, align 8
    %len = getelementptr i64, i64* %9, i64 1
    %10 = load i64, i64* %len, align 4
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %10)
    %11 = add i32 %fmtsize3, 1
    %12 = sext i32 %11 to i64
    %13 = tail call i8* @malloc(i64 %12)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %13, i64 %12, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %10)
    %str5 = alloca %string, align 8
    %cstr618 = bitcast %string* %str5 to i8**
    store i8* %13, i8** %cstr618, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %14 = mul i64 %12, -1
    store i64 %14, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %15 = ptrtoint i8* %13 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %15, i64 %14)
    %16 = load i64*, i64** @b, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %16)
    %owned = icmp slt i64 %14, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %13)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned15 = icmp slt i64 %4, 0
    br i1 %owned15, label %free13, label %cont14
  
  free13:                                           ; preds = %cont
    tail call void @free(i8* %3)
    br label %cont14
  
  cont14:                                           ; preds = %free13, %cont
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  30
  2
