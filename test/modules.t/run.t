Simplest module with 1 type and 1 nonpolymorphic function
  $ schmu nonpoly_func.smu -m --dump-llvm
  nonpoly_func.smu:5:7: warning: Unused binding c
  5 |   val c = 10
            ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  @c = constant i64 10
  
  define i64 @schmu_add_ints(i64 %a, i64 %b) {
  entry:
    %add = add i64 %a, %b
    ret i64 %add
  }
  $ cat nonpoly_func.smi
  ((5:Mtype(8:Tvariant()6:either(((5:cname4:Left)(4:ctyp())(5:index1:0))((5:cname5:Right)(4:ctyp())(5:index1:1)))))(4:Mfun(4:Tfun(4:Tint4:Tint)4:Tint6:Simple)8:add_ints))

  $ schmu nonpoly_func.o open_nonpoly_func.smu --dump-llvm && ./open_nonpoly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  %either = type { i32 }
  
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare i64 @schmu_add_ints(i64 %0, i64 %1)
  
  declare void @printf(i8* %0, i64 %1)
  
  define i64 @schmu_do(i32 %0) {
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
    %str = alloca %string, align 8
    %cstr2 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr2, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %either = alloca %either, align 8
    %tag3 = bitcast %either* %either to i32*
    store i32 0, i32* %tag3, align 4
    %0 = tail call i64 @schmu_do(i32 0)
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    ret i64 0
  }
  5

  $ schmu nonpoly_func.o local_open_nonpoly_func.smu --dump-llvm && ./local_open_nonpoly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  %either = type { i32 }
  
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1)
  
  declare i64 @schmu_add_ints(i64 %0, i64 %1)
  
  define i64 @schmu_do(i32 %0) {
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
    %str = alloca %string, align 8
    %cstr2 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr2, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %either = alloca %either, align 8
    %tag3 = bitcast %either* %either to i32*
    store i32 0, i32* %tag3, align 4
    %0 = tail call i64 @schmu_do(i32 0)
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
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
  
  declare void @printf(i8* %0, i64 %1)
  
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

  $ schmu lets.o open_lets.smu --dump-llvm && ./open_lets
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @b = external global i64
  @a__2 = external global i64
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1)
  
  declare i64 @schmu_generate_b()
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca %string, align 8
    %cstr4 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr4, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %a__2 = load i64, i64* @a__2, align 4
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %a__2)
    %str1 = alloca %string, align 8
    %cstr25 = bitcast %string* %str1 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr25, align 8
    %length3 = getelementptr inbounds %string, %string* %str1, i32 0, i32 1
    store i64 3, i64* %length3, align 4
    %b = load i64, i64* @b, align 4
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %b)
    ret i64 0
  }
  11
  21

  $ cat lets.smi
  ((4:Mext4:Tint1:a())(4:Mext(4:Tfun((6:Talias4:cstr(4:Tptr3:Tu8))4:Tint)5:Tunit6:Simple)6:printf())(4:Mfun(4:Tfun()4:Tint6:Simple)10:generate_b)(4:Mext(4:Tvar(4:Link4:Tint))1:b())(4:Mext4:Tint1:a(4:a__2)))

  $ schmu lets.o local_open_lets.smu --dump-llvm && ./local_open_lets
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %string = type { i8*, i64 }
  
  @b = external global i64
  @a__2 = external global i64
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1)
  
  declare i64 @schmu_generate_b()
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca %string, align 8
    %cstr4 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr4, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %a__2 = load i64, i64* @a__2, align 4
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %a__2)
    %str1 = alloca %string, align 8
    %cstr25 = bitcast %string* %str1 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr25, align 8
    %length3 = getelementptr inbounds %string, %string* %str1, i32 0, i32 1
    store i64 3, i64* %length3, align 4
    %b = load i64, i64* @b, align 4
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %b)
    ret i64 0
  }
  11
  21

  $ schmu -m --dump-llvm poly_func.smu
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  $ cat poly_func.smi
  ((9:Mpoly_fun((7:nparams(5:thing))(4:body((3:typ4:Tint)(4:expr(3:Let7:__expr0()((3:typ(4:Tvar(4:Link(8:Tvariant((4:Tvar(4:Link(4:Tvar(7:Unbound2:481:2)))))6:option(((5:cname4:Some)(4:ctyp((4:Tvar(4:Link(4:Tvar(7:Unbound2:481:2))))))(5:index1:0))((5:cname4:None)(4:ctyp())(5:index1:1)))))))(4:expr(3:Var5:thing))(4:attr((5:const5:false)(6:global5:false))))((3:typ(4:Tvar(4:Link4:Tint)))(4:expr(2:If((3:typ5:Tbool)(4:expr(3:Bop7:Equal_i((3:typ4:Ti32)(4:expr(13:Variant_index((3:typ(8:Tvariant((4:Tvar(4:Link(4:Tvar(7:Unbound2:481:2)))))6:option(((5:cname4:Some)(4:ctyp((4:Tvar(4:Link(4:Tvar(7:Unbound2:481:2))))))(5:index1:0))((5:cname4:None)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false))))))(4:attr((5:const5:false)(6:global5:false))))((3:typ4:Ti32)(4:expr(5:Const(3:I321:0)))(4:attr((5:const4:true)(6:global5:false))))))(4:attr((5:const5:false)(6:global5:false))))((3:typ4:Tint)(4:expr(3:Let7:__expr0()((3:typ(4:Tvar(4:Link(4:Tvar(7:Unbound2:481:2)))))(4:expr(12:Variant_data((3:typ(8:Tvariant((4:Tvar(4:Link(4:Tvar(7:Unbound2:481:2)))))6:option(((5:cname4:Some)(4:ctyp((4:Tvar(4:Link(4:Tvar(7:Unbound2:481:2))))))(5:index1:0))((5:cname4:None)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false))))))(4:attr((5:const5:false)(6:global5:false))))((3:typ4:Tint)(4:expr(5:Const(3:Int1:0)))(4:attr((5:const4:true)(6:global5:false))))))(4:attr((5:const4:true)(6:global5:false))))((3:typ(4:Tvar(4:Link4:Tint)))(4:expr(3:Let7:__expr0()((3:typ(8:Tvariant((4:Tvar(7:Unbound2:481:2)))6:option(((5:cname4:Some)(4:ctyp((4:Tvar(7:Unbound2:481:2))))(5:index1:0))((5:cname4:None)(4:ctyp())(5:index1:1)))))(4:expr(3:Var7:__expr0))(4:attr((5:const5:false)(6:global5:false))))((3:typ4:Tint)(4:expr(5:Const(3:Int1:1)))(4:attr((5:const4:true)(6:global5:false))))))(4:attr((5:const5:false)(6:global5:false))))))(4:attr((5:const5:false)(6:global5:false))))))(4:attr((5:const5:false)(6:global5:false)))))(4:func((7:tparams((8:Tvariant((4:Qvar2:48))6:option(((5:cname4:Some)(4:ctyp((4:Qvar2:48)))(5:index1:0))((5:cname4:None)(4:ctyp())(5:index1:1))))))(3:ret4:Tint)(4:kind6:Simple))))8:classify))

  $ schmu poly_func.o open_poly_func.smu --dump-llvm && ./open_poly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_float = type { i32, double }
  %option_int = type { i32, i64 }
  %string = type { i8*, i64 }
  
  @none = global %option_float zeroinitializer, align 16
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
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
    %str = alloca %string, align 8
    %cstr10 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr10, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %option = alloca %option_int, align 8
    %tag11 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag11, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 3, i64* %data, align 4
    %0 = call i64 @schmu___optiong.i_classify_optioni.i(%option_int* %option)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    %str1 = alloca %string, align 8
    %cstr212 = bitcast %string* %str1 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr212, align 8
    %length3 = getelementptr inbounds %string, %string* %str1, i32 0, i32 1
    store i64 3, i64* %length3, align 4
    %option4 = alloca %option_float, align 8
    %tag513 = bitcast %option_float* %option4 to i32*
    store i32 0, i32* %tag513, align 4
    %data6 = getelementptr inbounds %option_float, %option_float* %option4, i32 0, i32 1
    store double 3.000000e+00, double* %data6, align 8
    %1 = call i64 @schmu___optiong.i_classify_optionf.i(%option_float* %option4)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %1)
    store i32 1, i32* getelementptr inbounds (%option_float, %option_float* @none, i32 0, i32 0), align 4
    %str7 = alloca %string, align 8
    %cstr814 = bitcast %string* %str7 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr814, align 8
    %length9 = getelementptr inbounds %string, %string* %str7, i32 0, i32 1
    store i64 3, i64* %length9, align 4
    %2 = call i64 @schmu___optiong.i_classify_optionf.i(%option_float* @none)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %2)
    ret i64 0
  }
  0
  0
  1

  $ schmu poly_func.o local_open_poly_func.smu --dump-llvm && ./local_open_poly_func
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_float = type { i32, double }
  %option_int = type { i32, i64 }
  %string = type { i8*, i64 }
  
  @none = global %option_float zeroinitializer, align 16
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
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
    %str = alloca %string, align 8
    %cstr10 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr10, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %option = alloca %option_int, align 8
    %tag11 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag11, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 3, i64* %data, align 4
    %0 = call i64 @schmu___optiong.i_classify_optioni.i(%option_int* %option)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    %str1 = alloca %string, align 8
    %cstr212 = bitcast %string* %str1 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr212, align 8
    %length3 = getelementptr inbounds %string, %string* %str1, i32 0, i32 1
    store i64 3, i64* %length3, align 4
    %option4 = alloca %option_float, align 8
    %tag513 = bitcast %option_float* %option4 to i32*
    store i32 0, i32* %tag513, align 4
    %data6 = getelementptr inbounds %option_float, %option_float* %option4, i32 0, i32 1
    store double 3.000000e+00, double* %data6, align 8
    %1 = call i64 @schmu___optiong.i_classify_optionf.i(%option_float* %option4)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %1)
    store i32 1, i32* getelementptr inbounds (%option_float, %option_float* @none, i32 0, i32 0), align 4
    %str7 = alloca %string, align 8
    %cstr814 = bitcast %string* %str7 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr814, align 8
    %length9 = getelementptr inbounds %string, %string* %str7, i32 0, i32 1
    store i64 3, i64* %length9, align 4
    %2 = call i64 @schmu___optiong.i_classify_optionf.i(%option_float* @none)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %2)
    ret i64 0
  }
  0
  0
  1

  $ schmu -m malloc_some.smu --dump-llvm
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { i64*, i64, i64 }
  
  @a = constant i64 12
  @b = global i64 0, align 8
  @vtest = global %vector_int zeroinitializer, align 16
  @vtest2 = global %vector_int zeroinitializer, align 16
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
    %1 = tail call i8* @malloc(i64 16)
    %2 = bitcast i8* %1 to i64*
    store i64* %2, i64** getelementptr inbounds (%vector_int, %vector_int* @vtest, i32 0, i32 0), align 8
    store i64 0, i64* %2, align 4
    %3 = getelementptr i64, i64* %2, i64 1
    store i64 1, i64* %3, align 4
    store i64 2, i64* getelementptr inbounds (%vector_int, %vector_int* @vtest, i32 0, i32 1), align 4
    store i64 2, i64* getelementptr inbounds (%vector_int, %vector_int* @vtest, i32 0, i32 2), align 4
    %4 = tail call i8* @malloc(i64 8)
    %5 = bitcast i8* %4 to i64*
    store i64* %5, i64** getelementptr inbounds (%vector_int, %vector_int* @vtest2, i32 0, i32 0), align 8
    store i64 3, i64* %5, align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @vtest2, i32 0, i32 1), align 4
    store i64 1, i64* getelementptr inbounds (%vector_int, %vector_int* @vtest2, i32 0, i32 2), align 4
    ret void
  }
  
  declare i8* @malloc(i64 %0)
  
  define internal void @__malloc_some_deinit() section ".text.startup" {
  entry:
    %0 = load i64*, i64** getelementptr inbounds (%vector_int, %vector_int* @vtest2, i32 0, i32 0), align 8
    %1 = bitcast i64* %0 to i8*
    tail call void @free(i8* %1)
    %2 = load i64*, i64** getelementptr inbounds (%vector_int, %vector_int* @vtest, i32 0, i32 0), align 8
    %3 = bitcast i64* %2 to i8*
    tail call void @free(i8* %3)
    ret void
  }
  
  declare void @free(i8* %0)
  $ schmu malloc_some.o use_malloc_some.smu --dump-llvm && ./use_malloc_some
  use_malloc_some.smu:3:5: warning: Unused binding do_something
  3 | fun do_something(big) = big.a + 1
          ^^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %vector_int = type { i64*, i64, i64 }
  %closure = type { i8*, i8* }
  %string = type { i8*, i64 }
  %big = type { i64, double, i64, i64 }
  
  @a = external global i64
  @b = external global i64
  @vtest = external global %vector_int
  @vtest2 = external global %vector_int
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1)
  
  declare i64 @schmu_add_ints(i64 %0, i64 %1)
  
  define void @schmu___vectorgg.u.u_vector_iter_vectorii.u.u(%vector_int* %vec, %closure* %f) {
  entry:
    %monoclstmp = alloca %closure, align 8
    %funptr5 = bitcast %closure* %monoclstmp to i8**
    store i8* bitcast (void (i64, i8*)* @schmu___i.u_inner_i.u to i8*), i8** %funptr5, align 8
    %clsr_monoclstmp = alloca { %closure*, %vector_int* }, align 8
    %f16 = bitcast { %closure*, %vector_int* }* %clsr_monoclstmp to %closure**
    store %closure* %f, %closure** %f16, align 8
    %vec2 = getelementptr inbounds { %closure*, %vector_int* }, { %closure*, %vector_int* }* %clsr_monoclstmp, i32 0, i32 1
    store %vector_int* %vec, %vector_int** %vec2, align 8
    %env = bitcast { %closure*, %vector_int* }* %clsr_monoclstmp to i8*
    %envptr = getelementptr inbounds %closure, %closure* %monoclstmp, i32 0, i32 1
    store i8* %env, i8** %envptr, align 8
    call void @schmu___i.u_inner_i.u(i64 0, i8* %env)
    ret void
  }
  
  define void @schmu___i.u_inner_i.u(i64 %i, i8* %0) {
  entry:
    %clsr = bitcast i8* %0 to { %closure*, %vector_int* }*
    %f6 = bitcast { %closure*, %vector_int* }* %clsr to %closure**
    %f1 = load %closure*, %closure** %f6, align 8
    %vec = getelementptr inbounds { %closure*, %vector_int* }, { %closure*, %vector_int* }* %clsr, i32 0, i32 1
    %vec2 = load %vector_int*, %vector_int** %vec, align 8
    %1 = alloca i64, align 8
    store i64 %i, i64* %1, align 4
    br label %rec
  
  rec:                                              ; preds = %else, %entry
    %i3 = phi i64 [ %add, %else ], [ %i, %entry ]
    %2 = getelementptr inbounds %vector_int, %vector_int* %vec2, i32 0, i32 1
    %3 = load i64, i64* %2, align 4
    %eq = icmp eq i64 %i3, %3
    br i1 %eq, label %then, label %else
  
  then:                                             ; preds = %rec
    ret void
  
  else:                                             ; preds = %rec
    %4 = bitcast %vector_int* %vec2 to i64**
    %5 = load i64*, i64** %4, align 8
    %scevgep = getelementptr i64, i64* %5, i64 %i3
    %6 = load i64, i64* %scevgep, align 4
    %funcptr7 = bitcast %closure* %f1 to i8**
    %loadtmp = load i8*, i8** %funcptr7, align 8
    %casttmp = bitcast i8* %loadtmp to void (i64, i8*)*
    %envptr = getelementptr inbounds %closure, %closure* %f1, i32 0, i32 1
    %loadtmp4 = load i8*, i8** %envptr, align 8
    tail call void %casttmp(i64 %6, i8* %loadtmp4)
    %add = add i64 %i3, 1
    store i64 %add, i64* %1, align 4
    br label %rec
  }
  
  define void @schmu_printi(i64 %i) {
  entry:
    %str = alloca %string, align 8
    %cstr1 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr1, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    tail call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %i)
    ret void
  }
  
  define i64 @schmu_do_something(%big* %big) {
  entry:
    %0 = bitcast %big* %big to i64*
    %1 = load i64, i64* %0, align 4
    %add = add i64 %1, 1
    ret i64 %add
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %clstmp = alloca %closure, align 8
    %funptr1 = bitcast %closure* %clstmp to i8**
    store i8* bitcast (void (i64)* @schmu_printi to i8*), i8** %funptr1, align 8
    %envptr = getelementptr inbounds %closure, %closure* %clstmp, i32 0, i32 1
    store i8* null, i8** %envptr, align 8
    call void @schmu___vectorgg.u.u_vector_iter_vectorii.u.u(%vector_int* @vtest, %closure* %clstmp)
    ret i64 0
  }
  0
  1
