###############################################################
#
# Type of code to build $CNFG, location of code (in $ROOT) and 
# location where model is to be built $BIN
#
ROOT      = ..
BIN       = $(ROOT)/bin
ARCH      := $(shell uname)
#
# Define machine dependent variables
#
#
# Generic Variables
#
SRC     =$(ROOT)/src

ECHO    = /bin/echo
RM      = /bin/rm -f

ifeq ($(ARCH),AIX)
  NCDF = /usr/local
  NCDFLIB = -L$(NCDF)/lib64/r4i4 -lnetcdf
  NCDFINC = -I$(NCDF)/include
  ARCHIVE   = ar rs
  RANLIB    =:
  F90       = xlf95_r
  MPIF90    = mpxlf95_r 
  FFLAGS    = -O4 -Q -qarch=auto -qmaxmem=-1 -qrealsize=8  $(NCDFINC)
  MPIFFLAGS = -qmoddir=$(SRC)/mpi -I$(SRC)/mpi
  SEQFFLAGS = -qmoddir=$(SRC)/seq -I$(SRC)/seq
  LIBS      = $(NCDFLIB) -lmass
  MPILIBS   = -lblacssmp -lpesslsmp $(LIBS)
  F77FLAGS  = -qfixed
endif

ifeq ($(ARCH),Darwin)
  F90  = f95
  ARCHIVE   = ar rs
  RANLIB    =: 
  SEQFFLAGS = -I$(SRC)/seq
  MPIFFLAGS = -I$(SRC)/mpi
  NCDF = /usr/local/netcdf/$(F90)
  ifeq ($(F90),f95)
     FFLAGS   = -C=all -gline -nan -O4 -r8 -kind=byte\
	-mdir $(SRC)/seq   $(NCDFINC)
     F77FLAGS = -fixed -dusty
  endif
  ifeq ($(F90),g95)
     FFLAGS   = -O3 -r8  -fmod=$(SRC)/seq $(NCDFINC)
     F77FLAGS = -ffixed-form
  endif
  ifeq ($(F90),ifort)
     MPIF90   = mpif90
     FFLAGS   = -O3 -r8 -diag-disable remark -module $(SRC)/seq $(NCDFINC)
     F77FLAGS = -fixed
  endif
  NCDFLIB   = -L$(NCDF)/lib  -lnetcdf
  NCDFINC   = -I$(NCDF)/include
  LIBS      = $(NCDFLIB)
endif

LES_ARC_MPI=$(BIN)/libles_mpi.a
LES_OUT_MPI=$(BIN)/les.mpi

LES_ARC_SEQ=$(BIN)/libles_seq.a
LES_OUT_SEQ=$(BIN)/les.seq

default: mpi

all:  mpi seq

seq: $(LES_OUT_SEQ)

mpi: $(LES_OUT_MPI)

$(LES_OUT_SEQ): $(SRC)/LES.f90 $(LES_ARC_SEQ)  
	$(F90) $(FFLAGS) $(SEQFFLAGS) -o $@ $< $(LES_ARC_SEQ) $(LIBS)

$(LES_OUT_MPI): $(SRC)/LES.f90 $(LES_ARC_MPI)  
	$(MPIF90) $(FFLAGS) $(MPIFFLAGS) -o $@ $< $(LES_ARC_MPI) $(MPILIBS)

$(LES_ARC_SEQ): FORCE
	cd $(SRC) ; $(MAKE) LES_ARC=$(LES_ARC_SEQ) \
        FFLAGS='$(FFLAGS) $(SEQFFLAGS)' F90=$(F90) ARCHIVE='$(ARCHIVE)' \
	RANLIB=$(RANLIB) F77FLAGS='$(F77FLAGS)'

$(LES_ARC_MPI): FORCE
	cd $(SRC) ; $(MAKE) LES_ARC=$(LES_ARC_MPI) \
        FFLAGS='$(FFLAGS) $(MPIFFLAGS)' F90='$(MPIF90)' ARCHIVE='$(ARCHIVE)' \
	RANLIB='$(RANLIB)' F77FLAGS='$(F77FLAGS)'
#
# cleaning
# --------------------
#
clean: cleanmpi cleanseq 
	$(RM) $(SRC)/*mod $(SRC)/*.o

cleanmpi:
	$(ECHO) "cleaning mpi model"
	$(RM) core $(LES_OUT_MPI) $(SRC)/mpi/*mod $(LES_ARC_MPI)

cleanseq:
	$(ECHO) "clean sequential model"
	$(RM) core $(LES_OUT_SEQ) $(SRC)/seq/*mod $(LES_ARC_SEQ)

FORCE: 
.PRECIOUS: $(LIBS)
