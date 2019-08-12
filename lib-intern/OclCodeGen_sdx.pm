# =============================================================================
# Company      : Unversity of Glasgow, Comuting Science
# Author:        Syed Waqar Nabi
# 
# Create Date  : 2017.07.30
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
# OCL Code Generator Module for use with TyBEC
#
# Target is SDx
# =============================================================================                        

package OclCodeGen_sdx;
use strict;
use warnings;

#use Data::Dumper;
use File::Slurp;
use File::Copy qw(copy);
use List::Util qw(min max);
use Term::ANSIColor qw(:constants);
use bigint;

use Exporter qw( import );

our $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};



# ============================================================================
# GENERATE HDL WRAPPER (Top level HDL meeting AXI stream)
# ============================================================================

sub genHdlWrapper {
  #which OCX gen template version?
  my $tv = $main::ocxTempVer; 
  
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$modName           #module_name
      ,$designName
      ,$outputOCLDir
      ,$ioVect
      ,$datat
      ,$dataw
      ) = @_; 

  my $dfgroup = 'main'; 
  my %hash    = %{$main::CODE{main}};  #the hash from parsed code for this pipe function
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/sdx/$tv/src/hdl/func_hdl_top.sv"; 
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
  # >>>>> dataw/streamw
  # -------------------------------------------------------
  (my $dataBase = $datat)  =~ s/\d*//g;
  my $streamw;
  if($dataBase eq 'float')  {$streamw=$dataw+2;}
  else                      {$streamw=$dataw;}
  
  $genCode =~ s/<dataw>/$dataw/g;
  $genCode =~ s/<streamw>/$streamw/g;
  
  # -------------------------------------------------------
  # generate ports and connection in instantiation of main
  # -------------------------------------------------------
  #buffers for creating code for different parts of the template
  my $strMainConnections = "";
  my $numInputStreams = 0;
  my $numOutputStreams = 0;
  #my $b_concatOutputs   = "";
  #my $b_localOutputWires= "";
  my $iStreamCount = 0;
  my $oStreamCount = 0;
  
  #find total number of input streams, needed for countdown in next loop
  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
      my $dir =$main::CODE{main}{allocaports}{$key}{dir};
      $iStreamCount = $iStreamCount+1 if($dir eq 'input');
      $oStreamCount = $oStreamCount+1 if($dir eq 'output');
  }
  $numInputStreams  = $iStreamCount;
  $numOutputStreams = $oStreamCount;

  
  #top tytra-HDL modules' code for sdx interface does not change for different vectors 
  #(only the data width parameter is passed down 
  #if($ioVect==1){
    #start the countup counter (we make connections in LITTLE ENDIAN fashion)
    $iStreamCount = 0; 
    $oStreamCount = 0;
    
    #make connections for each input/output port
    #(how am I making correct connections are being made here? Because testbench also loops through
    # alloca ports (in the same sequence), and hence packs and unpacks in the same sequence)
    foreach my $key (keys %{$main::CODE{main}{allocaports}}){
      my $name=$key;
      my $dir =$main::CODE{main}{allocaports}{$name}{dir};
      if ($main::coalIOs) {
        my $ihi = ($iStreamCount+1)*$dataw*$ioVect-1;
        my $ilo = ($iStreamCount  )*$dataw*$ioVect  ;
        my $ohi = ($oStreamCount+1)*$dataw*$ioVect-1;
        my $olo = ($oStreamCount  )*$dataw*$ioVect  ;
        #multiple input streams connect to packed array
        if($dir eq 'input') {
          $strMainConnections .= "  ,.$name"."  (s_tdata[$ihi:$ilo])\n";
          $iStreamCount       = $iStreamCount+1;
        }
        else {
          $strMainConnections .= "  ,.$name"."  (m_tdata[$ohi:$olo])\n";
          $oStreamCount       = $oStreamCount+1;
          #$strMainConnections = $strMainConnections."  ,.$name"."  (m_tdata)\n";
        }
      }
      
      #this is the base template, where each input has its OWN channel (and single output)
      #Does this need to be connected on incrementing count or decrementign count? (FIXME)
      else {
        if($dir eq 'input') {
          $strMainConnections .= "  ,.$name"."  (s_tdata[$iStreamCount])\n";
          $iStreamCount       = $iStreamCount+1;
        }
        else {
          $strMainConnections .= "  ,.$name"."  (m_tdata[$oStreamCount])\n";
          $oStreamCount       = $oStreamCount+1;
          #$strMainConnections = $strMainConnections."  ,.$name"."  (m_tdata)\n";
        }
      }
    }
  #}#if

  #$numInputStreams = $iStreamCount;
  
  ##vectorize ; todo later
  #-----------
  #else{
  #  #loop through vector elements
  #  for (my $v=0; $v<$ioVect; $v++) {  
  #    foreach my $key (keys %{$main::CODE{main}{allocaports}}){
  #      my $name=$key;
  #      my $dir =$main::CODE{main}{allocaports}{$name}{dir};
  #      
  #      #connection to child ports happens for each element of vector,
  #      #whether input or output
  #      $strInsts  = $strInsts.", .$name"."_v$v ($name"."_v$v)\n";
  #      
  #      #each input gets its own port for each vector-element
  #      if ($dir eq 'input') {
  #        $strPorts  = $strPorts."\n , $dir"." [STREAMW-1:0] $name"."_v$v";
  #      }
  #      #outputs vector elements get coalesced as AOCL-HDL allows one output
  #      #we need to coalesce as well
  #      else {
  #        #create local wires to connect child outputs
  #        #these would then be concatenated
  #        $b_localOutputWires = $b_localOutputWires."wire [STREAMW-1:0] $name"."_v$v;\n";
  #        
  #        
  #        if($v==0) {
  #          #also, create one (coalesced) parent output port for the entire vector
  #          $strPorts  = $strPorts."\n , $dir"." [(STREAMW*$ioVect)-1:0] $name";  
  #          $b_concatOutputs = "$name"."_v$v};\n";
  #        } 
  #        #initialize concatenation for $v = max-value (concatenate higher to lower)
  #        elsif($v==$ioVect-1) {
  #          $b_concatOutputs = "assign $name = {$name"."_v$v, ".$b_concatOutputs;
  #        }
  #        #terminate concatenation for lowest scalar $v==0
  #        #everything else in between
  #        else {
  #          $b_concatOutputs = "$name"."_v$v, ".$b_concatOutputs;
  #        }#else
  #      }#else
  #    }#foreach
  #  }#for
  #}#else
  
  $genCode  =~ s/<streamConnectionstoMain>/$strMainConnections/g;
  $genCode  =~ s/<numInputStreams>/$numInputStreams/g;
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
  
}  

