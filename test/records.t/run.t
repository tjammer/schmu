Compile stubs
  $ cc -c stub.c

Simple record creation (out of order)
  $ schmu --dump-llvm stub.o simple.smu && ./simple
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo_ = type { i1, i64 }
  
  @schmu_a = constant %foo_ { i1 true, i64 10 }
  
  declare void @printi(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    tail call void @printi(i64 10), !dbg !6
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "simple.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "simple.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 7, scope: !2)
  10

Pass record to function
  $ schmu --dump-llvm stub.o pass.smu && ./pass
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo_ = type { i64, i64 }
  
  @schmu_a = constant %foo_ { i64 10, i64 20 }
  
  declare void @printi(i64 %0)
  
  define void @schmu_pass_to_func(i64 %0, i64 %1) !dbg !2 {
  entry:
    %a = alloca { i64, i64 }, align 8
    store i64 %0, ptr %a, align 8
    %snd = getelementptr inbounds { i64, i64 }, ptr %a, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    tail call void @printi(i64 %1), !dbg !6
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    tail call void @schmu_pass_to_func(i64 10, i64 20), !dbg !8
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "pass.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "pass_to_func", linkageName: "schmu_pass_to_func", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "pass.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 5, column: 21, scope: !2)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 8, scope: !7)
  20


Create record
  $ schmu --dump-llvm stub.o create.smu && ./create
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo_ = type { i64, i64 }
  
  declare void @printi(i64 %0)
  
  define { i64, i64 } @schmu_create_record(i64 %x, i64 %y) !dbg !2 {
  entry:
    %0 = alloca %foo_, align 8
    store i64 %x, ptr %0, align 8
    %y2 = getelementptr inbounds %foo_, ptr %0, i32 0, i32 1
    store i64 %y, ptr %y2, align 8
    %unbox = load { i64, i64 }, ptr %0, align 8
    ret { i64, i64 } %unbox
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    %ret = alloca %foo_, align 8
    %0 = tail call { i64, i64 } @schmu_create_record(i64 8, i64 0), !dbg !7
    store { i64, i64 } %0, ptr %ret, align 8
    %1 = load i64, ptr %ret, align 8
    tail call void @printi(i64 %1), !dbg !8
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "create.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "create_record", linkageName: "schmu_create_record", scope: !3, file: !3, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "create.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 5, column: 7, scope: !6)
  !8 = !DILocation(line: 5, scope: !6)
  8

