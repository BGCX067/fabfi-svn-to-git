#!/bin/ash

latlonfile=/var/run/latlon-bc.js
olsr_info_file=/tmp/olsr.info

self_ip=$( cat $latlonfile | grep -i self | cut -d "(" -f 2 | cut -d "," -f 1 | tr -d "'" )

olsr_neigh_ips=`cat ${olsr_info_file} | cut -f 2`

remote_ip()
{
for i in $olsr_neigh_ips 
do 
	# forces communication so as to insert entries into ip -6 neigh show
	ping -c 1 -s 1 $i  >> /dev/null
	cat $latlonfile | grep -i mid | grep "$i" | cut -d "'" -f 2  
done
}

#Since we are only interested in OLSR main IPs

remote_ip=$( remote_ip )

#Node's own coordinates
my_lat=`/sbin/uci -q get olsrd.@LoadPlugin[1].lat`
my_lon=`/sbin/uci -q get olsrd.@LoadPlugin[1].lon`

#Node details

nodeType=`/sbin/uci -q get fabfi.@node[0].nodeType`

get_neigh_longitude()
{
#Require's node IP address
node_ip=$1
cat $latlonfile | grep  "'$node_ip','$self_ip'" | cut -d "," -f 7
}

get_neigh_latitude()
{
node_ip=$1
cat $latlonfile | grep  "'$node_ip','$self_ip'" | cut -d "," -f 6

}


case $1 in

	lat )
		echo ${my_lat}
		;;
	lon )
		echo ${my_lon}
		;;
        coords )
               
                echo "${my_lat}, ${my_lon}"
                ;;
	node_type )
		echo $nodeType
		;;

	fabfinumber )

		/sbin/uci -q get fabfi.@node[0].fabfiNumber
		;;
	self_ip )
		echo $self_ip                                	
		;;

	neigh_ip )
		for i in ${remote_ip}
		do
			echo $i
		done
		;;
		
	neigh_hostname )
		cat $latlonfile | grep -i node | cut -d "," -f 6 | cut -d ")" -f 1 | tr -d "'"
		;;

	neigh_lat )
		for i in ${remote_ip}
		do
			get_neigh_latitude $i
		done
		;;

	neigh_lon )
                for i in ${remote_ip}
		do
			get_neigh_longitude $i
		done
                ;;
	neigh_lq )
		cat ${olsr_info_file} | cut -f 4
		;;
	neigh_nlq )
		cat ${olsr_info_file} | cut -f 5 
		;;
	neigh_cost )
		cat ${olsr_info_file} | cut -f 6 
		;;
	wifi_interfaces )
		iw dev | grep phy | wc -l
		;;

	wifi_clients )

		wifi_clients_mac=$( iw dev wlan$2 station dump | grep Station | cut -d " " -f 2 | tr '\n' ' ' )

		for i in $wifi_clients_mac
		do
			#get IP address from MAC
			address=$( ip -6 neigh  show | grep -i $i | grep 2001 | cut -d " " -f 1 )
			if [ "$address" == "" ]; then 
				echo $i		 	
		 	else
			 	#convert to main IP
			 	cat $latlonfile | grep -i mid | grep "$address" | cut -d "'" -f 2
			fi
		done
		;;
	avg_signal )
		iw dev wlan$2 station dump | grep "signal avg" | cut -d ":" -f 2 | tr -d "\t" | cut -d " " -f 1
		;;
	tx_bitrate )
		iw dev wlan$2 station dump | grep -i "tx bitrate" | cut -d ":" -f 2 | cut -d " " -f 1 | tr -d "\t"
		;;
	rx_bitrate )
		iw dev wlan$2 station dump | grep -i "rx bitrate" | cut -d ":" -f 2 | cut -d " " -f 1 | tr -d "\t"
		;;
	node_info )
		cat /root/Node_Info | tr '\n' '%' | sed s/%$//
		;;

esac
