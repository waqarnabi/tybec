make check TARGETS=hw_emu DEVICES=$AWS_PLATFORM_DYNAMIC_5_0 all
env XCL_EMULATION_MODE=hw_emu ./host xclbin/*.xclbin