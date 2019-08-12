// =============================================================================
// Company      : Unversity of Glasgow, Comuting Science
// Author:        Syed Waqar Nabi
// 
// Create Date  : 2019.06.19
// Project Name : TyTra
//
// Dependencies : 
//
// Revision     : 
// Revision 0.01. File Created
// 
// Conventions  : 
// =============================================================================
//
// =============================================================================
// General Description
// -----------------------------------------------------------------------------
// Coriolis acceleration kernel, manually written in C
// to use for conversion to TIR via LLVM-IR
// =============================================================================

#define SIZE   1024

#define data_t float

//randomly initialized constants
//#define alpha 0.1f
//#define beta  0.2f
#define dt    0.1f

//mode also defined as a macro
#define mode 2


//----------------------------------------------------------------------------
// coriolis_ker0
//----------------------------------------------------------------------------
//I shouldnt need to pass alpha and beta, but it makes TIR conversion easier
void coriolis_ker0  ( data_t alpha
                    , data_t beta
                    , data_t u
                    , data_t v
                    , data_t *un
                    , data_t *vn
                    ) 
{
  #if (mode==1)
   *un = (u*(1.0f-beta)+alpha*v)/(1.0f+beta);
   *vn = (v*(1.0f-beta)-alpha*u)/(1.0f+beta);
  #else
    *un = cos(alpha)*u+sin(alpha)*v;
    *vn = cos(alpha)*v-sin(alpha)*u;
  #endif
}

//----------------------------------------------------------------------------
// coriolis_ker1
//----------------------------------------------------------------------------
void coriolis_ker1  ( data_t x
                    , data_t y
                    , data_t un
                    , data_t vn
                    , data_t *xn
                    , data_t *yn
                    ) 
{                    
  // predictor of new location
  *xn = x + dt*un/1000.0f;
  *yn = y + dt*vn/1000.0f;
}


//----------------------------------------------------------------------------
// coriolis_ker2
//----------------------------------------------------------------------------
void coriolis_ker2  ( data_t un
                    , data_t vn
                    , data_t xn
                    , data_t yn
                    , data_t *u
                    , data_t *v
                    , data_t *x
                    , data_t *y
                    ) 
{                    
  // updates for next time step 
  *u = un;
  *v = vn;
  *x = xn;
  *y = yn;
}