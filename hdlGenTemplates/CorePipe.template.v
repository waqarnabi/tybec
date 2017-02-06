// =============================================================================
// Company              : Unversity of Glasgow, Comuting Science
// Template Author      :        Syed Waqar Nabi
//
// Project Name         : TyTra
//
// Target Devices       : Stratix V 
//
// Generated Design Name: <design_name>
// Generated Module Name: <module_name> 
// Generator Version    : <gen_ver>
// Generator TimeStamp  : <timeStamp>
// 
// Dependencies         : <dependencies>
//
// 
// =============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// A generic pipelined module template for use by Tytra Back-End Compiler
// (TyBEC)
//
// ============================================================================= 




// =============================================================================
// ** Generator Macros 
// =============================================================================  

module <module_name>
#(  
  // ============================================================
  // ** Parameters 
  // ===========================================================
  // Parameters inherit from defines in include file. Default 
  // values defined here and must be overwritten as needed
     parameter DataW = 32 //width of functional units in Computes
<params>
  )

(
// =============================================================================
// ** Ports 
// =============================================================================
    input 	clk 
  , input 	rst 
  ,	input 	start
  , output	done
  //, <debug_output_stream>
   //emitted to ensure logic not pruned
// ----------------------------------------------------------------------------
// --------------------------** LMEM Interconnect **---------------------------
// ----------------------------------------------------------------------------
// The format is:
// XMEM_<var_name>_<port_type>_<port_name_if_app>_<otherSpec_if_app>
// in/out is from the perspective of this module
<lmem_ports>
  
);

// =============================================================================
// CONNECTION WIRES AND STREAM REGISTERS
// =============================================================================
wire  ready;
wire  cts;

<wires_for_streams>

// =============================================================================
// INDEX COUNTERS
// =============================================================================
// These are the counters that are used for indexing into LMEM memorys
// to read from / write to streaming ports
<index_counters>

// =============================================================================
// INTERNAL STOP SIGNAL CREATION  
// =============================================================================
// See comments for STOP input signal

// internally generated STOP signal to Kernel when the last element has been
// fed into the pipeline, which would be the case when the index counter of
// the input streaming data has reached the limit
// since we have a symmetrical case of input streams, we can use any one
// stream
<interal_stop_signal>

//since there is a 2 clock delay between the last index being reached, and the
//last data being fed into the pipeline, so we have to create this logic for
//a 2-tick delayed version; similarly for start (see next)
reg stop_z1;
reg stop_z2;

always @(posedge clk)
begin
  stop_z1 <= stop;
  stop_z2 <= stop_z1;
end

assign stop2kernel = stop_z2;

// =============================================================================
// INTERNAL START SIGNAL CREATION  
// =============================================================================
// internally generated START signal to Kernel which is a delayed version of
// external start input to this module
// the delay is needed for the two clock signals between externa start
// assertion and first data availibility at the streaming inputs
reg start_z1;
reg start_z2;

always @(posedge clk)
begin
  start_z1 <= start;
  start_z2 <= start_z1;
end

assign start2kernel = start_z2;

// =============================================================================
// STREAMING DATA CONTROL (Load / Store)
// =============================================================================
parameter smreg_W = 2; 
<stream_control_fsms>



// =============================================================================
// INSTANTIATE OFFSET-STREAM BUFFERS
// =============================================================================
// The offset stream creator internally has ports for all offsets between
// +max and -min. We only connect to the ones we need, and expect the 
// synthesis tool to remove the other ports
// So the port connections cant really be parameterized (?)
// We will have to generate custom code for these connections
//
// NOTE: once we use the offset stream, then the original stream
// cannot be used in place of the CURRENT index, as now the whole 
// thing is offset.
// So in this case, we cant use strm_a anymore, but will have to use 
// strm_a_0 henceforth for the current index 

<instaniateOffsetStreams>



// =============================================================================
// INSTANTIATE KERNEL PIPELINE
// =============================================================================
// NOTE: All internal streams and arithmetic untis assumed to be same size as the
// stream. If different though, then they should be differentiated here...


ComputePipe_<funcName>
  #(  . DataW   (DataW)
<childCore_parameter_connections>
)
  CoreACompute01
    ( .clk    (clk   )
    , .rst    (rst   )	
    , .start  (start2kernel ) 
    , .stop   (stop2kernel  ) 
    , .ready  (ready ) 
    , .done   (done  ) 
    , .cts    (cts   ) 

<childCore_stream_port_connections>
);
endmodule            
