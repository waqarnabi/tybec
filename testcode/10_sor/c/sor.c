//This is not really complete SOR code
// I am just using this to experiment c-->llvmir--> tir 
// conversions of various arithmetic functions

#define ROWS    53
#define COLS    ROWS

#define data_t float

#include "math.h"

//------------------------------------------
// dyn1() - the dynamics (1 of 2)
//------------------------------------------
__attribute__((annotate("tytra_linear_size(1024)")))
void sorKernel  ( data_t  in1
                , data_t  in2
                , data_t* out
                )
{              
  *out = pow(in1, in2);
}//()
