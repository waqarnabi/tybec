// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module ktop #(
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12 ,
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32 ,
  parameter integer C_M00_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_M00_AXI_DATA_WIDTH       = 32 ,
  parameter integer C_M01_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_M01_AXI_DATA_WIDTH       = 128
)
(
  // System Signals
  input  wire                                    ap_clk               ,
  input  wire                                    ap_rst_n             ,
  //  Note: A minimum subset of AXI4 memory mapped signals are declared.  AXI
  // signals omitted from these interfaces are automatically inferred with the
  // optimal values for Xilinx SDx systems.  This allows Xilinx AXI4 Interconnects
  // within the system to be optimized by removing logic for AXI4 protocol
  // features that are not necessary. When adapting AXI4 masters within the RTL
  // kernel that have signals not declared below, it is suitable to add the
  // signals to the declarations below to connect them to the AXI4 Master.
  // 
  // List of ommited signals - effect
  // -------------------------------
  // ID - Transaction ID are used for multithreading and out of order
  // transactions.  This increases complexity. This saves logic and increases Fmax
  // in the system when ommited.
  // SIZE - Default value is log2(data width in bytes). Needed for subsize bursts.
  // This saves logic and increases Fmax in the system when ommited.
  // BURST - Default value (0b01) is incremental.  Wrap and fixed bursts are not
  // recommended. This saves logic and increases Fmax in the system when ommited.
  // LOCK - Not supported in AXI4
  // CACHE - Default value (0b0011) allows modifiable transactions. No benefit to
  // changing this.
  // PROT - Has no effect in SDx systems.
  // QOS - Has no effect in SDx systems.
  // REGION - Has no effect in SDx systems.
  // USER - Has no effect in SDx systems.
  // RESP - Not useful in most SDx systems.
  // 
  // AXI4 master interface m00_axi
  output wire                                    m00_axi_awvalid      ,
  input  wire                                    m00_axi_awready      ,
  output wire [C_M00_AXI_ADDR_WIDTH-1:0]         m00_axi_awaddr       ,
  output wire [8-1:0]                            m00_axi_awlen        ,
  output wire                                    m00_axi_wvalid       ,
  input  wire                                    m00_axi_wready       ,
  output wire [C_M00_AXI_DATA_WIDTH-1:0]         m00_axi_wdata        ,
  output wire [C_M00_AXI_DATA_WIDTH/8-1:0]       m00_axi_wstrb        ,
  output wire                                    m00_axi_wlast        ,
  input  wire                                    m00_axi_bvalid       ,
  output wire                                    m00_axi_bready       ,
  output wire                                    m00_axi_arvalid      ,
  input  wire                                    m00_axi_arready      ,
  output wire [C_M00_AXI_ADDR_WIDTH-1:0]         m00_axi_araddr       ,
  output wire [8-1:0]                            m00_axi_arlen        ,
  input  wire                                    m00_axi_rvalid       ,
  output wire                                    m00_axi_rready       ,
  input  wire [C_M00_AXI_DATA_WIDTH-1:0]         m00_axi_rdata        ,
  input  wire                                    m00_axi_rlast        ,
  // AXI4 master interface m01_axi
  output wire                                    m01_axi_awvalid      ,
  input  wire                                    m01_axi_awready      ,
  output wire [C_M01_AXI_ADDR_WIDTH-1:0]         m01_axi_awaddr       ,
  output wire [8-1:0]                            m01_axi_awlen        ,
  output wire                                    m01_axi_wvalid       ,
  input  wire                                    m01_axi_wready       ,
  output wire [C_M01_AXI_DATA_WIDTH-1:0]         m01_axi_wdata        ,
  output wire [C_M01_AXI_DATA_WIDTH/8-1:0]       m01_axi_wstrb        ,
  output wire                                    m01_axi_wlast        ,
  input  wire                                    m01_axi_bvalid       ,
  output wire                                    m01_axi_bready       ,
  output wire                                    m01_axi_arvalid      ,
  input  wire                                    m01_axi_arready      ,
  output wire [C_M01_AXI_ADDR_WIDTH-1:0]         m01_axi_araddr       ,
  output wire [8-1:0]                            m01_axi_arlen        ,
  input  wire                                    m01_axi_rvalid       ,
  output wire                                    m01_axi_rready       ,
  input  wire [C_M01_AXI_DATA_WIDTH-1:0]         m01_axi_rdata        ,
  input  wire                                    m01_axi_rlast        ,
  // AXI4-Lite slave interface
  input  wire                                    s_axi_control_awvalid,
  output wire                                    s_axi_control_awready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr ,
  input  wire                                    s_axi_control_wvalid ,
  output wire                                    s_axi_control_wready ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata  ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb  ,
  input  wire                                    s_axi_control_arvalid,
  output wire                                    s_axi_control_arready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr ,
  output wire                                    s_axi_control_rvalid ,
  input  wire                                    s_axi_control_rready ,
  output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata  ,
  output wire [2-1:0]                            s_axi_control_rresp  ,
  output wire                                    s_axi_control_bvalid ,
  input  wire                                    s_axi_control_bready ,
  output wire [2-1:0]                            s_axi_control_bresp  ,
  output wire                                    interrupt            
);

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* DONT_TOUCH = "yes" *)
reg                                 areset                         = 1'b0;
wire                                ap_start                      ;
wire                                ap_idle                       ;
wire                                ap_done                       ;
wire [64-1:0]                       axi00_ptr0                    ;
wire [64-1:0]                       axi00_ptr1                    ;
wire [64-1:0]                       axi00_ptr2                    ;
wire [64-1:0]                       axi00_ptr3                    ;
wire [64-1:0]                       axi01_ptr0                    ;

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

