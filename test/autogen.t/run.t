Copy string literal
  $ schmu --dump-llvm string_lit.smu && valgrind -q --leak-check=yes --show-reachable=yes ./string_lit
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"test \00" }
  @1 = private unnamed_addr constant { i64, i64, [7 x i8] } { i64 6, i64 6, [7 x i8] c"%s%li\0A\00" }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    %0 = alloca ptr, align 8
    store ptr @0, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    %3 = getelementptr i8, ptr %2, i64 16
    call void (ptr, ...) @printf(ptr getelementptr (i8, ptr @1, i64 16), ptr %3, i64 1)
    call void @__free_ac_(ptr %1)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare void @printf(ptr %0, ...)
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "string_lit.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "string_lit.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  test 1

Copy array of strings
  $ schmu --dump-llvm arr_of_strings.smu && valgrind -q --leak-check=yes --show-reachable=yes ./arr_of_strings
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @schmu_a = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"test\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"toast\00" }
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    %0 = tail call ptr @malloc(i64 32)
    store ptr %0, ptr @schmu_a, align 8
    store i64 2, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 2, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = alloca ptr, align 8
    store ptr @0, ptr %2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 8 %2, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %1)
    %"1" = getelementptr ptr, ptr %1, i64 1
    %3 = alloca ptr, align 8
    store ptr @1, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %"1", ptr align 8 %3, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %"1")
    %4 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 @schmu_a, i64 8, i1 false)
    call void @__copy_2ac2_(ptr %4)
    %5 = load ptr, ptr %4, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = getelementptr ptr, ptr %6, i64 1
    %8 = load ptr, ptr %7, align 8
    call void @string_println(ptr %8), !dbg !6
    call void @__free_2ac2_(ptr %4)
    call void @__free_2ac2_(ptr @schmu_a)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__copy_2ac2_(ptr %0) {
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
    call void @__copy_ac_(ptr %8)
    %9 = add i64 %5, 1
    store i64 %9, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_2ac2_(ptr %0) {
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
    call void @__free_ac_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "arr_of_strings.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "arr_of_strings.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 2, scope: !2)
  toast

Copy records
  $ schmu --dump-llvm records.smu && valgrind -q --leak-check=yes --show-reachable=yes ./records
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %contdac_lal2__ = type { %t_ }
  %t_ = type { double, ptr, i64, ptr }
  
  @schmu_a = global %contdac_lal2__ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"lul\00" }
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    store double 1.000000e+01, ptr @schmu_a, align 8
    %0 = alloca ptr, align 8
    store ptr @0, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    store ptr %2, ptr getelementptr inbounds (%t_, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 10, ptr getelementptr inbounds (%t_, ptr @schmu_a, i32 0, i32 2), align 8
    %3 = call ptr @malloc(i64 40)
    %arr = alloca ptr, align 8
    store ptr %3, ptr %arr, align 8
    store i64 3, ptr %3, align 8
    %cap = getelementptr i64, ptr %3, i64 1
    store i64 3, ptr %cap, align 8
    %4 = getelementptr i8, ptr %3, i64 16
    store i64 10, ptr %4, align 8
    %"1" = getelementptr i64, ptr %4, i64 1
    store i64 20, ptr %"1", align 8
    %"2" = getelementptr i64, ptr %4, i64 2
    store i64 30, ptr %"2", align 8
    store ptr %3, ptr getelementptr inbounds (%t_, ptr @schmu_a, i32 0, i32 3), align 8
    %5 = alloca %contdac_lal2__, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %5, ptr align 8 @schmu_a, i64 32, i1 false)
    call void @__copy_dac_lal3_(ptr %5)
    %6 = getelementptr inbounds %t_, ptr %5, i32 0, i32 1
    %7 = load ptr, ptr %6, align 8
    call void @string_println(ptr %7), !dbg !6
    call void @__free_dac_lal3_(ptr %5)
    call void @__free_dac_lal3_(ptr @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_dac_lal2_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %t_, ptr %0, i32 0, i32 1
    call void @__copy_ac_(ptr %1)
    %2 = getelementptr inbounds %t_, ptr %0, i32 0, i32 3
    call void @__copy_al_(ptr %2)
    ret void
  }
  
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
  
  define linkonce_odr void @__copy_dac_lal3_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__copy_dac_lal2_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_dac_lal2_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %t_, ptr %0, i32 0, i32 1
    call void @__free_ac_(ptr %1)
    %2 = getelementptr inbounds %t_, ptr %0, i32 0, i32 3
    call void @__free_al_(ptr %2)
    ret void
  }
  
  define linkonce_odr void @__free_al_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_dac_lal3_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_dac_lal2_(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "records.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "records.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 6, scope: !2)
  lul

