# =============================================================================
# Company      : Unversity of Glasgow, Comuting Science
# Author:        Syed Waqar Nabi
# 
# Create Date  : 2015.03.10
# Project Name : TyTra
#
# Dependencies : 
#
# Revision     : 
# Revision 0.01. File Created
# 
# Conventions  : 
# =============================================================================
#
# =============================================================================
# General Description and Notes:
#
# Verilog Code Generator Module for use with TyBEC
#
# Target is Altera Stratix devices.
# =============================================================================                        

package HdlCodeGen;
use strict;
use warnings;

#use Data::Dumper;
use File::Slurp;
use File::Copy qw(copy);
use List::Util qw(min max);
use Term::ANSIColor qw(:constants);


use Exporter qw( import );
our @EXPORT = qw( $genCoreComputePipe );

our $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};


# ============================================================================
# Utility routines
# ============================================================================

sub log2 {
        my $n = shift;
        return int( (log($n)/log(2)) + 0.99); #0.99 for CEIL operation
    }

# ============================================================================
# Code Generation Lookups
# ============================================================================

# >>> Which (pipelined) module to use for which operation (and datatype)
our %mod4op;

$mod4op{add}{ui18} = 'PipePE_ui_add';
$mod4op{sub}{ui18} = 'PipePE_ui_sub';
$mod4op{mul}{ui18} = 'PipePE_ui_mul';
$mod4op{add}{ui32} = 'PipePE_ui_add';
$mod4op{sub}{ui32} = 'PipePE_ui_sub';
$mod4op{mul}{ui32} = 'PipePE_ui_mul';

# >>> Which combinational connector to use for which operation
our %conn4op;
$conn4op{and} = '&';
$conn4op{or}  = '|';

# what is the width in bits for a particular data type
  # TODO: something of a hack... this should be more centralized some ways
our %width4dtype;

$width4dtype{ui18} = 18;


# ============================================================================
# GENERATE offset Stream ()
# ============================================================================

sub genOffsetStream {

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my $fhGen       = $_[0];  #file handler for output file
  my $modName     = $_[1];  #module_name
  my $designName  = $_[2];  #design name
  my $portName    = $_[3];  #name of port for which offsetStream is needed
  my $maxPos      = $_[4];  #maximum positive offset required
  my $maxNeg      = $_[5];  #maximum negative offset required
  my @posOffsets  = @{$_[6]};  #array of required positive offsets
  my @negOffsets  = @{$_[7]};  #array of required negative offsets

  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # --------------------------------
  # >>>> Load template file
  # --------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/offsetStream.template.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  # --------------------------------
  # >>>> Read template contents into string
  # --------------------------------
  my $genCode = read_file ($fhTemplate);

  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  #genCode =~ s/<params>/$modName/g; <-- ? Got this from diff
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;

  # --------------------------------
  # >>>>> generate output ports
  # --------------------------------

  #for positive offsets
  for (my $i=1; $i <= $maxPos; $i++) {
    $strBuf = "$strBuf"
            . "  , output [DataW-1:0] outP$i \n"
  }
  #for negative offsets
  for (my $i=1; $i <= $maxNeg; $i++) {
    $strBuf = "$strBuf"
            . "  , output [DataW-1:0] outN$i \n"
  }

  $genCode =~ s/<ports>/$strBuf/g;
  $strBuf = "";

  # --------------------------------
  # >>>>> replace maxPos and maxPos
  # --------------------------------
  $genCode =~ s/<maxPos>/$maxPos/g;
  $genCode =~ s/<maxNeg>/$maxNeg/g;

  # -------------------------------------------
  # >>>>> connect output port to register bank
  # -------------------------------------------
  #for positive offsets
  for (my $i=$maxPos; $i >= 0; $i--) {
    $strBuf = "$strBuf"
            . "assign outP$i = offsetRegBank[".($maxPos-$i)."]; "
            . "//<-- +$i \n";
  }

  #for negative offsets
  for (my $i=1; $i <= $maxNeg; $i++) {
    $strBuf = "$strBuf"
            . "assign outN$i = offsetRegBank[".($maxPos+$i)."]; "
            . "//<-- +$i \n";
  }

  $genCode =~ s/<port2regConnections>/$strBuf/g;
  $strBuf = "";
  
  # -------------------------------------------
  # >>>>> create the shifting logic in the reg-bank
  # -------------------------------------------
  $strBuf = "$strBuf"
          . "always @(posedge clk) begin \n"
          . "  offsetRegBank[0]  <= in; \n";

  #loop through the entire buffer, and shift
  for (my $i=1; $i <= ($maxPos+$maxNeg); $i++) {
    $strBuf = "$strBuf"
            . "  offsetRegBank[$i"."]  <="
            . "  offsetRegBank[".($i-1)."]; \n";
  }

  $strBuf = "$strBuf"
          . "end";

  $genCode =~ s/<shiftRegister>/$strBuf/g;
  $strBuf = "";


#always @(posedge clk) begin
#  offsetRegBank[0]  <= in;                    //<--+12 
#  offsetRegBank[1]  <= offsetRegBank[0] ;   
#  offsetRegBank[2]  <= offsetRegBank[1] ;   
#  offsetRegBank[3]  <= offsetRegBank[2] ;   
#  offsetRegBank[4]  <= offsetRegBank[3] ;   
#  offsetRegBank[5]  <= offsetRegBank[4] ;   
#  offsetRegBank[6]  <= offsetRegBank[5] ;   
#  offsetRegBank[7]  <= offsetRegBank[6] ;   
#  offsetRegBank[8]  <= offsetRegBank[7] ;   
#  offsetRegBank[9]  <= offsetRegBank[8] ;   
#  offsetRegBank[10] <= offsetRegBank[9] ;   
#  offsetRegBank[11] <= offsetRegBank[10]; //<-- +1  
#  offsetRegBank[12] <= offsetRegBank[11]; //<-- 0   
#  offsetRegBank[13] <= offsetRegBank[12]; //<-- -1  
#  offsetRegBank[14] <= offsetRegBank[13];   
#  offsetRegBank[15] <= offsetRegBank[14];   
#  offsetRegBank[16] <= offsetRegBank[15];   
#  offsetRegBank[17] <= offsetRegBank[16];   
#  offsetRegBank[18] <= offsetRegBank[17];   
#  offsetRegBank[19] <= offsetRegBank[18];   
#  offsetRegBank[20] <= offsetRegBank[19];   
#  offsetRegBank[21] <= offsetRegBank[20];   
#  offsetRegBank[22] <= offsetRegBank[21];   
#  offsetRegBank[23] <= offsetRegBank[22];   
#  offsetRegBank[24] <= offsetRegBank[23]; //<-- -12   
#end 


  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName \n";
  
  return;
}#genOffsetStream 

# ============================================================================
# GENERATE Custom COMBinational modules (for comb functions)
# ============================================================================

sub genCustomComb {

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my $fhGen       = $_[0];  #file handler for output file
  my $modName     = $_[1];  #module_name
  my $designName  = $_[2];  #design name
  my %fHash       = %{$_[3]};  #the hash for the  parsed COMB function  

  my $outPort; #name of output port extracted and stored here, for use in elimination of its wire declaration
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # --------------------------------
  # >>>> Load template file
  # --------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/CustomComb.template.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  # --------------------------------
  # >>>> Read template contents into string
  # --------------------------------
  my $genCode = read_file ($fhTemplate);

  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;

  # -------------------------------------------------------
  # >>>>> Generate parameter list and default values
  # -------------------------------------------------------
  # foreach my $key (keys %{$fHash{args}}) {   
  #   my $name = $fHash{args}{$key}{name}; #reduce clutter    
  #   
  #   # inputs
  #   if($fHash{args}{$key}{dir} eq 'input') {
  #     $strBuf = "$strBuf"
  #             . "  , parameter SIG_$name"."_W = 32\n"
  #   }#if
  #   
  #   # outputs; treated same for now, but may need differentiation      
  #   else {
  #     $strBuf = "$strBuf"
  #             . "  , parameter SIG_$name"."_W = 32\n"
  #   }#else 
  # }#foreach
  # $genCode =~ s/<params>/$strBuf/g;
  # $strBuf = "";

  # ------------------------------------
  # >>>>> create inputs and output ports
  # ------------------------------------
  foreach my $key (keys %{$fHash{args}}) {
    my $name = $fHash{args}{$key}{name}; #reduce clutter    
    my $width = $width4dtype{$fHash{args}{$key}{type}}; #pick up width for data type
    
    #create input ports
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf"."  , "
              . "input   [$width"."-1:0] sig_$name"."_pre\n";
    }#if
    #create output  port (only 1 allowed. Store its name for later eliminating its wire declaration)
    else {
      $strBuf = "$strBuf"."  , "
              . "output  [$width"."-1:0] sig_$name\n";
      $outPort = $name;
              
    }#else 
  }#foreach
  $genCode =~ s/<ports>/$strBuf/g;
  $strBuf = "";

  # ------------------------------------
  # >>>>> create inputs registers AND
  # >>>>> registering logic
  # ------------------------------------
  foreach my $key (keys %{$fHash{args}}) {
    my $name = $fHash{args}{$key}{name}; #reduce clutter    
    my $width = $width4dtype{$fHash{args}{$key}{type}}; #pick up width for data type


    #only relevant for inputs
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf\n"
        . "reg [$width"."-1:0] sig_$name".";\n"
        . "always @(posedge clk)\n"
        . "  sig_$name"." <= sig_$name"."_pre;\n";
    }#if
  }#foreach
  $genCode =~ s/<inputRegisters>/$strBuf/g;
  $strBuf = "";

  # --------------------------------
  # >>>>>> create combinational logic
  # --------------------------------    
  my $op   ;
  my $dType;
  my $oper1;
  my $oper2;
  my $operD;

  # Iterate through the hash, sorted on the basis of instruction sequence
  # See http://perlmaven.com/how-to-sort-a-hash-in-perl on how it was done
  
  foreach my $key (
      sort { $fHash{instructions}{$a}{instrSequence} <=> $fHash{instructions}{$b}{instrSequence} } 
      keys %{$fHash{instructions}}) {
    # get the type of op and the data type, and operands from hash of instruction
    $op    = $fHash{instructions}{$key}{op};
    $dType = $fHash{instructions}{$key}{destType}; #the destination type is important
    $oper1 = $fHash{instructions}{$key}{oper1}; 
    $oper2 = $fHash{instructions}{$key}{oper2}; 
    $operD = $key;
    
    ## lookup the appropriate functional unit for this combination of op and opType
    #my $fu =  $mod4op{$op}{$dType};
    
    # lookup the appropriate combinational connector for the operation
    my $conn =  $conn4op{$op};
    
    # lookup the appropriate signal width for the destination type
    my $width = $width4dtype{$dType};

    # now add the code assign statement that creates the logic for the instruction
    #  check if destination is actually an output port, in which case its WIRE declaration has
    #  to be bypassed, and ASSIGN used
    # TODO: The "DataW" parameter is a cop-out, as it should correspond to the 
    # data type of the destination...
    if ($operD eq $outPort) {
      $strBuf 
        = "$strBuf \n"
        . "assign sig_$operD"
        . " = sig_$oper1"."  $conn  "."sig_$oper2".";\n";
    }#if
    else {
      $strBuf 
        = "$strBuf \n"
        . "wire [$width"."-1:0] sig_$operD"
        . " = sig_$oper1"."  $conn  "."sig_$oper2".";\n";
    }
  }#foreach   
  
  $genCode =~ s/<combLogic>/$strBuf/g;
  $strBuf = "";

  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated combinational logic module $modName for TyTra-IR function $fHash{funcName}\n";
  
  return;
} 

