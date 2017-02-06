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
  input                     we_0  , 
                            we_1  , 
                            we_2  , 
                            we_3  , 
                            clk   ,

  input [(DATA_WIDTH-1):0]  data_0, 
                            data_1,
                            data_2,
                            data_3,

  input [(ADDR_WIDTH-1):0]  waddr_0, 
                            waddr_1,
                            waddr_2,
                            waddr_3,
                            raddr_0,

  output reg [(DATA_WIDTH-1):0] q_0 
);


reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
  // Declare the RAM variable


wire [3:0] w_cntrl_word = {we_0, we_1, we_2, we_3};


always @(posedge clk)
begin
  case (w_cntrl_word)
    // no writes
    4'b0000: ;
    // one write
    // zyxw
    4'b1000: begin ram[waddr_0]<=data_0; end
    4'b0100: begin ram[waddr_1]<=data_1; end
    4'b0010: begin ram[waddr_2]<=data_2; end
    4'b0001: begin ram[waddr_3]<=data_3; end
    // two writes
    // zyxw
    4'b1100: begin ram[waddr_0]<=data_0; ram[waddr_1]<=data_1; end
    4'b1010: begin ram[waddr_0]<=data_0; ram[waddr_2]<=data_2; end
    4'b1001: begin ram[waddr_0]<=data_0; ram[waddr_3]<=data_3; end
    4'b0110: begin ram[waddr_1]<=data_1; ram[waddr_2]<=data_2; end
    4'b0101: begin ram[waddr_1]<=data_1; ram[waddr_3]<=data_3; end
    4'b0011: begin ram[waddr_2]<=data_2; ram[waddr_3]<=data_3; end
    // three writes
    // zyxw
    4'b1110: begin ram[waddr_0]<=data_0; ram[waddr_1]<=data_1; ram[waddr_2]<=data_2; end
    4'b1101: begin ram[waddr_0]<=data_0; ram[waddr_1]<=data_1; ram[waddr_3]<=data_3; end
    4'b1011: begin ram[waddr_0]<=data_0; ram[waddr_2]<=data_2; ram[waddr_3]<=data_3; end
    4'b0111: begin ram[waddr_1]<=data_1; ram[waddr_2]<=data_2; ram[waddr_3]<=data_3; end
    // four writes
    // zyxw
    4'b1111: begin ram[waddr_0]<=data_0; ram[waddr_1]<=data_1; ram[waddr_2]<=data_2; ram[waddr_3]<=data_3; end
    default: ;
  endcase
end

always @(posedge clk)
	q_0 <= ram[raddr_0];
endmodule

