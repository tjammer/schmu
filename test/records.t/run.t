Compile stubs
  $ cc -c stub.c

Simple record creation (out of order)
  $ schmu -dump-llvm simple.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i1, i32 }
  
  declare void @printi(i32 %0)
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %x1 = bitcast %foo* %0 to i1*
    store i1 true, i1* %x1, align 1
    %y = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    store i32 10, i32* %y, align 4
    tail call void @printi(i32 10)
    ret i32 0
  }
  10

Pass record to function
  $ schmu -dump-llvm pass.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i32, i32 }
  
  declare void @printi(i32 %0)
  
  define private void @pass_to_func(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %a = bitcast i64* %box to %foo*
    %1 = getelementptr inbounds %foo, %foo* %a, i32 0, i32 1
    %2 = lshr i64 %0, 32
    %3 = trunc i64 %2 to i32
    tail call void @printi(i32 %3)
    ret void
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %x2 = bitcast %foo* %0 to i32*
    store i32 10, i32* %x2, align 4
    %y = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    store i32 20, i32* %y, align 4
    %unbox = bitcast %foo* %0 to i64*
    %unbox1 = load i64, i64* %unbox, align 4
    tail call void @pass_to_func(i64 %unbox1)
    ret i32 0
  }
  20


Create record
  $ schmu -dump-llvm create.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i32, i32 }
  
  declare void @printi(i32 %0)
  
  define private i64 @create_record(i32 %x, i32 %y) {
  entry:
    %0 = alloca %foo, align 8
    %x14 = bitcast %foo* %0 to i32*
    store i32 %x, i32* %x14, align 4
    %y2 = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    store i32 %y, i32* %y2, align 4
    %unbox = bitcast %foo* %0 to i64*
    %unbox3 = load i64, i64* %unbox, align 4
    ret i64 %unbox3
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %ret = alloca %foo, align 8
    %0 = tail call i64 @create_record(i32 8, i32 0)
    %box = bitcast %foo* %ret to i64*
    store i64 %0, i64* %box, align 4
    %1 = trunc i64 %0 to i32
    tail call void @printi(i32 %1)
    ret i32 0
  }
  8

Nested records
  $ schmu -dump-llvm nested.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %inner = type { i32 }
  %foo = type { i32, %inner }
  %t_int = type { i32, %p_inner_innerst_int }
  %p_inner_innerst_int = type { %innerst_int }
  %innerst_int = type { i32 }
  
  declare void @printi(i32 %0)
  
  define private i64 @__g.g___fun0_ti.ti(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    ret i64 %0
  }
  
  define private i32 @inner() {
  entry:
    %0 = alloca %inner, align 8
    %a2 = bitcast %inner* %0 to i32*
    store i32 3, i32* %a2, align 4
    ret i32 3
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %a7 = bitcast %foo* %0 to i32*
    store i32 0, i32* %a7, align 4
    %b = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    %1 = tail call i32 @inner()
    %box = bitcast %inner* %b to i32*
    store i32 %1, i32* %box, align 4
    %2 = bitcast %inner* %b to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %2, i64 4, i1 false)
    %3 = bitcast %inner* %b to i32*
    %4 = load i32, i32* %3, align 4
    tail call void @printi(i32 %4)
    %5 = alloca %t_int, align 8
    %x8 = bitcast %t_int* %5 to i32*
    store i32 17, i32* %x8, align 4
    %inner = getelementptr inbounds %t_int, %t_int* %5, i32 0, i32 1
    %a29 = bitcast %p_inner_innerst_int* %inner to %innerst_int*
    %a310 = bitcast %innerst_int* %a29 to i32*
    store i32 124, i32* %a310, align 4
    %unbox = bitcast %t_int* %5 to i64*
    %unbox4 = load i64, i64* %unbox, align 4
    %ret = alloca %t_int, align 8
    %6 = tail call i64 @__g.g___fun0_ti.ti(i64 %unbox4)
    %box5 = bitcast %t_int* %ret to i64*
    store i64 %6, i64* %box5, align 4
    %7 = getelementptr inbounds %t_int, %t_int* %ret, i32 0, i32 1
    %8 = lshr i64 %6, 32
    %9 = trunc i64 %8 to i32
    tail call void @printi(i32 %9)
    ret i32 0
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  3
  124

