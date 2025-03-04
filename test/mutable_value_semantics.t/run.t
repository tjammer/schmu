Test simple setting of mutable variables
  $ schmu --dump-llvm simple_set.smu && valgrind -q --leak-check=yes --show-reachable=yes ./simple_set
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_b = global i64 10, align 8
  @schmu_a = global ptr null, align 8
  @schmu_b__3 = global ptr null, align 8
  @schmu_c = global ptr null, align 8
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
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
  
  define i64 @schmu_hmm() !dbg !32 {
  entry:
    %0 = alloca i64, align 8
    store i64 10, ptr %0, align 8
    store i64 15, ptr %0, align 8
    ret i64 15
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !34 {
  entry:
    store i64 14, ptr @schmu_b, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 14), !dbg !35
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %0 = call i64 @schmu_hmm(), !dbg !36
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 %0), !dbg !37
    %1 = call ptr @malloc(i64 32)
    store ptr %1, ptr @schmu_a, align 8
    store i64 2, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = call ptr @malloc(i64 24)
    store ptr %3, ptr %2, align 8
    store i64 1, ptr %3, align 8
    %cap5 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap5, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 10, ptr %4, align 8
    %"1" = getelementptr ptr, ptr %2, i64 1
    %5 = call ptr @malloc(i64 24)
    store ptr %5, ptr %"1", align 8
    store i64 1, ptr %5, align 8
    %cap8 = getelementptr i64, ptr %5, i64 1
    store i64 1, ptr %cap8, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store i64 20, ptr %6, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b__3, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_a.a.l(ptr @schmu_b__3)
    %7 = call ptr @malloc(i64 24)
    store ptr %7, ptr @schmu_c, align 8
    store i64 1, ptr %7, align 8
    %cap11 = getelementptr i64, ptr %7, i64 1
    store i64 1, ptr %cap11, align 8
    %8 = getelementptr i8, ptr %7, i64 16
    store i64 30, ptr %8, align 8
    %9 = load ptr, ptr @schmu_a, align 8
    %10 = getelementptr i8, ptr %9, i64 16
    %11 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %11, ptr align 8 @schmu_c, i64 8, i1 false)
    call void @__copy_a.l(ptr %11)
    call void @__free_a.l(ptr %10)
    %12 = load ptr, ptr %11, align 8
    store ptr %12, ptr %10, align 8
    %13 = load ptr, ptr @schmu_a, align 8
    %14 = getelementptr i8, ptr %13, i64 16
    %15 = call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %15, ptr %arr, align 8
    store i64 1, ptr %15, align 8
    %cap14 = getelementptr i64, ptr %15, i64 1
    store i64 1, ptr %cap14, align 8
    %16 = getelementptr i8, ptr %15, i64 16
    store i64 10, ptr %16, align 8
    call void @__free_a.l(ptr %14)
    store ptr %15, ptr %14, align 8
    call void @__free_a.l(ptr @schmu_c)
    call void @__free_a.a.l(ptr @schmu_b__3)
    call void @__free_a.a.l(ptr @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
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
  
  define linkonce_odr void @__copy_a.a.l(ptr %0) {
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
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %5 = load i64, ptr %cnt, align 8
    %6 = icmp slt i64 %5, %size
    br i1 %6, label %child, label %cont
  
  child:                                            ; preds = %rec
    %7 = getelementptr i8, ptr %1, i64 16
    %8 = getelementptr ptr, ptr %7, i64 %5
    call void @__copy_a.l(ptr %8)
    %9 = add i64 %5, 1
    store i64 %9, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.a.l(ptr %0) {
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
    call void @__free_a.l(ptr %5)
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "simple_set.smu", directory: "$TESTCASE_ROOT")
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
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !8, file: !8, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 293, column: 9, scope: !22)
  !24 = !DILocation(line: 293, column: 4, scope: !22)
  !25 = !DILocation(line: 293, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 80, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 65, column: 21, scope: !28)
  !30 = !DILocation(line: 66, column: 10, scope: !28)
  !31 = !DILocation(line: 69, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "hmm", linkageName: "schmu_hmm", scope: !33, file: !33, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "simple_set.smu", directory: "")
  !34 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !35 = !DILocation(line: 3, column: 5, scope: !34)
  !36 = !DILocation(line: 10, column: 18, scope: !34)
  !37 = !DILocation(line: 10, column: 5, scope: !34)
  14
  15

Warn on unneeded mutable bindings
  $ schmu unneeded_mut.smu
  unneeded_mut.smu:1.5-15: warning: Unused binding do_nothing.
  
  1 | fun do_nothing(a&): ignore(a)
          ^^^^^^^^^^
  
  unneeded_mut.smu:5.5-6: warning: Unmutated mutable binding b.
  
  5 | let b& = 0
          ^
  
Use mutable values as ptrs to C code
  $ schmu -c --dump-llvm ptr_to_c.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  
  @schmu_i = global i64 0, align 8
  @schmu_foo = global %foo zeroinitializer, align 8
  
  declare void @mutate_int(ptr noalias %0)
  
  declare void @mutate_foo(ptr noalias %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    tail call void @mutate_int(ptr @schmu_i), !dbg !6
    tail call void @mutate_foo(ptr @schmu_foo), !dbg !7
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "ptr_to_c.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "ptr_to_c.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 6, scope: !2)
  !7 = !DILocation(line: 8, scope: !2)

Check aliasing
  $ schmu --dump-llvm mut_alias.smu && valgrind -q --leak-check=yes --show-reachable=yes ./mut_alias
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_f = global %foo zeroinitializer, align 8
  @schmu_fst = global %foo zeroinitializer, align 8
  @schmu_snd = global %foo zeroinitializer, align 8
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
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
  
  define void @schmu_new_fun() !dbg !32 {
  entry:
    %0 = alloca %foo, align 8
    store i64 0, ptr %0, align 8
    %1 = alloca %foo, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    %2 = alloca %foo, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %1, i64 8, i1 false)
    store i64 1, ptr %1, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 1), !dbg !34
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 0), !dbg !35
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp4, i64 %3), !dbg !36
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
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !37 {
  entry:
    store i64 0, ptr @schmu_f, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_fst, ptr align 8 @schmu_f, i64 8, i1 false)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_snd, ptr align 8 @schmu_fst, i64 8, i1 false)
    store i64 1, ptr @schmu_fst, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 1), !dbg !38
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %0 = load i64, ptr @schmu_f, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 %0), !dbg !39
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %1 = load i64, ptr @schmu_snd, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp4, i64 %1), !dbg !40
    call void @schmu_new_fun(), !dbg !41
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "mut_alias.smu", directory: "$TESTCASE_ROOT")
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
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !8, file: !8, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 293, column: 9, scope: !22)
  !24 = !DILocation(line: 293, column: 4, scope: !22)
  !25 = !DILocation(line: 293, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 80, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 65, column: 21, scope: !28)
  !30 = !DILocation(line: 66, column: 10, scope: !28)
  !31 = !DILocation(line: 69, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "new_fun", linkageName: "schmu_new_fun", scope: !33, file: !33, line: 11, type: !4, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "mut_alias.smu", directory: "")
  !34 = !DILocation(line: 16, column: 7, scope: !32)
  !35 = !DILocation(line: 17, column: 7, scope: !32)
  !36 = !DILocation(line: 18, column: 7, scope: !32)
  !37 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 7, column: 5, scope: !37)
  !39 = !DILocation(line: 8, column: 5, scope: !37)
  !40 = !DILocation(line: 9, column: 5, scope: !37)
  !41 = !DILocation(line: 20, scope: !37)
  1
  0
  0
  1
  0
  0

