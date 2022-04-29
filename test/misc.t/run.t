Compile stubs
  $ cc -c stub.c

Test elif
  $ schmu -o out.o --dump-llvm elseif.smu && cc out.o stub.o && ./a.out
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
  $ schmu -o out.o --dump-llvm simple_typealias.smu && cc out.o stub.o && ./a.out
  simple_typealias.smu:2:10: warning: Unused binding puts
  2 | external puts : foo -> unit
               ^^^^
  
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
  $ schmu -o out.o --dump-llvm free_vector.smu && cc out.o stub.o && ./a.out
  free_vector.smu:7:1: warning: Unused binding vec
  7 | vec = ["hey", "young", "world"]
      ^^^
  
  free_vector.smu:8:1: warning: Unused binding vec
  8 | vec = [x, {x = 2}, {x = 3}]
      ^^^
  
  free_vector.smu:58:1: warning: Unused binding vec
  58 | vec = make_vec()
       ^^^
  
  free_vector.smu:61:1: warning: Unused binding normal
  61 | normal = nest_fns()
       ^^^^^^
  
  free_vector.smu:65:1: warning: Unused binding nested
  65 | nested = make_nested_vec()
       ^^^^^^
  
  free_vector.smu:66:1: warning: Unused binding nested
  66 | nested = nest_allocs()
       ^^^^^^
  
  free_vector.smu:69:1: warning: Unused binding rec_of_vec
  69 | rec_of_vec = { index = 12, vec = [1, 2]}
       ^^^^^^^^^^
  
  free_vector.smu:70:1: warning: Unused binding rec_of_vec
  70 | rec_of_vec = record_of_vecs()
       ^^^^^^^^^^
  
  free_vector.smu:72:1: warning: Unused binding vec_of_rec
  72 | vec_of_rec = [record_of_vecs(), record_of_vecs()]
       ^^^^^^^^^^
  
  free_vector.smu:73:1: warning: Unused binding vec_of_rec
  73 | vec_of_rec = vec_of_records()
       ^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %vector_container = type { %container*, i64, i64 }
  %container = type { i64, %vector_int }
  %vector_int = type { i64*, i64, i64 }
  %vector_vector_int = type { %vector_int*, i64, i64 }
  %vector_foo = type { %foo*, i64, i64 }
  %string = type { i8*, i64 }
  %vector_string = type { %string*, i64, i64 }
  
  @x = constant %foo { i64 1 }
  @__2x = constant %foo { i64 23 }
  @0 = private unnamed_addr constant [4 x i8] c"hey\00", align 1
  @1 = private unnamed_addr constant [6 x i8] c"young\00", align 1
  @2 = private unnamed_addr constant [6 x i8] c"world\00", align 1
  
  define private void @vec_of_records(%vector_container* %0) {
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
  
  define private void @record_of_vecs(%container* %0) {
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
  
  define private void @nest_allocs(%vector_vector_int* %0) {
  entry:
    tail call void @make_nested_vec(%vector_vector_int* %0)
    ret void
  }
  
  define private void @make_nested_vec(%vector_vector_int* %0) {
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
  
  define private void @nest_fns(%vector_foo* %0) {
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
  
  define private void @make_vec(%vector_foo* %0) {
  entry:
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to %foo*
    %data1 = bitcast %vector_foo* %0 to %foo**
    store %foo* %2, %foo** %data1, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* bitcast (%foo* @__2x to i8*), i64 8, i1 false)
    %3 = getelementptr %foo, %foo* %2, i64 1
    store %foo { i64 2 }, %foo* %3, align 4
    %4 = getelementptr %foo, %foo* %2, i64 2
    store %foo { i64 3 }, %foo* %4, align 4
    %len = getelementptr inbounds %vector_foo, %vector_foo* %0, i32 0, i32 1
    store i64 3, i64* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %0, i32 0, i32 2
    store i64 3, i64* %cap, align 4
    ret void
  }
  
  define private void @vec_inside() {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to %foo*
    %vec = alloca %vector_foo, align 8
    %data1 = bitcast %vector_foo* %vec to %foo**
    store %foo* %1, %foo** %data1, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* bitcast (%foo* @x to i8*), i64 8, i1 false)
    %2 = getelementptr %foo, %foo* %1, i64 1
    store %foo { i64 2 }, %foo* %2, align 4
    %3 = getelementptr %foo, %foo* %1, i64 2
    store %foo { i64 3 }, %foo* %3, align 4
    %len = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 1
    store i64 3, i64* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 2
    store i64 3, i64* %cap, align 4
    %4 = tail call i8* @realloc(i8* %0, i64 72)
    %5 = bitcast i8* %4 to %foo*
    store %foo* %5, %foo** %data1, align 8
    tail call void @free(i8* %4)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @free(i8* %0)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 48)
    %1 = bitcast i8* %0 to %string*
    %vec = alloca %vector_string, align 8
    %data72 = bitcast %vector_string* %vec to %string**
    store %string* %1, %string** %data72, align 8
    %cstr73 = bitcast %string* %1 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr73, align 8
    %length = getelementptr inbounds %string, %string* %1, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %2 = getelementptr %string, %string* %1, i64 1
    %cstr174 = bitcast %string* %2 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @1, i32 0, i32 0), i8** %cstr174, align 8
    %length2 = getelementptr inbounds %string, %string* %2, i32 0, i32 1
    store i64 5, i64* %length2, align 4
    %3 = getelementptr %string, %string* %1, i64 2
    %cstr375 = bitcast %string* %3 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @2, i32 0, i32 0), i8** %cstr375, align 8
    %length4 = getelementptr inbounds %string, %string* %3, i32 0, i32 1
    store i64 5, i64* %length4, align 4
    %len = getelementptr inbounds %vector_string, %vector_string* %vec, i32 0, i32 1
    store i64 3, i64* %len, align 4
    %cap = getelementptr inbounds %vector_string, %vector_string* %vec, i32 0, i32 2
    store i64 3, i64* %cap, align 4
    %4 = tail call i8* @malloc(i64 24)
    %5 = bitcast i8* %4 to %foo*
    %vec5 = alloca %vector_foo, align 8
    %data676 = bitcast %vector_foo* %vec5 to %foo**
    store %foo* %5, %foo** %data676, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* bitcast (%foo* @x to i8*), i64 8, i1 false)
    %6 = getelementptr %foo, %foo* %5, i64 1
    store %foo { i64 2 }, %foo* %6, align 4
    %7 = getelementptr %foo, %foo* %5, i64 2
    store %foo { i64 3 }, %foo* %7, align 4
    %len7 = getelementptr inbounds %vector_foo, %vector_foo* %vec5, i32 0, i32 1
    store i64 3, i64* %len7, align 4
    %cap8 = getelementptr inbounds %vector_foo, %vector_foo* %vec5, i32 0, i32 2
    store i64 3, i64* %cap8, align 4
    %ret = alloca %vector_foo, align 8
    call void @make_vec(%vector_foo* %ret)
    call void @vec_inside()
    call void @inner_parent_scope()
    %ret9 = alloca %vector_foo, align 8
    call void @nest_fns(%vector_foo* %ret9)
    %8 = call i8* @malloc(i64 48)
    %9 = bitcast i8* %8 to %vector_int*
    %vec10 = alloca %vector_vector_int, align 8
    %data1177 = bitcast %vector_vector_int* %vec10 to %vector_int**
    store %vector_int* %9, %vector_int** %data1177, align 8
    %10 = call i8* @malloc(i64 16)
    %11 = bitcast i8* %10 to i64*
    %data1278 = bitcast %vector_int* %9 to i64**
    store i64* %11, i64** %data1278, align 8
    store i64 0, i64* %11, align 4
    %12 = getelementptr i64, i64* %11, i64 1
    store i64 1, i64* %12, align 4
    %len13 = getelementptr inbounds %vector_int, %vector_int* %9, i32 0, i32 1
    store i64 2, i64* %len13, align 4
    %cap14 = getelementptr inbounds %vector_int, %vector_int* %9, i32 0, i32 2
    store i64 2, i64* %cap14, align 4
    %13 = getelementptr %vector_int, %vector_int* %9, i64 1
    %14 = call i8* @malloc(i64 16)
    %15 = bitcast i8* %14 to i64*
    %data1579 = bitcast %vector_int* %13 to i64**
    store i64* %15, i64** %data1579, align 8
    store i64 2, i64* %15, align 4
    %16 = getelementptr i64, i64* %15, i64 1
    store i64 3, i64* %16, align 4
    %len16 = getelementptr inbounds %vector_int, %vector_int* %13, i32 0, i32 1
    store i64 2, i64* %len16, align 4
    %cap17 = getelementptr inbounds %vector_int, %vector_int* %13, i32 0, i32 2
    store i64 2, i64* %cap17, align 4
    %len18 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec10, i32 0, i32 1
    store i64 2, i64* %len18, align 4
    %cap19 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec10, i32 0, i32 2
    store i64 2, i64* %cap19, align 4
    %17 = call i8* @realloc(i8* %8, i64 216)
    %18 = bitcast i8* %17 to %vector_int*
    store %vector_int* %18, %vector_int** %data1177, align 8
    %ret20 = alloca %vector_vector_int, align 8
    call void @make_nested_vec(%vector_vector_int* %ret20)
    %ret21 = alloca %vector_vector_int, align 8
    call void @nest_allocs(%vector_vector_int* %ret21)
    call void @nest_local()
    %19 = alloca %container, align 8
    %index80 = bitcast %container* %19 to i64*
    store i64 12, i64* %index80, align 4
    %vec22 = getelementptr inbounds %container, %container* %19, i32 0, i32 1
    %20 = call i8* @malloc(i64 16)
    %21 = bitcast i8* %20 to i64*
    %data2381 = bitcast %vector_int* %vec22 to i64**
    store i64* %21, i64** %data2381, align 8
    store i64 1, i64* %21, align 4
    %22 = getelementptr i64, i64* %21, i64 1
    store i64 2, i64* %22, align 4
    %len24 = getelementptr inbounds %vector_int, %vector_int* %vec22, i32 0, i32 1
    store i64 2, i64* %len24, align 4
    %cap25 = getelementptr inbounds %vector_int, %vector_int* %vec22, i32 0, i32 2
    store i64 2, i64* %cap25, align 4
    %ret26 = alloca %container, align 8
    call void @record_of_vecs(%container* %ret26)
    %23 = call i8* @malloc(i64 64)
    %24 = bitcast i8* %23 to %container*
    %vec27 = alloca %vector_container, align 8
    %data2882 = bitcast %vector_container* %vec27 to %container**
    store %container* %24, %container** %data2882, align 8
    call void @record_of_vecs(%container* %24)
    %25 = getelementptr %container, %container* %24, i64 1
    call void @record_of_vecs(%container* %25)
    %len29 = getelementptr inbounds %vector_container, %vector_container* %vec27, i32 0, i32 1
    store i64 2, i64* %len29, align 4
    %cap30 = getelementptr inbounds %vector_container, %vector_container* %vec27, i32 0, i32 2
    store i64 2, i64* %cap30, align 4
    %ret31 = alloca %vector_container, align 8
    call void @vec_of_records(%vector_container* %ret31)
    %26 = load %string*, %string** %data72, align 8
    %27 = bitcast %string* %26 to i8*
    call void @free(i8* %27)
    call void @free(i8* %4)
    %28 = bitcast %vector_foo* %ret to %foo**
    %29 = load %foo*, %foo** %28, align 8
    %30 = bitcast %foo* %29 to i8*
    call void @free(i8* %30)
    %31 = bitcast %vector_foo* %ret9 to %foo**
    %32 = load %foo*, %foo** %31, align 8
    %33 = bitcast %foo* %32 to i8*
    call void @free(i8* %33)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  rec:                                              ; preds = %free, %entry
    %lsr.iv69 = phi i8* [ %scevgep70, %free ], [ %17, %entry ]
    %34 = phi i64 [ %39, %free ], [ 0, %entry ]
    %35 = icmp slt i64 %34, 2
    br i1 %35, label %free, label %cont
  
  free:                                             ; preds = %rec
    %36 = bitcast i8* %lsr.iv69 to i64**
    %37 = load i64*, i64** %36, align 8
    %38 = bitcast i64* %37 to i8*
    call void @free(i8* %38)
    %39 = add i64 %34, 1
    store i64 %39, i64* %cnt, align 4
    %scevgep70 = getelementptr i8, i8* %lsr.iv69, i64 24
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(i8* %17)
    %40 = bitcast %vector_vector_int* %ret20 to %vector_int**
    %41 = load %vector_int*, %vector_int** %40, align 8
    %lenptr32 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %ret20, i32 0, i32 1
    %leni33 = load i64, i64* %lenptr32, align 4
    %cnt34 = alloca i64, align 8
    store i64 0, i64* %cnt34, align 4
    br label %rec35
  
  rec35:                                            ; preds = %free36, %cont
    %lsr.iv66 = phi %vector_int* [ %scevgep67, %free36 ], [ %41, %cont ]
    %42 = phi i64 [ %47, %free36 ], [ 0, %cont ]
    %43 = icmp slt i64 %42, %leni33
    br i1 %43, label %free36, label %cont37
  
  free36:                                           ; preds = %rec35
    %44 = bitcast %vector_int* %lsr.iv66 to i64**
    %45 = load i64*, i64** %44, align 8
    %46 = bitcast i64* %45 to i8*
    call void @free(i8* %46)
    %47 = add i64 %42, 1
    store i64 %47, i64* %cnt34, align 4
    %scevgep67 = getelementptr %vector_int, %vector_int* %lsr.iv66, i64 1
    br label %rec35
  
  cont37:                                           ; preds = %rec35
    %48 = bitcast %vector_int* %41 to i8*
    call void @free(i8* %48)
    %49 = bitcast %vector_vector_int* %ret21 to %vector_int**
    %50 = load %vector_int*, %vector_int** %49, align 8
    %lenptr38 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %ret21, i32 0, i32 1
    %leni39 = load i64, i64* %lenptr38, align 4
    %cnt40 = alloca i64, align 8
    store i64 0, i64* %cnt40, align 4
    br label %rec41
  
  rec41:                                            ; preds = %free42, %cont37
    %lsr.iv63 = phi %vector_int* [ %scevgep64, %free42 ], [ %50, %cont37 ]
    %51 = phi i64 [ %56, %free42 ], [ 0, %cont37 ]
    %52 = icmp slt i64 %51, %leni39
    br i1 %52, label %free42, label %cont43
  
  free42:                                           ; preds = %rec41
    %53 = bitcast %vector_int* %lsr.iv63 to i64**
    %54 = load i64*, i64** %53, align 8
    %55 = bitcast i64* %54 to i8*
    call void @free(i8* %55)
    %56 = add i64 %51, 1
    store i64 %56, i64* %cnt40, align 4
    %scevgep64 = getelementptr %vector_int, %vector_int* %lsr.iv63, i64 1
    br label %rec41
  
  cont43:                                           ; preds = %rec41
    %57 = bitcast %vector_int* %50 to i8*
    call void @free(i8* %57)
    call void @free(i8* %20)
    %58 = getelementptr inbounds %container, %container* %ret26, i32 0, i32 1
    %59 = bitcast %vector_int* %58 to i64**
    %60 = load i64*, i64** %59, align 8
    %61 = bitcast i64* %60 to i8*
    call void @free(i8* %61)
    %cnt46 = alloca i64, align 8
    store i64 0, i64* %cnt46, align 4
    %scevgep59 = getelementptr i8, i8* %23, i64 8
    br label %rec47
  
  rec47:                                            ; preds = %free48, %cont43
    %lsr.iv60 = phi i8* [ %scevgep61, %free48 ], [ %scevgep59, %cont43 ]
    %62 = phi i64 [ %67, %free48 ], [ 0, %cont43 ]
    %63 = icmp slt i64 %62, 2
    br i1 %63, label %free48, label %cont49
  
  free48:                                           ; preds = %rec47
    %64 = bitcast i8* %lsr.iv60 to i64**
    %65 = load i64*, i64** %64, align 8
    %66 = bitcast i64* %65 to i8*
    call void @free(i8* %66)
    %67 = add i64 %62, 1
    store i64 %67, i64* %cnt46, align 4
    %scevgep61 = getelementptr i8, i8* %lsr.iv60, i64 32
    br label %rec47
  
  cont49:                                           ; preds = %rec47
    call void @free(i8* %23)
    %68 = bitcast %vector_container* %ret31 to %container**
    %69 = load %container*, %container** %68, align 8
    %lenptr50 = getelementptr inbounds %vector_container, %vector_container* %ret31, i32 0, i32 1
    %leni51 = load i64, i64* %lenptr50, align 4
    %cnt52 = alloca i64, align 8
    store i64 0, i64* %cnt52, align 4
    %scevgep = getelementptr %container, %container* %69, i64 0, i32 1, i32 0
    %scevgep56 = bitcast i64** %scevgep to %container*
    br label %rec53
  
  rec53:                                            ; preds = %free54, %cont49
    %lsr.iv = phi %container* [ %scevgep57, %free54 ], [ %scevgep56, %cont49 ]
    %70 = phi i64 [ %75, %free54 ], [ 0, %cont49 ]
    %71 = icmp slt i64 %70, %leni51
    br i1 %71, label %free54, label %cont55
  
  free54:                                           ; preds = %rec53
    %72 = bitcast %container* %lsr.iv to i64**
    %73 = load i64*, i64** %72, align 8
    %74 = bitcast i64* %73 to i8*
    call void @free(i8* %74)
    %75 = add i64 %70, 1
    store i64 %75, i64* %cnt52, align 4
    %scevgep57 = getelementptr %container, %container* %lsr.iv, i64 1
    br label %rec53
  
  cont55:                                           ; preds = %rec53
    %76 = bitcast %container* %69 to i8*
    call void @free(i8* %76)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Test x86_64-linux-gnu ABI (parts of it, anyway)
  $ schmu -o out.o --dump-llvm abi.smu
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
    %boxconst = alloca %v2, align 8
    store %v2 { double 1.000000e+00, double 1.000000e+01 }, %v2* %boxconst, align 8
    %unbox = bitcast %v2* %boxconst to { double, double }*
    %fst29 = bitcast { double, double }* %unbox to double*
    %fst1 = load double, double* %fst29, align 8
    %snd = getelementptr inbounds { double, double }, { double, double }* %unbox, i32 0, i32 1
    %snd2 = load double, double* %snd, align 8
    %ret = alloca %v2, align 8
    %0 = tail call { double, double } @subv2(double %fst1, double %snd2)
    %box = bitcast %v2* %ret to { double, double }*
    store { double, double } %0, { double, double }* %box, align 8
    %boxconst4 = alloca %i2, align 8
    store %i2 { i64 1, i64 10 }, %i2* %boxconst4, align 4
    %unbox5 = bitcast %i2* %boxconst4 to { i64, i64 }*
    %fst630 = bitcast { i64, i64 }* %unbox5 to i64*
    %fst7 = load i64, i64* %fst630, align 4
    %snd8 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox5, i32 0, i32 1
    %snd9 = load i64, i64* %snd8, align 4
    %ret10 = alloca %i2, align 8
    %1 = tail call { i64, i64 } @subi2(i64 %fst7, i64 %snd9)
    %box11 = bitcast %i2* %ret10 to { i64, i64 }*
    store { i64, i64 } %1, { i64, i64 }* %box11, align 4
    %ret13 = alloca %v1, align 8
    %2 = tail call double @subv1(double bitcast (%v1 { double 1.000000e+00 } to double))
    %box14 = bitcast %v1* %ret13 to double*
    store double %2, double* %box14, align 8
    %ret16 = alloca %i1, align 8
    %3 = tail call i64 @subi1(i64 bitcast (%i1 { i64 1 } to i64))
    %box17 = bitcast %i1* %ret16 to i64*
    store i64 %3, i64* %box17, align 4
    %boxconst19 = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, %v3* %boxconst19, align 8
    %ret20 = alloca %v3, align 8
    call void @subv3(%v3* %ret20, %v3* %boxconst19)
    %boxconst21 = alloca %i3, align 8
    store %i3 { i64 1, i64 10, i64 100 }, %i3* %boxconst21, align 4
    %ret22 = alloca %i3, align 8
    call void @subi3(%i3* %ret22, %i3* %boxconst21)
    %boxconst23 = alloca %v4, align 8
    store %v4 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, %v4* %boxconst23, align 8
    %ret24 = alloca %v4, align 8
    call void @subv4(%v4* %ret24, %v4* %boxconst23)
    %boxconst25 = alloca %mixed4, align 8
    store %mixed4 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, i64 1 }, %mixed4* %boxconst25, align 8
    %ret26 = alloca %mixed4, align 8
    call void @submixed4(%mixed4* %ret26, %mixed4* %boxconst25)
    %boxconst27 = alloca %trailv2, align 8
    store %trailv2 { i64 1, i64 2, double 1.000000e+00, double 2.000000e+00 }, %trailv2* %boxconst27, align 8
    %ret28 = alloca %trailv2, align 8
    call void @subtrailv2(%trailv2* %ret28, %trailv2* %boxconst27)
    ret i64 0
  }

