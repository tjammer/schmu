Basic variant ctors
  $ schmu basic.smu --dump-llvm
  basic.smu:12.5-15: warning: Unused binding wrap_clike.
  
  12 | fun wrap_clike(): C
           ^^^^^^^^^^
  
  basic.smu:14.5-16: warning: Unused binding wrap_option.
  
  14 | fun wrap_option(): Some("hello")
           ^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %clike_ = type { i32 }
  %option.tac__ = type { i32, ptr }
  
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"hello\00" }
  
  define i32 @schmu_wrap_clike() !dbg !2 {
  entry:
    %clike = alloca %clike_, align 8
    store %clike_ { i32 2 }, ptr %clike, align 4
    %unbox = load i32, ptr %clike, align 4
    ret i32 %unbox
  }
  
  define { i32, i64 } @schmu_wrap_option() !dbg !6 {
  entry:
    %t = alloca %option.tac__, align 8
    store i32 1, ptr %t, align 4
    %data = getelementptr inbounds %option.tac__, ptr %t, i32 0, i32 1
    %0 = alloca ptr, align 8
    store ptr @0, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    store ptr %2, ptr %data, align 8
    %unbox = load { i32, i64 }, ptr %t, align 8
    ret { i32, i64 } %unbox
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "basic.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "wrap_clike", linkageName: "schmu_wrap_clike", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "basic.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "wrap_option", linkageName: "schmu_wrap_option", scope: !3, file: !3, line: 14, type: !4, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)

