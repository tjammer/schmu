Test simple setting of mutable variables
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu simple_set.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_b = global i64 10, align 8
  @schmu_a = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_b__3 = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_c = global { ptr, i64, i64 } zeroinitializer, align 8
  
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
  
  define i64 @schmu_hmm() !dbg !32 {
  entry:
    %0 = alloca i64, align 8
    store i64 10, ptr %0, align 8
    store i64 15, ptr %0, align 8
    ret i64 15
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !34 {
  entry:
    store i64 14, ptr @schmu_b, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 14), !dbg !35
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %0 = call i64 @schmu_hmm(), !dbg !36
    call void @__fmt_stdout_println_l(ptr %clstmp1, i64 %0), !dbg !37
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 2), align 8
    %1 = call ptr @malloc(i64 48)
    store ptr %1, ptr @schmu_a, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %1, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %1, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %2 = call ptr @malloc(i64 8)
    store ptr %2, ptr %1, align 8
    store i64 10, ptr %2, align 8
    %"1" = getelementptr { ptr, i64, i64 }, ptr %1, i64 1
    %len5 = getelementptr inbounds { ptr, i64, i64 }, ptr %"1", i32 0, i32 1
    store i64 1, ptr %len5, align 8
    %cap6 = getelementptr inbounds { ptr, i64, i64 }, ptr %"1", i32 0, i32 2
    store i64 1, ptr %cap6, align 8
    %3 = call ptr @malloc(i64 8)
    store ptr %3, ptr %"1", align 8
    store i64 20, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b__3, ptr align 8 @schmu_a, i64 24, i1 false)
    call void @__copy_a.a.l(ptr @schmu_b__3)
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_c, i32 0, i32 1), align 8
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_c, i32 0, i32 2), align 8
    %4 = call ptr @malloc(i64 8)
    store ptr %4, ptr @schmu_c, align 8
    store i64 30, ptr %4, align 8
    %5 = load ptr, ptr @schmu_a, align 8
    %6 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %6, ptr align 8 @schmu_c, i64 24, i1 false)
    call void @__copy_a.l(ptr %6)
    call void @__free_a.l(ptr %5)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %5, ptr align 8 %6, i64 24, i1 false)
    %7 = load ptr, ptr @schmu_a, align 8
    %arr = alloca { ptr, i64, i64 }, align 8
    %len10 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 1, ptr %len10, align 8
    %cap11 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 1, ptr %cap11, align 8
    %8 = call ptr @malloc(i64 8)
    store ptr %8, ptr %arr, align 8
    store i64 10, ptr %8, align 8
    call void @__free_a.l(ptr %7)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %7, ptr align 8 %arr, i64 24, i1 false)
    call void @__free_a.l(ptr @schmu_c)
    call void @__free_a.a.l(ptr @schmu_b__3)
    call void @__free_a.a.l(ptr @schmu_a)
    ret i64 0
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
  
  define linkonce_odr void @__copy_a.a.l(ptr %0) {
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
    tail call void @__copy_a.l(ptr %scevgep)
    %8 = add i64 %5, 1
    store i64 %8, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
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
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu simple_set.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./simple_set
  14
  15

Warn on unneeded mutable bindings
  $ schmu unneeded_mut.smu
  unneeded_mut.smu:1.5-15: warning: Unused binding do_nothing
  
  1 | fun do_nothing(mut a) { ignore(a) }
          ^^^^^^^^^^
  
  unneeded_mut.smu:5.9-10: warning: Unmutated mutable binding b
  
  5 | let mut b = 0
              ^
  
Use mutable values as ptrs to C code
  $ schmu -c --dump-llvm -c --target x86_64-unknown-linux-gnu ptr_to_c.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
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
  
  !5 = !{}

Check aliasing
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu mut_alias.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_f = global %foo zeroinitializer, align 8
  @schmu_fst = global %foo zeroinitializer, align 8
  @schmu_snd = global %foo zeroinitializer, align 8
  
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
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 1), !dbg !34
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp1, i64 0), !dbg !35
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp4, i64 %3), !dbg !36
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !37 {
  entry:
    store i64 0, ptr @schmu_f, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_fst, ptr align 8 @schmu_f, i64 8, i1 false)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_snd, ptr align 8 @schmu_fst, i64 8, i1 false)
    store i64 1, ptr @schmu_fst, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 1), !dbg !38
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %0 = load i64, ptr @schmu_f, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp1, i64 %0), !dbg !39
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %1 = load i64, ptr @schmu_snd, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp4, i64 %1), !dbg !40
    call void @schmu_new_fun(), !dbg !41
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu mut_alias.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./mut_alias
  1
  0
  0
  1
  0
  0

