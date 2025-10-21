Drop last element
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu array_drop_back.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %option.t.a.l = type { i32, { ptr, i64, i64 } }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_nested = global { ptr, i64, i64 } zeroinitializer, align 8
  @0 = private unnamed_addr constant [5 x i8] c"some\00"
  @1 = private unnamed_addr constant [5 x i8] c"none\00"
  
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
  
  define linkonce_odr void @__array_pop_back_a.a.lroption.t.a.l(ptr noalias %0, ptr noalias %arr) !dbg !7 {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    %1 = load i64, ptr %len, align 8
    %eq = icmp eq i64 %1, 0
    br i1 %eq, label %then, label %else, !dbg !8
  
  then:                                             ; preds = %entry
    store %option.t.a.l { i32 0, { ptr, i64, i64 } undef }, ptr %0, align 8
    ret void
  
  else:                                             ; preds = %entry
    store i32 1, ptr %0, align 4
    %data = getelementptr inbounds %option.t.a.l, ptr %0, i32 0, i32 1
    %2 = sub i64 %1, 1
    %sunkaddr = getelementptr inbounds i8, ptr %arr, i64 8
    store i64 %2, ptr %sunkaddr, align 8
    %3 = load ptr, ptr %arr, align 8
    %4 = getelementptr { ptr, i64, i64 }, ptr %3, i64 %2
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data, ptr align 1 %4, i64 24, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !9 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !11
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %ret), !dbg !12
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %fm) !dbg !13 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !14 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !15
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !16 {
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
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !18
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
    store ptr @__ctor_tp.A64.cl, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !20
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !21
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %i) !dbg !22 {
  entry:
    tail call void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !23
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println__ll(ptr %fmt, i64 %value) !dbg !24 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !25
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !26
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !27
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !29
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !31
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !33
    br i1 %lt, label %then4, label %ifcont, !dbg !33
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
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
    tail call void @__free__up.clru(ptr %0)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !34 {
  entry:
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 48)
    store ptr %0, ptr @schmu_nested, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 2, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 2, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 16)
    store ptr %1, ptr %0, align 8
    store i64 0, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %"1", align 8
    %"12" = getelementptr { ptr, i64, i64 }, ptr %0, i64 1
    %len3 = getelementptr inbounds { ptr, i64, i64 }, ptr %"12", i32 0, i32 1
    store i64 2, ptr %len3, align 8
    %cap4 = getelementptr inbounds { ptr, i64, i64 }, ptr %"12", i32 0, i32 2
    store i64 2, ptr %cap4, align 8
    %2 = tail call ptr @malloc(i64 16)
    store ptr %2, ptr %"12", align 8
    store i64 2, ptr %2, align 8
    %"17" = getelementptr i64, ptr %2, i64 1
    store i64 3, ptr %"17", align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %3 = load i64, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 1), align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %3), !dbg !36
    %ret = alloca %option.t.a.l, align 8
    call void @__array_pop_back_a.a.lroption.t.a.l(ptr %ret, ptr @schmu_nested), !dbg !37
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont, !dbg !38
  
  then:                                             ; preds = %entry
    %data8 = getelementptr inbounds %option.t.a.l, ptr %ret, i32 0, i32 1
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 4, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !39
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %clstmp9 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp9, align 8
    %envptr11 = getelementptr inbounds %closure, ptr %clstmp9, i32 0, i32 1
    store ptr null, ptr %envptr11, align 8
    %4 = load i64, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 1), align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp9, i64 %4), !dbg !40
    %ret12 = alloca %option.t.a.l, align 8
    call void @__array_pop_back_a.a.lroption.t.a.l(ptr %ret12, ptr @schmu_nested), !dbg !41
    %clstmp13 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp13, align 8
    %envptr15 = getelementptr inbounds %closure, ptr %clstmp13, i32 0, i32 1
    store ptr null, ptr %envptr15, align 8
    %5 = load i64, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 1), align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp13, i64 %5), !dbg !42
    %ret16 = alloca %option.t.a.l, align 8
    call void @__array_pop_back_a.a.lroption.t.a.l(ptr %ret16, ptr @schmu_nested), !dbg !43
    %index18 = load i32, ptr %ret16, align 4
    %eq19 = icmp eq i32 %index18, 1
    br i1 %eq19, label %then20, label %else22, !dbg !44
  
  then20:                                           ; preds = %ifcont
    %data21 = getelementptr inbounds %option.t.a.l, ptr %ret16, i32 0, i32 1
    br label %ifcont24
  
  else22:                                           ; preds = %ifcont
    %boxconst23 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @1, i64 4, i64 -1 }, ptr %boxconst23, align 8
    call void @string_println(ptr %boxconst23), !dbg !45
    br label %ifcont24
  
  ifcont24:                                         ; preds = %else22, %then20
    %clstmp25 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp25, align 8
    %envptr27 = getelementptr inbounds %closure, ptr %clstmp25, i32 0, i32 1
    store ptr null, ptr %envptr27, align 8
    %6 = load i64, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 1), align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp25, i64 %6), !dbg !46
    call void @__free_option.t.a.l(ptr %ret16)
    call void @__free_option.t.a.l(ptr %ret12)
    call void @__free_option.t.a.l(ptr %ret)
    call void @__free_a.a.l(ptr @schmu_nested)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_option.t.a.l(ptr %0) {
  entry:
    %index = load i32, ptr %0, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t.a.l, ptr %0, i32 0, i32 1
    tail call void @__free_a.l(ptr %data)
    ret void
  
  cont:                                             ; preds = %entry
    ret void
  }
  
  define linkonce_odr void @__free_a.a.l(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %child ], [ 0, %entry ]
    %1 = phi i64 [ %4, %child ], [ 0, %entry ]
    %2 = icmp slt i64 %1, %size
    br i1 %2, label %child, label %cont
  
  child:                                            ; preds = %rec
    %3 = load ptr, ptr %0, align 8
    %scevgep = getelementptr i8, ptr %3, i64 %lsr.iv
    tail call void @__free_a.l(ptr %scevgep)
    %4 = add i64 %1, 1
    store i64 %4, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
  
  cont:                                             ; preds = %rec
    %5 = load ptr, ptr %0, align 8
    tail call void @free(ptr %5)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu array_drop_back.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./array_drop_back
  2
  some
  1
  0
  none
  0

