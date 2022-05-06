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
  
  %option_float = type { i32, double }
  %clike = type { i32 }
  %option_int = type { i32, i64 }
  %larger = type { i32, %foo }
  %foo = type { double, double }
  
  define private %option_float* @wrap_option() {
  entry:
    %todo = alloca %option_float, align 8
    %tag1 = bitcast %option_float* %todo to i32*
    store i32 1, i32* %tag1, align 4
    %data = getelementptr inbounds %option_float, %option_float* %todo, i32 0, i32 1
    store double 3.140000e+00, double* %data, align 8
    ret %option_float* %todo
  }
  
  define private %clike* @wrap_clike() {
  entry:
    %todo = alloca %clike, align 8
    %tag1 = bitcast %clike* %todo to i32*
    store i32 2, i32* %tag1, align 4
    ret %clike* %todo
  }
  
  define i64 @main(i64 %arg) {
  entry:
    %todo = alloca %option_int, align 8
    %tag7 = bitcast %option_int* %todo to i32*
    store i32 1, i32* %tag7, align 4
    %data = getelementptr inbounds %option_int, %option_int* %todo, i32 0, i32 1
    store i64 1, i64* %data, align 4
    %todo1 = alloca %larger, align 8
    %tag28 = bitcast %larger* %todo1 to i32*
    store i32 2, i32* %tag28, align 4
    %data3 = getelementptr inbounds %larger, %larger* %todo1, i32 0, i32 1
    %data4 = bitcast %foo* %data3 to i64*
    store i64 3, i64* %data4, align 4
    %todo5 = alloca %clike, align 8
    %tag69 = bitcast %clike* %todo5 to i32*
    store i32 2, i32* %tag69, align 4
    ret i64 0
  }
