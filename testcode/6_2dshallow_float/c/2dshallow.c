#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define EPSILON 0.1
#define NTOT    1000
#define ROWS    53
#define COLS    ROWS
#define NX      (ROWS-2)
#define NY      (COLS-2)
#define XMID    (NX/2)
#define YMID    (NY/2)
#define SIZE   (ROWS*COLS)

#define ALIGNMENT 64

//#define host_t int
#define host_t float

#define FXS 100
  //fix-point scaling (so that our code is "integer" version only)

// =========================
// Commonly used Macros
// =========================
# define HLINE "-------------------------------------------------------------\n"
# define SLINE "*************************************************************\n"

# ifndef MIN
# define MIN(x,y) ((x)<(y)?(x):(y))
# endif
# ifndef MAX
# define MAX(x,y) ((x)>(y)?(x):(y))
# endif  
  
// =========================
// Signatures
// =========================
void init_data  ( host_t *hzero
                 , host_t *eta  
                 , host_t *etan 
                 , host_t *h    
                 , host_t *wet  
                 , host_t *u    
                 , host_t *un   
                 , host_t *v    
                 , host_t *vn
                 , host_t hmin
                 , int       BytesPerWord
                 );

void dyn  ( host_t  dt
          , host_t  dx
          , host_t  dy
          , host_t  g                    
          , host_t  *eta
          , host_t  *un
          , host_t  *u
          , host_t  *wet
          , host_t  *v
          , host_t  *vn
          , host_t  *h
          , host_t  *etan
          , int     BytesPerWord                    
          );

void shapiro ( host_t *wet 
             , host_t *etan
             , host_t eps
             , host_t *eta
             );


void updates  ( host_t *h 
              , host_t *hzero
              , host_t *eta
              , host_t *u
              , host_t *un
              , host_t *v
              , host_t *vn
              , host_t *wet
              , host_t hmin
              );

void log_results ( host_t* eta_g
                 , host_t* h_g
                 , host_t* u_g
                 , host_t* v_g
                 , host_t* hzero_g
                 );
                
// =========================
// Main
// =========================

int main(int argc, char** argv) {
 
// ======================================================================
// CONSTANTS
// ======================================================================
   const int ntot = NTOT; //how many time steps
   const int nout = 5;    //log output after every how many steps?
   const int rows = ROWS;
   const int cols = COLS;
   const int BytesPerWord = sizeof(host_t);

  //scalars
   host_t hmin    = (host_t) (FXS* 0.05);
   host_t dx      = (host_t) (FXS* 10.0);
   host_t dy      = (host_t) (FXS* 10.0);
   host_t dt      = (host_t) (FXS* 0.1 );
   host_t g       = (host_t) (FXS* 9.81);  
   host_t eps     = (host_t) (FXS* 0.05);
   host_t hmin_g  = (host_t) (FXS* 0.05); //golden copies not really needed, but to avoid bugs
   host_t dx_g    = (host_t) (FXS* 10.0);
   host_t dy_g    = (host_t) (FXS* 10.0);
   host_t dt_g    = (host_t) (FXS* 0.1 );
   host_t g_g     = (host_t) (FXS* 9.81);  
   host_t eps_g   = (host_t) (FXS* 0.05);
      
// ======================================================================
// Host run
// ======================================================================
  printf ("*** HOST Run ***\n");
   
  //arrays
  host_t  *hzero_g
            ,*eta_g  
            ,*etan_g 
            ,*h_g    
            ,*wet_g  
            ,*u_g    
            ,*un_g   
            ,*v_g    
            ,*vn_g
            ;   

  eta_g  =malloc(SIZE*BytesPerWord);
  etan_g =malloc(SIZE*BytesPerWord);
  h_g    =malloc(SIZE*BytesPerWord);
  hzero_g=malloc(SIZE*BytesPerWord);
  wet_g  =malloc(SIZE*BytesPerWord);
  u_g    =malloc(SIZE*BytesPerWord);
  un_g   =malloc(SIZE*BytesPerWord);
  v_g    =malloc(SIZE*BytesPerWord);
  vn_g   =malloc(SIZE*BytesPerWord);


  //initialize arrays
  //-------------------------
  init_data(hzero_g, eta_g, etan_g, h_g, wet_g, u_g, un_g, v_g, vn_g, hmin, BytesPerWord);

  // determine parameters
  //-------------------------
  
  // determine maximum water depth
  host_t hmax_g= (int) 0.0;
  for (int j=1; j<= COLS-2; j++) {
    for (int k=1; k<=ROWS-2; k++) {
      hmax_g = MAX (hmax_g, *(h_g + j+COLS + k));
    }
  }
  //maximum phase speed
  host_t c_g = sqrt(2*g*hmax_g);
  
  //determine stability parameter
  host_t lambda_g = dt*sqrt(g*hmax_g)/MIN(dx,dy);
  
  printf ("Host: starting time loop for host run\n");

  // simulation loop
  //-------------------------
  for (int i=0;i<ntot;i++) {  
    dyn(dt, dx, dy, g, eta_g, un_g, u_g, wet_g, v_g, vn_g, h_g, etan_g, BytesPerWord); 
    shapiro(wet_g, etan_g, eps_g, eta_g);
    updates  (h_g , hzero_g, eta_g, u_g, un_g, v_g, vn_g, wet_g, hmin_g);
  }
  
  // log results
  //-------------------------
  log_results(eta_g, h_g, u_g, v_g, hzero_g);

}//main()



