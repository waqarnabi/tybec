// =============================================================================
// Company      : Unversity of Glasgow, Comuting Science
// Author:        Syed Waqar Nabi
// 
// Create Date  : 2019.06.19
// Project Name : TyTra
//
// Dependencies : 
//
// Revision     : 
// Revision 0.01. File Created
// 
// Conventions  : 
// =============================================================================
//
// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// Coriolis acceleration kernel, manually written in C
// to use for conversion to TIR via LLVM-IR
// =============================================================================

#include "math.h"
#include "stdio.h"

#define IMAX  8
#define JMAX  8
#define NTOT  1

#define MODE  1

#define data_t float



//----------------------------------------------------------------------------
// lazy globals
//----------------------------------------------------------------------------
  float dt,freq,f,pi,alpha,beta,time;
  const int mode = MODE;
  const int imax = IMAX;
  const int jmax = JMAX; //I am introucing a 2D space grid that is not there in the original fortran
  const int ntot = NTOT; //total number of time interation steps

//---------------------------------------------------------------------------
// main
//----------------------------------------------------------------------------
//quick and dirty, written in fortran-95 style with globals
void main (void) {

  //global constants
  pi    = 4.0*atan(1.0)       ;// this calculates Pi  
  freq  = -2.*pi/(24.*3600.)  ;//
  f     = 2*freq              ;// Coriolis parameter
  dt    = 24.*3600./200.      ;// time step
  
  // parameters for semi-implicit scheme
  alpha = f*dt            ;//
  beta = 0.25*alpha*alpha ;//
 
  //print constant values for use in TIR/HDL
  printf("alpha = %f\n" , alpha);
  printf("beta = %f\n"  , beta);
  printf("dt = %f\n"    , dt);
 
  //locals
  data_t u[imax][jmax],v[imax][jmax],un[imax][jmax],vn[imax][jmax],x[imax][jmax],y[imax][jmax],xn[imax][jmax],yn[imax][jmax];  
  
    for (int i = 0; i < imax; i++) {
      for (int j = 0; j < jmax; j++) {
        //x[index0] = realtobitsSingle(3.14+index0+1);
        //u[index0] = realtobitsSingle(3.14+index0+1);
        //y[index0] = realtobitsSingle(3.14+index0+1);
        //v[index0] = realtobitsSingle(3.14+index0+1);        
        u[i][j] = 3.14+(j+i*jmax)+1;
        v[i][j] = 3.14+(j+i*jmax)+1;
        x[i][j] = 3.14+(j+i*jmax)+1;
        y[i][j] = 3.14+(j+i*jmax)+1;
      }
    }
  

  
  //files
  FILE *fp;
  fp=fopen("output.txt", "w");  
  
  //!**** start of iteration loop ****
  for (int n =0; n < ntot; n++) {
  //!*********************************
    time = n*dt;
    //space loop
    for (int i = 0; i < imax; i++) {
      for (int j = 0; j < jmax; j++) {
        //! velocity predictor
        if (mode == 1) {
          un[i][j] = (u[i][j]*(1-beta)+alpha*v[i][j])/(1+beta);
          vn[i][j] = (v[i][j]*(1-beta)-alpha*u[i][j])/(1+beta);
        }
        else {
          un[i][j] = cos(alpha)*u[i][j]+sin(alpha)*v[i][j];
          vn[i][j] = cos(alpha)*v[i][j]-sin(alpha)*u[i][j];
        }
        
        //! predictor of new location
        xn[i][j] = x[i][j] + dt*un[i][j]/1000;
        yn[i][j] = y[i][j] + dt*vn[i][j]/1000;
        
        //! updates for next time step 
        u[i][j] = un[i][j];
        v[i][j] = vn[i][j];
        x[i][j] = xn[i][j];
        y[i][j] = yn[i][j];
        
        //! data output
        //printf ("x[%d][%d] = %f, y[%d][%d] = %f, time = %f\n",i,j,x[i][j],i,j,y[i][j],time);
        fprintf (fp, "x[%d][%d] = %f, y[%d][%d] = %f, time = %f\n",i,j,x[i][j],i,j,y[i][j],time);
      }//for j         
    }//for i    
  }//for n 
  fclose(fp);
  
  
  //store results in hex for use in HDL sim verification
  //minimal lazy testing, just testing yn ##make sure HDL testbench are also using yn for verification##
  FILE *fp_verify_hex;  
  FILE *fp_verify;  
  fp_verify_hex = fopen("verifyChex.dat", "w");  
  fp_verify     = fopen("verifyC.dat", "w");  
  for (int i = 0; i < imax; i++)  {
    for (int j = 0; j < jmax; j++) {
      //fprintf (fp_verify_hex, "%x\n", yn[i][j]); //for integer outputs
      //fprintf (fp_verify_hex, "%x\n", yn[i][j]);  //for float outputs
      //following apparentlty violates the "strict aliasing rule" so may not always work?
      //https://stackoverflow.com/questions/45228925/how-to-print-float-as-hex-bytes-format-in-c?rq=1
      fprintf (fp_verify_hex, "%x\n", *(unsigned int*)&yn[i][j]);  //for float outputs
      fprintf (fp_verify, "%f\n", yn[i][j]);
    }
  }
	printf("Hex results logged for HDL verification\n");
  fclose(fp_verify_hex);
  fclose(fp_verify);
}//main()
