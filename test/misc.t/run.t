Compile stubs
  $ cc -c stub.c
  $ ar rs libstub.a stub.o
  ar: creating libstub.a

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
  simple_typealias.smu:2.10-14: warning: Unused binding puts.
  
  2 | external puts : (foo) -> unit
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
  $ schmu --dump-llvm stub.o free_array.smu && valgrind -q --leak-check=yes --show-reachable=yes ./free_array
  free_array.smu:7.5-8: warning: Unused binding arr.
  
  7 | let arr = ["hey", "young", "world"]
          ^^^
  
  free_array.smu:8.5-8: warning: Unused binding arr.
  
  8 | let arr = [copy(x), {x = 2}, {x = 3}]
          ^^^
  
  free_array.smu:47.5-8: warning: Unused binding arr.
  
  47 | let arr = make_arr()
           ^^^
  
  free_array.smu:50.5-11: warning: Unused binding normal.
  
  50 | let normal = nest_fns()
           ^^^^^^
  
  free_array.smu:54.5-11: warning: Unused binding nested.
  
  54 | let nested = make_nested_arr()
           ^^^^^^
  
  free_array.smu:55.5-11: warning: Unused binding nested.
  
  55 | let nested = nest_allocs()
           ^^^^^^
  
  free_array.smu:58.5-15: warning: Unused binding rec_of_arr.
  
  58 | let rec_of_arr = {index = 12, arr = [1, 2]}
           ^^^^^^^^^^
  
  free_array.smu:59.5-15: warning: Unused binding rec_of_arr.
  
  59 | let rec_of_arr = record_of_arrs()
           ^^^^^^^^^^
  
  free_array.smu:61.5-15: warning: Unused binding arr_of_rec.
  
  61 | let arr_of_rec = [record_of_arrs(), record_of_arrs()]
           ^^^^^^^^^^
  
  free_array.smu:62.5-15: warning: Unused binding arr_of_rec.
  
  62 | let arr_of_rec = arr_of_records()
           ^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %container = type { i64, i64* }
  
  @schmu_x = constant %foo { i64 1 }
  @schmu_x__2 = internal constant %foo { i64 23 }
  @schmu_arr = global i8** null, align 8
  @schmu_arr__2 = global %foo* null, align 8
  @schmu_arr__3 = global %foo* null, align 8
  @schmu_normal = global %foo* null, align 8
  @schmu_nested = global i64** null, align 8
  @schmu_nested__2 = global i64** null, align 8
  @schmu_nested__3 = global i64** null, align 8
  @schmu_rec_of_arr = global %container zeroinitializer, align 8
  @schmu_rec_of_arr__2 = global %container zeroinitializer, align 8
  @schmu_arr_of_rec = global %container* null, align 8
  @schmu_arr_of_rec__2 = global %container* null, align 8
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"hey\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"young\00" }
  @2 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"world\00" }
  
  define linkonce_odr void @__array_push_aaiai.u(i64*** noalias %arr, i64* %value) {
  entry:
    %0 = load i64**, i64*** %arr, align 8
    %1 = bitcast i64** %0 to i64*
    %capacity = getelementptr i64, i64* %1, i64 1
    %2 = load i64, i64* %capacity, align 8
    %3 = load i64, i64* %1, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %then, label %ifcont7
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %2, 0
    br i1 %eq1, label %then2, label %else
  
  then2:                                            ; preds = %then
    %4 = bitcast i64** %0 to i8*
    %5 = tail call i8* @realloc(i8* %4, i64 48)
    %6 = bitcast i8* %5 to i64**
    store i64** %6, i64*** %arr, align 8
    %newcap = bitcast i64** %6 to i64*
    %newcap3 = getelementptr i64, i64* %newcap, i64 1
    store i64 4, i64* %newcap3, align 8
    br label %ifcont7
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %2
    %7 = mul i64 %mul, 8
    %8 = add i64 %7, 16
    %9 = bitcast i64** %0 to i8*
    %10 = tail call i8* @realloc(i8* %9, i64 %8)
    %11 = bitcast i8* %10 to i64**
    store i64** %11, i64*** %arr, align 8
    %newcap4 = bitcast i64** %11 to i64*
    %newcap5 = getelementptr i64, i64* %newcap4, i64 1
    store i64 %mul, i64* %newcap5, align 8
    br label %ifcont7
  
  ifcont7:                                          ; preds = %entry, %then2, %else
    %.pre-phi = phi i64* [ %newcap4, %else ], [ %newcap, %then2 ], [ %1, %entry ]
    %12 = phi i64** [ %11, %else ], [ %6, %then2 ], [ %0, %entry ]
    %13 = bitcast i64** %12 to i8*
    %14 = getelementptr i8, i8* %13, i64 16
    %data = bitcast i8* %14 to i64**
    %15 = getelementptr inbounds i64*, i64** %data, i64 %3
    store i64* %value, i64** %15, align 8
    %add = add i64 %3, 1
    store i64 %add, i64* %.pre-phi, align 8
    ret void
  }
  
  define linkonce_odr void @__array_push_afoofoo.u(%foo** noalias %arr, i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %1 = load %foo*, %foo** %arr, align 8
    %2 = bitcast %foo* %1 to i64*
    %capacity = getelementptr i64, i64* %2, i64 1
    %3 = load i64, i64* %capacity, align 8
    %4 = load i64, i64* %2, align 8
    %eq = icmp eq i64 %3, %4
    br i1 %eq, label %then, label %ifcont8
  
  then:                                             ; preds = %entry
    %eq2 = icmp eq i64 %3, 0
    br i1 %eq2, label %then3, label %else
  
  then3:                                            ; preds = %then
    %5 = bitcast %foo* %1 to i8*
    %6 = tail call i8* @realloc(i8* %5, i64 48)
    %7 = bitcast i8* %6 to %foo*
    store %foo* %7, %foo** %arr, align 8
    %newcap = bitcast %foo* %7 to i64*
    %newcap4 = getelementptr i64, i64* %newcap, i64 1
    store i64 4, i64* %newcap4, align 8
    br label %ifcont8
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %3
    %8 = mul i64 %mul, 8
    %9 = add i64 %8, 16
    %10 = bitcast %foo* %1 to i8*
    %11 = tail call i8* @realloc(i8* %10, i64 %9)
    %12 = bitcast i8* %11 to %foo*
    store %foo* %12, %foo** %arr, align 8
    %newcap5 = bitcast %foo* %12 to i64*
    %newcap6 = getelementptr i64, i64* %newcap5, i64 1
    store i64 %mul, i64* %newcap6, align 8
    br label %ifcont8
  
  ifcont8:                                          ; preds = %entry, %then3, %else
    %.pre-phi = phi i64* [ %newcap5, %else ], [ %newcap, %then3 ], [ %2, %entry ]
    %13 = phi %foo* [ %12, %else ], [ %7, %then3 ], [ %1, %entry ]
    %14 = bitcast i64* %box to %foo*
    %15 = bitcast %foo* %13 to i8*
    %16 = getelementptr i8, i8* %15, i64 16
    %data = bitcast i8* %16 to %foo*
    %17 = getelementptr inbounds %foo, %foo* %data, i64 %4
    %18 = bitcast %foo* %17 to i8*
    %19 = bitcast %foo* %14 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %18, i8* %19, i64 8, i1 false)
    %add = add i64 %4, 1
    store i64 %add, i64* %.pre-phi, align 8
    ret void
  }
  
  define void @schmu_arr_inside() {
  entry:
    %0 = alloca %foo*, align 8
    %1 = tail call i8* @malloc(i64 40)
    %2 = bitcast i8* %1 to %foo*
    store %foo* %2, %foo** %0, align 8
    %3 = bitcast %foo* %2 to i64*
    store i64 3, i64* %3, align 8
    %cap = getelementptr i64, i64* %3, i64 1
    store i64 3, i64* %cap, align 8
    %4 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %4 to %foo*
    store %foo { i64 1 }, %foo* %data, align 8
    %"1" = getelementptr %foo, %foo* %data, i64 1
    store %foo { i64 2 }, %foo* %"1", align 8
    %"2" = getelementptr %foo, %foo* %data, i64 2
    store %foo { i64 3 }, %foo* %"2", align 8
    call void @__array_push_afoofoo.u(%foo** %0, i64 12)
    call void @__free_afoo(%foo** %0)
    ret void
  }
  
  define %container* @schmu_arr_of_records() {
  entry:
    %0 = tail call i8* @malloc(i64 48)
    %1 = bitcast i8* %0 to %container*
    %arr = alloca %container*, align 8
    store %container* %1, %container** %arr, align 8
    %2 = bitcast %container* %1 to i64*
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to %container*
    %4 = tail call { i64, i64 } @schmu_record_of_arrs()
    %box = bitcast %container* %data to { i64, i64 }*
    store { i64, i64 } %4, { i64, i64 }* %box, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %3, i64 16, i1 false)
    %"1" = getelementptr %container, %container* %data, i64 1
    %5 = tail call { i64, i64 } @schmu_record_of_arrs()
    %box2 = bitcast %container* %"1" to { i64, i64 }*
    store { i64, i64 } %5, { i64, i64 }* %box2, align 8
    %6 = bitcast %container* %"1" to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %6, i64 16, i1 false)
    ret %container* %1
  }
  
  define void @schmu_inner_parent_scope() {
  entry:
    %0 = tail call %foo* @schmu_make_arr()
    %1 = alloca %foo*, align 8
    store %foo* %0, %foo** %1, align 8
    call void @__free_afoo(%foo** %1)
    ret void
  }
  
  define %foo* @schmu_make_arr() {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to %foo*
    %arr = alloca %foo*, align 8
    store %foo* %1, %foo** %arr, align 8
    %2 = bitcast %foo* %1 to i64*
    store i64 3, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 3, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to %foo*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* bitcast (%foo* @schmu_x__2 to i8*), i64 8, i1 false)
    %"1" = getelementptr %foo, %foo* %data, i64 1
    store %foo { i64 2 }, %foo* %"1", align 8
    %"2" = getelementptr %foo, %foo* %data, i64 2
    store %foo { i64 3 }, %foo* %"2", align 8
    ret %foo* %1
  }
  
  define i64** @schmu_make_nested_arr() {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64**
    %arr = alloca i64**, align 8
    store i64** %1, i64*** %arr, align 8
    %2 = bitcast i64** %1 to i64*
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to i64**
    %4 = tail call i8* @malloc(i64 32)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %data, align 8
    store i64 2, i64* %5, align 8
    %cap2 = getelementptr i64, i64* %5, i64 1
    store i64 2, i64* %cap2, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data3 = bitcast i8* %6 to i64*
    store i64 0, i64* %data3, align 8
    %"1" = getelementptr i64, i64* %data3, i64 1
    store i64 1, i64* %"1", align 8
    %"15" = getelementptr i64*, i64** %data, i64 1
    %7 = tail call i8* @malloc(i64 32)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %"15", align 8
    store i64 2, i64* %8, align 8
    %cap7 = getelementptr i64, i64* %8, i64 1
    store i64 2, i64* %cap7, align 8
    %9 = getelementptr i8, i8* %7, i64 16
    %data8 = bitcast i8* %9 to i64*
    store i64 2, i64* %data8, align 8
    %"110" = getelementptr i64, i64* %data8, i64 1
    store i64 3, i64* %"110", align 8
    ret i64** %1
  }
  
  define i64** @schmu_nest_allocs() {
  entry:
    %0 = tail call i64** @schmu_make_nested_arr()
    ret i64** %0
  }
  
  define %foo* @schmu_nest_fns() {
  entry:
    %0 = tail call %foo* @schmu_make_arr()
    ret %foo* %0
  }
  
  define void @schmu_nest_local() {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64**
    %arr = alloca i64**, align 8
    store i64** %1, i64*** %arr, align 8
    %2 = bitcast i64** %1 to i64*
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to i64**
    %4 = tail call i8* @malloc(i64 32)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %data, align 8
    store i64 2, i64* %5, align 8
    %cap2 = getelementptr i64, i64* %5, i64 1
    store i64 2, i64* %cap2, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data3 = bitcast i8* %6 to i64*
    store i64 0, i64* %data3, align 8
    %"1" = getelementptr i64, i64* %data3, i64 1
    store i64 1, i64* %"1", align 8
    %"15" = getelementptr i64*, i64** %data, i64 1
    %7 = tail call i8* @malloc(i64 32)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %"15", align 8
    store i64 2, i64* %8, align 8
    %cap7 = getelementptr i64, i64* %8, i64 1
    store i64 2, i64* %cap7, align 8
    %9 = getelementptr i8, i8* %7, i64 16
    %data8 = bitcast i8* %9 to i64*
    store i64 2, i64* %data8, align 8
    %"110" = getelementptr i64, i64* %data8, i64 1
    store i64 3, i64* %"110", align 8
    call void @__free_aai(i64*** %arr)
    ret void
  }
  
  define { i64, i64 } @schmu_record_of_arrs() {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 2, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 2, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 1, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 2, i64* %"1", align 8
    %3 = alloca %container, align 8
    %index3 = bitcast %container* %3 to i64*
    store i64 1, i64* %index3, align 8
    %arr1 = getelementptr inbounds %container, %container* %3, i32 0, i32 1
    store i64* %1, i64** %arr1, align 8
    %unbox = bitcast %container* %3 to { i64, i64 }*
    %unbox2 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox2
  }
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__free_afoo(%foo** %0) {
  entry:
    %1 = load %foo*, %foo** %0, align 8
    %ref = bitcast %foo* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast i64** %1 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data = bitcast i8* %5 to i64**
    %6 = getelementptr i64*, i64** %data, i64 %2
    call void @__free_ai(i64** %6)
    %7 = add i64 %2, 1
    store i64 %7, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast i64** %1 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i8**
    store i8** %1, i8*** @schmu_arr, align 8
    %2 = bitcast i8** %1 to i64*
    store i64 3, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 3, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to i8**
    %4 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i8** %4, align 8
    %5 = bitcast i8** %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %5, i64 8, i1 false)
    tail call void @__copy_ac(i8** %data)
    %"1" = getelementptr i8*, i8** %data, i64 1
    %6 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @1 to i8*), i8** %6, align 8
    %7 = bitcast i8** %"1" to i8*
    %8 = bitcast i8** %6 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* %8, i64 8, i1 false)
    tail call void @__copy_ac(i8** %"1")
    %"2" = getelementptr i8*, i8** %data, i64 2
    %9 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @2 to i8*), i8** %9, align 8
    %10 = bitcast i8** %"2" to i8*
    %11 = bitcast i8** %9 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %11, i64 8, i1 false)
    tail call void @__copy_ac(i8** %"2")
    %12 = tail call i8* @malloc(i64 40)
    %13 = bitcast i8* %12 to %foo*
    store %foo* %13, %foo** @schmu_arr__2, align 8
    %14 = bitcast %foo* %13 to i64*
    store i64 3, i64* %14, align 8
    %cap2 = getelementptr i64, i64* %14, i64 1
    store i64 3, i64* %cap2, align 8
    %15 = getelementptr i8, i8* %12, i64 16
    %data3 = bitcast i8* %15 to %foo*
    store %foo { i64 1 }, %foo* %data3, align 8
    %"15" = getelementptr %foo, %foo* %data3, i64 1
    store %foo { i64 2 }, %foo* %"15", align 8
    %"26" = getelementptr %foo, %foo* %data3, i64 2
    store %foo { i64 3 }, %foo* %"26", align 8
    %16 = tail call %foo* @schmu_make_arr()
    store %foo* %16, %foo** @schmu_arr__3, align 8
    tail call void @schmu_arr_inside()
    tail call void @schmu_inner_parent_scope()
    %17 = tail call %foo* @schmu_nest_fns()
    store %foo* %17, %foo** @schmu_normal, align 8
    %18 = tail call i8* @malloc(i64 32)
    %19 = bitcast i8* %18 to i64**
    store i64** %19, i64*** @schmu_nested, align 8
    %20 = bitcast i64** %19 to i64*
    store i64 2, i64* %20, align 8
    %cap8 = getelementptr i64, i64* %20, i64 1
    store i64 2, i64* %cap8, align 8
    %21 = getelementptr i8, i8* %18, i64 16
    %data9 = bitcast i8* %21 to i64**
    %22 = tail call i8* @malloc(i64 32)
    %23 = bitcast i8* %22 to i64*
    store i64* %23, i64** %data9, align 8
    store i64 2, i64* %23, align 8
    %cap12 = getelementptr i64, i64* %23, i64 1
    store i64 2, i64* %cap12, align 8
    %24 = getelementptr i8, i8* %22, i64 16
    %data13 = bitcast i8* %24 to i64*
    store i64 0, i64* %data13, align 8
    %"115" = getelementptr i64, i64* %data13, i64 1
    store i64 1, i64* %"115", align 8
    %"116" = getelementptr i64*, i64** %data9, i64 1
    %25 = tail call i8* @malloc(i64 32)
    %26 = bitcast i8* %25 to i64*
    store i64* %26, i64** %"116", align 8
    store i64 2, i64* %26, align 8
    %cap18 = getelementptr i64, i64* %26, i64 1
    store i64 2, i64* %cap18, align 8
    %27 = getelementptr i8, i8* %25, i64 16
    %data19 = bitcast i8* %27 to i64*
    store i64 2, i64* %data19, align 8
    %"121" = getelementptr i64, i64* %data19, i64 1
    store i64 3, i64* %"121", align 8
    %28 = tail call i8* @malloc(i64 32)
    %29 = bitcast i8* %28 to i64*
    %arr = alloca i64*, align 8
    store i64* %29, i64** %arr, align 8
    store i64 2, i64* %29, align 8
    %cap23 = getelementptr i64, i64* %29, i64 1
    store i64 2, i64* %cap23, align 8
    %30 = getelementptr i8, i8* %28, i64 16
    %data24 = bitcast i8* %30 to i64*
    store i64 4, i64* %data24, align 8
    %"126" = getelementptr i64, i64* %data24, i64 1
    store i64 5, i64* %"126", align 8
    tail call void @__array_push_aaiai.u(i64*** @schmu_nested, i64* %29)
    %31 = tail call i64** @schmu_make_nested_arr()
    store i64** %31, i64*** @schmu_nested__2, align 8
    %32 = tail call i64** @schmu_nest_allocs()
    store i64** %32, i64*** @schmu_nested__3, align 8
    tail call void @schmu_nest_local()
    store i64 12, i64* getelementptr inbounds (%container, %container* @schmu_rec_of_arr, i32 0, i32 0), align 8
    %33 = tail call i8* @malloc(i64 32)
    %34 = bitcast i8* %33 to i64*
    %arr27 = alloca i64*, align 8
    store i64* %34, i64** %arr27, align 8
    store i64 2, i64* %34, align 8
    %cap29 = getelementptr i64, i64* %34, i64 1
    store i64 2, i64* %cap29, align 8
    %35 = getelementptr i8, i8* %33, i64 16
    %data30 = bitcast i8* %35 to i64*
    store i64 1, i64* %data30, align 8
    %"132" = getelementptr i64, i64* %data30, i64 1
    store i64 2, i64* %"132", align 8
    store i64* %34, i64** getelementptr inbounds (%container, %container* @schmu_rec_of_arr, i32 0, i32 1), align 8
    %36 = tail call { i64, i64 } @schmu_record_of_arrs()
    store { i64, i64 } %36, { i64, i64 }* bitcast (%container* @schmu_rec_of_arr__2 to { i64, i64 }*), align 8
    %37 = tail call i8* @malloc(i64 48)
    %38 = bitcast i8* %37 to %container*
    store %container* %38, %container** @schmu_arr_of_rec, align 8
    %39 = bitcast %container* %38 to i64*
    store i64 2, i64* %39, align 8
    %cap34 = getelementptr i64, i64* %39, i64 1
    store i64 2, i64* %cap34, align 8
    %40 = getelementptr i8, i8* %37, i64 16
    %data35 = bitcast i8* %40 to %container*
    %41 = tail call { i64, i64 } @schmu_record_of_arrs()
    %box = bitcast %container* %data35 to { i64, i64 }*
    store { i64, i64 } %41, { i64, i64 }* %box, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %40, i8* %40, i64 16, i1 false)
    %"138" = getelementptr %container, %container* %data35, i64 1
    %42 = tail call { i64, i64 } @schmu_record_of_arrs()
    %box39 = bitcast %container* %"138" to { i64, i64 }*
    store { i64, i64 } %42, { i64, i64 }* %box39, align 8
    %43 = bitcast %container* %"138" to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %43, i8* %43, i64 16, i1 false)
    %44 = tail call %container* @schmu_arr_of_records()
    store %container* %44, %container** @schmu_arr_of_rec__2, align 8
    %45 = alloca %container*, align 8
    store %container* %44, %container** %45, align 8
    call void @__free_acontainer(%container** %45)
    call void @__free_acontainer(%container** @schmu_arr_of_rec)
    call void @__free_container(%container* @schmu_rec_of_arr__2)
    call void @__free_container(%container* @schmu_rec_of_arr)
    %46 = alloca i64**, align 8
    store i64** %32, i64*** %46, align 8
    call void @__free_aai(i64*** %46)
    %47 = alloca i64**, align 8
    store i64** %31, i64*** %47, align 8
    call void @__free_aai(i64*** %47)
    call void @__free_aai(i64*** @schmu_nested)
    %48 = alloca %foo*, align 8
    store %foo* %17, %foo** %48, align 8
    call void @__free_afoo(%foo** %48)
    %49 = alloca %foo*, align 8
    store %foo* %16, %foo** %49, align 8
    call void @__free_afoo(%foo** %49)
    call void @__free_afoo(%foo** @schmu_arr__2)
    call void @__free_aac(i8*** @schmu_arr)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac(i8** %0) {
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
  
  define linkonce_odr void @__free_container(%container* %0) {
  entry:
    %1 = getelementptr inbounds %container, %container* %0, i32 0, i32 1
    call void @__free_ai(i64** %1)
    ret void
  }
  
  define linkonce_odr void @__free_acontainer(%container** %0) {
  entry:
    %1 = load %container*, %container** %0, align 8
    %ref = bitcast %container* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast %container* %1 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data = bitcast i8* %5 to %container*
    %6 = getelementptr %container, %container* %data, i64 %2
    call void @__free_container(%container* %6)
    %7 = add i64 %2, 1
    store i64 %7, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast %container* %1 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    ret void
  }
  
  define linkonce_odr void @__free_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_aac(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast i8** %1 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data = bitcast i8* %5 to i8**
    %6 = getelementptr i8*, i8** %data, i64 %2
    call void @__free_ac(i8** %6)
    %7 = add i64 %2, 1
    store i64 %7, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast i8** %1 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    ret void
  }
  
  declare void @free(i8* %0)
  
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
  
  declare void @subv3(%v3* noalias %0, %v3* byval(%v3) %1)
  
  declare void @subi3(%i3* noalias %0, %i3* byval(%i3) %1)
  
  declare void @subv4(%v4* noalias %0, %v4* byval(%v4) %1)
  
  declare void @submixed4(%mixed4* noalias %0, %mixed4* byval(%mixed4) %1)
  
  declare void @subtrailv2(%trailv2* noalias %0, %trailv2* byval(%trailv2) %1)
  
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
    store %i2 { i64 1, i64 10 }, %i2* %boxconst4, align 8
    %unbox5 = bitcast %i2* %boxconst4 to { i64, i64 }*
    %fst642 = bitcast { i64, i64 }* %unbox5 to i64*
    %fst7 = load i64, i64* %fst642, align 8
    %snd8 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox5, i32 0, i32 1
    %snd9 = load i64, i64* %snd8, align 8
    %ret10 = alloca %i2, align 8
    %1 = tail call { i64, i64 } @subi2(i64 %fst7, i64 %snd9)
    %box11 = bitcast %i2* %ret10 to { i64, i64 }*
    store { i64, i64 } %1, { i64, i64 }* %box11, align 8
    %ret13 = alloca %v1, align 8
    %2 = tail call double @subv1(double 1.000000e+00)
    %box14 = bitcast %v1* %ret13 to double*
    store double %2, double* %box14, align 8
    %ret16 = alloca %i1, align 8
    %3 = tail call i64 @subi1(i64 1)
    %box17 = bitcast %i1* %ret16 to i64*
    store i64 %3, i64* %box17, align 8
    %boxconst19 = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, %v3* %boxconst19, align 8
    %ret20 = alloca %v3, align 8
    call void @subv3(%v3* %ret20, %v3* %boxconst19)
    %boxconst21 = alloca %i3, align 8
    store %i3 { i64 1, i64 10, i64 100 }, %i3* %boxconst21, align 8
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
  
  define void @schmu_v3_add(%v3* noalias %0, %v3* %lhs, %v3* %rhs) {
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
  
  define void @schmu_v3_scale(%v3* noalias %0, %v3* %v3, double %factor) {
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
  
  define void @schmu_wrap(%v3* noalias %0) {
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
  
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"false\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"true\00" }
  @2 = private unnamed_addr constant { i64, i64, [12 x i8] } { i64 11, i64 11, [12 x i8] c"test 'and':\00" }
  @3 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"yes\00" }
  @4 = private unnamed_addr constant { i64, i64, [3 x i8] } { i64 2, i64 2, [3 x i8] c"no\00" }
  @5 = private unnamed_addr constant { i64, i64, [11 x i8] } { i64 10, i64 10, [11 x i8] c"test 'or':\00" }
  @6 = private unnamed_addr constant { i64, i64, [12 x i8] } { i64 11, i64 11, [12 x i8] c"test 'not':\00" }
  
  declare void @string_print(i8* %0)
  
  define i1 @schmu_false_() {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*))
    ret i1 false
  }
  
  define i1 @schmu_true_() {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [5 x i8] }* @1 to i8*))
    ret i1 true
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [12 x i8] }* @2 to i8*))
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
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont
  
  else:                                             ; preds = %cont
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %2 = tail call i1 @schmu_true_()
    br i1 %2, label %true11, label %cont3
  
  true11:                                           ; preds = %ifcont
    %3 = tail call i1 @schmu_false_()
    br i1 %3, label %true22, label %cont3
  
  true22:                                           ; preds = %true11
    br label %cont3
  
  cont3:                                            ; preds = %true22, %true11, %ifcont
    %andtmp4 = phi i1 [ false, %ifcont ], [ false, %true11 ], [ true, %true22 ]
    br i1 %andtmp4, label %then5, label %else6
  
  then5:                                            ; preds = %cont3
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont7
  
  else6:                                            ; preds = %cont3
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont7
  
  ifcont7:                                          ; preds = %else6, %then5
    %4 = tail call i1 @schmu_false_()
    br i1 %4, label %true18, label %cont10
  
  true18:                                           ; preds = %ifcont7
    %5 = tail call i1 @schmu_true_()
    br i1 %5, label %true29, label %cont10
  
  true29:                                           ; preds = %true18
    br label %cont10
  
  cont10:                                           ; preds = %true29, %true18, %ifcont7
    %andtmp11 = phi i1 [ false, %ifcont7 ], [ false, %true18 ], [ true, %true29 ]
    br i1 %andtmp11, label %then12, label %else13
  
  then12:                                           ; preds = %cont10
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont14
  
  else13:                                           ; preds = %cont10
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont14
  
  ifcont14:                                         ; preds = %else13, %then12
    %6 = tail call i1 @schmu_false_()
    br i1 %6, label %true115, label %cont17
  
  true115:                                          ; preds = %ifcont14
    %7 = tail call i1 @schmu_false_()
    br i1 %7, label %true216, label %cont17
  
  true216:                                          ; preds = %true115
    br label %cont17
  
  cont17:                                           ; preds = %true216, %true115, %ifcont14
    %andtmp18 = phi i1 [ false, %ifcont14 ], [ false, %true115 ], [ true, %true216 ]
    br i1 %andtmp18, label %then19, label %else20
  
  then19:                                           ; preds = %cont17
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont21
  
  else20:                                           ; preds = %cont17
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont21
  
  ifcont21:                                         ; preds = %else20, %then19
    tail call void @string_print(i8* bitcast ({ i64, i64, [11 x i8] }* @5 to i8*))
    %8 = tail call i1 @schmu_true_()
    br i1 %8, label %cont22, label %false1
  
  false1:                                           ; preds = %ifcont21
    %9 = tail call i1 @schmu_true_()
    br i1 %9, label %cont22, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont22
  
  cont22:                                           ; preds = %false2, %false1, %ifcont21
    %andtmp23 = phi i1 [ true, %ifcont21 ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp23, label %then24, label %else25
  
  then24:                                           ; preds = %cont22
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont26
  
  else25:                                           ; preds = %cont22
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont26
  
  ifcont26:                                         ; preds = %else25, %then24
    %10 = tail call i1 @schmu_true_()
    br i1 %10, label %cont29, label %false127
  
  false127:                                         ; preds = %ifcont26
    %11 = tail call i1 @schmu_false_()
    br i1 %11, label %cont29, label %false228
  
  false228:                                         ; preds = %false127
    br label %cont29
  
  cont29:                                           ; preds = %false228, %false127, %ifcont26
    %andtmp30 = phi i1 [ true, %ifcont26 ], [ true, %false127 ], [ false, %false228 ]
    br i1 %andtmp30, label %then31, label %else32
  
  then31:                                           ; preds = %cont29
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont33
  
  else32:                                           ; preds = %cont29
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont33
  
  ifcont33:                                         ; preds = %else32, %then31
    %12 = tail call i1 @schmu_false_()
    br i1 %12, label %cont36, label %false134
  
  false134:                                         ; preds = %ifcont33
    %13 = tail call i1 @schmu_true_()
    br i1 %13, label %cont36, label %false235
  
  false235:                                         ; preds = %false134
    br label %cont36
  
  cont36:                                           ; preds = %false235, %false134, %ifcont33
    %andtmp37 = phi i1 [ true, %ifcont33 ], [ true, %false134 ], [ false, %false235 ]
    br i1 %andtmp37, label %then38, label %else39
  
  then38:                                           ; preds = %cont36
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont40
  
  else39:                                           ; preds = %cont36
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont40
  
  ifcont40:                                         ; preds = %else39, %then38
    %14 = tail call i1 @schmu_false_()
    br i1 %14, label %cont43, label %false141
  
  false141:                                         ; preds = %ifcont40
    %15 = tail call i1 @schmu_false_()
    br i1 %15, label %cont43, label %false242
  
  false242:                                         ; preds = %false141
    br label %cont43
  
  cont43:                                           ; preds = %false242, %false141, %ifcont40
    %andtmp44 = phi i1 [ true, %ifcont40 ], [ true, %false141 ], [ false, %false242 ]
    br i1 %andtmp44, label %then45, label %else46
  
  then45:                                           ; preds = %cont43
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont47
  
  else46:                                           ; preds = %cont43
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont47
  
  ifcont47:                                         ; preds = %else46, %then45
    tail call void @string_print(i8* bitcast ({ i64, i64, [12 x i8] }* @6 to i8*))
    %16 = tail call i1 @schmu_true_()
    %17 = xor i1 %16, true
    br i1 %17, label %then48, label %else49
  
  then48:                                           ; preds = %ifcont47
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont50
  
  else49:                                           ; preds = %ifcont47
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont50
  
  ifcont50:                                         ; preds = %else49, %then48
    %18 = tail call i1 @schmu_false_()
    %19 = xor i1 %18, true
    br i1 %19, label %then51, label %else52
  
  then51:                                           ; preds = %ifcont50
    tail call void @string_print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont53
  
  else52:                                           ; preds = %ifcont50
    tail call void @string_print(i8* bitcast ({ i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont53
  
  ifcont53:                                         ; preds = %else52, %then51
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
  unary_minus.smu:1.5-6: warning: Unused binding a.
  
  1 | let a = -1.0
          ^
  
  unary_minus.smu:2.5-6: warning: Unused binding a.
  
  2 | let a = -.1.0
          ^
  
  unary_minus.smu:3.5-6: warning: Unused binding a.
  
  3 | let a = - 1.0
          ^
  
  unary_minus.smu:4.5-6: warning: Unused binding a.
  
  4 | let a = -. 1.0
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = constant double -1.000000e+00
  @schmu_a__2 = constant double -1.000000e+00
  @schmu_a__3 = constant double -1.000000e+00
  @schmu_a__4 = constant double -1.000000e+00
  @schmu_a__5 = constant i64 -1
  @schmu_b = constant i64 -1
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 -2
  }
  [254]

Test unused binding warning
  $ schmu unused.smu stub.o
  unused.smu:2.5-12: warning: Unused binding unused1.
  
  2 | let unused1 = 0
          ^^^^^^^
  
  unused.smu:5.5-12: warning: Unused binding unused2.
  
  5 | let unused2 = 0
          ^^^^^^^
  
  unused.smu:12.5-16: warning: Unused binding use_unused3.
  
  12 | fun use_unused3():
           ^^^^^^^^^^^
  
  unused.smu:17.9-16: warning: Unused binding unused4.
  
  17 |     let unused4 = 0
               ^^^^^^^
  
  unused.smu:20.9-16: warning: Unused binding unused5.
  
  20 |     let unused5 = 0
               ^^^^^^^
  
  unused.smu:33.9-18: warning: Unused binding usedlater.
  
  33 |     let usedlater = 0
               ^^^^^^^^^
  
  unused.smu:46.9-18: warning: Unused binding usedlater.
  
  46 |     let usedlater = 0
               ^^^^^^^^^
  
Allow declaring a c function with a different name
  $ schmu stub.o cname_decl.smu && ./cname_decl
  
  42

We can have if without else
  $ schmu if_no_else.smu
  if_no_else.smu:2.1-11: error: A conditional without else branch should evaluato to type unit.
  expecting [unit]
  but found [int].
  
  2 | if true: 2
      ^^^^^^^^^^
  
  [1]

Tailcall loops
  $ schmu --dump-llvm stub.o regression_issue_26.smu && ./regression_issue_26
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_limit = constant i64 3
  @0 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"%i, %i\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [12 x i8] } { i64 11, i64 11, [12 x i8] c"%i, %i, %i\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1, i64 %2, i64 %3)
  
  define void @schmu_nested(i64 %a, i64 %b) {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, i64* %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, i64* %1, align 8
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
    store i64 %add, i64* %0, align 8
    store i64 0, i64* %1, align 8
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %.ph, 3
    br i1 %eq1, label %then2, label %else3
  
  then2:                                            ; preds = %else
    ret void
  
  else3:                                            ; preds = %else
    %3 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [8 x i8] }* @0 to i8*))
    tail call void @printf(i8* %3, i64 %.ph, i64 %2, i64 0)
    %add4 = add i64 %2, 1
    store i64 %add4, i64* %1, align 8
    br label %rec
  }
  
  define void @schmu_nested__2(i64 %a, i64 %b, i64 %c) {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, i64* %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, i64* %1, align 8
    %2 = alloca i64, align 8
    store i64 %c, i64* %2, align 8
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
    store i64 %add, i64* %0, align 8
    store i64 0, i64* %1, align 8
    br label %rec.outer.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %4, 3
    br i1 %eq1, label %then2, label %else4
  
  then2:                                            ; preds = %else
    %add3 = add i64 %.ph, 1
    store i64 %add3, i64* %1, align 8
    store i64 0, i64* %2, align 8
    br label %rec.outer
  
  else4:                                            ; preds = %else
    %eq5 = icmp eq i64 %3, 3
    br i1 %eq5, label %then6, label %else7
  
  then6:                                            ; preds = %else4
    ret void
  
  else7:                                            ; preds = %else4
    %5 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [12 x i8] }* @1 to i8*))
    tail call void @printf(i8* %5, i64 %.ph11.ph, i64 %.ph, i64 %4)
    %add8 = add i64 %4, 1
    store i64 %add8, i64* %2, align 8
    br label %rec
  }
  
  define void @schmu_nested__3(i64 %a, i64 %b, i64 %c) {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, i64* %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, i64* %1, align 8
    %2 = alloca i64, align 8
    store i64 %c, i64* %2, align 8
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
    store i64 %add, i64* %0, align 8
    store i64 0, i64* %1, align 8
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
    store i64 %add6, i64* %1, align 8
    store i64 0, i64* %2, align 8
    br label %rec.outer
  
  else7:                                            ; preds = %else3
    %5 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [12 x i8] }* @1 to i8*))
    tail call void @printf(i8* %5, i64 %.ph10.ph, i64 %.ph, i64 %3)
    %add8 = add i64 %3, 1
    store i64 %add8, i64* %2, align 8
    br label %rec
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_nested(i64 0, i64 0)
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [2 x i8] }* @2 to i8*))
    tail call void @printf(i8* %0, i64 0, i64 0, i64 0)
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
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %v = type { double, double, double }
  
  @schmu_acc_force = internal constant double 1.000000e+02
  
  declare double @dot(%v* byval(%v) %0, %v* byval(%v) %1)
  
  declare void @norm(%v* noalias %0, %v* byval(%v) %1)
  
  declare void @scale(%v* noalias %0, %v* byval(%v) %1, double %2)
  
  declare i1 @maybe()
  
  define void @schmu_calc_acc(%v* noalias %0, %v* %vel) {
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
  
  %option.ti = type { i32, i64 }
  
  declare void @Printi(i64 %0)
  
  define i64 @__fun_schmu0(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @__fun_schmu1(%option.ti* %x) {
  entry:
    %tag1 = bitcast %option.ti* %x to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.ti, %option.ti* %x, i32 0, i32 1
    %0 = load i64, i64* %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @__fun_schmu0(i64 1)
    tail call void @Printi(i64 %0)
    %boxconst = alloca %option.ti, align 8
    store %option.ti { i32 0, i64 1 }, %option.ti* %boxconst, align 8
    %1 = call i64 @__fun_schmu1(%option.ti* %boxconst)
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
  
  @schmu_height = constant i64 720
  @schmu_world = global %bar zeroinitializer, align 8
  
  define linkonce_odr void @__schmu_get_seg_bar.u(%bar* %bar) {
  entry:
    ret void
  }
  
  define void @schmu_wrap_seg() {
  entry:
    tail call void @__schmu_get_seg_bar.u(%bar* @schmu_world)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store double 0.000000e+00, double* getelementptr inbounds (%bar, %bar* @schmu_world, i32 0, i32 0), align 8
    store double 1.280000e+03, double* getelementptr inbounds (%bar, %bar* @schmu_world, i32 0, i32 1), align 8
    store i64 10, i64* getelementptr inbounds (%bar, %bar* @schmu_world, i32 0, i32 2), align 8
    store double 1.000000e-01, double* getelementptr inbounds (%bar, %bar* @schmu_world, i32 0, i32 3), align 8
    store double 5.400000e+02, double* getelementptr inbounds (%bar, %bar* @schmu_world, i32 0, i32 4), align 8
    store float 5.000000e+00, float* getelementptr inbounds (%bar, %bar* @schmu_world, i32 0, i32 5), align 4
    tail call void @schmu_wrap_seg()
    ret i64 0
  }


Array push
  $ schmu --dump-llvm array_push.smu && valgrind -q --leak-check=yes --show-reachable=yes ./array_push
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global i64* null, align 8
  @schmu_b = global i64* null, align 8
  @schmu_nested = global i64** null, align 8
  @schmu_a__2 = global i64* null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define linkonce_odr void @__array_push_aaiai.u(i64*** noalias %arr, i64* %value) {
  entry:
    %0 = load i64**, i64*** %arr, align 8
    %1 = bitcast i64** %0 to i64*
    %capacity = getelementptr i64, i64* %1, i64 1
    %2 = load i64, i64* %capacity, align 8
    %3 = load i64, i64* %1, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %then, label %ifcont7
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %2, 0
    br i1 %eq1, label %then2, label %else
  
  then2:                                            ; preds = %then
    %4 = bitcast i64** %0 to i8*
    %5 = tail call i8* @realloc(i8* %4, i64 48)
    %6 = bitcast i8* %5 to i64**
    store i64** %6, i64*** %arr, align 8
    %newcap = bitcast i64** %6 to i64*
    %newcap3 = getelementptr i64, i64* %newcap, i64 1
    store i64 4, i64* %newcap3, align 8
    br label %ifcont7
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %2
    %7 = mul i64 %mul, 8
    %8 = add i64 %7, 16
    %9 = bitcast i64** %0 to i8*
    %10 = tail call i8* @realloc(i8* %9, i64 %8)
    %11 = bitcast i8* %10 to i64**
    store i64** %11, i64*** %arr, align 8
    %newcap4 = bitcast i64** %11 to i64*
    %newcap5 = getelementptr i64, i64* %newcap4, i64 1
    store i64 %mul, i64* %newcap5, align 8
    br label %ifcont7
  
  ifcont7:                                          ; preds = %entry, %then2, %else
    %.pre-phi = phi i64* [ %newcap4, %else ], [ %newcap, %then2 ], [ %1, %entry ]
    %12 = phi i64** [ %11, %else ], [ %6, %then2 ], [ %0, %entry ]
    %13 = bitcast i64** %12 to i8*
    %14 = getelementptr i8, i8* %13, i64 16
    %data = bitcast i8* %14 to i64**
    %15 = getelementptr inbounds i64*, i64** %data, i64 %3
    store i64* %value, i64** %15, align 8
    %add = add i64 %3, 1
    store i64 %add, i64* %.pre-phi, align 8
    ret void
  }
  
  define linkonce_odr void @__array_push_aii.u(i64** noalias %arr, i64 %value) {
  entry:
    %0 = load i64*, i64** %arr, align 8
    %capacity = getelementptr i64, i64* %0, i64 1
    %1 = load i64, i64* %capacity, align 8
    %2 = load i64, i64* %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else
  
  then2:                                            ; preds = %then
    %3 = bitcast i64* %0 to i8*
    %4 = tail call i8* @realloc(i8* %3, i64 48)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %arr, align 8
    %newcap = getelementptr i64, i64* %5, i64 1
    store i64 4, i64* %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %1
    %6 = mul i64 %mul, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %0 to i8*
    %9 = tail call i8* @realloc(i8* %8, i64 %7)
    %10 = bitcast i8* %9 to i64*
    store i64* %10, i64** %arr, align 8
    %newcap3 = getelementptr i64, i64* %10, i64 1
    store i64 %mul, i64* %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %11 = phi i64* [ %10, %else ], [ %5, %then2 ], [ %0, %entry ]
    %12 = bitcast i64* %11 to i8*
    %13 = getelementptr i8, i8* %12, i64 16
    %data = bitcast i8* %13 to i64*
    %14 = getelementptr inbounds i64, i64* %data, i64 %2
    store i64 %value, i64* %14, align 8
    %add = add i64 %2, 1
    store i64 %add, i64* %11, align 8
    ret void
  }
  
  define void @schmu_in_fun() {
  entry:
    %0 = alloca i64*, align 8
    %1 = tail call i8* @malloc(i64 32)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** %0, align 8
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    %4 = alloca i64*, align 8
    %5 = bitcast i64** %4 to i8*
    %6 = bitcast i64** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 8, i1 false)
    call void @__copy_ai(i64** %4)
    call void @__array_push_aii.u(i64** %0, i64 30)
    %7 = load i64*, i64** %0, align 8
    %8 = load i64, i64* %7, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %8)
    %9 = load i64*, i64** %4, align 8
    %10 = load i64, i64* %9, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %10)
    call void @__free_ai(i64** %4)
    call void @__free_ai(i64** %0)
    ret void
  }
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz1 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = bitcast i64* %5 to i8*
    %7 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 %3, i1 false)
    %newcap = getelementptr i64, i64* %5, i64 1
    store i64 %size, i64* %newcap, align 8
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @schmu_a, align 8
    store i64 2, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 2, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (i64** @schmu_b to i8*), i8* bitcast (i64** @schmu_a to i8*), i64 8, i1 false)
    tail call void @__copy_ai(i64** @schmu_b)
    tail call void @__array_push_aii.u(i64** @schmu_a, i64 30)
    %3 = load i64*, i64** @schmu_a, align 8
    %4 = load i64, i64* %3, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %4)
    %5 = load i64*, i64** @schmu_b, align 8
    %6 = load i64, i64* %5, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %6)
    tail call void @schmu_in_fun()
    %7 = tail call i8* @malloc(i64 32)
    %8 = bitcast i8* %7 to i64**
    store i64** %8, i64*** @schmu_nested, align 8
    %9 = bitcast i64** %8 to i64*
    store i64 2, i64* %9, align 8
    %cap3 = getelementptr i64, i64* %9, i64 1
    store i64 2, i64* %cap3, align 8
    %10 = getelementptr i8, i8* %7, i64 16
    %data4 = bitcast i8* %10 to i64**
    %11 = tail call i8* @malloc(i64 32)
    %12 = bitcast i8* %11 to i64*
    store i64* %12, i64** %data4, align 8
    store i64 2, i64* %12, align 8
    %cap7 = getelementptr i64, i64* %12, i64 1
    store i64 2, i64* %cap7, align 8
    %13 = getelementptr i8, i8* %11, i64 16
    %data8 = bitcast i8* %13 to i64*
    store i64 0, i64* %data8, align 8
    %"110" = getelementptr i64, i64* %data8, i64 1
    store i64 1, i64* %"110", align 8
    %"111" = getelementptr i64*, i64** %data4, i64 1
    %14 = tail call i8* @malloc(i64 32)
    %15 = bitcast i8* %14 to i64*
    store i64* %15, i64** %"111", align 8
    store i64 2, i64* %15, align 8
    %cap13 = getelementptr i64, i64* %15, i64 1
    store i64 2, i64* %cap13, align 8
    %16 = getelementptr i8, i8* %14, i64 16
    %data14 = bitcast i8* %16 to i64*
    store i64 2, i64* %data14, align 8
    %"116" = getelementptr i64, i64* %data14, i64 1
    store i64 3, i64* %"116", align 8
    %17 = tail call i8* @malloc(i64 32)
    %18 = bitcast i8* %17 to i64*
    store i64* %18, i64** @schmu_a__2, align 8
    store i64 2, i64* %18, align 8
    %cap18 = getelementptr i64, i64* %18, i64 1
    store i64 2, i64* %cap18, align 8
    %19 = getelementptr i8, i8* %17, i64 16
    %data19 = bitcast i8* %19 to i64*
    store i64 4, i64* %data19, align 8
    %"121" = getelementptr i64, i64* %data19, i64 1
    store i64 5, i64* %"121", align 8
    %20 = alloca i64*, align 8
    %21 = bitcast i64** %20 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %21, i8* bitcast (i64** @schmu_a__2 to i8*), i64 8, i1 false)
    call void @__copy_ai(i64** %20)
    %22 = load i64*, i64** %20, align 8
    call void @__array_push_aaiai.u(i64*** @schmu_nested, i64* %22)
    %23 = load i64**, i64*** @schmu_nested, align 8
    %24 = bitcast i64** %23 to i8*
    %25 = getelementptr i8, i8* %24, i64 16
    %data22 = bitcast i8* %25 to i64**
    %26 = getelementptr i64*, i64** %data22, i64 1
    %27 = alloca i64*, align 8
    %28 = bitcast i64** %27 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %28, i8* bitcast (i64** @schmu_a__2 to i8*), i64 8, i1 false)
    call void @__copy_ai(i64** %27)
    call void @__free_ai(i64** %26)
    %29 = load i64*, i64** %27, align 8
    store i64* %29, i64** %26, align 8
    %30 = load i64**, i64*** @schmu_nested, align 8
    %31 = bitcast i64** %30 to i8*
    %32 = getelementptr i8, i8* %31, i64 16
    %data23 = bitcast i8* %32 to i64**
    %33 = getelementptr i64*, i64** %data23, i64 1
    %34 = alloca i64*, align 8
    %35 = bitcast i64** %34 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %35, i8* bitcast (i64** @schmu_a__2 to i8*), i64 8, i1 false)
    call void @__copy_ai(i64** %34)
    call void @__free_ai(i64** %33)
    %36 = load i64*, i64** %34, align 8
    store i64* %36, i64** %33, align 8
    %37 = call i8* @malloc(i64 32)
    %38 = bitcast i8* %37 to i64*
    %arr = alloca i64*, align 8
    store i64* %38, i64** %arr, align 8
    store i64 2, i64* %38, align 8
    %cap25 = getelementptr i64, i64* %38, i64 1
    store i64 2, i64* %cap25, align 8
    %39 = getelementptr i8, i8* %37, i64 16
    %data26 = bitcast i8* %39 to i64*
    store i64 4, i64* %data26, align 8
    %"128" = getelementptr i64, i64* %data26, i64 1
    store i64 5, i64* %"128", align 8
    call void @__array_push_aaiai.u(i64*** @schmu_nested, i64* %38)
    %40 = load i64**, i64*** @schmu_nested, align 8
    %41 = bitcast i64** %40 to i8*
    %42 = getelementptr i8, i8* %41, i64 16
    %data29 = bitcast i8* %42 to i64**
    %43 = getelementptr i64*, i64** %data29, i64 1
    %44 = call i8* @malloc(i64 32)
    %45 = bitcast i8* %44 to i64*
    %arr30 = alloca i64*, align 8
    store i64* %45, i64** %arr30, align 8
    store i64 2, i64* %45, align 8
    %cap32 = getelementptr i64, i64* %45, i64 1
    store i64 2, i64* %cap32, align 8
    %46 = getelementptr i8, i8* %44, i64 16
    %data33 = bitcast i8* %46 to i64*
    store i64 4, i64* %data33, align 8
    %"135" = getelementptr i64, i64* %data33, i64 1
    store i64 5, i64* %"135", align 8
    call void @__free_ai(i64** %43)
    store i64* %45, i64** %43, align 8
    %47 = load i64**, i64*** @schmu_nested, align 8
    %48 = bitcast i64** %47 to i8*
    %49 = getelementptr i8, i8* %48, i64 16
    %data36 = bitcast i8* %49 to i64**
    %50 = getelementptr i64*, i64** %data36, i64 1
    %51 = call i8* @malloc(i64 32)
    %52 = bitcast i8* %51 to i64*
    %arr37 = alloca i64*, align 8
    store i64* %52, i64** %arr37, align 8
    store i64 2, i64* %52, align 8
    %cap39 = getelementptr i64, i64* %52, i64 1
    store i64 2, i64* %cap39, align 8
    %53 = getelementptr i8, i8* %51, i64 16
    %data40 = bitcast i8* %53 to i64*
    store i64 4, i64* %data40, align 8
    %"142" = getelementptr i64, i64* %data40, i64 1
    store i64 5, i64* %"142", align 8
    call void @__free_ai(i64** %50)
    store i64* %52, i64** %50, align 8
    call void @__free_ai(i64** @schmu_a__2)
    call void @__free_aai(i64*** @schmu_nested)
    call void @__free_ai(i64** @schmu_b)
    call void @__free_ai(i64** @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__free_aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast i64** %1 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data = bitcast i8* %5 to i64**
    %6 = getelementptr i64*, i64** %data, i64 %2
    call void @__free_ai(i64** %6)
    %7 = add i64 %2, 1
    store i64 %7, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast i64** %1 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  3
  2
  3
  2

Decrease ref counts for local variables in if branches
  $ schmu --dump-llvm decr_rc_if.smu && valgrind -q --leak-check=yes --show-reachable=yes ./decr_rc_if
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i1 @schmu_ret_true() {
  entry:
    ret i1 true
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i1 @schmu_ret_true()
    br i1 %0, label %then, label %else
  
  then:                                             ; preds = %entry
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to i64*
    %arr = alloca i64*, align 8
    store i64* %2, i64** %arr, align 8
    store i64 1, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    %4 = tail call i8* @malloc(i64 24)
    %5 = bitcast i8* %4 to i64*
    %arr1 = alloca i64*, align 8
    store i64* %5, i64** %arr1, align 8
    store i64 1, i64* %5, align 8
    %cap3 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %cap3, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data4 = bitcast i8* %6 to i64*
    store i64 10, i64* %data4, align 8
    call void @__free_ai(i64** %arr)
    br label %ifcont
  
  else:                                             ; preds = %entry
    %7 = tail call i8* @malloc(i64 24)
    %8 = bitcast i8* %7 to i64*
    %arr6 = alloca i64*, align 8
    store i64* %8, i64** %arr6, align 8
    store i64 1, i64* %8, align 8
    %cap8 = getelementptr i64, i64* %8, i64 1
    store i64 1, i64* %cap8, align 8
    %9 = getelementptr i8, i8* %7, i64 16
    %data9 = bitcast i8* %9 to i64*
    store i64 0, i64* %data9, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi i64** [ %arr1, %then ], [ %arr6, %else ]
    call void @__free_ai(i64** %iftmp)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare void @free(i8* %0)

Drop last element
  $ schmu --dump-llvm array_drop_back.smu && valgrind -q --leak-check=yes --show-reachable=yes ./array_drop_back
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_nested = global i64** null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64**
    store i64** %1, i64*** @schmu_nested, align 8
    %2 = bitcast i64** %1 to i64*
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to i64**
    %4 = tail call i8* @malloc(i64 32)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %data, align 8
    store i64 2, i64* %5, align 8
    %cap2 = getelementptr i64, i64* %5, i64 1
    store i64 2, i64* %cap2, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data3 = bitcast i8* %6 to i64*
    store i64 0, i64* %data3, align 8
    %"1" = getelementptr i64, i64* %data3, i64 1
    store i64 1, i64* %"1", align 8
    %"15" = getelementptr i64*, i64** %data, i64 1
    %7 = tail call i8* @malloc(i64 32)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %"15", align 8
    store i64 2, i64* %8, align 8
    %cap7 = getelementptr i64, i64* %8, i64 1
    store i64 2, i64* %cap7, align 8
    %9 = getelementptr i8, i8* %7, i64 16
    %data8 = bitcast i8* %9 to i64*
    store i64 2, i64* %data8, align 8
    %"110" = getelementptr i64, i64* %data8, i64 1
    store i64 3, i64* %"110", align 8
    %10 = load i64**, i64*** @schmu_nested, align 8
    %11 = bitcast i64** %10 to i64*
    %12 = load i64, i64* %11, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %12)
    %13 = load i64**, i64*** @schmu_nested, align 8
    %14 = bitcast i64** %13 to i64*
    %size12 = load i64, i64* %14, align 8
    %15 = icmp sgt i64 %size12, 0
    br i1 %15, label %drop_last, label %cont
  
  drop_last:                                        ; preds = %entry
    %16 = bitcast i64** %13 to i64*
    %17 = sub i64 %size12, 1
    %18 = bitcast i64** %13 to i8*
    %19 = getelementptr i8, i8* %18, i64 16
    %data13 = bitcast i8* %19 to i64**
    %20 = getelementptr i64*, i64** %data13, i64 %17
    tail call void @__free_ai(i64** %20)
    store i64 %17, i64* %16, align 8
    %.pre = load i64**, i64*** @schmu_nested, align 8
    %.phi.trans.insert = bitcast i64** %.pre to i64*
    %.pre27 = load i64, i64* %.phi.trans.insert, align 8
    br label %cont
  
  cont:                                             ; preds = %drop_last, %entry
    %.pre-phi = phi i64* [ %.phi.trans.insert, %drop_last ], [ %14, %entry ]
    %21 = phi i64 [ %.pre27, %drop_last ], [ %size12, %entry ]
    %22 = phi i64** [ %.pre, %drop_last ], [ %13, %entry ]
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %21)
    %23 = load i64**, i64*** @schmu_nested, align 8
    %24 = bitcast i64** %23 to i64*
    %size16 = load i64, i64* %24, align 8
    %25 = icmp sgt i64 %size16, 0
    br i1 %25, label %drop_last17, label %cont18
  
  drop_last17:                                      ; preds = %cont
    %26 = bitcast i64** %23 to i64*
    %27 = sub i64 %size16, 1
    %28 = bitcast i64** %23 to i8*
    %29 = getelementptr i8, i8* %28, i64 16
    %data19 = bitcast i8* %29 to i64**
    %30 = getelementptr i64*, i64** %data19, i64 %27
    tail call void @__free_ai(i64** %30)
    store i64 %27, i64* %26, align 8
    %.pre28 = load i64**, i64*** @schmu_nested, align 8
    %.phi.trans.insert29 = bitcast i64** %.pre28 to i64*
    %.pre30 = load i64, i64* %.phi.trans.insert29, align 8
    br label %cont18
  
  cont18:                                           ; preds = %drop_last17, %cont
    %.pre-phi34 = phi i64* [ %.phi.trans.insert29, %drop_last17 ], [ %24, %cont ]
    %31 = phi i64 [ %.pre30, %drop_last17 ], [ %size16, %cont ]
    %32 = phi i64** [ %.pre28, %drop_last17 ], [ %23, %cont ]
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %31)
    %33 = load i64**, i64*** @schmu_nested, align 8
    %34 = bitcast i64** %33 to i64*
    %size22 = load i64, i64* %34, align 8
    %35 = icmp sgt i64 %size22, 0
    br i1 %35, label %drop_last23, label %cont24
  
  drop_last23:                                      ; preds = %cont18
    %36 = bitcast i64** %33 to i64*
    %37 = sub i64 %size22, 1
    %38 = bitcast i64** %33 to i8*
    %39 = getelementptr i8, i8* %38, i64 16
    %data25 = bitcast i8* %39 to i64**
    %40 = getelementptr i64*, i64** %data25, i64 %37
    tail call void @__free_ai(i64** %40)
    store i64 %37, i64* %36, align 8
    %.pre31 = load i64**, i64*** @schmu_nested, align 8
    %.phi.trans.insert32 = bitcast i64** %.pre31 to i64*
    %.pre33 = load i64, i64* %.phi.trans.insert32, align 8
    br label %cont24
  
  cont24:                                           ; preds = %drop_last23, %cont18
    %.pre-phi35 = phi i64* [ %.phi.trans.insert32, %drop_last23 ], [ %34, %cont18 ]
    %41 = phi i64 [ %.pre33, %drop_last23 ], [ %size22, %cont18 ]
    %42 = phi i64** [ %.pre31, %drop_last23 ], [ %33, %cont18 ]
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %41)
    tail call void @__free_aai(i64*** @schmu_nested)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast i64** %1 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data = bitcast i8* %5 to i64**
    %6 = getelementptr i64*, i64** %data, i64 %2
    call void @__free_ai(i64** %6)
    %7 = add i64 %2, 1
    store i64 %7, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast i64** %1 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    ret void
  }
  
  declare void @free(i8* %0)
  2
  1
  0
  0

