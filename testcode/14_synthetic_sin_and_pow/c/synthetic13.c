//This is not really complete 1dshallow code
// I am just using this to experiment c-->llvmir--> tir 
// conversions of various arithmetic functions

#define data_t float

#include "math.h"
#define Apadle 0.1f
#define Tpadle 0.1f
#define pi     3.14f

__attribute__((annotate("tytra_linear_size(1024)")))
void oned_shallow   ( data_t  time
                    , data_t* eta
                    )
{              
  *eta = Apadle*sin(2.0f*pi*time/Tpadle);
}//()
