--[[ logging ]]--
require "logging.file"
logname = "/var/log/villagebus.log"
local log = logging.file(logname)
if not log then
  log = logging.file("/dev/null")
end
-- log:setLevel(logging.INFO)
log:setLevel(logging.DEBUG)
log:debug("loaded villagebus.modules.portalgun") 


--[[ dependencies ]]--

require "luci.sys.iptparser" -- http://luci.subsignal.org/api/luci/modules/luci.sys.iptparser.html
local ipt = luci.sys.iptparser.IptParser(6)


--[[ utilities ]]--

-- Return the output of a shell command as a string
function os.pexecute(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end



--[[ modules.portalgun ]]--
module("modules.portalgun", package.seeall)

-- also see: http://quamquam.org/~jow/luci-splash


-- /portalgun/list/[ipaddr] -> [ {rule}, ... ]
function list(request, response)
  --local rules = ipt:find({ target   = "REJECT", 
  --                         protocol = "tcp", 
  --                         options  = { "reject-with", "tcp-reset" } }) 
  
  ipt:resync()
  --[[local tables = ipt:tables()
  log:debug("tables: " .. json.encode(tables))
  for _,table in ipairs(tables) do
    local chains = ipt:chains(table)
    log:debug("  " .. table .. " -> chains: " .. json.encode(chains))
    for _,chain in ipairs(chains) do
      local rules = ipt:chain(table, chain)
      log:debug("    " .. table .. " ->  " .. chain .. ": " .. json.encode(rules))
    end
  end ]]--

  if not request.path[1] then
    local rules = ipt:chain("filter", "PORTALGUN")
    if not rules or not rules["rules"] then
      return {}
    end
    return rules["rules"]
  else
    local rule = ipt:find({ table  = "filter",
                            chain  = "PORTALGUN",
                            source = request.path[1] })
    return rule
  end
end


-- GET /portalgun/origin/%{CALLING-STATION-ID} -> %{Framed-IP-Address}
function origin(request, response)
  local macaddr = request.path[1]
  if not macaddr then
    return { error = "usage: /portalgun/origin/%{CALLING-STATION-ID}" }
  end
  
  return { raw = "Framed-IPV6-Address := " .. "2001:470:8c0e:fab:1e4b:d6ff:fe80:dada\n" }
end


-- TODO implement DELETE for lucid so we can have proper REST semantics
local post_dispatch = {}
function post(request, response)
  local name = table.remove(request.path, 1)
  return post_dispatch[name](request, response)
end

local delete_dispatch = {}
function delete(request, response)
  local name = table.remove(request.path, 1)
  return delete_dispatch[name](request, response)
end


-- /portalgun/post/ip6addr/<ipaddr> -> [ {rule}, ... ]
post_dispatch["ip6addr"] = function(request, response)
  log:debug("portalgun.post.ip6addr" ..
            " -> " .. json.encode(request))

  ipt:resync()

  local ipaddr = request.path[1]
  if not ipaddr then
    return { error = "usage: /portalgun/post/ip6addr/<ip address>" }
  end

  -- check if portal already exists
  local rule = ipt:find({ table  = "filter",
                          chain  = "PORTALGUN",
                          source = ipaddr })  
  if rule[1] then
    return rule
  end

  -- insert rules for portal
  local ret = ip6tables("I", "PORTALGUN", { source = ipaddr,
                                            jump   = "ACCEPT" })
  if ret ~= 0 then
    return { error = "failed to create portal: " .. ipaddr }
  end

  return ipt:find({ table  = "filter",
                    chain  = "PORTALGUN",
                    source = ipaddr })
end


-- /portalgun/post/macaddr/<macaddr> -> [ {rule}, ... ]
post_dispatch["macaddr"] = function(request, response)
  log:debug("portalgun.post.macaddr" ..
            " -> " .. json.encode(request))

  ipt:resync()

  local macaddr = request.path[1]
  if not macaddr then
    return { error = "usage: /portalgun/post/macaddr/<mac address>" }
  end

  -- normalize radius packet data: CALLING_STATION_ID="HH-HH-HH-HH-HH-HH"
  macaddr = string.upper(macaddr)
  macaddr = string.gsub(macaddr, "-", ":")  

  -- check if portal already exists
  local rule = ipt:find({ table   = "filter",
                          chain   = "PORTALGUN",
                          options = { "MAC", macaddr } })  
  if rule[1] then
    return rule
  end

  -- insert rules for portal
  local ret = ip6tables("I", "PORTALGUN", { options = { 
                                              mac = { mac_source = macaddr }
                                            },
                                            jump = "ACCEPT" })
  if ret ~= 0 then
    return { error = "failed to create portal: " .. macaddr }
  end

  return ipt:find({ table  = "filter",
                    chain  = "PORTALGUN",
                    options = { "MAC", macaddr } })  
end


-- /portalgun/delete/ip6addr/<ipaddr> -> {}   TODO http://wiki.freeradius.org/Disconnect-Messages
delete_dispatch["ip6addr"] = function(request, response)
  log:debug("portalgun.delete.ip6addr" ..
            " -> " .. json.encode(request))

  ipt:resync()

  local ipaddr = request.path[1]
  if not ipaddr then
    return { error = "usage: /portalgun/delete/ip6addr/<ip address>" }
  end

  -- check that portal exists
  local rule = ipt:find({ table  = "filter",
                          chain  = "PORTALGUN",
                          source = ipaddr })  
  if not rule[1] then
    return {}
  end
  
  -- delete rules for portal
  local ret = ip6tables("D", "PORTALGUN", { source = ipaddr,
                                            jump   = "ACCEPT" })
  if ret ~= 0 then
    return { error = "failed to delete portal: " .. ipaddr }
  end
  
  -- returns: {} on success
  return ipt:find({ table  = "filter",
                    chain  = "PORTALGUN",
                    source = ipaddr })
end


-- /portalgun/delete/macaddr/<macaddr> -> {}   TODO http://wiki.freeradius.org/Disconnect-Messages
delete_dispatch["macaddr"] = function(request, response)
  log:debug("portalgun.delete.macaddr" ..
            " -> " .. json.encode(request))

  ipt:resync()

  local macaddr = request.path[1]
  if not macaddr then
    return { error = "usage: /portalgun/delete/macaddr/<mac address>" }
  end

  -- normalize radius packet data: CALLING_STATION_ID="HH-HH-HH-HH-HH-HH"
  macaddr = string.upper(macaddr)
  macaddr = string.gsub(macaddr, "-", ":")  

  -- check that portal exists
  local rule = ipt:find({ table  = "filter",
                          chain  = "PORTALGUN",
                          options = { "MAC", macaddr } })  
  if not rule[1] then
    return {}
  end
  
  -- delete rules for portal
  local ret = ip6tables("D", "PORTALGUN", { options = { 
                                              mac = { mac_source = macaddr }
                                            },
                                            jump = "ACCEPT" })
  if ret ~= 0 then
    return { error = "failed to delete portal: " .. macaddr }
  end
  
  -- returns: {} on success
  return ipt:find({ table  = "filter",
                    chain  = "PORTALGUN",
                    options = { "MAC", macaddr } })  
end


-- portal management
portals = {
  GET  = function(request, response)
           return { getportals = request }
         end,
  POST = function(request, response)
           return { postportals = request }
         end
}



-- iptables
--   # alllow a specific ipv6 host
--   ip6tables -I PORTALGUN -s 2001:470:1f07:c42:1e4b:d6ff:fe80:dada -j ACCEPT #-m comment --comment "client beta"
--   
--   # remove a specific ipv6 host
--   ip6tables -D PORTALGUN -s 2001:470:1f07:c42:1e4b:d6ff:fe80:dada -j ACCEPT #-m comment --comment "client beta"
--
function ip6tables(action, chain, rulespec, options)
  local args = "-" .. action .. " " .. chain 
  for switch, value in pairs(rulespec) do
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

  ipt:resync()

  return ret
end
