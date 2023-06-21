Compile stubs
  $ cc -c stub.c

Simple record creation (out of order)
  $ schmu --dump-llvm stub.o simple.smu && ./simple
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i1, i64 }
  
  @schmu_a = constant %foo { i1 true, i64 10 }
  
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
  
  %foo = type { i64, i64 }
  
  @schmu_a = constant %foo { i64 10, i64 20 }
  
  declare void @printi(i64 %0)
  
  define void @schmu_pass_to_func(i64 %0, i64 %1) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst2 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst2, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %a = bitcast { i64, i64 }* %box to %foo*
    %2 = getelementptr inbounds %foo, %foo* %a, i32 0, i32 1
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
  
  %foo = type { i64, i64 }
  
  declare void @printi(i64 %0)
  
  define { i64, i64 } @schmu_create_record(i64 %x, i64 %y) {
  entry:
    %0 = alloca %foo, align 8
    %x14 = bitcast %foo* %0 to i64*
    store i64 %x, i64* %x14, align 8
    %y2 = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    store i64 %y, i64* %y2, align 8
    %unbox = bitcast %foo* %0 to { i64, i64 }*
    %unbox3 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox3
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %ret = alloca %foo, align 8
    %0 = tail call { i64, i64 } @schmu_create_record(i64 8, i64 0)
    %box = bitcast %foo* %ret to { i64, i64 }*
    store { i64, i64 } %0, { i64, i64 }* %box, align 8
    %1 = bitcast %foo* %ret to i64*
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
  
  %closure = type { i8*, i8* }
  %foo = type { i64, %inner }
  %inner = type { i64 }
  %t_int = type { i64, %p_inner_innerst_int }
  %p_inner_innerst_int = type { %innerst_int }
  %innerst_int = type { i64 }
  
  @schmu_f = global %closure zeroinitializer, align 16
  @schmu_a = global %foo zeroinitializer, align 16
  
  declare void @printi(i64 %0)
  
  define { i64, i64 } @__g.g___fun_schmu0_ti.ti(i64 %0, i64 %1) {
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
    %0 = alloca %inner, align 8
    store %inner { i64 3 }, %inner* %0, align 8
    %unbox = bitcast %inner* %0 to i64*
    %unbox1 = load i64, i64* %unbox, align 8
    ret i64 %unbox1
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, i64* getelementptr inbounds (%foo, %foo* @schmu_a, i32 0, i32 0), align 8
    %0 = tail call i64 @schmu_inner()
    store i64 %0, i64* getelementptr inbounds (%foo, %foo* @schmu_a, i32 0, i32 1, i32 0), align 8
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (%inner* getelementptr inbounds (%foo, %foo* @schmu_a, i32 0, i32 1) to i8*), i8* bitcast (i64* getelementptr inbounds (%foo, %foo* @schmu_a, i32 0, i32 1, i32 0) to i8*), i64 8, i1 false)
    %1 = load i64, i64* getelementptr inbounds (%foo, %foo* @schmu_a, i32 0, i32 1, i32 0), align 8
    tail call void @printi(i64 %1)
    %boxconst = alloca %t_int, align 8
    store %t_int { i64 17, %p_inner_innerst_int { %innerst_int { i64 124 } } }, %t_int* %boxconst, align 8
    %unbox = bitcast %t_int* %boxconst to { i64, i64 }*
    %fst4 = bitcast { i64, i64 }* %unbox to i64*
    %fst1 = load i64, i64* %fst4, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %unbox, i32 0, i32 1
    %snd2 = load i64, i64* %snd, align 8
    %ret = alloca %t_int, align 8
    %2 = tail call { i64, i64 } @__g.g___fun_schmu0_ti.ti(i64 %fst1, i64 %snd2)
    %box = bitcast %t_int* %ret to { i64, i64 }*
    store { i64, i64 } %2, { i64, i64 }* %box, align 8
    %3 = getelementptr inbounds %t_int, %t_int* %ret, i32 0, i32 1
    %4 = bitcast %p_inner_innerst_int* %3 to %innerst_int*
    %5 = bitcast %innerst_int* %4 to i64*
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
  
  %t_int = type { i64, i64, i1 }
  %closure = type { i8*, i8* }
  %t_bool = type { i64, i1, i1 }
  
  @schmu_int_t = constant %t_int { i64 700, i64 20, i1 false }
  
  declare void @printi(i64 %0)
  
  define { i64, i16 } @__g.gg.g_schmu_apply_tb.tbtb.tb(%closure* %f, i64 %0, i16 %1) {
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
    %ret = alloca %t_bool, align 8
    %2 = tail call { i64, i16 } %casttmp(i64 %0, i16 %1, i8* %loadtmp6)
    %box7 = bitcast %t_bool* %ret to { i64, i16 }*
    store { i64, i16 } %2, { i64, i16 }* %box7, align 8
    ret { i64, i16 } %2
  }
  
  define void @__g.gg.g_schmu_apply_ti.titi.ti(%t_int* %0, %closure* %f, %t_int* %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t_int*, %t_int*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(%t_int* %0, %t_int* %x, i8* %loadtmp1)
    ret void
  }
  
  define { i64, i16 } @__tg.tg_schmu_pass_tb.tb(i64 %0, i16 %1) {
  entry:
    %box = alloca { i64, i16 }, align 8
    %fst3 = bitcast { i64, i16 }* %box to i64*
    store i64 %0, i64* %fst3, align 8
    %snd = getelementptr inbounds { i64, i16 }, { i64, i16 }* %box, i32 0, i32 1
    store i16 %1, i16* %snd, align 2
    %x = bitcast { i64, i16 }* %box to %t_bool*
    %2 = alloca %t_bool, align 8
    %3 = bitcast %t_bool* %2 to i8*
    %4 = bitcast %t_bool* %x to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %4, i64 16, i1 false)
    %5 = alloca %t_bool, align 8
    %first4 = bitcast %t_bool* %5 to i64*
    %6 = bitcast %t_bool* %2 to i64*
    %7 = load i64, i64* %6, align 8
    store i64 %7, i64* %first4, align 8
    %gen = getelementptr inbounds %t_bool, %t_bool* %5, i32 0, i32 1
    %8 = getelementptr inbounds %t_bool, %t_bool* %2, i32 0, i32 1
    %9 = load i1, i1* %8, align 1
    store i1 %9, i1* %gen, align 1
    %third = getelementptr inbounds %t_bool, %t_bool* %5, i32 0, i32 2
    %10 = getelementptr inbounds %t_bool, %t_bool* %2, i32 0, i32 2
    %11 = load i1, i1* %10, align 1
    store i1 %11, i1* %third, align 1
    %unbox = bitcast %t_bool* %5 to { i64, i16 }*
    %unbox2 = load { i64, i16 }, { i64, i16 }* %unbox, align 8
    ret { i64, i16 } %unbox2
  }
  
  define void @__tg.tg_schmu_pass_ti.ti(%t_int* %0, %t_int* %x) {
  entry:
    %1 = alloca %t_int, align 8
    %2 = bitcast %t_int* %1 to i8*
    %3 = bitcast %t_int* %x to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 24, i1 false)
    %first1 = bitcast %t_int* %0 to i64*
    %4 = bitcast %t_int* %1 to i64*
    %5 = load i64, i64* %4, align 8
    store i64 %5, i64* %first1, align 8
    %gen = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 1
    %6 = getelementptr inbounds %t_int, %t_int* %1, i32 0, i32 1
    %7 = load i64, i64* %6, align 8
    store i64 %7, i64* %gen, align 8
    %third = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 2
    %8 = getelementptr inbounds %t_int, %t_int* %1, i32 0, i32 2
    %9 = load i1, i1* %8, align 1
    store i1 %9, i1* %third, align 1
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr8 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%t_int*, %t_int*)* @__tg.tg_schmu_pass_ti.ti to i8*), i8** %funptr8, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    call void @__g.gg.g_schmu_apply_ti.titi.ti(%t_int* %ret, %closure* %clstmp, %t_int* @schmu_int_t)
    %0 = bitcast %t_int* %ret to i64*
    %1 = load i64, i64* %0, align 8
    call void @printi(i64 %1)
    %clstmp1 = alloca %closure, align 8
    %funptr29 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast ({ i64, i16 } (i64, i16)* @__tg.tg_schmu_pass_tb.tb to i8*), i8** %funptr29, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %boxconst = alloca %t_bool, align 8
    store %t_bool { i64 234, i1 false, i1 true }, %t_bool* %boxconst, align 8
    %unbox = bitcast %t_bool* %boxconst to { i64, i16 }*
    %fst10 = bitcast { i64, i16 }* %unbox to i64*
    %fst4 = load i64, i64* %fst10, align 8
    %snd = getelementptr inbounds { i64, i16 }, { i64, i16 }* %unbox, i32 0, i32 1
    %snd5 = load i16, i16* %snd, align 2
    %ret6 = alloca %t_bool, align 8
    %2 = call { i64, i16 } @__g.gg.g_schmu_apply_tb.tbtb.tb(%closure* %clstmp1, i64 %fst4, i16 %snd5)
    %box = bitcast %t_bool* %ret6 to { i64, i16 }*
    store { i64, i16 } %2, { i64, i16 }* %box, align 8
    %3 = bitcast %t_bool* %ret6 to i64*
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
  
  %t_int = type { i64, i64, i64, i1 }
  %gen_first_int = type { i64, i1 }
  
  @schmu_int_t = constant %t_int { i64 0, i64 700, i64 20, i1 true }
  @schmu_f = constant %gen_first_int { i64 420, i1 false }
  
  declare void @printi(i64 %0)
  
  define i64 @__gen_firstg.g_schmu_only_gen_firsti.i(i64 %0, i8 %1) {
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
  
  define void @__gen_firstg.u_schmu_is_gen_firsti.u(i64 %0, i8 %1) {
  entry:
    %box = alloca { i64, i8 }, align 8
    %fst2 = bitcast { i64, i8 }* %box to i64*
    store i64 %0, i64* %fst2, align 8
    %snd = getelementptr inbounds { i64, i8 }, { i64, i8 }* %box, i32 0, i32 1
    store i8 %1, i8* %snd, align 1
    %any = bitcast { i64, i8 }* %box to %gen_first_int*
    %2 = getelementptr inbounds %gen_first_int, %gen_first_int* %any, i32 0, i32 1
    %3 = trunc i8 %1 to i1
    tail call void @schmu_print_bool(i1 %3)
    ret void
  }
  
  define i64 @__tg.g_schmu_gen_ti.i(%t_int* %any) {
  entry:
    %0 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 2
    %1 = alloca i64, align 8
    %2 = load i64, i64* %0, align 8
    store i64 %2, i64* %1, align 8
    ret i64 %2
  }
  
  define void @__tg.u_schmu_first_ti.u(%t_int* %any) {
  entry:
    %0 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 1
    %1 = load i64, i64* %0, align 8
    tail call void @printi(i64 %1)
    ret void
  }
  
  define void @__tg.u_schmu_third_ti.u(%t_int* %any) {
  entry:
    %0 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 3
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
    tail call void @__tg.u_schmu_first_ti.u(%t_int* @schmu_int_t)
    tail call void @__tg.u_schmu_third_ti.u(%t_int* @schmu_int_t)
    %0 = tail call i64 @__tg.g_schmu_gen_ti.i(%t_int* @schmu_int_t)
    tail call void @printi(i64 %0)
    %snd = load i8, i8* getelementptr inbounds ({ i64, i8 }, { i64, i8 }* bitcast (%gen_first_int* @schmu_f to { i64, i8 }*), i32 0, i32 1), align 1
    %1 = tail call i64 @__gen_firstg.g_schmu_only_gen_firsti.i(i64 420, i8 %snd)
    tail call void @printi(i64 %1)
    tail call void @__gen_firstg.u_schmu_is_gen_firsti.u(i64 420, i8 %snd)
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
  
  %misaligned_int = type { %inner, i64 }
  %inner = type { i64, i64 }
  
  @schmu_m = constant %misaligned_int { %inner { i64 50, i64 40 }, i64 30 }
  
  declare void @printi(i64 %0)
  
  define i64 @__misalignedg.g_schmu_gen_misalignedi.i(%misaligned_int* %any) {
  entry:
    %0 = getelementptr inbounds %misaligned_int, %misaligned_int* %any, i32 0, i32 1
    %1 = alloca i64, align 8
    %2 = load i64, i64* %0, align 8
    store i64 %2, i64* %1, align 8
    ret i64 %2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @__misalignedg.g_schmu_gen_misalignedi.i(%misaligned_int* @schmu_m)
    tail call void @printi(i64 %0)
    ret i64 0
  }
  30

Parametrization needs to be given, if a type is generic
  $ schmu --dump-llvm stub.o missing_parameter.smu && ./missing_parameter
  missing_parameter.smu:5:7: error: Type t expects 1 type parameter
  5 | (fn [(t t)] (.t t))
            ^^^
  
  [1]

Support function/closure fields
  $ schmu --dump-llvm stub.o function_fields.smu && valgrind -q --leak-check=yes --show-reachable=yes ./function_fields
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %state = type { i64, %closure }
  %closure = type { i8*, i8* }
  
  @0 = private unnamed_addr constant { i64, i64, i64, [5 x i8] } { i64 1, i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @__fun_schmu0(i64 %x) {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define void @schmu_advance(%state* %0, %state* %state) {
  entry:
    %cnt2 = bitcast %state* %0 to i64*
    %1 = getelementptr inbounds %state, %state* %state, i32 0, i32 1
    %2 = bitcast %state* %state to i64*
    %3 = load i64, i64* %2, align 8
    %funcptr3 = bitcast %closure* %1 to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %1, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %4 = tail call i64 %casttmp(i64 %3, i8* %loadtmp1)
    store i64 %4, i64* %cnt2, align 8
    %next = getelementptr inbounds %state, %state* %0, i32 0, i32 1
    %5 = bitcast %closure* %next to i8*
    %6 = bitcast %closure* %1 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 16, i1 false)
    ret void
  }
  
  define void @schmu_ten_times(%state* %state) {
  entry:
    %0 = alloca %state, align 8
    %1 = bitcast %state* %0 to i8*
    %2 = bitcast %state* %state to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 24, i1 false)
    %3 = alloca i1, align 1
    store i1 false, i1* %3, align 1
    %ret = alloca %state, align 8
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %4 = bitcast %state* %0 to i64*
    %5 = load i64, i64* %4, align 8
    %lt = icmp slt i64 %5, 10
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %rec
    %6 = bitcast %state* %0 to i8*
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [5 x i8] }* @0 to i8*), i64 24), i64 %5)
    call void @schmu_advance(%state* %ret, %state* %0)
    %7 = bitcast %state* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 24, i1 false)
    br label %rec
  
  else:                                             ; preds = %rec
    call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, i64, [5 x i8] }* @0 to i8*), i64 24), i64 100)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(i8* %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca %state, align 8
    %cnt1 = bitcast %state* %0 to i64*
    store i64 0, i64* %cnt1, align 8
    %next = getelementptr inbounds %state, %state* %0, i32 0, i32 1
    %funptr2 = bitcast %closure* %next to i8**
    store i8* bitcast (i64 (i64)* @__fun_schmu0 to i8*), i8** %funptr2, align 8
    %envptr = getelementptr inbounds %closure, %closure* %next, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu_ten_times(%state* %0)
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
  
  %foo = type { i64, i64 }
  
  @schmu_foo = constant %foo { i64 12, i64 14 }
  
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
  nested_init_let.smu:13:8: warning: Unused binding a
  13 |   (def a {:y {:x 1} :z 2})
              ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i64 }
  %ys = type { %foo, i64 }
  
  @schmu_x = internal constant %foo { i64 12 }
  @schmu_ret = internal constant %ys { %foo { i64 17 }, i64 9 }
  @schmu_a = internal constant %ys { %foo { i64 1 }, i64 2 }
  @schmu_ys = global %ys zeroinitializer, align 16
  @schmu_ctrl__2 = global %ys zeroinitializer, align 16
  
  declare void @printi(i64 %0)
  
  define { i64, i64 } @schmu_ctrl() {
  entry:
    %unbox = load { i64, i64 }, { i64, i64 }* bitcast (%ys* @schmu_ret to { i64, i64 }*), align 8
    ret { i64, i64 } %unbox
  }
  
  define { i64, i64 } @schmu_record_with_laters() {
  entry:
    %0 = alloca %ys, align 8
    store %ys { %foo { i64 12 }, i64 15 }, %ys* %0, align 8
    %unbox = bitcast %ys* %0 to { i64, i64 }*
    %unbox1 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox1
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call { i64, i64 } @schmu_record_with_laters()
    store { i64, i64 } %0, { i64, i64 }* bitcast (%ys* @schmu_ys to { i64, i64 }*), align 8
    %1 = load i64, i64* getelementptr inbounds (%ys, %ys* @schmu_ys, i32 0, i32 1), align 8
    tail call void @printi(i64 %1)
    %2 = load i64, i64* getelementptr inbounds (%ys, %ys* @schmu_ys, i32 0, i32 0, i32 0), align 8
    tail call void @printi(i64 %2)
    %3 = tail call { i64, i64 } @schmu_ctrl()
    store { i64, i64 } %3, { i64, i64 }* bitcast (%ys* @schmu_ctrl__2 to { i64, i64 }*), align 8
    %4 = load i64, i64* getelementptr inbounds (%ys, %ys* @schmu_ctrl__2, i32 0, i32 0, i32 0), align 8
    tail call void @printi(i64 %4)
    %5 = load i64, i64* getelementptr inbounds (%ys, %ys* @schmu_ctrl__2, i32 0, i32 1), align 8
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
  
  %test_int_wrap = type { %int_wrap }
  %int_wrap = type { i64, i64, i64 }
  %mut_int_wrap = type { %int_wrap }
  %closure = type { i8*, i8* }
  
  @schmu_test = internal constant %test_int_wrap { %int_wrap { i64 2, i64 0, i64 0 } }
  
  declare void @printi(i64 %0)
  
  define void @schmu_test_thing(%int_wrap* %0) {
  entry:
    tail call void @schmu_vector_loop(%int_wrap* %0, i64 0)
    ret void
  }
  
  define void @schmu_test_thing_mut(%int_wrap* %0) {
  entry:
    %1 = alloca %mut_int_wrap, align 8
    %wrapped3 = bitcast %mut_int_wrap* %1 to %int_wrap*
    store %int_wrap { i64 2, i64 0, i64 0 }, %int_wrap* %wrapped3, align 8
    %schmu_vector_loop__2 = alloca %closure, align 8
    %funptr4 = bitcast %closure* %schmu_vector_loop__2 to i8**
    store i8* bitcast (void (i64, i8*)* @schmu_vector_loop__2 to i8*), i8** %funptr4, align 8
    %clsr_schmu_vector_loop__2 = alloca { i8*, i8*, %mut_int_wrap* }, align 8
    %test = getelementptr inbounds { i8*, i8*, %mut_int_wrap* }, { i8*, i8*, %mut_int_wrap* }* %clsr_schmu_vector_loop__2, i32 0, i32 2
    store %mut_int_wrap* %1, %mut_int_wrap** %test, align 8
    %ctor5 = bitcast { i8*, i8*, %mut_int_wrap* }* %clsr_schmu_vector_loop__2 to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-mutint_wrap to i8*), i8** %ctor5, align 8
    %dtor = getelementptr inbounds { i8*, i8*, %mut_int_wrap* }, { i8*, i8*, %mut_int_wrap* }* %clsr_schmu_vector_loop__2, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, %mut_int_wrap* }* %clsr_schmu_vector_loop__2 to i8*
    %envptr = getelementptr inbounds %closure, %closure* %schmu_vector_loop__2, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu_vector_loop__2(i64 0, i8* %env)
    %2 = bitcast %int_wrap* %0 to i8*
    %3 = bitcast %int_wrap* %wrapped3 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 24, i1 false)
    ret void
  }
  
  define void @schmu_vector_loop(%int_wrap* %0, i64 %i) {
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
    %3 = bitcast %int_wrap* %0 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* bitcast (%test_int_wrap* @schmu_test to i8*), i64 24, i1 false)
    ret void
  
  else:                                             ; preds = %rec
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_vector_loop__2(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, %mut_int_wrap* }*
    %test = getelementptr inbounds { i8*, i8*, %mut_int_wrap* }, { i8*, i8*, %mut_int_wrap* }* %clsr, i32 0, i32 2
    %test1 = load %mut_int_wrap*, %mut_int_wrap** %test, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = alloca %int_wrap, align 8
    %3 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %3, %entry ]
    %eq = icmp eq i64 %lsr.iv, 11
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %4 = bitcast %mut_int_wrap* %test1 to %int_wrap*
    %dat3 = bitcast %int_wrap* %2 to i64*
    %5 = bitcast %int_wrap* %4 to i64*
    %6 = load i64, i64* %5, align 8
    %add = add i64 %6, 1
    store i64 %add, i64* %dat3, align 8
    %b = getelementptr inbounds %int_wrap, %int_wrap* %2, i32 0, i32 1
    store i64 0, i64* %b, align 8
    %c = getelementptr inbounds %int_wrap, %int_wrap* %2, i32 0, i32 2
    store i64 0, i64* %c, align 8
    %7 = bitcast %int_wrap* %4 to i8*
    %8 = bitcast %int_wrap* %2 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* %8, i64 24, i1 false)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define internal i8* @__ctor_tup-mutint_wrap(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, %mut_int_wrap* }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, %mut_int_wrap* }*
    %4 = bitcast { i8*, i8*, %mut_int_wrap* }* %3 to i8*
    %5 = bitcast { i8*, i8*, %mut_int_wrap* }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %6 = bitcast { i8*, i8*, %mut_int_wrap* }* %3 to i8*
    ret i8* %6
  }
  
  declare i8* @malloc(i64 %0)
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %ret = alloca %int_wrap, align 8
    call void @schmu_test_thing(%int_wrap* %ret)
    %0 = bitcast %int_wrap* %ret to i64*
    %1 = load i64, i64* %0, align 8
    call void @printi(i64 %1)
    %ret1 = alloca %int_wrap, align 8
    call void @schmu_test_thing_mut(%int_wrap* %ret1)
    %2 = bitcast %int_wrap* %ret1 to i64*
    %3 = load i64, i64* %2, align 8
    call void @printi(i64 %3)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  2
  12
