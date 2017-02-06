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
// A general purpose 2-way Mux Selector
// 
// NOTE: Output bit-width is same as inputs, and there is no overflow
// detection
//==============================================================================

module selectMux2
#(
// =============================================================================
// ** Parameters 
// =============================================================================
// Size of word (parent should over-write this if needeD)
  parameter N = 18 
)

(
// =============================================================================
// ** Ports 
// =============================================================================
  output  [N-1:0] out,
  input   [N-1:0] in0,
  input   [N-1:0] in1,
  input           select
);

// =============================================================================
// ** Procedures and assignments
// =============================================================================
assign out = select ? in1 : in0;
	
endmodule
