Compile stubs
  $ cc -c stub.c

Test name resolution and IR creation of functions
We discard the triple, b/c it varies from distro to distro
e.g. x86_64-unknown-linux-gnu on Fedora vs x86_64-pc-linux-gnu on gentoo

Simple fibonacci
  $ schmu --dump-llvm -o a.out stub.o fib.smu && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define i64 @schmu_fib(i64 %n) {
  entry:
    br label %tailrecurse
  
  tailrecurse:                                      ; preds = %else, %entry
    %accumulator.tr = phi i64 [ 0, %entry ], [ %add, %else ]
    %n.tr = phi i64 [ %n, %entry ], [ %2, %else ]
    %lt = icmp slt i64 %n.tr, 2
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %tailrecurse
    %accumulator.ret.tr = add i64 %n.tr, %accumulator.tr
    ret i64 %accumulator.ret.tr
  
  else:                                             ; preds = %tailrecurse
    %0 = add i64 %n.tr, -1
    %1 = tail call i64 @schmu_fib(i64 %0)
    %add = add i64 %1, %accumulator.tr
    %2 = add i64 %0, -1
    br label %tailrecurse
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @schmu_fib(i64 30)
    tail call void @printi(i64 %0)
    ret i64 0
  }
  832040

Fibonacci, but we shadow a bunch
  $ schmu --dump-llvm stub.o shadowing.smu && ./shadowing
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define i64 @__fun_schmu0(i64 %n) {
  entry:
    %sub = sub i64 %n, 1
    %0 = tail call i64 @schmu_fib(i64 %sub)
    ret i64 %0
  }
  
  define i64 @schmu_fib(i64 %n) {
  entry:
    %lt = icmp slt i64 %n, 2
    br i1 %lt, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %0 = tail call i64 @schmu_fibn2(i64 %n)
    %1 = tail call i64 @__fun_schmu0(i64 %n)
    %add = add i64 %0, %1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %add, %else ], [ %n, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_fibn2(i64 %n) {
  entry:
    %sub = sub i64 %n, 2
    %0 = tail call i64 @schmu_fib(i64 %sub)
    ret i64 %0
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @schmu_fib(i64 30)
    tail call void @printi(i64 %0)
    ret i64 0
  }
  832040

Multiple parameters
  $ schmu --dump-llvm stub.o multi_params.smu && ./multi_params
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @schmu_add(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define i64 @schmu_doiflesselse(i64 %a, i64 %b, i64 %greater, i64 %less) {
  entry:
    %lt = icmp slt i64 %a, %b
    br i1 %lt, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %greater, %else ], [ %less, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu_one() {
  entry:
    ret i64 1
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @schmu_one()
    %1 = tail call i64 @schmu_add(i64 %0, i64 1)
    %2 = tail call i64 @schmu_doiflesselse(i64 %1, i64 0, i64 1, i64 2)
    ret i64 %2
  }
  [1]

We have downwards closures
  $ schmu --dump-llvm stub.o closure.smu && ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %capturable = type { i64 }
  
  @schmu_a = global %capturable zeroinitializer, align 8
  
  define i64 @schmu_capture_a() {
  entry:
    %0 = load i64, i64* getelementptr inbounds (%capturable, %capturable* @schmu_a, i32 0, i32 0), align 8
    %add = add i64 %0, 2
    ret i64 %add
  }
  
  define i64 @schmu_capture_a_wrapped() {
  entry:
    %0 = tail call i64 @schmu_wrap()
    ret i64 %0
  }
  
  define i64 @schmu_inner() {
  entry:
    %0 = load i64, i64* getelementptr inbounds (%capturable, %capturable* @schmu_a, i32 0, i32 0), align 8
    %add = add i64 %0, 2
    ret i64 %add
  }
  
  define i64 @schmu_wrap() {
  entry:
    %0 = tail call i64 @schmu_inner()
    ret i64 %0
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 10, i64* getelementptr inbounds (%capturable, %capturable* @schmu_a, i32 0, i32 0), align 8
    %0 = tail call i64 @schmu_capture_a()
    %1 = tail call i64 @schmu_capture_a_wrapped()
    ret i64 %1
  }
  [12]

First class functions
  $ schmu --dump-llvm stub.o first_class.smu && ./first_class
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_pass2 = global %closure zeroinitializer, align 16
  
  declare void @printi(i64 %0)
  
  define i64 @__fun_schmu1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @__fun_schmu2(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @__g.g___fun_schmu0_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @__g.g_schmu_pass_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i1 @__gg.g.g_schmu_apply_bb.b.b(i1 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i1 (i1, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i1 %casttmp(i1 %x, i8* %loadtmp1)
    ret i1 %0
  }
  
  define i64 @__gg.g.g_schmu_apply_ii.i.i(i64 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i64 %x, i8* %loadtmp1)
    ret i64 %0
  }
  
  define i64 @schmu_add1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @schmu_int_of_bool(i1 %b) {
  entry:
    br i1 %b, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i1 @schmu_makefalse(i1 %b) {
  entry:
    ret i1 false
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr16 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64)* @schmu_add1 to i8*), i8** %funptr16, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @__gg.g.g_schmu_apply_ii.i.i(i64 0, %closure* %clstmp)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr217 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @__fun_schmu1 to i8*), i8** %funptr217, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %1 = call i64 @__gg.g.g_schmu_apply_ii.i.i(i64 1, %closure* %clstmp1)
    call void @printi(i64 %1)
    %clstmp4 = alloca %closure, align 8
    %funptr518 = bitcast %closure* %clstmp4 to i8**
    store i8* bitcast (i1 (i1)* @schmu_makefalse to i8*), i8** %funptr518, align 8
    %envptr6 = getelementptr inbounds %closure, %closure* %clstmp4, i32 0, i32 1
    store i8* null, i8** %envptr6, align 8
    %2 = call i1 @__gg.g.g_schmu_apply_bb.b.b(i1 true, %closure* %clstmp4)
    %3 = call i64 @schmu_int_of_bool(i1 %2)
    call void @printi(i64 %3)
    %clstmp7 = alloca %closure, align 8
    %funptr819 = bitcast %closure* %clstmp7 to i8**
    store i8* bitcast (i64 (i64)* @__fun_schmu2 to i8*), i8** %funptr819, align 8
    %envptr9 = getelementptr inbounds %closure, %closure* %clstmp7, i32 0, i32 1
    store i8* null, i8** %envptr9, align 8
    %4 = call i64 @__gg.g.g_schmu_apply_ii.i.i(i64 3, %closure* %clstmp7)
    call void @printi(i64 %4)
    %clstmp10 = alloca %closure, align 8
    %funptr1120 = bitcast %closure* %clstmp10 to i8**
    store i8* bitcast (i64 (i64)* @__g.g_schmu_pass_i.i to i8*), i8** %funptr1120, align 8
    %envptr12 = getelementptr inbounds %closure, %closure* %clstmp10, i32 0, i32 1
    store i8* null, i8** %envptr12, align 8
    %5 = call i64 @__gg.g.g_schmu_apply_ii.i.i(i64 4, %closure* %clstmp10)
    call void @printi(i64 %5)
    %clstmp13 = alloca %closure, align 8
    %funptr1421 = bitcast %closure* %clstmp13 to i8**
    store i8* bitcast (i64 (i64)* @__g.g___fun_schmu0_i.i to i8*), i8** %funptr1421, align 8
    %envptr15 = getelementptr inbounds %closure, %closure* %clstmp13, i32 0, i32 1
    store i8* null, i8** %envptr15, align 8
    %6 = call i64 @__gg.g.g_schmu_apply_ii.i.i(i64 5, %closure* %clstmp13)
    call void @printi(i64 %6)
    ret i64 0
  }
  1
  2
  0
  3
  4
  5

Don't try to create 'void' value in if
  $ schmu --dump-llvm stub.o if_return_void.smu && ./if_return_void
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define void @schmu_foo(i64 %i) {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, i64* %0, align 8
    br label %rec
  
  rec:                                              ; preds = %ifcont, %entry
    %1 = phi i64 [ %sub4, %ifcont ], [ %i, %entry ]
    %lt = icmp slt i64 %1, 2
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %rec
    %2 = add i64 %1, -1
    tail call void @printi(i64 %2)
    ret void
  
  else:                                             ; preds = %rec
    %lt1 = icmp slt i64 %1, 400
    br i1 %lt1, label %then2, label %else3
  
  then2:                                            ; preds = %else
    tail call void @printi(i64 %1)
    br label %ifcont
  
  else3:                                            ; preds = %else
    %add = add i64 %1, 1
    tail call void @printi(i64 %add)
    br label %ifcont
  
  ifcont:                                           ; preds = %else3, %then2
    %sub4 = sub i64 %1, 1
    %3 = add i64 %1, -1
    store i64 %3, i64* %0, align 8
    br label %rec
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_foo(i64 4)
    ret i64 0
  }
  4
  3
  2
  0

Captured values should not overwrite function params
  $ schmu --dump-llvm stub.o -o a.out overwrite_params.smu && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_b = constant i64 2
  
  declare void @printi(i64 %0)
  
  define i64 @schmu_add(%closure* %a, %closure* %b) {
  entry:
    %funcptr7 = bitcast %closure* %a to i8**
    %loadtmp = load i8*, i8** %funcptr7, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %a, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i8* %loadtmp1)
    %funcptr28 = bitcast %closure* %b to i8**
    %loadtmp3 = load i8*, i8** %funcptr28, align 8
    %casttmp4 = bitcast i8* %loadtmp3 to i64 (i8*)*
    %envptr5 = getelementptr inbounds %closure, %closure* %b, i32 0, i32 1
    %loadtmp6 = load i8*, i8** %envptr5, align 8
    %1 = tail call i64 %casttmp4(i8* %loadtmp6)
    %add = add i64 %0, %1
    ret i64 %add
  }
  
  define i64 @schmu_one() {
  entry:
    ret i64 1
  }
  
  define i64 @schmu_two() {
  entry:
    ret i64 2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr4 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 ()* @schmu_one to i8*), i8** %funptr4, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr25 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 ()* @schmu_two to i8*), i8** %funptr25, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %0 = call i64 @schmu_add(%closure* %clstmp, %closure* %clstmp1)
    call void @printi(i64 %0)
    ret i64 0
  }
  3

