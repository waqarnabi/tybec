#define IM 16
//
void f_1( int vin0_i,int vin0_im1,int  vin0_ip1,int vin1_i, int*  vconn0_i,int* vconn1_i, int i) {
 //boundary, pass through
    if ( (i==0) || (i==IM-1) ) {
      *vconn0_i = vin0_i;
      *vconn1_i = vin1_i;
    }
//non-boundary
    else {
      *vconn0_i = vin0_i + vin0_im1 + vin0_ip1 + vin1_i ;
      *vconn1_i = vin0_i + vin0_im1 + vin0_ip1 * vin1_i ;
    }//else
    
}

