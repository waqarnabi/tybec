// =============================================================================
// Company              : Unversity of Glasgow, Comuting Science
// Template Author      : S Waqar Nabi
// Template origin date : 2019.07.29
//
// Project Name         : TyTra
//
// Target Devices       : Xilinx Ultrascale (AWS)
//
// Generated Design Name: <design_name>
// Generated Module Name: <module_name>
// Generator Version    : <gen_ver>
// Generator TimeStamp  : <timeStamp>
// 
// Dependencies         : <dependencies>
//
// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// template for func_hdl_top.sv, required for SDx integration
// with TyBEC generated HDL
//
// This module is a light-weight wrapper that translates the packed AXI signals to
// unpacked signals for use by TyBEC generated modules, which have AXI-type
// signals but not with same names
// The top level function in TyTra-IR is ALWAYS "main", so this module will
// ALWYAS instantitate just one, MAIN module
//
// Based on template provided by Xilinx
//  /*******************************************************************************
//  Vendor: Xilinx
//  Associated Filename: main.c
//  #Purpose: This example shows a basic vector add +1 (constant) by manipulating
//  #         memory inplace.
//  *******************************************************************************/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <CL/opencl.h>
#include <CL/cl_ext.h>
#include <time.h>

////////////////////////////////////////////////////////////////////////////////

#define NUM_WORKGROUPS (1)
#define WORKGROUP_SIZE (256)
//#define MAX_LENGTH 8192

#if defined(SDX_PLATFORM) && !defined(TARGET_DEVICE)
#define STR_VALUE(arg)      #arg
#define GET_STRING(name) STR_VALUE(name)
#define TARGET_DEVICE GET_STRING(SDX_PLATFORM)
#endif


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

int load_file_to_memory(const char *filename, char **result)
{
    uint size = 0;
    FILE *f = fopen(filename, "rb");
    if (f == NULL) {
        *result = NULL;
        return -1; // -1 means file opening fail
    }
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    *result = (char *)malloc(size+1);
    if (size != fread(*result, sizeof(char), size, f)) {
        free(*result);
        return -2; // -2 means file reading fail
    }
    fclose(f);
    (*result)[size] = 0;
    return size;
}

//============================================================================
// Problem-specific
//============================================================================
  //#define VERBOSE
  #define TY_GVECT <globalVect>  
  #define NTOT  1
  #define DATA_SIZE <SIZE>
    //SDx read master/write master require 4kB aligned buffers
    // e.g. 1024 (or 32x32 for 2D square grid) makes this automatic:
      //32*32*4 = 4KB
      //subsequent pointers will automatically be 4KB aligned
  #define MAX_LENGTH DATA_SIZE
  
  #define data_t <data_t>
  
  #define NINPUTS   <ninputs>
  #define NOUTPUTS  NINPUTS 
    //this template can only same number of outputs as inputs 
    //(to make coalesced IO the same width, as they use the same interface)
      
  
