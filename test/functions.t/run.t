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

We don't have closures yet
  $ dune exec -- schmu no_closures.smu
  Fatal error: exception Failure("Internal Error: Could not find a in codegen. No closures yet")
  [2]

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
    %funcptr1 = bitcast { i8*, i8* }* %f to i8**
    %loadtmp = load i8*, i8** %funcptr1, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %0 = call i32 %casttmp(i32 %x, i8* null)
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
