Test simple setting of mutable variables
  $ schmu --dump-llvm simple_set.smu && valgrind -q --leak-check=yes --show-reachable=yes ./simple_set
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_b = global i64 0, align 8
  @schmu_a = global i64** null, align 8
  @schmu_b__2 = global i64** null, align 8
  @schmu_c = global i64* null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @schmu_hmm() {
  entry:
    %0 = alloca i64, align 8
    store i64 10, i64* %0, align 8
    store i64 15, i64* %0, align 8
    ret i64 15
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 10, i64* @schmu_b, align 8
    store i64 14, i64* @schmu_b, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 14)
    %0 = tail call i64 @schmu_hmm()
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %0)
    %1 = tail call i8* @malloc(i64 32)
    %2 = bitcast i8* %1 to i64**
    store i64** %2, i64*** @schmu_a, align 8
    %3 = bitcast i64** %2 to i64*
    store i64 2, i64* %3, align 8
    %cap = getelementptr i64, i64* %3, i64 1
    store i64 2, i64* %cap, align 8
    %4 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %4 to i64**
    %5 = tail call i8* @malloc(i64 24)
    %6 = bitcast i8* %5 to i64*
    store i64* %6, i64** %data, align 8
    store i64 1, i64* %6, align 8
    %cap2 = getelementptr i64, i64* %6, i64 1
    store i64 1, i64* %cap2, align 8
    %7 = getelementptr i8, i8* %5, i64 16
    %data3 = bitcast i8* %7 to i64*
    store i64 10, i64* %data3, align 8
    %"1" = getelementptr i64*, i64** %data, i64 1
    %8 = tail call i8* @malloc(i64 24)
    %9 = bitcast i8* %8 to i64*
    store i64* %9, i64** %"1", align 8
    store i64 1, i64* %9, align 8
    %cap6 = getelementptr i64, i64* %9, i64 1
    store i64 1, i64* %cap6, align 8
    %10 = getelementptr i8, i8* %8, i64 16
    %data7 = bitcast i8* %10 to i64*
    store i64 20, i64* %data7, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (i64*** @schmu_b__2 to i8*), i8* bitcast (i64*** @schmu_a to i8*), i64 8, i1 false)
    tail call void @__copy_aai(i64*** @schmu_b__2)
    %11 = tail call i8* @malloc(i64 24)
    %12 = bitcast i8* %11 to i64*
    store i64* %12, i64** @schmu_c, align 8
    store i64 1, i64* %12, align 8
    %cap10 = getelementptr i64, i64* %12, i64 1
    store i64 1, i64* %cap10, align 8
    %13 = getelementptr i8, i8* %11, i64 16
    %data11 = bitcast i8* %13 to i64*
    store i64 30, i64* %data11, align 8
    %14 = load i64**, i64*** @schmu_a, align 8
    %15 = bitcast i64** %14 to i8*
    %16 = getelementptr i8, i8* %15, i64 16
    %data13 = bitcast i8* %16 to i64**
    %17 = alloca i64*, align 8
    %18 = bitcast i64** %17 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %18, i8* bitcast (i64** @schmu_c to i8*), i64 8, i1 false)
    call void @__copy_ai(i64** %17)
    call void @__free_ai(i64** %data13)
    %19 = load i64*, i64** %17, align 8
    store i64* %19, i64** %data13, align 8
    %20 = load i64**, i64*** @schmu_a, align 8
    %21 = bitcast i64** %20 to i8*
    %22 = getelementptr i8, i8* %21, i64 16
    %data14 = bitcast i8* %22 to i64**
    %23 = call i8* @malloc(i64 24)
    %24 = bitcast i8* %23 to i64*
    %arr = alloca i64*, align 8
    store i64* %24, i64** %arr, align 8
    store i64 1, i64* %24, align 8
    %cap16 = getelementptr i64, i64* %24, i64 1
    store i64 1, i64* %cap16, align 8
    %25 = getelementptr i8, i8* %23, i64 16
    %data17 = bitcast i8* %25 to i64*
    store i64 10, i64* %data17, align 8
    call void @__free_ai(i64** %data14)
    store i64* %24, i64** %data14, align 8
    call void @__free_ai(i64** @schmu_c)
    call void @__free_aai(i64*** @schmu_b__2)
    call void @__free_aai(i64*** @schmu_a)
    ret i64 0
  }
  
  declare void @printf(i8* %0, ...)
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz2 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %sz2 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %ref, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64**
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64** %5 to i8*
    %9 = bitcast i64** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64** %5, i64*** %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %10 = load i64, i64* %cnt, align 8
    %11 = icmp slt i64 %10, %size
    br i1 %11, label %child, label %cont
  
  child:                                            ; preds = %rec
    %12 = bitcast i64** %1 to i8*
    %13 = mul i64 8, %10
    %14 = add i64 16, %13
    %15 = getelementptr i8, i8* %12, i64 %14
    %data = bitcast i8* %15 to i64**
    call void @__copy_ai(i64** %data)
    %16 = add i64 %10, 1
    store i64 %16, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast i64** %1 to i8*
    %5 = mul i64 8, %2
    %6 = add i64 16, %5
    %7 = getelementptr i8, i8* %4, i64 %6
    %data = bitcast i8* %7 to i64**
    call void @__free_ai(i64** %data)
    %8 = add i64 %2, 1
    store i64 %8, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %9 = bitcast i64** %1 to i64*
    %10 = bitcast i64* %9 to i8*
    call void @free(i8* %10)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  14
  15

