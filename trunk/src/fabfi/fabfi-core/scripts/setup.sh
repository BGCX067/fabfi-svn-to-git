#/bin/ash

#Some global variables
story=""
number=""
mapserver="map.mesh"
updateserver="http://fabfi.googlecode.com/files/"
default_key="8bb8d3c8d3dabbedffd38db33f"

client_lan_suffix=129
client_lan_index=0

#Global Functions

check_latlon()
{

latlonRegex="\b(-?[0-9]{1,3}\.[0-9]{1,16})\b"

check=$(echo $1 | egrep $latlonRegex)

if [ "$check" == "$1" ];
then
	echo "ok"
else
	echo "Invalid coordinate entry"
fi

}

check_ipv4_address()
{

ipv4regex='\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'

check=$(echo $1 | egrep $ipv4regex)

if [ "$check" == "$1" ];
then
	echo "ok"
else
	echo "Incorrect IP address"
fi

}


generic_configs()
{

touch /etc/config/fabfi
uci add fabfi node
uci add fabfi servers
uci set fabfi.@servers[0].mapserver=$mapserver
uci set fabfi.@node[0].mapUpdateInterval=180
uci set fabfi.@node[0].headnode=0
uci set fabfi.@servers[0].updateserver=$updateserver

platform2=$(echo $platform | tr -d " ")
uci set fabfi.@node[0].platform=${platform2}

echo > /etc/rc.local

echo "Enter fabfi number"
read number

uci set fabfi.@node[0].fabfiNumber=${number}

story="${story} Fabfi number : ${number} \n"

echo "Enter your 48 or 64-bit IPv6 prefix (e.g 2001:470:6826 There's no check on this text)"
read prefix
story="${story} IPv6 prefix : ${prefix}\n"

hexno=`printf "%x\n" ${number}`
uci set system.@system[0].hostname=schoolnet${number}

uci set network.mesh.proto=static
uci set network.mesh.ipaddr=10.0.${number}.1
uci set network.mesh.netmask=255.255.255.240
uci set network.mesh.ip6addr=${prefix}:${number}::1/128

uci set network.niit6to4=interface
uci set network.niit6to4.proto=none
uci set network.niit6to4.ifname=niit6to4
uci set network.niit4to6=interface
uci set network.niit4to6.proto=none
uci set network.niit4to6.ifname=niit4to6

uci set snmpd.@system[0].sysName=`uci get system.@system[0].hostname`
uci set snmpd.@system[0].sysLocation=`uci get system.@system[0].hostname`
uci set snmpd.@system[0].sysContact=fabfi@fabfi.com

if [ "$(pidof snmpd)" ];then
    killall snmpd
fi

#Portal Gun

uci add_list lucid.httpd.supports=VillagebusPublisher
uci add_list lucid.https.publisher=villagebus
uci set lucid.villagebus=VillagebusPublisher
uci set lucid.villagebus.name="Villagebus Publisher"
uci set lucid.villagebus.home=1
uci add_list lucid.villagebus.virtual=/villagebus

}



olsrd_base_config()
{
	/etc/init.d/olsrd enable
	#/etc/init.d/batman-adv disable
	
	echo "Enter GPS Coordinates in DD.DDDD ( decimal ) format"
	#echo "Enter Latitude"
	#read latitude

	while ( true )
	do
		echo "Enter Latitude"
		read latitude

		check=$( check_latlon $latitude )
		if [ "$check" == "ok" ]; then
			break;
		else
			echo $check
		fi
	done

	while ( true )
	do
		echo "Enter Longitude"
		read longitude

		check=$( check_latlon $longitude )
		if [ "$check" == "ok" ]; then
			break;
		else
			echo $check
		fi
	done
	

	#Start with an empty olsrd file

	while [ "$(uci show olsrd)" != "" ]
	do

		olsrd=$( uci show olsrd | cut -d "=" -f 1 | grep "@" |  tr "\n" " " )
        	for i in ${olsrd}
        	do
                	uci -q delete $i
        	done

	done

	#OLSR configuration
	uci add olsrd olsrd
	uci set olsrd.@olsrd[0]=olsrd
	uci set olsrd.@olsrd[0].DebugLevel=9
	uci set olsrd.@olsrd[0].IpVersion=6
	uci set olsrd.@olsrd[0].FIBMetric=flat
	uci set olsrd.@olsrd[0].LinkQualityAlgorithm=etx_ff
	uci set olsrd.@olsrd[0].AllowNoInt=yes
	uci set olsrd.@olsrd[0].TcRedundancy=2
	uci set olsrd.@olsrd[0].MprCoverage=2
	uci set olsrd.@olsrd[0].LinkQualityLevel=2
	uci set olsrd.@olsrd[0].SmartGateway=no
	uci set olsrd.@olsrd[0].NatThreshold=0.750000
	uci set olsrd.@olsrd[0].UseNiit=yes

	#Configure mesh interface
	uci add olsrd Interface
	uci set olsrd.@Interface[-1]=Interface
	uci set olsrd.@Interface[-1].Mode=ether
	uci set olsrd.@Interface[-1].ignore=0
	uci set olsrd.@Interface[-1].interface=mesh
	#uci set olsrd.@Interface[0].Ip6AddrType=global
	uci set olsrd.@Interface[-1].AutoDetectChanges=yes
	uci set olsrd.@Interface[-1].HelloInterval=2.0
	uci set olsrd.@Interface[-1].HelloValidityTime=20.0

	#OLSR dyn gateway
	uci add olsrd LoadPlugin
	uci set olsrd.@LoadPlugin[-1]=LoadPlugin
	uci set olsrd.@LoadPlugin[-1].library=olsrd_dyn_gw.so.0.5
	uci set olsrd.@LoadPlugin[-1].ignore=0
	uci set olsrd.@LoadPlugin[-1].Interval=30
	uci set olsrd.@LoadPlugin[-1].Ping=2001:470:20::2

	#OLSR nameservice
	uci add olsrd LoadPlugin
	uci set olsrd.@LoadPlugin[-1]=LoadPlugin
	uci set olsrd.@LoadPlugin[-1].library=olsrd_nameservice.so.0.3
	uci set olsrd.@LoadPlugin[-1].hosts_file=/var/etc/hosts.olsr
	uci set olsrd.@LoadPlugin[-1].resolv_file=/var/resolv.conf.auto
	uci set olsrd.@LoadPlugin[-1].sighup_pid_file=/var/run/dnsmasq.pid
	uci set olsrd.@LoadPlugin[-1].timeout=300
	uci set olsrd.@LoadPlugin[-1].interval=30
	uci set olsrd.@LoadPlugin[-1].suffix=.mesh
	uci set olsrd.@LoadPlugin[-1].name_change_script="/etc/init.d/dnsmasq restart"
	uci set olsrd.@LoadPlugin[-1].name=`uci get system.@system[0].hostname`
	uci set olsrd.@LoadPlugin[-1].latlon_file=/var/run/latlon.js
	uci set olsrd.@LoadPlugin[-1].lat=${latitude}
	uci set olsrd.@LoadPlugin[-1].lon=${longitude}

	uci add olsrd LoadPlugin
	uci set olsrd.@LoadPlugin[-1]=LoadPlugin
	uci set olsrd.@LoadPlugin[-1].library=olsrd_txtinfo.so.0.1
	uci set olsrd.@LoadPlugin[-1].accept=::1
	uci set olsrd.@LoadPlugin[-1].port=2006
	
	uci add olsrd Hna6

	uci set olsrd.@Hna6[-1].netaddr=0::ffff:0a00:${hexno}00
	uci set olsrd.@Hna6[-1].prefix=120

	uci add olsrd Hna6
	uci set olsrd.@Hna6[-1].netaddr=${prefix}:${number}::0
	uci set olsrd.@Hna6[-1].prefix=64

}

