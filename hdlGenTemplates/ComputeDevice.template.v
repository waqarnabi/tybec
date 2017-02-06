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
// =============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// A generic Compute Device template for TyBEC
// ============================================================================= 

`include "includeCustomConfig.v"

module <module_name>
(
// =============================================================================
// ** Ports 
// =============================================================================
    input 	clk 
  , input 	rst 	
  , input 	start
  , output	done 
// access ports to GMEM (Global Memory - DRAM on FPGA-board)

// memory mapped IOs for DMA access   
);

// -----------------------------------------------------------------------------
// *** Compute Unit
// -----------------------------------------------------------------------------
ComputeUnit 
  #(. DataW   (`DataW)
<childCore_parameter_connections>
)
  ComputeUnit0 
  ( .clk   (clk   ) 
  , .rst   (rst   )
  , .start (start )
  , .done  (done  )
);

endmodule            