Warn on unneeded mutable bindings
  $ schmu unneeded_mut.smu
  unneeded_mut.smu:1.19-20: warning: Unmutated mutable binding a
  1 | (defn do_nothing [a&]
                        ^
  
  unneeded_mut.smu:1.7-17: warning: Unused binding do_nothing
  1 | (defn do_nothing [a&]
            ^^^^^^^^^^
  
  unneeded_mut.smu:7.6-7: warning: Unmutated mutable binding b
  7 | (def b& 0)
           ^
  
Use mutable values as ptrs to C code
  $ schmu -c --dump-llvm ptr_to_c.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  
  @schmu_i = global i64 0, align 8
  @schmu_foo = global %foo zeroinitializer, align 8
  
  declare void @mutate_int(i64* noalias %0)
  
  declare void @mutate_foo(%foo* noalias %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* @schmu_i, align 8
    tail call void @mutate_int(i64* @schmu_i)
    store i64 0, i64* getelementptr inbounds (%foo, %foo* @schmu_foo, i32 0, i32 0), align 8
    tail call void @mutate_foo(%foo* @schmu_foo)
    ret i64 0
  }

Check aliasing
  $ schmu --dump-llvm mut_alias.smu && valgrind -q --leak-check=yes --show-reachable=yes ./mut_alias
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  
  @schmu_f = global %foo zeroinitializer, align 8
  @schmu_fst = global %foo zeroinitializer, align 8
  @schmu_snd = global %foo zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define void @schmu_new-fun() {
  entry:
    %0 = alloca %foo, align 8
    %a1 = bitcast %foo* %0 to i64*
    store i64 0, i64* %a1, align 8
    %1 = alloca %foo, align 8
    %2 = bitcast %foo* %1 to i8*
    %3 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    %4 = alloca %foo, align 8
    %5 = bitcast %foo* %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %2, i64 8, i1 false)
    %6 = bitcast %foo* %1 to i64*
    store i64 1, i64* %6, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 1)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 0)
    %7 = bitcast %foo* %4 to i64*
    %8 = load i64, i64* %7, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %8)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(i8* %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* getelementptr inbounds (%foo, %foo* @schmu_f, i32 0, i32 0), align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%foo* @schmu_fst to i8*), i8* bitcast (%foo* @schmu_f to i8*), i64 8, i1 false)
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%foo* @schmu_snd to i8*), i8* bitcast (%foo* @schmu_fst to i8*), i64 8, i1 false)
    store i64 1, i64* getelementptr inbounds (%foo, %foo* @schmu_fst, i32 0, i32 0), align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 1)
    %0 = load i64, i64* getelementptr inbounds (%foo, %foo* @schmu_f, i32 0, i32 0), align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %0)
    %1 = load i64, i64* getelementptr inbounds (%foo, %foo* @schmu_snd, i32 0, i32 0), align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %1)
    tail call void @schmu_new-fun()
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  1
  0
  0
  1
  0
  0