check_channel()
{
channel=$1
channellist=$(iw phy phy$2 info | grep -i "Mhz " | grep -v "disabled" | cut -d '[' -f 2 | cut -d ']' -f 1 | tr "\n" " ")
for i in ${channellist}
do
        if [ ${channel} == ${i} ]; then
                echo "ok"         
                exit
        fi
done

printf "Radio$2 does not support the selected Channel\nValid Channels are: ${channellist} \n\n"

}

generic_wireless_mesh()
{
	#radio = $1
	#channel = $2
	#interface = $3
	#network name = $4
	#network suffix = $5
	#SSID prefix = $6
	#Mode = $7
	#Encryption = $8
	#Key = $9

	uci set wireless.radio${1}=wifi-device
	uci set wireless.radio${1}.type=mac80211
	uci set wireless.radio${1}.hwmode=11ng
	uci set wireless.radio${1}.htmode=HT20
	uci set wireless.radio${1}.ht_capab="SHORT-GI-40 TX-STBC RX-STBC1 DSSS_CCK-40"
	uci set wireless.radio${1}.disabled=0
	uci set wireless.radio${1}.channel=${2}
	uci set wireless.radio${1}.rts=500

	uci set wireless.@wifi-iface[$3].device=radio${1}
	uci set wireless.@wifi-iface[$3].ssid=${6}${2}
	uci set wireless.@wifi-iface[$3].encryption=$8
	uci set wireless.@wifi-iface[$3].key=$9
	uci set wireless.@wifi-iface[$3].network=$4
	uci set wireless.@wifi-iface[$3].mode=$7
	
	#network
	uci set network.$4=interface
	uci set network.$4.proto=static
	uci set network.$4.ipaddr=10.0.${number}.$5
	uci set network.$4.netmask=255.255.255.240
	uci set network.$4.ip6addr=${prefix}:${number}::$5/128

	uci set firewall.@zone[0].network="$(uci get firewall.@zone[0].network) $4"

	uci add olsrd Interface
	uci set olsrd.@Interface[-1]=Interface
	uci set olsrd.@Interface[-1].Mode=mesh
	uci set olsrd.@Interface[-1].ignore=0
	uci set olsrd.@Interface[-1].interface=$4
	uci set olsrd.@Interface[-1].AutoDetectChanges=yes
	uci set olsrd.@Interface[-1].HelloInterval=2.0
	uci set olsrd.@Interface[-1].HelloValidityTime=20.0
}

