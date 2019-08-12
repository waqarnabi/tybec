#!/bin/bash -x

flopoco FPAdd 	frequency=300                     \
                wE=8 wF=23                        \
                pipeline=yes                      \
                target=Stratix5                   \
                outputFile=FPAddSingleDepth7.vhdl \
#                Testbench n=10 file=1

flopoco FPAdd 	frequency=300                     \
                wE=8 wF=23                        \
                pipeline=yes                      \
                target=Stratix5                   \
                sub=1                             \
                outputFile=FPSubSingleDepth7.vhdl \
 #               Testbench n=10 file=1

flopoco FPMult 	cleafrequency=300                   \
                wE=8 wF=23                          \
                pipeline=yes                        \
                target=Stratix5                     \
                outputFile=FPMultSingleDepth3.vhdl  \
#                Testbench n=10 file=1

flopoco FPDiv 	frequency=300                       \
                wE=8 wF=23                          \
                pipeline=yes                        \
                target=Stratix5                     \
                outputFile=FPDivSingleDepth12.vhdl  \
#                Testbench n=10 file=1



