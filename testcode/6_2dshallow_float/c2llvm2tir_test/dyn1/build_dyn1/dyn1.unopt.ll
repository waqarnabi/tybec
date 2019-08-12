; ModuleID = 'llvm_ocl_stubs.c'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [24 x i8] c"tytra_linear_size(1024)\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"./llvm_tmp_.cl\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [22 x i8] c"tytra_linear_size(18)\00", section "llvm.metadata"
@llvm.global.annotations = appending global [2 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float*, float*)* @dyn to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 17 }, { i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float*, float*)* @dyn to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 17 }], section "llvm.metadata"

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
define void @dyn(float %dt, float %dx, float %dy, float %g, float %u_j_k, float %v_j_k, float %h_j_k, float %eta_j_k, float %eta_j_kp1, float %eta_jp1_k, float %etan_j_k, float %wet_j_k, float %wet_j_kp1, float %wet_jp1_k, float %hzero_j_k, float %j, float %k, float* %un_j_k, float* %vn_j_k) #0 {
entry:
  %dt.addr = alloca float, align 4
  %dx.addr = alloca float, align 4
  %dy.addr = alloca float, align 4
  %g.addr = alloca float, align 4
  %u_j_k.addr = alloca float, align 4
  %v_j_k.addr = alloca float, align 4
  %h_j_k.addr = alloca float, align 4
  %eta_j_k.addr = alloca float, align 4
  %eta_j_kp1.addr = alloca float, align 4
  %eta_jp1_k.addr = alloca float, align 4
  %etan_j_k.addr = alloca float, align 4
  %wet_j_k.addr = alloca float, align 4
  %wet_j_kp1.addr = alloca float, align 4
  %wet_jp1_k.addr = alloca float, align 4
  %hzero_j_k.addr = alloca float, align 4
  %j.addr = alloca float, align 4
  %k.addr = alloca float, align 4
  %un_j_k.addr = alloca float*, align 8
  %vn_j_k.addr = alloca float*, align 8
  %du = alloca float, align 4
  %dv = alloca float, align 4
  %uu = alloca float, align 4
  %vv = alloca float, align 4
  %duu = alloca float, align 4
  %dvv = alloca float, align 4
  store float %dt, float* %dt.addr, align 4
  store float %dx, float* %dx.addr, align 4
  store float %dy, float* %dy.addr, align 4
  store float %g, float* %g.addr, align 4
  store float %u_j_k, float* %u_j_k.addr, align 4
  store float %v_j_k, float* %v_j_k.addr, align 4
  store float %h_j_k, float* %h_j_k.addr, align 4
  store float %eta_j_k, float* %eta_j_k.addr, align 4
  store float %eta_j_kp1, float* %eta_j_kp1.addr, align 4
  store float %eta_jp1_k, float* %eta_jp1_k.addr, align 4
  store float %etan_j_k, float* %etan_j_k.addr, align 4
  store float %wet_j_k, float* %wet_j_k.addr, align 4
  store float %wet_j_kp1, float* %wet_j_kp1.addr, align 4
  store float %wet_jp1_k, float* %wet_jp1_k.addr, align 4
  store float %hzero_j_k, float* %hzero_j_k.addr, align 4
  store float %j, float* %j.addr, align 4
  store float %k, float* %k.addr, align 4
  store float* %un_j_k, float** %un_j_k.addr, align 8
  store float* %vn_j_k, float** %vn_j_k.addr, align 8
  %0 = load float, float* %j.addr, align 4
  %cmp = fcmp oge float %0, 1.000000e+00
  br i1 %cmp, label %land.lhs.true, label %if.end45

land.lhs.true:                                    ; preds = %entry
  %1 = load float, float* %k.addr, align 4
  %cmp1 = fcmp oge float %1, 1.000000e+00
  br i1 %cmp1, label %land.lhs.true2, label %if.end45

land.lhs.true2:                                   ; preds = %land.lhs.true
  %2 = load float, float* %j.addr, align 4
  %cmp3 = fcmp ole float %2, 5.100000e+01
  br i1 %cmp3, label %land.lhs.true4, label %if.end45

land.lhs.true4:                                   ; preds = %land.lhs.true2
  %3 = load float, float* %k.addr, align 4
  %cmp5 = fcmp ole float %3, 5.100000e+01
  br i1 %cmp5, label %if.then, label %if.end45

