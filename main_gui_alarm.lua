#!/usr/bin/luajit

-- Using:
--  curl localhost:8090/api/state
--  or
--  http localhost:8090/api/state

-- Examples:
--  curl -d '{"username":"admin", "password":"admin"}' -H "Content-Type: application/json" -X POST localhost:8000/login
--  http -v --json POST localhost:8000/login username=admin password=admin
--  http -v -f GET localhost:8090/api/v1/e "Authorization:Bearer xxxxxxxxx"  "Content-Type: application/json"

package.path = package.path .. ";/app/?.lua"

local json = require("json")
local jwt = require("jwt")
local toml = require("toml")
local routes = require("routes")
local external = require("external")

local confFile = "/app/cfg/guiAlarm.toml"

local getWebRoutes = {
  ["/getList"] = function( debug, data ) routes.getList( debug, data ) end,
  ["/getState"] = function( debug, data ) routes.getState( debug, data ) end,
  ["/startAlarm"] = function( debug, data ) routes.startAlarm( debug, data ) end,
  ["/startStream"] = function( debug, data ) routes.startStream( debug, data ) end,
  ["/stopAlarm"] = function( debug, data ) routes.stopAlarm( debug, data) end,
  ["/stopStream"] = function( debug, data ) routes.stopStream( debug, data ) end,
  ["/refresh"] = function( debug, data, myJWT ) routes.refresh( debug, data, myJWT ) end,
}

------
-- Functions
------------

function errorResponse( debug, codeINT, errorStr )
  -- In debug mode, send the right error otherwise, to "counter" somes attacks, send a status code to 200
  if not debug then
    ngx.log(ngx.STDERR, errorStr)

    ngx.status = 200
    ngx.exit(200)
  end

  ngx.status = codeINT
  ngx.say(json.encode({error = errorStr}))

  ngx.log(ngx.STDERR, errorStr)
end

local function main()
  local data, err = external.loadConfig(confFile, toml)
  local debug = false

  if data and data.debug ~= nil then debug = data.debug end

  if err then
    errorResponse(debug, 500, err)
    ngx.exit(500)
  end

  local headers = ngx.req.get_headers()
  if not headers or not headers.authorization then
    errorResponse( true, 401, "Header's authorization is missing" )
    ngx.exit( 401 )
  end

  local myJWT = headers.authorization:gsub( "Bearer ", "" )

  local _
  _, _, err = jwt.verify( myJWT, data.default.secretKey, true )
  if err then
    errorResponse( true, 401, err )
    ngx.exit( 401 )
  end

  local routeInitial = data.default.routeInitial:gsub( "/$", "" )
  local road = ngx.var.uri:gsub( routeInitial, "" )

  if not getWebRoutes[road] then
    errorResponse(debug, 404, ngx.var.uri .. " URL does not exist")
    ngx.exit(404)
  end

  getWebRoutes[road](debug, data, myJWT)
end

------
-- Start here
-------------

main()
