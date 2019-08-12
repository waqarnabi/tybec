; ModuleID = 'llvm_ocl_stubs.c'
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
define i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %vin0 = alloca i32*, align 8
  %vin1 = alloca i32*, align 8
  %pred = alloca i32*, align 8
  %vout = alloca i32*, align 8
  %vconn_A_to_B = alloca i32*, align 8
  %vconn_B_to_C = alloca i32*, align 8
  %vconn_C_to_D = alloca i32*, align 8
  %fp = alloca %struct._IO_FILE*, align 8
  %fp_verify = alloca %struct._IO_FILE*, align 8
  %fp_verify_hex = alloca %struct._IO_FILE*, align 8
  %step = alloca i32, align 4
  store i32 0, i32* %retval, align 4
  %call = call noalias i8* @malloc(i64 256) #3
  %0 = bitcast i8* %call to i32*
  store i32* %0, i32** %vin0, align 8
  %call1 = call noalias i8* @malloc(i64 256) #3
  %1 = bitcast i8* %call1 to i32*
  store i32* %1, i32** %vin1, align 8
  %call2 = call noalias i8* @malloc(i64 256) #3
  %2 = bitcast i8* %call2 to i32*
  store i32* %2, i32** %pred, align 8
  %call3 = call noalias i8* @malloc(i64 256) #3
  %3 = bitcast i8* %call3 to i32*
  store i32* %3, i32** %vout, align 8
  %call4 = call noalias i8* @malloc(i64 256) #3
  %4 = bitcast i8* %call4 to i32*
  store i32* %4, i32** %vconn_A_to_B, align 8
  %call5 = call noalias i8* @malloc(i64 256) #3
  %5 = bitcast i8* %call5 to i32*
  store i32* %5, i32** %vconn_B_to_C, align 8
  %call6 = call noalias i8* @malloc(i64 256) #3
  %6 = bitcast i8* %call6 to i32*
  store i32* %6, i32** %vconn_C_to_D, align 8
  %7 = load i32*, i32** %vin0, align 8
  %8 = load i32*, i32** %vin1, align 8
  %9 = load i32*, i32** %pred, align 8
  call void @init(i32* %7, i32* %8, i32* %9)
  %call7 = call %struct._IO_FILE* @fopen(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.1, i32 0, i32 0))
  store %struct._IO_FILE* %call7, %struct._IO_FILE** %fp, align 8
  %call8 = call %struct._IO_FILE* @fopen(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.1, i32 0, i32 0))
  store %struct._IO_FILE* %call8, %struct._IO_FILE** %fp_verify, align 8
  %call9 = call %struct._IO_FILE* @fopen(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.3, i32 0, i32 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.1, i32 0, i32 0))
  store %struct._IO_FILE* %call9, %struct._IO_FILE** %fp_verify_hex, align 8
  %call10 = call i64 @clock() #3
  store i64 %call10, i64* @start, align 8
  store i32 0, i32* %step, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %10 = load i32, i32* %step, align 4
  %cmp = icmp slt i32 %10, 1
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %11 = load i32*, i32** %vin0, align 8
  %12 = load i32*, i32** %vin1, align 8
  %13 = load i32*, i32** %pred, align 8
  %14 = load i32*, i32** %vconn_A_to_B, align 8
  call void @kernel_A(i32* %11, i32* %12, i32* %13, i32* %14)
  %15 = load i32*, i32** %vconn_A_to_B, align 8
  %16 = load i32*, i32** %vconn_B_to_C, align 8
  call void @kernel_B(i32* %15, i32* %16)
  %17 = load i32*, i32** %vconn_B_to_C, align 8
  %18 = load i32*, i32** %vconn_C_to_D, align 8
  call void @kernel_C(i32* %17, i32* %18)
  %19 = load i32*, i32** %vconn_C_to_D, align 8
  %20 = load i32*, i32** %vout, align 8
  call void @kernel_D(i32* %19, i32* %20)
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %21 = load i32, i32* %step, align 4
  %inc = add nsw i32 %21, 1
  store i32 %inc, i32* %step, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  %call11 = call i64 @clock() #3
  store i64 %call11, i64* @end, align 8
  %22 = load i64, i64* @end, align 8
  %23 = load i64, i64* @start, align 8
  %sub = sub nsw i64 %22, %23
  %conv = sitofp i64 %sub to double
  %div = fdiv double %conv, 1.000000e+06
  store double %div, double* @cpu_time_used, align 8
  %24 = load double, double* @cpu_time_used, align 8
  %call12 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([50 x i8], [50 x i8]* @.str.4, i32 0, i32 0), double %24)
  %25 = load %struct._IO_FILE*, %struct._IO_FILE** %fp, align 8
  %26 = load %struct._IO_FILE*, %struct._IO_FILE** %fp_verify, align 8
  %27 = load %struct._IO_FILE*, %struct._IO_FILE** %fp_verify_hex, align 8
  %28 = load i32*, i32** %vin0, align 8
  %29 = load i32*, i32** %vin1, align 8
  %30 = load i32*, i32** %vconn_A_to_B, align 8
  %31 = load i32*, i32** %vconn_B_to_C, align 8
  %32 = load i32*, i32** %vconn_C_to_D, align 8
  %33 = load i32*, i32** %vout, align 8
  call void @post(%struct._IO_FILE* %25, %struct._IO_FILE* %26, %struct._IO_FILE* %27, i32* %28, i32* %29, i32* %30, i32* %31, i32* %32, i32* %33)
  ret i32 0
}

