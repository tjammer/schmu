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
  
  2 | external puts : (foo) -> unit
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    %boxconst = alloca %v2_, align 8
    store %v2_ { double 1.000000e+00, double 1.000000e+01 }, ptr %boxconst, align 8
    %fst1 = load double, ptr %boxconst, align 8
    %snd = getelementptr inbounds { double, double }, ptr %boxconst, i32 0, i32 1
    %snd2 = load double, ptr %snd, align 8
    %ret = alloca %v2_, align 8
    %0 = tail call { double, double } @subv2(double %fst1, double %snd2), !dbg !6
    store { double, double } %0, ptr %ret, align 8
    %boxconst3 = alloca %i2_, align 8
    store %i2_ { i64 1, i64 10 }, ptr %boxconst3, align 8
    %fst5 = load i64, ptr %boxconst3, align 8
    %snd6 = getelementptr inbounds { i64, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    %ret8 = alloca %i2_, align 8
    %1 = tail call { i64, i64 } @subi2(i64 %fst5, i64 %snd7), !dbg !7
    store { i64, i64 } %1, ptr %ret8, align 8
    %ret9 = alloca %v1_, align 8
    %2 = tail call double @subv1(double 1.000000e+00), !dbg !8
    store double %2, ptr %ret9, align 8
    %ret10 = alloca %i1_, align 8
    %3 = tail call i64 @subi1(i64 1), !dbg !9
    store i64 %3, ptr %ret10, align 8
    %boxconst11 = alloca %v3_, align 8
    store %v3_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, ptr %boxconst11, align 8
    %ret12 = alloca %v3_, align 8
    call void @subv3(ptr %ret12, ptr %boxconst11), !dbg !10
    %boxconst13 = alloca %i3_, align 8
    store %i3_ { i64 1, i64 10, i64 100 }, ptr %boxconst13, align 8
    %ret14 = alloca %i3_, align 8
    call void @subi3(ptr %ret14, ptr %boxconst13), !dbg !11
    %boxconst15 = alloca %v4_, align 8
    store %v4_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, ptr %boxconst15, align 8
    %ret16 = alloca %v4_, align 8
    call void @subv4(ptr %ret16, ptr %boxconst15), !dbg !12
    %boxconst17 = alloca %mixed4_, align 8
    store %mixed4_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, i64 1 }, ptr %boxconst17, align 8
    %ret18 = alloca %mixed4_, align 8
    call void @submixed4(ptr %ret18, ptr %boxconst17), !dbg !13
    %boxconst19 = alloca %trailv2_, align 8
    store %trailv2_ { i64 1, i64 2, double 1.000000e+00, double 2.000000e+00 }, ptr %boxconst19, align 8
    %ret20 = alloca %trailv2_, align 8
    call void @subtrailv2(ptr %ret20, ptr %boxconst19), !dbg !14
    %ret21 = alloca %f2s_, align 8
    %4 = call <2 x float> @subf2s(<2 x float> <float 2.000000e+00, float 3.000000e+00>), !dbg !15
    store <2 x float> %4, ptr %ret21, align 8
    %boxconst22 = alloca %f3s_, align 8
    store %f3s_ { float 2.000000e+00, float 3.000000e+00, float 5.000000e+00 }, ptr %boxconst22, align 4
    %fst24 = load <2 x float>, ptr %boxconst22, align 8
    %snd25 = getelementptr inbounds { <2 x float>, float }, ptr %boxconst22, i32 0, i32 1
    %snd26 = load float, ptr %snd25, align 4
    %ret27 = alloca %f3s_, align 8
    %5 = call { <2 x float>, float } @subf3s(<2 x float> %fst24, float %snd26), !dbg !16
    store { <2 x float>, float } %5, ptr %ret27, align 8
    %6 = call ptr @string_data(ptr @0), !dbg !17
    %7 = call ptr @string_data(ptr @1), !dbg !18
    %ret28 = alloca %shader_, align 8
    %8 = call { i32, i64 } @load_shader(ptr %6, ptr %7), !dbg !19
    store { i32, i64 } %8, ptr %ret28, align 8
    %9 = alloca %shader_, align 8
    store i32 0, ptr %9, align 4
    %locs = getelementptr inbounds %shader_, ptr %9, i32 0, i32 1
    store ptr null, ptr %locs, align 8
    %boxconst33 = alloca %v4_, align 8
    store %v4_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, ptr %boxconst33, align 8
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
  
  define i64 @__fun_schmu1(i32 %0, i64 %1) !dbg !6 {
  entry:
    %x = alloca { i32, i64 }, align 8
    store i32 %0, ptr %x, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %x, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else, !dbg !7
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !8 {
  entry:
    %0 = tail call i64 @__fun_schmu0(i64 1), !dbg !9
    tail call void @Printi(i64 %0), !dbg !10
    %boxconst = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %1 = tail call i64 @__fun_schmu1(i32 %fst1, i64 %snd2), !dbg !11
    tail call void @Printi(i64 %1), !dbg !12
    tail call void @Printi(i64 1), !dbg !13
    tail call void @string_println(ptr @0), !dbg !14
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
    %4 = tail call ptr @string_of_array(ptr %2), !dbg !15
    %5 = tail call i8 @string_get(ptr %4, i64 1), !dbg !16
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "piping.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !3, file: !3, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "piping.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1", scope: !3, file: !3, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 8, column: 2, scope: !6)
  !8 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 4, column: 5, scope: !8)
  !10 = !DILocation(line: 4, column: 22, scope: !8)
  !11 = !DILocation(line: 7, column: 3, scope: !8)
  !12 = !DILocation(line: 11, column: 3, scope: !8)
  !13 = !DILocation(line: 15, column: 13, scope: !8)
  !14 = !DILocation(line: 16, scope: !8)
  !15 = !DILocation(line: 18, scope: !8)
  !16 = !DILocation(line: 18, column: 36, scope: !8)
  
  2
  1
  1
  10
  b

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
    br i1 %eq, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr3 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp2 = load ptr, ptr %sunkaddr3, align 8
    tail call void %loadtmp(ptr @0, ptr %loadtmp2), !dbg !7
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(ptr %value) !dbg !8 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %value, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    call void @__free_ac_(ptr %1)
    ret void
  }
  
  define void @schmu_times(i64 %limit, ptr %f) !dbg !9 {
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
    call void @schmu_inner(i64 0, ptr %clsr_schmu_inner), !dbg !10
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @schmu_test, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @schmu_times(i64 2, ptr %clstmp), !dbg !12
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "if_ret_param.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "inner", linkageName: "schmu_inner", scope: !3, file: !3, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "if_ret_param.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 5, column: 7, scope: !2)
  !7 = !DILocation(line: 7, column: 6, scope: !2)
  !8 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !3, file: !3, line: 14, type: !4, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = distinct !DISubprogram(name: "times", linkageName: "schmu_times", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 11, column: 2, scope: !9)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 18, scope: !11)

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
  
  define void @schmu_set_moved() !dbg !6 {
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    %0 = tail call ptr @schmu_inf(), !dbg !8
    tail call void @schmu_set_moved(), !dbg !9
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_al_(ptr %1)
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
    br i1 %eq, label %then, label %ifcont5, !dbg !6
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !7
  
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
  
  define void @schmu_a__2() !dbg !8 {
  entry:
    ret void
  }
  
  define void @schmu_t__2(ptr noalias %0) !dbg !10 {
  entry:
    store %thing_ zeroinitializer, ptr %0, align 1
    ret void
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    store i32 1, ptr @schmu_b__2, align 4
    tail call void @schmu_a__2(), !dbg !12
    %index = load i32, ptr @schmu_b__2, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !13
  
  then:                                             ; preds = %entry
    tail call void @string_println(ptr @0), !dbg !14
    br label %ifcont
  
  else:                                             ; preds = %entry
    tail call void @string_println(ptr @1), !dbg !15
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    tail call void @schmu_t__2(ptr @schmu_t2), !dbg !16
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @2, i64 16), double 9.990000e+01)
    %0 = tail call ptr @malloc(i64 16)
    store ptr %0, ptr @schmu_arr, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    tail call void @__array_push_au_u_(ptr @schmu_arr), !dbg !17
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "unit_values.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_au_u_", scope: !3, file: !3, line: 29, type: !4, scopeLine: 29, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 33, column: 5, scope: !2)
  !7 = !DILocation(line: 34, column: 7, scope: !2)
  !8 = distinct !DISubprogram(name: "a", linkageName: "schmu_a__2", scope: !9, file: !9, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DIFile(filename: "unit_values.smu", directory: "")
  !10 = distinct !DISubprogram(name: "t", linkageName: "schmu_t__2", scope: !9, file: !9, line: 16, type: !4, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !9, file: !9, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 6, column: 13, scope: !11)
  !13 = !DILocation(line: 8, column: 2, scope: !11)
  !14 = !DILocation(line: 8, column: 11, scope: !11)
  !15 = !DILocation(line: 9, column: 8, scope: !11)
  !16 = !DILocation(line: 17, column: 9, scope: !11)
  !17 = !DILocation(line: 27, scope: !11)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    store i64 %__argc, ptr @__schmu_argc, align 8
    store ptr %__argv, ptr @__schmu_argv, align 8
    %0 = tail call ptr @sys_argv(), !dbg !6
    %1 = tail call ptr @string_concat(ptr @0, ptr %0), !dbg !7
    tail call void @string_println(ptr %1), !dbg !8
    %2 = alloca ptr, align 8
    store ptr %1, ptr %2, align 8
    call void @__free_ac_(ptr %2)
    %3 = alloca ptr, align 8
    store ptr %0, ptr %3, align 8
    call void @__free_2ac2_(ptr %3)
    ret i64 0
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
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "args.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "args.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 1, column: 27, scope: !2)
  !7 = !DILocation(line: 1, column: 8, scope: !2)
  !8 = !DILocation(line: 1, scope: !2)
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