///////////////////////////////////////////////////////////////////////////////
// Begin control interface RTL.  Modifying not recommended.
///////////////////////////////////////////////////////////////////////////////


// AXI4-Lite slave interface
ktop_control_s_axi #(
  .C_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .aclk       ( ap_clk                ),
  .areset     ( areset                ),
  .aclk_en    ( 1'b1                  ),
  .awvalid    ( s_axi_control_awvalid ),
  .awready    ( s_axi_control_awready ),
  .awaddr     ( s_axi_control_awaddr  ),
  .wvalid     ( s_axi_control_wvalid  ),
  .wready     ( s_axi_control_wready  ),
  .wdata      ( s_axi_control_wdata   ),
  .wstrb      ( s_axi_control_wstrb   ),
  .arvalid    ( s_axi_control_arvalid ),
  .arready    ( s_axi_control_arready ),
  .araddr     ( s_axi_control_araddr  ),
  .rvalid     ( s_axi_control_rvalid  ),
  .rready     ( s_axi_control_rready  ),
  .rdata      ( s_axi_control_rdata   ),
  .rresp      ( s_axi_control_rresp   ),
  .bvalid     ( s_axi_control_bvalid  ),
  .bready     ( s_axi_control_bready  ),
  .bresp      ( s_axi_control_bresp   ),
  .interrupt  ( interrupt             ),
  .ap_start   ( ap_start              ),
  .ap_done    ( ap_done               ),
  .ap_idle    ( ap_idle               ),
  .axi00_ptr0 ( axi00_ptr0            ),
  .axi00_ptr1 ( axi00_ptr1            ),
  .axi00_ptr2 ( axi00_ptr2            ),
  .axi00_ptr3 ( axi00_ptr3            ),
  .axi01_ptr0 ( axi01_ptr0            )
);

///////////////////////////////////////////////////////////////////////////////
// Add kernel logic here.  Modify/remove example code as necessary.
///////////////////////////////////////////////////////////////////////////////

// Example RTL block.  Remove to insert custom logic.
ktop_example #(
  .C_M00_AXI_ADDR_WIDTH ( C_M00_AXI_ADDR_WIDTH ),
  .C_M00_AXI_DATA_WIDTH ( C_M00_AXI_DATA_WIDTH ),
  .C_M01_AXI_ADDR_WIDTH ( C_M01_AXI_ADDR_WIDTH ),
  .C_M01_AXI_DATA_WIDTH ( C_M01_AXI_DATA_WIDTH )
)
inst_example (
  .ap_clk          ( ap_clk          ),
  .ap_rst_n        ( ap_rst_n        ),
  .m00_axi_awvalid ( m00_axi_awvalid ),
  .m00_axi_awready ( m00_axi_awready ),
  .m00_axi_awaddr  ( m00_axi_awaddr  ),
  .m00_axi_awlen   ( m00_axi_awlen   ),
  .m00_axi_wvalid  ( m00_axi_wvalid  ),
  .m00_axi_wready  ( m00_axi_wready  ),
  .m00_axi_wdata   ( m00_axi_wdata   ),
  .m00_axi_wstrb   ( m00_axi_wstrb   ),
  .m00_axi_wlast   ( m00_axi_wlast   ),
  .m00_axi_bvalid  ( m00_axi_bvalid  ),
  .m00_axi_bready  ( m00_axi_bready  ),
  .m00_axi_arvalid ( m00_axi_arvalid ),
  .m00_axi_arready ( m00_axi_arready ),
  .m00_axi_araddr  ( m00_axi_araddr  ),
  .m00_axi_arlen   ( m00_axi_arlen   ),
  .m00_axi_rvalid  ( m00_axi_rvalid  ),
  .m00_axi_rready  ( m00_axi_rready  ),
  .m00_axi_rdata   ( m00_axi_rdata   ),
  .m00_axi_rlast   ( m00_axi_rlast   ),
  .m01_axi_awvalid ( m01_axi_awvalid ),
  .m01_axi_awready ( m01_axi_awready ),
  .m01_axi_awaddr  ( m01_axi_awaddr  ),
  .m01_axi_awlen   ( m01_axi_awlen   ),
  .m01_axi_wvalid  ( m01_axi_wvalid  ),
  .m01_axi_wready  ( m01_axi_wready  ),
  .m01_axi_wdata   ( m01_axi_wdata   ),
  .m01_axi_wstrb   ( m01_axi_wstrb   ),
  .m01_axi_wlast   ( m01_axi_wlast   ),
  .m01_axi_bvalid  ( m01_axi_bvalid  ),
  .m01_axi_bready  ( m01_axi_bready  ),
  .m01_axi_arvalid ( m01_axi_arvalid ),
  .m01_axi_arready ( m01_axi_arready ),
  .m01_axi_araddr  ( m01_axi_araddr  ),
  .m01_axi_arlen   ( m01_axi_arlen   ),
  .m01_axi_rvalid  ( m01_axi_rvalid  ),
  .m01_axi_rready  ( m01_axi_rready  ),
  .m01_axi_rdata   ( m01_axi_rdata   ),
  .m01_axi_rlast   ( m01_axi_rlast   ),
  .ap_start        ( ap_start        ),
  .ap_done         ( ap_done         ),
  .ap_idle         ( ap_idle         ),
  .axi00_ptr0      ( axi00_ptr0      ),
  .axi00_ptr1      ( axi00_ptr1      ),
  .axi00_ptr2      ( axi00_ptr2      ),
  .axi00_ptr3      ( axi00_ptr3      ),
  .axi01_ptr0      ( axi01_ptr0      )
);

endmodule
`default_nettype wire
