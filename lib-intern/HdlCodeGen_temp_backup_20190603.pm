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

our $singleLine ="// -----------------------------------------------------------------------------\n";

# ============================================================================
# Utility routines
# ============================================================================

sub log2 {
        my $n = shift;
        return int( (log($n)/log(2)) + 0.99); #0.99 for CEIL operation
    }

#This subroutine overwrites input string     
sub remove_duplicate_lines {    
      my %seen;
      my @outbuff; 
      my @lines = split /\n/, $_[0];
      foreach my $line (@lines) {
        push @outbuff, $line if !$seen{$line}++;   # print if a line is never seen before
      }
      $_[0] = join ("\n",@outbuff);
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
# GENERATE AXI FIFO BUFFER
# ============================================================================

sub genAxiFifoBuffer {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$modName           #module_name
      ,$designName
      ,$outputRTLDir
      ,$hashref
      ,$vect
      ) = @_; 
      
  my %hash        = %{$hashref};  #the hash from parsed code for this pipe function
  my $synthunit   = 'fifobuf';
  my $synthDtype  = $hash{synthDtype};
  my $datat       = $synthDtype; #complete type (e.g i32)    
  (my $dataw = $datat)     =~ s/\D*//g; #width in bits
  (my $dataBase = $datat)  =~ s/\d*//g; #base type (ui, i, or float)
  
  my $buffSizeWords = $hash{bufferSizeWords};
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 
  my $str_instFifoBuff="";
  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName;
  $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.axiFifoBuff.v";
  
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

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
  # >>>>> DATAW/STREAMW parameters
  # -------------------------------------------------------
  my $streamw;
  if($dataBase eq 'float')  {$streamw=$dataw+2;}
  else                      {$streamw=$dataw;}

  $genCode =~ s/<dataw>/$dataw/g;
  $genCode =~ s/<streamw>/$streamw/g;
    
  #---------------
  #create DATAPATH
  #---------------
  my $buffAddrSize = log2($buffSizeWords);
  #depending on number of input operands, undo (or create) input data ports, and 
  for (my $v=0; $v<$vect; $v++) {
    #"datapath" for fifo buffer instantiating a fifo buffer, and connecting IO to it
    $str_instFifoBuff = $str_instFifoBuff
                      ."ty_fifoBuffCore             \n"
                      ."#(                          \n"
                      ."    abits ($buffAddrSize)   \n"
                      ."  , dbits (STREAMW)         \n"
                      .")                           \n"
                      ." ty_AxiFifoBuffCore_i       \n"
                      ."(                           \n"
                      ."   .clock (clk)             \n"
                      ."  ,.reset (rst)             \n"
                      ."  ,.wr    (write)           \n"
                      ."  ,.rd    (read)            \n"
                      ."  ,.din   (in1_s$v)         \n"
                      ."  ,.empty (empty)           \n"
                      ."  ,.full  (full)            \n"
                      ."  ,.dout  (out1_s$v)        \n"
                      .");                          \n"        
                      ;
  }#for
  
  
  $genCode  =~ s/<datapath>/$strBuf/g;
  $genCode  =~ s/<instFifoBuff>/$str_instFifoBuff/g;
  $strBuf   = "";
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
} 

# ============================================================================
# GENERATE map node -- leaf 
# ============================================================================
#while I have kept the ability to generate vectorized leaf nodes, 
#that is not currently used as the parent/hierarchical nodes
#instantiate multiple instances of their leaf nodes if needed
#for vectorization, so lead nodes are always scalar modules
#TODO: currently I am using separate source templates for each vector size
# no need for this, I should genreate from a common template

