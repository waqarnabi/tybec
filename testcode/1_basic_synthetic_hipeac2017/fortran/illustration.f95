program illustration

!--*****************************************!
!-- A simple mock example
!-- for prototyping
!--
!-- This instance is for testing
!-- smart buffering features
!-- and is based on example used
!-- in the HLPGPU-paper
!--
!-- Author: S Waqar Nabi
!--
!-- Created: 2016.12.23
!--
!-- Modifications:
!--
!--*****************************************!

!--USE param
!--USE sub

!-----------------------------------------
!-- local parameters
!-----------------------------------------
integer, parameter :: im      = 256
integer, parameter :: nsteps  = 1
integer, parameter :: maxinput= 250

!---------------------------------------
!-- variables
!---------------------------------------

!-- utility
real :: r
integer :: t


!-- IOs
integer :: vin0(im)
integer :: vin1(im)
integer :: vout(im)
integer :: s0

!-- intermediate/internal connecting variables
!-- the internal vectors are numbered vconn_N1_N2
!-- where N1, N2,...,NN are numbers representing paths
!-- taken at each hop (the position indicates hop#, the number
!-- represents the path taken)
integer :: vconn0(im)
integer :: vconn1(im)
integer :: vconn00(im)
integer :: vconn10(im)
integer :: vconn100(im)
integer :: sconn000

!---------------------------------------
!-- calls
!---------------------------------------

 call init()
 
 open(10, file = 'out.dat', form = 'formatted', status = 'unknown')
!-- call post()
 
!-- kernels are called repeatedly, .e.g in a time loop
 do t=1,nsteps
   call kernel_map_A()
   call kernel_unzip_A()
   call kernel_map_B()
   call kernel_fold_A()
   call kernel_map_C()
 end do
 
 call post()

!---------------------------------------
!-- init()
!---------------------------------------
  contains
  
  subroutine init
    
    !-- init scalar
    s0     = 3    !--input scalar
    sconn000 = s0   !--internal (accumulation) scalar
    
    !-- init vectors
    do i = 1, im
      call random_number(r)
      vin0(i) = floor(r*maxinput)

      call random_number(r)
      vin1(i) = floor(r*maxinput)
      
      vconn0(i)  = 0
      vconn1(i)  = 0
      vconn00(i) = 0
      vconn10(i) = 0
      vconn100(i)= 0
    end do
    
  end subroutine init


!---------------------------------------
!-- kernel_map_A
!---------------------------------------
  subroutine  kernel_map_A
    do i = 1,im
     ! boundary - pass through
     if (i==1 .or. i==im) then
      vconn0(i) = vin0(i)
      vconn1(i) = vin1(i)
     ! non-boundary
     else  
      vconn0(i) = vin0(i) + vin0(i-1) + vin0(i+1) + vin1(i)
      vconn1(i) = vin0(i) + vin0(i-1) + vin0(i+1) * vin1(i)
     endif
    end do
  end subroutine kernel_map_A    

!---------------------------------------
!-- kernel_unzip_A
!---------------------------------------
!-- No need to explicitluy "unzip" here as
!-- we already had two separate vectors (tuple of vectors) in this
!-- fortran version.
!-- We create a pass through kernel simply to retain a 1-1 with the
!-- original Functional/AST description
  subroutine  kernel_unzip_A
    do i = 1,im
     vconn00(i) = vconn0(i)
     vconn10(i) = vconn1(i)
    end do
  end subroutine kernel_unzip_A    


!---------------------------------------
!-- kernel_map_B
!---------------------------------------
  subroutine  kernel_map_B
    do i = 1,im
     vconn100(i) = vconn10(i) + vconn10(i)
    end do
  end subroutine kernel_map_B
  

!---------------------------------------
!-- kernel_fold_A
!---------------------------------------
  subroutine  kernel_fold_A
    do i = 1,im
     sconn000 = vconn00(i) + sconn000
    end do
  end subroutine kernel_fold_A

!---------------------------------------
!-- kernel_map_C
!---------------------------------------
  subroutine  kernel_map_C
    do i = 1,im
     vout(i) = sconn000 + vconn100(i)
    end do
  end subroutine kernel_map_C
  
!---------------------------
!--Writing the arrays to file
!---------------------------
subroutine post 
    write(10,*) "-------------------------------------------------------------------------------------------------------------------------------------------"
    write(10,*) "          i,      vin0(i),    vin1(i),       s0,     vconn0(i),  vconn1(i),   vconn00(i), vconn10(i), vconn100(i), sconn000,    vout(i) "
    write(10,*) "-------------------------------------------------------------------------------------------------------------------------------------------"
    do i = 1, im
      write(10,*) i,  vin0(i),  vin1(i),   s0,  vconn0(i),  vconn1(i), vconn00(i),  vconn10(i),  vconn100(i),  sconn000,  vout(i)
    end do
end subroutine post


end program illustration
