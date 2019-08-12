// =============================================================================
// Company              : Unversity of Glasgow, Comuting Science
// Template Author      : Syed Waqar Nabi
//
// Project Name         : TyTra
//
// Target Devices       : Altera FPGA OpenCL device
//
// Generated Design Name: <design_name>
// Generated Module Name: <module_name> 
// Generator Version    : <gen_ver>
// Generator TimeStamp  : <timeStamp>
// 
// Dependencies         : <dependencies>
//
// 
// =============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// A template OCL kernel files that instantiate HDL libraries (for TyTra)
// (TyBEC)
//
// ============================================================================= 
// Before compiling this kernel, create wn_lib.aoclib with:
//    perl make_lib.pl
// Then compile this kernel with:
//    aoc -l wn_lib.aoclib -L lib1 -I lib1 example1.cl

#ifdef AOCLIB
  #include "hdl_lib.h"
#endif  


#ifdef AOCLIB
typedef <deviceDataType> device_t;
typedef <scalarDataType> scalar_t;
#else
//no vector data type if aoc-only
typedef <scalarDataType> device_t;
typedef <scalarDataType> scalar_t;
#endif

#define IN_OUT_LAT <latency>
#define SIZE       <size>
#define VECT       <ioVect>


#ifndef AOCLIB
  // AOCL only function signature
device_t kernel_aocOnly(  
     <kernelAocOnlyArgs>
    ,int lincount
);  
#endif

// Using HDL library components
kernel void cl_func_lib ( 
     <globalmemoryargs>) {
 
  int lincount;
#ifdef AOCLIB  
  //with hdl lib, vectorization is possible, and we have to explicitly
  //handle the in-out latency
  //also, we need to gather inputs (scalars) from arrays
  for (lincount = 0; lincount < ((SIZE/VECT) + IN_OUT_LAT); lincount++) {
    int outCount  = lincount - (IN_OUT_LAT) + 1;  

    /// input branch ///    
    <gatherinputs>
    <scFromVectIn>
    
    /// Call the kernel ///
    device_t tempResult = func_lib(
       <inputargs2func_lib>    );
    
    /// output branch ///
    if (outCount >= 0) {
      <output>[outCount]=tempResult;
    } 
#else
  //for aoc-only, no vectorization, nor any need to handle latency    
  //and array pointers are passed directly to the kernel
  for (lincount = 0; lincount < SIZE; lincount++) {
    int outCount  = lincount;  

    /// Call the kernel ///
    device_t tempResult =  kernel_aocOnly(
       <inputargs2aocKernel>
      ,lincount
    );

    /// output branch ///
    vout[lincount]=tempResult;
#endif      
  }//for
}


//-----------------------------------------
// OCL only
//-----------------------------------------
#ifndef AOCLIB
  device_t  kernel_aocOnly(  
     <kernelAocOnlyArgs>
    ,int i
    ){      
    return( <aocKernel> );
}//()

#endif