; Function Attrs: nounwind
declare noalias i8* @malloc(i64) #1

; Function Attrs: nounwind uwtable
define void @init(i32* %vin0, i32* %vin1, i32* %pred) #0 {
entry:
  %vin0.addr = alloca i32*, align 8
  %vin1.addr = alloca i32*, align 8
  %pred.addr = alloca i32*, align 8
  %i = alloca i32, align 4
  store i32* %vin0, i32** %vin0.addr, align 8
  store i32* %vin1, i32** %vin1.addr, align 8
  store i32* %pred, i32** %pred.addr, align 8
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp slt i32 %0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %add = add nsw i32 %1, 1
  %2 = load i32, i32* %i, align 4
  %idxprom = sext i32 %2 to i64
  %3 = load i32*, i32** %vin0.addr, align 8
  %arrayidx = getelementptr inbounds i32, i32* %3, i64 %idxprom
  store i32 %add, i32* %arrayidx, align 4
  %4 = load i32, i32* %i, align 4
  %add1 = add nsw i32 %4, 1
  %5 = load i32, i32* %i, align 4
  %idxprom2 = sext i32 %5 to i64
  %6 = load i32*, i32** %vin1.addr, align 8
  %arrayidx3 = getelementptr inbounds i32, i32* %6, i64 %idxprom2
  store i32 %add1, i32* %arrayidx3, align 4
  %call = call i32 @rand() #3
  %rem = srem i32 %call, 2
  %7 = load i32, i32* %i, align 4
  %idxprom4 = sext i32 %7 to i64
  %8 = load i32*, i32** %pred.addr, align 8
  %arrayidx5 = getelementptr inbounds i32, i32* %8, i64 %idxprom4
  store i32 %rem, i32* %arrayidx5, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %9 = load i32, i32* %i, align 4
  %inc = add nsw i32 %9, 1
  store i32 %inc, i32* %i, align 4
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
  %vin0.addr = alloca i32*, align 8
  %vin1.addr = alloca i32*, align 8
  %pred.addr = alloca i32*, align 8
  %vconn_A_to_B.addr = alloca i32*, align 8
  %i = alloca i32, align 4
  %local1 = alloca i32, align 4
  %local2 = alloca i32, align 4
  store i32* %vin0, i32** %vin0.addr, align 8
  store i32* %vin1, i32** %vin1.addr, align 8
  store i32* %pred, i32** %pred.addr, align 8
  store i32* %vconn_A_to_B, i32** %vconn_A_to_B.addr, align 8
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp slt i32 %0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %idxprom = sext i32 %1 to i64
  %2 = load i32*, i32** %vin0.addr, align 8
  %arrayidx = getelementptr inbounds i32, i32* %2, i64 %idxprom
  %3 = load i32, i32* %arrayidx, align 4
  %4 = load i32, i32* %i, align 4
  %idxprom1 = sext i32 %4 to i64
  %5 = load i32*, i32** %vin1.addr, align 8
  %arrayidx2 = getelementptr inbounds i32, i32* %5, i64 %idxprom1
  %6 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %3, %6
  store i32 %add, i32* %local1, align 4
  %7 = load i32, i32* %i, align 4
  %idxprom3 = sext i32 %7 to i64
  %8 = load i32*, i32** %vin0.addr, align 8
  %arrayidx4 = getelementptr inbounds i32, i32* %8, i64 %idxprom3
  %9 = load i32, i32* %arrayidx4, align 4
  %10 = load i32, i32* %i, align 4
  %idxprom5 = sext i32 %10 to i64
  %11 = load i32*, i32** %vin1.addr, align 8
  %arrayidx6 = getelementptr inbounds i32, i32* %11, i64 %idxprom5
  %12 = load i32, i32* %arrayidx6, align 4
  %mul = mul nsw i32 %9, %12
  store i32 %mul, i32* %local2, align 4
  %13 = load i32, i32* %i, align 4
  %idxprom7 = sext i32 %13 to i64
  %14 = load i32*, i32** %pred.addr, align 8
  %arrayidx8 = getelementptr inbounds i32, i32* %14, i64 %idxprom7
  %15 = load i32, i32* %arrayidx8, align 4
  %tobool = icmp ne i32 %15, 0
  br i1 %tobool, label %cond.true, label %cond.false