Const let
  $ schmu --dump-llvm const_let.smu && valgrind -q --leak-check=yes --show-reachable=yes ./const_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_v = global i64* null, align 8
  @schmu_const = global i64 0, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define void @schmu_in-fun() {
  entry:
    %0 = alloca i64*, align 8
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** %0, align 8
    store i64 1, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 0, i64* %data, align 8
    %4 = load i64*, i64** %0, align 8
    %5 = bitcast i64* %4 to i8*
    %6 = getelementptr i8, i8* %5, i64 16
    %data1 = bitcast i8* %6 to i64*
    %7 = alloca i64, align 8
    %8 = load i64, i64* %data1, align 8
    store i64 %8, i64* %7, align 8
    store i64 1, i64* %data1, align 8
    %9 = load i64*, i64** %0, align 8
    %10 = bitcast i64* %9 to i8*
    %11 = getelementptr i8, i8* %10, i64 16
    %data3 = bitcast i8* %11 to i64*
    %12 = load i64, i64* %data3, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %12)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %8)
    call void @__free_ai(i64** %0)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @schmu_v, align 8
    store i64 1, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 0, i64* %data, align 8
    %3 = load i64*, i64** @schmu_v, align 8
    %4 = bitcast i64* %3 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data1 = bitcast i8* %5 to i64*
    %6 = load i64, i64* %data1, align 8
    store i64 %6, i64* @schmu_const, align 8
    store i64 1, i64* %data1, align 8
    %7 = load i64*, i64** @schmu_v, align 8
    %8 = bitcast i64* %7 to i8*
    %9 = getelementptr i8, i8* %8, i64 16
    %data3 = bitcast i8* %9 to i64*
    %10 = load i64, i64* %data3, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %10)
    %11 = load i64, i64* @schmu_const, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %11)
    tail call void @schmu_in-fun()
    tail call void @__free_ai(i64** @schmu_v)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  1
  0
  1
  0


Copies, but with ref-counted arrays
  $ schmu array_copies.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./array_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global i64* null, align 8
  @schmu_b = global i64* null, align 8
  @schmu_c = global i64* null, align 8
  @schmu_d = global i64* null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [7 x i8] } { i64 6, i64 6, [7 x i8] c"in fun\00" }
  
  declare void @std_print(i8* %0)
  
  define linkonce_odr void @__ag.u_schmu_print-0th_ai.u(i64* %a) {
  entry:
    %0 = bitcast i64* %a to i8*
    %1 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %1 to i64*
    %2 = load i64, i64* %data, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %2)
    ret void
  }
  
  define void @schmu_in-fun() {
  entry:
    tail call void @std_print(i8* bitcast ({ i64, i64, [7 x i8] }* @1 to i8*))
    %0 = alloca i64*, align 8
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** %0, align 8
    store i64 1, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    %4 = alloca i64*, align 8
    %5 = bitcast i64** %4 to i8*
    %6 = bitcast i64** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 8, i1 false)
    call void @__copy_ai(i64** %4)
    %7 = alloca i64*, align 8
    %8 = bitcast i64** %7 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %6, i64 8, i1 false)
    call void @__copy_ai(i64** %7)
    %9 = load i64*, i64** %0, align 8
    %10 = bitcast i64* %9 to i8*
    %11 = getelementptr i8, i8* %10, i64 16
    %data1 = bitcast i8* %11 to i64*
    store i64 12, i64* %data1, align 8
    %12 = load i64*, i64** %0, align 8
    call void @__ag.u_schmu_print-0th_ai.u(i64* %12)
    %13 = load i64*, i64** %7, align 8
    %14 = bitcast i64* %13 to i8*
    %15 = getelementptr i8, i8* %14, i64 16
    %data2 = bitcast i8* %15 to i64*
    store i64 15, i64* %data2, align 8
    %16 = load i64*, i64** %0, align 8
    call void @__ag.u_schmu_print-0th_ai.u(i64* %16)
    %17 = load i64*, i64** %4, align 8
    call void @__ag.u_schmu_print-0th_ai.u(i64* %17)
    %18 = load i64*, i64** %7, align 8
    call void @__ag.u_schmu_print-0th_ai.u(i64* %18)
    %19 = load i64*, i64** %4, align 8
    call void @__ag.u_schmu_print-0th_ai.u(i64* %19)
    call void @__free_ai(i64** %7)
    call void @__free_ai(i64** %4)
    call void @__free_ai(i64** %0)
    ret void
  }
  
  declare void @printf(i8* %0, ...)
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz2 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @schmu_a, align 8
    store i64 1, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 10, i64* %data, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (i64** @schmu_b to i8*), i8* bitcast (i64** @schmu_a to i8*), i64 8, i1 false)
    tail call void @__copy_ai(i64** @schmu_b)
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (i64** @schmu_c to i8*), i8* bitcast (i64** @schmu_a to i8*), i64 8, i1 false)
    tail call void @__copy_ai(i64** @schmu_c)
    %3 = load i64*, i64** @schmu_b, align 8
    store i64* %3, i64** @schmu_d, align 8
    %4 = load i64*, i64** @schmu_a, align 8
    %5 = bitcast i64* %4 to i8*
    %6 = getelementptr i8, i8* %5, i64 16
    %data1 = bitcast i8* %6 to i64*
    store i64 12, i64* %data1, align 8
    %7 = load i64*, i64** @schmu_a, align 8
    tail call void @__ag.u_schmu_print-0th_ai.u(i64* %7)
    %8 = load i64*, i64** @schmu_c, align 8
    %9 = bitcast i64* %8 to i8*
    %10 = getelementptr i8, i8* %9, i64 16
    %data2 = bitcast i8* %10 to i64*
    store i64 15, i64* %data2, align 8
    %11 = load i64*, i64** @schmu_a, align 8
    tail call void @__ag.u_schmu_print-0th_ai.u(i64* %11)
    %12 = load i64*, i64** @schmu_b, align 8
    tail call void @__ag.u_schmu_print-0th_ai.u(i64* %12)
    %13 = load i64*, i64** @schmu_c, align 8
    tail call void @__ag.u_schmu_print-0th_ai.u(i64* %13)
    %14 = load i64*, i64** @schmu_d, align 8
    tail call void @__ag.u_schmu_print-0th_ai.u(i64* %14)
    tail call void @schmu_in-fun()
    tail call void @__free_ai(i64** @schmu_c)
    tail call void @__free_ai(i64** @schmu_b)
    tail call void @__free_ai(i64** @schmu_a)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
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

