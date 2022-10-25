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
  
Use mutable values as ptrs to C code
  $ schmu -c --dump-llvm ptr_to_c.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  
  @i = global i64 0, align 8
  @foo = global %foo zeroinitializer, align 8
  
  declare void @mutate_int(i64* %0)
  
  declare void @mutate_foo(%foo* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* @i, align 4
    tail call void @mutate_int(i64* @i)
    store i64 0, i64* getelementptr inbounds (%foo, %foo* @foo, i32 0, i32 0), align 4
    tail call void @mutate_foo(%foo* @foo)
    ret i64 0
  }

Make sure there is no aliasing here
  $ schmu --dump-llvm copies.smu && ./copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { %owned_ptr_int, i64 }
  %owned_ptr_int = type { i64*, i64 }
  %vector_foo = type { %owned_ptr_foo, i64 }
  %owned_ptr_foo = type { %foo*, i64 }
  %foo = type { i64 }
  %string = type { i8*, i64 }
  
  @v = global %vector_int zeroinitializer, align 16
  @fst = global i64 0, align 8
  @v__2 = global %vector_foo zeroinitializer, align 16
  @fst__2 = global %foo zeroinitializer, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  @1 = private unnamed_addr constant [7 x i8] c"record\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_in-fun__2() {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to %foo*
    %vec = alloca %vector_foo, align 8
    %owned_ptr20 = bitcast %vector_foo* %vec to %owned_ptr_foo*
    %data21 = bitcast %owned_ptr_foo* %owned_ptr20 to %foo**
    store %foo* %1, %foo** %data21, align 8
    %a22 = bitcast %foo* %1 to i64*
    store i64 0, i64* %a22, align 4
    %len = getelementptr inbounds %owned_ptr_foo, %owned_ptr_foo* %owned_ptr20, i32 0, i32 1
    store i64 1, i64* %len, align 4
    %cap = getelementptr inbounds %vector_foo, %vector_foo* %vec, i32 0, i32 1
    store i64 1, i64* %cap, align 4
    %ret = alloca %foo, align 8
    %2 = call i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* %vec, i64 0)
    %box = bitcast %foo* %ret to i64*
    store i64 %2, i64* %box, align 4
    %3 = bitcast %foo* %ret to i64*
    store i64 1, i64* %3, align 4
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %4 = add i32 %fmtsize, 1
    %5 = sext i32 %4 to i64
    %6 = call i8* @malloc(i64 %5)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %5, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr23 = bitcast %string* %str to i8**
    store i8* %6, i8** %cstr23, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %7 = mul i64 %5, -1
    store i64 %7, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %8 = ptrtoint i8* %6 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %8, i64 %7)
    %ret4 = alloca %foo, align 8
    %9 = call i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* %vec, i64 0)
    %box5 = bitcast %foo* %ret4 to i64*
    store i64 %9, i64* %box5, align 4
    %fmtsize7 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %9)
    %10 = add i32 %fmtsize7, 1
    %11 = sext i32 %10 to i64
    %12 = call i8* @malloc(i64 %11)
    %fmt8 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %11, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %9)
    %str9 = alloca %string, align 8
    %cstr1025 = bitcast %string* %str9 to i8**
    store i8* %12, i8** %cstr1025, align 8
    %length11 = getelementptr inbounds %string, %string* %str9, i32 0, i32 1
    %13 = mul i64 %11, -1
    store i64 %13, i64* %length11, align 4
    %unbox12 = bitcast %string* %str9 to { i64, i64 }*
    %14 = ptrtoint i8* %12 to i64
    %snd15 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox12, i32 0, i32 1
    call void @schmu_print(i64 %14, i64 %13)
    %15 = load %foo*, %foo** %data21, align 8
    %16 = bitcast %foo* %15 to i8*
    call void @free(i8* %16)
    %owned = icmp slt i64 %7, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    call void @free(i8* %6)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned19 = icmp slt i64 %13, 0
    br i1 %owned19, label %free17, label %cont18
  
  free17:                                           ; preds = %cont
    call void @free(i8* %12)
    br label %cont18
  
  cont18:                                           ; preds = %free17, %cont
    ret void
  }
  
  define i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* %vec, i64 %i) {
  entry:
    %0 = bitcast %vector_foo* %vec to %owned_ptr_foo*
    %1 = bitcast %owned_ptr_foo* %0 to %foo**
    %2 = load %foo*, %foo** %1, align 8
    %3 = getelementptr inbounds %foo, %foo* %2, i64 %i
    %unbox = bitcast %foo* %3 to i64*
    %unbox1 = load i64, i64* %unbox, align 4
    ret i64 %unbox1
  }
  
  define void @schmu_in-fun() {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    %vec = alloca %vector_int, align 8
    %owned_ptr17 = bitcast %vector_int* %vec to %owned_ptr_int*
    %data18 = bitcast %owned_ptr_int* %owned_ptr17 to i64**
    store i64* %1, i64** %data18, align 8
    store i64 0, i64* %1, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr17, i32 0, i32 1
    store i64 1, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 1, i64* %cap, align 4
    %2 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    %fst = alloca i64, align 8
    store i64 %2, i64* %fst, align 4
    store i64 1, i64* %fst, align 4
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %3 = add i32 %fmtsize, 1
    %4 = sext i32 %3 to i64
    %5 = call i8* @malloc(i64 %4)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %4, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr19 = bitcast %string* %str to i8**
    store i8* %5, i8** %cstr19, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %6 = mul i64 %4, -1
    store i64 %6, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %7 = ptrtoint i8* %5 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %7, i64 %6)
    %8 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    %fmtsize4 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %8)
    %9 = add i32 %fmtsize4, 1
    %10 = sext i32 %9 to i64
    %11 = call i8* @malloc(i64 %10)
    %fmt5 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %8)
    %str6 = alloca %string, align 8
    %cstr721 = bitcast %string* %str6 to i8**
    store i8* %11, i8** %cstr721, align 8
    %length8 = getelementptr inbounds %string, %string* %str6, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length8, align 4
    %unbox9 = bitcast %string* %str6 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd12 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox9, i32 0, i32 1
    call void @schmu_print(i64 %13, i64 %12)
    %14 = load i64*, i64** %data18, align 8
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    %owned = icmp slt i64 %6, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    call void @free(i8* %5)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned16 = icmp slt i64 %12, 0
    br i1 %owned16, label %free14, label %cont15
  
  free14:                                           ; preds = %cont
    call void @free(i8* %11)
    br label %cont15
  
  cont15:                                           ; preds = %free14, %cont
    ret void
  }
  
  define i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 %i) {
  entry:
    %0 = bitcast %vector_int* %vec to %owned_ptr_int*
    %1 = bitcast %owned_ptr_int* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %3 = getelementptr inbounds i64, i64* %2, i64 %i
    %4 = load i64, i64* %3, align 4
    ret i64 %4
  }
  
  declare i8* @malloc(i64 %0)
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 0), align 8
    store i64 0, i64* %1, align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 1), align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 1), align 4
    %2 = tail call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* @v, i64 0)
    store i64 %2, i64* @fst, align 4
    store i64 1, i64* @fst, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %3 = add i32 %fmtsize, 1
    %4 = sext i32 %3 to i64
    %5 = tail call i8* @malloc(i64 %4)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %5, i64 %4, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr51 = bitcast %string* %str to i8**
    store i8* %5, i8** %cstr51, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %6 = mul i64 %4, -1
    store i64 %6, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %7 = ptrtoint i8* %5 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %7, i64 %6)
    %8 = tail call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* @v, i64 0)
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %8)
    %9 = add i32 %fmtsize3, 1
    %10 = sext i32 %9 to i64
    %11 = tail call i8* @malloc(i64 %10)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %8)
    %str5 = alloca %string, align 8
    %cstr653 = bitcast %string* %str5 to i8**
    store i8* %11, i8** %cstr653, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %13, i64 %12)
    tail call void @schmu_in-fun()
    %str13 = alloca %string, align 8
    %cstr1455 = bitcast %string* %str13 to i8**
    store i8* getelementptr inbounds ([7 x i8], [7 x i8]* @1, i32 0, i32 0), i8** %cstr1455, align 8
    %length15 = getelementptr inbounds %string, %string* %str13, i32 0, i32 1
    store i64 6, i64* %length15, align 4
    %unbox16 = bitcast %string* %str13 to { i64, i64 }*
    %snd19 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox16, i32 0, i32 1
    tail call void @schmu_print(i64 ptrtoint ([7 x i8]* @1 to i64), i64 6)
    %14 = tail call i8* @malloc(i64 8)
    %15 = bitcast i8* %14 to %foo*
    store %foo* %15, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @v__2, i32 0, i32 0, i32 0), align 8
    %a57 = bitcast %foo* %15 to i64*
    store i64 0, i64* %a57, align 4
    store i64 1, i64* getelementptr inbounds (%vector_foo, %vector_foo* @v__2, i32 0, i32 0, i32 1), align 4
    store i64 1, i64* getelementptr inbounds (%vector_foo, %vector_foo* @v__2, i32 0, i32 1), align 4
    %16 = tail call i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* @v__2, i64 0)
    store i64 %16, i64* getelementptr inbounds (%foo, %foo* @fst__2, i32 0, i32 0), align 4
    store i64 1, i64* getelementptr inbounds (%foo, %foo* @fst__2, i32 0, i32 0), align 4
    %fmtsize21 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %17 = add i32 %fmtsize21, 1
    %18 = sext i32 %17 to i64
    %19 = tail call i8* @malloc(i64 %18)
    %fmt22 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %19, i64 %18, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str23 = alloca %string, align 8
    %cstr2458 = bitcast %string* %str23 to i8**
    store i8* %19, i8** %cstr2458, align 8
    %length25 = getelementptr inbounds %string, %string* %str23, i32 0, i32 1
    %20 = mul i64 %18, -1
    store i64 %20, i64* %length25, align 4
    %unbox26 = bitcast %string* %str23 to { i64, i64 }*
    %21 = ptrtoint i8* %19 to i64
    %snd29 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox26, i32 0, i32 1
    tail call void @schmu_print(i64 %21, i64 %20)
    %ret = alloca %foo, align 8
    %22 = tail call i64 @schmu___vectorgi.g_vector-get_vectorfooi.foo(%vector_foo* @v__2, i64 0)
    %box = bitcast %foo* %ret to i64*
    store i64 %22, i64* %box, align 4
    %fmtsize32 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %22)
    %23 = add i32 %fmtsize32, 1
    %24 = sext i32 %23 to i64
    %25 = tail call i8* @malloc(i64 %24)
    %fmt33 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %25, i64 %24, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %22)
    %str34 = alloca %string, align 8
    %cstr3560 = bitcast %string* %str34 to i8**
    store i8* %25, i8** %cstr3560, align 8
    %length36 = getelementptr inbounds %string, %string* %str34, i32 0, i32 1
    %26 = mul i64 %24, -1
    store i64 %26, i64* %length36, align 4
    %unbox37 = bitcast %string* %str34 to { i64, i64 }*
    %27 = ptrtoint i8* %25 to i64
    %snd40 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox37, i32 0, i32 1
    tail call void @schmu_print(i64 %27, i64 %26)
    tail call void @schmu_in-fun__2()
    %owned = icmp slt i64 %26, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %25)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned44 = icmp slt i64 %20, 0
    br i1 %owned44, label %free42, label %cont43
  
  free42:                                           ; preds = %cont
    tail call void @free(i8* %19)
    br label %cont43
  
  cont43:                                           ; preds = %free42, %cont
    %28 = load %foo*, %foo** getelementptr inbounds (%vector_foo, %vector_foo* @v__2, i32 0, i32 0, i32 0), align 8
    %29 = bitcast %foo* %28 to i8*
    tail call void @free(i8* %29)
    %owned47 = icmp slt i64 %12, 0
    br i1 %owned47, label %free45, label %cont46
  
  free45:                                           ; preds = %cont43
    tail call void @free(i8* %11)
    br label %cont46
  
  cont46:                                           ; preds = %free45, %cont43
    %owned50 = icmp slt i64 %6, 0
    br i1 %owned50, label %free48, label %cont49
  
  free48:                                           ; preds = %cont46
    tail call void @free(i8* %5)
    br label %cont49
  
  cont49:                                           ; preds = %free48, %cont46
    %30 = load i64*, i64** getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 0), align 8
    %31 = bitcast i64* %30 to i8*
    tail call void @free(i8* %31)
    ret i64 0
  }
  1
  0
  1
  0
  record
  1
  0
  1
  0

  $ schmu --dump-llvm mut_alias.smu && ./mut_alias
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %string = type { i8*, i64 }
  
  @f = global %foo zeroinitializer, align 8
  @fst = global %foo zeroinitializer, align 8
  @snd = global %foo zeroinitializer, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_new-fun() {
  entry:
    %0 = alloca %foo, align 8
    %a31 = bitcast %foo* %0 to i64*
    store i64 0, i64* %a31, align 4
    %fst = alloca %foo, align 8
    %1 = bitcast %foo* %fst to i8*
    %2 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    %snd = alloca %foo, align 8
    %3 = bitcast %foo* %snd to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 8, i1 false)
    %4 = bitcast %foo* %fst to i64*
    store i64 1, i64* %4, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %5 = add i32 %fmtsize, 1
    %6 = sext i32 %5 to i64
    %7 = tail call i8* @malloc(i64 %6)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %7, i64 %6, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr32 = bitcast %string* %str to i8**
    store i8* %7, i8** %cstr32, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %8 = mul i64 %6, -1
    store i64 %8, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %9 = ptrtoint i8* %7 to i64
    %snd3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %9, i64 %8)
    %fmtsize5 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 0)
    %10 = add i32 %fmtsize5, 1
    %11 = sext i32 %10 to i64
    %12 = tail call i8* @malloc(i64 %11)
    %fmt6 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %11, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 0)
    %str7 = alloca %string, align 8
    %cstr834 = bitcast %string* %str7 to i8**
    store i8* %12, i8** %cstr834, align 8
    %length9 = getelementptr inbounds %string, %string* %str7, i32 0, i32 1
    %13 = mul i64 %11, -1
    store i64 %13, i64* %length9, align 4
    %unbox10 = bitcast %string* %str7 to { i64, i64 }*
    %14 = ptrtoint i8* %12 to i64
    %snd13 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox10, i32 0, i32 1
    tail call void @schmu_print(i64 %14, i64 %13)
    %15 = bitcast %foo* %snd to i64*
    %16 = load i64, i64* %15, align 4
    %fmtsize15 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %16)
    %17 = add i32 %fmtsize15, 1
    %18 = sext i32 %17 to i64
    %19 = tail call i8* @malloc(i64 %18)
    %fmt16 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %19, i64 %18, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %16)
    %str17 = alloca %string, align 8
    %cstr1836 = bitcast %string* %str17 to i8**
    store i8* %19, i8** %cstr1836, align 8
    %length19 = getelementptr inbounds %string, %string* %str17, i32 0, i32 1
    %20 = mul i64 %18, -1
    store i64 %20, i64* %length19, align 4
    %unbox20 = bitcast %string* %str17 to { i64, i64 }*
    %21 = ptrtoint i8* %19 to i64
    %snd23 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox20, i32 0, i32 1
    tail call void @schmu_print(i64 %21, i64 %20)
    %owned = icmp slt i64 %8, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %7)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned27 = icmp slt i64 %13, 0
    br i1 %owned27, label %free25, label %cont26
  
  free25:                                           ; preds = %cont
    tail call void @free(i8* %12)
    br label %cont26
  
  cont26:                                           ; preds = %free25, %cont
    %owned30 = icmp slt i64 %20, 0
    br i1 %owned30, label %free28, label %cont29
  
  free28:                                           ; preds = %cont26
    tail call void @free(i8* %19)
    ret void
  
  cont29:                                           ; preds = %cont26
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* getelementptr inbounds (%foo, %foo* @f, i32 0, i32 0), align 4
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%foo* @fst to i8*), i8* bitcast (%foo* @f to i8*), i64 8, i1 false)
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%foo* @snd to i8*), i8* bitcast (%foo* @fst to i8*), i64 8, i1 false)
    store i64 1, i64* getelementptr inbounds (%foo, %foo* @fst, i32 0, i32 0), align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %0 = add i32 %fmtsize, 1
    %1 = sext i32 %0 to i64
    %2 = tail call i8* @malloc(i64 %1)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %2, i64 %1, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 1)
    %str = alloca %string, align 8
    %cstr29 = bitcast %string* %str to i8**
    store i8* %2, i8** %cstr29, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %3 = mul i64 %1, -1
    store i64 %3, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %4 = ptrtoint i8* %2 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %4, i64 %3)
    %5 = load i64, i64* getelementptr inbounds (%foo, %foo* @f, i32 0, i32 0), align 4
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %5)
    %6 = add i32 %fmtsize3, 1
    %7 = sext i32 %6 to i64
    %8 = tail call i8* @malloc(i64 %7)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %8, i64 %7, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %5)
    %str5 = alloca %string, align 8
    %cstr631 = bitcast %string* %str5 to i8**
    store i8* %8, i8** %cstr631, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %9 = mul i64 %7, -1
    store i64 %9, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %10 = ptrtoint i8* %8 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %10, i64 %9)
    %11 = load i64, i64* getelementptr inbounds (%foo, %foo* @snd, i32 0, i32 0), align 4
    %fmtsize13 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %11)
    %12 = add i32 %fmtsize13, 1
    %13 = sext i32 %12 to i64
    %14 = tail call i8* @malloc(i64 %13)
    %fmt14 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %14, i64 %13, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %11)
    %str15 = alloca %string, align 8
    %cstr1633 = bitcast %string* %str15 to i8**
    store i8* %14, i8** %cstr1633, align 8
    %length17 = getelementptr inbounds %string, %string* %str15, i32 0, i32 1
    %15 = mul i64 %13, -1
    store i64 %15, i64* %length17, align 4
    %unbox18 = bitcast %string* %str15 to { i64, i64 }*
    %16 = ptrtoint i8* %14 to i64
    %snd21 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox18, i32 0, i32 1
    tail call void @schmu_print(i64 %16, i64 %15)
    tail call void @schmu_new-fun()
    %owned = icmp slt i64 %15, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %14)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned25 = icmp slt i64 %9, 0
    br i1 %owned25, label %free23, label %cont24
  
  free23:                                           ; preds = %cont
    tail call void @free(i8* %8)
    br label %cont24
  
  cont24:                                           ; preds = %free23, %cont
    %owned28 = icmp slt i64 %3, 0
    br i1 %owned28, label %free26, label %cont27
  
  free26:                                           ; preds = %cont24
    tail call void @free(i8* %2)
    br label %cont27
  
  cont27:                                           ; preds = %free26, %cont24
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  1
  0
  0
  1
  0
  0

  $ schmu --dump-llvm const_let.smu && ./const_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { %owned_ptr_int, i64 }
  %owned_ptr_int = type { i64*, i64 }
  %string = type { i8*, i64 }
  
  @v = global %vector_int zeroinitializer, align 16
  @const = global i64 0, align 8
  @0 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_in-fun__2() {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    %vec = alloca %vector_int, align 8
    %owned_ptr16 = bitcast %vector_int* %vec to %owned_ptr_int*
    %data17 = bitcast %owned_ptr_int* %owned_ptr16 to i64**
    store i64* %1, i64** %data17, align 8
    store i64 0, i64* %1, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr16, i32 0, i32 1
    store i64 1, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 1, i64* %cap, align 4
    %2 = load i64*, i64** %data17, align 8
    %const = load i64, i64* %2, align 4
    call void @schmu___vectorgig.u_vector-set_vectoriii.u(%vector_int* %vec, i64 0, i64 1)
    %3 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %4 = add i32 %fmtsize, 1
    %5 = sext i32 %4 to i64
    %6 = call i8* @malloc(i64 %5)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %5, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %str = alloca %string, align 8
    %cstr18 = bitcast %string* %str to i8**
    store i8* %6, i8** %cstr18, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %7 = mul i64 %5, -1
    store i64 %7, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %8 = ptrtoint i8* %6 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %8, i64 %7)
    %fmtsize3 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %const)
    %9 = add i32 %fmtsize3, 1
    %10 = sext i32 %9 to i64
    %11 = call i8* @malloc(i64 %10)
    %fmt4 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %const)
    %str5 = alloca %string, align 8
    %cstr620 = bitcast %string* %str5 to i8**
    store i8* %11, i8** %cstr620, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    call void @schmu_print(i64 %13, i64 %12)
    %14 = load i64*, i64** %data17, align 8
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    %owned = icmp slt i64 %7, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    call void @free(i8* %6)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned15 = icmp slt i64 %12, 0
    br i1 %owned15, label %free13, label %cont14
  
  free13:                                           ; preds = %cont
    call void @free(i8* %11)
    br label %cont14
  
  cont14:                                           ; preds = %free13, %cont
    ret void
  }
  
  define void @schmu_in-fun() {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    %vec = alloca %vector_int, align 8
    %owned_ptr16 = bitcast %vector_int* %vec to %owned_ptr_int*
    %data17 = bitcast %owned_ptr_int* %owned_ptr16 to i64**
    store i64* %1, i64** %data17, align 8
    store i64 0, i64* %1, align 4
    %len = getelementptr inbounds %owned_ptr_int, %owned_ptr_int* %owned_ptr16, i32 0, i32 1
    store i64 1, i64* %len, align 4
    %cap = getelementptr inbounds %vector_int, %vector_int* %vec, i32 0, i32 1
    store i64 1, i64* %cap, align 4
    %2 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    call void @schmu___vectorgig.u_vector-set_vectoriii.u(%vector_int* %vec, i64 0, i64 1)
    %3 = call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 0)
    %fmtsize = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %4 = add i32 %fmtsize, 1
    %5 = sext i32 %4 to i64
    %6 = call i8* @malloc(i64 %5)
    %fmt = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %5, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %str = alloca %string, align 8
    %cstr18 = bitcast %string* %str to i8**
    store i8* %6, i8** %cstr18, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %7 = mul i64 %5, -1
    store i64 %7, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %8 = ptrtoint i8* %6 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    call void @schmu_print(i64 %8, i64 %7)
    %fmtsize3 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %2)
    %9 = add i32 %fmtsize3, 1
    %10 = sext i32 %9 to i64
    %11 = call i8* @malloc(i64 %10)
    %fmt4 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %11, i64 %10, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %2)
    %str5 = alloca %string, align 8
    %cstr620 = bitcast %string* %str5 to i8**
    store i8* %11, i8** %cstr620, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %12 = mul i64 %10, -1
    store i64 %12, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %13 = ptrtoint i8* %11 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    call void @schmu_print(i64 %13, i64 %12)
    %14 = load i64*, i64** %data17, align 8
    %15 = bitcast i64* %14 to i8*
    call void @free(i8* %15)
    %owned = icmp slt i64 %7, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    call void @free(i8* %6)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned15 = icmp slt i64 %12, 0
    br i1 %owned15, label %free13, label %cont14
  
  free13:                                           ; preds = %cont
    call void @free(i8* %11)
    br label %cont14
  
  cont14:                                           ; preds = %free13, %cont
    ret void
  }
  
  define void @schmu___vectorgig.u_vector-set_vectoriii.u(%vector_int* %vec, i64 %i, i64 %v) {
  entry:
    %0 = bitcast %vector_int* %vec to %owned_ptr_int*
    %1 = bitcast %owned_ptr_int* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %3 = getelementptr inbounds i64, i64* %2, i64 %i
    store i64 %v, i64* %3, align 4
    ret void
  }
  
  define i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* %vec, i64 %i) {
  entry:
    %0 = bitcast %vector_int* %vec to %owned_ptr_int*
    %1 = bitcast %owned_ptr_int* %0 to i64**
    %2 = load i64*, i64** %1, align 8
    %3 = getelementptr inbounds i64, i64* %2, i64 %i
    %4 = load i64, i64* %3, align 4
    ret i64 %4
  }
  
  declare i8* @malloc(i64 %0)
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 8)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 0), align 8
    store i64 0, i64* %1, align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 1), align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 1), align 4
    %2 = tail call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* @v, i64 0)
    store i64 %2, i64* @const, align 4
    tail call void @schmu___vectorgig.u_vector-set_vectoriii.u(%vector_int* @v, i64 0, i64 1)
    %3 = tail call i64 @schmu___vectorgi.g_vector-get_vectorii.i(%vector_int* @v, i64 0)
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %4 = add i32 %fmtsize, 1
    %5 = sext i32 %4 to i64
    %6 = tail call i8* @malloc(i64 %5)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 %5, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %3)
    %str = alloca %string, align 8
    %cstr16 = bitcast %string* %str to i8**
    store i8* %6, i8** %cstr16, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %7 = mul i64 %5, -1
    store i64 %7, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %8 = ptrtoint i8* %6 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %8, i64 %7)
    %9 = load i64, i64* @const, align 4
    %fmtsize3 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %9)
    %10 = add i32 %fmtsize3, 1
    %11 = sext i32 %10 to i64
    %12 = tail call i8* @malloc(i64 %11)
    %fmt4 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %12, i64 %11, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %9)
    %str5 = alloca %string, align 8
    %cstr618 = bitcast %string* %str5 to i8**
    store i8* %12, i8** %cstr618, align 8
    %length7 = getelementptr inbounds %string, %string* %str5, i32 0, i32 1
    %13 = mul i64 %11, -1
    store i64 %13, i64* %length7, align 4
    %unbox8 = bitcast %string* %str5 to { i64, i64 }*
    %14 = ptrtoint i8* %12 to i64
    %snd11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox8, i32 0, i32 1
    tail call void @schmu_print(i64 %14, i64 %13)
    tail call void @schmu_in-fun()
    tail call void @schmu_in-fun__2()
    %owned = icmp slt i64 %13, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %entry
    tail call void @free(i8* %12)
    br label %cont
  
  cont:                                             ; preds = %free, %entry
    %owned15 = icmp slt i64 %7, 0
    br i1 %owned15, label %free13, label %cont14
  
  free13:                                           ; preds = %cont
    tail call void @free(i8* %6)
    br label %cont14
  
  cont14:                                           ; preds = %free13, %cont
    %15 = load i64*, i64** getelementptr inbounds (%vector_int, %vector_int* @v, i32 0, i32 0, i32 0), align 8
    %16 = bitcast i64* %15 to i8*
    tail call void @free(i8* %16)
    ret i64 0
  }
  1
  0
  1
  0
  1
  0


