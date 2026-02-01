Copy string literal
  $ schmu --dump-llvm --target x86_64-unknown-linux-gnu -c string_lit.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.lfmt.formatter.t.u = type { i64, %fmt.formatter.t.u }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_stdout_missing_arg_msg = external global { ptr, i64, i64 }
  @fmt_stdout_too_many_arg_msg = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @0 = private unnamed_addr constant [9 x i8] c"test {}\0A\00"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @fmt_prerr(ptr noalias %0)
  
  declare void @fmt_stdout_helper_printn(ptr noalias %0, ptr %1, ptr %2)
  
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
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_missing_fmt.formatter.t.u(ptr noalias %0) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !23
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_u(ptr %ret1, ptr %ret, ptr @fmt_stdout_missing_arg_msg), !dbg !24
    call void @__fmt_endl_u(ptr %ret1), !dbg !25
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_too_many_u() !dbg !26 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !27
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_u(ptr %ret1, ptr %ret, ptr @fmt_stdout_too_many_arg_msg), !dbg !28
    call void @__fmt_endl_u(ptr %ret1), !dbg !29
    call void @abort()
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_print1_l(ptr %fmtstr, ptr %f0, i64 %v0) !dbg !30 {
  entry:
    %__fun_fmt_stdout2_l = alloca %closure, align 8
    store ptr @__fun_fmt_stdout2_l, ptr %__fun_fmt_stdout2_l, align 8
    %clsr___fun_fmt_stdout2_l = alloca { ptr, ptr, %closure, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr___fun_fmt_stdout2_l, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %v02 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr___fun_fmt_stdout2_l, i32 0, i32 3
    store i64 %v0, ptr %v02, align 8
    store ptr @__ctor_tp.fmt.formatter.t.ulrfmt.formatter.t.ul, ptr %clsr___fun_fmt_stdout2_l, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr___fun_fmt_stdout2_l, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout2_l, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout2_l, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout2_l), !dbg !31
    %0 = getelementptr inbounds %tp.lfmt.formatter.t.u, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 1
    br i1 %ne, label %then, label %else, !dbg !32
  
  then:                                             ; preds = %entry
    call void @__fmt_stdout_impl_fmt_fail_too_many_u(), !dbg !33
    call void @__free_fmt.formatter.t.u(ptr %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @__fmt_formatter_extract_u(ptr %0), !dbg !34
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_str_u(ptr noalias %0, ptr %p, ptr %str) !dbg !35 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !36
    %2 = tail call i64 @string_len(ptr %str), !dbg !37
    tail call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !38
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
    tail call void @__array_fixed_swap_items_cA64.u(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !40
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout2_l(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !41 {
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
    tail call void @__fmt_stdout_impl_fmt_fail_missing_fmt.formatter.t.u(ptr %0), !dbg !44
    tail call void @__free_fmt.formatter.t.u(ptr %fmter)
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !46
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !47
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !48
    br i1 %lt, label %then4, label %ifcont, !dbg !48
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
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
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp.fmt.formatter.t.ulrfmt.formatter.t.ul(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 40)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %1, i32 0, i32 2
    tail call void @__copy_fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f0)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy_fmt.formatter.t.ulrfmt.formatter.t.u(ptr %0) {
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
    tail call void @__free_up.clru(ptr %0)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !49 {
  entry:
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 8, i64 -1 }, ptr %boxconst, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_print1_l(ptr %boxconst, ptr %clstmp, i64 1), !dbg !51
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu string_lit.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./string_lit
  test 1

Copy array of strings
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu arr_of_strings.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global { ptr, i64, i64 } zeroinitializer, align 8
  @0 = private unnamed_addr constant [5 x i8] c"test\00"
  @1 = private unnamed_addr constant [6 x i8] c"toast\00"
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 48)
    store ptr %0, ptr @schmu_a, align 8
    %1 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 4, i64 -1 }, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %0)
    %"1" = getelementptr { ptr, i64, i64 }, ptr %0, i64 1
    %2 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @1, i64 5, i64 -1 }, ptr %2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %"1", ptr align 8 %2, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %"1")
    %3 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 @schmu_a, i64 24, i1 false)
    call void @__copy_a.a.c(ptr %3)
    %4 = load ptr, ptr %3, align 8
    %5 = getelementptr { ptr, i64, i64 }, ptr %4, i64 1
    call void @string_println(ptr %5), !dbg !6
    call void @__free_a.a.c(ptr %3)
    call void @__free_a.a.c(ptr @schmu_a)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
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
  
  define linkonce_odr void @__copy_a.a.c(ptr %0) {
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
  
  cont:                                             ; preds = %rec, %zero
    ret void
  
  nonempty:                                         ; preds = %entry
    %2 = mul i64 %size, 24
    %3 = tail call ptr @malloc(i64 %2)
    %4 = load ptr, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %4, i64 %2, i1 false)
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 %size, ptr %cap2, align 8
    store ptr %3, ptr %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %nonempty
    %lsr.iv = phi i64 [ %lsr.iv.next, %child ], [ 0, %nonempty ]
    %5 = phi i64 [ %8, %child ], [ 0, %nonempty ]
    %6 = icmp slt i64 %5, %size
    br i1 %6, label %child, label %cont
  
  child:                                            ; preds = %rec
    %7 = load ptr, ptr %0, align 8
    %scevgep = getelementptr i8, ptr %7, i64 %lsr.iv
    tail call void @__copy_a.c(ptr %scevgep)
    %8 = add i64 %5, 1
    store i64 %8, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
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
  $ schmu arr_of_strings.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./arr_of_strings
  toast