Arrays in records
  $ schmu array_in_record_copies.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./array_in_record_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %arrec = type { i64* }
  
  @schmu_a = global %arrec zeroinitializer, align 8
  @schmu_b = global %arrec zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [7 x i8] } { i64 6, i64 6, [7 x i8] c"in fun\00" }
  
  declare void @std_print(i8* %0)
  
  define void @schmu_in-fun() {
  entry:
    %0 = alloca %arrec, align 8
    %a5 = bitcast %arrec* %0 to i64**
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to i64*
    %arr = alloca i64*, align 8
    store i64* %2, i64** %arr, align 8
    store i64 1, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    store i64* %2, i64** %a5, align 8
    %4 = alloca %arrec, align 8
    %5 = bitcast %arrec* %4 to i8*
    %6 = bitcast %arrec* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 8, i1 false)
    call void @__copy_arrec(%arrec* %4)
    store i64 12, i64* %data, align 8
    %unbox = bitcast %arrec* %0 to i64*
    %unbox2 = load i64, i64* %unbox, align 8
    call void @schmu_print-thing(i64 %unbox2)
    %unbox3 = bitcast %arrec* %4 to i64*
    %unbox4 = load i64, i64* %unbox3, align 8
    call void @schmu_print-thing(i64 %unbox4)
    call void @__free_arrec(%arrec* %4)
    call void @__free_arrec(%arrec* %0)
    ret void
  }
  
  define void @schmu_print-thing(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %1 = inttoptr i64 %0 to i64*
    %2 = bitcast i64* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to i64*
    %4 = load i64, i64* %data, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %4)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz2 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_arrec(%arrec* %0) {
  entry:
    %1 = bitcast %arrec* %0 to i64**
    call void @__copy_ai(i64** %1)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_arrec(%arrec* %0) {
  entry:
    %1 = bitcast %arrec* %0 to i64**
    call void @__free_ai(i64** %1)
    ret void
  }
  
  declare void @printf(i8* %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 10, i64* %data, align 8
    store i64* %1, i64** getelementptr inbounds (%arrec, %arrec* @schmu_a, i32 0, i32 0), align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%arrec* @schmu_b to i8*), i8* bitcast (%arrec* @schmu_a to i8*), i64 8, i1 false)
    tail call void @__copy_arrec(%arrec* @schmu_b)
    %3 = load i64*, i64** getelementptr inbounds (%arrec, %arrec* @schmu_a, i32 0, i32 0), align 8
    %4 = bitcast i64* %3 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data1 = bitcast i8* %5 to i64*
    store i64 12, i64* %data1, align 8
    %unbox = load i64, i64* bitcast (%arrec* @schmu_a to i64*), align 8
    tail call void @schmu_print-thing(i64 %unbox)
    %unbox2 = load i64, i64* bitcast (%arrec* @schmu_b to i64*), align 8
    tail call void @schmu_print-thing(i64 %unbox2)
    tail call void @std_print(i8* bitcast ({ i64, i64, [7 x i8] }* @1 to i8*))
    tail call void @schmu_in-fun()
    tail call void @__free_arrec(%arrec* @schmu_b)
    tail call void @__free_arrec(%arrec* @schmu_a)
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  12
  10
  in fun
  12
  10