Const let
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu const_let.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_v = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_const = global i64 0, align 8
  
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
  
  define void @schmu_in_fun() !dbg !32 {
  entry:
    %0 = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 8)
    store ptr %1, ptr %0, align 8
    store i64 0, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 0, ptr %2, align 8
    store i64 1, ptr %1, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 1), !dbg !34
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp4, i64 0), !dbg !35
    call void @__free_a.l(ptr %0)
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
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !36 {
  entry:
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_v, i32 0, i32 1), align 8
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_v, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 8)
    store ptr %0, ptr @schmu_v, align 8
    store i64 0, ptr %0, align 8
    %1 = load ptr, ptr @schmu_v, align 8
    %2 = load i64, ptr %1, align 8
    store i64 %2, ptr @schmu_const, align 8
    store i64 1, ptr %1, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %3 = load ptr, ptr @schmu_v, align 8
    %4 = load i64, ptr %3, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %4), !dbg !37
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %5 = load i64, ptr @schmu_const, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp1, i64 %5), !dbg !38
    call void @schmu_in_fun(), !dbg !39
    call void @__free_a.l(ptr @schmu_v)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu const_let.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./const_let
  1
  0
  1
  0


Copies, but with ref-counted arrays
  $ schmu array_copies.smu --dump-llvm -c --target x86_64-unknown-linux-gnu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_b = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_c = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_d = global { ptr, i64, i64 } zeroinitializer, align 8
  @0 = private unnamed_addr constant [7 x i8] c"in fun\00"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_println(ptr %0)
  
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
  
  define void @schmu_in_fun() !dbg !32 {
  entry:
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 6, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !34
    %0 = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %1 = call ptr @malloc(i64 8)
    store ptr %1, ptr %0, align 8
    store i64 10, ptr %1, align 8
    %2 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %0, i64 24, i1 false)
    call void @__copy_a.l(ptr %2)
    %3 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %0, i64 24, i1 false)
    call void @__copy_a.l(ptr %3)
    store i64 12, ptr %1, align 8
    call void @schmu_print_0th(ptr %0), !dbg !35
    %4 = load ptr, ptr %3, align 8
    store i64 15, ptr %4, align 8
    call void @schmu_print_0th(ptr %0), !dbg !36
    call void @schmu_print_0th(ptr %2), !dbg !37
    call void @schmu_print_0th(ptr %3), !dbg !38
    call void @schmu_print_0th(ptr %2), !dbg !39
    call void @__free_a.l(ptr %3)
    call void @__free_a.l(ptr %2)
    call void @__free_a.l(ptr %0)
    ret void
  }
  
  define void @schmu_print_0th(ptr %a) !dbg !40 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = load ptr, ptr %a, align 8
    %1 = load i64, ptr %0, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %1), !dbg !41
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !42 {
  entry:
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 8)
    store ptr %0, ptr @schmu_a, align 8
    store i64 10, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 24, i1 false)
    tail call void @__copy_a.l(ptr @schmu_b)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_c, ptr align 8 @schmu_a, i64 24, i1 false)
    tail call void @__copy_a.l(ptr @schmu_c)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_d, ptr align 8 @schmu_b, i64 24, i1 false)
    %1 = load ptr, ptr @schmu_a, align 8
    store i64 12, ptr %1, align 8
    tail call void @schmu_print_0th(ptr @schmu_a), !dbg !43
    %2 = load ptr, ptr @schmu_c, align 8
    store i64 15, ptr %2, align 8
    tail call void @schmu_print_0th(ptr @schmu_a), !dbg !44
    tail call void @schmu_print_0th(ptr @schmu_b), !dbg !45
    tail call void @schmu_print_0th(ptr @schmu_c), !dbg !46
    tail call void @schmu_print_0th(ptr @schmu_d), !dbg !47
    tail call void @schmu_in_fun(), !dbg !48
    tail call void @__free_a.l(ptr @schmu_c)
    tail call void @__free_a.l(ptr @schmu_b)
    tail call void @__free_a.l(ptr @schmu_a)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu array_copies.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./array_copies
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
  $ schmu array_in_record_copies.smu --dump-llvm -c --target x86_64-unknown-linux-gnu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %arrec = type { { ptr, i64, i64 } }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global %arrec zeroinitializer, align 8
  @schmu_b = global %arrec zeroinitializer, align 8
  @0 = private unnamed_addr constant [7 x i8] c"in fun\00"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_println(ptr %0)
  
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
  
  define void @schmu_in_fun() !dbg !32 {
  entry:
    %0 = alloca %arrec, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 8)
    store ptr %1, ptr %0, align 8
    store i64 10, ptr %1, align 8
    %2 = alloca %arrec, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %0, i64 24, i1 false)
    call void @__copy_arrec(ptr %2)
    store i64 12, ptr %1, align 8
    call void @schmu_print_thing(ptr %0), !dbg !34
    call void @schmu_print_thing(ptr %2), !dbg !35
    call void @__free_arrec(ptr %2)
    call void @__free_arrec(ptr %0)
    ret void
  }
  
  define void @schmu_print_thing(ptr %a) !dbg !36 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = load ptr, ptr %a, align 8
    %1 = load i64, ptr %0, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %1), !dbg !37
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
  
  define linkonce_odr void @__copy_arrec(ptr %0) {
  entry:
    tail call void @__copy_a.l(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_arrec(ptr %0) {
  entry:
    tail call void @__free_a.l(ptr %0)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !38 {
  entry:
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 8)
    store ptr %0, ptr @schmu_a, align 8
    store i64 10, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 24, i1 false)
    tail call void @__copy_arrec(ptr @schmu_b)
    %1 = load ptr, ptr @schmu_a, align 8
    store i64 12, ptr %1, align 8
    tail call void @schmu_print_thing(ptr @schmu_a), !dbg !39
    tail call void @schmu_print_thing(ptr @schmu_b), !dbg !40
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 6, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !41
    call void @schmu_in_fun(), !dbg !42
    call void @__free_arrec(ptr @schmu_b)
    call void @__free_arrec(ptr @schmu_a)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu array_in_record_copies.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./array_in_record_copies
  12
  10
  in fun
  12
  10

Nested arrays
  $ schmu nested_array.smu --dump-llvm -c --target x86_64-unknown-linux-gnu 2>&1 | grep -v !DI
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
  @schmu_a = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_b = global { ptr, i64, i64 } zeroinitializer, align 8
  @0 = private unnamed_addr constant [8 x i8] c"{}, {}\0A\00"
  
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
  
  define linkonce_odr void @__fmt_stdout_print2_ll(ptr %fmtstr, ptr %f0, i64 %v0, ptr %f1, i64 %v1) !dbg !30 {
  entry:
    %__fun_fmt_stdout3_ll = alloca %closure, align 8
    store ptr @__fun_fmt_stdout3_ll, ptr %__fun_fmt_stdout3_ll, align 8
    %clsr___fun_fmt_stdout3_ll = alloca { ptr, ptr, %closure, %closure, i64, i64 }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_ll, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %f12 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_ll, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f12, ptr align 1 %f1, i64 16, i1 false)
    %v03 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_ll, i32 0, i32 4
    store i64 %v0, ptr %v03, align 8
    %v14 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_ll, i32 0, i32 5
    store i64 %v1, ptr %v14, align 8
    store ptr @__ctor_tp.fmt.formatter.t.ulrfmt.formatter.t.ufmt.formatter.t.ulrfmt.formatter.t.ull, ptr %clsr___fun_fmt_stdout3_ll, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %clsr___fun_fmt_stdout3_ll, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout3_ll, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout3_ll, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout3_ll), !dbg !31
    %0 = getelementptr inbounds %tp.lfmt.formatter.t.u, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 2
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
  
  define linkonce_odr void @__fun_fmt_stdout3_ll(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !41 {
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
    tail call void @__fmt_stdout_impl_fmt_fail_missing_fmt.formatter.t.u(ptr %0), !dbg !46
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
  
  define void @schmu_prnt(ptr %a) !dbg !51 {
  entry:
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 7, i64 -1 }, ptr %boxconst, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = load ptr, ptr %a, align 8
    %1 = load ptr, ptr %0, align 8
    %2 = load i64, ptr %1, align 8
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %3 = getelementptr { ptr, i64, i64 }, ptr %0, i64 1
    %4 = load ptr, ptr %3, align 8
    %5 = load i64, ptr %4, align 8
    call void @__fmt_stdout_print2_ll(ptr %boxconst, ptr %clstmp, i64 %2, ptr %clstmp2, i64 %5), !dbg !53
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
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp.fmt.formatter.t.ulrfmt.formatter.t.ufmt.formatter.t.ulrfmt.formatter.t.ull(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 64)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 64, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 2
    tail call void @__copy_fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f0)
    %f1 = getelementptr inbounds { ptr, ptr, %closure, %closure, i64, i64 }, ptr %1, i32 0, i32 3
    tail call void @__copy_fmt.formatter.t.ulrfmt.formatter.t.u(ptr %f1)
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !54 {
  entry:
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 48)
    store ptr %0, ptr @schmu_a, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 8)
    store ptr %1, ptr %0, align 8
    store i64 10, ptr %1, align 8
    %"1" = getelementptr { ptr, i64, i64 }, ptr %0, i64 1
    %len2 = getelementptr inbounds { ptr, i64, i64 }, ptr %"1", i32 0, i32 1
    store i64 1, ptr %len2, align 8
    %cap3 = getelementptr inbounds { ptr, i64, i64 }, ptr %"1", i32 0, i32 2
    store i64 1, ptr %cap3, align 8
    %2 = tail call ptr @malloc(i64 8)
    store ptr %2, ptr %"1", align 8
    store i64 20, ptr %2, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 24, i1 false)
    tail call void @__copy_a.a.l(ptr @schmu_b)
    %3 = load ptr, ptr @schmu_a, align 8
    %4 = load ptr, ptr %3, align 8
    store i64 15, ptr %4, align 8
    tail call void @schmu_prnt(ptr @schmu_a), !dbg !55
    tail call void @schmu_prnt(ptr @schmu_b), !dbg !56
    tail call void @__free_a.a.l(ptr @schmu_b)
    tail call void @__free_a.a.l(ptr @schmu_a)
    ret i64 0
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
  
  define linkonce_odr void @__copy_a.a.l(ptr %0) {
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
    tail call void @__copy_a.l(ptr %scevgep)
    %8 = add i64 %5, 1
    store i64 %8, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
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
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu nested_array.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./nested_array
  15, 20
  10, 20


Modify in function
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu modify_in_fn.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %f = type { i64 }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global %f zeroinitializer, align 8
  @schmu_b = global { ptr, i64, i64 } zeroinitializer, align 8
  @0 = private unnamed_addr constant [15 x i8] c"__array_push_l\00"
  @1 = private unnamed_addr constant [10 x i8] c"array.smu\00"
  @2 = private unnamed_addr constant [15 x i8] c"file not found\00"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @prelude_power_2_above_or_equal(i64 %0, i64 %1)
  
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
  
  define linkonce_odr void @__array_push_l(ptr noalias %arr, i64 %value) !dbg !7 {
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
    %4 = tail call ptr @malloc(i64 32)
    store ptr %4, ptr %arr, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 4, ptr %sunkaddr, align 8
    br label %ifcont12
  
  fail:                                             ; preds = %then2
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 91, ptr @0), !dbg !10
    unreachable
  
  else:                                             ; preds = %then
    %5 = load ptr, ptr %arr, align 8
    %6 = icmp eq ptr %5, null
    %7 = xor i1 %6, true
    br i1 %7, label %success6, label %fail7, !dbg !11
  
  success6:                                         ; preds = %else
    %add = add i64 %0, 1
    %8 = tail call i64 @prelude_power_2_above_or_equal(i64 %0, i64 %add), !dbg !12
    %size = mul i64 %8, 8
    %9 = tail call ptr @realloc(ptr %5, i64 %size)
    store ptr %9, ptr %arr, align 8
    %sunkaddr16 = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 %8, ptr %sunkaddr16, align 8
    br label %ifcont12
  
  fail7:                                            ; preds = %else
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 95, ptr @0), !dbg !11
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
  
  define linkonce_odr void @__fmt_endl_u(ptr %p) !dbg !13 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !15
    call void @__fmt_formatter_extract_u(ptr %ret), !dbg !16
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_u(ptr %fm) !dbg !17 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !18 {
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
  
  define linkonce_odr void @__fmt_int_base_u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !20 {
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
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !22
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
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !25
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_u(ptr noalias %0, ptr %p, i64 %i) !dbg !26 {
  entry:
    tail call void @__fmt_int_base_u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !27
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_l(ptr %fmt, i64 %value) !dbg !28 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !29
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !30
    call void @__fmt_endl_u(ptr %ret2), !dbg !31
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
    tail call void @__array_fixed_swap_items_cA64.u(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !33
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
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !35
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !36
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !37
    br i1 %lt, label %then4, label %ifcont, !dbg !37
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_mod2(ptr noalias %a) !dbg !38 {
  entry:
    tail call void @__array_push_l(ptr %a, i64 20), !dbg !40
    ret void
  }
  
  define void @schmu_modify(ptr noalias %r) !dbg !41 {
  entry:
    store i64 30, ptr %r, align 8
    ret void
  }
  
  declare void @prelude_assert_fail(ptr %0, ptr %1, i32 %2, ptr %3)
  
  declare ptr @malloc(i64 %0)
  
  declare ptr @realloc(ptr %0, i64 %1)
  
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !42 {
  entry:
    store i64 20, ptr @schmu_a, align 8
    tail call void @schmu_modify(ptr @schmu_a), !dbg !43
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = load i64, ptr @schmu_a, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %0), !dbg !44
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_b, i32 0, i32 1), align 8
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_b, i32 0, i32 2), align 8
    %1 = call ptr @malloc(i64 8)
    store ptr %1, ptr @schmu_b, align 8
    store i64 10, ptr %1, align 8
    call void @schmu_mod2(ptr @schmu_b), !dbg !45
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %2 = load i64, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_b, i32 0, i32 1), align 8
    call void @__fmt_stdout_println_l(ptr %clstmp1, i64 %2), !dbg !46
    call void @__free_a.l(ptr @schmu_b)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu modify_in_fn.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./modify_in_fn
  30
  2

Make sure variable ids are correctly propagated
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu varid_propagate.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant [15 x i8] c"__array_push_l\00"
  @1 = private unnamed_addr constant [10 x i8] c"array.smu\00"
  @2 = private unnamed_addr constant [15 x i8] c"file not found\00"
  
  declare i64 @prelude_power_2_above_or_equal(i64 %0, i64 %1)
  
  define linkonce_odr void @__array_push_l(ptr noalias %arr, i64 %value) !dbg !2 {
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
    %4 = tail call ptr @malloc(i64 32)
    store ptr %4, ptr %arr, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 4, ptr %sunkaddr, align 8
    br label %ifcont12
  
  fail:                                             ; preds = %then2
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 91, ptr @0), !dbg !8
    unreachable
  
  else:                                             ; preds = %then
    %5 = load ptr, ptr %arr, align 8
    %6 = icmp eq ptr %5, null
    %7 = xor i1 %6, true
    br i1 %7, label %success6, label %fail7, !dbg !9
  
  success6:                                         ; preds = %else
    %add = add i64 %0, 1
    %8 = tail call i64 @prelude_power_2_above_or_equal(i64 %0, i64 %add), !dbg !10
    %size = mul i64 %8, 8
    %9 = tail call ptr @realloc(ptr %5, i64 %size)
    store ptr %9, ptr %arr, align 8
    %sunkaddr16 = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 %8, ptr %sunkaddr16, align 8
    br label %ifcont12
  
  fail7:                                            ; preds = %else
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 95, ptr @0), !dbg !9
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
  
  define linkonce_odr void @__schmu_f1_l(ptr noalias %0, ptr %acc, i64 %v) !dbg !11 {
  entry:
    %1 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %acc, i64 24, i1 false)
    call void @__copy_a.l(ptr %1)
    call void @__array_push_l(ptr %1, i64 %v), !dbg !13
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 24, i1 false)
    ret void
  }
  
  declare void @prelude_assert_fail(ptr %0, ptr %1, i32 %2, ptr %3)
  
  declare ptr @malloc(i64 %0)
  
  declare ptr @realloc(ptr %0, i64 %1)
  
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
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !14 {
  entry:
    %arr = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %0 = tail call ptr @malloc(i64 8)
    store ptr %0, ptr %arr, align 8
    store i64 0, ptr %0, align 8
    %ret = alloca { ptr, i64, i64 }, align 8
    call void @__schmu_f1_l(ptr %ret, ptr %arr, i64 0), !dbg !15
    call void @__free_a.l(ptr %ret)
    call void @__free_a.l(ptr %arr)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu varid_propagate.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./varid_propagate

Free array params correctly if they are returned
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu pass_array_param.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr void @__schmu_pass_a.l(ptr noalias %0, ptr %x) !dbg !2 {
  entry:
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %x, i64 24, i1 false)
    ret void
  }
  
  define void @schmu_create(ptr noalias %0) !dbg !6 {
  entry:
    %arr = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 8)
    store ptr %1, ptr %arr, align 8
    store i64 10, ptr %1, align 8
    call void @__schmu_pass_a.l(ptr %0, ptr %arr), !dbg !7
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !8 {
  entry:
    %ret = alloca { ptr, i64, i64 }, align 8
    call void @schmu_create(ptr %ret), !dbg !9
    call void @__free_a.l(ptr %ret)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu pass_array_param.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./pass_array_param

Refcounts for members in arrays, records and variants
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu member_refcounts.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %r = type { { ptr, i64, i64 } }
  %option.t.a.l = type { i32, { ptr, i64, i64 } }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_a = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_r = global %r zeroinitializer, align 8
  @schmu_r__2 = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_r__3 = global %option.t.a.l zeroinitializer, align 8
  @0 = private unnamed_addr constant [5 x i8] c"none\00"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_println(ptr %0)
  
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !32 {
  entry:
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_a, i32 0, i32 2), align 8
    %0 = tail call ptr @malloc(i64 8)
    store ptr %0, ptr @schmu_a, align 8
    store i64 10, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_r, ptr align 8 @schmu_a, i64 24, i1 false)
    tail call void @__copy_a.l(ptr @schmu_r)
    %1 = load ptr, ptr @schmu_a, align 8
    store i64 20, ptr %1, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %2 = load ptr, ptr @schmu_r, align 8
    %3 = load i64, ptr %2, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 %3), !dbg !34
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_r__2, i32 0, i32 1), align 8
    store i64 1, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_r__2, i32 0, i32 2), align 8
    %4 = call ptr @malloc(i64 24)
    store ptr %4, ptr @schmu_r__2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 8 @schmu_a, i64 24, i1 false)
    call void @__copy_a.l(ptr %4)
    %5 = load ptr, ptr @schmu_a, align 8
    store i64 30, ptr %5, align 8
    %clstmp2 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    %6 = load ptr, ptr @schmu_r__2, align 8
    %7 = load ptr, ptr %6, align 8
    %8 = load i64, ptr %7, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp2, i64 %8), !dbg !35
    store i32 1, ptr @schmu_r__3, align 4
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 getelementptr inbounds (%option.t.a.l, ptr @schmu_r__3, i32 0, i32 1), ptr align 8 @schmu_a, i64 24, i1 false)
    call void @__copy_a.l(ptr getelementptr inbounds (%option.t.a.l, ptr @schmu_r__3, i32 0, i32 1))
    %9 = load ptr, ptr @schmu_a, align 8
    store i64 40, ptr %9, align 8
    %index = load i32, ptr @schmu_r__3, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !36
  
  then:                                             ; preds = %entry
    %clstmp5 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp5, align 8
    %envptr7 = getelementptr inbounds %closure, ptr %clstmp5, i32 0, i32 1
    store ptr null, ptr %envptr7, align 8
    %10 = load ptr, ptr getelementptr inbounds (%option.t.a.l, ptr @schmu_r__3, i32 0, i32 1), align 8
    %11 = load i64, ptr %10, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp5, i64 %11), !dbg !37
    br label %ifcont
  
  else:                                             ; preds = %entry
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 4, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !38
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
  
  define linkonce_odr void @__free_r(ptr %0) {
  entry:
    tail call void @__free_a.l(ptr %0)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu member_refcounts.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./member_refcounts
  10
  20
  30

Make sure there are no hidden reference semantics in pattern matches
  $ schmu hidden_match_reference.smu && ./hidden_match_reference
  1

Convert Const_ptr values to Ptr in copy
  $ schmu ref_to_const.smu

Fix codegen
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu codegen_nested_projections.smu 2>&1 | grep -v !DI
  codegen_nested_projections.smu:4.11-12: warning: Unused binding z
  
  4 |   let mut z = mut y
                ^
  
  codegen_nested_projections.smu:1.5-6: warning: Unused binding t
  
  1 | fun t() {
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
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
  
  !5 = !{}

Partial move parameter
  $ schmu partially_move_parameter.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./partially_move_parameter

Partial move set
  $ schmu partial_move_set.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./partial_move_set

Track unmutated binding warnings across projections
  $ schmu projection_warnings.smu
  projection_warnings.smu:9.23-24: warning: Unused binding b
  
  9 | fun testfn(mut a, mut b : int) {
                            ^
  
  projection_warnings.smu:14.11-12: warning: Unmutated mutable binding a
  
  14 |   let mut a = 0
                 ^
  
  projection_warnings.smu:4.11-12: warning: Unused binding z
  
  4 |   let mut z = mut y
                ^
  
  projection_warnings.smu:9.5-11: warning: Unused binding testfn
  
  9 | fun testfn(mut a, mut b : int) {
          ^^^^^^
  
  projection_warnings.smu:13.5-18: warning: Unused binding single_binder
  
  13 | fun single_binder() {
           ^^^^^^^^^^^^^
  
  projection_warnings.smu:17.9-14: warning: Unmutated mutable binding outer
  
  17 | let mut outer = 10
               ^^^^^
  
  projection_warnings.smu:19.5-17: warning: Unused binding mutate_outer
  
  19 | fun mutate_outer() {
           ^^^^^^^^^^^^
  
Mutable locals must not be globals even if constexpr
  $ schmu mutable_locals.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./mutable_locals
  false
  false
  false

Partial moves out of variants with in arrays with dynamic indices
  $ schmu dyn_partial_move.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./dyn_partial_move

Nested simple borrow call
  $ schmu borrow_call_nest.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./borrow_call_nest
  some: 3
  12

Move variables directly in 'once' context
  $ schmu borrow_call_move_once.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./borrow_call_move_once

Explicit borrow moves
  $ schmu borrow_moves.smu --dump-llvm -c --target x86_64-unknown-linux-gnu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %rr.tp.a.ll = type { %tp.a.ll }
  %tp.a.ll = type { { ptr, i64, i64 }, i64 }
  %rr.a.l = type { { ptr, i64, i64 } }
  %option.t.a.l = type { i32, { ptr, i64, i64 } }
  
  define linkonce_odr i64 @__schmu_mm_l(ptr %thing) !dbg !2 {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %thing, i32 0, i32 1
    %0 = load i64, ptr %len, align 8
    ret i64 %0
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    %arr = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %0 = tail call ptr @malloc(i64 8)
    store ptr %0, ptr %arr, align 8
    store i64 0, ptr %0, align 8
    %1 = alloca %rr.tp.a.ll, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %arr, i64 24, i1 false)
    %"1" = getelementptr inbounds %tp.a.ll, ptr %1, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    %2 = alloca %rr.a.l, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %arr, i64 24, i1 false)
    %3 = call i64 @__schmu_mm_l(ptr %2), !dbg !7
    %t = alloca %option.t.a.l, align 8
    store i32 1, ptr %t, align 4
    %data3 = getelementptr inbounds %option.t.a.l, ptr %t, i32 0, i32 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %data3, ptr align 8 %arr, i64 24, i1 false)
    call void @__free_a.l(ptr %arr)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu borrow_moves.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./borrow_moves
