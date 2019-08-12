; ModuleID = 'llvmir.ll'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define i32 @computeKernelFunction(i32 %lin, i32 %vin0, i32 %vin1) #0 {
entry:
  %div = sdiv i32 %lin, 1024
  %rem = srem i32 %lin, 1024
  %cmp = icmp eq i32 %div, 0
  br i1 %cmp, label %if.then, label %lor.lhs.false

lor.lhs.false:                                    ; preds = %entry
  %cmp1 = icmp eq i32 %div, 1023
  br i1 %cmp1, label %if.then, label %lor.lhs.false2

lor.lhs.false2:                                   ; preds = %lor.lhs.false
  %cmp3 = icmp eq i32 %rem, 0
  br i1 %cmp3, label %if.then, label %lor.lhs.false4

lor.lhs.false4:                                   ; preds = %lor.lhs.false2
  %cmp5 = icmp eq i32 %rem, 1023
  br i1 %cmp5, label %if.then, label %if.else

if.then:                                          ; preds = %lor.lhs.false4, %lor.lhs.false2, %lor.lhs.false, %entry
  br label %if.end

if.else:                                          ; preds = %lor.lhs.false4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %stencilResult.0 = phi i32 [ %vin0, %if.then ], [ %vin1, %if.else ]
  ret i32 %stencilResult.0
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
