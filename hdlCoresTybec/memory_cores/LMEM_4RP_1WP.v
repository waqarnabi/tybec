// =============================================================================
// Company      : Unversity of Glasgow, Comuting Science
// Author:        Syed Waqar Nabi
// 
// Create Date  : 2014.08.28                         
// Module Name  : LMEM_4RP_1WP
// Project Name : 
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
// 4 read ports(a, b, c, d), and 1 write port (z)
// Based on a a true-dual-port Block RAM (M20K) in Stratix devices
// To  incorporate 4 simultaneous reads, most likely 4 identical BlockRAMs
// will be instantiated TODO confirm from synthesis
// See http://www.altera.co.uk/literature/hb/qts/qts_qii51007.pdf
// "The Quartus II software infers true dual-port RAMs in Verilog HDL and VHDL
// "with any combination of independent read or write operations in the same clock cycle, with at most two
// "unique port addresses, performing two reads and one write, two writes and one read, or two writes and two
// "reads in one clock cycle with one or two unique addresses.
// =============================================================================

module LMEM_4RP_1WP
#(  
  parameter DATA_WIDTH  = 18,
  parameter ADDR_WIDTH  = 10, //1K words by default
  parameter INIT_VALUES = 0, //ennumerated value indicating which DAT file to read data from - shortcut 
  parameter ID_LMEM_a   = 1,
  parameter ID_LMEM_b   = 2,
  parameter ID_LMEM_c   = 3        
)  

(
  input                     we_0  , 
                            clk   ,

  input [(DATA_WIDTH-1):0]  data_0, 

  input [(ADDR_WIDTH-1):0]  raddr_0, 
                            raddr_1,
                            raddr_2,
                            raddr_3,
                            waddr_0,

  output reg [(DATA_WIDTH-1):0] q_0,
                                q_1,
                                q_2,
                                q_3

);

//parameter DATA_WIDTH = 8;
//parameter ADDR_WIDTH = 6;

// Declare the RAM variable
reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

// --------------- WRITE -----------------------
//WN: changed := to <= as := only allowed in System Verilog
always @ (posedge clk)
begin // Port Z
  if (we_0)
    ram[waddr_0] <= data_0;
end


// --------------- READS -----------------------
always @ (posedge clk)
begin
  q_0 <= ram[raddr_0];
  q_1 <= ram[raddr_1];
  q_2 <= ram[raddr_2];
  q_3 <= ram[raddr_3];
end
  

endmodule

