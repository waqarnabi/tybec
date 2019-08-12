package HardwareSpecs;
use strict;
use warnings;

use Exporter qw( import );
our @EXPORT = qw( %devices %boards %nodes);
use POSIX;

# ============================================================================
# Notes
# ============================================================================
# theoMaxBops: (planned but not included)
#   This is the maximum theoretical Byte-ops-per-sec for a device
#   It is calculted by assuming a simple, registered, byte-wide AND operation
#   as the basic unit, scaled until it fills 80% of the FPGA. 
#   and working at the frequency as reported by the synth tool when synth
#   for just of these basic units...
#   The therotical limit is simply to give a perspective on the device 
#   capability. Practically, it is unacheivable. 
#
#   StratixV_GS_D5:
#     unit LE/LUT = 8     
#     unit Regs   = 8
#     freq        = 300 MHZ (rough av from synth experiments)
#     max LE      = 457000 (we take 80% of this)
#     max REGS    = 690400 
#     max Bops    = {(457000*0.8)/8} * 300e6
#                 = 13710 Giga-Byte-ops-per-sec <--- This is HUGE, and meaningless... Dont go there..
#
#
#
#
#
# ============================================================================

# ============================================================================
# Utility routines
# ============================================================================

sub log2 {
        my $n = shift;
        return ceil( log($n)/log(2));# + 0.99); #0.99 for CEIL operation
    }

# =========================
# DEVICES
# =========================
our %devices;

#DSPs figures are for 18x18 multiplier (0.5 for 27x27)

#the device for Cris's GPCE paper; check figures
#https://www.xilinx.com/support/documentation/selection-guides/cost-optimized-product-selection-guide.pdf#S6
$devices{Spartan6_XC6SLX75}
  = { 'Tech'      => '28nm'
    , 'ALMS'      => 11662
    , 'ALUTS'     => 46648  
    , 'LE'        => 11662
    , 'REGS'      => 93296 
    , 'DSPs'      => 132 
    , 'M20KBlocks'=> 0   #Stratix only
    , 'M20Kbits'  => 0   #Stratix only
    , 'MLABbits'  => 0   #Stratix only
    , 'BRAM36KbBlocks' => 0     #Virtex only
    , 'BRAM18KbBlocks' => 172  #18Kb each
    , 'BRAMbits'   => 3096000  #Virtex only
    , 'DistRAMbits'=> 0       #Virtex only
    , 'totalRAM'   => 3096000   
    , 'maxF_MHz'   => 500  #check
    , 'powAver_W'  => 20   #check
    };   

#the device for Cris's GPCE paper;  check figures
#https://www.xilinx.com/support/documentation/selection-guides/cost-optimized-product-selection-guide.pdf#S6
$devices{Spartan6_XC6SLX45}
  = { 'Tech'      => '28nm'
    , 'ALMS'      => 6822
    , 'ALUTS'     => 27288
    , 'LE'        => 6822
    , 'REGS'      => 54576
    , 'DSPs'      => 58 
    , 'M20KBlocks'=> 0   #Stratix only
    , 'M20Kbits'  => 0   #Stratix only
    , 'MLABbits'  => 0   #Stratix only
    , 'BRAM36KbBlocks' => 0     #Virtex only
    , 'BRAM18KbBlocks' => 116  #18Kb each
    , 'BRAMbits'   => 2088000  #Virtex only
    , 'DistRAMbits'=> 0       #Virtex only
    , 'totalRAM'   => 2088000   
    , 'maxF_MHz'   => 500  #check
    , 'powAver_W'  => 20   #check
    };   

#the device on the maxeler machine
$devices{StratixV_GS_D8}
  = { 'Tech'      => '28nm'
    , 'ALMS'      => 262800
    , 'ALUTS'     => 524800  
    , 'LE'        => 695000
    , 'REGS'      => 1049600 
    , 'DSPs'      => 4000 #check
    , 'M20KBlocks'=> 2576       #Stratix only
    , 'M20Kbits'  => 51000000   #Stratix only
    , 'MLABbits'  => 13120      #Stratix only
    , 'BRAM36KbBlocks' => 0     #Virtex only
    , 'BRAM18KbBlocks' => 0     #Virtex only
    , 'BRAMbits' => 0           #Virtex only
    , 'DistRAMbits'  => 0       #Virtex only
    , 'totalRAM'  => 59600000   
    , 'maxF_MHz'  => 500  #check
    , 'powAver_W' => 20   #check
    };   

#the device on the nallatech board
$devices{StratixV_GS_D5}
  = { 'Tech'      => '28nm'
    , 'ALMS'      => 172600
    , 'ALUTS'     => 345200  
    , 'aluts'     => 345200  
    , 'LE'        => 457000
    , 'REGS'      => 690400 
    , 'regs'      => 690400 
    , 'DSPs'      => 3000 #check
    , 'dsps'      => 3000 #check
    , 'M20KBlocks'=> 2014       #Stratix only
    , 'M20Kbits'  => 40000000   #Stratix only
    , 'bram'      => 40000000   #Stratix only
    , 'MLABbits'  => 8630       #Stratix only
    , 'BRAM36KbBlocks' => 0     #Virtex only
    , 'BRAM18KbBlocks' => 0     #Virtex only
    , 'BRAMbits' => 0           #Virtex only
    , 'DistRAMbits'  => 0       #Virtex only
    , 'totalRAM'  => 45600000
    , 'maxF_MHz'  => 500  #check
    , 'powAver_W' => 20   #check
    };   
    
