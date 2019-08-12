PROGRAM SOR
!A simple program to use the SOR kernel from LES is
!Populated with dummy data
!Purpose is to analyse performance on CPU, openmp, etc
!Since TyBEC does not support floats, so we do an integer version

!Created: Waqar Nabi, 2015.09.08

!** omp does not really work for this algo as the successive calls
!   to the kernel MUST be serialized. This is just for experimenting with performance impact
use omp_lib 

!parameters
      integer, parameter  :: nmaxp    = 100000 !number of relexation iterations          
      integer, parameter  :: im       = 144  !dimensions
      integer, parameter  :: jm       = 144
      integer, parameter  :: km       = 144
      integer, parameter  :: maxvalue = 250 !max value that can be taken by init values
      
      !constants
      integer, parameter :: omega = 1
      
      !scalar variables
      integer :: reltmp
      integer :: sor_err
      integer :: linear
      
      !arrays; start from 0 for comp' with  C
      integer :: p(0:im-1, 0:jm-1, 0:km-1)
      integer :: pTemp(0:im-1, 0:jm-1, 0:km-1)
      integer :: pOut(0:im-1, 0:jm-1, 0:km-1)
      integer :: pOriginal(0:im-1, 0:jm-1, 0:km-1)
      integer :: rhs(0:im-1, 0:jm-1, 0:km-1)
      integer :: cn1(0:im-1, 0:jm-1, 0:km-1)
      integer :: cn2l(0:im-1, 0:jm-1, 0:km-1)
      integer :: cn2s(0:im-1, 0:jm-1, 0:km-1)
      integer :: cn3l(0:im-1, 0:jm-1, 0:km-1)
      integer :: cn3s(0:im-1, 0:jm-1, 0:km-1)
      integer :: cn4l(0:im-1, 0:jm-1, 0:km-1)
      integer :: cn4s(0:im-1, 0:jm-1, 0:km-1)
      
!$ call omp_set_num_threads(4) 
!$ print *, "Using OMP with 4 threads"

      !initialize arrays and call sor routine
      call init()
      call sorKernel()
      call post()
      
      
      !========================
      contains  
      !========================
      
      !-------------------------
      !---- initialization -----

      subroutine init
        real :: r
          
        do k = 0,km-1
          do j = 0,jm-1
            do i = 0, im-1
                linear = i+(j*im)+(k*im*jm)
                p(i,j,k) = linear !+ 1
                pOriginal(i,j,k) = linear !+ 1
                rhs(i,j,k) = linear !+ 2
                cn1(i,j,k) = linear !+ 3
                cn2l(i,j,k) = linear! + 4
                cn2s(i,j,k) = linear! + 5
                cn3l(i,j,k) = linear! + 6
                cn3s(i,j,k) = linear! + 7
                cn4l(i,j,k) = linear! + 8
                cn4s(i,j,k) = linear! + 9
            end do
          end do 
        end do
      
        !do i = 1,im
        !  cn2l(i)= floor(r*maxvalue)
        !  cn2s(i)= floor(r*maxvalue)
        !end do
        
        !do j = 1,jm(0:im-1, 0:jm-1, 0:km-1)
        !  cn3l(j)= floor(r*maxvalue)
        !  cn3s(j)= floor(r*maxvalue)
        !end do
        
        !do k = 1,km
        !  cn4l(k)= floor(r*maxvalue)
        !  cn4s(k)= floor(r*maxvalue)
        !end do
        
        
      end subroutine init
      
      !-------------------------
      !---- the SOR routine -----
      !-------------------------
      subroutine  sorKernel 
      
!$omp parallel do private (reltmp, p, sor_err)
! thread_num = omp_get_thread_num()
! print *, "This thread = ", thread_num
      do l = 0,nmaxp-1
        sor_err = 0
        reltmp = 0 !WN
        !leave the boundary elements untouched for every iteration...
        do k = 1,km-2
          do j = 1,jm-2
            do i = 1,im-2
              reltmp = omega*(cn1(i,j,k)*( &
              cn2l(i,j,k)*p(i+1,j,k)+cn2s(i,j,k)*p(i-1,j,k) & 
              +cn3l(i,j,k)*p(i,j+1,k)+cn3s(i,j,k)*p(i,j-1,k)& 
              +cn4l(i,j,k)*p(i,j,k+1)+cn4s(i,j,k)*p(i,j,k-1)& 
              -rhs(i,j,k))-p(i,j,k))
              pOut(i,j,k) = p(i,j,k) + reltmp
              sor_err = sor_err+reltmp*reltmp
            end do
          end do
        end do
      
      !update p with pOut
        do k = 1,km-2
          do j = 1,jm-2
            do i = 1,im-2
              p(i,j,k) = pOut(i,j,k)
            end do
          end do
        end do
     
      end do      

      !  do k = 0,km+1
      !      do j = 0,jm+1
      !        p(   0,j,k) = p(1 ,j,k)
      !        p(im+1,j,k) = p(im,j,k)
      !      end do
      !  end do
        
      !  do k = 0,km+1
      !      do i = 0,im+1
      !        p(i,   0,k) = p(i,jm,k)
      !        p(i,jm+1,k) = p(i, 1,k)
      !      end do
      !  end do
      !  
      !  do j = 0,jm+1
      !      do i = 0,im+1
      !        p(i,j,   0) = p(i,j,1)
      !        p(i,j,km+1) = p(i,j,km)
      !      end do
      !  end do
        
        !if (sor_err < pjuge) goto 7188 
      !end do
      !7188 continue
      end subroutine sorKernel
      
      !-------------------------
      !Writing the arrays to file
      !-------------------------
      subroutine post
        open(10, file = 'output.txt', form = 'formatted', status = 'unknown')
  
        !leave the boundary elements
        do k = 0,km-1
          do j = 0,jm-1
            do i = 0,im-1
              write(10,*) "linear  = ", i+(j*im)+(k*im*jm) , pOriginal(i,j,k), p(i,j,k)
            end do
          end do 
        end do
      end subroutine post

      
      end program SOR
