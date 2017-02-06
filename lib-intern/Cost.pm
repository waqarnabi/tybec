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
# ARITHMETIC and LOGIC
# ========================================================================

sub costComputeInstruction {

    my  ( $dType   #data type
        , $op      #what is the operation? 
        , $op1form #the form of operand 1 (constant, local, global)
        , $op2form #
        ) = @_;
    

    $dType =~ s/\D//g; #extract the number

    my $aluts = 0;
    my $regs = 0;
    my $dsps = 0;
    my $latency = 1;  #latency is always 1, as protptype has all single-cycle instructions
    my $cpi = 1;      #see above
    my $propDelay = 0;

    # ----------------------------------------------------------------
    # calculate REGS (same for all ops)

    #if one of the operands is constant
    if (($op1form eq 'constant') || ($op2form eq 'constant')) {
      $regs  = $dType;}
    #else, since both inputs registers, so x2
    else {
      $regs  = $dType*2;}
    
    
    # ----------------------------------------------------------------
    # add, sub, and, or
    if  (   ($op eq 'add') 
        ||  ($op eq 'sub' ) 
        ||  ($op eq 'and' ) 
        ||  ($op eq 'or' ) )
    {
      $aluts = $dType;      
      # propDelay fixed
      $propDelay  = 3;
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
      
      if    ($dType <= 27)                    {$dsps = 1; }
      elsif (($dType > 28) && ($dType <= 36)) {$dsps = 2; }
      elsif (($dType > 36) && ($dType <= 54)) {$dsps = 3; }
      elsif (($dType > 54) && ($dType <= 63)) {$dsps = 7; }
      elsif ($dType == 64)                    {$dsps = 8; }
      else                                    {die "TyBEC: **ERROR** Unsupported data type for costing multipliers";}
    
      #expression for ALUTs from experiments:
      if    ($dType <= 36)                    {$aluts = 0; }
      elsif (($dType > 36) && ($dType <= 55)) {$aluts = (10+1*($dType-37));}
      elsif (($dType > 55) && ($dType <= 63)) {$aluts = (58+2*($dType-56));}
      elsif ($dType == 64)                    {$aluts = 57; }
      else                                    {die "TyBEC: **ERROR** Unsupported data type for costing multipliers";}

      #old and erroneous! 
      #y = 0.06x^2 - 1.5x + 7.6
      #$aluts = int( (0.06*($dType**2)) - (1.5*$dType) + 7.6); 
      
      # propDelay fixed; 3 or 4?. 3 gives closer estimates...
      #$propDelay  = 4; 
      $propDelay  = 3;
    }
    # ----------------------------------------------------------------
    elsif($op eq 'udiv') {
      #from trendline in excel; good for upto 64
      $aluts = int(($dType**2)+(3.68*$dType)-10.58); 

      # propDelay fixed; TODO: check and confirm
      $propDelay  = 11;
    }
    # ----------------------------------------------------------------
    else
      {die "TyBEC: unknown operation passed to costInstruction() in estimator"};

    # ----------------------------------------------------------------
    my $cost
      = { 'ALMS'      => 'null'
        , 'ALUTS'     => $aluts
        , 'REGS'      => $regs  
        , 'M20Kbits'  => 0
        , 'MLABbits'  => 0   
        , 'DSPs'      => $dsps 
        , 'Latency'   => $latency   
        , 'PropDelay' => $propDelay   
        , 'CPI'       => $cpi
        };
    return $cost;        
}
    
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
# OFFSET STREAMS 
# ========================================================================
sub costOffsetStream {
    my  ( $type      
        , $offsetDis
        ) = @_;

    my $regs = 0;
    my $M20Kbits = 0;
    my $ALUTS = 0;
    
    # calculate number of single-bit registers
    # used for creating stream window based on data type
    # and offset distance (size in words) 
    # NOTE: Experiment shows that Altera synthesizes
    # offset register bank on BRAM --- NOT using REGS!
    # BUT, it uses REGs as well (possible a combi of shift REGS and 
    # Block RAM)
    # It loosk like we can assign half the numner of bits to REGs
    # and other half to BlockRAM, and 1/10th (of the half) to ALUTs
    # TODO: This is a good enough estimate, but can be made better 
    # possibly with a trend-line
    
    # if    ($type eq 'ui32') { $M20Kbits = $offsetDis * 32 / 2;}
    # elsif ($type eq 'ui18') { $M20Kbits = $offsetDis * 18 / 2;}
    # elsif ($type eq 'ui12') { $M20Kbits = $offsetDis * 12 / 2;}
    # else                    { print "TyBEC: Unrecognized data type for memory\n"; }
    # $regs = $M20Kbits;
    
    # ADDED: for hotspot example, ALL memory bits were used in BRAM. Will have to figure this out!!
    # was it because of 32 bits?
    if    ($type eq 'ui32') { $M20Kbits = $offsetDis * 32 ;}
    elsif ($type eq 'ui18') { $M20Kbits = $offsetDis * 18 ;}
    elsif ($type eq 'ui12') { $M20Kbits = $offsetDis * 12 ;}
    else                    { print "TyBEC: Unrecognized data type for memory\n"; }
   
    #FIXME: more experiments for this...
    $regs = 2*int((0.01 * $M20Kbits)+0.5); #0.1 for 1/10th, 0.5 for rounding
    #$regs = 0;

    #FIXME: more experiments for this...
    #$ALUTS = int((0.1 * $M20Kbits)+0.5); #0.1 for 1/10th, 0.5 for rounding
    $ALUTS = int((0.01 * $M20Kbits)+0.5); #0.1 for 1/10th, 0.5 for rounding
    

    my $cost
      = { 'ALMS'      => 'null'
        , 'ALUTS'     => $ALUTS
        , 'REGS'      => $regs 
        , 'M20Kbits'  => $M20Kbits
        , 'MLABbits'  => 0   
        , 'DSPs'      => 0   
        , 'Latency'   => 0   
        , 'PropDelay' => 0   
        , 'CPI'       => 0
        };

    return $cost;        
}

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
        , $addrSpace #addrSpace qualifier of relevant **memory object**
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
# ************************************************************************
# COST OF MEMORY MODULES
# ************************************************************************
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
# ************************************************************************
# COST OF BASE PLATFORM
# ************************************************************************
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

    my $M20Kbits= 0;
    my $aluts   = 0;
    my $regs    = 0;  

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
        , 'ALUTS'     => $empDataHash_vsPescaling{$peScaling}{luts}       
        , 'REGS'      => $empDataHash_vsPescaling{$peScaling}{regs}
        , 'M20Kbits'  => $empDataHash_vsStreams{$numStreamsIn}{bram_bits}
        , 'MLABbits'  => 0   
        , 'DSPs'      => 0   
        , 'Latency'   => 0   
        , 'PropDelay' => 0   
        , 'CPI'       => 0
        };

    return $costBP;        
}

