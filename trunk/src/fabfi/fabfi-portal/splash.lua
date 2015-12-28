--[[ logging ]]--


function encodeIPv4(address)
	address=string.gsub(address,"%."," ")
	binaryIP=""
	
	for num in address:gmatch("%d+") do 
		binaryIP=binaryIP..string.char(num)
	end
	
	return binaryIP

end

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
                                                       
function getMAC(address)        
                                                                                       
	ipv6=ash("ip neigh show | grep -i '"..address.."' | cut -d ' ' -f 5" );
	ipv4=ash("ip neigh show | grep -i '"..address.."' | cut -d ' ' -f 5" );
	if ipv4 ~= "" then
		return ipv4                                                  
	
	elseif ipv6 ~= "" then
		return ipv6                                              
	else
		return "NOT FOUND"
	end
	
	return ipv6
end

function Bin2Dec(s)
	-- s	-> binary string
	local num = 0
	local ex = string.len(s) - 1
	local l = 0
	
	l = ex + 1
		for i = 1, l do
			b = string.sub(s, i, i)
			if b == "1" then
				num = num + 2^ex
			end
			ex = ex - 1
		end
					
	return string.format("%u", num)
end										
                
                
function numberstring(number, base)
	local s = ""
	repeat  
		local remainder = math.mod(number,base)
		s = remainder..s
		number = (number-remainder)/base
	until number==0

	if string.len(s)~=8  then 
		local n = 8 - string.len(s)
		for i=1,n,1 do
			s = 0 .. s
		end

	end
	return s
end

XOR_L=
{
	{0,1},
	{1,0},
}

function xor(a,b)
	pow=1
	c=0
	while a>0 or b>0 do
		c= c+ ( XOR_L[( a % 2 ) + 1][ ( b % 2 ) + 1 ]*pow)
		a=math.floor(a/2)
		b=math.floor(b/2)
		pow = pow * 2
	end
	return c
end

require "logging.file"
logname = "/var/log/villagebus.log"
local log = logging.file(logname)
if not log then
	log = logging.file("/dev/null")
end
-- log:setLevel(logging.INFO)
log:setLevel(logging.DEBUG)
log:debug("loaded villagebus.modules.splash") 


--[[ dependencies ]]--
local fs  = require "nixio.fs"
local md5 = require "md5"

require "luci.sys.iptparser" -- http://luci.subsignal.org/api/luci/modules/luci.sys.iptparser.html
local ipt6 = luci.sys.iptparser.IptParser(6)
local ipt4 = luci.sys.iptparser.IptParser(4)

clientIface=ash("uci get fabfi.@portal[0].clientLanInterface") 
clientIface=ash("uci -P/var/state get network."..clientIface..".ifname")
portalChain="YOU_SHALL_NOT_PASS"
selfMac=ash("ifconfig "..clientIface.." | grep -i "..clientIface.." | cut -d ' ' -f 10")
mainDictionary=ash("uci get fabfi.@portal[0].dictionaryFile")

--[[ modules.portalgun ]]--
module("modules.splash", package.seeall)

local splashconfig = { -- TODO configure via uci.lucid

	root = "/www/splash",
	page = "index.html"
  
}


-- [[ implementation ]]--
function GET(request, response)
	--log:debug(request)
	--log:debug("Function get : this actually ran")
	return splash(request, response)
end

function POST(request, response)
	--log:debug("Function post : this actually ran")
	return splash(request, response)
end

-- Splash page

