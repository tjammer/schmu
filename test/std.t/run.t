Test hashtbl
  $ schmu hashtbl_test.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %hashtbl.make.t_float = type { %hashtbl.make.slot_float*, i64 }
  %hashtbl.make.slot_float = type { i32, %hashtbl.make.item_float }
  %hashtbl.make.item_float = type { i8*, double }
  %option.t_float = type { i32, double }
  
  @hashtbl_make_string_load-limit = constant double 7.500000e-01
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"%.9g\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  @2 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"## string\00" }
  @3 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"key\00" }
  @4 = private unnamed_addr constant { i64, i64, [9 x i8] } { i64 8, i64 8, [9 x i8] c"otherkey\00" }
  @5 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"# hashtbl\00" }
  
  declare void @std_print(i8* %0)
  
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
  
  define linkonce_odr void @__ahashtbl.make.slotgacg.u.u_hashtbl_make_string_iter-data-move_ahashtbl.make.slotfacf.u.u(%hashtbl.make.slot_float** noalias %data, %closure* %f) {
  entry:
    %__i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u to i8*), i8** %funptr5, align 8
    %clsr___i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u = alloca { i8*, i8*, %hashtbl.make.slot_float**, %closure }, align 8
    %data1 = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float**, %closure }, { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %clsr___i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u, i32 0, i32 2
    store %hashtbl.make.slot_float** %data, %hashtbl.make.slot_float*** %data1, align 8
    %f2 = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float**, %closure }, { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %clsr___i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor6 = bitcast { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %clsr___i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ahashtbl.make.slotf-acf.u to i8*), i8** %ctor6, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float**, %closure }, { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %clsr___i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %clsr___i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u(i64 0, i8* %env)
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
    %4 = inttoptr i64 %0 to %hashtbl.make.slot_float*
    %5 = bitcast %hashtbl.make.slot_float* %4 to i64*
    %6 = load i64, i64* %5, align 8
    %7 = sitofp i64 %6 to double
    %div = fdiv double %3, %7
    ret double %div
  }
  
  define linkonce_odr void @__hashtbl.make.tg.u_hashtbl_make_string_grow_hashtbl.make.tf.u(%hashtbl.make.t_float* noalias %tbl) {
  entry:
    %0 = bitcast %hashtbl.make.t_float* %tbl to %hashtbl.make.slot_float**
    %1 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %0, align 8
    %2 = bitcast %hashtbl.make.slot_float* %1 to i64*
    %3 = load i64, i64* %2, align 8
    %mul = mul i64 2, %3
    %4 = alloca %hashtbl.make.slot_float*, align 8
    %5 = mul i64 %mul, 24
    %6 = add i64 16, %5
    %7 = tail call i8* @malloc(i64 %6)
    %8 = bitcast i8* %7 to %hashtbl.make.slot_float*
    store %hashtbl.make.slot_float* %8, %hashtbl.make.slot_float** %4, align 8
    %9 = bitcast %hashtbl.make.slot_float* %8 to i64*
    store i64 %mul, i64* %9, align 8
    %cap = getelementptr i64, i64* %9, i64 1
    store i64 %mul, i64* %cap, align 8
    %__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf = alloca %closure, align 8
    %funptr7 = bitcast %closure* %__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf to i8*), i8** %funptr7, align 8
    %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf = alloca { i8*, i8*, %hashtbl.make.slot_float** }, align 8
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float** }, { i8*, i8*, %hashtbl.make.slot_float** }* %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf, i32 0, i32 2
    store %hashtbl.make.slot_float** %4, %hashtbl.make.slot_float*** %_hashtbl_make_string_data, align 8
    %ctor8 = bitcast { i8*, i8*, %hashtbl.make.slot_float** }* %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ahashtbl.make.slotf to i8*), i8** %ctor8, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float** }, { i8*, i8*, %hashtbl.make.slot_float** }* %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %hashtbl.make.slot_float** }* %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @prelude_iter-range(i64 0, i64 %mul, %closure* %__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf)
    %10 = alloca %hashtbl.make.slot_float*, align 8
    %11 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %0, align 8
    store %hashtbl.make.slot_float* %11, %hashtbl.make.slot_float** %10, align 8
    %12 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %4, align 8
    store %hashtbl.make.slot_float* %12, %hashtbl.make.slot_float** %0, align 8
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
    call void @__ahashtbl.make.slotgacg.u.u_hashtbl_make_string_iter-data-move_ahashtbl.make.slotfacf.u.u(%hashtbl.make.slot_float** %10, %closure* %__acg.u-hashtbl.make.tg___fun_hashtbl_make_string2_acf.u-hashtbl.make.tf)
    call void @__free_ahashtbl.make.slotf(%hashtbl.make.slot_float** %10)
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
    %4 = inttoptr i64 %0 to %hashtbl.make.slot_float*
    %5 = bitcast %hashtbl.make.slot_float* %4 to i64*
    %6 = load i64, i64* %5, align 8
    %mod = srem i64 %3, %6
    ret i64 %mod
  }
  
  define linkonce_odr void @__hashtbl.make.tgac.option.tg_hashtbl_make_string_find_hashtbl.make.tfac.option.tf(%option.t_float* noalias %0, i64 %1, i64 %2, i8* %key) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst15 = bitcast { i64, i64 }* %box to i64*
    store i64 %1, i64* %fst15, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %2, i64* %snd, align 8
    %3 = tail call i64 @__hashtbl.make.tgacb.i_hashtbl_make_string_probe-linear_hashtbl.make.tfacb.i(i64 %1, i64 %2, i8* %key, i1 false)
    %4 = inttoptr i64 %1 to %hashtbl.make.slot_float*
    %5 = bitcast %hashtbl.make.slot_float* %4 to i8*
    %6 = mul i64 24, %3
    %7 = add i64 16, %6
    %8 = getelementptr i8, i8* %5, i64 %7
    %data = bitcast i8* %8 to %hashtbl.make.slot_float*
    %tag16 = bitcast %hashtbl.make.slot_float* %data to i32*
    %index = load i32, i32* %tag16, align 4
    %eq = icmp eq i32 %index, 2
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %tag717 = bitcast %option.t_float* %0 to i32*
    store i32 0, i32* %tag717, align 4
    %data8 = getelementptr inbounds %option.t_float, %option.t_float* %0, i32 0, i32 1
    %sunkaddr = inttoptr i64 %1 to double*
    %9 = bitcast double* %sunkaddr to i8*
    %sunkaddr18 = getelementptr i8, i8* %9, i64 %6
    %sunkaddr19 = getelementptr i8, i8* %sunkaddr18, i64 32
    %10 = bitcast i8* %sunkaddr19 to double*
    %11 = load double, double* %10, align 8
    store double %11, double* %data8, align 8
    store double %11, double* %data8, align 8
    br label %ifcont14
  
  else:                                             ; preds = %entry
    %eq11 = icmp eq i32 %index, 0
    br i1 %eq11, label %then12, label %else13
  
  then12:                                           ; preds = %else
    store %option.t_float { i32 1, double undef }, %option.t_float* %0, align 8
    br label %ifcont14
  
  else13:                                           ; preds = %else
    store %option.t_float { i32 1, double undef }, %option.t_float* %0, align 8
    br label %ifcont14
  
  ifcont14:                                         ; preds = %then12, %else13, %then
    ret void
  }
  
  define linkonce_odr i64 @__hashtbl.make.tgacb.i_hashtbl_make_string_probe-linear_hashtbl.make.tfacb.i(i64 %0, i64 %1, i8* %key, i1 %"insert?") {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst11 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst11, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %tbl = bitcast { i64, i64 }* %box to %hashtbl.make.t_float*
    %__ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf = alloca %closure, align 8
    %funptr12 = bitcast %closure* %__ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf to i8**
    store i8* bitcast (i64 (i64, i64, i8*)* @__ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf to i8*), i8** %funptr12, align 8
    %clsr___ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf = alloca { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, align 8
    %"insert?2" = getelementptr inbounds { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %clsr___ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf, i32 0, i32 2
    store i1 %"insert?", i1* %"insert?2", align 1
    %key3 = getelementptr inbounds { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %clsr___ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf, i32 0, i32 3
    store i8* %key, i8** %key3, align 8
    %tbl4 = getelementptr inbounds { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %clsr___ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf, i32 0, i32 4
    %2 = bitcast %hashtbl.make.t_float* %tbl4 to i8*
    %3 = bitcast %hashtbl.make.t_float* %tbl to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 16, i1 false)
    %ctor13 = bitcast { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %clsr___ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-b-ac-hashtbl.make.tf to i8*), i8** %ctor13, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %clsr___ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %clsr___ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    %4 = call i64 @__hashtbl.make.tgac.i_hashtbl_make_string_idx_hashtbl.make.tfac.i(i64 %0, i64 %1, i8* %key)
    %5 = inttoptr i64 %0 to %hashtbl.make.slot_float*
    %6 = bitcast %hashtbl.make.slot_float* %5 to i64*
    %7 = load i64, i64* %6, align 8
    %8 = call i64 @__ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf(i64 %4, i64 %7, i8* %env)
    ret i64 %8
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
    %4 = tail call i64 @__hashtbl.make.tgacb.i_hashtbl_make_string_probe-linear_hashtbl.make.tfacb.i(i64 %fst5, i64 %snd7, i8* %key, i1 true)
    %5 = bitcast %hashtbl.make.t_float* %tbl to %hashtbl.make.slot_float**
    %6 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %5, align 8
    %7 = bitcast %hashtbl.make.slot_float* %6 to i8*
    %8 = mul i64 24, %4
    %9 = add i64 16, %8
    %10 = getelementptr i8, i8* %7, i64 %9
    %data = bitcast i8* %10 to %hashtbl.make.slot_float*
    %slot = alloca %hashtbl.make.slot_float, align 8
    %tag14 = bitcast %hashtbl.make.slot_float* %slot to i32*
    store i32 2, i32* %tag14, align 4
    %data8 = getelementptr inbounds %hashtbl.make.slot_float, %hashtbl.make.slot_float* %slot, i32 0, i32 1
    %key915 = bitcast %hashtbl.make.item_float* %data8 to i8**
    store i8* %key, i8** %key915, align 8
    %value10 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data8, i32 0, i32 1
    store double %value, double* %value10, align 8
    tail call void @__free_hashtbl.make.slotf(%hashtbl.make.slot_float* %data)
    %11 = bitcast %hashtbl.make.slot_float* %slot to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %11, i64 24, i1 false)
    %12 = getelementptr inbounds %hashtbl.make.t_float, %hashtbl.make.t_float* %tbl, i32 0, i32 1
    %13 = load i64, i64* %12, align 8
    %add = add i64 1, %13
    store i64 %add, i64* %12, align 8
    ret void
  }
  
  define linkonce_odr { i64, i64 } @__i.hashtbl.make.tg_hashtbl_make_string_create_i.hashtbl.make.tf(i64 %size) {
  entry:
    %0 = alloca %hashtbl.make.slot_float*, align 8
    %1 = mul i64 %size, 24
    %2 = add i64 16, %1
    %3 = tail call i8* @malloc(i64 %2)
    %4 = bitcast i8* %3 to %hashtbl.make.slot_float*
    store %hashtbl.make.slot_float* %4, %hashtbl.make.slot_float** %0, align 8
    %5 = bitcast %hashtbl.make.slot_float* %4 to i64*
    store i64 %size, i64* %5, align 8
    %cap = getelementptr i64, i64* %5, i64 1
    store i64 %size, i64* %cap, align 8
    %__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf = alloca %closure, align 8
    %funptr3 = bitcast %closure* %__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf to i8*), i8** %funptr3, align 8
    %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf = alloca { i8*, i8*, %hashtbl.make.slot_float** }, align 8
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float** }, { i8*, i8*, %hashtbl.make.slot_float** }* %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf, i32 0, i32 2
    store %hashtbl.make.slot_float** %0, %hashtbl.make.slot_float*** %_hashtbl_make_string_data, align 8
    %ctor4 = bitcast { i8*, i8*, %hashtbl.make.slot_float** }* %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ahashtbl.make.slotf to i8*), i8** %ctor4, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float** }, { i8*, i8*, %hashtbl.make.slot_float** }* %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %hashtbl.make.slot_float** }* %clsr___i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @prelude_iter-range(i64 0, i64 %size, %closure* %__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf)
    %6 = alloca %hashtbl.make.t_float, align 8
    %data5 = bitcast %hashtbl.make.t_float* %6 to %hashtbl.make.slot_float**
    %7 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %0, align 8
    store %hashtbl.make.slot_float* %7, %hashtbl.make.slot_float** %data5, align 8
    %nitems = getelementptr inbounds %hashtbl.make.t_float, %hashtbl.make.t_float* %6, i32 0, i32 1
    store i64 0, i64* %nitems, align 8
    %unbox = bitcast %hashtbl.make.t_float* %6 to { i64, i64 }*
    %unbox2 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox2
  }
  
  define linkonce_odr void @__i.u-ahashtbl.make.slotg-acg.u_hashtbl_make_string_inner__2_i.u-ahashtbl.make.slotf-acf.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %hashtbl.make.slot_float**, %closure }*
    %data = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float**, %closure }, { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %clsr, i32 0, i32 2
    %data1 = load %hashtbl.make.slot_float**, %hashtbl.make.slot_float*** %data, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else12, %then10, %then5, %entry
    %2 = phi i64 [ %i, %entry ], [ %add15, %else12 ], [ %add11, %then10 ], [ %add, %then5 ]
    %3 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %data1, align 8
    %4 = bitcast %hashtbl.make.slot_float* %3 to i64*
    %5 = load i64, i64* %4, align 8
    %eq = icmp eq i64 %2, %5
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %6 = bitcast %hashtbl.make.slot_float* %3 to i64*
    store i64 0, i64* %6, align 8
    ret void
  
  else:                                             ; preds = %rec
    %7 = bitcast %hashtbl.make.slot_float* %3 to i8*
    %8 = getelementptr i8, i8* %7, i64 16
    %data3 = bitcast i8* %8 to %hashtbl.make.slot_float*
    %9 = getelementptr inbounds %hashtbl.make.slot_float, %hashtbl.make.slot_float* %data3, i64 %2
    %tag16 = bitcast %hashtbl.make.slot_float* %9 to i32*
    %index = load i32, i32* %tag16, align 4
    %eq4 = icmp eq i32 %index, 0
    br i1 %eq4, label %then5, label %else6
  
  then5:                                            ; preds = %else
    %add = add i64 %2, 1
    tail call void @__free_hashtbl.make.slotf(%hashtbl.make.slot_float* %9)
    store i64 %add, i64* %1, align 8
    br label %rec
  
  else6:                                            ; preds = %else
    %eq9 = icmp eq i32 %index, 1
    br i1 %eq9, label %then10, label %else12
  
  then10:                                           ; preds = %else6
    %add11 = add i64 %2, 1
    tail call void @__free_hashtbl.make.slotf(%hashtbl.make.slot_float* %9)
    store i64 %add11, i64* %1, align 8
    br label %rec
  
  else12:                                           ; preds = %else6
    %data13 = getelementptr inbounds %hashtbl.make.slot_float, %hashtbl.make.slot_float* %9, i32 0, i32 1
    %10 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data13, i32 0, i32 1
    %11 = bitcast %hashtbl.make.item_float* %data13 to i8**
    %12 = load i8*, i8** %11, align 8
    %13 = load double, double* %10, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 24
    %14 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %14, align 8
    %casttmp = bitcast i8* %loadtmp to void (i8*, double, i8*)*
    %sunkaddr18 = getelementptr inbounds i8, i8* %0, i64 32
    %15 = bitcast i8* %sunkaddr18 to i8**
    %loadtmp14 = load i8*, i8** %15, align 8
    tail call void %casttmp(i8* %12, double %13, i8* %loadtmp14)
    %add15 = add i64 %2, 1
    store i64 %add15, i64* %1, align 8
    br label %rec
  }
  
  define linkonce_odr void @__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string0_i.u-ahashtbl.make.slotf(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %hashtbl.make.slot_float** }*
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float** }, { i8*, i8*, %hashtbl.make.slot_float** }* %clsr, i32 0, i32 2
    %_hashtbl_make_string_data1 = load %hashtbl.make.slot_float**, %hashtbl.make.slot_float*** %_hashtbl_make_string_data, align 8
    %1 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %_hashtbl_make_string_data1, align 8
    %2 = bitcast %hashtbl.make.slot_float* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to %hashtbl.make.slot_float*
    %4 = getelementptr inbounds %hashtbl.make.slot_float, %hashtbl.make.slot_float* %data, i64 %i
    store %hashtbl.make.slot_float { i32 0, %hashtbl.make.item_float undef }, %hashtbl.make.slot_float* %4, align 8
    ret void
  }
  
  define linkonce_odr void @__i.u-ahashtbl.make.slotg___fun_hashtbl_make_string1_i.u-ahashtbl.make.slotf(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %hashtbl.make.slot_float** }*
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float** }, { i8*, i8*, %hashtbl.make.slot_float** }* %clsr, i32 0, i32 2
    %_hashtbl_make_string_data1 = load %hashtbl.make.slot_float**, %hashtbl.make.slot_float*** %_hashtbl_make_string_data, align 8
    %1 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %_hashtbl_make_string_data1, align 8
    %2 = bitcast %hashtbl.make.slot_float* %1 to i8*
    %3 = getelementptr i8, i8* %2, i64 16
    %data = bitcast i8* %3 to %hashtbl.make.slot_float*
    %4 = getelementptr inbounds %hashtbl.make.slot_float, %hashtbl.make.slot_float* %data, i64 %i
    store %hashtbl.make.slot_float { i32 0, %hashtbl.make.item_float undef }, %hashtbl.make.slot_float* %4, align 8
    ret void
  }
  
  define linkonce_odr i64 @__ii.i-b-ac-hashtbl.make.tg_hashtbl_make_string_probe_ii.i-b-ac-hashtbl.make.tf(i64 %i, i64 %size, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i1, i8*, %hashtbl.make.t_float }*
    %"insert?" = getelementptr inbounds { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %clsr, i32 0, i32 2
    %"insert?1" = load i1, i1* %"insert?", align 1
    %key = getelementptr inbounds { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %clsr, i32 0, i32 3
    %key2 = load i8*, i8** %key, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = alloca i64, align 8
    store i64 %size, i64* %2, align 8
    br label %rec
  
  rec:                                              ; preds = %else12, %else8, %entry
    %3 = phi i64 [ %i, %entry ], [ %mod14, %else12 ], [ %mod, %else8 ]
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 32
    %4 = bitcast i8* %sunkaddr to %hashtbl.make.slot_float**
    %5 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %4, align 8
    %6 = bitcast %hashtbl.make.slot_float* %5 to i8*
    %7 = mul i64 24, %3
    %8 = add i64 16, %7
    %9 = getelementptr i8, i8* %6, i64 %8
    %data = bitcast i8* %9 to %hashtbl.make.slot_float*
    %tag18 = bitcast %hashtbl.make.slot_float* %data to i32*
    %index = load i32, i32* %tag18, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %ifcont17, label %else
  
  else:                                             ; preds = %rec
    %eq5 = icmp eq i32 %index, 1
    br i1 %eq5, label %then6, label %else9
  
  then6:                                            ; preds = %else
    br i1 %"insert?1", label %ifcont17, label %else8
  
  else8:                                            ; preds = %then6
    %add = add i64 %3, 1
    %mod = srem i64 %add, %size
    store i64 %mod, i64* %1, align 8
    br label %rec
  
  else9:                                            ; preds = %else
    %10 = bitcast i8* %9 to %hashtbl.make.slot_float*
    %data10 = getelementptr inbounds %hashtbl.make.slot_float, %hashtbl.make.slot_float* %10, i32 0, i32 1
    %11 = getelementptr inbounds %hashtbl.make.item_float, %hashtbl.make.item_float* %data10, i32 0, i32 1
    %12 = bitcast %hashtbl.make.slot_float* %5 to i8*
    %sunkaddr19 = getelementptr i8, i8* %12, i64 %7
    %sunkaddr20 = getelementptr i8, i8* %sunkaddr19, i64 24
    %13 = bitcast i8* %sunkaddr20 to i8**
    %14 = load i8*, i8** %13, align 8
    %15 = tail call i1 @string_equal(i8* %key2, i8* %14)
    br i1 %15, label %ifcont17, label %else12
  
  else12:                                           ; preds = %else9
    %add13 = add i64 %3, 1
    %mod14 = srem i64 %add13, %size
    store i64 %mod14, i64* %1, align 8
    br label %rec
  
  ifcont17:                                         ; preds = %then6, %else9, %rec
    ret i64 %3
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
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [6 x i8] }* @0 to i8*), i64 16), double %1)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @std_print(i8* bitcast ({ i64, i64, [5 x i8] }* @1 to i8*))
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define void @schmu_string() {
  entry:
    tail call void @std_print(i8* bitcast ({ i64, i64, [10 x i8] }* @2 to i8*))
    %0 = alloca %hashtbl.make.t_float, align 8
    %1 = tail call { i64, i64 } @__i.hashtbl.make.tg_hashtbl_make_string_create_i.hashtbl.make.tf(i64 64)
    %box = bitcast %hashtbl.make.t_float* %0 to { i64, i64 }*
    store { i64, i64 } %1, { i64, i64 }* %box, align 8
    %2 = bitcast %hashtbl.make.t_float* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %2, i64 16, i1 false)
    %3 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*), i8** %3, align 8
    %4 = alloca i8*, align 8
    %5 = bitcast i8** %4 to i8*
    %6 = bitcast i8** %3 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 8, i1 false)
    call void @__copy_ac(i8** %4)
    %7 = load i8*, i8** %4, align 8
    call void @__hashtbl.make.tgacg.u_hashtbl_make_string_insert_hashtbl.make.tfacf.u(%hashtbl.make.t_float* %0, i8* %7, double 1.100000e+00)
    %schmu_find-print = alloca %closure, align 8
    %funptr9 = bitcast %closure* %schmu_find-print to i8**
    store i8* bitcast (void (i8*, i8*)* @schmu_find-print to i8*), i8** %funptr9, align 8
    %clsr_schmu_find-print = alloca { i8*, i8*, %hashtbl.make.t_float* }, align 8
    %tbl = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %clsr_schmu_find-print, i32 0, i32 2
    store %hashtbl.make.t_float* %0, %hashtbl.make.t_float** %tbl, align 8
    %ctor10 = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %clsr_schmu_find-print to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-hashtbl.make.tf to i8*), i8** %ctor10, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %hashtbl.make.t_float* }, { i8*, i8*, %hashtbl.make.t_float* }* %clsr_schmu_find-print, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %hashtbl.make.t_float* }* %clsr_schmu_find-print to i8*
    %envptr = getelementptr inbounds %closure, %closure* %schmu_find-print, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu_find-print(i8* bitcast ({ i64, i64, [4 x i8] }* @3 to i8*), i8* %env)
    call void @schmu_find-print(i8* bitcast ({ i64, i64, [9 x i8] }* @4 to i8*), i8* %env)
    call void @__free_hashtbl.make.tf(%hashtbl.make.t_float* %0)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr i8* @__ctor_tup-ahashtbl.make.slotf-acf.u(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %hashtbl.make.slot_float**, %closure }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, %hashtbl.make.slot_float**, %closure }*
    %4 = bitcast { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %data = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float**, %closure }, { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %3, i32 0, i32 2
    %6 = bitcast %hashtbl.make.slot_float*** %data to %hashtbl.make.slot_float**
    call void @__copy_ahashtbl.make.slotf(%hashtbl.make.slot_float** %6)
    %f = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float**, %closure }, { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %3, i32 0, i32 3
    call void @__copy_acf.u(%closure* %f)
    %7 = bitcast { i8*, i8*, %hashtbl.make.slot_float**, %closure }* %3 to i8*
    ret i8* %7
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_hashtbl.make.slotf(%hashtbl.make.slot_float* %0) {
  entry:
    %tag1 = bitcast %hashtbl.make.slot_float* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 2
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %hashtbl.make.slot_float, %hashtbl.make.slot_float* %0, i32 0, i32 1
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
    %sz2 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %ref, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = add i64 %cap1, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = add i64 %size, 16
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_ahashtbl.make.slotf(%hashtbl.make.slot_float** %0) {
  entry:
    %1 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %0, align 8
    %ref = bitcast %hashtbl.make.slot_float* %1 to i64*
    %sz2 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz2, align 8
    %cap = getelementptr i64, i64* %ref, i64 1
    %cap1 = load i64, i64* %cap, align 8
    %2 = mul i64 %cap1, 24
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to %hashtbl.make.slot_float*
    %6 = mul i64 %size, 24
    %7 = add i64 %6, 16
    %8 = bitcast %hashtbl.make.slot_float* %5 to i8*
    %9 = bitcast %hashtbl.make.slot_float* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 %7, i1 false)
    store %hashtbl.make.slot_float* %5, %hashtbl.make.slot_float** %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, i64* %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %10 = load i64, i64* %cnt, align 8
    %11 = icmp slt i64 %10, %size
    br i1 %11, label %child, label %cont
  
  child:                                            ; preds = %rec
    %12 = bitcast %hashtbl.make.slot_float* %1 to i8*
    %13 = mul i64 24, %10
    %14 = add i64 16, %13
    %15 = getelementptr i8, i8* %12, i64 %14
    %data = bitcast i8* %15 to %hashtbl.make.slot_float*
    call void @__copy_hashtbl.make.slotf(%hashtbl.make.slot_float* %data)
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
  
  define linkonce_odr i8* @__ctor_tup-ahashtbl.make.slotf(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %hashtbl.make.slot_float** }*
    %2 = call i8* @malloc(i64 24)
    %3 = bitcast i8* %2 to { i8*, i8*, %hashtbl.make.slot_float** }*
    %4 = bitcast { i8*, i8*, %hashtbl.make.slot_float** }* %3 to i8*
    %5 = bitcast { i8*, i8*, %hashtbl.make.slot_float** }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 24, i1 false)
    %_hashtbl_make_string_data = getelementptr inbounds { i8*, i8*, %hashtbl.make.slot_float** }, { i8*, i8*, %hashtbl.make.slot_float** }* %3, i32 0, i32 2
    %6 = bitcast %hashtbl.make.slot_float*** %_hashtbl_make_string_data to %hashtbl.make.slot_float**
    call void @__copy_ahashtbl.make.slotf(%hashtbl.make.slot_float** %6)
    %7 = bitcast { i8*, i8*, %hashtbl.make.slot_float** }* %3 to i8*
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
    %1 = bitcast %hashtbl.make.t_float* %0 to %hashtbl.make.slot_float**
    call void @__copy_ahashtbl.make.slotf(%hashtbl.make.slot_float** %1)
    ret void
  }
  
  define linkonce_odr void @__free_hashtbl.make.slotf(%hashtbl.make.slot_float* %0) {
  entry:
    %tag1 = bitcast %hashtbl.make.slot_float* %0 to i32*
    %index = load i32, i32* %tag1, align 4
    %1 = icmp eq i32 %index, 2
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %hashtbl.make.slot_float, %hashtbl.make.slot_float* %0, i32 0, i32 1
    call void @__free_hashtbl.make.itemf(%hashtbl.make.item_float* %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
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
  
  define linkonce_odr void @__free_ahashtbl.make.slotf(%hashtbl.make.slot_float** %0) {
  entry:
    %1 = load %hashtbl.make.slot_float*, %hashtbl.make.slot_float** %0, align 8
    %ref = bitcast %hashtbl.make.slot_float* %1 to i64*
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
    %4 = bitcast %hashtbl.make.slot_float* %1 to i8*
    %5 = mul i64 24, %2
    %6 = add i64 16, %5
    %7 = getelementptr i8, i8* %4, i64 %6
    %data = bitcast i8* %7 to %hashtbl.make.slot_float*
    call void @__free_hashtbl.make.slotf(%hashtbl.make.slot_float* %data)
    %8 = add i64 %2, 1
    store i64 %8, i64* %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    %9 = bitcast %hashtbl.make.slot_float* %1 to i64*
    %10 = bitcast i64* %9 to i8*
    call void @free(i8* %10)
    ret void
  }
  
  define linkonce_odr i8* @__ctor_tup-b-ac-hashtbl.make.tf(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i1, i8*, %hashtbl.make.t_float }*
    %2 = call i8* @malloc(i64 48)
    %3 = bitcast i8* %2 to { i8*, i8*, i1, i8*, %hashtbl.make.t_float }*
    %4 = bitcast { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %3 to i8*
    %5 = bitcast { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 48, i1 false)
    %key = getelementptr inbounds { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %3, i32 0, i32 3
    call void @__copy_ac(i8** %key)
    %tbl = getelementptr inbounds { i8*, i8*, i1, i8*, %hashtbl.make.t_float }, { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %3, i32 0, i32 4
    call void @__copy_hashtbl.make.tf(%hashtbl.make.t_float* %tbl)
    %6 = bitcast { i8*, i8*, i1, i8*, %hashtbl.make.t_float }* %3 to i8*
    ret i8* %6
  }
  
  declare void @printf(i8* %0, ...)
  
  define linkonce_odr void @__free_hashtbl.make.tf(%hashtbl.make.t_float* %0) {
  entry:
    %1 = bitcast %hashtbl.make.t_float* %0 to %hashtbl.make.slot_float**
    call void @__free_ahashtbl.make.slotf(%hashtbl.make.slot_float** %1)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @std_print(i8* bitcast ({ i64, i64, [10 x i8] }* @5 to i8*))
    tail call void @schmu_string()
    ret i64 0
  }
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  $ ./hashtbl_test
  # hashtbl
  ## string
  1.1
  none

String module test
  $ schmu string.smu
  $ ./string
  hello, world, :)
