/**********
Copyright (c) 2018, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**********/

// This function represents an OpenCL kernel. The kernel will be call from
// host application using the xcl_run_kernels call. The pointers in kernel
// parameters with the global keyword represents cl_mem objects on the FPGA
// DDR memory.
//
//#define BUFFER_SIZE 1024

kernel __attribute__((reqd_work_group_size(1, 1, 1)))
void oclComputeKernel(	
          global const float* u,
          global const float* x,
          global const float* v,
          global const float* y,
					global float*       un,
					global float*       xn,
					global float*       vn,
					global float*       yn,
					const int n_elements
          )
{
    float dt,freq,f,pi,alpha,beta;
  
    // Coriolis specific constants //
    //global constants
    pi    = 4.0*atan(1.0)       ;// this calculates Pi  
    freq  = -2.*pi/(24.*3600.)  ;//
    f     = 2*freq              ;// Coriolis parameter
    dt    = 24.*3600./200.      ;// time step
    
    // parameters for semi-implicit scheme
    alpha = f*dt            ;//
    beta = 0.25*alpha*alpha ;//
  
  
    for (int i = 0; i < n_elements; i=i+1) {
    //for (int j = 0; j < jmax; j++) {
      //! velocity predictor
      //if (mode == 1) {
        un[i] = (u[i]*(1-beta)+alpha*v[i])/(1+beta);
        vn[i] = (v[i]*(1-beta)-alpha*u[i])/(1+beta);
      //}
      //else {
      //  un[i][j] = cos(alpha)*u[i][j]+sin(alpha)*v[i][j];
      //  vn[i][j] = cos(alpha)*v[i][j]-sin(alpha)*u[i][j];
      //}
      
      //! predictor of new location
      xn[i] = x[i] + dt*un[i]/1000;
      yn[i] = y[i] + dt*vn[i]/1000;
      
      //! updates for next time step 
      //u[i*jmax + j] = un[i*jmax + j];
      //v[i*jmax + j] = vn[i*jmax + j];
      //x[i*jmax + j] = xn[i*jmax + j];
      //y[i*jmax + j] = yn[i*jmax + j];
    //}//for j         
    }//for i     
}
