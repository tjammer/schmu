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
  
  define i64 @schmu_fib(i64 %n) {
  entry:
    %lt = icmp slt i64 %n, 2
    br i1 %lt, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %0 = tail call i64 @schmu_fibn2(i64 %n)
    %1 = tail call i64 @schmu___fun0(i64 %n)
    %add = add i64 %0, %1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %add, %else ], [ %n, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu___fun0(i64 %n) {
  entry:
    %sub = sub i64 %n, 1
    %0 = tail call i64 @schmu_fib(i64 %sub)
    ret i64 %0
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
  
  define i64 @schmu_add(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
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
  
  @a = global %capturable zeroinitializer, align 8
  
  define i64 @schmu_capture_a_wrapped() {
  entry:
    %0 = tail call i64 @schmu_wrap()
    ret i64 %0
  }
  
  define i64 @schmu_wrap() {
  entry:
    %0 = tail call i64 @schmu_inner()
    ret i64 %0
  }
  
  define i64 @schmu_inner() {
  entry:
    %0 = load i64, i64* getelementptr inbounds (%capturable, %capturable* @a, i32 0, i32 0), align 4
    %add = add i64 %0, 2
    ret i64 %add
  }
  
  define i64 @schmu_capture_a() {
  entry:
    %0 = load i64, i64* getelementptr inbounds (%capturable, %capturable* @a, i32 0, i32 0), align 4
    %add = add i64 %0, 2
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 10, i64* getelementptr inbounds (%capturable, %capturable* @a, i32 0, i32 0), align 4
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
  
  @pass2 = global %closure zeroinitializer, align 8
  
  declare void @printi(i64 %0)
  
  define i64 @schmu___g.g___fun0_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu___g.g_pass_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu___fun2(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i1 @schmu___gg.g.g_apply_bb.b.b(i1 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i1 (i1, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i1 %casttmp(i1 %x, i8* %loadtmp1)
    ret i1 %0
  }
  
  define i64 @schmu___fun1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @schmu___gg.g.g_apply_ii.i.i(i64 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i64 %x, i8* %loadtmp1)
    ret i64 %0
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
  
  define i64 @schmu_add1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr16 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64)* @schmu_add1 to i8*), i8** %funptr16, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @schmu___gg.g.g_apply_ii.i.i(i64 0, %closure* %clstmp)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr217 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @schmu___fun1 to i8*), i8** %funptr217, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %1 = call i64 @schmu___gg.g.g_apply_ii.i.i(i64 1, %closure* %clstmp1)
    call void @printi(i64 %1)
    %clstmp4 = alloca %closure, align 8
    %funptr518 = bitcast %closure* %clstmp4 to i8**
    store i8* bitcast (i1 (i1)* @schmu_makefalse to i8*), i8** %funptr518, align 8
    %envptr6 = getelementptr inbounds %closure, %closure* %clstmp4, i32 0, i32 1
    store i8* null, i8** %envptr6, align 8
    %2 = call i1 @schmu___gg.g.g_apply_bb.b.b(i1 true, %closure* %clstmp4)
    %3 = call i64 @schmu_int_of_bool(i1 %2)
    call void @printi(i64 %3)
    %clstmp7 = alloca %closure, align 8
    %funptr819 = bitcast %closure* %clstmp7 to i8**
    store i8* bitcast (i64 (i64)* @schmu___fun2 to i8*), i8** %funptr819, align 8
    %envptr9 = getelementptr inbounds %closure, %closure* %clstmp7, i32 0, i32 1
    store i8* null, i8** %envptr9, align 8
    %4 = call i64 @schmu___gg.g.g_apply_ii.i.i(i64 3, %closure* %clstmp7)
    call void @printi(i64 %4)
    %clstmp10 = alloca %closure, align 8
    %funptr1120 = bitcast %closure* %clstmp10 to i8**
    store i8* bitcast (i64 (i64)* @schmu___g.g_pass_i.i to i8*), i8** %funptr1120, align 8
    %envptr12 = getelementptr inbounds %closure, %closure* %clstmp10, i32 0, i32 1
    store i8* null, i8** %envptr12, align 8
    %5 = call i64 @schmu___gg.g.g_apply_ii.i.i(i64 4, %closure* %clstmp10)
    call void @printi(i64 %5)
    %clstmp13 = alloca %closure, align 8
    %funptr1421 = bitcast %closure* %clstmp13 to i8**
    store i8* bitcast (i64 (i64)* @schmu___g.g___fun0_i.i to i8*), i8** %funptr1421, align 8
    %envptr15 = getelementptr inbounds %closure, %closure* %clstmp13, i32 0, i32 1
    store i8* null, i8** %envptr15, align 8
    %6 = call i64 @schmu___gg.g.g_apply_ii.i.i(i64 5, %closure* %clstmp13)
    call void @printi(i64 %6)
    ret i64 0
  }
  1
  2
  0
  3
  4
  5

We don't allow returning closures
  $ schmu --dump-llvm stub.o no_closure_returns.smu && ./no_closure_returns
  no_closure_returns.smu:7:7: error: Cannot (yet) return a closure
  7 | ......fun []
  8 |           (val a (fun [] a))
  9 |           a..
  
  [1]

Don't try to create 'void' value in if
  $ schmu --dump-llvm stub.o if_return_void.smu && ./if_return_void
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define void @schmu_foo(i64 %i) {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, i64* %0, align 4
    br label %rec
  
  rec:                                              ; preds = %ifcont, %entry
    %i1 = phi i64 [ %sub5, %ifcont ], [ %i, %entry ]
    %lt = icmp slt i64 %i1, 2
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %rec
    %1 = add i64 %i1, -1
    tail call void @printi(i64 %1)
    ret void
  
  else:                                             ; preds = %rec
    %lt2 = icmp slt i64 %i1, 400
    br i1 %lt2, label %then3, label %else4
  
  then3:                                            ; preds = %else
    tail call void @printi(i64 %i1)
    br label %ifcont
  
  else4:                                            ; preds = %else
    %add = add i64 %i1, 1
    tail call void @printi(i64 %add)
    br label %ifcont
  
  ifcont:                                           ; preds = %else4, %then3
    %sub5 = sub i64 %i1, 1
    %2 = add i64 %i1, -1
    store i64 %2, i64* %0, align 4
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
  
  @b = constant i64 2
  
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
  
  define i64 @schmu_two() {
  entry:
    ret i64 2
  }
  
  define i64 @schmu_one() {
  entry:
    ret i64 1
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
  %t_bool = type { i1 }
  %t_int = type { i64 }
  
  @a = constant i64 2
  @f = global %closure zeroinitializer, align 8
  
  declare void @printi(i64 %0)
  
  define i64 @schmu___fun1(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu___g.g___fun0_ti.ti(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    ret i64 %0
  }
  
  define i1 @schmu___gg.g.g_apply_bb.b.b(i1 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i1 (i1, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i1 %casttmp(i1 %x, i8* %loadtmp1)
    ret i1 %0
  }
  
  define i8 @schmu___gg.g.g_apply_tbtb.tb.tb(i8 %0, %closure* %f) {
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
  
  define i64 @schmu___gg.g.g_apply_titi.ti.ti(i64 %0, %closure* %f) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    %1 = tail call i64 %casttmp(i64 %0, i8* %loadtmp3)
    %box4 = bitcast %t_int* %ret to i64*
    store i64 %1, i64* %box4, align 4
    ret i64 %1
  }
  
  define i64 @schmu___gg.g.g_apply_ii.i.i(i64 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i64 %x, i8* %loadtmp1)
    ret i64 %0
  }
  
  define i64 @schmu_add3_rec(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %1 = alloca %t_int, align 8
    %x3 = bitcast %t_int* %1 to i64*
    %add = add i64 %0, 3
    store i64 %add, i64* %x3, align 4
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
  
  define i64 @schmu_add1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @schmu_add_closed(i64 %x) {
  entry:
    %add = add i64 %x, 2
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr20 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64)* @schmu_add1 to i8*), i8** %funptr20, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @schmu___gg.g.g_apply_ii.i.i(i64 20, %closure* %clstmp)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr221 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @schmu_add_closed to i8*), i8** %funptr221, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %1 = call i64 @schmu___gg.g.g_apply_ii.i.i(i64 20, %closure* %clstmp1)
    call void @printi(i64 %1)
    %clstmp4 = alloca %closure, align 8
    %funptr522 = bitcast %closure* %clstmp4 to i8**
    store i8* bitcast (i64 (i64)* @schmu_add3_rec to i8*), i8** %funptr522, align 8
    %envptr6 = getelementptr inbounds %closure, %closure* %clstmp4, i32 0, i32 1
    store i8* null, i8** %envptr6, align 8
    %ret = alloca %t_int, align 8
    %2 = call i64 @schmu___gg.g.g_apply_titi.ti.ti(i64 20, %closure* %clstmp4)
    %box = bitcast %t_int* %ret to i64*
    store i64 %2, i64* %box, align 4
    call void @printi(i64 %2)
    %clstmp8 = alloca %closure, align 8
    %funptr923 = bitcast %closure* %clstmp8 to i8**
    store i8* bitcast (i8 (i8)* @schmu_make_rec_false to i8*), i8** %funptr923, align 8
    %envptr10 = getelementptr inbounds %closure, %closure* %clstmp8, i32 0, i32 1
    store i8* null, i8** %envptr10, align 8
    %ret11 = alloca %t_bool, align 8
    %3 = call i8 @schmu___gg.g.g_apply_tbtb.tb.tb(i8 1, %closure* %clstmp8)
    %box12 = bitcast %t_bool* %ret11 to i8*
    store i8 %3, i8* %box12, align 1
    %4 = trunc i8 %3 to i1
    call void @schmu_print_bool(i1 %4)
    %clstmp14 = alloca %closure, align 8
    %funptr1524 = bitcast %closure* %clstmp14 to i8**
    store i8* bitcast (i1 (i1)* @schmu_makefalse to i8*), i8** %funptr1524, align 8
    %envptr16 = getelementptr inbounds %closure, %closure* %clstmp14, i32 0, i32 1
    store i8* null, i8** %envptr16, align 8
    %5 = call i1 @schmu___gg.g.g_apply_bb.b.b(i1 true, %closure* %clstmp14)
    call void @schmu_print_bool(i1 %5)
    %ret17 = alloca %t_int, align 8
    %6 = call i64 @schmu___g.g___fun0_ti.ti(i64 17)
    %box18 = bitcast %t_int* %ret17 to i64*
    store i64 %6, i64* %box18, align 4
    call void @printi(i64 %6)
    %7 = call i64 @schmu___fun1(i64 18)
    call void @printi(i64 %7)
    ret i64 0
  }
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
  
  %closure = type { i8*, i8* }
  %t = type { i64, i1 }
  
  declare void @printi(i64 %0)
  
  define { i64, i8 } @schmu___g.g_pass_t.t(i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst3 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst3, align 4
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %box, i32 0, i32 1
    store i8 %1, i8* %snd, align 1
    %unbox2 = load { i64, i8 }, { i64, i8 }* %box, align 4
    ret { i64, i8 } %unbox2
  }
  
  define { i64, i8 } @schmu___g.gg.g_apply_t.tt.t(%closure* %f, i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst11 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst11, align 4
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
    store { i64, i8 } %2, { i64, i8 }* %box7, align 4
    ret { i64, i8 } %2
  }
  
  define i64 @schmu___g.g_pass_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu___g.gg.g_apply_i.ii.i(%closure* %f, i64 %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i64 %x, i8* %loadtmp1)
    ret i64 %0
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr7 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64)* @schmu___g.g_pass_i.i to i8*), i8** %funptr7, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @schmu___g.gg.g_apply_i.ii.i(%closure* %clstmp, i64 20)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr28 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast ({ i64, i8 } (i64, i8)* @schmu___g.g_pass_t.t to i8*), i8** %funptr28, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %boxconst = alloca %t, align 8
    store %t { i64 700, i1 false }, %t* %boxconst, align 4
    %unbox = bitcast %t* %boxconst to { i64, i8 }*
    %fst9 = bitcast { i64, i8 }* %unbox to i64*
    %fst4 = load i64, i64* %fst9, align 4
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %unbox, i32 0, i32 1
    %snd5 = load i8, i8* %snd, align 1
    %ret = alloca %t, align 8
    %1 = call { i64, i8 } @schmu___g.gg.g_apply_t.tt.t(%closure* %clstmp1, i64 %fst4, i8 %snd5)
    %box = bitcast %t* %ret to { i64, i8 }*
    store { i64, i8 } %1, { i64, i8 }* %box, align 4
    %2 = bitcast %t* %ret to i64*
    %3 = load i64, i64* %2, align 4
    call void @printi(i64 %3)
    ret i64 0
  }
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
  
  @a = global i64 0, align 8
  @b = global i64 0, align 8
  
  declare void @printi(i64 %0)
  
  define i64 @schmu___ggg.g.gg.g.g_apply2_titii.i.tii.i.ti(i64 %0, %closure* %f, %closure* %env) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, %closure*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    %1 = tail call i64 %casttmp(i64 %0, %closure* %env, i8* %loadtmp3)
    %box4 = bitcast %t_int* %ret to i64*
    store i64 %1, i64* %box4, align 4
    ret i64 %1
  }
  
  define i64 @schmu___tgg.g.tg_boxed2int_int_tii.i.ti(i64 %0, %closure* %env) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %funcptr4 = bitcast %closure* %env to i8**
    %loadtmp = load i8*, i8** %funcptr4, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %env, i32 0, i32 1
    %loadtmp2 = load i8*, i8** %envptr, align 8
    %1 = tail call i64 %casttmp(i64 %0, i8* %loadtmp2)
    %2 = alloca %t_int, align 8
    %x5 = bitcast %t_int* %2 to i64*
    store i64 %1, i64* %x5, align 4
    ret i64 %1
  }
  
  define i64 @schmu___ggg.gg.g_apply_titii.i.tii.i.ti(i64 %0, %closure* %f, %closure* %env) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, %closure*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    %1 = tail call i64 %casttmp(i64 %0, %closure* %env, i8* %loadtmp3)
    %box4 = bitcast %t_int* %ret to i64*
    store i64 %1, i64* %box4, align 4
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
    store i8* bitcast (i64 (i64, %closure*)* @schmu___tgg.g.tg_boxed2int_int_tii.i.ti to i8*), i8** %funptr14, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr215 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @schmu_add1 to i8*), i8** %funptr215, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %ret = alloca %t_int, align 8
    %0 = call i64 @schmu___ggg.gg.g_apply_titii.i.tii.i.ti(i64 15, %closure* %clstmp, %closure* %clstmp1)
    %box = bitcast %t_int* %ret to i64*
    store i64 %0, i64* %box, align 4
    store i64 %0, i64* @a, align 4
    call void @printi(i64 %0)
    %clstmp5 = alloca %closure, align 8
    %funptr616 = bitcast %closure* %clstmp5 to i8**
    store i8* bitcast (i64 (i64, %closure*)* @schmu___tgg.g.tg_boxed2int_int_tii.i.ti to i8*), i8** %funptr616, align 8
    %envptr7 = getelementptr inbounds %closure, %closure* %clstmp5, i32 0, i32 1
    store i8* null, i8** %envptr7, align 8
    %clstmp8 = alloca %closure, align 8
    %funptr917 = bitcast %closure* %clstmp8 to i8**
    store i8* bitcast (i64 (i64)* @schmu_add1 to i8*), i8** %funptr917, align 8
    %envptr10 = getelementptr inbounds %closure, %closure* %clstmp8, i32 0, i32 1
    store i8* null, i8** %envptr10, align 8
    %ret11 = alloca %t_int, align 8
    %1 = call i64 @schmu___ggg.g.gg.g.g_apply2_titii.i.tii.i.ti(i64 15, %closure* %clstmp5, %closure* %clstmp8)
    %box12 = bitcast %t_int* %ret11 to i64*
    store i64 %1, i64* %box12, align 4
    store i64 %1, i64* @b, align 4
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
  
  @outer = constant i64 10
  
  declare void @printi(i64 %0)
  
  define void @schmu_loop(i64 %i) {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, i64* %0, align 4
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %i1 = phi i64 [ %add, %then ], [ %i, %entry ]
    %lt = icmp slt i64 %i1, 10
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %rec
    tail call void @printi(i64 %i1)
    %add = add i64 %i1, 1
    store i64 %add, i64* %0, align 4
    br label %rec
  
  else:                                             ; preds = %rec
    tail call void @printi(i64 %i1)
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
  5 | (val f (if true (fun [x] x) (fun [x] x)))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  
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
  
  %rec = type { i64 }
  
  declare void @printi(i64 %0)
  
  define i64 @schmu___g.g_wrapped_rec.rec(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %ret = alloca %rec, align 8
    %1 = tail call i64 @schmu___g.g_id_rec.rec(i64 %0)
    %box3 = bitcast %rec* %ret to i64*
    store i64 %1, i64* %box3, align 4
    ret i64 %1
  }
  
  define i64 @schmu___g.g_id_rec.rec(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    ret i64 %0
  }
  
  define i1 @schmu___g.g_wrapped_b.b(i1 %x) {
  entry:
    %0 = tail call i1 @schmu___g.g_id_b.b(i1 %x)
    ret i1 %0
  }
  
  define i1 @schmu___g.g_id_b.b(i1 %x) {
  entry:
    ret i1 %x
  }
  
  define i64 @schmu___g.g_wrapped_i.i(i64 %x) {
  entry:
    %0 = tail call i64 @schmu___g.g_id_i.i(i64 %x)
    ret i64 %0
  }
  
  define i64 @schmu___g.g_id_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @schmu___g.g_wrapped_i.i(i64 12)
    tail call void @printi(i64 %0)
    %1 = tail call i1 @schmu___g.g_wrapped_b.b(i1 false)
    %ret = alloca %rec, align 8
    %2 = tail call i64 @schmu___g.g_wrapped_rec.rec(i64 24)
    %box = bitcast %rec* %ret to i64*
    store i64 %2, i64* %box, align 4
    tail call void @printi(i64 %2)
    ret i64 0
  }
  12
  24

