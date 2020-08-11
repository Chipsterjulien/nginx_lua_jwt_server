local function isTableEmpty( data )
  for _ in pairs( data ) do
    return false
  end

  return true
end

return isTableEmpty