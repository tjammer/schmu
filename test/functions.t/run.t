Compile stubs
  $ cc -c stub.c

Test name resolution and IR creation of functions
We discard the triple, b/c it varies from distro to distro
e.g. x86_64-unknown-linux-gnu on Fedora vs x86_64-pc-linux-gnu on gentoo

Simple fibonacci
  $ dune exec -- schmu fib.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
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
  
  define i32 @main(i32 %0) {
  entry:
    %1 = tail call i32 @fib(i32 30)
    tail call void @printi(i32 %1)
    ret i32 0
  }
  unit
  832040

Fibonacci, but we shadow a bunch
  $ dune exec -- schmu shadowing.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
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
  
  define i32 @main(i32 %0) {
  entry:
    %1 = tail call i32 @fib(i32 30)
    tail call void @printi(i32 %1)
    ret i32 0
  }
  unit
  832040

Multiple parameters
  $ dune exec -- schmu multi_params.smu | grep -v x86_64 && cc out.o && ./a.out
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
  
  define i32 @main(i32 %0) {
  entry:
    %1 = tail call i32 @one()
    %2 = tail call i32 @add(i32 %1, i32 1)
    %3 = tail call i32 @doiflesselse(i32 %2, i32 0, i32 1, i32 2)
    ret i32 %3
  }
  int
  [1]

We have downwards closures
  $ dune exec -- schmu closure.smu | grep -v x86_64 && cc out.o && ./a.out
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
  
  define i32 @main(i32 %0) {
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
    %1 = call i32 @capture_a(i8* %env)
    ret i32 %1
  }
  int
  [12]

First class functions
  $ dune exec -- schmu first_class.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %generic = type opaque
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private i32 @__fun0(i32 %x) {
  entry:
    %addtmp = add i32 %x, 2
    ret i32 %addtmp
  }
  
  define void @__ig_ig(%generic* %0, %generic* %1, i64 %2, i64 %3, i8* %4) {
  entry:
    %5 = bitcast i8* %4 to %closure*
    %6 = bitcast %generic* %1 to i32*
    %7 = load i32, i32* %6, align 4
    %funcptr2 = bitcast %closure* %5 to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %5, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %8 = call i32 %casttmp(i32 %7, i8* %loadtmp1)
    %9 = bitcast %generic* %0 to i32*
    store i32 %8, i32* %9, align 4
    ret void
  }
  
  define private i32 @add1(i32 %x) {
  entry:
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
  }
  
  define private void @apply(%generic* %0, %generic* %x, %closure* %f, i64 %__3, i64 %__1) {
  entry:
    %funcptr3 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to void (%generic*, %generic*, i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca i8, i64 %__3, align 16
    %ret2 = bitcast i8* %ret to %generic*
    call void %casttmp(%generic* %ret2, %generic* %x, i64 %__3, i64 %__1, i8* %loadtmp1)
    %1 = bitcast %generic* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %ret, i64 %__3, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %0) {
  entry:
    %gen = alloca i32, align 4
    store i32 1, i32* %gen, align 4
    %1 = bitcast i32* %gen to %generic*
    %clstmp = alloca %closure, align 8
    %funptr14 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%generic*, %generic*, i64, i64, i8*)* @__ig_ig to i8*), i8** %funptr14, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    %wrapped = alloca %closure, align 8
    %funptr115 = bitcast %closure* %wrapped to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr115, align 8
    %envptr2 = getelementptr inbounds %closure, %closure* %wrapped, i32 0, i32 1
    store i8* null, i8** %envptr2, align 8
    %2 = bitcast %closure* %wrapped to i8*
    store i8* %2, i8** %envptr, align 8
    %ret = alloca i8, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), align 16
    %ret3 = bitcast i8* %ret to %generic*
    call void @apply(%generic* %ret3, %generic* %1, %closure* %clstmp, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64))
    %3 = bitcast %generic* %ret3 to i32*
    %realret = load i32, i32* %3, align 4
    call void @printi(i32 %realret)
    %gen4 = alloca i32, align 4
    store i32 1, i32* %gen4, align 4
    %4 = bitcast i32* %gen4 to %generic*
    %clstmp5 = alloca %closure, align 8
    %funptr616 = bitcast %closure* %clstmp5 to i8**
    store i8* bitcast (void (%generic*, %generic*, i64, i64, i8*)* @__ig_ig to i8*), i8** %funptr616, align 8
    %envptr7 = getelementptr inbounds %closure, %closure* %clstmp5, i32 0, i32 1
    %wrapped8 = alloca %closure, align 8
    %funptr917 = bitcast %closure* %wrapped8 to i8**
    store i8* bitcast (i32 (i32)* @__fun0 to i8*), i8** %funptr917, align 8
    %envptr10 = getelementptr inbounds %closure, %closure* %wrapped8, i32 0, i32 1
    store i8* null, i8** %envptr10, align 8
    %5 = bitcast %closure* %wrapped8 to i8*
    store i8* %5, i8** %envptr7, align 8
    %ret11 = alloca i8, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), align 16
    %ret12 = bitcast i8* %ret11 to %generic*
    call void @apply(%generic* %ret12, %generic* %4, %closure* %clstmp5, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64))
    %6 = bitcast %generic* %ret12 to i32*
    %realret13 = load i32, i32* %6, align 4
    call void @printi(i32 %realret13)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  2
  3

