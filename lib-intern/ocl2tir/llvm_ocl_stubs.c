// This file should containt the macros and definitions to make the kernel file work with LLVM
// OpenCL specific keywords and types should be removed or changed
// OpenCL API functions should be defined with a stub

// This file should containt the macros and definitions to make the kernel file work with LLVM
// OpenCL specific keywords and types should be removed or changed
// Macros
#define __kernel
#define __global
#define pipe
#define channel
#define read_only
#define write_only



// OpenCL API functions should be defined with a stub
// Stubs
void write_pipe (int ch00, int *data0){}
void read_pipe (int ch00, int *dataInt0){}
int get_pipe_num_packets(int a){return a;}

__attribute__((annotate("tytra_linear_size(18)")))
#include "llvm_tmp_.cl"

//We need this attribute to define the linear sizes of arrays (assumed to be same size)
//in all functions and all streams

 