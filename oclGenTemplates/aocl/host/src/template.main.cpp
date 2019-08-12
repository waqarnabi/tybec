//=============================================================================
//Company              : Unversity of Glasgow, Comuting Science                
//Template Author      :        Syed Waqar Nabi                                
//                                                                             
//Project Name         : TyTra                                                 
//                                                                             
//Target Devices       : Stratix V                                             
//                                                                             
//Generated Design Name: <design_name>                                         
//Generated Module Name: <module_name>                                         
//Generator Version    : <gen_ver>                                             
//Generator TimeStamp  : <timeStamp>                                           
//                                                                             
//Dependencies         : <dependencies>                                        
//                                                                             
//                                                                             
//=============================================================================
//                                                                             
//=============================================================================
//General Description                                                          
//-----------------------------------------------------------------------------
//A template main.cpp file for TyBEC OCL code generation
//                                                                             
//============================================================================= 

//-------------------------------------------------
//Libraries
//-------------------------------------------------
#include "CL/opencl.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <timer.h>
#include <math.h>
#include "timer.h"
#include "ACLHostUtils.h"

//------------------------------------------------------
//Will this generated code have a CPU-baseline version?
//------------------------------------------------------
<isCpuBaselineAvailable>

//-------------------------------------------------
//Problem size
//-------------------------------------------------
#define SIZE  <bufsize>     
#define NSTEP  1

//-------------------------------------------------
//types
//-------------------------------------------------
typedef <hosttype>    host_t;
typedef <devicetype>  device_t;  

//-------------------------------------------------
//signatures and helpers
//-------------------------------------------------
#define CHECK(X) assert(CL_SUCCESS == (X))

void notify_print( const char* errinfo, const void* private_info, size_t cb, void *user_data );

unsigned char *load_file(const char* filename,size_t*size_ret);

int generate_random_int()
{
    return (rand());
}


void init(
     <initArgsSignature>    );

int post  ( FILE *fp
          , FILE *fperor
          , device_t  *cpu_vout
          , device_t  *dev_vout
          );


void cpuKernel  ( 
     <cpuKernelArgs>    ); 

//-------------------------------------------------
//globals
//-------------------------------------------------
const unsigned char *binary = 0;
cl_platform_id    platform;
cl_device_id      device;
cl_context        context;
cl_command_queue  cq;
cl_program        my_program;
cl_kernel         kernel;

//-------------------------------------------------
//main()
//-------------------------------------------------
int main(int argc, char**argv) 
{
<decCpuArrays>

//initialize input data and output files
//-------------------------------------------------
  init(
         <passArgs2Init>    );

  //initialize output file
  FILE *fp, *fperror;
  fp      = fopen("out.dat", "w");
  fperror = fopen("error.log", "w");

#ifdef CPUBASELINE  
//cpu-run
//-------------------------------------------------
  printf("Starting CPU run\n");
  Timer t_cpu;
  t_cpu.start();
  for (int t=0; t<NSTEP; t++) {
    //call kernel to loop over space
    cpuKernel ( 
     <passArgs2cpuKernel>    );      
  }//for (time-loop)
  t_cpu.stop();
  printf("Ending CPU run\n");
#endif

//opencl run
//------------------------------------------------- 
  int NSTEP_CL = NSTEP;

  //host memory pointers
  //---------------------
  host_t *host_vout;
<declareHostInputArrays>

  //cl_mem pointers 
  //----------------
  cl_mem cl_vout = 0;
<declareDeviceInputArrays>

  //other variables
  //---------------------   
  cl_int status = 0;
  cl_int bin_status = 0;
  size_t bin_len = 0;
  int num_errs = 0;
  int i;
  
  //platform,device, context, command queue, load kernel
  //-----------------------------------------------------
  CHECK( clGetPlatformIDs(1,&platform,0) );
  CHECK( clGetDeviceIDs(platform,CL_DEVICE_TYPE_ACCELERATOR,1,&device,0) );

  context = clCreateContext( 0, 1, &device, notify_print, 0, &status );
  CHECK( status );

  cq = clCreateCommandQueue( context, device, 0, &status );
  CHECK( status );

  const unsigned char* my_binary;
  size_t my_binary_len = 0;

  const char *aocx_name = "kernels.aocx";
  printf("Loading %s ...\n", aocx_name);
  my_binary = load_file(aocx_name, &my_binary_len); 

  if ((my_binary == 0) || (my_binary_len == 0)) {
    printf("Error: unable to read %s into memory or the file was not found!\n", aocx_name);
    exit(-1);
  }

  my_program = clCreateProgramWithBinary(context,1,&device,&my_binary_len,&my_binary,&bin_status,&status);
  CHECK(status);

  CHECK( clBuildProgram(my_program,1,&device,"",0,0) );

  kernel = clCreateKernel(my_program,"cl_func_lib",&status);
  CHECK(status);

  
  // host buffers, gen input data
  //-------------------------------   
  printf("Create host buffers and generate input data...\n");  
  host_vout = (host_t *) acl_aligned_malloc(SIZE*sizeof(host_t));  
  if (host_vout == NULL)
  {
    printf("ERROR: Unable to allocate memory for data buffers.\n");
    exit(1);
  }

<allocateHostInputMemory>
  if (<checkAllocateHostInputMemory>)
  {
    printf("ERROR: Unable to allocate memory for data buffers.\n");
    exit(1);
  }

   //copy input data generated for CPU run
  for ( i = 0; i < SIZE ; i++ ) {
<copyInputData>
  }

  //cl buffers
  //---------------------    
  printf("Create CL buffers\n");
  cl_vout = clCreateBuffer(context,CL_MEM_READ_WRITE,SIZE*sizeof(device_t),0,&status); CHECK(status);
<createClInputBuffers>
  
  //Prepare Kernel, Args
  //---------------------
  printf("Preparing kernels\n");   
  int cl_wi=0;
  
  //write input data to cl buffers
<enqueueDeviceInputBuffers>

  //global, local sizes
  size_t dims[3] = {1, 0, 0};    
  printf("Enqueueing kernel %d times with global size %d\n", NSTEP_CL, (int)dims[0]);
  CHECK( clFinish(cq) );

  //Launch Kernel
  //-------------       
<setAllKernelArguments>
   
   Timer t_device;
   t_device.start();
   for (i = 0; i < NSTEP_CL; i++) {
     CHECK( clEnqueueNDRangeKernel(cq,kernel,1,0,dims,0,0,0,0) );
   }
   CHECK( clFinish(cq) );
   t_device.stop();
   
  //Read results from device
  //-------------------------
  CHECK( clEnqueueReadBuffer (cq,cl_vout, 1,0,SIZE*sizeof(device_t),host_vout,0,0,0) );
  CHECK( clFinish(cq) );
 
  //Compare times (if applicable)
  //-----------------------------
   printf("\n");
#ifdef CPUBASELINE   
   printf ("*CPU* kernel computation function took %g seconds\n"   , t_cpu.get_time_s()   );
#endif   
   printf ("*DEVICE* Kernel computation function took %g seconds\n", t_device.get_time_s());
   printf("\n");
    
  //Compare results
  //---------------------   
  num_errs = post (fp, fperror, cpu_vout, host_vout);
  
  //Cleanup
  //---------------------
   clReleaseMemObject(cl_vout);
<releaseClInputBuffers>
   clReleaseKernel(kernel);
   clReleaseProgram(my_program);
   clReleaseContext(context);
<freeHostInputBuffers>  
   free(host_vout);
   
   return 0;
}