Functions can be generic. In this test, we generate 'apply' only once and use it with
3 different functions with different types
  $ schmu --dump-llvm stub.o generic_fun_arg.smu && ./generic_fun_arg
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %t_int = type { i64 }
  %t_bool = type { i1 }
  
  @schmu_a = constant i64 2
  @schmu_f = global %closure zeroinitializer, align 16
  
  declare void @printi(i64 %0)
  
  define i64 @__fun_schmu1(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @__g.g___fun_schmu0_ti.ti(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %x = bitcast i64* %box to %t_int*
    %1 = alloca %t_int, align 8
    %2 = bitcast %t_int* %1 to i8*
    %3 = bitcast %t_int* %x to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    %unbox = bitcast %t_int* %1 to i64*
    %unbox2 = load i64, i64* %unbox, align 8
    ret i64 %unbox2
  }
  
  define i1 @__gg.g.g_schmu_apply_bb.b.b(i1 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i1 (i1, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i1 %casttmp(i1 %x, i8* %loadtmp1)
    ret i1 %0
  }
  
  define i64 @__gg.g.g_schmu_apply_ii.i.i(i64 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i64 %x, i8* %loadtmp1)
    ret i64 %0
  }
  
  define i8 @__gg.g.g_schmu_apply_tbtb.tb.tb(i8 %0, %closure* %f) {
  entry:
    %box = alloca i8, align 1
    store i8 %0, i8* %box, align 1
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to i8 (i8, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_bool, align 8
    %1 = tail call i8 %casttmp(i8 %0, i8* %loadtmp3)
    %box4 = bitcast %t_bool* %ret to i8*
    store i8 %1, i8* %box4, align 1
    ret i8 %1
  }
  
  define i64 @__gg.g.g_schmu_apply_titi.ti.ti(i64 %0, %closure* %f) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    %1 = tail call i64 %casttmp(i64 %0, i8* %loadtmp3)
    %box4 = bitcast %t_int* %ret to i64*
    store i64 %1, i64* %box4, align 8
    ret i64 %1
  }
  
  define i64 @schmu_add1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @schmu_add3_rec(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %1 = alloca %t_int, align 8
    %x3 = bitcast %t_int* %1 to i64*
    %add = add i64 %0, 3
    store i64 %add, i64* %x3, align 8
    ret i64 %add
  }
  
  define i64 @schmu_add_closed(i64 %x) {
  entry:
    %add = add i64 %x, 2
    ret i64 %add
  }
  
  define i8 @schmu_make_rec_false(i8 %0) {
  entry:
    %box = alloca i8, align 1
    store i8 %0, i8* %box, align 1
    %r = bitcast i8* %box to %t_bool*
    %1 = trunc i8 %0 to i1
    br i1 %1, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %2 = alloca %t_bool, align 8
    store %t_bool zeroinitializer, %t_bool* %2, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi %t_bool* [ %2, %then ], [ %r, %entry ]
    %unbox = bitcast %t_bool* %iftmp to i8*
    %unbox2 = load i8, i8* %unbox, align 1
    ret i8 %unbox2
  }
  
  define i1 @schmu_makefalse(i1 %b) {
  entry:
    ret i1 false
  }
  
  define void @schmu_print_bool(i1 %b) {
  entry:
    br i1 %b, label %then, label %else
  
  then:                                             ; preds = %entry
    tail call void @printi(i64 1)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @printi(i64 0)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr20 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64)* @schmu_add1 to i8*), i8** %funptr20, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @__gg.g.g_schmu_apply_ii.i.i(i64 20, %closure* %clstmp)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr221 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @schmu_add_closed to i8*), i8** %funptr221, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %1 = call i64 @__gg.g.g_schmu_apply_ii.i.i(i64 20, %closure* %clstmp1)
    call void @printi(i64 %1)
    %clstmp4 = alloca %closure, align 8
    %funptr522 = bitcast %closure* %clstmp4 to i8**
    store i8* bitcast (i64 (i64)* @schmu_add3_rec to i8*), i8** %funptr522, align 8
    %envptr6 = getelementptr inbounds %closure, %closure* %clstmp4, i32 0, i32 1
    store i8* null, i8** %envptr6, align 8
    %ret = alloca %t_int, align 8
    %2 = call i64 @__gg.g.g_schmu_apply_titi.ti.ti(i64 20, %closure* %clstmp4)
    %box = bitcast %t_int* %ret to i64*
    store i64 %2, i64* %box, align 8
    call void @printi(i64 %2)
    %clstmp8 = alloca %closure, align 8
    %funptr923 = bitcast %closure* %clstmp8 to i8**
    store i8* bitcast (i8 (i8)* @schmu_make_rec_false to i8*), i8** %funptr923, align 8
    %envptr10 = getelementptr inbounds %closure, %closure* %clstmp8, i32 0, i32 1
    store i8* null, i8** %envptr10, align 8
    %ret11 = alloca %t_bool, align 8
    %3 = call i8 @__gg.g.g_schmu_apply_tbtb.tb.tb(i8 1, %closure* %clstmp8)
    %box12 = bitcast %t_bool* %ret11 to i8*
    store i8 %3, i8* %box12, align 1
    %4 = trunc i8 %3 to i1
    call void @schmu_print_bool(i1 %4)
    %clstmp14 = alloca %closure, align 8
    %funptr1524 = bitcast %closure* %clstmp14 to i8**
    store i8* bitcast (i1 (i1)* @schmu_makefalse to i8*), i8** %funptr1524, align 8
    %envptr16 = getelementptr inbounds %closure, %closure* %clstmp14, i32 0, i32 1
    store i8* null, i8** %envptr16, align 8
    %5 = call i1 @__gg.g.g_schmu_apply_bb.b.b(i1 true, %closure* %clstmp14)
    call void @schmu_print_bool(i1 %5)
    %ret17 = alloca %t_int, align 8
    %6 = call i64 @__g.g___fun_schmu0_ti.ti(i64 17)
    %box18 = bitcast %t_int* %ret17 to i64*
    store i64 %6, i64* %box18, align 8
    call void @printi(i64 %6)
    %7 = call i64 @__fun_schmu1(i64 18)
    call void @printi(i64 %7)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  21
  22
  23
  0
  0
  17
  18

A generic pass function. This example is not 100% correct, but works due to calling convertion.
  $ schmu --dump-llvm stub.o generic_pass.smu && ./generic_pass
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t = type { i64, i1 }
  %closure = type { i8*, i8* }
  
  declare void @printi(i64 %0)
  
  define i64 @__g.g_schmu_pass_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define { i64, i8 } @__g.g_schmu_pass_t.t(i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst3 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst3, align 8
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %box, i32 0, i32 1
    store i8 %1, i8* %snd, align 1
    %x = bitcast { i64, i8 }* %box to %t*
    %2 = alloca %t, align 8
    %3 = bitcast %t* %2 to i8*
    %4 = bitcast %t* %x to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 16, i1 false)
    %unbox = bitcast %t* %2 to { i64, i8 }*
    %unbox2 = load { i64, i8 }, { i64, i8 }* %unbox, align 8
    ret { i64, i8 } %unbox2
  }
  
  define i64 @__g.gg.g_schmu_apply_i.ii.i(%closure* %f, i64 %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i64 %x, i8* %loadtmp1)
    ret i64 %0
  }
  
  define { i64, i8 } @__g.gg.g_schmu_apply_t.tt.t(%closure* %f, i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst11 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst11, align 8
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %box, i32 0, i32 1
    store i8 %1, i8* %snd, align 1
    %funcptr12 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr12, align 8
    %casttmp = bitcast i8* %loadtmp to { i64, i8 } (i64, i8, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp6 = load i8*, i8** %envptr, align 8
    %ret = alloca %t, align 8
    %2 = tail call { i64, i8 } %casttmp(i64 %0, i8 %1, i8* %loadtmp6)
    %box7 = bitcast %t* %ret to { i64, i8 }*
    store { i64, i8 } %2, { i64, i8 }* %box7, align 8
    ret { i64, i8 } %2
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr7 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64)* @__g.g_schmu_pass_i.i to i8*), i8** %funptr7, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @__g.gg.g_schmu_apply_i.ii.i(%closure* %clstmp, i64 20)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr28 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast ({ i64, i8 } (i64, i8)* @__g.g_schmu_pass_t.t to i8*), i8** %funptr28, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %boxconst = alloca %t, align 8
    store %t { i64 700, i1 false }, %t* %boxconst, align 8
    %unbox = bitcast %t* %boxconst to { i64, i8 }*
    %fst9 = bitcast { i64, i8 }* %unbox to i64*
    %fst4 = load i64, i64* %fst9, align 8
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %unbox, i32 0, i32 1
    %snd5 = load i8, i8* %snd, align 1
    %ret = alloca %t, align 8
    %1 = call { i64, i8 } @__g.gg.g_schmu_apply_t.tt.t(%closure* %clstmp1, i64 %fst4, i8 %snd5)
    %box = bitcast %t* %ret to { i64, i8 }*
    store { i64, i8 } %1, { i64, i8 }* %box, align 8
    %2 = bitcast %t* %ret to i64*
    %3 = load i64, i64* %2, align 8
    call void @printi(i64 %3)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  20
  700


