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
  
  declare void @printi(i32 %0)
  
  define private i32 @fib(i32 %n) {
  entry:
    br label %tailrecurse
  
  tailrecurse:                                      ; preds = %else, %entry
    %accumulator.tr = phi i32 [ 0, %entry ], [ %addtmp, %else ]
    %n.tr = phi i32 [ %n, %entry ], [ %2, %else ]
    %lesstmp = icmp slt i32 %n.tr, 2
    br i1 %lesstmp, label %then, label %else
  
  then:                                             ; preds = %tailrecurse
    %accumulator.ret.tr = add i32 %n.tr, %accumulator.tr
    ret i32 %accumulator.ret.tr
  
  else:                                             ; preds = %tailrecurse
    %0 = add i32 %n.tr, -1
    %1 = tail call i32 @fib(i32 %0)
    %addtmp = add i32 %1, %accumulator.tr
    %2 = add i32 %0, -1
    br label %tailrecurse
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = tail call i32 @fib(i32 30)
    tail call void @printi(i32 %0)
    ret i32 0
  }
  832040

Fibonacci, but we shadow a bunch
  $ schmu -dump-llvm shadowing.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i32 %0)
  
  define private i32 @fib(i32 %n) {
  entry:
    %lesstmp = icmp slt i32 %n, 2
    br i1 %lesstmp, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %0 = tail call i32 @fibn2(i32 %n)
    %1 = tail call i32 @__fun0(i32 %n)
    %addtmp = add i32 %0, %1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i32 [ %addtmp, %else ], [ %n, %entry ]
    ret i32 %iftmp
  }
  
  define private i32 @__fun0(i32 %n) {
  entry:
    %subtmp = sub i32 %n, 1
    %0 = tail call i32 @fib(i32 %subtmp)
    ret i32 %0
  }
  
  define private i32 @fibn2(i32 %n) {
  entry:
    %subtmp = sub i32 %n, 2
    %0 = tail call i32 @fib(i32 %subtmp)
    ret i32 %0
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = tail call i32 @fib(i32 30)
    tail call void @printi(i32 %0)
    ret i32 0
  }
  832040

Multiple parameters
  $ schmu -dump-llvm multi_params.smu && cc out.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define private i32 @doiflesselse(i32 %a, i32 %b, i32 %greater, i32 %less) {
  entry:
    %lesstmp = icmp slt i32 %a, %b
    br i1 %lesstmp, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i32 [ %greater, %else ], [ %less, %entry ]
    ret i32 %iftmp
  }
  
  define private i32 @add(i32 %a, i32 %b) {
  entry:
    %addtmp = add i32 %a, %b
    ret i32 %addtmp
  }
  
  define private i32 @one() {
  entry:
    ret i32 1
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = tail call i32 @one()
    %1 = tail call i32 @add(i32 %0, i32 1)
    %2 = tail call i32 @doiflesselse(i32 %1, i32 0, i32 1, i32 2)
    ret i32 %2
  }
  [1]

We have downwards closures
  $ schmu -dump-llvm closure.smu && cc out.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  define private i32 @capture_a(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i32 }*
    %a2 = bitcast { i32 }* %clsr to i32*
    %a1 = load i32, i32* %a2, align 4
    %addtmp = add i32 %a1, 2
    ret i32 %addtmp
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %capture_a = alloca %closure, align 8
    %funptr3 = bitcast %closure* %capture_a to i8**
    store i8* bitcast (i32 (i8*)* @capture_a to i8*), i8** %funptr3, align 8
    %clsr_capture_a = alloca { i32 }, align 8
    %a4 = bitcast { i32 }* %clsr_capture_a to i32*
    store i32 10, i32* %a4, align 4
    %env = bitcast { i32 }* %clsr_capture_a to i8*
    %envptr = getelementptr inbounds %closure, %closure* %capture_a, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %0 = call i32 @capture_a(i8* %env)
    ret i32 %0
  }
  [12]