# ============================================================================
# GENERATE Compute-Pipe  (leaf PIPES only)
# ============================================================================

sub genComputePipe {

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my $fhGen       = $_[0];  #file handler for output file
  my $modName     = $_[1];  #module_name
  my $designName  = $_[2];  #design name
  my %fHash       = %{$_[3]};  #the hash from parsed code for this pipe function

  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # --------------------------------
  # >>>> Load template file
  # --------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/ComputePipe.template.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  # --------------------------------
  # >>>> Read template contents into string
  # --------------------------------
  my $genCode = read_file ($fhTemplate);

  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;

  # -------------------------------------------------------
  # >>>>> Generate parameter list and default values
  # -------------------------------------------------------
  foreach my $key (keys %{$fHash{args}}) {   
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g; 
      #reduce clutter, get the name of arg minus % r @
    
    # input streams
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf"
              . "  , parameter STRM_$name"."_W            = 32\n"
    }#if
    
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf"
              . "  , parameter STRM_$name"."_W            = 32\n"
    }#else 
  }#foreach
  $genCode =~ s/<params>/$strBuf/g;
  $strBuf = "";

  # --------------------------------
  # >>>>> create inputs and output STREAMING ports
  # --------------------------------
  foreach my $key (keys %{$fHash{args}}) {
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g; 

    #create input streaming ports
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf \n"
              . "  , "
              . "input\t[STRM_$name"."_W-1:0] strm_"
              . $name;
      #check if this input stream has any associated offSets, which case
      #they need to be connected to the child as well
      if (exists $fHash{args}{$key}{offSets}) {
        foreach my $keyOffset (keys %{$fHash{args}{$key}{offSets}}) {
          $keyOffset =~ s/[\@\%]+//g;
          $strBuf = "$strBuf \n"
                  . "  , "
                  . "input\t[STRM_$name"."_W-1:0] strm_$keyOffset";  
        }#foreach
      }#if
    }#if
    #create output streaming ports
    else {
      $strBuf = "$strBuf \n"
              . "  , "
              . "output\t[STRM_$name"."_W-1:0] strm_"  
              . $name;
    }#else 
  }#foreach
  $genCode =~ s/<streamingPorts>/$strBuf/g;
  $strBuf = "";

  # --------------------------------
  # >>>>>> create pipeline stages
  # --------------------------------
  my $sCount = 0  ; # stage count. value from HASH via autoparallelize function
  
  my $fuCount = 0; 
    #count of functional unit (to give unique names)
    #only sCount will not suffice as there may be multiple FUs in a stage
    
  my $op   ;
  my $dType;
  my $oper1;
  my $oper2;
  my $operD;
  my $operDtype;


  # To identify pipeline stages, we need to iterate through the instructions
  # So iterate through the hash, but sorted on the basis of instruction sequence
  # See http://perlmaven.com/how-to-sort-a-hash-in-perl on how it was done
  
  #in order to go through the instructions hash in sequence, (and because getting bug when doing
  #the sort access as described in the above comment), I make a loop from 0 to NumInstructions-1,
  #and then pick up the instruction for THAT sequence, and then generate code for it.
  #that ensures code is generated in the right sequence in the verilog file...
  
  
  for (my $i = 0; $i < $fHash{instrCount} ; $i++) {
    
    #find the instruction key that goes with the current instrSequence
    my $key;
    foreach my $tempkey (keys %{$fHash{instructions}}) {
      if($fHash{instructions}{$tempkey}{instrSequence} == $i) {
        $key = $tempkey; }
    }#foreach    
     
    #now that $key holds the correct instruction key for the current sequence $i, 
    # we just continue as before (i.e. generate code for this key)
    #note the previous loop header commented out
        #foreach my $key (
        #  #  sort { $fHash{instructions}{$a}{instrSequence} <=> $fHash{instructions}{$b}{instrSequence} } 
        #  # TODO: check why this sorting is causing invalid access problems... 
        #    keys %{$fHash{instructions}}) {
        #
        
    #if function call instructions (can only be of type COMB - assumed, not checked) 
    #--------------------------------------------------------------------------------
    if($fHash{instructions}{$key}{instrType} eq 'funcCall') {
    
      #destination operand 
      ($operD  = $fHash{instructions}{$key}{operD}) =~ s/[\@\%]+//g; 
      
      #destination operand's type (dest  operand is always at 0th position in the arg list)
      $operDtype = $fHash{instructions}{$key}{args2child}{0}{type};
      
      #get the name of the child function (remove .N from name of  instruction)
      (my $childFuncName = $key) =~ s/\.\d+//;
           
      #get the stage count based on the autoparallelization run, where each 
      #instruction has already been assigned a stage in the pipeline
      #$sCount = $fHash{parExecInstWise}{$operD};
      $sCount = $fHash{parExecInstWise}{$key};
    
      # now start instantiating the child module for the child COMB function called 
      # unless destination is actually a port,  wire declaration IS needed. check!
      if($fHash{instructions}{$key}{writes2port} eq 'no') {
        $strBuf 
          = "$strBuf \n"
          . "wire [DataW-1:0] strm_$operD;\n"
      }
      #Instantiate the combinatorial module
      $strBuf 
        = "$strBuf \n"
        . "// --- Custom module in stage $sCount for $childFuncName ----\n"
        #. "wire [DataW-1:0] strm_$operD;\n"
        . "CustomComb_$childFuncName  CombModule_$fuCount (\n" 
        . "   .clk   (clk)\n";
        
      # now loop through the arguments passed to child function, and make connections
      foreach my $key2 (keys %{$fHash{instructions}{$key}{args2child}}) {
        (my $nameChildPort = $fHash{instructions}{$key}{args2child}{$key2}{nameChildPort}) =~ s/[\@\%]+//g; 
        (my $nameParentSig = $fHash{instructions}{$key}{args2child}{$key2}{name}) =~ s/[\@\%]+//g; 
        
        #for input ports
        if($fHash{instructions}{$key}{args2child}{$key2}{dir} eq 'input') {
          $strBuf 
            = "$strBuf"
            . "  ,.sig_$nameChildPort"."_pre   (strm_$nameParentSig".")\n";
        }
        #for output ports 
        else {
          $strBuf 
            = "$strBuf"
            . "  ,.sig_$nameChildPort"."       (strm_$nameParentSig".")\n";
        }
      }#foreach
      
      #conclude instantiation of customCOMb child module
      $strBuf 
        = "$strBuf".");\n";
      
      $fuCount++;  
    }#if function call instruction
    
    
    #all non-function-call (compute) instructions
    #----------------------------------------------------
    else {
      # get the type of op and the data type, and operands from hash of instruction
      $op    = $fHash{instructions}{$key}{op};
      $dType = $fHash{instructions}{$key}{opType};
      ($oper1 = $fHash{instructions}{$key}{oper1})=~ s/[\@\%]+//g;  
      ($oper2 = $fHash{instructions}{$key}{oper2})=~ s/[\@\%]+//g;  
      ($operD = $fHash{instructions}{$key}{operD})=~ s/[\@\%]+//g; 
      
      #get the stage count based on the autoparallelization run, where each 
      #instruction has already been assigned a stage in the pipeline
      $sCount = $fHash{parExecInstWise}{$key};
      
      # data delay lines 
      #-----------------
      #1. any of the operands refers to an input stream directly AND
      #2. this is a non-zero pipeline stage. 
      # This means that we need
      # to insert delay-lines so that argument value is coherent
      if($sCount >= 1) {
        #operand 1 is a direct port connections
        if($fHash{instructions}{$key}{oper1form} eq 'inPort') {
          my $i_start; 
            #we may not need to start the delay lines from the first stage
          
          #first off, see if a delay buffer for this port-argument has never been 
          #generated, indicated by the key for oper being  being non-existent
          # in the dataDelayLinesMaxZ hash
          # in such a case, we are starting off from 0th stage
          if(!(exists $fHash{dataDelayMaxZ}{$oper1})) {
            #create a duplicate wire with _z0 appended so that 
            #the loop is uniform
            $strBuf = "$strBuf"
                    . "//rename $oper1 \n"
                    . "wire [DataW-1:0] strm_$oper1"."_z0 = strm_$oper1;\n";
            
            #the delay line generation starts from first stage onwards
            $i_start = 1;
          }#if
          #else, the situation that a delay line has already been defined,
            #but its Z is less than what we need, so we start
            #delay line creation from the previous max value
          elsif ($fHash{dataDelayMaxZ}{$oper1} < $sCount)
            { $i_start = $fHash{dataDelayMaxZ}{$oper1}+1; }
          # if oper1maxZ is already defined and the already generated maxZ is greater than the Z
          # required for THIS instruction, then set i_start to sCount so
          # that the generation loop does not run at all
          else
            { $i_start = $sCount+1; }

          #delay line generation loop:
          #loop from i_start determined earlier
          #till you get to current stage, and create a delay line for each stage
          for (my $i=$i_start; $i <= $sCount; $i++) {
            $strBuf 
              = "$strBuf \n"
              . "// ------ DATA delay line for strm_$oper1, stage $i ------\n"
              . "wire [DataW-1:0] strm_$oper1"."_z".$i.";\n"
              . "delayline_z1 #(DataW) DL$oper1$i "
              . "(clk, strm_$oper1"."_z".$i.", strm_$oper1"."_z".($i-1)." ); \n";
              
            #add to cost!
            #HACK! -- this should happen at the estimate phase? 
            (my $toadd = $dType) =~ s/^\D+//g;
            $main::CODE{launch}{cost}{REGS} += $toadd;  
          }
          
          #update the hash to indicate the max delayed value that has been generated
          #for this particular port/argument
          #in case a delayed value is needed again, in which case we check against this
          #value to see of any further delay stages need to be added
          #$main::CODE{$fHash{funcName}}{dataDelayMaxZ}{$oper1} = $sCount;
          $fHash{dataDelayMaxZ}{$oper1} = $sCount;

          #update the value of $oper1 with the delayed version, so that correct code is generated
          $oper1 = $oper1."_z".$sCount;
          
        }#if
    
        #now do the same for port 2. i.e. if port 2 is a direct port connection
        if($fHash{instructions}{$key}{oper2form} eq 'inPort') {
          my $i_start; 
          if(!(exists $fHash{dataDelayMaxZ}{$oper2})) {
            $strBuf = "$strBuf"
                    . "//rename $oper2 \n"
                    . "wire [DataW-1:0] strm_$oper2"."_z0 = strm_$oper2;\n";
            $i_start = 1;
          }#if
          elsif ($fHash{dataDelayMaxZ}{$oper2} < $sCount)
            { $i_start = $fHash{dataDelayMaxZ}{$oper2}; }
          else
            { $i_start = $sCount+1; }

          for (my $i=$i_start; $i <= $sCount; $i++) {
            $strBuf 
              = "$strBuf \n"
              . "// ------ DATA delay line for strm_$oper2, stage $i ------\n"
              . "wire [DataW-1:0] strm_$oper2"."_z".$i.";\n"
              . "delayline_z1 #(DataW) DL$oper2$i "
              . "(clk, strm_$oper2"."_z".$i.", strm_$oper2"."_z".($i-1)." ); \n";
            #add to cost!
            #HACK! -- this should happen at the estimate phase? 
            (my $toadd = $dType) =~ s/^\D+//g;
            $main::CODE{launch}{cost}{REGS} += $toadd;     
          }
          #$main::CODE{$fHash{funcName}}{dataDelayMaxZ}{$oper2} = $sCount;
          $fHash{dataDelayMaxZ}{$oper2} = $sCount;
          $oper2 = $oper2."_z".$sCount;
        }#if
      }#if($sCount >= 1) {

      #generate the pipelined unit
      #-----------------------------
      # lookup the appropriate functional unit for this combination of op and opType
      my $fu =  $mod4op{$op}{$dType};
 
      #if this is a redux instruction, then re-define operands accordingly
      #one operand is the one that is not the accumulator - AS -IS
      #the other is the accumulator operand, with _r appended for its registers ver which is fed back
      if($fHash{instructions}{$key}{instrType} eq 'reduction') {
        ($oper1 = $fHash{instructions}{$key}{operNotAcc})=~ s/[\@\%]+//g; 
        ($oper2 = $fHash{instructions}{$key}{operD})=~ s/[\@\%]+//g; 
        $oper2 = $oper2."_r";
      }
      
      # now append the code for local wire, pipeline unit, and the delay lines
      # in the temporary buffer
      
      $strBuf = "$strBuf \n"
        . "// -------- Pipeline Stage $sCount -----------\n"
        . "// Pipelined unit for this stage\n";

      # unless destination is actually a port,  wire declaration IS needed. check!
      if($fHash{instructions}{$key}{writes2port} eq 'no') {
        $strBuf = "$strBuf \n"
          . "wire [DataW-1:0] strm_$operD;\n";
      }
      
      #if this is **redux** operation, then create accumulation register and logic
      if($fHash{instructions}{$key}{instrType} eq 'reduction') {
        $strBuf = "$strBuf \n"                                                
          . "reg  [DataW-1:0] strm_$operD"."_r;       \n"
          . "                                         \n"
          . "always @(posedge clk) begin              \n"
          . "  if (rst)                               \n"
          . "    strm_$operD"."_r  <= 0;              \n"
          . "  else                                   \n"
          . "    strm_$operD"."_r  <= strm_$operD"."; \n"
          . "end                                      \n";
      }
        
      #these lines for instantiating pipelined FU is common
      #the difference in source operands in case of redux is already handled by
      #re-assigning oper1 and oper2
      $strBuf = "$strBuf \n"
        . "$fu #(DataW) PE$fuCount "
        . "(clk, rst, , , strm_$operD, strm_$oper1, strm_$oper2);\n\n";
      
      $fuCount++;  
    }#else
    
  }#for   
  
  #since the last pipeline stages output is actually a port
  #so remove its wire declaration
  #$strBuf =~ s/wire \[DataW-1:0\] strm_$operD;//g;

  $genCode =~ s/<pipelineStages>/$strBuf/g;
  $strBuf = "";

  # -------------------------------------
  # >>>>>> create start/stop delay lines
  # -------------------------------------


  # create one delay line for (each) start and stop for each pipeline stage
  for (my $i=0; $i < $fHash{nPipeStages} ; $i++) {
    $strBuf 
      = "$strBuf \n"
      . "// ------ CONTROL delay lines for stage $i ------\n"
      . "wire start_z" . ($i+1) . ", stop_z" . ($i+1) . ";\n"
      . "delayline_z1 #(1) DL0$i (clk, start_z".($i+1).", start_z".$i." ); \n"
      . "delayline_z1 #(1) DL1$i (clk, stop_z".($i+1).", stop_z".$i."  ); \n";
    $fuCount++;
  }#for
  
  $genCode =~ s/<delayLines>/$strBuf/g;
  $strBuf = "";

  # --------------------------------
  # >>>>> Output wires
  # --------------------------------
  # the ready signal is picked from delayed start signal from penultimate stage
  $strBuf = "start_z".($fHash{nPipeStages}-1);
  $genCode =~ s/<outputReady>/$strBuf/g;
  $strBuf = "";

  # the done signal is picked from the delayed stop signal from final stage
  $strBuf = "stop_z".$fHash{nPipeStages};
  $genCode =~ s/<outputDone>/$strBuf/g;
  $strBuf = "";

  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName for TyTra-IR function $fHash{funcName}\n";
  
  return;
} 

