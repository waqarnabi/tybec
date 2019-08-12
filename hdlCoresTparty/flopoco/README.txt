WN, Glasgow, 2018.03.16:

* This simple testbench tests floating point adder generated from Flopoco.

* Other FP units are also in this folder but not tested yet.

* flopoco currently works only on:
+ neoch-ubuntu where these units were generated from the generate script in this folder
+ now also added to the micron machine on rantau (micron@rantau, hmc4...)

* Version used on RANTAU (along with the installation script used on it)
http://flopoco.gforge.inria.fr/install_scripts/install-plain-4.1.2-on-xenial64.sh

yes | sudo apt-get update && sudo apt-get install g++ libgmp3-dev libmpfr-dev libfplll-dev libxml2-dev bison libmpfi-dev flex cmake libboost-all-dev libgsl0-dev

wget https://gforge.inria.fr/frs/download.php/33151/sollya-4.1.tar.gz   && tar xzf sollya-4.1.tar.gz && cd sollya-4.1/   && ./configure && make  && sudo make install   && cd ..

wget   https://gforge.inria.fr/frs/download.php/file/37213/flopoco-4.1.2.tgz   && tar xzf flopoco-4.1.2.tgz && cd flopoco-4.1.2/  && cmake . && make

# build the html documentation in doc/web. 
./flopoco BuildHTMLDoc

# Pure luxury: bash autocompletion. This should be called only once
./flopoco BuildAutocomplete
mkdir ~/.bash_completion.d/
mv flopoco_autocomplete ~/.bash_completion.d/flopoco
echo ". ~/.bash_completion.d/flopoco" >> ~/.bashrc

# Now show the list of operators
./flopoco  






(see http://flopoco.gforge.inria.fr/flopoco_installation.html)

* the simulation was done on my (WN) laptop, on xilinx ISE as modelsim does not support mixed language simulation in its free version.

* some generated cores were manually modified to create correct stall behaviour

Available cores, and their Cost/Peformance Estimates:
-----------------------------------------------------

[The resource/cycle estimates are taken for a f of between 200-300 MHz
which is where most tybec designs seem to converge. The litertaure quotes
implementations at different frequences as well though].

+ For FPadd, mul, sub
  - I have performed empirical tests (synth locally) and added them to tybec 
  - Pipelined
  - CPO (Cycles per output) = 1

+ FPDiv
  - 
  
+ Exp
  - Ref: http://perso.citi-lab.fr/fdedinec/recherche/publis/2010-FPT-Exp.pdf
  - Pipelined
  - CPO = 1 (Not synth and checked though, but lit indicates this)

+ LOG 
  - https://hal-ens-lyon.archives-ouvertes.fr/ensl-00506122/document
  - ITERATIVE (so CPO is > 1, not pipelined)
  On Virtex 4
    - (8, 23) (single precision) 601 slices, 5 DSP48, 3 RAMB16 17 cycles @ 250 MHz
    - (11,52) (double precision) 1780 slices, 14 DSP48, 21 RAMB16 29 cycles @ 176 MHz
  
+ Cordic Sin/Cos
  - http://perso.citi-lab.fr/fdedinec/recherche/publis/2013-HEART-SinCos.pdf
  - Multiple options explored, I am for now focusing on the "reduced iterations cordic"
  - On virtex 5:
    - Precision = 24 bits (~SP) :: 23 cycles, 1721 + 2114 (Reg + LUTs)

+ Power
  - http://perso.citi-lab.fr/fdedinec/recherche/publis/2013-TRETS-Exponentiation.pdf
  - Based on Log, which is iterative, so overall iterative
  - On Stratix  - V 
  - (8,23)  = 27 cycles, (Regs+Slices BRAMs DSP48) = 1260R + 1828L 7  11
  - (11,52) = 77 cycles, (Regs+Slices BRAMs DSP48) = 5675R + 6153L 20 42

  




<OBSOLETE>
* Version used on RANTAU (along with the installation script used on it)

Version 2.3.2, the last version before the Great Leader embarked the project in the bit heap hazardous adventure
TODO: wrap this in a virtual machine for future generations.

$ yes | sudo apt-get install g++ libgmp3-dev libmpfr-dev libxml2-dev bison libmpfi-dev flex cmake libboost-all-dev libgsl0-dev && wget https://gforge.inria.fr/frs/download.php/file/34429/libfplll-3.0.12.tar.gz && tar xzf libfplll-3.0.12.tar.gz && cd libfplll-3.0.12/ && ./configure && make -j2 && sudo make install && cd .. && wget https://gforge.inria.fr/frs/download.php/28571/sollya-3.0.tar.gz && tar xzf sollya-3.0.tar.gz && cd sollya-3.0/ && ./configure && make -j4 && sudo make install && cd .. && wget https://gforge.inria.fr/frs/download.php/file/35206/flopoco-2.3.2.tgz && tar xzf flopoco-2.3.2.tgz && cd flopoco-2.3.2/ && cmake . && make -j4 && ./flopoco
<\OBSOLETE>
