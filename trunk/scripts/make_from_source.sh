#!/bin/bash

here=$(pwd)

echo "Enter the location of your OpenWrt source directory"
read DIR

DIR=$(readlink -f ${DIR} )

if [ -d ${DIR}/target/linux/ar71xx/base-files/etc/ ]; then

	cp -a ../files/etc/ ${DIR}/target/linux/ar71xx/base-files/ -R

	find ${DIR}/target/linux/ar71xx/base-files/etc/fabfi/ -name ".svn" -print0 | xargs -0 -I svn rm -rf svn

	cp -a ../openwrt/config ${DIR}/.config

	cd ../
	svn info > ${DIR}/target/linux/ar71xx/base-files/etc/fabfi/files/fabfi_info

	cd ${DIR}

	svn info > target/linux/ar71xx/base-files/etc/fabfi/files/openwrt_info

	if [ ! -h target/linux/ar71xx/base-files/setup  ]; then
		ln -s /etc/fabfi/scripts/setup.sh target/linux/ar71xx/base-files/setup
	fi

	if [ ! -h target/linux/ar71xx/base-files/setup2  ]; then
		ln -s /etc/fabfi/scripts/setup2.sh target/linux/ar71xx/base-files/setup2
	fi
	make -j 8 V=99

	if [ ! -d $DIR/latest-images/ ]; then mkdir $DIR/latest-images ; fi

	find bin/ar71xx -name \*ubnt-rs* -print0 -o -name \*ubnt-nano* -print0 | xargs -0 -I imgs cp imgs latest-images/
	echo "RS, RSPRO and NanoStation images have been placed in ${DIR}/latest-images"

else

	echo "Something is wrong with your openwrt directory - check then run the script again"

fi
