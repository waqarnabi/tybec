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
! Copyright 199-2007, Bjorn B. Stevens, Dep't Atmos and Ocean Sci, UCLA
!----------------------------------------------------------------------------
!
module step

  implicit none

  integer :: istpfl = 1
  real    :: timmax = 18000.
  logical :: corflg = .false.
  logical :: rylflg = .true.

  real    :: frqhis =  9000.
  real    :: frqanl =  3600.
  real    :: radfrq =  0.

  real    :: time   =  0.
  real    :: strtim =  0.0
  real    :: cntlat =  31.5 ! 30.0
  logical :: outflg = .true.

contains
  ! 
  ! ----------------------------------------------------------------------
  ! Subroutine model:  This is the main driver for the model's time
  ! integration.  It calls the routine tstep, which steps through the
  ! physical processes active on a time-step and updates variables.  It
  ! then checks to see whether or not different output options are
  ! satisfied.
  ! 
  subroutine stepper

    use mpi_interface, only : myid, double_scalar_par_max

    use grid, only : dtl, zt, zm, nzp, dn0, u0, v0, a_up, a_vp, a_wp, &
         a_uc, a_vc, a_wc, write_hist, write_anal, close_anal, dtlt,  &
         dtlv, dtlong, nzp, nyp, nxp, level
         
    use stat, only : sflg, savg_intvl, ssam_intvl, write_ps, close_stat
    use thrm, only : thermo

    logical, parameter :: StopOnCFLViolation = .False.
    real, parameter :: cfl_upper = 0.50, cfl_lower = 0.30

    real    :: t1,t2,tplsdt,begtime,cflmax,gcflmax
    integer :: istp, iret
    logical :: cflflg
    !
    ! Timestep loop for program
    !
    begtime = time
    istp = 0

    do while (time + 0.1*dtl < timmax)

       call cpu_time(t1)           !t1=timing()

       istp = istp+1
       tplsdt = time + dtl + 0.1*dtl
       sflg = (min(mod(tplsdt,ssam_intvl),mod(tplsdt,savg_intvl)) < dtl  &
            .or. tplsdt >= timmax  .or. tplsdt < 2.*dtl) 

       call t_step(cflflg,cflmax)

       time  = time + dtl

       call double_scalar_par_max(cflmax,gcflmax)
       cflmax = gcflmax

       if (cflmax > cfl_upper .or. cflmax < cfl_lower) then
          call tstep_reset(nzp,nxp,nyp,a_up,a_vp,a_wp,a_uc,a_vc,a_wc,     &
               dtl,dtlong,cflmax,cfl_upper,cfl_lower)
          dtlv=2.*dtl
          dtlt=dtl
       end if

       !
       ! output control
       !
       if (mod(tplsdt,savg_intvl)<dtl .or. time>=timmax .or. time==dtl)   &
       call write_ps(nzp,dn0,u0,v0,zm,zt,time)

       if ((mod(tplsdt,frqhis) < dtl .or. time >= timmax) .and. outflg)   &
            call write_hist(2, time)
       if (mod(tplsdt,savg_intvl)<dtl .or. time>=timmax .or. time==dtl)   &
            call write_hist(1, time)

       if ((mod(tplsdt,frqanl) < dtl .or. time >= timmax) .and. outflg) then
          call thermo(level)
          call write_anal(time)
       end if

       if (cflflg) then
          cflflg=.False. 
          if (StopOnCFLViolation) call write_hist(-1,time)
       end if

       if(myid == 0) then
          call cpu_time(t2)           !t1=timing()
          if (mod(istp,istpfl) == 0 ) print "('   Timestep # ',i5," //     &
              "'   Model time(sec)=',f10.2,3x,'CPU time(sec)=',f8.3)",     &
              istp, time, t2-t1
       endif

    enddo

    call write_hist(1, time)
    iret = close_anal()
    iret = close_stat()

  end subroutine stepper
  ! 
  !----------------------------------------------------------------------
  ! subroutine tstep_reset: Called to adjust current velocity and reset 
  ! timestep based on cfl limits
  !
  subroutine tstep_reset(n1,n2,n3,up,vp,wp,uc,vc,wc,dtl,dtmx,cfl,c1,c2)

  integer, intent (in) :: n1,n2,n3
  real, intent (in)    :: up(n1,n2,n3),vp(n1,n2,n3),wp(n1,n2,n3),dtmx,cfl,c1,c2
  real, intent (inout) :: uc(n1,n2,n3),vc(n1,n2,n3),wc(n1,n2,n3),dtl
  
  integer :: i,j,k
  real    :: cbar, dtl_old

  cbar = (c1+c2)*0.5
  dtl_old = dtl

  if (cfl > c1) dtl = min(dtmx,dtl*cbar/c1)
  if (cfl < c2) dtl = min(dtmx,dtl*cbar/c2)

  do j=1,n3
     do i=1,n2
        do k=1,n1
           uc(k,i,j) = up(k,i,j) + (uc(k,i,j)-up(k,i,j))*dtl/dtl_old
           vc(k,i,j) = vp(k,i,j) + (vc(k,i,j)-vp(k,i,j))*dtl/dtl_old
           wc(k,i,j) = wp(k,i,j) + (wc(k,i,j)-wp(k,i,j))*dtl/dtl_old
        end do
     end do
  end do

