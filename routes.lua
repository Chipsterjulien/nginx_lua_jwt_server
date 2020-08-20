local jwt = require( 'jwt' )
local json = require( 'json' )
local http = require( 'socket.http' )
local errorResponse = require( 'external.errorResponse' )
local ngx = ngx or require( 'ngx' )

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

local function checkProblems( queryParameters, data )
  -- check if where parameters is empty, not existing
  if not queryParameters.where then
    errorResponse( 404, 'No or not acceptable query parameters given' )
  end

  local where = queryParameters.where
  if where == "" then
    errorResponse( 400, "'where' query parameter is empty" )
  end

  if type( where ) ~= 'string' then
    errorResponse(
      400,
      "'where' query parameter is not a string (found a " .. type( where ) .. ')'
    )
  end

  -- Check if where exist in config file
  if not data[where] then
    errorResponse( 400, '[' .. where .. ']' .. ' is not known in confilg file' )
  end
end

local function getURL( url, timeout )
  -- Define timeout. Default is 5
  if timeout then
    http.TIMEOUT = timeout
  end

  local body, code, statusCode = http.request( url )

  if code ~= 200 then
    if type( code ) == 'number' then
      if not statusCode.connection then
        return nil, "Unable to get '" .. url
      else
        return nil, "Unable to get '" .. url .. "': connection " .. statusCode.connection
      end
    elseif type( code ) == 'string' then
      return nil, "Unable to get '" .. url .. "': " .. code
    end
  end

  return body:gsub( '\n', '' ), nil
end

local function startStop( queryParameters, data, action )
  checkProblems( queryParameters, data )

  -- buildURL
  local where = queryParameters.where
  local url = buildURL( data[ where ], action )

  -- contact url
  local dataStr, err = getURL( url, data.default.timeout )
  if err then
    errorResponse( 500, err )
  end

  if action == 'startAlarm' then
    local startFile = data.default.startFile

    if not startFile or startFile == '' then
      errorResponse( 500, '"startFile" is empty/not exists in config file' )
    end

    local fd = io.open( startFile, 'w' )
    fd:close()
  elseif action == 'stopAlarm' then
    local startFile = data.default.startFile
    os.remove(startFile)
  end

  ngx.say( dataStr )
end

------
-- Start routes
---------------

local routes = {}

function routes.getList( data )
  if not data.default.whereList then
    errorResponse( 404, "'whereList' not found in config file" )
  end

  local payload = {
    code = 200,
    whereList = data.default.whereList
  }

  ngx.say( json.encode( payload ) )
end

function routes.getState( data )
  local queryParameters = ngx.req.get_uri_args()

  checkProblems( queryParameters, data)

  -- buildURL
  local where = queryParameters.where
  local url = buildURL( data[ where ], 'stateAlarm' )

  -- contact url
  local dataStr, err = getURL( url, data.default.timeout )
  if err then
    errorResponse( 500, err )
  end

  ngx.say( dataStr )
end

function routes.refresh( data, myJWT )
  local newJWT, exp, err = jwt.refresh( myJWT, data.default.secretKey, data.default.exp )
  if err then
    errorResponse( 400, err )
  end

  -- Build payload response
  local payload = {
    code = 200,
    expire = os.date('!%Y-%m-%dT%H:%M:%SZ', exp),
    token = newJWT
  }

  ngx.say( json.encode( payload ) )
end

function routes.startAlarm( data )
  startStop( ngx.req.get_uri_args(), data, 'startAlarm' )
end

function routes.startStream( data )
  startStop( ngx.req.get_uri_args(), data, 'startStream' )
end

function routes.stopAlarm( data )
  startStop( ngx.req.get_uri_args(), data, 'stopAlarm' )
end

function routes.stopStream( data )
  startStop( ngx.req.get_uri_args(), data, 'stopStream' )
end

return routes
