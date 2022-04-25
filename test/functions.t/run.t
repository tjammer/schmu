Compile stubs
  $ cc -c stub.c

Test name resolution and IR creation of functions
We discard the triple, b/c it varies from distro to distro
e.g. x86_64-unknown-linux-gnu on Fedora vs x86_64-pc-linux-gnu on gentoo

Simple fibonacci
  $ schmu -dump-llvm fib.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define private i64 @fib(i64 %n) {
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
    %1 = tail call i64 @fib(i64 %0)
    %add = add i64 %1, %accumulator.tr
    %2 = add i64 %0, -1
    br label %tailrecurse
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @fib(i64 30)
    tail call void @printi(i64 %0)
    ret i64 0
  }
  832040

Fibonacci, but we shadow a bunch
  $ schmu -dump-llvm shadowing.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define private i64 @fib(i64 %n) {
  entry:
    %lt = icmp slt i64 %n, 2
    br i1 %lt, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %0 = tail call i64 @fibn2(i64 %n)
    %1 = tail call i64 @__fun0(i64 %n)
    %add = add i64 %0, %1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %add, %else ], [ %n, %entry ]
    ret i64 %iftmp
  }
  
  define private i64 @__fun0(i64 %n) {
  entry:
    %sub = sub i64 %n, 1
    %0 = tail call i64 @fib(i64 %sub)
    ret i64 %0
  }
  
  define private i64 @fibn2(i64 %n) {
  entry:
    %sub = sub i64 %n, 2
    %0 = tail call i64 @fib(i64 %sub)
    ret i64 %0
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @fib(i64 30)
    tail call void @printi(i64 %0)
    ret i64 0
  }
  832040

