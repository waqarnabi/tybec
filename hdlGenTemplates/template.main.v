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
// template for main (top-level synthesized module)
// (TyBEC)
//
//============================================================================= 

module <module_name>
#(  
  parameter STREAMW     = <streamw>
)

(
// =============================================================================
// ** Ports 
// =============================================================================
    input  clk   
  , input  rst   	
  , output iready 
  , input  ivalid 
  , output ovalid 
  , input  oready 

<ports>
);

// ============================================================================
// ** Instantiations
// ============================================================================

<connections>

//glue logic for output control signals
assign ovalid = 
<ovalids> 
			  1'b1;
assign iready = 
<ireadysAnd> 
			  1'b1;

<excFieldFlopoco>        

// if input data to kernel_top module is flopoco floats (with 2 control bits)
// those two bits will be appended here during instantiation

//if output data from kernel_top module is flopoco floats (with 2 control bits)
//they will be connected to narrower data signals here, so as to truncate the top-most 
//2 bits
    
<instantiations>


endmodule 