# ============================================================================
# GENERATE Compute-Pipe  [CG parent pipe (of pipes) ]
# ============================================================================

sub genComputePipe_CG {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my $fhGen       = $_[0];  #file handler for output file
  my $modName     = $_[1];  #module_name
  my $designName  = $_[2];  #design name
  my %fHash       = %{$_[3]};  #the hash from parsed code for this CG pipe function

  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # --------------------------------
  # >>>> Load template file
  # --------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/ComputePipe_CG.template.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  # --------------------------------
  # >>>> Read template contents into string
  # --------------------------------
  my $genCode = read_file ($fhTemplate);

  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;

  # -------------------------------------------------------
  # >>>>> Generate parameter list and default values
  # -------------------------------------------------------
  foreach my $key (keys %{$fHash{args}}) {   
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g;
    
    # input streams
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf"
              . "  , parameter STRM_$name"."_W            = 32\n"
    }#if
    
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf"
              . "  , parameter STRM_$name"."_W            = 32\n"
    }#else 
  }#foreach
  $genCode =~ s/<params>/$strBuf/g;
  $strBuf = "";

  # -------------------------------------------------
  # >>>>> create inputs and output STREAMING ports
  # -------------------------------------------------
  foreach my $key (keys %{$fHash{args}}) {
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g;   

    #create input streaming ports
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf \n"
              . "  , "
              . "input\t[STRM_$name"."_W-1:0] strm_"
              . $name;
      #check if this input stream has any associated offSets, which case
      #they need to be connected to the child as well
      if (exists $fHash{args}{$key}{offSets}) {
        foreach my $keyOffset (keys %{$fHash{args}{$key}{offSets}}) {
          $strBuf = "$strBuf \n"
                  . "  , "
                  . "input\t[STRM_$name"."_W-1:0] strm_$keyOffset";  
        }#foreach
      }#if
    }#if
    #create output streaming ports
    else {
      $strBuf = "$strBuf \n"
              . "  , "
              . "output\t[STRM_$name"."_W-1:0] strm_"  
              . $name;
    }#else 
  }#foreach
  $genCode =~ s/<streamingPorts>/$strBuf/g;
  $strBuf = "";

  # ------------------------------------------------------
  # >>>>> Instiate child modules, make connection wires
  # ------------------------------------------------------
  my $strBuf4wires = ''; 
    #this separate buffer for generation of code for creating wires
    #which happens alongside code-gen for inst' modules, but
    #has to be placed separately in the verilog target
    
  # **only for cPipe_PipesA
  #loop over each (pipe function call) instruction in the CG-pipeline
  foreach my $instrKey (keys %{ $fHash{instructions} }) {
        
    #only allow calls to other functions in this CG-PIPE function
    if( ($fHash{instructions}{$instrKey}{instrType} ne 'funcCall')
      &&($fHash{instructions}{$instrKey}{funcType} ne 'pipe')      ){
      die "TyBEC: **ERROR** In a Coarse-Grained Pipe module, all instructions must only be calls to pipe functions.";}

    my $childFuncName = $fHash{instructions}{$instrKey}{funcName};
    
    #begin child instantiation
    #--------------------------
    #start the string to instantiate the CORE module
    $strBuf = "$strBuf"
      . "\n// ------ Instantiating ComputePipe_$childFuncName ------\n"
      . "ComputePipe_$childFuncName \n"
      . "#(. DataW   (DataW) \n";

    #now iterate over all args2child in the function call (which are all presumed to be streams for now)
    #and generate parameter connections for each stream argument
    foreach my $argKey  (keys %{$fHash{instructions}{$instrKey}{args2child} }) {      
      
      #pick up the name of the child port to connect to
      (my $childPortName = $fHash{instructions}{$instrKey}{args2child}{$argKey}{nameChildPort}) =~ s/[\@\%]+//g;
      
      #pick up the name of the parent wire/stream that connects to the child port
      # TODO: currently connecting all parameters to "DataW" paramter, rather than custom for each port... 
      (my $parentPortName = $fHash{instructions}{$instrKey}{args2child}{$argKey}{name}) =~ s/[\@\%]+//g;
      # input streams
      if($fHash{instructions}{$instrKey}{args2child}{$argKey}{dir} eq 'input') {
        $strBuf = "$strBuf"
          ."  , .STRM_$childPortName"."_W (DataW)\n"}   #   (STRM_$parentPortName"."_W          )\n" }#if
      # output streams; treated same for now, but may need differentiation      
      else {
        $strBuf = "$strBuf"
          ."  , .STRM_$childPortName"."_W (DataW)\n"}   #  (STRM_$parentPortName"."_W          )\n" }#else 
    }#foreach argKey
  
    #now that parameters are connected, continue module declaration
    $strBuf = "$strBuf"
        . ")\n"
        . "  ComputePipe_$childFuncName"."\n"     #TODO: will need a sequence number if Symm pipes allowed
        . "  ( .clk   (clk    )\n"                     
        . "  , .rst   (rst    )\n";
        
        
    # control cconnections between peer kernels
    #-------------------------------------------
    
    # check instrSeq, to find the preceeding and succeeding kernels
    my $instrSeq = $fHash{instructions}{$instrKey}{instrSequence};
    
    #loop over all kernels (again) and if preceeding or succeeding to current
    # , create control wires and make connections accordingly
    foreach my $instrKeyNested (keys %{ $fHash{instructions} }) {
      my $nestedChildFuncName = $fHash{instructions}{$instrKeyNested}{funcName};
      
      #check that kernel being checked is not the current one; if so, nothing to do
      if($instrKey eq $instrKeyNested) 
        {}
      
      #LEFT neighbour found; connect START and STOP
      elsif( $fHash{instructions}{$instrKeyNested}{instrSequence} == ($instrSeq-1) ) {
        #for left neighbour, connect lefts (nesteds) ready and done to rights start and stop
        
        #create wires in the wiring buffer
        $strBuf4wires = "$strBuf4wires\n"
          . "wire ready_between;\n"
          . "wire done_between;\n";
        
        #make connections in the main buffer
        $strBuf = "$strBuf"
          ."  , .start  (ready_between)\n" 
          ."  , .stop   (done_between)\n";
      }
      
      #RIGHT neighbour found; connect READY and DONE
      elsif( $fHash{instructions}{$instrKeyNested}{instrSequence} == ($instrSeq+1) ) {
        #for right neighbour, connect lefts ready and done to rights (nested) start and stop
        
        #create wires in the wiring buffer
          # Taken this out as checking only left neighbours for all kernels is good enough...
          # This becomes redundant!
          #$strBuf4wires = "$strBuf4wires\n"
            #. "wire ready_$childFuncName"."_to_start_$nestedChildFuncName".";\n"
            #. "wire done_$childFuncName"."_to_stop_$nestedChildFuncName".";\n";
        
        #make connections to READY and DONE in the main buffer
        $strBuf = "$strBuf"
          ."  , .ready  (ready_between)\n" 
          ."  , .done   (done_between)\n";
      }
      #else, this is not a neighbour
      else
        {}
    }#foreach instrKeyNested
    
    # control connections parent-child kernels
    #-------------------------------------------
    #now check if this instruction is first or last in the sequence, in which case connect control
    #signals directly to parent ports
    #if left-most, START and STOP connect to parent ports
    #if right-most, READY and DONE connect to parent ports
    if($instrSeq == 0) { #left-most kernel
        $strBuf = "$strBuf"
          ."  , .start  (start) \n"
          ."  , .stop   (stop ) \n";
    }
    #
    elsif($instrSeq == ($fHash{nPipeStages}-1) ) { #right-most kernel
        $strBuf = "$strBuf"
          ."  , .ready  (ready) \n"
          ."  , .done   (done ) \n";
    }
    
    
    #data connections between peer kernels
    #--------------------------------------
    # loop over all kernels (again) and if preceeding or succeeding to current
    # create control wires
    foreach my $instrKeyNested (keys %{ $fHash{instructions} }) {
      (my $nestedChildFuncName = $fHash{instructions}{$instrKeyNested}{funcName}) =~ s/[\@\%]+//g;
      
      # Creating Connection wires -----------------
      #check that kernel being checked is not the current one; if so, nothing to do
      if($instrKey eq $instrKeyNested) 
        {}
      #LEFT neighbour found; make data connection wires
      elsif( $fHash{instructions}{$instrKeyNested}{instrSequence} == ($instrSeq-1) ) {
      #else {
        #now iterate over all args2child in the function call 
        #and check if the any of variables connected to its argument-ports is
        #common with that of another (the nested) kernel call, in which case, make
        #data connections
        #NOTE: TODO: This means we are currentl limited to a simple config
        #where connections cannot "jump" any kernel in the pipeline
        #the workaround is to pass every signal through the kernel, which
        #is as well as that will automatically create pipeline buffers inside it
        
        foreach my $argKey  (keys %{$fHash{instructions}{$instrKey}{args2child} }) {   
          #reduce clutter; this is the name of the connecting variable to the argument of the first kernel
          (my $argConnName = $fHash{instructions}{$instrKey}{args2child}{$argKey}{name}) =~ s/[\@\%]+//g;
          
          #now loop over all arguments of the second kernel to see if there is a match for connection
          foreach my $argKeyNested (keys %{$fHash{instructions}{$instrKeyNested}{args2child} }) {      
            #if the name of connecting variables in argument list of two kernels is same
            if (  $fHash{instructions}{$instrKey}{args2child}{$argKey}{name}
               eq $fHash{instructions}{$instrKeyNested}{args2child}{$argKeyNested}{name} ) {
              #create wires in the wiring buffer
              #TODO assuming all connecting wires are DataW!
              $strBuf4wires = "$strBuf4wires\n"
                . "wire [DataW-1:0] $argConnName" . "_between;"
                
            }#if
          }#foreach my $argKeyNested
        }#foreach argKey
      }#elsif
      
      # Making the connections --------------------
      #check that kernel being checked is not the current one; if so, nothing to do
      if($instrKey eq $instrKeyNested) 
        {}
      else {
        #now iterate over all args2child in the function call 
        #and check if the any of variables connected to its argument-ports is
        #common with that of another (the nested) kernel call, in which case, make
        #data connections
        #NOTE: TODO: This means we are currentl limited to a simple config
        #where connections cannot "jump" any kernel in the pipeline
        #the workaround is to pass every signal through the kernel, which
        #is as well as that will automatically create pipeline buffers inside it
        
        foreach my $argKey  (keys %{$fHash{instructions}{$instrKey}{args2child} }) {   
          #reduce clutter; this is the name of the connecting variable to the argument of the first kernel
          (my $argConnName = $fHash{instructions}{$instrKey}{args2child}{$argKey}{name}) =~ s/[\@\%]+//g;
          #and this is the name of this argument inside the kernel definition
          (my $argNameInsideKernel = $fHash{instructions}{$instrKey}{args2child}{$argKey}{nameChildPort}) =~ s/[\@\%]+//g;
          
          #now loop over all arguments of the second kernel to see if there is a match for connection
          foreach my $argKeyNested (keys %{$fHash{instructions}{$instrKeyNested}{args2child} }) {      
            #if the name of connecting variables in argument list of two kernels is same
            if (  $fHash{instructions}{$instrKey}{args2child}{$argKey}{name}
               eq $fHash{instructions}{$instrKeyNested}{args2child}{$argKeyNested}{name} ) {
              #make the connnections
              $strBuf = "$strBuf"
                ."  , ." . "strm_" . $argNameInsideKernel 
                ."("
                . $argConnName. "_between)\n" ;
            }#if
          }#foreach my $argKeyNested
        }#foreach argKey
      }#else      
    }#foreach my $instrKeyNested (keys %{ $fHash{instructions} }) {
    
    #data connections between parent-child kernels
    #---------------------------------------------
    #loop over all arguments (ports) of this parent kernel, and compare their names with
    #all the args (ports) of child kernels. Match indicates connection... make it!
    
    # the loop over all argument of parent kernel
    foreach my $argKey  (keys %{$fHash{args}}) {   
      #now the loop over all the arguments of the child kernel
      foreach my $argKeyNested  (keys %{$fHash{instructions}{$instrKey}{args2child} }) {   
        #see if names match  
        if (    $fHash{args}{$argKey}{name} 
            eq  $fHash{instructions}{$instrKey}{args2child}{$argKeyNested}{name} ) {
          #reduce clutter
          (my $argNameParent = $fHash{args}{$argKey}{name}) =~ s/[\@\%]+//g;
          (my $argNameInsideKernel = $fHash{instructions}{$instrKey}{args2child}{$argKeyNested}{nameChildPort}) =~ s/[\@\%]+//g;
          #make parent-child port-port data connection
          $strBuf = "$strBuf"
            ."  , ." . "strm_" . $argNameInsideKernel 
            ."("
            . "strm_" . $argNameParent
            .")\n" ;
        }#if  
      }#foreach my $argKeyNested
    }#foreach my $argKey

    #close module instantiation
    $strBuf = "$strBuf".");\n" ;
  }#foreach my $instrKey 

  $genCode =~ s/<childPipes>/$strBuf/g;
  $genCode =~ s/<connectingWires>/$strBuf4wires/g;
  $strBuf = "";
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName for TyTra-IR function $fHash{funcName}\n";
  
  return;
}

