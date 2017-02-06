// =============================================================================
// Company      : University of Glasgow
// Author:        Waqar Nabi
// 
// Create Date  : 2014.12.04
// Design Name  : 
// Module Name  : ui_add (Unsigned Integer Add)
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
// A general purpose N-bit adder.
// 
// NOTE: Output bit-width is same as inputs, and there is no overflow
// detection
//==============================================================================

module ui_add
#(
// =============================================================================
// ** Parameters 
// =============================================================================
// Size of word (parent should over-write this if needeD)
  parameter N = 64 
)

(
// =============================================================================
// ** Ports 
// =============================================================================
  output reg  [N-1:0] c,
  input       [N-1:0] a,
  input       [N-1:0] b
);

// =============================================================================
// ** Procedures and assignments
// =============================================================================
always @(*)
begin
  c = a + b; //2's complement addition so no additional logic needed...
end

endmodule
