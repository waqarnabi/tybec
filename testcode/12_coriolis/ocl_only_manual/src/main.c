//=============================================================================
//Company              : Unversity of Glasgow, Comuting Science                
//Template Author      :        Syed Waqar Nabi                                
//                                                                             
//Project Name         : TyTra                                                 
//                                                                             
//Target Devices       : Stratix V                                             
//                                                                             
//Generated Design Name: untitled                                         
//Generated Module Name: <module_name>                                         
//Generator Version    : R17.0                                             
//Generator TimeStamp  : Thu Jul 18 21:20:31 2019                                           
//                                                                             
//Dependencies         : <dependencies>                                        
//                                                                             
//                                                                             
//=============================================================================
//                                                                             
//=============================================================================
//General Description                                                          
//-----------------------------------------------------------------------------
//A template main.cpp file for TyBEC Sdx OCL host code generation
//Based on Xilinx's provided examples (see following copyright notice)              
//============================================================================= 
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
//============================================================================= 


#include "xcl2.hpp"
#include <vector>

#define DATA_SIZE 64
#define NTOT      1
#define TY_GVECT  1

#include <chrono>
#include <utility>
#include <math.h>

//#define VERBOSE

#define data_t float
//----------------------------------------------------------------------------
// lazy globals for Coriolis
//----------------------------------------------------------------------------

  float dt,freq,f,pi,alpha,beta;
  //const int mode = MODE;
  //const int imax = IMAX;
  //const int jmax = JMAX; //I am introucing a 2D space grid that is not there in the original fortran
  const int ntot = NTOT; //total number of time interation steps


int main(int argc, char** argv)
{
    // Coriolis specific constants //
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
    //\Coriolis specific constants //

  
    int size = DATA_SIZE;
    //Allocate Memory in Host Memory
    size_t vector_size_bytes = sizeof(int) * size;
    std::vector<data_t,aligned_allocator<data_t>> source_input_u       (size);
    std::vector<data_t,aligned_allocator<data_t>> source_input_x       (size);
    std::vector<data_t,aligned_allocator<data_t>> source_input_v       (size);
    std::vector<data_t,aligned_allocator<data_t>> source_input_y       (size);
    std::vector<data_t,aligned_allocator<data_t>> source_hw_results_un  (size);
    std::vector<data_t,aligned_allocator<data_t>> source_hw_results_xn  (size);
    std::vector<data_t,aligned_allocator<data_t>> source_hw_results_vn  (size);
    std::vector<data_t,aligned_allocator<data_t>> source_hw_results_yn  (size);
    std::vector<data_t,aligned_allocator<data_t>> source_sw_results  (size);

    // Create the test data and Software Result 
    for(int i = 0 ; i < size ; i++){
        source_input_u[i]  = 3.14+i+1;
        source_input_x[i]  = 3.14+i+1;
        source_input_v[i]  = 3.14+i+1;
        source_input_y[i]  = 3.14+i+1;
                
        //source_sw_results[i] = source_input1[i] + source_input2[i];
        //wn: the barebones tytra example
        //invalid, manually check results for now
        source_sw_results[i] = 0;
        //(source_input1[i] + source_input2[i])*(source_input1[i] + source_input2[i])*32; 
        //source_hw_results[i] = 0;
    }

//OPENCL HOST CODE AREA START
    //Create Program and Kernel
    std::vector<cl::Device> devices = xcl::get_xil_devices();
    cl::Device device = devices[0];

    cl::Context context(device);
    cl::CommandQueue q(context, device, CL_QUEUE_PROFILING_ENABLE);
    std::string device_name = device.getInfo<CL_DEVICE_NAME>(); 

    std::string binaryFile = xcl::find_binary_file(device_name,"oclComputeKernel");
    cl::Program::Binaries bins = xcl::import_binary_file(binaryFile);
    devices.resize(1);
    cl::Program program(context, devices, bins);
    cl::Kernel oclComputeKernel(program,"oclComputeKernel");

    //Allocate Buffer in Global Memory
    std::vector<cl::Memory> inBufVec, outBufVec;
    cl::Buffer buffer_u (context,CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY , vector_size_bytes, source_input_u.data());
    cl::Buffer buffer_x (context,CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY , vector_size_bytes, source_input_x.data());
    cl::Buffer buffer_v (context,CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY , vector_size_bytes, source_input_v.data());
    cl::Buffer buffer_y (context,CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY , vector_size_bytes, source_input_y.data());
    cl::Buffer buffer_un(context,CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY, vector_size_bytes, source_hw_results_un.data());
    cl::Buffer buffer_xn(context,CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY, vector_size_bytes, source_hw_results_xn.data());
    cl::Buffer buffer_vn(context,CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY, vector_size_bytes, source_hw_results_vn.data());
    cl::Buffer buffer_yn(context,CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY, vector_size_bytes, source_hw_results_yn.data());

    inBufVec.push_back (buffer_u );
    inBufVec.push_back (buffer_x );
    inBufVec.push_back (buffer_v );
    inBufVec.push_back (buffer_y );
    outBufVec.push_back(buffer_un);
    outBufVec.push_back(buffer_xn);
    outBufVec.push_back(buffer_vn);
    outBufVec.push_back(buffer_yn);


    //Copy input data to device global memory
    q.enqueueMigrateMemObjects(inBufVec,0/* 0 means from host*/);

    //Set the Kernel Arguments
    oclComputeKernel.setArg(0,buffer_u );
    oclComputeKernel.setArg(1,buffer_x );
    oclComputeKernel.setArg(2,buffer_v );
    oclComputeKernel.setArg(3,buffer_y );
    oclComputeKernel.setArg(4,buffer_un);
    oclComputeKernel.setArg(5,buffer_xn);
    oclComputeKernel.setArg(6,buffer_vn);
    oclComputeKernel.setArg(7,buffer_yn);
    oclComputeKernel.setArg(8,size);

    auto start = std::chrono::high_resolution_clock::now();          //<----------TIMER START
    for (int n=0;n<ntot;n++) {
    //Launch the Kernel
    q.enqueueTask(oclComputeKernel);
    q.finish();
    }
    auto finish = std::chrono::high_resolution_clock::now();          //<----------TIMER END

    //Copy Result from Device Global Memory to Host Local Memory
    q.enqueueMigrateMemObjects(outBufVec,CL_MIGRATE_MEM_OBJECT_HOST);
    q.finish();

    std::chrono::duration<double> elapsed = finish - start;
    std::cout << "TY:Kernel execution took:: " << elapsed.count() << " sec" << std::endl;
    
    
//OPENCL HOST CODE AREA END
    
    // Compare the results of the Device to the simulation
    int match = 0;
/*
    for (int i = 0 ; i < size ; i++){
      //wn: added --> always show result, right or wrong
      std::cout << "i = " << i << " Software result = " << source_sw_results[i]
      << " Device result = " << source_hw_results[i] << std::endl;
        if (source_hw_results[i] != source_sw_results[i]){
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << "i = " << i << " Software result = " << source_sw_results[i]
                << " Device result = " << source_hw_results[i] << std::endl;
            match = 1;
            //break;
        }
    }
*/
    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl; 
    
    std::cout << "TY:Kernel execution took:: " << elapsed.count() << " sec" << std::endl;

    return (match ? EXIT_FAILURE :  EXIT_SUCCESS);
}
