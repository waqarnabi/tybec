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
// A generic module template for use by Tytra Back-End Compiler
// (TyBEC) to generate custom combinatorial (single-cycle) modules
//
// With registered inputs
// ============================================================================= 

module <module_name>
(
// =============================================================================
// ** Ports 
// =============================================================================
    input clk
<ports>  
);

// =============================================================================
// ** Procedures and assignments
// =============================================================================     

//--------- registered inputs ----------
<inputRegisters>

//--------- combinational logic ----------
<combLogic>

endmodule            

