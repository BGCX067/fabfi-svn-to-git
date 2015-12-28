--[[ logging ]]--
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


--[[ modules.portalgun ]]--
module("modules.splash", package.seeall)

local splashconfig = { -- TODO configure via uci.lucid
  root = "/www/splash",
  page = "index.html"
}


-- [[ implementation ]]--
function GET(request, response)
  return splash(request, response)
end
function POST(request, response)
  return splash(request, response)
end


-- Splash page
function splash(request, response)
  log:debug("splash" .. 
            " -> " .. json.encode(request.verb) ..
            " -> " .. json.encode(request.path) ..
            " -> " .. json.encode(request.query) ..
            " -> " .. json.encode(request.data)) 

  -- get client address
  local client = request.headers["X-Forwarded-For"] or 
                 request.env["REMOTE_ADDR"] 

  -- check for and dispatch any portalgun operations
  local uuid = md5.sumhexa(request.env["HTTP_HOST"])
  if request.path[1] == uuid then
    log:debug("dispatching portalgun operation: " .. json.encode(request.path))
    response.prepare_content("application/json")
    response.status(200)
    response.write(json.encode(request.data))
    return nil
  end

  -- save original request url for login redirect
  local redirect = "http://" ..
                   request.headers["Host"] ..
                   request.env["REQUEST_URI"]
  log:info("splash" ..
           " -> " .. (client or "unknown client") .. 
           " -> " .. redirect)

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
  script = script .. "portalgun.rest.free = " .. json.encode("/" .. uuid .. "/free") .. ";\n"
  script = script .. "portalgun.redirect  = " .. json.encode(redirect)
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