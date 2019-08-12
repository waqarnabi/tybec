// =============================================================================
// Company              : Unversity of Glasgow, Comuting Science
// Template Author      :        Syed Waqar Nabi
//
// Project Name         : TyTra
//
// Target Devices       : Stratix V 
//
// Generated Design Name: untitled
// Generated Module Name: testbench 
// Generator Version    : R17.0
// Generator TimeStamp  : Mon Oct 29 16:59:19 2018
// 
// Dependencies         : <dependencies>
//
// 
// =============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
//============================================================================= 


// ******** NOTE: This testbench requires expected results to be placed in ../../../../../../../c/verifyChex.dat **********
//                The generated code should automatically be at this position relative to the C folder            
// NOTE: above comment is obsolete?
// obsolete?
//Should I simulate stalls?
//`define SIMSTALL

//utilities
//`include "../rtl/util.v"
 
 
`define TY_GVECT    1 
`define DATAW       32
`define STREAMW     32
`define SIZE        1024
`define NINPUTS     2
`define NOUPUTS     1
//`define IN_OUT_LAT  5
//`define STREAMW     32 
  //


//verify results up to how many decimal places
`define VERPRECBITS 1
`define VERPREC     10**`VERPRECBITS

module testbench;
 

// -----------------------------------------------------------------------------
// ** Parameters, and Locals
// -----------------------------------------------------------------------------
// Inputs to uut
reg   clk ;
reg   rst_n ;

//AXI-stream control signals to DUT  
reg  ivalid_todut  ;
wire oready_todut  = 1'b1;
wire iready_fromdut;
wire ovalid_fromdut;

//index and WI counters
reg  [`DATAW-1:0] lincount; 
reg  [`DATAW-1:0] wi_count; 

//wires for accessing child ports
wire [`STREAMW-1:0] vin1_stream_load_data_s0;
wire [`STREAMW-1:0] vin0_stream_load_data_s0;
wire [`STREAMW-1:0] vout_stream_store_data_s0;


//other variables
reg [`DATAW-1:0]  resultfromC     [0:(`SIZE*3)];  
integer           success;
integer           endsim;

// -----------------------------------------------------------------------------
// ** File handlers
// -----------------------------------------------------------------------------
////integer fhandle1;
integer flog;	    // output for man
integer fverify;	// output for machine
//
initial
begin
  flog    = $fopen("LOG.log");
  fverify = $fopen("verifyhdl.dat");	
end

// -----------------------------------------------------------------------------
// ** Initialize
// -----------------------------------------------------------------------------

//arrays in the dram
reg [`DATAW-1:0]  vin1  [0:`SIZE-1];
reg [`DATAW-1:0]  vin0  [0:`SIZE-1];
reg [`DATAW-1:0]  vout  [0:`SIZE-1];


//fill up the  buffer with data
integer index0;
initial 
  for (index0=0; index0 < `SIZE; index0 = index0 + 1) begin
    vin1[index0] = index0+1;
    vin0[index0] = index0+1;
    vout[index0] = 0;

  end
  
////zero padding  
//integer index1;
//initial 
//  for (index1=`SIZE; index1 < `SIZE+`IN_OUT_LAT; index1 = index1 + 1) begin
//<zeropadarrays-not>  
//  end
//
initial begin
////golden result from C
$readmemh("../../../../../../../c/verifyChex.dat", resultfromC);

end

// -----------------------------------------------------------------------------
// ** Instantiations
// -----------------------------------------------------------------------------

wire [(`STREAMW*`TY_GVECT*`NINPUTS)-1:0]  packed_data_in;
wire [(`STREAMW*`TY_GVECT)-1         :0]  packed_data_out;

assign packed_data_in  =  {
                           vin1_stream_load_data_s0
                          ,vin0_stream_load_data_s0
};

assign { vout_stream_store_data_s0 } = packed_data_out;

func_hdl_top 
//#(
//   .C_DATA_WIDTH   (`DATAW) 
//  ,.C_NUM_CHANNELS (2)
//  )
func_hdl_top_i
(
   .aclk      (clk)
  ,.areset    (~rst_n)
  ,.s_tvalid  ({ivalid_todut, ivalid_todut})
  ,.s_tdata   (packed_data_in)
  ,.s_tready  ()           
  ,.m_tvalid  (ovalid_fromdut)
  ,.m_tdata   (packed_data_out)
  ,.m_tready  (oready_todut)
  
 );

//<connectchildports-not>  


// -----------------------------------------------------------------------------
// ** CLK and RST_N
// -----------------------------------------------------------------------------
initial 
  clk   <= 0;
  
always
  #(5) clk = ~clk;
  
initial 
begin
  // RESET PULSE
  rst_n <= 1'b0; 
  @(posedge clk);
  @(posedge clk);  
  rst_n <= 1'b1; 
end

// -----------------------------------------------------------------------------
// ** control signals/counters
// -----------------------------------------------------------------------------
    
//a little counter to make ivalid last longer
reg [1:0] ivalid_count;

always @(posedge clk) begin
  if(~rst_n)
   ivalid_count <=0;
  else
   ivalid_count <= ivalid_count + 1;
end

//ivalid to DUT (randomly negate to simulate SHELL behaviour)
//-----------------------------------------------------------
//generate a random number, and then use it to create a boolean
//that is negated for ~10% of the time
always @(posedge clk) begin
`ifdef SIMSTALL
  //if ivalid was negated, and the count is not zero (75% probability), then keep it negated
  //should occassionally ivalid negated longer, upto 3 (4?) cycles
  if (!(ivalid_todut) && (ivalid_count !=0))
    ivalid_todut <= ivalid_todut;
  //otherwise, assign ivalid = 1 unless this following, infrequent condition is satisfied
  else
  ivalid_todut <= ~(($urandom%(`SIZE))==0);   //less frequent ivalid negations
  //ivalid <= ~(($urandom%(`SIZE/4))==0); //more frequent 
  //ivalid <= ~(($urandom%11)==0);        //much more frequent