We don't allow returning closures
  $ dune exec -- schmu no_closure_returns.smu
  no_closure_returns.smu:3:1: error: Cannot (yet) return a closure

Don't try to create 'void' value in if
  $ dune exec -- schmu if_return_void.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i32 %0)
  
  define private void @foo(i32 %i) {
  entry:
    br label %tailrecurse
  
  tailrecurse:                                      ; preds = %ifcont, %entry
    %i.tr = phi i32 [ %i, %entry ], [ %subtmp4, %ifcont ]
    %lesstmp = icmp slt i32 %i.tr, 2
    br i1 %lesstmp, label %then, label %else
  
  then:                                             ; preds = %tailrecurse
    %0 = add i32 %i.tr, -1
    tail call void @printi(i32 %0)
    ret void
  
  else:                                             ; preds = %tailrecurse
    %lesstmp1 = icmp slt i32 %i.tr, 400
    br i1 %lesstmp1, label %then2, label %else3
  
  then2:                                            ; preds = %else
    tail call void @printi(i32 %i.tr)
    br label %ifcont
  
  else3:                                            ; preds = %else
    %addtmp = add i32 %i.tr, 1
    tail call void @printi(i32 %addtmp)
    br label %ifcont
  
  ifcont:                                           ; preds = %else3, %then2
    %subtmp4 = sub i32 %i.tr, 1
    br label %tailrecurse
  }
  
  define i32 @main(i32 %0) {
  entry:
    tail call void @foo(i32 4)
    ret i32 0
  }
  unit
  4
  3
  2
  0

Captured values should not overwrite function params
  $ dune exec -- schmu overwrite_params.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
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
  
  define i32 @main(i32 %0) {
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
    %1 = call i32 @add(%closure* %clstmp, %closure* %two)
    call void @printi(i32 %1)
    ret i32 0
  }
  unit
  3

