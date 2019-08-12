; ModuleID = 'llvm_ocl_stubs.c'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"tytra_linear_size(18)\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"./llvm_tmp_.cl\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [24 x i8] c"tytra_linear_size(1024)\00", section "llvm.metadata"
@llvm.global.annotations = appending global [2 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (float (float)* @fabs to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 8 }, { i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float*)* @dyn2 to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 15 }], section "llvm.metadata"

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
define void @dyn2(float %dt, float %dx, float %dy, float %un_j_k, float %un_j_km1, float %vn_j_k, float %vn_jm1_k, float %h_j_k, float %h_jm1_k, float %h_j_km1, float %h_j_kp1, float %h_jp1_k, float %eta_j_k, float %j, float %k, float* %etan_j_k) #0 {
entry:
  %dt.addr = alloca float, align 4
  %dx.addr = alloca float, align 4
  %dy.addr = alloca float, align 4
  %un_j_k.addr = alloca float, align 4
  %un_j_km1.addr = alloca float, align 4
  %vn_j_k.addr = alloca float, align 4
  %vn_jm1_k.addr = alloca float, align 4
  %h_j_k.addr = alloca float, align 4
  %h_jm1_k.addr = alloca float, align 4
  %h_j_km1.addr = alloca float, align 4
  %h_j_kp1.addr = alloca float, align 4
  %h_jp1_k.addr = alloca float, align 4
  %eta_j_k.addr = alloca float, align 4
  %j.addr = alloca float, align 4
  %k.addr = alloca float, align 4
  %etan_j_k.addr = alloca float*, align 8
  %hue = alloca float, align 4
  %huw = alloca float, align 4
  %hwp = alloca float, align 4
  %hwn = alloca float, align 4
  %hen = alloca float, align 4
  %hep = alloca float, align 4
  %hvn = alloca float, align 4
  %hvs = alloca float, align 4
  %hsp = alloca float, align 4
  %hsn = alloca float, align 4
  %hnn = alloca float, align 4
  %hnp = alloca float, align 4
  store float %dt, float* %dt.addr, align 4
  store float %dx, float* %dx.addr, align 4
  store float %dy, float* %dy.addr, align 4
  store float %un_j_k, float* %un_j_k.addr, align 4
  store float %un_j_km1, float* %un_j_km1.addr, align 4
  store float %vn_j_k, float* %vn_j_k.addr, align 4
  store float %vn_jm1_k, float* %vn_jm1_k.addr, align 4
  store float %h_j_k, float* %h_j_k.addr, align 4
  store float %h_jm1_k, float* %h_jm1_k.addr, align 4
  store float %h_j_km1, float* %h_j_km1.addr, align 4
  store float %h_j_kp1, float* %h_j_kp1.addr, align 4
  store float %h_jp1_k, float* %h_jp1_k.addr, align 4
  store float %eta_j_k, float* %eta_j_k.addr, align 4
  store float %j, float* %j.addr, align 4
  store float %k, float* %k.addr, align 4
  store float* %etan_j_k, float** %etan_j_k.addr, align 8
  %0 = load float, float* %un_j_k.addr, align 4
  %1 = load float, float* %un_j_k.addr, align 4
  %call = call float @fabs(float %1)
  %add = fadd float %0, %call
  %mul = fmul float 5.000000e-01, %add
  %2 = load float, float* %h_j_k.addr, align 4
  %mul1 = fmul float %mul, %2
  store float %mul1, float* %hep, align 4
  %3 = load float, float* %un_j_k.addr, align 4
  %4 = load float, float* %un_j_k.addr, align 4
  %call2 = call float @fabs(float %4)
  %sub = fsub float %3, %call2
  %mul3 = fmul float 5.000000e-01, %sub
  %5 = load float, float* %h_j_kp1.addr, align 4
  %mul4 = fmul float %mul3, %5
  store float %mul4, float* %hen, align 4
  %6 = load float, float* %hep, align 4
  %7 = load float, float* %hen, align 4
  %add5 = fadd float %6, %7
  store float %add5, float* %hue, align 4
  %8 = load float, float* %un_j_km1.addr, align 4
  %9 = load float, float* %un_j_km1.addr, align 4
  %call6 = call float @fabs(float %9)
  %add7 = fadd float %8, %call6
  %mul8 = fmul float 5.000000e-01, %add7
  %10 = load float, float* %h_j_km1.addr, align 4
  %mul9 = fmul float %mul8, %10
  store float %mul9, float* %hwp, align 4
  %11 = load float, float* %un_j_km1.addr, align 4
  %12 = load float, float* %un_j_km1.addr, align 4
  %call10 = call float @fabs(float %12)
  %sub11 = fsub float %11, %call10
  %mul12 = fmul float 5.000000e-01, %sub11
  %13 = load float, float* %h_j_k.addr, align 4
  %mul13 = fmul float %mul12, %13
  store float %mul13, float* %hwn, align 4
  %14 = load float, float* %hwp, align 4
  %15 = load float, float* %hwn, align 4
  %add14 = fadd float %14, %15
  store float %add14, float* %huw, align 4
  %16 = load float, float* %vn_j_k.addr, align 4
  %17 = load float, float* %vn_j_k.addr, align 4
  %call15 = call float @fabs(float %17)
  %add16 = fadd float %16, %call15
  %mul17 = fmul float 5.000000e-01, %add16
  %18 = load float, float* %h_j_k.addr, align 4
  %mul18 = fmul float %mul17, %18
  store float %mul18, float* %hnp, align 4
  %19 = load float, float* %vn_j_k.addr, align 4
  %20 = load float, float* %vn_j_k.addr, align 4
  %call19 = call float @fabs(float %20)
  %sub20 = fsub float %19, %call19
  %mul21 = fmul float 5.000000e-01, %sub20
  %21 = load float, float* %h_jp1_k.addr, align 4
  %mul22 = fmul float %mul21, %21
  store float %mul22, float* %hnn, align 4
  %22 = load float, float* %hnp, align 4
  %23 = load float, float* %hnn, align 4
  %add23 = fadd float %22, %23
  store float %add23, float* %hvn, align 4
  %24 = load float, float* %vn_jm1_k.addr, align 4
  %25 = load float, float* %vn_jm1_k.addr, align 4
  %call24 = call float @fabs(float %25)
  %add25 = fadd float %24, %call24
  %mul26 = fmul float 5.000000e-01, %add25
  %26 = load float, float* %h_jm1_k.addr, align 4
  %mul27 = fmul float %mul26, %26
  store float %mul27, float* %hsp, align 4
  %27 = load float, float* %vn_jm1_k.addr, align 4
  %28 = load float, float* %vn_jm1_k.addr, align 4
  %call28 = call float @fabs(float %28)
  %sub29 = fsub float %27, %call28
  %mul30 = fmul float 5.000000e-01, %sub29
  %29 = load float, float* %h_j_k.addr, align 4
  %mul31 = fmul float %mul30, %29
  store float %mul31, float* %hsn, align 4
  %30 = load float, float* %hsp, align 4
  %31 = load float, float* %hsn, align 4
  %add32 = fadd float %30, %31
  store float %add32, float* %hvs, align 4
  %32 = load float, float* %eta_j_k.addr, align 4
  %33 = load float, float* %dt.addr, align 4
  %34 = load float, float* %hue, align 4
  %35 = load float, float* %huw, align 4
  %sub33 = fsub float %34, %35
  %mul34 = fmul float %33, %sub33
  %36 = load float, float* %dx.addr, align 4
  %div = fdiv float %mul34, %36
  %sub35 = fsub float %32, %div
  %37 = load float, float* %dt.addr, align 4
  %38 = load float, float* %hvn, align 4
  %39 = load float, float* %hvs, align 4
  %sub36 = fsub float %38, %39
  %mul37 = fmul float %37, %sub36
  %40 = load float, float* %dy.addr, align 4
  %div38 = fdiv float %mul37, %40
  %sub39 = fsub float %sub35, %div38
  %41 = load float*, float** %etan_j_k.addr, align 8
  store float %sub39, float* %41, align 4
  ret void
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
