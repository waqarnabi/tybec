{ use Regexp::Common qw(URI);}

# ============================================================================
#  Common Patterns
# ============================================================================
 
 INTEGER   : /$RE{num}{int}/      
 DATA_TYPE : /ui\d+/         # unsigned integer: ui followed by 1 or more numbers (TIR specific, not LLVM)
           | /i\d+/          # signed integers (or in LLVM-speak, integers)
 NAME      : /[^,=()":\s]+/  # one or more characters
 LOCAL_VAR : "%" NAME
  {$return = "%".$item{NAME};}
 LOCAL_VAR1 : "%" NAME
  {$return = "%".$item{NAME};}
 LOCAL_VAR2 : "%" NAME
  {$return = "%".$item{NAME};}
 
 GLOBAL_VAR: "@" NAME
 {$return = "@".$item{NAME};}
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
                                 
 POSITIVE_CONSTANT: /\d+/
 NEGATIVE_CONSTANT: /-\d+/
 CONSTANT         : /-?\d+/

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

 LOGICAL_OPS : "or"
             | "and"

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

 FUNC_NAME         : NAME
 CALLEE_FUNC_NAME  : FUNC_NAME

 ARG_NAME  : LOCAL_VAR
           | GLOBAL_VAR
 
 IMM_INT_OPER: EXPRESSION # Immediate operand can be an expression as well, and we will always EVAL an IMM_INT_OPER
   {$return = eval($item{EXPRESSION});}

 # typical operand (not destination operand)
 OPER      : CONSTANT
           | IMM_INT_OPER
           | LOCAL_VAR
           | GLOBAL_VAR
          
 # aliases for OPER; TRUE/FALSE/PREDICATE needed for select instruction
 OPER1     : OPER
 OPER2     : OPER
 TRUE_OPER : OPER
 FALSE_OPER: OPER
 PRED_OPER : OPER

 # destination operand cant be immediate
 OPER_DEST : LOCAL_VAR
           | GLOBAL_VAR

 DEST_TYPE : DATA_TYPE

 OP_TYPE   : DATA_TYPE  
 OP_TYPE1  : OP_TYPE  
 OP_TYPE2  : OP_TYPE  
 OP_TYPE3  : OP_TYPE  

 ARG_TYPE  : DATA_TYPE

 MEM_NAME  : NAME  
 
 COMMENT    : /$RE{comment}{Scheme}/

# ****************************************************************************
# ****************************************************************************
#                                 COMPUTE-IR
# ****************************************************************************
# ****************************************************************************

# ==========================================================================
# Instructions 
# ==========================================================================
CALLED_FUNCT_ARG  : ARG_TYPE ARG_NAME /,?/
       { TirGrammarMod::actCALLED_FUNCT_ARG(\@item, \%item, \@arg); }

CALLED_FUNCT_ARGS  : CALLED_FUNCT_ARG[$arg[0], $arg[1]](s) #)()
 
FUNC_CALL_INSTR : "call" "@" CALLEE_FUNC_NAME "("  CALLED_FUNCT_ARGS[$arg[0], $item{CALLEE_FUNC_NAME} ] ")" FUNC_TYPE
       { TirGrammarMod::actFUNC_CALL_INSTR(\@item, \%item, \@arg); }
 
RETURN_INSTR : "ret" "void"

SELECT_INSTR : DEST_TYPE OPER_DEST "=" OP_SELECT OP_TYPE1 PRED_OPER "," OP_TYPE2 TRUE_OPER "," OP_TYPE3 FALSE_OPER
       { TirGrammarMod::actSELECT_INSTR(\@item, \%item, \@arg); }

COMPARE_INSTR : DEST_TYPE OPER_DEST "=" OP_COMPARE TYPE_COMPARE OP_TYPE OPER1 "," OPER2
       { TirGrammarMod::actCOMPARE_INSTR(\@item, \%item, \@arg); }
 
REDUX_INSTR :  DEST_TYPE GLOBAL_VAR  "=" OP OP_TYPE OPER1 "," OPER2
       { TirGrammarMod::actREDUX_INSTR(\@item, \%item, \@arg); }
  # TODO: This should be merged with the COMPUTE instruction as the 
  # post processing is very similar for both?

COMPUTE_INSTR :  DEST_TYPE LOCAL_VAR  "=" OP OP_TYPE OPER1 "," OPER2
       { TirGrammarMod::actCOMPUTE_INSTR(\@item, \%item, \@arg); }
  # parse one compute instruction e.g. ui18 %3 = add ui18 %2, %1

ASSIGN_INSTR  : DEST_TYPE OPER_DEST "=" OP_TYPE OPER1  
       { TirGrammarMod::actASSIGN_INSTR(\@item, \%item, \@arg); }
  # TODO update it to become part of dependancy analysis

# ==========================================================================
# LABEL
# ==========================================================================
LABEL       : NAME "\:"

#===========================================================================
# OFFSET (WINDOWS) OF STREAMING PORTS
#===========================================================================
 
PLUS_OR_MINUS : "+" 
              | "-" 
#the regex captures two formats of describing offsets
#one was used in main when offset were created over ports to main so @main.NAME (which is outdated now) 
#the other format is creating offsets inside PIPE modules locally, which is now being used i.e. %NAME
#OFFSET_STREAM: DATA_TYPE LOCAL_VAR "=" DATA_TYPE ("@" "main" "."|"%") NAME "," "!" "tir.stream.offset" "," "!" PLUS_OR_MINUS INTEGER
#OFFSET_STREAM: DATA_TYPE LOCAL_VAR "=" DATA_TYPE ("@" "main" "."|"%") NAME "," "!" "tir.stream.offset" "," "!" PLUS_OR_MINUS  EXPRESSION
#no need to keep the MAIN offstreams syntax

OFFSET_STREAM: DATA_TYPE LOCAL_VAR "=" DATA_TYPE LOCAL_VAR2 "," "!" "tir.stream.offset" "," "!" PLUS_OR_MINUS  EXPRESSION
       { TirGrammarMod::actOFFSET_STREAM(\@item, \%item, \@arg);}

#===========================================================================
# COUNTERS
#===========================================================================
C_INIT_VAL: EXPRESSION
C_START   : EXPRESSION
C_END     : EXPRESSION

COUNTER_CHAINED_TO: ","  "!"  "\"" LOCAL_VAR "\""
                  { TirGrammarMod::actCOUNTER_CHAINED_TO(\@item, \%item, \@arg); }

# counter may or may not be chained (henace the last sub-rule with (?)
COUNTER: LOCAL_VAR "=" DATA_TYPE C_INIT_VAL "," "!" "\"" "counter" "\"" ","  "!"  C_START ":" C_END COUNTER_CHAINED_TO[$arg[0], $item{LOCAL_VAR}](?)
       { TirGrammarMod::actCOUNTER(\@item, \%item, \@arg); }

#===========================================================================
# Function Definitions (other than main)
#===========================================================================
FUNC_INSTRUCTION  : COMPUTE_INSTR[$arg[0]]
                  | REDUX_INSTR[$arg[0]]
                  | OFFSET_STREAM[$arg[0]]
                  | FUNC_CALL_INSTR[$arg[0]]
                  | ASSIGN_INSTR[$arg[0]]
                  | COMPARE_INSTR[$arg[0]]
                  | SELECT_INSTR[$arg[0]]
                  | RETURN_INSTR
                  | LABEL

FUNC_BODY:  FUNC_INSTRUCTION[$arg[0]](s) #)() 

FUNCT_ARG   : ARG_TYPE ARG_NAME /,?/
          { TirGrammarMod::actFUNCT_ARG(\@item, \%item, \@arg); }

FUNCT_ARGS  : FUNCT_ARG[$arg[0]](s) #)()

FUNCT_DECLR : "define" "void" "@" FUNC_NAME "(" FUNCT_ARGS[$item{FUNC_NAME}] ")" FUNC_TYPE
          { TirGrammarMod::actFUNCT_DECLR(\@item, \%item, \@arg); 
            $return = $item{FUNC_NAME};}

FUNCTION  : FUNCT_DECLR "{" FUNC_BODY[ $item{FUNCT_DECLR} ] "}" 
          { TirGrammarMod::actFUNCTION(\@item, \%item, \@arg); }

FUNCTIONS : FUNCTION(s) #)()

#===========================================================================
# Main function
#===========================================================================
MAIN_INSTRUCTION  : FUNC_CALL_INSTR[$arg[0]]
                  | OFFSET_STREAM[$arg[0]]
                  | COUNTER[$arg[0]]
                  | RETURN_INSTR
                  | LABEL
#                  | CHAINED_COUNTER[$arg[0]]

MAIN_BODY : MAIN_INSTRUCTION["main"](s) #)()

MAIN      : "define" "void" "@" "main" "(" ")" "{" (MAIN_BODY) "}"
          { TirGrammarMod::actMAIN(\@item, \%item, \@arg); }

#===========================================================================
# Port Declarations
#===========================================================================
PORT_DIR  : "!" "\"" ("istream"|"ostream"|"iscalar"|"oscalar") "\"" /,?/ #/
          { TirGrammarMod::actPORT_DIR(\@item, \%item, \@arg); }

PORT_DATA_PATTERN : "!" "\"" ("CONT"|"BLOCKING") "\"" /,?/ #/
          { TirGrammarMod::actPORT_DATA_PATTERN(\@item, \%item, \@arg); }

PORT_PIPE_STAGE : "!" (INTEGER|"T") /,?/ #/
          { TirGrammarMod::actPORT_PIPE_STAGE(\@item, \%item, \@arg); }

PORT_STREAM_OBJECT : "!" "\"" NAME "\"" /,?/ #/
          { TirGrammarMod::actPORT_STREAM_OBJECT(\@item, \%item, \@arg); }
          
PORT_METADATA : PORT_DIR[$arg[0]] 
              | PORT_DATA_PATTERN[$arg[0]]  
              | PORT_PIPE_STAGE[$arg[0]]  
              | PORT_STREAM_OBJECT[$arg[0]]  

PORT_METADATAS : PORT_METADATA[$arg[0]](s) #)()

ADDR_SPACE_IDENT: INTEGER

PORT_DATA_TYPE   : DATA_TYPE

PORT  : "@" "main" "." NAME "=" "addrSpace" "(" ADDR_SPACE_IDENT ")"  PORT_DATA_TYPE "," PORT_METADATAS[$item{NAME}]
          { TirGrammarMod::actPORT(\@item, \%item, \@arg); }

PORTS     : PORT(s) #)()

# ****************************************************************************
# ****************************************************************************
#                                 MANAGE-IR
# ****************************************************************************
# ****************************************************************************

# ==========================================================================
# Stream Objects
# ==========================================================================
STREAM_IS_SIGNAL : "!" "\"" "signal" "\"" "," "!" "\"" ("yes"|"no") "\"" /,?/ #/
           { TirGrammarMod::actSTREAM_IS_SIGNAL(\@item, \%item, \@arg); }

STREAM_START_ADDR : "!" "\"" "start" "\"" "," "!" EXPRESSION /,?/
           { TirGrammarMod::actSTREAM_START_ADDR(\@item, \%item, \@arg); }

STREAM_LEN : "!" "\"" "length" "\"" "," "!" (MACRO_NAME|INTEGER) /,?/ #/
           { TirGrammarMod::actSTREAM_LEN(\@item, \%item, \@arg); }

#currently not used as was having problem getting stride from pattern in estimate()
#TODO
STREAM_PATTERN : "!" "\"" "pattern" "\"" "," "!" "\"" PATTERN "\"" /,?/ #/
           { TirGrammarMod::actSTREAM_PATTERN(\@item, \%item, \@arg); }

STREAM_STRIDE : "!" "\"" "stride" "\"" "," "!" (MACRO_NAME|INTEGER) /,?/ #/
           { TirGrammarMod::actSTREAM_STRIDE(\@item, \%item, \@arg); }

STREAM_DIR : "!" "\"" "dir" "\"" "," "!" "\"" DIRECTION "\"" /,?/ #/
           { TirGrammarMod::actSTREAM_DIR(\@item, \%item, \@arg); }

STREAM_MEM_CONN : "!" "\"" "memConn" "\"" "," "!" "\"" "@" MEM_NAME "\"" /,?/ #/
           { TirGrammarMod::actSTREAM_MEM_CONN(\@item, \%item, \@arg); }

STREAM_METADATA : STREAM_MEM_CONN[$arg[0]] 
                | STREAM_DIR[$arg[0]]
                | STREAM_LEN[$arg[0]]
                | STREAM_START_ADDR[$arg[0]]  
                | STREAM_IS_SIGNAL[$arg[0]]
                | STREAM_PATTERN[$arg[0]]
                | STREAM_STRIDE[$arg[0]]
                | <error: "Check Stream Metadata">

STRM_OBJ  : "@" NAME "=" "addrSpace" "(" ADDR_SPACE_IDENT ")" "," STREAM_METADATA[$item{NAME}](s) #)()
           { TirGrammarMod::actSTRM_OBJ(\@item, \%item, \@arg); }

STRM_OBJS : STRM_OBJ(s) #)()

# ==========================================================================
# Scalar Objects
# ==========================================================================
SCALAR_IVAL : "!" "\"" "ival" "\"" "," "!" (MACRO_NAME|INTEGER) /,?/ #/
           { TirGrammarMod::actSCALAR_IVAL(\@item, \%item, \@arg); }

SCLR_HOSTMAP_NAME : "!" "\"" "hmap" "\"" "," "!" "\"" NAME "\"" /,?/ #/
           { TirGrammarMod::actSCLR_HOSTMAP_NAME(\@item, \%item, \@arg); }

SCALAR_METADATA  : SCALAR_IVAL[$arg[0]]
                 | SCLR_HOSTMAP_NAME[$arg[0]]
 
SCALAR_METADATAS : SCALAR_METADATA[$arg[0]](s) #)()     

SCLR_OBJ  : "@" NAME "=" "addrSpace" "(" ADDR_SPACE_IDENT ")"  DATA_TYPE  "," SCALAR_METADATAS[$item{NAME}] 
          { TirGrammarMod::actSCLR_OBJ(\@item, \%item, \@arg); }

SCLR_OBJS : SCLR_OBJ(s) #)()

# ==========================================================================
# Memory objects
# ==========================================================================
MEM_HOSTMAP_NAME : "!" "\"" "hmap" "\"" "," "!" "\"" NAME "\"" /,?/ #/
          { TirGrammarMod::actMEM_HOSTMAP_NAME(\@item, \%item, \@arg); }

MEM_INIT_DATA : "!" "\"" "init" "\"" "," "!" "\"" NAME "\"" /,?/ #/
          { TirGrammarMod::actMEM_INIT_DATA(\@item, \%item, \@arg); }

MEM_READ_PORTS : "!" "\"" "readPorts" "\"" "," "!" INTEGER /,?/
          { TirGrammarMod::actMEM_READ_PORTS(\@item, \%item, \@arg); }

MEM_WRITE_PORTS : "!" "\"" "writePorts" "\"" "," "!" INTEGER /,?/
          { TirGrammarMod::actMEM_WRITE_PORTS(\@item, \%item, \@arg); }

MEM_METADATA  : MEM_HOSTMAP_NAME[$arg[0]]
              | MEM_INIT_DATA[$arg[0]]
              | MEM_READ_PORTS[$arg[0]]
              | MEM_WRITE_PORTS[$arg[0]]

MEM_METADATAS : MEM_METADATA[$arg[0]](s) #)()

MEM_SIZE  : INTEGER

MEM_OBJ : "@" NAME "=" "addrSpace" "(" ADDR_SPACE_IDENT ")" "<" MEM_SIZE "x" DATA_TYPE ">" "," MEM_METADATAS[$item{NAME}] 
        { TirGrammarMod::actMEM_OBJ(\@item, \%item, \@arg); }

MEM_OBJS : MEM_OBJ(s) #)()


# ==========================================================================
# Block Memory Transfers
# ==========================================================================
BLMEM_TR_SIZE_MDATA : "!" "\"" "trSizeWords" "\"" "," "!" INTEGER  /,?/
        { TirGrammarMod::actBLMEM_TR_SIZE_MDATA(\@item, \%item, \@arg); }

BLMEM_DEST_ADDR_MDATA : "!" "\"" "destStartAddr" "\"" "," "!" INTEGER  /,?/
        { TirGrammarMod::actBLMEM_DEST_ADDR_MDATA(\@item, \%item, \@arg); }

BLMEM_SRC_ADDR_MDATA : "!" "\"" "srcStartAddr" "\"" "," "!" INTEGER  /,?/
        { TirGrammarMod::actBLMEM_SRC_ADDR_MDATA(\@item, \%item, \@arg); }

BLOCK_MEM_COPY_METADATA : BLMEM_SRC_ADDR_MDATA  
                        | BLMEM_DEST_ADDR_MDATA
                        | BLMEM_TR_SIZE_MDATA

BLOCK_MEM_COPY : "@" NAME1 "=" "@" NAME2 "," "!" "\"" "tir.lmem.copy" "\"" /,?/ BLOCK_MEM_COPY_METADATA(s) #/
        { TirGrammarMod::actBLOCK_MEM_COPY(\@item, \%item, \@arg); }

# ==========================================================================
# Repeat
# ==========================================================================
CALL_MAIN_IN_REPEAT : "call" "@" "main" "(" ")"
        { TirGrammarMod::actCALL_MAIN_IN_REPEAT(\@item, \%item, \@arg); }

REPEAT_BODY : CALL_MAIN_IN_REPEAT BLOCK_MEM_COPY(s) #)()
  # The repeat body must have one call to main, followed by one or more
  # block memory copy statements

REPEAT    : "repeat" NAME "=" INTEGER1 ":" INTEGER2 "{" REPEAT_BODY "}"
        { TirGrammarMod::actREPEAT(\@item, \%item, \@arg); }

# ============================================================================
# The LAUNCH body
# ============================================================================
LAUNCH_OBJECT  : MEM_OBJS
               | STRM_OBJS
               | SCLR_OBJS
               | BLOCK_MEM_COPY
               | <error>

# This CALL_MAIN rule is only called when there is no 
# repeat block
CALL_MAIN : "call" "@" "main" "(" ")"
        { TirGrammarMod::actCALL_MAIN(\@item, \%item, \@arg); }

# Launch ends by either calling main once, or calling a repeat block
LAUNCH_BODY : LAUNCH_OBJECT(s) (CALL_MAIN|REPEAT) #)()

LAUNCH      : "define" "void" "launch" "(" ")" "{" LAUNCH_BODY "}"    
        { TirGrammarMod::actLAUNCH(\@item, \%item, \@arg); }

# ============================================================================
# define macros
# ============================================================================
# Not needed if using GCC pre-processor
DEFINE_STATEMENT : "#" "define" NAME /\S+/
        { TirGrammarMod::actDEFINE_STATEMENT(\@item, \%item, \@arg); }

MACROS           : DEFINE_STATEMENT(s) #)()

# ============================================================================
# Start rule 
# ============================================================================
SECTION : LAUNCH
        | FUNCTIONS
        | MAIN      
        | PORTS
        | <error>

STARTRULE: SECTION(s) #)()
