; ModuleID = 'dyn1.unopt.ll'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [24 x i8] c"tytra_linear_size(1024)\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"./llvm_tmp_.cl\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [22 x i8] c"tytra_linear_size(18)\00", section "llvm.metadata"
@llvm.global.annotations = appending global [2 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float*, float*)* @dyn to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 17 }, { i8*, i8*, i8*, i32 } { i8* bitcast (void (float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float*, float*)* @dyn to i8*), i8* getelementptr inbounds ([22 x i8], [22 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.1, i32 0, i32 0), i32 17 }], section "llvm.metadata"

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
define void @dyn(float %dt, float %dx, float %dy, float %g, float %u_j_k, float %v_j_k, float %h_j_k, float %eta_j_k, float %eta_j_kp1, float %eta_jp1_k, float %etan_j_k, float %wet_j_k, float %wet_j_kp1, float %wet_jp1_k, float %hzero_j_k, float %j, float %k, float* %un_j_k, float* %vn_j_k) #0 {
entry:
  %cmp = fcmp oge float %j, 1.000000e+00
  br i1 %cmp, label %land.lhs.true, label %if.end45

land.lhs.true:                                    ; preds = %entry
  %cmp1 = fcmp oge float %k, 1.000000e+00
  br i1 %cmp1, label %land.lhs.true2, label %if.end45

land.lhs.true2:                                   ; preds = %land.lhs.true
  %cmp3 = fcmp ole float %j, 5.100000e+01
  br i1 %cmp3, label %land.lhs.true4, label %if.end45

land.lhs.true4:                                   ; preds = %land.lhs.true2
  %cmp5 = fcmp ole float %k, 5.100000e+01
  br i1 %cmp5, label %if.then, label %if.end45

if.then:                                          ; preds = %land.lhs.true4
  %sub = fsub float -0.000000e+00, %dt
  %mul = fmul float %sub, %g
  %sub6 = fsub float %eta_j_kp1, %eta_j_k
  %mul7 = fmul float %mul, %sub6
  %div = fdiv float %mul7, %dx
  %sub8 = fsub float -0.000000e+00, %dt
  %mul9 = fmul float %sub8, %g
  %sub10 = fsub float %eta_jp1_k, %eta_j_k
  %mul11 = fmul float %mul9, %sub10
  %div12 = fdiv float %mul11, %dy
  %cmp13 = fcmp oeq float %wet_j_k, 1.000000e+00
  br i1 %cmp13, label %land.lhs.true14, label %lor.lhs.false18

land.lhs.true14:                                  ; preds = %if.then
  %cmp15 = fcmp oeq float %wet_j_kp1, 1.000000e+00
  br i1 %cmp15, label %if.then25, label %lor.lhs.false

lor.lhs.false:                                    ; preds = %land.lhs.true14
  %conv = fpext float %div to double
  %cmp16 = fcmp ogt double %conv, 0.000000e+00
  br i1 %cmp16, label %if.then25, label %lor.lhs.false18

lor.lhs.false18:                                  ; preds = %lor.lhs.false, %if.then
  %cmp19 = fcmp oeq float %wet_j_kp1, 1.000000e+00
  br i1 %cmp19, label %land.lhs.true21, label %if.end

land.lhs.true21:                                  ; preds = %lor.lhs.false18
  %conv22 = fpext float %div to double
  %cmp23 = fcmp olt double %conv22, 0.000000e+00
  br i1 %cmp23, label %if.then25, label %if.end

if.then25:                                        ; preds = %land.lhs.true21, %lor.lhs.false, %land.lhs.true14
  %add = fadd float %u_j_k, %div
  store float %add, float* %un_j_k, align 4
  br label %if.end

if.end:                                           ; preds = %if.then25, %land.lhs.true21, %lor.lhs.false18
  %cmp26 = fcmp oeq float %wet_j_k, 1.000000e+00
  br i1 %cmp26, label %land.lhs.true28, label %lor.lhs.false35

land.lhs.true28:                                  ; preds = %if.end
  %cmp29 = fcmp oeq float %wet_jp1_k, 1.000000e+00
  br i1 %cmp29, label %if.then42, label %lor.lhs.false31

lor.lhs.false31:                                  ; preds = %land.lhs.true28
  %conv32 = fpext float %div12 to double
  %cmp33 = fcmp ogt double %conv32, 0.000000e+00
  br i1 %cmp33, label %if.then42, label %lor.lhs.false35

lor.lhs.false35:                                  ; preds = %lor.lhs.false31, %if.end
  %cmp36 = fcmp oeq float %wet_jp1_k, 1.000000e+00
  br i1 %cmp36, label %land.lhs.true38, label %if.end44

land.lhs.true38:                                  ; preds = %lor.lhs.false35
  %conv39 = fpext float %div12 to double
  %cmp40 = fcmp olt double %conv39, 0.000000e+00
  br i1 %cmp40, label %if.then42, label %if.end44

if.then42:                                        ; preds = %land.lhs.true38, %lor.lhs.false31, %land.lhs.true28
  %add43 = fadd float %v_j_k, %div12
  store float %add43, float* %vn_j_k, align 4
  br label %if.end44

if.end44:                                         ; preds = %if.then42, %land.lhs.true38, %lor.lhs.false35
  br label %if.end45

if.end45:                                         ; preds = %if.end44, %land.lhs.true4, %land.lhs.true2, %land.lhs.true, %entry
  ret void
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