cond.true:                                        ; preds = %for.body
  %16 = load i32, i32* %local1, align 4
  br label %cond.end

cond.false:                                       ; preds = %for.body
  %17 = load i32, i32* %local2, align 4
  br label %cond.end

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %16, %cond.true ], [ %17, %cond.false ]
  %18 = load i32, i32* %i, align 4
  %idxprom9 = sext i32 %18 to i64
  %19 = load i32*, i32** %vconn_A_to_B.addr, align 8
  %arrayidx10 = getelementptr inbounds i32, i32* %19, i64 %idxprom9
  store i32 %cond, i32* %arrayidx10, align 4
  %20 = load i32, i32* %i, align 4
  %21 = load i32, i32* %i, align 4
  %idxprom11 = sext i32 %21 to i64
  %22 = load i32*, i32** %vconn_A_to_B.addr, align 8
  %arrayidx12 = getelementptr inbounds i32, i32* %22, i64 %idxprom11
  %23 = load i32, i32* %arrayidx12, align 4
  %24 = load i32, i32* %i, align 4
  %idxprom13 = sext i32 %24 to i64
  %25 = load i32*, i32** %pred.addr, align 8
  %arrayidx14 = getelementptr inbounds i32, i32* %25, i64 %idxprom13
  %26 = load i32, i32* %arrayidx14, align 4
  %27 = load i32, i32* %local1, align 4
  %28 = load i32, i32* %local2, align 4
  %call = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([70 x i8], [70 x i8]* @.str.5, i32 0, i32 0), i32 %20, i32 %23, i32 %26, i32 %27, i32 %28)
  br label %for.inc

for.inc:                                          ; preds = %cond.end
  %29 = load i32, i32* %i, align 4
  %inc = add nsw i32 %29, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind uwtable