Global lets with expressions
  $ schmu --dump-llvm global_let.smu && valgrind -q --leak-check=yes --show-reachable=yes ./global_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tai = type { i32, i64* }
  %rai = type { i64* }
  
  @schmu_a = internal constant %option.tai { i32 1, i64* undef }
  @schmu_b = global i64* null, align 8
  @schmu_c = global i64 0, align 8
  
  define void @schmu_ret_none(%option.tai* noalias %0) {
  entry:
    %1 = bitcast %option.tai* %0 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* bitcast (%option.tai* @schmu_a to i8*), i64 16, i1 false)
    ret void
  }
  
  define i64 @schmu_ret_rec() {
  entry:
    %0 = alloca %rai, align 8
    %a2 = bitcast %rai* %0 to i64**
    %1 = tail call i8* @malloc(i64 40)
    %2 = bitcast i8* %1 to i64*
    %arr = alloca i64*, align 8
    store i64* %2, i64** %arr, align 8
    store i64 3, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 3, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    %"2" = getelementptr i64, i64* %data, i64 2
    store i64 30, i64* %"2", align 8
    store i64* %2, i64** %a2, align 8
    %4 = ptrtoint i64* %2 to i64
    ret i64 %4
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i8* @malloc(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %ret = alloca %option.tai, align 8
    call void @schmu_ret_none(%option.tai* %ret)
    %tag5 = bitcast %option.tai* %ret to i32*
    %index = load i32, i32* %tag5, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tai, %option.tai* %ret, i32 0, i32 1
    br label %ifcont
  
  else:                                             ; preds = %entry
    %0 = call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @schmu_b, align 8
    store i64 2, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 2, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data1 = bitcast i8* %2 to i64*
    store i64 1, i64* %data1, align 8
    %"1" = getelementptr i64, i64* %data1, i64 1
    store i64 2, i64* %"1", align 8
    call void @__free_option.tai(%option.tai* %ret)
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi i64** [ %data, %then ], [ @schmu_b, %else ]
    %3 = load i64*, i64** %iftmp, align 8
    store i64* %3, i64** @schmu_b, align 8
    %ret2 = alloca %rai, align 8
    %4 = call i64 @schmu_ret_rec()
    %box = bitcast %rai* %ret2 to i64*
    store i64 %4, i64* %box, align 8
    %5 = inttoptr i64 %4 to i64*
    %6 = bitcast i64* %5 to i8*
    %7 = getelementptr i8, i8* %6, i64 16
    %data4 = bitcast i8* %7 to i64*
    %8 = getelementptr i64, i64* %data4, i64 1
    %9 = load i64, i64* %8, align 8
    store i64 %9, i64* @schmu_c, align 8
    call void @__free_rai(%rai* %ret2)
    call void @__free_ai(i64** @schmu_b)
    ret i64 0
  }
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_option.tai(%option.tai* %0) {
  entry:
    %tag1 = bitcast %option.tai* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.tai, %option.tai* %0, i32 0, i32 1
    call void @__free_ai(i64** %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_rai(%rai* %0) {
  entry:
    %1 = bitcast %rai* %0 to i64**
    call void @__free_ai(i64** %1)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Mutual recursive function
  $ schmu mutual_rec.smu && ./mutual_rec
  true
  false
  true

Polymorphic mutual recursive function
  $ schmu -m m2.smu
  $ schmu polymorphic_mutual_rec.smu && ./polymorphic_mutual_rec
  true
  false
  true
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  0
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  0
  right


Incr refcounts correctly in ifs
  $ schmu rc_ifs.smu && valgrind -q --leak-check=yes --show-reachable=yes ./rc_ifs

Incr refcounts correctly for closed over returns
  $ schmu rc_linear_closed_return.smu && valgrind -q --leak-check=yes --show-reachable=yes ./rc_linear_closed_return


Return nonclosure functions
  $ schmu --dump-llvm return_fn.smu && ./return_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_f = global %closure zeroinitializer, align 8
  @schmu_f__2 = global %closure zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @__fun_schmu0(i64 %a) {
  entry:
    %add = add i64 %a, 12
    ret i64 %add
  }
  
  define i64 @schmu_named(i64 %a) {
  entry:
    %add = add i64 %a, 13
    ret i64 %add
  }
  
  define void @schmu_ret_fn(%closure* noalias %0) {
  entry:
    %funptr1 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i64)* @__fun_schmu0 to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    ret void
  }
  
  define void @schmu_ret_named(%closure* noalias %0) {
  entry:
    %funptr1 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i64)* @schmu_named to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_ret_fn(%closure* @schmu_f)
    %loadtmp = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f, i32 0, i32 0), align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %loadtmp1 = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %casttmp(i64 12, i8* %loadtmp1)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %0)
    tail call void @schmu_ret_named(%closure* @schmu_f__2)
    %loadtmp2 = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f__2, i32 0, i32 0), align 8
    %casttmp3 = bitcast i8* %loadtmp2 to i64 (i64, i8*)*
    %loadtmp4 = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f__2, i32 0, i32 1), align 8
    %1 = tail call i64 %casttmp3(i64 12, i8* %loadtmp4)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %1)
    tail call void @__free_i.i(%closure* @schmu_f__2)
    tail call void @__free_i.i(%closure* @schmu_f)
    ret i64 0
  }
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr void @__free_i.i(%closure* %0) {
  entry:
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %env = load i8*, i8** %envptr, align 8
    %1 = icmp eq i8* %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = bitcast i8* %env to { i8*, i8* }*
    %3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %2, i32 0, i32 1
    %dtor1 = load i8*, i8** %3, align 8
    %4 = icmp eq i8* %dtor1, null
    br i1 %4, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    %dtor2 = bitcast i8* %dtor1 to void (i8*)*
    call void %dtor2(i8* %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(i8* %env)
    br label %ret
  }
  
  declare void @free(i8* %0)
  24
  25

Return closures
  $ schmu --dump-llvm return_closure.smu && valgrind -q --leak-check=yes --show-reachable=yes ./return_closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_f = global %closure zeroinitializer, align 8
  @schmu_f2 = global %closure zeroinitializer, align 8
  @schmu_f__2 = global %closure zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @__fun_schmu0(i64 %a, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64 }*
    %b = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr, i32 0, i32 2
    %b1 = load i64, i64* %b, align 8
    %add = add i64 %a, %b1
    ret i64 %add
  }
  
  define i64 @schmu_bla(i64 %a, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64 }*
    %b = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr, i32 0, i32 2
    %b1 = load i64, i64* %b, align 8
    %add = add i64 %a, %b1
    ret i64 %add
  }
  
  define void @schmu_ret_fn(%closure* noalias %0, i64 %b) {
  entry:
    %funptr2 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i64, i8*)* @schmu_bla to i8*), i8** %funptr2, align 8
    %1 = tail call i8* @malloc(i64 24)
    %clsr_schmu_bla = bitcast i8* %1 to { i8*, i8*, i64 }*
    %b1 = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr_schmu_bla, i32 0, i32 2
    store i64 %b, i64* %b1, align 8
    %ctor3 = bitcast { i8*, i8*, i64 }* %clsr_schmu_bla to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-i to i8*), i8** %ctor3, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr_schmu_bla, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %1, i8** %envptr, align 8
    ret void
  }
  
  define void @schmu_ret_lambda(%closure* noalias %0, i64 %b) {
  entry:
    %funptr2 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i64, i8*)* @__fun_schmu0 to i8*), i8** %funptr2, align 8
    %1 = tail call i8* @malloc(i64 24)
    %clsr___fun_schmu0 = bitcast i8* %1 to { i8*, i8*, i64 }*
    %b1 = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr___fun_schmu0, i32 0, i32 2
    store i64 %b, i64* %b1, align 8
    %ctor3 = bitcast { i8*, i8*, i64 }* %clsr___fun_schmu0 to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-i to i8*), i8** %ctor3, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr___fun_schmu0, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %1, i8** %envptr, align 8
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr i8* @__ctor_tup-i(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64 }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, i64 }*
    %4 = bitcast { i8*, i8*, i64 }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64 }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %6 = bitcast { i8*, i8*, i64 }* %3 to i8*
    ret i8* %6
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_ret_fn(%closure* @schmu_f, i64 13)
    tail call void @schmu_ret_fn(%closure* @schmu_f2, i64 35)
    %loadtmp = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f, i32 0, i32 0), align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %loadtmp1 = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %casttmp(i64 12, i8* %loadtmp1)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %0)
    %loadtmp2 = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f2, i32 0, i32 0), align 8
    %casttmp3 = bitcast i8* %loadtmp2 to i64 (i64, i8*)*
    %loadtmp4 = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f2, i32 0, i32 1), align 8
    %1 = tail call i64 %casttmp3(i64 12, i8* %loadtmp4)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %1)
    tail call void @schmu_ret_lambda(%closure* @schmu_f__2, i64 134)
    %loadtmp5 = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f__2, i32 0, i32 0), align 8
    %casttmp6 = bitcast i8* %loadtmp5 to i64 (i64, i8*)*
    %loadtmp7 = load i8*, i8** getelementptr inbounds (%closure, %closure* @schmu_f__2, i32 0, i32 1), align 8
    %2 = tail call i64 %casttmp6(i64 12, i8* %loadtmp7)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %2)
    tail call void @__free_i.i(%closure* @schmu_f__2)
    tail call void @__free_i.i(%closure* @schmu_f2)
    tail call void @__free_i.i(%closure* @schmu_f)
    ret i64 0
  }
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr void @__free_i.i(%closure* %0) {
  entry:
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %env = load i8*, i8** %envptr, align 8
    %1 = icmp eq i8* %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = bitcast i8* %env to { i8*, i8* }*
    %3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %2, i32 0, i32 1
    %dtor1 = load i8*, i8** %3, align 8
    %4 = icmp eq i8* %dtor1, null
    br i1 %4, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    %dtor2 = bitcast i8* %dtor1 to void (i8*)*
    call void %dtor2(i8* %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(i8* %env)
    br label %ret
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  25
  47
  146

Don't try to free string literals in ifs
  $ schmu incr_str_lit_ifs.smu && valgrind -q --leak-check=yes --show-reachable=yes ./incr_str_lit_ifs
  none
  none

Mutable variables in upward closures
  $ schmu upward_mut.smu && valgrind -q --leak-check=yes --show-reachable=yes ./upward_mut
  1
  2
  3
  4
  1
  2
  3
  4

Functions in arrays
  $ schmu function_array.smu && valgrind -q --leak-check=yes --show-reachable=yes ./function_array

Take/use not all allocations of a record in tailrec calls
  $ schmu --dump-llvm take_partial_alloc.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %view = type { i8*, i64, i64 }
  %parse_resulti = type { i32, %successi }
  %successi = type { %view, i64 }
  %parse_resultview = type { i32, %successview }
  %successview = type { %view, %view }
  
  @schmu_s = global i8* null, align 8
  @schmu_inp = global %view zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c" \00" }
  
  declare i1 @prelude_char_equal(i8 %0, i8 %1)
  
  declare i64 @string_len(i8* %0)
  
  declare i8 @string_get(i8* %0, i64 %1)
  
  define void @schmu_aux(%parse_resulti* noalias %0, %view* %rem, i64 %cnt) {
  entry:
    %1 = alloca %view, align 8
    %2 = bitcast %view* %1 to i8*
    %3 = bitcast %view* %rem to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 24, i1 false)
    %4 = alloca i1, align 1
    store i1 false, i1* %4, align 1
    %5 = alloca i64, align 8
    store i64 %cnt, i64* %5, align 8
    %ret = alloca %parse_resultview, align 8
    br label %rec
  
  rec:                                              ; preds = %cont, %entry
    %6 = phi i1 [ true, %cont ], [ false, %entry ]
    %7 = phi i64 [ %add, %cont ], [ %cnt, %entry ]
    call void @schmu_ch(%parse_resultview* %ret, %view* %1)
    %tag8 = bitcast %parse_resultview* %ret to i32*
    %index = load i32, i32* %tag8, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %data = getelementptr inbounds %parse_resultview, %parse_resultview* %ret, i32 0, i32 1
    %add = add i64 %7, 1
    call void @__free_except0_successview(%successview* %data)
    br i1 %6, label %call_decr, label %cookie
  
  call_decr:                                        ; preds = %then
    call void @__free_view(%view* %1)
    br label %cont
  
  cookie:                                           ; preds = %then
    store i1 true, i1* %4, align 1
    br label %cont
  
  cont:                                             ; preds = %cookie, %call_decr
    %8 = bitcast %successview* %data to %view*
    %9 = bitcast %view* %1 to i8*
    %10 = bitcast %view* %8 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 24, i1 false)
    store i64 %add, i64* %5, align 8
    br label %rec
  
  else:                                             ; preds = %rec
    %11 = bitcast %view* %1 to i8*
    %data1 = getelementptr inbounds %parse_resultview, %parse_resultview* %ret, i32 0, i32 1
    %tag29 = bitcast %parse_resulti* %0 to i32*
    store i32 0, i32* %tag29, align 4
    %data3 = getelementptr inbounds %parse_resulti, %parse_resulti* %0, i32 0, i32 1
    %rem410 = bitcast %successi* %data3 to %view*
    %12 = bitcast %view* %rem410 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %12, i8* %11, i64 24, i1 false)
    call void @__copy_view(%view* %rem410)
    %mtch = getelementptr inbounds %successi, %successi* %data3, i32 0, i32 1
    store i64 %7, i64* %mtch, align 8
    call void @__free_parse_resultview(%parse_resultview* %ret)
    br i1 %6, label %call_decr5, label %cookie6
  
  call_decr5:                                       ; preds = %else
    call void @__free_view(%view* %1)
    br label %cont7
  
  cookie6:                                          ; preds = %else
    store i1 true, i1* %4, align 1
    br label %cont7
  
  cont7:                                            ; preds = %cookie6, %call_decr5
    ret void
  }
  
  define void @schmu_ch(%parse_resultview* noalias %0, %view* %buf) {
  entry:
    %1 = bitcast %view* %buf to i8**
    %2 = load i8*, i8** %1, align 8
    %3 = getelementptr inbounds %view, %view* %buf, i32 0, i32 1
    %4 = load i64, i64* %3, align 8
    %5 = tail call i8 @string_get(i8* %2, i64 %4)
    %6 = tail call i1 @prelude_char_equal(i8 %5, i8 32)
    br i1 %6, label %then, label %else
  
  then:                                             ; preds = %entry
    %7 = bitcast %view* %buf to i8**
    %tag8 = bitcast %parse_resultview* %0 to i32*
    store i32 0, i32* %tag8, align 4
    %data = getelementptr inbounds %parse_resultview, %parse_resultview* %0, i32 0, i32 1
    %rem9 = bitcast %successview* %data to %view*
    %buf110 = bitcast %view* %rem9 to i8**
    %8 = alloca i8*, align 8
    %9 = bitcast i8** %8 to i8*
    %10 = bitcast i8** %7 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 8, i1 false)
    call void @__copy_ac(i8** %8)
    %11 = load i8*, i8** %8, align 8
    store i8* %11, i8** %buf110, align 8
    %start = getelementptr inbounds %view, %view* %rem9, i32 0, i32 1
    %12 = bitcast %view* %buf to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %12, i64 8
    %13 = bitcast i8* %sunkaddr to i64*
    %14 = load i64, i64* %13, align 8
    %add = add i64 %14, 1
    store i64 %add, i64* %start, align 8
    %len = getelementptr inbounds %view, %view* %rem9, i32 0, i32 2
    %15 = getelementptr inbounds %view, %view* %buf, i32 0, i32 2
    %16 = load i64, i64* %15, align 8
    %sub = sub i64 %16, 1
    store i64 %sub, i64* %len, align 8
    %mtch = getelementptr inbounds %successview, %successview* %data, i32 0, i32 1
    %buf211 = bitcast %view* %mtch to i8**
    %17 = alloca i8*, align 8
    %18 = bitcast i8** %17 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %18, i8* %10, i64 8, i1 false)
    call void @__copy_ac(i8** %17)
    %19 = load i8*, i8** %17, align 8
    store i8* %19, i8** %buf211, align 8
    %start3 = getelementptr inbounds %view, %view* %mtch, i32 0, i32 1
    %20 = load i64, i64* %13, align 8
    store i64 %20, i64* %start3, align 8
    %len4 = getelementptr inbounds %view, %view* %mtch, i32 0, i32 2
    store i64 1, i64* %len4, align 8
    ret void
  
  else:                                             ; preds = %entry
    %tag512 = bitcast %parse_resultview* %0 to i32*
    store i32 1, i32* %tag512, align 4
    %data6 = getelementptr inbounds %parse_resultview, %parse_resultview* %0, i32 0, i32 1
    %21 = bitcast %successview* %data6 to %view*
    %22 = bitcast %view* %21 to i8*
    %23 = bitcast %view* %buf to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %22, i8* %23, i64 24, i1 false)
    tail call void @__copy_view(%view* %21)
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %22, i8* %22, i64 24, i1 false)
    ret void
  }
  
  define void @schmu_many_count(%parse_resulti* noalias %0, %view* %buf) {
  entry:
    tail call void @schmu_aux(%parse_resulti* %0, %view* %buf, i64 0)
    ret void
  }
  
  define void @schmu_view_of_string(%view* noalias %0, i8* %str) {
  entry:
    %buf1 = bitcast %view* %0 to i8**
    %1 = alloca i8*, align 8
    store i8* %str, i8** %1, align 8
    %2 = alloca i8*, align 8
    %3 = bitcast i8** %2 to i8*
    %4 = bitcast i8** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 8, i1 false)
    call void @__copy_ac(i8** %2)
    %5 = load i8*, i8** %2, align 8
    store i8* %5, i8** %buf1, align 8
    %start = getelementptr inbounds %view, %view* %0, i32 0, i32 1
    store i64 0, i64* %start, align 8
    %len = getelementptr inbounds %view, %view* %0, i32 0, i32 2
    %6 = call i64 @string_len(i8* %str)
    store i64 %6, i64* %len, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_view(%view* %0) {
  entry:
    %1 = bitcast %view* %0 to i8**
    call void @__free_ac(i8** %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_except0_successview(%successview* %0) {
  entry:
    %1 = getelementptr inbounds %successview, %successview* %0, i32 0, i32 1
    call void @__free_view(%view* %1)
    ret void
  }
  
  define linkonce_odr void @__copy_ac(i8** %0) {
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
  
  define linkonce_odr void @__copy_view(%view* %0) {
  entry:
    %1 = bitcast %view* %0 to i8**
    call void @__copy_ac(i8** %1)
    ret void
  }
  
  define linkonce_odr void @__free_successview(%successview* %0) {
  entry:
    %1 = bitcast %successview* %0 to %view*
    call void @__free_view(%view* %1)
    %2 = getelementptr inbounds %successview, %successview* %0, i32 0, i32 1
    call void @__free_view(%view* %2)
    ret void
  }
  
  define linkonce_odr void @__free_parse_resultview(%parse_resultview* %0) {
  entry:
    %tag4 = bitcast %parse_resultview* %0 to i32*
    %index = load i32, i32* %tag4, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse_resultview, %parse_resultview* %0, i32 0, i32 1
    call void @__free_successview(%successview* %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    %2 = icmp eq i32 %index, 1
    br i1 %2, label %match1, label %cont2
  
  match1:                                           ; preds = %cont
    %data3 = getelementptr inbounds %parse_resultview, %parse_resultview* %0, i32 0, i32 1
    %3 = bitcast %successview* %data3 to %view*
    call void @__free_view(%view* %3)
    br label %cont2
  
  cont2:                                            ; preds = %match1, %cont
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, [2 x i8] }* @0 to i8*), i64 16))
    %0 = add i32 %fmtsize, 17
    %1 = sext i32 %0 to i64
    %2 = tail call i8* @malloc(i64 %1)
    %3 = bitcast i8* %2 to i64*
    %4 = sext i32 %fmtsize to i64
    store i64 %4, i64* %3, align 8
    %cap = getelementptr i64, i64* %3, i64 1
    store i64 %4, i64* %cap, align 8
    %data = getelementptr i64, i64* %3, i64 2
    %5 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %1, i8* getelementptr (i8, i8* bitcast ({ i64, i64, [2 x i8] }* @0 to i8*), i64 16))
    store i8* %2, i8** @schmu_s, align 8
    tail call void @schmu_view_of_string(%view* @schmu_inp, i8* %2)
    %ret = alloca %parse_resulti, align 8
    call void @schmu_many_count(%parse_resulti* %ret, %view* @schmu_inp)
    call void @__free_parse_resulti(%parse_resulti* %ret)
    call void @__free_view(%view* @schmu_inp)
    call void @__free_ac(i8** @schmu_s)
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__free_successi(%successi* %0) {
  entry:
    %1 = bitcast %successi* %0 to %view*
    call void @__free_view(%view* %1)
    ret void
  }
  
  define linkonce_odr void @__free_parse_resulti(%parse_resulti* %0) {
  entry:
    %tag4 = bitcast %parse_resulti* %0 to i32*
    %index = load i32, i32* %tag4, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse_resulti, %parse_resulti* %0, i32 0, i32 1
    call void @__free_successi(%successi* %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    %2 = icmp eq i32 %index, 1
    br i1 %2, label %match1, label %cont2
  
  match1:                                           ; preds = %cont
    %data3 = getelementptr inbounds %parse_resulti, %parse_resulti* %0, i32 0, i32 1
    %3 = bitcast %successi* %data3 to %view*
    call void @__free_view(%view* %3)
    br label %cont2
  
  cont2:                                            ; preds = %match1, %cont
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  $ valgrind -q --leak-check=yes --show-reachable=yes ./take_partial_alloc

Take/use not all allocations of a record in tailrec calls, different order for pattern matches
  $ schmu take_partial_alloc_reorder.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./take_partial_alloc_reorder

Increase refcount for returned params in ifs
  $ schmu --dump-llvm if_ret_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./if_ret_param
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"/\00" }
  @schmu_s = constant i8* bitcast ({ i64, i64, [2 x i8] }* @0 to i8*)
  @1 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"/%s\00" }
  
  define void @schmu_inner(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %closure, i64 }*
    %limit = getelementptr inbounds { i8*, i8*, %closure, i64 }, { i8*, i8*, %closure, i64 }* %clsr, i32 0, i32 3
    %limit1 = load i64, i64* %limit, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = add i64 %i, 1
    %3 = sub i64 0, %limit1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %4 = add i64 %3, %lsr.iv
    %eq = icmp eq i64 %4, 1
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %5 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %5, align 8
    %casttmp = bitcast i8* %loadtmp to void (i8*, i8*)*
    %sunkaddr4 = getelementptr inbounds i8, i8* %0, i64 24
    %6 = bitcast i8* %sunkaddr4 to i8**
    %loadtmp2 = load i8*, i8** %6, align 8
    tail call void %casttmp(i8* bitcast ({ i64, i64, [2 x i8] }* @0 to i8*), i8* %loadtmp2)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(i8* %value) {
  entry:
    %0 = alloca i8*, align 8
    store i8* %value, i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac(i8** %1)
    call void @__free_ac(i8** %1)
    ret void
  }
  
  define void @schmu_times(i64 %limit, %closure* %f) {
  entry:
    %schmu_inner = alloca %closure, align 8
    %funptr5 = bitcast %closure* %schmu_inner to i8**
    store i8* bitcast (void (i64, i8*)* @schmu_inner to i8*), i8** %funptr5, align 8
    %clsr_schmu_inner = alloca { i8*, i8*, %closure, i64 }, align 8
    %f1 = getelementptr inbounds { i8*, i8*, %closure, i64 }, { i8*, i8*, %closure, i64 }* %clsr_schmu_inner, i32 0, i32 2
    %0 = bitcast %closure* %f1 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %limit2 = getelementptr inbounds { i8*, i8*, %closure, i64 }, { i8*, i8*, %closure, i64 }* %clsr_schmu_inner, i32 0, i32 3
    store i64 %limit, i64* %limit2, align 8
    %ctor6 = bitcast { i8*, i8*, %closure, i64 }* %clsr_schmu_inner to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ac.u-i to i8*), i8** %ctor6, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %closure, i64 }, { i8*, i8*, %closure, i64 }* %clsr_schmu_inner, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %closure, i64 }* %clsr_schmu_inner to i8*
    %envptr = getelementptr inbounds %closure, %closure* %schmu_inner, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu_inner(i64 0, i8* %env)
    ret void
  }
  
  define linkonce_odr void @__copy_ac(i8** %0) {
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
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__free_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr i8* @__ctor_tup-ac.u-i(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %closure, i64 }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, %closure, i64 }*
    %4 = bitcast { i8*, i8*, %closure, i64 }* %3 to i8*
    %5 = bitcast { i8*, i8*, %closure, i64 }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %f = getelementptr inbounds { i8*, i8*, %closure, i64 }, { i8*, i8*, %closure, i64 }* %3, i32 0, i32 2
    call void @__copy_ac.u(%closure* %f)
    %6 = bitcast { i8*, i8*, %closure, i64 }* %3 to i8*
    ret i8* %6
  }
  
  define linkonce_odr void @__copy_ac.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr1 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i8*)* @schmu_test to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu_times(i64 2, %closure* %clstmp)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Monomorphization in closures
  $ schmu --dump-llvm closure_monomorph.smu && ./closure_monomorph
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_arr = global i64* null, align 8
  @schmu_arr__2 = global i64* null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, %closure* %2)
  
  define linkonce_odr void @____fun_schmu0_i.u-ai-ii.i-i-i(i64 %j, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64**, %closure, i64*, i64 }*
    %arr = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 2
    %arr1 = load i64**, i64*** %arr, align 8
    %cmp = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 3
    %i = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 4
    %i2 = load i64*, i64** %i, align 8
    %pivot = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 5
    %pivot3 = load i64, i64* %pivot, align 8
    %1 = load i64*, i64** %arr1, align 8
    %2 = bitcast i64* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to i64*
    %4 = getelementptr i64, i64* %data, i64 %j
    %5 = load i64, i64* %4, align 8
    %funcptr5 = bitcast %closure* %cmp to i8**
    %loadtmp = load i8*, i8** %funcptr5, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %cmp, i32 0, i32 1
    %loadtmp4 = load i8*, i8** %envptr, align 8
    %6 = tail call i64 %casttmp(i64 %5, i64 %pivot3, i8* %loadtmp4)
    %lt = icmp slt i64 %6, 0
    br i1 %lt, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %7 = load i64, i64* %i2, align 8
    %add = add i64 %7, 1
    store i64 %add, i64* %i2, align 8
    tail call void @__array_swap_items_aiii.u(i64** %arr1, i64 %add, i64 %j)
    ret void
  
  ifcont:                                           ; preds = %entry
    ret void
  }
  
  define linkonce_odr void @____fun_schmu3_i.u-ai-ii.i-i-i(i64 %j, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64**, %closure, i64*, i64 }*
    %arr = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 2
    %arr1 = load i64**, i64*** %arr, align 8
    %cmp = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 3
    %i = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 4
    %i2 = load i64*, i64** %i, align 8
    %pivot = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 5
    %pivot3 = load i64, i64* %pivot, align 8
    %1 = load i64*, i64** %arr1, align 8
    %2 = bitcast i64* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to i64*
    %4 = getelementptr i64, i64* %data, i64 %j
    %5 = load i64, i64* %4, align 8
    %funcptr5 = bitcast %closure* %cmp to i8**
    %loadtmp = load i8*, i8** %funcptr5, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %cmp, i32 0, i32 1
    %loadtmp4 = load i8*, i8** %envptr, align 8
    %6 = tail call i64 %casttmp(i64 %5, i64 %pivot3, i8* %loadtmp4)
    %lt = icmp slt i64 %6, 0
    br i1 %lt, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %7 = load i64, i64* %i2, align 8
    %add = add i64 %7, 1
    store i64 %add, i64* %i2, align 8
    tail call void @__array_swap_items_aiii.u(i64** %arr1, i64 %add, i64 %j)
    ret void
  
  ifcont:                                           ; preds = %entry
    ret void
  }
  
  define linkonce_odr void @__array_inner_i.u-ai-i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64*, %closure }*
    %arr = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %3 = add i64 %lsr.iv, -1
    %4 = load i64, i64* %arr1, align 8
    %eq = icmp eq i64 %3, %4
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %scevgep = getelementptr i64, i64* %arr1, i64 %lsr.iv
    %scevgep3 = getelementptr i64, i64* %scevgep, i64 1
    %5 = load i64, i64* %scevgep3, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 24
    %6 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %6, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %sunkaddr5 = getelementptr inbounds i8, i8* %0, i64 32
    %7 = bitcast i8* %sunkaddr5 to i8**
    %loadtmp2 = load i8*, i8** %7, align 8
    tail call void %casttmp(i64 %5, i8* %loadtmp2)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr void @__array_iter_aii.u.u(i64* %arr, %closure* %f) {
  entry:
    %__array_inner_i.u-ai-i.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__array_inner_i.u-ai-i.u to i8**
    store i8* bitcast (void (i64, i8*)* @__array_inner_i.u-ai-i.u to i8*), i8** %funptr5, align 8
    %clsr___array_inner_i.u-ai-i.u = alloca { i8*, i8*, i64*, %closure }, align 8
    %arr1 = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u, i32 0, i32 2
    store i64* %arr, i64** %arr1, align 8
    %f2 = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor6 = bitcast { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ai-i.u to i8*), i8** %ctor6, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__array_inner_i.u-ai-i.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__array_inner_i.u-ai-i.u(i64 0, i8* %env)
    ret void
  }
  
  define linkonce_odr void @__array_swap_items_aiii.u(i64** noalias %arr, i64 %i, i64 %j) {
  entry:
    %eq = icmp eq i64 %i, %j
    %0 = xor i1 %eq, true
    br i1 %0, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %1 = alloca i64, align 8
    %2 = load i64*, i64** %arr, align 8
    %3 = bitcast i64* %2 to i8*
    %4 = getelementptr i8, i8* %3, i64 16
    %data = bitcast i8* %4 to i64*
    %5 = getelementptr i64, i64* %data, i64 %i
    %6 = load i64, i64* %5, align 8
    store i64 %6, i64* %1, align 8
    %7 = getelementptr i64, i64* %data, i64 %j
    %8 = load i64, i64* %7, align 8
    store i64 %8, i64* %5, align 8
    store i64 %6, i64* %7, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret void
  }
  
  define i64 @__fun_schmu1(i64 %a, i64 %b) {
  entry:
    %sub = sub i64 %a, %b
    ret i64 %sub
  }
  
  define void @__fun_schmu2(i64 %i) {
  entry:
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %i)
    ret void
  }
  
  define i64 @__fun_schmu4(i64 %a, i64 %b) {
  entry:
    %sub = sub i64 %a, %b
    ret i64 %sub
  }
  
  define void @__fun_schmu5(i64 %i) {
  entry:
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %i)
    ret void
  }
  
  define linkonce_odr i64 @__schmu_partition__2_aiii.i-ii.i(i64** noalias %arr, i64 %lo, i64 %hi, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %closure }*
    %cmp = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr, i32 0, i32 2
    %1 = load i64*, i64** %arr, align 8
    %2 = bitcast i64* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to i64*
    %4 = getelementptr i64, i64* %data, i64 %hi
    %5 = alloca i64, align 8
    %6 = load i64, i64* %4, align 8
    store i64 %6, i64* %5, align 8
    %7 = alloca i64, align 8
    %sub = sub i64 %lo, 1
    store i64 %sub, i64* %7, align 8
    %____fun_schmu3_i.u-ai-ii.i-i-i = alloca %closure, align 8
    %funptr3 = bitcast %closure* %____fun_schmu3_i.u-ai-ii.i-i-i to i8**
    store i8* bitcast (void (i64, i8*)* @____fun_schmu3_i.u-ai-ii.i-i-i to i8*), i8** %funptr3, align 8
    %clsr_____fun_schmu3_i.u-ai-ii.i-i-i = alloca { i8*, i8*, i64**, %closure, i64*, i64 }, align 8
    %arr1 = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu3_i.u-ai-ii.i-i-i, i32 0, i32 2
    store i64** %arr, i64*** %arr1, align 8
    %cmp2 = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu3_i.u-ai-ii.i-i-i, i32 0, i32 3
    %8 = bitcast %closure* %cmp2 to i8*
    %9 = bitcast %closure* %cmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 16, i1 false)
    %i = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu3_i.u-ai-ii.i-i-i, i32 0, i32 4
    store i64* %7, i64** %i, align 8
    %pivot = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu3_i.u-ai-ii.i-i-i, i32 0, i32 5
    store i64 %6, i64* %pivot, align 8
    %ctor4 = bitcast { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu3_i.u-ai-ii.i-i-i to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ai-ii.i-i-i to i8*), i8** %ctor4, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu3_i.u-ai-ii.i-i-i, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu3_i.u-ai-ii.i-i-i to i8*
    %envptr = getelementptr inbounds %closure, %closure* %____fun_schmu3_i.u-ai-ii.i-i-i, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, %closure* %____fun_schmu3_i.u-ai-ii.i-i-i)
    %10 = load i64, i64* %7, align 8
    %add = add i64 %10, 1
    call void @__array_swap_items_aiii.u(i64** %arr, i64 %add, i64 %hi)
    ret i64 %add
  }
  
  define linkonce_odr i64 @__schmu_partition_aiii.i-ii.i(i64** noalias %arr, i64 %lo, i64 %hi, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %closure }*
    %cmp = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr, i32 0, i32 2
    %1 = load i64*, i64** %arr, align 8
    %2 = bitcast i64* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to i64*
    %4 = getelementptr i64, i64* %data, i64 %hi
    %5 = alloca i64, align 8
    %6 = load i64, i64* %4, align 8
    store i64 %6, i64* %5, align 8
    %7 = alloca i64, align 8
    %sub = sub i64 %lo, 1
    store i64 %sub, i64* %7, align 8
    %____fun_schmu0_i.u-ai-ii.i-i-i = alloca %closure, align 8
    %funptr3 = bitcast %closure* %____fun_schmu0_i.u-ai-ii.i-i-i to i8**
    store i8* bitcast (void (i64, i8*)* @____fun_schmu0_i.u-ai-ii.i-i-i to i8*), i8** %funptr3, align 8
    %clsr_____fun_schmu0_i.u-ai-ii.i-i-i = alloca { i8*, i8*, i64**, %closure, i64*, i64 }, align 8
    %arr1 = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu0_i.u-ai-ii.i-i-i, i32 0, i32 2
    store i64** %arr, i64*** %arr1, align 8
    %cmp2 = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu0_i.u-ai-ii.i-i-i, i32 0, i32 3
    %8 = bitcast %closure* %cmp2 to i8*
    %9 = bitcast %closure* %cmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 16, i1 false)
    %i = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu0_i.u-ai-ii.i-i-i, i32 0, i32 4
    store i64* %7, i64** %i, align 8
    %pivot = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu0_i.u-ai-ii.i-i-i, i32 0, i32 5
    store i64 %6, i64* %pivot, align 8
    %ctor4 = bitcast { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu0_i.u-ai-ii.i-i-i to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ai-ii.i-i-i to i8*), i8** %ctor4, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu0_i.u-ai-ii.i-i-i, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i64**, %closure, i64*, i64 }* %clsr_____fun_schmu0_i.u-ai-ii.i-i-i to i8*
    %envptr = getelementptr inbounds %closure, %closure* %____fun_schmu0_i.u-ai-ii.i-i-i, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, %closure* %____fun_schmu0_i.u-ai-ii.i-i-i)
    %10 = load i64, i64* %7, align 8
    %add = add i64 %10, 1
    call void @__array_swap_items_aiii.u(i64** %arr, i64 %add, i64 %hi)
    ret i64 %add
  }
  
  define linkonce_odr void @__schmu_quicksort__2_aiii.u-aiii.i-ii.i(i64** noalias %arr, i64 %lo, i64 %hi, i8* %0) {
  entry:
    %1 = alloca i64**, align 8
    store i64** %arr, i64*** %1, align 8
    %2 = alloca i1, align 1
    store i1 false, i1* %2, align 1
    %3 = alloca i64, align 8
    store i64 %lo, i64* %3, align 8
    %4 = alloca i64, align 8
    store i64 %hi, i64* %4, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %5 = phi i64 [ %add, %else ], [ %lo, %entry ]
    %lt = icmp slt i64 %5, %hi
    %6 = xor i1 %lt, true
    br i1 %6, label %cont, label %false1
  
  false1:                                           ; preds = %rec
    %lt2 = icmp slt i64 %5, 0
    br i1 %lt2, label %cont, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont
  
  cont:                                             ; preds = %false2, %false1, %rec
    %andtmp = phi i1 [ true, %rec ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp, label %then, label %else
  
  then:                                             ; preds = %cont
    store i1 true, i1* %2, align 1
    ret void
  
  else:                                             ; preds = %cont
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %7 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %7, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64**, i64, i64, i8*)*
    %sunkaddr7 = getelementptr inbounds i8, i8* %0, i64 24
    %8 = bitcast i8* %sunkaddr7 to i8**
    %loadtmp3 = load i8*, i8** %8, align 8
    %9 = tail call i64 %casttmp(i64** %arr, i64 %5, i64 %hi, i8* %loadtmp3)
    %sub = sub i64 %9, 1
    tail call void @__schmu_quicksort__2_aiii.u-aiii.i-ii.i(i64** %arr, i64 %5, i64 %sub, i8* %0)
    %add = add i64 %9, 1
    store i64** %arr, i64*** %1, align 8
    store i64 %add, i64* %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_quicksort_aiii.u-aiii.i-ii.i(i64** noalias %arr, i64 %lo, i64 %hi, i8* %0) {
  entry:
    %1 = alloca i64**, align 8
    store i64** %arr, i64*** %1, align 8
    %2 = alloca i1, align 1
    store i1 false, i1* %2, align 1
    %3 = alloca i64, align 8
    store i64 %lo, i64* %3, align 8
    %4 = alloca i64, align 8
    store i64 %hi, i64* %4, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %5 = phi i64 [ %add, %else ], [ %lo, %entry ]
    %lt = icmp slt i64 %5, %hi
    %6 = xor i1 %lt, true
    br i1 %6, label %cont, label %false1
  
  false1:                                           ; preds = %rec
    %lt2 = icmp slt i64 %5, 0
    br i1 %lt2, label %cont, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont
  
  cont:                                             ; preds = %false2, %false1, %rec
    %andtmp = phi i1 [ true, %rec ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp, label %then, label %else
  
  then:                                             ; preds = %cont
    store i1 true, i1* %2, align 1
    ret void
  
  else:                                             ; preds = %cont
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %7 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %7, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64**, i64, i64, i8*)*
    %sunkaddr7 = getelementptr inbounds i8, i8* %0, i64 24
    %8 = bitcast i8* %sunkaddr7 to i8**
    %loadtmp3 = load i8*, i8** %8, align 8
    %9 = tail call i64 %casttmp(i64** %arr, i64 %5, i64 %hi, i8* %loadtmp3)
    %sub = sub i64 %9, 1
    tail call void @__schmu_quicksort_aiii.u-aiii.i-ii.i(i64** %arr, i64 %5, i64 %sub, i8* %0)
    %add = add i64 %9, 1
    store i64** %arr, i64*** %1, align 8
    store i64 %add, i64* %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_sort__2_aiii.i.u(i64** noalias %arr, %closure* %cmp) {
  entry:
    %__schmu_partition__2_aiii.i-ii.i = alloca %closure, align 8
    %funptr10 = bitcast %closure* %__schmu_partition__2_aiii.i-ii.i to i8**
    store i8* bitcast (i64 (i64**, i64, i64, i8*)* @__schmu_partition__2_aiii.i-ii.i to i8*), i8** %funptr10, align 8
    %clsr___schmu_partition__2_aiii.i-ii.i = alloca { i8*, i8*, %closure }, align 8
    %cmp1 = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___schmu_partition__2_aiii.i-ii.i, i32 0, i32 2
    %0 = bitcast %closure* %cmp1 to i8*
    %1 = bitcast %closure* %cmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor11 = bitcast { i8*, i8*, %closure }* %clsr___schmu_partition__2_aiii.i-ii.i to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ii.i to i8*), i8** %ctor11, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___schmu_partition__2_aiii.i-ii.i, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %closure }* %clsr___schmu_partition__2_aiii.i-ii.i to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__schmu_partition__2_aiii.i-ii.i, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %__schmu_quicksort__2_aiii.u-aiii.i-ii.i = alloca %closure, align 8
    %funptr212 = bitcast %closure* %__schmu_quicksort__2_aiii.u-aiii.i-ii.i to i8**
    store i8* bitcast (void (i64**, i64, i64, i8*)* @__schmu_quicksort__2_aiii.u-aiii.i-ii.i to i8*), i8** %funptr212, align 8
    %clsr___schmu_quicksort__2_aiii.u-aiii.i-ii.i = alloca { i8*, i8*, %closure }, align 8
    %__schmu_partition__2_aiii.i-ii.i3 = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___schmu_quicksort__2_aiii.u-aiii.i-ii.i, i32 0, i32 2
    %2 = bitcast %closure* %__schmu_partition__2_aiii.i-ii.i3 to i8*
    %3 = bitcast %closure* %__schmu_partition__2_aiii.i-ii.i to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 16, i1 false)
    %ctor413 = bitcast { i8*, i8*, %closure }* %clsr___schmu_quicksort__2_aiii.u-aiii.i-ii.i to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-aiii.i to i8*), i8** %ctor413, align 8
    %dtor5 = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___schmu_quicksort__2_aiii.u-aiii.i-ii.i, i32 0, i32 1
    store i8* null, i8** %dtor5, align 8
    %env6 = bitcast { i8*, i8*, %closure }* %clsr___schmu_quicksort__2_aiii.u-aiii.i-ii.i to i8*
    %envptr7 = getelementptr inbounds %closure, %closure* %__schmu_quicksort__2_aiii.u-aiii.i-ii.i, i32 0, i32 1
    store i8* %env6, i8** %envptr7, align 8
    %4 = load i64*, i64** %arr, align 8
    %5 = load i64, i64* %4, align 8
    %sub = sub i64 %5, 1
    call void @__schmu_quicksort__2_aiii.u-aiii.i-ii.i(i64** %arr, i64 0, i64 %sub, i8* %env6)
    ret void
  }
  
  define linkonce_odr void @__schmu_sort_aiii.i.u(i64** noalias %arr, %closure* %cmp) {
  entry:
    %__schmu_partition_aiii.i-ii.i = alloca %closure, align 8
    %funptr10 = bitcast %closure* %__schmu_partition_aiii.i-ii.i to i8**
    store i8* bitcast (i64 (i64**, i64, i64, i8*)* @__schmu_partition_aiii.i-ii.i to i8*), i8** %funptr10, align 8
    %clsr___schmu_partition_aiii.i-ii.i = alloca { i8*, i8*, %closure }, align 8
    %cmp1 = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___schmu_partition_aiii.i-ii.i, i32 0, i32 2
    %0 = bitcast %closure* %cmp1 to i8*
    %1 = bitcast %closure* %cmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor11 = bitcast { i8*, i8*, %closure }* %clsr___schmu_partition_aiii.i-ii.i to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ii.i to i8*), i8** %ctor11, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___schmu_partition_aiii.i-ii.i, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %closure }* %clsr___schmu_partition_aiii.i-ii.i to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__schmu_partition_aiii.i-ii.i, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %__schmu_quicksort_aiii.u-aiii.i-ii.i = alloca %closure, align 8
    %funptr212 = bitcast %closure* %__schmu_quicksort_aiii.u-aiii.i-ii.i to i8**
    store i8* bitcast (void (i64**, i64, i64, i8*)* @__schmu_quicksort_aiii.u-aiii.i-ii.i to i8*), i8** %funptr212, align 8
    %clsr___schmu_quicksort_aiii.u-aiii.i-ii.i = alloca { i8*, i8*, %closure }, align 8
    %__schmu_partition_aiii.i-ii.i3 = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___schmu_quicksort_aiii.u-aiii.i-ii.i, i32 0, i32 2
    %2 = bitcast %closure* %__schmu_partition_aiii.i-ii.i3 to i8*
    %3 = bitcast %closure* %__schmu_partition_aiii.i-ii.i to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 16, i1 false)
    %ctor413 = bitcast { i8*, i8*, %closure }* %clsr___schmu_quicksort_aiii.u-aiii.i-ii.i to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-aiii.i to i8*), i8** %ctor413, align 8
    %dtor5 = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___schmu_quicksort_aiii.u-aiii.i-ii.i, i32 0, i32 1
    store i8* null, i8** %dtor5, align 8
    %env6 = bitcast { i8*, i8*, %closure }* %clsr___schmu_quicksort_aiii.u-aiii.i-ii.i to i8*
    %envptr7 = getelementptr inbounds %closure, %closure* %__schmu_quicksort_aiii.u-aiii.i-ii.i, i32 0, i32 1
    store i8* %env6, i8** %envptr7, align 8
    %4 = load i64*, i64** %arr, align 8
    %5 = load i64, i64* %4, align 8
    %sub = sub i64 %5, 1
    call void @__schmu_quicksort_aiii.u-aiii.i-ii.i(i64** %arr, i64 0, i64 %sub, i8* %env6)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr i8* @__ctor_tup-ai-i.u(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64*, %closure }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, i64*, %closure }*
    %4 = bitcast { i8*, i8*, i64*, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64*, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %arr = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %3, i32 0, i32 2
    call void @__copy_ai(i64** %arr)
    %f = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %3, i32 0, i32 3
    call void @__copy_i.u(%closure* %f)
    %6 = bitcast { i8*, i8*, i64*, %closure }* %3 to i8*
    ret i8* %6
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz1 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = bitcast i64* %5 to i8*
    %7 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 %3, i1 false)
    %newcap = getelementptr i64, i64* %5, i64 1
    store i64 %size, i64* %newcap, align 8
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_i.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr i8* @__ctor_tup-ai-ii.i-i-i(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64**, %closure, i64*, i64 }*
    %2 = call i8* @malloc(i64 56)
    %3 = bitcast i8* %2 to { i8*, i8*, i64**, %closure, i64*, i64 }*
    %4 = bitcast { i8*, i8*, i64**, %closure, i64*, i64 }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64**, %closure, i64*, i64 }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 56, i1 false)
    %arr = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %3, i32 0, i32 2
    %6 = bitcast i64*** %arr to i64**
    call void @__copy_ai(i64** %6)
    %cmp = getelementptr inbounds { i8*, i8*, i64**, %closure, i64*, i64 }, { i8*, i8*, i64**, %closure, i64*, i64 }* %3, i32 0, i32 3
    call void @__copy_ii.i(%closure* %cmp)
    %7 = bitcast { i8*, i8*, i64**, %closure, i64*, i64 }* %3 to i8*
    ret i8* %7
  }
  
  define linkonce_odr void @__copy_ii.i(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr i8* @__ctor_tup-ii.i(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %closure }*
    %2 = call i8* @malloc(i64 32)
    %3 = bitcast i8* %2 to { i8*, i8*, %closure }*
    %4 = bitcast { i8*, i8*, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 32, i1 false)
    %cmp = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %3, i32 0, i32 2
    call void @__copy_ii.i(%closure* %cmp)
    %6 = bitcast { i8*, i8*, %closure }* %3 to i8*
    ret i8* %6
  }
  
  define linkonce_odr i8* @__ctor_tup-aiii.i(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %closure }*
    %2 = call i8* @malloc(i64 32)
    %3 = bitcast i8* %2 to { i8*, i8*, %closure }*
    %4 = bitcast { i8*, i8*, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 32, i1 false)
    %__schmu_partition__2_aiii.i-ii.i = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %3, i32 0, i32 2
    call void @__copy_aiii.i(%closure* %__schmu_partition__2_aiii.i-ii.i)
    %6 = bitcast { i8*, i8*, %closure }* %3 to i8*
    ret i8* %6
  }
  
  define linkonce_odr void @__copy_aiii.i(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 64)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @schmu_arr, align 8
    store i64 6, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 6, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 9, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 30, i64* %"1", align 8
    %"2" = getelementptr i64, i64* %data, i64 2
    store i64 0, i64* %"2", align 8
    %"3" = getelementptr i64, i64* %data, i64 3
    store i64 50, i64* %"3", align 8
    %"4" = getelementptr i64, i64* %data, i64 4
    store i64 2030, i64* %"4", align 8
    %"5" = getelementptr i64, i64* %data, i64 5
    store i64 34, i64* %"5", align 8
    %clstmp = alloca %closure, align 8
    %funptr19 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64, i64)* @__fun_schmu1 to i8*), i8** %funptr19, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @__schmu_sort_aiii.i.u(i64** @schmu_arr, %closure* %clstmp)
    %3 = load i64*, i64** @schmu_arr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr220 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (void (i64)* @__fun_schmu2 to i8*), i8** %funptr220, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    call void @__array_iter_aii.u.u(i64* %3, %closure* %clstmp1)
    %4 = call i8* @malloc(i64 64)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** @schmu_arr__2, align 8
    store i64 6, i64* %5, align 8
    %cap5 = getelementptr i64, i64* %5, i64 1
    store i64 6, i64* %cap5, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data6 = bitcast i8* %6 to i64*
    store i64 9, i64* %data6, align 8
    %"18" = getelementptr i64, i64* %data6, i64 1
    store i64 30, i64* %"18", align 8
    %"29" = getelementptr i64, i64* %data6, i64 2
    store i64 0, i64* %"29", align 8
    %"310" = getelementptr i64, i64* %data6, i64 3
    store i64 50, i64* %"310", align 8
    %"411" = getelementptr i64, i64* %data6, i64 4
    store i64 2030, i64* %"411", align 8
    %"512" = getelementptr i64, i64* %data6, i64 5
    store i64 34, i64* %"512", align 8
    %clstmp13 = alloca %closure, align 8
    %funptr1421 = bitcast %closure* %clstmp13 to i8**
    store i8* bitcast (i64 (i64, i64)* @__fun_schmu4 to i8*), i8** %funptr1421, align 8
    %envptr15 = getelementptr inbounds %closure, %closure* %clstmp13, i32 0, i32 1
    store i8* null, i8** %envptr15, align 8
    call void @__schmu_sort__2_aiii.i.u(i64** @schmu_arr__2, %closure* %clstmp13)
    %7 = load i64*, i64** @schmu_arr__2, align 8
    %clstmp16 = alloca %closure, align 8
    %funptr1722 = bitcast %closure* %clstmp16 to i8**
    store i8* bitcast (void (i64)* @__fun_schmu5 to i8*), i8** %funptr1722, align 8
    %envptr18 = getelementptr inbounds %closure, %closure* %clstmp16, i32 0, i32 1
    store i8* null, i8** %envptr18, align 8
    call void @__array_iter_aii.u.u(i64* %7, %closure* %clstmp16)
    call void @__free_ai(i64** @schmu_arr__2)
    call void @__free_ai(i64** @schmu_arr)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  0
  9
  30
  34
  50
  2030
  0
  9
  30
  34
  50
  2030

