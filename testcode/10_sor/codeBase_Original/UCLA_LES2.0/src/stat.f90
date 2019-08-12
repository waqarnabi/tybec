!----------------------------------------------------------------------------
! This file is part of UCLALES.
!
! UCLALES is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! UCLALES is distributsed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
! Copyright 1999-2007, Bjorn B. Stevens, Dep't Atmos and Ocean Sci, UCLA
!----------------------------------------------------------------------------
!
module stat

  use ncio, only : open_nc, define_nc
  use grid, only : level
  use util, only : get_avg, get_cor, get_avg3, get_cor3, get_var3, get_csum
  implicit none
  private

  integer, parameter :: nvar1 = 27, nvar2 = 92

  integer, save      :: nrec1, nrec2, ncid1, ncid2, nv1=nvar1, nv2=nvar2
  real, save         :: fsttm, lsttm, nsmp = 0

  logical            :: sflg = .false.
  real               :: ssam_intvl = 30.   ! statistical sampling interval
  real               :: savg_intvl = 1800. ! statistical averaging interval

  character (len=7), save :: s1(nvar1)=(/                           & 
       'time   ','cfl    ','maxdiv ','zi1_bar','zi2_bar','zi3_bar', & ! 1
       'vtke   ','sfcbflx','wmax   ','tsrf   ','ustar  ','shf_bar', & ! 7
       'lhf_bar','zi_bar ','lwp_bar','lwp_var','zc     ','zb     ', & !13
       'cfrac  ','lmax   ','albedo ','rwp_bar','prcp   ','pfrac  ', & !19
       'CCN    ','nrain  ','nrcnt  '/),                             &
       s2(nvar2)=(/                                                 &
       'time   ','zt     ','zm     ','dn0    ','u0     ','v0     ', & ! 1
       'fsttm  ','lsttm  ','nsmp   ','u      ','v      ','t      ', & ! 7
       'p      ','u_2    ','v_2    ','w_2    ','t_2    ','w_3    ', & !13
       't_3    ','tot_tw ','sfs_tw ','tot_uw ','sfs_uw ','tot_vw ', & !19
       'sfs_vw ','tot_ww ','sfs_ww ','km     ','kh     ','lmbd   ', & !25
       'lmbde  ','sfs_tke','sfs_boy','sfs_shr','boy_prd','shr_prd', & !31
       'trans  ','diss   ','dff_u  ','dff_v  ','dff_w  ','adv_u  ', & !37
       'adv_v  ','adv_w  ','prs_u  ','prs_v  ','prs_w  ','prd_uw ', & !43
       'storage','q      ','q_2    ','q_3    ','tot_qw ','sfs_qw ', & !49
       'rflx   ','rflx2  ','sflx   ','sflx2  ','l      ','l_2    ', & !55
       'l_3    ','tot_lw ','sed_lw ','cs1    ','cnt_cs1','w_cs1  ', & !61
       'tl_cs1 ','tv_cs1 ','rt_cs1 ','rl_cs1 ','wt_cs1 ','wv_cs1 ', & !67
       'wr_cs1 ','cs2    ','cnt_cs2','w_cs2  ','tl_cs2 ','tv_cs2 ', & !73
       'rt_cs2 ','rl_cs2 ','wt_cs2 ','wv_cs2 ','wr_cs2 ','Nc     ', & !79  
       'Nr     ','rr     ','precip ','evap   ','frc_prc','prc_prc', & !85
       'frc_ran','hst_srf' /)

  real, save, allocatable   :: tke_sgs(:), tke_res(:), tke0(:), wtv_sgs(:),  &
       wtv_res(:), wrl_sgs(:), thvar(:), svctr(:,:), ssclr(:)

  public :: sflg, ssam_intvl, savg_intvl, statistics, init_stat, write_ps,   &
       acc_tend, updtst, sfc_stat, close_stat, fill_scalar, tke_sgs, sgsflxs,&
       sgs_vel, comp_tke, get_zi

