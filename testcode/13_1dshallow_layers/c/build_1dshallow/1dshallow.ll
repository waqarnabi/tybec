; ModuleID = '1dshallow.unopt.ll'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [24 x i8] c"tytra_linear_size(1024)\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"./llvm_tmp_.cl\00", section "llvm.metadata"
@llvm.global.annotations = appending global [1 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float*)* @oned_shallow to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 13 }], section "llvm.metadata"

; Function Attrs: nounwind uwtable
define void @write_pipe(i32 %ch00, i32* %data0) #0 {
entry:
  ret void
}

; Function Attrs: nounwind uwtable
define void @read_pipe(i32 %ch00, i32* %dataInt0) #0 {
entry:
  ret void
}

; Function Attrs: nounwind uwtable
define i32 @get_pipe_num_packets(i32 %a) #0 {
entry:
  ret i32 %a
}

; Function Attrs: nounwind uwtable
define void @oned_shallow(float %time, float* %eta) #0 {
entry:
  %mul = fmul float 0x40191EB860000000, %time
  %div = fdiv float %mul, 0x3FB99999A0000000
  %conv = fpext float %div to double
  %call = call double @sin(double %conv) #2
  %mul1 = fmul double 0x3FB99999A0000000, %call
  %conv2 = fptrunc double %mul1 to float
  store float %conv2, float* %eta, align 4
  ret void
}

; Function Attrs: nounwind
declare double @sin(double) #1

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
