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
# Target is AOCL
# =============================================================================                        

package OclCodeGen_aocl;
use strict;
use warnings;

#use Data::Dumper;
use File::Slurp;
use File::Copy qw(copy);
use List::Util qw(min max);
use Term::ANSIColor qw(:constants);
use bigint;

use Exporter qw( import );
our @EXPORT = qw( $genCoreComputePipe );

our $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};


# ============================================================================
# GENERATE HDL WRAPPER (Top level HDL meeting AOCL interface requirements)
# ============================================================================


sub genHdlWrapper {

  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$modName           #module_name
      ,$designName
      ,$outputOCLDir
      ,$ioVect
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
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/aocl/lib/hdl/template.func_hdl_top.v"; 
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
  # >>>>> dataw
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
    }
  }
  
  my $streamw;
  if($dataBase eq 'float')  {$streamw=$dataw+2;}
  else                      {$streamw=$dataw;}
  
  $genCode =~ s/<dataw>/$dataw/g;
  $genCode =~ s/<streamw>/$streamw/g;
  
  # -------------------------------------------------------
  # generate ports and connection in instantiation of main
  # -------------------------------------------------------
  #buffers for creating code for different parts of the template
  my $strPorts          = "";
  my $strInsts          = "";
  my $b_concatOutputs   = "";
  my $b_localOutputWires= "";
  
  if($ioVect==1){
    foreach my $key (keys %{$main::CODE{main}{allocaports}}){
      my $name=$key;
      my $dir =$main::CODE{main}{allocaports}{$name}{dir};
      #if($dir eq 'input') {
        $strPorts  = $strPorts."\n , $dir"." [STREAMW-1:0] $name";
        $strInsts  = $strInsts.", .$name"."  ($name)\n";
      #}
    }
  }
  
  ##vectorize
  #-----------
  else{
    #loop through vector elements
    for (my $v=0; $v<$ioVect; $v++) {  
      foreach my $key (keys %{$main::CODE{main}{allocaports}}){
        my $name=$key;
        my $dir =$main::CODE{main}{allocaports}{$name}{dir};
        
        #connection to child ports happens for each element of vector,
        #whether input or output
        $strInsts  = $strInsts.", .$name"."_v$v ($name"."_v$v)\n";
        
        #each input gets its own port for each vector-element
        if ($dir eq 'input') {
          $strPorts  = $strPorts."\n , $dir"." [STREAMW-1:0] $name"."_v$v";
        }
        #outputs vector elements get coalesced as AOCL-HDL allows one output
        #we need to coalesce as well
        else {
          #create local wires to connect child outputs
          #these would then be concatenated
          $b_localOutputWires = $b_localOutputWires."wire [STREAMW-1:0] $name"."_v$v;\n";
          
          
          if($v==0) {
            #also, create one (coalesced) parent output port for the entire vector
            $strPorts  = $strPorts."\n , $dir"." [(STREAMW*$ioVect)-1:0] $name";  
            $b_concatOutputs = "$name"."_v$v};\n";
          } 
          #initialize concatenation for $v = max-value (concatenate higher to lower)
          elsif($v==$ioVect-1) {
            $b_concatOutputs = "assign $name = {$name"."_v$v, ".$b_concatOutputs;
          }
          #terminate concatenation for lowest scalar $v==0
          #everything else in between
          else {
            $b_concatOutputs = "$name"."_v$v, ".$b_concatOutputs;
          }#else
        }#else
      }#foreach
    }#for
  }#else
  
  $genCode  =~ s/<childPortConnections>/$strInsts/g;
  $genCode  =~ s/<ports>/$strPorts/g;
  $genCode  =~ s/<concatOutputs>/$b_concatOutputs/;
  $genCode  =~ s/<localOutputWires>/$b_localOutputWires/;
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated module $modName\n";  
  
}  


