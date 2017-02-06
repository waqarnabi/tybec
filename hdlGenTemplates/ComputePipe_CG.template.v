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
// A generic Coarse-Grained pipelined module template for use by Tytra Back-End 
// to allow instantiation of pipeline of pipelines
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
// ** Connection wires
// =============================================================================
<connectingWires>

// =============================================================================
// ** Instantiate Child Pipes and wire them up
// =============================================================================
<childPipes>




 
endmodule 


