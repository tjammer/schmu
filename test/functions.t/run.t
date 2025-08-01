Compile stubs
  $ cc -c stub.c

Test name resolution and IR creation of functions
We discard the triple, b/c it varies from distro to distro
e.g. x86_64-unknown-linux-gnu on Fedora vs x86_64-pc-linux-gnu on gentoo

Simple fibonacci
  $ schmu --dump-llvm -o a.out stub.o fib.smu 2>&1 | grep -v !DI && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
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
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = tail call i64 @schmu_fib(i64 30), !dbg !38
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp, i64 %0), !dbg !39
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  832040

Fibonacci, but we shadow a bunch
  $ schmu --dump-llvm stub.o shadowing.smu 2>&1 | grep -v !DI && ./shadowing
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
  
  !5 = !{}
  832040

Multiple parameters
  $ schmu --dump-llvm stub.o multi_params.smu 2>&1 | grep -v !DI && ./multi_params
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
  
  !5 = !{}
  [1]

We have downwards closures
  $ schmu --dump-llvm stub.o closure.smu 2>&1 | grep -v !DI && ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %capturable = type { i64 }
  
  @schmu_a = global %capturable zeroinitializer, align 8
  
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
  
  !5 = !{}
  [12]

First class functions
  $ schmu --dump-llvm stub.o first_class.smu 2>&1 | grep -v !DI && ./first_class
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__fun_schmu0_lrl(i64 %x) !dbg !2 {
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
  
  define linkonce_odr i1 @__schmu_apply_bschmu_apply_brbrb(i1 %x, ptr %f) !dbg !8 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i1 %loadtmp(i1 %x, ptr %loadtmp1), !dbg !9
    ret i1 %0
  }
  
  define linkonce_odr i64 @__schmu_apply_lschmu_apply_lrlrl(i64 %x, ptr %f) !dbg !10 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i64 %loadtmp(i64 %x, ptr %loadtmp1), !dbg !11
    ret i64 %0
  }
  
  define linkonce_odr i64 @__schmu_pass_lrl(i64 %x) !dbg !12 {
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
    %0 = call i64 @__schmu_apply_lschmu_apply_lrlrl(i64 0, ptr %clstmp), !dbg !18
    call void @printi(i64 %0), !dbg !19
    %clstmp1 = alloca %closure, align 8
    store ptr @__fun_schmu1, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %1 = call i64 @__schmu_apply_lschmu_apply_lrlrl(i64 1, ptr %clstmp1), !dbg !20
    call void @printi(i64 %1), !dbg !21
    %clstmp4 = alloca %closure, align 8
    store ptr @schmu_makefalse, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %2 = call i1 @__schmu_apply_bschmu_apply_brbrb(i1 true, ptr %clstmp4), !dbg !22
    %3 = call i64 @schmu_int_of_bool(i1 %2), !dbg !23
    call void @printi(i64 %3), !dbg !24
    %clstmp7 = alloca %closure, align 8
    store ptr @__fun_schmu2, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %4 = call i64 @__schmu_apply_lschmu_apply_lrlrl(i64 3, ptr %clstmp7), !dbg !25
    call void @printi(i64 %4), !dbg !26
    %clstmp10 = alloca %closure, align 8
    store ptr @__schmu_pass_lrl, ptr %clstmp10, align 8
    %envptr12 = getelementptr inbounds %closure, ptr %clstmp10, i32 0, i32 1
    store ptr null, ptr %envptr12, align 8
    %5 = call i64 @__schmu_apply_lschmu_apply_lrlrl(i64 4, ptr %clstmp10), !dbg !27
    call void @printi(i64 %5), !dbg !28
    %clstmp13 = alloca %closure, align 8
    store ptr @__fun_schmu0_lrl, ptr %clstmp13, align 8
    %envptr15 = getelementptr inbounds %closure, ptr %clstmp13, i32 0, i32 1
    store ptr null, ptr %envptr15, align 8
    %6 = call i64 @__schmu_apply_lschmu_apply_lrlrl(i64 5, ptr %clstmp13), !dbg !29
    call void @printi(i64 %6), !dbg !30
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  1
  2
  0
  3
  4
  5

Don't try to create 'void' value in if
  $ schmu --dump-llvm stub.o if_return_void.smu 2>&1 | grep -v !DI && ./if_return_void
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
  
  !5 = !{}
  4
  3
  2
  0

Captured values should not overwrite function params
  $ schmu --dump-llvm stub.o -o a.out overwrite_params.smu 2>&1 | grep -v !DI && ./a.out
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
  
  !5 = !{}
  3

Functions can be generic. In this test, we generate 'apply' only once and use it with
3 different functions with different types
  $ schmu --dump-llvm stub.o generic_fun_arg.smu 2>&1 | grep -v !DI && ./generic_fun_arg
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t.l = type { i64 }
  %closure = type { ptr, ptr }
  %t.b = type { i1 }
  
  @schmu_a = constant i64 2
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__fun_schmu0_t.lrt.l(i64 %0) !dbg !2 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %1 = alloca %t.l, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %x, i64 8, i1 false)
    %unbox = load i64, ptr %1, align 8
    ret i64 %unbox
  }
  
  define i64 @__fun_schmu1(i64 %x) !dbg !6 {
  entry:
    ret i64 %x
  }
  
  define linkonce_odr i1 @__schmu_apply_bschmu_apply_brbrb(i1 %x, ptr %f) !dbg !7 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i1 %loadtmp(i1 %x, ptr %loadtmp1), !dbg !8
    ret i1 %0
  }
  
  define linkonce_odr i64 @__schmu_apply_lschmu_apply_lrlrl(i64 %x, ptr %f) !dbg !9 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i64 %loadtmp(i64 %x, ptr %loadtmp1), !dbg !10
    ret i64 %0
  }
  
  define linkonce_odr i8 @__schmu_apply_t.bschmu_apply_t.brt.brt.b(i8 %0, ptr %f) !dbg !11 {
  entry:
    %x = alloca i8, align 1
    store i8 %0, ptr %x, align 1
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret = alloca %t.b, align 8
    %1 = tail call i8 %loadtmp(i8 %0, ptr %loadtmp1), !dbg !12
    store i8 %1, ptr %ret, align 1
    ret i8 %1
  }
  
  define linkonce_odr i64 @__schmu_apply_t.lschmu_apply_t.lrt.lrt.l(i64 %0, ptr %f) !dbg !13 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret = alloca %t.l, align 8
    %1 = tail call i64 %loadtmp(i64 %0, ptr %loadtmp1), !dbg !14
    store i64 %1, ptr %ret, align 8
    ret i64 %1
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
    %1 = alloca %t.l, align 8
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
    %2 = alloca %t.b, align 8
    store %t.b zeroinitializer, ptr %2, align 1
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
    %0 = call i64 @__schmu_apply_lschmu_apply_lrlrl(i64 20, ptr %clstmp), !dbg !26
    call void @printi(i64 %0), !dbg !27
    %clstmp1 = alloca %closure, align 8
    store ptr @schmu_add_closed, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %1 = call i64 @__schmu_apply_lschmu_apply_lrlrl(i64 20, ptr %clstmp1), !dbg !28
    call void @printi(i64 %1), !dbg !29
    %clstmp4 = alloca %closure, align 8
    store ptr @schmu_add3_rec, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %ret = alloca %t.l, align 8
    %2 = call i64 @__schmu_apply_t.lschmu_apply_t.lrt.lrt.l(i64 20, ptr %clstmp4), !dbg !30
    store i64 %2, ptr %ret, align 8
    call void @printi(i64 %2), !dbg !31
    %clstmp7 = alloca %closure, align 8
    store ptr @schmu_make_rec_false, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %ret10 = alloca %t.b, align 8
    %3 = call i8 @__schmu_apply_t.bschmu_apply_t.brt.brt.b(i8 1, ptr %clstmp7), !dbg !32
    store i8 %3, ptr %ret10, align 1
    %4 = trunc i8 %3 to i1
    call void @schmu_print_bool(i1 %4), !dbg !33
    %clstmp11 = alloca %closure, align 8
    store ptr @schmu_makefalse, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    %5 = call i1 @__schmu_apply_bschmu_apply_brbrb(i1 true, ptr %clstmp11), !dbg !34
    call void @schmu_print_bool(i1 %5), !dbg !35
    %ret14 = alloca %t.l, align 8
    %6 = call i64 @__fun_schmu0_t.lrt.l(i64 17), !dbg !36
    store i64 %6, ptr %ret14, align 8
    call void @printi(i64 %6), !dbg !37
    %7 = call i64 @__fun_schmu1(i64 18), !dbg !38
    call void @printi(i64 %7), !dbg !39
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  21
  22
  23
  0
  0
  17
  18

