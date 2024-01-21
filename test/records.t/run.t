Compile stubs
  $ cc -c stub.c

Simple record creation (out of order)
  $ schmu --dump-llvm stub.o simple.smu && ./simple
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %bl_ = type { i1, i64 }
  
  @schmu_a = constant %bl_ { i1 true, i64 10 }
  
  declare void @printi(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @printi(i64 10)
    ret i64 0
  }
  10

Pass record to function
  $ schmu --dump-llvm stub.o pass.smu && ./pass
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"2l_" = type { i64, i64 }
  
  @schmu_a = constant %"2l_" { i64 10, i64 20 }
  
  declare void @printi(i64 %0)
  
  define void @schmu_pass_to_func(i64 %0, i64 %1) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst2 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst2, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %a = bitcast { i64, i64 }* %box to %"2l_"*
    %2 = getelementptr inbounds %"2l_", %"2l_"* %a, i32 0, i32 1
    tail call void @printi(i64 %1)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_pass_to_func(i64 10, i64 20)
    ret i64 0
  }
  20


Create record
  $ schmu --dump-llvm stub.o create.smu && ./create
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"2l_" = type { i64, i64 }
  
  declare void @printi(i64 %0)
  
  define { i64, i64 } @schmu_create_record(i64 %x, i64 %y) {
  entry:
    %0 = alloca %"2l_", align 8
    %x14 = bitcast %"2l_"* %0 to i64*
    store i64 %x, i64* %x14, align 8
    %y2 = getelementptr inbounds %"2l_", %"2l_"* %0, i32 0, i32 1
    store i64 %y, i64* %y2, align 8
    %unbox = bitcast %"2l_"* %0 to { i64, i64 }*
    %unbox3 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox3
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %ret = alloca %"2l_", align 8
    %0 = tail call { i64, i64 } @schmu_create_record(i64 8, i64 0)
    %box = bitcast %"2l_"* %ret to { i64, i64 }*
    store { i64, i64 } %0, { i64, i64 }* %box, align 8
    %1 = bitcast %"2l_"* %ret to i64*
    %2 = load i64, i64* %1, align 8
    tail call void @printi(i64 %2)
    ret i64 0
  }
  8

Nested records
  $ schmu --dump-llvm stub.o nested.smu && ./nested
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"2l2_" = type { i64, %l_ }
  %l_ = type { i64 }
  %"2l3_" = type { i64, %l2_ }
  %l2_ = type { %l_ }
  
  @schmu_a = global %"2l2_" zeroinitializer, align 8
  
  declare void @printi(i64 %0)
  
  define linkonce_odr { i64, i64 } @____fun_schmu0_2l3_r2l4_(i64 %0, i64 %1) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst3 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst3, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %unbox2 = load { i64, i64 }, { i64, i64 }* %box, align 8
    ret { i64, i64 } %unbox2
  }
  
  define i64 @schmu_inner() {
  entry:
    %0 = alloca %l_, align 8
    store %l_ { i64 3 }, %l_* %0, align 8
    %unbox = bitcast %l_* %0 to i64*
    %unbox1 = load i64, i64* %unbox, align 8
    ret i64 %unbox1
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* getelementptr inbounds (%"2l2_", %"2l2_"* @schmu_a, i32 0, i32 0), align 8
    %0 = tail call i64 @schmu_inner()
    store i64 %0, i64* getelementptr inbounds (%"2l2_", %"2l2_"* @schmu_a, i32 0, i32 1, i32 0), align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%l_* getelementptr inbounds (%"2l2_", %"2l2_"* @schmu_a, i32 0, i32 1) to i8*), i8* bitcast (i64* getelementptr inbounds (%"2l2_", %"2l2_"* @schmu_a, i32 0, i32 1, i32 0) to i8*), i64 8, i1 false)
    %1 = load i64, i64* getelementptr inbounds (%"2l2_", %"2l2_"* @schmu_a, i32 0, i32 1, i32 0), align 8
    tail call void @printi(i64 %1)
    %boxconst = alloca %"2l3_", align 8
    store %"2l3_" { i64 17, %l2_ { %l_ { i64 124 } } }, %"2l3_"* %boxconst, align 8
    %unbox = bitcast %"2l3_"* %boxconst to { i64, i64 }*
    %fst4 = bitcast { i64, i64 }* %unbox to i64*
    %fst1 = load i64, i64* %fst4, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    %snd2 = load i64, i64* %snd, align 8
    %ret = alloca %"2l3_", align 8
    %2 = tail call { i64, i64 } @____fun_schmu0_2l3_r2l4_(i64 %fst1, i64 %snd2)
    %box = bitcast %"2l3_"* %ret to { i64, i64 }*
    store { i64, i64 } %2, { i64, i64 }* %box, align 8
    %3 = getelementptr inbounds %"2l3_", %"2l3_"* %ret, i32 0, i32 1
    %4 = bitcast %l2_* %3 to %l_*
    %5 = bitcast %l_* %4 to i64*
    %6 = load i64, i64* %5, align 8
    tail call void @printi(i64 %6)
    ret i64 0
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  3
  124