Nested records
  $ schmu --dump-llvm stub.o nested.smu && ./nested
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo_ = type { i64, %inner_ }
  %inner_ = type { i64 }
  %tl_ = type { i64, %p_innerl__ }
  %p_innerl__ = type { %innerstl_ }
  %innerstl_ = type { i64 }
  
  @schmu_a = global %foo_ zeroinitializer, align 8
  
  declare void @printi(i64 %0)
  
  define linkonce_odr { i64, i64 } @__fun_schmu0_2l3_r2l3__(i64 %0, i64 %1) !dbg !2 {
  entry:
    %x = alloca { i64, i64 }, align 8
    store i64 %0, ptr %x, align 8
    %snd = getelementptr inbounds { i64, i64 }, ptr %x, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %unbox = load { i64, i64 }, ptr %x, align 8
    ret { i64, i64 } %unbox
  }
  
  define i64 @schmu_inner() !dbg !6 {
  entry:
    %0 = alloca %inner_, align 8
    store %inner_ { i64 3 }, ptr %0, align 8
    %unbox = load i64, ptr %0, align 8
    ret i64 %unbox
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    store i64 0, ptr @schmu_a, align 8
    %0 = tail call i64 @schmu_inner(), !dbg !8
    store i64 %0, ptr getelementptr inbounds (%foo_, ptr @schmu_a, i32 0, i32 1), align 8
    tail call void @printi(i64 %0), !dbg !9
    %boxconst = alloca %tl_, align 8
    store %tl_ { i64 17, %p_innerl__ { %innerstl_ { i64 124 } } }, ptr %boxconst, align 8
    %fst1 = load i64, ptr %boxconst, align 8
    %snd = getelementptr inbounds { i64, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %ret = alloca %tl_, align 8
    %1 = tail call { i64, i64 } @__fun_schmu0_2l3_r2l3__(i64 %fst1, i64 %snd2), !dbg !10
    store { i64, i64 } %1, ptr %ret, align 8
    %2 = getelementptr inbounds %tl_, ptr %ret, i32 0, i32 1
    %3 = load i64, ptr %2, align 8
    tail call void @printi(i64 %3), !dbg !11
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "nested.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0_2l3_r2l3__", scope: !3, file: !3, line: 14, type: !4, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "nested.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "inner", linkageName: "schmu_inner", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 16, column: 21, scope: !7)
  !9 = !DILocation(line: 17, scope: !7)
  !10 = !DILocation(line: 18, column: 7, scope: !7)
  !11 = !DILocation(line: 18, scope: !7)
  3
  124

Pass generic record
  $ schmu --dump-llvm stub.o parametrized_pass.smu && ./parametrized_pass
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %tl_ = type { i64, i64, i1 }
  %closure = type { ptr, ptr }
  %tb_ = type { i64, i1, i1 }
  
  @schmu_int_t = constant %tl_ { i64 700, i64 20, i1 false }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr void @__schmu_apply_2lb_r2lb2_2lb_r2lb__(ptr noalias %0, ptr %f, ptr %x) !dbg !2 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %0, ptr %x, ptr %loadtmp1), !dbg !6
    ret void
  }
  
  define linkonce_odr { i64, i16 } @__schmu_apply_l2b_rl2b2_l2b_rl2b__(ptr %f, i64 %0, i16 %1) !dbg !7 {
  entry:
    %x = alloca { i64, i16 }, align 8
    store i64 %0, ptr %x, align 8
    %snd = getelementptr inbounds { i64, i16 }, ptr %x, i32 0, i32 1
    store i16 %1, ptr %snd, align 2
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp5 = load ptr, ptr %envptr, align 8
    %ret = alloca %tb_, align 8
    %2 = tail call { i64, i16 } %loadtmp(i64 %0, i16 %1, ptr %loadtmp5), !dbg !8
    store { i64, i16 } %2, ptr %ret, align 8
    ret { i64, i16 } %2
  }
  
  define linkonce_odr void @__schmu_pass_2lb_r2lb__(ptr noalias %0, ptr %x) !dbg !9 {
  entry:
    %1 = alloca %tl_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %x, i64 24, i1 false)
    %2 = load i64, ptr %1, align 8
    store i64 %2, ptr %0, align 8
    %gen = getelementptr inbounds %tl_, ptr %0, i32 0, i32 1
    %3 = getelementptr inbounds %tl_, ptr %1, i32 0, i32 1
    %4 = load i64, ptr %3, align 8
    store i64 %4, ptr %gen, align 8
    %third = getelementptr inbounds %tl_, ptr %0, i32 0, i32 2
    %5 = getelementptr inbounds %tl_, ptr %1, i32 0, i32 2
    %6 = load i1, ptr %5, align 1
    store i1 %6, ptr %third, align 1
    ret void
  }
  
  define linkonce_odr { i64, i16 } @__schmu_pass_l2b_rl2b__(i64 %0, i16 %1) !dbg !10 {
  entry:
    %x = alloca { i64, i16 }, align 8
    store i64 %0, ptr %x, align 8
    %snd = getelementptr inbounds { i64, i16 }, ptr %x, i32 0, i32 1
    store i16 %1, ptr %snd, align 2
    %2 = alloca %tb_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %x, i64 16, i1 false)
    %3 = alloca %tb_, align 8
    %4 = load i64, ptr %2, align 8
    store i64 %4, ptr %3, align 8
    %gen = getelementptr inbounds %tb_, ptr %3, i32 0, i32 1
    %5 = getelementptr inbounds %tb_, ptr %2, i32 0, i32 1
    %6 = load i1, ptr %5, align 1
    store i1 %6, ptr %gen, align 1
    %third = getelementptr inbounds %tb_, ptr %3, i32 0, i32 2
    %7 = getelementptr inbounds %tb_, ptr %2, i32 0, i32 2
    %8 = load i1, ptr %7, align 1
    store i1 %8, ptr %third, align 1
    %unbox = load { i64, i16 }, ptr %3, align 8
    ret { i64, i16 } %unbox
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__schmu_pass_2lb_r2lb__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %ret = alloca %tl_, align 8
    call void @__schmu_apply_2lb_r2lb2_2lb_r2lb__(ptr %ret, ptr %clstmp, ptr @schmu_int_t), !dbg !12
    %0 = load i64, ptr %ret, align 8
    call void @printi(i64 %0), !dbg !13
    %clstmp1 = alloca %closure, align 8
    store ptr @__schmu_pass_l2b_rl2b__, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %boxconst = alloca %tb_, align 8
    store %tb_ { i64 234, i1 false, i1 true }, ptr %boxconst, align 8
    %fst4 = load i64, ptr %boxconst, align 8
    %snd = getelementptr inbounds { i64, i16 }, ptr %boxconst, i32 0, i32 1
    %snd5 = load i16, ptr %snd, align 2
    %ret6 = alloca %tb_, align 8
    %1 = call { i64, i16 } @__schmu_apply_l2b_rl2b2_l2b_rl2b__(ptr %clstmp1, i64 %fst4, i16 %snd5), !dbg !14
    store { i64, i16 } %1, ptr %ret6, align 8
    %2 = load i64, ptr %ret6, align 8
    call void @printi(i64 %2), !dbg !15
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "parametrized_pass.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_2lb_r2lb2_2lb_r2lb__", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "parametrized_pass.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 5, column: 35, scope: !2)
  !7 = distinct !DISubprogram(name: "apply", linkageName: "__schmu_apply_l2b_rl2b2_l2b_rl2b__", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 5, column: 35, scope: !7)
  !9 = distinct !DISubprogram(name: "pass", linkageName: "__schmu_pass_2lb_r2lb__", scope: !3, file: !3, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = distinct !DISubprogram(name: "pass", linkageName: "__schmu_pass_l2b_rl2b__", scope: !3, file: !3, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 15, column: 7, scope: !11)
  !13 = !DILocation(line: 15, scope: !11)
  !14 = !DILocation(line: 16, column: 7, scope: !11)
  !15 = !DILocation(line: 16, scope: !11)
  700
  234

Access parametrized record fields
  $ schmu --dump-llvm stub.o parametrized_get.smu && ./parametrized_get
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %tl_ = type { i64, i64, i64, i1 }
  %gen_firstl_ = type { i64, i1 }
  
  @schmu_int_t = constant %tl_ { i64 0, i64 700, i64 20, i1 true }
  @schmu_f = constant %gen_firstl_ { i64 420, i1 false }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr void @__schmu_first_3lb__(ptr %any) !dbg !2 {
  entry:
    %0 = getelementptr inbounds %tl_, ptr %any, i32 0, i32 1
    %1 = load i64, ptr %0, align 8
    tail call void @printi(i64 %1), !dbg !6
    ret void
  }
  
  define linkonce_odr i64 @__schmu_gen_3lb_rl_(ptr %any) !dbg !7 {
  entry:
    %0 = getelementptr inbounds %tl_, ptr %any, i32 0, i32 2
    %1 = alloca i64, align 8
    %2 = load i64, ptr %0, align 8
    store i64 %2, ptr %1, align 8
    ret i64 %2
  }
  
  define linkonce_odr void @__schmu_is_lb__(i64 %0, i8 %1) !dbg !8 {
  entry:
    %any = alloca { i64, i8 }, align 8
    store i64 %0, ptr %any, align 8
    %snd = getelementptr inbounds { i64, i8 }, ptr %any, i32 0, i32 1
    store i8 %1, ptr %snd, align 1
    %2 = trunc i8 %1 to i1
    tail call void @schmu_print_bool(i1 %2), !dbg !9
    ret void
  }
  
  define linkonce_odr i64 @__schmu_only_lb_rl_(i64 %0, i8 %1) !dbg !10 {
  entry:
    %any = alloca { i64, i8 }, align 8
    store i64 %0, ptr %any, align 8
    %snd = getelementptr inbounds { i64, i8 }, ptr %any, i32 0, i32 1
    store i8 %1, ptr %snd, align 1
    %2 = alloca i64, align 8
    store i64 %0, ptr %2, align 8
    ret i64 %0
  }
  
  define linkonce_odr void @__schmu_third_3lb__(ptr %any) !dbg !11 {
  entry:
    %0 = getelementptr inbounds %tl_, ptr %any, i32 0, i32 3
    %1 = load i1, ptr %0, align 1
    tail call void @schmu_print_bool(i1 %1), !dbg !12
    ret void
  }
  
  define void @schmu_print_bool(i1 %b) !dbg !13 {
  entry:
    br i1 %b, label %then, label %else, !dbg !14
  
  then:                                             ; preds = %entry
    tail call void @printi(i64 1), !dbg !15
    ret void
  
  else:                                             ; preds = %entry
    tail call void @printi(i64 0), !dbg !16
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !17 {
  entry:
    tail call void @__schmu_first_3lb__(ptr @schmu_int_t), !dbg !18
    tail call void @__schmu_third_3lb__(ptr @schmu_int_t), !dbg !19
    %0 = tail call i64 @__schmu_gen_3lb_rl_(ptr @schmu_int_t), !dbg !20
    tail call void @printi(i64 %0), !dbg !21
    %snd = load i8, ptr getelementptr inbounds ({ i64, i8 }, ptr @schmu_f, i32 0, i32 1), align 1
    %1 = tail call i64 @__schmu_only_lb_rl_(i64 420, i8 %snd), !dbg !22
    tail call void @printi(i64 %1), !dbg !23
    tail call void @__schmu_is_lb__(i64 420, i8 %snd), !dbg !24
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "parametrized_get.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "first", linkageName: "__schmu_first_3lb__", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "parametrized_get.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 10, column: 2, scope: !2)
  !7 = distinct !DISubprogram(name: "gen", linkageName: "__schmu_gen_3lb_rl_", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = distinct !DISubprogram(name: "is", linkageName: "__schmu_is_lb__", scope: !3, file: !3, line: 18, type: !4, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 18, column: 13, scope: !8)
  !10 = distinct !DISubprogram(name: "only", linkageName: "__schmu_only_lb_rl_", scope: !3, file: !3, line: 16, type: !4, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = distinct !DISubprogram(name: "third", linkageName: "__schmu_third_3lb__", scope: !3, file: !3, line: 14, type: !4, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 14, column: 16, scope: !11)
  !13 = distinct !DISubprogram(name: "print_bool", linkageName: "schmu_print_bool", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = !DILocation(line: 7, column: 5, scope: !13)
  !15 = !DILocation(line: 7, column: 8, scope: !13)
  !16 = !DILocation(line: 7, column: 25, scope: !13)
  !17 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = !DILocation(line: 23, scope: !17)
  !19 = !DILocation(line: 24, scope: !17)
  !20 = !DILocation(line: 25, column: 7, scope: !17)
  !21 = !DILocation(line: 25, scope: !17)
  !22 = !DILocation(line: 26, column: 7, scope: !17)
  !23 = !DILocation(line: 26, scope: !17)
  !24 = !DILocation(line: 27, scope: !17)
  700
  1
  20
  420
  0

Make sure alignment of generic param works
  $ schmu --dump-llvm stub.o misaligned_get.smu && ./misaligned_get
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %misalignedl_ = type { %inner_, i64 }
  %inner_ = type { i64, i64 }
  
  @schmu_m = constant %misalignedl_ { %inner_ { i64 50, i64 40 }, i64 30 }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__schmu_gen_2l_l_rl_(ptr %any) !dbg !2 {
  entry:
    %0 = getelementptr inbounds %misalignedl_, ptr %any, i32 0, i32 1
    %1 = alloca i64, align 8
    %2 = load i64, ptr %0, align 8
    store i64 %2, ptr %1, align 8
    ret i64 %2
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    %0 = tail call i64 @__schmu_gen_2l_l_rl_(ptr @schmu_m), !dbg !7
    tail call void @printi(i64 %0), !dbg !8
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "misaligned_get.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "gen", linkageName: "__schmu_gen_2l_l_rl_", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "misaligned_get.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 9, column: 7, scope: !6)
  !8 = !DILocation(line: 9, scope: !6)
  30

Parametrization needs to be given, if a type is generic
  $ schmu --dump-llvm stub.o missing_parameter.smu && ./missing_parameter
  missing_parameter.smu:5.10-11: error: Type t expects 1 type parameter.
  
  5 | fun (t : t): t.t
               ^
  
  [1]

Support function/closure fields
  $ schmu --dump-llvm stub.o function_fields.smu && valgrind -q --leak-check=yes --show-reachable=yes ./function_fields
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %state_ = type { i64, %closure }
  %closure = type { ptr, ptr }
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @__fun_schmu0(i64 %x) !dbg !2 {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define void @schmu_advance(ptr noalias %0, ptr %state) !dbg !6 {
  entry:
    %1 = getelementptr inbounds %state_, ptr %state, i32 0, i32 1
    %2 = load i64, ptr %state, align 8
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %3 = tail call i64 %loadtmp(i64 %2, ptr %loadtmp1), !dbg !7
    store i64 %3, ptr %0, align 8
    %next = getelementptr inbounds %state_, ptr %0, i32 0, i32 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %next, ptr align 1 %1, i64 16, i1 false)
    ret void
  }
  
  define void @schmu_ten_times(ptr %state) !dbg !8 {
  entry:
    %0 = alloca %state_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 1 %state, i64 24, i1 false)
    %1 = alloca i1, align 1
    store i1 false, ptr %1, align 1
    %ret = alloca %state_, align 8
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %2 = load i64, ptr %0, align 8
    %lt = icmp slt i64 %2, 10
    br i1 %lt, label %then, label %else, !dbg !9
  
  then:                                             ; preds = %rec
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %2)
    call void @schmu_advance(ptr %ret, ptr %0), !dbg !10
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %ret, i64 24, i1 false)
    br label %rec
  
  else:                                             ; preds = %rec
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 100)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(ptr %0, ...)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    %0 = alloca %state_, align 8
    store i64 0, ptr %0, align 8
    %next = getelementptr inbounds %state_, ptr %0, i32 0, i32 1
    store ptr @__fun_schmu0, ptr %next, align 8
    %envptr = getelementptr inbounds %closure, ptr %next, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @schmu_ten_times(ptr %0), !dbg !12
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "function_fields.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !3, file: !3, line: 15, type: !4, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "function_fields.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "advance", linkageName: "schmu_advance", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 4, column: 10, scope: !6)
  !8 = distinct !DISubprogram(name: "ten_times", linkageName: "schmu_ten_times", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 7, column: 5, scope: !8)
  !10 = !DILocation(line: 9, column: 15, scope: !8)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 16, column: 2, scope: !11)
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
  100

