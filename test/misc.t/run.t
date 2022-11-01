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
  simple_typealias.smu:2:11: warning: Unused binding puts
  2 | (external puts (fun foo unit))
                ^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 0
  }

Allocate vectors on the heap and free them. Check with valgrind whenever something changes here.
Also mutable fields and 'realloc' builtin
  $ schmu --dump-llvm stub.o free_vector.smu && ./free_vector
  free_vector.smu:7:6: warning: Unused binding vec
  7 | (val vec ["hey" "young" "world"])
           ^^^
  
  free_vector.smu:8:6: warning: Unused binding vec
  8 | (val vec [x {:x 2} {:x 3}])
           ^^^
  
  free_vector.smu:48:6: warning: Unused binding vec
  48 | (val vec (make_vec))
            ^^^
  
  free_vector.smu:51:6: warning: Unused binding normal
  51 | (val normal (nest_fns))
            ^^^^^^
  
  free_vector.smu:55:6: warning: Unused binding nested
  55 | (val nested (make_nested_vec))
            ^^^^^^
  
  free_vector.smu:56:6: warning: Unused binding nested
  56 | (val nested (nest_allocs))
            ^^^^^^
  
  free_vector.smu:59:6: warning: Unused binding rec_of_vec
  59 | (val rec_of_vec {:index 12 :vec [1 2]})
            ^^^^^^^^^^
  
  free_vector.smu:60:6: warning: Unused binding rec_of_vec
  60 | (val rec_of_vec (record_of_vecs))
            ^^^^^^^^^^
  
  free_vector.smu:62:6: warning: Unused binding vec_of_rec
  62 | (val vec_of_rec [(record_of_vecs) (record_of_vecs)])
            ^^^^^^^^^^
  
  free_vector.smu:63:6: warning: Unused binding vec_of_rec
  63 | (val vec_of_rec (vec_of_records))
            ^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %vector_string = type { %owned_ptr_string, i64 }
  %owned_ptr_string = type { %string*, i64 }
  %string = type { i8*, i64 }
  %vector_foo = type { %owned_ptr_foo, i64 }
  %owned_ptr_foo = type { %foo*, i64 }
  %vector_vector_int = type { %owned_ptr_vector_int, i64 }
  %owned_ptr_vector_int = type { %vector_int*, i64 }
  %vector_int = type { %owned_ptr_int, i64 }
  %owned_ptr_int = type { i64*, i64 }
  %container = type { i64, %vector_int }
  %vector_container = type { %owned_ptr_container, i64 }
  %owned_ptr_container = type { %container*, i64 }
  
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
    %owned_ptr1 = bitcast %vector_container* %0 to %owned_ptr_container*
    %data2 = bitcast %owned_ptr_container* %owned_ptr1 to %container**
    store %container* %2, %container** %data2, align 8
    tail call void @schmu_record_of_vecs(%container* %2)
    %3 = getelementptr %container, %container* %2, i64 1
    tail call void @schmu_record_of_vecs(%container* %3)
    %len = getelementptr inbounds %owned_ptr_container, %owned_ptr_container* %owned_ptr1, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_container, %vector_container* %0, i32 0, i32 1
    store i64 2, i64* %cap, align 4
    ret void
  }
  
  define void @schmu_record_of_vecs(%container* %0) {
  entry:
    %1 = tail call i8* @malloc(i64 16)
    %2 = bitcast i8* %1 to i64*
    %vec = alloca %vector_int, align 8
    %owned_ptr2 = bitcast %vector_int* %vec to %owned_ptr_int*
    %data3 = bitcast %owned_ptr_int* %owned_ptr2 to i64**
    store i64* %2, i64** %data3, align 8
    store i64 1, i64* %2, align 4
    %3 = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %3, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr2, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 2, i64* %cap, align 4
    %index4 = bitcast %container* %0 to i64*
    store i64 1, i64* %index4, align 4
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
    %owned_ptr10 = bitcast %vector_vector_int* %vec to %owned_ptr_vector_int*
    %data11 = bitcast %owned_ptr_vector_int* %owned_ptr10 to %vector_int**
    store %vector_int* %1, %vector_int** %data11, align 8
    %2 = tail call i8* @malloc(i64 16)
    %3 = bitcast i8* %2 to i64*
    %owned_ptr112 = bitcast %vector_int* %1 to %owned_ptr_int*
    %data213 = bitcast %owned_ptr_int* %owned_ptr112 to i64**
    store i64* %3, i64** %data213, align 8
    store i64 0, i64* %3, align 4
    %4 = getelementptr i64, i64* %3, i64 1
    store i64 1, i64* %4, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr112, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %1, i32 0, i32 1
    store i64 2, i64* %cap, align 4
    %5 = getelementptr %vector_int, %vector_int* %1, i64 1
    %6 = tail call i8* @malloc(i64 16)
    %7 = bitcast i8* %6 to i64*
    %owned_ptr314 = bitcast %vector_int* %5 to %owned_ptr_int*
    %data415 = bitcast %owned_ptr_int* %owned_ptr314 to i64**
    store i64* %7, i64** %data415, align 8
    store i64 2, i64* %7, align 4
    %8 = getelementptr i64, i64* %7, i64 1
    store i64 3, i64* %8, align 4
    %len5 = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr314, i32 0, i32 1
    store i64 2, i64* %len5, align 4
    %cap6 = getelementptr inbounds %vector_int, %vector_int* %5, i32 0, i32 1
    store i64 2, i64* %cap6, align 4
    %len7 = getelementptr inbounds %owned_ptr_vector_int, %owned_ptr_vector_int* %owned_ptr10, i32 0, i32 1
    store i64 2, i64* %len7, align 4
    %cap8 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %vec, i32 0, i32 1
    store i64 2, i64* %cap8, align 4
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
    %owned_ptr9 = bitcast %vector_vector_int* %0 to %owned_ptr_vector_int*
    %data10 = bitcast %owned_ptr_vector_int* %owned_ptr9 to %vector_int**
    store %vector_int* %2, %vector_int** %data10, align 8
    %3 = tail call i8* @malloc(i64 16)
    %4 = bitcast i8* %3 to i64*
    %owned_ptr111 = bitcast %vector_int* %2 to %owned_ptr_int*
    %data212 = bitcast %owned_ptr_int* %owned_ptr111 to i64**
    store i64* %4, i64** %data212, align 8
    store i64 0, i64* %4, align 4
    %5 = getelementptr i64, i64* %4, i64 1
    store i64 1, i64* %5, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr111, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %2, i32 0, i32 1
    store i64 2, i64* %cap, align 4
    %6 = getelementptr %vector_int, %vector_int* %2, i64 1
    %7 = tail call i8* @malloc(i64 16)
    %8 = bitcast i8* %7 to i64*
    %owned_ptr313 = bitcast %vector_int* %6 to %owned_ptr_int*
    %data414 = bitcast %owned_ptr_int* %owned_ptr313 to i64**
    store i64* %8, i64** %data414, align 8
    store i64 2, i64* %8, align 4
    %9 = getelementptr i64, i64* %8, i64 1
    store i64 3, i64* %9, align 4
    %len5 = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr313, i32 0, i32 1
    store i64 2, i64* %len5, align 4
    %cap6 = getelementptr inbounds %vector_int, %vector_int* %6, i32 0, i32 1
    store i64 2, i64* %cap6, align 4
    %len7 = getelementptr inbounds %owned_ptr_vector_int, %owned_ptr_vector_int* %owned_ptr9, i32 0, i32 1
    store i64 2, i64* %len7, align 4
    %cap8 = getelementptr inbounds %vector_vector_int, %vector_vector_int* %0, i32 0, i32 1
    store i64 2, i64* %cap8, align 4
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
    %0 = bitcast %vector_foo* %ret to %owned_ptr_foo*
    %1 = bitcast %owned_ptr_foo* %0 to %foo**
    %2 = load %foo*, %foo** %1, align 8
    %3 = bitcast %foo* %2 to i8*
    call void @free(i8* %3)
    ret void
  }
  
  define void @schmu_make_vec(%vector_foo* %0) {
  entry:
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to %foo*
    %owned_ptr1 = bitcast %vector_foo* %0 to %owned_ptr_foo*
    %data2 = bitcast %owned_ptr_foo* %owned_ptr1 to %foo**
    store %foo* %2, %foo** %data2, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* bitcast (%foo* @x__2 to i8*), i64 8, i1 false)
    %3 = getelementptr %foo, %foo* %2, i64 1
    store %foo { i64 2 }, %foo* %3, align 4
    %4 = getelementptr %foo, %foo* %2, i64 2
    store %foo { i64 3 }, %foo* %4, align 4
    %len = getelementptr inbounds %owned_ptr_foo, %owned_ptr_foo* %owned_ptr1, i32 0, i32 1
    store i64 3, i64* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %0, i32 0, i32 1
    store i64 3, i64* %cap, align 4
    ret void
  }
  
  define void @schmu_vec_inside() {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to %foo*
    %vec = alloca %vector_foo, align 8
    %owned_ptr1 = bitcast %vector_foo* %vec to %owned_ptr_foo*
    %data2 = bitcast %owned_ptr_foo* %owned_ptr1 to %foo**
    store %foo* %1, %foo** %data2, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* bitcast (%foo* @x to i8*), i64 8, i1 false)
    %2 = getelementptr %foo, %foo* %1, i64 1
    store %foo { i64 2 }, %foo* %2, align 4
    %3 = getelementptr %foo, %foo* %1, i64 2
    store %foo { i64 3 }, %foo* %3, align 4
    %len = getelementptr inbounds %owned_ptr_foo, %owned_ptr_foo* %owned_ptr1, i32 0, i32 1
    store i64 3, i64* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 1
    store i64 3, i64* %cap, align 4
    %4 = tail call i8* @realloc(i8* %0, i64 72)
    %5 = bitcast i8* %4 to %foo*
    store %foo* %5, %foo** %data2, align 8
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
    store %string* %1, %string** getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 0, i32 0), align 8
    %cstr60 = bitcast %string* %1 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr60, align 8
    %length = getelementptr inbounds %string, %string* %1, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %2 = getelementptr %string, %string* %1, i64 1
    %cstr161 = bitcast %string* %2 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @1, i32 0, i32 0), i8** %cstr161, align 8
    %length2 = getelementptr inbounds %string, %string* %2, i32 0, i32 1
    store i64 5, i64* %length2, align 4
    %3 = getelementptr %string, %string* %1, i64 2
    %cstr362 = bitcast %string* %3 to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @2, i32 0, i32 0), i8** %cstr362, align 8
    %length4 = getelementptr inbounds %string, %string* %3, i32 0, i32 1
    store i64 5, i64* %length4, align 4
    store i64 3, i64* getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 0, i32 1), align 4
    store i64 3, i64* getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 1), align 4
    %4 = tail call i8* @malloc(i64 24)
    %5 = bitcast i8* %4 to %foo*
    store %foo* %5, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @vec__2, i32 0, i32 0, i32 0), align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* bitcast (%foo* @x to i8*), i64 8, i1 false)
    %6 = getelementptr %foo, %foo* %5, i64 1
    store %foo { i64 2 }, %foo* %6, align 4
    %7 = getelementptr %foo, %foo* %5, i64 2
    store %foo { i64 3 }, %foo* %7, align 4
    store i64 3, i64* getelementptr inbounds (%vector_foo, %vector_foo* @vec__2, i32 0, i32 0, i32 1), align 4
    store i64 3, i64* getelementptr inbounds (%vector_foo, %vector_foo* @vec__2, i32 0, i32 1), align 4
    tail call void @schmu_make_vec(%vector_foo* @vec__3)
    tail call void @schmu_vec_inside()
    tail call void @schmu_inner_parent_scope()
    tail call void @schmu_nest_fns(%vector_foo* @normal)
    %8 = tail call i8* @malloc(i64 48)
    %9 = bitcast i8* %8 to %vector_int*
    store %vector_int* %9, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0, i32 0), align 8
    %10 = tail call i8* @malloc(i64 16)
    %11 = bitcast i8* %10 to i64*
    %owned_ptr63 = bitcast %vector_int* %9 to %owned_ptr_int*
    %data64 = bitcast %owned_ptr_int* %owned_ptr63 to i64**
    store i64* %11, i64** %data64, align 8
    store i64 0, i64* %11, align 4
    %12 = getelementptr i64, i64* %11, i64 1
    store i64 1, i64* %12, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr63, i32 0, i32 1
    store i64 2, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %9, i32 0, i32 1
    store i64 2, i64* %cap, align 4
    %13 = getelementptr %vector_int, %vector_int* %9, i64 1
    %14 = tail call i8* @malloc(i64 16)
    %15 = bitcast i8* %14 to i64*
    %owned_ptr565 = bitcast %vector_int* %13 to %owned_ptr_int*
    %data666 = bitcast %owned_ptr_int* %owned_ptr565 to i64**
    store i64* %15, i64** %data666, align 8
    store i64 2, i64* %15, align 4
    %16 = getelementptr i64, i64* %15, i64 1
    store i64 3, i64* %16, align 4
    %len7 = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr565, i32 0, i32 1
    store i64 2, i64* %len7, align 4
    %cap8 = getelementptr inbounds %vector_int, %vector_int* %13, i32 0, i32 1
    store i64 2, i64* %cap8, align 4
    store i64 2, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0, i32 1), align 4
    store i64 2, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 1), align 4
    %17 = load %vector_int*, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0, i32 0), align 8
    %18 = bitcast %vector_int* %17 to i8*
    %19 = tail call i8* @realloc(i8* %18, i64 216)
    %20 = bitcast i8* %19 to %vector_int*
    store %vector_int* %20, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0, i32 0), align 8
    tail call void @schmu_make_nested_vec(%vector_vector_int* @nested__2)
    tail call void @schmu_nest_allocs(%vector_vector_int* @nested__3)
    tail call void @schmu_nest_local()
    store i64 12, i64* getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 0), align 4
    %21 = tail call i8* @malloc(i64 16)
    %22 = bitcast i8* %21 to i64*
    store i64* %22, i64** getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 1, i32 0, i32 0), align 8
    store i64 1, i64* %22, align 4
    %23 = getelementptr i64, i64* %22, i64 1
    store i64 2, i64* %23, align 4
    store i64 2, i64* getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 1, i32 0, i32 1), align 4
    store i64 2, i64* getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 1, i32 1), align 4
    tail call void @schmu_record_of_vecs(%container* @rec_of_vec__2)
    %24 = tail call i8* @malloc(i64 64)
    %25 = bitcast i8* %24 to %container*
    store %container* %25, %container** getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 0, i32 0), align 8
    tail call void @schmu_record_of_vecs(%container* %25)
    %26 = getelementptr %container, %container* %25, i64 1
    tail call void @schmu_record_of_vecs(%container* %26)
    store i64 2, i64* getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 0, i32 1), align 4
    store i64 2, i64* getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 1), align 4
    tail call void @schmu_vec_of_records(%vector_container* @vec_of_rec__2)
    %27 = load %container*, %container** getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec__2, i32 0, i32 0, i32 0), align 8
    %leni = load i64, i64* getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec__2, i32 0, i32 0, i32 1), align 4
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    %scevgep55 = getelementptr %container, %container* %27, i64 0, i32 1, i32 0, i32 0
    %scevgep5556 = bitcast i64** %scevgep55 to %container*
    br label %rec
  
  rec:                                              ; preds = %free, %entry
    %lsr.iv57 = phi %container* [ %scevgep58, %free ], [ %scevgep5556, %entry ]
    %28 = phi i64 [ %33, %free ], [ 0, %entry ]
    %29 = icmp slt i64 %28, %leni
    br i1 %29, label %free, label %cont
  
  free:                                             ; preds = %rec
    %30 = bitcast %container* %lsr.iv57 to i64**
    %31 = load i64*, i64** %30, align 8
    %32 = bitcast i64* %31 to i8*
    tail call void @free(i8* %32)
    %33 = add i64 %28, 1
    store i64 %33, i64* %cnt, align 4
    %scevgep58 = getelementptr %container, %container* %lsr.iv57, i64 1
    br label %rec
  
  cont:                                             ; preds = %rec
    %34 = bitcast %container* %27 to i8*
    tail call void @free(i8* %34)
    %35 = load %container*, %container** getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 0, i32 0), align 8
    %leni9 = load i64, i64* getelementptr inbounds (%vector_container, %vector_container* @vec_of_rec, i32 0, i32 0, i32 1), align 4
    %cnt10 = alloca i64, align 8
    store i64 0, i64* %cnt10, align 4
    %scevgep50 = getelementptr %container, %container* %35, i64 0, i32 1, i32 0, i32 0
    %scevgep5051 = bitcast i64** %scevgep50 to %container*
    br label %rec11
  
  rec11:                                            ; preds = %free12, %cont
    %lsr.iv52 = phi %container* [ %scevgep53, %free12 ], [ %scevgep5051, %cont ]
    %36 = phi i64 [ %41, %free12 ], [ 0, %cont ]
    %37 = icmp slt i64 %36, %leni9
    br i1 %37, label %free12, label %cont13
  
  free12:                                           ; preds = %rec11
    %38 = bitcast %container* %lsr.iv52 to i64**
    %39 = load i64*, i64** %38, align 8
    %40 = bitcast i64* %39 to i8*
    tail call void @free(i8* %40)
    %41 = add i64 %36, 1
    store i64 %41, i64* %cnt10, align 4
    %scevgep53 = getelementptr %container, %container* %lsr.iv52, i64 1
    br label %rec11
  
  cont13:                                           ; preds = %rec11
    %42 = bitcast %container* %35 to i8*
    tail call void @free(i8* %42)
    %43 = load i64*, i64** getelementptr inbounds (%container, %container* @rec_of_vec__2, i32 0, i32 1, i32 0, i32 0), align 8
    %44 = bitcast i64* %43 to i8*
    tail call void @free(i8* %44)
    %45 = load i64*, i64** getelementptr inbounds (%container, %container* @rec_of_vec, i32 0, i32 1, i32 0, i32 0), align 8
    %46 = bitcast i64* %45 to i8*
    tail call void @free(i8* %46)
    %47 = load %vector_int*, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested__3, i32 0, i32 0, i32 0), align 8
    %leni14 = load i64, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested__3, i32 0, i32 0, i32 1), align 4
    %cnt15 = alloca i64, align 8
    store i64 0, i64* %cnt15, align 4
    br label %rec16
  
  rec16:                                            ; preds = %free17, %cont13
    %lsr.iv47 = phi %vector_int* [ %scevgep48, %free17 ], [ %47, %cont13 ]
    %48 = phi i64 [ %53, %free17 ], [ 0, %cont13 ]
    %49 = icmp slt i64 %48, %leni14
    br i1 %49, label %free17, label %cont18
  
  free17:                                           ; preds = %rec16
    %50 = bitcast %vector_int* %lsr.iv47 to i64**
    %51 = load i64*, i64** %50, align 8
    %52 = bitcast i64* %51 to i8*
    tail call void @free(i8* %52)
    %53 = add i64 %48, 1
    store i64 %53, i64* %cnt15, align 4
    %scevgep48 = getelementptr %vector_int, %vector_int* %lsr.iv47, i64 1
    br label %rec16
  
  cont18:                                           ; preds = %rec16
    %54 = bitcast %vector_int* %47 to i8*
    tail call void @free(i8* %54)
    %55 = load %vector_int*, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested__2, i32 0, i32 0, i32 0), align 8
    %leni19 = load i64, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested__2, i32 0, i32 0, i32 1), align 4
    %cnt20 = alloca i64, align 8
    store i64 0, i64* %cnt20, align 4
    br label %rec21
  
  rec21:                                            ; preds = %free22, %cont18
    %lsr.iv44 = phi %vector_int* [ %scevgep45, %free22 ], [ %55, %cont18 ]
    %56 = phi i64 [ %61, %free22 ], [ 0, %cont18 ]
    %57 = icmp slt i64 %56, %leni19
    br i1 %57, label %free22, label %cont23
  
  free22:                                           ; preds = %rec21
    %58 = bitcast %vector_int* %lsr.iv44 to i64**
    %59 = load i64*, i64** %58, align 8
    %60 = bitcast i64* %59 to i8*
    tail call void @free(i8* %60)
    %61 = add i64 %56, 1
    store i64 %61, i64* %cnt20, align 4
    %scevgep45 = getelementptr %vector_int, %vector_int* %lsr.iv44, i64 1
    br label %rec21
  
  cont23:                                           ; preds = %rec21
    %62 = bitcast %vector_int* %55 to i8*
    tail call void @free(i8* %62)
    %63 = load %vector_int*, %vector_int** getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0, i32 0), align 8
    %leni24 = load i64, i64* getelementptr inbounds (%vector_vector_int, %vector_vector_int* @nested, i32 0, i32 0, i32 1), align 4
    %cnt25 = alloca i64, align 8
    store i64 0, i64* %cnt25, align 4
    br label %rec26
  
  rec26:                                            ; preds = %free27, %cont23
    %lsr.iv41 = phi %vector_int* [ %scevgep42, %free27 ], [ %63, %cont23 ]
    %64 = phi i64 [ %69, %free27 ], [ 0, %cont23 ]
    %65 = icmp slt i64 %64, %leni24
    br i1 %65, label %free27, label %cont28
  
  free27:                                           ; preds = %rec26
    %66 = bitcast %vector_int* %lsr.iv41 to i64**
    %67 = load i64*, i64** %66, align 8
    %68 = bitcast i64* %67 to i8*
    tail call void @free(i8* %68)
    %69 = add i64 %64, 1
    store i64 %69, i64* %cnt25, align 4
    %scevgep42 = getelementptr %vector_int, %vector_int* %lsr.iv41, i64 1
    br label %rec26
  
  cont28:                                           ; preds = %rec26
    %70 = bitcast %vector_int* %63 to i8*
    tail call void @free(i8* %70)
    %71 = load %foo*, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @normal, i32 0, i32 0, i32 0), align 8
    %72 = bitcast %foo* %71 to i8*
    tail call void @free(i8* %72)
    %73 = load %foo*, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @vec__3, i32 0, i32 0, i32 0), align 8
    %74 = bitcast %foo* %73 to i8*
    tail call void @free(i8* %74)
    %75 = load %foo*, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @vec__2, i32 0, i32 0, i32 0), align 8
    %76 = bitcast %foo* %75 to i8*
    tail call void @free(i8* %76)
    %77 = load %string*, %string** getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 0, i32 0), align 8
    %leni29 = load i64, i64* getelementptr inbounds (%vector_string, %vector_string* @vec, i32 0, i32 0, i32 1), align 4
    %cnt30 = alloca i64, align 8
    store i64 0, i64* %cnt30, align 4
    %scevgep = getelementptr %string, %string* %77, i64 0, i32 1
    %scevgep36 = bitcast i64* %scevgep to %string*
    br label %rec31
  
  rec31:                                            ; preds = %cont35, %cont28
    %lsr.iv = phi %string* [ %scevgep37, %cont35 ], [ %scevgep36, %cont28 ]
    %78 = phi i64 [ %85, %cont35 ], [ 0, %cont28 ]
    %79 = icmp slt i64 %78, %leni29
    br i1 %79, label %free32, label %cont33
  
  free32:                                           ; preds = %rec31
    %80 = bitcast %string* %lsr.iv to i64*
    %81 = load i64, i64* %80, align 4
    %owned = icmp slt i64 %81, 0
    br i1 %owned, label %free34, label %cont35
  
  cont33:                                           ; preds = %rec31
    %82 = bitcast %string* %77 to i8*
    tail call void @free(i8* %82)
    ret i64 0
  
  free34:                                           ; preds = %free32
    %83 = bitcast %string* %lsr.iv to i8**
    %scevgep39 = getelementptr i8*, i8** %83, i64 -1
    %84 = load i8*, i8** %scevgep39, align 8
    tail call void @free(i8* %84)
    br label %cont35
  
  cont35:                                           ; preds = %free34, %free32
    %85 = add i64 %78, 1
    store i64 %85, i64* %cnt30, align 4
    %scevgep37 = getelementptr %string, %string* %lsr.iv, i64 1
    br label %rec31
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
  %f2s = type { float, float }
  %f3s = type { float, float, float }
  
  declare { double, double } @subv2(double %0, double %1)
  
  declare { i64, i64 } @subi2(i64 %0, i64 %1)
  
  declare double @subv1(double %0)
  
  declare i64 @subi1(i64 %0)
  
  declare void @subv3(%v3* %0, %v3* byval(%v3) %1)
  
  declare void @subi3(%i3* %0, %i3* byval(%i3) %1)
  
  declare void @subv4(%v4* %0, %v4* byval(%v4) %1)
  
  declare void @submixed4(%mixed4* %0, %mixed4* byval(%mixed4) %1)
  
  declare void @subtrailv2(%trailv2* %0, %trailv2* byval(%trailv2) %1)
  
  declare <2 x float> @subf2s(<2 x float> %0)
  
  declare { <2 x float>, float } @subf3s(<2 x float> %0, float %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %boxconst = alloca %v2, align 8
    store %v2 { double 1.000000e+00, double 1.000000e+01 }, %v2* %boxconst, align 8
    %unbox = bitcast %v2* %boxconst to { double, double }*
    %fst41 = bitcast { double, double }* %unbox to double*
    %fst1 = load double, double* %fst41, align 8
    %snd = getelementptr inbounds { double, double }, { double, double }* %unbox, i32 0, i32 1
    %snd2 = load double, double* %snd, align 8
    %ret = alloca %v2, align 8
    %0 = tail call { double, double } @subv2(double %fst1, double %snd2)
    %box = bitcast %v2* %ret to { double, double }*
    store { double, double } %0, { double, double }* %box, align 8
    %boxconst4 = alloca %i2, align 8
    store %i2 { i64 1, i64 10 }, %i2* %boxconst4, align 4
    %unbox5 = bitcast %i2* %boxconst4 to { i64, i64 }*
    %fst642 = bitcast { i64, i64 }* %unbox5 to i64*
    %fst7 = load i64, i64* %fst642, align 4
    %snd8 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox5, i32 0, i32 1
    %snd9 = load i64, i64* %snd8, align 4
    %ret10 = alloca %i2, align 8
    %1 = tail call { i64, i64 } @subi2(i64 %fst7, i64 %snd9)
    %box11 = bitcast %i2* %ret10 to { i64, i64 }*
    store { i64, i64 } %1, { i64, i64 }* %box11, align 4
    %ret13 = alloca %v1, align 8
    %2 = tail call double @subv1(double 1.000000e+00)
    %box14 = bitcast %v1* %ret13 to double*
    store double %2, double* %box14, align 8
    %ret16 = alloca %i1, align 8
    %3 = tail call i64 @subi1(i64 1)
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
    %ret29 = alloca %f2s, align 8
    %4 = call <2 x float> @subf2s(<2 x float> <float 2.000000e+00, float 3.000000e+00>)
    %box30 = bitcast %f2s* %ret29 to <2 x float>*
    store <2 x float> %4, <2 x float>* %box30, align 8
    %boxconst32 = alloca %f3s, align 8
    store %f3s { float 2.000000e+00, float 3.000000e+00, float 5.000000e+00 }, %f3s* %boxconst32, align 4
    %unbox33 = bitcast %f3s* %boxconst32 to { <2 x float>, float }*
    %fst3443 = bitcast { <2 x float>, float }* %unbox33 to <2 x float>*
    %fst35 = load <2 x float>, <2 x float>* %fst3443, align 8
    %snd36 = getelementptr inbounds { <2 x float>, float }, { <2 x float>, float }* %unbox33, i32 0, i32 1
    %snd37 = load float, float* %snd36, align 4
    %ret38 = alloca %f3s, align 8
    %5 = call { <2 x float>, float } @subf3s(<2 x float> %fst35, float %snd37)
    %box39 = bitcast %f3s* %ret38 to { <2 x float>, float }*
    store { <2 x float>, float } %5, { <2 x float>, float }* %box39, align 8
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
  unary_minus.smu:1:6: warning: Unused binding a
  1 | (val a -1.0)
           ^
  
  unary_minus.smu:2:6: warning: Unused binding a
  2 | (val a -.1.0)
           ^
  
  unary_minus.smu:3:6: warning: Unused binding a
  3 | (val a - 1.0)
           ^
  
  unary_minus.smu:4:6: warning: Unused binding a
  4 | (val a -. 1.0)
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
  unused.smu:2:6: warning: Unused binding unused1
  2 | (val unused1 0)
           ^^^^^^^
  
  unused.smu:5:6: warning: Unused binding unused2
  5 | (val unused2 0)
           ^^^^^^^
  
  unused.smu:12:6: warning: Unused binding use_unused3
  12 | (fun use_unused3 []
            ^^^^^^^^^^^
  
  unused.smu:19:11: warning: Unused binding unused4
  19 |      (val unused4 0)
                 ^^^^^^^
  
  unused.smu:23:11: warning: Unused binding unused5
  23 |      (val unused5 0)
                 ^^^^^^^
  
  unused.smu:38:13: warning: Unused binding usedlater
  38 |        (val usedlater 0)
                   ^^^^^^^^^
  
  unused.smu:52:13: warning: Unused binding usedlater
  52 |        (val usedlater 0)
                   ^^^^^^^^^
  
Allow declaring a c function with a different name
  $ schmu stub.o cname_decl.smu && ./cname_decl
  
  42

We can have if without else
  $ schmu if_no_else.smu
  if_no_else.smu:2:2: error: A conditional without else branch should evaluato to type unit. Expected type unit but got type int
  2 | (if true 2)
       ^^^^^^^^^
  
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
    br label %rec.outer.outer
  
  rec.outer.outer:                                  ; preds = %then, %entry
    %.ph.ph = phi i64 [ 0, %then ], [ %b, %entry ]
    %.ph10.ph = phi i64 [ %add, %then ], [ %a, %entry ]
    %.ph11.ph = phi i64 [ %3, %then ], [ %c, %entry ]
    br label %rec.outer
  
  rec.outer:                                        ; preds = %rec.outer.outer, %then5
    %.ph = phi i64 [ %add6, %then5 ], [ %.ph.ph, %rec.outer.outer ]
    %.ph11 = phi i64 [ 0, %then5 ], [ %.ph11.ph, %rec.outer.outer ]
    %.ph12 = phi i64 [ %4, %then5 ], [ %.ph10.ph, %rec.outer.outer ]
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %else7
    %3 = phi i64 [ %add8, %else7 ], [ %.ph11, %rec.outer ]
    %4 = phi i64 [ %.ph10.ph, %else7 ], [ %.ph12, %rec.outer ]
    %eq = icmp eq i64 %.ph, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph10.ph, 1
    store i64 %add, i64* %0, align 4
    store i64 0, i64* %1, align 4
    br label %rec.outer.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %4, 3
    br i1 %eq1, label %then2, label %else3
  
  then2:                                            ; preds = %else
    ret void
  
  else3:                                            ; preds = %else
    %eq4 = icmp eq i64 %3, 3
    br i1 %eq4, label %then5, label %else7
  
  then5:                                            ; preds = %else3
    %add6 = add i64 %.ph, 1
    store i64 %add6, i64* %1, align 4
    store i64 0, i64* %2, align 4
    br label %rec.outer
  
  else7:                                            ; preds = %else3
    %cstr13 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i8** %cstr13, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 11, i64* %length, align 4
    tail call void @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i64 %.ph10.ph, i64 %.ph, i64 %3)
    %add8 = add i64 %3, 1
    store i64 %add8, i64* %2, align 4
    br label %rec
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
    br label %rec.outer.outer
  
  rec.outer.outer:                                  ; preds = %then, %entry
    %.ph.ph = phi i64 [ 0, %then ], [ %b, %entry ]
    %.ph11.ph = phi i64 [ %add, %then ], [ %a, %entry ]
    %.ph13.ph = phi i64 [ %4, %then ], [ %c, %entry ]
    br label %rec.outer
  
  rec.outer:                                        ; preds = %rec.outer.outer, %then2
    %.ph = phi i64 [ %add3, %then2 ], [ %.ph.ph, %rec.outer.outer ]
    %.ph12 = phi i64 [ %3, %then2 ], [ %.ph11.ph, %rec.outer.outer ]
    %.ph13 = phi i64 [ 0, %then2 ], [ %.ph13.ph, %rec.outer.outer ]
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %else7
    %3 = phi i64 [ %.ph11.ph, %else7 ], [ %.ph12, %rec.outer ]
    %4 = phi i64 [ %add8, %else7 ], [ %.ph13, %rec.outer ]
    %eq = icmp eq i64 %.ph, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph11.ph, 1
    store i64 %add, i64* %0, align 4
    store i64 0, i64* %1, align 4
    br label %rec.outer.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %4, 3
    br i1 %eq1, label %then2, label %else4
  
  then2:                                            ; preds = %else
    %add3 = add i64 %.ph, 1
    store i64 %add3, i64* %1, align 4
    store i64 0, i64* %2, align 4
    br label %rec.outer
  
  else4:                                            ; preds = %else
    %eq5 = icmp eq i64 %3, 3
    br i1 %eq5, label %then6, label %else7
  
  then6:                                            ; preds = %else4
    ret void
  
  else7:                                            ; preds = %else4
    %cstr14 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i8** %cstr14, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 11, i64* %length, align 4
    tail call void @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i64 %.ph11.ph, i64 %.ph, i64 %4)
    %add8 = add i64 %4, 1
    store i64 %add8, i64* %2, align 4
    br label %rec
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
    %.ph = phi i64 [ %a, %entry ], [ %add, %then ]
    %.ph6 = phi i64 [ %b, %entry ], [ 0, %then ]
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %else3
    %2 = phi i64 [ %add4, %else3 ], [ %.ph6, %rec.outer ]
    %eq = icmp eq i64 %2, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph, 1
    store i64 %add, i64* %0, align 4
    store i64 0, i64* %1, align 4
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %.ph, 3
    br i1 %eq1, label %then2, label %else3
  
  then2:                                            ; preds = %else
    ret void
  
  else3:                                            ; preds = %else
    %cstr7 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([8 x i8], [8 x i8]* @1, i32 0, i32 0), i8** %cstr7, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 7, i64* %length, align 4
    tail call void @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @1, i32 0, i32 0), i64 %.ph, i64 %2, i64 0)
    %add4 = add i64 %2, 1
    store i64 %add4, i64* %1, align 4
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

