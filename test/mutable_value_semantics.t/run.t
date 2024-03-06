Test simple setting of mutable variables
  $ schmu --dump-llvm simple_set.smu && valgrind -q --leak-check=yes --show-reachable=yes ./simple_set
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_b = global i64 10, align 8
  @schmu_a = global ptr null, align 8
  @schmu_b__3 = global ptr null, align 8
  @schmu_c = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define i64 @schmu_hmm() {
  entry:
    %0 = alloca i64, align 8
    store i64 10, ptr %0, align 8
    store i64 15, ptr %0, align 8
    ret i64 15
  }
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 14, ptr @schmu_b, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 14)
    %0 = tail call i64 @schmu_hmm()
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %1 = tail call ptr @malloc(i64 32)
    store ptr %1, ptr @schmu_a, align 8
    store i64 2, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 2, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = tail call ptr @malloc(i64 24)
    store ptr %3, ptr %2, align 8
    store i64 1, ptr %3, align 8
    %cap2 = getelementptr i64, ptr %3, i64 1
    store i64 1, ptr %cap2, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 10, ptr %4, align 8
    %"1" = getelementptr ptr, ptr %2, i64 1
    %5 = tail call ptr @malloc(i64 24)
    store ptr %5, ptr %"1", align 8
    store i64 1, ptr %5, align 8
    %cap5 = getelementptr i64, ptr %5, i64 1
    store i64 1, ptr %cap5, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store i64 20, ptr %6, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b__3, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_2al2_(ptr @schmu_b__3)
    %7 = tail call ptr @malloc(i64 24)
    store ptr %7, ptr @schmu_c, align 8
    store i64 1, ptr %7, align 8
    %cap8 = getelementptr i64, ptr %7, i64 1
    store i64 1, ptr %cap8, align 8
    %8 = getelementptr i8, ptr %7, i64 16
    store i64 30, ptr %8, align 8
    %9 = load ptr, ptr @schmu_a, align 8
    %10 = getelementptr i8, ptr %9, i64 16
    %11 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %11, ptr align 8 @schmu_c, i64 8, i1 false)
    call void @__copy_al_(ptr %11)
    call void @__free_al_(ptr %10)
    %12 = load ptr, ptr %11, align 8
    store ptr %12, ptr %10, align 8
    %13 = load ptr, ptr @schmu_a, align 8
    %14 = getelementptr i8, ptr %13, i64 16
    %15 = call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %15, ptr %arr, align 8
    store i64 1, ptr %15, align 8
    %cap11 = getelementptr i64, ptr %15, i64 1
    store i64 1, ptr %cap11, align 8
    %16 = getelementptr i8, ptr %15, i64 16
    store i64 10, ptr %16, align 8
    call void @__free_al_(ptr %14)
    store ptr %15, ptr %14, align 8
    call void @__free_al_(ptr @schmu_c)
    call void @__free_2al2_(ptr @schmu_b__3)
    call void @__free_2al2_(ptr @schmu_a)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_2al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %5 = load i64, ptr %cnt, align 8
    %6 = icmp slt i64 %5, %size
    br i1 %6, label %child, label %cont
  
  child:                                            ; preds = %rec
    %7 = getelementptr i8, ptr %1, i64 16
    %8 = getelementptr ptr, ptr %7, i64 %5
    call void @__copy_al_(ptr %8)
    %9 = add i64 %5, 1
    store i64 %9, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_2al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, ptr %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = getelementptr i8, ptr %1, i64 16
    %5 = getelementptr ptr, ptr %4, i64 %2
    call void @__free_al_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  14
  15

Warn on unneeded mutable bindings
  $ schmu unneeded_mut.smu
  unneeded_mut.smu:1.5-15: warning: Unused binding do_nothing.
  
  1 | fun do_nothing(a&): ignore(a)
          ^^^^^^^^^^
  
Use mutable values as ptrs to C code
  $ schmu -c --dump-llvm ptr_to_c.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo_ = type { i64 }
  
  @schmu_i = global i64 0, align 8
  @schmu_foo = global %foo_ zeroinitializer, align 8
  
  declare void @mutate_int(ptr noalias %0)
  
  declare void @mutate_foo(ptr noalias %0)
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @mutate_int(ptr @schmu_i)
    tail call void @mutate_foo(ptr @schmu_foo)
    ret i64 0
  }