Nested polymorphic closures. Does not quite work for another nesting level
  $ schmu --dump-llvm stub.o nested_polymorphic_closures.smu && ./nested_polymorphic_closures
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { %owned_ptr_int, i64 }
  %owned_ptr_int = type { i64*, i64 }
  %closure = type { i8*, i8* }
  
  @vec = global %vector_int zeroinitializer, align 16
  
  declare void @printi(i64 %0)
  
  define void @schmu___fun0(i64 %x) {
  entry:
    %mul = mul i64 %x, 2
    tail call void @printi(i64 %mul)
    ret void
  }
  
  define void @schmu___vectorgg.u.u_vector-iter_vectorii.u.u(%vector_int* %vec, %closure* %f) {
  entry:
    %monoclstmp = alloca %closure, align 8
    %funptr27 = bitcast %closure* %monoclstmp to i8**
    store i8* bitcast (void (i64, i8*)* @schmu___i.u_inner_cls_both_i.u to i8*), i8** %funptr27, align 8
    %clsr_monoclstmp = alloca { %closure*, %vector_int }, align 8
    %f128 = bitcast { %closure*, %vector_int }* %clsr_monoclstmp to %closure**
    store %closure* %f, %closure** %f128, align 8
    %vec2 = getelementptr inbounds { %closure*, %vector_int }, { %closure*, %vector_int }* %clsr_monoclstmp, i32 0, i32 1
    %0 = bitcast %vector_int* %vec2 to i8*
    %1 = bitcast %vector_int* %vec to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 24, i1 false)
    %env = bitcast { %closure*, %vector_int }* %clsr_monoclstmp to i8*
    %envptr = getelementptr inbounds %closure, %closure* %monoclstmp, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu___i.u_inner_cls_both_i.u(i64 0, i8* %env)
    %monoclstmp5 = alloca %closure, align 8
    %funptr629 = bitcast %closure* %monoclstmp5 to i8**
    store i8* bitcast (void (i64, %closure*, i8*)* @schmu___ig.u.u_inner_cls_vec_ii.u.u to i8*), i8** %funptr629, align 8
    %clsr_monoclstmp7 = alloca { %vector_int }, align 8
    %vec830 = bitcast { %vector_int }* %clsr_monoclstmp7 to %vector_int*
    %2 = bitcast %vector_int* %vec830 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %1, i64 24, i1 false)
    %env9 = bitcast { %vector_int }* %clsr_monoclstmp7 to i8*
    %envptr10 = getelementptr inbounds %closure, %closure* %monoclstmp5, i32 0, i32 1
    store i8* %env9, i8** %envptr10, align 8
    call void @schmu___ig.u.u_inner_cls_vec_ii.u.u(i64 0, %closure* %f, i8* %env9)
    %monoclstmp16 = alloca %closure, align 8
    %funptr1731 = bitcast %closure* %monoclstmp16 to i8**
    store i8* bitcast (void (i64, %vector_int*, i8*)* @schmu___ivectorg.u_inner_cls_f_ivectori.u to i8*), i8** %funptr1731, align 8
    %clsr_monoclstmp18 = alloca { %closure* }, align 8
    %f1932 = bitcast { %closure* }* %clsr_monoclstmp18 to %closure**
    store %closure* %f, %closure** %f1932, align 8
    %env20 = bitcast { %closure* }* %clsr_monoclstmp18 to i8*
    %envptr21 = getelementptr inbounds %closure, %closure* %monoclstmp16, i32 0, i32 1
    store i8* %env20, i8** %envptr21, align 8
    call void @schmu___ivectorg.u_inner_cls_f_ivectori.u(i64 0, %vector_int* %vec, i8* %env20)
    ret void
  }
  
  define void @schmu___ivectorg.u_inner_cls_f_ivectori.u(i64 %i, %vector_int* %vec, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %closure* }*
    %f7 = bitcast { %closure* }* %clsr to %closure**
    %f1 = load %closure*, %closure** %f7, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    %2 = alloca %vector_int*, align 8
    store %vector_int* %vec, %vector_int** %2, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %i2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %3 = bitcast %vector_int* %vec to %owned_ptr_int*
    %4 = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %3, i32 0, i32 1
    %5 = load i64, i64* %4, align 4
    %eq = icmp eq i64 %i2, %5
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %6 = bitcast %vector_int* %vec to %owned_ptr_int*
    %7 = bitcast %owned_ptr_int* %6 to i64**
    %8 = load i64*, i64** %7, align 8
    %scevgep = getelementptr i64, i64* %8, i64 %i2
    %9 = load i64, i64* %scevgep, align 4
    %funcptr8 = bitcast %closure* %f1 to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f1, i32 0, i32 1
    %loadtmp4 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %9, i8* %loadtmp4)
    %add = add i64 %i2, 1
    store i64 %add, i64* %1, align 4
    store %vector_int* %vec, %vector_int** %2, align 8
    br label %rec
  }
  
  define void @schmu___ig.u.u_inner_cls_vec_ii.u.u(i64 %i, %closure* %f, i8* %0) {
  entry:
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    %2 = alloca %closure*, align 8
    store %closure* %f, %closure** %2, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %i1 = phi i64 [ %add, %else ], [ %i, %entry ]
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 8
    %3 = bitcast i8* %sunkaddr to i64*
    %4 = load i64, i64* %3, align 4
    %eq = icmp eq i64 %i1, %4
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %5 = bitcast i8* %0 to i64**
    %6 = load i64*, i64** %5, align 8
    %scevgep = getelementptr i64, i64* %6, i64 %i1
    %7 = load i64, i64* %scevgep, align 4
    %funcptr7 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr7, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %7, i8* %loadtmp3)
    %add = add i64 %i1, 1
    store i64 %add, i64* %1, align 4
    store %closure* %f, %closure** %2, align 8
    br label %rec
  }
  
  define void @schmu___i.u_inner_cls_both_i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %closure*, %vector_int }*
    %f5 = bitcast { %closure*, %vector_int }* %clsr to %closure**
    %f1 = load %closure*, %closure** %f5, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %i2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %2 = bitcast i8* %sunkaddr to i64*
    %3 = load i64, i64* %2, align 4
    %eq = icmp eq i64 %i2, %3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr6 = getelementptr inbounds i8, i8* %0, i64 8
    %4 = bitcast i8* %sunkaddr6 to i64**
    %5 = load i64*, i64** %4, align 8
    %scevgep = getelementptr i64, i64* %5, i64 %i2
    %6 = load i64, i64* %scevgep, align 4
    %funcptr7 = bitcast %closure* %f1 to i8**
    %loadtmp = load i8*, i8** %funcptr7, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f1, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %6, i8* %loadtmp3)
    %add = add i64 %i2, 1
    store i64 %add, i64* %1, align 4
    br label %rec
  }
  
  define void @schmu___vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i64 %v) {
  entry:
    %0 = bitcast %vector_int* %vec to %owned_ptr_int*
    %1 = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %0, i32 0, i32 1
    %2 = load i64, i64* %1, align 4
    %3 = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    %4 = load i64, i64* %3, align 4
    %lt = icmp slt i64 %2, %4
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %entry
    %5 = bitcast %vector_int* %vec to %owned_ptr_int*
    %6 = bitcast %owned_ptr_int* %5 to i64**
    %7 = load i64*, i64** %6, align 8
    %8 = getelementptr inbounds i64, i64* %7, i64 %2
    store i64 %v, i64* %8, align 4
    %9 = bitcast %vector_int* %vec to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %9, i64 8
    %10 = bitcast i8* %sunkaddr to i64*
    %11 = load i64, i64* %10, align 4
    %add = add i64 %11, 1
    store i64 %add, i64* %10, align 4
    br label %ifcont
  
  else:                                             ; preds = %entry
    %12 = bitcast %vector_int* %vec to %owned_ptr_int*
    %mul = mul i64 %4, 2
    %13 = bitcast %owned_ptr_int* %12 to i64**
    %14 = mul i64 %mul, 8
    %15 = load i64*, i64** %13, align 8
    %16 = bitcast i64* %15 to i8*
    %17 = tail call i8* @realloc(i8* %16, i64 %14)
    %18 = bitcast i8* %17 to i64*
    store i64* %18, i64** %13, align 8
    %19 = bitcast %vector_int* %vec to i8*
    %sunkaddr2 = getelementptr inbounds i8, i8* %19, i64 16
    %20 = bitcast i8* %sunkaddr2 to i64*
    store i64 %mul, i64* %20, align 4
    %21 = bitcast %vector_int* %vec to i8*
    %sunkaddr3 = getelementptr inbounds i8, i8* %21, i64 8
    %22 = bitcast i8* %sunkaddr3 to i64*
    %23 = load i64, i64* %22, align 4
    %24 = getelementptr inbounds i64, i64* %18, i64 %23
    store i64 %v, i64* %24, align 4
    %25 = load i64, i64* %22, align 4
    %add1 = add i64 %25, 1
    store i64 %add1, i64* %22, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** getelementptr inbounds (%vector_int, %vector_int* @vec, i32 0, i32 0, i32 0), align 8
    store i64 0, i64* getelementptr inbounds (%vector_int, %vector_int* @vec, i32 0, i32 0, i32 1), align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @vec, i32 0, i32 1), align 4
    tail call void @schmu___vectorgg.u_vector_push_vectorii.u(%vector_int* @vec, i64 1)
    tail call void @schmu___vectorgg.u_vector_push_vectorii.u(%vector_int* @vec, i64 2)
    tail call void @schmu___vectorgg.u_vector_push_vectorii.u(%vector_int* @vec, i64 3)
    tail call void @schmu___vectorgg.u_vector_push_vectorii.u(%vector_int* @vec, i64 4)
    tail call void @schmu___vectorgg.u_vector_push_vectorii.u(%vector_int* @vec, i64 5)
    %clstmp = alloca %closure, align 8
    %funptr1 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @schmu___fun0 to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu___vectorgg.u.u_vector-iter_vectorii.u.u(%vector_int* @vec, %closure* %clstmp)
    %2 = load i64*, i64** getelementptr inbounds (%vector_int, %vector_int* @vec, i32 0, i32 0, i32 0), align 8
    %3 = bitcast i64* %2 to i8*
    call void @free(i8* %3)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
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
  
  %string = type { i8*, i64 }
  
  @a = constant i64 20
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1)
  
  define void @schmu_use_above() {
  entry:
    %str = alloca %string, align 8
    %cstr1 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr1, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %0 = tail call i64 @schmu_close_over_a()
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    ret void
  }
  
  define i64 @schmu_close_over_a() {
  entry:
    ret i64 20
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_use_above()
    ret i64 0
  }
  20

