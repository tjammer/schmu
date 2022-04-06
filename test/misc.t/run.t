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
    %eq = icmp eq i32 %n, 10
    br i1 %eq, label %ifcont8, label %else
  
  else:                                             ; preds = %entry
    %lt = icmp slt i32 %n, 1
    br i1 %lt, label %ifcont8, label %else2
  
  else2:                                            ; preds = %else
    %lt3 = icmp slt i32 %n, 10
    br i1 %lt3, label %ifcont8, label %else5
  
  else5:                                            ; preds = %else2
    br label %ifcont8
  
  ifcont8:                                          ; preds = %else, %else2, %else5, %entry
    %iftmp9 = phi i32 [ 1, %entry ], [ 2, %else ], [ 4, %else5 ], [ 3, %else2 ]
    ret i32 %iftmp9
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = tail call i32 @test(i32 10)
    %eq = icmp eq i32 %0, 1
    tail call void @assert(i1 %eq)
    %1 = tail call i32 @test(i32 0)
    %eq1 = icmp eq i32 %1, 2
    tail call void @assert(i1 %eq1)
    %2 = tail call i32 @test(i32 1)
    %eq2 = icmp eq i32 %2, 3
    tail call void @assert(i1 %eq2)
    %3 = tail call i32 @test(i32 11)
    %eq3 = icmp eq i32 %3, 4
    tail call void @assert(i1 %eq3)
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

