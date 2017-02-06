// =============================================================================
// Company      : Unversity of Glasgow, Comuting Science
// Author:        Syed Waqar Nabi
// 
// Create Date  : 2014.07.10
// Module Name  : LMEM
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
// Just implements a true-dual-port Block RAM (M20K) in Stratix devices
// Can evolve to be made a wrapper over different types of RAMs that can be
// chosen at compile time
// See http://www.altera.co.uk/literature/hb/qts/qts_qii51007.pdf
// =============================================================================

module LMEM
#(  
  parameter DATA_WIDTH  = 18,
  parameter ADDR_WIDTH  = 10, //1K-word memory
  parameter INIT_VALUES = 0, //ennumerated value indicating which DAT file to read data from - shortcut 
  parameter ID_LMEM_a   = 1,
  parameter ID_LMEM_b   = 2,
  parameter ID_LMEM_c   = 3
)  

(
  input                     we_a  , 
                            we_b  , 
                            clk   ,

  input [(DATA_WIDTH-1):0]  data_a, 
                            data_b,
  input [(ADDR_WIDTH-1):0]  addr_a, 
                            addr_b,

  output reg [(DATA_WIDTH-1):0] q_a, 
                                q_b
);

// Declare the RAM variable
reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

//WN: changed := to <= as := only allowed in System Verilog
always @ (posedge clk)
begin // Port A
  if (we_a)
  begin
    ram[addr_a] <= data_a;
    q_a <= data_a;
  end
  else
    q_a <= ram[addr_a];
end

always @ (posedge clk)
begin // Port b
  if (we_b)
  begin
    ram[addr_b] <= data_b;
    q_b <= data_b;
  end
  else
    q_b <= ram[addr_b];
end


//initial
//  if(INIT_VALUES==ID_LMEM_a)
//    $readmemh("../../../data/a.dat", ram);
//  else if (INIT_VALUES==ID_LMEM_b) 
//    $readmemh("../../../data/b.dat", ram);
//  else if (INIT_VALUES==ID_LMEM_c) 
//    $readmemh("../../../data/c.dat", ram);
//  else ;
    //no need to init memories holding results 
  
endmodule

