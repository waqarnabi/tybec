// =============================================================================
// Company              : Unversity of Glasgow, Comuting Science
// Template Author      :        Syed Waqar Nabi
//
// Project Name         : TyTra
//
// Target Devices       : Stratix V 
//
// Template Create Date : 2014.12.06 (Template)
// Template Module Name : t_CoreCompute_pipe
// Template Revision    :  
// Revision 0.01. File Created
//
// Generated Design Name: $design_name$
// Generated Module Name: $module_name$ 
// Generator Version    : $gen_ver$
// Generator TimeStamp  : $gen_timestampe$
// 
// Dependencies         : $dependencies$
//
// 
// =============================================================================

// =============================================================================
// Template Description
// -----------------------------------------------------------------------------
// A generic pipelined module template for use by Tytra Back-End Compiler
// (TyBEC)
//
// =============================================================================

// =============================================================================
// ** Generator Variables 
// =============================================================================
$NSTAGES$ // number of pipeline stages
          // does *not* include the final "stage" where only the stop signal
          // is generated

$NISTREAM$ // Number of input streams                                                 
$NOSTREAM$ // Number of output streams                                                
$NISCLR$   // Number of input scalars                                                 
$NOPERSD$  // Number of unique arithmetic operators used in the pipeline (e.g. +, *)  
$NFU$      // TOTAL arithmetic FUs in the pipeline (e.g. 3+, 1* = 4)                  
$NISTRM$   // Number of local stream variables                                        


// for N=[1..NSTAGES-1]
$NPAROPS_STAGE.N$
  // number of parallel operations for each stage of pipeline
  // last stage is only for registering outputs, so only relevant till
  // NSTAGES-1
  // should be equal to $NOSTREAMS$

// for N=[1..NSTAGES-1]
 // for M=[1..NPAROPS_STAGE.N]
  $OUTPUT_VAR_STAGE_%N_PE_%M_W$ //width of output port
  $OUTPUT_VAR_STAGE_%N_PE_%M$   //name of output port
  $INPUT1_VAR_STAGE_%N_PE_%M$   //name of input port 1
  $INPUT2_VAR_STAGE_%N_PE_%M$   //name of input port 2
  $PE_MOD_STAGE_%N_PE_%M$       //name of PE module to use
    // for each parallel PE in each pipeline stage, define the IOs, and the PE
    // to use


// for N=[1..NOSTREAM]
  $NAME_OUTPUT_STREAM_%N$     // name of output stream N
  $OUTPUT_STREAM_%N_CONN_TO$  // name of local stream to which output stream is connected

          
// =============================================================================
// ** Generator Marks 
// =============================================================================