Multiple parameters
  $ schmu -dump-llvm multi_params.smu && cc out.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define private i64 @doiflesselse(i64 %a, i64 %b, i64 %greater, i64 %less) {
  entry:
    %lt = icmp slt i64 %a, %b
    br i1 %lt, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %greater, %else ], [ %less, %entry ]
    ret i64 %iftmp
  }
  
  define private i64 @add(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define private i64 @one() {
  entry:
    ret i64 1
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @one()
    %1 = tail call i64 @add(i64 %0, i64 1)
    %2 = tail call i64 @doiflesselse(i64 %1, i64 0, i64 1, i64 2)
    ret i64 %2
  }
  [1]

We have downwards closures
  $ schmu -dump-llvm closure.smu && cc out.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %capturable = type { i64 }
  %closure = type { i8*, i8* }
  
  define private i64 @capture_a_wrapped(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %capturable* }*
    %a5 = bitcast { %capturable* }* %clsr to %capturable**
    %a1 = load %capturable*, %capturable** %a5, align 8
    %wrap = alloca %closure, align 8
    %funptr6 = bitcast %closure* %wrap to i8**
    store i8* bitcast (i64 (i8*)* @wrap to i8*), i8** %funptr6, align 8
    %clsr_wrap = alloca { %capturable* }, align 8
    %a27 = bitcast { %capturable* }* %clsr_wrap to %capturable**
    store %capturable* %a1, %capturable** %a27, align 8
    %env = bitcast { %capturable* }* %clsr_wrap to i8*
    %envptr = getelementptr inbounds %closure, %closure* %wrap, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %1 = call i64 @wrap(i8* %env)
    ret i64 %1
  }
  
  define private i64 @wrap(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %capturable* }*
    %a5 = bitcast { %capturable* }* %clsr to %capturable**
    %a1 = load %capturable*, %capturable** %a5, align 8
    %inner = alloca %closure, align 8
    %funptr6 = bitcast %closure* %inner to i8**
    store i8* bitcast (i64 (i8*)* @inner to i8*), i8** %funptr6, align 8
    %clsr_inner = alloca { %capturable* }, align 8
    %a27 = bitcast { %capturable* }* %clsr_inner to %capturable**
    store %capturable* %a1, %capturable** %a27, align 8
    %env = bitcast { %capturable* }* %clsr_inner to i8*
    %envptr = getelementptr inbounds %closure, %closure* %inner, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %1 = call i64 @inner(i8* %env)
    ret i64 %1
  }
  
  define private i64 @inner(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %capturable* }*
    %a2 = bitcast { %capturable* }* %clsr to %capturable**
    %a1 = load %capturable*, %capturable** %a2, align 8
    %1 = bitcast %capturable* %a1 to i64*
    %2 = load i64, i64* %1, align 4
    %add = add i64 %2, 2
    ret i64 %add
  }
  
  define private i64 @capture_a(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %capturable* }*
    %a2 = bitcast { %capturable* }* %clsr to %capturable**
    %a1 = load %capturable*, %capturable** %a2, align 8
    %1 = bitcast %capturable* %a1 to i64*
    %2 = load i64, i64* %1, align 4
    %add = add i64 %2, 2
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca %capturable, align 8
    %a13 = bitcast %capturable* %0 to i64*
    store i64 10, i64* %a13, align 4
    %capture_a = alloca %closure, align 8
    %funptr14 = bitcast %closure* %capture_a to i8**
    store i8* bitcast (i64 (i8*)* @capture_a to i8*), i8** %funptr14, align 8
    %clsr_capture_a = alloca { %capturable* }, align 8
    %a115 = bitcast { %capturable* }* %clsr_capture_a to %capturable**
    store %capturable* %0, %capturable** %a115, align 8
    %env = bitcast { %capturable* }* %clsr_capture_a to i8*
    %envptr = getelementptr inbounds %closure, %closure* %capture_a, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %capture_a_wrapped = alloca %closure, align 8
    %funptr216 = bitcast %closure* %capture_a_wrapped to i8**
    store i8* bitcast (i64 (i8*)* @capture_a_wrapped to i8*), i8** %funptr216, align 8
    %clsr_capture_a_wrapped = alloca { %capturable* }, align 8
    %a317 = bitcast { %capturable* }* %clsr_capture_a_wrapped to %capturable**
    store %capturable* %0, %capturable** %a317, align 8
    %env4 = bitcast { %capturable* }* %clsr_capture_a_wrapped to i8*
    %envptr5 = getelementptr inbounds %closure, %closure* %capture_a_wrapped, i32 0, i32 1
    store i8* %env4, i8** %envptr5, align 8
    %1 = call i64 @capture_a(i8* %env)
    %2 = call i64 @capture_a_wrapped(i8* %env4)
    ret i64 %2
  }
  [12]

