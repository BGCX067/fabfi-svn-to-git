#!/bin/ash

sleep 5; # This is to offset this script with other cron entries

#For OLSR

echo /links | ncat -6 ::1 2006 | sed '1,5d' |  sed '$d' > /tmp/olsr.info

#latlon.js

cat /var/run/latlon.js > /var/run/latlon-bc.js