Copy variants
  $ schmu variants.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./variants
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option.tac_l__ = type { i32, %ac_l_ }
  %ac_l_ = type { ptr, i64 }
  
  @schmu_a = global %option.tac_l__ zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"thing\00" }
  
  declare void @string_println(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    store i32 1, ptr @schmu_a, align 4
    %0 = alloca ptr, align 8
    store ptr @0, ptr %0, align 8
    %1 = alloca ptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %0, i64 8, i1 false)
    call void @__copy_ac_(ptr %1)
    %2 = load ptr, ptr %1, align 8
    store ptr %2, ptr getelementptr inbounds (%option.tac_l__, ptr @schmu_a, i32 0, i32 1), align 8
    store i64 0, ptr getelementptr inbounds (%option.tac_l__, ptr @schmu_a, i32 0, i32 1, i32 1), align 8
    %3 = alloca %option.tac_l__, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 @schmu_a, i64 24, i1 false)
    call void @__copy_vac_l2_(ptr %3)
    %index = load i32, ptr %3, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %ifcont, !dbg !6
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option.tac_l__, ptr %3, i32 0, i32 1
    %4 = getelementptr inbounds %ac_l_, ptr %data, i32 0, i32 1
    %5 = load ptr, ptr %data, align 8
    call void @string_println(ptr %5), !dbg !7
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    call void @__free_vac_l2_(ptr %3)
    call void @__free_vac_l2_(ptr @schmu_a)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__copy_ac_l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__copy_ac_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__copy_vac_l2_(ptr %0) {
  entry:
    %tag1 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag1, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.tac_l__, ptr %0, i32 0, i32 1
    call void @__copy_ac_l_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  define linkonce_odr void @__free_ac_l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_ac_(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_vac_l2_(ptr %0) {
  entry:
    %tag1 = bitcast ptr %0 to ptr
    %index = load i32, ptr %tag1, align 4
    %1 = icmp eq i32 %index, 1
    br i1 %1, label %match, label %cont
  
  match:                                            ; preds = %entry
    %data = getelementptr inbounds %option.tac_l__, ptr %0, i32 0, i32 1
    call void @__free_ac_l_(ptr %data)
    br label %cont
  
  cont:                                             ; preds = %match, %entry
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "variants.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "variants.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 4, column: 2, scope: !2)
  !7 = !DILocation(line: 4, column: 16, scope: !2)
  thing

Copy closures
  $ schmu --dump-llvm closure.smu && valgrind -q --leak-check=yes --show-reachable=yes ./closure
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  %"2l_" = type { i64, i64 }
  %"2rl2_l_" = type { %closure, i64 }
  
  @schmu_c = global %closure zeroinitializer, align 8
  @0 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"hello\00" }
  
  declare void @string_println(ptr %0)
  
  define void @__fun_schmu0(ptr %0) !dbg !2 {
  entry:
    %a = getelementptr inbounds { ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    %a1 = load ptr, ptr %a, align 8
    %1 = getelementptr i8, ptr %a1, i64 16
    %2 = load ptr, ptr %1, align 8
    tail call void @string_println(ptr %2), !dbg !6
    ret void
  }
  
  define i64 @schmu_capture(ptr %0) !dbg !7 {
  entry:
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %a1 = load i64, ptr %a, align 8
    %add = add i64 %a1, 1
    ret i64 %add
  }
  
  define i64 @schmu_capture__2(ptr %0) !dbg !8 {
  entry:
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %a1 = load i64, ptr %a, align 8
    %add = add i64 %a1, 1
    ret i64 %add
  }
  
  define void @schmu_hmm(ptr noalias %0) !dbg !9 {
  entry:
    %1 = alloca %"2l_", align 8
    store i64 1, ptr %1, align 8
    %"1" = getelementptr inbounds %"2l_", ptr %1, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    store ptr @schmu_capture, ptr %0, align 8
    %2 = tail call ptr @malloc(i64 24)
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 2
    store i64 1, ptr %a, align 8
    store ptr @__ctor_l_, ptr %2, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %2, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_hmm_move(ptr noalias %0) !dbg !10 {
  entry:
    %1 = alloca %"2l_", align 8
    store i64 1, ptr %1, align 8
    %"1" = getelementptr inbounds %"2l_", ptr %1, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    store ptr @schmu_capture__2, ptr %0, align 8
    %2 = tail call ptr @malloc(i64 24)
    %a = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 2
    store i64 1, ptr %a, align 8
    store ptr @__ctor_l_, ptr %2, align 8
    %dtor = getelementptr inbounds { ptr, ptr, i64 }, ptr %2, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %2, ptr %envptr, align 8
    ret void
  }
  
  define void @schmu_test(ptr noalias %0) !dbg !11 {
  entry:
    %1 = tail call ptr @malloc(i64 24)
    %arr = alloca ptr, align 8
    store ptr %1, ptr %arr, align 8
    store i64 1, ptr %1, align 8
    %cap = getelementptr i64, ptr %1, i64 1
    store i64 1, ptr %cap, align 8
    %2 = getelementptr i8, ptr %1, i64 16
    %3 = alloca ptr, align 8
    store ptr @0, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %2, ptr align 8 %3, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %2)
    store ptr @__fun_schmu0, ptr %0, align 8
    %4 = tail call ptr @malloc(i64 24)
    %a = getelementptr inbounds { ptr, ptr, ptr }, ptr %4, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a, ptr align 8 %arr, i64 8, i1 false)
    tail call void @__copy_2ac2_(ptr %a)
    %5 = load ptr, ptr %a, align 8
    store ptr %5, ptr %a, align 8
    store ptr @__ctor_2ac3_, ptr %4, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr }, ptr %4, i32 0, i32 1
    store ptr @__dtor_2ac3_, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    store ptr %4, ptr %envptr, align 8
    call void @__free_2ac2_(ptr %arr)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr ptr @__ctor_l_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    ret ptr %1
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_2ac2_(ptr %0) {
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
    call void @__copy_ac_(ptr %8)
    %9 = add i64 %5, 1
    store i64 %9, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    ret void
  }
  
  define linkonce_odr ptr @__ctor_2ac3_(ptr %0) {
  entry:
    %1 = call ptr @malloc(i64 24)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 24, i1 false)
    %a = getelementptr inbounds { ptr, ptr, ptr }, ptr %1, i32 0, i32 2
    call void @__copy_2ac2_(ptr %a)
    ret ptr %1
  }
  
  define linkonce_odr void @__dtor_2ac3_(ptr %0) {
  entry:
    %a = getelementptr inbounds { ptr, ptr, ptr }, ptr %0, i32 0, i32 2
    call void @__free_2ac2_(ptr %a)
    call void @free(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_2ac2_(ptr %0) {
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
    call void @__free_ac_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !12 {
  entry:
    %0 = alloca %"2rl2_l_", align 8
    %clstmp = alloca %closure, align 8
    store ptr @schmu_hmm, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %clstmp, i64 16, i1 false)
    call void @__copy_2rl2_(ptr %0)
    %"1" = getelementptr inbounds %"2rl2_l_", ptr %0, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    %1 = alloca %"2rl2_l_", align 8
    %clstmp2 = alloca %closure, align 8
    store ptr @schmu_hmm_move, ptr %clstmp2, align 8
    %envptr4 = getelementptr inbounds %closure, ptr %clstmp2, i32 0, i32 1
    store ptr null, ptr %envptr4, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 8 %clstmp2, i64 16, i1 false)
    call void @__copy_2rl2_(ptr %1)
    %"15" = getelementptr inbounds %"2rl2_l_", ptr %1, i32 0, i32 1
    store i64 0, ptr %"15", align 8
    call void @schmu_test(ptr @schmu_c), !dbg !13
    %2 = alloca %closure, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 @schmu_c, i64 16, i1 false)
    call void @__copy_ru_(ptr %2)
    %loadtmp = load ptr, ptr %2, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %2, i32 0, i32 1
    %loadtmp7 = load ptr, ptr %envptr6, align 8
    call void %loadtmp(ptr %loadtmp7), !dbg !14
    call void @__free_ru_(ptr %2)
    call void @__free_ru_(ptr @schmu_c)
    call void @__free_2rl2_l_(ptr %1)
    call void @__free_2rl2_l_(ptr %0)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_2rl2_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor2 = bitcast ptr %2 to ptr
    %ctor1 = load ptr, ptr %ctor2, align 8
    %4 = call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__copy_ru_(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor2 = bitcast ptr %2 to ptr
    %ctor1 = load ptr, ptr %ctor2, align 8
    %4 = call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__free_ru_(ptr %0) {
  entry:
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %env = load ptr, ptr %envptr, align 8
    %1 = icmp eq ptr %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = getelementptr inbounds { ptr, ptr }, ptr %env, i32 0, i32 1
    %dtor1 = load ptr, ptr %2, align 8
    %3 = icmp eq ptr %dtor1, null
    br i1 %3, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    call void %dtor1(ptr %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(ptr %env)
    br label %ret
  }
  
  define linkonce_odr void @__free_2rl2_(ptr %0) {
  entry:
    %envptr = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %env = load ptr, ptr %envptr, align 8
    %1 = icmp eq ptr %env, null
    br i1 %1, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %2 = getelementptr inbounds { ptr, ptr }, ptr %env, i32 0, i32 1
    %dtor1 = load ptr, ptr %2, align 8
    %3 = icmp eq ptr %dtor1, null
    br i1 %3, label %just_free, label %dtor
  
  ret:                                              ; preds = %just_free, %dtor, %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    call void %dtor1(ptr %env)
    br label %ret
  
  just_free:                                        ; preds = %notnull
    call void @free(ptr %env)
    br label %ret
  }
  
  define linkonce_odr void @__free_2rl2_l_(ptr %0) {
  entry:
    %1 = bitcast ptr %0 to ptr
    call void @__free_2rl2_(ptr %1)
    ret void
  }
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "closure.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !3, file: !3, line: 20, type: !4, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "closure.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = !DILocation(line: 20, column: 14, scope: !2)
  !7 = distinct !DISubprogram(name: "capture", linkageName: "schmu_capture", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !8 = distinct !DISubprogram(name: "capture", linkageName: "schmu_capture__2", scope: !3, file: !3, line: 12, type: !4, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !9 = distinct !DISubprogram(name: "hmm", linkageName: "schmu_hmm", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !10 = distinct !DISubprogram(name: "hmm_move", linkageName: "schmu_hmm_move", scope: !3, file: !3, line: 9, type: !4, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !11 = distinct !DISubprogram(name: "test", linkageName: "schmu_test", scope: !3, file: !3, line: 18, type: !4, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !12 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !13 = !DILocation(line: 23, column: 8, scope: !12)
  !14 = !DILocation(line: 24, scope: !12)
  hello

Copy string literal on move
  $ schmu copy_string_lit.smu --dump-llvm && valgrind -q --leak-check=yes --show-reachable=yes ./copy_string_lit
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { ptr, ptr }
  
  @schmu_a = global ptr null, align 8
  @schmu_b = global ptr null, align 8
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"aoeu\00" }
  
  declare void @string_modify_buf(ptr noalias %0, ptr %1)
  
  declare void @string_println(ptr %0)
  
  define void @__fun_schmu0(ptr noalias %arr) !dbg !2 {
  entry:
    %0 = load ptr, ptr %arr, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = getelementptr inbounds i8, ptr %1, i64 1
    store i8 105, ptr %2, align 1
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    %0 = tail call ptr @malloc(i64 24)
    store ptr %0, ptr @schmu_a, align 8
    store i64 1, ptr %0, align 8
    %cap = getelementptr i64, ptr %0, i64 1
    store i64 1, ptr %cap, align 8
    %1 = getelementptr i8, ptr %0, i64 16
    %2 = alloca ptr, align 8
    store ptr @0, ptr %2, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 8 %2, i64 8, i1 false)
    tail call void @__copy_ac_(ptr %1)
    %3 = alloca ptr, align 8
    store ptr @0, ptr %3, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 @schmu_b, ptr align 8 %3, i64 8, i1 false)
    tail call void @__copy_ac_(ptr @schmu_b)
    %clstmp = alloca %closure, align 8
    store ptr @__fun_schmu0, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @string_modify_buf(ptr @schmu_b, ptr %clstmp), !dbg !7
    %4 = load ptr, ptr @schmu_b, align 8
    call void @string_println(ptr %4), !dbg !8
    call void @string_println(ptr @0), !dbg !9
    %5 = load ptr, ptr @schmu_a, align 8
    %6 = getelementptr i8, ptr %5, i64 16
    %7 = load ptr, ptr %6, align 8
    call void @string_println(ptr %7), !dbg !10
    call void @__free_ac_(ptr @schmu_b)
    call void @__free_2ac2_(ptr @schmu_a)
    ret i64 0
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    %sz1 = bitcast ptr %1 to ptr
    %size = load i64, ptr %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call ptr @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %1, i64 %4, i1 false)
    %newcap = getelementptr i64, ptr %3, i64 1
    store i64 %size, ptr %newcap, align 8
    %5 = getelementptr i8, ptr %3, i64 %4
    store i8 0, ptr %5, align 1
    store ptr %3, ptr %0, align 8
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_ac_(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_2ac2_(ptr %0) {
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
    call void @__free_ac_(ptr %5)
    %6 = add i64 %2, 1
    store i64 %6, ptr %cnt, align 8
    br label %rec
  
  cont:                                             ; preds = %rec
    call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
  !1 = !DIFile(filename: "copy_string_lit.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "__fun_schmu0", linkageName: "__fun_schmu0", scope: !3, file: !3, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !3 = !DIFile(filename: "copy_string_lit.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !5)
  !7 = !DILocation(line: 3, scope: !6)
  !8 = !DILocation(line: 6, scope: !6)
  !9 = !DILocation(line: 7, scope: !6)
  !10 = !DILocation(line: 8, scope: !6)
  aieu
  aoeu
  aoeu

Correctly copy array
  $ schmu copy_array.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./copy_array

Correctly copy rc
  $ schmu rc.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./rc
