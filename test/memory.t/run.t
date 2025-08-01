Drop last element
  $ schmu --dump-llvm array_drop_back.smu 2>&1 | grep -v !DI && valgrind -q --leak-check=yes --show-reachable=yes ./array_drop_back
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.t.a.l = type { i32, ptr }
  %fmt.formatter.t.u = type { %closure }
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
  
  define linkonce_odr { i32, i64 } @__array_pop_back_a.a.lroption.t.a.l(ptr noalias %arr) !dbg !7 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, 0
    br i1 %eq, label %then, label %else, !dbg !8
  
  then:                                             ; preds = %entry
    %t = alloca %option.t.a.l, align 8
    store %option.t.a.l { i32 0, ptr undef }, ptr %t, align 8
    br label %ifcont
  
  else:                                             ; preds = %entry
    %t1 = alloca %option.t.a.l, align 8
    store i32 1, ptr %t1, align 4
    %data = getelementptr inbounds %option.t.a.l, ptr %t1, i32 0, i32 1
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !24 {
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
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %6 = load ptr, ptr @schmu_nested, align 8
    %7 = load i64, ptr %6, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %7), !dbg !36
    %ret = alloca %option.t.a.l, align 8
    %8 = call { i32, i64 } @__array_pop_back_a.a.lroption.t.a.l(ptr @schmu_nested), !dbg !37
    store { i32, i64 } %8, ptr %ret, align 8
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont, !dbg !38
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.t.a.l, ptr %ret, i32 0, i32 1
    call void @string_println(ptr @0), !dbg !39
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %clstmp9 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp9, align 8
    %envptr11 = getelementptr inbounds %closure, ptr %clstmp9, i32 0, i32 1
    store ptr null, ptr %envptr11, align 8
    %9 = load ptr, ptr @schmu_nested, align 8
    %10 = load i64, ptr %9, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp9, i64 %10), !dbg !40
    %ret13 = alloca %option.t.a.l, align 8
    %11 = call { i32, i64 } @__array_pop_back_a.a.lroption.t.a.l(ptr @schmu_nested), !dbg !41
    store { i32, i64 } %11, ptr %ret13, align 8
    %clstmp14 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp14, align 8
    %envptr16 = getelementptr inbounds %closure, ptr %clstmp14, i32 0, i32 1
    store ptr null, ptr %envptr16, align 8
    %12 = load ptr, ptr @schmu_nested, align 8
    %13 = load i64, ptr %12, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp14, i64 %13), !dbg !42
    %ret18 = alloca %option.t.a.l, align 8
    %14 = call { i32, i64 } @__array_pop_back_a.a.lroption.t.a.l(ptr @schmu_nested), !dbg !43
    store { i32, i64 } %14, ptr %ret18, align 8
    %index20 = load i32, ptr %ret18, align 4
    %eq21 = icmp eq i32 %index20, 1
    br i1 %eq21, label %then22, label %else24, !dbg !44
  
  then22:                                           ; preds = %ifcont
    %data23 = getelementptr inbounds %option.t.a.l, ptr %ret18, i32 0, i32 1
    br label %ifcont25
  
  else24:                                           ; preds = %ifcont
    call void @string_println(ptr @1), !dbg !45
    br label %ifcont25
  
  ifcont25:                                         ; preds = %else24, %then22
    %clstmp26 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp26, align 8
    %envptr28 = getelementptr inbounds %closure, ptr %clstmp26, i32 0, i32 1
    store ptr null, ptr %envptr28, align 8
    %15 = load ptr, ptr @schmu_nested, align 8
    %16 = load i64, ptr %15, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp26, i64 %16), !dbg !46
    call void @__free_option.t.a.l(ptr %ret18)
    call void @__free_option.t.a.l(ptr %ret13)
    call void @__free_option.t.a.l(ptr %ret)
    call void @__free_a.a.l(ptr @schmu_nested)
    ret i64 0
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
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  2
  some
  1
  0
  none
  0

