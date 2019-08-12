#!/bin/bash
clang -O0 -S -Wunknown-attributes -emit-llvm $1 -o llvmir.ll
opt -S -mem2reg llvmir.ll -o llvmir.opt.ll
