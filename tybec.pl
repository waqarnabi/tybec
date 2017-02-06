#!/usr/bin/perl -w

# =============================================================================
# Company      : Unversity of Glasgow, Comuting Science
# Author:        Syed Waqar Nabi
# 
# Create Date  : 2014.12.26
# Project Name : TyTra
#
# Dependencies : See ./README.txt
#               
# Revision     : 
# Revision 0.01. File Created
# 
# Conventions  : 
# =============================================================================
#
# =============================================================================
# General Description and Notes
# -----------------------------------------------------------------------------
# 1. A parser for lower TIR
#
# 2. Following functions implemented:
#  - parse TIRL and generate tokens
#  - calculate cost and annotate TIRL
#  - generate synthesizeable verilog for target
#
# TODOs:
# =====
#
#  - Search for "TODO" in the associated source code perl files
#-----------------------------------------------------------------------
# Configurations, and validity for (P)arsing, (C)osting, and (G)eneration
#-----------------------------------------------------------------------
#
# 1 = done
# 0 = not done 
  # X = not done AND Not TODO (for now at least)
  # + = not done AND TODO now
#
# Configuration     | P | A | C | G |Remarks              
# --------------    |---|---|---|---|------------------------------
# cPipe             | 1 | 1 |   | 1 |Single pipeline       
# cPar_PipeS        | 1 | 1 |   | + |Parallel Lanes of  symmetric  pipelines
# cPar_PipeA        | 1 | 1 |   | X |Parallel Lanes of asymmetric piplines
# cPipe_PipeS       | 1 | 1 |   | X |Single pipeline of  symmetric pipelines (loop unroll)
# cPipe_PipeA       | 1 | 1 |   | 1 |Single pipeline of asymmetric pipelines (coarse-pipeline)
# cPar_PipeA_PipeS  |   |   |   | X |Par Lanes of asymmetric pipes: Each is pipeline of  symmetrical pipelines
# cPar_PipeS_PipeS  |   |   |   | X |Par Lanes of  symmetric pipes: Each is pipeline of  symmetrical pipelines
# cPar_PipeA_PipeA  |   |   |   | X |Par Lanes of asymmetric pipes: Each is pipeline of asymmetrical pipelines
# cPar_PipeS_PipeA  |   |   |   | + |Par Lanes of  symmetric pipes: Each is pipeline of asymmetrical pipelines
# cPar_PipeA_PipeX  |   |   |   | X |Par Lanes of asymmetric pipes: Each is pipeline of symm' OR asymm' pipelines
# cSeq              | 1 | 1 |   | X |A single sequential processor                      
# cParSeq           |   |   |   | X |Multiple sequential processors in parallel (SIMD) 
# cPipeSeq          |   |   |   | X |Multiple sequential processors in pipeline             
# cPar              |   |   |   | X |A single instruction VLIW processor
# cPipePar          |   |   |   | X |Pipeline of parallel blocks, a pipeline of single instruction VLIW processors 


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
our $tybecRelease = 'R0.03';

# ----------------------
# Generic Modules
# ----------------------
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

# ----------------------
# TyBEC specific modules
# ----------------------
use Cost;             #read cost database and functions from Cost.pm
use HdlCodeGen;       #codeGenerator functions
use HardwareSpecs;    #specification of target hardware

# ============================================================================
# START TIMER
# ============================================================================
my $start = Time::HiRes::gettimeofday();

# ============================================================================
# GLOBALS and Initialization
# ============================================================================
#use vars qw(%VARIABLE); #global variable?

#hash for storing ALL parsed tokens in the TIR
our %CODE; 

#hash for compiling result in a batch job scenario
our %BATCH;

#function call graph
our %callGraph;

our $BODY; #global variable?

our $funCntr;       #counter to keep track of multiple calls to same function
our $insCntr;        #counter for number of instructions in a function
our $glComputeInstCntr; #counter for total number of GLOBAL compute intructions (all functions).
our $insCntrFcall;   #counter for number of function_call instructions in a function
our $argSeq;       #counter for sequence number of arguments in a function definition
our $argSeq2;      #counter for sequence number of arguments in a called function instruction

our $NparPipes;     #total number of parallel (top-level) pipes
#our $parTop;        #name of top level par module (if applicable)
#our $pipeTop;       #name of top level pipe module (if applicable)
#our $pipeSecond;    #name of second level pipe module (applicable only if top level is par)



our $topFuncKey  ; #top func key in any configuration
our $topFuncType ;
our $topFuncName ;

our $topPipeKey;    #Name of top-level PIPE in any config that has pipe (if it is CG, it is same is below)
our $topCGpipeKey;  #name of the top CG pipe in cPipe_PipeA or cPar_PipeS_PipeA 


#our $desConf;#what is the overall configuration of the design -- OBSOLETE
our $desConfigNew;#what is the overall configuration of the design-- NEW VERSION

our $designFail; #does the design meet resource and IO constraints?
$designFail = 0;

# error messages
our $dieConfigMsg = "TyBEC: **Illegal Configuration!**: Allowed configurations are:\n\tmain->pipe \n\tmain->par \n\tmain->pipe->par(s) \n\tmain->par->pipe(s) \n\tmain->par->pipe(s)->par(s)";
our $dieNotSamePipesMsh = "TyBEC: **Illegal Configuration!**: All concurrent pipelines must be symmetrical"; 

# Initialize
# -------------------
$CODE{launch}{wordsPerTuple} = 0;
$funCntr = 0;
$insCntr = 0;
$glComputeInstCntr = 0;
$insCntrFcall = 0;
$NparPipes = 0;
$argSeq = 0;
$argSeq2 = 0;

my $stages_pipe_top = 0;
my $latency_pipe_top = 0;

# ------------------------------------
# Create a Configuration Tree 
# ------------------------------------ 
our $tree = Tree::DAG_Node->new;
$tree->name('launch');

our $treeChild = Tree::DAG_Node->new;
$treeChild->name('null');
# ============================================================================
# Utility routines
# ============================================================================
sub mymax ($$) { $_[$_[0] < $_[1]] }
sub mymin ($$) { $_[$_[0] > $_[1]] }

# ============================================================================
# GRAMMAR
# ============================================================================
use TirGrammarMod;       #read Grammar from TirGrammarMod.pm

# ============================================================================
# Command Line
# ============================================================================

# default options
our $inputFileTirl = "file.tirl"; #input TIRL file
our $outputBuildDir = './TybecBuild';
our $outputRTLDir = './hdlGen/rtl';
our $debug = '';
our $batch = '';
our $batchChild = '';
our $autoParallelize = 1;
our $help = '';
our $showVer = '';
our $genRTL = '';
our $estimate = 1;
our $dot = '';
our $targetNode  = "bolamaNallatech";
our $targetBoard = $HardwareSpecs::nodes{$targetNode}{boardName};
our $targetDevice= $HardwareSpecs::boards{$targetBoard}{deviceName};

GetOptions (
    'd'     => \$debug            #--debug
  , 'batch' => \$batch            #--batch <run estimator on all .tirl files in folder with default options>
  , 'i=s'   => \$inputFileTirl    #--i    <input TIRL FILE>
  , 'obd=s' => \$outputBuildDir   #--obd  <output Build Directory>
  , 'ord=s' => \$outputRTLDir     #--ord  <output director for RTL code generated>
  , 'ilp'   => \$autoParallelize  #--ilp  <Should compiler find ILP in PIPEs>
  , 'help'  => \$help             #--h    <Display help>
  , 'v'     => \$showVer          #--v    <Show current TyBEC release version>
  , 'g'     => \$genRTL           #--g    <Generate RTL code>
  , 'e'     => \$estimate         #--e    <Estimate Resources and Performance from TIRL>
  , 'dot'   => \$dot              #--dot  <Run DOT and display graph at the end of compile>
  
  
  , 'batchChild' => \$batchChild  #--batchChild used internally by parent script of batch job to call childs and 
                                  # and indicate they are part of a batch job, so that they compile key results to parent LOG
  , 'tar' => \$targetBoard     #--target  <Name of target board>
  );

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

#if batch job, create a folder for each file, run the script for it in that folder
#-------------
if($batch) {
  my @allFiles = <*.tirl>;
  
  print "TyBEC: Running in BATCH mode. All TIRL files in current folder will be compiled\n";
  print "WARNING: Previous build folders in the current directory will be deleted if you continue\n";
  print "Are you sure you wish to continue? (y/n) \n";

  #chomp (my $yesno = <>);
  #if($yesno eq 'n') {exit;}
  
  #remove all directories in current folder
  system("rm batch.log");
  
  for my $oneFile (@allFiles) {
    my $tDir = $oneFile."_build";    
    
    system("rm -r $tDir");
    system("mkdir $tDir");
    
    system("cp $oneFile $tDir");
    chdir $tDir;

    system("tybec.pl --i $oneFile --g --batchChild");
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
  exit;
}

# ============================================================================
# Files and Dirs
# ============================================================================

#Root directory for TyBEC scripts
my $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};

#make targe directories if not present
make_path($outputBuildDir);
make_path($outputRTLDir) if ($genRTL);
 
#open input TIRL file
open(my $infh, "<", $inputFileTirl)
  or die "Could not open file '$inputFileTirl' $!";

#Create tokens.log (tokens parsed from TIRL are written this file)
my $logFilename = "tokens.log";
open(my $outfh, '>', "$outputBuildDir/$logFilename")
  or die "Could not open file '$logFilename' $!";

