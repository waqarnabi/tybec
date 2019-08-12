; ModuleID = 'barebonesBranch.unopt.ll'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }

@.str = private unnamed_addr constant [8 x i8] c"out.csv\00", align 1
@.str.1 = private unnamed_addr constant [2 x i8] c"w\00", align 1
@.str.2 = private unnamed_addr constant [12 x i8] c"verifyC.dat\00", align 1
@.str.3 = private unnamed_addr constant [15 x i8] c"verifyChex.dat\00", align 1
@start = common global i64 0, align 8
@end = common global i64 0, align 8
@cpu_time_used = common global double 0.000000e+00, align 8
@.str.4 = private unnamed_addr constant [50 x i8] c"Kernel execution took %f seconds (using clock_t)\0A\00", align 1
@.str.5 = private unnamed_addr constant [70 x i8] c"i = %d, vconn_A_to_B[i] = %d, pred[i] = %d, local1 = %d, local2 = %d\0A\00", align 1
@.str.6 = private unnamed_addr constant [70 x i8] c"FAILED verification:: i = %d ; vout[i] = %d ; goldenResults[i] = %d \0A\00", align 1
@.str.7 = private unnamed_addr constant [25 x i8] c"SUCCESSFUL verification\0A\00", align 1
@.str.8 = private unnamed_addr constant [141 x i8] c"-------------------------------------------------------------------------------------------------------------------------------------------\0A\00", align 1
@.str.9 = private unnamed_addr constant [101 x i8] c"\09\09   i,\09   vin0(i),\09   vin1(i),\09\09  vcon`n_A_to_B(i),\09 vconn_B_to_C(i),\09vconn_C_to_D(i),\09vout(i)\09   \0A\00", align 1
@.str.10 = private unnamed_addr constant [29 x i8] c"\09%d,\09%d,\09%d,\09%d,\09%d,\09%d,\09%d\0A\00", align 1
@.str.11 = private unnamed_addr constant [9 x i8] c"%d = %d\0A\00", align 1
@.str.12 = private unnamed_addr constant [4 x i8] c"%x\0A\00", align 1
@.str.13 = private unnamed_addr constant [16 x i8] c"Results logged\0A\00", align 1
@start_time = common global i64 0, align 8
@end_time = common global i64 0, align 8

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
define i32 @main() #0 {
entry:
  %call = call noalias i8* @malloc(i64 256) #3
  %0 = bitcast i8* %call to i32*
  %call1 = call noalias i8* @malloc(i64 256) #3
  %1 = bitcast i8* %call1 to i32*
  %call2 = call noalias i8* @malloc(i64 256) #3
  %2 = bitcast i8* %call2 to i32*
  %call3 = call noalias i8* @malloc(i64 256) #3
  %3 = bitcast i8* %call3 to i32*
  %call4 = call noalias i8* @malloc(i64 256) #3
  %4 = bitcast i8* %call4 to i32*
  %call5 = call noalias i8* @malloc(i64 256) #3
  %5 = bitcast i8* %call5 to i32*
  %call6 = call noalias i8* @malloc(i64 256) #3
  %6 = bitcast i8* %call6 to i32*
  call void @init(i32* %0, i32* %1, i32* %2)
  %call7 = call %struct._IO_FILE* @fopen(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.1, i32 0, i32 0))
  %call8 = call %struct._IO_FILE* @fopen(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.1, i32 0, i32 0))
  %call9 = call %struct._IO_FILE* @fopen(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.3, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.1, i32 0, i32 0))
  %call10 = call i64 @clock() #3
  store i64 %call10, i64* @start, align 8
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %step.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %step.0, 1
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  call void @kernel_A(i32* %0, i32* %1, i32* %2, i32* %4)
  call void @kernel_B(i32* %4, i32* %5)
  call void @kernel_C(i32* %5, i32* %6)
  call void @kernel_D(i32* %6, i32* %3)
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %step.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  %call11 = call i64 @clock() #3
  store i64 %call11, i64* @end, align 8
  %7 = load i64, i64* @end, align 8
  %8 = load i64, i64* @start, align 8
  %sub = sub nsw i64 %7, %8
  %conv = sitofp i64 %sub to double
  %div = fdiv double %conv, 1.000000e+06
  store double %div, double* @cpu_time_used, align 8
  %9 = load double, double* @cpu_time_used, align 8
  %call12 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([50 x i8], [50 x i8]* @.str.4, i32 0, i32 0), double %9)
  call void @post(%struct._IO_FILE* %call7, %struct._IO_FILE* %call8, %struct._IO_FILE* %call9, i32* %0, i32* %1, i32* %4, i32* %5, i32* %6, i32* %3)
  ret i32 0
}

