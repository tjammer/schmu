Compile stubs
  $ cc -c stub.c

Test name resolution and IR creation of functions
We discard the triple, b/c it varies from distro to distro
e.g. x86_64-unknown-linux-gnu on Fedora vs x86_64-pc-linux-gnu on gentoo
  $ dune exec -- schmu fib.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i32 %0)
  
  define private i32 @fib(i32 %n) {
  entry:
    %lesstmp = icmp slt i32 %n, 2
    br i1 %lesstmp, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %0 = call i32 @fibn2(i32 %n)
    %1 = call i32 @__fun0(i32 %n)
    %addtmp = add i32 %0, %1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i32 [ %addtmp, %else ], [ %n, %entry ]
    ret i32 %iftmp
  }
  
  define private i32 @__fun0(i32 %n) {
  entry:
    %subtmp = sub i32 %n, 1
    %0 = call i32 @fib(i32 %subtmp)
    ret i32 %0
  }
  
  define private i32 @fibn2(i32 %n) {
  entry:
    %subtmp = sub i32 %n, 2
    %0 = call i32 @fib(i32 %subtmp)
    ret i32 %0
  }
  
  define i32 @main(i32 %0) {
  entry:
    %1 = call i32 @fib(i32 30)
    call void @printi(i32 %1)
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
    %1 = call i32 @one()
    %2 = call i32 @add(i32 %1, i32 1)
    %3 = call i32 @doiflesselse(i32 %2, i32 0, i32 1, i32 2)
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
    %envptr = getelementptr inbounds %closure, %closure* %capture_a, i32 0, i32 1
    %env = bitcast { i32 }* %clsr_capture_a to i8*
    store i8* %env, i8** %envptr, align 8
    %funcptr5 = bitcast %closure* %capture_a to i8**
    %loadtmp = load i8*, i8** %funcptr5, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i8*)*
    %envptr1 = getelementptr inbounds %closure, %closure* %capture_a, i32 0, i32 1
    %loadtmp2 = load i8*, i8** %envptr1, align 8
    %1 = call i32 %casttmp(i8* %loadtmp2)
    ret i32 %1
  }
  int
  [12]