A generic pass function. This example is not 100% correct, but works due to calling convertion.
  $ schmu --dump-llvm stub.o generic_pass.smu 2>&1 | grep -v !DI && ./generic_pass
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %t = type { i64, i1 }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__schmu_apply_schmu_apply_lrllrl(ptr %f, i64 %x) !dbg !2 {
  entry:
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %0 = tail call i64 %loadtmp(i64 %x, ptr %loadtmp1), !dbg !6
    ret i64 %0
  }
  
  define linkonce_odr { i64, i8 } @__schmu_apply_schmu_apply_trttrt(ptr %f, i64 %0, i8 %1) !dbg !7 {
  entry:
    %x = alloca { i64, i8 }, align 8
    store i64 %0, ptr %x, align 8
    %snd = getelementptr inbounds { i64, i8 }, ptr %x, i32 0, i32 1
    store i8 %1, ptr %snd, align 1
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp5 = load ptr, ptr %envptr, align 8
    %ret = alloca %t, align 8
    %2 = tail call { i64, i8 } %loadtmp(i64 %0, i8 %1, ptr %loadtmp5), !dbg !8
    store { i64, i8 } %2, ptr %ret, align 8
    ret { i64, i8 } %2
  }
  
  define linkonce_odr i64 @__schmu_pass_lrl(i64 %x) !dbg !9 {
  entry:
    ret i64 %x
  }
  
  define linkonce_odr { i64, i8 } @__schmu_pass_trt(i64 %0, i8 %1) !dbg !10 {
  entry:
    %x = alloca { i64, i8 }, align 8
    store i64 %0, ptr %x, align 8
    %snd = getelementptr inbounds { i64, i8 }, ptr %x, i32 0, i32 1
    store i8 %1, ptr %snd, align 1
    %2 = alloca %t, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %x, i64 16, i1 false)
    %unbox = load { i64, i8 }, ptr %2, align 8
    ret { i64, i8 } %unbox
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !11 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__schmu_pass_lrl, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = call i64 @__schmu_apply_schmu_apply_lrllrl(ptr %clstmp, i64 20), !dbg !12
    call void @printi(i64 %0), !dbg !13
    %clstmp1 = alloca %closure, align 8
    store ptr @__schmu_pass_trt, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %boxconst = alloca %t, align 8
    store %t { i64 700, i1 false }, ptr %boxconst, align 8
    %fst4 = load i64, ptr %boxconst, align 8
    %snd = getelementptr inbounds { i64, i8 }, ptr %boxconst, i32 0, i32 1
    %snd5 = load i8, ptr %snd, align 1
    %ret = alloca %t, align 8
    %1 = call { i64, i8 } @__schmu_apply_schmu_apply_trttrt(ptr %clstmp1, i64 %fst4, i8 %snd5), !dbg !14
    store { i64, i8 } %1, ptr %ret, align 8
    %2 = load i64, ptr %ret, align 8
    call void @printi(i64 %2), !dbg !15
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  20
  700


