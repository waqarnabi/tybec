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
// A generic module template for autocounters
// This is an upcounter, with wrapping
// OVALID maintained for consistency with AXI-STREAM, but it is always "valid"
// Creates an output trigger when wrapping, to allow creation of nested counters
// ============================================================================= 

module <module_name>
#(  
     parameter COUNTERW = <counterw>
   , parameter STARTAT  = <startat>
   , parameter WRAPAT   = <wrapat>
)

(
// =============================================================================
// ** Ports 
// =============================================================================
    input                     clk   
  , input                     rst   	
  , input                     trig_count
  , output                    ovalid
  , output reg [COUNTERW-1:0] counter_value_s0
  , output                    trig_wrap
);

assign ovalid     = 1'b1;

//generate trigger if reached wrap (max) value
assign trig_wrap  = (counter_value_s0 == WRAPAT);

always @(posedge clk) begin
  if(rst)
    counter_value_s0 <= STARTAT;
  else if (trig_count)
    if(trig_wrap)
      counter_value_s0 <= STARTAT;
    else
      counter_value_s0 <= counter_value_s0+1;
  else 
    counter_value_s0 <= counter_value_s0;
end

endmodule 