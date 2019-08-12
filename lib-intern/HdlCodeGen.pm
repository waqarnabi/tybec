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
use Cwd;

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
  my @tapsAtDelays  = @{$hash{tapsAtDelays}};
  my $maxDelay      = $buffSizeWords;
    
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  
  #sring buffers for code-gen  
  my $str_outputs         ="";
  my $str_oreadys         ="";
  my $str_oreadysAnd      = "assign oready = 1'b1\n";
  my $str_ovalids         ="";
  my $str_assign_ovalids  = "";
  my $str_assign_dataouts = "";
  my $str_shift_data_and_valid = "";
  my $str_dont_shift_data_and_valid = "";
  
  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName;
  $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.axiStreamBuff.v";
  
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
  $genCode =~ s/<size>/$buffSizeWords/g;
      
  # -------------------------------------------------------
  # >>>>> output taps
  # -------------------------------------------------------
  #code required for each output tap
  my $tcount = 0;
  foreach my $tap (@tapsAtDelays) {
    #number each tap consecutively from 1 and up (for compatibility with over generation rules)
    $tcount++;
    
    $str_outputs        .= "  , output     [STREAMW-1:0]  out$tcount"."_s0 // at delay = $tap \n";
    $str_oreadys        .= "  , input                     oready_out$tcount"."_s0\n";
    $str_oreadysAnd     .= "  & oready_out$tcount"."_s0\n";
    $str_ovalids        .= "  , output                    ovalid_out$tcount"."_s0\n";
    $str_assign_ovalids .= "assign ovalid_out$tcount"."_s0 = valid_shifter[$tap-1] & ivalid_in1_s0;\n";
    $str_assign_dataouts.= "assign out$tcount"."_s0 = offsetRegBank[$tap-1]; // at delay = $tap \n";
  }
  
  #create the shift register for data and valid
  #template already has code for $d = 0
  foreach my $d (1..$maxDelay-1) {
    $str_shift_data_and_valid      .= "    offsetRegBank[$d]  <=  offsetRegBank[$d-1];\n"; 
    $str_shift_data_and_valid      .= "    valid_shifter[$d]  <=  valid_shifter[$d-1];\n"; 
    $str_dont_shift_data_and_valid .= "    offsetRegBank[$d]  <=  offsetRegBank[$d];\n"; 
    $str_dont_shift_data_and_valid .= "    valid_shifter[$d]  <=  valid_shifter[$d];\n"; 
  }
  
  $str_oreadysAnd .= "  ;";
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/<outputs>/$str_outputs/g;
  $genCode =~ s/<oreadys>/$str_oreadys/g;
  $genCode =~ s/<oreadysAnd>/$str_oreadysAnd/g;
  $genCode =~ s/<ovalids>/$str_ovalids/g;
  $genCode =~ s/<assign_ovalids>/$str_assign_ovalids/g;
  $genCode =~ s/<assign_dataouts>/$str_assign_dataouts/g;
  $genCode =~ s/<shift_data_and_valid>/$str_shift_data_and_valid/g;
  $genCode =~ s/<dont_shift_data_and_valid>/$str_dont_shift_data_and_valid/g;
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
} 

# ============================================================================
# GENERATE AXI _STENCIL_ BUFFER
# ============================================================================

