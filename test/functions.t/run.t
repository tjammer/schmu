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
  
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  define linkonce_odr void @__array_fixed_swap_items_A64c__(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
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
  
  define linkonce_odr void @__fmt_endl_upc_lru_u_ru_(ptr %p) !dbg !7 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !9
    call void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %ret), !dbg !10
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %fm) !dbg !11 {
  entry:
    tail call void @__free_except1_upc_lru_u_(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !12 {
  entry:
    %1 = alloca %fmt.formatter.tu_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !13
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !14 {
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
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 1), !dbg !16
    br label %ifcont
  
  else:                                             ; preds = %cont
    %fmt_aux = alloca %closure, align 8
    store ptr @fmt_aux, ptr %fmt_aux, align 8
    %clsr_fmt_aux = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr, align 8
    %base1 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 3
    store i64 %base, ptr %base1, align 8
    store ptr @__ctor_A64c_l_, ptr %clsr_fmt_aux, align 8
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
    store ptr @__ctor_A64c_l_, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !18
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !19
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i64 %i) !dbg !20 {
  entry:
    tail call void @__fmt_int_base_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, i64 %i, i64 10), !dbg !21
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.tu_, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret2), !dbg !25
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !26 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64c__(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !28 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !29
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !30
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !31
    br i1 %lt, label %then4, label %ifcont, !dbg !31
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_fib(i64 %n) !dbg !32 {
  entry:
    br label %tailrecurse, !dbg !34
  
  tailrecurse:                                      ; preds = %else, %entry
    %accumulator.tr = phi i64 [ 0, %entry ], [ %add, %else ]
    %n.tr = phi i64 [ %n, %entry ], [ %2, %else ]
    %lt = icmp slt i64 %n.tr, 2
    br i1 %lt, label %then, label %else, !dbg !35
  
  then:                                             ; preds = %tailrecurse
    %accumulator.ret.tr = add i64 %n.tr, %accumulator.tr
    ret i64 %accumulator.ret.tr
  
  else:                                             ; preds = %tailrecurse
    %0 = add i64 %n.tr, -1, !dbg !36
    %1 = tail call i64 @schmu_fib(i64 %0), !dbg !36
    %add = add i64 %1, %accumulator.tr
    %2 = add i64 %0, -1, !dbg !34
    br label %tailrecurse, !dbg !34
  }
  
  define linkonce_odr void @__free_upc_lru_(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_upc_lru_u_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_upc_lru_(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_A64c_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !37 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = tail call i64 @schmu_fib(i64 30), !dbg !38
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %0), !dbg !39
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "a.out.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !8, file: !8, line: 130, type: !4, scopeLine: 130, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DIFile(filename: "fmt.smu", directory: "")
  !9 = !DILocation(line: 132, column: 2, scope: !7)
  !10 = !DILocation(line: 133, column: 15, scope: !7)
  !11 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !8, file: !8, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 22, column: 4, scope: !12)
  !14 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 54, type: !4, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 56, column: 6, scope: !14)
  !16 = !DILocation(line: 57, column: 4, scope: !14)
  !17 = !DILocation(line: 74, column: 17, scope: !14)
  !18 = !DILocation(line: 77, column: 4, scope: !14)
  !19 = !DILocation(line: 81, column: 4, scope: !14)
  !20 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 109, type: !4, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 110, column: 2, scope: !20)
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_", scope: !8, file: !8, line: 220, type: !4, scopeLine: 220, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 221, column: 9, scope: !22)
  !24 = !DILocation(line: 221, column: 4, scope: !22)
  !25 = !DILocation(line: 221, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 77, type: !4, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 78, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 63, column: 21, scope: !28)
  !30 = !DILocation(line: 64, column: 10, scope: !28)
  !31 = !DILocation(line: 67, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "fib", linkageName: "schmu_fib", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "fib.smu", directory: "")
  !34 = !DILocation(line: 3, column: 21, scope: !32)
  !35 = !DILocation(line: 2, column: 5, scope: !32)
  !36 = !DILocation(line: 3, column: 8, scope: !32)
  !37 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 6, column: 18, scope: !37)
  !39 = !DILocation(line: 6, column: 5, scope: !37)
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
  !19 = !DILocation(line: 21, column: 18, scope: !17)
  !20 = !DILocation(line: 22, scope: !17)
  !21 = !DILocation(line: 22, column: 27, scope: !17)
  !22 = !DILocation(line: 23, column: 8, scope: !17)
  !23 = !DILocation(line: 23, column: 28, scope: !17)
  !24 = !DILocation(line: 23, column: 43, scope: !17)
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
  !38 = !DILocation(line: 52, column: 7, scope: !25)
  !39 = !DILocation(line: 52, column: 27, scope: !25)
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
  !15 = !DILocation(line: 9, column: 41, scope: !11)
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
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_al_l_", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 34, column: 5, scope: !2)
  !7 = !DILocation(line: 35, column: 7, scope: !2)
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
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  %r_ = type { i64 }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_rf = global %bref_ zeroinitializer, align 1
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"true\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"false\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  define linkonce_odr void @__array_fixed_swap_items_A64c__(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
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
  
  define linkonce_odr void @__fmt_bool_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i1 %b) !dbg !10 {
  entry:
    br i1 %b, label %then, label %else, !dbg !12
  
  then:                                             ; preds = %entry
    tail call void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr @0), !dbg !13
    ret void
  
  else:                                             ; preds = %entry
    tail call void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr @1), !dbg !14
    ret void
  }
  
  define linkonce_odr void @__fmt_endl_upc_lru_u_ru_(ptr %p) !dbg !15 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !16
    call void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %ret), !dbg !17
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %fm) !dbg !18 {
  entry:
    tail call void @__free_except1_upc_lru_u_(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !19 {
  entry:
    %1 = alloca %fmt.formatter.tu_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !20
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !21 {
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
    br i1 %andtmp, label %then, label %else, !dbg !22
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 1), !dbg !23
    br label %ifcont
  
  else:                                             ; preds = %cont
    %fmt_aux = alloca %closure, align 8
    store ptr @fmt_aux, ptr %fmt_aux, align 8
    %clsr_fmt_aux = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr, align 8
    %base1 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 3
    store i64 %base, ptr %base1, align 8
    store ptr @__ctor_A64c_l_, ptr %clsr_fmt_aux, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt_aux, i32 0, i32 1
    store ptr %clsr_fmt_aux, ptr %envptr, align 8
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !24
    %add = add i64 %2, 1
    %div = sdiv i64 %add, 2
    %__fun_fmt2 = alloca %closure, align 8
    store ptr @__fun_fmt2, ptr %__fun_fmt2, align 8
    %clsr___fun_fmt2 = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr5 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr5, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 3
    store i64 %add, ptr %_fmt_length, align 8
    store ptr @__ctor_A64c_l_, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !25
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !26
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i64 %i) !dbg !27 {
  entry:
    tail call void @__fmt_int_base_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, i64 %i, i64 10), !dbg !28
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_upc_lru_u_brupc_lru_u2_b_(ptr %fmt, i1 %value) !dbg !29 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !30
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.tu_, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i1 %value, ptr %loadtmp1), !dbg !31
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret2), !dbg !32
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %fmt, i64 %value) !dbg !33 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !34
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.tu_, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !35
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret2), !dbg !36
    ret void
  }
  
  define linkonce_odr void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, ptr %str) !dbg !37 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !38
    %2 = tail call i64 @string_len(ptr %str), !dbg !39
    tail call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !40
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !41 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64c__(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !42
    ret void
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
  
  define void @schmu_change_int(ptr noalias %i, i64 %j) !dbg !47 {
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
    br i1 %eq, label %then, label %else, !dbg !49
  
  then:                                             ; preds = %rec
    store i64 100, ptr %i, align 8
    ret void
  
  else:                                             ; preds = %rec
    store ptr %i, ptr %0, align 8
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_dontmut_bref(i64 %i, ptr noalias %rf) !dbg !50 {
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
    br i1 %gt, label %then, label %else, !dbg !51
  
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
  
  define void @schmu_mod_rec(ptr noalias %r, i64 %i) !dbg !52 {
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
    br i1 %eq, label %then, label %else, !dbg !53
  
  then:                                             ; preds = %rec
    store i64 2, ptr %r, align 8
    ret void
  
  else:                                             ; preds = %rec
    store ptr %r, ptr %0, align 8
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_mut_bref(i64 %i, ptr noalias %rf) !dbg !54 {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, ptr %0, align 8
    %1 = alloca ptr, align 8
    store ptr %rf, ptr %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %gt = icmp sgt i64 %2, 0
    br i1 %gt, label %then, label %else, !dbg !55
  
  then:                                             ; preds = %rec
    store i1 true, ptr %rf, align 1
    ret void
  
  else:                                             ; preds = %rec
    %add = add i64 %2, 1
    store i64 %add, ptr %0, align 8
    store ptr %rf, ptr %1, align 8
    br label %rec
  }
  
  define void @schmu_push_twice(ptr noalias %a, i64 %i) !dbg !56 {
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
    br i1 %eq, label %then, label %else, !dbg !57
  
  then:                                             ; preds = %rec
    store i1 true, ptr %1, align 1
    ret void
  
  else:                                             ; preds = %rec
    tail call void @__array_push_al_l_(ptr %a, i64 20), !dbg !58
    store ptr %a, ptr %0, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(ptr noalias %a, i64 %i) !dbg !59 {
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
    %5 = add i64 %.ph24, 1, !dbg !60
    br label %rec, !dbg !60
  
  rec:                                              ; preds = %rec.outer, %else14
    %lsr.iv = phi i64 [ %5, %rec.outer ], [ %lsr.iv.next, %else14 ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else, !dbg !60
  
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
    br i1 %eq2, label %then3, label %else11, !dbg !61
  
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
    br i1 %eq12, label %then13, label %else14, !dbg !62
  
  then13:                                           ; preds = %else11
    br i1 %.ph23, label %call_decr18, label %cookie19
  
  else14:                                           ; preds = %else11
    call void @__array_push_al_l_(ptr %.ph25, i64 20), !dbg !63
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
  
  define linkonce_odr void @__free_upc_lru_(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_upc_lru_u_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_upc_lru_(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_A64c_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !64 {
  entry:
    store i1 false, ptr @schmu_rf, align 1
    tail call void @schmu_mut_bref(i64 0, ptr @schmu_rf), !dbg !65
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_bool_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = load i1, ptr @schmu_rf, align 1
    call void @__fmt_stdout_println_upc_lru_u_brupc_lru_u2_b_(ptr %clstmp, i1 %0), !dbg !66
    call void @schmu_dontmut_bref(i64 0, ptr @schmu_rf), !dbg !67
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_bool_upc_lru_u_rupc_lru_u__, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %1 = load i1, ptr @schmu_rf, align 1
    call void @__fmt_stdout_println_upc_lru_u_brupc_lru_u2_b_(ptr %clstmp1, i1 %1), !dbg !68
    %2 = alloca %r_, align 8
    store i64 20, ptr %2, align 8
    call void @schmu_mod_rec(ptr %2, i64 0), !dbg !69
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp4, i64 %3), !dbg !70
    %4 = alloca ptr, align 8
    %5 = call ptr @malloc(i64 32)
    store ptr %5, ptr %4, align 8
    store i64 2, ptr %5, align 8
    %cap = getelementptr i64, ptr %5, i64 1
    store i64 2, ptr %cap, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store i64 10, ptr %6, align 8
    %"1" = getelementptr i64, ptr %6, i64 1
    store i64 20, ptr %"1", align 8
    call void @schmu_push_twice(ptr %4, i64 0), !dbg !71
    %clstmp7 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %7 = load ptr, ptr %4, align 8
    %8 = load i64, ptr %7, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp7, i64 %8), !dbg !72
    %9 = alloca i64, align 8
    store i64 0, ptr %9, align 8
    call void @schmu_change_int(ptr %9, i64 0), !dbg !73
    %clstmp10 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp10, align 8
    %envptr12 = getelementptr inbounds %closure, ptr %clstmp10, i32 0, i32 1
    store ptr null, ptr %envptr12, align 8
    %10 = load i64, ptr %9, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp10, i64 %10), !dbg !74
    %11 = alloca ptr, align 8
    %12 = call ptr @malloc(i64 24)
    store ptr %12, ptr %11, align 8
    store i64 0, ptr %12, align 8
    %cap14 = getelementptr i64, ptr %12, i64 1
    store i64 1, ptr %cap14, align 8
    %13 = getelementptr i8, ptr %12, i64 16
    call void @schmu_test(ptr %11, i64 0), !dbg !75
    %clstmp15 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp15, align 8
    %envptr17 = getelementptr inbounds %closure, ptr %clstmp15, i32 0, i32 1
    store ptr null, ptr %envptr17, align 8
    %14 = load ptr, ptr %11, align 8
    %15 = load i64, ptr %14, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp15, i64 %15), !dbg !76
    call void @__free_al_(ptr %11)
    call void @__free_al_(ptr %4)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "tailrec_mutable.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_al_l_", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 34, column: 5, scope: !7)
  !9 = !DILocation(line: 35, column: 7, scope: !7)
  !10 = distinct !DISubprogram(name: "_fmt_bool", linkageName: "__fmt_bool_upc_lru_u_rupc_lru_u__", scope: !11, file: !11, line: 125, type: !4, scopeLine: 125, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DIFile(filename: "fmt.smu", directory: "")
  !12 = !DILocation(line: 126, column: 5, scope: !10)
  !13 = !DILocation(line: 126, column: 9, scope: !10)
  !14 = !DILocation(line: 127, column: 9, scope: !10)
  !15 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !11, file: !11, line: 130, type: !4, scopeLine: 130, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !16 = !DILocation(line: 132, column: 2, scope: !15)
  !17 = !DILocation(line: 133, column: 15, scope: !15)
  !18 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !11, file: !11, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !19 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !11, file: !11, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !20 = !DILocation(line: 22, column: 4, scope: !19)
  !21 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !11, file: !11, line: 54, type: !4, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !22 = !DILocation(line: 56, column: 6, scope: !21)
  !23 = !DILocation(line: 57, column: 4, scope: !21)
  !24 = !DILocation(line: 74, column: 17, scope: !21)
  !25 = !DILocation(line: 77, column: 4, scope: !21)
  !26 = !DILocation(line: 81, column: 4, scope: !21)
  !27 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !11, file: !11, line: 109, type: !4, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !28 = !DILocation(line: 110, column: 2, scope: !27)
  !29 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_brupc_lru_u2_b_", scope: !11, file: !11, line: 220, type: !4, scopeLine: 220, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !30 = !DILocation(line: 221, column: 9, scope: !29)
  !31 = !DILocation(line: 221, column: 4, scope: !29)
  !32 = !DILocation(line: 221, column: 31, scope: !29)
  !33 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_", scope: !11, file: !11, line: 220, type: !4, scopeLine: 220, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !34 = !DILocation(line: 221, column: 9, scope: !33)
  !35 = !DILocation(line: 221, column: 4, scope: !33)
  !36 = !DILocation(line: 221, column: 31, scope: !33)
  !37 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_upc_lru_u_rupc_lru_u__", scope: !11, file: !11, line: 117, type: !4, scopeLine: 117, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 118, column: 22, scope: !37)
  !39 = !DILocation(line: 118, column: 40, scope: !37)
  !40 = !DILocation(line: 118, column: 2, scope: !37)
  !41 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !11, file: !11, line: 77, type: !4, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !42 = !DILocation(line: 78, column: 6, scope: !41)
  !43 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !11, file: !11, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !44 = !DILocation(line: 63, column: 21, scope: !43)
  !45 = !DILocation(line: 64, column: 10, scope: !43)
  !46 = !DILocation(line: 67, column: 11, scope: !43)
  !47 = distinct !DISubprogram(name: "change_int", linkageName: "schmu_change_int", scope: !48, file: !48, line: 58, type: !4, scopeLine: 58, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !48 = !DIFile(filename: "tailrec_mutable.smu", directory: "")
  !49 = !DILocation(line: 59, column: 5, scope: !47)
  !50 = distinct !DISubprogram(name: "dontmut_bref", linkageName: "schmu_dontmut_bref", scope: !48, file: !48, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !51 = !DILocation(line: 8, column: 5, scope: !50)
  !52 = distinct !DISubprogram(name: "mod_rec", linkageName: "schmu_mod_rec", scope: !48, file: !48, line: 31, type: !4, scopeLine: 31, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !53 = !DILocation(line: 32, column: 5, scope: !52)
  !54 = distinct !DISubprogram(name: "mut_bref", linkageName: "schmu_mut_bref", scope: !48, file: !48, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !55 = !DILocation(line: 4, column: 5, scope: !54)
  !56 = distinct !DISubprogram(name: "push_twice", linkageName: "schmu_push_twice", scope: !48, file: !48, line: 43, type: !4, scopeLine: 43, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !57 = !DILocation(line: 44, column: 5, scope: !56)
  !58 = !DILocation(line: 46, column: 4, scope: !56)
  !59 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !48, file: !48, line: 69, type: !4, scopeLine: 69, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !60 = !DILocation(line: 70, column: 5, scope: !59)
  !61 = !DILocation(line: 73, column: 12, scope: !59)
  !62 = !DILocation(line: 76, column: 12, scope: !59)
  !63 = !DILocation(line: 78, column: 4, scope: !59)
  !64 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !48, file: !48, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !65 = !DILocation(line: 18, scope: !64)
  !66 = !DILocation(line: 21, column: 5, scope: !64)
  !67 = !DILocation(line: 23, scope: !64)
  !68 = !DILocation(line: 26, column: 5, scope: !64)
  !69 = !DILocation(line: 38, column: 2, scope: !64)
  !70 = !DILocation(line: 39, column: 7, scope: !64)
  !71 = !DILocation(line: 53, column: 2, scope: !64)
  !72 = !DILocation(line: 54, column: 7, scope: !64)
  !73 = !DILocation(line: 64, column: 2, scope: !64)
  !74 = !DILocation(line: 65, column: 2, scope: !64)
  !75 = !DILocation(line: 85, column: 2, scope: !64)
  !76 = !DILocation(line: 86, column: 2, scope: !64)
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
  %fmt.formatter.tac__ = type { %closure, ptr }
  
  @fmt_int_digits = external global ptr
  @schmu_arr = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [1 x [1 x i8]] } { i64 0, i64 1, [1 x [1 x i8]] zeroinitializer }
  @1 = private unnamed_addr constant { i64, i64, [3 x i8] } { i64 2, i64 2, [3 x i8] c", \00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_append(ptr noalias %0, ptr %1)
  
  declare void @string_modify_buf(ptr noalias %0, ptr %1)
  
  declare void @string_println(ptr %0)
  
  declare void @fmt_fmt_str_create(ptr noalias %0)
  
  define linkonce_odr void @__array_fixed_swap_items_A64c__(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
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
  
  define linkonce_odr i1 @__array_inner__2_Cal_lrb__(i64 %i, ptr %0) !dbg !7 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %then3, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %then3 ], [ %2, %entry ]
    %3 = add i64 %lsr.iv, -1
    %4 = load i64, ptr %arr1, align 8
    %eq = icmp eq i64 %3, %4
    br i1 %eq, label %ifcont5, label %else, !dbg !8
  
  else:                                             ; preds = %rec
    %5 = shl i64 %lsr.iv, 3
    %uglygep = getelementptr i8, ptr %arr1, i64 %5
    %uglygep6 = getelementptr i8, ptr %uglygep, i64 8
    %6 = load i64, ptr %uglygep6, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr7 = getelementptr inbounds i8, ptr %0, i64 32
    %loadtmp2 = load ptr, ptr %sunkaddr7, align 8
    %7 = tail call i1 %loadtmp(i64 %6, ptr %loadtmp2), !dbg !9
    br i1 %7, label %then3, label %ifcont5, !dbg !9
  
  then3:                                            ; preds = %else
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  ifcont5:                                          ; preds = %else, %rec
    ret i1 false
  }
  
  define linkonce_odr i1 @__array_iter_al_lrb__(ptr %arr, ptr %cont) !dbg !10 {
  entry:
    %__array_inner__2_Cal_lrb__ = alloca %closure, align 8
    store ptr @__array_inner__2_Cal_lrb__, ptr %__array_inner__2_Cal_lrb__, align 8
    %clsr___array_inner__2_Cal_lrb__ = alloca { ptr, ptr, ptr, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_lrb__, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cont2 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_lrb__, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cont2, ptr align 1 %cont, i64 16, i1 false)
    store ptr @__ctor_al_lrb2_, ptr %clsr___array_inner__2_Cal_lrb__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Cal_lrb__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__array_inner__2_Cal_lrb__, i32 0, i32 1
    store ptr %clsr___array_inner__2_Cal_lrb__, ptr %envptr, align 8
    %0 = call i1 @__array_inner__2_Cal_lrb__(i64 0, ptr %clsr___array_inner__2_Cal_lrb__), !dbg !11
    ret i1 %0
  }
  
  define linkonce_odr i64 @__array_pop_back_ac_rvc__(ptr noalias %arr) !dbg !12 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, 0
    br i1 %eq, label %then, label %else, !dbg !13
  
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
  
  define linkonce_odr void @__array_push_ac_c_(ptr noalias %arr, i8 %value) !dbg !14 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5, !dbg !15
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !16
  
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
  
  define linkonce_odr ptr @__fmt_formatter_extract_ac_pc_lru_ac2_rac__(ptr %fm) !dbg !17 {
  entry:
    %0 = getelementptr inbounds %fmt.formatter.tac__, ptr %fm, i32 0, i32 1
    tail call void @__free_except1_ac_pc_lru_ac2_(ptr %fm)
    %1 = load ptr, ptr %0, align 8
    ret ptr %1
  }
  
  define linkonce_odr void @__fmt_formatter_format_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !19 {
  entry:
    %1 = alloca %fmt.formatter.tac__, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 24, i1 false)
    %2 = getelementptr inbounds %fmt.formatter.tac__, ptr %1, i32 0, i32 1
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    call void %loadtmp(ptr %2, ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !20
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr noalias %0, ptr %p, i64 %i) !dbg !21 {
  entry:
    tail call void @__fmt_int_base_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr %0, ptr %p, i64 %i, i64 10), !dbg !22
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !23 {
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
    br i1 %andtmp, label %then, label %else, !dbg !24
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr %0, ptr %p, ptr %1, i64 1), !dbg !25
    br label %ifcont
  
  else:                                             ; preds = %cont
    %fmt_aux = alloca %closure, align 8
    store ptr @fmt_aux, ptr %fmt_aux, align 8
    %clsr_fmt_aux = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr, align 8
    %base1 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 3
    store i64 %base, ptr %base1, align 8
    store ptr @__ctor_A64c_l_, ptr %clsr_fmt_aux, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt_aux, i32 0, i32 1
    store ptr %clsr_fmt_aux, ptr %envptr, align 8
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !26
    %add = add i64 %2, 1
    %div = sdiv i64 %add, 2
    %__fun_fmt2 = alloca %closure, align 8
    store ptr @__fun_fmt2, ptr %__fun_fmt2, align 8
    %clsr___fun_fmt2 = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr5 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr5, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 3
    store i64 %add, ptr %_fmt_length, align 8
    store ptr @__ctor_A64c_l_, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !27
    call void @__fmt_formatter_format_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !28
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr ptr @__fmt_str_print_ac_pc_lru_ac2_lrac_pc_lru_ac3_l_(ptr %fmt, i64 %value) !dbg !29 {
  entry:
    %ret = alloca %fmt.formatter.tac__, align 8
    call void @fmt_fmt_str_create(ptr %ret), !dbg !30
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.tac__, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !31
    %0 = call ptr @__fmt_formatter_extract_ac_pc_lru_ac2_rac__(ptr %ret2), !dbg !32
    ret ptr %0
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !33 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64c__(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !34
    ret void
  }
  
  define linkonce_odr i1 @__fun_iter6_lC2lru_l_(i64 %x, ptr %0) !dbg !35 {
  entry:
    %f = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %0, i32 0, i32 2
    %_iter_i = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %0, i32 0, i32 3
    %_iter_i1 = load ptr, ptr %_iter_i, align 8
    %1 = load i64, ptr %_iter_i1, align 8
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp2 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(i64 %1, i64 %x, ptr %loadtmp2), !dbg !37
    %2 = load i64, ptr %_iter_i1, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %_iter_i1, align 8
    ret i1 true
  }
  
  define void @__fun_schmu0(ptr noalias %arr) !dbg !38 {
  entry:
    tail call void @__array_push_ac_c_(ptr %arr, i8 0), !dbg !40
    %ret = alloca %option.tc_, align 8
    %0 = tail call i64 @__array_pop_back_ac_rvc__(ptr %arr), !dbg !41
    store i64 %0, ptr %ret, align 8
    ret void
  }
  
  define i1 @__fun_schmu1(ptr %__curry0, ptr %0) !dbg !42 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %1 = tail call i1 @__array_iter_al_lrb__(ptr %arr1, ptr %__curry0), !dbg !43
    ret i1 %1
  }
  
  define void @__fun_schmu2(i64 %i, i64 %v, ptr %0) !dbg !44 {
  entry:
    %acc = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    %acc1 = load ptr, ptr %acc, align 8
    %delim = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %0, i32 0, i32 3
    %delim2 = load ptr, ptr %delim, align 8
    %gt = icmp sgt i64 %i, 0
    br i1 %gt, label %then, label %ifcont, !dbg !45
  
  then:                                             ; preds = %entry
    tail call void @string_append(ptr %acc1, ptr %delim2), !dbg !46
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_ac_pc_lru_ac2_rac_pc_lru_ac2__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %1 = call ptr @__fmt_str_print_ac_pc_lru_ac2_lrac_pc_lru_ac3_l_(ptr %clstmp, i64 %v), !dbg !47
    call void @string_append(ptr %acc1, ptr %1), !dbg !48
    %2 = alloca ptr, align 8
    store ptr %1, ptr %2, align 8
    call void @__free_ac_(ptr %2)
    ret void
  }
  
  define linkonce_odr void @__iter_iteri_lrb_rb_2lru__(ptr %it, ptr %f) !dbg !49 {
  entry:
    %0 = alloca i64, align 8
    store i64 0, ptr %0, align 8
    %__fun_iter6_lC2lru_l_ = alloca %closure, align 8
    store ptr @__fun_iter6_lC2lru_l_, ptr %__fun_iter6_lC2lru_l_, align 8
    %clsr___fun_iter6_lC2lru_l_ = alloca { ptr, ptr, %closure, ptr }, align 8
    %f1 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_iter6_lC2lru_l_, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f1, ptr align 1 %f, i64 16, i1 false)
    %_iter_i = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_iter6_lC2lru_l_, i32 0, i32 3
    store ptr %0, ptr %_iter_i, align 8
    store ptr @__ctor_2lru_l_, ptr %clsr___fun_iter6_lC2lru_l_, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_iter6_lC2lru_l_, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_iter6_lC2lru_l_, i32 0, i32 1
    store ptr %clsr___fun_iter6_lC2lru_l_, ptr %envptr, align 8
    %loadtmp = load ptr, ptr %it, align 8
    %envptr2 = getelementptr inbounds %closure, ptr %it, i32 0, i32 1
    %loadtmp3 = load ptr, ptr %envptr2, align 8
    %1 = call i1 %loadtmp(ptr %__fun_iter6_lC2lru_l_, ptr %loadtmp3), !dbg !50
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !51 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !52
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !53
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !54
    br i1 %lt, label %then4, label %ifcont, !dbg !54
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_string_add_null(ptr noalias %str) !dbg !55 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @string_modify_buf(ptr %str, ptr %clstmp), !dbg !56
    ret void
  }
  
  define ptr @schmu_string_concat(ptr %arr, ptr %delim) !dbg !57 {
  entry:
    %0 = alloca ptr, align 8
    %1 = alloca ptr, align 8
    store ptr @0, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %1, i64 8, i1 false)
    call void @__copy_ac_(ptr %0)
    %__fun_schmu1 = alloca %closure, align 8
    store ptr @__fun_schmu1, ptr %__fun_schmu1, align 8
    %clsr___fun_schmu1 = alloca { ptr, ptr, ptr }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr___fun_schmu1, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    store ptr @__ctor_al2_, ptr %clsr___fun_schmu1, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr___fun_schmu1, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu1, i32 0, i32 1
    store ptr %clsr___fun_schmu1, ptr %envptr, align 8
    %__fun_schmu2 = alloca %closure, align 8
    store ptr @__fun_schmu2, ptr %__fun_schmu2, align 8
    %clsr___fun_schmu2 = alloca { ptr, ptr, ptr, ptr }, align 8
    %acc = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %clsr___fun_schmu2, i32 0, i32 2
    store ptr %0, ptr %acc, align 8
    %delim3 = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %clsr___fun_schmu2, i32 0, i32 3
    store ptr %delim, ptr %delim3, align 8
    store ptr @__ctor_ac_ac2_, ptr %clsr___fun_schmu2, align 8
    %dtor5 = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %clsr___fun_schmu2, i32 0, i32 1
    store ptr null, ptr %dtor5, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %__fun_schmu2, i32 0, i32 1
    store ptr %clsr___fun_schmu2, ptr %envptr6, align 8
    call void @__iter_iteri_lrb_rb_2lru__(ptr %__fun_schmu1, ptr %__fun_schmu2), !dbg !58
    call void @schmu_string_add_null(ptr %0), !dbg !59
    %2 = load ptr, ptr %0, align 8
    ret ptr %2
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_al_lrb2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy_al_(ptr %arr)
    %cont = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 3
    call void @__copy_lrb_(ptr %cont)
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
  
  define linkonce_odr void @__copy_lrb_(ptr %0) {
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
  
  define linkonce_odr void @__free_ac_pc_lru_(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_ac_pc_lru_ac2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_ac_pc_lru_(ptr %1)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_A64c_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_2lru_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_2lru_(ptr %f)
    ret ptr %1
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
  
  define linkonce_odr ptr @__ctor_al2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_al_(ptr %arr)
    ret ptr %1
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !60 {
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
    %3 = tail call ptr @schmu_string_concat(ptr %2, ptr @1), !dbg !61
    tail call void @string_println(ptr %3), !dbg !62
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
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_inner", linkageName: "__array_inner__2_Cal_lrb__", scope: !3, file: !3, line: 47, type: !4, scopeLine: 47, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 48, column: 7, scope: !7)
  !9 = !DILocation(line: 50, column: 9, scope: !7)
  !10 = distinct !DISubprogram(name: "_array_iter", linkageName: "__array_iter_al_lrb__", scope: !3, file: !3, line: 46, type: !4, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 54, column: 2, scope: !10)
  !12 = distinct !DISubprogram(name: "_array_pop_back", linkageName: "__array_pop_back_ac_rvc__", scope: !3, file: !3, line: 85, type: !4, scopeLine: 85, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 87, column: 5, scope: !12)
  !14 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_ac_c_", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 34, column: 5, scope: !14)
  !16 = !DILocation(line: 35, column: 7, scope: !14)
  !17 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_ac_pc_lru_ac2_rac__", scope: !18, file: !18, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = !DIFile(filename: "fmt.smu", directory: "")
  !19 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_ac_pc_lru_ac2_rac_pc_lru_ac2__", scope: !18, file: !18, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !20 = !DILocation(line: 22, column: 4, scope: !19)
  !21 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_ac_pc_lru_ac2_rac_pc_lru_ac2__", scope: !18, file: !18, line: 109, type: !4, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !22 = !DILocation(line: 110, column: 2, scope: !21)
  !23 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_ac_pc_lru_ac2_rac_pc_lru_ac2__", scope: !18, file: !18, line: 54, type: !4, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !24 = !DILocation(line: 56, column: 6, scope: !23)
  !25 = !DILocation(line: 57, column: 4, scope: !23)
  !26 = !DILocation(line: 74, column: 17, scope: !23)
  !27 = !DILocation(line: 77, column: 4, scope: !23)
  !28 = !DILocation(line: 81, column: 4, scope: !23)
  !29 = distinct !DISubprogram(name: "_fmt_str_print", linkageName: "__fmt_str_print_ac_pc_lru_ac2_lrac_pc_lru_ac3_l_", scope: !18, file: !18, line: 216, type: !4, scopeLine: 216, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !30 = !DILocation(line: 217, column: 9, scope: !29)
  !31 = !DILocation(line: 217, column: 4, scope: !29)
  !32 = !DILocation(line: 217, column: 41, scope: !29)
  !33 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !18, file: !18, line: 77, type: !4, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !34 = !DILocation(line: 78, column: 6, scope: !33)
  !35 = distinct !DISubprogram(name: "__fun_iter6", linkageName: "__fun_iter6_lC2lru_l_", scope: !36, file: !36, line: 93, type: !4, scopeLine: 93, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DIFile(filename: "iter.smu", directory: "")
  !37 = !DILocation(line: 94, column: 4, scope: !35)
  !38 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !39, file: !39, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !39 = !DIFile(filename: "polymorphic_lambda_argument.smu", directory: "")
  !40 = !DILocation(line: 5, column: 4, scope: !38)
  !41 = !DILocation(line: 6, column: 4, scope: !38)
  !42 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1", scope: !39, file: !39, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !43 = !DILocation(line: 12, column: 2, scope: !42)
  !44 = distinct !DISubprogram(name: "__fun_schmu2", linkageName: "__fun_schmu2", scope: !39, file: !39, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !45 = !DILocation(line: 13, column: 7, scope: !44)
  !46 = !DILocation(line: 13, column: 14, scope: !44)
  !47 = !DILocation(line: 14, column: 29, scope: !44)
  !48 = !DILocation(line: 14, column: 4, scope: !44)
  !49 = distinct !DISubprogram(name: "_iter_iteri", linkageName: "__iter_iteri_lrb_rb_2lru__", scope: !36, file: !36, line: 91, type: !4, scopeLine: 91, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !50 = !DILocation(line: 93, column: 2, scope: !49)
  !51 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !18, file: !18, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !52 = !DILocation(line: 63, column: 21, scope: !51)
  !53 = !DILocation(line: 64, column: 10, scope: !51)
  !54 = !DILocation(line: 67, column: 11, scope: !51)
  !55 = distinct !DISubprogram(name: "string_add_null", linkageName: "schmu_string_add_null", scope: !39, file: !39, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !56 = !DILocation(line: 4, column: 2, scope: !55)
  !57 = distinct !DISubprogram(name: "string_concat", linkageName: "schmu_string_concat", scope: !39, file: !39, line: 10, type: !4, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !58 = !DILocation(line: 12, column: 21, scope: !57)
  !59 = !DILocation(line: 16, column: 2, scope: !57)
  !60 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !39, file: !39, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !61 = !DILocation(line: 20, column: 8, scope: !60)
  !62 = !DILocation(line: 20, scope: !60)
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
  
  %wrapupc_lru_u_ac_rupc_lru_u2_ac_ru__ = type { %closure }
  %closure = type { ptr, ptr }
  %fmt.formatter.tu_ = type { %closure }
  %lupc_lru_u2_ = type { i64, %fmt.formatter.tu_ }
  
  @fmt_stdout_missing_arg_msg = external global ptr
  @fmt_stdout_too_many_arg_msg = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_once = global i1 true, align 1
  @schmu_result = global %wrapupc_lru_u_ac_rupc_lru_u2_ac_ru__ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"{} foo\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"{} bar\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"a\00" }
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare void @fmt_prerr(ptr noalias %0)
  
  declare void @fmt_stdout_helper_printn(ptr noalias %0, ptr %1, ptr %2)
  
  define linkonce_odr void @__fmt_endl_upc_lru_u_ru_(ptr %p) !dbg !2 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !6
    call void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %ret), !dbg !7
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %fm) !dbg !8 {
  entry:
    tail call void @__free_except1_upc_lru_u_(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !9 {
  entry:
    %1 = alloca %fmt.formatter.tu_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !10
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__(ptr noalias %0) !dbg !11 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_prerr(ptr %ret), !dbg !12
    %1 = load ptr, ptr @fmt_stdout_missing_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr %ret1, ptr %ret, ptr %1), !dbg !13
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret1), !dbg !14
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_too_many_ru_() !dbg !15 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_prerr(ptr %ret), !dbg !16
    %0 = load ptr, ptr @fmt_stdout_too_many_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr %ret1, ptr %ret, ptr %0), !dbg !17
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret1), !dbg !18
    call void @abort()
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_print1_upc_lru_u_ac_rupc_lru_u2_ac__(ptr %fmtstr, ptr %f0, ptr %v0) !dbg !19 {
  entry:
    %__fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__ = alloca %closure, align 8
    store ptr @__fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__, ptr %__fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__, align 8
    %clsr___fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__ = alloca { ptr, ptr, %closure, ptr }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %v02 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__, i32 0, i32 3
    store ptr %v0, ptr %v02, align 8
    store ptr @__ctor_upc_lru_u_ac_rupc_lru_u2_ac2_, ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__, ptr %envptr, align 8
    %ret = alloca %lupc_lru_u2_, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__), !dbg !20
    %0 = getelementptr inbounds %lupc_lru_u2_, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 1
    br i1 %ne, label %then, label %else, !dbg !21
  
  then:                                             ; preds = %entry
    call void @__fmt_stdout_impl_fmt_fail_too_many_ru_(), !dbg !22
    call void @__free_upc_lru_u_(ptr %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %0), !dbg !23
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, ptr %str) !dbg !24 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !25
    %2 = tail call i64 @string_len(ptr %str), !dbg !26
    tail call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !27
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !28 {
  entry:
    %v0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 3
    %v01 = load ptr, ptr %v0, align 8
    %eq = icmp eq i64 %i, 0
    br i1 %eq, label %then, label %else, !dbg !29
  
  then:                                             ; preds = %entry
    %sunkaddr = getelementptr inbounds i8, ptr %1, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr3 = getelementptr inbounds i8, ptr %1, i64 24
    %loadtmp2 = load ptr, ptr %sunkaddr3, align 8
    tail call void %loadtmp(ptr %0, ptr %fmter, ptr %v01, ptr %loadtmp2), !dbg !30
    ret void
  
  else:                                             ; preds = %entry
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__(ptr %0), !dbg !31
    tail call void @__free_upc_lru_u_(ptr %fmter)
    ret void
  }
  
  define linkonce_odr void @__fun_schmu0_upc_lru_u_ac_rupc_lru_u2_ac__(ptr %fmt, ptr %a) !dbg !32 {
  entry:
    tail call void @__fmt_stdout_print1_upc_lru_u_ac_rupc_lru_u2_ac__(ptr @0, ptr %fmt, ptr %a), !dbg !34
    ret void
  }
  
  define linkonce_odr void @__schmu_bar_upc_lru_u_ac_rupc_lru_u2_ac__(ptr %fmt, ptr %a) !dbg !35 {
  entry:
    tail call void @__fmt_stdout_print1_upc_lru_u_ac_rupc_lru_u2_ac__(ptr @1, ptr %fmt, ptr %a), !dbg !36
    ret void
  }
  
  define linkonce_odr void @__schmu_black_box_upc_lru_u_ac_rupc_lru_u2_ac_ru_upc_lru_u_ac_rupc_lru_u2_ac_ru_rupc_lru_u_ac_rupc_lru_u2_ac_ru__(ptr noalias %0, ptr %f, ptr %g) !dbg !37 {
  entry:
    %1 = load i1, ptr @schmu_once, align 1
    br i1 %1, label %then, label %else, !dbg !38
  
  then:                                             ; preds = %entry
    store i1 false, ptr @schmu_once, align 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %f, i64 16, i1 false)
    tail call void @__copy_upc_lru_u_ac_rupc_lru_u2_ac_ru_(ptr %0)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %g, i64 16, i1 false)
    tail call void @__copy_upc_lru_u_ac_rupc_lru_u2_ac_ru_(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_upc_lru_(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_upc_lru_u_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_upc_lru_(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_upc_lru_u_ac_rupc_lru_u2_ac2_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_upc_lru_u_ac_rupc_lru_u2_(ptr %f0)
    %v0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 3
    call void @__copy_ac_(ptr %v0)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_upc_lru_u_ac_rupc_lru_u2_(ptr %0) {
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
  
  define linkonce_odr void @__free_upc_lru_u_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_upc_lru_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__copy_upc_lru_u_ac_rupc_lru_u2_ac_ru_(ptr %0) {
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !39 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0_upc_lru_u_ac_rupc_lru_u2_ac__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @__schmu_bar_upc_lru_u_ac_rupc_lru_u2_ac__, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    call void @__schmu_black_box_upc_lru_u_ac_rupc_lru_u2_ac_ru_upc_lru_u_ac_rupc_lru_u2_ac_ru_rupc_lru_u_ac_rupc_lru_u2_ac_ru__(ptr @schmu_result, ptr %clstmp, ptr %clstmp1), !dbg !40
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_str_upc_lru_u_rupc_lru_u__, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %0 = alloca %closure, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %clstmp4, i64 16, i1 false)
    call void @__copy_upc_lru_u_ac_rupc_lru_u2_(ptr %0)
    %loadtmp = load ptr, ptr @schmu_result, align 8
    %loadtmp7 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_result, i32 0, i32 1), align 8
    call void %loadtmp(ptr %0, ptr @2, ptr %loadtmp7), !dbg !41
    call void @__free_upc_lru_u_ac_rupc_lru_u2_(ptr %0)
    call void @__free_upc_lru_u_ac_rupc_lru_u2_ac_ru2_(ptr @schmu_result)
    ret i64 0
  }
  
  define linkonce_odr void @__free_upc_lru_u_ac_rupc_lru_u2_(ptr %0) {
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
  
  define linkonce_odr void @__free_upc_lru_u_ac_rupc_lru_u2_ac_ru_(ptr %0) {
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
  
  define linkonce_odr void @__free_upc_lru_u_ac_rupc_lru_u2_ac_ru2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_upc_lru_u_ac_rupc_lru_u2_ac_ru_(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "poly_fn_ret_fn.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !3, file: !3, line: 130, type: !4, scopeLine: 130, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "fmt.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 132, column: 2, scope: !2)
  !7 = !DILocation(line: 133, column: 15, scope: !2)
  !8 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !3, file: !3, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !3, file: !3, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 22, column: 4, scope: !9)
  !11 = distinct !DISubprogram(name: "_fmt_stdout_impl_fmt_fail_missing", linkageName: "__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__", scope: !3, file: !3, line: 158, type: !4, scopeLine: 158, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 159, column: 6, scope: !11)
  !13 = !DILocation(line: 159, column: 17, scope: !11)
  !14 = !DILocation(line: 160, column: 9, scope: !11)
  !15 = distinct !DISubprogram(name: "_fmt_stdout_impl_fmt_fail_too_many", linkageName: "__fmt_stdout_impl_fmt_fail_too_many_ru_", scope: !3, file: !3, line: 164, type: !4, scopeLine: 164, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !16 = !DILocation(line: 165, column: 6, scope: !15)
  !17 = !DILocation(line: 165, column: 17, scope: !15)
  !18 = !DILocation(line: 166, column: 9, scope: !15)
  !19 = distinct !DISubprogram(name: "_fmt_stdout_print1", linkageName: "__fmt_stdout_print1_upc_lru_u_ac_rupc_lru_u2_ac__", scope: !3, file: !3, line: 242, type: !4, scopeLine: 242, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !20 = !DILocation(line: 243, column: 22, scope: !19)
  !21 = !DILocation(line: 249, column: 7, scope: !19)
  !22 = !DILocation(line: 250, column: 6, scope: !19)
  !23 = !DILocation(line: 252, column: 11, scope: !19)
  !24 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_upc_lru_u_rupc_lru_u__", scope: !3, file: !3, line: 117, type: !4, scopeLine: 117, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !25 = !DILocation(line: 118, column: 22, scope: !24)
  !26 = !DILocation(line: 118, column: 40, scope: !24)
  !27 = !DILocation(line: 118, column: 2, scope: !24)
  !28 = distinct !DISubprogram(name: "__fun_fmt_stdout2", linkageName: "__fun_fmt_stdout2_Cupc_lru_u_ac_rupc_lru_u2_ac__", scope: !3, file: !3, line: 243, type: !4, scopeLine: 243, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 245, column: 8, scope: !28)
  !30 = !DILocation(line: 245, column: 11, scope: !28)
  !31 = !DILocation(line: 246, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0_upc_lru_u_ac_rupc_lru_u2_ac__", scope: !33, file: !33, line: 11, type: !4, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "poly_fn_ret_fn.smu", directory: "")
  !34 = !DILocation(line: 13, column: 2, scope: !32)
  !35 = distinct !DISubprogram(name: "bar", linkageName: "__schmu_bar_upc_lru_u_ac_rupc_lru_u2_ac__", scope: !33, file: !33, line: 15, type: !4, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DILocation(line: 17, column: 2, scope: !35)
  !37 = distinct !DISubprogram(name: "black_box", linkageName: "__schmu_black_box_upc_lru_u_ac_rupc_lru_u2_ac_ru_upc_lru_u_ac_rupc_lru_u2_ac_ru_rupc_lru_u_ac_rupc_lru_u2_ac_ru__", scope: !33, file: !33, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 6, column: 5, scope: !37)
  !39 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !40 = !DILocation(line: 22, column: 22, scope: !39)
  !41 = !DILocation(line: 24, column: 1, scope: !39)
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

Unit parameters in folds
  $ schmu unit_param.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./unit_param
