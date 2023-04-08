Simplest module with 1 type and 1 nonpolymorphic function
  $ schmu nonpoly_func.smu -m --dump-llvm
  nonpoly_func.smu:4:8: warning: Unused binding c
  4 |   (def c 10)
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
  (()((5:Mtype(((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:0))((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum2:28)))(8:Tvariant()19:nonpoly_func/either(((5:cname4:left)(4:ctyp())(5:index1:0))((5:cname5:right)(4:ctyp())(5:index1:1)))))(4:Mfun(((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:30)(8:pos_cnum2:31))((9:pos_fname16:nonpoly_func.smu)(8:pos_lnum1:5)(7:pos_bol2:64)(8:pos_cnum2:73)))(4:Tfun(((2:pt4:Tint)(4:pmut5:false))((2:pt4:Tint)(4:pmut5:false)))4:Tint6:Simple)((4:user8:add_ints)(4:call21:nonpoly_func_add_ints)))))

  $ schmu open_nonpoly_func.smu --dump-llvm && ./open_nonpoly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %nonpoly_func.either = type { i32 }
  
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i64 @nonpoly_func_add_ints(i64 %0, i64 %1)
  
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
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %either = alloca %nonpoly_func.either, align 8
    %tag2 = bitcast %nonpoly_func.either* %either to i32*
    store i32 0, i32* %tag2, align 4
    %0 = tail call i64 @schmu_doo(i32 0)
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    ret i64 0
  }
  5

  $ schmu local_open_nonpoly_func.smu --dump-llvm && ./local_open_nonpoly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %nonpoly_func.either = type { i32 }
  
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 3, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
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
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %either = alloca %nonpoly_func.either, align 8
    %tag7 = bitcast %nonpoly_func.either* %either to i32*
    store i32 0, i32* %tag7, align 4
    %0 = tail call i64 @schmu_doo(i32 0)
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str2 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str2, align 8
    %either3 = alloca %nonpoly_func.either, align 8
    %tag48 = bitcast %nonpoly_func.either* %either3 to i32*
    store i32 0, i32* %tag48, align 4
    %1 = tail call i64 @schmu_do2(i32 0)
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    ret i64 0
  }
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

  $ schmu open_lets.smu --dump-llvm && ./open_lets
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @lets_b = external global i64
  @lets_a__2 = external global i64
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 5, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define void @schmu_inside-fn() {
  entry:
    tail call void @schmu_second()
    ret void
  }
  
  define void @schmu_second() {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %0 = load i64, i64* @lets_a__2, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str1, align 8
    %1 = load i64, i64* @lets_b, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    ret void
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %0 = load i64, i64* @lets_a__2, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str1, align 8
    %1 = load i64, i64* @lets_b, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    tail call void @schmu_inside-fn()
    ret i64 0
  }
  11
  21
  11
  21

  $ cat lets.smi
  (()((4:Mext(((9:pos_fname8:lets.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:1))((9:pos_fname8:lets.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:9)))4:Tint((4:user1:a)(4:call6:lets_a))5:false)(4:Mext(((9:pos_fname8:lets.smu)(8:pos_lnum1:3)(7:pos_bol2:12)(8:pos_cnum2:13))((9:pos_fname8:lets.smu)(8:pos_lnum1:3)(7:pos_bol2:12)(8:pos_cnum2:48)))(4:Tfun(((2:pt(6:Talias12:prelude/cstr(8:Traw_ptr3:Tu8)))(4:pmut5:false))((2:pt4:Tint)(4:pmut5:false)))5:Tunit6:Simple)((4:user6:printf)(4:call6:printf))5:false)(4:Mfun(((9:pos_fname8:lets.smu)(8:pos_lnum1:5)(7:pos_bol2:51)(8:pos_cnum2:52))((9:pos_fname8:lets.smu)(8:pos_lnum1:5)(7:pos_bol2:51)(8:pos_cnum2:73)))(4:Tfun()4:Tint6:Simple)((4:user10:generate_b)(4:call15:lets_generate_b)))(4:Mext(((9:pos_fname8:lets.smu)(8:pos_lnum1:7)(7:pos_bol2:76)(8:pos_cnum2:77))((9:pos_fname8:lets.smu)(8:pos_lnum1:7)(7:pos_bol2:76)(8:pos_cnum2:95)))4:Tint((4:user1:b)(4:call6:lets_b))5:false)(4:Mext(((9:pos_fname8:lets.smu)(8:pos_lnum1:9)(7:pos_bol2:98)(8:pos_cnum2:99))((9:pos_fname8:lets.smu)(8:pos_lnum1:9)(7:pos_bol2:98)(8:pos_cnum3:107)))4:Tint((4:user1:a)(4:call9:lets_a__2))5:false)))

  $ schmu local_open_lets.smu --dump-llvm && ./local_open_lets
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @lets_b = external global i64
  @lets_a__2 = external global i64
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 5, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %0 = load i64, i64* @lets_a__2, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str1, align 8
    %1 = load i64, i64* @lets_b, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    %str2 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str2, align 8
    %2 = load i64, i64* @lets_a__2, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %2)
    %str3 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str3, align 8
    %3 = load i64, i64* @lets_b, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %3)
    ret i64 0
  }
  11
  21
  11
  21

  $ schmu -m --dump-llvm poly_func.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  $ cat poly_func.smi
  (()((9:Mpoly_fun(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:1))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:56)(8:pos_cnum2:70)))((7:nparams(5:thing))(4:body((3:typ4:Tint)(4:expr(4:Bind7:__expr0((3:typ(8:Tvariant((4:Qvar1:1))14:prelude/option(((5:cname4:some)(4:ctyp((4:Qvar1:1)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var5:thing))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:23)(8:pos_cnum2:32))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:23)(8:pos_cnum2:37)))))((3:typ4:Tint)(4:expr(2:If((3:typ5:Tbool)(4:expr(3:Bop7:Equal_i((3:typ4:Ti32)(4:expr(13:Variant_index((3:typ(8:Tvariant((4:Qvar1:1))14:prelude/option(((5:cname4:some)(4:ctyp((4:Qvar1:1)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:23)(8:pos_cnum2:26))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:23)(8:pos_cnum2:37)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:44))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:49)))))((3:typ4:Ti32)(4:expr(5:Const(3:I321:0)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:44))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:49)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:44))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:49)))))((3:typ4:Tint)(4:expr(4:Bind7:__expr0((3:typ(4:Qvar1:1))(4:expr(12:Variant_data((3:typ(8:Tvariant((4:Qvar1:1))14:prelude/option(((5:cname4:some)(4:ctyp((4:Qvar1:1)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:23)(8:pos_cnum2:26))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:23)(8:pos_cnum2:37)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:44))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:49)))))((3:typ4:Tint)(4:expr(5:Const(3:Int1:0)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:53))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:54)))))))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:53))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:54)))))((3:typ4:Tint)(4:expr(4:Bind7:__expr0((3:typ(8:Tvariant((4:Qvar1:1))14:prelude/option(((5:cname4:some)(4:ctyp((4:Qvar1:1)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:44))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:49)))))((3:typ4:Tint)(4:expr(5:Const(3:Int1:1)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:56)(8:pos_cnum2:67))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:56)(8:pos_cnum2:68)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:56)(8:pos_cnum2:61))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:56)(8:pos_cnum2:66)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:44))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:49)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:44))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:38)(8:pos_cnum2:49))))))(4:func((7:tparams(((2:pt(8:Tvariant((4:Qvar1:1))14:prelude/option(((5:cname4:some)(4:ctyp((4:Qvar1:1)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:pmut5:false))))(3:ret4:Tint)(4:kind6:Simple)))(6:inline5:false))8:classify())))

  $ schmu open_poly_func.smu --dump-llvm && ./open_poly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %prelude.option_float = type { i32, double }
  %prelude.option_int = type { i32, i64 }
  
  @schmu_none = global %prelude.option_float zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 4, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optionf.i(%prelude.option_float* %thing) {
  entry:
    %tag1 = bitcast %prelude.option_float* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_float, %prelude.option_float* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optioni.i(%prelude.option_int* %thing) {
  entry:
    %tag1 = bitcast %prelude.option_int* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %option = alloca %prelude.option_int, align 8
    %tag6 = bitcast %prelude.option_int* %option to i32*
    store i32 0, i32* %tag6, align 4
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option, i32 0, i32 1
    store i64 3, i64* %data, align 8
    %0 = call i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optioni.i(%prelude.option_int* %option)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str1, align 8
    %option2 = alloca %prelude.option_float, align 8
    %tag37 = bitcast %prelude.option_float* %option2 to i32*
    store i32 0, i32* %tag37, align 4
    %data4 = getelementptr inbounds %prelude.option_float, %prelude.option_float* %option2, i32 0, i32 1
    store double 3.000000e+00, double* %data4, align 8
    %1 = call i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optionf.i(%prelude.option_float* %option2)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    store i32 1, i32* getelementptr inbounds (%prelude.option_float, %prelude.option_float* @schmu_none, i32 0, i32 0), align 4
    %str5 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str5, align 8
    %2 = call i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optionf.i(%prelude.option_float* @schmu_none)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %2)
    ret i64 0
  }
  0
  0
  1

  $ schmu local_open_poly_func.smu --dump-llvm && ./local_open_poly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %prelude.option_float = type { i32, double }
  %prelude.option_int = type { i32, i64 }
  
  @schmu_none = global %prelude.option_float zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 4, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optionf.i(%prelude.option_float* %thing) {
  entry:
    %tag1 = bitcast %prelude.option_float* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_float, %prelude.option_float* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optioni.i(%prelude.option_int* %thing) {
  entry:
    %tag1 = bitcast %prelude.option_int* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %option = alloca %prelude.option_int, align 8
    %tag6 = bitcast %prelude.option_int* %option to i32*
    store i32 0, i32* %tag6, align 4
    %data = getelementptr inbounds %prelude.option_int, %prelude.option_int* %option, i32 0, i32 1
    store i64 3, i64* %data, align 8
    %0 = call i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optioni.i(%prelude.option_int* %option)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str1, align 8
    %option2 = alloca %prelude.option_float, align 8
    %tag37 = bitcast %prelude.option_float* %option2 to i32*
    store i32 0, i32* %tag37, align 4
    %data4 = getelementptr inbounds %prelude.option_float, %prelude.option_float* %option2, i32 0, i32 1
    store double 3.000000e+00, double* %data4, align 8
    %1 = call i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optionf.i(%prelude.option_float* %option2)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    store i32 1, i32* getelementptr inbounds (%prelude.option_float, %prelude.option_float* @schmu_none, i32 0, i32 0), align 4
    %str5 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str5, align 8
    %2 = call i64 @__prelude.optiong.i_schmu__poly_func_classify_prelude.optionf.i(%prelude.option_float* @schmu_none)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %2)
    ret i64 0
  }
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
    %1 = tail call i8* @malloc(i64 40)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** @malloc_some_vtest, align 8
    store i64 1, i64* %2, align 8
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 8
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 8
    %3 = getelementptr i8, i8* %1, i64 24
    %data = bitcast i8* %3 to i64*
    store i64 0, i64* %data, align 8
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 1, i64* %"1", align 8
    %4 = tail call i8* @malloc(i64 32)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** @malloc_some_vtest2, align 8
    store i64 1, i64* %5, align 8
    %size2 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %size2, align 8
    %cap3 = getelementptr i64, i64* %5, i64 2
    store i64 1, i64* %cap3, align 8
    %6 = getelementptr i8, i8* %4, i64 24
    %data4 = bitcast i8* %6 to i64*
    store i64 3, i64* %data4, align 8
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__malloc_some_deinit() section ".text.startup" {
  entry:
    %0 = load i64*, i64** @malloc_some_vtest2, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %0)
    %1 = load i64*, i64** @malloc_some_vtest, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %1)
    ret void
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 8
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 8
    br label %merge
  
  free:                                             ; preds = %entry
    %4 = bitcast i64* %0 to i8*
    call void @free(i8* %4)
    br label %merge
  
  merge:                                            ; preds = %free, %decr
    ret void
  }
  
  declare void @free(i8* %0)

  $ cat malloc_some.smi
  (()((5:Mtype(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum1:0))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:1)(7:pos_bol1:0)(8:pos_cnum2:32)))(8:Tvariant()18:malloc_some/either(((5:cname4:left)(4:ctyp())(5:index1:4))((5:cname5:right)(4:ctyp())(5:index1:5)))))(4:Mfun(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:3)(7:pos_bol2:34)(8:pos_cnum2:35))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:3)(7:pos_bol2:34)(8:pos_cnum2:62)))(4:Tfun(((2:pt4:Tint)(4:pmut5:false))((2:pt4:Tint)(4:pmut5:false)))4:Tint6:Simple)((4:user8:add_ints)(4:call20:malloc_some_add_ints)))(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:5)(7:pos_bol2:65)(8:pos_cnum2:66))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:5)(7:pos_bol2:65)(8:pos_cnum2:74)))4:Tint((4:user1:a)(4:call13:malloc_some_a))5:false)(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:7)(7:pos_bol2:77)(8:pos_cnum2:78))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:7)(7:pos_bol2:77)(8:pos_cnum2:98)))4:Tint((4:user1:b)(4:call13:malloc_some_b))5:false)(9:Mpoly_fun(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol3:101)(8:pos_cnum3:102))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol3:101)(8:pos_cnum3:115)))((7:nparams(1:x))(4:body((3:typ(4:Qvar1:1))(4:expr(3:Var1:x))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol3:101)(8:pos_cnum3:114))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol3:101)(8:pos_cnum3:115))))))(4:func((7:tparams(((2:pt(4:Qvar1:1))(4:pmut5:false))))(3:ret(4:Qvar1:1))(4:kind6:Simple)))(6:inline5:false))2:id())(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:11)(7:pos_bol3:118)(8:pos_cnum3:119))((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:11)(7:pos_bol3:118)(8:pos_cnum3:134)))(6:Tarray4:Tint)((4:user5:vtest)(4:call17:malloc_some_vtest))5:false)(4:Mext(((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:12)(7:pos_bol3:136)(8:pos_cnum3:137))((9:pos_fname15:malloc_some.smu)(8:pos_lnum2:12)(7:pos_bol3:136)(8:pos_cnum3:151)))(6:Tarray4:Tint)((4:user6:vtest2)(4:call18:malloc_some_vtest2))5:false)))

  $ schmu use_malloc_some.smu --dump-llvm && ./use_malloc_some
  use_malloc_some.smu:3:7: warning: Unused binding do_something
  3 | (defn do_something [big] (+ (.a big) 1))
            ^^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %big = type { i64, double, i64, i64 }
  
  @malloc_some_vtest = external global i64*
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define void @__agg.u.u_schmu__prelude_array-iter_aii.u.u(i64* %arr, %closure* %f) {
  entry:
    %__i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u = alloca %closure, align 8
    %funptr5 = bitcast %closure* %__i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u to i8**
    store i8* bitcast (void (i64, i8*)* @__i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u to i8*), i8** %funptr5, align 8
    %clsr___i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u = alloca { i64, i8*, i64*, %closure }, align 8
    %arr1 = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u, i32 0, i32 2
    store i64* %arr, i64** %arr1, align 8
    %f2 = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u, i32 0, i32 3
    %0 = bitcast %closure* %f2 to i8*
    %1 = bitcast %closure* %f to i8*
    call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* %1, i64 16, i1 false)
    %rc6 = bitcast { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u to i64*
    store i64 2, i64* %rc6, align 8
    %dtor = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u, i32 0, i32 1
    store i8* null, i8** %dtor, align 8
    %env = bitcast { i64, i8*, i64*, %closure }* %clsr___i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u to i8*
    %envptr = getelementptr inbounds %closure, %closure* %__i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @__i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u(i64 0, i8* %env)
    ret void
  }
  
  define void @__i.u-ag-g.u_schmu__prelude_inner_i.u-ai-i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64, i8*, i64*, %closure }*
    %arr = getelementptr inbounds { i64, i8*, i64*, %closure }, { i64, i8*, i64*, %closure }* %clsr, i32 0, i32 2
    %arr1 = load i64*, i64** %arr, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 8
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %2 = phi i64 [ %add, %else ], [ %i, %entry ]
    %len = getelementptr i64, i64* %arr1, i64 1
    %3 = load i64, i64* %len, align 8
    %eq = icmp eq i64 %2, %3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = mul i64 %2, 8
    %4 = bitcast i64* %arr1 to i8*
    %sunkaddr4 = getelementptr i8, i8* %4, i64 %sunkaddr
    %sunkaddr5 = getelementptr i8, i8* %sunkaddr4, i64 24
    %5 = bitcast i8* %sunkaddr5 to i64*
    %6 = load i64, i64* %5, align 8
    %sunkaddr7 = getelementptr inbounds i8, i8* %0, i64 24
    %7 = bitcast i8* %sunkaddr7 to i8**
    %loadtmp = load i8*, i8** %7, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %sunkaddr8 = getelementptr inbounds i8, i8* %0, i64 32
    %8 = bitcast i8* %sunkaddr8 to i8**
    %loadtmp2 = load i8*, i8** %8, align 8
    tail call void %casttmp(i64 %6, i8* %loadtmp2)
    %add = add i64 %2, 1
    store i64 %add, i64* %1, align 8
    br label %rec
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
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %i)
    ret void
  }
  
  ; Function Attrs: argmemonly nofree nounwind willreturn
  declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly %0, i8* noalias nocapture readonly %1, i64 %2, i1 immarg %3) #0
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = load i64*, i64** @malloc_some_vtest, align 8
    %clstmp = alloca %closure, align 8
    %funptr1 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @schmu_printi to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @__agg.u.u_schmu__prelude_array-iter_aii.u.u(i64* %0, %closure* %clstmp)
    ret i64 0
  }
  
  attributes #0 = { argmemonly nofree nounwind willreturn }
  0
  1