#batch file if this is a batchChild
my $batchfh;
if($batchChild) {
  my $batchLogFilename = "batch.log";
  open($batchfh, '>>', "$outputBuildDir/../../$batchLogFilename")
      or die "Could not open file '$batchLogFilename' $!";
}

  
#Read input TIRL contents; remove comments while reading
my @lines = grep { /#.*/ } <$infh>; 

# ----------------------------
# Printing to LOG and STDOUT
# ----------------------------
my $tee = new IO::Tee(\*STDOUT, new IO::File(">$outputBuildDir/build.log"));        
select $tee;        

# ----------------------------
# DOT.png
# ----------------------------
my $dotFilename;
my $dotfh;
if($dot) {
  $dotFilename = "DOT.png";
  open($dotfh, '>', "$outputBuildDir/$dotFilename")
    or die "Could not open file '$dotFilename' $!";
}

# ============================================================================
# Create DOT graph
# ============================================================================
our $dotGraph = GraphViz->new();

# ============================================================================
# Create Parser
# ============================================================================
my $parser = Parse::RecDescent->new($TirGrammarMod::grammar);

# ============================================================================
# Run TyBEC Pre-Processor  + GCC Pre-Processor
# ============================================================================
# This is ugly (having a macro parser as well as a GCC Pre-Processor.. TODO
$parser->MACROS("@lines") or die "Parser Macro rule failed!"; 

close $infh;

my $tempMacExpFile = "temp.tirl";
system("gcc -E -x c -P -C $inputFileTirl > $outputBuildDir/$tempMacExpFile");

open(my $fh, "<", "$outputBuildDir/$tempMacExpFile")
  or die "Could not open file '$tempMacExpFile' $!";

# ============================================================================
# Initializations
# ============================================================================
init(); #always parse

# ============================================================================
# Run parser
# ============================================================================
parse(); #always parse

# ============================================================================
# Analyse configuration and create verilog generator variables
# ============================================================================
analyze(); #always analyze

# ============================================================================
# Calculate and Print Cost 
# ============================================================================
estimate() if($estimate);

# ============================================================================
# Generate Verilog files
# ============================================================================
generate() if($genRTL);

# ============================================================================
# Post-processing and cleanup
# ============================================================================

#Print compile time and duration.
my $end = Time::HiRes::gettimeofday();
#print  "Build started at $end\n";
printf ("Build took %.2f seconds\n", $end - $start);

# write to LOG file here
print $outfh Dumper(\%CODE); 

#create DOT graph
if($dot) {
  print $dotfh $dotGraph->as_png;
  
  #if ($OSNAME eq 'MSWin32') {
    system("cygstart ./TybecBuild/DOT.png") if($dot);
  #else {#assume linux and use EYE to open
  #  system("eog ./TybecBuild/DOT.png") if($dot);}
  close $dotfh;
}

#close files
close $fh;
close $outfh;
close $outfh;
# remove temporary output file of GCC Pre-Processor
#system("rm $tempMacExpFile");


# ****************************************************************************
#                              END OF SCRIPT
# ****************************************************************************



# ============================================================================
#                   *****   SUB ROUTINES for tybec.pl *****
# ============================================================================


# ============================================================================
# PARSE()
# ============================================================================
sub init {
  print "\n";
  print "=====================================\n";
  print "       TARGET HARDWARE               \n";
  print "=====================================\n";

  print "Target node is\t: $targetNode\n";
  print "Target board is\t: $targetBoard\n";
  print "Target device is\t: $targetDevice\n";
}

# ============================================================================
# PARSE()
# ============================================================================
sub parse {
  @lines = grep { not /;.*/ } <$fh>; #remove comments while reading file
  
  print "\n";
  print "=====================================\n";
  print "       Running TyBEC Parser          \n";
  print "=====================================\n";
  
  $parser->STARTRULE("@lines") or die "Parser start rule failed!"; 
  
  #print "\n";
  #print "================================\n";
  #print "       Call Graph       \n";
  #print "================================\n";
  #print map "$_\n", @{$tree->draw_ascii_tree};
    
}

# ============================================================================
# ANALYZE
# ============================================================================


# ---------------------------------------------------
# Helper function to add module to DOT graph
# ---------------------------------------------------
sub analyze_helper_dot_and_callGraph {
  my $myKey           = shift (@_); #the function now  being analyzed (was called as child)
  my $myName          = shift (@_); 
  my $myType          = shift (@_); 
  my $myRepeatCounter = shift (@_); 
  
  my $parentKey       = shift (@_); #the parent of this function
  my $cGraphParent    = shift (@_); #call graph hash ref of parent, so that this
                                    #function appends to it

  #is this function a leaf function?
  my $amIleaf        = $CODE{$myName}{leaf};
  
  if($amIleaf eq 'yes') {
    return;}
  else{
    #check each instruction of this function, which may be a function call
    foreach my $childKey (keys %{$CODE{$myName}{instructions}} ) {
      #see if it is a function call instruction
      if($CODE{$myName}{instructions}{$childKey}{instrType} eq 'funcCall') {
        my $childName          = $CODE{$myName}{instructions}{$childKey}{funcName};
        my $childRepeatCounter = $CODE{$myName}{instructions}{$childKey}{funcRepeatCounter};
        my $childType          = $CODE{$myName}{instructions}{$childKey}{funcType};
        my $isChildLeaf        = $CODE{$childName}{leaf};
        
        #add this child function to dot and call graph
        $dotGraph->add_node ("$childName"."::$childRepeatCounter");
        $dotGraph->add_edge ("$myName"."::$myRepeatCounter" => "$childName"."::$childRepeatCounter"
                            , label => "$childType");   
        $cGraphParent->{calls}{$childKey}{name} = $childName;
        $cGraphParent->{calls}{$childKey}{type} = $childType;
        
        #call recursively on child function
        #analyze_helper_dot_and_callGraph($key2 , $key, $cGraphParent->{calls}{$key2} );
        analyze_helper_dot_and_callGraph( $childKey, 
                                          $childName, 
                                          $childType, 
                                          $childRepeatCounter,
                                          $myKey, 
                                          $cGraphParent->{calls}{$childKey} );        
      }#if funcCall
    }#foreach
  }#if($isChildLeaf eq 'no') {   
}


# ---------------------------------------------------
# The analyze subroutine
# ---------------------------------------------------
sub analyze {

  print "\n";
  print "=====================================\n";
  print "    NEW Analysing Configuration       \n";
  print "=====================================\n";
  
  #--- launch exists
  #-----------------------------------------
  if (exists $CODE{launch}) { 
    $dotGraph->add_node('launch');
    $CODE{callGraph}{launch} = {};
  }
  else {
    die "TyBEC: **Illegel Configuration Error**. No launch() found";}


  #--- main called from launch?
  #-----------------------------------------
  if (exists $CODE{launch}{call2main}) {
    $dotGraph->add_node('main');
    $dotGraph->add_edge('launch' => 'main', label => "$CODE{launch}{call2main}{kIterSize}"); 
    $CODE{callGraph}{launch}{calls}{main} = {};
  }
  else {
    die "TyBEC: **Illegel Configuration Error**. No main() found";}
  
  #--- Build Call Graph and Dot Graph
  #-----------------------------------------
  foreach my $childKey (keys %{$CODE{main}{instructions}} ) {
  
    my $childName           = $CODE{main}{instructions}{$childKey}{funcName};
    my $childRepeatCounter  = $CODE{main}{instructions}{$childKey}{funcRepeatCounter};
    my $childType           = $CODE{main}{instructions}{$childKey}{funcType};
    my $isChildLeaf         = $CODE{$childName}{leaf};

    #add to dot graph and callGraph hash
    $dotGraph->add_node("$childName"."::$childRepeatCounter");
    $dotGraph->add_edge('main' => "$childName"."::$childRepeatCounter"
                       , label => "$childType");                      
    $CODE{callGraph}{launch}{calls}{main}{calls}{$childKey}{name} = $childName;
    $CODE{callGraph}{launch}{calls}{main}{calls}{$childKey}{type} = $childType;

    #call recursive function that does the same for each child function in main
    analyze_helper_dot_and_callGraph( $childKey, 
                                      $childName, 
                                      $childType, 
                                      $childRepeatCounter,
                                      'main', 
                                      $CODE{callGraph}{launch}{calls}{main}{calls}{$childKey} ); 
  }#foreach

  #-----------------------------------------
  #--- Analyze configuration
  #-----------------------------------------
  
  my $cgHash = $CODE{callGraph}{launch}{calls}{main}{calls}; #reduce clutter
  my @cgHashKeys = keys %{$cgHash}; #keys of all functions called by main
  
  ### Main can call only one function
  if(scalar @cgHashKeys > 1) {
    die "TyBEC: **ERROR** main() can call only one function\n";}
  
  ### Check all possible valid configurations; if none found, error ###

  #get the name and type of top function
  $topFuncKey  = $cgHashKeys[0];
  $topFuncType = $cgHash->{$topFuncKey}{type};
  $topFuncName = $cgHash->{$topFuncKey}{name};
  #$stages_pipe_top =  keys %{ $CODE{$pipeTop}{instructions} };   
   
  #Top function is PIPE
  #==============================
  if ($topFuncType eq 'pipe') {
    #cPIPE: no further calls from a top level PIPE
    if (!(exists $cgHash->{$topFuncKey}{calls}) ) {
      $desConfigNew = 'cPipe';  # <<-------------- cPipe
      #top function also the top PIPE function
      $topPipeKey = $topFuncKey;
      $NparPipes  = 1;
    }
      
    #There are further calls from the top level PIPE
    else {
      #check EACH called function from top PIPE
      foreach my $key (keys %{$cgHash->{$topFuncKey}{calls}} ) {
        #preserve Type and Name to check if ALL called functions are of same type/name
        state $prevType = 'null';
        state $prevName = 'null';

        #cPIPE: only calls to COMB from a top level PIPE
        if  (  ($cgHash->{$topFuncKey}{calls}{$key}{type} eq 'comb') 
            && ( ($prevType eq 'null') || ($prevType eq 'comb') ) ) {
          $desConfigNew = 'cPipe'; # <<-------------- cPipe 
          #top function also the top PIPE function
          $topPipeKey = $topFuncKey;     
        }
        #only calls to PIPEs from inside a top level PIPE
        elsif  (  ($cgHash->{$topFuncKey}{calls}{$key}{type} eq 'pipe') 
            && ( ($prevType eq 'null') || ($prevType eq 'pipe') ) ) {
            #symmetrical PIPElines (unrolled loop)
            if(($prevName eq $cgHash->{$topFuncKey}{calls}{$key}{name}) || ($prevName eq 'null') ) {
              $desConfigNew = 'cPipe_PipeS';} # <<-------------- cPipe_PipeS
            #Asymmetric pipelines
            else {
              $desConfigNew = 'cPipe_PipeA';} # <<-------------- cPipe_PipeS
            #store for use in generate()
            $topCGpipeKey = $topFuncKey;
            $topPipeKey = $topFuncKey;     
            $NparPipes  = 1;
        }#elsif  
        
        #check for cPipe_Par
        #TODO: Should this be made obsolete in view of auto ILP extraction?
        elsif ($cgHash->{$topFuncKey}{calls}{$key}{type} eq 'par') {
          die "TyBEC: **ERROR** PAR inside a PIPE is now obsolete, as ILP is automatically 
          extracted and scheduled.";
        }
  
        #illegal configuration with a top-level PIPE function
        else {
          die "TyBEC: **ERROR** Illegal Configuration for a top-level PIPE function.";
        }

        $prevType = $cgHash->{$topFuncKey}{calls}{$key}{type};
        $prevName = $cgHash->{$topFuncKey}{calls}{$key}{name};
      }#foreach
    }#else
  }#if ($topFuncType eq 'pipe')
  
  #cSeq: top func SEQ, and no further calls from it
  #====================================================
  elsif ( ($topFuncType eq 'seq') &&  ~(exists $cgHash->{$topFuncKey}{calls}) ) {
    $desConfigNew = 'cSeq'; }
    
  #cPar_XXX: Top function is PAR 
  #===============================
  elsif ($topFuncType eq 'par') {
    #no child functions: ILLEGAL
    if (!(exists $cgHash->{$topFuncKey}{calls}) ) {
      die "TyBEC: **ERROR** Illegal configuration for a top-level PAR function. It must have children."; 
    }
    
    #has child functions
    else {
      #check EACH called function from top PAR
      foreach my $key (keys %{$cgHash->{$topFuncKey}{calls}} ) {
        #preserve Type and Name to check if ALL called functions are of same type/name
        state $prevType = 'null';
        state $prevName = 'null';

        #cPAR: only calls to COMB from a top level PAR **ILLEGAL**
        if  (  ($cgHash->{$topFuncKey}{calls}{$key}{type} eq 'comb') 
            && ( ($prevType eq 'null') || ($prevType eq 'comb') ) ) {
          die "TyBEC: **ERROR** Illegal Configuration for a top-level PAR function.";}
        
        #only calls to PIPEs from inside a top level PAR
        elsif  (  ($cgHash->{$topFuncKey}{calls}{$key}{type} eq 'pipe') 
            && ( ($prevType eq 'null') || ($prevType eq 'pipe') ) ) {
            
            #symmetrical PIPElines (identical kernel for all pipes)
            if(($prevName eq $cgHash->{$topFuncKey}{calls}{$key}{name}) || ($prevName eq 'null') ) {
              $desConfigNew = 'cPar_PipeS'; # <<-------------- cPar_PipeS   
              $topPipeKey = $key;
            }#if
            #Asymmetric pipelines: different kernels in each parallel pipeline (invalid)
            else {
              $desConfigNew = 'cPar_PipeA';} # <<-------------- cPar_PipeA
        }#elsif  
         
        #**TODO**: Multiple CG pipelines
        
        #illegal configuration with a top-level PAR function
        else {
          die "TyBEC: **ERROR** Illegal Configuration for a top-level PAR function.";
        }
        $prevType = $cgHash->{$topFuncKey}{calls}{$key}{type};
        $prevName = $cgHash->{$topFuncKey}{calls}{$key}{name};
        $NparPipes++;
      }#foreach
      
      #if we have decided that it is ATLEAST a cPar_PipeS or cPar_PipeA, we should check if
      #these paralallel pipelines are themselves CG
      my $desConfigNewTemp = $desConfigNew;
      if  (  ($desConfigNew eq 'cPar_PipeS')
          || ($desConfigNew eq 'cPar_PipeA') ) {      
        
        #loop over each child pipe calls, and if none of them has further
        #function calls at all, it means we are already at the correct configuration
        foreach my $key (keys %{$cgHash->{$topFuncKey}{calls}} ) {
          state $prevType = 'null';
          state $prevName = 'null';
          if  (!(exists $cgHash->{$topFuncKey}{calls}{$key}{calls})
              &&($prevType eq 'null')  ) {
            #the current config is ok as none of the children has further children
          }
          #there is a further func call from at least one child pipe. 
          #Check it it is a pipe or comb only
          else {
            #loop through each called function (grandchild) of child
            foreach my $keyNested (keys %{$cgHash->{$topFuncKey}{calls}{$key}{calls}} ) {
              state $prevTypeNested = 'null';
              state $prevNameNested = 'null';
              #check if it calls symmetric pipelines, different pipelines, or comb
              
              #check comb
              if($cgHash->{$topFuncKey}{calls}{$key}{calls}{$keyNested}{type} eq 'comb') {
                #no change to config
              }#if
              
              #NOTE/TODO: This shoudl work ok for cPar_PipeS_PipeA, which is of interest
              # but may fail for cPar_PipeA_PipeX, which has not been tested
              elsif($cgHash->{$topFuncKey}{calls}{$key}{calls}{$keyNested}{type} eq 'pipe') {
                #we've determined that child pipe has further pipe children. Now check if symm
                #or asymm
                # symm-case
                if  (   $prevNameNested 
                    eq  $cgHash->{$topFuncKey}{calls}{$key}{calls}{$keyNested}{name}) {
                  #since nested pipes have same names, we have a symmetric pipes in the CG pipe
                  #(which is not really what we are focusing on). 
                  #the final config depends on the prev. derived partial config
                  $desConfigNewTemp = 'cPar_PipeS_PipeS' if($desConfigNew eq 'cPar_PipeS');
                  $desConfigNewTemp = 'cPar_PipeA_PipeS' if($desConfigNew eq 'cPar_PipeA');
                }#if
                #asymm-case
                else {
                  $desConfigNewTemp = 'cPar_PipeS_PipeA' if($desConfigNew eq 'cPar_PipeS');
                  $desConfigNewTemp = 'cPar_PipeA_PipeA' if($desConfigNew eq 'cPar_PipeA');
                  #save the name of the CG pipe in the symmetrical parallel CG pipe case, 
                  #which is of interest
                  $topCGpipeKey = $key;
                  $topPipeKey = $key;
                }
              }#elsif
              $prevTypeNested = $cgHash->{$topFuncKey}{calls}{$key}{calls}{$keyNested}{type};
              $prevNameNested = $cgHash->{$topFuncKey}{calls}{$key}{calls}{$keyNested}{name};
            }#foreach 
          }#else
          $prevType = $cgHash->{$topFuncKey}{calls}{$key}{type};
          $prevName = $cgHash->{$topFuncKey}{calls}{$key}{name};
        }#foreach PIPE in the top PAR
      }#if the top PAR had pipes
      #update designConfigNew if it has been updated in the previous code block
      $desConfigNew = $desConfigNewTemp;
    }#else: (has child functions)
  #print "desConfigNew = $desConfigNew \n";
  }#elsif: ($topFuncType eq 'par')
  
  #Unable to find a legal/known configuration
  #------------------------------------------
  else {$desConfigNew = 'ILLEGAL';}

  print "TyBEC: $desConfigNew configuration\n";
 
  print "\n\n";
  # print "=====================================\n";
  # print " OBSOLETE  Analysing Configuration   \n";
  # print "=====================================\n";
  # 
  # print "TyBEC: <<<<< $desConf configuration. >>>>>\n\n";
  # print "TyBEC: xxxxx Kernel is Repeated $CODE{launch}{call2main}{kIterSize} times xxxxx\n\n";
  
  # ---------------------------------------------------
  # Catch invalid configurations that were missed by parser
  # ---------------------------------------------------
  
  # ---------------------------------------------------
  # Process cPIPE and cPIPE_PAR configurations
  # ---------------------------------------------------
  
  # size of hash of instructions in appropriate function will tell us the number of stages
  
  
  #
  # if cPIPE or cPIPE_PARs
  # if ( ($desConf eq 'cPIPE') || ($desConf eq 'cPIPE_PARs') )
  # {
  #   print "TyBEC: $pipeTop is the top level pipeline module in the configuration.\n";
  #   print "TyBEC: $stages_pipe_top stages in the $pipeTop pipeline.\n";
  #   print "TyBEC: $CODE{$pipeTop}{instrCount} instructions in $pipeTop \n";
  # 
  #   # add tree elements
  #   #$childL1->name("$pipeTop"."|pipe");
  #   #$mainTree->add_daughter($childL1);
  # 
  #   # check if there are PAR blocks, and if so, which ones
  #   if ($desConf eq 'cPIPE_PARs')
  #   {
  #     print "TyBEC: $CODE{$pipeTop}{insCntrFcall} of these are functional call instructions \n";
  # 
  #     #iterate over all instructions called in top level pipe, and list par functions called:
  #     foreach my $key ( keys %{$CODE{$pipeTop}{instructions}} )
  #     {
  #       # if instruction was a function call instruction
  #       if ($CODE{$pipeTop}{instructions}{$key}{instrType} eq "funcCall")
  #       {
  #         print "TyBEC: $key is called from $pipeTop \n"; 
  #         #$childL1->new_daughter->name($key."|par");
  #       }#if
  #     }#foreach
  #   }#if
  # }#if
  
  # --------------------------------------------------------------------
  # Process cPAR_PIPEs and cPAR_PIPEs_PARs configurations
  # --------------------------------------------------------------------
  # elsif ( ($desConf eq 'cPAR_PIPEs_PARs') || ($desConf eq 'cPAR_PIPEs') )
  # {
  #   print "TyBEC: $parTop is the top level parallel module in the configuration\n";
  #   print "TyBEC: $pipeSecond pipeline is repeated $Npipes times in $parTop \n";
  #   print "TyBEC: $CODE{$pipeSecond}{instrCount} instructions in $pipeSecond \n";
  # 
  # 
  #   # check if there are PAR blocks, and if so, which ones
  #   # check if there are PAR blocks in the PIPE, and if so, which ones
  #   if ($desConf eq 'cPAR_PIPEs_PARs')
  #   {
  #     print "TyBEC: $CODE{$pipeSecond}{insCntrFcall} of these are functional call instructions \n";
  # 
  #     #iterate over all instructions called in top level pipe, and list par functions called:
  #     foreach my $key ( keys %{$CODE{$pipeSecond}{instructions}} )
  #     {
  #       # if instruction was a function call instruction
  #       if ($CODE{$pipeSecond}{instructions}{$key}{instrType} eq "funcCall")
  #       {
  #         print "TyBEC: $key is called from $pipeSecond \n";
  #         #$childL3->new_daughter->name($key);
  #       }#if
  #     }#foreach
  #   }#if
  # 
  #   # add tree elements
  #   #$childL1->name("$parTop"."|par");
  #   #foreach my $i (0..$Npipes-1) 
  #   #  {
  #   #    $childL1->new_daughter->name("$pipeSecond"."|pipe"."|$i");
  #   # }
  #   #$mainTree->add_daughter($childL1);
  # }#elsif
  
  # --------------------------------------------------------------------
  # Check for REPEAT block 
  # --------------------------------------------------------------------
  
  # ------------------------------------
  # Print Configuration Tree
  # ------------------------------------
  #print "\n";
  #print "================================\n";
  #print "       Configuration Tree       \n";
  #print "================================\n";
  #print map "$_\n", @{$launchTree->draw_ascii_tree};
  
  # ------------------------------------
  # -- Analyze memory execution type 
  # ------------------------------------

  # Memory execution model defines three types, and cost model
  # is dependent on them
  
  # Types:
  # ------
  #   A   : HOST streams
  #         Data transferred between
  #         host and device between
  #         each NDRange iteration (host streams)
  #   B   : GLOBAL (Device DRAM) streams
  #         Data transferred between
  #         device-DRAM (global-
  #         memory) and device
  #         between each NDRange
  #         iteration
  #   C   : Local streams 
  #         No data transferred to/from
  #         the device between each
  #         work-group iteration.
  
  
  # NOTE: The assumption is that all streams must be of the same type, 
  #       that is, sourced/sinked to the same type of memory. This is an
  #       unnatural constraint, which should be removed later (TODO)
  
  #loop over stream objects, confirm all are of same type, and then specify memory-exec type
#my $designAddrSpace;
#foreach my $key (keys %{$CODE{launch}{stream_objects}}) {
#    $designAddrSpace = $CODE{launch}{stream_objects}{$key}{memConnAddrSpace};
#    print "key = $key designAddrSpace = $designAddrSpace \n";
#    state $prev = $designAddrSpace;#initialize to first value
#    if ($designAddrSpace != $prev) {
#      die "**ERROR**: All streams must be connected to the same type (address space) 
#            of memory. Non-uniform streams are currently not supported.\n";
#    }
#  $prev = $designAddrSpace;
#}#foreach

  my $designAddrSpace = 1;

  
  $CODE{launch}{memExecModelType} = 'A' if ($designAddrSpace == 5); #host streams
  $CODE{launch}{memExecModelType} = 'B' if ($designAddrSpace == 1); #device-DRAM streams
  $CODE{launch}{memExecModelType} = 'C' if ($designAddrSpace == 2); #local streams
  
  print "\n";
  print "================================\n";
  print "       Memory Execution Model   \n";
  print "================================\n";
  print "TyBEC: This is a Type $CODE{launch}{memExecModelType} design.\n";
}#analyze


# ============================================================================
# ESTIMATE()
# ============================================================================
sub estimate {
  
  print "\n";
  print "============================================================================\n";
  print " THROUGHPUT ESTIMATES       \n";
  print "============================================================================\n\n"; 
  
  #top function name is key
  (my $topPipeName = $topPipeKey) =~ s/\.\d+//;

  # maximum frequency estimate
  my $maxFreq = (1/$CODE{launch}{cost}{PropDelay}) * 1000;
    # in MHz

  #The variables that make up the expression, 
  #-------------------------------------------
    # using the same variable names as used in documentation...
  
  my $mem_exec_type = $CODE{launch}{memExecModelType};
  my $w_s = 32;
    #word size in bits  
    #NOTE: All bandwidths have basic unit of MWords
    #TODO: this is VERY ugly.... the word-size should be derived from data types

  my $h_pb  = ($HardwareSpecs::boards{$main::targetBoard}{hostBW_Peak_Mbps}*1e6)/$w_s;     
    #Host peak bandwidth: TODO.. Update!
  my $rho_h = 1.0;                                                              
    #Host RHO factor. TODO
  my $g_pb = ($HardwareSpecs::boards{$main::targetBoard}{boardRAMBW_Peak_Mbps}*1e6)/$w_s;  
    #Global-mem (Device DRAM) peak bandwidth
  my $rho_g = 'null';
    #device-DRAM RHO factor. TODO
  
  # Since sustained bandwidth is already calculated in the parsed stream objects, 
  # we simply use them, and hence do not need to know peak BW + rho factor.
  # Also, we assume all streams are uniform, and so the sustained bandwidth is 
  # used from any stream object
  # TODO: host sust-BW MUST be udpated
  my $h_sb  = $h_pb * $rho_h;
    #Host sustained bandwidth
  my $g_sb_wps = ($CODE{launch}{cost}{sustBW_Mbps}*1e6)/$w_s;  
    #Global-mem (Device DRAM) sustained bandwidth, in words-per-sec
  my $g_sb_Bps = $g_sb_wps * ($w_s/8); #in bytes-per-sec
  
  my $n_gs  = $CODE{macros}{NLinear};
    # global size (total number of work-items processing per work-unit)
  
  my $k_nl = $CODE{macros}{NLanes};
    #number of parallel lanes of top level pipeline kernel
    #TODO: This is should be extracted from design config., rather than require macro for it

    #my $w_pt  = $CODE{$topPipeName}{wordsPerTupleFromOrToMemoryObjects}; 
  my $w_pt  = $CODE{launch}{totalWordsToFromGmemPerStep}/$k_nl;
    # Words per tuple(input AND output), required for *each* work-item execution
    # on the TOP level pipeline
    # ONLY considers the words to/from Globam-memory
    # This excludes any offset streams, as they are internally generated and do not effect
    # the traffic to memory_objects
    # I am also exclusing streams from CONSTANT memories as they can be expected
    # to be from on-chip memories.
    #note that this wordsPerTuple will accumulate streams across multiple PEs in case
    #of PE scaling. So this will need to be SCALED DOWN to get the number of wordsPerTuple
    #one ONE PE

  my $n_wu  = $CODE{macros}{NKIter};
    # Number of times kernel executed over all NGS work-items

  my $k_pd = $CODE{$topPipeName}{nPipeStages}; 
    #pipeline depth of top-level kernel pipeline

  my $f_d = $maxFreq * (1e6) ;
    #device operating frequency

  my $n_to = 1;
    #cycles per average primitive instruction (word-operation)

  my $n_i = 1;
    #instructions per PE-stage

  my $d_v = 1;
    #degree of vectorization per PE

  my $n_off = 0 ; #TODO
  $n_off = $CODE{$topPipeName}{maxPositiveOffset} 
    if (exists $CODE{$topPipeName}{maxPositiveOffset});
  # Maximum offset of any stream
  # NOTE: This parameter only looks at + streams, as they effect throughput 
  #       It  assumes that all off-set streams are defined in the 
  #       top-level pipeline, which may or may not be a CG pipeline
  #       This is an artificial (simplifying) constraint. TODO
  
  print "The value of variables that make up the EWUT expression:\n";
  print "--------------------------------------------------------\n";
  print "mem_exec_type = $mem_exec_type\n";
  print "n_off = $n_off \n";
  print "h_pb  = $h_pb  \n"; 
  print "h_sb  = $h_sb  \n";
  print "g_pb  = $g_pb  \n";  
  print "g_sb_wps  = $g_sb_wps  \n";      
  print "l_sb  = inf   \n";
  print "n_gs  = $n_gs  \n";
  print "w_pt  = $w_pt  \n";
  print "n_wu  = $n_wu  \n";
  print "k_pd  = $k_pd  \n";
  print "f_d   = $f_d   \n";
  print "n_to  = $n_to  \n";
  print "n_i   = $n_i   \n";
  print "k_nl  = $k_nl  \n";
  print "d_v   = $d_v   \n";
  print "w_s   = $w_s   \n";
  
  # EWUT:
  #------
  # See project report v1.1 for the expressions 
  
  #the two expressions inside the "max" in the EWUT expressions
  my $timeKernelExecution  = ($n_gs*$w_pt*$n_to*$n_i) / ($f_d*$k_nl*$d_v);
  my $timeGmemStreams = ($n_gs*$w_pt) / ($g_sb_wps);

  #the max of the above two wins (constraints) the overall throughput
  my $deisgnLimitedBy;
  my $limitingTime;
  if($timeKernelExecution >=  $timeGmemStreams) {
    $deisgnLimitedBy = 'Compute-bound';
    $limitingTime = $timeKernelExecution;
  }
  else {
    $deisgnLimitedBy = 'Memory-bound';
    $limitingTime = $timeGmemStreams;
  }
  
  #filling the pipeline latency
  my $timeFillPipe = $k_pd / $f_d;
  
  #filling offset buffers latency
  my $timeFillOffsets = $n_off / $g_sb_wps;
  
  #host streams latency (may or may not be repeated across kernel calls)
  my $timeHostStreams = ($n_gs * $w_pt) / ($h_sb);
  
  #time for 1-WU and N-WU (not used for ewut, but used later for BW estimates)
  my $t_1wu;
  my $t_nwu;
  
  #time for N WU
  
  #Now do mem-exec-type-specific calculations:
  my $ewut;
  if ($mem_exec_type eq 'A'){
    $t_1wu =  $timeHostStreams 
           +  $timeFillOffsets 
           +  $timeFillPipe 
           +  $limitingTime;
    $t_nwu = $n_wu * $t_1wu;
    $ewut = 1 / $t_1wu;                
  }
  elsif ($mem_exec_type eq 'B'){
    $t_1wu =  ($timeHostStreams/$n_wu) 
           +  $timeFillOffsets 
           +  $timeFillPipe 
           +  $limitingTime;
    $t_nwu = $n_wu * $t_1wu;
    $ewut = 1 / $t_1wu;
  }
  else {
    $t_1wu =  ($timeHostStreams/$n_wu) 
           +  $timeFillOffsets 
           +  $timeFillPipe 
           +  $timeKernelExecution;
    $t_nwu = $n_wu * $t_1wu;
    $ewut = 1 / $t_1wu;
  }
  
  print "\nEWUT:\n";
  print "----\n";
  print "$ewut Work-Units per second\n";
  print "** $deisgnLimitedBy ** design\n";
  

  # CPWI (Clocks per Work Instance):
  #--------------------------------
  my $execCycleEstSingle 	=  (($n_gs + $k_pd)* $n_to)/$k_nl;
  print "\nCPWI:\n";
  print "----\n";
  print "$execCycleEstSingle cycles-per-work-instance\n";
  
  
  
  
  print "\n";
  print "============================================================================\n";
  print " REQUIRED BANDWIDTH ESTIMATE \n";
  print "============================================================================\n\n";
  
  # Host  / GMem Bandwidth Estimate
  #--------------------------------------------
  #                           bits transported b/w device and global_mem/host/local mem (dep on type)
  # Requred  bandwidth = -----------------------------------------------------------------------------
  #                             total execution time
  #
  # 
  # bits b/w host-device = number of streams x size of each stream x width of each stream
  
  
  
  
  #pick up bits transported between device-host, or device-globalmem, depending on mem-exec type
  my $bitsFromOutsidePerWU ;
  my $bitsToOutsidePerWU   ;
  my $bitsOutsideTotalPerWU;
  if($CODE{launch}{memExecModelType} eq 'A') {
    $bitsFromOutsidePerWU    = $CODE{launch}{hostComm}{from};
    $bitsToOutsidePerWU      = $CODE{launch}{hostComm}{to};
    $bitsOutsideTotalPerWU   = $CODE{launch}{hostComm}{toFrom};
  }    
  elsif($CODE{launch}{memExecModelType} eq 'B') {
    $bitsFromOutsidePerWU    = $CODE{launch}{gMemComm}{from};
    $bitsToOutsidePerWU      = $CODE{launch}{gMemComm}{to};
    $bitsOutsideTotalPerWU   = $CODE{launch}{gMemComm}{toFrom};
  }
  
  # required bandwidth to/from host or GMEM ("outside" data)
  my $estOutsideTotalBW     = ($bitsOutsideTotalPerWU / $t_nwu) * (1/1e6); #Mbps
  my $estOutsideTotalBW_Bps = $estOutsideTotalBW/8; #MBps
  my $estFromOutsideBW      = ($bitsFromOutsidePerWU / $t_nwu) * (1/1e6);
  my $estToOutsideBW        = ($bitsToOutsidePerWU / $t_nwu) * (1/1e6);  
  
  
  #calculating both, but only one will apply depending on mem exec type
  my $hostBwPercent=100*( ($estOutsideTotalBW * 1e6) / $h_sb);  
  my $gMemBwPercent=100*( ($estOutsideTotalBW * 1e6) / $g_sb_wps);
  
  if($CODE{launch}{memExecModelType} eq 'A') {
    print "------------------------------------------------------------------\n";
    print "HOST<-->DEVICE BANDWIDTH REQUIREMENT for TYPE A MEMORY EXECUTION--\n"; 
    print "------------------------------------------------------------------\n";
    print "$estOutsideTotalBW\t Mbits/s\n";
    print "$estOutsideTotalBW_Bps\t MBytes/s\n";
    print "\nwhere:\n";
    print "$bitsFromOutsidePerWU bits\t host   --> device\n";
    print "$bitsToOutsidePerWU bits\t device --> host\n";
    print "$t_nwu\tsec net execution time\n";
    
    #if applicable
    print "\n";
    print "\nHost Bandwidth Utilization Percentage:\n";
    print "---------------------------------------\n";
    print "Host BW percentage utilization =  $hostBwPercent\n";
    print "\n";
    print "Host interface is $HardwareSpecs::boards{$targetBoard}{hostInterface}\n";
    
    if($hostBwPercent >= 100) {
      print "*NOTE*: Estimate of required host bandwidth exceeds available bandwidth. This means design is IO-bound.\n";
    }
  }
  
  elsif($CODE{launch}{memExecModelType} eq 'B') {
    print "------------------------------------------------------------------\n";
    print "DEVICE<-->DRAM BANDWIDTH REQUIREMENT for TYPE B MEMORY EXECUTION--\n"; 
    print "------------------------------------------------------------------\n";
    print "$estOutsideTotalBW\t Mbits/s\n";
    print "$estOutsideTotalBW_Bps\t MBytes/s\n";
    print "\nwhere:\n";
    print "$bitsFromOutsidePerWU bits\t DRAM   --> device\n";
    print "$bitsToOutsidePerWU   bits\t device --> DRAM\n";
    print "$t_nwu\tsec net execution time\n";
    
    #if applicable
    print "\n";
    print "\nDRAM (Global) Bandwidth Utilization Percentage:\n";
    print "---------------------------------------\n";
    print "DRAM (Global Memory) BW percentage utilization =  $gMemBwPercent\n";
    print "\n";
    print "DRAM interface is $HardwareSpecs::boards{$targetBoard}{boardRAM_type}\n";
    
    if($gMemBwPercent >= 100) {
      print "*NOTE*: Estimate of required host bandwidth exceeds available bandwidth. This means design is IO-bound.\n";
    }
  }
  
  
  print "\n";
  print "============================================================================\n";
  print " RESOURCE COST ESTIMATES  (before updates from generation)    \n";
  print "============================================================================\n\n";
  
  print "The Estimated Cost of the Processing Element (excluding base platform) is as follows:\n";
  print Dumper(\%{$CODE{launch}{cost}});
  
  my $alutsPercentKernel = 100*($CODE{launch}{cost}{ALUTS}   / $HardwareSpecs::devices{$targetDevice}{ALUTS});
  my $regsPercentKernel  = 100*($CODE{launch}{cost}{REGS}    / $HardwareSpecs::devices{$targetDevice}{REGS});
  my $m20kPercentKernel  = 100*($CODE{launch}{cost}{M20Kbits}/ $HardwareSpecs::devices{$targetDevice}{M20Kbits});
  my $dspPercentKernel   = 100*($CODE{launch}{cost}{DSPs}    / $HardwareSpecs::devices{$targetDevice}{DSPs});

  #TODO: data-type hardwired here (LAZY!) 
  #TODO: output streams from the top assumed to be = 1 (as AOCL+HDL has this limitation)
  #      and so to get input streams I just take away 1 from the total streams (words per tuple). This is a hack!
  my $inputGmemStreams = $w_pt-1;  #number of input streams of ONE PE
  my $costBasePlat_ref = Cost::costBasePlatform ( 'ui32' , $inputGmemStreams, 1 , $k_nl);
  my %costBasePlat = %$costBasePlat_ref;
   
  #read in cost of base platform from hash returned from cost function
  my $alutsPercentBasePlat = 100* ($costBasePlat{ALUTS}   / $HardwareSpecs::devices{$targetDevice}{ALUTS})    ;
  my $regsPercentBasePlat  = 100* ($costBasePlat{REGS}    / $HardwareSpecs::devices{$targetDevice}{REGS})     ;
  my $m20kPercentBasePlat  = 100* ($costBasePlat{M20Kbits}/ $HardwareSpecs::devices{$targetDevice}{M20Kbits}) ;
  my $dspPercentBasePlat   = 100* (0                      / $HardwareSpecs::devices{$targetDevice}{DSPs})     ;  
  
  #accumulate these costs into the total along with the Kernel costs
  my $alutsPercentTotal= $alutsPercentKernel+ $alutsPercentBasePlat;
  my $regsPercentTotal = $regsPercentKernel + $regsPercentBasePlat ;
  my $m20kPercentTotal = $m20kPercentKernel + $m20kPercentBasePlat ;
  my $dspPercentTotal  = $dspPercentKernel  + $dspPercentBasePlat  ;
  
  print "---------------------------------------------\n";
  print "Resource Utilization Percentage - TOTAL\n";
  print "---------------------------------------------\n";
  print "alutsPercentTotal  = $alutsPercentTotal  \n";
  print "regsPercentTotal   = $regsPercentTotal   \n";
  print "m20kPercentTotal   = $m20kPercentTotal   \n";
  print "dspPercentTotal    = $dspPercentTotal    \n";
  print "\n";
  print "-----------------------------------------------\n";
  print "Resource Utilization Percentage - KERNEL ONLY\n";
  print "-----------------------------------------------\n";
  print "alutsPercentKernel  = $alutsPercentKernel  \n";
  print "regsPercentKernel   = $regsPercentKernel   \n";
  print "m20kPercentKernel   = $m20kPercentKernel   \n";
  print "dspPercentKernel    = $dspPercentKernel    \n";
  print "\n";
  print "Target device is $targetDevice\n";
  print "\n";
  
  if  ( ($alutsPercentTotal >= 100) 
      ||($regsPercentTotal  >= 100)
      ||($m20kPercentTotal  >= 100)
      ||($dspPercentTotal   >= 100) )
  {
    print "WARNING: Estimate of required resources exceeds available resources\n";
    $designFail = 1;
  }  
  
  print "\n";
  print "============================================================================\n";
  print " NEW: ROOFLINE ANALYSIS                                                           \n";
  print "============================================================================\n\n";
  
  #pre-requisite parameters for ROOFLINE:
  #---------------------------------------
  
  # already evaluated
  # w_pt   = Words per tuple (input and output). Already available
  # $l_pi = $n_to = cycles per (word)  instruction. In the typical (and asymptotic) case, it will be 1. Already available.
  #                  can also refer to it as pipeline-stage-latency
  
  # f_d    = the throughput of the kernel (cycles per second). Already available
  
  
  # b_pw   = bytes per word (for memory bandwidth, as well as for operations)
  my $b_pw = $w_s/8; #bytes-per-word is word-size (in bits) / 8
  # n_wops =  Number of WORD operations performed for each execution of the kernel (i.e., for each w_pt words)
  #           When the pipeline is full, these many operations are performed EACH CYCLE  (given n_i = 1)
  # n_bops =  Same as n_wops,only in bytes
  my $n_wops = $glComputeInstCntr;
  my $n_bops = $n_wops * $b_pw;
  
  my $cp_pe_Bops;        #The Computational Power of one PE (in byte-ops / sec)
  my $cp_pe_GBops;       #The Computational Power of one PE (in Giga-byte-ops / sec)
  my $thisScaling;       #Number of times PE is repeated/scaled 
  
  my $cp_pe_Bops_s;      #The Computational Power of scaled (S) PEs (for THIS design)
  my $cp_pe_GBops_s;     #The Computational Power of scaled (S) PEs - GBops
  
  my $cp_pe_Bops_smax;      #The Computational Power of PEs scaled to theoretical MAX
  my $cp_pe_GBops_smax;     #The Computational Power of scaled (S) PEs - GBops
  
  my $ci;                #Computational Intensity (Byte-operations per byte from/to memory)         
  my $bw;                #Bandwidth (bytes/sec) from/to memory. This is the memory used for ci
  my $bw_G;              #Bandwidth (Gbytes/sec) from/to memory. This is the memory used for ci
  my $ci_bw;             #CI x BW
  my $peakTheoBW_GBps;   #Peak Theoretical Bandwidth of target Device+Memory (GB-per-sec)
  my $p_bops;            #Final estimated performance (byte-operations per second)
  my $xATcpRoof;         #value of CI and CP-ROOF (cp_pe_GBops_s)
  
  my $maxScaling;        #depending on the available resources, what it the maximum possible "scaling"
                         #i.e., how many times can we repeat the kernel pipeline
  
  print "TyBEC: Compute operations (word) per work-item (kernel) = $n_wops\n";
  print "TyBEC: Words to/from memory per work-item               = $w_pt\n";


  #Computational Power of 1 PE (baseline CP Roof)
  #----------------------------------------------
  #CP_PE (word-ops/sec) = ( (cycles/sec) / pipeline-stage-latency) * (word-ops-per-kernel)
  #CP_PE (byte-ops/sec) = ( (cycles/sec) / pipeline-stage-latency) * (word-ops-per-kernel) * (bytes/word)
  $cp_pe_Bops = ($f_d / $n_to) * $n_wops * $b_pw * $d_v;
  
  #my $timeKernelExecution  = ($n_gs*$w_pt*$n_to*$n_i) / ($f_d*$k_nl*$d_v);

  $cp_pe_GBops = $cp_pe_Bops * 1e-9;
  print "TyBEC: Computational Power (CP) of one PE = $cp_pe_GBops GBops/sec\n";
  
  #Scaling factor of THIS variant (how many PE replications? / how many kernel pipelines)
  #---------------------------------------------------------------------------------------
  #Number of times PE is repeated/scaled (which is same as the K_NL param)
  $thisScaling = $k_nl;     
  $cp_pe_Bops_s = $cp_pe_Bops * $thisScaling;
  $cp_pe_GBops_s = $cp_pe_Bops_s * 1e-9;

  print "TyBEC: PE scaling of THIS variant    = $thisScaling\n";
  print "TyBEC: CPof scaled PEs (this variant)= $cp_pe_GBops_s GBops/sec\n";

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
  
  my $SCm_aluts = (85-$alutsPercentBasePlat)/$alutsPercentKernel;
  my $SCm_regs  = (85-$regsPercentBasePlat)/$regsPercentKernel;
  my $SCm_m20k  = (85-$m20kPercentBasePlat)/$m20kPercentKernel;
  my $SCm_dsp   = (85-$dspPercentBasePlat) /$dspPercentKernel;
    
  $maxScaling =  min ( $SCm_aluts
                     , $SCm_regs 
                     , $SCm_m20k 
                     , $SCm_dsp  
                     );
  
#my $maxUtil = max ( $alutsPercentTotal
#                    , $regsPercentTotal
#                    , $m20kPercentTotal 
#                    , $dspPercentTotal  )  ;
#                    
  #we restrict the scaling upto 85% of (ANY) resource utilization, to allow for the synthesis tool P&R limitation. Is this sensible? 
  #Hence I am scaling up to 60% resources
#  $maxScaling =  int(85/$maxUtil);  
  
  $cp_pe_Bops_smax  = $cp_pe_Bops_s * $maxScaling;
  $cp_pe_GBops_smax = $cp_pe_Bops_smax * 1e-9;
  
  print "TyBEC: Theoretical maximum PE scaling         = $maxScaling\n";
  print "TyBEC: CP of PEs scaled to theoretical maximum= $cp_pe_GBops_smax GBops/sec\n";
  
  
  #Computational Intensity
  #---------------------------
  #CI = (word-ops-per-kernel * bytes-per-word-op) / (words-per-in-out-tuple * bytes-per-word)
  #      bytes-per-word cancel out...
  print "n_wops = $n_wops \n";
  print "w_pt = $w_pt \n";
  $ci =  $n_wops/$w_pt;
  print "TyBEC: Computational Intensity                                      = $ci Byte-op/Byte-trasfer\n";
  
  #Bandwidth
  #---------------------------
 
  $peakTheoBW_GBps = ($HardwareSpecs::boards{$main::targetBoard}{boardRAMBW_Peak_GBps});
  #BW = max bytes per second to/from memory (for ROOF, this is peak, for CEIL we use sustainable based on design)
  $bw     = $g_sb_Bps; #bytes-per-sec
  $bw_G   = $bw * 1e-9;
  $ci_bw  = $ci * $bw;

  $xATcpRoof = $cp_pe_Bops_s / $bw; #the value of CI where the two roofs meet, 

  print "TyBEC: Sustained Memory Bandwidth (this variant)                    = $bw_G GB/sec\n";
  print "TyBEC: Theoretical Peak Memory Bandwidth (chosen target)            = $peakTheoBW_GBps GB/sec\n";
  print "\n";
  
  #Final Performance
  #---------------------------
  #PERF (BYTE-OPS-PERSEC) = min (CP_PE*scale, CI*BW)
  $p_bops = min($cp_pe_Bops_s, $ci_bw);
  my $p_Gbops = $p_bops * 1e-9;
  my $p_Gbops_round = (int($p_Gbops*10+0.5))/10;
  
  print "TyBEC: The BOPS/sec performance is the minimum of CP_PE (Computational Performance Roof) and CI*BW (Computational Intensity x Bandwidth)\n";
  print "\n";
  print "TyBEC: Computation-Bound, CP_PE  x SCALE  = $cp_pe_Bops_s\tBops/sec\n";
  print "TyBEC: Bandwidth-Bound,   CI x BW         = $ci_bw\tBops/sec\n";
  print "\n";
  print RED "TyBEC: Estimated ASYMPTOTIC Performance from Roofline Analysis\t= ***$p_Gbops_round GBop/sec*** is the \n"; print RESET;
  print "TyBEC: ASYMPTOTIC --> Effect of filling up offset buffers and pipeline not considered\n";
  
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
  $genCode =~ s/<designCP>/$p_Gbops_round/g;
  
  
  #target TEX file
  make_path("TybecBuild/roofline");
  my $targetFilename = "TybecBuild/roofline/rooflineplot".".tex";  
  open(my $fh, '>', $targetFilename)
    or die "TyBEC: Could not open file '$targetFilename' $!";  
  print $fh $genCode;
  print "TyBEC: Generated custom ROOFLINE plot TEX file \n";
  close $fh;

  #--------------------------------------
  print "\n";
  print "============================================================================\n";
  print " TEMP: Comparison of Roofline Analysis with EWIT figures \n";
  print "============================================================================\n\n";
  
  print "TyBEC: $ewut work-instances/sec from EWIT analysis\n";
  
  #Convert to Bops/sec
  # byte-ops-persec = (WI/sec)  x  (#work-items (i.e. global-size, or # of kernel iter's))  x (Byte-ops/iter)
  my $p_bops_ewit  = $ewut * $n_gs * $n_bops;
  my $p_Gbops_ewit = $p_bops_ewit * 1e-9;
  print "TyBEC: ** $p_Gbops_ewit\tGBop/sec ** is the estimated  Performance from EWIT Analysis\n";
  print "TyBEC: ** $p_Gbops\tGBop/sec ** is the estimated ASYMPTOTIC Performance from Roofline Analysis\n";

  
}



# ============================================================================
# GENERATE()
# ============================================================================
sub generate {
  #locals
  my $hdlFileName;
  my $hdlfh;

  print "\n";
  print "=================================================\n";
  print " Verilog HDL Code Generation   					\n";
  print "=================================================\n";
  
  my $err = 1;
  # >>>>>>>>>>>>> copy in header file
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/includeTytraCommon.v", $outputRTLDir);
    print "TyBEC: Imported Tytra header file\n";  
  # >>>>>>>>>>>>> Import cores used directly
  # TODO: should only import cores needed by the design
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/pipelined_cores/PipePE_ui_add.v", $outputRTLDir);
    print "TyBEC: Imported module PipePE_ui_add\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/pipelined_cores/PipePE_ui_sub.v", $outputRTLDir);
    print "TyBEC: Imported module PipePE_ui_sub\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/pipelined_cores/PipePE_ui_mul.v", $outputRTLDir);
    print "TyBEC: Imported module PipePE_ui_mul\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/math_cores/ui_add.v", $outputRTLDir);
    print "TyBEC: Imported module ui_add\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/math_cores/ui_sub.v", $outputRTLDir);
    print "TyBEC: Imported module ui_sub\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/math_cores/ui_mul.v", $outputRTLDir);
    print "TyBEC: Imported module ui_mul\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/buffer_cores/delayline_z1.v", $outputRTLDir);
    print "TyBEC: Imported module delayline_z1\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/memory_cores/LMEM.v", $outputRTLDir);
    print "TyBEC: Imported module LMEM\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/memory_cores/LMEM_1RP_1WP.v", $outputRTLDir);
    print "TyBEC: Imported module LMEM_1RP_1WP\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/memory_cores/LMEM_1RP_2WP.v", $outputRTLDir);
    print "TyBEC: Imported module LMEM_1RP_1WP\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/memory_cores/LMEM_1RP_4WP.v", $outputRTLDir);
    print "TyBEC: Imported module LMEM_1RP_1WP\n";
  $err &= copy ("$TyBECROOTDIR/hdlCoresTybec/memory_cores/LMEM_4RP_1WP.v", $outputRTLDir);
    print "TyBEC: Imported module LMEM_1RP_1WP\n";
  #copy ('./hdlCoresTybec/memory_cores/LMEM.v', $outputRTLDir);
  #  print "TyBEC: Imported module LMEM\n";
    # memory cores cant be instantiated here as we would need multi-port 
    # with specific configurations that are design dependant

  if(!$err) {
    die "TyBEC: **ERROR** importing one or more TyTra Cores\n";
  }
  
  # --------------------------------------------------
  # Identify top and leaf functions
  # --------------------------------------------------
  #reduce clutter, and get keys of all funcs called by main (should be just one)
  my $cgHash = $CODE{callGraph}{launch}{calls}{main}{calls}; 
  my @cgHashKeys = keys %{$cgHash}; 

  #get the name and type of top function, 
  # and the keys of all function it calls (if any), and the number of child Funcs
  my $topFuncKey  = $cgHashKeys[0];
  my $topFuncType = $cgHash->{$topFuncKey}{type};
  my $topFuncName = $cgHash->{$topFuncKey}{name};    
  #my @topChildrenKeys = keys %{$cgHash->{$topFuncKey}{calls}};
  #my $topChildrenNum  = @topChildrenKeys;

  #local variables
  # my @leafPipeFuncs; # Array of leaf-level pipeline functions
  # my $leafPipeFun; #to make obsolete
  # my $topParFun; #to make obsolete
  
  ## DO I NEED THE FOLLOWING BLOCK?
  ## # cPipe - leaf and top functions are same
  ## #------------------------------------------
  ## if ($desConfigNew eq 'cPipe') {
  ##   print "TyBEC: $topFuncName is the top level pipeline module in the configuration.\n";
  ##   #$leafPipeFuncs[0] = $pipeTop; #only one leaf level function, same as top in this config
  ##   $leafPipeFuncs[0] = $cgHash->{$topFuncKey}{calls}{$topChildrenKeys[0]};    
  ## }
  ## 
  ## # cPar_PipeS: Parallel array of symmetric pipes
  ## # ----------------------------------------------
  ## #  ..cPar_PipeA not supported yet, so all concurrent pipelines must be symmetric
  ## elsif ($desConfigNew eq 'cPar_PipeS') {
  ##   print "TyBEC: $topFuncName is the top level parallel module in the configuration\n";
  ##   
  ##   #which PIPE function is called repeatedly from top PAR?
  ##   #since multiple *symmetric* pipes called from the top func, so the name of any one of them will do
  ##   #so get the keys and select first
  ##   $leafPipeFuncs[0] = $cgHash->{$topFuncKey}{calls}{$topChildrenKeys[0]};    
  ## }#elsif
  ## 
  ## # cPipe_PipeA: Coarse-level pipeline of asymmetric pipelines
  ## #-------------------------------------------------------------
  ## elsif ($desConfigNew eq 'cPipe_PipeA') {
  ##   print "TyBEC: $topFuncName is the top level pipeline module in this CG-pipeline configuration\n";
  ## 
  ##   my $j = 0;
  ##   #which PIPE functions are called from top CG-PIPE?
  ##   foreach my $key (keys %{$cgHash->{$topFuncKey}{calls}}) {
  ##       print "TyBEC: $key is a second (leaf) level pipeline function in the CG-pipeline\n";
  ##       $leafPipeFuncs[$j] = $key;
  ##       $j++;
  ##   }#foreach        
  ## }#elsif
   
  # ========================================================
  # LEAF PIPES: Generate code for all leaf PIPEs 
  # -- Generate **ComputePipe** module for each leaf PIPEs
  #   -- also generating any required COMBI module
  # -- Generate **CorePipe** module for each leaf PIPE
  # ========================================================
  
  #only for those configurations that have leaf PIPE(s)
  if  (   ($desConfigNew eq 'cPipe') 
      ||  ($desConfigNew eq 'cPar_PipeS')
      ||  ($desConfigNew eq 'cPipe_PipeA') 
      ||  ($desConfigNew eq 'cPar_PipeS_PipeA') ){
  
    #collect keys for PIPE func(s), depending on configuration
    # if top is the leaf PIPe (cPipe), then key collected differently than if a PAR/PIPE top has PIPE children
    my @leafPipeFuncKeys;
    
    #If the configuration depth = 1 with just one pipeline, then that is the only leaf pipeline
    if ($desConfigNew eq 'cPipe') {
      push @leafPipeFuncKeys, $topFuncKey; }
    #If the configuration depth = 2, then leaf pipelines are those called by top module
    #which may be pipe or par
    elsif (   ($desConfigNew eq 'cPar_PipeS')
          ||  ($desConfigNew eq 'cPipe_PipeA') ){
      @leafPipeFuncKeys = keys %{$cgHash->{$topFuncKey}{calls}};}
  
    #If the config depth = 3 (limited to cPar_PipeS_PipeA)
    elsif ($desConfigNew eq 'cPar_PipeS_PipeA') {
      # the CG pipeline would have been identified in the analyze() stage, so use
      # it now to find keys to all leaf-level pipes
      @leafPipeFuncKeys = keys %{$cgHash->{$topFuncKey}{calls}{$topCGpipeKey}{calls}};
    }#elsif
    else {}
  
    #now that we have located all leaf pipelines, generate them
    #outer for loop for each leaf pipeline
    foreach my $pipeFuncKey (@leafPipeFuncKeys) {
      #get name of PIPE function; remove .N from key
      (my $pipeFuncName = $pipeFuncKey) =~ s/\.\d+//;
      
      # --------------------------------------------------
      # COMB modules generation
      # --------------------------------------------------
      #loop over each INSTRUCTION in the pipeline function, and identify COMB func calls
      #and generate them
      foreach my $instrKey (keys %{$CODE{$pipeFuncName}{instructions}} ) {
        #check if instruction is function call instruction
        if ($CODE{$pipeFuncName}{instructions}{$instrKey}{instrType} eq 'funcCall') {
          #now check if that function call instruction is for a function of type COMB
          # TODO: INsert check here to ensure the same comb function is not repeatedly generate - though no harm really?
          if ($CODE{$pipeFuncName}{instructions}{$instrKey}{funcType} eq 'comb') {
            #extract name of function from instruction key (remove .N)
            (my $instrName = $instrKey) =~ s/\.\d+//;
            # open verilog target file
            my $hdlFileName = "$outputRTLDir/CustomComb_$instrName".".v";
            open(my $hdlfh, '>', $hdlFileName)
              or die "Could not open file '$hdlFileName' $!";   
            
            # generate file from template
            #args: 
            # - file handler for generated file
            # - module name
            # - design name
            # - hash for relevant leaf level PIPE function
            HdlCodeGen::genCustomComb($hdlfh, "CustomComb_$instrName", 'untitled', $CODE{$instrName}); 
          }#if COMB
        }#if funcCall instr
      }#foreach instrKey

      # --------------------------------------------------
      # Generate Compute_PIPE module 
      # --------------------------------------------------
      # Now that any required COMB blocks have been generated, generate the PIPE module
      
      # open verilog target file
      $hdlFileName = "$outputRTLDir/ComputePipe_$pipeFuncName".".v";
      open($hdlfh, '>', $hdlFileName)
        or die "Could not open file '$hdlFileName' $!";   
      
      # generate file from template
      #args: 
      # - file handler for generated file
      # - module name
      # - design name
      # - hash for relevant leaf level PIPE function
      HdlCodeGen::genComputePipe($hdlfh, "ComputePipe_$pipeFuncName", 'untitled', $CODE{$pipeFuncName}); 
      
      # --------------------------------------------------
      # Generate the corePipe for each leaf PIPE
      # --------------------------------------------------
      
      # Create Cores for Compute-Pipes only if they are the top-level pipes, and there
      # is no parent CG pipeline
      if  (   ($desConfigNew eq 'cPipe') 
      ||  ($desConfigNew eq 'cPar_PipeS') ){      
        #for loop for each pipe
        # open verilog target file
        $hdlFileName = "$outputRTLDir/CorePipe_$pipeFuncName".".v";
        open($hdlfh, '>', $hdlFileName)
          or die "Could not open file '$hdlFileName' $!";   
        
        # generate file from template
        #args: 
        # - file handler for generated file
        # - module name
        # - design name
        # - target directory needed as this generator can spawn its own genrator calls (for offsetStreams)
        # - hash for relevant leaf level PIPE function
        HdlCodeGen::genCorePipe($hdlfh, "CorePipe_$pipeFuncName", 'untitled', $outputRTLDir, $CODE{$pipeFuncName});
      }#if
    }#foreach pipeFuncKey
  }#if config has LEAF pipes

  # ================================================================
  # PARENT PIPES: generate top-level parent CG-Pipe (if applicable)
  # ================================================================
  #for now only relevant for cPipe_PipeA and cPar_PipeS_PipeA
  if  (   ($desConfigNew eq  'cPipe_PipeA')
      ||  ($desConfigNew eq  'cPar_PipeS_PipeA') ){
      
      #get name from key
      (my $topCGpipeName = $topCGpipeKey) =~ s/\.\d+//;
      
      # Generate the Compute-Pipe
      # -------------------------
      $hdlFileName = "$outputRTLDir/ComputePipe_$topCGpipeName".".v";
      open($hdlfh, '>', $hdlFileName)
        or die "Could not open file '$hdlFileName' $!";   
      
      # generate file from template
      #args: 
      # - file handler for generated file
      # - module name
      # - design name
      # - target directory needed as this generator can spawn its own genrator calls (for offsetStreams)
      # - hash for relevant leaf level PIPE function
      HdlCodeGen::genComputePipe_CG($hdlfh, "ComputePipe_$topCGpipeName", 'untitled', $CODE{$topCGpipeName}); 
  
      # Generate the Core
      # -------------------------
      $hdlFileName = "$outputRTLDir/CorePipe_$topCGpipeName".".v";
      open($hdlfh, '>', $hdlFileName)
        or die "Could not open file '$hdlFileName' $!";   
      # generate file from template
      # args: 
      # - file handler for generated file
      # - module name
      # - design name
      # - target directory needed as this generator can spawn its own genrator calls (for offsetStreams)
      # - hash for relevant leaf level PIPE function
      HdlCodeGen::genCorePipe($hdlfh, "CorePipe_$topCGpipeName", 'untitled', $outputRTLDir, $CODE{$topCGpipeName});
  }#if

  # ------------------------------------------------------
  # generate the ComputePipe for each leaf PIPE
  # ------------------------------------------------------
  # 
  # #only for those configurations that have leaf PIPE(s)
  # if  (   ($desConfigNew eq 'cPipe') 
  #     ||  ($desConfigNew eq 'cPar_PipeS')
  #     ||  ($desConfigNew eq 'cPipe_PipeA') ){
  # 
  #   #collect keys for PIPE func(s), depending on configuration
  #   # if top is the leaf PIPe, then key collected differently than if PAR/PIPE top has PIPE children
  #   my @leafPipeFuncKeys;
  #   if ($desConfigNew eq 'cPipe') {
  #     push @leafPipeFuncKeys, $topFuncKey; }
  #   else {
  #     @leafPipeFuncKeys = keys $cgHash->{$topFuncKey}{calls};}
  #     
  #   # Now that keys are collected, generated modules for each
  #   foreach my $pipeFuncKey (@leafPipeFuncKeys) {
  #   
  #     #get name of function corresponding to this key
  #     
  #     #for loop for each LEAF pipe
  #     # open verilog target file
  #     my $hdlFileName = "$outputRTLDir/ComputePipe_$pipeFuncKey".".v";
  #     open(my $hdlfh, '>', $hdlFileName)
  #       or die "Could not open file '$hdlFileName' $!";   
  #     
  #     # generate file from template
  #     #args: 
  #     # - file handler for generated file
  #     # - module name
  #     # - design name
  #     # - hash for relevant leaf level PIPE function
  #     HdlCodeGen::genComputePipe($hdlfh, "ComputePipe_$pipeFuncKey", 'untitled', $CODE{$pipeFuncKey}); 
  #   }#foreach leaf 
  # }#if leaf pipe(s)
  
  
  # --------------------------------------------------
  # >>>>>>>>>>>>> generate the corePipe
  # --------------------------------------------------
  
  # #for loop for each pipe
  # # open verilog target file
  # $hdlFileName = "$outputRTLDir/CorePipe_$leafPipeFun".".v";
  # open($hdlfh, '>', $hdlFileName)
  #   or die "Could not open file '$hdlFileName' $!";   
  # 
  # # generate file from template
  # #args: 
  # # - file handler for generated file
  # # - module name
  # # - design name
  # # - target directory needed as this generator can spawn its own genrator calls (for offsetStreams)
  # # - hash for relevant leaf level PIPE function
  # HdlCodeGen::genCorePipe($hdlfh, "CorePipe_$leafPipeFun", 'untitled', $outputRTLDir, $CODE{$leafPipeFun}); 
  
  # --------------------------------------------------
  # >>>>>>>>>>>>> generate the Compute Unit 
  # --------------------------------------------------
 
  $hdlFileName = "$outputRTLDir/ComputeUnit.v";
  open($hdlfh, '>', $hdlFileName)
    or die "Could not open file '$hdlFileName' $!";   

  #HdlCodeGen::genComputeUnit($hdlfh, $outputRTLDir, "ComputeUnit", 'untitled', 1, \%CODE, $topFuncName);
  #get the name of the top level pipe function
  #which may or may not be the overall top function
  #and may or may not be replicated in a PAR block
  (my $topPipeName = $topPipeKey) =~ s/\.\d+//;
  
  # C2 configuration: single pipeline
  if ( ($desConfigNew eq 'cPipe') 
    || ($desConfigNew eq 'cPipe_PipeA') ) {
    # generate file from template
    #args: 
    # - file handler for generated file
    # - target dir of codeGen required for importing LMEM module 
    # - module name
    # - design name
    # - num of pipelines
    # - hash for CODE
    # - name of leaf level pipeline function
  HdlCodeGen::genComputeUnit($hdlfh, $outputRTLDir, "ComputeUnit", 'untitled', 1, \%CODE, $topPipeName); 
  }
  
  # C1 configuration: PAR over Symmetrical PIPEs
  elsif (   ($desConfigNew eq 'cPar_PipeS') 
        ||  ($desConfigNew eq 'cPar_PipeS_PipeA') ) {
    # generate file from template
    #args: 
    # - file handler for generated file
    # - target dir of codeGen required for importing LMEM module 
    # - module name
    # - design name
    # - num of pipelines
    # - hash for CODE
    # - name of pipeline function (may be CG) that is repeated symmetrically in PAR
    # - name of top level par function
  HdlCodeGen::genComputeUnit($hdlfh, $outputRTLDir, "ComputeUnit", 'untitled', $NparPipes, \%CODE, $topPipeName, $topFuncName); 
  }
  
  # Not a valid configuration for Generation
  else {die "This configuration is currently not supported for code-generation. If you only wish to analyze and cost the configuration, run tybec on without the --g (generate) flag";}
  
  # --------------------------------------------------
  # >>>>>>>>>>>>> generate the Compute Device
  # --------------------------------------------------
  
  # # open verilog target file
  # $hdlFileName = "$outputRTLDir/ComputeDevice.v";
  # open($hdlfh, '>', $hdlFileName)
  #   or die "Could not open file '$hdlFileName' $!";   
  # 
  # # C2 configuration: single pipeline
  # if ( ($desConf eq 'cPIPE') || ($desConf eq 'cPIPE_PARs') || ($desConf eq 'cPIPE_COMBs') ) {
  #   # generate file from template
  #   #args: 
  #   # - file handler for generated file
  #   # - module name
  #   # - design name
  #   # - hash for relevant TOP LEVEL function (the one called from main)
  # #  HdlCodeGen::genComputeDevice($hdlfh, "ComputeDevice", 'untitled', 1, \%CODE, $leafPipeFun); 
  # }
  # # C1 configuration: PAR over PIPE
  # elsif ( ($desConf eq 'cPAR_PIPEs_PARs') || ($desConf eq 'cPAR_PIPEs') || ($desConf eq 'cPAR_PIPEs_COMBs') ) {
  #   # generate file from template
  #   #args: 
  #   # - file handler for generated file
  #   # - module name
  #   # - design name
  #   # - num of pipelines
  #   # - hash for CODE
  #   # - name of leaf level pipeline function
  #   # - name of top level par function
  # #  HdlCodeGen::genComputeDevice($hdlfh, "ComputeDevice", 'untitled', $Npipes, \%CODE, $leafPipeFun, $topParFun); 
  # }
    
  # --------------------------------------------------
  # >>>>>>>>>>>>> generate Custom Configuration File
  # --------------------------------------------------
  
  # open verilog target file
  $hdlFileName = "$outputRTLDir/includeCustomConfig.v";
  open($hdlfh, '>', $hdlFileName)
    or die "Could not open file '$hdlFileName' $!";   
  
  # generate file from template
  #args: 
  # - file handler for generated file
  # - design name
  # - (reference to) hash for relevant TOP LEVEL function (the one called from main)
  HdlCodeGen::genCustomConfig($hdlfh, 'untitled', \%CODE); 
  
  # #Print compile time and duration.
  # my $end = Time::HiRes::gettimeofday();
  # #print  "Build started at $end\n";
  # printf ("Build took %.2f seconds\n", $end - $start);
  
  
  # -------------------------------------------------------------------
  # >>>>>>>>>>>>> print costs again as GENERATE too updates COSTS"
  # -------------------------------------------------------------------
  #FIXE: This is an ugly hack?
  
  
  print "\n";
  print "============================================================================\n";
  print " RESOURCE COST ESTIMATES AFTER UPDATES FROM GENERATION       \n";
  print "============================================================================\n\n";
  
  print "The Estimated Cost of the Compute Unit is as follows:\n";
  print Dumper(\%{$CODE{launch}{cost}});
  
}#sub

# ----------------------------------------------------------------------------
#
# ----------------------------------------------------------------------------
sub printHelp {
  print "\ntybec command line options and default values\n";
  print "---------------------------------------------\n\n";
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
  print "--e    [ON]            :Estimate Resources and Performance from TIRL\n";
  print "--dot  [OFF]           :Run DOT and display graph at the end of compile\n";
  print "--tar  [bolamaNallatech] :Target board [philpotsMaxeler/bolamaNallatech/bolamaAlphadata]\n";
}

# ----------------------------------------------------------------------------
#
# ----------------------------------------------------------------------------
sub printVer {
  print "\nThis is TyBEC Release $tybecRelease\n\n";
  print "This is an in-house release and on-going work\n";
  print "For help, type \"tybec.pl --h\"\n"; 
}





