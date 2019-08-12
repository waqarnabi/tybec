#!/usr/bin/perl -w
use 5.012; # so readdir assigns to $_ in a lone while test
 

# =============================================================================
# Company      : Unversity of Glasgow, Comuting Science
# Author:        Syed Waqar Nabi
# 
# Create Date  : 2014.12.26
# Project Name : TyTra
#
# Dependencies : See ./README.txt
#               
# Revision     :  ** Tybec-17 **
#                   See ../TyBEC_Releases/ for releases 
#                    (the README in the latest version will have info for all
#                     previous releases)
# 
# Conventions  : 
# =============================================================================
#
# =============================================================================
# General Description and Notes
# -----------------------------------------------------------------------------
# 1. A parser for lower TIR
#
# 2. ******** THIS IS TIR-17 version. See ./RELEASE for more details.
#
# TODOs and NOTEs:
# =================
#
#  - Search for "TODO"  and "NOTE" 
# =============================================================================

#----------------------
#Environment Variables:
#----------------------
# Make sure these are set:
# TyBECROOTDIR="directory-of-this-script"
# PERL5LIB="$TyBECROOTDIR/lib-intern:$TyBECROOTDIR/lib-extern"

# ----------------------
# TyBEC RELEASE
# ----------------------
our $tybecRelease = 'R17.0';

# ============================================================================
# GENERIC MODULES
# ============================================================================
# NOTE: All generic, 3rd party perl modules I use are always "brough along" with the code
# in ./lib-extern. So you need to ensure that it is on your PERL path. (generally PERL5LIB)
# Similarly all custom modules I wrote for TyBEC are in lib-intern, and that path needs 
# to be included as well.

use strict;
use warnings;
use Parse::RecDescent;  #the parser module
# Enable warnings within the Parse::RecDescent module.
$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.

use Regexp::Common;     #generate common regexs from this utility
use Tree::DAG_Node;     #for generating call trees
use Data::Dumper;
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use List::Util qw(min max);
use Getopt::Long;   #for command line options
use IO::Tee; #muxign output to STDOUT and Log file
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
		      clock_gettime clock_getres clock_nanosleep clock
                      stat);
use GraphViz; 
use Term::ANSIColor qw(:constants);

use feature "state";
use IO::File;
use File::Slurp;
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);

use List::Util qw(min max);

use Graph;

use JSON;

# ----------------------
# TyBEC specific modules
# ----------------------
use Cost;             #read cost database and functions from Cost.pm
use HardwareSpecs;    #specification of target hardware
use TirGrammarMod;    #the module with callbacks for grammar
use HdlCodeGen;       #codeGenerator (dataflow implemented in Verilog HDL) functions
use OclCodeGen_aocl;  #OCL wrapper code for AOCL
use OclCodeGen_sdx;   #OCL wrapper code for SDx

# ============================================================================
# GRAMMAR
# ============================================================================
use TirGrammarMod;       #read Grammar from TirGrammarMod.pm

# ============================================================================
# START TIMER
# ============================================================================
my $start = Time::HiRes::gettimeofday();

# ============================================================================
# GLOBALS 
# ============================================================================
#hash for storing ALL parsed tokens in the TIR
our %CODE; 

#hash for compiling result in a batch job scenario
our %BATCH;

#function call graph
our %callGraph;

our $BODY; 

our $funCntr;       #counter to keep track of multiple calls to same function
our $insCntr;       #counter for number of instructions in a function
our $glComputeInstCntr; #counter for total number of GLOBAL compute intructions (all functions).
our $insCntrFcall;      #counter for number of function_call instructions in a function
our $argSeq;       #counter for sequence number of arguments in a function definition
our $argSeq2;      #counter for sequence number of arguments in a called function instruction
our $NparPipes;     #total number of parallel (top-level) pipes

our $topFuncKey  ; #top func key in any configuration
our $topFuncType ;
our $topFuncName ;
our $topPipeKey;    #Name of top-level PIPE in any config that has pipe (if it is CG, it is same is below)
our $topCGpipeKey;  #name of the top CG pipe in cPipe_PipeA or cPar_PipeS_PipeA 
our $desConfigNew;  #what is the overall configuration of the design-- NEW VERSION
our $designFail;    #does the design meet resource and IO constraints?

# error messages
our $dieConfigMsg = "TyBEC: **Illegal Configuration!**: Allowed configurations are:\n\tmain->pipe \n\tmain->par \n\tmain->pipe->par(s) \n\tmain->par->pipe(s) \n\tmain->par->pipe(s)->par(s)";
our $dieNotSamePipesMsh = "TyBEC: **Illegal Configuration!**: All concurrent pipelines must be symmetrical"; 

#global array used to temporarily store split-inputs/merge-outputs, which can be arbitrary
#in number so we need to push them on an array and assign back to the relevant hash later
our @split_outs;
our @merge_ins;

our $latency_pipe_top; 
our $stages_pipe_top;

#The tuple annotated with the dot DFG generated can be verbose or not...
our $VERBOSE_DFG_ANNOT=0;

# Command Line
# ------------------------------------

# default options
our $inputFileTirl = "file.tirl"; #input TIRL file
our $lambdaTxtFile = "lambda.txt"; #default lambda function file name
our $outputBuildDir = './TybecBuild';
our $outFPGACode ; 
our $outputRTLDir;
our $outputTbDir ;
our $outputSimDir;
our $outputOCLDir;

#our $outputRTLDir = './hdlGen/rtl';
#our $genCodeDir = './genFPGACode';
#our $outputOCLDir = './oclGen';
our $debug = '';
our $batch = '';
our $c2llvm2tir = '';
our $batchChild = '';
our $autoParallelize = 1;
our $help = '';
our $showVer = '';
our $genRTL = '';
our $estimate = '';
our $dot = '';
our $targetNode  = "awsf12x"; 
#our $targetNode  = "bolamaNallatech"; 
our $targetBoard = $HardwareSpecs::nodes{$targetNode}{boardName};
our $targetDevice= $HardwareSpecs::boards{$targetBoard}{deviceName};
our $lambda="";
our $lambdaTxt="";
our $ioVect=1;
our $oclKernelPipe='';

#Which OCX template version are you using?
#ver 1 is the default baseline
#ver 8 uses e.g. coalesced inputs

our $coalIOs = 1; #should I coalesce IOs?
our $ocxTempVer; #template to use, depends on coalIO or not


# Files
# ------------------------------------ 
our $tree;
our $treeChild;
our $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};
our $infh;
our $outfh;
our $outfh_json;
our $logFilename;
our $batchfh;
our $batchLogFilename;
our $tee;        
our $dotfh;
our $dotFilename;
our @lines;
our $fhinputpp;
our $estfh;


# Graphs
# ------------------------------------ 
our $dfGraph;
our $dfGraphDot;
our $dfgcluster ;
our $legendcluster;
our $notescluster;
our $dotGraph;

# parser
# ------------------------------------ 
our $parser;


# ============================================================================
# ::: MAIN :::: Call TyBEC subroutines
# ============================================================================
init(); 
batch() if($batch);
#c2llvm2tir() if($c2llvm2tir);
preprocess();
parse(); #always parse
estimate()    if($estimate);
generateHDL() if($genRTL);
generateOCL() if($genRTL);
post();

#schedule();
#analyze(); #always analyze
#estimate() if($estimate);

#ENDOF ::: MAIN :::: 



# ****************************************************************************
#                   *****   SUB ROUTINES for tybec.pl *****
# ****************************************************************************
# ============================================================================
# Utility routines
# ============================================================================
sub mymax ($$) { $_[$_[0] < $_[1]] }
sub mymin ($$) { $_[$_[0] > $_[1]] }
sub roundOne  {
  my $point = shift;
  $$point = (int($$point*10+0.5))/10;
}

sub roundTwo  {
  my $point = shift;
  $$point = (int($$point*100+5))/100;
}

# ============================================================================
# Pre-Processor  + GCC Pre-Processor
# ============================================================================
# This is ugly (having a macro parser as well as a GCC Pre-Processor.. TODO
sub preprocess{
$parser->MACROS("@main::lines") or die "Parser Macro rule failed!"; 

my $tempMacExpFile = "temp.tirl";
system("gcc -E -x c -P $inputFileTirl > $outputBuildDir/$tempMacExpFile");

open($fhinputpp, "<", "$outputBuildDir/$tempMacExpFile")
  or die "Could not open file '$tempMacExpFile' $!";
}

