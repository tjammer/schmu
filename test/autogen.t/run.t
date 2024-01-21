Copy string literal
  $ schmu --dump-llvm string_lit.smu && valgrind -q --leak-check=yes --show-reachable=yes ./string_lit
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"test \00" }
  @1 = private unnamed_addr constant { i64, i64, [7 x i8] } { i64 6, i64 6, [7 x i8] c"%s%li\0A\00" }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*), i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac_(i8** %1)
    %4 = load i8*, i8** %1, align 8
    %5 = getelementptr i8, i8* %4, i64 16
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [7 x i8] }* @1 to i8*), i64 16), i8* %5, i64 1)
    call void @__free_ac_(i8** %1)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %newref = bitcast i8* %3 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr void @__free_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  test 1

Copy array of strings
  $ schmu --dump-llvm arr_of_strings.smu && valgrind -q --leak-check=yes --show-reachable=yes ./arr_of_strings
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global i8** null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"test\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"toast\00" }
  
  declare void @string_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 32)
    %1 = bitcast i8* %0 to i8**
    store i8** %1, i8*** @schmu_a, align 8
    %2 = bitcast i8** %1 to i64*
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to i8**
    %4 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i8** %4, align 8
    %5 = bitcast i8** %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %5, i64 8, i1 false)
    tail call void @__copy_ac_(i8** %data)
    %"1" = getelementptr i8*, i8** %data, i64 1
    %6 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @1 to i8*), i8** %6, align 8
    %7 = bitcast i8** %"1" to i8*
    %8 = bitcast i8** %6 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* %8, i64 8, i1 false)
    tail call void @__copy_ac_(i8** %"1")
    %9 = alloca i8**, align 8
    %10 = bitcast i8*** %9 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* bitcast (i8*** @schmu_a to i8*), i64 8, i1 false)
    call void @__copy_2ac2_(i8*** %9)
    %11 = load i8**, i8*** %9, align 8
    %12 = bitcast i8** %11 to i8*
    %13 = getelementptr i8, i8* %12, i64 16
    %data1 = bitcast i8* %13 to i8**
    %14 = getelementptr i8*, i8** %data1, i64 1
    %15 = load i8*, i8** %14, align 8
    call void @string_print(i8* %15)
    call void @__free_2ac2_(i8*** %9)
    call void @__free_2ac2_(i8*** @schmu_a)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %newref = bitcast i8* %3 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__copy_2ac2_(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i8**
    %6 = bitcast i8** %5 to i8*
    %7 = bitcast i8** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 %3, i1 false)
    %newref = bitcast i8** %5 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    store i8** %5, i8*** %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %8 = load i64, i64* %cnt, align 8
    %9 = icmp slt i64 %8, %size
    br i1 %9, label %child, label %cont
  
  child:                                            ; preds = %rec
    %10 = bitcast i8** %1 to i8*
    %11 = getelementptr i8, i8* %10, i64 16
    %data = bitcast i8* %11 to i8**
    %12 = getelementptr i8*, i8** %data, i64 %8
    call void @__copy_ac_(i8** %12)
    %13 = add i64 %8, 1
    store i64 %13, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define linkonce_odr void @__free_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_2ac2_(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
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
    %4 = bitcast i8** %1 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data = bitcast i8* %5 to i8**
    %6 = getelementptr i8*, i8** %data, i64 %2
    call void @__free_ac_(i8** %6)
    %7 = add i64 %2, 1
    store i64 %7, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast i8** %1 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  toast

Copy records
  $ schmu --dump-llvm records.smu && valgrind -q --leak-check=yes --show-reachable=yes ./records
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %dac_lal3_ = type { %dac_lal2_ }
  %dac_lal2_ = type { double, i8*, i64, i64* }
  
  @schmu_a = global %dac_lal3_ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"lul\00" }
  
  declare void @string_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store double 1.000000e+01, double* getelementptr inbounds (%dac_lal3_, %dac_lal3_* @schmu_a, i32 0, i32 0, i32 0), align 8
    %0 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*), i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac_(i8** %1)
    %4 = load i8*, i8** %1, align 8
    store i8* %4, i8** getelementptr inbounds (%dac_lal3_, %dac_lal3_* @schmu_a, i32 0, i32 0, i32 1), align 8
    store i64 10, i64* getelementptr inbounds (%dac_lal3_, %dac_lal3_* @schmu_a, i32 0, i32 0, i32 2), align 8
    %5 = call i8* @malloc(i64 40)
    %6 = bitcast i8* %5 to i64*
    %arr = alloca i64*, align 8
    store i64* %6, i64** %arr, align 8
    store i64 3, i64* %6, align 8
    %cap = getelementptr i64, i64* %6, i64 1
    store i64 3, i64* %cap, align 8
    %7 = getelementptr i8, i8* %5, i64 16
    %data = bitcast i8* %7 to i64*
    store i64 10, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 20, i64* %"1", align 8
    %"2" = getelementptr i64, i64* %data, i64 2
    store i64 30, i64* %"2", align 8
    store i64* %6, i64** getelementptr inbounds (%dac_lal3_, %dac_lal3_* @schmu_a, i32 0, i32 0, i32 3), align 8
    %8 = alloca %dac_lal3_, align 8
    %9 = bitcast %dac_lal3_* %8 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %9, i8* bitcast (%dac_lal3_* @schmu_a to i8*), i64 32, i1 false)
    call void @__copy_dac_lal3_(%dac_lal3_* %8)
    %10 = bitcast %dac_lal3_* %8 to %dac_lal2_*
    %11 = getelementptr inbounds %dac_lal2_, %dac_lal2_* %10, i32 0, i32 1
    %12 = load i8*, i8** %11, align 8
    call void @string_print(i8* %12)
    call void @__free_dac_lal3_(%dac_lal3_* %8)
    call void @__free_dac_lal3_(%dac_lal3_* @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %newref = bitcast i8* %3 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_dac_lal2_(%dac_lal2_* %0) {
  entry:
    %1 = getelementptr inbounds %dac_lal2_, %dac_lal2_* %0, i32 0, i32 1
    call void @__copy_ac_(i8** %1)
    %2 = getelementptr inbounds %dac_lal2_, %dac_lal2_* %0, i32 0, i32 3
    call void @__copy_al_(i64** %2)
    ret void
  }
  
  define linkonce_odr void @__copy_al_(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz1 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = bitcast i64* %5 to i8*
    %7 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 %3, i1 false)
    %newcap = getelementptr i64, i64* %5, i64 1
    store i64 %size, i64* %newcap, align 8
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_dac_lal3_(%dac_lal3_* %0) {
  entry:
    %1 = bitcast %dac_lal3_* %0 to %dac_lal2_*
    call void @__copy_dac_lal2_(%dac_lal2_* %1)
    ret void
  }
  
  define linkonce_odr void @__free_dac_lal2_(%dac_lal2_* %0) {
  entry:
    %1 = getelementptr inbounds %dac_lal2_, %dac_lal2_* %0, i32 0, i32 1
    call void @__free_ac_(i8** %1)
    %2 = getelementptr inbounds %dac_lal2_, %dac_lal2_* %0, i32 0, i32 3
    call void @__free_al_(i64** %2)
    ret void
  }
  
  define linkonce_odr void @__free_al_(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_dac_lal3_(%dac_lal3_* %0) {
  entry:
    %1 = bitcast %dac_lal3_* %0 to %dac_lal2_*
    call void @__free_dac_lal2_(%dac_lal2_* %1)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  lul

Copy variants
  $ schmu variants.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./variants
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vac_l2_ = type { i32, %ac_l_ }
  %ac_l_ = type { i8*, i64 }
  
  @schmu_a = global %vac_l2_ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"thing\00" }
  
  declare void @string_print(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    store i32 0, i32* getelementptr inbounds (%vac_l2_, %vac_l2_* @schmu_a, i32 0, i32 0), align 4
    %0 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*), i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac_(i8** %1)
    %4 = load i8*, i8** %1, align 8
    store i8* %4, i8** getelementptr inbounds (%vac_l2_, %vac_l2_* @schmu_a, i32 0, i32 1, i32 0), align 8
    store i64 0, i64* getelementptr inbounds (%vac_l2_, %vac_l2_* @schmu_a, i32 0, i32 1, i32 1), align 8
    %5 = alloca %vac_l2_, align 8
    %6 = bitcast %vac_l2_* %5 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* bitcast (%vac_l2_* @schmu_a to i8*), i64 24, i1 false)
    call void @__copy_vac_l2_(%vac_l2_* %5)
    %tag1 = bitcast %vac_l2_* %5 to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %vac_l2_, %vac_l2_* %5, i32 0, i32 1
    %7 = getelementptr inbounds %ac_l_, %ac_l_* %data, i32 0, i32 1
    %8 = bitcast %ac_l_* %data to i8**
    %9 = load i8*, i8** %8, align 8
    call void @string_print(i8* %9)
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    call void @__free_vac_l2_(%vac_l2_* %5)
    call void @__free_vac_l2_(%vac_l2_* @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %newref = bitcast i8* %3 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__copy_ac_l_(%ac_l_* %0) {
  entry:
    %1 = bitcast %ac_l_* %0 to i8**
    call void @__copy_ac_(i8** %1)
    ret void
  }
  
  define linkonce_odr void @__copy_vac_l2_(%vac_l2_* %0) {
  entry:
    %tag1 = bitcast %vac_l2_* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %vac_l2_, %vac_l2_* %0, i32 0, i32 1
    call void @__copy_ac_l_(%ac_l_* %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_ac_l_(%ac_l_* %0) {
  entry:
    %1 = bitcast %ac_l_* %0 to i8**
    call void @__free_ac_(i8** %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_vac_l2_(%vac_l2_* %0) {
  entry:
    %tag1 = bitcast %vac_l2_* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %vac_l2_, %vac_l2_* %0, i32 0, i32 1
    call void @__free_ac_l_(%ac_l_* %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  thing

Copy closures
  $ schmu --dump-llvm closure.smu && valgrind -q --leak-check=yes --show-reachable=yes ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %"2l_" = type { i64, i64 }
  %"2rl2_l_" = type { %closure, i64 }
  
  @schmu_c = global %closure zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"hello\00" }
  
  declare void @string_print(i8* %0)
  
  define void @__fun_schmu0(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i8** }*
    %a = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr, i32 0, i32 2
    %a1 = load i8**, i8*** %a, align 8
    %1 = bitcast i8** %a1 to i8*
    %2 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %2 to i8**
    %3 = load i8*, i8** %data, align 8
    tail call void @string_print(i8* %3)
    ret void
  }
  
  define i64 @schmu_capture(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64 }*
    %a = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr, i32 0, i32 2
    %a1 = load i64, i64* %a, align 8
    %add = add i64 %a1, 1
    ret i64 %add
  }
  
  define i64 @schmu_capture__2(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64 }*
    %a = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr, i32 0, i32 2
    %a1 = load i64, i64* %a, align 8
    %add = add i64 %a1, 1
    ret i64 %add
  }
  
  define void @schmu_hmm(%closure* noalias %0) {
  entry:
    %1 = alloca %"2l_", align 8
    %"01" = bitcast %"2l_"* %1 to i64*
    store i64 1, i64* %"01", align 8
    %"1" = getelementptr inbounds %"2l_", %"2l_"* %1, i32 0, i32 1
    store i64 0, i64* %"1", align 8
    %funptr2 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i8*)* @schmu_capture to i8*), i8** %funptr2, align 8
    %2 = tail call i8* @malloc(i64 24)
    %clsr_schmu_capture = bitcast i8* %2 to { i8*, i8*, i64 }*
    %a = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr_schmu_capture, i32 0, i32 2
    store i64 1, i64* %a, align 8
    %ctor3 = bitcast { i8*, i8*, i64 }* %clsr_schmu_capture to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_l_ to i8*), i8** %ctor3, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr_schmu_capture, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %2, i8** %envptr, align 8
    ret void
  }
  
  define void @schmu_hmm_move(%closure* noalias %0) {
  entry:
    %1 = alloca %"2l_", align 8
    %"01" = bitcast %"2l_"* %1 to i64*
    store i64 1, i64* %"01", align 8
    %"1" = getelementptr inbounds %"2l_", %"2l_"* %1, i32 0, i32 1
    store i64 0, i64* %"1", align 8
    %funptr2 = bitcast %closure* %0 to i8**
    store i8* bitcast (i64 (i8*)* @schmu_capture__2 to i8*), i8** %funptr2, align 8
    %2 = tail call i8* @malloc(i64 24)
    %clsr_schmu_capture__2 = bitcast i8* %2 to { i8*, i8*, i64 }*
    %a = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr_schmu_capture__2, i32 0, i32 2
    store i64 1, i64* %a, align 8
    %ctor3 = bitcast { i8*, i8*, i64 }* %clsr_schmu_capture__2 to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_l_ to i8*), i8** %ctor3, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64 }, { i8*, i8*, i64 }* %clsr_schmu_capture__2, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %2, i8** %envptr, align 8
    ret void
  }
  
  define void @schmu_test(%closure* noalias %0) {
  entry:
    %1 = tail call i8* @malloc(i64 24)
    %2 = bitcast i8* %1 to i8**
    %arr = alloca i8**, align 8
    store i8** %2, i8*** %arr, align 8
    %3 = bitcast i8** %2 to i64*
    store i64 1, i64* %3, align 8
    %cap = getelementptr i64, i64* %3, i64 1
    store i64 1, i64* %cap, align 8
    %4 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %4 to i8**
    %5 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*), i8** %5, align 8
    %6 = bitcast i8** %5 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %6, i64 8, i1 false)
    tail call void @__copy_ac_(i8** %data)
    %funptr1 = bitcast %closure* %0 to i8**
    store i8* bitcast (void (i8*)* @__fun_schmu0 to i8*), i8** %funptr1, align 8
    %7 = tail call i8* @malloc(i64 24)
    %clsr___fun_schmu0 = bitcast i8* %7 to { i8*, i8*, i8** }*
    %a = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr___fun_schmu0, i32 0, i32 2
    %8 = bitcast i8*** %a to i8*
    %9 = bitcast i8*** %arr to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 8, i1 false)
    tail call void @__copy_2ac2_(i8*** %a)
    %10 = load i8**, i8*** %a, align 8
    store i8** %10, i8*** %a, align 8
    %ctor2 = bitcast { i8*, i8*, i8** }* %clsr___fun_schmu0 to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_2ac3_ to i8*), i8** %ctor2, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %clsr___fun_schmu0, i32 0, i32 1
    store i8* bitcast (void (i8*)* @__dtor_2ac3_ to i8*), i8** %dtor, align 8
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    store i8* %7, i8** %envptr, align 8
    call void @__free_2ac2_(i8*** %arr)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr i8* @__ctor_l_(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64 }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, i64 }*
    %4 = bitcast { i8*, i8*, i64 }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64 }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %6 = bitcast { i8*, i8*, i64 }* %3 to i8*
    ret i8* %6
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__copy_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %newref = bitcast i8* %3 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_2ac2_(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i8**
    %6 = bitcast i8** %5 to i8*
    %7 = bitcast i8** %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 %3, i1 false)
    %newref = bitcast i8** %5 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    store i8** %5, i8*** %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %8 = load i64, i64* %cnt, align 8
    %9 = icmp slt i64 %8, %size
    br i1 %9, label %child, label %cont
  
  child:                                            ; preds = %rec
    %10 = bitcast i8** %1 to i8*
    %11 = getelementptr i8, i8* %10, i64 16
    %data = bitcast i8* %11 to i8**
    %12 = getelementptr i8*, i8** %data, i64 %8
    call void @__copy_ac_(i8** %12)
    %13 = add i64 %8, 1
    store i64 %13, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define linkonce_odr i8* @__ctor_2ac3_(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i8** }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, i8** }*
    %4 = bitcast { i8*, i8*, i8** }* %3 to i8*
    %5 = bitcast { i8*, i8*, i8** }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %a = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %3, i32 0, i32 2
    call void @__copy_2ac2_(i8*** %a)
    %6 = bitcast { i8*, i8*, i8** }* %3 to i8*
    ret i8* %6
  }
  
  define linkonce_odr void @__dtor_2ac3_(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i8** }*
    %a = getelementptr inbounds { i8*, i8*, i8** }, { i8*, i8*, i8** }* %1, i32 0, i32 2
    call void @__free_2ac2_(i8*** %a)
    call void @free(i8* %0)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_2ac2_(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
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
    %4 = bitcast i8** %1 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data = bitcast i8* %5 to i8**
    %6 = getelementptr i8*, i8** %data, i64 %2
    call void @__free_ac_(i8** %6)
    %7 = add i64 %2, 1
    store i64 %7, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast i8** %1 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    ret void
  }
  
  declare void @free(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca %"2rl2_l_", align 8
    %"08" = bitcast %"2rl2_l_"* %0 to %closure*
    %clstmp = alloca %closure, align 8
    %funptr9 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%closure*)* @schmu_hmm to i8*), i8** %funptr9, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %1 = bitcast %closure* %"08" to i8*
    %2 = bitcast %closure* %clstmp to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 16, i1 false)
    call void @__copy_2rl2_(%closure* %"08")
    %"1" = getelementptr inbounds %"2rl2_l_", %"2rl2_l_"* %0, i32 0, i32 1
    store i64 0, i64* %"1", align 8
    %3 = alloca %"2rl2_l_", align 8
    %"0110" = bitcast %"2rl2_l_"* %3 to %closure*
    %clstmp2 = alloca %closure, align 8
    %funptr311 = bitcast %closure* %clstmp2 to i8**
    store i8* bitcast (void (%closure*)* @schmu_hmm_move to i8*), i8** %funptr311, align 8
    %envptr4 = getelementptr inbounds %closure, %closure* %clstmp2, i32 0, i32 1
    store i8* null, i8** %envptr4, align 8
    %4 = bitcast %closure* %"0110" to i8*
    %5 = bitcast %closure* %clstmp2 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 16, i1 false)
    call void @__copy_2rl2_(%closure* %"0110")
    %"15" = getelementptr inbounds %"2rl2_l_", %"2rl2_l_"* %3, i32 0, i32 1
    store i64 0, i64* %"15", align 8
    call void @schmu_test(%closure* @schmu_c)
    %6 = alloca %closure, align 8
    %7 = bitcast %closure* %6 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* bitcast (%closure* @schmu_c to i8*), i64 16, i1 false)
    call void @__copy_ru_(%closure* %6)
    %funcptr12 = bitcast %closure* %6 to i8**
    %loadtmp = load i8*, i8** %funcptr12, align 8
    %casttmp = bitcast i8* %loadtmp to void (i8*)*
    %envptr6 = getelementptr inbounds %closure, %closure* %6, i32 0, i32 1
    %loadtmp7 = load i8*, i8** %envptr6, align 8
    call void %casttmp(i8* %loadtmp7)
    call void @__free_ru_(%closure* %6)
    call void @__free_ru_(%closure* @schmu_c)
    call void @__free_2rl2_l_(%"2rl2_l_"* %3)
    call void @__free_2rl2_l_(%"2rl2_l_"* %0)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_2rl2_(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__copy_ru_(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__free_ru_(%closure* %0) {
  entry:
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %env = load i8*, i8** %envptr, align 8
    %1 = icmp eq i8* %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = bitcast i8* %env to { i8*, i8* }*
    %3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %2, i32 0, i32 1
    %dtor1 = load i8*, i8** %3, align 8
    %4 = icmp eq i8* %dtor1, null
    br i1 %4, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    %dtor2 = bitcast i8* %dtor1 to void (i8*)*
    call void %dtor2(i8* %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(i8* %env)
    br label %ret
  }
  
  define linkonce_odr void @__free_2rl2_(%closure* %0) {
  entry:
    %envptr = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %env = load i8*, i8** %envptr, align 8
    %1 = icmp eq i8* %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = bitcast i8* %env to { i8*, i8* }*
    %3 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %2, i32 0, i32 1
    %dtor1 = load i8*, i8** %3, align 8
    %4 = icmp eq i8* %dtor1, null
    br i1 %4, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    %dtor2 = bitcast i8* %dtor1 to void (i8*)*
    call void %dtor2(i8* %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(i8* %env)
    br label %ret
  }
  
  define linkonce_odr void @__free_2rl2_l_(%"2rl2_l_"* %0) {
  entry:
    %1 = bitcast %"2rl2_l_"* %0 to %closure*
    call void @__free_2rl2_(%closure* %1)
    ret void
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  hello

Copy string literal on move
  $ schmu copy_string_lit.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./copy_string_lit
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  
  @schmu_a = global i8** null, align 8
  @schmu_b = global i8* null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"aoeu\00" }
  
  declare void @string_print(i8* %0)
  
  declare void @string_modify_buf(i8** noalias %0, %closure* %1)
  
  define void @__fun_schmu0(i8** noalias %arr) {
  entry:
    %0 = load i8*, i8** %arr, align 8
    %1 = getelementptr i8, i8* %0, i64 16
    %2 = getelementptr inbounds i8, i8* %1, i64 1
    store i8 105, i8* %2, align 1
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @malloc(i64 24)
    %1 = bitcast i8* %0 to i8**
    store i8** %1, i8*** @schmu_a, align 8
    %2 = bitcast i8** %1 to i64*
    store i64 1, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %cap, align 8
    %3 = getelementptr i8, i8* %0, i64 16
    %data = bitcast i8* %3 to i8**
    %4 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i8** %4, align 8
    %5 = bitcast i8** %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %5, i64 8, i1 false)
    tail call void @__copy_ac_(i8** %data)
    %6 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i8** %6, align 8
    %7 = bitcast i8** %6 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (i8** @schmu_b to i8*), i8* %7, i64 8, i1 false)
    tail call void @__copy_ac_(i8** @schmu_b)
    %clstmp = alloca %closure, align 8
    %funptr2 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i8**)* @__fun_schmu0 to i8*), i8** %funptr2, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @string_modify_buf(i8** @schmu_b, %closure* %clstmp)
    %8 = load i8*, i8** @schmu_b, align 8
    call void @string_print(i8* %8)
    call void @string_print(i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*))
    %9 = load i8**, i8*** @schmu_a, align 8
    %10 = bitcast i8** %9 to i8*
    %11 = getelementptr i8, i8* %10, i64 16
    %data1 = bitcast i8* %11 to i8**
    %12 = load i8*, i8** %data1, align 8
    call void @string_print(i8* %12)
    call void @__free_ac_(i8** @schmu_b)
    call void @__free_2ac2_(i8*** @schmu_a)
    ret i64 0
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %newref = bitcast i8* %3 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_ac_(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_2ac2_(i8*** %0) {
  entry:
    %1 = load i8**, i8*** %0, align 8
    %ref = bitcast i8** %1 to i64*
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
    %4 = bitcast i8** %1 to i8*
    %5 = getelementptr i8, i8* %4, i64 16
    %data = bitcast i8* %5 to i8**
    %6 = getelementptr i8*, i8** %data, i64 %2
    call void @__free_ac_(i8** %6)
    %7 = add i64 %2, 1
    store i64 %7, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %8 = bitcast i8** %1 to i64*
    %9 = bitcast i64* %8 to i8*
    call void @free(i8* %9)
    ret void
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  aieu
  aoeu
  aoeu

Correctly copy array
  $ schmu copy_array.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./copy_array
