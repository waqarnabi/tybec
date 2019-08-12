{ use Regexp::Common qw(URI);}

# ============================================================================
#  Common Patterns
# ============================================================================
 
 INTEGER   : /$RE{num}{int}/      
 
 DATA_TYPE : /ui\d+/      # unsigned integer: ui followed by 1 or more numbers (TIR specific, not LLVM)
           | /i\d+/       # signed integers (or in LLVM-speak, integers)
           | /float\d+/   # sized floating point (if 32/64, then standard IEEE, otherwise custom) 
 
 POINTER_TYPE: DATA_TYPE "*"
 
 
 #SIZE      : INTEGER
 SIZE      : IMM_INT_OPER
           | "auto"
           
 ARRAY_TYPE: "[" SIZE "x" DATA_TYPE "]"
  {$return= $item{DATA_TYPE}.".".$item{SIZE};}
 
 NAME      : /[^,=()":\s<>]+/  # one or more characters
 LOCAL_VAR : "%" NAME
  {$return = "%".$item{NAME};}
 LOCAL_VAR1 : "%" NAME
  {$return = "%".$item{NAME};}
 LOCAL_VAR2 : "%" NAME
  {$return = "%".$item{NAME};}
 
 GLOBAL_VAR: "@" NAME
 {$return = "@".$item{NAME};}
 
 VARIABLE : LOCAL_VAR
          | GLOBAL_VAR
 
# LOCAL_VAR : /%[^,=()"\s]+/     # % followed by 1 r more chars, other than: , = whitespace
#
# GLOBAL_VAR: /@[^,=()"\s]+/     # @ followed by 1 or more chars, other than: , = whitespace
 RANGE     : /[:\d]+/
 PATTERN   : /\[\d*:\d*:\d*\]/    # [START :END : STRIDE] 
                                # START: optional, can get from start metadata
                                # END:   optional, can get from start + size metadata
                                # STRIDE:optional;  default = 1 word
 # EXPRESSION: /[\d\+\*\-\/()\ ]+/ # Expressions should be calculalable by EVAL
 EXPRESSION: /[\d\+\*\-\/()\ ]+/ # Expressions should be calculalable by EVAL
                                 # this regex only allows integer numbers, no variables
                                 # not sure if this is 100% correct regex FIXME
                                 
 EXPRESSION1: EXPRESSION
 EXPRESSION2: EXPRESSION
 
 POSITIVE_CONSTANT: /\d+/
 NEGATIVE_CONSTANT: /-\d+/
 CONSTANT         : /-?\d+/
 FXP_CONSTANT     : /-?\d+\.?\d*/ #collides with CONSTANT, so should always be checked before it if we are testing for both together

 NAME1     : NAME
 NAME2     : NAME

 
 INTEGER1  : INTEGER
 INTEGER2  : INTEGER

 MACRO_NAME: NAME
 
 ARITH_OPS : "add" 
           | "mul"
           | "sub"
           | "udiv"
           | "sdiv"
           | "pow"
           
 LOGICAL_OPS : "or"
             | "and"

 OP_ONEOP : "sin"  
          | "cos"  
          
 OP  : ARITH_OPS
     | LOGICAL_OPS

 OP_COMPARE  : "icmp" 
 
 OP_SELECT   : "select"

 TYPE_COMPARE: "eq"
             | "ne"
            

 FUNC_TYPE  : "seq"
            | "pipe"
            | "par"
            | "comb"

 DIRECTION : "in"
           | "out"
           
 TYPES_OF_STREAMS : "stream1d"
                  | "stream2d"
                  | "stream3d"
                  | "streamNd" 
                  | "streamfifo"
                  | "streamconstant "
                  | "streamscalar"
                  

 FUNC_NAME         : NAME
 CALLEE_FUNC_NAME  : FUNC_NAME

 ARG_NAME  : VARIABLE
 
 IMM_INT_OPER: EXPRESSION # Immediate operand can be an expression as well, and we will always EVAL an IMM_INT_OPER
   {$return = eval($item{EXPRESSION});}

 # typical source operand (not destination)
 OPER      : FXP_CONSTANT
           | IMM_INT_OPER
           | CONSTANT
           | LOCAL_VAR
           | GLOBAL_VAR
          
 # aliases for OPER; TRUE/FALSE/PREDICATE needed for select instruction
 OPER1     : OPER
 OPER2     : OPER
 OPER3     : OPER
 TRUE_OPER : OPER
 FALSE_OPER: OPER
 PRED_OPER : OPER

 # destination operand cant be immediate
 OPER_DEST : LOCAL_VAR
           | GLOBAL_VAR
 OPER_DEST1: OPER_DEST
 OPER_DEST2: OPER_DEST

           
           
 DEST_TYPE : DATA_TYPE

 OP_TYPE   : DATA_TYPE  
 OP_TYPE1  : OP_TYPE  
 OP_TYPE2  : OP_TYPE  
 OP_TYPE3  : OP_TYPE  

 ARG_TYPE  : DATA_TYPE

 MEM_NAME  : NAME  

 #For smart-buffering, I allow AUTO keyword to specify the memroy size as well
 MEM_SIZE  : INTEGER
           | "auto"
 
 ADDR_SPACE_IDENT: INTEGER
 
 COMMENT    : /$RE{comment}{Scheme}/

 PLUS_OR_MINUS : "+" 
               | "-" 
 
# ==========================================================================
# Functional-call instruction
# ==========================================================================
#Earlier I required specificatio of the type of function as well when calling it, but
#that is redundant as the function definition specifies that, and I should propagate that info 
FUNC_CALL_INSTR : "call" "@" CALLEE_FUNC_NAME "("  CALLED_FUNCT_ARGS[$arg[0], $item{CALLEE_FUNC_NAME} ] ")" 
       { TirGrammarMod::actFUNC_CALL_INSTR(\@item, \%item, \@arg); }

# ==========================================================================
# Compute Instructions 
# ==========================================================================
# I have made the argument type optional. Is that ok?
# CALLED_FUNCT_ARG  : ARG_TYPE(?) ARG_NAME /,?/
# NOOOO: I need it to detering the data-type of edge connections between nodes
CALLED_FUNCT_ARG  : ARG_TYPE ARG_NAME /,?/
       { TirGrammarMod::actCALLED_FUNCT_ARG(\@item, \%item, \@arg); }

CALLED_FUNCT_ARGS  : CALLED_FUNCT_ARG[$arg[0], $arg[1]](s) #)()
 
RETURN_INSTR : "ret" "void"
            

#SELECT_INSTR : DEST_TYPE OPER_DEST "=" OP_SELECT OP_TYPE1 PRED_OPER "," OP_TYPE2 TRUE_OPER "," OP_TYPE3 FALSE_OPER
SELECT_INSTR : DEST_TYPE OPER_DEST "=" OP_SELECT OP_TYPE1 OPER1 "," OP_TYPE2 OPER2 "," OP_TYPE3 OPER3
#       { TirGrammarMod::actSELECT_INSTR(\@item, \%item, \@arg); }
       { TirGrammarMod::actPRIMITIVE_INSTRUCTION('select', \@item, \%item, \@arg); }

COMPARE_INSTR : DEST_TYPE OPER_DEST "=" OP_COMPARE TYPE_COMPARE OP_TYPE OPER1 "," OPER2
       #{ TirGrammarMod::actCOMPARE_INSTR(\@item, \%item, \@arg); }
       { TirGrammarMod::actPRIMITIVE_INSTRUCTION('compare', \@item, \%item, \@arg); }
       
#meta-data in compute instructions only relevant for reductions
#, !tir.reduction.size  !NLinear  
MD_REDUCTION_SIZE: "!" "tir.reduction.size" /,?/ "!" EXPRESSION #/ 
  {TirGrammarMod::actMD_REDUCTION_SIZE(\@item, \%item, \@arg);
  print "Found MD_REDUCTION_SIZE\n";}

COMPUTE_INSTR :  DEST_TYPE OPER_DEST  "=" OP OP_TYPE OPER1 "," OPER2 /,?/ MD_REDUCTION_SIZE[$item{OPER_DEST}, $arg[0]](s?)  #??
       {TirGrammarMod::actPRIMITIVE_INSTRUCTION('compute', \@item, \%item, \@arg); }

COMPUTE_INSTR_ONEOP :  DEST_TYPE OPER_DEST  "="  OP_ONEOP OP_TYPE OPER1 /,?/ MD_REDUCTION_SIZE[$item{OPER_DEST}, $arg[0]](s?)  #??
       {TirGrammarMod::actPRIMITIVE_INSTRUCTION('compute1op', \@item, \%item, \@arg); }
       
       
#almost same as compute instruction  
#REDUX_INSTR :  DEST_TYPE GLOBAL_VAR  "=" OP OP_TYPE OPER1 "," OPER2
#       { TirGrammarMod::actREDUX_INSTR(\@item, \%item, \@arg); }
  # TODO: This should be merged with the COMPUTE instruction as the 
  # post processing is very similar for both?
  
#this statement is currently  used only to make scalar copies        
LOAD_INSTR  : DEST_TYPE OPER_DEST "=" "load" OP_TYPE OPER1  
       { TirGrammarMod::actPRIMITIVE_INSTRUCTION('load',\@item, \%item, \@arg); }
  # TODO update it to become part of dependancy analysis
  
#LOAD_INSTR: DATA_TYPE LOCAL_VAR1 "=" "load" DATA_TYPE LOCAL_VAR2 
#  {TirGrammarMod::actPRIMITIVE_INSTRUCTION('load', \@item, \%item, \@arg); }

# ==========================================================================
# Memory/Stream Instructions 
# ==========================================================================

ADDRSPACE_IDENTIFICATION: "addrspace" "(" ADDR_SPACE_IDENT ")" 
            {$return =$item{ADDR_SPACE_IDENT};}

MD_STREAM_START_ADDR : "!" "tir.stream.saddr" /,?/ "!" IMM_INT_OPER /,?/ #/
        {TirGrammarMod::actMD_STREAM_START_ADDR(\@item, \%item, \@arg); }

MD_STREAM_TYPE : "!" "tir.stream.type" /,?/ "!" TYPES_OF_STREAMS /,?/ #/
        {TirGrammarMod::actMD_STREAM_TYPE(\@item, \%item, \@arg); }

MD_STREAM_SIZE : "!" "tir.stream.size" /,?/ "!" IMM_INT_OPER /,?/ #/
        {TirGrammarMod::actMD_STREAM_SIZE(\@item, \%item, \@arg); }

MD_STREAM_STRIDE : "!" "tir.stream.stride" /,?/ "!" IMM_INT_OPER /,?/ #/
        {TirGrammarMod::actMD_STREAM_STRIDE(\@item, \%item, \@arg); }

STREAMRW_METADATA : MD_STREAM_STRIDE[$arg[0], $arg[1]]
                  | MD_STREAM_SIZE[$arg[0], $arg[1]]
                  | MD_STREAM_TYPE[$arg[0], $arg[1]]
                  | MD_STREAM_START_ADDR[$arg[0], $arg[1]]
#                  | MD_STREAM_PATTERN[$arg[0]]
#                  | <error: "Check Stream Metadata">

STREAMWRITE: "streamwrite" DATA_TYPE LOCAL_VAR "," POINTER_TYPE VARIABLE "," STREAMRW_METADATA[$item{LOCAL_VAR},$arg[0]](s) #)()
  {TirGrammarMod::actSTREAMWRITE(\@item, \%item, \@arg); }

STREAMREAD: LOCAL_VAR "=" "streamread" DATA_TYPE "," POINTER_TYPE VARIABLE "," STREAMRW_METADATA[$item{LOCAL_VAR}, $arg[0]](s) #)()
  {
    TirGrammarMod::actSTREAMREAD(\@item, \%item, \@arg); 
  }

STORE_INSTR: "store" DATA_TYPE (EXPRESSION|VARIABLE) "," POINTER_TYPE LOCAL_VAR
  {print "Found STORE (constant) instruction\n";}
        
# 0        1      2     3                4             5          6
ALLOCA: VARIABLE "=" "alloca" (ARRAY_TYPE|DATA_TYPE) /,?/   ADDRSPACE_IDENTIFICATION(?)        #/
  {TirGrammarMod::actALLOCA(\@item, \%item, \@arg); }
    
  
# ==========================================================================
# LABEL
# ==========================================================================
LABEL       : NAME "\:"

#===========================================================================
# OFFSET (WINDOWS) OF STREAMING PORTS
#===========================================================================
 
OFFSET_STREAM: DATA_TYPE LOCAL_VAR "=" "offstream" LOCAL_VAR2 "," "!" "tir.stream.offset" /,?/ "!" PLUS_OR_MINUS  EXPRESSION #/
       {  TirGrammarMod::actOFFSET_STREAM(\@item, \%item, \@arg);
          print "Found OFFSET  instruction\n";}


#===========================================================================
# AUTOINDEX
#===========================================================================
AUTOINDEX_START : EXPRESSION
AUTOINDEX_END   : EXPRESSION
AUTOINDEX_TYPE  : "1d"
                | "2d"

MD_AI_TYPE : "!" "tir.aindex.type"  /,?/ "!" AUTOINDEX_TYPE /,?/ #/
          {  TirGrammarMod::actMD_AI_TYPE(\@item, \%item, \@arg);
          print "Found AI TYPE  metadata\n";}
                

MD_AI_RANGE : "!" "tir.aindex.range" /,?/ "!" EXPRESSION1 /,?/ "!" EXPRESSION2 /,?/#/
       {  TirGrammarMod::actMD_AI_RANGE(\@item, \%item, \@arg);
            print "Found AI RANGE  metadata\n";}

MD_AI_DIMNUM : "!" "tir.aindex.dimNum" /,?/ "!" EXPRESSION1 /,?/ #/
       {  TirGrammarMod::actMD_AI_DIMNUM(\@item, \%item, \@arg);
            print "Found MD_AI_DIMNUM \n";}

MD_AI_NESTUNDER : "!" "tir.aindex.nestUnder" /,?/ "!" LOCAL_VAR /,?/ #/
       {  TirGrammarMod::actMD_AI_NESTUNDER(\@item, \%item, \@arg);
            print "Found MD_AI_NESTUNDER \n";}

MD_AI_NESTOVER : "!" "tir.aindex.nestOver" /,?/ "!" LOCAL_VAR /,?/ #/
       {  TirGrammarMod::actMD_AI_NESTOVER(\@item, \%item, \@arg);
            print "Found MD_AI_NESTUNDER \n";}
            
AUTOINDEX_METADATA: MD_AI_TYPE[$arg[0], $arg[1]]
                  | MD_AI_RANGE[$arg[0], $arg[1]]
                  | MD_AI_DIMNUM[$arg[0], $arg[1]]
                  | MD_AI_NESTUNDER[$arg[0], $arg[1]]
                  | MD_AI_NESTOVER[$arg[0], $arg[1]]
                                    
AUTOINDEX: DATA_TYPE LOCAL_VAR "=" "autoindex" LOCAL_VAR2 "," AUTOINDEX_METADATA[$item{LOCAL_VAR},$arg[0]](s) #)()
       {  TirGrammarMod::actAUTOINDEX(\@item, \%item, \@arg);
          print "Found AUTOINDEX instruction\n";}

#"streamread" DATA_TYPE "," POINTER_TYPE VARIABLE "," STREAMRW_METADATA[$item{LOCAL_VAR}](s) #)()

#COUNTER: DATA_TYPE LOCAL_VAR "=" DATA_TYPE C_INIT_VAL "," "!" "\"" "t" "\"" ","  "!"  C_START ":" C_END COUNTER_CHAINED_TO[$arg[0], $item{LOCAL_VAR}](?)

#       { TirGrammarMod::actCOUNTER(\@item, \%item, \@arg); }

# ==========================================================================
# SPLITS and MERGES
# ==========================================================================

#we need a way to store split destinations separately, so they need a separate callback
#which stores the split destinations in a temporary array, to be assigned
#back to the SPLIT node it its callback
SPLIT_OUT: OPER 
       { TirGrammarMod::actSPLIT_OUT(\@item, \%item, \@arg);}

#SPLIT: DATA_TYPE "<" OPER_DEST1 "," OPER_DEST2 ">" "=" "split" DATA_TYPE OPER1 "to" "<" INTEGER "x" DATA_TYPE ">"
SPLIT: DATA_TYPE "<" (SPLIT_OUT /,?/)(s) ">" "=" "split" DATA_TYPE OPER1 "to" "<" INTEGER "x" DATA_TYPE ">"   #))
      { TirGrammarMod::actSPLIT(\@item, \%item, \@arg); }

MERGE_IN: OPER 
       { TirGrammarMod::actMERGE_IN(\@item, \%item, \@arg);}
      
MERGE: OPER_DEST "=" "merge" "<" INTEGER "x" DATA_TYPE ">" "<" (MERGE_IN /,?/)(s) ">" "to" DATA_TYPE  #))
      { TirGrammarMod::actMERGE(\@item, \%item, \@arg); }
       
       
#===========================================================================
# Function Definitions (other than main)
#===========================================================================
FUNC_INSTRUCTION  : COMPUTE_INSTR[$arg[0]]
                  | COMPUTE_INSTR_ONEOP[$arg[0]]
#                  | REDUX_INSTR[$arg[0]]
                  | OFFSET_STREAM[$arg[0]]
                  | FUNC_CALL_INSTR[$arg[0]]
#                  | ASSIGN_INSTR[$arg[0]]
                  | COMPARE_INSTR[$arg[0]]
                  | SELECT_INSTR[$arg[0]]
                  | RETURN_INSTR
                  | LABEL
                  | ALLOCA[$arg[0]]
                  | STORE_INSTR[$arg[0]]
                  | LOAD_INSTR[$arg[0]]
                  | STREAMREAD[$arg[0]]
                  | STREAMWRITE[$arg[0]]
                  | AUTOINDEX[$arg[0]]
                  | SPLIT[$arg[0]]
                  | MERGE[$arg[0]]

FUNC_BODY:  FUNC_INSTRUCTION[$arg[0]](s) #)() 

FUNCT_ARG   : ARG_TYPE ARG_NAME /,?/
          { TirGrammarMod::actFUNCT_ARG(\@item, \%item, \@arg); }

FUNCT_ARGS  : FUNCT_ARG[$arg[0]](s) #)()

FUNCT_DECLR : "define" "void" "@" FUNC_NAME "(" FUNCT_ARGS[$item{FUNC_NAME}] ")" FUNC_TYPE
        { print "Found FUNCT_DECLR $item{FUNC_NAME}\n";
          TirGrammarMod::actFUNCT_DECLR(\@item, \%item, \@arg); 
          $return = $item{FUNC_NAME};}

FUNCTION  : FUNCT_DECLR "{" FUNC_BODY[ $item{FUNCT_DECLR} ] "}" 
          { TirGrammarMod::actFUNCTION(\@item, \%item, \@arg); 
            print "Found FUNCTION\n";}

FUNCTIONS : FUNCTION(s) #)()

#===========================================================================
# Main function
#===========================================================================
# The main function can have any of the following:
# ADDRSPACE_ALLOCA  : First and primary type of memory allocation, using the addrspace ident'
# STACK_ALLOCA      : Secondary allocation, only scalar registers in "stack" private memory
# FUNC_CALL_INSTR   :
# OFFSET_STREAM     :
# RETURN_INSTR      :
# LABEL             :
# STREAMREAD        :
# STREAMWRITE       :

MAIN_INSTRUCTION  : COMPUTE_INSTR[$arg[0]]
#                  | REDUX_INSTR[$arg[0]]
                  | OFFSET_STREAM[$arg[0]]
                  | FUNC_CALL_INSTR[$arg[0]]
                  #| ASSIGN_INSTR[$arg[0]]
                  | LOAD_INSTR[$arg[0]]
                  | COMPARE_INSTR[$arg[0]]
                  | SELECT_INSTR[$arg[0]]
                  | RETURN_INSTR
                  | LABEL
                  | ALLOCA[$arg[0]]
                  | STORE_INSTR[$arg[0]]
                  | STREAMREAD[$arg[0]]
                  | STREAMWRITE[$arg[0]]
                  | AUTOINDEX[$arg[0]]
                  | SPLIT[$arg[0]]
                  | MERGE[$arg[0]]

MAIN_BODY : MAIN_INSTRUCTION["main"](s) #)()

MAIN      : "define" "void" "@" "main" "(" ")" "{" (MAIN_BODY) "}"
          { TirGrammarMod::actMAIN(\@item, \%item, \@arg); }
#MAIN      : "define" "void" "@" "main" "(" ")" "{" (MAIN_BODY) "}"
#          { print "Found main!\n"; }

# ============================================================================
# define macros
# ============================================================================
# Not needed if using GCC pre-processor
DEFINE_STATEMENT : "#" "define" NAME /\S+/
        { TirGrammarMod::actDEFINE_STATEMENT(\@item, \%item, \@arg); }

MACROS           : DEFINE_STATEMENT(s?) #??

# ============================================================================
# Start rule 
# ============================================================================
SECTION : FUNCTIONS
        | MAIN      
        | <error>

STARTRULE: SECTION(s) #)()
