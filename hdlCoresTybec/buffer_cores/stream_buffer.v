//WN, 2019.06.11, Glasgow
//A generic delay line (to be generated eventually with possibility of multiple taps)
//Based on earlier work with smache, modified for AXI4 stream interface

module stream_buffer
#(
    parameter STREAMW = 32
  , parameter SIZE    = 1
)

(
  input                 clk,
  input                 rst,
  input [STREAMW-1:0]   in1_s0,
  
  //single AXI interface upstream
  input                 ivalid_in1_s0,
  output                iready,
  
  //downstream can have multiple taps --> AXI interfaces
  input                 oready,
  output                ovalid
  output [STREAMW-1:0]  out1_s0
);

//shoft register bank for data, and ovalid(s)
reg [STREAMW-1:0] offsetRegBank [0:SIZE-1];   
reg               valid_shifter [0:SIZE-1];   

//iready when all oready's asserted
assign iready = 1'b1
              & oready
              ;
              
//tap at delay = 1              
assign ovalid  = valid_shifter[0];
assign out1_s0 = offsetRegBank[0];

/*
////SYNCH READ //
always @ (posedge clk) begin // Write port
    q0 <= offsetRegBank[raddr0];
    q1 <= offsetRegBank[raddr1];
    q2 <= offsetRegBank[raddr2];
    q3 <= offsetRegBank[raddr3];
    q4 <= offsetRegBank[raddr4]; 
end
*/

////SYNCH READ // //undo
//The offset register bank needs to hold output at !din_valid,
//otherwise the wrong data is pre-loaded and then read by the kernel
//always @ (posedge clk) begin // Write port
//  if(ivalid) begin
//    q0 <= offsetRegBank[0]; //delay = 1
//    //q1 <= offsetRegBank[raddr1];
//    //q2 <= offsetRegBank[raddr2];
//    //q3 <= offsetRegBank[raddr3];
//    //q4 <= offsetRegBank[raddr4]; 
//    end 
//  else begin
//    q0 <= q0;
//    //q1 <= q1;
//    //q2 <= q2;
//    //q3 <= q3;
//    //q4 <= q4; 
//  end
//end

//SHIFT write
//since I am also shifting ivalid --> ovalid, I don't need to
//halt the data shift register when input not valid. 
//when ivalid is negated (and do data is invalid), the
//invalid data will always come out the other end with ovalid negated

always @(posedge clk) begin 
//  if(ivalid) begin
    offsetRegBank[0]  <=  in1_s0; 
    valid_shifter[0]  <=  ivalid_in1_s0;
    //offsetRegBank[1]   <=  offsetRegBank[0]; 
    //offsetRegBank[2]   <=  offsetRegBank[1]; 
    //offsetRegBank[3]   <=  offsetRegBank[2]; 
    //offsetRegBank[4]   <=  offsetRegBank[3]; 
    //offsetRegBank[5]   <=  offsetRegBank[4]; 
    //offsetRegBank[6]   <=  offsetRegBank[5]; 
    //offsetRegBank[7]   <=  offsetRegBank[6]; 
    //offsetRegBank[8]   <=  offsetRegBank[7]; 
    //offsetRegBank[9]   <=  offsetRegBank[8]; 
    //offsetRegBank[10]  <=  offsetRegBank[9]; 
    //offsetRegBank[11]  <=  offsetRegBank[10]; 
    //offsetRegBank[12]  <=  offsetRegBank[11]; 
    //offsetRegBank[13]  <=  offsetRegBank[12]; 
    //offsetRegBank[14]  <=  offsetRegBank[13]; 
    //offsetRegBank[15]  <=  offsetRegBank[14]; 
    //offsetRegBank[16]  <=  offsetRegBank[15]; 
    //offsetRegBank[17]  <=  offsetRegBank[16]; 
    //offsetRegBank[18]  <=  offsetRegBank[17]; 
    //offsetRegBank[19]  <=  offsetRegBank[18]; 
    //offsetRegBank[20]  <=  offsetRegBank[19]; 
    //offsetRegBank[21]  <=  offsetRegBank[20]; 
    //offsetRegBank[22]  <=  offsetRegBank[21]; 
    //offsetRegBank[23]  <=  offsetRegBank[22]; 
    //offsetRegBank[24]  <=  offsetRegBank[23];
//  end 
//  else begin
//    offsetRegBank[0]   <=  offsetRegBank[0]; 
//    valid_shifter[0]   <=  valid_shifter[0];
//    //offsetRegBank[1]   <=  offsetRegBank[1]; 
//    //offsetRegBank[2]   <=  offsetRegBank[2]; 
//    //offsetRegBank[3]   <=  offsetRegBank[3]; 
//    //offsetRegBank[4]   <=  offsetRegBank[4]; 
//    //offsetRegBank[5]   <=  offsetRegBank[5]; 
//    //offsetRegBank[6]   <=  offsetRegBank[6]; 
//    //offsetRegBank[7]   <=  offsetRegBank[7]; 
//    //offsetRegBank[8]   <=  offsetRegBank[8]; 
//    //offsetRegBank[9]   <=  offsetRegBank[9]; 
//    //offsetRegBank[10]  <=  offsetRegBank[10];
//    //offsetRegBank[11]  <=  offsetRegBank[11]; 
//    //offsetRegBank[12]  <=  offsetRegBank[12]; 
//    //offsetRegBank[13]  <=  offsetRegBank[13]; 
//    //offsetRegBank[14]  <=  offsetRegBank[14]; 
//    //offsetRegBank[15]  <=  offsetRegBank[15]; 
//    //offsetRegBank[16]  <=  offsetRegBank[16]; 
//    //offsetRegBank[17]  <=  offsetRegBank[17]; 
//    //offsetRegBank[18]  <=  offsetRegBank[18]; 
//    //offsetRegBank[19]  <=  offsetRegBank[19]; 
//    //offsetRegBank[20]  <=  offsetRegBank[20]; 
//    //offsetRegBank[21]  <=  offsetRegBank[21]; 
//    //offsetRegBank[22]  <=  offsetRegBank[22]; 
//    //offsetRegBank[23]  <=  offsetRegBank[23]; 
//    //offsetRegBank[24]  <=  offsetRegBank[24];
//  end  
end

endmodule