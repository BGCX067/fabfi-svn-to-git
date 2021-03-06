#!/bin/sh

# for running on systems without the freifunk firmware you need to setup
# some parameters
# nodeCorrds are the longitude and the latitude, for example "43.2323232, 12.3245934"
# the note you wish to place in the map
include fabfimap.cfg
# updateIntervall should be a value between minute | hourly | daily | monthly
# this defined the lifetime of the node in the map ( lifetime = 2 * updateIntervall)
updateIntervall="minute"
# mapServer is the URL of the mapServer, for example "http://www.layereight.de/freifunkmap.php"
mapServer="http://map.mesh/live/index.php"
# httpInfoPlugin configures the URL and the port of the olsr node with running httpInfoPlugin
# you wish to update, that must not be the same where this script is running, but the neighbour 
# nodes should be accessebil from this node
httpInfoPlugin=""
# like httpInfoPlugin but for nodes with running textInfoPlugin
textInfoPlugin="http://127.0.0.1:2006"

## self settings of parameters
wget=`which wget`

# this works only with a global variable uriComponent
# because the return value can't be something like %20 so I think
encodeURIComponent( ) {
	lines=`echo -e "$uriComponent" | wc -l `
	N=1
	while [ $N -lt $lines ] ; do
 		N=$(( $N + 1))
		NN=`echo -e "N;$NN"`
	done
	
	# first replace all linefeeds if any exists
	if [ 1 -lt $lines ]; then
		uriComponentTmp=`echo "$uriComponent" | sed -r '$NN s/
\n/%0D/g'`
		uriComponent=$uriComponentTmp
	fi
	# then the other symbols
	uriComponentTmp=`echo "$uriComponent" | sed 's/\ /%20/g'`
	uriComponent=$uriComponentTmp
}

update () {
	# only one instance should be running at time
	# if exists an other one kill them and all wgets
	pid="$(cat /tmp/freifunkmap.pid 2> /dev/null)"
	if [ ! -z $pid ]; then
		kill $pid >/dev/null 2> /dev/null
		# killall wget
	fi

	# get rid of wget-s hanging arround
	for f in /proc/*/cmdline; do
		if grep -sq '^wget .*/mygooglemapscoords.txt' "$f"; then
			WGET_PID="${f#/proc/}"; WGET_PID="${WGET_PID%%/*}"
			kill "${WGET_PID}" 2>/dev/null
		fi
	done
	
	echo "$$" > /tmp/freifunkmap.pid
	
	updatestring=$nodeCoords
	parse=1

	# set up the updateintervall
	map_updateintervall=$updateIntervall
	if [ "$map_updateintervall" = "minute" ]; then
		updateiv=60
	elif [ "$map_updateintervall" = "hourly" ]; then
		updateiv=3600
	elif [ "$map_updateintervall" = "daily" ]; then
		updateiv=86400
	elif [ "$map_updateintervall" = "monthly" ]; then
		updateiv=2592000
	fi

	cnt=0
	row=0
	lq=""

	if [ $httpInfoPlugin ]; then
		# get the neighbors info from the olsrd http info plugin
		parse="off"
		
		for i in `$wget $httpInfoPlugin/nodes -qO -`; do
			if [ "`echo $i | sed -r 's/<h2>Links.*/parseon/'`" = "parseon" ]; then
				parse="on"
			elif [ "`echo $i | sed -r 's/<h2>Topology.*/parseoff/'`" = "parseoff" ]; then
				parse="off"
			fi
			
			if [ "$parse" = "on" ]; then
				ip=`echo $i | grep -E "<tr><td>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}</td><td>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
				if [ $ip ]; then 
					nip=`echo $i | sed -r 's/<tr><td>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}<\/td><td>([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/'`
					lq=`echo $i | sed -r 's/^<tr><td>(.*<\/td><td>){3}([0-9]\.[0-9]{2})(<\/td><td>.*){3}/\2/'`
					# if possible get the googlemaps coords from the neighbor and add
					# it to the updatestring for the freifunk map
					ncoords="`wget http://$nip/mygooglemapscoords.txt -qO - 2> /dev/null`"
					if [ ! -z "$ncoords" ]; then
						updatestring=`echo $updatestring, $ncoords, $lq`
					fi
					nip=""
					lq=""
				fi
			fi
		done
	elif [ $textInfoPlugin ]; then
		# get the neighbors info from the olsrd text info plugin
		for i in `$wget $textInfoPlugin/neighbours -qO -`; do
			ip=`echo $i | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
			if [ ! -z "$ip" ]; then
				cnt=$(( $cnt + 1 ))
				if [ $cnt -eq 2 ]; then
					nip=$ip
					cnt=0
					row=2
				fi
			else
				cnt=0
			fi

			if [ $row -gt 1 ]; then
				row=$(( $row + 1 ))
			fi
			if [ $row -eq 5 ]; then
				lq=$i
				row=0
			fi
   
			if [ ! -z $nip ]; then
				if [ ! -z $lq ]; then
					# if possible get the googlemaps coords from the neighbor and add
					# it to the updatestring for the freifunk map
					ncoords="`wget http://$nip/mygooglemapscoords.txt -qO - 2> /dev/null`"
					if [ ! -z "$ncoords" ]; then
						updatestring=`echo $updatestring, $ncoords, $lq`
					fi
					nip=""
					lq=""
				fi
			fi
		done
	fi

	# before exiting send the updatestring to the mapserver
	update=`echo "$updatestring" | sed s/\ /%20/g`
	uriComponent=$updatestring
	encodeURIComponent
	update=$uriComponent

	uriComponent=$note
	encodeURIComponent	                                                                        
	note=$uriComponent

	wget "$mapServer?update=$update&updateiv=$updateiv&note=$note" -qO - > /dev/null 2> /dev/null
	
	# everything looks fine
	rm /tmp/freifunkmap.pid
}

case "$1" in
	update)
		update
	;;
	*)
    echo "Usage: $0 {update}"
    exit 1
  ;;
esac