Check aliasing
  $ schmu --dump-llvm mut_alias.smu && valgrind -q --leak-check=yes --show-reachable=yes ./mut_alias
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %foo_ = type { i64 }
  
  @schmu_f = global %foo_ zeroinitializer, align 8
  @schmu_fst = global %foo_ zeroinitializer, align 8
  @schmu_snd = global %foo_ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define void @schmu_new_fun() {
  entry:
    %0 = alloca %foo_, align 8
    store i64 0, ptr %0, align 8
    %1 = alloca %foo_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    %2 = alloca %foo_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %1, i64 8, i1 false)
    store i64 1, ptr %1, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 1)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 0)
    %3 = load i64, ptr %2, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %3)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(ptr %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 0, ptr @schmu_f, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_fst, ptr align 8 @schmu_f, i64 8, i1 false)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_snd, ptr align 8 @schmu_fst, i64 8, i1 false)
    store i64 1, ptr @schmu_fst, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 1)
    %0 = load i64, ptr @schmu_f, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %1 = load i64, ptr @schmu_snd, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    tail call void @schmu_new_fun()
    ret i64 0
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  1
  0
  0
  1
  0
  0

Const let
  $ schmu --dump-llvm const_let.smu && valgrind -q --leak-check=yes --show-reachable=yes ./const_let
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_v = global ptr null, align 8
  @schmu_const = global i64 0, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define void @schmu_in_fun() {
  entry:
    %0 = alloca ptr, align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr %0, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 0, ptr %2, align 8
    %3 = load ptr, ptr %0, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    %5 = alloca i64, align 8
    %6 = load i64, ptr %4, align 8
    store i64 %6, ptr %5, align 8
    store i64 1, ptr %4, align 8
    %7 = load ptr, ptr %0, align 8
    %8 = getelementptr i8, ptr %7, i64 16
    %9 = load i64, ptr %8, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %9)
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %6)
    call void @__free_al_(ptr %0)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_v, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 0, ptr %1, align 8
    %2 = load ptr, ptr @schmu_v, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    %4 = load i64, ptr %3, align 8
    store i64 %4, ptr @schmu_const, align 8
    store i64 1, ptr %3, align 8
    %5 = load ptr, ptr @schmu_v, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = load i64, ptr %6, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %7)
    %8 = load i64, ptr @schmu_const, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %8)
    tail call void @schmu_in_fun()
    tail call void @__free_al_(ptr @schmu_v)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  1
  0
  1
  0


Copies, but with ref-counted arrays
  $ schmu array_copies.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./array_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global ptr null, align 8
  @schmu_b = global ptr null, align 8
  @schmu_c = global ptr null, align 8
  @schmu_d = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [7 x i8] } { i64 6, i64 6, [7 x i8] c"in fun\00" }
  
  declare void @string_print(ptr %0)
  
  define linkonce_odr void @__schmu_print_0th_al__(ptr %a) {
  entry:
    %0 = getelementptr i8, ptr %a, i64 16
    %1 = load i64, ptr %0, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %1)
    ret void
  }
  
  define void @schmu_in_fun() {
  entry:
    tail call void @string_print(ptr @1)
    %0 = alloca ptr, align 8
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr %0, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    %3 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_al_(ptr %3)
    %4 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_al_(ptr %4)
    %5 = load ptr, ptr %0, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    store i64 12, ptr %6, align 8
    %7 = load ptr, ptr %0, align 8
    call void @__schmu_print_0th_al__(ptr %7)
    %8 = load ptr, ptr %4, align 8
    %9 = getelementptr i8, ptr %8, i64 16
    store i64 15, ptr %9, align 8
    %10 = load ptr, ptr %0, align 8
    call void @__schmu_print_0th_al__(ptr %10)
    %11 = load ptr, ptr %3, align 8
    call void @__schmu_print_0th_al__(ptr %11)
    %12 = load ptr, ptr %4, align 8
    call void @__schmu_print_0th_al__(ptr %12)
    %13 = load ptr, ptr %3, align 8
    call void @__schmu_print_0th_al__(ptr %13)
    call void @__free_al_(ptr %4)
    call void @__free_al_(ptr %3)
    call void @__free_al_(ptr %0)
    ret void
  }
  
  declare void @printf(ptr %0, ...)
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_a, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_al_(ptr @schmu_b)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_c, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_al_(ptr @schmu_c)
    %2 = load ptr, ptr @schmu_b, align 8
    store ptr %2, ptr @schmu_d, align 8
    %3 = load ptr, ptr @schmu_a, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 12, ptr %4, align 8
    %5 = load ptr, ptr @schmu_a, align 8
    tail call void @__schmu_print_0th_al__(ptr %5)
    %6 = load ptr, ptr @schmu_c, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    store i64 15, ptr %7, align 8
    %8 = load ptr, ptr @schmu_a, align 8
    tail call void @__schmu_print_0th_al__(ptr %8)
    %9 = load ptr, ptr @schmu_b, align 8
    tail call void @__schmu_print_0th_al__(ptr %9)
    %10 = load ptr, ptr @schmu_c, align 8
    tail call void @__schmu_print_0th_al__(ptr %10)
    %11 = load ptr, ptr @schmu_d, align 8
    tail call void @__schmu_print_0th_al__(ptr %11)
    tail call void @schmu_in_fun()
    tail call void @__free_al_(ptr @schmu_c)
    tail call void @__free_al_(ptr @schmu_b)
    tail call void @__free_al_(ptr @schmu_a)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  12
  12
  10
  15
  10
  in fun
  12
  12
  10
  15
  10

