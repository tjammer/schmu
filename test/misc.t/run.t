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
  $ schmu --dump-llvm stub.o free_array.smu && valgrind -q --leak-check=yes --show-reachable=yes ./free_array
  free_array.smu:7:6: warning: Unused binding arr
  7 | (def arr ["hey" "young" "world"])
           ^^^
  
  free_array.smu:8:6: warning: Unused binding arr
  8 | (def arr [x {:x 2} {:x 3}])
           ^^^
  
  free_array.smu:48:6: warning: Unused binding arr
  48 | (def arr (make_arr))
            ^^^
  
  free_array.smu:51:6: warning: Unused binding normal
  51 | (def normal (nest_fns))
            ^^^^^^
  
  free_array.smu:55:6: warning: Unused binding nested
  55 | (def nested (make_nested_arr))
            ^^^^^^
  
  free_array.smu:56:6: warning: Unused binding nested
  56 | (def nested (nest_allocs))
            ^^^^^^
  
  free_array.smu:59:6: warning: Unused binding rec_of_arr
  59 | (def rec_of_arr {:index 12 :arr [1 2]})
            ^^^^^^^^^^
  
  free_array.smu:60:6: warning: Unused binding rec_of_arr
  60 | (def rec_of_arr (record_of_arrs))
            ^^^^^^^^^^
  
  free_array.smu:62:6: warning: Unused binding arr_of_rec
  62 | (def arr_of_rec [(record_of_arrs) (record_of_arrs)])
            ^^^^^^^^^^
  
  free_array.smu:63:6: warning: Unused binding arr_of_rec
  63 | (def arr_of_rec (arr_of_records))
            ^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %container = type { i64, i64* }
  
  @x = constant %foo { i64 1 }
  @x__2 = internal constant %foo { i64 23 }
  @arr = global i8** null, align 8
  @arr__2 = global %foo* null, align 8
  @arr__3 = global %foo* null, align 8
  @normal = global %foo* null, align 8
  @nested = global i64** null, align 8
  @nested__2 = global i64** null, align 8
  @nested__3 = global i64** null, align 8
  @rec_of_arr = global %container zeroinitializer, align 16
  @rec_of_arr__2 = global %container zeroinitializer, align 16
  @arr_of_rec = global %container* null, align 8
  @arr_of_rec__2 = global %container* null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"hey\00" }
  @1 = private unnamed_addr global { i64, i64, i64, [6 x i8] } { i64 2, i64 5, i64 5, [6 x i8] c"young\00" }
  @2 = private unnamed_addr global { i64, i64, i64, [6 x i8] } { i64 2, i64 5, i64 5, [6 x i8] c"world\00" }
  
  define void @schmu_arr_inside() {
  entry:
    %0 = tail call i8* @malloc(i64 48)
    %1 = bitcast i8* %0 to %foo*
    %arr = alloca %foo*, align 8
    store %foo* %1, %foo** %arr, align 8
    %2 = bitcast %foo* %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 3, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 3, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %3 to %foo*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* bitcast (%foo* @x to i8*), i64 8, i1 false)
    %"1" = getelementptr %foo, %foo* %data, i64 1
    store %foo { i64 2 }, %foo* %"1", align 8
    %"2" = getelementptr %foo, %foo* %data, i64 2
    store %foo { i64 3 }, %foo* %"2", align 8
    %4 = load %foo*, %foo** %arr, align 8
    %5 = bitcast %foo* %4 to i64*
    %size1 = getelementptr i64, i64* %5, i64 1
    %size2 = load i64, i64* %size1, align 8
    %cap3 = getelementptr i64, i64* %5, i64 2
    %cap4 = load i64, i64* %cap3, align 8
    %6 = icmp eq i64 %cap4, %size2
    br i1 %6, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %7 = call %foo* @__ag.ag_reloc_afoo.afoo(%foo** %arr)
    br label %merge
  
  grow:                                             ; preds = %entry
    %8 = call %foo* @__ag.ag_grow_afoo.afoo(%foo** %arr)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %9 = phi %foo* [ %7, %keep ], [ %8, %grow ]
    %10 = bitcast %foo* %9 to i64*
    %11 = bitcast %foo* %9 to i8*
    %12 = mul i64 8, %size2
    %13 = add i64 24, %12
    %14 = getelementptr i8, i8* %11, i64 %13
    %data5 = bitcast i8* %14 to %foo*
    store %foo { i64 12 }, %foo* %data5, align 8
    %size6 = getelementptr i64, i64* %10, i64 1
    %15 = add i64 %size2, 1
    store i64 %15, i64* %size6, align 8
    %16 = load %foo*, %foo** %arr, align 8
    call void @__g.u_decr_rc_afoo.u(%foo* %16)
    ret void
  }
  
  define %container* @schmu_arr_of_records() {
  entry:
    %0 = tail call i8* @malloc(i64 56)
    %1 = bitcast i8* %0 to %container*
    %arr = alloca %container*, align 8
    store %container* %1, %container** %arr, align 8
    %2 = bitcast %container* %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
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
    tail call void @__g.u_decr_rc_afoo.u(%foo* %0)
    ret void
  }
  
  define %foo* @schmu_make_arr() {
  entry:
    %0 = tail call i8* @malloc(i64 48)
    %1 = bitcast i8* %0 to %foo*
    %arr = alloca %foo*, align 8
    store %foo* %1, %foo** %arr, align 8
    %2 = bitcast %foo* %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 3, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 3, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %3 to %foo*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* bitcast (%foo* @x__2 to i8*), i64 8, i1 false)
    %"1" = getelementptr %foo, %foo* %data, i64 1
    store %foo { i64 2 }, %foo* %"1", align 8
    %"2" = getelementptr %foo, %foo* %data, i64 2
    store %foo { i64 3 }, %foo* %"2", align 8
    ret %foo* %1
  }
  
  define i64** @schmu_make_nested_arr() {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64**
    %arr = alloca i64**, align 8
    store i64** %1, i64*** %arr, align 8
    %2 = bitcast i64** %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %3 to i64**
    %4 = tail call i8* @malloc(i64 40)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %data, align 8
    store i64 1, i64* %5, align 8
    %size2 = getelementptr i64, i64* %5, i64 1
    store i64 2, i64* %size2, align 8
    %cap3 = getelementptr i64, i64* %5, i64 2
    store i64 2, i64* %cap3, align 8
    %6 = getelementptr i8, i8* %4, i64 24
    %data4 = bitcast i8* %6 to i64*
    store i64 0, i64* %data4, align 8
    %"1" = getelementptr i64, i64* %data4, i64 1
    store i64 1, i64* %"1", align 8
    %"16" = getelementptr i64*, i64** %data, i64 1
    %7 = tail call i8* @malloc(i64 40)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %"16", align 8
    store i64 1, i64* %8, align 8
    %size8 = getelementptr i64, i64* %8, i64 1
    store i64 2, i64* %size8, align 8
    %cap9 = getelementptr i64, i64* %8, i64 2
    store i64 2, i64* %cap9, align 8
    %9 = getelementptr i8, i8* %7, i64 24
    %data10 = bitcast i8* %9 to i64*
    store i64 2, i64* %data10, align 8
    %"112" = getelementptr i64, i64* %data10, i64 1
    store i64 3, i64* %"112", align 8
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
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64**
    %arr = alloca i64**, align 8
    store i64** %1, i64*** %arr, align 8
    %2 = bitcast i64** %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %3 to i64**
    %4 = tail call i8* @malloc(i64 40)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %data, align 8
    store i64 1, i64* %5, align 8
    %size2 = getelementptr i64, i64* %5, i64 1
    store i64 2, i64* %size2, align 8
    %cap3 = getelementptr i64, i64* %5, i64 2
    store i64 2, i64* %cap3, align 8
    %6 = getelementptr i8, i8* %4, i64 24
    %data4 = bitcast i8* %6 to i64*
    store i64 0, i64* %data4, align 8
    %"1" = getelementptr i64, i64* %data4, i64 1
    store i64 1, i64* %"1", align 8
    %"16" = getelementptr i64*, i64** %data, i64 1
    %7 = tail call i8* @malloc(i64 40)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %"16", align 8
    store i64 1, i64* %8, align 8
    %size8 = getelementptr i64, i64* %8, i64 1
    store i64 2, i64* %size8, align 8
    %cap9 = getelementptr i64, i64* %8, i64 2
    store i64 2, i64* %cap9, align 8
    %9 = getelementptr i8, i8* %7, i64 24
    %data10 = bitcast i8* %9 to i64*
    store i64 2, i64* %data10, align 8
    %"112" = getelementptr i64, i64* %data10, i64 1
    store i64 3, i64* %"112", align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %1)
    ret void
  }
  
  define { i64, i64 } @schmu_record_of_arrs() {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 8
    %size = getelementptr i64, i64* %1, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 2, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %2 to i64*
    store i64 1, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 2, i64* %"1", align 8
    %3 = alloca %container, align 8
    %index3 = bitcast %container* %3 to i64*
    store i64 1, i64* %index3, align 8
    %arr1 = getelementptr inbounds %container, %container* %3, i32 0, i32 1
    tail call void @__g.u_incr_rc_ai.u(i64* %1)
    store i64* %1, i64** %arr1, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %1)
    %unbox = bitcast %container* %3 to { i64, i64 }*
    %unbox2 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox2
  }
  
  declare i8* @malloc(i64 %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal %foo* @__ag.ag_reloc_afoo.afoo(%foo** %0) {
  entry:
    %1 = load %foo*, %foo** %0, align 8
    %ref = bitcast %foo* %1 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %2 = icmp sgt i64 %ref2, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %3 = bitcast %foo* %1 to i64*
    %sz = getelementptr i64, i64* %3, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %3, i64 2
    %cap3 = load i64, i64* %cap, align 8
    %4 = mul i64 %cap3, 8
    %5 = add i64 %4, 24
    %6 = call i8* @malloc(i64 %5)
    %7 = bitcast i8* %6 to %foo*
    %8 = mul i64 %size, 8
    %9 = add i64 %8, 24
    %10 = bitcast %foo* %7 to i8*
    %11 = bitcast %foo* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %11, i64 %9, i1 false)
    store %foo* %7, %foo** %0, align 8
    %ref4 = bitcast %foo* %7 to i64*
    %ref57 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref57, align 8
    call void @__g.u_decr_rc_afoo.u(%foo* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %12 = load %foo*, %foo** %0, align 8
    ret %foo* %12
  }
  
  define internal void @__g.u_decr_rc_afoo.u(%foo* %0) {
  entry:
    %ref = bitcast %foo* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast %foo* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast %foo* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal %foo* @__ag.ag_grow_afoo.afoo(%foo** %0) {
  entry:
    %1 = load %foo*, %foo** %0, align 8
    %2 = bitcast %foo* %1 to i64*
    %cap = getelementptr i64, i64* %2, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %3 = mul i64 %cap1, 2
    %ref7 = bitcast i64* %2 to i64*
    %ref2 = load i64, i64* %ref7, align 8
    %4 = mul i64 %3, 8
    %5 = add i64 %4, 24
    %6 = icmp eq i64 %ref2, 1
    br i1 %6, label %realloc, label %malloc
  
  realloc:                                          ; preds = %entry
    %7 = load %foo*, %foo** %0, align 8
    %8 = bitcast %foo* %7 to i8*
    %9 = call i8* @realloc(i8* %8, i64 %5)
    %10 = bitcast i8* %9 to %foo*
    store %foo* %10, %foo** %0, align 8
    br label %merge
  
  malloc:                                           ; preds = %entry
    %11 = bitcast %foo* %1 to i64*
    %12 = call i8* @malloc(i64 %5)
    %13 = bitcast i8* %12 to %foo*
    %size = getelementptr i64, i64* %11, i64 1
    %size3 = load i64, i64* %size, align 8
    %14 = mul i64 %size3, 8
    %15 = add i64 %14, 24
    %16 = bitcast %foo* %13 to i8*
    %17 = bitcast %foo* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %16, i8* %17, i64 %15, i1 false)
    store %foo* %13, %foo** %0, align 8
    %ref4 = bitcast %foo* %13 to i64*
    %ref58 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref58, align 8
    call void @__g.u_decr_rc_afoo.u(%foo* %1)
    br label %merge
  
  merge:                                            ; preds = %malloc, %realloc
    %18 = phi %foo* [ %10, %realloc ], [ %13, %malloc ]
    %newcap = bitcast %foo* %18 to i64*
    %newcap6 = getelementptr i64, i64* %newcap, i64 2
    store i64 %3, i64* %newcap6, align 8
    %19 = load %foo*, %foo** %0, align 8
    ret %foo* %19
  }
  
  define internal void @__g.u_decr_rc_aai.u(i64** %0) {
  entry:
    %ref = bitcast i64** %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64** %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i64** %0 to i64*
    %sz = getelementptr i64, i64* %5, i64 1
    %size = load i64, i64* %sz, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %6 = load i64, i64* %cnt, align 8
    %7 = icmp slt i64 %6, %size
    br i1 %7, label %child, label %cont
  
  child:                                            ; preds = %rec
    %8 = bitcast i64** %0 to i8*
    %9 = mul i64 8, %6
    %10 = add i64 24, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data = bitcast i8* %11 to i64**
    %12 = load i64*, i64** %data, align 8
    call void @__g.u_decr_rc_ai.u(i64* %12)
    %13 = add i64 %6, 1
    store i64 %13, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %14 = bitcast i64** %0 to i64*
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    br label %merge
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
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
    %ref1 = load i64, i64* %ref2, align 8
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 8
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 48)
    %1 = bitcast i8* %0 to i8**
    store i8** %1, i8*** @arr, align 8
    %2 = bitcast i8** %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 3, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 3, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %3 to i8**
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %data, align 8
    tail call void @__g.u_incr_rc_ac.u(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*))
    %"1" = getelementptr i8*, i8** %data, i64 1
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @1 to i8*), i8** %"1", align 8
    tail call void @__g.u_incr_rc_ac.u(i8* bitcast ({ i64, i64, i64, [6 x i8] }* @1 to i8*))
    %"2" = getelementptr i8*, i8** %data, i64 2
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @2 to i8*), i8** %"2", align 8
    tail call void @__g.u_incr_rc_ac.u(i8* bitcast ({ i64, i64, i64, [6 x i8] }* @2 to i8*))
    %4 = tail call i8* @malloc(i64 48)
    %5 = bitcast i8* %4 to %foo*
    store %foo* %5, %foo** @arr__2, align 8
    %6 = bitcast %foo* %5 to i64*
    store i64 1, i64* %6, align 8
    %size2 = getelementptr i64, i64* %6, i64 1
    store i64 3, i64* %size2, align 8
    %cap3 = getelementptr i64, i64* %6, i64 2
    store i64 3, i64* %cap3, align 8
    %7 = getelementptr i8, i8* %4, i64 24
    %data4 = bitcast i8* %7 to %foo*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* bitcast (%foo* @x to i8*), i64 8, i1 false)
    %"16" = getelementptr %foo, %foo* %data4, i64 1
    store %foo { i64 2 }, %foo* %"16", align 8
    %"27" = getelementptr %foo, %foo* %data4, i64 2
    store %foo { i64 3 }, %foo* %"27", align 8
    %8 = tail call %foo* @schmu_make_arr()
    store %foo* %8, %foo** @arr__3, align 8
    tail call void @schmu_arr_inside()
    tail call void @schmu_inner_parent_scope()
    %9 = tail call %foo* @schmu_nest_fns()
    store %foo* %9, %foo** @normal, align 8
    %10 = tail call i8* @malloc(i64 40)
    %11 = bitcast i8* %10 to i64**
    store i64** %11, i64*** @nested, align 8
    %12 = bitcast i64** %11 to i64*
    store i64 1, i64* %12, align 8
    %size9 = getelementptr i64, i64* %12, i64 1
    store i64 2, i64* %size9, align 8
    %cap10 = getelementptr i64, i64* %12, i64 2
    store i64 2, i64* %cap10, align 8
    %13 = getelementptr i8, i8* %10, i64 24
    %data11 = bitcast i8* %13 to i64**
    %14 = tail call i8* @malloc(i64 40)
    %15 = bitcast i8* %14 to i64*
    store i64* %15, i64** %data11, align 8
    store i64 1, i64* %15, align 8
    %size14 = getelementptr i64, i64* %15, i64 1
    store i64 2, i64* %size14, align 8
    %cap15 = getelementptr i64, i64* %15, i64 2
    store i64 2, i64* %cap15, align 8
    %16 = getelementptr i8, i8* %14, i64 24
    %data16 = bitcast i8* %16 to i64*
    store i64 0, i64* %data16, align 8
    %"118" = getelementptr i64, i64* %data16, i64 1
    store i64 1, i64* %"118", align 8
    %"119" = getelementptr i64*, i64** %data11, i64 1
    %17 = tail call i8* @malloc(i64 40)
    %18 = bitcast i8* %17 to i64*
    store i64* %18, i64** %"119", align 8
    store i64 1, i64* %18, align 8
    %size21 = getelementptr i64, i64* %18, i64 1
    store i64 2, i64* %size21, align 8
    %cap22 = getelementptr i64, i64* %18, i64 2
    store i64 2, i64* %cap22, align 8
    %19 = getelementptr i8, i8* %17, i64 24
    %data23 = bitcast i8* %19 to i64*
    store i64 2, i64* %data23, align 8
    %"125" = getelementptr i64, i64* %data23, i64 1
    store i64 3, i64* %"125", align 8
    %20 = tail call i8* @malloc(i64 40)
    %21 = bitcast i8* %20 to i64*
    %arr = alloca i64*, align 8
    store i64* %21, i64** %arr, align 8
    store i64 1, i64* %21, align 8
    %size27 = getelementptr i64, i64* %21, i64 1
    store i64 2, i64* %size27, align 8
    %cap28 = getelementptr i64, i64* %21, i64 2
    store i64 2, i64* %cap28, align 8
    %22 = getelementptr i8, i8* %20, i64 24
    %data29 = bitcast i8* %22 to i64*
    store i64 4, i64* %data29, align 8
    %"131" = getelementptr i64, i64* %data29, i64 1
    store i64 5, i64* %"131", align 8
    %23 = load i64**, i64*** @nested, align 8
    %24 = bitcast i64** %23 to i64*
    %size32 = getelementptr i64, i64* %24, i64 1
    %size33 = load i64, i64* %size32, align 8
    %cap34 = getelementptr i64, i64* %24, i64 2
    %cap35 = load i64, i64* %cap34, align 8
    %25 = icmp eq i64 %cap35, %size33
    br i1 %25, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %26 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    br label %merge
  
  grow:                                             ; preds = %entry
    %27 = tail call i64** @__ag.ag_grow_aai.aai(i64*** @nested)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %28 = phi i64** [ %26, %keep ], [ %27, %grow ]
    %29 = bitcast i8* %20 to i64*
    %30 = bitcast i64** %28 to i64*
    %31 = bitcast i64** %28 to i8*
    %32 = mul i64 8, %size33
    %33 = add i64 24, %32
    %34 = getelementptr i8, i8* %31, i64 %33
    %data36 = bitcast i8* %34 to i64**
    store i64* %29, i64** %data36, align 8
    %size37 = getelementptr i64, i64* %30, i64 1
    %35 = add i64 %size33, 1
    store i64 %35, i64* %size37, align 8
    %36 = tail call i64** @schmu_make_nested_arr()
    store i64** %36, i64*** @nested__2, align 8
    %37 = tail call i64** @schmu_nest_allocs()
    store i64** %37, i64*** @nested__3, align 8
    tail call void @schmu_nest_local()
    store i64 12, i64* getelementptr inbounds (%container, %container* @rec_of_arr, i32 0, i32 0), align 8
    %38 = tail call i8* @malloc(i64 40)
    %39 = bitcast i8* %38 to i64*
    %arr38 = alloca i64*, align 8
    store i64* %39, i64** %arr38, align 8
    store i64 1, i64* %39, align 8
    %size40 = getelementptr i64, i64* %39, i64 1
    store i64 2, i64* %size40, align 8
    %cap41 = getelementptr i64, i64* %39, i64 2
    store i64 2, i64* %cap41, align 8
    %40 = getelementptr i8, i8* %38, i64 24
    %data42 = bitcast i8* %40 to i64*
    store i64 1, i64* %data42, align 8
    %"144" = getelementptr i64, i64* %data42, i64 1
    store i64 2, i64* %"144", align 8
    store i64* %39, i64** getelementptr inbounds (%container, %container* @rec_of_arr, i32 0, i32 1), align 8
    %41 = tail call { i64, i64 } @schmu_record_of_arrs()
    store { i64, i64 } %41, { i64, i64 }* bitcast (%container* @rec_of_arr__2 to { i64, i64 }*), align 8
    %42 = tail call i8* @malloc(i64 56)
    %43 = bitcast i8* %42 to %container*
    store %container* %43, %container** @arr_of_rec, align 8
    %44 = bitcast %container* %43 to i64*
    store i64 1, i64* %44, align 8
    %size46 = getelementptr i64, i64* %44, i64 1
    store i64 2, i64* %size46, align 8
    %cap47 = getelementptr i64, i64* %44, i64 2
    store i64 2, i64* %cap47, align 8
    %45 = getelementptr i8, i8* %42, i64 24
    %data48 = bitcast i8* %45 to %container*
    %46 = tail call { i64, i64 } @schmu_record_of_arrs()
    %box = bitcast %container* %data48 to { i64, i64 }*
    store { i64, i64 } %46, { i64, i64 }* %box, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %45, i8* %45, i64 16, i1 false)
    %"151" = getelementptr %container, %container* %data48, i64 1
    %47 = tail call { i64, i64 } @schmu_record_of_arrs()
    %box52 = bitcast %container* %"151" to { i64, i64 }*
    store { i64, i64 } %47, { i64, i64 }* %box52, align 8
    %48 = bitcast %container* %"151" to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %48, i8* %48, i64 16, i1 false)
    %49 = tail call %container* @schmu_arr_of_records()
    store %container* %49, %container** @arr_of_rec__2, align 8
    tail call void @__g.u_decr_rc_acontainer.u(%container* %49)
    %50 = load %container*, %container** @arr_of_rec, align 8
    tail call void @__g.u_decr_rc_acontainer.u(%container* %50)
    tail call void @__g.u_decr_rc_container.u(%container* @rec_of_arr__2)
    tail call void @__g.u_decr_rc_container.u(%container* @rec_of_arr)
    %51 = load i64**, i64*** @nested__3, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %51)
    %52 = load i64**, i64*** @nested__2, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %52)
    %53 = load i64**, i64*** @nested, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %53)
    %54 = load %foo*, %foo** @normal, align 8
    tail call void @__g.u_decr_rc_afoo.u(%foo* %54)
    %55 = load %foo*, %foo** @arr__3, align 8
    tail call void @__g.u_decr_rc_afoo.u(%foo* %55)
    %56 = load %foo*, %foo** @arr__2, align 8
    tail call void @__g.u_decr_rc_afoo.u(%foo* %56)
    %57 = load i8**, i8*** @arr, align 8
    tail call void @__g.u_decr_rc_aac.u(i8** %57)
    ret i64 0
  }
  
  define internal void @__g.u_incr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 8
    ret void
  }
  
  define internal i64** @__ag.ag_reloc_aai.aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %2 = icmp sgt i64 %ref2, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %3 = bitcast i64** %1 to i64*
    %sz = getelementptr i64, i64* %3, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %3, i64 2
    %cap3 = load i64, i64* %cap, align 8
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
    %ref57 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref57, align 8
    call void @__g.u_decr_rc_aai.u(i64** %1)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %rec, %entry
    %12 = load i64**, i64*** %0, align 8
    ret i64** %12
  
  rec:                                              ; preds = %child, %relocate
    %13 = load i64, i64* %cnt, align 8
    %14 = icmp slt i64 %13, %size
    br i1 %14, label %child, label %merge
  
  child:                                            ; preds = %rec
    %15 = bitcast i64** %1 to i8*
    %16 = mul i64 8, %13
    %17 = add i64 24, %16
    %18 = getelementptr i8, i8* %15, i64 %17
    %data = bitcast i8* %18 to i64**
    %19 = load i64*, i64** %data, align 8
    call void @__g.u_incr_rc_ai.u(i64* %19)
    %20 = add i64 %13, 1
    store i64 %20, i64* %cnt, align 8
    br label %rec
  }
  
  define internal i64** @__ag.ag_grow_aai.aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %2 = bitcast i64** %1 to i64*
    %cap = getelementptr i64, i64* %2, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %3 = mul i64 %cap1, 2
    %ref7 = bitcast i64* %2 to i64*
    %ref2 = load i64, i64* %ref7, align 8
    %4 = mul i64 %3, 8
    %5 = add i64 %4, 24
    %6 = icmp eq i64 %ref2, 1
    br i1 %6, label %realloc, label %malloc
  
  realloc:                                          ; preds = %entry
    %7 = load i64**, i64*** %0, align 8
    %8 = bitcast i64** %7 to i8*
    %9 = call i8* @realloc(i8* %8, i64 %5)
    %10 = bitcast i8* %9 to i64**
    store i64** %10, i64*** %0, align 8
    br label %merge
  
  malloc:                                           ; preds = %entry
    %11 = bitcast i64** %1 to i64*
    %12 = call i8* @malloc(i64 %5)
    %13 = bitcast i8* %12 to i64**
    %size = getelementptr i64, i64* %11, i64 1
    %size3 = load i64, i64* %size, align 8
    %14 = mul i64 %size3, 8
    %15 = add i64 %14, 24
    %16 = bitcast i64** %13 to i8*
    %17 = bitcast i64** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %16, i8* %17, i64 %15, i1 false)
    store i64** %13, i64*** %0, align 8
    %ref4 = bitcast i64** %13 to i64*
    %ref58 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref58, align 8
    call void @__g.u_decr_rc_aai.u(i64** %1)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %rec, %realloc
    %18 = phi i64** [ %10, %realloc ], [ %20, %rec ]
    %newcap = bitcast i64** %18 to i64*
    %newcap6 = getelementptr i64, i64* %newcap, i64 2
    store i64 %3, i64* %newcap6, align 8
    %19 = load i64**, i64*** %0, align 8
    ret i64** %19
  
  rec:                                              ; preds = %child, %malloc
    %20 = bitcast i8* %12 to i64**
    %21 = load i64, i64* %cnt, align 8
    %22 = icmp slt i64 %21, %size3
    br i1 %22, label %child, label %merge
  
  child:                                            ; preds = %rec
    %23 = bitcast i64** %1 to i8*
    %24 = mul i64 8, %21
    %25 = add i64 24, %24
    %26 = getelementptr i8, i8* %23, i64 %25
    %data = bitcast i8* %26 to i64**
    %27 = load i64*, i64** %data, align 8
    call void @__g.u_incr_rc_ai.u(i64* %27)
    %28 = add i64 %21, 1
    store i64 %28, i64* %cnt, align 8
    br label %rec
  }
  
  define internal void @__g.u_decr_rc_acontainer.u(%container* %0) {
  entry:
    %ref = bitcast %container* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast %container* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast %container* %0 to i64*
    %sz = getelementptr i64, i64* %5, i64 1
    %size = load i64, i64* %sz, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %6 = load i64, i64* %cnt, align 8
    %7 = icmp slt i64 %6, %size
    br i1 %7, label %child, label %cont
  
  child:                                            ; preds = %rec
    %8 = bitcast %container* %0 to i8*
    %9 = mul i64 16, %6
    %10 = add i64 24, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data = bitcast i8* %11 to %container*
    call void @__g.u_decr_rc_container.u(%container* %data)
    %12 = add i64 %6, 1
    store i64 %12, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %13 = bitcast %container* %0 to i64*
    %14 = bitcast i64* %13 to i8*
    call void @free(i8* %14)
    br label %merge
  }
  
  define internal void @__g.u_decr_rc_container.u(%container* %0) {
  entry:
    %1 = getelementptr inbounds %container, %container* %0, i32 0, i32 1
    %2 = load i64*, i64** %1, align 8
    %ref2 = bitcast i64* %2 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %3 = icmp eq i64 %ref1, 1
    br i1 %3, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %4 = bitcast i64* %2 to i64*
    %5 = sub i64 %ref1, 1
    store i64 %5, i64* %4, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %6 = bitcast i64* %2 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_aac.u(i8** %0) {
  entry:
    %ref = bitcast i8** %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8** %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8** %0 to i64*
    %sz = getelementptr i64, i64* %5, i64 1
    %size = load i64, i64* %sz, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %6 = load i64, i64* %cnt, align 8
    %7 = icmp slt i64 %6, %size
    br i1 %7, label %child, label %cont
  
  child:                                            ; preds = %rec
    %8 = bitcast i8** %0 to i8*
    %9 = mul i64 8, %6
    %10 = add i64 24, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data = bitcast i8* %11 to i8**
    %12 = load i8*, i8** %data, align 8
    call void @__g.u_decr_rc_ac.u(i8* %12)
    %13 = add i64 %6, 1
    store i64 %13, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %14 = bitcast i8** %0 to i64*
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    br label %merge
  }
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
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
  
  @0 = private unnamed_addr global { i64, i64, i64, [6 x i8] } { i64 2, i64 5, i64 5, [6 x i8] c"false\00" }
  @1 = private unnamed_addr global { i64, i64, i64, [5 x i8] } { i64 2, i64 4, i64 4, [5 x i8] c"true\00" }
  @2 = private unnamed_addr global { i64, i64, i64, [12 x i8] } { i64 2, i64 11, i64 11, [12 x i8] c"test 'and':\00" }
  @3 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 11, i64 3, i64 3, [4 x i8] c"yes\00" }
  @4 = private unnamed_addr global { i64, i64, i64, [3 x i8] } { i64 11, i64 2, i64 2, [3 x i8] c"no\00" }
  @5 = private unnamed_addr global { i64, i64, i64, [11 x i8] } { i64 2, i64 10, i64 10, [11 x i8] c"test 'or':\00" }
  @6 = private unnamed_addr global { i64, i64, i64, [12 x i8] } { i64 2, i64 11, i64 11, [12 x i8] c"test 'not':\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i1 @schmu_false_() {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), i8** %str, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*))
    ret i1 false
  }
  
  define i1 @schmu_true_() {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [5 x i8] }* @1 to i8*), i8** %str, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [5 x i8] }* @1 to i8*))
    ret i1 true
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [12 x i8] }* @2 to i8*), i8** %str, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [12 x i8] }* @2 to i8*))
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
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str1, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont
  
  else:                                             ; preds = %cont
    %str2 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str2, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %2 = tail call i1 @schmu_true_()
    br i1 %2, label %true13, label %cont5
  
  true13:                                           ; preds = %ifcont
    %3 = tail call i1 @schmu_false_()
    br i1 %3, label %true24, label %cont5
  
  true24:                                           ; preds = %true13
    br label %cont5
  
  cont5:                                            ; preds = %true24, %true13, %ifcont
    %andtmp6 = phi i1 [ false, %ifcont ], [ false, %true13 ], [ true, %true24 ]
    br i1 %andtmp6, label %then7, label %else9
  
  then7:                                            ; preds = %cont5
    %str8 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str8, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont11
  
  else9:                                            ; preds = %cont5
    %str10 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str10, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont11
  
  ifcont11:                                         ; preds = %else9, %then7
    %4 = tail call i1 @schmu_false_()
    br i1 %4, label %true112, label %cont14
  
  true112:                                          ; preds = %ifcont11
    %5 = tail call i1 @schmu_true_()
    br i1 %5, label %true213, label %cont14
  
  true213:                                          ; preds = %true112
    br label %cont14
  
  cont14:                                           ; preds = %true213, %true112, %ifcont11
    %andtmp15 = phi i1 [ false, %ifcont11 ], [ false, %true112 ], [ true, %true213 ]
    br i1 %andtmp15, label %then16, label %else18
  
  then16:                                           ; preds = %cont14
    %str17 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str17, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont20
  
  else18:                                           ; preds = %cont14
    %str19 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str19, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont20
  
  ifcont20:                                         ; preds = %else18, %then16
    %6 = tail call i1 @schmu_false_()
    br i1 %6, label %true121, label %cont23
  
  true121:                                          ; preds = %ifcont20
    %7 = tail call i1 @schmu_false_()
    br i1 %7, label %true222, label %cont23
  
  true222:                                          ; preds = %true121
    br label %cont23
  
  cont23:                                           ; preds = %true222, %true121, %ifcont20
    %andtmp24 = phi i1 [ false, %ifcont20 ], [ false, %true121 ], [ true, %true222 ]
    br i1 %andtmp24, label %then25, label %else27
  
  then25:                                           ; preds = %cont23
    %str26 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str26, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont29
  
  else27:                                           ; preds = %cont23
    %str28 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str28, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont29
  
  ifcont29:                                         ; preds = %else27, %then25
    %str30 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [11 x i8] }* @5 to i8*), i8** %str30, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [11 x i8] }* @5 to i8*))
    %8 = tail call i1 @schmu_true_()
    br i1 %8, label %cont31, label %false1
  
  false1:                                           ; preds = %ifcont29
    %9 = tail call i1 @schmu_true_()
    br i1 %9, label %cont31, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont31
  
  cont31:                                           ; preds = %false2, %false1, %ifcont29
    %andtmp32 = phi i1 [ true, %ifcont29 ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp32, label %then33, label %else35
  
  then33:                                           ; preds = %cont31
    %str34 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str34, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont37
  
  else35:                                           ; preds = %cont31
    %str36 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str36, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont37
  
  ifcont37:                                         ; preds = %else35, %then33
    %10 = tail call i1 @schmu_true_()
    br i1 %10, label %cont40, label %false138
  
  false138:                                         ; preds = %ifcont37
    %11 = tail call i1 @schmu_false_()
    br i1 %11, label %cont40, label %false239
  
  false239:                                         ; preds = %false138
    br label %cont40
  
  cont40:                                           ; preds = %false239, %false138, %ifcont37
    %andtmp41 = phi i1 [ true, %ifcont37 ], [ true, %false138 ], [ false, %false239 ]
    br i1 %andtmp41, label %then42, label %else44
  
  then42:                                           ; preds = %cont40
    %str43 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str43, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont46
  
  else44:                                           ; preds = %cont40
    %str45 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str45, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont46
  
  ifcont46:                                         ; preds = %else44, %then42
    %12 = tail call i1 @schmu_false_()
    br i1 %12, label %cont49, label %false147
  
  false147:                                         ; preds = %ifcont46
    %13 = tail call i1 @schmu_true_()
    br i1 %13, label %cont49, label %false248
  
  false248:                                         ; preds = %false147
    br label %cont49
  
  cont49:                                           ; preds = %false248, %false147, %ifcont46
    %andtmp50 = phi i1 [ true, %ifcont46 ], [ true, %false147 ], [ false, %false248 ]
    br i1 %andtmp50, label %then51, label %else53
  
  then51:                                           ; preds = %cont49
    %str52 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str52, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont55
  
  else53:                                           ; preds = %cont49
    %str54 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str54, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont55
  
  ifcont55:                                         ; preds = %else53, %then51
    %14 = tail call i1 @schmu_false_()
    br i1 %14, label %cont58, label %false156
  
  false156:                                         ; preds = %ifcont55
    %15 = tail call i1 @schmu_false_()
    br i1 %15, label %cont58, label %false257
  
  false257:                                         ; preds = %false156
    br label %cont58
  
  cont58:                                           ; preds = %false257, %false156, %ifcont55
    %andtmp59 = phi i1 [ true, %ifcont55 ], [ true, %false156 ], [ false, %false257 ]
    br i1 %andtmp59, label %then60, label %else62
  
  then60:                                           ; preds = %cont58
    %str61 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str61, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont64
  
  else62:                                           ; preds = %cont58
    %str63 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str63, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont64
  
  ifcont64:                                         ; preds = %else62, %then60
    %str65 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [12 x i8] }* @6 to i8*), i8** %str65, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [12 x i8] }* @6 to i8*))
    %16 = tail call i1 @schmu_true_()
    %17 = xor i1 %16, true
    br i1 %17, label %then66, label %else68
  
  then66:                                           ; preds = %ifcont64
    %str67 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str67, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont70
  
  else68:                                           ; preds = %ifcont64
    %str69 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str69, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont70
  
  ifcont70:                                         ; preds = %else68, %then66
    %18 = tail call i1 @schmu_false_()
    %19 = xor i1 %18, true
    br i1 %19, label %then71, label %else73
  
  then71:                                           ; preds = %ifcont70
    %str72 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i8** %str72, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*))
    br label %ifcont75
  
  else73:                                           ; preds = %ifcont70
    %str74 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*), i8** %str74, align 8
    tail call void @prelude_print(i8* bitcast ({ i64, i64, i64, [3 x i8] }* @4 to i8*))
    br label %ifcont75
  
  ifcont75:                                         ; preds = %else73, %then71
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
  1 | (def a -1.0)
           ^
  
  unary_minus.smu:2:6: warning: Unused binding a
  2 | (def a -.1.0)
           ^
  
  unary_minus.smu:3:6: warning: Unused binding a
  3 | (def a - 1.0)
           ^
  
  unary_minus.smu:4:6: warning: Unused binding a
  4 | (def a -. 1.0)
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
  2 | (def unused1 0)
           ^^^^^^^
  
  unused.smu:5:6: warning: Unused binding unused2
  5 | (def unused2 0)
           ^^^^^^^
  
  unused.smu:12:7: warning: Unused binding use_unused3
  12 | (defn use_unused3 []
             ^^^^^^^^^^^
  
  unused.smu:19:11: warning: Unused binding unused4
  19 |      (def unused4 0)
                 ^^^^^^^
  
  unused.smu:23:11: warning: Unused binding unused5
  23 |      (def unused5 0)
                 ^^^^^^^
  
  unused.smu:38:13: warning: Unused binding usedlater
  38 |        (def usedlater 0)
                   ^^^^^^^^^
  
  unused.smu:52:13: warning: Unused binding usedlater
  52 |        (def usedlater 0)
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
  
  @limit = constant i64 3
  @0 = private unnamed_addr global { i64, i64, i64, [8 x i8] } { i64 2, i64 7, i64 7, [8 x i8] c"%i, %i\0A\00" }
  @1 = private unnamed_addr global { i64, i64, i64, [12 x i8] } { i64 3, i64 11, i64 11, [12 x i8] c"%i, %i, %i\0A\00" }
  @2 = private unnamed_addr global { i64, i64, i64, [2 x i8] } { i64 2, i64 1, i64 1, [2 x i8] c"\0A\00" }
  
  declare void @printf(i8* %0, i64 %1, i64 %2, i64 %3)
  
  define void @schmu_nested(i64 %a, i64 %b) {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, i64* %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, i64* %1, align 8
    %str = alloca i8*, align 8
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
    store i8* bitcast ({ i64, i64, i64, [8 x i8] }* @0 to i8*), i8** %str, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [8 x i8] }, { i64, i64, i64, [8 x i8] }* @0, i64 0, i32 3, i64 0), i64 %.ph, i64 %2, i64 0)
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
    %str = alloca i8*, align 8
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
    store i8* bitcast ({ i64, i64, i64, [12 x i8] }* @1 to i8*), i8** %str, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [12 x i8] }, { i64, i64, i64, [12 x i8] }* @1, i64 0, i32 3, i64 0), i64 %.ph11.ph, i64 %.ph, i64 %4)
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
    %str = alloca i8*, align 8
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
    store i8* bitcast ({ i64, i64, i64, [12 x i8] }* @1 to i8*), i8** %str, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [12 x i8] }, { i64, i64, i64, [12 x i8] }* @1, i64 0, i32 3, i64 0), i64 %.ph10.ph, i64 %.ph, i64 %3)
    %add8 = add i64 %3, 1
    store i64 %add8, i64* %2, align 8
    br label %rec
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_nested(i64 0, i64 0)
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [2 x i8] }* @2 to i8*), i8** %str, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [2 x i8] }, { i64, i64, i64, [2 x i8] }* @2, i64 0, i32 3, i64 0), i64 0, i64 0, i64 0)
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
  regression_issue_30.smu:8:7: warning: Unused binding calc_acc
  8 | (defn calc_acc [vel]
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
  
  %prelude.option_int = type { i32, i64 }
  
  declare void @Printi(i64 %0)
  
  define i64 @schmu___fun0(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @schmu___fun1(%prelude.option_int* %x) {
  entry:
    %tag1 = bitcast %prelude.option_int* %x to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %x, i32 0, i32 1
    %0 = load i64, i64* %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @schmu___fun0(i64 1)
    tail call void @Printi(i64 %0)
    %option = alloca %prelude.option_int, align 8
    %tag1 = bitcast %prelude.option_int* %option to i32*
    store i32 0, i32* %tag1, align 4
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 8
    %1 = call i64 @schmu___fun1(%prelude.option_int* %option)
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
  
  define void @schmu___g.u_get-seg_bar.u(%bar* %bar) {
  entry:
    ret void
  }
  
  define void @schmu_wrap-seg() {
  entry:
    tail call void @schmu___g.u_get-seg_bar.u(%bar* @world)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store double 0.000000e+00, double* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 0), align 8
    store double 1.280000e+03, double* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 1), align 8
    store i64 10, i64* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 2), align 8
    store double 1.000000e-01, double* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 3), align 8
    store double 5.400000e+02, double* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 4), align 8
    store float 5.000000e+00, float* getelementptr inbounds (%bar, %bar* @world, i32 0, i32 5), align 4
    tail call void @schmu_wrap-seg()
    ret i64 0
  }


  $ schmu --dump-llvm array_push.smu && valgrind -q --leak-check=yes --show-reachable=yes ./array_push
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @a = global i64* null, align 8
  @b = global i64* null, align 8
  @nested = global i64** null, align 8
  @a__2 = global i64* null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @prelude_print(i8* %0)
  
  define void @schmu_in-fun() {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 8
    %size = getelementptr i64, i64* %1, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 2, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %2 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    %3 = load i64*, i64** %arr, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %3)
    %size1 = getelementptr i64, i64* %3, i64 1
    %size2 = load i64, i64* %size1, align 8
    %cap3 = getelementptr i64, i64* %3, i64 2
    %cap4 = load i64, i64* %cap3, align 8
    %4 = icmp eq i64 %cap4, %size2
    br i1 %4, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %5 = call i64* @__ag.ag_reloc_ai.ai(i64** %arr)
    br label %merge
  
  grow:                                             ; preds = %entry
    %6 = call i64* @__ag.ag_grow_ai.ai(i64** %arr)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %7 = phi i64* [ %5, %keep ], [ %6, %grow ]
    %8 = bitcast i64* %7 to i8*
    %9 = mul i64 8, %size2
    %10 = add i64 24, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data5 = bitcast i8* %11 to i64*
    store i64 30, i64* %data5, align 8
    %size6 = getelementptr i64, i64* %7, i64 1
    %12 = add i64 %size2, 1
    store i64 %12, i64* %size6, align 8
    %13 = load i64*, i64** %arr, align 8
    %len = getelementptr i64, i64* %13, i64 1
    %14 = load i64, i64* %len, align 8
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %14)
    %15 = add i32 %fmtsize, 25
    %16 = sext i32 %15 to i64
    %17 = call i8* @malloc(i64 %16)
    %18 = bitcast i8* %17 to i64*
    store i64 1, i64* %18, align 8
    %size8 = getelementptr i64, i64* %18, i64 1
    %19 = sext i32 %fmtsize to i64
    store i64 %19, i64* %size8, align 8
    %cap9 = getelementptr i64, i64* %18, i64 2
    store i64 %19, i64* %cap9, align 8
    %data10 = getelementptr i64, i64* %18, i64 3
    %20 = bitcast i64* %data10 to i8*
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %20, i64 %16, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %14)
    %str = alloca i8*, align 8
    store i8* %17, i8** %str, align 8
    call void @prelude_print(i8* %17)
    %21 = bitcast i64* %3 to i8*
    %sunkaddr = getelementptr i8, i8* %21, i64 8
    %22 = bitcast i8* %sunkaddr to i64*
    %23 = load i64, i64* %22, align 8
    %fmtsize12 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %23)
    %24 = add i32 %fmtsize12, 25
    %25 = sext i32 %24 to i64
    %26 = call i8* @malloc(i64 %25)
    %27 = bitcast i8* %26 to i64*
    store i64 1, i64* %27, align 8
    %size14 = getelementptr i64, i64* %27, i64 1
    %28 = sext i32 %fmtsize12 to i64
    store i64 %28, i64* %size14, align 8
    %cap15 = getelementptr i64, i64* %27, i64 2
    store i64 %28, i64* %cap15, align 8
    %data16 = getelementptr i64, i64* %27, i64 3
    %29 = bitcast i64* %data16 to i8*
    %fmt17 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %29, i64 %25, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %23)
    %str18 = alloca i8*, align 8
    store i8* %26, i8** %str18, align 8
    call void @prelude_print(i8* %26)
    call void @__g.u_decr_rc_ac.u(i8* %26)
    call void @__g.u_decr_rc_ac.u(i8* %17)
    call void @__g.u_decr_rc_ai.u(i64* %3)
    %30 = load i64*, i64** %arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %30)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_incr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 8
    ret void
  }
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 8
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 8
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
    store i64 1, i64* %ref35, align 8
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
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
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 2
    %ref5 = bitcast i64* %1 to i64*
    %ref2 = load i64, i64* %ref5, align 8
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
    %size3 = load i64, i64* %size, align 8
    %12 = mul i64 %size3, 8
    %13 = add i64 %12, 24
    %14 = bitcast i64* %11 to i8*
    %15 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %14, i8* %15, i64 %13, i1 false)
    store i64* %11, i64** %0, align 8
    %ref46 = bitcast i64* %11 to i64*
    store i64 1, i64* %ref46, align 8
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %malloc, %realloc
    %16 = phi i64* [ %9, %realloc ], [ %11, %malloc ]
    %newcap = getelementptr i64, i64* %16, i64 2
    store i64 %2, i64* %newcap, align 8
    %17 = load i64*, i64** %0, align 8
    ret i64* %17
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
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
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @a, align 8
    store i64 1, i64* %1, align 8
    %size = getelementptr i64, i64* %1, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 2, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %2 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    %3 = load i64*, i64** @a, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %3)
    store i64* %3, i64** @b, align 8
    %4 = load i64*, i64** @a, align 8
    %size1 = getelementptr i64, i64* %4, i64 1
    %size2 = load i64, i64* %size1, align 8
    %cap3 = getelementptr i64, i64* %4, i64 2
    %cap4 = load i64, i64* %cap3, align 8
    %5 = icmp eq i64 %cap4, %size2
    br i1 %5, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %6 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @a)
    br label %merge
  
  grow:                                             ; preds = %entry
    %7 = tail call i64* @__ag.ag_grow_ai.ai(i64** @a)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %8 = phi i64* [ %6, %keep ], [ %7, %grow ]
    %9 = bitcast i64* %8 to i8*
    %10 = mul i64 8, %size2
    %11 = add i64 24, %10
    %12 = getelementptr i8, i8* %9, i64 %11
    %data5 = bitcast i8* %12 to i64*
    store i64 30, i64* %data5, align 8
    %size6 = getelementptr i64, i64* %8, i64 1
    %13 = add i64 %size2, 1
    store i64 %13, i64* %size6, align 8
    %14 = load i64*, i64** @a, align 8
    %len = getelementptr i64, i64* %14, i64 1
    %15 = load i64, i64* %len, align 8
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %15)
    %16 = add i32 %fmtsize, 25
    %17 = sext i32 %16 to i64
    %18 = tail call i8* @malloc(i64 %17)
    %19 = bitcast i8* %18 to i64*
    store i64 1, i64* %19, align 8
    %size8 = getelementptr i64, i64* %19, i64 1
    %20 = sext i32 %fmtsize to i64
    store i64 %20, i64* %size8, align 8
    %cap9 = getelementptr i64, i64* %19, i64 2
    store i64 %20, i64* %cap9, align 8
    %data10 = getelementptr i64, i64* %19, i64 3
    %21 = bitcast i64* %data10 to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %21, i64 %17, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %15)
    %str = alloca i8*, align 8
    store i8* %18, i8** %str, align 8
    tail call void @prelude_print(i8* %18)
    %22 = load i64*, i64** @b, align 8
    %len11 = getelementptr i64, i64* %22, i64 1
    %23 = load i64, i64* %len11, align 8
    %fmtsize12 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %23)
    %24 = add i32 %fmtsize12, 25
    %25 = sext i32 %24 to i64
    %26 = tail call i8* @malloc(i64 %25)
    %27 = bitcast i8* %26 to i64*
    store i64 1, i64* %27, align 8
    %size14 = getelementptr i64, i64* %27, i64 1
    %28 = sext i32 %fmtsize12 to i64
    store i64 %28, i64* %size14, align 8
    %cap15 = getelementptr i64, i64* %27, i64 2
    store i64 %28, i64* %cap15, align 8
    %data16 = getelementptr i64, i64* %27, i64 3
    %29 = bitcast i64* %data16 to i8*
    %fmt17 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %29, i64 %25, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %23)
    %str18 = alloca i8*, align 8
    store i8* %26, i8** %str18, align 8
    tail call void @prelude_print(i8* %26)
    tail call void @schmu_in-fun()
    %30 = tail call i8* @malloc(i64 40)
    %31 = bitcast i8* %30 to i64**
    store i64** %31, i64*** @nested, align 8
    %32 = bitcast i64** %31 to i64*
    store i64 1, i64* %32, align 8
    %size20 = getelementptr i64, i64* %32, i64 1
    store i64 2, i64* %size20, align 8
    %cap21 = getelementptr i64, i64* %32, i64 2
    store i64 2, i64* %cap21, align 8
    %33 = getelementptr i8, i8* %30, i64 24
    %data22 = bitcast i8* %33 to i64**
    %34 = tail call i8* @malloc(i64 40)
    %35 = bitcast i8* %34 to i64*
    store i64* %35, i64** %data22, align 8
    store i64 1, i64* %35, align 8
    %size25 = getelementptr i64, i64* %35, i64 1
    store i64 2, i64* %size25, align 8
    %cap26 = getelementptr i64, i64* %35, i64 2
    store i64 2, i64* %cap26, align 8
    %36 = getelementptr i8, i8* %34, i64 24
    %data27 = bitcast i8* %36 to i64*
    store i64 0, i64* %data27, align 8
    %"129" = getelementptr i64, i64* %data27, i64 1
    store i64 1, i64* %"129", align 8
    %"130" = getelementptr i64*, i64** %data22, i64 1
    %37 = tail call i8* @malloc(i64 40)
    %38 = bitcast i8* %37 to i64*
    store i64* %38, i64** %"130", align 8
    store i64 1, i64* %38, align 8
    %size32 = getelementptr i64, i64* %38, i64 1
    store i64 2, i64* %size32, align 8
    %cap33 = getelementptr i64, i64* %38, i64 2
    store i64 2, i64* %cap33, align 8
    %39 = getelementptr i8, i8* %37, i64 24
    %data34 = bitcast i8* %39 to i64*
    store i64 2, i64* %data34, align 8
    %"136" = getelementptr i64, i64* %data34, i64 1
    store i64 3, i64* %"136", align 8
    %40 = tail call i8* @malloc(i64 40)
    %41 = bitcast i8* %40 to i64*
    store i64* %41, i64** @a__2, align 8
    store i64 1, i64* %41, align 8
    %size38 = getelementptr i64, i64* %41, i64 1
    store i64 2, i64* %size38, align 8
    %cap39 = getelementptr i64, i64* %41, i64 2
    store i64 2, i64* %cap39, align 8
    %42 = getelementptr i8, i8* %40, i64 24
    %data40 = bitcast i8* %42 to i64*
    store i64 4, i64* %data40, align 8
    %"142" = getelementptr i64, i64* %data40, i64 1
    store i64 5, i64* %"142", align 8
    %43 = load i64*, i64** @a__2, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %43)
    %44 = load i64*, i64** @a__2, align 8
    %45 = load i64**, i64*** @nested, align 8
    %46 = bitcast i64** %45 to i64*
    %size43 = getelementptr i64, i64* %46, i64 1
    %size44 = load i64, i64* %size43, align 8
    %cap45 = getelementptr i64, i64* %46, i64 2
    %cap46 = load i64, i64* %cap45, align 8
    %47 = icmp eq i64 %cap46, %size44
    br i1 %47, label %grow48, label %keep47
  
  keep47:                                           ; preds = %merge
    %48 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    br label %merge49
  
  grow48:                                           ; preds = %merge
    %49 = tail call i64** @__ag.ag_grow_aai.aai(i64*** @nested)
    br label %merge49
  
  merge49:                                          ; preds = %grow48, %keep47
    %50 = phi i64** [ %48, %keep47 ], [ %49, %grow48 ]
    %51 = bitcast i64** %50 to i64*
    %52 = bitcast i64** %50 to i8*
    %53 = mul i64 8, %size44
    %54 = add i64 24, %53
    %55 = getelementptr i8, i8* %52, i64 %54
    %data50 = bitcast i8* %55 to i64**
    store i64* %44, i64** %data50, align 8
    %size51 = getelementptr i64, i64* %51, i64 1
    %56 = add i64 %size44, 1
    store i64 %56, i64* %size51, align 8
    %57 = load i64*, i64** @a__2, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %57)
    %58 = load i64*, i64** @a__2, align 8
    %59 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    %60 = bitcast i64** %59 to i8*
    %61 = getelementptr i8, i8* %60, i64 32
    %data52 = bitcast i8* %61 to i64**
    %62 = load i64*, i64** %data52, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %62)
    store i64* %58, i64** %data52, align 8
    %63 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    %64 = bitcast i64** %63 to i8*
    %65 = getelementptr i8, i8* %64, i64 32
    %data53 = bitcast i8* %65 to i64**
    %66 = load i64*, i64** @a__2, align 8
    tail call void @__g.u_incr_rc_ai.u(i64* %66)
    %67 = load i64*, i64** %data53, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %67)
    %68 = load i64*, i64** @a__2, align 8
    store i64* %68, i64** %data53, align 8
    %69 = tail call i8* @malloc(i64 40)
    %70 = bitcast i8* %69 to i64*
    %arr = alloca i64*, align 8
    store i64* %70, i64** %arr, align 8
    store i64 1, i64* %70, align 8
    %size55 = getelementptr i64, i64* %70, i64 1
    store i64 2, i64* %size55, align 8
    %cap56 = getelementptr i64, i64* %70, i64 2
    store i64 2, i64* %cap56, align 8
    %71 = getelementptr i8, i8* %69, i64 24
    %data57 = bitcast i8* %71 to i64*
    store i64 4, i64* %data57, align 8
    %"159" = getelementptr i64, i64* %data57, i64 1
    store i64 5, i64* %"159", align 8
    %72 = load i64**, i64*** @nested, align 8
    %73 = bitcast i64** %72 to i64*
    %size60 = getelementptr i64, i64* %73, i64 1
    %size61 = load i64, i64* %size60, align 8
    %cap62 = getelementptr i64, i64* %73, i64 2
    %cap63 = load i64, i64* %cap62, align 8
    %74 = icmp eq i64 %cap63, %size61
    br i1 %74, label %grow65, label %keep64
  
  keep64:                                           ; preds = %merge49
    %75 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    br label %merge66
  
  grow65:                                           ; preds = %merge49
    %76 = tail call i64** @__ag.ag_grow_aai.aai(i64*** @nested)
    br label %merge66
  
  merge66:                                          ; preds = %grow65, %keep64
    %77 = phi i64** [ %75, %keep64 ], [ %76, %grow65 ]
    %78 = bitcast i8* %69 to i64*
    %79 = bitcast i64** %77 to i64*
    %80 = bitcast i64** %77 to i8*
    %81 = mul i64 8, %size61
    %82 = add i64 24, %81
    %83 = getelementptr i8, i8* %80, i64 %82
    %data67 = bitcast i8* %83 to i64**
    store i64* %78, i64** %data67, align 8
    %size68 = getelementptr i64, i64* %79, i64 1
    %84 = add i64 %size61, 1
    store i64 %84, i64* %size68, align 8
    %85 = tail call i8* @malloc(i64 40)
    %86 = bitcast i8* %85 to i64*
    %arr69 = alloca i64*, align 8
    store i64* %86, i64** %arr69, align 8
    store i64 1, i64* %86, align 8
    %size71 = getelementptr i64, i64* %86, i64 1
    store i64 2, i64* %size71, align 8
    %cap72 = getelementptr i64, i64* %86, i64 2
    store i64 2, i64* %cap72, align 8
    %87 = getelementptr i8, i8* %85, i64 24
    %data73 = bitcast i8* %87 to i64*
    store i64 4, i64* %data73, align 8
    %"175" = getelementptr i64, i64* %data73, i64 1
    store i64 5, i64* %"175", align 8
    %88 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    %89 = bitcast i64** %88 to i8*
    %90 = getelementptr i8, i8* %89, i64 32
    %data76 = bitcast i8* %90 to i64**
    %91 = load i64*, i64** %data76, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %91)
    store i64* %86, i64** %data76, align 8
    %92 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    %93 = bitcast i64** %92 to i8*
    %94 = getelementptr i8, i8* %93, i64 32
    %data77 = bitcast i8* %94 to i64**
    %95 = tail call i8* @malloc(i64 40)
    %96 = bitcast i8* %95 to i64*
    %arr78 = alloca i64*, align 8
    store i64* %96, i64** %arr78, align 8
    store i64 1, i64* %96, align 8
    %size80 = getelementptr i64, i64* %96, i64 1
    store i64 2, i64* %size80, align 8
    %cap81 = getelementptr i64, i64* %96, i64 2
    store i64 2, i64* %cap81, align 8
    %97 = getelementptr i8, i8* %95, i64 24
    %data82 = bitcast i8* %97 to i64*
    store i64 4, i64* %data82, align 8
    %"184" = getelementptr i64, i64* %data82, i64 1
    store i64 5, i64* %"184", align 8
    %98 = load i64*, i64** %data77, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %98)
    store i64* %96, i64** %data77, align 8
    %99 = load i64*, i64** @a__2, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %99)
    %100 = load i64**, i64*** @nested, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %100)
    tail call void @__g.u_decr_rc_ac.u(i8* %26)
    tail call void @__g.u_decr_rc_ac.u(i8* %18)
    %101 = load i64*, i64** @b, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %101)
    %102 = load i64*, i64** @a, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %102)
    ret i64 0
  }
  
  define internal i64** @__ag.ag_reloc_aai.aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %2 = icmp sgt i64 %ref2, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %3 = bitcast i64** %1 to i64*
    %sz = getelementptr i64, i64* %3, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %3, i64 2
    %cap3 = load i64, i64* %cap, align 8
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
    %ref57 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref57, align 8
    call void @__g.u_decr_rc_aai.u(i64** %1)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %rec, %entry
    %12 = load i64**, i64*** %0, align 8
    ret i64** %12
  
  rec:                                              ; preds = %child, %relocate
    %13 = load i64, i64* %cnt, align 8
    %14 = icmp slt i64 %13, %size
    br i1 %14, label %child, label %merge
  
  child:                                            ; preds = %rec
    %15 = bitcast i64** %1 to i8*
    %16 = mul i64 8, %13
    %17 = add i64 24, %16
    %18 = getelementptr i8, i8* %15, i64 %17
    %data = bitcast i8* %18 to i64**
    %19 = load i64*, i64** %data, align 8
    call void @__g.u_incr_rc_ai.u(i64* %19)
    %20 = add i64 %13, 1
    store i64 %20, i64* %cnt, align 8
    br label %rec
  }
  
  define internal void @__g.u_decr_rc_aai.u(i64** %0) {
  entry:
    %ref = bitcast i64** %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64** %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i64** %0 to i64*
    %sz = getelementptr i64, i64* %5, i64 1
    %size = load i64, i64* %sz, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %6 = load i64, i64* %cnt, align 8
    %7 = icmp slt i64 %6, %size
    br i1 %7, label %child, label %cont
  
  child:                                            ; preds = %rec
    %8 = bitcast i64** %0 to i8*
    %9 = mul i64 8, %6
    %10 = add i64 24, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data = bitcast i8* %11 to i64**
    %12 = load i64*, i64** %data, align 8
    call void @__g.u_decr_rc_ai.u(i64* %12)
    %13 = add i64 %6, 1
    store i64 %13, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %14 = bitcast i64** %0 to i64*
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    br label %merge
  }
  
  define internal i64** @__ag.ag_grow_aai.aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %2 = bitcast i64** %1 to i64*
    %cap = getelementptr i64, i64* %2, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %3 = mul i64 %cap1, 2
    %ref7 = bitcast i64* %2 to i64*
    %ref2 = load i64, i64* %ref7, align 8
    %4 = mul i64 %3, 8
    %5 = add i64 %4, 24
    %6 = icmp eq i64 %ref2, 1
    br i1 %6, label %realloc, label %malloc
  
  realloc:                                          ; preds = %entry
    %7 = load i64**, i64*** %0, align 8
    %8 = bitcast i64** %7 to i8*
    %9 = call i8* @realloc(i8* %8, i64 %5)
    %10 = bitcast i8* %9 to i64**
    store i64** %10, i64*** %0, align 8
    br label %merge
  
  malloc:                                           ; preds = %entry
    %11 = bitcast i64** %1 to i64*
    %12 = call i8* @malloc(i64 %5)
    %13 = bitcast i8* %12 to i64**
    %size = getelementptr i64, i64* %11, i64 1
    %size3 = load i64, i64* %size, align 8
    %14 = mul i64 %size3, 8
    %15 = add i64 %14, 24
    %16 = bitcast i64** %13 to i8*
    %17 = bitcast i64** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %16, i8* %17, i64 %15, i1 false)
    store i64** %13, i64*** %0, align 8
    %ref4 = bitcast i64** %13 to i64*
    %ref58 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref58, align 8
    call void @__g.u_decr_rc_aai.u(i64** %1)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %rec, %realloc
    %18 = phi i64** [ %10, %realloc ], [ %20, %rec ]
    %newcap = bitcast i64** %18 to i64*
    %newcap6 = getelementptr i64, i64* %newcap, i64 2
    store i64 %3, i64* %newcap6, align 8
    %19 = load i64**, i64*** %0, align 8
    ret i64** %19
  
  rec:                                              ; preds = %child, %malloc
    %20 = bitcast i8* %12 to i64**
    %21 = load i64, i64* %cnt, align 8
    %22 = icmp slt i64 %21, %size3
    br i1 %22, label %child, label %merge
  
  child:                                            ; preds = %rec
    %23 = bitcast i64** %1 to i8*
    %24 = mul i64 8, %21
    %25 = add i64 24, %24
    %26 = getelementptr i8, i8* %23, i64 %25
    %data = bitcast i8* %26 to i64**
    %27 = load i64*, i64** %data, align 8
    call void @__g.u_incr_rc_ai.u(i64* %27)
    %28 = add i64 %21, 1
    store i64 %28, i64* %cnt, align 8
    br label %rec
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @free(i8* %0)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  3
  2
  3
  2

