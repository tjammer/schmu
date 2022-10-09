Test simple setting of mutable variables
  $ schmu --dump-llvm simple_set.smu && ./simple_set
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @b = global i64 0, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define i64 @schmu_hmm() {
  entry:
    %b = alloca i64, align 8
    store i64 10, i64* %b, align 4
    store i64 15, i64* %b, align 4
    ret i64 15
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 10, i64* @b, align 4
    store i64 14, i64* @b, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 14)
    %0 = add i32 %fmtsize, 1
    %1 = sext i32 %0 to i64
    %2 = tail call i8* @malloc(i64 %1)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %2, i64 %1, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 14)
    %str = alloca %string, align 8
    %cstr16 = bitcast %string* %str to i8**
    store i8* %2, i8** %cstr16, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %3 = mul i64 %1, -1
    store i64 %3, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %4 = ptrtoint i8* %2 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %4, i64 %3)
    %5 = tail call i64 @schmu_hmm()
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %5)
    %6 = add i32 %fmtsize3, 1
    %7 = sext i32 %6 to i64
    %8 = tail call i8* @malloc(i64 %7)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %8, i64 %7, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %5)
    %str5 = alloca %string, align 8
    %cstr618 = bitcast %string* %str5 to i8**
    store i8* %8, i8** %cstr618, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %9 = mul i64 %7, -1
    store i64 %9, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %10 = ptrtoint i8* %8 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %10, i64 %9)
    %owned = icmp slt i64 %9, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %8)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned15 = icmp slt i64 %3, 0
    br i1 %owned15, label %free13, label %cont14
  
  free13:                                           ; preds = %cont
    tail call void @free(i8* %2)
    br label %cont14
  
  cont14:                                           ; preds = %free13, %cont
    ret i64 0
  }
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
  14
  15

Warn on unneeded mutable bindings
  $ schmu unneeded_mut.smu
  unneeded_mut.smu:1:18: warning: Unmutated mutable binding a
  1 | (fun do_nothing [a&]
                       ^
  
  unneeded_mut.smu:1:6: warning: Unused binding do_nothing
  1 | (fun do_nothing [a&]
           ^^^^^^^^^^
  
  unneeded_mut.smu:7:6: warning: Unmutated mutable binding b
  7 | (val b& 0)
           ^
  
