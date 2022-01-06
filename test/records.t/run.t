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
  
  %t_int = type { i32, %p_inner_innerst_int }
  %p_inner_innerst_int = type { %innerst_int }
  %innerst_int = type { i32 }
  %inner = type { i32 }
  %foo = type { i32, %inner }
  
  declare void @printi(i32 %0)
  
  define private void @__g.g___fun0_it.it(%t_int* %0, %t_int* %x) {
  entry:
    %1 = bitcast %t_int* %0 to i8*
    %2 = bitcast %t_int* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 8, i1 false)
    ret void
  }
  
  define private void @inner(%inner* %0) {
  entry:
    %1 = alloca %inner, align 8
    %c1 = bitcast %inner* %1 to i32*
    store i32 3, i32* %c1, align 4
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
    %a2 = bitcast %foo* %0 to i32*
    store i32 0, i32* %a2, align 4
    %b = getelementptr inbounds %foo, %foo* %0, i32 0, i32 1
    %ret = alloca %inner, align 8
    call void @inner(%inner* %ret)
    %1 = bitcast %inner* %b to i8*
    %2 = bitcast %inner* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 4, i1 false)
    %3 = bitcast %inner* %b to i32*
    %4 = load i32, i32* %3, align 4
    call void @printi(i32 %4)
    %5 = alloca %t_int, align 8
    %x3 = bitcast %t_int* %5 to i32*
    store i32 17, i32* %x3, align 4
    %inner = getelementptr inbounds %t_int, %t_int* %5, i32 0, i32 1
    %6 = alloca %p_inner_innerst_int, align 8
    %y4 = bitcast %p_inner_innerst_int* %6 to %innerst_int*
    %7 = alloca %innerst_int, align 8
    %z5 = bitcast %innerst_int* %7 to i32*
    store i32 124, i32* %z5, align 4
    %8 = bitcast %innerst_int* %y4 to i8*
    %9 = bitcast %innerst_int* %7 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 4, i1 false)
    %10 = bitcast %p_inner_innerst_int* %inner to i8*
    %11 = bitcast %p_inner_innerst_int* %6 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %10, i8* %11, i64 4, i1 false)
    %ret1 = alloca %t_int, align 8
    call void @__g.g___fun0_it.it(%t_int* %ret1, %t_int* %5)
    %12 = getelementptr inbounds %t_int, %t_int* %ret1, i32 0, i32 1
    %13 = bitcast %p_inner_innerst_int* %12 to %innerst_int*
    %14 = bitcast %innerst_int* %13 to i32*
    %15 = load i32, i32* %14, align 4
    call void @printi(i32 %15)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  3
  124

