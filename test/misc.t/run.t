Compile stubs
  $ cc -c stub.c
  $ ar rs libstub.a stub.o > /dev/null 2>&1

Test elif
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu stub.o elseif.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  declare void @assert(i1 %0)
  
  define i64 @schmu_test(i64 %n) !dbg !2 {
  entry:
    %eq = icmp eq i64 %n, 10
    br i1 %eq, label %ifcont8, label %else, !dbg !6
  
  else:                                             ; preds = %entry
    %lt = icmp slt i64 %n, 1
    br i1 %lt, label %ifcont8, label %else2, !dbg !7
  
  else2:                                            ; preds = %else
    %lt3 = icmp slt i64 %n, 10
    br i1 %lt3, label %ifcont8, label %else5, !dbg !8
  
  else5:                                            ; preds = %else2
    br label %ifcont8
  
  ifcont8:                                          ; preds = %else, %else2, %else5, %entry
    %iftmp9 = phi i64 [ 1, %entry ], [ 2, %else ], [ 4, %else5 ], [ 3, %else2 ]
    ret i64 %iftmp9
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %0 = tail call i64 @schmu_test(i64 10), !dbg !10
    %eq = icmp eq i64 %0, 1
    tail call void @assert(i1 %eq), !dbg !11
    %1 = tail call i64 @schmu_test(i64 0), !dbg !12
    %eq1 = icmp eq i64 %1, 2
    tail call void @assert(i1 %eq1), !dbg !13
    %2 = tail call i64 @schmu_test(i64 1), !dbg !14
    %eq2 = icmp eq i64 %2, 3
    tail call void @assert(i1 %eq2), !dbg !15
    %3 = tail call i64 @schmu_test(i64 11), !dbg !16
    %eq3 = icmp eq i64 %3, 4
    tail call void @assert(i1 %eq3), !dbg !17
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu stub.o elseif.smu
  $ ./elseif

Test simple typedef
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu stub.o simple_typealias.smu 2>&1 | grep -v !DI
  simple_typealias.smu:2.10-14: warning: Unused binding puts
  
  2 | external puts : fun (foo) -> unit
               ^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu stub.o simple_typealias.smu > /dev/null 2>&1
  $ ./simple_typealias

Test x86_64-linux-gnu ABI (parts of it, anyway)
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu -c abi.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %v3 = type { double, double, double }
  %i3 = type { i64, i64, i64 }
  %v4 = type { double, double, double, double }
  %mixed4 = type { double, double, double, i64 }
  %trailv2 = type { i64, i64, double, double }
  %v2 = type { double, double }
  %i2 = type { i64, i64 }
  %v1 = type { double }
  %i1 = type { i64 }
  %f2s = type { float, float }
  %f3s = type { float, float, float }
  %shader = type { i32, ptr }
  
  @0 = private unnamed_addr constant [2 x i8] c"a\00"
  @1 = private unnamed_addr constant [2 x i8] c"b\00"
  
  declare ptr @string_data(ptr %0)
  
  declare { double, double } @subv2(double %0, double %1)
  
  declare { i64, i64 } @subi2(i64 %0, i64 %1)
  
  declare double @subv1(double %0)
  
  declare i64 @subi1(i64 %0)
  
  declare void @subv3(ptr noalias %0, ptr byval(%v3) %1)
  
  declare void @subi3(ptr noalias %0, ptr byval(%i3) %1)
  
  declare void @subv4(ptr noalias %0, ptr byval(%v4) %1)
  
  declare void @submixed4(ptr noalias %0, ptr byval(%mixed4) %1)
  
  declare void @subtrailv2(ptr noalias %0, ptr byval(%trailv2) %1)
  
  declare <2 x float> @subf2s(<2 x float> %0)
  
  declare { <2 x float>, float } @subf3s(<2 x float> %0, float %1)
  
  declare { i32, i64 } @load_shader(ptr %0, ptr %1)
  
  declare void @set_shader_value(i32 %0, i64 %1, i32 %2, ptr byval(%v4) %3)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    %boxconst = alloca %v2, align 8
    store %v2 { double 1.000000e+00, double 1.000000e+01 }, ptr %boxconst, align 8
    %fst1 = load double, ptr %boxconst, align 8
    %snd = getelementptr inbounds { double, double }, ptr %boxconst, i32 0, i32 1
    %snd2 = load double, ptr %snd, align 8
    %ret = alloca %v2, align 8
    %0 = tail call { double, double } @subv2(double %fst1, double %snd2), !dbg !6
    store { double, double } %0, ptr %ret, align 8
    %boxconst3 = alloca %i2, align 8
    store %i2 { i64 1, i64 10 }, ptr %boxconst3, align 8
    %fst5 = load i64, ptr %boxconst3, align 8
    %snd6 = getelementptr inbounds { i64, i64 }, ptr %boxconst3, i32 0, i32 1
    %snd7 = load i64, ptr %snd6, align 8
    %ret8 = alloca %i2, align 8
    %1 = tail call { i64, i64 } @subi2(i64 %fst5, i64 %snd7), !dbg !7
    store { i64, i64 } %1, ptr %ret8, align 8
    %ret9 = alloca %v1, align 8
    %2 = tail call double @subv1(double 1.000000e+00), !dbg !8
    store double %2, ptr %ret9, align 8
    %ret10 = alloca %i1, align 8
    %3 = tail call i64 @subi1(i64 1), !dbg !9
    store i64 %3, ptr %ret10, align 8
    %boxconst11 = alloca %v3, align 8
    store %v3 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02 }, ptr %boxconst11, align 8
    %ret12 = alloca %v3, align 8
    call void @subv3(ptr %ret12, ptr %boxconst11), !dbg !10
    %boxconst13 = alloca %i3, align 8
    store %i3 { i64 1, i64 10, i64 100 }, ptr %boxconst13, align 8
    %ret14 = alloca %i3, align 8
    call void @subi3(ptr %ret14, ptr %boxconst13), !dbg !11
    %boxconst15 = alloca %v4, align 8
    store %v4 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, ptr %boxconst15, align 8
    %ret16 = alloca %v4, align 8
    call void @subv4(ptr %ret16, ptr %boxconst15), !dbg !12
    %boxconst17 = alloca %mixed4, align 8
    store %mixed4 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, i64 1 }, ptr %boxconst17, align 8
    %ret18 = alloca %mixed4, align 8
    call void @submixed4(ptr %ret18, ptr %boxconst17), !dbg !13
    %boxconst19 = alloca %trailv2, align 8
    store %trailv2 { i64 1, i64 2, double 1.000000e+00, double 2.000000e+00 }, ptr %boxconst19, align 8
    %ret20 = alloca %trailv2, align 8
    call void @subtrailv2(ptr %ret20, ptr %boxconst19), !dbg !14
    %ret21 = alloca %f2s, align 8
    %4 = call <2 x float> @subf2s(<2 x float> <float 2.000000e+00, float 3.000000e+00>), !dbg !15
    store <2 x float> %4, ptr %ret21, align 8
    %boxconst22 = alloca %f3s, align 8
    store %f3s { float 2.000000e+00, float 3.000000e+00, float 5.000000e+00 }, ptr %boxconst22, align 4
    %fst24 = load <2 x float>, ptr %boxconst22, align 8
    %snd25 = getelementptr inbounds { <2 x float>, float }, ptr %boxconst22, i32 0, i32 1
    %snd26 = load float, ptr %snd25, align 4
    %ret27 = alloca %f3s, align 8
    %5 = call { <2 x float>, float } @subf3s(<2 x float> %fst24, float %snd26), !dbg !16
    store { <2 x float>, float } %5, ptr %ret27, align 8
    %boxconst28 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 1, i64 -1 }, ptr %boxconst28, align 8
    %6 = call ptr @string_data(ptr %boxconst28), !dbg !17
    %boxconst29 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @1, i64 1, i64 -1 }, ptr %boxconst29, align 8
    %7 = call ptr @string_data(ptr %boxconst29), !dbg !18
    %ret30 = alloca %shader, align 8
    %8 = call { i32, i64 } @load_shader(ptr %6, ptr %7), !dbg !19
    store { i32, i64 } %8, ptr %ret30, align 8
    %9 = alloca %shader, align 8
    store i32 0, ptr %9, align 4
    %locs = getelementptr inbounds %shader, ptr %9, i32 0, i32 1
    store ptr null, ptr %locs, align 8
    %boxconst35 = alloca %v4, align 8
    store %v4 { double 1.000000e+00, double 1.000000e+01, double 1.000000e+02, double 1.000000e+03 }, ptr %boxconst35, align 8
    call void @set_shader_value(i32 0, i64 0, i32 0, ptr %boxconst35), !dbg !20
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}

