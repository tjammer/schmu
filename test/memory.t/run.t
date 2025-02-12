Drop last element
  $ schmu --dump-llvm array_drop_back.smu && valgrind -q --leak-check=yes --show-reachable=yes ./array_drop_back
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tal__ = type { i32, ptr }
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_nested = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"some\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_println(ptr %0)
  
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
  
  define linkonce_odr { i32, i64 } @__array_pop_back_2al2_rval2__(ptr noalias %arr) !dbg !7 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, 0
    br i1 %eq, label %then, label %else, !dbg !8
  
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
  
  define linkonce_odr void @__fmt_endl_upc_lru_u_ru_(ptr %p) !dbg !9 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !11
    call void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %ret), !dbg !12
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %fm) !dbg !13 {
  entry:
    tail call void @__free_except1_upc_lru_u_(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !14 {
  entry:
    %1 = alloca %fmt.formatter.tu_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !15
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !16 {
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
    br i1 %andtmp, label %then, label %else, !dbg !17
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 1), !dbg !18
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
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !19
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
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !20
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !21
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i64 %i) !dbg !22 {
  entry:
    tail call void @__fmt_int_base_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, i64 %i, i64 10), !dbg !23
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %fmt, i64 %value) !dbg !24 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !25
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.tu_, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !26
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret2), !dbg !27
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !28 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64c__(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !29
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !30 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !31
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !33
    br i1 %lt, label %then4, label %ifcont, !dbg !33
  
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !34 {
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
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %6 = load ptr, ptr @schmu_nested, align 8
    %7 = load i64, ptr %6, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %7), !dbg !36
    %ret = alloca %option.tal__, align 8
    %8 = call { i32, i64 } @__array_pop_back_2al2_rval2__(ptr @schmu_nested), !dbg !37
    store { i32, i64 } %8, ptr %ret, align 8
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont, !dbg !38
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tal__, ptr %ret, i32 0, i32 1
    call void @string_println(ptr @0), !dbg !39
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %clstmp9 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp9, align 8
    %envptr11 = getelementptr inbounds %closure, ptr %clstmp9, i32 0, i32 1
    store ptr null, ptr %envptr11, align 8
    %9 = load ptr, ptr @schmu_nested, align 8
    %10 = load i64, ptr %9, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp9, i64 %10), !dbg !40
    %ret13 = alloca %option.tal__, align 8
    %11 = call { i32, i64 } @__array_pop_back_2al2_rval2__(ptr @schmu_nested), !dbg !41
    store { i32, i64 } %11, ptr %ret13, align 8
    %clstmp14 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp14, align 8
    %envptr16 = getelementptr inbounds %closure, ptr %clstmp14, i32 0, i32 1
    store ptr null, ptr %envptr16, align 8
    %12 = load ptr, ptr @schmu_nested, align 8
    %13 = load i64, ptr %12, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp14, i64 %13), !dbg !42
    %ret18 = alloca %option.tal__, align 8
    %14 = call { i32, i64 } @__array_pop_back_2al2_rval2__(ptr @schmu_nested), !dbg !43
    store { i32, i64 } %14, ptr %ret18, align 8
    %index20 = load i32, ptr %ret18, align 4
    %eq21 = icmp eq i32 %index20, 1
    br i1 %eq21, label %then22, label %else24, !dbg !44
  
  then22:                                           ; preds = %ifcont
    %data23 = getelementptr inbounds %option.tal__, ptr %ret18, i32 0, i32 1
    br label %ifcont25
  
  else24:                                           ; preds = %ifcont
    call void @string_println(ptr @1), !dbg !45
    br label %ifcont25
  
  ifcont25:                                         ; preds = %else24, %then22
    %clstmp26 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp26, align 8
    %envptr28 = getelementptr inbounds %closure, ptr %clstmp26, i32 0, i32 1
    store ptr null, ptr %envptr28, align 8
    %15 = load ptr, ptr @schmu_nested, align 8
    %16 = load i64, ptr %15, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp26, i64 %16), !dbg !46
    call void @__free_val2_(ptr %ret18)
    call void @__free_val2_(ptr %ret13)
    call void @__free_val2_(ptr %ret)
    call void @__free_2al2_(ptr @schmu_nested)
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "array_drop_back.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_pop_back", linkageName: "__array_pop_back_2al2_rval2__", scope: !3, file: !3, line: 85, type: !4, scopeLine: 85, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 87, column: 5, scope: !7)
  !9 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !10, file: !10, line: 130, type: !4, scopeLine: 130, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DIFile(filename: "fmt.smu", directory: "")
  !11 = !DILocation(line: 132, column: 2, scope: !9)
  !12 = !DILocation(line: 133, column: 15, scope: !9)
  !13 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !10, file: !10, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !10, file: !10, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 22, column: 4, scope: !14)
  !16 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !10, file: !10, line: 54, type: !4, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !17 = !DILocation(line: 56, column: 6, scope: !16)
  !18 = !DILocation(line: 57, column: 4, scope: !16)
  !19 = !DILocation(line: 74, column: 17, scope: !16)
  !20 = !DILocation(line: 77, column: 4, scope: !16)
  !21 = !DILocation(line: 81, column: 4, scope: !16)
  !22 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !10, file: !10, line: 109, type: !4, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 110, column: 2, scope: !22)
  !24 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_", scope: !10, file: !10, line: 220, type: !4, scopeLine: 220, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !25 = !DILocation(line: 221, column: 9, scope: !24)
  !26 = !DILocation(line: 221, column: 4, scope: !24)
  !27 = !DILocation(line: 221, column: 31, scope: !24)
  !28 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !10, file: !10, line: 77, type: !4, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 78, column: 6, scope: !28)
  !30 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !10, file: !10, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !31 = !DILocation(line: 63, column: 21, scope: !30)
  !32 = !DILocation(line: 64, column: 10, scope: !30)
  !33 = !DILocation(line: 67, column: 11, scope: !30)
  !34 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !35, file: !35, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !35 = !DIFile(filename: "array_drop_back.smu", directory: "")
  !36 = !DILocation(line: 2, column: 5, scope: !34)
  !37 = !DILocation(line: 3, column: 6, scope: !34)
  !38 = !DILocation(line: 3, column: 32, scope: !34)
  !39 = !DILocation(line: 3, column: 41, scope: !34)
  !40 = !DILocation(line: 4, column: 5, scope: !34)
  !41 = !DILocation(line: 5, scope: !34)
  !42 = !DILocation(line: 6, column: 5, scope: !34)
  !43 = !DILocation(line: 7, column: 6, scope: !34)
  !44 = !DILocation(line: 7, column: 31, scope: !34)
  !45 = !DILocation(line: 7, column: 50, scope: !34)
  !46 = !DILocation(line: 8, column: 5, scope: !34)
  2
  some
  1
  0
  none
  0

