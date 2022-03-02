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
  
  define private void @pass_to_func(%foo* %a) {
  entry:
    %0 = getelementptr inbounds %foo, %foo* %a, i32 0, i32 1
    %1 = load i32, i32* %0, align 4
    tail call void @printi(i32 %1)
    ret void
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %x1 = bitcast %foo* %0 to i32*
    store i32 10, i32* %x1, align 4
    %y = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    store i32 20, i32* %y, align 4
    call void @pass_to_func(%foo* %0)
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
  
  define private void @create_record(%foo* sret %0, i32 %x, i32 %y) {
  entry:
    %x13 = bitcast %foo* %0 to i32*
    store i32 %x, i32* %x13, align 4
    %y2 = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    store i32 %y, i32* %y2, align 4
    ret void
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %ret = alloca %foo, align 8
    call void @create_record(%foo* %ret, i32 8, i32 0)
    %0 = bitcast %foo* %ret to i32*
    %1 = load i32, i32* %0, align 4
    call void @printi(i32 %1)
    ret i32 0
  }
  8

Nested records
  $ schmu -dump-llvm nested.smu && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t_int = type { i32, %p_inner_innerst_int }
  %p_inner_innerst_int = type { %innerst_int }
  %innerst_int = type { i32 }
  %inner = type { i32 }
  %foo = type { i32, %inner }
  
  declare void @printi(i32 %0)
  
  define private void @__g.g___fun0_ti.ti(%t_int* sret %0, %t_int* %x) {
  entry:
    %1 = bitcast %t_int* %0 to i8*
    %2 = bitcast %t_int* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    ret void
  }
  
  define private void @inner(%inner* sret %0) {
  entry:
    %a1 = bitcast %inner* %0 to i32*
    store i32 3, i32* %a1, align 4
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %a3 = bitcast %foo* %0 to i32*
    store i32 0, i32* %a3, align 4
    %b = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    call void @inner(%inner* %b)
    %1 = bitcast %inner* %b to i32*
    %2 = load i32, i32* %1, align 4
    call void @printi(i32 %2)
    %3 = alloca %t_int, align 8
    %x4 = bitcast %t_int* %3 to i32*
    store i32 17, i32* %x4, align 4
    %inner = getelementptr inbounds %t_int, %t_int* %3, i32 0, i32 1
    %a15 = bitcast %p_inner_innerst_int* %inner to %innerst_int*
    %a26 = bitcast %innerst_int* %a15 to i32*
    store i32 124, i32* %a26, align 4
    %ret = alloca %t_int, align 8
    call void @__g.g___fun0_ti.ti(%t_int* %ret, %t_int* %3)
    %4 = getelementptr inbounds %t_int, %t_int* %ret, i32 0, i32 1
    %5 = bitcast %p_inner_innerst_int* %4 to %innerst_int*
    %6 = bitcast %innerst_int* %5 to i32*
    %7 = load i32, i32* %6, align 4
    call void @printi(i32 %7)
    ret i32 0
  }
  
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
  
  define private void @__tg.tg_pass_tb.tb(%t_bool* sret %0, %t_bool* %x) {
  entry:
    %first1 = bitcast %t_bool* %0 to i32*
    %1 = bitcast %t_bool* %x to i32*
    %2 = load i32, i32* %1, align 4
    store i32 %2, i32* %first1, align 4
    %gen = getelementptr inbounds %t_bool, %t_bool* %0, i32 0, i32 1
    %3 = getelementptr inbounds %t_bool, %t_bool* %x, i32 0, i32 1
    %4 = load i1, i1* %3, align 1
    store i1 %4, i1* %gen, align 1
    %third = getelementptr inbounds %t_bool, %t_bool* %0, i32 0, i32 2
    %5 = getelementptr inbounds %t_bool, %t_bool* %x, i32 0, i32 2
    %6 = load i1, i1* %5, align 1
    store i1 %6, i1* %third, align 1
    ret void
  }
  
  define private void @__g.gg.g_apply_tb.tbtb.tb(%t_bool* sret %0, %closure* %f, %t_bool* %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t_bool*, %t_bool*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_bool, align 8
    call void %casttmp(%t_bool* %ret, %t_bool* %x, i8* %loadtmp1)
    %1 = bitcast %t_bool* %0 to i8*
    %2 = bitcast %t_bool* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    ret void
  }
  
  define private void @__tg.tg_pass_ti.ti(%t_int* sret %0, %t_int* %x) {
  entry:
    %first1 = bitcast %t_int* %0 to i32*
    %1 = bitcast %t_int* %x to i32*
    %2 = load i32, i32* %1, align 4
    store i32 %2, i32* %first1, align 4
    %gen = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 1
    %3 = getelementptr inbounds %t_int, %t_int* %x, i32 0, i32 1
    %4 = load i32, i32* %3, align 4
    store i32 %4, i32* %gen, align 4
    %third = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 2
    %5 = getelementptr inbounds %t_int, %t_int* %x, i32 0, i32 2
    %6 = load i1, i1* %5, align 1
    store i1 %6, i1* %third, align 1
    ret void
  }
  
  define private void @__g.gg.g_apply_ti.titi.ti(%t_int* sret %0, %closure* %f, %t_int* %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%t_int*, %t_int*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    call void %casttmp(%t_int* %ret, %t_int* %x, i8* %loadtmp1)
    %1 = bitcast %t_int* %0 to i8*
    %2 = bitcast %t_int* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 12, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %t_int, align 8
    %first8 = bitcast %t_int* %0 to i32*
    store i32 700, i32* %first8, align 4
    %gen = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 1
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 2
    store i1 false, i1* %third, align 1
    %clstmp = alloca %closure, align 8
    %funptr9 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%t_int*, %t_int*)* @__tg.tg_pass_ti.ti to i8*), i8** %funptr9, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    call void @__g.gg.g_apply_ti.titi.ti(%t_int* %ret, %closure* %clstmp, %t_int* %0)
    %1 = bitcast %t_int* %ret to i32*
    %2 = load i32, i32* %1, align 4
    call void @printi(i32 %2)
    %clstmp1 = alloca %closure, align 8
    %funptr210 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (void (%t_bool*, %t_bool*)* @__tg.tg_pass_tb.tb to i8*), i8** %funptr210, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %3 = alloca %t_bool, align 8
    %first411 = bitcast %t_bool* %3 to i32*
    store i32 234, i32* %first411, align 4
    %gen5 = getelementptr inbounds %t_bool, %t_bool* %3, i32 0, i32 1
    store i1 false, i1* %gen5, align 1
    %third6 = getelementptr inbounds %t_bool, %t_bool* %3, i32 0, i32 2
    store i1 true, i1* %third6, align 1
    %ret7 = alloca %t_bool, align 8
    call void @__g.gg.g_apply_tb.tbtb.tb(%t_bool* %ret7, %closure* %clstmp1, %t_bool* %3)
    %4 = bitcast %t_bool* %ret7 to i32*
    %5 = load i32, i32* %4, align 4
    call void @printi(i32 %5)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
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
  
  define private void @__gen_firstg.u_is_gen_firsti.u(%gen_first_int* %any) {
  entry:
    %0 = getelementptr inbounds %gen_first_int, %gen_first_int* %any, i32 0, i32 1
    %1 = load i1, i1* %0, align 1
    tail call void @print_bool(i1 %1)
    ret void
  }
  
  define private i32 @__gen_firstg.g_only_gen_firsti.i(%gen_first_int* %any) {
  entry:
    %0 = bitcast %gen_first_int* %any to i32*
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define private i32 @__tg.g_gen_ti.i(%t_int* %any) {
  entry:
    %0 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 2
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define private void @__tg.u_third_ti.u(%t_int* %any) {
  entry:
    %0 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 3
    %1 = load i1, i1* %0, align 1
    tail call void @print_bool(i1 %1)
    ret void
  }
  
  define private void @__tg.u_first_ti.u(%t_int* %any) {
  entry:
    %0 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 1
    %1 = load i32, i32* %0, align 4
    tail call void @printi(i32 %1)
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
    %null1 = bitcast %t_int* %0 to i32*
    store i32 0, i32* %null1, align 4
    %first = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 1
    store i32 700, i32* %first, align 4
    %gen = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 2
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %t_int, %t_int* %0, i32 0, i32 3
    store i1 true, i1* %third, align 1
    %1 = alloca %gen_first_int, align 8
    %only2 = bitcast %gen_first_int* %1 to i32*
    store i32 420, i32* %only2, align 4
    %is = getelementptr inbounds %gen_first_int, %gen_first_int* %1, i32 0, i32 1
    store i1 false, i1* %is, align 1
    call void @__tg.u_first_ti.u(%t_int* %0)
    call void @__tg.u_third_ti.u(%t_int* %0)
    %2 = call i32 @__tg.g_gen_ti.i(%t_int* %0)
    call void @printi(i32 %2)
    %3 = call i32 @__gen_firstg.g_only_gen_firsti.i(%gen_first_int* %1)
    call void @printi(i32 %3)
    call void @__gen_firstg.u_is_gen_firsti.u(%gen_first_int* %1)
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
  
  define private i32 @__misalignedg.g_gen_misalignedi.i(%misaligned_int* %any) {
  entry:
    %0 = getelementptr inbounds %misaligned_int, %misaligned_int* %any, i32 0, i32 1
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %misaligned_int, align 8
    %fst2 = bitcast %misaligned_int* %0 to %inner*
    %fst13 = bitcast %inner* %fst2 to i32*
    store i32 50, i32* %fst13, align 4
    %snd = getelementptr inbounds %inner, %inner* %fst2, i32 0, i32 1
    store i32 40, i32* %snd, align 4
    %gen = getelementptr inbounds %misaligned_int, %misaligned_int* %0, i32 0, i32 1
    store i32 30, i32* %gen, align 4
    %1 = call i32 @__misalignedg.g_gen_misalignedi.i(%misaligned_int* %0)
    call void @printi(i32 %1)
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
    %lesstmp = icmp slt i32 %4, 10
    br i1 %lesstmp, label %then, label %else
  
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
    %addtmp = add i32 %x, 1
    ret i32 %addtmp
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
  
  define private void @ctrl(%ys* sret %0) {
  entry:
    %y4 = bitcast %ys* %0 to %foo*
    %x5 = bitcast %foo* %y4 to i32*
    store i32 17, i32* %x5, align 4
    %z = getelementptr inbounds %ys, %ys* %0, i32 0, i32 1
    store i32 9, i32* %z, align 4
    %1 = alloca %ys, align 8
    %y16 = bitcast %ys* %1 to %foo*
    %x27 = bitcast %foo* %y16 to i32*
    store i32 1, i32* %x27, align 4
    %z3 = getelementptr inbounds %ys, %ys* %1, i32 0, i32 1
    store i32 2, i32* %z3, align 4
    ret void
  }
  
  define private void @record_with_laters(%ys* sret %0) {
  entry:
    %1 = alloca %foo, align 8
    %x1 = bitcast %foo* %1 to i32*
    store i32 12, i32* %x1, align 4
    %y2 = bitcast %ys* %0 to %foo*
    %2 = bitcast %foo* %y2 to i8*
    %3 = bitcast %foo* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 4, i1 false)
    %z = getelementptr inbounds %ys, %ys* %0, i32 0, i32 1
    store i32 15, i32* %z, align 4
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %ret = alloca %ys, align 8
    call void @record_with_laters(%ys* %ret)
    %0 = getelementptr inbounds %ys, %ys* %ret, i32 0, i32 1
    %1 = load i32, i32* %0, align 4
    call void @printi(i32 %1)
    %2 = bitcast %ys* %ret to %foo*
    %3 = bitcast %foo* %2 to i32*
    %4 = load i32, i32* %3, align 4
    call void @printi(i32 %4)
    %ret1 = alloca %ys, align 8
    call void @ctrl(%ys* %ret1)
    %5 = bitcast %ys* %ret1 to %foo*
    %6 = bitcast %foo* %5 to i32*
    %7 = load i32, i32* %6, align 4
    call void @printi(i32 %7)
    %8 = getelementptr inbounds %ys, %ys* %ret1, i32 0, i32 1
    %9 = load i32, i32* %8, align 4
    call void @printi(i32 %9)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  15
  12
  17
  9
