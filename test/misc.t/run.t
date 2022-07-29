Compile stubs
  $ cc -c stub.c

Test elif
  $ schmu --dump-llvm stub.o elseif.smu && ./elseif
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @assert(i1 %0)
  
  define i64 @schmu_test(i64 %n) {
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
    %0 = tail call i64 @schmu_test(i64 10)
    %eq = icmp eq i64 %0, 1
    tail call void @assert(i1 %eq)
    %1 = tail call i64 @schmu_test(i64 0)
    %eq1 = icmp eq i64 %1, 2
    tail call void @assert(i1 %eq1)
    %2 = tail call i64 @schmu_test(i64 1)
    %eq2 = icmp eq i64 %2, 3
    tail call void @assert(i1 %eq2)
    %3 = tail call i64 @schmu_test(i64 11)
    %eq3 = icmp eq i64 %3, 4
    tail call void @assert(i1 %eq3)
    ret i64 0
  }

Test simple typedef
  $ schmu --dump-llvm stub.o simple_typealias.smu && ./simple_typealias
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
  $ schmu --dump-llvm stub.o free_vector.smu && ./free_vector
  free_vector.smu:7:5: warning: Unused binding vec
  7 | val vec = ["hey", "young", "world"]
          ^^^
  
  free_vector.smu:8:5: warning: Unused binding vec
  8 | val vec = [x, {x = 2}, {x = 3}]
          ^^^
  
  free_vector.smu:48:5: warning: Unused binding vec
  48 | val vec = make_vec()
           ^^^
  
  free_vector.smu:51:5: warning: Unused binding normal
  51 | val normal = nest_fns()
           ^^^^^^
  
  free_vector.smu:55:5: warning: Unused binding nested
  55 | val nested = make_nested_vec()
           ^^^^^^
  
  free_vector.smu:56:5: warning: Unused binding nested
  56 | val nested = nest_allocs()
           ^^^^^^
  
  free_vector.smu:59:5: warning: Unused binding rec_of_vec
  59 | val rec_of_vec = { index = 12, vec = [1, 2]}
           ^^^^^^^^^^
  
  free_vector.smu:60:5: warning: Unused binding rec_of_vec
  60 | val rec_of_vec = record_of_vecs()
           ^^^^^^^^^^
  
  free_vector.smu:62:5: warning: Unused binding vec_of_rec
  62 | val vec_of_rec = [record_of_vecs(), record_of_vecs()]
           ^^^^^^^^^^
  
  free_vector.smu:63:5: warning: Unused binding vec_of_rec
  63 | val vec_of_rec = vec_of_records()
           ^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %vector_string = type { %string*, i64, i64 }
  %string = type { i8*, i64 }
  %vector_foo = type { %foo*, i64, i64 }
  %vector_vector_int = type { %vector_int*, i64, i64 }
  %vector_int = type { i64*, i64, i64 }
  %container = type { i64, %vector_int }
  %vector_container = type { %container*, i64, i64 }
  
  @x = constant %foo { i64 1 }
  @x__2 = internal constant %foo { i64 23 }
  @vec = global %vector_string zeroinitializer, align 16
  @vec__2 = global %vector_foo zeroinitializer, align 16
  @vec__3 = global %vector_foo zeroinitializer, align 16
  @normal = global %vector_foo zeroinitializer, align 16
  @nested = global %vector_vector_int zeroinitializer, align 16
  @nested__2 = global %vector_vector_int zeroinitializer, align 16
  @nested__3 = global %vector_vector_int zeroinitializer, align 16
  @rec_of_vec = global %container zeroinitializer, align 32
  @rec_of_vec__2 = global %container zeroinitializer, align 32
  @vec_of_rec = global %vector_container zeroinitializer, align 16
  @vec_of_rec__2 = global %vector_container zeroinitializer, align 16
  @0 = private unnamed_addr constant [4 x i8] c"hey\00", align 1
  @1 = private unnamed_addr constant [6 x i8] c"young\00", align 1
  @2 = private unnamed_addr constant [6 x i8] c"world\00", align 1
  
  define void @schmu_vec_of_records(%vector_container* %0) {
  entry:
    %1 = tail call i8* @malloc(i64 64)
    %2 = bitcast i8* %1 to %container*
    %data1 = bitcast %vector_container* %0 to %container**
    store %container* %2, %container** %data1, align 8
    tail call void @schmu_record_of_vecs(%container* %2)
    %3 = getelementptr %container, %container* %2, i64 1
    tail call void @schmu_record_of_vecs(%container* %3)
    %len = getelementptr inbounds %vector_container, %vector_container* %0, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_container, %vector_container* %0, i32 0, i32 2
    store i64 2, i64* %cap, align 4
    ret void
  }
  
  define void @schmu_record_of_vecs(%container* %0) {
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
  
  define void @schmu_nest_local() {
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
  
  define void @schmu_nest_allocs(%vector_vector_int* %0) {
  entry:
    tail call void @schmu_make_nested_vec(%vector_vector_int* %0)
    ret void
  }
  
  define void @schmu_make_nested_vec(%vector_vector_int* %0) {
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
  
  define void @schmu_nest_fns(%vector_foo* %0) {
  entry:
    tail call void @schmu_make_vec(%vector_foo* %0)
    ret void
  }
  
  define void @schmu_inner_parent_scope() {
  entry:
    %ret = alloca %vector_foo, align 8
    call void @schmu_make_vec(%vector_foo* %ret)
    %0 = bitcast %vector_foo* %ret to %foo**
    %1 = load %foo*, %foo** %0, align 8
    %2 = bitcast %foo* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define void @schmu_make_vec(%vector_foo* %0) {
  entry:
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to %foo*
    %data1 = bitcast %vector_foo* %0 to %foo**
    store %foo* %2, %foo** %data1, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* bitcast (%foo* @x__2 to i8*), i64 8, i1 false)
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
  
  define void @schmu_vec_inside() {
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
    store %string* %1, %string** getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 0), align 8
    %cstr45 = bitcast %string* %1 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr45, align 8
    %length = getelementptr inbounds %string, %string* %1, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %2 = getelementptr %string, %string* %1, i64 1
    %cstr146 = bitcast %string* %2 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @1, i32 0, i32 0), i8** %cstr146, align 8
    %length2 = getelementptr inbounds %string, %string* %2, i32 0, i32 1
    store i64 5, i64* %length2, align 4
    %3 = getelementptr %string, %string* %1, i64 2
    %cstr347 = bitcast %string* %3 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @2, i32 0, i32 0), i8** %cstr347, align 8
    %length4 = getelementptr inbounds %string, %string* %3, i32 0, i32 1
    store i64 5, i64* %length4, align 4
    store i64 3, i64* getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 1), align 4
    store i64 3, i64* getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 2), align 4
    %4 = tail call i8* @malloc(i64 24)
    %5 = bitcast i8* %4 to %foo*
    store %foo* %5, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @vec__2, i32 0, i32 0), align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* bitcast (%foo* @x to i8*), i64 8, i1 false)
    %6 = getelementptr %foo, %foo* %5, i64 1
    store %foo { i64 2 }, %foo* %6, align 4
    %7 = getelementptr %foo, %foo* %5, i64 2
    store %foo { i64 3 }, %foo* %7, align 4
    store i64 3, i64* getelementptr inbounds (%vector_foo, %vector_foo* @vec__2, i32 0, i32 1), align 4
    store i64 3, i64* getelementptr inbounds (%vector_foo, %vector_foo* @vec__2, i32 0, i32 2), align 4
    tail call void @schmu_make_vec(%vector_foo* @vec__3)
    tail call void @schmu_vec_inside()
    tail call void @schmu_inner_parent_scope()
    tail call void @schmu_nest_fns(%vector_foo* @normal)
    %8 = tail call i8* @malloc(i64 48)
    %9 = bitcast i8* %8 to %vector_int*
    store %vector_int* %9, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0), align 8
    %10 = tail call i8* @malloc(i64 16)
    %11 = bitcast i8* %10 to i64*
    %data48 = bitcast %vector_int* %9 to i64**
    store i64* %11, i64** %data48, align 8
    store i64 0, i64* %11, align 4
    %12 = getelementptr i64, i64* %11, i64 1
    store i64 1, i64* %12, align 4
    %len = getelementptr inbounds %vector_int, %vector_int* %9, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %9, i32 0, i32 2
    store i64 2, i64* %cap, align 4
    %13 = getelementptr %vector_int, %vector_int* %9, i64 1
    %14 = tail call i8* @malloc(i64 16)
    %15 = bitcast i8* %14 to i64*
    %data549 = bitcast %vector_int* %13 to i64**
    store i64* %15, i64** %data549, align 8
    store i64 2, i64* %15, align 4
    %16 = getelementptr i64, i64* %15, i64 1
    store i64 3, i64* %16, align 4
    %len6 = getelementptr inbounds %vector_int, %vector_int* %13, i32 0, i32 1
    store i64 2, i64* %len6, align 4
    %cap7 = getelementptr inbounds %vector_int, %vector_int* %13, i32 0, i32 2
    store i64 2, i64* %cap7, align 4
    store i64 2, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 1), align 4
    store i64 2, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 2), align 4
    %17 = load %vector_int*, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0), align 8
    %18 = bitcast %vector_int* %17 to i8*
    %19 = tail call i8* @realloc(i8* %18, i64 216)
    %20 = bitcast i8* %19 to %vector_int*
    store %vector_int* %20, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0), align 8
    tail call void @schmu_make_nested_vec(%vector_vector_int* @nested__2)
    tail call void @schmu_nest_allocs(%vector_vector_int* @nested__3)
    tail call void @schmu_nest_local()
    store i64 12, i64* getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 0), align 4
    %21 = tail call i8* @malloc(i64 16)
    %22 = bitcast i8* %21 to i64*
    store i64* %22, i64** getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 1, i32 0), align 8
    store i64 1, i64* %22, align 4
    %23 = getelementptr i64, i64* %22, i64 1
    store i64 2, i64* %23, align 4
    store i64 2, i64* getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 1, i32 1), align 4
    store i64 2, i64* getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 1, i32 2), align 4
    tail call void @schmu_record_of_vecs(%container* @rec_of_vec__2)
    %24 = tail call i8* @malloc(i64 64)
    %25 = bitcast i8* %24 to %container*
    store %container* %25, %container** getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 0), align 8
    tail call void @schmu_record_of_vecs(%container* %25)
    %26 = getelementptr %container, %container* %25, i64 1
    tail call void @schmu_record_of_vecs(%container* %26)
    store i64 2, i64* getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 1), align 4
    store i64 2, i64* getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 2), align 4
    tail call void @schmu_vec_of_records(%vector_container* @vec_of_rec__2)
    %27 = load %container*, %container** getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec__2, i32 0, i32 0), align 8
    %leni = load i64, i64* getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec__2, i32 0, i32 1), align 4
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    %scevgep40 = getelementptr %container, %container* %27, i64 0, i32 1, i32 0
    %scevgep4041 = bitcast i64** %scevgep40 to %container*
    br label %rec
  
  rec:                                              ; preds = %free, %entry
    %lsr.iv42 = phi %container* [ %scevgep43, %free ], [ %scevgep4041, %entry ]
    %28 = phi i64 [ %33, %free ], [ 0, %entry ]
    %29 = icmp slt i64 %28, %leni
    br i1 %29, label %free, label %cont
  
  free:                                             ; preds = %rec
    %30 = bitcast %container* %lsr.iv42 to i64**
    %31 = load i64*, i64** %30, align 8
    %32 = bitcast i64* %31 to i8*
    tail call void @free(i8* %32)
    %33 = add i64 %28, 1
    store i64 %33, i64* %cnt, align 4
    %scevgep43 = getelementptr %container, %container* %lsr.iv42, i64 1
    br label %rec
  
  cont:                                             ; preds = %rec
    %34 = bitcast %container* %27 to i8*
    tail call void @free(i8* %34)
    %35 = load %container*, %container** getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 0), align 8
    %leni8 = load i64, i64* getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 1), align 4
    %cnt9 = alloca i64, align 8
    store i64 0, i64* %cnt9, align 4
    %scevgep35 = getelementptr %container, %container* %35, i64 0, i32 1, i32 0
    %scevgep3536 = bitcast i64** %scevgep35 to %container*
    br label %rec10
  
  rec10:                                            ; preds = %free11, %cont
    %lsr.iv37 = phi %container* [ %scevgep38, %free11 ], [ %scevgep3536, %cont ]
    %36 = phi i64 [ %41, %free11 ], [ 0, %cont ]
    %37 = icmp slt i64 %36, %leni8
    br i1 %37, label %free11, label %cont12
  
  free11:                                           ; preds = %rec10
    %38 = bitcast %container* %lsr.iv37 to i64**
    %39 = load i64*, i64** %38, align 8
    %40 = bitcast i64* %39 to i8*
    tail call void @free(i8* %40)
    %41 = add i64 %36, 1
    store i64 %41, i64* %cnt9, align 4
    %scevgep38 = getelementptr %container, %container* %lsr.iv37, i64 1
    br label %rec10
  
  cont12:                                           ; preds = %rec10
    %42 = bitcast %container* %35 to i8*
    tail call void @free(i8* %42)
    %43 = load i64*, i64** getelementptr inbounds (%container, %container* @rec_of_vec__2, i32 0, i32 1, i32 0), align 8
    %44 = bitcast i64* %43 to i8*
    tail call void @free(i8* %44)
    %45 = load i64*, i64** getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 1, i32 0), align 8
    %46 = bitcast i64* %45 to i8*
    tail call void @free(i8* %46)
    %47 = load %vector_int*, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested__3, i32 0, i32 0), align 8
    %leni13 = load i64, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested__3, i32 0, i32 1), align 4
    %cnt14 = alloca i64, align 8
    store i64 0, i64* %cnt14, align 4
    br label %rec15
  
  rec15:                                            ; preds = %free16, %cont12
    %lsr.iv32 = phi %vector_int* [ %scevgep33, %free16 ], [ %47, %cont12 ]
    %48 = phi i64 [ %53, %free16 ], [ 0, %cont12 ]
    %49 = icmp slt i64 %48, %leni13
    br i1 %49, label %free16, label %cont17
  
  free16:                                           ; preds = %rec15
    %50 = bitcast %vector_int* %lsr.iv32 to i64**
    %51 = load i64*, i64** %50, align 8
    %52 = bitcast i64* %51 to i8*
    tail call void @free(i8* %52)
    %53 = add i64 %48, 1
    store i64 %53, i64* %cnt14, align 4
    %scevgep33 = getelementptr %vector_int, %vector_int* %lsr.iv32, i64 1
    br label %rec15
  
  cont17:                                           ; preds = %rec15
    %54 = bitcast %vector_int* %47 to i8*
    tail call void @free(i8* %54)
    %55 = load %vector_int*, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested__2, i32 0, i32 0), align 8
    %leni18 = load i64, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested__2, i32 0, i32 1), align 4
    %cnt19 = alloca i64, align 8
    store i64 0, i64* %cnt19, align 4
    br label %rec20
  
  rec20:                                            ; preds = %free21, %cont17
    %lsr.iv29 = phi %vector_int* [ %scevgep30, %free21 ], [ %55, %cont17 ]
    %56 = phi i64 [ %61, %free21 ], [ 0, %cont17 ]
    %57 = icmp slt i64 %56, %leni18
    br i1 %57, label %free21, label %cont22
  
  free21:                                           ; preds = %rec20
    %58 = bitcast %vector_int* %lsr.iv29 to i64**
    %59 = load i64*, i64** %58, align 8
    %60 = bitcast i64* %59 to i8*
    tail call void @free(i8* %60)
    %61 = add i64 %56, 1
    store i64 %61, i64* %cnt19, align 4
    %scevgep30 = getelementptr %vector_int, %vector_int* %lsr.iv29, i64 1
    br label %rec20
  
  cont22:                                           ; preds = %rec20
    %62 = bitcast %vector_int* %55 to i8*
    tail call void @free(i8* %62)
    %63 = load %vector_int*, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0), align 8
    %leni23 = load i64, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 1), align 4
    %cnt24 = alloca i64, align 8
    store i64 0, i64* %cnt24, align 4
    br label %rec25
  
  rec25:                                            ; preds = %free26, %cont22
    %lsr.iv = phi %vector_int* [ %scevgep, %free26 ], [ %63, %cont22 ]
    %64 = phi i64 [ %69, %free26 ], [ 0, %cont22 ]
    %65 = icmp slt i64 %64, %leni23
    br i1 %65, label %free26, label %cont27
  
  free26:                                           ; preds = %rec25
    %66 = bitcast %vector_int* %lsr.iv to i64**
    %67 = load i64*, i64** %66, align 8
    %68 = bitcast i64* %67 to i8*
    tail call void @free(i8* %68)
    %69 = add i64 %64, 1
    store i64 %69, i64* %cnt24, align 4
    %scevgep = getelementptr %vector_int, %vector_int* %lsr.iv, i64 1
    br label %rec25
  
  cont27:                                           ; preds = %rec25
    %70 = bitcast %vector_int* %63 to i8*
    tail call void @free(i8* %70)
    %71 = load %foo*, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @normal, i32 0, i32 0), align 8
    %72 = bitcast %foo* %71 to i8*
    tail call void @free(i8* %72)
    %73 = load %foo*, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @vec__3, i32 0, i32 0), align 8
    %74 = bitcast %foo* %73 to i8*
    tail call void @free(i8* %74)
    %75 = load %foo*, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @vec__2, i32 0, i32 0), align 8
    %76 = bitcast %foo* %75 to i8*
    tail call void @free(i8* %76)
    %77 = load %string*, %string** getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 0), align 8
    %78 = bitcast %string* %77 to i8*
    tail call void @free(i8* %78)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Test x86_64-linux-gnu ABI (parts of it, anyway)
  $ schmu --dump-llvm -c abi.smu
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
  
  declare void @subv3(%v3* %0, %v3* byval(%v3) %1)
  
  declare void @subi3(%i3* %0, %i3* byval(%i3) %1)
  
  declare void @subv4(%v4* %0, %v4* byval(%v4) %1)
  
  declare void @submixed4(%mixed4* %0, %mixed4* byval(%mixed4) %1)
  
  declare void @subtrailv2(%trailv2* %0, %trailv2* byval(%trailv2) %1)
  
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
  $ schmu --dump-llvm stub.o regression_issue_19.smu && ./regression_issue_19
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %v3 = type { double, double, double }
  
  define void @schmu_wrap(%v3* %0) {
  entry:
    %boxconst = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, %v3* %boxconst, align 8
    %ret = alloca %v3, align 8
    call void @schmu_v3_scale(%v3* %ret, %v3* %boxconst, double 1.500000e+00)
    %boxconst1 = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 2.000000e+00, double 3.000000e+00 }, %v3* %boxconst1, align 8
    %ret2 = alloca %v3, align 8
    call void @schmu_v3_scale(%v3* %ret2, %v3* %boxconst1, double 1.500000e+00)
    call void @schmu_v3_add(%v3* %0, %v3* %ret, %v3* %ret2)
    ret void
  }
  
  define void @schmu_v3_scale(%v3* %0, %v3* %v3, double %factor) {
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
  
  define void @schmu_v3_add(%v3* %0, %v3* %lhs, %v3* %rhs) {
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
    call void @schmu_wrap(%v3* %ret)
    ret i64 0
  }

Test 'and', 'or' and 'not'
  $ schmu --dump-llvm stub.o boolean_logic.smu && ./boolean_logic
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @0 = private unnamed_addr constant [6 x i8] c"false\00", align 1
  @1 = private unnamed_addr constant [5 x i8] c"true\00", align 1
  @2 = private unnamed_addr constant [12 x i8] c"test 'and':\00", align 1
  @3 = private unnamed_addr constant [4 x i8] c"yes\00", align 1
  @4 = private unnamed_addr constant [3 x i8] c"no\00", align 1
  @5 = private unnamed_addr constant [11 x i8] c"test 'or':\00", align 1
  @6 = private unnamed_addr constant [12 x i8] c"test 'not':\00", align 1
  
  declare void @puts(i8* %0)
  
  define i1 @schmu_false_() {
  entry:
    %str = alloca %string, align 8
    %cstr3 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @0, i32 0, i32 0), i8** %cstr3, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 5, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([6 x i8]* @0 to i64), i64 5)
    ret i1 false
  }
  
  define i1 @schmu_true_() {
  entry:
    %str = alloca %string, align 8
    %cstr3 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([5 x i8], [5 x i8]* @1, i32 0, i32 0), i8** %cstr3, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 4, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([5 x i8]* @1 to i64), i64 4)
    ret i1 true
  }
  
  define void @schmu_ps(i64 %0, i64 %1) {
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
    tail call void @schmu_ps(i64 ptrtoint ([12 x i8]* @2 to i64), i64 11)
    %0 = tail call i1 @schmu_true_()
    br i1 %0, label %true1, label %cont
  
  true1:                                            ; preds = %entry
    %1 = tail call i1 @schmu_true_()
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
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont
  
  else:                                             ; preds = %cont
    %str11 = alloca %string, align 8
    %cstr12236 = bitcast %string* %str11 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr12236, align 8
    %length13 = getelementptr inbounds %string, %string* %str11, i32 0, i32 1
    store i64 2, i64* %length13, align 4
    %unbox14 = bitcast %string* %str11 to { i64, i64 }*
    %snd17 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox14, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %2 = tail call i1 @schmu_true_()
    br i1 %2, label %true119, label %cont21
  
  true119:                                          ; preds = %ifcont
    %3 = tail call i1 @schmu_false_()
    br i1 %3, label %true220, label %cont21
  
  true220:                                          ; preds = %true119
    br label %cont21
  
  cont21:                                           ; preds = %true220, %true119, %ifcont
    %andtmp22 = phi i1 [ false, %ifcont ], [ false, %true119 ], [ true, %true220 ]
    br i1 %andtmp22, label %then23, label %else32
  
  then23:                                           ; preds = %cont21
    %str24 = alloca %string, align 8
    %cstr25238 = bitcast %string* %str24 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr25238, align 8
    %length26 = getelementptr inbounds %string, %string* %str24, i32 0, i32 1
    store i64 3, i64* %length26, align 4
    %unbox27 = bitcast %string* %str24 to { i64, i64 }*
    %snd30 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox27, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont41
  
  else32:                                           ; preds = %cont21
    %str33 = alloca %string, align 8
    %cstr34240 = bitcast %string* %str33 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr34240, align 8
    %length35 = getelementptr inbounds %string, %string* %str33, i32 0, i32 1
    store i64 2, i64* %length35, align 4
    %unbox36 = bitcast %string* %str33 to { i64, i64 }*
    %snd39 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox36, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont41
  
  ifcont41:                                         ; preds = %else32, %then23
    %4 = tail call i1 @schmu_false_()
    br i1 %4, label %true142, label %cont44
  
  true142:                                          ; preds = %ifcont41
    %5 = tail call i1 @schmu_true_()
    br i1 %5, label %true243, label %cont44
  
  true243:                                          ; preds = %true142
    br label %cont44
  
  cont44:                                           ; preds = %true243, %true142, %ifcont41
    %andtmp45 = phi i1 [ false, %ifcont41 ], [ false, %true142 ], [ true, %true243 ]
    br i1 %andtmp45, label %then46, label %else55
  
  then46:                                           ; preds = %cont44
    %str47 = alloca %string, align 8
    %cstr48242 = bitcast %string* %str47 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr48242, align 8
    %length49 = getelementptr inbounds %string, %string* %str47, i32 0, i32 1
    store i64 3, i64* %length49, align 4
    %unbox50 = bitcast %string* %str47 to { i64, i64 }*
    %snd53 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox50, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont64
  
  else55:                                           ; preds = %cont44
    %str56 = alloca %string, align 8
    %cstr57244 = bitcast %string* %str56 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr57244, align 8
    %length58 = getelementptr inbounds %string, %string* %str56, i32 0, i32 1
    store i64 2, i64* %length58, align 4
    %unbox59 = bitcast %string* %str56 to { i64, i64 }*
    %snd62 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox59, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont64
  
  ifcont64:                                         ; preds = %else55, %then46
    %6 = tail call i1 @schmu_false_()
    br i1 %6, label %true165, label %cont67
  
  true165:                                          ; preds = %ifcont64
    %7 = tail call i1 @schmu_false_()
    br i1 %7, label %true266, label %cont67
  
  true266:                                          ; preds = %true165
    br label %cont67
  
  cont67:                                           ; preds = %true266, %true165, %ifcont64
    %andtmp68 = phi i1 [ false, %ifcont64 ], [ false, %true165 ], [ true, %true266 ]
    br i1 %andtmp68, label %then69, label %else78
  
  then69:                                           ; preds = %cont67
    %str70 = alloca %string, align 8
    %cstr71246 = bitcast %string* %str70 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr71246, align 8
    %length72 = getelementptr inbounds %string, %string* %str70, i32 0, i32 1
    store i64 3, i64* %length72, align 4
    %unbox73 = bitcast %string* %str70 to { i64, i64 }*
    %snd76 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox73, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont87
  
  else78:                                           ; preds = %cont67
    %str79 = alloca %string, align 8
    %cstr80248 = bitcast %string* %str79 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr80248, align 8
    %length81 = getelementptr inbounds %string, %string* %str79, i32 0, i32 1
    store i64 2, i64* %length81, align 4
    %unbox82 = bitcast %string* %str79 to { i64, i64 }*
    %snd85 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox82, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont87
  
  ifcont87:                                         ; preds = %else78, %then69
    %str88 = alloca %string, align 8
    %cstr89250 = bitcast %string* %str88 to i8**
    store i8* getelementptr inbounds ([11 x i8], [11 x i8]* @5, i32 0, i32 0), i8** %cstr89250, align 8
    %length90 = getelementptr inbounds %string, %string* %str88, i32 0, i32 1
    store i64 10, i64* %length90, align 4
    %unbox91 = bitcast %string* %str88 to { i64, i64 }*
    %snd94 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox91, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([11 x i8]* @5 to i64), i64 10)
    %8 = tail call i1 @schmu_true_()
    br i1 %8, label %cont96, label %false1
  
  false1:                                           ; preds = %ifcont87
    %9 = tail call i1 @schmu_true_()
    br i1 %9, label %cont96, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont96
  
  cont96:                                           ; preds = %false2, %false1, %ifcont87
    %andtmp97 = phi i1 [ true, %ifcont87 ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp97, label %then98, label %else107
  
  then98:                                           ; preds = %cont96
    %str99 = alloca %string, align 8
    %cstr100252 = bitcast %string* %str99 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr100252, align 8
    %length101 = getelementptr inbounds %string, %string* %str99, i32 0, i32 1
    store i64 3, i64* %length101, align 4
    %unbox102 = bitcast %string* %str99 to { i64, i64 }*
    %snd105 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox102, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont116
  
  else107:                                          ; preds = %cont96
    %str108 = alloca %string, align 8
    %cstr109254 = bitcast %string* %str108 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr109254, align 8
    %length110 = getelementptr inbounds %string, %string* %str108, i32 0, i32 1
    store i64 2, i64* %length110, align 4
    %unbox111 = bitcast %string* %str108 to { i64, i64 }*
    %snd114 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox111, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont116
  
  ifcont116:                                        ; preds = %else107, %then98
    %10 = tail call i1 @schmu_true_()
    br i1 %10, label %cont119, label %false1117
  
  false1117:                                        ; preds = %ifcont116
    %11 = tail call i1 @schmu_false_()
    br i1 %11, label %cont119, label %false2118
  
  false2118:                                        ; preds = %false1117
    br label %cont119
  
  cont119:                                          ; preds = %false2118, %false1117, %ifcont116
    %andtmp120 = phi i1 [ true, %ifcont116 ], [ true, %false1117 ], [ false, %false2118 ]
    br i1 %andtmp120, label %then121, label %else130
  
  then121:                                          ; preds = %cont119
    %str122 = alloca %string, align 8
    %cstr123256 = bitcast %string* %str122 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr123256, align 8
    %length124 = getelementptr inbounds %string, %string* %str122, i32 0, i32 1
    store i64 3, i64* %length124, align 4
    %unbox125 = bitcast %string* %str122 to { i64, i64 }*
    %snd128 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox125, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont139
  
  else130:                                          ; preds = %cont119
    %str131 = alloca %string, align 8
    %cstr132258 = bitcast %string* %str131 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr132258, align 8
    %length133 = getelementptr inbounds %string, %string* %str131, i32 0, i32 1
    store i64 2, i64* %length133, align 4
    %unbox134 = bitcast %string* %str131 to { i64, i64 }*
    %snd137 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox134, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont139
  
  ifcont139:                                        ; preds = %else130, %then121
    %12 = tail call i1 @schmu_false_()
    br i1 %12, label %cont142, label %false1140
  
  false1140:                                        ; preds = %ifcont139
    %13 = tail call i1 @schmu_true_()
    br i1 %13, label %cont142, label %false2141
  
  false2141:                                        ; preds = %false1140
    br label %cont142
  
  cont142:                                          ; preds = %false2141, %false1140, %ifcont139
    %andtmp143 = phi i1 [ true, %ifcont139 ], [ true, %false1140 ], [ false, %false2141 ]
    br i1 %andtmp143, label %then144, label %else153
  
  then144:                                          ; preds = %cont142
    %str145 = alloca %string, align 8
    %cstr146260 = bitcast %string* %str145 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr146260, align 8
    %length147 = getelementptr inbounds %string, %string* %str145, i32 0, i32 1
    store i64 3, i64* %length147, align 4
    %unbox148 = bitcast %string* %str145 to { i64, i64 }*
    %snd151 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox148, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont162
  
  else153:                                          ; preds = %cont142
    %str154 = alloca %string, align 8
    %cstr155262 = bitcast %string* %str154 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr155262, align 8
    %length156 = getelementptr inbounds %string, %string* %str154, i32 0, i32 1
    store i64 2, i64* %length156, align 4
    %unbox157 = bitcast %string* %str154 to { i64, i64 }*
    %snd160 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox157, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont162
  
  ifcont162:                                        ; preds = %else153, %then144
    %14 = tail call i1 @schmu_false_()
    br i1 %14, label %cont165, label %false1163
  
  false1163:                                        ; preds = %ifcont162
    %15 = tail call i1 @schmu_false_()
    br i1 %15, label %cont165, label %false2164
  
  false2164:                                        ; preds = %false1163
    br label %cont165
  
  cont165:                                          ; preds = %false2164, %false1163, %ifcont162
    %andtmp166 = phi i1 [ true, %ifcont162 ], [ true, %false1163 ], [ false, %false2164 ]
    br i1 %andtmp166, label %then167, label %else176
  
  then167:                                          ; preds = %cont165
    %str168 = alloca %string, align 8
    %cstr169264 = bitcast %string* %str168 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr169264, align 8
    %length170 = getelementptr inbounds %string, %string* %str168, i32 0, i32 1
    store i64 3, i64* %length170, align 4
    %unbox171 = bitcast %string* %str168 to { i64, i64 }*
    %snd174 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox171, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont185
  
  else176:                                          ; preds = %cont165
    %str177 = alloca %string, align 8
    %cstr178266 = bitcast %string* %str177 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr178266, align 8
    %length179 = getelementptr inbounds %string, %string* %str177, i32 0, i32 1
    store i64 2, i64* %length179, align 4
    %unbox180 = bitcast %string* %str177 to { i64, i64 }*
    %snd183 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox180, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont185
  
  ifcont185:                                        ; preds = %else176, %then167
    %str186 = alloca %string, align 8
    %cstr187268 = bitcast %string* %str186 to i8**
    store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @6, i32 0, i32 0), i8** %cstr187268, align 8
    %length188 = getelementptr inbounds %string, %string* %str186, i32 0, i32 1
    store i64 11, i64* %length188, align 4
    %unbox189 = bitcast %string* %str186 to { i64, i64 }*
    %snd192 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox189, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([12 x i8]* @6 to i64), i64 11)
    %16 = tail call i1 @schmu_true_()
    %17 = xor i1 %16, true
    br i1 %17, label %then194, label %else203
  
  then194:                                          ; preds = %ifcont185
    %str195 = alloca %string, align 8
    %cstr196270 = bitcast %string* %str195 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr196270, align 8
    %length197 = getelementptr inbounds %string, %string* %str195, i32 0, i32 1
    store i64 3, i64* %length197, align 4
    %unbox198 = bitcast %string* %str195 to { i64, i64 }*
    %snd201 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox198, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont212
  
  else203:                                          ; preds = %ifcont185
    %str204 = alloca %string, align 8
    %cstr205272 = bitcast %string* %str204 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr205272, align 8
    %length206 = getelementptr inbounds %string, %string* %str204, i32 0, i32 1
    store i64 2, i64* %length206, align 4
    %unbox207 = bitcast %string* %str204 to { i64, i64 }*
    %snd210 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox207, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
    br label %ifcont212
  
  ifcont212:                                        ; preds = %else203, %then194
    %18 = tail call i1 @schmu_false_()
    %19 = xor i1 %18, true
    br i1 %19, label %then213, label %else222
  
  then213:                                          ; preds = %ifcont212
    %str214 = alloca %string, align 8
    %cstr215274 = bitcast %string* %str214 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr215274, align 8
    %length216 = getelementptr inbounds %string, %string* %str214, i32 0, i32 1
    store i64 3, i64* %length216, align 4
    %unbox217 = bitcast %string* %str214 to { i64, i64 }*
    %snd220 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox217, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([4 x i8]* @3 to i64), i64 3)
    br label %ifcont231
  
  else222:                                          ; preds = %ifcont212
    %str223 = alloca %string, align 8
    %cstr224276 = bitcast %string* %str223 to i8**
    store i8* getelementptr inbounds ([3 x i8], [3 x i8]* @4, i32 0, i32 0), i8** %cstr224276, align 8
    %length225 = getelementptr inbounds %string, %string* %str223, i32 0, i32 1
    store i64 2, i64* %length225, align 4
    %unbox226 = bitcast %string* %str223 to { i64, i64 }*
    %snd229 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox226, i32 0, i32 1
    tail call void @schmu_ps(i64 ptrtoint ([3 x i8]* @4 to i64), i64 2)
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


  $ schmu --dump-llvm stub.o unary_minus.smu && ./unary_minus
  unary_minus.smu:1:5: warning: Unused binding a
  1 | val a = -1.0
          ^
  
  unary_minus.smu:2:5: warning: Unused binding a
  2 | val a = -.1.0
          ^
  
  unary_minus.smu:3:5: warning: Unused binding a
  3 | val a = - 1.0
          ^
  
  unary_minus.smu:4:5: warning: Unused binding a
  4 | val a = -. 1.0
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @a = constant double -1.000000e+00
  @a__2 = constant double -1.000000e+00
  @a__3 = constant double -1.000000e+00
  @a__4 = constant double -1.000000e+00
  @a__5 = constant i64 -1
  @b = constant i64 -1
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 -2
  }
  [254]

