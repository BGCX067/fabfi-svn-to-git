#!/bin/ash
if [ $(date +%s) -gt "1329593199" ] ; then

	/usr/bin/lua /usr/bin/fabfi/wlan_status.lua
	
	/bin/ash /usr/bin/fabfi/iface_graphs.sh


fi