# ============================================================================
# INITIALIZE()
# ============================================================================
sub init{  
  print("******************************************************************\n");
  print("TyBEC $tybecRelease\n");
  print("******************************************************************\n");

  # Initializing global variables
  # -------------------
  $CODE{launch}{wordsPerTuple} = 0;
  $funCntr = 0;
  $insCntr = 0;
  $glComputeInstCntr = 0;
  $insCntrFcall = 0;
  $NparPipes = 0;
  $argSeq = 0;
  $argSeq2 = 0;
  $stages_pipe_top = 0;
  $latency_pipe_top = 0;  
  $designFail = 0;

  #reset instruction counter
  $insCntr=0;
  
  #command-line
  #--------------
  GetOptions (
      'clt'   => \$c2llvm2tir       #--tybec has been called by c2llvm2tir tool (don't expose this option to command line user)
    , 'd'     => \$debug            #--debug
    , 'batch' => \$batch            #--batch <run estimator on all .tirl files in folder with default options>
    , 'i=s'   => \$inputFileTirl    #--i    <input TIRL FILE>
    , 'obd=s' => \$outputBuildDir   #--obd  <output Build Directory>
    #, 'ord=s' => \$outputRTLDir     #--ord  <output director for RTL code generated>
    , 'help'  => \$help             #--h    <Display help>
    , 'v'     => \$showVer          #--v    <Show current TyBEC release version>
    , 'g'     => \$genRTL           #--g    <Generate RTL code>
    , 'e'     => \$estimate         #--e    <Estimate Resources and Performance from TIRL>
    , 'dot'   => \$dot              #--dot  <Run DOT and display graph at the end of compile>
    
    
    , 'batchChild' => \$batchChild  #--batchChild used internally by parent script of batch job to call childs and 
                                    # and indicate they are part of a batch job, so that they compile key results to parent LOG
    , 'tar'     => \$targetBoard     #--target  <Name of target board>
    , 'lambda' => \$lambda          # You are providing lambda function to create cpu baseline
    , 'iov=s'  => \$ioVect          # Degree of IO vectorization (coalescing)
    , 'op'     => \$oclKernelPipe   #Should I create the kernel (CG) pipeline in OCL
    , 'cio'    => \$coalIOs         #Should I coalesce IOs? (makes OCS integration simpler)
    );
  
  print "\n";
  print "=====================================\n";
  print "       TARGET HARDWARE               \n";
  print "=====================================\n";

  print "TyBEC: Target node is\t: $targetNode\n";
  print "TyBEC: Target board is\t: $targetBoard\n";
  print "TyBEC: Target device is\t: $targetDevice\n";
  #my $hash = $main::CODE{top}; 

  
  #-------------------------------
  #non-standard termination points
  #-------------------------------
  #Display help
  if($help) {
    printHelp();
    exit;
  }
  #Show version
  if($showVer) {
    printVer();
    exit;
  }

  #if batch
  if($batch) {
    batch();
    exit;
  }

  #invalid command line arguments
  if  (  ($ioVect!=1)
      && ($ioVect!=2)
      && ($ioVect!=4)
      && ($ioVect!=8)
      && ($ioVect!=16)
      ) {
    print("TyBEC: INVALID IO vectorization width\n");
    exit;
  }
  
  #-------------------------------
  #standard run
  #-------------------------------
  
  #choose template version for OCX/HDL 
  
  #used for FPODE, with SDX v2017.4
  $ocxTempVer = 't01' if($coalIOs == 0); 
  
  #"t08"; #used for Hindawi, with SDX v2018.2, coalesced inputs, and coalesced outputs
  $ocxTempVer= 't09'  if($coalIOs == 1);  

  
  print "\n";
  print "=====================================\n";
  print "       SETUP                 \n";
  print "=====================================\n";
  print "TyBEC: CPU baseline code for comparison selected\n" if($lambda);
    
  #files and io
  #--------------  
  #Root directory for TyBEC scripts
  $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};
  
  #make targe directories if not present
  make_path($outputBuildDir);
  
  #other output directories in the build tree
  $outFPGACode  ="$outputBuildDir/genFPGACode/$targetNode"; 
  
  #target directory structure depends on target node
  if($targetNode eq 'awsf12x') {
    $outputRTLDir ="$outFPGACode/src/hdl";
    $outputTbDir  ="$outFPGACode/src/testbench";
    $outputSimDir ="$outFPGACode/src/sim";
    $outputOCLDir ="$outFPGACode";
  } 
  elsif($targetNode eq 'bolamaNallatech') {
    $outputRTLDir ="$outFPGACode/rtl";
    $outputTbDir  ="$outFPGACode/testbench";
    $outputSimDir ="$outFPGACode/sim";
    $outputOCLDir ="$outFPGACode/ocl";
  }
  else {die "Illegate target node definition\n";}
  
  #open input TIRL file
  open($infh, "<", $inputFileTirl)
    or die "Could not open file '$inputFileTirl' $!";
    
  #Read input TIRL contents; remove comments while reading
  @lines = grep { /#.*/ } <$infh>; 

  #read in lambda.txt file if applicable    
  $lambdaTxt=read_file($lambdaTxtFile) if($lambda);
  
  #Create tokens.log (tokens parsed from TIRL are written this file)
  $logFilename = "tokens.log";
  open($outfh, '>', "$outputBuildDir/$logFilename")
    or die "Could not open file '$logFilename' $!";
    
  #Create tokens.json as well
  $logFilename = "tokens.json";
  open($outfh_json, '>', "$outputBuildDir/$logFilename")
    or die "Could not open file '$logFilename' $!";
    
  
  #estimates.log 
  my $estFilename = "estimates.csv";
  open($estfh, '>', "$outputBuildDir/$estFilename")
    or die "Could not open file '$estFilename' $!";


  ##batch file if this is a batchChild
  #if($batchChild) {
  #  $batchLogFilename = "batchEstimates.csv";
  #  open($batchfh, '>>', "$outputBuildDir/../../$batchLogFilename")
  #      or die "Could not open file '$batchLogFilename' $!";
  #}
  
  # Printing to LOG and STDOUT
  # ----------------------------
  $tee = new IO::Tee(\*STDOUT, new IO::File(">$outputBuildDir/build.log"));        
  select $tee;        
  
  # DOT.png
  # ----------------------------
  if($dot) {
    $dotFilename = "DOT.png";
    open($dotfh, '>', "$outputBuildDir/$dotFilename")
      or die "Could not open file '$dotFilename' $!";
  }
  close $infh; 
  
  # Create Dataflow Graph
  # ----------------------------
  $dfGraph    = Graph->new(multiedged => 1);  # A directed abstract graph, with multiedges enabled 
  
  #my $g0 = Graph->new(countedged => 1);
  #my $g0 = Graph->new(multiedged => 1);
  
  $dfGraphDot = GraphViz->new();        # DOT visualization of the same graph
  
  #define cluster for DFG
  $dfgcluster = {
      name      =>'DFG',
      style     =>'',
      fillcolor =>'',
      fontname  =>'',
      fontsize  =>'',
  };
  
  #add legend
  $legendcluster = {
      name      =>'Legend',
      style     =>'filled',
      fillcolor =>'lightyellow',
      fontname  =>'',
      fontsize  =>'',
  };
  $dfGraphDot -> add_node ('Impl Memory (SSA)'    , shape => 'ellipse'        , cluster => $legendcluster);
  $dfGraphDot -> add_node ('Function-call Instr'  , shape => 'box3d'          , cluster => $legendcluster);
  $dfGraphDot -> add_node ('Expl Memory (alloca)' , shape => 'box'            , cluster => $legendcluster);
  $dfGraphDot -> add_node ('Functional argument'  , shape => 'invhouse'       , cluster => $legendcluster);
  $dfGraphDot -> add_node ('Plain  argument'      , shape => 'invtriangle'    , cluster => $legendcluster);
  $dfGraphDot -> add_node ('Autoindex'            , shape => 'hexagon'        , cluster => $legendcluster);
  $dfGraphDot -> add_node ('Smache-offset'        , shape => 'doubleoctagon'  , cluster => $legendcluster);
  
  #add notes
  $notescluster = {
      name      =>'Notes',
      style     =>'filled',
      fillcolor =>'lightpink',
      fontname  =>'',
      fontsize  =>'',
  };
  
  my $text;
  if ($VERBOSE_DFG_ANNOT == 1){
    $text = "5 attributes: (latency, actual-firing-interval, local-firing-interval, external-firing-interval, firings-per-output, starding delay)
    That is: (LAT, AFI, LFI, EFI, FPO, SD)\n\n";
  }
  else                              {
    $text = "2 attributes: (latency AND local-firing-interval a.k.a clocks-per-output))
    That is: (LAT, LFI)\n\n";
  }
  
  $dfGraphDot -> add_node (
  "
  1. The external-labels on the nodes is a tuple showing these $text
  2. Edges can refer to both explicit and implicit streams.
    Implicit: The source.destination label on the edge matches *both* the source and destination nodes.
    Explicit: The source.destination label does not match *one of* the source or destination node. The part that does not match on the edge-label refers to the explicit stream\n\n
  "         
    , shape => 'note'    , cluster => $notescluster);

  # Create DOT graph (call-tree)
  # ----------------------------
  $dotGraph = GraphViz->new();

  # Create Parser
  # ----------------------------
  $parser = Parse::RecDescent->new($TirGrammarMod::grammar);  

}#init()

