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
//============================================================================= 


// ******** NOTE: This testbench requires expected results to be placed in ../../../../../../../c/verifyChex.dat **********
//                The generated code should automatically be at this position relative to the C folder            
// NOTE: above comment is obsolete?
// obsolete?
//Should I simulate stalls?
//`define SIMSTALL

//utilities
//`include "../rtl/util.v"
 
 
`define TY_GVECT    <globalVect> 

//The distinction between DATAW and STREAMW is important when using floats with 
//flopoco
// DATAW: is the width of the data "payload"
// STREAMW: may have additional control bits appended (e.g. 2 bits in case of flopoco)
`define DATAW       <dataw>
`define STREAMW     <streamw>

  `define SIZE        <size>
`define NINPUTS     <ninputs>
`define NOUTPUTS     <noutputs>
//`define IN_OUT_LAT  <latency>
//`define STREAMW     <streamw> 
  //
<defFloat>

//verify results up to how many decimal places
`define VERPRECBITS 1
`define VERPREC     10**`VERPRECBITS

module testbench;
 <FpHelper>

// -----------------------------------------------------------------------------
// ** Parameters, and Locals
// -----------------------------------------------------------------------------
// Inputs to uut
reg   clk ;
reg   rst_n ;

//AXI-stream control signals to DUT  
reg  ivalid_todut_r;
wire ivalid_todut  ;
wire oready_todut  = 1'b1;
wire ovalid_fromdut;
wire iready_fromdut;  //combined signal
<wire_iready_fromduts>

//wire iready_fromdut0; 
//wire iready_fromdut1;

//index and WI counters
reg  [`DATAW-1:0] lincount; 
reg  [`DATAW-1:0] wi_count; 

//wires for accessing child ports
<portwires>

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
<declaregmemarrays>

//fill up the  buffer with data
integer index0;
initial 
  for (index0=0; index0 < `SIZE; index0 = index0 + 1) begin
<initarrays>
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
<readCResults>
end

// -----------------------------------------------------------------------------
// ** Instantiations
// -----------------------------------------------------------------------------

wire [(`STREAMW*`TY_GVECT*`NINPUTS)-1 :0]  packed_data_in;
wire [(`STREAMW*`TY_GVECT*`NOUTPUTS)-1:0]  packed_data_out;

assign packed_data_in  =  {
<packDataIn>};

assign {<packDataOut>} = packed_data_out;

func_hdl_top 
//#(
//   .C_DATA_WIDTH   (`DATAW) 
//  ,.C_NUM_CHANNELS (2)
//  )
func_hdl_top_i
(
   .aclk      (clk)
  ,.areset    (~rst_n)
  ,.s_tvalid  ({<ivalid_toduts>})
  ,.s_tdata   (packed_data_in)
  ,.s_tready  ({<iready_fromduts>})
  ,.m_tvalid  (ovalid_fromdut)    
  ,.m_tdata   (packed_data_out)
  ,.m_tready  (oready_todut)
  
 );
//since input nodes are (supposed to be) synchronized can use iready from any one of them
assign iready_fromdut = iready_fromdut0;

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
//NOTE/TODO: the reset dependence was added as float datapath was failing
// --> test it again with integers
always @(posedge clk) begin
  if(~rst_n)
    ivalid_todut_r <= 0;
  else begin
`ifdef SIMSTALL
  //if ivalid was negated, and the count is not zero (75% probability), then keep it negated
  //should occassionally ivalid negated longer, upto 3 (4?) cycles
  if (!(ivalid_todut_r) && (ivalid_count !=0))
    ivalid_todut_r <= ivalid_todut_r;
  //otherwise, assign ivalid = 1 unless this following, infrequent condition is satisfied
  else
  ivalid_todut_r <= ~(($urandom%(`SIZE))==0);   //less frequent ivalid negations
  //ivalid <= ~(($urandom%(`SIZE/4))==0); //more frequent 
  //ivalid <= ~(($urandom%11)==0);        //much more frequent
`else
  ivalid_todut_r <= 1;  
`endif  
  end//else
end//always

//ivalid to DUT only *IF* I can see iready from it first 
//I follow if VALID *after* READ protocol; otherwise data starts propagating when iready not asserted
//So ivalid_todut now takes into account iready from DUT, and hence we can use this as the main
//control signal for controlling the flow/stall of the pipeline
assign ivalid_todut = ivalid_todut_r & iready_fromdut;
  
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