sub genAxiStencilBuffer {
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
  my $synthunit   = 'smache';
  my $synthDtype  = $hash{synthDtype};
  my $datat       = $synthDtype; #complete type (e.g i32)    
  (my $dataw = $datat)     =~ s/\D*//g; #width in bits
  (my $dataBase = $datat)  =~ s/\d*//g; #base type (ui, i, or float)
  my $maxP = $hash{maxPosOffset};
  my $maxN = $hash{maxNegOffset};
  my $buffSizeWords = $maxP + $maxN + 1;
  #for left-to-right streaming shift register (LS word has latest/highest pos index)
  # so for offset:
  #k      @ buff[maxP-k]
  #so
  #0      @ buff[maxP]
  #+maxP  @ buff[0]
  #-maxN  @ buff[maxP+maxN]
  my $ind_0 = $maxP;
  
  my @tapsAtPosDelays  = @{$hash{tapsAtPosDelays}};
  my @tapsAtNegDelays  = @{$hash{tapsAtNegDelays}};
  my $maxDelay      = $buffSizeWords;
    
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  
  #sring buffers for code-gen  
  my $str_outputs         ="";
  my $str_oreadys         ="";
  my $str_oreadysAnd      = "assign oready = 1'b1\n";
  my $str_ovalids         ="";
  my $str_assign_ovalids  = "";
  my $str_assign_dataouts = "";
  my $str_shift_data_and_valid = "";
  my $str_dont_shift_data_and_valid = "";
#  
  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName;
  $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.axiStencilBuff.v";
  
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
  $genCode =~ s/<size>/$buffSizeWords/g;
      
  # -------------------------------------------------------
  # >>>>> output taps
  # -------------------------------------------------------
  # other than calculation of buffer address, code gen is same
  # for positive or negative offsets
  # name of output ports in smache, unlike other _leaf_ nodes, is _not_ generic (out1, out2...)
  # Instead, like hierarchical nodes, the output port name is same as the connectio name (that is, the identifier of the
  # stream it is producing
  
  foreach my $offstream (keys %{$hash{offstreams}}) {
    my $dist    = $hash{offstreams}{$offstream}{dist};
    my $dir     = $hash{offstreams}{$offstream}{dir};
    
    $offstream =~ s/(%|@)//g; 
    my $bufAddr;
    $bufAddr = $maxP-$dist if ($dir eq '+');
    $bufAddr = $maxP+$dist if ($dir eq '-');
    
    $str_outputs        .= "  , output     [STREAMW-1:0]  $offstream"."_s0\n ";
    $str_oreadys        .= "  , input                     oready_$offstream"."_s0\n";
    $str_oreadysAnd     .= "  & oready_$offstream"."_s0\n";
    $str_ovalids        .= "  , output                    ovalid_$offstream"."_s0\n";
    $str_assign_ovalids .= "assign ovalid_$offstream"."_s0 = valid_shifter[$maxP] & ivalid_in1_s0;\n";
      #the output is "valid" when the maximum POSITIVE offset is in (and thus the *current index* is now at 0)
      #if, at this point, you try to generate and access and _negative_ offsets, you will get garbage values
      #as the current index is at 0, and negative indices dont exist
      #boundary conditions in the subsequent nodes should take care of this (OR, we can emit strobe signals 
      #from the smache
    $str_assign_dataouts.= "assign $offstream"."_s0 = offsetRegBank[$bufAddr];\n";    
  }
  
#OBSOLETE loops  
#  foreach my $tap (@tapsAtPosDelays) {
#    #$tcount++;
#    my $bufAddr = $maxN+$tap;
#    $str_outputs        .= "  , output     [STREAMW-1:0]  out_p_$tap"."_s0\n ";
#    $str_oreadys        .= "  , input                     oready_out_p_$tap"."_s0\n";
#    $str_oreadysAnd     .= "  & oready_out_p_$tap"."_s0\n";
#    $str_ovalids        .= "  , output                    ovalid_out_p_$tap"."_s0\n";
#    $str_assign_ovalids .= "assign ovalid_out_p_$tap"."_s0 = valid_shifter[$maxDelay-1] & ivalid_in1_s0;\n";
#    $str_assign_dataouts.= "assign out_p_$tap"."_s0 = offsetRegBank[$bufAddr];\n";
#  }
#  
#  foreach my $tap (@tapsAtNegDelays) {
#    #$tcount++;
#    my $bufAddr = $maxN-$tap;
#    $str_outputs        .= "  , output     [STREAMW-1:0]  out_n_$tap"."_s0\n ";
#    $str_oreadys        .= "  , input                     oready_out_n_$tap"."_s0\n";
#    $str_oreadysAnd     .= "  & oready_out_n_$tap"."_s0\n";
#    $str_ovalids        .= "  , output                    ovalid_out_n_$tap"."_s0\n";
#    $str_assign_ovalids .= "assign ovalid_out_n_$tap"."_s0 = valid_shifter[$maxDelay-1] & ivalid_in1_s0;\n";
#    $str_assign_dataouts.= "assign out_n_$tap"."_s0 = offsetRegBank[$bufAddr];\n";
#  }

  #create the shift register for data and valid
  #template already has code for $d = 0
  foreach my $d (1..$maxDelay-1) {
    $str_shift_data_and_valid      .= "    offsetRegBank[$d]  <=  offsetRegBank[$d-1];\n"; 
    $str_shift_data_and_valid      .= "    valid_shifter[$d]  <=  valid_shifter[$d-1];\n"; 
    $str_dont_shift_data_and_valid .= "    offsetRegBank[$d]  <=  offsetRegBank[$d];\n"; 
    $str_dont_shift_data_and_valid .= "    valid_shifter[$d]  <=  valid_shifter[$d];\n"; 
  }
  
  $str_oreadysAnd .= "  ;";
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/<outputs>/$str_outputs/g;
  $genCode =~ s/<oreadys>/$str_oreadys/g;
  $genCode =~ s/<oreadysAnd>/$str_oreadysAnd/g;
  $genCode =~ s/<ovalids>/$str_ovalids/g;
  $genCode =~ s/<assign_ovalids>/$str_assign_ovalids/g;
  $genCode =~ s/<assign_dataouts>/$str_assign_dataouts/g;
  $genCode =~ s/<shift_data_and_valid>/$str_shift_data_and_valid/g;
  $genCode =~ s/<dont_shift_data_and_valid>/$str_dont_shift_data_and_valid/g;
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
#  
  print "TyBEC: Generated module $modName\n";  
} 

# ============================================================================
# GENERATE AUTOINDEX
# ============================================================================