#the device on the SDAccel board
$devices{Virtex7_XC7_VX69OT}
  = { 'Tech'      => '28nm'
    , 'ALMS'      => 261555 #calculated from ratios
                            #not relevant for Xilinx devices, and in any case not used
    , 'ALUTS'     => 523109 #calculated from ratios
    , 'LE'        => 457000 #This is exact figure from xilinx datasheet, called "Logic Cells",
                            #and maps 1-1 to Alteras LEs 
    , 'REGS'      => 866400    
    , 'DSPs'      => 3600 
    , 'M20KBlocks'=> 0            # Stratix only
    , 'M20Kbits'  => 0            # Stratix only
    , 'MLABbits'  => 0            # Stratix only
    , 'BRAM18KbBlocks' => 2940    #Virtex only
    , 'BRAM36KbBlocks' => 1470    #Virtex only
    , 'BRAMbits' => 52920000      #Virtex only
    , 'DistRAMbits'  => 10888000  #Virtex only
    , 'totalRAM'  => 52920000 #FIXME
    , 'maxF_MHz'  => 500  #check
    , 'powAver_W' => 20   #check
    };   
    
#todo: this is the device on AWS-F1; check resources availabel and update following    
$devices{ultrascale}
  = { 'Tech'      => '28nm'
    , 'ALMS'      => 172600
    , 'ALUTS'     => 345200  
    , 'aluts'     => 345200  
    , 'LE'        => 457000
    , 'REGS'      => 690400 
    , 'regs'      => 690400 
    , 'DSPs'      => 3000 #check
    , 'dsps'      => 3000 #check
    , 'M20KBlocks'=> 2014       #Stratix only
    , 'M20Kbits'  => 40000000   #Stratix only
    , 'bram'      => 40000000   #Stratix only
    , 'MLABbits'  => 8630       #Stratix only
    , 'BRAM36KbBlocks' => 0     #Virtex only
    , 'BRAM18KbBlocks' => 0     #Virtex only
    , 'BRAMbits' => 0           #Virtex only
    , 'DistRAMbits'  => 0       #Virtex only
    , 'totalRAM'  => 45600000
    , 'maxF_MHz'  => 500  #check
    , 'powAver_W' => 20   #check
    };   

# =========================
# BOARDS
# =========================
our %boards;

# numDevices           =     
# deviceName           = 
# boardRAM_banks       = Number of independent banks/channels
# boardRAM_perbank_GB  = 
# boardRAM_type        = [DDR3 | DDR4] etc.
# boardRAM_GB          = 
# boardRAMBW_MTps      = Mega Transfers per second
# boardRAMBW_Peak_Mbps = Channel width (bits/transfer) × transfers/second = bits transferred/second.
# boardRAMBW_Peak_MBps = Same as above, in Mega-Bytes-per-second
# boardRAMBW_Peak_Gbps = 
# boardRAMBW_Peak_GBps = 
# rho_g_contiguous     
# hostInterface        = 
# hostMaxBw_Gbps       = 
# hostMaxBw_GBps       = 
# hostMaxBw_Mbps       =      
# hostMaxBw_MBps       =



$boards{maxelerMaia}
  = { 'numDevices'          => 1 
    , 'deviceName'          => 'StratixV_GS_D8'
    , 'boardRAM_type'       => 'DDR3'
    , 'boardRAM_banks'      => 6   #check
    , 'boardRAM_perbank_GB' => 8   #check 
    , 'boardRAM_GB'         => 48     
    , 'boardRAMBW_MTps'     => 1300  #check
    , 'boardRAMBW_Peak_Mbps'=> (200*4*2*64) # =F * 4 (bus clock multiplier) * 2 (DDR) * 64
    , 'boardRAMBW_Peak_MBps'=> (200*4*2*64)/8
    , 'boardRAMBW_Peak_Gbps'=> (200*4*2*64)/(1000)
    , 'boardRAMBW_Peak_GBps'=> (200*4*2*64)/(8*1000)
    , 'hostInterface'       => 'pci2.0x8'
    , 'hostBW_Peak_Gbps'     => 32
    , 'hostBW_Peak_GBps'     => 4 
    , 'hostBW_Peak_Mbps'     => 32000
    , 'hostBW_Peak_MBps'     => 4000
    }; 
    
