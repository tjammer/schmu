Basic variant ctors
  $ schmu basic.smu --dump-llvm --target x86_64-unknown-linux-gnu -c
  basic.smu:4.15-18: warning: Unused constructor: One
  
  4 | type larger = One | Two(foo) | Three(int)
                    ^^^
  
  basic.smu:8.14-15: warning: Unused constructor: A
  
  8 | type clike = A | B | C | D | E
                   ^
  
  basic.smu:12.5-15: warning: Unused binding wrap_clike
  
  12 | fun wrap_clike() { C }
           ^^^^^^^^^^
  
  basic.smu:14.5-16: warning: Unused binding wrap_option
  
  14 | fun wrap_option() {Some(copy("hello"))}
           ^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %clike = type { i32 }
  %option.t.a.c = type { i32, { ptr, i64, i64 } }
  
  @0 = private unnamed_addr constant [6 x i8] c"hello\00"
  
  define i32 @schmu_wrap_clike() !dbg !2 {
  entry:
    %clike = alloca %clike, align 8
    store %clike { i32 2 }, ptr %clike, align 4
    %unbox = load i32, ptr %clike, align 4
    ret i32 %unbox
  }
  
  define void @schmu_wrap_option(ptr noalias %0) !dbg !6 {
  entry:
    store i32 1, ptr %0, align 4
    %data = getelementptr inbounds %option.t.a.c, ptr %0, i32 0, i32 1
    %1 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 5, i64 -1 }, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data, ptr align 8 %1, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %data)
    ret void
  }
  
  define linkonce_odr void @__copy_a.c(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %1 = icmp eq i64 %size, 0
    br i1 %1, label %zero, label %nonempty
  
  zero:                                             ; preds = %entry
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 0, ptr %cap, align 8
    store ptr null, ptr %0, align 8
    br label %cont
  
  cont:                                             ; preds = %nonempty, %zero
    ret void
  
  nonempty:                                         ; preds = %entry
    %2 = add i64 %size, 1
    %3 = tail call ptr @malloc(i64 %2)
    %4 = load ptr, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %4, i64 %2, i1 false)
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 %size, ptr %cap2, align 8
    store ptr %3, ptr %0, align 8
    br label %cont
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
  !2 = distinct !DISubprogram(name: "wrap_clike", linkageName: "schmu_wrap_clike", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
  !3 = !DIFile(filename: "basic.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "wrap_option", linkageName: "schmu_wrap_option", scope: !3, file: !3, line: 14, type: !4, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
  !7 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)

Match option
  $ schmu match_option.smu --dump-llvm --target x86_64-unknown-linux-gnu -c  2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %option.t.l = type { i32, i64 }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_none_int = constant %option.t.l { i32 0, i64 undef }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  define linkonce_odr void @__array_fixed_swap_items_cA64.u(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
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
  
  define linkonce_odr void @__fmt_endl_u(ptr %p) !dbg !7 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !9
    call void @__fmt_formatter_extract_u(ptr %ret), !dbg !10
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_u(ptr %fm) !dbg !11 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !12 {
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
  
  define linkonce_odr void @__fmt_int_base_u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !14 {
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
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !16
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
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !19
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_u(ptr noalias %0, ptr %p, i64 %i) !dbg !20 {
  entry:
    tail call void @__fmt_int_base_u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !21
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_l(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_u(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_cA64.u(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
    ret void
  }
  
  define void @__fun_schmu0(i64 %i) !dbg !28 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !30
    ret void
  }
  
  define void @__fun_schmu1(i64 %i) !dbg !31 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !32
    ret void
  }
  
  define void @__fun_schmu2(i64 %i) !dbg !33 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !34
    ret void
  }
  
  define void @__fun_schmu3(i64 %i) !dbg !35 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !36
    ret void
  }
  
  define void @__fun_schmu4(i64 %i) !dbg !37 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !38
    ret void
  }
  
  define void @__fun_schmu5(i64 %i) !dbg !39 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !40
    ret void
  }
  
  define void @__fun_schmu6(i64 %i) !dbg !41 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !42
    ret void
  }
  
  define void @__fun_schmu7(i64 %i) !dbg !43 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !44
    ret void
  }
  
  define linkonce_odr i64 @__schmu_none_all_l(i32 %0, i64 %1) !dbg !45 {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !46
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !48
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !49
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !50
    br i1 %lt, label %then4, label %ifcont, !dbg !50
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_match_opt(i32 %0, i64 %1) !dbg !51 {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else, !dbg !52
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_opt_match(i32 %0, i64 %1) !dbg !53 {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !54
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_some_all(i32 %0, i64 %1) !dbg !55 {
  entry:
    %p = alloca { i32, i64 }, align 8
    store i32 %0, ptr %p, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %p, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else, !dbg !56
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr void @__free_up.clru(ptr %0) {
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
  
  ret:                                              ; preds = %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    tail call void %dtor1(ptr %env)
    ret void
  
  just_free:                                        ; preds = %notnull
    tail call void @free(ptr %env)
    ret void
  }
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free_up.clru(ptr %0)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !57 {
  entry:
    %boxconst = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %0 = tail call i64 @schmu_match_opt(i32 %fst1, i64 %snd2), !dbg !58
    tail call void @__fun_schmu0(i64 %0), !dbg !59
    %boxconst3 = alloca %option.t.l, align 8
    store %option.t.l { i32 0, i64 undef }, ptr %boxconst3, align 8
    %fst5 = load i32, ptr %boxconst3, align 4
    %snd6 = getelementptr inbounds { i32, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    %1 = tail call i64 @schmu_match_opt(i32 %fst5, i64 %snd7), !dbg !60
    tail call void @__fun_schmu1(i64 %1), !dbg !61
    %boxconst8 = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 1 }, ptr %boxconst8, align 8
    %fst10 = load i32, ptr %boxconst8, align 4
    %snd11 = getelementptr inbounds { i32, i64 }, ptr %boxconst8, i32 0, i32 1
    %snd12 = load i64, ptr %snd11, align 8
    %2 = tail call i64 @schmu_opt_match(i32 %fst10, i64 %snd12), !dbg !62
    tail call void @__fun_schmu2(i64 %2), !dbg !63
    %boxconst13 = alloca %option.t.l, align 8
    store %option.t.l { i32 0, i64 undef }, ptr %boxconst13, align 8
    %fst15 = load i32, ptr %boxconst13, align 4
    %snd16 = getelementptr inbounds { i32, i64 }, ptr %boxconst13, i32 0, i32 1
    %snd17 = load i64, ptr %snd16, align 8
    %3 = tail call i64 @schmu_opt_match(i32 %fst15, i64 %snd17), !dbg !64
    tail call void @__fun_schmu3(i64 %3), !dbg !65
    %boxconst18 = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 1 }, ptr %boxconst18, align 8
    %fst20 = load i32, ptr %boxconst18, align 4
    %snd21 = getelementptr inbounds { i32, i64 }, ptr %boxconst18, i32 0, i32 1
    %snd22 = load i64, ptr %snd21, align 8
    %4 = tail call i64 @schmu_some_all(i32 %fst20, i64 %snd22), !dbg !66
    tail call void @__fun_schmu4(i64 %4), !dbg !67
    %boxconst23 = alloca %option.t.l, align 8
    store %option.t.l { i32 0, i64 undef }, ptr %boxconst23, align 8
    %fst25 = load i32, ptr %boxconst23, align 4
    %snd26 = getelementptr inbounds { i32, i64 }, ptr %boxconst23, i32 0, i32 1
    %snd27 = load i64, ptr %snd26, align 8
    %5 = tail call i64 @schmu_some_all(i32 %fst25, i64 %snd27), !dbg !68
    tail call void @__fun_schmu5(i64 %5), !dbg !69
    %boxconst28 = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 1 }, ptr %boxconst28, align 8
    %fst30 = load i32, ptr %boxconst28, align 4
    %snd31 = getelementptr inbounds { i32, i64 }, ptr %boxconst28, i32 0, i32 1
    %snd32 = load i64, ptr %snd31, align 8
    %6 = tail call i64 @__schmu_none_all_l(i32 %fst30, i64 %snd32), !dbg !70
    tail call void @__fun_schmu6(i64 %6), !dbg !71
    %7 = tail call i64 @__schmu_none_all_l(i32 0, i64 undef), !dbg !72
    tail call void @__fun_schmu7(i64 %7), !dbg !73
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu match_option.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./match_option
  1
  0
  1
  0
  1
  0
  1
  0

Nested pattern matching
  $ schmu match_nested.smu --dump-llvm --target x86_64-unknown-linux-gnu -c  2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %option.t.test = type { i32, %test }
  %test = type { i32, double }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  define linkonce_odr void @__array_fixed_swap_items_cA64.u(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
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
  
  define linkonce_odr void @__fmt_endl_u(ptr %p) !dbg !7 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !9
    call void @__fmt_formatter_extract_u(ptr %ret), !dbg !10
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_u(ptr %fm) !dbg !11 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !12 {
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
  
  define linkonce_odr void @__fmt_int_base_u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !14 {
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
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !16
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
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !19
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_u(ptr noalias %0, ptr %p, i64 %i) !dbg !20 {
  entry:
    tail call void @__fmt_int_base_u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !21
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_l(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_u(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_cA64.u(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
    ret void
  }
  
  define void @__fun_schmu0(i64 %i) !dbg !28 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !30
    ret void
  }
  
  define void @__fun_schmu1(i64 %i) !dbg !31 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !32
    ret void
  }
  
  define void @__fun_schmu2(i64 %i) !dbg !33 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !34
    ret void
  }
  
  define void @__fun_schmu3(i64 %i) !dbg !35 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !36
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !37 {
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !38
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !39
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !40
    br i1 %lt, label %then4, label %ifcont, !dbg !40
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_doo(ptr %m) !dbg !41 {
  entry:
    %index = load i32, ptr %m, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont15, !dbg !42
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.t.test, ptr %m, i32 0, i32 1
    %index2 = load i32, ptr %data, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else, !dbg !43
  
  then4:                                            ; preds = %then
    %sunkaddr = getelementptr inbounds i8, ptr %m, i64 16
    %0 = load double, ptr %sunkaddr, align 8
    %1 = fptosi double %0 to i64
    br label %ifcont15
  
  else:                                             ; preds = %then
    %eq8 = icmp eq i32 %index2, 1
    br i1 %eq8, label %then9, label %ifcont15, !dbg !44
  
  then9:                                            ; preds = %else
    %sunkaddr17 = getelementptr inbounds i8, ptr %m, i64 16
    %2 = load i64, ptr %sunkaddr17, align 8
    br label %ifcont15
  
  ifcont15:                                         ; preds = %entry, %then4, %else, %then9
    %iftmp16 = phi i64 [ %1, %then4 ], [ %2, %then9 ], [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp16
  }
  
  define linkonce_odr void @__free_up.clru(ptr %0) {
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
  
  ret:                                              ; preds = %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    tail call void %dtor1(ptr %env)
    ret void
  
  just_free:                                        ; preds = %notnull
    tail call void @free(ptr %env)
    ret void
  }
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free_up.clru(ptr %0)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !45 {
  entry:
    %boxconst = alloca %option.t.test, align 8
    store %option.t.test { i32 1, %test { i32 0, double 3.000000e+00 } }, ptr %boxconst, align 8
    %0 = call i64 @schmu_doo(ptr %boxconst), !dbg !46
    call void @__fun_schmu0(i64 %0), !dbg !47
    %boxconst1 = alloca %option.t.test, align 8
    store %option.t.test { i32 1, %test { i32 1, double 9.881310e-324 } }, ptr %boxconst1, align 8
    %1 = call i64 @schmu_doo(ptr %boxconst1), !dbg !48
    call void @__fun_schmu1(i64 %1), !dbg !49
    %boxconst2 = alloca %option.t.test, align 8
    store %option.t.test { i32 1, %test { i32 2, double undef } }, ptr %boxconst2, align 8
    %2 = call i64 @schmu_doo(ptr %boxconst2), !dbg !50
    call void @__fun_schmu2(i64 %2), !dbg !51
    %boxconst3 = alloca %option.t.test, align 8
    store %option.t.test { i32 0, %test undef }, ptr %boxconst3, align 8
    %3 = call i64 @schmu_doo(ptr %boxconst3), !dbg !52
    call void @__fun_schmu3(i64 %3), !dbg !53
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu match_nested.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./match_nested
  3
  2
  1
  0

Match multiple columns
  $ schmu tuple_match.smu --dump-llvm --target x86_64-unknown-linux-gnu -c  2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %option.t.l = type { i32, i64 }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.option.t.loption.t.l = type { %option.t.l, %option.t.l }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_none_int = constant %option.t.l { i32 0, i64 undef }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  define linkonce_odr void @__array_fixed_swap_items_cA64.u(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
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
  
  define linkonce_odr void @__fmt_endl_u(ptr %p) !dbg !7 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !9
    call void @__fmt_formatter_extract_u(ptr %ret), !dbg !10
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_u(ptr %fm) !dbg !11 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !12 {
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
  
  define linkonce_odr void @__fmt_int_base_u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !14 {
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
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !16
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
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !19
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_u(ptr noalias %0, ptr %p, i64 %i) !dbg !20 {
  entry:
    tail call void @__fmt_int_base_u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !21
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_l(ptr %fmt, i64 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_u(ptr %ret2), !dbg !25
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
    tail call void @__array_fixed_swap_items_cA64.u(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !27
    ret void
  }
  
  define void @__fun_schmu0(i64 %i) !dbg !28 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %i), !dbg !30
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !32
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !33
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !34
    br i1 %lt, label %then4, label %ifcont, !dbg !34
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_doo(i32 %0, i64 %1, i32 %2, i64 %3) !dbg !35 {
  entry:
    %a = alloca { i32, i64 }, align 8
    store i32 %0, ptr %a, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %a, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %b = alloca { i32, i64 }, align 8
    store i32 %2, ptr %b, align 4
    %snd2 = getelementptr inbounds { i32, i64 }, ptr %b, i32 0, i32 1
    store i64 %3, ptr %snd2, align 8
    %4 = alloca %tp.option.t.loption.t.l, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 %a, i64 16, i1 false)
    %"1" = getelementptr inbounds %tp.option.t.loption.t.l, ptr %4, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %"1", ptr align 8 %b, i64 16, i1 false)
    %index = load i32, ptr %"1", align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else8, !dbg !36
  
  then:                                             ; preds = %entry
    %index4 = load i32, ptr %4, align 4
    %eq5 = icmp eq i32 %index4, 1
    br i1 %eq5, label %then6, label %else, !dbg !37
  
  then6:                                            ; preds = %then
    %data7 = getelementptr inbounds %option.t.l, ptr %4, i32 0, i32 1
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
    br i1 %eq11, label %then12, label %ifcont17, !dbg !38
  
  then12:                                           ; preds = %else8
    %data13 = getelementptr inbounds %option.t.l, ptr %4, i32 0, i32 1
    %8 = load i64, ptr %data13, align 8
    br label %ifcont17
  
  ifcont17:                                         ; preds = %then12, %else8, %then6, %else
    %iftmp18 = phi i64 [ %add, %then6 ], [ %7, %else ], [ %8, %then12 ], [ 0, %else8 ]
    tail call void @__fun_schmu0(i64 %iftmp18), !dbg !39
    ret void
  }
  
  define linkonce_odr void @__free_up.clru(ptr %0) {
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
  
  ret:                                              ; preds = %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    tail call void %dtor1(ptr %env)
    ret void
  
  just_free:                                        ; preds = %notnull
    tail call void @free(ptr %env)
    ret void
  }
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free_up.clru(ptr %0)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !40 {
  entry:
    %boxconst = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %boxconst3 = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 2 }, ptr %boxconst3, align 8
    %fst5 = load i32, ptr %boxconst3, align 4
    %snd6 = getelementptr inbounds { i32, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    tail call void @schmu_doo(i32 %fst1, i64 %snd2, i32 %fst5, i64 %snd7), !dbg !41
    %boxconst10 = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 2 }, ptr %boxconst10, align 8
    %fst12 = load i32, ptr %boxconst10, align 4
    %snd13 = getelementptr inbounds { i32, i64 }, ptr %boxconst10, i32 0, i32 1
    %snd14 = load i64, ptr %snd13, align 8
    tail call void @schmu_doo(i32 0, i64 undef, i32 %fst12, i64 %snd14), !dbg !42
    %boxconst15 = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 1 }, ptr %boxconst15, align 8
    %fst17 = load i32, ptr %boxconst15, align 4
    %snd18 = getelementptr inbounds { i32, i64 }, ptr %boxconst15, i32 0, i32 1
    %snd19 = load i64, ptr %snd18, align 8
    %boxconst20 = alloca %option.t.l, align 8
    store %option.t.l { i32 0, i64 undef }, ptr %boxconst20, align 8
    %fst22 = load i32, ptr %boxconst20, align 4
    %snd23 = getelementptr inbounds { i32, i64 }, ptr %boxconst20, i32 0, i32 1
    %snd24 = load i64, ptr %snd23, align 8
    tail call void @schmu_doo(i32 %fst17, i64 %snd19, i32 %fst22, i64 %snd24), !dbg !43
    %boxconst27 = alloca %option.t.l, align 8
    store %option.t.l { i32 0, i64 undef }, ptr %boxconst27, align 8
    %fst29 = load i32, ptr %boxconst27, align 4
    %snd30 = getelementptr inbounds { i32, i64 }, ptr %boxconst27, i32 0, i32 1
    %snd31 = load i64, ptr %snd30, align 8
    tail call void @schmu_doo(i32 0, i64 undef, i32 %fst29, i64 %snd31), !dbg !44
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu tuple_match.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./tuple_match
  3
  2
  1
  0

  $ schmu custom_tag_reuse.smu
  custom_tag_reuse.smu:1.27-28: error: Tag 1 already used for constructor a
  
  1 | type tags = A(1) | B(0) | C(int)
                                ^
  
  [1]

Record literals in pattern matches
  $ schmu match_record.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./match_record
  10
  -1
  20
  -2

Const ctors
  $ schmu const_ctor_issue.smu --dump-llvm --target x86_64-unknown-linux-gnu -c
  const_ctor_issue.smu:2.27-32: warning: Constructor is never used to build values: Thing
  
  2 | type var = Float(float) | Thing(thing)
                                ^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %var = type { i32, %thing }
  %thing = type { i64, %tp.lllll }
  %tp.lllll = type { i64, i64, i64, i64, i64 }
  
  @schmu_var = constant %var { i32 0, { double, [40 x i8] } { double 1.000000e+01, [40 x i8] undef } }
  @0 = private unnamed_addr constant [6 x i8] c"float\00"
  @1 = private unnamed_addr constant [6 x i8] c"thing\00"
  
  declare void @string_println(ptr %0)
  
  define void @schmu_dynamic(ptr %var) !dbg !2 {
  entry:
    %index = load i32, ptr %var, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %var, ptr %var, i32 0, i32 1
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 5, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !7
    br label %ifcont
  
  else:                                             ; preds = %entry
    %data1 = getelementptr inbounds %var, ptr %var, i32 0, i32 1
    %boxconst2 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @1, i64 5, i64 -1 }, ptr %boxconst2, align 8
    call void @string_println(ptr %boxconst2), !dbg !8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 5, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !10
    call void @schmu_dynamic(ptr @schmu_var), !dbg !11
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "const_ctor_issue.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "dynamic", linkageName: "schmu_dynamic", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
  !3 = !DIFile(filename: "const_ctor_issue.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 11, column: 4, scope: !2)
  !7 = !DILocation(line: 11, column: 16, scope: !2)
  !8 = !DILocation(line: 12, column: 16, scope: !2)
  !9 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
  !10 = !DILocation(line: 6, column: 14, scope: !9)
  !11 = !DILocation(line: 15, scope: !9)
  $ schmu const_ctor_issue.smu > /dev/null 2>&1
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./const_ctor_issue
  float
  float

Mutate in pattern matches
  $ schmu mutate.smu
  $ ./mutate
  11
  12

Don't free catchall let pattern in other branch
  $ schmu dont_free_catchall_let_pattern.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./dont_free_catchall_let_pattern

Basic recursive types
  $ schmu recursive.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./recursive

Support path prefixes in match patterns
  $ schmu path_prefix.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./path_prefix

Regression test for this if structure
  $ schmu failwith_ifs.smu
  failwith_ifs.smu:2.33-39: warning: Constructor is never used to build values: Rcurly
  
  2 | type token = With | Semicolon | Rcurly
                                      ^^^^^^
  

Regression test for tuple match
  $ schmu tuple_match_regression.smu
  tuple_match_regression.smu:1.12-13: warning: Constructor is never used to build values: A
  
  1 | type tok = A | B | C(int)
                 ^
  
  $ ./tuple_match_regression
  c
  none

Regression for borrowed ifs (phi nodes). Just make sure it doesn't segfault
 $ schmu -c borrow_phi_variant.smu

Regression for guard. This used to say "none" because it used the content of the
match instead of the ctor after the pattern guard clause
  $ schmu regression_guard.smu
  $ ./regression_guard
  some

Regression for creating an overlapping memcpy on return. The return value ptr %0
is used as a temporary return value and we copy from the temporary to (an offset
of) the return value
  $ schmu return_no_overlapping_copy.smu --dump-llvm --target x86_64-unknown-linux-gnu -c 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %option.t.a.c = type { i32, { ptr, i64, i64 } }
  %closure = type { ptr, ptr }
  %option.t.l = type { i32, i64 }
  
  @0 = private unnamed_addr constant [6 x i8] c"thing\00"
  @1 = private unnamed_addr constant [20 x i8] c"could not parse int\00"
  
  declare void @string_println(ptr %0)
  
  define void @__fun_schmu0(ptr noalias %0, i64 %_i) !dbg !2 {
  entry:
    store i32 1, ptr %0, align 4
    %data = getelementptr inbounds %option.t.a.c, ptr %0, i32 0, i32 1
    %1 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 5, i64 -1 }, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data, ptr align 8 %1, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %data)
    ret void
  }
  
  define linkonce_odr void @__schmu_geti_a.c(ptr noalias %0, ptr %f) !dbg !6 {
  entry:
    %1 = alloca %closure, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %f, i64 16, i1 false)
    %2 = alloca i1, align 1
    store i1 false, ptr %2, align 1
    %ret = alloca %option.t.l, align 8
    %boxconst = alloca { ptr, i64, i64 }, align 8
    %ret2 = alloca %option.t.a.c, align 8
    br label %rec
  
  rec:                                              ; preds = %else8, %then, %entry
    %3 = call { i32, i64 } @schmu_some(i64 0), !dbg !7
    store { i32, i64 } %3, ptr %ret, align 8
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else, !dbg !8
  
  then:                                             ; preds = %rec
    store { ptr, i64, i64 } { ptr @1, i64 19, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !9
    br label %rec
  
  else:                                             ; preds = %rec
    %sunkaddr = getelementptr inbounds i8, ptr %ret, i64 8
    %4 = load i64, ptr %sunkaddr, align 8
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    call void %loadtmp(ptr %ret2, i64 %4, ptr %loadtmp1), !dbg !10
    %index4 = load i32, ptr %ret2, align 4
    %eq5 = icmp eq i32 %index4, 1
    br i1 %eq5, label %then6, label %else8, !dbg !11
  
  then6:                                            ; preds = %else
    %data7 = getelementptr inbounds %option.t.a.c, ptr %ret2, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %data7, i64 24, i1 false)
    store i1 true, ptr %2, align 1
    ret void
  
  else8:                                            ; preds = %else
    call void @__free_option.t.a.c(ptr %ret2)
    br label %rec
  }
  
  define { i32, i64 } @schmu_some(i64 %i) !dbg !12 {
  entry:
    %t = alloca %option.t.l, align 8
    store i32 1, ptr %t, align 4
    %data = getelementptr inbounds %option.t.l, ptr %t, i32 0, i32 1
    store i64 %i, ptr %data, align 8
    %unbox = load { i32, i64 }, ptr %t, align 8
    ret { i32, i64 } %unbox
  }
  
  define linkonce_odr void @__copy_a.c(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %1 = icmp eq i64 %size, 0
    br i1 %1, label %zero, label %nonempty
  
  zero:                                             ; preds = %entry
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 0, ptr %cap, align 8
    store ptr null, ptr %0, align 8
    br label %cont
  
  cont:                                             ; preds = %nonempty, %zero
    ret void
  
  nonempty:                                         ; preds = %entry
    %2 = add i64 %size, 1
    %3 = tail call ptr @malloc(i64 %2)
    %4 = load ptr, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %4, i64 %2, i1 false)
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 %size, ptr %cap2, align 8
    store ptr %3, ptr %0, align 8
    br label %cont
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_option.t.a.c(ptr %0) {
  entry:
    %index = load i32, ptr %0, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t.a.c, ptr %0, i32 0, i32 1
    tail call void @__free_a.c(ptr %data)
    ret void
  
  cont:                                             ; preds = %entry
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !13 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %ret = alloca { ptr, i64, i64 }, align 8
    call void @__schmu_geti_a.c(ptr %ret, ptr %clstmp), !dbg !14
    call void @__free_a.c(ptr %ret)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  declare ptr @malloc(i64 %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu return_no_overlapping_copy.smu > /dev/null 2>&1

Unbox small nested variants to the correct i64
  $ schmu unbox_regression.smu
  $ ./unbox_regression
  a
  b
  c
