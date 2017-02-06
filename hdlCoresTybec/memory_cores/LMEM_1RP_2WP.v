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
// a read port(a), and 4 write ports (z, y, x, w)
// Based on a a true-dual-port Block RAM (M20K) in Stratix devices
//  - Implemented by creating a control wrapper around the dual-port instance of
//  BlockRAM.
//  - Simultaneous writes on 4 parts are read into fifos which are then
//  de-interleaved on the two write ports of the BRAM. 
//  - The same two write ports can be used for reading as well, but only one of
//  them is propagated via the wrapper.
//  - If the same address is written concurrently on any of the external
//  ports, the outcome will be indeterminate
//  - *NOTE* There is a maximum latency between when a data is written on the
//  external port, and when it has been committed to the memory, and reading
//  before this latency MAY (though not necessarily) give the OLD data. 
//  of Number-of-External-Write-Ports / Number 
//
//
// See http://www.altera.co.uk/literature/hb/qts/qts_qii51007.pdf
// =============================================================================

module LMEM_1RP_4WP
#(  
  parameter DATA_WIDTH = 18,
  parameter ADDR_WIDTH = 8,
  parameter INIT_VALUES = 0 //ennumerated value indicating which DAT file to read data from - shortcut 
)  

(
  input                     we_z  , 
                            we_y  , 
                            clk   ,

  input [(DATA_WIDTH-1):0]  data_z, 
                            data_y,

  input [(ADDR_WIDTH-1):0]  addr_a, 
                            addr_z,
                            addr_y,

  output reg [(DATA_WIDTH-1):0] q_a 
);


reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
  // Declare the RAM variable


wire [1:0] w_cntrl_word = {we_z, we_y};


always @(posedge clk)
begin
  case (w_cntrl_word)
    // no writes
    4'b00: ;
    // one write
    // zy
    4'b10: begin ram[addr_z]<=data_z; end
    4'b01: begin ram[addr_y]<=data_y; end
    // two writes
    // zy
    4'b11: begin ram[addr_z]<=data_z; ram[addr_y]<=data_y; end
    default: ;
  endcase
end

always @(posedge clk)
	q_a <= ram[addr_a];
endmodule