; Function Attrs: nounwind
declare noalias i8* @malloc(i64) #1

; Function Attrs: nounwind uwtable
define void @init(i32* %vin0, i32* %vin1, i32* %pred) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %i.0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %add = add nsw i32 %i.0, 1
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %vin0, i64 %idxprom
  store i32 %add, i32* %arrayidx, align 4
  %add1 = add nsw i32 %i.0, 1
  %idxprom2 = sext i32 %i.0 to i64
  %arrayidx3 = getelementptr inbounds i32, i32* %vin1, i64 %idxprom2
  store i32 %add1, i32* %arrayidx3, align 4
  %call = call i32 @rand() #3
  %rem = srem i32 %call, 2
  %idxprom4 = sext i32 %i.0 to i64
  %arrayidx5 = getelementptr inbounds i32, i32* %pred, i64 %idxprom4
  store i32 %rem, i32* %arrayidx5, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

declare %struct._IO_FILE* @fopen(i8*, i8*) #2

; Function Attrs: nounwind
declare i64 @clock() #1

; Function Attrs: nounwind uwtable
define void @kernel_A(i32* %vin0, i32* %vin1, i32* %pred, i32* %vconn_A_to_B) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %i.0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %vin0, i64 %idxprom
  %0 = load i32, i32* %arrayidx, align 4
  %idxprom1 = sext i32 %i.0 to i64
  %arrayidx2 = getelementptr inbounds i32, i32* %vin1, i64 %idxprom1
  %1 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %0, %1
  %idxprom3 = sext i32 %i.0 to i64
  %arrayidx4 = getelementptr inbounds i32, i32* %vin0, i64 %idxprom3
  %2 = load i32, i32* %arrayidx4, align 4
  %idxprom5 = sext i32 %i.0 to i64
  %arrayidx6 = getelementptr inbounds i32, i32* %vin1, i64 %idxprom5
  %3 = load i32, i32* %arrayidx6, align 4
  %mul = mul nsw i32 %2, %3
  %idxprom7 = sext i32 %i.0 to i64
  %arrayidx8 = getelementptr inbounds i32, i32* %pred, i64 %idxprom7
  %4 = load i32, i32* %arrayidx8, align 4
  %tobool = icmp ne i32 %4, 0
  br i1 %tobool, label %cond.true, label %cond.false

cond.true:                                        ; preds = %for.body
  br label %cond.end

cond.false:                                       ; preds = %for.body
  br label %cond.end

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %add, %cond.true ], [ %mul, %cond.false ]
  %idxprom9 = sext i32 %i.0 to i64
  %arrayidx10 = getelementptr inbounds i32, i32* %vconn_A_to_B, i64 %idxprom9
  store i32 %cond, i32* %arrayidx10, align 4
  %idxprom11 = sext i32 %i.0 to i64
  %arrayidx12 = getelementptr inbounds i32, i32* %vconn_A_to_B, i64 %idxprom11
  %5 = load i32, i32* %arrayidx12, align 4
  %idxprom13 = sext i32 %i.0 to i64
  %arrayidx14 = getelementptr inbounds i32, i32* %pred, i64 %idxprom13
  %6 = load i32, i32* %arrayidx14, align 4
  %call = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([70 x i8], [70 x i8]* @.str.5, i32 0, i32 0), i32 %i.0, i32 %5, i32 %6, i32 %add, i32 %mul)
  br label %for.inc

for.inc:                                          ; preds = %cond.end
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind uwtable
define void @kernel_B(i32* %vconn_A_to_B, i32* %vconn_B_to_C) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %i.0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %vconn_A_to_B, i64 %idxprom
  %0 = load i32, i32* %arrayidx, align 4
  %idxprom1 = sext i32 %i.0 to i64
  %arrayidx2 = getelementptr inbounds i32, i32* %vconn_A_to_B, i64 %idxprom1
  %1 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %0, %1
  %idxprom3 = sext i32 %i.0 to i64
  %arrayidx4 = getelementptr inbounds i32, i32* %vconn_B_to_C, i64 %idxprom3
  store i32 %add, i32* %arrayidx4, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind uwtable