Pass generic record
  $ schmu --dump-llvm stub.o parametrized_pass.smu && ./parametrized_pass
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"2lb_" = type { i64, i64, i1 }
  %closure = type { i8*, i8* }
  %l2b_ = type { i64, i1, i1 }
  
  @schmu_int_t = constant %"2lb_" { i64 700, i64 20, i1 false }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr void @__schmu_apply_2lb_r2lb2_2lb_r2lb2_(%"2lb_"* noalias %0, %closure* %f, %"2lb_"* %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%"2lb_"*, %"2lb_"*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(%"2lb_"* %0, %"2lb_"* %x, i8* %loadtmp1)
    ret void
  }
  
  define linkonce_odr { i64, i16 } @__schmu_apply_l2b_rl2b2_l2b_rl2b2_(%closure* %f, i64 %0, i16 %1) {
  entry:
    %box = alloca { i64, i16 }, align 8
    %fst11 = bitcast { i64, i16 }* %box to i64*
    store i64 %0, i64* %fst11, align 8
    %snd = getelementptr inbounds { i64, i16 }, { i64, i16 }* %box, i32 0, i32 1
    store i16 %1, i16* %snd, align 2
    %funcptr12 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr12, align 8
    %casttmp = bitcast i8* %loadtmp to { i64, i16 } (i64, i16, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp6 = load i8*, i8** %envptr, align 8
    %ret = alloca %l2b_, align 8
    %2 = tail call { i64, i16 } %casttmp(i64 %0, i16 %1, i8* %loadtmp6)
    %box7 = bitcast %l2b_* %ret to { i64, i16 }*
    store { i64, i16 } %2, { i64, i16 }* %box7, align 8
    ret { i64, i16 } %2
  }
  
  define linkonce_odr void @__schmu_pass_2lb_r2lb2_(%"2lb_"* noalias %0, %"2lb_"* %x) {
  entry:
    %1 = alloca %"2lb_", align 8
    %2 = bitcast %"2lb_"* %1 to i8*
    %3 = bitcast %"2lb_"* %x to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 24, i1 false)
    %first1 = bitcast %"2lb_"* %0 to i64*
    %4 = bitcast %"2lb_"* %1 to i64*
    %5 = load i64, i64* %4, align 8
    store i64 %5, i64* %first1, align 8
    %gen = getelementptr inbounds %"2lb_", %"2lb_"* %0, i32 0, i32 1
    %6 = getelementptr inbounds %"2lb_", %"2lb_"* %1, i32 0, i32 1
    %7 = load i64, i64* %6, align 8
    store i64 %7, i64* %gen, align 8
    %third = getelementptr inbounds %"2lb_", %"2lb_"* %0, i32 0, i32 2
    %8 = getelementptr inbounds %"2lb_", %"2lb_"* %1, i32 0, i32 2
    %9 = load i1, i1* %8, align 1
    store i1 %9, i1* %third, align 1
    ret void
  }
  
  define linkonce_odr { i64, i16 } @__schmu_pass_l2b_rl2b2_(i64 %0, i16 %1) {
  entry:
    %box = alloca { i64, i16 }, align 8
    %fst3 = bitcast { i64, i16 }* %box to i64*
    store i64 %0, i64* %fst3, align 8
    %snd = getelementptr inbounds { i64, i16 }, { i64, i16 }* %box, i32 0, i32 1
    store i16 %1, i16* %snd, align 2
    %x = bitcast { i64, i16 }* %box to %l2b_*
    %2 = alloca %l2b_, align 8
    %3 = bitcast %l2b_* %2 to i8*
    %4 = bitcast %l2b_* %x to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 16, i1 false)
    %5 = alloca %l2b_, align 8
    %first4 = bitcast %l2b_* %5 to i64*
    %6 = bitcast %l2b_* %2 to i64*
    %7 = load i64, i64* %6, align 8
    store i64 %7, i64* %first4, align 8
    %gen = getelementptr inbounds %l2b_, %l2b_* %5, i32 0, i32 1
    %8 = getelementptr inbounds %l2b_, %l2b_* %2, i32 0, i32 1
    %9 = load i1, i1* %8, align 1
    store i1 %9, i1* %gen, align 1
    %third = getelementptr inbounds %l2b_, %l2b_* %5, i32 0, i32 2
    %10 = getelementptr inbounds %l2b_, %l2b_* %2, i32 0, i32 2
    %11 = load i1, i1* %10, align 1
    store i1 %11, i1* %third, align 1
    %unbox = bitcast %l2b_* %5 to { i64, i16 }*
    %unbox2 = load { i64, i16 }, { i64, i16 }* %unbox, align 8
    ret { i64, i16 } %unbox2
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr8 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%"2lb_"*, %"2lb_"*)* @__schmu_pass_2lb_r2lb2_ to i8*), i8** %funptr8, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %ret = alloca %"2lb_", align 8
    call void @__schmu_apply_2lb_r2lb2_2lb_r2lb2_(%"2lb_"* %ret, %closure* %clstmp, %"2lb_"* @schmu_int_t)
    %0 = bitcast %"2lb_"* %ret to i64*
    %1 = load i64, i64* %0, align 8
    call void @printi(i64 %1)
    %clstmp1 = alloca %closure, align 8
    %funptr29 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast ({ i64, i16 } (i64, i16)* @__schmu_pass_l2b_rl2b2_ to i8*), i8** %funptr29, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %boxconst = alloca %l2b_, align 8
    store %l2b_ { i64 234, i1 false, i1 true }, %l2b_* %boxconst, align 8
    %unbox = bitcast %l2b_* %boxconst to { i64, i16 }*
    %fst10 = bitcast { i64, i16 }* %unbox to i64*
    %fst4 = load i64, i64* %fst10, align 8
    %snd = getelementptr inbounds { i64, i16 }, { i64, i16 }* %unbox, i32 0, i32 1
    %snd5 = load i16, i16* %snd, align 2
    %ret6 = alloca %l2b_, align 8
    %2 = call { i64, i16 } @__schmu_apply_l2b_rl2b2_l2b_rl2b2_(%closure* %clstmp1, i64 %fst4, i16 %snd5)
    %box = bitcast %l2b_* %ret6 to { i64, i16 }*
    store { i64, i16 } %2, { i64, i16 }* %box, align 8
    %3 = bitcast %l2b_* %ret6 to i64*
    %4 = load i64, i64* %3, align 8
    call void @printi(i64 %4)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  700
  234

