#!/bin/sh

#About:
#------
# Waqar Nabi, Glasgow, Feb 2019
# Integrating OpenCL to TyTra IR (via CLANG+OPT) with TyBEC
# Based on work done by MSc students, fall 2018, 


#Requirements:
#-------------
#llvm version: 3.8.1 (for clang and opt)
#python version: 3.0+
#tybec version: not fixed yet
#sdx versin: 2017.?

#cl file expected at input
if [ "$#" -ne 1 ]; then
    echo "TY: Illegal number of parameters. One parameter (input CL filename) expected."
    exit
fi


# Strip .cl from filename
echo "TY: Reading OpenCL Kernel file '$1'"
filename="${1%.*}"

# Copy the original file to llvm_tmp_.cl
cp $1 llvm_tmp_.cl

#copy in the llvm_ocl_stubs.c file
cp $OCL2TIRROOT/llvm_ocl_stubs.c .
# llvm_tmp_.cl is #included in llvm_tmp.c
# llvm_tmp.c has macros to undef OpenCL type attributes etc

# Run LLVM
# Make sure the LLVM version is 3.8
echo "TY: Running clang, unoptimized llvm-ir emitted as 'llvm_tmp.unopt.ll'"
clang -O0 -S -Wunknown-attributes -emit-llvm -c  llvm_ocl_stubs.c -o llvm_tmp.unopt.ll

echo "TY: Running opt,  optimized llvm-ir emitted as 'llvm_tmp.opt1.ll'"
opt -mem2reg -S llvm_tmp.unopt.ll -o llvm_tmp.opt1.ll

echo "TY: Final clang run, llvm-ir emitted as: '$filename.ll'"
clang  -O0  -S -emit-llvm llvm_tmp.opt1.ll -o $filename.ll

echo "TY: Calling llvm-IR to tir translator (python script), TIRl emitted as: '$filename.tirl'"
python $OCL2TIRROOT/llvm2tir.py kernels_channels.ll $filename

echo "TY: Copying '$filename.tirl' to ../tir"
cp $filename.tir ../tir
cd ../tir

echo "TY: Calling TyBEC on generated TIRL file, output in '../tir/$filename.TybecBuild'"
tybec.pl --i $filename.tir --g --obd ../tir/$filename.TybecBuild


# Rename the final file
#mv $1.ll $filename.ll