# ============================================================================
# Generate Kernel file (HDL pipeline)
# ============================================================================
sub genKernelHdlPipe {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$designName
      ,$outputOCLDir
      ,$ioVect
      ) = @_; 

  my $dfgroup = 'main'; 
  my %hash        = %{$main::CODE{main}};  #the hash from parsed code for this pipe function
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/template.kernels.hdlPipe.cl"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;
  
  # -------------------------------------------------------
  # >>>>> dataw
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
    }
  }  
  
  # -------------------------------------------------------
  # data types
  # -------------------------------------------------------
  my $scalar_t;
  my $device_t;
  
  if($dataBase eq 'float') {
    $scalar_t = 'float';
    $device_t = 'float';
  }
  
  else {
    if($ioVect==1) {
      $device_t  = 'int'; 
    }
    else {
      $device_t  = "int$ioVect"; 
    }
  }
  
  
  # -------------------------------------------------------
  # generate ports and connection in instantiation of main
  # -------------------------------------------------------
  #buffers for creating code for different parts of the template
  my $b_globalmemoryargs    = "";
  my $b_gatherinputs        = "";
  my $b_inputargs2func_lib  = "";
  my $b_inputargs2aocKernel = "";
  my $b_kernelAocOnlyArgs   = "";
  my $b_aocKernel           = "";
  my $b_scFromVectIn        = "";
  
  my $count = 0; #to find first (and not use comma)

  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
    #name of streamign port
    my $name=$key;
    my $dir =$main::CODE{main}{allocaports}{$name}{dir};
    my $nameInHash="%".$name;
    
    #name of relevant memory object (global memory array)
    my $nameOfMem;   
    if($dir eq 'input'){
      $nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{consumes}[0];
      $nameOfMem=~s/\%//;
    }
    else{
      $nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{produces}[0];
      $nameOfMem=~s/\%//;
    }

    
    $b_globalmemoryargs = $b_globalmemoryargs."\t\t," if ($count>0);
    $b_globalmemoryargs = $b_globalmemoryargs
                        . "global device_t * restrict $nameOfMem\n";

                        
    if($dir eq 'input') {
      #gather inputs from global memory
      $b_gatherinputs = $b_gatherinputs
                      . "\t\tdevice_t $nameOfMem"."_val = $nameOfMem"."[lincount];\n";
                      
      #assign to scalar variables if applicable                      
      if($ioVect>1) {
        for(my $v=0 ; $v<$ioVect ; $v=$v+1) {
          my $hexCount=$v->as_hex;
          $hexCount=~s/0x//;
          
          print "hexCount = $hexCount\n";
          $b_scFromVectIn = $b_scFromVectIn
                          . "\t\tscalar_t $nameOfMem"."_val_v$v = $nameOfMem".  "_val.s$hexCount;\n" 
        }
      }              
                      
      if($ioVect==1) {
        $b_inputargs2func_lib = $b_inputargs2func_lib."\t\t\t," if ($count>0);
        $b_inputargs2func_lib = $b_inputargs2func_lib
                              . "$nameOfMem"."_val\n"; 
      }
      else {
        for(my $v=0 ; $v<$ioVect ; $v=$v+1) {
          $b_inputargs2func_lib = $b_inputargs2func_lib."\t\t\t," if ($count>0 || $v>0);
          $b_inputargs2func_lib = $b_inputargs2func_lib
                                . "$nameOfMem"."_val_v$v\n"; 
        }
      }
                            
      $b_inputargs2aocKernel = $b_inputargs2aocKernel."\t\t\t," if ($count>0);
      $b_inputargs2aocKernel = $b_inputargs2aocKernel
                            . "$nameOfMem\n"; 

      $b_kernelAocOnlyArgs = $b_kernelAocOnlyArgs."\t\t," if ($count>0);
      $b_kernelAocOnlyArgs = $b_kernelAocOnlyArgs
                        . "global device_t * restrict $nameOfMem\n";
                            
                                  
    }
    #assuming there will be only one output                      
    else {
      $genCode  =~ s/<output>/$nameOfMem/ if($dir eq 'output');
    }
   
   $count++;                       
  }
  
  # --------------------
  # latency and size
  # --------------------
  my $lat = $main::CODE{main}{performance}{lat};
  my $size = $main::CODE{main}{bufsize};
  
  # --------------------
  # aocl only kernel
  # --------------------
  #Ifdef CPUBASELINE, then generate cpu baseline code
  if($main::lambda) {
    $b_aocKernel = $main::lambdaTxt;
  }  
  # --------------------
  # replace tags
  # --------------------
  $genCode =~ s/<deviceDataType>/$device_t/g;
  $genCode =~ s/<scalarDataType>/$scalar_t/g;
  $genCode  =~ s/<globalmemoryargs>/$b_globalmemoryargs/;
  $genCode  =~ s/<gatherinputs>/$b_gatherinputs/;
  $genCode  =~ s/<scFromVectIn>/$b_scFromVectIn/;
  $genCode  =~ s/<inputargs2func_lib>/$b_inputargs2func_lib/g;
  $genCode  =~ s/<inputargs2aocKernel>/$b_inputargs2aocKernel/g;
  $genCode  =~ s/<latency>/$lat/;
  $genCode =~ s/<size>/$size/g;
  $genCode =~ s/<kernelAocOnlyArgs>/$b_kernelAocOnlyArgs/g;
  $genCode =~ s/<aocKernel>/$b_aocKernel/g;
  $genCode =~ s/<ioVect>/$ioVect/g;
  
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated kernels.cl\n";  
  
}