Test unused binding warning
  $ schmu unused.smu stub.o
  unused.smu:2:5: warning: Unused binding unused1
  2 | val unused1 = 0
          ^^^^^^^
  
  unused.smu:5:5: warning: Unused binding unused2
  5 | val unused2 = 0
          ^^^^^^^
  
  unused.smu:12:5: warning: Unused binding use_unused3
  12 | fun use_unused3() =
           ^^^^^^^^^^^
  
  unused.smu:17:7: warning: Unused binding unused4
  17 |   val unused4 = 0
             ^^^^^^^
  
  unused.smu:20:7: warning: Unused binding unused5
  20 |   val unused5 = 0
             ^^^^^^^
  
  unused.smu:33:7: warning: Unused binding usedlater
  33 |   val usedlater = 0
             ^^^^^^^^^
  
  unused.smu:47:7: warning: Unused binding usedlater
  47 |   val usedlater = 0
             ^^^^^^^^^
  
Allow declaring a c function with a different name
  $ schmu stub.o cname_decl.smu && ./cname_decl
  
  42

Print error when using uppercase names for externals
  $ schmu stub.o cname_decl_wrong.smu
  cname_decl_wrong.smu:1:16: error: Functions must have lowercase names. Use the following form: 'external schmu_name : <type> = "CName"'
  
  1 | external Printi : int -> unit
               ^^^^^^
  
  [1]

