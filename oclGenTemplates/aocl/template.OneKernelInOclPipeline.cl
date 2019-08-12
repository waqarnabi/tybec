//-----------------------------------------
// :: <kernelName> ::
//-----------------------------------------

// Computation function if OCL only
//-----------------------------------------
#ifndef AOCLIB
  device_t  cl_<kernelName>_aocOnly(  
     <kernelAocOnlyArgs>
    ,int i
    ){      
    return( <aocKernel> );
}//()
#endif

// HDL + OpenCL for <kernelName>
//-----------------------------------------
// Using HDL library components
kernel void cl_<kernelName>_lib ( 
<kernelArgs>
  ){
 
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
    device_t tempResult = <kernelName>_lib(
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
    device_t tempResult =  cl_<kernelName>_aocOnly(
       <inputargs2aocKernel>
      ,lincount
    );

    /// output branch ///
    vout[lincount]=tempResult;
#endif      
  }//for
}