Regression test: Closures for records used to use store/load like for register values
  $ schmu --dump-llvm stub.o closure.smu && ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo_ = type { i64, i64 }
  
  @schmu_foo = constant %foo_ { i64 12, i64 14 }
  
  declare void @printi(i64 %0)
  
  define void @schmu_print_foo() !dbg !2 {
  entry:
    tail call void @printi(i64 12), !dbg !6
    tail call void @printi(i64 14), !dbg !7
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !8 {
  entry:
    tail call void @schmu_print_foo(), !dbg !9
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "closure.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "print_foo", linkageName: "schmu_print_foo", scope: !3, file: !3, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "closure.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 6, column: 2, scope: !2)
  !7 = !DILocation(line: 7, column: 2, scope: !2)
  !8 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 9, scope: !8)
  12
  14

Regression test: Return allocas were propagated by lets to values earlier in a function.
This caused stores to a wrong pointer type in LLVM
  $ schmu --dump-llvm stub.o nested_init_let.smu && ./nested_init_let
  nested_init_let.smu:12.9-10: warning: Unused binding a.
  
  12 |     let a = {y = {x = 1}, z = 2}
               ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo_ = type { i64 }
  %ys_ = type { %foo_, i64 }
  
  @schmu_x = internal constant %foo_ { i64 12 }
  @schmu_ret = internal constant %ys_ { %foo_ { i64 17 }, i64 9 }
  @schmu_a = internal constant %ys_ { %foo_ { i64 1 }, i64 2 }
  @schmu_ys = global %ys_ zeroinitializer, align 8
  @schmu_ctrl__2 = global %ys_ zeroinitializer, align 8
  
  declare void @printi(i64 %0)
  
  define { i64, i64 } @schmu_ctrl() !dbg !2 {
  entry:
    %unbox = load { i64, i64 }, ptr @schmu_ret, align 8
    ret { i64, i64 } %unbox
  }
  
  define { i64, i64 } @schmu_record_with_laters() !dbg !6 {
  entry:
    %0 = alloca %ys_, align 8
    store %ys_ { %foo_ { i64 12 }, i64 15 }, ptr %0, align 8
    %unbox = load { i64, i64 }, ptr %0, align 8
    ret { i64, i64 } %unbox
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    %0 = tail call { i64, i64 } @schmu_record_with_laters(), !dbg !8
    store { i64, i64 } %0, ptr @schmu_ys, align 8
    %1 = load i64, ptr getelementptr inbounds (%ys_, ptr @schmu_ys, i32 0, i32 1), align 8
    tail call void @printi(i64 %1), !dbg !9
    %2 = load i64, ptr @schmu_ys, align 8
    tail call void @printi(i64 %2), !dbg !10
    %3 = tail call { i64, i64 } @schmu_ctrl(), !dbg !11
    store { i64, i64 } %3, ptr @schmu_ctrl__2, align 8
    %4 = load i64, ptr @schmu_ctrl__2, align 8
    tail call void @printi(i64 %4), !dbg !12
    %5 = load i64, ptr getelementptr inbounds (%ys_, ptr @schmu_ctrl__2, i32 0, i32 1), align 8
    tail call void @printi(i64 %5), !dbg !13
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "nested_init_let.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "ctrl", linkageName: "schmu_ctrl", scope: !3, file: !3, line: 10, type: !4, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "nested_init_let.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "record_with_laters", linkageName: "schmu_record_with_laters", scope: !3, file: !3, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 15, column: 9, scope: !7)
  !9 = !DILocation(line: 16, scope: !7)
  !10 = !DILocation(line: 17, scope: !7)
  !11 = !DILocation(line: 19, column: 11, scope: !7)
  !12 = !DILocation(line: 20, scope: !7)
  !13 = !DILocation(line: 21, scope: !7)
  15
  12
  17
  9

