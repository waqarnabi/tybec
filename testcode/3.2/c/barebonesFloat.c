//*****************************************!
// A simple mock example
// for prototyping
//
// This instance is for testing
// smart buffering features
// and is based on example used
// in the HLPGPU-paper
//
// Author: S Waqar Nabi
//
// Created: 2016.12.23
//
// Modifications:
//
//*****************************************!

#include <stdio.h>
#include <stdlib.h>

//CONSTANTS
#define SIZE      128
#define NSTEP     1

//Floats?
#define FLOATD

#ifndef FLOATD
  //this is default
  #define INTD
#endif

#ifdef FLOATD
typedef float data_t;
#else
typedef int data_t;
#endif




//-------------------------------------------------
//signatures
//-------------------------------------------------
void init     (data_t[]  ,data_t[]  );
void kernel_A (data_t[]  ,data_t[]  ,data_t[]);
void kernel_B (data_t[]  ,data_t[]  );
void kernel_C (data_t[]  ,data_t[]  );
void kernel_D (data_t[]  ,data_t[]  );
void computeKernelFunction(data_t[], data_t[], data_t[]);

void post     (FILE*  ,FILE*  ,FILE*  ,data_t[]  ,data_t[]  ,data_t[]  ,data_t[]  ,data_t[]  ,data_t[]);

//-------------------------------------------------
//main()
//-------------------------------------------------
int main(void) {
  //constants
  
  //IOs
  data_t vin0[SIZE];
  data_t vin1[SIZE];
  data_t vout[SIZE]={0};
 
  //internal variables
  data_t vconn_A_to_B[SIZE] ={0};
  data_t vconn_B_to_C[SIZE] ={0};
  data_t vconn_C_to_D[SIZE] ={0};

  //initialize variables
  init(vin0, vin1);
  
  //initialize output file
  FILE *fp, *fp_verify, *fp_verify_hex;
  fp = fopen("out.csv", "w");
  fp_verify = fopen("verifyC.dat", "w");
  fp_verify_hex = fopen("verifyChex.dat", "w");
  
  
  //kernels are called repeatedly, .e.g in a time loop
//#pragma TRANSFER_2_DEVICE vin0    
//#pragma TRANSFER_2_DEVICE vin1
  for (int i=0; i<NSTEP; i++) {
//#pragma DEVICE_CODE_START
    kernel_A  ( vin0
              , vin1
              //, vconn_A_to_B
              , vout
              ); 
/* 
    kernel_B ( vconn_A_to_B
             , vconn_B_to_C
             );
                   
    kernel_C ( vconn_B_to_C
             , vconn_C_to_D
             );
                  
    kernel_D ( vconn_C_to_D
             , vout
             );
*/

//#pragma DEVICE_CODE_END
  }//for (time-loop)
//#pragma TRANSFER_FROM_DEVICE vout
  
post  ( fp
      , fp_verify
      , fp_verify_hex
      , vin0
      , vin1
      , vconn_A_to_B
      , vconn_B_to_C
      , vconn_C_to_D
      , vout
      );

  return 0;
}//main()

//-------------------------------------------------
//init()
//-------------------------------------------------
void init(data_t vin0[], data_t vin1[]) {
    //init vectors
    for(int i=0; i<SIZE; i++) {
      //random int between 0 and MAXINPUT
      //vin0[i] = rand() % MAXINPUT;
      //vin1[i] = rand() % MAXINPUT;
      
      //simple pattern of numbers
#ifdef FLOATD      
      vin0[i] = 3.14+i+1;
      vin1[i] = 3.14+i+1;
#else
      vin0[i] = i+1;
      vin1[i] = i+1;
#endif  
    }
}

//--------------------------------------
//- kernel_A
//--------------------------------------
void kernel_A ( data_t vin0[]
              , data_t vin1[]
              , data_t vconn_A_to_B[]
              ) {
  for (int i=0; i<SIZE; i++) {
//    vconn_A_to_B[i] = vin0[i] + vin1[i];
      vconn_A_to_B[i]= vin0[i] + vin1[i];
      //data_t local1 = vin0[i] + vin1[i];
      //vconn_A_to_B[i] = local1 + local1;
  }//for
}//() 