contains
  ! 
  ! ---------------------------------------------------------------------
  ! INIT_STAT:  This routine initializes the statistical arrays which
  ! are user/problem defined.  Note that svctr is given 100 elements, and
  ! elements 90 and above are used for computing the TKE budget. Hence
  ! if (nvar2 >= 90 the program stops
  ! 
  subroutine init_stat(time, filprf, expnme, nzp)

    use grid, only : nxp, nyp, iradtyp
    use mpi_interface, only : myid

    character (len=80), intent (in) :: filprf, expnme
    integer, intent (in)            :: nzp
    real, intent (in)               :: time

    character (len=80) :: fname

    allocate (wtv_sgs(nzp),wtv_res(nzp),wrl_sgs(nzp))
    allocate (tke_res(nzp),tke_sgs(nzp),tke0(nzp),thvar(nzp))
    allocate (ssclr(nvar1),svctr(nzp,100))

    wtv_sgs(:) = 0.
    wtv_res(:) = 0.
    wrl_sgs(:) = 0.
    tke_res(:) = 0.
    tke_sgs(:) = 0.
    tke0(:)    = 0.

    svctr(:,:) = 0.
    ssclr(:)   = 0.                 ! changed from = -999. to = 0.

    select case(level)
    case (0)
       nv1 = 13
       nv2 = 58
    case (1)
       nv1 = 14
       nv2 = 58
    case (2)
       nv1 = 20
       nv2 = 83
       if (iradtyp == 3) nv1=21
    case default
       nv1 = nvar1
       nv2 = nvar2
    end select

    fname =  trim(filprf)//'.ts'
    if(myid == 0) print                                                  &
         "(//' ',49('-')/,' ',/,'  Initializing: ',A20)",trim(fname)
    call open_nc( fname, expnme, time, (nxp-4)*(nyp-4), ncid1, nrec1)
    call define_nc( ncid1, nrec1, nv1, s1)
    if (myid == 0) print *, '   ...starting record: ', nrec1

    fname =  trim(filprf)//'.ps'
    if(myid == 0) print                                                  &
         "(//' ',49('-')/,' ',/,'  Initiailzing: ',A20)",trim(fname)
    call open_nc( fname, expnme, time,(nxp-4)*(nyp-4), ncid2, nrec2)
    call define_nc( ncid2, nrec2, nv2, s2, n1=nzp)
    if (myid == 0) print *, '   ...starting record: ', nrec2

  end subroutine init_stat
  !
  ! ---------------------------------------------------------------------
  ! Subroutine Statistics:  This subroutine is the statistics driver
  ! it calls various other subroutines to compute and accumulate
  ! statistical quantities.  These are stored in two arrays:  SVCTR,
  ! and SSCLR (which accumulate scalar and vector statistics respectively
  !
  subroutine statistics(time)

    use grid, only : a_up, a_vp, a_wp, a_rc, a_theta, a_scr1, a_scr2   &
         , a_rp, a_tp, a_press, nxp, nyp, nzp, dzm, dzt, zm, zt, th00, umean &
         , vmean, dn0, precip, a_rpp, a_npp, albedo, CCN, iradtyp, a_rflx    &
         , a_sflx, albedo

    real, intent (in) :: time

    if (nsmp == 0.) fsttm = time
    nsmp=nsmp+1.
    ssclr(14:nvar1) = -999.
    !
    ! profile statistics
    !
    call accum_stat(nzp, nxp, nyp, a_up, a_vp, a_wp, a_tp, a_press, umean &
         ,vmean,th00)
    if (iradtyp == 3) then
       call accum_rad(nzp, nxp, nyp, a_rflx, sflx=a_sflx, alb=albedo)
    elseif (iradtyp > 0) then
       call accum_rad(nzp, nxp, nyp, a_rflx)
    end if
    if (level >=1) call accum_lvl1(nzp, nxp, nyp, a_rp)
    if (level >=2) call accum_lvl2(nzp, nxp, nyp, th00, dn0, zm, a_wp, &
         a_scr1, a_theta, a_tp, a_rc, a_scr2, a_rp)
    if (level >=3) call accum_lvl3(nzp, nxp, nyp, dn0, zm, a_rc, a_rpp,     &
         a_npp, precip, CCN)
    !
    ! scalar statistics
    !
    call set_ts(nzp, nxp, nyp, a_wp, a_theta, dn0, zt,zm,dzt,dzm,th00,time)
    if (level >=1) call ts_lvl1(nzp, nxp, nyp, dn0, zt, dzm, a_rp)
    if (level >=2) call ts_lvl2(nzp, nxp, nyp, a_rp, a_scr2, zt)

    call write_ts

  end subroutine statistics
  ! 
  ! -----------------------------------------------------------------------
  ! subroutine set_ts: computes and writes time sequence stats
  !
  subroutine set_ts(n1,n2,n3,w,th,dn0,zt,zm,dzt,dzm,th00,time)

    use defs, only : cp

    integer, intent(in) :: n1,n2,n3
    real, intent(in)    :: w(n1,n2,n3),th(n1,n2,n3)
    real, intent(in)    :: dn0(n1),zt(n1),zm(n1),dzt(n1),dzm(n1),th00,time

    integer :: k
    real    :: bf(n1)

    ssclr(1) = time
    ssclr(4) = get_zi(n1, n2, n3, 2, th, dzm, zt, 1.)   ! maximum gradient
    ssclr(5) = get_zi(n1, n2, n3, 3, th, thvar, zt, 1.) ! maximum variance
    ! 
    ! buoyancy flux statistics
    ! 
    ssclr(7) = 0.
    do k = 2,n1-2
       bf(k) = wtv_res(k) + wtv_sgs(k)
       ssclr(7) = ssclr(7) + (tke_res(k)+tke_sgs(k))*dn0(k)/dzt(k)
       svctr(k,33) = svctr(k,33) + wtv_sgs(k)*9.8/th00
    end do
    ssclr(6) = get_zi(n1, n2, n3, 4, th, bf, zm, 1.) ! minimum buoyancy flux

    ssclr(8) = bf(2)
    ssclr(9) = maxval(w)

    ssclr(12) = ssclr(12)*cp*(dn0(1)+dn0(2))*0.5 

  end subroutine set_ts
  ! 
  ! -----------------------------------------------------------------------
  ! subroutine ts_lvl1: computes and writes time sequence stats; for the
  ! zi calculation setting itype=1 selects a concentration threshold
  !
  subroutine ts_lvl1(n1,n2,n3,dn0,zt,dzm,q)

    use defs, only : alvl

    integer, intent(in) :: n1,n2,n3
    real, intent(in)    :: q(n1,n2,n3)
    real, intent(in)    :: dn0(n1),zt(n1),dzm(n1)

    ssclr(13) = ssclr(13)*alvl*(dn0(1)+dn0(2))*0.5
    ssclr(14) = get_zi(n1, n2, n3, 1, q, dzm, zt, 0.5e-3)

  end subroutine ts_lvl1
  ! 
  ! -----------------------------------------------------------------------
  ! subroutine ts_lvl2: computes and writes time sequence stats
  !
  subroutine ts_lvl2(n1,n2,n3,rt,rs,zt)

    integer, intent(in) :: n1,n2,n3
    real, intent(in)    :: rt(n1,n2,n3),rs(n1,n2,n3), zt(n1)

    integer :: k,i,j
    real    :: cpnt, unit, xaqua

    ssclr(18)  = zt(n1)
    ssclr(19)  = 0.
    ssclr(20)  = 0.

    unit = 1./real((n2-4)*(n3-4))
    do j=3,n3-2
       do i=3,n2-2
          cpnt  = 0.
          do k=2,n1-2
             xaqua = rt(k,i,j) - rs(k,i,j)
             if (xaqua > 1.e-5) then
                ssclr(17) = max(ssclr(17),zt(k))
                ssclr(18) = min(ssclr(18),zt(k))
                cpnt = unit
                ssclr(20) = max(ssclr(20), xaqua)
             end if
          end do
          ssclr(19) = ssclr(19) + cpnt
       end do
    end do

    if (ssclr(18) == zt(n1)) ssclr(18) = -999.

  end subroutine ts_lvl2
  !
  !---------------------------------------------------------------------
  ! SUBROUTINE ACCUM_STAT: Accumulates various statistics over an 
  ! averaging period for base (level 0) version of model
  !
  subroutine accum_stat(n1,n2,n3,u,v,w,t,p,um,vm,th00)

    integer, intent (in) :: n1,n2,n3
    real, dimension (n1,n2,n3), intent (in)    :: u, v, w, t, p
    real, intent (in)           :: um, vm, th00

    integer :: i,j,k
    real    :: a1(n1), b1(n1), c1(n1), d1(n1), a3(n1), b3(n1), x

    x = 1./real( (n3-4)*(n2-4))
    call get_avg3(n1,n2,n3, u,a1)
    call get_avg3(n1,n2,n3, v,b1)
    call get_avg3(n1,n2,n3, t,c1)
    call get_avg3(n1,n2,n3, p,d1)
    call get_var3(n1,n2,n3, t, c1, thvar)

    a3(:) = 0.
    b3(:) = 0.
    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             a3(k)=a3(k) + w(k,i,j)**3
             b3(k)=b3(k) + (t(k,i,j)-a1(k))**3
          end do
       end do
    end do

    do k=1,n1
       svctr(k,10)=svctr(k,10) + a1(k) + um
       svctr(k,11)=svctr(k,11) + b1(k) + vm
       svctr(k,12)=svctr(k,12) + c1(k) + th00
       svctr(k,13)=svctr(k,13) + d1(k)
       svctr(k,17)=svctr(k,17) + thvar(k)
       svctr(k,18)=svctr(k,18) + a3(k) * x
       svctr(k,19)=svctr(k,19) + b3(k) * x
    end do

  end subroutine accum_stat
  !
  !---------------------------------------------------------------------
  ! SUBROUTINE ACCUM_STAT: Accumulates various statistics over an 
  ! averaging period for radiation variables
  !
  subroutine accum_rad(n1,n2,n3,rflx,sflx,alb)

    integer, intent (in) :: n1,n2,n3
    real, intent (in)    :: rflx(n1,n2,n3)
    real, optional, intent (in) :: sflx(n1,n2,n3), alb(n2,n3)

    integer :: k
    real    :: a1(n1),a2(n1)

    call get_avg3(n1,n2,n3,rflx,a1)
    call get_var3(n1,n2,n3,rflx,a1,a2)
    do k=1,n1
       svctr(k,55)=svctr(k,55) + a1(k)
       svctr(k,56)=svctr(k,56) + a2(k)
    end do

    if (present(sflx)) then
       call get_avg3(n1,n2,n3,sflx,a1)
       call get_var3(n1,n2,n3,sflx,a1,a2)
       do k=1,n1
          svctr(k,57)=svctr(k,57) + a1(k)
          svctr(k,58)=svctr(k,58) + a2(k)
       end do
       ssclr(21) = get_avg(1,n2,n3,1,alb)
    end if
    
  end subroutine accum_rad
  !
  !---------------------------------------------------------------------
  ! SUBROUTINE ACCUM_LVL1: Accumulates various statistics over an 
  ! averaging period for moisture variable (smoke or total water)
  !
  subroutine accum_lvl1(n1,n2,n3,rt)

    integer, intent (in) :: n1,n2,n3
    real, intent (in)  :: rt(n1,n2,n3)

    integer :: i,j,k
    real    :: a1(n1),a2(n1),a3(n1)

    call get_avg3(n1,n2,n3,rt,a1)
    call get_var3(n1,n2,n3,rt,a1,a2)

    a3(:) = 0.
    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             a3(k) = a3(k) + (rt(k,i,j)-a1(k))**3
          end do
       end do
    end do

    do k=1,n1
       svctr(k,50)=svctr(k,50) + a1(k)*1000.
       svctr(k,51)=svctr(k,51) + a2(k)
       svctr(k,52)=svctr(k,52) + a3(k)/REAL((n2-4)*(n3-4))
    end do

  end subroutine accum_lvl1
  !
  !---------------------------------------------------------------------
  ! SUBROUTINE ACCUM_LVL2: Accumulates specialized statistics that depend
  ! on level 3 variables.
  !
  subroutine accum_lvl2(n1, n2, n3, th00, dn0, zm, w, tv, th, tl, &
       rl, rs, rt)

    use defs, only : ep2

    integer, intent (in) :: n1,n2,n3
    real, intent (in)                       :: th00
    real, intent (in), dimension(n1)        :: zm, dn0
    real, intent (in), dimension(n1,n2,n3)  :: w, th, tl, rl, rs, rt
    real, intent (out), dimension(n1,n2,n3) :: tv

    integer                   :: k, i, j, km1
    logical                   :: aflg
    real                      :: xy1mx
    real, dimension(n1)       :: a1, a2, a3, tvbar
    real, dimension(n2,n3)    :: scr, xy1, xy2

    !
    ! liquid water statistics
    !
    call get_avg3(n1,n2,n3,rl,a1)
    call get_var3(n1,n2,n3,rl,a1,a2)

    a3(:) = 0.
    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             a3(k) = a3(k) + (rl(k,i,j)-a1(k))**3
          end do
       end do
    end do

    do k=1,n1
       svctr(k,59)=svctr(k,59) + a1(k)*1000.
       svctr(k,60)=svctr(k,60) + a2(k)
       svctr(k,61)=svctr(k,61) + a3(k)/REAL((n2-4)*(n3-4))
    end do
    !
    ! do some conditional sampling statistics: cloud, cloud-core
    !
    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             tv(k,i,j) = th(k,i,j)*(1.+ep2*rt(k,i,j) - rl(k,i,j))
          end do
       end do
    end do
    call get_avg3(n1,n2,n3,tv,tvbar)

    xy1mx = 0.
    do k=1,n1
       aflg = .false.
       do j=3,n3-2
          do i=3,n2-2
             xy1(i,j) = 0.
             xy2(i,j) = 0.
             if (rt(k,i,j) > rs(k,i,j) + 0.01e-3) then
                aflg = .true.
                xy1(i,j)=1.
                if (tv(k,i,j) > tvbar(k)) xy2(i,j)=1.
             end if
          end do
       end do

       if (aflg) then
          svctr(k,64)=svctr(k,64)+get_avg(1,n2,n3,1,xy1)
          svctr(k,65)=svctr(k,65)+get_csum(1,n2,n3,1,xy1,xy1)
          svctr(k,66)=svctr(k,66)+get_csum(n1,n2,n3,k,w,xy1)
          svctr(k,67)=svctr(k,67)+get_csum(n1,n2,n3,k,tl,xy1)
          svctr(k,68)=svctr(k,68)+get_csum(n1,n2,n3,k,tv,xy1)
          svctr(k,69)=svctr(k,69)+get_csum(n1,n2,n3,k,rt,xy1)*1000.
          svctr(k,70)=svctr(k,70)+get_csum(n1,n2,n3,k,rl,xy1)*1000.

          svctr(k,74)=svctr(k,74)+get_avg(1,n2,n3,1,xy2)
          svctr(k,75)=svctr(k,75)+get_csum(1,n2,n3,1,xy2,xy2)
          svctr(k,76)=svctr(k,76)+get_csum(n1,n2,n3,k,w,xy2)
          svctr(k,77)=svctr(k,77)+get_csum(n1,n2,n3,k,tl,xy2)
          svctr(k,78)=svctr(k,78)+get_csum(n1,n2,n3,k,tv,xy2)
          svctr(k,79)=svctr(k,79)+get_csum(n1,n2,n3,k,rt,xy2)*1000.
          svctr(k,80)=svctr(k,80)+get_csum(n1,n2,n3,k,rl,xy2)*1000.

          do j=3,n3-2
             do i=3,n2-2
                scr(i,j)=(.5*(tl(k,i,j)+tl(k+1,i,j))+th00)*w(k,i,j)
             end do
          end do
          svctr(k,71)=svctr(k,71)+get_csum(1,n2,n3,1,scr,xy1)
          svctr(k,81)=svctr(k,81)+get_csum(1,n2,n3,1,scr,xy2)

          do j=3,n3-2
             do i=3,n2-2
                scr(i,j)=(.5*(tv(k,i,j)+tv(k+1,i,j)))*w(k,i,j)
             end do
          end do
          svctr(k,72)=svctr(k,72)+get_csum(1,n2,n3,1,scr,xy1)
          svctr(k,82)=svctr(k,82)+get_csum(1,n2,n3,1,scr,xy2)

          do j=3,n3-2
             do i=3,n2-2
                scr(i,j)=(.5*(rt(k,i,j)+rt(k+1,i,j)))*w(k,i,j)
             end do
          end do
          svctr(k,73)=svctr(k,73)+get_csum(1,n2,n3,1,scr,xy1)
          svctr(k,83)=svctr(k,83)+get_csum(1,n2,n3,1,scr,xy2)
       end if
    end do
    !
    ! water paths
    !
    do j=3,n3-2
       do i=3,n2-2
          scr(i,j) = 0.
          do k=1,n1
             km1=max(1,k-1)
             scr(i,j)=scr(i,j)+rl(k,i,j)*dn0(k)*(zm(k)-zm(km1))*1000.
          enddo
       end do
    end do
    ssclr(15) = get_avg(1,n2,n3,1,scr)
    ssclr(16) = get_cor(1,n2,n3,1,scr,scr)
  end subroutine accum_lvl2
  !
  !---------------------------------------------------------------------
  ! SUBROUTINE ACCUM_LVL3: Accumulates specialized statistics that depend
  ! on level 3 variables.
  !
  subroutine accum_lvl3(n1, n2, n3, dn0, zm, rc, rr, nr, rrate, CCN)

    use defs, only : alvl

    integer, intent (in) :: n1,n2,n3
    real, intent (in)                      :: CCN
    real, intent (in), dimension(n1)       :: zm, dn0
    real, intent (in), dimension(n1,n2,n3) :: rc, rr, nr, rrate

    integer                :: k, i, j, km1
    real                   :: nrsum, nrcnt, rrsum, rrcnt, xrain, xaqua
    real                   :: rmax, rmin
    real, dimension(n1)    :: a1
    real, dimension(n2,n3) :: scr1,scr2
    logical                :: aflg
    
    !
    ! conditionally average rain numbers, and droplet concentrations
    !
    
    call get_avg3(n1,n2,n3,rr,a1)
    nrsum = 0.
    nrcnt = 0.
    do k=1,n1-1
       aflg = .false.
       do j=3,n3-2
          do i=3,n2-2
             scr1(i,j) = 0.
             if (rr(k,i,j) > 0.001e-3) then
                aflg = .true.
                scr1(i,j) = 1.
                nrsum = nrsum + nr(k,i,j)
                nrcnt = nrcnt + 1.
             end if
          end do
       end do
       svctr(k,84)=svctr(k,84) + CCN*dn0(k)/1000. ! nc (1/litre)
       svctr(k,86)=svctr(k,86) + a1(k)*1000.
       if (aflg) then
          svctr(k,85)=svctr(k,85)+get_csum(n1,n2,n3,k,nr,scr1)
          svctr(k,91)=svctr(k,91)+get_avg(1,n2,n3,1,scr1)
       end if
    end do
    !
    ! conditionally average precip fluxes
    !
    do k=2,n1-2
       rrsum = 0.
       rrcnt = 0.
       aflg = .false.
       do j=3,n3-2
          do i=3,n2-2
             scr1(i,j) = 0.
             if (rrate(k,i,j) > 3.65e-5) then
                aflg = .true.
                scr1(i,j) = 1.
                rrsum = rrsum + rrate(k,i,j) * alvl * 0.5*(dn0(1)+dn0(2))
                rrcnt = rrcnt + 1.
             end if
          end do
       end do
       if (aflg) then
          if (k == 2 ) ssclr(24) = rrcnt
          svctr(k-1,90)=svctr(k-1,90)+get_csum(n1,n2,n3,k,rrate,scr1)
          svctr(k-1,89)=svctr(k-1,89)+get_avg(1,n2,n3,1,scr1)
       end if
    end do
    !
    ! histograms
    !
    do k=1,n1
       rrcnt = 0.
       do j=3,n3-2
          do i=3,n2-2
             rmin = max(6.2e-8,(k-1)*3.421e-5)
             rmax =  k * 3.421e-5
             if (rrate(2,i,j) > rmin .and. rrate(2,i,j) <= rmax) rrcnt=rrcnt+1.
          end do
       end do
       if (rrcnt > 0.) svctr(k,92)=svctr(k,92)+rrcnt
    end do
    !
    ! water paths
    !
    do j=3,n3-2
       do i=3,n2-2
          scr1(i,j) = 0.
          scr2(i,j) = 0.
          do k=1,n1
             km1=max(1,k-1)
             xrain = max(0.,rr(k,i,j))
             xaqua = max(xrain,rc(k,i,j))
             scr1(i,j)=scr1(i,j)+xaqua*dn0(k)*(zm(k)-zm(km1))*1000.
             scr2(i,j)=scr2(i,j)+xrain*dn0(k)*(zm(k)-zm(km1))*1000.
          enddo
       end do
    end do
    ssclr(15) = get_avg(1,n2,n3,1,scr1)
    ssclr(16) = get_cor(1,n2,n3,1,scr1,scr1)
    ssclr(22) = get_avg(1,n2,n3,1,scr2)
    ssclr(23) = get_avg(1,n2,n3,1,rrate(2,:,:))
    ssclr(25) = CCN*1.e-6 ! per cc
    ssclr(26) = nrsum
    ssclr(27) = nrcnt

  end subroutine accum_lvl3
  ! 
  ! ---------------------------------------------------------------------
  ! subroutine comp_tke: calculates some components of the turbulent
  ! kinetic energy budgets and velocity statistics
  ! 
  subroutine comp_tke(n1,n2,n3,dzm,th00,u,v,w,s,scr)

    integer, intent (in) :: n1,n2,n3
    real, intent (in)    :: dzm(n1),th00,u(n1,n2,n3),v(n1,n2,n3),w(n1,n2,n3)
    real, intent (inout) :: s(n1,n2,n3)
    real, intent (out) :: scr(n1,n2,n3)

    integer :: k,kp1,i,j
    real    :: x1(n1), x2(n1), xx

    ! 
    ! ------
    ! Calculates buoyancy forcing
    ! 
    call get_buoyancy(n1,n2,n3,s,w,th00)
    ! 
    ! ------
    ! Estimates shear component of TKE budget
    ! 
    call get_shear(n1,n2,n3,u,v,w,dzm)
    ! 
    ! ------
    ! Calculates horizontal variances and resolved TKE
    ! 
    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             scr(k,i,j)=u(k,i,j)**2
          end do
       end do
    end do
    call get_avg3(n1,n2,n3,scr,x1)
    call get_avg3(n1,n2,n3,u,x2)
    do k=1,n1
       svctr(k,14) = svctr(k,14) + x1(k)
       xx = x1(k)-x2(k)**2
       tke_res(k)  = xx
    end do

    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             scr(k,i,j)=v(k,i,j)**2
          end do
       end do
    end do
    call get_avg3(n1,n2,n3,scr,x1)
    call get_avg3(n1,n2,n3,v,x2)
    do k=1,n1
       svctr(k,15) = svctr(k,15) + x1(k)
       xx = x1(k)-x2(k)**2
       tke_res(k)  = tke_res(k) + xx
    end do

    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             scr(k,i,j)=w(k,i,j)**2
          end do
       end do
    end do
    call get_avg3(n1,n2,n3,scr,x1)

    do k=1,n1
       svctr(k,16) = svctr(k,16)+x1(k)
       kp1 = min(k+1,n1)
       tke_res(k)  = 0.5*(0.5*(tke_res(k)+tke_res(kp1)) + x1(k))
       if (nsmp == 0) tke0(k) = tke_res(k)
    end do

  end subroutine comp_tke
  ! 
  ! ---------------------------------------------------------------------
  ! get_buoyancy:  estimates buoyancy production term in tke budget
  ! 
  subroutine get_buoyancy(n1,n2,n3,b,w,th00)

    use defs, only : g

    integer, intent(in) :: n1,n2,n3
    real, intent(in)    :: w(n1,n2,n3),th00
    real, intent(inout) :: b(n1,n2,n3)

    integer :: i,j,k,kp1

    do j=3,n3-2
       do i=3,n2-2
          do k=1,n1
             kp1 = min(k+1,n1)
             b(k,i,j) = (b(k,i,j) + b(kp1,i,j))
          end do
       end do
    end do
    call get_cor3(n1,n2,n3,b,w,wtv_res)
    do k=1,n1
       svctr(k,35) = svctr(k,35) + wtv_res(k)
       wtv_res(k) = wtv_res(k) * th00/g
    end do

  end subroutine get_buoyancy
  !
  ! ---------------------------------------------------------------------
  ! get_shear:  estimates shear production term in tke budget
  !
  subroutine get_shear(n1,n2,n3,u,v,w,dzm)

    integer, intent(in) :: n3,n2,n1
    real, intent(in)    :: w(n1,n2,n3),dzm(n1),u(n1,n2,n3),v(n1,n2,n3)

    real :: ub(n1), vb(n1)
    integer i,j,k
    real fact, uw_shear, vw_shear

    fact = 0.25/float((n2-4)*(n3-4))

    call get_avg3(n1,n2,n3,u,ub)
    call get_avg3(n1,n2,n3,v,vb)

    do j=3,n3-2
       do i=3,n2-2
          do k=2,n1-1
             uw_shear = -(u(k,i,j)-ub(k))*fact*(                              &
                  (w(k,i,j)  +w(k,i+1,j)  )*(ub(k+1)-ub(k)  )*dzm(k) +        &
                  (w(k-1,i,j)+w(k-1,i+1,j))*(ub(k)  -ub(k-1))*dzm(k-1))
             if (j > 1) vw_shear = -(v(k,i,j)-vb(k))*fact*(                   &
                  (w(k,i,j)  +w(k,i,j+1)  )*(vb(k+1)-vb(k)  )*dzm(k) +        &
                  (w(k-1,i,j)+w(k-1,i,j+1))*(vb(k)  -vb(k-1))*dzm(k-1))

             svctr(k,48) = svctr(k,48)+uw_shear
             svctr(k,36) = svctr(k,36)+uw_shear+vw_shear
          end do
       end do
    end do

  end subroutine get_shear
  ! 
  ! ----------------------------------------------------------------------
  ! Subroutine write_ts: writes the statistics file
  ! 
  subroutine write_ts

    use netcdf

    integer :: iret, n, VarID
    ! 
    ! define different dimensions
    ! 
    do n=1,nv1
       iret = nf90_inq_varid(ncid1, s1(n), VarID)
       iret = nf90_put_var(ncid1, VarID, ssclr(n), start=(/nrec1/))
       ssclr(n) = 0.
    end do
    iret = nf90_sync(ncid1)
    nrec1 = nrec1 + 1

  end subroutine write_ts
  ! 
  ! ----------------------------------------------------------------------
  ! Subroutine write_ps: writes the time averaged elements of the 
  ! statistics file
  ! 
  subroutine  write_ps(n1,dn0,u0,v0,zm,zt,time)

    use netcdf
    use defs, only : alvl, cp

    integer, intent (in) :: n1
    real, intent (in)    :: time
    real, intent (in)    :: dn0(n1), u0(n1), v0(n1), zm(n1), zt(n1)

    integer :: iret, VarID, k, n, kp1

    lsttm = time
    do k=1,n1
       kp1 = min(n1,k+1)
       svctr(k,20) = (svctr(k,20)+svctr(k,21))*cp
       svctr(k,22) = svctr(k,22)+svctr(k,23)
       svctr(k,24) = svctr(k,24)+svctr(k,25)
       svctr(k,26) = svctr(k,26)+svctr(k,27)
       svctr(k,53) = (svctr(k,53)+svctr(k,54))*alvl
       svctr(k,21) = svctr(k,21)*cp
       svctr(k,54) = svctr(k,54)*alvl
       svctr(k,62) = svctr(k,62)*alvl
       svctr(k,37) = svctr(k,44) + svctr(k,47) +(                         &
            +svctr(k,45) + svctr(kp1,45) + svctr(k,46) + svctr(kp1,46)    &
            +svctr(k,42) + svctr(kp1,42) + svctr(k,43) + svctr(kp1,43)    &
            -svctr(k,36) - svctr(kp1,36)   )*0.5       
       if (lsttm>fsttm) then
          svctr(k,49) = (tke_res(k) - tke0(k))/(lsttm-fsttm)
       else
          svctr(k,49) = 0.
       end if
       svctr(k,10:nv2) = svctr(k,10:nv2)/nsmp
    end do

    iret = nf90_inq_VarID(ncid2, s2(1), VarID)
    iret = nf90_put_var(ncid2, VarID, time, start=(/nrec2/))
    if (nrec2 == 1) then
       iret = nf90_inq_varid(ncid2, s2(2), VarID)
       iret = nf90_put_var(ncid2, VarID, zt, start = (/nrec2/))
       iret = nf90_inq_varid(ncid2, s2(3), VarID)
       iret = nf90_put_var(ncid2, VarID, zm, start = (/nrec2/))
       iret = nf90_inq_varid(ncid2, s2(4), VarID)
       iret = nf90_put_var(ncid2, VarID, dn0, start = (/nrec2/))
       iret = nf90_inq_varid(ncid2, s2(5), VarID)
       iret = nf90_put_var(ncid2, VarID, u0, start = (/nrec2/))
       iret = nf90_inq_varid(ncid2, s2(6), VarID)
       iret = nf90_put_var(ncid2, VarID, v0, start = (/nrec2/))
    end if

    iret = nf90_inq_VarID(ncid2, s2(7), VarID)
    iret = nf90_put_var(ncid2, VarID, fsttm, start=(/nrec2/))
    iret = nf90_inq_VarID(ncid2, s2(8), VarID)
    iret = nf90_put_var(ncid2, VarID, lsttm, start=(/nrec2/))
    iret = nf90_inq_VarID(ncid2, s2(9), VarID)
    iret = nf90_put_var(ncid2, VarID, nsmp,  start=(/nrec2/))

    do n=10,nv2
       iret = nf90_inq_varid(ncid2, s2(n), VarID)
       iret = nf90_put_var(ncid2,VarID,svctr(:,n), start=(/1,nrec2/),    &
            count=(/n1,1/))
    end do

    iret  = nf90_sync(ncid2)
    nrec2 = nrec2+1
    nsmp  = 0.

    do k=1,n1
       svctr(k,:) = 0.
    end do

  end subroutine write_ps
  !
  ! ----------------------------------------------------------------------
  ! subroutine: sfc_stat:  Updates statistical arrays with surface flux
  ! variables
  !
  subroutine sfc_stat(n2,n3,tflx,qflx,ustar,sst)

    integer, intent(in) :: n2,n3
    real, intent(in), dimension(n2,n3) :: tflx, qflx, ustar
    real, intent(in)    :: sst

    ssclr(10) = sst
    ssclr(11) = get_avg(1,n2,n3,1,ustar)

    ssclr(12) = get_avg(1,n2,n3,1,tflx)
    if (level >= 1) ssclr(13) = get_avg(1,n2,n3,1,qflx)

  end subroutine sfc_stat
  ! 
  ! ----------------------------------------------------------------------
  ! subroutine: fills scalar array based on index
  ! 1: cfl; 2 max divergence
  ! 
  subroutine fill_scalar(index,xval)

    integer, intent(in) :: index
    real, intent (in)   :: xval

    select case(index)
    case(1) 
       ssclr(2) = xval
    case(2) 
       ssclr(3) = xval
    end select

  end subroutine fill_scalar
  !
  ! ----------------------------------------------------------------------
  ! subroutine: calculates the dissipation for output diagnostics, if
  ! isgstyp equals 2 then le is passed in via diss
  !
  subroutine sgs_vel(n1,n2,n3,v1,v2,v3)

    integer, intent(in) :: n1,n2,n3
    real, intent(in)    :: v1(n1),v2(n1),v3(n1)

    svctr(:,23)=svctr(:,23)+v1(:)/float((n2-2)*(n3-2))
    svctr(:,25)=svctr(:,25)+v2(:)/float((n2-2)*(n3-2))
    svctr(:,27)=svctr(:,27)+v3(:)/float((n2-2)*(n3-2))

  end subroutine sgs_vel
  !
  ! --------------------------------------------------------------------------
  ! SGSFLXS: estimates the sgs rl and tv flux from the sgs theta_l and sgs r_t 
  ! fluxes
  !
  subroutine sgsflxs(n1,n2,n3,level,rl,rv,th,flx,type)

    use defs, only : alvl, cp, rm, ep2

    integer, intent(in) :: n1,n2,n3,level
    real, intent(in)    :: rl(n1,n2,n3),rv(n1,n2,n3)
    real, intent(in)    :: th(n1,n2,n3),flx(n1,n2,n3)
    character (len=2)   :: type

    integer :: k,i,j
    real    :: rnpts      ! reciprical of number of points and
    real    :: fctl, fctt ! factors for liquid (l) and tv (t) fluxes

    if (type == 'tl') then
       wrl_sgs(:) = 0.
       wtv_sgs(:) = 0.
    end if
    rnpts = 1./real((n2-4)*(n3-4))
    !
    ! calculate fluxes assuming the possibility of liquid water.  if liquid
    ! water does not exist sgs_rl = 0.
    !
    if ( level >= 2 ) then
       do j = 3,n3-2
          do i = 3,n2-2
             do k = 1,n1-1
                if (rl(k+1,i,j) > 0.) then
                   fctt = rnpts*(1. + rv(k,i,j)*(1.+ep2 +ep2*rv(k,i,j)*alvl   &
                        /(rm*th(k,i,j))))                                     &
                        /(1.+(rv(k,i,j)*(alvl/th(k,i,j))**2)/(rm*cp))
                   select case (type)
                   case ('tl')
                      fctl =-rnpts/(rm*th(k,i,j)**2/(rv(k,i,j)*alvl)+alvl/cp)
                   case ('rt')
                      fctl =rnpts/(1.+(rv(k,i,j)*alvl**2)/(cp*rm*th(k,i,j)**2))
                      fctt = (alvl*fctt/cp - th(k,i,j)*rnpts)
                   end select
                   wrl_sgs(k) = wrl_sgs(k) + fctl*flx(k,i,j)
                   wtv_sgs(k) = wtv_sgs(k) + fctt*flx(k,i,j)
                else
                   select case (type)
                   case ('tl')
                      fctt = rnpts*(1. + ep2*rv(k,i,j))
                   case ('rt')
                      fctt = rnpts*(ep2*th(k,i,j))
                   end select
                   wtv_sgs(k) = wtv_sgs(k) + fctt*flx(k,i,j)
                end if
             end do
          end do
       end do
       !
       ! calculate fluxes for dry thermodynamics, i.e., wrl_sgs is by def
       ! zero
       !   
    else
       do k = 1,n1
          wrl_sgs(k) = 0.
       end do
       do j = 3,n3-2
          do i = 3,n2-2
             do k = 1,n1-1
                if ( level >= 1) then
                   select case (type)
                   case ('tl')
                      fctt = rnpts * (1. + ep2*rv(k,i,j)) 
                   case ('rt')
                      fctt = rnpts * ep2*th(k,i,j)
                   end select
                else
                   fctt = rnpts 
                end if
                wtv_sgs(k) = wtv_sgs(k) + fctt*flx(k,i,j)
             end do
          end do
       end do
    end if

  end subroutine sgsflxs
  !
  ! ----------------------------------------------------------------------
  ! subroutine fill_tend: fills arrays with current value of tendencies
  !
  subroutine acc_tend(n1,n2,n3,f1,f2,f3,t1,t2,t3,v1,v2,v3,ic,routine)

    integer, intent(in) :: n1,n2,n3,ic
    real, intent(in)    :: f1(n1,n2,n3),f2(n1,n2,n3),f3(n1,n2,n3)
    real, intent(in)    :: t1(n1,n2,n3),t2(n1,n2,n3),t3(n1,n2,n3)
    real, intent(inout) :: v1(n1),v2(n1),v3(n1)
    character (len=3)   :: routine

    integer :: k,ii
    real    :: x1(n1),x2(n1),x3(n1)

    call get_cor3(n1,n2,n3,f1,t1,x1)
    call get_cor3(n1,n2,n3,f2,t2,x2)
    call get_cor3(n1,n2,n3,f3,t3,x3)

    select case (routine)
    case ('sgs')
       ii = 39
    case ('adv')
       ii = 42
    end select

    select case (ic)
    case (1)
       do k=1,n1
          v1(k) = x1(k)
          v2(k) = x2(k)
          v3(k) = x3(k)
       end do
    case (2)
       do k=1,n1
          svctr(k,ii)   = svctr(k,ii)   + (x1(k)-v1(k))
          svctr(k,ii+1) = svctr(k,ii+1) + (x2(k)-v2(k))
          svctr(k,ii+2) = svctr(k,ii+2) + (x3(k)-v3(k))
       end do
    end select

  end subroutine acc_tend
  !
  !---------------------------------------------------------------------
  ! subroutine updtst: updates appropriate statistical arrays
  !
  subroutine updtst(n1,routine,nfld,values,ic)

    integer, intent(in)            :: n1,nfld,ic
    real, intent (in)              :: values(n1)
    character (len=3), intent (in) :: routine

    integer :: nn,k

    select case (routine)
    case("sgs")
       select case (nfld)
       case (-6)    
          nn = 31 ! dissipation length-scale
       case (-5)   
          nn = 30 ! mixing length
       case (-4)  
          nn = 29 ! eddy diffusivity
       case (-3) 
          nn = 28 ! eddy viscosity
       case (-2) 
          nn = 38 ! dissipation
       case (-1)  
          nn = 32 ! estimated sgs energy
       case (1)
          nn = 21 ! sgs tl flux
       case (2)
          nn = 54 ! sgs rt flux
       case default
          nn = 0
       end select
    case("adv")
       select case (nfld)
       case (-3)
          nn = 26 ! adv w flux
       case (-2)
          nn = 24 ! adv v flux
       case (-1)
          nn = 22 ! adv u flux
       case (0)
          nn = 62 ! adv rl flux
       case (1)
          nn = 20 ! adv tl flux
       case (2)
          nn = 53 ! adv rt flux
       case default
          nn = 0
       end select
    case("prs")
       select case (nfld)
       case (1)
          nn = 45 ! dpdx u corr
       case (2)
          nn = 46 ! dpdy v corr
       case (3)
          nn = 47 ! dpdz w corr
       case default
          nn = 0
       end select
    case("prc")
       select case (nfld)
       case (1)
          nn = 87
       case (2)
          nn = 88
       case (3)
          nn = 63
       case default
          nn = 0
       end select
    case default
       nn = 0      
    end select

    if (nn > 0) then
       if (ic == 0) svctr(:,nn)=0.
       do k=1,n1
          svctr(k,nn)=svctr(k,nn)+values(k)
       enddo
    end if

  end subroutine updtst
  !
  ! -------------------------------------------------------------------------
  !
  integer function close_stat()

    use netcdf

    close_stat = nf90_close(ncid1) + nf90_close(ncid2)

  end function close_stat
  !
  ! -------------------------------------------------------------------------
  !
  real function get_zi (n1, n2, n3, itype, sx, xx, z, threshold)

    integer, intent (in) :: n1, n2, n3, itype
    real, intent (in)    :: xx(n1), z(n1), sx(n1,n2,n3), threshold

    integer :: i, j, k, kk
    real    :: zibar, sval, dmy, scr(n2,n3)

    get_zi = -999.
    select case(itype)
    case (1) 
       !
       ! find level at which sx=threshold (xx is one over grid spacing)
       !
       zibar = 0.
       do j=3,n3-2
          do i=3,n2-2
             k = 2
             do while (k < n1-2 .and. sx(k,i,j) > threshold)
                k = k+1
             end do
             if (k == n1-2) zibar = -999.
             if (zibar /= -999.) zibar = zibar + z(k-1) +  &
                  (threshold - sx(k-1,i,j))/xx(k-1)     /  &
                  (sx(k,i,j) - sx(k-1,i,j) + epsilon(1.)) 
          end do
       end do
       if (zibar /= -999.) get_zi = zibar/real((n3-4)*(n2-4))

    case(2)
       !
       ! find level of maximum gradient (xx is one over grid spacing)
       !
       scr=0.
       do j=3,n3-2
          do i=3,n2-2
             sval = 0.
             do k=2,n1-5
                dmy = (sx(k+1,i,j)-sx(k,i,j))*xx(k)
                if (dmy > sval) then
                   sval = dmy
                   scr(i,j) = z(k)
                end if
             end do
          end do
       end do
       get_zi = get_avg(1,n2,n3,1,scr)

    case(3)
       !
       ! find level where xx is a maximum
       !
       sval = -huge(1.)
       kk = 1
       do k=2,n1
          if (xx(k) > sval) then
             kk = k
             sval = xx(k)
          end if
       end do
       get_zi = z(kk)

    case(4)
       !
       ! find level where xx is a maximum
       !
       sval = huge(1.)
       kk = 1
       do k=2,n1-2
          if (xx(k) < sval) then
             kk = k
             sval = xx(k)
          end if
       end do
       get_zi = z(kk)
    end select

  end function get_zi

end module stat


