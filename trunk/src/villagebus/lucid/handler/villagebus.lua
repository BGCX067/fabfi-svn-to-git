--[[
LuCId HTTP-Slave
(c) 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

--[[ my dependencies ]]--
require "logging.file"
logname = "/var/log/villagebus.log"
local log = logging.file(logname)
if not log then
  log = logging.file("/dev/null")
end
log:setLevel(logging.DEBUG)
log:debug("loaded luci.lucid.http.handler.villagebus") 
local io = require "io"
local json = require "json"

--local dsp = require "luci.dispatcher"
local dsp = require "villagebus.dispatcher"
local util = require "luci.util"
local http = require "luci.http"
local ltn12 = require "luci.ltn12"
local srv = require "luci.lucid.http.server"
local coroutine = require "coroutine"
local type = type

--- LuCI web handler
-- @cstyle instance
module "luci.lucid.http.handler.villagebus"

--- Create a Villagebus web handler.
-- @class function
-- @param name Name
-- @param prefix Dispatching prefix
-- @return LuCI web handler object
Villagebus = util.class(srv.Handler)

function Villagebus.__init__(self, name, prefix)
  srv.Handler.__init__(self, name)
  self.prefix = prefix
  --dsp.indexcache = "/tmp/luci-indexcache"
end

--- Handle a HEAD request.
-- @param request Request object
-- @return status code, header table, response source
function Villagebus.handle_HEAD(self, ...)
  local stat, head = self:handle_GET(...)
  return stat, head
end

--- Handle a POST request.
-- @param request Request object
-- @return status code, header table, response source
function Villagebus.handle_POST(self, ...)
  return self:handle_GET(...)
end

--- Handle a PUT request.
-- @param request Request object
-- @return status code, header table, response source
function Villagebus.handle_PUT(self, ...)
  return self:handle_GET(...)
end

--- Handle a GET request.
-- @param request Request object
-- @return status code, header table, response source
function Villagebus.handle_GET(self, request, sourcein)
  local http_Request= http.Request(
    request.env,
    sourcein
  )

  local res, id, data1, data2 = true, 0, nil, nil
  local headers = {}
  local status = 200
  local active = true
  local dsp_httpdispatch = coroutine.create(dsp.httpdispatch)

  while not id or id < 3 do
    -- horrible hack to restore request headers to the world of the sane
    res, id, data1, data2 = coroutine.resume(dsp_httpdispatch, http_Request, self.prefix, request.headers)

    if not res then
      status = 500
      headers["Content-Type"] = "text/plain"
      return status, headers, ltn12.source.string(id)
    end

    if id == 1 then
      status = data1
    elseif id == 2 then
      if not headers[data1] then
        headers[data1] = data2
      elseif type(headers[data1]) ~= "table" then
        headers[data1] = {headers[data1], data2}
      else
        headers[data1][#headers[data1]+1] = data2
      end
    end
  end

  if id == 6 then
    while (coroutine.resume(dsp_httpdispatch)) do end
    return status, headers, srv.IOResource(data1, data2)
  end

  local function iter()
    local res, id, data = coroutine.resume(dsp_httpdispatch)
    if not res then
      return nil, id
    elseif not id or not active then
      return true
    elseif id == 5 then
      active = false
      while (coroutine.resume(dsp_httpdispatch)) do 
      end
      return nil
    elseif id == 4 then
      return data
    end
  end

  return status, headers, iter
end

