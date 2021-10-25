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
    %capture_a = alloca { i8*, i8* }, align 8
    %funptr3 = bitcast { i8*, i8* }* %capture_a to i8**
    store i8* bitcast (i32 (i8*)* @capture_a to i8*), i8** %funptr3, align 8
    %clsr_capture_a = alloca { i32 }, align 8
    %a4 = bitcast { i32 }* %clsr_capture_a to i32*
    store i32 10, i32* %a4, align 4
    %envptr = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %capture_a, i32 0, i32 1
    %env = bitcast { i32 }* %clsr_capture_a to i8*
    store i8* %env, i8** %envptr, align 8
    %funcptr5 = bitcast { i8*, i8* }* %capture_a to i8**
    %loadtmp = load i8*, i8** %funcptr5, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i8*)*
    %envptr1 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %capture_a, i32 0, i32 1
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
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i32 %0)
  
  define private i32 @__fun0(i32 %x) {
  entry:
    %addtmp = add i32 %x, 2
    ret i32 %addtmp
  }
  
  define private i32 @add1(i32 %x) {
  entry:
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
  }
  
  define private i32 @apply(i32 %x, { i8*, i8* }* %f) {
  entry:
    %funcptr2 = bitcast { i8*, i8* }* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %0 = call i32 %casttmp(i32 %x, i8* %loadtmp1)
    ret i32 %0
  }
  
  define i32 @main(i32 %0) {
  entry:
    %clstmp = alloca { i8*, i8* }, align 8
    %funptr4 = bitcast { i8*, i8* }* %clstmp to i8**
    store i8* bitcast (i32 (i32)* @add1 to i8*), i8** %funptr4, align 8
    %envptr = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %1 = call i32 @apply(i32 1, { i8*, i8* }* %clstmp)
    call void @printi(i32 %1)
    %clstmp1 = alloca { i8*, i8* }, align 8
    %funptr25 = bitcast { i8*, i8* }* %clstmp1 to i8**
    store i8* bitcast (i32 (i32)* @__fun0 to i8*), i8** %funptr25, align 8
    %envptr3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %2 = call i32 @apply(i32 1, { i8*, i8* }* %clstmp1)
    call void @printi(i32 %2)
    ret i32 0
  }
  unit
  2
  3

We don't allow returning closures
  $ dune exec -- schmu no_closure_returns.smu
  Cannot (yet) return a closure

Don't try to create 'void' value in if
  $ dune exec -- schmu if_return_void.smu
  x86_64-pc-linux-gnu
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
    call void @foo(i32 20)
    ret i32 0
  }
  unit
