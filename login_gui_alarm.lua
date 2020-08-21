#!/usr/bin/luajit

package.path = package.path .. ';/app/?.lua;/app/external/?.lua;/app/third-party/?.lua'

local confFile = '/app/cfg/guiAlarm.toml'

local json = require( 'json' )
local jwt = require( 'jwt' )
local loadConfig = require( 'external.loadConfig' )
local isTableEmpty = require( 'external.isTableEmpty' )
local errorResponse = require( 'external.errorResponse' )
local ngx = ngx or require( 'ngx' )

local function main()
  local data, err = loadConfig( confFile )

  if err then
    errorResponse( 500, err )
  end

  -- Check if request method is POST
  local requestMethod = ngx.var.request_method
  if requestMethod ~= 'POST' then
    errorResponse(
      405,
      requestMethod .. ' method is not supported in ' .. ngx.var.uri .. ' call'
    )
  end

  -- Explicitly read the request body
  ngx.req.read_body()
  -- Get data from request body
  local body = ngx.req.get_body_data()
  if not body or body == '' then
    errorResponse( 400, 'No data found' )
  end

  local ok, bodyJSON = pcall( json.decode, body )
  if not ok or isTableEmpty( bodyJSON ) then
    errorResponse( 500, 'Unable to decode string to JSON' )
  end

  if not bodyJSON.username then
    errorResponse( 400, 'Username are missing' )
  end
  if not bodyJSON.password then
    errorResponse( 400, 'Password are missing' )
  end

  local db = ngx.shared.db
  local value = db:get( bodyJSON.username )

  if value ~= bodyJSON.password then
    errorResponse( 400, 'Bad username and/or password' )
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
    errorResponse( 400, err )
  end

  -- Build payload response
  payload = {
    code = 200,
    expire = os.date('!%Y-%m-%dT%H:%M:%SZ', exp),
    token = myJWT
  }

  ngx.say( json.encode( payload ) )

  ngx.log( ngx.NOTICE, string.format( '\n\nLogin elapsed time: %.2f ms\n\n', ( os.clock() - initTime ) * 1000 ) )

  ngx.exit( 200 )
end

------
-- Start here
-------------
initTime = os.clock()
main()
