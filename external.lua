local external = {}

function external.isTableEmpty(data)
  for _ in pairs(data) do
    return false
  end

  return true
end

function external.loadConfig(filename, toml)
  local tomlStr = external.readEntireFile(filename)

  if not tomlStr then
    return nil, filename .. " config file is not existed"
  end

  local data = toml.parse(tomlStr)

  if external.isTableEmpty(data) then
    return nil, filename .. " is an empty config file"
  end

  return data, nil
end

function external.readEntireFile(filename)
  local f = io.open(filename, "rb")

  if f == nil then return nil end

  local content = f:read("*a")
  f:close()

  return content
end

function external.splitN(str, sep, maxSplit)
  sep = sep or ' '
  maxSplit = maxSplit or #str
  local t = {}
  local s = 1
  local e, f = str:find(sep, s, true)

  while e do
    maxSplit = maxSplit - 1
    if maxSplit <= 0 then break end

    table.insert(t, str:sub(s, e - 1))
    s = f + 1
    e, f = str:find(sep, s, true)
  end

  if s <= #str then
    table.insert(t, str:sub(s))
  end

  return t
end

return external