First class functions
  $ schmu -dump-llvm first_class.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private i32 @__g.g_pass_i.i(i32 %x) {
  entry:
    ret i32 %x
  }
  
  define private i32 @__fun2(i32 %x) {
  entry:
    ret i32 %x
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
  
  define private i32 @__fun1(i32 %x) {
  entry:
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
  }
  
  define private i32 @__gg.g.g_apply_ii.i.i(i32 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i32 %casttmp(i32 %x, i8* %loadtmp1)
    ret i32 %0
  }
  
  define private i32 @int_of_bool(i1 %b) {
  entry:
    br i1 %b, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i32 [ 0, %else ], [ 1, %entry ]
    ret i32 %iftmp
  }
  
  define private i1 @makefalse(i1 %b) {
  entry:
    ret i1 false
  }
  
  define private i32 @add1(i32 %x) {
  entry:
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr13 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr13, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i32 @__gg.g.g_apply_ii.i.i(i32 0, %closure* %clstmp)
    call void @printi(i32 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr214 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i32 (i32)* @__fun1 to i8*), i8** %funptr214, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %1 = call i32 @__gg.g.g_apply_ii.i.i(i32 1, %closure* %clstmp1)
    call void @printi(i32 %1)
    %clstmp4 = alloca %closure, align 8
    %funptr515 = bitcast %closure* %clstmp4 to i8**
    store i8* bitcast (i1 (i1)* @makefalse to i8*), i8** %funptr515, align 8
    %envptr6 = getelementptr inbounds %closure, %closure* %clstmp4, i32 0, i32 1
    store i8* null, i8** %envptr6, align 8
    %2 = call i1 @__gg.g.g_apply_bb.b.b(i1 true, %closure* %clstmp4)
    %3 = call i32 @int_of_bool(i1 %2)
    call void @printi(i32 %3)
    %clstmp7 = alloca %closure, align 8
    %funptr816 = bitcast %closure* %clstmp7 to i8**
    store i8* bitcast (i32 (i32)* @__fun2 to i8*), i8** %funptr816, align 8
    %envptr9 = getelementptr inbounds %closure, %closure* %clstmp7, i32 0, i32 1
    store i8* null, i8** %envptr9, align 8
    %4 = call i32 @__gg.g.g_apply_ii.i.i(i32 3, %closure* %clstmp7)
    call void @printi(i32 %4)
    %clstmp10 = alloca %closure, align 8
    %funptr1117 = bitcast %closure* %clstmp10 to i8**
    store i8* bitcast (i32 (i32)* @__g.g_pass_i.i to i8*), i8** %funptr1117, align 8
    %envptr12 = getelementptr inbounds %closure, %closure* %clstmp10, i32 0, i32 1
    store i8* null, i8** %envptr12, align 8
    %5 = call i32 @__gg.g.g_apply_ii.i.i(i32 4, %closure* %clstmp10)
    call void @printi(i32 %5)
    ret i32 0
  }
  1
  2
  0
  3
  4

We don't allow returning closures
  $ schmu -dump-llvm no_closure_returns.smu
  no_closure_returns.smu:3:1: error: Cannot (yet) return a closure
  3 | fun()
                                                                   4 |   a = fun() a end
                                                                   5 |   a
                                                                   6 | end
                                                                   
  [1]

Don't try to create 'void' value in if
  $ schmu -dump-llvm if_return_void.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i32 %0)
  
  define private void @foo(i32 %i) {
  entry:
    %0 = alloca i32, align 4
    store i32 %i, i32* %0, align 4
    br label %rec
  
  rec:                                              ; preds = %ifcont, %entry
    %i1 = phi i32 [ %subtmp5, %ifcont ], [ %i, %entry ]
    %lesstmp = icmp slt i32 %i1, 2
    br i1 %lesstmp, label %then, label %else
  
  then:                                             ; preds = %rec
    %1 = add i32 %i1, -1
    tail call void @printi(i32 %1)
    ret void
  
  else:                                             ; preds = %rec
    %lesstmp2 = icmp slt i32 %i1, 400
    br i1 %lesstmp2, label %then3, label %else4
  
  then3:                                            ; preds = %else
    tail call void @printi(i32 %i1)
    br label %ifcont
  
  else4:                                            ; preds = %else
    %addtmp = add i32 %i1, 1
    tail call void @printi(i32 %addtmp)
    br label %ifcont
  
  ifcont:                                           ; preds = %else4, %then3
    %subtmp5 = sub i32 %i1, 1
    %2 = add i32 %i1, -1
    store i32 %2, i32* %0, align 4
    br label %rec
  }
  
  define i32 @main(i32 %arg) {
  entry:
    tail call void @foo(i32 4)
    ret i32 0
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
  
  declare void @printi(i32 %0)
  
  define private i32 @add(%closure* %a, %closure* %b) {
  entry:
    %funcptr7 = bitcast %closure* %a to i8**
    %loadtmp = load i8*, i8** %funcptr7, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %a, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i32 %casttmp(i8* %loadtmp1)
    %funcptr28 = bitcast %closure* %b to i8**
    %loadtmp3 = load i8*, i8** %funcptr28, align 8
    %casttmp4 = bitcast i8* %loadtmp3 to i32 (i8*)*
    %envptr5 = getelementptr inbounds %closure, %closure* %b, i32 0, i32 1
    %loadtmp6 = load i8*, i8** %envptr5, align 8
    %1 = tail call i32 %casttmp4(i8* %loadtmp6)
    %addtmp = add i32 %0, %1
    ret i32 %addtmp
  }
  
  define private i32 @two(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i32 }*
    %b2 = bitcast { i32 }* %clsr to i32*
    %b1 = load i32, i32* %b2, align 4
    ret i32 %b1
  }
  
  define private i32 @one() {
  entry:
    ret i32 1
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %two = alloca %closure, align 8
    %funptr3 = bitcast %closure* %two to i8**
    store i8* bitcast (i32 (i8*)* @two to i8*), i8** %funptr3, align 8
    %clsr_two = alloca { i32 }, align 8
    %b4 = bitcast { i32 }* %clsr_two to i32*
    store i32 2, i32* %b4, align 4
    %env = bitcast { i32 }* %clsr_two to i8*
    %envptr = getelementptr inbounds %closure, %closure* %two, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %clstmp = alloca %closure, align 8
    %funptr15 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i32 ()* @one to i8*), i8** %funptr15, align 8
    %envptr2 = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr2, align 8
    %0 = call i32 @add(%closure* %clstmp, %closure* %two)
    call void @printi(i32 %0)
    ret i32 0
  }
  3

