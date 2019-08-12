#define ROWS    53
#define COLS    ROWS

#define data_t float

//------------------------------------------
// dyn1() - the dynamics (1 of 2)
//------------------------------------------
__attribute__((annotate("tytra_linear_size(1024)")))
void dyn  ( data_t dt
          , data_t dx
          , data_t dy
          , data_t g
          , data_t u_j_k    
          , data_t v_j_k    
          , data_t h_j_k    
          , data_t eta_j_k  
          , data_t eta_j_kp1
          , data_t eta_jp1_k
          , data_t etan_j_k 
          , data_t wet_j_k  
          , data_t wet_j_kp1
          , data_t wet_jp1_k
          , data_t hzero_j_k
          , data_t j
          , data_t k
          , data_t *un_j_k
          , data_t *vn_j_k
          )
{              
    //un_j_k = 0.0;
    //vn_j_k = 0.0;
    
    //locals
    //-------------------
    data_t du;
    data_t dv;
    data_t uu;
    data_t vv;
    data_t duu;
    data_t dvv;

    //exclude boundaries when computing un and vn
    if  ((j>=1) && (k>=1) && (j<= ROWS-2) && (k<=COLS-2)) {      
      duu  = -dt 
           * g
           * ( eta_j_kp1
             - eta_j_k
             ) 
           / dx;
      dvv  = -dt 
           * g
           * ( eta_jp1_k
             - eta_j_k
             ) 
           / dy;

      //prediction for u and v (merged loop)
      //---------------------------------
      uu = u_j_k;
      if (  ( (wet_j_k == 1)
              && ( (wet_j_kp1 == 1) || (duu > 0.0)))
         || ( (wet_j_kp1 == 1) && (duu < 0.0))     
         ){
          *un_j_k = uu+duu;
      }//if
      
      vv = v_j_k;
      if (  (  (wet_j_k == 1)
             && ( (wet_jp1_k == 1) || (dvv > 0.0)))
         || ((wet_jp1_k == 1) && (dvv < 0.0))
         ){
          *vn_j_k = vv+dvv;
      }//if
  }//if   
}//()