Decrease ref counts for local variables in if branches
  $ schmu --dump-llvm decr_rc_if.smu && valgrind -q --leak-check=yes --show-reachable=yes ./decr_rc_if
  decr_rc_if.smu:5:10: warning: Unused binding a
  5 |    (let [a [10]]
               ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i1 @schmu_ret-true() {
  entry:
    ret i1 true
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i1 @schmu_ret-true()
    br i1 %0, label %then, label %else
  
  then:                                             ; preds = %entry
    %1 = tail call i8* @malloc(i64 32)
    %2 = bitcast i8* %1 to i64*
    %arr = alloca i64*, align 8
    store i64* %2, i64** %arr, align 8
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 24
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    %4 = tail call i8* @malloc(i64 32)
    %5 = bitcast i8* %4 to i64*
    %arr1 = alloca i64*, align 8
    store i64* %5, i64** %arr1, align 8
    store i64 1, i64* %5, align 8
    %size3 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %size3, align 8
    %cap4 = getelementptr i64, i64* %5, i64 2
    store i64 1, i64* %cap4, align 8
    %6 = getelementptr i8, i8* %4, i64 24
    %data5 = bitcast i8* %6 to i64*
    store i64 10, i64* %data5, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %2)
    br label %ifcont
  
  else:                                             ; preds = %entry
    %7 = tail call i8* @malloc(i64 32)
    %8 = bitcast i8* %7 to i64*
    %arr7 = alloca i64*, align 8
    store i64* %8, i64** %arr7, align 8
    store i64 1, i64* %8, align 8
    %size9 = getelementptr i64, i64* %8, i64 1
    store i64 1, i64* %size9, align 8
    %cap10 = getelementptr i64, i64* %8, i64 2
    store i64 1, i64* %cap10, align 8
    %9 = getelementptr i8, i8* %7, i64 24
    %data11 = bitcast i8* %9 to i64*
    store i64 0, i64* %data11, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %10 = phi i64* [ %5, %then ], [ %8, %else ]
    %iftmp = phi i64** [ %arr1, %then ], [ %arr7, %else ]
    tail call void @__g.u_decr_rc_ai.u(i64* %10)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  declare void @free(i8* %0)

Drop last element
  $ schmu --dump-llvm array_drop_back.smu && valgrind -q --leak-check=yes --show-reachable=yes ./array_drop_back
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @nested = global i64** null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 40)
    %1 = bitcast i8* %0 to i64**
    store i64** %1, i64*** @nested, align 8
    %2 = bitcast i64** %1 to i64*
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 24
    %data = bitcast i8* %3 to i64**
    %4 = tail call i8* @malloc(i64 40)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %data, align 8
    store i64 1, i64* %5, align 8
    %size2 = getelementptr i64, i64* %5, i64 1
    store i64 2, i64* %size2, align 8
    %cap3 = getelementptr i64, i64* %5, i64 2
    store i64 2, i64* %cap3, align 8
    %6 = getelementptr i8, i8* %4, i64 24
    %data4 = bitcast i8* %6 to i64*
    store i64 0, i64* %data4, align 8
    %"1" = getelementptr i64, i64* %data4, i64 1
    store i64 1, i64* %"1", align 8
    %"16" = getelementptr i64*, i64** %data, i64 1
    %7 = tail call i8* @malloc(i64 40)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %"16", align 8
    store i64 1, i64* %8, align 8
    %size8 = getelementptr i64, i64* %8, i64 1
    store i64 2, i64* %size8, align 8
    %cap9 = getelementptr i64, i64* %8, i64 2
    store i64 2, i64* %cap9, align 8
    %9 = getelementptr i8, i8* %7, i64 24
    %data10 = bitcast i8* %9 to i64*
    store i64 2, i64* %data10, align 8
    %"112" = getelementptr i64, i64* %data10, i64 1
    store i64 3, i64* %"112", align 8
    %10 = load i64**, i64*** @nested, align 8
    %11 = bitcast i64** %10 to i64*
    %len = getelementptr i64, i64* %11, i64 1
    %12 = load i64, i64* %len, align 8
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %12)
    %13 = add i32 %fmtsize, 25
    %14 = sext i32 %13 to i64
    %15 = tail call i8* @malloc(i64 %14)
    %16 = bitcast i8* %15 to i64*
    store i64 1, i64* %16, align 8
    %size14 = getelementptr i64, i64* %16, i64 1
    %17 = sext i32 %fmtsize to i64
    store i64 %17, i64* %size14, align 8
    %cap15 = getelementptr i64, i64* %16, i64 2
    store i64 %17, i64* %cap15, align 8
    %data16 = getelementptr i64, i64* %16, i64 3
    %18 = bitcast i64* %data16 to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %18, i64 %14, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %12)
    %str = alloca i8*, align 8
    store i8* %15, i8** %str, align 8
    tail call void @prelude_print(i8* %15)
    %19 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    %20 = bitcast i64** %19 to i64*
    %size17 = getelementptr i64, i64* %20, i64 1
    %size18 = load i64, i64* %size17, align 8
    %21 = icmp sgt i64 %size18, 0
    br i1 %21, label %drop_last, label %cont
  
  drop_last:                                        ; preds = %entry
    %22 = sub i64 %size18, 1
    %23 = bitcast i64** %19 to i8*
    %24 = mul i64 8, %22
    %25 = add i64 24, %24
    %26 = getelementptr i8, i8* %23, i64 %25
    %data19 = bitcast i8* %26 to i64**
    %27 = load i64*, i64** %data19, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %27)
    %28 = bitcast i64** %19 to i8*
    %sunkaddr = getelementptr i8, i8* %28, i64 8
    %29 = bitcast i8* %sunkaddr to i64*
    store i64 %22, i64* %29, align 8
    br label %cont
  
  cont:                                             ; preds = %drop_last, %entry
    %30 = load i64**, i64*** @nested, align 8
    %31 = bitcast i64** %30 to i64*
    %len20 = getelementptr i64, i64* %31, i64 1
    %32 = load i64, i64* %len20, align 8
    %fmtsize21 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %32)
    %33 = add i32 %fmtsize21, 25
    %34 = sext i32 %33 to i64
    %35 = tail call i8* @malloc(i64 %34)
    %36 = bitcast i8* %35 to i64*
    store i64 1, i64* %36, align 8
    %size23 = getelementptr i64, i64* %36, i64 1
    %37 = sext i32 %fmtsize21 to i64
    store i64 %37, i64* %size23, align 8
    %cap24 = getelementptr i64, i64* %36, i64 2
    store i64 %37, i64* %cap24, align 8
    %data25 = getelementptr i64, i64* %36, i64 3
    %38 = bitcast i64* %data25 to i8*
    %fmt26 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %38, i64 %34, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %32)
    %str27 = alloca i8*, align 8
    store i8* %35, i8** %str27, align 8
    tail call void @prelude_print(i8* %35)
    %39 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    %40 = bitcast i64** %39 to i64*
    %size28 = getelementptr i64, i64* %40, i64 1
    %size29 = load i64, i64* %size28, align 8
    %41 = icmp sgt i64 %size29, 0
    br i1 %41, label %drop_last30, label %cont31
  
  drop_last30:                                      ; preds = %cont
    %42 = sub i64 %size29, 1
    %43 = bitcast i64** %39 to i8*
    %44 = mul i64 8, %42
    %45 = add i64 24, %44
    %46 = getelementptr i8, i8* %43, i64 %45
    %data32 = bitcast i8* %46 to i64**
    %47 = load i64*, i64** %data32, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %47)
    %48 = bitcast i64** %39 to i8*
    %sunkaddr54 = getelementptr i8, i8* %48, i64 8
    %49 = bitcast i8* %sunkaddr54 to i64*
    store i64 %42, i64* %49, align 8
    br label %cont31
  
  cont31:                                           ; preds = %drop_last30, %cont
    %50 = load i64**, i64*** @nested, align 8
    %51 = bitcast i64** %50 to i64*
    %len33 = getelementptr i64, i64* %51, i64 1
    %52 = load i64, i64* %len33, align 8
    %fmtsize34 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %52)
    %53 = add i32 %fmtsize34, 25
    %54 = sext i32 %53 to i64
    %55 = tail call i8* @malloc(i64 %54)
    %56 = bitcast i8* %55 to i64*
    store i64 1, i64* %56, align 8
    %size36 = getelementptr i64, i64* %56, i64 1
    %57 = sext i32 %fmtsize34 to i64
    store i64 %57, i64* %size36, align 8
    %cap37 = getelementptr i64, i64* %56, i64 2
    store i64 %57, i64* %cap37, align 8
    %data38 = getelementptr i64, i64* %56, i64 3
    %58 = bitcast i64* %data38 to i8*
    %fmt39 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %58, i64 %54, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %52)
    %str40 = alloca i8*, align 8
    store i8* %55, i8** %str40, align 8
    tail call void @prelude_print(i8* %55)
    %59 = tail call i64** @__ag.ag_reloc_aai.aai(i64*** @nested)
    %60 = bitcast i64** %59 to i64*
    %size41 = getelementptr i64, i64* %60, i64 1
    %size42 = load i64, i64* %size41, align 8
    %61 = icmp sgt i64 %size42, 0
    br i1 %61, label %drop_last43, label %cont44
  
  drop_last43:                                      ; preds = %cont31
    %62 = sub i64 %size42, 1
    %63 = bitcast i64** %59 to i8*
    %64 = mul i64 8, %62
    %65 = add i64 24, %64
    %66 = getelementptr i8, i8* %63, i64 %65
    %data45 = bitcast i8* %66 to i64**
    %67 = load i64*, i64** %data45, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %67)
    %68 = bitcast i64** %59 to i8*
    %sunkaddr55 = getelementptr i8, i8* %68, i64 8
    %69 = bitcast i8* %sunkaddr55 to i64*
    store i64 %62, i64* %69, align 8
    br label %cont44
  
  cont44:                                           ; preds = %drop_last43, %cont31
    %70 = load i64**, i64*** @nested, align 8
    %71 = bitcast i64** %70 to i64*
    %len46 = getelementptr i64, i64* %71, i64 1
    %72 = load i64, i64* %len46, align 8
    %fmtsize47 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %72)
    %73 = add i32 %fmtsize47, 25
    %74 = sext i32 %73 to i64
    %75 = tail call i8* @malloc(i64 %74)
    %76 = bitcast i8* %75 to i64*
    store i64 1, i64* %76, align 8
    %size49 = getelementptr i64, i64* %76, i64 1
    %77 = sext i32 %fmtsize47 to i64
    store i64 %77, i64* %size49, align 8
    %cap50 = getelementptr i64, i64* %76, i64 2
    store i64 %77, i64* %cap50, align 8
    %data51 = getelementptr i64, i64* %76, i64 3
    %78 = bitcast i64* %data51 to i8*
    %fmt52 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %78, i64 %74, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %72)
    %str53 = alloca i8*, align 8
    store i8* %75, i8** %str53, align 8
    tail call void @prelude_print(i8* %75)
    tail call void @__g.u_decr_rc_ac.u(i8* %75)
    tail call void @__g.u_decr_rc_ac.u(i8* %55)
    tail call void @__g.u_decr_rc_ac.u(i8* %35)
    tail call void @__g.u_decr_rc_ac.u(i8* %15)
    %79 = load i64**, i64*** @nested, align 8
    tail call void @__g.u_decr_rc_aai.u(i64** %79)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  define internal i64** @__ag.ag_reloc_aai.aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %2 = icmp sgt i64 %ref2, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %3 = bitcast i64** %1 to i64*
    %sz = getelementptr i64, i64* %3, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %3, i64 2
    %cap3 = load i64, i64* %cap, align 8
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
    %ref57 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref57, align 8
    call void @__g.u_decr_rc_aai.u(i64** %1)
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %rec, %entry
    %12 = load i64**, i64*** %0, align 8
    ret i64** %12
  
  rec:                                              ; preds = %child, %relocate
    %13 = load i64, i64* %cnt, align 8
    %14 = icmp slt i64 %13, %size
    br i1 %14, label %child, label %merge
  
  child:                                            ; preds = %rec
    %15 = bitcast i64** %1 to i8*
    %16 = mul i64 8, %13
    %17 = add i64 24, %16
    %18 = getelementptr i8, i8* %15, i64 %17
    %data = bitcast i8* %18 to i64**
    %19 = load i64*, i64** %data, align 8
    call void @__g.u_incr_rc_ai.u(i64* %19)
    %20 = add i64 %13, 1
    store i64 %20, i64* %cnt, align 8
    br label %rec
  }
  
  define internal void @__g.u_decr_rc_aai.u(i64** %0) {
  entry:
    %ref = bitcast i64** %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64** %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i64** %0 to i64*
    %sz = getelementptr i64, i64* %5, i64 1
    %size = load i64, i64* %sz, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  merge:                                            ; preds = %cont, %decr
    ret void
  
  rec:                                              ; preds = %child, %free
    %6 = load i64, i64* %cnt, align 8
    %7 = icmp slt i64 %6, %size
    br i1 %7, label %child, label %cont
  
  child:                                            ; preds = %rec
    %8 = bitcast i64** %0 to i8*
    %9 = mul i64 8, %6
    %10 = add i64 24, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data = bitcast i8* %11 to i64**
    %12 = load i64*, i64** %data, align 8
    call void @__g.u_decr_rc_ai.u(i64* %12)
    %13 = add i64 %6, 1
    store i64 %13, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %14 = bitcast i64** %0 to i64*
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    br label %merge
  }
  
  define internal void @__g.u_incr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 8
    ret void
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
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
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
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
  2
  1
  0
  0

