#!/usr/bin/luajit

-- https://blog.elao.com/fr/infra/acceder-api-cross-domain-depuis-javascript-avec-cors-reverse-proxy-nginx/

package.path = package.path .. ';/app/?.lua;/app/external/?.lua;/app/third-party/?.lua'

local confFile = '/app/cfg/guiAlarm.toml'

local json = require( 'json' )
local toml = require( 'toml' )
local jwt = require( 'jwt' )
local external = require( 'external' )

local ngx = ngx or require( 'ngx' )

local function main()
  local data, err = external.loadConfig( confFile, toml.parse )

  if err then
    external.errorResponse( 500, err )
  end

  -- Check if request method is POST
  local requestMethod = ngx.var.request_method
  if requestMethod ~= 'POST' then
    external.errorResponse(
      405,
      requestMethod .. ' method is not supported in ' .. ngx.var.uri .. ' call'
    )
  end

  -- Explicitly read the request body
  ngx.req.read_body()
  -- Get data from request body
  local body = ngx.req.get_body_data()
  if not body or body == "" then
    external.errorResponse( 400, 'No data found' )
  end

  local ok, bodyJSON = pcall( json.decode, body )
  if not ok or external.isTableEmpty( bodyJSON ) then
    external.errorResponse( 500, 'Unable to decode string to JSON' )
  end

  if not bodyJSON.username then
    external.errorResponse( 400, 'Username are missing' )
  end
  if not bodyJSON.password then
    external.errorResponse( 400, 'Password are missing' )
  end

  local db = ngx.shared.db
  local value = db:get( bodyJSON.username )

  if value ~= bodyJSON.password then
    external.errorResponse( 400, 'Bad username and/or password' )
  end

  -- Build payload to create signature
  local payload = {
    sub = data.default.sub,
    exp = ngx.time() + data.default.exp,
    iat = ngx.time()
  }

  local myJWT, exp
  myJWT, exp, err = jwt.sign(payload, data.default.secretKey, data.default.alg)

  if err then
    external.errorResponse( 400, err )
  end

  -- Build payload response
  payload = {
    code = 200,
    expire = os.date('!%Y-%m-%dT%H:%M:%SZ', exp),
    token = myJWT
  }

  ngx.say( json.encode( payload ) )
  ngx.exit( 200 )
end

------
-- Start here
-------------

main()