Array push
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu array_push.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_b = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_nested = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_a__2 = global { ptr, i64, i64 } zeroinitializer, align 8
  @0 = private unnamed_addr constant [22 x i8] c"__array_push_a.a.la.l\00"
  @1 = private unnamed_addr constant [10 x i8] c"array.smu\00"
  @2 = private unnamed_addr constant [15 x i8] c"file not found\00"
  @3 = private unnamed_addr constant [18 x i8] c"__array_push_a.ll\00"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @prelude_power_2_above_or_equal(i64 %0, i64 %1)
  
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
  
  define linkonce_odr void @__array_push_a.a.la.l(ptr noalias %arr, ptr %value) !dbg !7 {
  entry:
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    %0 = load i64, ptr %cap, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    %1 = load i64, ptr %len, align 8
    %eq = icmp eq i64 %0, %1
    br i1 %eq, label %then, label %else11, !dbg !8
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %0, 0
    br i1 %eq1, label %then2, label %else, !dbg !9
  
  then2:                                            ; preds = %then
    %2 = load ptr, ptr %arr, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %success, label %fail, !dbg !10
  
  success:                                          ; preds = %then2
    %4 = tail call ptr @malloc(i64 96)
    store ptr %4, ptr %arr, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 4, ptr %sunkaddr, align 8
    br label %ifcont12
  
  fail:                                             ; preds = %then2
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 55, ptr @0), !dbg !10
    unreachable
  
  else:                                             ; preds = %then
    %5 = load ptr, ptr %arr, align 8
    %6 = icmp eq ptr %5, null
    %7 = xor i1 %6, true
    br i1 %7, label %success6, label %fail7, !dbg !11
  
  success6:                                         ; preds = %else
    %add = add i64 %0, 1
    %8 = tail call i64 @prelude_power_2_above_or_equal(i64 %0, i64 %add), !dbg !12
    %size = mul i64 %8, 24
    %9 = tail call ptr @realloc(ptr %5, i64 %size)
    store ptr %9, ptr %arr, align 8
    %sunkaddr16 = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 %8, ptr %sunkaddr16, align 8
    br label %ifcont12
  
  fail7:                                            ; preds = %else
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 59, ptr @0), !dbg !11
    unreachable
  
  else11:                                           ; preds = %entry
    %.pre = load ptr, ptr %arr, align 8
    br label %ifcont12
  
  ifcont12:                                         ; preds = %success, %success6, %else11
    %10 = phi ptr [ %.pre, %else11 ], [ %9, %success6 ], [ %4, %success ]
    %11 = getelementptr inbounds { ptr, i64, i64 }, ptr %10, i64 %1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %11, ptr align 1 %value, i64 24, i1 false)
    %add15 = add i64 %1, 1
    %sunkaddr17 = getelementptr inbounds i8, ptr %arr, i64 8
    store i64 %add15, ptr %sunkaddr17, align 8
    ret void
  }
  
  define linkonce_odr void @__array_push_a.ll(ptr noalias %arr, i64 %value) !dbg !13 {
  entry:
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    %0 = load i64, ptr %cap, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    %1 = load i64, ptr %len, align 8
    %eq = icmp eq i64 %0, %1
    br i1 %eq, label %then, label %else11, !dbg !14
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %0, 0
    br i1 %eq1, label %then2, label %else, !dbg !15
  
  then2:                                            ; preds = %then
    %2 = load ptr, ptr %arr, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %success, label %fail, !dbg !16
  
  success:                                          ; preds = %then2
    %4 = tail call ptr @malloc(i64 32)
    store ptr %4, ptr %arr, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 4, ptr %sunkaddr, align 8
    br label %ifcont12
  
  fail:                                             ; preds = %then2
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 55, ptr @3), !dbg !16
    unreachable
  
  else:                                             ; preds = %then
    %5 = load ptr, ptr %arr, align 8
    %6 = icmp eq ptr %5, null
    %7 = xor i1 %6, true
    br i1 %7, label %success6, label %fail7, !dbg !17
  
  success6:                                         ; preds = %else
    %add = add i64 %0, 1
    %8 = tail call i64 @prelude_power_2_above_or_equal(i64 %0, i64 %add), !dbg !18
    %size = mul i64 %8, 8
    %9 = tail call ptr @realloc(ptr %5, i64 %size)
    store ptr %9, ptr %arr, align 8
    %sunkaddr16 = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 %8, ptr %sunkaddr16, align 8
    br label %ifcont12
  
  fail7:                                            ; preds = %else
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 59, ptr @3), !dbg !17
    unreachable
  
  else11:                                           ; preds = %entry
    %.pre = load ptr, ptr %arr, align 8
    br label %ifcont12
  
  ifcont12:                                         ; preds = %success, %success6, %else11
    %10 = phi ptr [ %.pre, %else11 ], [ %9, %success6 ], [ %4, %success ]
    %11 = getelementptr inbounds i64, ptr %10, i64 %1
    store i64 %value, ptr %11, align 8
    %add15 = add i64 %1, 1
    %sunkaddr17 = getelementptr inbounds i8, ptr %arr, i64 8
    store i64 %add15, ptr %sunkaddr17, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !19 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !21
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %ret), !dbg !22
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %fm) !dbg !23 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !24 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !25
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !26 {
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
    br i1 %andtmp, label %then, label %else, !dbg !27
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !28
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
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !29
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
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !30
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !31
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %i) !dbg !32 {
  entry:
    tail call void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !33
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println__ll(ptr %fmt, i64 %value) !dbg !34 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !35
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !36
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !37
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !38 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !39
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !40 {
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
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !41
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !42
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !43
    br i1 %lt, label %then4, label %ifcont, !dbg !43
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_in_fun() !dbg !44 {
  entry:
    %0 = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 2, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 2, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 16)
    store ptr %1, ptr %0, align 8
    store i64 10, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 20, ptr %"1", align 8
    %2 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %0, i64 24, i1 false)
    call void @__copy_a.l(ptr %2)
    call void @__array_push_a.ll(ptr %0, i64 30), !dbg !46
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %3 = load i64, ptr %len, align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %3), !dbg !47
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %len5 = getelementptr inbounds { ptr, i64, i64 }, ptr %2, i32 0, i32 1
    %4 = load i64, ptr %len5, align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp2, i64 %4), !dbg !48
    call void @__free_a.l(ptr %2)
    call void @__free_a.l(ptr %0)
    ret void
  }
  
  declare void @prelude_assert_fail(ptr %0, ptr %1, i32 %2, ptr %3)
  
  declare ptr @malloc(i64 %0)
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
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
    tail call void @__free__up.clru(ptr %0)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
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
    %2 = mul i64 %size, 8
    %3 = tail call ptr @malloc(i64 %2)
    %4 = load ptr, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %4, i64 %2, i1 false)
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 %size, ptr %cap2, align 8
    store ptr %3, ptr %0, align 8
    br label %cont
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !49 {
  entry:
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 16)
    store ptr %0, ptr @schmu_a, align 8
    store i64 10, ptr %0, align 8
    %"1" = getelementptr i64, ptr %0, i64 1
    store i64 20, ptr %"1", align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 24, i1 false)
    tail call void @__copy_a.l(ptr @schmu_b)
    tail call void @__array_push_a.ll(ptr @schmu_a, i64 30), !dbg !50
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %1 = load i64, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %1), !dbg !51
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %2 = load i64, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_b, i32 0, i32 1), align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp1, i64 %2), !dbg !52
    call void @schmu_in_fun(), !dbg !53
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 2), align 8
    %3 = call ptr @malloc(i64 48)
    store ptr %3, ptr @schmu_nested, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %3, i32 0, i32 1
    store i64 2, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %3, i32 0, i32 2
    store i64 2, ptr %cap, align 8
    %4 = call ptr @malloc(i64 16)
    store ptr %4, ptr %3, align 8
    store i64 0, ptr %4, align 8
    %"16" = getelementptr i64, ptr %4, i64 1
    store i64 1, ptr %"16", align 8
    %"17" = getelementptr { ptr, i64, i64 }, ptr %3, i64 1
    %len8 = getelementptr inbounds { ptr, i64, i64 }, ptr %"17", i32 0, i32 1
    store i64 2, ptr %len8, align 8
    %cap9 = getelementptr inbounds { ptr, i64, i64 }, ptr %"17", i32 0, i32 2
    store i64 2, ptr %cap9, align 8
    %5 = call ptr @malloc(i64 16)
    store ptr %5, ptr %"17", align 8
    store i64 2, ptr %5, align 8
    %"112" = getelementptr i64, ptr %5, i64 1
    store i64 3, ptr %"112", align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a__2, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a__2, i32 0, i32 2), align 8
    %6 = call ptr @malloc(i64 16)
    store ptr %6, ptr @schmu_a__2, align 8
    store i64 4, ptr %6, align 8
    %"114" = getelementptr i64, ptr %6, i64 1
    store i64 5, ptr %"114", align 8
    %7 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %7, ptr align 8 @schmu_a__2, i64 24, i1 false)
    call void @__copy_a.l(ptr %7)
    call void @__array_push_a.a.la.l(ptr @schmu_nested, ptr %7), !dbg !54
    %8 = load ptr, ptr @schmu_nested, align 8
    %9 = getelementptr { ptr, i64, i64 }, ptr %8, i64 1
    %10 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %10, ptr align 8 @schmu_a__2, i64 24, i1 false)
    call void @__copy_a.l(ptr %10)
    call void @__free_a.l(ptr %9)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %9, ptr align 8 %10, i64 24, i1 false)
    %11 = load ptr, ptr @schmu_nested, align 8
    %12 = getelementptr { ptr, i64, i64 }, ptr %11, i64 1
    %13 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %13, ptr align 8 @schmu_a__2, i64 24, i1 false)
    call void @__copy_a.l(ptr %13)
    call void @__free_a.l(ptr %12)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %12, ptr align 8 %13, i64 24, i1 false)
    %arr = alloca { ptr, i64, i64 }, align 8
    %len15 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 2, ptr %len15, align 8
    %cap16 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 2, ptr %cap16, align 8
    %14 = call ptr @malloc(i64 16)
    store ptr %14, ptr %arr, align 8
    store i64 4, ptr %14, align 8
    %"119" = getelementptr i64, ptr %14, i64 1
    store i64 5, ptr %"119", align 8
    call void @__array_push_a.a.la.l(ptr @schmu_nested, ptr %arr), !dbg !55
    %15 = load ptr, ptr @schmu_nested, align 8
    %16 = getelementptr { ptr, i64, i64 }, ptr %15, i64 1
    %arr20 = alloca { ptr, i64, i64 }, align 8
    %len21 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr20, i32 0, i32 1
    store i64 2, ptr %len21, align 8
    %cap22 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr20, i32 0, i32 2
    store i64 2, ptr %cap22, align 8
    %17 = call ptr @malloc(i64 16)
    store ptr %17, ptr %arr20, align 8
    store i64 4, ptr %17, align 8
    %"125" = getelementptr i64, ptr %17, i64 1
    store i64 5, ptr %"125", align 8
    call void @__free_a.l(ptr %16)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %16, ptr align 8 %arr20, i64 24, i1 false)
    %18 = load ptr, ptr @schmu_nested, align 8
    %19 = getelementptr { ptr, i64, i64 }, ptr %18, i64 1
    %arr26 = alloca { ptr, i64, i64 }, align 8
    %len27 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr26, i32 0, i32 1
    store i64 2, ptr %len27, align 8
    %cap28 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr26, i32 0, i32 2
    store i64 2, ptr %cap28, align 8
    %20 = call ptr @malloc(i64 16)
    store ptr %20, ptr %arr26, align 8
    store i64 4, ptr %20, align 8
    %"131" = getelementptr i64, ptr %20, i64 1
    store i64 5, ptr %"131", align 8
    call void @__free_a.l(ptr %19)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %19, ptr align 8 %arr26, i64 24, i1 false)
    call void @__free_a.l(ptr @schmu_a__2)
    call void @__free_a.a.l(ptr @schmu_nested)
    call void @__free_a.l(ptr @schmu_b)
    call void @__free_a.l(ptr @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.a.l(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %child ], [ 0, %entry ]
    %1 = phi i64 [ %4, %child ], [ 0, %entry ]
    %2 = icmp slt i64 %1, %size
    br i1 %2, label %child, label %cont
  
  child:                                            ; preds = %rec
    %3 = load ptr, ptr %0, align 8
    %scevgep = getelementptr i8, ptr %3, i64 %lsr.iv
    tail call void @__free_a.l(ptr %scevgep)
    %4 = add i64 %1, 1
    store i64 %4, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
  
  cont:                                             ; preds = %rec
    %5 = load ptr, ptr %0, align 8
    tail call void @free(ptr %5)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu array_push.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./array_push
  3
  2
  3
  2

Don't free string literals
  $ schmu borrow_string_lit.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./borrow_string_lit

Use captured record-field functions
  $ schmu capture_record_pattern.smu && ./capture_record_pattern
  3
  printing 0
  printing 1.1

Monomorphization in closures
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu closure_monomorph.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.t.u = type { %closure }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_arr = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_arr__2 = global { ptr, i64, i64 } zeroinitializer, align 8
  
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
  
  define linkonce_odr i1 @__array_inner__2_Ca.l_lrb(i64 %i, ptr %0) !dbg !7 {
  entry:
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    br label %rec
  
  rec:                                              ; preds = %then2, %entry
    %2 = phi i64 [ %add, %then2 ], [ %i, %entry ]
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 24
    %3 = load i64, ptr %sunkaddr, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %ifcont4, label %else, !dbg !8
  
  else:                                             ; preds = %rec
    %sunkaddr5 = getelementptr inbounds i8, ptr %0, i64 16
    %4 = load ptr, ptr %sunkaddr5, align 8
    %5 = shl i64 %2, 3
    %scevgep = getelementptr i8, ptr %4, i64 %5
    %6 = load i64, ptr %scevgep, align 8
    %sunkaddr6 = getelementptr inbounds i8, ptr %0, i64 40
    %loadtmp = load ptr, ptr %sunkaddr6, align 8
    %sunkaddr7 = getelementptr inbounds i8, ptr %0, i64 48
    %loadtmp1 = load ptr, ptr %sunkaddr7, align 8
    %7 = tail call i1 %loadtmp(i64 %6, ptr %loadtmp1), !dbg !9
    br i1 %7, label %then2, label %ifcont4, !dbg !9
  
  then2:                                            ; preds = %else
    %add = add i64 %2, 1
    store i64 %add, ptr %1, align 8
    br label %rec
  
  ifcont4:                                          ; preds = %else, %rec
    ret i1 false
  }
  
  define linkonce_odr i1 @__array_iter_a.l_l(ptr %arr, ptr %cont) !dbg !10 {
  entry:
    %__array_inner__2_Ca.l_lrb = alloca %closure, align 8
    store ptr @__array_inner__2_Ca.l_lrb, ptr %__array_inner__2_Ca.l_lrb, align 8
    %clsr___array_inner__2_Ca.l_lrb = alloca { ptr, ptr, { ptr, i64, i64 }, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 }, %closure }, ptr %clsr___array_inner__2_Ca.l_lrb, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %arr1, ptr align 1 %arr, i64 24, i1 false)
    %cont2 = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 }, %closure }, ptr %clsr___array_inner__2_Ca.l_lrb, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cont2, ptr align 1 %cont, i64 16, i1 false)
    store ptr @__ctor_tp.a.l_lrb, ptr %clsr___array_inner__2_Ca.l_lrb, align 8
    %dtor = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 }, %closure }, ptr %clsr___array_inner__2_Ca.l_lrb, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__array_inner__2_Ca.l_lrb, i32 0, i32 1
    store ptr %clsr___array_inner__2_Ca.l_lrb, ptr %envptr, align 8
    %0 = call i1 @__array_inner__2_Ca.l_lrb(i64 0, ptr %clsr___array_inner__2_Ca.l_lrb), !dbg !11
    ret i1 %0
  }
  
  define linkonce_odr void @__array_swap_items_a.l(ptr noalias %arr, i64 %i, i64 %j) !dbg !12 {
  entry:
    %eq = icmp eq i64 %i, %j
    %0 = xor i1 %eq, true
    br i1 %0, label %then, label %ifcont, !dbg !13
  
  then:                                             ; preds = %entry
    %1 = alloca i64, align 8
    %2 = load ptr, ptr %arr, align 8
    %3 = getelementptr i64, ptr %2, i64 %i
    %4 = load i64, ptr %3, align 8
    store i64 %4, ptr %1, align 8
    %5 = getelementptr i64, ptr %2, i64 %j
    %6 = load i64, ptr %5, align 8
    store i64 %6, ptr %3, align 8
    store i64 %4, ptr %5, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !14 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !16
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %ret), !dbg !17
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %fm) !dbg !18 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !19 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !20
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !21 {
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
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !23
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
    store ptr @__ctor_tp.A64.cl, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !25
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !26
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %i) !dbg !27 {
  entry:
    tail call void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !28
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println__ll(ptr %fmt, i64 %value) !dbg !29 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !30
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !31
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !32
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !34
    ret void
  }
  
  define linkonce_odr i1 @__fun_iter6_lC_lru(i64 %x, ptr %0) !dbg !35 {
  entry:
    %f = getelementptr inbounds { ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(i64 %x, ptr %loadtmp1), !dbg !37
    ret i1 true
  }
  
  define linkonce_odr void @__fun_schmu0_Ca.l_llrlll(i64 %j, ptr %0) !dbg !38 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %cmp = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 3
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 4
    %i2 = load ptr, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 5
    %pivot3 = load i64, ptr %pivot, align 8
    %1 = load ptr, ptr %arr1, align 8
    %2 = getelementptr i64, ptr %1, i64 %j
    %3 = load i64, ptr %2, align 8
    %loadtmp = load ptr, ptr %cmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %cmp, i32 0, i32 1
    %loadtmp4 = load ptr, ptr %envptr, align 8
    %4 = tail call i64 %loadtmp(i64 %3, i64 %pivot3, ptr %loadtmp4), !dbg !40
    %lt = icmp slt i64 %4, 0
    br i1 %lt, label %then, label %ifcont, !dbg !40
  
  then:                                             ; preds = %entry
    %5 = load i64, ptr %i2, align 8
    %add = add i64 %5, 1
    store i64 %add, ptr %i2, align 8
    tail call void @__array_swap_items_a.l(ptr %arr1, i64 %add, i64 %j), !dbg !41
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
    %0 = tail call i1 @__array_iter_a.l_l(ptr @schmu_arr, ptr %__curry0), !dbg !44
    ret i1 %0
  }
  
  define void @__fun_schmu3(i64 %i) !dbg !45 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %i), !dbg !46
    ret void
  }
  
  define linkonce_odr void @__fun_schmu4_Ca.l_llrlll(i64 %j, ptr %0) !dbg !47 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %cmp = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 3
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 4
    %i2 = load ptr, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %0, i32 0, i32 5
    %pivot3 = load i64, ptr %pivot, align 8
    %1 = load ptr, ptr %arr1, align 8
    %2 = getelementptr i64, ptr %1, i64 %j
    %3 = load i64, ptr %2, align 8
    %loadtmp = load ptr, ptr %cmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %cmp, i32 0, i32 1
    %loadtmp4 = load ptr, ptr %envptr, align 8
    %4 = tail call i64 %loadtmp(i64 %3, i64 %pivot3, ptr %loadtmp4), !dbg !48
    %lt = icmp slt i64 %4, 0
    br i1 %lt, label %then, label %ifcont, !dbg !48
  
  then:                                             ; preds = %entry
    %5 = load i64, ptr %i2, align 8
    %add = add i64 %5, 1
    store i64 %add, ptr %i2, align 8
    tail call void @__array_swap_items_a.l(ptr %arr1, i64 %add, i64 %j), !dbg !49
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
    %0 = tail call i1 @__array_iter_a.l_l(ptr @schmu_arr__2, ptr %__curry0), !dbg !52
    ret i1 %0
  }
  
  define void @__fun_schmu7(i64 %i) !dbg !53 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %i), !dbg !54
    ret void
  }
  
  define linkonce_odr void @__iter_iter___l_l(ptr %it, ptr %f) !dbg !55 {
  entry:
    %__fun_iter6_lC_lru = alloca %closure, align 8
    store ptr @__fun_iter6_lC_lru, ptr %__fun_iter6_lC_lru, align 8
    %clsr___fun_iter6_lC_lru = alloca { ptr, ptr, %closure }, align 8
    %f1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___fun_iter6_lC_lru, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f1, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_tp._lru, ptr %clsr___fun_iter6_lC_lru, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___fun_iter6_lC_lru, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_iter6_lC_lru, i32 0, i32 1
    store ptr %clsr___fun_iter6_lC_lru, ptr %envptr, align 8
    %loadtmp = load ptr, ptr %it, align 8
    %envptr2 = getelementptr inbounds %closure, ptr %it, i32 0, i32 1
    %loadtmp3 = load ptr, ptr %envptr2, align 8
    %0 = call i1 %loadtmp(ptr %__fun_iter6_lC_lru, ptr %loadtmp3), !dbg !56
    ret void
  }
  
  define linkonce_odr i64 @__schmu_partition__2_a.lC_llrl(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !57 {
  entry:
    %cmp = getelementptr inbounds { ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %1 = load ptr, ptr %arr, align 8
    %2 = getelementptr i64, ptr %1, i64 %hi
    %3 = alloca i64, align 8
    %4 = load i64, ptr %2, align 8
    store i64 %4, ptr %3, align 8
    %5 = alloca i64, align 8
    %sub = sub i64 %lo, 1
    store i64 %sub, ptr %5, align 8
    %__fun_schmu4_Ca.l_llrlll = alloca %closure, align 8
    store ptr @__fun_schmu4_Ca.l_llrlll, ptr %__fun_schmu4_Ca.l_llrlll, align 8
    %clsr___fun_schmu4_Ca.l_llrlll = alloca { ptr, ptr, ptr, %closure, ptr, i64 }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l_llrlll, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cmp2 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l_llrlll, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp2, ptr align 1 %cmp, i64 16, i1 false)
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l_llrlll, i32 0, i32 4
    store ptr %5, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l_llrlll, i32 0, i32 5
    store i64 %4, ptr %pivot, align 8
    store ptr @__ctor_tp.a.l_llrlll, ptr %clsr___fun_schmu4_Ca.l_llrlll, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l_llrlll, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu4_Ca.l_llrlll, i32 0, i32 1
    store ptr %clsr___fun_schmu4_Ca.l_llrlll, ptr %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, ptr %__fun_schmu4_Ca.l_llrlll), !dbg !58
    %6 = load i64, ptr %5, align 8
    %add = add i64 %6, 1
    call void @__array_swap_items_a.l(ptr %arr, i64 %add, i64 %hi), !dbg !59
    ret i64 %add
  }
  
  define linkonce_odr i64 @__schmu_partition_a.lC_llrl(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !60 {
  entry:
    %cmp = getelementptr inbounds { ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %1 = load ptr, ptr %arr, align 8
    %2 = getelementptr i64, ptr %1, i64 %hi
    %3 = alloca i64, align 8
    %4 = load i64, ptr %2, align 8
    store i64 %4, ptr %3, align 8
    %5 = alloca i64, align 8
    %sub = sub i64 %lo, 1
    store i64 %sub, ptr %5, align 8
    %__fun_schmu0_Ca.l_llrlll = alloca %closure, align 8
    store ptr @__fun_schmu0_Ca.l_llrlll, ptr %__fun_schmu0_Ca.l_llrlll, align 8
    %clsr___fun_schmu0_Ca.l_llrlll = alloca { ptr, ptr, ptr, %closure, ptr, i64 }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l_llrlll, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cmp2 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l_llrlll, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp2, ptr align 1 %cmp, i64 16, i1 false)
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l_llrlll, i32 0, i32 4
    store ptr %5, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l_llrlll, i32 0, i32 5
    store i64 %4, ptr %pivot, align 8
    store ptr @__ctor_tp.a.l_llrlll, ptr %clsr___fun_schmu0_Ca.l_llrlll, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l_llrlll, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu0_Ca.l_llrlll, i32 0, i32 1
    store ptr %clsr___fun_schmu0_Ca.l_llrlll, ptr %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, ptr %__fun_schmu0_Ca.l_llrlll), !dbg !61
    %6 = load i64, ptr %5, align 8
    %add = add i64 %6, 1
    call void @__array_swap_items_a.l(ptr %arr, i64 %add, i64 %hi), !dbg !62
    ret i64 %add
  }
  
  define linkonce_odr void @__schmu_quicksort__2_a.lC_a.lllrlC_llrl(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !63 {
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
    tail call void @__schmu_quicksort__2_a.lC_a.lllrlC_llrl(ptr %arr, i64 %5, i64 %sub, ptr %0), !dbg !66
    %add = add i64 %7, 1
    store ptr %arr, ptr %1, align 8
    store i64 %add, ptr %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_quicksort_a.lC_a.lllrlC_llrl(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !67 {
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
    tail call void @__schmu_quicksort_a.lC_a.lllrlC_llrl(ptr %arr, i64 %5, i64 %sub, ptr %0), !dbg !70
    %add = add i64 %7, 1
    store ptr %arr, ptr %1, align 8
    store i64 %add, ptr %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_sort__2_a.l_ll(ptr noalias %arr, ptr %cmp) !dbg !71 {
  entry:
    %__schmu_partition__2_a.lC_llrl = alloca %closure, align 8
    store ptr @__schmu_partition__2_a.lC_llrl, ptr %__schmu_partition__2_a.lC_llrl, align 8
    %clsr___schmu_partition__2_a.lC_llrl = alloca { ptr, ptr, %closure }, align 8
    %cmp1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition__2_a.lC_llrl, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp1, ptr align 1 %cmp, i64 16, i1 false)
    store ptr @__ctor_tp._llrl, ptr %clsr___schmu_partition__2_a.lC_llrl, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition__2_a.lC_llrl, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__schmu_partition__2_a.lC_llrl, i32 0, i32 1
    store ptr %clsr___schmu_partition__2_a.lC_llrl, ptr %envptr, align 8
    %__schmu_quicksort__2_a.lC_a.lllrlC_llrl = alloca %closure, align 8
    store ptr @__schmu_quicksort__2_a.lC_a.lllrlC_llrl, ptr %__schmu_quicksort__2_a.lC_a.lllrlC_llrl, align 8
    %clsr___schmu_quicksort__2_a.lC_a.lllrlC_llrl = alloca { ptr, ptr, %closure }, align 8
    %__schmu_partition__2_a.lC_llrl3 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort__2_a.lC_a.lllrlC_llrl, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %__schmu_partition__2_a.lC_llrl3, ptr align 8 %__schmu_partition__2_a.lC_llrl, i64 16, i1 false)
    store ptr @__ctor_tp._a.lllrl, ptr %clsr___schmu_quicksort__2_a.lC_a.lllrlC_llrl, align 8
    %dtor5 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort__2_a.lC_a.lllrlC_llrl, i32 0, i32 1
    store ptr null, ptr %dtor5, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %__schmu_quicksort__2_a.lC_a.lllrlC_llrl, i32 0, i32 1
    store ptr %clsr___schmu_quicksort__2_a.lC_a.lllrlC_llrl, ptr %envptr6, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    %0 = load i64, ptr %len, align 8
    %sub = sub i64 %0, 1
    call void @__schmu_quicksort__2_a.lC_a.lllrlC_llrl(ptr %arr, i64 0, i64 %sub, ptr %clsr___schmu_quicksort__2_a.lC_a.lllrlC_llrl), !dbg !72
    ret void
  }
  
  define linkonce_odr void @__schmu_sort_a.l_ll(ptr noalias %arr, ptr %cmp) !dbg !73 {
  entry:
    %__schmu_partition_a.lC_llrl = alloca %closure, align 8
    store ptr @__schmu_partition_a.lC_llrl, ptr %__schmu_partition_a.lC_llrl, align 8
    %clsr___schmu_partition_a.lC_llrl = alloca { ptr, ptr, %closure }, align 8
    %cmp1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition_a.lC_llrl, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp1, ptr align 1 %cmp, i64 16, i1 false)
    store ptr @__ctor_tp._llrl, ptr %clsr___schmu_partition_a.lC_llrl, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition_a.lC_llrl, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__schmu_partition_a.lC_llrl, i32 0, i32 1
    store ptr %clsr___schmu_partition_a.lC_llrl, ptr %envptr, align 8
    %__schmu_quicksort_a.lC_a.lllrlC_llrl = alloca %closure, align 8
    store ptr @__schmu_quicksort_a.lC_a.lllrlC_llrl, ptr %__schmu_quicksort_a.lC_a.lllrlC_llrl, align 8
    %clsr___schmu_quicksort_a.lC_a.lllrlC_llrl = alloca { ptr, ptr, %closure }, align 8
    %__schmu_partition_a.lC_llrl3 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort_a.lC_a.lllrlC_llrl, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %__schmu_partition_a.lC_llrl3, ptr align 8 %__schmu_partition_a.lC_llrl, i64 16, i1 false)
    store ptr @__ctor_tp._a.lllrl, ptr %clsr___schmu_quicksort_a.lC_a.lllrlC_llrl, align 8
    %dtor5 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort_a.lC_a.lllrlC_llrl, i32 0, i32 1
    store ptr null, ptr %dtor5, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %__schmu_quicksort_a.lC_a.lllrlC_llrl, i32 0, i32 1
    store ptr %clsr___schmu_quicksort_a.lC_a.lllrlC_llrl, ptr %envptr6, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    %0 = load i64, ptr %len, align 8
    %sub = sub i64 %0, 1
    call void @__schmu_quicksort_a.lC_a.lllrlC_llrl(ptr %arr, i64 0, i64 %sub, ptr %clsr___schmu_quicksort_a.lC_a.lllrlC_llrl), !dbg !74
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !76
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !77
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !78
    br i1 %lt, label %then4, label %ifcont, !dbg !78
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.a.l_lrb(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 56)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 56, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 }, %closure }, ptr %1, i32 0, i32 2
    tail call void @__copy_a.l(ptr %arr)
    %cont = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 }, %closure }, ptr %1, i32 0, i32 3
    tail call void @__copy__lrb(ptr %cont)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
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
    %2 = mul i64 %size, 8
    %3 = tail call ptr @malloc(i64 %2)
    %4 = load ptr, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %4, i64 %2, i1 false)
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 %size, ptr %cap2, align 8
    store ptr %3, ptr %0, align 8
    br label %cont
  }
  
  define linkonce_odr void @__copy__lrb(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
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
    tail call void @__free__up.clru(ptr %0)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  define linkonce_odr ptr @__ctor_tp._lru(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 32)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %f = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    tail call void @__copy__lru(ptr %f)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__lru(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp.a.l_llrlll(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 72)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 72, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %1, i32 0, i32 2
    tail call void @__copy_a.l(ptr %arr)
    %cmp = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %1, i32 0, i32 3
    tail call void @__copy__llrl(ptr %cmp)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__llrl(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp._llrl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 32)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %cmp = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    tail call void @__copy__llrl(ptr %cmp)
    ret ptr %1
  }
  
  define linkonce_odr ptr @__ctor_tp._a.lllrl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 32)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %__schmu_partition__2_a.lC_llrl = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    tail call void @__copy__a.lllrl(ptr %__schmu_partition__2_a.lC_llrl)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__a.lllrl(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !79 {
  entry:
    store i64 6, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr, i32 0, i32 1), align 8
    store i64 6, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 48)
    store ptr %0, ptr @schmu_arr, align 8
    store i64 9, ptr %0, align 8
    %"1" = getelementptr i64, ptr %0, i64 1
    store i64 30, ptr %"1", align 8
    %"2" = getelementptr i64, ptr %0, i64 2
    store i64 0, ptr %"2", align 8
    %"3" = getelementptr i64, ptr %0, i64 3
    store i64 50, ptr %"3", align 8
    %"4" = getelementptr i64, ptr %0, i64 4
    store i64 2030, ptr %"4", align 8
    %"5" = getelementptr i64, ptr %0, i64 5
    store i64 34, ptr %"5", align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu1, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__schmu_sort_a.l_ll(ptr @schmu_arr, ptr %clstmp), !dbg !80
    %clstmp1 = alloca %closure, align 8
    store ptr @__fun_schmu2, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %clstmp4 = alloca %closure, align 8
    store ptr @__fun_schmu3, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    call void @__iter_iter___l_l(ptr %clstmp1, ptr %clstmp4), !dbg !81
    store i64 6, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr__2, i32 0, i32 1), align 8
    store i64 6, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr__2, i32 0, i32 2), align 8
    %1 = call ptr @malloc(i64 48)
    store ptr %1, ptr @schmu_arr__2, align 8
    store i64 9, ptr %1, align 8
    %"18" = getelementptr i64, ptr %1, i64 1
    store i64 30, ptr %"18", align 8
    %"29" = getelementptr i64, ptr %1, i64 2
    store i64 0, ptr %"29", align 8
    %"310" = getelementptr i64, ptr %1, i64 3
    store i64 50, ptr %"310", align 8
    %"411" = getelementptr i64, ptr %1, i64 4
    store i64 2030, ptr %"411", align 8
    %"512" = getelementptr i64, ptr %1, i64 5
    store i64 34, ptr %"512", align 8
    %clstmp13 = alloca %closure, align 8
    store ptr @__fun_schmu5, ptr %clstmp13, align 8
    %envptr15 = getelementptr inbounds %closure, ptr %clstmp13, i32 0, i32 1
    store ptr null, ptr %envptr15, align 8
    call void @__schmu_sort__2_a.l_ll(ptr @schmu_arr__2, ptr %clstmp13), !dbg !82
    %clstmp16 = alloca %closure, align 8
    store ptr @__fun_schmu6, ptr %clstmp16, align 8
    %envptr18 = getelementptr inbounds %closure, ptr %clstmp16, i32 0, i32 1
    store ptr null, ptr %envptr18, align 8
    %clstmp19 = alloca %closure, align 8
    store ptr @__fun_schmu7, ptr %clstmp19, align 8
    %envptr21 = getelementptr inbounds %closure, ptr %clstmp19, i32 0, i32 1
    store ptr null, ptr %envptr21, align 8
    call void @__iter_iter___l_l(ptr %clstmp16, ptr %clstmp19), !dbg !83
    call void @__free_a.l(ptr @schmu_arr__2)
    call void @__free_a.l(ptr @schmu_arr)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu closure_monomorph.smu
  $ ./closure_monomorph
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
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu const_fixed_arr.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.ll = type { i64, i64 }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @schmu_a = constant i64 17
  @schmu_arr = constant [3 x i64] [i64 1, i64 17, i64 3]
  @fmt_newline = internal constant [1 x i8] c"\0A"
  
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
  
  define linkonce_odr void @__fmt_stdout_println__ll(ptr %fmt, i64 %value) !dbg !22 {
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !29
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !30
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !31
    br i1 %lt, label %then4, label %ifcont, !dbg !31
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
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
    tail call void @__free__up.clru(ptr %0)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !32 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 17), !dbg !34
    %0 = alloca %tp.ll, align 8
    store i64 10, ptr %0, align 8
    %"1" = getelementptr inbounds %tp.ll, ptr %0, i32 0, i32 1
    store i64 17, ptr %"1", align 8
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu const_fixed_arr.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./const_fixed_arr
  17

