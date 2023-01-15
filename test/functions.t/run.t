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
  
  define i64 @schmu___fun0(i64 %n) {
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
    %1 = tail call i64 @schmu___fun0(i64 %n)
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
  
  @a = global %capturable zeroinitializer, align 8
  
  define i64 @schmu_capture_a() {
  entry:
    %0 = load i64, i64* getelementptr inbounds (%capturable, %capturable* @a, i32 0, i32 0), align 8
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
    %0 = load i64, i64* getelementptr inbounds (%capturable, %capturable* @a, i32 0, i32 0), align 8
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
    store i64 10, i64* getelementptr inbounds (%capturable, %capturable* @a, i32 0, i32 0), align 8
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
  
  @pass2 = global %closure zeroinitializer, align 16
  
  declare void @printi(i64 %0)
  
  define i64 @schmu___fun1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @schmu___fun2(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu___g.g___fun0_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu___g.g_pass_i.i(i64 %x) {
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
  %t_bool = type { i1 }
  %t_int = type { i64 }
  
  @a = constant i64 2
  @f = global %closure zeroinitializer, align 16
  
  declare void @printi(i64 %0)
  
  define i64 @schmu___fun1(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu___g.g___fun0_ti.ti(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
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
    store i64 %2, i64* %box, align 8
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
    store i64 %6, i64* %box18, align 8
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
  
  define i64 @schmu___g.g_pass_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define { i64, i8 } @schmu___g.g_pass_t.t(i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst3 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst3, align 8
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %box, i32 0, i32 1
    store i8 %1, i8* %snd, align 1
    %unbox2 = load { i64, i8 }, { i64, i8 }* %box, align 8
    ret { i64, i8 } %unbox2
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
  
  define { i64, i8 } @schmu___g.gg.g_apply_t.tt.t(%closure* %f, i64 %0, i8 %1) {
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
    store %t { i64 700, i1 false }, %t* %boxconst, align 8
    %unbox = bitcast %t* %boxconst to { i64, i8 }*
    %fst9 = bitcast { i64, i8 }* %unbox to i64*
    %fst4 = load i64, i64* %fst9, align 8
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %unbox, i32 0, i32 1
    %snd5 = load i8, i8* %snd, align 1
    %ret = alloca %t, align 8
    %1 = call { i64, i8 } @schmu___g.gg.g_apply_t.tt.t(%closure* %clstmp1, i64 %fst4, i8 %snd5)
    %box = bitcast %t* %ret to { i64, i8 }*
    store { i64, i8 } %1, { i64, i8 }* %box, align 8
    %2 = bitcast %t* %ret to i64*
    %3 = load i64, i64* %2, align 8
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
  
  define i64 @schmu___ggg.gg.g_apply_titii.i.tii.i.ti(i64 %0, %closure* %f, %closure* %env) {
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
  
  define i64 @schmu___tgg.g.tg_boxed2int_int_tii.i.ti(i64 %0, %closure* %env) {
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
    store i64 %0, i64* %box, align 8
    store i64 %0, i64* @a, align 8
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
    store i64 %1, i64* %box12, align 8
    store i64 %1, i64* @b, align 8
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
  
  %rc = type { i64 }
  
  declare void @printi(i64 %0)
  
  define i1 @schmu___g.g_id_b.b(i1 %x) {
  entry:
    ret i1 %x
  }
  
  define i64 @schmu___g.g_id_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @schmu___g.g_id_rc.rc(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    ret i64 %0
  }
  
  define i1 @schmu___g.g_wrapped_b.b(i1 %x) {
  entry:
    %0 = tail call i1 @schmu___g.g_id_b.b(i1 %x)
    ret i1 %0
  }
  
  define i64 @schmu___g.g_wrapped_i.i(i64 %x) {
  entry:
    %0 = tail call i64 @schmu___g.g_id_i.i(i64 %x)
    ret i64 %0
  }
  
  define i64 @schmu___g.g_wrapped_rc.rc(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %ret = alloca %rc, align 8
    %1 = tail call i64 @schmu___g.g_id_rc.rc(i64 %0)
    %box3 = bitcast %rc* %ret to i64*
    store i64 %1, i64* %box3, align 8
    ret i64 %1
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @schmu___g.g_wrapped_i.i(i64 12)
    tail call void @printi(i64 %0)
    %1 = tail call i1 @schmu___g.g_wrapped_b.b(i1 false)
    %ret = alloca %rc, align 8
    %2 = tail call i64 @schmu___g.g_wrapped_rc.rc(i64 24)
    %box = bitcast %rc* %ret to i64*
    store i64 %2, i64* %box, align 8
    tail call void @printi(i64 %2)
    ret i64 0
  }
  12
  24

Nested polymorphic closures. Does not quite work for another nesting level
  $ schmu --dump-llvm stub.o nested_polymorphic_closures.smu && valgrind -q --leak-check=yes --show-reachable=yes ./nested_polymorphic_closures
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @arr = global i64* null, align 8
  
  declare void @printi(i64 %0)
  
  define void @schmu___agg.u.u_array-iter_aii.u.u(i64* %arr, %closure* %f) {
  entry:
    %__i.u-ag-g.u_inner_cls_both_i.u-ai-i.u = alloca %closure, align 8
    %funptr27 = bitcast %closure* %__i.u-ag-g.u_inner_cls_both_i.u-ai-i.u to i8**
    store i8* bitcast (void (i64, i8*)* @schmu___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u to i8*), i8** %funptr27, align 8
    %clsr___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u = alloca { i64, i8*, i64*, %closure }, align 8
    %arr1 = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u, i32 0, i32 2
    store i64* %arr, i64** %arr1, align 8
    %f2 = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %rc28 = bitcast { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u to i64*
    store i64 2, i64* %rc28, align 8
    %dtor = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-g.u_inner_cls_both_i.u-ai-i.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %__ig.u.u-ag_inner_cls_arr_ii.u.u-ai = alloca %closure, align 8
    %funptr329 = bitcast %closure* %__ig.u.u-ag_inner_cls_arr_ii.u.u-ai to i8**
    store i8* bitcast (void (i64, %closure*, i8*)* @schmu___ig.u.u-ag_inner_cls_arr_ii.u.u-ai to i8*), i8** %funptr329, align 8
    %clsr___ig.u.u-ag_inner_cls_arr_ii.u.u-ai = alloca { i64, i8*, i64* }, align 8
    %arr4 = getelementptr inbounds { i64, i8*, i64* }, { i64, i8*, i64* }* %clsr___ig.u.u-ag_inner_cls_arr_ii.u.u-ai, i32 0, i32 2
    store i64* %arr, i64** %arr4, align 8
    %rc530 = bitcast { i64, i8*, i64* }* %clsr___ig.u.u-ag_inner_cls_arr_ii.u.u-ai to i64*
    store i64 2, i64* %rc530, align 8
    %dtor6 = getelementptr inbounds { i64, i8*, i64* }, { i64, i8*, i64* }* %clsr___ig.u.u-ag_inner_cls_arr_ii.u.u-ai, i32 0, i32 1
    store i8* null, i8** %dtor6, align 8
    %env7 = bitcast { i64, i8*, i64* }* %clsr___ig.u.u-ag_inner_cls_arr_ii.u.u-ai to i8*
    %envptr8 = getelementptr inbounds %closure, %closure* %__ig.u.u-ag_inner_cls_arr_ii.u.u-ai, i32 0, i32 1
    store i8* %env7, i8** %envptr8, align 8
    %__iag.u-g.u_inner_cls_f_iai.u-i.u = alloca %closure, align 8
    %funptr931 = bitcast %closure* %__iag.u-g.u_inner_cls_f_iai.u-i.u to i8**
    store i8* bitcast (void (i64, i64*, i8*)* @schmu___iag.u-g.u_inner_cls_f_iai.u-i.u to i8*), i8** %funptr931, align 8
    %clsr___iag.u-g.u_inner_cls_f_iai.u-i.u = alloca { i64, i8*, %closure }, align 8
    %f10 = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___iag.u-g.u_inner_cls_f_iai.u-i.u, i32 0, i32 2
    %2 = bitcast %closure* %f10 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %1, i64 16, i1 false)
    %rc1132 = bitcast { i64, i8*, %closure }* %clsr___iag.u-g.u_inner_cls_f_iai.u-i.u to i64*
    store i64 2, i64* %rc1132, align 8
    %dtor12 = getelementptr inbounds { i64, i8*, %closure }, { i64, i8*, %closure }* %clsr___iag.u-g.u_inner_cls_f_iai.u-i.u, i32 0, i32 1
    store i8* null, i8** %dtor12, align 8
    %env13 = bitcast { i64, i8*, %closure }* %clsr___iag.u-g.u_inner_cls_f_iai.u-i.u to i8*
    %envptr14 = getelementptr inbounds %closure, %closure* %__iag.u-g.u_inner_cls_f_iai.u-i.u, i32 0, i32 1
    store i8* %env13, i8** %envptr14, align 8
    call void @schmu___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u(i64 0, i8* %env)
    call void @schmu___ig.u.u-ag_inner_cls_arr_ii.u.u-ai(i64 0, %closure* %f, i8* %env7)
    call void @schmu___iag.u-g.u_inner_cls_f_iai.u-i.u(i64 0, i64* %arr, i8* %env13)
    ret void
  }
  
  define void @schmu___fun0(i64 %x) {
  entry:
    %mul = mul i64 %x, 2
    tail call void @printi(i64 %mul)
    ret void
  }
  
  define void @schmu___i.u-ag-g.u_inner_cls_both_i.u-ai-i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i64*, %closure }*
    %arr = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %len = getelementptr i64, i64* %arr1, i64 1
    %3 = load i64, i64* %len, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = mul i64 %2, 8
    %4 = bitcast i64* %arr1 to i8*
    %sunkaddr4 = getelementptr i8, i8* %4, i64 %sunkaddr
    %sunkaddr5 = getelementptr i8, i8* %sunkaddr4, i64 24
    %5 = bitcast i8* %sunkaddr5 to i64*
    %6 = load i64, i64* %5, align 8
    %sunkaddr7 = getelementptr inbounds i8, i8* %0, i64 24
    %7 = bitcast i8* %sunkaddr7 to i8**
    %loadtmp = load i8*, i8** %7, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %sunkaddr8 = getelementptr inbounds i8, i8* %0, i64 32
    %8 = bitcast i8* %sunkaddr8 to i8**
    %loadtmp2 = load i8*, i8** %8, align 8
    tail call void %casttmp(i64 %6, i8* %loadtmp2)
    %add = add i64 %2, 1
    store i64 %add, i64* %1, align 8
    br label %rec
  }
  
  define void @schmu___iag.u-g.u_inner_cls_f_iai.u-i.u(i64 %i, i64* %arr, i8* %0) {
  entry:
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = alloca i64*, align 8
    store i64* %arr, i64** %2, align 8
    %3 = alloca i1, align 1
    store i1 false, i1* %3, align 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %4 = phi i64 [ %add, %else ], [ %i, %entry ]
    %len = getelementptr i64, i64* %arr, i64 1
    %5 = load i64, i64* %len, align 8
    %eq = icmp eq i64 %4, %5
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    store i1 true, i1* %3, align 1
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = mul i64 %4, 8
    %6 = bitcast i64* %arr to i8*
    %sunkaddr3 = getelementptr i8, i8* %6, i64 %sunkaddr
    %sunkaddr4 = getelementptr i8, i8* %sunkaddr3, i64 24
    %7 = bitcast i8* %sunkaddr4 to i64*
    %8 = load i64, i64* %7, align 8
    %sunkaddr6 = getelementptr inbounds i8, i8* %0, i64 16
    %9 = bitcast i8* %sunkaddr6 to i8**
    %loadtmp = load i8*, i8** %9, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %sunkaddr7 = getelementptr inbounds i8, i8* %0, i64 24
    %10 = bitcast i8* %sunkaddr7 to i8**
    %loadtmp1 = load i8*, i8** %10, align 8
    tail call void %casttmp(i64 %8, i8* %loadtmp1)
    %add = add i64 %4, 1
    store i64 %add, i64* %1, align 8
    br label %rec
  }
  
  define void @schmu___ig.u.u-ag_inner_cls_arr_ii.u.u-ai(i64 %i, %closure* %f, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i64* }*
    %arr = getelementptr inbounds { i64, i8*, i64* }, { i64, i8*, i64* }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = alloca %closure, align 8
    %3 = bitcast %closure* %2 to i8*
    %4 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 16, i1 false)
    %5 = alloca i1, align 1
    store i1 false, i1* %5, align 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %6 = phi i64 [ %add, %else ], [ %i, %entry ]
    %len = getelementptr i64, i64* %arr1, i64 1
    %7 = load i64, i64* %len, align 8
    %eq = icmp eq i64 %6, %7
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    store i1 true, i1* %5, align 1
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = mul i64 %6, 8
    %8 = bitcast i64* %arr1 to i8*
    %sunkaddr4 = getelementptr i8, i8* %8, i64 %sunkaddr
    %sunkaddr5 = getelementptr i8, i8* %sunkaddr4, i64 24
    %9 = bitcast i8* %sunkaddr5 to i64*
    %10 = load i64, i64* %9, align 8
    %funcptr6 = bitcast %closure* %2 to i8**
    %loadtmp = load i8*, i8** %funcptr6, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %2, i32 0, i32 1
    %loadtmp2 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %10, i8* %loadtmp2)
    %add = add i64 %6, 1
    store i64 %add, i64* %1, align 8
    br label %rec
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal void @__g.u_decr_rc_i.u.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %nonnull
  
  nonnull:                                          ; preds = %entry
    %ref = bitcast i8* %2 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %4 = icmp eq i64 %ref2, 1
    br i1 %4, label %free, label %decr
  
  ret:                                              ; preds = %decr, %rly_free, %entry
    ret void
  
  decr:                                             ; preds = %nonnull
    %5 = bitcast i8* %2 to i64*
    %6 = bitcast i64* %5 to i64*
    %7 = sub i64 %ref2, 1
    store i64 %7, i64* %6, align 8
    br label %ret
  
  free:                                             ; preds = %nonnull
    %8 = bitcast i8* %2 to i64*
    %dtor3 = getelementptr i64, i64* %8, i64 1
    %9 = bitcast i64* %dtor3 to i8**
    %dtor4 = load i8*, i8** %9, align 8
    %10 = icmp eq i8* %dtor4, null
    br i1 %10, label %rly_free, label %dtor
  
  dtor:                                             ; preds = %free
    %11 = bitcast i8* %2 to i64*
    %dtor5 = bitcast i8* %dtor4 to void (i8*)*
    %12 = bitcast i64* %11 to i8*
    call void %dtor5(i8* %12)
    br label %rly_free
  
  rly_free:                                         ; preds = %dtor, %free
    %13 = bitcast i8* %2 to i64*
    %14 = bitcast i64* %13 to i8*
    call void @free(i8* %14)
    br label %ret
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @arr, align 8
    store i64 1, i64* %1, align 8
    %size = getelementptr i64, i64* %1, i64 1
    store i64 0, i64* %size, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 24
    %3 = load i64*, i64** @arr, align 8
    %size1 = getelementptr i64, i64* %3, i64 1
    %size2 = load i64, i64* %size1, align 8
    %cap3 = getelementptr i64, i64* %3, i64 2
    %cap4 = load i64, i64* %cap3, align 8
    %4 = icmp eq i64 %cap4, %size2
    br i1 %4, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %5 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @arr)
    br label %merge
  
  grow:                                             ; preds = %entry
    %6 = tail call i64* @__ag.ag_grow_ai.ai(i64** @arr)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %7 = phi i64* [ %5, %keep ], [ %6, %grow ]
    %8 = bitcast i64* %7 to i8*
    %9 = mul i64 8, %size2
    %10 = add i64 24, %9
    %11 = getelementptr i8, i8* %8, i64 %10
    %data5 = bitcast i8* %11 to i64*
    store i64 1, i64* %data5, align 8
    %size6 = getelementptr i64, i64* %7, i64 1
    %12 = add i64 %size2, 1
    store i64 %12, i64* %size6, align 8
    %13 = load i64*, i64** @arr, align 8
    %size7 = getelementptr i64, i64* %13, i64 1
    %size8 = load i64, i64* %size7, align 8
    %cap9 = getelementptr i64, i64* %13, i64 2
    %cap10 = load i64, i64* %cap9, align 8
    %14 = icmp eq i64 %cap10, %size8
    br i1 %14, label %grow12, label %keep11
  
  keep11:                                           ; preds = %merge
    %15 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @arr)
    br label %merge13
  
  grow12:                                           ; preds = %merge
    %16 = tail call i64* @__ag.ag_grow_ai.ai(i64** @arr)
    br label %merge13
  
  merge13:                                          ; preds = %grow12, %keep11
    %17 = phi i64* [ %15, %keep11 ], [ %16, %grow12 ]
    %18 = bitcast i64* %17 to i8*
    %19 = mul i64 8, %size8
    %20 = add i64 24, %19
    %21 = getelementptr i8, i8* %18, i64 %20
    %data14 = bitcast i8* %21 to i64*
    store i64 2, i64* %data14, align 8
    %size15 = getelementptr i64, i64* %17, i64 1
    %22 = add i64 %size8, 1
    store i64 %22, i64* %size15, align 8
    %23 = load i64*, i64** @arr, align 8
    %size16 = getelementptr i64, i64* %23, i64 1
    %size17 = load i64, i64* %size16, align 8
    %cap18 = getelementptr i64, i64* %23, i64 2
    %cap19 = load i64, i64* %cap18, align 8
    %24 = icmp eq i64 %cap19, %size17
    br i1 %24, label %grow21, label %keep20
  
  keep20:                                           ; preds = %merge13
    %25 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @arr)
    br label %merge22
  
  grow21:                                           ; preds = %merge13
    %26 = tail call i64* @__ag.ag_grow_ai.ai(i64** @arr)
    br label %merge22
  
  merge22:                                          ; preds = %grow21, %keep20
    %27 = phi i64* [ %25, %keep20 ], [ %26, %grow21 ]
    %28 = bitcast i64* %27 to i8*
    %29 = mul i64 8, %size17
    %30 = add i64 24, %29
    %31 = getelementptr i8, i8* %28, i64 %30
    %data23 = bitcast i8* %31 to i64*
    store i64 3, i64* %data23, align 8
    %size24 = getelementptr i64, i64* %27, i64 1
    %32 = add i64 %size17, 1
    store i64 %32, i64* %size24, align 8
    %33 = load i64*, i64** @arr, align 8
    %size25 = getelementptr i64, i64* %33, i64 1
    %size26 = load i64, i64* %size25, align 8
    %cap27 = getelementptr i64, i64* %33, i64 2
    %cap28 = load i64, i64* %cap27, align 8
    %34 = icmp eq i64 %cap28, %size26
    br i1 %34, label %grow30, label %keep29
  
  keep29:                                           ; preds = %merge22
    %35 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @arr)
    br label %merge31
  
  grow30:                                           ; preds = %merge22
    %36 = tail call i64* @__ag.ag_grow_ai.ai(i64** @arr)
    br label %merge31
  
  merge31:                                          ; preds = %grow30, %keep29
    %37 = phi i64* [ %35, %keep29 ], [ %36, %grow30 ]
    %38 = bitcast i64* %37 to i8*
    %39 = mul i64 8, %size26
    %40 = add i64 24, %39
    %41 = getelementptr i8, i8* %38, i64 %40
    %data32 = bitcast i8* %41 to i64*
    store i64 4, i64* %data32, align 8
    %size33 = getelementptr i64, i64* %37, i64 1
    %42 = add i64 %size26, 1
    store i64 %42, i64* %size33, align 8
    %43 = load i64*, i64** @arr, align 8
    %size34 = getelementptr i64, i64* %43, i64 1
    %size35 = load i64, i64* %size34, align 8
    %cap36 = getelementptr i64, i64* %43, i64 2
    %cap37 = load i64, i64* %cap36, align 8
    %44 = icmp eq i64 %cap37, %size35
    br i1 %44, label %grow39, label %keep38
  
  keep38:                                           ; preds = %merge31
    %45 = tail call i64* @__ag.ag_reloc_ai.ai(i64** @arr)
    br label %merge40
  
  grow39:                                           ; preds = %merge31
    %46 = tail call i64* @__ag.ag_grow_ai.ai(i64** @arr)
    br label %merge40
  
  merge40:                                          ; preds = %grow39, %keep38
    %47 = phi i64* [ %45, %keep38 ], [ %46, %grow39 ]
    %48 = bitcast i64* %47 to i8*
    %49 = mul i64 8, %size35
    %50 = add i64 24, %49
    %51 = getelementptr i8, i8* %48, i64 %50
    %data41 = bitcast i8* %51 to i64*
    store i64 5, i64* %data41, align 8
    %size42 = getelementptr i64, i64* %47, i64 1
    %52 = add i64 %size35, 1
    store i64 %52, i64* %size42, align 8
    %53 = load i64*, i64** @arr, align 8
    %clstmp = alloca %closure, align 8
    %funptr43 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @schmu___fun0 to i8*), i8** %funptr43, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu___agg.u.u_array-iter_aii.u.u(i64* %53, %closure* %clstmp)
    %54 = load i64*, i64** @arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %54)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 8
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 8
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
    store i64 1, i64* %ref35, align 8
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal i64* @__ag.ag_grow_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 2
    %ref5 = bitcast i64* %1 to i64*
    %ref2 = load i64, i64* %ref5, align 8
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
    %size3 = load i64, i64* %size, align 8
    %12 = mul i64 %size3, 8
    %13 = add i64 %12, 24
    %14 = bitcast i64* %11 to i8*
    %15 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %14, i8* %15, i64 %13, i1 false)
    store i64* %11, i64** %0, align 8
    %ref46 = bitcast i64* %11 to i64*
    store i64 1, i64* %ref46, align 8
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %malloc, %realloc
    %16 = phi i64* [ %9, %realloc ], [ %11, %malloc ]
    %newcap = getelementptr i64, i64* %16, i64 2
    store i64 %2, i64* %newcap, align 8
    %17 = load i64*, i64** %0, align 8
    ret i64* %17
  }
  
  declare void @free(i8* %0)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
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
  
  @a = constant i64 20
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_close_over_a() {
  entry:
    ret i64 20
  }
  
  define void @schmu_use_above() {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %0 = tail call i64 @schmu_close_over_a()
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
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
  
  @rf = global %bref zeroinitializer, align 1
  @0 = private unnamed_addr global { i64, i64, i64, [6 x i8] } { i64 2, i64 5, i64 5, [6 x i8] c"false\00" }
  @1 = private unnamed_addr global { i64, i64, i64, [5 x i8] } { i64 2, i64 4, i64 4, [5 x i8] c"true\00" }
  @2 = private unnamed_addr global { i64, i64, i64, [3 x i8] } { i64 2, i64 2, i64 2, [3 x i8] c"%s\00" }
  @3 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  
  declare void @prelude_print(i8* %0)
  
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
    %size = getelementptr i64, i64* %4, i64 1
    %size2 = load i64, i64* %size, align 8
    %cap = getelementptr i64, i64* %4, i64 2
    %cap3 = load i64, i64* %cap, align 8
    %5 = icmp eq i64 %cap3, %size2
    br i1 %5, label %grow, label %keep
  
  keep:                                             ; preds = %else
    %6 = tail call i64* @__ag.ag_reloc_ai.ai(i64** %a)
    br label %merge
  
  grow:                                             ; preds = %else
    %7 = tail call i64* @__ag.ag_grow_ai.ai(i64** %a)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %8 = phi i64* [ %6, %keep ], [ %7, %grow ]
    %9 = bitcast i64* %8 to i8*
    %10 = mul i64 8, %size2
    %11 = add i64 24, %10
    %12 = getelementptr i8, i8* %9, i64 %11
    %data = bitcast i8* %12 to i64*
    store i64 20, i64* %data, align 8
    %size4 = getelementptr i64, i64* %8, i64 1
    %13 = add i64 %size2, 1
    store i64 %13, i64* %size4, align 8
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
    %arr = alloca i64*, align 8
    %arr4 = alloca i64*, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %cont, %cont12, %entry
    %.ph = phi i1 [ false, %entry ], [ true, %cont ], [ %12, %cont12 ]
    %.ph31 = phi i1 [ false, %entry ], [ true, %cont ], [ true, %cont12 ]
    %.ph32 = phi i1 [ false, %entry ], [ true, %cont ], [ true, %cont12 ]
    %.ph33 = phi i64 [ %i, %entry ], [ 3, %cont ], [ 11, %cont12 ]
    %.ph34 = phi i64** [ %a, %entry ], [ %arr, %cont ], [ %arr4, %cont12 ]
    %3 = add i64 %.ph33, 1
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %merge
    %lsr.iv = phi i64 [ %3, %rec.outer ], [ %lsr.iv.next, %merge ]
    %eq = icmp eq i64 %lsr.iv, 3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %4 = call i8* @malloc(i64 32)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %arr, align 8
    store i64 1, i64* %5, align 8
    %size = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %size, align 8
    %cap = getelementptr i64, i64* %5, i64 2
    store i64 1, i64* %cap, align 8
    %6 = getelementptr i8, i8* %4, i64 24
    %data = bitcast i8* %6 to i64*
    store i64 10, i64* %data, align 8
    br i1 %.ph, label %call_decr, label %cookie
  
  call_decr:                                        ; preds = %then
    %7 = load i64*, i64** %.ph34, align 8
    call void @__g.u_decr_rc_ai.u(i64* %7)
    br label %cont
  
  cookie:                                           ; preds = %then
    store i1 true, i1* %1, align 1
    br label %cont
  
  cont:                                             ; preds = %cookie, %call_decr
    store i64** %arr, i64*** %0, align 8
    store i64 3, i64* %2, align 8
    br label %rec.outer
  
  else:                                             ; preds = %rec
    %eq2 = icmp eq i64 %lsr.iv, 11
    br i1 %eq2, label %then3, label %else14
  
  then3:                                            ; preds = %else
    %8 = call i8* @malloc(i64 32)
    %9 = bitcast i8* %8 to i64*
    store i64* %9, i64** %arr4, align 8
    store i64 1, i64* %9, align 8
    %size6 = getelementptr i64, i64* %9, i64 1
    store i64 1, i64* %size6, align 8
    %cap7 = getelementptr i64, i64* %9, i64 2
    store i64 1, i64* %cap7, align 8
    %10 = getelementptr i8, i8* %8, i64 24
    %data8 = bitcast i8* %10 to i64*
    store i64 10, i64* %data8, align 8
    br i1 %.ph31, label %call_decr10, label %cookie11
  
  call_decr10:                                      ; preds = %then3
    %11 = load i64*, i64** %.ph34, align 8
    call void @__g.u_decr_rc_ai.u(i64* %11)
    br label %cont12
  
  cookie11:                                         ; preds = %then3
    store i1 true, i1* %1, align 1
    br label %cont12
  
  cont12:                                           ; preds = %cookie11, %call_decr10
    %12 = phi i1 [ true, %cookie11 ], [ %.ph, %call_decr10 ]
    store i64** %arr4, i64*** %0, align 8
    store i64 11, i64* %2, align 8
    br label %rec.outer
  
  else14:                                           ; preds = %else
    %eq15 = icmp eq i64 %lsr.iv, 13
    br i1 %eq15, label %then16, label %else17
  
  then16:                                           ; preds = %else14
    br i1 %.ph32, label %call_decr27, label %cookie28
  
  else17:                                           ; preds = %else14
    %13 = load i64*, i64** %.ph34, align 8
    %size18 = getelementptr i64, i64* %13, i64 1
    %size19 = load i64, i64* %size18, align 8
    %cap20 = getelementptr i64, i64* %13, i64 2
    %cap21 = load i64, i64* %cap20, align 8
    %14 = icmp eq i64 %cap21, %size19
    br i1 %14, label %grow, label %keep
  
  keep:                                             ; preds = %else17
    %15 = call i64* @__ag.ag_reloc_ai.ai(i64** %.ph34)
    br label %merge
  
  grow:                                             ; preds = %else17
    %16 = call i64* @__ag.ag_grow_ai.ai(i64** %.ph34)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %17 = phi i64* [ %15, %keep ], [ %16, %grow ]
    %18 = bitcast i64* %17 to i8*
    %19 = mul i64 8, %size19
    %20 = add i64 24, %19
    %21 = getelementptr i8, i8* %18, i64 %20
    %data22 = bitcast i8* %21 to i64*
    store i64 20, i64* %data22, align 8
    %size23 = getelementptr i64, i64* %17, i64 1
    %22 = add i64 %size19, 1
    store i64 %22, i64* %size23, align 8
    store i64** %.ph34, i64*** %0, align 8
    store i64 %lsr.iv, i64* %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  call_decr27:                                      ; preds = %then16
    %23 = load i64*, i64** %.ph34, align 8
    call void @__g.u_decr_rc_ai.u(i64* %23)
    br label %cont29
  
  cookie28:                                         ; preds = %then16
    store i1 true, i1* %1, align 1
    br label %cont29
  
  cont29:                                           ; preds = %cookie28, %call_decr27
    ret void
  }
  
  define internal i64* @__ag.ag_reloc_ai.ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %ref4 = bitcast i64* %1 to i64*
    %ref1 = load i64, i64* %ref4, align 8
    %2 = icmp sgt i64 %ref1, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %sz = getelementptr i64, i64* %1, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 8
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
    store i64 1, i64* %ref35, align 8
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %11 = load i64*, i64** %0, align 8
    ret i64* %11
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
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
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 2
    %ref5 = bitcast i64* %1 to i64*
    %ref2 = load i64, i64* %ref5, align 8
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
    %size3 = load i64, i64* %size, align 8
    %12 = mul i64 %size3, 8
    %13 = add i64 %12, 24
    %14 = bitcast i64* %11 to i8*
    %15 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %14, i8* %15, i64 %13, i1 false)
    store i64* %11, i64** %0, align 8
    %ref46 = bitcast i64* %11 to i64*
    store i64 1, i64* %ref46, align 8
    call void @__g.u_decr_rc_ai.u(i64* %1)
    br label %merge
  
  merge:                                            ; preds = %malloc, %realloc
    %16 = phi i64* [ %9, %realloc ], [ %11, %malloc ]
    %newcap = getelementptr i64, i64* %16, i64 2
    store i64 %2, i64* %newcap, align 8
    %17 = load i64*, i64** %0, align 8
    ret i64* %17
  }
  
  declare i8* @malloc(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i1 false, i1* getelementptr inbounds (%bref, %bref* @rf, i32 0, i32 0), align 1
    tail call void @schmu_mut-bref(i64 0, %bref* @rf)
    %0 = load i1, i1* getelementptr inbounds (%bref, %bref* @rf, i32 0, i32 0), align 1
    br i1 %0, label %cont, label %free
  
  free:                                             ; preds = %entry
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %1 = phi i8* [ bitcast ({ i64, i64, i64, [5 x i8] }* @1 to i8*), %entry ], [ bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), %free ]
    %2 = getelementptr i8, i8* %1, i64 24
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [3 x i8] }* @2 to i8*), i64 24), i8* %2)
    %3 = add i32 %fmtsize, 25
    %4 = sext i32 %3 to i64
    %5 = tail call i8* @malloc(i64 %4)
    %6 = bitcast i8* %5 to i64*
    store i64 1, i64* %6, align 8
    %size = getelementptr i64, i64* %6, i64 1
    %7 = sext i32 %fmtsize to i64
    store i64 %7, i64* %size, align 8
    %cap = getelementptr i64, i64* %6, i64 2
    store i64 %7, i64* %cap, align 8
    %data = getelementptr i64, i64* %6, i64 3
    %8 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %8, i64 %4, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [3 x i8] }* @2 to i8*), i64 24), i8* %2)
    %str = alloca i8*, align 8
    store i8* %5, i8** %str, align 8
    tail call void @prelude_print(i8* %5)
    tail call void @schmu_dontmut-bref(i64 0, %bref* @rf)
    %9 = load i1, i1* getelementptr inbounds (%bref, %bref* @rf, i32 0, i32 0), align 1
    br i1 %9, label %cont2, label %free1
  
  free1:                                            ; preds = %cont
    br label %cont2
  
  cont2:                                            ; preds = %free1, %cont
    %10 = phi i8* [ bitcast ({ i64, i64, i64, [5 x i8] }* @1 to i8*), %cont ], [ bitcast ({ i64, i64, i64, [6 x i8] }* @0 to i8*), %free1 ]
    %11 = getelementptr i8, i8* %10, i64 24
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [3 x i8] }* @2 to i8*), i64 24), i8* %11)
    %12 = add i32 %fmtsize3, 25
    %13 = sext i32 %12 to i64
    %14 = tail call i8* @malloc(i64 %13)
    %15 = bitcast i8* %14 to i64*
    store i64 1, i64* %15, align 8
    %size5 = getelementptr i64, i64* %15, i64 1
    %16 = sext i32 %fmtsize3 to i64
    store i64 %16, i64* %size5, align 8
    %cap6 = getelementptr i64, i64* %15, i64 2
    store i64 %16, i64* %cap6, align 8
    %data7 = getelementptr i64, i64* %15, i64 3
    %17 = bitcast i64* %data7 to i8*
    %fmt8 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %17, i64 %13, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [3 x i8] }* @2 to i8*), i64 24), i8* %11)
    %str9 = alloca i8*, align 8
    store i8* %14, i8** %str9, align 8
    tail call void @prelude_print(i8* %14)
    %18 = alloca %r, align 8
    %a48 = bitcast %r* %18 to i64*
    store i64 20, i64* %a48, align 8
    call void @schmu_mod-rec(%r* %18, i64 0)
    %19 = load i64, i64* %a48, align 8
    %fmtsize10 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i64 24), i64 %19)
    %20 = add i32 %fmtsize10, 25
    %21 = sext i32 %20 to i64
    %22 = call i8* @malloc(i64 %21)
    %23 = bitcast i8* %22 to i64*
    store i64 1, i64* %23, align 8
    %size12 = getelementptr i64, i64* %23, i64 1
    %24 = sext i32 %fmtsize10 to i64
    store i64 %24, i64* %size12, align 8
    %cap13 = getelementptr i64, i64* %23, i64 2
    store i64 %24, i64* %cap13, align 8
    %data14 = getelementptr i64, i64* %23, i64 3
    %25 = bitcast i64* %data14 to i8*
    %fmt15 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %25, i64 %21, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i64 24), i64 %19)
    %str16 = alloca i8*, align 8
    store i8* %22, i8** %str16, align 8
    call void @prelude_print(i8* %22)
    %26 = call i8* @malloc(i64 40)
    %27 = bitcast i8* %26 to i64*
    %arr = alloca i64*, align 8
    store i64* %27, i64** %arr, align 8
    store i64 1, i64* %27, align 8
    %size18 = getelementptr i64, i64* %27, i64 1
    store i64 2, i64* %size18, align 8
    %cap19 = getelementptr i64, i64* %27, i64 2
    store i64 2, i64* %cap19, align 8
    %28 = getelementptr i8, i8* %26, i64 24
    %data20 = bitcast i8* %28 to i64*
    store i64 10, i64* %data20, align 8
    %"1" = getelementptr i64, i64* %data20, i64 1
    store i64 20, i64* %"1", align 8
    call void @schmu_push-twice(i64** %arr, i64 0)
    %29 = load i64*, i64** %arr, align 8
    %len = getelementptr i64, i64* %29, i64 1
    %30 = load i64, i64* %len, align 8
    %fmtsize21 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i64 24), i64 %30)
    %31 = add i32 %fmtsize21, 25
    %32 = sext i32 %31 to i64
    %33 = call i8* @malloc(i64 %32)
    %34 = bitcast i8* %33 to i64*
    store i64 1, i64* %34, align 8
    %size23 = getelementptr i64, i64* %34, i64 1
    %35 = sext i32 %fmtsize21 to i64
    store i64 %35, i64* %size23, align 8
    %cap24 = getelementptr i64, i64* %34, i64 2
    store i64 %35, i64* %cap24, align 8
    %data25 = getelementptr i64, i64* %34, i64 3
    %36 = bitcast i64* %data25 to i8*
    %fmt26 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %36, i64 %32, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i64 24), i64 %30)
    %str27 = alloca i8*, align 8
    store i8* %33, i8** %str27, align 8
    call void @prelude_print(i8* %33)
    %i = alloca i64, align 8
    store i64 0, i64* %i, align 8
    call void @schmu_change-int(i64* %i, i64 0)
    %37 = load i64, i64* %i, align 8
    %fmtsize28 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i64 24), i64 %37)
    %38 = add i32 %fmtsize28, 25
    %39 = sext i32 %38 to i64
    %40 = call i8* @malloc(i64 %39)
    %41 = bitcast i8* %40 to i64*
    store i64 1, i64* %41, align 8
    %size30 = getelementptr i64, i64* %41, i64 1
    %42 = sext i32 %fmtsize28 to i64
    store i64 %42, i64* %size30, align 8
    %cap31 = getelementptr i64, i64* %41, i64 2
    store i64 %42, i64* %cap31, align 8
    %data32 = getelementptr i64, i64* %41, i64 3
    %43 = bitcast i64* %data32 to i8*
    %fmt33 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %43, i64 %39, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i64 24), i64 %37)
    %str34 = alloca i8*, align 8
    store i8* %40, i8** %str34, align 8
    call void @prelude_print(i8* %40)
    %44 = call i8* @malloc(i64 32)
    %45 = bitcast i8* %44 to i64*
    %arr35 = alloca i64*, align 8
    store i64* %45, i64** %arr35, align 8
    store i64 1, i64* %45, align 8
    %size37 = getelementptr i64, i64* %45, i64 1
    store i64 0, i64* %size37, align 8
    %cap38 = getelementptr i64, i64* %45, i64 2
    store i64 1, i64* %cap38, align 8
    %46 = getelementptr i8, i8* %44, i64 24
    call void @schmu_test(i64** %arr35, i64 0)
    %47 = load i64*, i64** %arr35, align 8
    %len40 = getelementptr i64, i64* %47, i64 1
    %48 = load i64, i64* %len40, align 8
    %fmtsize41 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i64 24), i64 %48)
    %49 = add i32 %fmtsize41, 25
    %50 = sext i32 %49 to i64
    %51 = call i8* @malloc(i64 %50)
    %52 = bitcast i8* %51 to i64*
    store i64 1, i64* %52, align 8
    %size43 = getelementptr i64, i64* %52, i64 1
    %53 = sext i32 %fmtsize41 to i64
    store i64 %53, i64* %size43, align 8
    %cap44 = getelementptr i64, i64* %52, i64 2
    store i64 %53, i64* %cap44, align 8
    %data45 = getelementptr i64, i64* %52, i64 3
    %54 = bitcast i64* %data45 to i8*
    %fmt46 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %54, i64 %50, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @3 to i8*), i64 24), i64 %48)
    %str47 = alloca i8*, align 8
    store i8* %51, i8** %str47, align 8
    call void @prelude_print(i8* %51)
    call void @__g.u_decr_rc_ac.u(i8* %51)
    %55 = load i64*, i64** %arr35, align 8
    call void @__g.u_decr_rc_ai.u(i64* %55)
    call void @__g.u_decr_rc_ac.u(i8* %40)
    call void @__g.u_decr_rc_ac.u(i8* %33)
    %56 = load i64*, i64** %arr, align 8
    call void @__g.u_decr_rc_ai.u(i64* %56)
    call void @__g.u_decr_rc_ac.u(i8* %22)
    %57 = load i8*, i8** %str9, align 8
    call void @__g.u_decr_rc_ac.u(i8* %57)
    %58 = load i8*, i8** %str, align 8
    call void @__g.u_decr_rc_ac.u(i8* %58)
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
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