First class functions
  $ dune exec -- schmu first_class.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  
  %generic = type opaque
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private i32 @__fun0(i32 %x) {
  entry:
    %addtmp = add i32 %x, 2
    ret i32 %addtmp
  }
  
  define void @__ig_ig(%generic* %0, %generic* %1, i8* %2, i64 %3, i64 %4) {
  entry:
    %5 = bitcast i8* %2 to %closure*
    %funcptr = getelementptr inbounds %closure, %closure* %5, i32 0, i32 0
    %loadtmp = load i8*, i8** %funcptr, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32)*
    %6 = bitcast %generic* %1 to i32*
    %7 = load i32, i32* %6, align 4
    %8 = call i32 %casttmp(i32 %7)
    %9 = bitcast %generic* %0 to i32*
    store i32 %8, i32* %9, align 4
    ret void
  }
  
  declare i32 @add1(i32 %0)
  
  declare void @apply(%generic* %0, %generic* %1, %closure* %2, i64 %3, i64 %4)
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
  
  define void @__ig_ig(%generic* %0, %generic* %1, i8* %2, i64 %3, i64 %4) {
  entry:
    %5 = bitcast i8* %2 to %closure*
    %funcptr1 = bitcast %closure* %5 to i8**
    %loadtmp = load i8*, i8** %funcptr1, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32)*
    %6 = bitcast %generic* %1 to i32*
    %7 = load i32, i32* %6, align 4
    %8 = call i32 %casttmp(i32 %7)
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
    %casttmp = bitcast i8* %loadtmp to void (%generic*, %generic*, i8*, i64, i64)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca i8, i64 %__3, align 16
    %ret2 = bitcast i8* %ret to %generic*
    call void %casttmp(%generic* %ret2, %generic* %x, i8* %loadtmp1, i64 %__3, i64 %__1)
    %1 = bitcast %generic* %0 to i8*
    %2 = bitcast %generic* %ret2 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 %__3, i1 false)
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
    store i8* bitcast (void (%generic*, %generic*, i8*, i64, i64)* @__ig_ig to i8*), i8** %funptr14, align 8
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
    store i8* bitcast (void (%generic*, %generic*, i8*, i64, i64)* @__ig_ig to i8*), i8** %funptr616, align 8
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
    %lesstmp = icmp slt i32 %i, 2
    br i1 %lesstmp, label %then, label %else
  
  then:                                             ; preds = %entry
    %subtmp = sub i32 %i, 1
    call void @printi(i32 %subtmp)
    br label %ifcont5
  
  else:                                             ; preds = %entry
    %lesstmp1 = icmp slt i32 %i, 400
    br i1 %lesstmp1, label %then2, label %else3
  
  then2:                                            ; preds = %else
    call void @printi(i32 %i)
    br label %ifcont
  
  else3:                                            ; preds = %else
    %addtmp = add i32 %i, 1
    call void @printi(i32 %addtmp)
    br label %ifcont
  
  ifcont:                                           ; preds = %else3, %then2
    %subtmp4 = sub i32 %i, 1
    call void @foo(i32 %subtmp4)
    br label %ifcont5
  
  ifcont5:                                          ; preds = %ifcont, %then
    ret void
  }
  
  define i32 @main(i32 %0) {
  entry:
    call void @foo(i32 4)
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
    %0 = call i32 %casttmp(i8* %loadtmp1)
    %funcptr28 = bitcast %closure* %b to i8**
    %loadtmp3 = load i8*, i8** %funcptr28, align 8
    %casttmp4 = bitcast i8* %loadtmp3 to i32 (i8*)*
    %envptr5 = getelementptr inbounds %closure, %closure* %b, i32 0, i32 1
    %loadtmp6 = load i8*, i8** %envptr5, align 8
    %1 = call i32 %casttmp4(i8* %loadtmp6)
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
    %envptr = getelementptr inbounds %closure, %closure* %two, i32 0, i32 1
    %env = bitcast { i32 }* %clsr_two to i8*
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

This is a regression test. The 'add1' function was not marked as a closure when being called from
a second function. Instead, the closure struct was being created again and the code segfaulted
  $ dune exec -- schmu indirect_closure.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"

  declare void @printi(i32 %0)

  define private void @boxed2int_int({ i32 }* %0, { i32 }* %t, { i8*, i8* }* %env) {
  entry:
    %1 = bitcast { i32 }* %t to i32*
    %2 = load i32, i32* %1, align 4
    %funcptr2 = bitcast { i8*, i8* }* %env to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %env, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %3 = call i32 %casttmp(i32 %2, i8* %loadtmp1)
    %4 = alloca { i32 }, align 8
    %x3 = bitcast { i32 }* %4 to i32*
    store i32 %3, i32* %x3, align 4
    %5 = bitcast { i32 }* %0 to i8*
    %6 = bitcast { i32 }* %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), i1 false)
    ret void
  }

  define private i32 @add1(i32 %x) {
  entry:
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
  }

  define private void @apply({ i32 }* %0, { i32 }* %x, { i8*, i8* }* %f, { i8*, i8* }* %env) {
  entry:
    %funcptr2 = bitcast { i8*, i8* }* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void ({ i32 }*, { i32 }*, { i8*, i8* }*, i8*)*
    %envptr = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca { i32 }, align 8
    call void %casttmp({ i32 }* %ret, { i32 }* %x, { i8*, i8* }* %env, i8* %loadtmp1)
    %1 = bitcast { i32 }* %0 to i8*
    %2 = bitcast { i32 }* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i64), i1 false)
    ret void
  }

  ; Function Attrs: argmemonly nofree nosync nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0

  define i32 @main(i32 %0) {
  entry:
    %1 = alloca { i32 }, align 8
    %x4 = bitcast { i32 }* %1 to i32*
    store i32 15, i32* %x4, align 4
    %clstmp = alloca { i8*, i8* }, align 8
    %funptr5 = bitcast { i8*, i8* }* %clstmp to i8**
    store i8* bitcast (void ({ i32 }*, { i32 }*, { i8*, i8* }*)* @boxed2int_int to i8*), i8** %funptr5, align 8
    %envptr = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %clstmp1 = alloca { i8*, i8* }, align 8
    %funptr26 = bitcast { i8*, i8* }* %clstmp1 to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr26, align 8
    %envptr3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %ret = alloca { i32 }, align 8
    call void @apply({ i32 }* %ret, { i32 }* %1, { i8*, i8* }* %clstmp, { i8*, i8* }* %clstmp1)
    %2 = bitcast { i32 }* %ret to i32*
    %3 = load i32, i32* %2, align 4
    call void @printi(i32 %3)
    ret i32 0
  }

  attributes #0 = { argmemonly nofree nosync nounwind willreturn }
  unit
  16
