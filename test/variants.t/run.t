Basic variant ctors
  $ schmu basic.smu --dump-llvm
  basic.smu:12:5: warning: Unused binding wrap_clike
  12 | fun wrap_clike() = C
           ^^^^^^^^^^
  
  basic.smu:14:5: warning: Unused binding wrap_option
  14 | fun wrap_option() = Some("hello")
           ^^^^^^^^^^^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_string = type { i32, %string }
  %string = type { i8*, i64 }
  %clike = type { i32 }
  %option_int = type { i32, i64 }
  %larger = type { i32, %foo }
  %foo = type { double, double }
  
  @0 = private unnamed_addr constant [6 x i8] c"hello\00", align 1
  
  define private void @wrap_option(%option_string* %0) {
  entry:
    %tag1 = bitcast %option_string* %0 to i32*
    store i32 0, i32* %tag1, align 4
    %data = getelementptr inbounds %option_string, %option_string* %0, i32 0, i32 1
    %cstr2 = bitcast %string* %data to i8**
    store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @0, i32 0, i32 0), i8** %cstr2, align 8
    %length = getelementptr inbounds %string, %string* %data, i32 0, i32 1
    store i64 5, i64* %length, align 4
    ret void
  }
  
  define private i32 @wrap_clike() {
  entry:
    %clike = alloca %clike, align 8
    %tag2 = bitcast %clike* %clike to i32*
    store i32 2, i32* %tag2, align 4
    ret i32 2
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %option = alloca %option_int, align 8
    %tag5 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag5, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 4
    %larger = alloca %larger, align 8
    %tag16 = bitcast %larger* %larger to i32*
    store i32 2, i32* %tag16, align 4
    %data2 = getelementptr inbounds %larger, %larger* %larger, i32 0, i32 1
    %0 = bitcast %foo* %data2 to i64*
    store i64 3, i64* %0, align 4
    %clike = alloca %clike, align 8
    %tag47 = bitcast %clike* %clike to i32*
    store i32 2, i32* %tag47, align 4
    ret i64 0
  }