Allocate and clean init code with refcounting
  $ schmu init.smu -m
  $ schmu use_init.smu && ./use_init
  use_init.smu:1:1: warning: Unused module open init
  1 | (open init)
      ^^^^^^^^^^^
  
  hello from init

Use module name prefix for function names to prevent linker dups
  $ schmu nameclash_mod.smu -m
  $ schmu nameclash_use.smu
  nameclash_use.smu:1:1: warning: Unused module open nameclash_mod
  1 | (open nameclash_mod)
      ^^^^^^^^^^^^^^^^^^^^
  
  nameclash_use.smu:2:7: warning: Unused binding specific_name
  2 | (defn specific_name [] ())
            ^^^^^^^^^^^^^
  
Distinguish closures and functions
  $ schmu decl_lambda.smu -m
  $ schmu use_lambda.smu && ./use_lambda


Test signature
  $ schmu -m sign.smu
  sign.smu:20:7: warning: Unused binding hidden
  20 | (defn hidden [a]
             ^^^^^^
  
  $ schmu use-sign.smu && ./use-sign
  hello 20
  200
  20.2
  $ schmu use-sign-hidden.smu
  use-sign-hidden.smu:4:2: error: No var named hidden
  4 | (hidden 10)
       ^^^^^^
  
  [1]
  $ schmu use-sign-hidden-type.smu
  use-sign-hidden-type.smu:4:2: error: Unbound type hidden-type.
  4 | (def (i hidden-type) 10)
       ^^^^^^^^^^^^^^^^^^^^^^
  
  [1]