Functions can be generic. In this test, we generate 'apply' only once and use it with
3 different functions with different types
  $ schmu -dump-llvm generic_fun_arg.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t_int = type { i32 }
  %closure = type { i8*, i8* }
  %t_bool = type { i1 }
  
  declare void @printi(i32 %0)
  
  define private i32 @__fun1(i32 %x) {
  entry:
    ret i32 %x
  }
  
  define private void @__g.g___fun0_ti.ti(%t_int* sret %0, %t_int* %x) {
  entry:
    %1 = bitcast %t_int* %0 to i8*
    %2 = bitcast %t_int* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 4, i1 false)
    ret void
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
  
  define private void @__gg.g.g_apply_tbtb.tb.tb(%t_bool* sret %0, %t_bool* %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t_bool*, %t_bool*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_bool, align 8
    call void %casttmp(%t_bool* %ret, %t_bool* %x, i8* %loadtmp1)
    %1 = bitcast %t_bool* %0 to i8*
    %2 = bitcast %t_bool* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 1, i1 false)
    ret void
  }
  
  define private void @__gg.g.g_apply_titi.ti.ti(%t_int* sret %0, %t_int* %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t_int*, %t_int*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    call void %casttmp(%t_int* %ret, %t_int* %x, i8* %loadtmp1)
    %1 = bitcast %t_int* %0 to i8*
    %2 = bitcast %t_int* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 4, i1 false)
    ret void
  }
  
  define private i32 @__gg.g.g_apply_ii.i.i(i32 %x, %closure* %f) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i32 %casttmp(i32 %x, i8* %loadtmp1)
    ret i32 %0
  }
  
  define private void @add3_rec(%t_int* sret %0, %t_int* %t) {
  entry:
    %x1 = bitcast %t_int* %0 to i32*
    %1 = bitcast %t_int* %t to i32*
    %2 = load i32, i32* %1, align 4
    %addtmp = add i32 %2, 3
    store i32 %addtmp, i32* %x1, align 4
    ret void
  }
  
  define private void @make_rec_false(%t_bool* sret %0, %t_bool* %r) {
  entry:
    %1 = bitcast %t_bool* %r to i1*
    %2 = load i1, i1* %1, align 1
    br i1 %2, label %then, label %else
  
  then:                                             ; preds = %entry
    %x1 = bitcast %t_bool* %0 to i1*
    store i1 false, i1* %x1, align 1
    ret void
  
  else:                                             ; preds = %entry
    %3 = bitcast %t_bool* %0 to i8*
    %4 = bitcast %t_bool* %r to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 1, i1 false)
    ret void
  }
  
  define private i1 @makefalse(i1 %b) {
  entry:
    ret i1 false
  }
  
  define private void @print_bool(i1 %b) {
  entry:
    br i1 %b, label %then, label %else
  
  then:                                             ; preds = %entry
    tail call void @printi(i32 1)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @printi(i32 0)
    ret void
  }
  
  define private i32 @add1(i32 %x) {
  entry:
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
  }
  
  define private i32 @add_closed(i32 %x, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i32 }*
    %a2 = bitcast { i32 }* %clsr to i32*
    %a1 = load i32, i32* %a2, align 4
    %addtmp = add i32 %x, %a1
    ret i32 %addtmp
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %add_closed = alloca %closure, align 8
    %funptr16 = bitcast %closure* %add_closed to i8**
    store i8* bitcast (i32 (i32, i8*)* @add_closed to i8*), i8** %funptr16, align 8
    %clsr_add_closed = alloca { i32 }, align 8
    %a17 = bitcast { i32 }* %clsr_add_closed to i32*
    store i32 2, i32* %a17, align 4
    %env = bitcast { i32 }* %clsr_add_closed to i8*
    %envptr = getelementptr inbounds %closure, %closure* %add_closed, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %clstmp = alloca %closure, align 8
    %funptr118 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr118, align 8
    %envptr2 = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr2, align 8
    %0 = call i32 @__gg.g.g_apply_ii.i.i(i32 20, %closure* %clstmp)
    call void @printi(i32 %0)
    %1 = call i32 @__gg.g.g_apply_ii.i.i(i32 20, %closure* %add_closed)
    call void @printi(i32 %1)
    %2 = alloca %t_int, align 8
    %x19 = bitcast %t_int* %2 to i32*
    store i32 20, i32* %x19, align 4
    %clstmp3 = alloca %closure, align 8
    %funptr420 = bitcast %closure* %clstmp3 to i8**
    store i8* bitcast (void (%t_int*, %t_int*)* @add3_rec to i8*), i8** %funptr420, align 8
    %envptr5 = getelementptr inbounds %closure, %closure* %clstmp3, i32 0, i32 1
    store i8* null, i8** %envptr5, align 8
    %ret = alloca %t_int, align 8
    call void @__gg.g.g_apply_titi.ti.ti(%t_int* %ret, %t_int* %2, %closure* %clstmp3)
    %3 = bitcast %t_int* %ret to i32*
    %4 = load i32, i32* %3, align 4
    call void @printi(i32 %4)
    %5 = alloca %t_bool, align 8
    %x621 = bitcast %t_bool* %5 to i1*
    store i1 true, i1* %x621, align 1
    %clstmp7 = alloca %closure, align 8
    %funptr822 = bitcast %closure* %clstmp7 to i8**
    store i8* bitcast (void (%t_bool*, %t_bool*)* @make_rec_false to i8*), i8** %funptr822, align 8
    %envptr9 = getelementptr inbounds %closure, %closure* %clstmp7, i32 0, i32 1
    store i8* null, i8** %envptr9, align 8
    %ret10 = alloca %t_bool, align 8
    call void @__gg.g.g_apply_tbtb.tb.tb(%t_bool* %ret10, %t_bool* %5, %closure* %clstmp7)
    %6 = bitcast %t_bool* %ret10 to i1*
    %7 = load i1, i1* %6, align 1
    call void @print_bool(i1 %7)
    %clstmp11 = alloca %closure, align 8
    %funptr1223 = bitcast %closure* %clstmp11 to i8**
    store i8* bitcast (i1 (i1)* @makefalse to i8*), i8** %funptr1223, align 8
    %envptr13 = getelementptr inbounds %closure, %closure* %clstmp11, i32 0, i32 1
    store i8* null, i8** %envptr13, align 8
    %8 = call i1 @__gg.g.g_apply_bb.b.b(i1 true, %closure* %clstmp11)
    call void @print_bool(i1 %8)
    %9 = alloca %t_int, align 8
    %x1424 = bitcast %t_int* %9 to i32*
    store i32 17, i32* %x1424, align 4
    %ret15 = alloca %t_int, align 8
    call void @__g.g___fun0_ti.ti(%t_int* %ret15, %t_int* %9)
    %10 = bitcast %t_int* %ret15 to i32*
    %11 = load i32, i32* %10, align 4
    call void @printi(i32 %11)
    %12 = call i32 @__fun1(i32 18)
    call void @printi(i32 %12)
    ret i32 0
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
  $ schmu -dump-llvm generic_pass.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t = type { i32, i1 }
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private void @__g.g_pass_t.t(%t* sret %0, %t* %x) {
  entry:
    %1 = bitcast %t* %0 to i8*
    %2 = bitcast %t* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    ret void
  }
  
  define private void @__g.gg.g_apply_t.tt.t(%t* sret %0, %closure* %f, %t* %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t*, %t*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t, align 8
    call void %casttmp(%t* %ret, %t* %x, i8* %loadtmp1)
    %1 = bitcast %t* %0 to i8*
    %2 = bitcast %t* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    ret void
  }
  
  define private i32 @__g.g_pass_i.i(i32 %x) {
  entry:
    ret i32 %x
  }
  
  define private i32 @__g.gg.g_apply_i.ii.i(%closure* %f, i32 %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = tail call i32 %casttmp(i32 %x, i8* %loadtmp1)
    ret i32 %0
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr4 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i32 (i32)* @__g.g_pass_i.i to i8*), i8** %funptr4, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %0 = call i32 @__g.gg.g_apply_i.ii.i(%closure* %clstmp, i32 20)
    call void @printi(i32 %0)
    %clstmp1 = alloca %closure, align 8
    %funptr25 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (void (%t*, %t*)* @__g.g_pass_t.t to i8*), i8** %funptr25, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %1 = alloca %t, align 8
    %i6 = bitcast %t* %1 to i32*
    store i32 700, i32* %i6, align 4
    %b = getelementptr inbounds %t, %t* %1, i32 0, i32 1
    store i1 false, i1* %b, align 1
    %ret = alloca %t, align 8
    call void @__g.gg.g_apply_t.tt.t(%t* %ret, %closure* %clstmp1, %t* %1)
    %2 = bitcast %t* %ret to i32*
    %3 = load i32, i32* %2, align 4
    call void @printi(i32 %3)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  20
  700