define void @kernel_C(i32* %vconn_B_to_C, i32* %vconn_C_to_D) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %i.0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %vconn_B_to_C, i64 %idxprom
  %0 = load i32, i32* %arrayidx, align 4
  %idxprom1 = sext i32 %i.0 to i64
  %arrayidx2 = getelementptr inbounds i32, i32* %vconn_B_to_C, i64 %idxprom1
  %1 = load i32, i32* %arrayidx2, align 4
  %mul = mul nsw i32 %0, %1
  %idxprom3 = sext i32 %i.0 to i64
  %arrayidx4 = getelementptr inbounds i32, i32* %vconn_C_to_D, i64 %idxprom3
  store i32 %mul, i32* %arrayidx4, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind uwtable
define void @kernel_D(i32* %vconn_C_to_D, i32* %vout) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %i.0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %vconn_C_to_D, i64 %idxprom
  %0 = load i32, i32* %arrayidx, align 4
  %idxprom1 = sext i32 %i.0 to i64
  %arrayidx2 = getelementptr inbounds i32, i32* %vconn_C_to_D, i64 %idxprom1
  %1 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %0, %1
  %idxprom3 = sext i32 %i.0 to i64
  %arrayidx4 = getelementptr inbounds i32, i32* %vout, i64 %idxprom3
  store i32 %add, i32* %arrayidx4, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

declare i32 @printf(i8*, ...) #2

; Function Attrs: nounwind uwtable
define void @post(%struct._IO_FILE* %fp, %struct._IO_FILE* %fp_verify, %struct._IO_FILE* %fp_verify_hex, i32* %vin0, i32* %vin1, i32* %vconn_A_to_B, i32* %vconn_B_to_C, i32* %vconn_C_to_D, i32* %vout) #0 {
entry:
  %call = call noalias i8* @malloc(i64 256) #3
  %0 = bitcast i8* %call to i32*
  call void @computeKernelFunction(i32* %vin0, i32* %vin1, i32* %0)
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %success.0 = phi i32 [ 1, %entry ], [ %success.1, %for.inc ]
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %i.0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %vout, i64 %idxprom
  %1 = load i32, i32* %arrayidx, align 4
  %idxprom1 = sext i32 %i.0 to i64
  %arrayidx2 = getelementptr inbounds i32, i32* %0, i64 %idxprom1
  %2 = load i32, i32* %arrayidx2, align 4
  %cmp3 = icmp ne i32 %1, %2
  br i1 %cmp3, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  %idxprom4 = sext i32 %i.0 to i64
  %arrayidx5 = getelementptr inbounds i32, i32* %vout, i64 %idxprom4
  %3 = load i32, i32* %arrayidx5, align 4
  %idxprom6 = sext i32 %i.0 to i64
  %arrayidx7 = getelementptr inbounds i32, i32* %0, i64 %idxprom6
  %4 = load i32, i32* %arrayidx7, align 4
  %call8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([70 x i8], [70 x i8]* @.str.6, i32 0, i32 0), i32 %i.0, i32 %3, i32 %4)
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body
  %success.1 = phi i32 [ 0, %if.then ], [ %success.0, %for.body ]
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  %cmp9 = icmp eq i32 %success.0, 1
  br i1 %cmp9, label %if.then10, label %if.end12

if.then10:                                        ; preds = %for.end
  %call11 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.str.7, i32 0, i32 0))
  br label %if.end12

if.end12:                                         ; preds = %if.then10, %for.end
  %call13 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %fp, i8* getelementptr inbounds ([141 x i8], [141 x i8]* @.str.8, i32 0, i32 0))
  %call14 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %fp, i8* getelementptr inbounds ([101 x i8], [101 x i8]* @.str.9, i32 0, i32 0))
  %call15 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %fp, i8* getelementptr inbounds ([141 x i8], [141 x i8]* @.str.8, i32 0, i32 0))
  br label %for.cond17

