Compile stubs
  $ cc -c stub.c

Simple record creation (out of order)
  $ schmu simple.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
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
  unit
  10

Pass record to function
  $ schmu pass.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
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
  unit
  20


Create record
  $ schmu create.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i32, i32 }
  
  declare void @printi(i32 %0)
  
  define private void @create_record(%foo* %0, i32 %x, i32 %y) {
  entry:
    %1 = alloca %foo, align 8
    %x13 = bitcast %foo* %1 to i32*
    store i32 %x, i32* %x13, align 4
    %y2 = getelementptr inbounds %foo, %foo* %1, i32 0, i32 1
    store i32 %y, i32* %y2, align 4
    %2 = bitcast %foo* %0 to i8*
    %3 = bitcast %foo* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %ret = alloca %foo, align 8
    call void @create_record(%foo* %ret, i32 8, i32 0)
    %0 = bitcast %foo* %ret to i32*
    %1 = load i32, i32* %0, align 4
    call void @printi(i32 %1)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  8

Nested records
  $ schmu nested.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %inner = type { i32 }
  %foo = type { i32, %inner }
  
  declare void @printi(i32 %0)
  
  define private void @inner(%inner* %0) {
  entry:
    %1 = alloca %inner, align 8
    %z1 = bitcast %inner* %1 to i32*
    store i32 3, i32* %z1, align 4
    %2 = bitcast %inner* %0 to i8*
    %3 = bitcast %inner* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 4, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %foo, align 8
    %x1 = bitcast %foo* %0 to i32*
    store i32 0, i32* %x1, align 4
    %y = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    %ret = alloca %inner, align 8
    call void @inner(%inner* %ret)
    %1 = bitcast %inner* %y to i8*
    %2 = bitcast %inner* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 4, i1 false)
    %3 = bitcast %inner* %y to i32*
    %4 = load i32, i32* %3, align 4
    call void @printi(i32 %4)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  3

Pass generic record
  $ schmu parametrized_pass.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %bool_t = type { i32, i1, i1 }
  %closure = type { i8*, i8* }
  %int_t = type { i32, i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @__g.g_pass_tb.tb(%bool_t* %0, %bool_t* %x) {
  entry:
    %1 = bitcast %bool_t* %0 to i8*
    %2 = bitcast %bool_t* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    ret void
  }
  
  define private void @__g.gg.g_apply_tb.tbtb.tb(%bool_t* %0, %closure* %f, %bool_t* %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%bool_t*, %bool_t*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %bool_t, align 8
    call void %casttmp(%bool_t* %ret, %bool_t* %x, i8* %loadtmp1)
    %1 = bitcast %bool_t* %0 to i8*
    %2 = bitcast %bool_t* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    ret void
  }
  
  define private void @__g.g_pass_ti.ti(%int_t* %0, %int_t* %x) {
  entry:
    %1 = bitcast %int_t* %0 to i8*
    %2 = bitcast %int_t* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 12, i1 false)
    ret void
  }
  
  define private void @__g.gg.g_apply_ti.titi.ti(%int_t* %0, %closure* %f, %int_t* %x) {
  entry:
    %funcptr2 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr2, align 8
    %casttmp = bitcast i8* %loadtmp to void (%int_t*, %int_t*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca %int_t, align 8
    call void %casttmp(%int_t* %ret, %int_t* %x, i8* %loadtmp1)
    %1 = bitcast %int_t* %0 to i8*
    %2 = bitcast %int_t* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 12, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %int_t, align 8
    %first8 = bitcast %int_t* %0 to i32*
    store i32 700, i32* %first8, align 4
    %gen = getelementptr inbounds %int_t, %int_t* %0, i32 0, i32 1
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %int_t, %int_t* %0, i32 0, i32 2
    store i1 false, i1* %third, align 1
    %clstmp = alloca %closure, align 8
    %funptr9 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%int_t*, %int_t*)* @__g.g_pass_ti.ti to i8*), i8** %funptr9, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %ret = alloca %int_t, align 8
    call void @__g.gg.g_apply_ti.titi.ti(%int_t* %ret, %closure* %clstmp, %int_t* %0)
    %1 = bitcast %int_t* %ret to i32*
    %2 = load i32, i32* %1, align 4
    call void @printi(i32 %2)
    %clstmp1 = alloca %closure, align 8
    %funptr210 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (void (%bool_t*, %bool_t*)* @__g.g_pass_tb.tb to i8*), i8** %funptr210, align 8
    %envptr3 = getelementptr inbounds %closure, %closure* %clstmp1, i32 0, i32 1
    store i8* null, i8** %envptr3, align 8
    %3 = alloca %bool_t, align 8
    %first411 = bitcast %bool_t* %3 to i32*
    store i32 234, i32* %first411, align 4
    %gen5 = getelementptr inbounds %bool_t, %bool_t* %3, i32 0, i32 1
    store i1 false, i1* %gen5, align 1
    %third6 = getelementptr inbounds %bool_t, %bool_t* %3, i32 0, i32 2
    store i1 true, i1* %third6, align 1
    %ret7 = alloca %bool_t, align 8
    call void @__g.gg.g_apply_tb.tbtb.tb(%bool_t* %ret7, %closure* %clstmp1, %bool_t* %3)
    %4 = bitcast %bool_t* %ret7 to i32*
    %5 = load i32, i32* %4, align 4
    call void @printi(i32 %5)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  700
  234

Access parametrized record fields
  $ schmu parametrized_get.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %int_gen_first = type { i32, i1 }
  %int_t = type { i32, i32, i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @__gen_firstg.u_is_gen_firsti.u(%int_gen_first* %any) {
  entry:
    %0 = getelementptr inbounds %int_gen_first, %int_gen_first* %any, i32 0, i32 1
    %1 = load i1, i1* %0, align 1
    tail call void @print_bool(i1 %1)
    ret void
  }
  
  define private i32 @__gen_firstg.g_only_gen_firsti.i(%int_gen_first* %any) {
  entry:
    %0 = bitcast %int_gen_first* %any to i32*
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define private i32 @__tg.g_gen_ti.i(%int_t* %any) {
  entry:
    %0 = getelementptr inbounds %int_t, %int_t* %any, i32 0, i32 2
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define private void @__tg.u_third_ti.u(%int_t* %any) {
  entry:
    %0 = getelementptr inbounds %int_t, %int_t* %any, i32 0, i32 3
    %1 = load i1, i1* %0, align 1
    tail call void @print_bool(i1 %1)
    ret void
  }
  
  define private void @__tg.u_first_ti.u(%int_t* %any) {
  entry:
    %0 = getelementptr inbounds %int_t, %int_t* %any, i32 0, i32 1
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
    %0 = alloca %int_t, align 8
    %null1 = bitcast %int_t* %0 to i32*
    store i32 0, i32* %null1, align 4
    %first = getelementptr inbounds %int_t, %int_t* %0, i32 0, i32 1
    store i32 700, i32* %first, align 4
    %gen = getelementptr inbounds %int_t, %int_t* %0, i32 0, i32 2
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %int_t, %int_t* %0, i32 0, i32 3
    store i1 true, i1* %third, align 1
    %1 = alloca %int_gen_first, align 8
    %only2 = bitcast %int_gen_first* %1 to i32*
    store i32 420, i32* %only2, align 4
    %is = getelementptr inbounds %int_gen_first, %int_gen_first* %1, i32 0, i32 1
    store i1 false, i1* %is, align 1
    call void @__tg.u_first_ti.u(%int_t* %0)
    call void @__tg.u_third_ti.u(%int_t* %0)
    %2 = call i32 @__tg.g_gen_ti.i(%int_t* %0)
    call void @printi(i32 %2)
    %3 = call i32 @__gen_firstg.g_only_gen_firsti.i(%int_gen_first* %1)
    call void @printi(i32 %3)
    call void @__gen_firstg.u_is_gen_firsti.u(%int_gen_first* %1)
    ret i32 0
  }
  unit
  700
  1
  20
  420
  0

Make sure alignment of generic param works
  $ schmu misaligned_get.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %int_misaligned = type { i1, i32 }
  
  declare void @printi(i32 %0)
  
  define private i32 @__misalignedg.g_gen_misalignedi.i(%int_misaligned* %any) {
  entry:
    %0 = getelementptr inbounds %int_misaligned, %int_misaligned* %any, i32 0, i32 1
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %int_misaligned, align 8
    %fst1 = bitcast %int_misaligned* %0 to i1*
    store i1 true, i1* %fst1, align 1
    %gen = getelementptr inbounds %int_misaligned, %int_misaligned* %0, i32 0, i32 1
    store i32 30, i32* %gen, align 4
    %1 = call i32 @__misalignedg.g_gen_misalignedi.i(%int_misaligned* %0)
    call void @printi(i32 %1)
    ret i32 0
  }
  unit
  30
