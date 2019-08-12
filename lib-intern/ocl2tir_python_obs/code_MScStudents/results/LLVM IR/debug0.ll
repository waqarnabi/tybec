; ModuleID = 'llvm_tmp.opt1.ll'
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.14.0"

; Function Attrs: nounwind ssp uwtable
define void @write_pipe(i8 signext %ch00, i32* %data0) #0 {
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @read_pipe(i8 signext %ch00, i32* %dataInt0) #0 {
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @get_pipe_num_packets(i32 %a) #0 {
  ret i32 %a
}

; Function Attrs: nounwind ssp uwtable
define void @kernelInput(i32 %aIn0, i32 %aIn1, i32 %ch00, i32 %ch01) #0 {
  %data0 = alloca i32, align 4
  %data1 = alloca i32, align 4
  store i32 %aIn0, i32* %data0, align 4
  store i32 %aIn1, i32* %data1, align 4
  %1 = trunc i32 %ch00 to i8
  call void @write_pipe(i8 signext %1, i32* %data0)
  %2 = trunc i32 %ch01 to i8
  call void @write_pipe(i8 signext %2, i32* %data1)
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @kernelCompute(i32 %ch00, i32 %ch01, i32 %ch1) #0 {
  %dataIn0 = alloca i32, align 4
  %dataIn1 = alloca i32, align 4
  %dataOut = alloca i32, align 4
  %1 = trunc i32 %ch00 to i8
  call void @read_pipe(i8 signext %1, i32* %dataIn0)
  %2 = trunc i32 %ch01 to i8
  call void @read_pipe(i8 signext %2, i32* %dataIn1)
  %3 = load i32, i32* %dataIn0, align 4
  %4 = load i32, i32* %dataIn1, align 4
  %5 = mul nsw i32 %3, %4
  %6 = load i32, i32* %dataIn1, align 4
  %7 = mul nsw i32 %5, %6
  store i32 %7, i32* %dataOut, align 4
  %8 = trunc i32 %ch1 to i8
  call void @write_pipe(i8 signext %8, i32* %dataOut)
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @kernelOutput(i32* %aOut, i32 %ch1) #0 {
  %data = alloca i32, align 4
  %1 = trunc i32 %ch1 to i8
  call void @read_pipe(i8 signext %1, i32* %data)
  %2 = load i32, i32* %data, align 4
  store i32 %2, i32* %aOut, align 4
  ret void
}

attributes #0 = { nounwind ssp uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+ssse3" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"PIC Level", i32 2}
!1 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