Nested arrays
  $ schmu nested_array.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./nested_array
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global i64** null, align 8
  @schmu_b = global i64** null, align 8
  @0 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"%li, %li\0A\00" }
  
  define linkonce_odr void @__aag.u_schmu_prnt_aai.u(i64** %a) {
  entry:
    %0 = bitcast i64** %a to i8*
    %1 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %1 to i64**
    %2 = load i64*, i64** %data, align 8
    %3 = bitcast i64* %2 to i8*
    %4 = getelementptr i8, i8* %3, i64 16
    %data1 = bitcast i8* %4 to i64*
    %5 = load i64, i64* %data1, align 8
    %6 = getelementptr i8, i8* %0, i64 24
    %data2 = bitcast i8* %6 to i64**
    %7 = load i64*, i64** %data2, align 8
    %8 = bitcast i64* %7 to i8*
    %9 = getelementptr i8, i8* %8, i64 16
    %data3 = bitcast i8* %9 to i64*
    %10 = load i64, i64* %data3, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [10 x i8] }* @0 to i8*), i64 16), i64 %5, i64 %10)
    ret void
  }
  
  declare void @printf(i8* %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i64**
    store i64** %1, i64*** @schmu_a, align 8
    %2 = bitcast i64** %1 to i64*
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to i64**
    %4 = tail call i8* @malloc(i64 24)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** %data, align 8
    store i64 1, i64* %5, align 8
    %cap2 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %cap2, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data3 = bitcast i8* %6 to i64*
    store i64 10, i64* %data3, align 8
    %"1" = getelementptr i64*, i64** %data, i64 1
    %7 = tail call i8* @malloc(i64 24)
    %8 = bitcast i8* %7 to i64*
    store i64* %8, i64** %"1", align 8
    store i64 1, i64* %8, align 8
    %cap6 = getelementptr i64, i64* %8, i64 1
    store i64 1, i64* %cap6, align 8
    %9 = getelementptr i8, i8* %7, i64 16
    %data7 = bitcast i8* %9 to i64*
    store i64 20, i64* %data7, align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (i64*** @schmu_b to i8*), i8* bitcast (i64*** @schmu_a to i8*), i64 8, i1 false)
    tail call void @__copy_aai(i64*** @schmu_b)
    %10 = load i64**, i64*** @schmu_a, align 8
    %11 = bitcast i64** %10 to i8*
    %12 = getelementptr i8, i8* %11, i64 16
    %data9 = bitcast i8* %12 to i64**
    %13 = load i64*, i64** %data9, align 8
    %14 = bitcast i64* %13 to i8*
    %15 = getelementptr i8, i8* %14, i64 16
    %data10 = bitcast i8* %15 to i64*
    store i64 15, i64* %data10, align 8
    %16 = load i64**, i64*** @schmu_a, align 8
    tail call void @__aag.u_schmu_prnt_aai.u(i64** %16)
    %17 = load i64**, i64*** @schmu_b, align 8
    tail call void @__aag.u_schmu_prnt_aai.u(i64** %17)
    tail call void @__free_aai(i64*** @schmu_b)
    tail call void @__free_aai(i64*** @schmu_a)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz2 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %sz2 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %ref, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64**
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64** %5 to i8*
    %9 = bitcast i64** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64** %5, i64*** %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %10 = load i64, i64* %cnt, align 8
    %11 = icmp slt i64 %10, %size
    br i1 %11, label %child, label %cont
  
  child:                                            ; preds = %rec
    %12 = bitcast i64** %1 to i8*
    %13 = mul i64 8, %10
    %14 = add i64 16, %13
    %15 = getelementptr i8, i8* %12, i64 %14
    %data = bitcast i8* %15 to i64**
    call void @__copy_ai(i64** %data)
    %16 = add i64 %10, 1
    store i64 %16, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast i64** %1 to i8*
    %5 = mul i64 8, %2
    %6 = add i64 16, %5
    %7 = getelementptr i8, i8* %4, i64 %6
    %data = bitcast i8* %7 to i64**
    call void @__free_ai(i64** %data)
    %8 = add i64 %2, 1
    store i64 %8, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %9 = bitcast i64** %1 to i64*
    %10 = bitcast i64* %9 to i8*
    call void @free(i8* %10)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  15, 20
  10, 20