sub genMapNode_leaf {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$modName           #module_name
      ,$designName
      ,$outputRTLDir
      ,$hashref
      ,$vect
      ) = @_; 
      
  my %hash        = %{$hashref};  #the hash from parsed code for this pipe function
  my $synthunit   = $hash{synthunit};
  my $synthDtype  = $hash{synthDtype};
  my $datat       = $synthDtype; #complete type (e.g i32)    
  (my $dataw = $datat)     =~ s/\D*//g; #width in bits
  (my $dataBase = $datat)  =~ s/\d*//g; #base type (ui, i, or float)
  
  #How many input operands? Code-gen depends on it
  my $nInOps = 2; #default
  $nInOps = 1 if ($synthunit eq 'load'); 
  $nInOps = 3 if ($synthunit eq 'select') ;
    
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 
  my $operator = "";

  #by default, first input port exists (does not exist for CONSTANT)
  my $firstOpInputPort = "  , input      [STREAMW-1:0]  in1_s0"; 

  
  #by default, second input port exists (does not exist for LOAD, or CONSTANT)
  my $secondOpInputPort = "  , input      [STREAMW-1:0]  in2_s0"; 
  
  #by default 2 input operands; SELECT requires 3rd
  my $thirdOpInputPort = ""; 
  
  #string for creating input valids, input readys, and output ready ports
  my $str_inputIvalids = "";
  my $str_inputOreadys = "";
  my $str_inputIreadys = "";
  
  #string for ANDING input ivalids and oreadys, and fanning out ireadys
  my $str_inputIvalidsAnded = "";
  my $str_inputOreadysAnded = "";
  my $str_ireadysFanout     = "";
  
  #assigning contant operands their value
  my $str_assignConstants = "";
  
  #fifo buffer instantiated in case this is a fifobuf module
  my $str_instFifoBuff = '';
  
  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName;
  #pick up the template file for the appropriate vectorization
  if($vect==1) {$templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.mapnode_leaf.v";}
  else         {$templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.mapnode_leaf_vect$vect.v";}
  
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

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
  # >>>>> DATAW/STREAMW parameters
  # -------------------------------------------------------
  my $streamw;
  if($dataBase eq 'float')  {$streamw=$dataw+2;}
  else                      {$streamw=$dataw;}

  $genCode =~ s/<dataw>/$dataw/g;
  $genCode =~ s/<streamw>/$streamw/g;
  
  #the output stream width is same as STREAMW by default
  my $oStrWidth = "[STREAMW-1:0]";
  #(its 1-bit for compare operation)
  $oStrWidth = "             " if ($synthunit eq 'compare');
  
  # ---------------------------------------------------------------
  # >>>>> input valids, and output readys (create ports, and them)
  # ---------------------------------------------------------------
  $str_inputIvalidsAnded = "assign ivalid = ";
 my $index = 1;
 
  foreach (@{$hash{consumes}}) {
    (my $src = $_) =~ s/\%//;
    $str_inputIvalids       = $str_inputIvalids."  , input ivalid_in".$index."_s0\n"; 
    $str_inputIreadys       = $str_inputIreadys."  , output iready_in".$index."_s0\n"; 
    $str_inputIvalidsAnded  = $str_inputIvalidsAnded."ivalid_in".$index."_s0 & ";
    $str_ireadysFanout      = $str_ireadysFanout."assign iready_in".$index."_s0 = iready;\n";
    $index++;
  }
  $str_inputIvalidsAnded = $str_inputIvalidsAnded." 1'b1;\n";
  
  # -------------------------------------------------------
  # >>>>> add datapath logic
  # -------------------------------------------------------
  #int
  #---------------
  #choose operator
  #if ($synthDtype eq 'i32') {
  if ($synthDtype =~ m/i\d+/) {
    #choose operator symbol (applies for MOST Primitive instructions)
    if    ($synthunit eq 'add')       {$operator = '+';}
    elsif ($synthunit eq 'sub')       {$operator = '-';}
    elsif ($synthunit eq 'mul')       {$operator = '*';}
    elsif ( ($synthunit eq 'udiv')       
          ||($synthunit eq 'sdiv'))   {$operator = '/';}
    elsif ($synthunit eq 'compare')   {$operator = '==';}
    elsif ($synthunit eq 'or')        {$operator = '|';}
    #treat these specially later
    elsif ($synthunit eq 'select')    {$operator = '';} 
    elsif ($synthunit eq 'load')      {$operator = '';}
    else                            {die "TyBEC: Unknown integer operator \"$synthunit\" used\n";}
    
    #generate datapath string
    #------------------------
    
    #if any of the input ports are constants, make sure they are not in the port list
    for (my $i=0; $i<$vect; $i++) {
      $firstOpInputPort  = "" if(                 ($hash{oper1form} eq 'constant'));
      $secondOpInputPort = "" if(($nInOps > 1) && ($hash{oper2form} eq 'constant'));
      $thirdOpInputPort  = "" if(($nInOps > 2) && ($hash{oper3form} eq 'constant'));
    }

    
    #first check if any constant inputs, and assign them to local variables
    #witgh name as they would have had if they were regular ports
    #makes later code generation uniform
    for (my $i=0; $i<$vect; $i++) {
      $str_assignConstants  = $str_assignConstants. "wire [STREAMW-1:0] in1_s$i = $hash{oper1val};"
        if ($hash{oper1form} eq 'constant');
      $str_assignConstants  = $str_assignConstants. "wire [STREAMW-1:0] in2_s$i = $hash{oper2val};"
        if (($nInOps > 1) && ($hash{oper2form} eq 'constant'));
      $str_assignConstants  = $str_assignConstants. "wire [STREAMW-1:0] in3_s$i = $hash{oper3val};"
        if (($nInOps > 2) && ($hash{oper3form} eq 'constant'));
    }
    
    #---------------
    #create DATAPATH
    #---------------
    #depending on number of input operands, undo (or create) input data ports, and 
    for (my $i=0; $i<$vect; $i++) {
      
      #"select" inst has 3 operands
      if ($nInOps == 3){
        $strBuf   = $strBuf."\nassign out1_pre_s$i = in1_s$i ? in2_s$i : in3_s$i;";
        #add input port for 3rd (select) source operand, as template has only two by default
        #also first input port is now a single bit
        $firstOpInputPort = "  , input                     in1_s0";
        $thirdOpInputPort = "  , input      [STREAMW-1:0]  in3_s0";
      }
      
      #"load" inst, 1 operand
      elsif ($nInOps==1){
        $secondOpInputPort = "";
        $strBuf   = $strBuf."\nassign out1_pre_s$i = in1_s$i;";
      }
      
      #default units have 2 input operands
      else{
        $strBuf   = $strBuf."\nassign out1_pre_s$i = in1_s$i ".$operator." in2_s$i;";
      }
    }#for
  }#if
  
  #float
  #---------------
  if ($synthDtype eq 'float32') {
    
    #dependign on operation, move flopoco IP to generated code folder
    #and set module name and instance to use for code generation
    #todo: pre-generated cores are used here. ideally I should
    #generate flopoco at tybec's runtime
    my $flopocoIPFile   ;
    my $flopocoModule   ;
    my $flopopModuleInst;
    my $err             ;
    my $flopocoCoresRoot="$TyBECROOTDIR/hdlCoresTparty/flopoco/cores";
    
    if    ($synthunit eq 'add'){  
      #$flopocoIPFile    = "$flopocoCoresRoot/FPAddSingleDepth7.vhd";
      $flopocoIPFile    = "$flopocoCoresRoot/FPAddSingleDepth7_stallable.vhd";
      $flopocoModule    = "FPAdd_8_23_F300_uid2";
      $flopopModuleInst = "fpAdd";
      $err =copy("$flopocoIPFile", "$outputRTLDir");
    }
    elsif ($synthunit eq 'sub') {
      $flopocoIPFile    = "$flopocoCoresRoot/FPSubSingleDepth7.vhd";
      $flopocoModule    = "FPSub_8_23_F300_uid2";
      $flopopModuleInst = "fpSub";
      $err =copy("$flopocoIPFile", "$outputRTLDir");
    }
    elsif ($synthunit eq 'mul') {
      #$flopocoIPFile    = "$flopocoCoresRoot/FPMultSingleDepth2.vhd";
      $flopocoIPFile    = "$flopocoCoresRoot/FPMultSingleDepth2_stallable.vhd";
      $flopocoModule    = "FPMult_8_23_8_23_8_23_F400_uid2";
      $flopopModuleInst = "fpMul";
      $err =copy("$flopocoIPFile", "$outputRTLDir");
    }
    elsif ($synthunit eq 'div') {
      $flopocoIPFile    = "$flopocoCoresRoot/FPDivSingleDepth12.vhd";
      $flopocoModule    = "FPDiv_8_23_F300_uid2";
      $flopopModuleInst = "fpDiv";
      $err =copy("$flopocoIPFile", "$outputRTLDir");
    
    }
    else                        {die "TyBEC: Unknown float operator used\n";}    
    
    #instantiate flopoco IP in the node module
    $strBuf = $strBuf ."$flopocoModule  $flopopModuleInst\n"
                      ."  ( .clk (clk)     \n"
                      ."  , .rst (rst)     \n"
                      ."  , .stall (stall)     \n"
                      ."  , .X   (in1)     \n"
                      ."  , .Y   (in2)     \n"
                      ."  , .R   (out1_pre)\n"
                      .");"
                      ;
  }

  
  
  $genCode  =~ s/<datapath>/$strBuf/g;
  $genCode  =~ s/<oStrWidth>/$oStrWidth/g;
  $genCode  =~ s/<firstOpInputPort>/$firstOpInputPort/g;
  $genCode  =~ s/<secondOpInputPort>/$secondOpInputPort/g;
  $genCode  =~ s/<thirdOpInputPort>/$thirdOpInputPort/g;
  $genCode  =~ s/<inputIvalids>/$str_inputIvalids/g;
  $genCode  =~ s/<inputReadys>/$str_inputIreadys/g;
  $genCode  =~ s/<inputIvalidsAnded>/$str_inputIvalidsAnded/g;
  $genCode  =~ s/<ireadysFanout>/$str_ireadysFanout/g;
  $genCode  =~ s/<assignConstants>/$str_assignConstants/g;
  $genCode  =~ s/<instFifoBuff>/$str_instFifoBuff/g;
  $strBuf   = "";
  $strBuf = "";
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
} 

# ============================================================================
# GENERATE map node -- hiearchical (functions)
# ==============================================5==============================

sub genMapNode_hier {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$modName           #module_name
      ,$designName
      ,$outputRTLDir
      ,$dfgroup
      ,$hashref
      ,$vect      
      ) = @_; 
      
  my %hash        = %{$hashref};  #the hash from parsed code for this pipe function
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 
  my $strBuf2 = ""; # temp string buffer used in code generation 

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.mapnode_hier.v"; 
  #$templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.main.v" if ($dfgroup eq 'main');
  
  $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.main.v" if ($dfgroup eq 'main');
  
  #$templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.mapnode_hier.v" if ($dfgroup eq 'main');
      ## TODO/NOTE:: Doing this temporarilty as I had not committed the map template
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header, module name and parameter
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;
  
  #$strBuf = $dataw;
  #$genCode =~ s/<dataw>/$strBuf/g;
  #$strBuf = "";
  
  # -------------------------------------------------------
  # set latency
  # -------------------------------------------------------
  #now redundant as I dont have fixed latency kernels
  #my $lat = $main::CODE{main}{performance}{lat};
  #$genCode =~ s/<latency>/$lat/;  
  
  # -------------------------------------------------------
  # >>>>> dataw
  # -------------------------------------------------------
  my $datat; #complete type (e.g i32)
  my $dataw; #width in bits
  my $dataBase; #base type (ui, i, or float)
  
  if ($dfgroup eq 'main') {
    #TODO: I am using the data type of the first stream I see in main (connectd to global memory object) to set data type in main
    #but this is artificially limiting  
    #$strBuf = $dataw;
    foreach (keys %{$main::CODE{main}{symbols}} ) {
      if ($main::CODE{main}{symbols}{$_}{cat} eq 'streamread') {
        $datat = $main::CODE{main}{symbols}{$_}{dtype};
      }
    }
  } 
  else {
    $datat = $hash{synthDtype};
  }
  
  #extract base type and width
  ($dataw = $datat)     =~ s/\D*//g;
  ($dataBase = $datat)  =~ s/\d*//g;
  
  #set stream width, +2 for floating types (for comp with flopoco)
  my $streamw;
  if($dataBase eq 'float')  {$streamw=$dataw+2;}
  else                      {$streamw=$dataw;}
  
  $genCode =~ s/<dataw>/$dataw/g;
  $genCode =~ s/<streamw>/$streamw/g;
  
  # -------------------------------------------------------
  # >>>>> 
  # -------------------------------------------------------
  #string buffers for creating code for different parts of the template
  my $strPorts      = "";
  my $strInsts      = "\n// Instantiations\n";
  my $strConns      = "\n// Data and control connection wires\n";
  my $str_ovalids   = "";
  my $str_ireadysAnd= "";
  my $str_ivalids   = "";
  my $str_oreadys   = "";
  my $str_ivalidsAnd= "assign ivalid = 1'b1\n";
  my $str_oreadysAnd= "assign oready = 1'b1\n";
  
 
  #Loop through all connected groups till you get to  group against this function
  my @nodes_conn = $main::dfGraph->weakly_connected_components();
  foreach (@nodes_conn) { 
    my @conn_group_items = @{$_};
    my ($dfg, undef) = split('\.',$conn_group_items[0],2);    
    
    
    #we are at the connected group for this function \
    ##TODO: If it is truly distributed, I shouldnt need to call to do this... I will have a single call that creates RTL for ALL modules
    if($dfg eq $dfgroup) { 
      #---------------------------------------------------------------------
      # INSTANTIATIONS
      #---------------------------------------------------------------------
      #now loop over all vertices (nodes) in this connected group, and instantiate them
      foreach my $item (@conn_group_items) {
        my $parentFunc= $main::dfGraph -> get_vertex_attribute ($item, 'parentFunc');
        my $symbol    = $main::dfGraph -> get_vertex_attribute ($item, 'symbol'    );
        (my $ident =  $symbol) =~ s/(%|@)//; #remove %/@
        my $cat       = $main::CODE{$parentFunc}{symbols}{$symbol}{cat};
        

        #---------------------------------
        #ports
        #---------------------------------
        if(($cat eq 'arg') || ($cat eq 'func-arg')) {
          my $dir =  $main::CODE{$parentFunc}{symbols}{$symbol}{dir};
          
          #I should have a single code generation block, no matter what the vectorization
          #if($vect==1) {
          #  $strPorts  = $strPorts."\n"
          #            . "  , $dir"." [STREAMW-1:0] $ident"
          #            ;
          #}
          #else {
          
          #create data ports, input and output
          for (my $i=0; $i<$vect; $i++) {
            $strPorts .= "\n"
                      ."  , $dir"." [STREAMW-1:0] conn_$ident"."_s$i\n"
                      ;
          }#for
          
          #create input valids from all inputs, and AND them together:
          if($dir eq 'input') {
            $str_ivalids     = $str_ivalids."  , input ivalid_conn_".$ident."_s0\n"; 
            $str_ivalidsAnd  = $str_ivalidsAnd."  & ivalid_conn_".$ident."_s0\n";
          }
          
          #create output readys from all outputs, and AND them together:
          if($dir eq 'output') {
            $str_oreadys     = $str_oreadys."  , input oready_conn_".$ident."_s0\n"; 
            $str_oreadysAnd  = $str_oreadysAnd."  & oready_conn_".$ident."_s0\n";
          }
          #}#else
        }#if
        
        #incase of main, it can be alloca port as well
        #TODO: direction should be picked up from the edge, not the alloca node, since there can be multiple streams (both in an out)
        #from the same alloca object
        if($cat eq 'alloca') {
          #loop over all stream connections from this alloca object
          foreach my $key (keys %{$main::CODE{$parentFunc}{symbols}{$symbol}{streamConn}}) {
            my $dir  =  $main::CODE{$parentFunc}{symbols}{$symbol}{streamConn}{$key}{dir};
            my $name =  $main::CODE{$parentFunc}{symbols}{$symbol}{streamConn}{$key}{name};
            $name =~ s/(@|%)//;
            
            #if main, then my vectorized data wires are packed into a single bus
            if($dfgroup eq 'main') {
              $strPorts  = $strPorts."\n"
                        . "  , $dir"." [STREAMW-1:0] conn_$name\n"
                        ;
            }
            #if not, the vector elements are separately available
            else {
              for (my $i=0; $i<$vect; $i++) {
              $strPorts  = $strPorts."\n"
                        . "  , $dir"." [STREAMW-1:0] conn_$name"."_s$i\n"
                        ;
              }#for
            }
           #push the port onto  hash for later use (in OCL code generation, required for main only)
           $main::CODE{$parentFunc}{allocaports}{$name}{dir} = $dir;
          }
        }
        
        #-----------------------------
        #instantion of child modules
        #-----------------------------
        if( ($cat eq 'impscal') 
          ||($cat eq 'func-arg') 
          ||($cat eq 'funcall')
          ||($cat eq 'fifobuffer')
          ){
          #remove .N from identity of funcall instructions
          $ident =~ s/\.\d+// if($cat eq 'funcall');

          #name of module to instantiate
          my $module2Inst = $parentFunc."_".$ident;
          
          for (my $v=0; $v<$vect; $v++) {
            my $modInstanceName = $module2Inst."_i_s$v";
              
            #if I need to extract scalar from packed vector, what are the hi/lo bits
            my $lo = $v*$dataw;
            my $hi = ($v+1)*$dataw-1;
          #-----------------------------------------
            #common control signals
            $strInsts = $strInsts."\n"
                      . "$module2Inst \n"
#                      . "#()\n"
                      . "$modInstanceName (\n"
                      . "  .clk    (clk)\n" 
                      . ", .rst    (rst)\n" 	
                      ;
                      
            #connections -- func-args
            #-----------------------
            #if $item is a func-arg (a compute node that is also an argument), it needs 
            #outport data and connections that are  not exposed by the edges
            #(because it has no "consumer")
            if ($cat eq 'func-arg') {
              my $dir =  $main::CODE{$parentFunc}{symbols}{$symbol}{dir};
              $strInsts .= ", .out1_s0  (conn_$ident"."_s$v)\n"; 
              
              if($dir eq 'output') {
                $strInsts.= ", .ovalid (ovalid_s$v)\n"
                          . ", .oready (oready)\n"
                          ;    
                #each generated module for a vector element has its own ovalid
                $strConns .= "\n"
                          . "wire ovalid_s$v;\n"
                          ;
                $str_ovalids .= "        ovalid_s$v &\n";
              }
            }
            
            #connections -- outputs
            #-----------------------
            my @succs = $main::dfGraph->successors($item);
            foreach my $consumer (@succs) {
              #print RED; print "item = $item; consumer = $consumer\n"; print RESET;
              #Loop over multi-edges, if applicable
              my @multiedges = $main::dfGraph->get_multiedge_ids($item, $consumer);
              foreach my $id (@multiedges) {
                #get edge properties
                my $connection  = $main::dfGraph ->get_edge_attribute_by_id ( $item, $consumer, $id, 'connection' );
                my $pnode_pos   = $main::dfGraph ->get_edge_attribute_by_id ( $item, $consumer, $id, 'pnode_pos'  );
                my $cnode_pos   = $main::dfGraph ->get_edge_attribute_by_id ( $item, $consumer, $id, 'cnode_pos'  );
                my $pnode_local = $main::dfGraph ->get_edge_attribute_by_id ( $item, $consumer, $id, 'pnode_local');
                my $cnode_local = $main::dfGraph ->get_edge_attribute_by_id ( $item, $consumer, $id, 'cnode_local');
                my $pnode_cat   = $main::dfGraph ->get_edge_attribute_by_id ( $item, $consumer, $id, 'pnode_cat'  );
                my $cnode_cat   = $main::dfGraph ->get_edge_attribute_by_id ( $item, $consumer, $id, 'cnode_cat'  );
                $connection =~ s/(%|@)//; 
                
                #condition variable indicating consumer is a port (not an imp-scalar or a func-call)
                my $consumerisPort = ( ($cnode_cat eq 'arg') 
                                    || ($cnode_cat eq 'func-arg') 
                                    || ($cnode_cat eq 'alloca') 
                                    || ($cnode_cat eq 'streamread') 
                                    || ($cnode_cat eq 'streamwrite')
                                    ); #redundant?
                                    
                #condition variable indicating consumer is a module (will require explicitly declated connection wires)
                my $consumerisModule  =  ($cnode_cat eq 'impscal') 
                                      || ($cnode_cat eq 'func-arg') 
                                      || ($cnode_cat eq 'funcall') 
                                      || ($cnode_cat eq 'fifobuffer') 
                                      ;

                #depending on location in the vector, we will either append _sX
                #or choose the correct data slice (main only)
                if ($dfgroup eq 'main') {$connection = $connection."[$hi:$lo]";}
                else                    {$connection = $connection."_s$v";}

                #data port connection 
                #child ports data port is always s0
                $strInsts   .= ", .$pnode_local"."_s0"."  (conn_$connection)\n";
                
                #each generated module for a vector element has its own ovalid
                $strConns   = $strConns."\n"
                            . "wire ovalid_s$v;\n"
                            ;
                $str_ovalids = $str_ovalids. "        ovalid_s$v &\n";

                #the consumer-side axi signal connections (and requirement of explicit connection wires)
                #depend on whether consumer is a another module instance, or direct connection to parent port
                if ($consumerisModule) {
                  #connection wires
                  $strConns .= "\nwire [STREAMW-1:0] conn_$connection;";
                  $strConns .= "\nwire valid_conn_$connection;";
                  $strConns .= "\nwire ready_conn_$connection;";
                  #control port connetions
                  $strInsts .= ", .ovalid (valid_conn_$connection)\n"
                            .  ", .oready (ready_conn_$connection)\n"
                            ;
                }
                #consumer is Port
                else {
                  $strInsts   .=", .oready_conn_$pnode_local\_s0 (oready)\n"   #20190205
                              . ", .ovalid (ovalid_s$v)\n"
                              ;
                }
              }#foreach my $id (@multiedges) {
            }#foreach consumer
            
            
            #connections -- inputs
            #-----------------------
            my @preds = $main::dfGraph->predecessors($item);
            foreach my $producer (@preds) {
            
              #Loop over multi-edges, if applicable
              my @multiedges = $main::dfGraph->get_multiedge_ids($producer, $item);
              foreach my $id (@multiedges) {
                #get edge properties
                my $connection  = $main::dfGraph ->get_edge_attribute_by_id ($producer, $item, $id, 'connection' );
                my $pnode_pos   = $main::dfGraph ->get_edge_attribute_by_id ($producer, $item, $id, 'pnode_pos'  );
                my $cnode_pos   = $main::dfGraph ->get_edge_attribute_by_id ($producer, $item, $id, 'cnode_pos'  );
                my $pnode_local = $main::dfGraph ->get_edge_attribute_by_id ($producer, $item, $id, 'pnode_local');
                my $cnode_local = $main::dfGraph ->get_edge_attribute_by_id ($producer, $item, $id, 'cnode_local');
                my $pnode_cat   = $main::dfGraph ->get_edge_attribute_by_id ($producer, $item, $id, 'pnode_cat'  );
                my $cnode_cat   = $main::dfGraph ->get_edge_attribute_by_id ($producer, $item, $id, 'cnode_cat'  );
                
                #print YELLOW;
                #print "item = $item, producer = $producer, pnode_cat = $pnode_cat, cnode_cat = $cnode_cat\n";
                #print RESET;
                
                #condition variable indicating producer a port (not another peer function)
                my $producerisPort = ( ($pnode_cat eq 'arg') 
                                    || ($pnode_cat eq 'alloca') 
                                    || ($pnode_cat eq 'streamread') 
                                    || ($pnode_cat eq 'streamwrite')
                                    );

                my $producerisModule =  ($pnode_cat eq 'impscal') 
                                     || ($pnode_cat eq 'func-arg') 
                                     || ($pnode_cat eq 'funcall')                                    
                                     || ($pnode_cat eq 'fifobuffer')                                    
                                     ;

                $connection =~ s/(%|@)//; 
                #depending on location in the vector, we will either append _sX
                #or choose the correct data slice (main only)
                if ($dfgroup eq 'main') {$connection = $connection."[$hi:$lo]";}
                else                    {$connection = $connection."_s$v";}

                #port for the $item
                #child ports data port is always s0                
                $strInsts   .= ", .$cnode_local"."_s0"."  (conn_$connection)\n";
                 
                #each generated module for a vector element has its own iready
                $strConns   .= "\nwire iready_conn_$ident"."_s$v;\n";
                
                #$str_ireadysAnd = $str_ireadysAnd."        iready_$ident"."_s$v &\n";
                #if producer is port (so this is first stage node), then use it to create the global IREADY
                $str_ireadysAnd .= "        iready_conn_$ident"."_s$v &\n" if ($producerisPort);

                #the producer-side axi signal connections (and requirement of explicit connection wires)
                #depend on whether producer is a another module instance, or direct connection to parent port
                if ($producerisModule) {
                  #connection wires
                  $strConns .= "\nwire [STREAMW-1:0] conn_$connection;";
                  $strConns .= "\nwire valid_conn_$connection;";
                  $strConns .= "\nwire ready_conn_$connection;";
                  
                  #port connetions
                  #we  have IVALID and IREADY for EACH input port
                  $strInsts .= ", .ivalid_$cnode_local"."_s$v (valid_conn_$connection)\n"
                            .  ", .iready (ready_conn_$connection)\n"
                            ;
                }
                #producer is port; 
                #ivalid connects directly to parent ivalid
                #iready connects to local wire (which is ANDED to produce a global IREADY)
                else {
                  $strInsts   .=", .ivalid_$cnode_local"."_s$v (ivalid)\n"
                              . ", .iready (iready_conn_$ident"."_s$v)\n"
                              ;    
                }
              }
            }#foreach -- input connections
  
            #complete 
            $strInsts = $strInsts."\n"
                      . ");\n"
                      ;
            
            #this has to happen here as instantiations of different modules may legitimately have identical lines
            $strInsts = $strInsts."\n"
                      . "<instantiations>";
            remove_duplicate_lines($strInsts); 
            $genCode  =~ s/<instantiations>/$strInsts/g;
            $strInsts = "";
          }#for (my $v=0; $v<$vect; $v++) {
        }#if(($cat eq 'impscal') || ($cat eq 'func-arg') || ($cat eq 'funcall')) {
      }#foreach vertex  
      
      #close IVALIDS and OREADY anding string
      $str_ivalidsAnd = $str_ivalidsAnd."  ;\n";
      $str_oreadysAnd = $str_oreadysAnd."  ;\n";

   
      #remove any duplicate wire/port declarations (created due to fanout)
      #See: http://www.regular-expressions.info/duplicatelines.html
      #$strPorts=~ s/^(.*)(\r?\n\1)+$/$1/mg;
      #$strInsts=~ s/^(.*)(\r?\n\1)+$/$1/mg;
      #$strConns=~ s/^(.*)(\r?\n\1)+$/$1/mg;
      
      remove_duplicate_lines($strPorts);
      remove_duplicate_lines($strConns);
      remove_duplicate_lines($str_ovalids);
      remove_duplicate_lines($str_ireadysAnd);
      remove_duplicate_lines($str_ivalidsAnd);
      remove_duplicate_lines($str_oreadysAnd);
      
      $genCode  =~ s/<ports>/$strPorts/g;
      $genCode  =~ s/<connections>/$strConns/g;
      $genCode  =~ s/<ovalids>/$str_ovalids/g;
      $genCode  =~ s/<ireadysAnd>/$str_ireadysAnd/g;
      $genCode  =~ s/<ivalids>/$str_ivalids/g;
      $genCode  =~ s/<ivalidsAnd>/$str_ivalidsAnd/g;
      $genCode  =~ s/<oreadys>/$str_oreadys/g;
      $genCode  =~ s/<oreadysAnd>/$str_oreadysAnd/g;
      $genCode  =~ s/<instantiations>//g;
      $strPorts = "";
      $strInsts = "";
      $strConns = "";
    }
  }
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
} 