This is a regression test. The 'add1' function was not marked as a closure when being called from
a second function. Instead, the closure struct was being created again and the code segfaulted
  $ schmu --dump-llvm stub.o indirect_closure.smu && ./indirect_closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %t_int = type { i64 }
  
  @schmu_a = global i64 0, align 8
  @schmu_b = global i64 0, align 8
  
  declare void @printi(i64 %0)
  
  define i64 @__ggg.g.gg.g.g_schmu_apply2_titii.i.tii.i.ti(i64 %0, %closure* %f, %closure* %env) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, %closure*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    %1 = tail call i64 %casttmp(i64 %0, %closure* %env, i8* %loadtmp3)
    %box4 = bitcast %t_int* %ret to i64*
    store i64 %1, i64* %box4, align 8
    ret i64 %1
  }
  
  define i64 @__ggg.gg.g_schmu_apply_titii.i.tii.i.ti(i64 %0, %closure* %f, %closure* %env) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, %closure*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    %1 = tail call i64 %casttmp(i64 %0, %closure* %env, i8* %loadtmp3)
    %box4 = bitcast %t_int* %ret to i64*
    store i64 %1, i64* %box4, align 8
    ret i64 %1
  }
  
  define i64 @__tgg.g.tg_schmu_boxed2int_int_tii.i.ti(i64 %0, %closure* %env) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %funcptr4 = bitcast %closure* %env to i8**
    %loadtmp = load i8*, i8** %funcptr4, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %env, i32 0, i32 1
    %loadtmp2 = load i8*, i8** %envptr, align 8
    %1 = tail call i64 %casttmp(i64 %0, i8* %loadtmp2)
    %2 = alloca %t_int, align 8
    %x5 = bitcast %t_int* %2 to i64*
    store i64 %1, i64* %x5, align 8
    ret i64 %1
  }
  
  define i64 @schmu_add1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr14 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64, %closure*)* @__tgg.g.tg_schmu_boxed2int_int_tii.i.ti to i8*), i8** %funptr14, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr215 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @schmu_add1 to i8*), i8** %funptr215, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %ret = alloca %t_int, align 8
    %0 = call i64 @__ggg.gg.g_schmu_apply_titii.i.tii.i.ti(i64 15, %closure* %clstmp, %closure* %clstmp1)
    %box = bitcast %t_int* %ret to i64*
    store i64 %0, i64* %box, align 8
    store i64 %0, i64* @schmu_a, align 8
    call void @printi(i64 %0)
    %clstmp5 = alloca %closure, align 8
    %funptr616 = bitcast %closure* %clstmp5 to i8**
    store i8* bitcast (i64 (i64, %closure*)* @__tgg.g.tg_schmu_boxed2int_int_tii.i.ti to i8*), i8** %funptr616, align 8
    %envptr7 = getelementptr inbounds %closure, %closure* %clstmp5, i32 0, i32 1
    store i8* null, i8** %envptr7, align 8
    %clstmp8 = alloca %closure, align 8
    %funptr917 = bitcast %closure* %clstmp8 to i8**
    store i8* bitcast (i64 (i64)* @schmu_add1 to i8*), i8** %funptr917, align 8
    %envptr10 = getelementptr inbounds %closure, %closure* %clstmp8, i32 0, i32 1
    store i8* null, i8** %envptr10, align 8
    %ret11 = alloca %t_int, align 8
    %1 = call i64 @__ggg.g.gg.g.g_schmu_apply2_titii.i.tii.i.ti(i64 15, %closure* %clstmp5, %closure* %clstmp8)
    %box12 = bitcast %t_int* %ret11 to i64*
    store i64 %1, i64* %box12, align 8
    store i64 %1, i64* @schmu_b, align 8
    call void @printi(i64 %1)
    ret i64 0
  }
  16
  16

Closures can recurse too
  $ schmu --dump-llvm stub.o -o a.out recursive_closure.smu && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_outer = constant i64 10
  
  declare void @printi(i64 %0)
  
  define void @schmu_loop(i64 %i) {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, i64* %0, align 8
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %1 = phi i64 [ %add, %then ], [ %i, %entry ]
    %lt = icmp slt i64 %1, 10
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %rec
    tail call void @printi(i64 %1)
    %add = add i64 %1, 1
    store i64 %add, i64* %0, align 8
    br label %rec
  
  else:                                             ; preds = %rec
    tail call void @printi(i64 %1)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_loop(i64 0)
    ret i64 0
  }
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
  $ schmu --dump-llvm stub.o no_lambda_let_poly_monomorph.smu
  no_lambda_let_poly_monomorph.smu:5:9: error: Returning polymorphic anonymous function in if expressions is not supported (yet). Sorry. You can type the function concretely though.
  5 | (def f (if true (fn [x] (copy x)) (fn [x] (copy x))))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  
  [1]
Allow mixing of typedefs and external decls in the preface
  $ schmu --dump-llvm stub.o mix_preface.smu && ./mix_preface
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare i64 @dummy_call()
  
  declare void @print_2nd(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 0
  }

