//*******************************************
// This is the Scilab script for Exercise 7.
//
// Use the help facility for more information 
// on individual functions used.
//
// Author: J. Kaempf, 2008
//********************************************

clf(); set("figure_style","new"); a=get("current_axes");
a.parent.figure_size= [700,350]; xset('pixmap',1);

// read input data
info = read("header.txt",1,5); // read header information
dtout = info(1); dx = info(2); nx = info(3); nz = info(4); hmax = info(5);
h0in=read("h0.dat",-1,nx); hin=read("h.dat",-1,nx); uin=read("u.dat",-1,nx); 

[ntot nx] = size(hin); ntot = floor(ntot/nz); // total number of frames
x = (0:dx:(nx-1)*dx); // location vector 
h0 = h0in; htot = h0; // bathymetry
time = 0.0; // time counter

for n=1:ntot // animation loop

scf(0); clf(); xset('pixmap',1);
time = time + dtout; // time in seconds

for i = 1:nz // convert data to individual matrices
  ii = nz*(n-1)+i;
  u(i,1:nx) = uin(ii,1:nx); // horizontal velocity
  h(i,1:nx) = hin(ii,1:nx); // layer thickness
end;

xset('wwpc'); 

htot(1:nx) = 0.0; // calculate interface depths
for ii = 1:nz
  i = nz-ii+1; 
  htot(1:nx) = htot(1:nx)+h(i,1:nx);
  ic = i; if ic > 7; ic = ic-7; end; // line colours
  xset("thickness",2); xset("font size",4); 
  plot2d(x,htot-h0,ic) // draw interface depths
  xset("thickness",1);
end;

xset("thickness",2); xset("font size",4); // draw bathymetry
plot2d(x,-h0,1,'111','',[0 -100 (nx-1)*dx 20],[1 6 1 7])
xset("thickness",1)

xstring(400, -95,"Distance (m)");  // x label
xstring(-100, 3,"z (m)");  // y label
xstring(650, 7,"Time = "+string(int(time/3600))+" hours"); //title

// produce GIF files of each frame (optional)
// if n < 10 then
//  xs2gif(0,'ex7b100'+string(n)+'.gif')
// else
//  if n < 100 then
//    xs2gif(0,'ex7b10'+string(n)+'.gif')
//  else
//   xs2gif(0,'ex7b1'+string(n)+'.gif')
//  end
// end

xset('wshow'); xpause(2d4);

end // end of animation

