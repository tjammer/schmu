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
  (Trecord (None, "foo", [|("x", Tbool); ("y", Tint)|]))
  foo
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
  (Trecord (None, "foo", [|("x", Tint); ("y", Tint)|]))
  foo
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
  (Trecord (None, "foo", [|("x", Tint); ("y", Tint)|]))
  foo
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
  (Trecord (None, "inner", [|("z", Tint)|]))
  foo
  inner
  (Trecord (None, "foo",
     [|("x", Tint); ("y", (Trecord (None, "inner", [|("z", Tint)|])))|]))
  foo
  inner
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
  
  define private void @pass(%generic* %0, %generic* %x, i64* %__p_7) {
  entry:
    %_7 = load i64, i64* %__p_7, align 4
    %1 = bitcast %generic* %0 to i8*
    %2 = bitcast %generic* %x to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %2, i64 %_7, i1 false)
    ret void
  }
  
  define private void @apply(%generic* %0, %closure* %f, %generic* %x, i64* %__p_4, i64* %__p_5) {
  entry:
    %_5 = load i64, i64* %__p_5, align 4
    %funcptr4 = bitcast %closure* %f to i8**
    %loadtmp = load i8*, i8** %funcptr4, align 8
    %casttmp = bitcast i8* %loadtmp to void (%generic*, %generic*, i64*, i64*, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f, i32 0, i32 1
    %loadtmp1 = load i8*, i8** %envptr, align 8
    %ret = alloca i8, i64 %_5, align 16
    %ret3 = bitcast i8* %ret to %generic*
    call void %casttmp(%generic* %ret3, %generic* %x, i64* %__p_4, i64* %__p_5, i8* %loadtmp1)
    %1 = bitcast %generic* %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %ret, i64 %_5, i1 false)
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
    store i8* bitcast (void (%generic*, %generic*, i64*)* @pass to i8*), i8** %funptr11, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    %2 = bitcast %int_t* %1 to %generic*
    %3 = alloca i64, align 8
    store i64 12, i64* %3, align 4
    %ret = alloca i8, i64 12, align 16
    %ret1 = bitcast i8* %ret to %generic*
    %4 = alloca i64, align 8
    store i64 12, i64* %4, align 4
    call void @apply(%generic* %ret1, %closure* %clstmp, %generic* %2, i64* %4, i64* %3)
    %5 = bitcast %generic* %ret1 to %int_t*
    %6 = bitcast %int_t* %5 to i32*
    %7 = load i32, i32* %6, align 4
    call void @printi(i32 %7)
    %clstmp2 = alloca %closure, align 8
    %funptr312 = bitcast %closure* %clstmp2 to i8**
    store i8* bitcast (void (%generic*, %generic*, i64*)* @pass to i8*), i8** %funptr312, align 8
    %envptr4 = getelementptr inbounds %closure, %closure* %clstmp2, i32 0, i32 1
    store i8* null, i8** %envptr4, align 8
    %8 = alloca %bool_t, align 8
    %first513 = bitcast %bool_t* %8 to i32*
    store i32 234, i32* %first513, align 4
    %gen6 = getelementptr inbounds %bool_t, %bool_t* %8, i32 0, i32 1
    store i1 false, i1* %gen6, align 1
    %third7 = getelementptr inbounds %bool_t, %bool_t* %8, i32 0, i32 2
    store i1 true, i1* %third7, align 1
    %9 = bitcast %bool_t* %8 to %generic*
    %10 = alloca i64, align 8
    store i64 8, i64* %10, align 4
    %ret8 = alloca i8, i64 8, align 16
    %ret9 = bitcast i8* %ret8 to %generic*
    %11 = alloca i64, align 8
    store i64 8, i64* %11, align 4
    call void @apply(%generic* %ret9, %closure* %clstmp2, %generic* %9, i64* %11, i64* %10)
    %12 = bitcast %generic* %ret9 to %bool_t*
    %13 = bitcast %bool_t* %12 to i32*
    %14 = load i32, i32* %13, align 4
    call void @printi(i32 %14)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  (Trecord ((Some 1), "t", [|("first", Tint); ("gen", Tint); ("third", Tbool)|]
     ))
  bool_t
  generic_t
  int_t
  (Trecord ((Some 1), "t",
     [|("first", Tint); ("gen", Tbool); ("third", Tbool)|]))
  bool_t
  generic_t
  int_t
  unit
  700
  234

Access parametrized record fields
  $ schmu parametrized_get.smu | grep -v x86_64 && cc out.o stub.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %generic_gen_first = type opaque
  %generic = type opaque
  %generic_t = type opaque
  %int_t = type { i32, i32, i32, i1 }
  %int_gen_first = type { i32, i1 }
  
  declare void @printi(i32 %0)
  
  define private void @is(%generic_gen_first* %any, i64* %__p_23_gen_first) {
  entry:
    %0 = getelementptr i64, i64* %__p_23_gen_first, i32 1
    %_23 = load i64, i64* %0, align 4
    %1 = bitcast %generic_gen_first* %any to i8*
    %sub = sub i64 %_23, 1
    %div = udiv i64 %sub, %_23
    %alignup = mul i64 %div, %_23
    %addtmp = add i64 %alignup, %_23
    %sum1 = add i64 %addtmp, 1
    %2 = getelementptr inbounds i8, i8* %1, i64 %addtmp
    %3 = bitcast i8* %2 to i1*
    %4 = load i1, i1* %3, align 1
    tail call void @print_bool(i1 %4)
    ret void
  }
  
  define private void @only(%generic* %0, %generic_gen_first* %any, i64* %__p_20_gen_first) {
  entry:
    %1 = getelementptr i64, i64* %__p_20_gen_first, i32 1
    %_20 = load i64, i64* %1, align 4
    %2 = bitcast %generic_gen_first* %any to i8*
    %3 = bitcast %generic* %0 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %2, i64 %_20, i1 false)
    ret void
  }
  
  define private void @third(%generic_t* %any, i64* %__p_16_t) {
  entry:
    %0 = getelementptr i64, i64* %__p_16_t, i32 1
    %_16 = load i64, i64* %0, align 4
    %1 = bitcast %generic_t* %any to i8*
    %sum = add i64 8, %_16
    %sub = sub i64 %sum, 1
    %div = udiv i64 %sub, %_16
    %alignup = mul i64 %div, %_16
    %addtmp = add i64 %alignup, %_16
    %sum1 = add i64 %addtmp, 1
    %2 = getelementptr inbounds i8, i8* %1, i64 %addtmp
    %3 = bitcast i8* %2 to i1*
    %4 = load i1, i1* %3, align 1
    tail call void @print_bool(i1 %4)
    ret void
  }
  
  define private void @gen(%generic* %0, %generic_t* %any, i64* %__p_13_t) {
  entry:
    %1 = getelementptr i64, i64* %__p_13_t, i32 1
    %_13 = load i64, i64* %1, align 4
    %2 = bitcast %generic_t* %any to i8*
    %sum = add i64 8, %_13
    %sub = sub i64 %sum, 1
    %div = udiv i64 %sub, %_13
    %alignup = mul i64 %div, %_13
    %3 = getelementptr inbounds i8, i8* %2, i64 %alignup
    %4 = bitcast %generic* %0 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %3, i64 %_13, i1 false)
    ret void
  }
  
  define private void @first(%generic_t* %any, i64* %__p_9_t) {
  entry:
    %0 = getelementptr i64, i64* %__p_9_t, i32 1
    %1 = bitcast %generic_t* %any to i8*
    %2 = getelementptr inbounds i8, i8* %1, i64 4
    %3 = bitcast i8* %2 to i32*
    %4 = load i32, i32* %3, align 4
    tail call void @printi(i32 %4)
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
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i32 @main(i32 %0) {
  entry:
    %1 = alloca %int_t, align 8
    %null17 = bitcast %int_t* %1 to i32*
    store i32 0, i32* %null17, align 4
    %first = getelementptr inbounds %int_t, %int_t* %1, i32 0, i32 1
    store i32 700, i32* %first, align 4
    %gen = getelementptr inbounds %int_t, %int_t* %1, i32 0, i32 2
    store i32 20, i32* %gen, align 4
    %third = getelementptr inbounds %int_t, %int_t* %1, i32 0, i32 3
    store i1 true, i1* %third, align 1
    %2 = alloca %int_gen_first, align 8
    %only18 = bitcast %int_gen_first* %2 to i32*
    store i32 420, i32* %only18, align 4
    %is = getelementptr inbounds %int_gen_first, %int_gen_first* %2, i32 0, i32 1
    store i1 false, i1* %is, align 1
    %gencast = bitcast %int_t* %1 to %generic_t*
    %__p_9_t = alloca i64, i32 2, align 8
    store i64 16, i64* %__p_9_t, align 4
    %p1 = getelementptr i64, i64* %__p_9_t, i32 1
    store i64 4, i64* %p1, align 4
    call void @first(%generic_t* %gencast, i64* %__p_9_t)
    %__p_16_t = alloca i64, i32 2, align 8
    store i64 16, i64* %__p_16_t, align 4
    %p13 = getelementptr i64, i64* %__p_16_t, i32 1
    store i64 4, i64* %p13, align 4
    call void @third(%generic_t* %gencast, i64* %__p_16_t)
    %__p_13_t = alloca i64, i32 2, align 8
    store i64 16, i64* %__p_13_t, align 4
    %p16 = getelementptr i64, i64* %__p_13_t, i32 1
    store i64 4, i64* %p16, align 4
    %ret = alloca i8, i64 4, align 16
    %ret7 = bitcast i8* %ret to %generic*
    call void @gen(%generic* %ret7, %generic_t* %gencast, i64* %__p_13_t)
    %3 = bitcast %generic* %ret7 to i32*
    %realret = load i32, i32* %3, align 4
    call void @printi(i32 %realret)
    %gencast8 = bitcast %int_gen_first* %2 to %generic_gen_first*
    %__p_20_gen_first = alloca i64, i32 2, align 8
    store i64 8, i64* %__p_20_gen_first, align 4
    %p110 = getelementptr i64, i64* %__p_20_gen_first, i32 1
    store i64 4, i64* %p110, align 4
    %ret11 = alloca i8, i64 4, align 16
    %ret12 = bitcast i8* %ret11 to %generic*
    call void @only(%generic* %ret12, %generic_gen_first* %gencast8, i64* %__p_20_gen_first)
    %4 = bitcast %generic* %ret12 to i32*
    %realret13 = load i32, i32* %4, align 4
    call void @printi(i32 %realret13)
    %__p_23_gen_first = alloca i64, i32 2, align 8
    store i64 8, i64* %__p_23_gen_first, align 4
    %p116 = getelementptr i64, i64* %__p_23_gen_first, i32 1
    store i64 4, i64* %p116, align 4
    call void @is(%generic_gen_first* %gencast8, i64* %__p_23_gen_first)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  (Trecord ((Some 2), "t",
     [|("null", Tint); ("first", Tint); ("gen", Tint); ("third", Tbool)|]))
  int_gen_first
  generic_t
  int_t
  generic_gen_first
  (Trecord ((Some 0), "gen_first", [|("only", Tint); ("is", Tbool)|]))
  int_gen_first
  generic_t
  int_t
  generic_gen_first
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
  
  %generic = type opaque
  %generic_misaligned = type opaque
  %int_misaligned = type { i1, i32 }
  
  declare void @printi(i32 %0)
  
  define private void @gen(%generic* %0, %generic_misaligned* %any, i64* %__p_3_misaligned) {
  entry:
    %1 = getelementptr i64, i64* %__p_3_misaligned, i32 1
    %_3 = load i64, i64* %1, align 4
    %2 = bitcast %generic_misaligned* %any to i8*
    %sum = add i64 1, %_3
    %3 = getelementptr inbounds i8, i8* %2, i64 %_3
    %4 = bitcast %generic* %0 to i8*
    tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %3, i64 %_3, i1 false)
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
    %__p_3_misaligned = alloca i64, i32 2, align 8
    store i64 8, i64* %__p_3_misaligned, align 4
    %p1 = getelementptr i64, i64* %__p_3_misaligned, i32 1
    store i64 4, i64* %p1, align 4
    %ret = alloca i8, i64 4, align 16
    %ret1 = bitcast i8* %ret to %generic*
    call void @gen(%generic* %ret1, %generic_misaligned* %gencast, i64* %__p_3_misaligned)
    %2 = bitcast %generic* %ret1 to i32*
    %realret = load i32, i32* %2, align 4
    call void @printi(i32 %realret)
    ret i32 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  (Trecord ((Some 1), "misaligned", [|("fst", Tbool); ("gen", Tint)|]))
  int_misaligned
  generic_misaligned
  unit
  30