Arrays in records
  $ schmu array_in_record_copies.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./array_in_record_copies
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %arrec_ = type { ptr }
  
  @schmu_a = global %arrec_ zeroinitializer, align 8
  @schmu_b = global %arrec_ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [7 x i8] } { i64 6, i64 6, [7 x i8] c"in fun\00" }
  
  declare void @string_print(ptr %0)
  
  define void @schmu_in_fun() {
  entry:
    %0 = alloca %arrec_, align 8
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    store ptr %1, ptr %0, align 8
    %3 = alloca %arrec_, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_al2_(ptr %3)
    store i64 12, ptr %2, align 8
    %unbox = load i64, ptr %0, align 8
    call void @schmu_print_thing(i64 %unbox)
    %unbox1 = load i64, ptr %3, align 8
    call void @schmu_print_thing(i64 %unbox1)
    call void @__free_al2_(ptr %3)
    call void @__free_al2_(ptr %0)
    ret void
  }
  
  define void @schmu_print_thing(i64 %0) {
  entry:
    %a = alloca i64, align 8
    store i64 %0, ptr %a, align 8
    %1 = inttoptr i64 %0 to ptr
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = load i64, ptr %2, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %3)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_al2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__copy_al_(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_al2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_al_(ptr %1)
    ret void
  }
  
  declare void @printf(ptr %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    store ptr %0, ptr @schmu_a, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_al2_(ptr @schmu_b)
    %2 = load ptr, ptr @schmu_a, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i64 12, ptr %3, align 8
    %unbox = load i64, ptr @schmu_a, align 8
    tail call void @schmu_print_thing(i64 %unbox)
    %unbox1 = load i64, ptr @schmu_b, align 8
    tail call void @schmu_print_thing(i64 %unbox1)
    tail call void @string_print(ptr @1)
    tail call void @schmu_in_fun()
    tail call void @__free_al2_(ptr @schmu_b)
    tail call void @__free_al2_(ptr @schmu_a)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  12
  10
  in fun
  12
  10

Nested arrays
  $ schmu nested_array.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./nested_array
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global ptr null, align 8
  @schmu_b = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"%li, %li\0A\00" }
  
  define linkonce_odr void @__schmu_prnt_2al2__(ptr %a) {
  entry:
    %0 = getelementptr i8, ptr %a, i64 16
    %1 = load ptr, ptr %0, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = load i64, ptr %2, align 8
    %4 = getelementptr ptr, ptr %0, i64 1
    %5 = load ptr, ptr %4, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = load i64, ptr %6, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %3, i64 %7)
    ret void
  }
  
  declare void @printf(ptr %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    store ptr %0, ptr @schmu_a, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = tail call ptr @malloc(i64 24)
    store ptr %2, ptr %1, align 8
    store i64 1, ptr %2, align 8
    %cap2 = getelementptr i64, ptr %2, i64 1
    store i64 1, ptr %cap2, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    store i64 10, ptr %3, align 8
    %"1" = getelementptr ptr, ptr %1, i64 1
    %4 = tail call ptr @malloc(i64 24)
    store ptr %4, ptr %"1", align 8
    store i64 1, ptr %4, align 8
    %cap5 = getelementptr i64, ptr %4, i64 1
    store i64 1, ptr %cap5, align 8
    %5 = getelementptr i8, ptr %4, i64 16
    store i64 20, ptr %5, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 @schmu_a, i64 8, i1 false)
    tail call void @__copy_2al2_(ptr @schmu_b)
    %6 = load ptr, ptr @schmu_a, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    %8 = load ptr, ptr %7, align 8
    %9 = getelementptr i8, ptr %8, i64 16
    store i64 15, ptr %9, align 8
    %10 = load ptr, ptr @schmu_a, align 8
    tail call void @__schmu_prnt_2al2__(ptr %10)
    %11 = load ptr, ptr @schmu_b, align 8
    tail call void @__schmu_prnt_2al2__(ptr %11)
    tail call void @__free_2al2_(ptr @schmu_b)
    tail call void @__free_2al2_(ptr @schmu_a)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_2al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %5 = load i64, ptr %cnt, align 8
    %6 = icmp slt i64 %5, %size
    br i1 %6, label %child, label %cont
  
  child:                                            ; preds = %rec
    %7 = getelementptr i8, ptr %1, i64 16
    %8 = getelementptr ptr, ptr %7, i64 %5
    call void @__copy_al_(ptr %8)
    %9 = add i64 %5, 1
    store i64 %9, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_2al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, ptr %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = getelementptr i8, ptr %1, i64 16
    %5 = getelementptr ptr, ptr %4, i64 %2
    call void @__free_al_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  15, 20
  10, 20