Don't copy mutable types in setup of tailrecursive functions
  $ schmu --dump-llvm tailrec_mutable.smu && valgrind -q --leak-check=yes ./tailrec_mutable
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %bref = type { i1 }
  %r = type { i64 }
  %string = type { i8*, i64 }
  
  @rf = global %bref zeroinitializer, align 1
  @0 = private unnamed_addr constant [6 x i8] c"false\00", align 1
  @1 = private unnamed_addr constant [5 x i8] c"true\00", align 1
  @2 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
  @3 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_test(i64** %a, i64 %i) {
  entry:
    %0 = alloca i64**, align 8
    store i64** %a, i64*** %0, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    %arr = alloca i64*, align 8
    %arr5 = alloca i64*, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %then, %then4, %entry
    %i2.ph = phi i64 [ %i, %entry ], [ 3, %then ], [ 11, %then4 ]
    %a1.ph = phi i64** [ %a, %entry ], [ %arr, %then ], [ %arr5, %then4 ]
    %2 = add i64 %i2.ph, 1
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %merge
    %lsr.iv = phi i64 [ %2, %rec.outer ], [ %lsr.iv.next, %merge ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %3 = call i8* @malloc(i64 32)
    %4 = bitcast i8* %3 to i64*
    store i64* %4, i64** %arr, align 8
    store i64 1, i64* %4, align 4
    %size = getelementptr i64, i64* %4, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %4, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %4, i64 3
    store i64 10, i64* %data, align 4
    store i64** %arr, i64*** %0, align 8
    store i64 3, i64* %1, align 4
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq3 = icmp eq i64 %lsr.iv, 11
    br i1 %eq3, label %then4, label %else12
  
  then4:                                            ; preds = %else
    %5 = call i8* @malloc(i64 32)
    %6 = bitcast i8* %5 to i64*
    store i64* %6, i64** %arr5, align 8
    store i64 1, i64* %6, align 4
    %size7 = getelementptr i64, i64* %6, i64 1
    store i64 1, i64* %size7, align 4
    %cap8 = getelementptr i64, i64* %6, i64 2
    store i64 1, i64* %cap8, align 4
    %data9 = getelementptr i64, i64* %6, i64 3
    store i64 10, i64* %data9, align 4
    store i64** %arr5, i64*** %0, align 8
    store i64 11, i64* %1, align 4
    br label %rec.outer
  
  else12:                                           ; preds = %else
    %eq13 = icmp eq i64 %lsr.iv, 13
    br i1 %eq13, label %then14, label %else15
  
  then14:                                           ; preds = %else12
    %7 = load i64*, i64** %arr5, align 8
    call void @__g.u_decr_rc_ai.u(i64* %7)
    %8 = load i64*, i64** %arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %8)
    ret void
  
  else15:                                           ; preds = %else12
    %9 = load i64*, i64** %a1.ph, align 8
    %size16 = getelementptr i64, i64* %9, i64 1
    %size17 = load i64, i64* %size16, align 4
    %cap18 = getelementptr i64, i64* %9, i64 2
    %cap19 = load i64, i64* %cap18, align 4
    %10 = icmp eq i64 %cap19, %size17
    br i1 %10, label %grow, label %keep
  
  keep:                                             ; preds = %else15
    %11 = call i64* @__ag.ag_reloc_ai.ai(i64** %a1.ph)
    br label %merge
  
  grow:                                             ; preds = %else15
    %12 = call i64* @__ag.ag_grow_ai.ai(i64** %a1.ph)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %13 = phi i64* [ %11, %keep ], [ %12, %grow ]
    %data20 = getelementptr i64, i64* %13, i64 3
    %14 = getelementptr i64, i64* %data20, i64 %size17
    store i64 20, i64* %14, align 4
    %size21 = getelementptr i64, i64* %13, i64 1
    %15 = add i64 %size17, 1
    store i64 %15, i64* %size21, align 4
    store i64** %a1.ph, i64*** %0, align 8
    store i64 %lsr.iv, i64* %1, align 4
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_change-int(i64* %i, i64 %j) {
  entry:
    %0 = alloca i64*, align 8
    store i64* %i, i64** %0, align 8
    %1 = alloca i64, align 8
    store i64 %j, i64* %1, align 4
    %2 = add i64 %j, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 101
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    store i64 100, i64* %i, align 4
    ret void
  
  else:                                             ; preds = %rec
    store i64* %i, i64** %0, align 8
    store i64 %lsr.iv, i64* %1, align 4
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_push-twice(i64** %a, i64 %i) {
  entry:
    %0 = alloca i64**, align 8
    store i64** %a, i64*** %0, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %merge, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %merge ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %3 = load i64*, i64** %a, align 8
    %size = getelementptr i64, i64* %3, i64 1
    %size3 = load i64, i64* %size, align 4
    %cap = getelementptr i64, i64* %3, i64 2
    %cap4 = load i64, i64* %cap, align 4
    %4 = icmp eq i64 %cap4, %size3
    br i1 %4, label %grow, label %keep
  
  keep:                                             ; preds = %else
    %5 = tail call i64* @__ag.ag_reloc_ai.ai(i64** %a)
    br label %merge
  
  grow:                                             ; preds = %else
    %6 = tail call i64* @__ag.ag_grow_ai.ai(i64** %a)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %7 = phi i64* [ %5, %keep ], [ %6, %grow ]
    %data = getelementptr i64, i64* %7, i64 3
    %8 = getelementptr i64, i64* %data, i64 %size3
    store i64 20, i64* %8, align 4
    %size5 = getelementptr i64, i64* %7, i64 1
    %9 = add i64 %size3, 1
    store i64 %9, i64* %size5, align 4
    store i64** %a, i64*** %0, align 8
    store i64 %lsr.iv, i64* %1, align 4
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_mod-rec(%r* %r, i64 %i) {
  entry:
    %0 = alloca %r*, align 8
    store %r* %r, %r** %0, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %3 = bitcast %r* %r to i64*
    store i64 2, i64* %3, align 4
    ret void
  
  else:                                             ; preds = %rec
    store %r* %r, %r** %0, align 8
    store i64 %lsr.iv, i64* %1, align 4
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_dontmut-bref(i64 %i, %bref* %rf) {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, i64* %0, align 4
    %1 = alloca %bref*, align 8
    store %bref* %rf, %bref** %1, align 8
    %2 = alloca %bref, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %rf2 = phi %bref* [ %2, %else ], [ %rf, %entry ]
    %i1 = phi i64 [ %add, %else ], [ %i, %entry ]
    %gt = icmp sgt i64 %i1, 0
    br i1 %gt, label %then, label %else
  
  then:                                             ; preds = %rec
    %3 = bitcast %bref* %rf2 to i1*
    store i1 false, i1* %3, align 1
    ret void
  
  else:                                             ; preds = %rec
    %a5 = bitcast %bref* %2 to i1*
    store i1 true, i1* %a5, align 1
    %add = add i64 %i1, 1
    store i64 %add, i64* %0, align 4
    store %bref* %2, %bref** %1, align 8
    br label %rec
  }
  
  define void @schmu_mut-bref(i64 %i, %bref* %rf) {
  entry:
    %0 = alloca i64, align 8
    store i64 %i, i64* %0, align 4
    %1 = alloca %bref*, align 8
    store %bref* %rf, %bref** %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %i1 = phi i64 [ %add, %else ], [ %i, %entry ]
    %gt = icmp sgt i64 %i1, 0
    br i1 %gt, label %then, label %else
  
  then:                                             ; preds = %rec
    %2 = bitcast %bref* %rf to i1*
    store i1 true, i1* %2, align 1
    ret void
  
  else:                                             ; preds = %rec
    %add = add i64 %i1, 1
    store i64 %add, i64* %0, align 4
    store %bref* %rf, %bref** %1, align 8
    br label %rec
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 4
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 4
    %3 = mul i64 %cap2, 8
    %4 = add i64 %3, 24
    %5 = call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    %7 = mul i64 %size, 8
    %8 = add i64 %7, 24
    %9 = bitcast i64* %6 to i8*
    %10 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* %10, i64 %8, i1 false)
    store i64* %6, i64** %0, align 8
    %ref35 = bitcast i64* %6 to i64*
    store i64 1, i64* %ref35, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal i64* @__ag.ag_grow_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap1 = load i64, i64* %cap, align 4
    %2 = mul i64 %cap1, 2
    %ref5 = bitcast i64* %1 to i64*
    %ref2 = load i64, i64* %ref5, align 4
    %3 = mul i64 %2, 8
    %4 = add i64 %3, 24
    %5 = icmp eq i64 %ref2, 1
    br i1 %5, label %realloc, label %malloc
  
  realloc:                                          ; preds = %entry
    %6 = load i64*, i64** %0, align 8
    %7 = bitcast i64* %6 to i8*
    %8 = call i8* @realloc(i8* %7, i64 %4)
    %9 = bitcast i8* %8 to i64*
    store i64* %9, i64** %0, align 8
    br label %merge
  
  malloc:                                           ; preds = %entry
    %10 = call i8* @malloc(i64 %4)
    %11 = bitcast i8* %10 to i64*
    %size = getelementptr i64, i64* %1, i64 1
    %size3 = load i64, i64* %size, align 4
    %12 = mul i64 %size3, 8
    %13 = add i64 %12, 24
    %14 = bitcast i64* %11 to i8*
    %15 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %14, i8* %15, i64 %13, i1 false)
    store i64* %11, i64** %0, align 8
    %ref46 = bitcast i64* %11 to i64*
    store i64 1, i64* %ref46, align 4
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %malloc, %realloc
    %16 = phi i64* [ %9, %realloc ], [ %11, %malloc ]
    %newcap = getelementptr i64, i64* %16, i64 2
    store i64 %2, i64* %newcap, align 4
    %17 = load i64*, i64** %0, align 8
    ret i64* %17
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i1 false, i1* getelementptr inbounds (%bref, %bref* @rf, i32 0, i32 0), align 1
    tail call void @schmu_mut-bref(i64 0, %bref* @rf)
    %0 = load i1, i1* getelementptr inbounds (%bref, %bref* @rf, i32 0, i32 0), align 1
    br i1 %0, label %cont, label %free
  
  free:                                             ; preds = %entry
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %1 = phi i8* [ getelementptr inbounds ([5 x i8], [5 x i8]* @1, i32 0, i32 0), %entry ], [ getelementptr inbounds ([6 x i8], [6 x i8]* @0, i32 0, i32 0), %free ]
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @2, i32 0, i32 0), i8* %1)
    %2 = add i32 %fmtsize, 1
    %3 = sext i32 %2 to i64
    %4 = tail call i8* @malloc(i64 %3)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %4, i64 %3, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @2, i32 0, i32 0), i8* %1)
    %str = alloca %string, align 8
    %cstr78 = bitcast %string* %str to i8**
    store i8* %4, i8** %cstr78, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %5 = mul i64 %3, -1
    store i64 %5, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %6 = ptrtoint i8* %4 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %6, i64 %5)
    tail call void @schmu_dontmut-bref(i64 0, %bref* @rf)
    %7 = load i1, i1* getelementptr inbounds (%bref, %bref* @rf, i32 0, i32 0), align 1
    br i1 %7, label %cont4, label %free3
  
  free3:                                            ; preds = %cont
    br label %cont4
  
  cont4:                                            ; preds = %free3, %cont
    %8 = phi i8* [ getelementptr inbounds ([5 x i8], [5 x i8]* @1, i32 0, i32 0), %cont ], [ getelementptr inbounds ([6 x i8], [6 x i8]* @0, i32 0, i32 0), %free3 ]
    %fmtsize5 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @2, i32 0, i32 0), i8* %8)
    %9 = add i32 %fmtsize5, 1
    %10 = sext i32 %9 to i64
    %11 = tail call i8* @malloc(i64 %10)
    %fmt6 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @2, i32 0, i32 0), i8* %8)
    %str7 = alloca %string, align 8
    %cstr880 = bitcast %string* %str7 to i8**
    store i8* %11, i8** %cstr880, align 8
    %length9 = getelementptr inbounds %string, %string* %str7, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length9, align 4
    %unbox10 = bitcast %string* %str7 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd13 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox10, i32 0, i32 1
    tail call void @schmu_print(i64 %13, i64 %12)
    %14 = alloca %r, align 8
    %a82 = bitcast %r* %14 to i64*
    store i64 20, i64* %a82, align 4
    call void @schmu_mod-rec(%r* %14, i64 0)
    %15 = load i64, i64* %a82, align 4
    %fmtsize15 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %15)
    %16 = add i32 %fmtsize15, 1
    %17 = sext i32 %16 to i64
    %18 = call i8* @malloc(i64 %17)
    %fmt16 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %18, i64 %17, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %15)
    %str17 = alloca %string, align 8
    %cstr1883 = bitcast %string* %str17 to i8**
    store i8* %18, i8** %cstr1883, align 8
    %length19 = getelementptr inbounds %string, %string* %str17, i32 0, i32 1
    %19 = mul i64 %17, -1
    store i64 %19, i64* %length19, align 4
    %unbox20 = bitcast %string* %str17 to { i64, i64 }*
    %20 = ptrtoint i8* %18 to i64
    %snd23 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox20, i32 0, i32 1
    call void @schmu_print(i64 %20, i64 %19)
    %21 = call i8* @malloc(i64 40)
    %22 = bitcast i8* %21 to i64*
    %arr = alloca i64*, align 8
    store i64* %22, i64** %arr, align 8
    store i64 1, i64* %22, align 4
    %size = getelementptr i64, i64* %22, i64 1
    store i64 2, i64* %size, align 4
    %cap = getelementptr i64, i64* %22, i64 2
    store i64 2, i64* %cap, align 4
    %data = getelementptr i64, i64* %22, i64 3
    store i64 10, i64* %data, align 4
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 4
    call void @schmu_push-twice(i64** %arr, i64 0)
    %23 = load i64*, i64** %arr, align 8
    %len = getelementptr i64, i64* %23, i64 1
    %24 = load i64, i64* %len, align 4
    %fmtsize25 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %24)
    %25 = add i32 %fmtsize25, 1
    %26 = sext i32 %25 to i64
    %27 = call i8* @malloc(i64 %26)
    %fmt26 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %27, i64 %26, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %24)
    %str27 = alloca %string, align 8
    %cstr2885 = bitcast %string* %str27 to i8**
    store i8* %27, i8** %cstr2885, align 8
    %length29 = getelementptr inbounds %string, %string* %str27, i32 0, i32 1
    %28 = mul i64 %26, -1
    store i64 %28, i64* %length29, align 4
    %unbox30 = bitcast %string* %str27 to { i64, i64 }*
    %29 = ptrtoint i8* %27 to i64
    %snd33 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox30, i32 0, i32 1
    call void @schmu_print(i64 %29, i64 %28)
    %i = alloca i64, align 8
    store i64 0, i64* %i, align 4
    call void @schmu_change-int(i64* %i, i64 0)
    %30 = load i64, i64* %i, align 4
    %fmtsize35 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %30)
    %31 = add i32 %fmtsize35, 1
    %32 = sext i32 %31 to i64
    %33 = call i8* @malloc(i64 %32)
    %fmt36 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %33, i64 %32, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %30)
    %str37 = alloca %string, align 8
    %cstr3887 = bitcast %string* %str37 to i8**
    store i8* %33, i8** %cstr3887, align 8
    %length39 = getelementptr inbounds %string, %string* %str37, i32 0, i32 1
    %34 = mul i64 %32, -1
    store i64 %34, i64* %length39, align 4
    %unbox40 = bitcast %string* %str37 to { i64, i64 }*
    %35 = ptrtoint i8* %33 to i64
    %snd43 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox40, i32 0, i32 1
    call void @schmu_print(i64 %35, i64 %34)
    %36 = call i8* @malloc(i64 32)
    %37 = bitcast i8* %36 to i64*
    %arr45 = alloca i64*, align 8
    store i64* %37, i64** %arr45, align 8
    store i64 1, i64* %37, align 4
    %size47 = getelementptr i64, i64* %37, i64 1
    store i64 0, i64* %size47, align 4
    %cap48 = getelementptr i64, i64* %37, i64 2
    store i64 1, i64* %cap48, align 4
    %data49 = getelementptr i64, i64* %37, i64 3
    call void @schmu_test(i64** %arr45, i64 0)
    %38 = load i64*, i64** %arr45, align 8
    %len50 = getelementptr i64, i64* %38, i64 1
    %39 = load i64, i64* %len50, align 4
    %fmtsize51 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %39)
    %40 = add i32 %fmtsize51, 1
    %41 = sext i32 %40 to i64
    %42 = call i8* @malloc(i64 %41)
    %fmt52 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %42, i64 %41, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %39)
    %str53 = alloca %string, align 8
    %cstr5489 = bitcast %string* %str53 to i8**
    store i8* %42, i8** %cstr5489, align 8
    %length55 = getelementptr inbounds %string, %string* %str53, i32 0, i32 1
    %43 = mul i64 %41, -1
    store i64 %43, i64* %length55, align 4
    %unbox56 = bitcast %string* %str53 to { i64, i64 }*
    %44 = ptrtoint i8* %42 to i64
    %snd59 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox56, i32 0, i32 1
    call void @schmu_print(i64 %44, i64 %43)
    %45 = load i64*, i64** %arr45, align 8
    call void @__g.u_decr_rc_ai.u(i64* %45)
    %46 = load i64*, i64** %arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %46)
    %owned = icmp slt i64 %43, 0
    br i1 %owned, label %free61, label %cont62
  
  free61:                                           ; preds = %cont4
    call void @free(i8* %42)
    br label %cont62
  
  cont62:                                           ; preds = %free61, %cont4
    %owned65 = icmp slt i64 %34, 0
    br i1 %owned65, label %free63, label %cont64
  
  free63:                                           ; preds = %cont62
    call void @free(i8* %33)
    br label %cont64
  
  cont64:                                           ; preds = %free63, %cont62
    %owned68 = icmp slt i64 %28, 0
    br i1 %owned68, label %free66, label %cont67
  
  free66:                                           ; preds = %cont64
    call void @free(i8* %27)
    br label %cont67
  
  cont67:                                           ; preds = %free66, %cont64
    %owned71 = icmp slt i64 %19, 0
    br i1 %owned71, label %free69, label %cont70
  
  free69:                                           ; preds = %cont67
    call void @free(i8* %18)
    br label %cont70
  
  cont70:                                           ; preds = %free69, %cont67
    %47 = bitcast %string* %str7 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %47, i64 8
    %48 = bitcast i8* %sunkaddr to i64*
    %49 = load i64, i64* %48, align 4
    %owned74 = icmp slt i64 %49, 0
    br i1 %owned74, label %free72, label %cont73
  
  free72:                                           ; preds = %cont70
    %50 = bitcast %string* %str7 to i8**
    %51 = load i8*, i8** %50, align 8
    call void @free(i8* %51)
    br label %cont73
  
  cont73:                                           ; preds = %free72, %cont70
    %52 = bitcast %string* %str to i8*
    %sunkaddr91 = getelementptr inbounds i8, i8* %52, i64 8
    %53 = bitcast i8* %sunkaddr91 to i64*
    %54 = load i64, i64* %53, align 4
    %owned77 = icmp slt i64 %54, 0
    br i1 %owned77, label %free75, label %cont76
  
  free75:                                           ; preds = %cont73
    %55 = bitcast %string* %str to i8**
    %56 = load i8*, i8** %55, align 8
    call void @free(i8* %56)
    br label %cont76
  
  cont76:                                           ; preds = %free75, %cont73
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare void @free(i8* %0)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  true
  true
  2
  4
  100
  2
