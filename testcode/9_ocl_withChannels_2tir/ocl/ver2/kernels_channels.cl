channel int ch00;
channel int ch01;
channel int ch1;


//------------------------------------------
// Read memory kernel (scalar version)
//------------------------------------------
__kernel void kernelInput (  int *aIn0
                           , int *aIn1
                           ) {
    int data0, data1;
    //for(int i=0; i<SIZE; i++) {
    //read from global memory
    data0 = *aIn0;
    data1 = *aIn1;
    
    //write to channel
    write_pipe(ch00, &data0);
    write_pipe(ch01, &data1);
    //}
}//()


//----------------------
//Compute kernel
//----------------------
__kernel void kernelCompute (
                             ) {
    
    //locals
    int dataIn0, dataIn1, dataOut;
    int i;
    
    
    //for(i=0; i < SIZE; i++) {
    //read from channels
    read_pipe(ch00, &dataIn0);
    read_pipe(ch01, &dataIn1);
    
    //the computation
    dataOut = (dataIn0 + dataIn1) / dataIn0;
    
    //write to channel
    write_pipe(ch1, &dataOut);
    //}
}//()


//------------------------------------------
// Write memory kernel
//------------------------------------------
__kernel void kernelOutput( int* aOut
                           ) {
    int data;
    //for (int i=0; i < SIZE; i++) {
    //read from channel
    //while(get_pipe_num_packets(ch1)==0); //busy-wait until packet available in the pipe
    read_pipe(ch1, &data);
    
    //write to global mem
    *aOut = data;
    //}
}//()