This is a regression test. The 'add1' function was not marked as a closure when being called from
a second function. Instead, the closure struct was being created again and the code segfaulted
  $ schmu -dump-llvm indirect_closure.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t_int = type { i32 }
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private void @__ggg.g.gg.g.g_apply2_titii.i.tii.i.ti(%t_int* sret %0, %t_int* %x, %closure* %f, %closure* %env) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t_int*, %t_int*, %closure*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    call void %casttmp(%t_int* %ret, %t_int* %x, %closure* %env, i8* %loadtmp1)
    %1 = bitcast %t_int* %0 to i8*
    %2 = bitcast %t_int* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 4, i1 false)
    ret void
  }
  
  define private void @__tgg.g.tg_boxed2int_int_tii.i.ti(%t_int* sret %0, %t_int* %t, %closure* %env) {
  entry:
    %1 = bitcast %t_int* %t to i32*
    %2 = load i32, i32* %1, align 4
    %funcptr2 = bitcast %closure* %env to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %env, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %3 = tail call i32 %casttmp(i32 %2, i8* %loadtmp1)
    %x3 = bitcast %t_int* %0 to i32*
    store i32 %3, i32* %x3, align 4
    ret void
  }
  
  define private void @__ggg.gg.g_apply_titii.i.tii.i.ti(%t_int* sret %0, %t_int* %x, %closure* %f, %closure* %env) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t_int*, %t_int*, %closure*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    call void %casttmp(%t_int* %ret, %t_int* %x, %closure* %env, i8* %loadtmp1)
    %1 = bitcast %t_int* %0 to i8*
    %2 = bitcast %t_int* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 4, i1 false)
    ret void
  }
  
  define private i32 @add1(i32 %x) {
  entry:
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %t_int, align 8
    %x12 = bitcast %t_int* %0 to i32*
    store i32 15, i32* %x12, align 4
    %clstmp = alloca %closure, align 8
    %funptr13 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%t_int*, %t_int*, %closure*)* @__tgg.g.tg_boxed2int_int_tii.i.ti to i8*), i8** %funptr13, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca %closure, align 8
    %funptr214 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr214, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %ret = alloca %t_int, align 8
    call void @__ggg.gg.g_apply_titii.i.tii.i.ti(%t_int* %ret, %t_int* %0, %closure* %clstmp, %closure* %clstmp1)
    %1 = bitcast %t_int* %ret to i32*
    %2 = load i32, i32* %1, align 4
    call void @printi(i32 %2)
    %3 = alloca %t_int, align 8
    %x415 = bitcast %t_int* %3 to i32*
    store i32 15, i32* %x415, align 4
    %clstmp5 = alloca %closure, align 8
    %funptr616 = bitcast %closure* %clstmp5 to i8**
    store i8* bitcast (void (%t_int*, %t_int*, %closure*)* @__tgg.g.tg_boxed2int_int_tii.i.ti to i8*), i8** %funptr616, align 8
    %envptr7 = getelementptr inbounds %closure, %closure* %clstmp5, i32 0, i32 1
    store i8* null, i8** %envptr7, align 8
    %clstmp8 = alloca %closure, align 8
    %funptr917 = bitcast %closure* %clstmp8 to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr917, align 8
    %envptr10 = getelementptr inbounds %closure, %closure* %clstmp8, i32 0, i32 1
    store i8* null, i8** %envptr10, align 8
    %ret11 = alloca %t_int, align 8
    call void @__ggg.g.gg.g.g_apply2_titii.i.tii.i.ti(%t_int* %ret11, %t_int* %3, %closure* %clstmp5, %closure* %clstmp8)
    %4 = bitcast %t_int* %ret11 to i32*
    %5 = load i32, i32* %4, align 4
    call void @printi(i32 %5)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  16
  16

