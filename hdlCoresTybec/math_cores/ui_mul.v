// =============================================================================
// Company      : University of Glasgow
// Author:        Waqar Nabi
// 
// Create Date  : 2014.12.04
// Design Name  : 
// Module Name  : ui_mult (Unsigned Integer Add)
// Project Name : TyTra
// Target Devices: Stratix V (D5/D8) 
//
// Tool versions: 
// Dependencies : includes.v (include)  
//
// Revision     : 
// Revision 0.01. File Created
// 
// =============================================================================           

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
//
// multiplication of unsigned integers 
// *Note* input and output are same size at the ports,
// There is NO check for overflow 
// 
// TODO Another option is to premptively truncate the inputs to half size.
// That will reduce the size of synthesized multiplier. However, that will
// also result in possibility of information loss at the input, when there was
// not going to be any overflow at the output (e.g. one very large number,
// other smaller number)
//==============================================================================

module ui_mul
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
  c = a * b; //
end

endmodule