Pass generic record
  $ schmu parametrized_pass.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t_bool = type { i32, i1, i1 }
  %closure = type { i8*, i8* }
  %t_int = type { i32, i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @__gt.gt_pass_bt.bt(%t_bool* %0, %t_bool* %x) {
  entry:
    %1 = alloca %t_bool, align 8
    %first1 = bitcast %t_bool* %1 to i32*
    %2 = bitcast %t_bool* %x to i32*
    %3 = load i32, i32* %2, align 4
    store i32 %3, i32* %first1, align 4
    %gen = getelementptr inbounds %t_bool, %t_bool* %1, i32 0, i32 1
    %4 = getelementptr inbounds %t_bool, %t_bool* %x, i32 0, i32 1
    %5 = load i1, i1* %4, align 1
    store i1 %5, i1* %gen, align 1
    %third = getelementptr inbounds %t_bool, %t_bool* %1, i32 0, i32 2
    %6 = getelementptr inbounds %t_bool, %t_bool* %x, i32 0, i32 2
    %7 = load i1, i1* %6, align 1
    store i1 %7, i1* %third, align 1
    %8 = bitcast %t_bool* %0 to i8*
    %9 = bitcast %t_bool* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 8, i1 false)
    ret void
  }
  
  define private void @__g.gg.g_apply_bt.btbt.bt(%t_bool* %0, %closure* %f, %t_bool* %x) {
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
  
  define private void @__gt.gt_pass_it.it(%t_int* %0, %t_int* %x) {
  entry:
    %1 = alloca %t_int, align 8
    %first1 = bitcast %t_int* %1 to i32*
    %2 = bitcast %t_int* %x to i32*
    %3 = load i32, i32* %2, align 4
    store i32 %3, i32* %first1, align 4
    %gen = getelementptr inbounds %t_int, %t_int* %1, i32 0, i32 1
    %4 = getelementptr inbounds %t_int, %t_int* %x, i32 0, i32 1
    %5 = load i32, i32* %4, align 4
    store i32 %5, i32* %gen, align 4
    %third = getelementptr inbounds %t_int, %t_int* %1, i32 0, i32 2
    %6 = getelementptr inbounds %t_int, %t_int* %x, i32 0, i32 2
    %7 = load i1, i1* %6, align 1
    store i1 %7, i1* %third, align 1
    %8 = bitcast %t_int* %0 to i8*
    %9 = bitcast %t_int* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %8, i8* %9, i64 12, i1 false)
    ret void
  }
  
  define private void @__g.gg.g_apply_it.itit.it(%t_int* %0, %closure* %f, %t_int* %x) {
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
    store i8* bitcast (void (%t_int*, %t_int*)* @__gt.gt_pass_it.it to i8*), i8** %funptr9, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %ret = alloca %t_int, align 8
    call void @__g.gg.g_apply_it.itit.it(%t_int* %ret, %closure* %clstmp, %t_int* %0)
    %1 = bitcast %t_int* %ret to i32*
    %2 = load i32, i32* %1, align 4
    call void @printi(i32 %2)
    %clstmp1 = alloca %closure, align 8
    %funptr210 = bitcast %closure* %clstmp1 to i8**
    store i8* bitcast (void (%t_bool*, %t_bool*)* @__gt.gt_pass_bt.bt to i8*), i8** %funptr210, align 8
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
    call void @__g.gg.g_apply_bt.btbt.bt(%t_bool* %ret7, %closure* %clstmp1, %t_bool* %3)
    %4 = bitcast %t_bool* %ret7 to i32*
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
  
  %gen_first_int = type { i32, i1 }
  %t_int = type { i32, i32, i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @__ggen_first.u_is_igen_first.u(%gen_first_int* %any) {
  entry:
    %0 = getelementptr inbounds %gen_first_int, %gen_first_int* %any, i32 0, i32 1
    %1 = load i1, i1* %0, align 1
    tail call void @print_bool(i1 %1)
    ret void
  }
  
  define private i32 @__ggen_first.g_only_igen_first.i(%gen_first_int* %any) {
  entry:
    %0 = bitcast %gen_first_int* %any to i32*
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define private i32 @__gt.g_gen_it.i(%t_int* %any) {
  entry:
    %0 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 2
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define private void @__gt.u_third_it.u(%t_int* %any) {
  entry:
    %0 = getelementptr inbounds %t_int, %t_int* %any, i32 0, i32 3
    %1 = load i1, i1* %0, align 1
    tail call void @print_bool(i1 %1)
    ret void
  }
  
  define private void @__gt.u_first_it.u(%t_int* %any) {
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
    call void @__gt.u_first_it.u(%t_int* %0)
    call void @__gt.u_third_it.u(%t_int* %0)
    %2 = call i32 @__gt.g_gen_it.i(%t_int* %0)
    call void @printi(i32 %2)
    %3 = call i32 @__ggen_first.g_only_igen_first.i(%gen_first_int* %1)
    call void @printi(i32 %3)
    call void @__ggen_first.u_is_igen_first.u(%gen_first_int* %1)
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
  
  %misaligned_int = type { i1, i32 }
  
  declare void @printi(i32 %0)
  
  define private i32 @__gmisaligned.g_gen_imisaligned.i(%misaligned_int* %any) {
  entry:
    %0 = getelementptr inbounds %misaligned_int, %misaligned_int* %any, i32 0, i32 1
    %1 = load i32, i32* %0, align 4
    ret i32 %1
  }
  
  define i32 @main(i32 %arg) {
  entry:
    %0 = alloca %misaligned_int, align 8
    %fst1 = bitcast %misaligned_int* %0 to i1*
    store i1 true, i1* %fst1, align 1
    %gen = getelementptr inbounds %misaligned_int, %misaligned_int* %0, i32 0, i32 1
    store i32 30, i32* %gen, align 4
    %1 = call i32 @__gmisaligned.g_gen_imisaligned.i(%misaligned_int* %0)
    call void @printi(i32 %1)
    ret i32 0
  }
  unit
  30
