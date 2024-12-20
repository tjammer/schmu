Simplest module with 1 type and 1 nonpolymorphic function
  $ schmu nonpoly_func.smu -m --dump-llvm
  nonpoly_func.smu:4.7-8: warning: Unused binding c.
  
  4 |   let c = 10
            ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @nonpoly_func_c = internal constant i64 10
  
  define i64 @nonpoly_func_add_ints(i64 %a, i64 %b) !dbg !2 {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "nonpoly_func.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "add_ints", linkageName: "nonpoly_func_add_ints", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "nonpoly_func.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  $ cat nonpoly_func.smi | sed -E 's/([0-9]+:\/.*lib\/schmu\/std)//'
  (()((5:Mtype(((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:0))((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum2:26)))6:either((6:params())(4:kind(8:Dvariant((12:is_recursive5:false)(8:has_base4:true)(17:params_behind_ptr5:false))(((5:cname4:left)(4:ctyp())(5:index1:0))((5:cname5:right)(4:ctyp())(5:index1:1)))))(6:in_sgn5:false)))(4:Mfun(((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:28)(8:pos_cnum2:32))((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:6)(7:pos_bol2:70)(8:pos_cnum2:71)))(4:Tfun(((2:pt(7:Tconstr3:int()))(5:pattr5:Dnorm))((2:pt(7:Tconstr3:int()))(5:pattr5:Dnorm)))(7:Tconstr3:int())6:Simple)((4:user8:add_ints)(4:call((8:add_ints(12:nonpoly_func)()))))))((/std/string5:false)))

  $ schmu import_nonpoly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  declare i64 @nonpoly_func_add_ints(i64 %0, i64 %1)
  
  define i64 @schmu_doo(i32 %0) !dbg !2 {
  entry:
    %a = alloca i32, align 4
    store i32 %0, ptr %a, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5), !dbg !7
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5), !dbg !8
    ret i64 %2
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %0 = tail call i64 @schmu_doo(i32 0), !dbg !10
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "import_nonpoly_func.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "doo", linkageName: "schmu_doo", scope: !3, file: !3, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "import_nonpoly_func.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 6, column: 3, scope: !2)
  !7 = !DILocation(line: 6, column: 9, scope: !2)
  !8 = !DILocation(line: 7, column: 10, scope: !2)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 10, scope: !9)
  $ ./import_nonpoly_func
  5

  $ schmu local_import_nonpoly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  declare i64 @nonpoly_func_add_ints(i64 %0, i64 %1)
  
  define i64 @schmu_do2(i32 %0) !dbg !2 {
  entry:
    %a = alloca i32, align 4
    store i32 %0, ptr %a, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5), !dbg !7
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5), !dbg !8
    ret i64 %2
  }
  
  define i64 @schmu_doo(i32 %0) !dbg !9 {
  entry:
    %a = alloca i32, align 4
    store i32 %0, ptr %a, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else, !dbg !10
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5), !dbg !11
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5), !dbg !12
    ret i64 %2
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !13 {
  entry:
    %0 = tail call i64 @schmu_doo(i32 0), !dbg !14
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %1 = tail call i64 @schmu_do2(i32 0), !dbg !15
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "local_import_nonpoly_func.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "do2", linkageName: "schmu_do2", scope: !3, file: !3, line: 10, type: !4, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "local_import_nonpoly_func.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 13, column: 4, scope: !2)
  !7 = !DILocation(line: 13, column: 10, scope: !2)
  !8 = !DILocation(line: 14, column: 11, scope: !2)
  !9 = distinct !DISubprogram(name: "doo", linkageName: "schmu_doo", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 6, column: 4, scope: !9)
  !11 = !DILocation(line: 6, column: 10, scope: !9)
  !12 = !DILocation(line: 7, column: 11, scope: !9)
  !13 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = !DILocation(line: 17, scope: !13)
  !15 = !DILocation(line: 18, scope: !13)
  $ ./local_import_nonpoly_func
  5
  5

  $ schmu lets.smu -m --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @lets_a = constant i64 12
  @lets_a__2 = constant i64 11
  @lets_b = global i64 0, align 8
  @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__lets_init, ptr null }]
  
  define i64 @lets_generate_b() !dbg !2 {
  entry:
    ret i64 21
  }
  
  define internal void @__lets_init() section ".text.startup" !dbg !6 {
  entry:
    %0 = tail call i64 @lets_generate_b(), !dbg !7
    store i64 %0, ptr @lets_b, align 8
    ret void
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "lets.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "generate_b", linkageName: "lets_generate_b", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "lets.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "__lets_init", linkageName: "__lets_init", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 7, column: 8, scope: !6)

  $ schmu import_lets.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @lets_b = external global i64
  @lets_a__2 = external global i64
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare void @printf(ptr %0, i64 %1)
  
  define void @schmu_inside_fn() !dbg !2 {
  entry:
    tail call void @schmu_second(), !dbg !6
    ret void
  }
  
  define void @schmu_second() !dbg !7 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !8
    %1 = load i64, ptr @lets_a__2, align 8
    tail call void @printf(ptr %0, i64 %1), !dbg !9
    %2 = tail call ptr @string_data(ptr @0), !dbg !10
    %3 = load i64, ptr @lets_b, align 8
    tail call void @printf(ptr %2, i64 %3), !dbg !11
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !12 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !13
    %1 = load i64, ptr @lets_a__2, align 8
    tail call void @printf(ptr %0, i64 %1), !dbg !14
    %2 = tail call ptr @string_data(ptr @0), !dbg !15
    %3 = load i64, ptr @lets_b, align 8
    tail call void @printf(ptr %2, i64 %3), !dbg !16
    tail call void @schmu_inside_fn(), !dbg !17
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "import_lets.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "inside_fn", linkageName: "schmu_inside_fn", scope: !3, file: !3, line: 8, type: !4, scopeLine: 8, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "import_lets.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 14, column: 2, scope: !2)
  !7 = distinct !DISubprogram(name: "second", linkageName: "schmu_second", scope: !3, file: !3, line: 10, type: !4, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 11, column: 11, scope: !7)
  !9 = !DILocation(line: 11, column: 4, scope: !7)
  !10 = !DILocation(line: 12, column: 11, scope: !7)
  !11 = !DILocation(line: 12, column: 4, scope: !7)
  !12 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 5, column: 7, scope: !12)
  !14 = !DILocation(line: 5, scope: !12)
  !15 = !DILocation(line: 6, column: 7, scope: !12)
  !16 = !DILocation(line: 6, scope: !12)
  !17 = !DILocation(line: 16, scope: !12)
  $ ./import_lets
  11
  21
  11
  21

  $ schmu local_import_lets.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @lets_b = external global i64
  @lets_a__2 = external global i64
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare void @printf(ptr %0, i64 %1)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !6
    %1 = load i64, ptr @lets_a__2, align 8
    tail call void @printf(ptr %0, i64 %1), !dbg !7
    %2 = tail call ptr @string_data(ptr @0), !dbg !8
    %3 = load i64, ptr @lets_b, align 8
    tail call void @printf(ptr %2, i64 %3), !dbg !9
    %4 = tail call ptr @string_data(ptr @0), !dbg !10
    %5 = load i64, ptr @lets_a__2, align 8
    tail call void @printf(ptr %4, i64 %5), !dbg !11
    %6 = tail call ptr @string_data(ptr @0), !dbg !12
    %7 = load i64, ptr @lets_b, align 8
    tail call void @printf(ptr %6, i64 %7), !dbg !13
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "local_import_lets.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "local_import_lets.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 3, column: 12, scope: !2)
  !7 = !DILocation(line: 3, scope: !2)
  !8 = !DILocation(line: 4, column: 13, scope: !2)
  !9 = !DILocation(line: 4, column: 6, scope: !2)
  !10 = !DILocation(line: 6, column: 9, scope: !2)
  !11 = !DILocation(line: 6, column: 2, scope: !2)
  !12 = !DILocation(line: 7, column: 9, scope: !2)
  !13 = !DILocation(line: 7, column: 2, scope: !2)
  $ ./local_import_lets
  11
  21
  11
  21

  $ schmu -m --dump-llvm poly_func.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "poly_func.smu", directory: "$TESTCASE_ROOT")

  $ schmu import_poly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %poly_func.optiond_ = type { i32, double }
  %poly_func.optionl_ = type { i32, i64 }
  
  @schmu_none = constant %poly_func.optiond_ { i32 1, double undef }
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define linkonce_odr i64 @__poly_func_classify_vd__(i32 %0, double %1) !dbg !2 {
  entry:
    %thing = alloca { i32, double }, align 8
    store i32 %0, ptr %thing, align 4
    %snd = getelementptr inbounds { i32, double }, ptr %thing, i32 0, i32 1
    store double %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !6
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @__poly_func_classify_vl__(i32 %0, i64 %1) !dbg !7 {
  entry:
    %thing = alloca { i32, i64 }, align 8
    store i32 %0, ptr %thing, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %thing, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !8
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %boxconst = alloca %poly_func.optionl_, align 8
    store %poly_func.optionl_ { i32 0, i64 3 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %0 = tail call i64 @__poly_func_classify_vl__(i32 %fst1, i64 %snd2), !dbg !11
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %boxconst3 = alloca %poly_func.optiond_, align 8
    store %poly_func.optiond_ { i32 0, double 3.000000e+00 }, ptr %boxconst3, align 8
    %fst5 = load i32, ptr %boxconst3, align 4
    %snd6 = getelementptr inbounds { i32, double }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load double, ptr %snd6, align 8
    %1 = tail call i64 @__poly_func_classify_vd__(i32 %fst5, double %snd7), !dbg !12
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    %2 = tail call i64 @__poly_func_classify_vd__(i32 1, double undef), !dbg !13
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %2)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "import_poly_func.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_poly_func_classify", linkageName: "__poly_func_classify_vd__", scope: !3, file: !3, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "poly_func.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 6, column: 4, scope: !2)
  !7 = distinct !DISubprogram(name: "_poly_func_classify", linkageName: "__poly_func_classify_vl__", scope: !3, file: !3, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 6, column: 4, scope: !7)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !10, file: !10, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DIFile(filename: "import_poly_func.smu", directory: "")
  !11 = !DILocation(line: 5, scope: !9)
  !12 = !DILocation(line: 6, scope: !9)
  !13 = !DILocation(line: 8, scope: !9)
  $ ./import_poly_func
  0
  0
  1

  $ schmu local_import_poly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %poly_func.optiond_ = type { i32, double }
  %poly_func.optionl_ = type { i32, i64 }
  
  @schmu_none = constant %poly_func.optiond_ { i32 1, double undef }
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define linkonce_odr i64 @__poly_func_classify_vd__(i32 %0, double %1) !dbg !2 {
  entry:
    %thing = alloca { i32, double }, align 8
    store i32 %0, ptr %thing, align 4
    %snd = getelementptr inbounds { i32, double }, ptr %thing, i32 0, i32 1
    store double %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !6
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @__poly_func_classify_vl__(i32 %0, i64 %1) !dbg !7 {
  entry:
    %thing = alloca { i32, i64 }, align 8
    store i32 %0, ptr %thing, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %thing, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !8
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %boxconst = alloca %poly_func.optionl_, align 8
    store %poly_func.optionl_ { i32 0, i64 3 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %0 = tail call i64 @__poly_func_classify_vl__(i32 %fst1, i64 %snd2), !dbg !11
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %boxconst3 = alloca %poly_func.optiond_, align 8
    store %poly_func.optiond_ { i32 0, double 3.000000e+00 }, ptr %boxconst3, align 8
    %fst5 = load i32, ptr %boxconst3, align 4
    %snd6 = getelementptr inbounds { i32, double }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load double, ptr %snd6, align 8
    %1 = tail call i64 @__poly_func_classify_vd__(i32 %fst5, double %snd7), !dbg !12
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    %2 = tail call i64 @__poly_func_classify_vd__(i32 1, double undef), !dbg !13
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %2)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "local_import_poly_func.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_poly_func_classify", linkageName: "__poly_func_classify_vd__", scope: !3, file: !3, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "poly_func.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 6, column: 4, scope: !2)
  !7 = distinct !DISubprogram(name: "_poly_func_classify", linkageName: "__poly_func_classify_vl__", scope: !3, file: !3, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 6, column: 4, scope: !7)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !10, file: !10, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DIFile(filename: "local_import_poly_func.smu", directory: "")
  !11 = !DILocation(line: 3, scope: !9)
  !12 = !DILocation(line: 4, scope: !9)
  !13 = !DILocation(line: 6, column: 11, scope: !9)
  $ ./local_import_poly_func
  0
  0
  1

  $ schmu -m malloc_some.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @malloc_some_a = constant i64 12
  @malloc_some_b = global i64 0, align 8
  @malloc_some_vtest = global ptr null, align 8
  @malloc_some_vtest2 = global ptr null, align 8
  @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__malloc_some_init, ptr null }]
  @llvm.global_dtors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__malloc_some_deinit, ptr null }]
  
  define i64 @malloc_some_add_ints(i64 %a, i64 %b) !dbg !2 {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define internal void @__malloc_some_init() section ".text.startup" !dbg !6 {
  entry:
    %0 = tail call i64 @malloc_some_add_ints(i64 1, i64 3), !dbg !7
    store i64 %0, ptr @malloc_some_b, align 8
    %1 = tail call ptr @malloc(i64 32)
    store ptr %1, ptr @malloc_some_vtest, align 8
    store i64 2, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 0, ptr %2, align 8
    %"1" = getelementptr i64, ptr %2, i64 1
    store i64 1, ptr %"1", align 8
    %3 = tail call ptr @malloc(i64 24)
    store ptr %3, ptr @malloc_some_vtest2, align 8
    store i64 1, ptr %3, align 8
    %cap2 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap2, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 3, ptr %4, align 8
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define internal void @__malloc_some_deinit() section ".text.startup" !dbg !8 {
  entry:
    tail call void @__free_al_(ptr @malloc_some_vtest2)
    tail call void @__free_al_(ptr @malloc_some_vtest)
    ret void
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "malloc_some.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "add_ints", linkageName: "malloc_some_add_ints", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "malloc_some.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "__malloc_some_init", linkageName: "__malloc_some_init", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 7, column: 8, scope: !6)
  !8 = distinct !DISubprogram(name: "__malloc_some_deinit", linkageName: "__malloc_some_deinit", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)

  $ cat malloc_some.smi | sed -E 's/([0-9]+:\/.*lib\/schmu\/std)//'
  (()((5:Mtype(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:0))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum2:29)))6:either((6:params())(4:kind(8:Dvariant((12:is_recursive5:false)(8:has_base4:true)(17:params_behind_ptr5:false))(((5:cname4:left)(4:ctyp())(5:index1:4))((5:cname5:right)(4:ctyp())(5:index1:5)))))(6:in_sgn5:false)))(4:Mfun(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:3)(7:pos_bol2:31)(8:pos_cnum2:35))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:3)(7:pos_bol2:31)(8:pos_cnum2:57)))(4:Tfun(((2:pt(7:Tconstr3:int()))(5:pattr5:Dnorm))((2:pt(7:Tconstr3:int()))(5:pattr5:Dnorm)))(7:Tconstr3:int())6:Simple)((4:user8:add_ints)(4:call((8:add_ints(11:malloc_some)())))))(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:5)(7:pos_bol2:59)(8:pos_cnum2:59))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:5)(7:pos_bol2:59)(8:pos_cnum2:69)))(7:Tconstr3:int())((4:user1:a)(4:call((1:a(11:malloc_some)()))))5:false)(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:7)(7:pos_bol2:71)(8:pos_cnum2:71))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:7)(7:pos_bol2:71)(8:pos_cnum2:93)))(7:Tconstr3:int())((4:user1:b)(4:call((1:b(11:malloc_some)()))))5:false)(9:Mpoly_fun(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum2:99))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:114)))((7:nparams(1:x))(4:body((3:typ(4:Qvar1:1))(4:expr(4:Move((3:typ(4:Qvar1:1))(4:expr(3:App(6:callee((3:typ(4:Tfun(((2:pt(4:Qvar1:1))(5:pattr5:Dnorm)))(4:Qvar1:1)6:Simple))(4:expr(3:Var4:copy()))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:106))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:110))))))(4:args((((3:typ(4:Qvar1:1))(4:expr(3:Var1:x()))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:111))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:112)))))5:Dnorm)))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:106))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:113)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:106))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:113))))))(4:func((7:tparams(((2:pt(4:Qvar1:1))(5:pattr5:Dnorm))))(3:ret(4:Qvar1:1))(4:kind6:Simple)(7:touched())))(6:inline5:false)(6:is_rec5:false))2:id())(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:11)(7:pos_bol3:116)(8:pos_cnum3:116))((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:11)(7:pos_bol3:116)(8:pos_cnum3:134)))(7:Tconstr5:array((7:Tconstr3:int())))((4:user5:vtest)(4:call((5:vtest(11:malloc_some)()))))5:false)(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:12)(7:pos_bol3:135)(8:pos_cnum3:135))((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:12)(7:pos_bol3:135)(8:pos_cnum3:151)))(7:Tconstr5:array((7:Tconstr3:int())))((4:user6:vtest2)(4:call((6:vtest2(11:malloc_some)()))))5:false))((/std/string5:false)))

  $ schmu use_malloc_some.smu --dump-llvm
  use_malloc_some.smu:5.5-17: warning: Unused binding do_something.
  
  5 | fun do_something(big) {
          ^^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @malloc_some_vtest = external global ptr
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare void @printf(ptr %0, i64 %1)
  
  define linkonce_odr void @__array_inner__2_Cal_lru__(i64 %i, ptr %0) !dbg !2 {
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
    br i1 %eq, label %then, label %else, !dbg !6
  
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
    tail call void %loadtmp(i64 %6, ptr %loadtmp2), !dbg !7
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr void @__array_iter_al_lru__(ptr %arr, ptr %f) !dbg !8 {
  entry:
    %__array_inner__2_Cal_lru__ = alloca %closure, align 8
    store ptr @__array_inner__2_Cal_lru__, ptr %__array_inner__2_Cal_lru__, align 8
    %clsr___array_inner__2_Cal_lru__ = alloca { ptr, ptr, ptr, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_lru__, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %f2 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_lru__, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f2, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_al_lru2_, ptr %clsr___array_inner__2_Cal_lru__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_lru__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__array_inner__2_Cal_lru__, i32 0, i32 1
    store ptr %clsr___array_inner__2_Cal_lru__, ptr %envptr, align 8
    call void @__array_inner__2_Cal_lru__(i64 0, ptr %clsr___array_inner__2_Cal_lru__), !dbg !9
    ret void
  }
  
  define i64 @schmu_do_something(ptr %big) !dbg !10 {
  entry:
    %0 = load i64, ptr %big, align 8
    %add = add i64 %0, 1
    ret i64 %add
  }
  
  define void @schmu_printi(i64 %i) !dbg !12 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !13
    tail call void @printf(ptr %0, i64 %i), !dbg !14
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !15 {
  entry:
    %0 = load ptr, ptr @malloc_some_vtest, align 8
    %clstmp = alloca %closure, align 8
    store ptr @schmu_printi, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__array_iter_al_lru__(ptr %0, ptr %clstmp), !dbg !16
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "use_malloc_some.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_inner", linkageName: "__array_inner__2_Cal_lru__", scope: !3, file: !3, line: 47, type: !4, scopeLine: 47, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 48, column: 7, scope: !2)
  !7 = !DILocation(line: 51, column: 6, scope: !2)
  !8 = distinct !DISubprogram(name: "_array_iter", linkageName: "__array_iter_al_lru__", scope: !3, file: !3, line: 46, type: !4, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 56, column: 2, scope: !8)
  !10 = distinct !DISubprogram(name: "do_something", linkageName: "schmu_do_something", scope: !11, file: !11, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DIFile(filename: "use_malloc_some.smu", directory: "")
  !12 = distinct !DISubprogram(name: "printi", linkageName: "schmu_printi", scope: !11, file: !11, line: 10, type: !4, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 11, column: 9, scope: !12)
  !14 = !DILocation(line: 11, column: 2, scope: !12)
  !15 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !11, file: !11, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !16 = !DILocation(line: 13, scope: !15)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./use_malloc_some
  0
  1

Allocate and clean init code with refcounting
  $ schmu init.smu -m
  $ schmu use_init.smu
  use_init.smu:3.5-9: warning: Unused module 'use' declaration init.
  
  3 | use init
          ^^^^
  
  $ ./use_init
  hello from init

Use module name prefix for function names to prevent linker dups
  $ schmu nameclash_mod.smu -m
  $ schmu nameclash_use.smu
  nameclash_use.smu:3.5-18: warning: Unused module 'use' declaration nameclash_mod.
  
  3 | use nameclash_mod
          ^^^^^^^^^^^^^
  
  nameclash_use.smu:4.5-18: warning: Unused binding specific_name.
  
  4 | fun specific_name(): ()
          ^^^^^^^^^^^^^
  
Distinguish closures and functions
  $ schmu decl_lambda.smu -m
  $ schmu use_lambda.smu
  $ ./use_lambda


Test signature
  $ schmu -m sign.smu
  sign.smu:22.5-11: warning: Unused binding hidden.
  
  22 | fun hidden(a) {
           ^^^^^^
  
  $ schmu use-sign.smu
  use-sign.smu:21.5-15: warning: Unused binding use_hidden.
  
  21 | fun use_hidden () {
           ^^^^^^^^^^
  
  $ ./use-sign
  hello 20
  200
  20.2
  $ schmu use-sign-hidden.smu
  use-sign-hidden.smu:6.1-7: error: No var named hidden.
  
  6 | hidden(10)
      ^^^^^^
  
  [1]
  $ schmu use-sign-hidden-type.smu
  use-sign-hidden-type.smu:5.9-20: error: Unbound type hidden_type..
  
  5 | let i : hidden_type = 10
              ^^^^^^^^^^^
  
  [1]

Polymorphic lambdas in modules
  $ schmu -m poly_lambda.smu
  $ schmu use_poly_lambda.smu


Local modules
  $ schmu --dump-llvm local_module.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %nosig.t_ = type { i64 }
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"test\00" }
  @schmu_local_value = constant ptr @0
  @schmu_test__2 = constant %nosig.t_ { i64 10 }
  @1 = private unnamed_addr constant { i64, i64, [13 x i8] } { i64 12, i64 12, [13 x i8] c"hey poly %s\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"hey thing\00" }
  @3 = private unnamed_addr constant { i64, i64, [11 x i8] } { i64 10, i64 10, [11 x i8] c"i'm nested\00" }
  @4 = private unnamed_addr constant { i64, i64, [9 x i8] } { i64 8, i64 8, [9 x i8] c"hey test\00" }
  
  declare void @string_println(ptr %0)
  
  define linkonce_odr void @__schmu_local_poly_test_ac__(ptr %a) !dbg !2 {
  entry:
    %0 = getelementptr i8, ptr %a, i64 16
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @1, i64 16), ptr %0)
    ret void
  }
  
  define void @schmu_local_test() !dbg !6 {
  entry:
    tail call void @string_println(ptr @2), !dbg !7
    ret void
  }
  
  define void @schmu_nosig_nested_nested() !dbg !8 {
  entry:
    tail call void @string_println(ptr @3), !dbg !9
    ret void
  }
  
  define void @schmu_test() !dbg !10 {
  entry:
    tail call void @string_println(ptr @4), !dbg !11
    ret void
  }
  
  declare void @printf(ptr %0, ...)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !12 {
  entry:
    tail call void @schmu_test(), !dbg !13
    tail call void @schmu_local_test(), !dbg !14
    tail call void @__schmu_local_poly_test_ac__(ptr @0), !dbg !15
    tail call void @schmu_nosig_nested_nested(), !dbg !16
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "local_module.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_schmu_local_poly_test", linkageName: "__schmu_local_poly_test_ac__", scope: !3, file: !3, line: 17, type: !4, scopeLine: 17, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "local_module.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "_schmu_local_test", linkageName: "schmu_local_test", scope: !3, file: !3, line: 14, type: !4, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 15, column: 4, scope: !6)
  !8 = distinct !DISubprogram(name: "_schmu_nosig_nested_nested", linkageName: "schmu_nosig_nested_nested", scope: !3, file: !3, line: 32, type: !4, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 33, column: 6, scope: !8)
  !10 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 1, column: 12, scope: !10)
  !12 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 23, scope: !12)
  !14 = !DILocation(line: 25, scope: !12)
  !15 = !DILocation(line: 26, scope: !12)
  !16 = !DILocation(line: 40, scope: !12)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./local_module
  hey test
  hey thing
  hey poly test
  i'm nested

Fix shadowing for local modules
  $ schmu local_module_shadowing.smu
  $ ./local_module_shadowing
  i'm in a module
  a
  10
  a
  a
  10

Prefix type names in nested polymorphic functions
  $ schmu -m nested_fn.smu
  $ schmu use_nested_fn.smu

Use local module from other file
  $ schmu -m local_otherfile.smu
  $ schmu use_local_otherfile.smu
  $ ./use_local_otherfile
  hey test
  hey thing
  hey poly test
  i'm nested
  hey test
  hey thing
  hey poly test
  i'm nested
  i'm nested


Local modules can shadow types. Use unique type names in codegen
  $ schmu local_module_type_shadowing.smu --dump-llvm
  local_module_type_shadowing.smu:5.5-6: warning: Unused binding t.
  
  5 | let t = {a = 10}
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t_ = type { i64 }
  %nosig.t_ = type { i64, i64 }
  %nosig.nested.t_ = type { i64, i64, i64 }
  
  @schmu_t = constant %t_ { i64 10 }
  @schmu_nosig_t = constant %nosig.t_ { i64 10, i64 20 }
  @schmu_nosig_nested_t = constant %nosig.nested.t_ { i64 10, i64 20, i64 30 }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "local_module_type_shadowing.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "local_module_type_shadowing.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}

Search for modules when variables cannot be found
  $ schmu err_local_otherfile.smu
  err_local_otherfile.smu:3.1-24: error: No var named local_otherfile/aliased, but a module with the name exists.
  
  3 | local_otherfile/aliased
      ^^^^^^^^^^^^^^^^^^^^^^^
  
  [1]

Use directory as module
  $ cd modd
  $ schmu -m hidden.smu
  $ schmu -m indirect.smu
  $ schmu -m public.smu
  $ schmu -m modd.smu
  $ cd ..
  $ schmu consume_dir.smu
  $ ./consume_dir
  modd
  indirect
  public
  lol
  lol
  hello
  world

  $ printf "import indirect\nprintln(indirect/a)" > err.smu
  $ schmu err.smu
  err.smu:1.8-16: error: Cannot find module: indirect.
  
  1 | import indirect
             ^^^^^^^^
  
  [1]

Transitive polymorphic dependency needs to be available
  $ schmu -m transitive.smu
  $ schmu -m direct_dep.smu
  $ schmu use_dep.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr i64 @__direct_dep_id_lrl_(i64 %a) !dbg !2 {
  entry:
    %0 = tail call i64 @__transitive_id_lrl_(i64 %a), !dbg !6
    ret i64 %0
  }
  
  define linkonce_odr i64 @__transitive_id_lrl_(i64 %a) !dbg !7 {
  entry:
    ret i64 %a
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %0 = tail call i64 @__direct_dep_id_lrl_(i64 10), !dbg !11
    ret i64 %0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "use_dep.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_direct_dep_id", linkageName: "__direct_dep_id_lrl_", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "direct_dep.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 3, column: 12, scope: !2)
  !7 = distinct !DISubprogram(name: "_transitive_id", linkageName: "__transitive_id_lrl_", scope: !8, file: !8, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DIFile(filename: "transitive.smu", directory: "")
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !10, file: !10, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DIFile(filename: "use_dep.smu", directory: "")
  !11 = !DILocation(line: 3, scope: !9)

Apply local functors
  $ schmu --dump-llvm local_functor.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %outer.t_ = type { i64 }
  %somerec.t_ = type { i64, i64 }
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"%.9g\0A\00" }
  
  define double @schmu_floata_add(double %a, double %b) !dbg !2 {
  entry:
    %add = fadd double %a, %b
    ret double %add
  }
  
  define double @schmu_floatadder_add_twice(double %a, double %b) !dbg !6 {
  entry:
    %0 = tail call double @schmu_floata_add(double %a, double %b), !dbg !7
    %1 = tail call double @schmu_floata_add(double %0, double %b), !dbg !8
    ret double %1
  }
  
  define i64 @schmu_inta_add(i64 %a, i64 %b) !dbg !9 {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define i64 @schmu_intadder_add_twice(i64 %a, i64 %b) !dbg !10 {
  entry:
    %0 = tail call i64 @schmu_inta_add(i64 %a, i64 %b), !dbg !11
    %1 = tail call i64 @schmu_inta_add(i64 %0, i64 %b), !dbg !12
    ret i64 %1
  }
  
  define i64 @schmu_outa_add(i64 %0, i64 %1) !dbg !13 {
  entry:
    %a = alloca i64, align 8
    store i64 %0, ptr %a, align 8
    %b = alloca i64, align 8
    store i64 %1, ptr %b, align 8
    %2 = alloca %outer.t_, align 8
    %add = add i64 %0, %1
    store i64 %add, ptr %2, align 8
    ret i64 %add
  }
  
  define i64 @schmu_outeradder_add_twice(i64 %0, i64 %1) !dbg !14 {
  entry:
    %a = alloca i64, align 8
    store i64 %0, ptr %a, align 8
    %b = alloca i64, align 8
    store i64 %1, ptr %b, align 8
    %ret = alloca %outer.t_, align 8
    %2 = tail call i64 @schmu_outa_add(i64 %0, i64 %1), !dbg !15
    store i64 %2, ptr %ret, align 8
    %ret4 = alloca %outer.t_, align 8
    %3 = tail call i64 @schmu_outa_add(i64 %2, i64 %1), !dbg !16
    store i64 %3, ptr %ret4, align 8
    ret i64 %3
  }
  
  define { i64, i64 } @schmu_recadder_add_twice(i64 %0, i64 %1, i64 %2, i64 %3) !dbg !17 {
  entry:
    %a = alloca { i64, i64 }, align 8
    store i64 %0, ptr %a, align 8
    %snd = getelementptr inbounds { i64, i64 }, ptr %a, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %b = alloca { i64, i64 }, align 8
    store i64 %2, ptr %b, align 8
    %snd2 = getelementptr inbounds { i64, i64 }, ptr %b, i32 0, i32 1
    store i64 %3, ptr %snd2, align 8
    %ret = alloca %somerec.t_, align 8
    %4 = tail call { i64, i64 } @schmu_somerec_add(i64 %0, i64 %1, i64 %2, i64 %3), !dbg !18
    store { i64, i64 } %4, ptr %ret, align 8
    %fst12 = load i64, ptr %ret, align 8
    %snd13 = getelementptr inbounds { i64, i64 }, ptr %ret, i32 0, i32 1
    %snd14 = load i64, ptr %snd13, align 8
    %ret19 = alloca %somerec.t_, align 8
    %5 = tail call { i64, i64 } @schmu_somerec_add(i64 %fst12, i64 %snd14, i64 %2, i64 %3), !dbg !19
    store { i64, i64 } %5, ptr %ret19, align 8
    ret { i64, i64 } %5
  }
  
  define { i64, i64 } @schmu_somerec_add(i64 %0, i64 %1, i64 %2, i64 %3) !dbg !20 {
  entry:
    %a = alloca { i64, i64 }, align 8
    store i64 %0, ptr %a, align 8
    %snd = getelementptr inbounds { i64, i64 }, ptr %a, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %b = alloca { i64, i64 }, align 8
    store i64 %2, ptr %b, align 8
    %snd2 = getelementptr inbounds { i64, i64 }, ptr %b, i32 0, i32 1
    store i64 %3, ptr %snd2, align 8
    %4 = alloca %somerec.t_, align 8
    %add = add i64 %0, %2
    store i64 %add, ptr %4, align 8
    %b4 = getelementptr inbounds %somerec.t_, ptr %4, i32 0, i32 1
    %add5 = add i64 %1, %3
    store i64 %add5, ptr %b4, align 8
    %unbox = load { i64, i64 }, ptr %4, align 8
    ret { i64, i64 } %unbox
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !21 {
  entry:
    %0 = tail call i64 @schmu_intadder_add_twice(i64 1, i64 2), !dbg !22
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %1 = tail call double @schmu_floatadder_add_twice(double 1.000000e+00, double 2.000000e+00), !dbg !23
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @1, i64 16), double %1)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "local_functor.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_schmu_floata_add", linkageName: "schmu_floata_add", scope: !3, file: !3, line: 24, type: !4, scopeLine: 24, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "local_functor.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "_schmu_floatadder_add_twice", linkageName: "schmu_floatadder_add_twice", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 9, column: 29, scope: !6)
  !8 = !DILocation(line: 9, column: 23, scope: !6)
  !9 = distinct !DISubprogram(name: "_schmu_inta_add", linkageName: "schmu_inta_add", scope: !3, file: !3, line: 17, type: !4, scopeLine: 17, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = distinct !DISubprogram(name: "_schmu_intadder_add_twice", linkageName: "schmu_intadder_add_twice", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 9, column: 29, scope: !10)
  !12 = !DILocation(line: 9, column: 23, scope: !10)
  !13 = distinct !DISubprogram(name: "_schmu_outa_add", linkageName: "schmu_outa_add", scope: !3, file: !3, line: 13, type: !4, scopeLine: 13, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = distinct !DISubprogram(name: "_schmu_outeradder_add_twice", linkageName: "schmu_outeradder_add_twice", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 9, column: 29, scope: !14)
  !16 = !DILocation(line: 9, column: 23, scope: !14)
  !17 = distinct !DISubprogram(name: "_schmu_recadder_add_twice", linkageName: "schmu_recadder_add_twice", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = !DILocation(line: 9, column: 29, scope: !17)
  !19 = !DILocation(line: 9, column: 23, scope: !17)
  !20 = distinct !DISubprogram(name: "_schmu_somerec_add", linkageName: "schmu_somerec_add", scope: !3, file: !3, line: 28, type: !4, scopeLine: 28, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !22 = !DILocation(line: 37, column: 12, scope: !21)
  !23 = !DILocation(line: 38, column: 12, scope: !21)
  $ ./local_functor
  5
  5

Simple functor
  $ schmu -m simple_functor.smu
  $ schmu use_simple_functor.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %s.otherac__ = type { ptr, ptr }
  
  @0 = private unnamed_addr constant { i64, i64, [15 x i8] } { i64 14, i64 14, [15 x i8] c"create: %s %s\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"this\00" }
  @2 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"other\00" }
  
  declare i64 @string_hash(ptr %0)
  
  define linkonce_odr { i64, i64 } @__schmu_s_create_ac_rac_ac2__(ptr %this, ptr %other) !dbg !2 {
  entry:
    %0 = tail call ptr @schmu_string_to_string(ptr %this), !dbg !6
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = getelementptr i8, ptr %other, i64 16
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), ptr %1, ptr %2)
    %3 = alloca %s.otherac__, align 8
    store ptr %this, ptr %3, align 8
    %other2 = getelementptr inbounds %s.otherac__, ptr %3, i32 0, i32 1
    store ptr %other, ptr %other2, align 8
    %4 = alloca ptr, align 8
    store ptr %0, ptr %4, align 8
    call void @__free_ac_(ptr %4)
    %unbox = load { i64, i64 }, ptr %3, align 8
    ret { i64, i64 } %unbox
  }
  
  define ptr @schmu_string_to_string(ptr %t) !dbg !7 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %t, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    ret ptr %2
  }
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %0 = alloca ptr, align 8
    store ptr @1, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    %3 = alloca ptr, align 8
    store ptr @2, ptr %3, align 8
    %4 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 %3, i64 8, i1 false)
    call void @__copy_ac_(ptr %4)
    %5 = load ptr, ptr %4, align 8
    %ret = alloca %s.otherac__, align 8
    %6 = call { i64, i64 } @__schmu_s_create_ac_rac_ac2__(ptr %2, ptr %5), !dbg !10
    store { i64, i64 } %6, ptr %ret, align 8
    call void @__free_ac_ac2_(ptr %ret)
    ret i64 0
  }
  
  define linkonce_odr void @__free_ac_ac2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_ac_(ptr %1)
    %2 = getelementptr inbounds %s.otherac__, ptr %0, i32 0, i32 1
    call void @__free_ac_(ptr %2)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "use_simple_functor.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_schmu_s_create", linkageName: "__schmu_s_create_ac_rac_ac2__", scope: !3, file: !3, line: 10, type: !4, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "simple_functor.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 11, column: 28, scope: !2)
  !7 = distinct !DISubprogram(name: "_schmu_string_to_string", linkageName: "schmu_string_to_string", scope: !8, file: !8, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DIFile(filename: "use_simple_functor.smu", directory: "")
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !8, file: !8, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 12, column: 7, scope: !9)
  $ ./use_simple_functor
  create: this other

Nameclashes with filename
  $ schmu -m filename_nameclash.smu

No mutable global state in modules
  $ schmu -m mutable_global_state.smu
  mutable_global_state.smu:1.1-11: error: Mutable top level bindings are not allowed in modules.
  
  1 | let _& = 0
      ^^^^^^^^^^
  
  [1]

No mutable global state in submodules
  $ schmu mutable_global_state_submodule.smu
  mutable_global_state_submodule.smu:2.3-13: error: Mutable top level bindings are not allowed in modules.
  
  2 |   let _& = 0
        ^^^^^^^^^^
  
  [1]

Ensure prelude is not reachable
  $ schmu use_prelude.smu
  use_prelude.smu:1.8-26: error: Module prelude has not been imported.
  
  1 | ignore(prelude/iter_range)
             ^^^^^^^^^^^^^^^^^^
  
  [1]

Ensure prelude is not importable
  $ schmu import_prelude.smu
  import_prelude.smu:1.8-15: error: Cannot find module: prelude.
  
  1 | import prelude
             ^^^^^^^
  
  [1]

Fix handling of parameterized abstract types
  $ schmu -m nullvec.smu
  $ schmu use_nullvec.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./use_nullvec

Fix external declarations in inner modules
  $ schmu inner_module_externals.smu

Make applied functors hidden behind signatures usable. Does this apply to local module too?
  $ schmu -m hidden_functor_app.smu
  $ schmu use_hidden_functor_app.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./use_hidden_functor_app

Check deps
  $ schmu -m --deps modd/modd.smu
  modd.o modd.smi: indirect.smi public.smi
  $ schmu --deps modd/modd.smu
  modd: indirect.smi public.smi

Use correct location to report functor application errors
  $ schmu functor_app_err.smu
  functor_app_err.smu:7.27-31: error: Mismatch between implementation and signature: Missing implementation of (t, t) -> bool equal.
  
  7 | module tbl = hashtbl/make(file)
                                ^^^^
  
  [1]

A regression test for monomorphization. Without proper regeneralization, the
type could change during monomorphization due to overlapping qvar ids.
  $ schmu -m async.smu
  $ schmu test_async.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./test_async
  resolving first promise
  resolved to 3
  resolving second promise
  resolved later to a string