sub genAutoIndex {
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
  my $synthunit   = 'autoindex';
  my $synthDtype  = $hash{synthDtype};
  my $datat       = $synthDtype; #complete type (e.g i32)    
  (my $dataw = $datat)     =~ s/\D*//g; #width in bits
  (my $dataBase = $datat)  =~ s/\d*//g; #base type (ui, i, or float)
  my $startat     = $hash{start};
  my $wrapat      = $hash{end};

  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  
  #sring buffers for code-gen  
#  
  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName;
  $templateFileName = "$TyBECROOTDIR/hdlGenTemplates/template.autocounter.v";
  
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

      
  
  # ------------------------------------
  # >>>>> Update tags and write to file
  # ------------------------------------
  $genCode =~ s/<counterw>/$dataw/g;
  $genCode =~ s/<startat>/$startat/g;
  $genCode =~ s/<wrapat>/$wrapat/g;
  #$genCode =~ s/<outputs>/$str_outputs/g;
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

  #need latency to generate correct ovalid signal
  #all leaf nodes (must) have deterministic, fixed latency
  my $lat = $hash{performance}{lat};

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

  #ovalid logic, diff for integer vs float
  my $str_ovalidLogic = '';
  
  
  #in case of FP units, 2 MSBs are fixed as per requirements of flopoco
  my $str_fpcEF = "";
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
   
  #I used to have separate iready's for each input, but redundant, a single should
  #be used
  foreach (@{$hash{consumes}}) {
    (my $src = $_) =~ s/\%//;
    $str_inputIvalids       = $str_inputIvalids."  , input ivalid_in".$index."_s0\n"; 
    #$str_inputIreadys       = $str_inputIreadys."  , output iready_in".$index."_s0\n"; 
    $str_inputIvalidsAnded  = $str_inputIvalidsAnded."ivalid_in".$index."_s0 & ";
    #$str_ireadysFanout      = $str_ireadysFanout."assign iready_in".$index."_s0 = iready;\n";
    $index++;
  }
  $str_inputIvalidsAnded = $str_inputIvalidsAnded." 1'b1;\n";
  
  # -------------------------------------------------------
  # >>>>> add datapath logic
  # -------------------------------------------------------

  #---------------------------
  #deal with constant operands
  #---------------------------
  
  #if any of the input ports are constants, make sure they are not in the port list
  for (my $i=0; $i<$vect; $i++) {
    $firstOpInputPort  = "" if(                 ($hash{oper1form} eq 'constant'));
    $secondOpInputPort = "" if(($nInOps > 1) && ($hash{oper2form} eq 'constant'));
    $thirdOpInputPort  = "" if(($nInOps > 2) && ($hash{oper3form} eq 'constant'));
  }

  
    
  #---------------
  #int
  #---------------
  #the LOAD operation of float is same as int, so dealt with here
  if ( ($synthDtype =~ m/i\d+/)
     ||(($synthDtype eq 'float32') && ($synthunit eq 'load'))
     )
  {
  
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
  
  #---------------
  #float
  #---------------
  elsif ($synthDtype eq 'float32') {
    
    #first check if any constant inputs, and assign them to local variables
    #witgh name as they would have had if they were regular ports
    #makes later code generation uniform
    #float constants need a little function to convery floating poitn values to equivalent HEX for use in HDL
    sub float2hex {return unpack ('H*' => pack 'f>' => shift)};
    
    #flopoco requires 2 extra bits 
    $str_fpcEF = "wire [1:0] fpcEF = 2'b01;\n";

    for (my $i=0; $i<$vect; $i++) {
      $str_assignConstants  = $str_assignConstants. "wire [STREAMW-1:0] in1_s$i = {fpcEF, 32'h${\float2hex($hash{oper1val})} };"
        if ($hash{oper1form} eq 'constant');
      $str_assignConstants  = $str_assignConstants. "wire [STREAMW-1:0] in2_s$i = {fpcEF, 32'h${\float2hex($hash{oper2val})} };"
        if (($nInOps > 1) && ($hash{oper2form} eq 'constant'));
      $str_assignConstants  = $str_assignConstants. "wire [STREAMW-1:0] in3_s$i = {fpcEF, 32'h${\float2hex($hash{oper3val})} };"
        if (($nInOps > 2) && ($hash{oper3form} eq 'constant'));
    }    
    
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
      $flopocoIPFile    = "$flopocoCoresRoot/FPSubSingleDepth7_stallable.vhd";
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
    elsif ($synthunit eq 'udiv') {
      $flopocoIPFile    = "$flopocoCoresRoot/FPDivSingleDepth12_stallable.vhd";
      $flopocoModule    = "FPDiv_8_23_F300_uid2";
      $flopopModuleInst = "fpDiv";
      $err =copy("$flopocoIPFile", "$outputRTLDir");
    
    }
    else                        {die "TyBEC: Unknown float operator used\n";}    
    
    #instantiate flopoco IP in the node module

    for (my $v=0; $v<$vect; $v++) {
      $strBuf .= $strBuf ."$flopocoModule  $flopopModuleInst"."_$v\n"
                      ."  ( .clk (clk)     \n"
                      ."  , .rst (rst)     \n"
                      ."  , .stall (~dontStall)     \n"
                      ."  , .X   (in1_s$v)     \n"
                      ."  , .Y   (in2_s$v)     \n"
                      ."  , .R   (out1_pre_s$v)\n"
                      .");"
                      ;
    }#for                      
  }#if float

  #--------------------------------
  #types other than int and float?
  #--------------------------------
  else {die "TyBEC: only intNN and float32 currently supported for code generation\n";}
  
    #---------------
    #ovalid logic
    #---------------
    #TODO: No need to have separate branchs for genersting int (1 cycle latecy) and float (n-cycle latency)
    #ovalid logic as the same loop should work ok for 1-cycle latency
    $str_ovalidLogic  .="//output valid\n"
                      . "//follows ivalid with an N-cycle delay (latency of this unit)\n"
                      . "//Also, only asserted with no back-pressure (oready asserted)\n"
                      ;
    #ovalid logic for floats; propagate ivalid along a shift register
    if ($synthDtype eq 'float32') {
      $str_ovalidLogic  .= "reg [$lat-1:0] valid_shifter;\n"
                        .  "always @(posedge clk) begin\n"
                        .  "  if(ivalid) begin\n"
                        .  "    valid_shifter[0] <= ivalid;\n"
                        ;
      
      #start shifting TO index 1, as 0th index does not follow pattern
      foreach my $d (1..$lat-1) {
        $str_ovalidLogic .= "    valid_shifter[$d]  <=  valid_shifter[$d-1];\n"; 
      }                        
      
      $str_ovalidLogic  .= "  end\n";
      $str_ovalidLogic  .= "  else begin\n";
      
      foreach my $d (0..$lat-1) {
        $str_ovalidLogic .= "    valid_shifter[$d]  <=  valid_shifter[$d];\n"; 
      }                        
      $str_ovalidLogic  .= "  end //else\n";
      $str_ovalidLogic  .= "end //always\n";

      $str_ovalidLogic  .= "\nassign ovalid = valid_shifter[$lat-1] & oready;\n";

    } 

    #ovalid logic for ints
    else {
      $str_ovalidLogic  .= "reg ovalid_pre;\n";
      $str_ovalidLogic  .="always @(posedge clk) begin\n"
                        . "  if(rst)\n"
                        . "    ovalid_pre <= 0;\n"
                        . "  else\n" 
                        . "    ovalid_pre <= ivalid & oready;\n"
                        . "end\n"
                        ;
      $str_ovalidLogic  .= "\nassign ovalid = ovalid_pre;\n";
    }                      
  
  $genCode  =~ s/<datapath>/$strBuf/g;
  $genCode  =~ s/<oStrWidth>/$oStrWidth/g;
  $genCode  =~ s/<firstOpInputPort>/$firstOpInputPort/g;
  $genCode  =~ s/<secondOpInputPort>/$secondOpInputPort/g;
  $genCode  =~ s/<thirdOpInputPort>/$thirdOpInputPort/g;
  $genCode  =~ s/<inputIvalids>/$str_inputIvalids/g;
  #$genCode  =~ s/<inputReadys>/$str_inputIreadys/g; #replaced by a single iready output
  $genCode  =~ s/<inputIvalidsAnded>/$str_inputIvalidsAnded/g;
  $genCode  =~ s/<ireadysFanout>/$str_ireadysFanout/g;
  $genCode  =~ s/<assignConstants>/$str_assignConstants/g;
  $genCode  =~ s/<instFifoBuff>/$str_instFifoBuff/g;
  $genCode  =~ s/<ovalidLogic>/$str_ovalidLogic/g;
  $genCode  =~ s/<fpcEF>/$str_fpcEF/g;
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
    #but dont add +s in main, as we explicitly add/remove these 2 bits in main for upwards 32-bit compatibility
  my $streamw;
  if(($dataBase eq 'float') && ($dfgroup ne 'main')) {$streamw=$dataw+2;}
  else                                               {$streamw=$dataw;}
  
  
  
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
  my $str_ireadyConns= "";
  my $excFieldFlopoco='';
  my $flPre='';
  my $flPst='';  
  # -------------------------------------------------------
  # >>>>> prepend flopoco control bits if main
  # -------------------------------------------------------
  if(($dataBase eq 'float') && ($dfgroup eq 'main')) {
    $excFieldFlopoco = 
     "//Exception fields for flopoco                                         \n"
    ."//A 2-bit exception field                                              \n"
    ."//00 for zero, 01 for normal numbers, 10 for infinities, and 11 for NaN\n"
    ."wire [1:0] fpcEF = 2'b01;                                              \n";
    $flPre = '{fpcEF,';
    $flPst = '}';
  }
  
  
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
      #a local hash to keep track of IREADYs that need to be collected (anded) 
      #applies to a oneProducerOneSignal-to-manyConsumer scenario
      my %iReadyHash;
      
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
                      ."  , $dir"." [STREAMW-1:0]  $ident"."_s$i\n"
                      ;
          }#for
          
          #create input valids from all inputs, and AND them together:
          if($dir eq 'input') {
            $str_ivalids     = $str_ivalids."  , input ivalid_".$ident."_s0\n"; 
            $str_ivalidsAnd  = $str_ivalidsAnd."  & ivalid_".$ident."_s0\n";
          }
          
          #create output readys from all outputs, and AND them together:
          if($dir eq 'output') {
            $str_oreadys     = $str_oreadys."  , input oready_".$ident."_s0\n"; 
            $str_oreadysAnd  = $str_oreadysAnd."  & oready_".$ident."_s0\n";
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
                        . "  , $dir"." [STREAMW-1:0]  $name\n"
                        ;
            }
            #if not, the vector elements are separately available
            else {
              for (my $i=0; $i<$vect; $i++) {
              $strPorts  = $strPorts."\n"
                        . "  , $dir"." [STREAMW-1:0]  $name"."_s$i\n"
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
          ||($cat eq 'smache')
          ||($cat eq 'autoindex')
          ){
          #remove _N from identity of funcall instructions
          #$ident =~ s/\.\d+// if($cat eq 'funcall');
          $ident =~ s/\_\d+$// if($cat eq 'funcall');

          #name of module to instantiate
          my $module2Inst = $parentFunc."_".$ident;
          
          for (my $v=0; $v<$vect; $v++) {
            my $modInstanceName = $module2Inst."_i_s$v";
              
            #if I need to extract scalar from packed vector, what are the hi/lo bits
            my $lo = $v*$streamw;
            my $hi = ($v+1)*$streamw-1;
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
              $strInsts .= ", .out1_s0  ( $ident"."_s$v)\n"; 
              
              if($dir eq 'output') {
                #ovalid for this func-arg is used to create the global ovalid
                #and since this is a terminal node, it is fed the global oready
                $strInsts.= ", .ovalid (ovalid_$ident"."_s$v)\n"
                          . ", .oready (oready)\n"
                          ;    
                #each generated module for a vector element has its own ovalid
                $strConns .= "\nwire ovalid_$ident"."_s$v;";
                $str_ovalids .= "        ovalid_$ident"."_s$v &\n";
              }
            }
            
            #connections -- outputs
            #-----------------------
            my @succs = $main::dfGraph->successors($item);
            foreach my $consumer (@succs) {
              #Loop over multi-edges (that is, multiple wires between prod and cons)
              #if applicable
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
                                      || ($cnode_cat eq 'smache') 
                                      ;
                #condition indicating producer is node, as node modules have different port naming
                #conventions (single oready, named "oready")
                my $producerisLeafNode =  ($pnode_cat eq 'impscal')
                                       || ($pnode_cat eq 'fifobuffer')
                                       ;            
                                       
                my $producerisBuffer =  ($pnode_cat eq 'fifobuffer')
                                     || ($pnode_cat eq 'smache')
                                     ;
                                     
                my $producerisAutoindex = ($pnode_cat eq 'autoindex');

                #depending on location in the vector, we will either append _sX
                #or choose the correct data slice (main only)
                if ($dfgroup eq 'main') {$connection = $connection."[$hi:$lo]";}
                else                    {$connection = $connection."_s$v";}

                #data port connection 
                #child ports data port is always s0
                $strInsts   .= ", .$pnode_local"."_s0"."  ( $connection )\n";
                
                #each generated module for a vector element has its own ovalid
                #$strConns    .= "\nwire ovalid_s$v;\n";
                #$str_ovalids .= "        ovalid_s$v &\n";
                
                #the consumer-side axi signal connections (and requirement of explicit connection wires)
                #depend on whether consumer is a another module instance, or direct connection to parent port
                my $app = '';
                if ($consumerisModule) {
                  #connection wires
                  $strConns .= "\nwire [STREAMW-1:0]  $connection;";
                  #valid signal is names after _module_, not the _connection_, as every module has a _single_ ovalid
                  #which should be used for ALL consumers. See NOTES, 2017.07.15
                  #$strConns .= "\nwire valid_$connection;"; 
                  $strConns .= "\nwire valid_$ident;"; 
                  $strConns .= "\nwire ready_$connection;";
                  #control port connetions
                  #if producer is fifobuffer, it can have multiple ovalids (this is the only case)
                  #so the ovalids are appended with relevant output data identifieer
                  $app = "_$pnode_local"."_s$v" if $producerisBuffer;
                  #$strInsts .= ", .ovalid$app (valid_$connection)\n";
                  $strInsts .= ", .ovalid$app (valid_$ident)\n";
                  
                  #oready 
                  #------
                  #is named differently depending on whether or not producer is a leaf node
                  #as leaf nodes have a single oready named "oready"
                  #also, autoindex do not have oreadys
                  $app = '';
                  if ($producerisLeafNode) {
                    #if producer is fifobuffer, it can have multiple oreadys (this is the only case)
                    #so the ovalids are appended with relevant output data identifieer
                    $app = "_$pnode_local"."_s$v" if $producerisBuffer;
                    $strInsts .=  ", .oready$app (ready_$connection)\n";
                    #TODO: if multiple consumers for this leaf node, then the single OREADY
                    #has to be distributed across nodes
                  }
                  elsif ($producerisAutoindex) {
                    $strInsts .= '';
                  }
                  else {
                    $strInsts .=  ", .oready_$pnode_local"."_s0 (ready_$connection) \n";}
                }
                
                #consumer is parent port
                #so the ovalid from the producer should be used to create the global ovalid
                else {
                  $strConns   .= "\nwire ovalid_$ident"."_s$v;";
                  $str_ovalids.= "        ovalid_$ident"."_s$v &\n";
                  $strInsts   .=", .oready_$pnode_local\_s0 (oready)\n"   #20190205
                              . ", .ovalid (ovalid_$ident"."_s$v)\n"
                              ;
                }
                
                
                #autoindex requires special treatment, as it does not have a predecessor
                #so it is only a consumer. We need to find the right trigger for it
                if ($pnode_cat eq 'autoindex'){
                
                  my $trigger;
                  #this is nested _over_ another counter, so input trigger is output wrap trigger 
                  #of that counter.
                  if (exists $main::CODE{$parentFunc}{symbols}{$symbol}{nestOver}) {
                    my $nestOver = $main::CODE{$parentFunc}{symbols}{$symbol}{nestOver};
                    my $nestOverConn = $main::CODE{$parentFunc}{symbols}{$nestOver}{produces}[0];
                    $nestOverConn =~ s/(%|@)//;
                    $trigger = "trig_wrap_$nestOverConn"."_s0";
                  }
                  else {
                    #find the source stream for creating the autoindex
                    #then find it's VALID (whose name depends on whether or not is an  input arg)
                    #to use as trigger
                    my $sstream = $main::CODE{$parentFunc}{symbols}{$symbol}{sstream};
                    my $sstream_cat = $main::CODE{$parentFunc}{symbols}{$sstream}{cat};
                    $sstream =~ s/(%|@)//; 
                    if ($sstream_cat eq 'arg')  {$trigger = "ivalid";}
                    else                        {$trigger = "valid_$sstream"."_s0";}
          
                  }
                  #connect with the identified trigger
                  $strInsts .=  ", .trig_count ($trigger) \n";
                  
                  #create and connect to output wrap trigger signal
                  $strConns .= "\nwire trig_wrap_$connection;";
                  $strInsts .=  ", .trig_wrap  (trig_wrap_$connection) \n";
                }
              }#foreach my $id (@multiedges) {
            }#foreach consumer
            
            
            #connections -- inputs
            #-----------------------
            my @preds = $main::dfGraph->predecessors($item);
            foreach my $producer (@preds) {
              
              #get producer identifier (it's name in the DFG graph is quite mangled)
              my $psymbol    = $main::dfGraph -> get_vertex_attribute ($producer, 'symbol'    );
              (my $pident =  $psymbol)  =~ s/(%|@)//; #remove %/@
              $pident                   =~ s/\_\d+$//; #remove _N subscript
              
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
                                     || ($pnode_cat eq 'smache')                                    
                                     || ($pnode_cat eq 'autoindex')                                    
                                     ;

                $connection =~ s/(%|@)//; 
                #depending on location in the vector, we will either append _sX
                #or choose the correct data slice (main only)
                if ($dfgroup eq 'main') {$connection = $connection."[$hi:$lo]";}
                else                    {$connection = $connection."_s$v";}

                #port for the $item
                #child ports data port is always s0                
                $strInsts   .= ", .$cnode_local"."_s0"."  ( $flPre $connection $flPst)\n";
                 
                #each generated module for a vector element has its own iready
                $strConns   .= "\nwire iready_$ident"."_s$v;  \n";
                
                #$str_ireadysAnd = $str_ireadysAnd."        iready_$ident"."_s$v &\n";
                #if producer is port (so this is first stage node), then use it to create the global IREADY
                $str_ireadysAnd .= "        iready_$ident"."_s$v &\n" if ($producerisPort);

                #the producer-side axi signal connections (and requirement of explicit connection wires)
                #depend on whether producer is a another module instance, or direct connection to parent port
                if ($producerisModule) {
                  #connection wires
                  $strConns .= "\nwire [STREAMW-1:0]  $connection;";
                  #valid signal is names after _module_, not the _connection_, as every module has a _single_ ovalid
                  #which should be used for ALL consumers. See NOTES, 2017.07.15                  
                  #$strConns .= "\nwire valid_$connection;";
                  $strConns .= "\nwire valid_$pident;";
                  $strConns .= "\nwire ready_$connection;";
                  
                  #port connetions
                  #we  have IVALID for EACH input port
                  #IREADY is common for node
                  #$strInsts .= ", .ivalid_$cnode_local"."_s$v (valid_$connection)\n"
                  #$strInsts .= ", .ivalid_$cnode_local"."_s$v (valid_$pident)\n"
                  $strInsts .= ", .ivalid_$cnode_local"."_s0 (valid_$pident)\n"
                            .  ", .iready (iready_from_$ident)\n"
                            ;
                  #manyproducers-to-oneconsumer                            
                  #a single, common iready is now fed to each predecessor's oready...
                  #make those connections (glue logic) here (simple fan-out)
                  $str_ireadyConns .= "wire iready_from_$ident;\n";
                  #$str_ireadyConns .= "assign ready_$connection = iready_from_$ident;\n";
                  #$str_ireadyConns .= "ready_$connection &= iready_from_$ident;\n";
                  
                  #oneproducer-to-manyconsumers
                  #collect iready into hash, generate later
                  push @{$iReadyHash{"ready_$connection"}}, "iready_from_$ident";
                }
                #producer is port; 
                #ivalid connects directly to parent ivalid
                #iready connects to local wire (which is ANDED to produce a global IREADY)
                else {
                  #$strInsts   .=", .ivalid_$cnode_local"."_s$v (ivalid)\n"
                  $strInsts   .=", .ivalid_$cnode_local"."_s0 (ivalid)\n"
                              . ", .iready (iready_$ident"."_s$v)\n"
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
      }#foreach node  

      #after looping over all inputs of all nodes, now go through the iReady hash and 
      #create all ready signals
      #See NOTES, for date: 2019.06.07 (or thereabout)
      foreach my $readyConns (keys %iReadyHash) {
        #make sure each connection in the list against this hash (ready connection wire) is unique
        #duplications arise as the same connection is made from both prod and cons p.o.v.
        my %hash = map {$_,1} @{$iReadyHash{$readyConns}};
        my @readyConnsUniq = keys %hash;

        #now generate first list of assigment, then loop over connections to and them into a single
        #iready that should go to all predecessors        
        $str_ireadyConns .= "assign $readyConns = 1'b1 ";        
        foreach (@readyConnsUniq) {
          $str_ireadyConns .= "& $_";
        }
        $str_ireadyConns .= ";\n";
      } 
      
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
      remove_duplicate_lines($str_ireadyConns);
      
      $genCode  =~ s/<ports>/$strPorts/g;
      $genCode  =~ s/<connections>/$strConns/g;
      $genCode  =~ s/<ovalids>/$str_ovalids/g;
      $genCode  =~ s/<ireadysAnd>/$str_ireadysAnd/g;
      $genCode  =~ s/<ivalids>/$str_ivalids/g;
      $genCode  =~ s/<ivalidsAnd>/$str_ivalidsAnd/g;
      $genCode  =~ s/<oreadys>/$str_oreadys/g;
      $genCode  =~ s/<oreadysAnd>/$str_oreadysAnd/g;
      $genCode  =~ s/<ireadyConns>/$str_ireadyConns/g;
      $genCode  =~ s/<excFieldFlopoco>/$excFieldFlopoco/g;      
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
 
  my $cwd = getcwd; #pwd needed for passing absolute path of results to xilinx ISE testbench

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
  #my $streamw;
  #if($dataBase eq 'float')  {$streamw=$dataw+2;}
  #else                      {$streamw=$dataw;}
  
  #no need now, as flopoco control bits are added/removed internally for upwards host-code compatimilty
  my $streamw = $dataw;
  
  $genCode =~ s/<streamw>/$streamw/g;
  

    
  
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
  my $str_ivalid_toduts  = ''; 
  my $str_iready_fromduts= '';
  my $str_wire_iready_fromduts= '';
  
  my $array4verifyingResult = '';
  # -------------------------------------------------------
  # if float, include helper and also define macro, and type of resultC
  # also set how to print outputs using printfs (%d/%f)
  # -------------------------------------------------------
  if($dataBase eq 'float') {
    my $srcdir = "$TyBECROOTDIR/hdlGenTemplates";
    my $err;
    #I was earlier copying this helper file into HDL folder, but it is only used by 
    #testbench so best to keep it there
    #$err =copy("$srcdir/template.spFloatHelpers.v" , "$outputRTLDir/../hdl/spFloatHelpers.v"); 
    $err =copy("$srcdir/template.spFloatHelpers.v" , "$outputRTLDir/spFloatHelpers.v"); 
    $strFpHelper = "//helper functions for SP-floats\n"
#                 . "`include \"../hdl/spFloatHelpers.v\" "
                 . "`include \"spFloatHelpers.v\" "
                 ;
    $defFloat = '`define FLOAT';
    $PT       = 'f';
  }
  # -------------------------------------------------------
  # read ground truth from C simulation, set output print type
  # -------------------------------------------------------

  #this is the typical case
  #$readCResults = "\$readmemh(\"../../../../../../../c/verifyChex.dat\", resultfromC);\n";

  #vivado likes absolute path
  $readCResults =  "//Absolute path as readmemh behaviour unreliable across different simulators (vivado likes absolute path)\n";
  $readCResults .= "\$readmemh(\"$cwd/../../c/ver3/verifyChex.dat\", resultfromC);\n";

  #in some test cases, each tir version has its own C version, this is manually set in the generated testbench
  #this is ugly FIXME
  #$readCResults = "\$readmemh(\"../../../../../../../c/verX/verifyChex.dat\", resultfromC);\n";
  
  
  if ($dataBase eq 'float') {
  $readCResults = "$readCResults\n"
                . ""
                ;
                
  }

  # -------------------------------------------------------
  # how many total inputs/outputs? 
  #   - create packed  busses
  #   - connect Xple ivalids, ireadys
  # -------------------------------------------------------
  my $ninputs = 0;
  my $noutputs = 0;
  foreach my $key (keys %{$main::CODE{main}{allocaports}}) {
    my $dir =$main::CODE{main}{allocaports}{$key}{dir};
    $ninputs  = $ninputs+1  if($dir eq 'input');
    $noutputs = $noutputs+1 if($dir eq 'output');
    
    #in case of multiple outputs, pick the last one for result verification
    #since $key is name of the stream, I have to lookup the hash to find the corresponding memory array
    #this should be deterministic FIXME
    $array4verifyingResult = $main::CODE{main}{symbols}{"%$key"}{produces}[0] if($dir eq 'output');
    $array4verifyingResult =~ s/\%//;
  }
  
  #handle ivalid, iready, for each input
  my $loopto = $noutputs;
  $loopto = 1 if ($main::ocxTempVer eq 't08'); #for template version 9, inputs are coalesced (FIXME)
  
  foreach my $i (0..$loopto-1) {
    my $c = ($i == 0) ? "" : ", ";
    $str_ivalid_toduts        .= "$c"."ivalid_todut"; 
    $str_iready_fromduts      .= "$c"."iready_fromdut$i";
    $str_wire_iready_fromduts .= "wire iready_fromdut$i;\n";
  }
  
  

  # -------------------------------------------------------
  # generate ports and connection in instantiation of DUT
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
    if($dir eq 'input') {$nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{consumes}[0];}
    else                {$nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{produces}[0];}
    $nameOfMem=~s/\%//;

    
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
    #print "nameInHash = $nameInHash\n";
    
    #if floats, then prepend with floating bias
    if($dir eq 'input'){
      if($dataBase eq 'float'){
        $strInitArrays= $strInitArrays
                      ."    $nameOfMem\[index0\] = realtobitsSingle(3.14+index0+1);\n";}
      else {
        $strInitArrays= $strInitArrays
                      ."    $nameOfMem\[index0\] = index0+1;\n";}
                      #."    $nameOfMem\[index0\] = index0;\n";}
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
    #  $strAssignOuput = $strAssignOuput  ."    $nameOfMem\[effaddr\] <= $nameWire"."_s$v;\n";
    #    if($dir eq 'output');
    #}
    #else {
      for (my $v=0; $v<$ioVect; $v++) {
        
        #the following is redundant now, as flopoco control bits are handled internally
        #if($dataBase eq 'float') {
        #  $excFieldFlopoco = 
        #   "//Exception fields for flopoco                                         \n"
        #  ."//A 2-bit exception field                                              \n"
        #  ."//00 for zero, 01 for normal numbers, 10 for infinities, and 11 for NaN\n"
        #  ."wire [1:0] fpcEF = 2'b01;                                              \n";
        #  $flPre = '{fpcEF,';
        #  $flPst = '}';
        #}

        if($dir eq 'input'){ 
          $strAssignInput = $strAssignInput ."assign $name"."_data_s$v = $flPre $nameOfMem\[lincount+$v\] $flPst;\n"
        } else {
          my $sPos = $v*$dataw;
          my $ePos = ($v+1)*$dataw-1;
          #calculating starting and endign indices of relevant scalar from
          #concatenated vector output
            ##redundant as output is now already scalarized (unpacked)
          $strAssignOuput = $strAssignOuput  
                          ."    $nameOfMem\[effaddr+$v\] <= $nameWire"."_s$v;\n";
          #$strAssignOuput = $strAssignOuput  ."    $nameOfMem\[effaddr\] <= $nameWire"."_s$v;\n";
        }#else
        #if($dir eq 'input') {
        #  $strAssignInput = $strAssignInput ."assign $name"."_data_s$v = $nameOfMem\[lincount+$v\];\n";
        #}
        #else {
        #  #$strAssignOuput = $strAssignOuput  ."    $nameOfMem\[effaddr+$v\] <= $nameWire"."_v$v;\n"
        #
        #                  #."    $nameOfMem\[effaddr+$v\] <= $nameWire"."[$ePos:$sPos];\n";
        #}
      }#for
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
  $genCode  =~ s/<noutputs>/$noutputs/g;
  $genCode  =~ s/<ivalid_toduts>/$str_ivalid_toduts/g;
  $genCode  =~ s/<iready_fromduts>/$str_iready_fromduts/g;
  $genCode  =~ s/<wire_iready_fromduts>/$str_wire_iready_fromduts/g;
  
  $genCode  =~ s/<array4verifyingResult>/$array4verifyingResult/g;
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
  
}  

