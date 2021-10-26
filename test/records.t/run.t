Compile stubs
  $ cc -c stub.c

Simple record creation (out of order)
  $ dune exec -- schmu simple.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i32 %0)
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca { i1, i32 }, align 8
    %x1 = bitcast { i1, i32 }* %1 to i1*
    store i1 true, i1* %x1, align 1
    %y = getelementptr inbounds { i1, i32 }, { i1, i32 }* %1, i32 0, i32 1
    store i32 10, i32* %y, align 4
    %2 = getelementptr inbounds { i1, i32 }, { i1, i32 }* %1, i32 0, i32 1
    %3 = load i32, i32* %2, align 4
    call void @printi(i32 %3)
    ret i32 0
  }
  unit
  10

Pass record to function
  $ dune exec -- schmu pass.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  declare void @printi(i32 %0)
  
  define private void @pass_to_func({ i32, i32 }* %a) {
  entry:
    %0 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %a, i32 0, i32 1
    %1 = load i32, i32* %0, align 4
    call void @printi(i32 %1)
    ret void
  }
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca { i32, i32 }, align 8
    %x1 = bitcast { i32, i32 }* %1 to i32*
    store i32 10, i32* %x1, align 4
    %y = getelementptr inbounds { i32, i32 }, { i32, i32 }* %1, i32 0, i32 1
    store i32 20, i32* %y, align 4
    call void @pass_to_func({ i32, i32 }* %1)
    ret i32 0
  }
  unit
  20
