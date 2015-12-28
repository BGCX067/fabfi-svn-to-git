#!/bin/bash

#echo "enter the openwrt codename"
#read owrtv
#OWRTPATH=openwrt
#IBPATH=../../../openwrt/$owrtv/bin/ar71xx/

VER="4.0.0_RC2"

echo "WARNING, this script will forever change your imagebuilder!"
sleep 1;
until (echo $revok | grep "^[yn]$"); do
	echo "Did you sync trunk in your svn archive with svn update? (y/n)  If not, rev number will be marked as unverified."
	read revok
done

if [ $revok = "n" ]
then
	rev=${VER}.`svn info ../ | grep "Revision:" | sed 's/Revision: //'`U;
else
	rev=${VER}.`svn info ../ | grep "Revision:" | sed 's/Revision: //'`;
fi

echo "pick a profile (and you'd better spell it right or this thing blows up)"
read profile

here=$(pwd) #svn/fabfi/trunk/scripts/

#
echo "enter path to the contents of the image builder directory (no trailing /)"
read IBPATH

#IBDIR='OpenWrt-ImageBuilder-ar71xx-for-Linux-i686'

cd ../
IBMake=$(pwd)/imagebuilder/target/linux/ar71xx/image/${profile}/Makefile

#rm -f ${IBPATH}/target/linux/ar71xx/profiles/${profile}.mk
#rm -f ${IBPATH}/target/linux/ar71xx/image/Makefile
rm -rf ${IBPATH}/fabfi


cp -f  $(pwd)/imagebuilder/target/linux/ar71xx/profiles/${profile}/* ${IBPATH}/target/linux/ar71xx/profiles/
cp -f $IBMake ${IBPATH}/target/linux/ar71xx/image/Makefile


#cp -a $(pwd)/files/router_configs/${profile} ${IBPATH}/fabfi/
mkdir ${IBPATH}/fabfi
cp -a $(pwd)/files/router_configs/${profile} /tmp/fabfi/
cp -a $(pwd)/files/router_configs/common/* /tmp/fabfi/
find /tmp/fabfi -name '.svn' -exec rm -rf {} \;
echo echo $rev >> /tmp/fabfi/etc/fabfi-scripts/version
cp -a /tmp/fabfi ${IBPATH}/

rm -rf /tmp/fabfi
#cp -a $(pwd)/files/router_configs/common/* ${IBPATH}/fabfi/${profile}



cd ${IBPATH}
make image PROFILE=${profile}
cd $here

#rm -f ${IBPATH}/target/linux/ar71xx/profiles/${profile}.mk
#rm -f ${IBPATH}/target/linux/ar71xx/image/Makefile
#rm -rf ${IBPATH}/fabfi

