Compile stubs
  $ cc -c stub.c

Test elif
  $ schmu -dump-llvm elseif.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @assert(i1 %0)
  
  define private i32 @test(i32 %n) {
  entry:
    %eqtmp = icmp eq i32 %n, 10
    br i1 %eqtmp, label %ifcont8, label %else
  
  else:                                             ; preds = %entry
    %lesstmp = icmp slt i32 %n, 1
    br i1 %lesstmp, label %ifcont8, label %else2
  
  else2:                                            ; preds = %else
    %lesstmp3 = icmp slt i32 %n, 10
    br i1 %lesstmp3, label %ifcont8, label %else5
  
  else5:                                            ; preds = %else2
    br label %ifcont8
  
  ifcont8:                                          ; preds = %else, %else2, %else5, %entry
    %iftmp9 = phi i32 [ 1, %entry ], [ 2, %else ], [ 4, %else5 ], [ 3, %else2 ]
    ret i32 %iftmp9
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = tail call i32 @test(i32 10)
    %eqtmp = icmp eq i32 %0, 1
    tail call void @assert(i1 %eqtmp)
    %1 = tail call i32 @test(i32 0)
    %eqtmp1 = icmp eq i32 %1, 2
    tail call void @assert(i1 %eqtmp1)
    %2 = tail call i32 @test(i32 1)
    %eqtmp2 = icmp eq i32 %2, 3
    tail call void @assert(i1 %eqtmp2)
    %3 = tail call i32 @test(i32 11)
    %eqtmp3 = icmp eq i32 %3, 4
    tail call void @assert(i1 %eqtmp3)
    ret i32 0
  }

Test simple typedef
  $ schmu -dump-llvm simple_typealias.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @puts(i8* %0)
  
  define i32 @main(i32 %arg) {
  entry:
    ret i32 0
  }

