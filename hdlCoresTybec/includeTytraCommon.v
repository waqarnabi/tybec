// =============================================================================
// Company      : Unversity of Glasgow, Comuting Science
// Author:        Syed Waqar Nabi
// 
// Create Date  : 2014.12.05
// Design Name  : NA
// Module Name  : 
// Project Name : TyTra
// Target Devices:
// Tool versions: 
//
// Dependencies : 
//
// Revision     : 
// Revision 0.01. File Created
// 
// Conventions  : 
// ==============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// Common include file for all TyTra-RTL designs
// =============================================================================

`ifndef _INCLUDE_TYTRA_COMMON_
`define _INCLUDE_TYTRA_COMMON_

// =============================================================================
// ** CONVENIENCE MACROS **
// =============================================================================
`define b2r         $bitstoreal
`define r2b         $realtobits

// Flattening (Packing) and Unpacking an array to pass it through ports
// REF: Acknowledging "mrfibble" --> http://www.edaboard.com/thread80929.html
`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST)    genvar pk_idx; generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin:gepack assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end endgenerate
`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC)  genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin:genunpack assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end endgenerate


// equivalent of $clog(n) for computing the number of bits required to address a certain size/depth
// courtesy: http://stackoverflow.com/questions/5269634/address-width-from-ram-depth
`define CLOG2(x) \
(x<	2 	)?1: \
(x<	4 	)?2: \
(x<	8 	)?3: \
(x<	16 	)?4: \
(x<	32 	)?5: \
(x<	64 	)?6: \
(x<	128 	)?7: \
(x<	256 	)?8: \
(x<	512 	)?9: \
(x<	1024 	)?10: \
(x<	2048 	)?11: \
(x<	4096 	)?12: \
(x<	8192 	)?13: \
(x<	16384 	)?14: \
(x<	32768 	)?15: \
(x<	65536 	)?16: \
(x<	131072 	)?17: \
(x<	262144 	)?18: \
(x<	524288 	)?19: \
(x<	1048576 	)?20: \
(x<	2097152 	)?21: \
(x<	4194304 	)?22: \
(x<	8388608 	)?23: \
(x<	16777216 	)?24: \
(x<	33554432 	)?25: \
(x<	67108864 	)?26: \
(x<	134217728 	)?27: \
(x<	268435456 	)?28: \
(x<	536870912 	)?29: \
(x<	1073741824 	)?30: \
(x<	2147483648 	)?31: \
 -1

// -----------------------------------------------------------------------------
// TYTRA DATA TYPES
// -----------------------------------------------------------------------------

`define ui18_W 18       


// =============================================================================
// ** DEFINING ARITHMETIC UNITS
// =============================================================================

//`define OP_imul mult
//`define OP_iadd add

`endif
           