Decrease ref counts for local variables in if branches
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu decr_rc_if.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  define i1 @schmu_ret_true() !dbg !2 {
  entry:
    ret i1 true
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    %0 = tail call i1 @schmu_ret_true(), !dbg !7
    br i1 %0, label %then, label %else, !dbg !7
  
  then:                                             ; preds = %entry
    %arr = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 8)
    store ptr %1, ptr %arr, align 8
    store i64 10, ptr %1, align 8
    %arr1 = alloca { ptr, i64, i64 }, align 8
    %len2 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr1, i32 0, i32 1
    store i64 1, ptr %len2, align 8
    %cap3 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr1, i32 0, i32 2
    store i64 1, ptr %cap3, align 8
    %2 = tail call ptr @malloc(i64 8)
    store ptr %2, ptr %arr1, align 8
    store i64 10, ptr %2, align 8
    call void @__free_a.l(ptr %arr)
    br label %ifcont
  
  else:                                             ; preds = %entry
    %arr6 = alloca { ptr, i64, i64 }, align 8
    %len7 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr6, i32 0, i32 1
    store i64 1, ptr %len7, align 8
    %cap8 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr6, i32 0, i32 2
    store i64 1, ptr %cap8, align 8
    %3 = tail call ptr @malloc(i64 8)
    store ptr %3, ptr %arr6, align 8
    store i64 0, ptr %3, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %arr1, %then ], [ %arr6, %else ]
    call void @__free_a.l(ptr %iftmp)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu decr_rc_if.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./decr_rc_if