# ============================================================================
# GENERATE Core --> Pipe ()
# ============================================================================
# Generate the wrapper Core around a CoreCompute of type pipe.


sub genCorePipe {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my $fhGen       = $_[0];  #file handler for output file
  my $modName     = $_[1];  #module_name
  my $designName  = $_[2];  #design name
  my $targetDir   = $_[3];  #target dir needed because this generator can spawn its own generate calls
  my %fHash       = %{$_[4]};  #the hash from parsed code for the pipe function function


  my $thisFuncName = $fHash{funcName}; #reduce clutter
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # --------------------------------
  # >>>> Load template file
  # --------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/CorePipe.template.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!";     
  
  # --------------------------------
  # >>>> Read template contents into string
  # --------------------------------
  my $genCode = read_file ($fhTemplate);

  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header 
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;

  # -------------------------------------------------------
  # >>>>> Generate parameter list and default values
  # -------------------------------------------------------
  foreach my $key (keys %{$fHash{args}}) {   
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g; 
    
    # input streams
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf\n"
        . "  ,  parameter STRM_$name"."_W            = 32\n"
        . "  ,  parameter NDims_$name"."             = 1 \n"
        . "  ,  parameter Dim1Length_$name"."        = 12\n"
        . "  ,  parameter LinearLength_$name"."      = 12\n"
        . "  ,  parameter IndexStartDim1_$name"."    = 0 \n"
        . "  ,  parameter IndexEndDim1_$name"."      = 11\n"
        . "  ,  parameter IndexStartLinear_$name"."  = 0 \n"
        . "  ,  parameter IndexEndLinear_$name"."    = 11\n"           
        . "  ,  parameter MEM_DATA_W_$name"."        = 32\n"    
        . "  ,  parameter MEM_ADDR_W_$name"."        = 10\n"  
        . "  ,  parameter MEM_STARTADDR_$name"."     = 0 \n"        
    }#if
    
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf\n"
        . "  ,  parameter STRM_$name"."_W            = 32\n"
        . "  ,  parameter NDims_$name"."             = 1 \n"
        . "  ,  parameter Dim1Length_$name"."        = 12\n"
        . "  ,  parameter LinearLength_$name"."      = 12\n"
        . "  ,  parameter IndexStartDim1_$name"."    = 0 \n"
        . "  ,  parameter IndexEndDim1_$name"."      = 11\n"
        . "  ,  parameter IndexStartLinear_$name"."  = 0 \n"
        . "  ,  parameter IndexEndLinear_$name"."    = 11\n"           
        . "  ,  parameter MEM_DATA_W_$name"."        = 32\n"    
        . "  ,  parameter MEM_ADDR_W_$name"."        = 10\n"  
        . "  ,  parameter MEM_STARTADDR_$name"."     = 0 \n"        
    }#else 
  }#foreach
  $genCode =~ s/<params>/$strBuf/g;
  $strBuf = "";
  
  # -------------------------------------------------------
  # >>>>> create memory ports for input and output streams ONLY
  # -------------------------------------------------------

  foreach my $key (keys %{$fHash{args}}) {
    #check to confirm stream is not offset stream, in which case bypass
    #as offset streams are deal differently
    if($fHash{args}{$key}{isOffsetStream} != 1) {
      (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g; 
      
      # comment line
      $strBuf = "$strBuf \n"."// ------------ LMEM ports for $name ----------";
      
      #create data_in and read_en for input streaming ports
      if($fHash{args}{$key}{dir} eq 'input') {
        $strBuf = "$strBuf \n"
                . "  , "
                . "input\t[MEM_DATA_W_$name"."-1:0]\t"  
                . "LMEM_$name"."_datain";
        $strBuf = "$strBuf \n"
                . "  , "
                . "output\t"  
                . "LMEM_$name"."_re";
      }#if
      
      #create data_out and wr_en for output streaming ports
      else {
        $strBuf = "$strBuf \n"
                . "  , "
                . "output\t[MEM_DATA_W_$name"."-1:0]\t"  
                . "LMEM_$name"."_dataout";
        $strBuf = "$strBuf \n"
                . "  , "
                . "output\t"  
                . "LMEM_$name"."_we";
      }#else 
      
      #create address for all streams
      $strBuf = "$strBuf \n"
              . "  , "
              #. "output\t[MEM_ADDR_W_$name"."-1:0]\t"  taking out -1 as it seems to cause overflow error (signed comparison?)
              . "output\t[MEM_ADDR_W_$name".":0]\t"  
              . "LMEM_$name"."_addr";
    }#if
  }#foreach
  $genCode =~ s/<lmem_ports>/$strBuf/g;
  $strBuf = "";

  
  
  # -------------------------------------------------------
  # >>>>> create wires for stream connections from/to child
  # -------------------------------------------------------
  # this is required for all streams, whether port streams or
  # internal offset streams
  foreach my $key (keys %{$fHash{args}}) {   
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g;
    
    # input streams
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf \n"
              . "wire [DataW-1:0]\t"."strm_$name".";";
    }#if
    
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf \n"
              . "wire\t[DataW-1:0]\t"."strm_$name".";";
    }#else 
  }#foreach
  $genCode =~ s/<wires_for_streams>/$strBuf/g;
  $strBuf = "";

  # -------------------------------------------------------
  # >>>>> Create index counters for each stream
  # -------------------------------------------------------
  foreach my $key (keys %{$fHash{args}}) {   
    #check to confirm stream is not offset stream, in which case bypass
    #as offset streams are deal differently
    if($fHash{args}{$key}{isOffsetStream} != 1) {
      (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g; 
  
      # comment line
      $strBuf = "$strBuf\n"."// ------------ Index counter(s) for stream $name ----------";
      
      # index counters for input streams
      if($fHash{args}{$key}{dir} eq 'input') {
        $strBuf = "$strBuf \n"
          #. "reg   [MEM_ADDR_W_$name"."-1:0]   icount_$name".";\n" #taking out -1; seems to cause error?
          . "reg   [MEM_ADDR_W_$name".":0]   icount_$name".";\n"
          . "always @(posedge clk)\n"
          . "  if (rst)\n"
          . "    icount_$name"." <= 0;\n"
          . "  else if (start)//<-- input streams start counting on start\n"
          . "    icount_$name"." <= IndexStartLinear_$name".";\n"
          . "  else\n"
          . "    icount_$name"." <= icount_$name"." + 1;\n"
      }#if
      
      # index counters for output streams
      else {
        $strBuf = "$strBuf \n"
          #. "reg   [MEM_ADDR_W_$name"."-1:0]   icount_$name".";\n" #taking out -1; seems to cause error?
          . "reg   [MEM_ADDR_W_$name".":0]   icount_$name".";\n"
          . "always @(posedge clk)\n" 
          . "  if (rst)\n"
          . "    icount_$name"." <= 0;\n"
          . "  else if (ready) //<-- output streams start counting on ready\n"
          . "    icount_$name"." <= IndexStartLinear_$name".";\n"
          . "  else if (cts)\n"
          . "    icount_$name"." <= icount_$name"." + 1;\n"
          . "  else\n" 
          . "    icount_$name"." <= icount_$name".";\n"
      }#else 
    }#if
  }#foreach
  $genCode =~ s/<index_counters>/$strBuf/g;
  $strBuf = "";


  # --------------------------------
  # >>>>> Create STOP 
  # --------------------------------
  # STOP is created on the basis of one of the input streams 
  # Iterate through all ports, and on encountering the first input 
  # use it to generate signal, and then break...
  # [TODO: SHOULD have been set as SIGNAL in the TIR, but that messes up the
  # modularity of code generation, as a PIPE function should be translatable
  # to HDL in a modular fashion, without having to refer to a stream object?]
  #
  foreach my $key (keys %{$fHash{args}}) {   
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g;
    #check if arg is input, and NOT an internal streamOffset
    if( ($fHash{args}{$key}{dir} eq 'input') && ($fHash{args}{$key}{isOffsetStream} != 1) ) {
      $strBuf = "assign stop = (icount_$name"." == IndexEndLinear_$name".");";
      last; #break when you find the first input
    }#if
  }#foreach 
  $genCode =~ s/<interal_stop_signal>/$strBuf/g;
  $strBuf = "";

  # -------------------------------------------------------
  # >>>>> create FSMs for controlling streams
  # -------------------------------------------------------
  foreach my $key (keys %{$fHash{args}}) {   
    #check to confirm stream is not offset stream, in which case bypass
    #as offset streams are deal differently
    if($fHash{args}{$key}{isOffsetStream} != 1) {
      (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g;
      
      # comment line
      $strBuf = "$strBuf\n"."// ---------------- FSM for stream $name --------------";
      
      # input streams
      if($fHash{args}{$key}{dir} eq 'input') {
        $strBuf = "$strBuf \n"
          ."// State machine for reading from memory                  \n"
          ."localparam  S_init_$name"." = 0,\n"
          ."            S_read_$name"." = 1,\n"
          ."            S_done_$name"." = 2;\n"
          ."\n"
          ."reg  [smreg_W-1:0]  cstate_$name".";\n"
          ."reg  [smreg_W-1:0]  nstate_$name".";  \n"
          ."\n"
          ."always @(*)\n"
          ."  case(cstate_$name".")\n"
          ."    S_init_$name".": if(start) nstate_$name"." = S_read_$name".";\n"
          ."              else      nstate_$name"." = cstate_$name".";\n"
          ."    S_read_$name".": if(stop)  nstate_$name"." = S_done_$name".";\n"
          ."              else      nstate_$name"." = cstate_$name".";\n"
          ."    S_done_$name".": nstate_$name"." = S_init_$name".";\n"
          ."  endcase\n"
          ."                                                          \n"
          ."always @(posedge clk)                                     \n"
          ."  if(rst)                                                 \n"
          ."    cstate_$name"." <= S_init_$name".";\n"
          ."  else                                                    \n"
          ."    cstate_$name"." <= nstate_$name".";\n"
          ."                                                          \n"
          ."// Setting signals to memory                              \n"
          ."assign LMEM_$name"."_re    = (cstate_$name"."==S_read_$name".") ? 1'b1 : 1'b0; \n"
          ."assign LMEM_$name"."_addr  = MEM_STARTADDR_$name"." + icount_$name".";\n"
          ."                                                          \n"
          ."// registering data read from memory                      \n"
          ."assign strm_$name"." = LMEM_$name"."_datain;                          \n"
      }#if
      
      # output streams; 
      else {
        $strBuf = "$strBuf \n"
          ."// State machine for writing to memory\n"
          ."localparam  Sw_init_$name"."  = 0,\n"
          ."            Sw_write_$name"." = 1,\n"
          ."            Sw_done_$name"."  = 2;\n"
          ."\n"
          ."reg  [smreg_W-1:0]  cstate_$name".";\n"
          ."reg  [smreg_W-1:0]  nstate_$name".";\n"
          ." \n"
          ."always @(*) \n"
          ."  case(cstate_$name".") \n"
          ."    Sw_init_$name"."  : if(ready) nstate_$name"." = Sw_write_$name".";\n"
          ."                else      nstate_$name"." = cstate_$name".";\n"
          ."    Sw_write_$name"." : if(done)  nstate_$name"." = Sw_done_$name".";\n"
          ."                else      nstate_$name"." = cstate_$name".";\n"
          ."    Sw_done_$name"."  : nstate_$name"." = Sw_init_$name"."; \n"
          ."  endcase\n"
          ."\n"
          ."always @(posedge clk) \n"
          ."  if(rst) \n"
          ."    cstate_$name"."  <= Sw_init_$name".";\n"
          ."  else \n"
          ."    cstate_$name"." <= nstate_$name".";\n"
          ."\n"
          ."// Setting signals to memory  \n"
          ."assign LMEM_$name"."_we      = (cstate_$name"."==Sw_write_$name".") ? 1'b1 : 1'b0; \n"
          ."assign LMEM_$name"."_addr    = MEM_STARTADDR_$name"." + icount_$name"."; \n"
          ."assign LMEM_$name"."_dataout = strm_$name"."; \n"
      }#else 
    }#if
  }#foreach
  $genCode =~ s/<stream_control_fsms>/$strBuf/g;
  $strBuf = "";

  # ------------------------------------------
  # >>>>> now deal with offset streams <<<<
  # ------------------------------------------
  
  # >>>>>>> create offset modules for all ARGS that 
  # are offsets 
  # --------------------------------------------------
  
  #loop through all the ARGS, and see if offset streams
  #need to be generated for them
  foreach my $key (keys %{$fHash{args}} ) {
    my @posOffsets;
    my @negOffsets;
    my $maxPos;
    my $maxNeg;
    
    #check if this ARG has any offsets
    if(exists $fHash{args}{$key}{offSets}) {
      #if so, loop through all offsets, and compile parameters for generation of the
      #single offset module that generates all those offsets
      foreach my $key2 (keys %{$fHash{args}{$key}{offSets}} ) {
          #positive offset 
          if($fHash{args}{$key}{offSets}{$key2}{offsetDir} eq '+') {
            push @posOffsets, $fHash{args}{$key}{offSets}{$key2}{offsetDist};
          }#if
          #negative offset 
          else{
            push @negOffsets, $fHash{args}{$key}{offSets}{$key2}{offsetDist};
          }#else
      }#foreach offset stream of port
      
      $maxPos = max(@posOffsets);
      $maxNeg = max(@negOffsets);
            
      #now generate the offset module
      (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g;
      my $hdlFileName = "$targetDir/offsetStream_$name".".v";
        open(my $hdlfh, '>', $hdlFileName)
          or die "Could not open file '$hdlFileName' $!";   
        
        # >>>> ARGS to genOffsetStream()
        #   file handler for output file
        #   module_name    
        #   design name    
        #   name of port for which offsetStream is needed    
        #   maximum positive offset required
        #   maximum negative offset required
        #   array of required positive offsets  
        #   array of required negative offsets    
        HdlCodeGen::genOffsetStream
          ($hdlfh, "offsetStream_$name", 'justAdd', $key, $maxPos, $maxNeg, \@posOffsets, \@negOffsets );
    }#if port has offset
  }#foreach port

  
  # >>>>>>> Instantiate the offset module inside the
  # Core and make connections in the Core
  # --------------------------------------------------
  #NOTE: our assumption is that corePipe is always either the top function, or
  #is inside a PAR. Either way, it connects to PORTs in the overall MAIN design
  #which is why we iterate over the ports, and see which of them have offset streams
  #and then check them against ports in this module
  
  #iterate through all ARGS to this module (the ports)
  foreach my $keyArg (keys %{$fHash{args}} ) {
    #see if any offsets created inside the module for this ARG
    if(exists $fHash{args}{$keyArg}{offSets}) {
      
      #reduce clutter; extract name of source ARG (stream)
      (my $strConn = $fHash{args}{$keyArg}{name}) =~ s/[\@\%]+//g;
  
      #iterate through all the offsets for this source argument/stream
      #and create connection wires
      foreach my $keyOffset (keys %{$fHash{args}{$keyArg}{offSets}} ) {
      $keyOffset =~ s/[\@\%]+//g;
      $strBuf = "$strBuf"
              . "wire [DataW-1:0]  strm_$keyOffset;\n";
      }#foreach
  
      #start instantiating the offset module for this ARG
      # comment line
      $strBuf = "$strBuf"."// ------------ offset Creator for stream argument $strConn ----------\n";
     
      #beginning of instantiation
      $strBuf = "$strBuf"
              . "offsetStream_$strConn\n"
              . "  #(.DataW  (STRM_$strConn"."_W) ) \n"
              . "  OffsetStream_$strConn"."_mod \n"
              . "    ( .clk    (clk)\n"
              . "    , .rst    (rst)\n"
              . "    , .in     (strm_$strConn".")\n";
      
      #iterate through all the offsets for this source argument/stream
      foreach my $keyOffset (keys %{$fHash{args}{$keyArg}{offSets}} ) {
        #get its parameters
        (my $offsetName = $keyOffset)=~ s/[\@\%]+//g;
        my $offsetDir = $fHash{args}{$keyArg}{offSets}{$keyOffset}{offsetDir};
        my $offsetDist = $fHash{args}{$keyArg}{offSets}{$keyOffset}{offsetDist};
        
        #now add the connection line in the instantiation of the offsetStream module
        #different for + vs - direction
        if($offsetDir eq '+') {
          $strBuf = "$strBuf"
                  . "    , .outP$offsetDist"
                  . " (strm_$offsetName ) \n";
        }#if
        else {
          $strBuf = "$strBuf"
                  . "    , .outN$offsetDist"
                  . " (strm_$offsetName ) \n";
        }#else
      }#foreach
       
      #end instantiation of offset module    
      $strBuf = "$strBuf"
              . ");\n";
    }#if
  }#foreach

  $genCode =~ s/<instaniateOffsetStreams>/$strBuf/g;
  $strBuf = "";  

  # -------------------------------------------------------
  # >>>>> connect parameters in child instantiation (ComputePipe)
  # -------------------------------------------------------
  foreach my $key (keys %{$fHash{args}}) {   
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g;
    
    # input streams
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf"
              . "\t, .STRM_$name"."_W \t(STRM_$name"."_W)\n";
    }#if
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf"
              . "\t, .STRM_$name"."_W \t(STRM_$name"."_W)\n";
    }#else 
  }#foreach
  $genCode =~ s/<childCore_parameter_connections>/$strBuf/g;
  $strBuf = "";


  # -------------------------------------------------------
  # >>>>> connect signals to stream ports of child instantiation (ComputePipe)
  # -------------------------------------------------------
  foreach my $key (keys %{$fHash{args}}) {   
    (my $name = $fHash{args}{$key}{name}) =~ s/[\@\%]+//g; 
    
    # input streams
    if($fHash{args}{$key}{dir} eq 'input') {
      $strBuf = "$strBuf"
              . "\t, .strm_$name"."\t(strm_$name".")\n";
      #check if this input stream has any associated offSets, which case
      #they need to be connected to the child as well
      if (exists $fHash{args}{$key}{offSets}) {
        foreach my $keyOffset (keys %{$fHash{args}{$key}{offSets}}) {
          $keyOffset =~ s/[\@\%]+//g;
          $strBuf = "$strBuf"
                  . "\t, .strm_$keyOffset\t(strm_$keyOffset".")\n";
        }#foreach
      }#if
   }#if
    
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf"
              . "\t, .strm_$name"."\t(strm_$name".")\n";
    }#else 
  }#foreach
  $genCode =~ s/<childCore_stream_port_connections>/$strBuf/g;
  $strBuf = "";

  # -------------------------------------------------------
  # >>>>> Update name of child module 
  # (which depends on the relevant function name)
  # -------------------------------------------------------
  $genCode =~ s/<funcName>/$fHash{funcName}/g;
  


  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;

  print "TyBEC: Generated module $modName for TyTra-IR function $fHash{funcName}\n";

  return;

}#()


