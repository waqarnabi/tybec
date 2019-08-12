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
   parameter DATAW     = <dataw>
)

(
// =============================================================================
// ** Ports 
// =============================================================================
    input                 clk   
  , input                 rst   	
  , input                 stall
  , output reg[DATAW-1:0] out1_s0
  , output reg[DATAW-1:0] out1_s1
  , input     [DATAW-1:0] in1_s0
  , input     [DATAW-1:0] in1_s1
  , input     [DATAW-1:0] in2_s0  
  , input     [DATAW-1:0] in2_s1  
);

//unregistered output
wire [DATAW-1:0] out1_pre_s0;
wire [DATAW-1:0] out1_pre_s1;

//perform datapath operation, or instantiate module
<datapath>

//registered output
always @(posedge clk) begin
  if(rst) begin
    out1_s0 <= 0;
    out1_s1 <= 0;
  end    
  else if (stall) begin
    out1_s0 <= out1_s0;
    out1_s1 <= out1_s1;
  end
  else begin
    out1_s0 <= out1_pre_s0;
    out1_s1 <= out1_pre_s1;
  end
end

endmodule 