Allocate vectors on the heap and free them. Check with valgrind whenever something changes here
  $ schmu -dump-llvm free_vector.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { i32*, i32, i32 }
  %vector_vector_int = type { %vector_int*, i32, i32 }
  %vector_foo = type { %foo*, i32, i32 }
  %foo = type { i32 }
  %string = type { i8*, i32 }
  %vector_string = type { %string*, i32, i32 }
  %closure = type { i8*, i8* }
  
  @0 = private unnamed_addr constant [4 x i8] c"hey\00", align 1
  @1 = private unnamed_addr constant [6 x i8] c"young\00", align 1
  @2 = private unnamed_addr constant [6 x i8] c"world\00", align 1
  
  define private i32 @nest_local() {
  entry:
    %0 = tail call i8* @malloc(i32 32)
    %1 = bitcast i8* %0 to %vector_int*
    %vec = alloca %vector_vector_int, align 8
    %data7 = bitcast %vector_vector_int* %vec to %vector_int**
    store %vector_int* %1, %vector_int** %data7, align 8
    %2 = tail call i8* @malloc(i32 8)
    %3 = bitcast i8* %2 to i32*
    %data18 = bitcast %vector_int* %1 to i32**
    store i32* %3, i32** %data18, align 8
    store i32 0, i32* %3, align 4
    %4 = getelementptr i32, i32* %3, i32 1
    store i32 1, i32* %3, align 4
    %len = getelementptr inbounds %vector_int, %vector_int* %1, i32 0, i32 1
    store i32 2, i32* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %1, i32 0, i32 2
    store i32 2, i32* %cap, align 4
    %5 = getelementptr %vector_int, %vector_int* %1, i32 1
    %6 = tail call i8* @malloc(i32 8)
    %7 = bitcast i8* %6 to i32*
    %data29 = bitcast %vector_int* %5 to i32**
    store i32* %7, i32** %data29, align 8
    store i32 2, i32* %7, align 4
    %8 = getelementptr i32, i32* %7, i32 1
    store i32 3, i32* %7, align 4
    %len3 = getelementptr inbounds %vector_int, %vector_int* %5, i32 0, i32 1
    store i32 2, i32* %len3, align 4
    %cap4 = getelementptr inbounds %vector_int, %vector_int* %5, i32 0, i32 2
    store i32 2, i32* %cap4, align 4
    %len5 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec, i32 0, i32 1
    store i32 2, i32* %len5, align 4
    %cap6 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec, i32 0, i32 2
    store i32 2, i32* %cap6, align 4
    tail call void @free(i8* %0)
    tail call void @free(i8* %6)
    tail call void @free(i8* %2)
    ret i32 0
  }
  
  define private void @nest_allocs(%vector_vector_int* sret %0) {
  entry:
    tail call void @make_nested_vec(%vector_vector_int* %0)
    ret void
  }
  
  define private void @make_nested_vec(%vector_vector_int* sret %0) {
  entry:
    %1 = tail call i8* @malloc(i32 32)
    %2 = bitcast i8* %1 to %vector_int*
    %data7 = bitcast %vector_vector_int* %0 to %vector_int**
    store %vector_int* %2, %vector_int** %data7, align 8
    %3 = tail call i8* @malloc(i32 8)
    %4 = bitcast i8* %3 to i32*
    %data18 = bitcast %vector_int* %2 to i32**
    store i32* %4, i32** %data18, align 8
    store i32 0, i32* %4, align 4
    %5 = getelementptr i32, i32* %4, i32 1
    store i32 1, i32* %4, align 4
    %len = getelementptr inbounds %vector_int, %vector_int* %2, i32 0, i32 1
    store i32 2, i32* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %2, i32 0, i32 2
    store i32 2, i32* %cap, align 4
    %6 = getelementptr %vector_int, %vector_int* %2, i32 1
    %7 = tail call i8* @malloc(i32 8)
    %8 = bitcast i8* %7 to i32*
    %data29 = bitcast %vector_int* %6 to i32**
    store i32* %8, i32** %data29, align 8
    store i32 2, i32* %8, align 4
    %9 = getelementptr i32, i32* %8, i32 1
    store i32 3, i32* %8, align 4
    %len3 = getelementptr inbounds %vector_int, %vector_int* %6, i32 0, i32 1
    store i32 2, i32* %len3, align 4
    %cap4 = getelementptr inbounds %vector_int, %vector_int* %6, i32 0, i32 2
    store i32 2, i32* %cap4, align 4
    %len5 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %0, i32 0, i32 1
    store i32 2, i32* %len5, align 4
    %cap6 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %0, i32 0, i32 2
    store i32 2, i32* %cap6, align 4
    ret void
  }
  
  define private void @nest_fns(%vector_foo* sret %0) {
  entry:
    tail call void @make_vec(%vector_foo* %0)
    ret void
  }
  
  define private i32 @inner_parent_scope() {
  entry:
    %ret = alloca %vector_foo, align 8
    call void @make_vec(%vector_foo* %ret)
    %0 = bitcast %vector_foo* %ret to %foo**
    %1 = load %foo*, %foo** %0, align 8
    %2 = bitcast %foo* %1 to i8*
    call void @free(i8* %2)
    ret i32 0
  }
  
  define private void @make_vec(%vector_foo* sret %0) {
  entry:
    %1 = alloca %foo, align 8
    %x3 = bitcast %foo* %1 to i32*
    store i32 23, i32* %x3, align 4
    %2 = tail call i8* @malloc(i32 12)
    %3 = bitcast i8* %2 to %foo*
    %data4 = bitcast %vector_foo* %0 to %foo**
    store %foo* %3, %foo** %data4, align 8
    %4 = bitcast %foo* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %4, i64 4, i1 false)
    %5 = getelementptr %foo, %foo* %3, i32 1
    %x15 = bitcast %foo* %5 to i32*
    store i32 2, i32* %x15, align 4
    %6 = getelementptr %foo, %foo* %3, i32 2
    %x26 = bitcast %foo* %6 to i32*
    store i32 3, i32* %x26, align 4
    %len = getelementptr inbounds %vector_foo, %vector_foo* %0, i32 0, i32 1
    store i32 3, i32* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %0, i32 0, i32 2
    store i32 3, i32* %cap, align 4
    ret void
  }
  
  define private i32 @vec_inside(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %foo }*
    %x3 = bitcast { %foo }* %clsr to %foo*
    %1 = tail call i8* @malloc(i32 12)
    %2 = bitcast i8* %1 to %foo*
    %vec = alloca %vector_foo, align 8
    %data4 = bitcast %vector_foo* %vec to %foo**
    store %foo* %2, %foo** %data4, align 8
    %3 = bitcast %foo* %x3 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %3, i64 4, i1 false)
    %4 = getelementptr %foo, %foo* %2, i32 1
    %x15 = bitcast %foo* %4 to i32*
    store i32 2, i32* %x15, align 4
    %5 = getelementptr %foo, %foo* %2, i32 2
    %x26 = bitcast %foo* %5 to i32*
    store i32 3, i32* %x26, align 4
    %len = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 1
    store i32 3, i32* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 2
    store i32 3, i32* %cap, align 4
    tail call void @free(i8* %1)
    ret i32 0
  }
  
  declare i8* @malloc(i32 %0)
  
  declare void @free(i8* %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %x39 = bitcast %foo* %0 to i32*
    store i32 1, i32* %x39, align 4
    %1 = tail call i8* @malloc(i32 48)
    %2 = bitcast i8* %1 to %string*
    %vec = alloca %vector_string, align 8
    %data40 = bitcast %vector_string* %vec to %string**
    store %string* %2, %string** %data40, align 8
    %cstr41 = bitcast %string* %2 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr41, align 8
    %length = getelementptr inbounds %string, %string* %2, i32 0, i32 1
    store i32 3, i32* %length, align 4
    %3 = getelementptr %string, %string* %2, i32 1
    %cstr142 = bitcast %string* %3 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @1, i32 0, i32 0), i8** %cstr142, align 8
    %length2 = getelementptr inbounds %string, %string* %3, i32 0, i32 1
    store i32 5, i32* %length2, align 4
    %4 = getelementptr %string, %string* %2, i32 2
    %cstr343 = bitcast %string* %4 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @2, i32 0, i32 0), i8** %cstr343, align 8
    %length4 = getelementptr inbounds %string, %string* %4, i32 0, i32 1
    store i32 5, i32* %length4, align 4
    %len = getelementptr inbounds %vector_string, %vector_string* %vec, i32 0, i32 1
    store i32 3, i32* %len, align 4
    %cap = getelementptr inbounds %vector_string, %vector_string* %vec, i32 0, i32 2
    store i32 3, i32* %cap, align 4
    %5 = tail call i8* @malloc(i32 12)
    %6 = bitcast i8* %5 to %foo*
    %vec5 = alloca %vector_foo, align 8
    %data644 = bitcast %vector_foo* %vec5 to %foo**
    store %foo* %6, %foo** %data644, align 8
    %7 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %7, i64 4, i1 false)
    %8 = getelementptr %foo, %foo* %6, i32 1
    %x745 = bitcast %foo* %8 to i32*
    store i32 2, i32* %x745, align 4
    %9 = getelementptr %foo, %foo* %6, i32 2
    %x846 = bitcast %foo* %9 to i32*
    store i32 3, i32* %x846, align 4
    %len9 = getelementptr inbounds %vector_foo, %vector_foo* %vec5, i32 0, i32 1
    store i32 3, i32* %len9, align 4
    %cap10 = getelementptr inbounds %vector_foo, %vector_foo* %vec5, i32 0, i32 2
    store i32 3, i32* %cap10, align 4
    %vec_inside = alloca %closure, align 8
    %funptr47 = bitcast %closure* %vec_inside to i8**
    store i8* bitcast (i32 (i8*)* @vec_inside to i8*), i8** %funptr47, align 8
    %clsr_vec_inside = alloca { %foo }, align 8
    %x1148 = bitcast { %foo }* %clsr_vec_inside to %foo*
    %10 = bitcast %foo* %x1148 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %7, i64 4, i1 false)
    %env = bitcast { %foo }* %clsr_vec_inside to i8*
    %envptr = getelementptr inbounds %closure, %closure* %vec_inside, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %ret = alloca %vector_foo, align 8
    call void @make_vec(%vector_foo* %ret)
    %11 = call i32 @vec_inside(i8* %env)
    %12 = call i32 @inner_parent_scope()
    %ret14 = alloca %vector_foo, align 8
    call void @nest_fns(%vector_foo* %ret14)
    %13 = call i8* @malloc(i32 32)
    %14 = bitcast i8* %13 to %vector_int*
    %vec15 = alloca %vector_vector_int, align 8
    %data1649 = bitcast %vector_vector_int* %vec15 to %vector_int**
    store %vector_int* %14, %vector_int** %data1649, align 8
    %15 = call i8* @malloc(i32 8)
    %16 = bitcast i8* %15 to i32*
    %data1750 = bitcast %vector_int* %14 to i32**
    store i32* %16, i32** %data1750, align 8
    store i32 0, i32* %16, align 4
    %17 = getelementptr i32, i32* %16, i32 1
    store i32 1, i32* %16, align 4
    %len18 = getelementptr inbounds %vector_int, %vector_int* %14, i32 0, i32 1
    store i32 2, i32* %len18, align 4
    %cap19 = getelementptr inbounds %vector_int, %vector_int* %14, i32 0, i32 2
    store i32 2, i32* %cap19, align 4
    %18 = getelementptr %vector_int, %vector_int* %14, i32 1
    %19 = call i8* @malloc(i32 8)
    %20 = bitcast i8* %19 to i32*
    %data2051 = bitcast %vector_int* %18 to i32**
    store i32* %20, i32** %data2051, align 8
    store i32 2, i32* %20, align 4
    %21 = getelementptr i32, i32* %20, i32 1
    store i32 3, i32* %20, align 4
    %len21 = getelementptr inbounds %vector_int, %vector_int* %18, i32 0, i32 1
    store i32 2, i32* %len21, align 4
    %cap22 = getelementptr inbounds %vector_int, %vector_int* %18, i32 0, i32 2
    store i32 2, i32* %cap22, align 4
    %len23 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec15, i32 0, i32 1
    store i32 2, i32* %len23, align 4
    %cap24 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec15, i32 0, i32 2
    store i32 2, i32* %cap24, align 4
    %ret25 = alloca %vector_vector_int, align 8
    call void @make_nested_vec(%vector_vector_int* %ret25)
    %ret26 = alloca %vector_vector_int, align 8
    call void @nest_allocs(%vector_vector_int* %ret26)
    %22 = call i32 @nest_local()
    %23 = bitcast %vector_vector_int* %ret26 to %vector_int**
    %24 = load %vector_int*, %vector_int** %23, align 8
    %lenptr = getelementptr inbounds %vector_vector_int, %vector_vector_int* %ret26, i32 0, i32 1
    %leni = load i32, i32* %lenptr, align 4
    %len27 = sext i32 %leni to i64
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  rec:                                              ; preds = %free, %entry
    %lsr.iv36 = phi %vector_int* [ %scevgep37, %free ], [ %24, %entry ]
    %25 = phi i64 [ %30, %free ], [ 0, %entry ]
    %26 = icmp slt i64 %25, %len27
    br i1 %26, label %free, label %cont
  
  free:                                             ; preds = %rec
    %27 = bitcast %vector_int* %lsr.iv36 to i32**
    %28 = load i32*, i32** %27, align 8
    %29 = bitcast i32* %28 to i8*
    call void @free(i8* %29)
    %30 = add i64 %25, 1
    store i64 %30, i64* %cnt, align 4
    %scevgep37 = getelementptr %vector_int, %vector_int* %lsr.iv36, i64 1
    br label %rec
  
  cont:                                             ; preds = %rec
    %31 = bitcast %vector_int* %24 to i8*
    call void @free(i8* %31)
    %32 = bitcast %vector_vector_int* %ret25 to %vector_int**
    %33 = load %vector_int*, %vector_int** %32, align 8
    %lenptr28 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %ret25, i32 0, i32 1
    %leni29 = load i32, i32* %lenptr28, align 4
    %len30 = sext i32 %leni29 to i64
    %cnt31 = alloca i64, align 8
    store i64 0, i64* %cnt31, align 4
    br label %rec32
  
  rec32:                                            ; preds = %free33, %cont
    %lsr.iv = phi %vector_int* [ %scevgep, %free33 ], [ %33, %cont ]
    %34 = phi i64 [ %39, %free33 ], [ 0, %cont ]
    %35 = icmp slt i64 %34, %len30
    br i1 %35, label %free33, label %cont34
  
  free33:                                           ; preds = %rec32
    %36 = bitcast %vector_int* %lsr.iv to i32**
    %37 = load i32*, i32** %36, align 8
    %38 = bitcast i32* %37 to i8*
    call void @free(i8* %38)
    %39 = add i64 %34, 1
    store i64 %39, i64* %cnt31, align 4
    %scevgep = getelementptr %vector_int, %vector_int* %lsr.iv, i64 1
    br label %rec32
  
  cont34:                                           ; preds = %rec32
    %40 = bitcast %vector_int* %33 to i8*
    call void @free(i8* %40)
    call void @free(i8* %13)
    call void @free(i8* %19)
    call void @free(i8* %15)
    %41 = bitcast %vector_foo* %ret14 to %foo**
    %42 = load %foo*, %foo** %41, align 8
    %43 = bitcast %foo* %42 to i8*
    call void @free(i8* %43)
    %44 = bitcast %vector_foo* %ret to %foo**
    %45 = load %foo*, %foo** %44, align 8
    %46 = bitcast %foo* %45 to i8*
    call void @free(i8* %46)
    call void @free(i8* %5)
    call void @free(i8* %1)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
