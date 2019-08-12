#define ROWS    53
#define COLS    ROWS

#define data_t float

//have a way to deal with ABS (stub function)
#define ABS fabs
float fabs (data_t in){}


//------------------------------------------
// dyn1() - the dynamics (1 of 2)
//------------------------------------------
__attribute__((annotate("tytra_linear_size(1024)")))
void shapiro  ( data_t hmin 
              , data_t un_j_k   
              , data_t vn_j_k   
              , data_t hzero_j_k
              , data_t eta_j_k
              , data_t* u_j_k
              , data_t* v_j_k
              , data_t* h_j_k
              , data_t* wet_j_k
              )
{    
  //h update
  *h_j_k = hzero_j_k
        + eta_j_k;
  //wet update
  *wet_j_k = 1;
  //if ( h_j_k < hmin )
  //      wet_j_k = 0;
  //u, v updates
  *u_j_k = un_j_k;
  *v_j_k = vn_j_k;

}//()