Closures can recurse too
  $ schmu -dump-llvm recursive_closure.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private void @loop(i32 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i32 }*
    %outer4 = bitcast { i32 }* %clsr to i32*
    %outer1 = load i32, i32* %outer4, align 4
    %1 = alloca i32, align 4
    store i32 %i, i32* %1, align 4
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %i2 = phi i32 [ %addtmp, %then ], [ %i, %entry ]
    %lesstmp = icmp slt i32 %i2, %outer1
    br i1 %lesstmp, label %then, label %else
  
  then:                                             ; preds = %rec
    tail call void @printi(i32 %i2)
    %addtmp = add i32 %i2, 1
    store i32 %addtmp, i32* %1, align 4
    br label %rec
  
  else:                                             ; preds = %rec
    tail call void @printi(i32 %i2)
    ret void
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %loop = alloca %closure, align 8
    %funptr3 = bitcast %closure* %loop to i8**
    store i8* bitcast (void (i32, i8*)* @loop to i8*), i8** %funptr3, align 8
    %clsr_loop = alloca { i32 }, align 8
    %outer4 = bitcast { i32 }* %clsr_loop to i32*
    store i32 10, i32* %outer4, align 4
    %env = bitcast { i32 }* %clsr_loop to i8*
    %envptr = getelementptr inbounds %closure, %closure* %loop, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @loop(i32 0, i8* %env)
    ret i32 0
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
  
  %first = type { i32 }
  %second = type { i32 }
  
  declare void @dummy_call(%first* %0)
  
  declare void @print_2nd(%second* %0)
  
  define i32 @main(i32 %arg) {
  entry:
    ret i32 0
  }

