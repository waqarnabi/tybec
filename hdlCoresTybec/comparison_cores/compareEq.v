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
// A general purpose equality comparator
// 
// NOTE: Output bit-width is same as inputs, and there is no overflow
// detection
//==============================================================================

module compareEq
#(
// =============================================================================
// ** Parameters 
// =============================================================================
// Size of word (parent should over-write this if needeD)
  parameter N = 10 
)

(
// =============================================================================
// ** Ports 
// =============================================================================
  output          out,
  input   [N-1:0] in0,
  input   [N-1:0] in1
);

// =============================================================================
// ** Procedures and assignments
// =============================================================================
assign out = (in0==in1);
	
endmodule