if.then:                                          ; preds = %land.lhs.true4
  %4 = load float, float* %dt.addr, align 4
  %sub = fsub float -0.000000e+00, %4
  %5 = load float, float* %g.addr, align 4
  %mul = fmul float %sub, %5
  %6 = load float, float* %eta_j_kp1.addr, align 4
  %7 = load float, float* %eta_j_k.addr, align 4
  %sub6 = fsub float %6, %7
  %mul7 = fmul float %mul, %sub6
  %8 = load float, float* %dx.addr, align 4
  %div = fdiv float %mul7, %8
  store float %div, float* %duu, align 4
  %9 = load float, float* %dt.addr, align 4
  %sub8 = fsub float -0.000000e+00, %9
  %10 = load float, float* %g.addr, align 4
  %mul9 = fmul float %sub8, %10
  %11 = load float, float* %eta_jp1_k.addr, align 4
  %12 = load float, float* %eta_j_k.addr, align 4
  %sub10 = fsub float %11, %12
  %mul11 = fmul float %mul9, %sub10
  %13 = load float, float* %dy.addr, align 4
  %div12 = fdiv float %mul11, %13
  store float %div12, float* %dvv, align 4
  %14 = load float, float* %u_j_k.addr, align 4
  store float %14, float* %uu, align 4
  %15 = load float, float* %wet_j_k.addr, align 4
  %cmp13 = fcmp oeq float %15, 1.000000e+00
  br i1 %cmp13, label %land.lhs.true14, label %lor.lhs.false18

land.lhs.true14:                                  ; preds = %if.then
  %16 = load float, float* %wet_j_kp1.addr, align 4
  %cmp15 = fcmp oeq float %16, 1.000000e+00
  br i1 %cmp15, label %if.then25, label %lor.lhs.false

lor.lhs.false:                                    ; preds = %land.lhs.true14
  %17 = load float, float* %duu, align 4
  %conv = fpext float %17 to double
  %cmp16 = fcmp ogt double %conv, 0.000000e+00
  br i1 %cmp16, label %if.then25, label %lor.lhs.false18

lor.lhs.false18:                                  ; preds = %lor.lhs.false, %if.then
  %18 = load float, float* %wet_j_kp1.addr, align 4
  %cmp19 = fcmp oeq float %18, 1.000000e+00
  br i1 %cmp19, label %land.lhs.true21, label %if.end

land.lhs.true21:                                  ; preds = %lor.lhs.false18
  %19 = load float, float* %duu, align 4
  %conv22 = fpext float %19 to double
  %cmp23 = fcmp olt double %conv22, 0.000000e+00
  br i1 %cmp23, label %if.then25, label %if.end

if.then25:                                        ; preds = %land.lhs.true21, %lor.lhs.false, %land.lhs.true14
  %20 = load float, float* %uu, align 4
  %21 = load float, float* %duu, align 4
  %add = fadd float %20, %21
  %22 = load float*, float** %un_j_k.addr, align 8
  store float %add, float* %22, align 4
  br label %if.end

if.end:                                           ; preds = %if.then25, %land.lhs.true21, %lor.lhs.false18
  %23 = load float, float* %v_j_k.addr, align 4
  store float %23, float* %vv, align 4
  %24 = load float, float* %wet_j_k.addr, align 4
  %cmp26 = fcmp oeq float %24, 1.000000e+00
  br i1 %cmp26, label %land.lhs.true28, label %lor.lhs.false35

land.lhs.true28:                                  ; preds = %if.end
  %25 = load float, float* %wet_jp1_k.addr, align 4
  %cmp29 = fcmp oeq float %25, 1.000000e+00
  br i1 %cmp29, label %if.then42, label %lor.lhs.false31

lor.lhs.false31:                                  ; preds = %land.lhs.true28
  %26 = load float, float* %dvv, align 4
  %conv32 = fpext float %26 to double
  %cmp33 = fcmp ogt double %conv32, 0.000000e+00
  br i1 %cmp33, label %if.then42, label %lor.lhs.false35

lor.lhs.false35:                                  ; preds = %lor.lhs.false31, %if.end
  %27 = load float, float* %wet_jp1_k.addr, align 4
  %cmp36 = fcmp oeq float %27, 1.000000e+00
  br i1 %cmp36, label %land.lhs.true38, label %if.end44

land.lhs.true38:                                  ; preds = %lor.lhs.false35
  %28 = load float, float* %dvv, align 4
  %conv39 = fpext float %28 to double
  %cmp40 = fcmp olt double %conv39, 0.000000e+00
  br i1 %cmp40, label %if.then42, label %if.end44

if.then42:                                        ; preds = %land.lhs.true38, %lor.lhs.false31, %land.lhs.true28
  %29 = load float, float* %vv, align 4
  %30 = load float, float* %dvv, align 4
  %add43 = fadd float %29, %30
  %31 = load float*, float** %vn_j_k.addr, align 8
  store float %add43, float* %31, align 4
  br label %if.end44

if.end44:                                         ; preds = %if.then42, %land.lhs.true38, %lor.lhs.false35
  br label %if.end45

if.end45:                                         ; preds = %if.end44, %land.lhs.true4, %land.lhs.true2, %land.lhs.true, %entry
  ret void
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
