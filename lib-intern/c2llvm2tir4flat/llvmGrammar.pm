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
 OPER_DEST    : LOCAL_VAR
              | GLOBAL_VAR
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
RETURN_INSTR  : "ret" "void"
COMPUTE_INSTR : OPER_DEST "=" OP WRAP OP_TYPE OPER1 "," OPER2
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
                #print "Found ComputeInstruction\n";
              }
STORE_INSTR   : "store" OP_TYPE OPER1 "," POINTER_TYPE OPER_DEST /,?/ ALIGN(?)             
              {
                #In store, the source operand is a local variable already defined
                #so the hash would have entry for it
                #the destination pointer is the new destination operator now,
                #so I simple go to the hash and replace it with new destination
                #TODO: Will this always work?
                my $func    = $arg[0];
                my $src = $item{OPER1};
                my $dst = $item{OPER_DEST};
                $main::cltCode{$func}{insts}{$src}{operD} = $dst;
                #print "Found StoreInstruction\n";
              }


#Function structure
#-------------------
FUNC_INSTR  : ENTRY[$arg[0]]
            | RETURN_INSTR[$arg[0]]
            | COMPUTE_INSTR[$arg[0]]
            | STORE_INSTR[$arg[0]]
FUNC_BODY   : FUNC_INSTR[$arg[0]](s) #)() 
FUNCT_ARG   : ARG_TYPE ARG_NAME /,?/
            {
              my $func  = $arg[0];
              my $aName = $item{ARG_NAME};
              my $aType = $item{ARG_TYPE};
              $main::cltCode{$func}{args}{$aName}{name} = $aName;
              $main::cltCode{$func}{args}{$aName}{type} = $aType;
              #default input
              $main::cltCode{$func}{args}{$aName}{dir}  = 'in';
              #if pointer type, this is an output
              $main::cltCode{$func}{args}{$aName}{dir}  = 'out'
                if ($aType =~ m/[^\*]+\*/);
            }
FUNCT_ARGS  : FUNCT_ARG[$arg[0]](s) 
FUNCT_DECLR : "define" "void" "@" FUNC_NAME "(" FUNCT_ARGS[$item{FUNC_NAME}] ")"
            { 
              #print "Found FUNCT_DECLR $item{FUNC_NAME}\n";
              $main::cltCode{$item{FUNC_NAME}}{name} = $item{FUNC_NAME};
              $return = $item{FUNC_NAME};
            }
FUNC_ATTR   : "#" INTEGER
FUNCTION    : FUNCT_DECLR  FUNC_ATTR(?) "{" FUNC_BODY[$item{FUNCT_DECLR}] "}" 
            { 
              my $func = $item{FUNCT_DECLR};
              my $funcType = 'pipe';
                #TODO: This is default, but do I need to look at other options?
              
              #write function declaration
              $main::outTirBuff .= ";-- ------------------\n";
              $main::outTirBuff .= ";--  $func\n";
              $main::outTirBuff .= ";-- ------------------\n";
              $main::outTirBuff .= "define void @".$func."(\n";
              
              #write each argument
              foreach my $key ( keys %{$main::cltCode{$func}{args}} ) {
                my $aName = $main::cltCode{$func}{args}{$key}{name};
                my $aType = $main::cltCode{$func}{args}{$key}{type};
                $aType =~ s/\*//;
                  #remove pointer * if there, not relevant in TIR
                $main::outTirBuff .= "\t$aType\t%$aName\t,\n";
              }
              
              #close declaration, open body
              $main::outTirBuff .= ") $funcType {\n";
              
              #write  instructions            
              foreach my $key ( keys %{$main::cltCode{$func}{insts}} ) {
                my $operD   = $main::cltCode{$func}{insts}{$key}{operD};
                my $oper1   = $main::cltCode{$func}{insts}{$key}{oper1};
                my $oper2   = $main::cltCode{$func}{insts}{$key}{oper2};
                my $op      = $main::cltCode{$func}{insts}{$key}{op};
                my $opType  = $main::cltCode{$func}{insts}{$key}{opType};
                $main::outTirBuff .= "\t $opType %$operD = $op $opType %$oper1, %$oper2\n";
              }
              
              #close function definition
              $main::outTirBuff .= "\tret void\n}\n";

              #write main
              #This is a hack to create a complete TIR code, but even for real
              #main won't be very different
              #The hack is that I generate a MAIN in the callback of having found
              #a (any) function. So I am assuming there is just one C function.
              #in reality there will be more, and I would look at the "top" function
              if (defined $main::linSize) {
                print("CLT:: Generating main with all default global arrays and linear sizes = $main::linSize\n");
                $main::outTirBuff .= "\n;-- ------------------\n";
                $main::outTirBuff .= ";--  MAIN\n";
                $main::outTirBuff .= ";-- ------------------\n";
                $main::outTirBuff .= "\n#define NLinear $main::linSize\n\n";
                $main::outTirBuff .= "define void \@main () {\n";
                
                #each argument of the function is:
                #1 a global memory array
                #2 a stream from the array
                #3 an arg to the top function
                my $gmemsBuff   ='';
                my $streamsBuff ='';
                my $args2Top    ='';
                foreach my $key ( keys %{$main::cltCode{$func}{args}} ) {
                  my $aName = $main::cltCode{$func}{args}{$key}{name};
                  my $aType = $main::cltCode{$func}{args}{$key}{type};
                  my $aDir  = $main::cltCode{$func}{args}{$key}{dir} ;
                  $aType =~ s/\*//;
                    #remove pointer * if there, not relevant in TIR

                  $gmemsBuff  .= "\t\%$aName = alloca [NLinear x $aType], addrspace(1) \n";
                  if($aDir eq 'in') {
                    $streamsBuff.= "\t\%$aName"."_stream = streamread $aType, $aType* \%$aName\n"
                                 . "\t, !tir.stream.type   !stream1d  \n"
                                 . "\t, !tir.stream.size   !NLinear   \n"
                                 . "\t, !tir.stream.saddr  !0         \n"
                                 . "\t, !tir.stream.stride !1         \n"
                                 ;
                  }
                  else {
                    $streamsBuff.= "\t streamwrite $aType \%$aName"."_stream, $aType* \%$aName\n"
                                 . "\t, !tir.stream.type   !stream1d  \n"
                                 . "\t, !tir.stream.size   !NLinear   \n"
                                 . "\t, !tir.stream.saddr  !0         \n"
                                 . "\t, !tir.stream.stride !1         \n"
                                 ;
                  }                                 
                  $args2Top  .= "\t $aType \%$aName"."_stream\t,\n"
                }

                $main::outTirBuff .= $gmemsBuff."\n";
                $main::outTirBuff .= $streamsBuff."\n";
                $main::outTirBuff .= "call \@$func (\n"
                                   . $args2Top
                                   . ")\n"
                                   ;
                
                #wrap up main
                $main::outTirBuff .= "\tret void\n}\n";
              }
              else{
                print("CLT:: Warning: Did not find linear size annotation, TIR will be generated without a main\n");
              }

              
            }
FUNCTIONS   : FUNCTION(s) #)()

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
SECTION : FUNCTIONS
        | ATTRIBUTE
        | META_DATA
        | TARGET
        | ANNOTATION
        | <error>

STARTRULE: SECTION(s) #)()