client_lan_config()
{
	uci set network.clientlan_${client_lan_index}=interface
	uci set network.clientlan_${client_lan_index}.proto=static
	uci set network.clientlan_${client_lan_index}.ipaddr=10.0.${number}.${client_lan_suffix}
	uci set network.clientlan_${client_lan_index}.netmask=255.255.255.128
	uci set network.clientlan_${client_lan_index}.ip6addr=${prefix}:${number}::${client_lan_suffix}

	client_lan_radio=$1
	#echo "By default radio0 is configured for client access"
	while ( true ); do
 		echo "Set client-access channel"
		read client_lan_channel
		check=$(check_channel $client_lan_channel $client_lan_radio)
		if [ "$check" == "ok" ]; then
			echo "Channel $client_lan_channel selected"
			break
		else
			echo "$check"
		fi
	done

	story="${story} Client LAN channel : ${client_lan_channel} \n"
       	uci set wireless.radio$client_lan_radio.disabled=0
   	uci set wireless.radio$client_lan_radio.channel=$client_lan_channel
	uci set wireless.radio$client_lan_radio.rts=500

	#uci set wireless.@wifi-iface[0].network=clientlan
    	#uci set wireless.@wifi-iface[0].mode=ap
	#uci set wireless.@wifi-iface[0].ssid=schoolnet${number}

	uci set wireless.@wifi-iface[$1]=wifi-iface
	uci set wireless.@wifi-iface[$1].device=radio$client_lan_radio
	uci set wireless.@wifi-iface[$1].network=clientlan_${client_lan_index}
	uci set wireless.@wifi-iface[$1].mode=ap
	uci set wireless.@wifi-iface[$1].ssid=schoolnet${number}
	uci set wireless.@wifi-iface[$1].encryption=none
#	uci set wireless.@wifi-iface[$1].encryption=wpa2
#	uci set wireless.@wifi-iface[$1].eap_type=tls
#	uci set wireless.@wifi-iface[$1].ca_cert=/etc/fabfi/certificates/ca.pem
#	uci set wireless.@wifi-iface[$1].priv_key=/etc/fabfi/certificates/meshnode.pem
#	uci set wireless.@wifi-iface[$1].priv_key_pwd=FFJAMesh
#	uci set wireless.@wifi-iface[$1].server=radius.mesh
#	uci set wireless.@wifi-iface[$1].key=cisco123


	uci set dhcp.lan.interface=clientlan_${client_lan_index}
	uci set dhcp.lan.start=150
	uci set dhcp.lan.limit=200

	uci set radvd.@interface[0].interface=clientlan_${client_lan_index}
	uci set radvd.@interface[0].AdvSendAdvert=1
	uci set radvd.@interface[0].AdvManagedFlag=0
	uci set radvd.@interface[0].AdvOtherConfigFlag=0
	uci set radvd.@interface[0].client=
	uci set radvd.@interface[0].ignore=0
	uci set radvd.@prefix[0].interface=clientlan_${client_lan_index}
	#uci set radvd.@prefix[0].prefix=${prefix}
	uci set radvd.@prefix[0].AdvOnLink=1
	uci set radvd.@prefix[0].AdvAutonomous=1
	uci set radvd.@prefix[0].AdvRouterAddr=0
	uci set radvd.@prefix[0].ignore=0
	uci set radvd.@rdnss[0].interface=clientlan_${client_lan_index}
	uci set radvd.@rdnss[0].addr=2001:470:20::2
	uci set radvd.@rdnss[0].ignore=0


	uci add firewall zone
	uci set firewall.@zone[-1]=zone
	uci set firewall.@zone[-1].name=clientlan
	uci set firewall.@zone[-1].network=clientlan_${client_lan_index}
	uci set firewall.@zone[-1].input=ACCEPT
	uci set firewall.@zone[-1].output=ACCEPT
	uci set firewall.@zone[-1].forward=ACCEPT

	uci add firewall forwarding
	uci set firewall.@forwarding[-1].src=clientlan
	uci set firewall.@forwarding[-1].dest=mesh
	
	uci add firewall forwarding
	uci set firewall.@forwarding[-1].src=clientlan
	uci set firewall.@forwarding[-1].dest=siit

	uci add firewall forwarding
	uci set firewall.@forwarding[-1].src=mesh
	uci set firewall.@forwarding[-1].dest=clientlan

	uci add firewall forwarding
	uci set firewall.@forwarding[-1].src=siit
	uci set firewall.@forwarding[-1].dest=clientlan

	until (echo $fabportal | grep "^[yn]$"); do
        	echo "Configure fabfi-portal for this interface? (y/n)"
        	read fabportal 
		tunnel=$( echo $fabportal | tr 'A-Z' 'a-z' )
        done

	#tunnel
        if  [ $fabportal == "y" ]; then
		
		while ( true ) do
			echo "Enter your radius IP ( raw IP address for now ) "
			read radIP

			check=$( check_ipv4_address $radIP )

			if [ "$check" == "ok" ]; then
				break;
			else
				echo "$check"
			fi
		done

		uci add fabfi portal
		uci set fabfi.@portal[-1].radiusIP=radIP
		uci set fabfi.@portal[-1].radiusAuthPort=1812
		uci set fabfi.@portal[-1].radiusAcctPort=1813
		uci set fabfi.@portal[-1].radiusSecret=cisco123
		uci set fabfi.@portal[-1].dictionaryFile="/etc/fabfi-portal/dictionary"
		uci set fabfi.@portal[-1].timeout=5
		uci set fabfi.@portal[-1].clientLanInterface=clientlan_${client_lan_index}
					
		touch /etc/config/haproxy

		uci add haproxy listen
		uci set haproxy.@listen[-1].name="portalgun_splash"
		uci set haproxy.@listen[-1].bind=clientlan_${client_lan_index}
		uci set haproxy.@listen[-1].ipMode=ipv4
		uci set haproxy.@listen[-1].mode=http
		uci set haproxy.@listen[-1].option=forwardfor
		uci set haproxy.@listen[-1].reqadd="Foo-Header:\ plonk"
		uci set haproxy.@listen[-1].servername=splash01
		uci set haproxy.@listen[-1].serverIP="127.0.0.1:8001"
		
		uci add haproxy listen
		uci set haproxy.@listen[-1].name="portalgun_splash2"
		uci set haproxy.@listen[-1].bind=clientlan_${client_lan_index}
		uci set haproxy.@listen[-1].ipMode=ipv6
		uci set haproxy.@listen[-1].mode=http
		uci set haproxy.@listen[-1].option=forwardfor
		uci set haproxy.@listen[-1].reqadd="Foo-Header:\ plonk"
		uci set haproxy.@listen[-1].servername=splash01
		uci set haproxy.@listen[-1].serverIP="127.0.0.1:8001"
		
		/etc/init.d/fabfi-portal enable
		/etc/init.d/haproxy enable
		
		uci set lucid.splashroot=VillagebusPublisher
		uci set lucid.splashroot.name="portalgun splash"
		uci set lucid.splashroot.home=1
		uci set lucid.splashroot.physical="/splash"
		uci set lucid.splash=daemon
		uci set lucid.splash.slave=httpd
		uci set lucid.splash.address=8001
		uci set lucid.splash.nokeepalive=1
		uci set lucid.splash.memlimit=1572864
		uci set lucid.splash.enabled=1
		uci set lucid.splash.publisher=splashroot		

	fi	

}

