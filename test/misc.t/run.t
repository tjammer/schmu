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
    br i1 %eq, label %ifcont8, label %else, !dbg !6
  
  else:                                             ; preds = %entry
    %lt = icmp slt i64 %n, 1
    br i1 %lt, label %ifcont8, label %else2, !dbg !7
  
  else2:                                            ; preds = %else
    %lt3 = icmp slt i64 %n, 10
    br i1 %lt3, label %ifcont8, label %else5, !dbg !8
  
  else5:                                            ; preds = %else2
    br label %ifcont8
  
  ifcont8:                                          ; preds = %else, %else2, %else5, %entry
    %iftmp9 = phi i64 [ 1, %entry ], [ 2, %else ], [ 4, %else5 ], [ 3, %else2 ]
    ret i64 %iftmp9
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %0 = tail call i64 @schmu_test(i64 10), !dbg !10
    %eq = icmp eq i64 %0, 1
    tail call void @assert(i1 %eq), !dbg !11
    %1 = tail call i64 @schmu_test(i64 0), !dbg !12
    %eq1 = icmp eq i64 %1, 2
    tail call void @assert(i1 %eq1), !dbg !13
    %2 = tail call i64 @schmu_test(i64 1), !dbg !14
    %eq2 = icmp eq i64 %2, 3
    tail call void @assert(i1 %eq2), !dbg !15
    %3 = tail call i64 @schmu_test(i64 11), !dbg !16
    %eq3 = icmp eq i64 %3, 4
    tail call void @assert(i1 %eq3), !dbg !17
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "elseif.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "elseif.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 4, column: 5, scope: !2)
  !7 = !DILocation(line: 5, column: 10, scope: !2)
  !8 = !DILocation(line: 6, column: 10, scope: !2)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 10, column: 7, scope: !9)
  !11 = !DILocation(line: 10, scope: !9)
  !12 = !DILocation(line: 11, column: 7, scope: !9)
  !13 = !DILocation(line: 11, scope: !9)
  !14 = !DILocation(line: 12, column: 7, scope: !9)
  !15 = !DILocation(line: 12, scope: !9)
  !16 = !DILocation(line: 13, column: 7, scope: !9)
  !17 = !DILocation(line: 13, scope: !9)