define void @kernel_B(i32* %vconn_A_to_B, i32* %vconn_B_to_C) #0 {
entry:
  %vconn_A_to_B.addr = alloca i32*, align 8
  %vconn_B_to_C.addr = alloca i32*, align 8
  %i = alloca i32, align 4
  store i32* %vconn_A_to_B, i32** %vconn_A_to_B.addr, align 8
  store i32* %vconn_B_to_C, i32** %vconn_B_to_C.addr, align 8
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp slt i32 %0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %idxprom = sext i32 %1 to i64
  %2 = load i32*, i32** %vconn_A_to_B.addr, align 8
  %arrayidx = getelementptr inbounds i32, i32* %2, i64 %idxprom
  %3 = load i32, i32* %arrayidx, align 4
  %4 = load i32, i32* %i, align 4
  %idxprom1 = sext i32 %4 to i64
  %5 = load i32*, i32** %vconn_A_to_B.addr, align 8
  %arrayidx2 = getelementptr inbounds i32, i32* %5, i64 %idxprom1
  %6 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %3, %6
  %7 = load i32, i32* %i, align 4
  %idxprom3 = sext i32 %7 to i64
  %8 = load i32*, i32** %vconn_B_to_C.addr, align 8
  %arrayidx4 = getelementptr inbounds i32, i32* %8, i64 %idxprom3
  store i32 %add, i32* %arrayidx4, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %9 = load i32, i32* %i, align 4
  %inc = add nsw i32 %9, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind uwtable
define void @kernel_C(i32* %vconn_B_to_C, i32* %vconn_C_to_D) #0 {
entry:
  %vconn_B_to_C.addr = alloca i32*, align 8
  %vconn_C_to_D.addr = alloca i32*, align 8
  %i = alloca i32, align 4
  store i32* %vconn_B_to_C, i32** %vconn_B_to_C.addr, align 8
  store i32* %vconn_C_to_D, i32** %vconn_C_to_D.addr, align 8
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp slt i32 %0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %idxprom = sext i32 %1 to i64
  %2 = load i32*, i32** %vconn_B_to_C.addr, align 8
  %arrayidx = getelementptr inbounds i32, i32* %2, i64 %idxprom
  %3 = load i32, i32* %arrayidx, align 4
  %4 = load i32, i32* %i, align 4
  %idxprom1 = sext i32 %4 to i64
  %5 = load i32*, i32** %vconn_B_to_C.addr, align 8
  %arrayidx2 = getelementptr inbounds i32, i32* %5, i64 %idxprom1
  %6 = load i32, i32* %arrayidx2, align 4
  %mul = mul nsw i32 %3, %6
  %7 = load i32, i32* %i, align 4
  %idxprom3 = sext i32 %7 to i64
  %8 = load i32*, i32** %vconn_C_to_D.addr, align 8
  %arrayidx4 = getelementptr inbounds i32, i32* %8, i64 %idxprom3
  store i32 %mul, i32* %arrayidx4, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %9 = load i32, i32* %i, align 4
  %inc = add nsw i32 %9, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind uwtable
define void @kernel_D(i32* %vconn_C_to_D, i32* %vout) #0 {
entry:
  %vconn_C_to_D.addr = alloca i32*, align 8
  %vout.addr = alloca i32*, align 8
  %i = alloca i32, align 4
  store i32* %vconn_C_to_D, i32** %vconn_C_to_D.addr, align 8
  store i32* %vout, i32** %vout.addr, align 8
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp slt i32 %0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %idxprom = sext i32 %1 to i64
  %2 = load i32*, i32** %vconn_C_to_D.addr, align 8
  %arrayidx = getelementptr inbounds i32, i32* %2, i64 %idxprom
  %3 = load i32, i32* %arrayidx, align 4
  %4 = load i32, i32* %i, align 4
  %idxprom1 = sext i32 %4 to i64
  %5 = load i32*, i32** %vconn_C_to_D.addr, align 8
  %arrayidx2 = getelementptr inbounds i32, i32* %5, i64 %idxprom1
  %6 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %3, %6
  %7 = load i32, i32* %i, align 4
  %idxprom3 = sext i32 %7 to i64
  %8 = load i32*, i32** %vout.addr, align 8
  %arrayidx4 = getelementptr inbounds i32, i32* %8, i64 %idxprom3
  store i32 %add, i32* %arrayidx4, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %9 = load i32, i32* %i, align 4
  %inc = add nsw i32 %9, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