# ============================================================================
# BATCH()
# ============================================================================
#if batch job, create a folder for each file, run the script for it in that folder
#-------------
sub batch{
  $batchLogFilename = "batchEstimates.csv";
  #print "$outputBuildDir/../$batchLogFilename\n";
  #overWrite
  open($batchfh, '>', "./$batchLogFilename")
      or die "Could not open file '$batchLogFilename' $!";

  my @allFiles = <*.tirl>;
  
  print "TyBEC: Running in BATCH mode. All TIRL files in current folder will be compiled\n";
  print "WARNING: Previous build folders in the current directory will be deleted if you continue\n";
  print "Are you sure you wish to continue? (y/n) \n";

  chomp (my $yesno = <>);
  if($yesno eq 'n') {exit;}
  
  #remove all directories in current folder
  system("rm batchEstimates.log");
  
  #Write estimates.log (and batchEstimates.log if applicable)
  #----------------------------------------------------------
  #NOTE: These ***MUST*** be in the same sequence as the entries made at the end
  #of the call to estimate() for each batch child
  print $batchfh "                                          ,         \n";
  print $batchfh "PARAMETER                                 ,UNITS    \n";
  print $batchfh "Performance                               ,GBop/sec \n";
  print $batchfh "Frequency                                 ,MHz      \n";
  print $batchfh "alutsTotal                                ,         \n";
  print $batchfh "regsTotal                                 ,         \n";
  print $batchfh "bramTotal                                 ,         \n";
  print $batchfh "dspTotal                                  ,         \n";
  print $batchfh "Host sust' BW                             ,Mbps     \n";
  print $batchfh "Gl-Mem sust' BW                           ,Mbps     \n";
  print $batchfh "Size of 1 input array (n_gs)              ,         \n";
  print $batchfh "Firing interval/II (n_to)                 ,         \n";
  print $batchfh "Total word operations per kernel (n_wops) ,         \n";
  print $batchfh "Words per tuple (from GMEM)      (w_pt)   ,         \n";
  print $batchfh "Size of problem (array size in words)     ,         \n";
  print $batchfh "Word size in bits (w_s_bits)              ,         \n";
  print $batchfh "Bytes per word (b_pw)                     ,         \n";
  print $batchfh "Kernel Pipeline  Latency (k_pd)           ,         \n";
  print $batchfh "CP of one PE                              ,GBops/sec\n";
  print $batchfh "CP of one PE (Asymptotic)                 ,GBops/sec\n";
  print $batchfh "Theoretical maximum PE scaling            ,         \n";
  print $batchfh "Computation-Bound: CP_PE  x SCALE         ,GBops/sec\n";
  print $batchfh "Bandwidth-Bound:   CI x BW                ,GBops/sec\n";
  print $batchfh "Computational Intensity                   ,ByOP/ByTR\n";
  print $batchfh "alutsKernel                               ,         \n";
  print $batchfh "regsKernel                                ,         \n";
  print $batchfh "bramKernel                                ,         \n";
  print $batchfh "dspKernel                                 ,         \n";
  print $batchfh "alutsBasePlat                             ,         \n";
  print $batchfh "regsBasePlat                              ,         \n";
  print $batchfh "bramBasePlat                              ,         \n";
  print $batchfh "dspBasePlat                               ,         \n";

  close($batchfh);
  
  for my $oneFile (@allFiles) {
    my $tDir = $oneFile."_build";    
    
    system("rm -r $tDir");
    system("mkdir $tDir");
    
    system("cp $oneFile $tDir");
    chdir $tDir;

    system("tybec.pl --i $oneFile --batchChild");
    chdir "..";
  }#for
  
  ##print compiled results HASH
  #my $batchLogFilename = "batch.log";
  #open(my $batchfh, '>', "$batchLogFilename")
  #  or die "Could not open file '$batchLogFilename' $!";
  #print $batchfh Dumper(\%BATCH);
  #close $batchfh;
  
  my $end = Time::HiRes::gettimeofday();
  printf("\nThis batch build took %.2f seconds\n", $end - $start);
  #exit;
}


# ============================================================================
# PARSE() (and schedule)
# ============================================================================
sub parse {
  @lines = grep { not /;.*/ } <$fhinputpp>; #remove comments while reading file
  
  print "\n";
  print "=====================================\n";
  print "       Running TyBEC Parser          \n";
  print "=====================================\n";
  
  $parser->STARTRULE("@lines") or die "Parser start rule failed!"; 
}

