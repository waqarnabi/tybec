#!/bin/sh

#About:
#------
# Waqar Nabi, Glasgow, Feb 2019
# This script converts OpenCL kernel code (with channels)
# to LLVM-IR.
#
# Used as part of the TyBEC flow
# 
# Based on work done by MSc students, fall 2018, 


#Requirements:
#-------------
#llvm version: 3.8.1 (for clang and opt)
#make sure they are defined appropriately in the followign env variables
if [[ -z "${CLANG4TyBEC}" ]]; then
  echo "OLT: *Error* Environment variable CLANG4TyBEC not defined"
  exit
else
  CLANG=${CLANG4TyBEC};
fi

if [[ -z "${OPT4TyBEC}" ]]; then
  echo "OLT: *Error* Environment variable OPT4TyBEC not defined"
  exit
else
  OPT=${OPT4TyBEC};
fi


#cl file expected at input
if [ "$#" -ne 1 ]; then
    echo "OLT: Illegal number of parameters to 'ocl2llvm.sh'. One parameter (input CL filename) expected."
    exit
fi


# Strip .cl from filename
echo "OLT: Reading OpenCL Kernel file '$1'"
filename="${1%.*}"

# Copy the original file to llvm_tmp_.cl
cp $1 llvm_tmp_.cl

#copy in the llvm_ocl_stubs.c file
cp $OCL2TIRROOT/llvm_ocl_stubs.c .
# llvm_tmp_.cl is #included in llvm_tmp.c
# llvm_tmp.c has macros to undef OpenCL type attributes etc

# Run LLVM


echo "OLT: Running clang, unoptimized llvm-ir emitted as '$filename.unopt.ll'"
$CLANG -O0 -S -Wunknown-attributes -emit-llvm -c  llvm_ocl_stubs.c -o $filename.unopt.ll

echo "OLT: Running opt,  optimized llvm-ir emitted as '$filename.ll'"
$OPT -mem2reg -S $filename.unopt.ll -o $filename.ll
#$OPT -mem2reg -S $filename.unopt.ll -o $filename.opt.ll

#echo "OLT: Final clang run, llvm-ir emitted as: '$filename.ll'"
#$CLANG  -O0  -S -emit-llvm $filename.opt.ll -o $filename.ll