Compile stubs
  $ cc -c stub.c

Simple record creation (out of order)
  $ schmu simple.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo = type { i1, i32 }
  
  declare void @printi(i32 %0)
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca %foo, align 8
    %x1 = bitcast %foo* %1 to i1*
    store i1 true, i1* %x1, align 1
    %y = getelementptr inbounds %foo, %foo* %1, i32 0, i32 1
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
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca %foo, align 8
    %x1 = bitcast %foo* %1 to i32*
    store i32 10, i32* %x1, align 4
    %y = getelementptr inbounds %foo, %foo* %1, i32 0, i32 1
    store i32 20, i32* %y, align 4
    call void @pass_to_func(%foo* %1)
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
  
  define i32 @main(i32 %0) {
  entry:
    %ret = alloca %foo, align 8
    call void @create_record(%foo* %ret, i32 8, i32 0)
    %1 = bitcast %foo* %ret to i32*
    %2 = load i32, i32* %1, align 4
    call void @printi(i32 %2)
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
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca %foo, align 8
    %x1 = bitcast %foo* %1 to i32*
    store i32 0, i32* %x1, align 4
    %y = getelementptr inbounds %foo, %foo* %1, i32 0, i32 1
    %ret = alloca %inner, align 8
    call void @inner(%inner* %ret)
    %2 = bitcast %inner* %y to i8*
    %3 = bitcast %inner* %ret to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 4, i1 false)
    %4 = bitcast %inner* %y to i32*
    %5 = load i32, i32* %4, align 4
    call void @printi(i32 %5)
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
  
  %generic = type opaque
  %closure = type { i8*, i8* }
  %int_t = type { i32, i32, i1 }
  %bool_t = type { i32, i1, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @pass(%generic* %0, %generic* %x, i64 %__7) {
  entry:
    %1 = bitcast %generic* %0 to i8*
    %2 = bitcast %generic* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 %__7, i1 false)
    ret void
  }
  
  define private void @apply(%generic* %0, %closure* %f, %generic* %x, i64 %__4, i64 %__5) {
  entry:
    %funcptr3 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr3, align 8
    %casttmp = bitcast i8* %loadtmp to void (%generic*, %generic*, i64, i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca i8, i64 %__5, align 16
    %ret2 = bitcast i8* %ret to %generic*
    call void %casttmp(%generic* %ret2, %generic* %x, i64 %__4, i64 %__5, i8* %loadtmp1)
    %1 = bitcast %generic* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %ret, i64 %__5, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca %int_t, align 8
    %first10 = bitcast %int_t* %1 to i32*
    store i32 700, i32* %first10, align 4
    %gen = getelementptr inbounds %int_t, %int_t* %1, i32 0, i32 1
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %int_t, %int_t* %1, i32 0, i32 2
    store i1 false, i1* %third, align 1
    %clstmp = alloca %closure, align 8
    %funptr11 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (%generic*, %generic*, i64)* @pass to i8*), i8** %funptr11, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %2 = bitcast %int_t* %1 to %generic*
    %ret = alloca i8, i64 12, align 16
    %ret1 = bitcast i8* %ret to %generic*
    call void @apply(%generic* %ret1, %closure* %clstmp, %generic* %2, i64 12, i64 12)
    %3 = bitcast %generic* %ret1 to %int_t*
    %4 = bitcast %int_t* %3 to i32*
    %5 = load i32, i32* %4, align 4
    call void @printi(i32 %5)
    %clstmp2 = alloca %closure, align 8
    %funptr312 = bitcast %closure* %clstmp2 to i8**
    store i8* bitcast (void (%generic*, %generic*, i64)* @pass to i8*), i8** %funptr312, align 8
    %envptr4 = getelementptr inbounds %closure, %closure* %clstmp2, i32 0, i32 1
    store i8* null, i8** %envptr4, align 8
    %6 = alloca %bool_t, align 8
    %first513 = bitcast %bool_t* %6 to i32*
    store i32 234, i32* %first513, align 4
    %gen6 = getelementptr inbounds %bool_t, %bool_t* %6, i32 0, i32 1
    store i1 false, i1* %gen6, align 1
    %third7 = getelementptr inbounds %bool_t, %bool_t* %6, i32 0, i32 2
    store i1 true, i1* %third7, align 1
    %7 = bitcast %bool_t* %6 to %generic*
    %ret8 = alloca i8, i64 8, align 16
    %ret9 = bitcast i8* %ret8 to %generic*
    call void @apply(%generic* %ret9, %closure* %clstmp2, %generic* %7, i64 8, i64 8)
    %8 = bitcast %generic* %ret9 to %bool_t*
    %9 = bitcast %bool_t* %8 to i32*
    %10 = load i32, i32* %9, align 4
    call void @printi(i32 %10)
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
  
  %generic_t = type opaque
  %generic = type opaque
  %int_t = type { i32, i32, i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @third(%generic_t* %any, i64 %__0) {
  entry:
    %0 = bitcast %generic_t* %any to i8*
    %sub = sub i64 %__0, 1
    %div = udiv i64 %sub, %__0
    %alignup = mul i64 %div, %__0
    %size = add i64 %__0, %alignup
    %cmp = icmp slt i64 1, %__0
    %align = select i1 %cmp, i64 %__0, i64 1
    %sum1 = add i64 %size, %align
    %sub2 = sub i64 %sum1, 1
    %div3 = udiv i64 %sub2, %align
    %alignup4 = mul i64 %div3, %align
    %sum5 = add i64 8, %alignup4
    %sub6 = sub i64 %sum5, 1
    %div7 = udiv i64 %sub6, %alignup4
    %alignup8 = mul i64 %div7, %alignup4
    %size9 = add i64 %alignup4, %alignup8
    %cmp10 = icmp slt i64 1, %alignup4
    %align11 = select i1 %cmp10, i64 %alignup4, i64 1
    %sum12 = add i64 %size9, 1
    %1 = getelementptr inbounds i8, i8* %0, i64 %size9
    %2 = bitcast i8* %1 to i1*
    %3 = load i1, i1* %2, align 1
    br i1 %3, label %then, label %else
  
  then:                                             ; preds = %entry
    tail call void @printi(i32 1)
    ret void
  
  else:                                             ; preds = %entry
    tail call void @printi(i32 0)
    ret void
  }
  
  define private void @gen(%generic* %0, %generic_t* %any, i64 %__0) {
  entry:
    %1 = bitcast %generic_t* %any to i8*
    %sub = sub i64 %__0, 1
    %div = udiv i64 %sub, %__0
    %alignup = mul i64 %div, %__0
    %size = add i64 %__0, %alignup
    %cmp = icmp slt i64 1, %__0
    %align = select i1 %cmp, i64 %__0, i64 1
    %sum1 = add i64 %size, %align
    %sub2 = sub i64 %sum1, 1
    %div3 = udiv i64 %sub2, %align
    %alignup4 = mul i64 %div3, %align
    %sum5 = add i64 8, %alignup4
    %sub6 = sub i64 %sum5, 1
    %div7 = udiv i64 %sub6, %alignup4
    %alignup8 = mul i64 %div7, %alignup4
    %2 = getelementptr inbounds i8, i8* %1, i64 %alignup8
    %3 = bitcast %generic* %0 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %2, i64 %__0, i1 false)
    ret void
  }
  
  define private void @first(%generic_t* %any, i64 %__0) {
  entry:
    %0 = bitcast %generic_t* %any to i8*
    %1 = getelementptr inbounds i8, i8* %0, i64 4
    %2 = bitcast i8* %1 to i32*
    %3 = load i32, i32* %2, align 4
    tail call void @printi(i32 %3)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca %int_t, align 8
    %null4 = bitcast %int_t* %1 to i32*
    store i32 0, i32* %null4, align 4
    %first = getelementptr inbounds %int_t, %int_t* %1, i32 0, i32 1
    store i32 700, i32* %first, align 4
    %gen = getelementptr inbounds %int_t, %int_t* %1, i32 0, i32 2
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %int_t, %int_t* %1, i32 0, i32 3
    store i1 true, i1* %third, align 1
    %gencast = bitcast %int_t* %1 to %generic_t*
    call void @first(%generic_t* %gencast, i64 4)
    call void @third(%generic_t* %gencast, i64 4)
    %ret = alloca i8, i64 4, align 16
    %ret3 = bitcast i8* %ret to %generic*
    call void @gen(%generic* %ret3, %generic_t* %gencast, i64 4)
    %2 = bitcast %generic* %ret3 to i32*
    %realret = load i32, i32* %2, align 4
    call void @printi(i32 %realret)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  700
  1
  20

Make sure alignment of generic param works
  $ schmu misaligned_get.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %generic = type opaque
  %generic_misaligned = type opaque
  %int_misaligned = type { i1, i32 }
  
  declare void @printi(i32 %0)
  
  define private void @gen(%generic* %0, %generic_misaligned* %any, i64 %__0) {
  entry:
    %1 = bitcast %generic_misaligned* %any to i8*
    %sub = sub i64 %__0, 1
    %div = udiv i64 %sub, %__0
    %alignup = mul i64 %div, %__0
    %size = add i64 %__0, %alignup
    %cmp = icmp slt i64 1, %__0
    %align = select i1 %cmp, i64 %__0, i64 1
    %sum1 = add i64 %size, %align
    %sub2 = sub i64 %sum1, 1
    %div3 = udiv i64 %sub2, %align
    %alignup4 = mul i64 %div3, %align
    %sum5 = add i64 1, %alignup4
    %2 = getelementptr inbounds i8, i8* %1, i64 %alignup4
    %3 = bitcast %generic* %0 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %2, i64 %__0, i1 false)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca %int_misaligned, align 8
    %fst2 = bitcast %int_misaligned* %1 to i1*
    store i1 true, i1* %fst2, align 1
    %gen = getelementptr inbounds %int_misaligned, %int_misaligned* %1, i32 0, i32 1
    store i32 30, i32* %gen, align 4
    %gencast = bitcast %int_misaligned* %1 to %generic_misaligned*
    %ret = alloca i8, i64 4, align 16
    %ret1 = bitcast i8* %ret to %generic*
    call void @gen(%generic* %ret1, %generic_misaligned* %gencast, i64 4)
    %2 = bitcast %generic* %ret1 to i32*
    %realret = load i32, i32* %2, align 4
    call void @printi(i32 %realret)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  unit
  30
