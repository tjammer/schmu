Basic variant ctors
  $ schmu basic.smu --dump-llvm
  basic.smu:15:5: warning: Unused binding wrap_clike
  15 | fun wrap_clike()
           ^^^^^^^^^^
  
  basic.smu:19:5: warning: Unused binding wrap_option
  19 | fun wrap_option()
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
    store i32 1, i32* %tag1, align 4
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
    store i32 1, i32* %tag5, align 4
    %data = getelementptr inbounds %option_int, %option_int* %option, i32 0, i32 1
    store i64 1, i64* %data, align 4
    %larger = alloca %larger, align 8
    %tag16 = bitcast %larger* %larger to i32*
    store i32 2, i32* %tag16, align 4
    %data2 = getelementptr inbounds %larger, %larger* %larger, i32 0, i32 1
    %data3 = bitcast %foo* %data2 to i64*
    store i64 3, i64* %data3, align 4
    %clike = alloca %clike, align 8
    %tag47 = bitcast %clike* %clike to i32*
    store i32 2, i32* %tag47, align 4
    ret i64 0
  }