Check allocs in fixed array
  $ schmu fixed_array_allocs.smu
  fixed_array_allocs.smu:1.5-8: warning: Unused binding arr
  
  1 | let arr = #[#[1, 2, 3], #[3, 4, 5]]
          ^^^
  
  fixed_array_allocs.smu:8.9-12: warning: Unmutated mutable binding arr
  
  8 | let mut arr = #[copy("hey"), copy("hie")] -- correctly free as mutate
              ^^^
  

  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./fixed_array_allocs
  3
  hi
  hie
  oho

Allocate vectors on the heap and free them. Check with valgrind-wrapper whenever something changes here.
Also mutable fields and 'realloc' builtin
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu free_array.smu 2>&1 | grep -v !DI
  free_array.smu:7.5-8: warning: Unused binding arr
  
  7 | let arr = [copy("hey"), copy("young"), copy("world")]
          ^^^
  
  free_array.smu:8.5-8: warning: Unused binding arr
  
  8 | let arr = [copy(x), {x = 2}, {x = 3}]
          ^^^
  
  free_array.smu:47.5-8: warning: Unused binding arr
  
  47 | let arr = make_arr()
           ^^^
  
  free_array.smu:50.5-11: warning: Unused binding normal
  
  50 | let normal = nest_fns()
           ^^^^^^
  
  free_array.smu:54.5-11: warning: Unused binding nested
  
  54 | let nested = make_nested_arr()
           ^^^^^^
  
  free_array.smu:55.5-11: warning: Unused binding nested
  
  55 | let nested = nest_allocs()
           ^^^^^^
  
  free_array.smu:58.5-15: warning: Unused binding rec_of_arr
  
  58 | let rec_of_arr = {index = 12, arr = [1, 2]}
           ^^^^^^^^^^
  
  free_array.smu:59.5-15: warning: Unused binding rec_of_arr
  
  59 | let rec_of_arr = record_of_arrs()
           ^^^^^^^^^^
  
  free_array.smu:61.5-15: warning: Unused binding arr_of_rec
  
  61 | let arr_of_rec = [record_of_arrs(), record_of_arrs()]
           ^^^^^^^^^^
  
  free_array.smu:62.5-15: warning: Unused binding arr_of_rec
  
  62 | let arr_of_rec = arr_of_records()
           ^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %container = type { i64, { ptr, i64, i64 } }
  
  @schmu_x = constant %foo { i64 1 }
  @schmu_x__2 = internal constant %foo { i64 23 }
  @schmu_arr = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_arr__2 = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_arr__3 = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_normal = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_nested = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_nested__2 = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_nested__3 = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_rec_of_arr = global %container zeroinitializer, align 8
  @schmu_rec_of_arr__2 = global %container zeroinitializer, align 8
  @schmu_arr_of_rec = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_arr_of_rec__2 = global { ptr, i64, i64 } zeroinitializer, align 8
  @0 = private unnamed_addr constant [22 x i8] c"__array_push_a.a.la.l\00"
  @1 = private unnamed_addr constant [10 x i8] c"array.smu\00"
  @2 = private unnamed_addr constant [15 x i8] c"file not found\00"
  @3 = private unnamed_addr constant [22 x i8] c"__array_push_a.foofoo\00"
  @4 = private unnamed_addr constant [4 x i8] c"hey\00"
  @5 = private unnamed_addr constant [6 x i8] c"young\00"
  @6 = private unnamed_addr constant [6 x i8] c"world\00"
  
  declare i64 @prelude_power_2_above_or_equal(i64 %0, i64 %1)
  
  define linkonce_odr void @__array_push_a.a.la.l(ptr noalias %arr, ptr %value) !dbg !2 {
  entry:
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    %0 = load i64, ptr %cap, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    %1 = load i64, ptr %len, align 8
    %eq = icmp eq i64 %0, %1
    br i1 %eq, label %then, label %else11, !dbg !6
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %0, 0
    br i1 %eq1, label %then2, label %else, !dbg !7
  
  then2:                                            ; preds = %then
    %2 = load ptr, ptr %arr, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %success, label %fail, !dbg !8
  
  success:                                          ; preds = %then2
    %4 = tail call ptr @malloc(i64 96)
    store ptr %4, ptr %arr, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 4, ptr %sunkaddr, align 8
    br label %ifcont12
  
  fail:                                             ; preds = %then2
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 55, ptr @0), !dbg !8
    unreachable
  
  else:                                             ; preds = %then
    %5 = load ptr, ptr %arr, align 8
    %6 = icmp eq ptr %5, null
    %7 = xor i1 %6, true
    br i1 %7, label %success6, label %fail7, !dbg !9
  
  success6:                                         ; preds = %else
    %add = add i64 %0, 1
    %8 = tail call i64 @prelude_power_2_above_or_equal(i64 %0, i64 %add), !dbg !10
    %size = mul i64 %8, 24
    %9 = tail call ptr @realloc(ptr %5, i64 %size)
    store ptr %9, ptr %arr, align 8
    %sunkaddr16 = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 %8, ptr %sunkaddr16, align 8
    br label %ifcont12
  
  fail7:                                            ; preds = %else
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 59, ptr @0), !dbg !9
    unreachable
  
  else11:                                           ; preds = %entry
    %.pre = load ptr, ptr %arr, align 8
    br label %ifcont12
  
  ifcont12:                                         ; preds = %success, %success6, %else11
    %10 = phi ptr [ %.pre, %else11 ], [ %9, %success6 ], [ %4, %success ]
    %11 = getelementptr inbounds { ptr, i64, i64 }, ptr %10, i64 %1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %11, ptr align 1 %value, i64 24, i1 false)
    %add15 = add i64 %1, 1
    %sunkaddr17 = getelementptr inbounds i8, ptr %arr, i64 8
    store i64 %add15, ptr %sunkaddr17, align 8
    ret void
  }
  
  define linkonce_odr void @__array_push_a.foofoo(ptr noalias %arr, i64 %0) !dbg !11 {
  entry:
    %value = alloca i64, align 8
    store i64 %0, ptr %value, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    %1 = load i64, ptr %cap, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    %2 = load i64, ptr %len, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %else11, !dbg !12
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else, !dbg !13
  
  then2:                                            ; preds = %then
    %3 = load ptr, ptr %arr, align 8
    %4 = icmp eq ptr %3, null
    br i1 %4, label %success, label %fail, !dbg !14
  
  success:                                          ; preds = %then2
    %5 = tail call ptr @malloc(i64 32)
    store ptr %5, ptr %arr, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 4, ptr %sunkaddr, align 8
    br label %ifcont12
  
  fail:                                             ; preds = %then2
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 55, ptr @3), !dbg !14
    unreachable
  
  else:                                             ; preds = %then
    %6 = load ptr, ptr %arr, align 8
    %7 = icmp eq ptr %6, null
    %8 = xor i1 %7, true
    br i1 %8, label %success6, label %fail7, !dbg !15
  
  success6:                                         ; preds = %else
    %add = add i64 %1, 1
    %9 = tail call i64 @prelude_power_2_above_or_equal(i64 %1, i64 %add), !dbg !16
    %size = mul i64 %9, 8
    %10 = tail call ptr @realloc(ptr %6, i64 %size)
    store ptr %10, ptr %arr, align 8
    %sunkaddr16 = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 %9, ptr %sunkaddr16, align 8
    br label %ifcont12
  
  fail7:                                            ; preds = %else
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 59, ptr @3), !dbg !15
    unreachable
  
  else11:                                           ; preds = %entry
    %.pre = load ptr, ptr %arr, align 8
    br label %ifcont12
  
  ifcont12:                                         ; preds = %success, %success6, %else11
    %11 = phi ptr [ %.pre, %else11 ], [ %10, %success6 ], [ %5, %success ]
    %12 = getelementptr inbounds %foo, ptr %11, i64 %2
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %12, ptr align 8 %value, i64 8, i1 false)
    %add15 = add i64 %2, 1
    %sunkaddr17 = getelementptr inbounds i8, ptr %arr, i64 8
    store i64 %add15, ptr %sunkaddr17, align 8
    ret void
  }
  
  define void @schmu_arr_inside() !dbg !17 {
  entry:
    %0 = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 3, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 3, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr %0, align 8
    store %foo { i64 1 }, ptr %1, align 8
    %"1" = getelementptr %foo, ptr %1, i64 1
    store %foo { i64 2 }, ptr %"1", align 8
    %"2" = getelementptr %foo, ptr %1, i64 2
    store %foo { i64 3 }, ptr %"2", align 8
    call void @__array_push_a.foofoo(ptr %0, i64 12), !dbg !19
    call void @__free_a.foo(ptr %0)
    ret void
  }
  
  define void @schmu_arr_of_records(ptr noalias %0) !dbg !20 {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 2, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 2, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 64)
    store ptr %1, ptr %0, align 8
    tail call void @schmu_record_of_arrs(ptr %1), !dbg !21
    %"1" = getelementptr %container, ptr %1, i64 1
    tail call void @schmu_record_of_arrs(ptr %"1"), !dbg !22
    ret void
  }
  
  define void @schmu_inner_parent_scope() !dbg !23 {
  entry:
    %ret = alloca { ptr, i64, i64 }, align 8
    call void @schmu_make_arr(ptr %ret), !dbg !24
    call void @__free_a.foo(ptr %ret)
    ret void
  }
  
  define void @schmu_make_arr(ptr noalias %0) !dbg !25 {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 3, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 3, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 8 @schmu_x__2, i64 8, i1 false)
    %"1" = getelementptr %foo, ptr %1, i64 1
    store %foo { i64 2 }, ptr %"1", align 8
    %"2" = getelementptr %foo, ptr %1, i64 2
    store %foo { i64 3 }, ptr %"2", align 8
    ret void
  }
  
  define void @schmu_make_nested_arr(ptr noalias %0) !dbg !26 {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 2, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 2, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 48)
    store ptr %1, ptr %0, align 8
    %len1 = getelementptr inbounds { ptr, i64, i64 }, ptr %1, i32 0, i32 1
    store i64 2, ptr %len1, align 8
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %1, i32 0, i32 2
    store i64 2, ptr %cap2, align 8
    %2 = tail call ptr @malloc(i64 16)
    store ptr %2, ptr %1, align 8
    store i64 0, ptr %2, align 8
    %"1" = getelementptr i64, ptr %2, i64 1
    store i64 1, ptr %"1", align 8
    %"15" = getelementptr { ptr, i64, i64 }, ptr %1, i64 1
    %len6 = getelementptr inbounds { ptr, i64, i64 }, ptr %"15", i32 0, i32 1
    store i64 2, ptr %len6, align 8
    %cap7 = getelementptr inbounds { ptr, i64, i64 }, ptr %"15", i32 0, i32 2
    store i64 2, ptr %cap7, align 8
    %3 = tail call ptr @malloc(i64 16)
    store ptr %3, ptr %"15", align 8
    store i64 2, ptr %3, align 8
    %"110" = getelementptr i64, ptr %3, i64 1
    store i64 3, ptr %"110", align 8
    ret void
  }
  
  define void @schmu_nest_allocs(ptr noalias %0) !dbg !27 {
  entry:
    tail call void @schmu_make_nested_arr(ptr %0), !dbg !28
    ret void
  }
  
  define void @schmu_nest_fns(ptr noalias %0) !dbg !29 {
  entry:
    tail call void @schmu_make_arr(ptr %0), !dbg !30
    ret void
  }
  
  define void @schmu_nest_local() !dbg !31 {
  entry:
    %arr = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 2, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 2, ptr %cap, align 8
    %0 = tail call ptr @malloc(i64 48)
    store ptr %0, ptr %arr, align 8
    %len1 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 2, ptr %len1, align 8
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 2, ptr %cap2, align 8
    %1 = tail call ptr @malloc(i64 16)
    store ptr %1, ptr %0, align 8
    store i64 0, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %"1", align 8
    %"15" = getelementptr { ptr, i64, i64 }, ptr %0, i64 1
    %len6 = getelementptr inbounds { ptr, i64, i64 }, ptr %"15", i32 0, i32 1
    store i64 2, ptr %len6, align 8
    %cap7 = getelementptr inbounds { ptr, i64, i64 }, ptr %"15", i32 0, i32 2
    store i64 2, ptr %cap7, align 8
    %2 = tail call ptr @malloc(i64 16)
    store ptr %2, ptr %"15", align 8
    store i64 2, ptr %2, align 8
    %"110" = getelementptr i64, ptr %2, i64 1
    store i64 3, ptr %"110", align 8
    call void @__free_a.a.l(ptr %arr)
    ret void
  }
  
  define void @schmu_record_of_arrs(ptr noalias %0) !dbg !32 {
  entry:
    %arr = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 2, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 2, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 16)
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %"1", align 8
    store i64 1, ptr %0, align 8
    %arr1 = getelementptr inbounds %container, ptr %0, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %arr1, ptr align 8 %arr, i64 24, i1 false)
    ret void
  }
  
  declare void @prelude_assert_fail(ptr %0, ptr %1, i32 %2, ptr %3)
  
  declare ptr @malloc(i64 %0)
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_a.foo(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.a.l(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %child ], [ 0, %entry ]
    %1 = phi i64 [ %4, %child ], [ 0, %entry ]
    %2 = icmp slt i64 %1, %size
    br i1 %2, label %child, label %cont
  
  child:                                            ; preds = %rec
    %3 = load ptr, ptr %0, align 8
    %scevgep = getelementptr i8, ptr %3, i64 %lsr.iv
    tail call void @__free_a.l(ptr %scevgep)
    %4 = add i64 %1, 1
    store i64 %4, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
  
  cont:                                             ; preds = %rec
    %5 = load ptr, ptr %0, align 8
    tail call void @free(ptr %5)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !33 {
  entry:
    store i64 3, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr, i32 0, i32 1), align 8
    store i64 3, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 72)
    store ptr %0, ptr @schmu_arr, align 8
    %1 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 3, i64 -1 }, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %0)
    %"1" = getelementptr { ptr, i64, i64 }, ptr %0, i64 1
    %2 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @5, i64 5, i64 -1 }, ptr %2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %"1", ptr align 8 %2, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %"1")
    %"2" = getelementptr { ptr, i64, i64 }, ptr %0, i64 2
    %3 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @6, i64 5, i64 -1 }, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %"2", ptr align 8 %3, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %"2")
    store i64 3, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr__2, i32 0, i32 1), align 8
    store i64 3, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr__2, i32 0, i32 2), align 8
    %4 = tail call ptr @malloc(i64 24)
    store ptr %4, ptr @schmu_arr__2, align 8
    store %foo { i64 1 }, ptr %4, align 8
    %"12" = getelementptr %foo, ptr %4, i64 1
    store %foo { i64 2 }, ptr %"12", align 8
    %"23" = getelementptr %foo, ptr %4, i64 2
    store %foo { i64 3 }, ptr %"23", align 8
    tail call void @schmu_make_arr(ptr @schmu_arr__3), !dbg !34
    tail call void @schmu_arr_inside(), !dbg !35
    tail call void @schmu_inner_parent_scope(), !dbg !36
    tail call void @schmu_nest_fns(ptr @schmu_normal), !dbg !37
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_nested, i32 0, i32 2), align 8
    %5 = tail call ptr @malloc(i64 48)
    store ptr %5, ptr @schmu_nested, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %5, i32 0, i32 1
    store i64 2, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %5, i32 0, i32 2
    store i64 2, ptr %cap, align 8
    %6 = tail call ptr @malloc(i64 16)
    store ptr %6, ptr %5, align 8
    store i64 0, ptr %6, align 8
    %"16" = getelementptr i64, ptr %6, i64 1
    store i64 1, ptr %"16", align 8
    %"17" = getelementptr { ptr, i64, i64 }, ptr %5, i64 1
    %len8 = getelementptr inbounds { ptr, i64, i64 }, ptr %"17", i32 0, i32 1
    store i64 2, ptr %len8, align 8
    %cap9 = getelementptr inbounds { ptr, i64, i64 }, ptr %"17", i32 0, i32 2
    store i64 2, ptr %cap9, align 8
    %7 = tail call ptr @malloc(i64 16)
    store ptr %7, ptr %"17", align 8
    store i64 2, ptr %7, align 8
    %"112" = getelementptr i64, ptr %7, i64 1
    store i64 3, ptr %"112", align 8
    %arr = alloca { ptr, i64, i64 }, align 8
    %len13 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 2, ptr %len13, align 8
    %cap14 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 2, ptr %cap14, align 8
    %8 = tail call ptr @malloc(i64 16)
    store ptr %8, ptr %arr, align 8
    store i64 4, ptr %8, align 8
    %"117" = getelementptr i64, ptr %8, i64 1
    store i64 5, ptr %"117", align 8
    call void @__array_push_a.a.la.l(ptr @schmu_nested, ptr %arr), !dbg !38
    call void @schmu_make_nested_arr(ptr @schmu_nested__2), !dbg !39
    call void @schmu_nest_allocs(ptr @schmu_nested__3), !dbg !40
    call void @schmu_nest_local(), !dbg !41
    store i64 12, ptr @schmu_rec_of_arr, align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr getelementptr inbounds (%container, ptr @schmu_rec_of_arr, i32 0, i32 1), i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr getelementptr inbounds (%container, ptr @schmu_rec_of_arr, i32 0, i32 1), i32 0, i32 2), align 8
    %9 = call ptr @malloc(i64 16)
    store ptr %9, ptr getelementptr inbounds (%container, ptr @schmu_rec_of_arr, i32 0, i32 1), align 8
    store i64 1, ptr %9, align 8
    %"119" = getelementptr i64, ptr %9, i64 1
    store i64 2, ptr %"119", align 8
    call void @schmu_record_of_arrs(ptr @schmu_rec_of_arr__2), !dbg !42
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr_of_rec, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr_of_rec, i32 0, i32 2), align 8
    %10 = call ptr @malloc(i64 64)
    store ptr %10, ptr @schmu_arr_of_rec, align 8
    call void @schmu_record_of_arrs(ptr %10), !dbg !43
    %"121" = getelementptr %container, ptr %10, i64 1
    call void @schmu_record_of_arrs(ptr %"121"), !dbg !44
    call void @schmu_arr_of_records(ptr @schmu_arr_of_rec__2), !dbg !45
    call void @__free_a.container(ptr @schmu_arr_of_rec__2)
    call void @__free_a.container(ptr @schmu_arr_of_rec)
    call void @__free_container(ptr @schmu_rec_of_arr__2)
    call void @__free_container(ptr @schmu_rec_of_arr)
    call void @__free_a.a.l(ptr @schmu_nested__3)
    call void @__free_a.a.l(ptr @schmu_nested__2)
    call void @__free_a.a.l(ptr @schmu_nested)
    call void @__free_a.foo(ptr @schmu_normal)
    call void @__free_a.foo(ptr @schmu_arr__3)
    call void @__free_a.foo(ptr @schmu_arr__2)
    call void @__free_a.a.c(ptr @schmu_arr)
    ret i64 0
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
  
  define linkonce_odr void @__free_container(ptr %0) {
  entry:
    %1 = getelementptr inbounds %container, ptr %0, i32 0, i32 1
    tail call void @__free_a.l(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.container(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %child ], [ 0, %entry ]
    %1 = phi i64 [ %4, %child ], [ 0, %entry ]
    %2 = icmp slt i64 %1, %size
    br i1 %2, label %child, label %cont
  
  child:                                            ; preds = %rec
    %3 = load ptr, ptr %0, align 8
    %scevgep = getelementptr i8, ptr %3, i64 %lsr.iv
    tail call void @__free_container(ptr %scevgep)
    %4 = add i64 %1, 1
    store i64 %4, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 32
    br label %rec
  
  cont:                                             ; preds = %rec
    %5 = load ptr, ptr %0, align 8
    tail call void @free(ptr %5)
    ret void
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.a.c(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %child ], [ 0, %entry ]
    %1 = phi i64 [ %4, %child ], [ 0, %entry ]
    %2 = icmp slt i64 %1, %size
    br i1 %2, label %child, label %cont
  
  child:                                            ; preds = %rec
    %3 = load ptr, ptr %0, align 8
    %scevgep = getelementptr i8, ptr %3, i64 %lsr.iv
    tail call void @__free_a.c(ptr %scevgep)
    %4 = add i64 %1, 1
    store i64 %4, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
  
  cont:                                             ; preds = %rec
    %5 = load ptr, ptr %0, align 8
    tail call void @free(ptr %5)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu free_array.smu > /dev/null 2>&1
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./free_array

Free correctly when moving ifs with outer borrows
  $ schmu free_cond.smu && valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./free_cond

Free moved parameters
  $ schmu free_moved_param.smu && valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./free_moved_param

Don't free params if parts are passed in tail calls
  $ schmu free_param_parts.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./free_param_parts
  thing
  none

Functions in arrays
  $ schmu function_array.smu && valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./function_array

Global lets with expressions
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu global_let.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %option.t.a.l = type { i32, { ptr, i64, i64 } }
  %r.a.l = type { { ptr, i64, i64 } }
  
  @schmu_a = internal constant %option.t.a.l { i32 0, { ptr, i64, i64 } undef }
  @schmu_b = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_c = global i64 0, align 8
  
  define void @schmu_ret_none(ptr noalias %0) !dbg !2 {
  entry:
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 16 @schmu_a, i64 32, i1 false)
    ret void
  }
  
  define void @schmu_ret_rec(ptr noalias %0) !dbg !6 {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 3, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 3, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr %0, align 8
    store i64 10, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 20, ptr %"1", align 8
    %"2" = getelementptr i64, ptr %1, i64 2
    store i64 30, ptr %"2", align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    %ret = alloca %option.t.a.l, align 8
    call void @schmu_ret_none(ptr %ret), !dbg !8
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !9
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.t.a.l, ptr %ret, i32 0, i32 1
    br label %ifcont
  
  else:                                             ; preds = %entry
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_b, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_b, i32 0, i32 2), align 8
    %0 = call ptr @malloc(i64 16)
    store ptr %0, ptr @schmu_b, align 8
    store i64 1, ptr %0, align 8
    %"1" = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %"1", align 8
    call void @__free_option.t.a.l(ptr %ret)
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %data, %then ], [ @schmu_b, %else ]
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 1 %iftmp, i64 24, i1 false)
    %ret1 = alloca %r.a.l, align 8
    call void @schmu_ret_rec(ptr %ret1), !dbg !10
    %1 = load ptr, ptr %ret1, align 8
    %2 = getelementptr i64, ptr %1, i64 1
    %3 = load i64, ptr %2, align 8
    store i64 %3, ptr @schmu_c, align 8
    call void @__free_r.a.l(ptr %ret1)
    call void @__free_a.l(ptr @schmu_b)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_option.t.a.l(ptr %0) {
  entry:
    %index = load i32, ptr %0, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t.a.l, ptr %0, i32 0, i32 1
    tail call void @__free_a.l(ptr %data)
    ret void
  
  cont:                                             ; preds = %entry
    ret void
  }
  
  define linkonce_odr void @__free_r.a.l(ptr %0) {
  entry:
    tail call void @__free_a.l(ptr %0)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu global_let.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./global_let

Don't try to free string literals in ifs
  $ schmu incr_str_lit_ifs.smu && valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./incr_str_lit_ifs
  none
  none

`inner` here should not make `tmp` a const, otherwise could gen would fail
  $ schmu mutable_inner_let.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./mutable_inner_let

Incr refcounts correctly in ifs
  $ schmu rc_ifs.smu && valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./rc_ifs

Incr refcounts correctly for closed over returns
  $ schmu rc_linear_closed_return.smu && valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./rc_linear_closed_return

Regression test for issue #19
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu regression_issue_19.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %v3 = type { double, double, double }
  
  define void @schmu_v3_add(ptr noalias %0, ptr %lhs, ptr %rhs) !dbg !2 {
  entry:
    %1 = load double, ptr %rhs, align 8
    %2 = load double, ptr %lhs, align 8
    %add = fadd double %2, %1
    store double %add, ptr %0, align 8
    %y = getelementptr inbounds %v3, ptr %0, i32 0, i32 1
    %3 = getelementptr inbounds %v3, ptr %lhs, i32 0, i32 1
    %4 = getelementptr inbounds %v3, ptr %rhs, i32 0, i32 1
    %5 = load double, ptr %4, align 8
    %6 = load double, ptr %3, align 8
    %add1 = fadd double %6, %5
    store double %add1, ptr %y, align 8
    %z = getelementptr inbounds %v3, ptr %0, i32 0, i32 2
    %7 = getelementptr inbounds %v3, ptr %lhs, i32 0, i32 2
    %8 = getelementptr inbounds %v3, ptr %rhs, i32 0, i32 2
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
    %y = getelementptr inbounds %v3, ptr %0, i32 0, i32 1
    %2 = getelementptr inbounds %v3, ptr %v3, i32 0, i32 1
    %3 = load double, ptr %2, align 8
    %mul1 = fmul double %3, %factor
    store double %mul1, ptr %y, align 8
    %z = getelementptr inbounds %v3, ptr %0, i32 0, i32 2
    %4 = getelementptr inbounds %v3, ptr %v3, i32 0, i32 2
    %5 = load double, ptr %4, align 8
    %mul2 = fmul double %5, %factor
    store double %mul2, ptr %z, align 8
    ret void
  }
  
  define void @schmu_wrap(ptr noalias %0) !dbg !7 {
  entry:
    %boxconst = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, ptr %boxconst, align 8
    %ret = alloca %v3, align 8
    call void @schmu_v3_scale(ptr %ret, ptr %boxconst, double 1.500000e+00), !dbg !8
    %boxconst1 = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 2.000000e+00, double 3.000000e+00 }, ptr %boxconst1, align 8
    %ret2 = alloca %v3, align 8
    call void @schmu_v3_scale(ptr %ret2, ptr %boxconst1, double 1.500000e+00), !dbg !9
    call void @schmu_v3_add(ptr %0, ptr %ret, ptr %ret2), !dbg !10
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    %ret = alloca %v3, align 8
    call void @schmu_wrap(ptr %ret), !dbg !12
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu regression_issue_19.smu
  $ ./regression_issue_19

Tailcall loops
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu regression_issue_26.smu 2>&1 | grep -v !DI
  regression_issue_26.smu:25.9-15: warning: Unused binding nested
  
  25 | fun rec nested(a, b, c) {
               ^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.lfmt.formatter.t.u = type { i64, %fmt.formatter.t.u }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_stdout_missing_arg_msg = external global { ptr, i64, i64 }
  @fmt_stdout_too_many_arg_msg = external global { ptr, i64, i64 }
  @schmu_limit = constant i64 3
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @0 = private unnamed_addr constant [8 x i8] c"{}, {}\0A\00"
  @1 = private unnamed_addr constant [12 x i8] c"{}, {}, {}\0A\00"
  @2 = private unnamed_addr constant [1 x i8] zeroinitializer
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_println(ptr %0)
  
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
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret1, ptr %ret, ptr @fmt_stdout_missing_arg_msg), !dbg !24
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret1), !dbg !25
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_too_many_ru() !dbg !26 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !27
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret1, ptr %ret, ptr @fmt_stdout_too_many_arg_msg), !dbg !28
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret1), !dbg !29
    call void @abort()
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_print2__ll_ll(ptr %fmtstr, ptr %f0, i64 %v0, ptr %f1, i64 %v1) !dbg !30 {
  entry:
    %__fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull = alloca %closure, align 8
    store ptr @__fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, ptr %__fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, align 8
    %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull = alloca { ptr, ptr, %closure, %closure, i64, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %f12 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f12, ptr align 1 %f1, i64 16, i1 false)
    %v03 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 4
    store i64 %v0, ptr %v03, align 8
    %v14 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 5
    store i64 %v1, ptr %v14, align 8
    store ptr @__ctor_tp._fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull), !dbg !31
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
  
  define linkonce_odr void @__fmt_stdout_print3__ll_ll_ll(ptr %fmtstr, ptr %f0, i64 %v0, ptr %f1, i64 %v1, ptr %f2, i64 %v2) !dbg !35 {
  entry:
    %__fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll = alloca %closure, align 8
    store ptr @__fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, ptr %__fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, align 8
    %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll = alloca { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %f12 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f12, ptr align 1 %f1, i64 16, i1 false)
    %f23 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 4
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f23, ptr align 1 %f2, i64 16, i1 false)
    %v04 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 5
    store i64 %v0, ptr %v04, align 8
    %v15 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 6
    store i64 %v1, ptr %v15, align 8
    %v26 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 7
    store i64 %v2, ptr %v26, align 8
    store ptr @__ctor_tp._fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll), !dbg !36
    %0 = getelementptr inbounds %tp.lfmt.formatter.t.u, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 3
    br i1 %ne, label %then, label %else, !dbg !37
  
  then:                                             ; preds = %entry
    call void @__fmt_stdout_impl_fmt_fail_too_many_ru(), !dbg !38
    call void @__free_fmt.formatter.t.u(ptr %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %0), !dbg !39
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, ptr %str) !dbg !40 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !41
    %2 = tail call i64 @string_len(ptr %str), !dbg !42
    tail call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !43
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !45
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout3_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !46 {
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
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rfmt.formatter.t.u(ptr %0), !dbg !51
    tail call void @__free_fmt.formatter.t.u(ptr %fmter)
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout4_C_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !52 {
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
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rfmt.formatter.t.u(ptr %0), !dbg !59
    tail call void @__free_fmt.formatter.t.u(ptr %fmter)
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !61
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !62
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !63
    br i1 %lt, label %then4, label %ifcont, !dbg !63
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_nested(i64 %a, i64 %b) !dbg !64 {
  entry:
    %0 = alloca i64, align 8
    store i64 %a, ptr %0, align 8
    %1 = alloca i64, align 8
    store i64 %b, ptr %1, align 8
    %boxconst = alloca { ptr, i64, i64 }, align 8
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
    store { ptr, i64, i64 } { ptr @0, i64 7, i64 -1 }, ptr %boxconst, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    call void @__fmt_stdout_print2__ll_ll(ptr %boxconst, ptr %clstmp, i64 %.ph, ptr %clstmp4, i64 %2), !dbg !68
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
    %boxconst = alloca { ptr, i64, i64 }, align 8
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
    store { ptr, i64, i64 } { ptr @1, i64 11, i64 -1 }, ptr %boxconst, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp8, align 8
    %envptr10 = getelementptr inbounds %closure, ptr %clstmp8, i32 0, i32 1
    store ptr null, ptr %envptr10, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    call void @__fmt_stdout_print3__ll_ll_ll(ptr %boxconst, ptr %clstmp, i64 %.ph17.ph, ptr %clstmp8, i64 %.ph, ptr %clstmp11, i64 %4), !dbg !73
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
    %boxconst = alloca { ptr, i64, i64 }, align 8
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
    store { ptr, i64, i64 } { ptr @1, i64 11, i64 -1 }, ptr %boxconst, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp8, align 8
    %envptr10 = getelementptr inbounds %closure, ptr %clstmp8, i32 0, i32 1
    store ptr null, ptr %envptr10, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    call void @__fmt_stdout_print3__ll_ll_ll(ptr %boxconst, ptr %clstmp, i64 %.ph16.ph, ptr %clstmp8, i64 %.ph, ptr %clstmp11, i64 %3), !dbg !78
    %add14 = add i64 %3, 1
    store i64 %add14, ptr %2, align 8
    br label %rec
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
    tail call void @__free__up.clru(ptr %0)
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
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp._fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ull(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 64)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 64, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 2
    tail call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f0)
    %f1 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 3
    tail call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f1)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__free_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free__up.clru(ptr %0)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp._fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 2
    tail call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f0)
    %f1 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 3
    tail call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f1)
    %f2 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 4
    tail call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f2)
    ret ptr %1
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !79 {
  entry:
    tail call void @schmu_nested(i64 0, i64 0), !dbg !80
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @2, i64 0, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !81
    call void @schmu_nested__2(i64 0, i64 0, i64 0), !dbg !82
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu regression_issue_26.smu > /dev/null 2>&1
  $ ./regression_issue_26
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
  $ schmu -c --dump-llvm -c --target x86_64-unknown-linux-gnu regression_issue_30.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %v = type { double, double, double }
  
  @schmu_acc_force = internal constant double 1.000000e+02
  
  declare double @dot(ptr byval(%v) %0, ptr byval(%v) %1)
  
  declare void @norm(ptr noalias %0, ptr byval(%v) %1)
  
  declare void @scale(ptr noalias %0, ptr byval(%v) %1, double %2)
  
  declare i1 @maybe()
  
  define void @schmu_calc_acc(ptr noalias %0, ptr %vel) !dbg !2 {
  entry:
    %1 = tail call double @dot(ptr %vel, ptr %vel), !dbg !6
    %gt = fcmp ogt double %1, 1.000000e-01
    br i1 %gt, label %then, label %else, !dbg !6
  
  then:                                             ; preds = %entry
    %ret = alloca %v, align 8
    call void @norm(ptr %ret, ptr %vel), !dbg !7
    br label %ifcont
  
  else:                                             ; preds = %entry
    %2 = alloca %v, align 8
    store %v { double 1.000000e+00, double 0.000000e+00, double 0.000000e+00 }, ptr %2, align 8
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
  
  !5 = !{}

Ensure global are loadad correctly when passed to functions
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu regression_load_global.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %bar = type { double, double, i64, double, double, float }
  
  @schmu_height = constant i64 720
  @schmu_world = global %bar zeroinitializer, align 8
  
  define linkonce_odr void @__schmu_get_seg_bar(ptr %bar) !dbg !2 {
  entry:
    ret void
  }
  
  define void @schmu_wrap_seg() !dbg !6 {
  entry:
    tail call void @__schmu_get_seg_bar(ptr @schmu_world), !dbg !7
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !8 {
  entry:
    store double 0.000000e+00, ptr @schmu_world, align 8
    store double 1.280000e+03, ptr getelementptr inbounds (%bar, ptr @schmu_world, i32 0, i32 1), align 8
    store i64 10, ptr getelementptr inbounds (%bar, ptr @schmu_world, i32 0, i32 2), align 8
    store double 1.000000e-01, ptr getelementptr inbounds (%bar, ptr @schmu_world, i32 0, i32 3), align 8
    store double 5.400000e+02, ptr getelementptr inbounds (%bar, ptr @schmu_world, i32 0, i32 4), align 8
    store float 5.000000e+00, ptr getelementptr inbounds (%bar, ptr @schmu_world, i32 0, i32 5), align 4
    tail call void @schmu_wrap_seg(), !dbg !9
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}

Return closures
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu return_closure.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.t.u = type { %closure }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_f = global %closure zeroinitializer, align 8
  @schmu_f2 = global %closure zeroinitializer, align 8
  @schmu_f__2 = global %closure zeroinitializer, align 8
  
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
  
  define linkonce_odr void @__fmt_stdout_println__ll(ptr %fmt, i64 %value) !dbg !22 {
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !31
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !33
    br i1 %lt, label %then4, label %ifcont, !dbg !33
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
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
    store ptr @__ctor_tp.l, ptr %1, align 8
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
    store ptr @__ctor_tp.l, ptr %1, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %1, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %1, ptr %envptr, align 8
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
    tail call void @__free__up.clru(ptr %0)
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
  
  define linkonce_odr ptr @__ctor_tp.l(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 24)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    ret ptr %1
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !37 {
  entry:
    tail call void @schmu_ret_fn(ptr @schmu_f, i64 13), !dbg !38
    tail call void @schmu_ret_fn(ptr @schmu_f2, i64 35), !dbg !39
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %loadtmp = load ptr, ptr @schmu_f, align 8
    %loadtmp1 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %loadtmp(i64 12, ptr %loadtmp1), !dbg !40
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %0), !dbg !41
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %loadtmp5 = load ptr, ptr @schmu_f2, align 8
    %loadtmp6 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f2, i32 0, i32 1), align 8
    %1 = call i64 %loadtmp5(i64 12, ptr %loadtmp6), !dbg !42
    call void @__fmt_stdout_println__ll(ptr %clstmp2, i64 %1), !dbg !43
    call void @schmu_ret_lambda(ptr @schmu_f__2, i64 134), !dbg !44
    %clstmp7 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %loadtmp10 = load ptr, ptr @schmu_f__2, align 8
    %loadtmp11 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f__2, i32 0, i32 1), align 8
    %2 = call i64 %loadtmp10(i64 12, ptr %loadtmp11), !dbg !45
    call void @__fmt_stdout_println__ll(ptr %clstmp7, i64 %2), !dbg !46
    call void @__free__lrl(ptr @schmu_f__2)
    call void @__free__lrl(ptr @schmu_f2)
    call void @__free__lrl(ptr @schmu_f)
    ret i64 0
  }
  
  define linkonce_odr void @__free__lrl(ptr %0) {
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
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu return_closure.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./return_closure
  25
  47
  146

Return nonclosure functions
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu return_fn.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.t.u = type { %closure }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_f = global %closure zeroinitializer, align 8
  @schmu_f__2 = global %closure zeroinitializer, align 8
  
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
  
  define linkonce_odr void @__fmt_stdout_println__ll(ptr %fmt, i64 %value) !dbg !22 {
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !31
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !33
    br i1 %lt, label %then4, label %ifcont, !dbg !33
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
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
    tail call void @__free__up.clru(ptr %0)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !37 {
  entry:
    tail call void @schmu_ret_fn(ptr @schmu_f), !dbg !38
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %loadtmp = load ptr, ptr @schmu_f, align 8
    %loadtmp1 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %loadtmp(i64 12, ptr %loadtmp1), !dbg !39
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %0), !dbg !40
    call void @schmu_ret_named(ptr @schmu_f__2), !dbg !41
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %loadtmp5 = load ptr, ptr @schmu_f__2, align 8
    %loadtmp6 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f__2, i32 0, i32 1), align 8
    %1 = call i64 %loadtmp5(i64 12, ptr %loadtmp6), !dbg !42
    call void @__fmt_stdout_println__ll(ptr %clstmp2, i64 %1), !dbg !43
    call void @__free__lrl(ptr @schmu_f__2)
    call void @__free__lrl(ptr @schmu_f)
    ret i64 0
  }
  
  define linkonce_odr void @__free__lrl(ptr %0) {
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
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu return_fn.smu
  $ ./return_fn
  24
  25

Take/use not all allocations of a record in tailrec calls
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu -c --target x86_64-unknown-linux-gnu take_partial_alloc.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %view = type { { ptr, i64, i64 }, i64, i64 }
  %fmt.formatter.t.a.c = type { %closure, { ptr, i64, i64 } }
  %closure = type { ptr, ptr }
  %parse_result.view = type { i32, %success.view }
  %success.view = type { %view, %view }
  %parse_result.l = type { i32, %success.l }
  %success.l = type { %view, i64 }
  
  @schmu_s = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_inp = global %view zeroinitializer, align 8
  @0 = private unnamed_addr constant [2 x i8] c" \00"
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare i1 @prelude_char_equal(i8 %0, i8 %1)
  
  declare void @fmt_fmt_str_create(ptr noalias %0)
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.a.cra.c(ptr noalias %0, ptr %fm) !dbg !2 {
  entry:
    %1 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %fm, i32 0, i32 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %1, i64 24, i1 false)
    tail call void @__free_except1_fmt.formatter.t.a.c(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !6 {
  entry:
    %1 = alloca %fmt.formatter.t.a.c, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 40, i1 false)
    %2 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %1, i32 0, i32 1
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    call void %loadtmp(ptr %2, ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !7
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 40, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %p, ptr %str) !dbg !8 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !9
    %2 = tail call i64 @string_len(ptr %str), !dbg !10
    tail call void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !11
    ret void
  }
  
  define linkonce_odr void @__fmt_str_print__a.ca.c(ptr noalias %0, ptr %fmt, ptr %value) !dbg !12 {
  entry:
    %ret = alloca %fmt.formatter.t.a.c, align 8
    call void @fmt_fmt_str_create(ptr %ret), !dbg !13
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.a.c, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, ptr %value, ptr %loadtmp1), !dbg !14
    call void @__fmt_formatter_extract_fmt.formatter.t.a.cra.c(ptr %0, ptr %ret2), !dbg !15
    ret void
  }
  
  define void @schmu_aux(ptr noalias %0, ptr %rem, i64 %cnt) !dbg !16 {
  entry:
    %1 = alloca %view, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %rem, i64 40, i1 false)
    %2 = alloca i1, align 1
    store i1 false, ptr %2, align 1
    %3 = alloca i64, align 8
    store i64 %cnt, ptr %3, align 8
    %ret = alloca %parse_result.view, align 8
    br label %rec
  
  rec:                                              ; preds = %cont, %entry
    %4 = phi i1 [ true, %cont ], [ false, %entry ]
    %5 = phi i64 [ %add, %cont ], [ %cnt, %entry ]
    call void @schmu_ch(ptr %ret, ptr %1), !dbg !18
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else, !dbg !19
  
  then:                                             ; preds = %rec
    %data = getelementptr inbounds %parse_result.view, ptr %ret, i32 0, i32 1
    %add = add i64 %5, 1
    call void @__free_except0_success.view(ptr %data)
    br i1 %4, label %call_decr, label %cookie
  
  call_decr:                                        ; preds = %then
    call void @__free_view(ptr %1)
    br label %cont
  
  cookie:                                           ; preds = %then
    store i1 true, ptr %2, align 1
    br label %cont
  
  cont:                                             ; preds = %cookie, %call_decr
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %data, i64 40, i1 false)
    store i64 %add, ptr %3, align 8
    br label %rec
  
  else:                                             ; preds = %rec
    %data1 = getelementptr inbounds %parse_result.view, ptr %ret, i32 0, i32 1
    store i32 0, ptr %0, align 4
    %data3 = getelementptr inbounds %parse_result.l, ptr %0, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data3, ptr align 8 %1, i64 40, i1 false)
    call void @__copy_view(ptr %data3)
    %mtch = getelementptr inbounds %success.l, ptr %data3, i32 0, i32 1
    store i64 %5, ptr %mtch, align 8
    call void @__free_parse_result.view(ptr %ret)
    br i1 %4, label %call_decr5, label %cookie6
  
  call_decr5:                                       ; preds = %else
    call void @__free_view(ptr %1)
    br label %cont7
  
  cookie6:                                          ; preds = %else
    store i1 true, ptr %2, align 1
    br label %cont7
  
  cont7:                                            ; preds = %cookie6, %call_decr5
    ret void
  }
  
  define void @schmu_ch(ptr noalias %0, ptr %buf) !dbg !20 {
  entry:
    %1 = getelementptr inbounds %view, ptr %buf, i32 0, i32 1
    %2 = load i64, ptr %1, align 8
    %3 = tail call i8 @string_get(ptr %buf, i64 %2), !dbg !21
    %4 = tail call i1 @prelude_char_equal(i8 %3, i8 32), !dbg !22
    br i1 %4, label %then, label %else, !dbg !22
  
  then:                                             ; preds = %entry
    store i32 0, ptr %0, align 4
    %data = getelementptr inbounds %parse_result.view, ptr %0, i32 0, i32 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data, ptr align 1 %buf, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %data)
    %start = getelementptr inbounds %view, ptr %data, i32 0, i32 1
    %sunkaddr = getelementptr inbounds i8, ptr %buf, i64 24
    %5 = load i64, ptr %sunkaddr, align 8
    %add = add i64 %5, 1
    store i64 %add, ptr %start, align 8
    %len = getelementptr inbounds %view, ptr %data, i32 0, i32 2
    %6 = getelementptr inbounds %view, ptr %buf, i32 0, i32 2
    %7 = load i64, ptr %6, align 8
    %sub = sub i64 %7, 1
    store i64 %sub, ptr %len, align 8
    %mtch = getelementptr inbounds %success.view, ptr %data, i32 0, i32 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %mtch, ptr align 1 %buf, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %mtch)
    %start3 = getelementptr inbounds %view, ptr %mtch, i32 0, i32 1
    %8 = load i64, ptr %sunkaddr, align 8
    store i64 %8, ptr %start3, align 8
    %len4 = getelementptr inbounds %view, ptr %mtch, i32 0, i32 2
    store i64 1, ptr %len4, align 8
    ret void
  
  else:                                             ; preds = %entry
    store i32 1, ptr %0, align 4
    %data6 = getelementptr inbounds %parse_result.view, ptr %0, i32 0, i32 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data6, ptr align 1 %buf, i64 40, i1 false)
    tail call void @__copy_view(ptr %data6)
    ret void
  }
  
  define void @schmu_many_count(ptr noalias %0, ptr %buf) !dbg !23 {
  entry:
    tail call void @schmu_aux(ptr %0, ptr %buf, i64 0), !dbg !24
    ret void
  }
  
  define void @schmu_view_of_string(ptr noalias %0, ptr %str) !dbg !25 {
  entry:
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %str, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %0)
    %start = getelementptr inbounds %view, ptr %0, i32 0, i32 1
    store i64 0, ptr %start, align 8
    %len = getelementptr inbounds %view, ptr %0, i32 0, i32 2
    %1 = tail call i64 @string_len(ptr %str), !dbg !26
    store i64 %1, ptr %len, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free__a.cp.clru(ptr %0) {
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
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.a.c(ptr %0) {
  entry:
    tail call void @__free__a.cp.clru(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_view(ptr %0) {
  entry:
    tail call void @__free_a.c(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_except0_success.view(ptr %0) {
  entry:
    %1 = getelementptr inbounds %success.view, ptr %0, i32 0, i32 1
    tail call void @__free_view(ptr %1)
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
  
  define linkonce_odr void @__copy_view(ptr %0) {
  entry:
    tail call void @__copy_a.c(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_success.view(ptr %0) {
  entry:
    tail call void @__free_view(ptr %0)
    %1 = getelementptr inbounds %success.view, ptr %0, i32 0, i32 1
    tail call void @__free_view(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_parse_result.view(ptr %0) {
  entry:
    %index = load i32, ptr %0, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse_result.view, ptr %0, i32 0, i32 1
    tail call void @__free_success.view(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    %2 = icmp eq i32 %index, 1
    br i1 %2, label %match1, label %cont2
  
  match1:                                           ; preds = %cont
    %data3 = getelementptr inbounds %parse_result.view, ptr %0, i32 0, i32 1
    tail call void @__free_view(ptr %data3)
    ret void
  
  cont2:                                            ; preds = %cont
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !27 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_str_fmt.formatter.t.a.crfmt.formatter.t.a.c, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 1, i64 -1 }, ptr %boxconst, align 8
    call void @__fmt_str_print__a.ca.c(ptr @schmu_s, ptr %clstmp, ptr %boxconst), !dbg !28
    call void @schmu_view_of_string(ptr @schmu_inp, ptr @schmu_s), !dbg !29
    %ret = alloca %parse_result.l, align 8
    call void @schmu_many_count(ptr %ret, ptr @schmu_inp), !dbg !30
    call void @__free_parse_result.l(ptr %ret)
    call void @__free_view(ptr @schmu_inp)
    call void @__free_a.c(ptr @schmu_s)
    ret i64 0
  }
  
  define linkonce_odr void @__free_success.l(ptr %0) {
  entry:
    tail call void @__free_view(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_parse_result.l(ptr %0) {
  entry:
    %index = load i32, ptr %0, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse_result.l, ptr %0, i32 0, i32 1
    tail call void @__free_success.l(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    %2 = icmp eq i32 %index, 1
    br i1 %2, label %match1, label %cont2
  
  match1:                                           ; preds = %cont
    %data3 = getelementptr inbounds %parse_result.l, ptr %0, i32 0, i32 1
    tail call void @__free_view(ptr %data3)
    ret void
  
  cont2:                                            ; preds = %cont
    ret void
  }
  
  declare void @free(ptr %0)
  
  declare ptr @malloc(i64 %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu take_partial_alloc.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./take_partial_alloc

Take/use not all allocations of a record in tailrec calls, different order for pattern matches
  $ schmu take_partial_alloc_reorder.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./take_partial_alloc_reorder

Mutable variables in upward closures
  $ schmu upward_mut.smu && valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./upward_mut
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
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./partial_rc

Leak builtin
  $ schmu leak.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./leak
  thing

Fix double free
  $ schmu match_partial_move.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./match_partial_move

Fix leak after fix above
  $ schmu match_partial_move_followup_leak.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./match_partial_move_followup_leak

Fix parent reentering
  $ schmu reenter_parent.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./reenter_parent

Fix partial parent setting
  $ schmu set_partial_parent.smu
  set_partial_parent.smu:4.18-29: warning: Constructor is never used to build values: Resolv_deps
  
  4 | type key_state = Resolv_deps | Building(building) | Built(built)
                       ^^^^^^^^^^^
  
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./set_partial_parent

Correctly track partial moves in record expressions
  $ schmu partial_move_in_record.smu
  partial_move_in_record.smu:4.26-32: warning: Unused constructor: Module
  
  4 | type rule = Executable | Module
                               ^^^^^^
  
  partial_move_in_record.smu:8.45-53: warning: Constructor is never used to build values: Building
  
  8 | type key_state = Resolv_deps(resolv_deps) | Building(building) | Built(built)
                                                  ^^^^^^^^
  
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./partial_move_in_record

Mutable bindings cannot be const
  $ schmu mut_nonconst.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./mut_nonconst