function splash(request, response)
  log:debug("splash" .. 
           " -> " .. json.encode(request.verb) .. 
           " -> " .. json.encode(request.path) ..
           " -> " .. json.encode(request.query) ..
           " -> " .. json.encode(request.data)
           ) 
	
	
  -- get client address
	local client = request.headers["X-Forwarded-For"] or 
		request.env["REMOTE_ADDR"] 

	-- check for and dispatch any portalgun operations
  
	local uuid = md5.sumhexa(request.env["HTTP_HOST"])
  
	if request.path[1] == uuid then
		response.prepare_content("application/json")
		response.status(200)
		local address = request.data["client"]
		
		if request.path[2] == "freei" then
			local result = addFreeUser(mac_addr)	
			if result ~= 0 then
				log:debug(result)
			end
		elseif request.path[2]=="login" then
			local user=request.data["username"]
			local passwd=request.data["password"]
			
			log:debug("Logging in User "..user)
			
			local mac_addr=getMAC(address)
			log:debug(mac_addr)	
			result=loginUser(user,passwd,address,mac_addr)
			log:debug(result)	
			
			if result == "ACCESS-ACCEPT" then
				log:debug("Accounting 001")
				startAccounting(user,address,mac_addr)
				addPaidUser(mac_addr)
				log:debug("Logged in User "..user)
			elseif result == "ACCESS-DENIED" then
			
				log:debug("Failed to login User "..user)
			else
				log:debug("An Error occured "..user)
			
			end
			--print(result)
		else
		
				log:debug("An Error occured "..user)
		end
		
		response.write(json.encode(request.data))
		log:debug(response)
		return nil
	end

	-- save original request url for login redirect
	
	local redirect = "http://" ..
		request.headers["Host"] ..
		request.env["REQUEST_URI"]
		log:info("splash" ..
           	" -> " .. (client or "unknown client") .. 
           	" -> " .. redirect
          ) 

  -- read & serve file
  local file = fs.realpath(splashconfig.root .. "/" .. splashconfig.page)
  local stat = fs.stat(file)
  --response.header["Content-Length"] = stat.size
  --response.header["Content-Type"] = mime.to_mime(file)
  local content = fs.readfile(file)

  local debug = "<pre>"
  debug = debug .. "original request: "
  debug = debug .. "http://"
  debug = debug .. request.headers["Host"]
  debug = debug .. request.env["REQUEST_URI"]
  debug = debug .. "</pre>"

  local script = "<script type='text/javascript'>\n"
  script = script .. "var portalgun = {};\n"
  script = script .. "portalgun.rest = {};\n"
  script = script .. "portalgun.rest.uuid = " .. json.encode("/" .. uuid) .. ";\n"
  script = script .. "portalgun.rest.free = " .. json.encode("/" .. uuid .. "/freei") .. ";\n"
  script = script .. "portalgun.rest.login = " .. json.encode("/" .. uuid .. "/login") .. ";\n"
  script = script .. "portalgun.redirect  = " .. json.encode(redirect) .. ";\n"
  script = script .. "portalgun.ipaddress  = " .. json.encode(client) .. ";\n"
  
  -- script = script .. "console.log('from server:');\n"
  -- script = script .. "console.log(JSON.stringify(portalgun.request));\n"
  -- script = script .. "console.log(JSON.stringify(portalgun.uuid));\n"
  
  script = script .. "</script>\n"

  local sha1 = [[
      <script type='text/javascript'>
        /*
         * A JavaScript implementation of the Secure Hash Algorithm, SHA-1, as defined
         * in FIPS 180-1
         * Version 2.2 Copyright Paul Johnston 2000 - 2009.
         * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
         * Distributed under the BSD License
         * See http://pajhome.org.uk/crypt/md5 for details.
         */
        var hexcase=0;var b64pad="";function hex_sha1(a){return rstr2hex(rstr_sha1(str2rstr_utf8(a)))}function hex_hmac_sha1(a,b){return rstr2hex(rstr_hmac_sha1(str2rstr_utf8(a),str2rstr_utf8(b)))}function sha1_vm_test(){return hex_sha1("abc").toLowerCase()=="a9993e364706816aba3e25717850c26c9cd0d89d"}function rstr_sha1(a){return binb2rstr(binb_sha1(rstr2binb(a),a.length*8))}function rstr_hmac_sha1(c,f){var e=rstr2binb(c);if(e.length>16){e=binb_sha1(e,c.length*8)}var a=Array(16),d=Array(16);for(var b=0;b<16;b++){a[b]=e[b]^909522486;d[b]=e[b]^1549556828}var g=binb_sha1(a.concat(rstr2binb(f)),512+f.length*8);return binb2rstr(binb_sha1(d.concat(g),512+160))}function rstr2hex(c){try{hexcase}catch(g){hexcase=0}var f=hexcase?"0123456789ABCDEF":"0123456789abcdef";var b="";var a;for(var d=0;d<c.length;d++){a=c.charCodeAt(d);b+=f.charAt((a>>>4)&15)+f.charAt(a&15)}return b}function str2rstr_utf8(c){var b="";var d=-1;var a,e;while(++d<c.length){a=c.charCodeAt(d);e=d+1<c.length?c.charCodeAt(d+1):0;if(55296<=a&&a<=56319&&56320<=e&&e<=57343){a=65536+((a&1023)<<10)+(e&1023);d++}if(a<=127){b+=String.fromCharCode(a)}else{if(a<=2047){b+=String.fromCharCode(192|((a>>>6)&31),128|(a&63))}else{if(a<=65535){b+=String.fromCharCode(224|((a>>>12)&15),128|((a>>>6)&63),128|(a&63))}else{if(a<=2097151){b+=String.fromCharCode(240|((a>>>18)&7),128|((a>>>12)&63),128|((a>>>6)&63),128|(a&63))}}}}}return b}function rstr2binb(b){var a=Array(b.length>>2);for(var c=0;c<a.length;c++){a[c]=0}for(var c=0;c<b.length*8;c+=8){a[c>>5]|=(b.charCodeAt(c/8)&255)<<(24-c%32)}return a}function binb2rstr(b){var a="";for(var c=0;c<b.length*32;c+=8){a+=String.fromCharCode((b[c>>5]>>>(24-c%32))&255)}return a}function binb_sha1(v,o){v[o>>5]|=128<<(24-o%32);v[((o+64>>9)<<4)+15]=o;var y=Array(80);var u=1732584193;var s=-271733879;var r=-1732584194;var q=271733878;var p=-1009589776;for(var l=0;l<v.length;l+=16){var n=u;var m=s;var k=r;var h=q;var f=p;for(var g=0;g<80;g++){if(g<16){y[g]=v[l+g]}else{y[g]=bit_rol(y[g-3]^y[g-8]^y[g-14]^y[g-16],1)}var z=safe_add(safe_add(bit_rol(u,5),sha1_ft(g,s,r,q)),safe_add(safe_add(p,y[g]),sha1_kt(g)));p=q;q=r;r=bit_rol(s,30);s=u;u=z}u=safe_add(u,n);s=safe_add(s,m);r=safe_add(r,k);q=safe_add(q,h);p=safe_add(p,f)}return Array(u,s,r,q,p)}function sha1_ft(e,a,g,f){if(e<20){return(a&g)|((~a)&f)}if(e<40){return a^g^f}if(e<60){return(a&g)|(a&f)|(g&f)}return a^g^f}function sha1_kt(a){return(a<20)?1518500249:(a<40)?1859775393:(a<60)?-1894007588:-899497514}function safe_add(a,d){var c=(a&65535)+(d&65535);var b=(a>>16)+(d>>16)+(c>>16);return(b<<16)|(c&65535)}function bit_rol(a,b){return(a<<b)|(a>>>(32-b))};
      </script>
  ]]

  response.prepare_content("text/html")
  response.status(200)
  response.write(content)
  response.write(script)
  response.write(sha1)
  response.write(debug)

  return nil
