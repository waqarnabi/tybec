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
//CONSTANTS
#define ROWS    8
#define COLS    8
#define SIZE    (ROWS*COLS)
#define NSTEP	  1

//Floats?
//#define FLOATD

#ifndef FLOAT
  //this is default
  #define INTD
#endif

#ifdef FLOATD
typedef float data_t;
#else
typedef int data_t;
#endif

//define this if you want c to execute in a "dataflow" styles
//with a coarse-grained kernel "pipeline"
//if not defined, all computation done in the more standard C fashion
#define DATAFLOW_SYLE

//deffine this if you want to write results to file (for use in RTL verification e.g.)
//dont use for very large sizes
#define LOGRESULTS

//define this for the minimal version I am using progressive testing and debuggin
// DATAFLOW_SYLE *must* be defined for this to have effect
// for compatibiity, the same macro should be defined in the TIR code
#define MINIMAL4TEST

//-------------------------------------------------
//signatures
//-------------------------------------------------
void init	    (data_t*	 ,data_t*);
void kernel_A (data_t*	 ,data_t*	, data_t*);
void kernel_B (data_t*	 ,data_t*	);
void kernel_C (data_t*	 ,data_t*	);
void kernel_D (data_t*	 ,data_t*	);
void computeKernelFunction(data_t*, data_t*, data_t*);

void post	  (FILE*  ,FILE*  ,FILE*  ,data_t*	 ,data_t*	,data_t*  ,data_t*  ,data_t*	 ,data_t*);

//-------------------------------------------------
//measuring time
//-------------------------------------------------
#include <time.h>
clock_t start, end;
double cpu_time_used;
time_t  start_time, end_time;