This is a regression test. The 'add1' function was not marked as a closure when being called from
a second function. Instead, the closure struct was being created again and the code segfaulted
  $ schmu --dump-llvm stub.o indirect_closure.smu 2>&1 | grep -v !DI && ./indirect_closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %t.l = type { i64 }
  
  @schmu_a = global i64 0, align 8
  @schmu_b = global i64 0, align 8
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__schmu_apply2_t.lschmu_apply2_t.lschmu_apply2_lrlrt.lschmu_apply2_lrlrt.l(i64 %0, ptr %f, ptr %env) !dbg !2 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret = alloca %t.l, align 8
    %1 = tail call i64 %loadtmp(i64 %0, ptr %env, ptr %loadtmp1), !dbg !6
    store i64 %1, ptr %ret, align 8
    ret i64 %1
  }
  
  define linkonce_odr i64 @__schmu_apply_t.lschmu_apply_t.lschmu_apply_lrlrt.lschmu_apply_lrlrt.l(i64 %0, ptr %f, ptr %env) !dbg !7 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret = alloca %t.l, align 8
    %1 = tail call i64 %loadtmp(i64 %0, ptr %env, ptr %loadtmp1), !dbg !8
    store i64 %1, ptr %ret, align 8
    ret i64 %1
  }
  
  define linkonce_odr i64 @__schmu_boxed2int_int_t.lschmu_boxed2int_int_lrlrt.l(i64 %0, ptr %env) !dbg !9 {
  entry:
    %t = alloca i64, align 8
    store i64 %0, ptr %t, align 8
    %loadtmp = load ptr, ptr %env, align 8
    %envptr = getelementptr inbounds %closure, ptr %env, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %1 = tail call i64 %loadtmp(i64 %0, ptr %loadtmp1), !dbg !10
    %2 = alloca %t.l, align 8
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
    store ptr @__schmu_boxed2int_int_t.lschmu_boxed2int_int_lrlrt.l, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @schmu_add1, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %ret = alloca %t.l, align 8
    %0 = call i64 @__schmu_apply_t.lschmu_apply_t.lschmu_apply_lrlrt.lschmu_apply_lrlrt.l(i64 15, ptr %clstmp, ptr %clstmp1), !dbg !13
    store i64 %0, ptr %ret, align 8
    store i64 %0, ptr @schmu_a, align 8
    call void @printi(i64 %0), !dbg !14
    %clstmp4 = alloca %closure, align 8
    store ptr @__schmu_boxed2int_int_t.lschmu_boxed2int_int_lrlrt.l, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %clstmp7 = alloca %closure, align 8
    store ptr @schmu_add1, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %ret10 = alloca %t.l, align 8
    %1 = call i64 @__schmu_apply2_t.lschmu_apply2_t.lschmu_apply2_lrlrt.lschmu_apply2_lrlrt.l(i64 15, ptr %clstmp4, ptr %clstmp7), !dbg !15
    store i64 %1, ptr %ret10, align 8
    store i64 %1, ptr @schmu_b, align 8
    call void @printi(i64 %1), !dbg !16
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  16
  16

Closures can recurse too
  $ schmu --dump-llvm stub.o -o a.out recursive_closure.smu 2>&1 | grep -v !DI && ./a.out
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
  
  !5 = !{}
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
  $ schmu --dump-llvm stub.o no_lambda_let_poly_monomorph.smu 2>&1 | grep -v !DI
  no_lambda_let_poly_monomorph.smu:5.9-59: error: Returning polymorphic anonymous function in if expressions is not supported (yet). Sorry. You can type the function concretely though..
  
  5 | let f = if true {fun(x) {copy(x)}} else {fun(x) {copy(x)}}
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  
Allow mixing of typedefs and external decls in the preface
  $ schmu --dump-llvm stub.o mix_preface.smu 2>&1 | grep -v !DI && ./mix_preface
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
  
  !5 = !{}

Support monomorphization of nested functions
  $ schmu --dump-llvm stub.o monomorph_nested.smu 2>&1 | grep -v !DI && ./monomorph_nested
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %rc = type { i64 }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i1 @__schmu_id_brb(i1 %x) !dbg !2 {
  entry:
    ret i1 %x
  }
  
  define linkonce_odr i64 @__schmu_id_lrl(i64 %x) !dbg !6 {
  entry:
    ret i64 %x
  }
  
  define linkonce_odr i64 @__schmu_id_rcrrc(i64 %0) !dbg !7 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %1 = alloca %rc, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %x, i64 8, i1 false)
    %unbox = load i64, ptr %1, align 8
    ret i64 %unbox
  }
  
  define linkonce_odr i1 @__schmu_wrapped_brb(i1 %x) !dbg !8 {
  entry:
    %0 = tail call i1 @__schmu_id_brb(i1 %x), !dbg !9
    ret i1 %0
  }
  
  define linkonce_odr i64 @__schmu_wrapped_lrl(i64 %x) !dbg !10 {
  entry:
    %0 = tail call i64 @__schmu_id_lrl(i64 %x), !dbg !11
    ret i64 %0
  }
  
  define linkonce_odr i64 @__schmu_wrapped_rcrrc(i64 %0) !dbg !12 {
  entry:
    %x = alloca i64, align 8
    store i64 %0, ptr %x, align 8
    %ret = alloca %rc, align 8
    %1 = tail call i64 @__schmu_id_rcrrc(i64 %0), !dbg !13
    store i64 %1, ptr %ret, align 8
    ret i64 %1
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !14 {
  entry:
    %0 = tail call i64 @__schmu_wrapped_lrl(i64 12), !dbg !15
    tail call void @printi(i64 %0), !dbg !16
    %1 = tail call i1 @__schmu_wrapped_brb(i1 false), !dbg !17
    %ret = alloca %rc, align 8
    %2 = tail call i64 @__schmu_wrapped_rcrrc(i64 24), !dbg !18
    store i64 %2, ptr %ret, align 8
    tail call void @printi(i64 %2), !dbg !19
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  12
  24

Nested polymorphic closures. Does not quite work for another nesting level
  $ schmu --dump-llvm stub.o nested_polymorphic_closures.smu 2>&1 | grep -v !DI && valgrind -q --leak-check=yes --show-reachable=yes ./nested_polymorphic_closures
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @schmu_arr = global ptr null, align 8
  
  declare void @printi(i64 %0)
  
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
  
  define void @__fun_schmu0(i64 %x) !dbg !8 {
  entry:
    %mul = mul i64 %x, 2
    tail call void @printi(i64 %mul), !dbg !10
    ret void
  }
  
  define linkonce_odr void @__schmu_array_iter_a.lschmu_array_iter_l(ptr %arr, ptr %f) !dbg !11 {
  entry:
    %__schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru = alloca %closure, align 8
    store ptr @__schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru, ptr %__schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru, align 8
    %clsr___schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru = alloca { ptr, ptr, ptr, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %f2 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f2, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_tp.a.l_lru, ptr %clsr___schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru, i32 0, i32 1
    store ptr %clsr___schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru, ptr %envptr, align 8
    %__schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l = alloca %closure, align 8
    store ptr @__schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l, ptr %__schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l, align 8
    %clsr___schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l = alloca { ptr, ptr, ptr }, align 8
    %arr4 = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr___schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l, i32 0, i32 2
    store ptr %arr, ptr %arr4, align 8
    store ptr @__ctor_tp.a.l, ptr %clsr___schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l, align 8
    %dtor6 = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr___schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l, i32 0, i32 1
    store ptr null, ptr %dtor6, align 8
    %envptr7 = getelementptr inbounds %closure, ptr %__schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l, i32 0, i32 1
    store ptr %clsr___schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l, ptr %envptr7, align 8
    %__schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru = alloca %closure, align 8
    store ptr @__schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru, ptr %__schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru, align 8
    %clsr___schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru = alloca { ptr, ptr, %closure }, align 8
    %f9 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f9, ptr align 1 %f, i64 16, i1 false)
    store ptr @__ctor_tp._lru, ptr %clsr___schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru, align 8
    %dtor11 = getelementptr inbounds { ptr, ptr, %closure }, ptr %clsr___schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru, i32 0, i32 1
    store ptr null, ptr %dtor11, align 8
    %envptr12 = getelementptr inbounds %closure, ptr %__schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru, i32 0, i32 1
    store ptr %clsr___schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru, ptr %envptr12, align 8
    call void @__schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru(i64 0, ptr %clsr___schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru), !dbg !12
    call void @__schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l(i64 0, ptr %f, ptr %clsr___schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l), !dbg !13
    call void @__schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru(i64 0, ptr %arr, ptr %clsr___schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru), !dbg !14
    ret void
  }
  
  define linkonce_odr void @__schmu_inner_cls_arr_schmu_inner_cls_arr_lCa.l(i64 %i, ptr %f, ptr %0) !dbg !15 {
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
  
  define linkonce_odr void @__schmu_inner_cls_both_Ca.lschmu_inner_cls_both_lru(i64 %i, ptr %0) !dbg !18 {
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
  
  define linkonce_odr void @__schmu_inner_cls_f_a.lCschmu_inner_cls_f_lru(i64 %i, ptr %arr, ptr %0) !dbg !21 {
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
  
  define linkonce_odr ptr @__ctor_tp.a.l_lru(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    call void @__copy_a.l(ptr %arr)
    %f = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 3
    call void @__copy__lru(ptr %f)
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
  
  define linkonce_odr ptr @__ctor_tp.a.l(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_a.l(ptr %arr)
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
  
  define linkonce_odr void @__free_a.l(ptr %0) {
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
    tail call void @__array_push_a.ll(ptr @schmu_arr, i64 1), !dbg !25
    tail call void @__array_push_a.ll(ptr @schmu_arr, i64 2), !dbg !26
    tail call void @__array_push_a.ll(ptr @schmu_arr, i64 3), !dbg !27
    tail call void @__array_push_a.ll(ptr @schmu_arr, i64 4), !dbg !28
    tail call void @__array_push_a.ll(ptr @schmu_arr, i64 5), !dbg !29
    %2 = load ptr, ptr @schmu_arr, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__schmu_array_iter_a.lschmu_array_iter_l(ptr %2, ptr %clstmp), !dbg !30
    call void @__free_a.l(ptr @schmu_arr)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
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
  $ schmu --dump-llvm stub.o closures_to_env.smu 2>&1 | grep -v !DI && ./closures_to_env
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
  
  !5 = !{}
  20

Don't copy mutable types in setup of tailrecursive functions
  $ schmu --dump-llvm tailrec_mutable.smu 2>&1 | grep -v !DI && valgrind -q --leak-check=yes --show-reachable=yes ./tailrec_mutable
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %bref = type { i1 }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %r = type { i64 }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_rf = global %bref zeroinitializer, align 1
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"true\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"false\00" }
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
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
  
  define linkonce_odr void @__fmt_bool_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, i1 %b) !dbg !10 {
  entry:
    br i1 %b, label %then, label %else, !dbg !12
  
  then:                                             ; preds = %entry
    tail call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr @0), !dbg !13
    ret void
  
  else:                                             ; preds = %entry
    tail call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr @1), !dbg !14
    ret void
  }
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !15 {
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
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_bb(ptr %fmt, i1 %value) !dbg !29 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !30
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i1 %value, ptr %loadtmp1), !dbg !31
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !32
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %fmt, i64 %value) !dbg !33 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !34
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !35
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret2), !dbg !36
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, ptr %str) !dbg !37 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !38
    %2 = tail call i64 @string_len(ptr %str), !dbg !39
    tail call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !40
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !42
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
    %2 = alloca %bref, align 8
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
    tail call void @__array_push_a.ll(ptr %a, i64 20), !dbg !58
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
    call void @__free_a.l(ptr %.ph25)
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
    call void @__free_a.l(ptr %.ph25)
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
    call void @__array_push_a.ll(ptr %.ph25, i64 20), !dbg !63
    store ptr %.ph25, ptr %0, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  call_decr18:                                      ; preds = %then13
    call void @__free_a.l(ptr %.ph25)
    br label %cont20
  
  cookie19:                                         ; preds = %then13
    store i1 true, ptr %1, align 1
    br label %cont20
  
  cont20:                                           ; preds = %cookie19, %call_decr18
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
  
  define linkonce_odr void @__free_a.l(ptr %0) {
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
    store ptr @__fmt_bool_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = load i1, ptr @schmu_rf, align 1
    call void @__fmt_stdout_println_fmt_stdout_println_bb(ptr %clstmp, i1 %0), !dbg !66
    call void @schmu_dontmut_bref(i64 0, ptr @schmu_rf), !dbg !67
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_bool_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %1 = load i1, ptr @schmu_rf, align 1
    call void @__fmt_stdout_println_fmt_stdout_println_bb(ptr %clstmp1, i1 %1), !dbg !68
    %2 = alloca %r, align 8
    store i64 20, ptr %2, align 8
    call void @schmu_mod_rec(ptr %2, i64 0), !dbg !69
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp4, i64 %3), !dbg !70
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
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp7, align 8
    %envptr9 = getelementptr inbounds %closure, ptr %clstmp7, i32 0, i32 1
    store ptr null, ptr %envptr9, align 8
    %7 = load ptr, ptr %4, align 8
    %8 = load i64, ptr %7, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp7, i64 %8), !dbg !72
    %9 = alloca i64, align 8
    store i64 0, ptr %9, align 8
    call void @schmu_change_int(ptr %9, i64 0), !dbg !73
    %clstmp10 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp10, align 8
    %envptr12 = getelementptr inbounds %closure, ptr %clstmp10, i32 0, i32 1
    store ptr null, ptr %envptr12, align 8
    %10 = load i64, ptr %9, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp10, i64 %10), !dbg !74
    %11 = alloca ptr, align 8
    %12 = call ptr @malloc(i64 24)
    store ptr %12, ptr %11, align 8
    store i64 0, ptr %12, align 8
    %cap14 = getelementptr i64, ptr %12, i64 1
    store i64 1, ptr %cap14, align 8
    %13 = getelementptr i8, ptr %12, i64 16
    call void @schmu_test(ptr %11, i64 0), !dbg !75
    %clstmp15 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp15, align 8
    %envptr17 = getelementptr inbounds %closure, ptr %clstmp15, i32 0, i32 1
    store ptr null, ptr %envptr17, align 8
    %14 = load ptr, ptr %11, align 8
    %15 = load i64, ptr %14, align 8
    call void @__fmt_stdout_println_fmt_stdout_println_ll(ptr %clstmp15, i64 %15), !dbg !76
    call void @__free_a.l(ptr %11)
    call void @__free_a.l(ptr %4)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  true
  true
  2
  4
  100
  2

