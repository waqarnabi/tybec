# =============================================================================
# Company      : Unversity of Glasgow, Comuting Science
# Author:        Syed Waqar Nabi
# 
# Create Date  : 2015.01.13
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
#  Limitations and Constraints:
#  ===========================
#  See TybeTirlParser.pl
# =============================================================================                        

package TirGrammarMod;
use strict;
use warnings;

use Cost;             #read costs from Cost.pm

use Exporter qw( import );
our @EXPORT = qw( $grammar );

use List::Util 'max';
use File::Slurp;
use Tree::DAG_Node;     #for generating call trees
use Term::ANSIColor qw(:constants);

my $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};

# ============================================================================
# Utility routines
# ============================================================================

# --------------------------------------------------------------------------
# MAX and MIN
# --------------------------------------------------------------------------
sub mymax ($$) { $_[$_[0] < $_[1]] }
sub mymin ($$) { $_[$_[0] > $_[1]] }


# ==========================================================================
# DEPENDANCY ANALYSIS
# ==========================================================================

#----------------------------------------------------
#WHEN THE INSTRUCTION IS A COMPUTE INSTRUCTION
#-----------------------------------------------------
#do dependency analysis on the passed instruction for a function
#based on previous instructions of this function already parsed
#args:
#0 = function name
#1 = destination operand
#2 = oper1
#3 = oper2
#4 = oper3 (if applicable)
sub dependAnalysis {
  my $n       = scalar(@_);
  my $func    = shift(@_); 
  my $operDest= shift(@_); 
  my $oper1   = shift(@_);
  my $oper2   = shift(@_);

  #if total args =5, it means 3 operands passed
  #if not, just give it a garbage value so that comparison
  #against can never yield 
  my $oper3;
  if ($n == 5)
    {$oper3 = shift(@_);
    print "found 3 operands!\n";}
  else
    {$oper3 = 'null';}

  $main::CODE{$func}{parExecInstWise}{$operDest} = 0;
        #initialization to ensure comparison for max is not against undef

   #if one of the previously passed instruction's DEST_OPER is now a source operand
   #of this instruction, then this instructions Stage is  max of:
     # +1 of previous stage 
     # the already set Stage of this instruction based on its dependence on another previous instruction
   #otherwise, do nothing
   foreach my $key (keys %{$main::CODE{$func}{parExecInstWise}}) 
   {
     # check the operD against each key (for compute instruction, the key and operD are 
     # actually identical, but not so for CALL instructions
     if (   ($main::CODE{$func}{instructions}{$key}{operD} eq $oper1) 
        ||  ($main::CODE{$func}{instructions}{$key}{operD} eq $oper2) 
        ||  ($main::CODE{$func}{instructions}{$key}{operD} eq $oper3))
       {$main::CODE{$func}{parExecInstWise}{$operDest} 
         = mymax ( $main::CODE{$func}{parExecInstWise}{$operDest}
                 , ($main::CODE{$func}{parExecInstWise}{$key} + 1)        ); }#if
   }#foreach
   #print ">==> Setting parExecInstWise of $operDest to $main::CODE{$func}{parExecInstWise}{$operDest} \n";
}#sub dependAnalysis

#-----------------------------------------------------
#WHEN THE INSTRUCTION IS A FUNCTION CALL INSTRUCTION
#-----------------------------------------------------
#do dependency analysis on the passed instruction for a function
#based on previous instructions of this function already parsed

#args:
#0 = parent/caller function name
#1 = child/callee function name
sub dependAnalysisFunc {
  my $n       = scalar(@_);
  my $parentFunc    = shift(@_); #caller function
  my $childFunc     = shift(@_); #childfunc.seq

  # the relevant destination operand for analysis 
  my $operDest = $main::CODE{$parentFunc}{instructions}{$childFunc}{operD};
  
  $main::CODE{$parentFunc}{parExecInstWise}{$childFunc} = 0;
    #initialization to ensure comparison for max is not against undef

   #if one of the previously passed instruction's DEST_OPER is now a source operand
   #of this instruction, then this instructions Stage is  max of:
     # +1 of previous stage 
     # the already set Stage of this instruction based on its dependence on another previous instruction
   #otherwise, do nothing
  foreach my $key (keys %{$main::CODE{$parentFunc}{parExecInstWise}}) {
    #as there is no fixed number of input arguments to the COMB block, so we need
    #to iterate through the entire HASH and check each argument for dependency in 
    #another nested loop, and set a boolean to indicate dependency
    my $boolCond = 0;
    foreach my $key2 (keys %{$main::CODE{$parentFunc}{instructions}{$childFunc}{args2child}} ) {
      #only relevant for input arguments
      if($main::CODE{$parentFunc}{instructions}{$childFunc}{args2child}{$key2}{dir} eq 'input') {
        # if the $key from  parExecInstWise, whose operD indicates a destination, matches an input key
        # then set flag to indicate dependence
        $boolCond = $boolCond 
                  ||(   $main::CODE{$parentFunc}{instructions}{$key}{operD} 
                    eq  $main::CODE{$parentFunc}{instructions}{$childFunc}{args2child}{$key2}{name} );
      }#if
    }#foreach
    
    #if bool condition is set, it means that ATLEAST one input argument to child function
    #is a destination for a previously parsed instruction, so update its pipe stage
    #based on this dependancy
    if ($boolCond) {
        $main::CODE{$parentFunc}{parExecInstWise}{$childFunc} 
        = mymax ( $main::CODE{$parentFunc}{parExecInstWise}{$childFunc}
                , ($main::CODE{$parentFunc}{parExecInstWise}{$key} + 1)        ); 
    }#if
      
  }#foreach
}#sub dependAnalysisFunc