Test 'and', 'or' and 'not'
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu stub.o boolean_logic.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant [6 x i8] c"false\00"
  @1 = private unnamed_addr constant [5 x i8] c"true\00"
  @2 = private unnamed_addr constant [12 x i8] c"test 'and':\00"
  @3 = private unnamed_addr constant [4 x i8] c"yes\00"
  @4 = private unnamed_addr constant [3 x i8] c"no\00"
  @5 = private unnamed_addr constant [11 x i8] c"test 'or':\00"
  @6 = private unnamed_addr constant [12 x i8] c"test 'not':\00"
  
  declare void @string_println(ptr %0)
  
  define i1 @schmu_false_() !dbg !2 {
  entry:
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 5, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !6
    ret i1 false
  }
  
  define i1 @schmu_true_() !dbg !7 {
  entry:
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @1, i64 4, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !8
    ret i1 true
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !9 {
  entry:
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @2, i64 11, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !10
    %0 = call i1 @schmu_true_(), !dbg !11
    br i1 %0, label %true1, label %cont
  
  true1:                                            ; preds = %entry
    %1 = call i1 @schmu_true_(), !dbg !12
    br i1 %1, label %true2, label %cont
  
  true2:                                            ; preds = %true1
    br label %cont
  
  cont:                                             ; preds = %true2, %true1, %entry
    %andtmp = phi i1 [ false, %entry ], [ false, %true1 ], [ true, %true2 ]
    br i1 %andtmp, label %then, label %else, !dbg !11
  
  then:                                             ; preds = %cont
    %boxconst1 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst1, align 8
    call void @string_println(ptr %boxconst1), !dbg !13
    br label %ifcont
  
  else:                                             ; preds = %cont
    %boxconst2 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst2, align 8
    call void @string_println(ptr %boxconst2), !dbg !14
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    %2 = call i1 @schmu_true_(), !dbg !15
    br i1 %2, label %true13, label %cont5
  
  true13:                                           ; preds = %ifcont
    %3 = call i1 @schmu_false_(), !dbg !16
    br i1 %3, label %true24, label %cont5
  
  true24:                                           ; preds = %true13
    br label %cont5
  
  cont5:                                            ; preds = %true24, %true13, %ifcont
    %andtmp6 = phi i1 [ false, %ifcont ], [ false, %true13 ], [ true, %true24 ]
    br i1 %andtmp6, label %then7, label %else9, !dbg !15
  
  then7:                                            ; preds = %cont5
    %boxconst8 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst8, align 8
    call void @string_println(ptr %boxconst8), !dbg !17
    br label %ifcont11
  
  else9:                                            ; preds = %cont5
    %boxconst10 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst10, align 8
    call void @string_println(ptr %boxconst10), !dbg !18
    br label %ifcont11
  
  ifcont11:                                         ; preds = %else9, %then7
    %4 = call i1 @schmu_false_(), !dbg !19
    br i1 %4, label %true112, label %cont14
  
  true112:                                          ; preds = %ifcont11
    %5 = call i1 @schmu_true_(), !dbg !20
    br i1 %5, label %true213, label %cont14
  
  true213:                                          ; preds = %true112
    br label %cont14
  
  cont14:                                           ; preds = %true213, %true112, %ifcont11
    %andtmp15 = phi i1 [ false, %ifcont11 ], [ false, %true112 ], [ true, %true213 ]
    br i1 %andtmp15, label %then16, label %else18, !dbg !19
  
  then16:                                           ; preds = %cont14
    %boxconst17 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst17, align 8
    call void @string_println(ptr %boxconst17), !dbg !21
    br label %ifcont20
  
  else18:                                           ; preds = %cont14
    %boxconst19 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst19, align 8
    call void @string_println(ptr %boxconst19), !dbg !22
    br label %ifcont20
  
  ifcont20:                                         ; preds = %else18, %then16
    %6 = call i1 @schmu_false_(), !dbg !23
    br i1 %6, label %true121, label %cont23
  
  true121:                                          ; preds = %ifcont20
    %7 = call i1 @schmu_false_(), !dbg !24
    br i1 %7, label %true222, label %cont23
  
  true222:                                          ; preds = %true121
    br label %cont23
  
  cont23:                                           ; preds = %true222, %true121, %ifcont20
    %andtmp24 = phi i1 [ false, %ifcont20 ], [ false, %true121 ], [ true, %true222 ]
    br i1 %andtmp24, label %then25, label %else27, !dbg !23
  
  then25:                                           ; preds = %cont23
    %boxconst26 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst26, align 8
    call void @string_println(ptr %boxconst26), !dbg !25
    br label %ifcont29
  
  else27:                                           ; preds = %cont23
    %boxconst28 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst28, align 8
    call void @string_println(ptr %boxconst28), !dbg !26
    br label %ifcont29
  
  ifcont29:                                         ; preds = %else27, %then25
    %boxconst30 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @5, i64 10, i64 -1 }, ptr %boxconst30, align 8
    call void @string_println(ptr %boxconst30), !dbg !27
    %8 = call i1 @schmu_true_(), !dbg !28
    br i1 %8, label %cont31, label %false1
  
  false1:                                           ; preds = %ifcont29
    %9 = call i1 @schmu_true_(), !dbg !29
    br i1 %9, label %cont31, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont31
  
  cont31:                                           ; preds = %false2, %false1, %ifcont29
    %andtmp32 = phi i1 [ true, %ifcont29 ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp32, label %then33, label %else35, !dbg !28
  
  then33:                                           ; preds = %cont31
    %boxconst34 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst34, align 8
    call void @string_println(ptr %boxconst34), !dbg !30
    br label %ifcont37
  
  else35:                                           ; preds = %cont31
    %boxconst36 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst36, align 8
    call void @string_println(ptr %boxconst36), !dbg !31
    br label %ifcont37
  
  ifcont37:                                         ; preds = %else35, %then33
    %10 = call i1 @schmu_true_(), !dbg !32
    br i1 %10, label %cont40, label %false138
  
  false138:                                         ; preds = %ifcont37
    %11 = call i1 @schmu_false_(), !dbg !33
    br i1 %11, label %cont40, label %false239
  
  false239:                                         ; preds = %false138
    br label %cont40
  
  cont40:                                           ; preds = %false239, %false138, %ifcont37
    %andtmp41 = phi i1 [ true, %ifcont37 ], [ true, %false138 ], [ false, %false239 ]
    br i1 %andtmp41, label %then42, label %else44, !dbg !32
  
  then42:                                           ; preds = %cont40
    %boxconst43 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst43, align 8
    call void @string_println(ptr %boxconst43), !dbg !34
    br label %ifcont46
  
  else44:                                           ; preds = %cont40
    %boxconst45 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst45, align 8
    call void @string_println(ptr %boxconst45), !dbg !35
    br label %ifcont46
  
  ifcont46:                                         ; preds = %else44, %then42
    %12 = call i1 @schmu_false_(), !dbg !36
    br i1 %12, label %cont49, label %false147
  
  false147:                                         ; preds = %ifcont46
    %13 = call i1 @schmu_true_(), !dbg !37
    br i1 %13, label %cont49, label %false248
  
  false248:                                         ; preds = %false147
    br label %cont49
  
  cont49:                                           ; preds = %false248, %false147, %ifcont46
    %andtmp50 = phi i1 [ true, %ifcont46 ], [ true, %false147 ], [ false, %false248 ]
    br i1 %andtmp50, label %then51, label %else53, !dbg !36
  
  then51:                                           ; preds = %cont49
    %boxconst52 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst52, align 8
    call void @string_println(ptr %boxconst52), !dbg !38
    br label %ifcont55
  
  else53:                                           ; preds = %cont49
    %boxconst54 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst54, align 8
    call void @string_println(ptr %boxconst54), !dbg !39
    br label %ifcont55
  
  ifcont55:                                         ; preds = %else53, %then51
    %14 = call i1 @schmu_false_(), !dbg !40
    br i1 %14, label %cont58, label %false156
  
  false156:                                         ; preds = %ifcont55
    %15 = call i1 @schmu_false_(), !dbg !41
    br i1 %15, label %cont58, label %false257
  
  false257:                                         ; preds = %false156
    br label %cont58
  
  cont58:                                           ; preds = %false257, %false156, %ifcont55
    %andtmp59 = phi i1 [ true, %ifcont55 ], [ true, %false156 ], [ false, %false257 ]
    br i1 %andtmp59, label %then60, label %else62, !dbg !40
  
  then60:                                           ; preds = %cont58
    %boxconst61 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst61, align 8
    call void @string_println(ptr %boxconst61), !dbg !42
    br label %ifcont64
  
  else62:                                           ; preds = %cont58
    %boxconst63 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst63, align 8
    call void @string_println(ptr %boxconst63), !dbg !43
    br label %ifcont64
  
  ifcont64:                                         ; preds = %else62, %then60
    %boxconst65 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @6, i64 11, i64 -1 }, ptr %boxconst65, align 8
    call void @string_println(ptr %boxconst65), !dbg !44
    %16 = call i1 @schmu_true_(), !dbg !45
    %17 = xor i1 %16, true
    br i1 %17, label %then66, label %else68, !dbg !46
  
  then66:                                           ; preds = %ifcont64
    %boxconst67 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst67, align 8
    call void @string_println(ptr %boxconst67), !dbg !47
    br label %ifcont70
  
  else68:                                           ; preds = %ifcont64
    %boxconst69 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst69, align 8
    call void @string_println(ptr %boxconst69), !dbg !48
    br label %ifcont70
  
  ifcont70:                                         ; preds = %else68, %then66
    %18 = call i1 @schmu_false_(), !dbg !49
    %19 = xor i1 %18, true
    br i1 %19, label %then71, label %else73, !dbg !50
  
  then71:                                           ; preds = %ifcont70
    %boxconst72 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 3, i64 -1 }, ptr %boxconst72, align 8
    call void @string_println(ptr %boxconst72), !dbg !51
    br label %ifcont75
  
  else73:                                           ; preds = %ifcont70
    %boxconst74 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 2, i64 -1 }, ptr %boxconst74, align 8
    call void @string_println(ptr %boxconst74), !dbg !52
    br label %ifcont75
  
  ifcont75:                                         ; preds = %else73, %then71
    ret i64 0
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu stub.o boolean_logic.smu
  $ ./boolean_logic
  test 'and':
  true
  true
  yes
  true
  false
  no
  false
  no
  false
  no
  test 'or':
  true
  yes
  true
  yes
  false
  true
  yes
  false
  false
  no
  test 'not':
  true
  no
  false
  yes


  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu stub.o unary_minus.smu 2>&1 | grep -v !DI
  unary_minus.smu:1.5-6: warning: Unused binding a
  
  1 | let a = -1.0
          ^
  
  unary_minus.smu:2.5-6: warning: Unused binding a
  
  2 | let a = -.1.0
          ^
  
  unary_minus.smu:3.5-6: warning: Unused binding a
  
  3 | let a = - 1.0
          ^
  
  unary_minus.smu:4.5-6: warning: Unused binding a
  
  4 | let a = -. 1.0
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @schmu_a = constant double -1.000000e+00
  @schmu_a__2 = constant double -1.000000e+00
  @schmu_a__3 = constant double -1.000000e+00
  @schmu_a__4 = constant double -1.000000e+00
  @schmu_a__5 = constant i64 -1
  @schmu_b = constant i64 -1
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !2 {
  entry:
    ret i64 -2
  }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu stub.o unary_minus.smu > /dev/null 2>&1
  $ ./unary_minus
  [254]

