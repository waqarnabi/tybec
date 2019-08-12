#!/usr/bin/perl -w
use strict;
use warnings;

#external
use Getopt::Long;       #for command line options
use File::Slurp;
use Parse::RecDescent;  #the parser module
use Regexp::Common;     #generate common regexs from this utility
use Data::Dumper;

#set clang and opt executables here
my $CLANG ="clang";
my $OPT ="opt-3.8.1";


#globals shared across packages
our $outTirBuff = '';#string buffer for output TIR file
our %cltCode;   #hash for tokens from parsed llvm code
our $linSize;   #linear size of array(s)

#locals
my $TyBECROOTDIR = $ENV{"TyBECROOTDIR"};



##--------------------------------
## input file and output directory
##--------------------------------
my $inputFileC    = ''; 
my $outputFileTir = '';	  
GetOptions (
    'i=s'   => \$inputFileC       #--i    <input C File>
  , 'o=s'   => \$outputFileTir    #--o    <output TIR File>
  );

(my $without_extension = $inputFileC) =~ s/\.[^.]+$//;
our $outputBuildDir = "build_".$without_extension;
my $llInt = $without_extension."_intermediate.ll";
my $llFinal = $without_extension."_optimized.ll";
$outputFileTir = $without_extension.".tirl" if($outputFileTir eq '');

##--------------------------------
## run clang, generate llvm
##--------------------------------
print("******************************************************************\n");
print("C-to-LLVM-to-TIR v0.1\n");
print("******************************************************************\n");
print("CLT:: Create output build directory: ok\n");
system("rm -r $outputBuildDir");
mkdir($outputBuildDir);
chdir($outputBuildDir);

#run clang with -O0
system("$CLANG -O0 -S -Wunknown-attributes -emit-llvm ../$inputFileC -o $llInt"); 
print("CLT:: Clang on input: ok\n"); 

#apply mem2reg optimization as redundance in dataflow paradigm of TIR
system("$OPT -S -mem2reg $llInt -o $llFinal"); 
print("CLT:: Run llvm mem2reg opt: ok\n"); 

##--------------------------------
## read in llvm
##--------------------------------
my $fhLlvm;
open($fhLlvm, "<", "$llFinal");
##just testing
#$llFinal="../testTemp.ll";
open($fhLlvm, "<", "$llFinal") 
  or die "Could not open file '$llFinal' $!";
my @llvmLines = grep { not /;.*/ } <$fhLlvm>; #remove comments while reading file
#chomp(my @llvmLines = <$fhLlvm>);
close $fhLlvm;  
print("CLT:: Read in optimizied llvm-IR: ok\n"); 

##--------------------------------
## convert to tir
##---------------

#read in grammar from file
my $cltGrammarFileName = "$TyBECROOTDIR/lib-intern/c2llvm2tir4flat/llvmGrammar.pm"; 
open (my $cltFhTemplate, '<', $cltGrammarFileName)
 or die "Could not open file '$cltGrammarFileName' $!";     
our $cltGrammar = read_file ($cltFhTemplate);
close $cltFhTemplate;

#create and call parser
our $cltParser;
$cltParser = Parse::RecDescent->new($cltGrammar);
$cltParser->STARTRULE("@llvmLines") or die "clt-Parser start rule failed!"; 
print("CLT:: Parse llvm-IR and generate Tytra-IR string: ok\n");


##----------
## write tir
##----------
my $fhTir;
open ($fhTir, "> $outputFileTir") || die "problem opening $outputFileTir\n";

#put time stamp
my $timeStamp   = localtime(time);
$outTirBuff = ";-- Generation time stamp :: $timeStamp\n".$outTirBuff;

#write created string buffer to TIR file
print $fhTir $outTirBuff;
#foreach (@llvmLines) { 
#   print $fhTir $_ . "\n";        
#}
close $fhTir;
print("CLT:: Write  Tytra-IR to file: ok\n");              
print("CLT:: Now calling TYBEC on the generated TIR\n\n\n");            

##----------------------------
## call TYBEC on generated TIR
##----------------------------
# --clt paramter tells tybec it has been called by this tool
system("tybec.pl --clt --i $outputFileTir --g");

#post
#-----
my $logFilename = "llvmTokens.log";
  open(my $outfh, '>', "$logFilename")
    or die "Could not open file '$logFilename' $!";
print $outfh Dumper(\%cltCode); 







