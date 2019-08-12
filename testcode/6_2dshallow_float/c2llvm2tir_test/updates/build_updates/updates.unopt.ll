; ModuleID = 'llvm_ocl_stubs.c'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"tytra_linear_size(18)\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"./llvm_tmp_.cl\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [24 x i8] c"tytra_linear_size(1024)\00", section "llvm.metadata"
@llvm.global.annotations = appending global [2 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (float (float)* @fabs to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 8 }, { i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float*, float*, float*, float*)* @shapiro to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 15 }], section "llvm.metadata"

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
define void @shapiro(float %hmin, float %un_j_k, float %vn_j_k, float %hzero_j_k, float %eta_j_k, float* %u_j_k, float* %v_j_k, float* %h_j_k, float* %wet_j_k) #0 {
entry:
  %hmin.addr = alloca float, align 4
  %un_j_k.addr = alloca float, align 4
  %vn_j_k.addr = alloca float, align 4
  %hzero_j_k.addr = alloca float, align 4
  %eta_j_k.addr = alloca float, align 4
  %u_j_k.addr = alloca float*, align 8
  %v_j_k.addr = alloca float*, align 8
  %h_j_k.addr = alloca float*, align 8
  %wet_j_k.addr = alloca float*, align 8
  store float %hmin, float* %hmin.addr, align 4
  store float %un_j_k, float* %un_j_k.addr, align 4
  store float %vn_j_k, float* %vn_j_k.addr, align 4
  store float %hzero_j_k, float* %hzero_j_k.addr, align 4
  store float %eta_j_k, float* %eta_j_k.addr, align 4
  store float* %u_j_k, float** %u_j_k.addr, align 8
  store float* %v_j_k, float** %v_j_k.addr, align 8
  store float* %h_j_k, float** %h_j_k.addr, align 8
  store float* %wet_j_k, float** %wet_j_k.addr, align 8
  %0 = load float, float* %hzero_j_k.addr, align 4
  %1 = load float, float* %eta_j_k.addr, align 4
  %add = fadd float %0, %1
  %2 = load float*, float** %h_j_k.addr, align 8
  store float %add, float* %2, align 4
  %3 = load float*, float** %wet_j_k.addr, align 8
  store float 1.000000e+00, float* %3, align 4
  %4 = load float, float* %un_j_k.addr, align 4
  %5 = load float*, float** %u_j_k.addr, align 8
  store float %4, float* %5, align 4
  %6 = load float, float* %vn_j_k.addr, align 4
  %7 = load float*, float** %v_j_k.addr, align 8
  store float %6, float* %7, align 4
  ret void
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
