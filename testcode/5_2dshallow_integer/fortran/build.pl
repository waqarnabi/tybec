#!/usr/bin/perl -w

use strict;
use warnings;

#Warning: This clears all profiling data and annotated source
#------------------------------
if ($ARGV[0] eq '-c') {
  system("rm *o *exe *dat *mod *mod0");
  system("rm -r oprofile_data");
  system("rm -r annotated");
  system("rm gprofreport.log gmon.out");
}

#Just build (no debug info)
#------------------------------
elsif ($ARGV[0] eq '-b') {
  system("gfortran -c param.f95 sub.f95");
  system("gfortran -o run.exe main.f95 param.o sub.o");
}

##Build and Run with  OPROFILER
#------------------------------
elsif ($ARGV[0] eq '-opr') {
  
  #compile
  system("gfortran -g -c param.f95 sub.f95");               #build modules
  system("gfortran -g -o run.exe main.f95 param.o sub.o");  #build  exe
  
  #run
  system("operf ./run.exe");                                #run exe via profiler
  
  #create oprofile report
  system("opreport"                                         #print report    
         ." --callgraph"
         ." --debug-info"
         ." --symbols"
         ." --exclude-dependent"
         ." --output-file opreport.log"
#         ." --global-percent"
#         ." --threshold 1"
#         ." --verbose"
         );

#emit annotated code using oprofile  
system("opannotate"                            #generate annotated source code
      ." --session-dir=oprofile_data/"
      ." --output-dir=annotated"
      ." --source"
#      ." --exclude-dependent"
      );                                                        
}

##Build and Run with  GPROF
#------------------------------
elsif ($ARGV[0] eq '-gpr') {
  
  #compile
  system("gfortran -g -pg -c param.f95 sub.f95");               #build modules
  system("gfortran -g -pg -o run.exe main.f95 param.o sub.o");  #build  exe
  
  #run
  system("./run.exe");                                #run exe
  
  #create gprof report
  system("gprof"
        ." --print-path"
        ." ./run.exe > gprofreport.log"
      );                                                           
}


#plain build and run
#-------------------
elsif ($ARGV[0] eq '-r') {
  system("gfortran -c param.f95 sub.f95");
  system("gfortran -o run.exe main.f95 param.o sub.o");
  system("./run.exe");
}

#help
#------
elsif ($ARGV[0] eq '-h') {
  print "Usage: ./build.pl <flag>\n";
  print "FLAGS\n";
  print "-c  = clean\n";
  print "-b  = plain build\n";
  print "-opr = profiled build and run (operf)\n";
  print "-gpr = profiled build and run (gprof)\n";
  print "-r  = plain build and run\n";
}
else {die "Unrecognized command line";}