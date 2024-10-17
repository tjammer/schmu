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
  
  define i64 @schmu_test(i64 %n) !dbg !2 {
  entry:
    %eq = icmp eq i64 %n, 10
    br i1 %eq, label %ifcont8, label %else, !dbg !5
  
  else:                                             ; preds = %entry
    %lt = icmp slt i64 %n, 1
    br i1 %lt, label %ifcont8, label %else2, !dbg !6
  
  else2:                                            ; preds = %else
    %lt3 = icmp slt i64 %n, 10
    br i1 %lt3, label %ifcont8, label %else5, !dbg !7
  
  else5:                                            ; preds = %else2
    br label %ifcont8
  
  ifcont8:                                          ; preds = %else, %else2, %else5, %entry
    %iftmp9 = phi i64 [ 1, %entry ], [ 2, %else ], [ 4, %else5 ], [ 3, %else2 ]
    ret i64 %iftmp9
  }
  
  define i64 @main(i64 %arg) !dbg !8 {
  entry:
    %0 = tail call i64 @schmu_test(i64 10), !dbg !9
    %eq = icmp eq i64 %0, 1
    tail call void @assert(i1 %eq), !dbg !10
    %1 = tail call i64 @schmu_test(i64 0), !dbg !11
    %eq1 = icmp eq i64 %1, 2
    tail call void @assert(i1 %eq1), !dbg !12
    %2 = tail call i64 @schmu_test(i64 1), !dbg !13
    %eq2 = icmp eq i64 %2, 3
    tail call void @assert(i1 %eq2), !dbg !14
    %3 = tail call i64 @schmu_test(i64 11), !dbg !15
    %eq3 = icmp eq i64 %3, 4
    tail call void @assert(i1 %eq3), !dbg !16
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "elseif.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !1, file: !1, line: 3, type: !3, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 4, column: 5, scope: !2)
  !6 = !DILocation(line: 5, column: 10, scope: !2)
  !7 = !DILocation(line: 6, column: 10, scope: !2)
  !8 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !9 = !DILocation(line: 10, column: 7, scope: !8)
  !10 = !DILocation(line: 10, scope: !8)
  !11 = !DILocation(line: 11, column: 7, scope: !8)
  !12 = !DILocation(line: 11, scope: !8)
  !13 = !DILocation(line: 12, column: 7, scope: !8)
  !14 = !DILocation(line: 12, scope: !8)
  !15 = !DILocation(line: 13, column: 7, scope: !8)
  !16 = !DILocation(line: 13, scope: !8)

Test simple typedef
  $ schmu --dump-llvm stub.o simple_typealias.smu && ./simple_typealias
  simple_typealias.smu:2.10-14: warning: Unused binding puts.
  
  2 | external puts : (foo) -> unit
               ^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @main(i64 %arg) !dbg !2 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "simple_typealias.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}

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
  
  %foo_ = type { i64 }
  %container_ = type { i64, ptr }
  
  @schmu_x = constant %foo_ { i64 1 }
  @schmu_x__2 = internal constant %foo_ { i64 23 }
  @schmu_arr = global ptr null, align 8
  @schmu_arr__2 = global ptr null, align 8
  @schmu_arr__3 = global ptr null, align 8
  @schmu_normal = global ptr null, align 8
  @schmu_nested = global ptr null, align 8
  @schmu_nested__2 = global ptr null, align 8
  @schmu_nested__3 = global ptr null, align 8
  @schmu_rec_of_arr = global %container_ zeroinitializer, align 8
  @schmu_rec_of_arr__2 = global %container_ zeroinitializer, align 8
  @schmu_arr_of_rec = global ptr null, align 8
  @schmu_arr_of_rec__2 = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"hey\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"young\00" }
  @2 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"world\00" }
  
  define linkonce_odr void @__array_push_2al2_al__(ptr noalias %arr, ptr %value) !dbg !2 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5, !dbg !5
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !6
  
  then2:                                            ; preds = %then
    %3 = tail call ptr @realloc(ptr %0, i64 48)
    store ptr %3, ptr %arr, align 8
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 4, ptr %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %1
    %4 = mul i64 %mul, 8
    %5 = add i64 %4, 16
    %6 = tail call ptr @realloc(ptr %0, i64 %5)
    store ptr %6, ptr %arr, align 8
    %newcap3 = getelementptr i64, ptr %6, i64 1
    store i64 %mul, ptr %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %7 = phi ptr [ %6, %else ], [ %3, %then2 ], [ %0, %entry ]
    %8 = getelementptr i8, ptr %7, i64 16
    %9 = getelementptr inbounds ptr, ptr %8, i64 %2
    store ptr %value, ptr %9, align 8
    %10 = load ptr, ptr %arr, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %10, align 8
    ret void
  }
  
  define linkonce_odr void @__array_push_al2_l__(ptr noalias %arr, i64 %0) !dbg !7 {
  entry:
    %value = alloca i64, align 8
    store i64 %0, ptr %value, align 8
    %1 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %1, i64 1
    %2 = load i64, ptr %capacity, align 8
    %3 = load i64, ptr %1, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %then, label %ifcont5, !dbg !8
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %2, 0
    br i1 %eq1, label %then2, label %else, !dbg !9
  
  then2:                                            ; preds = %then
    %4 = tail call ptr @realloc(ptr %1, i64 48)
    store ptr %4, ptr %arr, align 8
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 4, ptr %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %2
    %5 = mul i64 %mul, 8
    %6 = add i64 %5, 16
    %7 = tail call ptr @realloc(ptr %1, i64 %6)
    store ptr %7, ptr %arr, align 8
    %newcap3 = getelementptr i64, ptr %7, i64 1
    store i64 %mul, ptr %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %8 = phi ptr [ %7, %else ], [ %4, %then2 ], [ %1, %entry ]
    %9 = getelementptr i8, ptr %8, i64 16
    %10 = getelementptr inbounds %foo_, ptr %9, i64 %3
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %10, ptr align 8 %value, i64 8, i1 false)
    %11 = load ptr, ptr %arr, align 8
    %add = add i64 %3, 1
    store i64 %add, ptr %11, align 8
    ret void
  }
  
  define void @schmu_arr_inside() !dbg !10 {
  entry:
    %0 = alloca ptr, align 8
    %1 = tail call ptr @malloc(i64 40)
    store ptr %1, ptr %0, align 8
    store i64 3, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 3, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store %foo_ { i64 1 }, ptr %2, align 8
    %"1" = getelementptr %foo_, ptr %2, i64 1
    store %foo_ { i64 2 }, ptr %"1", align 8
    %"2" = getelementptr %foo_, ptr %2, i64 2
    store %foo_ { i64 3 }, ptr %"2", align 8
    call void @__array_push_al2_l__(ptr %0, i64 12), !dbg !11
    call void @__free_al2_(ptr %0)
    ret void
  }
  
  define ptr @schmu_arr_of_records() !dbg !12 {
  entry:
    %0 = tail call ptr @malloc(i64 48)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !13
    store { i64, i64 } %2, ptr %1, align 8
    %"1" = getelementptr %container_, ptr %1, i64 1
    %3 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !14
    store { i64, i64 } %3, ptr %"1", align 8
    ret ptr %0
  }
  
  define void @schmu_inner_parent_scope() !dbg !15 {
  entry:
    %0 = tail call ptr @schmu_make_arr(), !dbg !16
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_al2_(ptr %1)
    ret void
  }
  
  define ptr @schmu_make_arr() !dbg !17 {
  entry:
    %0 = tail call ptr @malloc(i64 40)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 3, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 3, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 8 @schmu_x__2, i64 8, i1 false)
    %"1" = getelementptr %foo_, ptr %1, i64 1
    store %foo_ { i64 2 }, ptr %"1", align 8
    %"2" = getelementptr %foo_, ptr %1, i64 2
    store %foo_ { i64 3 }, ptr %"2", align 8
    ret ptr %0
  }
  
  define ptr @schmu_make_nested_arr() !dbg !18 {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = tail call ptr @malloc(i64 32)
    store ptr %2, ptr %1, align 8
    store i64 2, ptr %2, align 8
    %cap2 = getelementptr i64, ptr %2, i64 1
    store i64 2, ptr %cap2, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i64 0, ptr %3, align 8
    %"1" = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %"1", align 8
    %"14" = getelementptr ptr, ptr %1, i64 1
    %4 = tail call ptr @malloc(i64 32)
    store ptr %4, ptr %"14", align 8
    store i64 2, ptr %4, align 8
    %cap6 = getelementptr i64, ptr %4, i64 1
    store i64 2, ptr %cap6, align 8
    %5 = getelementptr i8, ptr %4, i64 16
    store i64 2, ptr %5, align 8
    %"18" = getelementptr i64, ptr %5, i64 1
    store i64 3, ptr %"18", align 8
    ret ptr %0
  }
  
  define ptr @schmu_nest_allocs() !dbg !19 {
  entry:
    %0 = tail call ptr @schmu_make_nested_arr(), !dbg !20
    ret ptr %0
  }
  
  define ptr @schmu_nest_fns() !dbg !21 {
  entry:
    %0 = tail call ptr @schmu_make_arr(), !dbg !22
    ret ptr %0
  }
  
  define void @schmu_nest_local() !dbg !23 {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = tail call ptr @malloc(i64 32)
    store ptr %2, ptr %1, align 8
    store i64 2, ptr %2, align 8
    %cap2 = getelementptr i64, ptr %2, i64 1
    store i64 2, ptr %cap2, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i64 0, ptr %3, align 8
    %"1" = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %"1", align 8
    %"14" = getelementptr ptr, ptr %1, i64 1
    %4 = tail call ptr @malloc(i64 32)
    store ptr %4, ptr %"14", align 8
    store i64 2, ptr %4, align 8
    %cap6 = getelementptr i64, ptr %4, i64 1
    store i64 2, ptr %cap6, align 8
    %5 = getelementptr i8, ptr %4, i64 16
    store i64 2, ptr %5, align 8
    %"18" = getelementptr i64, ptr %5, i64 1
    store i64 3, ptr %"18", align 8
    call void @__free_2al2_(ptr %arr)
    ret void
  }
  
  define { i64, i64 } @schmu_record_of_arrs() !dbg !24 {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 1, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %"1", align 8
    %2 = alloca %container_, align 8
    store i64 1, ptr %2, align 8
    %arr1 = getelementptr inbounds %container_, ptr %2, i32 0, i32 1
    store ptr %0, ptr %arr1, align 8
    %unbox = load { i64, i64 }, ptr %2, align 8
    ret { i64, i64 } %unbox
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_2al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, ptr %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = getelementptr i8, ptr %1, i64 16
    %5 = getelementptr ptr, ptr %4, i64 %2
    call void @__free_al_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !25 {
  entry:
    %0 = tail call ptr @malloc(i64 40)
    store ptr %0, ptr @schmu_arr, align 8
    store i64 3, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 3, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = alloca ptr, align 8
    store ptr @0, ptr %2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 8 %2, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %1)
    %"1" = getelementptr ptr, ptr %1, i64 1
    %3 = alloca ptr, align 8
    store ptr @1, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %"1", ptr align 8 %3, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %"1")
    %"2" = getelementptr ptr, ptr %1, i64 2
    %4 = alloca ptr, align 8
    store ptr @2, ptr %4, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %"2", ptr align 8 %4, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %"2")
    %5 = tail call ptr @malloc(i64 40)
    store ptr %5, ptr @schmu_arr__2, align 8
    store i64 3, ptr %5, align 8
    %cap2 = getelementptr i64, ptr %5, i64 1
    store i64 3, ptr %cap2, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store %foo_ { i64 1 }, ptr %6, align 8
    %"14" = getelementptr %foo_, ptr %6, i64 1
    store %foo_ { i64 2 }, ptr %"14", align 8
    %"25" = getelementptr %foo_, ptr %6, i64 2
    store %foo_ { i64 3 }, ptr %"25", align 8
    %7 = tail call ptr @schmu_make_arr(), !dbg !26
    store ptr %7, ptr @schmu_arr__3, align 8
    tail call void @schmu_arr_inside(), !dbg !27
    tail call void @schmu_inner_parent_scope(), !dbg !28
    %8 = tail call ptr @schmu_nest_fns(), !dbg !29
    store ptr %8, ptr @schmu_normal, align 8
    %9 = tail call ptr @malloc(i64 32)
    store ptr %9, ptr @schmu_nested, align 8
    store i64 2, ptr %9, align 8
    %cap7 = getelementptr i64, ptr %9, i64 1
    store i64 2, ptr %cap7, align 8
    %10 = getelementptr i8, ptr %9, i64 16
    %11 = tail call ptr @malloc(i64 32)
    store ptr %11, ptr %10, align 8
    store i64 2, ptr %11, align 8
    %cap10 = getelementptr i64, ptr %11, i64 1
    store i64 2, ptr %cap10, align 8
    %12 = getelementptr i8, ptr %11, i64 16
    store i64 0, ptr %12, align 8
    %"112" = getelementptr i64, ptr %12, i64 1
    store i64 1, ptr %"112", align 8
    %"113" = getelementptr ptr, ptr %10, i64 1
    %13 = tail call ptr @malloc(i64 32)
    store ptr %13, ptr %"113", align 8
    store i64 2, ptr %13, align 8
    %cap15 = getelementptr i64, ptr %13, i64 1
    store i64 2, ptr %cap15, align 8
    %14 = getelementptr i8, ptr %13, i64 16
    store i64 2, ptr %14, align 8
    %"117" = getelementptr i64, ptr %14, i64 1
    store i64 3, ptr %"117", align 8
    %15 = tail call ptr @malloc(i64 32)
    %arr = alloca ptr, align 8
    store ptr %15, ptr %arr, align 8
    store i64 2, ptr %15, align 8
    %cap19 = getelementptr i64, ptr %15, i64 1
    store i64 2, ptr %cap19, align 8
    %16 = getelementptr i8, ptr %15, i64 16
    store i64 4, ptr %16, align 8
    %"121" = getelementptr i64, ptr %16, i64 1
    store i64 5, ptr %"121", align 8
    tail call void @__array_push_2al2_al__(ptr @schmu_nested, ptr %15), !dbg !30
    %17 = tail call ptr @schmu_make_nested_arr(), !dbg !31
    store ptr %17, ptr @schmu_nested__2, align 8
    %18 = tail call ptr @schmu_nest_allocs(), !dbg !32
    store ptr %18, ptr @schmu_nested__3, align 8
    tail call void @schmu_nest_local(), !dbg !33
    store i64 12, ptr @schmu_rec_of_arr, align 8
    %19 = tail call ptr @malloc(i64 32)
    %arr22 = alloca ptr, align 8
    store ptr %19, ptr %arr22, align 8
    store i64 2, ptr %19, align 8
    %cap24 = getelementptr i64, ptr %19, i64 1
    store i64 2, ptr %cap24, align 8
    %20 = getelementptr i8, ptr %19, i64 16
    store i64 1, ptr %20, align 8
    %"126" = getelementptr i64, ptr %20, i64 1
    store i64 2, ptr %"126", align 8
    store ptr %19, ptr getelementptr inbounds (%container_, ptr @schmu_rec_of_arr, i32 0, i32 1), align 8
    %21 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !34
    store { i64, i64 } %21, ptr @schmu_rec_of_arr__2, align 8
    %22 = tail call ptr @malloc(i64 48)
    store ptr %22, ptr @schmu_arr_of_rec, align 8
    store i64 2, ptr %22, align 8
    %cap28 = getelementptr i64, ptr %22, i64 1
    store i64 2, ptr %cap28, align 8
    %23 = getelementptr i8, ptr %22, i64 16
    %24 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !35
    store { i64, i64 } %24, ptr %23, align 8
    %"130" = getelementptr %container_, ptr %23, i64 1
    %25 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !36
    store { i64, i64 } %25, ptr %"130", align 8
    %26 = tail call ptr @schmu_arr_of_records(), !dbg !37
    store ptr %26, ptr @schmu_arr_of_rec__2, align 8
    %27 = alloca ptr, align 8
    store ptr %26, ptr %27, align 8
    call void @__free_alal3_(ptr %27)
    call void @__free_alal3_(ptr @schmu_arr_of_rec)
    call void @__free_lal2_(ptr @schmu_rec_of_arr__2)
    call void @__free_lal2_(ptr @schmu_rec_of_arr)
    %28 = alloca ptr, align 8
    store ptr %18, ptr %28, align 8
    call void @__free_2al2_(ptr %28)
    %29 = alloca ptr, align 8
    store ptr %17, ptr %29, align 8
    call void @__free_2al2_(ptr %29)
    call void @__free_2al2_(ptr @schmu_nested)
    %30 = alloca ptr, align 8
    store ptr %8, ptr %30, align 8
    call void @__free_al2_(ptr %30)
    %31 = alloca ptr, align 8
    store ptr %7, ptr %31, align 8
    call void @__free_al2_(ptr %31)
    call void @__free_al2_(ptr @schmu_arr__2)
    call void @__free_2ac2_(ptr @schmu_arr)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__free_lal2_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %container_, ptr %0, i32 0, i32 1
    call void @__free_al_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_alal3_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, ptr %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = getelementptr i8, ptr %1, i64 16
    %5 = getelementptr %container_, ptr %4, i64 %2
    call void @__free_lal2_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_2ac2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, ptr %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = getelementptr i8, ptr %1, i64 16
    %5 = getelementptr ptr, ptr %4, i64 %2
    call void @__free_ac_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "free_array.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_2al2_al__", scope: !1, file: !1, line: 15, type: !3, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 19, column: 5, scope: !2)
  !6 = !DILocation(line: 20, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_al2_l__", scope: !1, file: !1, line: 15, type: !3, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = !DILocation(line: 19, column: 5, scope: !7)
  !9 = !DILocation(line: 20, column: 7, scope: !7)
  !10 = distinct !DISubprogram(name: "arr_inside", linkageName: "schmu_arr_inside", scope: !1, file: !1, line: 11, type: !3, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !11 = !DILocation(line: 14, column: 2, scope: !10)
  !12 = distinct !DISubprogram(name: "arr_of_records", linkageName: "schmu_arr_of_records", scope: !1, file: !1, line: 44, type: !3, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !13 = !DILocation(line: 45, column: 3, scope: !12)
  !14 = !DILocation(line: 45, column: 21, scope: !12)
  !15 = distinct !DISubprogram(name: "inner_parent_scope", linkageName: "schmu_inner_parent_scope", scope: !1, file: !1, line: 21, type: !3, scopeLine: 21, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !16 = !DILocation(line: 22, column: 9, scope: !15)
  !17 = distinct !DISubprogram(name: "make_arr", linkageName: "schmu_make_arr", scope: !1, file: !1, line: 17, type: !3, scopeLine: 17, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !18 = distinct !DISubprogram(name: "make_nested_arr", linkageName: "schmu_make_nested_arr", scope: !1, file: !1, line: 27, type: !3, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !19 = distinct !DISubprogram(name: "nest_allocs", linkageName: "schmu_nest_allocs", scope: !1, file: !1, line: 31, type: !3, scopeLine: 31, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !20 = !DILocation(line: 32, column: 2, scope: !19)
  !21 = distinct !DISubprogram(name: "nest_fns", linkageName: "schmu_nest_fns", scope: !1, file: !1, line: 25, type: !3, scopeLine: 25, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !22 = !DILocation(line: 25, column: 16, scope: !21)
  !23 = distinct !DISubprogram(name: "nest_local", linkageName: "schmu_nest_local", scope: !1, file: !1, line: 35, type: !3, scopeLine: 35, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !24 = distinct !DISubprogram(name: "record_of_arrs", linkageName: "schmu_record_of_arrs", scope: !1, file: !1, line: 39, type: !3, scopeLine: 39, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !25 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !26 = !DILocation(line: 47, column: 10, scope: !25)
  !27 = !DILocation(line: 48, scope: !25)
  !28 = !DILocation(line: 49, scope: !25)
  !29 = !DILocation(line: 50, column: 13, scope: !25)
  !30 = !DILocation(line: 53, scope: !25)
  !31 = !DILocation(line: 54, column: 13, scope: !25)
  !32 = !DILocation(line: 55, column: 13, scope: !25)
  !33 = !DILocation(line: 56, scope: !25)
  !34 = !DILocation(line: 59, column: 17, scope: !25)
  !35 = !DILocation(line: 61, column: 18, scope: !25)
  !36 = !DILocation(line: 61, column: 36, scope: !25)
  !37 = !DILocation(line: 62, column: 17, scope: !25)

Test x86_64-linux-gnu ABI (parts of it, anyway)
  $ schmu --dump-llvm -c abi.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %v3_ = type { double, double, double }
  %i3_ = type { i64, i64, i64 }
  %v4_ = type { double, double, double, double }
  %mixed4_ = type { double, double, double, i64 }
  %trailv2_ = type { i64, i64, double, double }
  %v2_ = type { double, double }
  %i2_ = type { i64, i64 }
  %v1_ = type { double }
  %i1_ = type { i64 }
  %f2s_ = type { float, float }
  %f3s_ = type { float, float, float }
  %shader_ = type { i32, ptr }
  
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"a\00" }
  @1 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"b\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare { double, double } @subv2(double %0, double %1)
  
  declare { i64, i64 } @subi2(i64 %0, i64 %1)
  
  declare double @subv1(double %0)
  
  declare i64 @subi1(i64 %0)
  
  declare void @subv3(ptr noalias %0, ptr byval(%v3_) %1)
  
  declare void @subi3(ptr noalias %0, ptr byval(%i3_) %1)
  
  declare void @subv4(ptr noalias %0, ptr byval(%v4_) %1)
  
  declare void @submixed4(ptr noalias %0, ptr byval(%mixed4_) %1)
  
  declare void @subtrailv2(ptr noalias %0, ptr byval(%trailv2_) %1)
  
  declare <2 x float> @subf2s(<2 x float> %0)
  
  declare { <2 x float>, float } @subf3s(<2 x float> %0, float %1)
  
  declare { i32, i64 } @load_shader(ptr %0, ptr %1)
  
  declare void @set_shader_value(i32 %0, i64 %1, i32 %2, ptr byval(%v4_) %3)
  
  define i64 @main(i64 %arg) !dbg !2 {
  entry:
    %boxconst = alloca %v2_, align 8
    store %v2_ { double 1.000000e+00, double 1.000000e+01 }, ptr %boxconst, align 8
    %fst1 = load double, ptr %boxconst, align 8
    %snd = getelementptr inbounds { double, double }, ptr %boxconst, i32 0, i32 1
    %snd2 = load double, ptr %snd, align 8
    %ret = alloca %v2_, align 8
    %0 = tail call { double, double } @subv2(double %fst1, double %snd2), !dbg !5
    store { double, double } %0, ptr %ret, align 8
    %boxconst3 = alloca %i2_, align 8
    store %i2_ { i64 1, i64 10 }, ptr %boxconst3, align 8
    %fst5 = load i64, ptr %boxconst3, align 8
    %snd6 = getelementptr inbounds { i64, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    %ret8 = alloca %i2_, align 8
    %1 = tail call { i64, i64 } @subi2(i64 %fst5, i64 %snd7), !dbg !6
    store { i64, i64 } %1, ptr %ret8, align 8
    %ret9 = alloca %v1_, align 8
    %2 = tail call double @subv1(double 1.000000e+00), !dbg !7
    store double %2, ptr %ret9, align 8
    %ret10 = alloca %i1_, align 8
    %3 = tail call i64 @subi1(i64 1), !dbg !8
    store i64 %3, ptr %ret10, align 8
    %boxconst11 = alloca %v3_, align 8
    store %v3_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, ptr %boxconst11, align 8
    %ret12 = alloca %v3_, align 8
    call void @subv3(ptr %ret12, ptr %boxconst11), !dbg !9
    %boxconst13 = alloca %i3_, align 8
    store %i3_ { i64 1, i64 10, i64 100 }, ptr %boxconst13, align 8
    %ret14 = alloca %i3_, align 8
    call void @subi3(ptr %ret14, ptr %boxconst13), !dbg !10
    %boxconst15 = alloca %v4_, align 8
    store %v4_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, ptr %boxconst15, align 8
    %ret16 = alloca %v4_, align 8
    call void @subv4(ptr %ret16, ptr %boxconst15), !dbg !11
    %boxconst17 = alloca %mixed4_, align 8
    store %mixed4_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, i64 1 }, ptr %boxconst17, align 8
    %ret18 = alloca %mixed4_, align 8
    call void @submixed4(ptr %ret18, ptr %boxconst17), !dbg !12
    %boxconst19 = alloca %trailv2_, align 8
    store %trailv2_ { i64 1, i64 2, double 1.000000e+00, double 2.000000e+00 }, ptr %boxconst19, align 8
    %ret20 = alloca %trailv2_, align 8
    call void @subtrailv2(ptr %ret20, ptr %boxconst19), !dbg !13
    %ret21 = alloca %f2s_, align 8
    %4 = call <2 x float> @subf2s(<2 x float> <float 2.000000e+00, float 3.000000e+00>), !dbg !14
    store <2 x float> %4, ptr %ret21, align 8
    %boxconst22 = alloca %f3s_, align 8
    store %f3s_ { float 2.000000e+00, float 3.000000e+00, float 5.000000e+00 }, ptr %boxconst22, align 4
    %fst24 = load <2 x float>, ptr %boxconst22, align 8
    %snd25 = getelementptr inbounds { <2 x float>, float }, ptr %boxconst22, i32 0, i32 1
    %snd26 = load float, ptr %snd25, align 4
    %ret27 = alloca %f3s_, align 8
    %5 = call { <2 x float>, float } @subf3s(<2 x float> %fst24, float %snd26), !dbg !15
    store { <2 x float>, float } %5, ptr %ret27, align 8
    %6 = call ptr @string_data(ptr @0), !dbg !16
    %7 = call ptr @string_data(ptr @1), !dbg !17
    %ret28 = alloca %shader_, align 8
    %8 = call { i32, i64 } @load_shader(ptr %6, ptr %7), !dbg !18
    store { i32, i64 } %8, ptr %ret28, align 8
    %9 = alloca %shader_, align 8
    store i32 0, ptr %9, align 4
    %locs = getelementptr inbounds %shader_, ptr %9, i32 0, i32 1
    store ptr null, ptr %locs, align 8
    %boxconst33 = alloca %v4_, align 8
    store %v4_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, ptr %boxconst33, align 8
    call void @set_shader_value(i32 0, i64 0, i32 0, ptr %boxconst33), !dbg !19
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "abi.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 28, column: 8, scope: !2)
  !6 = !DILocation(line: 29, column: 8, scope: !2)
  !7 = !DILocation(line: 30, column: 8, scope: !2)
  !8 = !DILocation(line: 31, column: 8, scope: !2)
  !9 = !DILocation(line: 32, column: 8, scope: !2)
  !10 = !DILocation(line: 33, column: 8, scope: !2)
  !11 = !DILocation(line: 34, column: 8, scope: !2)
  !12 = !DILocation(line: 35, column: 8, scope: !2)
  !13 = !DILocation(line: 36, column: 8, scope: !2)
  !14 = !DILocation(line: 37, column: 8, scope: !2)
  !15 = !DILocation(line: 38, column: 8, scope: !2)
  !16 = !DILocation(line: 39, column: 16, scope: !2)
  !17 = !DILocation(line: 39, column: 28, scope: !2)
  !18 = !DILocation(line: 39, scope: !2)
  !19 = !DILocation(line: 40, scope: !2)

Regression test for issue #19
  $ schmu --dump-llvm stub.o regression_issue_19.smu && ./regression_issue_19
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %v3_ = type { double, double, double }
  
  define void @schmu_v3_add(ptr noalias %0, ptr %lhs, ptr %rhs) !dbg !2 {
  entry:
    %1 = load double, ptr %rhs, align 8
    %2 = load double, ptr %lhs, align 8
    %add = fadd double %2, %1
    store double %add, ptr %0, align 8
    %y = getelementptr inbounds %v3_, ptr %0, i32 0, i32 1
    %3 = getelementptr inbounds %v3_, ptr %lhs, i32 0, i32 1
    %4 = getelementptr inbounds %v3_, ptr %rhs, i32 0, i32 1
    %5 = load double, ptr %4, align 8
    %6 = load double, ptr %3, align 8
    %add1 = fadd double %6, %5
    store double %add1, ptr %y, align 8
    %z = getelementptr inbounds %v3_, ptr %0, i32 0, i32 2
    %7 = getelementptr inbounds %v3_, ptr %lhs, i32 0, i32 2
    %8 = getelementptr inbounds %v3_, ptr %rhs, i32 0, i32 2
    %9 = load double, ptr %8, align 8
    %10 = load double, ptr %7, align 8
    %add2 = fadd double %10, %9
    store double %add2, ptr %z, align 8
    ret void
  }
  
  define void @schmu_v3_scale(ptr noalias %0, ptr %v3, double %factor) !dbg !5 {
  entry:
    %1 = load double, ptr %v3, align 8
    %mul = fmul double %1, %factor
    store double %mul, ptr %0, align 8
    %y = getelementptr inbounds %v3_, ptr %0, i32 0, i32 1
    %2 = getelementptr inbounds %v3_, ptr %v3, i32 0, i32 1
    %3 = load double, ptr %2, align 8
    %mul1 = fmul double %3, %factor
    store double %mul1, ptr %y, align 8
    %z = getelementptr inbounds %v3_, ptr %0, i32 0, i32 2
    %4 = getelementptr inbounds %v3_, ptr %v3, i32 0, i32 2
    %5 = load double, ptr %4, align 8
    %mul2 = fmul double %5, %factor
    store double %mul2, ptr %z, align 8
    ret void
  }
  
  define void @schmu_wrap(ptr noalias %0) !dbg !6 {
  entry:
    %boxconst = alloca %v3_, align 8
    store %v3_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, ptr %boxconst, align 8
    %ret = alloca %v3_, align 8
    call void @schmu_v3_scale(ptr %ret, ptr %boxconst, double 1.500000e+00), !dbg !7
    %boxconst1 = alloca %v3_, align 8
    store %v3_ { double 1.000000e+00, double 2.000000e+00, double 3.000000e+00 }, ptr %boxconst1, align 8
    %ret2 = alloca %v3_, align 8
    call void @schmu_v3_scale(ptr %ret2, ptr %boxconst1, double 1.500000e+00), !dbg !8
    call void @schmu_v3_add(ptr %0, ptr %ret, ptr %ret2), !dbg !9
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !10 {
  entry:
    %ret = alloca %v3_, align 8
    call void @schmu_wrap(ptr %ret), !dbg !11
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "regression_issue_19.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "v3_add", linkageName: "schmu_v3_add", scope: !1, file: !1, line: 3, type: !3, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = distinct !DISubprogram(name: "v3_scale", linkageName: "schmu_v3_scale", scope: !1, file: !1, line: 7, type: !3, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !6 = distinct !DISubprogram(name: "wrap", linkageName: "schmu_wrap", scope: !1, file: !1, line: 11, type: !3, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !7 = !DILocation(line: 12, column: 2, scope: !6)
  !8 = !DILocation(line: 13, column: 10, scope: !6)
  !9 = !DILocation(line: 13, column: 3, scope: !6)
  !10 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !11 = !DILocation(line: 16, column: 7, scope: !10)

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
  
  declare void @string_println(ptr %0)
  
  define i1 @schmu_false_() !dbg !2 {
  entry:
    tail call void @string_println(ptr @0), !dbg !5
    ret i1 false
  }
  
  define i1 @schmu_true_() !dbg !6 {
  entry:
    tail call void @string_println(ptr @1), !dbg !7
    ret i1 true
  }
  
  define i64 @main(i64 %arg) !dbg !8 {
  entry:
    tail call void @string_println(ptr @2), !dbg !9
    %0 = tail call i1 @schmu_true_(), !dbg !10
    br i1 %0, label %true1, label %cont
  
  true1:                                            ; preds = %entry
    %1 = tail call i1 @schmu_true_(), !dbg !11
    br i1 %1, label %true2, label %cont
  
  true2:                                            ; preds = %true1
    br label %cont
  
  cont:                                             ; preds = %true2, %true1, %entry
    %andtmp = phi i1 [ false, %entry ], [ false, %true1 ], [ true, %true2 ]
    br i1 %andtmp, label %then, label %else, !dbg !10
  
  then:                                             ; preds = %cont
    tail call void @string_println(ptr @3), !dbg !12
    br label %ifcont
  
  else:                                             ; preds = %cont
    tail call void @string_println(ptr @4), !dbg !13
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %2 = tail call i1 @schmu_true_(), !dbg !14
    br i1 %2, label %true11, label %cont3
  
  true11:                                           ; preds = %ifcont
    %3 = tail call i1 @schmu_false_(), !dbg !15
    br i1 %3, label %true22, label %cont3
  
  true22:                                           ; preds = %true11
    br label %cont3
  
  cont3:                                            ; preds = %true22, %true11, %ifcont
    %andtmp4 = phi i1 [ false, %ifcont ], [ false, %true11 ], [ true, %true22 ]
    br i1 %andtmp4, label %then5, label %else6, !dbg !14
  
  then5:                                            ; preds = %cont3
    tail call void @string_println(ptr @3), !dbg !16
    br label %ifcont7
  
  else6:                                            ; preds = %cont3
    tail call void @string_println(ptr @4), !dbg !17
    br label %ifcont7
  
  ifcont7:                                          ; preds = %else6, %then5
    %4 = tail call i1 @schmu_false_(), !dbg !18
    br i1 %4, label %true18, label %cont10
  
  true18:                                           ; preds = %ifcont7
    %5 = tail call i1 @schmu_true_(), !dbg !19
    br i1 %5, label %true29, label %cont10
  
  true29:                                           ; preds = %true18
    br label %cont10
  
  cont10:                                           ; preds = %true29, %true18, %ifcont7
    %andtmp11 = phi i1 [ false, %ifcont7 ], [ false, %true18 ], [ true, %true29 ]
    br i1 %andtmp11, label %then12, label %else13, !dbg !18
  
  then12:                                           ; preds = %cont10
    tail call void @string_println(ptr @3), !dbg !20
    br label %ifcont14
  
  else13:                                           ; preds = %cont10
    tail call void @string_println(ptr @4), !dbg !21
    br label %ifcont14
  
  ifcont14:                                         ; preds = %else13, %then12
    %6 = tail call i1 @schmu_false_(), !dbg !22
    br i1 %6, label %true115, label %cont17
  
  true115:                                          ; preds = %ifcont14
    %7 = tail call i1 @schmu_false_(), !dbg !23
    br i1 %7, label %true216, label %cont17
  
  true216:                                          ; preds = %true115
    br label %cont17
  
  cont17:                                           ; preds = %true216, %true115, %ifcont14
    %andtmp18 = phi i1 [ false, %ifcont14 ], [ false, %true115 ], [ true, %true216 ]
    br i1 %andtmp18, label %then19, label %else20, !dbg !22
  
  then19:                                           ; preds = %cont17
    tail call void @string_println(ptr @3), !dbg !24
    br label %ifcont21
  
  else20:                                           ; preds = %cont17
    tail call void @string_println(ptr @4), !dbg !25
    br label %ifcont21
  
  ifcont21:                                         ; preds = %else20, %then19
    tail call void @string_println(ptr @5), !dbg !26
    %8 = tail call i1 @schmu_true_(), !dbg !27
    br i1 %8, label %cont22, label %false1
  
  false1:                                           ; preds = %ifcont21
    %9 = tail call i1 @schmu_true_(), !dbg !28
    br i1 %9, label %cont22, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont22
  
  cont22:                                           ; preds = %false2, %false1, %ifcont21
    %andtmp23 = phi i1 [ true, %ifcont21 ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp23, label %then24, label %else25, !dbg !27
  
  then24:                                           ; preds = %cont22
    tail call void @string_println(ptr @3), !dbg !29
    br label %ifcont26
  
  else25:                                           ; preds = %cont22
    tail call void @string_println(ptr @4), !dbg !30
    br label %ifcont26
  
  ifcont26:                                         ; preds = %else25, %then24
    %10 = tail call i1 @schmu_true_(), !dbg !31
    br i1 %10, label %cont29, label %false127
  
  false127:                                         ; preds = %ifcont26
    %11 = tail call i1 @schmu_false_(), !dbg !32
    br i1 %11, label %cont29, label %false228
  
  false228:                                         ; preds = %false127
    br label %cont29
  
  cont29:                                           ; preds = %false228, %false127, %ifcont26
    %andtmp30 = phi i1 [ true, %ifcont26 ], [ true, %false127 ], [ false, %false228 ]
    br i1 %andtmp30, label %then31, label %else32, !dbg !31
  
  then31:                                           ; preds = %cont29
    tail call void @string_println(ptr @3), !dbg !33
    br label %ifcont33
  
  else32:                                           ; preds = %cont29
    tail call void @string_println(ptr @4), !dbg !34
    br label %ifcont33
  
  ifcont33:                                         ; preds = %else32, %then31
    %12 = tail call i1 @schmu_false_(), !dbg !35
    br i1 %12, label %cont36, label %false134
  
  false134:                                         ; preds = %ifcont33
    %13 = tail call i1 @schmu_true_(), !dbg !36
    br i1 %13, label %cont36, label %false235
  
  false235:                                         ; preds = %false134
    br label %cont36
  
  cont36:                                           ; preds = %false235, %false134, %ifcont33
    %andtmp37 = phi i1 [ true, %ifcont33 ], [ true, %false134 ], [ false, %false235 ]
    br i1 %andtmp37, label %then38, label %else39, !dbg !35
  
  then38:                                           ; preds = %cont36
    tail call void @string_println(ptr @3), !dbg !37
    br label %ifcont40
  
  else39:                                           ; preds = %cont36
    tail call void @string_println(ptr @4), !dbg !38
    br label %ifcont40
  
  ifcont40:                                         ; preds = %else39, %then38
    %14 = tail call i1 @schmu_false_(), !dbg !39
    br i1 %14, label %cont43, label %false141
  
  false141:                                         ; preds = %ifcont40
    %15 = tail call i1 @schmu_false_(), !dbg !40
    br i1 %15, label %cont43, label %false242
  
  false242:                                         ; preds = %false141
    br label %cont43
  
  cont43:                                           ; preds = %false242, %false141, %ifcont40
    %andtmp44 = phi i1 [ true, %ifcont40 ], [ true, %false141 ], [ false, %false242 ]
    br i1 %andtmp44, label %then45, label %else46, !dbg !39
  
  then45:                                           ; preds = %cont43
    tail call void @string_println(ptr @3), !dbg !41
    br label %ifcont47
  
  else46:                                           ; preds = %cont43
    tail call void @string_println(ptr @4), !dbg !42
    br label %ifcont47
  
  ifcont47:                                         ; preds = %else46, %then45
    tail call void @string_println(ptr @6), !dbg !43
    %16 = tail call i1 @schmu_true_(), !dbg !44
    %17 = xor i1 %16, true
    br i1 %17, label %then48, label %else49, !dbg !45
  
  then48:                                           ; preds = %ifcont47
    tail call void @string_println(ptr @3), !dbg !46
    br label %ifcont50
  
  else49:                                           ; preds = %ifcont47
    tail call void @string_println(ptr @4), !dbg !47
    br label %ifcont50
  
  ifcont50:                                         ; preds = %else49, %then48
    %18 = tail call i1 @schmu_false_(), !dbg !48
    %19 = xor i1 %18, true
    br i1 %19, label %then51, label %else52, !dbg !49
  
  then51:                                           ; preds = %ifcont50
    tail call void @string_println(ptr @3), !dbg !50
    br label %ifcont53
  
  else52:                                           ; preds = %ifcont50
    tail call void @string_println(ptr @4), !dbg !51
    br label %ifcont53
  
  ifcont53:                                         ; preds = %else52, %then51
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "boolean_logic.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "false_", linkageName: "schmu_false_", scope: !1, file: !1, line: 6, type: !3, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 7, column: 2, scope: !2)
  !6 = distinct !DISubprogram(name: "true_", linkageName: "schmu_true_", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !7 = !DILocation(line: 2, column: 2, scope: !6)
  !8 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !9 = !DILocation(line: 11, scope: !8)
  !10 = !DILocation(line: 13, column: 3, scope: !8)
  !11 = !DILocation(line: 13, column: 15, scope: !8)
  !12 = !DILocation(line: 14, column: 2, scope: !8)
  !13 = !DILocation(line: 16, column: 2, scope: !8)
  !14 = !DILocation(line: 19, column: 3, scope: !8)
  !15 = !DILocation(line: 19, column: 15, scope: !8)
  !16 = !DILocation(line: 20, column: 2, scope: !8)
  !17 = !DILocation(line: 22, column: 2, scope: !8)
  !18 = !DILocation(line: 25, column: 3, scope: !8)
  !19 = !DILocation(line: 25, column: 16, scope: !8)
  !20 = !DILocation(line: 26, column: 2, scope: !8)
  !21 = !DILocation(line: 28, column: 2, scope: !8)
  !22 = !DILocation(line: 31, column: 3, scope: !8)
  !23 = !DILocation(line: 31, column: 16, scope: !8)
  !24 = !DILocation(line: 32, column: 2, scope: !8)
  !25 = !DILocation(line: 34, column: 2, scope: !8)
  !26 = !DILocation(line: 37, scope: !8)
  !27 = !DILocation(line: 39, column: 3, scope: !8)
  !28 = !DILocation(line: 39, column: 14, scope: !8)
  !29 = !DILocation(line: 40, column: 2, scope: !8)
  !30 = !DILocation(line: 42, column: 2, scope: !8)
  !31 = !DILocation(line: 45, column: 3, scope: !8)
  !32 = !DILocation(line: 45, column: 14, scope: !8)
  !33 = !DILocation(line: 46, column: 2, scope: !8)
  !34 = !DILocation(line: 48, column: 2, scope: !8)
  !35 = !DILocation(line: 51, column: 3, scope: !8)
  !36 = !DILocation(line: 51, column: 15, scope: !8)
  !37 = !DILocation(line: 52, column: 2, scope: !8)
  !38 = !DILocation(line: 54, column: 2, scope: !8)
  !39 = !DILocation(line: 57, column: 3, scope: !8)
  !40 = !DILocation(line: 57, column: 15, scope: !8)
  !41 = !DILocation(line: 58, column: 2, scope: !8)
  !42 = !DILocation(line: 60, column: 2, scope: !8)
  !43 = !DILocation(line: 63, scope: !8)
  !44 = !DILocation(line: 65, column: 7, scope: !8)
  !45 = !DILocation(line: 65, column: 3, scope: !8)
  !46 = !DILocation(line: 66, column: 2, scope: !8)
  !47 = !DILocation(line: 68, column: 2, scope: !8)
  !48 = !DILocation(line: 71, column: 7, scope: !8)
  !49 = !DILocation(line: 71, column: 3, scope: !8)
  !50 = !DILocation(line: 72, column: 2, scope: !8)
  !51 = !DILocation(line: 74, column: 2, scope: !8)
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
  
  define i64 @main(i64 %arg) !dbg !2 {
  entry:
    ret i64 -2
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "unary_minus.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
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
  
  12 | fun use_unused3() {
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
  
  2 | if true{2}
      ^^^^^^^^^^
  
  [1]

Tailcall loops
  $ schmu --dump-llvm stub.o regression_issue_26.smu && ./regression_issue_26
  regression_issue_26.smu:27.9-15: warning: Unused binding nested.
  
  27 | fun rec nested(a, b, c) {
               ^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_limit = constant i64 3
  @0 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"%i, %i\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [12 x i8] } { i64 11, i64 11, [12 x i8] c"%i, %i, %i\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"\0A\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare void @printf(ptr %0, i64 %1, i64 %2, i64 %3)
  
  define void @schmu_nested(i64 %a, i64 %b) !dbg !2 {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, ptr %1, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %entry, %then
    %.ph = phi i64 [ %a, %entry ], [ %add, %then ]
    %.ph6 = phi i64 [ %b, %entry ], [ 0, %then ]
    br label %rec, !dbg !5
  
  rec:                                              ; preds = %rec.outer, %else3
    %2 = phi i64 [ %add4, %else3 ], [ %.ph6, %rec.outer ]
    %eq = icmp eq i64 %2, 3
    br i1 %eq, label %then, label %else, !dbg !5
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph, 1
    store i64 %add, ptr %0, align 8
    store i64 0, ptr %1, align 8
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %.ph, 3
    br i1 %eq1, label %then2, label %else3, !dbg !6
  
  then2:                                            ; preds = %else
    ret void
  
  else3:                                            ; preds = %else
    %3 = tail call ptr @string_data(ptr @0), !dbg !7
    tail call void @printf(ptr %3, i64 %.ph, i64 %2, i64 0), !dbg !8
    %add4 = add i64 %2, 1
    store i64 %add4, ptr %1, align 8
    br label %rec
  }
  
  define void @schmu_nested__2(i64 %a, i64 %b, i64 %c) !dbg !9 {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 %c, ptr %2, align 8
    br label %rec.outer.outer
  
  rec.outer.outer:                                  ; preds = %then, %entry
    %.ph.ph = phi i64 [ 0, %then ], [ %b, %entry ]
    %.ph11.ph = phi i64 [ %add, %then ], [ %a, %entry ]
    %.ph13.ph = phi i64 [ %4, %then ], [ %c, %entry ]
    br label %rec.outer, !dbg !10
  
  rec.outer:                                        ; preds = %rec.outer.outer, %then2
    %.ph = phi i64 [ %add3, %then2 ], [ %.ph.ph, %rec.outer.outer ]
    %.ph12 = phi i64 [ %3, %then2 ], [ %.ph11.ph, %rec.outer.outer ]
    %.ph13 = phi i64 [ 0, %then2 ], [ %.ph13.ph, %rec.outer.outer ]
    br label %rec, !dbg !10
  
  rec:                                              ; preds = %rec.outer, %else7
    %3 = phi i64 [ %.ph11.ph, %else7 ], [ %.ph12, %rec.outer ]
    %4 = phi i64 [ %add8, %else7 ], [ %.ph13, %rec.outer ]
    %eq = icmp eq i64 %.ph, 3
    br i1 %eq, label %then, label %else, !dbg !10
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph11.ph, 1
    store i64 %add, ptr %0, align 8
    store i64 0, ptr %1, align 8
    br label %rec.outer.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %4, 3
    br i1 %eq1, label %then2, label %else4, !dbg !11
  
  then2:                                            ; preds = %else
    %add3 = add i64 %.ph, 1
    store i64 %add3, ptr %1, align 8
    store i64 0, ptr %2, align 8
    br label %rec.outer
  
  else4:                                            ; preds = %else
    %eq5 = icmp eq i64 %3, 3
    br i1 %eq5, label %then6, label %else7, !dbg !12
  
  then6:                                            ; preds = %else4
    ret void
  
  else7:                                            ; preds = %else4
    %5 = tail call ptr @string_data(ptr @1), !dbg !13
    tail call void @printf(ptr %5, i64 %.ph11.ph, i64 %.ph, i64 %4), !dbg !14
    %add8 = add i64 %4, 1
    store i64 %add8, ptr %2, align 8
    br label %rec
  }
  
  define void @schmu_nested__3(i64 %a, i64 %b, i64 %c) !dbg !15 {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 %c, ptr %2, align 8
    br label %rec.outer.outer
  
  rec.outer.outer:                                  ; preds = %then, %entry
    %.ph.ph = phi i64 [ 0, %then ], [ %b, %entry ]
    %.ph10.ph = phi i64 [ %add, %then ], [ %a, %entry ]
    %.ph11.ph = phi i64 [ %3, %then ], [ %c, %entry ]
    br label %rec.outer, !dbg !16
  
  rec.outer:                                        ; preds = %rec.outer.outer, %then5
    %.ph = phi i64 [ %add6, %then5 ], [ %.ph.ph, %rec.outer.outer ]
    %.ph11 = phi i64 [ 0, %then5 ], [ %.ph11.ph, %rec.outer.outer ]
    %.ph12 = phi i64 [ %4, %then5 ], [ %.ph10.ph, %rec.outer.outer ]
    br label %rec, !dbg !16
  
  rec:                                              ; preds = %rec.outer, %else7
    %3 = phi i64 [ %add8, %else7 ], [ %.ph11, %rec.outer ]
    %4 = phi i64 [ %.ph10.ph, %else7 ], [ %.ph12, %rec.outer ]
    %eq = icmp eq i64 %.ph, 3
    br i1 %eq, label %then, label %else, !dbg !16
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph10.ph, 1
    store i64 %add, ptr %0, align 8
    store i64 0, ptr %1, align 8
    br label %rec.outer.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %4, 3
    br i1 %eq1, label %then2, label %else3, !dbg !17
  
  then2:                                            ; preds = %else
    ret void
  
  else3:                                            ; preds = %else
    %eq4 = icmp eq i64 %3, 3
    br i1 %eq4, label %then5, label %else7, !dbg !18
  
  then5:                                            ; preds = %else3
    %add6 = add i64 %.ph, 1
    store i64 %add6, ptr %1, align 8
    store i64 0, ptr %2, align 8
    br label %rec.outer
  
  else7:                                            ; preds = %else3
    %5 = tail call ptr @string_data(ptr @1), !dbg !19
    tail call void @printf(ptr %5, i64 %.ph10.ph, i64 %.ph, i64 %3), !dbg !20
    %add8 = add i64 %3, 1
    store i64 %add8, ptr %2, align 8
    br label %rec
  }
  
  define i64 @main(i64 %arg) !dbg !21 {
  entry:
    tail call void @schmu_nested(i64 0, i64 0), !dbg !22
    %0 = tail call ptr @string_data(ptr @2), !dbg !23
    tail call void @printf(ptr %0, i64 0, i64 0, i64 0), !dbg !24
    tail call void @schmu_nested__2(i64 0, i64 0, i64 0), !dbg !25
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "regression_issue_26.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "nested", linkageName: "schmu_nested", scope: !1, file: !1, line: 6, type: !3, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 7, column: 5, scope: !2)
  !6 = !DILocation(line: 8, column: 10, scope: !2)
  !7 = !DILocation(line: 10, column: 11, scope: !2)
  !8 = !DILocation(line: 10, column: 4, scope: !2)
  !9 = distinct !DISubprogram(name: "nested", linkageName: "schmu_nested__2", scope: !1, file: !1, line: 17, type: !3, scopeLine: 17, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !10 = !DILocation(line: 18, column: 5, scope: !9)
  !11 = !DILocation(line: 19, column: 10, scope: !9)
  !12 = !DILocation(line: 20, column: 10, scope: !9)
  !13 = !DILocation(line: 22, column: 11, scope: !9)
  !14 = !DILocation(line: 22, column: 4, scope: !9)
  !15 = distinct !DISubprogram(name: "nested", linkageName: "schmu_nested__3", scope: !1, file: !1, line: 27, type: !3, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !16 = !DILocation(line: 28, column: 5, scope: !15)
  !17 = !DILocation(line: 29, column: 10, scope: !15)
  !18 = !DILocation(line: 30, column: 10, scope: !15)
  !19 = !DILocation(line: 32, column: 11, scope: !15)
  !20 = !DILocation(line: 32, column: 4, scope: !15)
  !21 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !22 = !DILocation(line: 14, scope: !21)
  !23 = !DILocation(line: 16, column: 7, scope: !21)
  !24 = !DILocation(line: 16, scope: !21)
  !25 = !DILocation(line: 26, scope: !21)
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
  
  %v_ = type { double, double, double }
  
  @schmu_acc_force = internal constant double 1.000000e+02
  
  declare double @dot(ptr byval(%v_) %0, ptr byval(%v_) %1)
  
  declare void @norm(ptr noalias %0, ptr byval(%v_) %1)
  
  declare void @scale(ptr noalias %0, ptr byval(%v_) %1, double %2)
  
  declare i1 @maybe()
  
  define void @schmu_calc_acc(ptr noalias %0, ptr %vel) !dbg !2 {
  entry:
    %1 = tail call double @dot(ptr %vel, ptr %vel), !dbg !5
    %gt = fcmp ogt double %1, 1.000000e-01
    br i1 %gt, label %then, label %else, !dbg !5
  
  then:                                             ; preds = %entry
    %ret = alloca %v_, align 8
    call void @norm(ptr %ret, ptr %vel), !dbg !6
    br label %ifcont
  
  else:                                             ; preds = %entry
    %2 = alloca %v_, align 8
    store %v_ { double 1.000000e+00, double 0.000000e+00, double 0.000000e+00 }, ptr %2, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %ret, %then ], [ %2, %else ]
    %3 = call i1 @maybe(), !dbg !7
    br i1 %3, label %then1, label %else2, !dbg !7
  
  then1:                                            ; preds = %ifcont
    call void @scale(ptr %0, ptr %iftmp, double 1.000000e+02), !dbg !8
    br label %ifcont6
  
  else2:                                            ; preds = %ifcont
    %4 = call i1 @maybe(), !dbg !9
    br i1 %4, label %then3, label %else4, !dbg !9
  
  then3:                                            ; preds = %else2
    call void @scale(ptr %0, ptr %iftmp, double -3.000000e+02), !dbg !10
    br label %ifcont6
  
  else4:                                            ; preds = %else2
    call void @scale(ptr %0, ptr %iftmp, double 1.000000e-01), !dbg !11
    br label %ifcont6
  
  ifcont6:                                          ; preds = %then3, %else4, %then1
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !12 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "regression_issue_30.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "calc_acc", linkageName: "schmu_calc_acc", scope: !1, file: !1, line: 8, type: !3, scopeLine: 8, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 10, column: 7, scope: !2)
  !6 = !DILocation(line: 11, column: 6, scope: !2)
  !7 = !DILocation(line: 15, column: 15, scope: !2)
  !8 = !DILocation(line: 15, column: 24, scope: !2)
  !9 = !DILocation(line: 16, column: 12, scope: !2)
  !10 = !DILocation(line: 16, column: 21, scope: !2)
  !11 = !DILocation(line: 17, column: 10, scope: !2)
  !12 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)

Piping for ctors and field accessors
  $ schmu stub.o --dump-llvm piping.smu && ./piping
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tl_ = type { i32, i64 }
  
  @0 = private unnamed_addr constant { i64, i64, [1 x [1 x i8]] } { i64 0, i64 1, [1 x [1 x i8]] zeroinitializer }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%c\0A\00" }
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare ptr @string_of_array(ptr %0)
  
  declare void @string_println(ptr %0)
  
  declare void @Printi(i64 %0)
  
  define i64 @__fun_schmu0(i64 %x) !dbg !2 {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @__fun_schmu1(i32 %0, i64 %1) !dbg !5 {
  entry:
    %x = alloca { i32, i64 }, align 8
    store i32 %0, ptr %x, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %x, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else, !dbg !6
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) !dbg !7 {
  entry:
    %0 = tail call i64 @__fun_schmu0(i64 1), !dbg !8
    tail call void @Printi(i64 %0), !dbg !9
    %boxconst = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %1 = tail call i64 @__fun_schmu1(i32 %fst1, i64 %snd2), !dbg !10
    tail call void @Printi(i64 %1), !dbg !11
    tail call void @Printi(i64 1), !dbg !12
    tail call void @string_println(ptr @0), !dbg !13
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @1, i64 16), i64 10)
    %2 = tail call ptr @malloc(i64 19)
    %arr = alloca ptr, align 8
    store ptr %2, ptr %arr, align 8
    store i64 3, ptr %2, align 8
    %cap = getelementptr i64, ptr %2, i64 1
    store i64 3, ptr %cap, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i8 97, ptr %3, align 1
    %"1" = getelementptr i8, ptr %3, i64 1
    store i8 98, ptr %"1", align 1
    %"2" = getelementptr i8, ptr %3, i64 2
    store i8 99, ptr %"2", align 1
    %4 = tail call ptr @string_of_array(ptr %2), !dbg !14
    %5 = tail call i8 @string_get(ptr %4, i64 1), !dbg !15
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @2, i64 16), i8 %5)
    %6 = alloca ptr, align 8
    store ptr %4, ptr %6, align 8
    call void @__free_ac_(ptr %6)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "piping.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !1, file: !1, line: 4, type: !3, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1", scope: !1, file: !1, line: 7, type: !3, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !6 = !DILocation(line: 8, column: 2, scope: !5)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = !DILocation(line: 4, column: 3, scope: !7)
  !9 = !DILocation(line: 4, column: 20, scope: !7)
  !10 = !DILocation(line: 7, column: 2, scope: !7)
  !11 = !DILocation(line: 10, column: 6, scope: !7)
  !12 = !DILocation(line: 14, column: 10, scope: !7)
  !13 = !DILocation(line: 15, scope: !7)
  !14 = !DILocation(line: 17, column: 16, scope: !7)
  !15 = !DILocation(line: 17, column: 34, scope: !7)
  
  2
  1
  1
  10
  b

Function calls for known functions act as annotations to decide which ctor or record to use.
Prints nothing, just works
  $ schmu function_call_annot.smu

Ensure global are loadad correctly when passed to functions
  $ schmu --dump-llvm regression_load_global.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %bar_ = type { double, double, i64, double, double, float }
  
  @schmu_height = constant i64 720
  @schmu_world = global %bar_ zeroinitializer, align 8
  
  define linkonce_odr void @__schmu_get_seg_2dl2df__(ptr %bar) !dbg !2 {
  entry:
    ret void
  }
  
  define void @schmu_wrap_seg() !dbg !5 {
  entry:
    tail call void @__schmu_get_seg_2dl2df__(ptr @schmu_world), !dbg !6
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !7 {
  entry:
    store double 0.000000e+00, ptr @schmu_world, align 8
    store double 1.280000e+03, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 1), align 8
    store i64 10, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 2), align 8
    store double 1.000000e-01, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 3), align 8
    store double 5.400000e+02, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 4), align 8
    store float 5.000000e+00, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 5), align 4
    tail call void @schmu_wrap_seg(), !dbg !8
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "regression_load_global.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "get_seg", linkageName: "__schmu_get_seg_2dl2df__", scope: !1, file: !1, line: 16, type: !3, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = distinct !DISubprogram(name: "wrap_seg", linkageName: "schmu_wrap_seg", scope: !1, file: !1, line: 18, type: !3, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !6 = !DILocation(line: 18, column: 16, scope: !5)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = !DILocation(line: 20, scope: !7)


Array push
  $ schmu --dump-llvm array_push.smu && valgrind -q --leak-check=yes --show-reachable=yes ./array_push
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global ptr null, align 8
  @schmu_b = global ptr null, align 8
  @schmu_nested = global ptr null, align 8
  @schmu_a__2 = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define linkonce_odr void @__array_push_2al2_al__(ptr noalias %arr, ptr %value) !dbg !2 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5, !dbg !5
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !6
  
  then2:                                            ; preds = %then
    %3 = tail call ptr @realloc(ptr %0, i64 48)
    store ptr %3, ptr %arr, align 8
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 4, ptr %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %1
    %4 = mul i64 %mul, 8
    %5 = add i64 %4, 16
    %6 = tail call ptr @realloc(ptr %0, i64 %5)
    store ptr %6, ptr %arr, align 8
    %newcap3 = getelementptr i64, ptr %6, i64 1
    store i64 %mul, ptr %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %7 = phi ptr [ %6, %else ], [ %3, %then2 ], [ %0, %entry ]
    %8 = getelementptr i8, ptr %7, i64 16
    %9 = getelementptr inbounds ptr, ptr %8, i64 %2
    store ptr %value, ptr %9, align 8
    %10 = load ptr, ptr %arr, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %10, align 8
    ret void
  }
  
  define linkonce_odr void @__array_push_al_l_(ptr noalias %arr, i64 %value) !dbg !7 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5, !dbg !8
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !9
  
  then2:                                            ; preds = %then
    %3 = tail call ptr @realloc(ptr %0, i64 48)
    store ptr %3, ptr %arr, align 8
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 4, ptr %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %1
    %4 = mul i64 %mul, 8
    %5 = add i64 %4, 16
    %6 = tail call ptr @realloc(ptr %0, i64 %5)
    store ptr %6, ptr %arr, align 8
    %newcap3 = getelementptr i64, ptr %6, i64 1
    store i64 %mul, ptr %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %7 = phi ptr [ %6, %else ], [ %3, %then2 ], [ %0, %entry ]
    %8 = getelementptr i8, ptr %7, i64 16
    %9 = getelementptr inbounds i64, ptr %8, i64 %2
    store i64 %value, ptr %9, align 8
    %10 = load ptr, ptr %arr, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %10, align 8
    ret void
  }
  
  define void @schmu_in_fun() !dbg !10 {
  entry:
    %0 = alloca ptr, align 8
    %1 = tail call ptr @malloc(i64 32)
    store ptr %1, ptr %0, align 8
    store i64 2, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    %"1" = getelementptr i64, ptr %2, i64 1
    store i64 20, ptr %"1", align 8
    %3 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_al_(ptr %3)
    call void @__array_push_al_l_(ptr %0, i64 30), !dbg !11
    %4 = load ptr, ptr %0, align 8
    %5 = load i64, ptr %4, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %5)
    %6 = load ptr, ptr %3, align 8
    %7 = load i64, ptr %6, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %7)
    call void @__free_al_(ptr %3)
    call void @__free_al_(ptr %0)
    ret void
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !12 {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    store ptr %0, ptr @schmu_a, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 20, ptr %"1", align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_al_(ptr @schmu_b)
    tail call void @__array_push_al_l_(ptr @schmu_a, i64 30), !dbg !13
    %2 = load ptr, ptr @schmu_a, align 8
    %3 = load i64, ptr %2, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %3)
    %4 = load ptr, ptr @schmu_b, align 8
    %5 = load i64, ptr %4, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %5)
    tail call void @schmu_in_fun(), !dbg !14
    %6 = tail call ptr @malloc(i64 32)
    store ptr %6, ptr @schmu_nested, align 8
    store i64 2, ptr %6, align 8
    %cap3 = getelementptr i64, ptr %6, i64 1
    store i64 2, ptr %cap3, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    %8 = tail call ptr @malloc(i64 32)
    store ptr %8, ptr %7, align 8
    store i64 2, ptr %8, align 8
    %cap6 = getelementptr i64, ptr %8, i64 1
    store i64 2, ptr %cap6, align 8
    %9 = getelementptr i8, ptr %8, i64 16
    store i64 0, ptr %9, align 8
    %"18" = getelementptr i64, ptr %9, i64 1
    store i64 1, ptr %"18", align 8
    %"19" = getelementptr ptr, ptr %7, i64 1
    %10 = tail call ptr @malloc(i64 32)
    store ptr %10, ptr %"19", align 8
    store i64 2, ptr %10, align 8
    %cap11 = getelementptr i64, ptr %10, i64 1
    store i64 2, ptr %cap11, align 8
    %11 = getelementptr i8, ptr %10, i64 16
    store i64 2, ptr %11, align 8
    %"113" = getelementptr i64, ptr %11, i64 1
    store i64 3, ptr %"113", align 8
    %12 = tail call ptr @malloc(i64 32)
    store ptr %12, ptr @schmu_a__2, align 8
    store i64 2, ptr %12, align 8
    %cap15 = getelementptr i64, ptr %12, i64 1
    store i64 2, ptr %cap15, align 8
    %13 = getelementptr i8, ptr %12, i64 16
    store i64 4, ptr %13, align 8
    %"117" = getelementptr i64, ptr %13, i64 1
    store i64 5, ptr %"117", align 8
    %14 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %14, ptr align 8 @schmu_a__2, i64 8, i1 false)
    call void @__copy_al_(ptr %14)
    %15 = load ptr, ptr %14, align 8
    call void @__array_push_2al2_al__(ptr @schmu_nested, ptr %15), !dbg !15
    %16 = load ptr, ptr @schmu_nested, align 8
    %17 = getelementptr i8, ptr %16, i64 16
    %18 = getelementptr ptr, ptr %17, i64 1
    %19 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %19, ptr align 8 @schmu_a__2, i64 8, i1 false)
    call void @__copy_al_(ptr %19)
    call void @__free_al_(ptr %18)
    %20 = load ptr, ptr %19, align 8
    store ptr %20, ptr %18, align 8
    %21 = load ptr, ptr @schmu_nested, align 8
    %22 = getelementptr i8, ptr %21, i64 16
    %23 = getelementptr ptr, ptr %22, i64 1
    %24 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %24, ptr align 8 @schmu_a__2, i64 8, i1 false)
    call void @__copy_al_(ptr %24)
    call void @__free_al_(ptr %23)
    %25 = load ptr, ptr %24, align 8
    store ptr %25, ptr %23, align 8
    %26 = call ptr @malloc(i64 32)
    %arr = alloca ptr, align 8
    store ptr %26, ptr %arr, align 8
    store i64 2, ptr %26, align 8
    %cap19 = getelementptr i64, ptr %26, i64 1
    store i64 2, ptr %cap19, align 8
    %27 = getelementptr i8, ptr %26, i64 16
    store i64 4, ptr %27, align 8
    %"121" = getelementptr i64, ptr %27, i64 1
    store i64 5, ptr %"121", align 8
    call void @__array_push_2al2_al__(ptr @schmu_nested, ptr %26), !dbg !16
    %28 = load ptr, ptr @schmu_nested, align 8
    %29 = getelementptr i8, ptr %28, i64 16
    %30 = getelementptr ptr, ptr %29, i64 1
    %31 = call ptr @malloc(i64 32)
    %arr22 = alloca ptr, align 8
    store ptr %31, ptr %arr22, align 8
    store i64 2, ptr %31, align 8
    %cap24 = getelementptr i64, ptr %31, i64 1
    store i64 2, ptr %cap24, align 8
    %32 = getelementptr i8, ptr %31, i64 16
    store i64 4, ptr %32, align 8
    %"126" = getelementptr i64, ptr %32, i64 1
    store i64 5, ptr %"126", align 8
    call void @__free_al_(ptr %30)
    store ptr %31, ptr %30, align 8
    %33 = load ptr, ptr @schmu_nested, align 8
    %34 = getelementptr i8, ptr %33, i64 16
    %35 = getelementptr ptr, ptr %34, i64 1
    %36 = call ptr @malloc(i64 32)
    %arr27 = alloca ptr, align 8
    store ptr %36, ptr %arr27, align 8
    store i64 2, ptr %36, align 8
    %cap29 = getelementptr i64, ptr %36, i64 1
    store i64 2, ptr %cap29, align 8
    %37 = getelementptr i8, ptr %36, i64 16
    store i64 4, ptr %37, align 8
    %"131" = getelementptr i64, ptr %37, i64 1
    store i64 5, ptr %"131", align 8
    call void @__free_al_(ptr %35)
    store ptr %36, ptr %35, align 8
    call void @__free_al_(ptr @schmu_a__2)
    call void @__free_2al2_(ptr @schmu_nested)
    call void @__free_al_(ptr @schmu_b)
    call void @__free_al_(ptr @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__free_2al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, ptr %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = getelementptr i8, ptr %1, i64 16
    %5 = getelementptr ptr, ptr %4, i64 %2
    call void @__free_al_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "array_push.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_2al2_al__", scope: !1, file: !1, line: 15, type: !3, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 19, column: 5, scope: !2)
  !6 = !DILocation(line: 20, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_al_l_", scope: !1, file: !1, line: 15, type: !3, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = !DILocation(line: 19, column: 5, scope: !7)
  !9 = !DILocation(line: 20, column: 7, scope: !7)
  !10 = distinct !DISubprogram(name: "in_fun", linkageName: "schmu_in_fun", scope: !1, file: !1, line: 9, type: !3, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !11 = !DILocation(line: 13, column: 2, scope: !10)
  !12 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !13 = !DILocation(line: 4, scope: !12)
  !14 = !DILocation(line: 19, scope: !12)
  !15 = !DILocation(line: 23, scope: !12)
  !16 = !DILocation(line: 26, scope: !12)
  3
  2
  3
  2

Decrease ref counts for local variables in if branches
  $ schmu --dump-llvm decr_rc_if.smu && valgrind -q --leak-check=yes --show-reachable=yes ./decr_rc_if
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i1 @schmu_ret_true() !dbg !2 {
  entry:
    ret i1 true
  }
  
  define i64 @main(i64 %arg) !dbg !5 {
  entry:
    %0 = tail call i1 @schmu_ret_true(), !dbg !6
    br i1 %0, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %entry
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    %3 = tail call ptr @malloc(i64 24)
    %arr1 = alloca ptr, align 8
    store ptr %3, ptr %arr1, align 8
    store i64 1, ptr %3, align 8
    %cap3 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap3, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 10, ptr %4, align 8
    call void @__free_al_(ptr %arr)
    br label %ifcont
  
  else:                                             ; preds = %entry
    %5 = tail call ptr @malloc(i64 24)
    %arr5 = alloca ptr, align 8
    store ptr %5, ptr %arr5, align 8
    store i64 1, ptr %5, align 8
    %cap7 = getelementptr i64, ptr %5, i64 1
    store i64 1, ptr %cap7, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store i64 0, ptr %6, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %arr1, %then ], [ %arr5, %else ]
    call void @__free_al_(ptr %iftmp)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "decr_rc_if.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "ret_true", linkageName: "schmu_ret_true", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !6 = !DILocation(line: 3, column: 4, scope: !5)

Drop last element
  $ schmu --dump-llvm array_drop_back.smu && valgrind -q --leak-check=yes --show-reachable=yes ./array_drop_back
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tal__ = type { i32, ptr }
  
  @schmu_nested = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"some\00" }
  @2 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  
  declare void @string_println(ptr %0)
  
  define linkonce_odr { i32, i64 } @__array_pop_back_2al2_rval2__(ptr noalias %arr) !dbg !2 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, 0
    br i1 %eq, label %then, label %else, !dbg !5
  
  then:                                             ; preds = %entry
    %t = alloca %option.tal__, align 8
    store %option.tal__ { i32 0, ptr undef }, ptr %t, align 8
    br label %ifcont
  
  else:                                             ; preds = %entry
    %t1 = alloca %option.tal__, align 8
    store i32 1, ptr %t1, align 4
    %data = getelementptr inbounds %option.tal__, ptr %t1, i32 0, i32 1
    %2 = sub i64 %1, 1
    store i64 %2, ptr %0, align 8
    %3 = getelementptr i8, ptr %0, i64 16
    %4 = getelementptr ptr, ptr %3, i64 %2
    %5 = load ptr, ptr %4, align 8
    store ptr %5, ptr %data, align 8
    store ptr %5, ptr %data, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %t, %then ], [ %t1, %else ]
    %unbox = load { i32, i64 }, ptr %iftmp, align 8
    ret { i32, i64 } %unbox
  }
  
  define i64 @main(i64 %arg) !dbg !6 {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    store ptr %0, ptr @schmu_nested, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = tail call ptr @malloc(i64 32)
    store ptr %2, ptr %1, align 8
    store i64 2, ptr %2, align 8
    %cap2 = getelementptr i64, ptr %2, i64 1
    store i64 2, ptr %cap2, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i64 0, ptr %3, align 8
    %"1" = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %"1", align 8
    %"14" = getelementptr ptr, ptr %1, i64 1
    %4 = tail call ptr @malloc(i64 32)
    store ptr %4, ptr %"14", align 8
    store i64 2, ptr %4, align 8
    %cap6 = getelementptr i64, ptr %4, i64 1
    store i64 2, ptr %cap6, align 8
    %5 = getelementptr i8, ptr %4, i64 16
    store i64 2, ptr %5, align 8
    %"18" = getelementptr i64, ptr %5, i64 1
    store i64 3, ptr %"18", align 8
    %6 = load ptr, ptr @schmu_nested, align 8
    %7 = load i64, ptr %6, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %7)
    %ret = alloca %option.tal__, align 8
    %8 = tail call { i32, i64 } @__array_pop_back_2al2_rval2__(ptr @schmu_nested), !dbg !7
    store { i32, i64 } %8, ptr %ret, align 8
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont, !dbg !8
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tal__, ptr %ret, i32 0, i32 1
    tail call void @string_println(ptr @1), !dbg !9
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %9 = load ptr, ptr @schmu_nested, align 8
    %10 = load i64, ptr %9, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %10)
    %ret10 = alloca %option.tal__, align 8
    %11 = tail call { i32, i64 } @__array_pop_back_2al2_rval2__(ptr @schmu_nested), !dbg !10
    store { i32, i64 } %11, ptr %ret10, align 8
    %12 = load ptr, ptr @schmu_nested, align 8
    %13 = load i64, ptr %12, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %13)
    %ret12 = alloca %option.tal__, align 8
    %14 = tail call { i32, i64 } @__array_pop_back_2al2_rval2__(ptr @schmu_nested), !dbg !11
    store { i32, i64 } %14, ptr %ret12, align 8
    %index14 = load i32, ptr %ret12, align 4
    %eq15 = icmp eq i32 %index14, 1
    br i1 %eq15, label %then16, label %else18, !dbg !12
  
  then16:                                           ; preds = %ifcont
    %data17 = getelementptr inbounds %option.tal__, ptr %ret12, i32 0, i32 1
    br label %ifcont19
  
  else18:                                           ; preds = %ifcont
    tail call void @string_println(ptr @2), !dbg !13
    br label %ifcont19
  
  ifcont19:                                         ; preds = %else18, %then16
    %15 = load ptr, ptr @schmu_nested, align 8
    %16 = load i64, ptr %15, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %16)
    call void @__free_val2_(ptr %ret12)
    call void @__free_val2_(ptr %ret10)
    call void @__free_val2_(ptr %ret)
    call void @__free_2al2_(ptr @schmu_nested)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_val2_(ptr %0) {
  entry:
    %tag1 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag1, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.tal__, ptr %0, i32 0, i32 1
    call void @__free_al_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_2al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, ptr %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = getelementptr i8, ptr %1, i64 16
    %5 = getelementptr ptr, ptr %4, i64 %2
    call void @__free_al_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "array_drop_back.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_pop_back", linkageName: "__array_pop_back_2al2_rval2__", scope: !1, file: !1, line: 98, type: !3, scopeLine: 98, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 100, column: 5, scope: !2)
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !7 = !DILocation(line: 3, column: 6, scope: !6)
  !8 = !DILocation(line: 3, column: 32, scope: !6)
  !9 = !DILocation(line: 3, column: 41, scope: !6)
  !10 = !DILocation(line: 5, scope: !6)
  !11 = !DILocation(line: 7, column: 6, scope: !6)
  !12 = !DILocation(line: 7, column: 31, scope: !6)
  !13 = !DILocation(line: 7, column: 51, scope: !6)
  2
  some
  1
  0
  none
  0

Global lets with expressions
  $ schmu --dump-llvm global_let.smu && valgrind -q --leak-check=yes --show-reachable=yes ./global_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tal__ = type { i32, ptr }
  %ral__ = type { ptr }
  
  @schmu_a = internal constant %option.tal__ { i32 0, ptr undef }
  @schmu_b = global ptr null, align 8
  @schmu_c = global i64 0, align 8
  
  define { i32, i64 } @schmu_ret_none() !dbg !2 {
  entry:
    %unbox = load { i32, i64 }, ptr @schmu_a, align 8
    ret { i32, i64 } %unbox
  }
  
  define i64 @schmu_ret_rec() !dbg !5 {
  entry:
    %0 = alloca %ral__, align 8
    %1 = tail call ptr @malloc(i64 40)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 3, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 3, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    %"1" = getelementptr i64, ptr %2, i64 1
    store i64 20, ptr %"1", align 8
    %"2" = getelementptr i64, ptr %2, i64 2
    store i64 30, ptr %"2", align 8
    store ptr %1, ptr %0, align 8
    %3 = ptrtoint ptr %1 to i64
    ret i64 %3
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %arg) !dbg !6 {
  entry:
    %ret = alloca %option.tal__, align 8
    %0 = tail call { i32, i64 } @schmu_ret_none(), !dbg !7
    store { i32, i64 } %0, ptr %ret, align 8
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !8
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tal__, ptr %ret, i32 0, i32 1
    br label %ifcont
  
  else:                                             ; preds = %entry
    %1 = tail call ptr @malloc(i64 32)
    store ptr %1, ptr @schmu_b, align 8
    store i64 2, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 1, ptr %2, align 8
    %"1" = getelementptr i64, ptr %2, i64 1
    store i64 2, ptr %"1", align 8
    call void @__free_val2_(ptr %ret)
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %data, %then ], [ @schmu_b, %else ]
    %3 = load ptr, ptr %iftmp, align 8
    store ptr %3, ptr @schmu_b, align 8
    %ret1 = alloca %ral__, align 8
    %4 = call i64 @schmu_ret_rec(), !dbg !9
    store i64 %4, ptr %ret1, align 8
    %5 = inttoptr i64 %4 to ptr
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = getelementptr i64, ptr %6, i64 1
    %8 = load i64, ptr %7, align 8
    store i64 %8, ptr @schmu_c, align 8
    call void @__free_al2_(ptr %ret1)
    call void @__free_al_(ptr @schmu_b)
    ret i64 0
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_val2_(ptr %0) {
  entry:
    %tag1 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag1, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.tal__, ptr %0, i32 0, i32 1
    call void @__free_al_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_al2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_al_(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "global_let.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "ret_none", linkageName: "schmu_ret_none", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = distinct !DISubprogram(name: "ret_rec", linkageName: "schmu_ret_rec", scope: !1, file: !1, line: 9, type: !3, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !7 = !DILocation(line: 5, column: 15, scope: !6)
  !8 = !DILocation(line: 5, column: 27, scope: !6)
  !9 = !DILocation(line: 11, column: 10, scope: !6)

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
  
  %closure = type { ptr, ptr }
  
  @schmu_f = global %closure zeroinitializer, align 8
  @schmu_f__2 = global %closure zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @__fun_schmu0(i64 %a) !dbg !2 {
  entry:
    %add = add i64 %a, 12
    ret i64 %add
  }
  
  define i64 @schmu_named(i64 %a) !dbg !5 {
  entry:
    %add = add i64 %a, 13
    ret i64 %add
  }
  
  define void @schmu_ret_fn(ptr noalias %0) !dbg !6 {
  entry:
    store ptr @__fun_schmu0, ptr %0, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_ret_named(ptr noalias %0) !dbg !7 {
  entry:
    store ptr @schmu_named, ptr %0, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !8 {
  entry:
    tail call void @schmu_ret_fn(ptr @schmu_f), !dbg !9
    %loadtmp = load ptr, ptr @schmu_f, align 8
    %loadtmp1 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %loadtmp(i64 12, ptr %loadtmp1), !dbg !10
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    tail call void @schmu_ret_named(ptr @schmu_f__2), !dbg !11
    %loadtmp2 = load ptr, ptr @schmu_f__2, align 8
    %loadtmp3 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f__2, i32 0, i32 1), align 8
    %1 = tail call i64 %loadtmp2(i64 12, ptr %loadtmp3), !dbg !12
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    tail call void @__free_lrl_(ptr @schmu_f__2)
    tail call void @__free_lrl_(ptr @schmu_f)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr void @__free_lrl_(ptr %0) {
  entry:
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %env = load ptr, ptr %envptr, align 8
    %1 = icmp eq ptr %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = getelementptr inbounds { ptr, ptr }, ptr %env, i32 0, i32 1
    %dtor1 = load ptr, ptr %2, align 8
    %3 = icmp eq ptr %dtor1, null
    br i1 %3, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    call void %dtor1(ptr %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(ptr %env)
    br label %ret
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "return_fn.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !1, file: !1, line: 2, type: !3, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = distinct !DISubprogram(name: "named", linkageName: "schmu_named", scope: !1, file: !1, line: 6, type: !3, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !6 = distinct !DISubprogram(name: "ret_fn", linkageName: "schmu_ret_fn", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !7 = distinct !DISubprogram(name: "ret_named", linkageName: "schmu_ret_named", scope: !1, file: !1, line: 5, type: !3, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !9 = !DILocation(line: 10, column: 8, scope: !8)
  !10 = !DILocation(line: 11, column: 12, scope: !8)
  !11 = !DILocation(line: 13, column: 8, scope: !8)
  !12 = !DILocation(line: 14, column: 12, scope: !8)
  24
  25

Return closures
  $ schmu --dump-llvm return_closure.smu && valgrind -q --leak-check=yes --show-reachable=yes ./return_closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @schmu_f = global %closure zeroinitializer, align 8
  @schmu_f2 = global %closure zeroinitializer, align 8
  @schmu_f__2 = global %closure zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @__fun_schmu0(i64 %a, ptr %0) !dbg !2 {
  entry:
    %b = getelementptr inbounds { ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %b1 = load i64, ptr %b, align 8
    %add = add i64 %a, %b1
    ret i64 %add
  }
  
  define i64 @schmu_bla(i64 %a, ptr %0) !dbg !5 {
  entry:
    %b = getelementptr inbounds { ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %b1 = load i64, ptr %b, align 8
    %add = add i64 %a, %b1
    ret i64 %add
  }
  
  define void @schmu_ret_fn(ptr noalias %0, i64 %b) !dbg !6 {
  entry:
    store ptr @schmu_bla, ptr %0, align 8
    %1 = tail call ptr @malloc(i64 24)
    %b1 = getelementptr inbounds { ptr, ptr, i64 }, ptr %1, i32 0, i32 2
    store i64 %b, ptr %b1, align 8
    store ptr @__ctor_l_, ptr %1, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %1, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %1, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_ret_lambda(ptr noalias %0, i64 %b) !dbg !7 {
  entry:
    store ptr @__fun_schmu0, ptr %0, align 8
    %1 = tail call ptr @malloc(i64 24)
    %b1 = getelementptr inbounds { ptr, ptr, i64 }, ptr %1, i32 0, i32 2
    store i64 %b, ptr %b1, align 8
    store ptr @__ctor_l_, ptr %1, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %1, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %1, ptr %envptr, align 8
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr ptr @__ctor_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    ret ptr %1
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) !dbg !8 {
  entry:
    tail call void @schmu_ret_fn(ptr @schmu_f, i64 13), !dbg !9
    tail call void @schmu_ret_fn(ptr @schmu_f2, i64 35), !dbg !10
    %loadtmp = load ptr, ptr @schmu_f, align 8
    %loadtmp1 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %loadtmp(i64 12, ptr %loadtmp1), !dbg !11
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %loadtmp2 = load ptr, ptr @schmu_f2, align 8
    %loadtmp3 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f2, i32 0, i32 1), align 8
    %1 = tail call i64 %loadtmp2(i64 12, ptr %loadtmp3), !dbg !12
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    tail call void @schmu_ret_lambda(ptr @schmu_f__2, i64 134), !dbg !13
    %loadtmp4 = load ptr, ptr @schmu_f__2, align 8
    %loadtmp5 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f__2, i32 0, i32 1), align 8
    %2 = tail call i64 %loadtmp4(i64 12, ptr %loadtmp5), !dbg !14
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %2)
    tail call void @__free_lrl_(ptr @schmu_f__2)
    tail call void @__free_lrl_(ptr @schmu_f2)
    tail call void @__free_lrl_(ptr @schmu_f)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr void @__free_lrl_(ptr %0) {
  entry:
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %env = load ptr, ptr %envptr, align 8
    %1 = icmp eq ptr %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = getelementptr inbounds { ptr, ptr }, ptr %env, i32 0, i32 1
    %dtor1 = load ptr, ptr %2, align 8
    %3 = icmp eq ptr %dtor1, null
    br i1 %3, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    call void %dtor1(ptr %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(ptr %env)
    br label %ret
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "return_closure.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !1, file: !1, line: 7, type: !3, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = distinct !DISubprogram(name: "bla", linkageName: "schmu_bla", scope: !1, file: !1, line: 2, type: !3, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !6 = distinct !DISubprogram(name: "ret_fn", linkageName: "schmu_ret_fn", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !7 = distinct !DISubprogram(name: "ret_lambda", linkageName: "schmu_ret_lambda", scope: !1, file: !1, line: 6, type: !3, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !9 = !DILocation(line: 10, column: 8, scope: !8)
  !10 = !DILocation(line: 11, column: 9, scope: !8)
  !11 = !DILocation(line: 12, column: 12, scope: !8)
  !12 = !DILocation(line: 13, column: 12, scope: !8)
  !13 = !DILocation(line: 15, column: 8, scope: !8)
  !14 = !DILocation(line: 16, column: 12, scope: !8)
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
  
  %view_ = type { ptr, i64, i64 }
  %parse_resultac_2l__ = type { i32, %successac_2l__ }
  %successac_2l__ = type { %view_, %view_ }
  %parse_resultl_ = type { i32, %successl_ }
  %successl_ = type { %view_, i64 }
  
  @schmu_s = global ptr null, align 8
  @schmu_inp = global %view_ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c" \00" }
  
  declare i64 @string_len(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare i1 @prelude_char_equal(i8 %0, i8 %1)
  
  define void @schmu_aux(ptr noalias %0, ptr %rem, i64 %cnt) !dbg !2 {
  entry:
    %1 = alloca %view_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %rem, i64 24, i1 false)
    %2 = alloca i1, align 1
    store i1 false, ptr %2, align 1
    %3 = alloca i64, align 8
    store i64 %cnt, ptr %3, align 8
    %ret = alloca %parse_resultac_2l__, align 8
    br label %rec
  
  rec:                                              ; preds = %cont, %entry
    %4 = phi i1 [ true, %cont ], [ false, %entry ]
    %5 = phi i64 [ %add, %cont ], [ %cnt, %entry ]
    call void @schmu_ch(ptr %ret, ptr %1), !dbg !5
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %rec
    %data = getelementptr inbounds %parse_resultac_2l__, ptr %ret, i32 0, i32 1
    %add = add i64 %5, 1
    call void @__free_except0_ac_2l_ac_2l2_(ptr %data)
    br i1 %4, label %call_decr, label %cookie
  
  call_decr:                                        ; preds = %then
    call void @__free_ac_2l_(ptr %1)
    br label %cont
  
  cookie:                                           ; preds = %then
    store i1 true, ptr %2, align 1
    br label %cont
  
  cont:                                             ; preds = %cookie, %call_decr
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %data, i64 24, i1 false)
    store i64 %add, ptr %3, align 8
    br label %rec
  
  else:                                             ; preds = %rec
    %data1 = getelementptr inbounds %parse_resultac_2l__, ptr %ret, i32 0, i32 1
    store i32 0, ptr %0, align 4
    %data3 = getelementptr inbounds %parse_resultl_, ptr %0, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data3, ptr align 8 %1, i64 24, i1 false)
    call void @__copy_ac_2l_(ptr %data3)
    %mtch = getelementptr inbounds %successl_, ptr %data3, i32 0, i32 1
    store i64 %5, ptr %mtch, align 8
    call void @__free_vac_2l_ac_2l2_ac_2l2_(ptr %ret)
    br i1 %4, label %call_decr5, label %cookie6
  
  call_decr5:                                       ; preds = %else
    call void @__free_ac_2l_(ptr %1)
    br label %cont7
  
  cookie6:                                          ; preds = %else
    store i1 true, ptr %2, align 1
    br label %cont7
  
  cont7:                                            ; preds = %cookie6, %call_decr5
    ret void
  }
  
  define void @schmu_ch(ptr noalias %0, ptr %buf) !dbg !7 {
  entry:
    %1 = load ptr, ptr %buf, align 8
    %2 = getelementptr inbounds %view_, ptr %buf, i32 0, i32 1
    %3 = load i64, ptr %2, align 8
    %4 = tail call i8 @string_get(ptr %1, i64 %3), !dbg !8
    %5 = tail call i1 @prelude_char_equal(i8 %4, i8 32), !dbg !9
    br i1 %5, label %then, label %else, !dbg !9
  
  then:                                             ; preds = %entry
    store i32 0, ptr %0, align 4
    %data = getelementptr inbounds %parse_resultac_2l__, ptr %0, i32 0, i32 1
    %6 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %6, ptr align 1 %buf, i64 8, i1 false)
    call void @__copy_ac_(ptr %6)
    %7 = load ptr, ptr %6, align 8
    store ptr %7, ptr %data, align 8
    %start = getelementptr inbounds %view_, ptr %data, i32 0, i32 1
    %sunkaddr = getelementptr inbounds i8, ptr %buf, i64 8
    %8 = load i64, ptr %sunkaddr, align 8
    %add = add i64 %8, 1
    store i64 %add, ptr %start, align 8
    %len = getelementptr inbounds %view_, ptr %data, i32 0, i32 2
    %9 = getelementptr inbounds %view_, ptr %buf, i32 0, i32 2
    %10 = load i64, ptr %9, align 8
    %sub = sub i64 %10, 1
    store i64 %sub, ptr %len, align 8
    %mtch = getelementptr inbounds %successac_2l__, ptr %data, i32 0, i32 1
    %11 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %11, ptr align 1 %buf, i64 8, i1 false)
    call void @__copy_ac_(ptr %11)
    %12 = load ptr, ptr %11, align 8
    store ptr %12, ptr %mtch, align 8
    %start3 = getelementptr inbounds %view_, ptr %mtch, i32 0, i32 1
    %13 = load i64, ptr %sunkaddr, align 8
    store i64 %13, ptr %start3, align 8
    %len4 = getelementptr inbounds %view_, ptr %mtch, i32 0, i32 2
    store i64 1, ptr %len4, align 8
    ret void
  
  else:                                             ; preds = %entry
    store i32 1, ptr %0, align 4
    %data6 = getelementptr inbounds %parse_resultac_2l__, ptr %0, i32 0, i32 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data6, ptr align 1 %buf, i64 24, i1 false)
    tail call void @__copy_ac_2l_(ptr %data6)
    ret void
  }
  
  define void @schmu_many_count(ptr noalias %0, ptr %buf) !dbg !10 {
  entry:
    tail call void @schmu_aux(ptr %0, ptr %buf, i64 0), !dbg !11
    ret void
  }
  
  define void @schmu_view_of_string(ptr noalias %0, ptr %str) !dbg !12 {
  entry:
    %1 = alloca ptr, align 8
    store ptr %str, ptr %1, align 8
    %2 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %1, i64 8, i1 false)
    call void @__copy_ac_(ptr %2)
    %3 = load ptr, ptr %2, align 8
    store ptr %3, ptr %0, align 8
    %start = getelementptr inbounds %view_, ptr %0, i32 0, i32 1
    store i64 0, ptr %start, align 8
    %len = getelementptr inbounds %view_, ptr %0, i32 0, i32 2
    %4 = call i64 @string_len(ptr %str), !dbg !13
    store i64 %4, ptr %len, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_ac_2l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_ac_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_except0_ac_2l_ac_2l2_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %successac_2l__, ptr %0, i32 0, i32 1
    call void @__free_ac_2l_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_ac_2l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__copy_ac_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac_2l_ac_2l2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_ac_2l_(ptr %1)
    %2 = getelementptr inbounds %successac_2l__, ptr %0, i32 0, i32 1
    call void @__free_ac_2l_(ptr %2)
    ret void
  }
  
  define linkonce_odr void @__free_vac_2l_ac_2l2_ac_2l2_(ptr %0) {
  entry:
    %tag4 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag4, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse_resultac_2l__, ptr %0, i32 0, i32 1
    call void @__free_ac_2l_ac_2l2_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    %2 = icmp eq i32 %index, 1
    br i1 %2, label %match1, label %cont2
  
  match1:                                           ; preds = %cont
    %data3 = getelementptr inbounds %parse_resultac_2l__, ptr %0, i32 0, i32 1
    call void @__free_ac_2l_(ptr %data3)
    br label %cont2
  
  cont2:                                            ; preds = %match1, %cont
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !14 {
  entry:
    %fmtsize = tail call i32 (ptr, i64, ptr, ...) @snprintf(ptr null, i64 0, ptr getelementptr (i8, ptr @0, i64 16))
    %0 = add i32 %fmtsize, 17
    %1 = sext i32 %0 to i64
    %2 = tail call ptr @malloc(i64 %1)
    %3 = sext i32 %fmtsize to i64
    store i64 %3, ptr %2, align 8
    %cap = getelementptr i64, ptr %2, i64 1
    store i64 %3, ptr %cap, align 8
    %data = getelementptr i64, ptr %2, i64 2
    %fmt = tail call i32 (ptr, i64, ptr, ...) @snprintf(ptr %data, i64 %1, ptr getelementptr (i8, ptr @0, i64 16))
    store ptr %2, ptr @schmu_s, align 8
    tail call void @schmu_view_of_string(ptr @schmu_inp, ptr %2), !dbg !15
    %ret = alloca %parse_resultl_, align 8
    call void @schmu_many_count(ptr %ret, ptr @schmu_inp), !dbg !16
    call void @__free_vac_2l_l_ac_2l2_(ptr %ret)
    call void @__free_ac_2l_(ptr @schmu_inp)
    call void @__free_ac_(ptr @schmu_s)
    ret i64 0
  }
  
  declare i32 @snprintf(ptr %0, i64 %1, ptr %2, ...)
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_ac_2l_l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_ac_2l_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_vac_2l_l_ac_2l2_(ptr %0) {
  entry:
    %tag4 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag4, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse_resultl_, ptr %0, i32 0, i32 1
    call void @__free_ac_2l_l_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    %2 = icmp eq i32 %index, 1
    br i1 %2, label %match1, label %cont2
  
  match1:                                           ; preds = %cont
    %data3 = getelementptr inbounds %parse_resultl_, ptr %0, i32 0, i32 1
    call void @__free_ac_2l_(ptr %data3)
    br label %cont2
  
  cont2:                                            ; preds = %match1, %cont
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "take_partial_alloc.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "aux", linkageName: "schmu_aux", scope: !1, file: !1, line: 19, type: !3, scopeLine: 19, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 20, column: 10, scope: !2)
  !6 = !DILocation(line: 21, column: 6, scope: !2)
  !7 = distinct !DISubprogram(name: "ch", linkageName: "schmu_ch", scope: !1, file: !1, line: 9, type: !3, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = !DILocation(line: 10, column: 16, scope: !7)
  !9 = !DILocation(line: 10, column: 5, scope: !7)
  !10 = distinct !DISubprogram(name: "many_count", linkageName: "schmu_many_count", scope: !1, file: !1, line: 18, type: !3, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !11 = !DILocation(line: 27, column: 2, scope: !10)
  !12 = distinct !DISubprogram(name: "view_of_string", linkageName: "schmu_view_of_string", scope: !1, file: !1, line: 5, type: !3, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !13 = !DILocation(line: 6, column: 37, scope: !12)
  !14 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !15 = !DILocation(line: 31, column: 10, scope: !14)
  !16 = !DILocation(line: 32, column: 7, scope: !14)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./take_partial_alloc

Take/use not all allocations of a record in tailrec calls, different order for pattern matches
  $ schmu take_partial_alloc_reorder.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./take_partial_alloc_reorder

Increase refcount for returned params in ifs
  $ schmu --dump-llvm if_ret_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./if_ret_param
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"/\00" }
  @schmu_s = constant ptr @0
  @1 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"/%s\00" }
  
  define void @schmu_inner(i64 %i, ptr %0) !dbg !2 {
  entry:
    %limit = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %0, i32 0, i32 3
    %limit1 = load i64, ptr %limit, align 8
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = add i64 %i, 1
    %3 = sub i64 0, %limit1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %4 = add i64 %3, %lsr.iv
    %eq = icmp eq i64 %4, 1
    br i1 %eq, label %then, label %else, !dbg !5
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr3 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp2 = load ptr, ptr %sunkaddr3, align 8
    tail call void %loadtmp(ptr @0, ptr %loadtmp2), !dbg !6
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(ptr %value) !dbg !7 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %value, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    call void @__free_ac_(ptr %1)
    ret void
  }
  
  define void @schmu_times(i64 %limit, ptr %f) !dbg !8 {
  entry:
    %schmu_inner = alloca %closure, align 8
    store ptr @schmu_inner, ptr %schmu_inner, align 8
    %clsr_schmu_inner = alloca { ptr, ptr, %closure, i64 }, align 8
    %f1 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f1, ptr align 1 %f, i64 16, i1 false)
    %limit2 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 3
    store i64 %limit, ptr %limit2, align 8
    store ptr @__ctor_ac_ru_l_, ptr %clsr_schmu_inner, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %schmu_inner, i32 0, i32 1
    store ptr %clsr_schmu_inner, ptr %envptr, align 8
    call void @schmu_inner(i64 0, ptr %clsr_schmu_inner), !dbg !9
    ret void
  }
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i32 @snprintf(ptr %0, i64 %1, ptr %2, ...)
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_ac_ru_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %1, i32 0, i32 2
    call void @__copy_ac_ru_(ptr %f)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy_ac_ru_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor2 = bitcast ptr %2 to ptr
    %ctor1 = load ptr, ptr %ctor2, align 8
    %4 = call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !10 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @schmu_test, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @schmu_times(i64 2, ptr %clstmp), !dbg !11
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "if_ret_param.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "inner", linkageName: "schmu_inner", scope: !1, file: !1, line: 4, type: !3, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 5, column: 7, scope: !2)
  !6 = !DILocation(line: 7, column: 6, scope: !2)
  !7 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !1, file: !1, line: 14, type: !3, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = distinct !DISubprogram(name: "times", linkageName: "schmu_times", scope: !1, file: !1, line: 3, type: !3, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !9 = !DILocation(line: 11, column: 2, scope: !8)
  !10 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !11 = !DILocation(line: 18, scope: !10)

Monomorphization in closures
  $ schmu --dump-llvm closure_monomorph.smu && ./closure_monomorph
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @schmu_arr = global ptr null, align 8
  @schmu_arr__2 = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  define linkonce_odr void @__array_inner_Cal_lru__(i64 %i, ptr %0) !dbg !2 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %3 = add i64 %lsr.iv, -1
    %4 = load i64, ptr %arr1, align 8
    %eq = icmp eq i64 %3, %4
    br i1 %eq, label %then, label %else, !dbg !5
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %5 = shl i64 %lsr.iv, 3
    %uglygep = getelementptr i8, ptr %arr1, i64 %5
    %uglygep3 = getelementptr i8, ptr %uglygep, i64 8
    %6 = load i64, ptr %uglygep3, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr4 = getelementptr inbounds i8, ptr %0, i64 32
    %loadtmp2 = load ptr, ptr %sunkaddr4, align 8
    tail call void %loadtmp(i64 %6, ptr %loadtmp2), !dbg !6
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr void @__array_iter_al_lru__(ptr %arr, ptr %f) !dbg !7 {
  entry:
    %__array_inner_Cal_lru__ = alloca %closure, align 8
    store ptr @__array_inner_Cal_lru__, ptr %__array_inner_Cal_lru__, align 8
    %clsr___array_inner_Cal_lru__ = alloca { ptr, ptr, ptr, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner_Cal_lru__, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %f2 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner_Cal_lru__, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f2, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_al_lru2_, ptr %clsr___array_inner_Cal_lru__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner_Cal_lru__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__array_inner_Cal_lru__, i32 0, i32 1
    store ptr %clsr___array_inner_Cal_lru__, ptr %envptr, align 8
    call void @__array_inner_Cal_lru__(i64 0, ptr %clsr___array_inner_Cal_lru__), !dbg !8
    ret void
  }
  
  define linkonce_odr void @__array_swap_items_al__(ptr noalias %arr, i64 %i, i64 %j) !dbg !9 {
  entry:
    %eq = icmp eq i64 %i, %j
    %0 = xor i1 %eq, true
    br i1 %0, label %then, label %ifcont, !dbg !10
  
  then:                                             ; preds = %entry
    %1 = alloca i64, align 8
    %2 = load ptr, ptr %arr, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    %4 = getelementptr i64, ptr %3, i64 %i
    %5 = load i64, ptr %4, align 8
    store i64 %5, ptr %1, align 8
    %6 = getelementptr i64, ptr %3, i64 %j
    %7 = load i64, ptr %6, align 8
    store i64 %7, ptr %4, align 8
    store i64 %5, ptr %6, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret void
  }
  
  define linkonce_odr void @__fun_schmu0_Cal_2lrl_ll_(i64 %j, ptr %0) !dbg !11 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %cmp = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 3
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 4
    %i2 = load ptr, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 5
    %pivot3 = load i64, ptr %pivot, align 8
    %1 = load ptr, ptr %arr1, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = getelementptr i64, ptr %2, i64 %j
    %4 = load i64, ptr %3, align 8
    %loadtmp = load ptr, ptr %cmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %cmp, i32 0, i32 1
    %loadtmp4 = load ptr, ptr %envptr, align 8
    %5 = tail call i64 %loadtmp(i64 %4, i64 %pivot3, ptr %loadtmp4), !dbg !12
    %lt = icmp slt i64 %5, 0
    br i1 %lt, label %then, label %ifcont, !dbg !12
  
  then:                                             ; preds = %entry
    %6 = load i64, ptr %i2, align 8
    %add = add i64 %6, 1
    store i64 %add, ptr %i2, align 8
    tail call void @__array_swap_items_al__(ptr %arr1, i64 %add, i64 %j), !dbg !13
    ret void
  
  ifcont:                                           ; preds = %entry
    ret void
  }
  
  define i64 @__fun_schmu1(i64 %a, i64 %b) !dbg !14 {
  entry:
    %sub = sub i64 %a, %b
    ret i64 %sub
  }
  
  define void @__fun_schmu2(i64 %i) !dbg !15 {
  entry:
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %i)
    ret void
  }
  
  define linkonce_odr void @__fun_schmu3_Cal_2lrl_ll_(i64 %j, ptr %0) !dbg !16 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %cmp = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 3
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 4
    %i2 = load ptr, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 5
    %pivot3 = load i64, ptr %pivot, align 8
    %1 = load ptr, ptr %arr1, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = getelementptr i64, ptr %2, i64 %j
    %4 = load i64, ptr %3, align 8
    %loadtmp = load ptr, ptr %cmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %cmp, i32 0, i32 1
    %loadtmp4 = load ptr, ptr %envptr, align 8
    %5 = tail call i64 %loadtmp(i64 %4, i64 %pivot3, ptr %loadtmp4), !dbg !17
    %lt = icmp slt i64 %5, 0
    br i1 %lt, label %then, label %ifcont, !dbg !17
  
  then:                                             ; preds = %entry
    %6 = load i64, ptr %i2, align 8
    %add = add i64 %6, 1
    store i64 %add, ptr %i2, align 8
    tail call void @__array_swap_items_al__(ptr %arr1, i64 %add, i64 %j), !dbg !18
    ret void
  
  ifcont:                                           ; preds = %entry
    ret void
  }
  
  define i64 @__fun_schmu4(i64 %a, i64 %b) !dbg !19 {
  entry:
    %sub = sub i64 %a, %b
    ret i64 %sub
  }
  
  define void @__fun_schmu5(i64 %i) !dbg !20 {
  entry:
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %i)
    ret void
  }
  
  define linkonce_odr i64 @__schmu_partition__2_al_C2lrl__(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !21 {
  entry:
    %cmp = getelementptr inbounds { ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %1 = load ptr, ptr %arr, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = getelementptr i64, ptr %2, i64 %hi
    %4 = alloca i64, align 8
    %5 = load i64, ptr %3, align 8
    store i64 %5, ptr %4, align 8
    %6 = alloca i64, align 8
    %sub = sub i64 %lo, 1
    store i64 %sub, ptr %6, align 8
    %__fun_schmu3_Cal_2lrl_ll_ = alloca %closure, align 8
    store ptr @__fun_schmu3_Cal_2lrl_ll_, ptr %__fun_schmu3_Cal_2lrl_ll_, align 8
    %clsr___fun_schmu3_Cal_2lrl_ll_ = alloca { ptr, ptr, ptr, %closure, ptr, i64 }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu3_Cal_2lrl_ll_, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cmp2 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu3_Cal_2lrl_ll_, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp2, ptr align 1 %cmp, i64 16, i1 false)
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu3_Cal_2lrl_ll_, i32 0, i32 4
    store ptr %6, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu3_Cal_2lrl_ll_, i32 0, i32 5
    store i64 %5, ptr %pivot, align 8
    store ptr @__ctor_al_2lrl_2l_, ptr %clsr___fun_schmu3_Cal_2lrl_ll_, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu3_Cal_2lrl_ll_, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu3_Cal_2lrl_ll_, i32 0, i32 1
    store ptr %clsr___fun_schmu3_Cal_2lrl_ll_, ptr %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, ptr %__fun_schmu3_Cal_2lrl_ll_), !dbg !22
    %7 = load i64, ptr %6, align 8
    %add = add i64 %7, 1
    call void @__array_swap_items_al__(ptr %arr, i64 %add, i64 %hi), !dbg !23
    ret i64 %add
  }
  
  define linkonce_odr i64 @__schmu_partition_al_C2lrl__(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !24 {
  entry:
    %cmp = getelementptr inbounds { ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %1 = load ptr, ptr %arr, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = getelementptr i64, ptr %2, i64 %hi
    %4 = alloca i64, align 8
    %5 = load i64, ptr %3, align 8
    store i64 %5, ptr %4, align 8
    %6 = alloca i64, align 8
    %sub = sub i64 %lo, 1
    store i64 %sub, ptr %6, align 8
    %__fun_schmu0_Cal_2lrl_ll_ = alloca %closure, align 8
    store ptr @__fun_schmu0_Cal_2lrl_ll_, ptr %__fun_schmu0_Cal_2lrl_ll_, align 8
    %clsr___fun_schmu0_Cal_2lrl_ll_ = alloca { ptr, ptr, ptr, %closure, ptr, i64 }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Cal_2lrl_ll_, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cmp2 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Cal_2lrl_ll_, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp2, ptr align 1 %cmp, i64 16, i1 false)
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Cal_2lrl_ll_, i32 0, i32 4
    store ptr %6, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Cal_2lrl_ll_, i32 0, i32 5
    store i64 %5, ptr %pivot, align 8
    store ptr @__ctor_al_2lrl_2l_, ptr %clsr___fun_schmu0_Cal_2lrl_ll_, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Cal_2lrl_ll_, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu0_Cal_2lrl_ll_, i32 0, i32 1
    store ptr %clsr___fun_schmu0_Cal_2lrl_ll_, ptr %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, ptr %__fun_schmu0_Cal_2lrl_ll_), !dbg !25
    %7 = load i64, ptr %6, align 8
    %add = add i64 %7, 1
    call void @__array_swap_items_al__(ptr %arr, i64 %add, i64 %hi), !dbg !26
    ret i64 %add
  }
  
  define linkonce_odr void @__schmu_quicksort__2_al_Cal_2lrlC2lrl2__(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !27 {
  entry:
    %1 = alloca ptr, align 8
    store ptr %arr, ptr %1, align 8
    %2 = alloca i1, align 1
    store i1 false, ptr %2, align 1
    %3 = alloca i64, align 8
    store i64 %lo, ptr %3, align 8
    %4 = alloca i64, align 8
    store i64 %hi, ptr %4, align 8
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
    br i1 %andtmp, label %then, label %else, !dbg !28
  
  then:                                             ; preds = %cont
    store i1 true, ptr %2, align 1
    ret void
  
  else:                                             ; preds = %cont
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr6 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp3 = load ptr, ptr %sunkaddr6, align 8
    %7 = tail call i64 %loadtmp(ptr %arr, i64 %5, i64 %hi, ptr %loadtmp3), !dbg !29
    %sub = sub i64 %7, 1
    tail call void @__schmu_quicksort__2_al_Cal_2lrlC2lrl2__(ptr %arr, i64 %5, i64 %sub, ptr %0), !dbg !30
    %add = add i64 %7, 1
    store ptr %arr, ptr %1, align 8
    store i64 %add, ptr %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_quicksort_al_Cal_2lrlC2lrl2__(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !31 {
  entry:
    %1 = alloca ptr, align 8
    store ptr %arr, ptr %1, align 8
    %2 = alloca i1, align 1
    store i1 false, ptr %2, align 1
    %3 = alloca i64, align 8
    store i64 %lo, ptr %3, align 8
    %4 = alloca i64, align 8
    store i64 %hi, ptr %4, align 8
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
    br i1 %andtmp, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %cont
    store i1 true, ptr %2, align 1
    ret void
  
  else:                                             ; preds = %cont
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr6 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp3 = load ptr, ptr %sunkaddr6, align 8
    %7 = tail call i64 %loadtmp(ptr %arr, i64 %5, i64 %hi, ptr %loadtmp3), !dbg !33
    %sub = sub i64 %7, 1
    tail call void @__schmu_quicksort_al_Cal_2lrlC2lrl2__(ptr %arr, i64 %5, i64 %sub, ptr %0), !dbg !34
    %add = add i64 %7, 1
    store ptr %arr, ptr %1, align 8
    store i64 %add, ptr %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_sort__2_al_2lrl__(ptr noalias %arr, ptr %cmp) !dbg !35 {
  entry:
    %__schmu_partition__2_al_C2lrl__ = alloca %closure, align 8
    store ptr @__schmu_partition__2_al_C2lrl__, ptr %__schmu_partition__2_al_C2lrl__, align 8
    %clsr___schmu_partition__2_al_C2lrl__ = alloca { ptr, ptr, %closure }, align 8
    %cmp1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition__2_al_C2lrl__, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp1, ptr align 1 %cmp, i64 16, i1 false)
    store ptr @__ctor_2lrl2_, ptr %clsr___schmu_partition__2_al_C2lrl__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition__2_al_C2lrl__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__schmu_partition__2_al_C2lrl__, i32 0, i32 1
    store ptr %clsr___schmu_partition__2_al_C2lrl__, ptr %envptr, align 8
    %__schmu_quicksort__2_al_Cal_2lrlC2lrl2__ = alloca %closure, align 8
    store ptr @__schmu_quicksort__2_al_Cal_2lrlC2lrl2__, ptr %__schmu_quicksort__2_al_Cal_2lrlC2lrl2__, align 8
    %clsr___schmu_quicksort__2_al_Cal_2lrlC2lrl2__ = alloca { ptr, ptr, %closure }, align 8
    %__schmu_partition__2_al_C2lrl__3 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort__2_al_Cal_2lrlC2lrl2__, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %__schmu_partition__2_al_C2lrl__3, ptr align 8 %__schmu_partition__2_al_C2lrl__, i64 16, i1 false)
    store ptr @__ctor_al_2lrl2_, ptr %clsr___schmu_quicksort__2_al_Cal_2lrlC2lrl2__, align 8
    %dtor5 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort__2_al_Cal_2lrlC2lrl2__, i32 0, i32 1
    store ptr null, ptr %dtor5, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %__schmu_quicksort__2_al_Cal_2lrlC2lrl2__, i32 0, i32 1
    store ptr %clsr___schmu_quicksort__2_al_Cal_2lrlC2lrl2__, ptr %envptr6, align 8
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %sub = sub i64 %1, 1
    call void @__schmu_quicksort__2_al_Cal_2lrlC2lrl2__(ptr %arr, i64 0, i64 %sub, ptr %clsr___schmu_quicksort__2_al_Cal_2lrlC2lrl2__), !dbg !36
    ret void
  }
  
  define linkonce_odr void @__schmu_sort_al_2lrl__(ptr noalias %arr, ptr %cmp) !dbg !37 {
  entry:
    %__schmu_partition_al_C2lrl__ = alloca %closure, align 8
    store ptr @__schmu_partition_al_C2lrl__, ptr %__schmu_partition_al_C2lrl__, align 8
    %clsr___schmu_partition_al_C2lrl__ = alloca { ptr, ptr, %closure }, align 8
    %cmp1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition_al_C2lrl__, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp1, ptr align 1 %cmp, i64 16, i1 false)
    store ptr @__ctor_2lrl2_, ptr %clsr___schmu_partition_al_C2lrl__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition_al_C2lrl__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__schmu_partition_al_C2lrl__, i32 0, i32 1
    store ptr %clsr___schmu_partition_al_C2lrl__, ptr %envptr, align 8
    %__schmu_quicksort_al_Cal_2lrlC2lrl2__ = alloca %closure, align 8
    store ptr @__schmu_quicksort_al_Cal_2lrlC2lrl2__, ptr %__schmu_quicksort_al_Cal_2lrlC2lrl2__, align 8
    %clsr___schmu_quicksort_al_Cal_2lrlC2lrl2__ = alloca { ptr, ptr, %closure }, align 8
    %__schmu_partition_al_C2lrl__3 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort_al_Cal_2lrlC2lrl2__, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %__schmu_partition_al_C2lrl__3, ptr align 8 %__schmu_partition_al_C2lrl__, i64 16, i1 false)
    store ptr @__ctor_al_2lrl2_, ptr %clsr___schmu_quicksort_al_Cal_2lrlC2lrl2__, align 8
    %dtor5 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort_al_Cal_2lrlC2lrl2__, i32 0, i32 1
    store ptr null, ptr %dtor5, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %__schmu_quicksort_al_Cal_2lrlC2lrl2__, i32 0, i32 1
    store ptr %clsr___schmu_quicksort_al_Cal_2lrlC2lrl2__, ptr %envptr6, align 8
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %sub = sub i64 %1, 1
    call void @__schmu_quicksort_al_Cal_2lrlC2lrl2__(ptr %arr, i64 0, i64 %sub, ptr %clsr___schmu_quicksort_al_Cal_2lrlC2lrl2__), !dbg !38
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_al_lru2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy_al_(ptr %arr)
    %f = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 3
    call void @__copy_lru_(ptr %f)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_lru_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor2 = bitcast ptr %2 to ptr
    %ctor1 = load ptr, ptr %ctor2, align 8
    %4 = call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr ptr @__ctor_al_2lrl_2l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 56)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 56, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %1, i32 0, i32 2
    call void @__copy_al_(ptr %arr)
    %cmp = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %1, i32 0, i32 3
    call void @__copy_2lrl_(ptr %cmp)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy_2lrl_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor2 = bitcast ptr %2 to ptr
    %ctor1 = load ptr, ptr %ctor2, align 8
    %4 = call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_2lrl2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 32)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %cmp = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy_2lrl_(ptr %cmp)
    ret ptr %1
  }
  
  define linkonce_odr ptr @__ctor_al_2lrl2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 32)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %__schmu_partition__2_al_C2lrl__ = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy_al_2lrl_(ptr %__schmu_partition__2_al_C2lrl__)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy_al_2lrl_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor2 = bitcast ptr %2 to ptr
    %ctor1 = load ptr, ptr %ctor2, align 8
    %4 = call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !39 {
  entry:
    %0 = tail call ptr @malloc(i64 64)
    store ptr %0, ptr @schmu_arr, align 8
    store i64 6, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 6, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 9, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 30, ptr %"1", align 8
    %"2" = getelementptr i64, ptr %1, i64 2
    store i64 0, ptr %"2", align 8
    %"3" = getelementptr i64, ptr %1, i64 3
    store i64 50, ptr %"3", align 8
    %"4" = getelementptr i64, ptr %1, i64 4
    store i64 2030, ptr %"4", align 8
    %"5" = getelementptr i64, ptr %1, i64 5
    store i64 34, ptr %"5", align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu1, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__schmu_sort_al_2lrl__(ptr @schmu_arr, ptr %clstmp), !dbg !40
    %2 = load ptr, ptr @schmu_arr, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @__fun_schmu2, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    call void @__array_iter_al_lru__(ptr %2, ptr %clstmp1), !dbg !41
    %3 = call ptr @malloc(i64 64)
    store ptr %3, ptr @schmu_arr__2, align 8
    store i64 6, ptr %3, align 8
    %cap5 = getelementptr i64, ptr %3, i64 1
    store i64 6, ptr %cap5, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 9, ptr %4, align 8
    %"17" = getelementptr i64, ptr %4, i64 1
    store i64 30, ptr %"17", align 8
    %"28" = getelementptr i64, ptr %4, i64 2
    store i64 0, ptr %"28", align 8
    %"39" = getelementptr i64, ptr %4, i64 3
    store i64 50, ptr %"39", align 8
    %"410" = getelementptr i64, ptr %4, i64 4
    store i64 2030, ptr %"410", align 8
    %"511" = getelementptr i64, ptr %4, i64 5
    store i64 34, ptr %"511", align 8
    %clstmp12 = alloca %closure, align 8
    store ptr @__fun_schmu4, ptr %clstmp12, align 8
    %envptr14 = getelementptr inbounds %closure, ptr %clstmp12, i32 0, i32 1
    store ptr null, ptr %envptr14, align 8
    call void @__schmu_sort__2_al_2lrl__(ptr @schmu_arr__2, ptr %clstmp12), !dbg !42
    %5 = load ptr, ptr @schmu_arr__2, align 8
    %clstmp15 = alloca %closure, align 8
    store ptr @__fun_schmu5, ptr %clstmp15, align 8
    %envptr17 = getelementptr inbounds %closure, ptr %clstmp15, i32 0, i32 1
    store ptr null, ptr %envptr17, align 8
    call void @__array_iter_al_lru__(ptr %5, ptr %clstmp15), !dbg !43
    call void @__free_al_(ptr @schmu_arr__2)
    call void @__free_al_(ptr @schmu_arr)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "closure_monomorph.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_inner", linkageName: "__array_inner_Cal_lru__", scope: !1, file: !1, line: 32, type: !3, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 33, column: 7, scope: !2)
  !6 = !DILocation(line: 36, column: 6, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_iter", linkageName: "__array_iter_al_lru__", scope: !1, file: !1, line: 31, type: !3, scopeLine: 31, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = !DILocation(line: 41, column: 2, scope: !7)
  !9 = distinct !DISubprogram(name: "_array_swap_items", linkageName: "__array_swap_items_al__", scope: !1, file: !1, line: 108, type: !3, scopeLine: 108, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !10 = !DILocation(line: 109, column: 5, scope: !9)
  !11 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0_Cal_2lrl_ll_", scope: !1, file: !1, line: 5, type: !3, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !12 = !DILocation(line: 6, column: 9, scope: !11)
  !13 = !DILocation(line: 8, column: 8, scope: !11)
  !14 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1", scope: !1, file: !1, line: 36, type: !3, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !15 = distinct !DISubprogram(name: "__fun_schmu2", linkageName: "__fun_schmu2", scope: !1, file: !1, line: 37, type: !3, scopeLine: 37, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !16 = distinct !DISubprogram(name: "__fun_schmu3", linkageName: "__fun_schmu3_Cal_2lrl_ll_", scope: !1, file: !1, line: 44, type: !3, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !17 = !DILocation(line: 45, column: 9, scope: !16)
  !18 = !DILocation(line: 47, column: 8, scope: !16)
  !19 = distinct !DISubprogram(name: "__fun_schmu4", linkageName: "__fun_schmu4", scope: !1, file: !1, line: 75, type: !3, scopeLine: 75, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !20 = distinct !DISubprogram(name: "__fun_schmu5", linkageName: "__fun_schmu5", scope: !1, file: !1, line: 76, type: !3, scopeLine: 76, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !21 = distinct !DISubprogram(name: "partition", linkageName: "__schmu_partition__2_al_C2lrl__", scope: !1, file: !1, line: 41, type: !3, scopeLine: 41, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !22 = !DILocation(line: 44, column: 4, scope: !21)
  !23 = !DILocation(line: 51, column: 4, scope: !21)
  !24 = distinct !DISubprogram(name: "partition", linkageName: "__schmu_partition_al_C2lrl__", scope: !1, file: !1, line: 2, type: !3, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !25 = !DILocation(line: 5, column: 4, scope: !24)
  !26 = !DILocation(line: 12, column: 4, scope: !24)
  !27 = distinct !DISubprogram(name: "quicksort", linkageName: "__schmu_quicksort__2_al_Cal_2lrlC2lrl2__", scope: !1, file: !1, line: 62, type: !3, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !28 = !DILocation(line: 63, column: 7, scope: !27)
  !29 = !DILocation(line: 66, column: 14, scope: !27)
  !30 = !DILocation(line: 67, column: 6, scope: !27)
  !31 = distinct !DISubprogram(name: "quicksort", linkageName: "__schmu_quicksort_al_Cal_2lrlC2lrl2__", scope: !1, file: !1, line: 22, type: !3, scopeLine: 22, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !32 = !DILocation(line: 23, column: 7, scope: !31)
  !33 = !DILocation(line: 26, column: 14, scope: !31)
  !34 = !DILocation(line: 27, column: 6, scope: !31)
  !35 = distinct !DISubprogram(name: "sort", linkageName: "__schmu_sort__2_al_2lrl__", scope: !1, file: !1, line: 40, type: !3, scopeLine: 40, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !36 = !DILocation(line: 72, column: 2, scope: !35)
  !37 = distinct !DISubprogram(name: "sort", linkageName: "__schmu_sort_al_2lrl__", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !38 = !DILocation(line: 32, column: 2, scope: !37)
  !39 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !40 = !DILocation(line: 36, scope: !39)
  !41 = !DILocation(line: 37, scope: !39)
  !42 = !DILocation(line: 75, scope: !39)
  !43 = !DILocation(line: 76, scope: !39)
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
  
  %fal__ = type { ptr, ptr, ptr }
  %tal__ = type { ptr, ptr }
  %al_l_ = type { ptr, i64 }
  
  define ptr @schmu_inf() !dbg !2 {
  entry:
    %0 = alloca %fal__, align 8
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    store ptr %1, ptr %0, align 8
    %b = getelementptr inbounds %fal__, ptr %0, i32 0, i32 1
    %3 = tail call ptr @malloc(i64 24)
    %arr1 = alloca ptr, align 8
    store ptr %3, ptr %arr1, align 8
    store i64 1, ptr %3, align 8
    %cap3 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap3, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 10, ptr %4, align 8
    store ptr %3, ptr %b, align 8
    %c = getelementptr inbounds %fal__, ptr %0, i32 0, i32 2
    %5 = tail call ptr @malloc(i64 24)
    %arr5 = alloca ptr, align 8
    store ptr %5, ptr %arr5, align 8
    store i64 1, ptr %5, align 8
    %cap7 = getelementptr i64, ptr %5, i64 1
    store i64 1, ptr %cap7, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store i64 10, ptr %6, align 8
    store ptr %5, ptr %c, align 8
    %7 = alloca ptr, align 8
    call void @__free_al_(ptr %c)
    %.pre.pre = load ptr, ptr %0, align 8
    store ptr %.pre.pre, ptr %7, align 8
    call void @__free_al_(ptr %7)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    %8 = load ptr, ptr %sunkaddr, align 8
    ret ptr %8
  }
  
  define void @schmu_set_moved() !dbg !5 {
  entry:
    %0 = alloca %tal__, align 8
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    store ptr %1, ptr %0, align 8
    %b = getelementptr inbounds %tal__, ptr %0, i32 0, i32 1
    %3 = tail call ptr @malloc(i64 24)
    %arr1 = alloca ptr, align 8
    store ptr %3, ptr %arr1, align 8
    store i64 1, ptr %3, align 8
    %cap3 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap3, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 20, ptr %4, align 8
    store ptr %3, ptr %b, align 8
    %5 = alloca %al_l_, align 8
    %6 = load ptr, ptr %0, align 8
    store ptr %6, ptr %5, align 8
    %"1" = getelementptr inbounds %al_l_, ptr %5, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    %7 = tail call ptr @malloc(i64 24)
    %arr6 = alloca ptr, align 8
    store ptr %7, ptr %arr6, align 8
    store i64 1, ptr %7, align 8
    %cap8 = getelementptr i64, ptr %7, i64 1
    store i64 1, ptr %cap8, align 8
    %8 = getelementptr i8, ptr %7, i64 16
    store i64 20, ptr %8, align 8
    store ptr %7, ptr %0, align 8
    call void @__free_al_l_(ptr %5)
    call void @__free_al_al2_(ptr %0)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_al_l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_al_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_al_al2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_al_(ptr %1)
    %2 = getelementptr inbounds %tal__, ptr %0, i32 0, i32 1
    call void @__free_al_(ptr %2)
    ret void
  }
  
  define i64 @main(i64 %arg) !dbg !6 {
  entry:
    %0 = tail call ptr @schmu_inf(), !dbg !7
    tail call void @schmu_set_moved(), !dbg !8
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_al_(ptr %1)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "partials.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "inf", linkageName: "schmu_inf", scope: !1, file: !1, line: 3, type: !3, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = distinct !DISubprogram(name: "set_moved", linkageName: "schmu_set_moved", scope: !1, file: !1, line: 15, type: !3, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !7 = !DILocation(line: 12, column: 7, scope: !6)
  !8 = !DILocation(line: 21, scope: !6)

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
  
  fixed_array_allocs.smu:8.5-8: warning: Unmutated mutable binding arr.
  
  8 | let arr& = #["hey", "hie"] -- correctly free as mut
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
  
  %"2l_" = type { i64, i64 }
  
  @schmu_a = constant i64 17
  @schmu_arr = constant [3 x i64] [i64 1, i64 17, i64 3]
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @main(i64 %arg) !dbg !2 {
  entry:
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 17)
    %0 = alloca %"2l_", align 8
    store i64 10, ptr %0, align 8
    %"1" = getelementptr inbounds %"2l_", ptr %0, i32 0, i32 1
    store i64 17, ptr %"1", align 8
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "const_fixed_arr.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  $ valgrind -q --leak-check=yes --show-reachable=yes ./const_fixed_arr
  17

Using unit values
  $ schmu unit_values.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./unit_values
  unit_values.smu:3.5-6: warning: Unused binding b.
  
  3 | let b = Some(a)
          ^
  
  unit_values.smu:8.8-9: warning: Unused binding a.
  
  8 |   Some(a): println("some")
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
  
  %option.tu_ = type { i32 }
  %thing_ = type {}
  %inrec_ = type { i64, double }
  
  @schmu_a = constant i8 0
  @schmu_b = constant %option.tu_ { i32 1 }
  @schmu_t = constant %thing_ zeroinitializer
  @schmu_u = constant i8 0
  @schmu_t__3 = constant %inrec_ { i64 10, double 9.990000e+01 }
  @schmu_arr__2 = constant i8 0
  @schmu_b__2 = global %option.tu_ zeroinitializer, align 4
  @schmu_t2 = global %thing_ zeroinitializer, align 1
  @schmu_u2 = global i8 0, align 1
  @schmu_arr = global ptr null, align 8
  @schmu_u__2 = global i8 0, align 1
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"some\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  @2 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"%.9g\0A\00" }
  @3 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  declare void @string_println(ptr %0)
  
  define linkonce_odr void @__array_push_au_u_(ptr noalias %arr) !dbg !2 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5, !dbg !5
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !6
  
  then2:                                            ; preds = %then
    %3 = tail call ptr @realloc(ptr %0, i64 16)
    store ptr %3, ptr %arr, align 8
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 4, ptr %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %1
    %4 = tail call ptr @realloc(ptr %0, i64 16)
    store ptr %4, ptr %arr, align 8
    %newcap3 = getelementptr i64, ptr %4, i64 1
    store i64 %mul, ptr %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %5 = phi ptr [ %4, %else ], [ %3, %then2 ], [ %0, %entry ]
    %add = add i64 %2, 1
    store i64 %add, ptr %5, align 8
    ret void
  }
  
  define void @schmu_a__2() !dbg !7 {
  entry:
    ret void
  }
  
  define void @schmu_t__2(ptr noalias %0) !dbg !8 {
  entry:
    store %thing_ zeroinitializer, ptr %0, align 1
    ret void
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  define i64 @main(i64 %arg) !dbg !9 {
  entry:
    store i32 1, ptr @schmu_b__2, align 4
    tail call void @schmu_a__2(), !dbg !10
    %index = load i32, ptr @schmu_b__2, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !11
  
  then:                                             ; preds = %entry
    tail call void @string_println(ptr @0), !dbg !12
    br label %ifcont
  
  else:                                             ; preds = %entry
    tail call void @string_println(ptr @1), !dbg !13
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    tail call void @schmu_t__2(ptr @schmu_t2), !dbg !14
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @2, i64 16), double 9.990000e+01)
    %0 = tail call ptr @malloc(i64 16)
    store ptr %0, ptr @schmu_arr, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    tail call void @__array_push_au_u_(ptr @schmu_arr), !dbg !15
    %2 = load ptr, ptr @schmu_arr, align 8
    %3 = load i64, ptr %2, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @3, i64 16), i64 %3)
    %4 = alloca %thing_, align 8
    %5 = alloca %thing_, align 8
    tail call void @__free_au_(ptr @schmu_arr)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_au_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "unit_values.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_au_u_", scope: !1, file: !1, line: 15, type: !3, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !3 = !DISubroutineType(flags: DIFlagPrototyped, types: !4)
  !4 = !{}
  !5 = !DILocation(line: 19, column: 5, scope: !2)
  !6 = !DILocation(line: 20, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "a", linkageName: "schmu_a__2", scope: !1, file: !1, line: 5, type: !3, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !8 = distinct !DISubprogram(name: "t", linkageName: "schmu_t__2", scope: !1, file: !1, line: 16, type: !3, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !1, file: !1, line: 1, type: !3, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !4)
  !10 = !DILocation(line: 6, column: 13, scope: !9)
  !11 = !DILocation(line: 8, column: 2, scope: !9)
  !12 = !DILocation(line: 8, column: 11, scope: !9)
  !13 = !DILocation(line: 9, column: 8, scope: !9)
  !14 = !DILocation(line: 17, column: 9, scope: !9)
  !15 = !DILocation(line: 27, scope: !9)
  some
  99.9
  3

`inner` here should not make `tmp` a const, otherwise could gen would fail
  $ schmu mutable_inner_let.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./mutable_inner_let


Don't free params if parts are passed in tail calls
  $ schmu free_param_parts.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./free_param_parts
  thing
  none