# ============================================================================
# GENERATE TEST BENCH
# ============================================================================

sub genTestbench {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$modName           #module_name
      ,$designName
      ,$outputRTLDir
      ,$ioVect
      ) = @_; 
      
  my $dfgroup = 'main'; 
  my %hash        = %{$main::CODE{main}};  #the hash from parsed code for this pipe function
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.testbench.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;
  $genCode =~ s/<globalVect>/$ioVect/g;
  
  # -------------------------------------------------------
  # >>>>> dataw, datat, streamw
  # -------------------------------------------------------
  my $datat; #complete type (e.g i32)
  my $dataw; #width in bits
  my $dataBase; #base type (ui, i, or float)
  #TODO: I am using the data type of the first stream I see in main (connectd to global memory object) to set data type in the top as well
  #but this is artificially limiting  $strBuf = $dataw;
  foreach (keys %{$main::CODE{main}{symbols}} ) {
    if ($main::CODE{main}{symbols}{$_}{cat} eq 'streamread') {
      $datat = $main::CODE{main}{symbols}{$_}{dtype};
      ($dataw = $datat)     =~ s/\D*//g;
      ($dataBase = $datat)  =~ s/\d*//g;
      #$dataw = $main::CODE{main}{symbols}{$_}{dtype};
      #$dataw =~ s/\D*//;
    }
  }
  $genCode =~ s/<dataw>/$dataw/g;
  

  
  #stream-width
  #same as dataw for ints, but for floats, we  need to add
  #2 extra control bits as they are needed by flopoco
  my $streamw;
  if($dataBase eq 'float')  {$streamw=$dataw+2;}
  else                      {$streamw=$dataw;}
  

    
  
  # -------------------------------------------------------
  # set latency
  # -------------------------------------------------------
  my $lat = $main::CODE{main}{performance}{lat};
  $genCode =~ s/<latency>/$lat/;

  # -------------------------------------------------------
  # size
  # -------------------------------------------------------
  my $size = $main::CODE{main}{bufsize};
  $genCode =~ s/<size>/$size/g;

  # -------------------------------------------------------
  #buffers for creating code for different parts of the template
  # -------------------------------------------------------
  my $strPortWires  = "";
  my $strChildPorts = "";
  my $strDecGmemAr  = "";
  my $strInitArrays = "";
  my $strZeroPadAr  = "";
  my $strAssignInput= "";
  my $strAssignOuput= "";
  my $strFpHelper   ="";
  my $excFieldFlopoco='';
  my $bits2realOpen = '';
  my $bits2realClose= '';
  my $readCResults  = '';
  my $defFloat       = '';
  my $resultCType    = '';
  my $PT             = 'd';#default
  my $getScalarResGold   = '';
  my $getScalarResCalc   = '';
  my $getScalarResCalcEnd= '';
  my $result_t           = '';
  my $getScalarResGold2Compare= '';
  my $getScalarResCalc2Compare= '';
  my $strpackDataIn  = '';
  my $strpackDataOut = '';
  # -------------------------------------------------------
  # if float, include helper and also define macro, and type of resultC
  # also set how to print outputs using printfs (%d/%f)
  # -------------------------------------------------------
  if($dataBase eq 'float') {
    my $srcdir = "$TyBECROOTDIR/hdlGenTemplates";
    my $err;
    $err =copy("$srcdir/template.spFloatHelpers.v" , "$outputRTLDir/../rtl/spFloatHelpers.v"); 
    $strFpHelper = "//helper functions for SP-floats\n"
                 . "`include \"../rtl/spFloatHelpers.v\" "
                 ;
    $defFloat = '`define FLOAT';
    $PT       = 'f';
  }
  # -------------------------------------------------------
  # read ground truth from C simulation, set output print type
  # -------------------------------------------------------
  $readCResults = "\$readmemh(\"../../../../../../../c/verifyChex.dat\", resultfromC);\n";
  if ($dataBase eq 'float') {
  $readCResults = "$readCResults\n"
                . ""
                ;
                
  }

  # -------------------------------------------------------
  # how many total inputs? (need to create packed input bus)
  # -------------------------------------------------------
  my $ninputs = 0;
  foreach my $key (keys %{$main::CODE{main}{allocaports}}) {
    my $dir =$main::CODE{main}{allocaports}{$key}{dir};
    $ninputs = $ninputs+1 if($dir eq 'input');
  }

  # -------------------------------------------------------
  # generate ports and connection in instantiation of main
  # -------------------------------------------------------
  
  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
    #name of streamign port
    my $name=$key;
    my $nameInHash="%".$name;
    my $nameWire = $name."_data";
    
    #name of relevant memory object (global memory array)
    my $nameOfMem;   
    my $dir =$main::CODE{main}{allocaports}{$name}{dir};
    
    #get name of mem
    if($dir eq 'input'){
      $nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{consumes}[0];
      $nameOfMem=~s/\%//;
    }
    else{
      $nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{produces}[0];
      $nameOfMem=~s/\%//;
    }
    
    #create connection wires
    #if($ioVect==1){
    #  $strPortWires = $strPortWires ."wire [`STREAMW-1:0] $name"."_data;\n";
    #  $strChildPorts= $strChildPorts.", .$name"."  ($name"."_data)\n";
    #}
    #else {
      #if($dir eq 'input'){
        for (my $v=0; $v<$ioVect; $v++) {
          $strPortWires = $strPortWires ."wire [`STREAMW-1:0] $name"."_data_s$v;\n";
          $strChildPorts= $strChildPorts.", .$name"."_s$v"."  ($name"."_data_s$v)\n";
        }
      

      #packing data wires in/out of DUT
      #the scalars in vectors are organized big-endian order (higher elements of vector are towards MSB)
      #so we have to count down when concatenating
      for (my $v=$ioVect-1; $v>=0; $v--) {
        if($dir eq 'input'){
          $strpackDataIn  = $strpackDataIn
                          . "                          ,$name"."_data_s$v\n"
                          ;
          }
        else {
         $strpackDataOut  = $strpackDataOut
                          . ",$name"."_data_s$v "
                          ;
        }
      }#for
      

      
      #}
      #else {
      #  for (my $v=0; $v<$ioVect; $v++) {
      #    $strPortWires = $strPortWires ."wire [`STREAMW-1:0] $name"."_data_s$v;\n";
      #    $strChildPorts= $strChildPorts.", .$name"."_s$v ($name"."_data_s$v)\n";
      #  }
      #}
    #}
    
    #declare and initialize global memory arrays
    $strDecGmemAr = $strDecGmemAr ."reg [`DATAW-1:0]  $nameOfMem  [0:`SIZE-1];\n";
    print "nameInHash = $nameInHash\n";
    
    #if floats, then prepend with floating bias
    if($dir eq 'input'){
      if($dataBase eq 'float'){
        $strInitArrays= $strInitArrays
                      ."    $nameOfMem\[index0\] = realtobitsSingle(3.14+index0+1);\n";}
      else {
        $strInitArrays= $strInitArrays
                      ."    $nameOfMem\[index0\] = index0+1;\n";}
    }
    else{
      $strInitArrays= $strInitArrays."    $nameOfMem\[index0\] = 0;\n";
      #for debug message
      $genCode  =~ s/<outputData>/$nameOfMem/g;
      }
      
    $strZeroPadAr = $strZeroPadAr ."$nameOfMem\[index1\] = 0;\n";
    
    #connect data wires to global memories
    my $flPre= '';#extra pre/post characters when floatin data
    my $flPst= '';#extra pre/post characters when floatin data
    #if($ioVect==1){
    #  if($dataBase eq 'float') {
    #  $excFieldFlopoco = 
    #     "//Exception fields for flopoco                                         \n"
    #    ."//A 2-bit exception field                                              \n"
    #    ."//00 for zero, 01 for normal numbers, 10 for infinities, and 11 for NaN\n"
    #    ."wire [1:0] fpcEF = 2'b01;                                              \n";
    #    $flPre = '{fpcEF,';
    #    $flPst = '}';
    #  }
    #  
    #  $strAssignInput = $strAssignInput ."assign $name"."_data = $flPre $nameOfMem\[lincount\] $flPst;\n"
    #    if($dir eq 'input');
    #  $strAssignOuput = $strAssignOuput  ."    $nameOfMem\[effaddr\] <= $nameWire;\n"
    #    if($dir eq 'output');
    #}
    #else {
      for (my $v=0; $v<$ioVect; $v++) {
        if($dir eq 'input') {
          $strAssignInput = $strAssignInput ."assign $name"."_data_s$v = $nameOfMem\[lincount+$v\];\n";
        }
        else {
          #$strAssignOuput = $strAssignOuput  ."    $nameOfMem\[effaddr+$v\] <= $nameWire"."_v$v;\n"
        
          #calculating starting and endign indices of relevant scalar from
          #concatenated vector output
          my $sPos = $v*$dataw;
          my $ePos = ($v+1)*$dataw-1;
            ##redundant as output is now already scalarized (unpacked)
          $strAssignOuput = $strAssignOuput  
                          ."    $nameOfMem\[effaddr+$v\] <= $nameWire"."_s$v;\n";
                          #."    $nameOfMem\[effaddr+$v\] <= $nameWire"."[$ePos:$sPos];\n";
        }
      }
    #}
    
    #checking and displaying results
    if ($dataBase eq 'float') {
      $bits2realOpen      = 'bitstorealSingle(';
      $bits2realClose     = ')';
      $getScalarResGold   = "bitstorealSingle(resultfromC[index]);";
      $getScalarResCalc   = "bitstorealSingle(";
      $getScalarResCalcEnd= "[index]);";
      $result_t           = 'real';
      $getScalarResGold2Compare = "\$rtoi(`VERPREC*scalarResGold);";
      $getScalarResCalc2Compare = "\$rtoi(`VERPREC*scalarResCalc);";
    }
    else {
      $getScalarResGold   = "resultfromC[index];";
      $getScalarResCalc   = "";
      $getScalarResCalcEnd= '[index];';
      $result_t           = 'integer';
      $getScalarResGold2Compare = "scalarResGold;";
      $getScalarResCalc2Compare = "scalarResCalc;";
    }
    
  }
  
  #remove first "," from generated strings where needed
  $strpackDataIn  =~ s/,{1}/ /;
  $strpackDataOut =~ s/,{1}/ /;
  
  #insert created strings into appropriate tag locations
  $genCode  =~ s/<defFloat>/$defFloat/g;
  $genCode  =~ s/<PT>/$PT/g;
  $genCode  =~ s/<portwires>/$strPortWires/g;
  $genCode  =~ s/<connectchildports>/$strChildPorts/g;
  $genCode  =~ s/<declaregmemarrays>/$strDecGmemAr/g;
  $genCode  =~ s/<initarrays>/$strInitArrays/g;
  $genCode  =~ s/<zeropadarrays>/$strZeroPadAr/g;
  $genCode  =~ s/<assigninputdata>/$strAssignInput/g;
  $genCode  =~ s/<assignoutputdata>/$strAssignOuput/g;
  $genCode  =~ s/<ioVect>/$ioVect/g;
  $genCode  =~ s/<FpHelper>/$strFpHelper/g;
  $genCode  =~ s/<streamw>/$streamw/g;
  $genCode  =~ s/<excFieldFlopoco>/$excFieldFlopoco/g;
  $genCode  =~ s/<excFieldFlopoco>/$excFieldFlopoco/g;
  $genCode  =~ s/<bits2realOpen>/$bits2realOpen/g;
  $genCode  =~ s/<bits2realClose>/$bits2realClose/g;
  $genCode  =~ s/<readCResults>/$readCResults/;
  $genCode  =~ s/<getScalarResGold>/$getScalarResGold/;
  $genCode  =~ s/<getScalarResCalc>/$getScalarResCalc/;
  $genCode  =~ s/<getScalarResCalcEnd>/$getScalarResCalcEnd/;
  $genCode  =~ s/<result_t>/$result_t/g;
  $genCode  =~ s/<getScalarResGold2Compare>/$getScalarResGold2Compare/g;
  $genCode  =~ s/<getScalarResCalc2Compare>/$getScalarResCalc2Compare/g;
  $genCode  =~ s/<packDataIn>/$strpackDataIn/g;
  $genCode  =~ s/<packDataOut>/$strpackDataOut/g;
  $genCode  =~ s/<ninputs>/$ninputs/g;
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
  
}  

