// =============================================================================
// Company      : Unversity of Glasgow, Comuting Science
// Author:        Syed Waqar Nabi
// 
// Create Date  : 2014.07.10
// Module Name  : LMEM
// Project Name : nbody hdl 
// Target Devices: Stratix V
// Tool versions: 
// Description  : 
//
// Dependencies : 
//
// Revision     : 
// Revision 0.01. File Created
// 
// Conventions  : 
// =============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// module for implementing LMEM in TyTra architecture
//
// See http://www.altera.co.uk/literature/hb/qts/qts_qii51007.pdf
// =============================================================================

module LMEM_1RP_1WP
#(  
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 6,
  parameter INIT_VALUES = 0 //ennumerated value indicating which DAT file to read data from - shortcut 
)  

(
  input 							 clk,
  input                     we_0  ,

  input [(DATA_WIDTH-1):0]  data_0, 

  input [(ADDR_WIDTH-1):0]  raddr_0, 
                            waddr_0,

  output reg [(DATA_WIDTH-1):0] q_0 
);


reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
  // Declare the RAM variable

always @(posedge clk)
  if(we_0)
    ram[waddr_0] <= data_0;  

always @(posedge clk)
  q_0 <= ram[raddr_0];

endmodule

