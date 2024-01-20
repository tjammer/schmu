Simplest module with 1 type and 1 nonpolymorphic function
  $ schmu nonpoly_func.smu -m --dump-llvm
  nonpoly_func.smu:4.7-8: warning: Unused binding c.
  
  4 |   let c = 10
            ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @nonpoly_func_c = internal constant i64 10
  
  define i64 @nonpoly_func_add_ints(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  $ cat nonpoly_func.smi
  (()((5:Mtype(((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:0))((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum2:26)))(8:Tvariant()19:nonpoly_func.either(((5:cname4:left)(4:ctyp())(5:index1:0))((5:cname5:right)(4:ctyp())(5:index1:1)))))(4:Mfun(((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:28)(8:pos_cnum2:32))((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:6)(7:pos_bol2:69)(8:pos_cnum2:69)))(4:Tfun(((2:pt4:Tint)(5:pattr5:Dnorm))((2:pt4:Tint)(5:pattr5:Dnorm)))4:Tint6:Simple)((4:user8:add_ints)(4:call(21:nonpoly_func_add_ints)))))())

  $ schmu import_nonpoly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i64 @nonpoly_func_add_ints(i64 %0, i64 %1)
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_doo(i32 %0) {
  entry:
    %box = alloca i32, align 4
    store i32 %0, i32* %box, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5)
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5)
    ret i64 %2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %1 = tail call i64 @schmu_doo(i32 0)
    tail call void @printf(i8* %0, i64 %1)
    ret i64 0
  }
  $ ./import_nonpoly_func
  5

  $ schmu local_import_nonpoly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare i64 @nonpoly_func_add_ints(i64 %0, i64 %1)
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_do2(i32 %0) {
  entry:
    %box = alloca i32, align 4
    store i32 %0, i32* %box, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5)
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5)
    ret i64 %2
  }
  
  define i64 @schmu_doo(i32 %0) {
  entry:
    %box = alloca i32, align 4
    store i32 %0, i32* %box, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 5)
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @nonpoly_func_add_ints(i64 0, i64 -5)
    ret i64 %2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %1 = tail call i64 @schmu_doo(i32 0)
    tail call void @printf(i8* %0, i64 %1)
    %2 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %3 = tail call i64 @schmu_do2(i32 0)
    tail call void @printf(i8* %2, i64 %3)
    ret i64 0
  }
  $ ./local_import_nonpoly_func
  5
  5

  $ schmu lets.smu -m --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @lets_a = constant i64 12
  @lets_a__2 = constant i64 11
  @lets_b = global i64 0, align 8
  @llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @__lets_init, i8* null }]
  
  define i64 @lets_generate_b() {
  entry:
    ret i64 21
  }
  
  define internal void @__lets_init() section ".text.startup" {
  entry:
    %0 = tail call i64 @lets_generate_b()
    store i64 %0, i64* @lets_b, align 8
    ret void
  }

  $ schmu import_lets.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @lets_b = external global i64
  @lets_a__2 = external global i64
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  declare i8* @string_data(i8* %0)
  
  define void @schmu_inside_fn() {
  entry:
    tail call void @schmu_second()
    ret void
  }
  
  define void @schmu_second() {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %1 = load i64, i64* @lets_a__2, align 8
    tail call void @printf(i8* %0, i64 %1)
    %2 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %3 = load i64, i64* @lets_b, align 8
    tail call void @printf(i8* %2, i64 %3)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %1 = load i64, i64* @lets_a__2, align 8
    tail call void @printf(i8* %0, i64 %1)
    %2 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %3 = load i64, i64* @lets_b, align 8
    tail call void @printf(i8* %2, i64 %3)
    tail call void @schmu_inside_fn()
    ret i64 0
  }
  $ ./import_lets
  11
  21
  11
  21

  $ schmu local_import_lets.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @lets_b = external global i64
  @lets_a__2 = external global i64
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  declare i8* @string_data(i8* %0)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %1 = load i64, i64* @lets_a__2, align 8
    tail call void @printf(i8* %0, i64 %1)
    %2 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %3 = load i64, i64* @lets_b, align 8
    tail call void @printf(i8* %2, i64 %3)
    %4 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %5 = load i64, i64* @lets_a__2, align 8
    tail call void @printf(i8* %4, i64 %5)
    %6 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %7 = load i64, i64* @lets_b, align 8
    tail call void @printf(i8* %6, i64 %7)
    ret i64 0
  }
  $ ./local_import_lets
  11
  21
  11
  21

  $ schmu -m --dump-llvm poly_func.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  $ cat poly_func.smi
  (()((5:Mtype(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:80)(8:pos_cnum2:80))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:80)(8:pos_cnum3:113)))(8:Tvariant((4:Qvar1:1))16:poly_func.option(((5:cname4:some)(4:ctyp((4:Qvar1:1)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(9:Mpoly_fun(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol3:115)(8:pos_cnum3:119))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:8)(7:pos_bol3:178)(8:pos_cnum3:178)))((7:nparams(5:thing))(4:body((3:typ4:Tint)(4:expr(4:Move((3:typ4:Tint)(4:expr(4:Bind7:__expr0((3:typ(8:Tvariant((4:Qvar1:2))16:poly_func.option(((5:cname4:some)(4:ctyp((4:Qvar1:2)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var5:thing()))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:5)(7:pos_bol3:136)(8:pos_cnum3:144))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:5)(7:pos_bol3:136)(8:pos_cnum3:149)))))((3:typ4:Tint)(4:expr(2:If((3:typ5:Tbool)(4:expr(3:Bop7:Equal_i((3:typ4:Ti32)(4:expr(13:Variant_index((3:typ(8:Tvariant((4:Qvar1:2))16:poly_func.option(((5:cname4:some)(4:ctyp((4:Qvar1:2)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0(9:poly_func)))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:5)(7:pos_bol3:136)(8:pos_cnum3:138))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:8)(7:pos_bol3:178)(8:pos_cnum3:178)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:155))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:159)))))((3:typ4:Ti32)(4:expr(5:Const(3:I321:0)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:155))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:159)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:155))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:159)))))(4:true)((3:typ4:Tint)(4:expr(4:Bind7:__expr0((3:typ(4:Qvar1:2))(4:expr(12:Variant_data((3:typ(8:Tvariant((4:Qvar1:2))16:poly_func.option(((5:cname4:some)(4:ctyp((4:Qvar1:2)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0(9:poly_func)))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:5)(7:pos_bol3:136)(8:pos_cnum3:138))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:8)(7:pos_bol3:178)(8:pos_cnum3:178)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:155))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:159)))))((3:typ4:Tint)(4:expr(5:Const(3:Int1:0)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:164))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:165)))))))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:164))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:165)))))((3:typ4:Tint)(4:expr(4:Bind7:__expr0((3:typ(8:Tvariant((4:Qvar1:2))16:poly_func.option(((5:cname4:some)(4:ctyp((4:Qvar1:2)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0(9:poly_func)))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:155))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:159)))))((3:typ4:Tint)(4:expr(5:Const(3:Int1:1)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:7)(7:pos_bol3:166)(8:pos_cnum3:176))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:7)(7:pos_bol3:166)(8:pos_cnum3:177)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:7)(7:pos_bol3:166)(8:pos_cnum3:170))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:7)(7:pos_bol3:166)(8:pos_cnum3:174)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:155))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:159)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:155))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:159)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:155))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:6)(7:pos_bol3:151)(8:pos_cnum3:159))))))(4:func((7:tparams(((2:pt(8:Tvariant((4:Qvar1:2))16:poly_func.option(((5:cname4:some)(4:ctyp((4:Qvar1:2)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(5:pattr5:Dnorm))))(3:ret4:Tint)(4:kind6:Simple)(7:touched())))(6:inline5:false))8:classify()))())

  $ schmu import_poly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %poly_func.optionf = type { i32, double }
  %poly_func.optioni = type { i32, i64 }
  
  @schmu_none = constant %poly_func.optionf { i32 1, double undef }
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define linkonce_odr i64 @__poly_func_classify_poly_func.optionf.i(%poly_func.optionf* %thing) {
  entry:
    %tag1 = bitcast %poly_func.optionf* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %poly_func.optionf, %poly_func.optionf* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @__poly_func_classify_poly_func.optioni.i(%poly_func.optioni* %thing) {
  entry:
    %tag1 = bitcast %poly_func.optioni* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %poly_func.optioni, %poly_func.optioni* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst = alloca %poly_func.optioni, align 8
    store %poly_func.optioni { i32 0, i64 3 }, %poly_func.optioni* %boxconst, align 8
    %1 = call i64 @__poly_func_classify_poly_func.optioni.i(%poly_func.optioni* %boxconst)
    call void @printf(i8* %0, i64 %1)
    %2 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst1 = alloca %poly_func.optionf, align 8
    store %poly_func.optionf { i32 0, double 3.000000e+00 }, %poly_func.optionf* %boxconst1, align 8
    %3 = call i64 @__poly_func_classify_poly_func.optionf.i(%poly_func.optionf* %boxconst1)
    call void @printf(i8* %2, i64 %3)
    %4 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %5 = call i64 @__poly_func_classify_poly_func.optionf.i(%poly_func.optionf* @schmu_none)
    call void @printf(i8* %4, i64 %5)
    ret i64 0
  }
  $ ./import_poly_func
  0
  0
  1

  $ schmu local_import_poly_func.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %poly_func.optionf = type { i32, double }
  %poly_func.optioni = type { i32, i64 }
  
  @schmu_none = constant %poly_func.optionf { i32 1, double undef }
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define linkonce_odr i64 @__poly_func_classify_poly_func.optionf.i(%poly_func.optionf* %thing) {
  entry:
    %tag1 = bitcast %poly_func.optionf* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %poly_func.optionf, %poly_func.optionf* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define linkonce_odr i64 @__poly_func_classify_poly_func.optioni.i(%poly_func.optioni* %thing) {
  entry:
    %tag1 = bitcast %poly_func.optioni* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %poly_func.optioni, %poly_func.optioni* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst = alloca %poly_func.optioni, align 8
    store %poly_func.optioni { i32 0, i64 3 }, %poly_func.optioni* %boxconst, align 8
    %1 = call i64 @__poly_func_classify_poly_func.optioni.i(%poly_func.optioni* %boxconst)
    call void @printf(i8* %0, i64 %1)
    %2 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %boxconst1 = alloca %poly_func.optionf, align 8
    store %poly_func.optionf { i32 0, double 3.000000e+00 }, %poly_func.optionf* %boxconst1, align 8
    %3 = call i64 @__poly_func_classify_poly_func.optionf.i(%poly_func.optionf* %boxconst1)
    call void @printf(i8* %2, i64 %3)
    %4 = call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    %5 = call i64 @__poly_func_classify_poly_func.optionf.i(%poly_func.optionf* @schmu_none)
    call void @printf(i8* %4, i64 %5)
    ret i64 0
  }
  $ ./local_import_poly_func
  0
  0
  1

  $ schmu -m malloc_some.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @malloc_some_a = constant i64 12
  @malloc_some_b = global i64 0, align 8
  @malloc_some_vtest = global i64* null, align 8
  @malloc_some_vtest2 = global i64* null, align 8
  @llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @__malloc_some_init, i8* null }]
  @llvm.global_dtors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @__malloc_some_deinit, i8* null }]
  
  define i64 @malloc_some_add_ints(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define internal void @__malloc_some_init() section ".text.startup" {
  entry:
    %0 = tail call i64 @malloc_some_add_ints(i64 1, i64 3)
    store i64 %0, i64* @malloc_some_b, align 8
    %1 = tail call i8* @malloc(i64 32)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** @malloc_some_vtest, align 8
    store i64 2, i64* %2, align 8
    %cap = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 16
    %data = bitcast i8* %3 to i64*
    store i64 0, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 1, i64* %"1", align 8
    %4 = tail call i8* @malloc(i64 24)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** @malloc_some_vtest2, align 8
    store i64 1, i64* %5, align 8
    %cap2 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %cap2, align 8
    %6 = getelementptr i8, i8* %4, i64 16
    %data3 = bitcast i8* %6 to i64*
    store i64 3, i64* %data3, align 8
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__malloc_some_deinit() section ".text.startup" {
  entry:
    tail call void @__free_ai(i64** @malloc_some_vtest2)
    tail call void @__free_ai(i64** @malloc_some_vtest)
    ret void
  }
  
  define linkonce_odr void @__free_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %2 = bitcast i64* %1 to i8*
    call void @free(i8* %2)
    ret void
  }
  
  declare void @free(i8* %0)

  $ cat malloc_some.smi
  (()((5:Mtype(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:0))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum2:29)))(8:Tvariant()18:malloc_some.either(((5:cname4:left)(4:ctyp())(5:index1:4))((5:cname5:right)(4:ctyp())(5:index1:5)))))(4:Mfun(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:3)(7:pos_bol2:31)(8:pos_cnum2:35))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:3)(7:pos_bol2:31)(8:pos_cnum2:56)))(4:Tfun(((2:pt4:Tint)(5:pattr5:Dnorm))((2:pt4:Tint)(5:pattr5:Dnorm)))4:Tint6:Simple)((4:user8:add_ints)(4:call(20:malloc_some_add_ints))))(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:5)(7:pos_bol2:58)(8:pos_cnum2:58))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:5)(7:pos_bol2:58)(8:pos_cnum2:68)))4:Tint((4:user1:a)(4:call(13:malloc_some_a)))5:false)(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:7)(7:pos_bol2:70)(8:pos_cnum2:70))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:7)(7:pos_bol2:70)(8:pos_cnum2:92)))4:Tint((4:user1:b)(4:call(13:malloc_some_b)))5:false)(9:Mpoly_fun(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum2:98))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:112)))((7:nparams(1:x))(4:body((3:typ(4:Qvar1:1))(4:expr(4:Move((3:typ(4:Qvar1:1))(4:expr(3:App(6:callee((3:typ(4:Tfun(((2:pt(4:Qvar1:1))(5:pattr5:Dnorm)))(4:Qvar1:1)6:Simple))(4:expr(3:Var4:copy()))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:105))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:109))))))(4:args((((3:typ(4:Qvar1:1))(4:expr(3:Var1:x()))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:110))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:111)))))5:Dnorm)))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:105))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:112)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:105))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol2:94)(8:pos_cnum3:112))))))(4:func((7:tparams(((2:pt(4:Qvar1:1))(5:pattr5:Dnorm))))(3:ret(4:Qvar1:1))(4:kind6:Simple)(7:touched())))(6:inline5:false))2:id())(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:11)(7:pos_bol3:114)(8:pos_cnum3:114))((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:11)(7:pos_bol3:114)(8:pos_cnum3:132)))(6:Tarray4:Tint)((4:user5:vtest)(4:call(17:malloc_some_vtest)))5:false)(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:12)(7:pos_bol3:133)(8:pos_cnum3:133))((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:12)(7:pos_bol3:133)(8:pos_cnum3:149)))(6:Tarray4:Tint)((4:user6:vtest2)(4:call(18:malloc_some_vtest2)))5:false))())

  $ schmu use_malloc_some.smu --dump-llvm
  use_malloc_some.smu:3.5-17: warning: Unused binding do_something.
  
  3 | fun do_something(big):
          ^^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %big = type { i64, double, i64, i64 }
  
  @malloc_some_vtest = external global i64*
  @0 = private unnamed_addr constant { i64, i64, [4 x i8] } { i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i8* @string_data(i8* %0)
  
  declare void @printf(i8* %0, i64 %1)
  
  define linkonce_odr void @__array_inner_i.u-ai-i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i8*, i8*, i64*, %closure }*
    %arr = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    %2 = add i64 %i, 1
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %lsr.iv = phi i64 [ %lsr.iv.next, %else ], [ %2, %entry ]
    %3 = add i64 %lsr.iv, -1
    %4 = load i64, i64* %arr1, align 8
    %eq = icmp eq i64 %3, %4
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %scevgep = getelementptr i64, i64* %arr1, i64 %lsr.iv
    %scevgep3 = getelementptr i64, i64* %scevgep, i64 1
    %5 = load i64, i64* %scevgep3, align 8
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 24
    %6 = bitcast i8* %sunkaddr to i8**
    %loadtmp = load i8*, i8** %6, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %sunkaddr5 = getelementptr inbounds i8, i8* %0, i64 32
    %7 = bitcast i8* %sunkaddr5 to i8**
    %loadtmp2 = load i8*, i8** %7, align 8
    tail call void %casttmp(i64 %5, i8* %loadtmp2)
    store i64 %lsr.iv, i64* %1, align 8
    %lsr.iv.next = add i64 %lsr.iv, 1
    br label %rec
  }
  
  define linkonce_odr void @__array_iter_aii.u.u(i64* %arr, %closure* %f) {
  entry:
    %__array_inner_i.u-ai-i.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__array_inner_i.u-ai-i.u to i8**
    store i8* bitcast (void (i64, i8*)* @__array_inner_i.u-ai-i.u to i8*), i8** %funptr5, align 8
    %clsr___array_inner_i.u-ai-i.u = alloca { i8*, i8*, i64*, %closure }, align 8
    %arr1 = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u, i32 0, i32 2
    store i64* %arr, i64** %arr1, align 8
    %f2 = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %ctor6 = bitcast { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u to i8**
    store i8* bitcast (i8* (i8*)* @__ctor_tup-ai-i.u to i8*), i8** %ctor6, align 8
    %dtor = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i8*, i8*, i64*, %closure }* %clsr___array_inner_i.u-ai-i.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__array_inner_i.u-ai-i.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__array_inner_i.u-ai-i.u(i64 0, i8* %env)
    ret void
  }
  
  define i64 @schmu_do_something(%big* %big) {
  entry:
    %0 = bitcast %big* %big to i64*
    %1 = load i64, i64* %0, align 8
    %add = add i64 %1, 1
    ret i64 %add
  }
  
  define void @schmu_printi(i64 %i) {
  entry:
    %0 = tail call i8* @string_data(i8* bitcast ({ i64, i64, [4 x i8] }* @0 to i8*))
    tail call void @printf(i8* %0, i64 %i)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr i8* @__ctor_tup-ai-i.u(i8* %0) {
  entry:
    %1 = bitcast i8* %0 to { i8*, i8*, i64*, %closure }*
    %2 = call i8* @malloc(i64 40)
    %3 = bitcast i8* %2 to { i8*, i8*, i64*, %closure }*
    %4 = bitcast { i8*, i8*, i64*, %closure }* %3 to i8*
    %5 = bitcast { i8*, i8*, i64*, %closure }* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* %5, i64 40, i1 false)
    %arr = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %3, i32 0, i32 2
    call void @__copy_ai(i64** %arr)
    %f = getelementptr inbounds { i8*, i8*, i64*, %closure }, { i8*, i8*, i64*, %closure }* %3, i32 0, i32 3
    call void @__copy_i.u(%closure* %f)
    %6 = bitcast { i8*, i8*, i64*, %closure }* %3 to i8*
    ret i8* %6
  }
  
  declare i8* @malloc(i64 %0)
  
  define linkonce_odr void @__copy_ai(i64** %0) {
  entry:
    %1 = load i64*, i64** %0, align 8
    %sz1 = bitcast i64* %1 to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = mul i64 %size, 8
    %3 = add i64 %2, 16
    %4 = call i8* @malloc(i64 %3)
    %5 = bitcast i8* %4 to i64*
    %6 = bitcast i64* %5 to i8*
    %7 = bitcast i64* %1 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 %3, i1 false)
    %newcap = getelementptr i64, i64* %5, i64 1
    store i64 %size, i64* %newcap, align 8
    store i64* %5, i64** %0, align 8
    ret void
  }
  
  define linkonce_odr void @__copy_i.u(%closure* %0) {
  entry:
    %1 = getelementptr inbounds %closure, %closure* %0, i32 0, i32 1
    %2 = load i8*, i8** %1, align 8
    %3 = icmp eq i8* %2, null
    br i1 %3, label %ret, label %notnull
  
  notnull:                                          ; preds = %entry
    %ctor3 = bitcast i8* %2 to i8*
    %4 = bitcast i8* %ctor3 to i8**
    %ctor1 = load i8*, i8** %4, align 8
    %ctor2 = bitcast i8* %ctor1 to i8* (i8*)*
    %5 = call i8* %ctor2(i8* %2)
    %6 = bitcast %closure* %0 to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %6, i64 8
    %7 = bitcast i8* %sunkaddr to i8**
    store i8* %5, i8** %7, align 8
    br label %ret
  
  ret:                                              ; preds = %notnull, %entry
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = load i64*, i64** @malloc_some_vtest, align 8
    %clstmp = alloca %closure, align 8
    %funptr1 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @schmu_printi to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @__array_iter_aii.u.u(i64* %0, %closure* %clstmp)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  $ ./use_malloc_some
  0
  1

Allocate and clean init code with refcounting
  $ schmu init.smu -m
  $ schmu use_init.smu
  use_init.smu:1.8-12: warning: Unused module import init.
  
  1 | import Init
             ^^^^
  
  $ ./use_init
  hello from init

Use module name prefix for function names to prevent linker dups
  $ schmu nameclash_mod.smu -m
  $ schmu nameclash_use.smu
  nameclash_use.smu:1.8-21: warning: Unused module import nameclash_mod.
  
  1 | import Nameclash_mod
             ^^^^^^^^^^^^^
  
  nameclash_use.smu:2.5-18: warning: Unused binding specific_name.
  
  2 | fun specific_name(): ()
          ^^^^^^^^^^^^^
  
Distinguish closures and functions
  $ schmu decl_lambda.smu -m
  $ schmu use_lambda.smu
  $ ./use_lambda


Test signature
  $ schmu -m sign.smu
  sign.smu:20.5-11: warning: Unused binding hidden.
  
  20 | fun hidden(a):
           ^^^^^^
  
  $ schmu use-sign.smu
  $ ./use-sign
  hello 20
  200
  20.2
  $ schmu use-sign-hidden.smu
  use-sign-hidden.smu:4.1-6: error: No var named hidde.
  
  4 | hidde(10)
      ^^^^^
  
  [1]
  $ schmu use-sign-hidden-type.smu
  use-sign-hidden-type.smu:4.1-25: error: Unbound type hidden_type..
  
  4 | let i : hidden_type = 10
      ^^^^^^^^^^^^^^^^^^^^^^^^
  
  [1]

Polymorphic lambdas in modules
  $ schmu -m poly_lambda.smu
  $ schmu use_poly_lambda.smu


Local modules
  $ schmu --dump-llvm local_module.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %nosig.t = type { i64 }
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"test\00" }
  @schmu_local_value = constant i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*)
  @schmu_test__2 = constant %nosig.t { i64 10 }
  @1 = private unnamed_addr constant { i64, i64, [13 x i8] } { i64 12, i64 12, [13 x i8] c"hey poly %s\0A\00" }
  @2 = private unnamed_addr constant { i64, i64, [10 x i8] } { i64 9, i64 9, [10 x i8] c"hey thing\00" }
  @3 = private unnamed_addr constant { i64, i64, [11 x i8] } { i64 10, i64 10, [11 x i8] c"i'm nested\00" }
  @4 = private unnamed_addr constant { i64, i64, [9 x i8] } { i64 8, i64 8, [9 x i8] c"hey test\00" }
  
  declare void @string_print(i8* %0)
  
  define linkonce_odr void @__schmu_local_poly_test_ac.u(i8* %a) {
  entry:
    %0 = getelementptr i8, i8* %a, i64 16
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [13 x i8] }* @1 to i8*), i64 16), i8* %0)
    ret void
  }
  
  define void @schmu_local_test() {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [10 x i8] }* @2 to i8*))
    ret void
  }
  
  define void @schmu_nosig_nested_nested() {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [11 x i8] }* @3 to i8*))
    ret void
  }
  
  define void @schmu_test() {
  entry:
    tail call void @string_print(i8* bitcast ({ i64, i64, [9 x i8] }* @4 to i8*))
    ret void
  }
  
  declare void @printf(i8* %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    tail call void @schmu_test()
    tail call void @schmu_local_test()
    tail call void @__schmu_local_poly_test_ac.u(i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*))
    tail call void @schmu_nosig_nested_nested()
    ret i64 0
  }
  $ valgrind -q --leak-check=yes --show-reachable=yes ./local_module
  hey test
  hey thing
  hey poly test
  i'm nested

