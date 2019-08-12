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
void shapiro  ( data_t        eps
              , data_t   etan_j_k
              , data_t etan_jm1_k
              , data_t etan_j_km1
              , data_t etan_j_kp1
              , data_t etan_jp1_k
              , data_t    wet_j_k
              , data_t  wet_jm1_k
              , data_t  wet_j_km1
              , data_t  wet_j_kp1
              , data_t  wet_jp1_k
              , data_t*   eta_j_k
              )
{              
    //locals
    data_t term1,term2,term3;

  ////exclude boundaries
  //if  ((j>=1) && (k>=1) && (j<= ROWS-2) && (k<=COLS-2)) {      
  //    if (wet_j_k==1) {
      term1 = ( 1.0f-0.25f*eps
                * ( wet_j_kp1
                  + wet_j_km1
                  + wet_jp1_k
                  + wet_jm1_k
                  ) 
              )
              * etan_j_k;
      term2 = 0.25f*eps
              * ( wet_j_kp1
                * etan_j_kp1
                + wet_j_km1
                * etan_j_km1
                );
      term3 = 0.25f*eps
              * ( wet_jp1_k
                * etan_jp1_k
                + wet_jm1_k
                * etan_jm1_k
                );
      *eta_j_k = term1 + term2 + term3;
    //}//if
    //else {
    //  eta_j_k = etan_j_k;
    //}//else
}//()