Test simple typedef
  $ schmu --dump-llvm stub.o simple_typealias.smu && ./simple_typealias
  simple_typealias.smu:2.10-14: warning: Unused binding puts.
  
  2 | external puts : fun (foo) -> unit
               ^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "simple_typealias.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "simple_typealias.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}

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
  %shader = type { i32, ptr }
  
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"a\00" }
  @1 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"b\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare { double, double } @subv2(double %0, double %1)
  
  declare { i64, i64 } @subi2(i64 %0, i64 %1)
  
  declare double @subv1(double %0)
  
  declare i64 @subi1(i64 %0)
  
  declare void @subv3(ptr noalias %0, ptr byval(%v3) %1)
  
  declare void @subi3(ptr noalias %0, ptr byval(%i3) %1)
  
  declare void @subv4(ptr noalias %0, ptr byval(%v4) %1)
  
  declare void @submixed4(ptr noalias %0, ptr byval(%mixed4) %1)
  
  declare void @subtrailv2(ptr noalias %0, ptr byval(%trailv2) %1)
  
  declare <2 x float> @subf2s(<2 x float> %0)
  
  declare { <2 x float>, float } @subf3s(<2 x float> %0, float %1)
  
  declare { i32, i64 } @load_shader(ptr %0, ptr %1)
  
  declare void @set_shader_value(i32 %0, i64 %1, i32 %2, ptr byval(%v4) %3)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    %boxconst = alloca %v2, align 8
    store %v2 { double 1.000000e+00, double 1.000000e+01 }, ptr %boxconst, align 8
    %fst1 = load double, ptr %boxconst, align 8
    %snd = getelementptr inbounds { double, double }, ptr %boxconst, i32 0, i32 1
    %snd2 = load double, ptr %snd, align 8
    %ret = alloca %v2, align 8
    %0 = tail call { double, double } @subv2(double %fst1, double %snd2), !dbg !6
    store { double, double } %0, ptr %ret, align 8
    %boxconst3 = alloca %i2, align 8
    store %i2 { i64 1, i64 10 }, ptr %boxconst3, align 8
    %fst5 = load i64, ptr %boxconst3, align 8
    %snd6 = getelementptr inbounds { i64, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    %ret8 = alloca %i2, align 8
    %1 = tail call { i64, i64 } @subi2(i64 %fst5, i64 %snd7), !dbg !7
    store { i64, i64 } %1, ptr %ret8, align 8
    %ret9 = alloca %v1, align 8
    %2 = tail call double @subv1(double 1.000000e+00), !dbg !8
    store double %2, ptr %ret9, align 8
    %ret10 = alloca %i1, align 8
    %3 = tail call i64 @subi1(i64 1), !dbg !9
    store i64 %3, ptr %ret10, align 8
    %boxconst11 = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, ptr %boxconst11, align 8
    %ret12 = alloca %v3, align 8
    call void @subv3(ptr %ret12, ptr %boxconst11), !dbg !10
    %boxconst13 = alloca %i3, align 8
    store %i3 { i64 1, i64 10, i64 100 }, ptr %boxconst13, align 8
    %ret14 = alloca %i3, align 8
    call void @subi3(ptr %ret14, ptr %boxconst13), !dbg !11
    %boxconst15 = alloca %v4, align 8
    store %v4 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, ptr %boxconst15, align 8
    %ret16 = alloca %v4, align 8
    call void @subv4(ptr %ret16, ptr %boxconst15), !dbg !12
    %boxconst17 = alloca %mixed4, align 8
    store %mixed4 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, i64 1 }, ptr %boxconst17, align 8
    %ret18 = alloca %mixed4, align 8
    call void @submixed4(ptr %ret18, ptr %boxconst17), !dbg !13
    %boxconst19 = alloca %trailv2, align 8
    store %trailv2 { i64 1, i64 2, double 1.000000e+00, double 2.000000e+00 }, ptr %boxconst19, align 8
    %ret20 = alloca %trailv2, align 8
    call void @subtrailv2(ptr %ret20, ptr %boxconst19), !dbg !14
    %ret21 = alloca %f2s, align 8
    %4 = call <2 x float> @subf2s(<2 x float> <float 2.000000e+00, float 3.000000e+00>), !dbg !15
    store <2 x float> %4, ptr %ret21, align 8
    %boxconst22 = alloca %f3s, align 8
    store %f3s { float 2.000000e+00, float 3.000000e+00, float 5.000000e+00 }, ptr %boxconst22, align 4
    %fst24 = load <2 x float>, ptr %boxconst22, align 8
    %snd25 = getelementptr inbounds { <2 x float>, float }, ptr %boxconst22, i32 0, i32 1
    %snd26 = load float, ptr %snd25, align 4
    %ret27 = alloca %f3s, align 8
    %5 = call { <2 x float>, float } @subf3s(<2 x float> %fst24, float %snd26), !dbg !16
    store { <2 x float>, float } %5, ptr %ret27, align 8
    %6 = call ptr @string_data(ptr @0), !dbg !17
    %7 = call ptr @string_data(ptr @1), !dbg !18
    %ret28 = alloca %shader, align 8
    %8 = call { i32, i64 } @load_shader(ptr %6, ptr %7), !dbg !19
    store { i32, i64 } %8, ptr %ret28, align 8
    %9 = alloca %shader, align 8
    store i32 0, ptr %9, align 4
    %locs = getelementptr inbounds %shader, ptr %9, i32 0, i32 1
    store ptr null, ptr %locs, align 8
    %boxconst33 = alloca %v4, align 8
    store %v4 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, ptr %boxconst33, align 8
    call void @set_shader_value(i32 0, i64 0, i32 0, ptr %boxconst33), !dbg !20
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "abi.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "abi.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 28, column: 8, scope: !2)
  !7 = !DILocation(line: 29, column: 8, scope: !2)
  !8 = !DILocation(line: 30, column: 8, scope: !2)
  !9 = !DILocation(line: 31, column: 8, scope: !2)
  !10 = !DILocation(line: 32, column: 8, scope: !2)
  !11 = !DILocation(line: 33, column: 8, scope: !2)
  !12 = !DILocation(line: 34, column: 8, scope: !2)
  !13 = !DILocation(line: 35, column: 8, scope: !2)
  !14 = !DILocation(line: 36, column: 8, scope: !2)
  !15 = !DILocation(line: 37, column: 8, scope: !2)
  !16 = !DILocation(line: 38, column: 8, scope: !2)
  !17 = !DILocation(line: 39, column: 19, scope: !2)
  !18 = !DILocation(line: 39, column: 32, scope: !2)
  !19 = !DILocation(line: 39, scope: !2)
  !20 = !DILocation(line: 40, scope: !2)

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
    tail call void @string_println(ptr @0), !dbg !6
    ret i1 false
  }
  
  define i1 @schmu_true_() !dbg !7 {
  entry:
    tail call void @string_println(ptr @1), !dbg !8
    ret i1 true
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    tail call void @string_println(ptr @2), !dbg !10
    %0 = tail call i1 @schmu_true_(), !dbg !11
    br i1 %0, label %true1, label %cont
  
  true1:                                            ; preds = %entry
    %1 = tail call i1 @schmu_true_(), !dbg !12
    br i1 %1, label %true2, label %cont
  
  true2:                                            ; preds = %true1
    br label %cont
  
  cont:                                             ; preds = %true2, %true1, %entry
    %andtmp = phi i1 [ false, %entry ], [ false, %true1 ], [ true, %true2 ]
    br i1 %andtmp, label %then, label %else, !dbg !11
  
  then:                                             ; preds = %cont
    tail call void @string_println(ptr @3), !dbg !13
    br label %ifcont
  
  else:                                             ; preds = %cont
    tail call void @string_println(ptr @4), !dbg !14
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %2 = tail call i1 @schmu_true_(), !dbg !15
    br i1 %2, label %true11, label %cont3
  
  true11:                                           ; preds = %ifcont
    %3 = tail call i1 @schmu_false_(), !dbg !16
    br i1 %3, label %true22, label %cont3
  
  true22:                                           ; preds = %true11
    br label %cont3
  
  cont3:                                            ; preds = %true22, %true11, %ifcont
    %andtmp4 = phi i1 [ false, %ifcont ], [ false, %true11 ], [ true, %true22 ]
    br i1 %andtmp4, label %then5, label %else6, !dbg !15
  
  then5:                                            ; preds = %cont3
    tail call void @string_println(ptr @3), !dbg !17
    br label %ifcont7
  
  else6:                                            ; preds = %cont3
    tail call void @string_println(ptr @4), !dbg !18
    br label %ifcont7
  
  ifcont7:                                          ; preds = %else6, %then5
    %4 = tail call i1 @schmu_false_(), !dbg !19
    br i1 %4, label %true18, label %cont10
  
  true18:                                           ; preds = %ifcont7
    %5 = tail call i1 @schmu_true_(), !dbg !20
    br i1 %5, label %true29, label %cont10
  
  true29:                                           ; preds = %true18
    br label %cont10
  
  cont10:                                           ; preds = %true29, %true18, %ifcont7
    %andtmp11 = phi i1 [ false, %ifcont7 ], [ false, %true18 ], [ true, %true29 ]
    br i1 %andtmp11, label %then12, label %else13, !dbg !19
  
  then12:                                           ; preds = %cont10
    tail call void @string_println(ptr @3), !dbg !21
    br label %ifcont14
  
  else13:                                           ; preds = %cont10
    tail call void @string_println(ptr @4), !dbg !22
    br label %ifcont14
  
  ifcont14:                                         ; preds = %else13, %then12
    %6 = tail call i1 @schmu_false_(), !dbg !23
    br i1 %6, label %true115, label %cont17
  
  true115:                                          ; preds = %ifcont14
    %7 = tail call i1 @schmu_false_(), !dbg !24
    br i1 %7, label %true216, label %cont17
  
  true216:                                          ; preds = %true115
    br label %cont17
  
  cont17:                                           ; preds = %true216, %true115, %ifcont14
    %andtmp18 = phi i1 [ false, %ifcont14 ], [ false, %true115 ], [ true, %true216 ]
    br i1 %andtmp18, label %then19, label %else20, !dbg !23
  
  then19:                                           ; preds = %cont17
    tail call void @string_println(ptr @3), !dbg !25
    br label %ifcont21
  
  else20:                                           ; preds = %cont17
    tail call void @string_println(ptr @4), !dbg !26
    br label %ifcont21
  
  ifcont21:                                         ; preds = %else20, %then19
    tail call void @string_println(ptr @5), !dbg !27
    %8 = tail call i1 @schmu_true_(), !dbg !28
    br i1 %8, label %cont22, label %false1
  
  false1:                                           ; preds = %ifcont21
    %9 = tail call i1 @schmu_true_(), !dbg !29
    br i1 %9, label %cont22, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont22
  
  cont22:                                           ; preds = %false2, %false1, %ifcont21
    %andtmp23 = phi i1 [ true, %ifcont21 ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp23, label %then24, label %else25, !dbg !28
  
  then24:                                           ; preds = %cont22
    tail call void @string_println(ptr @3), !dbg !30
    br label %ifcont26
  
  else25:                                           ; preds = %cont22
    tail call void @string_println(ptr @4), !dbg !31
    br label %ifcont26
  
  ifcont26:                                         ; preds = %else25, %then24
    %10 = tail call i1 @schmu_true_(), !dbg !32
    br i1 %10, label %cont29, label %false127
  
  false127:                                         ; preds = %ifcont26
    %11 = tail call i1 @schmu_false_(), !dbg !33
    br i1 %11, label %cont29, label %false228
  
  false228:                                         ; preds = %false127
    br label %cont29
  
  cont29:                                           ; preds = %false228, %false127, %ifcont26
    %andtmp30 = phi i1 [ true, %ifcont26 ], [ true, %false127 ], [ false, %false228 ]
    br i1 %andtmp30, label %then31, label %else32, !dbg !32
  
  then31:                                           ; preds = %cont29
    tail call void @string_println(ptr @3), !dbg !34
    br label %ifcont33
  
  else32:                                           ; preds = %cont29
    tail call void @string_println(ptr @4), !dbg !35
    br label %ifcont33
  
  ifcont33:                                         ; preds = %else32, %then31
    %12 = tail call i1 @schmu_false_(), !dbg !36
    br i1 %12, label %cont36, label %false134
  
  false134:                                         ; preds = %ifcont33
    %13 = tail call i1 @schmu_true_(), !dbg !37
    br i1 %13, label %cont36, label %false235
  
  false235:                                         ; preds = %false134
    br label %cont36
  
  cont36:                                           ; preds = %false235, %false134, %ifcont33
    %andtmp37 = phi i1 [ true, %ifcont33 ], [ true, %false134 ], [ false, %false235 ]
    br i1 %andtmp37, label %then38, label %else39, !dbg !36
  
  then38:                                           ; preds = %cont36
    tail call void @string_println(ptr @3), !dbg !38
    br label %ifcont40
  
  else39:                                           ; preds = %cont36
    tail call void @string_println(ptr @4), !dbg !39
    br label %ifcont40
  
  ifcont40:                                         ; preds = %else39, %then38
    %14 = tail call i1 @schmu_false_(), !dbg !40
    br i1 %14, label %cont43, label %false141
  
  false141:                                         ; preds = %ifcont40
    %15 = tail call i1 @schmu_false_(), !dbg !41
    br i1 %15, label %cont43, label %false242
  
  false242:                                         ; preds = %false141
    br label %cont43
  
  cont43:                                           ; preds = %false242, %false141, %ifcont40
    %andtmp44 = phi i1 [ true, %ifcont40 ], [ true, %false141 ], [ false, %false242 ]
    br i1 %andtmp44, label %then45, label %else46, !dbg !40
  
  then45:                                           ; preds = %cont43
    tail call void @string_println(ptr @3), !dbg !42
    br label %ifcont47
  
  else46:                                           ; preds = %cont43
    tail call void @string_println(ptr @4), !dbg !43
    br label %ifcont47
  
  ifcont47:                                         ; preds = %else46, %then45
    tail call void @string_println(ptr @6), !dbg !44
    %16 = tail call i1 @schmu_true_(), !dbg !45
    %17 = xor i1 %16, true
    br i1 %17, label %then48, label %else49, !dbg !46
  
  then48:                                           ; preds = %ifcont47
    tail call void @string_println(ptr @3), !dbg !47
    br label %ifcont50
  
  else49:                                           ; preds = %ifcont47
    tail call void @string_println(ptr @4), !dbg !48
    br label %ifcont50
  
  ifcont50:                                         ; preds = %else49, %then48
    %18 = tail call i1 @schmu_false_(), !dbg !49
    %19 = xor i1 %18, true
    br i1 %19, label %then51, label %else52, !dbg !50
  
  then51:                                           ; preds = %ifcont50
    tail call void @string_println(ptr @3), !dbg !51
    br label %ifcont53
  
  else52:                                           ; preds = %ifcont50
    tail call void @string_println(ptr @4), !dbg !52
    br label %ifcont53
  
  ifcont53:                                         ; preds = %else52, %then51
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "boolean_logic.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "false_", linkageName: "schmu_false_", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "boolean_logic.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 7, column: 2, scope: !2)
  !7 = distinct !DISubprogram(name: "true_", linkageName: "schmu_true_", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 2, column: 2, scope: !7)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 11, scope: !9)
  !11 = !DILocation(line: 13, column: 3, scope: !9)
  !12 = !DILocation(line: 13, column: 15, scope: !9)
  !13 = !DILocation(line: 14, column: 2, scope: !9)
  !14 = !DILocation(line: 16, column: 2, scope: !9)
  !15 = !DILocation(line: 19, column: 3, scope: !9)
  !16 = !DILocation(line: 19, column: 15, scope: !9)
  !17 = !DILocation(line: 20, column: 2, scope: !9)
  !18 = !DILocation(line: 22, column: 2, scope: !9)
  !19 = !DILocation(line: 25, column: 3, scope: !9)
  !20 = !DILocation(line: 25, column: 16, scope: !9)
  !21 = !DILocation(line: 26, column: 2, scope: !9)
  !22 = !DILocation(line: 28, column: 2, scope: !9)
  !23 = !DILocation(line: 31, column: 3, scope: !9)
  !24 = !DILocation(line: 31, column: 16, scope: !9)
  !25 = !DILocation(line: 32, column: 2, scope: !9)
  !26 = !DILocation(line: 34, column: 2, scope: !9)
  !27 = !DILocation(line: 37, scope: !9)
  !28 = !DILocation(line: 39, column: 3, scope: !9)
  !29 = !DILocation(line: 39, column: 14, scope: !9)
  !30 = !DILocation(line: 40, column: 2, scope: !9)
  !31 = !DILocation(line: 42, column: 2, scope: !9)
  !32 = !DILocation(line: 45, column: 3, scope: !9)
  !33 = !DILocation(line: 45, column: 14, scope: !9)
  !34 = !DILocation(line: 46, column: 2, scope: !9)
  !35 = !DILocation(line: 48, column: 2, scope: !9)
  !36 = !DILocation(line: 51, column: 3, scope: !9)
  !37 = !DILocation(line: 51, column: 15, scope: !9)
  !38 = !DILocation(line: 52, column: 2, scope: !9)
  !39 = !DILocation(line: 54, column: 2, scope: !9)
  !40 = !DILocation(line: 57, column: 3, scope: !9)
  !41 = !DILocation(line: 57, column: 15, scope: !9)
  !42 = !DILocation(line: 58, column: 2, scope: !9)
  !43 = !DILocation(line: 60, column: 2, scope: !9)
  !44 = !DILocation(line: 63, scope: !9)
  !45 = !DILocation(line: 65, column: 7, scope: !9)
  !46 = !DILocation(line: 65, column: 3, scope: !9)
  !47 = !DILocation(line: 66, column: 2, scope: !9)
  !48 = !DILocation(line: 68, column: 2, scope: !9)
  !49 = !DILocation(line: 71, column: 7, scope: !9)
  !50 = !DILocation(line: 71, column: 3, scope: !9)
  !51 = !DILocation(line: 72, column: 2, scope: !9)
  !52 = !DILocation(line: 74, column: 2, scope: !9)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    ret i64 -2
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "unary_minus.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "unary_minus.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
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
  expecting unit
  but found int.
  
  2 | if true{2}
      ^^^^^^^^^^
  
  [1]