declare i32 @printf(i8*, ...) #2

; Function Attrs: nounwind uwtable
define void @post(%struct._IO_FILE* %fp, %struct._IO_FILE* %fp_verify, %struct._IO_FILE* %fp_verify_hex, i32* %vin0, i32* %vin1, i32* %vconn_A_to_B, i32* %vconn_B_to_C, i32* %vconn_C_to_D, i32* %vout) #0 {
entry:
  %fp.addr = alloca %struct._IO_FILE*, align 8
  %fp_verify.addr = alloca %struct._IO_FILE*, align 8
  %fp_verify_hex.addr = alloca %struct._IO_FILE*, align 8
  %vin0.addr = alloca i32*, align 8
  %vin1.addr = alloca i32*, align 8
  %vconn_A_to_B.addr = alloca i32*, align 8
  %vconn_B_to_C.addr = alloca i32*, align 8
  %vconn_C_to_D.addr = alloca i32*, align 8
  %vout.addr = alloca i32*, align 8
  %goldenResults = alloca i32*, align 8
  %success = alloca i32, align 4
  %i = alloca i32, align 4
  %i16 = alloca i32, align 4
  store %struct._IO_FILE* %fp, %struct._IO_FILE** %fp.addr, align 8
  store %struct._IO_FILE* %fp_verify, %struct._IO_FILE** %fp_verify.addr, align 8
  store %struct._IO_FILE* %fp_verify_hex, %struct._IO_FILE** %fp_verify_hex.addr, align 8
  store i32* %vin0, i32** %vin0.addr, align 8
  store i32* %vin1, i32** %vin1.addr, align 8
  store i32* %vconn_A_to_B, i32** %vconn_A_to_B.addr, align 8
  store i32* %vconn_B_to_C, i32** %vconn_B_to_C.addr, align 8
  store i32* %vconn_C_to_D, i32** %vconn_C_to_D.addr, align 8
  store i32* %vout, i32** %vout.addr, align 8
  %call = call noalias i8* @malloc(i64 256) #3
  %0 = bitcast i8* %call to i32*
  store i32* %0, i32** %goldenResults, align 8
  %1 = load i32*, i32** %vin0.addr, align 8
  %2 = load i32*, i32** %vin1.addr, align 8
  %3 = load i32*, i32** %goldenResults, align 8
  call void @computeKernelFunction(i32* %1, i32* %2, i32* %3)
  store i32 1, i32* %success, align 4
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %4 = load i32, i32* %i, align 4
  %cmp = icmp slt i32 %4, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %5 = load i32, i32* %i, align 4
  %idxprom = sext i32 %5 to i64
  %6 = load i32*, i32** %vout.addr, align 8
  %arrayidx = getelementptr inbounds i32, i32* %6, i64 %idxprom
  %7 = load i32, i32* %arrayidx, align 4
  %8 = load i32, i32* %i, align 4
  %idxprom1 = sext i32 %8 to i64
  %9 = load i32*, i32** %goldenResults, align 8
  %arrayidx2 = getelementptr inbounds i32, i32* %9, i64 %idxprom1
  %10 = load i32, i32* %arrayidx2, align 4
  %cmp3 = icmp ne i32 %7, %10
  br i1 %cmp3, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  store i32 0, i32* %success, align 4
  %11 = load i32, i32* %i, align 4
  %12 = load i32, i32* %i, align 4
  %idxprom4 = sext i32 %12 to i64
  %13 = load i32*, i32** %vout.addr, align 8
  %arrayidx5 = getelementptr inbounds i32, i32* %13, i64 %idxprom4
  %14 = load i32, i32* %arrayidx5, align 4
  %15 = load i32, i32* %i, align 4
  %idxprom6 = sext i32 %15 to i64
  %16 = load i32*, i32** %goldenResults, align 8
  %arrayidx7 = getelementptr inbounds i32, i32* %16, i64 %idxprom6
  %17 = load i32, i32* %arrayidx7, align 4
  %call8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([70 x i8], [70 x i8]* @.str.6, i32 0, i32 0), i32 %11, i32 %14, i32 %17)
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %18 = load i32, i32* %i, align 4
  %inc = add nsw i32 %18, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  %19 = load i32, i32* %success, align 4
  %cmp9 = icmp eq i32 %19, 1
  br i1 %cmp9, label %if.then10, label %if.end12