# ============================================================================
# ESTIMATE()
# ============================================================================
sub estimate {
  print "============================================================================\n";
  print " Running the Cost Model (Performance and Resource Estimates)       \n";
  print "============================================================================\n\n"; 
 
  print "Target node is   : $targetNode\n";
  print "Target board is  : $targetBoard\n";
  print "Target device is : $targetDevice\n\n"; 
  
  my $topKernel = $CODE{main}{topKernelName};
  $topKernel =~ s/\_\d+$//;
  
  my $ninputs   = $CODE{$topKernel}{ninputs};
  my $noutputs  = $CODE{$topKernel}{noutputs};
  my $w_pt      = $ninputs + $noutputs;
  print ">>>>>>>>>>>>>>>>>> $ninputs, $noutputs, $w_pt\n";
    #Words per tuple from GMEM (in and out) TODO: This should not be hardwired  
  my $dtype     = $CODE{$topKernel}{synthDtype};
  (my $dWidthBits= $dtype) =~ s/\D+//;
  my $dWidthByes = $dWidthBits/8;
  
  print "\n";
  print "----------------------------------------------------------------------------\n";
  print " BANDWIDTH ESTIMATES \n";
  print "----------------------------------------------------------------------------\n";

  #device operating frequency
  my $f_mhz = (1/$CODE{main}{resource}{propDelay}) * 1000;
  roundOne(\$f_mhz);
  my $f_hz  = $f_mhz * (1e6) ;
  print "TyBEC: f  = $f_mhz MHz $f_hz Hz\n";
  
  #host and gmem sustained bandwidth
  my $h_pb_Mbps= ($HardwareSpecs::boards{$main::targetBoard}{hostBW_Peak_Mbps});     
  my $rho_h   = 1.0;                                                              
  my $h_sb_Mbps= $h_pb_Mbps * $rho_h;
  
  my $g_pb_Mbps= $HardwareSpecs::boards{$main::targetBoard}{boardRAMBW_Peak_Mbps};  
  my $rho_g   = 0.57; #TODO:: link this to mp-stream... this is a typical value for strided, non-vectorized access
  my $g_sb_Mbps= $g_pb_Mbps * $rho_g;
  my $g_sb_MBps= $g_pb_Mbps * $rho_g / 8;
  roundOne(\$g_sb_MBps);
  

  print "TyBEC: host peak_Mbps  = $h_pb_Mbps Mbps\n";
  print "TyBEC: host sust Mbps  = $h_sb_Mbps Mbps\n";
  print "TyBEC: mem  peak Mbps  = $g_pb_Mbps Mbps\n";
  print "TyBEC: mem  sust Mbps  = $g_sb_Mbps Mbps\n";
  
  print "\n";
  print "----------------------------------------------------------------------------\n";
  print " RESOURCE ESTIMATES (Kernel & Shell) \n";
  print "----------------------------------------------------------------------------\n";

  my $alutsKernel = $CODE{main}{resource}{aluts};
  my $regsKernel  = $CODE{main}{resource}{regs} ;
  my $bramKernel  = $CODE{main}{resource}{bram} ;
  my $dspKernel   = $CODE{main}{resource}{dsps} ;

  my $alutsPercentKernel  = 100*($alutsKernel/ $HardwareSpecs::devices{$targetDevice}{aluts});
  my $regsPercentKernel   = 100*($regsKernel / $HardwareSpecs::devices{$targetDevice}{regs});
  my $bramPercentKernel   = 100*($bramKernel / $HardwareSpecs::devices{$targetDevice}{bram}  );
  my $dspPercentKernel    = 100*($dspKernel  / $HardwareSpecs::devices{$targetDevice}{dsps});
  roundTwo(\$regsPercentKernel );
  roundTwo(\$dspPercentKernel  );
  roundTwo(\$alutsPercentKernel);
  roundTwo(\$bramPercentKernel );
   
  #read in cost of base platform from hash returned from cost function
  my $inputGmemStreams = $w_pt-1;  #number of input streams of ONE PE
  my $costBasePlat_ref = Cost::costBasePlatform ( 'ui32' , $inputGmemStreams, 1 , 1);
  my %costBasePlat = %$costBasePlat_ref;

  my $alutsBasePlat= $costBasePlat{aluts};
  my $regsBasePlat = $costBasePlat{regs} ;
  my $bramBasePlat = $costBasePlat{bram} ;
  my $dspBasePlat  = 0                   ;
  
  my $alutsPercentBasePlat = 100* ($alutsBasePlat/ $HardwareSpecs::devices{$targetDevice}{aluts});
  my $regsPercentBasePlat  = 100* ($regsBasePlat / $HardwareSpecs::devices{$targetDevice}{regs}) ;
  my $bramPercentBasePlat  = 100* ($bramBasePlat / $HardwareSpecs::devices{$targetDevice}{bram}) ;
  my $dspPercentBasePlat   = 100* ($dspBasePlat  / $HardwareSpecs::devices{$targetDevice}{dsps}) ;
  roundTwo(\$alutsPercentBasePlat);
  roundTwo(\$regsPercentBasePlat );
  roundTwo(\$bramPercentBasePlat );
  roundTwo(\$dspPercentBasePlat  );  
  
  #accumulate these costs into the total along with the Kernel costs
  my $alutsTotal = $alutsBasePlat+ $alutsKernel;
  my $regsTotal  = $regsBasePlat + $regsKernel ;
  my $bramTotal  = $bramBasePlat + $bramKernel ;
  my $dspTotal   = $dspBasePlat  + $dspKernel  ;
  
  my $alutsPercentTotal= $alutsPercentKernel+ $alutsPercentBasePlat;
  my $regsPercentTotal = $regsPercentKernel + $regsPercentBasePlat ;
  my $bramPercentTotal = $bramPercentKernel + $bramPercentBasePlat ;
  my $dspPercentTotal  = $dspPercentKernel  + $dspPercentBasePlat  ;
  
  print "\n";
  print "::KERNEL::\n";
  print "TyBEC: aluts = $alutsKernel ($bramPercentKernel %)\n";
  print "TyBEC: regs  = $regsKernel  ($alutsPercentKernel %)\n";
  print "TyBEC: bram  = $bramKernel  ($dspPercentKernel %)\n";
  print "TyBEC: dsp   = $dspKernel   ($regsPercentKernel %)\n";

  print "\n";
  print "::SHELL::\n";
  print "TyBEC: aluts = $alutsBasePlat ($alutsPercentBasePlat %)\n";
  print "TyBEC: regs  = $regsBasePlat  ($regsPercentBasePlat %)\n";
  print "TyBEC: bram  = $bramBasePlat  ($bramPercentBasePlat %)\n";
  print "TyBEC: dsp   = $dspBasePlat   ($dspPercentBasePlat %)\n";
  
  print "\n";
  print "::TOTAL::\n";
  print "TyBEC: aluts = $alutsTotal ($alutsPercentTotal %)\n";
  print "TyBEC: regs  = $regsTotal  ($regsPercentTotal %)\n";
  print "TyBEC: bram  = $bramTotal  ($bramPercentTotal %)\n";
  print "TyBEC: dsp   = $dspTotal   ($dspPercentTotal %)\n";
  
  print "\n";
  print "----------------------------------------------------------------------------\n";
  print " ROOFLINE ANALYSIS                                                           \n";
  print "----------------------------------------------------------------------------\n";
  
  #ASSUMPTION: that any input array can be used as represengint size (and data type) of all
  #input arrays
  
  my $n_wops  = $glComputeInstCntr;
  my $w_s_bits= $dWidthBits;
  my $b_pw    = $w_s_bits/8;
  my $n_gs    = $main::CODE{main}{bufsize}; #Size of array
  my $n_to    = $CODE{main}{performance}{afi}; 
    #Latency per instruction, or Firining Interval, or (loop) Initiation Interval
  my $d_v     = 1; 
    #TODO: This shouldnt be hardwired. Also, with tybec-17, this should be OBSOLETE
  my $k_pd    = $CODE{main}{performance}{lat}; 
    #The kernel depth (effectively, the overall latency): TODO: not hardwired!

  print "TYBEC: Size of 1 input array (n_gs)              = $n_gs\n";
  print "TYBEC: Firing interval/II (n_to)                 = $n_to\n";
  print "TYBEC: Total word operations per kernel (n_wops) = $n_wops\n";
  print "TYBEC: Words per tuple (from GMEM)      (w_pt)   = $w_pt\n";
  print "TYBEC: Size of problem (array size, words)       = $n_gs\n";
  print "TYBEC: Word size in bits (w_s_bits)              = $w_s_bits\n";
  print "TYBEC: Bytes per word (b_pw)                     = $b_pw\n";
  print "TYBEC: Kernel Pipeline  Latency (k_pd)           = $k_pd\n";
  
  
  my $cp_pe_Bops_asympt = ($f_hz / $n_to) * $n_wops * $b_pw * $d_v; 
    #This is the asymptotic performance (ignoring latency)
    #See JPDC paper for this
    
  my $cp_pe_Bops = ($f_hz * $n_gs * $n_wops * $b_pw)
                 / ($k_pd + $n_to * $n_gs )
                 ;
    #This takes into account the latency as well...`
    #See Google-keep #tybec17 for this (snapshot)
    
  my $cp_pe_asympt_GBops  = $cp_pe_Bops_asympt * 1e-9;
  my $cp_pe_GBops         = $cp_pe_Bops        * 1e-9;
  roundOne(\$cp_pe_asympt_GBops);
  roundOne(\$cp_pe_GBops);
  print "\n";
  print "TyBEC: CP of one PE              = $cp_pe_GBops GBops/sec\n";
  print "TyBEC: CP of one PE (Asymptotic) = $cp_pe_asympt_GBops GBops/sec\n";
  
  #Scaling factor of THIS variant (how many PE replications? / how many kernel pipelines)
  # This should change when I involve splits and merges
  #---------------------------------------------------------------------------------------
  # OBSOLETE?
    #Think about how relevant this is for tybec17: shouldn't split/merge
    #take care of this automatically
  my $thisScaling   = 1; #TODO: This shouldnt be hardwired
  my $cp_pe_Bops_s  = $cp_pe_Bops * $thisScaling;
  my $cp_pe_GBops_s = $cp_pe_Bops_s * 1e-9;
  roundOne(\$cp_pe_GBops_s);

  
  #print "TyBEC: PE scaling of THIS variant    = $thisScaling\n";
  #print "TyBEC: CPof scaled PEs (this variant)= $cp_pe_GBops_s GBops/sec\n";

  #Maximum Theorotical Computational Power when PEs scaled to maximum possible
  #---------------------------------------------------------------------------
  #The maximum scaling is limited by the one (of four) resource that has maximum percentage utilization
  #Since the Base-platform is assumed to be unaffected by the scaling, so *one any given resource"
  #the maximum scaling can be extracted from this expression:
  # Rbp + SCm.Rka < 100
  #  where Rbp = Percentage resource consumption of  base platform
  #        SCm = max scaling
  #        Rka = Resource consumpion in the kernel for resource type A
  # Turning this into an equality for the limit:
  # SCm = (100-Rbp)/Rka
  # If we want to limit scaling to 85% (tool/physical limitation), then it becomes
  # SCm = (85-Rbp)/Rka  <----- (1)
  # We calculate (1) for all 4 resources, and then pick the minumum of that:
  #print "targetDevice = $targetDevice\n";



  #print "alutsPercentBasePlat=$alutsPercentBasePlat and $CODE{main}{resource}{bram}\n";
  my $SCm_aluts = (85-$alutsPercentBasePlat)/$alutsPercentKernel;
  my $SCm_regs  = (85-$regsPercentBasePlat)/$regsPercentKernel;
  my $SCm_bram  = (85-$bramPercentBasePlat)/$bramPercentKernel;
  my $SCm_dsp   = (85-$dspPercentBasePlat) /$dspPercentKernel;
    
  my $maxScaling =  min ( $SCm_aluts
                     , $SCm_regs 
                     , $SCm_bram 
                     , $SCm_dsp  
                     ); 
                     
  roundOne(\$maxScaling);
                     
  my $cp_pe_Bops_smax  = $cp_pe_Bops_s * $maxScaling;
  my $cp_pe_GBops_smax = $cp_pe_Bops_smax * 1e-9;
  
  
  print "\n";
  print "TyBEC: Theoretical maximum PE scaling         = $maxScaling\n";

  #Computational Intensity
  #---------------------------
  #CI = (word-ops-per-kernel * bytes-per-word-op) / (words-per-in-out-tuple * bytes-per-word)
  #      bytes-per-word cancel out...
  my $ci =  $n_wops/$w_pt;
  roundOne(\$ci);
  print "\n";
  print "TyBEC: Computational Intensity = $ci Byte-op/Byte-trasfer\n";

  #Bandwidth
  #---------------------------
  my $peakTheoBW_GBps = ($HardwareSpecs::boards{$main::targetBoard}{boardRAMBW_Peak_GBps});
  #BW = max bytes per second to/from memory (for ROOF, this is peak, for CEIL we use sustainable based on design)
  my $bw     = $g_sb_MBps * 1e6; #Mbytes-per-sec
  my $bw_M   = $g_sb_MBps; #Mbytes-per-sec
  my $bw_G   = $bw_M * 1e-3;
  roundOne(\$bw_G);
  my $ci_bw     = $ci * $bw;
  my $ci_bw_G   = $ci_bw * 1e-9;
  roundOne(\$ci_bw_G);
   

  my $xATcpRoof = $cp_pe_Bops_s / $bw; #the value of CI where the two roofs meet, 

  print "\n";
  print "TyBEC: Sustained Memory Bandwidth (this variant)         = $bw_G GB/sec\n";
  print "TyBEC: Theoretical Peak Memory Bandwidth (chosen target) = $peakTheoBW_GBps GB/sec\n";
  print "\n";

  #Final Performance
  #---------------------------
  #PERF (BYTE-OPS-PERSEC) = min (CP_PE*scale, CI*BW)
  my $p_bops = min($cp_pe_Bops_s, $ci_bw);
  my $p_Gbops = $p_bops * 1e-9;
  roundOne(\$p_Gbops);
  #my $p_Gbops_round = (int($p_Gbops*10+0.5))/10;
  
  #print "TyBEC: The BOPS/sec performance is the minimum of CP_PE (Computational Performance Roof) and CI*BW (Computational Intensity x Bandwidth)\n";
  print "\n";
  print "TyBEC: Computation-Bound, CP_PE  x SCALE  = $cp_pe_GBops_s\tGBops/sec\n";
  print "TyBEC: Bandwidth-Bound,   CI x BW         = $ci_bw_G\tGBops/sec\n";
  print "\n";
  print YELLOW "TyBEC: Estimated Performance from Roofline Analysis\t= ***$p_Gbops GBop/sec***\n"; print RESET;
#  print "TyBEC: ASYMPTOTIC --> Effect of filling up offset buffers and pipeline not considered\n";
  
  #Write TIKZ plot TEX file
  #---------------------------
  print "\n";
  print "TyBEC: Generating TEX file to plot performance on roofline graph\n";
  
  # >>>> Load template file
  my $templateFileName = "$TyBECROOTDIR/rooflinePlots/template_rooflineplot.tex"; 
  open (my $fhTemplate, '<', $templateFileName)
    or die "TyBEC: Could not open template file '$templateFileName' $!"; 

  # >>>> Read template contents into string
  my $genCode = read_file ($fhTemplate);
  close $fhTemplate;

  $genCode =~ s/<cpRoof>/$cp_pe_GBops_s/g;
  $genCode =~ s/<xATcpRoof>/$xATcpRoof/g;
  $genCode =~ s/<slopeBW>/$bw_G/g;
  $genCode =~ s/<peakTheoBW_GBps>/$peakTheoBW_GBps/g;
  $genCode =~ s/<designCI>/$ci/g;
  $genCode =~ s/<myXmax>/1000/g;
  $genCode =~ s/<myYmax>/5000/g;
  $genCode =~ s/<maxcpWithMaxScaling>/$cp_pe_GBops_smax/g;
  $genCode =~ s/<designCP>/$p_Gbops/g;
  
  #target TEX file
  make_path("$outputBuildDir/roofline");
  my $targetFilename = "$outputBuildDir/roofline/rooflineplot".".tex";  
  open(my $fh, '>', $targetFilename)
    or die "TyBEC: Could not open file '$targetFilename' $!";  
  print $fh $genCode;
  print "TyBEC: Generated custom ROOFLINE plot TEX file \n";
  close $fh;  
  print "----------------------------------------------------------------------------\n";
  
  #Write estimates.log (and batchEstimates.log if applicable)
  #----------------------------------------------------------
  #NOTE: These ***MUST*** be in the same sequence as the entries made 
  #at the beginning of call to batch() [in case you are a batch-child]
  print $estfh "                                          ,$inputFileTirl       ,           \n";
  print $estfh "PARAMETER                                 ,VALUE                , UNITS     \n";
  print $estfh "Performance                               ,$p_Gbops             , GBop/sec  \n";
  print $estfh "Frequency                                 ,$f_mhz               , MHz       \n";
  print $estfh "alutsTotal                                ,$alutsTotal          ,           \n";
  print $estfh "regsTotal                                 ,$regsTotal           ,           \n";
  print $estfh "bramTotal                                 ,$bramTotal           ,           \n";
  print $estfh "dspTotal                                  ,$dspTotal            ,           \n";
  print $estfh "Host sust' BW                             ,$h_sb_Mbps           , Mbps      \n";
  print $estfh "Gl-Mem sust' BW                           ,$g_sb_Mbps           , Mbps      \n";
  print $estfh "Size of 1 input array (n_gs)              ,$n_gs                ,           \n";
  print $estfh "Firing interval/II (n_to)                 ,$n_to                ,           \n";
  print $estfh "Total word operations per kernel (n_wops) ,$n_wops              ,           \n";
  print $estfh "Words per tuple (from GMEM)      (w_pt)   ,$w_pt                ,           \n";
  print $estfh "Size of problem (array size in words)     ,$n_gs                ,           \n";
  print $estfh "Word size in bits (w_s_bits)              ,$w_s_bits            ,           \n";
  print $estfh "Bytes per word (b_pw)                     ,$b_pw                ,           \n";
  print $estfh "Kernel Pipeline  Latency (k_pd)           ,$k_pd                ,           \n";
  print $estfh "CP of one PE                              ,$cp_pe_GBops         , GBops/sec \n";
  print $estfh "CP of one PE (Asymptotic)                 ,$cp_pe_asympt_GBops  , GBops/sec \n";
  print $estfh "Theoretical maximum PE scaling            ,$maxScaling          ,           \n";
  print $estfh "Computation-Bound: CP_PE  x SCALE         ,$cp_pe_GBops_s       , GBops/sec \n";
  print $estfh "Bandwidth-Bound:   CI x BW                ,$ci_bw_G             , GBops/sec \n";
  print $estfh "Computational Intensity                   ,$ci                  , Byte-op/Byte-trasfer\n";
  print $estfh "alutsKernel                               ,$alutsKernel         ,           \n";
  print $estfh "regsKernel                                ,$regsKernel          ,           \n";
  print $estfh "bramKernel                                ,$bramKernel          ,           \n";
  print $estfh "dspKernel                                 ,$dspKernel           ,           \n";
  print $estfh "alutsBasePlat                             ,$alutsBasePlat       ,           \n";
  print $estfh "regsBasePlat                              ,$regsBasePlat        ,           \n";
  print $estfh "bramBasePlat                              ,$bramBasePlat        ,           \n";
  print $estfh "dspBasePlat                               ,$dspBasePlat         ,           \n";
  
  #if I am child of batch job, then write to master results file
  #open master file, read lines, close, open, append, write back, close
  if($batchChild) {
    my $bfh;
    my $inputBatchFile = "$outputBuildDir/../../batchEstimates.csv";
    
    #read contents
    open($bfh, '<', $inputBatchFile)
        or die "Could not open file '$inputBatchFile' $!";
    chomp(my @rlines = <$bfh>);        
    # = grep { /#.*/ } <$bfh>;   
    close($bfh);
    
    #append new results
    #NOTE: These ***MUST*** be in the same sequence as the entries made 
    #at the beginning of call to batch() [in case you are a batch-child]
    $rlines[0]  = $rlines[0] . ",$inputFileTirl     ";
    $rlines[1]  = $rlines[1] . ",VALUE              ";
    $rlines[2]  = $rlines[2] . ",$p_Gbops           ";
    $rlines[3]  = $rlines[3] . ",$f_mhz             ";
    $rlines[4]  = $rlines[4] . ",$alutsTotal        ";
    $rlines[5]  = $rlines[5] . ",$regsTotal         ";
    $rlines[6]  = $rlines[6] . ",$bramTotal         ";
    $rlines[7]  = $rlines[7] . ",$dspTotal          ";
    $rlines[8]  = $rlines[8] . ",$h_sb_Mbps         ";
    $rlines[9]  = $rlines[9] . ",$g_sb_Mbps         ";
    $rlines[10] = $rlines[10]. ",$n_gs              ";
    $rlines[11] = $rlines[11]. ",$n_to              ";
    $rlines[12] = $rlines[12]. ",$n_wops            ";
    $rlines[13] = $rlines[13]. ",$w_pt              ";
    $rlines[14] = $rlines[14]. ",$n_gs              ";
    $rlines[15] = $rlines[15]. ",$w_s_bits          ";
    $rlines[16] = $rlines[16]. ",$b_pw              ";
    $rlines[17] = $rlines[17]. ",$k_pd              ";
    $rlines[18] = $rlines[18]. ",$cp_pe_GBops       ";
    $rlines[19] = $rlines[19]. ",$cp_pe_asympt_GBops";
    $rlines[20] = $rlines[20]. ",$maxScaling        ";
    $rlines[21] = $rlines[21]. ",$cp_pe_GBops_s     ";
    $rlines[22] = $rlines[22]. ",$ci_bw_G           ";
    $rlines[23] = $rlines[23]. ",$ci                ";
    $rlines[24] = $rlines[24]. ",$alutsKernel       ";
    $rlines[25] = $rlines[25]. ",$regsKernel        ";
    $rlines[26] = $rlines[26]. ",$bramKernel        ";
    $rlines[27] = $rlines[27]. ",$dspKernel         ";
    $rlines[28] = $rlines[28]. ",$alutsBasePlat     ";
    $rlines[29] = $rlines[29]. ",$regsBasePlat      ";
    $rlines[30] = $rlines[30]. ",$bramBasePlat      ";
    $rlines[31] = $rlines[31]. ",$dspBasePlat       ";
    
    #write back
    open($bfh, '>', $inputBatchFile)
        or die "Could not open file '$inputBatchFile' $!";
    print $bfh join ("\n", @rlines);        
    close ($bfh);
    
    
    
  }
  
}#cost()


