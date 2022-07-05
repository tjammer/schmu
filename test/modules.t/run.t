Simplest module with 1 type and 1 nonpolymorphic function
  $ schmu nonpoly_func.smu -m --dump-llvm
  nonpoly_func.smu:3:5: warning: Unused binding add_ints
  3 | fun add_ints(a, b) = a + b
          ^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @schmu_add_ints(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  $ cat nonpoly_func.smi
  ((5:Mtype(8:Tvariant()6:either(((8:ctorname4:Left)(7:ctortyp()))((8:ctorname5:Right)(7:ctortyp())))))(4:Mfun(4:Tfun(4:Tint4:Tint)4:Tint6:Simple)8:add_ints))
  $ schmu import_nonpoly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  %either = type { i32 }
  
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare i64 @schmu_add_ints(i64 %0, i64 %1)
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_do(i32 %0) {
  entry:
    %box = alloca i32, align 4
    store i32 %0, i32* %box, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @schmu_add_ints(i64 0, i64 5)
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @schmu_add_ints(i64 0, i64 -5)
    ret i64 %2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca %string, align 8
    %cstr2 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr2, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %either = alloca %either, align 8
    %tag3 = bitcast %either* %either to i32*
    store i32 0, i32* %tag3, align 4
    %0 = tail call i64 @schmu_do(i32 0)
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    ret i64 0
  }
  $ cc nonpoly_func.o import_nonpoly_func.o && ./a.out
  5