//wire [31:0] effaddr = lincount-(`IN_OUT_LAT*<ioVect>);
<excFieldFlopoco>
<assigninputdata>
                            
// writing back to drams...
always @(posedge clk) 
  if(ovalid_fromdut) begin 
<assignoutputdata>
  end



// -----------------------------------------------------------------------------
// ** Logging/displaying results
// -----------------------------------------------------------------------------
initial  begin
  $fdisplay(fverify, ":: Time stamp = <timeStamp> ::\n\n");
  $fdisplay(fverify, "\t\t           time   index    resultfromC[index]  <array4verifyingResult>[index]");
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

//these variables used only when fp data
real scalarResGold;
real scalarResCalc;
integer scalarResGold2Compare;
integer scalarResCalc2Compare;

always @ (posedge clk)  begin
  if(checkResultCond_r) begin
    for(index = 0; index < `SIZE; index=index+1 ) begin
//---------
`ifdef FLOAT
//---------
       scalarResGold = bitstorealSingle(resultfromC[index]);
       scalarResCalc = bitstorealSingle(<array4verifyingResult>[index]);
       scalarResGold2Compare=$rtoi(`VERPREC*scalarResGold);
       scalarResCalc2Compare=$rtoi(`VERPREC*scalarResCalc);

       $display("Comparing at index=%d, Gold = %f, Calc = %f"
                 ,index
                 //, scalarResGold2Compare
                 //, scalarResCalc2Compare
                 , scalarResGold
                 , scalarResCalc
                );       
       
      $fdisplay(fverify, $time/(5*2), "%d\t||%f\t%f"
                       , index
                       , scalarResGold
                       , scalarResCalc
                );
        if(scalarResGold2Compare!=scalarResCalc2Compare) begin
          $display("FAIL: Verification failed at index=%d, expected = %f, calc = %f"
                    ,index
                    ,scalarResGold
                    ,scalarResCalc
                   );
          success=0;
        end//if
    end//for
//---------
//integer data
`else
//---------
      $fdisplay(fverify, $time/(5*2), "%d\t||%d\t%d"
      //$fdisplay(fverify, $time/(5*2), "%d\t||\t%d"
                       , index
                       , resultfromC[index]
                       , <array4verifyingResult>[index]
                );
                
        if(resultfromC[index]!==<array4verifyingResult>[index]) begin
          $display("FAIL: Verification failed at index=%d, expected = %d, calc = %d"
                    ,index
                    ,resultfromC[index]
                    ,<array4verifyingResult>[index]
                   );
          success=0;
        end//if
    end//for
//---------
`endif
//---------
    
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
//   $fdisplay(fverify, "\t\t           time   index    resultfromC[index]  <outputData>[index]");
// 
// initial begin
//   success = 1;
//   endsim = 0;
// end
// 
// //wire  checkResultCond  = (lincount>=`SIZE-1+(`IN_OUT_LAT*<ioVect>)); 
// wire  checkResultCond  = (lincount==`SIZE-1+(`IN_OUT_LAT*<ioVect>)); 
// reg   checkResultCond_r;
// always @(posedge clk)
//  checkResultCond_r <= checkResultCond;
// 
// 
//  
// integer index;
// <result_t> scalarResGold;
// <result_t> scalarResCalc;
// integer scalarResGold2Compare;
// integer scalarResCalc2Compare;
// 
// always @ (posedge clk)  begin
//   if(checkResultCond_r) begin
//     for(index = 0; index < `SIZE; index=index+1 ) begin
//        scalarResGold = <getScalarResGold>
//        scalarResCalc = <getScalarResCalc><outputData><getScalarResCalcEnd>
//        scalarResGold2Compare=<getScalarResGold2Compare>
//        scalarResCalc2Compare=<getScalarResCalc2Compare>
// 
//        $display("Comparing at index=%d, Gold = %d, Calc = %d"
//                  ,index
//                  , scalarResGold2Compare
//                  , scalarResCalc2Compare
//                 );       
//        
//       $fdisplay(fverify, $time/(5*2), "%d\t||%<PT>\t%<PT>"
//                        , index
//                        , scalarResGold
//                        , scalarResCalc
//                 );
//         if(scalarResGold2Compare!=scalarResCalc2Compare) begin
//           $display("FAIL: Verification failed at index=%d, expected = %<PT>, calc = %<PT>"
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