transparent_link_config()
{

	/etc/init.d/olsrd disable
	#/etc/init.d/batman-adv enable
	echo "What is the fabfi number of the node you're connecting this to?"
	read mnode
	
	check=999 #just to be sure
	until [ $check -eq 0 ]
	do
		echo "Enter index ( Must be between 2 and 14)"
		read index
		echo $index | egrep "\b([2-9]|1[0-4])\b"
		check=$?
	done

	echo "Enter your 64-bit IPv6 prefix (e.g 2001:470:1f08:1b61 There's no check on this text)"
	read prefix
	story="${story} IPv6 prefix : ${prefix}\n"

	uci set system.@system[0].hostname=schoolnet${mnode}_${index}

	printf "\n Setting ${platform} as transparent link device \n \n"
	
	story="${story} Device set as transparent link \n Host node is ${mnode} \n"
	story="${story} Device Index : ${index} \n"

	mhexno=`printf "%x\n" ${mnode}`

	uci set network.trans_wifi=interface
	uci set network.trans_wifi.proto=static
	uci set network.trans_wifi.netmask=255.255.0.0
	uci set network.trans_wifi.ifname=wlan0
	uci set network.trans_wifi.ipaddr=172.16.$mnode.${index}
	uci set network.trans_wifi.ip6addr=${prefix}:${mnode}::${index}

	uci set network.mesh.ipaddr=10.0.${mnode}.4
	uci set network.mesh.netmask=255.255.255.240
	uci set network.mesh.ip6addr=${prefix}:${mnode}::4
	uci set network.mesh.gateway=10.0.${mnode}.1
	uci set network.mesh.ip6gw=${prefix}:${mnode}::1
	uci set network.mesh.ifname="eth0 bat0"
	uci set network.mesh.type=bridge

	uci set network.bat0=interface
	uci set network.bat0.ifname=bat0
	uci set network.bat0.proto=none

	#uci set batman-adv.bat0=mesh
	#uci set batman-adv.bat0.interfaces="mesh trans_wifi"
	#uci set wireless.radio0.htmode=HT20


	trans_radio=0
	while ( true ); do
 		echo "Set Transparent Link channel"
		read trans_channel
		check=$(check_channel $trans_channel $trans_radio)
		if [ "$check" == "ok" ]; then
			echo "Channel $trans_channel selected"
			break
		else
			echo "$check"
		fi
	done

	#Wireless
	uci set wireless.radio0.disabled=0
	uci set wireless.@wifi-iface[0].network="trans_wifi"
	uci set wireless.@wifi-iface[0].mode=adhoc
	uci set wireless.@wifi-iface[0].ssid=schoolnet_transparent_$trans_channel
	uci set wireless.radio0.channel=$trans_radio

	uci set firewall.@zone[0].network="uci get firewall.@zone[0].network trans_wifi"
}


