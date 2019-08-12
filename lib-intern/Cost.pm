package Cost;
use strict;
use warnings;
use Data::Dumper;

use Exporter qw( import );
our @EXPORT = qw( %costI %costC costMem);

# Simple functional interface
use Text::CSV::Hashify;

# ============================================================================
# Utility routines
# ============================================================================

sub log2 {
        my $n = shift;
        return int( (log($n)/log(2)) + 0.99); #0.99 for CEIL operation
    }

# all costs are for the StratiX V device on Nallatech board
# all costs with Latency >0 include pipeline regusters' cost

# ========================================================================
# ************************************************************************
# COST OF INSTRUCTIONS
# ************************************************************************
# ========================================================================
our %costI;
our $targetBoard;

# ========================================================================
# IO
# ========================================================================
sub costInit {
  my  ($hash) = @_;
     
  #initialize performance paramters  
  #At this point I dont know the direction
  $hash->{performance}{afi}=-1; #unknown
  $hash->{performance}{efi}=-1; #unknown
  
  $hash->{performance}{sd }=-1;
  $hash->{performance}{lat}= 0;#by default I should have 0 latency (e.g. input arguments)
  $hash->{performance}{lfi}=1; #1 for integer output(and always 1 for input)
  $hash->{performance}{fpo}=1; #1 for integer output(and always 1 for input)

  #intialize resource parameters
  $hash->{resource}{aluts    } = 0;
  $hash->{resource}{regs     } = 0;
  $hash->{resource}{dsps     } = 0;
  $hash->{resource}{propDelay} = 0;    
  $hash->{resource}{bram}      = 0;    
}#()

# ========================================================================
# Functions and Function-Call Instructions
# ========================================================================

#----------------------------------------
sub costFunction {
#----------------------------------------
  my $func   = shift(@_);
  my $hash = $main::CODE{$func}; 

  $hash->{resource}{regs}     = 0;
  $hash->{resource}{dsps}     = 0;
  $hash->{resource}{aluts}    = 0;
  $hash->{resource}{bram}     = 0;
  $hash->{resource}{propDelay}= 0;

  #default to 1 to avoid divide by 0 error (required for main only
  $hash->{resource}{bram}     = 1 if($func eq 'main');
  $hash->{resource}{dsps}     = 1 if($func eq 'main');
  
  #my $instrinsic =(  ($func eq 'pow')
  #                || ($func eq 'cos')
  #                || ($func eq 'sin')
  #                );
  #my $intrinsic = 0;
  
  #instrinsic functions map to opaque (typically 3rd party) functions
  #(e.g. FP units from flopoco), so are dealt with differently than
  #normal IR-based hierarchical functions
  
  #if($intrinsic){;}
#  if($intrinsic) {
#    if($func eq 'pow') {
#      #see <>\TyBEC\hdlCoresTparty\flopoco\README.txt
#      $hash->{resource}{regs} += 1260;
#      $hash->{resource}{dsps} += 0; 
#      $hash->{resource}{aluts}+= 1828 ; 
#      $hash->{resource}{bram} += 0;
#      $hash->{resource}{propDelay} = 3;
#      $hash->{ninputs}  = 2;
#      $hash->{noutputs} = 1;
#    }  
#  }
#  else {
    # ------------------------------------------------
    # iterate through all symbols 
    # accumulate/update overall cost for the function
    # ------------------------------------------------   
    foreach my $key ( keys %{$hash->{symbols}} ) {
      #accumulate resources
  #    print "accumulating cost for $func, $key\n";
      $hash->{resource}{regs} += $hash->{symbols}{$key}{resource}{regs} ;
      $hash->{resource}{dsps} += $hash->{symbols}{$key}{resource}{dsps} ; 
      $hash->{resource}{aluts}+= $hash->{symbols}{$key}{resource}{aluts}; 
      $hash->{resource}{bram} += $hash->{symbols}{$key}{resource}{bram}; 
      
      #propDelay is the maximum value
      $hash->{resource}{propDelay} = 
        TirGrammarMod::mymax ( $hash->{resource}{propDelay} 
                             , $hash->{symbols}{$key}{resource}{propDelay} ); 
                             
      #I need the total number of inputs and outputs for functions
      if (($hash->{symbols}{$key}{cat} eq 'arg') && ($hash->{symbols}{$key}{dir} eq 'input')) {
        $hash->{ninputs} = $hash->{ninputs} + 1;
      }
      elsif(($hash->{symbols}{$key}{cat} eq 'arg') && ($hash->{symbols}{$key}{dir} eq 'output')) {
        $hash->{noutputs} = $hash->{noutputs} + 1;
      }
      elsif($hash->{symbols}{$key}{cat} eq 'func-arg') {
        $hash->{noutputs} = $hash->{noutputs} + 1;
      }
    }#foreach   
 # }#else

}