Modify in function
  $ schmu --dump-llvm modify_in_fn.smu && valgrind -q --leak-check=yes --show-reachable=yes ./modify_in_fn
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %f_ = type { i64 }
  
  @schmu_a = global %f_ zeroinitializer, align 8
  @schmu_b = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  
  define linkonce_odr void @__array_push_al_l_(ptr noalias %arr, i64 %value) {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else
  
  then2:                                            ; preds = %then
    %3 = tail call ptr @realloc(ptr %0, i64 48)
    store ptr %3, ptr %arr, align 8
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 4, ptr %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %1
    %4 = mul i64 %mul, 8
    %5 = add i64 %4, 16
    %6 = tail call ptr @realloc(ptr %0, i64 %5)
    store ptr %6, ptr %arr, align 8
    %newcap3 = getelementptr i64, ptr %6, i64 1
    store i64 %mul, ptr %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %7 = phi ptr [ %6, %else ], [ %3, %then2 ], [ %0, %entry ]
    %8 = getelementptr i8, ptr %7, i64 16
    %9 = getelementptr inbounds i64, ptr %8, i64 %2
    store i64 %value, ptr %9, align 8
    %10 = load ptr, ptr %arr, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %10, align 8
    ret void
  }
  
  define void @schmu_mod2(ptr noalias %a) {
  entry:
    tail call void @__array_push_al_l_(ptr %a, i64 20)
    ret void
  }
  
  define void @schmu_modify(ptr noalias %r) {
  entry:
    store i64 30, ptr %r, align 8
    ret void
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    store i64 20, ptr @schmu_a, align 8
    tail call void @schmu_modify(ptr @schmu_a)
    %0 = load i64, ptr @schmu_a, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %0)
    %1 = tail call ptr @malloc(i64 24)
    store ptr %1, ptr @schmu_b, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    store i64 10, ptr %2, align 8
    tail call void @schmu_mod2(ptr @schmu_b)
    %3 = load ptr, ptr @schmu_b, align 8
    %4 = load i64, ptr %3, align 8
    tail call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %4)
    tail call void @__free_al_(ptr @schmu_b)
    ret i64 0
  }
  
  declare void @printf(ptr %0, ...)
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  30
  2