head_node_config() 
{
	uci set fabfi.@node[0].headnode=1
	while ( true )
	do
		echo "Enter your external IPv4 address or simply 'd' for dhcp "
		read wanaddr

		if [ $wanaddr == "d" ]; then
			break;
		fi

		check=$( check_ipv4_address $wanaddr )
		if [ "$check" == "ok" ]; then
			break;
		else
			echo "$check"
		fi
	done

	if [ $wanaddr == "d" ]; then
		uci set network.wan.proto=dhcp
		story="$story WAN ADDRESS : DHCP"
	else

		echo "whats your netmask?"
        	read wannetmask

		while ( true )
		do
			echo "Enter your gateway address"
			read wangateway

			check=$( check_ipv4_address $wangateway )
			if [ "$check" == "ok" ]; then
				break;
			else
				echo "$check"
			fi
		done

		story="$story WAN IP address : ${wanaddr} \n WAN Netmask : ${wannetmask} \n WAN Gateway : ${wangateway} \n"

		uci set network.wan.proto=static
		uci set network.wan.ipaddr=${wanaddr}
		uci set network.wan.netmask=${wannetmask}
		uci set network.wan.gateway=${wangateway}
		uci set network.wan.dns=8.8.8.8
	fi

	uci add firewall zone
	uci set firewall.@zone[-1].name=wan
	uci set firewall.@zone[-1].network="wan"
	uci set firewall.@zone[-1].input=REJECT
	uci set firewall.@zone[-1].output=ACCEPT
	uci set firewall.@zone[-1].forward=REJECT
	uci set firewall.@zone[-1].masq=1
	uci set firewall.@zone[-1].mtu_fix=1

	while ( true )
	do
		echo "Enter your cloud server address ( IPv4 for now )"
		read cloud 
		check=$( check_ipv4_address $cloud )
		if [ "$check" == "ok" ]; then
			break;
		else
			echo "$check"
		fi
	done

	#Servers
	uci add dhcp domain
	uci set dhcp.@domain[-1].name=map.mesh
	uci set dhcp.@domain[-1].ip=$cloud	

	until (echo $tunnel | grep "^[yn]$"); do
        	echo "do you wish to setup an ipv6 tunnel? (y/n)"
        	read tunnel
		tunnel=$( echo $tunnel | tr 'A-Z' 'a-z' )
        done

	#tunnel
        if  [ $tunnel == "y" ]; then

		until (echo $broker | grep "^[hs]$"); do

			echo "Who is your tunnel broker, Hurricane Electric or Sixxs? (h/s) "
			read broker
			broker=$( echo $broker | tr 'A-Z' 'a-z' )
		done

		if [ $broker == "h" ]; then
			echo "what is your remote ipv4 tunnel address?"
			read remote
			story="${story} Remote tunnel address : ${remote}\n"
			printf "ip tunnel add tun0 mode sit remote ${remote} local ${wanaddr} ttl 255 \nip link set tun0 up \nip -6 route add default dev tun0 \n" > /etc/rc.local
		fi

		if [ $broker == "s" ]; then

			echo "Enter your sixxs Username"
			read sixusername
			echo "Enter your sixxs Password"
			read sixpassword
			echo "What is your tunnel ID?"
			read tunnelid
			#echo "What is your sixxs server address?"
			#read sixserver

			sixserver= "tic.sixxs.net"
			uci set aiccu.@aiccu[0].username=${sixusername}
			uci set aiccu.@aiccu[0].password=${sixpassword}
			uci set aiccu.@aiccu[0].protocol=TIC
			uci set aiccu.@aiccu[0].server=${sixserver}
			uci set aiccu.@aiccu[0].interface=tun0
			uci set aiccu.@aiccu[0].tunnel_id=${tunnelid}
			uci set aiccu.@aiccu[0].requiretls=0
			uci set aiccu.@aiccu[0].defaultroute=1
			uci set aiccu.@aiccu[0].nat=1
			uci set aiccu.@aiccu[0].heartbeat=1

		fi
	else

		echo "" > /etc/rc.local

	fi #ends do you want to configure tunnel

	uci add olsrd Hna6
	uci set olsrd.@Hna6[-1].netaddr=0::ffff:0:0
	uci set olsrd.@Hna6[-1].prefix=96

	uci add firewall rule
	uci set firewall.@rule[-1].src=wan
	uci set firewall.@rule[-1].proto=udp
	uci set firewall.@rule[-1].dest_port=68
	uci set firewall.@rule[-1].target=ACCEPT
	uci set firewall.@rule[-1].family=ipv4


	uci add firewall rule
	uci set firewall.@rule[-1].src=wan
	uci set firewall.@rule[-1].proto=icmp
	uci set firewall.@rule[-1].icmp_type="echo-request"
	uci set firewall.@rule[-1].family=ipv4
	uci set firewall.@rule[-1].target=ACCEPT

	#Allow IPv6 encapsulation - protocol 41
	uci add firewall rule
	uci set firewall.@rule[-1].src=wan
	uci set firewall.@rule[-1].proto=41
	uci set firewall.@rule[-1].target=ACCEPT

	uci add firewall rule
	uci set firewall.@rule[-1].target=ACCEPT
	uci set firewall.@rule[-1]._name="SSH from net"
	uci set firewall.@rule[-1].src=wan
	uci set firewall.@rule[-1].proto=tcp
	uci set firewall.@rule[-1].dest_port=22

	uci add firewall rule
	uci set firewall.@rule[-1].target=ACCEPT
	uci set firewall.@rule[-1]._name="SNMP"
	uci set firewall.@rule[-1].src=wan
	uci set firewall.@rule[-1].proto="tcp udp"
	uci set firewall.@rule[-1].dest_port=161

	uci add firewall forwarding
	uci set firewall.@forwarding[-1].src=mesh
	uci set firewall.@forwarding[-1].dest=wan

	uci add firewall forwarding
	uci set firewall.@forwarding[-1].src=siit
	uci set firewall.@forwarding[-1].dest=wan

	uci add firewall forwarding
	uci set firewall.@forwarding[-1].src=clientlan
	uci set firewall.@forwarding[-1].dest=wan

	#uci set network.mesh.ip6addr=${prefix}:${hexno}::1
	#uci set olsrd.@LoadPlugin[-1].dns_server=`uci get network.mesh.ip6addr`
	uci set olsrd.@LoadPlugin[1].dns_server=${prefix}:${number}::1




}