Test unused binding warning
  $ schmu unused.smu stub.o
  unused.smu:2.5-12: warning: Unused binding unused1
  
  2 | let unused1 = 0
          ^^^^^^^
  
  unused.smu:5.5-12: warning: Unused binding unused2
  
  5 | let unused2 = 0
          ^^^^^^^
  
  unused.smu:12.5-16: warning: Unused binding use_unused3
  
  12 | fun use_unused3() {
           ^^^^^^^^^^^
  
  unused.smu:17.9-16: warning: Unused binding unused4
  
  17 |     let unused4 = 0
               ^^^^^^^
  
  unused.smu:20.9-16: warning: Unused binding unused5
  
  20 |     let unused5 = 0
               ^^^^^^^
  
  unused.smu:33.9-18: warning: Unused binding usedlater
  
  33 |     let usedlater = 0
               ^^^^^^^^^
  
  unused.smu:46.9-18: warning: Unused binding usedlater
  
  46 |     let usedlater = 0
               ^^^^^^^^^
  
Allow declaring a c function with a different name
  $ schmu stub.o cname_decl.smu && ./cname_decl
  
  42

We can have if without else
  $ schmu if_no_else.smu
  if_no_else.smu:2.1-11: error: A conditional without else branch should evaluato to type unit.
  expecting unit
  but found int
  
  2 | if true{2}
      ^^^^^^^^^^
  
  [1]

Piping for ctors and field accessors
  $ schmu stub.o --dump-llvm -c --target x86_64-unknown-linux-gnu piping.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %option.t.l = type { i32, i64 }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @0 = private unnamed_addr constant [3 x i8] c"u8\00"
  @1 = private unnamed_addr constant [1 x i8] zeroinitializer
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_of_array(ptr noalias %0, ptr %1)
  
  declare void @string_println(ptr %0)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  declare void @Printi(i64 %0)
  
  define linkonce_odr void @__array_fixed_swap_items_cA64.u(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
  entry:
    %eq = icmp eq i64 %i, %j
    %0 = xor i1 %eq, true
    br i1 %0, label %then, label %ifcont, !dbg !6
  
  then:                                             ; preds = %entry
    %1 = alloca i8, align 1
    %2 = getelementptr i8, ptr %arr, i64 %i
    %3 = load i8, ptr %2, align 1
    store i8 %3, ptr %1, align 1
    %4 = getelementptr i8, ptr %arr, i64 %j
    %5 = load i8, ptr %4, align 1
    store i8 %5, ptr %2, align 1
    store i8 %3, ptr %4, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_endl_u(ptr %p) !dbg !7 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !9
    call void @__fmt_formatter_extract_u(ptr %ret), !dbg !10
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_u(ptr %fm) !dbg !11 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !12 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !13
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !14 {
  entry:
    %1 = alloca [64 x i8], align 1
    store [64 x i8] zeroinitializer, ptr %1, align 1
    %lt = icmp slt i64 %base, 2
    br i1 %lt, label %cont, label %false1
  
  false1:                                           ; preds = %entry
    %gt = icmp sgt i64 %base, 36
    br i1 %gt, label %cont, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont
  
  cont:                                             ; preds = %false2, %false1, %entry
    %andtmp = phi i1 [ true, %entry ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp, label %then, label %else, !dbg !15
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !16
    br label %ifcont
  
  else:                                             ; preds = %cont
    %fmt_aux = alloca %closure, align 8
    store ptr @fmt_aux, ptr %fmt_aux, align 8
    %clsr_fmt_aux = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr, align 8
    %base1 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 3
    store i64 %base, ptr %base1, align 8
    store ptr @__ctor_tp.A64.cl, ptr %clsr_fmt_aux, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt_aux, i32 0, i32 1
    store ptr %clsr_fmt_aux, ptr %envptr, align 8
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !17
    %add = add i64 %2, 1
    %div = sdiv i64 %add, 2
    %__fun_fmt2 = alloca %closure, align 8
    store ptr @__fun_fmt2, ptr %__fun_fmt2, align 8
    %clsr___fun_fmt2 = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr5 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr5, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 3
    store i64 %add, ptr %_fmt_length, align 8
    store ptr @__ctor_tp.A64.cl, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !18
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !19
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_u(ptr noalias %0, ptr %p, i64 %i) !dbg !20 {
  entry:
    tail call void @__fmt_int_base_u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !21
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_c(ptr %fmt, i8 %value) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !23
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i8 %value, ptr %loadtmp1), !dbg !24
    call void @__fmt_endl_u(ptr %ret2), !dbg !25
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_l(ptr %fmt, i64 %value) !dbg !26 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !27
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !28
    call void @__fmt_endl_u(ptr %ret2), !dbg !29
    ret void
  }
  
  define linkonce_odr void @__fmt_str_u(ptr noalias %0, ptr %p, ptr %str) !dbg !30 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !31
    %2 = tail call i64 @string_len(ptr %str), !dbg !32
    tail call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !33
    ret void
  }
  
  define linkonce_odr void @__fmt_u8_u(ptr noalias %0, ptr %p, i8 %u) !dbg !34 {
  entry:
    %1 = zext i8 %u to i64
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_int_u(ptr %ret, ptr %p, i64 %1), !dbg !35
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 2, i64 -1 }, ptr %boxconst, align 8
    call void @__fmt_str_u(ptr %0, ptr %ret, ptr %boxconst), !dbg !36
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !37 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_cA64.u(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !38
    ret void
  }
  
  define i64 @__fun_schmu0(i64 %x) !dbg !39 {
  entry:
    %add = add i64 %x, 1
    ret i64 %add
  }
  
  define i64 @__fun_schmu1(i32 %0, i64 %1) !dbg !41 {
  entry:
    %x = alloca { i32, i64 }, align 8
    store i32 %0, ptr %x, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %x, i32 0, i32 1
    store i64 %1, ptr %snd, align 8
    %eq = icmp eq i32 %0, 1
    br i1 %eq, label %ifcont, label %else, !dbg !42
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 0, %else ], [ %1, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !43 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %base = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %base2 = load i64, ptr %base, align 8
    %1 = alloca i64, align 8
    store i64 %value, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 %index, ptr %2, align 8
    %3 = add i64 %index, 1
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %then ], [ %3, %entry ]
    %4 = phi i64 [ %div, %then ], [ %value, %entry ]
    %div = sdiv i64 %4, %base2
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !44
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !45
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !46
    br i1 %lt, label %then4, label %ifcont, !dbg !46
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  define linkonce_odr void @__free_up.clru(ptr %0) {
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
  
  ret:                                              ; preds = %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    tail call void %dtor1(ptr %env)
    ret void
  
  just_free:                                        ; preds = %notnull
    tail call void @free(ptr %env)
    ret void
  }
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free_up.clru(ptr %0)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !47 {
  entry:
    %0 = tail call i64 @__fun_schmu0(i64 1), !dbg !48
    tail call void @Printi(i64 %0), !dbg !49
    %boxconst = alloca %option.t.l, align 8
    store %option.t.l { i32 1, i64 1 }, ptr %boxconst, align 8
    %fst1 = load i32, ptr %boxconst, align 4
    %snd = getelementptr inbounds { i32, i64 }, ptr %boxconst, i32 0, i32 1
    %snd2 = load i64, ptr %snd, align 8
    %1 = tail call i64 @__fun_schmu1(i32 %fst1, i64 %snd2), !dbg !50
    tail call void @Printi(i64 %1), !dbg !51
    tail call void @Printi(i64 1), !dbg !52
    %boxconst3 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @1, i64 0, i64 -1 }, ptr %boxconst3, align 8
    call void @string_println(ptr %boxconst3), !dbg !53
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @__fmt_stdout_println_l(ptr %clstmp, i64 10), !dbg !54
    %clstmp4 = alloca %closure, align 8
    store ptr @__fmt_u8_u, ptr %clstmp4, align 8
    %envptr6 = getelementptr inbounds %closure, ptr %clstmp4, i32 0, i32 1
    store ptr null, ptr %envptr6, align 8
    %arr = alloca { ptr, i64, i64 }, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 3, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 3, ptr %cap, align 8
    %2 = call ptr @malloc(i64 3)
    store ptr %2, ptr %arr, align 8
    store i8 97, ptr %2, align 1
    %"1" = getelementptr i8, ptr %2, i64 1
    store i8 98, ptr %"1", align 1
    %"2" = getelementptr i8, ptr %2, i64 2
    store i8 99, ptr %"2", align 1
    %ret = alloca { ptr, i64, i64 }, align 8
    call void @string_of_array(ptr %ret, ptr %arr), !dbg !55
    %3 = call i8 @string_get(ptr %ret, i64 1), !dbg !56
    call void @__fmt_stdout_println_c(ptr %clstmp4, i8 %3), !dbg !57
    call void @__free_a.c(ptr %ret)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu stub.o piping.smu
  $ ./piping
  
  2
  1
  1
  10
  98u8

Function calls for known functions act as annotations to decide which ctor or record to use.
Prints nothing, just works
  $ schmu function_call_annot.smu

Mutual recursive function
  $ schmu mutual_rec.smu && ./mutual_rec
  true
  false
  true

Polymorphic mutual recursive function
  $ schmu -m m2.smu
  $ schmu polymorphic_mutual_rec.smu && ./polymorphic_mutual_rec
  true
  false
  true
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  0
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  pop
  0
  right

Increase refcount for returned params in ifs
  $ schmu --dump-llvm -c --target x86_64-unknown-linux-gnu if_ret_param.smu 2>&1 | grep -v !DI
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  %fmt.formatter.t.a.c = type { %closure, { ptr, i64, i64 } }
  %tp.lfmt.formatter.t.a.c = type { i64, %fmt.formatter.t.a.c }
  
  @fmt_str_missing_arg_msg = external global { ptr, i64, i64 }
  @fmt_str_too_many_arg_msg = external global { ptr, i64, i64 }
  @0 = private unnamed_addr constant [2 x i8] c"/\00"
  @schmu_s = constant { ptr, i64, i64 } { ptr @0, i64 1, i64 -1 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @1 = private unnamed_addr constant [4 x i8] c"/{}\00"
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare void @fmt_prerr(ptr noalias %0)
  
  declare void @fmt_str_helper_printn(ptr noalias %0, ptr %1, ptr %2)
  
  define linkonce_odr void @__fmt_endl_u(ptr %p) !dbg !2 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !6
    call void @__fmt_formatter_extract_u(ptr %ret), !dbg !7
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_a.c(ptr noalias %0, ptr %fm) !dbg !8 {
  entry:
    %1 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %fm, i32 0, i32 1
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %1, i64 24, i1 false)
    tail call void @__free_except1_fmt.formatter.t.a.c(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_u(ptr %fm) !dbg !9 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_a.c(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !10 {
  entry:
    %1 = alloca %fmt.formatter.t.a.c, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 40, i1 false)
    %2 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %1, i32 0, i32 1
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    call void %loadtmp(ptr %2, ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !11
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 40, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !12 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !13
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_str_a.c(ptr noalias %0, ptr %p, ptr %str) !dbg !14 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !15
    %2 = tail call i64 @string_len(ptr %str), !dbg !16
    tail call void @__fmt_formatter_format_a.c(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !17
    ret void
  }
  
  define linkonce_odr void @__fmt_str_impl_fmt_fail_missing_fmt.formatter.t.a.c(ptr noalias %0) !dbg !18 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !19
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_u(ptr %ret1, ptr %ret, ptr @fmt_str_missing_arg_msg), !dbg !20
    call void @__fmt_endl_u(ptr %ret1), !dbg !21
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_str_impl_fmt_fail_too_many_a.c(ptr noalias %0) !dbg !22 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_prerr(ptr %ret), !dbg !23
    %ret1 = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_str_u(ptr %ret1, ptr %ret, ptr @fmt_str_too_many_arg_msg), !dbg !24
    call void @__fmt_endl_u(ptr %ret1), !dbg !25
    call void @abort()
    %failwith = alloca ptr, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_str_print1_a.c(ptr noalias %0, ptr %fmtstr, ptr %f0, ptr %v0) !dbg !26 {
  entry:
    %__fun_fmt_str2_a.c = alloca %closure, align 8
    store ptr @__fun_fmt_str2_a.c, ptr %__fun_fmt_str2_a.c, align 8
    %clsr___fun_fmt_str2_a.c = alloca { ptr, ptr, %closure, { ptr, i64, i64 } }, align 8
    %f01 = getelementptr inbounds { ptr, ptr, %closure, { ptr, i64, i64 } }, ptr %clsr___fun_fmt_str2_a.c, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f01, ptr align 1 %f0, i64 16, i1 false)
    %v02 = getelementptr inbounds { ptr, ptr, %closure, { ptr, i64, i64 } }, ptr %clsr___fun_fmt_str2_a.c, i32 0, i32 3
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %v02, ptr align 1 %v0, i64 24, i1 false)
    store ptr @__ctor_tp.fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c, ptr %clsr___fun_fmt_str2_a.c, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, { ptr, i64, i64 } }, ptr %clsr___fun_fmt_str2_a.c, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %__fun_fmt_str2_a.c, i32 0, i32 1
    store ptr %clsr___fun_fmt_str2_a.c, ptr %envptr, align 8
    %ret = alloca %tp.lfmt.formatter.t.a.c, align 8
    call void @fmt_str_helper_printn(ptr %ret, ptr %fmtstr, ptr %__fun_fmt_str2_a.c), !dbg !27
    %1 = getelementptr inbounds %tp.lfmt.formatter.t.a.c, ptr %ret, i32 0, i32 1
    %2 = load i64, ptr %ret, align 8
    %ne = icmp ne i64 %2, 1
    br i1 %ne, label %then, label %else, !dbg !28
  
  then:                                             ; preds = %entry
    call void @__fmt_str_impl_fmt_fail_too_many_a.c(ptr %0), !dbg !29
    call void @__free_fmt.formatter.t.a.c(ptr %1)
    br label %ifcont
  
  else:                                             ; preds = %entry
    call void @__fmt_formatter_extract_a.c(ptr %0, ptr %1), !dbg !30
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_str_u(ptr noalias %0, ptr %p, ptr %str) !dbg !31 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !32
    %2 = tail call i64 @string_len(ptr %str), !dbg !33
    tail call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !34
    ret void
  }
  
  define linkonce_odr void @__fun_fmt_str2_a.c(ptr noalias %0, ptr %fmter, i64 %i, ptr %1) !dbg !35 {
  entry:
    %v0 = getelementptr inbounds { ptr, ptr, %closure, { ptr, i64, i64 } }, ptr %1, i32 0, i32 3
    %eq = icmp eq i64 %i, 0
    br i1 %eq, label %then, label %else, !dbg !36
  
  then:                                             ; preds = %entry
    %sunkaddr = getelementptr inbounds i8, ptr %1, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr2 = getelementptr inbounds i8, ptr %1, i64 24
    %loadtmp1 = load ptr, ptr %sunkaddr2, align 8
    tail call void %loadtmp(ptr %0, ptr %fmter, ptr %v0, ptr %loadtmp1), !dbg !37
    ret void
  
  else:                                             ; preds = %entry
    tail call void @__fmt_str_impl_fmt_fail_missing_fmt.formatter.t.a.c(ptr %0), !dbg !38
    tail call void @__free_fmt.formatter.t.a.c(ptr %fmter)
    ret void
  }
  
  define void @schmu_inner(i64 %i, ptr %0) !dbg !39 {
  entry:
    %limit = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %0, i32 0, i32 3
    %limit1 = load i64, ptr %limit, align 8
    %1 = alloca i64, align 8
    store i64 %i, ptr %1, align 8
    %2 = add i64 %i, 1
    %3 = sub i64 0, %limit1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %4 = add i64 %3, %lsr.iv
    %eq = icmp eq i64 %4, 1
    br i1 %eq, label %then, label %else, !dbg !41
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 16
    %loadtmp = load ptr, ptr %sunkaddr, align 8
    %sunkaddr3 = getelementptr inbounds i8, ptr %0, i64 24
    %loadtmp2 = load ptr, ptr %sunkaddr3, align 8
    tail call void %loadtmp(ptr @schmu_s, ptr %loadtmp2), !dbg !42
    store i64 %lsr.iv, ptr %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define void @schmu_test(ptr %value) !dbg !43 {
  entry:
    %0 = alloca { ptr, i64, i64 }, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 1 %value, i64 24, i1 false)
    call void @__copy_a.c(ptr %0)
    call void @__free_a.c(ptr %0)
    ret void
  }
  
  define void @schmu_times(i64 %limit, ptr %f) !dbg !44 {
  entry:
    %schmu_inner = alloca %closure, align 8
    store ptr @schmu_inner, ptr %schmu_inner, align 8
    %clsr_schmu_inner = alloca { ptr, ptr, %closure, i64 }, align 8
    %f1 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 2
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %f1, ptr align 1 %f, i64 16, i1 false)
    %limit2 = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 3
    store i64 %limit, ptr %limit2, align 8
    store ptr @__ctor_tp.a.crul, ptr %clsr_schmu_inner, align 8
    %dtor = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %clsr_schmu_inner, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %schmu_inner, i32 0, i32 1
    store ptr %clsr_schmu_inner, ptr %envptr, align 8
    call void @schmu_inner(i64 0, ptr %clsr_schmu_inner), !dbg !45
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_a.cp.clru(ptr %0) {
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
  
  ret:                                              ; preds = %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    tail call void %dtor1(ptr %env)
    ret void
  
  just_free:                                        ; preds = %notnull
    tail call void @free(ptr %env)
    ret void
  }
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.a.c(ptr %0) {
  entry:
    tail call void @__free_a.cp.clru(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_up.clru(ptr %0) {
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
  
  ret:                                              ; preds = %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    tail call void %dtor1(ptr %env)
    ret void
  
  just_free:                                        ; preds = %notnull
    tail call void @free(ptr %env)
    ret void
  }
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free_up.clru(ptr %0)
    ret void
  }
  
  declare void @abort()
  
  define linkonce_odr ptr @__ctor_tp.fmt.formatter.t.a.ca.crfmt.formatter.t.a.ca.c(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 56)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 56, i1 false)
    %f0 = getelementptr inbounds { ptr, ptr, %closure, { ptr, i64, i64 } }, ptr %1, i32 0, i32 2
    tail call void @__copy_fmt.formatter.t.a.ca.crfmt.formatter.t.a.c(ptr %f0)
    %v0 = getelementptr inbounds { ptr, ptr, %closure, { ptr, i64, i64 } }, ptr %1, i32 0, i32 3
    tail call void @__copy_a.c(ptr %v0)
    ret ptr %1
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__copy_fmt.formatter.t.a.ca.crfmt.formatter.t.a.c(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define linkonce_odr void @__copy_a.c(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %1 = icmp eq i64 %size, 0
    br i1 %1, label %zero, label %nonempty
  
  zero:                                             ; preds = %entry
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 0, ptr %cap, align 8
    store ptr null, ptr %0, align 8
    br label %cont
  
  cont:                                             ; preds = %nonempty, %zero
    ret void
  
  nonempty:                                         ; preds = %entry
    %2 = add i64 %size, 1
    %3 = tail call ptr @malloc(i64 %2)
    %4 = load ptr, ptr %0, align 8
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %4, i64 %2, i1 false)
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 %size, ptr %cap2, align 8
    store ptr %3, ptr %0, align 8
    br label %cont
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_fmt.formatter.t.a.c(ptr %0) {
  entry:
    tail call void @__free_a.cp.clru(ptr %0)
    %1 = getelementptr inbounds %fmt.formatter.t.a.c, ptr %0, i32 0, i32 1
    tail call void @__free_a.c(ptr %1)
    ret void
  }
  
  define linkonce_odr ptr @__ctor_tp.a.crul(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 40)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 40, i1 false)
    %f = getelementptr inbounds { ptr, ptr, %closure, i64 }, ptr %1, i32 0, i32 2
    tail call void @__copy_a.cru(ptr %f)
    ret ptr %1
  }
  
  define linkonce_odr void @__copy_a.cru(ptr %0) {
  entry:
    %1 = getelementptr inbounds %closure, ptr %0, i32 0, i32 1
    %2 = load ptr, ptr %1, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor1 = load ptr, ptr %2, align 8
    %4 = tail call ptr %ctor1(ptr %2)
    %sunkaddr = getelementptr inbounds i8, ptr %0, i64 8
    store ptr %4, ptr %sunkaddr, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !46 {
  entry:
    %clstmp = alloca %closure, align 8
    store ptr @schmu_test, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    call void @schmu_times(i64 2, ptr %clstmp), !dbg !47
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu if_ret_param.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./if_ret_param

Allow patterns in decls
  $ schmu pattern_decls.smu && ./pattern_decls
  hello
  20
  30
  lol

Assertions
  $ schmu assert.smu
  $ ret=$(./assert 2> err) 2> /dev/null
  [134]
  $ echo $ret
  hmm
  $ cat err | grep assert | grep 8 | grep false | grep -q failed

Find function by callname even when not calling
  $ schmu find_fn.smu

Handle partial allocations
  $ schmu partials.smu --dump-llvm -c --target x86_64-unknown-linux-gnu 2>&1 | grep -v !D
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %f.a.l = type { { ptr, i64, i64 }, { ptr, i64, i64 }, { ptr, i64, i64 } }
  %t.a.l = type { { ptr, i64, i64 }, { ptr, i64, i64 } }
  %tp.a.ll = type { { ptr, i64, i64 }, i64 }
  
  define void @schmu_inf(ptr noalias %0) !dbg !2 {
  entry:
    %1 = alloca %f.a.l, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %1, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %1, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %2 = tail call ptr @malloc(i64 8)
    store ptr %2, ptr %1, align 8
    store i64 10, ptr %2, align 8
    %b = getelementptr inbounds %f.a.l, ptr %1, i32 0, i32 1
    %len1 = getelementptr inbounds { ptr, i64, i64 }, ptr %b, i32 0, i32 1
    store i64 1, ptr %len1, align 8
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %b, i32 0, i32 2
    store i64 1, ptr %cap2, align 8
    %3 = tail call ptr @malloc(i64 8)
    store ptr %3, ptr %b, align 8
    store i64 10, ptr %3, align 8
    %c = getelementptr inbounds %f.a.l, ptr %1, i32 0, i32 2
    %len5 = getelementptr inbounds { ptr, i64, i64 }, ptr %c, i32 0, i32 1
    store i64 1, ptr %len5, align 8
    %cap6 = getelementptr inbounds { ptr, i64, i64 }, ptr %c, i32 0, i32 2
    store i64 1, ptr %cap6, align 8
    %4 = tail call ptr @malloc(i64 8)
    store ptr %4, ptr %c, align 8
    store i64 10, ptr %4, align 8
    %5 = alloca { ptr, i64, i64 }, align 8
    call void @__free_a.l(ptr %c)
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %5, ptr align 8 %1, i64 24, i1 false)
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %b, i64 24, i1 false)
    call void @__free_a.l(ptr %5)
    ret void
  }
  
  define void @schmu_set_moved() !dbg !6 {
  entry:
    %0 = alloca %t.a.l, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    store i64 1, ptr %len, align 8
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 2
    store i64 1, ptr %cap, align 8
    %1 = tail call ptr @malloc(i64 8)
    store ptr %1, ptr %0, align 8
    store i64 10, ptr %1, align 8
    %b = getelementptr inbounds %t.a.l, ptr %0, i32 0, i32 1
    %len1 = getelementptr inbounds { ptr, i64, i64 }, ptr %b, i32 0, i32 1
    store i64 1, ptr %len1, align 8
    %cap2 = getelementptr inbounds { ptr, i64, i64 }, ptr %b, i32 0, i32 2
    store i64 1, ptr %cap2, align 8
    %2 = tail call ptr @malloc(i64 8)
    store ptr %2, ptr %b, align 8
    store i64 20, ptr %2, align 8
    %3 = alloca %tp.a.ll, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %0, i64 24, i1 false)
    %"1" = getelementptr inbounds %tp.a.ll, ptr %3, i32 0, i32 1
    store i64 0, ptr %"1", align 8
    %arr = alloca { ptr, i64, i64 }, align 8
    %len6 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    store i64 1, ptr %len6, align 8
    %cap7 = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    store i64 1, ptr %cap7, align 8
    %4 = tail call ptr @malloc(i64 8)
    store ptr %4, ptr %arr, align 8
    store i64 20, ptr %4, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %arr, i64 24, i1 false)
    call void @__free_tp.a.ll(ptr %3)
    call void @__free_t.a.l(ptr %0)
    ret void
  }
  
  declare ptr @malloc(i64 %0)
  
  define linkonce_odr void @__free_a.l(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_tp.a.ll(ptr %0) {
  entry:
    tail call void @__free_a.l(ptr %0)
    ret void
  }
  
  define linkonce_odr void @__free_t.a.l(ptr %0) {
  entry:
    tail call void @__free_a.l(ptr %0)
    %1 = getelementptr inbounds %t.a.l, ptr %0, i32 0, i32 1
    tail call void @__free_a.l(ptr %1)
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !7 {
  entry:
    %ret = alloca { ptr, i64, i64 }, align 8
    call void @schmu_inf(ptr %ret), !dbg !8
    call void @schmu_set_moved(), !dbg !9
    call void @__free_a.l(ptr %ret)
    ret i64 0
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu partials.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./partials

Correct link order for cc flags
  $ schmu piping.smu --cc -L. --cc -lstub

Using unit values
  $ schmu unit_values.smu --dump-llvm -c --target x86_64-unknown-linux-gnu 2>&1 | grep -v !D
  unit_values.smu:3.5-6: warning: Unused binding b
  
  3 | let b = Some(a)
          ^
  
  unit_values.smu:8.8-9: warning: Unused binding a
  
  8 |   Some(a) -> println("some")
             ^
  
  unit_values.smu:14.5-6: warning: Unused binding u
  
  14 | let u = t.u
           ^
  
  unit_values.smu:18.5-7: warning: Unused binding u2
  
  18 | let u2 = t2.u
           ^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  %option.t.u = type { i32 }
  %thing = type {}
  %inrec = type { i64, double }
  %fmt.formatter.t.u = type { %closure }
  %closure = type { ptr, ptr }
  
  @fmt_int_digits = external global { ptr, i64, i64 }
  @schmu_a = constant i8 0
  @schmu_b = constant %option.t.u { i32 1 }
  @schmu_t = constant %thing zeroinitializer
  @schmu_u = constant i8 0
  @schmu_t__3 = constant %inrec { i64 10, double 9.990000e+01 }
  @fmt_newline = internal constant [1 x i8] c"\0A"
  @schmu_arr__2 = constant i8 0
  @schmu_b__2 = global %option.t.u zeroinitializer, align 4
  @schmu_t2 = global %thing zeroinitializer, align 1
  @schmu_u2 = global i8 0, align 1
  @schmu_arr = global { ptr, i64, i64 } zeroinitializer, align 8
  @schmu_u__2 = global i8 0, align 1
  @0 = private unnamed_addr constant [15 x i8] c"__array_push_u\00"
  @1 = private unnamed_addr constant [10 x i8] c"array.smu\00"
  @2 = private unnamed_addr constant [15 x i8] c"file not found\00"
  @3 = private unnamed_addr constant [5 x i8] c"some\00"
  @4 = private unnamed_addr constant [5 x i8] c"none\00"
  @5 = private unnamed_addr constant [5 x i8] c"99.9\00"
  
  declare void @prelude_iter_range(i64 %0, i64 %1, ptr %2)
  
  declare i64 @prelude_power_2_above_or_equal(i64 %0, i64 %1)
  
  declare i64 @string_len(ptr %0)
  
  declare ptr @string_data(ptr %0)
  
  declare i8 @string_get(ptr %0, i64 %1)
  
  declare void @string_println(ptr %0)
  
  declare void @fmt_fmt_stdout_create(ptr noalias %0)
  
  define linkonce_odr void @__array_fixed_swap_items_cA64.u(ptr noalias %arr, i64 %i, i64 %j) !dbg !2 {
  entry:
    %eq = icmp eq i64 %i, %j
    %0 = xor i1 %eq, true
    br i1 %0, label %then, label %ifcont, !dbg !6
  
  then:                                             ; preds = %entry
    %1 = alloca i8, align 1
    %2 = getelementptr i8, ptr %arr, i64 %i
    %3 = load i8, ptr %2, align 1
    store i8 %3, ptr %1, align 1
    %4 = getelementptr i8, ptr %arr, i64 %j
    %5 = load i8, ptr %4, align 1
    store i8 %5, ptr %2, align 1
    store i8 %3, ptr %4, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    ret void
  }
  
  define linkonce_odr void @__array_push_u(ptr noalias %arr) !dbg !7 {
  entry:
    %cap = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 2
    %0 = load i64, ptr %cap, align 8
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %arr, i32 0, i32 1
    %1 = load i64, ptr %len, align 8
    %eq = icmp eq i64 %0, %1
    br i1 %eq, label %then, label %ifcont12, !dbg !8
  
  then:                                             ; preds = %entry
    %eq1 = icmp eq i64 %0, 0
    br i1 %eq1, label %then2, label %else, !dbg !9
  
  then2:                                            ; preds = %then
    %2 = load ptr, ptr %arr, align 8
    %3 = icmp eq ptr %2, null
    br i1 %3, label %success, label %fail, !dbg !10
  
  success:                                          ; preds = %then2
    %4 = tail call ptr @malloc(i64 0)
    store ptr %4, ptr %arr, align 8
    %sunkaddr = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 4, ptr %sunkaddr, align 8
    br label %ifcont12
  
  fail:                                             ; preds = %then2
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 91, ptr @0), !dbg !10
    unreachable
  
  else:                                             ; preds = %then
    %5 = load ptr, ptr %arr, align 8
    %6 = icmp eq ptr %5, null
    %7 = xor i1 %6, true
    br i1 %7, label %success6, label %fail7, !dbg !11
  
  success6:                                         ; preds = %else
    %add = add i64 %0, 1
    %8 = tail call i64 @prelude_power_2_above_or_equal(i64 %0, i64 %add), !dbg !12
    %9 = tail call ptr @realloc(ptr %5, i64 %8)
    store ptr %9, ptr %arr, align 8
    %sunkaddr16 = getelementptr inbounds i8, ptr %arr, i64 16
    store i64 %8, ptr %sunkaddr16, align 8
    br label %ifcont12
  
  fail7:                                            ; preds = %else
    tail call void @prelude_assert_fail(ptr @2, ptr @1, i32 95, ptr @0), !dbg !11
    unreachable
  
  ifcont12:                                         ; preds = %entry, %success, %success6
    %add15 = add i64 %1, 1
    %sunkaddr17 = getelementptr inbounds i8, ptr %arr, i64 8
    store i64 %add15, ptr %sunkaddr17, align 8
    ret void
  }
  
  define linkonce_odr void @__fmt_endl_u(ptr %p) !dbg !13 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @__fmt_formatter_format_u(ptr %ret, ptr %p, ptr @fmt_newline, i64 1), !dbg !15
    call void @__fmt_formatter_extract_u(ptr %ret), !dbg !16
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_extract_u(ptr %fm) !dbg !17 {
  entry:
    tail call void @__free_except1_fmt.formatter.t.u(ptr %fm)
    ret void
  }
  
  define linkonce_odr void @__fmt_formatter_format_u(ptr noalias %0, ptr %fm, ptr %ptr, i64 %len) !dbg !18 {
  entry:
    %1 = alloca %fmt.formatter.t.u, align 8
    call void @llvm.memcpy.p0.p0.i64(ptr align 8 %1, ptr align 1 %fm, i64 16, i1 false)
    %loadtmp = load ptr, ptr %1, align 8
    %envptr = getelementptr inbounds %closure, ptr %1, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    tail call void %loadtmp(ptr %ptr, i64 %len, ptr %loadtmp1), !dbg !19
    call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 8 %1, i64 16, i1 false)
    ret void
  }
  
  define linkonce_odr void @__fmt_int_base_u(ptr noalias %0, ptr %p, i64 %value, i64 %base) !dbg !20 {
  entry:
    %1 = alloca [64 x i8], align 1
    store [64 x i8] zeroinitializer, ptr %1, align 1
    %lt = icmp slt i64 %base, 2
    br i1 %lt, label %cont, label %false1
  
  false1:                                           ; preds = %entry
    %gt = icmp sgt i64 %base, 36
    br i1 %gt, label %cont, label %false2
  
  false2:                                           ; preds = %false1
    br label %cont
  
  cont:                                             ; preds = %false2, %false1, %entry
    %andtmp = phi i1 [ true, %entry ], [ true, %false1 ], [ false, %false2 ]
    br i1 %andtmp, label %then, label %else, !dbg !21
  
  then:                                             ; preds = %cont
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 1), !dbg !22
    br label %ifcont
  
  else:                                             ; preds = %cont
    %fmt_aux = alloca %closure, align 8
    store ptr @fmt_aux, ptr %fmt_aux, align 8
    %clsr_fmt_aux = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr, align 8
    %base1 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 3
    store i64 %base, ptr %base1, align 8
    store ptr @__ctor_tp.A64.cl, ptr %clsr_fmt_aux, align 8
    %dtor = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr_fmt_aux, i32 0, i32 1
    store ptr null, ptr %dtor, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt_aux, i32 0, i32 1
    store ptr %clsr_fmt_aux, ptr %envptr, align 8
    %2 = call i64 @fmt_aux(i64 %value, i64 0, ptr %clsr_fmt_aux), !dbg !23
    %add = add i64 %2, 1
    %div = sdiv i64 %add, 2
    %__fun_fmt2 = alloca %closure, align 8
    store ptr @__fun_fmt2, ptr %__fun_fmt2, align 8
    %clsr___fun_fmt2 = alloca { ptr, ptr, ptr, i64 }, align 8
    %_fmt_arr5 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 2
    store ptr %1, ptr %_fmt_arr5, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 3
    store i64 %add, ptr %_fmt_length, align 8
    store ptr @__ctor_tp.A64.cl, ptr %clsr___fun_fmt2, align 8
    %dtor7 = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %clsr___fun_fmt2, i32 0, i32 1
    store ptr null, ptr %dtor7, align 8
    %envptr8 = getelementptr inbounds %closure, ptr %__fun_fmt2, i32 0, i32 1
    store ptr %clsr___fun_fmt2, ptr %envptr8, align 8
    call void @prelude_iter_range(i64 0, i64 %div, ptr %__fun_fmt2), !dbg !24
    call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %add), !dbg !25
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    ret void
  }
  
  define linkonce_odr void @__fmt_int_u(ptr noalias %0, ptr %p, i64 %i) !dbg !26 {
  entry:
    tail call void @__fmt_int_base_u(ptr %0, ptr %p, i64 %i, i64 10), !dbg !27
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_a.c(ptr %fmt, ptr %value) !dbg !28 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !29
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, ptr %value, ptr %loadtmp1), !dbg !30
    call void @__fmt_endl_u(ptr %ret2), !dbg !31
    ret void
  }
  
  define linkonce_odr void @__fmt_stdout_println_l(ptr %fmt, i64 %value) !dbg !32 {
  entry:
    %ret = alloca %fmt.formatter.t.u, align 8
    call void @fmt_fmt_stdout_create(ptr %ret), !dbg !33
    %loadtmp = load ptr, ptr %fmt, align 8
    %envptr = getelementptr inbounds %closure, ptr %fmt, i32 0, i32 1
    %loadtmp1 = load ptr, ptr %envptr, align 8
    %ret2 = alloca %fmt.formatter.t.u, align 8
    call void %loadtmp(ptr %ret2, ptr %ret, i64 %value, ptr %loadtmp1), !dbg !34
    call void @__fmt_endl_u(ptr %ret2), !dbg !35
    ret void
  }
  
  define linkonce_odr void @__fmt_str_u(ptr noalias %0, ptr %p, ptr %str) !dbg !36 {
  entry:
    %1 = tail call ptr @string_data(ptr %str), !dbg !37
    %2 = tail call i64 @string_len(ptr %str), !dbg !38
    tail call void @__fmt_formatter_format_u(ptr %0, ptr %p, ptr %1, i64 %2), !dbg !39
    ret void
  }
  
  define linkonce_odr void @__fun_fmt2(i64 %i, ptr %0) !dbg !40 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %_fmt_length = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %_fmt_length2 = load i64, ptr %_fmt_length, align 8
    %sub = sub i64 %_fmt_length2, %i
    %sub3 = sub i64 %sub, 1
    tail call void @__array_fixed_swap_items_cA64.u(ptr %_fmt_arr1, i64 %i, i64 %sub3), !dbg !41
    ret void
  }
  
  define linkonce_odr i64 @fmt_aux(i64 %value, i64 %index, ptr %0) !dbg !42 {
  entry:
    %_fmt_arr = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 2
    %_fmt_arr1 = load ptr, ptr %_fmt_arr, align 8
    %base = getelementptr inbounds { ptr, ptr, ptr, i64 }, ptr %0, i32 0, i32 3
    %base2 = load i64, ptr %base, align 8
    %1 = alloca i64, align 8
    store i64 %value, ptr %1, align 8
    %2 = alloca i64, align 8
    store i64 %index, ptr %2, align 8
    %3 = add i64 %index, 1
    br label %rec
  
  rec:                                              ; preds = %then, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %then ], [ %3, %entry ]
    %4 = phi i64 [ %div, %then ], [ %value, %entry ]
    %div = sdiv i64 %4, %base2
    %scevgep9 = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    %scevgep10 = getelementptr i8, ptr %scevgep9, i64 -1
    %mul = mul i64 %div, %base2
    %sub = sub i64 %4, %mul
    %add = add i64 35, %sub
    %5 = tail call i8 @string_get(ptr @fmt_int_digits, i64 %add), !dbg !43
    store i8 %5, ptr %scevgep10, align 1
    %ne = icmp ne i64 %div, 0
    br i1 %ne, label %then, label %else, !dbg !44
  
  then:                                             ; preds = %rec
    store i64 %div, ptr %1, align 8
    store i64 %lsr.iv, ptr %2, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  
  else:                                             ; preds = %rec
    %lt = icmp slt i64 %4, 0
    %6 = add i64 %lsr.iv, -1, !dbg !45
    br i1 %lt, label %then4, label %ifcont, !dbg !45
  
  then4:                                            ; preds = %else
    %scevgep = getelementptr i8, ptr %_fmt_arr1, i64 %lsr.iv
    store i8 45, ptr %scevgep, align 1
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then4
    %iftmp = phi i64 [ %lsr.iv, %then4 ], [ %6, %else ]
    ret i64 %iftmp
  }
  
  define void @schmu_a__2() !dbg !46 {
  entry:
    ret void
  }
  
  define void @schmu_t__2(ptr noalias %0) !dbg !48 {
  entry:
    store %thing zeroinitializer, ptr %0, align 1
    ret void
  }
  
  declare void @prelude_assert_fail(ptr %0, ptr %1, i32 %2, ptr %3)
  
  declare ptr @malloc(i64 %0)
  
  declare ptr @realloc(ptr %0, i64 %1)
  
  define linkonce_odr void @__free_up.clru(ptr %0) {
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
  
  ret:                                              ; preds = %entry
    ret void
  
  dtor:                                             ; preds = %notnull
    tail call void %dtor1(ptr %env)
    ret void
  
  just_free:                                        ; preds = %notnull
    tail call void @free(ptr %env)
    ret void
  }
  
  define linkonce_odr void @__free_except1_fmt.formatter.t.u(ptr %0) {
  entry:
    tail call void @__free_up.clru(ptr %0)
    ret void
  }
  
  ; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
  declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly %0, ptr noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr ptr @__ctor_tp.A64.cl(ptr %0) {
  entry:
    %1 = tail call ptr @malloc(i64 88)
    tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %1, ptr align 1 %0, i64 88, i1 false)
    ret ptr %1
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !49 {
  entry:
    store i32 1, ptr @schmu_b__2, align 4
    tail call void @schmu_a__2(), !dbg !50
    %index = load i32, ptr @schmu_b__2, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %then, label %else, !dbg !51
  
  then:                                             ; preds = %entry
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @3, i64 4, i64 -1 }, ptr %boxconst, align 8
    call void @string_println(ptr %boxconst), !dbg !52
    br label %ifcont
  
  else:                                             ; preds = %entry
    %boxconst1 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @4, i64 4, i64 -1 }, ptr %boxconst1, align 8
    call void @string_println(ptr %boxconst1), !dbg !53
    br label %ifcont
  
  ifcont:                                           ; preds = %else, %then
    call void @schmu_t__2(ptr @schmu_t2), !dbg !54
    %clstmp = alloca %closure, align 8
    store ptr @__fmt_str_u, ptr %clstmp, align 8
    %envptr = getelementptr inbounds %closure, ptr %clstmp, i32 0, i32 1
    store ptr null, ptr %envptr, align 8
    %boxconst2 = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @5, i64 4, i64 -1 }, ptr %boxconst2, align 8
    call void @__fmt_stdout_println_a.c(ptr %clstmp, ptr %boxconst2), !dbg !55
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr, i32 0, i32 1), align 8
    store i64 2, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr, i32 0, i32 2), align 8
    %0 = call ptr @malloc(i64 0)
    store ptr %0, ptr @schmu_arr, align 8
    call void @__array_push_u(ptr @schmu_arr), !dbg !56
    %clstmp3 = alloca %closure, align 8
    store ptr @__fmt_int_u, ptr %clstmp3, align 8
    %envptr5 = getelementptr inbounds %closure, ptr %clstmp3, i32 0, i32 1
    store ptr null, ptr %envptr5, align 8
    %1 = load i64, ptr getelementptr inbounds ({ ptr, i64, i64 }, ptr @schmu_arr, i32 0, i32 1), align 8
    call void @__fmt_stdout_println_l(ptr %clstmp3, i64 %1), !dbg !57
    %2 = alloca %thing, align 8
    %3 = alloca %thing, align 8
    call void @__free_a.u(ptr @schmu_arr)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.u(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  declare void @free(ptr %0)
  
  attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
  
  !llvm.dbg.cu = !{!0}
  
  !5 = !{}
  $ schmu unit_values.smu > /dev/null 2>&1
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./unit_values
  some
  99.9
  3

Arguments
  $ schmu args.smu --dump-llvm -c --target x86_64-unknown-linux-gnu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
  
  @__schmu_argv = global ptr null
  @__schmu_argc = global i64 0
  @0 = private unnamed_addr constant [2 x i8] c" \00"
  
  declare void @string_concat(ptr noalias %0, ptr %1, ptr %2)
  
  declare void @string_println(ptr %0)
  
  declare void @sys_make_argv(ptr noalias %0)
  
  define void @schmu_nothing() !dbg !2 {
  entry:
    ret void
  }
  
  define i64 @main(i64 %__argc, ptr %__argv) !dbg !6 {
  entry:
    store i64 %__argc, ptr @__schmu_argc, align 8
    store ptr %__argv, ptr @__schmu_argv, align 8
    tail call void @schmu_nothing(), !dbg !7
    %boxconst = alloca { ptr, i64, i64 }, align 8
    store { ptr, i64, i64 } { ptr @0, i64 1, i64 -1 }, ptr %boxconst, align 8
    %ret = alloca { ptr, i64, i64 }, align 8
    call void @sys_make_argv(ptr %ret), !dbg !8
    %ret1 = alloca { ptr, i64, i64 }, align 8
    call void @string_concat(ptr %ret1, ptr %boxconst, ptr %ret), !dbg !9
    call void @string_println(ptr %ret1), !dbg !10
    call void @__free_a.c(ptr %ret1)
    call void @__free_a.a.c(ptr %ret)
    ret i64 0
  }
  
  define linkonce_odr void @__free_a.c(ptr %0) {
  entry:
    %1 = load ptr, ptr %0, align 8
    tail call void @free(ptr %1)
    ret void
  }
  
  define linkonce_odr void @__free_a.a.c(ptr %0) {
  entry:
    %len = getelementptr inbounds { ptr, i64, i64 }, ptr %0, i32 0, i32 1
    %size = load i64, ptr %len, align 8
    %cnt = alloca i64, align 8
    store i64 0, ptr %cnt, align 8
    br label %rec
  
  rec:                                              ; preds = %child, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %child ], [ 0, %entry ]
    %1 = phi i64 [ %4, %child ], [ 0, %entry ]
    %2 = icmp slt i64 %1, %size
    br i1 %2, label %child, label %cont
  
  child:                                            ; preds = %rec
    %3 = load ptr, ptr %0, align 8
    %scevgep = getelementptr i8, ptr %3, i64 %lsr.iv
    tail call void @__free_a.c(ptr %scevgep)
    %4 = add i64 %1, 1
    store i64 %4, ptr %cnt, align 8
    %lsr.iv.next = add i64 %lsr.iv, 24
    br label %rec
  
  cont:                                             ; preds = %rec
    %5 = load ptr, ptr %0, align 8
    tail call void @free(ptr %5)
    ret void
  }
  
  declare void @free(ptr %0)
  
  !llvm.dbg.cu = !{!0}
  
  !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "schmu 0.1x", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly)
  !1 = !DIFile(filename: "args.smu", directory: "$TESTCASE_ROOT")
  !2 = distinct !DISubprogram(name: "nothing", linkageName: "schmu_nothing", scope: !3, file: !3, line: 2, type: !4, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
  !3 = !DIFile(filename: "args.smu", directory: "")
  !4 = !DISubroutineType(flags: DIFlagPrototyped, types: !5)
  !5 = !{}
  !6 = distinct !DISubprogram(name: "main", linkageName: "main", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
  !7 = !DILocation(line: 5, scope: !6)
  !8 = !DILocation(line: 6, column: 27, scope: !6)
  !9 = !DILocation(line: 6, column: 8, scope: !6)
  !10 = !DILocation(line: 6, scope: !6)
  $ schmu args.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./args and other --args=2
  ./args and other --args=2

Support closures with unit types. Closures with only unit types are a special
case and don't need to be allocated.
  $ schmu unit_closures.smu
  $ valgrind-wrapper ./unit_closures 2>&1 | grep allocs | cut -f 5- -d '='
     total heap usage: 2 allocs, 2 frees, 64 bytes allocated

Weak rcs
  $ schmu weak_rc.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./weak_rc

Cyclic ref counts
  $ schmu rc_cycle.smu
  rc_cycle.smu:2.19-25: warning: Unused constructor: Strong
  
  2 | type any_rc['a] = Strong(rc['a]) | Weak(weak_rc['a])
                        ^^^^^^
  
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./rc_cycle

Currying in pipes
  $ schmu curry_pipe.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./curry_pipe
  a: 10 b: 12 c: 1 d: 2
  [cont] a: 10 b: 11

Codgen fixes for recursive types
  $ schmu codegen_recursive.smu
  codegen_recursive.smu:5.5-10: warning: Constructor is never used to build values: Other
  
  5 |   | Other(rc[prom_state])
          ^^^^^
  

  $ schmu codegen_recursive2.smu
  codegen_recursive2.smu:14.5-10: warning: Constructor is never used to build values: Other
  
  14 |   | Other(rc[prom_state])
           ^^^^^
  
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./codegen_recursive2

No unmutated warning on addr
  $ schmu --check no_unmutated_warning.smu

Regression test for miscompile
  $ schmu miscompile_variant_parents.smu
  miscompile_variant_parents.smu:12.66-71: warning: Constructor is never used to build values: Built
  
  12 | type key_state = Resolv_deps(resolv_deps) | Building(building) | Built(built)
                                                                        ^^^^^
  
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./miscompile_variant_parents

Unit closures from stateful iter experiment
  $ schmu unit_closure_fixup.smu
