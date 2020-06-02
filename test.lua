#!/usr/bin/luajit

local jwt = require("jwt")

local payload = {
  sub = "1234567890",
  name = "John Doe",
  iat = 1516239022,
}

print(jwt.sign(payload, "your-256-bit-secret"))