c_node_config()
{

slot=$1
cnumber=notvalid

until (echo $cnumber | grep "^[12345]$"); do

	printf "\nRadio detected in $slot\n"

	printf "\nConfigure radio in $slot for :\n"
	echo " 1 : Client Lan"
	echo " 2 : C-mesh"
	echo " 3 : C-T Link"
	echo " 4 : Client Lan + C-mesh"
	echo " 5 : Ignore "
	echo ""
	echo "Choose 1, 2, 3 or 4 "
	read cnumber
done

if [ $cnumber == "1" ] ; then
	story="${story} Radio in $slot set for Client LAN \n"
	client_lan_config $radio
	client_lan_suffix=$(expr ${client_lan_suffix} + 1)
	client_lan_index=$(expr ${client_lan_index} + 1)

fi # end cnumber == 1

if [ $cnumber == "2" ] ; then

	while ( true ); do
		echo "Set C-mesh channel"
		read meshchannel
		check=$(check_channel $meshchannel $radio)
		if [ "$check" == "ok" ]; then
			echo "Channel $meshchannel selected"
			break
		else
			echo "$check"
		fi
       	done

	radio=$radio
	channel=${meshchannel}
	iface=$radio
	network=cmesh_$cmesh_index
	suffix=${cmesh_suffix}
	ssid_prefix=schoolnetmesh
	mode=adhoc
	encryption="psk2"
	key=$default_key

	generic_wireless_mesh $radio $channel $iface $network $suffix $ssid_prefix $mode $encryption $key

	cmesh_suffix=$(expr ${cmesh_suffix} + 1)	
	cmesh_index=$(expr $cmesh_index + 1)
	story="${story} Radio in $slot set for C-mesh \n C-mesh channel : ${meshchannel} \n"
fi # end cnumber == 2, C-mesh

if [ $cnumber == "3" ]; then
	while ( true ); do
		echo "Set C-T link channel"
		read ctchannel
		check=$(check_channel $ctchannel $radio)
		if [ "$check" == "ok" ]; then
			echo "Channel $ctchannel selected"
			break
		else
			echo "$check"
		fi
       	 done

	radio=$radio
	channel=${ctchannel}
	iface=$radio
	network=c_t_link_$c_t_link_index
	suffix=${c_t_suffix}
	ssid_prefix=schoolnetBH
	mode=adhoc
	encryption="psk2"
	key=$default_key

	generic_wireless_mesh $radio $channel $iface $network $suffix $ssid_prefix $mode $encryption $key 
	c_t_suffix=$(expr ${c_t_suffix} + 1)
	c_t_link_index=$(expr ${c_t_link_index} + 1)
	story="${story} Radio in $slot set for C-T link \n C-T link channel : ${ctchannel} \n"
fi # cnumber == 3 - C-T link

if [ $cnumber == "4" ] ; then
        story="${story} Radio in $slot set for Client LAN + C-mesh \n"
        client_lan_config $radio
        client_lan_suffix=$(expr ${client_lan_suffix} + 1)
        client_lan_index=$(expr ${client_lan_index} + 1)

        uci add wireless wifi-iface
	uci set wireless.@wifi-iface[-1].device=radio${radio}
        uci set wireless.@wifi-iface[-1].ssid=schoolnetmesh${client_lan_channel}
        uci set wireless.@wifi-iface[-1].encryption=none
        uci set wireless.@wifi-iface[-1].key=""
        uci set wireless.@wifi-iface[-1].network=cmesh_$cmesh_index
        uci set wireless.@wifi-iface[-1].mode=adhoc

        #network
        uci set network.cmesh_$cmesh_index=interface
        uci set network.cmesh_$cmesh_index.proto=static
        uci set network.cmesh_$cmesh_index.ipaddr=10.0.${number}.17
        uci set network.cmesh_$cmesh_index.netmask=255.255.255.240
        uci set network.cmesh_$cmesh_index.ip6addr=${prefix}:${number}::17
	
	uci set firewall.@zone[0].network="$(uci get firewall.@zone[0].network) cmesh_$cmesh_index"
	
	uci add olsrd Interface
        uci set olsrd.@Interface[-1]=Interface
        uci set olsrd.@Interface[-1].Mode=mesh
        uci set olsrd.@Interface[-1].ignore=0
        uci set olsrd.@Interface[-1].interface=cmesh_$cmesh_index
        uci set olsrd.@Interface[-1].AutoDetectChanges=yes
        uci set olsrd.@Interface[-1].HelloInterval=2.0
        uci set olsrd.@Interface[-1].HelloValidityTime=20.0

fi # end cnumber == 4


}

t_node_config() 
{
slot=$1
tnumber=notvalid

until (echo $tnumber | grep "^[123]$"); do

	printf "\nRadio detected in $slot\n"
	printf "\nConfigure radio in $slot for :\n"
	echo " 1 : Client Lan"
	echo " 2 : T-T Link"
	echo " 3 : Ignore"
	echo ""
	echo "Choose 1, 2, 3"
	read tnumber
done

if [ $tnumber == "1" ] ; then
	story="${story} Radio in $slot set for Client LAN \n"
	client_lan_config $radio
        client_lan_suffix=$(expr ${client_lan_suffix} + 1)
        client_lan_index=$(expr ${client_lan_index} + 1)


fi # end tnumber == 1

if [ $tnumber == "2" ] ; then

	while ( true ); do
		echo "Set T-T link channel"
		read ttchannel
		check=$(check_channel $ttchannel $radio)
		if [ "$check" == "ok" ]; then
			echo "Channel $ttchannel selected"
			break
		else
			echo "$check"
		fi
         done

	radio=$radio
	channel=${ttchannel}
	iface=$radio
	network=t_t_link_$t_t_link_index
	suffix=${t_t_suffix}
	ssid_prefix=schoolnetBH
	mode=adhoc
	encryption="psk2"
	key=$default_key

	generic_wireless_mesh $radio $channel $iface $network $suffix $ssid_prefix $mode $encryption $key
	t_t_link_index=$(expr $t_t_link_index + 1)
	t_t_suffix=$(expr ${t_t_suffix} + 1)
	story="${story} Radio in $slot set for T-T link \n T-T link channel : ${ttchannel} \n"

fi # end tnumber=2, configure T-T

}