# ============================================================================
# GRAMMAR ACTIONS' SUB-ROUTINES
# ============================================================================
# Easier to maintain/re-use code


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMEM_OBJ{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {mem_objects} {$item{NAME}} {addrSpace} = $item{ADDR_SPACE_IDENT};
  $main::CODE {launch} {mem_objects} {$item{NAME}} {dataType} = $item{DATA_TYPE};
  $main::CODE {launch} {mem_objects} {$item{NAME}} {size}      = $item[9];
  $main::CODE {launch} {mem_objects} {$item{NAME}} {connStreamCount} = 0;
  $main::CODE {launch} {mem_objects} {$item{NAME}} {connInStreamCount} = 0;
  $main::CODE {launch} {mem_objects} {$item{NAME}} {connOutStreamCount} = 0;
  print "TyBEC: Found memory module: $item{NAME}, $item{DATA_TYPE} , $item[9] words , addressspace = $item{ADDR_SPACE_IDENT} \n";

  #---------------------------
  # update cost of mem object
  # --------------------------
  # call subroutine: type, addrSpace, size in words, nReadPorts (inStream), nWritePorts (outStream)
  $main::CODE {launch} {mem_objects} {$item{NAME}} {cost} 
    = Cost::costMem  ( $item{DATA_TYPE}
                    , $item{ADDR_SPACE_IDENT}
                    , $item{MEM_SIZE} 
                    , $main::CODE{launch}{mem_objects}{$item{NAME}}{readPorts}
                    , $main::CODE{launch}{mem_objects}{$item{NAME}}{writePorts}
                    );
  
}


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMEM_WRITE_PORTS{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {mem_objects} {$arg[0]} {writePorts} = $item{INTEGER};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMEM_HOSTMAP_NAME{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
    
  $main::CODE {launch} {mem_objects} {$arg[0]} {hmap} = $item{NAME};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMEM_INIT_DATA{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {mem_objects} {$arg[0]} {init} = $item{NAME};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMEM_READ_PORTS{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
$main::CODE {launch} {mem_objects} {$arg[0]} {readPorts} = $item{INTEGER};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSCALAR_IVAL{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {scalar_objects} {$arg[0]} {init_value} = $item[7];
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSCLR_HOSTMAP_NAME{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {scalar_objects} {$arg[0]} {hmap} = $item{NAME};
} 

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSCLR_OBJ{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {scalar_objects} { $item{NAME} } {addrSpace} = $item{ADDR_SPACE_IDENT};
  $main::CODE {launch} {scalar_objects} { $item{NAME} } {dataType} = $item{DATA_TYPE};
  print "TyBEC: Found scalar object: $item{NAME}, $item{DATA_TYPE} ,  addressspace = $item{ADDR_SPACE_IDENT} \n";
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAM_IS_SIGNAL{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{launch}{stream_objects}{$arg[0]}{signal} = $item[8];
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAM_START_ADDR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{launch}{stream_objects}{$arg[0]}{startAddr} = eval($item[7]);
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAM_LEN{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{launch}{stream_objects}{$arg[0]}{length} = $item[7];
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAM_STRIDE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{launch}{stream_objects}{$arg[0]}{stride} = $item[7];
}
# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAM_PATTERN{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{launch}{stream_objects}{$arg[0]}{pattern} = $item{PATTERN};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAM_DIR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{launch}{stream_objects}{$arg[0]}{dir} = $item{DIRECTION};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTREAM_MEM_CONN{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{launch}{stream_objects}{$arg[0]}{memConn} = $item{MEM_NAME}; 
  # pick up data type from memory object to which it is connected
  $main::CODE{launch}{stream_objects}{$arg[0]}{dataType}  
    = $main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{dataType};
  
  #extract the data width from the data type
  ($main::CODE{launch}{stream_objects}{$arg[0]}{dataWidth}  
    = $main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{dataType}) =~ s/\D//g; #extract the number
  
  #pickup memory type (addrspace qualifier) and add to stream's hash as well
  $main::CODE{launch}{stream_objects}{$arg[0]}{memConnAddrSpace}  
    = $main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{addrSpace};
  
  #Also update the hash of relevant memory object
  # pick up connStreamCount value from the hash 
  my $counter = $main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{connStreamCount};
  # update in hash
  $main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{streamConn}{$counter}{name} = $arg[0];
  $main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{streamConn}{$counter}{dir}  
    = $main::CODE{launch}{stream_objects}{$arg[0]}{dir};
        # NOTE: TODO: Requires DIR to be defined before mem connection!
  # increment counter in the hash
  $main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{connStreamCount} = $counter + 1;
  
  #now update the in/out Stream counter as well
  if ($main::CODE{launch}{stream_objects}{$arg[0]}{dir} eq 'in')
    {$main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{connInStreamCount}++;}
  else
    {$main::CODE{launch}{mem_objects}{$item{MEM_NAME}}{connOutStreamCount}++;}
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSTRM_OBJ{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {stream_objects} {$item{NAME}} {addrSpace} = $item{ADDR_SPACE_IDENT};
  
  #calculate end address of stream based on start and length
  $main::CODE{launch}{stream_objects}{$item{NAME}}{endAddr} 
  = $main::CODE{launch}{stream_objects}{$item{NAME}}{startAddr}
  + $main::CODE{launch}{stream_objects}{$item{NAME}}{length}
  - 1; 
  
  print "TyBEC: Found stream object: $item{NAME}, addrSpace = $item{ADDR_SPACE_IDENT} \n";
  
  # ------------------------------------------
  # Calculate cost of Stream Object 
  # ------------------------------------------
  # call sub-routine in Cost package; pass it: datatype, direction, size in words, addrsspace
  $main::CODE{launch}{stream_objects}{$item{NAME}}{cost} 
    = Cost::costStreamObject 
      ( $main::CODE{launch}{stream_objects}{$item{NAME}}{dataType}
      , $main::CODE{launch}{stream_objects}{$item{NAME}}{dir}
      , $main::CODE{launch}{stream_objects}{$item{NAME}}{length}
      , $item{ADDR_SPACE_IDENT} 
      , $main::CODE{launch}{stream_objects}{$item{NAME}}{stride}
      , $main::CODE{launch}{stream_objects}{$item{NAME}}{memConnAddrSpace}
    ) ;
    
  #Going on the assumption that all streams are uniform, pick up the sustained BW
  #of this stream, and give this as a parameter of the overall design
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actPORT_DIR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{ports}{$arg[0]}{port_dir} = $item[3];
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actPORT_DATA_PATTERN{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{ports}{$arg[0]}{pattern} = $item[3];
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actPORT_PIPE_STAGE{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{ports}{$arg[0]}{pipe_stage} = $item[2];
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actPORT_STREAM_OBJECT{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  #this may be a scalar or stream object; so just assign to "obj" for now for later use
  $main::CODE{ports}{$arg[0]}{obj} = $item[3];

  #$main::CODE{ports}{$arg[0]}{stream_obj} = $item[3];
    #update the hash for the port
  #$main::CODE{launch}{stream_objects}{$item[3]}{portConn} = $arg[0];
    #update the hash of the relevant streamObject (as port-streams are 1-1)
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actPORT{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{ports}{$item{NAME}}{addrSpace} = $item{ADDR_SPACE_IDENT};
  $main::CODE{ports}{$item{NAME}}{dataType} = $item{PORT_DATA_TYPE};
  
  #update the hash of the relevant streamObject OR scalarObject (as port-streams/scalars are 1-1)
  #and also update this port to ensure either stream_obj or scalar_obj is correctly updated with obj
  #if scalar object connection
  my $nameOfObj = $main::CODE{ports}{$item{NAME}}{obj};
  if (  ($main::CODE{ports}{$item{NAME}}{port_dir} eq 'iscalar')  
     || ($main::CODE{ports}{$item{NAME}}{port_dir} eq 'oscalar') ) {
     $main::CODE{ports}{$item{NAME}}{scalar_obj} = $nameOfObj;
     $main::CODE{launch}{scalar_objects}{$nameOfObj}{portConn} = $arg[0];
  }
  #otherwise assume stream object connection
  else{
    $main::CODE{ports}{$item{NAME}}{stream_obj} = $nameOfObj;
    $main::CODE{launch}{stream_objects}{$nameOfObj}{portConn} = $item{NAME};
    
    #what is the address space of the corresponding memory object (get it from the stream object)
    $main::CODE{ports}{$item{NAME}}{memConnAddrSpace} 
      = $main::CODE{launch}{stream_objects}{$nameOfObj}{memConnAddrSpace};
      
    #increment counter wordsPerTuple if this is a non-constant stream from global-memory
    $main::CODE{launch}{totalWordsToFromGmemPerStep} = $main::CODE{launch}{totalWordsToFromGmemPerStep} + 1
      if ($main::CODE{ports}{$item{NAME}}{memConnAddrSpace} == 1);
  }
  
  print  "TyBEC: Found port: $item{NAME}, $item{PORT_DATA_TYPE}, target mem addrSpace"
        ." = $main::CODE{ports}{$item{NAME}}{memConnAddrSpace} \n"; 
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actMAIN{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $hash = $main::CODE{main}; 
     # just making code less wordy. Refers to hash for main

  print "TyBEC: Found function definition of main.\n\n";
  
  # ------------------------------------------------
  # Accumulate Cost of functions called in main 
  # ------------------------------------------------

  # iterate through all instructions inside the function, and 
  # accumulate/update overall cost for the function
  # this is for future-proofing; just now TIR only 
  # allows a single function-call instruction in the main
  # all other costs related to local variables (next)
  # in any case, of multiple function are added, then simply
  # accumulation will not work esp for Latency, PropDelay etc

  foreach my $key ( keys %{$hash->{instructions}} )
  {
    $hash->{cost}{ALUTS}    += $hash->{instructions}{$key}{cost}{ALUTS}; 
    $hash->{cost}{REGS}     += $hash->{instructions}{$key}{cost}{REGS}; 
    $hash->{cost}{M20Kbits} += $hash->{instructions}{$key}{cost}{M20Kbits}; 
    $hash->{cost}{MLABbits} += $hash->{instructions}{$key}{cost}{MLABbits}; 
    $hash->{cost}{DSPs}     += $hash->{instructions}{$key}{cost}{DSPs};  
    $hash->{cost}{PropDelay}+= $hash->{instructions}{$key}{cost}{PropDelay};
    $hash->{cost}{CPI}      += $hash->{instructions}{$key}{cost}{CPI};
    $hash->{cost}{Latency}  += $hash->{instructions}{$key}{cost}{Latency};
  }#foreach 

  # this simply needs to be init to 0 for to avoid error in later accumulation
  $hash->{cost}{sustBW_Mbps} = 0;
 
  # ------------------------------------------------
  # Accumulate cost of any counters 
  # ------------------------------------------------

  # add cost of counters 
  # only resources used are added
  # since counters are part of control (not datapath)
  # so latencies, propDelay, CPI are not accumulated 
  # to main
  foreach my $key ( keys %{$hash->{counters}} )
  {
    $hash->{cost}{ALUTS}    += $hash->{counters}{$key}{cost}{ALUTS}; 
    $hash->{cost}{REGS}     += $hash->{counters}{$key}{cost}{REGS}; 
  }#foreach 


  # ------------------------------------------------
  # Accumulate cost of offset Streams 
  # ------------------------------------------------

  # only resources used are added
  # since offset Streams are not part of main datapath 
  # so latencies, propDelay, CPI are not accumulated 
  foreach my $key ( keys %{$hash->{offsetStreams}} )
  {
    $hash->{cost}{ALUTS}    += $hash->{offsetStreams}{$key}{cost}{ALUTS}; 
    $hash->{cost}{REGS}     += $hash->{offsetStreams}{$key}{cost}{REGS}; 
    $hash->{cost}{M20Kbits}     += $hash->{offsetStreams}{$key}{cost}{M20Kbits}; 
  }#foreach 

  # ------------------------------------------------
  # Update cost of LAUNCH (total cost) now that 
  # main has been parsed and costed
  # ------------------------------------------------
  # Add cost of main to already calculated EXCLUSIVE cost
  # of launch
  #foreach my $key ( keys %{$main::CODE{launch}{costExclusive}} ) {
  foreach my $key ( keys %{$main::CODE{main}{cost}} ) {
    $main::CODE{launch}{cost}{$key}  = $main::CODE{launch}{costExclusive}{$key}
                                     + $main::CODE{main}{cost}{$key};
    #   if (($key ne 'totalBits') && ($key ne 'ALMS') && ($key ne 'sustBW_Mbps'));#these do not accumulate from main (TODO ?)
  }

  #------------------------------------------------
  # reset the global counters when a function is parsed, so that they can be 
  # reused for parsing next function
  # ------------------------------------------------
  $main::insCntr = 0; 
  $main::insCntrFcall = 0; 
  $main::funCntr = 0;
  $main::argSeq = 0;
  
  # -----------------------------------------
  # Update DOT and Call graph
  # -----------------------------------------
  #$main::dotGraph->add_node('main');
  #$main::dotGraph->add_edge('launch' => 'main');  
  #$main::CODE{callGraph}{launch}{main} = {};
}#actMAIN()

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actFUNCT_ARG{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {$arg[0]} {"args"} {$main::argSeq} {name} = $item{ARG_NAME};
  $main::CODE {$arg[0]} {"args"} {$main::argSeq} {type} = $item{ARG_TYPE};
  $main::CODE {$arg[0]} {"args"} {$main::argSeq} {dir} = 'null';
    # direction will be filled with instructions are parsed
  $main::CODE {$arg[0]} {"args"} {$main::argSeq} {isOffsetStream} = 0;
   #initialize to 0. Will be updated to 1 if needed when parent function is parsed
  $main::argSeq++;
}


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actFUNCT_DECLR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{$item{FUNC_NAME}}{func_type} = $item{FUNC_TYPE};

  #having found a function, initialize the parExecInstWise hash for this function
  #as initialized is needed for dependancy analysis to work when individual instructions
  #for this function are parsed
  #this is then removed later as otherwise it causes bugs
  #$main::CODE{$item{FUNC_NAME}}{parExecInstWise}{nullkey} = -1;
  #NOTE: this has been removed as no longer needed (the dep analysis does the
  #initialization itself. Also it was causing errors,
}
 
# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actFUNCTION{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $hash = $main::CODE{$item{FUNCT_DECLR}}; 
     # just making code less wordy. Refers to hash for function under consideration

  print "TyBEC: Found function definition of $item{FUNCT_DECLR} \n"; 
  $hash->{funcName} = $item{FUNCT_DECLR}; 
    #having the name of function (i.e. the key) is useful later in code generation
    
  $hash->{instrCount} = $main::insCntr;
  $hash->{insCntrFcall} = $main::insCntrFcall;

  # ------------------------------------------------
  # iterate through all instructions inside the function, and 
  # check their destination operands to identify which writes directly to an output port 
  # this is needed for code generation
  # ------------------------------------------------   
  #initialize to no
  foreach my $key ( keys %{$hash->{instructions}} ) {
        $hash->{instructions}{$key}{writes2port} = 'no';}

  #check against arguments (ports) now
  #ignore % and @
  foreach my $key ( keys %{$hash->{instructions}} ) {
    foreach my $key2 ( keys %{$hash->{args}} ) {   
      (my $temp1 = $hash->{instructions}{$key}{operD}) =~s/[\@\%]+//g;
      (my $temp2 = $hash->{args}{$key2}{name})=~s/[\@\%]+//g;
      if( $temp1 eq $temp2 ) {
        $hash->{instructions}{$key}{writes2port} = 'yes';
        print "\n\n";
      }
        
    }
    
  # ------------------------------------------------
  # Words Per Tuple
  # ------------------------------------------------   
  # These are words that need to be loaded from memory-objects for every
  # work-item executed by this funciton.
  # Needed for cost-model for the top-level pipeline. 
  # This should typically be the same as the number of arguments passed to pipeline
  # function.
  #   TODO: There would be exceptions like constants, scalars and reduction outputs.
  #         That should be reflected here
  my @tempArr = keys %{$hash->{args}};
  $hash->{wordsPerTupleFromOrToMemoryObjects} 
    = scalar @tempArr;
  }#foreadh

  # ------------------------------------------------
  # Now that we have an instruction-wise parExec hash
  # turn it into a stage-wise hash, only including
  # the PropDelays (actual instruction reference
  # is not important
  # ------------------------------------------------
  
  #delete $hash->{parExecInstWise}{nullkey};
    #remove the nullkey init hash value now as it causes bugs

  foreach my $key ( keys %{$hash->{parExecInstWise}} ) {
    my $stage = $hash->{parExecInstWise}{$key};
      #what is the stage of this instruction?

    push @{$hash->{parExecStages}{$stage}}  , $hash->{instructions}{$key}{cost}{PropDelay};  
      #push this instruction into array for that stage
    #push @{$hash->{parExecStages}{$stage}}, $key;  
  }
  
  #also add to hash the total number of stages in the pipeline (if relevant)
  #But in case this function is a CG pipe, the following assignment is incorrect,
  #in which case the next block of code comes into play
  $hash->{nPipeStages} = keys %{$hash->{parExecStages}};
  
  #however, if this function was a CG pipe, then the number of pipeline stages
  #is the accumulation of all numbers from all children
  # loop through all, and all of them are pipelines, then add their stages up, and update nPipeStages accordingly
  # NOTE: There is no error check here for illegal mix of function types (pipe, par etc) at the
  # child level. I simply add up the total number of pipeline stages for all child pipes...
  my $pipeStagesTemp = 0;
  foreach my $key (keys %{$hash->{instructions}}) {
    if ($hash->{instructions}{$key}{instrType} eq 'funcCall') {
      if ($hash->{instructions}{$key}{funcType} eq 'pipe') {
        (my $childName = $key) =~ s/\.\d+//;
        $pipeStagesTemp += $main::CODE{$childName}{nPipeStages};
        $hash->{nPipeStages} = $pipeStagesTemp; 
      }
    }
  }#foreach


  # ------------------------------------------------
  # Initialize cost hash for this function 
  # ------------------------------------------------
  # initialization is necessary as costs are accumulated
  # in this hash
  $hash->{cost}    
    = { 'ALMS'       => 0     
      , 'ALUTS'      => 0
      , 'REGS'       => 0
      , 'M20Kbits'   => 0
      , 'MLABbits'   => 0
      , 'DSPs'       => 0
      , 'Latency'    => 0
      , 'PropDelay'  => 0
      , 'CPI'        => 0
    };
  
  # ------------------------------------------------
  # iterate through all instructions inside the function, and 
  # accumulate/update overall cost for the function
  # ------------------------------------------------   
  foreach my $key ( keys %{$hash->{instructions}} )
  {
    #### COMMON TO PIPE, PAR, COMB ######
    $hash->{cost}{ALUTS}     += $hash->{instructions}{$key}{cost}{ALUTS}; 
    $hash->{cost}{REGS}      += $hash->{instructions}{$key}{cost}{REGS}; 
    $hash->{cost}{M20Kbits}  += $hash->{instructions}{$key}{cost}{M20Kbits}; 
    $hash->{cost}{MLABbits}  += $hash->{instructions}{$key}{cost}{MLABbits}; 
    $hash->{cost}{DSPs}      += $hash->{instructions}{$key}{cost}{DSPs}; 
       
    #### COMMON TO PIPE, PAR, UNIQUE FOR COMB ######
    # PropDelay and CPI, use MAX for both PIPE and PAR 
    if (($hash->{func_type} eq 'par') || ($hash->{func_type} eq 'pipe'))
    {
      $hash->{cost}{PropDelay} = TirGrammarMod::mymax ( $hash->{cost}{PropDelay} 
                               , $hash->{instructions}{$key}{cost}{PropDelay} ); 
      $hash->{cost}{CPI}       = TirGrammarMod::mymax ( $hash->{cost}{CPI} 
                               , $hash->{instructions}{$key}{cost}{CPI} ); 
    }
    # for COMB, the iteration is over the parExecStages Block, not over instructions
    # so that happens in the succeesing loop. Just initialize here
    # Also, CPI is one, so set it here.
    elsif($hash->{func_type} eq 'comb')
    {
      $hash->{cost}{PropDelay}  = 0; #intialize
      $hash->{cost}{CPI}        = 1; #fixed by definition

    }

    #### UNIQUE FOR ALL ######
    # if PAR, latencies do NOT add; just choose the highest one
    if($hash->{func_type} eq 'par')
      {$hash->{cost}{Latency} = TirGrammarMod::mymax ( $hash->{cost}{Latency} 
                             , $hash->{instructions}{$key}{cost}{Latency} );}
    # if leaf module is PIPE, then latency is equal to the number of pipeline stages?
    elsif($hash->{func_type} eq 'pipe')
      #{$hash->{cost}{Latency} += $hash->{instructions}{$key}{cost}{Latency};}
      {$hash->{cost}{Latency} = $hash->{nPipeStages};}
    elsif($hash->{func_type} eq 'comb')
      {$hash->{cost}{Latency} = 1;}#fixed by definition 
  }#foreach 
  
  
  # ------------------------------------------------
  # Add offstream costs if applicable
  # ------------------------------------------------   
  #the division by numOffsetStreams is a hack as i assume only one of the argumenbts
  #has a stream FIXME
  if (exists $hash->{offsetStreams}){
    foreach my $key ( keys %{$hash->{offsetStreams}} ) {
      $hash->{cost}{ALUTS}    += $hash->{offsetStreams}{$key}{cost}{ALUTS} / $hash->{numOffsetStreams};
      $hash->{cost}{REGS}     += $hash->{offsetStreams}{$key}{cost}{REGS} / $hash->{numOffsetStreams};
      $hash->{cost}{M20Kbits} += $hash->{offsetStreams}{$key}{cost}{M20Kbits};
    }#foreach
  }#if


  # ------------------------------------------------
  # The PropDelay for COMB blocks is found
  # by iterating over parExecStages hash
  # (not over the instructions)
  # ------------------------------------------------   
  if($hash->{func_type} eq 'comb')
  {
    foreach my $key ( keys %{$hash->{parExecStages}} )
    {
      my $maxDelay = List::Util::max (@{$hash->{parExecStages}{$key}});
      $hash->{cost}{PropDelay} += $maxDelay;
    }#foreach
  }#if

  # ------------------------------------------------
  # check for leaf (no instructions of Fcall type)
  # calculate cost accordingly
  # ------------------------------------------------
  if($main::insCntrFcall==0)
  {
    $main::CODE{ $item{FUNCT_DECLR} } {leaf} = 'yes';
    print "TyBEC: $item{FUNCT_DECLR} is a leaf node\n";                
  }#if
  # ------------------------------------------------
  ## non-leaf nodes
  # ------------------------------------------------
  else
    {$main::CODE{ $item{FUNCT_DECLR} } {leaf} = 'no';}#else

  print "\n";
  
  # reset the main counters when a function is parsed, so that they can be 
  # reused for parsing next function
  $main::insCntr = 0; 
  $main::insCntrFcall = 0; 
  $main::funCntr = 0;
  $main::argSeq = 0;
}#actFUNCTION

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actCOUNTER_CHAINED_TO{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{$arg[0]}{counters}{$arg[1]}{chainedTo} = $item{LOCAL_VAR};
  print "TyBEC: Counter $arg[0] nested under $item{LOCAL_VAR}\n";
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actCOUNTER{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE{$arg[0]}{counters}{$item{LOCAL_VAR}}{dataType}  = $item{DATA_TYPE};
  $main::CODE{$arg[0]}{counters}{$item{LOCAL_VAR}}{start}     = eval($item{C_START});
  $main::CODE{$arg[0]}{counters}{$item{LOCAL_VAR}}{end}       = eval($item{C_END});
  #$main::CODE{$arg[0]}{counters}{$item{LOCAL_VAR}}{chainedTo} = 'null';

  print "TyBEC: Found counter $item{LOCAL_VAR}\n"; 
  
  # ------------------------------------------
  # Update cost of counter 
  # ------------------------------------------
  $main::CODE{$arg[0]}{counters}{$item{LOCAL_VAR}}{cost}     
    = { 'ALMS'      => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{ALMS}          
      , 'ALUTS'     => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{ALUTS}    
      , 'REGS'      => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{REGS}     
      , 'M20Kbits'  => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{M20Kbits} 
      , 'MLABbits'  => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{MLABbits} 
      , 'DSPs'      => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{DSPs}     
      , 'Latency'   => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{Latency}  
      , 'PropDelay' => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{PropDelay}
      , 'CPI'       => $Cost::costI{counter}{$item{DATA_TYPE}}{ver0}{CPI}      
      };


}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actOFFSET_STREAM{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
    
  $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {sourceStream}= $item{LOCAL_VAR2};
  $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {dataType}    = $item{DATA_TYPE};
  $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {offsetDir}   = $item{PLUS_OR_MINUS};
  $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {offsetDist}  = eval($item{EXPRESSION});
  
  #Update the MAX *positive* offset stream, if applicable, as that effects throughput estimate
  #------
  
  #initialize
  if (!(exists $main::CODE {$arg[0]} {maxPositiveOffset})) {
  $main::CODE {$arg[0]} {maxPositiveOffset} = 0; }
  
  #update if needed
  if  (   ($item{PLUS_OR_MINUS} eq '+')  
      &&  (   $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {offsetDist} 
          > $main::CODE {$arg[0]} {maxPositiveOffset} )              ){
    $main::CODE {$arg[0]} {maxPositiveOffset} 
      = $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {offsetDist};
  }#if

  #also update hash of relevant port on which this offset is based
    #NOTE: TODO: this assumes that offsets are only created at the MAIN, which 
    #connects directly to the streamobjects in Manage-IR. This should be changed to 
    #functions further down the hierarchy to create local offsets
  #$main::CODE{ports}{$item{NAME}}{offSets}{$item{LOCAL_VAR}}{dataType}    = $item{DATA_TYPE};
  #$main::CODE{ports}{$item{NAME}}{offSets}{$item{LOCAL_VAR}}{offsetDir}   = $item{PLUS_OR_MINUS};
  #$main::CODE{ports}{$item{NAME}}{offSets}{$item{LOCAL_VAR}}{offsetDist}  = $item{INTEGER};
  
  #also update hash of relevant argument (i.e. local port) on which this offset is based
  #since args are hashed by their sequence (not their name), so we have to loop over
  #the argumetns to catch the matchign name
  foreach my $key (keys %{$main::CODE{$arg[0]}{args}} ) {
    my $name = $main::CODE{$arg[0]}{args}{$key}{name};
    #if the name of an argument matches the source of offset stream
    if($name eq $item{LOCAL_VAR2}) {
      $main::CODE{$arg[0]}{args}{$key}{offSets}{$item{LOCAL_VAR}}{dataType}    = $item{DATA_TYPE};
      $main::CODE{$arg[0]}{args}{$key}{offSets}{$item{LOCAL_VAR}}{offsetDir}   = $item{PLUS_OR_MINUS};
      $main::CODE{$arg[0]}{args}{$key}{offSets}{$item{LOCAL_VAR}}{offsetDist}  = eval($item{EXPRESSION});
      
      #update number of offset streams for this arg
      if (!(exists $main::CODE{$arg[0]}{args}{$key}{numOffsetStreams})) {
        $main::CODE{$arg[0]}{args}{$key}{numOffsetStreams} = 1;}
      else {
        $main::CODE{$arg[0]}{args}{$key}{numOffsetStreams} += 1;}
      #hack!
      $main::CODE{$arg[0]}{numOffsetStreams} = $main::CODE{$arg[0]}{args}{$key}{numOffsetStreams};
      print "TyBEC: Found offset stream for port $item{LOCAL_VAR2} \n";
      
      #update max POS streams for this arg
      if (!(exists $main::CODE{$arg[0]}{args}{$key}{maxPositiveOffset})) {
        $main::CODE{$arg[0]}{args}{$key}{maxPositiveOffset} = 0; }
      if  (   ($item{PLUS_OR_MINUS} eq '+')  
      &&  (   $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {offsetDist} 
          > $main::CODE{$arg[0]}{args}{$key}{maxPositiveOffset} )              ){
        $main::CODE{$arg[0]}{args}{$key}{maxPositiveOffset} 
          = $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {offsetDist};
      }

      #update max NEG streams for this arg
      if (!(exists $main::CODE{$arg[0]}{args}{$key}{maxNegativeOffset})) {
        $main::CODE{$arg[0]}{args}{$key}{maxNegativeOffset} = 0; }
      if  (   ($item{PLUS_OR_MINUS} eq '-')  
      &&  (   $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {offsetDist} 
          > $main::CODE{$arg[0]}{args}{$key}{maxNegativeOffset} )              ){
        $main::CODE{$arg[0]}{args}{$key}{maxNegativeOffset} 
          = $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {offsetDist};
      }
      
    #each offset stream needs to know how many other "peer" streams (other offsets with same source)
    #are present. This is needed in costing.
    #$main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {numTotalPeerStreams}  
    #  = $main::CODE{$arg[0]}{args}{$key}{numOffsetStreams};
    }#if   
  }#foreach
  


 
  #------------------------------------
  # update cost of offsetStreams buffer
  # -----------------------------------
  # call sub-routine in Cost package; pass it: type, offset Distance (size in words)
  # FIXME: Since a single offstream object is created for muliple offsets of same stream, so 
  #         the cost should be accumulated such that no incorrect repetitions in accumulation
  $main::CODE {$arg[0]} {offsetStreams} {$item{LOCAL_VAR}} {cost} 
    = Cost::costOffsetStream( $item{DATA_TYPE}, eval($item{EXPRESSION}) );  
}  


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actCALLED_FUNCT_ARG{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {$arg[0]} {instructions} 
              {$arg[1].".".$main::funCntr} 
              {args2child} {$main::argSeq2} {name} 
                = $item{ARG_NAME};

  $main::CODE {$arg[0]} {instructions} 
              {$arg[1].".".$main::funCntr} 
              {args2child} {$main::argSeq2} {type} 
                = $item{ARG_TYPE};

  # pick up direction of called argument from 
  # hash entry for child function <<<<--- NOTE REQUIRES CHILD DEFINITION TO APPEAR FIRST IN CODE
  # matching to child argument is done by position (not name!)
  $main::CODE {$arg[0]} {instructions} 
              {$arg[1].".".$main::funCntr} 
              {args2child} {$main::argSeq2} {dir} 
                = $main::CODE{$arg[1]}{args}{$main::argSeq2}{dir};


  # if direction of port is output, then it means this is the destination operand
  # ONLY RELEVANT for comb functions which have only one output by definition
  # (pipe functions can have multiple outputs)
  if ($main::CODE{$arg[1]}{args}{$main::argSeq2}{dir} eq 'output') {
    $main::CODE{$arg[0]}{instructions}{$arg[1].".".$main::funCntr}{operD} =  $item{ARG_NAME}; }
    

  # pick up name of port in child to which this port is connected
  $main::CODE {$arg[0]} {instructions} 
              {$arg[1].".".$main::funCntr} 
              {args2child} {$main::argSeq2} {nameChildPort} 
                = $main::CODE{$arg[1]}{args}{$main::argSeq2}{name};
   # ----------------------------------------
   # WHERE APPLICABLE
   # Set port directions for caller function
   # based on Called function port directions
   # ----------------------------------------
   #iterate through all arguments of the caller function, 
   #and check if it matches any argument of called function
   #if so, set direction of parent port based on dir of child port
   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} )
   {
     # first confirm if port direction (parent) has not already been assigned
     if ($main::CODE{$arg[0]}{args}{$key}{dir} eq 'null') 
     {
       #if argument to child function matches an argument of parent function
       #then pick up direction from child function signature, and assign to parent's
       if ($item{ARG_NAME} eq $main::CODE{$arg[0]}{args}{$key}{name})
       { $main::CODE{$arg[0]}{args}{$key}{dir} 
           = $main::CODE{$arg[1]}{args}{$main::argSeq2}{dir};
       }
     }
   }

   $main::argSeq2++;
 }#CALLED_FUNCT_ARG:

 
# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actFUNC_CALL_INSTR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
   $main::CODE {$arg[0]} {instructions}    
               { $item{CALLEE_FUNC_NAME}.".".$main::funCntr} {instrType}      ='funcCall';
   $main::CODE {$arg[0]} {instructions}    
               { $item{CALLEE_FUNC_NAME}.".".$main::funCntr} {instrSequence}  =  $main::insCntr;
   $main::CODE {$arg[0]} {instructions}    
               { $item{CALLEE_FUNC_NAME}.".".$main::funCntr} {funcType}       = $item{FUNC_TYPE};
   $main::CODE {$arg[0]} {instructions}    
               { $item{CALLEE_FUNC_NAME}.".".$main::funCntr} {funcName}       = $item{CALLEE_FUNC_NAME};
   $main::CODE {$arg[0]} {instructions}    
               { $item{CALLEE_FUNC_NAME}.".".$main::funCntr} {funcRepeatCounter}= $main::funCntr;
   
   print "TyBEC: $item{CALLEE_FUNC_NAME} called by $arg[0]\n";

   # reset counter that was sequencing
   # the position of argumetns in called function
   $main::argSeq2 = 0;

   # ----------------------------------------------------------------------
   # Dependancy Analysis
   # If flag is set (relevant for COMB blocks only)
   # then call func to find parallel blocks (AUTO_PARALLELIZE_COMB)
   # ----------------------------------------------------------------------
   if( ($main::autoParallelize) && ($arg[0] ne 'main'))
     {TirGrammarMod::dependAnalysisFunc($arg[0], "$item{CALLEE_FUNC_NAME}."."$main::funCntr" );}
 
   
  # -------------------------------------------------------------
  # When CALLER is MAIN
  # CHECK if argument passed to child is an OFFSET STREAM
  # -------------------------------------------------------------
  # check arguments passed to function called (which would be the
  # top level pipe
  # compare then with local offsetStreams created in Main
  # if any match, then go to hash of child function, and 
  # update the argument property of the relevant argument
  # to indicate that the argument is an offsetStream stream (not to be generated for LMEM i.e.)
  
  my $childCall = "$item{CALLEE_FUNC_NAME}".".0"; #reduce clutter. this is e.g. funcName.0 in the main
  (my $childFunc = $childCall) =~ s/\.\d+//; #extract function name from function-call hash 
   
  if($arg[0] eq 'main') {
    #go the 0th function call of child function (which is the only on main as per allowed syntax
    #and iterate through the arguments passed to it
    print "childCall = $childCall\n";
    foreach my $key (keys %{$main::CODE{main}{instructions}{$childCall}{args2child}} ) {
      #now iterate through each offset stream, and compare against each argument
      foreach my $key2 (keys %{$main::CODE{main}{offsetStreams}} ) {
        #compare argument to child, against offstream variable, and enter if found
        if ($main::CODE{main}{instructions}{$childCall}{args2child}{$key}{name} eq $key2) {

          #get the name of port in child Function
          my $childPort = $main::CODE{main}{instructions}{$childCall}{args2child}{$key}{nameChildPort};
          
          #go the hash of child function, and set the argument property 
          #accordingly for this argument/port in the child's hash
          #as args in child hash function are keyed by sequence (rather than by name)
          #so we will have to loop through the entire args hash to find the right childPort
          foreach my $key3 (keys %{$main::CODE{$childFunc}{args}} ) {
            if ($main::CODE{$childFunc}{args}{$key3}{name} eq $childPort) {
              $main::CODE{$childFunc}{args}{$key3}{isOffsetStream} = 1;
              $main::CODE{$childFunc}{args}{$key3}{offsetStreamNameInMain} = $key2;
              $main::CODE{$childFunc}{args}{$key3}{offsetSourceStream} = $main::CODE{main}{offsetStreams}{$key2}{sourceStream};
            }#if
          }#foreach
        }#if
      }#foreach 
    }#foreach
  }#if($arg[0] eq 'main') {
   
   
  #### ALL ANALYSIS MOVED TO analyze() ####  
   
   # -------------------------------------------------------------
   # When CALLER is MAIN
   # Check for cPIPE or cPAR
   # -------------------------------------------------------------
   # in case of main, check whether the top-level function(s) called is pipe or par
   # and update counter for number of pipes at main level
   # main is parsed last so only set cofiguration if it hasnt been set already

   #check if in main()
   #if ($arg[0] eq 'main')
   #{
     #top is pipe
     #if ($item{FUNC_TYPE} eq 'pipe') 
     #{
       #print "TyBEC: Found **top level PIPE** function $item{CALLEE_FUNC_NAME} in main \n";
       #$main::Npipes++;
       #$main::pipeTop = $item{CALLEE_FUNC_NAME};
       #$main::desConf = 'cPIPE' if ($main::desConf eq 'null');
         #main is parsed last
         #update config only if not already determined by a previous parse
     #}

     #top is par
     #elsif ($item{FUNC_TYPE} eq 'par') 
     #{
     #  print "TyBEC: Found **top level PAR** function $item{CALLEE_FUNC_NAME} in main \n";
       #$main::parTop = $item{CALLEE_FUNC_NAME};
       #$main::desConf = 'cPAR' if ($main::desConf eq 'null');
         #main is parsed last
         #update config only if not already determined by a previous parse
     #}

     # top is neither par nor pipe - error 
     #else 
     #  {die "$main::dieConfigMsg\n";}
       #{}
   #}
#
   # -------------------------------------------------------------
   # Check for cPAR_PIPE and cPAR_PIPEs_COMBs
   # -------------------------------------------------------------
   # if previous parse set conf to cPIPE_PARs, and you find a PAR
   # calling a PIPE, then then the config is cPAR_PIPE_PARs
   # however, if a PAR is calling PIPE and previous parse has NOT
   # found a PAR inside the PIPE, then the config is cPAR_PIPE only

   # so first check that if a PAR is calling PIPE
   #elsif ( ($main::CODE{$arg[0]}{func_type} eq 'par') && ($item{FUNC_TYPE} eq 'pipe') )                    
   #{
     #increment count of number of pipes in the config
     #$main::Npipes++;

     #check that all pipes are identical (no other configuration allowed)
     #if( ($main::pipeSecond ne 'null') && ($main::pipeSecond ne $item{CALLEE_FUNC_NAME}) )
     #  {die "$main::dieNotSamePipesMsh\n";}
     #else
     #  {$main::pipeSecond = $item{CALLEE_FUNC_NAME};}
     
     # check if a previous parse has not already determined config
     # to be cPAR_PIPEs_PARs or cPAR_PIPEs_COMBs or cPAR_PIPEs <<<<<here..
     # this is because there will be multiple pipes inside the par, and
     # the first call to the pipe function will set the config correctly.  
     # if (   ($main::desConf ne 'cPAR_PIPEs_PARs') 
     #    &&  ($main::desConf ne 'cPAR_PIPEs_COMBs') 
     #    &&  ($main::desConf ne 'cPAR_PIPEs')    )
     # {
     #   # has a previous parse already found PARs inside PIPE ?
     #   # this means it is PAR->PIPEs->PARs
     #   if  ( $main::desConf eq 'cPIPE_PARs' ) 
     #     {$main::desConf = 'cPAR_PIPEs_PARs';}
     #   # has a previous parse already found COMBs inside PIPE ?
     #   # this means it is PAR->PIPEs->COMBs
     #   elsif  ( $main::desConf eq 'cPIPE_COMBs' ) 
     #     {$main::desConf = 'cPAR_PIPEs_COMBs';}
     #   # otherwise, it is a PAR calling a primitive (flat) PIPE, 
     #   else
     #     {$main::desConf = 'cPAR_PIPEs';}
     # }
   #}

   # if PAR is calling anything BUT a PIPE, it is invalid configuration
   #elsif ($main::CODE{$arg[0]}{func_type} eq 'par')
   #  {die "$main::dieConfigMsg\n";}
    #{}
                        
   
   
   # -------------------------------------------------------------
   # Check for cPIPE_PAR and cPIPE_COMB and cPIPE_PIPE
   # -------------------------------------------------------------
   # in case this caller is a PIPE function (may be top level or second level), 
   # and it is calling a PAR or COMB function
   # >>>>>>>>>>>>>>> TODO::: <<<<<<<<<<<<<
   # The PIPE_PAR should be redundant as I no longer am explicitly using PAR blocks inside PIPES
   # as the ILP is automatically extracted.
   #    BUT: may be useful to retain for future purposes
   
 #   elsif ($arg[0] ne 'main') # first check this is not main
 #   {
 #     # check that pipe called par
 #     # so config is either CONG_PAR_PIPE_PAR/COMB or cPIPE_PAR/COMB
 #     # set to cPIPE_PAR here, as we can't confirn cPAR_PIPE_PAR until further parsing
 #     if ($main::CODE{$arg[0]}{func_type} eq 'pipe') {
 #       if ($item{FUNC_TYPE} eq 'par') {
 #         print "TyBEC: Found a PAR block inside a pipe block\n";
 #         # check if the pipe that called par is a top level function
 #         $main::desConf = 'cPIPE_PARs';
 #       }
 #       elsif ($item{FUNC_TYPE} eq 'comb') {
 #         print "TyBEC: Found a COMB block inside a pipe block\n";
 #         $main::desConf = 'cPIPE_COMBs';
 #         #update hash of the PIPE function to indicate that the called          
 #       }
 #       elsif ($item{FUNC_TYPE} eq 'pipe') {
 #         print "TyBEC: Found a PIPE block inside a pipe block\n";
 #         $main::desConf = 'cPIPE_PIPEs';
 #      }
 #       # only PAR, COMB or PIPE allowed inside a pipe (i.e. no SEQ)
 # 
 #       else {
 #        die "$main::dieConfigMsg\n";}
 #     }
 #   }#elsif

   # ------------------------------------------
   # Calculate cost of instruction 
   # ------------------------------------------
   # pick up the cost of function call instruction from the
   # calculated cost of called (child) function
   $main::CODE{$arg[0]}{instructions}{$item{CALLEE_FUNC_NAME}.".".$main::funCntr}{cost}
     = { 'ALMS'      => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{ALMS}       
       , 'ALUTS'     => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{ALUTS}      
       , 'REGS'      => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{REGS}       
       , 'M20Kbits'  => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{M20Kbits}   
       , 'MLABbits'  => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{MLABbits}   
       , 'DSPs'      => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{DSPs}       
       , 'Latency'   => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{Latency}    
       , 'PropDelay' => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{PropDelay}  
       , 'CPI'       => $main::CODE{$item{CALLEE_FUNC_NAME}}{cost}{CPI}        
       };

   # ------------------------------------------
   # increment required counters over detection of a valid
   # function call instruction
   # ------------------------------------------
   $main::funCntr++;
   $main::insCntr++;
   $main::insCntrFcall++;
 }#FUNC_CALL_INSTR
 
# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actSELECT_INSTR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
   if ($item{OP_TYPE2} ne $item{OP_TYPE3})
     {die "TyBEC **ERROR**: Type of operands compared in a select instruction must be same";}

   $main::CODE {$arg[0]} {instructions} {$item{OPER_DEST}} 
     =  {  'destType'     => $item{DEST_TYPE}
        ,  'operPred'     => $item{PRED_OPER}
        ,  'operTrue'     => $item{TRUE_OPER}
        ,  'operFalse'    => $item{FALSE_OPER}
        ,  'op'           => $item{OP_SELECT}
        ,  'opType'       => $item{OP_TYPE1}
        ,  'instrType'    => "select"
        ,  'instrSequence'=> $main::insCntr  
        };

   $main::insCntr++;
   print "TyBEC: Select instruction found in $arg[0]\n";      

   # ----------------------------------------------------------------------
   # Dependancy Analysis
   # If flag is set (relevant for COMB and PIPE blocks only, but computed for all - no harm done!)
   # then call func to find parallel blocks (AUTO_PARALLELIZE_COMB)
   # ----------------------------------------------------------------------
   if( ($main::autoParallelize) )#&& ($main::CODE{$arg[0]}{func_type} eq 'comb') )
     {TirGrammarMod::dependAnalysis( $arg[0], $item{OPER_DEST}, $item{PRED_OPER}, $item{TRUE_OPER}, $item{FALSE_OPER} ); }

   # ------------------------------------------
   # Calculate cost of instruction 
   # ------------------------------------------
   $main::CODE{$arg[0]}{instructions}{$item{OPER_DEST}}{cost}     
     = { 'ALMS'      => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{ALMS}          
       , 'ALUTS'     => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{ALUTS}    
       , 'REGS'      => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{REGS}     
       , 'M20Kbits'  => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{M20Kbits} 
       , 'MLABbits'  => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{MLABbits} 
       , 'DSPs'      => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{DSPs}     
       , 'Latency'   => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{Latency}  
       , 'PropDelay' => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{PropDelay}
       , 'CPI'       => $Cost::costI{select}{2}{$item{OP_TYPE2}}{ver0}{CPI}      
       }; 
 }

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actCOMPARE_INSTR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
   $main::CODE {$arg[0]} {instructions} {$item{OPER_DEST}} 
     =  {  'destType'     => $item{DEST_TYPE}
        ,  'oper1'        => $item{OPER1}
        ,  'oper2'        => $item{OPER2}
        ,  'op'           => $item{OP_COMPARE}
        ,  'opType'       => $item{OP_TYPE}
        ,  'instrType'    => "compare"
        ,  'instrSequence'=> $main::insCntr  
        };

   $main::insCntr++;
   print "TyBEC: Compare instruction found in $arg[0]\n";  

   # ------------------------------------------
   # Calculate cost of instruction 
   # ------------------------------------------
   $main::CODE{$arg[0]}{instructions}{$item{OPER_DEST}}{cost} = 
   {'ALMS'=> $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{ALMS}          
   , 'ALUTS'    => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{ALUTS}    
   , 'REGS'     => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{REGS}     
   , 'M20Kbits' => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{M20Kbits} 
   , 'MLABbits' => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{MLABbits} 
   , 'DSPs'     => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{DSPs}     
   , 'Latency'  => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{Latency}  
   , 'PropDelay'=> $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{PropDelay}
   , 'CPI'      => $Cost::costI{$item{OP_COMPARE}}{$item{TYPE_COMPARE}}{$item{OP_TYPE}}{ver0}{CPI}      
   }; 

   # ----------------------------------------------------------------------
   # Dependancy Analysis
   # If flag is set (relevant for COMB blocks only)
   # then call funct to find parallel blocks (AUTO_PARALLELIZE_COMB)
   # ----------------------------------------------------------------------
   if( ($main::autoParallelize) ) #&& ($main::CODE{$arg[0]}{func_type} eq 'comb') )
     {TirGrammarMod::dependAnalysis($arg[0], $item{OPER_DEST}, $item{OPER1},$item{OPER2});}

 }

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actREDUX_INSTR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
   $main::CODE {$arg[0]} {instructions} {$item{GLOBAL_VAR}} 
     =  {  'destType'     => $item{DEST_TYPE}
        ,  'oper1'        => $item{OPER1}
        ,  'oper2'        => $item{OPER2}
        ,  'operD'        => $item{GLOBAL_VAR}
        ,  'op'           => $item{OP}
        ,  'opType'       => $item{OP_TYPE}
        ,  'instrType'    => "reduction"
        ,  'instrSequence'=> $main::insCntr  
        };
        # the parExecInstWise is 0 by default 
   
   #since this is reduction instruction, so one of the operands is the same as the 
   #destination. Check which one, and add keys to identify this distinction
   #as later needed in code generation
   
   $main::insCntr++;
   print "TyBEC: Reduction instruction found in $arg[0]\n";
   
    #since this is reduction instruction, so one of the operands is the same as the 
    #destination. Check which one, and add keys to identify this distinction
    #as later needed in code generation
    #we need to keep track of which operand is NOT the accumulator, as the other
    #is identified by the dest operand anyway
    if($item{GLOBAL_VAR} eq $item{OPER1}) {
      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{operNotAcc} =  $item{OPER2}; }
    elsif($item{GLOBAL_VAR} eq $item{OPER2}) {
      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{operNotAcc} =  $item{OPER1}; }
    #at least one oper should match operD. Othewise this is not a legal REDUX  instruction
    else
      {die "TyBEC-ERROR: If destination is global variable, this is considered a REDUCTION/ACCUMULATION operation, and that means one of the source operands must be the same as the destination operand\n";}
    

   # ----------------------------------------------------------------------
   # Dependancy Analysis
   # If flag is set (relevant for COMB blocks only)
   # then call func to find parallel blocks (AUTO_PARALLELIZE_COMB)
   # ----------------------------------------------------------------------
   if( ($main::autoParallelize) )#&& ($main::CODE{$arg[0]}{func_type} eq 'comb') )
     {TirGrammarMod::dependAnalysis($arg[0], $item{GLOBAL_VAR}, $item{OPER1},$item{OPER2});}

   # ----------------------------------------
   # Set port directions for caller function
   # ----------------------------------------
   #iterate through all arguments of the caller function, and check
   #if it should be set to output or input based on if it matches a LHS operand
   #and set their direction
   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} )
   {
     # first check tp confirm if the argument has not already been set by a previous
     # parse over another instruction. 
     if ($main::CODE{$arg[0]}{args}{$key}{dir} eq 'null') 
     {
       # if argument matches destination operand of this instruction
       if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{GLOBAL_VAR})
         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'output';}
       # if argument matches a source operand of this instruction
       elsif (   ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER1}) 
             ||  ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER2}) )
         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'input';}
       else
         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'null';}
     }
   }
   
   # --------------------------------------------------------
   # Check if any input operand is a direct port connection 
   # --------------------------------------------------------
   # this information is later needed for code generation
   
   #iterate through all arguments of the caller function, and check
   #if it matches operand 1 (only relevant for input ports)
   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} ) {
    if (  ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER1}) 
       && ($main::CODE{$arg[0]}{args}{$key}{dir} eq 'input')        ){
      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper1form} = 'inPort';
    }#if
    #if the property oper1form does not exist, it means it can safely be defined is
    #local type, as we are sure no previous iteration has detected as inPort already
    elsif (!(exists $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper1form})) {
      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper1form} = 'local';
    }
   }#foreach
   
   #same for operand 2
   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} ) {
    if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER2}) {
      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper2form} = 'inPort';
    }#if
    elsif (!(exists $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper2form})) {
      $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper2form} = 'local';
    }
   }#foreach
   
   # --------------------------------------------------------
   # Check if any input operand is an offset Stream
   # --------------------------------------------------------
   # this information may be  needed for code generation
   # TODO...
   
   # ------------------------------------------
   # Calculate cost of instruction 
   # ------------------------------------------
   # call sub-routine in Cost package; pass it: type, addrSpace, size in words
   # TODO: The Macro needs to be translated into value here... SO DO SECOND PASS FIRST!
   #$main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{cost}
   #          = Cost::costComputeInstruction($item{OP_TYPE}, $item{OP}); 
             
   $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{cost}
             = Cost::costComputeInstruction(
                $item{OP_TYPE}
              , $item{OP}
              , $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper1form}
              , $main::CODE{$arg[0]}{instructions}{$item{GLOBAL_VAR}}{oper2form}
             );              
 }#REDUX INSTRUCTION

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actCOMPUTE_INSTR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
   $main::CODE {$arg[0]} {instructions} {$item{LOCAL_VAR}} 
     =  {  'destType'     => $item{DEST_TYPE}
        ,  'oper1'        => $item{OPER1}
        ,  'oper2'        => $item{OPER2}
        ,  'operD'        => $item{LOCAL_VAR}
        ,  'op'           => $item{OP}
        ,  'opType'       => $item{OP_TYPE}
        ,  'instrType'    => "compute"
        ,  'instrSequence'=> $main::insCntr  
        };
        # the parExecInstWise is 0 by default 

        
   $main::insCntr++;
   $main::glComputeInstCntr++;
   print "TyBEC: Compute instruction found in $arg[0]\n";

   # ----------------------------------------------------------------------
   # Dependancy Analysis
   # If flag is set (relevant for COMB blocks only)
   # then call func to find parallel blocks (AUTO_PARALLELIZE_COMB)
   # ----------------------------------------------------------------------
   if( ($main::autoParallelize) )#&& ($main::CODE{$arg[0]}{func_type} eq 'comb') )
     {TirGrammarMod::dependAnalysis($arg[0], $item{LOCAL_VAR}, $item{OPER1},$item{OPER2});}

   # ----------------------------------------
   # Set port directions for caller function
   # ----------------------------------------
   #iterate through all arguments of the caller function, and check
   #if it should be set to output or input based on if it matches a LHS operand
   #and set their direction
   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} )
   {
     # first check tp confirm if the argument has not already been set by a previous
     # parse over another instruction. 
     if ($main::CODE{$arg[0]}{args}{$key}{dir} eq 'null') 
     {
       # if argument matches destination operand of this instruction
       if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{LOCAL_VAR})
         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'output';}
       # if argument matches a source operand of this instruction
       elsif (   ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER1}) 
             ||  ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER2}) )
         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'input';}
       else
         { $main::CODE{$arg[0]}{args}{$key}{dir} = 'null';}
     }
   }
   
   # --------------------------------------------------------
   # Check if any input operand is a direct port connection
   # --------------------------------------------------------
   # this information is later needed for code generation
   
   #iterate through all arguments of the caller function, and check
   #if it matches operand 1
   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} ) {
    if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER1}) {
      $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form} = 'inPort';
    }#if
    #if the property oper1form does not exist, it means it can safely be defined is
    #local type, as we are sure no previous iteration has detected as inPort already
    elsif (!(exists $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form})) {
      $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form} = 'local';
    }
   }#foreach
   
   #same for operand 2
   foreach my $key ( keys %{$main::CODE{$arg[0]}{args}} ) {
    if ($main::CODE{$arg[0]}{args}{$key}{name} eq $item{OPER2}) {
      $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form} = 'inPort';
    }#if
    elsif (!(exists $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form})) {
      $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form} = 'local';
    }
   }#foreach
   
   # --------------------------------------------------------
   # Check if any of the operands is constant
   # --------------------------------------------------------
   if ($item{OPER1} =~ /^-?\d+$/) {
     $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form} = 'constant';
   }
   if ($item{OPER2} =~ /^-?\d+$/) {
     $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form} = 'constant';
   }

   # --------------------------------------------------------
   # Check if any input operand is an offset Stream
   # --------------------------------------------------------
   # this information may be  needed for code generation
   # TODO...
   
   # ------------------------------------------
   # Calculate cost of instruction 
   # ------------------------------------------
   # call sub-routine in Cost package; pass it: type, addrSpace, size in words
   # TODO: The Macro needs to be translated into value here... SO DO SECOND PASS FIRST!
   $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{cost}
             = Cost::costComputeInstruction(
                $item{OP_TYPE}
              , $item{OP}
              , $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper1form}
              , $main::CODE{$arg[0]}{instructions}{$item{LOCAL_VAR}}{oper2form}
             ); 
 }#COMPUTE_INSTR

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actASSIGN_INSTR{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {$arg[0]} {"instructions"} { $item{OPER_DEST} }
    = { 'destType'  => $item{DEST_TYPE}
      , 'oper1'     => $item{OPER1}
      , 'opType'    => $item{OP_TYPE}
      , 'op'        => "assign"
      , 'instrType' => "assign"
      };

  $main::insCntr++;
  print "TyBEC: Assign instruction found in $arg[0]\n";
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actCALL_MAIN{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  print "TyBEC: Found call to main() in launch module.\n"; 
  $main::CODE{launch}{call2main}{kIterSize} = 1;
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actBLMEM_TR_SIZE_MDATA{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {blockMemCpyInstrs} {$main::insCntr} {trSizeWords} = $item{INTEGER};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actBLMEM_DEST_ADDR_MDATA{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {blockMemCpyInstrs} {$main::insCntr} {destStartAddr} = $item{INTEGER};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actBLMEM_SRC_ADDR_MDATA{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {launch} {blockMemCpyInstrs} {$main::insCntr} {srcStartAddr} = $item{INTEGER};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actBLOCK_MEM_COPY{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  print "TyBEC: Found Block Memory Copy instruction in Launch: $item{NAME2} --> $item{NAME1}\n";
  $main::CODE{launch}{blockMemCpyInstrs}{$main::insCntr}{dest}        = $item{NAME1};
  $main::CODE{launch}{blockMemCpyInstrs}{$main::insCntr}{src}         = $item{NAME2};
  $main::insCntr++; 
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actCALL_MAIN_IN_REPEAT{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  print "TyBEC: Found call to main() inside a repeat block in  launch module.\n";
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actREPEAT{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  # update Kernel Iterator parameters here
  $main::CODE{launch}{call2main}{kIter}       = $item{NAME};
  $main::CODE{launch}{call2main}{kIterStart}  = $item{INTEGER1};
  $main::CODE{launch}{call2main}{kIterEnd}    = $item{INTEGER2};
  $main::CODE{launch}{call2main}{kIterSize}   = $item{INTEGER2}-$item{INTEGER1}+1;
}


# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actLAUNCH{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  my $hash = $main::CODE{launch}; 
  #reduce clutter
  print "TyBEC: Found launch module.\n\n";
  
  # -------------------------------
  # Initialize 
  # -------------------------------
  $main::CODE {launch} {costExclusive}    
  = { 'ALMS'       => 0     
    , 'ALUTS'      => 0
    , 'REGS'       => 0
    , 'M20Kbits'   => 0
    , 'MLABbits'   => 0
    , 'DSPs'       => 0
    , 'Latency'    => 0
    , 'PropDelay'  => 0
    , 'CPI'        => 0
  };
  
  $main::CODE{launch}{hostComm}{from} = 0;
  $main::CODE{launch}{hostComm}{to}   = 0;
  $main::CODE{launch}{hostComm}{toFrom}   = 0;
  
  $main::CODE{launch}{gMemComm}{to}   = 0;
  $main::CODE{launch}{gMemComm}{from} = 0;
  $main::CODE{launch}{gMemComm}{toFrom}   = 0;

  # -------------------------------
  # Accumulate cost of MEM OBJs
  # -------------------------------
  ## Iterate through all MEM_OBJECTS to accumulate cost 
  foreach my $key ( keys %{$hash->{mem_objects}} )
  {
    #iterate over all cost parameters
    foreach my $key2 ( keys %{$hash->{mem_objects}{$key}{cost} } )
    {
      $hash->{costExclusive}{$key2} += $hash->{mem_objects}{$key}{cost}{$key2} 
        if ($hash->{mem_objects}{$key}{cost}{$key2} ne 'null');#don't accumulate null values
    }
  }
  
  # ----------------------------------------------------------
  # Accumulate RESOURCE and COMMUNICATION cost of STREAM OBJs
  # ----------------------------------------------------------
  #init. sustBW as min has to be picked
  $hash->{costExclusive}{sustBW_Mbps} = 1000000000; #inf

  #iterate over all stream objects
  foreach my $key ( keys %{$hash->{stream_objects}} ) {    
    #iterate over all cost parameters
    foreach my $key2 ( keys %{$hash->{stream_objects}{$key}{cost} } )
    {
      #don't accumulate sustained BW, just pick up the lowest 
      #But make sure you leave out any streams with sust bandwidth = -1
      #that is just indicating this stream is not relevant (constant stream e.g.)
      if ($key2 eq 'sustBW_Mbps') {
        $hash->{costExclusive}{$key2} = mymin($hash->{costExclusive}{$key2}, 
                                              $hash->{stream_objects}{$key}{cost}{$key2})
          if($hash->{stream_objects}{$key}{cost}{$key2} > 0);                 
      }#if
      
      #accumulate all other costs
      else {
      $hash->{costExclusive}{$key2} += $hash->{stream_objects}{$key}{cost}{$key2}
        if ($hash->{stream_objects}{$key}{cost}{$key2} ne 'null'); #don't accumulate null values
      }#else
    }#foreach 
    
    #accumulate total data transferred between host-device over streams
    my $totalBits = $hash->{stream_objects}{$key}{cost}{totalBits};
    $hash->{hostComm}{toFrom} += $totalBits;

    #separately record against in and out too, in case needed
    if ($hash->{stream_objects}{$key}{dir} eq 'in') {
      $hash->{hostComm}{from} += $totalBits; }
    else {
      $hash->{hostComm}{to} += $totalBits; }   
  }
  
  # FIXME: I am recording it for BOTH host and gMEM..only one will be used dependong on memory-exec type
  $hash->{gMemComm}{to}     = $hash->{hostComm}{to}    ;
  $hash->{gMemComm}{from}   = $hash->{hostComm}{from}  ;
  $hash->{gMemComm}{toFrom} = $hash->{hostComm}{toFrom};
  
  #reset instruction counter that was counting number of mem copy instructions in launch
  $main::insCntr=0;
  
  # -----------------------------------------
  # Accumulate cost of MEM COPY instructions 
  # -----------------------------------------
  
  # -----------------------------------------
  # Cost of Compute_Core (MAIN) accumulated
  # when main is parsed
  # -----------------------------------------
  
  # -----------------------------------------
  # Update DOT and CALL_GRAPH
  # -----------------------------------------
  #$main::dotGraph->add_node('launch');
  #$main::CODE{callGraph}{launch} = {};
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------
sub actDEFINE_STATEMENT{
  my @item = @{shift(@_)};
  my %item = %{shift(@_)};
  my @arg  = @{shift(@_)};
  
  $main::CODE {"macros"} {$item{NAME}} = $item[4]; 
  print "TyBEC: Found macro $item{NAME} = $item[4]\n";
}

# ============================================================================
# GRAMMAR STRING
# ============================================================================

# --------------------------------
# >>>> Load Grammar file
# --------------------------------
my $grammarFileName = "$TyBECROOTDIR/lib-intern/TirGrammarString.pm"; 
open (my $fhTemplate, '<', $grammarFileName)
 or die "Could not open file '$grammarFileName' $!";     
 
# --------------------------------
# >>>> Read 
# --------------------------------
our $grammar = read_file ($fhTemplate);
 close $fhTemplate;
