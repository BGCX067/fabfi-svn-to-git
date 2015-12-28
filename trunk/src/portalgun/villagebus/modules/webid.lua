--[[ logging ]]--
require "logging.file"
logname = "/var/log/villagebus.log"
local log = logging.file(logname)
if not log then
  log = logging.file("/dev/null")
end
log:setLevel(logging.DEBUG)
log:debug("loaded villagebus.modules.webid") 


--[[ dependencies ]]--


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


--[[ modules.webid ]]--
module("modules.webid", package.seeall)


-- http://webid.info/
-- http://digitalbazaar.com/2010/08/07/webid/
-- http://webid.myxwiki.org/xwiki/bin/view/WebId/CreateCert


-- /webid/generate
function generate(request, response)
  log:debug("webid.generate" ..
            " -> " .. json.encode(request))
  return {}
end


-- /webid/authenticate
function authenticate(request, response)
  log:debug("webid.authenticate" ..
            " -> " .. json.encode(request))
  return {}
end