Functions can be generic. In this test, we generate 'apply' only once and use it with
3 different functions with different types
  $ dune exec -- schmu generic_fun_arg.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %generic = type opaque
  %closure = type { i8*, i8* }
  %t = type { i32 }
  
  declare void @printi(i32 %0)
  
  define void @__bg_bg(%generic* %0, %generic* %1, i64 %2, i64 %3, i8* %4) {
  entry:
    %5 = bitcast i8* %4 to %closure*
    %6 = bitcast %generic* %1 to i1*
    %7 = load i1, i1* %6, align 1
    %funcptr2 = bitcast %closure* %5 to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i1 (i1, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %5, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %8 = call i1 %casttmp(i1 %7, i8* %loadtmp1)
    %9 = bitcast %generic* %0 to i1*
    store i1 %8, i1* %9, align 1
    ret void
  }
  
  define void @__tg_tg(%generic* %0, %generic* %1, i64 %2, i64 %3, i8* %4) {
  entry:
    %5 = bitcast i8* %4 to %closure*
    %6 = bitcast %generic* %1 to %t*
    %funcptr2 = bitcast %closure* %5 to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t*, %t*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %5, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t, align 8
    call void %casttmp(%t* %ret, %t* %6, i8* %loadtmp1)
    %7 = bitcast %generic* %0 to i8*
    %8 = bitcast %t* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* %8, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), i1 false)
    ret void
  }
  
  define void @__ig_ig(%generic* %0, %generic* %1, i64 %2, i64 %3, i8* %4) {
  entry:
    %5 = bitcast i8* %4 to %closure*
    %6 = bitcast %generic* %1 to i32*
    %7 = load i32, i32* %6, align 4
    %funcptr2 = bitcast %closure* %5 to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %5, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %8 = call i32 %casttmp(i32 %7, i8* %loadtmp1)
    %9 = bitcast %generic* %0 to i32*
    store i32 %8, i32* %9, align 4
    ret void
  }
  
  define private void @add1_rec(%t* %0, %t* %t) {
  entry:
    %1 = alloca %t, align 8
    %x1 = bitcast %t* %1 to i32*
    %2 = bitcast %t* %t to i32*
    %3 = load i32, i32* %2, align 4
    %addtmp = add i32 %3, 3
    store i32 %addtmp, i32* %x1, align 4
    %4 = bitcast %t* %0 to i8*
    %5 = bitcast %t* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), i1 false)
    ret void
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
  
  define private i32 @add_closed(i32 %x, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i32 }*
    %a2 = bitcast { i32 }* %clsr to i32*
    %a1 = load i32, i32* %a2, align 4
    %addtmp = add i32 %x, %a1
    ret i32 %addtmp
  }
  
  define private void @apply(%generic* %0, %generic* %x, %closure* %f, i64 %__3, i64 %__1) {
  entry:
    %funcptr3 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to void (%generic*, %generic*, i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca i8, i64 %__3, align 16
    %ret2 = bitcast i8* %ret to %generic*
    call void %casttmp(%generic* %ret2, %generic* %x, i64 %__3, i64 %__1, i8* %loadtmp1)
    %1 = bitcast %generic* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %ret, i64 %__3, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %0) {
  entry:
    %add_closed = alloca %closure, align 8
    %funptr31 = bitcast %closure* %add_closed to i8**
    store i8* bitcast (i32 (i32, i8*)* @add_closed to i8*), i8** %funptr31, align 8
    %clsr_add_closed = alloca { i32 }, align 8
    %a32 = bitcast { i32 }* %clsr_add_closed to i32*
    store i32 2, i32* %a32, align 4
    %env = bitcast { i32 }* %clsr_add_closed to i8*
    %envptr = getelementptr inbounds %closure, %closure* %add_closed, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %gen = alloca i32, align 4
    store i32 20, i32* %gen, align 4
    %1 = bitcast i32* %gen to %generic*
    %clstmp = alloca %closure, align 8
    %funptr133 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%generic*, %generic*, i64, i64, i8*)* @__ig_ig to i8*), i8** %funptr133, align 8
    %envptr2 = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    %wrapped = alloca %closure, align 8
    %funptr334 = bitcast %closure* %wrapped to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr334, align 8
    %envptr4 = getelementptr inbounds %closure, %closure* %wrapped, i32 0, i32 1
    store i8* null, i8** %envptr4, align 8
    %2 = bitcast %closure* %wrapped to i8*
    store i8* %2, i8** %envptr2, align 8
    %ret = alloca i8, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), align 16
    %ret5 = bitcast i8* %ret to %generic*
    call void @apply(%generic* %ret5, %generic* %1, %closure* %clstmp, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64))
    %3 = bitcast %generic* %ret5 to i32*
    %realret = load i32, i32* %3, align 4
    call void @printi(i32 %realret)
    %gen6 = alloca i32, align 4
    store i32 20, i32* %gen6, align 4
    %4 = bitcast i32* %gen6 to %generic*
    %clstmp7 = alloca %closure, align 8
    %funptr835 = bitcast %closure* %clstmp7 to i8**
    store i8* bitcast (void (%generic*, %generic*, i64, i64, i8*)* @__ig_ig to i8*), i8** %funptr835, align 8
    %envptr9 = getelementptr inbounds %closure, %closure* %clstmp7, i32 0, i32 1
    %5 = bitcast %closure* %add_closed to i8*
    store i8* %5, i8** %envptr9, align 8
    %ret10 = alloca i8, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), align 16
    %ret11 = bitcast i8* %ret10 to %generic*
    call void @apply(%generic* %ret11, %generic* %4, %closure* %clstmp7, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64))
    %6 = bitcast %generic* %ret11 to i32*
    %realret12 = load i32, i32* %6, align 4
    call void @printi(i32 %realret12)
    %7 = alloca %t, align 8
    %x36 = bitcast %t* %7 to i32*
    store i32 20, i32* %x36, align 4
    %8 = bitcast %t* %7 to %generic*
    %clstmp13 = alloca %closure, align 8
    %funptr1437 = bitcast %closure* %clstmp13 to i8**
    store i8* bitcast (void (%generic*, %generic*, i64, i64, i8*)* @__tg_tg to i8*), i8** %funptr1437, align 8
    %envptr15 = getelementptr inbounds %closure, %closure* %clstmp13, i32 0, i32 1
    %wrapped16 = alloca %closure, align 8
    %funptr1738 = bitcast %closure* %wrapped16 to i8**
    store i8* bitcast (void (%t*, %t*)* @add1_rec to i8*), i8** %funptr1738, align 8
    %envptr18 = getelementptr inbounds %closure, %closure* %wrapped16, i32 0, i32 1
    store i8* null, i8** %envptr18, align 8
    %9 = bitcast %closure* %wrapped16 to i8*
    store i8* %9, i8** %envptr15, align 8
    %ret19 = alloca i8, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), align 16
    %ret20 = bitcast i8* %ret19 to %generic*
    call void @apply(%generic* %ret20, %generic* %8, %closure* %clstmp13, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64))
    %10 = bitcast %generic* %ret20 to %t*
    %11 = bitcast %t* %10 to i32*
    %12 = load i32, i32* %11, align 4
    call void @printi(i32 %12)
    %gen21 = alloca i1, align 1
    store i1 true, i1* %gen21, align 1
    %13 = bitcast i1* %gen21 to %generic*
    %clstmp22 = alloca %closure, align 8
    %funptr2339 = bitcast %closure* %clstmp22 to i8**
    store i8* bitcast (void (%generic*, %generic*, i64, i64, i8*)* @__bg_bg to i8*), i8** %funptr2339, align 8
    %envptr24 = getelementptr inbounds %closure, %closure* %clstmp22, i32 0, i32 1
    %wrapped25 = alloca %closure, align 8
    %funptr2640 = bitcast %closure* %wrapped25 to i8**
    store i8* bitcast (i1 (i1)* @makefalse to i8*), i8** %funptr2640, align 8
    %envptr27 = getelementptr inbounds %closure, %closure* %wrapped25, i32 0, i32 1
    store i8* null, i8** %envptr27, align 8
    %14 = bitcast %closure* %wrapped25 to i8*
    store i8* %14, i8** %envptr24, align 8
    %ret28 = alloca i8, i64 ptrtoint (i1* getelementptr (i1, i1* null, i32 1) to i64), align 16
    %ret29 = bitcast i8* %ret28 to %generic*
    call void @apply(%generic* %ret29, %generic* %13, %closure* %clstmp22, i64 ptrtoint (i1* getelementptr (i1, i1* null, i32 1) to i64), i64 ptrtoint (i1* getelementptr (i1, i1* null, i32 1) to i64))
    %15 = bitcast %generic* %ret29 to i1*
    %realret30 = load i1, i1* %15, align 1
    br i1 %realret30, label %then, label %else
  
  then:                                             ; preds = %entry
    call void @printi(i32 1)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @printi(i32 0)
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  21
  22
  23
  0