Support monomorphization of nested functions
  $ schmu --dump-llvm stub.o monomorph_nested.smu && ./monomorph_nested
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %rc = type { i64 }
  
  declare void @printi(i64 %0)
  
  define i1 @__g.g_schmu_id_b.b(i1 %x) {
  entry:
    ret i1 %x
  }
  
  define i64 @__g.g_schmu_id_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @__g.g_schmu_id_rc.rc(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %x = bitcast i64* %box to %rc*
    %1 = alloca %rc, align 8
    %2 = bitcast %rc* %1 to i8*
    %3 = bitcast %rc* %x to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    %unbox = bitcast %rc* %1 to i64*
    %unbox2 = load i64, i64* %unbox, align 8
    ret i64 %unbox2
  }
  
  define i1 @__g.g_schmu_wrapped_b.b(i1 %x) {
  entry:
    %0 = tail call i1 @__g.g_schmu_id_b.b(i1 %x)
    ret i1 %0
  }
  
  define i64 @__g.g_schmu_wrapped_i.i(i64 %x) {
  entry:
    %0 = tail call i64 @__g.g_schmu_id_i.i(i64 %x)
    ret i64 %0
  }
  
  define i64 @__g.g_schmu_wrapped_rc.rc(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %ret = alloca %rc, align 8
    %1 = tail call i64 @__g.g_schmu_id_rc.rc(i64 %0)
    %box3 = bitcast %rc* %ret to i64*
    store i64 %1, i64* %box3, align 8
    ret i64 %1
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @__g.g_schmu_wrapped_i.i(i64 12)
    tail call void @printi(i64 %0)
    %1 = tail call i1 @__g.g_schmu_wrapped_b.b(i1 false)
    %ret = alloca %rc, align 8
    %2 = tail call i64 @__g.g_schmu_wrapped_rc.rc(i64 24)
    %box = bitcast %rc* %ret to i64*
    store i64 %2, i64* %box, align 8
    tail call void @printi(i64 %2)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  12
  24

Nested polymorphic closures. Does not quite work for another nesting level
  $ schmu --dump-llvm stub.o nested_polymorphic_closures.smu && valgrind -q --leak-check=yes --show-reachable=yes ./nested_polymorphic_closures
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_arr = global i64* null, align 8
  
  declare void @printi(i64 %0)
  
  define void @__agg.u.u_schmu_array-iter_aii.u.u(i64* %arr, %closure* %f) {
  entry:
    %__i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u = alloca %closure, align 8
    %funptr27 = bitcast %closure* %__i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u to i8*), i8** %funptr27, align 8
    %clsr___i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u = alloca { i8*, i8*, i64*, %closure }, align 8
    %arr1 = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u, i32 0, i32 2
    store i64* %arr, i64** %arr1, align 8
    %f2 = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor28 = bitcast { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ai-i.u to i8*), i8** %ctor28, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %__ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai = alloca %closure, align 8
    %funptr329 = bitcast %closure* %__ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai to i8**
    store i8* bitcast (void (i64, %closure*, i8*)* @__ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai to i8*), i8** %funptr329, align 8
    %clsr___ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai = alloca { i8*, i8*, i64* }, align 8
    %arr4 = getelementptr inbounds { i8*, i8*, i64* }, { i8*, i8*, i64* }* %clsr___ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai, i32 0, i32 2
    store i64* %arr, i64** %arr4, align 8
    %ctor530 = bitcast { i8*, i8*, i64* }* %clsr___ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ai to i8*), i8** %ctor530, align 8
    %dtor6 = getelementptr inbounds { i8*, i8*, i64* }, { i8*, i8*, i64* }* %clsr___ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai, i32 0, i32 1
    store i8* null, i8** %dtor6, align 8
    %env7 = bitcast { i8*, i8*, i64* }* %clsr___ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai to i8*
    %envptr8 = getelementptr inbounds %closure, %closure* %__ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai, i32 0, i32 1
    store i8* %env7, i8** %envptr8, align 8
    %__iag.u-g.u_schmu_inner_cls_f_iai.u-i.u = alloca %closure, align 8
    %funptr931 = bitcast %closure* %__iag.u-g.u_schmu_inner_cls_f_iai.u-i.u to i8**
    store i8* bitcast (void (i64, i64*, i8*)* @__iag.u-g.u_schmu_inner_cls_f_iai.u-i.u to i8*), i8** %funptr931, align 8
    %clsr___iag.u-g.u_schmu_inner_cls_f_iai.u-i.u = alloca { i8*, i8*, %closure }, align 8
    %f10 = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___iag.u-g.u_schmu_inner_cls_f_iai.u-i.u, i32 0, i32 2
    %2 = bitcast %closure* %f10 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %1, i64 16, i1 false)
    %ctor1132 = bitcast { i8*, i8*, %closure }* %clsr___iag.u-g.u_schmu_inner_cls_f_iai.u-i.u to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-i.u to i8*), i8** %ctor1132, align 8
    %dtor12 = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %clsr___iag.u-g.u_schmu_inner_cls_f_iai.u-i.u, i32 0, i32 1
    store i8* null, i8** %dtor12, align 8
    %env13 = bitcast { i8*, i8*, %closure }* %clsr___iag.u-g.u_schmu_inner_cls_f_iai.u-i.u to i8*
    %envptr14 = getelementptr inbounds %closure, %closure* %__iag.u-g.u_schmu_inner_cls_f_iai.u-i.u, i32 0, i32 1
    store i8* %env13, i8** %envptr14, align 8
    call void @__i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u(i64 0, i8* %env)
    call void @__ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai(i64 0, %closure* %f, i8* %env7)
    call void @__iag.u-g.u_schmu_inner_cls_f_iai.u-i.u(i64 0, i64* %arr, i8* %env13)
    ret void
  }
  
  define void @__fun_schmu0(i64 %x) {
  entry:
    %mul = mul i64 %x, 2
    tail call void @printi(i64 %mul)
    ret void
  }
  
  define void @__i.u-ag-g.u_schmu_inner_cls_both_i.u-ai-i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64*, %closure }*
    %arr = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %3 = add i64 %lsr.iv, -1
    %4 = load i64, i64* %arr1, align 8
    %eq = icmp eq i64 %3, %4
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %scevgep = getelementptr i64, i64* %arr1, i64 %lsr.iv
    %scevgep3 = getelementptr i64, i64* %scevgep, i64 1
    %5 = load i64, i64* %scevgep3, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 24
    %6 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %6, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %sunkaddr5 = getelementptr inbounds i8, i8* %0, i64 32
    %7 = bitcast i8* %sunkaddr5 to i8**
    %loadtmp2 = load i8*, i8** %7, align 8
    tail call void %casttmp(i64 %5, i8* %loadtmp2)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @__iag.u-g.u_schmu_inner_cls_f_iai.u-i.u(i64 %i, i64* %arr, i8* %0) {
  entry:
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = alloca i64*, align 8
    store i64* %arr, i64** %2, align 8
    %3 = alloca i1, align 1
    store i1 false, i1* %3, align 1
    %4 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %4, %entry ]
    %5 = add i64 %lsr.iv, -1
    %6 = load i64, i64* %arr, align 8
    %eq = icmp eq i64 %5, %6
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    store i1 true, i1* %3, align 1
    ret void
  
  else:                                             ; preds = %rec
    %scevgep = getelementptr i64, i64* %arr, i64 %lsr.iv
    %scevgep2 = getelementptr i64, i64* %scevgep, i64 1
    %7 = load i64, i64* %scevgep2, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %8 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %8, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %sunkaddr4 = getelementptr inbounds i8, i8* %0, i64 24
    %9 = bitcast i8* %sunkaddr4 to i8**
    %loadtmp1 = load i8*, i8** %9, align 8
    tail call void %casttmp(i64 %7, i8* %loadtmp1)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @__ig.u.u-ag_schmu_inner_cls_arr_ii.u.u-ai(i64 %i, %closure* %f, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64* }*
    %arr = getelementptr inbounds { i8*, i8*, i64* }, { i8*, i8*, i64* }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = alloca %closure, align 8
    %3 = bitcast %closure* %2 to i8*
    %4 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 16, i1 false)
    %5 = alloca i1, align 1
    store i1 false, i1* %5, align 1
    %6 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %6, %entry ]
    %7 = add i64 %lsr.iv, -1
    %8 = load i64, i64* %arr1, align 8
    %eq = icmp eq i64 %7, %8
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    store i1 true, i1* %5, align 1
    ret void
  
  else:                                             ; preds = %rec
    %scevgep = getelementptr i64, i64* %arr1, i64 %lsr.iv
    %scevgep3 = getelementptr i64, i64* %scevgep, i64 1
    %9 = load i64, i64* %scevgep3, align 8
    %funcptr4 = bitcast %closure* %2 to i8**
    %loadtmp = load i8*, i8** %funcptr4, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %2, i32 0, i32 1
    %loadtmp2 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %9, i8* %loadtmp2)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal i8* @__ctor_tup-ai-i.u(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64*, %closure }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, i64*, %closure }*
    %4 = bitcast { i8*, i8*, i64*, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64*, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %arr = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %3, i32 0, i32 2
    call void @__copy_ai(i64** %arr)
    %f = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %3, i32 0, i32 3
    call void @__copy_i.u(%closure* %f)
    %6 = bitcast { i8*, i8*, i64*, %closure }* %3 to i8*
    ret i8* %6
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz2 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define internal void @__copy_i.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define internal i8* @__ctor_tup-ai(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64* }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, i64* }*
    %4 = bitcast { i8*, i8*, i64* }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64* }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %arr = getelementptr inbounds { i8*, i8*, i64* }, { i8*, i8*, i64* }* %3, i32 0, i32 2
    call void @__copy_ai(i64** %arr)
    %6 = bitcast { i8*, i8*, i64* }* %3 to i8*
    ret i8* %6
  }
  
  define internal i8* @__ctor_tup-i.u(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %closure }*
    %2 = call i8* @malloc(i64 32)
    %3 = bitcast i8* %2 to { i8*, i8*, %closure }*
    %4 = bitcast { i8*, i8*, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 32, i1 false)
    %f = getelementptr inbounds { i8*, i8*, %closure }, { i8*, i8*, %closure }* %3, i32 0, i32 2
    call void @__copy_i.u(%closure* %f)
    %6 = bitcast { i8*, i8*, %closure }* %3 to i8*
    ret i8* %6
  }
  
  define internal void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define internal void @__free_i.u(%closure* %0) {
  entry:
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %env = load i8*, i8** %envptr, align 8
    %1 = icmp eq i8* %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = bitcast i8* %env to { i8*, i8* }*
    %3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %2, i32 0, i32 1
    %dtor1 = load i8*, i8** %3, align 8
    %4 = icmp eq i8* %dtor1, null
    br i1 %4, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    %dtor2 = bitcast i8* %dtor1 to void (i8*)*
    call void %dtor2(i8* %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(i8* %env)
    br label %ret
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @schmu_arr, align 8
    store i64 0, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %3 = load i64*, i64** @schmu_arr, align 8
    %size2 = load i64, i64* %3, align 8
    %cap3 = getelementptr i64, i64* %3, i64 1
    %cap4 = load i64, i64* %cap3, align 8
    %4 = icmp eq i64 %cap4, %size2
    br i1 %4, label %grow, label %merge
  
  grow:                                             ; preds = %entry
    %5 = tail call i64* @__ag.ag_grow_ai.ai(i64** @schmu_arr)
    br label %merge
  
  merge:                                            ; preds = %entry, %grow
    %6 = phi i64* [ %5, %grow ], [ %3, %entry ]
    %7 = bitcast i64* %6 to i8*
    %8 = mul i64 8, %size2
    %9 = add i64 16, %8
    %10 = getelementptr i8, i8* %7, i64 %9
    %data5 = bitcast i8* %10 to i64*
    store i64 1, i64* %data5, align 8
    %11 = add i64 %size2, 1
    store i64 %11, i64* %6, align 8
    %12 = load i64*, i64** @schmu_arr, align 8
    %size8 = load i64, i64* %12, align 8
    %cap9 = getelementptr i64, i64* %12, i64 1
    %cap10 = load i64, i64* %cap9, align 8
    %13 = icmp eq i64 %cap10, %size8
    br i1 %13, label %grow12, label %merge13
  
  grow12:                                           ; preds = %merge
    %14 = tail call i64* @__ag.ag_grow_ai.ai(i64** @schmu_arr)
    br label %merge13
  
  merge13:                                          ; preds = %merge, %grow12
    %15 = phi i64* [ %14, %grow12 ], [ %12, %merge ]
    %16 = bitcast i64* %15 to i8*
    %17 = mul i64 8, %size8
    %18 = add i64 16, %17
    %19 = getelementptr i8, i8* %16, i64 %18
    %data14 = bitcast i8* %19 to i64*
    store i64 2, i64* %data14, align 8
    %20 = add i64 %size8, 1
    store i64 %20, i64* %15, align 8
    %21 = load i64*, i64** @schmu_arr, align 8
    %size17 = load i64, i64* %21, align 8
    %cap18 = getelementptr i64, i64* %21, i64 1
    %cap19 = load i64, i64* %cap18, align 8
    %22 = icmp eq i64 %cap19, %size17
    br i1 %22, label %grow21, label %merge22
  
  grow21:                                           ; preds = %merge13
    %23 = tail call i64* @__ag.ag_grow_ai.ai(i64** @schmu_arr)
    br label %merge22
  
  merge22:                                          ; preds = %merge13, %grow21
    %24 = phi i64* [ %23, %grow21 ], [ %21, %merge13 ]
    %25 = bitcast i64* %24 to i8*
    %26 = mul i64 8, %size17
    %27 = add i64 16, %26
    %28 = getelementptr i8, i8* %25, i64 %27
    %data23 = bitcast i8* %28 to i64*
    store i64 3, i64* %data23, align 8
    %29 = add i64 %size17, 1
    store i64 %29, i64* %24, align 8
    %30 = load i64*, i64** @schmu_arr, align 8
    %size26 = load i64, i64* %30, align 8
    %cap27 = getelementptr i64, i64* %30, i64 1
    %cap28 = load i64, i64* %cap27, align 8
    %31 = icmp eq i64 %cap28, %size26
    br i1 %31, label %grow30, label %merge31
  
  grow30:                                           ; preds = %merge22
    %32 = tail call i64* @__ag.ag_grow_ai.ai(i64** @schmu_arr)
    br label %merge31
  
  merge31:                                          ; preds = %merge22, %grow30
    %33 = phi i64* [ %32, %grow30 ], [ %30, %merge22 ]
    %34 = bitcast i64* %33 to i8*
    %35 = mul i64 8, %size26
    %36 = add i64 16, %35
    %37 = getelementptr i8, i8* %34, i64 %36
    %data32 = bitcast i8* %37 to i64*
    store i64 4, i64* %data32, align 8
    %38 = add i64 %size26, 1
    store i64 %38, i64* %33, align 8
    %39 = load i64*, i64** @schmu_arr, align 8
    %size35 = load i64, i64* %39, align 8
    %cap36 = getelementptr i64, i64* %39, i64 1
    %cap37 = load i64, i64* %cap36, align 8
    %40 = icmp eq i64 %cap37, %size35
    br i1 %40, label %grow39, label %merge40
  
  grow39:                                           ; preds = %merge31
    %41 = tail call i64* @__ag.ag_grow_ai.ai(i64** @schmu_arr)
    br label %merge40
  
  merge40:                                          ; preds = %merge31, %grow39
    %42 = phi i64* [ %41, %grow39 ], [ %39, %merge31 ]
    %43 = bitcast i64* %42 to i8*
    %44 = mul i64 8, %size35
    %45 = add i64 16, %44
    %46 = getelementptr i8, i8* %43, i64 %45
    %data41 = bitcast i8* %46 to i64*
    store i64 5, i64* %data41, align 8
    %47 = add i64 %size35, 1
    store i64 %47, i64* %42, align 8
    %48 = load i64*, i64** @schmu_arr, align 8
    %clstmp = alloca %closure, align 8
    %funptr43 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @__fun_schmu0 to i8*), i8** %funptr43, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @__agg.u.u_schmu_array-iter_aii.u.u(i64* %48, %closure* %clstmp)
    call void @__free_ai(i64** @schmu_arr)
    ret i64 0
  }
  
  define internal i64* @__ag.ag_grow_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 2
    %3 = mul i64 %2, 8
    %4 = add i64 %3, 16
    %5 = load i64*, i64** %0, align 8
    %6 = bitcast i64* %5 to i8*
    %7 = call i8* @realloc(i8* %6, i64 %4)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %0, align 8
    %newcap = getelementptr i64, i64* %8, i64 1
    store i64 %2, i64* %newcap, align 8
    %9 = load i64*, i64** %0, align 8
    ret i64* %9
  }
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
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
  $ schmu --dump-llvm stub.o closures_to_env.smu && ./closures_to_env
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = constant i64 20
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_close_over_a() {
  entry:
    ret i64 20
  }
  
  define void @schmu_use_above() {
  entry:
    %0 = tail call i64 @schmu_close_over_a()
    tail call void @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i64 16), i64 %0)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_use_above()
    ret i64 0
  }
  20