// =============================================================================
// ** Local Macros (arithmetic cores) 
// =============================================================================
$replicate N=[1..NOPERD] {`define OP_$distinct_operator.N$  $module_for_operator.N$} 


//module 
module $module_name$
#(  
  // ============================================================
  // ** Parameters 
  // ===========================================================
    //No need to generate default parameters since they will be overwritten
    $replicate N=[1..NISTREAM] {parameter STRM_$istream.N$_W = 32,}    
    $replicate N=[1..NOSTREAM] {parameter STRM_$ostream.N$_W = 32,}
    $replicate N=[1..NISCLR]   {parameter SCLR_$isclr.N$_W   = 32,}
    $replicate N=[1..NLSTREAM] {parameter LSTRM$lstream.N$_W = 32,} 
    $replicate N=[1..NFU]      {parameter FU$fu.N$_W         = 32,} 
    $delete_last_comma
)

(

// =============================================================================
// ** Ports 
// =============================================================================
  // standard ComputeCore control ports
  input       clk   ,
  input       rst   ,	
  input       start , //asserted when first element is fed into the pipeline
  input       stop  , //asserted when the last element is fed into the pipe
  output      ready , //asserted whenb first element exits the pipeline 
  output      done  , //asserted when the last element exits the pipeline 
  output reg  cts   , //for compatibility with SEQ Core
  
  // streaming input ports
  $replicate NN=[1..NISTREAM] {input   [STRM_$istream.NN$_W-1:0] strm_$istream.NN$,} 

  // input scalars
  $replicate NN=[1..NISCLR]   {input   [SCLR_$isclr.NN$_W-1:0]   sclr_$isclr.NN$ ,} 

  // output streaming ports
  $replicate NN=[1..NOSTREAM] {output  [STRM_$ostream.NN$_W-1:0] strm_$ostream.NN$,}
  $delete_last_comma
);

// =============================================================================
// ** Local variables (streams), pipeline registers for streams and control
// =============================================================================
// istremXX, with XX numbered seriall from 01 onwards, refers to intermediate
// connecting wires for carrying streaming data
// for the 0th stage, there are no pipeline registers

// =============================================================================
// ** Dataflow
// =============================================================================


//replicate block for creating pipeline stages
$replicate N=[1..NSTAGES-1] {
  //----------------------- pipe stage %N ----------------------------------------

  // replicate for each parallel PE in this stage
  $replicate M=[1..N_PAR_PE_STAGE.N] {
    wire [$OUTPUT_VAR_STAGE_%N_PE_%M_W$-1:0] $OUTPUT_VAR_STAGE_%N_PE_%M$;
    $PE_MOD_STAGE_N_PE_M$ #($OUTPUT_VAR_STAGE_%N_PE_%M_W$) PE%N%M (clk, rst, , , $OUTPUT_VAR_STAGE_%N_PE_%M$, $INPUT1_VAR_STAGE_%N_PE_%M$, $INPUT2_VAR_STAGE_%N_PE_%M$);  

  }//$replicate M=[1..N_PAR_PE_STAGE.N] {

  wire start_z%N, stop_z%N;
  delayline_z1 #(1) DL%Nstart (clk, start_z%N, start_z%(N-1) ); 
  delayline_z1 #(1) DL%Nstop (clk, stop_z%N , stop_z%(N-1)  ); 
}//$replicate N=[1..NSTAGES-1]


//----------------------- pipe stage %NSTAGES (output stage) -------------------------
// delay lines (control)
wire start_z$NSTAGES$, stop_z$NSTAGES$;
delayline_z1 #(1) DL$NSTAGES$start  (clk, start_z$NSTAGES$, start_z$NSTAGES-1$); 
delayline_z1 #(1) DL$NSTAGES$stop   (clk, stop_z$NSTAGES$ , stop_z$NSTAGES-1$ ); 

// delay lines (data)
$repeat N=[1..$NOSTREAM$] // $NOSTREAM$ = $NPAROPS_STAGE.NSTAGES$ 
{
  wire [$OUTPUT_VAR_STAGE_$NSTAGES$_PE_%N$_W-1:0]  $OUTPUT_VAR_STAGE_$NSTAGES$_PE_%N$_z1;
  delayline_z1 #($OUTPUT_VAR_STAGE_$NSTAGES$_PE_%N$_W) DL$NSTAGES$data%N (clk, $OUTPUT_VAR_STAGE_$NSTAGES$_PE_%N$_z1 , $OUTPUT_VAR_STAGE_$NSTAGES$_PE_%N$);      
}//$repeat N=[1..$NOSTREAM$]



//----------------------- output wires -----------------------------------------
// assign to output wires the relevant pipeline registers from last stage

$repeat N=[1..$NOSTREAM$] // $NOSTREAM$ = $NPAROPS_STAGE.NSTAGES$ 
{
  assign $NAME_OUTPUT_STREAM_%N$ = $OUTPUT_STREAM_%N_CONN_TO$_z1;
}

assign  ready   = start_z$NSTAGES-1$;
assign  done    = stop_z$NSTAGES$;

//cts is asserted when the first element exits the pipeline
//(i.e. is when read is asserted for one tick)
//it remains asserted 
//as this is a pipeline that takes in a continuous stream
//of data, so it is always CTS
//It is used by parent to enable counting for destination counter
always @(posedge clk)
  if(ready || cts)
    cts <= 1'b1;
  else
    cts <= 1'b0;

endmodule            