A generic pass function. This example is not 100% correct, but works due to calling convertion.
  $ dune exec -- schmu generic_pass.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %generic = type opaque
  %t = type { i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @apply(%generic* %0, %closure* %f, %generic* %x, i64 %__5, i64 %__4) {
  entry:
    %funcptr3 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to void (%generic*, %generic*, i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca i8, i64 %__5, align 16
    %ret2 = bitcast i8* %ret to %generic*
    call void %casttmp(%generic* %ret2, %generic* %x, i64 %__5, i64 %__4, i8* %loadtmp1)
    %1 = bitcast %generic* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %ret, i64 %__5, i1 false)
    ret void
  }
  
  define private void @pass(%generic* %0, %generic* %x, i64 %__1) {
  entry:
    %1 = bitcast %generic* %0 to i8*
    %2 = bitcast %generic* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 %__1, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %0) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr7 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%generic*, %generic*, i64)* @pass to i8*), i8** %funptr7, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %gen = alloca i32, align 4
    store i32 20, i32* %gen, align 4
    %1 = bitcast i32* %gen to %generic*
    %ret = alloca i8, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), align 16
    %ret1 = bitcast i8* %ret to %generic*
    call void @apply(%generic* %ret1, %closure* %clstmp, %generic* %1, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64))
    %2 = bitcast %generic* %ret1 to i32*
    %realret = load i32, i32* %2, align 4
    call void @printi(i32 %realret)
    %clstmp2 = alloca %closure, align 8
    %funptr38 = bitcast %closure* %clstmp2 to i8**
    store i8* bitcast (void (%generic*, %generic*, i64)* @pass to i8*), i8** %funptr38, align 8
    %envptr4 = getelementptr inbounds %closure, %closure* %clstmp2, i32 0, i32 1
    store i8* null, i8** %envptr4, align 8
    %3 = alloca %t, align 8
    %i9 = bitcast %t* %3 to i32*
    store i32 700, i32* %i9, align 4
    %b = getelementptr inbounds %t, %t* %3, i32 0, i32 1
    store i1 false, i1* %b, align 1
    %4 = bitcast %t* %3 to %generic*
    %ret5 = alloca i8, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), align 16
    %ret6 = bitcast i8* %ret5 to %generic*
    call void @apply(%generic* %ret6, %closure* %clstmp2, %generic* %4, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64))
    %5 = bitcast %generic* %ret6 to %t*
    %6 = bitcast %t* %5 to i32*
    %7 = load i32, i32* %6, align 4
    call void @printi(i32 %7)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  20
  700


