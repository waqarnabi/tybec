// =============================================================================
// Company      : University of Glasgow
// Author:        Waqar Nabi
// 
// Create Date  : 2014.12.12
// Design Name  : 
// Module Name  : PipePE_ui_add
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
// A TyTra Pipeline compliant PE for unsigned integer multiplication
// An "AlWAYS-ON" module. So input trigger is redundant and is simply kept for
// uniformity.
// Will be optmized away by synthesizer
//==============================================================================

// =============================================================================
// ** Local Macros (arithmetic core) 
// =============================================================================
`define OP_uimul ui_mul // which module to use for UI addition

module PipePE_ui_mul
#(
// =============================================================================
// ** Parameters 
// =============================================================================
// Size of word 
  parameter N = 64 
)

(
// =============================================================================
// ** Ports 
// =============================================================================
  input           clk,
  input           rst, //redundant
  input           trigger, //redundant
  output          cts, // Always asserted for ALWAYS-ON modules


  output [N-1:0]  out,
  input  [N-1:0]  in1,
  input  [N-1:0]  in2
);

// =============================================================================
// ** Procedures and assignments
// =============================================================================

//registered inputs for pipelining stage
reg [N-1:0]  in1_z1;
reg [N-1:0]  in2_z1;

always @(posedge clk) begin
  in1_z1 <= in1;
  in2_z1 <= in2;
end

//The FU computing output 
`OP_uimul #(N) uimul01 (out, in1_z1, in2_z1);

// cts set to 1 for ALWAYS-ON PEs
assign cts = 1'b1;

endmodule

// =============================================================================
// ** UNDEFINE Local Macros  
// =============================================================================
`undef OP_uimul 


