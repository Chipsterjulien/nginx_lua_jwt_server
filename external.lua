local external = {}

local ngx = ngx or require( 'ngx' )
local json = require( 'json' )

function external.errorResponse( codeINT, errorStr )
  ngx.status = codeINT
  ngx.log( ngx.STDERR, errorStr )

  ngx.say( json.encode( { error = errorStr, code = codeINT } ) )

  ngx.exit( codeINT )
end

function external.isTableEmpty( data )
  for _ in pairs( data ) do
    return false
  end

  return true
end

function external.loadConfig( filename, parseToml )
  local tomlStr = external.readEntireFile( filename )

  if not tomlStr then
    return nil, filename .. ' config file is not existed'
  end

  -- Config file must endling by empty line
  if not tomlStr:match( '\n$' ) then
    tomlStr = tomlStr .. '\n'
  end

  local data = parseToml( tomlStr )

  if external.isTableEmpty( data ) then
    return nil, filename .. ' is an empty config file'
  end

  return data, nil
end

function external.readEntireFile( filename )
  local f = io.open( filename, 'rb' )

  if f == nil then return nil end

  local content = f:read( '*a' )
  f:close()

  return content
end

function external.splitN( str, sep, maxSplit )
  sep = sep or ' '
  maxSplit = maxSplit or #str
  local t = {}
  local s = 1
  local e, f = str:find( sep, s, true )

  while e do
    maxSplit = maxSplit - 1
    if maxSplit <= 0 then break end

    table.insert( t, str:sub( s, e - 1 ) )
    s = f + 1
    e, f = str:find( sep, s, true )
  end

  if s <= #str then
    table.insert( t, str:sub( s ) )
  end

  return t
end

return external