This is a regression test. The 'add1' function was not marked as a closure when being called from
a second function. Instead, the closure struct was being created again and the code segfaulted
  $ dune exec -- schmu indirect_closure.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t = type { i32 }
  %generic = type opaque
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define void @__tg_tt_.i.i.g(%generic* %0, %t* %1, %generic* %2, i64 %3, i64 %4, i8* %5) {
  entry:
    %6 = bitcast i8* %5 to %closure*
    %7 = bitcast %generic* %2 to %closure*
    %funcptr2 = bitcast %closure* %6 to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t*, %t*, %closure*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %6, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t, align 8
    call void %casttmp(%t* %ret, %t* %1, %closure* %7, i8* %loadtmp1)
    %8 = bitcast %generic* %0 to i8*
    %9 = bitcast %t* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), i1 false)
    ret void
  }
  
  define private void @boxed2int_int(%t* %0, %t* %t, %closure* %env) {
  entry:
    %1 = bitcast %t* %t to i32*
    %2 = load i32, i32* %1, align 4
    %funcptr2 = bitcast %closure* %env to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %env, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %3 = tail call i32 %casttmp(i32 %2, i8* %loadtmp1)
    %4 = alloca %t, align 8
    %x3 = bitcast %t* %4 to i32*
    store i32 %3, i32* %x3, align 4
    %5 = bitcast %t* %0 to i8*
    %6 = bitcast %t* %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), i1 false)
    ret void
  }
  
  define private i32 @add1(i32 %x) {
  entry:
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
  }
  
  define private void @apply(%generic* %0, %t* %x, %closure* %f, %generic* %env, i64 %__3, i64 %__2) {
  entry:
    %funcptr3 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to void (%generic*, %t*, %generic*, i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca i8, i64 %__3, align 16
    %ret2 = bitcast i8* %ret to %generic*
    call void %casttmp(%generic* %ret2, %t* %x, %generic* %env, i64 %__3, i64 %__2, i8* %loadtmp1)
    %1 = bitcast %generic* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %ret, i64 %__3, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca %t, align 8
    %x7 = bitcast %t* %1 to i32*
    store i32 15, i32* %x7, align 4
    %clstmp = alloca %closure, align 8
    %funptr8 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%generic*, %t*, %generic*, i64, i64, i8*)* @__tg_tt_.i.i.g to i8*), i8** %funptr8, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    %wrapped = alloca %closure, align 8
    %funptr19 = bitcast %closure* %wrapped to i8**
    store i8* bitcast (void (%t*, %t*, %closure*)* @boxed2int_int to i8*), i8** %funptr19, align 8
    %envptr2 = getelementptr inbounds %closure, %closure* %wrapped, i32 0, i32 1
    store i8* null, i8** %envptr2, align 8
    %2 = bitcast %closure* %wrapped to i8*
    store i8* %2, i8** %envptr, align 8
    %clstmp3 = alloca %closure, align 8
    %funptr410 = bitcast %closure* %clstmp3 to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr410, align 8
    %envptr5 = getelementptr inbounds %closure, %closure* %clstmp3, i32 0, i32 1
    store i8* null, i8** %envptr5, align 8
    %3 = bitcast %closure* %clstmp3 to %generic*
    %ret = alloca i8, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), align 16
    %ret6 = bitcast i8* %ret to %generic*
    call void @apply(%generic* %ret6, %t* %1, %closure* %clstmp, %generic* %3, i64 ptrtoint (%t* getelementptr (%t, %t* null, i32 1) to i64), i64 ptrtoint (i32 (i32, i8*)** getelementptr (i32 (i32, i8*)*, i32 (i32, i8*)** null, i32 1) to i64))
    %4 = bitcast %generic* %ret6 to %t*
    %5 = bitcast %t* %4 to i32*
    %6 = load i32, i32* %5, align 4
    call void @printi(i32 %6)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  16

Closures can recurse too
  $ dune exec -- schmu recursive_closure.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private void @loop(i32 %i, i8* %0) {
  entry:
    br label %tailrecurse
  
  tailrecurse:                                      ; preds = %then, %entry
    %i.tr = phi i32 [ %i, %entry ], [ %addtmp, %then ]
    %clsr = bitcast i8* %0 to { i32 }*
    %outer2 = bitcast { i32 }* %clsr to i32*
    %outer1 = load i32, i32* %outer2, align 4
    %lesstmp = icmp slt i32 %i.tr, %outer1
    br i1 %lesstmp, label %then, label %else
  
  then:                                             ; preds = %tailrecurse
    tail call void @printi(i32 %i.tr)
    %addtmp = add i32 %i.tr, 1
    br label %tailrecurse
  
  else:                                             ; preds = %tailrecurse
    tail call void @printi(i32 %i.tr)
    ret void
  }
  
  define i32 @main(i32 %0) {
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
  unit
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
