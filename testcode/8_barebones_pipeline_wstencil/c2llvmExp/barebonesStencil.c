//Testinn how LLVM treats index (boundary) testing conditions


#define ROWS    1024
#define COLS    1024

int computeKernelFunction (   int lin
                              ,int vin0
                              ,int vin1
                            ) {
                              
      //2d indices for boundary identification
      int i = lin/COLS;
      int j = lin%COLS;
      
      int stencilResult;
      //static boundaries; if boundary element, no stencil
      if ( (i==0) || (i==ROWS-1) || (j==0) || (j==COLS-1)) {
        stencilResult = vin0;
      }
      else {
        stencilResult = vin1;
      }
      
      return (stencilResult);// + vin1[lin])*(stencilResult + vin1[lin])*32;
 }
