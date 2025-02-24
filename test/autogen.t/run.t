Copy string literal
  $ schmu --dump-llvm string_lit.smu && valgrind -q --leak-check=yes --show-reachable=yes ./string_lit
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  %lupc_lru_u2_ = type { i64, %fmt.formatter.tu_ }
  
  @fmt_int_digits = external global ptr
  @fmt_stdout_missing_arg_msg = external global ptr
  @fmt_stdout_too_many_arg_msg = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @0 = private unnamed_addr constant { i64, i64, [9 x i8] } { i64 8, i64 8, [9 x i8] c"test {}\0A\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @fmt_prerr(ptr noalias %0)
  
  declare void @fmt_stdout_helper_printn(ptr noalias %0, ptr %1, ptr %2)
  
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
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__(ptr noalias %0) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_prerr(ptr %ret), !dbg !23
    %1 = load ptr, ptr @fmt_stdout_missing_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr %ret1, ptr %ret, ptr %1), !dbg !24
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret1), !dbg !25
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_too_many_ru_() !dbg !26 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_prerr(ptr %ret), !dbg !27
    %0 = load ptr, ptr @fmt_stdout_too_many_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr %ret1, ptr %ret, ptr %0), !dbg !28
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret1), !dbg !29
    call void @abort()
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_print1_upc_lru_u_lrupc_lru_u2_l_(ptr %fmtstr, ptr %f0, i64 %v0) !dbg !30 {
  entry:
    %__fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_ = alloca %closure, align 8
    store ptr @__fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_, ptr %__fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_, align 8
    %clsr___fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_ = alloca { ptr, ptr, %closure, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %v02 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_, i32 0, i32 3
    store i64 %v0, ptr %v02, align 8
    store ptr @__ctor_upc_lru_u_lrupc_lru_u2_l_, ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_, ptr %envptr, align 8
    %ret = alloca %lupc_lru_u2_, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_), !dbg !31
    %0 = getelementptr inbounds %lupc_lru_u2_, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 1
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %entry
    call void @__fmt_stdout_impl_fmt_fail_too_many_ru_(), !dbg !33
    call void @__free_upc_lru_u_(ptr %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %0), !dbg !34
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, ptr %str) !dbg !35 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !36
    %2 = tail call i64 @string_len(ptr %str), !dbg !37
    tail call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !38
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
    tail call void @__array_fixed_swap_items_A64c__(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !40
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !41 {
  entry:
    %v0 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %1, i32 0, i32 3
    %v01 = load i64, ptr %v0, align 8
    %eq = icmp eq i64 %i, 0
    br i1 %eq, label %then, label %else, !dbg !42
  
  then:                                             ; preds = %entry
    %sunkaddr = getelementptr inbounds i8, ptr %1, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr3 = getelementptr inbounds i8, ptr %1, i64 24
    %loadtmp2 = load ptr, ptr %sunkaddr3, align 8
    tail call void %loadtmp(ptr %0, ptr %fmter, i64 %v01, ptr %loadtmp2), !dbg !43
    ret void
  
  else:                                             ; preds = %entry
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__(ptr %0), !dbg !44
    tail call void @__free_upc_lru_u_(ptr %fmter)
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !45 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !46
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !47
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !48
    br i1 %lt, label %then4, label %ifcont, !dbg !48
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
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
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_upc_lru_u_lrupc_lru_u2_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %1, i32 0, i32 2
    call void @__copy_upc_lru_u_lrupc_lru_u2_(ptr %f0)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy_upc_lru_u_lrupc_lru_u2_(ptr %0) {
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
  
  define linkonce_odr void @__free_upc_lru_u_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_upc_lru_(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !49 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_print1_upc_lru_u_lrupc_lru_u2_l_(ptr @0, ptr %clstmp, i64 1), !dbg !51
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "string_lit.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !8, file: !8, line: 137, type: !4, scopeLine: 137, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DIFile(filename: "fmt.smu", directory: "")
  !9 = !DILocation(line: 139, column: 2, scope: !7)
  !10 = !DILocation(line: 140, column: 15, scope: !7)
  !11 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !8, file: !8, line: 28, type: !4, scopeLine: 28, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 22, type: !4, scopeLine: 22, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 24, column: 4, scope: !12)
  !14 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 56, type: !4, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 58, column: 6, scope: !14)
  !16 = !DILocation(line: 59, column: 4, scope: !14)
  !17 = !DILocation(line: 76, column: 17, scope: !14)
  !18 = !DILocation(line: 79, column: 4, scope: !14)
  !19 = !DILocation(line: 83, column: 4, scope: !14)
  !20 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 111, type: !4, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 112, column: 2, scope: !20)
  !22 = distinct !DISubprogram(name: "_fmt_stdout_impl_fmt_fail_missing", linkageName: "__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__", scope: !8, file: !8, line: 224, type: !4, scopeLine: 224, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 225, column: 6, scope: !22)
  !24 = !DILocation(line: 225, column: 17, scope: !22)
  !25 = !DILocation(line: 226, column: 9, scope: !22)
  !26 = distinct !DISubprogram(name: "_fmt_stdout_impl_fmt_fail_too_many", linkageName: "__fmt_stdout_impl_fmt_fail_too_many_ru_", scope: !8, file: !8, line: 230, type: !4, scopeLine: 230, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 231, column: 6, scope: !26)
  !28 = !DILocation(line: 231, column: 17, scope: !26)
  !29 = !DILocation(line: 232, column: 9, scope: !26)
  !30 = distinct !DISubprogram(name: "_fmt_stdout_print1", linkageName: "__fmt_stdout_print1_upc_lru_u_lrupc_lru_u2_l_", scope: !8, file: !8, line: 308, type: !4, scopeLine: 308, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !31 = !DILocation(line: 309, column: 22, scope: !30)
  !32 = !DILocation(line: 315, column: 7, scope: !30)
  !33 = !DILocation(line: 316, column: 6, scope: !30)
  !34 = !DILocation(line: 318, column: 11, scope: !30)
  !35 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 124, type: !4, scopeLine: 124, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DILocation(line: 125, column: 22, scope: !35)
  !37 = !DILocation(line: 125, column: 40, scope: !35)
  !38 = !DILocation(line: 125, column: 2, scope: !35)
  !39 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 79, type: !4, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !40 = !DILocation(line: 80, column: 6, scope: !39)
  !41 = distinct !DISubprogram(name: "__fun_fmt_stdout2", linkageName: "__fun_fmt_stdout2_Cupc_lru_u_lrupc_lru_u2_l_", scope: !8, file: !8, line: 309, type: !4, scopeLine: 309, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !42 = !DILocation(line: 311, column: 8, scope: !41)
  !43 = !DILocation(line: 311, column: 11, scope: !41)
  !44 = !DILocation(line: 312, column: 11, scope: !41)
  !45 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !46 = !DILocation(line: 65, column: 21, scope: !45)
  !47 = !DILocation(line: 66, column: 10, scope: !45)
  !48 = !DILocation(line: 69, column: 11, scope: !45)
  !49 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !50, file: !50, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !50 = !DIFile(filename: "string_lit.smu", directory: "")
  !51 = !DILocation(line: 1, column: 5, scope: !49)
  test 1

Copy array of strings
  $ schmu --dump-llvm arr_of_strings.smu && valgrind -q --leak-check=yes --show-reachable=yes ./arr_of_strings
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"test\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"toast\00" }
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    store ptr %0, ptr @schmu_a, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
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
    %4 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_2ac2_(ptr %4)
    %5 = load ptr, ptr %4, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = getelementptr ptr, ptr %6, i64 1
    %8 = load ptr, ptr %7, align 8
    call void @string_println(ptr %8), !dbg !6
    call void @__free_2ac2_(ptr %4)
    call void @__free_2ac2_(ptr @schmu_a)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
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
  
  define linkonce_odr void @__copy_2ac2_(ptr %0) {
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
    call void @__copy_ac_(ptr %8)
    %9 = add i64 %5, 1
    store i64 %9, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "arr_of_strings.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "arr_of_strings.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 2, scope: !2)
  toast

Copy records
  $ schmu --dump-llvm records.smu && valgrind -q --leak-check=yes --show-reachable=yes ./records
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %contdac_lal2__ = type { %t_ }
  %t_ = type { double, ptr, i64, ptr }
  
  @schmu_a = global %contdac_lal2__ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"lul\00" }
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    store double 1.000000e+01, ptr @schmu_a, align 8
    %0 = alloca ptr, align 8
    store ptr @0, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    store ptr %2, ptr getelementptr inbounds (%t_, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 10, ptr getelementptr inbounds (%t_, ptr @schmu_a, i32 0, i32 2), align 8
    %3 = call ptr @malloc(i64 40)
    %arr = alloca ptr, align 8
    store ptr %3, ptr %arr, align 8
    store i64 3, ptr %3, align 8
    %cap = getelementptr i64, ptr %3, i64 1
    store i64 3, ptr %cap, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 10, ptr %4, align 8
    %"1" = getelementptr i64, ptr %4, i64 1
    store i64 20, ptr %"1", align 8
    %"2" = getelementptr i64, ptr %4, i64 2
    store i64 30, ptr %"2", align 8
    store ptr %3, ptr getelementptr inbounds (%t_, ptr @schmu_a, i32 0, i32 3), align 8
    %5 = alloca %contdac_lal2__, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %5, ptr align 8 @schmu_a, i64 32, i1 false)
    call void @__copy_dac_lal3_(ptr %5)
    %6 = getelementptr inbounds %t_, ptr %5, i32 0, i32 1
    %7 = load ptr, ptr %6, align 8
    call void @string_println(ptr %7), !dbg !6
    call void @__free_dac_lal3_(ptr %5)
    call void @__free_dac_lal3_(ptr @schmu_a)
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
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_dac_lal2_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %t_, ptr %0, i32 0, i32 1
    call void @__copy_ac_(ptr %1)
    %2 = getelementptr inbounds %t_, ptr %0, i32 0, i32 3
    call void @__copy_al_(ptr %2)
    ret void
  }
  
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
  
  define linkonce_odr void @__copy_dac_lal3_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__copy_dac_lal2_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_dac_lal2_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %t_, ptr %0, i32 0, i32 1
    call void @__free_ac_(ptr %1)
    %2 = getelementptr inbounds %t_, ptr %0, i32 0, i32 3
    call void @__free_al_(ptr %2)
    ret void
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_dac_lal3_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_dac_lal2_(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "records.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "records.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 6, scope: !2)
  lul

Copy variants
  $ schmu variants.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./variants
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tac_l__ = type { i32, %ac_l_ }
  %ac_l_ = type { ptr, i64 }
  
  @schmu_a = global %option.tac_l__ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"thing\00" }
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    store i32 1, ptr @schmu_a, align 4
    %0 = alloca ptr, align 8
    store ptr @0, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    store ptr %2, ptr getelementptr inbounds (%option.tac_l__, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 0, ptr getelementptr inbounds (%option.tac_l__, ptr @schmu_a, i32 0, i32 1, i32 1), align 8
    %3 = alloca %option.tac_l__, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 @schmu_a, i64 24, i1 false)
    call void @__copy_vac_l2_(ptr %3)
    %index = load i32, ptr %3, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont, !dbg !6
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tac_l__, ptr %3, i32 0, i32 1
    %4 = getelementptr inbounds %ac_l_, ptr %data, i32 0, i32 1
    %5 = load ptr, ptr %data, align 8
    call void @string_println(ptr %5), !dbg !7
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    call void @__free_vac_l2_(ptr %3)
    call void @__free_vac_l2_(ptr @schmu_a)
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
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__copy_ac_l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__copy_ac_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__copy_vac_l2_(ptr %0) {
  entry:
    %tag1 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag1, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.tac_l__, ptr %0, i32 0, i32 1
    call void @__copy_ac_l_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_ac_l_(ptr %0) {
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
  
  define linkonce_odr void @__free_vac_l2_(ptr %0) {
  entry:
    %tag1 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag1, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.tac_l__, ptr %0, i32 0, i32 1
    call void @__free_ac_l_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "variants.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "variants.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 4, column: 2, scope: !2)
  !7 = !DILocation(line: 4, column: 16, scope: !2)
  thing

Copy closures
  $ schmu --dump-llvm closure.smu && valgrind -q --leak-check=yes --show-reachable=yes ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %"2l_" = type { i64, i64 }
  %"2rl2_l_" = type { %closure, i64 }
  
  @schmu_c = global %closure zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"hello\00" }
  
  declare void @string_println(ptr %0)
  
  define void @__fun_schmu0(ptr %0) !dbg !2 {
  entry:
    %a = getelementptr inbounds { ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    %a1 = load ptr, ptr %a, align 8
    %1 = getelementptr i8, ptr %a1, i64 16
    %2 = load ptr, ptr %1, align 8
    tail call void @string_println(ptr %2), !dbg !6
    ret void
  }
  
  define i64 @schmu_capture(ptr %0) !dbg !7 {
  entry:
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %a1 = load i64, ptr %a, align 8
    %add = add i64 %a1, 1
    ret i64 %add
  }
  
  define i64 @schmu_capture__2(ptr %0) !dbg !8 {
  entry:
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %a1 = load i64, ptr %a, align 8
    %add = add i64 %a1, 1
    ret i64 %add
  }
  
  define void @schmu_hmm(ptr noalias %0) !dbg !9 {
  entry:
    %1 = alloca %"2l_", align 8
    store i64 1, ptr %1, align 8
    %"1" = getelementptr inbounds %"2l_", ptr %1, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    store ptr @schmu_capture, ptr %0, align 8
    %2 = tail call ptr @malloc(i64 24)
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 2
    store i64 1, ptr %a, align 8
    store ptr @__ctor_l_, ptr %2, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %2, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_hmm_move(ptr noalias %0) !dbg !10 {
  entry:
    %1 = alloca %"2l_", align 8
    store i64 1, ptr %1, align 8
    %"1" = getelementptr inbounds %"2l_", ptr %1, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    store ptr @schmu_capture__2, ptr %0, align 8
    %2 = tail call ptr @malloc(i64 24)
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 2
    store i64 1, ptr %a, align 8
    store ptr @__ctor_l_, ptr %2, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %2, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_test(ptr noalias %0) !dbg !11 {
  entry:
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = alloca ptr, align 8
    store ptr @0, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %2, ptr align 8 %3, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %2)
    store ptr @__fun_schmu0, ptr %0, align 8
    %4 = tail call ptr @malloc(i64 24)
    %a = getelementptr inbounds { ptr, ptr, ptr }, ptr %4, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a, ptr align 8 %arr, i64 8, i1 false)
    tail call void @__copy_2ac2_(ptr %a)
    %5 = load ptr, ptr %a, align 8
    store ptr %5, ptr %a, align 8
    store ptr @__ctor_2ac3_, ptr %4, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr }, ptr %4, i32 0, i32 1
    store ptr @__dtor_2ac3_, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %4, ptr %envptr, align 8
    call void @__free_2ac2_(ptr %arr)
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
  
  define linkonce_odr void @__copy_2ac2_(ptr %0) {
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
    call void @__copy_ac_(ptr %8)
    %9 = add i64 %5, 1
    store i64 %9, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define linkonce_odr ptr @__ctor_2ac3_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    %a = getelementptr inbounds { ptr, ptr, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_2ac2_(ptr %a)
    ret ptr %1
  }
  
  define linkonce_odr void @__dtor_2ac3_(ptr %0) {
  entry:
    %a = getelementptr inbounds { ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    call void @__free_2ac2_(ptr %a)
    call void @free(ptr %0)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !12 {
  entry:
    %0 = alloca %"2rl2_l_", align 8
    %clstmp = alloca %closure, align 8
    store ptr @schmu_hmm, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %clstmp, i64 16, i1 false)
    call void @__copy_2rl2_(ptr %0)
    %"1" = getelementptr inbounds %"2rl2_l_", ptr %0, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    %1 = alloca %"2rl2_l_", align 8
    %clstmp2 = alloca %closure, align 8
    store ptr @schmu_hmm_move, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %clstmp2, i64 16, i1 false)
    call void @__copy_2rl2_(ptr %1)
    %"15" = getelementptr inbounds %"2rl2_l_", ptr %1, i32 0, i32 1
    store i64 0, ptr %"15", align 8
    call void @schmu_test(ptr @schmu_c), !dbg !13
    %2 = alloca %closure, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 @schmu_c, i64 16, i1 false)
    call void @__copy_ru_(ptr %2)
    %loadtmp = load ptr, ptr %2, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %2, i32 0, i32 1
    %loadtmp7 = load ptr, ptr %envptr6, align 8
    call void %loadtmp(ptr %loadtmp7), !dbg !14
    call void @__free_ru_(ptr %2)
    call void @__free_ru_(ptr @schmu_c)
    call void @__free_2rl2_l_(ptr %1)
    call void @__free_2rl2_l_(ptr %0)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_2rl2_(ptr %0) {
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
  
  define linkonce_odr void @__copy_ru_(ptr %0) {
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
  
  define linkonce_odr void @__free_ru_(ptr %0) {
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
  
  define linkonce_odr void @__free_2rl2_(ptr %0) {
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
  
  define linkonce_odr void @__free_2rl2_l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_2rl2_(ptr %1)
    ret void
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "closure.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !3, file: !3, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "closure.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 20, column: 14, scope: !2)
  !7 = distinct !DISubprogram(name: "capture", linkageName: "schmu_capture", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = distinct !DISubprogram(name: "capture", linkageName: "schmu_capture__2", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = distinct !DISubprogram(name: "hmm", linkageName: "schmu_hmm", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = distinct !DISubprogram(name: "hmm_move", linkageName: "schmu_hmm_move", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !3, file: !3, line: 18, type: !4, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 23, column: 8, scope: !12)
  !14 = !DILocation(line: 24, scope: !12)
  hello

Copy string literal on move
  $ schmu copy_string_lit.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./copy_string_lit
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @schmu_a = global ptr null, align 8
  @schmu_b = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"aoeu\00" }
  
  declare void @string_modify_buf(ptr noalias %0, ptr %1)
  
  declare void @string_println(ptr %0)
  
  define void @__fun_schmu0(ptr noalias %arr) !dbg !2 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = getelementptr inbounds i8, ptr %1, i64 1
    store i8 105, ptr %2, align 1
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_a, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = alloca ptr, align 8
    store ptr @0, ptr %2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 8 %2, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %1)
    %3 = alloca ptr, align 8
    store ptr @0, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 %3, i64 8, i1 false)
    tail call void @__copy_ac_(ptr @schmu_b)
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @string_modify_buf(ptr @schmu_b, ptr %clstmp), !dbg !7
    %4 = load ptr, ptr @schmu_b, align 8
    call void @string_println(ptr %4), !dbg !8
    call void @string_println(ptr @0), !dbg !9
    %5 = load ptr, ptr @schmu_a, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = load ptr, ptr %6, align 8
    call void @string_println(ptr %7), !dbg !10
    call void @__free_ac_(ptr @schmu_b)
    call void @__free_2ac2_(ptr @schmu_a)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "copy_string_lit.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "copy_string_lit.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 3, scope: !6)
  !8 = !DILocation(line: 6, scope: !6)
  !9 = !DILocation(line: 7, scope: !6)
  !10 = !DILocation(line: 8, scope: !6)
  aieu
  aoeu
  aoeu

Correctly copy array
  $ schmu copy_array.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./copy_array

Correctly copy rc
  $ schmu rc.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./rc
