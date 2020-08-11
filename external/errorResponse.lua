local json = require( 'json' )
local ngx = ngx or require( 'ngx' )

local function errorResponse( codeINT, errorStr )
  ngx.status = codeINT
  ngx.log( ngx.STDERR, errorStr )

  ngx.say( json.encode( { error = errorStr, code = codeINT } ) )

  ngx.exit( codeINT )
end

return errorResponse