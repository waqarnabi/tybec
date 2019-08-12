//--------------------------------------------------
// WN, Glasgow, Dec 2017
// Toy C code, single **flat** functions, 
// to test this flow:
// c-->llvm-->tir-->tybec-->estimates
//                      |-->hdl+ocl solution
//--------------------------------------------------

//--------------------------------------------------
//- kernel_A from testcode/0_barebones (Scalarized)
//--------------------------------------------------

//Requirements:
//Flat function, no branches or loops
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
//For standalone functions, we need this annotation
__attribute__((annotate("tytra_linear_size(18)")))
void kernel_A ( int  vin0_i
              , int  vin1_i
              , int*  vconn_A_to_B_i
              ) 
{

  //Equivalent block for single statement next
  int local1 = vin0_i + vin1_i;
  int local2 = vin0_i - vin1_i;
  int local3 = vin0_i * vin1_i;
  *vconn_A_to_B_i = local1 + local2 + local3;

  //single equivalent statement
  //*vconn_A_to_B_i = (vin0_i + vin1_i) + (vin0_i - vin1_i) + (vin0_i * vin1_i);
}//()


//The pragma is needed to unset diagnostic that ignores unknowon attributes
//#pragma clang diagnostic ignored "-Wunknown-attributes"
//#pragma clang diagnostic ignored "-Wignored-attributes"