Const let
  $ schmu --dump-llvm const_let.smu && valgrind -q --leak-check=yes --show-reachable=yes ./const_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_v = global ptr null, align 8
  @schmu_const = global i64 0, align 8
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
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
  
  define void @schmu_in_fun() !dbg !32 {
  entry:
    %0 = alloca ptr, align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr %0, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 0, ptr %2, align 8
    %3 = load ptr, ptr %0, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    %5 = alloca i64, align 8
    %6 = load i64, ptr %4, align 8
    store i64 %6, ptr %5, align 8
    store i64 1, ptr %4, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %7 = load ptr, ptr %0, align 8
    %8 = getelementptr i8, ptr %7, i64 16
    %9 = load i64, ptr %8, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %9), !dbg !34
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 %6), !dbg !35
    call void @__free_a.l(ptr %0)
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
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !36 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_v, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 0, ptr %1, align 8
    %2 = load ptr, ptr @schmu_v, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    %4 = load i64, ptr %3, align 8
    store i64 %4, ptr @schmu_const, align 8
    store i64 1, ptr %3, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %5 = load ptr, ptr @schmu_v, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = load i64, ptr %6, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %7), !dbg !37
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %8 = load i64, ptr @schmu_const, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 %8), !dbg !38
    call void @schmu_in_fun(), !dbg !39
    call void @__free_a.l(ptr @schmu_v)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "const_let.smu", directory: "$TESTCASE_ROOT")
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
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !8, file: !8, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 293, column: 9, scope: !22)
  !24 = !DILocation(line: 293, column: 4, scope: !22)
  !25 = !DILocation(line: 293, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 80, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 65, column: 21, scope: !28)
  !30 = !DILocation(line: 66, column: 10, scope: !28)
  !31 = !DILocation(line: 69, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "in_fun", linkageName: "schmu_in_fun", scope: !33, file: !33, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "const_let.smu", directory: "")
  !34 = !DILocation(line: 11, column: 7, scope: !32)
  !35 = !DILocation(line: 12, column: 7, scope: !32)
  !36 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !37 = !DILocation(line: 4, column: 5, scope: !36)
  !38 = !DILocation(line: 5, column: 5, scope: !36)
  !39 = !DILocation(line: 14, scope: !36)
  1
  0
  1
  0