Make sure variable ids are correctly propagated
  $ schmu --dump-llvm varid_propagate.smu && valgrind -q --leak-check=yes --show-reachable=yes ./varid_propagate
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr void @__array_push_al_l_(ptr noalias %arr, i64 %value) {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %capacity = getelementptr i64, ptr %0, i64 1
    %1 = load i64, ptr %capacity, align 8
    %2 = load i64, ptr %0, align 8
    %eq = icmp eq i64 %1, %2
    br i1 %eq, label %then, label %ifcont5
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %1, 0
    br i1 %eq1, label %then2, label %else
  
  then2:                                            ; preds = %then
    %3 = tail call ptr @realloc(ptr %0, i64 48)
    store ptr %3, ptr %arr, align 8
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 4, ptr %newcap, align 8
    br label %ifcont5
  
  else:                                             ; preds = %then
    %mul = mul i64 2, %1
    %4 = mul i64 %mul, 8
    %5 = add i64 %4, 16
    %6 = tail call ptr @realloc(ptr %0, i64 %5)
    store ptr %6, ptr %arr, align 8
    %newcap3 = getelementptr i64, ptr %6, i64 1
    store i64 %mul, ptr %newcap3, align 8
    br label %ifcont5
  
  ifcont5:                                          ; preds = %entry, %then2, %else
    %7 = phi ptr [ %6, %else ], [ %3, %then2 ], [ %0, %entry ]
    %8 = getelementptr i8, ptr %7, i64 16
    %9 = getelementptr inbounds i64, ptr %8, i64 %2
    store i64 %value, ptr %9, align 8
    %10 = load ptr, ptr %arr, align 8
    %add = add i64 %2, 1
    store i64 %add, ptr %10, align 8
    ret void
  }
  
  define linkonce_odr ptr @__schmu_f1_al_lral__(ptr %acc, i64 %v) {
  entry:
    %0 = alloca ptr, align 8
    %1 = alloca ptr, align 8
    store ptr %acc, ptr %1, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %1, i64 8, i1 false)
    call void @__copy_al_(ptr %0)
    call void @__array_push_al_l_(ptr %0, i64 %v)
    %2 = load ptr, ptr %0, align 8
    ret ptr %2
  }
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  define linkonce_odr void @__copy_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 0, ptr %1, align 8
    %2 = load ptr, ptr %arr, align 8
    %3 = tail call ptr @__schmu_f1_al_lral__(ptr %2, i64 0)
    %4 = alloca ptr, align 8
    store ptr %3, ptr %4, align 8
    call void @__free_al_(ptr %4)
    call void @__free_al_(ptr %arr)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }

Free array params correctly if they are returned
  $ schmu --dump-llvm pass_array_param.smu && valgrind -q --leak-check=yes --show-reachable=yes ./pass_array_param
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr ptr @__schmu_pass_al_ral__(ptr %x) {
  entry:
    ret ptr %x
  }
  
  define ptr @schmu_create() {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %0, ptr %arr, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    %2 = tail call ptr @__schmu_pass_al_ral__(ptr %0)
    ret ptr %2
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call ptr @schmu_create()
    %1 = alloca ptr, align 8
    store ptr %0, ptr %1, align 8
    call void @__free_al_(ptr %1)
    ret i64 0
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)

