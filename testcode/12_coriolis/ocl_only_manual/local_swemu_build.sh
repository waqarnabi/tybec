make check TARGETS=sw_emu DEVICES=$AWS_PLATFORM_DYNAMIC_5_0 all
env XCL_EMULATION_MODE=sw_emu ./host xclbin/*.xclbin
