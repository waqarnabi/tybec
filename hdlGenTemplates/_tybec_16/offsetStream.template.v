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
// Template for creating offset window streams, for use by Tytra 
// Back-End Compiler (TyBEC)
//
// ============================================================================= 


module <module_name>
#(
// =============================================================================
// ** Parameters 
// =============================================================================
  parameter DataW = 32 
)

(
// =============================================================================
// ** Ports 
// =============================================================================
     input   clk 
  ,  input   rst    
  ,  input   [DataW-1:0] in    
  ,  output  [DataW-1:0] outP0 //zero-offset always emitted by default
  <ports>    
);

// =============================================================================
// ** Locals
// =============================================================================
localparam sizeWords = <maxPos> + <maxNeg> + 1;

reg [DataW-1:0]  offsetRegBank [0:sizeWords-1];   

// =============================================================================
// ** Procedures and assignments
// =============================================================================

<port2regConnections>

<shiftRegister>

endmodule
