#!/bin/sh
#$1 = name of this project, which will be the name of the folder created in the target parent directory


if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters. \$1 = name of this project, which will be the name of the folder created in the target parent directory"
    return
fi
project_name=${1}

#paramters
local_target="/home/tytra/Work/_TyTra_BackEnd_Compiler_/TyBEC/testcode/_git_awscode_/awsCode"
exec="host" #name of host binary to copy (if it exists)
gitrepo="https://github.com/waqarnabi/awsCode.git"

#create targer directory and sub-directories. Parent folder hardwired
target_dir="$local_target/$project_name"

mkdir -p $target_dir
mkdir -p $target_dir/xclbin
mkdir -p $target_dir/src

#copy in awsxclbin, scripts, xml, Makefile, and .c/cpp files (and exec named "host" if it exists)
cp *.sh $target_dir/
cp *.txt $target_dir/
cp *.json $target_dir/
cp xclbin/*awsxclbin $target_dir/xclbin
cp Makefile $target_dir/
cp src/*.xml $target_dir/srcsour
cp src/*.c* $target_dir/src
if [ -f $exec ]; then
  cp host $target_dir
fi  

#commit to git
current_dir=$(pwd)
cd $target_dir/..
git add .
git commit -m "Adding $target_dir"
git push origin master
cd $current_dir