Use captured record-field functions
  $ schmu capture_record_pattern.smu && ./capture_record_pattern
  3
  printing 0
  printing 1.1

Allow patterns in decls
  $ schmu pattern_decls.smu && ./pattern_decls
  hello
  20
  30
  lol

Assertions
  $ schmu assert.smu
  $ ret=$(./assert 2> err) 2> /dev/null
  [134]
  $ echo $ret
  hmm
  $ cat err | grep assert
  assert: assert.smu:9: main: Assertion `false' failed.

Find function by callname even when not calling
  $ schmu find_fn.smu

Free moved parameters
  $ schmu free_moved_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./free_moved_param

Free correctly when moving ifs with outer borrows
  $ schmu free_cond.smu && valgrind -q --leak-check=yes --show-reachable=yes ./free_cond

Handle partial allocations
  $ schmu partials.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./partials
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fai = type { i64*, i64*, i64* }
  %tai = type { i64*, i64* }
  %tup-ai-i = type { i64*, i64 }
  
  define i64* @schmu_inf() {
  entry:
    %0 = alloca %fai, align 8
    %a16 = bitcast %fai* %0 to i64**
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to i64*
    %arr = alloca i64*, align 8
    store i64* %2, i64** %arr, align 8
    store i64 1, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    store i64* %2, i64** %a16, align 8
    %b = getelementptr inbounds %fai, %fai* %0, i32 0, i32 1
    %4 = tail call i8* @malloc(i64 24)
    %5 = bitcast i8* %4 to i64*
    %arr1 = alloca i64*, align 8
    store i64* %5, i64** %arr1, align 8
    store i64 1, i64* %5, align 8
    %cap3 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %cap3, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data4 = bitcast i8* %6 to i64*
    store i64 10, i64* %data4, align 8
    store i64* %5, i64** %b, align 8
    %c = getelementptr inbounds %fai, %fai* %0, i32 0, i32 2
    %7 = tail call i8* @malloc(i64 24)
    %8 = bitcast i8* %7 to i64*
    %arr6 = alloca i64*, align 8
    store i64* %8, i64** %arr6, align 8
    store i64 1, i64* %8, align 8
    %cap8 = getelementptr i64, i64* %8, i64 1
    store i64 1, i64* %cap8, align 8
    %9 = getelementptr i8, i8* %7, i64 16
    %data9 = bitcast i8* %9 to i64*
    store i64 10, i64* %data9, align 8
    store i64* %8, i64** %c, align 8
    %10 = alloca i64*, align 8
    %11 = bitcast %fai* %0 to i64**
    call void @__free_ai(i64** %c)
    %.pre.pre = load i64*, i64** %11, align 8
    store i64* %.pre.pre, i64** %10, align 8
    call void @__free_ai(i64** %10)
    %12 = bitcast %fai* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %12, i64 8
    %13 = bitcast i8* %sunkaddr to i64**
    %14 = load i64*, i64** %13, align 8
    ret i64* %14
  }
  
  define void @schmu_set_moved() {
  entry:
    %0 = alloca %tai, align 8
    %a12 = bitcast %tai* %0 to i64**
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to i64*
    %arr = alloca i64*, align 8
    store i64* %2, i64** %arr, align 8
    store i64 1, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    store i64* %2, i64** %a12, align 8
    %b = getelementptr inbounds %tai, %tai* %0, i32 0, i32 1
    %4 = tail call i8* @malloc(i64 24)
    %5 = bitcast i8* %4 to i64*
    %arr1 = alloca i64*, align 8
    store i64* %5, i64** %arr1, align 8
    store i64 1, i64* %5, align 8
    %cap3 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %cap3, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data4 = bitcast i8* %6 to i64*
    store i64 20, i64* %data4, align 8
    store i64* %5, i64** %b, align 8
    %7 = alloca %tup-ai-i, align 8
    %"0613" = bitcast %tup-ai-i* %7 to i64**
    %8 = load i64*, i64** %a12, align 8
    store i64* %8, i64** %"0613", align 8
    %"1" = getelementptr inbounds %tup-ai-i, %tup-ai-i* %7, i32 0, i32 1
    store i64 0, i64* %"1", align 8
    %9 = tail call i8* @malloc(i64 24)
    %10 = bitcast i8* %9 to i64*
    %arr7 = alloca i64*, align 8
    store i64* %10, i64** %arr7, align 8
    store i64 1, i64* %10, align 8
    %cap9 = getelementptr i64, i64* %10, i64 1
    store i64 1, i64* %cap9, align 8
    %11 = getelementptr i8, i8* %9, i64 16
    %data10 = bitcast i8* %11 to i64*
    store i64 20, i64* %data10, align 8
    store i64* %10, i64** %a12, align 8
    call void @__free_tup-ai-i(%tup-ai-i* %7)
    call void @__free_tai(%tai* %0)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_tup-ai-i(%tup-ai-i* %0) {
  entry:
    %1 = bitcast %tup-ai-i* %0 to i64**
    call void @__free_ai(i64** %1)
    ret void
  }
  
  define linkonce_odr void @__free_tai(%tai* %0) {
  entry:
    %1 = bitcast %tai* %0 to i64**
    call void @__free_ai(i64** %1)
    %2 = getelementptr inbounds %tai, %tai* %0, i32 0, i32 1
    call void @__free_ai(i64** %2)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64* @schmu_inf()
    tail call void @schmu_set_moved()
    %1 = alloca i64*, align 8
    store i64* %0, i64** %1, align 8
    call void @__free_ai(i64** %1)
    ret i64 0
  }
  
  declare void @free(i8* %0)

Don't free string literals
  $ schmu borrow_string_lit.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./borrow_string_lit

Correct link order for cc flags
  $ schmu piping.smu --cc -L. --cc -lstub

Check allocs in fixed array
  $ schmu fixed_array_allocs.smu
  fixed_array_allocs.smu:1.5-8: warning: Unused binding arr.
  
  1 | let arr = #[#[1, 2, 3], #[3, 4, 5]]
          ^^^
  
  $ valgrind -q --leak-check=yes --show-reachable=yes ./fixed_array_allocs
  3
  hi
  hie
  oho

Const fixed array
  $ schmu --dump-llvm const_fixed_arr.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %tup-i-i = type { i64, i64 }
  
  @schmu_a = constant i64 17
  @schmu_arr = constant [3 x i64] [i64 1, i64 17, i64 3]
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 17)
    %0 = alloca %tup-i-i, align 8
    %"01" = bitcast %tup-i-i* %0 to i64*
    store i64 10, i64* %"01", align 8
    %"1" = getelementptr inbounds %tup-i-i, %tup-i-i* %0, i32 0, i32 1
    store i64 17, i64* %"1", align 8
    ret i64 0
  }
  
  declare void @printf(i8* %0, ...)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./const_fixed_arr
  17

Using unit values
  $ schmu unit_values.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./unit_values
  unit_values.smu:3.5-6: warning: Unused binding b.
  
  3 | let b = Some(a)
          ^
  
  unit_values.smu:8.8-9: warning: Unused binding a.
  
  8 |   Some(a): print("some")
             ^
  
  unit_values.smu:14.5-6: warning: Unused binding u.
  
  14 | let u = t.u
           ^
  
  unit_values.smu:18.5-7: warning: Unused binding u2.
  
  18 | let u2 = t2.u
           ^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tu = type { i32 }
  %thing = type {}
  %inrec = type { i64, double }
  
  @schmu_a = constant i8 0
  @schmu_b = constant %option.tu zeroinitializer
  @schmu_t = constant %thing zeroinitializer
  @schmu_u = constant i8 0
  @schmu_t__3 = constant %inrec { i64 10, double 9.990000e+01 }
  @schmu_arr__2 = constant i8 0
  @schmu_b__2 = global %option.tu zeroinitializer, align 4
  @schmu_t2 = global %thing zeroinitializer, align 1
  @schmu_u2 = global i8 0, align 1
  @schmu_arr = global void* null, align 8
  @schmu_u__2 = global i8 0, align 1
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"some\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  @2 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"%.9g\0A\00" }
  @3 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  declare void @string_print(i8* %0)
  
  define linkonce_odr void @__array_push_auu.u(void** noalias %arr) {
  entry:
    %0 = load void*, void** %arr, align 8
    %1 = bitcast void* %0 to i64*
    %capacity = getelementptr i64, i64* %1, i64 1
    %2 = load i64, i64* %capacity, align 8
    %3 = load i64, i64* %1, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %then, label %ifcont7
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %2, 0
    br i1 %eq1, label %then2, label %else
  
  then2:                                            ; preds = %then
    %4 = bitcast void* %0 to i8*
    %5 = tail call i8* @realloc(i8* %4, i64 16)
    %6 = bitcast i8* %5 to void*
    store void* %6, void** %arr, align 8
    %newcap = bitcast void* %6 to i64*
    %newcap3 = getelementptr i64, i64* %newcap, i64 1
    store i64 4, i64* %newcap3, align 8
    br label %ifcont7
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %2
    %7 = bitcast void* %0 to i8*
    %8 = tail call i8* @realloc(i8* %7, i64 16)
    %9 = bitcast i8* %8 to void*
    store void* %9, void** %arr, align 8
    %newcap4 = bitcast void* %9 to i64*
    %newcap5 = getelementptr i64, i64* %newcap4, i64 1
    store i64 %mul, i64* %newcap5, align 8
    br label %ifcont7
  
  ifcont7:                                          ; preds = %entry, %then2, %else
    %.pre-phi = phi i64* [ %newcap4, %else ], [ %newcap, %then2 ], [ %1, %entry ]
    %10 = phi void* [ %9, %else ], [ %6, %then2 ], [ %0, %entry ]
    %add = add i64 %3, 1
    store i64 %add, i64* %.pre-phi, align 8
    ret void
  }
  
  define void @schmu_a__2() {
  entry:
    ret void
  }
  
  define void @schmu_t__2(%thing* noalias %0) {
  entry:
    store %thing zeroinitializer, %thing* %0, align 1
    ret void
  }
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    store i32 0, i32* getelementptr inbounds (%option.tu, %option.tu* @schmu_b__2, i32 0, i32 0), align 4
    tail call void @string_print(i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*))
    tail call void @schmu_t__2(%thing* @schmu_t2)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [6 x i8] }* @2 to i8*), i64 16), double 9.990000e+01)
    %0 = tail call i8* @malloc(i64 16)
    %1 = bitcast i8* %0 to void*
    store void* %1, void** @schmu_arr, align 8
    %2 = bitcast void* %1 to i64*
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    tail call void @__array_push_auu.u(void** @schmu_arr)
    %4 = load void*, void** @schmu_arr, align 8
    %5 = bitcast void* %4 to i64*
    %6 = load i64, i64* %5, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @3 to i8*), i64 16), i64 %6)
    %7 = alloca %thing, align 8
    %8 = alloca %thing, align 8
    tail call void @__free_au(void** @schmu_arr)
    ret i64 0
  }
  
  declare void @printf(i8* %0, ...)
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__free_au(void** %0) {
  entry:
    %1 = load void*, void** %0, align 8
    %ref = bitcast void* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare void @free(i8* %0)
  some
  99.9
  3
