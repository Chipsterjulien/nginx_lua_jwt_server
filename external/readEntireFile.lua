local function readEntireFile( filename )
  local f = io.open( filename, 'rb' )

  if f == nil then return nil end

  local content = f:read( '*a' )
  f:close()

  return content
end

return readEntireFile