//--------------------------------------
//- kernel_B
//--------------------------------------
void kernel_B ( data_t vconn_A_to_B[]
              , data_t vconn_B_to_C[]
              ) {
  for (int i=0; i<SIZE; i++) {
    vconn_B_to_C[i] = vconn_A_to_B[i] + vconn_A_to_B[i];
  }//for
}//() 
//--------------------------------------
//- kernel_C
//--------------------------------------
void kernel_C ( data_t vconn_B_to_C[]
              , data_t vconn_C_to_D[]
              ) {
  for (int i=0; i<SIZE; i++) {
    vconn_C_to_D[i] = vconn_B_to_C[i] * vconn_B_to_C[i];
    //vconn_C_to_D[i] = vconn_B_to_C[i] + vconn_B_to_C[i];
  }//for
}//() 


//--------------------------------------
//- kernel_D
//--------------------------------------
void kernel_D ( data_t vconn_C_to_D[]
              , data_t vout[]
              ) {
  for (int i=0; i<SIZE; i++) {
    vout[i] = vconn_C_to_D[i] + vconn_C_to_D[i];
  }//for
}//() 


//--------------------------
//-Writing the arrays to file
//--------------------------
void post ( FILE *fp
          , FILE *fp_verify
          , FILE *fp_verify_hex
          , data_t vin0[]
          , data_t vin1[]
          , data_t vconn_A_to_B[]
          , data_t vconn_B_to_C[]
          , data_t vconn_C_to_D[]
          , data_t vout[]
          ) {
            
    //verify result against pure (structure-less) functin
    data_t goldenResults[SIZE];
    computeKernelFunction(vin0, vin1, goldenResults);
    int success=1;
    for (int i=0; i<SIZE; i++) {
      if(vout[i]!=goldenResults[i]){
        success=0;
#ifdef FLOATD        
        printf("FAILED verification:: i = %d ; vout[i] = %f ; goldenResults[i] = %f \n", i, vout[i], goldenResults[i]);
#else        
        printf("FAILED verification:: i = %d ; vout[i] = %d ; goldenResults[i] = %d \n", i, vout[i], goldenResults[i]);
#endif

        
      }
    }
    if(success==1)
        printf("SUCCESSFUL verification\n");


    //log results for use in verification of OCL/HDL code      
    fprintf(fp, "-------------------------------------------------------------------------------------------------------------------------------------------\n");
    fprintf(fp, "          i,      vin0(i),    vin1(i),       vcon`n_A_to_B(i),  vconn_B_to_C(i),   vconn_C_to_D(i),    vout(i)    \n");
    fprintf(fp, "-------------------------------------------------------------------------------------------------------------------------------------------\n");
    for (int i=0;i<SIZE;i++){ 
      //pretty print for human
#ifdef FLOATD      
      fprintf (fp, "\t%d,\t%f,\t%f,\t%f,\t%f,\t%f,\t%f\n"
#else      
      fprintf (fp, "\t%d,\t%d,\t%d,\t%d,\t%d,\t%d,\t%d\n"
#endif    
                 , i,  vin0[i],  vin1[i], vconn_A_to_B[i],  vconn_B_to_C[i],   vconn_C_to_D[i],  vout[i]);
                 
      //boring print for machine (hex and decimal)
#ifdef FLOATD      
      //fprintf (fp_verify    , "%f\n", vout[i]);
      fprintf (fp_verify    , "%f\n", goldenResults[i]);
#else                         
      fprintf (fp_verify    , "%d\n", vout[i]);
#endif    
      fprintf (fp_verify_hex,"%x\n", *(int*)&vout[i]);
      
      //fprintf (fp_verify_hex, "%x\n", vout[i]);
      //fprintf (fp_verify_hex,"%x\n", *(int*)&goldenResults[i]);
      //fprintf (fp_verify_hex,"%lx\n", goldenResults[i]);
    }
    printf("Results logged\n");
}

//-----------------------------------------------------
//computeKernelFunction
// (functionally equivalent function with no structure
//-----------------------------------------------------
void computeKernelFunction ( data_t vin0[]
                           , data_t vin1[]
                           , data_t vout[]
                           ) {
   for (int i=0; i<SIZE; i++) {
    //original
    //vout[i] = (vin0[i] + vin1[i])*(vin0[i] + vin1[i])*32;
    vout[i] = (vin0[i] + vin1[i]);
    //vout[i] = (vin0[i] + vin1[i])*2*2*2*2;

    
    //vout[i] = (vin0[i] + vin1[i])*16;
    //vout[i] = (vin0[i] + vin1[i])*(vin0[i] + vin1[i])*(vin0[i] + vin1[i])*(vin0[i] + vin1[i])*32;
    //vout[i] = 2*2*(vin0[i] + vin1[i]);
   }//for
 
 }