for.cond17:                                       ; preds = %for.inc39, %if.end12
  %i16.0 = phi i32 [ 0, %if.end12 ], [ %inc40, %for.inc39 ]
  %cmp18 = icmp slt i32 %i16.0, 64
  br i1 %cmp18, label %for.body19, label %for.end41

for.body19:                                       ; preds = %for.cond17
  %idxprom20 = sext i32 %i16.0 to i64
  %arrayidx21 = getelementptr inbounds i32, i32* %vin0, i64 %idxprom20
  %5 = load i32, i32* %arrayidx21, align 4
  %idxprom22 = sext i32 %i16.0 to i64
  %arrayidx23 = getelementptr inbounds i32, i32* %vin1, i64 %idxprom22
  %6 = load i32, i32* %arrayidx23, align 4
  %idxprom24 = sext i32 %i16.0 to i64
  %arrayidx25 = getelementptr inbounds i32, i32* %vconn_A_to_B, i64 %idxprom24
  %7 = load i32, i32* %arrayidx25, align 4
  %idxprom26 = sext i32 %i16.0 to i64
  %arrayidx27 = getelementptr inbounds i32, i32* %vconn_B_to_C, i64 %idxprom26
  %8 = load i32, i32* %arrayidx27, align 4
  %idxprom28 = sext i32 %i16.0 to i64
  %arrayidx29 = getelementptr inbounds i32, i32* %vconn_C_to_D, i64 %idxprom28
  %9 = load i32, i32* %arrayidx29, align 4
  %idxprom30 = sext i32 %i16.0 to i64
  %arrayidx31 = getelementptr inbounds i32, i32* %vout, i64 %idxprom30
  %10 = load i32, i32* %arrayidx31, align 4
  %call32 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %fp, i8* getelementptr inbounds ([29 x i8], [29 x i8]* @.str.10, i32 0, i32 0), i32 %i16.0, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9, i32 %10)
  %idxprom33 = sext i32 %i16.0 to i64
  %arrayidx34 = getelementptr inbounds i32, i32* %vout, i64 %idxprom33
  %11 = load i32, i32* %arrayidx34, align 4
  %call35 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %fp_verify, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str.11, i32 0, i32 0), i32 %i16.0, i32 %11)
  %idxprom36 = sext i32 %i16.0 to i64
  %arrayidx37 = getelementptr inbounds i32, i32* %vout, i64 %idxprom36
  %12 = load i32, i32* %arrayidx37, align 4
  %call38 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %fp_verify_hex, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.12, i32 0, i32 0), i32 %12)
  br label %for.inc39

for.inc39:                                        ; preds = %for.body19
  %inc40 = add nsw i32 %i16.0, 1
  br label %for.cond17

for.end41:                                        ; preds = %for.cond17
  %call42 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([16 x i8], [16 x i8]* @.str.13, i32 0, i32 0))
  ret void
}

; Function Attrs: nounwind
declare i32 @rand() #1

; Function Attrs: nounwind uwtable
define void @computeKernelFunction(i32* %vin0, i32* %vin1, i32* %vout) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %i.0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %vin0, i64 %idxprom
  %0 = load i32, i32* %arrayidx, align 4
  %idxprom1 = sext i32 %i.0 to i64
  %arrayidx2 = getelementptr inbounds i32, i32* %vin1, i64 %idxprom1
  %1 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %0, %1
  %idxprom3 = sext i32 %i.0 to i64
  %arrayidx4 = getelementptr inbounds i32, i32* %vin0, i64 %idxprom3
  %2 = load i32, i32* %arrayidx4, align 4
  %idxprom5 = sext i32 %i.0 to i64
  %arrayidx6 = getelementptr inbounds i32, i32* %vin1, i64 %idxprom5
  %3 = load i32, i32* %arrayidx6, align 4
  %add7 = add nsw i32 %2, %3
  %mul = mul nsw i32 %add, %add7
  %mul8 = mul nsw i32 %mul, 32
  %idxprom9 = sext i32 %i.0 to i64
  %arrayidx10 = getelementptr inbounds i32, i32* %vout, i64 %idxprom9
  store i32 %mul8, i32* %arrayidx10, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

declare i32 @fprintf(%struct._IO_FILE*, i8*, ...) #2

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.8.1 (tags/RELEASE_381/final)"}