platform=$(cat /proc/cpuinfo | grep machine | cut -d ":" -f 2 | cut -c2- | tr -d "\n")

story="${story} \n Node Settings \n Device: ${platform} \n"
clear

cat /usr/share/fabfi/logo2
sleep 2

clear
printf "\n\n${platform}\n\n"
sleep 1


uci set system.@system[0].platform="${platform}"

uci rename network.lan=mesh
uci delete network.mesh.type

uci add network alias
uci set network.@alias[-1].interface=mesh
uci set network.@alias[-1].proto=static
uci set network.@alias[-1].ipaddr=192.168.100.1
uci set network.@alias[-1].netmask=255.255.0.0

#Firewall Configuration
#start with an empty firewall file

while [ "$(uci show firewall)" != "" ]
do

	firewall=$( uci show firewall | cut -d "=" -f 1 | grep "@" |  tr "\n" " " )
	for i in ${firewall}
	do
		uci -q delete $i
        done

done


uci add firewall defaults 
uci set firewall.@defaults[0]=defaults
uci set firewall.@defaults[0].syn_flood=1
uci set firewall.@defaults[0].input=ACCEPT
uci set firewall.@defaults[0].output=ACCEPT
uci set firewall.@defaults[0].forward=ACCEPT

uci add firewall include
uci set firewall.@include[-1].path="/etc/firewall.user"

uci add firewall zone
uci set firewall.@zone[-1]=zone
uci set firewall.@zone[-1].name=mesh
uci set firewall.@zone[-1].network="mesh"
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT

uci add firewall zone
uci set firewall.@zone[-1]=zone
uci set firewall.@zone[-1].name=siit
uci set firewall.@zone[-1].network="siit0"
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=mesh
uci set firewall.@forwarding[-1].dest=siit

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=siit
uci set firewall.@forwarding[-1].dest=mesh


if [[ "${platform}" != "Ubiquiti RouterStation Pro" && "${platform}" != "Ubiquiti RouterStation" && "${platform}" != "Ubiquiti Nanostation M" ]]; then

	until (echo $nano | grep "^[yn]$"); do
	        echo "Is this a transparent link device ? (y/n)"
		#echo "(determines whether to run batman or olsr)"
	        read nano
	done

	if  [ $nano == "y" ]; then

	        transparent_link_config
        
	else
		generic_configs
		olsrd_base_config
 
		until (echo $client | grep "^[yn]$"); do
	        	echo "do you want to configure this device for client access? (y/n)"
		        read client
		done

		if  [ $client == "y" ]; then

			client_lan_config 0

		fi #end "do you want to configure the device for client access"	


		until (echo $mesh | grep "^[yn]$"); do
	                echo "do you wish to add a mesh interface (adhoc) ? (y/n)"
	                read mesh
		done

                if  [ $mesh == "y" ]; then

			until (echo $radio2 | grep "^[yn]$"); do
		                echo "do you have a second radio on this device? (y/n)"
		        	read radio2
			done

			if  [ $radio2 == "y" ]; then

				cmeshradio=1
			else
				cmeshradio=0
				uci add wireless wifi-iface

			fi # end "second radio"

			while ( true ); do
				echo "Set C-mesh channel"
				read meshchannel
				check=$(check_channel $meshchannel $cmeshradio)
				if [ "$check" == "ok" ]; then
					echo "Channel $meshchannel selected"
					break
				else
					echo "$check"
				fi
			done

			radio=$cmeshradio
			channel=${meshchannel}
			iface=1
			network=cmesh
			suffix=17
			ssid_prefix=schoolnetmesh
			mode=adhoc
			encryption="psk2"
			key=$default_key

			generic_wireless_mesh $radio $channel $iface $network $suffix $ssid_prefix $mode $encryption $key
			story="${story} Radio$radio set for C-mesh \n C-mesh channel : ${meshchannel} \n"

		fi # end "do you want to configure mesh"

		until (echo $hnode | grep "^[yn]$"); do
		      echo "is this your headnode? (y/n)"
		      read hnode
		done

		if  [ $hnode == "y" ]; then

			head_node_config

		fi #ends is this a headnode

	fi  #end "is this a transparent link device"

	#End custom device config