Fix shadowing for local modules
  $ schmu local_module_shadowing.smu
  $ ./local_module_shadowing
  i'm in a module
  a
  10
  a
  a
  10

Prefix type names in nested polymorphic functions
  $ schmu -m nested_fn.smu
  $ schmu use_nested_fn.smu

Use local module from other file
  $ schmu -m local_otherfile.smu
  $ schmu use_local_otherfile.smu
  $ ./use_local_otherfile
  hey test
  hey thing
  hey poly test
  i'm nested
  hey test
  hey thing
  hey poly test
  i'm nested
  i'm nested


Local modules can shadow types. Use unique type names in codegen
  $ schmu local_module_type_shadowing.smu --dump-llvm
  local_module_type_shadowing.smu:5.5-6: warning: Unused binding t.
  
  5 | let t = {a = 10}
          ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %t = type { i64 }
  %nosig.t = type { i64, i64 }
  %nosig.nested.t = type { i64, i64, i64 }
  
  @schmu_t = constant %t { i64 10 }
  @schmu_nosig_t = constant %nosig.t { i64 10, i64 20 }
  @schmu_nosig_nested_t = constant %nosig.nested.t { i64 10, i64 20, i64 30 }
  
  define i64 @main(i64 %arg) {
  entry:
    ret i64 0
  }

