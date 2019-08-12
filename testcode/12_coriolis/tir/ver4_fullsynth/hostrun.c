  float dt,freq,f,pi,alpha,beta;
  
  // Coriolis specific constants //
  //global constants
  pi    = 4.0*atan(1.0)       ;// this calculates Pi  
  freq  = -2.*pi/(24.*3600.)  ;//
  f     = 2*freq              ;// Coriolis parameter
  dt    = 24.*3600./200.      ;// time step
  
  // parameters for semi-implicit scheme
  alpha = f*dt            ;//
  beta = 0.25*alpha*alpha ;//

  //print constant values for use in TIR/HDL
  printf("alpha = %f\n" , alpha);
  printf("beta = %f\n"  , beta);
  printf("dt = %f\n"    , dt);
  //\Coriolis specific constants //
   
  printf("TY:Starting Host run timer\n");
  
  //<----------TIMER START
  //!**** start of iteration loop ****
  for (int n =0; n < ntot; n++) {
  //!*********************************
    //time = n*dt;
    //space loop
    for (int i = 0; i < imax; i++) {
      for (int j = 0; j < jmax; j++) {
        //! velocity predictor
        //if (mode == 1) {
          un[i*jmax + j] = (u[i*jmax + j]*(1-beta)+alpha*v[i*jmax + j])/(1+beta);
          vn[i*jmax + j] = (v[i*jmax + j]*(1-beta)-alpha*u[i*jmax + j])/(1+beta);
        //}
        //else {
        //  un[i][j] = cos(alpha)*u[i][j]+sin(alpha)*v[i][j];
        //  vn[i][j] = cos(alpha)*v[i][j]-sin(alpha)*u[i][j];
        //}
        
        //! predictor of new location
        xn[i*jmax + j] = x[i*jmax + j] + dt*un[i*jmax + j]/1000;
        yn[i*jmax + j] = y[i*jmax + j] + dt*vn[i*jmax + j]/1000;
        
        //! updates for next time step 
        u[i*jmax + j] = un[i*jmax + j];
        v[i*jmax + j] = vn[i*jmax + j];
        x[i*jmax + j] = xn[i*jmax + j];
        y[i*jmax + j] = yn[i*jmax + j];
      }//for j         
    }//for i    
  }//for n 
  //<----------TIMER END   