Don't copy mutable types in setup of tailrecursive functions
  $ schmu --dump-llvm tailrec_mutable.smu && valgrind -q --leak-check=yes --show-reachable=yes ./tailrec_mutable
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %bref = type { i1 }
  %r = type { i64 }
  
  @schmu_rf = global %bref zeroinitializer, align 1
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"false\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"true\00" }
  @2 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%s\0A\00" }
  @3 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define void @schmu_change-int(i64* %i, i64 %j) {
  entry:
    %0 = alloca i64*, align 8
    store i64* %i, i64** %0, align 8
    %1 = alloca i64, align 8
    store i64 %j, i64* %1, align 8
    %2 = add i64 %j, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 101
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    store i64 100, i64* %i, align 8
    ret void
  
  else:                                             ; preds = %rec
    store i64* %i, i64** %0, align 8
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_dontmut-bref(i64 %i, %bref* %rf) {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, i64* %0, align 8
    %1 = alloca %bref*, align 8
    store %bref* %rf, %bref** %1, align 8
    %2 = alloca %bref, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %3 = phi i64 [ %add, %else ], [ %i, %entry ]
    %rf1 = phi %bref* [ %2, %else ], [ %rf, %entry ]
    %gt = icmp sgt i64 %3, 0
    br i1 %gt, label %then, label %else
  
  then:                                             ; preds = %rec
    %4 = bitcast %bref* %rf1 to i1*
    store i1 false, i1* %4, align 1
    ret void
  
  else:                                             ; preds = %rec
    %a3 = bitcast %bref* %2 to i1*
    store i1 true, i1* %a3, align 1
    %add = add i64 %3, 1
    store i64 %add, i64* %0, align 8
    store %bref* %2, %bref** %1, align 8
    br label %rec
  }
  
  define void @schmu_mod-rec(%r* %r, i64 %i) {
  entry:
    %0 = alloca %r*, align 8
    store %r* %r, %r** %0, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %3 = bitcast %r* %r to i64*
    store i64 2, i64* %3, align 8
    ret void
  
  else:                                             ; preds = %rec
    store %r* %r, %r** %0, align 8
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_mut-bref(i64 %i, %bref* %rf) {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, i64* %0, align 8
    %1 = alloca %bref*, align 8
    store %bref* %rf, %bref** %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %gt = icmp sgt i64 %2, 0
    br i1 %gt, label %then, label %else
  
  then:                                             ; preds = %rec
    %3 = bitcast %bref* %rf to i1*
    store i1 true, i1* %3, align 1
    ret void
  
  else:                                             ; preds = %rec
    %add = add i64 %2, 1
    store i64 %add, i64* %0, align 8
    store %bref* %rf, %bref** %1, align 8
    br label %rec
  }
  
  define void @schmu_push-twice(i64** %a, i64 %i) {
  entry:
    %0 = alloca i64**, align 8
    store i64** %a, i64*** %0, align 8
    %1 = alloca i1, align 1
    store i1 false, i1* %1, align 1
    %2 = alloca i64, align 8
    store i64 %i, i64* %2, align 8
    %3 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %merge, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %merge ], [ %3, %entry ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    store i1 true, i1* %1, align 1
    ret void
  
  else:                                             ; preds = %rec
    %4 = load i64*, i64** %a, align 8
    %size2 = load i64, i64* %4, align 8
    %cap = getelementptr i64, i64* %4, i64 1
    %cap3 = load i64, i64* %cap, align 8
    %5 = icmp eq i64 %cap3, %size2
    br i1 %5, label %grow, label %merge
  
  grow:                                             ; preds = %else
    %6 = tail call i64* @__ag.ag_grow_ai.ai(i64** %a)
    br label %merge
  
  merge:                                            ; preds = %else, %grow
    %7 = phi i64* [ %6, %grow ], [ %4, %else ]
    %8 = bitcast i64* %7 to i8*
    %9 = mul i64 8, %size2
    %10 = add i64 16, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data = bitcast i8* %11 to i64*
    store i64 20, i64* %data, align 8
    %12 = add i64 %size2, 1
    store i64 %12, i64* %7, align 8
    store i64** %a, i64*** %0, align 8
    store i64 %lsr.iv, i64* %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(i64** %a, i64 %i) {
  entry:
    %0 = alloca i64**, align 8
    store i64** %a, i64*** %0, align 8
    %1 = alloca i1, align 1
    store i1 false, i1* %1, align 1
    %2 = alloca i64, align 8
    store i64 %i, i64* %2, align 8
    %3 = alloca i64*, align 8
    %4 = alloca i64*, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %cont, %cont11, %entry
    %.ph = phi i1 [ false, %entry ], [ true, %cont ], [ %12, %cont11 ]
    %.ph29 = phi i1 [ false, %entry ], [ true, %cont ], [ true, %cont11 ]
    %.ph30 = phi i1 [ false, %entry ], [ true, %cont ], [ true, %cont11 ]
    %.ph31 = phi i64 [ %i, %entry ], [ 3, %cont ], [ 11, %cont11 ]
    %.ph32 = phi i64** [ %a, %entry ], [ %3, %cont ], [ %4, %cont11 ]
    %5 = add i64 %.ph31, 1
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %merge
    %lsr.iv = phi i64 [ %5, %rec.outer ], [ %lsr.iv.next, %merge ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %6 = call i8* @malloc(i64 24)
    %7 = bitcast i8* %6 to i64*
    store i64* %7, i64** %3, align 8
    store i64 1, i64* %7, align 8
    %cap = getelementptr i64, i64* %7, i64 1
    store i64 1, i64* %cap, align 8
    %8 = getelementptr i8, i8* %6, i64 16
    %data = bitcast i8* %8 to i64*
    store i64 10, i64* %data, align 8
    br i1 %.ph, label %call_decr, label %cookie
  
  call_decr:                                        ; preds = %then
    call void @__free_ai(i64** %.ph32)
    br label %cont
  
  cookie:                                           ; preds = %then
    store i1 true, i1* %1, align 1
    br label %cont
  
  cont:                                             ; preds = %cookie, %call_decr
    store i64** %3, i64*** %0, align 8
    store i64 3, i64* %2, align 8
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq2 = icmp eq i64 %lsr.iv, 11
    br i1 %eq2, label %then3, label %else12
  
  then3:                                            ; preds = %else
    %9 = call i8* @malloc(i64 24)
    %10 = bitcast i8* %9 to i64*
    store i64* %10, i64** %4, align 8
    store i64 1, i64* %10, align 8
    %cap5 = getelementptr i64, i64* %10, i64 1
    store i64 1, i64* %cap5, align 8
    %11 = getelementptr i8, i8* %9, i64 16
    %data6 = bitcast i8* %11 to i64*
    store i64 10, i64* %data6, align 8
    br i1 %.ph29, label %call_decr9, label %cookie10
  
  call_decr9:                                       ; preds = %then3
    call void @__free_ai(i64** %.ph32)
    br label %cont11
  
  cookie10:                                         ; preds = %then3
    store i1 true, i1* %1, align 1
    br label %cont11
  
  cont11:                                           ; preds = %cookie10, %call_decr9
    %12 = phi i1 [ true, %cookie10 ], [ %.ph, %call_decr9 ]
    store i64** %4, i64*** %0, align 8
    store i64 11, i64* %2, align 8
    br label %rec.outer
  
  else12:                                           ; preds = %else
    %eq13 = icmp eq i64 %lsr.iv, 13
    br i1 %eq13, label %then14, label %else15
  
  then14:                                           ; preds = %else12
    br i1 %.ph30, label %call_decr25, label %cookie26
  
  else15:                                           ; preds = %else12
    %13 = load i64*, i64** %.ph32, align 8
    %size17 = load i64, i64* %13, align 8
    %cap18 = getelementptr i64, i64* %13, i64 1
    %cap19 = load i64, i64* %cap18, align 8
    %14 = icmp eq i64 %cap19, %size17
    br i1 %14, label %grow, label %merge
  
  grow:                                             ; preds = %else15
    %15 = call i64* @__ag.ag_grow_ai.ai(i64** %.ph32)
    br label %merge
  
  merge:                                            ; preds = %else15, %grow
    %16 = phi i64* [ %15, %grow ], [ %13, %else15 ]
    %17 = bitcast i64* %16 to i8*
    %18 = mul i64 8, %size17
    %19 = add i64 16, %18
    %20 = getelementptr i8, i8* %17, i64 %19
    %data20 = bitcast i8* %20 to i64*
    store i64 20, i64* %data20, align 8
    %21 = add i64 %size17, 1
    store i64 %21, i64* %16, align 8
    store i64** %.ph32, i64*** %0, align 8
    store i64 %lsr.iv, i64* %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  call_decr25:                                      ; preds = %then14
    call void @__free_ai(i64** %.ph32)
    br label %cont27
  
  cookie26:                                         ; preds = %then14
    store i1 true, i1* %1, align 1
    br label %cont27
  
  cont27:                                           ; preds = %cookie26, %call_decr25
    ret void
  }
  
  define internal i64* @__ag.ag_grow_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 2
    %3 = mul i64 %2, 8
    %4 = add i64 %3, 16
    %5 = load i64*, i64** %0, align 8
    %6 = bitcast i64* %5 to i8*
    %7 = call i8* @realloc(i8* %6, i64 %4)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %0, align 8
    %newcap = getelementptr i64, i64* %8, i64 1
    store i64 %2, i64* %newcap, align 8
    %9 = load i64*, i64** %0, align 8
    ret i64* %9
  }
  
  define internal void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i1 false, i1* getelementptr inbounds (%bref, %bref* @schmu_rf, i32 0, i32 0), align 1
    tail call void @schmu_mut-bref(i64 0, %bref* @schmu_rf)
    %0 = load i1, i1* getelementptr inbounds (%bref, %bref* @schmu_rf, i32 0, i32 0), align 1
    br i1 %0, label %cont, label %free
  
  free:                                             ; preds = %entry
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %1 = phi i8* [ bitcast ({ i64, i64, [5 x i8] }* @1 to i8*), %entry ], [ bitcast ({ i64, i64, [6 x i8] }* @0 to i8*), %free ]
    %2 = getelementptr i8, i8* %1, i64 16
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @2 to i8*), i64 16), i8* %2)
    tail call void @schmu_dontmut-bref(i64 0, %bref* @schmu_rf)
    %3 = load i1, i1* getelementptr inbounds (%bref, %bref* @schmu_rf, i32 0, i32 0), align 1
    br i1 %3, label %cont2, label %free1
  
  free1:                                            ; preds = %cont
    br label %cont2
  
  cont2:                                            ; preds = %free1, %cont
    %4 = phi i8* [ bitcast ({ i64, i64, [5 x i8] }* @1 to i8*), %cont ], [ bitcast ({ i64, i64, [6 x i8] }* @0 to i8*), %free1 ]
    %5 = getelementptr i8, i8* %4, i64 16
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @2 to i8*), i64 16), i8* %5)
    %6 = alloca %r, align 8
    %a7 = bitcast %r* %6 to i64*
    store i64 20, i64* %a7, align 8
    call void @schmu_mod-rec(%r* %6, i64 0)
    %7 = load i64, i64* %a7, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @3 to i8*), i64 16), i64 %7)
    %8 = alloca i64*, align 8
    %9 = call i8* @malloc(i64 32)
    %10 = bitcast i8* %9 to i64*
    store i64* %10, i64** %8, align 8
    store i64 2, i64* %10, align 8
    %cap = getelementptr i64, i64* %10, i64 1
    store i64 2, i64* %cap, align 8
    %11 = getelementptr i8, i8* %9, i64 16
    %data = bitcast i8* %11 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    call void @schmu_push-twice(i64** %8, i64 0)
    %12 = load i64*, i64** %8, align 8
    %13 = load i64, i64* %12, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @3 to i8*), i64 16), i64 %13)
    %14 = alloca i64, align 8
    store i64 0, i64* %14, align 8
    call void @schmu_change-int(i64* %14, i64 0)
    %15 = load i64, i64* %14, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @3 to i8*), i64 16), i64 %15)
    %16 = alloca i64*, align 8
    %17 = call i8* @malloc(i64 24)
    %18 = bitcast i8* %17 to i64*
    store i64* %18, i64** %16, align 8
    store i64 0, i64* %18, align 8
    %cap4 = getelementptr i64, i64* %18, i64 1
    store i64 1, i64* %cap4, align 8
    %19 = getelementptr i8, i8* %17, i64 16
    call void @schmu_test(i64** %16, i64 0)
    %20 = load i64*, i64** %16, align 8
    %21 = load i64, i64* %20, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @3 to i8*), i64 16), i64 %21)
    call void @__free_ai(i64** %16)
    call void @__free_ai(i64** %8)
    ret i64 0
  }
  
  declare void @printf(i8* %0, ...)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  declare void @free(i8* %0)
  true
  true
  2
  4
  100
  2