Global lets with expressions
  $ schmu --dump-llvm global_let.smu && valgrind -q --leak-check=yes --show-reachable=yes ./global_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %prelude.option_array_int = type { i32, i64* }
  %r_array_int = type { i64* }
  
  @b = global i64* null, align 8
  @c = global i64 0, align 8
  
  define void @schmu_ret-none(%prelude.option_array_int* %0) {
  entry:
    %tag1 = bitcast %prelude.option_array_int* %0 to i32*
    store i32 1, i32* %tag1, align 4
    ret void
  }
  
  define i64 @schmu_ret-rec() {
  entry:
    %0 = alloca %r_array_int, align 8
    %a2 = bitcast %r_array_int* %0 to i64**
    %1 = tail call i8* @malloc(i64 48)
    %2 = bitcast i8* %1 to i64*
    %arr = alloca i64*, align 8
    store i64* %2, i64** %arr, align 8
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 3, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 3, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 24
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
  
  declare i8* @malloc(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %ret = alloca %prelude.option_array_int, align 8
    call void @schmu_ret-none(%prelude.option_array_int* %ret)
    %tag5 = bitcast %prelude.option_array_int* %ret to i32*
    %index = load i32, i32* %tag5, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_array_int, %prelude.option_array_int* %ret, i32 0, i32 1
    %0 = load i64*, i64** %data, align 8
    call void @__g.u_incr_rc_ai.u(i64* %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    %1 = call i8* @malloc(i64 40)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** @b, align 8
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 24
    %data1 = bitcast i8* %3 to i64*
    store i64 1, i64* %data1, align 8
    %"1" = getelementptr i64, i64* %data1, i64 1
    store i64 2, i64* %"1", align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi i64** [ %data, %then ], [ @b, %else ]
    %4 = load i64*, i64** %iftmp, align 8
    call void @__g.u_incr_rc_ai.u(i64* %4)
    store i64* %4, i64** @b, align 8
    %ret2 = alloca %r_array_int, align 8
    %5 = call i64 @schmu_ret-rec()
    %box = bitcast %r_array_int* %ret2 to i64*
    store i64 %5, i64* %box, align 8
    %6 = inttoptr i64 %5 to i64*
    %7 = bitcast i64* %6 to i8*
    %8 = getelementptr i8, i8* %7, i64 32
    %data4 = bitcast i8* %8 to i64*
    %9 = load i64, i64* %data4, align 8
    store i64 %9, i64* @c, align 8
    call void @__g.u_decr_rc_rai.u(%r_array_int* %ret2)
    %10 = load i64*, i64** @b, align 8
    call void @__g.u_decr_rc_ai.u(i64* %10)
    %11 = load i64*, i64** %iftmp, align 8
    call void @__g.u_decr_rc_ai.u(i64* %11)
    call void @__g.u_decr_rc_prelude.optionai.u(%prelude.option_array_int* %ret)
    ret i64 0
  }
  
  define internal void @__g.u_incr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = add i64 %ref1, 1
    store i64 %1, i64* %ref2, align 8
    ret void
  }
  
  define internal void @__g.u_decr_rc_rai.u(%r_array_int* %0) {
  entry:
    %1 = bitcast %r_array_int* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %ref2 = bitcast i64* %2 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %3 = icmp eq i64 %ref1, 1
    br i1 %3, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %4 = bitcast i64* %2 to i64*
    %5 = sub i64 %ref1, 1
    store i64 %5, i64* %4, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %6 = bitcast i64* %2 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_prelude.optionai.u(%prelude.option_array_int* %0) {
  entry:
    %tag2 = bitcast %prelude.option_array_int* %0 to i32*
    %index = load i32, i32* %tag2, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %prelude.option_array_int, %prelude.option_array_int* %0, i32 0, i32 1
    %2 = load i64*, i64** %data, align 8
    %ref3 = bitcast i64* %2 to i64*
    %ref1 = load i64, i64* %ref3, align 8
    %3 = icmp eq i64 %ref1, 1
    br i1 %3, label %free, label %decr
  
  cont:                                             ; preds = %decr, %free, %entry
    ret void
  
  decr:                                             ; preds = %match
    %4 = bitcast i64* %2 to i64*
    %5 = sub i64 %ref1, 1
    store i64 %5, i64* %4, align 8
    br label %cont
  
  free:                                             ; preds = %match
    %6 = bitcast i64* %2 to i8*
    call void @free(i8* %6)
    br label %cont
  }
  
  declare void @free(i8* %0)

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
  8
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  0
  8
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
  
  @f = global %closure zeroinitializer, align 16
  @f__2 = global %closure zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @schmu___fun0(i64 %a) {
  entry:
    %add = add i64 %a, 12
    ret i64 %add
  }
  
  define i64 @schmu_named(i64 %a) {
  entry:
    %add = add i64 %a, 13
    ret i64 %add
  }
  
  define void @schmu_ret-fn(%closure* %0) {
  entry:
    %funptr1 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i64)* @schmu___fun0 to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    ret void
  }
  
  define void @schmu_ret-named(%closure* %0) {
  entry:
    %funptr1 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i64)* @schmu_named to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_ret-fn(%closure* @f)
    %loadtmp = load i8*, i8** getelementptr inbounds (%closure, %closure* @f, i32 0, i32 0), align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %loadtmp1 = load i8*, i8** getelementptr inbounds (%closure, %closure* @f, i32 0, i32 1), align 8
    %0 = tail call i64 %casttmp(i64 12, i8* %loadtmp1)
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %0)
    %1 = add i32 %fmtsize, 25
    %2 = sext i32 %1 to i64
    %3 = tail call i8* @malloc(i64 %2)
    %4 = bitcast i8* %3 to i64*
    store i64 1, i64* %4, align 8
    %size = getelementptr i64, i64* %4, i64 1
    %5 = sext i32 %fmtsize to i64
    store i64 %5, i64* %size, align 8
    %cap = getelementptr i64, i64* %4, i64 2
    store i64 %5, i64* %cap, align 8
    %data = getelementptr i64, i64* %4, i64 3
    %6 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %2, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %0)
    %str = alloca i8*, align 8
    store i8* %3, i8** %str, align 8
    tail call void @prelude_print(i8* %3)
    tail call void @schmu_ret-named(%closure* @f__2)
    %loadtmp2 = load i8*, i8** getelementptr inbounds (%closure, %closure* @f__2, i32 0, i32 0), align 8
    %casttmp3 = bitcast i8* %loadtmp2 to i64 (i64, i8*)*
    %loadtmp4 = load i8*, i8** getelementptr inbounds (%closure, %closure* @f__2, i32 0, i32 1), align 8
    %7 = tail call i64 %casttmp3(i64 12, i8* %loadtmp4)
    %fmtsize5 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %7)
    %8 = add i32 %fmtsize5, 25
    %9 = sext i32 %8 to i64
    %10 = tail call i8* @malloc(i64 %9)
    %11 = bitcast i8* %10 to i64*
    store i64 1, i64* %11, align 8
    %size7 = getelementptr i64, i64* %11, i64 1
    %12 = sext i32 %fmtsize5 to i64
    store i64 %12, i64* %size7, align 8
    %cap8 = getelementptr i64, i64* %11, i64 2
    store i64 %12, i64* %cap8, align 8
    %data9 = getelementptr i64, i64* %11, i64 3
    %13 = bitcast i64* %data9 to i8*
    %fmt10 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %13, i64 %9, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %7)
    %str11 = alloca i8*, align 8
    store i8* %10, i8** %str11, align 8
    tail call void @prelude_print(i8* %10)
    tail call void @__g.u_decr_rc_ac.u(i8* %10)
    tail call void @__g.u_decr_rc_i.i.u(%closure* @f__2)
    tail call void @__g.u_decr_rc_ac.u(i8* %3)
    tail call void @__g.u_decr_rc_i.i.u(%closure* @f)
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_i.i.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %nonnull
  
  nonnull:                                          ; preds = %entry
    %ref = bitcast i8* %2 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %4 = icmp eq i64 %ref2, 1
    br i1 %4, label %free, label %decr
  
  ret:                                              ; preds = %decr, %rly_free, %entry
    ret void
  
  decr:                                             ; preds = %nonnull
    %5 = bitcast i8* %2 to i64*
    %6 = bitcast i64* %5 to i64*
    %7 = sub i64 %ref2, 1
    store i64 %7, i64* %6, align 8
    br label %ret
  
  free:                                             ; preds = %nonnull
    %8 = bitcast i8* %2 to i64*
    %dtor3 = getelementptr i64, i64* %8, i64 1
    %9 = bitcast i64* %dtor3 to i8**
    %dtor4 = load i8*, i8** %9, align 8
    %10 = icmp eq i8* %dtor4, null
    br i1 %10, label %rly_free, label %dtor
  
  dtor:                                             ; preds = %free
    %11 = bitcast i8* %2 to i64*
    %dtor5 = bitcast i8* %dtor4 to void (i8*)*
    %12 = bitcast i64* %11 to i8*
    call void %dtor5(i8* %12)
    br label %rly_free
  
  rly_free:                                         ; preds = %dtor, %free
    %13 = bitcast i8* %2 to i64*
    %14 = bitcast i64* %13 to i8*
    call void @free(i8* %14)
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
  
  @f = global %closure zeroinitializer, align 16
  @f2 = global %closure zeroinitializer, align 16
  @f__2 = global %closure zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @prelude_print(i8* %0)
  
  define i64 @schmu___fun0(i64 %a, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i64 }*
    %b = getelementptr inbounds { i64, i8*, i64 }, { i64, i8*, i64 }* %clsr, i32 0, i32 2
    %b1 = load i64, i64* %b, align 8
    %add = add i64 %a, %b1
    ret i64 %add
  }
  
  define i64 @schmu_bla(i64 %a, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i64 }*
    %b = getelementptr inbounds { i64, i8*, i64 }, { i64, i8*, i64 }* %clsr, i32 0, i32 2
    %b1 = load i64, i64* %b, align 8
    %add = add i64 %a, %b1
    ret i64 %add
  }
  
  define void @schmu_ret-fn(%closure* %0, i64 %b) {
  entry:
    %funptr2 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i64, i8*)* @schmu_bla to i8*), i8** %funptr2, align 8
    %1 = tail call i8* @malloc(i64 ptrtoint ({ i64, i8*, i64 }* getelementptr ({ i64, i8*, i64 }, { i64, i8*, i64 }* null, i32 1) to i64))
    %clsr_bla = bitcast i8* %1 to { i64, i8*, i64 }*
    %b1 = getelementptr inbounds { i64, i8*, i64 }, { i64, i8*, i64 }* %clsr_bla, i32 0, i32 2
    store i64 %b, i64* %b1, align 8
    %rc3 = bitcast { i64, i8*, i64 }* %clsr_bla to i64*
    store i64 1, i64* %rc3, align 8
    %dtor = getelementptr inbounds { i64, i8*, i64 }, { i64, i8*, i64 }* %clsr_bla, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %1, i8** %envptr, align 8
    ret void
  }
  
  define void @schmu_ret-lambda(%closure* %0, i64 %b) {
  entry:
    %funptr2 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i64, i8*)* @schmu___fun0 to i8*), i8** %funptr2, align 8
    %1 = tail call i8* @malloc(i64 ptrtoint ({ i64, i8*, i64 }* getelementptr ({ i64, i8*, i64 }, { i64, i8*, i64 }* null, i32 1) to i64))
    %clsr___fun0 = bitcast i8* %1 to { i64, i8*, i64 }*
    %b1 = getelementptr inbounds { i64, i8*, i64 }, { i64, i8*, i64 }* %clsr___fun0, i32 0, i32 2
    store i64 %b, i64* %b1, align 8
    %rc3 = bitcast { i64, i8*, i64 }* %clsr___fun0 to i64*
    store i64 1, i64* %rc3, align 8
    %dtor = getelementptr inbounds { i64, i8*, i64 }, { i64, i8*, i64 }* %clsr___fun0, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %1, i8** %envptr, align 8
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_ret-fn(%closure* @f, i64 13)
    tail call void @schmu_ret-fn(%closure* @f2, i64 35)
    %loadtmp = load i8*, i8** getelementptr inbounds (%closure, %closure* @f, i32 0, i32 0), align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %loadtmp1 = load i8*, i8** getelementptr inbounds (%closure, %closure* @f, i32 0, i32 1), align 8
    %0 = tail call i64 %casttmp(i64 12, i8* %loadtmp1)
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %0)
    %1 = add i32 %fmtsize, 25
    %2 = sext i32 %1 to i64
    %3 = tail call i8* @malloc(i64 %2)
    %4 = bitcast i8* %3 to i64*
    store i64 1, i64* %4, align 8
    %size = getelementptr i64, i64* %4, i64 1
    %5 = sext i32 %fmtsize to i64
    store i64 %5, i64* %size, align 8
    %cap = getelementptr i64, i64* %4, i64 2
    store i64 %5, i64* %cap, align 8
    %data = getelementptr i64, i64* %4, i64 3
    %6 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %2, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %0)
    %str = alloca i8*, align 8
    store i8* %3, i8** %str, align 8
    tail call void @prelude_print(i8* %3)
    %loadtmp2 = load i8*, i8** getelementptr inbounds (%closure, %closure* @f2, i32 0, i32 0), align 8
    %casttmp3 = bitcast i8* %loadtmp2 to i64 (i64, i8*)*
    %loadtmp4 = load i8*, i8** getelementptr inbounds (%closure, %closure* @f2, i32 0, i32 1), align 8
    %7 = tail call i64 %casttmp3(i64 12, i8* %loadtmp4)
    %fmtsize5 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %7)
    %8 = add i32 %fmtsize5, 25
    %9 = sext i32 %8 to i64
    %10 = tail call i8* @malloc(i64 %9)
    %11 = bitcast i8* %10 to i64*
    store i64 1, i64* %11, align 8
    %size7 = getelementptr i64, i64* %11, i64 1
    %12 = sext i32 %fmtsize5 to i64
    store i64 %12, i64* %size7, align 8
    %cap8 = getelementptr i64, i64* %11, i64 2
    store i64 %12, i64* %cap8, align 8
    %data9 = getelementptr i64, i64* %11, i64 3
    %13 = bitcast i64* %data9 to i8*
    %fmt10 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %13, i64 %9, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %7)
    %str11 = alloca i8*, align 8
    store i8* %10, i8** %str11, align 8
    tail call void @prelude_print(i8* %10)
    tail call void @schmu_ret-lambda(%closure* @f__2, i64 134)
    %loadtmp12 = load i8*, i8** getelementptr inbounds (%closure, %closure* @f__2, i32 0, i32 0), align 8
    %casttmp13 = bitcast i8* %loadtmp12 to i64 (i64, i8*)*
    %loadtmp14 = load i8*, i8** getelementptr inbounds (%closure, %closure* @f__2, i32 0, i32 1), align 8
    %14 = tail call i64 %casttmp13(i64 12, i8* %loadtmp14)
    %fmtsize15 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %14)
    %15 = add i32 %fmtsize15, 25
    %16 = sext i32 %15 to i64
    %17 = tail call i8* @malloc(i64 %16)
    %18 = bitcast i8* %17 to i64*
    store i64 1, i64* %18, align 8
    %size17 = getelementptr i64, i64* %18, i64 1
    %19 = sext i32 %fmtsize15 to i64
    store i64 %19, i64* %size17, align 8
    %cap18 = getelementptr i64, i64* %18, i64 2
    store i64 %19, i64* %cap18, align 8
    %data19 = getelementptr i64, i64* %18, i64 3
    %20 = bitcast i64* %data19 to i8*
    %fmt20 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %20, i64 %16, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i64 24), i64 %14)
    %str21 = alloca i8*, align 8
    store i8* %17, i8** %str21, align 8
    tail call void @prelude_print(i8* %17)
    tail call void @__g.u_decr_rc_ac.u(i8* %17)
    tail call void @__g.u_decr_rc_i.i.u(%closure* @f__2)
    tail call void @__g.u_decr_rc_ac.u(i8* %10)
    tail call void @__g.u_decr_rc_ac.u(i8* %3)
    tail call void @__g.u_decr_rc_i.i.u(%closure* @f2)
    tail call void @__g.u_decr_rc_i.i.u(%closure* @f)
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_i.i.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %nonnull
  
  nonnull:                                          ; preds = %entry
    %ref = bitcast i8* %2 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %4 = icmp eq i64 %ref2, 1
    br i1 %4, label %free, label %decr
  
  ret:                                              ; preds = %decr, %rly_free, %entry
    ret void
  
  decr:                                             ; preds = %nonnull
    %5 = bitcast i8* %2 to i64*
    %6 = bitcast i64* %5 to i64*
    %7 = sub i64 %ref2, 1
    store i64 %7, i64* %6, align 8
    br label %ret
  
  free:                                             ; preds = %nonnull
    %8 = bitcast i8* %2 to i64*
    %dtor3 = getelementptr i64, i64* %8, i64 1
    %9 = bitcast i64* %dtor3 to i8**
    %dtor4 = load i8*, i8** %9, align 8
    %10 = icmp eq i8* %dtor4, null
    br i1 %10, label %rly_free, label %dtor
  
  dtor:                                             ; preds = %free
    %11 = bitcast i8* %2 to i64*
    %dtor5 = bitcast i8* %dtor4 to void (i8*)*
    %12 = bitcast i64* %11 to i8*
    call void %dtor5(i8* %12)
    br label %rly_free
  
  rly_free:                                         ; preds = %dtor, %free
    %13 = bitcast i8* %2 to i64*
    %14 = bitcast i64* %13 to i8*
    call void @free(i8* %14)
    br label %ret
  }
  
  declare void @free(i8* %0)
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
  $ schmu --dump-llvm take_partial_alloc.smu && valgrind -q --leak-check=yes --show-reachable=yes ./take_partial_alloc
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %view = type { i8*, i64, i64 }
  %parse-result_int = type { i32, %success_int }
  %success_int = type { %view, i64 }
  %parse-result_view = type { i32, %success_view }
  %success_view = type { %view, %view }
  
  @s = global i8* null, align 8
  @inp = global %view zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [2 x i8] } { i64 2, i64 1, i64 1, [2 x i8] c" \00" }
  
  declare i1 @prelude_char-equal(i8 %0, i8 %1)
  
  define void @schmu_aux(%parse-result_int* %0, %view* %rem, i64 %cnt) {
  entry:
    %1 = alloca %view, align 8
    %2 = bitcast %view* %1 to i8*
    %3 = bitcast %view* %rem to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 24, i1 false)
    %4 = alloca i1, align 1
    store i1 false, i1* %4, align 1
    %5 = alloca i64, align 8
    store i64 %cnt, i64* %5, align 8
    %ret = alloca %parse-result_view, align 8
    br label %rec
  
  rec:                                              ; preds = %cont, %entry
    %6 = phi i1 [ true, %cont ], [ false, %entry ]
    %7 = phi i64 [ %add, %cont ], [ %cnt, %entry ]
    call void @schmu_ch(%parse-result_view* %ret, %view* %1)
    %tag8 = bitcast %parse-result_view* %ret to i32*
    %index = load i32, i32* %tag8, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %data = getelementptr inbounds %parse-result_view, %parse-result_view* %ret, i32 0, i32 1
    call void @__g.u_incr_rc_successview.u(%success_view* %data)
    %8 = bitcast %success_view* %data to %view*
    call void @__g.u_incr_rc_view.u(%view* %8)
    br i1 %6, label %call_decr, label %cookie
  
  call_decr:                                        ; preds = %then
    call void @__g.u_decr_rc_view.u(%view* %1)
    br label %cont
  
  cookie:                                           ; preds = %then
    store i1 true, i1* %4, align 1
    br label %cont
  
  cont:                                             ; preds = %cookie, %call_decr
    %9 = bitcast %success_view* %data to %view*
    %10 = bitcast %view* %1 to i8*
    %11 = bitcast %view* %9 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %11, i64 24, i1 false)
    %add = add i64 %7, 1
    call void @__g.u_decr_rc_parse-resultview.u(%parse-result_view* %ret)
    call void @__g.u_decr_rc_successview.u(%success_view* %data)
    store i64 %add, i64* %5, align 8
    br label %rec
  
  else:                                             ; preds = %rec
    %12 = bitcast %view* %1 to i8*
    %data1 = getelementptr inbounds %parse-result_view, %parse-result_view* %ret, i32 0, i32 1
    %tag29 = bitcast %parse-result_int* %0 to i32*
    store i32 0, i32* %tag29, align 4
    %data3 = getelementptr inbounds %parse-result_int, %parse-result_int* %0, i32 0, i32 1
    %rem410 = bitcast %success_int* %data3 to %view*
    call void @__g.u_incr_rc_view.u(%view* %1)
    %13 = bitcast %view* %rem410 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %13, i8* %12, i64 24, i1 false)
    %mtch = getelementptr inbounds %success_int, %success_int* %data3, i32 0, i32 1
    store i64 %7, i64* %mtch, align 8
    call void @__g.u_decr_rc_parse-resultview.u(%parse-result_view* %ret)
    br i1 %6, label %call_decr5, label %cookie6
  
  call_decr5:                                       ; preds = %else
    call void @__g.u_decr_rc_view.u(%view* %1)
    br label %cont7
  
  cookie6:                                          ; preds = %else
    store i1 true, i1* %4, align 1
    br label %cont7
  
  cont7:                                            ; preds = %cookie6, %call_decr5
    ret void
  }
  
  define void @schmu_ch(%parse-result_view* %0, %view* %buf) {
  entry:
    %1 = bitcast %view* %buf to i8**
    %2 = getelementptr inbounds %view, %view* %buf, i32 0, i32 1
    %3 = load i64, i64* %2, align 8
    %4 = load i8*, i8** %1, align 8
    %5 = add i64 24, %3
    %6 = getelementptr i8, i8* %4, i64 %5
    %7 = load i8, i8* %6, align 1
    %8 = tail call i1 @prelude_char-equal(i8 %7, i8 32)
    br i1 %8, label %then, label %else
  
  then:                                             ; preds = %entry
    %9 = bitcast %view* %buf to i8**
    %tag8 = bitcast %parse-result_view* %0 to i32*
    store i32 0, i32* %tag8, align 4
    %data = getelementptr inbounds %parse-result_view, %parse-result_view* %0, i32 0, i32 1
    %rem9 = bitcast %success_view* %data to %view*
    %buf110 = bitcast %view* %rem9 to i8**
    %10 = load i8*, i8** %9, align 8
    tail call void @__g.u_incr_rc_ac.u(i8* %10)
    %11 = load i8*, i8** %9, align 8
    store i8* %11, i8** %buf110, align 8
    %start = getelementptr inbounds %view, %view* %rem9, i32 0, i32 1
    %12 = bitcast %view* %buf to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %12, i64 8
    %13 = bitcast i8* %sunkaddr to i64*
    %14 = load i64, i64* %13, align 8
    %add = add i64 1, %14
    store i64 %add, i64* %start, align 8
    %len = getelementptr inbounds %view, %view* %rem9, i32 0, i32 2
    %15 = getelementptr inbounds %view, %view* %buf, i32 0, i32 2
    %16 = load i64, i64* %15, align 8
    %sub = sub i64 %16, 1
    store i64 %sub, i64* %len, align 8
    %mtch = getelementptr inbounds %success_view, %success_view* %data, i32 0, i32 1
    %buf211 = bitcast %view* %mtch to i8**
    %17 = load i8*, i8** %9, align 8
    tail call void @__g.u_incr_rc_ac.u(i8* %17)
    %18 = load i8*, i8** %9, align 8
    store i8* %18, i8** %buf211, align 8
    %start3 = getelementptr inbounds %view, %view* %mtch, i32 0, i32 1
    %19 = load i64, i64* %13, align 8
    store i64 %19, i64* %start3, align 8
    %len4 = getelementptr inbounds %view, %view* %mtch, i32 0, i32 2
    store i64 1, i64* %len4, align 8
    ret void
  
  else:                                             ; preds = %entry
    %tag512 = bitcast %parse-result_view* %0 to i32*
    store i32 1, i32* %tag512, align 4
    %data6 = getelementptr inbounds %parse-result_view, %parse-result_view* %0, i32 0, i32 1
    %20 = bitcast %success_view* %data6 to %view*
    tail call void @__g.u_incr_rc_view.u(%view* %buf)
    %21 = bitcast %view* %20 to i8*
    %22 = bitcast %view* %buf to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %21, i8* %22, i64 24, i1 false)
    ret void
  }
  
  define void @schmu_many-count(%parse-result_int* %0, %view* %buf) {
  entry:
    tail call void @schmu_aux(%parse-result_int* %0, %view* %buf, i64 0)
    ret void
  }
  
  define void @schmu_view-of-string(%view* %0, i8* %str) {
  entry:
    %buf2 = bitcast %view* %0 to i8**
    tail call void @__g.u_incr_rc_ac.u(i8* %str)
    store i8* %str, i8** %buf2, align 8
    %start = getelementptr inbounds %view, %view* %0, i32 0, i32 1
    store i64 0, i64* %start, align 8
    %len = getelementptr inbounds %view, %view* %0, i32 0, i32 2
    %1 = bitcast i8* %str to i64*
    %len1 = getelementptr i64, i64* %1, i64 1
    %2 = load i64, i64* %len1, align 8
    store i64 %2, i64* %len, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__g.u_incr_rc_successview.u(%success_view* %0) {
  entry:
    %1 = bitcast %success_view* %0 to %view*
    %2 = bitcast %view* %1 to i8**
    %3 = load i8*, i8** %2, align 8
    %ref = bitcast i8* %3 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %4 = add i64 %ref2, 1
    store i64 %4, i64* %ref16, align 8
    %5 = getelementptr inbounds %success_view, %success_view* %0, i32 0, i32 1
    %6 = bitcast %view* %5 to i8**
    %7 = load i8*, i8** %6, align 8
    %ref3 = bitcast i8* %7 to i64*
    %ref47 = bitcast i64* %ref3 to i64*
    %ref5 = load i64, i64* %ref47, align 8
    %8 = add i64 %ref5, 1
    store i64 %8, i64* %ref47, align 8
    ret void
  }
  
  define internal void @__g.u_incr_rc_view.u(%view* %0) {
  entry:
    %1 = bitcast %view* %0 to i8**
    %2 = load i8*, i8** %1, align 8
    %ref = bitcast i8* %2 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %3 = add i64 %ref2, 1
    store i64 %3, i64* %ref13, align 8
    ret void
  }
  
  define internal void @__g.u_decr_rc_view.u(%view* %0) {
  entry:
    %1 = bitcast %view* %0 to i8**
    %2 = load i8*, i8** %1, align 8
    %ref = bitcast i8* %2 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %3 = icmp eq i64 %ref2, 1
    br i1 %3, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %4 = bitcast i8* %2 to i64*
    %5 = bitcast i64* %4 to i64*
    %6 = sub i64 %ref2, 1
    store i64 %6, i64* %5, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %7 = bitcast i8* %2 to i64*
    %8 = bitcast i64* %7 to i8*
    call void @free(i8* %8)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_parse-resultview.u(%parse-result_view* %0) {
  entry:
    %tag18 = bitcast %parse-result_view* %0 to i32*
    %index = load i32, i32* %tag18, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse-result_view, %parse-result_view* %0, i32 0, i32 1
    %2 = bitcast %success_view* %data to %view*
    %3 = bitcast %view* %2 to i8**
    %4 = load i8*, i8** %3, align 8
    %ref = bitcast i8* %4 to i64*
    %ref119 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref119, align 8
    %5 = icmp eq i64 %ref2, 1
    br i1 %5, label %free, label %decr
  
  cont:                                             ; preds = %decr6, %free7, %entry
    %6 = icmp eq i32 %index, 1
    br i1 %6, label %match9, label %cont10
  
  decr:                                             ; preds = %match
    %7 = bitcast i8* %4 to i64*
    %8 = bitcast i64* %7 to i64*
    %9 = sub i64 %ref2, 1
    store i64 %9, i64* %8, align 8
    br label %merge
  
  free:                                             ; preds = %match
    %10 = bitcast i8* %4 to i64*
    %11 = bitcast i64* %10 to i8*
    call void @free(i8* %11)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    %12 = bitcast %parse-result_view* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %12, i64 32
    %13 = bitcast i8* %sunkaddr to i8**
    %14 = load i8*, i8** %13, align 8
    %ref3 = bitcast i8* %14 to i64*
    %ref420 = bitcast i64* %ref3 to i64*
    %ref5 = load i64, i64* %ref420, align 8
    %15 = icmp eq i64 %ref5, 1
    br i1 %15, label %free7, label %decr6
  
  decr6:                                            ; preds = %merge
    %16 = bitcast i8* %14 to i64*
    %17 = bitcast i64* %16 to i64*
    %18 = sub i64 %ref5, 1
    store i64 %18, i64* %17, align 8
    br label %cont
  
  free7:                                            ; preds = %merge
    %19 = bitcast i8* %14 to i64*
    %20 = bitcast i64* %19 to i8*
    call void @free(i8* %20)
    br label %cont
  
  match9:                                           ; preds = %cont
    %data11 = getelementptr inbounds %parse-result_view, %parse-result_view* %0, i32 0, i32 1
    %21 = bitcast %success_view* %data11 to %view*
    %22 = bitcast %view* %21 to i8**
    %23 = load i8*, i8** %22, align 8
    %ref12 = bitcast i8* %23 to i64*
    %ref1321 = bitcast i64* %ref12 to i64*
    %ref14 = load i64, i64* %ref1321, align 8
    %24 = icmp eq i64 %ref14, 1
    br i1 %24, label %free16, label %decr15
  
  cont10:                                           ; preds = %decr15, %free16, %cont
    ret void
  
  decr15:                                           ; preds = %match9
    %25 = bitcast i8* %23 to i64*
    %26 = bitcast i64* %25 to i64*
    %27 = sub i64 %ref14, 1
    store i64 %27, i64* %26, align 8
    br label %cont10
  
  free16:                                           ; preds = %match9
    %28 = bitcast i8* %23 to i64*
    %29 = bitcast i64* %28 to i8*
    call void @free(i8* %29)
    br label %cont10
  }
  
  define internal void @__g.u_decr_rc_successview.u(%success_view* %0) {
  entry:
    %1 = bitcast %success_view* %0 to %view*
    %2 = bitcast %view* %1 to i8**
    %3 = load i8*, i8** %2, align 8
    %ref = bitcast i8* %3 to i64*
    %ref19 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref19, align 8
    %4 = icmp eq i64 %ref2, 1
    br i1 %4, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %5 = bitcast i8* %3 to i64*
    %6 = bitcast i64* %5 to i64*
    %7 = sub i64 %ref2, 1
    store i64 %7, i64* %6, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %8 = bitcast i8* %3 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    %10 = getelementptr inbounds %success_view, %success_view* %0, i32 0, i32 1
    %11 = bitcast %view* %10 to i8**
    %12 = load i8*, i8** %11, align 8
    %ref3 = bitcast i8* %12 to i64*
    %ref410 = bitcast i64* %ref3 to i64*
    %ref5 = load i64, i64* %ref410, align 8
    %13 = icmp eq i64 %ref5, 1
    br i1 %13, label %free7, label %decr6
  
  decr6:                                            ; preds = %merge
    %14 = bitcast i8* %12 to i64*
    %15 = bitcast i64* %14 to i64*
    %16 = sub i64 %ref5, 1
    store i64 %16, i64* %15, align 8
    br label %merge8
  
  free7:                                            ; preds = %merge
    %17 = bitcast i8* %12 to i64*
    %18 = bitcast i64* %17 to i8*
    call void @free(i8* %18)
    br label %merge8
  
  merge8:                                           ; preds = %free7, %decr6
    ret void
  }
  
  define internal void @__g.u_incr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 8
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [2 x i8] }* @0 to i8*), i64 24))
    %0 = add i32 %fmtsize, 25
    %1 = sext i32 %0 to i64
    %2 = tail call i8* @malloc(i64 %1)
    %3 = bitcast i8* %2 to i64*
    store i64 1, i64* %3, align 8
    %size = getelementptr i64, i64* %3, i64 1
    %4 = sext i32 %fmtsize to i64
    store i64 %4, i64* %size, align 8
    %cap = getelementptr i64, i64* %3, i64 2
    store i64 %4, i64* %cap, align 8
    %data = getelementptr i64, i64* %3, i64 3
    %5 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %1, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [2 x i8] }* @0 to i8*), i64 24))
    store i8* %2, i8** @s, align 8
    tail call void @schmu_view-of-string(%view* @inp, i8* %2)
    %ret = alloca %parse-result_int, align 8
    call void @schmu_many-count(%parse-result_int* %ret, %view* @inp)
    call void @__g.u_decr_rc_parse-resulti.u(%parse-result_int* %ret)
    call void @__g.u_decr_rc_view.u(%view* @inp)
    %6 = load i8*, i8** @s, align 8
    call void @__g.u_decr_rc_ac.u(i8* %6)
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_decr_rc_parse-resulti.u(%parse-result_int* %0) {
  entry:
    %tag12 = bitcast %parse-result_int* %0 to i32*
    %index = load i32, i32* %tag12, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse-result_int, %parse-result_int* %0, i32 0, i32 1
    %2 = bitcast %success_int* %data to %view*
    %3 = bitcast %view* %2 to i8**
    %4 = load i8*, i8** %3, align 8
    %ref = bitcast i8* %4 to i64*
    %ref113 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref113, align 8
    %5 = icmp eq i64 %ref2, 1
    br i1 %5, label %free, label %decr
  
  cont:                                             ; preds = %decr, %free, %entry
    %6 = icmp eq i32 %index, 1
    br i1 %6, label %match3, label %cont4
  
  decr:                                             ; preds = %match
    %7 = bitcast i8* %4 to i64*
    %8 = bitcast i64* %7 to i64*
    %9 = sub i64 %ref2, 1
    store i64 %9, i64* %8, align 8
    br label %cont
  
  free:                                             ; preds = %match
    %10 = bitcast i8* %4 to i64*
    %11 = bitcast i64* %10 to i8*
    call void @free(i8* %11)
    br label %cont
  
  match3:                                           ; preds = %cont
    %data5 = getelementptr inbounds %parse-result_int, %parse-result_int* %0, i32 0, i32 1
    %12 = bitcast %success_int* %data5 to %view*
    %13 = bitcast %view* %12 to i8**
    %14 = load i8*, i8** %13, align 8
    %ref6 = bitcast i8* %14 to i64*
    %ref714 = bitcast i64* %ref6 to i64*
    %ref8 = load i64, i64* %ref714, align 8
    %15 = icmp eq i64 %ref8, 1
    br i1 %15, label %free10, label %decr9
  
  cont4:                                            ; preds = %decr9, %free10, %cont
    ret void
  
  decr9:                                            ; preds = %match3
    %16 = bitcast i8* %14 to i64*
    %17 = bitcast i64* %16 to i64*
    %18 = sub i64 %ref8, 1
    store i64 %18, i64* %17, align 8
    br label %cont4
  
  free10:                                           ; preds = %match3
    %19 = bitcast i8* %14 to i64*
    %20 = bitcast i64* %19 to i8*
    call void @free(i8* %20)
    br label %cont4
  }
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
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
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Increase refcount for returned params in ifs
  $ schmu --dump-llvm if_ret_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./if_ret_param
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @s = global i8* null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"/%s\00" }
  @1 = private unnamed_addr global { i64, i64, i64, [2 x i8] } { i64 2, i64 1, i64 1, [2 x i8] c"/\00" }
  
  define void @schmu_inner(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, %closure, i64 }*
    %limit = getelementptr inbounds { i64, i8*, %closure, i64 }, { i64, i8*, %closure, i64 }* %clsr, i32 0, i32 3
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
    %5 = load i8*, i8** @s, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %6 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %6, align 8
    %casttmp = bitcast i8* %loadtmp to void (i8*, i8*)*
    %sunkaddr4 = getelementptr inbounds i8, i8* %0, i64 24
    %7 = bitcast i8* %sunkaddr4 to i8**
    %loadtmp2 = load i8*, i8** %7, align 8
    tail call void %casttmp(i8* %5, i8* %loadtmp2)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(i8* %value) {
  entry:
    tail call void @__g.u_incr_rc_ac.u(i8* %value)
    tail call void @__g.u_decr_rc_ac.u(i8* %value)
    ret void
  }
  
  define void @schmu_times(i64 %limit, %closure* %f) {
  entry:
    %inner = alloca %closure, align 8
    %funptr5 = bitcast %closure* %inner to i8**
    store i8* bitcast (void (i64, i8*)* @schmu_inner to i8*), i8** %funptr5, align 8
    %clsr_inner = alloca { i64, i8*, %closure, i64 }, align 8
    %f1 = getelementptr inbounds { i64, i8*, %closure, i64 }, { i64, i8*, %closure, i64 }* %clsr_inner, i32 0, i32 2
    %0 = bitcast %closure* %f1 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %limit2 = getelementptr inbounds { i64, i8*, %closure, i64 }, { i64, i8*, %closure, i64 }* %clsr_inner, i32 0, i32 3
    store i64 %limit, i64* %limit2, align 8
    %rc6 = bitcast { i64, i8*, %closure, i64 }* %clsr_inner to i64*
    store i64 2, i64* %rc6, align 8
    %dtor = getelementptr inbounds { i64, i8*, %closure, i64 }, { i64, i8*, %closure, i64 }* %clsr_inner, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, %closure, i64 }* %clsr_inner to i8*
    %envptr = getelementptr inbounds %closure, %closure* %inner, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu_inner(i64 0, i8* %env)
    ret void
  }
  
  define internal void @__g.u_incr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 8
    ret void
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
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
  
  define i64 @main(i64 %arg) {
  entry:
    store i8* bitcast ({ i64, i64, i64, [2 x i8] }* @1 to i8*), i8** @s, align 8
    tail call void @__g.u_incr_rc_ac.u(i8* bitcast ({ i64, i64, i64, [2 x i8] }* @1 to i8*))
    %clstmp = alloca %closure, align 8
    %funptr1 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i8*)* @schmu_test to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu_times(i64 2, %closure* %clstmp)
    %0 = load i8*, i8** @s, align 8
    call void @__g.u_decr_rc_ac.u(i8* %0)
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
  
  @arr = global i64* null, align 8
  @arr__2 = global i64* null, align 8
  
  declare void @prelude_iter-range(i64 %0, i64 %1, %closure* %2)
  
  define void @schmu___aggg.i.u_sort__2_aiii.i.u(i64** %arr, %closure* %cmp) {
  entry:
    %__agii.i-gg.i_partition__2_aiii.i-ii.i = alloca %closure, align 8
    %funptr10 = bitcast %closure* %__agii.i-gg.i_partition__2_aiii.i-ii.i to i8**
    store i8* bitcast (i64 (i64**, i64, i64, i8*)* @schmu___agii.i-gg.i_partition__2_aiii.i-ii.i to i8*), i8** %funptr10, align 8
    %clsr___agii.i-gg.i_partition__2_aiii.i-ii.i = alloca { i64, i8*, %closure }, align 8
    %cmp1 = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___agii.i-gg.i_partition__2_aiii.i-ii.i, i32 0, i32 2
    %0 = bitcast %closure* %cmp1 to i8*
    %1 = bitcast %closure* %cmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %rc11 = bitcast { i64, i8*, %closure }* %clsr___agii.i-gg.i_partition__2_aiii.i-ii.i to i64*
    store i64 2, i64* %rc11, align 8
    %dtor = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___agii.i-gg.i_partition__2_aiii.i-ii.i, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, %closure }* %clsr___agii.i-gg.i_partition__2_aiii.i-ii.i to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__agii.i-gg.i_partition__2_aiii.i-ii.i, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %__agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i = alloca %closure, align 8
    %funptr212 = bitcast %closure* %__agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i to i8**
    store i8* bitcast (void (i64**, i64, i64, i8*)* @schmu___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i to i8*), i8** %funptr212, align 8
    %clsr___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i = alloca { i64, i8*, %closure }, align 8
    %__agii.i-gg.i_partition__2_aiii.i-ii.i3 = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i, i32 0, i32 2
    %2 = bitcast %closure* %__agii.i-gg.i_partition__2_aiii.i-ii.i3 to i8*
    %3 = bitcast %closure* %__agii.i-gg.i_partition__2_aiii.i-ii.i to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 16, i1 false)
    %rc413 = bitcast { i64, i8*, %closure }* %clsr___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i to i64*
    store i64 2, i64* %rc413, align 8
    %dtor5 = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i, i32 0, i32 1
    store i8* null, i8** %dtor5, align 8
    %env6 = bitcast { i64, i8*, %closure }* %clsr___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i to i8*
    %envptr7 = getelementptr inbounds %closure, %closure* %__agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i, i32 0, i32 1
    store i8* %env6, i8** %envptr7, align 8
    %4 = load i64*, i64** %arr, align 8
    %len = getelementptr i64, i64* %4, i64 1
    %5 = load i64, i64* %len, align 8
    %sub = sub i64 %5, 1
    call void @schmu___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i(i64** %arr, i64 0, i64 %sub, i8* %env6)
    ret void
  }
  
  define void @schmu___aggg.i.u_sort_aiii.i.u(i64** %arr, %closure* %cmp) {
  entry:
    %__agii.i-gg.i_partition_aiii.i-ii.i = alloca %closure, align 8
    %funptr10 = bitcast %closure* %__agii.i-gg.i_partition_aiii.i-ii.i to i8**
    store i8* bitcast (i64 (i64**, i64, i64, i8*)* @schmu___agii.i-gg.i_partition_aiii.i-ii.i to i8*), i8** %funptr10, align 8
    %clsr___agii.i-gg.i_partition_aiii.i-ii.i = alloca { i64, i8*, %closure }, align 8
    %cmp1 = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___agii.i-gg.i_partition_aiii.i-ii.i, i32 0, i32 2
    %0 = bitcast %closure* %cmp1 to i8*
    %1 = bitcast %closure* %cmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %rc11 = bitcast { i64, i8*, %closure }* %clsr___agii.i-gg.i_partition_aiii.i-ii.i to i64*
    store i64 2, i64* %rc11, align 8
    %dtor = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___agii.i-gg.i_partition_aiii.i-ii.i, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, %closure }* %clsr___agii.i-gg.i_partition_aiii.i-ii.i to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__agii.i-gg.i_partition_aiii.i-ii.i, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %__agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i = alloca %closure, align 8
    %funptr212 = bitcast %closure* %__agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i to i8**
    store i8* bitcast (void (i64**, i64, i64, i8*)* @schmu___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i to i8*), i8** %funptr212, align 8
    %clsr___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i = alloca { i64, i8*, %closure }, align 8
    %__agii.i-gg.i_partition_aiii.i-ii.i3 = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i, i32 0, i32 2
    %2 = bitcast %closure* %__agii.i-gg.i_partition_aiii.i-ii.i3 to i8*
    %3 = bitcast %closure* %__agii.i-gg.i_partition_aiii.i-ii.i to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 16, i1 false)
    %rc413 = bitcast { i64, i8*, %closure }* %clsr___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i to i64*
    store i64 2, i64* %rc413, align 8
    %dtor5 = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i, i32 0, i32 1
    store i8* null, i8** %dtor5, align 8
    %env6 = bitcast { i64, i8*, %closure }* %clsr___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i to i8*
    %envptr7 = getelementptr inbounds %closure, %closure* %__agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i, i32 0, i32 1
    store i8* %env6, i8** %envptr7, align 8
    %4 = load i64*, i64** %arr, align 8
    %len = getelementptr i64, i64* %4, i64 1
    %5 = load i64, i64* %len, align 8
    %sub = sub i64 %5, 1
    call void @schmu___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i(i64** %arr, i64 0, i64 %sub, i8* %env6)
    ret void
  }
  
  define i64 @schmu___agii.i-gg.i_partition__2_aiii.i-ii.i(i64** %arr, i64 %lo, i64 %hi, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, %closure }*
    %cmp = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr, i32 0, i32 2
    %1 = load i64*, i64** %arr, align 8
    %2 = bitcast i64* %1 to i8*
    %3 = mul i64 8, %hi
    %4 = add i64 24, %3
    %5 = getelementptr i8, i8* %2, i64 %4
    %data = bitcast i8* %5 to i64*
    %pivot = load i64, i64* %data, align 8
    %sub = sub i64 %lo, 1
    %i = alloca i64, align 8
    store i64 %sub, i64* %i, align 8
    %__i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i to i8**
    store i8* bitcast (void (i64, i8*)* @schmu___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i to i8*), i8** %funptr5, align 8
    %clsr___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i = alloca { i64, i8*, i64**, %closure, i64*, i64 }, align 8
    %arr1 = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i, i32 0, i32 2
    store i64** %arr, i64*** %arr1, align 8
    %cmp2 = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i, i32 0, i32 3
    %6 = bitcast %closure* %cmp2 to i8*
    %7 = bitcast %closure* %cmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 16, i1 false)
    %i3 = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i, i32 0, i32 4
    store i64* %i, i64** %i3, align 8
    %pivot4 = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i, i32 0, i32 5
    store i64 %pivot, i64* %pivot4, align 8
    %rc6 = bitcast { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i to i64*
    store i64 2, i64* %rc6, align 8
    %dtor = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @prelude_iter-range(i64 %lo, i64 %hi, %closure* %__i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i)
    %8 = load i64, i64* %i, align 8
    %add = add i64 %8, 1
    call void @schmu___agii.u_swap__2_aiii.u(i64** %arr, i64 %add, i64 %hi)
    ret i64 %add
  }
  
  define i64 @schmu___agii.i-gg.i_partition_aiii.i-ii.i(i64** %arr, i64 %lo, i64 %hi, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, %closure }*
    %cmp = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr, i32 0, i32 2
    %1 = load i64*, i64** %arr, align 8
    %2 = bitcast i64* %1 to i8*
    %3 = mul i64 8, %hi
    %4 = add i64 24, %3
    %5 = getelementptr i8, i8* %2, i64 %4
    %data = bitcast i8* %5 to i64*
    %pivot = load i64, i64* %data, align 8
    %sub = sub i64 %lo, 1
    %i = alloca i64, align 8
    store i64 %sub, i64* %i, align 8
    %__i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i to i8**
    store i8* bitcast (void (i64, i8*)* @schmu___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i to i8*), i8** %funptr5, align 8
    %clsr___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i = alloca { i64, i8*, i64**, %closure, i64*, i64 }, align 8
    %arr1 = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i, i32 0, i32 2
    store i64** %arr, i64*** %arr1, align 8
    %cmp2 = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i, i32 0, i32 3
    %6 = bitcast %closure* %cmp2 to i8*
    %7 = bitcast %closure* %cmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 16, i1 false)
    %i3 = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i, i32 0, i32 4
    store i64* %i, i64** %i3, align 8
    %pivot4 = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i, i32 0, i32 5
    store i64 %pivot, i64* %pivot4, align 8
    %rc6 = bitcast { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i to i64*
    store i64 2, i64* %rc6, align 8
    %dtor = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, i64**, %closure, i64*, i64 }* %clsr___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @prelude_iter-range(i64 %lo, i64 %hi, %closure* %__i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i)
    %8 = load i64, i64* %i, align 8
    %add = add i64 %8, 1
    call void @schmu___agii.u_swap_aiii.u(i64** %arr, i64 %add, i64 %hi)
    ret i64 %add
  }
  
  define void @schmu___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i(i64** %arr, i64 %lo, i64 %hi, i8* %0) {
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
    tail call void @schmu___agii.u-agii.i-gg.i_quicksort__2_aiii.u-aiii.i-ii.i(i64** %arr, i64 %5, i64 %sub, i8* %0)
    store i64** %arr, i64*** %1, align 8
    %add = add i64 %9, 1
    store i64 %add, i64* %3, align 8
    br label %rec
  }
  
  define void @schmu___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i(i64** %arr, i64 %lo, i64 %hi, i8* %0) {
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
    tail call void @schmu___agii.u-agii.i-gg.i_quicksort_aiii.u-aiii.i-ii.i(i64** %arr, i64 %5, i64 %sub, i8* %0)
    store i64** %arr, i64*** %1, align 8
    %add = add i64 %9, 1
    store i64 %add, i64* %3, align 8
    br label %rec
  }
  
  define void @schmu___agii.u_swap__2_aiii.u(i64** %arr, i64 %i, i64 %j) {
  entry:
    %0 = load i64*, i64** %arr, align 8
    %1 = bitcast i64* %0 to i8*
    %2 = mul i64 8, %i
    %3 = add i64 24, %2
    %4 = getelementptr i8, i8* %1, i64 %3
    %data = bitcast i8* %4 to i64*
    %tmp = load i64, i64* %data, align 8
    %5 = tail call i64* @__ag.ag_reloc_ai.ai(i64** %arr)
    %6 = bitcast i64* %5 to i8*
    %7 = getelementptr i8, i8* %6, i64 %3
    %data1 = bitcast i8* %7 to i64*
    %8 = load i64*, i64** %arr, align 8
    %9 = bitcast i64* %8 to i8*
    %10 = mul i64 8, %j
    %11 = add i64 24, %10
    %12 = getelementptr i8, i8* %9, i64 %11
    %data2 = bitcast i8* %12 to i64*
    %13 = load i64, i64* %data2, align 8
    store i64 %13, i64* %data1, align 8
    %14 = tail call i64* @__ag.ag_reloc_ai.ai(i64** %arr)
    %15 = bitcast i64* %14 to i8*
    %16 = getelementptr i8, i8* %15, i64 %11
    %data3 = bitcast i8* %16 to i64*
    store i64 %tmp, i64* %data3, align 8
    ret void
  }
  
  define void @schmu___agii.u_swap_aiii.u(i64** %arr, i64 %i, i64 %j) {
  entry:
    %0 = load i64*, i64** %arr, align 8
    %1 = bitcast i64* %0 to i8*
    %2 = mul i64 8, %i
    %3 = add i64 24, %2
    %4 = getelementptr i8, i8* %1, i64 %3
    %data = bitcast i8* %4 to i64*
    %tmp = load i64, i64* %data, align 8
    %5 = tail call i64* @__ag.ag_reloc_ai.ai(i64** %arr)
    %6 = bitcast i64* %5 to i8*
    %7 = getelementptr i8, i8* %6, i64 %3
    %data1 = bitcast i8* %7 to i64*
    %8 = load i64*, i64** %arr, align 8
    %9 = bitcast i64* %8 to i8*
    %10 = mul i64 8, %j
    %11 = add i64 24, %10
    %12 = getelementptr i8, i8* %9, i64 %11
    %data2 = bitcast i8* %12 to i64*
    %13 = load i64, i64* %data2, align 8
    store i64 %13, i64* %data1, align 8
    %14 = tail call i64* @__ag.ag_reloc_ai.ai(i64** %arr)
    %15 = bitcast i64* %14 to i8*
    %16 = getelementptr i8, i8* %15, i64 %11
    %data3 = bitcast i8* %16 to i64*
    store i64 %tmp, i64* %data3, align 8
    ret void
  }
  
  define i64 @schmu___fun1(i64 %a, i64 %b) {
  entry:
    %sub = sub i64 %a, %b
    ret i64 %sub
  }
  
  define i64 @schmu___fun3(i64 %a, i64 %b) {
  entry:
    %sub = sub i64 %a, %b
    ret i64 %sub
  }
  
  define void @schmu___i.u-ag-gg.i-i-g___fun0_i.u-ai-ii.i-i-i(i64 %j, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i64**, %closure, i64*, i64 }*
    %arr = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 2
    %arr1 = load i64**, i64*** %arr, align 8
    %cmp = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 3
    %i = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 4
    %i2 = load i64*, i64** %i, align 8
    %pivot = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 5
    %pivot3 = load i64, i64* %pivot, align 8
    %1 = load i64*, i64** %arr1, align 8
    %2 = bitcast i64* %1 to i8*
    %3 = mul i64 8, %j
    %4 = add i64 24, %3
    %5 = getelementptr i8, i8* %2, i64 %4
    %data = bitcast i8* %5 to i64*
    %6 = load i64, i64* %data, align 8
    %funcptr5 = bitcast %closure* %cmp to i8**
    %loadtmp = load i8*, i8** %funcptr5, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %cmp, i32 0, i32 1
    %loadtmp4 = load i8*, i8** %envptr, align 8
    %7 = tail call i64 %casttmp(i64 %6, i64 %pivot3, i8* %loadtmp4)
    %lt = icmp slt i64 %7, 0
    br i1 %lt, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %8 = load i64, i64* %i2, align 8
    %add = add i64 %8, 1
    store i64 %add, i64* %i2, align 8
    tail call void @schmu___agii.u_swap_aiii.u(i64** %arr1, i64 %add, i64 %j)
    ret void
  
  ifcont:                                           ; preds = %entry
    ret void
  }
  
  define void @schmu___i.u-ag-gg.i-i-g___fun2_i.u-ai-ii.i-i-i(i64 %j, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i64**, %closure, i64*, i64 }*
    %arr = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 2
    %arr1 = load i64**, i64*** %arr, align 8
    %cmp = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 3
    %i = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 4
    %i2 = load i64*, i64** %i, align 8
    %pivot = getelementptr inbounds { i64, i8*, i64**, %closure, i64*, i64 }, { i64, i8*, i64**, %closure, i64*, i64 }* %clsr, i32 0, i32 5
    %pivot3 = load i64, i64* %pivot, align 8
    %1 = load i64*, i64** %arr1, align 8
    %2 = bitcast i64* %1 to i8*
    %3 = mul i64 8, %j
    %4 = add i64 24, %3
    %5 = getelementptr i8, i8* %2, i64 %4
    %data = bitcast i8* %5 to i64*
    %6 = load i64, i64* %data, align 8
    %funcptr5 = bitcast %closure* %cmp to i8**
    %loadtmp = load i8*, i8** %funcptr5, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %cmp, i32 0, i32 1
    %loadtmp4 = load i8*, i8** %envptr, align 8
    %7 = tail call i64 %casttmp(i64 %6, i64 %pivot3, i8* %loadtmp4)
    %lt = icmp slt i64 %7, 0
    br i1 %lt, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %8 = load i64, i64* %i2, align 8
    %add = add i64 %8, 1
    store i64 %add, i64* %i2, align 8
    tail call void @schmu___agii.u_swap__2_aiii.u(i64** %arr1, i64 %add, i64 %j)
    ret void
  
  ifcont:                                           ; preds = %entry
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 8
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 8
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
    store i64 1, i64* %ref35, align 8
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 72)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @arr, align 8
    store i64 1, i64* %1, align 8
    %size = getelementptr i64, i64* %1, i64 1
    store i64 6, i64* %size, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 6, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 24
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
    %funptr14 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64, i64)* @schmu___fun1 to i8*), i8** %funptr14, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu___aggg.i.u_sort_aiii.i.u(i64** @arr, %closure* %clstmp)
    %3 = call i8* @malloc(i64 72)
    %4 = bitcast i8* %3 to i64*
    store i64* %4, i64** @arr__2, align 8
    store i64 1, i64* %4, align 8
    %size2 = getelementptr i64, i64* %4, i64 1
    store i64 6, i64* %size2, align 8
    %cap3 = getelementptr i64, i64* %4, i64 2
    store i64 6, i64* %cap3, align 8
    %5 = getelementptr i8, i8* %3, i64 24
    %data4 = bitcast i8* %5 to i64*
    store i64 9, i64* %data4, align 8
    %"16" = getelementptr i64, i64* %data4, i64 1
    store i64 30, i64* %"16", align 8
    %"27" = getelementptr i64, i64* %data4, i64 2
    store i64 0, i64* %"27", align 8
    %"38" = getelementptr i64, i64* %data4, i64 3
    store i64 50, i64* %"38", align 8
    %"49" = getelementptr i64, i64* %data4, i64 4
    store i64 2030, i64* %"49", align 8
    %"510" = getelementptr i64, i64* %data4, i64 5
    store i64 34, i64* %"510", align 8
    %clstmp11 = alloca %closure, align 8
    %funptr1215 = bitcast %closure* %clstmp11 to i8**
    store i8* bitcast (i64 (i64, i64)* @schmu___fun3 to i8*), i8** %funptr1215, align 8
    %envptr13 = getelementptr inbounds %closure, %closure* %clstmp11, i32 0, i32 1
    store i8* null, i8** %envptr13, align 8
    call void @schmu___aggg.i.u_sort__2_aiii.i.u(i64** @arr__2, %closure* %clstmp11)
    %6 = load i64*, i64** @arr__2, align 8
    call void @__g.u_decr_rc_ai.u(i64* %6)
    %7 = load i64*, i64** @arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %7)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

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
