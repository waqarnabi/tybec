// =============================================================================
// Company              : Unversity of Glasgow, Comuting Science
// Template Author      :        Syed Waqar Nabi
//
// Project Name         : TyTra
//
// Target Devices       : Stratix V 
//
// Generated Design Name: <design_name>
// Generated Module Name: <module_name> 
// Generator Version    : <gen_ver>
// Generator TimeStamp  : <timeStamp>
// 
// Dependencies         : <dependencies>
//
// 
// =============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// A generic module template for leaf map nodes for use by Tytra Back-End Compile
// (TyBEC)
//
// ============================================================================= 

module <module_name>
#(  
   parameter STREAMW   = <streamw>
)

(
// =============================================================================
// ** Ports 
// =============================================================================
    input                     clk   
  , input                     rst   	
  , output                    ovalid 
  , output reg <oStrWidth>    out1_s0
  , input                     oready     
  , output                    iready
//<inputReadys> <-- deprecated
<inputIvalids>
<firstOpInputPort>
<secondOpInputPort>
<thirdOpInputPort>
);

//if FP, then I need to attend this constant 2 bits for flopoco units
<fpcEF>

//unregistered output
wire <oStrWidth> out1_pre_s0;

//And input valids  and output readys
<inputIvalidsAnded>

//If any input operands are constants, assign them their value here
<assignConstants>

//dont stall if input valid and slave ready
wire dontStall = ivalid & oready;

//perform datapath operation, or instantiate module
<datapath>

//if I'm not stalling, I am ready
//assign iready = dontStall;

//if output is ready (and no locally generated stall), I am ready
//assign iready = oready & local_stall;
assign iready = oready;

//fanout iready to all inputs <-- deprecated
//<ireadysFanout>

//registered output
always @(posedge clk) begin
  if(rst)
    out1_s0 <= 0;
  else if (dontStall)
    out1_s0 <= out1_pre_s0;
  else 
    out1_s0 <= out1_s0;
end


<ovalidLogic>

endmodule 