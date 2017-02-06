// =============================================================================
// Company              : Unversity of Glasgow, Comuting Science
// Template Author      :        Syed Waqar Nabi
//
// Project Name         : TyTra
//
// Target Devices       : Stratix V 
//
// Generated Design Name: <design_name>
// Generator Version    : <gen_ver>
// Generator TimeStamp  : <timeStamp>
// 
// Dependencies         : <dependencies>
//
// =============================================================================

// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// A generic template for custom design configuration file for TyBEC
// ============================================================================= 

`ifndef _INCLUDE_CUSTOM_DESIGN_
`define _INCLUDE_CUSTOM_DESIGN_

// include common tytra header
`include "includeTytraCommon.v"
  
// =============================================================================
// ** TIME SCALE **
// =============================================================================
`timescale 1ns/1ps



// =============================================================================
// ** Design Parameters 
// =============================================================================

// -----------------------------------------------------------------------------
// CLOCK
// -----------------------------------------------------------------------------

// clock
`define CLK_HALF 5

// -----------------------------------------------------------------------------
// STREAM/DATA/MEMORY PARAMETERS
// -----------------------------------------------------------------------------

`define DataW         <DataW> // default data width of streams and functional units
<streamParameters>
//<<<<<<<<<<<<<<< GENERATED CODE UPTO HERE >>>>>>>>>>>>>>>>>


// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
// ENUMERATION FOR INITIALIZATION OF MEMORIES AT COMPILE TIME
`define ID_LMEM_a 1
`define ID_LMEM_b 2
`define ID_LMEM_c 3


`endif
           
