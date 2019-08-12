#!/bin/bash
#expects the AFI ID to be passed as argument
aws ec2 describe-fpga-images --fpga-image-ids $1