# ============================================================================
# GENERATE ComputeUnit
# ============================================================================
# 

sub genComputeUnit {
  #die "Too many arguments for subroutine" unless @_ <= 4;
  #die "Too few arguments for subroutine" unless @_ >= 4;   

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my $fhGen       = $_[0];  #file handler for output file
  my $targetDir   = $_[1];  #target directory needed for importing LMEM files
  my $modName     = $_[2];  #module_name
  my $designName  = $_[3];  #design name
  my $numPipes    = $_[4];  #number of identical pipeline stages (C1)
  my %CODE       = %{$_[5]};  #the hash for the code
  
  my $leafPipe  = $_[6];  #name of leaf level pipeline function
  my $topPar;
  
  if($numPipes > 1) {
    $topPar = $_[7]; #name of top level par function, if applicable
  }

  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # --------------------------------
  # >>>> Load template file
  # --------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/ComputeUnit.template.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!";     
  
  # --------------------------------
  # >>>> Read template contents into string
  # --------------------------------
  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header 
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;

  # -------------------------------------------------------
  # >>>>> Generate parameter list and default values for each stream
  # -------------------------------------------------------
  # We are at the Compute Unit level, so the stream objects have a 
  # 1-1 with ports, which have a 1-1 with the arguments (streaming variables only)
  # of the top level module
  foreach my $key (keys %{$CODE{launch}{stream_objects}}) {   
    my $name = $CODE{launch}{stream_objects}{$key}{portConn}; #the relevant port    
        
    # input streams
    if($CODE{launch}{stream_objects}{$key}{dir} eq 'in') {
      $strBuf = "$strBuf\n"
        . "  ,  parameter STRM_$name"."_W            = 32\n"
        . "  ,  parameter NDims_$name"."             = 1 \n"
        . "  ,  parameter Dim1Length_$name"."        = 12\n"
        . "  ,  parameter LinearLength_$name"."      = 12\n"
        . "  ,  parameter IndexStartDim1_$name"."    = 0 \n"
        . "  ,  parameter IndexEndDim1_$name"."      = 11\n"
        . "  ,  parameter IndexStartLinear_$name"."  = 0 \n"
        . "  ,  parameter IndexEndLinear_$name"."    = 11\n"           
        . "  ,  parameter MEM_DATA_W_$name"."        = 32\n"    
        . "  ,  parameter MEM_ADDR_W_$name"."        = 10\n"  
        . "  ,  parameter MEM_STARTADDR_$name"."     = 0 \n"        
    }#if
    
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf\n"
        . "  ,  parameter STRM_$name"."_W            = 32\n"
        . "  ,  parameter NDims_$name"."             = 1 \n"
        . "  ,  parameter Dim1Length_$name"."        = 12\n"
        . "  ,  parameter LinearLength_$name"."      = 12\n"
        . "  ,  parameter IndexStartDim1_$name"."    = 0 \n"
        . "  ,  parameter IndexEndDim1_$name"."      = 11\n"
        . "  ,  parameter IndexStartLinear_$name"."  = 0 \n"
        . "  ,  parameter IndexEndLinear_$name"."    = 11\n"           
        . "  ,  parameter MEM_DATA_W_$name"."        = 32\n"    
        . "  ,  parameter MEM_ADDR_W_$name"."        = 10\n"  
        . "  ,  parameter MEM_STARTADDR_$name"."     = 0 \n"        
    }#else 
  }#foreach
  $genCode =~ s/<params>/$strBuf/g;
  $strBuf = "";

  # -------------------------------------------------------
  # >>>>> create wires for LMEM connections
  # -------------------------------------------------------
  foreach my $key (keys %{$CODE{launch}{stream_objects}}) {   
    my $name = $CODE{launch}{stream_objects}{$key}{portConn}; #the relevant port    
    
    # reading data for input streams
    if($CODE{launch}{stream_objects}{$key}{dir} eq 'in') {
      $strBuf = "$strBuf"
              . "wire [MEM_DATA_W_$name"."-1:0]\t"."LMEM_$name"."_rdata;\n";
      $strBuf = "$strBuf"
              . "wire [MEM_ADDR_W_$name"."-1:0]\t"."LMEM_$name"."_raddr;\n";
    }#if
    
    # writing data for output streams (data bus and write enable)
    else {
      $strBuf = "$strBuf"
              . "wire [MEM_DATA_W_$name"."-1:0]\t"."LMEM_$name"."_wdata;\n";              
      $strBuf = "$strBuf"
              . "wire\tLMEM_$name"."_we;\n";
      $strBuf = "$strBuf"
              . "wire [MEM_ADDR_W_$name"."-1:0]\t"."LMEM_$name"."_waddr;\n";
    }#else 
    
  }#foreach
  $genCode =~ s/<LMEM_connection_wires>/$strBuf/g;
  $strBuf = "";

  # -------------------------------------------------------
  # >>>>> Instantiate LMEMs
  # -------------------------------------------------------
  foreach my $key (keys %{$CODE{launch}{mem_objects}}) {   
    # get the name of the memory array variable from the mem_XX format name
    (my $name=$key)=~s/mem_//; 

    # number of read and write ports
    my $nrp  = $CODE{launch}{mem_objects}{$key}{readPorts};
    my $nwp  = $CODE{launch}{mem_objects}{$key}{writePorts};
    
    # IMPORT LMEM module from Library
    copy ("./hdlCoresTybec/memory_cores/LMEM_$nrp"."RP_$nwp"."WP.v", $targetDir);
        print "TyBEC: Imported module LMEM_$nrp"."RP_$nwp"."WP\n";

    
    # comment line
    $strBuf = "$strBuf \n"."// ------------ LMEM  for $name ----------\n";
    
    # LMEM instantiation line
    # create LMEM module name depending on number of read and write ports
    # will only work if the right module is available in the library
    # no branching needed here based on direction of stream
      # the _00 suffix is there # only in the case of multiple  r or w ports, 
      # because that means multiple streams, and code generator generates separate parameter for each
      # stream that connects to a memory, so we simply use the parameters of the 0the stream
      # for the overall memory bus widths. TODO: this is of course redundant as we are assuming
      # all stream widths are same as the core memory width. However, later on, should perhaps
      # allow non-uniform streams to be connected to the same memory object? 
      
    if (($nrp==1) && ($nwp==1))  {
      $strBuf = "$strBuf"
        ."LMEM_$nrp"."RP_$nwp"."WP #(              \n"
        ."  .DATA_WIDTH (MEM_DATA_W_$name),     \n"
        ."  .ADDR_WIDTH (MEM_ADDR_W_$name),     \n"
        ."  .INIT_VALUES()                         \n"
        .")\n"
        ."LMEM_$name"."  (                         \n"
        ."   .clk    (clk  )\n";
    }#if  
    else {
      $strBuf = "$strBuf"
        ."LMEM_$nrp"."RP_$nwp"."WP #(              \n"
        ."  .DATA_WIDTH (MEM_DATA_W_$name"."_01),     \n"
        ."  .ADDR_WIDTH (MEM_ADDR_W_$name"."_01),     \n"
        ."  .INIT_VALUES()                         \n"
        .")\n"
        ."LMEM_$name"."  (                         \n"
        ."   .clk    (clk  )\n";
    }#else  
    
    # counters for creating port names of LMEM module (which is design agnostic and simply
    # numbers ports from 0 upwards
    my $rpcount = 0;
    my $wpcount = 0;
    
    # now some stream dependent port connections
    # (so loop over streams connected to the memory)
    
    foreach my $key2 (keys %{$CODE{launch}{mem_objects}{$key}{streamConn}}) {   
      
      #get name of stream object (minus the strobj prefix)
      (my $name2 = $CODE{launch}{mem_objects}{$key}{streamConn}{$key2}{name}) =~ s/strobj_//; 
      
      #for input (to core, i.e., read from memory) streams
      if($CODE{launch}{mem_objects}{$key}{streamConn}{$key2}{dir} eq 'in') {
        $strBuf = "$strBuf"
          ."  ,.raddr_$rpcount"."  (LMEM_$name2"."_raddr)\n"
          ."  ,.q_$rpcount"."      (LMEM_$name2"."_rdata)\n";
        $rpcount++;
      }#if
      
      #for output (from core, i.e., write to memory) streams
      else {
        $strBuf = "$strBuf"
          ."  ,.waddr_$wpcount"."  (LMEM_$name2"."_waddr)\n"
          ."  ,.we_$wpcount"."     (LMEM_$name2"."_we)\n"
          ."  ,.data_$wpcount"."   (LMEM_$name2"."_wdata)\n";
        $wpcount++;
      }#else       
    }#foreach
    
    #put closing braces to instantiation of LMEM
    $strBuf = "$strBuf".");\n";
    
    print "TyBEC: Instantiated module LMEM_$name of type LMEM_$nrp"."RP_$nwp"."WP in $modName\n";   
  }#foreach
  $genCode =~ s/<LMEM_instantiations>/$strBuf/g;
  $strBuf = "";
  
  # -------------------------------------------------------
  # >>>>>>>>>>> Instantiate CHILD CORE(S) <<<<<<<<<<<<<<<<<
  # -------------------------------------------------------

  
  # -------------------------------------------------------
  # >>>>> connect parameters in child instantiation (CorePipe)
  # -------------------------------------------------------
  # each instruction in the topPar will be a call to a pipeline module
  # so a CORE module to be instantiated for each
  
  # however, in case of C2 when there is just one pipe, the topPar is actually
  # the main itself, as there is no thread-parallelism at the top level 
  if($numPipes == 1) {
    $topPar = 'main';
  }

  foreach my $key (keys %{$CODE{$topPar}{instructions}}) {   
  
    #remove the "." and any digits to extract pure function name (e.g. f1 from f1.0)
    (my $fname=$key)=~s/\.\d+//;
    
    #the number after . is also required later for code generation
    (my $seq=$key)=~s/\S+\.//;   

    #start the string to instantiate the CORE module
    $strBuf = "$strBuf"
      . "\n// ------ Instantiating CorePipe #$seq for $fname ------\n"
      . "CorePipe_$fname \n"
      . "#(. DataW   (DataW) \n";

    #now iterate over all args2child in the function call (which are all presumed to be streams for now)
    #and generate parameter connections for each stream argument
    foreach my $key2 (keys %{$CODE{$topPar}{instructions}{$key}{args2child}}) {
      
      #pick up the name of the child port (i.e. Core's port) to connect to
      (my $pname = $CODE{$topPar}{instructions}{$key}{args2child}{$key2}{nameChildPort}) =~ s/[\@\%]+//g;
      
      #pick up the name of the parent wire/stream that connects to the child port
      (my $sname = $CODE{$topPar}{instructions}{$key}{args2child}{$key2}{name}) =~ s/[\@\%]+//g;
      
      # input streams
      if($CODE{$topPar}{instructions}{$key}{args2child}{$key2}{dir} eq 'input') {
        $strBuf = "$strBuf"
          ."  , .STRM_$pname"."_W           (STRM_$sname"."_W          )\n"
          ."  , .NDims_$pname"."            (NDims_$sname"."           )\n"
          ."  , .Dim1Length_$pname"."       (Dim1Length_$sname"."      )\n"
          ."  , .LinearLength_$pname"."     (LinearLength_$sname"."    )\n"
          ."  , .IndexStartDim1_$pname"."   (IndexStartDim1_$sname"."  )\n"
          ."  , .IndexEndDim1_$pname"."     (IndexEndDim1_$sname"."    )\n"
          ."  , .IndexStartLinear_$pname"." (IndexStartLinear_$sname".")\n"
          ."  , .IndexEndLinear_$pname"."   (IndexEndLinear_$sname"."  )\n"           
          ."  , .MEM_DATA_W_$pname"."       (MEM_DATA_W_$sname"."      )\n"    
          ."  , .MEM_ADDR_W_$pname"."       (MEM_ADDR_W_$sname"."      )\n"  
          ."  , .MEM_STARTADDR_$pname"."    (MEM_STARTADDR_$sname"."   )\n"        
      }#if
    
      # output streams; treated same for now, but may need differentiation      
      else {
        $strBuf = "$strBuf"
            ."  , .STRM_$pname"."_W           (STRM_$sname"."_W          )\n"
            ."  , .NDims_$pname"."            (NDims_$sname"."           )\n"
            ."  , .Dim1Length_$pname"."       (Dim1Length_$sname"."      )\n"
            ."  , .LinearLength_$pname"."     (LinearLength_$sname"."    )\n"
            ."  , .IndexStartDim1_$pname"."   (IndexStartDim1_$sname"."  )\n"
            ."  , .IndexEndDim1_$pname"."     (IndexEndDim1_$sname"."    )\n"
            ."  , .IndexStartLinear_$pname"." (IndexStartLinear_$sname".")\n"
            ."  , .IndexEndLinear_$pname"."   (IndexEndLinear_$sname"."  )\n"           
            ."  , .MEM_DATA_W_$pname"."       (MEM_DATA_W_$sname"."      )\n"    
            ."  , .MEM_ADDR_W_$pname"."       (MEM_ADDR_W_$sname"."      )\n"  
            ."  , .MEM_STARTADDR_$pname"."    (MEM_STARTADDR_$sname"."   )\n"        
      }#else 
    }#foreach my $key2 (keys %{$CODE{$topPar}{instructions}{$key}{args2child}} {

  
    #now that parameters are connected, continue module declaration
    $strBuf = "$strBuf"
        . ")\n"
        . "  core$seq\n" 
        . "  ( .clk               (clk    )\n"                     
        . "  , .rst 	            (rst    )\n"
        . "  , .start             (start  )\n";
    
    #DONE is only connected for the first lane of the pipeline 
    #note that  we are assuming symmetrical pipelines
    if($seq == 0) {
      $strBuf = "$strBuf"
        . "  , .done              (done   )\n";
    }
    else {
      $strBuf = "$strBuf"
        . "  , .done              (       )\n";
    }


    # -------------------------------------------------------
    # >>>>> connect signals to memory ports of child core
    # -------------------------------------------------------  
    
    #AGAIN  iterate over all args2child in the function call (which are all presumed to be streams for now)
    #and generate parameter connections for each stream argument
    foreach my $key2 (keys %{$CODE{$topPar}{instructions}{$key}{args2child}}) {
      
      #pick up the name of the child port (i.e. Core's port) to connect to
      (my $pname = $CODE{$topPar}{instructions}{$key}{args2child}{$key2}{nameChildPort}) =~ s/[\@\%]+//g;
      
      #pick up the name of the parent wire/stream that connects to the child port
      (my $sname = $CODE{$topPar}{instructions}{$key}{args2child}{$key2}{name}) =~ s/[\@\%]+//g;
                               
      # Lmem connections for input streams
      if($CODE{$topPar}{instructions}{$key}{args2child}{$key2}{dir} eq 'input') {
        $strBuf = "$strBuf"
          ."  , .LMEM_$pname"."_datain      (LMEM_$sname"."_rdata) \n"
          ."  , .LMEM_$pname"."_addr        (LMEM_$sname"."_raddr) \n"
          ."  , .LMEM_$pname"."_re          ()                    \n";
        }#if
        
      # Lmem connections for output streams
        else {
          $strBuf = "$strBuf"
          ."  , .LMEM_$pname"."_dataout     (LMEM_$sname"."_wdata) \n"
          ."  , .LMEM_$pname"."_addr        (LMEM_$sname"."_waddr) \n"
          ."  , .LMEM_$pname"."_we          (LMEM_$sname"."_we)    \n";
        }#else       
      #}#foreach   
    }#foreach
  
    #now that ports are connected, close the module declaration
    $strBuf = "$strBuf"
      . ");\n";
      
    print "TyBEC: Instantiated module core$seq of type CorePipe_$key in $modName\n";   
  }#foreach my $key (keys %{$CODE{$topPar}{instructions}}) { 
  
  $genCode =~ s/<childCores>/$strBuf/g;
  $strBuf = "";
   
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;

  print "TyBEC: Generated module $modName for TyTra-IR design $designName with top level function $CODE{$leafPipe}{funcName}\n";
  return;  
}#genComputeUnit()


