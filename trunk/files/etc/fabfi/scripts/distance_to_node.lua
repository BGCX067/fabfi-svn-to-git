#!/usr/bin/lua
require("uci")

-- Haversine function implemented in Lua --

-- Usage ./distance_to_node lat1, lon1, lat2, lon2 --

d2r = math.pi/180 -- Factor for converting degrees to radians --

function distance (lat1,lon1,lat2,lon2)

	d_lon = (lon2 - lon1) * d2r ;
	d_lat = (lat2 - lat1) * d2r ;
	a = math.pow(math.sin(d_lat/2.0), 2) + math.cos(lat1*d2r) * math.cos(lat2*d2r) * math.pow(math.sin(d_lon/2.0), 2);
	c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
	d = 6367 * c;
	return d;
end

f = distance ( arg[1] , arg[2], arg[3], arg[4] );

print (f);
