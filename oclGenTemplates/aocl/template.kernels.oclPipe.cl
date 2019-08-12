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

// Declaring the channels
<declareChannels>

//=========================================
// IO kernels
//=========================================
kernel void data_in (
  <globalInputsIOKernel>
) {
  int lincount;  
  for (lincount=0; lincount<=SIZE; lincount++) {
<readGlobalArrays>
<wChannelDataInKernel>
  }
}//()


kernel void data_out  (
  <globalOutputsIOKernel>
) {
  int lincount;  
  for (lincount=0; lincount<=SIZE; lincount++) {
<rChannelDataOutKernel>
<writeGlobalArrays>
    }
  }     
  
//=========================================
// Compute Kernels
//=========================================

<computeKernelsAll>

#endif