else 

	if [[ "${platform}" == "Ubiquiti Nanostation M" ]]; then
		until (echo $olsr | grep "^[bo]$"); do
        	        echo "Batman or olsr? (b/o)"
                	read olsr
	        olsr=$( echo $olsr | tr 'A-Z' 'a-z' )
        	done

		if [ $olsr == "b" ]; then

			transparent_link_config

		else

			generic_configs
                	olsrd_base_config

			uci set fabfi.@node[0].nodeType="N"
			story="${story} Node type : N \n"
			while ( true ); do
                              echo "Set link channel"
				read ttmeshchannel
                                check=$(check_channel ${ttmeshchannel} 0)

			       if [ "$check" == "ok" ]; then
                        	       echo "Channel $ttmeshchannel selected"
                                       break
                                else
                                        echo "$check"
                                fi 
                        done


			radio=0
			channel=${ttmeshchannel}
			iface=0
			network=t_t_link
			suffix=33
                        ssid_prefix=schoolnetBH
                        mode=adhoc
                        encryption="psk2"
                        key=$default_key
			generic_wireless_mesh $radio $channel $iface $network $suffix $ssid_prefix $mode $encryption $key

		fi
	else
		generic_configs
		olsrd_base_config

		until (echo $ntype | grep "^[TC]$"); do
 
			echo "Enter node type ( T or C )"
			read ntype
			ntype=$(echo $ntype | tr '[a-z' '[A-Z]')
	         done

		uci set fabfi.@node[0].nodeType=${ntype}

	        story="${story} Node type : ${ntype} \n"


		if  [ $ntype == "C" ]; then

			radio=0
			cmesh_suffix=17
			cmesh_index=0
			c_t_suffix=33
			c_t_link_index=0


			if [ "$( lspci |  grep -i "00:11.0" )" ]; then
			
				c_node_config slot_0
				radio=$(expr $radio + 1)
							
			fi # end slot_0 radio detect


			
			# Slot_1 radio detect

			if [ "$( lspci |  grep -i "00:12.0" )" ]; then
				
				c_node_config slot_1
				radio=$(expr $radio + 1)
				
			fi # end slot_1 radio detect
		
			#slot_2 radio detect

			if [ "$( lspci |  grep -i "00:13.0" )" ]; then
				
				c_node_config slot_2
				radio=$(expr $radio + 1)			
											
			fi # end slot_2 radio detect

		fi #ends if nodetype == C

		if  [ $ntype == "T" ]; then

			radio=0
			t_t_suffix=33
			t_t_link_index=0

			if [ "$( lspci |  grep -i "00:11.0" )" ]; then

				t_node_config slot_0
				radio=$(expr $radio + 1)

			fi # end slot_0 radio detect


			
			# Slot_1 radio detect

			if [ "$( lspci |  grep -i "00:12.0" )" ]; then
				
				t_node_config slot_1
				radio=$(expr $radio + 1)
				
			fi # end slot_1 radio detect
		
			#slot_2 radio detect

			if [ "$( lspci |  grep -i "00:13.0" )" ]; then
				
				t_node_config slot_2
				radio=$(expr $radio + 1)			
											
			fi # end slot_2 radio detect

			until (echo $hnode | grep "^[yn]$"); do
				echo "is this your headnode? (y/n)"
				read hnode
				hnode=$(echo $hnode | tr '[A-Z]' '[a-z]')
			done

			if  [ $hnode == "y" ]; then

				head_node_config

			fi #ends is this a headnode

		fi # ends is this T-node

	fi  #end "ends nanostation config"

fi #ends branch to custom config

printf "\n\n Configuration Completed \n\n"

#cp /etc/fabfi/files/passwd2 /etc/passwd # To deal with openwrt's passwd problem 
until (echo $password | grep "^[y]$"); do
   printf "\nEnter root password \n\n"
    passwd root     
    if [ $? == 0 ]; then
    	password="y"		
    else
	echo ""
    fi
    
done

clear

printf "${story}"

  until (echo $commit | grep "^[yn]$"); do
        
	echo ""
	echo "Commit and reboot? (y/n)"

        read commit
        commit=$( echo $commit | tr 'A-Z' 'a-z' )
  done

if [ ${commit} == "y" ]; then

	#openwrt=$(cat /etc/banner | grep -i bleed | cut -d "(" -f 2 | cut -d ")" -f 1)

	echo createUser random SHA1 "random" AES "random" >> /usr/lib/snmp/snmpd.conf #something funny happens to the first entry; it never appears - this is why we have this silly entry
	echo createUser fabfi-user SHA1 "cisco123" AES "cisco123" >> /usr/lib/snmp/snmpd.conf
	echo createUser fabfi-admin SHA1 "cisco123" AES "cisco123" >> /usr/lib/snmp/snmpd.conf
	#echo "*/1 * * * * /bin/ash /etc/fabfi/scripts/copy-files.sh 2> /dev/null" >> /etc/crontabs/root
	#echo "*/2 * * * * sh /etc/fabfi/scripts/fabfimap.sh > /dev/null" >> /etc/crontabs/root
	#echo "*/5 * * * * sh /etc/fabfi/scripts/offline-log.sh > /dev/null" >> /etc/crontabs/root


	#cp /etc/fabfi/files/logo2 /etc/banner 
	#printf " ${platform} \n Fabfi r${fabfi} - OpenWrt r${openwrt} \n $(cat /proc/version  | cut -d "(" -f 1)" >> /etc/banner
	#printf "\n - - - - - - - - - - - - - - - - - -\n" >> /etc/banner

	echo "::1 localhost" >> /etc/hosts
	printf "${story}" >> /root/Node_Info

	echo "Node info summarized in /root/Node_Info"
	#Keep power levels low while we test


	for i in 0 1 2 3 #assumes we can have upto 4 radios on a device

	do
		if [ `uci -q get wireless.radio$i` ] ; then
			uci set wireless.radio$i.txpower=0  #change from 0 to your preference
	        fi

	done

	echo exit 0 >> /etc/rc.local

	#cp /etc/fabfi/files/sysupgrade.conf /etc/sysupgrade.conf
#	ln -s /usr/bin/fabfi/siit-init /etc/init.d/siit
#	ln -s /usr/bin/fabfi/siit-hotplug /etc/hotplug.d/iface/30-siit
#	/etc/init.d/siit enable

	echo "Wait for telnet to close before unplugging router from power"

	uci commit
	sleep 3	
	rm /setup
	
	if [ "$(pidof telnetd)" ];then
	
		reboot && killall telnetd
	fi

	if [ "$(pidof dropbear)" ];then
	
		reboot && killall dropbear 
	fi
	
else
	echo "Setup not committed"
	echo "Reverting UCI . . ."
	sleep 1
	configs=$(ls /etc/config | tr "\n" " ")

	for i in ${configs}
	do
		echo Reverting $i
		uci revert $i   
	done	
	
	sleep 1
	echo "Setup script will now exit"
fi

exit 0
