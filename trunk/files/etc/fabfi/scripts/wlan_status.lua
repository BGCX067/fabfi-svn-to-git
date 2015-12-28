#!/usr/bin/lua

meshmib="/bin/ash /etc/fabfi/scripts/meshmib.sh ";
logDir="/root/logs/"
os.execute("if [ ! -d "..logDir.." ]; then mkdir "..logDir.." ; fi")
function ash(cmd, raw)
	
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	if raw then return s end
	s = string.gsub(s, '^%s+', '')
	s = string.gsub(s, '%s+$', '')
	s = string.gsub(s, '[\n\r]+', ' ')
	return s
end


function fromCSV (s)
	s = s .. ','        -- ending comma
	local t = {}        -- table to collect fields
	local fieldstart = 1
	repeat
	-- next field is quoted? (start with `"'?)
		if string.find(s, '^"', fieldstart) then
			local a, c
    			local i  = fieldstart
    			repeat
				-- find closing quote
				a, i, c = string.find(s, '"("?)', i+1)
			until c ~= '"'    -- quote not followed by quote?
			if not i then error('unmatched "') end
	
			local f = string.sub(s, fieldstart+1, i-1)
			table.insert(t, (string.gsub(f, '""', '"')))
			fieldstart = string.find(s, ',', i) + 1
		else                -- unquoted; find next comma
			local nexti = string.find(s, ',', fieldstart)
			table.insert(t, string.sub(s, fieldstart, nexti-1))
			fieldstart = nexti + 1
		end
	until fieldstart > string.len(s)
	return t
end


ifaces=tonumber(ash(meshmib .. " wifi_interfaces" )); -- no. of wlan interfaces

olsr_neigh = fromCSV(ash(meshmib .. "neigh_ip " .. (ifaces-1) .." | tr '\n' ',' | sed s/,$//"),",");
lq = fromCSV(ash(meshmib .. "neigh_lq " .. (ifaces-1) .." | tr '\n' ',' | sed s/,$//"),",");
nlq = fromCSV(ash(meshmib .. "neigh_nlq " .. (ifaces-1) .." | tr '\n' ',' | sed s/,$//"),",");
cost = fromCSV(ash(meshmib .. "neigh_cost " .. (ifaces-1) .." | tr '\n' ',' | sed s/,$//"),",");
	
while ( ifaces>0)
do
	
	local file = io.open(logDir.."wlan"..(ifaces-1)..".log", "a")

	clients = fromCSV(ash(meshmib .. "wifi_clients " .. (ifaces-1) .." | tr '\n' ',' | sed s/,$//"),","); 
	signal  = fromCSV(ash(meshmib .. "avg_signal " .. (ifaces-1) .." | tr '\n' ',' | sed s/,$//"),",");
	tx_bitrate = fromCSV(ash(meshmib .."tx_bitrate " .. (ifaces-1) .." | tr '\n' ',' | sed s/,$//"),",");	
	rx_bitrate = fromCSV(ash(meshmib .."rx_bitrate " .. (ifaces-1) .." | tr '\n' ',' | sed s/,$//"),",");


	date=os.date();
	
	for i=1,table.getn(clients) 
	do
		if clients[i] ~= nil and clients[i] ~= "" then
			for j=1,table.getn(olsr_neigh)
			do
				if olsr_neigh[j] == clients[i] then
					file:write(date.."\t"..clients[i].."\t"..signal[i].."\t"..tx_bitrate[i].."\t"..rx_bitrate[i].."\t"..lq[j].."\t"..nlq[j].."\t"..cost[j].."\n");
					clients[i] = nil
					signal[i] = nil
					tx_bitrate[i] = nil
					rx_bitrate[i] = nil
				end
			end
		
		end
	end
	
	for i=1,table.getn(clients)
	do	
		if clients[i] ~= nil and clients[i] ~= "" then
			file:write(date.."\t"..clients[i].."\t"..signal[i].."\t"..tx_bitrate[i].."\t"..rx_bitrate[i].."\n");
		end
	end	

	file:close()
	ifaces=ifaces-1;
end

