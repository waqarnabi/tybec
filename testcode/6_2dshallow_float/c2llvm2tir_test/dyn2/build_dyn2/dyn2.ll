; ModuleID = 'dyn2.unopt.ll'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"tytra_linear_size(18)\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"./llvm_tmp_.cl\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [24 x i8] c"tytra_linear_size(1024)\00", section "llvm.metadata"
@llvm.global.annotations = appending global [2 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (float (float)* @fabs to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 8 }, { i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float*)* @dyn2 to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 15 }], section "llvm.metadata"

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
define void @dyn2(float %dt, float %dx, float %dy, float %un_j_k, float %un_j_km1, float %vn_j_k, float %vn_jm1_k, float %h_j_k, float %h_jm1_k, float %h_j_km1, float %h_j_kp1, float %h_jp1_k, float %eta_j_k, float %j, float %k, float* %etan_j_k) #0 {
entry:
  %call = call float @fabs(float %un_j_k)
  %add = fadd float %un_j_k, %call
  %mul = fmul float 5.000000e-01, %add
  %mul1 = fmul float %mul, %h_j_k
  %call2 = call float @fabs(float %un_j_k)
  %sub = fsub float %un_j_k, %call2
  %mul3 = fmul float 5.000000e-01, %sub
  %mul4 = fmul float %mul3, %h_j_kp1
  %add5 = fadd float %mul1, %mul4
  %call6 = call float @fabs(float %un_j_km1)
  %add7 = fadd float %un_j_km1, %call6
  %mul8 = fmul float 5.000000e-01, %add7
  %mul9 = fmul float %mul8, %h_j_km1
  %call10 = call float @fabs(float %un_j_km1)
  %sub11 = fsub float %un_j_km1, %call10
  %mul12 = fmul float 5.000000e-01, %sub11
  %mul13 = fmul float %mul12, %h_j_k
  %add14 = fadd float %mul9, %mul13
  %call15 = call float @fabs(float %vn_j_k)
  %add16 = fadd float %vn_j_k, %call15
  %mul17 = fmul float 5.000000e-01, %add16
  %mul18 = fmul float %mul17, %h_j_k
  %call19 = call float @fabs(float %vn_j_k)
  %sub20 = fsub float %vn_j_k, %call19
  %mul21 = fmul float 5.000000e-01, %sub20
  %mul22 = fmul float %mul21, %h_jp1_k
  %add23 = fadd float %mul18, %mul22
  %call24 = call float @fabs(float %vn_jm1_k)
  %add25 = fadd float %vn_jm1_k, %call24
  %mul26 = fmul float 5.000000e-01, %add25
  %mul27 = fmul float %mul26, %h_jm1_k
  %call28 = call float @fabs(float %vn_jm1_k)
  %sub29 = fsub float %vn_jm1_k, %call28
  %mul30 = fmul float 5.000000e-01, %sub29
  %mul31 = fmul float %mul30, %h_j_k
  %add32 = fadd float %mul27, %mul31
  %sub33 = fsub float %add5, %add14
  %mul34 = fmul float %dt, %sub33
  %div = fdiv float %mul34, %dx
  %sub35 = fsub float %eta_j_k, %div
  %sub36 = fsub float %add23, %add32
  %mul37 = fmul float %dt, %sub36
  %div38 = fdiv float %mul37, %dy
  %sub39 = fsub float %sub35, %div38
  store float %sub39, float* %etan_j_k, align 4
  ret void
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