Copies, but with ref-counted arrays
  $ schmu array_copies.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./array_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global ptr null, align 8
  @schmu_b = global ptr null, align 8
  @schmu_c = global ptr null, align 8
  @schmu_d = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [7 x i8] } { i64 6, i64 6, [7 x i8] c"in fun\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
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
  
  define void @schmu_in_fun() !dbg !32 {
  entry:
    tail call void @string_println(ptr @0), !dbg !34
    %0 = alloca ptr, align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr %0, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    %3 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_a.l(ptr %3)
    %4 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_a.l(ptr %4)
    %5 = load ptr, ptr %0, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store i64 12, ptr %6, align 8
    %7 = load ptr, ptr %0, align 8
    call void @schmu_print_0th(ptr %7), !dbg !35
    %8 = load ptr, ptr %4, align 8
    %9 = getelementptr i8, ptr %8, i64 16
    store i64 15, ptr %9, align 8
    %10 = load ptr, ptr %0, align 8
    call void @schmu_print_0th(ptr %10), !dbg !36
    %11 = load ptr, ptr %3, align 8
    call void @schmu_print_0th(ptr %11), !dbg !37
    %12 = load ptr, ptr %4, align 8
    call void @schmu_print_0th(ptr %12), !dbg !38
    %13 = load ptr, ptr %3, align 8
    call void @schmu_print_0th(ptr %13), !dbg !39
    call void @__free_a.l(ptr %4)
    call void @__free_a.l(ptr %3)
    call void @__free_a.l(ptr %0)
    ret void
  }
  
  define void @schmu_print_0th(ptr %a) !dbg !40 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = getelementptr i8, ptr %a, i64 16
    %1 = load i64, ptr %0, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %1), !dbg !41
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
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
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
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !42 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_a, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_a.l(ptr @schmu_b)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_c, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_a.l(ptr @schmu_c)
    %2 = load ptr, ptr @schmu_b, align 8
    store ptr %2, ptr @schmu_d, align 8
    %3 = load ptr, ptr @schmu_a, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 12, ptr %4, align 8
    %5 = load ptr, ptr @schmu_a, align 8
    tail call void @schmu_print_0th(ptr %5), !dbg !43
    %6 = load ptr, ptr @schmu_c, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    store i64 15, ptr %7, align 8
    %8 = load ptr, ptr @schmu_a, align 8
    tail call void @schmu_print_0th(ptr %8), !dbg !44
    %9 = load ptr, ptr @schmu_b, align 8
    tail call void @schmu_print_0th(ptr %9), !dbg !45
    %10 = load ptr, ptr @schmu_c, align 8
    tail call void @schmu_print_0th(ptr %10), !dbg !46
    %11 = load ptr, ptr @schmu_d, align 8
    tail call void @schmu_print_0th(ptr %11), !dbg !47
    tail call void @schmu_in_fun(), !dbg !48
    tail call void @__free_a.l(ptr @schmu_c)
    tail call void @__free_a.l(ptr @schmu_b)
    tail call void @__free_a.l(ptr @schmu_a)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "array_copies.smu", directory: "$TESTCASE_ROOT")
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
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !8, file: !8, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 293, column: 9, scope: !22)
  !24 = !DILocation(line: 293, column: 4, scope: !22)
  !25 = !DILocation(line: 293, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 80, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 65, column: 21, scope: !28)
  !30 = !DILocation(line: 66, column: 10, scope: !28)
  !31 = !DILocation(line: 69, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "in_fun", linkageName: "schmu_in_fun", scope: !33, file: !33, line: 16, type: !4, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "array_copies.smu", directory: "")
  !34 = !DILocation(line: 17, column: 2, scope: !32)
  !35 = !DILocation(line: 24, column: 2, scope: !32)
  !36 = !DILocation(line: 26, column: 2, scope: !32)
  !37 = !DILocation(line: 27, column: 2, scope: !32)
  !38 = !DILocation(line: 28, column: 2, scope: !32)
  !39 = !DILocation(line: 29, column: 2, scope: !32)
  !40 = distinct !DISubprogram(name: "print_0th", linkageName: "schmu_print_0th", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !41 = !DILocation(line: 1, column: 18, scope: !40)
  !42 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !43 = !DILocation(line: 9, scope: !42)
  !44 = !DILocation(line: 11, scope: !42)
  !45 = !DILocation(line: 12, scope: !42)
  !46 = !DILocation(line: 13, scope: !42)
  !47 = !DILocation(line: 14, scope: !42)
  !48 = !DILocation(line: 32, scope: !42)
  12
  12
  10
  15
  10
  in fun
  12
  12
  10
  15
  10

Arrays in records
  $ schmu array_in_record_copies.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./array_in_record_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %arrec = type { ptr }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global %arrec zeroinitializer, align 8
  @schmu_b = global %arrec zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [7 x i8] } { i64 6, i64 6, [7 x i8] c"in fun\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
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
  
  define void @schmu_in_fun() !dbg !32 {
  entry:
    %0 = alloca %arrec, align 8
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    store ptr %1, ptr %0, align 8
    %3 = alloca %arrec, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_arrec(ptr %3)
    store i64 12, ptr %2, align 8
    %unbox = load i64, ptr %0, align 8
    call void @schmu_print_thing(i64 %unbox), !dbg !34
    %unbox1 = load i64, ptr %3, align 8
    call void @schmu_print_thing(i64 %unbox1), !dbg !35
    call void @__free_arrec(ptr %3)
    call void @__free_arrec(ptr %0)
    ret void
  }
  
  define void @schmu_print_thing(i64 %0) !dbg !36 {
  entry:
    %a = alloca i64, align 8
    store i64 %0, ptr %a, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %1 = inttoptr i64 %0 to ptr
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %3), !dbg !37
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
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
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
  
  define linkonce_odr void @__copy_arrec(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__copy_a.l(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_arrec(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_a.l(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !38 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    store ptr %0, ptr @schmu_a, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_arrec(ptr @schmu_b)
    %2 = load ptr, ptr @schmu_a, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i64 12, ptr %3, align 8
    %unbox = load i64, ptr @schmu_a, align 8
    tail call void @schmu_print_thing(i64 %unbox), !dbg !39
    %unbox1 = load i64, ptr @schmu_b, align 8
    tail call void @schmu_print_thing(i64 %unbox1), !dbg !40
    tail call void @string_println(ptr @0), !dbg !41
    tail call void @schmu_in_fun(), !dbg !42
    tail call void @__free_arrec(ptr @schmu_b)
    tail call void @__free_arrec(ptr @schmu_a)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "array_in_record_copies.smu", directory: "$TESTCASE_ROOT")
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
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !8, file: !8, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 293, column: 9, scope: !22)
  !24 = !DILocation(line: 293, column: 4, scope: !22)
  !25 = !DILocation(line: 293, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 80, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 65, column: 21, scope: !28)
  !30 = !DILocation(line: 66, column: 10, scope: !28)
  !31 = !DILocation(line: 69, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "in_fun", linkageName: "schmu_in_fun", scope: !33, file: !33, line: 15, type: !4, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "array_in_record_copies.smu", directory: "")
  !34 = !DILocation(line: 20, column: 2, scope: !32)
  !35 = !DILocation(line: 21, column: 2, scope: !32)
  !36 = distinct !DISubprogram(name: "print_thing", linkageName: "schmu_print_thing", scope: !33, file: !33, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !37 = !DILocation(line: 7, column: 21, scope: !36)
  !38 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !39 = !DILocation(line: 9, scope: !38)
  !40 = !DILocation(line: 10, scope: !38)
  !41 = !DILocation(line: 12, scope: !38)
  !42 = !DILocation(line: 23, scope: !38)
  12
  10
  in fun
  12
  10

Nested arrays
  $ schmu nested_array.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./nested_array
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.lfmt.formatter.t.u = type { i64, %fmt.formatter.t.u }
  
  @fmt_int_digits = external global ptr
  @fmt_stdout_missing_arg_msg = external global ptr
  @fmt_stdout_too_many_arg_msg = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global ptr null, align 8
  @schmu_b = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"{}, {}\0A\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @fmt_prerr(ptr noalias %0)
  
  declare void @fmt_stdout_helper_printn(ptr noalias %0, ptr %1, ptr %2)
  
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
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_missing_rfmt.formatter.t.u(ptr noalias %0) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !23
    %1 = load ptr, ptr @fmt_stdout_missing_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret1, ptr %ret, ptr %1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret1), !dbg !25
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_too_many_ru() !dbg !26 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !27
    %0 = load ptr, ptr @fmt_stdout_too_many_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret1, ptr %ret, ptr %0), !dbg !28
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret1), !dbg !29
    call void @abort()
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_print2_fmt_stdout_print2_llfmt_stdout_print2_ll(ptr %fmtstr, ptr %f0, i64 %v0, ptr %f1, i64 %v1) !dbg !30 {
  entry:
    %__fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull = alloca %closure, align 8
    store ptr @__fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, ptr %__fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, align 8
    %clsr___fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull = alloca { ptr, ptr, %closure, %closure, i64, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %f12 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f12, ptr align 1 %f1, i64 16, i1 false)
    %v03 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 4
    store i64 %v0, ptr %v03, align 8
    %v14 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 5
    store i64 %v1, ptr %v14, align 8
    store ptr @__ctor_tp._fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, ptr %clsr___fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull), !dbg !31
    %0 = getelementptr inbounds %tp.lfmt.formatter.t.u, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 2
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %entry
    call void @__fmt_stdout_impl_fmt_fail_too_many_ru(), !dbg !33
    call void @__free_fmt.formatter.t.u(ptr %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %0), !dbg !34
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, ptr %str) !dbg !35 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !36
    %2 = tail call i64 @string_len(ptr %str), !dbg !37
    tail call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !38
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !39 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !40
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !41 {
  entry:
    %v0 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 4
    %v01 = load i64, ptr %v0, align 8
    %v1 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 5
    %v12 = load i64, ptr %v1, align 8
    %eq = icmp eq i64 %i, 0
    br i1 %eq, label %then, label %else, !dbg !42
  
  then:                                             ; preds = %entry
    %sunkaddr = getelementptr inbounds i8, ptr %1, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr12 = getelementptr inbounds i8, ptr %1, i64 24
    %loadtmp3 = load ptr, ptr %sunkaddr12, align 8
    tail call void %loadtmp(ptr %0, ptr %fmter, i64 %v01, ptr %loadtmp3), !dbg !43
    ret void
  
  else:                                             ; preds = %entry
    %eq4 = icmp eq i64 %i, 1
    br i1 %eq4, label %then5, label %else10, !dbg !44
  
  then5:                                            ; preds = %else
    %sunkaddr13 = getelementptr inbounds i8, ptr %1, i64 32
    %loadtmp7 = load ptr, ptr %sunkaddr13, align 8
    %sunkaddr14 = getelementptr inbounds i8, ptr %1, i64 40
    %loadtmp9 = load ptr, ptr %sunkaddr14, align 8
    tail call void %loadtmp7(ptr %0, ptr %fmter, i64 %v12, ptr %loadtmp9), !dbg !45
    ret void
  
  else10:                                           ; preds = %else
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rfmt.formatter.t.u(ptr %0), !dbg !46
    tail call void @__free_fmt.formatter.t.u(ptr %fmter)
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !47 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !48
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !49
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !50
    br i1 %lt, label %then4, label %ifcont, !dbg !50
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_prnt(ptr %a) !dbg !51 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = getelementptr i8, ptr %a, i64 16
    %1 = load ptr, ptr %0, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = load i64, ptr %2, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %4 = getelementptr ptr, ptr %0, i64 1
    %5 = load ptr, ptr %4, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = load i64, ptr %6, align 8
    call void @__fmt_stdout_print2_fmt_stdout_print2_llfmt_stdout_print2_ll(ptr @0, ptr %clstmp, i64 %3, ptr %clstmp1, i64 %7), !dbg !53
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
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp._fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 64)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 64, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 2
    call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f0)
    %f1 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 3
    call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f1)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %0) {
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
  
  define linkonce_odr void @__free_fmt.formatter.t.u(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free__up.clru(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !54 {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    store ptr %0, ptr @schmu_a, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = tail call ptr @malloc(i64 24)
    store ptr %2, ptr %1, align 8
    store i64 1, ptr %2, align 8
    %cap2 = getelementptr i64, ptr %2, i64 1
    store i64 1, ptr %cap2, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i64 10, ptr %3, align 8
    %"1" = getelementptr ptr, ptr %1, i64 1
    %4 = tail call ptr @malloc(i64 24)
    store ptr %4, ptr %"1", align 8
    store i64 1, ptr %4, align 8
    %cap5 = getelementptr i64, ptr %4, i64 1
    store i64 1, ptr %cap5, align 8
    %5 = getelementptr i8, ptr %4, i64 16
    store i64 20, ptr %5, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_a.a.l(ptr @schmu_b)
    %6 = load ptr, ptr @schmu_a, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    %8 = load ptr, ptr %7, align 8
    %9 = getelementptr i8, ptr %8, i64 16
    store i64 15, ptr %9, align 8
    %10 = load ptr, ptr @schmu_a, align 8
    tail call void @schmu_prnt(ptr %10), !dbg !55
    %11 = load ptr, ptr @schmu_b, align 8
    tail call void @schmu_prnt(ptr %11), !dbg !56
    tail call void @__free_a.a.l(ptr @schmu_b)
    tail call void @__free_a.a.l(ptr @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
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
  
  define linkonce_odr void @__copy_a.a.l(ptr %0) {
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
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %5 = load i64, ptr %cnt, align 8
    %6 = icmp slt i64 %5, %size
    br i1 %6, label %child, label %cont
  
  child:                                            ; preds = %rec
    %7 = getelementptr i8, ptr %1, i64 16
    %8 = getelementptr ptr, ptr %7, i64 %5
    call void @__copy_a.l(ptr %8)
    %9 = add i64 %5, 1
    store i64 %9, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.a.l(ptr %0) {
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
    call void @__free_a.l(ptr %5)
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "nested_array.smu", directory: "$TESTCASE_ROOT")
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
  !22 = distinct !DISubprogram(name: "_fmt_stdout_impl_fmt_fail_missing", linkageName: "__fmt_stdout_impl_fmt_fail_missing_rfmt.formatter.t.u", scope: !8, file: !8, line: 230, type: !4, scopeLine: 230, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 231, column: 6, scope: !22)
  !24 = !DILocation(line: 231, column: 17, scope: !22)
  !25 = !DILocation(line: 232, column: 9, scope: !22)
  !26 = distinct !DISubprogram(name: "_fmt_stdout_impl_fmt_fail_too_many", linkageName: "__fmt_stdout_impl_fmt_fail_too_many_ru", scope: !8, file: !8, line: 236, type: !4, scopeLine: 236, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 237, column: 6, scope: !26)
  !28 = !DILocation(line: 237, column: 17, scope: !26)
  !29 = !DILocation(line: 238, column: 9, scope: !26)
  !30 = distinct !DISubprogram(name: "_fmt_stdout_print2", linkageName: "__fmt_stdout_print2_fmt_stdout_print2_llfmt_stdout_print2_ll", scope: !8, file: !8, line: 327, type: !4, scopeLine: 327, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !31 = !DILocation(line: 328, column: 22, scope: !30)
  !32 = !DILocation(line: 335, column: 7, scope: !30)
  !33 = !DILocation(line: 335, column: 21, scope: !30)
  !34 = !DILocation(line: 336, column: 11, scope: !30)
  !35 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_fmt.formatter.t.urfmt.formatter.t.u", scope: !8, file: !8, line: 124, type: !4, scopeLine: 124, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DILocation(line: 125, column: 22, scope: !35)
  !37 = !DILocation(line: 125, column: 40, scope: !35)
  !38 = !DILocation(line: 125, column: 2, scope: !35)
  !39 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !40 = !DILocation(line: 80, column: 6, scope: !39)
  !41 = distinct !DISubprogram(name: "__fun_fmt_stdout3", linkageName: "__fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull", scope: !8, file: !8, line: 328, type: !4, scopeLine: 328, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !42 = !DILocation(line: 330, column: 8, scope: !41)
  !43 = !DILocation(line: 330, column: 11, scope: !41)
  !44 = !DILocation(line: 331, column: 8, scope: !41)
  !45 = !DILocation(line: 331, column: 11, scope: !41)
  !46 = !DILocation(line: 332, column: 11, scope: !41)
  !47 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !48 = !DILocation(line: 65, column: 21, scope: !47)
  !49 = !DILocation(line: 66, column: 10, scope: !47)
  !50 = !DILocation(line: 69, column: 11, scope: !47)
  !51 = distinct !DISubprogram(name: "prnt", linkageName: "schmu_prnt", scope: !52, file: !52, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !52 = !DIFile(filename: "nested_array.smu", directory: "")
  !53 = !DILocation(line: 3, column: 2, scope: !51)
  !54 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !52, file: !52, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !55 = !DILocation(line: 9, scope: !54)
  !56 = !DILocation(line: 10, scope: !54)
  15, 20
  10, 20


Modify in function
  $ schmu --dump-llvm modify_in_fn.smu && valgrind -q --leak-check=yes --show-reachable=yes ./modify_in_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %f = type { i64 }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global %f zeroinitializer, align 8
  @schmu_b = global ptr null, align 8
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
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
  
  define linkonce_odr void @__array_push_a.ll(ptr noalias %arr, i64 %value) !dbg !7 {
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !25 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !26
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !27
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !28
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !29 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !30
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !31 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !32
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !33
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !34
    br i1 %lt, label %then4, label %ifcont, !dbg !34
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_mod2(ptr noalias %a) !dbg !35 {
  entry:
    tail call void @__array_push_a.ll(ptr %a, i64 20), !dbg !37
    ret void
  }
  
  define void @schmu_modify(ptr noalias %r) !dbg !38 {
  entry:
    store i64 30, ptr %r, align 8
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !39 {
  entry:
    store i64 20, ptr @schmu_a, align 8
    tail call void @schmu_modify(ptr @schmu_a), !dbg !40
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = load i64, ptr @schmu_a, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %0), !dbg !41
    %1 = call ptr @malloc(i64 24)
    store ptr %1, ptr @schmu_b, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    call void @schmu_mod2(ptr @schmu_b), !dbg !42
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %3 = load ptr, ptr @schmu_b, align 8
    %4 = load i64, ptr %3, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 %4), !dbg !43
    call void @__free_a.l(ptr @schmu_b)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "modify_in_fn.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64.c", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_a.ll", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
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
  !25 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !11, file: !11, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !26 = !DILocation(line: 293, column: 9, scope: !25)
  !27 = !DILocation(line: 293, column: 4, scope: !25)
  !28 = !DILocation(line: 293, column: 31, scope: !25)
  !29 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !11, file: !11, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !30 = !DILocation(line: 80, column: 6, scope: !29)
  !31 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !11, file: !11, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !32 = !DILocation(line: 65, column: 21, scope: !31)
  !33 = !DILocation(line: 66, column: 10, scope: !31)
  !34 = !DILocation(line: 69, column: 11, scope: !31)
  !35 = distinct !DISubprogram(name: "mod2", linkageName: "schmu_mod2", scope: !36, file: !36, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DIFile(filename: "modify_in_fn.smu", directory: "")
  !37 = !DILocation(line: 5, column: 14, scope: !35)
  !38 = distinct !DISubprogram(name: "modify", linkageName: "schmu_modify", scope: !36, file: !36, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !39 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !36, file: !36, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !40 = !DILocation(line: 8, scope: !39)
  !41 = !DILocation(line: 9, column: 5, scope: !39)
  !42 = !DILocation(line: 12, scope: !39)
  !43 = !DILocation(line: 13, column: 5, scope: !39)
  30
  2

Make sure variable ids are correctly propagated
  $ schmu --dump-llvm varid_propagate.smu && valgrind -q --leak-check=yes --show-reachable=yes ./varid_propagate
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr void @__array_push_a.ll(ptr noalias %arr, i64 %value) !dbg !2 {
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
  
  define linkonce_odr ptr @__schmu_f1_a.llra.l(ptr %acc, i64 %v) !dbg !8 {
  entry:
    %0 = alloca ptr, align 8
    %1 = alloca ptr, align 8
    store ptr %acc, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %1, i64 8, i1 false)
    call void @__copy_a.l(ptr %0)
    call void @__array_push_a.ll(ptr %0, i64 %v), !dbg !10
    %2 = load ptr, ptr %0, align 8
    ret ptr %2
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 0, ptr %1, align 8
    %2 = load ptr, ptr %arr, align 8
    %3 = tail call ptr @__schmu_f1_a.llra.l(ptr %2, i64 0), !dbg !12
    %4 = alloca ptr, align 8
    store ptr %3, ptr %4, align 8
    call void @__free_a.l(ptr %4)
    call void @__free_a.l(ptr %arr)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "varid_propagate.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_a.ll", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 34, column: 5, scope: !2)
  !7 = !DILocation(line: 35, column: 7, scope: !2)
  !8 = distinct !DISubprogram(name: "f1", linkageName: "__schmu_f1_a.llra.l", scope: !9, file: !9, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DIFile(filename: "varid_propagate.smu", directory: "")
  !10 = !DILocation(line: 3, column: 2, scope: !8)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !9, file: !9, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 6, column: 7, scope: !11)

Free array params correctly if they are returned
  $ schmu --dump-llvm pass_array_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./pass_array_param
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr ptr @__schmu_pass_a.lra.l(ptr %x) !dbg !2 {
  entry:
    ret ptr %x
  }
  
  define ptr @schmu_create() !dbg !6 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    %2 = tail call ptr @__schmu_pass_a.lra.l(ptr %0), !dbg !7
    ret ptr %2
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !8 {
  entry:
    %0 = tail call ptr @schmu_create(), !dbg !9
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_a.l(ptr %1)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "pass_array_param.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "pass", linkageName: "__schmu_pass_a.lra.l", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "pass_array_param.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "create", linkageName: "schmu_create", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 5, column: 2, scope: !6)
  !8 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 7, column: 7, scope: !8)

Refcounts for members in arrays, records and variants
  $ schmu --dump-llvm member_refcounts.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %r = type { ptr }
  %option.t.a.l = type { i32, ptr }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global ptr null, align 8
  @schmu_r = global %r zeroinitializer, align 8
  @schmu_r__2 = global ptr null, align 8
  @schmu_r__3 = global %option.t.a.l zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !32 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_a, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    %2 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_a.l(ptr %2)
    %3 = load ptr, ptr %2, align 8
    store ptr %3, ptr @schmu_r, align 8
    %4 = load ptr, ptr @schmu_a, align 8
    %5 = getelementptr i8, ptr %4, i64 16
    store i64 20, ptr %5, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %6 = load ptr, ptr @schmu_r, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    %8 = load i64, ptr %7, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %8), !dbg !34
    %9 = call ptr @malloc(i64 24)
    store ptr %9, ptr @schmu_r__2, align 8
    store i64 1, ptr %9, align 8
    %cap2 = getelementptr i64, ptr %9, i64 1
    store i64 1, ptr %cap2, align 8
    %10 = getelementptr i8, ptr %9, i64 16
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %10, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_a.l(ptr %10)
    %11 = load ptr, ptr @schmu_a, align 8
    %12 = getelementptr i8, ptr %11, i64 16
    store i64 30, ptr %12, align 8
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %13 = load ptr, ptr @schmu_r__2, align 8
    %14 = getelementptr i8, ptr %13, i64 16
    %15 = load ptr, ptr %14, align 8
    %16 = getelementptr i8, ptr %15, i64 16
    %17 = load i64, ptr %16, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp4, i64 %17), !dbg !35
    store i32 1, ptr @schmu_r__3, align 4
    %18 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %18, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_a.l(ptr %18)
    %19 = load ptr, ptr %18, align 8
    store ptr %19, ptr getelementptr inbounds (%option.t.a.l, ptr @schmu_r__3, i32 0, i32 1), align 8
    %20 = load ptr, ptr @schmu_a, align 8
    %21 = getelementptr i8, ptr %20, i64 16
    store i64 40, ptr %21, align 8
    %index = load i32, ptr @schmu_r__3, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !36
  
  then:                                             ; preds = %entry
    %clstmp7 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %22 = load ptr, ptr getelementptr inbounds (%option.t.a.l, ptr @schmu_r__3, i32 0, i32 1), align 8
    %23 = getelementptr i8, ptr %22, i64 16
    %24 = load i64, ptr %23, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp7, i64 %24), !dbg !37
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @string_println(ptr @0), !dbg !38
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    call void @__free_option.t.a.l(ptr @schmu_r__3)
    call void @__free_a.a.l(ptr @schmu_r__2)
    call void @__free_r(ptr @schmu_r)
    call void @__free_a.l(ptr @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
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
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_option.t.a.l(ptr %0) {
  entry:
    %tag1 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag1, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t.a.l, ptr %0, i32 0, i32 1
    call void @__free_a.l(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_a.a.l(ptr %0) {
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
    call void @__free_a.l(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_r(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_a.l(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "member_refcounts.smu", directory: "$TESTCASE_ROOT")
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
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_fmt_stdout_println_ll", scope: !8, file: !8, line: 292, type: !4, scopeLine: 292, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 293, column: 9, scope: !22)
  !24 = !DILocation(line: 293, column: 4, scope: !22)
  !25 = !DILocation(line: 293, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 80, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 65, column: 21, scope: !28)
  !30 = !DILocation(line: 66, column: 10, scope: !28)
  !31 = !DILocation(line: 69, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "member_refcounts.smu", directory: "")
  !34 = !DILocation(line: 5, column: 5, scope: !32)
  !35 = !DILocation(line: 10, column: 5, scope: !32)
  !36 = !DILocation(line: 14, column: 10, scope: !32)
  !37 = !DILocation(line: 14, column: 24, scope: !32)
  !38 = !DILocation(line: 14, column: 52, scope: !32)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./member_refcounts
  10
  20
  30

Make sure there are no hidden reference semantics in pattern matches
  $ schmu hidden_match_reference.smu && ./hidden_match_reference
  1

Convert Const_ptr values to Ptr in copy
  $ schmu ref_to_const.smu

Fix codegen
  $ schmu --dump-llvm codegen_nested_projections.smu
  codegen_nested_projections.smu:4.7-8: warning: Unused binding z.
  
  4 |   let z& = &y
            ^
  
  codegen_nested_projections.smu:1.5-6: warning: Unused binding t.
  
  1 | fun t() {
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @schmu_t() !dbg !2 {
  entry:
    %0 = alloca i64, align 8
    store i64 10, ptr %0, align 8
    store i64 11, ptr %0, align 8
    ret i64 11
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "codegen_nested_projections.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "t", linkageName: "schmu_t", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "codegen_nested_projections.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)

Partial move parameter
  $ schmu partially_move_parameter.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./partially_move_parameter

Partial move set
  $ schmu partial_move_set.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./partial_move_set

Track unmutated binding warnings across projections
  $ schmu projection_warnings.smu
  projection_warnings.smu:9.16-17: warning: Unused binding b.
  
  9 | fun testfn(a&, b& : int) {
                     ^
  
  projection_warnings.smu:14.7-8: warning: Unmutated mutable binding a.
  
  14 |   let a& = 0
             ^
  
  projection_warnings.smu:4.7-8: warning: Unused binding z.
  
  4 |   let z& = &y
            ^
  
  projection_warnings.smu:9.5-11: warning: Unused binding testfn.
  
  9 | fun testfn(a&, b& : int) {
          ^^^^^^
  
  projection_warnings.smu:13.5-18: warning: Unused binding single_binder.
  
  13 | fun single_binder() {
           ^^^^^^^^^^^^^
  
  projection_warnings.smu:19.5-17: warning: Unused binding mutate_outer.
  
  19 | fun mutate_outer() {
           ^^^^^^^^^^^^
  
Mutable locals must not be globals even if constexpr
  $ schmu mutable_locals.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./mutable_locals
  false
  false
  false

Partial moves out of variants with in arrays with dynamic indices
  $ schmu dyn_partial_move.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./dyn_partial_move