Make sure an if returns either Const or Const_ptr, but in a consistent way
  $ schmu -c --dump-llvm regression_issue_30.smu
  regression_issue_30.smu:8:6: warning: Unused binding calc_acc
  8 | (fun calc_acc [vel]
           ^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %v = type { double, double, double }
  
  @acc_force = internal constant double 1.000000e+02
  
  declare double @dot(%v* byval(%v) %0, %v* byval(%v) %1)
  
  declare void @norm(%v* %0, %v* byval(%v) %1)
  
  declare void @scale(%v* %0, %v* byval(%v) %1, double %2)
  
  declare i1 @maybe()
  
  define void @schmu_calc_acc(%v* %0, %v* %vel) {
  entry:
    %1 = tail call double @dot(%v* %vel, %v* %vel)
    %gt = fcmp ogt double %1, 1.000000e-01
    br i1 %gt, label %then, label %else
  
  then:                                             ; preds = %entry
    %ret = alloca %v, align 8
    call void @norm(%v* %ret, %v* %vel)
    br label %ifcont
  
  else:                                             ; preds = %entry
    %2 = alloca %v, align 8
    store %v { double 1.000000e+00, double 0.000000e+00, double 0.000000e+00 }, %v* %2, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi %v* [ %ret, %then ], [ %2, %else ]
    %3 = call i1 @maybe()
    br i1 %3, label %then1, label %else2
  
  then1:                                            ; preds = %ifcont
    call void @scale(%v* %0, %v* %iftmp, double 1.000000e+02)
    br label %ifcont6
  
  else2:                                            ; preds = %ifcont
    %4 = call i1 @maybe()
    br i1 %4, label %then3, label %else4
  
  then3:                                            ; preds = %else2
    call void @scale(%v* %0, %v* %iftmp, double -3.000000e+02)
    br label %ifcont6
  
  else4:                                            ; preds = %else2
    call void @scale(%v* %0, %v* %iftmp, double 1.000000e-01)
    br label %ifcont6
  
  ifcont6:                                          ; preds = %then3, %else4, %then1
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 0
  }

Piping for ctors and field accessors
  $ schmu stub.o --dump-llvm piping.smu && ./piping
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_int = type { i32, i64 }
  
  declare void @Printi(i64 %0)
  
  define i64 @schmu___fun1(%option_int* %x) {
  entry:
    %tag1 = bitcast %option_int* %x to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %x, i32 0, i32 1
    %0 = load i64, i64* %data, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu___fun0(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @schmu___fun0(i64 1)
    tail call void @Printi(i64 %0)
    %option = alloca %option_int, align 8
    %tag1 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag1, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 4
    %1 = call i64 @schmu___fun1(%option_int* %option)
    call void @Printi(i64 %1)
    call void @Printi(i64 1)
    ret i64 0
  }
  
  2
  1
  1

Function calls for known functions act as annotations to decide which ctor or record to use.
Prints nothing, just works
  $ schmu function_call_annot.smu

Ensure global are loadad correctly when passed to functions
  $ schmu --dump-llvm regression_load_global.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %bar = type { double, double, i64, double, double, float }
  
  @height = constant i64 720
  @world = global %bar zeroinitializer, align 32
  
  define void @schmu_wrap-seg() {
  entry:
    tail call void @schmu___g.u_get-seg_bar.u(%bar* @world)
    ret void
  }
  
  define void @schmu___g.u_get-seg_bar.u(%bar* %bar) {
  entry:
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store double 0.000000e+00, double* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 0), align 8
    store double 1.280000e+03, double* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 1), align 8
    store i64 10, i64* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 2), align 4
    store double 1.000000e-01, double* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 3), align 8
    store double 5.400000e+02, double* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 4), align 8
    store float 5.000000e+00, float* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 5), align 4
    tail call void @schmu_wrap-seg()
    ret i64 0
  }


  $ schmu --dump-llvm array_push.smu && ./array_push
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @a = global i64* null, align 8
  @b = global i64* null, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_in-fun() {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 2, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 2, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 10, i64* %data, align 4
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 4
    %2 = load i64*, i64** %arr, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %2)
    %size1 = getelementptr i64, i64* %2, i64 1
    %size2 = load i64, i64* %size1, align 4
    %cap3 = getelementptr i64, i64* %2, i64 2
    %cap4 = load i64, i64* %cap3, align 4
    %3 = icmp eq i64 %cap4, %size2
    br i1 %3, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %4 = call i64* @__ag.ag_reloc_ai.ai(i64** %arr)
    br label %merge
  
  grow:                                             ; preds = %entry
    %5 = call i64* @__ag.ag_grow_ai.ai(i64** %arr)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %6 = phi i64* [ %4, %keep ], [ %5, %grow ]
    %data5 = getelementptr i64, i64* %6, i64 3
    %7 = getelementptr i64, i64* %data5, i64 %size2
    store i64 30, i64* %7, align 4
    %size6 = getelementptr i64, i64* %6, i64 1
    %8 = add i64 %size2, 1
    store i64 %8, i64* %size6, align 4
    %9 = load i64*, i64** %arr, align 8
    %len = getelementptr i64, i64* %9, i64 1
    %10 = load i64, i64* %len, align 4
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %10)
    %11 = add i32 %fmtsize, 1
    %12 = sext i32 %11 to i64
    %13 = call i8* @malloc(i64 %12)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %13, i64 %12, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %10)
    %str = alloca %string, align 8
    %cstr23 = bitcast %string* %str to i8**
    store i8* %13, i8** %cstr23, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %14 = mul i64 %12, -1
    store i64 %14, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %15 = ptrtoint i8* %13 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %15, i64 %14)
    %16 = bitcast i64* %2 to i8*
    %sunkaddr = getelementptr i8, i8* %16, i64 8
    %17 = bitcast i8* %sunkaddr to i64*
    %18 = load i64, i64* %17, align 4
    %fmtsize10 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %18)
    %19 = add i32 %fmtsize10, 1
    %20 = sext i32 %19 to i64
    %21 = call i8* @malloc(i64 %20)
    %fmt11 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %21, i64 %20, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %18)
    %str12 = alloca %string, align 8
    %cstr1325 = bitcast %string* %str12 to i8**
    store i8* %21, i8** %cstr1325, align 8
    %length14 = getelementptr inbounds %string, %string* %str12, i32 0, i32 1
    %22 = mul i64 %20, -1
    store i64 %22, i64* %length14, align 4
    %unbox15 = bitcast %string* %str12 to { i64, i64 }*
    %23 = ptrtoint i8* %21 to i64
    %snd18 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox15, i32 0, i32 1
    call void @schmu_print(i64 %23, i64 %22)
    %owned = icmp slt i64 %14, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %merge
    call void @free(i8* %13)
    br label %cont
  
  cont:                                             ; preds = %free, %merge
    %owned22 = icmp slt i64 %22, 0
    br i1 %owned22, label %free20, label %cont21
  
  free20:                                           ; preds = %cont
    call void @free(i8* %21)
    br label %cont21
  
  cont21:                                           ; preds = %free20, %cont
    call void @__g.u_decr_rc_ai.u(i64* %2)
    %24 = load i64*, i64** %arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %24)
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
    %sz = getelementptr i64, i64* %0, i64 1
    %size = load i64, i64* %sz, align 4
    %data = getelementptr i64, i64* %0, i64 3
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 4
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %4 = load i64, i64* %cnt, align 4
    %5 = icmp slt i64 %4, %size
    br i1 %5, label %child, label %cont
  
  child:                                            ; preds = %rec
    %6 = getelementptr i64, i64* %data, i64 %4
    %7 = add i64 %4, 1
    store i64 %7, i64* %cnt, align 4
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast i64* %0 to i8*
    call void @free(i8* %8)
    br label %merge
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
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @a, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 2, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 2, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 10, i64* %data, align 4
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 4
    %2 = load i64*, i64** @a, align 8
    store i64* %2, i64** @a, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %2)
    store i64* %2, i64** @b, align 8
    %3 = load i64*, i64** @a, align 8
    %size1 = getelementptr i64, i64* %3, i64 1
    %size2 = load i64, i64* %size1, align 4
    %cap3 = getelementptr i64, i64* %3, i64 2
    %cap4 = load i64, i64* %cap3, align 4
    %4 = icmp eq i64 %cap4, %size2
    br i1 %4, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %5 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @a)
    br label %merge
  
  grow:                                             ; preds = %entry
    %6 = tail call i64* @__ag.ag_grow_ai.ai(i64** @a)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %7 = phi i64* [ %5, %keep ], [ %6, %grow ]
    %data5 = getelementptr i64, i64* %7, i64 3
    %8 = getelementptr i64, i64* %data5, i64 %size2
    store i64 30, i64* %8, align 4
    %size6 = getelementptr i64, i64* %7, i64 1
    %9 = add i64 %size2, 1
    store i64 %9, i64* %size6, align 4
    %10 = load i64*, i64** @a, align 8
    %len = getelementptr i64, i64* %10, i64 1
    %11 = load i64, i64* %len, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %11)
    %12 = add i32 %fmtsize, 1
    %13 = sext i32 %12 to i64
    %14 = tail call i8* @malloc(i64 %13)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %14, i64 %13, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %11)
    %str = alloca %string, align 8
    %cstr23 = bitcast %string* %str to i8**
    store i8* %14, i8** %cstr23, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %15 = mul i64 %13, -1
    store i64 %15, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %16 = ptrtoint i8* %14 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %16, i64 %15)
    %17 = load i64*, i64** @b, align 8
    %len9 = getelementptr i64, i64* %17, i64 1
    %18 = load i64, i64* %len9, align 4
    %fmtsize10 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %18)
    %19 = add i32 %fmtsize10, 1
    %20 = sext i32 %19 to i64
    %21 = tail call i8* @malloc(i64 %20)
    %fmt11 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %21, i64 %20, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %18)
    %str12 = alloca %string, align 8
    %cstr1325 = bitcast %string* %str12 to i8**
    store i8* %21, i8** %cstr1325, align 8
    %length14 = getelementptr inbounds %string, %string* %str12, i32 0, i32 1
    %22 = mul i64 %20, -1
    store i64 %22, i64* %length14, align 4
    %unbox15 = bitcast %string* %str12 to { i64, i64 }*
    %23 = ptrtoint i8* %21 to i64
    %snd18 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox15, i32 0, i32 1
    tail call void @schmu_print(i64 %23, i64 %22)
    tail call void @schmu_in-fun()
    %24 = load i64*, i64** @b, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %24)
    %25 = load i64*, i64** @a, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %25)
    %owned = icmp slt i64 %22, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %merge
    tail call void @free(i8* %21)
    br label %cont
  
  cont:                                             ; preds = %free, %merge
    %owned22 = icmp slt i64 %15, 0
    br i1 %owned22, label %free20, label %cont21
  
  free20:                                           ; preds = %cont
    tail call void @free(i8* %14)
    br label %cont21
  
  cont21:                                           ; preds = %free20, %cont
    ret i64 0
  }
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  3
  2
  3
  2