Search for modules when variables cannot be found
  $ schmu err_local_otherfile.smu
  err_local_otherfile.smu:1.1-24: error: No var named Local_otherfile.aliased, but a module with the name exists.
  
  1 | Local_otherfile.aliased
      ^^^^^^^^^^^^^^^^^^^^^^^
  
  [1]

Use directory as module
  $ cd modd
  $ schmu -m hidden.smu
  $ schmu -m indirect.smu
  $ schmu -m public.smu
  $ schmu -m modd.smu
  $ cd ..
  $ schmu consume_dir.smu
  $ ./consume_dir
  modd
  indirect
  public
  lol
  lol
  hello
  world
  $ echo "print(Indirect.a)" > err.smu
  $ schmu err.smu
  indirect.smi
  err.smu:1.7-17: error: Module indirect: Cannot find module: Indirect.
  
  1 | print(Indirect.a)
            ^^^^^^^^^^
  
  [1]

Transitive polymorphic dependency needs to be available
  $ schmu -m transitive.smu
  $ schmu -m direct_dep.smu
  $ schmu use_dep.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  define linkonce_odr i64 @__direct_dep_id_i.i(i64 %a) {
  entry:
    %0 = tail call i64 @__transitive_id_i.i(i64 %a)
    ret i64 %0
  }
  
  define linkonce_odr i64 @__transitive_id_i.i(i64 %a) {
  entry:
    ret i64 %a
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @__direct_dep_id_i.i(i64 10)
    ret i64 %0
  }