Access parametrized record fields
  $ schmu --dump-llvm stub.o parametrized_get.smu && ./parametrized_get
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"3lb_" = type { i64, i64, i64, i1 }
  %lb_ = type { i64, i1 }
  
  @schmu_int_t = constant %"3lb_" { i64 0, i64 700, i64 20, i1 true }
  @schmu_f = constant %lb_ { i64 420, i1 false }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr void @__schmu_first_3lb_ru_(%"3lb_"* %any) {
  entry:
    %0 = getelementptr inbounds %"3lb_", %"3lb_"* %any, i32 0, i32 1
    %1 = load i64, i64* %0, align 8
    tail call void @printi(i64 %1)
    ret void
  }
  
  define linkonce_odr i64 @__schmu_gen_3lb_rl_(%"3lb_"* %any) {
  entry:
    %0 = getelementptr inbounds %"3lb_", %"3lb_"* %any, i32 0, i32 2
    %1 = alloca i64, align 8
    %2 = load i64, i64* %0, align 8
    store i64 %2, i64* %1, align 8
    ret i64 %2
  }
  
  define linkonce_odr void @__schmu_is_lb_ru_(i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst2 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst2, align 8
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %box, i32 0, i32 1
    store i8 %1, i8* %snd, align 1
    %any = bitcast { i64, i8 }* %box to %lb_*
    %2 = getelementptr inbounds %lb_, %lb_* %any, i32 0, i32 1
    %3 = trunc i8 %1 to i1
    tail call void @schmu_print_bool(i1 %3)
    ret void
  }
  
  define linkonce_odr i64 @__schmu_only_lb_rl_(i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst2 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst2, align 8
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %box, i32 0, i32 1
    store i8 %1, i8* %snd, align 1
    %2 = alloca i64, align 8
    store i64 %0, i64* %2, align 8
    ret i64 %0
  }
  
  define linkonce_odr void @__schmu_third_3lb_ru_(%"3lb_"* %any) {
  entry:
    %0 = getelementptr inbounds %"3lb_", %"3lb_"* %any, i32 0, i32 3
    %1 = load i1, i1* %0, align 1
    tail call void @schmu_print_bool(i1 %1)
    ret void
  }
  
  define void @schmu_print_bool(i1 %b) {
  entry:
    br i1 %b, label %then, label %else
  
  then:                                             ; preds = %entry
    tail call void @printi(i64 1)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @printi(i64 0)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @__schmu_first_3lb_ru_(%"3lb_"* @schmu_int_t)
    tail call void @__schmu_third_3lb_ru_(%"3lb_"* @schmu_int_t)
    %0 = tail call i64 @__schmu_gen_3lb_rl_(%"3lb_"* @schmu_int_t)
    tail call void @printi(i64 %0)
    %snd = load i8, i8* getelementptr inbounds ({ i64, i8 }, { i64, i8 }* bitcast (%lb_* @schmu_f to { i64, i8 }*), i32 0, i32 1), align 1
    %1 = tail call i64 @__schmu_only_lb_rl_(i64 420, i8 %snd)
    tail call void @printi(i64 %1)
    tail call void @__schmu_is_lb_ru_(i64 420, i8 %snd)
    ret i64 0
  }
  700
  1
  20
  420
  0