# ============================================================================
# GENERATE()
# ============================================================================
sub generateHDL {

  print "\n";
  print "=================================================\n";
  print " Verilog HDL Code Generation   					\n";
  print "=================================================\n";
  
  #create target directories
  make_path("$outFPGACode");
  make_path("$outputRTLDir");
  make_path("$outputTbDir");
  make_path("$outputSimDir");  
  
  # --------------------------------------------------
  # get data/stream width to pass on to generators
  # --------------------------------------------------
  my $datat; #complete type (e.g i32)
  my $dataw; #width in bits
  my $dataBase; #base type (ui, i, or float)
  #TODO: I am using the data type of the first stream I see in main (connectd to global memory object) to set data type in the top as well
  #but this is artificially limiting  $strBuf = $dataw;
  foreach (keys %{$CODE{main}{symbols}} ) {
    if ($CODE{main}{symbols}{$_}{cat} eq 'streamread') {
      $datat = $main::CODE{main}{symbols}{$_}{dtype};
      ($dataw = $datat)     =~ s/\D*//g;
      ($dataBase = $datat)  =~ s/\d*//g;
    }
  }  
  my $streamw;
  if($dataBase eq 'float')  {$streamw=$dataw+2;}
  else                      {$streamw=$dataw;}  
  
  # --------------------------------------------------
  # Loop through all nodes, generate code
  # --------------------------------------------------
  #my @nodes_all = $main::dfGraph -> vertices;
  #my @nodes_isolated = $main::dfGraph->isolated_vertices(); #for testing if any unconnected node (redundant)

  #identify connected groups (hierarchical modules)
  #This approach takes care of arbitrary hierarchical depth as all functions will necessarily have their own connected groups
  my @nodes_conn = $main::dfGraph->weakly_connected_components();

  #loop through each group (module)
  #-----------------------
  foreach (@nodes_conn) { 
    my @conn_group_items = @{$_};

    #get name of connected group by peeking at first elements
    my ($dfgroup, undef) = split('\.',$conn_group_items[0],2);
    #print("::dfgroup = $dfgroup\n");

    #----
    #main
    #if DFG group is main, then it needs to generate itself as 
    #it has no parent module (i.e. it is not a NODE in another graph)
    #----
    #If MAIN is vectorized, then none of the children need to be vectorized
    my $vect      = $ioVect;
    #since function modules are generated when they are called by another function, and main is never called
    #so we need a separate route for generating main module
    if($dfgroup eq 'main') {
      my $module    = 'main';
      my $hdlFileName = "$outputRTLDir/$module".".v";
      open(my $hdlfh, '>', $hdlFileName)
        or die "Could not open file '$hdlFileName' $!";
      #HdlCodeGen::genMain($hdlfh, $module, 'untitled', $outputRTLDir, $CODE{main});    
      HdlCodeGen::genMapNode_hier($hdlfh, $module, 'untitled', $outputRTLDir, 'main', $CODE{main}, $vect);    
    }
    
    #loop through each item (node) in a group (main or otherwise)
    #-----------------------------------------
    foreach (@conn_group_items) {
      my $parentFunc= $dfGraph -> get_vertex_attribute ($_, 'parentFunc');
      my $symbol    = $dfGraph -> get_vertex_attribute ($_, 'symbol'    );
      my $ident; #the identifier used for code gen; different way to get it for different cats  
      my $cat       = $CODE{$parentFunc}{symbols}{$symbol}{cat};
      
    #print("::symbol = $symbol\n");
    #print("::cat    = $cat\n");
      
      
      #generate leaf nodes (impscal)
      #-----------------------------
      #leaf nodes are always scalar, and vectorization happens by creating multiple instances at the parent level
      #but the code generator can work with other vector widths as well
      $vect      = 1; 
      if (  ($cat eq 'impscal') 
         || ($cat eq 'func-arg')
         ){
        ($ident =  $symbol) =~ s/(%|@)//; #remove %/@
        my $module    = $parentFunc."_".$ident;
        my $hdlFileName = "$outputRTLDir/$module".".v";
        open(my $hdlfh, '>', $hdlFileName)
          or die "Could not open file '$hdlFileName' $!";
      #print RED; print "::generate:: generating node = $_, parentFunc = $parentFunc, symbol = $symbol, ident = $ident, cat = $cat \n"; print RESET;
        HdlCodeGen::genMapNode_leaf($hdlfh, $module, 'untitled', $outputRTLDir, $CODE{$parentFunc}{symbols}{$symbol}, $vect);    
      }
      
      #generate inferred AXI fifo buffers
      #-------------------------------
      if ($cat eq 'fifobuffer') {
        ($ident =  $symbol) =~ s/(%|@)//; #remove %/@
        my $module    = $parentFunc."_".$ident;
        my $hdlFileName = "$outputRTLDir/$module".".v";
        open(my $hdlfh, '>', $hdlFileName)
          or die "Could not open file '$hdlFileName' $!";
        HdlCodeGen::genAxiFifoBuffer($hdlfh, $module, 'untitled', $outputRTLDir, $CODE{$parentFunc}{symbols}{$symbol}, $vect);    
      }

      #generate inferred AXI stencil buffer
      #-------------------------------
      if ($cat eq 'smache') {
        ($ident =  $symbol) =~ s/(%|@)//; #remove %/@
        my $module    = $parentFunc."_".$ident;
        my $hdlFileName = "$outputRTLDir/$module".".v";
        open(my $hdlfh, '>', $hdlFileName)
          or die "Could not open file '$hdlFileName' $!";
        HdlCodeGen::genAxiStencilBuffer($hdlfh, $module, 'untitled', $outputRTLDir, $CODE{$parentFunc}{symbols}{$symbol}, $vect);    
      }
      
      #generate autoindex nodes
      #-------------------------------
      if ($cat eq 'autoindex') {
        ($ident =  $symbol) =~ s/(%|@)//; #remove %/@
        my $module    = $parentFunc."_".$ident;
        my $hdlFileName = "$outputRTLDir/$module".".v";
        open(my $hdlfh, '>', $hdlFileName)
          or die "Could not open file '$hdlFileName' $!";
        HdlCodeGen::genAutoIndex($hdlfh, $module, 'untitled', $outputRTLDir, $CODE{$parentFunc}{symbols}{$symbol}, $vect);    
      }

      #function-call nodes
      #----------------------------
      #TODO: hardwired - change
      #I am hardwiring this for now, but this should be inferred by the parser
      #in this case, I am hardwiring to 1, as MAIN is vectorized, so we dont want duplicate vectorization
      $vect      = 1;
      #$vect      = 2;
      if($cat eq 'funcall') {
        ($ident = $symbol)  =~ s/\_\d+//; #extract function name from function-call hash 
        my $childFuncDepth  = $CODE{$ident}{depth}; #hierarchical or flat
        my $dfgroup_local   = $ident; #the DFG group of the child function (same as $ident)        
        my $module    = $parentFunc."_".$ident;
        my $hdlFileName = "$outputRTLDir/$module".".v";
        open(my $hdlfh, '>', $hdlFileName)
          or die "Could not open file '$hdlFileName' $!";
        HdlCodeGen::genMapNode_hier($hdlfh, $module, 'untitled', $outputRTLDir, $dfgroup_local, $CODE{$ident}, $vect);
      }
    }#foreach item in group
  }#foreach group
 
  # --------------------------------------------------
  # Top HDL wrapper, depends on target
  # -------------------------------------------------- 
  my $module      = 'func_hdl_top';
  my $hdlFileName;

  $hdlFileName = "$outputRTLDir/$module".".v"  if ($targetNode eq "bolamaNallatech");
  $hdlFileName = "$outputRTLDir/$module".".sv" if ($targetNode eq "awsf12x"); #sdx requires this to be SystemVerilog
  
  open(my $hdlfh, '>', $hdlFileName)
    or die "Could not open file '$hdlFileName' $!";
  
  OclCodeGen_aocl::genHdlWrapper($hdlfh, $module, 'untitled', $outputRTLDir, $ioVect) 
    if ($targetNode eq "bolamaNallatech");
  OclCodeGen_sdx::genHdlWrapper ($hdlfh, $module, 'untitled', $outputRTLDir, $ioVect, $datat, $dataw) 
    if ($targetNode eq "awsf12x");

  #the SDx top level RTL file requires generation too (simply to pass vectorizatiom macro and data width)
  if ($targetNode eq "awsf12x")  {
    $module      = 'krnl_vadd_rtl';
    $hdlFileName = "$outputRTLDir/$module".".v";
    open(my $hdlfh, '>', $hdlFileName)
      or die "Could not open file '$hdlFileName' $!";
    OclCodeGen_sdx::genSdxTopRtl ($hdlfh, $module, 'untitled', $outputRTLDir, $ioVect, $datat, $dataw);
  }
  

 
  # --------------------------------------------------
  # import utility functions 
  # --------------------------------------------------  
  my $srcdir = "$TyBECROOTDIR/hdlGenTemplates"; #reduce clutter
  #copy in util.v
  my $err;
  #$err =copy("$srcdir/template.util.v"            , "$outputRTLDir/../sim/util.v");  
  $err =copy("$srcdir/template.util.v"            , "$outputRTLDir/util.v");  

  
  
  # --------------------------------------------------
  # generate testbench
  # --------------------------------------------------  
  $module    = 'testbench';
  #my $hdlFileName = "$outputRTLDir/../sim/$module.v";
  $hdlFileName = "$outputTbDir/$module.v";
  open($hdlfh, '>', $hdlFileName)
    or die "Could not open file '$hdlFileName' $!";
  HdlCodeGen::genTestbench($hdlfh, $module, 'untitled', $outputTbDir, $ioVect);  
}#sub


