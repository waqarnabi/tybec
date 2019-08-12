; ModuleID = 'llvm_ocl_stubs.c'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"tytra_linear_size(18)\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"./llvm_tmp_.cl\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [24 x i8] c"tytra_linear_size(1024)\00", section "llvm.metadata"
@llvm.global.annotations = appending global [2 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (float (float)* @fabs to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 8 }, { i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float, float, float, float, float, float, float*)* @shapiro to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 15 }], section "llvm.metadata"

; Function Attrs: nounwind uwtable
define void @write_pipe(i32 %ch00, i32* %data0) #0 {
entry:
  %ch00.addr = alloca i32, align 4
  %data0.addr = alloca i32*, align 8
  store i32 %ch00, i32* %ch00.addr, align 4
  store i32* %data0, i32** %data0.addr, align 8
  ret void
}

; Function Attrs: nounwind uwtable
define void @read_pipe(i32 %ch00, i32* %dataInt0) #0 {
entry:
  %ch00.addr = alloca i32, align 4
  %dataInt0.addr = alloca i32*, align 8
  store i32 %ch00, i32* %ch00.addr, align 4
  store i32* %dataInt0, i32** %dataInt0.addr, align 8
  ret void
}

; Function Attrs: nounwind uwtable
define i32 @get_pipe_num_packets(i32 %a) #0 {
entry:
  %a.addr = alloca i32, align 4
  store i32 %a, i32* %a.addr, align 4
  %0 = load i32, i32* %a.addr, align 4
  ret i32 %0
}

; Function Attrs: nounwind uwtable
define float @fabs(float %in) #0 {
entry:
  %retval = alloca float, align 4
  %in.addr = alloca float, align 4
  store float %in, float* %in.addr, align 4
  %0 = load float, float* %retval, align 4
  ret float %0
}

; Function Attrs: nounwind uwtable
define void @shapiro(float %eps, float %etan_j_k, float %etan_jm1_k, float %etan_j_km1, float %etan_j_kp1, float %etan_jp1_k, float %wet_j_k, float %wet_jm1_k, float %wet_j_km1, float %wet_j_kp1, float %wet_jp1_k, float* %eta_j_k) #0 {
entry:
  %eps.addr = alloca float, align 4
  %etan_j_k.addr = alloca float, align 4
  %etan_jm1_k.addr = alloca float, align 4
  %etan_j_km1.addr = alloca float, align 4
  %etan_j_kp1.addr = alloca float, align 4
  %etan_jp1_k.addr = alloca float, align 4
  %wet_j_k.addr = alloca float, align 4
  %wet_jm1_k.addr = alloca float, align 4
  %wet_j_km1.addr = alloca float, align 4
  %wet_j_kp1.addr = alloca float, align 4
  %wet_jp1_k.addr = alloca float, align 4
  %eta_j_k.addr = alloca float*, align 8
  %term1 = alloca float, align 4
  %term2 = alloca float, align 4
  %term3 = alloca float, align 4
  store float %eps, float* %eps.addr, align 4
  store float %etan_j_k, float* %etan_j_k.addr, align 4
  store float %etan_jm1_k, float* %etan_jm1_k.addr, align 4
  store float %etan_j_km1, float* %etan_j_km1.addr, align 4
  store float %etan_j_kp1, float* %etan_j_kp1.addr, align 4
  store float %etan_jp1_k, float* %etan_jp1_k.addr, align 4
  store float %wet_j_k, float* %wet_j_k.addr, align 4
  store float %wet_jm1_k, float* %wet_jm1_k.addr, align 4
  store float %wet_j_km1, float* %wet_j_km1.addr, align 4
  store float %wet_j_kp1, float* %wet_j_kp1.addr, align 4
  store float %wet_jp1_k, float* %wet_jp1_k.addr, align 4
  store float* %eta_j_k, float** %eta_j_k.addr, align 8
  %0 = load float, float* %eps.addr, align 4
  %mul = fmul float 2.500000e-01, %0
  %1 = load float, float* %wet_j_kp1.addr, align 4
  %2 = load float, float* %wet_j_km1.addr, align 4
  %add = fadd float %1, %2
  %3 = load float, float* %wet_jp1_k.addr, align 4
  %add1 = fadd float %add, %3
  %4 = load float, float* %wet_jm1_k.addr, align 4
  %add2 = fadd float %add1, %4
  %mul3 = fmul float %mul, %add2
  %sub = fsub float 1.000000e+00, %mul3
  %5 = load float, float* %etan_j_k.addr, align 4
  %mul4 = fmul float %sub, %5
  store float %mul4, float* %term1, align 4
  %6 = load float, float* %eps.addr, align 4
  %mul5 = fmul float 2.500000e-01, %6
  %7 = load float, float* %wet_j_kp1.addr, align 4
  %8 = load float, float* %etan_j_kp1.addr, align 4
  %mul6 = fmul float %7, %8
  %9 = load float, float* %wet_j_km1.addr, align 4
  %10 = load float, float* %etan_j_km1.addr, align 4
  %mul7 = fmul float %9, %10
  %add8 = fadd float %mul6, %mul7
  %mul9 = fmul float %mul5, %add8
  store float %mul9, float* %term2, align 4
  %11 = load float, float* %eps.addr, align 4
  %mul10 = fmul float 2.500000e-01, %11
  %12 = load float, float* %wet_jp1_k.addr, align 4
  %13 = load float, float* %etan_jp1_k.addr, align 4
  %mul11 = fmul float %12, %13
  %14 = load float, float* %wet_jm1_k.addr, align 4
  %15 = load float, float* %etan_jm1_k.addr, align 4
  %mul12 = fmul float %14, %15
  %add13 = fadd float %mul11, %mul12
  %mul14 = fmul float %mul10, %add13
  store float %mul14, float* %term3, align 4
  %16 = load float, float* %term1, align 4
  %17 = load float, float* %term2, align 4
  %add15 = fadd float %16, %17
  %18 = load float, float* %term3, align 4
  %add16 = fadd float %add15, %18
  %19 = load float*, float** %eta_j_k.addr, align 8
  store float %add16, float* %19, align 4
  ret void
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
