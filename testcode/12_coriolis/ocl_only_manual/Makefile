# Points to Utility Directory
COMMON_REPO := $(AWS_FPGA_REPO_DIR)/SDAccel/examples/xilinx_2018.2
## COMMON_REPO = ../../../
ABS_COMMON_REPO = $(shell readlink -f $(COMMON_REPO))

include ./utils.mk
# Run Target:
#   hw  - Compile for hardware
#   sw_emu/hw_emu - Compile for software/hardware emulation
# FPGA Board Platform (Default ~ vcu1525)

TARGETS := hw
TARGET := $(TARGETS)
#DEVICES := xilinx_vcu1525_dynamic
DEVICES := xilinx_aws-vu9p-f1-04261818_dynamic_5_0
DEVICE := $(DEVICES)
XCLBIN := ./xclbin
DSA := $(call device2sandsa, $(DEVICE))



CXX := $(XILINX_SDX)/bin/xcpp
XOCC := $(XILINX_SDX)/bin/xocc

CXXFLAGS := $(opencl_CXXFLAGS) -Wall -O0 -g -std=c++14
LDFLAGS := $(opencl_LDFLAGS)

HOST_SRCS = src/main.c


# Host compiler global settings
CXXFLAGS = -I $(XILINX_SDX)/runtime/include/1_2/ -I/$(XILINX_SDX)/Vivado_HLS/include/ -O0 -g -Wall -fmessage-length=0 -std=c++14
LDFLAGS = -lOpenCL -lpthread -lrt -lstdc++ -L$(XILINX_SDX)/runtime/lib/x86_64

# WN: From 2018.2 template
SDX_PLATFORM = xilinx_aws-vu9p-f1-04261818_dynamic_5_0
CXXFLAGS += -DSDX_PLATFORM=$(SDX_PLATFORM)
# \WN

# Kernel compiler global settings
CLFLAGS = -t $(TARGET) --platform $(DEVICE) --save-temps 

EXECUTABLE = host

EMCONFIG_DIR = $(XCLBIN)/$(DSA)

BINARY_CONTAINERS += $(XCLBIN)/oclComputeKernel.$(TARGET).$(DSA).xclbin
BINARY_CONTAINER_vector_addition_OBJS += $(XCLBIN)/oclComputeKernel.$(TARGET).$(DSA).xo

#Include Libraries
include $(ABS_COMMON_REPO)/libs/opencl/opencl.mk
include $(ABS_COMMON_REPO)/libs/xcl2/xcl2.mk
CXXFLAGS += $(xcl2_CXXFLAGS)
LDFLAGS += $(xcl2_LDFLAGS)
HOST_SRCS += $(xcl2_SRCS)

CP = cp -rf

.PHONY: all clean cleanall docs emconfig
all: $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig

.PHONY: exe
exe: $(EXECUTABLE)

# Building kernel
$(XCLBIN)/oclComputeKernel.$(TARGET).$(DSA).xo: ./src/oclComputeKernel.cl
	mkdir -p $(XCLBIN)
	$(XOCC) $(CLFLAGS) -c -k oclComputeKernel -I'$(<D)' -o'$@' '$<'

$(XCLBIN)/oclComputeKernel.$(TARGET).$(DSA).xclbin: $(BINARY_CONTAINER_vector_addition_OBJS)
	$(XOCC) $(CLFLAGS) -l $(LDCLFLAGS) --nk oclComputeKernel:1 -o'$@' $(+)

# Building Host
$(EXECUTABLE): $(HOST_SRCS) $(HOST_HDRS)
	mkdir -p $(XCLBIN)
	$(CXX) $(CXXFLAGS) $(HOST_SRCS) $(HOST_HDRS) -o '$@' $(LDFLAGS)

emconfig:$(EMCONFIG_DIR)/emconfig.json
$(EMCONFIG_DIR)/emconfig.json:
	emconfigutil --platform $(DEVICE) --od $(EMCONFIG_DIR)

check: all
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE)
else
	 ./$(EXECUTABLE)
endif
	sdx_analyze profile -i sdaccel_profile_summary.csv -f html

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE) $(XCLBIN)/{*sw_emu*,*hw_emu*} 
	-$(RMDIR) sdaccel_* TempConfig system_estimate.xtxt *.rpt
	-$(RMDIR) src/*.ll _xocc_* .Xil emconfig.json dltmp* xmltmp* *.log *.jou *.wcfg *.wdb

cleanall: clean
	-$(RMDIR) $(XCLBIN)
	-$(RMDIR) ./_x

.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to generate the design for specified Target and Device."
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO) "  make check TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) ""

docs: README.md

README.md: description.json
	$(ABS_COMMON_REPO)/utility/readme_gen/readme_gen.py description.json





##############################################################################################
##############################################################################################
##############################################################################################
# 2017.4 template
##############################################################################################
##############################################################################################
##############################################################################################
## COMMON_REPO := $(AWS_FPGA_REPO_DIR)/SDAccel/examples/xilinx_2018.2
## #COMMON_REPO := $(AWS_FPGA_REPO_DIR)/SDAccel/examples/xilinx_2017.4
## #COMMON_REPO := ../../..
## 
## #Common Includes
## include $(COMMON_REPO)/utility/boards.mk
## include $(COMMON_REPO)/libs/xcl2/xcl2.mk
## include $(COMMON_REPO)/libs/opencl/opencl.mk
## 
## # Host Application
## host_SRCS=./src/main.c $(oclHelper_SRCS) $(xcl2_SRCS)
## host_HDRS=$(xcl2_HDRS)
## host_CXXFLAGS=-I./src/ $(opencl_CXXFLAGS) $(xcl2_CXXFLAGS) $(oclHelper_CXXFLAGS) -std=c++0x
## host_LDFLAGS=$(opencl_LDFLAGS)
## EXES=host
## 
## 
## # Kernel
## computeKernel_SRCS=./src/oclComputeKernel.cl
## 
## XOS=oclComputeKernel
## 
## computeKernel_XOS=oclComputeKernel
## 
## XCLBINS=oclComputeKernel
## 
## #computeKernel_KERNEL := computeKernel
## 
## #EXTRA_CLEAN=tmp_kernel_pack* packaged_kernel* $(computeKernel_KERNEL).xo
## 
## # check
## check_EXE=host
## check_XCLBINS=oclComputeKernel
## #check_NTARGETS=$(computeKernel_NTARGETS)
## 
## CHECKS=check
## 
## include $(COMMON_REPO)/utility/rules.mk
