#!/bin/bash -x

#Run this script to build the aocx file (with HDL lib)
#Note that you cannot RUN this build as this is emulation, and that is not exectuable when using an HDL lib
#So the only purpose for running this would be to test syntax

echo -e "** Did you run the script with 2 dots? **"
echo -e "================================="
echo -e "Building Kernel"
echo -e "================================="
aoc -v --report -march=emulator kernels.cl
echo -e "================================="
echo -e "Building Host"
echo -e "================================="
make --directory host
echo -e "================================="
echo -e "Executing"
echo -e "================================="
cp kernels.aocx host
cd host
env CL_CONTEXT_EMULATOR_DEVICE_ALTERA=1 ./host kernels.aocx
cd ..