$boards{nallatech_385_D5}
  = { 'numDevices'          => 1 
    , 'deviceName'          => 'StratixV_GS_D5'
    , 'boardRAM_type'       => 'DDR3'
    , 'boardRAM_banks'      => 2   #check
    , 'boardRAM_perbank_GB' => 4   #check 
    , 'boardRAM_GB'         => 8   #check   
    , 'boardRAMBW_MTps'     => 1666
    , 'boardRAMBW_Peak_Mbps'=> 213248
    , 'boardRAMBW_Peak_MBps'=> 26656
    , 'boardRAMBW_Peak_Gbps'=> 208
    , 'boardRAMBW_Peak_GBps'=> 26
    , 'hostInterface'       => 'pci3.0x8'
    , 'hostBW_Peak_Gbps'    => 63
    , 'hostBW_Peak_GBps'    => 7 
    , 'hostBW_Peak_Mbps'    => 63000
    , 'hostBW_Peak_MBps'    => 7875
    }; 
    
$boards{alphadata_adm_pcie_7v3}
  = { 'numDevices'          => 1 
    , 'deviceName'          => 'Virtex7_XC7_VX69OT'
    , 'boardRAM_type'       => 'DDR3'
    , 'boardRAM_banks'      => 2   
    , 'boardRAM_perbank_GB' => 8
    , 'boardRAM_GB'         => 16
    , 'boardRAMBW_MTps'     => 1300
    , 'boardRAMBW_Peak_Mbps'=> 83200
    , 'boardRAMBW_Peak_MBps'=> 10400
    , 'boardRAMBW_Peak_Gbps'=> 83.2
    , 'boardRAMBW_Peak_GBps'=> 10.4
    , 'hostInterface'       => 'pci3.0x8'
    , 'hostBW_Peak_Gbps'     => 63
    , 'hostBW_Peak_GBps'     => 7 
    , 'hostBW_Peak_Mbps'     => 63000
    , 'hostBW_Peak_MBps'     => 7875
    };   
    

#todo: update these numbers, I just copy-pasted them
#also check info about devices/board

$boards{awsf1Board}
  = { 'numDevices'          => 1 
    , 'deviceName'          => 'ultrascale'
    , 'boardRAM_type'       => 'DDR3'
    , 'boardRAM_banks'      => 2   
    , 'boardRAM_perbank_GB' => 8
    , 'boardRAM_GB'         => 16
    , 'boardRAMBW_MTps'     => 1300
    , 'boardRAMBW_Peak_Mbps'=> 83200
    , 'boardRAMBW_Peak_MBps'=> 10400
    , 'boardRAMBW_Peak_Gbps'=> 83.2
    , 'boardRAMBW_Peak_GBps'=> 10.4
    , 'hostInterface'       => 'pci3.0x8'
    , 'hostBW_Peak_Gbps'     => 63
    , 'hostBW_Peak_GBps'     => 7 
    , 'hostBW_Peak_Mbps'     => 63000
    , 'hostBW_Peak_MBps'     => 7875
    };   

# =========================
# NODES
# =========================
our %nodes;

$nodes{philpotsMaxeler}
  = { 'numBoards'     => 1
    ,  'boardName'     => 'maxelerMaia'
    ,  'hostCpuDevice' => 'i7'
    ,  'hostCpuSockets'=> 1
    ,  'hostCpuCores'  => 4
    ,  'hostCpuRam_GB' => 32
    ,  'hdd_TB'        => 1
     };

$nodes{bolamaNallatech}
  = { 'numBoards'     => 1
    ,  'boardName'     => 'nallatech_385_D5'
    ,  'hostCpuDevice' => 'xeonE52609V2'
    ,  'hostCpuSockets'=> 2
    ,  'hostCpuCores'  => 8
    ,  'hostCpuRam_GB' => 64
    ,  'hdd_TB'        => 1
     };

$nodes{bolamaAlphadata}
  = { 'numBoards'     => 1
    ,  'boardName'     => 'alphadata_adm_pcie_7v3'
    ,  'hostCpuDevice' => 'xeonE52609V2'
    ,  'hostCpuSockets'=> 2
    ,  'hostCpuCores'  => 8
    ,  'hostCpuRam_GB' => 64
    ,  'hdd_TB'        => 1
     };
     
#todo: update the following information     
$nodes{awsf12x}
  = { 'numBoards'     => 1
    ,  'boardName'     => 'awsf1Board'
    ,  'hostCpuDevice' => 'xeonE52609V2'
    ,  'hostCpuSockets'=> 2
    ,  'hostCpuCores'  => 8
    ,  'hostCpuRam_GB' => 64
    ,  'hdd_TB'        => 1
     };
     
$nodes{awsf14x}
  = { 'numBoards'     => 4
    ,  'boardName'     => 'awsf1Board'
    ,  'hostCpuDevice' => 'xeonE52609V2'
    ,  'hostCpuSockets'=> 2
    ,  'hostCpuCores'  => 8
    ,  'hostCpuRam_GB' => 64
    ,  'hdd_TB'        => 1
     };     

$nodes{awsf116x}
  = { 'numBoards'     => 16
    ,  'boardName'     => 'awsf1Board'
    ,  'hostCpuDevice' => 'xeonE52609V2'
    ,  'hostCpuSockets'=> 2
    ,  'hostCpuCores'  => 8
    ,  'hostCpuRam_GB' => 64
    ,  'hdd_TB'        => 1
     };     