//------------------------------------------
// initialize 2D shallow-water host arrays
//------------------------------------------
void init_data ( host_t *hzero
                , host_t *eta  
                , host_t *etan 
                , host_t *h    
                , host_t *wet  
                , host_t *u    
                , host_t *un   
                , host_t *v    
                , host_t *vn
                , host_t hmin
                , int BytesPerWord
                ) {
      
//FILE * fdebug;
//fdebug= fopen ("debug.dat","w");

  int j, k;
  //initialize height
  for (j=0; j<=ROWS-1; j++) {
    for (k=0; k<=COLS-1; k++) {
      hzero[j*COLS + k] = (int) FXS * 10.0;
    }
  }

  //land boundaries with 10 m elevation
  for (k=0; k<=COLS-1; k++) {
    //top-row
    hzero[0*COLS + k] = (int) FXS * -10.0;
    //bottom-row (ROWS-1)
    hzero[(ROWS-1)*COLS + k] = (int) FXS * -10.0;
  }
  for (j=0; j<=ROWS-1; j++) {
    //left-most-col
    hzero[j*COLS + 0] = (int) FXS * -10.0;
    //right-most-col
    hzero[j*COLS + COLS-1] = (int) FXS * -10.0;
  }

  // eta and etan
  for (j=0; j<= ROWS-1; j++) {
    for (k=0; k<=COLS-1; k++) {
      eta [j*COLS + k] = -MIN(0, hzero[j*COLS + k] );
      etan[j*COLS + k] = eta[j*COLS + k];
//      fprintf(fdebug, "j = %d, k = %d, eta = %f\n"
//                       ,j, k, eta[j*COLS + k]);
    }                                                                           
  } 

  //h, wet, u, un, v, vn
  // eta and etan
  for (j=0; j<= ROWS-1; j++) {
    for (k=0; k<= COLS-1; k++) {
      //h
      h[j*COLS + k] = hzero[j*COLS + k] 
                    +   eta[j*COLS + k];
      //wet                   
      //wet = 1 defines "wet" grid cells 
      //wet = 0 defines "dry" grid cells (land)
//temp-for-debug
//    wet[j*COLS + k] = j*COLS + k +1; 

      
//#if 0
      wet[j*COLS + k] = 1; 
      if (h[j*COLS + k] < hmin)
       wet[j*COLS + k] = 0; 
//#endif
      //u, v, un, vn
      u [j*COLS + k] = 0;
      un[j*COLS + k] = 0;
      v [j*COLS + k] = 0;
      vn[j*COLS + k] = 0;

//printf("HOST-INIT:j = %d, k = %d,  wet = %f\n"
//               , j, k, wet[j*COLS + k]
//      );

    }
  }

  //Initial Condition... Give eta=1 @ MID_POINT
  //-------------------------------------------
  *(eta+ XMID*COLS + YMID) = (int) FXS * 1.0;


 printf("Host arrays initialized.\n");

 //fclose(fdebug);  
}

