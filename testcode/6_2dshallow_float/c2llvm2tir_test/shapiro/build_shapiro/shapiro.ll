; ModuleID = 'shapiro.unopt.ll'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"tytra_linear_size(18)\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"./llvm_tmp_.cl\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [24 x i8] c"tytra_linear_size(1024)\00", section "llvm.metadata"
@llvm.global.annotations = appending global [2 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (float (float)* @fabs to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 8 }, { i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float, float, float, float, float, float, float*)* @shapiro to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 15 }], section "llvm.metadata"

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
define float @fabs(float %in) #0 {
entry:
  ret float undef
}

; Function Attrs: nounwind uwtable
define void @shapiro(float %eps, float %etan_j_k, float %etan_jm1_k, float %etan_j_km1, float %etan_j_kp1, float %etan_jp1_k, float %wet_j_k, float %wet_jm1_k, float %wet_j_km1, float %wet_j_kp1, float %wet_jp1_k, float* %eta_j_k) #0 {
entry:
  %mul = fmul float 2.500000e-01, %eps
  %add = fadd float %wet_j_kp1, %wet_j_km1
  %add1 = fadd float %add, %wet_jp1_k
  %add2 = fadd float %add1, %wet_jm1_k
  %mul3 = fmul float %mul, %add2
  %sub = fsub float 1.000000e+00, %mul3
  %mul4 = fmul float %sub, %etan_j_k
  %mul5 = fmul float 2.500000e-01, %eps
  %mul6 = fmul float %wet_j_kp1, %etan_j_kp1
  %mul7 = fmul float %wet_j_km1, %etan_j_km1
  %add8 = fadd float %mul6, %mul7
  %mul9 = fmul float %mul5, %add8
  %mul10 = fmul float 2.500000e-01, %eps
  %mul11 = fmul float %wet_jp1_k, %etan_jp1_k
  %mul12 = fmul float %wet_jm1_k, %etan_jm1_k
  %add13 = fadd float %mul11, %mul12
  %mul14 = fmul float %mul10, %add13
  %add15 = fadd float %mul4, %mul9
  %add16 = fadd float %add15, %mul14
  store float %add16, float* %eta_j_k, align 4
  ret void
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
