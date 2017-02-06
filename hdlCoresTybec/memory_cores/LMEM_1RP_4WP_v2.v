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


/// BUGGED VERSION: cant write to same reg memory in separate always
//blocks...


module LMEM_1RP_4WP_v2
#(  
  parameter DATA_WIDTH = 18,
  parameter ADDR_WIDTH = 10,
  parameter INIT_VALUES = 0 //ennumerated value indicating which DAT file to read data from - shortcut 
)  

(
  input                     we_z  , 
                            we_y  , 
                            we_x  , 
                            we_w  , 
                            clk   ,

  input [(DATA_WIDTH-1):0]  data_z, 
                            data_y,
                            data_x,
                            data_w,

  input [(ADDR_WIDTH-1):0]  addr_z,
                            addr_y,
                            addr_x,
                            addr_w,

  output reg [(DATA_WIDTH-1):0] q_z ,
                                q_y ,
                                q_x ,
                                q_w
                                  
);


reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
  // Declare the RAM variable


wire [3:0] w_cntrl_word = {we_z, we_y, we_x, we_w};


//WN: changed := to <= as := only allowed in System Verilog
always @ (posedge clk)
begin // Port Z
  if (we_z)
  begin
    ram[addr_z] <= data_z;
    q_z <= data_z;
  end
  else
    q_z <= ram[addr_z];
end

always @ (posedge clk)
begin // Port Y
  if (we_y)
  begin
    ram[addr_y] <= data_y;
    q_y <= data_y;
  end
  else
    q_y <= ram[addr_y];
end  

always @ (posedge clk)
begin // Port X
  if (we_x)
  begin
    ram[addr_x] <= data_x;
    q_x <= data_x;
  end
  else
    q_x <= ram[addr_x];
end  

always @ (posedge clk)
begin // Port W
  if (we_w)
  begin
    ram[addr_w] <= data_w;
    q_w <= data_w;
  end
  else
    q_w <= ram[addr_w];
end  


//always @(posedge clk)
//begin
//  case (w_cntrl_word)
//    // no writes
//    4'b0000: ;
//    // one write
//    // zyxw
//    4'b1000: begin ram[addr_z]<=data_z; end
//    4'b0100: begin ram[addr_y]<=data_y; end
//    4'b0010: begin ram[addr_x]<=data_x; end
//    4'b0001: begin ram[addr_w]<=data_w; end
//    // two writes
//    // zyxw
//    4'b1100: begin ram[addr_z]<=data_z; ram[addr_y]<=data_y; end
//    4'b1010: begin ram[addr_z]<=data_z; ram[addr_x]<=data_x; end
//    4'b1001: begin ram[addr_z]<=data_z; ram[addr_w]<=data_w; end
//    4'b0110: begin ram[addr_y]<=data_y; ram[addr_x]<=data_x; end
//    4'b0101: begin ram[addr_y]<=data_y; ram[addr_w]<=data_w; end
//    4'b0011: begin ram[addr_x]<=data_x; ram[addr_w]<=data_w; end
//    // three writes
//    // zyxw
//    4'b1110: begin ram[addr_z]<=data_z; ram[addr_y]<=data_y; ram[addr_x]<=data_x; end
//    4'b1101: begin ram[addr_z]<=data_z; ram[addr_y]<=data_y; ram[addr_w]<=data_w; end
//    4'b1011: begin ram[addr_z]<=data_z; ram[addr_x]<=data_x; ram[addr_w]<=data_w; end
//    4'b0111: begin ram[addr_y]<=data_y; ram[addr_x]<=data_x; ram[addr_w]<=data_w; end
//    // four writes
//    // zyxw
//    4'b1111: begin ram[addr_z]<=data_z; ram[addr_y]<=data_y; ram[addr_x]<=data_x; ram[addr_w]<=data_w; end
//    default: ;
//  endcase
//end
//
//always @(posedge clk)
//	q_a <= ram[addr_a];
endmodule

