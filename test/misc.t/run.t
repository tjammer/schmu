Compile stubs
  $ cc -c stub.c

Test elif
  $ schmu -dump-llvm elseif.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @assert(i1 %0)
  
  define private i64 @test(i64 %n) {
  entry:
    %eq = icmp eq i64 %n, 10
    br i1 %eq, label %ifcont8, label %else
  
  else:                                             ; preds = %entry
    %lt = icmp slt i64 %n, 1
    br i1 %lt, label %ifcont8, label %else2
  
  else2:                                            ; preds = %else
    %lt3 = icmp slt i64 %n, 10
    br i1 %lt3, label %ifcont8, label %else5
  
  else5:                                            ; preds = %else2
    br label %ifcont8
  
  ifcont8:                                          ; preds = %else, %else2, %else5, %entry
    %iftmp9 = phi i64 [ 1, %entry ], [ 2, %else ], [ 4, %else5 ], [ 3, %else2 ]
    ret i64 %iftmp9
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @test(i64 10)
    %eq = icmp eq i64 %0, 1
    tail call void @assert(i1 %eq)
    %1 = tail call i64 @test(i64 0)
    %eq1 = icmp eq i64 %1, 2
    tail call void @assert(i1 %eq1)
    %2 = tail call i64 @test(i64 1)
    %eq2 = icmp eq i64 %2, 3
    tail call void @assert(i1 %eq2)
    %3 = tail call i64 @test(i64 11)
    %eq3 = icmp eq i64 %3, 4
    tail call void @assert(i1 %eq3)
    ret i64 0
  }

Test simple typedef
  $ schmu -dump-llvm simple_typealias.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @puts(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 0
  }