`else
  ivalid_todut <= 1;  
`endif  
end
  
//linear index counter to keep track of where we are, and input to the DUT
//------------------------------------------
always @(posedge clk)
  if(~rst_n)
    lincount <= 0;
  else if (lincount>=`SIZE-1)
    lincount <= 0;
  else if (ivalid_todut)
    lincount <= lincount + `TY_GVECT;
  else  
    lincount <= lincount;
    
//linear index counter to keep track of where we are at the output
//------------------------------------------
reg [31:0] effaddr;

always @(posedge clk)
  if(~rst_n)
    effaddr <= 0;
  else if (effaddr==`SIZE-`TY_GVECT)
    effaddr <= 0;
  //increment if output from DUT valid
  else if (ovalid_fromdut)
    effaddr <= effaddr + `TY_GVECT;
  else  
    effaddr <= effaddr;    
    
//work instance counter    
//------------------------------------------
always @(posedge clk)
  if(~rst_n)
    wi_count <= 0;
  else if ((lincount==`SIZE-`TY_GVECT) && ivalid_todut)
    wi_count <= wi_count + 1;
  else
    wi_count <= wi_count;  
    
// -----------------------------------------------------------------------------
// ** reading/writing the "dram" arrays 
// -----------------------------------------------------------------------------

//wire [31:0] effaddr = lincount-(`IN_OUT_LAT*1);

assign vin1_stream_load_data_s0 = vin1[lincount+0];
assign vin0_stream_load_data_s0 = vin0[lincount+0];

                            
// writing back to drams...
always @(posedge clk) 
  if(ovalid_fromdut) begin 
    vout[effaddr+0] <= vout_stream_store_data_s0;

  end



// -----------------------------------------------------------------------------
// ** Logging/displaying results
// -----------------------------------------------------------------------------
initial  begin
  $fdisplay(fverify, ":: Time stamp = Mon Oct 29 16:59:19 2018 ::\n\n");
  $fdisplay(fverify, "\t\t           time   index    resultfromC[index]  vout[index]");
end

initial begin
  success = 1;
  endsim = 0;
end

wire  checkResultCond  = (effaddr==`SIZE-`TY_GVECT); 
reg   checkResultCond_r;
always @(posedge clk)
 checkResultCond_r <= checkResultCond;


integer index;
always @ (posedge clk)  begin
  if(checkResultCond_r) begin
    for(index = 0; index < `SIZE; index=index+1 ) begin
      $fdisplay(fverify, $time/(5*2), "%d\t||%d\t%d"
      //$fdisplay(fverify, $time/(5*2), "%d\t||\t%d"
                       , index
                       , resultfromC[index]
                       , vout[index]
                );
                
        if(resultfromC[index]!==vout[index]) begin
          $display("FAIL: Verification failed at index=%d, expected = %d, calc = %d"
                    ,index
                    ,resultfromC[index]
                    ,vout[index]
                   );
          success=0;
        end//if
    end//for
    
    if(success)
      $display("TEST PASSED WITH NO ERRORS!");
    else
      $display("TEST FAIL!!!");
    
    $fclose(flog);
    $fclose(fverify);
    $stop;
  end//if
end//always  
  
// // -----------------------------------------------------------------------------
// // ** Logging/displaying results
// // -----------------------------------------------------------------------------
// initial 
//   $fdisplay(fverify, "\t\t           time   index    resultfromC[index]  vout[index]");
// 
// initial begin
//   success = 1;
//   endsim = 0;
// end
// 
// //wire  checkResultCond  = (lincount>=`SIZE-1+(`IN_OUT_LAT*1)); 
// wire  checkResultCond  = (lincount==`SIZE-1+(`IN_OUT_LAT*1)); 
// reg   checkResultCond_r;
// always @(posedge clk)
//  checkResultCond_r <= checkResultCond;
// 
// 
//  
// integer index;
// integer scalarResGold;
// integer scalarResCalc;
// integer scalarResGold2Compare;
// integer scalarResCalc2Compare;
// 
// always @ (posedge clk)  begin
//   if(checkResultCond_r) begin
//     for(index = 0; index < `SIZE; index=index+1 ) begin
//        scalarResGold = resultfromC[index];
//        scalarResCalc = vout[index];
//        scalarResGold2Compare=scalarResGold;
//        scalarResCalc2Compare=scalarResCalc;
// 
//        $display("Comparing at index=%d, Gold = %d, Calc = %d"
//                  ,index
//                  , scalarResGold2Compare
//                  , scalarResCalc2Compare
//                 );       
//        
//       $fdisplay(fverify, $time/(5*2), "%d\t||%d\t%d"
//                        , index
//                        , scalarResGold
//                        , scalarResCalc
//                 );
//         if(scalarResGold2Compare!=scalarResCalc2Compare) begin
//           $display("FAIL: Verification failed at index=%d, expected = %d, calc = %d"
//                     ,index
//                     , scalarResGold
//                     , scalarResCalc
//                    );
//           success=0;
//         end//if
//     end//for
//     
//     if(success)
//       $display("TEST PASSED WITH NO ERRORS!");
//     else
//       $display("TEST FAIL!!!");
//     
//     $fclose(flog);
//     $fclose(fverify);
//     $stop;
//   end//if
// end//always
//   
//   

endmodule
