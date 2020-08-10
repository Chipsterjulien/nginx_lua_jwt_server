#!/usr/bin/luajit

package.path = package.path .. ';/app/?.lua'

local dbFile = '/app/db/dbFile.db'

local external = require( 'external' )

local function main()
  local data = external.readEntireFile( dbFile )
  local dataSplitted = external.splitN( data, "\n" )

  -- Load all login and password in shared memory
  for _, line in ipairs( dataSplitted ) do
    if line ~= '' then
      local login, password = unpack( external.splitN( line, " " ) )

      local db = ngx.shared.db
      local success, err = db:set( login, password )

      if not success then
        io.stderr:write( 'Unable to set ' .. login .. ' in shared memory: ' .. err )
      end
    end
  end
end

------
-- Start here
-------------

main()