Allocate vectors on the heap and free them. Check with valgrind whenever something changes here.
Also mutable fields and 'realloc' builtin
  $ schmu -dump-llvm free_vector.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_container = type { %container*, i32, i32 }
  %container = type { i32, %vector_int }
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
  
  define private void @vec_of_records(%vector_container* sret %0) {
  entry:
    %1 = tail call i8* @malloc(i32 48)
    %2 = bitcast i8* %1 to %container*
    %data1 = bitcast %vector_container* %0 to %container**
    store %container* %2, %container** %data1, align 8
    tail call void @record_of_vecs(%container* %2)
    %3 = getelementptr %container, %container* %2, i32 1
    tail call void @record_of_vecs(%container* %3)
    %len = getelementptr inbounds %vector_container, %vector_container* %0, i32 0, i32 1
    store i32 2, i32* %len, align 4
    %cap = getelementptr inbounds %vector_container, %vector_container* %0, i32 0, i32 2
    store i32 2, i32* %cap, align 4
    ret void
  }
  
  define private void @record_of_vecs(%container* sret %0) {
  entry:
    %1 = tail call i8* @malloc(i32 8)
    %2 = bitcast i8* %1 to i32*
    %vec = alloca %vector_int, align 8
    %data2 = bitcast %vector_int* %vec to i32**
    store i32* %2, i32** %data2, align 8
    store i32 1, i32* %2, align 4
    %3 = getelementptr i32, i32* %2, i32 1
    store i32 2, i32* %3, align 4
    %len = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i32 2, i32* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 2
    store i32 2, i32* %cap, align 4
    %index3 = bitcast %container* %0 to i32*
    store i32 1, i32* %index3, align 4
    %vec1 = getelementptr inbounds %container, %container* %0, i32 0, i32 1
    %4 = bitcast %vector_int* %vec1 to i8*
    %5 = bitcast %vector_int* %vec to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 16, i1 false)
    ret void
  }
  
  define private void @nest_local() {
  entry:
    %0 = tail call i8* @malloc(i32 32)
    %1 = bitcast i8* %0 to %vector_int*
    %vec = alloca %vector_vector_int, align 8
    %data9 = bitcast %vector_vector_int* %vec to %vector_int**
    store %vector_int* %1, %vector_int** %data9, align 8
    %2 = tail call i8* @malloc(i32 8)
    %3 = bitcast i8* %2 to i32*
    %data110 = bitcast %vector_int* %1 to i32**
    store i32* %3, i32** %data110, align 8
    store i32 0, i32* %3, align 4
    %4 = getelementptr i32, i32* %3, i32 1
    store i32 1, i32* %4, align 4
    %len = getelementptr inbounds %vector_int, %vector_int* %1, i32 0, i32 1
    store i32 2, i32* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %1, i32 0, i32 2
    store i32 2, i32* %cap, align 4
    %5 = getelementptr %vector_int, %vector_int* %1, i32 1
    %6 = tail call i8* @malloc(i32 8)
    %7 = bitcast i8* %6 to i32*
    %data211 = bitcast %vector_int* %5 to i32**
    store i32* %7, i32** %data211, align 8
    store i32 2, i32* %7, align 4
    %8 = getelementptr i32, i32* %7, i32 1
    store i32 3, i32* %8, align 4
    %len3 = getelementptr inbounds %vector_int, %vector_int* %5, i32 0, i32 1
    store i32 2, i32* %len3, align 4
    %cap4 = getelementptr inbounds %vector_int, %vector_int* %5, i32 0, i32 2
    store i32 2, i32* %cap4, align 4
    %len5 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec, i32 0, i32 1
    store i32 2, i32* %len5, align 4
    %cap6 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec, i32 0, i32 2
    store i32 2, i32* %cap6, align 4
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  rec:                                              ; preds = %free, %entry
    %lsr.iv = phi i8* [ %scevgep, %free ], [ %0, %entry ]
    %9 = phi i64 [ %14, %free ], [ 0, %entry ]
    %10 = icmp slt i64 %9, 2
    br i1 %10, label %free, label %cont
  
  free:                                             ; preds = %rec
    %11 = bitcast i8* %lsr.iv to i32**
    %12 = load i32*, i32** %11, align 8
    %13 = bitcast i32* %12 to i8*
    tail call void @free(i8* %13)
    %14 = add i64 %9, 1
    store i64 %14, i64* %cnt, align 4
    %scevgep = getelementptr i8, i8* %lsr.iv, i64 16
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
    store i32 1, i32* %5, align 4
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
    store i32 3, i32* %9, align 4
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
  
  define private void @vec_inside(i8* %0) {
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
    %6 = tail call i8* @realloc(i8* %1, i32 36)
    %7 = bitcast i8* %6 to %foo*
    store %foo* %7, %foo** %data4, align 8
    tail call void @free(i8* %6)
    ret void
  }
  
  declare i8* @malloc(i32 %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @free(i8* %0)
  
  declare i8* @realloc(i8* %0, i32 %1)
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %x82 = bitcast %foo* %0 to i32*
    store i32 1, i32* %x82, align 4
    %1 = tail call i8* @malloc(i32 48)
    %2 = bitcast i8* %1 to %string*
    %vec = alloca %vector_string, align 8
    %data83 = bitcast %vector_string* %vec to %string**
    store %string* %2, %string** %data83, align 8
    %cstr84 = bitcast %string* %2 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr84, align 8
    %length = getelementptr inbounds %string, %string* %2, i32 0, i32 1
    store i32 3, i32* %length, align 4
    %3 = getelementptr %string, %string* %2, i32 1
    %cstr185 = bitcast %string* %3 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @1, i32 0, i32 0), i8** %cstr185, align 8
    %length2 = getelementptr inbounds %string, %string* %3, i32 0, i32 1
    store i32 5, i32* %length2, align 4
    %4 = getelementptr %string, %string* %2, i32 2
    %cstr386 = bitcast %string* %4 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @2, i32 0, i32 0), i8** %cstr386, align 8
    %length4 = getelementptr inbounds %string, %string* %4, i32 0, i32 1
    store i32 5, i32* %length4, align 4
    %len = getelementptr inbounds %vector_string, %vector_string* %vec, i32 0, i32 1
    store i32 3, i32* %len, align 4
    %cap = getelementptr inbounds %vector_string, %vector_string* %vec, i32 0, i32 2
    store i32 3, i32* %cap, align 4
    %5 = tail call i8* @malloc(i32 12)
    %6 = bitcast i8* %5 to %foo*
    %vec5 = alloca %vector_foo, align 8
    %data687 = bitcast %vector_foo* %vec5 to %foo**
    store %foo* %6, %foo** %data687, align 8
    %7 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %7, i64 4, i1 false)
    %8 = getelementptr %foo, %foo* %6, i32 1
    %x788 = bitcast %foo* %8 to i32*
    store i32 2, i32* %x788, align 4
    %9 = getelementptr %foo, %foo* %6, i32 2
    %x889 = bitcast %foo* %9 to i32*
    store i32 3, i32* %x889, align 4
    %len9 = getelementptr inbounds %vector_foo, %vector_foo* %vec5, i32 0, i32 1
    store i32 3, i32* %len9, align 4
    %cap10 = getelementptr inbounds %vector_foo, %vector_foo* %vec5, i32 0, i32 2
    store i32 3, i32* %cap10, align 4
    %vec_inside = alloca %closure, align 8
    %funptr90 = bitcast %closure* %vec_inside to i8**
    store i8* bitcast (void (i8*)* @vec_inside to i8*), i8** %funptr90, align 8
    %clsr_vec_inside = alloca { %foo }, align 8
    %x1191 = bitcast { %foo }* %clsr_vec_inside to %foo*
    %10 = bitcast %foo* %x1191 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %7, i64 4, i1 false)
    %env = bitcast { %foo }* %clsr_vec_inside to i8*
    %envptr = getelementptr inbounds %closure, %closure* %vec_inside, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %ret = alloca %vector_foo, align 8
    call void @make_vec(%vector_foo* %ret)
    call void @vec_inside(i8* %env)
    call void @inner_parent_scope()
    %ret14 = alloca %vector_foo, align 8
    call void @nest_fns(%vector_foo* %ret14)
    %11 = call i8* @malloc(i32 32)
    %12 = bitcast i8* %11 to %vector_int*
    %vec15 = alloca %vector_vector_int, align 8
    %data1692 = bitcast %vector_vector_int* %vec15 to %vector_int**
    store %vector_int* %12, %vector_int** %data1692, align 8
    %13 = call i8* @malloc(i32 8)
    %14 = bitcast i8* %13 to i32*
    %data1793 = bitcast %vector_int* %12 to i32**
    store i32* %14, i32** %data1793, align 8
    store i32 0, i32* %14, align 4
    %15 = getelementptr i32, i32* %14, i32 1
    store i32 1, i32* %15, align 4
    %len18 = getelementptr inbounds %vector_int, %vector_int* %12, i32 0, i32 1
    store i32 2, i32* %len18, align 4
    %cap19 = getelementptr inbounds %vector_int, %vector_int* %12, i32 0, i32 2
    store i32 2, i32* %cap19, align 4
    %16 = getelementptr %vector_int, %vector_int* %12, i32 1
    %17 = call i8* @malloc(i32 8)
    %18 = bitcast i8* %17 to i32*
    %data2094 = bitcast %vector_int* %16 to i32**
    store i32* %18, i32** %data2094, align 8
    store i32 2, i32* %18, align 4
    %19 = getelementptr i32, i32* %18, i32 1
    store i32 3, i32* %19, align 4
    %len21 = getelementptr inbounds %vector_int, %vector_int* %16, i32 0, i32 1
    store i32 2, i32* %len21, align 4
    %cap22 = getelementptr inbounds %vector_int, %vector_int* %16, i32 0, i32 2
    store i32 2, i32* %cap22, align 4
    %len23 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec15, i32 0, i32 1
    store i32 2, i32* %len23, align 4
    %cap24 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec15, i32 0, i32 2
    store i32 2, i32* %cap24, align 4
    %20 = call i8* @realloc(i8* %11, i32 144)
    %21 = bitcast i8* %20 to %vector_int*
    store %vector_int* %21, %vector_int** %data1692, align 8
    %ret25 = alloca %vector_vector_int, align 8
    call void @make_nested_vec(%vector_vector_int* %ret25)
    %ret26 = alloca %vector_vector_int, align 8
    call void @nest_allocs(%vector_vector_int* %ret26)
    call void @nest_local()
    %22 = alloca %container, align 8
    %index95 = bitcast %container* %22 to i32*
    store i32 12, i32* %index95, align 4
    %vec27 = getelementptr inbounds %container, %container* %22, i32 0, i32 1
    %23 = call i8* @malloc(i32 8)
    %24 = bitcast i8* %23 to i32*
    %data2896 = bitcast %vector_int* %vec27 to i32**
    store i32* %24, i32** %data2896, align 8
    store i32 1, i32* %24, align 4
    %25 = getelementptr i32, i32* %24, i32 1
    store i32 2, i32* %25, align 4
    %len29 = getelementptr inbounds %vector_int, %vector_int* %vec27, i32 0, i32 1
    store i32 2, i32* %len29, align 4
    %cap30 = getelementptr inbounds %vector_int, %vector_int* %vec27, i32 0, i32 2
    store i32 2, i32* %cap30, align 4
    %ret31 = alloca %container, align 8
    call void @record_of_vecs(%container* %ret31)
    %26 = call i8* @malloc(i32 48)
    %27 = bitcast i8* %26 to %container*
    %vec32 = alloca %vector_container, align 8
    %data3397 = bitcast %vector_container* %vec32 to %container**
    store %container* %27, %container** %data3397, align 8
    call void @record_of_vecs(%container* %27)
    %28 = getelementptr %container, %container* %27, i32 1
    call void @record_of_vecs(%container* %28)
    %len34 = getelementptr inbounds %vector_container, %vector_container* %vec32, i32 0, i32 1
    store i32 2, i32* %len34, align 4
    %cap35 = getelementptr inbounds %vector_container, %vector_container* %vec32, i32 0, i32 2
    store i32 2, i32* %cap35, align 4
    %ret36 = alloca %vector_container, align 8
    call void @vec_of_records(%vector_container* %ret36)
    %29 = load %string*, %string** %data83, align 8
    %30 = bitcast %string* %29 to i8*
    call void @free(i8* %30)
    %31 = load %foo*, %foo** %data687, align 8
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
    %lsr.iv79 = phi i8* [ %scevgep80, %free ], [ %20, %entry ]
    %39 = phi i64 [ %44, %free ], [ 0, %entry ]
    %40 = icmp slt i64 %39, 2
    br i1 %40, label %free, label %cont
  
  free:                                             ; preds = %rec
    %41 = bitcast i8* %lsr.iv79 to i32**
    %42 = load i32*, i32** %41, align 8
    %43 = bitcast i32* %42 to i8*
    call void @free(i8* %43)
    %44 = add i64 %39, 1
    store i64 %44, i64* %cnt, align 4
    %scevgep80 = getelementptr i8, i8* %lsr.iv79, i64 16
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(i8* %20)
    %45 = bitcast %vector_vector_int* %ret25 to %vector_int**
    %46 = load %vector_int*, %vector_int** %45, align 8
    %lenptr38 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %ret25, i32 0, i32 1
    %leni39 = load i32, i32* %lenptr38, align 4
    %len40 = sext i32 %leni39 to i64
    %cnt41 = alloca i64, align 8
    store i64 0, i64* %cnt41, align 4
    br label %rec42
  
  rec42:                                            ; preds = %free43, %cont
    %lsr.iv76 = phi %vector_int* [ %scevgep77, %free43 ], [ %46, %cont ]
    %47 = phi i64 [ %52, %free43 ], [ 0, %cont ]
    %48 = icmp slt i64 %47, %len40
    br i1 %48, label %free43, label %cont44
  
  free43:                                           ; preds = %rec42
    %49 = bitcast %vector_int* %lsr.iv76 to i32**
    %50 = load i32*, i32** %49, align 8
    %51 = bitcast i32* %50 to i8*
    call void @free(i8* %51)
    %52 = add i64 %47, 1
    store i64 %52, i64* %cnt41, align 4
    %scevgep77 = getelementptr %vector_int, %vector_int* %lsr.iv76, i64 1
    br label %rec42
  
  cont44:                                           ; preds = %rec42
    %53 = bitcast %vector_int* %46 to i8*
    call void @free(i8* %53)
    %54 = bitcast %vector_vector_int* %ret26 to %vector_int**
    %55 = load %vector_int*, %vector_int** %54, align 8
    %lenptr45 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %ret26, i32 0, i32 1
    %leni46 = load i32, i32* %lenptr45, align 4
    %len47 = sext i32 %leni46 to i64
    %cnt48 = alloca i64, align 8
    store i64 0, i64* %cnt48, align 4
    br label %rec49
  
  rec49:                                            ; preds = %free50, %cont44
    %lsr.iv73 = phi %vector_int* [ %scevgep74, %free50 ], [ %55, %cont44 ]
    %56 = phi i64 [ %61, %free50 ], [ 0, %cont44 ]
    %57 = icmp slt i64 %56, %len47
    br i1 %57, label %free50, label %cont51
  
  free50:                                           ; preds = %rec49
    %58 = bitcast %vector_int* %lsr.iv73 to i32**
    %59 = load i32*, i32** %58, align 8
    %60 = bitcast i32* %59 to i8*
    call void @free(i8* %60)
    %61 = add i64 %56, 1
    store i64 %61, i64* %cnt48, align 4
    %scevgep74 = getelementptr %vector_int, %vector_int* %lsr.iv73, i64 1
    br label %rec49
  
  cont51:                                           ; preds = %rec49
    %62 = bitcast %vector_int* %55 to i8*
    call void @free(i8* %62)
    call void @free(i8* %23)
    %63 = getelementptr inbounds %container, %container* %ret31, i32 0, i32 1
    %64 = bitcast %vector_int* %63 to i32**
    %65 = load i32*, i32** %64, align 8
    %66 = bitcast i32* %65 to i8*
    call void @free(i8* %66)
    %cnt55 = alloca i64, align 8
    store i64 0, i64* %cnt55, align 4
    %scevgep69 = getelementptr i8, i8* %26, i64 8
    br label %rec56
  
  rec56:                                            ; preds = %free57, %cont51
    %lsr.iv70 = phi i8* [ %scevgep71, %free57 ], [ %scevgep69, %cont51 ]
    %67 = phi i64 [ %72, %free57 ], [ 0, %cont51 ]
    %68 = icmp slt i64 %67, 2
    br i1 %68, label %free57, label %cont58
  
  free57:                                           ; preds = %rec56
    %69 = bitcast i8* %lsr.iv70 to i32**
    %70 = load i32*, i32** %69, align 8
    %71 = bitcast i32* %70 to i8*
    call void @free(i8* %71)
    %72 = add i64 %67, 1
    store i64 %72, i64* %cnt55, align 4
    %scevgep71 = getelementptr i8, i8* %lsr.iv70, i64 24
    br label %rec56
  
  cont58:                                           ; preds = %rec56
    call void @free(i8* %26)
    %73 = bitcast %vector_container* %ret36 to %container**
    %74 = load %container*, %container** %73, align 8
    %lenptr59 = getelementptr inbounds %vector_container, %vector_container* %ret36, i32 0, i32 1
    %leni60 = load i32, i32* %lenptr59, align 4
    %len61 = sext i32 %leni60 to i64
    %cnt62 = alloca i64, align 8
    store i64 0, i64* %cnt62, align 4
    %scevgep = getelementptr %container, %container* %74, i64 0, i32 1, i32 0
    %scevgep66 = bitcast i32** %scevgep to %container*
    br label %rec63
  
  rec63:                                            ; preds = %free64, %cont58
    %lsr.iv = phi %container* [ %scevgep67, %free64 ], [ %scevgep66, %cont58 ]
    %75 = phi i64 [ %80, %free64 ], [ 0, %cont58 ]
    %76 = icmp slt i64 %75, %len61
    br i1 %76, label %free64, label %cont65
  
  free64:                                           ; preds = %rec63
    %77 = bitcast %container* %lsr.iv to i32**
    %78 = load i32*, i32** %77, align 8
    %79 = bitcast i32* %78 to i8*
    call void @free(i8* %79)
    %80 = add i64 %75, 1
    store i64 %80, i64* %cnt62, align 4
    %scevgep67 = getelementptr %container, %container* %lsr.iv, i64 1
    br label %rec63
  
  cont65:                                           ; preds = %rec63
    %81 = bitcast %container* %74 to i8*
    call void @free(i8* %81)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Test x86_64-linux-gnu ABI (parts of it, anyway)
  $ schmu -dump-llvm abi.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %i3 = type { i32, i32, i32 }
  %v2 = type { float, float }
  %i2 = type { i32, i32 }
  %v1 = type { float }
  %i1 = type { i32 }
  %v3 = type { float, float, float }
  %v4 = type { float, float, float, float }
  %mixed4 = type { float, float, float, i32 }
  %trailv2 = type { i32, i32, float, float }
  
  declare <2 x float> @subv2(<2 x float> %0)
  
  declare i64 @subi2(i64 %0)
  
  declare float @subv1(float %0)
  
  declare i32 @subi1(i32 %0)
  
  declare { <2 x float>, float } @subv3({ <2 x float>, float } %0)
  
  declare void @subi3(%i3* %0, %i3* %1)
  
  declare { <2 x float>, <2 x float> } @subv4({ <2 x float>, <2 x float> } %0)
  
  declare { <2 x float>, i64 } @submixed4({ <2 x float>, i64 } %0)
  
  declare { i64, <2 x float> } @subtrailv2({ i64, <2 x float> } %0)
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %v2, align 8
    %z54 = bitcast %v2* %0 to float*
    store float 1.000000e+00, float* %z54, align 4
    %y = getelementptr inbounds %v2, %v2* %0, i32 0, i32 1
    store float 1.000000e+01, float* %y, align 4
    %unbox = bitcast %v2* %0 to <2 x float>*
    %unbox1 = load <2 x float>, <2 x float>* %unbox, align 8
    %ret = alloca %v2, align 8
    %1 = tail call <2 x float> @subv2(<2 x float> %unbox1)
    %box = bitcast %v2* %ret to <2 x float>*
    store <2 x float> %1, <2 x float>* %box, align 8
    %2 = alloca %i2, align 8
    %x55 = bitcast %i2* %2 to i32*
    store i32 1, i32* %x55, align 4
    %y3 = getelementptr inbounds %i2, %i2* %2, i32 0, i32 1
    store i32 10, i32* %y3, align 4
    %unbox4 = bitcast %i2* %2 to i64*
    %unbox5 = load i64, i64* %unbox4, align 4
    %ret6 = alloca %i2, align 8
    %3 = tail call i64 @subi2(i64 %unbox5)
    %box7 = bitcast %i2* %ret6 to i64*
    store i64 %3, i64* %box7, align 4
    %4 = alloca %v1, align 8
    %z956 = bitcast %v1* %4 to float*
    store float 1.000000e+00, float* %z956, align 4
    %ret12 = alloca %v1, align 8
    %5 = tail call float @subv1(float 1.000000e+00)
    %box13 = bitcast %v1* %ret12 to float*
    store float %5, float* %box13, align 4
    %6 = alloca %i1, align 8
    %x1557 = bitcast %i1* %6 to i32*
    store i32 1, i32* %x1557, align 4
    %ret18 = alloca %i1, align 8
    %7 = tail call i32 @subi1(i32 1)
    %box19 = bitcast %i1* %ret18 to i32*
    store i32 %7, i32* %box19, align 4
    %8 = alloca %v3, align 8
    %x2158 = bitcast %v3* %8 to float*
    store float 1.000000e+00, float* %x2158, align 4
    %y22 = getelementptr inbounds %v3, %v3* %8, i32 0, i32 1
    store float 1.000000e+01, float* %y22, align 4
    %z23 = getelementptr inbounds %v3, %v3* %8, i32 0, i32 2
    store float 1.000000e+02, float* %z23, align 4
    %unbox24 = bitcast %v3* %8 to { <2 x float>, float }*
    %unbox25 = load { <2 x float>, float }, { <2 x float>, float }* %unbox24, align 8
    %ret26 = alloca %v3, align 8
    %9 = tail call { <2 x float>, float } @subv3({ <2 x float>, float } %unbox25)
    %box27 = bitcast %v3* %ret26 to { <2 x float>, float }*
    store { <2 x float>, float } %9, { <2 x float>, float }* %box27, align 8
    %10 = alloca %i3, align 8
    %w59 = bitcast %i3* %10 to i32*
    store i32 1, i32* %w59, align 4
    %y29 = getelementptr inbounds %i3, %i3* %10, i32 0, i32 1
    store i32 10, i32* %y29, align 4
    %z30 = getelementptr inbounds %i3, %i3* %10, i32 0, i32 2
    store i32 100, i32* %z30, align 4
    %ret31 = alloca %i3, align 8
    call void @subi3(%i3* %ret31, %i3* %10)
    %11 = alloca %v4, align 8
    %x3260 = bitcast %v4* %11 to float*
    store float 1.000000e+00, float* %x3260, align 4
    %y33 = getelementptr inbounds %v4, %v4* %11, i32 0, i32 1
    store float 1.000000e+01, float* %y33, align 4
    %z34 = getelementptr inbounds %v4, %v4* %11, i32 0, i32 2
    store float 1.000000e+02, float* %z34, align 4
    %w35 = getelementptr inbounds %v4, %v4* %11, i32 0, i32 3
    store float 1.000000e+03, float* %w35, align 4
    %unbox36 = bitcast %v4* %11 to { <2 x float>, <2 x float> }*
    %unbox37 = load { <2 x float>, <2 x float> }, { <2 x float>, <2 x float> }* %unbox36, align 8
    %ret38 = alloca %v4, align 8
    %12 = call { <2 x float>, <2 x float> } @subv4({ <2 x float>, <2 x float> } %unbox37)
    %box39 = bitcast %v4* %ret38 to { <2 x float>, <2 x float> }*
    store { <2 x float>, <2 x float> } %12, { <2 x float>, <2 x float> }* %box39, align 8
    %13 = alloca %mixed4, align 8
    %x4161 = bitcast %mixed4* %13 to float*
    store float 1.000000e+00, float* %x4161, align 4
    %y42 = getelementptr inbounds %mixed4, %mixed4* %13, i32 0, i32 1
    store float 1.000000e+01, float* %y42, align 4
    %z43 = getelementptr inbounds %mixed4, %mixed4* %13, i32 0, i32 2
    store float 1.000000e+02, float* %z43, align 4
    %k = getelementptr inbounds %mixed4, %mixed4* %13, i32 0, i32 3
    store i32 1, i32* %k, align 4
    %unbox44 = bitcast %mixed4* %13 to { <2 x float>, i64 }*
    %unbox45 = load { <2 x float>, i64 }, { <2 x float>, i64 }* %unbox44, align 8
    %ret46 = alloca %mixed4, align 8
    %14 = call { <2 x float>, i64 } @submixed4({ <2 x float>, i64 } %unbox45)
    %box47 = bitcast %mixed4* %ret46 to { <2 x float>, i64 }*
    store { <2 x float>, i64 } %14, { <2 x float>, i64 }* %box47, align 8
    %15 = alloca %trailv2, align 8
    %a62 = bitcast %trailv2* %15 to i32*
    store i32 1, i32* %a62, align 4
    %b = getelementptr inbounds %trailv2, %trailv2* %15, i32 0, i32 1
    store i32 2, i32* %b, align 4
    %c = getelementptr inbounds %trailv2, %trailv2* %15, i32 0, i32 2
    store float 1.000000e+00, float* %c, align 4
    %d = getelementptr inbounds %trailv2, %trailv2* %15, i32 0, i32 3
    store float 2.000000e+00, float* %d, align 4
    %unbox49 = bitcast %trailv2* %15 to { i64, <2 x float> }*
    %unbox50 = load { i64, <2 x float> }, { i64, <2 x float> }* %unbox49, align 8
    %ret51 = alloca %trailv2, align 8
    %16 = call { i64, <2 x float> } @subtrailv2({ i64, <2 x float> } %unbox50)
    %box52 = bitcast %trailv2* %ret51 to { i64, <2 x float> }*
    store { i64, <2 x float> } %16, { i64, <2 x float> }* %box52, align 8
    ret i32 0
  }
