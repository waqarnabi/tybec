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
// NOTE ON AXI STREAM PROTOCOL:
//I am working on a IREADY **before** IVALID mechanism
//That is, the consimer indicates it is READY when it is ready, irrespetive of the 
//IVALID state.
//Typiclaly, a node will look at OREADY downstream and 
//assert IREADY accordingly, but since this is a (decoupling) FIFO buffer,
//it simply asserts IREADY when it is not empty
//In such a situation, write  happens as soon as IVALID
//is asserted
//Read happens as soon as OREADY and OVALID are asserted
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
  , output reg                ovalid 
  , input                     oready
  , output                    iready
  , input                     ivalid_in1_s0
  , input      [STREAMW-1:0]  in1_s0
  , output     [STREAMW-1:0]  out1_s0
);


wire empty;

//ovalid should follow ~empty with a single cycle delay
always @(posedge clk)
  ovalid <= ~empty;

//always @(*)
//  ovalid = ~empty;


//not full = iready
wire full;
assign iready = ~full;

//read and write
wire write  = ivalid_in1_s0 & (~full);
wire read   = oready & ovalid;


//instantiate buffer
<instFifoBuff>

endmodule 