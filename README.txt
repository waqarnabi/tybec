NOTE: tybec is _not_ currently ready for public release. This is currently an active, on-going project.
Please contact me if you are taking it for a spin and face any issues: syed.nabi@glasgow.ac.uk

#----------------------
#Environment Variables:
#----------------------

## BOLAMA-specific comment: As of 2019.04.01, these env variables are mamanged via "module" rather than in the bashrc

//0//
The following are all set in bashrc on BOLAMA. 
On other machines, run setupTybec.sh from the directory that contains tybec.pl
(That is,  <this-directory>)


//1//
#root directory for TyBEC
export TyBECROOTDIR=<this-directory>
export PATH=$PATH:$TyBECROOTDIR

//2//
#root directory for c2llvm2tir4flat
export C2LLVM2TIR4FLATROOT=$TyBECROOTDIR/lib-intern/c2llvm2tir4flat
export PATH=$PATH:$C2LLVM2TIR4FLATROOT

//3//
#Perl libraries used, internal and external, are included
#in the repository of this project for code portability and min hassle
#Just make sure Perl looks in the appropriate folder, as follows
export PERL5LIB="$TyBECROOTDIR/lib-intern:$TyBECROOTDIR/lib-extern"

//4//
#root directory for OCL2TIR (OpenCL kernel files with channels --> TIR)
export OCL2TIRROOT=$TyBECROOTDIR/lib-intern/ocl2tir
export PATH=$PATH:$OCL2TIRROOT

//5//
#Executables (including path if not in $PATH) for clang and opt
export CLANG4TyBEC="clang"
export OPT4TyBEC="opt-3.8.1"


#----------------------
#DEPENDENCIES
#----------------------

//1//
gcc (C pre-processor)

//2//
Perl ver 5+
(with additional libraries, see #3 in prev section)

//3//
graphviz (for dot)

//4// 
#for ocl2tir and c2llvm2tir4flat
llvm version: 3.8.1 (for clang and opt)

//5//
#for ocl2tir
bash (tested with GNU bash, version 4.1.2)

//6//
#for SDX 
python version 2.X 
(3.X fails on a python script $(COMMON_REPO)/utility/parsexpmf.py used in Make function device2sandsa)

// 7 //
For FPGA shell integration, synthesis, and execution, the F1 instances on AWS are presumed.
+ SDx version: 2018.2
+ Target hardware platform: xilinx_aws-vu9p-f1-04261818_dynamic_5_0

#----------------------
#To run:
#----------------------
>> tybec.pl --h

+ Not all flags are currently active/integrated. The most important flag for this version is --iov, for vectorization)
+ This current release 






 