# ============================================================================
# GENERATE top level Sdx RTL file
# ============================================================================

sub genSdxTopRtl {

  #which OCX gen template version?
  my $tv = $main::ocxTempVer; 
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$modName           #module_name
      ,$designName
      ,$outputOCLDir
      ,$ioVect
      ,$datat
      ,$dataw
      ) = @_; 

  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/sdx/$tv/src/hdl/krnl_vadd_rtl.v"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;
  
  
  $genCode =~ s/<module_name>/$modName/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;
  
  # ---------------------------------------
  # >>>> number of inputs and vectorization
  # (determines data bus width)
  # ---------------------------------------
  my $iStreamCount = 0;
  my $oStreamCount = 0;
  
  #find total number of input streams, needed for countdown in next loop
  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
      my $dir =$main::CODE{main}{allocaports}{$key}{dir};
      $iStreamCount = $iStreamCount+1 if($dir eq 'input');
      $oStreamCount = $oStreamCount+1 if($dir eq 'output');
  }  

  #width of coalesced AXI data (input and output constrained to be same width for now)
  #for NEW template, no longer needed
  #my $axiDataWidth = "($dataw*$iStreamCount*$ioVect) //word-size x num-input-sreams x vectorization factor";
  #$genCode =~ s/<axiDataWidth>/$axiDataWidth/g; #this is the main reason I meed tp generate the file
  #
  #my $lengthInBytes =  ($dataw/8) * $main::CODE{main}{bufsize};
  #$genCode =~ s/<lengthInBytes>/$lengthInBytes/g;
  
  $genCode =~ s/<ninputs>/$iStreamCount/g;
  $genCode =~ s/<globalVect>/$ioVect/g;
  

  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
  
} 

# ============================================================================
# GENERATE host.cpp
# ============================================================================