Pass generic record
  $ schmu -dump-llvm parametrized_pass.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t_bool = type { i32, i1, i1 }
  %closure = type { i8*, i8* }
  %t_int = type { i32, i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private i64 @__tg.tg_pass_tb.tb(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %x = bitcast i64* %box to %t_bool*
    %1 = alloca %t_bool, align 8
    %first3 = bitcast %t_bool* %1 to i32*
    %2 = trunc i64 %0 to i32
    store i32 %2, i32* %first3, align 4
    %gen = getelementptr inbounds %t_bool, %t_bool* %1, i32 0, i32 1
    %3 = getelementptr inbounds %t_bool, %t_bool* %x, i32 0, i32 1
    %4 = load i1, i1* %3, align 1
    store i1 %4, i1* %gen, align 1
    %third = getelementptr inbounds %t_bool, %t_bool* %1, i32 0, i32 2
    %5 = getelementptr inbounds %t_bool, %t_bool* %x, i32 0, i32 2
    %6 = load i1, i1* %5, align 1
    store i1 %6, i1* %third, align 1
    %unbox = bitcast %t_bool* %1 to i64*
    %unbox2 = load i64, i64* %unbox, align 4
    ret i64 %unbox2
  }
  
  define private i64 @__g.gg.g_apply_tb.tbtb.tb(%closure* %f, i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to i64 (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_bool, align 8
    %1 = tail call i64 %casttmp(i64 %0, i8* %loadtmp3)
    %box4 = bitcast %t_bool* %ret to i64*
    store i64 %1, i64* %box4, align 4
    ret i64 %1
  }
  
  define private { i64, i8 } @__tg.tg_pass_ti.ti({ i64, i8 } %0) {
  entry:
    %box = alloca { i64, i8 }, align 8
    store { i64, i8 } %0, { i64, i8 }* %box, align 4
    %x = bitcast { i64, i8 }* %box to %t_int*
    %1 = alloca %t_int, align 8
    %first3 = bitcast %t_int* %1 to i32*
    %2 = bitcast %t_int* %x to i32*
    %3 = load i32, i32* %2, align 4
    store i32 %3, i32* %first3, align 4
    %gen = getelementptr inbounds %t_int, %t_int* %1, i32 0, i32 1
    %4 = getelementptr inbounds %t_int, %t_int* %x, i32 0, i32 1
    %5 = load i32, i32* %4, align 4
    store i32 %5, i32* %gen, align 4
    %third = getelementptr inbounds %t_int, %t_int* %1, i32 0, i32 2
    %6 = getelementptr inbounds %t_int, %t_int* %x, i32 0, i32 2
    %7 = load i1, i1* %6, align 1
    store i1 %7, i1* %third, align 1
    %unbox = bitcast %t_int* %1 to { i64, i8 }*
    %unbox2 = load { i64, i8 }, { i64, i8 }* %unbox, align 4
    ret { i64, i8 } %unbox2
  }
  
  define private { i64, i8 } @__g.gg.g_apply_ti.titi.ti(%closure* %f, { i64, i8 } %0) {
  entry:
    %box = alloca { i64, i8 }, align 8
    store { i64, i8 } %0, { i64, i8 }* %box, align 4
    %funcptr8 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr8, align 8
    %casttmp = bitcast i8* %loadtmp to { i64, i8 } ({ i64, i8 }, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp3 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    %1 = tail call { i64, i8 } %casttmp({ i64, i8 } %0, i8* %loadtmp3)
    %box4 = bitcast %t_int* %ret to { i64, i8 }*
    store { i64, i8 } %1, { i64, i8 }* %box4, align 4
    ret { i64, i8 } %1
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %t_int, align 8
    %first14 = bitcast %t_int* %0 to i32*
    store i32 700, i32* %first14, align 4
    %gen = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 1
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 2
    store i1 false, i1* %third, align 1
    %clstmp = alloca %closure, align 8
    %funptr15 = bitcast %closure* %clstmp to i8**
    store i8* bitcast ({ i64, i8 } ({ i64, i8 })* @__tg.tg_pass_ti.ti to i8*), i8** %funptr15, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %unbox = bitcast %t_int* %0 to { i64, i8 }*
    %unbox1 = load { i64, i8 }, { i64, i8 }* %unbox, align 4
    %ret = alloca %t_int, align 8
    %1 = call { i64, i8 } @__g.gg.g_apply_ti.titi.ti(%closure* %clstmp, { i64, i8 } %unbox1)
    %box = bitcast %t_int* %ret to { i64, i8 }*
    store { i64, i8 } %1, { i64, i8 }* %box, align 4
    %2 = bitcast %t_int* %ret to i32*
    %3 = load i32, i32* %2, align 4
    call void @printi(i32 %3)
    %clstmp3 = alloca %closure, align 8
    %funptr416 = bitcast %closure* %clstmp3 to i8**
    store i8* bitcast (i64 (i64)* @__tg.tg_pass_tb.tb to i8*), i8** %funptr416, align 8
    %envptr5 = getelementptr inbounds %closure, %closure* %clstmp3, i32 0, i32 1
    store i8* null, i8** %envptr5, align 8
    %4 = alloca %t_bool, align 8
    %first617 = bitcast %t_bool* %4 to i32*
    store i32 234, i32* %first617, align 4
    %gen7 = getelementptr inbounds %t_bool, %t_bool* %4, i32 0, i32 1
    store i1 false, i1* %gen7, align 1
    %third8 = getelementptr inbounds %t_bool, %t_bool* %4, i32 0, i32 2
    store i1 true, i1* %third8, align 1
    %unbox9 = bitcast %t_bool* %4 to i64*
    %unbox10 = load i64, i64* %unbox9, align 4
    %ret11 = alloca %t_bool, align 8
    %5 = call i64 @__g.gg.g_apply_tb.tbtb.tb(%closure* %clstmp3, i64 %unbox10)
    %box12 = bitcast %t_bool* %ret11 to i64*
    store i64 %5, i64* %box12, align 4
    %6 = trunc i64 %5 to i32
    call void @printi(i32 %6)
    ret i32 0
  }
  700
  234

Access parametrized record fields
  $ schmu -dump-llvm parametrized_get.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %gen_first_int = type { i32, i1 }
  %t_int = type { i32, i32, i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @__gen_firstg.u_is_gen_firsti.u(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %any = bitcast i64* %box to %gen_first_int*
    %1 = getelementptr inbounds %gen_first_int, %gen_first_int* %any, i32 0, i32 1
    %2 = load i1, i1* %1, align 1
    tail call void @print_bool(i1 %2)
    ret void
  }
  
  define private i32 @__gen_firstg.g_only_gen_firsti.i(i64 %0) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 4
    %1 = trunc i64 %0 to i32
    ret i32 %1
  }
  
  define private i32 @__tg.g_gen_ti.i({ i64, i64 } %0) {
  entry:
    %box = alloca { i64, i64 }, align 8
    store { i64, i64 } %0, { i64, i64 }* %box, align 4
    %any = bitcast { i64, i64 }* %box to %t_int*
    %1 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 2
    %2 = load i32, i32* %1, align 4
    ret i32 %2
  }
  
  define private void @__tg.u_third_ti.u({ i64, i64 } %0) {
  entry:
    %box = alloca { i64, i64 }, align 8
    store { i64, i64 } %0, { i64, i64 }* %box, align 4
    %any = bitcast { i64, i64 }* %box to %t_int*
    %1 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 3
    %2 = load i1, i1* %1, align 1
    tail call void @print_bool(i1 %2)
    ret void
  }
  
  define private void @__tg.u_first_ti.u({ i64, i64 } %0) {
  entry:
    %box = alloca { i64, i64 }, align 8
    store { i64, i64 } %0, { i64, i64 }* %box, align 4
    %any = bitcast { i64, i64 }* %box to %t_int*
    %1 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 1
    %2 = load i32, i32* %1, align 4
    tail call void @printi(i32 %2)
    ret void
  }
  
  define private void @print_bool(i1 %b) {
  entry:
    br i1 %b, label %then, label %else
  
  then:                                             ; preds = %entry
    tail call void @printi(i32 1)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @printi(i32 0)
    ret void
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %t_int, align 8
    %null10 = bitcast %t_int* %0 to i32*
    store i32 0, i32* %null10, align 4
    %first = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 1
    store i32 700, i32* %first, align 4
    %gen = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 2
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 3
    store i1 true, i1* %third, align 1
    %1 = alloca %gen_first_int, align 8
    %only11 = bitcast %gen_first_int* %1 to i32*
    store i32 420, i32* %only11, align 4
    %is = getelementptr inbounds %gen_first_int, %gen_first_int* %1, i32 0, i32 1
    store i1 false, i1* %is, align 1
    %unbox = bitcast %t_int* %0 to { i64, i64 }*
    %unbox1 = load { i64, i64 }, { i64, i64 }* %unbox, align 4
    tail call void @__tg.u_first_ti.u({ i64, i64 } %unbox1)
    tail call void @__tg.u_third_ti.u({ i64, i64 } %unbox1)
    %2 = tail call i32 @__tg.g_gen_ti.i({ i64, i64 } %unbox1)
    tail call void @printi(i32 %2)
    %unbox6 = bitcast %gen_first_int* %1 to i64*
    %unbox7 = load i64, i64* %unbox6, align 4
    %3 = tail call i32 @__gen_firstg.g_only_gen_firsti.i(i64 %unbox7)
    tail call void @printi(i32 %3)
    tail call void @__gen_firstg.u_is_gen_firsti.u(i64 %unbox7)
    ret i32 0
  }
  700
  1
  20
  420
  0

Make sure alignment of generic param works
  $ schmu -dump-llvm misaligned_get.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %misaligned_int = type { %inner, i32 }
  %inner = type { i32, i32 }
  
  declare void @printi(i32 %0)
  
  define private i32 @__misalignedg.g_gen_misalignedi.i({ i64, i32 } %0) {
  entry:
    %box = alloca { i64, i32 }, align 8
    store { i64, i32 } %0, { i64, i32 }* %box, align 4
    %any = bitcast { i64, i32 }* %box to %misaligned_int*
    %1 = getelementptr inbounds %misaligned_int, %misaligned_int* %any, i32 0, i32 1
    %2 = load i32, i32* %1, align 4
    ret i32 %2
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %misaligned_int, align 8
    %fst3 = bitcast %misaligned_int* %0 to %inner*
    %fst14 = bitcast %inner* %fst3 to i32*
    store i32 50, i32* %fst14, align 4
    %snd = getelementptr inbounds %inner, %inner* %fst3, i32 0, i32 1
    store i32 40, i32* %snd, align 4
    %gen = getelementptr inbounds %misaligned_int, %misaligned_int* %0, i32 0, i32 1
    store i32 30, i32* %gen, align 4
    %unbox = bitcast %misaligned_int* %0 to { i64, i32 }*
    %unbox2 = load { i64, i32 }, { i64, i32 }* %unbox, align 4
    %1 = tail call i32 @__misalignedg.g_gen_misalignedi.i({ i64, i32 } %unbox2)
    tail call void @printi(i32 %1)
    ret i32 0
  }
  30

Parametrization needs to be given, if a type is generic
  $ schmu -dump-llvm missing_parameter.smu && cc out.o stub.o && ./a.out
  missing_parameter.smu:5:1: error: Type t needs a type parameter
  5 | fun (t : t) t.t end
                                                                      ^^^^^^^^^^^^^^^^^^^
                                                                  
  [1]

Support function/closure fields
  $ schmu -dump-llvm function_fields.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %state = type { i32, %closure* }
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private void @ten_times(%state* %state) {
  entry:
    %0 = alloca %state, align 8
    %1 = bitcast %state* %0 to i8*
    %2 = bitcast %state* %state to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 16, i1 false)
    %ret = alloca %state, align 8
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %3 = bitcast %state* %0 to i32*
    %4 = load i32, i32* %3, align 4
    %lt = icmp slt i32 %4, 10
    br i1 %lt, label %then, label %else
  
  then:                                             ; preds = %rec
    %5 = bitcast %state* %0 to i8*
    call void @printi(i32 %4)
    call void @advance(%state* %ret, %state* %0)
    %6 = bitcast %state* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %5, i8* %6, i64 16, i1 false)
    br label %rec
  
  else:                                             ; preds = %rec
    call void @printi(i32 100)
    ret void
  }
  
  define private void @advance(%state* sret %0, %state* %state) {
  entry:
    %cnt2 = bitcast %state* %0 to i32*
    %1 = getelementptr inbounds %state, %state* %state, i32 0, i32 1
    %2 = load %closure*, %closure** %1, align 8
    %3 = bitcast %state* %state to i32*
    %4 = load i32, i32* %3, align 4
    %funcptr3 = bitcast %closure* %2 to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to i32 (i32, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %2, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %5 = tail call i32 %casttmp(i32 %4, i8* %loadtmp1)
    store i32 %5, i32* %cnt2, align 4
    %next = getelementptr inbounds %state, %state* %0, i32 0, i32 1
    %6 = load %closure*, %closure** %1, align 8
    store %closure* %6, %closure** %next, align 8
    ret void
  }
  
  define private i32 @__fun0(i32 %x) {
  entry:
    %add = add i32 %x, 1
    ret i32 %add
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %state, align 8
    %cnt1 = bitcast %state* %0 to i32*
    store i32 0, i32* %cnt1, align 4
    %next = getelementptr inbounds %state, %state* %0, i32 0, i32 1
    %clstmp = alloca %closure, align 8
    %funptr2 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (i32 (i32)* @__fun0 to i8*), i8** %funptr2, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    store %closure* %clstmp, %closure** %next, align 8
    call void @ten_times(%state* %0)
    ret i32 0
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
  $ schmu -dump-llvm closure.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i32, i32 }
  %closure = type { i8*, i8* }
  
  declare void @printi(i32 %0)
  
  define private void @print_foo(i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %foo }*
    %foo1 = bitcast { %foo }* %clsr to %foo*
    %1 = bitcast %foo* %foo1 to i32*
    %2 = load i32, i32* %1, align 4
    tail call void @printi(i32 %2)
    %3 = getelementptr inbounds %foo, %foo* %foo1, i32 0, i32 1
    %4 = load i32, i32* %3, align 4
    tail call void @printi(i32 %4)
    ret void
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %x3 = bitcast %foo* %0 to i32*
    store i32 12, i32* %x3, align 4
    %y = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    store i32 14, i32* %y, align 4
    %print_foo = alloca %closure, align 8
    %funptr4 = bitcast %closure* %print_foo to i8**
    store i8* bitcast (void (i8*)* @print_foo to i8*), i8** %funptr4, align 8
    %clsr_print_foo = alloca { %foo }, align 8
    %foo5 = bitcast { %foo }* %clsr_print_foo to %foo*
    %1 = bitcast %foo* %foo5 to i8*
    %2 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    %env = bitcast { %foo }* %clsr_print_foo to i8*
    %envptr = getelementptr inbounds %closure, %closure* %print_foo, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @print_foo(i8* %env)
    ret i32 0
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  12
  14

Regression test: Return allocas were propagated by lets to values earlier in a function.
This caused stores to a wrong pointer type in LLVM
  $ schmu -dump-llvm nested_init_let.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %ys = type { %foo, i32 }
  %foo = type { i32 }
  
  declare void @printi(i32 %0)
  
  define private i64 @ctrl() {
  entry:
    %0 = alloca %ys, align 8
    %y5 = bitcast %ys* %0 to %foo*
    %x6 = bitcast %foo* %y5 to i32*
    store i32 17, i32* %x6, align 4
    %z = getelementptr inbounds %ys, %ys* %0, i32 0, i32 1
    store i32 9, i32* %z, align 4
    %1 = alloca %ys, align 8
    %y17 = bitcast %ys* %1 to %foo*
    %x28 = bitcast %foo* %y17 to i32*
    store i32 1, i32* %x28, align 4
    %z3 = getelementptr inbounds %ys, %ys* %1, i32 0, i32 1
    store i32 2, i32* %z3, align 4
    %unbox = bitcast %ys* %0 to i64*
    %unbox4 = load i64, i64* %unbox, align 4
    ret i64 %unbox4
  }
  
  define private i64 @record_with_laters() {
  entry:
    %0 = alloca %foo, align 8
    %x2 = bitcast %foo* %0 to i32*
    store i32 12, i32* %x2, align 4
    %1 = alloca %ys, align 8
    %y3 = bitcast %ys* %1 to %foo*
    %2 = bitcast %foo* %y3 to i8*
    %3 = bitcast %foo* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 4, i1 false)
    %z = getelementptr inbounds %ys, %ys* %1, i32 0, i32 1
    store i32 15, i32* %z, align 4
    %unbox = bitcast %ys* %1 to i64*
    %unbox1 = load i64, i64* %unbox, align 4
    ret i64 %unbox1
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %ret = alloca %ys, align 8
    %0 = tail call i64 @record_with_laters()
    %box = bitcast %ys* %ret to i64*
    store i64 %0, i64* %box, align 4
    %1 = getelementptr inbounds %ys, %ys* %ret, i32 0, i32 1
    %2 = lshr i64 %0, 32
    %3 = trunc i64 %2 to i32
    tail call void @printi(i32 %3)
    %4 = trunc i64 %0 to i32
    tail call void @printi(i32 %4)
    %ret2 = alloca %ys, align 8
    %5 = tail call i64 @ctrl()
    %box3 = bitcast %ys* %ret2 to i64*
    store i64 %5, i64* %box3, align 4
    %6 = trunc i64 %5 to i32
    tail call void @printi(i32 %6)
    %7 = getelementptr inbounds %ys, %ys* %ret2, i32 0, i32 1
    %8 = lshr i64 %5, 32
    %9 = trunc i64 %8 to i32
    tail call void @printi(i32 %9)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  15
  12
  17
  9