Basic pattern matching
  $ schmu match_option.smu --dump-llvm -o out.o && cc out.o && ./a.out
  match_option.smu:22:3: warning: Unused binding a
  22 |   a -> 0
         ^
  
  match_option.smu:29:3: warning: Unused binding a
  29 |   a -> 1
         ^
  
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_int = type { i32, i64 }
  %string = type { i8*, i64 }
  
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @1 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @2 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @3 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @4 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @5 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @6 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @7 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1)
  
  define private i64 @none_all(%option_int* %p) {
  entry:
    %tag1 = bitcast %option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define private i64 @some_all(%option_int* %p) {
  entry:
    %tag1 = bitcast %option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define private i64 @opt_match(%option_int* %p) {
  entry:
    %tag1 = bitcast %option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 1
    br i1 %eq, label %ifcont, label %else
  
  else:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %else
    %iftmp = phi i64 [ %0, %else ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define private i64 @match_opt(%option_int* %p) {
  entry:
    %tag1 = bitcast %option_int* %p to i32*
    %index = load i32, i32* %tag1, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_int, %option_int* %p, i32 0, i32 1
    %0 = load i64, i64* %data, align 4
    br label %ifcont
  
  ifcont:                                           ; preds = %entry, %then
    %iftmp = phi i64 [ %0, %then ], [ 0, %entry ]
    ret i64 %iftmp
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca %string, align 8
    %cstr39 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr39, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %option = alloca %option_int, align 8
    %tag40 = bitcast %option_int* %option to i32*
    store i32 0, i32* %tag40, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 4
    %0 = call i64 @match_opt(%option_int* %option)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    %str1 = alloca %string, align 8
    %cstr241 = bitcast %string* %str1 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i8** %cstr241, align 8
    %length3 = getelementptr inbounds %string, %string* %str1, i32 0, i32 1
    store i64 3, i64* %length3, align 4
    %option4 = alloca %option_int, align 8
    %tag542 = bitcast %option_int* %option4 to i32*
    store i32 1, i32* %tag542, align 4
    %1 = call i64 @match_opt(%option_int* %option4)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %1)
    %str6 = alloca %string, align 8
    %cstr743 = bitcast %string* %str6 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @2, i32 0, i32 0), i8** %cstr743, align 8
    %length8 = getelementptr inbounds %string, %string* %str6, i32 0, i32 1
    store i64 3, i64* %length8, align 4
    %option9 = alloca %option_int, align 8
    %tag1044 = bitcast %option_int* %option9 to i32*
    store i32 0, i32* %tag1044, align 4
    %data11 = getelementptr inbounds %option_int, %option_int* %option9, i32 0, i32 1
    store i64 1, i64* %data11, align 4
    %2 = call i64 @opt_match(%option_int* %option9)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @2, i32 0, i32 0), i64 %2)
    %str12 = alloca %string, align 8
    %cstr1345 = bitcast %string* %str12 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr1345, align 8
    %length14 = getelementptr inbounds %string, %string* %str12, i32 0, i32 1
    store i64 3, i64* %length14, align 4
    %option15 = alloca %option_int, align 8
    %tag1646 = bitcast %option_int* %option15 to i32*
    store i32 1, i32* %tag1646, align 4
    %3 = call i64 @opt_match(%option_int* %option15)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %3)
    %str17 = alloca %string, align 8
    %cstr1847 = bitcast %string* %str17 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @4, i32 0, i32 0), i8** %cstr1847, align 8
    %length19 = getelementptr inbounds %string, %string* %str17, i32 0, i32 1
    store i64 3, i64* %length19, align 4
    %option20 = alloca %option_int, align 8
    %tag2148 = bitcast %option_int* %option20 to i32*
    store i32 0, i32* %tag2148, align 4
    %data22 = getelementptr inbounds %option_int, %option_int* %option20, i32 0, i32 1
    store i64 1, i64* %data22, align 4
    %4 = call i64 @some_all(%option_int* %option20)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @4, i32 0, i32 0), i64 %4)
    %str23 = alloca %string, align 8
    %cstr2449 = bitcast %string* %str23 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @5, i32 0, i32 0), i8** %cstr2449, align 8
    %length25 = getelementptr inbounds %string, %string* %str23, i32 0, i32 1
    store i64 3, i64* %length25, align 4
    %option26 = alloca %option_int, align 8
    %tag2750 = bitcast %option_int* %option26 to i32*
    store i32 1, i32* %tag2750, align 4
    %5 = call i64 @some_all(%option_int* %option26)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @5, i32 0, i32 0), i64 %5)
    %str28 = alloca %string, align 8
    %cstr2951 = bitcast %string* %str28 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @6, i32 0, i32 0), i8** %cstr2951, align 8
    %length30 = getelementptr inbounds %string, %string* %str28, i32 0, i32 1
    store i64 3, i64* %length30, align 4
    %option31 = alloca %option_int, align 8
    %tag3252 = bitcast %option_int* %option31 to i32*
    store i32 0, i32* %tag3252, align 4
    %data33 = getelementptr inbounds %option_int, %option_int* %option31, i32 0, i32 1
    store i64 1, i64* %data33, align 4
    %6 = call i64 @none_all(%option_int* %option31)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @6, i32 0, i32 0), i64 %6)
    %str34 = alloca %string, align 8
    %cstr3553 = bitcast %string* %str34 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @7, i32 0, i32 0), i8** %cstr3553, align 8
    %length36 = getelementptr inbounds %string, %string* %str34, i32 0, i32 1
    store i64 3, i64* %length36, align 4
    %option37 = alloca %option_int, align 8
    %tag3854 = bitcast %option_int* %option37 to i32*
    store i32 1, i32* %tag3854, align 4
    %7 = call i64 @none_all(%option_int* %option37)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @7, i32 0, i32 0), i64 %7)
    ret i64 0
  }
  1
  0
  1
  0
  1
  0
  1
  0