sub genHostCpp {
  #which OCX gen template version?
  my $tv = $main::ocxTempVer; 

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$designName
      ,$outputOCLDir
      ,$ioVect
      ,$datat
      ,$dataw
      ) = @_; 

  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);
  my $strBuf = ""; # temp string buffer used in code generation 

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/sdx/$tv/src/main.c"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<module_name>/main.c/g;
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;
    
  # -------------------------------------------------------
  # >>>>> VECTORIZATION
  # -------------------------------------------------------
  $genCode =~ s/<globalVect>/$ioVect/g; #this is the main reason I meed tp generate the file
  
  # -------------------------------------------------------
  # >>>>> SIZE, DATA TYPE
  # -------------------------------------------------------
  my $bufsize = $main::CODE{main}{bufsize};
  $genCode =~ s/<SIZE>/$bufsize/g;
  
  my $hostdtype = 'int';
  $hostdtype = 'float'   if ($datat eq 'float32');
  $genCode =~ s/<data_t>/$hostdtype/g;
   
  
  # -------------------------------------------------------
  # >>>>> Stuff to generate for each IO
  # -------------------------------------------------------
  #find total number of input streams, needed for countdown in next loop
  my $iStreamCount = 0;
  my $oStreamCount = 0;
  my $hostArraysForHostRunDeclare = '';
  my $init_host_input = '';
  my $init_val = "3.14+(j+i*jmax)+1"; #HARDWIRED init value
  my $init_dev_input  = '';
  my $init_dev_output = '';
  my $compareResultsCond = "      if (";
  my $compareResultsPrint  = "";
  my $compareResultsPrint2 = "";
  
  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
    my $dir =$main::CODE{main}{allocaports}{$key}{dir};
   
    #name of relevant array
    my $nameInHash="%".$key;
    my $nameOfMem;   
    #get name of mem
    if($dir eq 'input') {$nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{consumes}[0];}
    else                {$nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{produces}[0];}
    $nameOfMem=~s/\%//;

    
    #declare host arrays (for host run, and for device run), initialize data
    $hostArraysForHostRunDeclare .= "  data_t* $nameOfMem = (data_t*) malloc((sizeof (data_t))*DATA_SIZE);\n";
    # device input (output) array is a single one,  with all host input (output) arrays interleaved
    if($dir eq 'input') {
      $init_host_input.= "      $nameOfMem"."[i*jmax + j+w] = (data_t) $init_val;\n"; 
      $init_dev_input .= "      h_axi00_ptr0_input  [(j+i*jmax)*NINPUTS + ($iStreamCount*vect) + w]"
                      .  "= (data_t) $nameOfMem"."[i*jmax + j+w];\n";
    }
    else {
      $init_dev_output.= "      h_axi00_ptr0_output  [(j+i*jmax)*NOUTPUTS + ($oStreamCount*vect) + w]"
                      .  "= (data_t) 0; //$nameOfMem\n";
      $compareResultsCond  .= "\n         (h_axi00_ptr0_output[i*NOUTPUTS + ($oStreamCount*vect) + w]" 
                           .  "!= $nameOfMem"."[r*jmax + c+w]) ||";
      $compareResultsPrint .= "$nameOfMem"."(e,a)=(%f,%f); ";
      $compareResultsPrint2.="\n        , $nameOfMem"."[r*jmax + c+w], h_axi00_ptr0_output[i*NOUTPUTS + ($oStreamCount*vect) + w]";
    }
    
    
    #count IO streams
    $iStreamCount = $iStreamCount+1 if($dir eq 'input');
    $oStreamCount = $oStreamCount+1 if($dir eq 'output');
  }
  
  #cleanup strings that need closure
  $/ = '||'; #chomp will remove this
  chomp ($compareResultsCond);
  $compareResultsCond .= "\n         ){";
  
  $genCode =~ s/<ninputs>/$iStreamCount/g;
  $genCode =~ s/<hostArraysForHostRunDeclare>/$hostArraysForHostRunDeclare/g;
  $genCode =~ s/<init_host_input>/$init_host_input/g;
  $genCode =~ s/<init_dev_input>/$init_dev_input/g;
  $genCode =~ s/<init_dev_output>/$init_dev_output/g;
  $genCode =~ s/<compareResultsCond>/$compareResultsCond/g;
  $genCode =~ s/<compareResultsPrint>/$compareResultsPrint/g;
  $genCode =~ s/<compareResultsPrint2>/$compareResultsPrint2/g;
  
  # --------------------------------
  # >>>>> Host golden run
  # --------------------------------
  #picked up from a template, presumed to be available in the same folder as tirl file. 
  my $hostrun_filename = "hostrun.c";
  open (my $fh, '<', $hostrun_filename) or die "Could not open $hostrun_filename\n";
  my $hostrun_code = read_file ($fh);
  close $fh;
  $genCode =~ s/<hostRun4GoldenResults>/$hostrun_code/;
  

  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated host.cpp\n";  
  
} 


# ============================================================================
# GENERATE kernel.xml
# ============================================================================

sub genKernelXML {
  #which OCX gen template version?
  my $tv = $main::ocxTempVer; 
  my $timeStamp   = localtime(time);

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$designName
      ,$outputOCLDir
      ,$ioVect
      ,$datat
      ,$dataw
      ) = @_; 

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/sdx/$tv/src/kernel.xml"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<timeStamp>/$timeStamp/g;
  # ---------------------------------------
  # >>>> AXI (coalesced) data width, 
  # ---------------------------------------
  my $iStreamCount = 0;
  my $oStreamCount = 0;
  
  #find total number of input streams, needed for countdown in next loop
  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
      my $dir =$main::CODE{main}{allocaports}{$key}{dir};
      $iStreamCount = $iStreamCount+1 if($dir eq 'input');
      $oStreamCount = $oStreamCount+1 if($dir eq 'output');
  }  

  #width of coalesced AXI data (input and output constrained to be same width for now)
  my $axiDataWidth = $dataw*$iStreamCount*$ioVect;#word-size x num-input-sreams x vectorization factor";
  $genCode =~ s/<axiDataWidth>/$axiDataWidth/g; #this is the main reason I meed tp generate the file
  

  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated krenel.xml\n";  
  
} 