if.then10:                                        ; preds = %for.end
  %call11 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.str.7, i32 0, i32 0))
  br label %if.end12

if.end12:                                         ; preds = %if.then10, %for.end
  %20 = load %struct._IO_FILE*, %struct._IO_FILE** %fp.addr, align 8
  %call13 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %20, i8* getelementptr inbounds ([141 x i8], [141 x i8]* @.str.8, i32 0, i32 0))
  %21 = load %struct._IO_FILE*, %struct._IO_FILE** %fp.addr, align 8
  %call14 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %21, i8* getelementptr inbounds ([101 x i8], [101 x i8]* @.str.9, i32 0, i32 0))
  %22 = load %struct._IO_FILE*, %struct._IO_FILE** %fp.addr, align 8
  %call15 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %22, i8* getelementptr inbounds ([141 x i8], [141 x i8]* @.str.8, i32 0, i32 0))
  store i32 0, i32* %i16, align 4
  br label %for.cond17

for.cond17:                                       ; preds = %for.inc39, %if.end12
  %23 = load i32, i32* %i16, align 4
  %cmp18 = icmp slt i32 %23, 64
  br i1 %cmp18, label %for.body19, label %for.end41

for.body19:                                       ; preds = %for.cond17
  %24 = load %struct._IO_FILE*, %struct._IO_FILE** %fp.addr, align 8
  %25 = load i32, i32* %i16, align 4
  %26 = load i32, i32* %i16, align 4
  %idxprom20 = sext i32 %26 to i64
  %27 = load i32*, i32** %vin0.addr, align 8
  %arrayidx21 = getelementptr inbounds i32, i32* %27, i64 %idxprom20
  %28 = load i32, i32* %arrayidx21, align 4
  %29 = load i32, i32* %i16, align 4
  %idxprom22 = sext i32 %29 to i64
  %30 = load i32*, i32** %vin1.addr, align 8
  %arrayidx23 = getelementptr inbounds i32, i32* %30, i64 %idxprom22
  %31 = load i32, i32* %arrayidx23, align 4
  %32 = load i32, i32* %i16, align 4
  %idxprom24 = sext i32 %32 to i64
  %33 = load i32*, i32** %vconn_A_to_B.addr, align 8
  %arrayidx25 = getelementptr inbounds i32, i32* %33, i64 %idxprom24
  %34 = load i32, i32* %arrayidx25, align 4
  %35 = load i32, i32* %i16, align 4
  %idxprom26 = sext i32 %35 to i64
  %36 = load i32*, i32** %vconn_B_to_C.addr, align 8
  %arrayidx27 = getelementptr inbounds i32, i32* %36, i64 %idxprom26
  %37 = load i32, i32* %arrayidx27, align 4
  %38 = load i32, i32* %i16, align 4
  %idxprom28 = sext i32 %38 to i64
  %39 = load i32*, i32** %vconn_C_to_D.addr, align 8
  %arrayidx29 = getelementptr inbounds i32, i32* %39, i64 %idxprom28
  %40 = load i32, i32* %arrayidx29, align 4
  %41 = load i32, i32* %i16, align 4
  %idxprom30 = sext i32 %41 to i64
  %42 = load i32*, i32** %vout.addr, align 8
  %arrayidx31 = getelementptr inbounds i32, i32* %42, i64 %idxprom30
  %43 = load i32, i32* %arrayidx31, align 4
  %call32 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %24, i8* getelementptr inbounds ([29 x i8], [29 x i8]* @.str.10, i32 0, i32 0), i32 %25, i32 %28, i32 %31, i32 %34, i32 %37, i32 %40, i32 %43)
  %44 = load %struct._IO_FILE*, %struct._IO_FILE** %fp_verify.addr, align 8
  %45 = load i32, i32* %i16, align 4
  %46 = load i32, i32* %i16, align 4
  %idxprom33 = sext i32 %46 to i64
  %47 = load i32*, i32** %vout.addr, align 8
  %arrayidx34 = getelementptr inbounds i32, i32* %47, i64 %idxprom33
  %48 = load i32, i32* %arrayidx34, align 4
  %call35 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %44, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str.11, i32 0, i32 0), i32 %45, i32 %48)
  %49 = load %struct._IO_FILE*, %struct._IO_FILE** %fp_verify_hex.addr, align 8
  %50 = load i32, i32* %i16, align 4
  %idxprom36 = sext i32 %50 to i64
  %51 = load i32*, i32** %vout.addr, align 8
  %arrayidx37 = getelementptr inbounds i32, i32* %51, i64 %idxprom36
  %52 = load i32, i32* %arrayidx37, align 4
  %call38 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %49, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.12, i32 0, i32 0), i32 %52)
  br label %for.inc39

