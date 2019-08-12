C to LLVM-IR to TIR (and then to TYBEC-->HDL+OCL+estimates) tool
================================================================

1. See ../../README.txt for setting up the tool

2. To run testcode:
> cd ../../testcode/2_c2llvm2tir_flatFuncs
> c2llvm2tir4flat.pl --i test_00.c 

3. ** Input C code Limitations **
//Requirements:
//Flat, ***SINGLE**  function, no branches or loops, only interger arithmethic
//Inputs are *always* passed by value
//Output are *always* accessed by reference
//Integer only 
//No scalars

//Assumptions:
//All arguments are "streaming" variables for arrays in device global memory

//This attribute specifies size of arrays accessed by the 
//arguments in this flat function. 
//It is required to generate (and evaluate) IR code 
//for full flow, this information would be available to the program
//For standalone functions, we need this annotation (e.g. for size=18)
__attribute__((annotate("tytra_linear_size(18)")))