//------------------------------------------
// dyn() - the dynamics
//------------------------------------------

void dyn  ( host_t dt
          , host_t dx
          , host_t dy
          , host_t g
          , host_t *eta
          , host_t *un
          , host_t *u
          , host_t *wet
          , host_t *v
          , host_t *vn
          , host_t *h
          , host_t *etan
          , int BytesPerWord
          ) {



//locals
//-------------------
host_t *du;// [ROWS][COLS];
host_t *dv;// [ROWS][COLS];
du  =malloc(SIZE*BytesPerWord);
dv  =malloc(SIZE*BytesPerWord);
host_t uu;
host_t vv;
host_t duu;
host_t dvv;
host_t hue;
host_t huw;
host_t hwp;
host_t hwn;
host_t hen;
host_t hep;
host_t hvn;
host_t hvs;
host_t hsp;
host_t hsn;
host_t hnn;
host_t hnp;
int j, k;


//calculate du, dv on all non-boundary points
//-------------------------------------------
  for (j=1; j<= ROWS-2; j++) {
    for (k=1; k<= COLS-2; k++) {
      du[j*COLS + k]  = -dt 
                      * g
                      * ( eta[j*COLS + k+1 ]
                        - eta[j*COLS + k   ]
                        ) 
                      / dx;
      dv[j*COLS + k]  = -dt 
                      * g
                      * ( eta[(j+1)*COLS + k]
                        - eta[    j*COLS + k]
                        ) 
                      / dy;
    }
  }


//prediction for u and v
//---------------------------------
  for (j=1; j<= ROWS-2; j++) {
    for (k=1; k<= COLS-2; k++) {

      //u
      un[j*COLS + k]  = 0.0;
      uu = u[j*COLS + k];
      duu= du[j*COLS + k];
      if (wet[j*COLS + k] == 1){
        if( (wet[j*COLS + k+1] == 1) || (duu > 0.0) ) 
          un[j*COLS + k] = uu+duu;
      }//if
      else {
        if((wet[j*COLS + k+1] == 1) && (duu < 0.0) )
          un[j*COLS + k] = uu+duu;
      }//else

      //v
      vn[j*COLS + k]  = 0.0;
      vv =  v[j*COLS + k];
      dvv= dv[j*COLS + k];
      if (wet[j*COLS + k] == 1){
        if( (wet[(j+1)*COLS + k] == 1) || (dvv > 0.0) ) 
          vn[j*COLS + k] = vv+dvv;
      }//if
      else {
        if((wet[(j+1)*COLS + k] == 1) && (dvv < 0.0) )
          vn[j*COLS + k] = vv+dvv;
      }//else

    }//for
  }//for

//sea level predictor
//--------------------
  for (j=1; j<= ROWS-2; j++) {
    for (k=1; k<= COLS-2; k++) {   
      hep = 0.5*( un[j*COLS + k] + fabs(un[j*COLS + k]) ) * h[j*COLS + k  ];
      hen = 0.5*( un[j*COLS + k] - fabs(un[j*COLS + k]) ) * h[j*COLS + k+1];
      hue = hep+hen;

      hwp = 0.5*( un[j*COLS + k-1] + fabs(un[j*COLS + k-1]) ) * h[j*COLS + k-1];
      hwn = 0.5*( un[j*COLS + k-1] - fabs(un[j*COLS + k-1]) ) * h[j*COLS + k  ];
      huw = hwp+hwn;

      hnp = 0.5*( vn[j*COLS + k] + fabs(vn[j*COLS + k]) ) * h[    j*COLS + k];
      hnn = 0.5*( vn[j*COLS + k] - fabs(vn[j*COLS + k]) ) * h[(j+1)*COLS + k];
      hvn = hnp+hnn;

      hsp = 0.5*( vn[(j-1)*COLS + k] + fabs(vn[(j-1)*COLS + k]) ) * h[(j-1)*COLS + k];
      hsn = 0.5*( vn[(j-1)*COLS + k] - fabs(vn[(j-1)*COLS + k]) ) * h[    j*COLS + k];
      hvs = hsp+hsn;

      etan[j*COLS + k]  = eta[j*COLS + k]
                        - dt*(hue-huw)/dx
                        - dt*(hvn-hvs)/dy;
    }//for
  }//for  

//fclose(fdebug);  
}//()