end subroutine tstep_reset

  ! 
  !----------------------------------------------------------------------
  ! subroutine t_step: Called by driver to timestep through the LES
  ! routines.  Within many subroutines, data is accumulated during
  ! the course of a timestep for the purposes of statistical analysis.
  ! 
  subroutine t_step(cflflg,cflmax)

    use grid, only : level, dtl
    use stat, only : sflg, statistics
    use sgsm, only : diffuse
    use srfc, only : surface,sst
    use thrm, only : thermo
    use mcrp, only : micro
    use prss, only : poisson
    use advf, only : fadvect
    use advl, only : ladvect
    use forc, only : forcings

    logical, intent (out) :: cflflg
    real, intent (out)    :: cflmax

    real :: xtime

    xtime = time/86400. + strtim
    cflflg = .false.

    call tend0

    call surface

    call diffuse

    call fadvect

    call sponge(0) 

    if (level >= 1) then
       call thermo(level)

       call forcings(xtime,cntlat,sst)

       call micro(level)
    end if

    call update_sclrs

    call thermo(level)

    call corlos 

    call ladvect

    call buoyancy

    call sponge(1)

    call poisson 

    call cfl (cflflg, cflmax)

    if (sflg) then 
       call thermo (level)
       call statistics (time+dtl)
    end if

  end subroutine t_step
  ! 
  !----------------------------------------------------------------------
  ! subroutine tend0: sets all tendency arrays to zero
  ! 
  subroutine tend0

    use grid, only : a_ut, a_vt, a_wt, nscl, a_st, nxyzp, newsclr
    use util, only : azero

    integer :: n

    call azero(nxyzp,a_ut,a2=a_vt,a3=a_wt)
    do n=1,nscl
       call newsclr(n)
       call azero(nxyzp,a_st)
    end do

  end subroutine tend0
  ! 
  !----------------------------------------------------------------------
  ! Subroutine cfl: Driver for calling CFL computation subroutine
  ! 
  subroutine cfl(cflflg,cflmax)

    use grid, only : a_up,a_vp,a_wp,nxp,nyp,nzp,dxi,dyi,dzt,dtlt
    use stat, only : fill_scalar

    logical, intent(out) :: cflflg
    real, intent (out)   :: cflmax
    real, parameter :: cflnum=0.95

    cflmax =  cfll(nzp,nxp,nyp,a_up,a_vp,a_wp,dxi,dyi,dzt,dtlt)

    cflflg = (cflmax > cflnum)
    if (cflflg) print *, 'Warning CFL Violation :', cflmax
    call fill_scalar(1,cflmax)

  end subroutine cfl
  ! 
  !----------------------------------------------------------------------
  ! Subroutine cfll: Checks CFL criteria, brings down the model if the
  ! maximum thershold is exceeded
  ! 
  real function cfll(n1,n2,n3,u,v,w,dxi,dyi,dzt,dtlt)

    integer, intent (in) :: n1, n2, n3
    real, dimension (n1,n2,n3), intent (in) :: u, v, w
    real, intent (in)    :: dxi,dyi,dzt(n1),dtlt

    integer :: i, j, k
    cfll=0.
    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             cfll=max(cfll, dtlt*2.* max(abs(u(k,i,j)*dxi),             &
                  abs(v(k,i,j)*dyi), abs(w(k,i,j)*dzt(k))))
          end do
       end do
    end do

  end function cfll
  ! 
  !----------------------------------------------------------------------
  ! subroutine update_sclrs:  Updates scalars by applying tendency and 
  ! boundary conditions
  ! 
  subroutine update_sclrs

    use grid, only : a_sp, a_st, a_qp, nscl, nxyzp, nxp, nyp, nzp, dzt, &
         dtlt, newsclr, isgstyp
    use sgsm, only : tkeinit
    use util, only : sclrset

    integer :: n

    do n=1,nscl
       call newsclr(n)
       call update(nzp,nxp,nyp,a_sp,a_st,dtlt)
       call sclrset('mixd',nzp,nxp,nyp,a_sp,dzt)
    end do

    if (isgstyp == 2) then
       call tkeinit(nxyzp,a_qp)
    end if

  end subroutine update_sclrs
  ! 
  ! ----------------------------------------------------------------------
  ! subroutine update:
  !
  subroutine update(n1,n2,n3,a,fa,dt)

    integer, intent(in)   :: n1, n2, n3
    real, intent (in)     :: fa(n1,n2,n3),dt
    real, intent (in out) :: a(n1,n2,n3)
    integer :: i, j, k

    do j=3,n3-2
       do i=3,n2-2
          do k=2,n1-1
             a(k,i,j) = a(k,i,j) + fa(k,i,j)*dt
          end do
       end do
    end do

  end subroutine update
  ! 
  ! ----------------------------------------------------------------------
  ! subroutine buoyancy:
  !
  subroutine buoyancy

    use grid, only : a_uc, a_vc, a_wc, a_wt, a_rv, a_theta, a_scr1, a_scr3, &
         a_rp, nxp, nyp, nzp, dzm, th00, level, pi1
    use stat, only : sflg, comp_tke
    use util, only : ae1mm
    use thrm, only : update_pi1

    real, dimension (nzp) :: awtbar

    call boyanc(nzp,nxp,nyp,level,a_wt,a_theta,a_rp,a_rv,th00,a_scr1)
    call ae1mm(nzp,nxp,nyp,a_wt,awtbar)
    call update_pi1(nzp,awtbar,pi1)

    if (sflg)  call comp_tke(nzp,nxp,nyp,dzm,th00,a_uc,a_vc,a_wc,a_scr1,a_scr3)

  end subroutine buoyancy
  ! 
  ! ----------------------------------------------------------------------
  ! subroutine boyanc:
  !
  subroutine boyanc(n1,n2,n3,level,wt,th,rt,rv,th00,scr)

    use defs, only: g, ep2

    integer, intent(in) :: n1,n2,n3,level
    real, intent(in)    :: th00,th(n1,n2,n3),rt(n1,n2,n3),rv(n1,n2,n3)
    real, intent(inout) :: wt(n1,n2,n3)
    real, intent(out)   :: scr(n1,n2,n3)

    integer :: k, i, j
    real :: gover2

    gover2  = 0.5*g
 
    do j=3,n3-2
       do i=3,n2-2
          if (level >= 2) then
             do k=1,n1
                scr(k,i,j)=gover2*((th(k,i,j)*(1.+ep2*rv(k,i,j))-th00)       &
                     /th00-(rt(k,i,j)-rv(k,i,j)))
             end do
          else
             do k=1,n1
                scr(k,i,j)=gover2*(th(k,i,j)/th00-1.)
             end do
          end if
          
          do k=2,n1-2
             wt(k,i,j)=wt(k,i,j)+scr(k,i,j)+scr(k+1,i,j)
          end do
       end do
    end do

  end subroutine boyanc
  ! 
  ! ----------------------------------------------------------------------
  ! subroutine corlos:  This is the coriolis driver, its purpose is to
  ! from the coriolis accelerations for u and v and add them into the 
  ! accumulated tendency arrays of ut and vt.
  ! 
  subroutine corlos

    use defs, only : omega
    use grid, only : a_uc, a_vc, a_ut, a_vt, nxp, nyp, nzp, u0, v0

    logical, save :: initialized = .False.
    real, save    :: fcor

    integer :: i, j, k

    if (corflg) then
       if (.not.initialized) fcor=2.*omega*sin(cntlat*0.01745329)
       do j=3,nyp-2
          do i=3,nxp-2
             do k=2,nzp
                a_ut(k,i,j)=a_ut(k,i,j) - fcor*(v0(k)-0.25*                   &
                     (a_vc(k,i,j)+a_vc(k,i+1,j)+a_vc(k,i,j-1)+a_vc(k,i+1,j-1)))
                a_vt(k,i,j)=a_vt(k,i,j) + fcor*(u0(k)-0.25*                   &
                     (a_uc(k,i,j)+a_uc(k,i-1,j)+a_uc(k,i,j+1)+a_uc(k,i-1,j+1)))
             end do
          end do
       end do
       initialized = .True.
    end if

  end subroutine corlos
