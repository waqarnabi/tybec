{ use Regexp::Common qw(URI);}

# ============================================================================
#  Common Patterns
# ============================================================================
 INTEGER      : /$RE{num}{int}/  
 NAME         : /[^,=()":\s<>]+/  # one or more characters
 DATA_TYPE    : /ui\d+/           # unsigned integer: ui followed by 1 or more numbers (TIR specific, not LLVM)
              | /i\d+/            # signed integers (or in LLVM-speak, integers)
              | /float\d+/        # sized floating point (if 32/64, then standard IEEE, otherwise custom) 
 POINTER_TYPE : DATA_TYPE "\*"
              {$return = $item{DATA_TYPE}."*";}
 FUNC_NAME    : NAME
 LOCAL_VAR    : "%" NAME
 LOCAL_VAR1   : LOCAL_VAR
 LOCAL_VAR2   : LOCAL_VAR
              #  {$return = "%".$item{NAME};}
 GLOBAL_VAR   : "@" NAME
              # {$return = "@".$item{NAME};}
 VARIABLE     : LOCAL_VAR
              | GLOBAL_VAR
 ARG_NAME     : VARIABLE
 ARG_TYPE     : POINTER_TYPE
              | DATA_TYPE
              #POINTER_TYPE *must* be tested first, as DATA_TYPE is contained in it, and 
              #that will match first if we try to match both with DATA_TYPE first
 DEST_TYPE    : DATA_TYPE
 OPER_DEST    : VARIABLE
 ARITH_OPS    : "add" 
              | "mul"
              | "sub"
              | "udiv"
              | "sdiv"  
 LOGICAL_OPS  : "or"
              | "and"              
 OP           : ARITH_OPS
              | LOGICAL_OPS
 OP_TYPE      : DATA_TYPE   
 EXPRESSION   : /[\d\+\*\-\/()\ ]+/ # Expressions should be calculalable by EVAL
                                    # this regex only allows integer numbers, no variables
                                    # not sure if this is 100% correct regex FIXME
IMM_INT_OPER  : EXPRESSION          # Immediate operand can be an expression as well, and we will always EVAL an IMM_INT_OPER
              {$return = eval($item{EXPRESSION});}
POS_CONSTANT  : /\d+/
NEG_CONSTANT  : /-\d+/
CONSTANT      : /-?\d+/   
OPER          : IMM_INT_OPER
              | CONSTANT
              | LOCAL_VAR
              | GLOBAL_VAR
OPER1         : OPER
OPER2         : OPER
OPER3         : OPER

WRAP          : "nuw"
              | "nsw"
ALIGN         : "align" POS_CONSTANT

ANNOT_NAME    : "@" NAME
ALL2NEWLINE   : /[^\n]+\n/  

#===========================================================================
# Function Definitions 
#===========================================================================

#Possible instructions
#---------------------
ENTRY         : "entry" ":" 
RETURN_IV : "ret" "void"
RETURN_I  : "ret" DATA_TYPE LOCAL_VAR
COMPUTE_I : OPER_DEST "=" OP WRAP OP_TYPE OPER1 "," OPER2
              {
                my $func    = $arg[0];
                my $operD   = $item{OPER_DEST};
                my $oper1   = $item{OPER1};
                my $oper2   = $item{OPER2};
                my $op      = $item{OP};
                my $opType  = $item{OP_TYPE};
                $main::cltCode{$func}{insts}{$operD}{operD} = $operD;
                $main::cltCode{$func}{insts}{$operD}{oper1} = $oper1;
                $main::cltCode{$func}{insts}{$operD}{oper2} = $oper2;
                $main::cltCode{$func}{insts}{$operD}{op}    = $op;
                $main::cltCode{$func}{insts}{$operD}{opType}= $opType;
                $main::cltCode{$func}{insts}{$operD}{cat}   = 'compute';

                #print "Found ComputeInstruction\n";
              }
#a store instruction translates to a "translation" of variables, so put it in the TLUT as well
STORE_I   : "store" DATA_TYPE OPER1 "," POINTER_TYPE OPER_DEST /,?/ ALIGN(?)
              {
                my $func= $arg[0];
                my $src = $item{OPER1};
                my $dst = $item{OPER_DEST};
                $main::cltCode{$func}{insts}{$dst}{operD} = $dst;
                $main::cltCode{$func}{insts}{$dst}{operS} = $src;
                $main::cltCode{$func}{insts}{$dst}{cat}   = 'store';
                $main::cltCode{$func}{insts}{$dst}{opType}= $item{DATA_TYPE};                
                $main::tlut{$func}{$dst}=$src; #if you see dst, replace with src
              }

#a load instruction translates to a "translation" of variables, so put it in the TLUT as well
LOAD_I       : OPER_DEST "=" "load" DATA_TYPE "," POINTER_TYPE OPER1 /,?/ ALIGN(?)
              {
                my $func= $arg[0];
                my $src = $item{OPER1};
                my $dst = $item{OPER_DEST};
                $main::cltCode{$func}{insts}{$dst}{operD} = $dst;
                $main::cltCode{$func}{insts}{$dst}{operS} = $src;
                $main::cltCode{$func}{insts}{$dst}{cat}   = 'load';
                $main::cltCode{$func}{insts}{$dst}{opType}= $item{DATA_TYPE};                                
                $main::tlut{$func}{$dst}=$src; #if you see dst, replace with src
              }

#write-pipe translates to a LOAD instruction in the TIR, so just add it to the code hash
WRITE_PIPE_I  : "call" "void" "@" "write_pipe" "(" DATA_TYPE LOCAL_VAR1 "," POINTER_TYPE LOCAL_VAR2 ")"
              {
                my $func= $arg[0];
                my $src = $item{LOCAL_VAR2};
                my $dst = $item{LOCAL_VAR1};
                $main::cltCode{$func}{insts}{$dst}{operD} = $dst;
                $main::cltCode{$func}{insts}{$dst}{operS} = $src;
                $main::cltCode{$func}{insts}{$dst}{cat}   = 'write_pipe';
                $main::cltCode{$func}{insts}{$dst}{opType}= $item{DATA_TYPE};

                #get to the final dest of this channel write call, to ensure
                #we get the channel, not some intermediate
                my $finalDest = main::lookupTlut($func, $dst);
                #if writing to a global pipe/channel, it needs to go on the argument list
                #of this function
                if (exists $main::globalChannels{$finalDest}) {
                  $main::cltCode{$func}{args}{$finalDest}{name} = $finalDest;
                  $main::cltCode{$func}{args}{$finalDest}{cat}  = 'globalPipe';
                  $main::cltCode{$func}{args}{$finalDest}{type} = $item{DATA_TYPE};
                }
              }              
#read-pipe translates to a "translation" of variables, so put it in the TLUT as well
READ_PIPE_I   : "call" "void" "@" "read_pipe" "(" DATA_TYPE LOCAL_VAR1 "," POINTER_TYPE LOCAL_VAR2 ")"
              {
                my $func= $arg[0];
                my $src = $item{LOCAL_VAR1};
                my $dst = $item{LOCAL_VAR2};
                $main::cltCode{$func}{insts}{$dst}{operD} = $dst;
                $main::cltCode{$func}{insts}{$dst}{operS} = $src;
                $main::cltCode{$func}{insts}{$dst}{cat}   = 'read_pipe';
                $main::cltCode{$func}{insts}{$dst}{opType}= $item{DATA_TYPE};
                $main::tlut{$func}{$dst}=$src; #if you see dst, replace with src

                #get to the initial source of this channel read call, to ensure
                #we get the channel, not some intermediate
                my $initSource = main::lookupTlut($func, $src);
                #if writing to a global pipe/channel, it needs to go on the argument list
                #of this function
                if (exists $main::globalChannels{$initSource}) {
                  $main::cltCode{$func}{args}{$initSource}{name} = $initSource;
                  $main::cltCode{$func}{args}{$initSource}{cat}  = 'globalPipe';
                  $main::cltCode{$func}{args}{$initSource}{type} = $item{DATA_TYPE};
                }              }              

ALLOCA_I  : LOCAL_VAR "=" "alloca" DATA_TYPE /,?/ ALIGN(?)
              {
                print("OLT:: Found alloca instruction for $item{LOCAL_VAR} in $arg[0]. Ignoring.\n");
              }


#Function structure
#-------------------
FUNC_I  : ENTRY[$arg[0]]
            | RETURN_I[$arg[0]]
            | RETURN_IV[$arg[0]]
            | COMPUTE_I[$arg[0]]
            | STORE_I[$arg[0]]
            | LOAD_I[$arg[0]]
            | ALLOCA_I[$arg[0]]
            | WRITE_PIPE_I[$arg[0]]
            | READ_PIPE_I[$arg[0]]
FUNC_BODY   : FUNC_I[$arg[0]](s) #)() 
FUNCT_ARG   : ARG_TYPE ARG_NAME /,?/
            {
              my $func  = $arg[0];
              my $aName = $item{ARG_NAME};
              my $aType = $item{ARG_TYPE};
              $main::cltCode{$func}{args}{$aName}{name} = $aName;
              $main::cltCode{$func}{args}{$aName}{type} = $aType;

              #argument connects to global memory if it is a pointer type
              #add to the global hash for global mems
              if ($aType =~ m/[^\*]+\*/) {
                $main::cltCode{$func}{args}{$aName}{cat}  = 'gmem';
              } 
              else {
                $main::cltCode{$func}{args}{$aName}{cat}  = 'undefined';
              }  

              ##default input
              #$main::cltCode{$func}{args}{$aName}{dir}  = 'in';
              ##if pointer type, this is an output
              #$main::cltCode{$func}{args}{$aName}{dir}  = 'out'
              #  if ($aType =~ m/[^\*]+\*/);
            }

#functions can have zero or more args            
FUNCT_ARGS  : FUNCT_ARG[$arg[0]](s?) #?? 
FUNCT_DECLR : "define" ("void"|DATA_TYPE) "@" FUNC_NAME "(" FUNCT_ARGS[$item{FUNC_NAME}] ")"
            { 
              #print "Found FUNCT_DECLR $item{FUNC_NAME}\n";
              $main::cltCode{$item{FUNC_NAME}}{name} = $item{FUNC_NAME};
              $return = $item{FUNC_NAME};
            }
FUNC_ATTR   : "#" INTEGER
FUNCTION    : FUNCT_DECLR  FUNC_ATTR(?) "{" FUNC_BODY[$item{FUNCT_DECLR}] "}" 
            { 
              my $func = $item{FUNCT_DECLR};
              
              
              #if you find write_pipe or read_pipe or get_pipe_num_packets
              #function definitions assume they are stubs and do nothing
              #also update "cat" entry in hash
              if(($func eq 'write_pipe') || ($func eq 'read_pipe') || ($func eq 'get_pipe_num_packets')) {
                $main::cltCode{$func}{cat} = 'stub';
                $main::outTirBuff .= ";-- Found $func definition\n";
              }

              else {
                #set default function category;
                $main::cltCode{$func}{cat} = 'regular';

                my $funcType = 'pipe';
                  #TODO: This is default, but do I need to look at other options?
                
                #write function declaration
                $main::outTirBuff .= ";-- ------------------\n";
                $main::outTirBuff .= ";--  $func \n";
                $main::outTirBuff .= ";-- ------------------\n";
                $main::outTirBuff .= "define void @".$func."(\n";
                
                #write each argument
                foreach my $key ( keys %{$main::cltCode{$func}{args}} ) {
                  my $aName = $main::cltCode{$func}{args}{$key}{name};
                  my $aType = $main::cltCode{$func}{args}{$key}{type};
                  $aType =~ s/\*//;
                    #remove pointer * if there, not relevant in TIR
                  $main::outTirBuff .= "\t$aType\t%$aName\t,\n";

                  #decide arg direction, needed later for main code generation
                  #if arg ALSO exists as an instruction dest 
                  #(identified by keys in {inst}) then it is an output, else input
                  if (exists $main::cltCode{$func}{insts}{$aName}) {
                    $main::cltCode{$func}{args}{$key}{dir} = 'output';
                  } 
                  else {
                    $main::cltCode{$func}{args}{$key}{dir} = 'input';
                  }

                }#foreach
                
                #close declaration, open body
                $main::outTirBuff .= ") $funcType {\n";
                

                #----------------------------
                # WRITE TIR CODE FOR THIS FUNC
                #----------------------------                
                foreach my $key ( keys %{$main::cltCode{$func}{insts}} ) {
                  my $cat       = $main::cltCode{$func}{insts}{$key}{cat};
                  
                  #write compute instructions            
                  #----------------------------
                  
                  #compute instruction translate almost as-is to TIR
                  if ($cat eq 'compute') {
                    #source operands need to be looked up in the TLUT
                    my $oper1   = main::lookupTlut($func, $main::cltCode{$func}{insts}{$key}{oper1});
                    my $oper2   = main::lookupTlut($func, $main::cltCode{$func}{insts}{$key}{oper2});

                    my $operD   = $main::cltCode{$func}{insts}{$key}{operD};
                    my $op      = $main::cltCode{$func}{insts}{$key}{op};
                    my $opType  = $main::cltCode{$func}{insts}{$key}{opType};
                    $main::outTirBuff .= "\t $opType %$operD = $op $opType %$oper1, %$oper2\n";
                  }
                  
                  #write pipe instruction translate to LOAD, but source operand
                  #may need looking up in the TLUT (translation LUT)
                  #----------------------------
                  elsif ($cat eq 'write_pipe') {
                    
                    #lookup source and dest operands in TLUT to see if they need to be replaced
                    #by another variable
                    my $operD   = main::lookupTlut($func, $main::cltCode{$func}{insts}{$key}{operD});
                    my $operS   = main::lookupTlut($func, $main::cltCode{$func}{insts}{$key}{operS});

                    my $op      = 'load';
                    my $opType  = $main::cltCode{$func}{insts}{$key}{opType};
                    $main::outTirBuff .= "\t $opType %$operD = $op $opType %$operS\n";                    
                  }

                  #store instruction:
                  #see ./README.txt, TRANSLATION NOTES
                  #----------------------------
                  elsif ($cat eq 'store') {
                    
                    #lookup source and dest operands in TLUT to see if they need to be replaced
                    #by another variable
                    #my $operD   = main::lookupTlut($func, $main::cltCode{$func}{insts}{$key}{operD});
                    #my $operS   = $main::cltCode{$func}{insts}{$key}{operS};
                    
                    #we don't lookup dest as dest is supposed to be arg *directly*
                    my $operD   = $main::cltCode{$func}{insts}{$key}{operD};
                    my $operS   = main::lookupTlut($func, $main::cltCode{$func}{insts}{$key}{operS});

                    #is operD an argument, then generate code
                    if(exists $main::cltCode{$func}{args}{$operD}) {
                      my $op      = 'load';
                      my $opType  = $main::cltCode{$func}{insts}{$key}{opType};
                      $main::outTirBuff .= "\t $opType %$operD = $op $opType %$operS\n";                    
                    }
                  }#elsif
                }#foreach my $key ( keys %{$main::cltCode{$func}{insts}} ) {
                
                #close function definition
                $main::outTirBuff .= "\tret void\n}\n";
              }#else (if NOT write_pipe or read_pipe)
            }#FUNCTION
FUNCTIONS   : FUNCTION(s) #)()


#===========================================================================
# Global Channels/Pipes
#===========================================================================


GL_CHANNEL: GLOBAL_VAR "=" "common" "global" DATA_TYPE "0" /,?/ ALIGN(?)
          {
            $main::globalChannels{$item{GLOBAL_VAR}}{dtype} = $item{DATA_TYPE};
           print ("OLT: Found global channel $item{GLOBAL_VAR}\n");
          }
GL_CHANNELS : GL_CHANNEL(s)          

#===========================================================================
# LLVM (non-function) elements
#===========================================================================

#For now, parsing these entities to ignore them. 
META_DATA   : /\![^\n]+\n/
            #{print "Found META_DATA statement\n";}
ATTRIBUTE   : "attributes" /[^\n]+\n/
            #{print "Found ATTRIBUTES statement\n";}
TARGET      : "target" /[^\n]+\n/
            #{print "Found TARGET statement\n";}
#check if annotation is there to give us linear size            
ANNOTATION  : ANNOT_NAME "=" ALL2NEWLINE 
            {
              my $annot = $item{ALL2NEWLINE};
              if ($annot =~ m/(tytra_linear_size\()(\d+)(\))/){$main::linSize = $2;}                                  
            }



# ============================================================================
# Start rule 
# ============================================================================
SECTION : GL_CHANNELS
        | FUNCTIONS
        | ATTRIBUTE
        | META_DATA
        | TARGET
        | ANNOTATION
        | <error>

STARTRULE: SECTION(s) #)()