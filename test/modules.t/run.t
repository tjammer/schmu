Simplest module with 1 type and 1 nonpolymorphic function
  $ schmu nonpoly_func.smu -m --dump-llvm
  nonpoly_func.smu:4:8: warning: Unused binding c
  4 |   (val c 10)
             ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @c = internal constant i64 10
  
  define i64 @schmu_add_ints(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  $ cat nonpoly_func.smi
  ((5:Mtype(8:Tvariant()19:nonpoly_func/either(((5:cname4:left)(4:ctyp())(5:index1:0))((5:cname5:right)(4:ctyp())(5:index1:1)))))(4:Mfun(4:Tfun(((2:pt4:Tint)(4:pmut5:false))((2:pt4:Tint)(4:pmut5:false)))4:Tint6:Simple)8:add_ints))

  $ schmu open_nonpoly_func.smu --dump-llvm && ./open_nonpoly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %either = type { i32 }
  
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare i64 @schmu_add_ints(i64 %0, i64 %1)
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_doo(i32 %0) {
  entry:
    %box = alloca i32, align 4
    store i32 %0, i32* %box, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @schmu_add_ints(i64 0, i64 5)
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @schmu_add_ints(i64 0, i64 -5)
    ret i64 %2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %either = alloca %either, align 8
    %tag2 = bitcast %either* %either to i32*
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
  
  %either = type { i32 }
  
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  declare i64 @schmu_add_ints(i64 %0, i64 %1)
  
  define i64 @schmu_doo(i32 %0) {
  entry:
    %box = alloca i32, align 4
    store i32 %0, i32* %box, align 4
    %eq = icmp eq i32 %0, 0
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %entry
    %1 = tail call i64 @schmu_add_ints(i64 0, i64 5)
    ret i64 %1
  
  else:                                             ; preds = %entry
    %2 = tail call i64 @schmu_add_ints(i64 0, i64 -5)
    ret i64 %2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %either = alloca %either, align 8
    %tag2 = bitcast %either* %either to i32*
    store i32 0, i32* %tag2, align 4
    %0 = tail call i64 @schmu_doo(i32 0)
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    ret i64 0
  }
  5

  $ schmu lets.smu -m --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @a = constant i64 12
  @a__2 = constant i64 11
  @b = global i64 0, align 8
  @llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @__lets_init, i8* null }]
  
  define i64 @schmu_generate_b() {
  entry:
    ret i64 21
  }
  
  define internal void @__lets_init() section ".text.startup" {
  entry:
    %0 = tail call i64 @schmu_generate_b()
    store i64 %0, i64* @b, align 4
    ret void
  }

  $ schmu open_lets.smu --dump-llvm && ./open_lets
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @b = external global i64
  @a__2 = external global i64
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 3, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %0 = load i64, i64* @a__2, align 4
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str1, align 8
    %1 = load i64, i64* @b, align 4
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    ret i64 0
  }
  11
  21

  $ cat lets.smi
  ((4:Mext4:Tint1:a())(4:Mext(4:Tfun(((2:pt(6:Talias4:cstr(8:Traw_ptr3:Tu8)))(4:pmut5:false))((2:pt4:Tint)(4:pmut5:false)))5:Tunit6:Simple)6:printf())(4:Mfun(4:Tfun()4:Tint6:Simple)10:generate_b)(4:Mext4:Tint1:b())(4:Mext4:Tint1:a(4:a__2)))

  $ schmu local_open_lets.smu --dump-llvm && ./local_open_lets
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @b = external global i64
  @a__2 = external global i64
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 5, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %0 = load i64, i64* @a__2, align 4
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str1 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str1, align 8
    %1 = load i64, i64* @b, align 4
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    %str3 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str3, align 8
    %2 = load i64, i64* @a__2, align 4
    tail call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %2)
    %str5 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str5, align 8
    %3 = load i64, i64* @b, align 4
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
  ((9:Mpoly_fun((7:nparams(5:thing))(4:body((3:typ4:Tint)(4:expr(3:Let((2:id7:__expr0)(4:uniq())(4:rmut5:false)(3:lhs((3:typ(8:Tvariant((4:Qvar1:1))6:option(((5:cname4:some)(4:ctyp((4:Qvar1:1)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var5:thing))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:22)(8:pos_cnum2:31))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:22)(8:pos_cnum2:36))))))(4:cont((3:typ4:Tint)(4:expr(2:If((3:typ5:Tbool)(4:expr(3:Bop7:Equal_i((3:typ4:Ti32)(4:expr(13:Variant_index((3:typ(8:Tvariant((4:Tvar(7:Unbound1:11:2)))6:option(((5:cname4:some)(4:ctyp((4:Tvar(7:Unbound1:11:2))))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:22)(8:pos_cnum2:25))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:22)(8:pos_cnum2:36)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:43))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:48)))))((3:typ4:Ti32)(4:expr(5:Const(3:I321:0)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:43))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:48)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:43))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:48)))))((3:typ4:Tint)(4:expr(3:Let((2:id7:__expr0)(4:uniq())(4:rmut5:false)(3:lhs((3:typ(4:Tvar(7:Unbound1:11:2)))(4:expr(12:Variant_data((3:typ(8:Tvariant((4:Tvar(7:Unbound1:11:2)))6:option(((5:cname4:some)(4:ctyp((4:Tvar(7:Unbound1:11:2))))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:22)(8:pos_cnum2:25))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:2)(7:pos_bol2:22)(8:pos_cnum2:36)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:43))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:48))))))(4:cont((3:typ4:Tint)(4:expr(5:Const(3:Int1:0)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:52))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:53)))))))))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:52))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:53)))))((3:typ4:Tint)(4:expr(3:Let((2:id7:__expr0)(4:uniq())(4:rmut5:false)(3:lhs((3:typ(8:Tvariant((4:Tvar(7:Unbound1:11:2)))6:option(((5:cname4:some)(4:ctyp((4:Tvar(7:Unbound1:11:2))))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:43))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:48))))))(4:cont((3:typ4:Tint)(4:expr(5:Const(3:Int1:1)))(4:attr((5:const4:true)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:55)(8:pos_cnum2:66))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:55)(8:pos_cnum2:67)))))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:55)(8:pos_cnum2:60))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:4)(7:pos_bol2:55)(8:pos_cnum2:65)))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:43))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:48)))))))))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:43))((9:pos_fname13:poly_func.smu)(8:pos_lnum1:3)(7:pos_bol2:37)(8:pos_cnum2:48))))))(4:func((7:tparams(((2:pt(8:Tvariant((4:Qvar1:1))6:option(((5:cname4:some)(4:ctyp((4:Qvar1:1)))(5:index1:0))((5:cname4:none)(4:ctyp())(5:index1:1)))))(4:pmut5:false))))(3:ret4:Tint)(4:kind6:Simple)))(6:inline5:false))8:classify))

  $ schmu open_poly_func.smu --dump-llvm && ./open_poly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_float = type { i32, double }
  %option_int = type { i32, i64 }
  
  @none = global %option_float zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 4, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu___optiong.i_classify_optionf.i(%option_float* %thing) {
  entry:
    %tag1 = bitcast %option_float* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_float, %option_float* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu___optiong.i_classify_optioni.i(%option_int* %thing) {
  entry:
    %tag1 = bitcast %option_int* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %option = alloca %option_int, align 8
    %tag9 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag9, align 4
    %data1 = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 3, i64* %data1, align 4
    %0 = call i64 @schmu___optiong.i_classify_optioni.i(%option_int* %option)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str2 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str2, align 8
    %option4 = alloca %option_float, align 8
    %tag510 = bitcast %option_float* %option4 to i32*
    store i32 0, i32* %tag510, align 4
    %data6 = getelementptr inbounds %option_float, %option_float* %option4, i32 0, i32 1
    store double 3.000000e+00, double* %data6, align 8
    %1 = call i64 @schmu___optiong.i_classify_optionf.i(%option_float* %option4)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    store i32 1, i32* getelementptr inbounds (%option_float, %option_float* @none, i32 0, i32 0), align 4
    %str7 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str7, align 8
    %2 = call i64 @schmu___optiong.i_classify_optionf.i(%option_float* @none)
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
  
  %option_float = type { i32, double }
  %option_int = type { i32, i64 }
  
  @none = global %option_float zeroinitializer, align 16
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 4, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu___optiong.i_classify_optionf.i(%option_float* %thing) {
  entry:
    %tag1 = bitcast %option_float* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_float, %option_float* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @schmu___optiong.i_classify_optioni.i(%option_int* %thing) {
  entry:
    %tag1 = bitcast %option_int* %thing to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %thing, i32 0, i32 1
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ 0, %then ], [ 1, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str, align 8
    %option = alloca %option_int, align 8
    %tag9 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag9, align 4
    %data1 = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 3, i64* %data1, align 4
    %0 = call i64 @schmu___optiong.i_classify_optioni.i(%option_int* %option)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %0)
    %str2 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str2, align 8
    %option4 = alloca %option_float, align 8
    %tag510 = bitcast %option_float* %option4 to i32*
    store i32 0, i32* %tag510, align 4
    %data6 = getelementptr inbounds %option_float, %option_float* %option4, i32 0, i32 1
    store double 3.000000e+00, double* %data6, align 8
    %1 = call i64 @schmu___optiong.i_classify_optionf.i(%option_float* %option4)
    call void @printf(i8* getelementptr inbounds ({ i64, i64, i64, [4 x i8] }, { i64, i64, i64, [4 x i8] }* @0, i64 0, i32 3, i64 0), i64 %1)
    store i32 1, i32* getelementptr inbounds (%option_float, %option_float* @none, i32 0, i32 0), align 4
    %str7 = alloca i8*, align 8
    store i8* bitcast ({ i64, i64, i64, [4 x i8] }* @0 to i8*), i8** %str7, align 8
    %2 = call i64 @schmu___optiong.i_classify_optionf.i(%option_float* @none)
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
  
  @a = constant i64 12
  @b = global i64 0, align 8
  @vtest = global i64* null, align 8
  @vtest2 = global i64* null, align 8
  @llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @__malloc_some_init, i8* null }]
  @llvm.global_dtors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @__malloc_some_deinit, i8* null }]
  
  define i64 @schmu_add_ints(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  
  define internal void @__malloc_some_init() section ".text.startup" {
  entry:
    %0 = tail call i64 @schmu_add_ints(i64 1, i64 3)
    store i64 %0, i64* @b, align 4
    %1 = tail call i8* @malloc(i64 40)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** @vtest, align 8
    store i64 1, i64* %2, align 4
    %size = getelementptr i64, i64* %2, i64 1
    store i64 2, i64* %size, align 4
    %cap = getelementptr i64, i64* %2, i64 2
    store i64 2, i64* %cap, align 4
    %data = getelementptr i64, i64* %2, i64 3
    store i64 0, i64* %data, align 4
    %"1" = getelementptr i64, i64* %data, i64 1
    store i64 1, i64* %"1", align 4
    %3 = load i64*, i64** @vtest, align 8
    store i64* %3, i64** @vtest, align 8
    %4 = tail call i8* @malloc(i64 32)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** @vtest2, align 8
    store i64 1, i64* %5, align 4
    %size2 = getelementptr i64, i64* %5, i64 1
    store i64 1, i64* %size2, align 4
    %cap3 = getelementptr i64, i64* %5, i64 2
    store i64 1, i64* %cap3, align 4
    %data4 = getelementptr i64, i64* %5, i64 3
    store i64 3, i64* %data4, align 4
    %6 = load i64*, i64** @vtest2, align 8
    store i64* %6, i64** @vtest2, align 8
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__malloc_some_deinit() section ".text.startup" {
  entry:
    %0 = load i64*, i64** @vtest2, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %0)
    %1 = load i64*, i64** @vtest, align 8
    tail call void @__g.u_decr_rc_ai.u(i64* %1)
    ret void
  }
  
  define internal void @__g.u_decr_rc_ai.u(i64* %0) {
  entry:
    %ref2 = bitcast i64* %0 to i64*
    %ref1 = load i64, i64* %ref2, align 4
    %1 = icmp eq i64 %ref1, 1
    br i1 %1, label %free, label %decr
  
  decr:                                             ; preds = %entry
    %2 = bitcast i64* %0 to i64*
    %3 = sub i64 %ref1, 1
    store i64 %3, i64* %2, align 4
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
  ((5:Mtype(8:Tvariant()18:malloc_some/either(((5:cname4:left)(4:ctyp())(5:index1:4))((5:cname5:right)(4:ctyp())(5:index1:5)))))(4:Mfun(4:Tfun(((2:pt4:Tint)(4:pmut5:false))((2:pt4:Tint)(4:pmut5:false)))4:Tint6:Simple)8:add_ints)(4:Mext4:Tint1:a())(4:Mext4:Tint1:b())(9:Mpoly_fun((7:nparams(1:x))(4:body((3:typ(4:Qvar1:1))(4:expr(3:Var1:x))(4:attr((5:const5:false)(6:global5:false)(3:mut5:false)))(3:loc(((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol3:100)(8:pos_cnum3:112))((9:pos_fname15:malloc_some.smu)(8:pos_lnum1:9)(7:pos_bol3:100)(8:pos_cnum3:113))))))(4:func((7:tparams(((2:pt(4:Qvar1:1))(4:pmut5:false))))(3:ret(4:Qvar1:1))(4:kind6:Simple)))(6:inline5:false))2:id)(4:Mext(6:Tarray4:Tint)5:vtest())(4:Mext(6:Tarray4:Tint)6:vtest2()))

  $ schmu use_malloc_some.smu --dump-llvm && ./use_malloc_some
  use_malloc_some.smu:3:6: warning: Unused binding do_something
  3 | (fun do_something [big] (+ (.a big) 1))
           ^^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %closure = type { i8*, i8* }
  %big = type { i64, double, i64, i64 }
  
  @vtest = external global i64*
  @0 = private unnamed_addr global { i64, i64, i64, [4 x i8] } { i64 2, i64 3, i64 3, [4 x i8] c"%i\0A\00" }
  
  declare void @printf(i8* %0, i64 %1)
  
  define void @schmu___agg.u.u_array-iter_aii.u.u(i64* %arr, %closure* %f) {
  entry:
    %monoclstmp = alloca %closure, align 8
    %funptr5 = bitcast %closure* %monoclstmp to i8**
    store i8* bitcast (void (i64, i8*)* @schmu___i.u-ag-g.u_inner_i.u-ai-i.u to i8*), i8** %funptr5, align 8
    %clsr_monoclstmp = alloca { i64*, %closure* }, align 8
    %arr16 = bitcast { i64*, %closure* }* %clsr_monoclstmp to i64**
    store i64* %arr, i64** %arr16, align 8
    %f2 = getelementptr inbounds { i64*, %closure* }, { i64*, %closure* }* %clsr_monoclstmp, i32 0, i32 1
    store %closure* %f, %closure** %f2, align 8
    %env = bitcast { i64*, %closure* }* %clsr_monoclstmp to i8*
    %envptr = getelementptr inbounds %closure, %closure* %monoclstmp, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu___i.u-ag-g.u_inner_i.u-ai-i.u(i64 0, i8* %env)
    ret void
  }
  
  define void @schmu___i.u-ag-g.u_inner_i.u-ai-i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { i64*, %closure* }*
    %arr7 = bitcast { i64*, %closure* }* %clsr to i64**
    %arr1 = load i64*, i64** %arr7, align 8
    %f = getelementptr inbounds { i64*, %closure* }, { i64*, %closure* }* %clsr, i32 0, i32 1
    %f2 = load %closure*, %closure** %f, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %i3 = phi i64 [ %add, %else ], [ %i, %entry ]
    %len = getelementptr i64, i64* %arr1, i64 1
    %2 = load i64, i64* %len, align 4
    %eq = icmp eq i64 %i3, %2
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %sunkaddr = mul i64 %i3, 8
    %3 = bitcast i64* %arr1 to i8*
    %sunkaddr8 = getelementptr i8, i8* %3, i64 %sunkaddr
    %sunkaddr9 = getelementptr i8, i8* %sunkaddr8, i64 24
    %4 = bitcast i8* %sunkaddr9 to i64*
    %5 = load i64, i64* %4, align 4
    %funcptr10 = bitcast %closure* %f2 to i8**
    %loadtmp = load i8*, i8** %funcptr10, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f2, i32 0, i32 1
    %loadtmp4 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %5, i8* %loadtmp4)
    %add = add i64 %i3, 1
    store i64 %add, i64* %1, align 4
    br label %rec
  }
  
  define i64 @schmu_do_something(%big* %big) {
  entry:
    %0 = bitcast %big* %big to i64*
    %1 = load i64, i64* %0, align 4
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
  
  define i64 @main(i64 %arg) {
  entry:
    %0 = load i64*, i64** @vtest, align 8
    %clstmp = alloca %closure, align 8
    %funptr1 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @schmu_printi to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu___agg.u.u_array-iter_aii.u.u(i64* %0, %closure* %clstmp)
    ret i64 0
  }
  0
  1
