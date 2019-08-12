PROGRAM corio

!*************************************
!* Barebones.f 
!*
!* Author: S Waqar Nabi
!*************************************

!*********************************
!For paper
!*********************************
!time loop
DO n = 1,ntot
  !space loop
  DO i = 1, size
    local1(i) = vin0(i) + vin1(i) 
	  vconn_A_to_B(i) = local1(i) + local1(i)
  END DO
END DO  

END PROGRAM corio


TODO