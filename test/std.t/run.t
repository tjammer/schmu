Test hashtbl
  $ schmu hashtbl_test.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %hashtbl.make.t_float = type { %option.t_hashtbl.make.item_float*, i64 }
  %option.t_hashtbl.make.item_float = type { i32, %hashtbl.make.item_float }
  %hashtbl.make.item_float = type { i8*, double, i64, i1 }
  %tuple_int_bool = type { i64, i1 }
  %option.t_float = type { i32, double }
  %option.t_int = type { i32, i64 }
  
  @hashtbl_make_string_load-limit = constant double 7.500000e-01
  @0 = private unnamed_addr constant { i64, i64, [90 x i8] } { i64 89, i64 89, [90 x i8] c"__aoption.thashtbl.make.itemgi.u_hashtbl_make_string_fixup_aoption.thashtbl.make.itemfi.u\00" }
  @1 = private unnamed_addr constant { i64, i64, [12 x i8] } { i64 11, i64 11, [12 x i8] c"hashtbl.smu\00" }
  @2 = private unnamed_addr constant { i64, i64, [15 x i8] } { i64 14, i64 14, [15 x i8] c"file not found\00" }
  @3 = private unnamed_addr constant { i64, i64, [88 x i8] } { i64 87, i64 87, [88 x i8] c"__ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf\00" }
  @4 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"%.9g\0A\00" }
  @5 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  @6 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"## string\00" }
  @7 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"key\00" }
  @8 = private unnamed_addr constant { i64, i64, [9 x i8] } { i64 8, i64 8, [9 x i8] c"otherkey\00" }
  @9 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"# hashtbl\00" }
  
  declare void @string_print(i8* %0)
  
  declare void @prelude_iter-range(i64 %0, i64 %1, %closure* %2)
  
  declare i64 @string_hash(i8* %0)
  
  declare i1 @string_equal(i8* %0, i8* %1)
  
  declare i64 @abs(i64 %0)
  
  define linkonce_odr void @__acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf(i8* %key, double %value, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %hashtbl.make.t_float* }*
    %tbl = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %clsr, i32 0, i32 2
    %tbl1 = load %hashtbl.make.t_float*, %hashtbl.make.t_float** %tbl, align 8
    tail call void @__hashtbl.make.tgacg.u_hashtbl_make_string_insert_hashtbl.make.tfacf.u(%hashtbl.make.t_float* %tbl1, i8* %key, double %value)
    ret void
  }
  
  define linkonce_odr void @__agii.u_array_swap-items_aoption.thashtbl.make.itemfii.u(%option.t_hashtbl.make.item_float** noalias %arr, i64 %i, i64 %j) {
  entry:
    %eq = icmp eq i64 %i, %j
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %0 = alloca %option.t_hashtbl.make.item_float, align 8
    %1 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %arr, align 8
    %2 = bitcast %option.t_hashtbl.make.item_float* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to %option.t_hashtbl.make.item_float*
    %4 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %data, i64 %i
    %5 = bitcast %option.t_hashtbl.make.item_float* %0 to i8*
    %6 = bitcast %option.t_hashtbl.make.item_float* %4 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 40, i1 false)
    %7 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %data, i64 %j
    %8 = bitcast %option.t_hashtbl.make.item_float* %7 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %8, i64 40, i1 false)
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %5, i64 40, i1 false)
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    ret void
  }
  
  define linkonce_odr void @__aoption.thashtbl.make.itemgacg.u.u_hashtbl_make_string_iter-data-move_aoption.thashtbl.make.itemfacf.u.u(%option.t_hashtbl.make.item_float** noalias %data, %closure* %f) {
  entry:
    %__i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u to i8*), i8** %funptr5, align 8
    %clsr___i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u = alloca { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }, align 8
    %data1 = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }, { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %clsr___i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u, i32 0, i32 2
    store %option.t_hashtbl.make.item_float** %data, %option.t_hashtbl.make.item_float*** %data1, align 8
    %f2 = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }, { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %clsr___i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor6 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %clsr___i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-aoption.thashtbl.make.itemf-acf.u to i8*), i8** %ctor6, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }, { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %clsr___i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %clsr___i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u(i64 0, i8* %env)
    ret void
  }
  
  define linkonce_odr void @__aoption.thashtbl.make.itemgi.u_hashtbl_make_string_fixup_aoption.thashtbl.make.itemfi.u(%option.t_hashtbl.make.item_float** noalias %data, i64 %old) {
  entry:
    %0 = alloca %option.t_hashtbl.make.item_float**, align 8
    store %option.t_hashtbl.make.item_float** %data, %option.t_hashtbl.make.item_float*** %0, align 8
    %1 = alloca i1, align 1
    store i1 false, i1* %1, align 1
    %2 = alloca i64, align 8
    store i64 %old, i64* %2, align 8
    %ret = alloca %tuple_int_bool, align 8
    %3 = alloca %option.t_hashtbl.make.item_float, align 8
    %4 = alloca %hashtbl.make.item_float, align 8
    %t = alloca %option.t_hashtbl.make.item_float, align 8
    br label %rec
  
  rec:                                              ; preds = %ifcont21, %entry
    %5 = phi i64 [ %11, %ifcont21 ], [ %old, %entry ]
    %6 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %data, align 8
    %7 = bitcast %option.t_hashtbl.make.item_float* %6 to i64*
    %8 = load i64, i64* %7, align 8
    %9 = call { i64, i8 } @hashtbl_make_string_next-wrapped(i64 %5, i64 %8)
    %box = bitcast %tuple_int_bool* %ret to { i64, i8 }*
    store { i64, i8 } %9, { i64, i8 }* %box, align 8
    %10 = bitcast %tuple_int_bool* %ret to i64*
    %11 = load i64, i64* %10, align 8
    %12 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %data, align 8
    %13 = bitcast %option.t_hashtbl.make.item_float* %12 to i8*
    %14 = mul i64 40, %11
    %15 = add i64 16, %14
    %16 = getelementptr i8, i8* %13, i64 %15
    %data3 = bitcast i8* %16 to %option.t_hashtbl.make.item_float*
    %tag26 = bitcast %option.t_hashtbl.make.item_float* %data3 to i32*
    %index = load i32, i32* %tag26, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont24
  
  then:                                             ; preds = %rec
    %17 = bitcast %option.t_hashtbl.make.item_float* %12 to i8*
    %sunkaddr = getelementptr i8, i8* %17, i64 %14
    %sunkaddr27 = getelementptr i8, i8* %sunkaddr, i64 40
    %18 = bitcast i8* %sunkaddr27 to i64*
    %19 = load i64, i64* %18, align 8
    %eq5 = icmp eq i64 %19, %11
    br i1 %eq5, label %ifcont24, label %else
  
  else:                                             ; preds = %then
    %20 = bitcast %tuple_int_bool* %ret to i8*
    %sunkaddr28 = getelementptr inbounds i8, i8* %20, i64 8
    %21 = bitcast i8* %sunkaddr28 to i1*
    %22 = load i1, i1* %21, align 1
    br i1 %22, label %then7, label %ifcont21
  
  then7:                                            ; preds = %else
    %23 = bitcast %option.t_hashtbl.make.item_float* %12 to i8*
    %sunkaddr29 = getelementptr i8, i8* %23, i64 %14
    %sunkaddr30 = getelementptr i8, i8* %sunkaddr29, i64 48
    %24 = bitcast i8* %sunkaddr30 to i1*
    %25 = load i1, i1* %24, align 1
    br i1 %25, label %success, label %fail
  
  success:                                          ; preds = %then7
    %26 = bitcast %option.t_hashtbl.make.item_float* %12 to i8*
    %27 = getelementptr i8, i8* %26, i64 16
    %data8 = bitcast i8* %27 to %option.t_hashtbl.make.item_float*
    %28 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %data8, i64 %11
    %29 = bitcast %option.t_hashtbl.make.item_float* %3 to i8*
    %30 = bitcast %option.t_hashtbl.make.item_float* %28 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %29, i8* %30, i64 40, i1 false)
    %tag931 = bitcast %option.t_hashtbl.make.item_float* %3 to i32*
    %index10 = load i32, i32* %tag931, align 4
    %eq11 = icmp eq i32 %index10, 0
    br i1 %eq11, label %then12, label %else17
  
  fail:                                             ; preds = %then7
    call void @__assert_fail(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [15 x i8] }* @2 to i8*), i64 16), i8* getelementptr (i8, i8* bitcast ({ i64, i64, [12 x i8] }* @1 to i8*), i64 16), i32 150, i8* getelementptr (i8, i8* bitcast ({ i64, i64, [90 x i8] }* @0 to i8*), i64 16))
    unreachable
  
  then12:                                           ; preds = %success
    %31 = bitcast %option.t_hashtbl.make.item_float* %28 to i8*
    %data13 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %3, i32 0, i32 1
    %32 = bitcast %hashtbl.make.item_float* %4 to i8*
    %33 = bitcast %hashtbl.make.item_float* %data13 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %32, i8* %33, i64 32, i1 false)
    %tag1532 = bitcast %option.t_hashtbl.make.item_float* %t to i32*
    store i32 0, i32* %tag1532, align 4
    %data16 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %t, i32 0, i32 1
    %key33 = bitcast %hashtbl.make.item_float* %data16 to i8**
    %34 = bitcast %hashtbl.make.item_float* %4 to i8**
    %35 = load i8*, i8** %34, align 8
    store i8* %35, i8** %key33, align 8
    %value = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data16, i32 0, i32 1
    %36 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %4, i32 0, i32 1
    %37 = load double, double* %36, align 8
    store double %37, double* %value, align 8
    %hash = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data16, i32 0, i32 2
    %38 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %4, i32 0, i32 2
    %39 = load i64, i64* %38, align 8
    store i64 %39, i64* %hash, align 8
    %wrapped = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data16, i32 0, i32 3
    store i1 false, i1* %wrapped, align 1
    %40 = bitcast %option.t_hashtbl.make.item_float* %t to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %31, i8* %40, i64 40, i1 false)
    br label %ifcont21
  
  else17:                                           ; preds = %success
    call void @__assert_fail(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [15 x i8] }* @2 to i8*), i64 16), i8* getelementptr (i8, i8* bitcast ({ i64, i64, [12 x i8] }* @1 to i8*), i64 16), i32 161, i8* getelementptr (i8, i8* bitcast ({ i64, i64, [90 x i8] }* @0 to i8*), i64 16))
    unreachable
  
  ifcont21:                                         ; preds = %else, %then12
    call void @__agii.u_array_swap-items_aoption.thashtbl.make.itemfii.u(%option.t_hashtbl.make.item_float** %data, i64 %5, i64 %11)
    store %option.t_hashtbl.make.item_float** %data, %option.t_hashtbl.make.item_float*** %0, align 8
    store i64 %11, i64* %2, align 8
    br label %rec
  
  ifcont24:                                         ; preds = %rec, %then
    store i1 true, i1* %1, align 1
    ret void
  }
  
  define linkonce_odr double @__hashtbl.make.tg.f_hashtbl_make_string_load-factor_hashtbl.make.tf.f(i64 %0, i64 %1) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst2 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst2, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %tbl = bitcast { i64, i64 }* %box to %hashtbl.make.t_float*
    %2 = getelementptr inbounds %hashtbl.make.t_float, %hashtbl.make.t_float* %tbl, i32 0, i32 1
    %3 = sitofp i64 %1 to double
    %4 = inttoptr i64 %0 to %option.t_hashtbl.make.item_float*
    %5 = bitcast %option.t_hashtbl.make.item_float* %4 to i64*
    %6 = load i64, i64* %5, align 8
    %7 = sitofp i64 %6 to double
    %div = fdiv double %3, %7
    ret double %div
  }
  
  define linkonce_odr void @__hashtbl.make.tg.u_hashtbl_make_string_grow_hashtbl.make.tf.u(%hashtbl.make.t_float* noalias %tbl) {
  entry:
    %0 = bitcast %hashtbl.make.t_float* %tbl to %option.t_hashtbl.make.item_float**
    %1 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %0, align 8
    %2 = bitcast %option.t_hashtbl.make.item_float* %1 to i64*
    %3 = load i64, i64* %2, align 8
    %mul = mul i64 2, %3
    %4 = alloca %option.t_hashtbl.make.item_float*, align 8
    %5 = mul i64 %mul, 40
    %6 = add i64 16, %5
    %7 = tail call i8* @malloc(i64 %6)
    %8 = bitcast i8* %7 to %option.t_hashtbl.make.item_float*
    store %option.t_hashtbl.make.item_float* %8, %option.t_hashtbl.make.item_float** %4, align 8
    %9 = bitcast %option.t_hashtbl.make.item_float* %8 to i64*
    store i64 %mul, i64* %9, align 8
    %cap = getelementptr i64, i64* %9, i64 1
    store i64 %mul, i64* %cap, align 8
    %__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf = alloca %closure, align 8
    %funptr7 = bitcast %closure* %__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf to i8*), i8** %funptr7, align 8
    %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf = alloca { i8*, i8*, %option.t_hashtbl.make.item_float** }, align 8
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float** }, { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf, i32 0, i32 2
    store %option.t_hashtbl.make.item_float** %4, %option.t_hashtbl.make.item_float*** %_hashtbl_make_string_data, align 8
    %ctor8 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-aoption.thashtbl.make.itemf to i8*), i8** %ctor8, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float** }, { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @prelude_iter-range(i64 0, i64 %mul, %closure* %__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf)
    %10 = alloca %option.t_hashtbl.make.item_float*, align 8
    %11 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %0, align 8
    store %option.t_hashtbl.make.item_float* %11, %option.t_hashtbl.make.item_float** %10, align 8
    %12 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %4, align 8
    store %option.t_hashtbl.make.item_float* %12, %option.t_hashtbl.make.item_float** %0, align 8
    %13 = getelementptr inbounds %hashtbl.make.t_float, %hashtbl.make.t_float* %tbl, i32 0, i32 1
    store i64 0, i64* %13, align 8
    %__acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf = alloca %closure, align 8
    %funptr19 = bitcast %closure* %__acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf to i8**
    store i8* bitcast (void (i8*, double, i8*)* @__acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf to i8*), i8** %funptr19, align 8
    %clsr___acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf = alloca { i8*, i8*, %hashtbl.make.t_float* }, align 8
    %tbl2 = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %clsr___acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf, i32 0, i32 2
    store %hashtbl.make.t_float* %tbl, %hashtbl.make.t_float** %tbl2, align 8
    %ctor310 = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %clsr___acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-hashtbl.make.tf to i8*), i8** %ctor310, align 8
    %dtor4 = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %clsr___acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf, i32 0, i32 1
    store i8* null, i8** %dtor4, align 8
    %env5 = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %clsr___acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf to i8*
    %envptr6 = getelementptr inbounds %closure, %closure* %__acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf, i32 0, i32 1
    store i8* %env5, i8** %envptr6, align 8
    call void @__aoption.thashtbl.make.itemgacg.u.u_hashtbl_make_string_iter-data-move_aoption.thashtbl.make.itemfacf.u.u(%option.t_hashtbl.make.item_float** %10, %closure* %__acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf)
    call void @__free_aoption.thashtbl.make.itemf(%option.t_hashtbl.make.item_float** %10)
    ret void
  }
  
  define linkonce_odr i64 @__hashtbl.make.tgac.i_hashtbl_make_string_idx_hashtbl.make.tfac.i(i64 %0, i64 %1, i8* %key) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst2 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst2, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %2 = tail call i64 @string_hash(i8* %key)
    %3 = tail call i64 @abs(i64 %2)
    %4 = inttoptr i64 %0 to %option.t_hashtbl.make.item_float*
    %5 = bitcast %option.t_hashtbl.make.item_float* %4 to i64*
    %6 = load i64, i64* %5, align 8
    %mod = srem i64 %3, %6
    ret i64 %mod
  }
  
  define linkonce_odr void @__hashtbl.make.tgac.option.tg_hashtbl_make_string_find_hashtbl.make.tfac.option.tf(%option.t_float* noalias %0, i64 %1, i64 %2, i8* %key) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst21 = bitcast { i64, i64 }* %box to i64*
    store i64 %1, i64* %fst21, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %2, i64* %snd, align 8
    %3 = tail call i64 @__hashtbl.make.tgac.i_hashtbl_make_string_idx_hashtbl.make.tfac.i(i64 %1, i64 %2, i8* %key)
    %ret = alloca %option.t_int, align 8
    call void @__ihashtbl.make.tgacib.option.ti_hashtbl_make_string_find-index_ihashtbl.make.tfacib.option.ti(%option.t_int* %ret, i64 %3, i64 %1, i64 %2, i8* %key, i64 %3, i1 false)
    %tag22 = bitcast %option.t_int* %ret to i32*
    %index = load i32, i32* %tag22, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else19
  
  then:                                             ; preds = %entry
    %4 = inttoptr i64 %1 to %option.t_hashtbl.make.item_float*
    %data = getelementptr inbounds %option.t_int, %option.t_int* %ret, i32 0, i32 1
    %5 = load i64, i64* %data, align 8
    %6 = bitcast %option.t_hashtbl.make.item_float* %4 to i8*
    %7 = mul i64 40, %5
    %8 = add i64 16, %7
    %9 = getelementptr i8, i8* %6, i64 %8
    %data11 = bitcast i8* %9 to %option.t_hashtbl.make.item_float*
    %tag1223 = bitcast %option.t_hashtbl.make.item_float* %data11 to i32*
    %index13 = load i32, i32* %tag1223, align 4
    %eq14 = icmp eq i32 %index13, 0
    br i1 %eq14, label %then15, label %else
  
  then15:                                           ; preds = %then
    %tag1724 = bitcast %option.t_float* %0 to i32*
    store i32 0, i32* %tag1724, align 4
    %data18 = getelementptr inbounds %option.t_float, %option.t_float* %0, i32 0, i32 1
    %sunkaddr = inttoptr i64 %1 to double*
    %10 = bitcast double* %sunkaddr to i8*
    %sunkaddr25 = getelementptr i8, i8* %10, i64 %7
    %sunkaddr26 = getelementptr i8, i8* %sunkaddr25, i64 32
    %11 = bitcast i8* %sunkaddr26 to double*
    %12 = load double, double* %11, align 8
    store double %12, double* %data18, align 8
    store double %12, double* %data18, align 8
    br label %ifcont20
  
  else:                                             ; preds = %then
    store %option.t_float { i32 1, double undef }, %option.t_float* %0, align 8
    br label %ifcont20
  
  else19:                                           ; preds = %entry
    store %option.t_float { i32 1, double undef }, %option.t_float* %0, align 8
    br label %ifcont20
  
  ifcont20:                                         ; preds = %then15, %else, %else19
    ret void
  }
  
  define linkonce_odr void @__hashtbl.make.tgac.u_hashtbl_make_string_remove_hashtbl.make.tfac.u(%hashtbl.make.t_float* noalias %tbl, i8* %key) {
  entry:
    %unbox = bitcast %hashtbl.make.t_float* %tbl to { i64, i64 }*
    %fst9 = bitcast { i64, i64 }* %unbox to i64*
    %fst1 = load i64, i64* %fst9, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    %snd2 = load i64, i64* %snd, align 8
    %0 = tail call i64 @__hashtbl.make.tgac.i_hashtbl_make_string_idx_hashtbl.make.tfac.i(i64 %fst1, i64 %snd2, i8* %key)
    %ret = alloca %option.t_int, align 8
    call void @__ihashtbl.make.tgacib.option.ti_hashtbl_make_string_find-index_ihashtbl.make.tfacib.option.ti(%option.t_int* %ret, i64 %0, i64 %fst1, i64 %snd2, i8* %key, i64 %0, i1 false)
    %tag10 = bitcast %option.t_int* %ret to i32*
    %index = load i32, i32* %tag10, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %1 = inttoptr i64 %fst1 to %option.t_hashtbl.make.item_float*
    %data = getelementptr inbounds %option.t_int, %option.t_int* %ret, i32 0, i32 1
    %2 = bitcast %hashtbl.make.t_float* %tbl to %option.t_hashtbl.make.item_float**
    %3 = load i64, i64* %data, align 8
    %4 = bitcast %option.t_hashtbl.make.item_float* %1 to i8*
    %5 = mul i64 40, %3
    %6 = add i64 16, %5
    %7 = getelementptr i8, i8* %4, i64 %6
    %data8 = bitcast i8* %7 to %option.t_hashtbl.make.item_float*
    call void @__free_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %data8)
    store %option.t_hashtbl.make.item_float { i32 1, %hashtbl.make.item_float undef }, %option.t_hashtbl.make.item_float* %data8, align 8
    %8 = getelementptr inbounds %hashtbl.make.t_float, %hashtbl.make.t_float* %tbl, i32 0, i32 1
    %9 = load i64, i64* %8, align 8
    %sub = sub i64 %9, 1
    store i64 %sub, i64* %8, align 8
    %10 = load i64, i64* %data, align 8
    call void @__aoption.thashtbl.make.itemgi.u_hashtbl_make_string_fixup_aoption.thashtbl.make.itemfi.u(%option.t_hashtbl.make.item_float** %2, i64 %10)
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret void
  }
  
  define linkonce_odr void @__hashtbl.make.tgacg.u_hashtbl_make_string_insert_hashtbl.make.tfacf.u(%hashtbl.make.t_float* noalias %tbl, i8* %key, double %value) {
  entry:
    %unbox = bitcast %hashtbl.make.t_float* %tbl to { i64, i64 }*
    %fst13 = bitcast { i64, i64 }* %unbox to i64*
    %fst1 = load i64, i64* %fst13, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    %snd2 = load i64, i64* %snd, align 8
    %0 = tail call double @__hashtbl.make.tg.f_hashtbl_make_string_load-factor_hashtbl.make.tf.f(i64 %fst1, i64 %snd2)
    %gt = fcmp ogt double %0, 7.500000e-01
    br i1 %gt, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    tail call void @__hashtbl.make.tg.u_hashtbl_make_string_grow_hashtbl.make.tf.u(%hashtbl.make.t_float* %tbl)
    %1 = bitcast %hashtbl.make.t_float* %tbl to i64*
    %fst5.pre = load i64, i64* %1, align 8
    %2 = bitcast %hashtbl.make.t_float* %tbl to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %2, i64 8
    %3 = bitcast i8* %sunkaddr to i64*
    %snd7.pre = load i64, i64* %3, align 8
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %snd7 = phi i64 [ %snd7.pre, %then ], [ %snd2, %entry ]
    %fst5 = phi i64 [ %fst5.pre, %then ], [ %fst1, %entry ]
    %4 = tail call i64 @__hashtbl.make.tgac.i_hashtbl_make_string_idx_hashtbl.make.tfac.i(i64 %fst5, i64 %snd7, i8* %key)
    %5 = bitcast %hashtbl.make.t_float* %tbl to %option.t_hashtbl.make.item_float**
    %6 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %5, align 8
    %7 = bitcast %option.t_hashtbl.make.item_float* %6 to i64*
    %8 = load i64, i64* %7, align 8
    %__ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf = alloca %closure, align 8
    %funptr14 = bitcast %closure* %__ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf to i8**
    store i8* bitcast (void (i64, i1, i8*, double, i8*)* @__ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf to i8*), i8** %funptr14, align 8
    %clsr___ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf = alloca { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, align 8
    %_hashtbl_make_string_hash = getelementptr inbounds { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr___ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf, i32 0, i32 2
    store i64 %4, i64* %_hashtbl_make_string_hash, align 8
    %_hashtbl_make_string_size = getelementptr inbounds { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr___ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf, i32 0, i32 3
    store i64 %8, i64* %_hashtbl_make_string_size, align 8
    %tbl8 = getelementptr inbounds { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr___ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf, i32 0, i32 4
    store %hashtbl.make.t_float* %tbl, %hashtbl.make.t_float** %tbl8, align 8
    %ctor15 = bitcast { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr___ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-i-i-hashtbl.make.tf to i8*), i8** %ctor15, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr___ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr___ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf(i64 %4, i1 false, i8* %key, double %value, i8* %env)
    ret void
  }
  
  define linkonce_odr void @__hashtbl.make.tgbiii.u_hashtbl_make_string_redist_hashtbl.make.tfbiii.u(%hashtbl.make.t_float* noalias %tbl, i1 %wrapped, i64 %old, i64 %curr, i64 %hash) {
  entry:
    %0 = alloca %hashtbl.make.t_float*, align 8
    store %hashtbl.make.t_float* %tbl, %hashtbl.make.t_float** %0, align 8
    %1 = alloca i1, align 1
    store i1 false, i1* %1, align 1
    %2 = alloca i1, align 1
    store i1 %wrapped, i1* %2, align 1
    %3 = alloca i64, align 8
    store i64 %old, i64* %3, align 8
    %4 = alloca i64, align 8
    store i64 %curr, i64* %4, align 8
    %5 = alloca i64, align 8
    store i64 %hash, i64* %5, align 8
    %6 = alloca i64, align 8
    %7 = alloca i1, align 1
    %ret = alloca %tuple_int_bool, align 8
    br label %rec.outer
  
  rec.outer:                                        ; preds = %entry, %else5
    %.ph = phi i64 [ %curr, %entry ], [ %40, %else5 ]
    %.ph8 = phi i1 [ %wrapped, %entry ], [ %39, %else5 ]
    br label %rec
  
  rec:                                              ; preds = %rec.outer, %cont
    %8 = phi i1 [ %33, %cont ], [ %.ph8, %rec.outer ]
    %9 = bitcast %hashtbl.make.t_float* %tbl to %option.t_hashtbl.make.item_float**
    %10 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %9, align 8
    %11 = bitcast %option.t_hashtbl.make.item_float* %10 to i64*
    %12 = load i64, i64* %11, align 8
    %13 = bitcast %option.t_hashtbl.make.item_float* %10 to i8*
    %14 = mul i64 40, %.ph
    %15 = add i64 16, %14
    %16 = getelementptr i8, i8* %13, i64 %15
    %data = bitcast i8* %16 to %option.t_hashtbl.make.item_float*
    %tag9 = bitcast %option.t_hashtbl.make.item_float* %data to i32*
    %index = load i32, i32* %tag9, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %17 = bitcast %hashtbl.make.t_float* %tbl to %option.t_hashtbl.make.item_float**
    tail call void @__agii.u_array_swap-items_aoption.thashtbl.make.itemfii.u(%option.t_hashtbl.make.item_float** %17, i64 %old, i64 %.ph)
    store i1 true, i1* %1, align 1
    ret void
  
  else:                                             ; preds = %rec
    %18 = bitcast %option.t_hashtbl.make.item_float* %10 to i8*
    %sunkaddr = getelementptr i8, i8* %18, i64 %14
    %sunkaddr10 = getelementptr i8, i8* %sunkaddr, i64 40
    %19 = bitcast i8* %sunkaddr10 to i64*
    %20 = load i64, i64* %19, align 8
    store i64 %20, i64* %6, align 8
    %21 = bitcast %option.t_hashtbl.make.item_float* %10 to i8*
    %sunkaddr11 = getelementptr i8, i8* %21, i64 %14
    %sunkaddr12 = getelementptr i8, i8* %sunkaddr11, i64 48
    %22 = bitcast i8* %sunkaddr12 to i1*
    %23 = load i1, i1* %22, align 1
    store i1 %23, i1* %7, align 1
    %24 = tail call { i64, i8 } @hashtbl_make_string_next-wrapped(i64 %.ph, i64 %12)
    %box = bitcast %tuple_int_bool* %ret to { i64, i8 }*
    store { i64, i8 } %24, { i64, i8 }* %box, align 8
    %25 = load i64, i64* %19, align 8
    %26 = load i1, i1* %22, align 1
    %27 = tail call i1 @hashtbl_make_string_greater-wrapped(i64 %25, i1 %26, i64 %hash, i1 %8, i64 %12)
    br i1 %27, label %then4, label %else5
  
  then4:                                            ; preds = %else
    br i1 %23, label %then4.cont_crit_edge, label %false1
  
  then4.cont_crit_edge:                             ; preds = %then4
    %28 = bitcast %tuple_int_bool* %ret to i8*
    %sunkaddr13 = getelementptr inbounds i8, i8* %28, i64 8
    %29 = bitcast i8* %sunkaddr13 to i1*
    %.pre = load i1, i1* %29, align 1
    br label %cont
  
  false1:                                           ; preds = %then4
    %30 = bitcast %tuple_int_bool* %ret to i8*
    %sunkaddr14 = getelementptr inbounds i8, i8* %30, i64 8
    %31 = bitcast i8* %sunkaddr14 to i1*
    %32 = load i1, i1* %31, align 1
    br i1 %32, label %cont, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont
  
  cont:                                             ; preds = %then4.cont_crit_edge, %false2, %false1
    %33 = phi i1 [ %.pre, %then4.cont_crit_edge ], [ true, %false1 ], [ false, %false2 ]
    %andtmp = phi i1 [ true, %then4.cont_crit_edge ], [ true, %false1 ], [ false, %false2 ]
    %34 = bitcast %tuple_int_bool* %ret to i64*
    %35 = load i64, i64* %34, align 8
    tail call void @__hashtbl.make.tgbiii.u_hashtbl_make_string_redist_hashtbl.make.tfbiii.u(%hashtbl.make.t_float* %tbl, i1 %andtmp, i64 %.ph, i64 %35, i64 %20)
    store %hashtbl.make.t_float* %tbl, %hashtbl.make.t_float** %0, align 8
    store i1 %33, i1* %2, align 1
    br label %rec
  
  else5:                                            ; preds = %else
    %36 = bitcast %tuple_int_bool* %ret to i64*
    store %hashtbl.make.t_float* %tbl, %hashtbl.make.t_float** %0, align 8
    %37 = bitcast %tuple_int_bool* %ret to i8*
    %sunkaddr15 = getelementptr inbounds i8, i8* %37, i64 8
    %38 = bitcast i8* %sunkaddr15 to i1*
    %39 = load i1, i1* %38, align 1
    store i1 %39, i1* %2, align 1
    %40 = load i64, i64* %36, align 8
    store i64 %40, i64* %4, align 8
    br label %rec.outer
  }
  
  define linkonce_odr { i64, i64 } @__i.hashtbl.make.tg_hashtbl_make_string_create_i.hashtbl.make.tf(i64 %size) {
  entry:
    %0 = alloca %option.t_hashtbl.make.item_float*, align 8
    %1 = mul i64 %size, 40
    %2 = add i64 16, %1
    %3 = tail call i8* @malloc(i64 %2)
    %4 = bitcast i8* %3 to %option.t_hashtbl.make.item_float*
    store %option.t_hashtbl.make.item_float* %4, %option.t_hashtbl.make.item_float** %0, align 8
    %5 = bitcast %option.t_hashtbl.make.item_float* %4 to i64*
    store i64 %size, i64* %5, align 8
    %cap = getelementptr i64, i64* %5, i64 1
    store i64 %size, i64* %cap, align 8
    %__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf = alloca %closure, align 8
    %funptr3 = bitcast %closure* %__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf to i8*), i8** %funptr3, align 8
    %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf = alloca { i8*, i8*, %option.t_hashtbl.make.item_float** }, align 8
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float** }, { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf, i32 0, i32 2
    store %option.t_hashtbl.make.item_float** %0, %option.t_hashtbl.make.item_float*** %_hashtbl_make_string_data, align 8
    %ctor4 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-aoption.thashtbl.make.itemf to i8*), i8** %ctor4, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float** }, { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr___i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @prelude_iter-range(i64 0, i64 %size, %closure* %__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf)
    %6 = alloca %hashtbl.make.t_float, align 8
    %data5 = bitcast %hashtbl.make.t_float* %6 to %option.t_hashtbl.make.item_float**
    %7 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %0, align 8
    store %option.t_hashtbl.make.item_float* %7, %option.t_hashtbl.make.item_float** %data5, align 8
    %nitems = getelementptr inbounds %hashtbl.make.t_float, %hashtbl.make.t_float* %6, i32 0, i32 1
    store i64 0, i64* %nitems, align 8
    %unbox = bitcast %hashtbl.make.t_float* %6 to { i64, i64 }*
    %unbox2 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox2
  }
  
  define linkonce_odr void @__i.u-aoption.thashtbl.make.itemg-acg.u_hashtbl_make_string_inner_i.u-aoption.thashtbl.make.itemf-acf.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }*
    %data = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }, { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %clsr, i32 0, i32 2
    %data1 = load %option.t_hashtbl.make.item_float**, %option.t_hashtbl.make.item_float*** %data, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else6, %then5, %entry
    %2 = phi i64 [ %i, %entry ], [ %add9, %else6 ], [ %add, %then5 ]
    %3 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %data1, align 8
    %4 = bitcast %option.t_hashtbl.make.item_float* %3 to i64*
    %5 = load i64, i64* %4, align 8
    %eq = icmp eq i64 %2, %5
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %6 = bitcast %option.t_hashtbl.make.item_float* %3 to i64*
    store i64 0, i64* %6, align 8
    ret void
  
  else:                                             ; preds = %rec
    %7 = bitcast %option.t_hashtbl.make.item_float* %3 to i8*
    %8 = getelementptr i8, i8* %7, i64 16
    %data3 = bitcast i8* %8 to %option.t_hashtbl.make.item_float*
    %9 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %data3, i64 %2
    %tag10 = bitcast %option.t_hashtbl.make.item_float* %9 to i32*
    %index = load i32, i32* %tag10, align 4
    %eq4 = icmp eq i32 %index, 1
    br i1 %eq4, label %then5, label %else6
  
  then5:                                            ; preds = %else
    %add = add i64 %2, 1
    tail call void @__free_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %9)
    store i64 %add, i64* %1, align 8
    br label %rec
  
  else6:                                            ; preds = %else
    %data7 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %9, i32 0, i32 1
    %10 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data7, i32 0, i32 3
    %11 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data7, i32 0, i32 2
    %12 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data7, i32 0, i32 1
    %13 = bitcast %hashtbl.make.item_float* %data7 to i8**
    %14 = load i8*, i8** %13, align 8
    %15 = load double, double* %12, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 24
    %16 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %16, align 8
    %casttmp = bitcast i8* %loadtmp to void (i8*, double, i8*)*
    %sunkaddr12 = getelementptr inbounds i8, i8* %0, i64 32
    %17 = bitcast i8* %sunkaddr12 to i8**
    %loadtmp8 = load i8*, i8** %17, align 8
    tail call void %casttmp(i8* %14, double %15, i8* %loadtmp8)
    %add9 = add i64 %2, 1
    store i64 %add9, i64* %1, align 8
    br label %rec
  }
  
  define linkonce_odr void @__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string0_i.u-aoption.thashtbl.make.itemf(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %option.t_hashtbl.make.item_float** }*
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float** }, { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr, i32 0, i32 2
    %_hashtbl_make_string_data1 = load %option.t_hashtbl.make.item_float**, %option.t_hashtbl.make.item_float*** %_hashtbl_make_string_data, align 8
    %1 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %_hashtbl_make_string_data1, align 8
    %2 = bitcast %option.t_hashtbl.make.item_float* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to %option.t_hashtbl.make.item_float*
    %4 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %data, i64 %i
    store %option.t_hashtbl.make.item_float { i32 1, %hashtbl.make.item_float undef }, %option.t_hashtbl.make.item_float* %4, align 8
    ret void
  }
  
  define linkonce_odr void @__i.u-aoption.thashtbl.make.itemg___fun_hashtbl_make_string1_i.u-aoption.thashtbl.make.itemf(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %option.t_hashtbl.make.item_float** }*
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float** }, { i8*, i8*, %option.t_hashtbl.make.item_float** }* %clsr, i32 0, i32 2
    %_hashtbl_make_string_data1 = load %option.t_hashtbl.make.item_float**, %option.t_hashtbl.make.item_float*** %_hashtbl_make_string_data, align 8
    %1 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %_hashtbl_make_string_data1, align 8
    %2 = bitcast %option.t_hashtbl.make.item_float* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to %option.t_hashtbl.make.item_float*
    %4 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %data, i64 %i
    store %option.t_hashtbl.make.item_float { i32 1, %hashtbl.make.item_float undef }, %option.t_hashtbl.make.item_float* %4, align 8
    ret void
  }
  
  define linkonce_odr void @__ibacg.u-i-i-hashtbl.make.tg_hashtbl_make_string_insert__2_ibacf.u-i-i-hashtbl.make.tf(i64 %i, i1 %wrapped, i8* %key, double %value, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64, i64, %hashtbl.make.t_float* }*
    %_hashtbl_make_string_hash = getelementptr inbounds { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr, i32 0, i32 2
    %_hashtbl_make_string_hash1 = load i64, i64* %_hashtbl_make_string_hash, align 8
    %_hashtbl_make_string_size = getelementptr inbounds { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr, i32 0, i32 3
    %_hashtbl_make_string_size2 = load i64, i64* %_hashtbl_make_string_size, align 8
    %tbl = getelementptr inbounds { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %clsr, i32 0, i32 4
    %tbl3 = load %hashtbl.make.t_float*, %hashtbl.make.t_float** %tbl, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = alloca i1, align 1
    store i1 %wrapped, i1* %2, align 1
    %3 = alloca i8*, align 8
    store i8* %key, i8** %3, align 8
    %4 = alloca i1, align 1
    store i1 false, i1* %4, align 1
    %5 = alloca double, align 8
    store double %value, double* %5, align 8
    %t = alloca %option.t_hashtbl.make.item_float, align 8
    %t13 = alloca %option.t_hashtbl.make.item_float, align 8
    %ret = alloca %tuple_int_bool, align 8
    %6 = alloca i64, align 8
    %7 = alloca i1, align 1
    %t31 = alloca %option.t_hashtbl.make.item_float, align 8
    br label %rec
  
  rec:                                              ; preds = %else38, %entry
    %8 = phi i1 [ %55, %else38 ], [ %wrapped, %entry ]
    %9 = phi i64 [ %52, %else38 ], [ %i, %entry ]
    %10 = bitcast %hashtbl.make.t_float* %tbl3 to %option.t_hashtbl.make.item_float**
    %11 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %10, align 8
    %12 = bitcast %option.t_hashtbl.make.item_float* %11 to i8*
    %13 = mul i64 40, %9
    %14 = add i64 16, %13
    %15 = getelementptr i8, i8* %12, i64 %14
    %data = bitcast i8* %15 to %option.t_hashtbl.make.item_float*
    %tag42 = bitcast %option.t_hashtbl.make.item_float* %data to i32*
    %index = load i32, i32* %tag42, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %16 = bitcast i8* %15 to %option.t_hashtbl.make.item_float*
    %tag543 = bitcast %option.t_hashtbl.make.item_float* %t to i32*
    store i32 0, i32* %tag543, align 4
    %data6 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %t, i32 0, i32 1
    %key744 = bitcast %hashtbl.make.item_float* %data6 to i8**
    store i8* %key, i8** %key744, align 8
    %value8 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data6, i32 0, i32 1
    store double %value, double* %value8, align 8
    %hash = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data6, i32 0, i32 2
    store i64 %_hashtbl_make_string_hash1, i64* %hash, align 8
    %wrapped9 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data6, i32 0, i32 3
    store i1 %8, i1* %wrapped9, align 1
    tail call void @__free_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %16)
    %17 = bitcast %option.t_hashtbl.make.item_float* %t to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %15, i8* %17, i64 40, i1 false)
    %18 = getelementptr inbounds %hashtbl.make.t_float, %hashtbl.make.t_float* %tbl3, i32 0, i32 1
    %19 = load i64, i64* %18, align 8
    %add = add i64 1, %19
    store i64 %add, i64* %18, align 8
    br label %ifcont41
  
  else:                                             ; preds = %rec
    %20 = bitcast i8* %15 to %option.t_hashtbl.make.item_float*
    %data10 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %20, i32 0, i32 1
    %21 = bitcast %hashtbl.make.item_float* %data10 to i8**
    %22 = load i8*, i8** %21, align 8
    %23 = tail call i1 @string_equal(i8* %key, i8* %22)
    br i1 %23, label %then11, label %else20
  
  then11:                                           ; preds = %else
    %24 = bitcast %hashtbl.make.t_float* %tbl3 to %option.t_hashtbl.make.item_float**
    %25 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %24, align 8
    %26 = bitcast %option.t_hashtbl.make.item_float* %25 to i8*
    %27 = getelementptr i8, i8* %26, i64 %14
    %data12 = bitcast i8* %27 to %option.t_hashtbl.make.item_float*
    %tag1445 = bitcast %option.t_hashtbl.make.item_float* %t13 to i32*
    store i32 0, i32* %tag1445, align 4
    %data15 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %t13, i32 0, i32 1
    %key1646 = bitcast %hashtbl.make.item_float* %data15 to i8**
    store i8* %key, i8** %key1646, align 8
    %value17 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data15, i32 0, i32 1
    store double %value, double* %value17, align 8
    %hash18 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data15, i32 0, i32 2
    store i64 %_hashtbl_make_string_hash1, i64* %hash18, align 8
    %wrapped19 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data15, i32 0, i32 3
    store i1 %8, i1* %wrapped19, align 1
    tail call void @__free_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %data12)
    %28 = bitcast %option.t_hashtbl.make.item_float* %t13 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %27, i8* %28, i64 40, i1 false)
    br label %ifcont41
  
  else20:                                           ; preds = %else
    %29 = tail call { i64, i8 } @hashtbl_make_string_next-wrapped(i64 %9, i64 %_hashtbl_make_string_size2)
    %box = bitcast %tuple_int_bool* %ret to { i64, i8 }*
    store { i64, i8 } %29, { i64, i8 }* %box, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %15, i64 24
    %30 = bitcast i8* %sunkaddr to i64*
    %31 = load i64, i64* %30, align 8
    %sunkaddr47 = getelementptr inbounds i8, i8* %15, i64 32
    %32 = bitcast i8* %sunkaddr47 to i1*
    %33 = load i1, i1* %32, align 1
    %34 = tail call i1 @hashtbl_make_string_greater-wrapped(i64 %31, i1 %33, i64 %_hashtbl_make_string_hash1, i1 %8, i64 %_hashtbl_make_string_size2)
    br i1 %34, label %then22, label %else38
  
  then22:                                           ; preds = %else20
    %sunkaddr48 = getelementptr inbounds i8, i8* %15, i64 24
    %35 = bitcast i8* %sunkaddr48 to i64*
    %36 = load i64, i64* %35, align 8
    store i64 %36, i64* %6, align 8
    %sunkaddr49 = getelementptr inbounds i8, i8* %15, i64 32
    %37 = bitcast i8* %sunkaddr49 to i1*
    %38 = load i1, i1* %37, align 1
    store i1 %38, i1* %7, align 1
    br i1 %38, label %cont, label %false1
  
  false1:                                           ; preds = %then22
    %39 = bitcast %tuple_int_bool* %ret to i8*
    %sunkaddr50 = getelementptr inbounds i8, i8* %39, i64 8
    %40 = bitcast i8* %sunkaddr50 to i1*
    %41 = load i1, i1* %40, align 1
    br i1 %41, label %cont, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont
  
  cont:                                             ; preds = %false2, %false1, %then22
    %andtmp = phi i1 [ true, %then22 ], [ true, %false1 ], [ false, %false2 ]
    %42 = bitcast %tuple_int_bool* %ret to i64*
    %43 = bitcast %hashtbl.make.t_float* %tbl3 to %option.t_hashtbl.make.item_float**
    %44 = load i64, i64* %42, align 8
    tail call void @__hashtbl.make.tgbiii.u_hashtbl_make_string_redist_hashtbl.make.tfbiii.u(%hashtbl.make.t_float* %tbl3, i1 %andtmp, i64 %9, i64 %44, i64 %36)
    %45 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %43, align 8
    %46 = bitcast %option.t_hashtbl.make.item_float* %45 to i8*
    %47 = getelementptr i8, i8* %46, i64 %14
    %data23 = bitcast i8* %47 to %option.t_hashtbl.make.item_float*
    %tag2451 = bitcast %option.t_hashtbl.make.item_float* %data23 to i32*
    %index25 = load i32, i32* %tag2451, align 4
    %eq26 = icmp eq i32 %index25, 1
    br i1 %eq26, label %ifcont, label %else28
  
  else28:                                           ; preds = %cont
    %48 = bitcast i8* %47 to %option.t_hashtbl.make.item_float*
    %data29 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %48, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %cont, %else28
    %iftmp = phi i1 [ false, %else28 ], [ true, %cont ]
    br i1 %iftmp, label %success, label %fail
  
  success:                                          ; preds = %ifcont
    %49 = bitcast i8* %47 to %option.t_hashtbl.make.item_float*
    %tag3252 = bitcast %option.t_hashtbl.make.item_float* %t31 to i32*
    store i32 0, i32* %tag3252, align 4
    %data33 = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %t31, i32 0, i32 1
    %key3453 = bitcast %hashtbl.make.item_float* %data33 to i8**
    store i8* %key, i8** %key3453, align 8
    %value35 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data33, i32 0, i32 1
    store double %value, double* %value35, align 8
    %hash36 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data33, i32 0, i32 2
    store i64 %_hashtbl_make_string_hash1, i64* %hash36, align 8
    %wrapped37 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data33, i32 0, i32 3
    store i1 %8, i1* %wrapped37, align 1
    tail call void @__free_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %49)
    %50 = bitcast %option.t_hashtbl.make.item_float* %t31 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %47, i8* %50, i64 40, i1 false)
    br label %ifcont41
  
  fail:                                             ; preds = %ifcont
    tail call void @__assert_fail(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [15 x i8] }* @2 to i8*), i64 16), i8* getelementptr (i8, i8* bitcast ({ i64, i64, [12 x i8] }* @1 to i8*), i64 16), i32 115, i8* getelementptr (i8, i8* bitcast ({ i64, i64, [88 x i8] }* @3 to i8*), i64 16))
    unreachable
  
  else38:                                           ; preds = %else20
    %51 = bitcast %tuple_int_bool* %ret to i64*
    %52 = load i64, i64* %51, align 8
    store i64 %52, i64* %1, align 8
    %53 = bitcast %tuple_int_bool* %ret to i8*
    %sunkaddr54 = getelementptr inbounds i8, i8* %53, i64 8
    %54 = bitcast i8* %sunkaddr54 to i1*
    %55 = load i1, i1* %54, align 1
    store i1 %55, i1* %2, align 1
    br label %rec
  
  ifcont41:                                         ; preds = %then11, %success, %then
    ret void
  }
  
  define linkonce_odr void @__ihashtbl.make.tgacib.option.ti_hashtbl_make_string_find-index_ihashtbl.make.tfacib.option.ti(%option.t_int* noalias %0, i64 %i, i64 %1, i64 %2, i8* %key, i64 %hash, i1 %wrapped) {
  entry:
    %3 = alloca i64, align 8
    store i64 %i, i64* %3, align 8
    %box = alloca { i64, i64 }, align 8
    %fst17 = bitcast { i64, i64 }* %box to i64*
    store i64 %1, i64* %fst17, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %2, i64* %snd, align 8
    %tbl = bitcast { i64, i64 }* %box to %hashtbl.make.t_float*
    %4 = alloca %hashtbl.make.t_float, align 8
    %5 = bitcast %hashtbl.make.t_float* %4 to i8*
    %6 = bitcast %hashtbl.make.t_float* %tbl to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 16, i1 false)
    %7 = alloca i1, align 1
    store i1 false, i1* %7, align 1
    %8 = alloca i8*, align 8
    store i8* %key, i8** %8, align 8
    %9 = alloca i1, align 1
    store i1 false, i1* %9, align 1
    %10 = alloca i64, align 8
    store i64 %hash, i64* %10, align 8
    %11 = alloca i1, align 1
    store i1 %wrapped, i1* %11, align 1
    %ret = alloca %tuple_int_bool, align 8
    %.phi.trans.insert18 = bitcast %hashtbl.make.t_float* %4 to %option.t_hashtbl.make.item_float**
    %.pre = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %.phi.trans.insert18, align 8
    br label %rec
  
  rec:                                              ; preds = %else7, %entry
    %12 = phi i1 [ %37, %else7 ], [ %wrapped, %entry ]
    %13 = phi i64 [ %36, %else7 ], [ %i, %entry ]
    %14 = bitcast %option.t_hashtbl.make.item_float* %.pre to i8*
    %15 = mul i64 40, %13
    %16 = add i64 16, %15
    %17 = getelementptr i8, i8* %14, i64 %16
    %data = bitcast i8* %17 to %option.t_hashtbl.make.item_float*
    %tag19 = bitcast %option.t_hashtbl.make.item_float* %data to i32*
    %index = load i32, i32* %tag19, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else12
  
  then:                                             ; preds = %rec
    %18 = bitcast %option.t_hashtbl.make.item_float* %.pre to i8*
    %sunkaddr = getelementptr i8, i8* %18, i64 %15
    %sunkaddr20 = getelementptr i8, i8* %sunkaddr, i64 24
    %19 = bitcast i8* %sunkaddr20 to i8**
    %20 = load i8*, i8** %19, align 8
    %21 = tail call i1 @string_equal(i8* %key, i8* %20)
    br i1 %21, label %then3, label %else
  
  then3:                                            ; preds = %then
    %tag421 = bitcast %option.t_int* %0 to i32*
    store i32 0, i32* %tag421, align 4
    %data5 = getelementptr inbounds %option.t_int, %option.t_int* %0, i32 0, i32 1
    store i64 %13, i64* %data5, align 8
    br label %ifcont13
  
  else:                                             ; preds = %then
    %22 = bitcast %option.t_hashtbl.make.item_float* %.pre to i8*
    %sunkaddr22 = getelementptr i8, i8* %22, i64 %15
    %sunkaddr23 = getelementptr i8, i8* %sunkaddr22, i64 40
    %23 = bitcast i8* %sunkaddr23 to i64*
    %24 = load i64, i64* %23, align 8
    %25 = bitcast %option.t_hashtbl.make.item_float* %.pre to i8*
    %sunkaddr24 = getelementptr i8, i8* %25, i64 %15
    %sunkaddr25 = getelementptr i8, i8* %sunkaddr24, i64 48
    %26 = bitcast i8* %sunkaddr25 to i1*
    %27 = load i1, i1* %26, align 1
    %28 = bitcast %option.t_hashtbl.make.item_float* %.pre to i64*
    %29 = load i64, i64* %28, align 8
    %30 = tail call i1 @hashtbl_make_string_greater-wrapped(i64 %24, i1 %27, i64 %hash, i1 %12, i64 %29)
    br i1 %30, label %then6, label %else7
  
  then6:                                            ; preds = %else
    store %option.t_int { i32 1, i64 undef }, %option.t_int* %0, align 8
    br label %ifcont13
  
  else7:                                            ; preds = %else
    %31 = bitcast %option.t_hashtbl.make.item_float* %.pre to i64*
    %32 = load i64, i64* %31, align 8
    %33 = tail call { i64, i8 } @hashtbl_make_string_next-wrapped(i64 %13, i64 %32)
    %box9 = bitcast %tuple_int_bool* %ret to { i64, i8 }*
    store { i64, i8 } %33, { i64, i8 }* %box9, align 8
    %34 = getelementptr inbounds %tuple_int_bool, %tuple_int_bool* %ret, i32 0, i32 1
    %35 = bitcast %tuple_int_bool* %ret to i64*
    %36 = load i64, i64* %35, align 8
    store i64 %36, i64* %3, align 8
    %37 = load i1, i1* %34, align 1
    store i1 %37, i1* %11, align 1
    br label %rec
  
  else12:                                           ; preds = %rec
    store %option.t_int { i32 1, i64 undef }, %option.t_int* %0, align 8
    br label %ifcont13
  
  ifcont13:                                         ; preds = %then3, %then6, %else12
    store i1 true, i1* %7, align 1
    store i1 true, i1* %9, align 1
    ret void
  }
  
  define i1 @hashtbl_make_string_greater-wrapped(i64 %other-hash, i1 %other-wrapped, i64 %hash, i1 %wrapped, i64 %size) {
  entry:
    %0 = xor i1 %other-wrapped, true
    br i1 %0, label %true1, label %cont
  
  true1:                                            ; preds = %entry
    %1 = xor i1 %wrapped, true
    br i1 %1, label %true2, label %cont
  
  true2:                                            ; preds = %true1
    br label %cont
  
  cont:                                             ; preds = %true2, %true1, %entry
    %andtmp = phi i1 [ false, %entry ], [ false, %true1 ], [ true, %true2 ]
    br i1 %andtmp, label %cont1, label %false1
  
  false1:                                           ; preds = %cont
    br i1 %other-wrapped, label %true12, label %cont4
  
  false2:                                           ; preds = %cont4
    br label %cont1
  
  cont1:                                            ; preds = %false2, %cont4, %cont
    %andtmp6 = phi i1 [ true, %cont ], [ true, %cont4 ], [ false, %false2 ]
    br i1 %andtmp6, label %then, label %else
  
  true12:                                           ; preds = %false1
    br i1 %wrapped, label %true23, label %cont4
  
  true23:                                           ; preds = %true12
    br label %cont4
  
  cont4:                                            ; preds = %true23, %true12, %false1
    %andtmp5 = phi i1 [ false, %false1 ], [ false, %true12 ], [ true, %true23 ]
    br i1 %andtmp5, label %cont1, label %false2
  
  then:                                             ; preds = %cont1
    %gt = icmp sgt i64 %other-hash, %hash
    br label %ifcont12
  
  else:                                             ; preds = %cont1
    br i1 %other-wrapped, label %then7, label %else9
  
  then7:                                            ; preds = %else
    %sub = sub i64 %other-hash, %size
    %gt8 = icmp sgt i64 %sub, %hash
    br label %ifcont12
  
  else9:                                            ; preds = %else
    %sub10 = sub i64 %hash, %size
    %gt11 = icmp sgt i64 %other-hash, %sub10
    br label %ifcont12
  
  ifcont12:                                         ; preds = %then7, %else9, %then
    %iftmp13 = phi i1 [ %gt, %then ], [ %gt8, %then7 ], [ %gt11, %else9 ]
    ret i1 %iftmp13
  }
  
  define { i64, i8 } @hashtbl_make_string_next-wrapped(i64 %curr, i64 %size) {
  entry:
    %add = add i64 %curr, 1
    %eq = icmp eq i64 %add, %size
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %0 = alloca %tuple_int_bool, align 8
    store %tuple_int_bool { i64 0, i1 true }, %tuple_int_bool* %0, align 8
    br label %ifcont
  
  else:                                             ; preds = %entry
    %1 = alloca %tuple_int_bool, align 8
    %"03" = bitcast %tuple_int_bool* %1 to i64*
    store i64 %add, i64* %"03", align 8
    %"1" = getelementptr inbounds %tuple_int_bool, %tuple_int_bool* %1, i32 0, i32 1
    store i1 false, i1* %"1", align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %iftmp = phi %tuple_int_bool* [ %0, %then ], [ %1, %else ]
    %unbox = bitcast %tuple_int_bool* %iftmp to { i64, i8 }*
    %unbox2 = load { i64, i8 }, { i64, i8 }* %unbox, align 8
    ret { i64, i8 } %unbox2
  }
  
  define void @schmu_find-print(i8* %key, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %hashtbl.make.t_float* }*
    %tbl = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %clsr, i32 0, i32 2
    %tbl1 = load %hashtbl.make.t_float*, %hashtbl.make.t_float** %tbl, align 8
    %unbox = bitcast %hashtbl.make.t_float* %tbl1 to { i64, i64 }*
    %fst4 = bitcast { i64, i64 }* %unbox to i64*
    %fst2 = load i64, i64* %fst4, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    %snd3 = load i64, i64* %snd, align 8
    %ret = alloca %option.t_float, align 8
    call void @__hashtbl.make.tgac.option.tg_hashtbl_make_string_find_hashtbl.make.tfac.option.tf(%option.t_float* %ret, i64 %fst2, i64 %snd3, i8* %key)
    %tag5 = bitcast %option.t_float* %ret to i32*
    %index = load i32, i32* %tag5, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.t_float, %option.t_float* %ret, i32 0, i32 1
    %1 = load double, double* %data, align 8
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [6 x i8] }* @4 to i8*), i64 16), double %1)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @string_print(i8* bitcast ({ i64, i64, [5 x i8] }* @5 to i8*))
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define void @schmu_string() {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [10 x i8] }* @6 to i8*))
    %0 = alloca %hashtbl.make.t_float, align 8
    %1 = tail call { i64, i64 } @__i.hashtbl.make.tg_hashtbl_make_string_create_i.hashtbl.make.tf(i64 2)
    %box = bitcast %hashtbl.make.t_float* %0 to { i64, i64 }*
    store { i64, i64 } %1, { i64, i64 }* %box, align 8
    %2 = bitcast %hashtbl.make.t_float* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %2, i64 16, i1 false)
    %3 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [4 x i8] }* @7 to i8*), i8** %3, align 8
    %4 = alloca i8*, align 8
    %5 = bitcast i8** %4 to i8*
    %6 = bitcast i8** %3 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 8, i1 false)
    call void @__copy_ac(i8** %4)
    %7 = load i8*, i8** %4, align 8
    call void @__hashtbl.make.tgacg.u_hashtbl_make_string_insert_hashtbl.make.tfacf.u(%hashtbl.make.t_float* %0, i8* %7, double 1.100000e+00)
    %schmu_find-print = alloca %closure, align 8
    %funptr14 = bitcast %closure* %schmu_find-print to i8**
    store i8* bitcast (void (i8*, i8*)* @schmu_find-print to i8*), i8** %funptr14, align 8
    %clsr_schmu_find-print = alloca { i8*, i8*, %hashtbl.make.t_float* }, align 8
    %tbl = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %clsr_schmu_find-print, i32 0, i32 2
    store %hashtbl.make.t_float* %0, %hashtbl.make.t_float** %tbl, align 8
    %ctor15 = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %clsr_schmu_find-print to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-hashtbl.make.tf to i8*), i8** %ctor15, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %clsr_schmu_find-print, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %clsr_schmu_find-print to i8*
    %envptr = getelementptr inbounds %closure, %closure* %schmu_find-print, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu_find-print(i8* bitcast ({ i64, i64, [4 x i8] }* @7 to i8*), i8* %env)
    call void @schmu_find-print(i8* bitcast ({ i64, i64, [9 x i8] }* @8 to i8*), i8* %env)
    call void @__hashtbl.make.tgac.u_hashtbl_make_string_remove_hashtbl.make.tfac.u(%hashtbl.make.t_float* %0, i8* bitcast ({ i64, i64, [4 x i8] }* @7 to i8*))
    call void @schmu_find-print(i8* bitcast ({ i64, i64, [4 x i8] }* @7 to i8*), i8* %env)
    call void @__free_hashtbl.make.tf(%hashtbl.make.t_float* %0)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr i8* @__ctor_tup-aoption.thashtbl.make.itemf-acf.u(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }*
    %4 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %data = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }, { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %3, i32 0, i32 2
    %6 = bitcast %option.t_hashtbl.make.item_float*** %data to %option.t_hashtbl.make.item_float**
    call void @__copy_aoption.thashtbl.make.itemf(%option.t_hashtbl.make.item_float** %6)
    %f = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }, { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %3, i32 0, i32 3
    call void @__copy_acf.u(%closure* %f)
    %7 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float**, %closure }* %3 to i8*
    ret i8* %7
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %0) {
  entry:
    %tag1 = bitcast %option.t_hashtbl.make.item_float* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %0, i32 0, i32 1
    call void @__copy_hashtbl.make.itemf(%hashtbl.make.item_float* %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__copy_hashtbl.make.itemf(%hashtbl.make.item_float* %0) {
  entry:
    %1 = bitcast %hashtbl.make.item_float* %0 to i8**
    call void @__copy_ac(i8** %1)
    ret void
  }
  
  define linkonce_odr void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 16
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_aoption.thashtbl.make.itemf(%option.t_hashtbl.make.item_float** %0) {
  entry:
    %1 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %0, align 8
    %ref = bitcast %option.t_hashtbl.make.item_float* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = mul i64 %size, 40
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to %option.t_hashtbl.make.item_float*
    %6 = mul i64 %size, 40
    %7 = add i64 %6, 16
    %8 = bitcast %option.t_hashtbl.make.item_float* %5 to i8*
    %9 = bitcast %option.t_hashtbl.make.item_float* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store %option.t_hashtbl.make.item_float* %5, %option.t_hashtbl.make.item_float** %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %10 = load i64, i64* %cnt, align 8
    %11 = icmp slt i64 %10, %size
    br i1 %11, label %child, label %cont
  
  child:                                            ; preds = %rec
    %12 = bitcast %option.t_hashtbl.make.item_float* %1 to i8*
    %13 = mul i64 40, %10
    %14 = add i64 16, %13
    %15 = getelementptr i8, i8* %12, i64 %14
    %data = bitcast i8* %15 to %option.t_hashtbl.make.item_float*
    call void @__copy_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %data)
    %16 = add i64 %10, 1
    store i64 %16, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define linkonce_odr void @__copy_acf.u(%closure* %0) {
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
  
  declare void @__assert_fail(i8* %0, i8* %1, i32 %2, i8* %3)
  
  define linkonce_odr void @__free_hashtbl.make.itemf(%hashtbl.make.item_float* %0) {
  entry:
    %1 = bitcast %hashtbl.make.item_float* %0 to i8**
    call void @__free_ac(i8** %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %0) {
  entry:
    %tag1 = bitcast %option.t_hashtbl.make.item_float* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.t_hashtbl.make.item_float, %option.t_hashtbl.make.item_float* %0, i32 0, i32 1
    call void @__free_hashtbl.make.itemf(%hashtbl.make.item_float* %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_aoption.thashtbl.make.itemf(%option.t_hashtbl.make.item_float** %0) {
  entry:
    %1 = load %option.t_hashtbl.make.item_float*, %option.t_hashtbl.make.item_float** %0, align 8
    %ref = bitcast %option.t_hashtbl.make.item_float* %1 to i64*
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
    %4 = bitcast %option.t_hashtbl.make.item_float* %1 to i8*
    %5 = mul i64 40, %2
    %6 = add i64 16, %5
    %7 = getelementptr i8, i8* %4, i64 %6
    %data = bitcast i8* %7 to %option.t_hashtbl.make.item_float*
    call void @__free_option.thashtbl.make.itemf(%option.t_hashtbl.make.item_float* %data)
    %8 = add i64 %2, 1
    store i64 %8, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %9 = bitcast %option.t_hashtbl.make.item_float* %1 to i64*
    %10 = bitcast i64* %9 to i8*
    call void @free(i8* %10)
    ret void
  }
  
  define linkonce_odr i8* @__ctor_tup-aoption.thashtbl.make.itemf(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %option.t_hashtbl.make.item_float** }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, %option.t_hashtbl.make.item_float** }*
    %4 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float** }* %3 to i8*
    %5 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float** }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %option.t_hashtbl.make.item_float** }, { i8*, i8*, %option.t_hashtbl.make.item_float** }* %3, i32 0, i32 2
    %6 = bitcast %option.t_hashtbl.make.item_float*** %_hashtbl_make_string_data to %option.t_hashtbl.make.item_float**
    call void @__copy_aoption.thashtbl.make.itemf(%option.t_hashtbl.make.item_float** %6)
    %7 = bitcast { i8*, i8*, %option.t_hashtbl.make.item_float** }* %3 to i8*
    ret i8* %7
  }
  
  define linkonce_odr i8* @__ctor_tup-hashtbl.make.tf(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %hashtbl.make.t_float* }*
    %2 = call i8* @malloc(i64 32)
    %3 = bitcast i8* %2 to { i8*, i8*, %hashtbl.make.t_float* }*
    %4 = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %3 to i8*
    %5 = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 32, i1 false)
    %tbl = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %3, i32 0, i32 2
    %6 = bitcast %hashtbl.make.t_float** %tbl to %hashtbl.make.t_float*
    call void @__copy_hashtbl.make.tf(%hashtbl.make.t_float* %6)
    %7 = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %3 to i8*
    ret i8* %7
  }
  
  define linkonce_odr void @__copy_hashtbl.make.tf(%hashtbl.make.t_float* %0) {
  entry:
    %1 = bitcast %hashtbl.make.t_float* %0 to %option.t_hashtbl.make.item_float**
    call void @__copy_aoption.thashtbl.make.itemf(%option.t_hashtbl.make.item_float** %1)
    ret void
  }
  
  define linkonce_odr i8* @__ctor_tup-i-i-hashtbl.make.tf(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64, i64, %hashtbl.make.t_float* }*
    %2 = call i8* @malloc(i64 48)
    %3 = bitcast i8* %2 to { i8*, i8*, i64, i64, %hashtbl.make.t_float* }*
    %4 = bitcast { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 48, i1 false)
    %tbl = getelementptr inbounds { i8*, i8*, i64, i64, %hashtbl.make.t_float* }, { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %3, i32 0, i32 4
    %6 = bitcast %hashtbl.make.t_float** %tbl to %hashtbl.make.t_float*
    call void @__copy_hashtbl.make.tf(%hashtbl.make.t_float* %6)
    %7 = bitcast { i8*, i8*, i64, i64, %hashtbl.make.t_float* }* %3 to i8*
    ret i8* %7
  }
  
  define linkonce_odr void @__free_hashtbl.make.tf(%hashtbl.make.t_float* %0) {
  entry:
    %1 = bitcast %hashtbl.make.t_float* %0 to %option.t_hashtbl.make.item_float**
    call void @__free_aoption.thashtbl.make.itemf(%option.t_hashtbl.make.item_float** %1)
    ret void
  }
  
  declare void @printf(i8* %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [10 x i8] }* @9 to i8*))
    tail call void @schmu_string()
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  $ valgrind -q --leak-check=yes --show-reachable=yes ./hashtbl_test
  # hashtbl
  ## string
  1.1
  none
  none

