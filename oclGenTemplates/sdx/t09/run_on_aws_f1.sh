make host
sudo -E sh #-E ensures we keep env variables
export VIVADO_TOOL_VERSION=2018.2
source $AWS_FPGA_REPO_DIR/sdaccel_runtime_setup.sh 
./host xclbin/*.awsxclbin

#source /opt/Xilinx/SDx/2017.4.rte.dyn/setup.sh 