Allocate vectors on the heap and free them. Check with valgrind whenever something changes here.
Also mutable fields and 'realloc' builtin
  $ schmu -dump-llvm free_vector.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_container = type { %container*, i64, i64 }
  %container = type { i64, %vector_int }
  %vector_int = type { i64*, i64, i64 }
  %vector_vector_int = type { %vector_int*, i64, i64 }
  %vector_foo = type { %foo*, i64, i64 }
  %foo = type { i64 }
  %string = type { i8*, i64 }
  %vector_string = type { %string*, i64, i64 }
  %closure = type { i8*, i8* }
  
  @0 = private unnamed_addr constant [4 x i8] c"hey\00", align 1
  @1 = private unnamed_addr constant [6 x i8] c"young\00", align 1
  @2 = private unnamed_addr constant [6 x i8] c"world\00", align 1
  
  define private void @vec_of_records(%vector_container* sret %0) {
  entry:
    %1 = tail call i8* @malloc(i64 64)
    %2 = bitcast i8* %1 to %container*
    %data1 = bitcast %vector_container* %0 to %container**
    store %container* %2, %container** %data1, align 8
    tail call void @record_of_vecs(%container* %2)
    %3 = getelementptr %container, %container* %2, i64 1
    tail call void @record_of_vecs(%container* %3)
    %len = getelementptr inbounds %vector_container, %vector_container* %0, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_container, %vector_container* %0, i32 0, i32 2
    store i64 2, i64* %cap, align 4
    ret void
  }
  
  define private void @record_of_vecs(%container* sret %0) {
  entry:
    %1 = tail call i8* @malloc(i64 16)
    %2 = bitcast i8* %1 to i64*
    %vec = alloca %vector_int, align 8
    %data2 = bitcast %vector_int* %vec to i64**
    store i64* %2, i64** %data2, align 8
    store i64 1, i64* %2, align 4
    %3 = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %3, align 4
    %len = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 2
    store i64 2, i64* %cap, align 4
    %index3 = bitcast %container* %0 to i64*
    store i64 1, i64* %index3, align 4
    %vec1 = getelementptr inbounds %container, %container* %0, i32 0, i32 1
    %4 = bitcast %vector_int* %vec1 to i8*
    %5 = bitcast %vector_int* %vec to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    ret void
  }
  
  define private void @nest_local() {
  entry:
    %0 = tail call i8* @malloc(i64 48)
    %1 = bitcast i8* %0 to %vector_int*
    %vec = alloca %vector_vector_int, align 8
    %data8 = bitcast %vector_vector_int* %vec to %vector_int**
    store %vector_int* %1, %vector_int** %data8, align 8
    %2 = tail call i8* @malloc(i64 16)
    %3 = bitcast i8* %2 to i64*
    %data19 = bitcast %vector_int* %1 to i64**
    store i64* %3, i64** %data19, align 8
    store i64 0, i64* %3, align 4
    %4 = getelementptr i64, i64* %3, i64 1
    store i64 1, i64* %4, align 4
    %len = getelementptr inbounds %vector_int, %vector_int* %1, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %1, i32 0, i32 2
    store i64 2, i64* %cap, align 4
    %5 = getelementptr %vector_int, %vector_int* %1, i64 1
    %6 = tail call i8* @malloc(i64 16)
    %7 = bitcast i8* %6 to i64*
    %data210 = bitcast %vector_int* %5 to i64**
    store i64* %7, i64** %data210, align 8
    store i64 2, i64* %7, align 4
    %8 = getelementptr i64, i64* %7, i64 1
    store i64 3, i64* %8, align 4
    %len3 = getelementptr inbounds %vector_int, %vector_int* %5, i32 0, i32 1
    store i64 2, i64* %len3, align 4
    %cap4 = getelementptr inbounds %vector_int, %vector_int* %5, i32 0, i32 2
    store i64 2, i64* %cap4, align 4
    %len5 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec, i32 0, i32 1
    store i64 2, i64* %len5, align 4
    %cap6 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec, i32 0, i32 2
    store i64 2, i64* %cap6, align 4
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  rec:                                              ; preds = %free, %entry
    %lsr.iv = phi i8* [ %scevgep, %free ], [ %0, %entry ]
    %9 = phi i64 [ %14, %free ], [ 0, %entry ]
    %10 = icmp slt i64 %9, 2
    br i1 %10, label %free, label %cont
  
  free:                                             ; preds = %rec
    %11 = bitcast i8* %lsr.iv to i64**
    %12 = load i64*, i64** %11, align 8
    %13 = bitcast i64* %12 to i8*
    tail call void @free(i8* %13)
    %14 = add i64 %9, 1
    store i64 %14, i64* %cnt, align 4
    %scevgep = getelementptr i8, i8* %lsr.iv, i64 24
    br label %rec
  
  cont:                                             ; preds = %rec
    tail call void @free(i8* %0)
    ret void
  }
  
  define private void @nest_allocs(%vector_vector_int* sret %0) {
  entry:
    tail call void @make_nested_vec(%vector_vector_int* %0)
    ret void
  }
  
  define private void @make_nested_vec(%vector_vector_int* sret %0) {
  entry:
    %1 = tail call i8* @malloc(i64 48)
    %2 = bitcast i8* %1 to %vector_int*
    %data7 = bitcast %vector_vector_int* %0 to %vector_int**
    store %vector_int* %2, %vector_int** %data7, align 8
    %3 = tail call i8* @malloc(i64 16)
    %4 = bitcast i8* %3 to i64*
    %data18 = bitcast %vector_int* %2 to i64**
    store i64* %4, i64** %data18, align 8
    store i64 0, i64* %4, align 4
    %5 = getelementptr i64, i64* %4, i64 1
    store i64 1, i64* %5, align 4
    %len = getelementptr inbounds %vector_int, %vector_int* %2, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %2, i32 0, i32 2
    store i64 2, i64* %cap, align 4
    %6 = getelementptr %vector_int, %vector_int* %2, i64 1
    %7 = tail call i8* @malloc(i64 16)
    %8 = bitcast i8* %7 to i64*
    %data29 = bitcast %vector_int* %6 to i64**
    store i64* %8, i64** %data29, align 8
    store i64 2, i64* %8, align 4
    %9 = getelementptr i64, i64* %8, i64 1
    store i64 3, i64* %9, align 4
    %len3 = getelementptr inbounds %vector_int, %vector_int* %6, i32 0, i32 1
    store i64 2, i64* %len3, align 4
    %cap4 = getelementptr inbounds %vector_int, %vector_int* %6, i32 0, i32 2
    store i64 2, i64* %cap4, align 4
    %len5 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %0, i32 0, i32 1
    store i64 2, i64* %len5, align 4
    %cap6 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %0, i32 0, i32 2
    store i64 2, i64* %cap6, align 4
    ret void
  }
  
  define private void @nest_fns(%vector_foo* sret %0) {
  entry:
    tail call void @make_vec(%vector_foo* %0)
    ret void
  }
  
  define private void @inner_parent_scope() {
  entry:
    %ret = alloca %vector_foo, align 8
    call void @make_vec(%vector_foo* %ret)
    %0 = bitcast %vector_foo* %ret to %foo**
    %1 = load %foo*, %foo** %0, align 8
    %2 = bitcast %foo* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define private void @make_vec(%vector_foo* sret %0) {
  entry:
    %1 = alloca %foo, align 8
    %x3 = bitcast %foo* %1 to i64*
    store i64 23, i64* %x3, align 4
    %2 = tail call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to %foo*
    %data4 = bitcast %vector_foo* %0 to %foo**
    store %foo* %3, %foo** %data4, align 8
    %4 = bitcast %foo* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %4, i64 8, i1 false)
    %5 = getelementptr %foo, %foo* %3, i64 1
    %x15 = bitcast %foo* %5 to i64*
    store i64 2, i64* %x15, align 4
    %6 = getelementptr %foo, %foo* %3, i64 2
    %x26 = bitcast %foo* %6 to i64*
    store i64 3, i64* %x26, align 4
    %len = getelementptr inbounds %vector_foo, %vector_foo* %0, i32 0, i32 1
    store i64 3, i64* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %0, i32 0, i32 2
    store i64 3, i64* %cap, align 4
    ret void
  }
  
  define private void @vec_inside(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %foo }*
    %x3 = bitcast { %foo }* %clsr to %foo*
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to %foo*
    %vec = alloca %vector_foo, align 8
    %data4 = bitcast %vector_foo* %vec to %foo**
    store %foo* %2, %foo** %data4, align 8
    %3 = bitcast %foo* %x3 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %3, i64 8, i1 false)
    %4 = getelementptr %foo, %foo* %2, i64 1
    %x15 = bitcast %foo* %4 to i64*
    store i64 2, i64* %x15, align 4
    %5 = getelementptr %foo, %foo* %2, i64 2
    %x26 = bitcast %foo* %5 to i64*
    store i64 3, i64* %x26, align 4
    %len = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 1
    store i64 3, i64* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 2
    store i64 3, i64* %cap, align 4
    %6 = tail call i8* @realloc(i8* %1, i64 72)
    %7 = bitcast i8* %6 to %foo*
    store %foo* %7, %foo** %data4, align 8
    tail call void @free(i8* %6)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @free(i8* %0)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %x77 = bitcast %foo* %0 to i64*
    store i64 1, i64* %x77, align 4
    %1 = tail call i8* @malloc(i64 48)
    %2 = bitcast i8* %1 to %string*
    %vec = alloca %vector_string, align 8
    %data78 = bitcast %vector_string* %vec to %string**
    store %string* %2, %string** %data78, align 8
    %cstr79 = bitcast %string* %2 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr79, align 8
    %length = getelementptr inbounds %string, %string* %2, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %3 = getelementptr %string, %string* %2, i64 1
    %cstr180 = bitcast %string* %3 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @1, i32 0, i32 0), i8** %cstr180, align 8
    %length2 = getelementptr inbounds %string, %string* %3, i32 0, i32 1
    store i64 5, i64* %length2, align 4
    %4 = getelementptr %string, %string* %2, i64 2
    %cstr381 = bitcast %string* %4 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @2, i32 0, i32 0), i8** %cstr381, align 8
    %length4 = getelementptr inbounds %string, %string* %4, i32 0, i32 1
    store i64 5, i64* %length4, align 4
    %len = getelementptr inbounds %vector_string, %vector_string* %vec, i32 0, i32 1
    store i64 3, i64* %len, align 4
    %cap = getelementptr inbounds %vector_string, %vector_string* %vec, i32 0, i32 2
    store i64 3, i64* %cap, align 4
    %5 = tail call i8* @malloc(i64 24)
    %6 = bitcast i8* %5 to %foo*
    %vec5 = alloca %vector_foo, align 8
    %data682 = bitcast %vector_foo* %vec5 to %foo**
    store %foo* %6, %foo** %data682, align 8
    %7 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %7, i64 8, i1 false)
    %8 = getelementptr %foo, %foo* %6, i64 1
    %x783 = bitcast %foo* %8 to i64*
    store i64 2, i64* %x783, align 4
    %9 = getelementptr %foo, %foo* %6, i64 2
    %x884 = bitcast %foo* %9 to i64*
    store i64 3, i64* %x884, align 4
    %len9 = getelementptr inbounds %vector_foo, %vector_foo* %vec5, i32 0, i32 1
    store i64 3, i64* %len9, align 4
    %cap10 = getelementptr inbounds %vector_foo, %vector_foo* %vec5, i32 0, i32 2
    store i64 3, i64* %cap10, align 4
    %vec_inside = alloca %closure, align 8
    %funptr85 = bitcast %closure* %vec_inside to i8**
    store i8* bitcast (void (i8*)* @vec_inside to i8*), i8** %funptr85, align 8
    %clsr_vec_inside = alloca { %foo }, align 8
    %x1186 = bitcast { %foo }* %clsr_vec_inside to %foo*
    %10 = bitcast %foo* %x1186 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %7, i64 8, i1 false)
    %env = bitcast { %foo }* %clsr_vec_inside to i8*
    %envptr = getelementptr inbounds %closure, %closure* %vec_inside, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %ret = alloca %vector_foo, align 8
    call void @make_vec(%vector_foo* %ret)
    call void @vec_inside(i8* %env)
    call void @inner_parent_scope()
    %ret14 = alloca %vector_foo, align 8
    call void @nest_fns(%vector_foo* %ret14)
    %11 = call i8* @malloc(i64 48)
    %12 = bitcast i8* %11 to %vector_int*
    %vec15 = alloca %vector_vector_int, align 8
    %data1687 = bitcast %vector_vector_int* %vec15 to %vector_int**
    store %vector_int* %12, %vector_int** %data1687, align 8
    %13 = call i8* @malloc(i64 16)
    %14 = bitcast i8* %13 to i64*
    %data1788 = bitcast %vector_int* %12 to i64**
    store i64* %14, i64** %data1788, align 8
    store i64 0, i64* %14, align 4
    %15 = getelementptr i64, i64* %14, i64 1
    store i64 1, i64* %15, align 4
    %len18 = getelementptr inbounds %vector_int, %vector_int* %12, i32 0, i32 1
    store i64 2, i64* %len18, align 4
    %cap19 = getelementptr inbounds %vector_int, %vector_int* %12, i32 0, i32 2
    store i64 2, i64* %cap19, align 4
    %16 = getelementptr %vector_int, %vector_int* %12, i64 1
    %17 = call i8* @malloc(i64 16)
    %18 = bitcast i8* %17 to i64*
    %data2089 = bitcast %vector_int* %16 to i64**
    store i64* %18, i64** %data2089, align 8
    store i64 2, i64* %18, align 4
    %19 = getelementptr i64, i64* %18, i64 1
    store i64 3, i64* %19, align 4
    %len21 = getelementptr inbounds %vector_int, %vector_int* %16, i32 0, i32 1
    store i64 2, i64* %len21, align 4
    %cap22 = getelementptr inbounds %vector_int, %vector_int* %16, i32 0, i32 2
    store i64 2, i64* %cap22, align 4
    %len23 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec15, i32 0, i32 1
    store i64 2, i64* %len23, align 4
    %cap24 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec15, i32 0, i32 2
    store i64 2, i64* %cap24, align 4
    %20 = call i8* @realloc(i8* %11, i64 216)
    %21 = bitcast i8* %20 to %vector_int*
    store %vector_int* %21, %vector_int** %data1687, align 8
    %ret25 = alloca %vector_vector_int, align 8
    call void @make_nested_vec(%vector_vector_int* %ret25)
    %ret26 = alloca %vector_vector_int, align 8
    call void @nest_allocs(%vector_vector_int* %ret26)
    call void @nest_local()
    %22 = alloca %container, align 8
    %index90 = bitcast %container* %22 to i64*
    store i64 12, i64* %index90, align 4
    %vec27 = getelementptr inbounds %container, %container* %22, i32 0, i32 1
    %23 = call i8* @malloc(i64 16)
    %24 = bitcast i8* %23 to i64*
    %data2891 = bitcast %vector_int* %vec27 to i64**
    store i64* %24, i64** %data2891, align 8
    store i64 1, i64* %24, align 4
    %25 = getelementptr i64, i64* %24, i64 1
    store i64 2, i64* %25, align 4
    %len29 = getelementptr inbounds %vector_int, %vector_int* %vec27, i32 0, i32 1
    store i64 2, i64* %len29, align 4
    %cap30 = getelementptr inbounds %vector_int, %vector_int* %vec27, i32 0, i32 2
    store i64 2, i64* %cap30, align 4
    %ret31 = alloca %container, align 8
    call void @record_of_vecs(%container* %ret31)
    %26 = call i8* @malloc(i64 64)
    %27 = bitcast i8* %26 to %container*
    %vec32 = alloca %vector_container, align 8
    %data3392 = bitcast %vector_container* %vec32 to %container**
    store %container* %27, %container** %data3392, align 8
    call void @record_of_vecs(%container* %27)
    %28 = getelementptr %container, %container* %27, i64 1
    call void @record_of_vecs(%container* %28)
    %len34 = getelementptr inbounds %vector_container, %vector_container* %vec32, i32 0, i32 1
    store i64 2, i64* %len34, align 4
    %cap35 = getelementptr inbounds %vector_container, %vector_container* %vec32, i32 0, i32 2
    store i64 2, i64* %cap35, align 4
    %ret36 = alloca %vector_container, align 8
    call void @vec_of_records(%vector_container* %ret36)
    %29 = load %string*, %string** %data78, align 8
    %30 = bitcast %string* %29 to i8*
    call void @free(i8* %30)
    %31 = load %foo*, %foo** %data682, align 8
    %32 = bitcast %foo* %31 to i8*
    call void @free(i8* %32)
    %33 = bitcast %vector_foo* %ret to %foo**
    %34 = load %foo*, %foo** %33, align 8
    %35 = bitcast %foo* %34 to i8*
    call void @free(i8* %35)
    %36 = bitcast %vector_foo* %ret14 to %foo**
    %37 = load %foo*, %foo** %36, align 8
    %38 = bitcast %foo* %37 to i8*
    call void @free(i8* %38)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  rec:                                              ; preds = %free, %entry
    %lsr.iv74 = phi i8* [ %scevgep75, %free ], [ %20, %entry ]
    %39 = phi i64 [ %44, %free ], [ 0, %entry ]
    %40 = icmp slt i64 %39, 2
    br i1 %40, label %free, label %cont
  
  free:                                             ; preds = %rec
    %41 = bitcast i8* %lsr.iv74 to i64**
    %42 = load i64*, i64** %41, align 8
    %43 = bitcast i64* %42 to i8*
    call void @free(i8* %43)
    %44 = add i64 %39, 1
    store i64 %44, i64* %cnt, align 4
    %scevgep75 = getelementptr i8, i8* %lsr.iv74, i64 24
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(i8* %20)
    %45 = bitcast %vector_vector_int* %ret25 to %vector_int**
    %46 = load %vector_int*, %vector_int** %45, align 8
    %lenptr37 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %ret25, i32 0, i32 1
    %leni38 = load i64, i64* %lenptr37, align 4
    %cnt39 = alloca i64, align 8
    store i64 0, i64* %cnt39, align 4
    br label %rec40
  
  rec40:                                            ; preds = %free41, %cont
    %lsr.iv71 = phi %vector_int* [ %scevgep72, %free41 ], [ %46, %cont ]
    %47 = phi i64 [ %52, %free41 ], [ 0, %cont ]
    %48 = icmp slt i64 %47, %leni38
    br i1 %48, label %free41, label %cont42
  
  free41:                                           ; preds = %rec40
    %49 = bitcast %vector_int* %lsr.iv71 to i64**
    %50 = load i64*, i64** %49, align 8
    %51 = bitcast i64* %50 to i8*
    call void @free(i8* %51)
    %52 = add i64 %47, 1
    store i64 %52, i64* %cnt39, align 4
    %scevgep72 = getelementptr %vector_int, %vector_int* %lsr.iv71, i64 1
    br label %rec40
  
  cont42:                                           ; preds = %rec40
    %53 = bitcast %vector_int* %46 to i8*
    call void @free(i8* %53)
    %54 = bitcast %vector_vector_int* %ret26 to %vector_int**
    %55 = load %vector_int*, %vector_int** %54, align 8
    %lenptr43 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %ret26, i32 0, i32 1
    %leni44 = load i64, i64* %lenptr43, align 4
    %cnt45 = alloca i64, align 8
    store i64 0, i64* %cnt45, align 4
    br label %rec46
  
  rec46:                                            ; preds = %free47, %cont42
    %lsr.iv68 = phi %vector_int* [ %scevgep69, %free47 ], [ %55, %cont42 ]
    %56 = phi i64 [ %61, %free47 ], [ 0, %cont42 ]
    %57 = icmp slt i64 %56, %leni44
    br i1 %57, label %free47, label %cont48
  
  free47:                                           ; preds = %rec46
    %58 = bitcast %vector_int* %lsr.iv68 to i64**
    %59 = load i64*, i64** %58, align 8
    %60 = bitcast i64* %59 to i8*
    call void @free(i8* %60)
    %61 = add i64 %56, 1
    store i64 %61, i64* %cnt45, align 4
    %scevgep69 = getelementptr %vector_int, %vector_int* %lsr.iv68, i64 1
    br label %rec46
  
  cont48:                                           ; preds = %rec46
    %62 = bitcast %vector_int* %55 to i8*
    call void @free(i8* %62)
    call void @free(i8* %23)
    %63 = getelementptr inbounds %container, %container* %ret31, i32 0, i32 1
    %64 = bitcast %vector_int* %63 to i64**
    %65 = load i64*, i64** %64, align 8
    %66 = bitcast i64* %65 to i8*
    call void @free(i8* %66)
    %cnt51 = alloca i64, align 8
    store i64 0, i64* %cnt51, align 4
    %scevgep64 = getelementptr i8, i8* %26, i64 8
    br label %rec52
  
  rec52:                                            ; preds = %free53, %cont48
    %lsr.iv65 = phi i8* [ %scevgep66, %free53 ], [ %scevgep64, %cont48 ]
    %67 = phi i64 [ %72, %free53 ], [ 0, %cont48 ]
    %68 = icmp slt i64 %67, 2
    br i1 %68, label %free53, label %cont54
  
  free53:                                           ; preds = %rec52
    %69 = bitcast i8* %lsr.iv65 to i64**
    %70 = load i64*, i64** %69, align 8
    %71 = bitcast i64* %70 to i8*
    call void @free(i8* %71)
    %72 = add i64 %67, 1
    store i64 %72, i64* %cnt51, align 4
    %scevgep66 = getelementptr i8, i8* %lsr.iv65, i64 32
    br label %rec52
  
  cont54:                                           ; preds = %rec52
    call void @free(i8* %26)
    %73 = bitcast %vector_container* %ret36 to %container**
    %74 = load %container*, %container** %73, align 8
    %lenptr55 = getelementptr inbounds %vector_container, %vector_container* %ret36, i32 0, i32 1
    %leni56 = load i64, i64* %lenptr55, align 4
    %cnt57 = alloca i64, align 8
    store i64 0, i64* %cnt57, align 4
    %scevgep = getelementptr %container, %container* %74, i64 0, i32 1, i32 0
    %scevgep61 = bitcast i64** %scevgep to %container*
    br label %rec58
  
  rec58:                                            ; preds = %free59, %cont54
    %lsr.iv = phi %container* [ %scevgep62, %free59 ], [ %scevgep61, %cont54 ]
    %75 = phi i64 [ %80, %free59 ], [ 0, %cont54 ]
    %76 = icmp slt i64 %75, %leni56
    br i1 %76, label %free59, label %cont60
  
  free59:                                           ; preds = %rec58
    %77 = bitcast %container* %lsr.iv to i64**
    %78 = load i64*, i64** %77, align 8
    %79 = bitcast i64* %78 to i8*
    call void @free(i8* %79)
    %80 = add i64 %75, 1
    store i64 %80, i64* %cnt57, align 4
    %scevgep62 = getelementptr %container, %container* %lsr.iv, i64 1
    br label %rec58
  
  cont60:                                           ; preds = %rec58
    %81 = bitcast %container* %74 to i8*
    call void @free(i8* %81)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Test x86_64-linux-gnu ABI (parts of it, anyway)
  $ schmu -dump-llvm abi.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %v3 = type { double, double, double }
  %i3 = type { i64, i64, i64 }
  %v4 = type { double, double, double, double }
  %mixed4 = type { double, double, double, i64 }
  %trailv2 = type { i64, i64, double, double }
  %v2 = type { double, double }
  %i2 = type { i64, i64 }
  %v1 = type { double }
  %i1 = type { i64 }
  
  declare { double, double } @subv2(double %0, double %1)
  
  declare { i64, i64 } @subi2(i64 %0, i64 %1)
  
  declare double @subv1(double %0)
  
  declare i64 @subi1(i64 %0)
  
  declare void @subv3(%v3* %0, %v3* %1)
  
  declare void @subi3(%i3* %0, %i3* %1)
  
  declare void @subv4(%v4* %0, %v4* %1)
  
  declare void @submixed4(%mixed4* %0, %mixed4* %1)
  
  declare void @subtrailv2(%trailv2* %0, %trailv2* %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca %v2, align 8
    %z42 = bitcast %v2* %0 to double*
    store double 1.000000e+00, double* %z42, align 8
    %y = getelementptr inbounds %v2, %v2* %0, i32 0, i32 1
    store double 1.000000e+01, double* %y, align 8
    %unbox = bitcast %v2* %0 to { double, double }*
    %snd = getelementptr inbounds { double, double }, { double, double }* %unbox, i32 0, i32 1
    %ret = alloca %v2, align 8
    %1 = tail call { double, double } @subv2(double 1.000000e+00, double 1.000000e+01)
    %box = bitcast %v2* %ret to { double, double }*
    store { double, double } %1, { double, double }* %box, align 8
    %2 = alloca %i2, align 8
    %x44 = bitcast %i2* %2 to i64*
    store i64 1, i64* %x44, align 4
    %y4 = getelementptr inbounds %i2, %i2* %2, i32 0, i32 1
    store i64 10, i64* %y4, align 4
    %unbox5 = bitcast %i2* %2 to { i64, i64 }*
    %snd8 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox5, i32 0, i32 1
    %ret10 = alloca %i2, align 8
    %3 = tail call { i64, i64 } @subi2(i64 1, i64 10)
    %box11 = bitcast %i2* %ret10 to { i64, i64 }*
    store { i64, i64 } %3, { i64, i64 }* %box11, align 4
    %4 = alloca %v1, align 8
    %z1346 = bitcast %v1* %4 to double*
    store double 1.000000e+00, double* %z1346, align 8
    %ret16 = alloca %v1, align 8
    %5 = tail call double @subv1(double 1.000000e+00)
    %box17 = bitcast %v1* %ret16 to double*
    store double %5, double* %box17, align 8
    %6 = alloca %i1, align 8
    %x1947 = bitcast %i1* %6 to i64*
    store i64 1, i64* %x1947, align 4
    %ret22 = alloca %i1, align 8
    %7 = tail call i64 @subi1(i64 1)
    %box23 = bitcast %i1* %ret22 to i64*
    store i64 %7, i64* %box23, align 4
    %8 = alloca %v3, align 8
    %x2548 = bitcast %v3* %8 to double*
    store double 1.000000e+00, double* %x2548, align 8
    %y26 = getelementptr inbounds %v3, %v3* %8, i32 0, i32 1
    store double 1.000000e+01, double* %y26, align 8
    %z27 = getelementptr inbounds %v3, %v3* %8, i32 0, i32 2
    store double 1.000000e+02, double* %z27, align 8
    %ret28 = alloca %v3, align 8
    call void @subv3(%v3* %ret28, %v3* %8)
    %9 = alloca %i3, align 8
    %w49 = bitcast %i3* %9 to i64*
    store i64 1, i64* %w49, align 4
    %y29 = getelementptr inbounds %i3, %i3* %9, i32 0, i32 1
    store i64 10, i64* %y29, align 4
    %z30 = getelementptr inbounds %i3, %i3* %9, i32 0, i32 2
    store i64 100, i64* %z30, align 4
    %ret31 = alloca %i3, align 8
    call void @subi3(%i3* %ret31, %i3* %9)
    %10 = alloca %v4, align 8
    %x3250 = bitcast %v4* %10 to double*
    store double 1.000000e+00, double* %x3250, align 8
    %y33 = getelementptr inbounds %v4, %v4* %10, i32 0, i32 1
    store double 1.000000e+01, double* %y33, align 8
    %z34 = getelementptr inbounds %v4, %v4* %10, i32 0, i32 2
    store double 1.000000e+02, double* %z34, align 8
    %w35 = getelementptr inbounds %v4, %v4* %10, i32 0, i32 3
    store double 1.000000e+03, double* %w35, align 8
    %ret36 = alloca %v4, align 8
    call void @subv4(%v4* %ret36, %v4* %10)
    %11 = alloca %mixed4, align 8
    %x3751 = bitcast %mixed4* %11 to double*
    store double 1.000000e+00, double* %x3751, align 8
    %y38 = getelementptr inbounds %mixed4, %mixed4* %11, i32 0, i32 1
    store double 1.000000e+01, double* %y38, align 8
    %z39 = getelementptr inbounds %mixed4, %mixed4* %11, i32 0, i32 2
    store double 1.000000e+02, double* %z39, align 8
    %k = getelementptr inbounds %mixed4, %mixed4* %11, i32 0, i32 3
    store i64 1, i64* %k, align 4
    %ret40 = alloca %mixed4, align 8
    call void @submixed4(%mixed4* %ret40, %mixed4* %11)
    %12 = alloca %trailv2, align 8
    %a52 = bitcast %trailv2* %12 to i64*
    store i64 1, i64* %a52, align 4
    %b = getelementptr inbounds %trailv2, %trailv2* %12, i32 0, i32 1
    store i64 2, i64* %b, align 4
    %c = getelementptr inbounds %trailv2, %trailv2* %12, i32 0, i32 2
    store double 1.000000e+00, double* %c, align 8
    %d = getelementptr inbounds %trailv2, %trailv2* %12, i32 0, i32 3
    store double 2.000000e+00, double* %d, align 8
    %ret41 = alloca %trailv2, align 8
    call void @subtrailv2(%trailv2* %ret41, %trailv2* %12)
    ret i64 0
  }