# ============================================================================
# Generate Kernel file (OCL pipeline)
# ============================================================================
sub genKernelOclPipe {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$designName
      ,$outputOCLDir
      ,$ioVect
      ) = @_; 

  my $dfgroup = 'main'; 
  my %hash        = %{$main::CODE{main}};  #the hash from parsed code for this pipe function
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/ocl/template.kernels.oclPipe.cl"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;
  
  # -------------------------------------------------------
  # >>>>> dataw
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
    }
  }  
  
  # -------------------------------------------------------
  # data types
  # -------------------------------------------------------
  my $scalar_t;
  my $device_t;
  
  if($dataBase eq 'float') {
    $scalar_t = 'float';
    $device_t = 'float';
  }
  
  else {
    if($ioVect==1) {
      $device_t  = 'int'; 
    }
    else {
      $device_t  = "int$ioVect"; 
    }
  }

  #buffers for creating code for different parts of the template
  # -------------------------------------------------------
#  my $b_globalmemoryargs    = "";
#  my $b_gatherinputs        = "";
#  my $b_inputargs2func_lib  = "";
#  my $b_inputargs2aocKernel = "";
#  my $b_kernelAocOnlyArgs   = "";
#  my $b_scFromVectIn        = "";

  my $b_aocKernel            = '';
  my $b_globalInputsIOKernel = '';
  my $b_globalOutputsIOKernel= '';
  my $b_readGlobalArrays     = '';
  my $b_writeGlobalArrays    = '';
  my $b_declareChannels      = '';
  my $b_wChannelDataInKernel = '';
  my $b_rChannelDataOutKernel= '';
  my $b_computeKernelsAll    = '';
 
  # -------------------------------------------------------
  # generate IO kernels
  # -------------------------------------------------------  
  my $count = 0; #to find first (and not use comma)
  
  #locate top kernel
  my $topKernel = $main::CODE{main}{topKernelName};
  my $topKernelKeyinMain = $topKernel.".0"; #since only one kernel in main, so...
  
  #loop through all args to top kernel, as that forms the basis of arguments the data_in/out kernels
  #their channels, and their content (reading and writing from global memories as well as their channels)
  #-------------------------------
  foreach my $args2ChildKey (keys %{$main::CODE{main}{symbols}{$topKernelKeyinMain}{args2child}}) {
    my $argDir  = $main::CODE{main}{symbols}{$topKernelKeyinMain}{args2child}{$args2ChildKey}{dir};
    #name of connection to use in the topKernel (channel should have same name)
    my $connectName = $main::CODE{main}{symbols}{$topKernelKeyinMain}{args2child}{$args2ChildKey}{nameChildPort};
    $connectName =~ s/\%//;
    
    #name of stream feeding the argument/port
    my $nameStreamParent = $main::CODE{main}{symbols}{$topKernelKeyinMain}{args2child}{$args2ChildKey}{name};
   
    #name of memory (global memory array) feeding/consuming the stream
    my $nameOfMem;
    
    ## input ##
    if ($argDir eq 'input') {
      #what's the name of global memory array for this argument?
      $nameOfMem = $main::CODE{main}{symbols}{$nameStreamParent}{consumes}[0];
      $nameOfMem =~ s/\%//;
    
      #create arguments to the kernel
      $b_globalInputsIOKernel = $b_globalInputsIOKernel."\t\t," if ($count>0);
      $b_globalInputsIOKernel = $b_globalInputsIOKernel
                            . "global device_t * restrict $nameOfMem\n";
    
      #gather inputs from global memory
      $b_readGlobalArrays = $b_readGlobalArrays
                      . "\t\tdevice_t $nameOfMem"."_val = $nameOfMem"."[lincount];\n";
      
      #declare input channels
      $b_declareChannels  = $b_declareChannels
                          . "channel device_t  ch_$connectName ;\n";
                          
      #write to channels
      $b_wChannelDataInKernel = $b_wChannelDataInKernel
                            . "\t\twrite_channel_altera(ch_$connectName, $nameOfMem"."_val);"  
                            . "mem_fence(CLK_CHANNEL_MEM_FENCE);\n";                                     
                          
    }#if
    
    ## output ##
    else {
      #what's the name of global memory array for this argument?
      $nameOfMem = $main::CODE{main}{symbols}{$nameStreamParent}{produces}[0];
      $nameOfMem =~ s/\%//;
      
      #create arguments to the kernel
      $b_globalOutputsIOKernel = $b_globalOutputsIOKernel
                              . "global device_t * restrict $nameOfMem\n";
      
      #read from  channels
      $b_rChannelDataOutKernel  = $b_rChannelDataOutKernel
                                . "\t\tdevice_t $nameOfMem"."_val = read_channel_altera(ch_$nameOfMem);  "
                                . "mem_fence(CLK_CHANNEL_MEM_FENCE);\n";
                                
      #write read values to global kernel
      $b_writeGlobalArrays = $b_writeGlobalArrays
                          . "\t\t$nameOfMem"."[lincount] = $nameOfMem"."_val;\n";                          
    }
  }#foreach
  
  # ---------------------------------------------------------------------
  # generate other Kernels (top-level kernels that form the OCL pipeline
  # ---------------------------------------------------------------------
      
  #loop through each symbol in top kernel, find function call instructions    
  #------------------------------------------------------------------------
  foreach my $kernelKey (keys %{$main::CODE{$topKernel}{symbols}}) {
    if($main::CODE{$topKernel}{symbols}{$kernelKey}{cat} eq 'funcall') {
      my $kernelName = $main::CODE{$topKernel}{symbols}{$kernelKey}{funcName};
      
      #read in template (designed to define a shell for HDL kernel in a CG OCL pipeline)
      my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/ocl/template.OneKernelInOclPipeline.cl"; 
      open (my $fhTemplate, '<', $templateFileName)
        or die "Could not open file '$templateFileName' $!";    
      my $b_computeKernelsThis = read_file ($fhTemplate);
      close $fhTemplate;      
                 
      #update code in the template     
      #iterate through all ports/args of function call (to kernel), identify inputs/outputs
      #------------------------------------------------------------------------------------
      
      my $b_gatherinputs = '';
      
      foreach my $args2ChildKey (keys %{$main::CODE{$topKernel}{symbols}{$kernelKey}{args2child}}) {
        #find the name of the connetion in the parent kernel
        my $connectName = $main::CODE{$topKernel}{symbols}{$kernelKey}{args2child}{$args2ChildKey}{name};
        $connectName =~ s/\%//;
        
        #find the name and dir of the argument the (child) kernel definition
        my $argName = $main::CODE{$topKernel}{symbols}{$kernelKey}{args2child}{$args2ChildKey}{nameChildPort};
        $argName =~ s/\%//;
        my $argDir  = $main::CODE{$topKernel}{symbols}{$kernelKey}{args2child}{$args2ChildKey}{dir};

        #declare a channel for every output argument
        if($argDir eq 'output') {
          $b_declareChannels  = $b_declareChannels
                              . "channel device_t  ch_$connectName ;\n";        
        }
        
        #gather inputs from channels
        if($argDir eq 'input') {
          $b_gatherinputs = $b_gatherinputs
                          . "\t\tdevice_t $argName"."_val = read_channel_altera(ch_$connectName);\n"; 
        } 
      }
      
      #update tags, and append to global string that is accumulated for all kernels
      $b_computeKernelsThis =~ s/<kernelArgs>//;
      $b_computeKernelsThis =~ s/<kernelName>/$kernelName/g;
      $b_computeKernelsThis =~ s/<gatherinputs>/$b_gatherinputs/;
      $b_computeKernelsThis =~ s/<scFromVectIn>//;
      
      
      $b_computeKernelsAll = $b_computeKernelsAll.$b_computeKernelsThis;
    }#if
  }#foreach
  
  
  
  
  # --------------------
  # latency and size
  # --------------------
  my $lat = $main::CODE{main}{performance}{lat};
  my $size = $main::CODE{main}{bufsize};
  
  # --------------------
  # aocl only kernel
  # --------------------
  #Ifdef CPUBASELINE, then generate cpu baseline code
  if($main::lambda) {
    $b_aocKernel = $main::lambdaTxt;
  }  
  # --------------------
  # replace tags
  # --------------------
  $genCode =~ s/<deviceDataType>/$device_t/g;
  $genCode =~ s/<scalarDataType>/$scalar_t/g;
  $genCode  =~ s/<latency>/$lat/;
  $genCode =~ s/<size>/$size/g;
  $genCode =~ s/<globalInputsIOKernel>/$b_globalInputsIOKernel/;
  $genCode =~ s/<globalOutputsIOKernel>/$b_globalOutputsIOKernel/; 
  $genCode =~ s/<readGlobalArrays>/$b_readGlobalArrays/;      
  $genCode =~ s/<writeGlobalArrays>/$b_writeGlobalArrays/;     
  $genCode =~ s/<declareChannels>/$b_declareChannels/;     
  $genCode =~ s/<wChannelDataInKernel>/$b_wChannelDataInKernel/;     
  $genCode =~ s/<rChannelDataOutKernel>/$b_rChannelDataOutKernel/;
  $genCode =~ s/<computeKernelsAll>/$b_computeKernelsAll/;
  #$genCode  =~ s/<globalmemoryargs>/$b_globalmemoryargs/;
  #$genCode  =~ s/<gatherinputs>/$b_gatherinputs/;
  #$genCode  =~ s/<scFromVectIn>/$b_scFromVectIn/;
  #$genCode  =~ s/<inputargs2func_lib>/$b_inputargs2func_lib/g;
  #$genCode  =~ s/<inputargs2aocKernel>/$b_inputargs2aocKernel/g;
  #$genCode =~ s/<kernelAocOnlyArgs>/$b_kernelAocOnlyArgs/g;
  #$genCode =~ s/<aocKernel>/$b_aocKernel/g;
  #$genCode =~ s/<ioVect>/$ioVect/g;
  
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated kernels.cl\n";  
  
}

