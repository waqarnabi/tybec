#!/bin/sh

#I am now using "module" to do all this, so shouldn't be needed (on Bolama at least)

#MAKE SURE this is run from the Tybec root directory (that contains tybec.pl)

#//1//
#root directory for TyBEC
export TyBECROOTDIR=$(pwd)
export PATH=$PATH:$TyBECROOTDIR

#//2//
#root directory for c2llvm2tir4flat
export C2LLVM2TIR4FLATROOT=$TyBECROOTDIR/lib-intern/c2llvm2tir4flat
export PATH=$PATH:$C2LLVM2TIR4FLATROOT

#//3//
#Perl libraries used, internal and external, are included
#in the repository of this project for code portability and min hassle
#Just make sure Perl looks in the appropriate folder, as follows
export PERL5LIB="$TyBECROOTDIR/lib-intern:$TyBECROOTDIR/lib-extern"

#//4//
#root directory for OCL2TIR (OpenCL kernel files with channels --> TIR)
export OCL2TIRROOT=$TyBECROOTDIR/lib-intern/ocl2tir
export PATH=$PATH:$OCL2TIRROOT
