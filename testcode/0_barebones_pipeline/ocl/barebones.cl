//-----------------
//Problem Size
//-----------------
//Make sure it matches size in main.cpp
#define SIZE 1//  should really be very large

//comment if you don't want to see debug messages
//#define DEBUG

// This file should containt the macros and definitions to make the kernel file work with LLVM
// OpenCL specific keywords and types should be removed or changed
// Macros
// ... your code here ...
// #define __kernel
// #define __global
// #define pipe
// #define read_only
// #define write_only
// 
// 
// 
// // OpenCL API functions should be defined with a stub
// // Stubs
// // ... your code here ...
// void write_pipe (char ch00, int *data0){}
// void read_pipe (char ch00, int *dataInt0){}
// int get_pipe_num_packets(int a){return a;}



//------------------------------------------
// Read memory and compute 
//------------------------------------------
__kernel void kernel_A  (  int ka_vin0
                         , int ka_vin1
                         , write_only pipe int ka_vout
                         ) {
    int data0, data1;
    data0 = ka_vin0;
    data1 = ka_vin1;
    
	  int local1 = data0 + data1;
    
    //write to channel
    write_pipe(ka_vout, &local1);
}//()


//----------------------
//kernel_B
//----------------------
__kernel void kernel_B (
                         read_only  pipe int kb_vin
                        ,write_only pipe int kb_vout
                        ) {
    int dataIn0, dataOut;
    read_pipe(kb_vin, &dataIn0);
    
    //converting into a non-compute function
    //dataOut = dataIn0 + dataIn0;
    dataOut = dataIn0;
    
    write_pipe(kb_vout, &dataOut);

}//()


//----------------------
//kernel_C
//----------------------
__kernel void kernel_C (
                         read_only  pipe int kc_vin
                        ,write_only pipe int kc_vout
                        ) {
    int dataIn0, dataOut;
    read_pipe(kc_vin, &dataIn0);
    dataOut = dataIn0 * dataIn0;
    write_pipe(kc_vout, &dataOut);
}//()


//----------------------
//kernel_D
//----------------------
__kernel void kernel_D (
                         read_only pipe int kd_vin
                        ,int* kd_vout
                        ) {
    int dataIn0, dataOut;
    read_pipe(kd_vin, &dataIn0);
    dataOut = dataIn0 + dataIn0;
    *kd_vout = dataOut;
}//()