Regression test for issue #19
  $ schmu -o out.o --dump-llvm regression_issue_19.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %v3 = type { double, double, double }
  
  define private void @wrap(%v3* %0) {
  entry:
    %boxconst = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, %v3* %boxconst, align 8
    %ret = alloca %v3, align 8
    call void @v3_scale(%v3* %ret, %v3* %boxconst, double 1.500000e+00)
    %boxconst1 = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 2.000000e+00, double 3.000000e+00 }, %v3* %boxconst1, align 8
    %ret2 = alloca %v3, align 8
    call void @v3_scale(%v3* %ret2, %v3* %boxconst1, double 1.500000e+00)
    call void @v3_add(%v3* %0, %v3* %ret, %v3* %ret2)
    ret void
  }
  
  define private void @v3_scale(%v3* %0, %v3* %v3, double %factor) {
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
  
  define private void @v3_add(%v3* %0, %v3* %lhs, %v3* %rhs) {
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

Test 'and', 'or' and 'not'
  $ schmu -o out.o --dump-llvm boolean_logic.smu && cc out.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @0 = private unnamed_addr constant [6 x i8] c"false\00", align 1
  @1 = private unnamed_addr constant [5 x i8] c"true\00", align 1
  @2 = private unnamed_addr constant [12 x i8] c"test 'and':\00", align 1
  @3 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @4 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @5 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @6 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @7 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @8 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @9 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @10 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @11 = private unnamed_addr constant [11 x i8] c"test 'or':\00", align 1
  @12 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @13 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @14 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @15 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @16 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @17 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @18 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @19 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @20 = private unnamed_addr constant [12 x i8] c"test 'not':\00", align 1
  @21 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @22 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @23 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @24 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  
  declare void @puts(i8* %0)
  
  define private i1 @false_() {
  entry:
    %str = alloca %string, align 8
    %cstr3 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @0, i32 0, i32 0), i8** %cstr3, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 5, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([6 x i8]* @0 to i64), i64 5)
    ret i1 false
  }
  
  define private i1 @true_() {
  entry:
    %str = alloca %string, align 8
    %cstr3 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([5 x i8], [5 x i8]* @1, i32 0, i32 0), i8** %cstr3, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 4, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([5 x i8]* @1 to i64), i64 4)
    ret i1 true
  }
  
  define private void @ps(i64 %0, i64 %1) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst2 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst2, align 4
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 4
    %2 = inttoptr i64 %0 to i8*
    tail call void @puts(i8* %2)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca %string, align 8
    %cstr232 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @2, i32 0, i32 0), i8** %cstr232, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 11, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([12 x i8]* @2 to i64), i64 11)
    %0 = tail call i1 @true_()
    br i1 %0, label %true1, label %cont
  
  true1:                                            ; preds = %entry
    %1 = tail call i1 @true_()
    br i1 %1, label %true2, label %cont
  
  true2:                                            ; preds = %true1
    br label %cont
  
  cont:                                             ; preds = %true2, %true1, %entry
    %andtmp = phi i1 [ false, %entry ], [ false, %true1 ], [ true, %true2 ]
    br i1 %andtmp, label %then, label %else
  
  then:                                             ; preds = %cont
    %str3 = alloca %string, align 8
    %cstr4234 = bitcast %string* %str3 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr4234, align 8
    %length5 = getelementptr inbounds %string, %string* %str3, i32 0, i32 1
    store i64 3, i64* %length5, align 4
    %unbox6 = bitcast %string* %str3 to { i64, i64 }*
    %snd9 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox6, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont
  
  else:                                             ; preds = %cont
    %str11 = alloca %string, align 8
    %cstr12236 = bitcast %string* %str11 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr12236, align 8
    %length13 = getelementptr inbounds %string, %string* %str11, i32 0, i32 1
    store i64 2, i64* %length13, align 4
    %unbox14 = bitcast %string* %str11 to { i64, i64 }*
    %snd17 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox14, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %2 = tail call i1 @true_()
    br i1 %2, label %true119, label %cont21
  
  true119:                                          ; preds = %ifcont
    %3 = tail call i1 @false_()
    br i1 %3, label %true220, label %cont21
  
  true220:                                          ; preds = %true119
    br label %cont21
  
  cont21:                                           ; preds = %true220, %true119, %ifcont
    %andtmp22 = phi i1 [ false, %ifcont ], [ false, %true119 ], [ true, %true220 ]
    br i1 %andtmp22, label %then23, label %else32
  
  then23:                                           ; preds = %cont21
    %str24 = alloca %string, align 8
    %cstr25238 = bitcast %string* %str24 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @5, i32 0, i32 0), i8** %cstr25238, align 8
    %length26 = getelementptr inbounds %string, %string* %str24, i32 0, i32 1
    store i64 3, i64* %length26, align 4
    %unbox27 = bitcast %string* %str24 to { i64, i64 }*
    %snd30 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox27, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @5 to i64), i64 3)
    br label %ifcont41
  
  else32:                                           ; preds = %cont21
    %str33 = alloca %string, align 8
    %cstr34240 = bitcast %string* %str33 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @6, i32 0, i32 0), i8** %cstr34240, align 8
    %length35 = getelementptr inbounds %string, %string* %str33, i32 0, i32 1
    store i64 2, i64* %length35, align 4
    %unbox36 = bitcast %string* %str33 to { i64, i64 }*
    %snd39 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox36, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @6 to i64), i64 2)
    br label %ifcont41
  
  ifcont41:                                         ; preds = %else32, %then23
    %4 = tail call i1 @false_()
    br i1 %4, label %true142, label %cont44
  
  true142:                                          ; preds = %ifcont41
    %5 = tail call i1 @true_()
    br i1 %5, label %true243, label %cont44
  
  true243:                                          ; preds = %true142
    br label %cont44
  
  cont44:                                           ; preds = %true243, %true142, %ifcont41
    %andtmp45 = phi i1 [ false, %ifcont41 ], [ false, %true142 ], [ true, %true243 ]
    br i1 %andtmp45, label %then46, label %else55
  
  then46:                                           ; preds = %cont44
    %str47 = alloca %string, align 8
    %cstr48242 = bitcast %string* %str47 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @7, i32 0, i32 0), i8** %cstr48242, align 8
    %length49 = getelementptr inbounds %string, %string* %str47, i32 0, i32 1
    store i64 3, i64* %length49, align 4
    %unbox50 = bitcast %string* %str47 to { i64, i64 }*
    %snd53 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox50, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @7 to i64), i64 3)
    br label %ifcont64
  
  else55:                                           ; preds = %cont44
    %str56 = alloca %string, align 8
    %cstr57244 = bitcast %string* %str56 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @8, i32 0, i32 0), i8** %cstr57244, align 8
    %length58 = getelementptr inbounds %string, %string* %str56, i32 0, i32 1
    store i64 2, i64* %length58, align 4
    %unbox59 = bitcast %string* %str56 to { i64, i64 }*
    %snd62 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox59, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @8 to i64), i64 2)
    br label %ifcont64
  
  ifcont64:                                         ; preds = %else55, %then46
    %6 = tail call i1 @false_()
    br i1 %6, label %true165, label %cont67
  
  true165:                                          ; preds = %ifcont64
    %7 = tail call i1 @false_()
    br i1 %7, label %true266, label %cont67
  
  true266:                                          ; preds = %true165
    br label %cont67
  
  cont67:                                           ; preds = %true266, %true165, %ifcont64
    %andtmp68 = phi i1 [ false, %ifcont64 ], [ false, %true165 ], [ true, %true266 ]
    br i1 %andtmp68, label %then69, label %else78
  
  then69:                                           ; preds = %cont67
    %str70 = alloca %string, align 8
    %cstr71246 = bitcast %string* %str70 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @9, i32 0, i32 0), i8** %cstr71246, align 8
    %length72 = getelementptr inbounds %string, %string* %str70, i32 0, i32 1
    store i64 3, i64* %length72, align 4
    %unbox73 = bitcast %string* %str70 to { i64, i64 }*
    %snd76 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox73, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @9 to i64), i64 3)
    br label %ifcont87
  
  else78:                                           ; preds = %cont67
    %str79 = alloca %string, align 8
    %cstr80248 = bitcast %string* %str79 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @10, i32 0, i32 0), i8** %cstr80248, align 8
    %length81 = getelementptr inbounds %string, %string* %str79, i32 0, i32 1
    store i64 2, i64* %length81, align 4
    %unbox82 = bitcast %string* %str79 to { i64, i64 }*
    %snd85 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox82, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @10 to i64), i64 2)
    br label %ifcont87
  
  ifcont87:                                         ; preds = %else78, %then69
    %str88 = alloca %string, align 8
    %cstr89250 = bitcast %string* %str88 to i8**
    store i8* getelementptr inbounds ([11 x i8], [11 x i8]* @11, i32 0, i32 0), i8** %cstr89250, align 8
    %length90 = getelementptr inbounds %string, %string* %str88, i32 0, i32 1
    store i64 10, i64* %length90, align 4
    %unbox91 = bitcast %string* %str88 to { i64, i64 }*
    %snd94 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox91, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([11 x i8]* @11 to i64), i64 10)
    %8 = tail call i1 @true_()
    br i1 %8, label %cont96, label %false1
  
  false1:                                           ; preds = %ifcont87
    %9 = tail call i1 @true_()
    br i1 %9, label %cont96, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont96
  
  cont96:                                           ; preds = %false2, %false1, %ifcont87
    %andtmp97 = phi i1 [ true, %ifcont87 ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp97, label %then98, label %else107
  
  then98:                                           ; preds = %cont96
    %str99 = alloca %string, align 8
    %cstr100252 = bitcast %string* %str99 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @12, i32 0, i32 0), i8** %cstr100252, align 8
    %length101 = getelementptr inbounds %string, %string* %str99, i32 0, i32 1
    store i64 3, i64* %length101, align 4
    %unbox102 = bitcast %string* %str99 to { i64, i64 }*
    %snd105 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox102, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @12 to i64), i64 3)
    br label %ifcont116
  
  else107:                                          ; preds = %cont96
    %str108 = alloca %string, align 8
    %cstr109254 = bitcast %string* %str108 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @13, i32 0, i32 0), i8** %cstr109254, align 8
    %length110 = getelementptr inbounds %string, %string* %str108, i32 0, i32 1
    store i64 2, i64* %length110, align 4
    %unbox111 = bitcast %string* %str108 to { i64, i64 }*
    %snd114 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox111, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @13 to i64), i64 2)
    br label %ifcont116
  
  ifcont116:                                        ; preds = %else107, %then98
    %10 = tail call i1 @true_()
    br i1 %10, label %cont119, label %false1117
  
  false1117:                                        ; preds = %ifcont116
    %11 = tail call i1 @false_()
    br i1 %11, label %cont119, label %false2118
  
  false2118:                                        ; preds = %false1117
    br label %cont119
  
  cont119:                                          ; preds = %false2118, %false1117, %ifcont116
    %andtmp120 = phi i1 [ true, %ifcont116 ], [ true, %false1117 ], [ false, %false2118 ]
    br i1 %andtmp120, label %then121, label %else130
  
  then121:                                          ; preds = %cont119
    %str122 = alloca %string, align 8
    %cstr123256 = bitcast %string* %str122 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @14, i32 0, i32 0), i8** %cstr123256, align 8
    %length124 = getelementptr inbounds %string, %string* %str122, i32 0, i32 1
    store i64 3, i64* %length124, align 4
    %unbox125 = bitcast %string* %str122 to { i64, i64 }*
    %snd128 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox125, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @14 to i64), i64 3)
    br label %ifcont139
  
  else130:                                          ; preds = %cont119
    %str131 = alloca %string, align 8
    %cstr132258 = bitcast %string* %str131 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @15, i32 0, i32 0), i8** %cstr132258, align 8
    %length133 = getelementptr inbounds %string, %string* %str131, i32 0, i32 1
    store i64 2, i64* %length133, align 4
    %unbox134 = bitcast %string* %str131 to { i64, i64 }*
    %snd137 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox134, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @15 to i64), i64 2)
    br label %ifcont139
  
  ifcont139:                                        ; preds = %else130, %then121
    %12 = tail call i1 @false_()
    br i1 %12, label %cont142, label %false1140
  
  false1140:                                        ; preds = %ifcont139
    %13 = tail call i1 @true_()
    br i1 %13, label %cont142, label %false2141
  
  false2141:                                        ; preds = %false1140
    br label %cont142
  
  cont142:                                          ; preds = %false2141, %false1140, %ifcont139
    %andtmp143 = phi i1 [ true, %ifcont139 ], [ true, %false1140 ], [ false, %false2141 ]
    br i1 %andtmp143, label %then144, label %else153
  
  then144:                                          ; preds = %cont142
    %str145 = alloca %string, align 8
    %cstr146260 = bitcast %string* %str145 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @16, i32 0, i32 0), i8** %cstr146260, align 8
    %length147 = getelementptr inbounds %string, %string* %str145, i32 0, i32 1
    store i64 3, i64* %length147, align 4
    %unbox148 = bitcast %string* %str145 to { i64, i64 }*
    %snd151 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox148, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @16 to i64), i64 3)
    br label %ifcont162
  
  else153:                                          ; preds = %cont142
    %str154 = alloca %string, align 8
    %cstr155262 = bitcast %string* %str154 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @17, i32 0, i32 0), i8** %cstr155262, align 8
    %length156 = getelementptr inbounds %string, %string* %str154, i32 0, i32 1
    store i64 2, i64* %length156, align 4
    %unbox157 = bitcast %string* %str154 to { i64, i64 }*
    %snd160 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox157, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @17 to i64), i64 2)
    br label %ifcont162
  
  ifcont162:                                        ; preds = %else153, %then144
    %14 = tail call i1 @false_()
    br i1 %14, label %cont165, label %false1163
  
  false1163:                                        ; preds = %ifcont162
    %15 = tail call i1 @false_()
    br i1 %15, label %cont165, label %false2164
  
  false2164:                                        ; preds = %false1163
    br label %cont165
  
  cont165:                                          ; preds = %false2164, %false1163, %ifcont162
    %andtmp166 = phi i1 [ true, %ifcont162 ], [ true, %false1163 ], [ false, %false2164 ]
    br i1 %andtmp166, label %then167, label %else176
  
  then167:                                          ; preds = %cont165
    %str168 = alloca %string, align 8
    %cstr169264 = bitcast %string* %str168 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @18, i32 0, i32 0), i8** %cstr169264, align 8
    %length170 = getelementptr inbounds %string, %string* %str168, i32 0, i32 1
    store i64 3, i64* %length170, align 4
    %unbox171 = bitcast %string* %str168 to { i64, i64 }*
    %snd174 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox171, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @18 to i64), i64 3)
    br label %ifcont185
  
  else176:                                          ; preds = %cont165
    %str177 = alloca %string, align 8
    %cstr178266 = bitcast %string* %str177 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @19, i32 0, i32 0), i8** %cstr178266, align 8
    %length179 = getelementptr inbounds %string, %string* %str177, i32 0, i32 1
    store i64 2, i64* %length179, align 4
    %unbox180 = bitcast %string* %str177 to { i64, i64 }*
    %snd183 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox180, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @19 to i64), i64 2)
    br label %ifcont185
  
  ifcont185:                                        ; preds = %else176, %then167
    %str186 = alloca %string, align 8
    %cstr187268 = bitcast %string* %str186 to i8**
    store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @20, i32 0, i32 0), i8** %cstr187268, align 8
    %length188 = getelementptr inbounds %string, %string* %str186, i32 0, i32 1
    store i64 11, i64* %length188, align 4
    %unbox189 = bitcast %string* %str186 to { i64, i64 }*
    %snd192 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox189, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([12 x i8]* @20 to i64), i64 11)
    %16 = tail call i1 @true_()
    %17 = xor i1 %16, true
    br i1 %17, label %then194, label %else203
  
  then194:                                          ; preds = %ifcont185
    %str195 = alloca %string, align 8
    %cstr196270 = bitcast %string* %str195 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @21, i32 0, i32 0), i8** %cstr196270, align 8
    %length197 = getelementptr inbounds %string, %string* %str195, i32 0, i32 1
    store i64 3, i64* %length197, align 4
    %unbox198 = bitcast %string* %str195 to { i64, i64 }*
    %snd201 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox198, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @21 to i64), i64 3)
    br label %ifcont212
  
  else203:                                          ; preds = %ifcont185
    %str204 = alloca %string, align 8
    %cstr205272 = bitcast %string* %str204 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @22, i32 0, i32 0), i8** %cstr205272, align 8
    %length206 = getelementptr inbounds %string, %string* %str204, i32 0, i32 1
    store i64 2, i64* %length206, align 4
    %unbox207 = bitcast %string* %str204 to { i64, i64 }*
    %snd210 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox207, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @22 to i64), i64 2)
    br label %ifcont212
  
  ifcont212:                                        ; preds = %else203, %then194
    %18 = tail call i1 @false_()
    %19 = xor i1 %18, true
    br i1 %19, label %then213, label %else222
  
  then213:                                          ; preds = %ifcont212
    %str214 = alloca %string, align 8
    %cstr215274 = bitcast %string* %str214 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @23, i32 0, i32 0), i8** %cstr215274, align 8
    %length216 = getelementptr inbounds %string, %string* %str214, i32 0, i32 1
    store i64 3, i64* %length216, align 4
    %unbox217 = bitcast %string* %str214 to { i64, i64 }*
    %snd220 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox217, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([4 x i8]* @23 to i64), i64 3)
    br label %ifcont231
  
  else222:                                          ; preds = %ifcont212
    %str223 = alloca %string, align 8
    %cstr224276 = bitcast %string* %str223 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @24, i32 0, i32 0), i8** %cstr224276, align 8
    %length225 = getelementptr inbounds %string, %string* %str223, i32 0, i32 1
    store i64 2, i64* %length225, align 4
    %unbox226 = bitcast %string* %str223 to { i64, i64 }*
    %snd229 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox226, i32 0, i32 1
    tail call void @ps(i64 ptrtoint ([3 x i8]* @24 to i64), i64 2)
    br label %ifcont231
  
  ifcont231:                                        ; preds = %else222, %then213
    ret i64 0
  }
  test 'and':
  true
  true
  yes
  true
  false
  no
  false
  no
  false
  no
  test 'or':
  true
  yes
  true
  yes
  false
  true
  yes
  false
  false
  no
  test 'not':
  true
  no
  false
  yes


  $ schmu -o out.o --dump-llvm unary_minus.smu && cc out.o stub.o && ./a.out
  unary_minus.smu:1:1: warning: Unused binding a
  1 | a = -1.0
      ^
  
  unary_minus.smu:2:1: warning: Unused binding a
  2 | a = -.1.0
      ^
  
  unary_minus.smu:3:1: warning: Unused binding a
  3 | a = - 1.0
      ^
  
  unary_minus.smu:4:1: warning: Unused binding a
  4 | a = -. 1.0
      ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 -2
  }
  [254]

Test unused binding warning
  $ schmu -o out.o unused.smu
  unused.smu:2:1: warning: Unused binding unused1
  2 | unused1 = 0
      ^^^^^^^
  
  unused.smu:5:1: warning: Unused binding unused2
  5 | unused2 = 0
      ^^^^^^^
  
  unused.smu:12:5: warning: Unused binding use_unused3
  12 | fun use_unused3()
           ^^^^^^^^^^^
  
  unused.smu:18:3: warning: Unused binding unused4
  18 |   unused4 = 0
         ^^^^^^^
  
  unused.smu:21:3: warning: Unused binding unused5
  21 |   unused5 = 0
         ^^^^^^^
  
  unused.smu:35:3: warning: Unused binding usedlater
  35 |   usedlater = 0
         ^^^^^^^^^
  
  unused.smu:49:3: warning: Unused binding usedlater
  49 |   usedlater = 0
         ^^^^^^^^^
  