A return of a field should not be preallocated
  $ schmu --dump-llvm stub.o nested_prealloc.smu && ./nested_prealloc
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %test3l__ = type { %int_wrap_ }
  %int_wrap_ = type { i64, i64, i64 }
  %mut3l__ = type { %int_wrap_ }
  %closure = type { ptr, ptr }
  
  @schmu_test = internal constant %test3l__ { %int_wrap_ { i64 2, i64 0, i64 0 } }
  
  declare void @printi(i64 %0)
  
  define void @schmu_test_thing(ptr noalias %0) !dbg !2 {
  entry:
    tail call void @schmu_vector_loop(ptr %0, i64 0), !dbg !6
    ret void
  }
  
  define void @schmu_test_thing_mut(ptr noalias %0) !dbg !7 {
  entry:
    %1 = alloca %mut3l__, align 8
    store %int_wrap_ { i64 2, i64 0, i64 0 }, ptr %1, align 8
    %schmu_vector_loop__2 = alloca %closure, align 8
    store ptr @schmu_vector_loop__2, ptr %schmu_vector_loop__2, align 8
    %clsr_schmu_vector_loop__2 = alloca { ptr, ptr, ptr }, align 8
    %test = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr_schmu_vector_loop__2, i32 0, i32 2
    store ptr %1, ptr %test, align 8
    store ptr @__ctor_3l3_, ptr %clsr_schmu_vector_loop__2, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr_schmu_vector_loop__2, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %schmu_vector_loop__2, i32 0, i32 1
    store ptr %clsr_schmu_vector_loop__2, ptr %envptr, align 8
    call void @schmu_vector_loop__2(i64 0, ptr %clsr_schmu_vector_loop__2), !dbg !8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    ret void
  }
  
  define void @schmu_vector_loop(ptr noalias %0, i64 %i) !dbg !9 {
  entry:
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 11
    br i1 %eq, label %then, label %else, !dbg !10
  
  then:                                             ; preds = %rec
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 16 @schmu_test, i64 24, i1 false)
    ret void
  
  else:                                             ; preds = %rec
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_vector_loop__2(i64 %i, ptr %0) !dbg !11 {
  entry:
    %test = getelementptr inbounds { ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    %test1 = load ptr, ptr %test, align 8
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = alloca %int_wrap_, align 8
    %3 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %3, %entry ]
    %eq = icmp eq i64 %lsr.iv, 11
    br i1 %eq, label %then, label %else, !dbg !12
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %4 = load i64, ptr %test1, align 8
    %add = add i64 %4, 1
    store i64 %add, ptr %2, align 8
    %b = getelementptr inbounds %int_wrap_, ptr %2, i32 0, i32 1
    store i64 0, ptr %b, align 8
    %c = getelementptr inbounds %int_wrap_, ptr %2, i32 0, i32 2
    store i64 0, ptr %c, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %test1, ptr align 8 %2, i64 24, i1 false)
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr ptr @__ctor_3l3_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !13 {
  entry:
    %ret = alloca %int_wrap_, align 8
    call void @schmu_test_thing(ptr %ret), !dbg !14
    %0 = load i64, ptr %ret, align 8
    call void @printi(i64 %0), !dbg !15
    %ret1 = alloca %int_wrap_, align 8
    call void @schmu_test_thing_mut(ptr %ret1), !dbg !16
    %1 = load i64, ptr %ret1, align 8
    call void @printi(i64 %1), !dbg !17
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "nested_prealloc.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "test_thing", linkageName: "schmu_test_thing", scope: !3, file: !3, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "nested_prealloc.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 12, column: 4, scope: !2)
  !7 = distinct !DISubprogram(name: "test_thing_mut", linkageName: "schmu_test_thing_mut", scope: !3, file: !3, line: 14, type: !4, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 21, column: 4, scope: !7)
  !9 = distinct !DISubprogram(name: "vector_loop", linkageName: "schmu_vector_loop", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 10, column: 11, scope: !9)
  !11 = distinct !DISubprogram(name: "vector_loop", linkageName: "schmu_vector_loop__2", scope: !3, file: !3, line: 16, type: !4, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 17, column: 11, scope: !11)
  !13 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = !DILocation(line: 24, scope: !13)
  !15 = !DILocation(line: 24, column: 17, scope: !13)
  !16 = !DILocation(line: 25, scope: !13)
  !17 = !DILocation(line: 25, column: 21, scope: !13)
  2
  12

Free nested records
  $ schmu free_nested.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./free_nested

Free missing record fields
  $ schmu free_missing_fields.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./free_missing_fields
