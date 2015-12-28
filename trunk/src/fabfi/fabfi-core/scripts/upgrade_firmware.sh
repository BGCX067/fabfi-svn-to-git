#!/bin/ash


platform=`uci get fabfi.@node[0].platform`
upgradeURL=`uci get fabfi.@servers[0].updateserver`

preupgrade="pre-upgrade.sh"
 
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


#Get the preupgrade script
wget -P /tmp $upgradeURL$preupgrade

#Download Image

wget -P /tmp $upgradeURL$image

#Run pre-upgrade

/bin/ash /tmp/$preupgrade

#Finaly do the upgrade.

sysupgrade /tmp/$image