Refcounts for members in arrays, records and variants
  $ schmu --dump-llvm member_refcounts.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %r_ = type { ptr }
  %option.tal__ = type { i32, ptr }
  
  @schmu_a = global ptr null, align 8
  @schmu_r = global %r_ zeroinitializer, align 8
  @schmu_r__2 = global ptr null, align 8
  @schmu_r__3 = global %option.tal__ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"none\00" }
  
  declare void @string_print(ptr %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_a, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    store i64 10, ptr %1, align 8
    %2 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_al_(ptr %2)
    %3 = load ptr, ptr %2, align 8
    store ptr %3, ptr @schmu_r, align 8
    %4 = load ptr, ptr @schmu_a, align 8
    %5 = getelementptr i8, ptr %4, i64 16
    store i64 20, ptr %5, align 8
    %6 = load ptr, ptr @schmu_r, align 8
    %7 = getelementptr i8, ptr %6, i64 16
    %8 = load i64, ptr %7, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %8)
    %9 = call ptr @malloc(i64 24)
    store ptr %9, ptr @schmu_r__2, align 8
    store i64 1, ptr %9, align 8
    %cap2 = getelementptr i64, ptr %9, i64 1
    store i64 1, ptr %cap2, align 8
    %10 = getelementptr i8, ptr %9, i64 16
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %10, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_al_(ptr %10)
    %11 = load ptr, ptr @schmu_a, align 8
    %12 = getelementptr i8, ptr %11, i64 16
    store i64 30, ptr %12, align 8
    %13 = load ptr, ptr @schmu_r__2, align 8
    %14 = getelementptr i8, ptr %13, i64 16
    %15 = load ptr, ptr %14, align 8
    %16 = getelementptr i8, ptr %15, i64 16
    %17 = load i64, ptr %16, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %17)
    store i32 0, ptr @schmu_r__3, align 4
    %18 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %18, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_al_(ptr %18)
    %19 = load ptr, ptr %18, align 8
    store ptr %19, ptr getelementptr inbounds (%option.tal__, ptr @schmu_r__3, i32 0, i32 1), align 8
    %20 = load ptr, ptr @schmu_a, align 8
    %21 = getelementptr i8, ptr %20, i64 16
    store i64 40, ptr %21, align 8
    %index = load i32, ptr @schmu_r__3, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %22 = load ptr, ptr getelementptr inbounds (%option.tal__, ptr @schmu_r__3, i32 0, i32 1), align 8
    %23 = getelementptr i8, ptr %22, i64 16
    %24 = load i64, ptr %23, align 8
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @0, i64 16), i64 %24)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @string_print(ptr @1)
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    call void @__free_val2_(ptr @schmu_r__3)
    call void @__free_2al2_(ptr @schmu_r__2)
    call void @__free_al2_(ptr @schmu_r)
    call void @__free_al_(ptr @schmu_a)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call ptr @malloc(i64 %3)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %4, ptr align 1 %1, i64 %3, i1 false)
    %newcap = getelementptr i64, ptr %4, i64 1
    store i64 %size, ptr %newcap, align 8
    store ptr %4, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_val2_(ptr %0) {
  entry:
    %tag1 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag1, align 4
    %1 = icmp eq i32 %index, 0
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.tal__, ptr %0, i32 0, i32 1
    call void @__free_al_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_2al2_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %2 = load i64, ptr %cnt, align 8
    %3 = icmp slt i64 %2, %size
    br i1 %3, label %child, label %cont
  
  child:                                            ; preds = %rec
    %4 = getelementptr i8, ptr %1, i64 16
    %5 = getelementptr ptr, ptr %4, i64 %2
    call void @__free_al_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_al2_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_al_(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  $ valgrind -q --leak-check=yes --show-reachable=yes ./member_refcounts
  10
  20
  30

Make sure there are no hidden reference semantics in pattern matches
  $ schmu hidden_match_reference.smu && ./hidden_match_reference
  1

Convert Const_ptr values to Ptr in copy
  $ schmu ref_to_const.smu

Fix codegen
  $ schmu --dump-llvm codegen_nested_projections.smu
  codegen_nested_projections.smu:4.7-8: warning: Unused binding z.
  
  4 |   let z& = &y
            ^
  
  codegen_nested_projections.smu:1.5-6: warning: Unused binding t.
  
  1 | fun t():
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define i64 @schmu_t() {
  entry:
    %0 = alloca i64, align 8
    store i64 10, ptr %0, align 8
    store i64 11, ptr %0, align 8
    ret i64 11
  }
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 0
  }

Partial move parameter
  $ schmu partially_move_parameter.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./partially_move_parameter

Partial move set
  $ schmu partial_move_set.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./partial_move_set

Track unmutated binding warnings across projections
  $ schmu projection_warnings.smu
  projection_warnings.smu:9.16-17: warning: Unused binding b.
  
  9 | fun testfn(a&, b& : int):
                     ^
  
  projection_warnings.smu:4.7-8: warning: Unused binding z.
  
  4 |   let z& = &y
            ^
  
  projection_warnings.smu:9.5-11: warning: Unused binding testfn.
  
  9 | fun testfn(a&, b& : int):
          ^^^^^^
  
Mutable locals must not be globals even if constexpr
  $ schmu mutable_locals.smu
  $ ./mutable_locals
  false
  false
  false