Array push
  $ schmu --dump-llvm array_push.smu 2>&1 | grep -v !DI && valgrind -q --leak-check=yes --show-reachable=yes ./array_push
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
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
  
  define linkonce_odr void @__array_push_a.ll(ptr noalias %arr, i64 %value) !dbg !10 {
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
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !13 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !15
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %ret), !dbg !16
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %fm) !dbg !17 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !18 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !19
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !20 {
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
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !22
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
    store ptr @__ctor_tp.A64.cl, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !24
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !25
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i64 %i) !dbg !26 {
  entry:
    tail call void @__fmt_int_base_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !27
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !28 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !29
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !30
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !31
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !33
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
    call void @__copy_a.l(ptr %3)
    call void @__array_push_a.ll(ptr %0, i64 30), !dbg !40
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %4 = load ptr, ptr %0, align 8
    %5 = load i64, ptr %4, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %5), !dbg !41
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %6 = load ptr, ptr %3, align 8
    %7 = load i64, ptr %6, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 %7), !dbg !42
    call void @__free_a.l(ptr %3)
    call void @__free_a.l(ptr %0)
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
    tail call void @__copy_a.l(ptr @schmu_b)
    tail call void @__array_push_a.ll(ptr @schmu_a, i64 30), !dbg !44
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %2 = load ptr, ptr @schmu_a, align 8
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %3), !dbg !45
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %4 = load ptr, ptr @schmu_b, align 8
    %5 = load i64, ptr %4, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp1, i64 %5), !dbg !46
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
    call void @__copy_a.l(ptr %14)
    %15 = load ptr, ptr %14, align 8
    call void @__array_push_a.a.la.l(ptr @schmu_nested, ptr %15), !dbg !48
    %16 = load ptr, ptr @schmu_nested, align 8
    %17 = getelementptr i8, ptr %16, i64 16
    %18 = getelementptr ptr, ptr %17, i64 1
    %19 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %19, ptr align 8 @schmu_a__2, i64 8, i1 false)
    call void @__copy_a.l(ptr %19)
    call void @__free_a.l(ptr %18)
    %20 = load ptr, ptr %19, align 8
    store ptr %20, ptr %18, align 8
    %21 = load ptr, ptr @schmu_nested, align 8
    %22 = getelementptr i8, ptr %21, i64 16
    %23 = getelementptr ptr, ptr %22, i64 1
    %24 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %24, ptr align 8 @schmu_a__2, i64 8, i1 false)
    call void @__copy_a.l(ptr %24)
    call void @__free_a.l(ptr %23)
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
    call void @__array_push_a.a.la.l(ptr @schmu_nested, ptr %26), !dbg !49
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
    call void @__free_a.l(ptr %30)
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
    call void @__free_a.l(ptr %35)
    store ptr %36, ptr %35, align 8
    call void @__free_a.l(ptr @schmu_a__2)
    call void @__free_a.a.l(ptr @schmu_nested)
    call void @__free_a.l(ptr @schmu_b)
    call void @__free_a.l(ptr @schmu_a)
    ret i64 0
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
  
  !5 = !{}
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
  $ schmu --dump-llvm closure_monomorph.smu 2>&1 | grep -v !DI && ./closure_monomorph
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.t.u = type { %closure }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_arr = global ptr null, align 8
  @schmu_arr__2 = global ptr null, align 8
  
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
  
  define linkonce_odr i1 @__array_inner__2_Ca.larray_inner__2_lrb(i64 %i, ptr %0) !dbg !7 {
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
  
  define linkonce_odr i1 @__array_iter_a.larray_iter_l(ptr %arr, ptr %cont) !dbg !10 {
  entry:
    %__array_inner__2_Ca.larray_inner__2_lrb = alloca %closure, align 8
    store ptr @__array_inner__2_Ca.larray_inner__2_lrb, ptr %__array_inner__2_Ca.larray_inner__2_lrb, align 8
    %clsr___array_inner__2_Ca.larray_inner__2_lrb = alloca { ptr, ptr, ptr, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Ca.larray_inner__2_lrb, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cont2 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Ca.larray_inner__2_lrb, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cont2, ptr align 1 %cont, i64 16, i1 false)
    store ptr @__ctor_tp.a.l_lrb, ptr %clsr___array_inner__2_Ca.larray_inner__2_lrb, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Ca.larray_inner__2_lrb, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__array_inner__2_Ca.larray_inner__2_lrb, i32 0, i32 1
    store ptr %clsr___array_inner__2_Ca.larray_inner__2_lrb, ptr %envptr, align 8
    %0 = call i1 @__array_inner__2_Ca.larray_inner__2_lrb(i64 0, ptr %clsr___array_inner__2_Ca.larray_inner__2_lrb), !dbg !11
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !29 {
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
  
  define linkonce_odr i1 @__fun_iter5_lC__fun_iter5_lru(i64 %x, ptr %0) !dbg !35 {
  entry:
    %f = getelementptr inbounds { ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(i64 %x, ptr %loadtmp1), !dbg !37
    ret i1 true
  }
  
  define linkonce_odr void @__fun_schmu0_Ca.l__fun_schmu0_llrlll(i64 %j, ptr %0) !dbg !38 {
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
    %0 = load ptr, ptr @schmu_arr, align 8
    %1 = tail call i1 @__array_iter_a.larray_iter_l(ptr %0, ptr %__curry0), !dbg !44
    ret i1 %1
  }
  
  define void @__fun_schmu3(i64 %i) !dbg !45 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %i), !dbg !46
    ret void
  }
  
  define linkonce_odr void @__fun_schmu4_Ca.l__fun_schmu4_llrlll(i64 %j, ptr %0) !dbg !47 {
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
    %0 = load ptr, ptr @schmu_arr__2, align 8
    %1 = tail call i1 @__array_iter_a.larray_iter_l(ptr %0, ptr %__curry0), !dbg !52
    ret i1 %1
  }
  
  define void @__fun_schmu7(i64 %i) !dbg !53 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %i), !dbg !54
    ret void
  }
  
  define linkonce_odr void @__iter_iter_iter_iter_iter_iter_liter_iter_l(ptr %it, ptr %f) !dbg !55 {
  entry:
    %__fun_iter5_lC__fun_iter5_lru = alloca %closure, align 8
    store ptr @__fun_iter5_lC__fun_iter5_lru, ptr %__fun_iter5_lC__fun_iter5_lru, align 8
    %clsr___fun_iter5_lC__fun_iter5_lru = alloca { ptr, ptr, %closure }, align 8
    %f1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___fun_iter5_lC__fun_iter5_lru, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f1, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_tp._lru, ptr %clsr___fun_iter5_lC__fun_iter5_lru, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___fun_iter5_lC__fun_iter5_lru, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_iter5_lC__fun_iter5_lru, i32 0, i32 1
    store ptr %clsr___fun_iter5_lC__fun_iter5_lru, ptr %envptr, align 8
    %loadtmp = load ptr, ptr %it, align 8
    %envptr2 = getelementptr inbounds %closure, ptr %it, i32 0, i32 1
    %loadtmp3 = load ptr, ptr %envptr2, align 8
    %0 = call i1 %loadtmp(ptr %__fun_iter5_lC__fun_iter5_lru, ptr %loadtmp3), !dbg !56
    ret void
  }
  
  define linkonce_odr i64 @__schmu_partition__2_a.lCschmu_partition__2_llrl(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !57 {
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
    %__fun_schmu4_Ca.l__fun_schmu4_llrlll = alloca %closure, align 8
    store ptr @__fun_schmu4_Ca.l__fun_schmu4_llrlll, ptr %__fun_schmu4_Ca.l__fun_schmu4_llrlll, align 8
    %clsr___fun_schmu4_Ca.l__fun_schmu4_llrlll = alloca { ptr, ptr, ptr, %closure, ptr, i64 }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l__fun_schmu4_llrlll, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cmp2 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l__fun_schmu4_llrlll, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp2, ptr align 1 %cmp, i64 16, i1 false)
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l__fun_schmu4_llrlll, i32 0, i32 4
    store ptr %6, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l__fun_schmu4_llrlll, i32 0, i32 5
    store i64 %5, ptr %pivot, align 8
    store ptr @__ctor_tp.a.l_llrlll, ptr %clsr___fun_schmu4_Ca.l__fun_schmu4_llrlll, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu4_Ca.l__fun_schmu4_llrlll, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu4_Ca.l__fun_schmu4_llrlll, i32 0, i32 1
    store ptr %clsr___fun_schmu4_Ca.l__fun_schmu4_llrlll, ptr %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, ptr %__fun_schmu4_Ca.l__fun_schmu4_llrlll), !dbg !58
    %7 = load i64, ptr %6, align 8
    %add = add i64 %7, 1
    call void @__array_swap_items_a.l(ptr %arr, i64 %add, i64 %hi), !dbg !59
    ret i64 %add
  }
  
  define linkonce_odr i64 @__schmu_partition_a.lCschmu_partition_llrl(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !60 {
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
    %__fun_schmu0_Ca.l__fun_schmu0_llrlll = alloca %closure, align 8
    store ptr @__fun_schmu0_Ca.l__fun_schmu0_llrlll, ptr %__fun_schmu0_Ca.l__fun_schmu0_llrlll, align 8
    %clsr___fun_schmu0_Ca.l__fun_schmu0_llrlll = alloca { ptr, ptr, ptr, %closure, ptr, i64 }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l__fun_schmu0_llrlll, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cmp2 = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l__fun_schmu0_llrlll, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp2, ptr align 1 %cmp, i64 16, i1 false)
    %i = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l__fun_schmu0_llrlll, i32 0, i32 4
    store ptr %6, ptr %i, align 8
    %pivot = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l__fun_schmu0_llrlll, i32 0, i32 5
    store i64 %5, ptr %pivot, align 8
    store ptr @__ctor_tp.a.l_llrlll, ptr %clsr___fun_schmu0_Ca.l__fun_schmu0_llrlll, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %clsr___fun_schmu0_Ca.l__fun_schmu0_llrlll, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_schmu0_Ca.l__fun_schmu0_llrlll, i32 0, i32 1
    store ptr %clsr___fun_schmu0_Ca.l__fun_schmu0_llrlll, ptr %envptr, align 8
    call void @prelude_iter_range(i64 %lo, i64 %hi, ptr %__fun_schmu0_Ca.l__fun_schmu0_llrlll), !dbg !61
    %7 = load i64, ptr %6, align 8
    %add = add i64 %7, 1
    call void @__array_swap_items_a.l(ptr %arr, i64 %add, i64 %hi), !dbg !62
    ret i64 %add
  }
  
  define linkonce_odr void @__schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !63 {
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
    tail call void @__schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl(ptr %arr, i64 %5, i64 %sub, ptr %0), !dbg !66
    %add = add i64 %7, 1
    store ptr %arr, ptr %1, align 8
    store i64 %add, ptr %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl(ptr noalias %arr, i64 %lo, i64 %hi, ptr %0) !dbg !67 {
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
    tail call void @__schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl(ptr %arr, i64 %5, i64 %sub, ptr %0), !dbg !70
    %add = add i64 %7, 1
    store ptr %arr, ptr %1, align 8
    store i64 %add, ptr %3, align 8
    br label %rec
  }
  
  define linkonce_odr void @__schmu_sort__2_a.lschmu_sort__2_ll(ptr noalias %arr, ptr %cmp) !dbg !71 {
  entry:
    %__schmu_partition__2_a.lCschmu_partition__2_llrl = alloca %closure, align 8
    store ptr @__schmu_partition__2_a.lCschmu_partition__2_llrl, ptr %__schmu_partition__2_a.lCschmu_partition__2_llrl, align 8
    %clsr___schmu_partition__2_a.lCschmu_partition__2_llrl = alloca { ptr, ptr, %closure }, align 8
    %cmp1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition__2_a.lCschmu_partition__2_llrl, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp1, ptr align 1 %cmp, i64 16, i1 false)
    store ptr @__ctor_tp._llrl, ptr %clsr___schmu_partition__2_a.lCschmu_partition__2_llrl, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition__2_a.lCschmu_partition__2_llrl, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__schmu_partition__2_a.lCschmu_partition__2_llrl, i32 0, i32 1
    store ptr %clsr___schmu_partition__2_a.lCschmu_partition__2_llrl, ptr %envptr, align 8
    %__schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl = alloca %closure, align 8
    store ptr @__schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl, ptr %__schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl, align 8
    %clsr___schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl = alloca { ptr, ptr, %closure }, align 8
    %__schmu_partition__2_a.lCschmu_partition__2_llrl3 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %__schmu_partition__2_a.lCschmu_partition__2_llrl3, ptr align 8 %__schmu_partition__2_a.lCschmu_partition__2_llrl, i64 16, i1 false)
    store ptr @__ctor_tp._a.lllrl, ptr %clsr___schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl, align 8
    %dtor5 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl, i32 0, i32 1
    store ptr null, ptr %dtor5, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %__schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl, i32 0, i32 1
    store ptr %clsr___schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl, ptr %envptr6, align 8
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %sub = sub i64 %1, 1
    call void @__schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl(ptr %arr, i64 0, i64 %sub, ptr %clsr___schmu_quicksort__2_a.lCschmu_quicksort__2_a.lllrlCschmu_quicksort__2_llrl), !dbg !72
    ret void
  }
  
  define linkonce_odr void @__schmu_sort_a.lschmu_sort_ll(ptr noalias %arr, ptr %cmp) !dbg !73 {
  entry:
    %__schmu_partition_a.lCschmu_partition_llrl = alloca %closure, align 8
    store ptr @__schmu_partition_a.lCschmu_partition_llrl, ptr %__schmu_partition_a.lCschmu_partition_llrl, align 8
    %clsr___schmu_partition_a.lCschmu_partition_llrl = alloca { ptr, ptr, %closure }, align 8
    %cmp1 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition_a.lCschmu_partition_llrl, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cmp1, ptr align 1 %cmp, i64 16, i1 false)
    store ptr @__ctor_tp._llrl, ptr %clsr___schmu_partition_a.lCschmu_partition_llrl, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_partition_a.lCschmu_partition_llrl, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__schmu_partition_a.lCschmu_partition_llrl, i32 0, i32 1
    store ptr %clsr___schmu_partition_a.lCschmu_partition_llrl, ptr %envptr, align 8
    %__schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl = alloca %closure, align 8
    store ptr @__schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl, ptr %__schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl, align 8
    %clsr___schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl = alloca { ptr, ptr, %closure }, align 8
    %__schmu_partition_a.lCschmu_partition_llrl3 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %__schmu_partition_a.lCschmu_partition_llrl3, ptr align 8 %__schmu_partition_a.lCschmu_partition_llrl, i64 16, i1 false)
    store ptr @__ctor_tp._a.lllrl, ptr %clsr___schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl, align 8
    %dtor5 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl, i32 0, i32 1
    store ptr null, ptr %dtor5, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %__schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl, i32 0, i32 1
    store ptr %clsr___schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl, ptr %envptr6, align 8
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %sub = sub i64 %1, 1
    call void @__schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl(ptr %arr, i64 0, i64 %sub, ptr %clsr___schmu_quicksort_a.lCschmu_quicksort_a.lllrlCschmu_quicksort_llrl), !dbg !74
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
  
  define linkonce_odr ptr @__ctor_tp.a.l_lrb(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy_a.l(ptr %arr)
    %cont = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 3
    call void @__copy__lrb(ptr %cont)
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
  
  define linkonce_odr void @__copy__lrb(ptr %0) {
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
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  define linkonce_odr ptr @__ctor_tp._lru(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 32)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %f = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy__lru(ptr %f)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__lru(ptr %0) {
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
  
  define linkonce_odr ptr @__ctor_tp.a.l_llrlll(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 56)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 56, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %1, i32 0, i32 2
    call void @__copy_a.l(ptr %arr)
    %cmp = getelementptr inbounds { ptr, ptr, ptr, %closure, ptr, i64 }, ptr %1, i32 0, i32 3
    call void @__copy__llrl(ptr %cmp)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__llrl(ptr %0) {
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
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp._llrl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 32)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %cmp = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy__llrl(ptr %cmp)
    ret ptr %1
  }
  
  define linkonce_odr ptr @__ctor_tp._a.lllrl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 32)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %__schmu_partition__2_a.lCschmu_partition__2_llrl = getelementptr inbounds { ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy__a.lllrl(ptr %__schmu_partition__2_a.lCschmu_partition__2_llrl)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__a.lllrl(ptr %0) {
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
    call void @__schmu_sort_a.lschmu_sort_ll(ptr @schmu_arr, ptr %clstmp), !dbg !80
    %clstmp1 = alloca %closure, align 8
    store ptr @__fun_schmu2, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %clstmp4 = alloca %closure, align 8
    store ptr @__fun_schmu3, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    call void @__iter_iter_iter_iter_iter_iter_liter_iter_l(ptr %clstmp1, ptr %clstmp4), !dbg !81
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
    call void @__schmu_sort__2_a.lschmu_sort__2_ll(ptr @schmu_arr__2, ptr %clstmp15), !dbg !82
    %clstmp18 = alloca %closure, align 8
    store ptr @__fun_schmu6, ptr %clstmp18, align 8
    %envptr20 = getelementptr inbounds %closure, ptr %clstmp18, i32 0, i32 1
    store ptr null, ptr %envptr20, align 8
    %clstmp21 = alloca %closure, align 8
    store ptr @__fun_schmu7, ptr %clstmp21, align 8
    %envptr23 = getelementptr inbounds %closure, ptr %clstmp21, i32 0, i32 1
    store ptr null, ptr %envptr23, align 8
    call void @__iter_iter_iter_iter_iter_iter_liter_iter_l(ptr %clstmp18, ptr %clstmp21), !dbg !83
    call void @__free_a.l(ptr @schmu_arr__2)
    call void @__free_a.l(ptr @schmu_arr)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
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
  $ schmu --dump-llvm const_fixed_arr.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.ll = type { i64, i64 }
  
  @fmt_int_digits = external global ptr
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
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 17), !dbg !34
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
  $ valgrind -q --leak-check=yes --show-reachable=yes ./const_fixed_arr
  17

Decrease ref counts for local variables in if branches
  $ schmu --dump-llvm decr_rc_if.smu 2>&1 | grep -v !DI && valgrind -q --leak-check=yes --show-reachable=yes ./decr_rc_if
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
    call void @__free_a.l(ptr %arr)
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
    call void @__free_a.l(ptr %iftmp)
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
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}

Check allocs in fixed array
  $ schmu fixed_array_allocs.smu
  fixed_array_allocs.smu:1.5-8: warning: Unused binding arr.
  
  1 | let arr = #[#[1, 2, 3], #[3, 4, 5]]
          ^^^
  
  fixed_array_allocs.smu:8.9-12: warning: Unmutated mutable binding arr.
  
  8 | let mut arr = #[copy("hey"), copy("hie")] -- correctly free as mutate
              ^^^
  

  $ valgrind -q --leak-check=yes --show-reachable=yes ./fixed_array_allocs
  3
  hi
  hie
  oho

Allocate vectors on the heap and free them. Check with valgrind whenever something changes here.
Also mutable fields and 'realloc' builtin
  $ schmu --dump-llvm free_array.smu 2>&1 | grep -v !DI && valgrind -q --leak-check=yes --show-reachable=yes ./free_array
  free_array.smu:7.5-8: warning: Unused binding arr.
  
  7 | let arr = [copy("hey"), copy("young"), copy("world")]
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
  
  %foo = type { i64 }
  %container = type { i64, ptr }
  
  @schmu_x = constant %foo { i64 1 }
  @schmu_x__2 = internal constant %foo { i64 23 }
  @schmu_arr = global ptr null, align 8
  @schmu_arr__2 = global ptr null, align 8
  @schmu_arr__3 = global ptr null, align 8
  @schmu_normal = global ptr null, align 8
  @schmu_nested = global ptr null, align 8
  @schmu_nested__2 = global ptr null, align 8
  @schmu_nested__3 = global ptr null, align 8
  @schmu_rec_of_arr = global %container zeroinitializer, align 8
  @schmu_rec_of_arr__2 = global %container zeroinitializer, align 8
  @schmu_arr_of_rec = global ptr null, align 8
  @schmu_arr_of_rec__2 = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"hey\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"young\00" }
  @2 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"world\00" }
  
  define linkonce_odr void @__array_push_a.a.la.l(ptr noalias %arr, ptr %value) !dbg !2 {
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
  
  define linkonce_odr void @__array_push_a.foofoo(ptr noalias %arr, i64 %0) !dbg !8 {
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
    %10 = getelementptr inbounds %foo, ptr %9, i64 %3
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
    store %foo { i64 1 }, ptr %2, align 8
    %"1" = getelementptr %foo, ptr %2, i64 1
    store %foo { i64 2 }, ptr %"1", align 8
    %"2" = getelementptr %foo, ptr %2, i64 2
    store %foo { i64 3 }, ptr %"2", align 8
    call void @__array_push_a.foofoo(ptr %0, i64 12), !dbg !13
    call void @__free_a.foo(ptr %0)
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
    %"1" = getelementptr %container, ptr %1, i64 1
    %3 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !16
    store { i64, i64 } %3, ptr %"1", align 8
    ret ptr %0
  }
  
  define void @schmu_inner_parent_scope() !dbg !17 {
  entry:
    %0 = tail call ptr @schmu_make_arr(), !dbg !18
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_a.foo(ptr %1)
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
    %"1" = getelementptr %foo, ptr %1, i64 1
    store %foo { i64 2 }, ptr %"1", align 8
    %"2" = getelementptr %foo, ptr %1, i64 2
    store %foo { i64 3 }, ptr %"2", align 8
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
    call void @__free_a.a.l(ptr %arr)
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
    %2 = alloca %container, align 8
    store i64 1, ptr %2, align 8
    %arr1 = getelementptr inbounds %container, ptr %2, i32 0, i32 1
    store ptr %0, ptr %arr1, align 8
    %unbox = load { i64, i64 }, ptr %2, align 8
    ret { i64, i64 } %unbox
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_a.foo(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
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
    tail call void @__copy_a.c(ptr %1)
    %"1" = getelementptr ptr, ptr %1, i64 1
    %3 = alloca ptr, align 8
    store ptr @1, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %"1", ptr align 8 %3, i64 8, i1 false)
    tail call void @__copy_a.c(ptr %"1")
    %"2" = getelementptr ptr, ptr %1, i64 2
    %4 = alloca ptr, align 8
    store ptr @2, ptr %4, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %"2", ptr align 8 %4, i64 8, i1 false)
    tail call void @__copy_a.c(ptr %"2")
    %5 = tail call ptr @malloc(i64 40)
    store ptr %5, ptr @schmu_arr__2, align 8
    store i64 3, ptr %5, align 8
    %cap2 = getelementptr i64, ptr %5, i64 1
    store i64 3, ptr %cap2, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store %foo { i64 1 }, ptr %6, align 8
    %"14" = getelementptr %foo, ptr %6, i64 1
    store %foo { i64 2 }, ptr %"14", align 8
    %"25" = getelementptr %foo, ptr %6, i64 2
    store %foo { i64 3 }, ptr %"25", align 8
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
    tail call void @__array_push_a.a.la.l(ptr @schmu_nested, ptr %15), !dbg !32
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
    store ptr %19, ptr getelementptr inbounds (%container, ptr @schmu_rec_of_arr, i32 0, i32 1), align 8
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
    %"130" = getelementptr %container, ptr %23, i64 1
    %25 = tail call { i64, i64 } @schmu_record_of_arrs(), !dbg !38
    store { i64, i64 } %25, ptr %"130", align 8
    %26 = tail call ptr @schmu_arr_of_records(), !dbg !39
    store ptr %26, ptr @schmu_arr_of_rec__2, align 8
    %27 = alloca ptr, align 8
    store ptr %26, ptr %27, align 8
    call void @__free_a.container(ptr %27)
    call void @__free_a.container(ptr @schmu_arr_of_rec)
    call void @__free_container(ptr @schmu_rec_of_arr__2)
    call void @__free_container(ptr @schmu_rec_of_arr)
    %28 = alloca ptr, align 8
    store ptr %18, ptr %28, align 8
    call void @__free_a.a.l(ptr %28)
    %29 = alloca ptr, align 8
    store ptr %17, ptr %29, align 8
    call void @__free_a.a.l(ptr %29)
    call void @__free_a.a.l(ptr @schmu_nested)
    %30 = alloca ptr, align 8
    store ptr %8, ptr %30, align 8
    call void @__free_a.foo(ptr %30)
    %31 = alloca ptr, align 8
    store ptr %7, ptr %31, align 8
    call void @__free_a.foo(ptr %31)
    call void @__free_a.foo(ptr @schmu_arr__2)
    call void @__free_a.a.c(ptr @schmu_arr)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_a.c(ptr %0) {
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
  
  define linkonce_odr void @__free_container(ptr %0) {
  entry:
    %1 = getelementptr inbounds %container, ptr %0, i32 0, i32 1
    call void @__free_a.l(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.container(ptr %0) {
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
    %5 = getelementptr %container, ptr %4, i64 %2
    call void @__free_container(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.a.c(ptr %0) {
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
    call void @__free_a.c(ptr %5)
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
  
  !5 = !{}

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
  $ schmu --dump-llvm global_let.smu 2>&1 | grep -v !DI && valgrind -q --leak-check=yes --show-reachable=yes ./global_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.t.a.l = type { i32, ptr }
  %r.a.l = type { ptr }
  
  @schmu_a = internal constant %option.t.a.l { i32 0, ptr undef }
  @schmu_b = global ptr null, align 8
  @schmu_c = global i64 0, align 8
  
  define { i32, i64 } @schmu_ret_none() !dbg !2 {
  entry:
    %unbox = load { i32, i64 }, ptr @schmu_a, align 8
    ret { i32, i64 } %unbox
  }
  
  define i64 @schmu_ret_rec() !dbg !6 {
  entry:
    %0 = alloca %r.a.l, align 8
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
    %ret = alloca %option.t.a.l, align 8
    %0 = tail call { i32, i64 } @schmu_ret_none(), !dbg !8
    store { i32, i64 } %0, ptr %ret, align 8
    %index = load i32, ptr %ret, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !9
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.t.a.l, ptr %ret, i32 0, i32 1
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
    call void @__free_option.t.a.l(ptr %ret)
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi ptr [ %data, %then ], [ @schmu_b, %else ]
    %3 = load ptr, ptr %iftmp, align 8
    store ptr %3, ptr @schmu_b, align 8
    %ret1 = alloca %r.a.l, align 8
    %4 = call i64 @schmu_ret_rec(), !dbg !10
    store i64 %4, ptr %ret1, align 8
    %5 = inttoptr i64 %4 to ptr
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = getelementptr i64, ptr %6, i64 1
    %8 = load i64, ptr %7, align 8
    store i64 %8, ptr @schmu_c, align 8
    call void @__free_r.a.l(ptr %ret1)
    call void @__free_a.l(ptr @schmu_b)
    ret i64 0
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
  
  define linkonce_odr void @__free_r.a.l(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_a.l(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}

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
  $ schmu --dump-llvm regression_issue_19.smu 2>&1 | grep -v !DI && ./regression_issue_19
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
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

Tailcall loops
  $ schmu --dump-llvm regression_issue_26.smu 2>&1 | grep -v !DI && ./regression_issue_26
  regression_issue_26.smu:25.9-15: warning: Unused binding nested.
  
  25 | fun rec nested(a, b, c) {
               ^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.lfmt.formatter.t.u = type { i64, %fmt.formatter.t.u }
  
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
  
  define linkonce_odr void @__fmt_stdout_print3_fmt_stdout_print3_llfmt_stdout_print3_llfmt_stdout_print3_ll(ptr %fmtstr, ptr %f0, i64 %v0, ptr %f1, i64 %v1, ptr %f2, i64 %v2) !dbg !35 {
  entry:
    %__fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll = alloca %closure, align 8
    store ptr @__fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, ptr %__fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, align 8
    %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll = alloca { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %f12 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f12, ptr align 1 %f1, i64 16, i1 false)
    %f23 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 4
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f23, ptr align 1 %f2, i64 16, i1 false)
    %v04 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 5
    store i64 %v0, ptr %v04, align 8
    %v15 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 6
    store i64 %v1, ptr %v15, align 8
    %v26 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 7
    store i64 %v2, ptr %v26, align 8
    store ptr @__ctor_tp._fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll, ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll), !dbg !36
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
  
  define linkonce_odr void @__fun_fmt_stdout3_C__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout3_fmt.formatter.t.ulrfmt.formatter.t.ull(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !46 {
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
  
  define linkonce_odr void @__fun_fmt_stdout4_C__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.u__fun_fmt_stdout4_fmt.formatter.t.ulrfmt.formatter.t.ulll(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !52 {
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
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    call void @__fmt_stdout_print2_fmt_stdout_print2_llfmt_stdout_print2_ll(ptr @0, ptr %clstmp, i64 %.ph, ptr %clstmp4, i64 %2), !dbg !68
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
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp8, align 8
    %envptr10 = getelementptr inbounds %closure, ptr %clstmp8, i32 0, i32 1
    store ptr null, ptr %envptr10, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    call void @__fmt_stdout_print3_fmt_stdout_print3_llfmt_stdout_print3_llfmt_stdout_print3_ll(ptr @1, ptr %clstmp, i64 %.ph17.ph, ptr %clstmp8, i64 %.ph, ptr %clstmp11, i64 %4), !dbg !73
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
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp8, align 8
    %envptr10 = getelementptr inbounds %closure, ptr %clstmp8, i32 0, i32 1
    store ptr null, ptr %envptr10, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    call void @__fmt_stdout_print3_fmt_stdout_print3_llfmt_stdout_print3_llfmt_stdout_print3_ll(ptr @1, ptr %clstmp, i64 %.ph16.ph, ptr %clstmp8, i64 %.ph, ptr %clstmp11, i64 %3), !dbg !78
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
  
  define linkonce_odr ptr @__ctor_tp._fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.u_fmt.formatter.t.ulrfmt.formatter.t.ulll(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 2
    call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f0)
    %f1 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 3
    call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f1)
    %f2 = getelementptr inbounds { ptr, ptr, %closure, %closure, %closure, i64, i64, i64 }, ptr %1, i32 0, i32 4
    call void @__copy__fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f2)
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
  
  !5 = !{}
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
  $ schmu -c --dump-llvm regression_issue_30.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
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
  $ schmu --dump-llvm regression_load_global.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
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
  $ schmu --dump-llvm return_closure.smu 2>&1 | grep -v !DI && valgrind -q --leak-check=yes --show-reachable=yes ./return_closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.t.u = type { %closure }
  
  @fmt_int_digits = external global ptr
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
  
  define linkonce_odr ptr @__ctor_tp.l(ptr %0) {
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
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %loadtmp = load ptr, ptr @schmu_f, align 8
    %loadtmp1 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %loadtmp(i64 12, ptr %loadtmp1), !dbg !40
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %0), !dbg !41
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %loadtmp5 = load ptr, ptr @schmu_f2, align 8
    %loadtmp6 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f2, i32 0, i32 1), align 8
    %1 = call i64 %loadtmp5(i64 12, ptr %loadtmp6), !dbg !42
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp2, i64 %1), !dbg !43
    call void @schmu_ret_lambda(ptr @schmu_f__2, i64 134), !dbg !44
    %clstmp7 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %loadtmp10 = load ptr, ptr @schmu_f__2, align 8
    %loadtmp11 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f__2, i32 0, i32 1), align 8
    %2 = call i64 %loadtmp10(i64 12, ptr %loadtmp11), !dbg !45
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp7, i64 %2), !dbg !46
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
  
  !5 = !{}
  25
  47
  146

Return nonclosure functions
  $ schmu --dump-llvm return_fn.smu 2>&1 | grep -v !DI && ./return_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %fmt.formatter.t.u = type { %closure }
  
  @fmt_int_digits = external global ptr
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
    tail call void @schmu_ret_fn(ptr @schmu_f), !dbg !38
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %loadtmp = load ptr, ptr @schmu_f, align 8
    %loadtmp1 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f, i32 0, i32 1), align 8
    %0 = tail call i64 %loadtmp(i64 12, ptr %loadtmp1), !dbg !39
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %0), !dbg !40
    call void @schmu_ret_named(ptr @schmu_f__2), !dbg !41
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %loadtmp5 = load ptr, ptr @schmu_f__2, align 8
    %loadtmp6 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_f__2, i32 0, i32 1), align 8
    %1 = call i64 %loadtmp5(i64 12, ptr %loadtmp6), !dbg !42
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp2, i64 %1), !dbg !43
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
  
  !5 = !{}
  24
  25

Take/use not all allocations of a record in tailrec calls
  $ schmu --dump-llvm take_partial_alloc.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %view = type { ptr, i64, i64 }
  %fmt.formatter.t.a.c = type { %closure, ptr }
  %closure = type { ptr, ptr }
  %parse_result.view = type { i32, %success.view }
  %success.view = type { %view, %view }
  %parse_result.l = type { i32, %success.l }
  %success.l = type { %view, i64 }
  
  @schmu_s = global ptr null, align 8
  @schmu_inp = global %view zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c" \00" }
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare i1 @prelude_char_equal(i8 %0, i8 %1)
  
  declare void @fmt_fmt_str_create(ptr noalias %0)
  
  define linkonce_odr ptr @__fmt_formatter_extract_fmt.formatter.t.a.cra.c(ptr %fm) !dbg !2 {
  entry:
    %0 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %fm, i32 0, i32 1
    tail call void @__free_except1_fmt.formatter.t.a.c(ptr %fm)
    %1 = load ptr, ptr %0, align 8
    ret ptr %1
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !6 {
  entry:
    %1 = alloca %fmt.formatter.t.a.c, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 24, i1 false)
    %2 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %1, i32 0, i32 1
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    call void %loadtmp(ptr %2, ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !7
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %p, ptr %str) !dbg !8 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !9
    %2 = tail call i64 @string_len(ptr %str), !dbg !10
    tail call void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !11
    ret void
  }
  
  define linkonce_odr ptr @__fmt_str_print_fmt_str_print_a.ca.c(ptr %fmt, ptr %value) !dbg !12 {
  entry:
    %ret = alloca %fmt.formatter.t.a.c, align 8
    call void @fmt_fmt_str_create(ptr %ret), !dbg !13
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.a.c, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, ptr %value, ptr %loadtmp1), !dbg !14
    %0 = call ptr @__fmt_formatter_extract_fmt.formatter.t.a.cra.c(ptr %ret2), !dbg !15
    ret ptr %0
  }
  
  define void @schmu_aux(ptr noalias %0, ptr %rem, i64 %cnt) !dbg !16 {
  entry:
    %1 = alloca %view, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %rem, i64 24, i1 false)
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
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %data, i64 24, i1 false)
    store i64 %add, ptr %3, align 8
    br label %rec
  
  else:                                             ; preds = %rec
    %data1 = getelementptr inbounds %parse_result.view, ptr %ret, i32 0, i32 1
    store i32 0, ptr %0, align 4
    %data3 = getelementptr inbounds %parse_result.l, ptr %0, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data3, ptr align 8 %1, i64 24, i1 false)
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
    %1 = load ptr, ptr %buf, align 8
    %2 = getelementptr inbounds %view, ptr %buf, i32 0, i32 1
    %3 = load i64, ptr %2, align 8
    %4 = tail call i8 @string_get(ptr %1, i64 %3), !dbg !21
    %5 = tail call i1 @prelude_char_equal(i8 %4, i8 32), !dbg !22
    br i1 %5, label %then, label %else, !dbg !22
  
  then:                                             ; preds = %entry
    store i32 0, ptr %0, align 4
    %data = getelementptr inbounds %parse_result.view, ptr %0, i32 0, i32 1
    %6 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %6, ptr align 1 %buf, i64 8, i1 false)
    call void @__copy_a.c(ptr %6)
    %7 = load ptr, ptr %6, align 8
    store ptr %7, ptr %data, align 8
    %start = getelementptr inbounds %view, ptr %data, i32 0, i32 1
    %sunkaddr = getelementptr inbounds i8, ptr %buf, i64 8
    %8 = load i64, ptr %sunkaddr, align 8
    %add = add i64 %8, 1
    store i64 %add, ptr %start, align 8
    %len = getelementptr inbounds %view, ptr %data, i32 0, i32 2
    %9 = getelementptr inbounds %view, ptr %buf, i32 0, i32 2
    %10 = load i64, ptr %9, align 8
    %sub = sub i64 %10, 1
    store i64 %sub, ptr %len, align 8
    %mtch = getelementptr inbounds %success.view, ptr %data, i32 0, i32 1
    %11 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %11, ptr align 1 %buf, i64 8, i1 false)
    call void @__copy_a.c(ptr %11)
    %12 = load ptr, ptr %11, align 8
    store ptr %12, ptr %mtch, align 8
    %start3 = getelementptr inbounds %view, ptr %mtch, i32 0, i32 1
    %13 = load i64, ptr %sunkaddr, align 8
    store i64 %13, ptr %start3, align 8
    %len4 = getelementptr inbounds %view, ptr %mtch, i32 0, i32 2
    store i64 1, ptr %len4, align 8
    ret void
  
  else:                                             ; preds = %entry
    store i32 1, ptr %0, align 4
    %data6 = getelementptr inbounds %parse_result.view, ptr %0, i32 0, i32 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %data6, ptr align 1 %buf, i64 24, i1 false)
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
    %1 = alloca ptr, align 8
    store ptr %str, ptr %1, align 8
    %2 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %1, i64 8, i1 false)
    call void @__copy_a.c(ptr %2)
    %3 = load ptr, ptr %2, align 8
    store ptr %3, ptr %0, align 8
    %start = getelementptr inbounds %view, ptr %0, i32 0, i32 1
    store i64 0, ptr %start, align 8
    %len = getelementptr inbounds %view, ptr %0, i32 0, i32 2
    %4 = call i64 @string_len(ptr %str), !dbg !26
    store i64 %4, ptr %len, align 8
    ret void
  }
  
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
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    call void %dtor1(ptr %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(ptr %env)
    br label %ret
  }
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.a.c(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free__a.cp.clru(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_view(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_a.c(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_except0_success.view(ptr %0) {
  entry:
    %1 = getelementptr inbounds %success.view, ptr %0, i32 0, i32 1
    call void @__free_view(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__copy_a.c(ptr %0) {
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
  
  define linkonce_odr void @__copy_view(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__copy_a.c(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_success.view(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_view(ptr %1)
    %2 = getelementptr inbounds %success.view, ptr %0, i32 0, i32 1
    call void @__free_view(ptr %2)
    ret void
  }
  
  define linkonce_odr void @__free_parse_result.view(ptr %0) {
  entry:
    %tag4 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag4, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse_result.view, ptr %0, i32 0, i32 1
    call void @__free_success.view(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    %2 = icmp eq i32 %index, 1
    br i1 %2, label %match1, label %cont2
  
  match1:                                           ; preds = %cont
    %data3 = getelementptr inbounds %parse_result.view, ptr %0, i32 0, i32 1
    call void @__free_view(ptr %data3)
    br label %cont2
  
  cont2:                                            ; preds = %match1, %cont
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !27 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_str_fmt.formatter.t.a.crfmt.formatter.t.a.c, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = call ptr @__fmt_str_print_fmt_str_print_a.ca.c(ptr %clstmp, ptr @0), !dbg !28
    store ptr %0, ptr @schmu_s, align 8
    call void @schmu_view_of_string(ptr @schmu_inp, ptr %0), !dbg !29
    %ret = alloca %parse_result.l, align 8
    call void @schmu_many_count(ptr %ret, ptr @schmu_inp), !dbg !30
    call void @__free_parse_result.l(ptr %ret)
    call void @__free_view(ptr @schmu_inp)
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_a.c(ptr %1)
    ret i64 0
  }
  
  define linkonce_odr void @__free_success.l(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_view(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_parse_result.l(ptr %0) {
  entry:
    %tag4 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag4, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %parse_result.l, ptr %0, i32 0, i32 1
    call void @__free_success.l(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    %2 = icmp eq i32 %index, 1
    br i1 %2, label %match1, label %cont2
  
  match1:                                           ; preds = %cont
    %data3 = getelementptr inbounds %parse_result.l, ptr %0, i32 0, i32 1
    call void @__free_view(ptr %data3)
    br label %cont2
  
  cont2:                                            ; preds = %match1, %cont
    ret void
  }
  
  declare void @free(ptr %0)
  
  declare ptr @malloc(i64 %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
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

Fix parent reentering
  $ schmu reenter_parent.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./reenter_parent

Fix partial parent setting
  $ schmu set_partial_parent.smu
  set_partial_parent.smu:4.18-29: warning: Constructor is never used to build values: Resolv_deps.
  
  4 | type key_state = Resolv_deps | Building(building) | Built(built)
                       ^^^^^^^^^^^
  
  $ valgrind -q --leak-check=yes --show-reachable=yes ./set_partial_parent

Correctly track partial moves in record expressions
  $ schmu partial_move_in_record.smu
  partial_move_in_record.smu:4.26-32: warning: Unused constructor: Module.
  
  4 | type rule = Executable | Module
                               ^^^^^^
  
  partial_move_in_record.smu:8.45-53: warning: Constructor is never used to build values: Building.
  
  8 | type key_state = Resolv_deps(resolv_deps) | Building(building) | Built(built)
                                                  ^^^^^^^^
  
  $ valgrind -q --leak-check=yes --show-reachable=yes ./partial_move_in_record
