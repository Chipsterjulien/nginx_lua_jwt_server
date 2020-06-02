#!/usr/bin/luajit

-- https://blog.elao.com/fr/infra/acceder-api-cross-domain-depuis-javascript-avec-cors-reverse-proxy-nginx/

package.path = package.path .. ";/app/?.lua"

local confFile = "/app/cfg/guiAlarm.toml"

local json = require("json")
local toml = require("toml")
local jwt = require("jwt")
local external = require("external")

local function errorResponse( debug, codeINT, errorStr )
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
  local data, err = external.loadConfig( confFile, toml )
  local debug = false

  if data and data.debug ~= nil then debug = data.debug end

  if err then
    errorResponse( debug, 500, err )
    ngx.exit( 500 )
  end

  -- Check if request method is POST
  local requestMethod = ngx.var.request_method
  if requestMethod ~= 'POST' then
    errorResponse( debug, 405, requestMethod .. " method is not supported in " .. ngx.var.uri .. " call" )
    ngx.exit( 405 )
  end

  -- Explicitly read the request body
  ngx.req.read_body()
  -- Get data from request body
  local body = ngx.req.get_body_data()
  if not body or body == "" then
    errorResponse( debug, 400, "No data found" )
    ngx.exit( 400 )
  end

  local bodyJSON = json.decode(body)
  if external.isTableEmpty(bodyJSON) then
    errorResponse( debug, 500, "Unable to decode string to JSON" )
    ngx.exit( 500 )
  end

  if not bodyJSON.username then
    errorResponse( debug, 400, "Username are missing" )
    ngx.exit( 400 )
  end
  if not bodyJSON.password then
    errorResponse( debug, 400, "Password are missing" )
    ngx.exit( 400 )
  end

  local db = ngx.shared.db
  local value = db:get( bodyJSON.username )

  if value ~= bodyJSON.password then
    errorResponse( true, 400, "Bad username and/or password" )
    ngx.exit( 400 )
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
    errorResponse( debug, 400, err )
    ngx.exit( 400 )
  end

  -- Build payload response
  payload = {
    code = 200,
    expire = os.date('!%Y-%m-%dT%H:%M:%SZ', exp),
    token = myJWT
  }

  ngx.say( json.encode( payload ) )
end

------
-- Start here
-------------

main()