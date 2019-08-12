// synopsys translate_off
//`timescale 1 ps / 1 ps


//utilities
`include "util.v"

// synopsys translate_on
module func_hdl_top
#(  
   parameter DATAW     = <dataw>
  ,parameter STREAMW   = <streamw>
   
)
(
   input   clock 
  ,input   resetn
  ,input   ivalid 
  ,input   iready
  ,output  ovalid 
  ,output  oready
  <ports>
);

//statically synchronized, no handshaking 
assign ovalid = 1'b1;
assign oready = 1'b1;

// ivalid, iready, resetn are ignored
wire rst = !resetn;
wire ovalidDut; 

//child instantiation
<localOutputWires>
<concatOutputs>
main main_i(
   .clk               (clock)
  ,.rst               (rst)
  ,.stall             (!ivalid)
  ,.ovalid            (ovalidDut)
<childPortConnections>
);
  
endmodule