The lamba passed as array-iter argument is polymorphic
  $ schmu polymorphic_lambda_argument.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./polymorphic_lambda_argument
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @arr = global i64* null, align 8
  @0 = private unnamed_addr global { i64, i64, i64, [1 x [1 x i8]] } { i64 2, i64 0, i64 1, [1 x [1 x i8]] zeroinitializer }
  @1 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%li\00" }
  @2 = private unnamed_addr global { i64, i64, i64, [3 x i8] } { i64 2, i64 2, i64 2, [3 x i8] c", \00" }
  
  declare void @prelude_print(i8* %0)
  
  define i8* @schmu___agac.ac_string-concat_aiac.ac(i64* %arr, i8* %delim) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [1 x [1 x i8]] }* @0 to i8*), i8** %str, align 8
    tail call void @__g.u_incr_rc_ac.u(i8* bitcast ({ i64, i64, i64, [1 x [1 x i8]] }* @0 to i8*))
    %acc = alloca i8*, align 8
    %0 = bitcast i8** %acc to i8*
    %1 = bitcast i8** %str to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 8, i1 false)
    %__ig.u-ac-ac___fun1_ii.u-ac-ac = alloca %closure, align 8
    %funptr3 = bitcast %closure* %__ig.u-ac-ac___fun1_ii.u-ac-ac to i8**
    store i8* bitcast (void (i64, i64, i8*)* @schmu___ig.u-ac-ac___fun1_ii.u-ac-ac to i8*), i8** %funptr3, align 8
    %clsr___ig.u-ac-ac___fun1_ii.u-ac-ac = alloca { i64, i8*, i8**, i8* }, align 8
    %acc1 = getelementptr inbounds { i64, i8*, i8**, i8* }, { i64, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun1_ii.u-ac-ac, i32 0, i32 2
    store i8** %acc, i8*** %acc1, align 8
    %delim2 = getelementptr inbounds { i64, i8*, i8**, i8* }, { i64, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun1_ii.u-ac-ac, i32 0, i32 3
    store i8* %delim, i8** %delim2, align 8
    %rc4 = bitcast { i64, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun1_ii.u-ac-ac to i64*
    store i64 2, i64* %rc4, align 8
    %dtor = getelementptr inbounds { i64, i8*, i8**, i8* }, { i64, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun1_ii.u-ac-ac, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, i8**, i8* }* %clsr___ig.u-ac-ac___fun1_ii.u-ac-ac to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__ig.u-ac-ac___fun1_ii.u-ac-ac, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu___agig.u.u__prelude_array-iteri_aiii.u.u(i64* %arr, %closure* %__ig.u-ac-ac___fun1_ii.u-ac-ac)
    call void @schmu_string-add-null(i8** %acc)
    %2 = load i8*, i8** %acc, align 8
    ret i8* %2
  }
  
  define void @schmu___agag.u_string-append_acac.u(i8** %str, i8* %app) {
  entry:
    %__g.u-ag___fun0_c.u-ac = alloca %closure, align 8
    %funptr2 = bitcast %closure* %__g.u-ag___fun0_c.u-ac to i8**
    store i8* bitcast (void (i8, i8*)* @schmu___g.u-ag___fun0_c.u-ac to i8*), i8** %funptr2, align 8
    %clsr___g.u-ag___fun0_c.u-ac = alloca { i64, i8*, i8** }, align 8
    %str1 = getelementptr inbounds { i64, i8*, i8** }, { i64, i8*, i8** }* %clsr___g.u-ag___fun0_c.u-ac, i32 0, i32 2
    store i8** %str, i8*** %str1, align 8
    %rc3 = bitcast { i64, i8*, i8** }* %clsr___g.u-ag___fun0_c.u-ac to i64*
    store i64 2, i64* %rc3, align 8
    %dtor = getelementptr inbounds { i64, i8*, i8** }, { i64, i8*, i8** }* %clsr___g.u-ag___fun0_c.u-ac, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, i8** }* %clsr___g.u-ag___fun0_c.u-ac to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__g.u-ag___fun0_c.u-ac, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu___agg.u.u__prelude_array-iter_acc.u.u(i8* %app, %closure* %__g.u-ag___fun0_c.u-ac)
    ret void
  }
  
  define void @schmu___agg.u.u__prelude_array-iter_acc.u.u(i8* %arr, %closure* %f) {
  entry:
    %__i.u-ag-g.u__prelude_inner_i.u-ac-c.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-ag-g.u__prelude_inner_i.u-ac-c.u to i8**
    store i8* bitcast (void (i64, i8*)* @schmu___i.u-ag-g.u__prelude_inner_i.u-ac-c.u to i8*), i8** %funptr5, align 8
    %clsr___i.u-ag-g.u__prelude_inner_i.u-ac-c.u = alloca { i64, i8*, i8*, %closure }, align 8
    %arr1 = getelementptr inbounds { i64, i8*, i8*, %closure }, { i64, i8*, i8*, %closure }* %clsr___i.u-ag-g.u__prelude_inner_i.u-ac-c.u, i32 0, i32 2
    store i8* %arr, i8** %arr1, align 8
    %f2 = getelementptr inbounds { i64, i8*, i8*, %closure }, { i64, i8*, i8*, %closure }* %clsr___i.u-ag-g.u__prelude_inner_i.u-ac-c.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %rc6 = bitcast { i64, i8*, i8*, %closure }* %clsr___i.u-ag-g.u__prelude_inner_i.u-ac-c.u to i64*
    store i64 2, i64* %rc6, align 8
    %dtor = getelementptr inbounds { i64, i8*, i8*, %closure }, { i64, i8*, i8*, %closure }* %clsr___i.u-ag-g.u__prelude_inner_i.u-ac-c.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, i8*, %closure }* %clsr___i.u-ag-g.u__prelude_inner_i.u-ac-c.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-g.u__prelude_inner_i.u-ac-c.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu___i.u-ag-g.u__prelude_inner_i.u-ac-c.u(i64 0, i8* %env)
    ret void
  }
  
  define void @schmu___agig.u.u__prelude_array-iteri_aiii.u.u(i64* %arr, %closure* %f) {
  entry:
    %__i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u to i8**
    store i8* bitcast (void (i64, i8*)* @schmu___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u to i8*), i8** %funptr5, align 8
    %clsr___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u = alloca { i64, i8*, i64*, %closure }, align 8
    %arr1 = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u, i32 0, i32 2
    store i64* %arr, i64** %arr1, align 8
    %f2 = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %rc6 = bitcast { i64, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u to i64*
    store i64 2, i64* %rc6, align 8
    %dtor = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, i64*, %closure }* %clsr___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u(i64 0, i8* %env)
    ret void
  }
  
  define void @schmu___g.u-ag___fun0_c.u-ac(i8 %char, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i8** }*
    %str = getelementptr inbounds { i64, i8*, i8** }, { i64, i8*, i8** }* %clsr, i32 0, i32 2
    %str1 = load i8**, i8*** %str, align 8
    %1 = load i8*, i8** %str1, align 8
    %2 = bitcast i8* %1 to i64*
    %size = getelementptr i64, i64* %2, i64 1
    %size2 = load i64, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    %cap3 = load i64, i64* %cap, align 8
    %3 = icmp eq i64 %cap3, %size2
    br i1 %3, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %4 = tail call i8* @__ag.ag_reloc_ac.ac(i8** %str1)
    br label %merge
  
  grow:                                             ; preds = %entry
    %5 = tail call i8* @__ag.ag_grow_ac.ac(i8** %str1)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %6 = phi i8* [ %4, %keep ], [ %5, %grow ]
    %7 = bitcast i8* %6 to i64*
    %8 = add i64 24, %size2
    %9 = getelementptr i8, i8* %6, i64 %8
    store i8 %char, i8* %9, align 1
    %size4 = getelementptr i64, i64* %7, i64 1
    %10 = add i64 %size2, 1
    store i64 %10, i64* %size4, align 8
    ret void
  }
  
  define void @schmu___i.u-ag-g.u__prelude_inner_i.u-ac-c.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i8*, %closure }*
    %arr = getelementptr inbounds { i64, i8*, i8*, %closure }, { i64, i8*, i8*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i8*, i8** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %3 = bitcast i8* %arr1 to i64*
    %len = getelementptr i64, i64* %3, i64 1
    %4 = load i64, i64* %len, align 8
    %eq = icmp eq i64 %2, %4
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = getelementptr i8, i8* %arr1, i64 %2
    %sunkaddr4 = getelementptr i8, i8* %sunkaddr, i64 24
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
  
  define void @schmu___i.u-ag-ig.u__prelude_inner__2_i.u-ai-ii.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i64*, %closure }*
    %arr = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %len = getelementptr i64, i64* %arr1, i64 1
    %3 = load i64, i64* %len, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = mul i64 %2, 8
    %4 = bitcast i64* %arr1 to i8*
    %sunkaddr4 = getelementptr i8, i8* %4, i64 %sunkaddr
    %sunkaddr5 = getelementptr i8, i8* %sunkaddr4, i64 24
    %5 = bitcast i8* %sunkaddr5 to i64*
    %6 = load i64, i64* %5, align 8
    %sunkaddr7 = getelementptr inbounds i8, i8* %0, i64 24
    %7 = bitcast i8* %sunkaddr7 to i8**
    %loadtmp = load i8*, i8** %7, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i64, i8*)*
    %sunkaddr8 = getelementptr inbounds i8, i8* %0, i64 32
    %8 = bitcast i8* %sunkaddr8 to i8**
    %loadtmp2 = load i8*, i8** %8, align 8
    tail call void %casttmp(i64 %2, i64 %6, i8* %loadtmp2)
    %add = add i64 %2, 1
    store i64 %add, i64* %1, align 8
    br label %rec
  }
  
  define void @schmu___ig.u-ac-ac___fun1_ii.u-ac-ac(i64 %i, i64 %v, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i8**, i8* }*
    %acc = getelementptr inbounds { i64, i8*, i8**, i8* }, { i64, i8*, i8**, i8* }* %clsr, i32 0, i32 2
    %acc1 = load i8**, i8*** %acc, align 8
    %delim = getelementptr inbounds { i64, i8*, i8**, i8* }, { i64, i8*, i8**, i8* }* %clsr, i32 0, i32 3
    %delim2 = load i8*, i8** %delim, align 8
    %gt = icmp sgt i64 %i, 0
    br i1 %gt, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    tail call void @schmu___agag.u_string-append_acac.u(i8** %acc1, i8* %delim2)
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @1 to i8*), i64 24), i64 %v)
    %1 = add i32 %fmtsize, 25
    %2 = sext i32 %1 to i64
    %3 = tail call i8* @malloc(i64 %2)
    %4 = bitcast i8* %3 to i64*
    store i64 1, i64* %4, align 8
    %size = getelementptr i64, i64* %4, i64 1
    %5 = sext i32 %fmtsize to i64
    store i64 %5, i64* %size, align 8
    %cap = getelementptr i64, i64* %4, i64 2
    store i64 %5, i64* %cap, align 8
    %data = getelementptr i64, i64* %4, i64 3
    %6 = bitcast i64* %data to i8*
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %2, i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [4 x i8] }* @1 to i8*), i64 24), i64 %v)
    %str = alloca i8*, align 8
    store i8* %3, i8** %str, align 8
    tail call void @schmu___agag.u_string-append_acac.u(i8** %acc1, i8* %3)
    tail call void @__g.u_decr_rc_ac.u(i8* %3)
    ret void
  }
  
  define void @schmu_string-add-null(i8** %str) {
  entry:
    %0 = load i8*, i8** %str, align 8
    %1 = bitcast i8* %0 to i64*
    %size = getelementptr i64, i64* %1, i64 1
    %size1 = load i64, i64* %size, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    %cap2 = load i64, i64* %cap, align 8
    %2 = icmp eq i64 %cap2, %size1
    br i1 %2, label %grow, label %keep
  
  keep:                                             ; preds = %entry
    %3 = tail call i8* @__ag.ag_reloc_ac.ac(i8** %str)
    br label %merge
  
  grow:                                             ; preds = %entry
    %4 = tail call i8* @__ag.ag_grow_ac.ac(i8** %str)
    br label %merge
  
  merge:                                            ; preds = %grow, %keep
    %5 = phi i8* [ %3, %keep ], [ %4, %grow ]
    %6 = bitcast i8* %5 to i64*
    %7 = add i64 24, %size1
    %8 = getelementptr i8, i8* %5, i64 %7
    store i8 0, i8* %8, align 1
    %size3 = getelementptr i64, i64* %6, i64 1
    %9 = add i64 %size1, 1
    store i64 %9, i64* %size3, align 8
    %10 = tail call i8* @__ag.ag_reloc_ac.ac(i8** %str)
    %11 = bitcast i8* %10 to i64*
    %size4 = getelementptr i64, i64* %11, i64 1
    %size5 = load i64, i64* %size4, align 8
    %12 = icmp sgt i64 %size5, 0
    br i1 %12, label %drop_last, label %cont
  
  drop_last:                                        ; preds = %merge
    %13 = sub i64 %size5, 1
    %14 = add i64 24, %13
    %15 = getelementptr i8, i8* %10, i64 %14
    %sunkaddr = getelementptr i8, i8* %10, i64 8
    %16 = bitcast i8* %sunkaddr to i64*
    store i64 %13, i64* %16, align 8
    br label %cont
  
  cont:                                             ; preds = %drop_last, %merge
    ret void
  }
  
  define internal void @__g.u_incr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = add i64 %ref2, 1
    store i64 %1, i64* %ref13, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define internal i8* @__ag.ag_reloc_ac.ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %ref16 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref16, align 8
    %2 = icmp sgt i64 %ref2, 1
    br i1 %2, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %3 = bitcast i8* %1 to i64*
    %sz = getelementptr i64, i64* %3, i64 1
    %size = load i64, i64* %sz, align 8
    %cap = getelementptr i64, i64* %3, i64 2
    %cap3 = load i64, i64* %cap, align 8
    %4 = mul i64 %cap3, 1
    %5 = add i64 %4, 24
    %6 = call i8* @malloc(i64 %5)
    %7 = mul i64 %size, 1
    %8 = add i64 %7, 24
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %1, i64 %8, i1 false)
    store i8* %6, i8** %0, align 8
    %ref4 = bitcast i8* %6 to i64*
    %ref57 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref57, align 8
    call void @__g.u_decr_rc_ac.u(i8* %1)
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %9 = load i8*, i8** %0, align 8
    ret i8* %9
  }
  
  define internal void @__g.u_decr_rc_ac.u(i8* %0) {
  entry:
    %ref = bitcast i8* %0 to i64*
    %ref13 = bitcast i64* %ref to i64*
    %ref2 = load i64, i64* %ref13, align 8
    %1 = icmp eq i64 %ref2, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i8* %0 to i64*
    %3 = bitcast i64* %2 to i64*
    %4 = sub i64 %ref2, 1
    store i64 %4, i64* %3, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %5 = bitcast i8* %0 to i64*
    %6 = bitcast i64* %5 to i8*
    call void @free(i8* %6)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  define internal i8* @__ag.ag_grow_ac.ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %2 = bitcast i8* %1 to i64*
    %cap = getelementptr i64, i64* %2, i64 2
    %cap1 = load i64, i64* %cap, align 8
    %3 = mul i64 %cap1, 2
    %ref7 = bitcast i64* %2 to i64*
    %ref2 = load i64, i64* %ref7, align 8
    %4 = mul i64 %3, 1
    %5 = add i64 %4, 24
    %6 = icmp eq i64 %ref2, 1
    br i1 %6, label %realloc, label %malloc
  
  realloc:                                          ; preds = %entry
    %7 = load i8*, i8** %0, align 8
    %8 = call i8* @realloc(i8* %7, i64 %5)
    store i8* %8, i8** %0, align 8
    br label %merge
  
  malloc:                                           ; preds = %entry
    %9 = bitcast i8* %1 to i64*
    %10 = call i8* @malloc(i64 %5)
    %size = getelementptr i64, i64* %9, i64 1
    %size3 = load i64, i64* %size, align 8
    %11 = mul i64 %size3, 1
    %12 = add i64 %11, 24
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %1, i64 %12, i1 false)
    store i8* %10, i8** %0, align 8
    %ref4 = bitcast i8* %10 to i64*
    %ref58 = bitcast i64* %ref4 to i64*
    store i64 1, i64* %ref58, align 8
    call void @__g.u_decr_rc_ac.u(i8* %1)
    br label %merge
  
  merge:                                            ; preds = %malloc, %realloc
    %13 = phi i8* [ %8, %realloc ], [ %10, %malloc ]
    %newcap = bitcast i8* %13 to i64*
    %newcap6 = getelementptr i64, i64* %newcap, i64 2
    store i64 %3, i64* %newcap6, align 8
    %14 = load i8*, i8** %0, align 8
    ret i8* %14
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 104)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @arr, align 8
    store i64 1, i64* %1, align 8
    %size = getelementptr i64, i64* %1, i64 1
    store i64 10, i64* %size, align 8
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 10, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 24
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
    %3 = load i64*, i64** @arr, align 8
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [3 x i8] }* @2 to i8*), i8** %str, align 8
    %4 = tail call i8* @schmu___agac.ac_string-concat_aiac.ac(i64* %3, i8* bitcast ({ i64, i64, i64, [3 x i8] }* @2 to i8*))
    tail call void @prelude_print(i8* %4)
    tail call void @__g.u_decr_rc_ac.u(i8* %4)
    %5 = load i64*, i64** @arr, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %5)
    ret i64 0
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  declare void @free(i8* %0)
  
  declare i8* @realloc(i8* %0, i64 %1)
  
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
