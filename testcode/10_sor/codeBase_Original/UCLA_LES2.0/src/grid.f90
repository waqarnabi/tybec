!----------------------------------------------------------------------------
! This file is part of UCLALES.
!
! UCLALES is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! UCLALES is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
! Copyright 1999, 2001, Bjorn B. Stevens, Dep't Atmos and Ocean Sci, UCLA
!----------------------------------------------------------------------------
!
module grid

  use ncio, only : open_nc, define_nc
  implicit none
  !
  integer           :: nxp = 132           ! number of x points
  integer           :: nyp = 132           ! number of y points
  integer           :: nzp = 105           ! number of z points

  logical           :: nxpart = .true.     ! number of processors in x

  real              :: deltax = 35.        ! dx for basic grid
  real              :: deltay = 35.        ! dy for basic grid
  real              :: deltaz = 17.5       ! dz for basic grid
  real              :: dzrat  = 1.02       ! grid stretching ratio
  real              :: dzmax  = 1200.      ! height to start grid-stretching
  real              :: dtlong = 10.0       ! long timestep
  real              :: th00   = 288.       ! basic state temperature

  real              :: CCN = 150.e6

  integer           :: igrdtyp = 1         ! vertical grid type
  integer           :: isgstyp = 1         ! sgs model type
  integer           :: iradtyp = 0         ! radiation model type
  integer           :: level   = 0         ! thermodynamic level
  integer           :: naddsc  = 0         ! number of additional scalars

  integer           :: nfpt = 10           ! number of rayleigh friction points
  real              :: distim = 300.0      ! dissipation timescale

  character (len=7), allocatable, save :: sanal(:)
  character (len=80):: expnme = 'Default' ! Experiment name
  character (len=80):: filprf = 'x'       ! File Prefix
  character (len=7) :: runtype = 'INITIAL'! Run Type Selection


  character (len=7),  private :: v_snm='sxx    ' 
  character (len=80), private :: fname

  integer, private, save  ::  nrec0, nvar0, nbase=15

  integer           :: nz, nxyzp, nxyp
  real              :: dxi, dyi, dtl, dtlv, dtlt, umean, vmean, psrf
  real, allocatable :: xt(:), xm(:), yt(:), ym(:), zt(:), zm(:), dzt(:), dzm(:)
  real, allocatable :: u0(:), v0(:), pi0(:), pi1(:), th0(:), dn0(:), rt0(:)
  real, allocatable :: spng_wfct(:), spng_tfct(:)
  !
  ! velocity variables (past, current and tendency)
  !
  real, allocatable, target :: a_up(:,:,:),a_uc(:,:,:),a_ut(:,:,:)
  real, allocatable, target :: a_vp(:,:,:),a_vc(:,:,:),a_vt(:,:,:)
  real, allocatable, target :: a_wp(:,:,:),a_wc(:,:,:),a_wt(:,:,:)
  !
  ! wsave variables used in fft in x and y directons
  !
  real, allocatable :: wsavex(:), wsavey(:)
  !
  ! prognostic scalar variables
  !
  real, pointer :: a_tp(:,:,:),a_tt(:,:,:)
  real, pointer :: a_rp(:,:,:),a_rt(:,:,:)
  real, pointer :: a_rpp(:,:,:),a_rpt(:,:,:)
  real, pointer :: a_npp(:,:,:),a_npt(:,:,:)
  real, pointer :: a_qp(:,:,:),a_qt(:,:,:)
  real, pointer :: a_sp(:,:,:),a_st(:,:,:)
  real, allocatable, target :: a_sclrp(:,:,:,:),a_sclrt(:,:,:,:)
  !
  ! 3d diagnostic quantities
  !
  real, allocatable, target :: a_theta(:,:,:)  ! dry potential temp (k)
  real, allocatable :: a_pexnr(:,:,:)  ! perturbation exner func
  real, allocatable :: a_press(:,:,:)  ! pressure (hpa)
  real, allocatable :: a_rc(:,:,:)     ! cloud water
  real, allocatable :: a_rv(:,:,:)     ! water vapor
  !
  ! scratch arrays
  !
  real, allocatable, dimension (:,:,:) :: a_rflx, a_sflx, a_scr1, a_scr2, &
       a_scr3, a_scr4, a_scr5, a_scr6
  !
  !
  real, allocatable :: a_ustar(:,:)
  real, allocatable :: a_tstar(:,:)
  real, allocatable :: a_rstar(:,:)
  real, allocatable :: uw_sfc(:,:)
  real, allocatable :: vw_sfc(:,:)
  real, allocatable :: ww_sfc(:,:)
  real, allocatable :: wt_sfc(:,:)
  real, allocatable :: wq_sfc(:,:)
  real, allocatable :: precip(:,:,:), albedo(:,:)

  !
  integer :: nscl = 1
  integer, save :: ncid0,ncid_s
  !