Array push
  $ schmu --dump-llvm array_push.smu && valgrind -q --leak-check=yes --show-reachable=yes ./array_push
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global ptr null, align 8
  @schmu_b = global ptr null, align 8
  @schmu_nested = global ptr null, align 8
  @schmu_a__2 = global ptr null, align 8
  
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
  
  define linkonce_odr void @__array_push_2al2_al__(ptr noalias %arr, ptr %value) !dbg !7 {
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
    %9 = getelementptr inbounds ptr, ptr %8, i64 %2
    store ptr %value, ptr %9, align 8
    %10 = load ptr, ptr %arr, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %10, align 8
    ret void
  }
  
  define linkonce_odr void @__array_push_al_l_(ptr noalias %arr, i64 %value) !dbg !10 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5, !dbg !11
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !12
  
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
  
  define linkonce_odr void @__fmt_endl_upc_lru_u_ru_(ptr %p) !dbg !13 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !15
    call void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %ret), !dbg !16
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %fm) !dbg !17 {
  entry:
    tail call void @__free_except1_upc_lru_u_(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !18 {
  entry:
    %1 = alloca %fmt.formatter.tu_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !19
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !20 {
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
    br i1 %andtmp, label %then, label %else, !dbg !21
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 1), !dbg !22
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
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !23
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
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !24
    call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !25
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, i64 %i) !dbg !26 {
  entry:
    tail call void @__fmt_int_base_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, i64 %i, i64 10), !dbg !27
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %fmt, i64 %value) !dbg !28 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !29
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.tu_, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !30
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret2), !dbg !31
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !32 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64c__(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !33
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !34 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !35
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !36
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !37
    br i1 %lt, label %then4, label %ifcont, !dbg !37
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_in_fun() !dbg !38 {
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
    call void @__array_push_al_l_(ptr %0, i64 30), !dbg !40
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %4 = load ptr, ptr %0, align 8
    %5 = load i64, ptr %4, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %5), !dbg !41
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %6 = load ptr, ptr %3, align 8
    %7 = load i64, ptr %6, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp1, i64 %7), !dbg !42
    call void @__free_al_(ptr %3)
    call void @__free_al_(ptr %0)
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
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !43 {
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
    tail call void @__array_push_al_l_(ptr @schmu_a, i64 30), !dbg !44
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %2 = load ptr, ptr @schmu_a, align 8
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %3), !dbg !45
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %4 = load ptr, ptr @schmu_b, align 8
    %5 = load i64, ptr %4, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp1, i64 %5), !dbg !46
    call void @schmu_in_fun(), !dbg !47
    %6 = call ptr @malloc(i64 32)
    store ptr %6, ptr @schmu_nested, align 8
    store i64 2, ptr %6, align 8
    %cap6 = getelementptr i64, ptr %6, i64 1
    store i64 2, ptr %cap6, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    %8 = call ptr @malloc(i64 32)
    store ptr %8, ptr %7, align 8
    store i64 2, ptr %8, align 8
    %cap9 = getelementptr i64, ptr %8, i64 1
    store i64 2, ptr %cap9, align 8
    %9 = getelementptr i8, ptr %8, i64 16
    store i64 0, ptr %9, align 8
    %"111" = getelementptr i64, ptr %9, i64 1
    store i64 1, ptr %"111", align 8
    %"112" = getelementptr ptr, ptr %7, i64 1
    %10 = call ptr @malloc(i64 32)
    store ptr %10, ptr %"112", align 8
    store i64 2, ptr %10, align 8
    %cap14 = getelementptr i64, ptr %10, i64 1
    store i64 2, ptr %cap14, align 8
    %11 = getelementptr i8, ptr %10, i64 16
    store i64 2, ptr %11, align 8
    %"116" = getelementptr i64, ptr %11, i64 1
    store i64 3, ptr %"116", align 8
    %12 = call ptr @malloc(i64 32)
    store ptr %12, ptr @schmu_a__2, align 8
    store i64 2, ptr %12, align 8
    %cap18 = getelementptr i64, ptr %12, i64 1
    store i64 2, ptr %cap18, align 8
    %13 = getelementptr i8, ptr %12, i64 16
    store i64 4, ptr %13, align 8
    %"120" = getelementptr i64, ptr %13, i64 1
    store i64 5, ptr %"120", align 8
    %14 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %14, ptr align 8 @schmu_a__2, i64 8, i1 false)
    call void @__copy_al_(ptr %14)
    %15 = load ptr, ptr %14, align 8
    call void @__array_push_2al2_al__(ptr @schmu_nested, ptr %15), !dbg !48
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
    %cap22 = getelementptr i64, ptr %26, i64 1
    store i64 2, ptr %cap22, align 8
    %27 = getelementptr i8, ptr %26, i64 16
    store i64 4, ptr %27, align 8
    %"124" = getelementptr i64, ptr %27, i64 1
    store i64 5, ptr %"124", align 8
    call void @__array_push_2al2_al__(ptr @schmu_nested, ptr %26), !dbg !49
    %28 = load ptr, ptr @schmu_nested, align 8
    %29 = getelementptr i8, ptr %28, i64 16
    %30 = getelementptr ptr, ptr %29, i64 1
    %31 = call ptr @malloc(i64 32)
    %arr25 = alloca ptr, align 8
    store ptr %31, ptr %arr25, align 8
    store i64 2, ptr %31, align 8
    %cap27 = getelementptr i64, ptr %31, i64 1
    store i64 2, ptr %cap27, align 8
    %32 = getelementptr i8, ptr %31, i64 16
    store i64 4, ptr %32, align 8
    %"129" = getelementptr i64, ptr %32, i64 1
    store i64 5, ptr %"129", align 8
    call void @__free_al_(ptr %30)
    store ptr %31, ptr %30, align 8
    %33 = load ptr, ptr @schmu_nested, align 8
    %34 = getelementptr i8, ptr %33, i64 16
    %35 = getelementptr ptr, ptr %34, i64 1
    %36 = call ptr @malloc(i64 32)
    %arr30 = alloca ptr, align 8
    store ptr %36, ptr %arr30, align 8
    store i64 2, ptr %36, align 8
    %cap32 = getelementptr i64, ptr %36, i64 1
    store i64 2, ptr %cap32, align 8
    %37 = getelementptr i8, ptr %36, i64 16
    store i64 4, ptr %37, align 8
    %"134" = getelementptr i64, ptr %37, i64 1
    store i64 5, ptr %"134", align 8
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "array_push.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_2al2_al__", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 34, column: 5, scope: !7)
  !9 = !DILocation(line: 35, column: 7, scope: !7)
  !10 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_al_l_", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = !DILocation(line: 34, column: 5, scope: !10)
  !12 = !DILocation(line: 35, column: 7, scope: !10)
  !13 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !14, file: !14, line: 130, type: !4, scopeLine: 130, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !14 = !DIFile(filename: "fmt.smu", directory: "")
  !15 = !DILocation(line: 132, column: 2, scope: !13)
  !16 = !DILocation(line: 133, column: 15, scope: !13)
  !17 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !14, file: !14, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !14, file: !14, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !19 = !DILocation(line: 22, column: 4, scope: !18)
  !20 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !14, file: !14, line: 54, type: !4, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 56, column: 6, scope: !20)
  !22 = !DILocation(line: 57, column: 4, scope: !20)
  !23 = !DILocation(line: 74, column: 17, scope: !20)
  !24 = !DILocation(line: 77, column: 4, scope: !20)
  !25 = !DILocation(line: 81, column: 4, scope: !20)
  !26 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !14, file: !14, line: 109, type: !4, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 110, column: 2, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_", scope: !14, file: !14, line: 220, type: !4, scopeLine: 220, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 221, column: 9, scope: !28)
  !30 = !DILocation(line: 221, column: 4, scope: !28)
  !31 = !DILocation(line: 221, column: 31, scope: !28)
  !32 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !14, file: !14, line: 77, type: !4, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DILocation(line: 78, column: 6, scope: !32)
  !34 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !14, file: !14, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !35 = !DILocation(line: 63, column: 21, scope: !34)
  !36 = !DILocation(line: 64, column: 10, scope: !34)
  !37 = !DILocation(line: 67, column: 11, scope: !34)
  !38 = distinct !DISubprogram(name: "in_fun", linkageName: "schmu_in_fun", scope: !39, file: !39, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !39 = !DIFile(filename: "array_push.smu", directory: "")
  !40 = !DILocation(line: 13, column: 2, scope: !38)
  !41 = !DILocation(line: 15, column: 7, scope: !38)
  !42 = !DILocation(line: 16, column: 7, scope: !38)
  !43 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !39, file: !39, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !44 = !DILocation(line: 4, scope: !43)
  !45 = !DILocation(line: 6, column: 5, scope: !43)
  !46 = !DILocation(line: 7, column: 5, scope: !43)
  !47 = !DILocation(line: 19, scope: !43)
  !48 = !DILocation(line: 23, scope: !43)
  !49 = !DILocation(line: 26, scope: !43)
  3
  2
  3
  2

Don't free string literals
  $ schmu borrow_string_lit.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./borrow_string_lit

Use captured record-field functions
  $ schmu capture_record_pattern.smu && ./capture_record_pattern
  3
  printing 0
  printing 1.1

Monomorphization in closures
  $ schmu --dump-llvm closure_monomorph.smu && ./closure_monomorph
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.tu_ = type { %closure }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_arr = global ptr null, align 8
  @schmu_arr__2 = global ptr null, align 8
  
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
  
  define linkonce_odr void @__array_swap_items_al__(ptr noalias %arr, i64 %i, i64 %j) !dbg !12 {
  entry:
    %eq = icmp eq i64 %i, %j
    %0 = xor i1 %eq, true
    br i1 %0, label %then, label %ifcont, !dbg !13
  
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
  
  define linkonce_odr void @__fmt_endl_upc_lru_u_ru_(ptr %p) !dbg !14 {
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
  
  define linkonce_odr void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %fmt, i64 %value) !dbg !29 {
  entry:
    %ret = alloca %fmt.formatter.tu_, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !30
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.tu_, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !31
    call void @__fmt_endl_upc_lru_u_ru_(ptr %ret2), !dbg !32
    ret void
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
  
  define linkonce_odr i1 @__fun_iter5_lClru__(i64 %x, ptr %0) !dbg !35 {
  entry:
    %f = getelementptr inbounds { ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(i64 %x, ptr %loadtmp1), !dbg !37
    ret i1 true
  }
  
  define linkonce_odr void @__fun_schmu0_Cal_2lrl_ll_(i64 %j, ptr %0) !dbg !38 {
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
    %5 = tail call i64 %loadtmp(i64 %4, i64 %pivot3, ptr %loadtmp4), !dbg !40
    %lt = icmp slt i64 %5, 0
    br i1 %lt, label %then, label %ifcont, !dbg !40
  
  then:                                             ; preds = %entry
    %6 = load i64, ptr %i2, align 8
    %add = add i64 %6, 1
    store i64 %add, ptr %i2, align 8
    tail call void @__array_swap_items_al__(ptr %arr1, i64 %add, i64 %j), !dbg !41
    ret void
  
  ifcont:                                           ; preds = %entry
    ret void
  }
  
  define i64 @__fun_schmu1(i64 %a, i64 %b) !dbg !42 {
  entry:
    %sub = sub i64 %a, %b
    ret i64 %sub
  }
  
  define i1 @__fun_schmu2(ptr %__curry0) !dbg !43 {
  entry:
    %0 = load ptr, ptr @schmu_arr, align 8
    %1 = tail call i1 @__array_iter_al_lrb__(ptr %0, ptr %__curry0), !dbg !44
    ret i1 %1
  }
  
  define void @__fun_schmu3(i64 %i) !dbg !45 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %i), !dbg !46
    ret void
  }
  
  define linkonce_odr void @__fun_schmu4_Cal_2lrl_ll_(i64 %j, ptr %0) !dbg !47 {
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
    %5 = tail call i64 %loadtmp(i64 %4, i64 %pivot3, ptr %loadtmp4), !dbg !48
    %lt = icmp slt i64 %5, 0
    br i1 %lt, label %then, label %ifcont, !dbg !48
  
  then:                                             ; preds = %entry
    %6 = load i64, ptr %i2, align 8
    %add = add i64 %6, 1
    store i64 %add, ptr %i2, align 8
    tail call void @__array_swap_items_al__(ptr %arr1, i64 %add, i64 %j), !dbg !49
    ret void
  
  ifcont:                                           ; preds = %entry
    ret void
  }
  
  define i64 @__fun_schmu5(i64 %a, i64 %b) !dbg !50 {
  entry:
    %sub = sub i64 %a, %b
    ret i64 %sub
  }
  
  define i1 @__fun_schmu6(ptr %__curry0) !dbg !51 {
  entry:
    %0 = load ptr, ptr @schmu_arr__2, align 8
    %1 = tail call i1 @__array_iter_al_lrb__(ptr %0, ptr %__curry0), !dbg !52
    ret i1 %1
  }
  
  define void @__fun_schmu7(i64 %i) !dbg !53 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %i), !dbg !54
    ret void
  }
  
  define linkonce_odr void @__iter_iter_lrb_rb_lru__(ptr %it, ptr %f) !dbg !55 {
  entry:
    %__fun_iter5_lClru__ = alloca %closure, align 8
    store ptr @__fun_iter5_lClru__, ptr %__fun_iter5_lClru__, align 8
    %clsr___fun_iter5_lClru__ = alloca { ptr, ptr, %closure }, align 8
    %f1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___fun_iter5_lClru__, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f1, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_lru2_, ptr %clsr___fun_iter5_lClru__, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___fun_iter5_lClru__, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_iter5_lClru__, i32 0, i32 1
    store ptr %clsr___fun_iter5_lClru__, ptr %envptr, align 8
    %loadtmp = load ptr, ptr %it, align 8
    %envptr2 = getelementptr inbounds %closure, ptr %it, i32 0, i32 1
    %loadtmp3 = load ptr, ptr %envptr2, align 8
    %0 = call i1 %loadtmp(ptr %__fun_iter5_lClru__, ptr %loadtmp3), !dbg !56
    ret void
  }
  
  define linkonce_odr i64 @__schmu_partition__2_al_C2lrl__(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !57 {
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
    %__fun_schmu4_Cal_2lrl_ll_ = alloca %closure, align 8
    store ptr @__fun_schmu4_Cal_2lrl_ll_, ptr %__fun_schmu4_Cal_2lrl_ll_, align 8
    %clsr___fun_schmu4_Cal_2lrl_ll_ = alloca { ptr, ptr, ptr, %closure, ptr, i64 }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Cal_2lrl_ll_, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cmp2 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Cal_2lrl_ll_, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp2, ptr align 1 %cmp, i64 16, i1 false)
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Cal_2lrl_ll_, i32 0, i32 4
    store ptr %6, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Cal_2lrl_ll_, i32 0, i32 5
    store i64 %5, ptr %pivot, align 8
    store ptr @__ctor_al_2lrl_2l_, ptr %clsr___fun_schmu4_Cal_2lrl_ll_, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Cal_2lrl_ll_, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu4_Cal_2lrl_ll_, i32 0, i32 1
    store ptr %clsr___fun_schmu4_Cal_2lrl_ll_, ptr %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, ptr %__fun_schmu4_Cal_2lrl_ll_), !dbg !58
    %7 = load i64, ptr %6, align 8
    %add = add i64 %7, 1
    call void @__array_swap_items_al__(ptr %arr, i64 %add, i64 %hi), !dbg !59
    ret i64 %add
  }
  
  define linkonce_odr i64 @__schmu_partition_al_C2lrl__(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !60 {
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
    call void @prelude_iter_range(i64 %lo, i64 %hi, ptr %__fun_schmu0_Cal_2lrl_ll_), !dbg !61
    %7 = load i64, ptr %6, align 8
    %add = add i64 %7, 1
    call void @__array_swap_items_al__(ptr %arr, i64 %add, i64 %hi), !dbg !62
    ret i64 %add
  }
  
  define linkonce_odr void @__schmu_quicksort__2_al_Cal_2lrlC2lrl2__(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !63 {
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
    br i1 %andtmp, label %then, label %else, !dbg !64
  
  then:                                             ; preds = %cont
    store i1 true, ptr %2, align 1
    ret void
  
  else:                                             ; preds = %cont
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr6 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp3 = load ptr, ptr %sunkaddr6, align 8
    %7 = tail call i64 %loadtmp(ptr %arr, i64 %5, i64 %hi, ptr %loadtmp3), !dbg !65
    %sub = sub i64 %7, 1
    tail call void @__schmu_quicksort__2_al_Cal_2lrlC2lrl2__(ptr %arr, i64 %5, i64 %sub, ptr %0), !dbg !66
    %add = add i64 %7, 1
    store ptr %arr, ptr %1, align 8
    store i64 %add, ptr %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_quicksort_al_Cal_2lrlC2lrl2__(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !67 {
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
    br i1 %andtmp, label %then, label %else, !dbg !68
  
  then:                                             ; preds = %cont
    store i1 true, ptr %2, align 1
    ret void
  
  else:                                             ; preds = %cont
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr6 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp3 = load ptr, ptr %sunkaddr6, align 8
    %7 = tail call i64 %loadtmp(ptr %arr, i64 %5, i64 %hi, ptr %loadtmp3), !dbg !69
    %sub = sub i64 %7, 1
    tail call void @__schmu_quicksort_al_Cal_2lrlC2lrl2__(ptr %arr, i64 %5, i64 %sub, ptr %0), !dbg !70
    %add = add i64 %7, 1
    store ptr %arr, ptr %1, align 8
    store i64 %add, ptr %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_sort__2_al_2lrl__(ptr noalias %arr, ptr %cmp) !dbg !71 {
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
    call void @__schmu_quicksort__2_al_Cal_2lrlC2lrl2__(ptr %arr, i64 0, i64 %sub, ptr %clsr___schmu_quicksort__2_al_Cal_2lrlC2lrl2__), !dbg !72
    ret void
  }
  
  define linkonce_odr void @__schmu_sort_al_2lrl__(ptr noalias %arr, ptr %cmp) !dbg !73 {
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
    call void @__schmu_quicksort_al_Cal_2lrlC2lrl2__(ptr %arr, i64 0, i64 %sub, ptr %clsr___schmu_quicksort_al_Cal_2lrlC2lrl2__), !dbg !74
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !75 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !76
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !77
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !78
    br i1 %lt, label %then4, label %ifcont, !dbg !78
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
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
  
  define linkonce_odr ptr @__ctor_A64c_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !79 {
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
    call void @__schmu_sort_al_2lrl__(ptr @schmu_arr, ptr %clstmp), !dbg !80
    %clstmp1 = alloca %closure, align 8
    store ptr @__fun_schmu2, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %clstmp4 = alloca %closure, align 8
    store ptr @__fun_schmu3, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    call void @__iter_iter_lrb_rb_lru__(ptr %clstmp1, ptr %clstmp4), !dbg !81
    %2 = call ptr @malloc(i64 64)
    store ptr %2, ptr @schmu_arr__2, align 8
    store i64 6, ptr %2, align 8
    %cap8 = getelementptr i64, ptr %2, i64 1
    store i64 6, ptr %cap8, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i64 9, ptr %3, align 8
    %"110" = getelementptr i64, ptr %3, i64 1
    store i64 30, ptr %"110", align 8
    %"211" = getelementptr i64, ptr %3, i64 2
    store i64 0, ptr %"211", align 8
    %"312" = getelementptr i64, ptr %3, i64 3
    store i64 50, ptr %"312", align 8
    %"413" = getelementptr i64, ptr %3, i64 4
    store i64 2030, ptr %"413", align 8
    %"514" = getelementptr i64, ptr %3, i64 5
    store i64 34, ptr %"514", align 8
    %clstmp15 = alloca %closure, align 8
    store ptr @__fun_schmu5, ptr %clstmp15, align 8
    %envptr17 = getelementptr inbounds %closure, ptr %clstmp15, i32 0, i32 1
    store ptr null, ptr %envptr17, align 8
    call void @__schmu_sort__2_al_2lrl__(ptr @schmu_arr__2, ptr %clstmp15), !dbg !82
    %clstmp18 = alloca %closure, align 8
    store ptr @__fun_schmu6, ptr %clstmp18, align 8
    %envptr20 = getelementptr inbounds %closure, ptr %clstmp18, i32 0, i32 1
    store ptr null, ptr %envptr20, align 8
    %clstmp21 = alloca %closure, align 8
    store ptr @__fun_schmu7, ptr %clstmp21, align 8
    %envptr23 = getelementptr inbounds %closure, ptr %clstmp21, i32 0, i32 1
    store ptr null, ptr %envptr23, align 8
    call void @__iter_iter_lrb_rb_lru__(ptr %clstmp18, ptr %clstmp21), !dbg !83
    call void @__free_al_(ptr @schmu_arr__2)
    call void @__free_al_(ptr @schmu_arr)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "closure_monomorph.smu", directory: "$TESTCASE_ROOT")
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
  !12 = distinct !DISubprogram(name: "_array_swap_items", linkageName: "__array_swap_items_al__", scope: !3, file: !3, line: 95, type: !4, scopeLine: 95, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 96, column: 5, scope: !12)
  !14 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !15, file: !15, line: 130, type: !4, scopeLine: 130, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DIFile(filename: "fmt.smu", directory: "")
  !16 = !DILocation(line: 132, column: 2, scope: !14)
  !17 = !DILocation(line: 133, column: 15, scope: !14)
  !18 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !15, file: !15, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !19 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !15, file: !15, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !20 = !DILocation(line: 22, column: 4, scope: !19)
  !21 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !15, file: !15, line: 54, type: !4, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !22 = !DILocation(line: 56, column: 6, scope: !21)
  !23 = !DILocation(line: 57, column: 4, scope: !21)
  !24 = !DILocation(line: 74, column: 17, scope: !21)
  !25 = !DILocation(line: 77, column: 4, scope: !21)
  !26 = !DILocation(line: 81, column: 4, scope: !21)
  !27 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !15, file: !15, line: 109, type: !4, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !28 = !DILocation(line: 110, column: 2, scope: !27)
  !29 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_", scope: !15, file: !15, line: 220, type: !4, scopeLine: 220, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !30 = !DILocation(line: 221, column: 9, scope: !29)
  !31 = !DILocation(line: 221, column: 4, scope: !29)
  !32 = !DILocation(line: 221, column: 31, scope: !29)
  !33 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !15, file: !15, line: 77, type: !4, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !34 = !DILocation(line: 78, column: 6, scope: !33)
  !35 = distinct !DISubprogram(name: "__fun_iter5", linkageName: "__fun_iter5_lClru__", scope: !36, file: !36, line: 85, type: !4, scopeLine: 85, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DIFile(filename: "iter.smu", directory: "")
  !37 = !DILocation(line: 86, column: 4, scope: !35)
  !38 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0_Cal_2lrl_ll_", scope: !39, file: !39, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !39 = !DIFile(filename: "closure_monomorph.smu", directory: "")
  !40 = !DILocation(line: 6, column: 9, scope: !38)
  !41 = !DILocation(line: 8, column: 8, scope: !38)
  !42 = distinct !DISubprogram(name: "__fun_schmu1", linkageName: "__fun_schmu1", scope: !39, file: !39, line: 36, type: !4, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !43 = distinct !DISubprogram(name: "__fun_schmu2", linkageName: "__fun_schmu2", scope: !39, file: !39, line: 37, type: !4, scopeLine: 37, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !44 = !DILocation(line: 37, scope: !43)
  !45 = distinct !DISubprogram(name: "__fun_schmu3", linkageName: "__fun_schmu3", scope: !39, file: !39, line: 37, type: !4, scopeLine: 37, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !46 = !DILocation(line: 37, column: 42, scope: !45)
  !47 = distinct !DISubprogram(name: "__fun_schmu4", linkageName: "__fun_schmu4_Cal_2lrl_ll_", scope: !39, file: !39, line: 44, type: !4, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !48 = !DILocation(line: 45, column: 9, scope: !47)
  !49 = !DILocation(line: 47, column: 8, scope: !47)
  !50 = distinct !DISubprogram(name: "__fun_schmu5", linkageName: "__fun_schmu5", scope: !39, file: !39, line: 75, type: !4, scopeLine: 75, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !51 = distinct !DISubprogram(name: "__fun_schmu6", linkageName: "__fun_schmu6", scope: !39, file: !39, line: 76, type: !4, scopeLine: 76, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !52 = !DILocation(line: 76, scope: !51)
  !53 = distinct !DISubprogram(name: "__fun_schmu7", linkageName: "__fun_schmu7", scope: !39, file: !39, line: 76, type: !4, scopeLine: 76, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !54 = !DILocation(line: 76, column: 42, scope: !53)
  !55 = distinct !DISubprogram(name: "_iter_iter", linkageName: "__iter_iter_lrb_rb_lru__", scope: !36, file: !36, line: 84, type: !4, scopeLine: 84, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !56 = !DILocation(line: 85, column: 2, scope: !55)
  !57 = distinct !DISubprogram(name: "partition", linkageName: "__schmu_partition__2_al_C2lrl__", scope: !39, file: !39, line: 41, type: !4, scopeLine: 41, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !58 = !DILocation(line: 44, column: 4, scope: !57)
  !59 = !DILocation(line: 51, column: 4, scope: !57)
  !60 = distinct !DISubprogram(name: "partition", linkageName: "__schmu_partition_al_C2lrl__", scope: !39, file: !39, line: 2, type: !4, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !61 = !DILocation(line: 5, column: 4, scope: !60)
  !62 = !DILocation(line: 12, column: 4, scope: !60)
  !63 = distinct !DISubprogram(name: "quicksort", linkageName: "__schmu_quicksort__2_al_Cal_2lrlC2lrl2__", scope: !39, file: !39, line: 62, type: !4, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !64 = !DILocation(line: 63, column: 7, scope: !63)
  !65 = !DILocation(line: 66, column: 14, scope: !63)
  !66 = !DILocation(line: 67, column: 6, scope: !63)
  !67 = distinct !DISubprogram(name: "quicksort", linkageName: "__schmu_quicksort_al_Cal_2lrlC2lrl2__", scope: !39, file: !39, line: 22, type: !4, scopeLine: 22, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !68 = !DILocation(line: 23, column: 7, scope: !67)
  !69 = !DILocation(line: 26, column: 14, scope: !67)
  !70 = !DILocation(line: 27, column: 6, scope: !67)
  !71 = distinct !DISubprogram(name: "sort", linkageName: "__schmu_sort__2_al_2lrl__", scope: !39, file: !39, line: 40, type: !4, scopeLine: 40, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !72 = !DILocation(line: 72, column: 2, scope: !71)
  !73 = distinct !DISubprogram(name: "sort", linkageName: "__schmu_sort_al_2lrl__", scope: !39, file: !39, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !74 = !DILocation(line: 32, column: 2, scope: !73)
  !75 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !15, file: !15, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !76 = !DILocation(line: 63, column: 21, scope: !75)
  !77 = !DILocation(line: 64, column: 10, scope: !75)
  !78 = !DILocation(line: 67, column: 11, scope: !75)
  !79 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !39, file: !39, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !80 = !DILocation(line: 36, scope: !79)
  !81 = !DILocation(line: 37, column: 19, scope: !79)
  !82 = !DILocation(line: 75, scope: !79)
  !83 = !DILocation(line: 76, column: 19, scope: !79)
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

Const fixed array
  $ schmu --dump-llvm const_fixed_arr.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  %"2l_" = type { i64, i64 }
  
  @fmt_int_digits = external global ptr
  @schmu_a = constant i64 17
  @schmu_arr = constant [3 x i64] [i64 1, i64 17, i64 3]
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !32 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 17), !dbg !34
    %0 = alloca %"2l_", align 8
    store i64 10, ptr %0, align 8
    %"1" = getelementptr inbounds %"2l_", ptr %0, i32 0, i32 1
    store i64 17, ptr %"1", align 8
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "const_fixed_arr.smu", directory: "$TESTCASE_ROOT")
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
  !32 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "const_fixed_arr.smu", directory: "")
  !34 = !DILocation(line: 4, column: 5, scope: !32)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./const_fixed_arr
  17

Decrease ref counts for local variables in if branches
  $ schmu --dump-llvm decr_rc_if.smu && valgrind -q --leak-check=yes --show-reachable=yes ./decr_rc_if
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i1 @schmu_ret_true() !dbg !2 {
  entry:
    ret i1 true
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    %0 = tail call i1 @schmu_ret_true(), !dbg !7
    br i1 %0, label %then, label %else, !dbg !7
  
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "decr_rc_if.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "ret_true", linkageName: "schmu_ret_true", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "decr_rc_if.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 3, column: 4, scope: !6)

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

Allocate vectors on the heap and free them. Check with valgrind whenever something changes here.
Also mutable fields and 'realloc' builtin
  $ schmu --dump-llvm free_array.smu && valgrind -q --leak-check=yes --show-reachable=yes ./free_array
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
    %9 = getelementptr inbounds ptr, ptr %8, i64 %2
    store ptr %value, ptr %9, align 8
    %10 = load ptr, ptr %arr, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %10, align 8
    ret void
  }
  
  define linkonce_odr void @__array_push_al2_l__(ptr noalias %arr, i64 %0) !dbg !8 {
  entry:
    %value = alloca i64, align 8
    store i64 %0, ptr %value, align 8
    %1 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %1, i64 1
    %2 = load i64, ptr %capacity, align 8
    %3 = load i64, ptr %1, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %then, label %ifcont5, !dbg !9
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %2, 0
    br i1 %eq1, label %then2, label %else, !dbg !10
  
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
  
  define void @schmu_arr_inside() !dbg !11 {
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
    call void @__array_push_al2_l__(ptr %0, i64 12), !dbg !13
    call void @__free_al2_(ptr %0)
    ret void
  }
  
  define ptr @schmu_arr_of_records() !dbg !14 {
  entry:
    %0 = tail call ptr @malloc(i64 48)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !15
    store { i64, i64 } %2, ptr %1, align 8
    %"1" = getelementptr %container_, ptr %1, i64 1
    %3 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !16
    store { i64, i64 } %3, ptr %"1", align 8
    ret ptr %0
  }
  
  define void @schmu_inner_parent_scope() !dbg !17 {
  entry:
    %0 = tail call ptr @schmu_make_arr(), !dbg !18
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_al2_(ptr %1)
    ret void
  }
  
  define ptr @schmu_make_arr() !dbg !19 {
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
  
  define ptr @schmu_make_nested_arr() !dbg !20 {
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
  
  define ptr @schmu_nest_allocs() !dbg !21 {
  entry:
    %0 = tail call ptr @schmu_make_nested_arr(), !dbg !22
    ret ptr %0
  }
  
  define ptr @schmu_nest_fns() !dbg !23 {
  entry:
    %0 = tail call ptr @schmu_make_arr(), !dbg !24
    ret ptr %0
  }
  
  define void @schmu_nest_local() !dbg !25 {
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
  
  define { i64, i64 } @schmu_record_of_arrs() !dbg !26 {
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !27 {
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
    %7 = tail call ptr @schmu_make_arr(), !dbg !28
    store ptr %7, ptr @schmu_arr__3, align 8
    tail call void @schmu_arr_inside(), !dbg !29
    tail call void @schmu_inner_parent_scope(), !dbg !30
    %8 = tail call ptr @schmu_nest_fns(), !dbg !31
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
    tail call void @__array_push_2al2_al__(ptr @schmu_nested, ptr %15), !dbg !32
    %17 = tail call ptr @schmu_make_nested_arr(), !dbg !33
    store ptr %17, ptr @schmu_nested__2, align 8
    %18 = tail call ptr @schmu_nest_allocs(), !dbg !34
    store ptr %18, ptr @schmu_nested__3, align 8
    tail call void @schmu_nest_local(), !dbg !35
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
    %21 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !36
    store { i64, i64 } %21, ptr @schmu_rec_of_arr__2, align 8
    %22 = tail call ptr @malloc(i64 48)
    store ptr %22, ptr @schmu_arr_of_rec, align 8
    store i64 2, ptr %22, align 8
    %cap28 = getelementptr i64, ptr %22, i64 1
    store i64 2, ptr %cap28, align 8
    %23 = getelementptr i8, ptr %22, i64 16
    %24 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !37
    store { i64, i64 } %24, ptr %23, align 8
    %"130" = getelementptr %container_, ptr %23, i64 1
    %25 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !38
    store { i64, i64 } %25, ptr %"130", align 8
    %26 = tail call ptr @schmu_arr_of_records(), !dbg !39
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "free_array.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_2al2_al__", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 34, column: 5, scope: !2)
  !7 = !DILocation(line: 35, column: 7, scope: !2)
  !8 = distinct !DISubprogram(name: "_array_push", linkageName: "__array_push_al2_l__", scope: !3, file: !3, line: 30, type: !4, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 34, column: 5, scope: !8)
  !10 = !DILocation(line: 35, column: 7, scope: !8)
  !11 = distinct !DISubprogram(name: "arr_inside", linkageName: "schmu_arr_inside", scope: !12, file: !12, line: 11, type: !4, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DIFile(filename: "free_array.smu", directory: "")
  !13 = !DILocation(line: 14, column: 2, scope: !11)
  !14 = distinct !DISubprogram(name: "arr_of_records", linkageName: "schmu_arr_of_records", scope: !12, file: !12, line: 44, type: !4, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 45, column: 3, scope: !14)
  !16 = !DILocation(line: 45, column: 21, scope: !14)
  !17 = distinct !DISubprogram(name: "inner_parent_scope", linkageName: "schmu_inner_parent_scope", scope: !12, file: !12, line: 21, type: !4, scopeLine: 21, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !18 = !DILocation(line: 22, column: 9, scope: !17)
  !19 = distinct !DISubprogram(name: "make_arr", linkageName: "schmu_make_arr", scope: !12, file: !12, line: 17, type: !4, scopeLine: 17, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !20 = distinct !DISubprogram(name: "make_nested_arr", linkageName: "schmu_make_nested_arr", scope: !12, file: !12, line: 27, type: !4, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = distinct !DISubprogram(name: "nest_allocs", linkageName: "schmu_nest_allocs", scope: !12, file: !12, line: 31, type: !4, scopeLine: 31, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !22 = !DILocation(line: 32, column: 2, scope: !21)
  !23 = distinct !DISubprogram(name: "nest_fns", linkageName: "schmu_nest_fns", scope: !12, file: !12, line: 25, type: !4, scopeLine: 25, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !24 = !DILocation(line: 25, column: 16, scope: !23)
  !25 = distinct !DISubprogram(name: "nest_local", linkageName: "schmu_nest_local", scope: !12, file: !12, line: 35, type: !4, scopeLine: 35, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !26 = distinct !DISubprogram(name: "record_of_arrs", linkageName: "schmu_record_of_arrs", scope: !12, file: !12, line: 39, type: !4, scopeLine: 39, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !12, file: !12, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !28 = !DILocation(line: 47, column: 10, scope: !27)
  !29 = !DILocation(line: 48, scope: !27)
  !30 = !DILocation(line: 49, scope: !27)
  !31 = !DILocation(line: 50, column: 13, scope: !27)
  !32 = !DILocation(line: 53, scope: !27)
  !33 = !DILocation(line: 54, column: 13, scope: !27)
  !34 = !DILocation(line: 55, column: 13, scope: !27)
  !35 = !DILocation(line: 56, scope: !27)
  !36 = !DILocation(line: 59, column: 17, scope: !27)
  !37 = !DILocation(line: 61, column: 18, scope: !27)
  !38 = !DILocation(line: 61, column: 36, scope: !27)
  !39 = !DILocation(line: 62, column: 17, scope: !27)

Free correctly when moving ifs with outer borrows
  $ schmu free_cond.smu && valgrind -q --leak-check=yes --show-reachable=yes ./free_cond

Free moved parameters
  $ schmu free_moved_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./free_moved_param

Don't free params if parts are passed in tail calls
  $ schmu free_param_parts.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./free_param_parts
  thing
  none

Functions in arrays
  $ schmu function_array.smu && valgrind -q --leak-check=yes --show-reachable=yes ./function_array

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
  
  define i64 @schmu_ret_rec() !dbg !6 {
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    %ret = alloca %option.tal__, align 8
    %0 = tail call { i32, i64 } @schmu_ret_none(), !dbg !8
    store { i32, i64 } %0, ptr %ret, align 8
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !9
  
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
    %4 = call i64 @schmu_ret_rec(), !dbg !10
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "global_let.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "ret_none", linkageName: "schmu_ret_none", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "global_let.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "ret_rec", linkageName: "schmu_ret_rec", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 5, column: 15, scope: !7)
  !9 = !DILocation(line: 5, column: 27, scope: !7)
  !10 = !DILocation(line: 11, column: 10, scope: !7)

Don't try to free string literals in ifs
  $ schmu incr_str_lit_ifs.smu && valgrind -q --leak-check=yes --show-reachable=yes ./incr_str_lit_ifs
  none
  none

`inner` here should not make `tmp` a const, otherwise could gen would fail
  $ schmu mutable_inner_let.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./mutable_inner_let

Incr refcounts correctly in ifs
  $ schmu rc_ifs.smu && valgrind -q --leak-check=yes --show-reachable=yes ./rc_ifs

Incr refcounts correctly for closed over returns
  $ schmu rc_linear_closed_return.smu && valgrind -q --leak-check=yes --show-reachable=yes ./rc_linear_closed_return

Regression test for issue #19
  $ schmu --dump-llvm regression_issue_19.smu && ./regression_issue_19
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
  
  define void @schmu_v3_scale(ptr noalias %0, ptr %v3, double %factor) !dbg !6 {
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
  
  define void @schmu_wrap(ptr noalias %0) !dbg !7 {
  entry:
    %boxconst = alloca %v3_, align 8
    store %v3_ { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, ptr %boxconst, align 8
    %ret = alloca %v3_, align 8
    call void @schmu_v3_scale(ptr %ret, ptr %boxconst, double 1.500000e+00), !dbg !8
    %boxconst1 = alloca %v3_, align 8
    store %v3_ { double 1.000000e+00, double 2.000000e+00, double 3.000000e+00 }, ptr %boxconst1, align 8
    %ret2 = alloca %v3_, align 8
    call void @schmu_v3_scale(ptr %ret2, ptr %boxconst1, double 1.500000e+00), !dbg !9
    call void @schmu_v3_add(ptr %0, ptr %ret, ptr %ret2), !dbg !10
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    %ret = alloca %v3_, align 8
    call void @schmu_wrap(ptr %ret), !dbg !12
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "regression_issue_19.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "v3_add", linkageName: "schmu_v3_add", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "regression_issue_19.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "v3_scale", linkageName: "schmu_v3_scale", scope: !3, file: !3, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "wrap", linkageName: "schmu_wrap", scope: !3, file: !3, line: 11, type: !4, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DILocation(line: 12, column: 2, scope: !7)
  !9 = !DILocation(line: 13, column: 12, scope: !7)
  !10 = !DILocation(line: 13, column: 5, scope: !7)
  !11 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = !DILocation(line: 16, column: 7, scope: !11)

Tailcall loops
  $ schmu --dump-llvm regression_issue_26.smu && ./regression_issue_26
  regression_issue_26.smu:25.9-15: warning: Unused binding nested.
  
  25 | fun rec nested(a, b, c) {
               ^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  %lupc_lru_u2_ = type { i64, %fmt.formatter.tu_ }
  
  @fmt_int_digits = external global ptr
  @fmt_stdout_missing_arg_msg = external global ptr
  @fmt_stdout_too_many_arg_msg = external global ptr
  @schmu_limit = constant i64 3
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @0 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"{}, {}\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [12 x i8] } { i64 11, i64 11, [12 x i8] c"{}, {}, {}\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [1 x [1 x i8]] } { i64 0, i64 1, [1 x [1 x i8]] zeroinitializer }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_println(ptr %0)
  
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
  
  define linkonce_odr void @__fmt_stdout_print2_upc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_l_(ptr %fmtstr, ptr %f0, i64 %v0, ptr %f1, i64 %v1) !dbg !30 {
  entry:
    %__fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_ = alloca %closure, align 8
    store ptr @__fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, ptr %__fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, align 8
    %clsr___fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_ = alloca { ptr, ptr, %closure, %closure, i64, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %f12 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f12, ptr align 1 %f1, i64 16, i1 false)
    %v03 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, i32 0, i32 4
    store i64 %v0, ptr %v03, align 8
    %v14 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, i32 0, i32 5
    store i64 %v1, ptr %v14, align 8
    store ptr @__ctor_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_2l_, ptr %clsr___fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_, ptr %envptr, align 8
    %ret = alloca %lupc_lru_u2_, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_), !dbg !31
    %0 = getelementptr inbounds %lupc_lru_u2_, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 2
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
  
  define linkonce_odr void @__fmt_stdout_print3_upc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_l_(ptr %fmtstr, ptr %f0, i64 %v0, ptr %f1, i64 %v1, ptr %f2, i64 %v2) !dbg !35 {
  entry:
    %__fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_ = alloca %closure, align 8
    store ptr @__fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, ptr %__fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, align 8
    %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_ = alloca { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %f12 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f12, ptr align 1 %f1, i64 16, i1 false)
    %f23 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, i32 0, i32 4
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f23, ptr align 1 %f2, i64 16, i1 false)
    %v04 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, i32 0, i32 5
    store i64 %v0, ptr %v04, align 8
    %v15 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, i32 0, i32 6
    store i64 %v1, ptr %v15, align 8
    %v26 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, i32 0, i32 7
    store i64 %v2, ptr %v26, align 8
    store ptr @__ctor_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_3l_, ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_, ptr %envptr, align 8
    %ret = alloca %lupc_lru_u2_, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_), !dbg !36
    %0 = getelementptr inbounds %lupc_lru_u2_, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 3
    br i1 %ne, label %then, label %else, !dbg !37
  
  then:                                             ; preds = %entry
    call void @__fmt_stdout_impl_fmt_fail_too_many_ru_(), !dbg !38
    call void @__free_upc_lru_u_(ptr %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @__fmt_formatter_extract_upc_lru_u_ru_(ptr %0), !dbg !39
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_str_upc_lru_u_rupc_lru_u__(ptr noalias %0, ptr %p, ptr %str) !dbg !40 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !41
    %2 = tail call i64 @string_len(ptr %str), !dbg !42
    tail call void @__fmt_formatter_format_upc_lru_u_rupc_lru_u__(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !43
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !44 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64c__(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !45
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !46 {
  entry:
    %v0 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 4
    %v01 = load i64, ptr %v0, align 8
    %v1 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 5
    %v12 = load i64, ptr %v1, align 8
    %eq = icmp eq i64 %i, 0
    br i1 %eq, label %then, label %else, !dbg !47
  
  then:                                             ; preds = %entry
    %sunkaddr = getelementptr inbounds i8, ptr %1, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr12 = getelementptr inbounds i8, ptr %1, i64 24
    %loadtmp3 = load ptr, ptr %sunkaddr12, align 8
    tail call void %loadtmp(ptr %0, ptr %fmter, i64 %v01, ptr %loadtmp3), !dbg !48
    ret void
  
  else:                                             ; preds = %entry
    %eq4 = icmp eq i64 %i, 1
    br i1 %eq4, label %then5, label %else10, !dbg !49
  
  then5:                                            ; preds = %else
    %sunkaddr13 = getelementptr inbounds i8, ptr %1, i64 32
    %loadtmp7 = load ptr, ptr %sunkaddr13, align 8
    %sunkaddr14 = getelementptr inbounds i8, ptr %1, i64 40
    %loadtmp9 = load ptr, ptr %sunkaddr14, align 8
    tail call void %loadtmp7(ptr %0, ptr %fmter, i64 %v12, ptr %loadtmp9), !dbg !50
    ret void
  
  else10:                                           ; preds = %else
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__(ptr %0), !dbg !51
    tail call void @__free_upc_lru_u_(ptr %fmter)
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !52 {
  entry:
    %v0 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 5
    %v01 = load i64, ptr %v0, align 8
    %v1 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 6
    %v12 = load i64, ptr %v1, align 8
    %v2 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 7
    %v23 = load i64, ptr %v2, align 8
    %eq = icmp eq i64 %i, 0
    br i1 %eq, label %then, label %else, !dbg !53
  
  then:                                             ; preds = %entry
    %sunkaddr = getelementptr inbounds i8, ptr %1, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr21 = getelementptr inbounds i8, ptr %1, i64 24
    %loadtmp4 = load ptr, ptr %sunkaddr21, align 8
    tail call void %loadtmp(ptr %0, ptr %fmter, i64 %v01, ptr %loadtmp4), !dbg !54
    ret void
  
  else:                                             ; preds = %entry
    %eq5 = icmp eq i64 %i, 1
    br i1 %eq5, label %then6, label %else11, !dbg !55
  
  then6:                                            ; preds = %else
    %sunkaddr22 = getelementptr inbounds i8, ptr %1, i64 32
    %loadtmp8 = load ptr, ptr %sunkaddr22, align 8
    %sunkaddr23 = getelementptr inbounds i8, ptr %1, i64 40
    %loadtmp10 = load ptr, ptr %sunkaddr23, align 8
    tail call void %loadtmp8(ptr %0, ptr %fmter, i64 %v12, ptr %loadtmp10), !dbg !56
    ret void
  
  else11:                                           ; preds = %else
    %eq12 = icmp eq i64 %i, 2
    br i1 %eq12, label %then13, label %else18, !dbg !57
  
  then13:                                           ; preds = %else11
    %sunkaddr24 = getelementptr inbounds i8, ptr %1, i64 48
    %loadtmp15 = load ptr, ptr %sunkaddr24, align 8
    %sunkaddr25 = getelementptr inbounds i8, ptr %1, i64 56
    %loadtmp17 = load ptr, ptr %sunkaddr25, align 8
    tail call void %loadtmp15(ptr %0, ptr %fmter, i64 %v23, ptr %loadtmp17), !dbg !58
    ret void
  
  else18:                                           ; preds = %else11
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__(ptr %0), !dbg !59
    tail call void @__free_upc_lru_u_(ptr %fmter)
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !60 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !61
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !62
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !63
    br i1 %lt, label %then4, label %ifcont, !dbg !63
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_nested(i64 %a, i64 %b) !dbg !64 {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, ptr %1, align 8
    %clstmp = alloca %closure, align 8
    %clstmp4 = alloca %closure, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %entry, %then
    %.ph = phi i64 [ %a, %entry ], [ %add, %then ]
    %.ph9 = phi i64 [ %b, %entry ], [ 0, %then ]
    br label %rec, !dbg !66
  
  rec:                                              ; preds = %rec.outer, %else3
    %2 = phi i64 [ %add7, %else3 ], [ %.ph9, %rec.outer ]
    %eq = icmp eq i64 %2, 3
    br i1 %eq, label %then, label %else, !dbg !66
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph, 1
    store i64 %add, ptr %0, align 8
    store i64 0, ptr %1, align 8
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %.ph, 3
    br i1 %eq1, label %then2, label %else3, !dbg !67
  
  then2:                                            ; preds = %else
    ret void
  
  else3:                                            ; preds = %else
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    call void @__fmt_stdout_print2_upc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_l_(ptr @0, ptr %clstmp, i64 %.ph, ptr %clstmp4, i64 %2), !dbg !68
    %add7 = add i64 %2, 1
    store i64 %add7, ptr %1, align 8
    br label %rec
  }
  
  define void @schmu_nested__2(i64 %a, i64 %b, i64 %c) !dbg !69 {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 %c, ptr %2, align 8
    %clstmp = alloca %closure, align 8
    %clstmp8 = alloca %closure, align 8
    %clstmp11 = alloca %closure, align 8
    br label %rec.outer.outer
  
  rec.outer.outer:                                  ; preds = %then, %entry
    %.ph.ph = phi i64 [ 0, %then ], [ %b, %entry ]
    %.ph17.ph = phi i64 [ %add, %then ], [ %a, %entry ]
    %.ph19.ph = phi i64 [ %4, %then ], [ %c, %entry ]
    br label %rec.outer, !dbg !70
  
  rec.outer:                                        ; preds = %rec.outer.outer, %then2
    %.ph = phi i64 [ %add3, %then2 ], [ %.ph.ph, %rec.outer.outer ]
    %.ph18 = phi i64 [ %3, %then2 ], [ %.ph17.ph, %rec.outer.outer ]
    %.ph19 = phi i64 [ 0, %then2 ], [ %.ph19.ph, %rec.outer.outer ]
    br label %rec, !dbg !70
  
  rec:                                              ; preds = %rec.outer, %else7
    %3 = phi i64 [ %.ph17.ph, %else7 ], [ %.ph18, %rec.outer ]
    %4 = phi i64 [ %add14, %else7 ], [ %.ph19, %rec.outer ]
    %eq = icmp eq i64 %.ph, 3
    br i1 %eq, label %then, label %else, !dbg !70
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph17.ph, 1
    store i64 %add, ptr %0, align 8
    store i64 0, ptr %1, align 8
    br label %rec.outer.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %4, 3
    br i1 %eq1, label %then2, label %else4, !dbg !71
  
  then2:                                            ; preds = %else
    %add3 = add i64 %.ph, 1
    store i64 %add3, ptr %1, align 8
    store i64 0, ptr %2, align 8
    br label %rec.outer
  
  else4:                                            ; preds = %else
    %eq5 = icmp eq i64 %3, 3
    br i1 %eq5, label %then6, label %else7, !dbg !72
  
  then6:                                            ; preds = %else4
    ret void
  
  else7:                                            ; preds = %else4
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp8, align 8
    %envptr10 = getelementptr inbounds %closure, ptr %clstmp8, i32 0, i32 1
    store ptr null, ptr %envptr10, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    call void @__fmt_stdout_print3_upc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_l_(ptr @1, ptr %clstmp, i64 %.ph17.ph, ptr %clstmp8, i64 %.ph, ptr %clstmp11, i64 %4), !dbg !73
    %add14 = add i64 %4, 1
    store i64 %add14, ptr %2, align 8
    br label %rec
  }
  
  define void @schmu_nested__3(i64 %a, i64 %b, i64 %c) !dbg !74 {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 %c, ptr %2, align 8
    %clstmp = alloca %closure, align 8
    %clstmp8 = alloca %closure, align 8
    %clstmp11 = alloca %closure, align 8
    br label %rec.outer.outer
  
  rec.outer.outer:                                  ; preds = %then, %entry
    %.ph.ph = phi i64 [ 0, %then ], [ %b, %entry ]
    %.ph16.ph = phi i64 [ %add, %then ], [ %a, %entry ]
    %.ph17.ph = phi i64 [ %3, %then ], [ %c, %entry ]
    br label %rec.outer, !dbg !75
  
  rec.outer:                                        ; preds = %rec.outer.outer, %then5
    %.ph = phi i64 [ %add6, %then5 ], [ %.ph.ph, %rec.outer.outer ]
    %.ph17 = phi i64 [ 0, %then5 ], [ %.ph17.ph, %rec.outer.outer ]
    %.ph18 = phi i64 [ %4, %then5 ], [ %.ph16.ph, %rec.outer.outer ]
    br label %rec, !dbg !75
  
  rec:                                              ; preds = %rec.outer, %else7
    %3 = phi i64 [ %add14, %else7 ], [ %.ph17, %rec.outer ]
    %4 = phi i64 [ %.ph16.ph, %else7 ], [ %.ph18, %rec.outer ]
    %eq = icmp eq i64 %.ph, 3
    br i1 %eq, label %then, label %else, !dbg !75
  
  then:                                             ; preds = %rec
    %add = add i64 %.ph16.ph, 1
    store i64 %add, ptr %0, align 8
    store i64 0, ptr %1, align 8
    br label %rec.outer.outer
  
  else:                                             ; preds = %rec
    %eq1 = icmp eq i64 %4, 3
    br i1 %eq1, label %then2, label %else3, !dbg !76
  
  then2:                                            ; preds = %else
    ret void
  
  else3:                                            ; preds = %else
    %eq4 = icmp eq i64 %3, 3
    br i1 %eq4, label %then5, label %else7, !dbg !77
  
  then5:                                            ; preds = %else3
    %add6 = add i64 %.ph, 1
    store i64 %add6, ptr %1, align 8
    store i64 0, ptr %2, align 8
    br label %rec.outer
  
  else7:                                            ; preds = %else3
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp8, align 8
    %envptr10 = getelementptr inbounds %closure, ptr %clstmp8, i32 0, i32 1
    store ptr null, ptr %envptr10, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    call void @__fmt_stdout_print3_upc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_l_(ptr @1, ptr %clstmp, i64 %.ph16.ph, ptr %clstmp8, i64 %.ph, ptr %clstmp11, i64 %3), !dbg !78
    %add14 = add i64 %3, 1
    store i64 %add14, ptr %2, align 8
    br label %rec
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
  
  define linkonce_odr ptr @__ctor_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_2l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 64)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 64, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 2
    call void @__copy_upc_lru_u_lrupc_lru_u2_(ptr %f0)
    %f1 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 3
    call void @__copy_upc_lru_u_lrupc_lru_u2_(ptr %f1)
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
  
  define linkonce_odr ptr @__ctor_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_3l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 2
    call void @__copy_upc_lru_u_lrupc_lru_u2_(ptr %f0)
    %f1 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 3
    call void @__copy_upc_lru_u_lrupc_lru_u2_(ptr %f1)
    %f2 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 4
    call void @__copy_upc_lru_u_lrupc_lru_u2_(ptr %f2)
    ret ptr %1
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !79 {
  entry:
    tail call void @schmu_nested(i64 0, i64 0), !dbg !80
    tail call void @string_println(ptr @2), !dbg !81
    tail call void @schmu_nested__2(i64 0, i64 0, i64 0), !dbg !82
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "regression_issue_26.smu", directory: "$TESTCASE_ROOT")
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
  !22 = distinct !DISubprogram(name: "_fmt_stdout_impl_fmt_fail_missing", linkageName: "__fmt_stdout_impl_fmt_fail_missing_rupc_lru_u__", scope: !8, file: !8, line: 158, type: !4, scopeLine: 158, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 159, column: 6, scope: !22)
  !24 = !DILocation(line: 159, column: 17, scope: !22)
  !25 = !DILocation(line: 160, column: 9, scope: !22)
  !26 = distinct !DISubprogram(name: "_fmt_stdout_impl_fmt_fail_too_many", linkageName: "__fmt_stdout_impl_fmt_fail_too_many_ru_", scope: !8, file: !8, line: 164, type: !4, scopeLine: 164, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 165, column: 6, scope: !26)
  !28 = !DILocation(line: 165, column: 17, scope: !26)
  !29 = !DILocation(line: 166, column: 9, scope: !26)
  !30 = distinct !DISubprogram(name: "_fmt_stdout_print2", linkageName: "__fmt_stdout_print2_upc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_l_", scope: !8, file: !8, line: 255, type: !4, scopeLine: 255, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !31 = !DILocation(line: 256, column: 22, scope: !30)
  !32 = !DILocation(line: 263, column: 7, scope: !30)
  !33 = !DILocation(line: 263, column: 21, scope: !30)
  !34 = !DILocation(line: 264, column: 11, scope: !30)
  !35 = distinct !DISubprogram(name: "_fmt_stdout_print3", linkageName: "__fmt_stdout_print3_upc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_lupc_lru_u_lrupc_lru_u2_l_", scope: !8, file: !8, line: 267, type: !4, scopeLine: 267, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DILocation(line: 268, column: 22, scope: !35)
  !37 = !DILocation(line: 276, column: 7, scope: !35)
  !38 = !DILocation(line: 276, column: 21, scope: !35)
  !39 = !DILocation(line: 277, column: 11, scope: !35)
  !40 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 117, type: !4, scopeLine: 117, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !41 = !DILocation(line: 118, column: 22, scope: !40)
  !42 = !DILocation(line: 118, column: 40, scope: !40)
  !43 = !DILocation(line: 118, column: 2, scope: !40)
  !44 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 77, type: !4, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !45 = !DILocation(line: 78, column: 6, scope: !44)
  !46 = distinct !DISubprogram(name: "__fun_fmt_stdout3", linkageName: "__fun_fmt_stdout3_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_ll_", scope: !8, file: !8, line: 256, type: !4, scopeLine: 256, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !47 = !DILocation(line: 258, column: 8, scope: !46)
  !48 = !DILocation(line: 258, column: 11, scope: !46)
  !49 = !DILocation(line: 259, column: 8, scope: !46)
  !50 = !DILocation(line: 259, column: 11, scope: !46)
  !51 = !DILocation(line: 260, column: 11, scope: !46)
  !52 = distinct !DISubprogram(name: "__fun_fmt_stdout4", linkageName: "__fun_fmt_stdout4_Cupc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_upc_lru_u_lrupc_lru_u2_lll_", scope: !8, file: !8, line: 268, type: !4, scopeLine: 268, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !53 = !DILocation(line: 270, column: 8, scope: !52)
  !54 = !DILocation(line: 270, column: 11, scope: !52)
  !55 = !DILocation(line: 271, column: 8, scope: !52)
  !56 = !DILocation(line: 271, column: 11, scope: !52)
  !57 = !DILocation(line: 272, column: 8, scope: !52)
  !58 = !DILocation(line: 272, column: 11, scope: !52)
  !59 = !DILocation(line: 273, column: 11, scope: !52)
  !60 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !61 = !DILocation(line: 63, column: 21, scope: !60)
  !62 = !DILocation(line: 64, column: 10, scope: !60)
  !63 = !DILocation(line: 67, column: 11, scope: !60)
  !64 = distinct !DISubprogram(name: "nested", linkageName: "schmu_nested", scope: !65, file: !65, line: 4, type: !4, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !65 = !DIFile(filename: "regression_issue_26.smu", directory: "")
  !66 = !DILocation(line: 5, column: 5, scope: !64)
  !67 = !DILocation(line: 6, column: 10, scope: !64)
  !68 = !DILocation(line: 8, column: 9, scope: !64)
  !69 = distinct !DISubprogram(name: "nested", linkageName: "schmu_nested__2", scope: !65, file: !65, line: 15, type: !4, scopeLine: 15, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !70 = !DILocation(line: 16, column: 5, scope: !69)
  !71 = !DILocation(line: 17, column: 10, scope: !69)
  !72 = !DILocation(line: 18, column: 10, scope: !69)
  !73 = !DILocation(line: 20, column: 9, scope: !69)
  !74 = distinct !DISubprogram(name: "nested", linkageName: "schmu_nested__3", scope: !65, file: !65, line: 25, type: !4, scopeLine: 25, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !75 = !DILocation(line: 26, column: 5, scope: !74)
  !76 = !DILocation(line: 27, column: 10, scope: !74)
  !77 = !DILocation(line: 28, column: 10, scope: !74)
  !78 = !DILocation(line: 30, column: 9, scope: !74)
  !79 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !65, file: !65, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !80 = !DILocation(line: 12, scope: !79)
  !81 = !DILocation(line: 14, scope: !79)
  !82 = !DILocation(line: 24, scope: !79)
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
    %1 = tail call double @dot(ptr %vel, ptr %vel), !dbg !6
    %gt = fcmp ogt double %1, 1.000000e-01
    br i1 %gt, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %entry
    %ret = alloca %v_, align 8
    call void @norm(ptr %ret, ptr %vel), !dbg !7
    br label %ifcont
  
  else:                                             ; preds = %entry
    %2 = alloca %v_, align 8
    store %v_ { double 1.000000e+00, double 0.000000e+00, double 0.000000e+00 }, ptr %2, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %ret, %then ], [ %2, %else ]
    %3 = call i1 @maybe(), !dbg !8
    br i1 %3, label %then1, label %else2, !dbg !8
  
  then1:                                            ; preds = %ifcont
    call void @scale(ptr %0, ptr %iftmp, double 1.000000e+02), !dbg !9
    br label %ifcont6
  
  else2:                                            ; preds = %ifcont
    %4 = call i1 @maybe(), !dbg !10
    br i1 %4, label %then3, label %else4, !dbg !10
  
  then3:                                            ; preds = %else2
    call void @scale(ptr %0, ptr %iftmp, double -3.000000e+02), !dbg !11
    br label %ifcont6
  
  else4:                                            ; preds = %else2
    call void @scale(ptr %0, ptr %iftmp, double 1.000000e-01), !dbg !12
    br label %ifcont6
  
  ifcont6:                                          ; preds = %then3, %else4, %then1
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !13 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "regression_issue_30.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "calc_acc", linkageName: "schmu_calc_acc", scope: !3, file: !3, line: 8, type: !4, scopeLine: 8, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "regression_issue_30.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 10, column: 7, scope: !2)
  !7 = !DILocation(line: 11, column: 6, scope: !2)
  !8 = !DILocation(line: 15, column: 15, scope: !2)
  !9 = !DILocation(line: 15, column: 24, scope: !2)
  !10 = !DILocation(line: 16, column: 12, scope: !2)
  !11 = !DILocation(line: 16, column: 21, scope: !2)
  !12 = !DILocation(line: 17, column: 10, scope: !2)
  !13 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)

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
  
  define void @schmu_wrap_seg() !dbg !6 {
  entry:
    tail call void @__schmu_get_seg_2dl2df__(ptr @schmu_world), !dbg !7
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !8 {
  entry:
    store double 0.000000e+00, ptr @schmu_world, align 8
    store double 1.280000e+03, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 1), align 8
    store i64 10, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 2), align 8
    store double 1.000000e-01, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 3), align 8
    store double 5.400000e+02, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 4), align 8
    store float 5.000000e+00, ptr getelementptr inbounds (%bar_, ptr @schmu_world, i32 0, i32 5), align 4
    tail call void @schmu_wrap_seg(), !dbg !9
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "regression_load_global.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "get_seg", linkageName: "__schmu_get_seg_2dl2df__", scope: !3, file: !3, line: 16, type: !4, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "regression_load_global.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "wrap_seg", linkageName: "schmu_wrap_seg", scope: !3, file: !3, line: 18, type: !4, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 18, column: 16, scope: !6)
  !8 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 20, scope: !8)

Return closures
  $ schmu --dump-llvm return_closure.smu && valgrind -q --leak-check=yes --show-reachable=yes ./return_closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.tu_ = type { %closure }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_f = global %closure zeroinitializer, align 8
  @schmu_f2 = global %closure zeroinitializer, align 8
  @schmu_f__2 = global %closure zeroinitializer, align 8
  
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
  
  define i64 @__fun_schmu0(i64 %a, ptr %0) !dbg !28 {
  entry:
    %b = getelementptr inbounds { ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %b1 = load i64, ptr %b, align 8
    %add = add i64 %a, %b1
    ret i64 %add
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !30 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !31
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !33
    br i1 %lt, label %then4, label %ifcont, !dbg !33
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_bla(i64 %a, ptr %0) !dbg !34 {
  entry:
    %b = getelementptr inbounds { ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %b1 = load i64, ptr %b, align 8
    %add = add i64 %a, %b1
    ret i64 %add
  }
  
  define void @schmu_ret_fn(ptr noalias %0, i64 %b) !dbg !35 {
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
  
  define void @schmu_ret_lambda(ptr noalias %0, i64 %b) !dbg !36 {
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
  
  define linkonce_odr ptr @__ctor_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    ret ptr %1
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !37 {
  entry:
    tail call void @schmu_ret_fn(ptr @schmu_f, i64 13), !dbg !38
    tail call void @schmu_ret_fn(ptr @schmu_f2, i64 35), !dbg !39
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %loadtmp = load ptr, ptr @schmu_f, align 8
    %loadtmp1 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %loadtmp(i64 12, ptr %loadtmp1), !dbg !40
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %0), !dbg !41
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %loadtmp5 = load ptr, ptr @schmu_f2, align 8
    %loadtmp6 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f2, i32 0, i32 1), align 8
    %1 = call i64 %loadtmp5(i64 12, ptr %loadtmp6), !dbg !42
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp2, i64 %1), !dbg !43
    call void @schmu_ret_lambda(ptr @schmu_f__2, i64 134), !dbg !44
    %clstmp7 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %loadtmp10 = load ptr, ptr @schmu_f__2, align 8
    %loadtmp11 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f__2, i32 0, i32 1), align 8
    %2 = call i64 %loadtmp10(i64 12, ptr %loadtmp11), !dbg !45
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp7, i64 %2), !dbg !46
    call void @__free_lrl_(ptr @schmu_f__2)
    call void @__free_lrl_(ptr @schmu_f2)
    call void @__free_lrl_(ptr @schmu_f)
    ret i64 0
  }
  
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "return_closure.smu", directory: "$TESTCASE_ROOT")
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
  !28 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !29, file: !29, line: 7, type: !4, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DIFile(filename: "return_closure.smu", directory: "")
  !30 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !31 = !DILocation(line: 63, column: 21, scope: !30)
  !32 = !DILocation(line: 64, column: 10, scope: !30)
  !33 = !DILocation(line: 67, column: 11, scope: !30)
  !34 = distinct !DISubprogram(name: "bla", linkageName: "schmu_bla", scope: !29, file: !29, line: 2, type: !4, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !35 = distinct !DISubprogram(name: "ret_fn", linkageName: "schmu_ret_fn", scope: !29, file: !29, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = distinct !DISubprogram(name: "ret_lambda", linkageName: "schmu_ret_lambda", scope: !29, file: !29, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !37 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !29, file: !29, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 10, column: 8, scope: !37)
  !39 = !DILocation(line: 11, column: 9, scope: !37)
  !40 = !DILocation(line: 12, column: 18, scope: !37)
  !41 = !DILocation(line: 12, column: 5, scope: !37)
  !42 = !DILocation(line: 13, column: 18, scope: !37)
  !43 = !DILocation(line: 13, column: 5, scope: !37)
  !44 = !DILocation(line: 15, column: 8, scope: !37)
  !45 = !DILocation(line: 16, column: 18, scope: !37)
  !46 = !DILocation(line: 16, column: 5, scope: !37)
  25
  47
  146

Return nonclosure functions
  $ schmu --dump-llvm return_fn.smu && ./return_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.tu_ = type { %closure }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_f = global %closure zeroinitializer, align 8
  @schmu_f__2 = global %closure zeroinitializer, align 8
  
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
  
  define i64 @__fun_schmu0(i64 %a) !dbg !28 {
  entry:
    %add = add i64 %a, 12
    ret i64 %add
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !30 {
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
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !31
    store i8 %6, ptr %uglygep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !33
    br i1 %lt, label %then4, label %ifcont, !dbg !33
  
  then4:                                            ; preds = %else
    %uglygep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %uglygep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_named(i64 %a) !dbg !34 {
  entry:
    %add = add i64 %a, 13
    ret i64 %add
  }
  
  define void @schmu_ret_fn(ptr noalias %0) !dbg !35 {
  entry:
    store ptr @__fun_schmu0, ptr %0, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_ret_named(ptr noalias %0) !dbg !36 {
  entry:
    store ptr @schmu_named, ptr %0, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
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
  
  define linkonce_odr ptr @__ctor_A64c_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !37 {
  entry:
    tail call void @schmu_ret_fn(ptr @schmu_f), !dbg !38
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %loadtmp = load ptr, ptr @schmu_f, align 8
    %loadtmp1 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %loadtmp(i64 12, ptr %loadtmp1), !dbg !39
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %0), !dbg !40
    call void @schmu_ret_named(ptr @schmu_f__2), !dbg !41
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %loadtmp5 = load ptr, ptr @schmu_f__2, align 8
    %loadtmp6 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f__2, i32 0, i32 1), align 8
    %1 = call i64 %loadtmp5(i64 12, ptr %loadtmp6), !dbg !42
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp2, i64 %1), !dbg !43
    call void @__free_lrl_(ptr @schmu_f__2)
    call void @__free_lrl_(ptr @schmu_f)
    ret i64 0
  }
  
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
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "return_fn.smu", directory: "$TESTCASE_ROOT")
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
  !28 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !29, file: !29, line: 2, type: !4, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DIFile(filename: "return_fn.smu", directory: "")
  !30 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 60, type: !4, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !31 = !DILocation(line: 63, column: 21, scope: !30)
  !32 = !DILocation(line: 64, column: 10, scope: !30)
  !33 = !DILocation(line: 67, column: 11, scope: !30)
  !34 = distinct !DISubprogram(name: "named", linkageName: "schmu_named", scope: !29, file: !29, line: 6, type: !4, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !35 = distinct !DISubprogram(name: "ret_fn", linkageName: "schmu_ret_fn", scope: !29, file: !29, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = distinct !DISubprogram(name: "ret_named", linkageName: "schmu_ret_named", scope: !29, file: !29, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !37 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !29, file: !29, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 10, column: 8, scope: !37)
  !39 = !DILocation(line: 11, column: 18, scope: !37)
  !40 = !DILocation(line: 11, column: 5, scope: !37)
  !41 = !DILocation(line: 13, column: 8, scope: !37)
  !42 = !DILocation(line: 14, column: 18, scope: !37)
  !43 = !DILocation(line: 14, column: 5, scope: !37)
  24
  25

Take/use not all allocations of a record in tailrec calls
  $ schmu --dump-llvm take_partial_alloc.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %view_ = type { ptr, i64, i64 }
  %fmt.formatter.tac__ = type { %closure, ptr }
  %closure = type { ptr, ptr }
  %parse_resultac_2l__ = type { i32, %successac_2l__ }
  %successac_2l__ = type { %view_, %view_ }
  %parse_resultl_ = type { i32, %successl_ }
  %successl_ = type { %view_, i64 }
  
  @schmu_s = global ptr null, align 8
  @schmu_inp = global %view_ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c" \00" }
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare i1 @prelude_char_equal(i8 %0, i8 %1)
  
  declare void @fmt_fmt_str_create(ptr noalias %0)
  
  define linkonce_odr ptr @__fmt_formatter_extract_ac_pc_lru_ac2_rac__(ptr %fm) !dbg !2 {
  entry:
    %0 = getelementptr inbounds %fmt.formatter.tac__, ptr %fm, i32 0, i32 1
    tail call void @__free_except1_ac_pc_lru_ac2_(ptr %fm)
    %1 = load ptr, ptr %0, align 8
    ret ptr %1
  }
  
  define linkonce_odr void @__fmt_formatter_format_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !6 {
  entry:
    %1 = alloca %fmt.formatter.tac__, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 24, i1 false)
    %2 = getelementptr inbounds %fmt.formatter.tac__, ptr %1, i32 0, i32 1
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    call void %loadtmp(ptr %2, ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !7
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_str_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr noalias %0, ptr %p, ptr %str) !dbg !8 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !9
    %2 = tail call i64 @string_len(ptr %str), !dbg !10
    tail call void @__fmt_formatter_format_ac_pc_lru_ac2_rac_pc_lru_ac2__(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !11
    ret void
  }
  
  define linkonce_odr ptr @__fmt_str_print_ac_pc_lru_ac2_ac_rac_pc_lru_ac3_ac__(ptr %fmt, ptr %value) !dbg !12 {
  entry:
    %ret = alloca %fmt.formatter.tac__, align 8
    call void @fmt_fmt_str_create(ptr %ret), !dbg !13
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.tac__, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, ptr %value, ptr %loadtmp1), !dbg !14
    %0 = call ptr @__fmt_formatter_extract_ac_pc_lru_ac2_rac__(ptr %ret2), !dbg !15
    ret ptr %0
  }
  
  define void @schmu_aux(ptr noalias %0, ptr %rem, i64 %cnt) !dbg !16 {
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
    call void @schmu_ch(ptr %ret, ptr %1), !dbg !18
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else, !dbg !19
  
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
  
  define void @schmu_ch(ptr noalias %0, ptr %buf) !dbg !20 {
  entry:
    %1 = load ptr, ptr %buf, align 8
    %2 = getelementptr inbounds %view_, ptr %buf, i32 0, i32 1
    %3 = load i64, ptr %2, align 8
    %4 = tail call i8 @string_get(ptr %1, i64 %3), !dbg !21
    %5 = tail call i1 @prelude_char_equal(i8 %4, i8 32), !dbg !22
    br i1 %5, label %then, label %else, !dbg !22
  
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
  
  define void @schmu_many_count(ptr noalias %0, ptr %buf) !dbg !23 {
  entry:
    tail call void @schmu_aux(ptr %0, ptr %buf, i64 0), !dbg !24
    ret void
  }
  
  define void @schmu_view_of_string(ptr noalias %0, ptr %str) !dbg !25 {
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
    %4 = call i64 @string_len(ptr %str), !dbg !26
    store i64 %4, ptr %len, align 8
    ret void
  }
  
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !27 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_str_ac_pc_lru_ac2_rac_pc_lru_ac2__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = call ptr @__fmt_str_print_ac_pc_lru_ac2_ac_rac_pc_lru_ac3_ac__(ptr %clstmp, ptr @0), !dbg !28
    store ptr %0, ptr @schmu_s, align 8
    call void @schmu_view_of_string(ptr @schmu_inp, ptr %0), !dbg !29
    %ret = alloca %parse_resultl_, align 8
    call void @schmu_many_count(ptr %ret, ptr @schmu_inp), !dbg !30
    call void @__free_vac_2l_l_ac_2l2_(ptr %ret)
    call void @__free_ac_2l_(ptr @schmu_inp)
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_ac_(ptr %1)
    ret i64 0
  }
  
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
  
  declare ptr @malloc(i64 %0)
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "take_partial_alloc.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_ac_pc_lru_ac2_rac__", scope: !3, file: !3, line: 26, type: !4, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "fmt.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_ac_pc_lru_ac2_rac_pc_lru_ac2__", scope: !3, file: !3, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 22, column: 4, scope: !6)
  !8 = distinct !DISubprogram(name: "_fmt_str", linkageName: "__fmt_str_ac_pc_lru_ac2_rac_pc_lru_ac2__", scope: !3, file: !3, line: 117, type: !4, scopeLine: 117, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = !DILocation(line: 118, column: 22, scope: !8)
  !10 = !DILocation(line: 118, column: 40, scope: !8)
  !11 = !DILocation(line: 118, column: 2, scope: !8)
  !12 = distinct !DISubprogram(name: "_fmt_str_print", linkageName: "__fmt_str_print_ac_pc_lru_ac2_ac_rac_pc_lru_ac3_ac__", scope: !3, file: !3, line: 216, type: !4, scopeLine: 216, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 217, column: 9, scope: !12)
  !14 = !DILocation(line: 217, column: 4, scope: !12)
  !15 = !DILocation(line: 217, column: 41, scope: !12)
  !16 = distinct !DISubprogram(name: "aux", linkageName: "schmu_aux", scope: !17, file: !17, line: 19, type: !4, scopeLine: 19, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !17 = !DIFile(filename: "take_partial_alloc.smu", directory: "")
  !18 = !DILocation(line: 20, column: 10, scope: !16)
  !19 = !DILocation(line: 21, column: 6, scope: !16)
  !20 = distinct !DISubprogram(name: "ch", linkageName: "schmu_ch", scope: !17, file: !17, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 10, column: 16, scope: !20)
  !22 = !DILocation(line: 10, column: 5, scope: !20)
  !23 = distinct !DISubprogram(name: "many_count", linkageName: "schmu_many_count", scope: !17, file: !17, line: 18, type: !4, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !24 = !DILocation(line: 27, column: 2, scope: !23)
  !25 = distinct !DISubprogram(name: "view_of_string", linkageName: "schmu_view_of_string", scope: !17, file: !17, line: 5, type: !4, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !26 = !DILocation(line: 6, column: 37, scope: !25)
  !27 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !17, file: !17, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !28 = !DILocation(line: 29, column: 13, scope: !27)
  !29 = !DILocation(line: 31, column: 10, scope: !27)
  !30 = !DILocation(line: 32, column: 7, scope: !27)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./take_partial_alloc

Take/use not all allocations of a record in tailrec calls, different order for pattern matches
  $ schmu take_partial_alloc_reorder.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./take_partial_alloc_reorder

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

Partially free rc
  $ schmu partial_rc.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./partial_rc

Leak builtin
  $ schmu leak.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./leak
  thing

Fix double free
  $ schmu match_partial_move.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./match_partial_move

Fix leak after fix above
  $ schmu match_partial_move_followup_leak.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./match_partial_move_followup_leak