Support monomorphization of nested functions
  $ schmu -dump-llvm monomorph_nested.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %rec = type { i32 }
  
  declare void @printi(i32 %0)
  
  define private void @__g.g_wrapped_rec.rec(%rec* sret %0, %rec* %x) {
  entry:
    %ret = alloca %rec, align 8
    call void @__g.g_id_rec.rec(%rec* %ret, %rec* %x)
    %1 = bitcast %rec* %0 to i8*
    %2 = bitcast %rec* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 4, i1 false)
    ret void
  }
  
  define private void @__g.g_id_rec.rec(%rec* sret %0, %rec* %x) {
  entry:
    %1 = bitcast %rec* %0 to i8*
    %2 = bitcast %rec* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 4, i1 false)
    ret void
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
  
  define private i32 @__g.g_wrapped_i.i(i32 %x) {
  entry:
    %0 = tail call i32 @__g.g_id_i.i(i32 %x)
    ret i32 %0
  }
  
  define private i32 @__g.g_id_i.i(i32 %x) {
  entry:
    ret i32 %x
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = tail call i32 @__g.g_wrapped_i.i(i32 12)
    tail call void @printi(i32 %0)
    %1 = tail call i1 @__g.g_wrapped_b.b(i1 false)
    %2 = alloca %rec, align 8
    %x1 = bitcast %rec* %2 to i32*
    store i32 24, i32* %x1, align 4
    %ret = alloca %rec, align 8
    call void @__g.g_wrapped_rec.rec(%rec* %ret, %rec* %2)
    %3 = bitcast %rec* %ret to i32*
    %4 = load i32, i32* %3, align 4
    call void @printi(i32 %4)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  12
  24

Nested polymorphic closures. Does not quite work for another nesting level
  $ schmu -dump-llvm nested_polymorphic_closures.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { i32*, i32, i32 }
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private void @__fun0(i32 %x) {
  entry:
    %multmp = mul i32 %x, 2
    tail call void @printi(i32 %multmp)
    ret void
  }
  
  define private void @__vectorgg.u.u_vector_iter_vectorii.u.u(%vector_int* %vec, %closure* %f) {
  entry:
    %monoclstmp = alloca %closure, align 8
    %funptr27 = bitcast %closure* %monoclstmp to i8**
    store i8* bitcast (void (i32, i8*)* @__i.u_inner_cls_both_i.u to i8*), i8** %funptr27, align 8
    %clsr_monoclstmp = alloca { %closure*, %vector_int }, align 8
    %f128 = bitcast { %closure*, %vector_int }* %clsr_monoclstmp to %closure**
    store %closure* %f, %closure** %f128, align 8
    %vec2 = getelementptr inbounds { %closure*, %vector_int }, { %closure*, %vector_int }* %clsr_monoclstmp, i32 0, i32 1
    %0 = bitcast %vector_int* %vec2 to i8*
    %1 = bitcast %vector_int* %vec to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %env = bitcast { %closure*, %vector_int }* %clsr_monoclstmp to i8*
    %envptr = getelementptr inbounds %closure, %closure* %monoclstmp, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__i.u_inner_cls_both_i.u(i32 0, i8* %env)
    %monoclstmp5 = alloca %closure, align 8
    %funptr629 = bitcast %closure* %monoclstmp5 to i8**
    store i8* bitcast (void (i32, %closure*, i8*)* @__ig.u.u_inner_cls_vec_ii.u.u to i8*), i8** %funptr629, align 8
    %clsr_monoclstmp7 = alloca { %vector_int }, align 8
    %vec830 = bitcast { %vector_int }* %clsr_monoclstmp7 to %vector_int*
    %2 = bitcast %vector_int* %vec830 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %1, i64 16, i1 false)
    %env9 = bitcast { %vector_int }* %clsr_monoclstmp7 to i8*
    %envptr10 = getelementptr inbounds %closure, %closure* %monoclstmp5, i32 0, i32 1
    store i8* %env9, i8** %envptr10, align 8
    call void @__ig.u.u_inner_cls_vec_ii.u.u(i32 0, %closure* %f, i8* %env9)
    %monoclstmp16 = alloca %closure, align 8
    %funptr1731 = bitcast %closure* %monoclstmp16 to i8**
    store i8* bitcast (void (i32, %vector_int*, i8*)* @__ivectorg.u_inner_cls_f_ivectori.u to i8*), i8** %funptr1731, align 8
    %clsr_monoclstmp18 = alloca { %closure* }, align 8
    %f1932 = bitcast { %closure* }* %clsr_monoclstmp18 to %closure**
    store %closure* %f, %closure** %f1932, align 8
    %env20 = bitcast { %closure* }* %clsr_monoclstmp18 to i8*
    %envptr21 = getelementptr inbounds %closure, %closure* %monoclstmp16, i32 0, i32 1
    store i8* %env20, i8** %envptr21, align 8
    call void @__ivectorg.u_inner_cls_f_ivectori.u(i32 0, %vector_int* %vec, i8* %env20)
    ret void
  }
  
  define private void @__ivectorg.u_inner_cls_f_ivectori.u(i32 %i, %vector_int* %vec, i8* %0) {
  entry:
    br label %tailrecurse
  
  tailrecurse:                                      ; preds = %else, %entry
    %i.tr = phi i32 [ %i, %entry ], [ %addtmp, %else ]
    %clsr = bitcast i8* %0 to { %closure* }*
    %f3 = bitcast { %closure* }* %clsr to %closure**
    %f1 = load %closure*, %closure** %f3, align 8
    %1 = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    %2 = load i32, i32* %1, align 4
    %eqtmp = icmp eq i32 %i.tr, %2
    br i1 %eqtmp, label %then, label %else
  
  then:                                             ; preds = %tailrecurse
    ret void
  
  else:                                             ; preds = %tailrecurse
    %3 = bitcast %vector_int* %vec to i32**
    %4 = load i32*, i32** %3, align 8
    %5 = getelementptr inbounds i32, i32* %4, i32 %i.tr
    %6 = load i32, i32* %5, align 4
    %funcptr4 = bitcast %closure* %f1 to i8**
    %loadtmp = load i8*, i8** %funcptr4, align 8
    %casttmp = bitcast i8* %loadtmp to void (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f1, i32 0, i32 1
    %loadtmp2 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i32 %6, i8* %loadtmp2)
    %addtmp = add i32 %i.tr, 1
    br label %tailrecurse
  }
  
  define private void @__ig.u.u_inner_cls_vec_ii.u.u(i32 %i, %closure* %f, i8* %0) {
  entry:
    br label %tailrecurse
  
  tailrecurse:                                      ; preds = %else, %entry
    %i.tr = phi i32 [ %i, %entry ], [ %addtmp, %else ]
    %clsr = bitcast i8* %0 to { %vector_int }*
    %vec2 = bitcast { %vector_int }* %clsr to %vector_int*
    %1 = getelementptr inbounds %vector_int, %vector_int* %vec2, i32 0, i32 1
    %2 = load i32, i32* %1, align 4
    %eqtmp = icmp eq i32 %i.tr, %2
    br i1 %eqtmp, label %then, label %else
  
  then:                                             ; preds = %tailrecurse
    ret void
  
  else:                                             ; preds = %tailrecurse
    %3 = bitcast i8* %0 to i32**
    %4 = load i32*, i32** %3, align 8
    %5 = getelementptr inbounds i32, i32* %4, i32 %i.tr
    %6 = load i32, i32* %5, align 4
    %funcptr3 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to void (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i32 %6, i8* %loadtmp1)
    %addtmp = add i32 %i.tr, 1
    br label %tailrecurse
  }
  
  define private void @__i.u_inner_cls_both_i.u(i32 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %closure*, %vector_int }*
    %f5 = bitcast { %closure*, %vector_int }* %clsr to %closure**
    %f1 = load %closure*, %closure** %f5, align 8
    %1 = alloca i32, align 4
    store i32 %i, i32* %1, align 4
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %i2 = phi i32 [ %addtmp, %else ], [ %i, %entry ]
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %2 = bitcast i8* %sunkaddr to i32*
    %3 = load i32, i32* %2, align 4
    %eqtmp = icmp eq i32 %i2, %3
    br i1 %eqtmp, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr6 = getelementptr inbounds i8, i8* %0, i64 8
    %4 = bitcast i8* %sunkaddr6 to i32**
    %5 = load i32*, i32** %4, align 8
    %6 = getelementptr inbounds i32, i32* %5, i32 %i2
    %7 = load i32, i32* %6, align 4
    %funcptr7 = bitcast %closure* %f1 to i8**
    %loadtmp = load i8*, i8** %funcptr7, align 8
    %casttmp = bitcast i8* %loadtmp to void (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f1, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i32 %7, i8* %loadtmp3)
    %addtmp = add i32 %i2, 1
    store i32 %addtmp, i32* %1, align 4
    br label %rec
  }
  
  define private void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i32 %val) {
  entry:
    %0 = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    %1 = load i32, i32* %0, align 4
    %2 = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 2
    %3 = load i32, i32* %2, align 4
    %lesstmp = icmp slt i32 %1, %3
    br i1 %lesstmp, label %then, label %else
  
  then:                                             ; preds = %entry
    %4 = bitcast %vector_int* %vec to i32**
    %5 = load i32*, i32** %4, align 8
    %6 = getelementptr inbounds i32, i32* %5, i32 %1
    store i32 %val, i32* %6, align 4
    %7 = bitcast %vector_int* %vec to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %7, i64 8
    %8 = bitcast i8* %sunkaddr to i32*
    %9 = load i32, i32* %8, align 4
    %addtmp = add i32 %9, 1
    store i32 %addtmp, i32* %8, align 4
    br label %ifcont
  
  else:                                             ; preds = %entry
    %multmp = mul i32 %3, 2
    %10 = bitcast %vector_int* %vec to i32**
    %11 = load i32*, i32** %10, align 8
    %12 = mul i32 %multmp, 4
    %13 = bitcast i32* %11 to i8*
    %14 = tail call i8* @realloc(i8* %13, i32 %12)
    %15 = bitcast i8* %14 to i32*
    store i32* %15, i32** %10, align 8
    %16 = bitcast %vector_int* %vec to i8*
    %sunkaddr2 = getelementptr inbounds i8, i8* %16, i64 12
    %17 = bitcast i8* %sunkaddr2 to i32*
    store i32 %multmp, i32* %17, align 4
    %18 = bitcast %vector_int* %vec to i8*
    %sunkaddr3 = getelementptr inbounds i8, i8* %18, i64 8
    %19 = bitcast i8* %sunkaddr3 to i32*
    %20 = load i32, i32* %19, align 4
    %21 = getelementptr inbounds i32, i32* %15, i32 %20
    store i32 %val, i32* %21, align 4
    %22 = load i32, i32* %19, align 4
    %addtmp1 = add i32 %22, 1
    store i32 %addtmp1, i32* %19, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i8* @realloc(i8* %0, i32 %1)
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = tail call i8* @malloc(i32 4)
    %1 = bitcast i8* %0 to i32*
    %vec = alloca %vector_int, align 8
    %data1 = bitcast %vector_int* %vec to i32**
    store i32* %1, i32** %data1, align 8
    %len = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i32 0, i32* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 2
    store i32 1, i32* %cap, align 4
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i32 1)
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i32 2)
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i32 3)
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i32 4)
    call void @__vectorgg.u_vector_push_vectorii.u(%vector_int* %vec, i32 5)
    %clstmp = alloca %closure, align 8
    %funptr2 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i32)* @__fun0 to i8*), i8** %funptr2, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @__vectorgg.u.u_vector_iter_vectorii.u.u(%vector_int* %vec, %closure* %clstmp)
    %2 = load i32*, i32** %data1, align 8
    %3 = bitcast i32* %2 to i8*
    call void @free(i8* %3)
    ret i32 0
  }
  
  declare i8* @malloc(i32 %0)
  
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
