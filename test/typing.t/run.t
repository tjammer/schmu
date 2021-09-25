Compile stubs
  $ cc -c stub.c

Test name resolution and IR creation of functions
  $ dune exec -- schmu functions.smu
  x86_64-unknown-linux-gnu
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

Build main
  $ cc out.o stub.o

Run
  $ ./a.out
  832040