# ============================================================================
# GENERATE OCL SHELL
# ============================================================================
sub generateOCL {
  print "\n";
  print "=================================================\n";
  print " OCL Wrapper Code Generation   					\n";
  print "=================================================\n";
  
  my $srcdir;
  my $err;
  my $fh;
  my $targetFileName;
  
  make_path($outputOCLDir);
  
  if($targetNode eq 'bolamaNallatech') {
    make_path($outputOCLDir.'/host');
    make_path($outputOCLDir.'/host/inc');
    make_path($outputOCLDir.'/host/src');
    make_path($outputOCLDir.'/lib' ); 
    make_path($outputOCLDir.'/lib/hdl' ); 
    $srcdir = "$TyBECROOTDIR/oclGenTemplates/aocl";
  }
  elsif($targetNode eq 'awsf12x') {
    make_path($outputOCLDir.'/scripts');
    make_path($outputOCLDir.'/src');
    $srcdir = "$TyBECROOTDIR/oclGenTemplates/sdx/$ocxTempVer/";
  }
  else {die "Illegal targetNode definition";}
  

  # --------------------------------------------------
  # get data/stream width to pass on to generators
  # --------------------------------------------------
  my $datat; #complete type (e.g i32)
  my $dataw; #width in bits
  my $dataBase; #base type (ui, i, or float)
  #TODO: I am using the data type of the first stream I see in main (connectd to global memory object) to set data type in the top as well
  #but this is artificially limiting  $strBuf = $dataw;
  foreach (keys %{$CODE{main}{symbols}} ) {
    if ($CODE{main}{symbols}{$_}{cat} eq 'streamread') {
      $datat = $main::CODE{main}{symbols}{$_}{dtype};
      ($dataw = $datat)     =~ s/\D*//g;
      ($dataBase = $datat)  =~ s/\d*//g;
    }
  }  
  my $streamw;
  if($dataBase eq 'float')  {$streamw=$dataw+2;}
  else                      {$streamw=$dataw;}  
  
  # ====================================================
  if($targetNode eq 'bolamaNallatech') {
  # ====================================================
    # --------------------------------------------------
    # Copy in files where no modification needed)
    # --------------------------------------------------  
    $err =copy("$srcdir/template.README"            , "$outputOCLDir/README");
    $err&=copy("$srcdir/template.make_lib.pl"       , "$outputOCLDir/make_lib.pl");
    $err&=copy("$srcdir/host/inc/ACLHostUtils.h"    , "$outputOCLDir/host/inc/ACLHostUtils.h");
    $err&=copy("$srcdir/host/inc/ACLHostUtils.h"    , "$outputOCLDir/host/inc/ACLHostUtils.h");
    $err&=copy("$srcdir/host/inc/ACLThreadUtils.h"  , "$outputOCLDir/host/inc/ACLThreadUtils.h");
    $err&=copy("$srcdir/host/inc/timer.h"           , "$outputOCLDir/host/inc/timer.h");
    $err&=copy("$srcdir/host/src/ACLHostUtils.cpp"  , "$outputOCLDir/host/src/ACLHostUtils.cpp");
    $err&=copy("$srcdir/host/src/ACLThreadUtils.cpp", "$outputOCLDir/host/src/ACLThreadUtils.cpp");
    $err&=copy("$srcdir/host/src/timer.cpp"         , "$outputOCLDir/host/src/timer.cpp");
    $err&=copy("$srcdir/host/template.Makefile"     , "$outputOCLDir/host/Makefile");
    $err&=copy("$srcdir/template.build_emu.sh"      , "$outputOCLDir/build_emu.sh");
    $err&=copy("$srcdir/template.build_hw.sh"       , "$outputOCLDir/build_hw.sh");
    $err&=copy("$srcdir/template.build_emu_aocOnly.sh"  , "$outputOCLDir/build_emu_aocOnly.sh");
    $err&=copy("$srcdir/template.build_hw_aocOnly.sh"   , "$outputOCLDir/build_hw_aocOnly.sh");
    $err&=copy("$srcdir/template.clean.sh"          , "$outputOCLDir/clean.sh");
    
    # --------------------------------------------------
    # Copy in already generated HDL files (kernel)
    # --------------------------------------------------  
    opendir(my $direc, $outputRTLDir) || die "Can't open $outputRTLDir: $!";
    while (readdir $direc) {
      $err &= copy("$outputRTLDir/$_", "$outputOCLDir/lib/hdl/");
    }
    closedir $direc;  
  
  
    # --------------------------------------------------
    # Kernels.cl
    # --------------------------------------------------  
    $targetFileName = "$outputOCLDir/kernels.cl";
    open($fh, '>', $targetFileName)
      or die "Could not open file '$targetFileName' $!";
    if($oclKernelPipe){OclCodeGen_aocl::genKernelOclPipe($fh, 'untitled', $outputOCLDir, $ioVect);}
    else              {OclCodeGen_aocl::genKernelHdlPipe($fh, 'untitled', $outputOCLDir, $ioVect);}
  
    # --------------------------------------------------
    # hdl_lib.xml
    # --------------------------------------------------  
    $targetFileName = "$outputOCLDir/lib/hdl_lib.xml";
    open($fh, '>', $targetFileName)
      or die "Could not open file '$targetFileName' $!";
    OclCodeGen_aocl::genXML($fh, 'untitled', $outputOCLDir, $outputRTLDir, $ioVect);
  
    # --------------------------------------------------
    # cl_model.cl and hdl_lib.h
    # --------------------------------------------------  
    my ($fh_c, $fh_h);
    my $targetFileName_cmodel = "$outputOCLDir/lib/c_model.cl";
    my $targetFileName_hdllib = "$outputOCLDir/lib/hdl_lib.h";
    open($fh_c, '>', $targetFileName_cmodel)
      or die "Could not open file '$targetFileName_cmodel' $!";
    open($fh_h, '>', $targetFileName_hdllib)
      or die "Could not open file '$targetFileName_hdllib' $!";
    OclCodeGen_aocl::genCModelAndHdlLibH($fh_c, $fh_h, 'untitled', $outputOCLDir, $ioVect);
  
    # --------------------------------------------------
    # main.cpp
    # --------------------------------------------------  
    $targetFileName = "$outputOCLDir/host/src/main.cpp";
    open($fh, '>', $targetFileName)
      or die "Could not open file '$targetFileName' $!";
    OclCodeGen_aocl::genMainCpp($fh, 'untitled', $outputOCLDir);
      
  }#if
  
  # ====================================================
  elsif($targetNode eq 'awsf12x') {
  # ====================================================
    # --------------------------------------------------
    # Copy in files where no modification needed)
    # --------------------------------------------------  
    #$err = dircopy($srcdir,$outputOCLDir);
    #print ("dircopy err = $err\n");
    $err =copy("$srcdir/Makefile"                    , "$outputOCLDir/Makefile");
    $err =copy("$srcdir/README.md"                   , "$outputOCLDir/README.md");
    $err =copy("$srcdir/local_hwemu_build_and_run.sh", "$outputOCLDir/local_hwemu_build_and_run.sh");
    $err =copy("$srcdir/local_hwSynth_build.sh"      , "$outputOCLDir/local_hwSynth_build.sh");
    $err =copy("$srcdir/local_createAFIonS3bucket.sh", "$outputOCLDir/local_createAFIonS3bucket.sh");
    $err =copy("$srcdir/run_on_aws_f1.sh"            , "$outputOCLDir/run_on_aws_f1.sh");
    $err =copy("$srcdir/describe-fpga-images.sh"     , "$outputOCLDir/describe-fpga-images.sh");
    $err =copy("$srcdir/clean.sh"                     , "$outputOCLDir/clean.sh");
    $err =copy("$srcdir/move_files_to_github_for_awsf1.sh"                     
              , "$outputOCLDir/move_files_to_github_for_awsf1.sh");
    $err =copy("$srcdir/local_host_only_build_and_emu_run.sh"
              , "$outputOCLDir/local_host_only_build_and_emu_run.sh");
    $err =copy("$srcdir/description.json"            , "$outputOCLDir/description.json");
    $err =copy("$srcdir/aws_hwemu_build.sh"          , "$outputOCLDir/aws_hwemu_build.sh");
    $err =copy("$srcdir/scripts/gen_xo.tcl"          , "$outputOCLDir/scripts/gen_xo.tcl");
    $err =copy("$srcdir/scripts/package_kernel.tcl"  , "$outputOCLDir/scripts/package_kernel.tcl");
    #$err =copy("$srcdir/src/kernel.xml"              , "$outputOCLDir/src/kernel.xml"); 
      #this should now be custom generated
    
    #these are HDL files, but since they are part of the shell needed for sdaccel integration, they
    #are created in the call to generateOCL
    $err =copy("$srcdir/src/hdl/krnl_vadd_rtl_axi_read_master.sv"  
            , "$outputOCLDir/src/hdl/krnl_vadd_rtl_axi_read_master.sv");
    $err =copy("$srcdir/src/hdl/krnl_vadd_rtl_axi_write_master.sv" 
            , "$outputOCLDir/src/hdl/krnl_vadd_rtl_axi_write_master.sv");
    $err =copy("$srcdir/src/hdl/krnl_vadd_rtl_control_s_axi.v"     
            , "$outputOCLDir/src/hdl/krnl_vadd_rtl_control_s_axi.v");
    $err =copy("$srcdir/src/hdl/krnl_vadd_rtl_counter.sv"          
            , "$outputOCLDir/src/hdl/krnl_vadd_rtl_counter.sv");
    $err =copy("$srcdir/src/hdl/krnl_vadd_rtl_int.sv"              
            , "$outputOCLDir/src/hdl/krnl_vadd_rtl_int.sv");
    #$err =copy("$srcdir/src/hdl/krnl_vadd_rtl_example.sv"              
    #        , "$outputOCLDir/src/hdl/krnl_vadd_rtl_example.sv");
    #$err =copy("$srcdir/src/hdl/krnl_vadd_rtl_example_vadd.sv"              
    #        , "$outputOCLDir/src/hdl/krnl_vadd_rtl_example_vadd.sv");
    
    # --------------------------------------------------
    # main.c
    # --------------------------------------------------  
    $targetFileName = "$outputOCLDir/src/main.c";
    open($fh, '>', $targetFileName)
      or die "Could not open file '$targetFileName' $!";
    OclCodeGen_sdx::genHostCpp($fh, 'untitled', $outputOCLDir, $ioVect, $datat, $dataw);

    # --------------------------------------------------
    # kernel.xml
    # --------------------------------------------------  
    $targetFileName = "$outputOCLDir/src/kernel.xml";
    open($fh, '>', $targetFileName)
      or die "Could not open file '$targetFileName' $!";
    OclCodeGen_sdx::genKernelXML($fh, 'untitled', $outputOCLDir, $ioVect, $datat, $dataw);
  }
  else {die "Illegal targetNode definition";}

  print "=================================================\n";
}#()

