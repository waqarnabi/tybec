; ModuleID = 'barebonesStencil.c'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define i32 @computeKernelFunction(i32 %lin, i32 %vin0, i32 %vin1) #0 {
entry:
  %lin.addr = alloca i32, align 4
  %vin0.addr = alloca i32, align 4
  %vin1.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %j = alloca i32, align 4
  %stencilResult = alloca i32, align 4
  store i32 %lin, i32* %lin.addr, align 4
  store i32 %vin0, i32* %vin0.addr, align 4
  store i32 %vin1, i32* %vin1.addr, align 4
  %0 = load i32, i32* %lin.addr, align 4
  %div = sdiv i32 %0, 1024
  store i32 %div, i32* %i, align 4
  %1 = load i32, i32* %lin.addr, align 4
  %rem = srem i32 %1, 1024
  store i32 %rem, i32* %j, align 4
  %2 = load i32, i32* %i, align 4
  %cmp = icmp eq i32 %2, 0
  br i1 %cmp, label %if.then, label %lor.lhs.false

lor.lhs.false:                                    ; preds = %entry
  %3 = load i32, i32* %i, align 4
  %cmp1 = icmp eq i32 %3, 1023
  br i1 %cmp1, label %if.then, label %lor.lhs.false2

lor.lhs.false2:                                   ; preds = %lor.lhs.false
  %4 = load i32, i32* %j, align 4
  %cmp3 = icmp eq i32 %4, 0
  br i1 %cmp3, label %if.then, label %lor.lhs.false4

lor.lhs.false4:                                   ; preds = %lor.lhs.false2
  %5 = load i32, i32* %j, align 4
  %cmp5 = icmp eq i32 %5, 1023
  br i1 %cmp5, label %if.then, label %if.else

if.then:                                          ; preds = %lor.lhs.false4, %lor.lhs.false2, %lor.lhs.false, %entry
  %6 = load i32, i32* %vin0.addr, align 4
  store i32 %6, i32* %stencilResult, align 4
  br label %if.end

if.else:                                          ; preds = %lor.lhs.false4
  %7 = load i32, i32* %vin1.addr, align 4
  store i32 %7, i32* %stencilResult, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %8 = load i32, i32* %stencilResult, align 4
  ret i32 %8
}

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