# ============================================================================
# Generate XML
# ============================================================================
sub genXML {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$designName
      ,$outputOCLDir
      ,$outputRTLDir
      ,$ioVect
      ) = @_; 

  my $dfgroup = 'main'; 
  my %hash        = %{$main::CODE{main}};  #the hash from parsed code for this pipe function
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/aocl/lib/template.hdl_lib.xml"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------------
  # >>>>> Update header and module name 
  # --------------------------------------
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;
  
  # -------------------------------------------------------
  # data width
  # -------------------------------------------------------
  my $dataw    = 32; #TODO:: This is hardwired for now
  my $datawOut = 32*$ioVect;
  # -------------------------------------------------------
  # set latency
  # -------------------------------------------------------
  my $lat = $main::CODE{main}{performance}{lat};
  ##NOTE: Overwritten to 1 in the code, as that is how
  # I am able to get correct functionality
  $lat=1;
  $genCode =~ s/\[latency\]/$lat/;

  
  # -------------------------------------------------------
  # generate ports 
  # -------------------------------------------------------
  #buffers for creating code for different parts of the template
  my $b_ports    = "";
  my $b_files    = "";

  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
    my $name=$key;
    my $dir =$main::CODE{main}{allocaports}{$name}{dir};
    my $dirtxt;
    
    if ($dir eq 'output') {
      $dirtxt = 'OUTPUT';
      $b_ports = $b_ports
              . "      <$dirtxt  port=\"$name\" width=\"$datawOut\"/>\n";
    }
    else {
      $dirtxt = 'INPUT';
      if($ioVect==1) {
        $b_ports = $b_ports
                . "      <$dirtxt  port=\"$name\" width=\"$dataw\"/>\n";
      }
      else {
        for(my $v=0 ; $v<$ioVect ; $v=$v+1) {
          $b_ports = $b_ports
                  . "      <$dirtxt  port=\"$name"."_v$v\" width=\"$dataw\"/>\n";
        }
      }
    }
  }

  $genCode  =~ s/\[setPorts\]/$b_ports/;
  $b_ports    = "";
  
  # --------------------------------------------------
  # List HDL files (available in the hdl directory)
  # --------------------------------------------------  
  opendir(my $direc, $outputRTLDir) || die "Can't open $outputRTLDir: $!";
  while (readdir $direc) {
    #hack to exclude spFloatHelpers.v 
    if($_ ne 'spFloatHelpers.v') {
      $b_files = $b_files."      <FILE name=\"hdl/$_\" />\n" 
        if(($_ =~ /\.v$/i)||($_ =~ /\.vhd$/i)); #only list .v/.vhd files
    }
  }
  closedir $direc;    
  $genCode  =~ s/\[includeHdlFiles\]/$b_files/;
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated hdl_lib.xml\n";  
  
}