contains
  !
  !----------------------------------------------------------------------
  !
  subroutine define_vars

    use mpi_interface, only :myid

    integer :: memsize

    allocate (u0(nzp),v0(nzp),pi0(nzp),pi1(nzp),th0(nzp),dn0(nzp),rt0(nzp))

    memsize = 2*nxyzp ! complex array in pressure solver

    allocate (a_up(nzp,nxp,nyp),a_vp(nzp,nxp,nyp),a_wp(nzp,nxp,nyp))
    a_up(:,:,:) = 0.
    a_vp(:,:,:) = 0.
    a_wp(:,:,:) = 0.

    allocate (a_uc(nzp,nxp,nyp),a_vc(nzp,nxp,nyp),a_wc(nzp,nxp,nyp))
    a_uc(:,:,:) = 0.
    a_vc(:,:,:) = 0.
    a_wc(:,:,:) = 0.

    allocate (a_ut(nzp,nxp,nyp),a_vt(nzp,nxp,nyp),a_wt(nzp,nxp,nyp))
    a_ut(:,:,:) = 0.
    a_vt(:,:,:) = 0.
    a_wt(:,:,:) = 0.

    allocate (a_theta(nzp,nxp,nyp),a_pexnr(nzp,nxp,nyp),a_press(nzp,nxp,nyp))
    a_theta(:,:,:) = 0.
    a_pexnr(:,:,:) = 0.
    a_press(:,:,:) = 0.

    memsize = memsize + nxyzp*13 !

    if (level >= 0) then
       allocate (a_rv(nzp,nxp,nyp))
       a_rv(:,:,:) = 0.
       memsize = memsize + nxyzp
       if (level > 1) then
          allocate (a_rc(nzp,nxp,nyp))
          a_rc(:,:,:) = 0.
          memsize = memsize + nxyzp
       end if
    end if

    if (iradtyp > 0 ) then
       allocate (a_rflx(nzp,nxp,nyp))
       a_rflx(:,:,:) = 0.
       memsize = memsize + nxyzp
    end if
    if (iradtyp >= 3) then
       allocate (a_sflx(nzp,nxp,nyp),albedo(nxp,nyp))
       a_sflx(:,:,:) = 0.
       albedo(:,:) = 0.
       memsize = memsize + nxyzp + nxyp
    end if

    allocate (a_scr1(nzp,nxp,nyp),a_scr2(nzp,nxp,nyp),a_scr3(nzp,nxp,nyp))
    allocate (a_scr4(nzp,nxp,nyp),a_scr5(nzp,nxp,nyp),a_scr6(nzp,nxp,nyp))
    a_scr1(:,:,:) = 0.
    a_scr2(:,:,:) = 0.
    a_scr3(:,:,:) = 0.
    a_scr4(:,:,:) = 0.
    a_scr5(:,:,:) = 0.
    a_scr6(:,:,:) = 0.
    memsize = memsize + 6.*nxyzp

    nscl = nscl+naddsc
    if (level   > 0) nscl = nscl+1
    if (level   > 2) nscl = nscl+2
    if (isgstyp > 1) nscl = nscl+1      
    allocate (a_sclrp(nzp,nxp,nyp,nscl), a_sclrt(nzp,nxp,nyp,nscl))
    a_sclrp(:,:,:,:) = 0.
    a_sclrt(:,:,:,:) = 0.

    a_tp=>a_sclrp(:,:,:,1)
    a_tt=>a_sclrt(:,:,:,1)
    if (level >= 0) then
       a_rp=>a_sclrp(:,:,:,2)
       a_rt=>a_sclrt(:,:,:,2)
    end if
    if (level >= 3) then
      a_rpp=>a_sclrp(:,:,:,3)
      a_rpt=>a_sclrt(:,:,:,3)
      a_npp=>a_sclrp(:,:,:,4)
      a_npt=>a_sclrt(:,:,:,4)
    end if
    if (isgstyp > 1) then
       a_qp=>a_sclrp(:,:,:,nscl - naddsc)
       a_qt=>a_sclrt(:,:,:,nscl - naddsc)
    end if

    allocate (a_ustar(nxp,nyp),a_tstar(nxp,nyp),a_rstar(nxp,nyp))
    allocate (uw_sfc(nxp,nyp),vw_sfc(nxp,nyp),ww_sfc(nxp,nyp))
    allocate (wt_sfc(nxp,nyp),wq_sfc(nxp,nyp))

    if (level >= 3) then
       allocate(precip(nzp,nxp,nyp))
       memsize = memsize + nxyzp
    end if

    a_ustar(:,:) = 0.
    a_tstar(:,:) = 0.
    a_rstar(:,:) = 0.
    uw_sfc(:,:)  = 0.
    vw_sfc(:,:)  = 0.
    ww_sfc(:,:)  = 0.
    wt_sfc(:,:) = 0.
    wq_sfc(:,:) = 0.

    umean = 0.
    vmean = 0. 

    memsize = memsize +  nxyzp*nscl*2 + 3*nxyp + nxyp*10

    if(myid == 0) then
       print "(//' ',49('-')/,' ',/3x,i3.3,' prognostic scalars')", nscl
       print "('   memory to be allocated  -  ',f8.3,' mbytes')", &
            memsize*1.e-6*kind(0.0)
    end if

  end subroutine define_vars
  !
  !----------------------------------------------------------------------
  !
  subroutine define_grid

    use mpi_interface, only: xoffset, yoffset, wrxid, wryid, nxpg, nypg,   &
         appl_abort, myid

    integer :: i,j,k,kmax,nchby
    real    :: dzrfm,dz,zb,dzmin
    real    :: zmnvc(-1:nzp+1)
    character (len=51) :: &
         fm1 = '(//" ",49("-")/,"   grid dimensions:"/)            ',      &
         fm2 = '("   nxp-4 = ",i3,", dx, dx = ",f8.1,",",f8.1," m")',      &
         fm3 = '("   nyp-4 = ",i3,", dy, dy = ",f8.1,",",f8.1," m")',      &
         fm4 = '("   nzp   = ",i3,", dz, dz = ",f8.1,",",f8.1," m")',      &
         fm5 = '("   timestep: ",f7.3,"s ")                        ',      &
         fm6 = '("   thermo level: ",i3)                        '

    nxyzp  = nxp*nyp*nzp
    nxyp   = nxp*nyp

    nz= nzp-1

    dxi=1./deltax
    dyi=1./deltay
    allocate(wsavex(4*nxpg+100),wsavey(4*nypg+100))
    wsavex=0.0
    wsavey=0.0

    !
    ! define xm array for grid 1 from deltax
    !                                      
    allocate (xm(nxp))
    xm(1)=-float(max(nxpg-2,1))*.5*deltax+xoffset(wrxid)*deltax
    do i=2,nxp-1
       xm(i)=xm(i-1)+deltax
    end do
    xm(nxp)=2*xm(nxp-1)-xm(nxp-2)
    !    
    ! define ym array for grid 1 from deltay
    !
    allocate (ym(nyp))
    ym(1)=-float(max(nypg-2,1))*.5*deltay+yoffset(wryid)*deltay
    do j=2,nyp-1
       ym(j)=ym(j-1)+deltay
    end do
    ym(nyp)=2*ym(nyp-1)-ym(nyp-2)

    !      
    !      define where the momentum points will lie in vertical
    !      
  allocate (zm(nzp))
  select case (abs(igrdtyp))
     !
     ! Read in grid spacings from a file
     !     
  case(3)
     open (1,file='zm_grid_in',status='old',form='formatted')
     do k=1,nzp
        read (1,*) zm(k)
     end do
     close (1)
     if (zm(1) /= 0.) then
       if (myid == 0) print *, 'ABORTING:  Error in input grid'
       call appl_abort(0)
    end if
     !
     ! Tschebyschev Grid with vertical size given by dzmax
     !
  case(2) 
     zm(1) = 0.
     nchby = nzp-3
     do k=1,nzp-1
        zm(k+1) = cos( ((2.*nchby - 1. - 2.*(k-1))*2.*asin(1.))/(2.*nchby))
        zm(k+1) = (zm(k+1)+1.)*dzmax/2.
     end do
     zm(nzp-1) = dzmax
     zm(nzp)   = dzmax + zm(2)*zm(2)/(zm(3)-zm(2))
     !    
     ! define zm array for grid 1 from deltaz and dzrat, if dzrat is
     ! negative compress grid so that dzmin is the grid spacing in a 100m
     ! interval below dzmax.  In both cases stretcvh grid uniformly by the 
     ! ration |dzrat| above dzmax
     !
  case(1)
     zm(1)=0.
     zm(2)=deltaz
     zb=dzmax+100.
     if (dzrat.lt.0.) then
        dzmin = -float(int(dzrat))
        dzrat =  dzrat+dzmin-1
        kmax = int(log(deltaz/dzmin)/log(abs(dzrat)))
        zb=dzmax-100.
        do k=1,kmax
           zb=zb-dzmin*abs(dzrat)**k
        end do
     end if
     
     dz=deltaz
     do k=3,nzp
        if(zm(k-1) > zb .and. zm(k-1) < dzmax)then
           dz=max(dzmin,dz/abs(dzrat))
        else if (zm(k-1) >= dzmax) then
           dz=dz*abs(dzrat)
        end if
        zm(k)=zm(k-1)+dz
     end do
  case default
     zm(1)=0.
     do k=1,nzp
        zm(k)=zm(k-1)+deltaz
     end do
  end select
  !
  ! Grid Points for Thermal Points (T-Grid): 
  !    
  allocate (xt(nxp))
  do i=2,nxp
     xt(i)=.5*(xm(i)+xm(i-1))
  end do
  xt(1)=1.5*xm(1)-.5*xm(2)
  !    
  allocate (yt(nyp))
  do j=2,nyp
     yt(j)=.5*(ym(j)+ym(j-1))
  end do
  yt(1)=1.5*ym(1)-.5*ym(2)
  !      
  allocate (zt(nzp))
  if (igrdtyp .lt. 0) then
     !
     ! Read in grid spacings from a file
     !     
     open (2,file='zt_grid_in',status='old',form='formatted')
     do k=1,nzp
        read (2,*) zt(k)
     end do
     close (2)
   else
     !
     ! calculate where the thermo points will lie based on geometric
     ! interpolation from the momentum points 
     !    
     do k=1,nzp
        zmnvc(k)=zm(k)
     end do
     zmnvc(0)=-(zmnvc(2)-zmnvc(1))**2 /(zmnvc(3)-zmnvc(2))
     zmnvc(-1)=zmnvc(0)-(zmnvc(1)-zmnvc(0))**2 /(zmnvc(2)-zmnvc(1))
     zmnvc(nzp+1)=zmnvc(nzp)+(zmnvc(nzp)-zmnvc(nzp-1))**2              &
                  /(zmnvc(nzp-1)-zmnvc(nzp-2))

     do k=1,nzp
       dzrfm=sqrt(sqrt((zmnvc(k+1)-zmnvc(k)) /(zmnvc(k-1)-zmnvc(k-2))))
       zt(k)=zmnvc(k-1)+(zmnvc(k)-zmnvc(k-1))/(1.+dzrfm)
     end do
  end if
  !    
  ! compute other arrays based on the vertical grid.
  !   dzm: inverse of distance between thermal points k+1 and k
  !   dzt: inverse of distance between momentum points k and k-1
  !
  allocate (dzm(nzp))
  do k=1,nzp-1
     dzm(k)=1./(zt(k+1)-zt(k))
  end do
  dzm(nzp)=dzm(nzp-1)*dzm(nzp-1)/dzm(nzp-2)
  
  allocate (dzt(nzp))
  do k=2,nzp
     dzt(k)=1./(zm(k)-zm(k-1))
  end do
  dzt(1)=dzt(2)*dzt(2)/dzt(3)
  !
  ! set timesteps
  !
  dtl=dtlong
  dtlv=2.*dtl
  dtlt=dtl
  !
  if(myid == 0) then
     write(6,fm1)
     write(6,fm2) nxpg-4, deltax, 2.*xt(nxp-2)
     write(6,fm3) nypg-4, deltay, 2.*yt(nyp-2)

     write(6,fm4) nzp,zm(2)-zm(1),zm(nzp)
     write(6,fm5) dtl
     write(6,fm6) level
  endif

  end subroutine define_grid
  !
  ! ----------------------------------------------------------------------
  ! subroutine init_anal:  Defines the netcdf Analysis file
  !
  subroutine init_anal(time)

    use mpi_interface, only :myid

    integer, parameter :: nnames = 21
    character (len=7), save :: sbase(nnames) =  (/ &
         'time   ','zt     ','zm     ','xt     ','xm     ','yt     '   ,&
         'ym     ','u0     ','v0     ','dn0    ','u      ','v      '   ,&  
         'w      ','t      ','p      ','q      ','l      ','r      '   ,&
         'n      ','stke   ','rflx   '/)

    real, intent (in) :: time
    integer           :: nbeg, nend

    nvar0 = nbase + naddsc    
    if (level  >= 1) nvar0 = nvar0+1
    if (level  >= 2) nvar0 = nvar0+1
    if (level  >= 3) nvar0 = nvar0+2
    if (isgstyp > 1) nvar0 = nvar0+1
    if (iradtyp > 1) nvar0 = nvar0+1

    allocate (sanal(nvar0))
    sanal(1:nbase) = sbase(1:nbase)

    nvar0 = nbase
    !
    ! add liquid water, which is a diagnostic variable, first
    !
    if (level >= 2) then
       nvar0 = nvar0+1
       sanal(nvar0) = sbase(nbase+2)
    end if
    !
    ! add additional scalars, in the order in which they appear in scalar
    ! table
    !
    if (level >= 1) then
       nvar0 = nvar0+1
       sanal(nvar0) = sbase(nbase+1)
    end if

    if (level >= 3) then
       nvar0 = nvar0+1
       sanal(nvar0) = sbase(nbase+3)
       nvar0 = nvar0+1
       sanal(nvar0) = sbase(nbase+4)
    end if

    if (isgstyp > 1) then
       nvar0 = nvar0+1
       sanal(nvar0) = sbase(nbase+5)
    end if

    if (iradtyp > 2) then
       nvar0 = nvar0+1
       sanal(nvar0) = sbase(nbase+6)
    end if

    nbeg = nvar0+1
    nend = nvar0+naddsc
    do nvar0 = nbeg, nend
       write(v_snm(2:3),'(i2.2)') nvar0-nbeg
       sanal(nvar0) = v_snm
    end do
    nvar0=nend

    fname =  trim(filprf)
    if(myid == 0) print                                                  &
            "(//' ',49('-')/,' ',/,'   Initializing: ',A20)",trim(fname)
    call open_nc( fname, expnme, time, (nxp-4)*(nyp-4), ncid0, nrec0)
    call define_nc( ncid0, nrec0, nvar0, sanal, n1=nzp, n2=nxp-4, n3=nyp-4)
    if (myid == 0) print *,'   ...starting record: ', nrec0

  end subroutine init_anal
  !
  ! ----------------------------------------------------------------------
  ! subroutine close_anal:  Closes netcdf anal file
  !
  integer function close_anal()

    use netcdf

    close_anal = nf90_close(ncid0)

  end function close_anal
  !
  ! ----------------------------------------------------------------------
  ! Subroutine Write_anal:  Writes the netcdf Analysis file
  !
  subroutine write_anal(time)

    use netcdf
    use mpi_interface, only : myid, appl_abort

    real, intent (in) :: time

    integer :: iret, VarID, nn, n
    integer :: ibeg(4), icnt(4), i1, i2, j1, j2

    return
    icnt = (/nzp,nxp-4,nyp-4,1   /)
    ibeg = (/1  ,1  ,1  ,nrec0/)
    i1 = 3
    i2 = nxp-2
    j1 = 3
    j2 = nyp-2

    iret = nf90_inq_Varid(ncid0, sanal(1), VarID)
    iret = nf90_put_var(ncid0, VarID, time, start=(/nrec0/))
    if (nrec0 == 1) then
       iret = nf90_inq_varid(ncid0, sanal(2), VarID)
       iret = nf90_put_var(ncid0, VarID, zt, start = (/nrec0/))
       iret = nf90_inq_varid(ncid0, sanal(3), VarID)
       iret = nf90_put_var(ncid0, VarID, zm, start = (/nrec0/))
       iret = nf90_inq_varid(ncid0, sanal(4), VarID)
       iret = nf90_put_var(ncid0, VarID, xt(i1:i2), start = (/nrec0/))
       iret = nf90_inq_varid(ncid0, sanal(5), VarID)
       iret = nf90_put_var(ncid0, VarID, xm(i1:i2), start = (/nrec0/))
       iret = nf90_inq_varid(ncid0, sanal(6), VarID)
       iret = nf90_put_var(ncid0, VarID, yt(j1:j2), start = (/nrec0/))
       iret = nf90_inq_varid(ncid0, sanal(7), VarID)
       iret = nf90_put_var(ncid0, VarID, ym(j1:j2), start = (/nrec0/))
       iret = nf90_inq_varid(ncid0, sanal(8), VarID)
       iret = nf90_put_var(ncid0, VarID, u0, start = (/nrec0/))
       iret = nf90_inq_varid(ncid0, sanal(9), VarID)
       iret = nf90_put_var(ncid0, VarID, v0, start = (/nrec0/))
       iret = nf90_inq_varid(ncid0, sanal(10), VarID)
       iret = nf90_put_var(ncid0, VarID, dn0, start = (/nrec0/))
    end if

    iret = nf90_inq_varid(ncid0, sanal(11), VarID)
    iret = nf90_put_var(ncid0, VarID, a_up(:,i1:i2,j1:j2), start=ibeg,    &
         count=icnt)
    iret = nf90_inq_varid(ncid0, sanal(12), VarID)
    iret = nf90_put_var(ncid0, VarID, a_vp(:,i1:i2,j1:j2), start=ibeg,    &
         count=icnt)
    iret = nf90_inq_varid(ncid0, sanal(13), VarID)
    iret = nf90_put_var(ncid0, VarID, a_wp(:,i1:i2,j1:j2), start=ibeg,    &
         count=icnt)
    iret = nf90_inq_varid(ncid0, sanal(14), VarID)
    iret = nf90_put_var(ncid0, VarID, a_theta(:,i1:i2,j1:j2), start=ibeg, &
         count=icnt)
    iret = nf90_inq_varid(ncid0, sanal(15), VarID)
    iret = nf90_put_var(ncid0, VarID, a_press(:,i1:i2,j1:j2), start=ibeg, &
         count=icnt)

    nn = nbase
    if (level >= 2)  then
       nn = nn+1
       iret = nf90_inq_varid(ncid0, 'l', VarID)
       iret = nf90_put_var(ncid0, VarID, a_rc(:,i1:i2,j1:j2), start=ibeg, &
            count=icnt)
    end if

    do n = 2, nscl
       nn = nn+1
       call newsclr(n)
       iret = nf90_inq_varid(ncid0, sanal(nn), VarID)
       iret = nf90_put_var(ncid0,VarID,a_sp(:,i1:i2,j1:j2), start=ibeg,   &
            count=icnt)
    end do

    if (isgstyp > 1)  then
       nn = nn+1
       iret = nf90_inq_varid(ncid0, 'stke', VarID)
       iret = nf90_put_var(ncid0, VarID, a_qp(:,i1:i2,j1:j2), start=ibeg, &
            count=icnt)
    end if

    if (iradtyp > 1)  then
       nn = nn+1
       iret = nf90_inq_varid(ncid0, 'rflx', VarID)
       iret = nf90_put_var(ncid0, VarID, a_rflx(:,i1:i2,j1:j2), start=ibeg, &
            count=icnt)
    end if

    if (nn /= nvar0) then
       if (myid == 0) print *, 'ABORTING:  Anal write error'
       call appl_abort(0)
    end if

    if (myid==0) print "(//' ',12('-'),'   Record ',I3,' to: ',A60)",    &
         nrec0,fname 

    iret  = nf90_sync(ncid0)
    nrec0 = nrec0+1

  end subroutine write_anal
  ! 
  ! ----------------------------------------------------------------------
  ! Subroutine write_hist:  This subroutine writes a binary history file 
  !
  subroutine write_hist(htype, time)

    use mpi_interface, only : appl_abort, myid, wrxid, wryid
    integer :: errcode=-17

    integer, intent (in) :: htype
    real, intent (in)    :: time

    character (len=80) :: hname

    integer :: n, iblank
    !
    ! create and open a new output file.
    !
    write(hname,'(i4.4,a1,i4.4)') wrxid,'_',wryid
    hname = trim(hname)//'.'//trim(filprf)

    select case(htype)
    case default
       hname = trim(hname)//'.iflg'
    case(0)
       hname = trim(hname)//'.R'
    case(1) 
       hname = trim(hname)//'.rst'
    case(2) 
       iblank=index(hname,' ')
       write (hname(iblank:iblank+7),'(a1,i6.6,a1)') '.', int(time), 's'
    end select
    !
    ! Write fields
    !
    if (myid == 0) print "(//' ',49('-')/,' ',/,'   History write to: ',A30)" &
         ,hname
    open(10,file=trim(hname), form='unformatted')

    write(10) time,th00,umean,vmean,dtl,level,isgstyp,iradtyp,nzp,nxp,nyp,nscl
    write(10) xt, xm, yt, ym, zt, zm, dn0, th0, u0, v0, pi0, pi1, rt0, psrf

    write(10) a_ustar, a_tstar, a_rstar

    write(10) a_pexnr
    write(10) a_press
    write(10) a_theta

    write(10) a_up
    write(10) a_vp
    write(10) a_wp
    write(10) a_uc
    write(10) a_vc
    write(10) a_wc

    do n=1,nscl
       call newsclr(n)
       write(10) a_sp
    end do

    if ( allocated(a_rv)   ) write(10) a_rv
    if ( allocated(a_rc)   ) write(10) a_rc
    if ( allocated(a_rflx) ) write(10) a_rflx
    close(10)

    if (myid == 0 .and. htype < 0) then
       print *, 'CFL Violation'
       call appl_abort(errcode)
    end if

    return
  end subroutine write_hist
  ! 
  ! ----------------------------------------------------------------------
  ! Subroutine read_hist:  This subroutine reads a binary history file 
  !
  subroutine read_hist(time, hfilin)

    use mpi_interface, only : appl_abort, myid, wrxid, wryid

    character(len=80), intent(in) :: hfilin
    real, intent(out)             :: time

    character (len=80) :: hname
    integer :: n, nxpx, nypx, nzpx, nsclx, iradx, isgsx, lvlx
    logical :: exans
    real :: umx, vmx, thx
    !
    ! open input file.
    !

    write(hname,'(i4.4,a1,i4.4)') wrxid,'_',wryid
    hname = trim(hname)//'.'//trim(hfilin)

    inquire(file=trim(hname),exist=exans)
    if (.not.exans) then
       print *,'ABORTING: History file', trim(hname),' not found'
       call appl_abort(0)
    else
       open (10,file=trim(hname),status='old',form='unformatted')
       read (10) time,thx,umx,vmx,dtl,lvlx,isgsx,iradx,nzpx,nxpx,nypx,nsclx

       if (nxpx /= nxp .or. nypx /= nyp .or. nzpx /= nzp)  then
          if (myid == 0) print *, nxp, nyp, nzp, nxpx, nypx, nzpx
          call appl_abort(-1)
       end if

       read (10) xt, xm, yt, ym, zt, zm, dn0, th0, u0, v0, pi0, pi1, rt0, psrf

       read (10) a_ustar, a_tstar, a_rstar

       read (10) a_pexnr
       read (10) a_press
       read (10) a_theta

       read (10) a_up
       read (10) a_vp
       read (10) a_wp
       read (10) a_uc
       read (10) a_vc
       read (10) a_wc

       do n=1,nscl
          call newsclr(n)
          if (n <= nsclx) read (10) a_sp
       end do
       do n=nscl+1,nsclx
          read (10)
       end do

       if (lvlx > 0) then
          if (level > 0) then
             read (10) a_rv
          else
             read (10)
          end if
       end if
       if (lvlx > 1) then
          if (level > 1) then
             read (10) a_rc
          else
             read (10)
          end if
       end if
       if (iradx > 0) then
          if (iradtyp > 0) then
             read (10) a_rflx
          else
             read (10)
          end if
       end if

       close(10)
       !
       ! adjust namelist and basic state appropriately
       !
       if (thx /= th00) then
          if (myid == 0) print "('  th00 changed  -  ',2f8.2)",th00,thx
          a_tp(:,:,:) = a_tp(:,:,:) + thx - th00
       end if
       if (umx /= umean) then
          if (myid == 0) print "('  umean changed  -  ',2f8.2)",umean,umx
          a_up = a_up + umx - umean
       end if
       if (vmx /= vmean) then
          if (myid == 0) print "('  vmean changed  -  ',2f8.2)",vmean,vmx
          a_vp = a_vp + vmx - vmean
       end if
       dtlv=2.*dtl
       dtlt=dtl

    end if

  end subroutine read_hist
  !
  ! ----------------------------------------------------------------------
  ! Subroutine newsclr:  This routine updates the scalar pointer to the
  ! value corresponding to the next scalar in the scalar table
  !
  subroutine newsclr(iscnum)

    integer, intent(in) :: iscnum

    a_sp=>a_sclrp(:,:,:,iscnum)
    a_st=>a_sclrt(:,:,:,iscnum)

    return
  end subroutine newsclr

end module grid

