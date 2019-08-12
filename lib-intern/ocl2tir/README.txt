Waqar Nabi, Glasgow, 2019.02.13
OpenCL  to LLVM-IR to TIR (and then to TYBEC-->HDL+OCL+estimates) tool
================================================================

0. Inspired by student MSc project (that was based in Python), but entirely different approach 
(define LLVM grammar, based on recdescent, perl).

1. See ../../README.txt for setting up the tool

2. To run testcode:
> cd ../../testcode/9_ocl_withChannels_2tir
> ocl2tir.pl --i test_00.c 

3. ** Input OpenCL code Limitations **

4. General Notes:
+ See <TyBEC>\DONE_TOCONTINUE to see where I left this off. It currently works ok with testcase 0, with 
channels passed as arguments. Next is to move to ver2 with global args, and then sdx/opecl syntax rather than AOCL.


LIMITATIONS (as of 2019.02.11)
-------------------------------
+ Ocl kernel code only
+ Scalarized kernels
+ Arguments to memories can remain pointers as in opencl kernels
+ Channel arguments which connect to the same channel (in the opencl host code scope which is not visible here) MUST have EXACTLY same names. Note that this is a very artificial requirement. Normal OpenCL code 
will have no reason to follow this requirement.

+ No loops (or branches?)
+ An (ugly) hack to differentiate between input and ouput memory streams in the opencl kernel code
  + the last 3 characters of identifier of *output* streams MUST be "out" (case insensitive)
  
+ tytra_linear_size attribute
__attribute__((annotate("tytra_linear_size(18)")))
  //This attribute specifies size of arrays accessed by the 
  //arguments in this flat function. 
  //It is required to generate (and evaluate) IR code 
  //for full flow, this information would be available to the program
  //For standalone functions, we need this annotation (e.g. for size=18)


TRANSLATION NOTES
-----------------

+ There is no need of separate load and store instructions in TIR
as we never access memory directly in an instruction. So we just
use LOAD to represent what one may call load, store, or simply
register-register transfer

+ 

+ Rules for translating LLVM instructions to TIR instructions
- Compute     : always have an equivalent in TIR
- write_pipe  : always have an equivalent in TIR
- read_pipe   : only enter in LUT, no equivalent in TIR
- load        : only enter in LUT, no equivalent in TIR
                (load instruction always implies a transfer)
- store       : if dest *is* an argument,
                  then equivalent is a LOAD in TIR
                else
                  only enter in LUT, no equivalent TIR