# ============================================================================
# Generate c_model.cl
# ============================================================================
sub genCModelAndHdlLibH {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen_c             #file handler for output file
      ,$fhGen_h
      ,$designName
      ,$outputOCLDir
      ,$ioVect
      ) = @_; 

  my $dfgroup = 'main'; 
  my %hash        = %{$main::CODE{main}};  #the hash from parsed code for this pipe function
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);

  # ---------------------------------------
  # >>>> Load template files, read contents
  # ---------------------------------------
  my $templateFileName_c = "$TyBECROOTDIR/oclGenTemplates/aocl/lib/template.c_model.cl"; 
  my $templateFileName_h  = "$TyBECROOTDIR/oclGenTemplates/aocl/lib/template.hdl_lib.h"; 
  open (my $fhTemplate_c, '<', $templateFileName_c)
    or die "Could not open file '$templateFileName_c' $!"; 
  open (my $fhTemplate_h, '<', $templateFileName_h)
    or die "Could not open file '$templateFileName_h' $!"; 

  my $genCode_c = read_file ($fhTemplate_c);
  my $genCode_h = read_file ($fhTemplate_h);
  close $fhTemplate_c;
  close $fhTemplate_h;

  # --------------------------------------
  # >>>>> Update header and module name 
  # --------------------------------------
  $genCode_c =~ s/<design_name>/$designName/g;
  $genCode_c =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode_h =~ s/<design_name>/$designName/g;
  $genCode_h =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode_h =~ s/<timeStamp>/$timeStamp/g;
  
  # -------------------------------------------------------
  # data type
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
    }
  }    
  
  my $data_t;
  if($dataBase eq 'float')  {$data_t = 'float';}  
  else                      {$data_t = 'int';  }
  
  if($ioVect==1) {
    my $return_t = $data_t; 
    $genCode_h =~ s/<return_t>/$return_t/g;
    $genCode_c =~ s/<return_t>/$return_t/g;
  }
  else {
    my $return_t = $data_t.$ioVect; 
    $genCode_h =~ s/<return_t>/$return_t/g;
    $genCode_c =~ s/<return_t>/$return_t/g;
  }

  # -------------------------------------------------------
  # generate ports 
  # -------------------------------------------------------
  #buffers for creating code for different parts of the template
  my $b_inputs    = "";
  my $count = 0; #to find first (and not use comma)

  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
    my $name = $key;
    my $dir  = $main::CODE{main}{allocaports}{$name}{dir};
    if($dir eq 'input') {
      if($ioVect==1){   
        $b_inputs = $b_inputs."," if ($count>0);
        $b_inputs = $b_inputs
                  ."$data_t $name\n";
      }
      
      else {
        for(my $v=0 ; $v<$ioVect ; $v=$v+1) {
          $b_inputs = $b_inputs."," if ($count>0 || $v>0);
          $b_inputs = $b_inputs
                    ."$data_t $name"."_v$v\n";
        }
      }
      $count++;
    }
  }

  $genCode_c  =~ s/<inputArguments>/$b_inputs/;
  $genCode_h  =~ s/<inputArguments>/$b_inputs/;
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode_c =~ s/\r//g; #to remove the ^M  
  $genCode_h =~ s/\r//g; #to remove the ^M  
  print $fhGen_c $genCode_c;
  print $fhGen_h $genCode_h;
  
  print "TyBEC: Generated c_model.cl\n";  
  print "TyBEC: Generated hdl_lib.h\n";  
}


