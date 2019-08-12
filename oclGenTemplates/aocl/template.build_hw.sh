#!/bin/bash -x

#Run this script to build the aocx file (with HDL lib)

echo -e "** Did you run the script with 2 dots? **\n"
echo -e "================================"
echo -e "Making lib"
echo -e "================================="
perl make_lib.pl
echo -e "================================="
echo -e "Building Kernel"
echo -e "================================="
aoc -v --profile --report --board p385_hpc_d5 -l hdl_lib.aoclib -L lib -I lib  -DAOCLIB kernels.cl
echo -e "================================="
echo -e "Building Host\n"
echo -e "================================="
make --directory host
echo -e "================================="
echo -e "Executing\n"
echo -e "================================="
mv kernels.aocx host

