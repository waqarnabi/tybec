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
#define SIZE        256
#define NSTEP     1
#define MAXINPUT  250

//-------------------------------------------------
//signatures
//-------------------------------------------------
void init(int vin0[], int vin1[], int* s0, int* sconn000);

void kernel_map_A ( int vin0[]
                  , int vin1[]
                  , int vconn0[]
                  , int vconn1[]
                  );
                  
void kernel_unzip_A ( int vconn0[]
                    , int vconn1[]
                    , int vconn00[]
                    , int vconn10[]
                    );
                  
void kernel_map_B ( int vconn10[]
                  , int vconn100[]
                  );  

void kernel_fold_A  ( int vconn00[]
                    , int *sconn000
                    );        
void kernel_map_C ( int vconn100[]
                  , int vout[]
                  , int *sconn000
                  );
void post ( FILE *fp
          , int vin0[]
          , int vin1[]
          , int s0
          , int vconn0[]
          , int vconn1[]
          , int vconn00[]
          , int vconn10[]
          , int vconn100[]
          , int sconn000
          , int vout[]
          );

//-------------------------------------------------
//main()
//-------------------------------------------------
int main(void) {
  //constants
  
  //IOs
  int vin0[SIZE];
  int vin1[SIZE];
  int vout[SIZE]={0};
  int s0;

  //internal variables
  int vconn0[SIZE]  ={0};
  int vconn1[SIZE]  ={0};
  int vconn00[SIZE] ={0};
  int vconn10[SIZE] ={0};
  int vconn100[SIZE]={0};
  int sconn000    =0  ;

  //initialize variables
  init(vin0, vin1, &s0, &sconn000);
  
  //initialize output file
  FILE *fp;
  fp = fopen("out.dat", "w");
  
  //kernels are called repeatedly, .e.g in a time loop
  for (int i=0; i<NSTEP; i++) {
  kernel_map_A ( vin0
               , vin1
               , vconn0
               , vconn1
               );  
               
  kernel_unzip_A ( vconn0
                 , vconn1
                 , vconn00
                 , vconn10
                 );
                 
  kernel_map_B  ( vconn10
                , vconn100
                );
                
  kernel_fold_A (vconn00
                ,&sconn000
                );

  kernel_map_C ( vconn100
               , vout
               , &sconn000
               );
}//for (time-loop)
  
post  ( fp
      , vin0
      , vin1
      , s0
      , vconn0
      , vconn1
      , vconn00
      , vconn10
      , vconn100
      , sconn000
      , vout
      );
    return 0;
}//main()

//-------------------------------------------------
//init()
//-------------------------------------------------
void init(int vin0[], int vin1[], int* s0, int* sconn000) {
    //init scalar
    *s0       = 3 ; //!--input scalar
    *sconn000 = *s0; //!--internal (accumulation) scalar
    
    //init vectors
    for(int i=0; i<SIZE; i++) {
      //random int between 0 and MAXINPUT
      vin0[i] = rand() % MAXINPUT;
      vin1[i] = rand() % MAXINPUT;
    }
}
//
void f_1( int vin0_i,int vin0_im1,int  vin0_ip1,int vin1_i, int*  vconn0_i,int* vconn1_i, int i) {
 //boundary, pass through
    if ( (i==0) || (i==SIZE-1) ) {
      *vconn0_i = vin0_i;
      *vconn1_i = vin1_i;
    }
  //non-boundary
    else {
      *vconn0_i = vin0_i + vin0_im1 + vin0_ip1 + vin1_i ;
      *vconn1_i = vin0_i + vin0_im1 + vin0_ip1 * vin1_i ;
    }//else
    
}
//--------------------------------------
//- kernel_map_A
//--------------------------------------
void kernel_map_A ( int vin0[]
                  , int vin1[]
                  , int vconn0[]
                  , int vconn1[]
                  ) {
  for (int i=0; i<SIZE; i++) {
      f_1(vin0[i] , vin0[i-1] , vin0[i+1] , vin1[i], &vconn0[i], &vconn1[i], i);
  }//for
}//() 

//--------------------------------------
//- kernel_unzip_A
//--------------------------------------
void kernel_unzip_A ( int vconn0[]
                    , int vconn00[]
                    , int vconn10[]
                    , int vconn1[]
                    ) {
  for (int i=0; i<SIZE; i++) {
   vconn00[i] = vconn0[i];
   vconn10[i] = vconn1[i];
  }
} 

//--------------------------------------
//- kernel_map_B
//--------------------------------------
void kernel_map_B ( int vconn10[]
                  , int vconn100[]
                  ) {
  for (int i=0; i<SIZE; i++) {
   vconn100[i] = vconn10[i] + vconn10[i];
  }
}

//--------------------------------------
//- kernel_fold_A
//--------------------------------------
void kernel_fold_A  ( int vconn00[]
                    , int *sconn000
                  ) {
  for (int i=0; i<SIZE; i++) {
   *sconn000 = vconn00[i] + *sconn000;
  }
}

//--------------------------------------
//- kernel_map_C
//--------------------------------------
void kernel_map_C ( int vconn100[]
                  , int vout[]
                  , int *sconn000
                  ) {
  for (int i=0; i<SIZE; i++) {
   vout[i] = *sconn000 + vconn100[i];
  }
}
  
//--------------------------
//-Writing the arrays to file
//--------------------------
void post ( FILE *fp
          , int vin0[]
          , int vin1[]
          , int s0
          , int vconn0[]
          , int vconn1[]
          , int vconn00[]
          , int vconn10[]
          , int vconn100[]
          , int sconn000
          , int vout[]
          ) {
    fprintf(fp, "-------------------------------------------------------------------------------------------------------------------------------------------\n");
    fprintf(fp, "          i,      vin0(i),    vin1(i),       s0,     vconn0(i),  vconn1(i),   vconn00(i), vconn10(i), vconn100(i), sconn000,    vout(i)    \n");
    fprintf(fp, "-------------------------------------------------------------------------------------------------------------------------------------------\n");
    for (int i=0;i<SIZE;i++){ 
      fprintf (fp, "\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n"
                 , i,  vin0[i],  vin1[i],   s0,  vconn0[i],  vconn1[i], vconn00[i],  vconn10[i],  vconn100[i],  sconn000,  vout[i]);
    }
}