We can have if without else
  $ schmu if_no_else.smu
  if_no_else.smu:3:1: error: A conditional without else branch should evaluato to type unit. Expected type unit but got type int
  3 | if true then 2
      ^^^^^^^^^^^^^^
  
  [1]

Tailcall loops
  $ schmu --dump-llvm stub.o regression_issue_26.smu && ./regression_issue_26
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @limit = constant i64 3
  @0 = private unnamed_addr constant [12 x i8] c"%i, %i, %i\0A\00", align 1
  @1 = private unnamed_addr constant [8 x i8] c"%i, %i\0A\00", align 1
  @2 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1, i64 %2, i64 %3)
  
  define void @schmu_nested__3(i64 %a, i64 %b, i64 %c) {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, i64* %0, align 4
    %1 = alloca i64, align 8
    store i64 %b, i64* %1, align 4
    %2 = alloca i64, align 8
    store i64 %c, i64* %2, align 4
    %str = alloca %string, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %then10, %else12, %entry
    %c3.ph = phi i64 [ %c, %entry ], [ 0, %then10 ], [ %add13, %else12 ]
    %b2.ph = phi i64 [ %b, %entry ], [ %add11, %then10 ], [ %b2, %else12 ]
    %a1.ph = phi i64 [ %a, %entry ], [ %a1, %then10 ], [ %a1, %else12 ]
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %then
    %b2 = phi i64 [ 0, %then ], [ %b2.ph, %rec.outer ]
    %a1 = phi i64 [ %add, %then ], [ %a1.ph, %rec.outer ]
    %eq = icmp eq i64 %b2, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %add = add i64 %a1, 1
    store i64 %add, i64* %0, align 4
    store i64 0, i64* %1, align 4
    store i64 %c3.ph, i64* %2, align 4
    br label %rec
  
  else:                                             ; preds = %rec
    %eq5 = icmp eq i64 %a1, 3
    br i1 %eq5, label %then6, label %else7
  
  then6:                                            ; preds = %else
    ret void
  
  else7:                                            ; preds = %else
    %eq9 = icmp eq i64 %c3.ph, 3
    br i1 %eq9, label %then10, label %else12
  
  then10:                                           ; preds = %else7
    store i64 %a1, i64* %0, align 4
    %add11 = add i64 %b2, 1
    store i64 %add11, i64* %1, align 4
    store i64 0, i64* %2, align 4
    br label %rec.outer
  
  else12:                                           ; preds = %else7
    %cstr18 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i8** %cstr18, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 11, i64* %length, align 4
    tail call void @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i64 %a1, i64 %b2, i64 %c3.ph)
    store i64 %a1, i64* %0, align 4
    store i64 %b2, i64* %1, align 4
    %add13 = add i64 %c3.ph, 1
    store i64 %add13, i64* %2, align 4
    br label %rec.outer
  }
  
  define void @schmu_nested__2(i64 %a, i64 %b, i64 %c) {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, i64* %0, align 4
    %1 = alloca i64, align 8
    store i64 %b, i64* %1, align 4
    %2 = alloca i64, align 8
    store i64 %c, i64* %2, align 4
    %str = alloca %string, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %then6, %else12, %entry
    %c3.ph = phi i64 [ %c, %entry ], [ 0, %then6 ], [ %add13, %else12 ]
    %b2.ph = phi i64 [ %b, %entry ], [ %add7, %then6 ], [ %b2, %else12 ]
    %a1.ph = phi i64 [ %a, %entry ], [ %a1, %then6 ], [ %a1, %else12 ]
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %then
    %b2 = phi i64 [ 0, %then ], [ %b2.ph, %rec.outer ]
    %a1 = phi i64 [ %add, %then ], [ %a1.ph, %rec.outer ]
    %eq = icmp eq i64 %b2, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %add = add i64 %a1, 1
    store i64 %add, i64* %0, align 4
    store i64 0, i64* %1, align 4
    store i64 %c3.ph, i64* %2, align 4
    br label %rec
  
  else:                                             ; preds = %rec
    %eq5 = icmp eq i64 %c3.ph, 3
    br i1 %eq5, label %then6, label %else8
  
  then6:                                            ; preds = %else
    store i64 %a1, i64* %0, align 4
    %add7 = add i64 %b2, 1
    store i64 %add7, i64* %1, align 4
    store i64 0, i64* %2, align 4
    br label %rec.outer
  
  else8:                                            ; preds = %else
    %eq10 = icmp eq i64 %a1, 3
    br i1 %eq10, label %then11, label %else12
  
  then11:                                           ; preds = %else8
    ret void
  
  else12:                                           ; preds = %else8
    %cstr19 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i8** %cstr19, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 11, i64* %length, align 4
    tail call void @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i64 %a1, i64 %b2, i64 %c3.ph)
    store i64 %a1, i64* %0, align 4
    store i64 %b2, i64* %1, align 4
    %add13 = add i64 %c3.ph, 1
    store i64 %add13, i64* %2, align 4
    br label %rec.outer
  }
  
  define void @schmu_nested(i64 %a, i64 %b) {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, i64* %0, align 4
    %1 = alloca i64, align 8
    store i64 %b, i64* %1, align 4
    %str = alloca %string, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %entry, %then
    %b2.ph = phi i64 [ %b, %entry ], [ 0, %then ]
    %a1.ph = phi i64 [ %a, %entry ], [ %add, %then ]
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %else6
    %b2 = phi i64 [ %add7, %else6 ], [ %b2.ph, %rec.outer ]
    %eq = icmp eq i64 %b2, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %add = add i64 %a1.ph, 1
    store i64 %add, i64* %0, align 4
    store i64 0, i64* %1, align 4
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq4 = icmp eq i64 %a1.ph, 3
    br i1 %eq4, label %then5, label %else6
  
  then5:                                            ; preds = %else
    ret void
  
  else6:                                            ; preds = %else
    %cstr11 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([8 x i8], [8 x i8]* @1, i32 0, i32 0), i8** %cstr11, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 7, i64* %length, align 4
    tail call void @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @1, i32 0, i32 0), i64 %a1.ph, i64 %b2, i64 0)
    store i64 %a1.ph, i64* %0, align 4
    %add7 = add i64 %b2, 1
    store i64 %add7, i64* %1, align 4
    br label %rec
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_nested(i64 0, i64 0)
    %str = alloca %string, align 8
    %cstr1 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([2 x i8], [2 x i8]* @2, i32 0, i32 0), i8** %cstr1, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 1, i64* %length, align 4
    tail call void @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @2, i32 0, i32 0), i64 0, i64 0, i64 0)
    tail call void @schmu_nested__2(i64 0, i64 0, i64 0)
    ret i64 0
  }
  0, 0
  0, 1
  0, 2
  1, 0
  1, 1
  1, 2
  2, 0
  2, 1
  2, 2
  
  0, 0, 0
  0, 0, 1
  0, 0, 2
  0, 1, 0
  0, 1, 1
  0, 1, 2
  0, 2, 0
  0, 2, 1
  0, 2, 2
  1, 0, 0
  1, 0, 1
  1, 0, 2
  1, 1, 0
  1, 1, 1
  1, 1, 2
  1, 2, 0
  1, 2, 1
  1, 2, 2
  2, 0, 0
  2, 0, 1
  2, 0, 2
  2, 1, 0
  2, 1, 1
  2, 1, 2
  2, 2, 0
  2, 2, 1
  2, 2, 2
