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
// A generic Compute Unit template for TyBEC
//
// ============================================================================= 

module <module_name>
#(  
  // ============================================================
  // ** Parameters 
  // ===========================================================
  // Parameters inherit from defines in include file. Default 
  // values defined here and must be overwritten as needed
    parameter ID_LMEM_a         = 1 
  , parameter ID_LMEM_b         = 2 
  , parameter ID_LMEM_c         = 3 
  , parameter DataW             = 32
<params>
)

(
// =============================================================================
// ** Ports 
// =============================================================================
    input 	clk 
  , input 	rst 	
  , input 	start
  , output	done 
	
// PLACEHOLDER: access ports to GMEM (Global Memory - DRAM on FPGA-board)
// PLACEHOLDER: memory mapped IOs for DMA access   
);

// =============================================================================
// ** Connection wires 
// =============================================================================

<LMEM_connection_wires>

// =============================================================================
// *** Memories
// =============================================================================

<LMEM_instantiations>

// -----------------------------------------------------------------------------
// *** Wrapped_Kernel
// -----------------------------------------------------------------------------

<childCores>


endmodule            
