#!/bin/sh
#WN, 2019.04.02, convenience script to run AFTER synthesis has completed
# use it to:
# + create AFI
# + The script loops (infinitely) to check status of AFI creation, you will have to 
# manually stop it 
# TODO: Make it stop automatically when AFI creation successful.

# You must have SDx installed and in path, and have run the sdaccel setup script
# that comes with the aws

#input arguments
#$1 = xcl binary file name

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters. xcl binary file must be passed as the first (and only) argument"
    return
fi

## Get file root ##
xcl_bin=$1
xcl_bin_root="${1%.*}"

## build AFI image ##
info_msg "calling create_sdaccel_afi.sh"
$SDACCEL_DIR/tools/create_sdaccel_afi.sh\
    -xclbin=$xcl_bin\
    -o=$xcl_bin_root\
		-s3_bucket=tytrabucket4 -s3_dcp_key=dcp -s3_logs_key=logs
		
## check the status of the AFI ##

#pick the first file it sees with *_afi_id.txt, so you shouldn only have
#one of these
afi_file="$(find . -name "*_afi_id.txt")"

#get second line, which has AFI_ID
line="$(sed -n '2p' < $afi_file)" 

# with quotes set as delimiter, get the appropriat string against AFI_ID
IFS='"' 
read -ra ADDR <<< "$line"
afi_id="${ADDR[3]}"

# check status infinitely, every 10 seconds
while :
do
  info_msg "Checking status of AFI with AFI_ID = $afi_id"
  aws ec2 describe-fpga-images --fpga-image-ids	$afi_id
  info_msg "I will continue checking. Press [CTRL+C] to stop when you see \"Code\": \"available\""
	sleep 10
done

info_msg "Command to check manually: aws ec2 describe-fpga-images --fpga-image-ids  $afi_id"


