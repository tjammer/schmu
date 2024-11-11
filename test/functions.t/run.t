Compile stubs
  $ cc -c stub.c

Test name resolution and IR creation of functions
We discard the triple, b/c it varies from distro to distro
e.g. x86_64-unknown-linux-gnu on Fedora vs x86_64-pc-linux-gnu on gentoo

Simple fibonacci
  $ schmu --dump-llvm -o a.out stub.o fib.smu && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @schmu_fib(i64 %n) !dbg !2 {
  entry:
    br label %tailrecurse, !dbg !6
  
  tailrecurse:                                      ; preds = %else, %entry
    %accumulator.tr = phi i64 [ 0, %entry ], [ %add, %else ]
    %n.tr = phi i64 [ %n, %entry ], [ %2, %else ]
    %lt = icmp slt i64 %n.tr, 2
    br i1 %lt, label %then, label %else, !dbg !7
  
  then:                                             ; preds = %tailrecurse
    %accumulator.ret.tr = add i64 %n.tr, %accumulator.tr
    ret i64 %accumulator.ret.tr
  
  else:                                             ; preds = %tailrecurse
    %0 = add i64 %n.tr, -1, !dbg !8
    %1 = tail call i64 @schmu_fib(i64 %0), !dbg !8
    %add = add i64 %1, %accumulator.tr
    %2 = add i64 %0, -1, !dbg !6
    br label %tailrecurse, !dbg !6
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %0 = tail call i64 @schmu_fib(i64 30), !dbg !10
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "a.out.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "fib", linkageName: "schmu_fib", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "fib.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 3, column: 21, scope: !2)
  !7 = !DILocation(line: 2, column: 5, scope: !2)
  !8 = !DILocation(line: 3, column: 8, scope: !2)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 6, column: 12, scope: !9)
  832040