Regression test for issue #19
  $ schmu -dump-llvm regression_issue_19.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %v3 = type { double, double, double }
  
  define private void @wrap(%v3* sret %0) {
  entry:
    %1 = alloca %v3, align 8
    %x5 = bitcast %v3* %1 to double*
    store double 1.000000e+00, double* %x5, align 8
    %y = getelementptr inbounds %v3, %v3* %1, i32 0, i32 1
    store double 1.000000e+01, double* %y, align 8
    %z = getelementptr inbounds %v3, %v3* %1, i32 0, i32 2
    store double 1.000000e+02, double* %z, align 8
    %ret = alloca %v3, align 8
    call void @v3_scale(%v3* %ret, %v3* %1, double 1.500000e+00)
    %2 = alloca %v3, align 8
    %x16 = bitcast %v3* %2 to double*
    store double 1.000000e+00, double* %x16, align 8
    %y2 = getelementptr inbounds %v3, %v3* %2, i32 0, i32 1
    store double 2.000000e+00, double* %y2, align 8
    %z3 = getelementptr inbounds %v3, %v3* %2, i32 0, i32 2
    store double 3.000000e+00, double* %z3, align 8
    %ret4 = alloca %v3, align 8
    call void @v3_scale(%v3* %ret4, %v3* %2, double 1.500000e+00)
    call void @v3_add(%v3* %0, %v3* %ret, %v3* %ret4)
    ret void
  }
  
  define private void @v3_scale(%v3* sret %0, %v3* %v3, double %factor) {
  entry:
    %x3 = bitcast %v3* %0 to double*
    %1 = bitcast %v3* %v3 to double*
    %2 = load double, double* %1, align 8
    %mul = fmul double %2, %factor
    store double %mul, double* %x3, align 8
    %y = getelementptr inbounds %v3, %v3* %0, i32 0, i32 1
    %3 = getelementptr inbounds %v3, %v3* %v3, i32 0, i32 1
    %4 = load double, double* %3, align 8
    %mul1 = fmul double %4, %factor
    store double %mul1, double* %y, align 8
    %z = getelementptr inbounds %v3, %v3* %0, i32 0, i32 2
    %5 = getelementptr inbounds %v3, %v3* %v3, i32 0, i32 2
    %6 = load double, double* %5, align 8
    %mul2 = fmul double %6, %factor
    store double %mul2, double* %z, align 8
    ret void
  }
  
  define private void @v3_add(%v3* sret %0, %v3* %lhs, %v3* %rhs) {
  entry:
    %x3 = bitcast %v3* %0 to double*
    %1 = bitcast %v3* %lhs to double*
    %2 = load double, double* %1, align 8
    %3 = bitcast %v3* %rhs to double*
    %4 = load double, double* %3, align 8
    %add = fadd double %2, %4
    store double %add, double* %x3, align 8
    %y = getelementptr inbounds %v3, %v3* %0, i32 0, i32 1
    %5 = getelementptr inbounds %v3, %v3* %lhs, i32 0, i32 1
    %6 = load double, double* %5, align 8
    %7 = getelementptr inbounds %v3, %v3* %rhs, i32 0, i32 1
    %8 = load double, double* %7, align 8
    %add1 = fadd double %6, %8
    store double %add1, double* %y, align 8
    %z = getelementptr inbounds %v3, %v3* %0, i32 0, i32 2
    %9 = getelementptr inbounds %v3, %v3* %lhs, i32 0, i32 2
    %10 = load double, double* %9, align 8
    %11 = getelementptr inbounds %v3, %v3* %rhs, i32 0, i32 2
    %12 = load double, double* %11, align 8
    %add2 = fadd double %10, %12
    store double %add2, double* %z, align 8
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %ret = alloca %v3, align 8
    call void @wrap(%v3* %ret)
    ret i64 0
  }