//-------------------------------------------------
//main()
//-------------------------------------------------
int main(void) {
  //constants
  
  //IO vectors 
  //we want to dynamically allocate the memory for 2D arrays
  //there are multiple ways to do this in C; we use a single pointer + pointer arithmetic
  data_t* vin0;//[SIZE];
  data_t* vin1;//[SIZE];
  data_t* vout;//[SIZE]={0};
 
  vin0 = (data_t *)malloc(sizeof(data_t)*SIZE);
  vin1 = (data_t *)malloc(sizeof(data_t)*SIZE);
  vout = (data_t *)malloc(sizeof(data_t)*SIZE);

  //internal variables
  data_t* vconn_A_to_B;
  data_t* vconn_B_to_C;
  data_t* vconn_C_to_D;
  vconn_A_to_B = (data_t *)malloc(sizeof(data_t)*SIZE);
  vconn_B_to_C = (data_t *)malloc(sizeof(data_t)*SIZE);
  vconn_C_to_D = (data_t *)malloc(sizeof(data_t)*SIZE);

  //initialize variables
  init(vin0, vin1);
  
  //initialize output file
  FILE *fp, *fp_verify, *fp_verify_hex;
  fp = fopen("out.csv", "w");
  fp_verify = fopen("verifyC.dat", "w");
  fp_verify_hex = fopen("verifyChex.dat", "w");
  
  start = clock();	
  //time (&start_time);


  //time loop (repeated call to kernel)
  for (int step=0; step<NSTEP; step++) {
//---------------------    
#ifndef DATAFLOW_SYLE
//---------------------   
//this is *not* dataflow style
//i.e., this is how one would expect to write a typical C program 
    for (int lin=0; lin<SIZE; lin++) {
      //2d indices for boundary identification
      int i = lin/COLS;
      int j = lin%COLS;
      
      data_t stencilResult;
      //static boundaries; if boundary element, no stencil
      if ( (i==0) || (i==ROWS-1) || (j==0) || (j==COLS-1)) {
        stencilResult = vin0[lin];
      }
      else {
        stencilResult = ( vin0[(i-1)*COLS+(j  )] 
                        + vin0[(i+1)*COLS+(j  )] 
                        + vin0[(i  )*COLS+(j-1)] 
                        + vin0[(i  )*COLS+(j+1)] 
                        ) / 4
                        ;
      }
      
      vout[lin] = (stencilResult + vin1[lin])*(stencilResult + vin1[lin])*32;
    }//for SIZE
//---------------------    
#else
//---------------------    
//the dataflow style only makes sense if we have TyTra based pipeline already in mind
//is useful in testing C to Tytra-IR translation
//#pragma DEVICE_CODE_START
	  kernel_A	( vin0
				, vin1
				, vconn_A_to_B
				);	
				   
	  kernel_B ( vconn_A_to_B
			   , vconn_B_to_C
			   );
					 
	  kernel_C ( vconn_B_to_C
			   , vconn_C_to_D
			   );
					
	  kernel_D ( vconn_C_to_D
			   , vout
			   );

//#pragma DEVICE_CODE_END
#endif
  //#pragma TRANSFER_FROM_DEVICE vout
  }//for NSTEP (time-loop)
  
  end = clock();
  //time (&end_time);
  //double dif = difftime (end_time,start_time);
	cpu_time_used = (double)((double) (end - start)) / CLOCKS_PER_SEC;
	printf("Kernel execution took %f seconds (using clock_t)\n", cpu_time_used);
	//printf("Kernel execution took %f seconds (using time_t)\n", dif);

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
void init(data_t *vin0, data_t *vin1) {
	//init vectors
	for(int lin=0; lin<SIZE; lin++) {
	  //random int between 0 and MAXINPUT
	  //vin0[i] = rand() % MAXINPUT;
	  //vin1[i] = rand() % MAXINPUT;
	  //simple pattern of numbers
	  *(vin0+lin) = lin+1;
	  *(vin1+lin) = lin+1;
	  //vin1[i] = SIZE+i;
	}
}

//--------------------------------------
//- kernel_A
//--------------------------------------
void kernel_A ( data_t *vin0
              , data_t *vin1
              , data_t *vconn_A_to_B
              ) {
#ifdef MINIMAL4TEST
  printf("I am in MINIMAL4TEST\n");
  for (int lin=0; lin<SIZE; lin++) {
	  //vconn_A_to_B[lin] = 2*(vin0[lin] + vin1[lin]);
    int i = lin/COLS;
    int j = lin%COLS;    
    vconn_A_to_B[(i  )*COLS+(j)  ] = 
      ( vin0[(i-1)*COLS+(j  )] 
      + vin0[(i+1)*COLS+(j  )] 
      + vin0[(i  )*COLS+(j-1)] 
      + vin0[(i  )*COLS+(j+1)]
      + vin0[(i  )*COLS+(j)  ]
      + vin1[(i  )*COLS+(j)  ]
      );
    printf("vconn_A_to_B[%d] = %d, vin0[lin] = %d, vin1[%d] = %d\n", 
           lin, vconn_A_to_B[lin], lin, vin0[lin], lin, vin1[lin]);
  }
#else
  data_t stResult;
  data_t local1;
  
  //linear iteration is the default for TyTra
  for (int lin=0; lin<SIZE; lin++) {
    //2d indices for boundary identification
    int i = lin/COLS;
    int j = lin%COLS;
    
    //static boundaries; if boundary element, no stencil
    if ( (i==0) || (i==ROWS-1) || (j==0) || (j==COLS-1)) {
      stResult = vin0[lin];
    }
    //non-boundary
    else {
      stResult  = ( vin0[(i-1)*COLS+(j  )] 
                + vin0[(i+1)*COLS+(j  )] 
                + vin0[(i  )*COLS+(j-1)] 
                + vin0[(i  )*COLS+(j+1)] 
                ) / 4;
    }//else
      
    local1 = stResult + vin1[lin];
	  vconn_A_to_B[lin] = local1 + local1;
  }//for
#endif  
}//() 

//--------------------------------------
//- kernel_B
//--------------------------------------
void kernel_B ( data_t *vconn_A_to_B
              , data_t *vconn_B_to_C
              ) {
  for (int lin=0; lin<SIZE; lin++) {
	vconn_B_to_C[lin] = vconn_A_to_B[lin] + vconn_A_to_B[lin];
  }//for
}//() 

//--------------------------------------
//- kernel_C
//--------------------------------------
void kernel_C ( data_t *vconn_B_to_C
              , data_t *vconn_C_to_D
              ) {
  for (int lin=0; lin<SIZE; lin++) {
    vconn_C_to_D[lin] = vconn_B_to_C[lin] + vconn_B_to_C[lin];
  }//for
}//() 

//--------------------------------------
//- kernel_D
//--------------------------------------
void kernel_D ( data_t *vconn_C_to_D
              , data_t *vout
              ) {
  for (int lin=0; lin<SIZE; lin++) {
	vout[lin] = vconn_C_to_D[lin] + vconn_C_to_D[lin];
  }//for
}//() 

//--------------------------
//-Writing the arrays to file
//--------------------------
void post ( FILE *fp
          , FILE *fp_verify
          , FILE *fp_verify_hex
          , data_t *vin0
          , data_t *vin1
          , data_t *vconn_A_to_B
          , data_t *vconn_B_to_C
          , data_t *vconn_C_to_D
          , data_t *vout
          ) {
			
	//verify result against pure (structure-less) functin
	data_t* goldenResults;//[SIZE];
	goldenResults = (data_t *)malloc(sizeof(data_t)*SIZE);
	
	computeKernelFunction(vin0, vin1, goldenResults);
	int success=1;
	for (int lin=0; lin<SIZE; lin++) {
	  if(vout[lin]!=goldenResults[lin]){
		success=0;
#ifdef FLOATD		 
		//printf("FAILED verification:: lin = %d ; vout[lin] = %f ; goldenResults[lin] = %f \n", lin, vout[lin], goldenResults[lin]);
#else		 
		//printf("FAILED verification:: lin = %d ; vout[lin] = %d ; goldenResults[lin] = %d \n", lin, vout[lin], goldenResults[lin]);
#endif

		
	  }
	}
	if(success==1)
		printf("SUCCESSFUL verification\n");


#ifdef LOGRESULTS
	//log results for use in verification of OCL/HDL code	   
	fprintf(fp, "-------------------------------------------------------------------------------------------------------------------------------------------\n");
	fprintf(fp, "		   lin,	   vin0(lin),	   vin1(lin),		  vcon`n_A_to_B(lin),	 vconn_B_to_C(lin),	vconn_C_to_D(lin),	vout(lin)	   \n");
	fprintf(fp, "-------------------------------------------------------------------------------------------------------------------------------------------\n");
	for (int lin=0;lin<SIZE;lin++){ 
	  //pretty print for human
#ifdef FLOATD	   
	  fprintf (fp, "\t%d,\t%f,\t%f,\t%f,\t%f,\t%f,\t%f\n"
#else	   
	  fprintf (fp, "\t%d,\t%d,\t%d,\t%d,\t%d,\t%d,\t%d\n"
#endif	  
				 , lin,  vin0[lin],	 vin1[lin], vconn_A_to_B[lin],	vconn_B_to_C[lin],   vconn_C_to_D[lin],	 vout[lin]);
				 
	  //boring print for machine (hex and decimal)
#ifdef FLOATD	   
	  fprintf (fp_verify	, "%d = %f\n", lin, vout[lin]);
#else	   
	  fprintf (fp_verify	, "%d = %d\n", lin, vout[lin]);
#endif	  
	  fprintf (fp_verify_hex, "%x\n", vout[lin]);
	}
	printf("Results logged\n");

#endif
  //#ifdef LOGRESULTS
}

//-----------------------------------------------------
//computeKernelFunction
// (functionally equivalent function with no structure
//-----------------------------------------------------
void computeKernelFunction (  data_t *vin0
                            , data_t *vin1
                            , data_t *vout
                            ) {
                              
  //Won't this fail for multiple time steps?                              
  for (int step=0; step<NSTEP; step++) {   
    for (int lin=0; lin<SIZE; lin++) {
      //2d indices for boundary identification
      int i = lin/COLS;
      int j = lin%COLS;
      
      data_t stencilResult;
      //static boundaries; if boundary element, no stencil
      if ( (i==0) || (i==ROWS-1) || (j==0) || (j==COLS-1)) {
        stencilResult = vin0[lin];
      }
      else {
        stencilResult = ( vin0[(i-1)*COLS+(j  )] 
                        + vin0[(i+1)*COLS+(j  )] 
                        + vin0[(i  )*COLS+(j-1)] 
                        + vin0[(i  )*COLS+(j+1)] 
                        ) / 4
                        ;
      }
      
      vout[lin] = (stencilResult + vin1[lin])*(stencilResult + vin1[lin])*32;
    }//for                              
  }//for
 }