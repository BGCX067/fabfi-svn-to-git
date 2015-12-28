#!/bin/ash
platform=`uci get fabfi.@node[0].platform`
upgradeURL=`uci get fabfi.@servers[0].updateserver`

cd /tmp

case $platform in

	UbiquitiRouterStation )
	image=fabfi-rs-sysupgrade.bin
	;;

	UbiquitiRouterStationPro )
	image=fabfi-rs_pro-sysupgrade.bin
	;;

	UbiquitiNanoStationM )
	image=fabfi-nanom-sysupgrade.bin
	;;

esac

if [ -f /tmp/$image ] ; then rm -f /tmp/$image; fi

wget -P /tmp $upgradeURL$image

sysupgrade /tmp/$image