end

function addFreeUser(address)
	--local ret2 = ip6tables("mangle", "I", "PREROUTING", { in_interface =clientIface , proto = "tcp", dport = "80",source = address, jump =  "TPROXY" , tproxy_mark="0xfac/0xFFFFFFFF" , on_ip="2001:470:6826:20::1", on_port="3129" })
	local command  = "iptables -I "..portalChain.." -i "..clientIface.." -j ACCEPT -m mac --mac-source "..mac_addr
	local command2 = "ip6tables -I "..portalChain.." -i "..clientIface.." -j  ACCEPT -m mac --mac-source "..mac_addr
	local command3 = "iptables -t mangle -I PREROUTING -i "..clientIface.." -j ACCEPT -m mac --mac-source "..mac_addr
	local command4 = "ip6tables -t mangle -I PREROUTING -i "..clientIface.." -j ACCEPT -m mac --mac-source "..mac_addr
	--local command = "ip6tables -t mangle -I PREROUTING -i "..clientIface.." -p tcp --dport 80 -s ".. address .. "  -j TPROXY --tproxy-mark 0xfac/0xFFFFFFFF --on-ip 2001:470:6826:20::1 --on-port 3128"
	--local command2 = "iptables -t mangle -I PREROUTING -i "..clientIface.." -p tcp --dport 80 -s ".. address .. "  -j TPROXY --tproxy-mark 0xfac/0xFFFFFFFF --on-ip 10.0.20.1 --on-port 3128"
	os.execute(command)		
	os.execute(command2)		
	os.execute(command3)		
	os.execute(command4)		