# ============================================================================
# GENERATE Compute DEVICE
# ============================================================================
# 

sub genComputeDevice {
  #die "Too many arguments for subroutine" unless @_ <= 6;
  #die "Too few arguments for subroutine" unless @_ >= 6;   

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my $fhGen       = $_[0];  #file handler for output file
  my $modName     = $_[1];  #module_name
  my $designName  = $_[2];  #design name
  my $numPipes    = $_[3];  #number of identical pipeline stages (C1)
  my %CODE       = %{$_[4]};  #the hash for the code
  
  my $leafPipe  = $_[5];  #name of leaf level pipeline function
  my $topPar;
  
  if($numPipes > 1) {
    $topPar = $_[6]; #name of top level par function, if applicable
  }
  
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # --------------------------------
  # >>>> Load template file
  # --------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/ComputeDevice.template.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!";     
  
  # --------------------------------
  # >>>> Read template contents into string
  # --------------------------------
  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header 
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;

  # -------------------------------------------------------
  # >>>>>>>>>>> Instantiate CORE <<<<<<<<<<<<<<<<<<<
  # -------------------------------------------------------

  # -------------------------------------------------------
  # >>>>> connect parameters in child instantiation (ComputeUnit)
  # -------------------------------------------------------
  # We are at the Compute Device level, so the stream objects have a 
  # 1-1 with ports, which have a 1-1 with the arguments (streaming variables only)
  # of the top level module
  foreach my $key (keys %{$CODE{launch}{stream_objects}}) {   
    my $name = $CODE{launch}{stream_objects}{$key}{portConn}; #the relevant port    
    # input streams
    if($CODE{launch}{stream_objects}{$key}{dir} eq 'in') {
      $strBuf = "$strBuf"
        ."  , .STRM_$name"."_W           (`STRM_$name"."_W          )\n"
        ."  , .NDims_$name"."            (`NDims_$name"."           )\n"
        ."  , .Dim1Length_$name"."       (`Dim1Length_$name"."      )\n"
        ."  , .LinearLength_$name"."     (`LinearLength_$name"."    )\n"
        ."  , .IndexStartDim1_$name"."   (`IndexStartDim1_$name"."  )\n"
        ."  , .IndexEndDim1_$name"."     (`IndexEndDim1_$name"."    )\n"
        ."  , .IndexStartLinear_$name"." (`IndexStartLinear_$name".")\n"
        ."  , .IndexEndLinear_$name"."   (`IndexEndLinear_$name"."  )\n"           
        ."  , .MEM_DATA_W_$name"."       (`MEM_DATA_W_$name"."      )\n"    
        ."  , .MEM_ADDR_W_$name"."       (`MEM_ADDR_W_$name"."      )\n"  
        ."  , .MEM_STARTADDR_$name"."    (`MEM_STARTADDR_$name"."   )\n"        
   }#if
    
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf"
        ."  , .STRM_$name"."_W           (`STRM_$name"."_W          )\n"
        ."  , .NDims_$name"."            (`NDims_$name"."           )\n"
        ."  , .Dim1Length_$name"."       (`Dim1Length_$name"."      )\n"
        ."  , .LinearLength_$name"."     (`LinearLength_$name"."    )\n"
        ."  , .IndexStartDim1_$name"."   (`IndexStartDim1_$name"."  )\n"
        ."  , .IndexEndDim1_$name"."     (`IndexEndDim1_$name"."    )\n"
        ."  , .IndexStartLinear_$name"." (`IndexStartLinear_$name".")\n"
        ."  , .IndexEndLinear_$name"."   (`IndexEndLinear_$name"."  )\n"           
        ."  , .MEM_DATA_W_$name"."       (`MEM_DATA_W_$name"."      )\n"    
        ."  , .MEM_ADDR_W_$name"."       (`MEM_ADDR_W_$name"."      )\n"  
        ."  , .MEM_STARTADDR_$name"."    (`MEM_STARTADDR_$name"."   )\n"        
    }#else 
  }#foreach
  $genCode =~ s/<childCore_parameter_connections>/$strBuf/g;
  $strBuf = "";
      
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;

  print "TyBEC: Generated module $modName for TyTra-IR design $designName\n";
  return; 
}#genComputeDevice()


