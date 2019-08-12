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

module <module_name>
#(  
  // ============================================================
  // ** Parameters 
  // ===========================================================
  // Parameters inherit from defines in include file. Default 
  // values defined here and must be overwritten as needed
  parameter DataW  = 32 
<params>
)

(
// =============================================================================
// ** Ports 
// =============================================================================
  // standard kernel control ports
    input   clk   
  , input   rst   	
  , input   start  //asserted when first element is fed into the pipeline
  , input   stop   //asserted when the last element is fed into the pipe
  , output  ready  //asserted whenb first element exits the pipeline 
  , output  done   //asserted when the last element exits the pipeline 
  , output  reg cts    //for compatibility with SEQ Core

  <streamingPorts>

);

// =============================================================================
// ** Dataflow
// =============================================================================
// renamed for uniformity later
wire start_z0 = start;
wire stop_z0 = stop;

<pipelineStages>

<delayLines>

//----------------------- output wires -----------------------------------------
// Use the (N-1)th START for READY (so _z3 for 4 stage pipeline)
assign ready = <outputReady>;

// Use the (Nth) STOP for DONE (so _z4 for 4 stage pipeline)
assign done = <outputDone>;

//cts is asserted when the first element exits the pipeline
//(i.e. is when read is asserted for one tick) it remains asserted 
//as this is a pipeline that takes in a continuous stream
//of data, so it is always CTS
//It is used by parent to enable counting for destination counter
always @(posedge clk)
  if(ready || cts)
    cts <= 1'b1;
  else
    cts <= 1'b0;
 
endmodule 