Modify in function
  $ schmu --dump-llvm modify_in_fn.smu && valgrind -q --leak-check=yes --show-reachable=yes ./modify_in_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %f = type { i64 }
  
  @schmu_a = global %f zeroinitializer, align 8
  @schmu_b = global i64* null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define linkonce_odr void @__agg.u_array_push_aii.u(i64** noalias %arr, i64 %value) {
  entry:
    %0 = load i64*, i64** %arr, align 8
    %capacity = getelementptr i64, i64* %0, i64 1
    %1 = load i64, i64* %capacity, align 8
    %2 = load i64, i64* %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %mul = mul i64 2, %1
    %3 = mul i64 %mul, 8
    %4 = add i64 %3, 16
    %5 = bitcast i64* %0 to i8*
    %6 = tail call i8* @realloc(i8* %5, i64 %4)
    %7 = bitcast i8* %6 to i64*
    store i64* %7, i64** %arr, align 8
    %newcap = getelementptr i64, i64* %7, i64 1
    store i64 %mul, i64* %newcap, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %8 = phi i64* [ %7, %then ], [ %0, %entry ]
    %9 = bitcast i64* %8 to i8*
    %10 = getelementptr i8, i8* %9, i64 16
    %data = bitcast i8* %10 to i64*
    %11 = getelementptr inbounds i64, i64* %data, i64 %2
    store i64 %value, i64* %11, align 8
    %add = add i64 1, %2
    store i64 %add, i64* %8, align 8
    ret void
  }
  
  define void @schmu_mod2(i64** noalias %a) {
  entry:
    tail call void @__agg.u_array_push_aii.u(i64** %a, i64 20)
    ret void
  }
  
  define void @schmu_modify(%f* noalias %r) {
  entry:
    %0 = bitcast %f* %r to i64*
    store i64 30, i64* %0, align 8
    ret void
  }
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 20, i64* getelementptr inbounds (%f, %f* @schmu_a, i32 0, i32 0), align 8
    tail call void @schmu_modify(%f* @schmu_a)
    %0 = load i64, i64* getelementptr inbounds (%f, %f* @schmu_a, i32 0, i32 0), align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %0)
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** @schmu_b, align 8
    store i64 1, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 10, i64* %data, align 8
    tail call void @schmu_mod2(i64** @schmu_b)
    %4 = load i64*, i64** @schmu_b, align 8
    %5 = load i64, i64* %4, align 8
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %5)
    tail call void @__free_ai(i64** @schmu_b)
    ret i64 0
  }
  
  declare void @printf(i8* %0, ...)
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare void @free(i8* %0)
  30
  2