Copies, but with ref-counted arrays
  $ schmu array_copies.smu --dump-llvm && ./array_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @a = global i64* null, align 8
  @b = global i64* null, align 8
  @c = global i64* null, align 8
  @d = global i64* null, align 8
  @0 = private unnamed_addr constant [7 x i8] c"in fun\00", align 1
  @1 = private unnamed_addr constant [4 x i8] c"%li\00", align 1
  
  declare void @schmu_print(i64 %0, i64 %1)
  
  define void @schmu_in-fun() {
  entry:
    %str = alloca %string, align 8
    %cstr90 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([7 x i8], [7 x i8]* @0, i32 0, i32 0), i8** %cstr90, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 6, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 ptrtoint ([7 x i8]* @0 to i64), i64 6)
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 10, i64* %data, align 4
    store i64 2, i64* %1, align 4
    store i64 3, i64* %1, align 4
    %c = alloca i64*, align 8
    %2 = bitcast i64** %c to i8*
    %3 = bitcast i64** %arr to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    store i64 4, i64* %1, align 4
    %4 = bitcast i8* %0 to i64*
    %5 = tail call i8* @malloc(i64 32)
    %6 = bitcast i8* %5 to i64*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %5, i64 32, i1 false)
    store i64* %6, i64** %arr, align 8
    %ref14 = load i64, i64* %4, align 4
    %7 = sub i64 %ref14, 1
    store i64 %7, i64* %4, align 4
    %data15 = getelementptr i64, i64* %6, i64 3
    store i64 12, i64* %data15, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 12)
    %8 = add i32 %fmtsize, 1
    %9 = sext i32 %8 to i64
    %10 = tail call i8* @malloc(i64 %9)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %10, i64 %9, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 12)
    %str17 = alloca %string, align 8
    %cstr1892 = bitcast %string* %str17 to i8**
    store i8* %10, i8** %cstr1892, align 8
    %length19 = getelementptr inbounds %string, %string* %str17, i32 0, i32 1
    %11 = mul i64 %9, -1
    store i64 %11, i64* %length19, align 4
    %unbox20 = bitcast %string* %str17 to { i64, i64 }*
    %12 = ptrtoint i8* %10 to i64
    %snd23 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox20, i32 0, i32 1
    tail call void @schmu_print(i64 %12, i64 %11)
    %13 = load i64*, i64** %c, align 8
    %ref28 = load i64, i64* %13, align 4
    %14 = icmp sgt i64 %ref28, 1
    br i1 %14, label %relocate25, label %merge26
  
  relocate25:                                       ; preds = %entry
    %cap29 = getelementptr i64, i64* %13, i64 2
    %cap30 = load i64, i64* %cap29, align 4
    %15 = mul i64 %cap30, 8
    %16 = add i64 %15, 24
    %17 = tail call i8* @malloc(i64 %16)
    %18 = bitcast i8* %17 to i64*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %17, i8* %17, i64 %16, i1 false)
    store i64* %18, i64** %c, align 8
    %ref32 = load i64, i64* %13, align 4
    %19 = sub i64 %ref32, 1
    store i64 %19, i64* %13, align 4
    br label %merge26
  
  merge26:                                          ; preds = %relocate25, %entry
    %20 = phi i64* [ %18, %relocate25 ], [ %13, %entry ]
    %21 = bitcast i8* %0 to i64*
    %data33 = getelementptr i64, i64* %20, i64 3
    store i64 15, i64* %data33, align 4
    %22 = bitcast i64* %6 to i8*
    %sunkaddr = getelementptr i8, i8* %22, i64 24
    %23 = bitcast i8* %sunkaddr to i64*
    %24 = load i64, i64* %23, align 4
    %fmtsize35 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %24)
    %25 = add i32 %fmtsize35, 1
    %26 = sext i32 %25 to i64
    %27 = tail call i8* @malloc(i64 %26)
    %fmt36 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %27, i64 %26, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %24)
    %str37 = alloca %string, align 8
    %cstr3894 = bitcast %string* %str37 to i8**
    store i8* %27, i8** %cstr3894, align 8
    %length39 = getelementptr inbounds %string, %string* %str37, i32 0, i32 1
    %28 = mul i64 %26, -1
    store i64 %28, i64* %length39, align 4
    %unbox40 = bitcast %string* %str37 to { i64, i64 }*
    %29 = ptrtoint i8* %27 to i64
    %snd43 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox40, i32 0, i32 1
    tail call void @schmu_print(i64 %29, i64 %28)
    %30 = bitcast i64* %21 to i8*
    %sunkaddr96 = getelementptr i8, i8* %30, i64 24
    %31 = bitcast i8* %sunkaddr96 to i64*
    %32 = load i64, i64* %31, align 4
    %fmtsize46 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %32)
    %33 = add i32 %fmtsize46, 1
    %34 = sext i32 %33 to i64
    %35 = tail call i8* @malloc(i64 %34)
    %fmt47 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %35, i64 %34, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %32)
    %str48 = alloca %string, align 8
    %cstr4997 = bitcast %string* %str48 to i8**
    store i8* %35, i8** %cstr4997, align 8
    %length50 = getelementptr inbounds %string, %string* %str48, i32 0, i32 1
    %36 = mul i64 %34, -1
    store i64 %36, i64* %length50, align 4
    %unbox51 = bitcast %string* %str48 to { i64, i64 }*
    %37 = ptrtoint i8* %35 to i64
    %snd54 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox51, i32 0, i32 1
    tail call void @schmu_print(i64 %37, i64 %36)
    %38 = load i64, i64* %data33, align 4
    %fmtsize57 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %38)
    %39 = add i32 %fmtsize57, 1
    %40 = sext i32 %39 to i64
    %41 = tail call i8* @malloc(i64 %40)
    %fmt58 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %41, i64 %40, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %38)
    %str59 = alloca %string, align 8
    %cstr6099 = bitcast %string* %str59 to i8**
    store i8* %41, i8** %cstr6099, align 8
    %length61 = getelementptr inbounds %string, %string* %str59, i32 0, i32 1
    %42 = mul i64 %40, -1
    store i64 %42, i64* %length61, align 4
    %unbox62 = bitcast %string* %str59 to { i64, i64 }*
    %43 = ptrtoint i8* %41 to i64
    %snd65 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox62, i32 0, i32 1
    tail call void @schmu_print(i64 %43, i64 %42)
    %44 = load i64, i64* %31, align 4
    %fmtsize68 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %44)
    %45 = add i32 %fmtsize68, 1
    %46 = sext i32 %45 to i64
    %47 = tail call i8* @malloc(i64 %46)
    %fmt69 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %47, i64 %46, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %44)
    %str70 = alloca %string, align 8
    %cstr71101 = bitcast %string* %str70 to i8**
    store i8* %47, i8** %cstr71101, align 8
    %length72 = getelementptr inbounds %string, %string* %str70, i32 0, i32 1
    %48 = mul i64 %46, -1
    store i64 %48, i64* %length72, align 4
    %unbox73 = bitcast %string* %str70 to { i64, i64 }*
    %49 = ptrtoint i8* %47 to i64
    %snd76 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox73, i32 0, i32 1
    tail call void @schmu_print(i64 %49, i64 %48)
    %owned = icmp slt i64 %11, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %merge26
    tail call void @free(i8* %10)
    br label %cont
  
  cont:                                             ; preds = %free, %merge26
    %owned80 = icmp slt i64 %28, 0
    br i1 %owned80, label %free78, label %cont79
  
  free78:                                           ; preds = %cont
    tail call void @free(i8* %27)
    br label %cont79
  
  cont79:                                           ; preds = %free78, %cont
    %owned83 = icmp slt i64 %36, 0
    br i1 %owned83, label %free81, label %cont82
  
  free81:                                           ; preds = %cont79
    tail call void @free(i8* %35)
    br label %cont82
  
  cont82:                                           ; preds = %free81, %cont79
    %owned86 = icmp slt i64 %42, 0
    br i1 %owned86, label %free84, label %cont85
  
  free84:                                           ; preds = %cont82
    tail call void @free(i8* %41)
    br label %cont85
  
  cont85:                                           ; preds = %free84, %cont82
    %owned89 = icmp slt i64 %48, 0
    br i1 %owned89, label %free87, label %cont88
  
  free87:                                           ; preds = %cont85
    tail call void @free(i8* %47)
    ret void
  
  cont88:                                           ; preds = %cont85
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i32 @snprintf(i8* %0, i64 %1, i8* %2, ...)
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @a, align 8
    store i64 1, i64* %1, align 4
    %size = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %size, align 4
    %cap = getelementptr i64, i64* %1, i64 2
    store i64 1, i64* %cap, align 4
    %data = getelementptr i64, i64* %1, i64 3
    store i64 10, i64* %data, align 4
    %2 = load i64*, i64** @a, align 8
    store i64* %2, i64** @a, align 8
    %ref2 = load i64, i64* %2, align 4
    %3 = add i64 %ref2, 1
    store i64 %3, i64* %2, align 4
    store i64* %2, i64** @b, align 8
    %4 = load i64*, i64** @a, align 8
    %ref4 = load i64, i64* %4, align 4
    %5 = add i64 %ref4, 1
    store i64 %5, i64* %4, align 4
    store i64* %4, i64** @c, align 8
    %6 = load i64*, i64** @b, align 8
    %ref6 = load i64, i64* %6, align 4
    %7 = add i64 %ref6, 1
    store i64 %7, i64* %6, align 4
    store i64* %6, i64** @d, align 8
    %8 = load i64*, i64** @a, align 8
    %ref8 = load i64, i64* %8, align 4
    %9 = icmp sgt i64 %ref8, 1
    br i1 %9, label %relocate, label %merge
  
  relocate:                                         ; preds = %entry
    %cap9 = getelementptr i64, i64* %8, i64 2
    %cap10 = load i64, i64* %cap9, align 4
    %10 = mul i64 %cap10, 8
    %11 = add i64 %10, 24
    %12 = tail call i8* @malloc(i64 %11)
    %13 = bitcast i8* %12 to i64*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %12, i8* %12, i64 %11, i1 false)
    store i64* %13, i64** @a, align 8
    %ref12 = load i64, i64* %8, align 4
    %14 = sub i64 %ref12, 1
    store i64 %14, i64* %8, align 4
    %.pre = load i64*, i64** @a, align 8
    br label %merge
  
  merge:                                            ; preds = %relocate, %entry
    %15 = phi i64* [ %.pre, %relocate ], [ %8, %entry ]
    %data13 = getelementptr i64, i64* %15, i64 3
    store i64 12, i64* %data13, align 4
    %16 = load i64*, i64** @a, align 8
    %data14 = getelementptr i64, i64* %16, i64 3
    %17 = load i64, i64* %data14, align 4
    %fmtsize = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %17)
    %18 = add i32 %fmtsize, 1
    %19 = sext i32 %18 to i64
    %20 = tail call i8* @malloc(i64 %19)
    %fmt = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %20, i64 %19, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %17)
    %str = alloca %string, align 8
    %cstr83 = bitcast %string* %str to i8**
    store i8* %20, i8** %cstr83, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    %21 = mul i64 %19, -1
    store i64 %21, i64* %length, align 4
    %unbox = bitcast %string* %str to { i64, i64 }*
    %22 = ptrtoint i8* %20 to i64
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    tail call void @schmu_print(i64 %22, i64 %21)
    %23 = load i64*, i64** @c, align 8
    %ref20 = load i64, i64* %23, align 4
    %24 = icmp sgt i64 %ref20, 1
    br i1 %24, label %relocate17, label %merge18
  
  relocate17:                                       ; preds = %merge
    %cap21 = getelementptr i64, i64* %23, i64 2
    %cap22 = load i64, i64* %cap21, align 4
    %25 = mul i64 %cap22, 8
    %26 = add i64 %25, 24
    %27 = tail call i8* @malloc(i64 %26)
    %28 = bitcast i8* %27 to i64*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %27, i8* %27, i64 %26, i1 false)
    store i64* %28, i64** @c, align 8
    %ref24 = load i64, i64* %23, align 4
    %29 = sub i64 %ref24, 1
    store i64 %29, i64* %23, align 4
    %.pre82 = load i64*, i64** @c, align 8
    br label %merge18
  
  merge18:                                          ; preds = %relocate17, %merge
    %30 = phi i64* [ %.pre82, %relocate17 ], [ %23, %merge ]
    %data25 = getelementptr i64, i64* %30, i64 3
    store i64 15, i64* %data25, align 4
    %31 = load i64*, i64** @a, align 8
    %data26 = getelementptr i64, i64* %31, i64 3
    %32 = load i64, i64* %data26, align 4
    %fmtsize27 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %32)
    %33 = add i32 %fmtsize27, 1
    %34 = sext i32 %33 to i64
    %35 = tail call i8* @malloc(i64 %34)
    %fmt28 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %35, i64 %34, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %32)
    %str29 = alloca %string, align 8
    %cstr3085 = bitcast %string* %str29 to i8**
    store i8* %35, i8** %cstr3085, align 8
    %length31 = getelementptr inbounds %string, %string* %str29, i32 0, i32 1
    %36 = mul i64 %34, -1
    store i64 %36, i64* %length31, align 4
    %unbox32 = bitcast %string* %str29 to { i64, i64 }*
    %37 = ptrtoint i8* %35 to i64
    %snd35 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox32, i32 0, i32 1
    tail call void @schmu_print(i64 %37, i64 %36)
    %38 = load i64*, i64** @b, align 8
    %data37 = getelementptr i64, i64* %38, i64 3
    %39 = load i64, i64* %data37, align 4
    %fmtsize38 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %39)
    %40 = add i32 %fmtsize38, 1
    %41 = sext i32 %40 to i64
    %42 = tail call i8* @malloc(i64 %41)
    %fmt39 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %42, i64 %41, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %39)
    %str40 = alloca %string, align 8
    %cstr4187 = bitcast %string* %str40 to i8**
    store i8* %42, i8** %cstr4187, align 8
    %length42 = getelementptr inbounds %string, %string* %str40, i32 0, i32 1
    %43 = mul i64 %41, -1
    store i64 %43, i64* %length42, align 4
    %unbox43 = bitcast %string* %str40 to { i64, i64 }*
    %44 = ptrtoint i8* %42 to i64
    %snd46 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox43, i32 0, i32 1
    tail call void @schmu_print(i64 %44, i64 %43)
    %45 = load i64*, i64** @c, align 8
    %data48 = getelementptr i64, i64* %45, i64 3
    %46 = load i64, i64* %data48, align 4
    %fmtsize49 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %46)
    %47 = add i32 %fmtsize49, 1
    %48 = sext i32 %47 to i64
    %49 = tail call i8* @malloc(i64 %48)
    %fmt50 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %49, i64 %48, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %46)
    %str51 = alloca %string, align 8
    %cstr5289 = bitcast %string* %str51 to i8**
    store i8* %49, i8** %cstr5289, align 8
    %length53 = getelementptr inbounds %string, %string* %str51, i32 0, i32 1
    %50 = mul i64 %48, -1
    store i64 %50, i64* %length53, align 4
    %unbox54 = bitcast %string* %str51 to { i64, i64 }*
    %51 = ptrtoint i8* %49 to i64
    %snd57 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox54, i32 0, i32 1
    tail call void @schmu_print(i64 %51, i64 %50)
    %52 = load i64*, i64** @d, align 8
    %data59 = getelementptr i64, i64* %52, i64 3
    %53 = load i64, i64* %data59, align 4
    %fmtsize60 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %53)
    %54 = add i32 %fmtsize60, 1
    %55 = sext i32 %54 to i64
    %56 = tail call i8* @malloc(i64 %55)
    %fmt61 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* %56, i64 %55, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %53)
    %str62 = alloca %string, align 8
    %cstr6391 = bitcast %string* %str62 to i8**
    store i8* %56, i8** %cstr6391, align 8
    %length64 = getelementptr inbounds %string, %string* %str62, i32 0, i32 1
    %57 = mul i64 %55, -1
    store i64 %57, i64* %length64, align 4
    %unbox65 = bitcast %string* %str62 to { i64, i64 }*
    %58 = ptrtoint i8* %56 to i64
    %snd68 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox65, i32 0, i32 1
    tail call void @schmu_print(i64 %58, i64 %57)
    tail call void @schmu_in-fun()
    %owned = icmp slt i64 %57, 0
    br i1 %owned, label %free, label %cont
  
  free:                                             ; preds = %merge18
    tail call void @free(i8* %56)
    br label %cont
  
  cont:                                             ; preds = %free, %merge18
    %owned72 = icmp slt i64 %50, 0
    br i1 %owned72, label %free70, label %cont71
  
  free70:                                           ; preds = %cont
    tail call void @free(i8* %49)
    br label %cont71
  
  cont71:                                           ; preds = %free70, %cont
    %owned75 = icmp slt i64 %43, 0
    br i1 %owned75, label %free73, label %cont74
  
  free73:                                           ; preds = %cont71
    tail call void @free(i8* %42)
    br label %cont74
  
  cont74:                                           ; preds = %free73, %cont71
    %owned78 = icmp slt i64 %36, 0
    br i1 %owned78, label %free76, label %cont77
  
  free76:                                           ; preds = %cont74
    tail call void @free(i8* %35)
    br label %cont77
  
  cont77:                                           ; preds = %free76, %cont74
    %owned81 = icmp slt i64 %21, 0
    br i1 %owned81, label %free79, label %cont80
  
  free79:                                           ; preds = %cont77
    tail call void @free(i8* %20)
    br label %cont80
  
  cont80:                                           ; preds = %free79, %cont77
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  12
  12
  10
  15
  10
  in fun
  12
  12
  10
  15
  10