//============================================================================
int main(int argc, char** argv)
//============================================================================
{
  clock_t cstart, cend;
  double cpu_time_used;
  clock_t dstart, dend;
  double dev_time_used;
  
  //note: size = DATA_SIZE = MAX_LENGTH = IM*JM
    //MAX_SIZE could be different?
  const int imax = (int)sqrt((double)DATA_SIZE);
  const int jmax = (int)sqrt((double)DATA_SIZE); 
  const int ntot = NTOT; //total number of time interation steps
  const int vect = TY_GVECT; 
//-----------------------------------------------------------------------------------
// INIT DATA (Host and Device)
// ----------------------------------------------------------------------------------


  int size = DATA_SIZE;
  //host arrays for host run
<hostArraysForHostRunDeclare>

  //host memory for device run (coalesced inputs and outputs)
  data_t* h_axi00_ptr0_input = (data_t*) malloc((sizeof (data_t))*MAX_LENGTH*NINPUTS); 
  data_t* h_axi00_ptr0_output = (data_t*) malloc((sizeof (data_t))*MAX_LENGTH*NOUTPUTS); 

  //init data
  for (int i = 0; i < imax; i++) {
    for (int j = 0; j < jmax; j=j+vect) { //vect _must_ be a factor of jmax
      for (int w = 0; w < vect; w++) {
<init_host_input>
      //interleave inputs into a single array for device
<init_dev_input>
<init_dev_output>
      }
    }
  }
  
//-----------------------------------------------------------------------------------
// HOST RUN (Golden results)
// ----------------------------------------------------------------------------------
  cstart = clock();
  <hostRun4GoldenResults>
  cend = clock();
  cpu_time_used = ((double) (cend - cstart)) / CLOCKS_PER_SEC;

      
//-----------------------------------------------------------------------------------
// DEV RUN 
// ----------------------------------------------------------------------------------
    int err;                            // error code returned from api calls
    int check_status = 0;
    const uint number_of_words = DATA_SIZE; // 


    cl_platform_id platform_id;         // platform id
    cl_device_id device_id;             // compute device id
    cl_context context;                 // compute context
    cl_command_queue commands;          // compute command queue
    cl_program program;                 // compute programs
    cl_kernel kernel;                   // compute kernel

    char cl_platform_vendor[1001];
    char target_device_name[1001] = TARGET_DEVICE;

    cl_mem d_axi00_ptr0_input;  // device memory used for a vector (coalesced) input
    cl_mem d_axi00_ptr0_output; // device memory used for a vector (coalesced) output

    if (argc != 2) {
        printf("Usage: %s xclbin\n", argv[0]);
        return EXIT_FAILURE;
    }

   // Get all platforms and then select Xilinx platform
    cl_platform_id platforms[16];       // platform id
    cl_uint platform_count;
    int platform_found = 0;
    err = clGetPlatformIDs(16, platforms, &platform_count);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to find an OpenCL platform!\n");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }
    printf("INFO: Found %d platforms\n", platform_count);

    // Find Xilinx Plaftorm
    for (unsigned int iplat=0; iplat<platform_count; iplat++) {
        err = clGetPlatformInfo(platforms[iplat], CL_PLATFORM_VENDOR, 1000, (void *)cl_platform_vendor,NULL);
        if (err != CL_SUCCESS) {
            printf("Error: clGetPlatformInfo(CL_PLATFORM_VENDOR) failed!\n");
            printf("Test failed\n");
            return EXIT_FAILURE;
        }
        if (strcmp(cl_platform_vendor, "Xilinx") == 0) {
            printf("INFO: Selected platform %d from %s\n", iplat, cl_platform_vendor);
            platform_id = platforms[iplat];
            platform_found = 1;
        }
    }
    if (!platform_found) {
        printf("ERROR: Platform Xilinx not found. Exit.\n");
        return EXIT_FAILURE;
    }

   // Get Accelerator compute device
    cl_uint num_devices;
    unsigned int device_found = 0;
    cl_device_id devices[16];  // compute device id
    char cl_device_name[1001];
    err = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_ACCELERATOR, 16, devices, &num_devices);
    printf("INFO: Found %d devices\n", num_devices);
    if (err != CL_SUCCESS) {
        printf("ERROR: Failed to create a device group!\n");
        printf("ERROR: Test failed\n");
        return -1;
    }

    //iterate all devices to select the target device.
    for (uint i=0; i<num_devices; i++) {
        err = clGetDeviceInfo(devices[i], CL_DEVICE_NAME, 1024, cl_device_name, 0);
        if (err != CL_SUCCESS) {
            printf("Error: Failed to get device name for device %d!\n", i);
            printf("Test failed\n");
            return EXIT_FAILURE;
        }
        printf("CL_DEVICE_NAME %s\n", cl_device_name);
        if(strcmp(cl_device_name, target_device_name) == 0) {
            device_id = devices[i];
            device_found = 1;
            printf("Selected %s as the target device\n", cl_device_name);
       }
    }

    if (!device_found) {
        printf("Target device %s not found. Exit.\n", target_device_name);
        return EXIT_FAILURE;
    }

    // Create a compute context
    //
    context = clCreateContext(0, 1, &device_id, NULL, NULL, &err);
    if (!context) {
        printf("Error: Failed to create a compute context!\n");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }

    // Create a command commands
    commands = clCreateCommandQueue(context, device_id, 0, &err);
    if (!commands) {
        printf("Error: Failed to create a command commands!\n");
        printf("Error: code %i\n",err);
        printf("Test failed\n");
        return EXIT_FAILURE;
    }

    int status;

    // Create Program Objects
    // Load binary from disk
    unsigned char *kernelbinary;
    char *xclbin = argv[1];

    //------------------------------------------------------------------------------
    // xclbin
    //------------------------------------------------------------------------------
    printf("INFO: loading xclbin %s\n", xclbin);
    int n_i0 = load_file_to_memory(xclbin, (char **) &kernelbinary);
    if (n_i0 < 0) {
        printf("failed to load kernel from xclbin: %s\n", xclbin);
        printf("Test failed\n");
        return EXIT_FAILURE;
    }

    size_t n0 = n_i0;

    // Create the compute program from offline
    program = clCreateProgramWithBinary(context, 1, &device_id, &n0,
                                        (const unsigned char **) &kernelbinary, &status, &err);

    if ((!program) || (err!=CL_SUCCESS)) {
        printf("Error: Failed to create compute program from binary %d!\n", err);
        printf("Test failed\n");
        return EXIT_FAILURE;
    }

    // Build the program executable
    //
    err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t len;
        char buffer[2048];

        printf("Error: Failed to build program executable!\n");
        clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, &len);
        printf("%s\n", buffer);
        printf("Test failed\n");
        return EXIT_FAILURE;
    }

    // Create the compute kernel in the program we wish to run
    //
     kernel = clCreateKernel(program, "krnl_vadd_rtl", &err);
    if (!kernel || err != CL_SUCCESS) {
        printf("Error: Failed to create compute kernel!\n");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }

    // Create structs to define memory bank mapping
    cl_mem_ext_ptr_t d_bank_ext[4];

    d_bank_ext[0].flags = XCL_MEM_DDR_BANK0;
    d_bank_ext[0].obj = NULL;
    d_bank_ext[0].param = 0;

    d_bank_ext[1].flags = XCL_MEM_DDR_BANK1;
    d_bank_ext[1].obj = NULL;
    d_bank_ext[1].param = 0;

    d_bank_ext[2].flags = XCL_MEM_DDR_BANK2;
    d_bank_ext[2].obj = NULL;
    d_bank_ext[2].param = 0;

    d_bank_ext[3].flags = XCL_MEM_DDR_BANK3;
    d_bank_ext[3].obj = NULL;
    d_bank_ext[3].param = 0;
    // Create the input and output arrays in device memory for our calculation



    d_axi00_ptr0_input  = clCreateBuffer(context,  CL_MEM_READ_WRITE | CL_MEM_EXT_PTR_XILINX,  sizeof(data_t) * number_of_words*NINPUTS, &d_bank_ext[0], NULL);
    d_axi00_ptr0_output = clCreateBuffer(context,  CL_MEM_READ_WRITE | CL_MEM_EXT_PTR_XILINX,  sizeof(data_t) * number_of_words*NOUTPUTS, &d_bank_ext[0], NULL);


    if (!(d_axi00_ptr0_input) || !(d_axi00_ptr0_output)) {
        printf("Error: Failed to allocate device memory!\n");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }
    // Write our data set into the input array in device memory
    //


    err = clEnqueueWriteBuffer(commands, d_axi00_ptr0_input, CL_TRUE, 0, sizeof(int) * number_of_words * NINPUTS, h_axi00_ptr0_input, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to write to source array h_axi00_ptr0_input!\n");
        printf("Test failed\n");
        return EXIT_FAILURE;
    }


    // Set the arguments to our compute kernel
    // int vector_length = MAX_LENGTH;
    err = 0;
    err |= clSetKernelArg(kernel, 0, sizeof(cl_mem), &d_axi00_ptr0_input); 
    err |= clSetKernelArg(kernel, 1, sizeof(cl_mem), &d_axi00_ptr0_output);
    int num_vect_words_2_transfer = size/TY_GVECT;
    err |= clSetKernelArg(kernel, 2, sizeof(int), &num_vect_words_2_transfer); //WN: added
    
    if (err != CL_SUCCESS) {
        printf("Error: Failed to set kernel arguments! %d\n", err);
        printf("Test failed\n");
        return EXIT_FAILURE;
    }

    // -------------------------------------------------------------------
    // KERNEL EXEC
    // -------------------------------------------------------------------
    
    // Execute the kernel over the entire range of our 1d input data set
    // using the maximum number of work group items for this device
    dstart = clock();
    //!**** start of iteration loop ****
    for (int n =0; n < ntot; n++) {
    //!*********************************
      err = clEnqueueTask(commands, kernel, 0, NULL, NULL);
      if (err) {
              printf("Error: Failed to execute kernel! %d\n", err);
              printf("Test failed\n");
              return EXIT_FAILURE;
          }
  
      // Read back the results from the device to verify the output
      //
      clFinish(commands);
    }
    dend = clock();
    dev_time_used = ((double) (dend - dstart)) / CLOCKS_PER_SEC;

    cl_event readevent;
    err = 0;
    err |= clEnqueueReadBuffer( commands, d_axi00_ptr0_output, CL_TRUE, 0, sizeof(int) * number_of_words * NOUTPUTS, h_axi00_ptr0_output, 0, NULL, &readevent );


    if (err != CL_SUCCESS) {
            printf("Error: Failed to read output array! %d\n", err);
            printf("Test failed\n");
            return EXIT_FAILURE;
        }
    clWaitForEvents(1, &readevent);

    //------------------------------------------------------------------------------
    // Check Results
    //------------------------------------------------------------------------------
    
    //const int how_many_words_to_compare = number_of_words; //mak
    const int how_many_words_to_compare = 16; //for quick verification and less clutter, check few initial results
    for (uint i = 0; i < how_many_words_to_compare; i=i+vect) {
      for (uint w = 0; w < vect; w++) {
        int r = i/jmax;
        int c = i%jmax;
        
<compareResultsCond>
        printf("ERROR,i=%d:: <compareResultsPrint>\n"
          , i+w<compareResultsPrint2>
          );
        check_status = 1;
      }
    }
  }
  
  //-----------------------------
  //Compare times (if applicable)
  //-----------------------------
   printf("\n");
   printf ("*CPU* kernel computation function took %g seconds\n"   , cpu_time_used );
   printf ("*DEVICE* Kernel computation function took %g seconds\n", dev_time_used );
   printf("\n");

    //--------------------------------------------------------------------------
    // Shutdown and cleanup
    //-------------------------------------------------------------------------- 
    clReleaseMemObject(d_axi00_ptr0_input);
    clReleaseMemObject(d_axi00_ptr0_output);

    clReleaseProgram(program);
    clReleaseKernel(kernel);
    clReleaseCommandQueue(commands);
    clReleaseContext(context);

    if (check_status) {
        printf("INFO: Test failed\n");
        return EXIT_FAILURE;
    } else {
        printf("INFO: Test completed successfully.\n");
        return EXIT_SUCCESS;
    }
} // end of main