Make sure alignment of generic param works
  $ schmu --dump-llvm stub.o misaligned_get.smu && ./misaligned_get
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"2l_l_" = type { %"2l_", i64 }
  %"2l_" = type { i64, i64 }
  
  @schmu_m = constant %"2l_l_" { %"2l_" { i64 50, i64 40 }, i64 30 }
  
  declare void @printi(i64 %0)
  
  define linkonce_odr i64 @__schmu_gen_2l_l_rl_(%"2l_l_"* %any) {
  entry:
    %0 = getelementptr inbounds %"2l_l_", %"2l_l_"* %any, i32 0, i32 1
    %1 = alloca i64, align 8
    %2 = load i64, i64* %0, align 8
    store i64 %2, i64* %1, align 8
    ret i64 %2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @__schmu_gen_2l_l_rl_(%"2l_l_"* @schmu_m)
    tail call void @printi(i64 %0)
    ret i64 0
  }
  30

Parametrization needs to be given, if a type is generic
  $ schmu --dump-llvm stub.o missing_parameter.smu && ./missing_parameter
  missing_parameter.smu:5.6-11: error: Type t expects 1 type parameter.
  
  5 | fun (t : t): t.t
           ^^^^^
  
  [1]

Support function/closure fields
  $ schmu --dump-llvm stub.o function_fields.smu && valgrind -q --leak-check=yes --show-reachable=yes ./function_fields
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"2lrl2_" = type { i64, %closure }
  %closure = type { i8*, i8* }
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @__fun_schmu0(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define void @schmu_advance(%"2lrl2_"* noalias %0, %"2lrl2_"* %state) {
  entry:
    %cnt2 = bitcast %"2lrl2_"* %0 to i64*
    %1 = getelementptr inbounds %"2lrl2_", %"2lrl2_"* %state, i32 0, i32 1
    %2 = bitcast %"2lrl2_"* %state to i64*
    %3 = load i64, i64* %2, align 8
    %funcptr3 = bitcast %closure* %1 to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %1, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %4 = tail call i64 %casttmp(i64 %3, i8* %loadtmp1)
    store i64 %4, i64* %cnt2, align 8
    %next = getelementptr inbounds %"2lrl2_", %"2lrl2_"* %0, i32 0, i32 1
    %5 = bitcast %closure* %next to i8*
    %6 = bitcast %closure* %1 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 16, i1 false)
    ret void
  }
  
  define void @schmu_ten_times(%"2lrl2_"* %state) {
  entry:
    %0 = alloca %"2lrl2_", align 8
    %1 = bitcast %"2lrl2_"* %0 to i8*
    %2 = bitcast %"2lrl2_"* %state to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 24, i1 false)
    %3 = alloca i1, align 1
    store i1 false, i1* %3, align 1
    %ret = alloca %"2lrl2_", align 8
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %4 = bitcast %"2lrl2_"* %0 to i64*
    %5 = load i64, i64* %4, align 8
    %lt = icmp slt i64 %5, 10
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %rec
    %6 = bitcast %"2lrl2_"* %0 to i8*
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %5)
    call void @schmu_advance(%"2lrl2_"* %ret, %"2lrl2_"* %0)
    %7 = bitcast %"2lrl2_"* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 24, i1 false)
    br label %rec
  
  else:                                             ; preds = %rec
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 100)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(i8* %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca %"2lrl2_", align 8
    %cnt1 = bitcast %"2lrl2_"* %0 to i64*
    store i64 0, i64* %cnt1, align 8
    %next = getelementptr inbounds %"2lrl2_", %"2lrl2_"* %0, i32 0, i32 1
    %funptr2 = bitcast %closure* %next to i8**
    store i8* bitcast (i64 (i64)* @__fun_schmu0 to i8*), i8** %funptr2, align 8
    %envptr = getelementptr inbounds %closure, %closure* %next, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu_ten_times(%"2lrl2_"* %0)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  0
  1
  2
  3
  4
  5
  6
  7
  8
  9
  100

Regression test: Closures for records used to use store/load like for register values
  $ schmu --dump-llvm stub.o closure.smu && ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"2l_" = type { i64, i64 }
  
  @schmu_foo = constant %"2l_" { i64 12, i64 14 }
  
  declare void @printi(i64 %0)
  
  define void @schmu_print_foo() {
  entry:
    tail call void @printi(i64 12)
    tail call void @printi(i64 14)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_print_foo()
    ret i64 0
  }
  12
  14

Regression test: Return allocas were propagated by lets to values earlier in a function.
This caused stores to a wrong pointer type in LLVM
  $ schmu --dump-llvm stub.o nested_init_let.smu && ./nested_init_let
  nested_init_let.smu:12.9-10: warning: Unused binding a.
  
  12 |     let a = {y = {x = 1}, z = 2}
               ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %l_ = type { i64 }
  %l_l_ = type { %l_, i64 }
  
  @schmu_x = internal constant %l_ { i64 12 }
  @schmu_ret = internal constant %l_l_ { %l_ { i64 17 }, i64 9 }
  @schmu_a = internal constant %l_l_ { %l_ { i64 1 }, i64 2 }
  @schmu_ys = global %l_l_ zeroinitializer, align 8
  @schmu_ctrl__2 = global %l_l_ zeroinitializer, align 8
  
  declare void @printi(i64 %0)
  
  define { i64, i64 } @schmu_ctrl() {
  entry:
    %unbox = load { i64, i64 }, { i64, i64 }* bitcast (%l_l_* @schmu_ret to { i64, i64 }*), align 8
    ret { i64, i64 } %unbox
  }
  
  define { i64, i64 } @schmu_record_with_laters() {
  entry:
    %0 = alloca %l_l_, align 8
    store %l_l_ { %l_ { i64 12 }, i64 15 }, %l_l_* %0, align 8
    %unbox = bitcast %l_l_* %0 to { i64, i64 }*
    %unbox1 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox1
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call { i64, i64 } @schmu_record_with_laters()
    store { i64, i64 } %0, { i64, i64 }* bitcast (%l_l_* @schmu_ys to { i64, i64 }*), align 8
    %1 = load i64, i64* getelementptr inbounds (%l_l_, %l_l_* @schmu_ys, i32 0, i32 1), align 8
    tail call void @printi(i64 %1)
    %2 = load i64, i64* getelementptr inbounds (%l_l_, %l_l_* @schmu_ys, i32 0, i32 0, i32 0), align 8
    tail call void @printi(i64 %2)
    %3 = tail call { i64, i64 } @schmu_ctrl()
    store { i64, i64 } %3, { i64, i64 }* bitcast (%l_l_* @schmu_ctrl__2 to { i64, i64 }*), align 8
    %4 = load i64, i64* getelementptr inbounds (%l_l_, %l_l_* @schmu_ctrl__2, i32 0, i32 0, i32 0), align 8
    tail call void @printi(i64 %4)
    %5 = load i64, i64* getelementptr inbounds (%l_l_, %l_l_* @schmu_ctrl__2, i32 0, i32 1), align 8
    tail call void @printi(i64 %5)
    ret i64 0
  }
  15
  12
  17
  9

A return of a field should not be preallocated
  $ schmu --dump-llvm stub.o nested_prealloc.smu && ./nested_prealloc
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %"3l2_" = type { %"3l_" }
  %"3l_" = type { i64, i64, i64 }
  %closure = type { i8*, i8* }
  
  @schmu_test = internal constant %"3l2_" { %"3l_" { i64 2, i64 0, i64 0 } }
  
  declare void @printi(i64 %0)
  
  define void @schmu_test_thing(%"3l_"* noalias %0) {
  entry:
    tail call void @schmu_vector_loop(%"3l_"* %0, i64 0)
    ret void
  }
  
  define void @schmu_test_thing_mut(%"3l_"* noalias %0) {
  entry:
    %1 = alloca %"3l2_", align 8
    %wrapped3 = bitcast %"3l2_"* %1 to %"3l_"*
    store %"3l_" { i64 2, i64 0, i64 0 }, %"3l_"* %wrapped3, align 8
    %schmu_vector_loop__2 = alloca %closure, align 8
    %funptr4 = bitcast %closure* %schmu_vector_loop__2 to i8**
    store i8* bitcast (void (i64, i8*)* @schmu_vector_loop__2 to i8*), i8** %funptr4, align 8
    %clsr_schmu_vector_loop__2 = alloca { i8*, i8*, %"3l2_"* }, align 8
    %test = getelementptr inbounds { i8*, i8*, %"3l2_"* }, { i8*, i8*, %"3l2_"* }* %clsr_schmu_vector_loop__2, i32 0, i32 2
    store %"3l2_"* %1, %"3l2_"** %test, align 8
    %ctor5 = bitcast { i8*, i8*, %"3l2_"* }* %clsr_schmu_vector_loop__2 to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_3l3_ to i8*), i8** %ctor5, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %"3l2_"* }, { i8*, i8*, %"3l2_"* }* %clsr_schmu_vector_loop__2, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %"3l2_"* }* %clsr_schmu_vector_loop__2 to i8*
    %envptr = getelementptr inbounds %closure, %closure* %schmu_vector_loop__2, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu_vector_loop__2(i64 0, i8* %env)
    %2 = bitcast %"3l_"* %0 to i8*
    %3 = bitcast %"3l_"* %wrapped3 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 24, i1 false)
    ret void
  }
  
  define void @schmu_vector_loop(%"3l_"* noalias %0, i64 %i) {
  entry:
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %eq = icmp eq i64 %lsr.iv, 11
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    %3 = bitcast %"3l_"* %0 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* bitcast (%"3l2_"* @schmu_test to i8*), i64 24, i1 false)
    ret void
  
  else:                                             ; preds = %rec
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_vector_loop__2(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %"3l2_"* }*
    %test = getelementptr inbounds { i8*, i8*, %"3l2_"* }, { i8*, i8*, %"3l2_"* }* %clsr, i32 0, i32 2
    %test1 = load %"3l2_"*, %"3l2_"** %test, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = alloca %"3l_", align 8
    %3 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %3, %entry ]
    %eq = icmp eq i64 %lsr.iv, 11
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %4 = bitcast %"3l2_"* %test1 to %"3l_"*
    %dat3 = bitcast %"3l_"* %2 to i64*
    %5 = bitcast %"3l_"* %4 to i64*
    %6 = load i64, i64* %5, align 8
    %add = add i64 %6, 1
    store i64 %add, i64* %dat3, align 8
    %b = getelementptr inbounds %"3l_", %"3l_"* %2, i32 0, i32 1
    store i64 0, i64* %b, align 8
    %c = getelementptr inbounds %"3l_", %"3l_"* %2, i32 0, i32 2
    store i64 0, i64* %c, align 8
    %7 = bitcast %"3l_"* %4 to i8*
    %8 = bitcast %"3l_"* %2 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* %8, i64 24, i1 false)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr i8* @__ctor_3l3_(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %"3l2_"* }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, %"3l2_"* }*
    %4 = bitcast { i8*, i8*, %"3l2_"* }* %3 to i8*
    %5 = bitcast { i8*, i8*, %"3l2_"* }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %6 = bitcast { i8*, i8*, %"3l2_"* }* %3 to i8*
    ret i8* %6
  }
  
  declare i8* @malloc(i64 %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %ret = alloca %"3l_", align 8
    call void @schmu_test_thing(%"3l_"* %ret)
    %0 = bitcast %"3l_"* %ret to i64*
    %1 = load i64, i64* %0, align 8
    call void @printi(i64 %1)
    %ret1 = alloca %"3l_", align 8
    call void @schmu_test_thing_mut(%"3l_"* %ret1)
    %2 = bitcast %"3l_"* %ret1 to i64*
    %3 = load i64, i64* %2, align 8
    call void @printi(i64 %3)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  2
  12

Free nested records
  $ schmu free_nested.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./free_nested

Free missing record fields
  $ schmu free_missing_fields.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./free_missing_fields