Piping for ctors and field accessors
  $ schmu stub.o --dump-llvm piping.smu && ./piping
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %option.t.l = type { i32, i64 }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @0 = private unnamed_addr constant { i64, i64, [3 x i8] } { i64 2, i64 2, [3 x i8] c"u8\00" }
  @1 = private unnamed_addr constant { i64, i64, [1 x [1 x i8]] } { i64 0, i64 1, [1 x [1 x i8]] zeroinitializer }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare ptr @string_of_array(ptr %0)
  
  declare void @string_println(ptr %0)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  declare void @Printi(i64 %0)
  
  define linkonce_odr void @__array_fixed_swap_items_A64.c(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
  entry:
    %eq = icmp eq i64 %i, %j
    %0 = xor i1 %eq, true
    br i1 %0, label %then, label %ifcont, !dbg !6
  
  then:                                             ; preds = %entry
    %1 = alloca i8, align 1
    %2 = getelementptr i8, ptr %arr, i64 %i
    %3 = load i8, ptr %2, align 1
    store i8 %3, ptr %1, align 1
    %4 = getelementptr i8, ptr %arr, i64 %j
    %5 = load i8, ptr %4, align 1
    store i8 %5, ptr %2, align 1
    store i8 %3, ptr %4, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !7 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !9
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %ret), !dbg !10
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %fm) !dbg !11 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !12 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !13
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !14 {
  entry:
    %1 = alloca [64 x i8], align 1
    store [64 x i8] zeroinitializer, ptr %1, align 1
    %lt = icmp slt i64 %base, 2
    br i1 %lt, label %cont, label %false1
  
  false1:                                           ; preds = %entry
    %gt = icmp sgt i64 %base, 36
    br i1 %gt, label %cont, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont
  
  cont:                                             ; preds = %false2, %false1, %entry
    %andtmp = phi i1 [ true, %entry ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp, label %then, label %else, !dbg !15
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !16
    br label %ifcont
  
  else:                                             ; preds = %cont
    %fmt_aux = alloca %closure, align 8
    store ptr @fmt_aux, ptr %fmt_aux, align 8
    %clsr_fmt_aux = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr, align 8
    %base1 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 3
    store i64 %base, ptr %base1, align 8
    store ptr @__ctor_tp.A64.cl, ptr %clsr_fmt_aux, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt_aux, i32 0, i32 1
    store ptr %clsr_fmt_aux, ptr %envptr, align 8
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !17
    %add = add i64 %2, 1
    %div = sdiv i64 %add, 2
    %__fun_fmt2 = alloca %closure, align 8
    store ptr @__fun_fmt2, ptr %__fun_fmt2, align 8
    %clsr___fun_fmt2 = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr5 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr5, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 3
    store i64 %add, ptr %_fmt_length, align 8
    store ptr @__ctor_tp.A64.cl, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !18
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !19
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %i) !dbg !20 {
  entry:
    tail call void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !21
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_cc(ptr %fmt, i8 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i8 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !25
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !26 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !27
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !28
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !29
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, ptr %str) !dbg !30 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !31
    %2 = tail call i64 @string_len(ptr %str), !dbg !32
    tail call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !33
    ret void
  }
  
  define linkonce_odr void @__fmt_u8_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i8 %u) !dbg !34 {
  entry:
    %1 = zext i8 %u to i64
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, i64 %1), !dbg !35
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %ret, ptr @0), !dbg !36
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !37 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !38
    ret void
  }
  
  define i64 @__fun_schmu0(i64 %x) !dbg !39 {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @__fun_schmu1(i32 %0, i64 %1) !dbg !41 {
  entry:
    %x = alloca { i32, i64 }, align 8
    store i32 %0, ptr %x, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %x, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else, !dbg !42
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !43 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %base = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %base2 = load i64, ptr %base, align 8
    %1 = alloca i64, align 8
    store i64 %value, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 %index, ptr %2, align 8
    %3 = add i64 %index, 1
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %then ], [ %3, %entry ]
    %4 = phi i64 [ %div, %then ], [ %value, %entry ]
    %div = sdiv i64 %4, %base2
    %uglygep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %uglygep10 = getelementptr i8, ptr %uglygep9, i64 -1
    %5 = load ptr, ptr @fmt_int_digits, align 8
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !44
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !45
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !46
    br i1 %lt, label %then4, label %ifcont, !dbg !46
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define linkonce_odr void @__free__up.clru(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free__up.clru(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !47 {
  entry:
    %0 = tail call i64 @__fun_schmu0(i64 1), !dbg !48
    tail call void @Printi(i64 %0), !dbg !49
    %boxconst = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %1 = tail call i64 @__fun_schmu1(i32 %fst1, i64 %snd2), !dbg !50
    tail call void @Printi(i64 %1), !dbg !51
    tail call void @Printi(i64 1), !dbg !52
    tail call void @string_println(ptr @1), !dbg !53
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 10), !dbg !54
    %clstmp3 = alloca %closure, align 8
    store ptr @__fmt_u8_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp3, align 8
    %envptr5 = getelementptr inbounds %closure, ptr %clstmp3, i32 0, i32 1
    store ptr null, ptr %envptr5, align 8
    %2 = call ptr @malloc(i64 19)
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
    %4 = call ptr @string_of_array(ptr %2), !dbg !55
    %5 = call i8 @string_get(ptr %4, i64 1), !dbg !56
    call void @__fmt_stdout_println_fmt_stdout_println_cc(ptr %clstmp3, i8 %5), !dbg !57
    %6 = alloca ptr, align 8
    store ptr %4, ptr %6, align 8
    call void @__free_a.c(ptr %6)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "piping.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64.c", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_fmt.formatter.t.uru", scope: !8, file: !8, line: 143, type: !4, scopeLine: 143, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DIFile(filename: "fmt.smu", directory: "")
  !9 = !DILocation(line: 145, column: 2, scope: !7)
  !10 = !DILocation(line: 146, column: 15, scope: !7)
  !11 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_fmt.formatter.t.uru", scope: !8, file: !8, line: 28, type: !4, scopeLine: 28, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u", scope: !8, file: !8, line: 22, type: !4, scopeLine: 22, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 24, column: 4, scope: !12)
  !14 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u", scope: !8, file: !8, line: 56, type: !4, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 58, column: 6, scope: !14)
  !16 = !DILocation(line: 59, column: 4, scope: !14)
  !17 = !DILocation(line: 76, column: 17, scope: !14)
  !18 = !DILocation(line: 79, column: 4, scope: !14)
  !19 = !DILocation(line: 83, column: 4, scope: !14)
  !20 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_fmt.formatter.t.urfmt.formatter.t.u", scope: !8, file: !8, line: 111, type: !4, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 112, column: 2, scope: !20)
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_cc", scope: !8, file: !8, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 293, column: 9, scope: !22)
  !24 = !DILocation(line: 293, column: 4, scope: !22)
  !25 = !DILocation(line: 293, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !8, file: !8, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 293, column: 9, scope: !26)
  !28 = !DILocation(line: 293, column: 4, scope: !26)
  !29 = !DILocation(line: 293, column: 31, scope: !26)
  !30 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_fmt.formatter.t.urfmt.formatter.t.u", scope: !8, file: !8, line: 124, type: !4, scopeLine: 124, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !31 = !DILocation(line: 125, column: 22, scope: !30)
  !32 = !DILocation(line: 125, column: 40, scope: !30)
  !33 = !DILocation(line: 125, column: 2, scope: !30)
  !34 = distinct !DISubprogram(name: "_fmt_u8", linkageName: "__fmt_u8_fmt.formatter.t.urfmt.formatter.t.u", scope: !8, file: !8, line: 134, type: !4, scopeLine: 134, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !35 = !DILocation(line: 135, column: 2, scope: !34)
  !36 = !DILocation(line: 135, column: 26, scope: !34)
  !37 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 80, column: 6, scope: !37)
  !39 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !40, file: !40, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !40 = !DIFile(filename: "piping.smu", directory: "")
  !41 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1", scope: !40, file: !40, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !42 = !DILocation(line: 8, column: 2, scope: !41)
  !43 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !44 = !DILocation(line: 65, column: 21, scope: !43)
  !45 = !DILocation(line: 66, column: 10, scope: !43)
  !46 = !DILocation(line: 69, column: 11, scope: !43)
  !47 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !40, file: !40, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !48 = !DILocation(line: 4, column: 5, scope: !47)
  !49 = !DILocation(line: 4, column: 22, scope: !47)
  !50 = !DILocation(line: 7, column: 3, scope: !47)
  !51 = !DILocation(line: 11, column: 3, scope: !47)
  !52 = !DILocation(line: 15, column: 13, scope: !47)
  !53 = !DILocation(line: 16, scope: !47)
  !54 = !DILocation(line: 17, column: 12, scope: !47)
  !55 = !DILocation(line: 18, scope: !47)
  !56 = !DILocation(line: 18, column: 36, scope: !47)
  !57 = !DILocation(line: 18, column: 59, scope: !47)
  
  2
  1
  1
  10
  98u8

Function calls for known functions act as annotations to decide which ctor or record to use.
Prints nothing, just works
  $ schmu function_call_annot.smu

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

Increase refcount for returned params in ifs
  $ schmu --dump-llvm if_ret_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./if_ret_param
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %fmt.formatter.t.a.c = type { %closure, ptr }
  %tp.lfmt.formatter.t.a.c = type { i64, %fmt.formatter.t.a.c }
  
  @fmt_str_missing_arg_msg = external global ptr
  @fmt_str_too_many_arg_msg = external global ptr
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"/\00" }
  @schmu_s = constant ptr @0
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @1 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"/{}\00" }
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare void @fmt_prerr(ptr noalias %0)
  
  declare void @fmt_str_helper_printn(ptr noalias %0, ptr %1, ptr %2)
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !2 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !6
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %ret), !dbg !7
    ret void
  }
  
  define linkonce_odr ptr @__fmt_formatter_extract_fmt.formatter.t.a.cra.c(ptr %fm) !dbg !8 {
  entry:
    %0 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %fm, i32 0, i32 1
    tail call void @__free_except1_fmt.formatter.t.a.c(ptr %fm)
    %1 = load ptr, ptr %0, align 8
    ret ptr %1
  }
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %fm) !dbg !9 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !10 {
  entry:
    %1 = alloca %fmt.formatter.t.a.c, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 24, i1 false)
    %2 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %1, i32 0, i32 1
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    call void %loadtmp(ptr %2, ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !11
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !12 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !13
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %p, ptr %str) !dbg !14 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !15
    %2 = tail call i64 @string_len(ptr %str), !dbg !16
    tail call void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !17
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, ptr %str) !dbg !18 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !19
    %2 = tail call i64 @string_len(ptr %str), !dbg !20
    tail call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !21
    ret void
  }
  
  define linkonce_odr void @__fmt_str_impl_fmt_fail_missing_rfmt.formatter.t.a.c(ptr noalias %0) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !23
    %1 = load ptr, ptr @fmt_str_missing_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret1, ptr %ret, ptr %1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret1), !dbg !25
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr ptr @__fmt_str_impl_fmt_fail_too_many_ra.c() !dbg !26 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !27
    %0 = load ptr, ptr @fmt_str_too_many_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret1, ptr %ret, ptr %0), !dbg !28
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret1), !dbg !29
    call void @abort()
    %failwith = alloca ptr, align 8
    ret ptr undef
  }
  
  define linkonce_odr ptr @__fmt_str_print1_fmt_str_print1_a.ca.c(ptr %fmtstr, ptr %f0, ptr %v0) !dbg !30 {
  entry:
    %__fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c = alloca %closure, align 8
    store ptr @__fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, ptr %__fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, align 8
    %clsr___fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c = alloca { ptr, ptr, %closure, ptr }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %v02 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, i32 0, i32 3
    store ptr %v0, ptr %v02, align 8
    store ptr @__ctor_tp._fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, ptr %clsr___fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, i32 0, i32 1
    store ptr %clsr___fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.a.c, align 8
    call void @fmt_str_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c), !dbg !31
    %0 = getelementptr inbounds %tp.lfmt.formatter.t.a.c, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 1
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %entry
    %2 = call ptr @__fmt_str_impl_fmt_fail_too_many_ra.c(), !dbg !33
    call void @__free_fmt.formatter.t.a.c(ptr %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    %3 = call ptr @__fmt_formatter_extract_fmt.formatter.t.a.cra.c(ptr %0), !dbg !34
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %2, %then ], [ %3, %else ]
    ret ptr %iftmp
  }
  
  define linkonce_odr void @__fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !35 {
  entry:
    %v0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 3
    %v01 = load ptr, ptr %v0, align 8
    %eq = icmp eq i64 %i, 0
    br i1 %eq, label %then, label %else, !dbg !36
  
  then:                                             ; preds = %entry
    %sunkaddr = getelementptr inbounds i8, ptr %1, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr3 = getelementptr inbounds i8, ptr %1, i64 24
    %loadtmp2 = load ptr, ptr %sunkaddr3, align 8
    tail call void %loadtmp(ptr %0, ptr %fmter, ptr %v01, ptr %loadtmp2), !dbg !37
    ret void
  
  else:                                             ; preds = %entry
    tail call void @__fmt_str_impl_fmt_fail_missing_rfmt.formatter.t.a.c(ptr %0), !dbg !38
    tail call void @__free_fmt.formatter.t.a.c(ptr %fmter)
    ret void
  }
  
  define void @schmu_inner(i64 %i, ptr %0) !dbg !39 {
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
    br i1 %eq, label %then, label %else, !dbg !41
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr3 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp2 = load ptr, ptr %sunkaddr3, align 8
    tail call void %loadtmp(ptr @0, ptr %loadtmp2), !dbg !42
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(ptr %value) !dbg !43 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %value, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_a.c(ptr %1)
    %2 = load ptr, ptr %1, align 8
    %3 = alloca ptr, align 8
    store ptr %2, ptr %3, align 8
    call void @__free_a.c(ptr %3)
    ret void
  }
  
  define void @schmu_times(i64 %limit, ptr %f) !dbg !44 {
  entry:
    %schmu_inner = alloca %closure, align 8
    store ptr @schmu_inner, ptr %schmu_inner, align 8
    %clsr_schmu_inner = alloca { ptr, ptr, %closure, i64 }, align 8
    %f1 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f1, ptr align 1 %f, i64 16, i1 false)
    %limit2 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 3
    store i64 %limit, ptr %limit2, align 8
    store ptr @__ctor_tp._a.crul, ptr %clsr_schmu_inner, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %schmu_inner, i32 0, i32 1
    store ptr %clsr_schmu_inner, ptr %envptr, align 8
    call void @schmu_inner(i64 0, ptr %clsr_schmu_inner), !dbg !45
    ret void
  }
  
  define linkonce_odr void @__free__a.cp.clru(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.a.c(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free__a.cp.clru(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free__up.clru(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free__up.clru(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp._fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 2
    call void @__copy__fmt.formatter.t.a.ca.crfmt.formatter.t.a.c(ptr %f0)
    %v0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 3
    call void @__copy_a.c(ptr %v0)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy__fmt.formatter.t.a.ca.crfmt.formatter.t.a.c(ptr %0) {
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
  
  define linkonce_odr void @__copy_a.c(ptr %0) {
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
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_fmt.formatter.t.a.c(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free__a.cp.clru(ptr %1)
    %2 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %0, i32 0, i32 1
    call void @__free_a.c(ptr %2)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp._a.crul(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %1, i32 0, i32 2
    call void @__copy__a.cru(ptr %f)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__a.cru(ptr %0) {
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !46 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @schmu_test, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @schmu_times(i64 2, ptr %clstmp), !dbg !47
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "if_ret_param.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_fmt.formatter.t.uru", scope: !3, file: !3, line: 143, type: !4, scopeLine: 143, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "fmt.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 145, column: 2, scope: !2)
  !7 = !DILocation(line: 146, column: 15, scope: !2)
  !8 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_fmt.formatter.t.a.cra.c", scope: !3, file: !3, line: 28, type: !4, scopeLine: 28, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_fmt.formatter.t.uru", scope: !3, file: !3, line: 28, type: !4, scopeLine: 28, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c", scope: !3, file: !3, line: 22, type: !4, scopeLine: 22, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 24, column: 4, scope: !10)
  !12 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u", scope: !3, file: !3, line: 22, type: !4, scopeLine: 22, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 24, column: 4, scope: !12)
  !14 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_fmt.formatter.t.a.crfmt.formatter.t.a.c", scope: !3, file: !3, line: 124, type: !4, scopeLine: 124, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 125, column: 22, scope: !14)
  !16 = !DILocation(line: 125, column: 40, scope: !14)
  !17 = !DILocation(line: 125, column: 2, scope: !14)
  !18 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_fmt.formatter.t.urfmt.formatter.t.u", scope: !3, file: !3, line: 124, type: !4, scopeLine: 124, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !19 = !DILocation(line: 125, column: 22, scope: !18)
  !20 = !DILocation(line: 125, column: 40, scope: !18)
  !21 = !DILocation(line: 125, column: 2, scope: !18)
  !22 = distinct !DISubprogram(name: "_fmt_str_impl_fmt_fail_missing", linkageName: "__fmt_str_impl_fmt_fail_missing_rfmt.formatter.t.a.c", scope: !3, file: !3, line: 230, type: !4, scopeLine: 230, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 231, column: 6, scope: !22)
  !24 = !DILocation(line: 231, column: 17, scope: !22)
  !25 = !DILocation(line: 232, column: 9, scope: !22)
  !26 = distinct !DISubprogram(name: "_fmt_str_impl_fmt_fail_too_many", linkageName: "__fmt_str_impl_fmt_fail_too_many_ra.c", scope: !3, file: !3, line: 236, type: !4, scopeLine: 236, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 237, column: 6, scope: !26)
  !28 = !DILocation(line: 237, column: 17, scope: !26)
  !29 = !DILocation(line: 238, column: 9, scope: !26)
  !30 = distinct !DISubprogram(name: "_fmt_str_print1", linkageName: "__fmt_str_print1_fmt_str_print1_a.ca.c", scope: !3, file: !3, line: 314, type: !4, scopeLine: 314, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !31 = !DILocation(line: 315, column: 22, scope: !30)
  !32 = !DILocation(line: 321, column: 7, scope: !30)
  !33 = !DILocation(line: 322, column: 6, scope: !30)
  !34 = !DILocation(line: 324, column: 11, scope: !30)
  !35 = distinct !DISubprogram(name: "__fun_fmt_str2", linkageName: "__fun_fmt_str2_C__fun_fmt_str2_fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c", scope: !3, file: !3, line: 315, type: !4, scopeLine: 315, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DILocation(line: 317, column: 8, scope: !35)
  !37 = !DILocation(line: 317, column: 13, scope: !35)
  !38 = !DILocation(line: 318, column: 13, scope: !35)
  !39 = distinct !DISubprogram(name: "inner", linkageName: "schmu_inner", scope: !40, file: !40, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !40 = !DIFile(filename: "if_ret_param.smu", directory: "")
  !41 = !DILocation(line: 5, column: 7, scope: !39)
  !42 = !DILocation(line: 7, column: 6, scope: !39)
  !43 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !40, file: !40, line: 14, type: !4, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !44 = distinct !DISubprogram(name: "times", linkageName: "schmu_times", scope: !40, file: !40, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !45 = !DILocation(line: 11, column: 2, scope: !44)
  !46 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !40, file: !40, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !47 = !DILocation(line: 18, scope: !46)

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

Handle partial allocations
  $ schmu partials.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./partials
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %f.a.l = type { ptr, ptr, ptr }
  %t.a.l = type { ptr, ptr }
  %tp.a.ll = type { ptr, i64 }
  
  define ptr @schmu_inf() !dbg !2 {
  entry:
    %0 = alloca %f.a.l, align 8
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    store ptr %1, ptr %0, align 8
    %b = getelementptr inbounds %f.a.l, ptr %0, i32 0, i32 1
    %3 = tail call ptr @malloc(i64 24)
    %arr1 = alloca ptr, align 8
    store ptr %3, ptr %arr1, align 8
    store i64 1, ptr %3, align 8
    %cap3 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap3, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 10, ptr %4, align 8
    store ptr %3, ptr %b, align 8
    %c = getelementptr inbounds %f.a.l, ptr %0, i32 0, i32 2
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
    call void @__free_a.l(ptr %c)
    %.pre.pre = load ptr, ptr %0, align 8
    store ptr %.pre.pre, ptr %7, align 8
    call void @__free_a.l(ptr %7)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    %8 = load ptr, ptr %sunkaddr, align 8
    ret ptr %8
  }
  
  define void @schmu_set_moved() !dbg !6 {
  entry:
    %0 = alloca %t.a.l, align 8
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    store ptr %1, ptr %0, align 8
    %b = getelementptr inbounds %t.a.l, ptr %0, i32 0, i32 1
    %3 = tail call ptr @malloc(i64 24)
    %arr1 = alloca ptr, align 8
    store ptr %3, ptr %arr1, align 8
    store i64 1, ptr %3, align 8
    %cap3 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap3, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 20, ptr %4, align 8
    store ptr %3, ptr %b, align 8
    %5 = alloca %tp.a.ll, align 8
    %6 = load ptr, ptr %0, align 8
    store ptr %6, ptr %5, align 8
    %"1" = getelementptr inbounds %tp.a.ll, ptr %5, i32 0, i32 1
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
    call void @__free_tp.a.ll(ptr %5)
    call void @__free_t.a.l(ptr %0)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_tp.a.ll(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_a.l(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_t.a.l(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_a.l(ptr %1)
    %2 = getelementptr inbounds %t.a.l, ptr %0, i32 0, i32 1
    call void @__free_a.l(ptr %2)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    %0 = tail call ptr @schmu_inf(), !dbg !8
    tail call void @schmu_set_moved(), !dbg !9
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_a.l(ptr %1)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "partials.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "inf", linkageName: "schmu_inf", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "partials.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "set_moved", linkageName: "schmu_set_moved", scope: !3, file: !3, line: 15, type: !4, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 12, column: 7, scope: !7)
  !9 = !DILocation(line: 21, scope: !7)

Correct link order for cc flags
  $ schmu piping.smu --cc -L. --cc -lstub

Using unit values
  $ schmu unit_values.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./unit_values
  unit_values.smu:3.5-6: warning: Unused binding b.
  
  3 | let b = Some(a)
          ^
  
  unit_values.smu:8.8-9: warning: Unused binding a.
  
  8 |   Some(a) -> println("some")
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
  
  %option.t.u = type { i32 }
  %thing = type {}
  %inrec = type { i64, double }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @schmu_a = constant i8 0
  @schmu_b = constant %option.t.u { i32 1 }
  @schmu_t = constant %thing zeroinitializer
  @schmu_u = constant i8 0
  @schmu_t__3 = constant %inrec { i64 10, double 9.990000e+01 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_arr__2 = constant i8 0
  @schmu_b__2 = global %option.t.u zeroinitializer, align 4
  @schmu_t2 = global %thing zeroinitializer, align 1
  @schmu_u2 = global i8 0, align 1
  @schmu_arr = global ptr null, align 8
  @schmu_u__2 = global i8 0, align 1
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"some\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  @2 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"99.9\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_println(ptr %0)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  define linkonce_odr void @__array_fixed_swap_items_A64.c(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
  entry:
    %eq = icmp eq i64 %i, %j
    %0 = xor i1 %eq, true
    br i1 %0, label %then, label %ifcont, !dbg !6
  
  then:                                             ; preds = %entry
    %1 = alloca i8, align 1
    %2 = getelementptr i8, ptr %arr, i64 %i
    %3 = load i8, ptr %2, align 1
    store i8 %3, ptr %1, align 1
    %4 = getelementptr i8, ptr %arr, i64 %j
    %5 = load i8, ptr %4, align 1
    store i8 %5, ptr %2, align 1
    store i8 %3, ptr %4, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret void
  }
  
  define linkonce_odr void @__array_push_a.uu(ptr noalias %arr) !dbg !7 {
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
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !10 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !12
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %ret), !dbg !13
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %fm) !dbg !14 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !15 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !16
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !17 {
  entry:
    %1 = alloca [64 x i8], align 1
    store [64 x i8] zeroinitializer, ptr %1, align 1
    %lt = icmp slt i64 %base, 2
    br i1 %lt, label %cont, label %false1
  
  false1:                                           ; preds = %entry
    %gt = icmp sgt i64 %base, 36
    br i1 %gt, label %cont, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont
  
  cont:                                             ; preds = %false2, %false1, %entry
    %andtmp = phi i1 [ true, %entry ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp, label %then, label %else, !dbg !18
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !19
    br label %ifcont
  
  else:                                             ; preds = %cont
    %fmt_aux = alloca %closure, align 8
    store ptr @fmt_aux, ptr %fmt_aux, align 8
    %clsr_fmt_aux = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr, align 8
    %base1 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 3
    store i64 %base, ptr %base1, align 8
    store ptr @__ctor_tp.A64.cl, ptr %clsr_fmt_aux, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt_aux, i32 0, i32 1
    store ptr %clsr_fmt_aux, ptr %envptr, align 8
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !20
    %add = add i64 %2, 1
    %div = sdiv i64 %add, 2
    %__fun_fmt2 = alloca %closure, align 8
    store ptr @__fun_fmt2, ptr %__fun_fmt2, align 8
    %clsr___fun_fmt2 = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr5 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr5, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 3
    store i64 %add, ptr %_fmt_length, align 8
    store ptr @__ctor_tp.A64.cl, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !21
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !22
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %i) !dbg !23 {
  entry:
    tail call void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !24
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_a.ca.c(ptr %fmt, ptr %value) !dbg !25 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !26
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, ptr %value, ptr %loadtmp1), !dbg !27
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !28
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !29 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !30
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !31
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !32
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, ptr %str) !dbg !33 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !34
    %2 = tail call i64 @string_len(ptr %str), !dbg !35
    tail call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !36
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !37 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !38
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !39 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %base = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %base2 = load i64, ptr %base, align 8
    %1 = alloca i64, align 8
    store i64 %value, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 %index, ptr %2, align 8
    %3 = add i64 %index, 1
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %then ], [ %3, %entry ]
    %4 = phi i64 [ %div, %then ], [ %value, %entry ]
    %div = sdiv i64 %4, %base2
    %uglygep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %uglygep10 = getelementptr i8, ptr %uglygep9, i64 -1
    %5 = load ptr, ptr @fmt_int_digits, align 8
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !40
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !41
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !42
    br i1 %lt, label %then4, label %ifcont, !dbg !42
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_a__2() !dbg !43 {
  entry:
    ret void
  }
  
  define void @schmu_t__2(ptr noalias %0) !dbg !45 {
  entry:
    store %thing zeroinitializer, ptr %0, align 1
    ret void
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  define linkonce_odr void @__free__up.clru(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free__up.clru(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !46 {
  entry:
    store i32 1, ptr @schmu_b__2, align 4
    tail call void @schmu_a__2(), !dbg !47
    %index = load i32, ptr @schmu_b__2, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !48
  
  then:                                             ; preds = %entry
    tail call void @string_println(ptr @0), !dbg !49
    br label %ifcont
  
  else:                                             ; preds = %entry
    tail call void @string_println(ptr @1), !dbg !50
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    tail call void @schmu_t__2(ptr @schmu_t2), !dbg !51
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_a.ca.c(ptr %clstmp, ptr @2), !dbg !52
    %0 = call ptr @malloc(i64 16)
    store ptr %0, ptr @schmu_arr, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    call void @__array_push_a.uu(ptr @schmu_arr), !dbg !53
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %2 = load ptr, ptr @schmu_arr, align 8
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 %3), !dbg !54
    %4 = alloca %thing, align 8
    %5 = alloca %thing, align 8
    call void @__free_a.u(ptr @schmu_arr)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.u(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "unit_values.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64.c", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_a.uu", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 34, column: 5, scope: !7)
  !9 = !DILocation(line: 35, column: 7, scope: !7)
  !10 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_fmt.formatter.t.uru", scope: !11, file: !11, line: 143, type: !4, scopeLine: 143, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DIFile(filename: "fmt.smu", directory: "")
  !12 = !DILocation(line: 145, column: 2, scope: !10)
  !13 = !DILocation(line: 146, column: 15, scope: !10)
  !14 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_fmt.formatter.t.uru", scope: !11, file: !11, line: 28, type: !4, scopeLine: 28, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u", scope: !11, file: !11, line: 22, type: !4, scopeLine: 22, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !16 = !DILocation(line: 24, column: 4, scope: !15)
  !17 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u", scope: !11, file: !11, line: 56, type: !4, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = !DILocation(line: 58, column: 6, scope: !17)
  !19 = !DILocation(line: 59, column: 4, scope: !17)
  !20 = !DILocation(line: 76, column: 17, scope: !17)
  !21 = !DILocation(line: 79, column: 4, scope: !17)
  !22 = !DILocation(line: 83, column: 4, scope: !17)
  !23 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_fmt.formatter.t.urfmt.formatter.t.u", scope: !11, file: !11, line: 111, type: !4, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !24 = !DILocation(line: 112, column: 2, scope: !23)
  !25 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_a.ca.c", scope: !11, file: !11, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !26 = !DILocation(line: 293, column: 9, scope: !25)
  !27 = !DILocation(line: 293, column: 4, scope: !25)
  !28 = !DILocation(line: 293, column: 31, scope: !25)
  !29 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !11, file: !11, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !30 = !DILocation(line: 293, column: 9, scope: !29)
  !31 = !DILocation(line: 293, column: 4, scope: !29)
  !32 = !DILocation(line: 293, column: 31, scope: !29)
  !33 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_fmt.formatter.t.urfmt.formatter.t.u", scope: !11, file: !11, line: 124, type: !4, scopeLine: 124, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !34 = !DILocation(line: 125, column: 22, scope: !33)
  !35 = !DILocation(line: 125, column: 40, scope: !33)
  !36 = !DILocation(line: 125, column: 2, scope: !33)
  !37 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !11, file: !11, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 80, column: 6, scope: !37)
  !39 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !11, file: !11, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !40 = !DILocation(line: 65, column: 21, scope: !39)
  !41 = !DILocation(line: 66, column: 10, scope: !39)
  !42 = !DILocation(line: 69, column: 11, scope: !39)
  !43 = distinct !DISubprogram(name: "a", linkageName: "schmu_a__2", scope: !44, file: !44, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !44 = !DIFile(filename: "unit_values.smu", directory: "")
  !45 = distinct !DISubprogram(name: "t", linkageName: "schmu_t__2", scope: !44, file: !44, line: 16, type: !4, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !46 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !44, file: !44, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !47 = !DILocation(line: 6, column: 13, scope: !46)
  !48 = !DILocation(line: 8, column: 2, scope: !46)
  !49 = !DILocation(line: 8, column: 13, scope: !46)
  !50 = !DILocation(line: 9, column: 10, scope: !46)
  !51 = !DILocation(line: 17, column: 9, scope: !46)
  !52 = !DILocation(line: 23, column: 5, scope: !46)
  !53 = !DILocation(line: 27, scope: !46)
  !54 = !DILocation(line: 28, column: 5, scope: !46)
  some
  99.9
  3

Arguments
  $ schmu args.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @__schmu_argv = global ptr null
  @__schmu_argc = global i64 0
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c" \00" }
  
  declare ptr @string_concat(ptr %0, ptr %1)
  
  declare void @string_println(ptr %0)
  
  declare ptr @sys_argv()
  
  define void @schmu_nothing() !dbg !2 {
  entry:
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    store i64 %__argc, ptr @__schmu_argc, align 8
    store ptr %__argv, ptr @__schmu_argv, align 8
    tail call void @schmu_nothing(), !dbg !7
    %0 = tail call ptr @sys_argv(), !dbg !8
    %1 = tail call ptr @string_concat(ptr @0, ptr %0), !dbg !9
    tail call void @string_println(ptr %1), !dbg !10
    %2 = alloca ptr, align 8
    store ptr %1, ptr %2, align 8
    call void @__free_a.c(ptr %2)
    %3 = alloca ptr, align 8
    store ptr %0, ptr %3, align 8
    call void @__free_a.a.c(ptr %3)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.a.c(ptr %0) {
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
    call void @__free_a.c(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "args.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "nothing", linkageName: "schmu_nothing", scope: !3, file: !3, line: 2, type: !4, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "args.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 5, scope: !6)
  !8 = !DILocation(line: 6, column: 27, scope: !6)
  !9 = !DILocation(line: 6, column: 8, scope: !6)
  !10 = !DILocation(line: 6, scope: !6)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./args and other --args=2
  ./args and other --args=2

Support closures with unit types. Closures with only unit types are a special
case and don't need to be allocated.
  $ schmu unit_closures.smu
  $ valgrind ./unit_closures 2>&1 | grep allocs | cut -f 5- -d '='
     total heap usage: 2 allocs, 2 frees, 64 bytes allocated

Weak rcs
  $ schmu weak_rc.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./weak_rc

Cyclic ref counts
  $ schmu rc_cycle.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./rc_cycle

Currying in pipes
  $ schmu curry_pipe.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./curry_pipe
  a: 10 b: 12 c: 1 d: 2
  [cont] a: 10 b: 11

Codgen fixes for recursive types
  $ schmu codegen_recursive.smu

  $ schmu codegen_recursive2.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./codegen_recursive2

No unmutated warning on addr
  $ schmu --check no_unmutated_warning.smu