Nested pattern matching
  $ schmu match_nested.smu --dump-llvm -o out.o && cc out.o && ./a.out
  ; ModuleID = 'context'
  source_filename = "context"
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
  
  %option_test = type { i32, %test }
  %test = type { i32, double }
  %string = type { i8*, i64 }
  
  @0 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @1 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @2 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  @3 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
  
  declare void @printf(i8* %0, i64 %1)
  
  define private i64 @do(%option_test* %m) {
  entry:
    %tag17 = bitcast %option_test* %m to i32*
    %index = load i32, i32* %tag17, align 4
    %eq = icmp eq i32 %index, 0
    br i1 %eq, label %then, label %ifcont15
  
  then:                                             ; preds = %entry
    %data = getelementptr inbounds %option_test, %option_test* %m, i32 0, i32 1
    %tag118 = bitcast %test* %data to i32*
    %index2 = load i32, i32* %tag118, align 4
    %eq3 = icmp eq i32 %index2, 0
    br i1 %eq3, label %then4, label %else
  
  then4:                                            ; preds = %then
    %0 = bitcast %option_test* %m to i8*
    %sunkaddr = getelementptr inbounds i8, i8* %0, i64 16
    %1 = bitcast i8* %sunkaddr to double*
    %2 = load double, double* %1, align 8
    %3 = fptosi double %2 to i64
    br label %ifcont15
  
  else:                                             ; preds = %then
    %eq8 = icmp eq i32 %index2, 1
    br i1 %eq8, label %then9, label %ifcont15
  
  then9:                                            ; preds = %else
    %4 = bitcast %option_test* %m to i8*
    %sunkaddr19 = getelementptr inbounds i8, i8* %4, i64 16
    %5 = bitcast i8* %sunkaddr19 to i64*
    %6 = load i64, i64* %5, align 4
    br label %ifcont15
  
  ifcont15:                                         ; preds = %entry, %then4, %else, %then9
    %iftmp16 = phi i64 [ %3, %then4 ], [ %6, %then9 ], [ 1, %else ], [ 0, %entry ]
    ret i64 %iftmp16
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %str = alloca %string, align 8
    %cstr24 = bitcast %string* %str to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i8** %cstr24, align 8
    %length = getelementptr inbounds %string, %string* %str, i32 0, i32 1
    store i64 3, i64* %length, align 4
    %option = alloca %option_test, align 8
    %tag25 = bitcast %option_test* %option to i32*
    store i32 0, i32* %tag25, align 4
    %data = getelementptr inbounds %option_test, %option_test* %option, i32 0, i32 1
    %tag126 = bitcast %test* %data to i32*
    store i32 0, i32* %tag126, align 4
    %data2 = getelementptr inbounds %test, %test* %data, i32 0, i32 1
    store double 3.000000e+00, double* %data2, align 8
    %0 = call i64 @do(%option_test* %option)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @0, i32 0, i32 0), i64 %0)
    %str3 = alloca %string, align 8
    %cstr427 = bitcast %string* %str3 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i8** %cstr427, align 8
    %length5 = getelementptr inbounds %string, %string* %str3, i32 0, i32 1
    store i64 3, i64* %length5, align 4
    %option6 = alloca %option_test, align 8
    %tag728 = bitcast %option_test* %option6 to i32*
    store i32 0, i32* %tag728, align 4
    %data8 = getelementptr inbounds %option_test, %option_test* %option6, i32 0, i32 1
    %tag929 = bitcast %test* %data8 to i32*
    store i32 1, i32* %tag929, align 4
    %data10 = getelementptr inbounds %test, %test* %data8, i32 0, i32 1
    %1 = bitcast double* %data10 to i64*
    store i64 2, i64* %1, align 4
    %2 = call i64 @do(%option_test* %option6)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @1, i32 0, i32 0), i64 %2)
    %str12 = alloca %string, align 8
    %cstr1330 = bitcast %string* %str12 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @2, i32 0, i32 0), i8** %cstr1330, align 8
    %length14 = getelementptr inbounds %string, %string* %str12, i32 0, i32 1
    store i64 3, i64* %length14, align 4
    %option15 = alloca %option_test, align 8
    %tag1631 = bitcast %option_test* %option15 to i32*
    store i32 0, i32* %tag1631, align 4
    %data17 = getelementptr inbounds %option_test, %option_test* %option15, i32 0, i32 1
    %tag1832 = bitcast %test* %data17 to i32*
    store i32 2, i32* %tag1832, align 4
    %3 = call i64 @do(%option_test* %option15)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @2, i32 0, i32 0), i64 %3)
    %str19 = alloca %string, align 8
    %cstr2033 = bitcast %string* %str19 to i8**
    store i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i8** %cstr2033, align 8
    %length21 = getelementptr inbounds %string, %string* %str19, i32 0, i32 1
    store i64 3, i64* %length21, align 4
    %option22 = alloca %option_test, align 8
    %tag2334 = bitcast %option_test* %option22 to i32*
    store i32 1, i32* %tag2334, align 4
    %4 = call i64 @do(%option_test* %option22)
    call void @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @3, i32 0, i32 0), i64 %4)
    ret i64 0
  }
  3
  2
  1
  0