end

function addPaidUser(mac_addr)
	--local ret2 = ip6tables("mangle", "I", "PREROUTING", { in_interface = clientIface, proto = "tcp", dport = "80",source = address, jump =  "TPROXY" , tproxy_mark="0xfac/0xFFFFFFFF" , on_ip="2001:470:6826:20::1", on_port="3129" })
		
	log:debug(mac_addr)
	if mac_addr ~= "NOT FOUND" then
		local command  = "iptables -I "..portalChain.." -i "..clientIface.."  -j ACCEPT -m mac --mac-source "..mac_addr
		local command2 = "ip6tables -I "..portalChain.." -i "..clientIface.."  -j ACCEPT -m mac --mac-source "..mac_addr
		local command3 = "iptables -t mangle -I PREROUTING -i "..clientIface.." -j ACCEPT -m mac --mac-source "..mac_addr
		local command4 = "ip6tables -t mangle -I PREROUTING -i "..clientIface.." -j ACCEPT -m mac --mac-source "..mac_addr
		--local command = "ip6tables -t mangle -I PREROUTING -i "..clientIface.." -p tcp --dport 80 -j TPROXY --tproxy-mark 0xfac/0xFFFFFFFF --on-ip 2001:470:6826:20::1 --on-port 3129 -m mac --mac-source " ..mac_addr
		--local command2 = "iptables -t mangle -I PREROUTING -i "..clientIface.." -p tcp --dport 80 -j TPROXY --tproxy-mark 0xfac/0xFFFFFFFF --on-ip 10.0.20.1 --on-port 3129 -m mac --mac-source  "..mac_addr
		os.execute(command)		
		os.execute(command2)		
		os.execute(command3)		
		os.execute(command4)		
	end
end

function ip6tables(table, action, chain, rulespec, options)
	local args = "-t " .. table .. " -"  .. action .. " " .. chain 

	for switch, value in pairs(rulespec) do
	
		--switch = string.gsub(switch, "_", "-")
		if switch == "options" then
			for option, spec in pairs(value) do
				args = args .. " -m " .. option
				for switch, value in pairs(spec) do
					switch = string.gsub(switch, "_", "-")
					
					args = args .. " --" .. switch .. " " .. value
				end
			end
		else
			args = args .. " --" .. switch .. " " .. value
		end
	end
  
	log:debug("running: ip6tables " .. args)
	local ret = os.execute("ip6tables " .. args) 
	log:debug("returned: " .. ret)

	ipt6:resync()

	return ret
end

function ip4tables(table, action, chain, rulespec, options)
	local args = "-t " .. table .. " -"  .. action .. " " .. chain 

	for switch, value in pairs(rulespec) do
	
		--switch = string.gsub(switch, "_", "-")
		if switch == "options" then
			for option, spec in pairs(value) do
				args = args .. " -m " .. option
				for switch, value in pairs(spec) do
					switch = string.gsub(switch, "_", "-")
					
					args = args .. " --" .. switch .. " " .. value
				end
			end
		else
			args = args .. " --" .. switch .. " " .. value
		end
	end
  
	log:debug("running: iptables " .. args)
	local ret = os.execute("iptables " .. args) 
	log:debug("returned: " .. ret)

	ipt6:resync()

	return ret
end



require "socket"
require "md5"

radclient={}
radclient.__index = radclient

AccessRequest		= 1
AccessAccept		= 2
AccessReject		= 3
AccountingRequest	= 4
AccountingResponse	= 5
AccessChallenge		= 11
StatusServer		= 12
StatusClient		= 13
DisconnectRequest	= 40
DisconnectACK		= 41
DisconnectNAK		= 42
CoARequest	    	= 43
CoAACK			    = 44
CoANAK		    	= 45

