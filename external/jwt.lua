local basexx = require( "basexx" )
local sha2 = require( "sha2" )
local json = require( "json" )
local splitN = require( 'splitN' )

local alg_sign = {
  ['HS256'] = function( data, key ) return sha2.hmac(sha2.sha256, key, data) end,
  ['HS384'] = function( data, key ) return sha2.hmac(sha2.sha384, key, data) end,
  ['HS512'] = function( data, key ) return sha2.hmac(sha2.sha512, key, data) end
}

local alg_verify = {
  ['HS256'] = function( data, signature, key ) return signature == sha2.hex2bin(alg_sign['HS256'](data, key)) end,
  ['HS384'] = function( data, signature, key ) return signature == sha2.hex2bin(alg_sign['HS384'](data, key)) end,
  ['HS512'] = function( data, signature, key ) return signature == sha2.hex2bin(alg_sign['HS512'](data, key)) end
}

local jwt = {}

function jwt.sign( payload, key, alg )
  if type(payload) ~= 'table' then return nil, nil, "Argument #1 must be table" end
  if type(key) ~= 'string' then return nil, nil, "Argument #2 must be string" end

  alg = alg or 'HS256'

  if not alg_sign[alg] then
    return nil, nil, "Algorithm not supported"
  end

  local header = { typ = 'JWT', alg = alg }

  -- Check if payload have exp claims
  if not payload.exp then
    -- Expire in 1 hour if not set
    payload.exp = os.time() + 3600
  end

  local segments = {
    -- Encode somes datas to a string then to base64 url safe
    basexx.to_url64( json.encode( header ) ),
    basexx.to_url64( json.encode( payload ) )
  }

  -- Concat headers and payload
  local signing_input = table.concat(segments, ".")
  -- Sign with right algo and get hexa signature
  local signature_hex = alg_sign[alg](signing_input, key)
  -- Convert hexa signature to bin
  local signature_bin = sha2.hex2bin(signature_hex)

  segments[#segments+1] = basexx.to_url64(signature_bin)

  return table.concat(segments, "."), payload.exp
end

function jwt.refresh( JWTstr, key, validityPeriod )
  if validityPeriod == nil then validityPeriod = 3600 end
  if type( validityPeriod ) ~= 'number' then return nil, "Argument #3 must be nil or a number" end

  local body, header, err = jwt.verify( JWTstr, key, true )
  if err then
    return nil, nil, err
  end

  body.exp = os.time() + validityPeriod

  return jwt.sign( body, key, header.alg )
end

function jwt.verify( JWTstr, key, verify )
  if key and verify == nil then verify = true end
  if type( JWTstr ) ~= 'string' then return nil, "Argument #1 must be string" end
  if verify and type( key ) ~= 'string' then return nil, "Argument #2 must be string" end

  local token = splitN( JWTstr , '.')

  if #token ~= 3 then
    return nil, "Invalid token"
  end

  -- Can use unpack but there is somes issues with old lua version so, I prefer use as below
  local headerb64, bodyb64, sigb64 = token[1], token[2], token[3]

  local ok, header, body, sig = pcall( function ()
    return json.decode(basexx.from_url64(headerb64)),
           json.decode(basexx.from_url64(bodyb64)),
           basexx.from_url64(sigb64)
  end)

  if not ok then
    return nil, nil, "Invalid json"
  end

  if verify then
    if not header.typ or header.typ ~= "JWT" then
      return nil, nil, "Invalid typ"
    end

    if not header.alg or type(header.alg) ~= "string" then
      return nil, nil, "Invalid alg"
    end

    if body.exp and type(body.exp) ~= "number" then
      return nil, nil, "exp must be number"
    end

    if body.nbf and type(body.nbf) ~= "number" then
      return nil, nil, "nbf must be number"
    end

    if not alg_verify[header.alg] then
      return nil, nil, "Algorithm not supported"
    end

    if not alg_verify[header.alg](headerb64 .. "." .. bodyb64, sig, key) then
      return nil, nil, "Invalid signature"
    end

    if body.exp and os.time() >= body.exp then
      return nil, nil, "Not acceptable by exp"
    end

    if body.nbf and os.time() < body.nbf then
      return nil, nil, "Not acceptable by nbf"
    end
  end

  return body, header
end

return jwt