for.inc39:                                        ; preds = %for.body19
  %53 = load i32, i32* %i16, align 4
  %inc40 = add nsw i32 %53, 1
  store i32 %inc40, i32* %i16, align 4
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
  %vin0.addr = alloca i32*, align 8
  %vin1.addr = alloca i32*, align 8
  %vout.addr = alloca i32*, align 8
  %i = alloca i32, align 4
  store i32* %vin0, i32** %vin0.addr, align 8
  store i32* %vin1, i32** %vin1.addr, align 8
  store i32* %vout, i32** %vout.addr, align 8
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp slt i32 %0, 64
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %idxprom = sext i32 %1 to i64
  %2 = load i32*, i32** %vin0.addr, align 8
  %arrayidx = getelementptr inbounds i32, i32* %2, i64 %idxprom
  %3 = load i32, i32* %arrayidx, align 4
  %4 = load i32, i32* %i, align 4
  %idxprom1 = sext i32 %4 to i64
  %5 = load i32*, i32** %vin1.addr, align 8
  %arrayidx2 = getelementptr inbounds i32, i32* %5, i64 %idxprom1
  %6 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %3, %6
  %7 = load i32, i32* %i, align 4
  %idxprom3 = sext i32 %7 to i64
  %8 = load i32*, i32** %vin0.addr, align 8
  %arrayidx4 = getelementptr inbounds i32, i32* %8, i64 %idxprom3
  %9 = load i32, i32* %arrayidx4, align 4
  %10 = load i32, i32* %i, align 4
  %idxprom5 = sext i32 %10 to i64
  %11 = load i32*, i32** %vin1.addr, align 8
  %arrayidx6 = getelementptr inbounds i32, i32* %11, i64 %idxprom5
  %12 = load i32, i32* %arrayidx6, align 4
  %add7 = add nsw i32 %9, %12
  %mul = mul nsw i32 %add, %add7
  %mul8 = mul nsw i32 %mul, 32
  %13 = load i32, i32* %i, align 4
  %idxprom9 = sext i32 %13 to i64
  %14 = load i32*, i32** %vout.addr, align 8
  %arrayidx10 = getelementptr inbounds i32, i32* %14, i64 %idxprom9
  store i32 %mul8, i32* %arrayidx10, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %15 = load i32, i32* %i, align 4
  %inc = add nsw i32 %15, 1
  store i32 %inc, i32* %i, align 4
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