function radclient.create(dictionary)
	local client={}
	setmetatable(client,radclient)
	client.radserver=ash("uci get fabfi.@portal[0].radiusIP")
	client.radAuthport=ash("uci get fabfi.@portal[0].radiusAuthPort")
	client.radAcctport=ash("uci get fabfi.@portal[0].radiusAcctPort")
	client.radsecret=ash("uci get fabfi.@portal[0].radiusSecret")
	client.authenticator=radclient.createAuthenticator()
	client.AttributeTable={}
	client.dictTable={}
		io.input(dictionary)
		local line=io.read("*line")
		while ( line ) do
			start,fin=string.find(line,"ATTRIBUTE")
			if start==1 then
				subLine=string.sub(line,fin+1)
				for word in subLine:gmatch("%w+%-%w+") do 
					for num in subLine:gmatch("%d+") do
					client.dictTable[word]=num
					end
				end	
				for word in subLine:gmatch("%w+%-%w+%-%w+") do 
					for num in subLine:gmatch("%d+") do
					client.dictTable[word]=num
					end
				end	
			end
			line=io.read("*line")	
		end
	return client
end

function radclient:createAuthPacket(username, password)

	local auth = self:createAuthenticator() 
	self.AttributeTable["User-Name"]=username
	self.AttributeTable["User-Password"]=self:pwdCrypt(password,auth,self.radsecret )
	self.AttributeTable["Service-Type"]="\0\0\0"..string.char("1")
	self.AttributeTable["NAS-Identifier"]=ash("uci get system.@system[0].hostname")
	self.AttributeTable["Called-Station-Id"]=string.gsub(selfMac,":","-")

	
	local attributes = self:encodeAttributes()
	
	--HEADER STUFF--	
	local code=AccessRequest
	local ID=math.random(1,255)
	local packetLen=20+string.len(attributes)
	
	local binLen=string.char(math.floor(packetLen/256))..string.char(packetLen%256)
	local binID=string.char(ID)
	local binCode=string.char(code)
	
	header=binCode..binID..binLen..auth -- Auth packet header -- pack this as binary
	local packet=header..attributes	
	return packet 

end

function radclient:sendPacket(packet)

	local socket = require("socket")
	--local radIp = socket.try(socket.dns.toip(host))
	local radUDPsock = socket.try(socket.udp())
	radUDPsock:settimeout(10)
	socket.try(radUDPsock:sendto(packet, self.radserver, self.radAuthport))
	--io.write(socket.try((radUDPsock:receive())))
	reply=socket.try((radUDPsock:receive()))
	--io.write(reply)
	replyCode=string.byte(string.sub(reply,1,8))
	if replyCode == 2 then
		return "ACCESS-ACCEPT"
	elseif replyCode == 3 then	
		return "ACCESS-DENIED"
	else
		return "ERROR"
	end
end


function radclient:sendAcctPacket(packet)

	local socket = require("socket")
	log:debug("sending 1")
	--local radIp = socket.try(socket.dns.toip(host))
	local radUDPsock = socket.try(socket.udp())
	log:debug("sending 2")
	radUDPsock:settimeout(10)
	log:debug("sending 3")
	socket.try(radUDPsock:sendto(packet, self.radserver, self.radAcctport))
	log:debug("sending 4")
	reply=socket.try((radUDPsock:receive()))
	log:debug("sending 4")
	--io.write(reply)
--	replyCode=string.byte(string.sub(reply,1,8))
	return reply;
end

function radclient:AddAttribute(key,value)
	AttributeTable[key]=value	
end

function radclient:receivePacket()
	local packet = nil
	return packet
end

function radclient:encodeAttributes()
	attrList=""
	for k,v in pairs(self.dictTable) do
		for i,j in pairs(self.AttributeTable) do
			if i==k then
				local attrValue=j
				local attrID=string.char(v)
				local attrLen=string.char(2+string.len(attrValue))
				attrList=attrList..attrID..attrLen..attrValue
			end
			
		end
	end
	return attrList
			
end
 
function radclient:createAuthenticator()
	
	local result =""
	math.randomseed( os.time() )
	for i=0,15,1 do
		rand=math.random(1,255)
		local value=numberstring(rand,2)
		result=result..value
	end
	local authenticator=""
	for i=1,128,8 do 
		c=string.sub(result,i,i+7)
		d=Bin2Dec(c)
		authenticator=authenticator..string.char(d)
	end
	return authenticator
end     
                