#----------------------------------------
sub costFuncCallInstruction {
#----------------------------------------
  my $caller   = shift(@_);
  my $calleeWC = shift(@_);
  my $hash     = $main::CODE{$caller}{symbols}{$calleeWC};
  my $callee   = $hash->{funcName};
  
  #print "::costFuncCallInstruction:: inside main, $caller, $callee, $calleeWC\n" if ($caller eq 'main');
  
  # get initialized performance and resource parameters from hash of child function
  my $afi = $main::CODE{$callee}{performance}{afi};
  my $efi = $main::CODE{$callee}{performance}{efi};
  my $sd  = $main::CODE{$callee}{performance}{sd };
  my $lat = $main::CODE{$callee}{performance}{lat};
  my $lfi = $main::CODE{$callee}{performance}{lfi};
  my $fpo = $main::CODE{$callee}{performance}{fpo};
  
  my $dsps      = $main::CODE{$callee}{resource}{dsps     };
  my $propDelay = $main::CODE{$callee}{resource}{propDelay};
  my $regs      = $main::CODE{$callee}{resource}{regs     };
  my $aluts     = $main::CODE{$callee}{resource}{aluts    };
  my $bram      = $main::CODE{$callee}{resource}{bram     };
  
  TirGrammarMod::setCostValue($caller,$calleeWC,'performance','afi',$afi);
  TirGrammarMod::setCostValue($caller,$calleeWC,'performance','efi',$efi);
  TirGrammarMod::setCostValue($caller,$calleeWC,'performance','sd' ,$sd );
  TirGrammarMod::setCostValue($caller,$calleeWC,'performance','lat',$lat);
  TirGrammarMod::setCostValue($caller,$calleeWC,'performance','lfi',$lfi);
  TirGrammarMod::setCostValue($caller,$calleeWC,'performance','fpo',$fpo);
  #
  TirGrammarMod::setCostValue($caller,$calleeWC,'resource','dsps'      ,$dsps     );
  TirGrammarMod::setCostValue($caller,$calleeWC,'resource','propDelay' ,$propDelay);
  TirGrammarMod::setCostValue($caller,$calleeWC,'resource','regs'      ,$regs     );
  TirGrammarMod::setCostValue($caller,$calleeWC,'resource','aluts'     ,$aluts    );
  TirGrammarMod::setCostValue($caller,$calleeWC,'resource','bram'      ,$bram     );
}#()



#-----------------------------------
sub costFifoBuffers {
#-----------------------------------
  my  (  $func
      ,  $bufkey
      ,  $buff_size
      ,  $bufferSizeBits ) = @_;

  my $hash     = $main::CODE{$func}{symbols}{$bufkey}; 
      
  #initialize performance paramters
  Cost::costInit($hash);
      
  #calcualte scheduling parameters to buffer node
  my $lat = $buff_size;
  my $lfi = 1;
  my $efi = 1;
  my $afi = 1;
  my $fpo = 1;
  my $sd  = 0;
  
  #update calcualted costs
  TirGrammarMod::setCostValue($func,$bufkey,'performance','sd'  ,$sd);
  TirGrammarMod::setCostValue($func,$bufkey,'performance','efi' ,$efi);
  TirGrammarMod::setCostValue($func,$bufkey,'performance','afi' ,$afi);
  TirGrammarMod::setCostValue($func,$bufkey,'performance','lat' ,$lat);
  TirGrammarMod::setCostValue($func,$bufkey,'performance','lfi' ,$lfi);
  TirGrammarMod::setCostValue($func,$bufkey,'performance','fpo' ,$fpo);        

  #add buffer resource cost
  #::TODO::this should be based on empirical data
  TirGrammarMod::setCostValue($func,$bufkey,'resource','dsps'      ,0);
  TirGrammarMod::setCostValue($func,$bufkey,'resource','propDelay' ,1);
  TirGrammarMod::setCostValue($func,$bufkey,'resource','regs'      ,$bufferSizeBits);
  TirGrammarMod::setCostValue($func,$bufkey,'resource','aluts'     ,0);
  TirGrammarMod::setCostValue($func,$bufkey,'resource','bram'      ,0);     
}


