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
// -----------------------------------------------------------------------------
// ** Ports 
// -----------------------------------------------------------------------------
    input   clk   
  , input   rst   	
  , output  iready 
  , output  ovalid 
<ivalids>
<oreadys>
<ports>  
);

<connections>

//And input valids  and output readys
<ivalidsAnd>
<oreadysAnd>

//glue logic for output control signals
assign ovalid = 
<ovalids> 
			  1'b1;
assign iready = 
<ireadysAnd> 
        oready & 
			  1'b1;

//single iready from a successor node may connect to multiple
//predecssor nodes; make those connections here
<ireadyConns>
        
<instantiations>

endmodule 