//------------------------------------------
// shapiro() - filter
//------------------------------------------
void shapiro  ( host_t *wet 
              , host_t *etan
              , host_t eps
              , host_t *eta
              ) {

  //locals
  int j,k;
  host_t term1,term2,term3;

  //1-order Shapiro filter
  for (j=1; j<= ROWS-2; j++) {
    for (k=1; k<= COLS-2; k++) {   
        if (wet[j*COLS + k]==1) {
        term1 = ( 1.0-0.25*eps
                  * ( wet[    j*COLS + k+1] 
                    + wet[    j*COLS + k-1] 
                    + wet[(j+1)*COLS + k  ] 
                    + wet[(j-1)*COLS + k  ] 
                    ) 
                )
                * etan[j*COLS + k]; 
        term2 = 0.25*eps
                * ( wet [j*COLS + k+1]
                  * etan[j*COLS + k+1]
                  + wet [j*COLS + k-1]
                  * etan[j*COLS + k-1]
                  );
        term3 = 0.25*eps
                * ( wet [(j+1)*COLS + k]
                  * etan[(j+1)*COLS + k]
                  + wet [(j-1)*COLS + k]
                  * etan[(j-1)*COLS + k]
                  );
        eta[j*COLS + k] = term1 + term2 + term3;
      }//if
      else {
        eta[j*COLS + k] = etan[j*COLS + k];
      }//else
    }//for
  }//for
}//()


//------------------------------------------
// updates() - 
// in the original this was part of main
//------------------------------------------
void updates  ( host_t *h 
              , host_t *hzero
              , host_t *eta
              , host_t *u
              , host_t *un
              , host_t *v
              , host_t *vn
              , host_t *wet
              , host_t hmin
              ) {

  for (int j=0; j<= ROWS-1; j++) {
    for (int k=0; k<=COLS-1; k++) {
      //h update
      h[j*COLS + k] = hzero[j*COLS + k] 
                    + eta  [j*COLS + k];
      //wet update
      wet[j*COLS + k] = 1;
      if ( h[j*COLS + k] < hmin )
            wet[j*COLS + k] = 0;
      //u, v updates
      u[j*COLS + k] = un[j*COLS + k];
      v[j*COLS + k] = vn[j*COLS + k];
    }//for
  }//for
}//()

//------------------------------------------
// oclh_log_results
//------------------------------------------
void log_results ( host_t* eta_g
                 , host_t* h_g
                 , host_t* u_g
                 , host_t* v_g
                 , host_t* hzero_g
){
  printf("Logging data\n");
  FILE * feta_g;
  FILE * fh_g;
  FILE * fu_g;
  FILE * fv_g;
  FILE * fhzero_g;
  feta_g    = fopen ("eta_g.dat"  ,"w");
  fh_g      = fopen ("h_g.dat"    ,"w");
  fu_g      = fopen ("u_g.dat"    ,"w");
  fv_g      = fopen ("v_g.dat"    ,"w");
  fhzero_g  = fopen ("hzero_g.dat","w");

  for (int i = 0; i < ROWS; ++i) {
    for (int j = 0; j < COLS; ++j) {
      fprintf(feta_g  ,"%d,  ", *(eta_g   + i*COLS + j));
      fprintf(fh_g    ,"%d,  ", *(h_g     + i*COLS + j));
      fprintf(fu_g    ,"%d,  ", *(u_g     + i*COLS + j));
      fprintf(fv_g    ,"%d,  ", *(v_g     + i*COLS + j));
      fprintf(fhzero_g,"%d,  ", *(hzero_g + i*COLS + j));
    }//j
    fprintf(feta_g  ,"\n");
    fprintf(fh_g    ,"\n");
    fprintf(fu_g    ,"\n");
    fprintf(fv_g    ,"\n");
    fprintf(fhzero_g,"\n");
  }//i
  fclose(feta_g  );  
  fclose(fh_g    );
  fclose(fu_g    );  
  fclose(fv_g    );
  fclose(fhzero_g);
}//()