Match option
  $ schmu match_option.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./match_option
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tl_ = type { i32, i64 }
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_none_int = constant %option.tl_ { i32 0, i64 undef }
  
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
  
  define linkonce_odr i64 @__schmu_none_all_vl__(i32 %0, i64 %1) !dbg !28 {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !30
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
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
  
  define i64 @schmu_match_opt(i32 %0, i64 %1) !dbg !35 {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else, !dbg !36
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_opt_match(i32 %0, i64 %1) !dbg !37 {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !38
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_some_all(i32 %0, i64 %1) !dbg !39 {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else, !dbg !40
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !41 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %boxconst = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %0 = tail call i64 @schmu_match_opt(i32 %fst1, i64 %snd2), !dbg !42
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %0), !dbg !43
    %clstmp3 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp3, align 8
    %envptr5 = getelementptr inbounds %closure, ptr %clstmp3, i32 0, i32 1
    store ptr null, ptr %envptr5, align 8
    %boxconst6 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst6, align 8
    %fst8 = load i32, ptr %boxconst6, align 4
    %snd9 = getelementptr inbounds { i32, i64 }, ptr %boxconst6, i32 0, i32 1
    %snd10 = load i64, ptr %snd9, align 8
    %1 = call i64 @schmu_match_opt(i32 %fst8, i64 %snd10), !dbg !44
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp3, i64 %1), !dbg !45
    %clstmp11 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    %boxconst14 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst14, align 8
    %fst16 = load i32, ptr %boxconst14, align 4
    %snd17 = getelementptr inbounds { i32, i64 }, ptr %boxconst14, i32 0, i32 1
    %snd18 = load i64, ptr %snd17, align 8
    %2 = call i64 @schmu_opt_match(i32 %fst16, i64 %snd18), !dbg !46
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp11, i64 %2), !dbg !47
    %clstmp19 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp19, align 8
    %envptr21 = getelementptr inbounds %closure, ptr %clstmp19, i32 0, i32 1
    store ptr null, ptr %envptr21, align 8
    %boxconst22 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst22, align 8
    %fst24 = load i32, ptr %boxconst22, align 4
    %snd25 = getelementptr inbounds { i32, i64 }, ptr %boxconst22, i32 0, i32 1
    %snd26 = load i64, ptr %snd25, align 8
    %3 = call i64 @schmu_opt_match(i32 %fst24, i64 %snd26), !dbg !48
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp19, i64 %3), !dbg !49
    %clstmp27 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp27, align 8
    %envptr29 = getelementptr inbounds %closure, ptr %clstmp27, i32 0, i32 1
    store ptr null, ptr %envptr29, align 8
    %boxconst30 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst30, align 8
    %fst32 = load i32, ptr %boxconst30, align 4
    %snd33 = getelementptr inbounds { i32, i64 }, ptr %boxconst30, i32 0, i32 1
    %snd34 = load i64, ptr %snd33, align 8
    %4 = call i64 @schmu_some_all(i32 %fst32, i64 %snd34), !dbg !50
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp27, i64 %4), !dbg !51
    %clstmp35 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp35, align 8
    %envptr37 = getelementptr inbounds %closure, ptr %clstmp35, i32 0, i32 1
    store ptr null, ptr %envptr37, align 8
    %boxconst38 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst38, align 8
    %fst40 = load i32, ptr %boxconst38, align 4
    %snd41 = getelementptr inbounds { i32, i64 }, ptr %boxconst38, i32 0, i32 1
    %snd42 = load i64, ptr %snd41, align 8
    %5 = call i64 @schmu_some_all(i32 %fst40, i64 %snd42), !dbg !52
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp35, i64 %5), !dbg !53
    %clstmp43 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp43, align 8
    %envptr45 = getelementptr inbounds %closure, ptr %clstmp43, i32 0, i32 1
    store ptr null, ptr %envptr45, align 8
    %boxconst46 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst46, align 8
    %fst48 = load i32, ptr %boxconst46, align 4
    %snd49 = getelementptr inbounds { i32, i64 }, ptr %boxconst46, i32 0, i32 1
    %snd50 = load i64, ptr %snd49, align 8
    %6 = call i64 @__schmu_none_all_vl__(i32 %fst48, i64 %snd50), !dbg !54
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp43, i64 %6), !dbg !55
    %clstmp51 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp51, align 8
    %envptr53 = getelementptr inbounds %closure, ptr %clstmp51, i32 0, i32 1
    store ptr null, ptr %envptr53, align 8
    %7 = call i64 @__schmu_none_all_vl__(i32 0, i64 undef), !dbg !56
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp51, i64 %7), !dbg !57
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "match_option.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !8, file: !8, line: 136, type: !4, scopeLine: 136, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DIFile(filename: "fmt.smu", directory: "")
  !9 = !DILocation(line: 138, column: 2, scope: !7)
  !10 = !DILocation(line: 139, column: 15, scope: !7)
  !11 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !8, file: !8, line: 27, type: !4, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 21, type: !4, scopeLine: 21, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 23, column: 4, scope: !12)
  !14 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 55, type: !4, scopeLine: 55, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 57, column: 6, scope: !14)
  !16 = !DILocation(line: 58, column: 4, scope: !14)
  !17 = !DILocation(line: 75, column: 17, scope: !14)
  !18 = !DILocation(line: 78, column: 4, scope: !14)
  !19 = !DILocation(line: 82, column: 4, scope: !14)
  !20 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 110, type: !4, scopeLine: 110, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 111, column: 2, scope: !20)
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_", scope: !8, file: !8, line: 279, type: !4, scopeLine: 279, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 280, column: 9, scope: !22)
  !24 = !DILocation(line: 280, column: 4, scope: !22)
  !25 = !DILocation(line: 280, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 78, type: !4, scopeLine: 78, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 79, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "none_all", linkageName: "__schmu_none_all_vl__", scope: !29, file: !29, line: 27, type: !4, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DIFile(filename: "match_option.smu", directory: "")
  !30 = !DILocation(line: 27, column: 26, scope: !28)
  !31 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 61, type: !4, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !32 = !DILocation(line: 64, column: 21, scope: !31)
  !33 = !DILocation(line: 65, column: 10, scope: !31)
  !34 = !DILocation(line: 68, column: 11, scope: !31)
  !35 = distinct !DISubprogram(name: "match_opt", linkageName: "schmu_match_opt", scope: !29, file: !29, line: 2, type: !4, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !36 = !DILocation(line: 4, column: 4, scope: !35)
  !37 = distinct !DISubprogram(name: "opt_match", linkageName: "schmu_opt_match", scope: !29, file: !29, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 12, column: 28, scope: !37)
  !39 = distinct !DISubprogram(name: "some_all", linkageName: "schmu_some_all", scope: !29, file: !29, line: 18, type: !4, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !40 = !DILocation(line: 20, column: 4, scope: !39)
  !41 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !29, file: !29, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !42 = !DILocation(line: 8, scope: !41)
  !43 = !DILocation(line: 8, column: 28, scope: !41)
  !44 = !DILocation(line: 9, scope: !41)
  !45 = !DILocation(line: 9, column: 25, scope: !41)
  !46 = !DILocation(line: 14, scope: !41)
  !47 = !DILocation(line: 14, column: 28, scope: !41)
  !48 = !DILocation(line: 15, scope: !41)
  !49 = !DILocation(line: 15, column: 25, scope: !41)
  !50 = !DILocation(line: 24, scope: !41)
  !51 = !DILocation(line: 24, column: 27, scope: !41)
  !52 = !DILocation(line: 25, scope: !41)
  !53 = !DILocation(line: 25, column: 24, scope: !41)
  !54 = !DILocation(line: 29, scope: !41)
  !55 = !DILocation(line: 29, column: 27, scope: !41)
  !56 = !DILocation(line: 31, scope: !41)
  !57 = !DILocation(line: 31, column: 28, scope: !41)
  1
  0
  1
  0
  1
  0
  1
  0

Nested pattern matching
  $ schmu match_nested.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./match_nested
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  %option.tvdl__ = type { i32, %test_ }
  %test_ = type { i32, double }
  
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
  
  define i64 @schmu_doo(ptr %m) !dbg !32 {
  entry:
    %index = load i32, ptr %m, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont15, !dbg !34
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tvdl__, ptr %m, i32 0, i32 1
    %index2 = load i32, ptr %data, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else, !dbg !35
  
  then4:                                            ; preds = %then
    %sunkaddr = getelementptr inbounds i8, ptr %m, i64 16
    %0 = load double, ptr %sunkaddr, align 8
    %1 = fptosi double %0 to i64
    br label %ifcont15
  
  else:                                             ; preds = %then
    %eq8 = icmp eq i32 %index2, 1
    br i1 %eq8, label %then9, label %ifcont15, !dbg !36
  
  then9:                                            ; preds = %else
    %sunkaddr17 = getelementptr inbounds i8, ptr %m, i64 16
    %2 = load i64, ptr %sunkaddr17, align 8
    br label %ifcont15
  
  ifcont15:                                         ; preds = %entry, %then4, %else, %then9
    %iftmp16 = phi i64 [ %1, %then4 ], [ %2, %then9 ], [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp16
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
    %boxconst = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 1, %test_ { i32 0, double 3.000000e+00 } }, ptr %boxconst, align 8
    %0 = call i64 @schmu_doo(ptr %boxconst), !dbg !38
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %0), !dbg !39
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %boxconst4 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 1, %test_ { i32 1, double 9.881310e-324 } }, ptr %boxconst4, align 8
    %1 = call i64 @schmu_doo(ptr %boxconst4), !dbg !40
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp1, i64 %1), !dbg !41
    %clstmp5 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp5, align 8
    %envptr7 = getelementptr inbounds %closure, ptr %clstmp5, i32 0, i32 1
    store ptr null, ptr %envptr7, align 8
    %boxconst8 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 1, %test_ { i32 2, double undef } }, ptr %boxconst8, align 8
    %2 = call i64 @schmu_doo(ptr %boxconst8), !dbg !42
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp5, i64 %2), !dbg !43
    %clstmp9 = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp9, align 8
    %envptr11 = getelementptr inbounds %closure, ptr %clstmp9, i32 0, i32 1
    store ptr null, ptr %envptr11, align 8
    %boxconst12 = alloca %option.tvdl__, align 8
    store %option.tvdl__ { i32 0, %test_ undef }, ptr %boxconst12, align 8
    %3 = call i64 @schmu_doo(ptr %boxconst12), !dbg !44
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp9, i64 %3), !dbg !45
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "match_nested.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !8, file: !8, line: 136, type: !4, scopeLine: 136, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DIFile(filename: "fmt.smu", directory: "")
  !9 = !DILocation(line: 138, column: 2, scope: !7)
  !10 = !DILocation(line: 139, column: 15, scope: !7)
  !11 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !8, file: !8, line: 27, type: !4, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 21, type: !4, scopeLine: 21, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 23, column: 4, scope: !12)
  !14 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 55, type: !4, scopeLine: 55, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 57, column: 6, scope: !14)
  !16 = !DILocation(line: 58, column: 4, scope: !14)
  !17 = !DILocation(line: 75, column: 17, scope: !14)
  !18 = !DILocation(line: 78, column: 4, scope: !14)
  !19 = !DILocation(line: 82, column: 4, scope: !14)
  !20 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 110, type: !4, scopeLine: 110, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 111, column: 2, scope: !20)
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_", scope: !8, file: !8, line: 279, type: !4, scopeLine: 279, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 280, column: 9, scope: !22)
  !24 = !DILocation(line: 280, column: 4, scope: !22)
  !25 = !DILocation(line: 280, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 78, type: !4, scopeLine: 78, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 79, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 61, type: !4, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 64, column: 21, scope: !28)
  !30 = !DILocation(line: 65, column: 10, scope: !28)
  !31 = !DILocation(line: 68, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "doo", linkageName: "schmu_doo", scope: !33, file: !33, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "match_nested.smu", directory: "")
  !34 = !DILocation(line: 4, column: 2, scope: !32)
  !35 = !DILocation(line: 4, column: 7, scope: !32)
  !36 = !DILocation(line: 5, column: 7, scope: !32)
  !37 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !38 = !DILocation(line: 9, scope: !37)
  !39 = !DILocation(line: 9, column: 31, scope: !37)
  !40 = !DILocation(line: 10, scope: !37)
  !41 = !DILocation(line: 10, column: 27, scope: !37)
  !42 = !DILocation(line: 11, scope: !37)
  !43 = !DILocation(line: 11, column: 25, scope: !37)
  !44 = !DILocation(line: 12, scope: !37)
  !45 = !DILocation(line: 12, column: 19, scope: !37)
  3
  2
  1
  0

