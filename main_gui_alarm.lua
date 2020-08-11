#!/usr/bin/luajit

-- Using:
--  curl localhost:8090/api/state
--  or
--  http localhost:8090/api/state

-- Examples:
--  curl -d '{"username":"admin", "password":"admin"}' -H "Content-Type: application/json" -X POST localhost:8090/login
--  curl localhost:8090/api/v1/getList -H "Content-Type: application/json" -H "Authorization: Bearer xxxxxxx"
--
--  http -v --json POST localhost:8090/login username=admin password=admin
--  http -v -f GET localhost:8090/api/v1/getList "Authorization:Bearer xxxxxxxxx"  "Content-Type: application/json"

package.path = package.path .. ';/app/?.lua;/app/external/?.lua;/app/third-party/?.lua'

local jwt = require( 'jwt' )
local routes = require( 'routes' )
local loadConfig = require( 'external.loadConfig' )
local errorResponse = require( 'external.errorResponse' )
local ngx = ngx or require( 'ngx' )

local confFile = '/app/cfg/guiAlarm.toml'

local getWebRoutes = {
  ['/getList'] = function( data ) routes.getList( data ) end,
  ['/getState'] = function( data ) routes.getState( data ) end,
  ['/startAlarm'] = function( data ) routes.startAlarm( data ) end,
  ['/startStream'] = function( data ) routes.startStream( data ) end,
  ['/stopAlarm'] = function( data ) routes.stopAlarm( data) end,
  ['/stopStream'] = function( data ) routes.stopStream( data ) end,
  ['/refresh'] = function( data, myJWT ) routes.refresh( data, myJWT ) end,
}

------
-- Functions
------------

local function main()
  local data, err = loadConfig( confFile )

  if err then
    errorResponse( 500, err )
  end

  local headers = ngx.req.get_headers()
  if not headers or not headers.authorization then
    errorResponse( 401, "Header's authorization is missing" )
  end

  local myJWT = headers.authorization:gsub( 'Bearer ', '' )

  local _
  _, _, err = jwt.verify( myJWT, data.default.secretKey, true )
  if err then
    errorResponse( 401, err )
  end

  local routeInitial = data.default.routeInitial:gsub( "/$", '' )
  local road = ngx.var.uri:gsub( routeInitial, '' )

  if not getWebRoutes[ road ] then
    errorResponse( 404, ngx.var.uri .. ' URL does not exist' )
  end

  getWebRoutes[ road ]( data, myJWT )
end

------
-- Start here
-------------

main()