! 
! ----------------------------------------------------------------------
! subroutine sponge: does the rayleigh friction for the momentum terms, 
! and newtonian damping of thermal term the damping is accumulated with the
! other tendencies 
! 
  subroutine sponge (isponge)

    use grid, only : u0, v0, a_up, a_vp, a_wp, a_tp, a_ut, a_vt, a_wt, a_tt,&
         nfpt, spng_tfct, spng_wfct, nzp, nxp, nyp, th0, th00

    integer, intent (in) :: isponge

    integer :: i, j, k, kk

    if (maxval(spng_tfct) > epsilon(1.) .and. nfpt > 1) then
       do j=3,nyp-2
          do i=3,nxp-2
             do k=nzp-nfpt,nzp-1
                kk = k+1-(nzp-nfpt)
                if (isponge == 0) then
                   a_tt(k,i,j)=a_tt(k,i,j) - spng_tfct(kk)*                   &
                        (a_tp(k,i,j)-th0(k)+th00)
                else
                   a_ut(k,i,j)=a_ut(k,i,j) - spng_tfct(kk)*(a_up(k,i,j)-u0(k))
                   a_vt(k,i,j)=a_vt(k,i,j) - spng_tfct(kk)*(a_vp(k,i,j)-v0(k))
                   a_wt(k,i,j)=a_wt(k,i,j) - spng_wfct(kk)*(a_wp(k,i,j))
                end if
             end do
          end do
       end do
    end if

  end subroutine sponge

end module step