//-------------------------------------------------
//init()
//-------------------------------------------------
void init(  
          <initArgsSignature>
          ){      
    int i;
    for(i=0; i<SIZE; i++) {
<generateInputData>    }
}

//--------------------------------------
//- cpuKernel
//--------------------------------------
#ifdef CPUBASELINE
void cpuKernel (
   <cpuKernelArgs>
  ){
    
  for (int i=0; i<SIZE; i++) {
  vout[i] = <cpuKernel> ;
  }
}  
#endif

//-------------------------------------------------
//notify_print
//-------------------------------------------------
void notify_print( const char* errinfo, const void* private_info, size_t cb, void *user_data )
{
   private_info = private_info;
   cb = cb;
   user_data = user_data;
   printf("Error: %s\n", errinfo);
}

//-------------------------------------------------
//load_file
//-------------------------------------------------
unsigned char *load_file(const char* filename,size_t*size_ret)
{
   FILE* fp;
   int len;
   const size_t CHUNK_SIZE = 1000000;
   unsigned char *result;
   size_t r = 0;
   size_t w = 0;
   fp = fopen(filename,"rb");
   if ( !fp ) return 0;
   // Obtain file size.
   fseek(fp, 0, SEEK_END);
   len = ftell(fp);
   // Go to the beginning.
   fseek(fp, 0, SEEK_SET);
   // Allocate memory for the file data.
   result = (unsigned char*)malloc(len+CHUNK_SIZE);
   if ( !result )
   {
     fclose(fp);
     return 0;
   }
   // Read file.
   while ( 0 < (r=fread(result+w,1,CHUNK_SIZE,fp) ) )
   {
     w+=r;
   }
   fclose(fp);
   *size_ret = w;
   return result;
}

//--------------------------
//-Writing the arrays to file
//--------------------------
int post (  FILE *fp
          , FILE *fperror
          , device_t *vout_cpu
          , device_t *vout_cl
          ) {
    int num_errs = 0;
    int testPass = 1;
    for(int i=0; i<SIZE; i++) {
#ifdef CPUBASELINE      
      //print to file
      fprintf (fp, "\t%5d::\t%<pt>\t%<pt>\n", i, vout_cpu[i],  vout_cl[i]);
      //compare CPU <--> DEVICE
      if (vout_cl[i] != vout_cpu[i]) {
        num_errs++;
        fprintf (fperror, "ERROR: i=%d;  cpu = %<pt>, dev = %<pt>\n", i, vout_cpu[i],  vout_cl[i]);
        testPass=0;
       }
#else
      //print to file
      fprintf (fp, "\t%5d::\t%<pt>\n", i,  vout_cl[i]);
#endif  
    }//for

#ifdef CPUBASELINE    
    if (testPass==1)
     printf("$$$ Test PASSED! $$$\n");
#endif   
  
  return num_errs;
}//()
