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
void dyn2   ( data_t dt
            , data_t dx
            , data_t dy
            , data_t   un_j_k
            , data_t un_j_km1
            , data_t   vn_j_k
            , data_t vn_jm1_k
            , data_t    h_j_k
            , data_t  h_jm1_k
            , data_t  h_j_km1
            , data_t  h_j_kp1
            , data_t  h_jp1_k
            , data_t  eta_j_k
            , data_t j
            , data_t k
            , data_t *etan_j_k
            )
{              
  //un_j_k = 0.0;
  //vn_j_k = 0.0;
  
  //locals
  //-------------------
  data_t hue;
  data_t huw;
  data_t hwp;
  data_t hwn;
  data_t hen;
  data_t hep;
  data_t hvn;
  data_t hvs;
  data_t hsp;
  data_t hsn;
  data_t hnn;
  data_t hnp;

  //kernel loop
//   if  ((j>=1) && (k>=1) && (j<= ROWS-2) && (k<=COLS-2)) {      
      hep = 0.5f*( un_j_k + ABS(un_j_k) ) * h_j_k;
      hen = 0.5f*( un_j_k - ABS(un_j_k) ) * h_j_kp1;
      hue = hep+hen;
  
      hwp = 0.5f*( un_j_km1 + ABS(un_j_km1) ) * h_j_km1;
      hwn = 0.5f*( un_j_km1 - ABS(un_j_km1) ) * h_j_k;
      huw = hwp+hwn;
  
      hnp = 0.5f*( vn_j_k + ABS(vn_j_k) ) * h_j_k;
      hnn = 0.5f*( vn_j_k - ABS(vn_j_k) ) * h_jp1_k;
      hvn = hnp+hnn;
  
      hsp = 0.5f*( vn_jm1_k + ABS(vn_jm1_k) ) * h_jm1_k;
      hsn = 0.5f*( vn_jm1_k - ABS(vn_jm1_k) ) * h_j_k;
      hvs = hsp+hsn;
  
      *etan_j_k  = eta_j_k
                - dt*(hue-huw)/dx
                - dt*(hvn-hvs)/dy;
                
  //  }//if not boundary
}//()