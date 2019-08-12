// This file should containt the macros and definitions to make the kernel file work with LLVM
// OpenCL specific keywords and types should be removed or changed
// OpenCL API functions should be defined with a stub

// This file should containt the macros and definitions to make the kernel file work with LLVM
// OpenCL specific keywords and types should be removed or changed
// Macros
#define __kernel
#define __global
#define pipe
#define read_only
#define write_only



// OpenCL API functions should be defined with a stub
// Stubs
void write_pipe (char ch00, int *data0){}
void read_pipe (char ch00, int *dataInt0){}
int get_pipe_num_packets(int a){return a;}

#include "llvm_tmp_.cl"