function radclient:pwdCrypt(password, authenticator, secret)
	local buf=password
	local pwdLen=math.mod(string.len(password),16)
	if pwdLen~= 0 then
		local diff=16-pwdLen
		for i=1,diff,1 do
			buf=buf.."\0"
		end
	end
	
	local last = authenticator
	
	local result=""
	
	while string.len(buf) > 0 do
		local hash=md5.sum(secret..last)
		for i=1,16,1 do
			local k=string.sub(hash,i,i)
			local j=string.sub(buf,i,i)
			local c=string.char(xor( string.byte(j),string.byte(k) ))
			result=result..c
		end
		last=string.sub(result,-16)
		buf=string.sub(buf,17)
	end		
	
	return result
	
end


function radclient:createAcctStartPacket(username)

	log:debug("createAcctStartPacket")
	self.AttributeTable["User-Name"]=username
	self.AttributeTable["NAS-Identifier"]=ash("uci get system.@system[0].hostname")
	self.AttributeTable["Called-Station-Id"]=string.gsub(selfMac,":","-")
	self.AttributeTable["Acct-Status-Type"]="\0\0\0"..string.char("1") 
	
	log:debug("createAcctStartPacket i i i")
	local attributes= self:encodeAttributes()
	log:debug("createAcctStartPacket2")
	code=string.char("4")                                                                                                                
	identifier=string.char(math.random(1,255))                                                                                          
	packetLen=20+string.len(attributes)                                                                                                 
	totLen=string.char(math.floor(packetLen/256))..string.char(packetLen%256)                                   
	
	header=code..identifier..totLen                                                                  
	authenticator=md5.sum(string.sub(header,1,5).."\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"..attributes..self.radsecret)      
	log:debug("createAcctStartPacket3")
	packet=header..authenticator..attributes		
	return packet
end

function radclient:createAcctStopPacket(username)

	self.AttributeTable["User-Name"]=username
	self.AttributeTable["NAS-Identifier"]=ash("uci get system.@system[0].hostname")
	self.AttributeTable["Called-Station-Id"]=string.gsub(selfMac,":","-")
	attributes=encodeAttributes()
	code=string.char("5")                                                                                                                
	packetLen=20+string.len(attributes)                                                                                                 
	identifier=string.char(math.random(1,255))                                                                                          
	totLen=string.char(math.floor(packetLen/256))..string.char(packetLen%256)                                   
	authenticator=md5.sum(string.sub(header,1,5).."\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"..attributes..self.radsecret)      
	header=code..identifier..totLen..authenticator                                                                  
	packet=header..authenticator..attributes		
	return packet
end


--function radclient.create(radserver,radAuthport,radAcctport,radsecret,dictionary)

function loginUser(name,passwd,address,mac_addr)
	log:debug("Logging Started")
	client1=radclient.create(mainDictionary)
	log:debug("Dictionary loaded")
	log:debug(mac_addr)
	log:debug(address)
	client1.AttributeTable["Calling-Station-Id"]=string.gsub(mac_addr,":","-")
	client1.AttributeTable["Framed-IP-Address"]=encodeIPv4(address)
	log:debug(address)
	packet=client1:createAuthPacket(name,passwd,{})
	log:debug("Just about to send packet")
	result=client1:sendPacket(packet)
	return result
end

function startAccounting(name,address,mac_addr)
	log:debug("Starting Accounting")
	client1=radclient.create("/root/dictionary")
	client1.AttributeTable["Calling-Station-Id"]=string.gsub(mac_addr,":","-")
	log:debug("Starting Accounting")
	client1.AttributeTable["Framed-IP-Address"]=encodeIPv4(address)
	client1.AttributeTable["NAS-Port"]="0"
	log:debug("Accounting ready 1")
	packet=client1:createAcctStartPacket(name) --createAcctStartPacket
	log:debug("Accounting Ready")
	result=client1:sendAcctPacket(packet)
	log:debug("Accounting Sent")
	return result
end


function stopAccounting(name,address,mac_addr)
	client1=radclient.create("/root/dictionary")
	client1.AttributeTable["Calling-Station-Id"]=string.gsub(mac_addr,":","-")
	client1.AttributeTable["Framed-IP-Address"]=encodeIPv4(address)
	client1.AttributeTable["NAS-Port"]="0"
	log:debug("Accounting Sent")
	packet=client1:createAcctStopPacket(name)
	log:debug("Accounting Ready")
	result=client1:sendAcctPacket(packet)
	log:debug("Accounting Sent")
	return result
end