# ============================================================================
# Generate main.cpp
# ============================================================================
sub genMainCpp {
  # --------------------------------
  # >>> ARGS
  # --------------------------------
  my  ($fhGen             #file handler for output file
      ,$designName
      ,$outputOCLDir
      ) = @_; 

  my $dfgroup = 'main'; 
  my %hash        = %{$main::CODE{main}};  #the hash from parsed code for this pipe function
  
  # --------------------------------
  # >>>>> Locals
  # --------------------------------
  my $timeStamp   = localtime(time);

  # ---------------------------------------
  # >>>> Load template file, read contents
  # ---------------------------------------
  my $templateFileName = "$TyBECROOTDIR/oclGenTemplates/host/src/template.main.cpp"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "Could not open file '$templateFileName' $!"; 

  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  # --------------------------------
  # >>>>> Update header and module name 
  # --------------------------------
  $genCode =~ s/<design_name>/$designName/g;
  $genCode =~ s/<gen_ver>/$main::tybecRelease/g;
  $genCode =~ s/<timeStamp>/$timeStamp/g;
  
  # -------------------------------------------------------
  # >>>>> device_t
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
    }
  }      
  
  my $host_t  ;
  my $device_t;
  
  if($dataBase eq 'float')  {$host_t = 'float';}  
  else                      {$host_t = 'int';  }
  
  $device_t = $host_t;
  
  $genCode =~ s/<hosttype>/$host_t/g;
  $genCode =~ s/<devicetype>/$device_t/g;

  # -------------------------------------------------------
  # >>>>> bufsize
  # -------------------------------------------------------
  my $bufsize = $main::CODE{main}{bufsize};
  $genCode =~ s/<bufsize>/$bufsize/g;

  
  # -------------------------------------------------------
  # generate ports and connection in instantiation of main
  # -------------------------------------------------------
  #buffers for creating code for different parts of the template
  my $b_hstInputArrays    = "";
  my $b_devInputArrays    = "";
  my $b_clInputBuffers    = "";
  my $b_allocHostMem      = "";
  my $b_checkHostAlloc    = "";
  my $b_genInputData      = "";
  my $b_setKernelArgs     = "";
  my $b_enqWriteBuff      = "";
  my $b_relDevBuf         = "";
  my $b_relHostBuf        = "";
  my $b_isCpuBaselineAv   = "";
  my $b_passArgs2Init     = "";
  my $b_passArgs2cpuKernel= "";
  my $b_initArgsSignature = "";
  my $b_cpuKernelArgs     = "";
  my $b_copyInputData     = "";
  my $b_cpuKernel         = "";
  my $b_decCpuArrays      = "";
  my $b_pt                = '10d';#default printf type
  
     $b_pt = 'f' if($dataBase eq 'float');

  my $count = 0; #to find first (and not use comma)

  #looping though all alloca ports (ref to array in main memory)  
  foreach my $key (keys %{$main::CODE{main}{allocaports}}){
    #name of streamign port
    my $name=$key;
    my $dir =$main::CODE{main}{allocaports}{$name}{dir};
    my $nameInHash="%".$name;
    
    #name of relevant memory object (global memory array)
    my $nameOfMem;   
    if($dir eq 'input'){
      $nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{consumes}[0];
      $nameOfMem=~s/\%//;
    }
    else{
      $nameOfMem=$main::CODE{main}{symbols}{$nameInHash}{produces}[0];
      $nameOfMem=~s/\%//;
    }
  
    #both input or output
    
    $b_passArgs2cpuKernel = $b_passArgs2cpuKernel."\t\t," if ($count>0);
    $b_passArgs2cpuKernel = $b_passArgs2cpuKernel
                          . "cpu_$nameOfMem\n";
                             
    $b_cpuKernelArgs = $b_cpuKernelArgs."\t\t," if ($count>0);
    $b_cpuKernelArgs = $b_cpuKernelArgs
                     . "device_t $nameOfMem"."[SIZE]\n";
                                 
    $b_decCpuArrays = $b_decCpuArrays
                     . "\tstatic device_t cpu_$nameOfMem"."[SIZE];\n";
    
    #input-only relevant
    if($dir eq 'input') {
      $b_initArgsSignature = $b_initArgsSignature."\t\t," if ($count>0);
      $b_initArgsSignature = $b_initArgsSignature
                           . "device_t cpu_$nameOfMem"."[SIZE]\n";
      $b_passArgs2Init = $b_passArgs2Init."\t\t\t\t," if ($count>0);
      $b_passArgs2Init = $b_passArgs2Init
                          . "cpu_$nameOfMem\n";
      $b_hstInputArrays = $b_hstInputArrays
                        . "  host_t *host_$nameOfMem = 0;\n";
      $b_devInputArrays = $b_devInputArrays
                        . "  cl_mem cl_$nameOfMem = 0;\n";
      $b_clInputBuffers = $b_clInputBuffers
                        ."  cl_$nameOfMem = clCreateBuffer(context,CL_MEM_READ_WRITE,SIZE*sizeof(device_t),0,&status);"
                        ." CHECK(status);\n";
      $b_allocHostMem   = $b_allocHostMem
                        ."  host_$nameOfMem = (host_t *) acl_aligned_malloc(SIZE*sizeof(host_t));\n";
      $b_checkHostAlloc = $b_checkHostAlloc." ||" if ($count>0);
      $b_checkHostAlloc = $b_checkHostAlloc
                        ."(host_$nameOfMem == NULL)";

      if($dataBase eq 'float') {
        $b_genInputData   = $b_genInputData
                          ."\t\tcpu_$nameOfMem\[i\] = 3.14+i+1;\n";
      } 
      else {
        $b_genInputData   = $b_genInputData
                          ."\t\tcpu_$nameOfMem\[i\] = i+1;\n";
      }
      
      $b_copyInputData   = $b_copyInputData
                        ."    host_$nameOfMem\[i\] = cpu_$nameOfMem\[i\];\n";                        
      $b_setKernelArgs  = $b_setKernelArgs
                        . "  CHECK( clSetKernelArg(kernel,$count,sizeof(cl_mem),&cl_$nameOfMem) );\n";
      $b_enqWriteBuff   = $b_enqWriteBuff
                        . "  CHECK( clEnqueueWriteBuffer(cq,cl_$nameOfMem,0,0,SIZE*sizeof(device_t),host_$nameOfMem,0,0,0) );\n";
      $b_relDevBuf      = $b_relDevBuf
                        . "  clReleaseMemObject(cl_$nameOfMem);\n";
      $b_relHostBuf     = $b_relHostBuf
                        . "  free(host_$nameOfMem);\n";
    }
    
    #output-only
    #Since there will always be only one output, we can hardwire the name
    else {
      $b_setKernelArgs  = $b_setKernelArgs
                        . "  CHECK( clSetKernelArg(kernel,$count,sizeof(cl_mem),&cl_vout) );\n";
    }
   $count++;                       
  }
  #Once all ports are done, we need to set the "N" argument as well
  #$b_setKernelArgs  = $b_setKernelArgs
  #                  . "CHECK( clSetKernelArg(kernel_lib,$count,sizeof(cl_int),&N) );\n";
 
  
  #Ifdef CPUBASELINE, then generate cpu baseline code
  if($main::lambda) {
    $b_isCpuBaselineAv = "#define CPUBASELINE" ;
    $b_cpuKernel = $main::lambdaTxt;
  }

 
  $genCode  =~ s/<isCpuBaselineAvailable>/$b_isCpuBaselineAv/;
  $genCode  =~ s/<declareHostInputArrays>/$b_hstInputArrays/;
  $genCode  =~ s/<declareDeviceInputArrays>/$b_devInputArrays/;
  $genCode  =~ s/<createClInputBuffers>/$b_clInputBuffers/;
  $genCode  =~ s/<allocateHostInputMemory>/$b_allocHostMem/;
  $genCode  =~ s/<checkAllocateHostInputMemory>/$b_checkHostAlloc/;
  $genCode  =~ s/<generateInputData>/$b_genInputData/;
  $genCode  =~ s/<setAllKernelArguments>/$b_setKernelArgs/;
  $genCode  =~ s/<enqueueDeviceInputBuffers>/$b_enqWriteBuff/;
  $genCode  =~ s/<releaseClInputBuffers>/$b_relDevBuf/;
  $genCode  =~ s/<freeHostInputBuffers>/$b_relHostBuf/;
  $genCode  =~ s/<passArgs2Init>/$b_passArgs2Init/;
  $genCode  =~ s/<passArgs2cpuKernel>/$b_passArgs2cpuKernel/;
  $genCode  =~ s/<initArgsSignature>/$b_initArgsSignature/g;
  $genCode  =~ s/<cpuKernelArgs>/$b_cpuKernelArgs/g;
  $genCode  =~ s/<copyInputData>/$b_copyInputData/;
  $genCode  =~ s/<cpuKernel>/$b_cpuKernel/;
  $genCode  =~ s/<decCpuArrays>/$b_decCpuArrays/;
  $genCode  =~ s/<pt>/$b_pt/g;
  
  # --------------------------------
  # >>>>> Write to file
  # --------------------------------
  $genCode =~ s/\r//g; #to remove the ^M  
  print $fhGen $genCode;
  
  print "TyBEC: Generated main.cpp\n";  
  
}

