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
// Template for axi4 stencil buffer (no "smart" caching)
// ============================================================================= 

module <module_name>
#(  
    parameter STREAMW = <streamw>
  , parameter SIZE    = <size>
)

(
// =============================================================================
// ** Ports 
// =============================================================================
    input                     clk   
  , input                     rst   	
  , output                    iready
  , input                     ivalid_in1_s0
  , input      [STREAMW-1:0]  in1_s0
  
<ovalids>
<oreadys>
<outputs>
);

//shift register bank for data, and ovalid(s)
reg [STREAMW-1:0] offsetRegBank [0:SIZE-1];   
reg               valid_shifter [0:SIZE-1];   

//local oready only asserted when *all* outputs are ready
<oreadysAnd>

//iready when all oready's asserted
assign iready = oready;
              
//tap at relevant delays
//the valid shifter takes care of the initial latency of filling up the buffer
//if ivalid is negated anytime during operation, we simply freeze the stream buffer
//so the valid shifter never gets a "0" in there (and the data shift register never reads 
//invalid data). This contiguity of *valid* data ensures that data of a certain "offset" is 
//always available at a fixed location

<assign_ovalids>
<assign_dataouts>
//SHIFT write

always @(posedge clk) begin 
  if(ivalid_in1_s0) begin
    offsetRegBank[0]  <=  in1_s0; 
    valid_shifter[0]  <=  ivalid_in1_s0;
<shift_data_and_valid>
  end else begin
    offsetRegBank[0]  <=  offsetRegBank[0];
    valid_shifter[0]  <=  valid_shifter[0];
<dont_shift_data_and_valid>
  end
end

endmodule 