String module test
  $ schmu string.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./string
  hello, world, :)

In channel module test
  $ schmu in_channel.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./in_channel
  (match (in_channel/open "in_channel.smu")
    ((#som
  e ic)
  
  read 18 bytes
     (let ((ic& !ic)
  read 36 bytes
           (buf& (array/create 4096)))
  read 44 bytes
       (ignore (in_channel/readn &ic &buf 50))
  read 39 bytes
       (def str& !(string/of-array !buf))
  read 1836 bytes
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (ignore (in_channel/readn &ic &buf 6))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readrem &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (print (string/of-array !buf))
  
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (print (in_channel/readall &ic))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (in_channel/lines &ic (fn (line) (print line)))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic)
           (buf& (array/create 4096)))
       (ignore (in_channel/readn &ic &buf 50))
       (def str& !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (ignore (in_channel/readn &ic &buf 6))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readrem &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (print (string/of-array !buf))
  
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (print (in_channel/readall &ic))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (in_channel/lines &ic (fn (line) (print line)))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic)
           (buf& (array/create 4096)))
       (ignore (in_channel/readn &ic &buf 50))
       (def str& !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (ignore (in_channel/readn &ic &buf 6))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readrem &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (print (string/of-array !buf))
  
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (print (in_channel/readall &ic))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (in_channel/lines &ic (fn (line) (print line)))
       (in_channel/close ic)))
    (#none ()))