First class functions
  $ schmu -dump-llvm first_class.smu && cc out.o stub.o && ./a.out
  first_class.smu:11:1: warning: Unused binding pass2
  11 | pass2 = fun(x) x end
       ^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  declare void @printi(i64 %0)
  
  define private i64 @__g.g_pass_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define private i64 @__fun2(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define private i1 @__gg.g.g_apply_bb.b.b(i1 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i1 (i1, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i1 %casttmp(i1 %x, i8* %loadtmp1)
    ret i1 %0
  }
  
  define private i64 @__fun1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define private i64 @__gg.g.g_apply_ii.i.i(i64 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i64 %x, i8* %loadtmp1)
    ret i64 %0
  }
  
  define private i64 @int_of_bool(i1 %b) {
  entry:
    br i1 %b, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define private i1 @makefalse(i1 %b) {
  entry:
    ret i1 false
  }
  
  define private i64 @add1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr13 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64)* @add1 to i8*), i8** %funptr13, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @__gg.g.g_apply_ii.i.i(i64 0, %closure* %clstmp)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr214 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @__fun1 to i8*), i8** %funptr214, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %1 = call i64 @__gg.g.g_apply_ii.i.i(i64 1, %closure* %clstmp1)
    call void @printi(i64 %1)
    %clstmp4 = alloca %closure, align 8
    %funptr515 = bitcast %closure* %clstmp4 to i8**
    store i8* bitcast (i1 (i1)* @makefalse to i8*), i8** %funptr515, align 8
    %envptr6 = getelementptr inbounds %closure, %closure* %clstmp4, i32 0, i32 1
    store i8* null, i8** %envptr6, align 8
    %2 = call i1 @__gg.g.g_apply_bb.b.b(i1 true, %closure* %clstmp4)
    %3 = call i64 @int_of_bool(i1 %2)
    call void @printi(i64 %3)
    %clstmp7 = alloca %closure, align 8
    %funptr816 = bitcast %closure* %clstmp7 to i8**
    store i8* bitcast (i64 (i64)* @__fun2 to i8*), i8** %funptr816, align 8
    %envptr9 = getelementptr inbounds %closure, %closure* %clstmp7, i32 0, i32 1
    store i8* null, i8** %envptr9, align 8
    %4 = call i64 @__gg.g.g_apply_ii.i.i(i64 3, %closure* %clstmp7)
    call void @printi(i64 %4)
    %clstmp10 = alloca %closure, align 8
    %funptr1117 = bitcast %closure* %clstmp10 to i8**
    store i8* bitcast (i64 (i64)* @__g.g_pass_i.i to i8*), i8** %funptr1117, align 8
    %envptr12 = getelementptr inbounds %closure, %closure* %clstmp10, i32 0, i32 1
    store i8* null, i8** %envptr12, align 8
    %5 = call i64 @__gg.g.g_apply_ii.i.i(i64 4, %closure* %clstmp10)
    call void @printi(i64 %5)
    ret i64 0
  }
  1
  2
  0
  3
  4

We don't allow returning closures
  $ schmu -dump-llvm no_closure_returns.smu
  no_closure_returns.smu:5:1: error: Cannot (yet) return a closure
  5 | fun()
  6 |   a = fun() a end
  7 |   a
  8 | end
  
  [1]

Don't try to create 'void' value in if
  $ schmu -dump-llvm if_return_void.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define private void @foo(i64 %i) {
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
    tail call void @foo(i64 4)
    ret i64 0
  }
  4
  3
  2
  0

Captured values should not overwrite function params
  $ schmu -dump-llvm overwrite_params.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  declare void @printi(i64 %0)
  
  define private i64 @add(%closure* %a, %closure* %b) {
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
  
  define private i64 @two() {
  entry:
    ret i64 2
  }
  
  define private i64 @one() {
  entry:
    ret i64 1
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr4 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 ()* @one to i8*), i8** %funptr4, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr25 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 ()* @two to i8*), i8** %funptr25, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %0 = call i64 @add(%closure* %clstmp, %closure* %clstmp1)
    call void @printi(i64 %0)
    ret i64 0
  }
  3

