#!/usr/bin/luajit

package.path = package.path .. ';/app/?.lua;/app/external/?.lua;/app/third-party/?.lua'

local splitN = require( 'external.splitN' )
local readEntireFile = require( 'external.readEntireFile' )
local ngx = ngx or require( 'ngx' )

local dbFile = '/app/db/dbFile.db'

local function main()
  local data = readEntireFile( dbFile )
  local dataSplitted = splitN( data, '\n' )

  -- Load all login and password in shared memory
  for _, line in ipairs( dataSplitted ) do
    if line ~= '' then
      local login, password = unpack( splitN( line, ' ' ) )

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