The lamba passed as array-iter argument is polymorphic
  $ schmu polymorphic_lambda_argument.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./polymorphic_lambda_argument
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_arr = global i64* null, align 8
  @0 = private unnamed_addr constant { i64, i64, [1 x [1 x i8]] } { i64 0, i64 1, [1 x [1 x i8]] zeroinitializer }
  @1 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%li\00" }
  @2 = private unnamed_addr constant { i64, i64, [3 x i8] } { i64 2, i64 2, [3 x i8] c", \00" }
  
  declare void @prelude_print(i8* %0)
  
  define i8* @__agac.ac_schmu_string-concat_aiac.ac(i64* %arr, i8* %delim) {
  entry:
    %0 = alloca i8*, align 8
    %1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [1 x [1 x i8]] }* @0 to i8*), i8** %1, align 8
    %2 = bitcast i8** %0 to i8*
    %3 = bitcast i8** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac(i8** %0)
    %__ig.u-ac-ac___fun_schmu1_ii.u-ac-ac = alloca %closure, align 8
    %funptr2 = bitcast %closure* %__ig.u-ac-ac___fun_schmu1_ii.u-ac-ac to i8**
    store i8* bitcast (void (i64, i64, i8*)* @__ig.u-ac-ac___fun_schmu1_ii.u-ac-ac to i8*), i8** %funptr2, align 8
    %clsr___ig.u-ac-ac___fun_schmu1_ii.u-ac-ac = alloca { i8*, i8*, i8**, i8* }, align 8
    %acc = getelementptr inbounds { i8*, i8*, i8**, i8* }, { i8*, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun_schmu1_ii.u-ac-ac, i32 0, i32 2
    store i8** %0, i8*** %acc, align 8
    %delim1 = getelementptr inbounds { i8*, i8*, i8**, i8* }, { i8*, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun_schmu1_ii.u-ac-ac, i32 0, i32 3
    store i8* %delim, i8** %delim1, align 8
    %ctor3 = bitcast { i8*, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun_schmu1_ii.u-ac-ac to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ac-ac to i8*), i8** %ctor3, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i8**, i8* }, { i8*, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun_schmu1_ii.u-ac-ac, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun_schmu1_ii.u-ac-ac to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__ig.u-ac-ac___fun_schmu1_ii.u-ac-ac, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__agig.u.u_prelude_array-iteri_aiii.u.u(i64* %arr, %closure* %__ig.u-ac-ac___fun_schmu1_ii.u-ac-ac)
    call void @schmu_string-add-null(i8** %0)
    %4 = load i8*, i8** %0, align 8
    ret i8* %4
  }
  
  define void @__agag.u_schmu_string-append_acac.u(i8** %str, i8* %app) {
  entry:
    %__g.u-ag___fun_schmu0_c.u-ac = alloca %closure, align 8
    %funptr2 = bitcast %closure* %__g.u-ag___fun_schmu0_c.u-ac to i8**
    store i8* bitcast (void (i8, i8*)* @__g.u-ag___fun_schmu0_c.u-ac to i8*), i8** %funptr2, align 8
    %clsr___g.u-ag___fun_schmu0_c.u-ac = alloca { i8*, i8*, i8** }, align 8
    %str1 = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr___g.u-ag___fun_schmu0_c.u-ac, i32 0, i32 2
    store i8** %str, i8*** %str1, align 8
    %ctor3 = bitcast { i8*, i8*, i8** }* %clsr___g.u-ag___fun_schmu0_c.u-ac to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ac to i8*), i8** %ctor3, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr___g.u-ag___fun_schmu0_c.u-ac, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i8** }* %clsr___g.u-ag___fun_schmu0_c.u-ac to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__g.u-ag___fun_schmu0_c.u-ac, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__agg.u.u_prelude_array-iter_acc.u.u(i8* %app, %closure* %__g.u-ag___fun_schmu0_c.u-ac)
    ret void
  }
  
  define void @__agg.u.u_prelude_array-iter_acc.u.u(i8* %arr, %closure* %f) {
  entry:
    %__i.u-ag-g.u_prelude_inner_i.u-ac-c.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-ag-g.u_prelude_inner_i.u-ac-c.u to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-ag-g.u_prelude_inner_i.u-ac-c.u to i8*), i8** %funptr5, align 8
    %clsr___i.u-ag-g.u_prelude_inner_i.u-ac-c.u = alloca { i8*, i8*, i8*, %closure }, align 8
    %arr1 = getelementptr inbounds { i8*, i8*, i8*, %closure }, { i8*, i8*, i8*, %closure }* %clsr___i.u-ag-g.u_prelude_inner_i.u-ac-c.u, i32 0, i32 2
    store i8* %arr, i8** %arr1, align 8
    %f2 = getelementptr inbounds { i8*, i8*, i8*, %closure }, { i8*, i8*, i8*, %closure }* %clsr___i.u-ag-g.u_prelude_inner_i.u-ac-c.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor6 = bitcast { i8*, i8*, i8*, %closure }* %clsr___i.u-ag-g.u_prelude_inner_i.u-ac-c.u to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ac-c.u to i8*), i8** %ctor6, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i8*, %closure }, { i8*, i8*, i8*, %closure }* %clsr___i.u-ag-g.u_prelude_inner_i.u-ac-c.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i8*, %closure }* %clsr___i.u-ag-g.u_prelude_inner_i.u-ac-c.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-g.u_prelude_inner_i.u-ac-c.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__i.u-ag-g.u_prelude_inner_i.u-ac-c.u(i64 0, i8* %env)
    ret void
  }
  
  define void @__agig.u.u_prelude_array-iteri_aiii.u.u(i64* %arr, %closure* %f) {
  entry:
    %__i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u to i8*), i8** %funptr5, align 8
    %clsr___i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u = alloca { i8*, i8*, i64*, %closure }, align 8
    %arr1 = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u, i32 0, i32 2
    store i64* %arr, i64** %arr1, align 8
    %f2 = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor6 = bitcast { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ai-ii.u to i8*), i8** %ctor6, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u(i64 0, i8* %env)
    ret void
  }
  
  define void @__g.u-ag___fun_schmu0_c.u-ac(i8 %char, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i8** }*
    %str = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr, i32 0, i32 2
    %str1 = load i8**, i8*** %str, align 8
    %1 = load i8*, i8** %str1, align 8
    %2 = bitcast i8* %1 to i64*
    %size2 = load i64, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    %cap3 = load i64, i64* %cap, align 8
    %3 = icmp eq i64 %cap3, %size2
    br i1 %3, label %grow, label %merge
  
  grow:                                             ; preds = %entry
    %4 = tail call i8* @__ag.ag_grow_ac.ac(i8** %str1)
    %.pre = bitcast i8* %4 to i64*
    br label %merge
  
  merge:                                            ; preds = %entry, %grow
    %.pre-phi = phi i64* [ %.pre, %grow ], [ %2, %entry ]
    %5 = phi i8* [ %4, %grow ], [ %1, %entry ]
    %6 = add i64 16, %size2
    %7 = getelementptr i8, i8* %5, i64 %6
    store i8 %char, i8* %7, align 1
    %8 = add i64 %size2, 1
    store i64 %8, i64* %.pre-phi, align 8
    ret void
  }
  
  define void @__i.u-ag-g.u_prelude_inner_i.u-ac-c.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i8*, %closure }*
    %arr = getelementptr inbounds { i8*, i8*, i8*, %closure }, { i8*, i8*, i8*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i8*, i8** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %3 = bitcast i8* %arr1 to i64*
    %4 = load i64, i64* %3, align 8
    %eq = icmp eq i64 %2, %4
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = getelementptr i8, i8* %arr1, i64 %2
    %sunkaddr4 = getelementptr i8, i8* %sunkaddr, i64 16
    %5 = load i8, i8* %sunkaddr4, align 1
    %sunkaddr6 = getelementptr inbounds i8, i8* %0, i64 24
    %6 = bitcast i8* %sunkaddr6 to i8**
    %loadtmp = load i8*, i8** %6, align 8
    %casttmp = bitcast i8* %loadtmp to void (i8, i8*)*
    %sunkaddr7 = getelementptr inbounds i8, i8* %0, i64 32
    %7 = bitcast i8* %sunkaddr7 to i8**
    %loadtmp2 = load i8*, i8** %7, align 8
    tail call void %casttmp(i8 %5, i8* %loadtmp2)
    %add = add i64 %2, 1
    store i64 %add, i64* %1, align 8
    br label %rec
  }
  
  define void @__i.u-ag-ig.u_prelude_inner__2_i.u-ai-ii.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64*, %closure }*
    %arr = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %3 = add i64 %lsr.iv, -1
    %4 = load i64, i64* %arr1, align 8
    %eq = icmp eq i64 %3, %4
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %scevgep = getelementptr i64, i64* %arr1, i64 %lsr.iv
    %scevgep3 = getelementptr i64, i64* %scevgep, i64 1
    %5 = load i64, i64* %scevgep3, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 24
    %6 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %6, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i64, i8*)*
    %sunkaddr5 = getelementptr inbounds i8, i8* %0, i64 32
    %7 = bitcast i8* %sunkaddr5 to i8**
    %loadtmp2 = load i8*, i8** %7, align 8
    tail call void %casttmp(i64 %3, i64 %5, i8* %loadtmp2)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @__ig.u-ac-ac___fun_schmu1_ii.u-ac-ac(i64 %i, i64 %v, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i8**, i8* }*
    %acc = getelementptr inbounds { i8*, i8*, i8**, i8* }, { i8*, i8*, i8**, i8* }* %clsr, i32 0, i32 2
    %acc1 = load i8**, i8*** %acc, align 8
    %delim = getelementptr inbounds { i8*, i8*, i8**, i8* }, { i8*, i8*, i8**, i8* }* %clsr, i32 0, i32 3
    %delim2 = load i8*, i8** %delim, align 8
    %gt = icmp sgt i64 %i, 0
    br i1 %gt, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    tail call void @__agag.u_schmu_string-append_acac.u(i8** %acc1, i8* %delim2)
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @1 to i8*), i64 16), i64 %v)
    %1 = add i32 %fmtsize, 17
    %2 = sext i32 %1 to i64
    %3 = tail call i8* @malloc(i64 %2)
    %4 = bitcast i8* %3 to i64*
    %5 = sext i32 %fmtsize to i64
    store i64 %5, i64* %4, align 8
    %cap = getelementptr i64, i64* %4, i64 1
    store i64 %5, i64* %cap, align 8
    %data = getelementptr i64, i64* %4, i64 2
    %6 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %2, i8* getelementptr (i8, i8* bitcast ({ i64, i64, [4 x i8] }* @1 to i8*), i64 16), i64 %v)
    %str = alloca i8*, align 8
    store i8* %3, i8** %str, align 8
    tail call void @__agag.u_schmu_string-append_acac.u(i8** %acc1, i8* %3)
    call void @__free_ac(i8** %str)
    ret void
  }
  
  define void @schmu_string-add-null(i8** %str) {
  entry:
    %0 = load i8*, i8** %str, align 8
    %1 = bitcast i8* %0 to i64*
    %size1 = load i64, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap2 = load i64, i64* %cap, align 8
    %2 = icmp eq i64 %cap2, %size1
    br i1 %2, label %grow, label %merge
  
  grow:                                             ; preds = %entry
    %3 = tail call i8* @__ag.ag_grow_ac.ac(i8** %str)
    %.pre = bitcast i8* %3 to i64*
    br label %merge
  
  merge:                                            ; preds = %entry, %grow
    %.pre-phi = phi i64* [ %.pre, %grow ], [ %1, %entry ]
    %4 = phi i8* [ %3, %grow ], [ %0, %entry ]
    %5 = add i64 16, %size1
    %6 = getelementptr i8, i8* %4, i64 %5
    store i8 0, i8* %6, align 1
    %7 = add i64 %size1, 1
    store i64 %7, i64* %.pre-phi, align 8
    %8 = load i8*, i8** %str, align 8
    %9 = bitcast i8* %8 to i64*
    %size5 = load i64, i64* %9, align 8
    %10 = icmp sgt i64 %size5, 0
    br i1 %10, label %drop_last, label %cont
  
  drop_last:                                        ; preds = %merge
    %11 = bitcast i8* %8 to i64*
    %12 = sub i64 %size5, 1
    %13 = add i64 16, %12
    %14 = getelementptr i8, i8* %8, i64 %13
    store i64 %12, i64* %11, align 8
    br label %cont
  
  cont:                                             ; preds = %drop_last, %merge
    ret void
  }
  
  define internal void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz2 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %ref, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 16
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal i8* @__ctor_tup-ac-ac(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i8**, i8* }*
    %2 = call i8* @malloc(i64 32)
    %3 = bitcast i8* %2 to { i8*, i8*, i8**, i8* }*
    %4 = bitcast { i8*, i8*, i8**, i8* }* %3 to i8*
    %5 = bitcast { i8*, i8*, i8**, i8* }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 32, i1 false)
    %acc = getelementptr inbounds { i8*, i8*, i8**, i8* }, { i8*, i8*, i8**, i8* }* %3, i32 0, i32 2
    %6 = bitcast i8*** %acc to i8**
    call void @__copy_ac(i8** %6)
    %delim = getelementptr inbounds { i8*, i8*, i8**, i8* }, { i8*, i8*, i8**, i8* }* %3, i32 0, i32 3
    call void @__copy_ac(i8** %delim)
    %7 = bitcast { i8*, i8*, i8**, i8* }* %3 to i8*
    ret i8* %7
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal i8* @__ctor_tup-ac(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i8** }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, i8** }*
    %4 = bitcast { i8*, i8*, i8** }* %3 to i8*
    %5 = bitcast { i8*, i8*, i8** }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %str = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %3, i32 0, i32 2
    %6 = bitcast i8*** %str to i8**
    call void @__copy_ac(i8** %6)
    %7 = bitcast { i8*, i8*, i8** }* %3 to i8*
    ret i8* %7
  }
  
  define internal i8* @__ctor_tup-ac-c.u(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i8*, %closure }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, i8*, %closure }*
    %4 = bitcast { i8*, i8*, i8*, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, i8*, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %arr = getelementptr inbounds { i8*, i8*, i8*, %closure }, { i8*, i8*, i8*, %closure }* %3, i32 0, i32 2
    call void @__copy_ac(i8** %arr)
    %f = getelementptr inbounds { i8*, i8*, i8*, %closure }, { i8*, i8*, i8*, %closure }* %3, i32 0, i32 3
    call void @__copy_c.u(%closure* %f)
    %6 = bitcast { i8*, i8*, i8*, %closure }* %3 to i8*
    ret i8* %6
  }
  
  define internal void @__copy_c.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define internal i8* @__ctor_tup-ai-ii.u(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64*, %closure }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, i64*, %closure }*
    %4 = bitcast { i8*, i8*, i64*, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64*, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %arr = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %3, i32 0, i32 2
    call void @__copy_ai(i64** %arr)
    %f = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %3, i32 0, i32 3
    call void @__copy_ii.u(%closure* %f)
    %6 = bitcast { i8*, i8*, i64*, %closure }* %3 to i8*
    ret i8* %6
  }
  
  define internal void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz2 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define internal void @__copy_ii.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define internal i8* @__ag.ag_grow_ac.ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %2 = bitcast i8* %1 to i64*
    %cap = getelementptr i64, i64* %2, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %3 = mul i64 %cap1, 2
    %4 = mul i64 %3, 1
    %5 = add i64 %4, 16
    %6 = load i8*, i8** %0, align 8
    %7 = call i8* @realloc(i8* %6, i64 %5)
    store i8* %7, i8** %0, align 8
    %newcap = bitcast i8* %7 to i64*
    %newcap2 = getelementptr i64, i64* %newcap, i64 1
    store i64 %3, i64* %newcap2, align 8
    %8 = load i8*, i8** %0, align 8
    ret i8* %8
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  define internal void @__free_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 96)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @schmu_arr, align 8
    store i64 10, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 10, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 1, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 2, i64* %"1", align 8
    %"2" = getelementptr i64, i64* %data, i64 2
    store i64 3, i64* %"2", align 8
    %"3" = getelementptr i64, i64* %data, i64 3
    store i64 4, i64* %"3", align 8
    %"4" = getelementptr i64, i64* %data, i64 4
    store i64 5, i64* %"4", align 8
    %"5" = getelementptr i64, i64* %data, i64 5
    store i64 6, i64* %"5", align 8
    %"6" = getelementptr i64, i64* %data, i64 6
    store i64 7, i64* %"6", align 8
    %"7" = getelementptr i64, i64* %data, i64 7
    store i64 8, i64* %"7", align 8
    %"8" = getelementptr i64, i64* %data, i64 8
    store i64 9, i64* %"8", align 8
    %"9" = getelementptr i64, i64* %data, i64 9
    store i64 10, i64* %"9", align 8
    %3 = load i64*, i64** @schmu_arr, align 8
    %4 = tail call i8* @__agac.ac_schmu_string-concat_aiac.ac(i64* %3, i8* bitcast ({ i64, i64, [3 x i8] }* @2 to i8*))
    tail call void @prelude_print(i8* %4)
    %5 = alloca i8*, align 8
    store i8* %4, i8** %5, align 8
    call void @__free_ac(i8** %5)
    call void @__free_ai(i64** @schmu_arr)
    ret i64 0
  }
  
  define internal void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
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
  $ schmu poly_fn_ret_fn.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./poly_fn_ret_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_once = global i1 false, align 1
  @schmu_foo = global %closure zeroinitializer, align 16
  @schmu_result = global %closure zeroinitializer, align 16
  @0 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"%s foo\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [9 x i8] } { i64 8, i64 8, [9 x i8] c"%li foo\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [8 x i8] } { i64 7, i64 7, [8 x i8] c"%s bar\0A\00" }
  @3 = private unnamed_addr constant { i64, i64, [9 x i8] } { i64 8, i64 8, [9 x i8] c"%li bar\0A\00" }
  @4 = private unnamed_addr constant { i64, i64, [2 x i8] } { i64 1, i64 1, [2 x i8] c"a\00" }
  
  define void @__g.u___fun_schmu0_ac.u(i8* %a) {
  entry:
    %0 = getelementptr i8, i8* %a, i64 16
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [8 x i8] }* @0 to i8*), i64 16), i8* %0)
    ret void
  }
  
  define void @__g.u___fun_schmu0_i.u(i64 %a) {
  entry:
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [9 x i8] }* @1 to i8*), i64 16), i64 %a)
    ret void
  }
  
  define void @__g.u___fun_schmu1_ac.u(i8* %_0) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr6 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i8*)* @__g.u___fun_schmu0_ac.u to i8*), i8** %funptr6, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr27 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (void (i8*)* @__g.u_schmu_bar_ac.u to i8*), i8** %funptr27, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %ret = alloca %closure, align 8
    call void @__gg.g_schmu_black-box_ac.uac.u.ac.u(%closure* %ret, %closure* %clstmp, %closure* %clstmp1)
    %funcptr8 = bitcast %closure* %ret to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to void (i8*, i8*)*
    %envptr4 = getelementptr inbounds %closure, %closure* %ret, i32 0, i32 1
    %loadtmp5 = load i8*, i8** %envptr4, align 8
    call void %casttmp(i8* %_0, i8* %loadtmp5)
    call void @__free_ac.u(%closure* %ret)
    ret void
  }
  
  define void @__g.u___fun_schmu1_i.u(i64 %_0) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr6 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @__g.u___fun_schmu0_i.u to i8*), i8** %funptr6, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr27 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (void (i64)* @__g.u_schmu_bar_i.u to i8*), i8** %funptr27, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %ret = alloca %closure, align 8
    call void @__gg.g_schmu_black-box_i.ui.u.i.u(%closure* %ret, %closure* %clstmp, %closure* %clstmp1)
    %funcptr8 = bitcast %closure* %ret to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr4 = getelementptr inbounds %closure, %closure* %ret, i32 0, i32 1
    %loadtmp5 = load i8*, i8** %envptr4, align 8
    call void %casttmp(i64 %_0, i8* %loadtmp5)
    call void @__free_i.u(%closure* %ret)
    ret void
  }
  
  define void @__g.u_schmu_bar_ac.u(i8* %a) {
  entry:
    %0 = getelementptr i8, i8* %a, i64 16
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [8 x i8] }* @2 to i8*), i64 16), i8* %0)
    ret void
  }
  
  define void @__g.u_schmu_bar_i.u(i64 %a) {
  entry:
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [9 x i8] }* @3 to i8*), i64 16), i64 %a)
    ret void
  }
  
  define void @__gg.g_schmu_black-box_ac.uac.u.ac.u(%closure* %0, %closure* %f, %closure* %g) {
  entry:
    %1 = load i1, i1* @schmu_once, align 1
    br i1 %1, label %then, label %else
  
  then:                                             ; preds = %entry
    store i1 false, i1* @schmu_once, align 1
    %2 = bitcast %closure* %0 to i8*
    %3 = bitcast %closure* %f to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 16, i1 false)
    tail call void @__copy_ac.u(%closure* %0)
    ret void
  
  else:                                             ; preds = %entry
    %4 = bitcast %closure* %0 to i8*
    %5 = bitcast %closure* %g to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 16, i1 false)
    tail call void @__copy_ac.u(%closure* %0)
    ret void
  }
  
  define void @__gg.g_schmu_black-box_i.ui.u.i.u(%closure* %0, %closure* %f, %closure* %g) {
  entry:
    %1 = load i1, i1* @schmu_once, align 1
    br i1 %1, label %then, label %else
  
  then:                                             ; preds = %entry
    store i1 false, i1* @schmu_once, align 1
    %2 = bitcast %closure* %0 to i8*
    %3 = bitcast %closure* %f to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 16, i1 false)
    tail call void @__copy_i.u(%closure* %0)
    ret void
  
  else:                                             ; preds = %entry
    %4 = bitcast %closure* %0 to i8*
    %5 = bitcast %closure* %g to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 16, i1 false)
    tail call void @__copy_i.u(%closure* %0)
    ret void
  }
  
  declare void @printf(i8* %0, ...)
  
  define internal void @__free_ac.u(%closure* %0) {
  entry:
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %env = load i8*, i8** %envptr, align 8
    %1 = icmp eq i8* %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = bitcast i8* %env to { i8*, i8* }*
    %3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %2, i32 0, i32 1
    %dtor1 = load i8*, i8** %3, align 8
    %4 = icmp eq i8* %dtor1, null
    br i1 %4, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    %dtor2 = bitcast i8* %dtor1 to void (i8*)*
    call void %dtor2(i8* %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(i8* %env)
    br label %ret
  }
  
  define internal void @__free_i.u(%closure* %0) {
  entry:
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %env = load i8*, i8** %envptr, align 8
    %1 = icmp eq i8* %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = bitcast i8* %env to { i8*, i8* }*
    %3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %2, i32 0, i32 1
    %dtor1 = load i8*, i8** %3, align 8
    %4 = icmp eq i8* %dtor1, null
    br i1 %4, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    %dtor2 = bitcast i8* %dtor1 to void (i8*)*
    call void %dtor2(i8* %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(i8* %env)
    br label %ret
  }
  
  define internal void @__copy_ac.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__copy_i.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i1 true, i1* @schmu_once, align 1
    tail call void @__g.u___fun_schmu1_ac.u(i8* bitcast ({ i64, i64, [2 x i8] }* @4 to i8*))
    tail call void @__g.u___fun_schmu1_i.u(i64 10)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  a foo
  10 bar