Apply local functors
  $ schmu --dump-llvm local_functor.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %outer.t = type { i64 }
  %somerec.t = type { i64, i64 }
  
  @0 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"%li\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"%.9g\0A\00" }
  
  define double @schmu_floata_add(double %a, double %b) {
  entry:
    %add = fadd double %a, %b
    ret double %add
  }
  
  define i64 @schmu_inta_add(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define double @schmu_make_schmu_floata_add_twice(double %a, double %b) {
  entry:
    %0 = tail call double @schmu_floata_add(double %a, double %b)
    %1 = tail call double @schmu_floata_add(double %0, double %b)
    ret double %1
  }
  
  define i64 @schmu_make_schmu_inta_add_twice(i64 %a, i64 %b) {
  entry:
    %0 = tail call i64 @schmu_inta_add(i64 %a, i64 %b)
    %1 = tail call i64 @schmu_inta_add(i64 %0, i64 %b)
    ret i64 %1
  }
  
  define i64 @schmu_make_schmu_outa_add_twice(i64 %0, i64 %1) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %box2 = alloca i64, align 8
    store i64 %1, i64* %box2, align 8
    %ret = alloca %outer.t, align 8
    %2 = tail call i64 @schmu_outa_add(i64 %0, i64 %1)
    %box7 = bitcast %outer.t* %ret to i64*
    store i64 %2, i64* %box7, align 8
    %ret13 = alloca %outer.t, align 8
    %3 = tail call i64 @schmu_outa_add(i64 %2, i64 %1)
    %box14 = bitcast %outer.t* %ret13 to i64*
    store i64 %3, i64* %box14, align 8
    ret i64 %3
  }
  
  define { i64, i64 } @schmu_make_schmu_somerec_add_twice(i64 %0, i64 %1, i64 %2, i64 %3) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst32 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst32, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %box2 = alloca { i64, i64 }, align 8
    %fst333 = bitcast { i64, i64 }* %box2 to i64*
    store i64 %2, i64* %fst333, align 8
    %snd4 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box2, i32 0, i32 1
    store i64 %3, i64* %snd4, align 8
    %ret = alloca %somerec.t, align 8
    %4 = tail call { i64, i64 } @schmu_somerec_add(i64 %0, i64 %1, i64 %2, i64 %3)
    %box15 = bitcast %somerec.t* %ret to { i64, i64 }*
    store { i64, i64 } %4, { i64, i64 }* %box15, align 8
    %fst1834 = bitcast { i64, i64 }* %box15 to i64*
    %fst19 = load i64, i64* %fst1834, align 8
    %snd20 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box15, i32 0, i32 1
    %snd21 = load i64, i64* %snd20, align 8
    %ret27 = alloca %somerec.t, align 8
    %5 = tail call { i64, i64 } @schmu_somerec_add(i64 %fst19, i64 %snd21, i64 %2, i64 %3)
    %box28 = bitcast %somerec.t* %ret27 to { i64, i64 }*
    store { i64, i64 } %5, { i64, i64 }* %box28, align 8
    ret { i64, i64 } %5
  }
  
  define i64 @schmu_outa_add(i64 %0, i64 %1) {
  entry:
    %box = alloca i64, align 8
    store i64 %0, i64* %box, align 8
    %box2 = alloca i64, align 8
    store i64 %1, i64* %box2, align 8
    %2 = alloca %outer.t, align 8
    %i5 = bitcast %outer.t* %2 to i64*
    %add = add i64 %0, %1
    store i64 %add, i64* %i5, align 8
    ret i64 %add
  }
  
  define { i64, i64 } @schmu_somerec_add(i64 %0, i64 %1, i64 %2, i64 %3) {
  entry:
    %box = alloca { i64, i64 }, align 8
    %fst10 = bitcast { i64, i64 }* %box to i64*
    store i64 %0, i64* %fst10, align 8
    %snd = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box, i32 0, i32 1
    store i64 %1, i64* %snd, align 8
    %a = bitcast { i64, i64 }* %box to %somerec.t*
    %box2 = alloca { i64, i64 }, align 8
    %fst311 = bitcast { i64, i64 }* %box2 to i64*
    store i64 %2, i64* %fst311, align 8
    %snd4 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %box2, i32 0, i32 1
    store i64 %3, i64* %snd4, align 8
    %b = bitcast { i64, i64 }* %box2 to %somerec.t*
    %4 = alloca %somerec.t, align 8
    %a612 = bitcast %somerec.t* %4 to i64*
    %add = add i64 %0, %2
    store i64 %add, i64* %a612, align 8
    %b7 = getelementptr inbounds %somerec.t, %somerec.t* %4, i32 0, i32 1
    %5 = getelementptr inbounds %somerec.t, %somerec.t* %a, i32 0, i32 1
    %6 = getelementptr inbounds %somerec.t, %somerec.t* %b, i32 0, i32 1
    %add8 = add i64 %1, %3
    store i64 %add8, i64* %b7, align 8
    %unbox = bitcast %somerec.t* %4 to { i64, i64 }*
    %unbox9 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox9
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = tail call i64 @schmu_make_schmu_inta_add_twice(i64 1, i64 2)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [5 x i8] }* @0 to i8*), i64 16), i64 %0)
    %1 = tail call double @schmu_make_schmu_floata_add_twice(double 1.000000e+00, double 2.000000e+00)
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [6 x i8] }* @1 to i8*), i64 16), double %1)
    ret i64 0
  }
  
  declare void @printf(i8* %0, ...)
  $ ./local_functor
  5
  5