Match multiple columns
  $ schmu tuple_match.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./tuple_match
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tl_ = type { i32, i64 }
  %fmt.formatter.tu_ = type { %closure }
  %closure = type { ptr, ptr }
  %vl_vl2_ = type { %option.tl_, %option.tl_ }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_none_int = constant %option.tl_ { i32 0, i64 undef }
  
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
  
  define void @schmu_doo(i32 %0, i64 %1, i32 %2, i64 %3) !dbg !32 {
  entry:
    %a = alloca { i32, i64 }, align 8
    store i32 %0, ptr %a, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %a, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %b = alloca { i32, i64 }, align 8
    store i32 %2, ptr %b, align 4
    %snd2 = getelementptr inbounds { i32, i64 }, ptr %b, i32 0, i32 1
    store i64 %3, ptr %snd2, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_upc_lru_u_rupc_lru_u__, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %4 = alloca %vl_vl2_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 %a, i64 16, i1 false)
    %"1" = getelementptr inbounds %vl_vl2_, ptr %4, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %"1", ptr align 8 %b, i64 16, i1 false)
    %index = load i32, ptr %"1", align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else8, !dbg !34
  
  then:                                             ; preds = %entry
    %index4 = load i32, ptr %4, align 4
    %eq5 = icmp eq i32 %index4, 1
    br i1 %eq5, label %then6, label %else, !dbg !35
  
  then6:                                            ; preds = %then
    %data7 = getelementptr inbounds %option.tl_, ptr %4, i32 0, i32 1
    %sunkaddr = getelementptr inbounds i8, ptr %4, i64 24
    %5 = load i64, ptr %sunkaddr, align 8
    %6 = load i64, ptr %data7, align 8
    %add = add i64 %6, %5
    br label %ifcont17
  
  else:                                             ; preds = %then
    %sunkaddr19 = getelementptr inbounds i8, ptr %4, i64 24
    %7 = load i64, ptr %sunkaddr19, align 8
    br label %ifcont17
  
  else8:                                            ; preds = %entry
    %index10 = load i32, ptr %4, align 4
    %eq11 = icmp eq i32 %index10, 1
    br i1 %eq11, label %then12, label %ifcont17, !dbg !36
  
  then12:                                           ; preds = %else8
    %data13 = getelementptr inbounds %option.tl_, ptr %4, i32 0, i32 1
    %8 = load i64, ptr %data13, align 8
    br label %ifcont17
  
  ifcont17:                                         ; preds = %then12, %else8, %then6, %else
    %iftmp18 = phi i64 [ %add, %then6 ], [ %7, %else ], [ %8, %then12 ], [ 0, %else8 ]
    call void @__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_(ptr %clstmp, i64 %iftmp18), !dbg !37
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !38 {
  entry:
    %boxconst = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %boxconst3 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 2 }, ptr %boxconst3, align 8
    %fst5 = load i32, ptr %boxconst3, align 4
    %snd6 = getelementptr inbounds { i32, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    tail call void @schmu_doo(i32 %fst1, i64 %snd2, i32 %fst5, i64 %snd7), !dbg !39
    %boxconst10 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 2 }, ptr %boxconst10, align 8
    %fst12 = load i32, ptr %boxconst10, align 4
    %snd13 = getelementptr inbounds { i32, i64 }, ptr %boxconst10, i32 0, i32 1
    %snd14 = load i64, ptr %snd13, align 8
    tail call void @schmu_doo(i32 0, i64 undef, i32 %fst12, i64 %snd14), !dbg !40
    %boxconst15 = alloca %option.tl_, align 8
    store %option.tl_ { i32 1, i64 1 }, ptr %boxconst15, align 8
    %fst17 = load i32, ptr %boxconst15, align 4
    %snd18 = getelementptr inbounds { i32, i64 }, ptr %boxconst15, i32 0, i32 1
    %snd19 = load i64, ptr %snd18, align 8
    %boxconst20 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst20, align 8
    %fst22 = load i32, ptr %boxconst20, align 4
    %snd23 = getelementptr inbounds { i32, i64 }, ptr %boxconst20, i32 0, i32 1
    %snd24 = load i64, ptr %snd23, align 8
    tail call void @schmu_doo(i32 %fst17, i64 %snd19, i32 %fst22, i64 %snd24), !dbg !41
    %boxconst27 = alloca %option.tl_, align 8
    store %option.tl_ { i32 0, i64 undef }, ptr %boxconst27, align 8
    %fst29 = load i32, ptr %boxconst27, align 4
    %snd30 = getelementptr inbounds { i32, i64 }, ptr %boxconst27, i32 0, i32 1
    %snd31 = load i64, ptr %snd30, align 8
    tail call void @schmu_doo(i32 0, i64 undef, i32 %fst29, i64 %snd31), !dbg !42
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "tuple_match.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "_array_fixed_swap_items", linkageName: "__array_fixed_swap_items_A64c__", scope: !3, file: !3, line: 139, type: !4, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "array.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 140, column: 7, scope: !2)
  !7 = distinct !DISubprogram(name: "_fmt_endl", linkageName: "__fmt_endl_upc_lru_u_ru_", scope: !8, file: !8, line: 136, type: !4, scopeLine: 136, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = !DIFile(filename: "fmt.smu", directory: "")
  !9 = !DILocation(line: 138, column: 2, scope: !7)
  !10 = !DILocation(line: 139, column: 15, scope: !7)
  !11 = distinct !DISubprogram(name: "_fmt_formatter_extract", linkageName: "__fmt_formatter_extract_upc_lru_u_ru_", scope: !8, file: !8, line: 27, type: !4, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "_fmt_formatter_format", linkageName: "__fmt_formatter_format_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 21, type: !4, scopeLine: 21, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 23, column: 4, scope: !12)
  !14 = distinct !DISubprogram(name: "_fmt_int_base", linkageName: "__fmt_int_base_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 55, type: !4, scopeLine: 55, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !15 = !DILocation(line: 57, column: 6, scope: !14)
  !16 = !DILocation(line: 58, column: 4, scope: !14)
  !17 = !DILocation(line: 75, column: 17, scope: !14)
  !18 = !DILocation(line: 78, column: 4, scope: !14)
  !19 = !DILocation(line: 82, column: 4, scope: !14)
  !20 = distinct !DISubprogram(name: "_fmt_int", linkageName: "__fmt_int_upc_lru_u_rupc_lru_u__", scope: !8, file: !8, line: 110, type: !4, scopeLine: 110, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !21 = !DILocation(line: 111, column: 2, scope: !20)
  !22 = distinct !DISubprogram(name: "_fmt_stdout_println", linkageName: "__fmt_stdout_println_upc_lru_u_lrupc_lru_u2_l_", scope: !8, file: !8, line: 279, type: !4, scopeLine: 279, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !23 = !DILocation(line: 280, column: 9, scope: !22)
  !24 = !DILocation(line: 280, column: 4, scope: !22)
  !25 = !DILocation(line: 280, column: 31, scope: !22)
  !26 = distinct !DISubprogram(name: "__fun_fmt2", linkageName: "__fun_fmt2", scope: !8, file: !8, line: 78, type: !4, scopeLine: 78, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !27 = !DILocation(line: 79, column: 6, scope: !26)
  !28 = distinct !DISubprogram(name: "_fmt_aux", linkageName: "fmt_aux", scope: !8, file: !8, line: 61, type: !4, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !29 = !DILocation(line: 64, column: 21, scope: !28)
  !30 = !DILocation(line: 65, column: 10, scope: !28)
  !31 = !DILocation(line: 68, column: 11, scope: !28)
  !32 = distinct !DISubprogram(name: "doo", linkageName: "schmu_doo", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !33 = !DIFile(filename: "tuple_match.smu", directory: "")
  !34 = !DILocation(line: 3, column: 14, scope: !32)
  !35 = !DILocation(line: 3, column: 5, scope: !32)
  !36 = !DILocation(line: 5, column: 5, scope: !32)
  !37 = !DILocation(line: 8, column: 11, scope: !32)
  !38 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !33, file: !33, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !39 = !DILocation(line: 12, scope: !38)
  !40 = !DILocation(line: 13, scope: !38)
  !41 = !DILocation(line: 14, scope: !38)
  !42 = !DILocation(line: 15, scope: !38)
  3
  2
  1
  0

  $ schmu custom_tag_reuse.smu
  custom_tag_reuse.smu:1.27-28: error: Tag 1 already used for constructor a.
  
  1 | type tags = A(1) | B(0) | C(int)
                                ^
  
  [1]

Record literals in pattern matches
  $ schmu match_record.smu
  match_record.smu:5.24-25: warning: Unused binding b.
  
  5 |     Some({a = Some(a), b}): a
                             ^
  
  match_record.smu:6.21-22: warning: Unused binding b.
  
  6 |     Some({a = None, b}): -1
                          ^
  
  match_record.smu:15.18-19: warning: Unused binding b.
  
  15 |     {a = {a = c, b}, b = _}: c
                        ^
  
  $ valgrind -q --leak-check=yes --show-reachable=yes ./match_record
  10
  -1
  20
  -2

Const ctors
  $ schmu const_ctor_issue.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %var_ = type { i32, %thing_ }
  %thing_ = type { i64, %"5l_" }
  %"5l_" = type { i64, i64, i64, i64, i64 }
  
  @schmu_var = constant %var_ { i32 0, { double, [40 x i8] } { double 1.000000e+01, [40 x i8] undef } }
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"float\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"thing\00" }
  
  declare void @string_println(ptr %0)
  
  define void @schmu_dynamic(ptr %var) !dbg !2 {
  entry:
    %index = load i32, ptr %var, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %var_, ptr %var, i32 0, i32 1
    tail call void @string_println(ptr @0), !dbg !7
    ret void
  
  else:                                             ; preds = %entry
    %data1 = getelementptr inbounds %var_, ptr %var, i32 0, i32 1
    tail call void @string_println(ptr @1), !dbg !8
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    tail call void @string_println(ptr @0), !dbg !10
    tail call void @schmu_dynamic(ptr @schmu_var), !dbg !11
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "const_ctor_issue.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "dynamic", linkageName: "schmu_dynamic", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "const_ctor_issue.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 11, column: 4, scope: !2)
  !7 = !DILocation(line: 11, column: 14, scope: !2)
  !8 = !DILocation(line: 12, column: 14, scope: !2)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = !DILocation(line: 6, column: 12, scope: !9)
  !11 = !DILocation(line: 15, scope: !9)
  $ valgrind -q --leak-check=yes --show-reachable=yes ./const_ctor_issue
  float
  float

Mutate in pattern matches
  $ schmu mutate.smu
  $ ./mutate
  11
  12

Don't free catchall let pattern in other branch
  $ schmu dont_free_catchall_let_pattern.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./dont_free_catchall_let_pattern

Basic recursive types
  $ schmu recursive.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./recursive

Support path prefixes in match patterns
  $ schmu path_prefix.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./path_prefix

Regression test for this if structure
  $ schmu failwith_ifs.smu

Regression test for tuple match
  $ schmu tuple_match_regression.smu
  $ ./tuple_match_regression
  c
  none

Regression for borrowed ifs (phi nodes). Just make sure it doesn't segfault
 $ schmu -c borrow_phi_variant.smu
