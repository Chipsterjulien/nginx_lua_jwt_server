local jwt = require( "jwt" )
local http = require( "socket.http" )
local json = require( "json" )
http.TIMEOUT = 5

local function buildURL( location, action )
  return
    location.ip ..
    ( location.port and ( ":" .. location.port ) or "") ..
    ( location.api and (( location.api:sub( 1, 1 ) ~= "/" ) and "/" ) or "" ) ..
    ( location.api or "" ) ..
    ( location.api and (( location.api:sub( -1, -1 ) ~= "/" ) and "/" ) or "" ) ..
    action
end

local function checkProblems( queryParameters, debug, data )
  -- check if where parameters is empty, not existing
  if not queryParameters.where then
    errorResponse( debug, 404, "No or not acceptable query parameters given" )
    ngx.exit( 404 )
  end

  local where = queryParameters.where
  if where == "" then
    errorResponse( debug, 400, "'where' query parameter is empty" )
    ngx.exit( 400 )
  end

  if type( where ) ~= 'string' then
    errorResponse( debug, 400, "'where' query parameter is not a string (found a " .. type( where ) .. ")" )
    ngx.exit( 400 )
  end

  -- Check if where exist in config file
  if not data[where] then
    errorResponse( debug, 400, "[" .. where .. "]" .. " is not known in confilg file" )
    ngx.exit( 400 )
  end
end

local function getURL( url, timeout )
  -- Define timeout. Default is 5
  if timeout then
    http.TIMEOUT = timeout
  end

  local body, code, statusCode = http.request( url )

  if code ~= 200 then
    return nil, "Unable to get '" .. url .. "': connection " .. statusCode.connection
  end

  return body:gsub( "\n", "" ), nil
end

local function startStop( queryParameters, debug, data, action )
  checkProblems( queryParameters, debug, data )

  -- buildURL
  local where = queryParameters.where
  local url = buildURL( data[ where ], action )

  -- contact url
  local dataStr, err = getURL( url, data.default.timeout )
  if err then
    errorResponse( debug, 500, err )
    ngx.exit( 500 )
  end

  if action == "startAlarm" then
    local startFile = data.default.startFile
    local fd = os.open(startFile, 'w')
    fd:close()
  elseif action == "stopAlarm" then
    local startFile = data.default.startFile
    os.remove(startFile)
  end

  ngx.say( dataStr )
  ngx.exit( 200 )
end

------
-- Start routes
---------------

local routes = {}

function routes.getList( debug, data )
  if not data.default.whereList then
    errorResponse( debug, 404, "'whereList' not found in config file" )
    ngx.exit( 404 )
  end

  local payload = {
    code = 200,
    whereList = data.default.whereList
  }

  ngx.say( json.encode( payload ) )
  ngx.exit( 200 )
end

function routes.getState( debug, data )
  local queryParameters = ngx.req.get_uri_args()

  checkProblems( queryParameters, debug, data)

  -- buildURL
  local where = queryParameters.where
  local url = buildURL( data[ where ], "stateAlarm" )

  -- contact url
  local dataStr, err = getURL( url, data.default.timeout )
  if err then
    errorResponse( debug, 500, err )
    ngx.exit( 500 )
  end

  ngx.say( dataStr )
  ngx.exit( 200 )
end

function routes.refresh( debug, data, myJWT )
  local newJWT, exp, err = jwt.refresh( myJWT, data.default.secretKey, data.default.exp )
  if err then
    errorResponse( debug, 400, err )
    ngx.exit( 400 )
  end

  -- Build payload response
  local payload = {
    code = 200,
    expire = os.date('!%Y-%m-%dT%H:%M:%SZ', exp),
    token = newJWT
  }

  ngx.say( json.encode( payload ) )
  ngx.exit( 200 )
end

function routes.startAlarm( debug, data )
  startStop( ngx.req.get_uri_args(), debug, data, "startAlarm" )
end

function routes.startStream( debug, data )
  startStop( ngx.req.get_uri_args(), debug, data, "startStream" )
end

function routes.stopAlarm( debug, data )
  startStop( ngx.req.get_uri_args(), debug, data, "stopAlarm" )
end

function routes.stopStream( debug, data )
  startStop( ngx.req.get_uri_args(), debug, data, "stopStream" )
end

return routes