# ============================================================================
# Post-processing and cleanup
# ============================================================================
sub post{
#Print compile time and duration.
my $end = Time::HiRes::gettimeofday();
#print  "Build started at $end\n";
printf ("Build took %.2f seconds\n", $end - $start);

# write to LOG file here
print $outfh Dumper(\%CODE); 

#write to JSON as well 
my $json = encode_json \%CODE;
print $outfh_json $json;
#display DFG, and emit it as DOT
#-------------------------------

my $dfGraph_lines = $dfGraph;
$dfGraph_lines =~ s/,/\n/g;

#print "The graph is $dfGraph\n";
print "The graph is: \n $dfGraph_lines\n";

#graph as PNG
my $dfGraphDotFileName;
my $dfGraphDotFH;
$dfGraphDotFileName = "DFG.png";
#$dfGraphDotFileName = "DFG.jpg";
open($dfGraphDotFH, '>', "$outputBuildDir/$dfGraphDotFileName")
  or die "Could not open file '$dfGraphDotFileName' $!";

print $dfGraphDotFH $dfGraphDot->as_png;
#print $dfGraphDotFH $dfGraphDot->as_jpeg;
#system("cygstart ./$outputBuildDir/$dfGraphDotFileName");# if($dot);
close $dfGraphDotFH;

#graph as PS
$dfGraphDotFileName = "DFG.ps";
open($dfGraphDotFH, '>', "$outputBuildDir/$dfGraphDotFileName")
  or die "Could not open file '$dfGraphDotFileName' $!";

print $dfGraphDotFH $dfGraphDot->as_ps;
close $dfGraphDotFH;


#create DOT graph of callgraph
#----------------------------
if($dot) {
  print $dotfh $dotGraph->as_png;
  #print $dotfh $dotGraph->as_jpeg;
  
  #if ($OSNAME eq 'MSWin32') {
  #  system("cygstart ./TybecBuild/DOT.png") if($dot);
    #system("cygstart ./TybecBuild/DOT.jpg") if($dot);
  #else {#assume linux and use EYE to open
  #  system("eog ./TybecBuild/DOT.png") if($dot);}
  close $dotfh;
}

#close files
close $fhinputpp;
close $main::outfh;
close $main::outfh_json;
# remove temporary output file of GCC Pre-Processor
#system("rm $tempMacExpFile");

}#post()

