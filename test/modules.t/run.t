Simplest module with 1 type and 1 nonpolymorphic function
  $ schmu nonpoly_func.smu -m --dump-llvm 2>&1 | grep -v !DI
  nonpoly_func.smu:4.7-8: warning: Unused binding c.
  
  4 |   let c = 10
            ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @nonpoly_func_c = internal constant i64 10
  
  define i64 @nonpoly_func_add_ints(i64 %a, i64 %b) !dbg !2 {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ cat nonpoly_func.smi | sed -E 's/([0-9]+:\/.*lib\/schmu\/std)//'
  (()((5:Mtype(((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:0))((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum2:26)))6:either((6:params())(4:kind(8:Dvariant((12:is_recursive5:false)(8:has_base4:true)(17:params_behind_ptr5:false))(((5:cname4:left)(4:ctyp())(5:index1:0))((5:cname5:right)(4:ctyp())(5:index1:1)))))(6:in_sgn5:false)(14:contains_alloc5:false)))(4:Mfun(((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:28)(8:pos_cnum2:32))((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:6)(7:pos_bol2:70)(8:pos_cnum2:71)))(4:Tfun(((2:pt(7:Tconstr3:int()5:false))(5:pattr5:Dnorm)(5:pmode(6:Iknown4:Many)))((2:pt(7:Tconstr3:int()5:false))(5:pattr5:Dnorm)(5:pmode(6:Iknown4:Many))))(7:Tconstr3:int()5:false)6:Simple)((4:user8:add_ints)(4:call((8:add_ints(12:nonpoly_func)()))))))((/std/string5:false)))

  $ schmu import_nonpoly_func.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare i64 @nonpoly_func_add_ints(i64 %0, i64 %1)
  
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
    %5 = load ptr, ptr @fmt_int_digits, align 8
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !29
    store i8 %6, ptr %scevgep10, align 1
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
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_doo(i32 %0) !dbg !32 {
  entry:
    %a = alloca i32, align 4
    store i32 %0, ptr %a, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else, !dbg !34
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5), !dbg !35
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5), !dbg !36
    ret i64 %2
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
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = tail call i64 @schmu_doo(i32 0), !dbg !38
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %0), !dbg !39
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ ./import_nonpoly_func
  5

  $ schmu local_import_nonpoly_func.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare i64 @nonpoly_func_add_ints(i64 %0, i64 %1)
  
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
    %5 = load ptr, ptr @fmt_int_digits, align 8
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !29
    store i8 %6, ptr %scevgep10, align 1
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
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_do2(i32 %0) !dbg !32 {
  entry:
    %a = alloca i32, align 4
    store i32 %0, ptr %a, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else, !dbg !34
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5), !dbg !35
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5), !dbg !36
    ret i64 %2
  }
  
  define i64 @schmu_doo(i32 %0) !dbg !37 {
  entry:
    %a = alloca i32, align 4
    store i32 %0, ptr %a, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else, !dbg !38
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5), !dbg !39
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5), !dbg !40
    ret i64 %2
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !41 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = tail call i64 @schmu_doo(i32 0), !dbg !42
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %0), !dbg !43
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %1 = call i64 @schmu_do2(i32 0), !dbg !44
    call void @__fmt_stdout_println__ll(ptr %clstmp1, i64 %1), !dbg !45
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ ./local_import_nonpoly_func
  5
  5

  $ schmu lets.smu -m --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @lets_a = constant i64 12
  @lets_a__2 = constant i64 11
  @lets_b = global i64 0, align 8
  @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__lets_init, ptr null }]
  
  define i64 @lets_generate_b() !dbg !2 {
  entry:
    ret i64 21
  }
  
  define internal void @__lets_init() section ".text.startup" !dbg !6 {
  entry:
    %0 = tail call i64 @lets_generate_b(), !dbg !7
    store i64 %0, ptr @lets_b, align 8
    ret void
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}

  $ schmu import_lets.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @lets_b = external global i64
  @lets_a__2 = external global i64
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare void @printf(ptr %0, i64 %1)
  
  define void @schmu_inside_fn() !dbg !2 {
  entry:
    tail call void @schmu_second(), !dbg !6
    ret void
  }
  
  define void @schmu_second() !dbg !7 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !8
    %1 = load i64, ptr @lets_a__2, align 8
    tail call void @printf(ptr %0, i64 %1), !dbg !9
    %2 = tail call ptr @string_data(ptr @0), !dbg !10
    %3 = load i64, ptr @lets_b, align 8
    tail call void @printf(ptr %2, i64 %3), !dbg !11
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !12 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !13
    %1 = load i64, ptr @lets_a__2, align 8
    tail call void @printf(ptr %0, i64 %1), !dbg !14
    %2 = tail call ptr @string_data(ptr @0), !dbg !15
    %3 = load i64, ptr @lets_b, align 8
    tail call void @printf(ptr %2, i64 %3), !dbg !16
    tail call void @schmu_inside_fn(), !dbg !17
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ ./import_lets
  11
  21
  11
  21

  $ schmu local_import_lets.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @lets_b = external global i64
  @lets_a__2 = external global i64
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare void @printf(ptr %0, i64 %1)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !6
    %1 = load i64, ptr @lets_a__2, align 8
    tail call void @printf(ptr %0, i64 %1), !dbg !7
    %2 = tail call ptr @string_data(ptr @0), !dbg !8
    %3 = load i64, ptr @lets_b, align 8
    tail call void @printf(ptr %2, i64 %3), !dbg !9
    %4 = tail call ptr @string_data(ptr @0), !dbg !10
    %5 = load i64, ptr @lets_a__2, align 8
    tail call void @printf(ptr %4, i64 %5), !dbg !11
    %6 = tail call ptr @string_data(ptr @0), !dbg !12
    %7 = load i64, ptr @lets_b, align 8
    tail call void @printf(ptr %6, i64 %7), !dbg !13
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ ./local_import_lets
  11
  21
  11
  21

  $ schmu -m --dump-llvm poly_func.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  !llvm.dbg.cu = !{!0}
  

  $ schmu import_poly_func.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %poly_func.option.d = type { i32, double }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %poly_func.option.l = type { i32, i64 }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_none = constant %poly_func.option.d { i32 1, double undef }
  
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
  
  define linkonce_odr i64 @__poly_func_classify_poly_func.option.d(i32 %0, double %1) !dbg !28 {
  entry:
    %thing = alloca { i32, double }, align 8
    store i32 %0, ptr %thing, align 4
    %snd = getelementptr inbounds { i32, double }, ptr %thing, i32 0, i32 1
    store double %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !30
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @__poly_func_classify_poly_func.option.l(i32 %0, i64 %1) !dbg !31 {
  entry:
    %thing = alloca { i32, i64 }, align 8
    store i32 %0, ptr %thing, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %thing, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !32
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !33 {
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
    %5 = load ptr, ptr @fmt_int_digits, align 8
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !34
    store i8 %6, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !35
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !36
    br i1 %lt, label %then4, label %ifcont, !dbg !36
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
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
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %boxconst = alloca %poly_func.option.l, align 8
    store %poly_func.option.l { i32 0, i64 3 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %0 = tail call i64 @__poly_func_classify_poly_func.option.l(i32 %fst1, i64 %snd2), !dbg !39
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %0), !dbg !40
    %clstmp3 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp3, align 8
    %envptr5 = getelementptr inbounds %closure, ptr %clstmp3, i32 0, i32 1
    store ptr null, ptr %envptr5, align 8
    %boxconst6 = alloca %poly_func.option.d, align 8
    store %poly_func.option.d { i32 0, double 3.000000e+00 }, ptr %boxconst6, align 8
    %fst8 = load i32, ptr %boxconst6, align 4
    %snd9 = getelementptr inbounds { i32, double }, ptr %boxconst6, i32 0, i32 1
    %snd10 = load double, ptr %snd9, align 8
    %1 = call i64 @__poly_func_classify_poly_func.option.d(i32 %fst8, double %snd10), !dbg !41
    call void @__fmt_stdout_println__ll(ptr %clstmp3, i64 %1), !dbg !42
    %clstmp11 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    %2 = call i64 @__poly_func_classify_poly_func.option.d(i32 1, double undef), !dbg !43
    call void @__fmt_stdout_println__ll(ptr %clstmp11, i64 %2), !dbg !44
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ ./import_poly_func
  0
  0
  1

  $ schmu local_import_poly_func.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %poly_func.option.d = type { i32, double }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %poly_func.option.l = type { i32, i64 }
  
  @fmt_int_digits = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_none = constant %poly_func.option.d { i32 1, double undef }
  
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
  
  define linkonce_odr i64 @__poly_func_classify_poly_func.option.d(i32 %0, double %1) !dbg !28 {
  entry:
    %thing = alloca { i32, double }, align 8
    store i32 %0, ptr %thing, align 4
    %snd = getelementptr inbounds { i32, double }, ptr %thing, i32 0, i32 1
    store double %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !30
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @__poly_func_classify_poly_func.option.l(i32 %0, i64 %1) !dbg !31 {
  entry:
    %thing = alloca { i32, i64 }, align 8
    store i32 %0, ptr %thing, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %thing, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %ifcont, label %else, !dbg !32
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !33 {
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
    %5 = load ptr, ptr @fmt_int_digits, align 8
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !34
    store i8 %6, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !35
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %7 = add i64 %lsr.iv, -1, !dbg !36
    br i1 %lt, label %then4, label %ifcont, !dbg !36
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
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
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %boxconst = alloca %poly_func.option.l, align 8
    store %poly_func.option.l { i32 0, i64 3 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %0 = tail call i64 @__poly_func_classify_poly_func.option.l(i32 %fst1, i64 %snd2), !dbg !39
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %0), !dbg !40
    %clstmp3 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp3, align 8
    %envptr5 = getelementptr inbounds %closure, ptr %clstmp3, i32 0, i32 1
    store ptr null, ptr %envptr5, align 8
    %boxconst6 = alloca %poly_func.option.d, align 8
    store %poly_func.option.d { i32 0, double 3.000000e+00 }, ptr %boxconst6, align 8
    %fst8 = load i32, ptr %boxconst6, align 4
    %snd9 = getelementptr inbounds { i32, double }, ptr %boxconst6, i32 0, i32 1
    %snd10 = load double, ptr %snd9, align 8
    %1 = call i64 @__poly_func_classify_poly_func.option.d(i32 %fst8, double %snd10), !dbg !41
    call void @__fmt_stdout_println__ll(ptr %clstmp3, i64 %1), !dbg !42
    %clstmp11 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp11, align 8
    %envptr13 = getelementptr inbounds %closure, ptr %clstmp11, i32 0, i32 1
    store ptr null, ptr %envptr13, align 8
    %2 = call i64 @__poly_func_classify_poly_func.option.d(i32 1, double undef), !dbg !43
    call void @__fmt_stdout_println__ll(ptr %clstmp11, i64 %2), !dbg !44
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ ./local_import_poly_func
  0
  0
  1

  $ schmu -m malloc_some.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @malloc_some_a = constant i64 12
  @malloc_some_b = global i64 0, align 8
  @malloc_some_vtest = global ptr null, align 8
  @malloc_some_vtest2 = global ptr null, align 8
  @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__malloc_some_init, ptr null }]
  @llvm.global_dtors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__malloc_some_deinit, ptr null }]
  
  define i64 @malloc_some_add_ints(i64 %a, i64 %b) !dbg !2 {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define internal void @__malloc_some_init() section ".text.startup" !dbg !6 {
  entry:
    %0 = tail call i64 @malloc_some_add_ints(i64 1, i64 3), !dbg !7
    store i64 %0, ptr @malloc_some_b, align 8
    %1 = tail call ptr @malloc(i64 32)
    store ptr %1, ptr @malloc_some_vtest, align 8
    store i64 2, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 0, ptr %2, align 8
    %"1" = getelementptr i64, ptr %2, i64 1
    store i64 1, ptr %"1", align 8
    %3 = tail call ptr @malloc(i64 24)
    store ptr %3, ptr @malloc_some_vtest2, align 8
    store i64 1, ptr %3, align 8
    %cap2 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap2, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 3, ptr %4, align 8
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define internal void @__malloc_some_deinit() section ".text.startup" !dbg !8 {
  entry:
    tail call void @__free_a.l(ptr @malloc_some_vtest2)
    tail call void @__free_a.l(ptr @malloc_some_vtest)
    ret void
  }
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}

  $ cat malloc_some.smi | sed -E 's/([0-9]+:\/.*lib\/schmu\/std)//'
  (()((5:Mtype(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:0))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum2:29)))6:either((6:params())(4:kind(8:Dvariant((12:is_recursive5:false)(8:has_base4:true)(17:params_behind_ptr5:false))(((5:cname4:left)(4:ctyp())(5:index1:4))((5:cname5:right)(4:ctyp())(5:index1:5)))))(6:in_sgn5:false)(14:contains_alloc5:false)))(4:Mfun(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:3)(7:pos_bol2:31)(8:pos_cnum2:35))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:3)(7:pos_bol2:31)(8:pos_cnum2:57)))(4:Tfun(((2:pt(7:Tconstr3:int()5:false))(5:pattr5:Dnorm)(5:pmode(6:Iknown4:Many)))((2:pt(7:Tconstr3:int()5:false))(5:pattr5:Dnorm)(5:pmode(6:Iknown4:Many))))(7:Tconstr3:int()5:false)6:Simple)((4:user8:add_ints)(4:call((8:add_ints(11:malloc_some)())))))(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:5)(7:pos_bol2:59)(8:pos_cnum2:59))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:5)(7:pos_bol2:59)(8:pos_cnum2:69)))(7:Tconstr3:int()5:false)((4:user1:a)(4:call((1:a(11:malloc_some)()))))5:false)(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:7)(7:pos_bol2:71)(8:pos_cnum2:71))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:7)(7:pos_bol2:71)(8:pos_cnum2:93)))(7:Tconstr3:int()5:false)((4:user1:b)(4:call((1:b(11:malloc_some)()))))5:false)(9:Mpoly_fun(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum2:99))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:114)))((7:nparams(1:x))(4:body((3:typ(4:Qvar1:1))(4:expr(4:Move((3:typ(4:Qvar1:1))(4:expr(3:App(6:callee((3:typ(4:Tfun(((2:pt(4:Qvar1:1))(5:pattr5:Dnorm)(5:pmode(6:Iknown4:Many))))(4:Qvar1:1)6:Simple))(4:expr(3:Var4:copy()))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:106))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:110))))))(4:args((((3:typ(4:Qvar1:1))(4:expr(3:Var1:x()))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:111))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:112)))))5:Dnorm)))(11:borrow_call5:No_bc)))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:106))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:113)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:106))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:95)(8:pos_cnum3:113))))))(4:func((7:tparams(((2:pt(4:Qvar1:1))(5:pattr5:Dnorm)(5:pmode(6:Iknown4:Many)))))(3:ret(4:Qvar1:1))(4:kind6:Simple)(7:touched())))(6:inline5:false)(6:is_rec5:false))2:id())(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:11)(7:pos_bol3:116)(8:pos_cnum3:116))((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:11)(7:pos_bol3:116)(8:pos_cnum3:134)))(7:Tconstr5:array((7:Tconstr3:int()5:false))4:true)((4:user5:vtest)(4:call((5:vtest(11:malloc_some)()))))5:false)(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:12)(7:pos_bol3:135)(8:pos_cnum3:135))((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:12)(7:pos_bol3:135)(8:pos_cnum3:151)))(7:Tconstr5:array((7:Tconstr3:int()5:false))4:true)((4:user6:vtest2)(4:call((6:vtest2(11:malloc_some)()))))5:false))((/std/string5:false)))

  $ schmu use_malloc_some.smu --dump-llvm 2>&1 | grep -v !DI
  use_malloc_some.smu:5.5-17: warning: Unused binding do_something.
  
  5 | fun do_something(big) {
          ^^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @malloc_some_vtest = external global ptr
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare ptr @string_data(ptr %0)
  
  declare void @printf(ptr %0, i64 %1)
  
  define linkonce_odr i1 @__array_inner__2_Ca.l_lrb(i64 %i, ptr %0) !dbg !2 {
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
    br i1 %eq, label %ifcont5, label %else, !dbg !6
  
  else:                                             ; preds = %rec
    %5 = shl i64 %lsr.iv, 3
    %scevgep = getelementptr i8, ptr %arr1, i64 %5
    %scevgep6 = getelementptr i8, ptr %scevgep, i64 8
    %6 = load i64, ptr %scevgep6, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr7 = getelementptr inbounds i8, ptr %0, i64 32
    %loadtmp2 = load ptr, ptr %sunkaddr7, align 8
    %7 = tail call i1 %loadtmp(i64 %6, ptr %loadtmp2), !dbg !7
    br i1 %7, label %then3, label %ifcont5, !dbg !7
  
  then3:                                            ; preds = %else
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  ifcont5:                                          ; preds = %else, %rec
    ret i1 false
  }
  
  define linkonce_odr i1 @__array_iter_a.l_l(ptr %arr, ptr %cont) !dbg !8 {
  entry:
    %__array_inner__2_Ca.l_lrb = alloca %closure, align 8
    store ptr @__array_inner__2_Ca.l_lrb, ptr %__array_inner__2_Ca.l_lrb, align 8
    %clsr___array_inner__2_Ca.l_lrb = alloca { ptr, ptr, ptr, %closure }, align 8
    %arr1 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Ca.l_lrb, i32 0, i32 2
    store ptr %arr, ptr %arr1, align 8
    %cont2 = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Ca.l_lrb, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %cont2, ptr align 1 %cont, i64 16, i1 false)
    store ptr @__ctor_tp.a.l_lrb, ptr %clsr___array_inner__2_Ca.l_lrb, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %clsr___array_inner__2_Ca.l_lrb, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__array_inner__2_Ca.l_lrb, i32 0, i32 1
    store ptr %clsr___array_inner__2_Ca.l_lrb, ptr %envptr, align 8
    %0 = call i1 @__array_inner__2_Ca.l_lrb(i64 0, ptr %clsr___array_inner__2_Ca.l_lrb), !dbg !9
    ret i1 %0
  }
  
  define linkonce_odr i1 @__fun_iter6_lC_lru(i64 %x, ptr %0) !dbg !10 {
  entry:
    %f = getelementptr inbounds { ptr, ptr, %closure }, ptr %0, i32 0, i32 2
    %loadtmp = load ptr, ptr %f, align 8
    %envptr = getelementptr inbounds %closure, ptr %f, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(i64 %x, ptr %loadtmp1), !dbg !12
    ret i1 true
  }
  
  define i1 @__fun_schmu0(ptr %__curry0) !dbg !13 {
  entry:
    %0 = load ptr, ptr @malloc_some_vtest, align 8
    %1 = tail call i1 @__array_iter_a.l_l(ptr %0, ptr %__curry0), !dbg !15
    ret i1 %1
  }
  
  define linkonce_odr void @__iter_iter___l_l(ptr %it, ptr %f) !dbg !16 {
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
    %0 = call i1 %loadtmp(ptr %__fun_iter6_lC_lru, ptr %loadtmp3), !dbg !17
    ret void
  }
  
  define i64 @schmu_do_something(ptr %big) !dbg !18 {
  entry:
    %0 = load i64, ptr %big, align 8
    %add = add i64 %0, 1
    ret i64 %add
  }
  
  define void @schmu_printi(i64 %i) !dbg !19 {
  entry:
    %0 = tail call ptr @string_data(ptr @0), !dbg !20
    tail call void @printf(ptr %0, i64 %i), !dbg !21
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.a.l_lrb(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 40)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %arr = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 2
    tail call void @__copy_a.l(ptr %arr)
    %cont = getelementptr inbounds { ptr, ptr, ptr, %closure }, ptr %1, i32 0, i32 3
    tail call void @__copy__lrb(ptr %cont)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %size = load i64, ptr %1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = tail call ptr @malloc(i64 %3)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
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
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !22 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    store ptr @schmu_printi, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    call void @__iter_iter___l_l(ptr %clstmp, ptr %clstmp1), !dbg !23
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ valgrind -q --leak-check=yes --show-reachable=yes ./use_malloc_some
  0
  1

Allocate and clean init code with refcounting
  $ schmu init.smu -m
  $ schmu use_init.smu
  use_init.smu:3.5-9: warning: Unused module 'use' declaration init.
  
  3 | use init
          ^^^^
  
  $ ./use_init
  hello from init

Use module name prefix for function names to prevent linker dups
  $ schmu nameclash_mod.smu -m
  $ schmu nameclash_use.smu
  nameclash_use.smu:3.5-18: warning: Unused module 'use' declaration nameclash_mod.
  
  3 | use nameclash_mod
          ^^^^^^^^^^^^^
  
  nameclash_use.smu:4.5-18: warning: Unused binding specific_name.
  
  4 | fun specific_name() { () }
          ^^^^^^^^^^^^^
  
Distinguish closures and functions
  $ schmu decl_lambda.smu -m
  $ schmu use_lambda.smu
  $ ./use_lambda


Test signature
  $ schmu -m sign.smu
  sign.smu:22.5-11: warning: Unused binding hidden.
  
  22 | fun hidden(a) {
           ^^^^^^
  
  $ schmu use-sign.smu
  use-sign.smu:21.5-15: warning: Unused binding use_hidden.
  
  21 | fun use_hidden () {
           ^^^^^^^^^^
  
  $ ./use-sign
  hello 20
  200
  20
  $ schmu use-sign-hidden.smu
  use-sign-hidden.smu:6.1-7: error: No var named hidden.
  
  6 | hidden(10)
      ^^^^^^
  
  [1]
  $ schmu use-sign-hidden-type.smu
  use-sign-hidden-type.smu:5.9-20: error: Unbound type hidden_type.
  
  5 | let i : hidden_type = 10
              ^^^^^^^^^^^
  
  [1]

Polymorphic lambdas in modules
  $ schmu -m poly_lambda.smu
  $ schmu use_poly_lambda.smu


Local modules
  $ schmu --dump-llvm local_module.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %nosig.t = type { i64 }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.lfmt.formatter.t.u = type { i64, %fmt.formatter.t.u }
  
  @fmt_stdout_missing_arg_msg = external global ptr
  @fmt_stdout_too_many_arg_msg = external global ptr
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"test\00" }
  @schmu_local_value = constant ptr @0
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_test__2 = constant %nosig.t { i64 10 }
  @1 = private unnamed_addr constant { i64, i64, [13 x i8] } { i64 12, i64 12, [13 x i8] c"hey poly {}\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"hey thing\00" }
  @3 = private unnamed_addr constant { i64, i64, [11 x i8] } { i64 10, i64 10, [11 x i8] c"i'm nested\00" }
  @4 = private unnamed_addr constant { i64, i64, [9 x i8] } { i64 8, i64 8, [9 x i8] c"hey test\00" }
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare void @string_println(ptr %0)
  
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
  
  define linkonce_odr void @__fmt_stdout_print1__a.ca.c(ptr %fmtstr, ptr %f0, ptr %v0) !dbg !19 {
  entry:
    %__fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c = alloca %closure, align 8
    store ptr @__fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, ptr %__fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, align 8
    %clsr___fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c = alloca { ptr, ptr, %closure, ptr }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %v02 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, i32 0, i32 3
    store ptr %v0, ptr %v02, align 8
    store ptr @__ctor_tp._fmt.formatter.t.ua.crfmt.formatter.t.ua.c, ptr %clsr___fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %clsr___fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c), !dbg !20
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
  
  define linkonce_odr void @__fun_fmt_stdout2_C_fmt.formatter.t.ua.crfmt.formatter.t.ua.c(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !28 {
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
  
  define linkonce_odr void @__schmu_local_poly_test__a.ca.c(ptr %pr, ptr %a) !dbg !32 {
  entry:
    tail call void @__fmt_stdout_print1__a.ca.c(ptr @1, ptr %pr, ptr %a), !dbg !34
    ret void
  }
  
  define void @schmu_local_test() !dbg !35 {
  entry:
    tail call void @string_println(ptr @2), !dbg !36
    ret void
  }
  
  define void @schmu_nosig_nested_nested() !dbg !37 {
  entry:
    tail call void @string_println(ptr @3), !dbg !38
    ret void
  }
  
  define void @schmu_test() !dbg !39 {
  entry:
    tail call void @string_println(ptr @4), !dbg !40
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
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp._fmt.formatter.t.ua.crfmt.formatter.t.ua.c(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 40)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 2
    tail call void @__copy__fmt.formatter.t.ua.crfmt.formatter.t.u(ptr %f0)
    %v0 = getelementptr inbounds { ptr, ptr, %closure, ptr }, ptr %1, i32 0, i32 3
    tail call void @__copy_a.c(ptr %v0)
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
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__copy_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %size = load i64, ptr %1, align 8
    %2 = add i64 %size, 17
    %3 = tail call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__free_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free__up.clru(ptr %0)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !41 {
  entry:
    tail call void @schmu_test(), !dbg !42
    tail call void @schmu_local_test(), !dbg !43
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__schmu_local_poly_test__a.ca.c(ptr %clstmp, ptr @0), !dbg !44
    call void @schmu_nosig_nested_nested(), !dbg !45
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ valgrind -q --leak-check=yes --show-reachable=yes ./local_module
  hey test
  hey thing
  hey poly test
  i'm nested

Fix shadowing for local modules
  $ schmu local_module_shadowing.smu
  $ ./local_module_shadowing
  i'm in a module
  97u8
  10
  97u8
  97u8
  10

Prefix type names in nested polymorphic functions
  $ schmu -m nested_fn.smu
  $ schmu use_nested_fn.smu

Use local module from other file
  $ schmu -m local_otherfile.smu
  $ schmu use_local_otherfile.smu
  $ ./use_local_otherfile
  hey test
  hey thing
  hey poly test
  i'm nested
  hey test
  hey thing
  hey poly test
  i'm nested
  i'm nested


Local modules can shadow types. Use unique type names in codegen
  $ schmu local_module_type_shadowing.smu --dump-llvm 2>&1 | grep -v !DI
  local_module_type_shadowing.smu:5.5-6: warning: Unused binding t.
  
  5 | let t = {a = 10}
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %t = type { i64 }
  %nosig.t = type { i64, i64 }
  %nosig.nested.t = type { i64, i64, i64 }
  
  @schmu_t = constant %t { i64 10 }
  @schmu_nosig_t = constant %nosig.t { i64 10, i64 20 }
  @schmu_nosig_nested_t = constant %nosig.nested.t { i64 10, i64 20, i64 30 }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}

Search for modules when variables cannot be found
  $ schmu err_local_otherfile.smu
  err_local_otherfile.smu:3.1-24: error: No var named local_otherfile/aliased, but a module with the name exists.
  
  3 | local_otherfile/aliased
      ^^^^^^^^^^^^^^^^^^^^^^^
  
  [1]

Use directory as module
  $ cd modd
  $ schmu -m hidden.smu
  $ schmu -m indirect.smu
  $ schmu -m public.smu
  $ schmu -m modd.smu
  $ cd ..
  $ schmu consume_dir.smu
  $ ./consume_dir
  modd
  indirect
  public
  lol
  lol
  hello
  world

  $ printf "import indirect\nprintln(indirect/a)" > err.smu
  $ schmu err.smu
  err.smu:1.8-16: error: Cannot find module: indirect.
  
  1 | import indirect
             ^^^^^^^^
  
  [1]

Transitive polymorphic dependency needs to be available
  $ schmu -m transitive.smu
  $ schmu -m direct_dep.smu
  $ schmu use_dep.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr i64 @__direct_dep_id_lrl(i64 %a) !dbg !2 {
  entry:
    %0 = tail call i64 @__transitive_id_lrl(i64 %a), !dbg !6
    ret i64 %0
  }
  
  define linkonce_odr i64 @__transitive_id_lrl(i64 %a) !dbg !7 {
  entry:
    ret i64 %a
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %0 = tail call i64 @__direct_dep_id_lrl(i64 10), !dbg !11
    ret i64 %0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}

Apply local functors
  $ schmu --dump-llvm local_functor.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %outer.t = type { i64 }
  %somerec.t = type { i64, i64 }
  
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
    %5 = load ptr, ptr @fmt_int_digits, align 8
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %6 = tail call i8 @string_get(ptr %5, i64 %add), !dbg !29
    store i8 %6, ptr %scevgep10, align 1
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
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %7, %else ]
    ret i64 %iftmp
  }
  
  define double @schmu_floata_add(double %a, double %b) !dbg !32 {
  entry:
    %add = fadd double %a, %b
    ret double %add
  }
  
  define double @schmu_floatadder_add_twice(double %a, double %b) !dbg !34 {
  entry:
    %0 = tail call double @schmu_floata_add(double %a, double %b), !dbg !35
    %1 = tail call double @schmu_floata_add(double %0, double %b), !dbg !36
    ret double %1
  }
  
  define i64 @schmu_inta_add(i64 %a, i64 %b) !dbg !37 {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define i64 @schmu_intadder_add_twice(i64 %a, i64 %b) !dbg !38 {
  entry:
    %0 = tail call i64 @schmu_inta_add(i64 %a, i64 %b), !dbg !39
    %1 = tail call i64 @schmu_inta_add(i64 %0, i64 %b), !dbg !40
    ret i64 %1
  }
  
  define i64 @schmu_outa_add(i64 %0, i64 %1) !dbg !41 {
  entry:
    %a = alloca i64, align 8
    store i64 %0, ptr %a, align 8
    %b = alloca i64, align 8
    store i64 %1, ptr %b, align 8
    %2 = alloca %outer.t, align 8
    %add = add i64 %0, %1
    store i64 %add, ptr %2, align 8
    ret i64 %add
  }
  
  define i64 @schmu_outeradder_add_twice(i64 %0, i64 %1) !dbg !42 {
  entry:
    %a = alloca i64, align 8
    store i64 %0, ptr %a, align 8
    %b = alloca i64, align 8
    store i64 %1, ptr %b, align 8
    %ret = alloca %outer.t, align 8
    %2 = tail call i64 @schmu_outa_add(i64 %0, i64 %1), !dbg !43
    store i64 %2, ptr %ret, align 8
    %ret4 = alloca %outer.t, align 8
    %3 = tail call i64 @schmu_outa_add(i64 %2, i64 %1), !dbg !44
    store i64 %3, ptr %ret4, align 8
    ret i64 %3
  }
  
  define { i64, i64 } @schmu_recadder_add_twice(i64 %0, i64 %1, i64 %2, i64 %3) !dbg !45 {
  entry:
    %a = alloca { i64, i64 }, align 8
    store i64 %0, ptr %a, align 8
    %snd = getelementptr inbounds { i64, i64 }, ptr %a, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %b = alloca { i64, i64 }, align 8
    store i64 %2, ptr %b, align 8
    %snd2 = getelementptr inbounds { i64, i64 }, ptr %b, i32 0, i32 1
    store i64 %3, ptr %snd2, align 8
    %ret = alloca %somerec.t, align 8
    %4 = tail call { i64, i64 } @schmu_somerec_add(i64 %0, i64 %1, i64 %2, i64 %3), !dbg !46
    store { i64, i64 } %4, ptr %ret, align 8
    %fst12 = load i64, ptr %ret, align 8
    %snd13 = getelementptr inbounds { i64, i64 }, ptr %ret, i32 0, i32 1
    %snd14 = load i64, ptr %snd13, align 8
    %ret19 = alloca %somerec.t, align 8
    %5 = tail call { i64, i64 } @schmu_somerec_add(i64 %fst12, i64 %snd14, i64 %2, i64 %3), !dbg !47
    store { i64, i64 } %5, ptr %ret19, align 8
    ret { i64, i64 } %5
  }
  
  define { i64, i64 } @schmu_somerec_add(i64 %0, i64 %1, i64 %2, i64 %3) !dbg !48 {
  entry:
    %a = alloca { i64, i64 }, align 8
    store i64 %0, ptr %a, align 8
    %snd = getelementptr inbounds { i64, i64 }, ptr %a, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %b = alloca { i64, i64 }, align 8
    store i64 %2, ptr %b, align 8
    %snd2 = getelementptr inbounds { i64, i64 }, ptr %b, i32 0, i32 1
    store i64 %3, ptr %snd2, align 8
    %4 = alloca %somerec.t, align 8
    %add = add i64 %0, %2
    store i64 %add, ptr %4, align 8
    %b4 = getelementptr inbounds %somerec.t, ptr %4, i32 0, i32 1
    %add5 = add i64 %1, %3
    store i64 %add5, ptr %b4, align 8
    %unbox = load { i64, i64 }, ptr %4, align 8
    ret { i64, i64 } %unbox
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
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !49 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = tail call i64 @schmu_intadder_add_twice(i64 1, i64 2), !dbg !50
    call void @__fmt_stdout_println__ll(ptr %clstmp, i64 %0), !dbg !51
    %clstmp1 = alloca %closure, align 8
    store ptr @__fmt_int_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp1, align 8
    %envptr3 = getelementptr inbounds %closure, ptr %clstmp1, i32 0, i32 1
    store ptr null, ptr %envptr3, align 8
    %1 = call double @schmu_floatadder_add_twice(double 1.000000e+00, double 2.000000e+00), !dbg !52
    %2 = fptosi double %1 to i64
    call void @__fmt_stdout_println__ll(ptr %clstmp1, i64 %2), !dbg !53
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ ./local_functor
  5
  5

Simple functor
  $ schmu -m simple_functor.smu
  $ schmu use_simple_functor.smu --dump-llvm 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %tp.lfmt.formatter.t.u = type { i64, %fmt.formatter.t.u }
  %s.other.a.c = type { ptr, ptr }
  
  @fmt_stdout_missing_arg_msg = external global ptr
  @fmt_stdout_too_many_arg_msg = external global ptr
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @0 = private unnamed_addr constant { i64, i64, [15 x i8] } { i64 14, i64 14, [15 x i8] c"create: {} {}\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"this\00" }
  @2 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"other\00" }
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i64 @string_hash(ptr %0)
  
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
  
  define linkonce_odr void @__fmt_stdout_print2__a.ca.c_a.ca.c(ptr %fmtstr, ptr %f0, ptr %v0, ptr %f1, ptr %v1) !dbg !19 {
  entry:
    %__fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c = alloca %closure, align 8
    store ptr @__fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, ptr %__fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, align 8
    %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c = alloca { ptr, ptr, %closure, %closure, ptr, ptr }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %f12 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f12, ptr align 1 %f1, i64 16, i1 false)
    %v03 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, i32 0, i32 4
    store ptr %v0, ptr %v03, align 8
    %v14 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, i32 0, i32 5
    store ptr %v1, ptr %v14, align 8
    store ptr @__ctor_tp._fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, i32 0, i32 1
    store ptr %clsr___fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.u, align 8
    call void @fmt_stdout_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c), !dbg !20
    %0 = getelementptr inbounds %tp.lfmt.formatter.t.u, ptr %ret, i32 0, i32 1
    %1 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %1, 2
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
  
  define linkonce_odr void @__fun_fmt_stdout3_C_fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !28 {
  entry:
    %v0 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %1, i32 0, i32 4
    %v01 = load ptr, ptr %v0, align 8
    %v1 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %1, i32 0, i32 5
    %v12 = load ptr, ptr %v1, align 8
    %eq = icmp eq i64 %i, 0
    br i1 %eq, label %then, label %else, !dbg !29
  
  then:                                             ; preds = %entry
    %sunkaddr = getelementptr inbounds i8, ptr %1, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr12 = getelementptr inbounds i8, ptr %1, i64 24
    %loadtmp3 = load ptr, ptr %sunkaddr12, align 8
    tail call void %loadtmp(ptr %0, ptr %fmter, ptr %v01, ptr %loadtmp3), !dbg !30
    ret void
  
  else:                                             ; preds = %entry
    %eq4 = icmp eq i64 %i, 1
    br i1 %eq4, label %then5, label %else10, !dbg !31
  
  then5:                                            ; preds = %else
    %sunkaddr13 = getelementptr inbounds i8, ptr %1, i64 32
    %loadtmp7 = load ptr, ptr %sunkaddr13, align 8
    %sunkaddr14 = getelementptr inbounds i8, ptr %1, i64 40
    %loadtmp9 = load ptr, ptr %sunkaddr14, align 8
    tail call void %loadtmp7(ptr %0, ptr %fmter, ptr %v12, ptr %loadtmp9), !dbg !32
    ret void
  
  else10:                                           ; preds = %else
    tail call void @__fmt_stdout_impl_fmt_fail_missing_rfmt.formatter.t.u(ptr %0), !dbg !33
    tail call void @__free_fmt.formatter.t.u(ptr %fmter)
    ret void
  }
  
  define linkonce_odr { i64, i64 } @__schmu_s_create_a.c_a.crs.other.a.c(ptr %this, ptr %other, ptr %fmt) !dbg !34 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %0 = tail call ptr @schmu_string_to_string(ptr %this), !dbg !36
    call void @__fmt_stdout_print2__a.ca.c_a.ca.c(ptr @0, ptr %clstmp, ptr %0, ptr %fmt, ptr %other), !dbg !37
    %1 = alloca %s.other.a.c, align 8
    store ptr %this, ptr %1, align 8
    %other2 = getelementptr inbounds %s.other.a.c, ptr %1, i32 0, i32 1
    store ptr %other, ptr %other2, align 8
    %2 = alloca ptr, align 8
    store ptr %0, ptr %2, align 8
    call void @__free_a.c(ptr %2)
    %unbox = load { i64, i64 }, ptr %1, align 8
    ret { i64, i64 } %unbox
  }
  
  define ptr @schmu_string_to_string(ptr %t) !dbg !38 {
  entry:
    %0 = alloca ptr, align 8
    store ptr %t, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_a.c(ptr %1)
    %2 = load ptr, ptr %1, align 8
    ret ptr %2
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
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp._fmt.formatter.t.ua.crfmt.formatter.t.u_fmt.formatter.t.ua.crfmt.formatter.t.ua.ca.c(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 64)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 64, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %1, i32 0, i32 2
    tail call void @__copy__fmt.formatter.t.ua.crfmt.formatter.t.u(ptr %f0)
    %f1 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %1, i32 0, i32 3
    tail call void @__copy__fmt.formatter.t.ua.crfmt.formatter.t.u(ptr %f1)
    %v0 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %1, i32 0, i32 4
    tail call void @__copy_a.c(ptr %v0)
    %v1 = getelementptr inbounds { ptr, ptr, %closure, %closure, ptr, ptr }, ptr %1, i32 0, i32 5
    tail call void @__copy_a.c(ptr %v1)
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
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__copy_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %size = load i64, ptr %1, align 8
    %2 = add i64 %size, 17
    %3 = tail call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__free_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free__up.clru(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !40 {
  entry:
    %0 = alloca ptr, align 8
    store ptr @1, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_a.c(ptr %1)
    %2 = load ptr, ptr %1, align 8
    %3 = alloca ptr, align 8
    store ptr @2, ptr %3, align 8
    %4 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 %3, i64 8, i1 false)
    call void @__copy_a.c(ptr %4)
    %5 = load ptr, ptr %4, align 8
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_str_fmt.formatter.t.urfmt.formatter.t.u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %ret = alloca %s.other.a.c, align 8
    %6 = call { i64, i64 } @__schmu_s_create_a.c_a.crs.other.a.c(ptr %2, ptr %5, ptr %clstmp), !dbg !41
    store { i64, i64 } %6, ptr %ret, align 8
    call void @__free_s.other.a.c(ptr %ret)
    ret i64 0
  }
  
  define linkonce_odr void @__free_s.other.a.c(ptr %0) {
  entry:
    tail call void @__free_a.c(ptr %0)
    %1 = getelementptr inbounds %s.other.a.c, ptr %0, i32 0, i32 1
    tail call void @__free_a.c(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ ./use_simple_functor
  create: this other

Nameclashes with filename
  $ schmu -m filename_nameclash.smu

No mutable global state in modules
  $ schmu -m mutable_global_state.smu
  mutable_global_state.smu:1.1-14: error: Mutable top level bindings are not allowed in modules.
  
  1 | let mut _ = 0
      ^^^^^^^^^^^^^
  
  [1]

No mutable global state in submodules
  $ schmu mutable_global_state_submodule.smu
  mutable_global_state_submodule.smu:2.3-16: error: Mutable top level bindings are not allowed in modules.
  
  2 |   let mut _ = 0
        ^^^^^^^^^^^^^
  
  [1]

Ensure prelude is not reachable
  $ schmu use_prelude.smu
  use_prelude.smu:1.8-26: error: Module prelude has not been imported.
  
  1 | ignore(prelude/iter_range)
             ^^^^^^^^^^^^^^^^^^
  
  [1]

Ensure prelude is not importable
  $ schmu import_prelude.smu
  import_prelude.smu:1.8-15: error: Cannot find module: prelude.
  
  1 | import prelude
             ^^^^^^^
  
  [1]

Fix handling of parameterized abstract types
  $ schmu -m nullvec.smu
  $ schmu use_nullvec.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./use_nullvec

Fix external declarations in inner modules
  $ schmu inner_module_externals.smu

Make applied functors hidden behind signatures usable. Does this apply to local module too?
  $ schmu -m hidden_functor_app.smu
  $ schmu use_hidden_functor_app.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./use_hidden_functor_app

Check deps
  $ schmu -m --deps modd/modd.smu
  modd.o modd.smi: indirect.smi public.smi
  $ schmu --deps modd/modd.smu
  modd: indirect.smi public.smi

Use correct location to report functor application errors
  $ schmu functor_app_err.smu
  functor_app_err.smu:7.27-31: error: Mismatch between implementation and signature: Missing implementation of fun (t, t) -> bool equal.
  
  7 | module tbl = hashtbl/make(file)
                                ^^^^
  
  [1]

A regression test for monomorphization. Without proper regeneralization, the
type could change during monomorphization due to overlapping qvar ids.
  $ schmu -m async.smu
  $ schmu test_async.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./test_async
  resolving first promise
  resolved to 3
  resolving second promise
  resolved later to a string

Same thing borrow calls, also test module outname
  $ schmu -m async_borrow_call.smu -o async
  $ schmu test_async_borrow_call.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./test_async_borrow_call
  resolving first promise
  resolved to 3
  resolving second promise
  resolved later to a string

More complicated case, also regression test for frees from once moved closed variables
  $ schmu test_expl.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./test_expl
  resolving first promise
  resolved to 3
  resolving second promise
  resolved later to a string

Borrow call case with capture copies
  $ schmu test_async_borrow_call_copies.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./test_async_borrow_call_copies
  resolving first promise
  resolved to 3
  resolving second promise
  resolved later to a string

Support functor with inner modules
  $ schmu functor_inner_module.smu

Ensure no dups when linking
  $ schmu -m redefine_symbol_functor.smu
  $ schmu use_redefine_symbol_functor.smu

Suppress unused signature ctors
  $ schmu suppress_unused_signature_ctors.smu