Copy records
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu records.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %cont.t = type { %t }
  %t = type { double, { ptr, i64, i64 }, i64, { ptr, i64, i64 } }
  
  @schmu_a = global %cont.t zeroinitializer, align 8
  @0 = private unnamed_addr constant [4 x i8] c"lul\00"
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    store double 1.000000e+01, ptr @schmu_a, align 8
    %0 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 3, i64 -1 }, ptr %0, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 getelementptr inbounds (%t, ptr @schmu_a, i32 0, i32 1), ptr align 8 %0, i64 24, i1 false)
    tail call void @__copy_a.c(ptr getelementptr inbounds (%t, ptr @schmu_a, i32 0, i32 1))
    store i64 10, ptr getelementptr inbounds (%t, ptr @schmu_a, i32 0, i32 2), align 8
    store i64 3, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr getelementptr inbounds (%t, ptr @schmu_a, i32 0, i32 3), i32 0, i32 1), align 8
    store i64 3, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr getelementptr inbounds (%t, ptr @schmu_a, i32 0, i32 3), i32 0, i32 2), align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr getelementptr inbounds (%t, ptr @schmu_a, i32 0, i32 3), align 8
    store i64 10, ptr %1, align 8
    %"1" = getelementptr i64, ptr %1, i64 1
    store i64 20, ptr %"1", align 8
    %"2" = getelementptr i64, ptr %1, i64 2
    store i64 30, ptr %"2", align 8
    %2 = alloca %cont.t, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 @schmu_a, i64 64, i1 false)
    call void @__copy_cont.t(ptr %2)
    %3 = getelementptr inbounds %t, ptr %2, i32 0, i32 1
    call void @string_println(ptr %3), !dbg !6
    call void @__free_cont.t(ptr %2)
    call void @__free_cont.t(ptr @schmu_a)
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
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_t(ptr %0) {
  entry:
    %1 = getelementptr inbounds %t, ptr %0, i32 0, i32 1
    tail call void @__copy_a.c(ptr %1)
    %2 = getelementptr inbounds %t, ptr %0, i32 0, i32 3
    tail call void @__copy_a.l(ptr %2)
    ret void
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
  
  define linkonce_odr void @__copy_cont.t(ptr %0) {
  entry:
    tail call void @__copy_t(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_t(ptr %0) {
  entry:
    %1 = getelementptr inbounds %t, ptr %0, i32 0, i32 1
    tail call void @__free_a.c(ptr %1)
    %2 = getelementptr inbounds %t, ptr %0, i32 0, i32 3
    tail call void @__free_a.l(ptr %2)
    ret void
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_cont.t(ptr %0) {
  entry:
    tail call void @__free_t(ptr %0)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu records.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./records
  lul

Copy variants
  $ schmu variants.smu --dump-llvm --target x86_64-unknown-linux-gnu -c 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %option.t.tp.a.cl = type { i32, %tp.a.cl }
  %tp.a.cl = type { { ptr, i64, i64 }, i64 }
  
  @schmu_a = global %option.t.tp.a.cl zeroinitializer, align 8
  @0 = private unnamed_addr constant [6 x i8] c"thing\00"
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    store i32 1, ptr @schmu_a, align 4
    %0 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 5, i64 -1 }, ptr %0, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 getelementptr inbounds (%option.t.tp.a.cl, ptr @schmu_a, i32 0, i32 1), ptr align 8 %0, i64 24, i1 false)
    tail call void @__copy_a.c(ptr getelementptr inbounds (%option.t.tp.a.cl, ptr @schmu_a, i32 0, i32 1))
    store i64 0, ptr getelementptr inbounds (%tp.a.cl, ptr getelementptr inbounds (%option.t.tp.a.cl, ptr @schmu_a, i32 0, i32 1), i32 0, i32 1), align 8
    %1 = alloca %option.t.tp.a.cl, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 @schmu_a, i64 40, i1 false)
    call void @__copy_option.t.tp.a.cl(ptr %1)
    %index = load i32, ptr %1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont, !dbg !6
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.t.tp.a.cl, ptr %1, i32 0, i32 1
    %2 = getelementptr inbounds %tp.a.cl, ptr %data, i32 0, i32 1
    call void @string_println(ptr %data), !dbg !7
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    call void @__free_option.t.tp.a.cl(ptr %1)
    call void @__free_option.t.tp.a.cl(ptr @schmu_a)
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
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__copy_tp.a.cl(ptr %0) {
  entry:
    tail call void @__copy_a.c(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__copy_option.t.tp.a.cl(ptr %0) {
  entry:
    %index = load i32, ptr %0, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t.tp.a.cl, ptr %0, i32 0, i32 1
    tail call void @__copy_tp.a.cl(ptr %data)
    ret void
  
  cont:                                             ; preds = %entry
    ret void
  }
  
  define linkonce_odr void @__free_tp.a.cl(ptr %0) {
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
  
  define linkonce_odr void @__free_option.t.tp.a.cl(ptr %0) {
  entry:
    %index = load i32, ptr %0, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t.tp.a.cl, ptr %0, i32 0, i32 1
    tail call void @__free_tp.a.cl(ptr %data)
    ret void
  
  cont:                                             ; preds = %entry
    ret void
  }
  
  declare void @free(ptr %0)
  
  declare ptr @malloc(i64 %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu variants.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./variants
  thing

Copy closures
  $ schmu --dump-llvm --target x86_64-unknown-linux-gnu -c closure.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %tp.ll = type { i64, i64 }
  %tp.rrll = type { %closure, i64 }
  
  @schmu_c = global %closure zeroinitializer, align 8
  @0 = private unnamed_addr constant [6 x i8] c"hello\00"
  
  declare void @string_println(ptr %0)
  
  define void @__fun_schmu0(ptr %0) !dbg !2 {
  entry:
    %a = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 } }, ptr %0, i32 0, i32 2
    %1 = load ptr, ptr %a, align 8
    tail call void @string_println(ptr %1), !dbg !6
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
    %1 = alloca %tp.ll, align 8
    store i64 1, ptr %1, align 8
    %"1" = getelementptr inbounds %tp.ll, ptr %1, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    store ptr @schmu_capture, ptr %0, align 8
    %2 = tail call ptr @malloc(i64 24)
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 2
    store i64 1, ptr %a, align 8
    store ptr @__ctor_tp.l, ptr %2, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %2, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_hmm_move(ptr noalias %0) !dbg !10 {
  entry:
    %1 = alloca %tp.ll, align 8
    store i64 1, ptr %1, align 8
    %"1" = getelementptr inbounds %tp.ll, ptr %1, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    store ptr @schmu_capture__2, ptr %0, align 8
    %2 = tail call ptr @malloc(i64 24)
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 2
    store i64 1, ptr %a, align 8
    store ptr @__ctor_tp.l, ptr %2, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %2, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_test(ptr noalias %0) !dbg !11 {
  entry:
    %arr = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr %arr, align 8
    %2 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 5, i64 -1 }, ptr %2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 8 %2, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %1)
    store ptr @__fun_schmu0, ptr %0, align 8
    %3 = tail call ptr @malloc(i64 40)
    %a = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 } }, ptr %3, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a, ptr align 8 %arr, i64 24, i1 false)
    tail call void @__copy_a.a.c(ptr %a)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a, ptr align 1 %a, i64 24, i1 false)
    store ptr @__ctor_tp.a.a.c, ptr %3, align 8
    %dtor = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 } }, ptr %3, i32 0, i32 1
    store ptr @__dtor_tp.a.a.c, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %3, ptr %envptr, align 8
    call void @__free_a.a.c(ptr %arr)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr ptr @__ctor_tp.l(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 24)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    ret ptr %1
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
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
  
  define linkonce_odr void @__copy_a.a.c(ptr %0) {
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
  
  cont:                                             ; preds = %rec, %zero
    ret void
  
  nonempty:                                         ; preds = %entry
    %2 = mul i64 %size, 24
    %3 = tail call ptr @malloc(i64 %2)
    %4 = load ptr, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %4, i64 %2, i1 false)
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 %size, ptr %cap2, align 8
    store ptr %3, ptr %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %nonempty
    %lsr.iv = phi i64 [ %lsr.iv.next, %child ], [ 0, %nonempty ]
    %5 = phi i64 [ %8, %child ], [ 0, %nonempty ]
    %6 = icmp slt i64 %5, %size
    br i1 %6, label %child, label %cont
  
  child:                                            ; preds = %rec
    %7 = load ptr, ptr %0, align 8
    %scevgep = getelementptr i8, ptr %7, i64 %lsr.iv
    tail call void @__copy_a.c(ptr %scevgep)
    %8 = add i64 %5, 1
    store i64 %8, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
  }
  
  define linkonce_odr ptr @__ctor_tp.a.a.c(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 40)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %a = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 } }, ptr %1, i32 0, i32 2
    tail call void @__copy_a.a.c(ptr %a)
    ret ptr %1
  }
  
  define linkonce_odr void @__dtor_tp.a.a.c(ptr %0) {
  entry:
    %a = getelementptr inbounds { ptr, ptr, { ptr, i64, i64 } }, ptr %0, i32 0, i32 2
    tail call void @__free_a.a.c(ptr %a)
    tail call void @free(ptr %0)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !12 {
  entry:
    %0 = alloca %tp.rrll, align 8
    %clstmp = alloca %closure, align 8
    store ptr @schmu_hmm, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %clstmp, i64 16, i1 false)
    call void @__copy_rrl(ptr %0)
    %"1" = getelementptr inbounds %tp.rrll, ptr %0, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    %1 = alloca %tp.rrll, align 8
    %clstmp2 = alloca %closure, align 8
    store ptr @schmu_hmm_move, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %clstmp2, i64 16, i1 false)
    call void @__copy_rrl(ptr %1)
    %"15" = getelementptr inbounds %tp.rrll, ptr %1, i32 0, i32 1
    store i64 0, ptr %"15", align 8
    call void @schmu_test(ptr @schmu_c), !dbg !13
    %2 = alloca %closure, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 @schmu_c, i64 16, i1 false)
    call void @__copy_ru(ptr %2)
    %loadtmp = load ptr, ptr %2, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %2, i32 0, i32 1
    %loadtmp7 = load ptr, ptr %envptr6, align 8
    call void %loadtmp(ptr %loadtmp7), !dbg !14
    call void @__free_ru(ptr %2)
    call void @__free_ru(ptr @schmu_c)
    call void @__free_tp.rrll(ptr %1)
    call void @__free_tp.rrll(ptr %0)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_rrl(ptr %0) {
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
  
  define linkonce_odr void @__copy_ru(ptr %0) {
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
  
  define linkonce_odr void @__free_ru(ptr %0) {
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
  
  define linkonce_odr void @__free_rrl(ptr %0) {
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
  
  define linkonce_odr void @__free_tp.rrll(ptr %0) {
  entry:
    tail call void @__free_rrl(ptr %0)
    ret void
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu closure.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./closure
  hello

Copy string literal on move
  $ schmu copy_string_lit.smu --dump-llvm -c --target x86_64-unknown-linux-gnu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @schmu_a = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_b = global { ptr, i64, i64 } zeroinitializer, align 8
  @0 = private unnamed_addr constant [5 x i8] c"aoeu\00"
  
  declare void @string_modify_buf(ptr noalias %0, ptr %1)
  
  declare void @string_println(ptr %0)
  
  define void @__fun_schmu0(ptr noalias %arr) !dbg !2 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = getelementptr inbounds i8, ptr %0, i64 1
    store i8 105, ptr %1, align 1
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_a, align 8
    %1 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 4, i64 -1 }, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    tail call void @__copy_a.c(ptr %0)
    %2 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 4, i64 -1 }, ptr %2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 %2, i64 24, i1 false)
    tail call void @__copy_a.c(ptr @schmu_b)
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @string_modify_buf(ptr @schmu_b, ptr %clstmp), !dbg !7
    call void @string_println(ptr @schmu_b), !dbg !8
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 4, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !9
    %3 = load ptr, ptr @schmu_a, align 8
    call void @string_println(ptr %3), !dbg !10
    call void @__free_a.c(ptr @schmu_b)
    call void @__free_a.a.c(ptr @schmu_a)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
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
  $ schmu copy_string_lit.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./copy_string_lit
  aieu
  aoeu
  aoeu

Correctly copy array
  $ schmu copy_array.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./copy_array

Correctly copy rc
  $ schmu rc.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./rc

Regression from stateful iter experiment. Free deeply nested records and variants
  $ schmu free_nested.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./free_nested
  0
  6