# ----------------------------------------------------------------------------
#
# ----------------------------------------------------------------------------
sub printHelp {
  print "\ntybec command line options and default values\n";
  print "---------------------------------------------\n\n";
  print "--clt  [OFF]           :run c2llcm2tir on input first (not integrated yet)\n";                   
  print "--d    [OFF]           :turn on DEBUG mode                       \n";                   
  print "--batch[OFF]           :run on all tirl files in current folder  \n";
  print "--i    [./file.tirl]   :input TIRL FILE                          \n";
  print "--obd  [./TybecBuild]  :output Build Directory                   \n";
  print "--ord  [./hdlGen/rtl]  :output directory for generated RTL code  \n";
  print "--ilp  [ON]            :Should compiler find ILP in PIPEs        \n";
  print "--h                    :Display help                             \n";
  print "--help                 :Display help                             \n";
  print "--v                    :Show current TyBEC release version       \n";
  print "--g    [OFF]           :Generate HDL code                        \n";
  print "--e    [OFF]           :Estimate Resources and Performance from TIRL\n";
  print "--dot  [OFF]           :Run DOT and display graph at the end of compile\n";
  print "--tar  [awsf12x]       :Target node [awsf12x/philpotsMaxeler/bolamaNallatech/bolamaAlphadata]\n";
  print "--lambda [OFF]         :You will provide lamdba function for CPU baseline/AOCL-only  comparison \n";
  print "                        You *MUST* provide a string for the lambda function using\n";
  print "                        array operations (index = 'i') on the input arrays. \n";
  print "                        Place it in ./lambda.txt \n";
  print "--iov  [1]             :Degree of IO vectorization (coalescing) \n";
  print "--op   [OFF]           :Should I create the kernel (CG) pipeline in OCL \n";
  print "--cio  [ON]            :Should I coalesce IOs (makes OCX integration simpler)\n";
}

# ----------------------------------------------------------------------------
#
# ----------------------------------------------------------------------------
sub printVer {
  print "\nThis is TyBEC Release $tybecRelease\n\n";
  print "This is an in-house release and on-going work\n";
  print "For help, type \"tybec.pl --h\"\n"; 
}






