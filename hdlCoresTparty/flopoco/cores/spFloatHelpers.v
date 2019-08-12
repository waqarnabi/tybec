// -----------------------------------------------------------------------------
// ** helper functions for floats
// By: S Waqar Nabi, Glasgow University, 2018.03.16
// -----------------------------------------------------------------------------

//convert 64-bit double precision (e.g. returned from $real2bits) to 32-bit single precision
function [31:0] doubletosingle;
  input [63:0] d;
  reg [7:0] exp4s;
  integer exp4dval;
  
  begin
    exp4dval = d[62:52]-1023;
    exp4s    = exp4dval+127; //assumption is this will be >= 0
    doubletosingle = {d[63],exp4s,d[51:29]};    
  end
endfunction

//convert 32-bit single precision to 64-bit double precision (to be used e.g. in $bitstoreal)
function [63:0] singletodouble;
   input [31:0] s;
   reg   [10:0] exp4d;

   begin
     exp4d = s[30:23]-127+1023;
     singletodouble = {s[31], exp4d, s[22:0], {29{1'b0}} };
   end
endfunction

//get bits from real for 32-bit single precision representation
function [31:0] realtobitsSingle;
  input real r;  
  reg [63:0] bitsDouble;
  
  begin
    bitsDouble      = $realtobits(r);
    realtobitsSingle = doubletosingle(bitsDouble);
  end
endfunction

//get real from 32-bit single precision representation
function real bitstorealSingle;
  input [31:0] bitsSingle;  
  reg [63:0] bitsDouble;
  
  begin
    bitsDouble      = singletodouble(bitsSingle);
    bitstorealSingle = $bitstoreal(bitsDouble);
  end
endfunction




// -----------------------------------------------------------------------------
// ** Experimenting with doubles, floats
// -----------------------------------------------------------------------------
/*
real        doubleX;
real        doubleX_rec;
reg [63:0]  bitsDoubleX;
reg [63:0]  bitsDoubleX_rec; //recovered bits
reg [31:0]  bitsSingleX;

initial begin
  doubleX = 2.5;
  bitsDoubleX = $realtobits(doubleX) ;
  bitsSingleX = double2single(bitsDoubleX);
  bitsDoubleX_rec = single2double(bitsSingleX);
  doubleX_rec = $bitstoreal(bitsDoubleX_rec);
  $display("\n> doubleX = %f", doubleX);
  $display("> bitsDoubleX     :: sign = %b, exponent = %b, mantissa = %b",  bitsDoubleX[63], bitsDoubleX[62:52], bitsDoubleX[51:0] );
  $display("> bitsSingleX     :: sign = %b, exponent = %b, mantissa = %b",  bitsSingleX[31], bitsSingleX[30:23], bitsSingleX[22:0] );
  $display("> bitsDoubleX_rec ::  sign = %b, exponent = %b, mantissa = %b", bitsDoubleX_rec[63], bitsDoubleX_rec[62:52], bitsDoubleX_rec[51:0] );
  $display("> doubleX_rec = %f", doubleX_rec);

  doubleX = 1.0;
  bitsDoubleX = $realtobits(doubleX) ;
  bitsSingleX = double2single(bitsDoubleX);
  bitsDoubleX_rec = single2double(bitsSingleX);
  doubleX_rec = $bitstoreal(bitsDoubleX_rec);
  $display("\n> doubleX = %f", doubleX);
  $display("> bitsDoubleX     :: sign = %b, exponent = %b, mantissa = %b",  bitsDoubleX[63], bitsDoubleX[62:52], bitsDoubleX[51:0] );
  $display("> bitsSingleX     :: sign = %b, exponent = %b, mantissa = %b",  bitsSingleX[31], bitsSingleX[30:23], bitsSingleX[22:0] );
  $display("> bitsDoubleX_rec ::  sign = %b, exponent = %b, mantissa = %b", bitsDoubleX_rec[63], bitsDoubleX_rec[62:52], bitsDoubleX_rec[51:0] );
  $display("> doubleX_rec = %f", doubleX_rec);

  doubleX = 15482.2144;
  bitsDoubleX = $realtobits(doubleX) ;
  bitsSingleX = double2single(bitsDoubleX);
  bitsDoubleX_rec = single2double(bitsSingleX);
  doubleX_rec = $bitstoreal(bitsDoubleX_rec);
  $display("\n> doubleX = %f", doubleX);
  $display("> bitsDoubleX     :: sign = %b, exponent = %b, mantissa = %b",  bitsDoubleX[63], bitsDoubleX[62:52], bitsDoubleX[51:0] );
  $display("> bitsSingleX     :: sign = %b, exponent = %b, mantissa = %b",  bitsSingleX[31], bitsSingleX[30:23], bitsSingleX[22:0] );
  $display("> bitsDoubleX_rec ::  sign = %b, exponent = %b, mantissa = %b", bitsDoubleX_rec[63], bitsDoubleX_rec[62:52], bitsDoubleX_rec[51:0] );
  $display("> doubleX_rec = %f", doubleX_rec);

  end  
*/