The lamba passed as array-iter argument is polymorphic
  $ schmu polymorphic_lambda_argument.smu --dump-llvm 2>&1 | grep -v !DI&& valgrind -q --leak-check=yes --show-reachable=yes ./polymorphic_lambda_argument
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %option.t.c = type { i32, i8 }
  %fmt.formatter.t.a.c = type { %closure, ptr }
  
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
  
  define linkonce_odr i64 @__array_pop_back_a.croption.t.c(ptr noalias %arr) !dbg !12 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, 0
    br i1 %eq, label %then, label %else, !dbg !13
  
  then:                                             ; preds = %entry
    %t = alloca %option.t.c, align 8
    store %option.t.c { i32 0, i8 undef }, ptr %t, align 4
    br label %ifcont
  
  else:                                             ; preds = %entry
    %t1 = alloca %option.t.c, align 8
    store i32 1, ptr %t1, align 4
    %data = getelementptr inbounds %option.t.c, ptr %t1, i32 0, i32 1
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
  
  define linkonce_odr void @__array_push_a.cc(ptr noalias %arr, i8 %value) !dbg !14 {
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
  
  define linkonce_odr ptr @__fmt_formatter_extract_fmt.formatter.t.a.cra.c(ptr %fm) !dbg !17 {
  entry:
    %0 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %fm, i32 0, i32 1
    tail call void @__free_except1_fmt.formatter.t.a.c(ptr %fm)
    %1 = load ptr, ptr %0, align 8
    ret ptr %1
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !19 {
  entry:
    %1 = alloca %fmt.formatter.t.a.c, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 24, i1 false)
    %2 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %1, i32 0, i32 1
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    call void %loadtmp(ptr %2, ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !20
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !21 {
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
    call void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr %0, ptr %p, ptr %1, i64 1), !dbg !23
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
    call void @__fmt_formatter_format_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !26
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr noalias %0, ptr %p, i64 %i) !dbg !27 {
  entry:
    tail call void @__fmt_int_base_fmt.formatter.t.a.crfmt.formatter.t.a.c(ptr %0, ptr %p, i64 %i, i64 10), !dbg !28
    ret void
  }
  
  define linkonce_odr ptr @__fmt_str_print_fmt_str_print_ll(ptr %fmt, i64 %value) !dbg !29 {
  entry:
    %ret = alloca %fmt.formatter.t.a.c, align 8
    call void @fmt_fmt_str_create(ptr %ret), !dbg !30
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.a.c, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !31
    %0 = call ptr @__fmt_formatter_extract_fmt.formatter.t.a.cra.c(ptr %ret2), !dbg !32
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
    tail call void @__array_fixed_swap_items_A64.c(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !34
    ret void
  }
  
  define linkonce_odr i1 @__fun_iter6_lC__fun_iter6_llrul(i64 %x, ptr %0) !dbg !35 {
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
    tail call void @__array_push_a.cc(ptr %arr, i8 0), !dbg !40
    %ret = alloca %option.t.c, align 8
    %0 = tail call i64 @__array_pop_back_a.croption.t.c(ptr %arr), !dbg !41
    store i64 %0, ptr %ret, align 8
    ret void
  }
  
  define i1 @__fun_schmu1(ptr %__curry0, ptr %0) !dbg !42 {
  entry:
    %arr = getelementptr inbounds { ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    %arr1 = load ptr, ptr %arr, align 8
    %1 = tail call i1 @__array_iter_a.larray_iter_l(ptr %arr1, ptr %__curry0), !dbg !43
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
    store ptr @__fmt_int_fmt.formatter.t.a.crfmt.formatter.t.a.c, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %1 = call ptr @__fmt_str_print_fmt_str_print_ll(ptr %clstmp, i64 %v), !dbg !47
    call void @string_append(ptr %acc1, ptr %1), !dbg !48
    %2 = alloca ptr, align 8
    store ptr %1, ptr %2, align 8
    call void @__free_a.c(ptr %2)
    ret void
  }
  
  define linkonce_odr void @__iter_iteri_iter_iteri_iter_iteri_liter_iteri_l(ptr %it, ptr %f) !dbg !49 {
  entry:
    %0 = alloca i64, align 8
    store i64 0, ptr %0, align 8
    %__fun_iter6_lC__fun_iter6_llrul = alloca %closure, align 8
    store ptr @__fun_iter6_lC__fun_iter6_llrul, ptr %__fun_iter6_lC__fun_iter6_llrul, align 8
    %clsr___fun_iter6_lC__fun_iter6_llrul = alloca { ptr, ptr, %closure, ptr }, align 8
    %f1 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_iter6_lC__fun_iter6_llrul, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f1, ptr align 1 %f, i64 16, i1 false)
    %_iter_i = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_iter6_lC__fun_iter6_llrul, i32 0, i32 3
    store ptr %0, ptr %_iter_i, align 8
    store ptr @__ctor_tp._llrul, ptr %clsr___fun_iter6_lC__fun_iter6_llrul, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_iter6_lC__fun_iter6_llrul, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_iter6_lC__fun_iter6_llrul, i32 0, i32 1
    store ptr %clsr___fun_iter6_lC__fun_iter6_llrul, ptr %envptr, align 8
    %loadtmp = load ptr, ptr %it, align 8
    %envptr2 = getelementptr inbounds %closure, ptr %it, i32 0, i32 1
    %loadtmp3 = load ptr, ptr %envptr2, align 8
    %1 = call i1 %loadtmp(ptr %__fun_iter6_lC__fun_iter6_llrul, ptr %loadtmp3), !dbg !50
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
    call void @__copy_a.c(ptr %0)
    %__fun_schmu1 = alloca %closure, align 8
    store ptr @__fun_schmu1, ptr %__fun_schmu1, align 8
    %clsr___fun_schmu1 = alloca { ptr, ptr, ptr }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr }, ptr %clsr___fun_schmu1, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    store ptr @__ctor_tp.a.l, ptr %clsr___fun_schmu1, align 8
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
    store ptr @__ctor_tp.a.ca.c, ptr %clsr___fun_schmu2, align 8
    %dtor5 = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %clsr___fun_schmu2, i32 0, i32 1
    store ptr null, ptr %dtor5, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %__fun_schmu2, i32 0, i32 1
    store ptr %clsr___fun_schmu2, ptr %envptr6, align 8
    call void @__iter_iteri_iter_iteri_iter_iteri_liter_iteri_l(ptr %__fun_schmu1, ptr %__fun_schmu2), !dbg !58
    call void @schmu_string_add_null(ptr %0), !dbg !59
    %2 = load ptr, ptr %0, align 8
    ret ptr %2
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
  
  declare ptr @realloc(ptr %0, i64 %1)
  
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
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 88)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp._llrul(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 2
    call void @__copy__llru(ptr %f)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy__llru(ptr %0) {
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
  
  define linkonce_odr ptr @__ctor_tp.a.l(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_a.l(ptr %arr)
    ret ptr %1
  }
  
  define linkonce_odr ptr @__ctor_tp.a.ca.c(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 32)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 32, i1 false)
    %acc = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_a.c(ptr %acc)
    %delim = getelementptr inbounds { ptr, ptr, ptr, ptr }, ptr %1, i32 0, i32 3
    call void @__copy_a.c(ptr %delim)
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
    call void @__free_a.c(ptr %4)
    call void @__free_a.l(ptr @schmu_arr)
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
  
  !5 = !{}
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
  $ schmu poly_fn_ret_fn.smu --dump-llvm 2>&1 | grep -v !DI&& valgrind -q --leak-check=yes --show-reachable=yes ./poly_fn_ret_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %wrap.__fmt.formatter.t.ua.crfmt.formatter.t.ua.cru = type { %closure }
  %closure = type { ptr, ptr }
  %fmt.formatter.t.u = type { %closure }
  %tp.lfmt.formatter.t.u = type { i64, %fmt.formatter.t.u }
  
  @fmt_stdout_missing_arg_msg = external global ptr
  @fmt_stdout_too_many_arg_msg = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_once = global i1 true, align 1
  @schmu_result = global %wrap.__fmt.formatter.t.ua.crfmt.formatter.t.ua.cru zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"{} foo\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"{} bar\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"a\00" }
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare void @fmt_prerr(ptr noalias %0)
  
  declare void @fmt_stdout_helper_printn(ptr noalias %0, ptr %1, ptr %2)
  
  define linkonce_odr void @__fmt_endl_fmt.formatter.t.uru(ptr %p) !dbg !2 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !6
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %ret), !dbg !7
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %fm) !dbg !8 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !9 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !10
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_missing_rfmt.formatter.t.u(ptr noalias %0) !dbg !11 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !12
    %1 = load ptr, ptr @fmt_stdout_missing_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret1, ptr %ret, ptr %1), !dbg !13
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret1), !dbg !14
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_impl_fmt_fail_too_many_ru() !dbg !15 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !16
    %0 = load ptr, ptr @fmt_stdout_too_many_arg_msg, align 8
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr %ret1, ptr %ret, ptr %0), !dbg !17
    call void @__fmt_endl_fmt.formatter.t.uru(ptr %ret1), !dbg !18
    call void @abort()
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_print1_fmt_stdout_print1_a.ca.c(ptr %fmtstr, ptr %f0, ptr %v0) !dbg !19 {
  entry:
    %__fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c = alloca %closure, align 8
    store ptr @__fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, ptr %__fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, align 8
    %clsr___fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c = alloca { ptr, ptr, %closure, ptr }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %v02 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, i32 0, i32 3
    store ptr %v0, ptr %v02, align 8
    store ptr @__ctor_tp._fmt.formatter.t.ua.crfmt.formatter.t.ua.c, ptr %clsr___fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c), !dbg !20
    %0 = getelementptr inbounds %tp.lfmt.formatter.t.u, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 1
    br i1 %ne, label %then, label %else, !dbg !21
  
  then:                                             ; preds = %entry
    call void @__fmt_stdout_impl_fmt_fail_too_many_ru(), !dbg !22
    call void @__free_fmt.formatter.t.u(ptr %0)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @__fmt_formatter_extract_fmt.formatter.t.uru(ptr %0), !dbg !23
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u(ptr noalias %0, ptr %p, ptr %str) !dbg !24 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !25
    %2 = tail call i64 @string_len(ptr %str), !dbg !26
    tail call void @__fmt_formatter_format_fmt.formatter.t.urfmt.formatter.t.u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !27
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_stdout2_C__fun_fmt_stdout2_fmt.formatter.t.ua.crfmt.formatter.t.ua.c(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !28 {
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
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rfmt.formatter.t.u(ptr %0), !dbg !31
    tail call void @__free_fmt.formatter.t.u(ptr %fmter)
    ret void
  }
  
  define linkonce_odr void @__fun_schmu0___fun_schmu0_a.ca.c(ptr %fmt, ptr %a) !dbg !32 {
  entry:
    tail call void @__fmt_stdout_print1_fmt_stdout_print1_a.ca.c(ptr @0, ptr %fmt, ptr %a), !dbg !34
    ret void
  }
  
  define linkonce_odr void @__schmu_bar_schmu_bar_a.ca.c(ptr %fmt, ptr %a) !dbg !35 {
  entry:
    tail call void @__fmt_stdout_print1_fmt_stdout_print1_a.ca.c(ptr @1, ptr %fmt, ptr %a), !dbg !36
    ret void
  }
  
  define linkonce_odr void @__schmu_black_box_schmu_black_box_schmu_black_box_fmt.formatter.t.ua.crfmt.formatter.t.ua.cruschmu_black_box_schmu_black_box_fmt.formatter.t.ua.crfmt.formatter.t.ua.crurschmu_black_box_schmu_black_box_fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr noalias %0, ptr %f, ptr %g) !dbg !37 {
  entry:
    %1 = load i1, ptr @schmu_once, align 1
    br i1 %1, label %then, label %else, !dbg !38
  
  then:                                             ; preds = %entry
    store i1 false, ptr @schmu_once, align 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %f, i64 16, i1 false)
    tail call void @__copy___fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr %0)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %g, i64 16, i1 false)
    tail call void @__copy___fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr %0)
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
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp._fmt.formatter.t.ua.crfmt.formatter.t.ua.c(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 40)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 2
    call void @__copy__fmt.formatter.t.ua.crfmt.formatter.t.u(ptr %f0)
    %v0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 3
    call void @__copy_a.c(ptr %v0)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy__fmt.formatter.t.ua.crfmt.formatter.t.u(ptr %0) {
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
  
  define linkonce_odr void @__free_fmt.formatter.t.u(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free__up.clru(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__copy___fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr %0) {
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
    store ptr @__fun_schmu0___fun_schmu0_a.ca.c, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @__schmu_bar_schmu_bar_a.ca.c, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    call void @__schmu_black_box_schmu_black_box_schmu_black_box_fmt.formatter.t.ua.crfmt.formatter.t.ua.cruschmu_black_box_schmu_black_box_fmt.formatter.t.ua.crfmt.formatter.t.ua.crurschmu_black_box_schmu_black_box_fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr @schmu_result, ptr %clstmp, ptr %clstmp1), !dbg !40
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %0 = alloca %closure, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %clstmp4, i64 16, i1 false)
    call void @__copy__fmt.formatter.t.ua.crfmt.formatter.t.u(ptr %0)
    %loadtmp = load ptr, ptr @schmu_result, align 8
    %loadtmp7 = load ptr, ptr getelementptr inbounds (%closure, ptr @schmu_result, i32 0, i32 1), align 8
    call void %loadtmp(ptr %0, ptr @2, ptr %loadtmp7), !dbg !41
    call void @__free__fmt.formatter.t.ua.crfmt.formatter.t.u(ptr %0)
    call void @__free_wrap.__fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr @schmu_result)
    ret i64 0
  }
  
  define linkonce_odr void @__free__fmt.formatter.t.ua.crfmt.formatter.t.u(ptr %0) {
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
  
  define linkonce_odr void @__free___fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr %0) {
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
  
  define linkonce_odr void @__free_wrap.__fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free___fmt.formatter.t.ua.crfmt.formatter.t.ua.cru(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
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

Monomorphize types where the correct subst doesn't show up immediately
  $ schmu monomorph_later.smu
  monomorph_later.smu:14.5-10: warning: Constructor is never used to build values: Other.
  
  14 |   | Other(rc[prom_state])
           ^^^^^
  
  $ valgrind -q --leak-check=yes --show-reachable=yes ./monomorph_later
