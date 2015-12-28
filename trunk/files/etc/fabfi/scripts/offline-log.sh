#!/bin/ash
if [ $(date +%s) -gt "1329593199" ] ; then

	/usr/bin/lua /etc/fabfi/scripts/wlan_status.lua
	
	/bin/ash /etc/fabfi/scripts/iface_graphs.sh


fi
