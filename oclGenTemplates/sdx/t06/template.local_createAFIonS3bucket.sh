#!/bin/bash

## ASSUMPTIONS
#assuming binary is xclbin, and that there is JUST ONE binary there
#aws CLI installedc
#aws configure has been run successfully
#region           = eu-west-1

#bucket name      = tytrabucket4
#dcp-folder-name  = dcp
#s3_logs_key      = logs



cd xclbin
d=$(date +%Y-%m-%d)

#locate binary
f=$(find . -name \*.xclbin)
ft=$(echo $f | sed 's/\.\///')

#create output filename (without ext)
#o="$d"_"$ft"
o="$ft"
o=$(echo $o | sed 's/\.xclbin//')

#bucket variables
bucket="tytrabucket4"
dcp="dcp"
logs="logs"

#command
$SDACCEL_DIR/tools/create_sdaccel_afi.sh -xclbin=$f -o=$o -s3_bucket=$bucket -s3_dcp_key=$dcp -s3_logs_key=$logs

cd ..