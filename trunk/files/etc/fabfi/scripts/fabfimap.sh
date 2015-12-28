#!/bin/ash

mapserver=`uci get fabfi.@servers[0].mapserver`
updateinterval=`uci get fabfi.@node[0].mapUpdateInterval`

meshmib="/etc/fabfi/scripts/meshmib.sh"

node_id=`sh ${meshmib} fabfinumber`
node_ip=`sh ${meshmib} self_ip`
node_coords=`sh ${meshmib} coords` 

neigh_ip=`echo $(/bin/ash ${meshmib} neigh_ip | tr '\n' ',') | sed s/,$//`
neigh_cost=`echo $(/bin/ash ${meshmib} neigh_cost | tr '\n' ',') | sed s/,$//`
neigh_lq=`echo $(/bin/ash ${meshmib} neigh_lq | tr '\n' ',') | sed s/,$//`
neigh_nlq=`echo $(/bin/ash ${meshmib} neigh_nlq | tr '\n' ',') | sed s/,$//`

updateString=`echo "action=update&node_id=$node_id&node_ip=$node_ip&node_coords=$node_coords&neigh_ips=$neigh_ip&neigh_lqs=$neigh_lq&neigh_nlqs=$neigh_nlq&neigh_costs=$neigh_cost" | sed 's/\ /%20/g'`

echo "http://$mapserver/ff5map/index.php?$updateString"
wget "http://$mapserver/ff5map/index.php?$updateString" -qO - > /dev/null 2> /dev/null


