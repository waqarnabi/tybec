// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////

// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1ps / 1ps

module ktop_example_adder #(
  parameter integer C_AXIS_TDATA_WIDTH = 512, // Data width of both input and output data
  parameter integer C_ADDER_BIT_WIDTH  = 32
)
(
  input wire                       aclk,
  input wire                       aresetn,

  input wire  [C_ADDER_BIT_WIDTH-1:0]   ctrl_constant,

  input wire                             s_axis_tvalid,
  output wire                            s_axis_tready,
  input wire  [C_AXIS_TDATA_WIDTH-1:0]   s_axis_tdata,
  input wire  [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_tkeep,
  input wire                             s_axis_tlast,

  output wire                            m_axis_tvalid,
  input  wire                            m_axis_tready,
  output wire [C_AXIS_TDATA_WIDTH-1:0]   m_axis_tdata,
  output wire [C_AXIS_TDATA_WIDTH/8-1:0] m_axis_tkeep,
  output wire                            m_axis_tlast

);

localparam integer LP_NUM_LOOPS = C_AXIS_TDATA_WIDTH/C_ADDER_BIT_WIDTH;
/////////////////////////////////////////////////////////////////////////////
// Variables
/////////////////////////////////////////////////////////////////////////////
integer i;
reg   [C_ADDER_BIT_WIDTH-1:0]  constant_in;
reg   [C_AXIS_TDATA_WIDTH-1:0] data_out;
reg                            areset = 1'b0;

/////////////////////////////////////////////////////////////////////////////
// Adder Logic
/////////////////////////////////////////////////////////////////////////////

always @(posedge aclk) begin
  areset <= ~aresetn;
end

// Register constant, should be set before stream.
always @(posedge aclk) begin
  constant_in <= ctrl_constant;
end

// Adder function
always @(*) begin
  for (i = 0; i < LP_NUM_LOOPS; i = i + 1) begin
    data_out[i*C_ADDER_BIT_WIDTH+:C_ADDER_BIT_WIDTH] = s_axis_tdata[C_ADDER_BIT_WIDTH*i+:C_ADDER_BIT_WIDTH] + constant_in;
  end
end

assign m_axis_tdata = data_out;
assign m_axis_tvalid = s_axis_tvalid;
assign s_axis_tready = m_axis_tready;
assign m_axis_tkeep = s_axis_tkeep;
assign m_axis_tlast = s_axis_tlast;

endmodule

`default_nettype wire

