#!/bin/bash

#echo "enter the openwrt codename"
#read owrtv
#OWRTPATH=openwrt
#IBPATH=../../../openwrt/$owrtv/bin/ar71xx/
echo "Before running this script, you should update your Openwrt source"
#echo "./scripts/feeds update -a"
echo "from the source directory"
echo "WARNING. THIS SCRIPT WILL IRREVOCABLY CHANGE YOUR SOURCE DIRECTORY!!"
sleep 1;

here=$(pwd) #svn/fabfi/trunk/scripts/

#
echo "enter path to the contents of your source directory (no trailing /)"
read IBPATH

cd ../
IBMake=$(pwd)/openwrt

cd ${IBPATH}
cp -a ${IBMake}/.config ${IBPATH}/
cp -a ${IBMake}/feeds.conf.default ${IBPATH}/
cd $here
echo "now go back to the openwrt source and run"
echo "./scripts/feeds update -a"
#note: to make building source less of a huge pain, we need to only install te stuff that's actually needed
echo "./scripts/feeds install"
echo "make V=99"
sleep 5