# ============================================================================
# GENERATE Custom Configuration File
# ============================================================================
# 

sub genCustomConfig {
  die "Too many arguments for subroutine" unless @_ <= 3;
  die "Too few arguments for subroutine" unless @_ >= 3;   

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my $fhGen       = $_[0];  #file handler for output file
  my $designName  = $_[1];  #design name
  my %fHash       = %{$_[2]};  #entire CODE hash 

  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # --------------------------------
  # >>>> Load template file
  # --------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/includeCustomConfig.template.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!";     
  
  # --------------------------------
  # >>>> Read template contents into string
  # --------------------------------
  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header 
  # --------------------------------
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;


  # -------------------------------------------------------
  # >>>>> Define parameters for all the streams
  # -------------------------------------------------------
  my $dataW;
  foreach my $key (keys %{$fHash{launch}{stream_objects}}) {   
    my $pName = $fHash{launch}{stream_objects}{$key}{portConn}; #the relevant port    
    
    # extract data type and also calculate address width based on highest address
    ($dataW=$fHash{launch}{stream_objects}{$key}{dataType})=~s/\D//g; #extract the number
    my $addrW = log2($fHash{launch}{stream_objects}{$key}{endAddr});
    
    #TODO: Some parameters are hardwired for 1D vectors; parmeterize them
    
    # input streams
    if($fHash{launch}{stream_objects}{$key}{dir} eq 'in') {
      $strBuf = "$strBuf"
        ."`define STRM_$pName"."_W           $dataW \n"
        ."`define NDims_$pName"."            1 \n" #<--- TODO: HARDWIRED!
        ."`define Dim1Length_$pName"."       $fHash{launch}{stream_objects}{$key}{length} \n"
        ."`define LinearLength_$pName"."     $fHash{launch}{stream_objects}{$key}{length} \n"
        ."`define IndexStartDim1_$pName"."   $fHash{launch}{stream_objects}{$key}{startAddr} \n"
        ."`define IndexEndDim1_$pName"."     $fHash{launch}{stream_objects}{$key}{endAddr} \n"
        ."`define IndexStartLinear_$pName"." $fHash{launch}{stream_objects}{$key}{startAddr} \n"
        ."`define IndexEndLinear_$pName"."   $fHash{launch}{stream_objects}{$key}{endAddr} \n"           
        ."`define MEM_DATA_W_$pName"."       $dataW \n"    
        ."`define MEM_ADDR_W_$pName"."       $addrW \n"  
        ."`define MEM_STARTADDR_$pName"."    $fHash{launch}{stream_objects}{$key}{startAddr} \n"        
   }#if
    
    # output streams; treated same for now, but may need differentiation      
    else {
      $strBuf = "$strBuf"
        ."`define STRM_$pName"."_W           $dataW \n"
        ."`define NDims_$pName"."            1 \n"
        ."`define Dim1Length_$pName"."       $fHash{launch}{stream_objects}{$key}{length} \n"
        ."`define LinearLength_$pName"."     $fHash{launch}{stream_objects}{$key}{length} \n"
        ."`define IndexStartDim1_$pName"."   $fHash{launch}{stream_objects}{$key}{startAddr} \n"
        ."`define IndexEndDim1_$pName"."     $fHash{launch}{stream_objects}{$key}{endAddr} \n"
        ."`define IndexStartLinear_$pName"." $fHash{launch}{stream_objects}{$key}{startAddr} \n"
        ."`define IndexEndLinear_$pName"."   $fHash{launch}{stream_objects}{$key}{endAddr} \n"           
        ."`define MEM_DATA_W_$pName"."       $dataW \n"    
        ."`define MEM_ADDR_W_$pName"."       $addrW \n"  
        ."`define MEM_STARTADDR_$pName"."    $fHash{launch}{stream_objects}{$key}{startAddr} \n"        
    }#else 
  }#foreach
  $genCode =~ s/<streamParameters>/$strBuf/g;
  $strBuf = "";

  # --------------------------------
  # >>>>> Default Data Width parameter
  # --------------------------------
  # TODO: Just now it is simple taking the datawidth of last stream parsed
  # assumption is thata all streams are uniform anyway. This needs to be updated
  # possible IR should define this default dataW explicitly
  $genCode =~ s/<DataW>/$dataW/g;
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;

  print "TyBEC: Generated Custom Configuration file for TyTra-IR design $designName\n";
  
  return;
  
}#genCustomConfig()