Make sure variable ids are correctly propagated
  $ schmu --dump-llvm varid_propagate.smu && valgrind -q --leak-check=yes --show-reachable=yes ./varid_propagate
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr i64* @__agg.ag_schmu_f1_aii.ai(i64* %acc, i64 %v) {
  entry:
    %0 = alloca i64*, align 8
    %1 = alloca i64*, align 8
    store i64* %acc, i64** %1, align 8
    %2 = bitcast i64** %0 to i8*
    %3 = bitcast i64** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ai(i64** %0)
    call void @__agg.u_array_push_aii.u(i64** %0, i64 %v)
    %4 = load i64*, i64** %0, align 8
    ret i64* %4
  }
  
  define linkonce_odr void @__agg.u_array_push_aii.u(i64** noalias %arr, i64 %value) {
  entry:
    %0 = load i64*, i64** %arr, align 8
    %capacity = getelementptr i64, i64* %0, i64 1
    %1 = load i64, i64* %capacity, align 8
    %2 = load i64, i64* %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %mul = mul i64 2, %1
    %3 = mul i64 %mul, 8
    %4 = add i64 %3, 16
    %5 = bitcast i64* %0 to i8*
    %6 = tail call i8* @realloc(i8* %5, i64 %4)
    %7 = bitcast i8* %6 to i64*
    store i64* %7, i64** %arr, align 8
    %newcap = getelementptr i64, i64* %7, i64 1
    store i64 %mul, i64* %newcap, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %8 = phi i64* [ %7, %then ], [ %0, %entry ]
    %9 = bitcast i64* %8 to i8*
    %10 = getelementptr i8, i8* %9, i64 16
    %data = bitcast i8* %10 to i64*
    %11 = getelementptr inbounds i64, i64* %data, i64 %2
    store i64 %value, i64* %11, align 8
    %add = add i64 1, %2
    store i64 %add, i64* %8, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz2 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i8* @realloc(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 0, i64* %data, align 8
    %3 = load i64*, i64** %arr, align 8
    %4 = tail call i64* @__agg.ag_schmu_f1_aii.ai(i64* %3, i64 0)
    %5 = alloca i64*, align 8
    store i64* %4, i64** %5, align 8
    call void @__free_ai(i64** %5)
    call void @__free_ai(i64** %arr)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }

Free array params correctly if they are returned
  $ schmu --dump-llvm pass_array_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./pass_array_param
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr i64* @__g.g_schmu_pass_ai.ai(i64* %x) {
  entry:
    ret i64* %x
  }
  
  define i64* @schmu_create() {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to i64*
    %arr = alloca i64*, align 8
    store i64* %1, i64** %arr, align 8
    store i64 1, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 10, i64* %data, align 8
    %3 = tail call i64* @__g.g_schmu_pass_ai.ai(i64* %1)
    ret i64* %3
  }
  
  declare i8* @malloc(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64* @schmu_create()
    %1 = alloca i64*, align 8
    store i64* %0, i64** %1, align 8
    call void @__free_ai(i64** %1)
    ret i64 0
  }
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare void @free(i8* %0)

Refcounts for members in arrays, records and variants
  $ schmu --dump-llvm member_refcounts.smu && valgrind -q --leak-check=yes --show-reachable=yes ./member_refcounts
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %r = type { i64* }
  %option.t_array_int = type { i32, i64* }
  
  @schmu_a = global i64* null, align 8
  @schmu_r = global %r zeroinitializer, align 8
  @schmu_r__2 = global i64** null, align 8
  @schmu_r__3 = global %option.t_array_int zeroinitializer, align 16
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  
  declare void @std_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to i64*
    store i64* %1, i64** @schmu_a, align 8
    store i64 1, i64* %1, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    store i64 1, i64* %cap, align 8
    %2 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %2 to i64*
    store i64 10, i64* %data, align 8
    %3 = alloca i64*, align 8
    %4 = bitcast i64** %3 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* bitcast (i64** @schmu_a to i8*), i64 8, i1 false)
    call void @__copy_ai(i64** %3)
    %5 = load i64*, i64** %3, align 8
    store i64* %5, i64** getelementptr inbounds (%r, %r* @schmu_r, i32 0, i32 0), align 8
    %6 = load i64*, i64** @schmu_a, align 8
    %7 = bitcast i64* %6 to i8*
    %8 = getelementptr i8, i8* %7, i64 16
    %data1 = bitcast i8* %8 to i64*
    store i64 20, i64* %data1, align 8
    %9 = load i64*, i64** getelementptr inbounds (%r, %r* @schmu_r, i32 0, i32 0), align 8
    %10 = bitcast i64* %9 to i8*
    %11 = getelementptr i8, i8* %10, i64 16
    %data2 = bitcast i8* %11 to i64*
    %12 = load i64, i64* %data2, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %12)
    %13 = call i8* @malloc(i64 24)
    %14 = bitcast i8* %13 to i64**
    store i64** %14, i64*** @schmu_r__2, align 8
    %15 = bitcast i64** %14 to i64*
    store i64 1, i64* %15, align 8
    %cap4 = getelementptr i64, i64* %15, i64 1
    store i64 1, i64* %cap4, align 8
    %16 = getelementptr i8, i8* %13, i64 16
    %data5 = bitcast i8* %16 to i64**
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %16, i8* bitcast (i64** @schmu_a to i8*), i64 8, i1 false)
    call void @__copy_ai(i64** %data5)
    %17 = load i64*, i64** @schmu_a, align 8
    %18 = bitcast i64* %17 to i8*
    %19 = getelementptr i8, i8* %18, i64 16
    %data7 = bitcast i8* %19 to i64*
    store i64 30, i64* %data7, align 8
    %20 = load i64**, i64*** @schmu_r__2, align 8
    %21 = bitcast i64** %20 to i8*
    %22 = getelementptr i8, i8* %21, i64 16
    %data8 = bitcast i8* %22 to i64**
    %23 = load i64*, i64** %data8, align 8
    %24 = bitcast i64* %23 to i8*
    %25 = getelementptr i8, i8* %24, i64 16
    %data9 = bitcast i8* %25 to i64*
    %26 = load i64, i64* %data9, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %26)
    store i32 0, i32* getelementptr inbounds (%option.t_array_int, %option.t_array_int* @schmu_r__3, i32 0, i32 0), align 4
    %27 = alloca i64*, align 8
    %28 = bitcast i64** %27 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %28, i8* bitcast (i64** @schmu_a to i8*), i64 8, i1 false)
    call void @__copy_ai(i64** %27)
    %29 = load i64*, i64** %27, align 8
    store i64* %29, i64** getelementptr inbounds (%option.t_array_int, %option.t_array_int* @schmu_r__3, i32 0, i32 1), align 8
    %30 = load i64*, i64** @schmu_a, align 8
    %31 = bitcast i64* %30 to i8*
    %32 = getelementptr i8, i8* %31, i64 16
    %data10 = bitcast i8* %32 to i64*
    store i64 40, i64* %data10, align 8
    %index = load i32, i32* getelementptr inbounds (%option.t_array_int, %option.t_array_int* @schmu_r__3, i32 0, i32 0), align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %33 = load i64*, i64** getelementptr inbounds (%option.t_array_int, %option.t_array_int* @schmu_r__3, i32 0, i32 1), align 8
    %34 = bitcast i64* %33 to i8*
    %35 = getelementptr i8, i8* %34, i64 16
    %data11 = bitcast i8* %35 to i64*
    %36 = load i64, i64* %data11, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %36)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @std_print(i8* bitcast ({ i64, i64, [5 x i8] }* @1 to i8*))
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    call void @__free_option.tai(%option.t_array_int* @schmu_r__3)
    call void @__free_aai(i64*** @schmu_r__2)
    call void @__free_r(%r* @schmu_r)
    call void @__free_ai(i64** @schmu_a)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz2 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %1, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = mul i64 %size, 8
    %7 = add i64 %6, 16
    %8 = bitcast i64* %5 to i8*
    %9 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_option.tai(%option.t_array_int* %0) {
  entry:
    %tag1 = bitcast %option.t_array_int* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t_array_int, %option.t_array_int* %0, i32 0, i32 1
    call void @__free_ai(i64** %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_aai(i64*** %0) {
  entry:
    %1 = load i64**, i64*** %0, align 8
    %ref = bitcast i64** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, i64* %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = bitcast i64** %1 to i8*
    %5 = mul i64 8, %2
    %6 = add i64 16, %5
    %7 = getelementptr i8, i8* %4, i64 %6
    %data = bitcast i8* %7 to i64**
    call void @__free_ai(i64** %data)
    %8 = add i64 %2, 1
    store i64 %8, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %9 = bitcast i64** %1 to i64*
    %10 = bitcast i64* %9 to i8*
    call void @free(i8* %10)
    ret void
  }
  
  define linkonce_odr void @__free_r(%r* %0) {
  entry:
    %1 = bitcast %r* %0 to i64**
    call void @__free_ai(i64** %1)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  10
  20
  30

Make sure there are no hidden reference semantics in pattern matches
  $ schmu hidden_match_reference.smu && ./hidden_match_reference
  1

Convert Const_ptr values to Ptr in copy
  $ schmu ref_to_const.smu