Simple functor
  $ schmu -m simple_functor.smu
  $ schmu use_simple_functor.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %simple_functor.make.otherac = type { i8*, i8* }
  
  @0 = private unnamed_addr constant { i64, i64, [15 x i8] } { i64 14, i64 14, [15 x i8] c"create: %s %s\0A\00" }
  @1 = private unnamed_addr constant { i64, i64, [5 x i8] } { i64 4, i64 4, [5 x i8] c"this\00" }
  @2 = private unnamed_addr constant { i64, i64, [6 x i8] } { i64 5, i64 5, [6 x i8] c"other\00" }
  
  define linkonce_odr { i64, i64 } @__simple_functor_make_string_create_acac.simple_functor.make.otherac(i8* %this, i8* %other) {
  entry:
    %0 = getelementptr i8, i8* %this, i64 16
    %1 = getelementptr i8, i8* %other, i64 16
    tail call void (i8*, ...) @printf(i8* getelementptr (i8, i8* bitcast ({ i64, i64, [15 x i8] }* @0 to i8*), i64 16), i8* %0, i8* %1)
    %2 = alloca %simple_functor.make.otherac, align 8
    %this14 = bitcast %simple_functor.make.otherac* %2 to i8**
    store i8* %this, i8** %this14, align 8
    %other2 = getelementptr inbounds %simple_functor.make.otherac, %simple_functor.make.otherac* %2, i32 0, i32 1
    store i8* %other, i8** %other2, align 8
    %unbox = bitcast %simple_functor.make.otherac* %2 to { i64, i64 }*
    %unbox3 = load { i64, i64 }, { i64, i64 }* %unbox, align 8
    ret { i64, i64 } %unbox3
  }
  
  declare void @printf(i8* %0, ...)
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [5 x i8] }* @1 to i8*), i8** %0, align 8
    %1 = alloca i8*, align 8
    %2 = bitcast i8** %1 to i8*
    %3 = bitcast i8** %0 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* %3, i64 8, i1 false)
    call void @__copy_ac(i8** %1)
    %4 = load i8*, i8** %1, align 8
    %5 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, [6 x i8] }* @2 to i8*), i8** %5, align 8
    %6 = alloca i8*, align 8
    %7 = bitcast i8** %6 to i8*
    %8 = bitcast i8** %5 to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %7, i8* %8, i64 8, i1 false)
    call void @__copy_ac(i8** %6)
    %9 = load i8*, i8** %6, align 8
    %ret = alloca %simple_functor.make.otherac, align 8
    %10 = call { i64, i64 } @__simple_functor_make_string_create_acac.simple_functor.make.otherac(i8* %4, i8* %9)
    %box = bitcast %simple_functor.make.otherac* %ret to { i64, i64 }*
    store { i64, i64 } %10, { i64, i64 }* %box, align 8
    call void @__free_simple_functor.make.otherac(%simple_functor.make.otherac* %ret)
    ret i64 0
  }
  
  define linkonce_odr void @__copy_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %sz1 = bitcast i64* %ref to i64*
    %size = load i64, i64* %sz1, align 8
    %2 = add i64 %size, 17
    %3 = call i8* @malloc(i64 %2)
    %4 = sub i64 %2, 1
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %3, i8* %1, i64 %4, i1 false)
    %newref = bitcast i8* %3 to i64*
    %newcap = getelementptr i64, i64* %newref, i64 1
    store i64 %size, i64* %newcap, align 8
    %5 = getelementptr i8, i8* %3, i64 %4
    store i8 0, i8* %5, align 1
    store i8* %3, i8** %0, align 8
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define linkonce_odr void @__free_ac(i8** %0) {
  entry:
    %1 = load i8*, i8** %0, align 8
    %ref = bitcast i8* %1 to i64*
    %2 = bitcast i64* %ref to i8*
    call void @free(i8* %2)
    ret void
  }
  
  define linkonce_odr void @__free_simple_functor.make.otherac(%simple_functor.make.otherac* %0) {
  entry:
    %1 = bitcast %simple_functor.make.otherac* %0 to i8**
    call void @__free_ac(i8** %1)
    %2 = getelementptr inbounds %simple_functor.make.otherac, %simple_functor.make.otherac* %0, i32 0, i32 1
    call void @__free_ac(i8** %2)
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  declare void @free(i8* %0)
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  $ ./use_simple_functor
  create: this other

Nameclashes with filename
  $ schmu -m filename_nameclash.smu

No mutable global state in modules
  $ schmu -m mutable_global_state.smu
  mutable_global_state.smu:1.1-11: error: Mutable top level bindings are not allowed in modules.
  
  1 | let _& = 0
      ^^^^^^^^^^
  
  [1]

No mutable global state in submodules
  $ schmu mutable_global_state_submodule.smu
  mutable_global_state_submodule.smu:2.3-13: error: Mutable top level bindings are not allowed in modules.
  
  2 |   let _& = 0
        ^^^^^^^^^^
  
  [1]