#-----------------------------------
sub costAutoIndex {
#TODO: Look into this.. resource cost is not empirical
#-----------------------------------

  #my  ($hash) = @_;
  my $caller   = shift(@_);
  my $symbol   = shift(@_);
  my $hash     = $main::CODE{$caller}{symbols}{$symbol}; 

  my $dfgnode = $hash->{dfgnode};
  my $dtype   = $hash->{synthDtype};
  (my $dwidth  = $dtype) =~ s/\D*//g; #extract the number
     
  #-------------------------
  #Performance Estimate
  #-------------------------
  ## latency ##
  my $lat =  1;
  my $afi = 1;  
  my $lfi = 1;   
  my $efi = 1;  
  my $fpo = 1; 
  my $sd  = 0; ##autoindex always assumed to start at 0, when the stream is assumed to start as well    

  ## initialize resource cost
  my $dsps      = 0;    
  my $propDelay = 0;
  my $regs      = 0;
  my $aluts     = 0;
  my $bram      = 0;
  
 #perf
  TirGrammarMod::setCostValue($caller,$symbol,'performance','afi',$afi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','efi',$efi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','sd' ,$sd );
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lat',$lat);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lfi',$lfi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','fpo',$fpo);
  #                                    
  TirGrammarMod::setCostValue($caller,$symbol,'resource','dsps'      ,$dsps     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','propDelay' ,$propDelay);
  TirGrammarMod::setCostValue($caller,$symbol,'resource','regs'      ,$regs     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','aluts'     ,$aluts    );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','bram'      ,$bram     );  
}#()


# ========================================================================
# ARITHMETIC and LOGIC
# ========================================================================



#-----------------------------------
sub costPrimitiveInstruction {
#-----------------------------------

  #my  ($hash) = @_;
  my $caller   = shift(@_);
  my $symbol   = shift(@_);
  my $hash     = $main::CODE{$caller}{symbols}{$symbol}; 

  my $dfgnode = $hash->{dfgnode};
  my $dtype   = $hash->{synthDtype};
  (my $dwidth  = $dtype) =~ s/\D*//g; #extract the number
  (my $dcat    = $dtype) =~ s/\d*//g; #extract the category (int/float)
     
  #print  "::costComputeInstruction:: $symbol, $dtype,  $dwidth, $dcat\n";
     
  my $op1form = $hash->{oper1form};
  my $op2form = $hash->{oper2form};
  my $op      = $hash->{funcunit};
  
  #is this instruction iterative? (multi-cycle CPO/FPO)
  my $iterative=( ($op eq 'pow')
                ||($op eq 'sin') 
                ||($op eq 'cos') 
                ||($op eq 'log') 
                );
  
  #-------------------------
  #Performance Estimate
  #-------------------------
  
  #-------------
  ## latency ##
  #-------------
  #latency for ints
  my $lat =  1; #default latency, also for all integer primitive instructions
  
  #latency for floats
  #TODO: hardwired for 32-bit floats, and for Flopoco units synthesized
  #with these settings
  #flopoco <OP> frequency=300      \
  #              wE=8 wF=23        \
  #              pipeline=yes      \
  #              target=Stratix5   \
  #              outputFile=<FILE> \
  
  #NOTE: Looks like I need to add one to the latency of pipelined units created by
  #flopoco when I use them in my dataflow
  #That makes sense as the flopoco combinatorial unit (lat=0) would 
  #have a lat=1 for my DFG
  #BUT: this does not seem to apply to MUL! (it works correctly when I use the latency
  #provided by flopoco
  #BUT; does this always happen? As of 2018.04.03, I tested mul with lat set at 2 (flopoco provided) + 1, and it works quite well!
  #Soooooo?
  
  #TODO: what about operations other than add, mult, etc.
  if ($dcat eq 'float') {
    #add and sub: lat = 7
    if ( ($op eq 'add') 
       ||($op eq 'sub') 
       ){$lat =  7+1;}
    
    #mul: lat = 2 
    if (($op eq 'mul'))   {$lat =  2+1;}
    
    #div: lat = 12
    if (($op eq 'udiv'))  {$lat =  12+1;}
    
    #pow: 8,23)  = 27 cycles, (Regs+Slices BRAMs DSP48) = 1260R + 1828L 7  11
    if (($op eq 'pow'))   {$lat =  27;}

    #cordic - Precision = 24 bits (~SP) :: 23 cycles, 1721 + 2114 (Reg + LUTs)
    if (($op eq 'sin') || ($op eq 'cos'))   {$lat =  23;}
  }#if float
  
  #if reduction, then reductionSize effects the latency.
  #TODO: This is the simple calculation for linear 
  #(see $TYBEC$/docs/tybec_dfg_scheduler_buffer_generator.lyx)
  if(defined $hash->{reductionSize}) {
    $lat = $lat + ($hash->{reductionSize}) - 1;
  }
  
  #----------
  ## FI ## (or CPO)
  #----------
  # By default, we assume that the multi-cycle units can fire every cycle (because they are internally pipelined)
  # But we should also be able to cost (and schedule) those that don't (so the latency translates to local FI)
  
  ## initialize other scheduling paramaters ##
  my $afi = -1;  
  my $efi = -1;  
  my $fpo = 1; 
  my $sd  = -1;     
  my $lfi = 1;   
  
  # for iterative units, the LFI will be > 1 (equal to latency)
  # FPO set to one as the way I have defined it, the LFI x FPO gives CPO, so 
  #the iteration cycles should not appear at BOTH LFI and FPO
  if($iterative) {
    $lfi = $lat;
    #$fpo = $lat;
  }
  
  ## initialize resource cost
  my $dsps      = 0;    
  my $propDelay = 0;
  my $regs      = 0;
  my $aluts     = 0;
  my $bram      = 0;
  
  #udpate costs (hash, dfg)
  TirGrammarMod::setCostValue($caller,$symbol,'performance','afi',$afi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','efi',$efi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','sd' ,$sd );
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lat',$lat);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lfi',$lfi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','fpo',$fpo);
  #                                    
  TirGrammarMod::setCostValue($caller,$symbol,'resource','dsps'      ,$dsps     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','propDelay' ,$propDelay);
  TirGrammarMod::setCostValue($caller,$symbol,'resource','regs'      ,$regs     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','aluts'     ,$aluts    );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','bram'      ,$bram     );  
  
  #-------------------------
  #Resource Estimate
  #-------------------------
  #Limitations:
  #for floats, only add and float32 supported
  
  # calculate REGS (same for all ops)

  #if one of the operands is constant
  if (($op1form eq 'constant') || ($op2form eq 'constant')) {
    $hash->{resource}{regs}  = $dwidth;}
  #else, since both inputs registers, so x2
  else {
    $hash->{resource}{regs}  = $dwidth*2;}

  # ----------------------------------------------------------------
  # add, sub, and, or
  
  if  (   ($op eq 'add') 
      ||  ($op eq 'sub') 
      ||  ($op eq 'and') 
      ||  ($op eq 'or' ) 
      ||  ($op eq 'compare' )
      ||  ($op eq 'select' )
      )
       #I am NAIVELY assuming compare takes same resources as the rest in this block, but should check; TODO
  {
    #integer operations
    if (($dcat eq 'i') || ($dcat eq 'ui')) {
      $hash->{resource}{aluts} = $dwidth;      
      # propDelay fixed
      $hash->{resource}{propDelay} = 3;
    }
    
    #Note Limitations up there
    elsif ($dcat eq 'float') {
      $hash->{resource}{aluts} = 421; 
        #for experiments with stratix 5, float32, ip generator opt for freq @ 200MHZ, resulting in latency of 5
      # propDelay fixed
      $hash->{resource}{propDelay} = 3; 
        #TODO: check this
    }
    
  }
  # ----------------------------------------------------------------
  # mul
  elsif($op eq 'mul') {  
   
  # The new experiments were done on QuartusII (Prime giving same results), Stratix 5 DS
  # Bit-width :: ALUTS :: DSP blocks
  #     8	        0	        1
  #     27	      0	        1
  #     28	      0	        2
  #     36	      0	        2
  #     37	      10	      3
  #     48	      21	      3
  #     54	      27	      3
  #     55	      28	      7
  #     56	      58	      7
  #     58	      62	      7
  #     63	      72	      7
  #     64	      57	      8
    
    if    ( $dwidth <= 27)                   {$hash->{resource}{dsps} = 1; }
    elsif (($dwidth > 28) && ($dwidth <= 36)) {$hash->{resource}{dsps} = 2; }
    elsif (($dwidth > 36) && ($dwidth <= 54)) {$hash->{resource}{dsps} = 3; }
    elsif (($dwidth > 54) && ($dwidth <= 63)) {$hash->{resource}{dsps} = 7; }
    elsif ( $dwidth == 64)                   {$hash->{resource}{dsps} = 8; }
    else                                    {die "TyBEC: **ERROR** Unsupported data type for costing multipliers";}
  
    #expression for ALUTs from experiments:
    if    ( $dwidth <= 36)                   {$hash->{resource}{aluts} = 0; }
    elsif (($dwidth > 36) && ($dwidth <= 55)) {$hash->{resource}{aluts} = (10+1*($dwidth-37));}
    elsif (($dwidth > 55) && ($dwidth <= 63)) {$hash->{resource}{aluts} = (58+2*($dwidth-56));}
    elsif ( $dwidth == 64)                   {$hash->{resource}{aluts} = 57; }
    else                                    {die "TyBEC: **ERROR** Unsupported data type for costing multipliers";}

    #old and erroneous! 
    #y = 0.06x^2 - 1.5x + 7.6
    #$aluts = int( (0.06*($dType**2)) - (1.5*$dType) + 7.6); 
    
    # propDelay fixed; 3 or 4?. 3 gives closer estimates...
    #$propDelay  = 4; 
    $hash->{resource}{propDelay}  = 3;
  }
  # ----------------------------------------------------------------
  elsif($op eq 'udiv') {
    #from trendline in excel; good for upto 64
    $hash->{resource}{aluts} = int(($dwidth**2)+(3.68*$dwidth)-10.58); 

    # propDelay fixed; TODO: check and confirm
    $hash->{resource}{propDelay}  = 11;
  }
  # ----------------------------------------------------------------
  #load is simply making a copy of the variable, so just consumes one register
  elsif($op eq 'load') {
    $hash->{resource}{aluts} =$dwidth;
    $hash->{resource}{propDelay}  = 1;
  }
  # ----------------------------------------------------------------
  #  flopoco POW for SP (8,23)  = 27 cycles iteration, (Regs+Slices BRAMs DSP48) = 1260R + 1828L 7  11
  elsif($op eq 'pow') {
    $hash->{resource}{aluts} =1828;
    $hash->{resource}{propDelay}  = 3;
    $hash->{resource}{regs}  = 1260;
    $hash->{resource}{bram}  = 7*18000; #18000 is since of one blockRAM in Stratix 6; hardwiredl FIXME
    $hash->{resource}{dsps}  = 11;
  }
  #- flopoco cordic, Precision = 24 bits (~SP) :: 23 cycles, 1721 + 2114 (Reg + LUTs)
  elsif(($op eq 'sin') || ($op eq 'cos')) {
    $hash->{resource}{aluts} =2114;
    $hash->{resource}{propDelay}  = 3;
    $hash->{resource}{regs}  = 1721;
  }

  # ----------------------------------------------------------------
  else
    {die "TyBEC: unknown operation passed to costInstruction() in estimator"};
    
#  print  "::costComputeInstruction::END:: $symbol, $dtype,  $dwidth, $dcat\n";
}#()

## sub costComputeInstructionOld {
## 
##     my  ( $dType   #data type
##         , $op      #what is the operation? 
##         , $op1form #the form of operand 1 (constant, local, global)
##         , $op2form #
##         ) = @_;
##     
## 
##     $dType =~ s/\D//g; #extract the number
## 
##     my $aluts = 0;
##     my $regs = 0;
##     my $dsps = 0;
##     my $latency = 1;  #latency is always 1, as protptype has all single-cycle instructions
##     my $cpi = 1;      #see above
##     my $propDelay = 0;
## 
##     # ----------------------------------------------------------------
##     # calculate REGS (same for all ops)
## 
##     #if one of the operands is constant
##     if (($op1form eq 'constant') || ($op2form eq 'constant')) {
##       $regs  = $dType;}
##     #else, since both inputs registers, so x2
##     else {
##       $regs  = $dType*2;}
##     
##     
##     # ----------------------------------------------------------------
##     # add, sub, and, or
##     if  (   ($op eq 'add') 
##         ||  ($op eq 'sub' ) 
##         ||  ($op eq 'and' ) 
##         ||  ($op eq 'or' ) )
##     {
##       $aluts = $dType;      
##       # propDelay fixed
##       $propDelay  = 3;
##     }
##     # ----------------------------------------------------------------
##     # mul
##     elsif($op eq 'mul') {  
##      
##     # The new experiments were done on QuartusII (Prime giving same results), Stratix 5 DS
##     # Bit-width :: ALUTS :: DSP blocks
##     #     8	        0	        1
##     #     27	      0	        1
##     #     28	      0	        2
##     #     36	      0	        2
##     #     37	      10	      3
##     #     48	      21	      3
##     #     54	      27	      3
##     #     55	      28	      7
##     #     56	      58	      7
##     #     58	      62	      7
##     #     63	      72	      7
##     #     64	      57	      8
##       
##       if    ($dType <= 27)                    {$dsps = 1; }
##       elsif (($dType > 28) && ($dType <= 36)) {$dsps = 2; }
##       elsif (($dType > 36) && ($dType <= 54)) {$dsps = 3; }
##       elsif (($dType > 54) && ($dType <= 63)) {$dsps = 7; }
##       elsif ($dType == 64)                    {$dsps = 8; }
##       else                                    {die "TyBEC: **ERROR** Unsupported data type for costing multipliers";}
##     
##       #expression for ALUTs from experiments:
##       if    ($dType <= 36)                    {$aluts = 0; }
##       elsif (($dType > 36) && ($dType <= 55)) {$aluts = (10+1*($dType-37));}
##       elsif (($dType > 55) && ($dType <= 63)) {$aluts = (58+2*($dType-56));}
##       elsif ($dType == 64)                    {$aluts = 57; }
##       else                                    {die "TyBEC: **ERROR** Unsupported data type for costing multipliers";}
## 
##       #old and erroneous! 
##       #y = 0.06x^2 - 1.5x + 7.6
##       #$aluts = int( (0.06*($dType**2)) - (1.5*$dType) + 7.6); 
##       
##       # propDelay fixed; 3 or 4?. 3 gives closer estimates...
##       #$propDelay  = 4; 
##       $propDelay  = 3;
##     }
##     # ----------------------------------------------------------------
##     elsif($op eq 'udiv') {
##       #from trendline in excel; good for upto 64
##       $aluts = int(($dType**2)+(3.68*$dType)-10.58); 
## 
##       # propDelay fixed; TODO: check and confirm
##       $propDelay  = 11;
##     }
##     # ----------------------------------------------------------------
##     else
##       {die "TyBEC: unknown operation passed to costInstruction() in estimator"};
## 
##     # ----------------------------------------------------------------
##     my $cost
##       = { 'ALMS'      => 'null'
##         , 'ALUTS'     => $aluts
##         , 'REGS'      => $regs  
##         , 'M20Kbits'  => 0
##         , 'MLABbits'  => 0   
##         , 'DSPs'      => $dsps 
##         , 'Latency'   => $latency   
##         , 'PropDelay' => $propDelay   
##         , 'CPI'       => $cpi
##         };
##     return $cost;        
## }
    
# ========================================================================
# SELECT
# ========================================================================

# 2 input mux
# both inputs registered
$costI{select}{2}{ui18}{ver0}
  = { 'ALMS'       => 'null'
    , 'ALUTS'      => 18  
    , 'REGS'       => 36  
    , 'M20Kbits'   => 0   
    , 'MLABbits'   => 0   
    , 'DSPs'       => 0   
    , 'Latency'    => 1   
    , 'PropDelay'  => 3   
    , 'CPI'        => 1
    };   

# ========================================================================
# COMPARE
# ========================================================================
# both inputs registered
$costI{icmp}{eq}{ui10}{ver0}
  = { 'ALMS'       => 'null'
    , 'ALUTS'      => 4  
    , 'REGS'       => 20  
    , 'M20Kbits'   => 0   
    , 'MLABbits'   => 0   
    , 'DSPs'       => 0   
    , 'Latency'    => 1   
    , 'PropDelay'  => 3   
    , 'CPI'        => 1
    };   

$costI{icmp}{eq}{ui18}{ver0}
  = { 'ALMS'       => 'null'
    , 'ALUTS'      => 7  
    , 'REGS'       => 36  
    , 'M20Kbits'   => 0   
    , 'MLABbits'   => 0   
    , 'DSPs'       => 0   
    , 'Latency'    => 1   
    , 'PropDelay'  => 3   
    , 'CPI'        => 1
    };   

# ========================================================================
# COUNTERS
# ========================================================================

$costI{counter}{ui10}{ver0}
  = { 'ALMS'       => 'null'
    , 'ALUTS'      => 10  
    , 'REGS'       => 10 
    , 'M20Kbits'   => 0   
    , 'MLABbits'   => 0   
    , 'DSPs'       => 0   
    , 'Latency'    => 1   
    , 'PropDelay'  => 3   
    , 'CPI'        => 0
    };   

$costI{counter}{ui18}{ver0}
  = { 'ALMS'       => 'null'
    , 'ALUTS'      => 10  
    , 'REGS'       => 10 
    , 'M20Kbits'   => 0   
    , 'MLABbits'   => 0   
    , 'DSPs'       => 0   
    , 'Latency'    => 1   
    , 'PropDelay'  => 3   
    , 'CPI'        => 0
    };   

# ========================================================================
# OFFSET STREAMS/SMACHE/SPLIT/MERGE
# ========================================================================

#-----------------------------------
sub costMerge {
#TODO: Look into this.. resource cost is not empirical
#-----------------------------------

  #my  ($hash) = @_;
  my $caller   = shift(@_);
  my $symbol   = shift(@_);
  my $hash     = $main::CODE{$caller}{symbols}{$symbol}; 

  my $dfgnode = $hash->{dfgnode};
  my $dtype   = $hash->{synthDtype};
  (my $dwidth  = $dtype) =~ s/\D*//g; #extract the number
  my $nmerge  = $hash->{nMerge};
     
  #-------------------------
  #Performance Estimate
  #-------------------------
  ## latency ##
  my $lat = 1;
    #merge should not incur any latency, as I can emit words as they arrive
    #and if they arrive together, then I can sequence them
  my $afi = -1;  
  my $lfi = 1;   
  my $efi = -1;  
  my $fpo = 1; 
  my $sd  = -1;     
  
  ## initialize resource cost
  my $dsps      = 0;    
  my $propDelay = 0;
  my $regs      = $dwidth*$nmerge;
    #IF all words arrive concurrently, then I may need to store in order
    #to sequence them; TODO: think about this.
  my $aluts     = 0;
  my $bram      = 0;
  
 #perf
  TirGrammarMod::setCostValue($caller,$symbol,'performance','afi',$afi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','efi',$efi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','sd' ,$sd );
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lat',$lat);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lfi',$lfi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','fpo',$fpo);
  #                                    
  TirGrammarMod::setCostValue($caller,$symbol,'resource','dsps'      ,$dsps     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','propDelay' ,$propDelay);
  TirGrammarMod::setCostValue($caller,$symbol,'resource','regs'      ,$regs     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','aluts'     ,$aluts    );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','bram'      ,$bram     );  
}#()


#-----------------------------------
sub costSplit {
#TODO: Look into this.. resource cost is not empirical
#-----------------------------------

  #my  ($hash) = @_;
  my $caller   = shift(@_);
  my $symbol   = shift(@_);
  my $hash     = $main::CODE{$caller}{symbols}{$symbol}; 

  my $dfgnode = $hash->{dfgnode};
  my $dtype   = $hash->{synthDtype};
  (my $dwidth  = $dtype) =~ s/\D*//g; #extract the number
  my $nsplit  = $hash->{nSplit};
     
  #-------------------------
  #Performance Estimate
  #-------------------------
  ## latency ##
  my $lat = $nsplit;
    #I want to emit the split streams in-step, so I have to wait until I have enough
    #words for all the splits, and then emit them together
  my $afi = -1;  
  my $lfi = 1;   
  my $efi = -1;  
  my $fpo = 1; 
  my $sd  = -1;     
  
  #my $sizeInWords = $maxPosOff + $maxPosOff + 1;
  
  ## initialize resource cost
  my $dsps      = 0;    
  my $propDelay = 0;
  my $regs      = $dwidth*$nsplit;
    #See note for latency. If I want to wait until I have all the splits ready, then I 
    #I need memory to store them
  my $aluts     = 0;
  my $bram      = 0;
  
 #perf
  TirGrammarMod::setCostValue($caller,$symbol,'performance','afi',$afi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','efi',$efi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','sd' ,$sd );
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lat',$lat);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lfi',$lfi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','fpo',$fpo);
  #                                    
  TirGrammarMod::setCostValue($caller,$symbol,'resource','dsps'      ,$dsps     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','propDelay' ,$propDelay);
  TirGrammarMod::setCostValue($caller,$symbol,'resource','regs'      ,$regs     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','aluts'     ,$aluts    );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','bram'      ,$bram     );  
}#()


#-----------------------------------
sub costSplitOut {
#Since all the cost for creating Splits (including LATENCY) is incorporated in the
#relevant SPLIT node, so this node comes for "free"; has no cost
#I have put in a latency of 1, but even that may not be needed? Check. #TODO
  #my  ($hash) = @_;
  my $caller   = shift(@_);
  my $symbol   = shift(@_);
  my $hash     = $main::CODE{$caller}{symbols}{$symbol}; 

  my $dfgnode = $hash->{dfgnode};
  my $dtype   = $hash->{synthDtype};
  (my $dwidth  = $dtype) =~ s/\D*//g; #extract the number
     
  #-------------------------
  #Performance Estimate
  #-------------------------
  ## latency ##
  my $lat = 1;
  my $afi = -1;  
  my $lfi = 1;   
  my $efi = -1;  
  my $fpo = 1; 
  my $sd  = -1;     
  
  ## initialize resource cost
  my $dsps      = 0;    
  my $propDelay = 0;
  my $regs      = 0;
  my $aluts     = 0;
  my $bram      = 0;
  
 #perf
  TirGrammarMod::setCostValue($caller,$symbol,'performance','afi',$afi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','efi',$efi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','sd' ,$sd );
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lat',$lat);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lfi',$lfi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','fpo',$fpo);
  #                                    
  TirGrammarMod::setCostValue($caller,$symbol,'resource','dsps'      ,$dsps     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','propDelay' ,$propDelay);
  TirGrammarMod::setCostValue($caller,$symbol,'resource','regs'      ,$regs     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','aluts'     ,$aluts    );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','bram'      ,$bram     );  
}#()


#-----------------------------------
sub costSmache {
#TODO: Look into this.. resource cost is not empirical
#-----------------------------------

  #my  ($hash) = @_;
  my $caller   = shift(@_);
  my $symbol   = shift(@_);
  my $hash     = $main::CODE{$caller}{symbols}{$symbol}; 

  my $dfgnode = $hash->{dfgnode};
  my $dtype   = $hash->{synthDtype};
  (my $dwidth  = $dtype) =~ s/\D*//g; #extract the number
     
  my $maxPosOff = $main::CODE{$caller}{symbols}{$symbol}{maxPosOffset};     
  my $maxNegOff = $main::CODE{$caller}{symbols}{$symbol}{maxNegOffset};     
  #-------------------------
  #Performance Estimate
  #-------------------------
  ## latency ##
  my $lat = $maxPosOff+1; #TODO: look this up from smache work to see if correct
    #the latency of the smache module is equal to the largest positive offset, as that is how long you have to wait to 
    #get the furthest positive offset, and at that point all other offsets would be available anyway. 
    #And **all offsets from this module will be emitted at the same time**
    #one more cycle due to register delay
  my $afi = -1;  
  my $lfi = 1;   
  my $efi = -1;  
  my $fpo = 1; 
  my $sd  = -1;     
  
  my $sizeInWords = $maxPosOff + $maxPosOff + 1;
  
  ## initialize resource cost
  my $dsps      = 0;    
  my $propDelay = 0;
  my $regs      = $sizeInWords * $dwidth ;
  #print  "::costSmache:: For $symbol, calculated cost in buffer registers to be $regs\n";
  my $aluts     = 0;
  my $bram      = 0;
  
  #TODO: Incorporate the following rationale into the cost
  #-------------------------------------------------------
#  # calculate number of single-bit registers
#  # used for creating stream window based on data type
#  # and offset distance (size in words) 
#  # NOTE: Experiment shows that Altera synthesizes
#  # offset register bank on BRAM --- NOT using REGS!
#  # BUT, it uses REGs as well (possible a combi of shift REGS and 
#  # Block RAM)
#  # It loosk like we can assign half the numner of bits to REGs
#  # and other half to BlockRAM, and 1/10th (of the half) to ALUTs
#  # TODO: This is a good enough estimate, but can be made better 
#  # possibly with a trend-line
#    
#  # if    ($type eq 'ui32') { $M20Kbits = $offsetDis * 32 / 2;}
#  # elsif ($type eq 'ui18') { $M20Kbits = $offsetDis * 18 / 2;}
#  # elsif ($type eq 'ui12') { $M20Kbits = $offsetDis * 12 / 2;}
#  # else                    { print "TyBEC: Unrecognized data type for memory\n"; }
#  # $regs = $M20Kbits;
#  
#  # ADDED: for hotspot example, ALL memory bits were used in BRAM. Will have to figure this out!!
#  # was it because of 32 bits?
#  if    ($type eq 'ui32') { $M20Kbits = $offsetDis * 32 ;}
#  elsif ($type eq 'ui18') { $M20Kbits = $offsetDis * 18 ;}
#  elsif ($type eq 'ui12') { $M20Kbits = $offsetDis * 12 ;}
#  else                    { print "TyBEC: Unrecognized data type for memory\n"; }
#  
#  #FIXME: more experiments for this...
#  $regs = 2*int((0.01 * $M20Kbits)+0.5); #0.1 for 1/10th, 0.5 for rounding
#  #$regs = 0;
#
#  #FIXME: more experiments for this...
#  #$ALUTS = int((0.1 * $M20Kbits)+0.5); #0.1 for 1/10th, 0.5 for rounding
#  $ALUTS = int((0.01 * $M20Kbits)+0.5); #0.1 for 1/10th, 0.5 for rounding
  
 #perf
  TirGrammarMod::setCostValue($caller,$symbol,'performance','afi',$afi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','efi',$efi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','sd' ,$sd );
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lat',$lat);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lfi',$lfi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','fpo',$fpo);
  #                                    
  TirGrammarMod::setCostValue($caller,$symbol,'resource','dsps'      ,$dsps     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','propDelay' ,$propDelay);
  TirGrammarMod::setCostValue($caller,$symbol,'resource','regs'      ,$regs     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','aluts'     ,$aluts    );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','bram'      ,$bram     );  
}#()

#-----------------------------------
sub costOffsetStream {
#-----------------------------------
#Since all the cost for creating offsets (including LATENCY) is incorporated in the
#relevant SMACHE node, so this node comes for "free"; has no cost
#I have put in a latency of 1, but even that may not be needed? Check. #TODO
  #my  ($hash) = @_;
  my $caller   = shift(@_);
  my $symbol   = shift(@_);
  my $hash     = $main::CODE{$caller}{symbols}{$symbol}; 

  my $dfgnode = $hash->{dfgnode};
  my $dtype   = $hash->{synthDtype};
  (my $dwidth  = $dtype) =~ s/\D*//g; #extract the number
     
  #-------------------------
  #Performance Estimate
  #-------------------------
  ## latency ##
  my $lat = 1;
  my $afi = -1;  
  my $lfi = 1;   
  my $efi = -1;  
  my $fpo = 1; 
  my $sd  = -1;     
  
  ## initialize resource cost
  my $dsps      = 0;    
  my $propDelay = 0;
  my $regs      = 0;
  my $aluts     = 0;
  my $bram      = 0;
  
 #perf
  TirGrammarMod::setCostValue($caller,$symbol,'performance','afi',$afi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','efi',$efi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','sd' ,$sd );
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lat',$lat);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','lfi',$lfi);
  TirGrammarMod::setCostValue($caller,$symbol,'performance','fpo',$fpo);
  #                                    
  TirGrammarMod::setCostValue($caller,$symbol,'resource','dsps'      ,$dsps     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','propDelay' ,$propDelay);
  TirGrammarMod::setCostValue($caller,$symbol,'resource','regs'      ,$regs     );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','aluts'     ,$aluts    );
  TirGrammarMod::setCostValue($caller,$symbol,'resource','bram'      ,$bram     );  
}#()

# ========================================================================
# ************************************************************************
# COST OF CONTROL LOGIC (outside Compute Core)
# ************************************************************************
# ========================================================================
# ------------------------------------------------------------------------
# COST function for Stream Objects 
# (only for internal, explicit streams from BRAM)
# ------------------------------------------------------------------------

sub costStreamObject {
	#die "Too many arguments for subroutine" unless @_ <= 4;
	#die "Too few arguments for subroutine" unless @_ >= 4;

    my  ( $dType     #data type
        , $dir       #stream direction (from computeCore's perspective)
        , $size      #size in words
        , $addrspace #addrspace qualifier of relevant **memory object**
        , $stride    #stride:  effects sustained bandwidth 
        , $memConnAddrSpace 
        ) = @_;
                     #the address space qualifier of the relevant memory object
                     # 0 = private memory (on-chip)
                     # 1 = global memory (device DRAM)
                     # 2 = local memory (device on-chip Block RAM)
                     # 3 = constant memory
                     # 4 = peer kernel
                     # 5 = direct host stream
                     # 6 = pipeline buffers (typically NO explicit streams from them)
    
    #for the few experiments, this seems be constant. 
    #TODO: will change for much larger stream or other addrspaces... check
    my $aluts = 7;
    my $regs = 7;
 
    #total bits transferred over stream
    $dType =~ s/\D//g; #extract the number
    my $totalBits = $dType * $size;
 
    #sustained bandwidth for this stream in Mbps. 
    #--------------------------------------------
    #Depends on:
    # relevant memory type (addrSPace)
    # peak BW of channel
    # and access pattern
    my $peakBW_Mbps;
    my $sustBW_Mbps;
    my $rho;
    
    # Get peak BW depending on type of memory
    #device DRAM
    if($memConnAddrSpace == 1) {
      $peakBW_Mbps = $HardwareSpecs::boards{$main::targetBoard}{boardRAMBW_Peak_Mbps}; }
    #host streams
    elsif ($memConnAddrSpace == 5) {
      $peakBW_Mbps = $HardwareSpecs::boards{$main::targetBoard}{hostBW_Peak_Mbps}; }
    #on-chip BRAM, 
    #they will will always match the throughput of the kernel
    #so just set to -1 to indicate that this is not relevant to roof-line analysis
    #TODO check if this assumption is correct
    elsif ($memConnAddrSpace == 2) {
      $peakBW_Mbps = -1; }
    #same goes for CONSTANT memories; assume in BRAM and hence not a limiting factor  
    elsif ($memConnAddrSpace == 3) {
      $peakBW_Mbps = -1; }
    else {
      die "**ERROR**: Memory stream's relevant memory object's address space qualifier is not supported\n";}

    # Get scaling factor based on MP-stream results
    #simplistic RHO calculation, with just two possibilities;
    #contiguous (stride=1),
    #all else (stride!=1)
    #TODO: make this a bit more sophisticated based on rho experiments
    #just now, rho set to 57% based on mp-stream results on AOCL (assuming max sust BW using vectorization)
    #and strided is 10% of contiguous
    if($stride == 1) {
     $rho = 0.57;}
    else {
      $rho = 0.057; #debug why I am doing this...+
    }
    
    #sustained bandwidth is peak BW scaled by RHO
    $sustBW_Mbps = $rho * $peakBW_Mbps;
    
    # ----------------------------------------------------------------
    my $cost
      = { 'ALMS'      => 'null'
        , 'ALUTS'     => $aluts
        , 'REGS'      => $regs  
        , 'M20Kbits'  => 0
        , 'MLABbits'  => 0   
        , 'DSPs'      => 0
        , 'Latency'   => 0
        , 'PropDelay' => 0
        , 'CPI'       => 0
        , 'totalBits' => $totalBits
        , 'sustBW_Mbps' => $sustBW_Mbps
      };
    return $cost;        
}                 

# ========================================================================
# COST OF MEMORY MODULES
# ========================================================================

sub costMem {    
    my  ( $dType       
        , $addrspace   
        , $sizeInWords 
        , $readPorts   
        , $writePorts 
        ) = @_;  

    #round up size in words to nearest 2**N, as 
    #that is how LMEM is synthesized be BE (TODO: does it need to be so?)
    my $Awidth = log2($sizeInWords);
    $sizeInWords = 2 ** $Awidth;
    
    $dType =~ s/\D//g; #extract the number

    my $M20Kbits= 0;
    my $aluts   = 0;
    my $regs    = 0;  

  
    # Local Memories (addrspace == 2)
    #--------------------------------------
    if ($addrspace == 2) {
      # calculate M20Kbits based on data type
      # TODO NOTE Round up size to nearest 2^N as 
      # the way I create verilog modules, memory is always sized as 2^N
      # OR: update verilog memor module creation
  
      # 1 read port, 1 write port
      if (($readPorts==1) && ($writePorts==1))  {
        $M20Kbits = $sizeInWords * $dType;
      }
        
      # N read port, 1 write port
      # M20Kbits = (width of word) x (size of mem in words) x (number of read ports)
      elsif (($readPorts>1) && ($writePorts==1))  {
        $M20Kbits = $sizeInWords * $readPorts * $dType;
      }
  
      # 1 read port, N write port
      # REGS = (width of word) x (size of mem in words)
      # ALUTS = (width of word) x (size of mem in words) x 2  , if 4 ports and ui18
      # ALUTS = ??? for 8 ports? Check!
      # ALUTS = (width of word) x (size of mem in words) x 0.5, if 2 ports and ui18
      # ALUTS = (width of word) x (size of mem in words) x 2.3, if 4 ports and ui12 (approximated to 2)
      # for ui18, it seems ALUTS / REG =  0.75x - 1, where x is the number of writePorts
      elsif (($readPorts==1) && ($writePorts>1))  {
        $regs   = $sizeInWords * $dType;
        $aluts  = $regs * ((0.75*$writePorts)-1);
      }
  
      # N read ports, N write ports; currently not supported
      else
        {die "Unsupported combination of read/write ports in multi-port memory";}
    }#if ($addrspace == 2)
    
    # Global Memories (addrspace == 1)
    #--------------------------------------
    # The cost of memory controllers for global memory is added separately as
    # the base-platform cost. So no other cost here.
    elsif ($addrspace == 1) {
      $regs = 0;
      $aluts = 0;
      $M20Kbits = 0;
    }
    
    # Constant Memories (addrspace == 3)
    #--------------------------------------
    # TODO: For now I am not assigning resources to constant memories as I need to come back to
    # this and sort it properly
    elsif ($addrspace == 3) {
      $regs = 0;
      $aluts = 0;
      $M20Kbits = 0;
    }
    
    else {die "Unsupported memory address space for costing \n";}
    

    my $costM
      = { 'ALMS'      => 'null'
        , 'ALUTS'     => $aluts
        , 'REGS'      => $regs
        , 'M20Kbits'  => $M20Kbits
        , 'MLABbits'  => 0   
        , 'DSPs'      => 0   
        , 'Latency'   => 0   
        , 'PropDelay' => 0   
        , 'CPI'       => 0
        };

    return $costM;        
}


# ========================================================================
# COST OF BASE PLATFORM
# ========================================================================

# TODO:
# Experimental results on AOCL ONLY for now
# So the Empirical results are read for  AOCL only
# irrespective of the target

sub costBasePlatform {
    my( $dType      
      , $numStreamsIn
      , $numStreamsOut 
      , $peScaling
      ) = @_;
   
    $dType =~ s/\D//g; #extract the number

    my $bram  = 0;
    my $aluts = 0;
    my $regs  = 0;  

    my $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};
    
    #TODO: target-device based branch here to read appropriate empirical data.
    #hardiwired to AOCL for now.

    #the resource vs #streams data; use for BRAM
    my $empDataHash_vsStreams_ref 
      = hashify("$TyBECROOTDIR/empirical/baseplatform-resources-vs-inputstreams-nallatech_385_D5.csv", 'input-streams');
    my %empDataHash_vsStreams = %$empDataHash_vsStreams_ref;
    
    #the resource vs pe-scaling data; use for luts and regs
    my $empDataHash_vsPescaling_ref 
      = hashify("$TyBECROOTDIR/empirical/baseplatform-resources-vs-pescaling-nallatech_385_D5.csv", 'cus');
    my %empDataHash_vsPescaling = %$empDataHash_vsPescaling_ref;
   
    #TODO: Interpolate data for those points that do not have empirical results
    #till then, this function will only work for the points where we have empirical results.
    
    my $costBP
      = { 'ALMS'      => 'null'
        , 'aluts'     => $empDataHash_vsPescaling{$peScaling}{luts}       
        , 'regs'      => $empDataHash_vsPescaling{$peScaling}{regs}
        , 'bram'      => $empDataHash_vsStreams{$numStreamsIn}{bram_bits}
        , 'MLABbits'  => 0   
        , 'dsps'      => 0   
        , 'Latency'   => 0   
        , 'PropDelay' => 0   
        , 'CPI'       => 0
        };

    return $costBP;        
}

