// =============================================================================
// Company      : University of Glasgow
// Author:        Waqar Nabi
// 
// Create Date  : 2014.12.12
// Design Name  : 
// Module Name  : delayline_z1
// Project Name : TyTra
// Target Devices: Stratix V (D5/D8) 
//
// Tool versions: 
// Dependencies : 
//
// Revision     : 
// Revision 0.01. File Created
// 
// =============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// A TyTra Pipeline compliant delay line (delay = 1 clock cycle)
// [A more generic N-cycle delay line will replace this later TODO]
//==============================================================================

module delayline_z1
#(
// =============================================================================
// ** Parameters 
// =============================================================================
// Size of word 
  parameter W = 1 
)

(
// =============================================================================
// ** Ports 
// =============================================================================
  input           clk,

  output reg [W-1:0]  out,
  input      [W-1:0]  in
);

// =============================================================================
// ** Procedures and assignments
// =============================================================================
//registered inputs for pipelining stage
always @(posedge clk) 
  out <= in;

endmodule