Functions can be generic. In this test, we generate 'apply' only once and use it with
3 different functions with different types
  $ schmu -dump-llvm generic_fun_arg.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %t_bool = type { i1 }
  %t_int = type { i64 }
  
  declare void @printi(i64 %0)
  
  define private i64 @__fun1(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define private i64 @__g.g___fun0_ti.ti(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    ret i64 %0
  }
  
  define private i1 @__gg.g.g_apply_bb.b.b(i1 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i1 (i1, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i1 %casttmp(i1 %x, i8* %loadtmp1)
    ret i1 %0
  }
  
  define private i8 @__gg.g.g_apply_tbtb.tb.tb(i8 %0, %closure* %f) {
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
  
  define private i64 @__gg.g.g_apply_titi.ti.ti(i64 %0, %closure* %f) {
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
  
  define private i64 @__gg.g.g_apply_ii.i.i(i64 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i64 %casttmp(i64 %x, i8* %loadtmp1)
    ret i64 %0
  }
  
  define private i64 @add3_rec(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %1 = alloca %t_int, align 8
    %x3 = bitcast %t_int* %1 to i64*
    %add = add i64 %0, 3
    store i64 %add, i64* %x3, align 4
    ret i64 %add
  }
  
  define private i8 @make_rec_false(i8 %0) {
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
  
  define private i1 @makefalse(i1 %b) {
  entry:
    ret i1 false
  }
  
  define private void @print_bool(i1 %b) {
  entry:
    br i1 %b, label %then, label %else
  
  then:                                             ; preds = %entry
    tail call void @printi(i64 1)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @printi(i64 0)
    ret void
  }
  
  define private i64 @add1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define private i64 @add_closed(i64 %x) {
  entry:
    %add = add i64 %x, 2
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr20 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64)* @add1 to i8*), i8** %funptr20, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @__gg.g.g_apply_ii.i.i(i64 20, %closure* %clstmp)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr221 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @add_closed to i8*), i8** %funptr221, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %1 = call i64 @__gg.g.g_apply_ii.i.i(i64 20, %closure* %clstmp1)
    call void @printi(i64 %1)
    %clstmp4 = alloca %closure, align 8
    %funptr522 = bitcast %closure* %clstmp4 to i8**
    store i8* bitcast (i64 (i64)* @add3_rec to i8*), i8** %funptr522, align 8
    %envptr6 = getelementptr inbounds %closure, %closure* %clstmp4, i32 0, i32 1
    store i8* null, i8** %envptr6, align 8
    %ret = alloca %t_int, align 8
    %2 = call i64 @__gg.g.g_apply_titi.ti.ti(i64 bitcast (%t_int { i64 20 } to i64), %closure* %clstmp4)
    %box = bitcast %t_int* %ret to i64*
    store i64 %2, i64* %box, align 4
    call void @printi(i64 %2)
    %clstmp8 = alloca %closure, align 8
    %funptr923 = bitcast %closure* %clstmp8 to i8**
    store i8* bitcast (i8 (i8)* @make_rec_false to i8*), i8** %funptr923, align 8
    %envptr10 = getelementptr inbounds %closure, %closure* %clstmp8, i32 0, i32 1
    store i8* null, i8** %envptr10, align 8
    %ret11 = alloca %t_bool, align 8
    %3 = call i8 @__gg.g.g_apply_tbtb.tb.tb(i8 bitcast (%t_bool { i1 true } to i8), %closure* %clstmp8)
    %box12 = bitcast %t_bool* %ret11 to i8*
    store i8 %3, i8* %box12, align 1
    %4 = trunc i8 %3 to i1
    call void @print_bool(i1 %4)
    %clstmp14 = alloca %closure, align 8
    %funptr1524 = bitcast %closure* %clstmp14 to i8**
    store i8* bitcast (i1 (i1)* @makefalse to i8*), i8** %funptr1524, align 8
    %envptr16 = getelementptr inbounds %closure, %closure* %clstmp14, i32 0, i32 1
    store i8* null, i8** %envptr16, align 8
    %5 = call i1 @__gg.g.g_apply_bb.b.b(i1 true, %closure* %clstmp14)
    call void @print_bool(i1 %5)
    %ret17 = alloca %t_int, align 8
    %6 = call i64 @__g.g___fun0_ti.ti(i64 bitcast (%t_int { i64 17 } to i64))
    %box18 = bitcast %t_int* %ret17 to i64*
    store i64 %6, i64* %box18, align 4
    call void @printi(i64 %6)
    %7 = call i64 @__fun1(i64 18)
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
  $ schmu -dump-llvm generic_pass.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %t = type { i64, i1 }
  
  declare void @printi(i64 %0)
  
  define private { i64, i8 } @__g.g_pass_t.t(i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst3 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst3, align 4
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %box, i32 0, i32 1
    store i8 %1, i8* %snd, align 1
    %unbox2 = load { i64, i8 }, { i64, i8 }* %box, align 4
    ret { i64, i8 } %unbox2
  }
  
  define private { i64, i8 } @__g.gg.g_apply_t.tt.t(%closure* %f, i64 %0, i8 %1) {
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
  
  define private i64 @__g.g_pass_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define private i64 @__g.gg.g_apply_i.ii.i(%closure* %f, i64 %x) {
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
    store i8* bitcast (i64 (i64)* @__g.g_pass_i.i to i8*), i8** %funptr7, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i64 @__g.gg.g_apply_i.ii.i(%closure* %clstmp, i64 20)
    call void @printi(i64 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr28 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast ({ i64, i8 } (i64, i8)* @__g.g_pass_t.t to i8*), i8** %funptr28, align 8
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
    %1 = call { i64, i8 } @__g.gg.g_apply_t.tt.t(%closure* %clstmp1, i64 %fst4, i8 %snd5)
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
  $ schmu -dump-llvm indirect_closure.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %t_int = type { i64 }
  
  declare void @printi(i64 %0)
  
  define private i64 @__ggg.g.gg.g.g_apply2_titii.i.tii.i.ti(i64 %0, %closure* %f, %closure* %env) {
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
  
  define private i64 @__tgg.g.tg_boxed2int_int_tii.i.ti(i64 %0, %closure* %env) {
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
  
  define private i64 @__ggg.gg.g_apply_titii.i.tii.i.ti(i64 %0, %closure* %f, %closure* %env) {
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
  
  define private i64 @add1(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr14 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i64 (i64, %closure*)* @__tgg.g.tg_boxed2int_int_tii.i.ti to i8*), i8** %funptr14, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr215 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i64 (i64)* @add1 to i8*), i8** %funptr215, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %ret = alloca %t_int, align 8
    %0 = call i64 @__ggg.gg.g_apply_titii.i.tii.i.ti(i64 bitcast (%t_int { i64 15 } to i64), %closure* %clstmp, %closure* %clstmp1)
    %box = bitcast %t_int* %ret to i64*
    store i64 %0, i64* %box, align 4
    call void @printi(i64 %0)
    %clstmp5 = alloca %closure, align 8
    %funptr616 = bitcast %closure* %clstmp5 to i8**
    store i8* bitcast (i64 (i64, %closure*)* @__tgg.g.tg_boxed2int_int_tii.i.ti to i8*), i8** %funptr616, align 8
    %envptr7 = getelementptr inbounds %closure, %closure* %clstmp5, i32 0, i32 1
    store i8* null, i8** %envptr7, align 8
    %clstmp8 = alloca %closure, align 8
    %funptr917 = bitcast %closure* %clstmp8 to i8**
    store i8* bitcast (i64 (i64)* @add1 to i8*), i8** %funptr917, align 8
    %envptr10 = getelementptr inbounds %closure, %closure* %clstmp8, i32 0, i32 1
    store i8* null, i8** %envptr10, align 8
    %ret11 = alloca %t_int, align 8
    %1 = call i64 @__ggg.g.gg.g.g_apply2_titii.i.tii.i.ti(i64 bitcast (%t_int { i64 15 } to i64), %closure* %clstmp5, %closure* %clstmp8)
    %box12 = bitcast %t_int* %ret11 to i64*
    store i64 %1, i64* %box12, align 4
    call void @printi(i64 %1)
    ret i64 0
  }
  16
  16

Closures can recurse too
  $ schmu -dump-llvm recursive_closure.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i64 %0)
  
  define private void @loop(i64 %i) {
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
    tail call void @loop(i64 0)
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
  $ schmu -dump-llvm no_lambda_let_poly_monomorph.smu
  no_lambda_let_poly_monomorph.smu:6:5: error: Returning polymorphic anonymous function in if expressions is not supported (yet). Sorry. You can type the function concretely though.
  6 | f = if true then fun(x) x end else fun(x) x end end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  
  [1]
Allow mixing of typedefs and external decls in the preface
  $ schmu -dump-llvm mix_preface.smu
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
  $ schmu -dump-llvm monomorph_nested.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %rec = type { i64 }
  
  declare void @printi(i64 %0)
  
  define private i64 @__g.g_wrapped_rec.rec(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %ret = alloca %rec, align 8
    %1 = tail call i64 @__g.g_id_rec.rec(i64 %0)
    %box3 = bitcast %rec* %ret to i64*
    store i64 %1, i64* %box3, align 4
    ret i64 %1
  }
  
  define private i64 @__g.g_id_rec.rec(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    ret i64 %0
  }
  
  define private i1 @__g.g_wrapped_b.b(i1 %x) {
  entry:
    %0 = tail call i1 @__g.g_id_b.b(i1 %x)
    ret i1 %0
  }
  
  define private i1 @__g.g_id_b.b(i1 %x) {
  entry:
    ret i1 %x
  }
  
  define private i64 @__g.g_wrapped_i.i(i64 %x) {
  entry:
    %0 = tail call i64 @__g.g_id_i.i(i64 %x)
    ret i64 %0
  }
  
  define private i64 @__g.g_id_i.i(i64 %x) {
  entry:
    ret i64 %x
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @__g.g_wrapped_i.i(i64 12)
    tail call void @printi(i64 %0)
    %1 = tail call i1 @__g.g_wrapped_b.b(i1 false)
    %ret = alloca %rec, align 8
    %2 = tail call i64 @__g.g_wrapped_rec.rec(i64 bitcast (%rec { i64 24 } to i64))
    %box = bitcast %rec* %ret to i64*
    store i64 %2, i64* %box, align 4
    tail call void @printi(i64 %2)
    ret i64 0
  }
  12
  24

Nested polymorphic closures. Does not quite work for another nesting level
  $ schmu -dump-llvm nested_polymorphic_closures.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { i64*, i64, i64 }
  %closure = type { i8*, i8* }
  
  declare void @printi(i64 %0)
  
  define private void @__fun0(i64 %x) {
  entry:
    %mul = mul i64 %x, 2
    tail call void @printi(i64 %mul)
    ret void
  }
  
  define private void @__vectorgg.u.u_vector_iter_vectorii.u.u(%vector_int* %vec, %closure* %f) {
  entry:
    %monoclstmp = alloca %closure, align 8
    %funptr27 = bitcast %closure* %monoclstmp to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u_inner_cls_both_i.u to i8*), i8** %funptr27, align 8
    %clsr_monoclstmp = alloca { %closure*, %vector_int* }, align 8
    %f128 = bitcast { %closure*, %vector_int* }* %clsr_monoclstmp to %closure**
    store %closure* %f, %closure** %f128, align 8
    %vec2 = getelementptr inbounds { %closure*, %vector_int* }, { %closure*, %vector_int* }* %clsr_monoclstmp, i32 0, i32 1
    store %vector_int* %vec, %vector_int** %vec2, align 8
    %env = bitcast { %closure*, %vector_int* }* %clsr_monoclstmp to i8*
    %envptr = getelementptr inbounds %closure, %closure* %monoclstmp, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__i.u_inner_cls_both_i.u(i64 0, i8* %env)
    %monoclstmp5 = alloca %closure, align 8
    %funptr629 = bitcast %closure* %monoclstmp5 to i8**
    store i8* bitcast (void (i64, %closure*, i8*)* @__ig.u.u_inner_cls_vec_ii.u.u to i8*), i8** %funptr629, align 8
    %clsr_monoclstmp7 = alloca { %vector_int* }, align 8
    %vec830 = bitcast { %vector_int* }* %clsr_monoclstmp7 to %vector_int**
    store %vector_int* %vec, %vector_int** %vec830, align 8
    %env9 = bitcast { %vector_int* }* %clsr_monoclstmp7 to i8*
    %envptr10 = getelementptr inbounds %closure, %closure* %monoclstmp5, i32 0, i32 1
    store i8* %env9, i8** %envptr10, align 8
    call void @__ig.u.u_inner_cls_vec_ii.u.u(i64 0, %closure* %f, i8* %env9)
    %monoclstmp16 = alloca %closure, align 8
    %funptr1731 = bitcast %closure* %monoclstmp16 to i8**
    store i8* bitcast (void (i64, %vector_int*, i8*)* @__ivectorg.u_inner_cls_f_ivectori.u to i8*), i8** %funptr1731, align 8
    %clsr_monoclstmp18 = alloca { %closure* }, align 8
    %f1932 = bitcast { %closure* }* %clsr_monoclstmp18 to %closure**
    store %closure* %f, %closure** %f1932, align 8
    %env20 = bitcast { %closure* }* %clsr_monoclstmp18 to i8*
    %envptr21 = getelementptr inbounds %closure, %closure* %monoclstmp16, i32 0, i32 1
    store i8* %env20, i8** %envptr21, align 8
    call void @__ivectorg.u_inner_cls_f_ivectori.u(i64 0, %vector_int* %vec, i8* %env20)
    ret void
  }
  
  define private void @__ivectorg.u_inner_cls_f_ivectori.u(i64 %i, %vector_int* %vec, i8* %0) {
  entry:
    br label %tailrecurse
  
  tailrecurse:                                      ; preds = %else, %entry
    %i.tr = phi i64 [ %i, %entry ], [ %add, %else ]
    %clsr = bitcast i8* %0 to { %closure* }*
    %f3 = bitcast { %closure* }* %clsr to %closure**
    %f1 = load %closure*, %closure** %f3, align 8
    %1 = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    %2 = load i64, i64* %1, align 4
    %eq = icmp eq i64 %i.tr, %2
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %tailrecurse
    ret void
  
  else:                                             ; preds = %tailrecurse
    %3 = bitcast %vector_int* %vec to i64**
    %4 = load i64*, i64** %3, align 8
    %scevgep = getelementptr i64, i64* %4, i64 %i.tr
    %5 = load i64, i64* %scevgep, align 4
    %funcptr4 = bitcast %closure* %f1 to i8**
    %loadtmp = load i8*, i8** %funcptr4, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f1, i32 0, i32 1
    %loadtmp2 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %5, i8* %loadtmp2)
    %add = add i64 %i.tr, 1
    br label %tailrecurse
  }
  
  define private void @__ig.u.u_inner_cls_vec_ii.u.u(i64 %i, %closure* %f, i8* %0) {
  entry:
    br label %tailrecurse
  
  tailrecurse:                                      ; preds = %else, %entry
    %i.tr = phi i64 [ %i, %entry ], [ %add, %else ]
    %clsr = bitcast i8* %0 to { %vector_int* }*
    %vec3 = bitcast { %vector_int* }* %clsr to %vector_int**
    %vec1 = load %vector_int*, %vector_int** %vec3, align 8
    %1 = getelementptr inbounds %vector_int, %vector_int* %vec1, i32 0, i32 1
    %2 = load i64, i64* %1, align 4
    %eq = icmp eq i64 %i.tr, %2
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %tailrecurse
    ret void
  
  else:                                             ; preds = %tailrecurse
    %3 = bitcast %vector_int* %vec1 to i64**
    %4 = load i64*, i64** %3, align 8
    %scevgep = getelementptr i64, i64* %4, i64 %i.tr
    %5 = load i64, i64* %scevgep, align 4
    %funcptr4 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr4, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp2 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %5, i8* %loadtmp2)
    %add = add i64 %i.tr, 1
    br label %tailrecurse
  }
  
  define private void @__i.u_inner_cls_both_i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %closure*, %vector_int* }*
    %f6 = bitcast { %closure*, %vector_int* }* %clsr to %closure**
    %f1 = load %closure*, %closure** %f6, align 8
    %vec = getelementptr inbounds { %closure*, %vector_int* }, { %closure*, %vector_int* }* %clsr, i32 0, i32 1
    %vec2 = load %vector_int*, %vector_int** %vec, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %i3 = phi i64 [ %add, %else ], [ %i, %entry ]
    %2 = getelementptr inbounds %vector_int, %vector_int* %vec2, i32 0, i32 1
    %3 = load i64, i64* %2, align 4
    %eq = icmp eq i64 %i3, %3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %4 = bitcast %vector_int* %vec2 to i64**
    %5 = load i64*, i64** %4, align 8
    %scevgep = getelementptr i64, i64* %5, i64 %i3
    %6 = load i64, i64* %scevgep, align 4
    %funcptr7 = bitcast %closure* %f1 to i8**
    %loadtmp = load i8*, i8** %funcptr7, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f1, i32 0, i32 1
    %loadtmp4 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %6, i8* %loadtmp4)
    %add = add i64 %i3, 1
    store i64 %add, i64* %1, align 4
    br label %rec
  }
  
  define private void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i64 %val) {
  entry:
    %0 = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    %1 = load i64, i64* %0, align 4
    %2 = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 2
    %3 = load i64, i64* %2, align 4
    %lt = icmp slt i64 %1, %3
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %entry
    %4 = bitcast %vector_int* %vec to i64**
    %5 = load i64*, i64** %4, align 8
    %6 = getelementptr inbounds i64, i64* %5, i64 %1
    store i64 %val, i64* %6, align 4
    %7 = bitcast %vector_int* %vec to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %7, i64 8
    %8 = bitcast i8* %sunkaddr to i64*
    %9 = load i64, i64* %8, align 4
    %add = add i64 %9, 1
    store i64 %add, i64* %8, align 4
    br label %ifcont
  
  else:                                             ; preds = %entry
    %mul = mul i64 %3, 2
    %10 = bitcast %vector_int* %vec to i64**
    %11 = load i64*, i64** %10, align 8
    %12 = mul i64 %mul, 8
    %13 = bitcast i64* %11 to i8*
    %14 = tail call i8* @realloc(i8* %13, i64 %12)
    %15 = bitcast i8* %14 to i64*
    store i64* %15, i64** %10, align 8
    %16 = bitcast %vector_int* %vec to i8*
    %sunkaddr2 = getelementptr inbounds i8, i8* %16, i64 16
    %17 = bitcast i8* %sunkaddr2 to i64*
    store i64 %mul, i64* %17, align 4
    %18 = bitcast %vector_int* %vec to i8*
    %sunkaddr3 = getelementptr inbounds i8, i8* %18, i64 8
    %19 = bitcast i8* %sunkaddr3 to i64*
    %20 = load i64, i64* %19, align 4
    %21 = getelementptr inbounds i64, i64* %15, i64 %20
    store i64 %val, i64* %21, align 4
    %22 = load i64, i64* %19, align 4
    %add1 = add i64 %22, 1
    store i64 %add1, i64* %19, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    %vec = alloca %vector_int, align 8
    %data1 = bitcast %vector_int* %vec to i64**
    store i64* %1, i64** %data1, align 8
    %len = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 0, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 2
    store i64 1, i64* %cap, align 4
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i64 1)
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i64 2)
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i64 3)
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i64 4)
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i64 5)
    %clstmp = alloca %closure, align 8
    %funptr2 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @__fun0 to i8*), i8** %funptr2, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @__vectorgg.u.u_vector_iter_vectorii.u.u(%vector_int* %vec, %closure* %clstmp)
    %2 = load i64*, i64** %data1, align 8
    %3 = bitcast i64* %2 to i8*
    call void @free(i8* %3)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
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
  $ schmu -dump-llvm closures_to_env.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1)
  
  define private void @use_above() {
  entry:
    %str = alloca %string, align 8
    %cstr1 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr1, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %0 = tail call i64 @close_over_a()
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    ret void
  }
  
  define private i64 @close_over_a() {
  entry:
    ret i64 20
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @use_above()
    ret i64 0
  }
  20