Fibonacci, but we shadow a bunch
  $ schmu --dump-llvm stub.o shadowing.smu && ./shadowing
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define i64 @__fun_schmu0(i64 %n) !dbg !2 {
  entry:
    %sub = sub i64 %n, 1
    %0 = tail call i64 @schmu_fib(i64 %sub), !dbg !6
    ret i64 %0
  }
  
  define i64 @schmu_fib(i64 %n) !dbg !7 {
  entry:
    %lt = icmp slt i64 %n, 2
    br i1 %lt, label %ifcont, label %else, !dbg !8
  
  else:                                             ; preds = %entry
    %0 = tail call i64 @schmu_fibn2(i64 %n), !dbg !9
    %1 = tail call i64 @__fun_schmu0(i64 %n), !dbg !10
    %add = add i64 %0, %1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %add, %else ], [ %n, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_fibn2(i64 %n) !dbg !11 {
  entry:
    %sub = sub i64 %n, 2
    %0 = tail call i64 @schmu_fib(i64 %sub), !dbg !12
    ret i64 %0
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !13 {
  entry:
    %0 = tail call i64 @schmu_fib(i64 30), !dbg !14
    tail call void @printi(i64 %0), !dbg !15
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "shadowing.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !3, file: !3, line: 10, type: !4, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "shadowing.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 10, column: 21, scope: !2)
  !7 = distinct !DISubprogram(name: "fib", linkageName: "schmu_fib", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 4, column: 5, scope: !7)
  !9 = !DILocation(line: 11, column: 4, scope: !7)
  !10 = !DILocation(line: 11, column: 15, scope: !7)
  !11 = distinct !DISubprogram(name: "fibn2", linkageName: "schmu_fibn2", scope: !3, file: !3, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 7, column: 18, scope: !11)
  !13 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = !DILocation(line: 14, column: 7, scope: !13)
  !15 = !DILocation(line: 14, scope: !13)
  832040

Multiple parameters
  $ schmu --dump-llvm stub.o multi_params.smu && ./multi_params
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @schmu_add(i64 %a, i64 %b) !dbg !2 {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define i64 @schmu_doiflesselse(i64 %a, i64 %b, i64 %greater, i64 %less) !dbg !6 {
  entry:
    %lt = icmp slt i64 %a, %b
    br i1 %lt, label %ifcont, label %else, !dbg !7
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %greater, %else ], [ %less, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_one() !dbg !8 {
  entry:
    ret i64 1
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %0 = tail call i64 @schmu_one(), !dbg !10
    %1 = tail call i64 @schmu_add(i64 %0, i64 1), !dbg !11
    %2 = tail call i64 @schmu_doiflesselse(i64 %1, i64 0, i64 1, i64 2), !dbg !12
    ret i64 %2
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "multi_params.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "add", linkageName: "schmu_add", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "multi_params.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "doiflesselse", linkageName: "schmu_doiflesselse", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 6, column: 5, scope: !6)
  !8 = distinct !DISubprogram(name: "one", linkageName: "schmu_one", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 9, column: 17, scope: !9)
  !11 = !DILocation(line: 9, column: 13, scope: !9)
  !12 = !DILocation(line: 9, scope: !9)
  [1]

We have downwards closures
  $ schmu --dump-llvm stub.o closure.smu && ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %capturable_ = type { i64 }
  
  @schmu_a = global %capturable_ zeroinitializer, align 8
  
  define i64 @schmu_capture_a() !dbg !2 {
  entry:
    %0 = load i64, ptr @schmu_a, align 8
    %add = add i64 %0, 2
    ret i64 %add
  }
  
  define i64 @schmu_capture_a_wrapped() !dbg !6 {
  entry:
    %0 = tail call i64 @schmu_wrap(), !dbg !7
    ret i64 %0
  }
  
  define i64 @schmu_inner() !dbg !8 {
  entry:
    %0 = load i64, ptr @schmu_a, align 8
    %add = add i64 %0, 2
    ret i64 %add
  }
  
  define i64 @schmu_wrap() !dbg !9 {
  entry:
    %0 = tail call i64 @schmu_inner(), !dbg !10
    ret i64 %0
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    store i64 10, ptr @schmu_a, align 8
    %0 = tail call i64 @schmu_capture_a(), !dbg !12
    %1 = tail call i64 @schmu_capture_a_wrapped(), !dbg !13
    ret i64 %1
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "closure.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "capture_a", linkageName: "schmu_capture_a", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "closure.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "capture_a_wrapped", linkageName: "schmu_capture_a_wrapped", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 16, column: 2, scope: !6)
  !8 = distinct !DISubprogram(name: "inner", linkageName: "schmu_inner", scope: !3, file: !3, line: 13, type: !4, scopeLine: 13, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = distinct !DISubprogram(name: "wrap", linkageName: "schmu_wrap", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 14, column: 4, scope: !9)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 19, column: 7, scope: !11)
  !13 = !DILocation(line: 20, scope: !11)
  [12]

First class functions
  $ schmu --dump-llvm stub.o first_class.smu && ./first_class
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__fun_schmu0_lrl_(i64 %x) !dbg !2 {
  entry:
    ret i64 %x
  }
  
  define i64 @__fun_schmu1(i64 %x) !dbg !6 {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @__fun_schmu2(i64 %x) !dbg !7 {
  entry:
    ret i64 %x
  }
  
  define linkonce_odr i1 @__schmu_apply_bbrb_rb_(i1 %x, ptr %f) !dbg !8 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i1 %loadtmp(i1 %x, ptr %loadtmp1), !dbg !9
    ret i1 %0
  }
  
  define linkonce_odr i64 @__schmu_apply_llrl_rl_(i64 %x, ptr %f) !dbg !10 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i64 %loadtmp(i64 %x, ptr %loadtmp1), !dbg !11
    ret i64 %0
  }
  
  define linkonce_odr i64 @__schmu_pass_lrl_(i64 %x) !dbg !12 {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu_add1(i64 %x) !dbg !13 {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @schmu_int_of_bool(i1 %b) !dbg !14 {
  entry:
    br i1 %b, label %ifcont, label %else, !dbg !15
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i1 @schmu_makefalse(i1 %b) !dbg !16 {
  entry:
    ret i1 false
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !17 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @schmu_add1, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = call i64 @__schmu_apply_llrl_rl_(i64 0, ptr %clstmp), !dbg !18
    call void @printi(i64 %0), !dbg !19
    %clstmp1 = alloca %closure, align 8
    store ptr @__fun_schmu1, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %1 = call i64 @__schmu_apply_llrl_rl_(i64 1, ptr %clstmp1), !dbg !20
    call void @printi(i64 %1), !dbg !21
    %clstmp4 = alloca %closure, align 8
    store ptr @schmu_makefalse, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %2 = call i1 @__schmu_apply_bbrb_rb_(i1 true, ptr %clstmp4), !dbg !22
    %3 = call i64 @schmu_int_of_bool(i1 %2), !dbg !23
    call void @printi(i64 %3), !dbg !24
    %clstmp7 = alloca %closure, align 8
    store ptr @__fun_schmu2, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %4 = call i64 @__schmu_apply_llrl_rl_(i64 3, ptr %clstmp7), !dbg !25
    call void @printi(i64 %4), !dbg !26
    %clstmp10 = alloca %closure, align 8
    store ptr @__schmu_pass_lrl_, ptr %clstmp10, align 8
    %envptr12 = getelementptr inbounds %closure, ptr %clstmp10, i32 0, i32 1
    store ptr null, ptr %envptr12, align 8
    %5 = call i64 @__schmu_apply_llrl_rl_(i64 4, ptr %clstmp10), !dbg !27
    call void @printi(i64 %5), !dbg !28
    %clstmp13 = alloca %closure, align 8
    store ptr @__fun_schmu0_lrl_, ptr %clstmp13, align 8
    %envptr15 = getelementptr inbounds %closure, ptr %clstmp13, i32 0, i32 1
    store ptr null, ptr %envptr15, align 8
    %6 = call i64 @__schmu_apply_llrl_rl_(i64 5, ptr %clstmp13), !dbg !29
    call void @printi(i64 %6), !dbg !30
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "first_class.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0_lrl_", scope: !3, file: !3, line: 11, type: !4, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "first_class.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1", scope: !3, file: !3, line: 22, type: !4, scopeLine: 22, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "__fun_schmu2", linkageName: "__fun_schmu2", scope: !3, file: !3, line: 24, type: !4, scopeLine: 24, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_bbrb_rb_", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 3, column: 17, scope: !8)
  !10 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_llrl_rl_", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 3, column: 17, scope: !10)
  !12 = distinct !DISubprogram(name: "pass", linkageName: "__schmu_pass_lrl_", scope: !3, file: !3, line: 8, type: !4, scopeLine: 8, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = distinct !DISubprogram(name: "add1", linkageName: "schmu_add1", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = distinct !DISubprogram(name: "int_of_bool", linkageName: "schmu_int_of_bool", scope: !3, file: !3, line: 17, type: !4, scopeLine: 17, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 17, column: 23, scope: !14)
  !16 = distinct !DISubprogram(name: "makefalse", linkageName: "schmu_makefalse", scope: !3, file: !3, line: 13, type: !4, scopeLine: 13, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !17 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = !DILocation(line: 21, scope: !17)
  !19 = !DILocation(line: 21, column: 15, scope: !17)
  !20 = !DILocation(line: 22, scope: !17)
  !21 = !DILocation(line: 22, column: 24, scope: !17)
  !22 = !DILocation(line: 23, column: 5, scope: !17)
  !23 = !DILocation(line: 23, column: 22, scope: !17)
  !24 = !DILocation(line: 23, column: 36, scope: !17)
  !25 = !DILocation(line: 24, column: 7, scope: !17)
  !26 = !DILocation(line: 24, scope: !17)
  !27 = !DILocation(line: 25, column: 7, scope: !17)
  !28 = !DILocation(line: 25, scope: !17)
  !29 = !DILocation(line: 26, column: 7, scope: !17)
  !30 = !DILocation(line: 26, scope: !17)
  1
  2
  0
  3
  4
  5

Don't try to create 'void' value in if
  $ schmu --dump-llvm stub.o if_return_void.smu && ./if_return_void
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define void @schmu_foo(i64 %i) !dbg !2 {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, ptr %0, align 8
    br label %rec
  
  rec:                                              ; preds = %ifcont, %entry
    %1 = phi i64 [ %sub4, %ifcont ], [ %i, %entry ]
    %lt = icmp slt i64 %1, 2
    br i1 %lt, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %rec
    %2 = add i64 %1, -1, !dbg !7
    tail call void @printi(i64 %2), !dbg !7
    ret void
  
  else:                                             ; preds = %rec
    %lt1 = icmp slt i64 %1, 400
    br i1 %lt1, label %then2, label %else3, !dbg !8
  
  then2:                                            ; preds = %else
    tail call void @printi(i64 %1), !dbg !9
    br label %ifcont
  
  else3:                                            ; preds = %else
    %add = add i64 %1, 1
    tail call void @printi(i64 %add), !dbg !10
    br label %ifcont
  
  ifcont:                                           ; preds = %else3, %then2
    %sub4 = sub i64 %1, 1
    %3 = add i64 %1, -1
    store i64 %3, ptr %0, align 8
    br label %rec
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    tail call void @schmu_foo(i64 4), !dbg !12
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "if_return_void.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "foo", linkageName: "schmu_foo", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "if_return_void.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 4, column: 5, scope: !2)
  !7 = !DILocation(line: 4, column: 12, scope: !2)
  !8 = !DILocation(line: 6, column: 7, scope: !2)
  !9 = !DILocation(line: 6, column: 16, scope: !2)
  !10 = !DILocation(line: 7, column: 10, scope: !2)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 11, scope: !11)
  4
  3
  2
  0

Captured values should not overwrite function params
  $ schmu --dump-llvm stub.o -o a.out overwrite_params.smu && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @schmu_b = constant i64 2
  
  declare void @printi(i64 %0)
  
  define i64 @schmu_add(ptr %a, ptr %b) !dbg !2 {
  entry:
    %loadtmp = load ptr, ptr %a, align 8
    %envptr = getelementptr inbounds %closure, ptr %a, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i64 %loadtmp(ptr %loadtmp1), !dbg !6
    %loadtmp3 = load ptr, ptr %b, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %b, i32 0, i32 1
    %loadtmp5 = load ptr, ptr %envptr4, align 8
    %1 = tail call i64 %loadtmp3(ptr %loadtmp5), !dbg !7
    %add = add i64 %0, %1
    ret i64 %add
  }
  
  define i64 @schmu_one() !dbg !8 {
  entry:
    ret i64 1
  }
  
  define i64 @schmu_two() !dbg !9 {
  entry:
    ret i64 2
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !10 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @schmu_one, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @schmu_two, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %0 = call i64 @schmu_add(ptr %clstmp, ptr %clstmp1), !dbg !11
    call void @printi(i64 %0), !dbg !12
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "a.out.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "add", linkageName: "schmu_add", scope: !3, file: !3, line: 8, type: !4, scopeLine: 8, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "overwrite_params.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 10, column: 2, scope: !2)
  !7 = !DILocation(line: 10, column: 8, scope: !2)
  !8 = distinct !DISubprogram(name: "one", linkageName: "schmu_one", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = distinct !DISubprogram(name: "two", linkageName: "schmu_two", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 13, column: 7, scope: !10)
  !12 = !DILocation(line: 13, scope: !10)
  3

Functions can be generic. In this test, we generate 'apply' only once and use it with
3 different functions with different types
  $ schmu --dump-llvm stub.o generic_fun_arg.smu && ./generic_fun_arg
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %tl_ = type { i64 }
  %closure = type { ptr, ptr }
  %tb_ = type { i1 }
  
  @schmu_a = constant i64 2
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__fun_schmu0_l_rl__(i64 %0) !dbg !2 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %1 = alloca %tl_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %x, i64 8, i1 false)
    %unbox = load i64, ptr %1, align 8
    ret i64 %unbox
  }
  
  define i64 @__fun_schmu1(i64 %x) !dbg !6 {
  entry:
    ret i64 %x
  }
  
  define linkonce_odr i8 @__schmu_apply_b_b_rb2_rb__(i8 %0, ptr %f) !dbg !7 {
  entry:
    %x = alloca i8, align 1
    store i8 %0, ptr %x, align 1
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret = alloca %tb_, align 8
    %1 = tail call i8 %loadtmp(i8 %0, ptr %loadtmp1), !dbg !8
    store i8 %1, ptr %ret, align 1
    ret i8 %1
  }
  
  define linkonce_odr i1 @__schmu_apply_bbrb_rb_(i1 %x, ptr %f) !dbg !9 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i1 %loadtmp(i1 %x, ptr %loadtmp1), !dbg !10
    ret i1 %0
  }
  
  define linkonce_odr i64 @__schmu_apply_l_l_rl2_rl__(i64 %0, ptr %f) !dbg !11 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret = alloca %tl_, align 8
    %1 = tail call i64 %loadtmp(i64 %0, ptr %loadtmp1), !dbg !12
    store i64 %1, ptr %ret, align 8
    ret i64 %1
  }
  
  define linkonce_odr i64 @__schmu_apply_llrl_rl_(i64 %x, ptr %f) !dbg !13 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i64 %loadtmp(i64 %x, ptr %loadtmp1), !dbg !14
    ret i64 %0
  }
  
  define i64 @schmu_add1(i64 %x) !dbg !15 {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @schmu_add3_rec(i64 %0) !dbg !16 {
  entry:
    %t = alloca i64, align 8
    store i64 %0, ptr %t, align 8
    %1 = alloca %tl_, align 8
    %add = add i64 %0, 3
    store i64 %add, ptr %1, align 8
    ret i64 %add
  }
  
  define i64 @schmu_add_closed(i64 %x) !dbg !17 {
  entry:
    %add = add i64 %x, 2
    ret i64 %add
  }
  
  define i8 @schmu_make_rec_false(i8 %0) !dbg !18 {
  entry:
    %r = alloca i8, align 1
    store i8 %0, ptr %r, align 1
    %1 = trunc i8 %0 to i1
    br i1 %1, label %then, label %ifcont, !dbg !19
  
  then:                                             ; preds = %entry
    %2 = alloca %tb_, align 8
    store %tb_ zeroinitializer, ptr %2, align 1
    %unbox.pre = load i8, ptr %2, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %unbox = phi i8 [ %unbox.pre, %then ], [ %0, %entry ]
    %iftmp = phi ptr [ %2, %then ], [ %r, %entry ]
    ret i8 %unbox
  }
  
  define i1 @schmu_makefalse(i1 %b) !dbg !20 {
  entry:
    ret i1 false
  }
  
  define void @schmu_print_bool(i1 %b) !dbg !21 {
  entry:
    br i1 %b, label %then, label %else, !dbg !22
  
  then:                                             ; preds = %entry
    tail call void @printi(i64 1), !dbg !23
    ret void
  
  else:                                             ; preds = %entry
    tail call void @printi(i64 0), !dbg !24
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !25 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @schmu_add1, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = call i64 @__schmu_apply_llrl_rl_(i64 20, ptr %clstmp), !dbg !26
    call void @printi(i64 %0), !dbg !27
    %clstmp1 = alloca %closure, align 8
    store ptr @schmu_add_closed, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %1 = call i64 @__schmu_apply_llrl_rl_(i64 20, ptr %clstmp1), !dbg !28
    call void @printi(i64 %1), !dbg !29
    %clstmp4 = alloca %closure, align 8
    store ptr @schmu_add3_rec, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %ret = alloca %tl_, align 8
    %2 = call i64 @__schmu_apply_l_l_rl2_rl__(i64 20, ptr %clstmp4), !dbg !30
    store i64 %2, ptr %ret, align 8
    call void @printi(i64 %2), !dbg !31
    %clstmp7 = alloca %closure, align 8
    store ptr @schmu_make_rec_false, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %ret10 = alloca %tb_, align 8
    %3 = call i8 @__schmu_apply_b_b_rb2_rb__(i8 1, ptr %clstmp7), !dbg !32
    store i8 %3, ptr %ret10, align 1
    %4 = trunc i8 %3 to i1
    call void @schmu_print_bool(i1 %4), !dbg !33
    %clstmp11 = alloca %closure, align 8
    store ptr @schmu_makefalse, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    %5 = call i1 @__schmu_apply_bbrb_rb_(i1 true, ptr %clstmp11), !dbg !34
    call void @schmu_print_bool(i1 %5), !dbg !35
    %ret14 = alloca %tl_, align 8
    %6 = call i64 @__fun_schmu0_l_rl__(i64 17), !dbg !36
    store i64 %6, ptr %ret14, align 8
    call void @printi(i64 %6), !dbg !37
    %7 = call i64 @__fun_schmu1(i64 18), !dbg !38
    call void @printi(i64 %7), !dbg !39
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "generic_fun_arg.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0_l_rl__", scope: !3, file: !3, line: 43, type: !4, scopeLine: 43, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "generic_fun_arg.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1", scope: !3, file: !3, line: 52, type: !4, scopeLine: 52, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_b_b_rb2_rb__", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 7, column: 2, scope: !7)
  !9 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_bbrb_rb_", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 7, column: 2, scope: !9)
  !11 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_l_l_rl2_rl__", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 7, column: 2, scope: !11)
  !13 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_llrl_rl_", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = !DILocation(line: 7, column: 2, scope: !13)
  !15 = distinct !DISubprogram(name: "add1", linkageName: "schmu_add1", scope: !3, file: !3, line: 18, type: !4, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !16 = distinct !DISubprogram(name: "add3_rec", linkageName: "schmu_add3_rec", scope: !3, file: !3, line: 38, type: !4, scopeLine: 38, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !17 = distinct !DISubprogram(name: "add_closed", linkageName: "schmu_add_closed", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = distinct !DISubprogram(name: "make_rec_false", linkageName: "schmu_make_rec_false", scope: !3, file: !3, line: 31, type: !4, scopeLine: 31, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !19 = !DILocation(line: 32, column: 5, scope: !18)
  !20 = distinct !DISubprogram(name: "makefalse", linkageName: "schmu_makefalse", scope: !3, file: !3, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = distinct !DISubprogram(name: "print_bool", linkageName: "schmu_print_bool", scope: !3, file: !3, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !22 = !DILocation(line: 21, column: 5, scope: !21)
  !23 = !DILocation(line: 21, column: 8, scope: !21)
  !24 = !DILocation(line: 22, column: 8, scope: !21)
  !25 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !26 = !DILocation(line: 45, column: 7, scope: !25)
  !27 = !DILocation(line: 45, scope: !25)
  !28 = !DILocation(line: 46, column: 7, scope: !25)
  !29 = !DILocation(line: 46, scope: !25)
  !30 = !DILocation(line: 47, column: 7, scope: !25)
  !31 = !DILocation(line: 47, scope: !25)
  !32 = !DILocation(line: 48, column: 11, scope: !25)
  !33 = !DILocation(line: 48, scope: !25)
  !34 = !DILocation(line: 49, column: 11, scope: !25)
  !35 = !DILocation(line: 49, scope: !25)
  !36 = !DILocation(line: 50, column: 7, scope: !25)
  !37 = !DILocation(line: 50, scope: !25)
  !38 = !DILocation(line: 52, column: 4, scope: !25)
  !39 = !DILocation(line: 52, column: 23, scope: !25)
  21
  22
  23
  0
  0
  17
  18

A generic pass function. This example is not 100% correct, but works due to calling convertion.
  $ schmu --dump-llvm stub.o generic_pass.smu && ./generic_pass
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %t_ = type { i64, i1 }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr { i64, i8 } @__schmu_apply_lb_rlb2_lb_rlb__(ptr %f, i64 %0, i8 %1) !dbg !2 {
  entry:
    %x = alloca { i64, i8 }, align 8
    store i64 %0, ptr %x, align 8
    %snd = getelementptr inbounds { i64, i8 }, ptr %x, i32 0, i32 1
    store i8 %1, ptr %snd, align 1
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp5 = load ptr, ptr %envptr, align 8
    %ret = alloca %t_, align 8
    %2 = tail call { i64, i8 } %loadtmp(i64 %0, i8 %1, ptr %loadtmp5), !dbg !6
    store { i64, i8 } %2, ptr %ret, align 8
    ret { i64, i8 } %2
  }
  
  define linkonce_odr i64 @__schmu_apply_lrl_lrl_(ptr %f, i64 %x) !dbg !7 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i64 %loadtmp(i64 %x, ptr %loadtmp1), !dbg !8
    ret i64 %0
  }
  
  define linkonce_odr { i64, i8 } @__schmu_pass_lb_rlb__(i64 %0, i8 %1) !dbg !9 {
  entry:
    %x = alloca { i64, i8 }, align 8
    store i64 %0, ptr %x, align 8
    %snd = getelementptr inbounds { i64, i8 }, ptr %x, i32 0, i32 1
    store i8 %1, ptr %snd, align 1
    %2 = alloca %t_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %x, i64 16, i1 false)
    %unbox = load { i64, i8 }, ptr %2, align 8
    ret { i64, i8 } %unbox
  }
  
  define linkonce_odr i64 @__schmu_pass_lrl_(i64 %x) !dbg !10 {
  entry:
    ret i64 %x
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__schmu_pass_lrl_, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = call i64 @__schmu_apply_lrl_lrl_(ptr %clstmp, i64 20), !dbg !12
    call void @printi(i64 %0), !dbg !13
    %clstmp1 = alloca %closure, align 8
    store ptr @__schmu_pass_lb_rlb__, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %boxconst = alloca %t_, align 8
    store %t_ { i64 700, i1 false }, ptr %boxconst, align 8
    %fst4 = load i64, ptr %boxconst, align 8
    %snd = getelementptr inbounds { i64, i8 }, ptr %boxconst, i32 0, i32 1
    %snd5 = load i8, ptr %snd, align 1
    %ret = alloca %t_, align 8
    %1 = call { i64, i8 } @__schmu_apply_lb_rlb2_lb_rlb__(ptr %clstmp1, i64 %fst4, i8 %snd5), !dbg !14
    store { i64, i8 } %1, ptr %ret, align 8
    %2 = load i64, ptr %ret, align 8
    call void @printi(i64 %2), !dbg !15
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "generic_pass.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_lb_rlb2_lb_rlb__", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "generic_pass.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 6, column: 17, scope: !2)
  !7 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_lrl_lrl_", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 6, column: 17, scope: !7)
  !9 = distinct !DISubprogram(name: "pass", linkageName: "__schmu_pass_lb_rlb__", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = distinct !DISubprogram(name: "pass", linkageName: "__schmu_pass_lrl_", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 8, column: 7, scope: !11)
  !13 = !DILocation(line: 8, scope: !11)
  !14 = !DILocation(line: 9, column: 1, scope: !11)
  !15 = !DILocation(line: 9, column: 38, scope: !11)
  20
  700


This is a regression test. The 'add1' function was not marked as a closure when being called from
a second function. Instead, the closure struct was being created again and the code segfaulted
  $ schmu --dump-llvm stub.o indirect_closure.smu && ./indirect_closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %tl_ = type { i64 }
  
  @schmu_a = global i64 0, align 8
  @schmu_b = global i64 0, align 8
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__schmu_apply2_l_l_lrl_rl2_lrl_rl__(i64 %0, ptr %f, ptr %env) !dbg !2 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret = alloca %tl_, align 8
    %1 = tail call i64 %loadtmp(i64 %0, ptr %env, ptr %loadtmp1), !dbg !6
    store i64 %1, ptr %ret, align 8
    ret i64 %1
  }
  
  define linkonce_odr i64 @__schmu_apply_l_l_lrl_rl2_lrl_rl__(i64 %0, ptr %f, ptr %env) !dbg !7 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret = alloca %tl_, align 8
    %1 = tail call i64 %loadtmp(i64 %0, ptr %env, ptr %loadtmp1), !dbg !8
    store i64 %1, ptr %ret, align 8
    ret i64 %1
  }
  
  define linkonce_odr i64 @__schmu_boxed2int_int_l_lrl_rl__(i64 %0, ptr %env) !dbg !9 {
  entry:
    %t = alloca i64, align 8
    store i64 %0, ptr %t, align 8
    %loadtmp = load ptr, ptr %env, align 8
    %envptr = getelementptr inbounds %closure, ptr %env, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %1 = tail call i64 %loadtmp(i64 %0, ptr %loadtmp1), !dbg !10
    %2 = alloca %tl_, align 8
    store i64 %1, ptr %2, align 8
    ret i64 %1
  }
  
  define i64 @schmu_add1(i64 %x) !dbg !11 {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !12 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__schmu_boxed2int_int_l_lrl_rl__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @schmu_add1, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %ret = alloca %tl_, align 8
    %0 = call i64 @__schmu_apply_l_l_lrl_rl2_lrl_rl__(i64 15, ptr %clstmp, ptr %clstmp1), !dbg !13
    store i64 %0, ptr %ret, align 8
    store i64 %0, ptr @schmu_a, align 8
    call void @printi(i64 %0), !dbg !14
    %clstmp4 = alloca %closure, align 8
    store ptr @__schmu_boxed2int_int_l_lrl_rl__, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %clstmp7 = alloca %closure, align 8
    store ptr @schmu_add1, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %ret10 = alloca %tl_, align 8
    %1 = call i64 @__schmu_apply2_l_l_lrl_rl2_lrl_rl__(i64 15, ptr %clstmp4, ptr %clstmp7), !dbg !15
    store i64 %1, ptr %ret10, align 8
    store i64 %1, ptr @schmu_b, align 8
    call void @printi(i64 %1), !dbg !16
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "indirect_closure.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "apply2", linkageName: "__schmu_apply2_l_l_lrl_rl2_lrl_rl__", scope: !3, file: !3, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "indirect_closure.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 8, column: 2, scope: !2)
  !7 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_l_l_lrl_rl2_lrl_rl__", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 5, column: 22, scope: !7)
  !9 = distinct !DISubprogram(name: "boxed2int_int", linkageName: "__schmu_boxed2int_int_l_lrl_rl__", scope: !3, file: !3, line: 13, type: !4, scopeLine: 13, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 14, column: 10, scope: !9)
  !11 = distinct !DISubprogram(name: "add1", linkageName: "schmu_add1", scope: !3, file: !3, line: 11, type: !4, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 18, column: 8, scope: !12)
  !14 = !DILocation(line: 19, scope: !12)
  !15 = !DILocation(line: 20, column: 8, scope: !12)
  !16 = !DILocation(line: 21, scope: !12)
  16
  16

Closures can recurse too
  $ schmu --dump-llvm stub.o -o a.out recursive_closure.smu && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_outer = constant i64 10
  
  declare void @printi(i64 %0)
  
  define void @schmu_loop(i64 %i) !dbg !2 {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, ptr %0, align 8
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %1 = phi i64 [ %add, %then ], [ %i, %entry ]
    %lt = icmp slt i64 %1, 10
    br i1 %lt, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %rec
    tail call void @printi(i64 %1), !dbg !7
    %add = add i64 %1, 1
    store i64 %add, ptr %0, align 8
    br label %rec
  
  else:                                             ; preds = %rec
    tail call void @printi(i64 %1), !dbg !8
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    tail call void @schmu_loop(i64 0), !dbg !10
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "a.out.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "loop", linkageName: "schmu_loop", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "recursive_closure.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 7, column: 5, scope: !2)
  !7 = !DILocation(line: 8, column: 4, scope: !2)
  !8 = !DILocation(line: 10, column: 10, scope: !2)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 13, scope: !9)
  0
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10

Print error when returning a polymorphic lambda in an if expression
  $ schmu --dump-llvm stub.o no_lambda_let_poly_monomorph.smu
  no_lambda_let_poly_monomorph.smu:5.9-59: error: Returning polymorphic anonymous function in if expressions is not supported (yet). Sorry. You can type the function concretely though..
  
  5 | let f = if true {fun(x) {copy(x)}} else {fun(x) {copy(x)}}
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  
  [1]
Allow mixing of typedefs and external decls in the preface
  $ schmu --dump-llvm stub.o mix_preface.smu && ./mix_preface
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare i64 @dummy_call()
  
  declare void @print_2nd(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "mix_preface.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "mix_preface.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}

Support monomorphization of nested functions
  $ schmu --dump-llvm stub.o monomorph_nested.smu && ./monomorph_nested
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %rc_ = type { i64 }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i1 @__schmu_id_brb_(i1 %x) !dbg !2 {
  entry:
    ret i1 %x
  }
  
  define linkonce_odr i64 @__schmu_id_l_rl__(i64 %0) !dbg !6 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %1 = alloca %rc_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %x, i64 8, i1 false)
    %unbox = load i64, ptr %1, align 8
    ret i64 %unbox
  }
  
  define linkonce_odr i64 @__schmu_id_lrl_(i64 %x) !dbg !7 {
  entry:
    ret i64 %x
  }
  
  define linkonce_odr i1 @__schmu_wrapped_brb_(i1 %x) !dbg !8 {
  entry:
    %0 = tail call i1 @__schmu_id_brb_(i1 %x), !dbg !9
    ret i1 %0
  }
  
  define linkonce_odr i64 @__schmu_wrapped_l_rl__(i64 %0) !dbg !10 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %ret = alloca %rc_, align 8
    %1 = tail call i64 @__schmu_id_l_rl__(i64 %0), !dbg !11
    store i64 %1, ptr %ret, align 8
    ret i64 %1
  }
  
  define linkonce_odr i64 @__schmu_wrapped_lrl_(i64 %x) !dbg !12 {
  entry:
    %0 = tail call i64 @__schmu_id_lrl_(i64 %x), !dbg !13
    ret i64 %0
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !14 {
  entry:
    %0 = tail call i64 @__schmu_wrapped_lrl_(i64 12), !dbg !15
    tail call void @printi(i64 %0), !dbg !16
    %1 = tail call i1 @__schmu_wrapped_brb_(i1 false), !dbg !17
    %ret = alloca %rc_, align 8
    %2 = tail call i64 @__schmu_wrapped_l_rl__(i64 24), !dbg !18
    store i64 %2, ptr %ret, align 8
    tail call void @printi(i64 %2), !dbg !19
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "monomorph_nested.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "id", linkageName: "__schmu_id_brb_", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "monomorph_nested.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "id", linkageName: "__schmu_id_l_rl__", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "id", linkageName: "__schmu_id_lrl_", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = distinct !DISubprogram(name: "wrapped", linkageName: "__schmu_wrapped_brb_", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 7, column: 2, scope: !8)
  !10 = distinct !DISubprogram(name: "wrapped", linkageName: "__schmu_wrapped_l_rl__", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 7, column: 2, scope: !10)
  !12 = distinct !DISubprogram(name: "wrapped", linkageName: "__schmu_wrapped_lrl_", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 7, column: 2, scope: !12)
  !14 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 10, column: 7, scope: !14)
  !16 = !DILocation(line: 10, scope: !14)
  !17 = !DILocation(line: 11, column: 7, scope: !14)
  !18 = !DILocation(line: 12, column: 7, scope: !14)
  !19 = !DILocation(line: 12, scope: !14)
  12
  24

Nested polymorphic closures. Does not quite work for another nesting level
  $ schmu --dump-llvm stub.o nested_polymorphic_closures.smu && valgrind -q --leak-check=yes --show-reachable=yes ./nested_polymorphic_closures
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @schmu_arr = global ptr null, align 8
  
  declare void @printi(i64 %0)
  
  define linkonce_odr void @__array_push_al_l_(ptr noalias %arr, i64 %value) !dbg !2 {
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
  
  define void @__fun_schmu0(i64 %x) !dbg !8 {
  entry:
    %mul = mul i64 %x, 2
    tail call void @printi(i64 %mul), !dbg !10
    ret void
  }
  
  define linkonce_odr void @__schmu_array_iter_al_lru__(ptr %arr, ptr %f) !dbg !11 {
  entry:
    %__schmu_inner_cls_both_Cal_lru__ = alloca %closure, align 8
    store ptr @__schmu_inner_cls_both_Cal_lru__, ptr %__schmu_inner_cls_both_Cal_lru__, align 8
    %clsr___schmu_inner_cls_both_Cal_lru__ = alloca { ptr, ptr, ptr, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_both_Cal_lru__, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %f2 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_both_Cal_lru__, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f2, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_al_lru2_, ptr %clsr___schmu_inner_cls_both_Cal_lru__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_both_Cal_lru__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__schmu_inner_cls_both_Cal_lru__, i32 0, i32 1
    store ptr %clsr___schmu_inner_cls_both_Cal_lru__, ptr %envptr, align 8
    %__schmu_inner_cls_arr_lru_Cal__ = alloca %closure, align 8
    store ptr @__schmu_inner_cls_arr_lru_Cal__, ptr %__schmu_inner_cls_arr_lru_Cal__, align 8
    %clsr___schmu_inner_cls_arr_lru_Cal__ = alloca { ptr, ptr, ptr }, align 8
    %arr4 = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr___schmu_inner_cls_arr_lru_Cal__, i32 0, i32 2
    store ptr %arr, ptr %arr4, align 8
    store ptr @__ctor_al2_, ptr %clsr___schmu_inner_cls_arr_lru_Cal__, align 8
    %dtor6 = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr___schmu_inner_cls_arr_lru_Cal__, i32 0, i32 1
    store ptr null, ptr %dtor6, align 8
    %envptr7 = getelementptr inbounds %closure, ptr %__schmu_inner_cls_arr_lru_Cal__, i32 0, i32 1
    store ptr %clsr___schmu_inner_cls_arr_lru_Cal__, ptr %envptr7, align 8
    %__schmu_inner_cls_f_al_Clru__ = alloca %closure, align 8
    store ptr @__schmu_inner_cls_f_al_Clru__, ptr %__schmu_inner_cls_f_al_Clru__, align 8
    %clsr___schmu_inner_cls_f_al_Clru__ = alloca { ptr, ptr, %closure }, align 8
    %f9 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_f_al_Clru__, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f9, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_lru2_, ptr %clsr___schmu_inner_cls_f_al_Clru__, align 8
    %dtor11 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_f_al_Clru__, i32 0, i32 1
    store ptr null, ptr %dtor11, align 8
    %envptr12 = getelementptr inbounds %closure, ptr %__schmu_inner_cls_f_al_Clru__, i32 0, i32 1
    store ptr %clsr___schmu_inner_cls_f_al_Clru__, ptr %envptr12, align 8
    call void @__schmu_inner_cls_both_Cal_lru__(i64 0, ptr %clsr___schmu_inner_cls_both_Cal_lru__), !dbg !12
    call void @__schmu_inner_cls_arr_lru_Cal__(i64 0, ptr %f, ptr %clsr___schmu_inner_cls_arr_lru_Cal__), !dbg !13
    call void @__schmu_inner_cls_f_al_Clru__(i64 0, ptr %arr, ptr %clsr___schmu_inner_cls_f_al_Clru__), !dbg !14
    ret void
  }
  
  define linkonce_odr void @__schmu_inner_cls_arr_lru_Cal__(i64 %i, ptr %f, ptr %0) !dbg !15 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = alloca %closure, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 1 %f, i64 16, i1 false)
    %3 = alloca i1, align 1
    store i1 false, ptr %3, align 1
    %4 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %4, %entry ]
    %5 = add i64 %lsr.iv, -1
    %6 = load i64, ptr %arr1, align 8
    %eq = icmp eq i64 %5, %6
    br i1 %eq, label %then, label %else, !dbg !16
  
  then:                                             ; preds = %rec
    store i1 true, ptr %3, align 1
    ret void
  
  else:                                             ; preds = %rec
    %7 = shl i64 %lsr.iv, 3
    %uglygep = getelementptr i8, ptr %arr1, i64 %7
    %uglygep3 = getelementptr i8, ptr %uglygep, i64 8
    %8 = load i64, ptr %uglygep3, align 8
    %loadtmp = load ptr, ptr %2, align 8
    %envptr = getelementptr inbounds %closure, ptr %2, i32 0, i32 1
    %loadtmp2 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(i64 %8, ptr %loadtmp2), !dbg !17
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr void @__schmu_inner_cls_both_Cal_lru__(i64 %i, ptr %0) !dbg !18 {
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
    br i1 %eq, label %then, label %else, !dbg !19
  
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
    tail call void %loadtmp(i64 %6, ptr %loadtmp2), !dbg !20
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr void @__schmu_inner_cls_f_al_Clru__(i64 %i, ptr %arr, ptr %0) !dbg !21 {
  entry:
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = alloca ptr, align 8
    store ptr %arr, ptr %2, align 8
    %3 = alloca i1, align 1
    store i1 false, ptr %3, align 1
    %4 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %4, %entry ]
    %5 = add i64 %lsr.iv, -1
    %6 = load i64, ptr %arr, align 8
    %eq = icmp eq i64 %5, %6
    br i1 %eq, label %then, label %else, !dbg !22
  
  then:                                             ; preds = %rec
    store i1 true, ptr %3, align 1
    ret void
  
  else:                                             ; preds = %rec
    %7 = shl i64 %lsr.iv, 3
    %uglygep = getelementptr i8, ptr %arr, i64 %7
    %uglygep2 = getelementptr i8, ptr %uglygep, i64 8
    %8 = load i64, ptr %uglygep2, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr3 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp1 = load ptr, ptr %sunkaddr3, align 8
    tail call void %loadtmp(i64 %8, ptr %loadtmp1), !dbg !23
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
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
  
  define linkonce_odr ptr @__ctor_al2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_al_(ptr %arr)
    ret ptr %1
  }
  
  define linkonce_odr ptr @__ctor_lru2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 32)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %f = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy_lru_(ptr %f)
    ret ptr %1
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !24 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_arr, align 8
    store i64 0, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    tail call void @__array_push_al_l_(ptr @schmu_arr, i64 1), !dbg !25
    tail call void @__array_push_al_l_(ptr @schmu_arr, i64 2), !dbg !26
    tail call void @__array_push_al_l_(ptr @schmu_arr, i64 3), !dbg !27
    tail call void @__array_push_al_l_(ptr @schmu_arr, i64 4), !dbg !28
    tail call void @__array_push_al_l_(ptr @schmu_arr, i64 5), !dbg !29
    %2 = load ptr, ptr @schmu_arr, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__schmu_array_iter_al_lru__(ptr %2, ptr %clstmp), !dbg !30
    call void @__free_al_(ptr @schmu_arr)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "nested_polymorphic_closures.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_al_l_", scope: !3, file: !3, line: 15, type: !4, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 19, column: 5, scope: !2)
  !7 = !DILocation(line: 20, column: 7, scope: !2)
  !8 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !9, file: !9, line: 40, type: !4, scopeLine: 40, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DIFile(filename: "nested_polymorphic_closures.smu", directory: "")
  !10 = !DILocation(line: 40, column: 23, scope: !8)
  !11 = distinct !DISubprogram(name: "array_iter", linkageName: "__schmu_array_iter_al_lru__", scope: !9, file: !9, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 28, column: 2, scope: !11)
  !13 = !DILocation(line: 29, column: 2, scope: !11)
  !14 = !DILocation(line: 30, column: 2, scope: !11)
  !15 = distinct !DISubprogram(name: "inner_cls_arr", linkageName: "__schmu_inner_cls_arr_lru_Cal__", scope: !9, file: !9, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !16 = !DILocation(line: 13, column: 7, scope: !15)
  !17 = !DILocation(line: 15, column: 6, scope: !15)
  !18 = distinct !DISubprogram(name: "inner_cls_both", linkageName: "__schmu_inner_cls_both_Cal_lru__", scope: !9, file: !9, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !19 = !DILocation(line: 5, column: 7, scope: !18)
  !20 = !DILocation(line: 7, column: 6, scope: !18)
  !21 = distinct !DISubprogram(name: "inner_cls_f", linkageName: "__schmu_inner_cls_f_al_Clru__", scope: !9, file: !9, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !22 = !DILocation(line: 21, column: 7, scope: !21)
  !23 = !DILocation(line: 23, column: 6, scope: !21)
  !24 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !9, file: !9, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !25 = !DILocation(line: 34, scope: !24)
  !26 = !DILocation(line: 35, scope: !24)
  !27 = !DILocation(line: 36, scope: !24)
  !28 = !DILocation(line: 37, scope: !24)
  !29 = !DILocation(line: 38, scope: !24)
  !30 = !DILocation(line: 40, scope: !24)
  2
  4
  6
  8
  10
  2
  4
  6
  8
  10
  2
  4
  6
  8
  10

Closures have to be added to the env of other closures, so they can be called correctly
  $ schmu --dump-llvm stub.o closures_to_env.smu && ./closures_to_env
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = constant i64 20
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare void @printf(ptr %0, i64 %1)
  
  define i64 @schmu_close_over_a() !dbg !2 {
  entry:
    ret i64 20
  }
  
  define void @schmu_use_above() !dbg !6 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !7
    %1 = tail call i64 @schmu_close_over_a(), !dbg !8
    tail call void @printf(ptr %0, i64 %1), !dbg !9
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !10 {
  entry:
    tail call void @schmu_use_above(), !dbg !11
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "closures_to_env.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "close_over_a", linkageName: "schmu_close_over_a", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "closures_to_env.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "use_above", linkageName: "schmu_use_above", scope: !3, file: !3, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 8, column: 9, scope: !6)
  !8 = !DILocation(line: 8, column: 30, scope: !6)
  !9 = !DILocation(line: 8, column: 2, scope: !6)
  !10 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 11, scope: !10)
  20

Don't copy mutable types in setup of tailrecursive functions
  $ schmu --dump-llvm tailrec_mutable.smu && valgrind -q --leak-check=yes --show-reachable=yes ./tailrec_mutable
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %bref_ = type { i1 }
  %r_ = type { i64 }
  
  @schmu_rf = global %bref_ zeroinitializer, align 1
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"false\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"true\00" }
  @2 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%s\0A\00" }
  @3 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define linkonce_odr void @__array_push_al_l_(ptr noalias %arr, i64 %value) !dbg !2 {
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
  
  define void @schmu_change_int(ptr noalias %i, i64 %j) !dbg !8 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %i, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %j, ptr %1, align 8
    %2 = add i64 %j, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 101
    br i1 %eq, label %then, label %else, !dbg !10
  
  then:                                             ; preds = %rec
    store i64 100, ptr %i, align 8
    ret void
  
  else:                                             ; preds = %rec
    store ptr %i, ptr %0, align 8
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_dontmut_bref(i64 %i, ptr noalias %rf) !dbg !11 {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, ptr %0, align 8
    %1 = alloca ptr, align 8
    store ptr %rf, ptr %1, align 8
    %2 = alloca %bref_, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %3 = phi i64 [ %add, %else ], [ %i, %entry ]
    %rf1 = phi ptr [ %2, %else ], [ %rf, %entry ]
    %gt = icmp sgt i64 %3, 0
    br i1 %gt, label %then, label %else, !dbg !12
  
  then:                                             ; preds = %rec
    store i1 false, ptr %rf1, align 1
    ret void
  
  else:                                             ; preds = %rec
    store i1 true, ptr %2, align 1
    %add = add i64 %3, 1
    store i64 %add, ptr %0, align 8
    store ptr %2, ptr %1, align 8
    br label %rec
  }
  
  define void @schmu_mod_rec(ptr noalias %r, i64 %i) !dbg !13 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %r, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else, !dbg !14
  
  then:                                             ; preds = %rec
    store i64 2, ptr %r, align 8
    ret void
  
  else:                                             ; preds = %rec
    store ptr %r, ptr %0, align 8
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_mut_bref(i64 %i, ptr noalias %rf) !dbg !15 {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, ptr %0, align 8
    %1 = alloca ptr, align 8
    store ptr %rf, ptr %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %gt = icmp sgt i64 %2, 0
    br i1 %gt, label %then, label %else, !dbg !16
  
  then:                                             ; preds = %rec
    store i1 true, ptr %rf, align 1
    ret void
  
  else:                                             ; preds = %rec
    %add = add i64 %2, 1
    store i64 %add, ptr %0, align 8
    store ptr %rf, ptr %1, align 8
    br label %rec
  }
  
  define void @schmu_push_twice(ptr noalias %a, i64 %i) !dbg !17 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %a, ptr %0, align 8
    %1 = alloca i1, align 1
    store i1 false, ptr %1, align 1
    %2 = alloca i64, align 8
    store i64 %i, ptr %2, align 8
    %3 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %3, %entry ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else, !dbg !18
  
  then:                                             ; preds = %rec
    store i1 true, ptr %1, align 1
    ret void
  
  else:                                             ; preds = %rec
    tail call void @__array_push_al_l_(ptr %a, i64 20), !dbg !19
    store ptr %a, ptr %0, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(ptr noalias %a, i64 %i) !dbg !20 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %a, ptr %0, align 8
    %1 = alloca i1, align 1
    store i1 false, ptr %1, align 1
    %2 = alloca i64, align 8
    store i64 %i, ptr %2, align 8
    %3 = alloca ptr, align 8
    %4 = alloca ptr, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %cont, %cont10, %entry
    %.ph = phi i1 [ false, %entry ], [ true, %cont ], [ %10, %cont10 ]
    %.ph22 = phi i1 [ false, %entry ], [ true, %cont ], [ true, %cont10 ]
    %.ph23 = phi i1 [ false, %entry ], [ true, %cont ], [ true, %cont10 ]
    %.ph24 = phi i64 [ %i, %entry ], [ 3, %cont ], [ 11, %cont10 ]
    %.ph25 = phi ptr [ %a, %entry ], [ %3, %cont ], [ %4, %cont10 ]
    %5 = add i64 %.ph24, 1, !dbg !21
    br label %rec, !dbg !21
  
  rec:                                              ; preds = %rec.outer, %else14
    %lsr.iv = phi i64 [ %5, %rec.outer ], [ %lsr.iv.next, %else14 ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else, !dbg !21
  
  then:                                             ; preds = %rec
    %6 = call ptr @malloc(i64 24)
    store ptr %6, ptr %3, align 8
    store i64 1, ptr %6, align 8
    %cap = getelementptr i64, ptr %6, i64 1
    store i64 1, ptr %cap, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    store i64 10, ptr %7, align 8
    br i1 %.ph, label %call_decr, label %cookie
  
  call_decr:                                        ; preds = %then
    call void @__free_al_(ptr %.ph25)
    br label %cont
  
  cookie:                                           ; preds = %then
    store i1 true, ptr %1, align 1
    br label %cont
  
  cont:                                             ; preds = %cookie, %call_decr
    store ptr %3, ptr %0, align 8
    store i64 3, ptr %2, align 8
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq2 = icmp eq i64 %lsr.iv, 11
    br i1 %eq2, label %then3, label %else11, !dbg !22
  
  then3:                                            ; preds = %else
    %8 = call ptr @malloc(i64 24)
    store ptr %8, ptr %4, align 8
    store i64 1, ptr %8, align 8
    %cap5 = getelementptr i64, ptr %8, i64 1
    store i64 1, ptr %cap5, align 8
    %9 = getelementptr i8, ptr %8, i64 16
    store i64 10, ptr %9, align 8
    br i1 %.ph22, label %call_decr8, label %cookie9
  
  call_decr8:                                       ; preds = %then3
    call void @__free_al_(ptr %.ph25)
    br label %cont10
  
  cookie9:                                          ; preds = %then3
    store i1 true, ptr %1, align 1
    br label %cont10
  
  cont10:                                           ; preds = %cookie9, %call_decr8
    %10 = phi i1 [ true, %cookie9 ], [ %.ph, %call_decr8 ]
    store ptr %4, ptr %0, align 8
    store i64 11, ptr %2, align 8
    br label %rec.outer
  
  else11:                                           ; preds = %else
    %eq12 = icmp eq i64 %lsr.iv, 13
    br i1 %eq12, label %then13, label %else14, !dbg !23
  
  then13:                                           ; preds = %else11
    br i1 %.ph23, label %call_decr18, label %cookie19
  
  else14:                                           ; preds = %else11
    call void @__array_push_al_l_(ptr %.ph25, i64 20), !dbg !24
    store ptr %.ph25, ptr %0, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  call_decr18:                                      ; preds = %then13
    call void @__free_al_(ptr %.ph25)
    br label %cont20
  
  cookie19:                                         ; preds = %then13
    store i1 true, ptr %1, align 1
    br label %cont20
  
  cont20:                                           ; preds = %cookie19, %call_decr18
    ret void
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !25 {
  entry:
    store i1 false, ptr @schmu_rf, align 1
    tail call void @schmu_mut_bref(i64 0, ptr @schmu_rf), !dbg !26
    %0 = load i1, ptr @schmu_rf, align 1
    br i1 %0, label %cont, label %free
  
  free:                                             ; preds = %entry
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %1 = phi ptr [ @1, %entry ], [ @0, %free ]
    %2 = getelementptr i8, ptr %1, i64 16
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @2, i64 16), ptr %2)
    tail call void @schmu_dontmut_bref(i64 0, ptr @schmu_rf), !dbg !27
    %3 = load i1, ptr @schmu_rf, align 1
    br i1 %3, label %cont2, label %free1
  
  free1:                                            ; preds = %cont
    br label %cont2
  
  cont2:                                            ; preds = %free1, %cont
    %4 = phi ptr [ @1, %cont ], [ @0, %free1 ]
    %5 = getelementptr i8, ptr %4, i64 16
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @2, i64 16), ptr %5)
    %6 = alloca %r_, align 8
    store i64 20, ptr %6, align 8
    call void @schmu_mod_rec(ptr %6, i64 0), !dbg !28
    %7 = load i64, ptr %6, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @3, i64 16), i64 %7)
    %8 = alloca ptr, align 8
    %9 = call ptr @malloc(i64 32)
    store ptr %9, ptr %8, align 8
    store i64 2, ptr %9, align 8
    %cap = getelementptr i64, ptr %9, i64 1
    store i64 2, ptr %cap, align 8
    %10 = getelementptr i8, ptr %9, i64 16
    store i64 10, ptr %10, align 8
    %"1" = getelementptr i64, ptr %10, i64 1
    store i64 20, ptr %"1", align 8
    call void @schmu_push_twice(ptr %8, i64 0), !dbg !29
    %11 = load ptr, ptr %8, align 8
    %12 = load i64, ptr %11, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @3, i64 16), i64 %12)
    %13 = alloca i64, align 8
    store i64 0, ptr %13, align 8
    call void @schmu_change_int(ptr %13, i64 0), !dbg !30
    %14 = load i64, ptr %13, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @3, i64 16), i64 %14)
    %15 = alloca ptr, align 8
    %16 = call ptr @malloc(i64 24)
    store ptr %16, ptr %15, align 8
    store i64 0, ptr %16, align 8
    %cap4 = getelementptr i64, ptr %16, i64 1
    store i64 1, ptr %cap4, align 8
    %17 = getelementptr i8, ptr %16, i64 16
    call void @schmu_test(ptr %15, i64 0), !dbg !31
    %18 = load ptr, ptr %15, align 8
    %19 = load i64, ptr %18, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @3, i64 16), i64 %19)
    call void @__free_al_(ptr %15)
    call void @__free_al_(ptr %8)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "tailrec_mutable.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_al_l_", scope: !3, file: !3, line: 15, type: !4, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 19, column: 5, scope: !2)
  !7 = !DILocation(line: 20, column: 7, scope: !2)
  !8 = distinct !DISubprogram(name: "change_int", linkageName: "schmu_change_int", scope: !9, file: !9, line: 58, type: !4, scopeLine: 58, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DIFile(filename: "tailrec_mutable.smu", directory: "")
  !10 = !DILocation(line: 59, column: 5, scope: !8)
  !11 = distinct !DISubprogram(name: "dontmut_bref", linkageName: "schmu_dontmut_bref", scope: !9, file: !9, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 8, column: 5, scope: !11)
  !13 = distinct !DISubprogram(name: "mod_rec", linkageName: "schmu_mod_rec", scope: !9, file: !9, line: 31, type: !4, scopeLine: 31, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = !DILocation(line: 32, column: 5, scope: !13)
  !15 = distinct !DISubprogram(name: "mut_bref", linkageName: "schmu_mut_bref", scope: !9, file: !9, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !16 = !DILocation(line: 4, column: 5, scope: !15)
  !17 = distinct !DISubprogram(name: "push_twice", linkageName: "schmu_push_twice", scope: !9, file: !9, line: 43, type: !4, scopeLine: 43, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = !DILocation(line: 44, column: 5, scope: !17)
  !19 = !DILocation(line: 46, column: 4, scope: !17)
  !20 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !9, file: !9, line: 69, type: !4, scopeLine: 69, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 70, column: 5, scope: !20)
  !22 = !DILocation(line: 73, column: 12, scope: !20)
  !23 = !DILocation(line: 76, column: 12, scope: !20)
  !24 = !DILocation(line: 78, column: 4, scope: !20)
  !25 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !9, file: !9, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !26 = !DILocation(line: 18, scope: !25)
  !27 = !DILocation(line: 23, scope: !25)
  !28 = !DILocation(line: 38, column: 2, scope: !25)
  !29 = !DILocation(line: 53, column: 2, scope: !25)
  !30 = !DILocation(line: 64, column: 2, scope: !25)
  !31 = !DILocation(line: 85, column: 2, scope: !25)
  true
  true
  2
  4
  100
  2

The lamba passed as array-iter argument is polymorphic
  $ schmu polymorphic_lambda_argument.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./polymorphic_lambda_argument
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %option.tc_ = type { i32, i8 }
  
  @schmu_arr = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%li\00" }
  @1 = private unnamed_addr constant { i64, i64, [1 x [1 x i8]] } { i64 0, i64 1, [1 x [1 x i8]] zeroinitializer }
  @2 = private unnamed_addr constant { i64, i64, [3 x i8] } { i64 2, i64 2, [3 x i8] c", \00" }
  
  declare void @string_append(ptr noalias %0, ptr %1)
  
  declare void @string_modify_buf(ptr noalias %0, ptr %1)
  
  declare void @string_println(ptr %0)
  
  define linkonce_odr void @__array_inner__2_Cal_2lru__(i64 %i, ptr %0) !dbg !2 {
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
    tail call void %loadtmp(i64 %3, i64 %6, ptr %loadtmp2), !dbg !7
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr void @__array_iteri_al_2lru__(ptr %arr, ptr %f) !dbg !8 {
  entry:
    %__array_inner__2_Cal_2lru__ = alloca %closure, align 8
    store ptr @__array_inner__2_Cal_2lru__, ptr %__array_inner__2_Cal_2lru__, align 8
    %clsr___array_inner__2_Cal_2lru__ = alloca { ptr, ptr, ptr, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_2lru__, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %f2 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_2lru__, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f2, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_al_2lru2_, ptr %clsr___array_inner__2_Cal_2lru__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_2lru__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__array_inner__2_Cal_2lru__, i32 0, i32 1
    store ptr %clsr___array_inner__2_Cal_2lru__, ptr %envptr, align 8
    call void @__array_inner__2_Cal_2lru__(i64 0, ptr %clsr___array_inner__2_Cal_2lru__), !dbg !9
    ret void
  }
  
  define linkonce_odr i64 @__array_pop_back_ac_rvc__(ptr noalias %arr) !dbg !10 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, 0
    br i1 %eq, label %then, label %else, !dbg !11
  
  then:                                             ; preds = %entry
    %t = alloca %option.tc_, align 8
    store %option.tc_ { i32 0, i8 undef }, ptr %t, align 4
    br label %ifcont
  
  else:                                             ; preds = %entry
    %t1 = alloca %option.tc_, align 8
    store i32 1, ptr %t1, align 4
    %data = getelementptr inbounds %option.tc_, ptr %t1, i32 0, i32 1
    %2 = sub i64 %1, 1
    store i64 %2, ptr %0, align 8
    %3 = getelementptr i8, ptr %0, i64 16
    %4 = getelementptr i8, ptr %3, i64 %2
    %5 = load i8, ptr %4, align 1
    store i8 %5, ptr %data, align 1
    store i8 %5, ptr %data, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %t, %then ], [ %t1, %else ]
    %unbox = load i64, ptr %iftmp, align 8
    ret i64 %unbox
  }
  
  define linkonce_odr void @__array_push_ac_c_(ptr noalias %arr, i8 %value) !dbg !12 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5, !dbg !13
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !14
  
  then2:                                            ; preds = %then
    %3 = tail call ptr @realloc(ptr %0, i64 20)
    store ptr %3, ptr %arr, align 8
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 4, ptr %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %1
    %4 = add i64 %mul, 16
    %5 = tail call ptr @realloc(ptr %0, i64 %4)
    store ptr %5, ptr %arr, align 8
    %newcap3 = getelementptr i64, ptr %5, i64 1
    store i64 %mul, ptr %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %6 = phi ptr [ %5, %else ], [ %3, %then2 ], [ %0, %entry ]
    %7 = getelementptr i8, ptr %6, i64 16
    %8 = getelementptr inbounds i8, ptr %7, i64 %2
    store i8 %value, ptr %8, align 1
    %9 = load ptr, ptr %arr, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %9, align 8
    ret void
  }
  
  define void @__fun_schmu0(ptr noalias %arr) !dbg !15 {
  entry:
    tail call void @__array_push_ac_c_(ptr %arr, i8 0), !dbg !17
    %ret = alloca %option.tc_, align 8
    %0 = tail call i64 @__array_pop_back_ac_rvc__(ptr %arr), !dbg !18
    store i64 %0, ptr %ret, align 8
    ret void
  }
  
  define linkonce_odr void @__fun_schmu1_lCac_ac__(i64 %i, i64 %v, ptr %0) !dbg !19 {
  entry:
    %acc = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    %acc1 = load ptr, ptr %acc, align 8
    %delim = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %0, i32 0, i32 3
    %delim2 = load ptr, ptr %delim, align 8
    %gt = icmp sgt i64 %i, 0
    br i1 %gt, label %then, label %ifcont, !dbg !20
  
  then:                                             ; preds = %entry
    tail call void @string_append(ptr %acc1, ptr %delim2), !dbg !21
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %fmtsize = tail call i32 (ptr, i64, ptr, ...) @snprintf(ptr null, i64 0, ptr getelementptr (i8, ptr @0, i64 16), i64 %v)
    %1 = add i32 %fmtsize, 17
    %2 = sext i32 %1 to i64
    %3 = tail call ptr @malloc(i64 %2)
    %4 = sext i32 %fmtsize to i64
    store i64 %4, ptr %3, align 8
    %cap = getelementptr i64, ptr %3, i64 1
    store i64 %4, ptr %cap, align 8
    %data = getelementptr i64, ptr %3, i64 2
    %fmt = tail call i32 (ptr, i64, ptr, ...) @snprintf(ptr %data, i64 %2, ptr getelementptr (i8, ptr @0, i64 16), i64 %v)
    %str = alloca ptr, align 8
    store ptr %3, ptr %str, align 8
    tail call void @string_append(ptr %acc1, ptr %3), !dbg !22
    call void @__free_ac_(ptr %str)
    ret void
  }
  
  define linkonce_odr ptr @__schmu_string_concat_al__(ptr %arr, ptr %delim) !dbg !23 {
  entry:
    %0 = alloca ptr, align 8
    %1 = alloca ptr, align 8
    store ptr @1, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %1, i64 8, i1 false)
    call void @__copy_ac_(ptr %0)
    %__fun_schmu1_lCac_ac__ = alloca %closure, align 8
    store ptr @__fun_schmu1_lCac_ac__, ptr %__fun_schmu1_lCac_ac__, align 8
    %clsr___fun_schmu1_lCac_ac__ = alloca { ptr, ptr, ptr, ptr }, align 8
    %acc = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %clsr___fun_schmu1_lCac_ac__, i32 0, i32 2
    store ptr %0, ptr %acc, align 8
    %delim1 = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %clsr___fun_schmu1_lCac_ac__, i32 0, i32 3
    store ptr %delim, ptr %delim1, align 8
    store ptr @__ctor_ac_ac2_, ptr %clsr___fun_schmu1_lCac_ac__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %clsr___fun_schmu1_lCac_ac__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu1_lCac_ac__, i32 0, i32 1
    store ptr %clsr___fun_schmu1_lCac_ac__, ptr %envptr, align 8
    call void @__array_iteri_al_2lru__(ptr %arr, ptr %__fun_schmu1_lCac_ac__), !dbg !24
    call void @schmu_string_add_null(ptr %0), !dbg !25
    %2 = load ptr, ptr %0, align 8
    ret ptr %2
  }
  
  define void @schmu_string_add_null(ptr noalias %str) !dbg !26 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @string_modify_buf(ptr %str, ptr %clstmp), !dbg !27
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_al_2lru2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy_al_(ptr %arr)
    %f = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 3
    call void @__copy_2lru_(ptr %f)
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
  
  define linkonce_odr void @__copy_2lru_(ptr %0) {
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
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  declare i32 @snprintf(ptr %0, i64 %1, ptr %2, ...)
  
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
  
  define linkonce_odr ptr @__ctor_ac_ac2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 32)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %acc = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_ac_(ptr %acc)
    %delim = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %1, i32 0, i32 3
    call void @__copy_ac_(ptr %delim)
    ret ptr %1
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !28 {
  entry:
    %0 = tail call ptr @malloc(i64 96)
    store ptr %0, ptr @schmu_arr, align 8
    store i64 10, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 10, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 1, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %"1", align 8
    %"2" = getelementptr i64, ptr %1, i64 2
    store i64 3, ptr %"2", align 8
    %"3" = getelementptr i64, ptr %1, i64 3
    store i64 4, ptr %"3", align 8
    %"4" = getelementptr i64, ptr %1, i64 4
    store i64 5, ptr %"4", align 8
    %"5" = getelementptr i64, ptr %1, i64 5
    store i64 6, ptr %"5", align 8
    %"6" = getelementptr i64, ptr %1, i64 6
    store i64 7, ptr %"6", align 8
    %"7" = getelementptr i64, ptr %1, i64 7
    store i64 8, ptr %"7", align 8
    %"8" = getelementptr i64, ptr %1, i64 8
    store i64 9, ptr %"8", align 8
    %"9" = getelementptr i64, ptr %1, i64 9
    store i64 10, ptr %"9", align 8
    %2 = load ptr, ptr @schmu_arr, align 8
    %3 = tail call ptr @__schmu_string_concat_al__(ptr %2, ptr @2), !dbg !29
    tail call void @string_println(ptr %3), !dbg !30
    %4 = alloca ptr, align 8
    store ptr %3, ptr %4, align 8
    call void @__free_ac_(ptr %4)
    call void @__free_al_(ptr @schmu_arr)
    ret i64 0
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "polymorphic_lambda_argument.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_inner", linkageName: "__array_inner__2_Cal_2lru__", scope: !3, file: !3, line: 45, type: !4, scopeLine: 45, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 46, column: 7, scope: !2)
  !7 = !DILocation(line: 49, column: 6, scope: !2)
  !8 = distinct !DISubprogram(name: "_array_iteri", linkageName: "__array_iteri_al_2lru__", scope: !3, file: !3, line: 44, type: !4, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 54, column: 2, scope: !8)
  !10 = distinct !DISubprogram(name: "_array_pop_back", linkageName: "__array_pop_back_ac_rvc__", scope: !3, file: !3, line: 98, type: !4, scopeLine: 98, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 100, column: 5, scope: !10)
  !12 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_ac_c_", scope: !3, file: !3, line: 15, type: !4, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 19, column: 5, scope: !12)
  !14 = !DILocation(line: 20, column: 7, scope: !12)
  !15 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !16, file: !16, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !16 = !DIFile(filename: "polymorphic_lambda_argument.smu", directory: "")
  !17 = !DILocation(line: 5, column: 4, scope: !15)
  !18 = !DILocation(line: 6, column: 4, scope: !15)
  !19 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1_lCac_ac__", scope: !16, file: !16, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !20 = !DILocation(line: 13, column: 7, scope: !19)
  !21 = !DILocation(line: 13, column: 14, scope: !19)
  !22 = !DILocation(line: 14, column: 4, scope: !19)
  !23 = distinct !DISubprogram(name: "string_concat", linkageName: "__schmu_string_concat_al__", scope: !16, file: !16, line: 10, type: !4, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !24 = !DILocation(line: 12, column: 2, scope: !23)
  !25 = !DILocation(line: 16, column: 2, scope: !23)
  !26 = distinct !DISubprogram(name: "string_add_null", linkageName: "schmu_string_add_null", scope: !16, file: !16, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 4, column: 2, scope: !26)
  !28 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !16, file: !16, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 20, column: 8, scope: !28)
  !30 = !DILocation(line: 20, scope: !28)
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10

Infer type in upward closure
  $ schmu closure_inference.smu && valgrind -q --leak-check=yes --show-reachable=yes ./closure_inference
  ("", "x")
  ("x", "i")
  ("i", "x")

Refcount captured values and destroy correctly
  $ schmu closure_dtor.smu && valgrind -q --leak-check=yes --show-reachable=yes ./closure_dtor
  ++aoeu

Function call returning a polymorphic function
  $ schmu poly_fn_ret_fn.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./poly_fn_ret_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %wrapac_ru__ = type { %closure }
  %closure = type { ptr, ptr }
  
  @schmu_once = global i1 true, align 1
  @schmu_result = global %wrapac_ru__ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"%s foo\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"%s bar\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"a\00" }
  
  define linkonce_odr void @__fun_schmu0_ac__(ptr %a) !dbg !2 {
  entry:
    %0 = getelementptr i8, ptr %a, i64 16
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), ptr %0)
    ret void
  }
  
  define linkonce_odr void @__schmu_bar_ac__(ptr %a) !dbg !6 {
  entry:
    %0 = getelementptr i8, ptr %a, i64 16
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @1, i64 16), ptr %0)
    ret void
  }
  
  define linkonce_odr void @__schmu_black_box_ac_ru_ac_ru_rac_ru__(ptr noalias %0, ptr %f, ptr %g) !dbg !7 {
  entry:
    %1 = load i1, ptr @schmu_once, align 1
    br i1 %1, label %then, label %else, !dbg !8
  
  then:                                             ; preds = %entry
    store i1 false, ptr @schmu_once, align 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %f, i64 16, i1 false)
    tail call void @__copy_ac_ru_(ptr %0)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %g, i64 16, i1 false)
    tail call void @__copy_ac_ru_(ptr %0)
    ret void
  }
  
  declare void @printf(ptr %0, ...)
  
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
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0_ac__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @__schmu_bar_ac__, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    call void @__schmu_black_box_ac_ru_ac_ru_rac_ru__(ptr @schmu_result, ptr %clstmp, ptr %clstmp1), !dbg !10
    %loadtmp = load ptr, ptr @schmu_result, align 8
    %loadtmp4 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_result, i32 0, i32 1), align 8
    call void %loadtmp(ptr @2, ptr %loadtmp4), !dbg !11
    call void @__free_ac_ru2_(ptr @schmu_result)
    ret i64 0
  }
  
  define linkonce_odr void @__free_ac_ru_(ptr %0) {
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
  
  define linkonce_odr void @__free_ac_ru2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_ac_ru_(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "poly_fn_ret_fn.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0_ac__", scope: !3, file: !3, line: 11, type: !4, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "poly_fn_ret_fn.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "bar", linkageName: "__schmu_bar_ac__", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "black_box", linkageName: "__schmu_black_box_ac_ru_ac_ru_rac_ru__", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 6, column: 5, scope: !7)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 16, column: 22, scope: !9)
  !11 = !DILocation(line: 18, column: 1, scope: !9)
  a foo

Check allocations of nested closures
  $ schmu nested_closure_allocs.smu
  $ valgrind ./nested_closure_allocs 2>&1 | grep allocs | cut -f 5- -d '='
   Command: ./nested_closure_allocs
     total heap usage: 8 allocs, 8 frees, 240 bytes allocated

Check that binops with multiple argument works
  $ schmu binop.smu
  $ ./binop
  1
  19

Knuth's man or boy test
  $ schmu man_or_boy.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./man_or_boy
  -67

Local environments must not be freed in self-recursive functions
  $ schmu selfrec_fun_param.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./selfrec_fun_param

Shadowing of names in monomorph pass
  $ schmu shadowing2.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./shadowing2

Upward closures are moved closures
  $ schmu closure_move_upward.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./closure_move_upward
  on iteration: 0
  on iteration: 1
  on iteration: 2
  on iteration: 3
  on iteration: 4
  on iteration: 5
  on iteration: 6
  on iteration: 7
  on iteration: 8
  on iteration: 9

Only direct recursive calls count as recursive
  $ schmu nested_recursive.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./nested_recursive
  heya
  none

Failwith function
  $ schmu failwith.smu
  $ ret=$(./failwith 2> err) 2> /dev/null
  [134]
  $ echo $ret
  
  $ cat err | grep false
  failwith: i'm false

Monomorphize functions as variables
  $ schmu monomorph_variable.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./monomorph_variable
  0
  0
