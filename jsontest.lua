local encode, decode, dkencode, dkdecode


local test_module, opt = ... -- command line argument
--local test_module = 'cmj-json'
--local test_module = 'dkjson'
--local test_module = 'dkjson-nopeg'
--local test_module = 'fleece'
--locel test_module = 'lua-yajl'
--local test_module = 'mp-cjson'
--local test_module = 'nm-json'
--local test_module = 'sb-json'
--local test_module = 'th-json'

if test_module == 'dkjson-nopeg' then
  test_module = 'dkjson'
  package.preload["lpeg"] = function () error "lpeg disabled" end
  package.loaded["lpeg"] = nil
  lpeg = nil
end

do
  -- http://chiselapp.com/user/dhkolf/repository/dkjson/
  local dkjson = require "dkjson"
  dkencode = dkjson.encode
  dkdecode = dkjson.decode
end

if test_module == 'cmj-json' then
  -- http://json.luaforge.net/
  local json = require "cmjjson" -- renamed, the original file was just 'json'
  encode = json.encode
  decode = json.decode
elseif test_module == 'dkjson' then
  -- http://chiselapp.com/user/dhkolf/repository/dkjson/
  encode = dkencode
  decode = dkdecode
elseif test_module == 'fleece' then
  -- http://www.eonblast.com/fleece/
  local fleece = require "fleece"
  encode = function(x) return fleece.json(x, "E4") end
elseif test_module == 'lua-yajl' then
  -- http://github.com/brimworks/lua-yajl
  local yajl = require ("yajl")
  encode = yajl.to_string
  decode = yajl.to_value
elseif test_module == 'mp-cjson' then
  -- http://www.kyne.com.au/~mark/software/lua-cjson.php
  local json = require "cjson"
  encode = json.encode
  decode = json.decode
elseif test_module == 'nm-json' then
  -- http://luaforge.net/projects/luajsonlib/
  local json = require "LuaJSON"
  encode = json.stringify
  decode = json.parse
elseif test_module == 'sb-json' then
  -- http://www.chipmunkav.com/downloads/Json.lua
  local json = require "sbjson" -- renamed, the original file was just 'Json'
  encode = json.Encode
  decode = json.Decode
elseif test_module == 'th-json' then
  -- http://luaforge.net/projects/luajson/
  local json = require "json"
  encode = json.encode
  decode = json.decode
else
  print "No module specified"
  return
end

if not encode then
  print ("No encode method")
else
  local x, r

  local function test (x, s)
    return string.match(x, "^%s*%[%s*%\"" .. s .. "%\"%s*%]%s*$")
  end

  x = encode{ "'" }
  if not test(x, "%'") then
    print("\"'\" isn't encoded correctly:", x)
  end

  x = encode{ "\011" }
  if not test(x, "%\\u000[bB]") then
    print("\\u000b isn't encoded correctly:", x)
  end

  x = encode{ "\000" }
  if not test(x, "%\\u0000") then
    print("\\u0000 isn't encoded correctly")
  end

  r,x = pcall (encode, { [1000] = "x" })
  if not r then
    print ("encoding a sparse array raises an error:", x)
  else
    if #x > 30 then
      print ("sparse array encoded as:", x:sub(1,15).." <...> "..x:sub(-15,-1), "#"..#x)
    else
      print ("sparse array encoded as:", x)
    end
  end

  r, x = pcall(encode, { math.huge*0 }) -- NaN
  if not r then
    print ("encoding NaN raises an error:", x)
  else
    r = dkdecode(x)
    if not r then
      print ("NaN isn't converted into valid JSON:", x)
    elseif type(r[1]) == "number" and r[1] == r[1] then -- a number, but not NaN
      print ("NaN is converted into a valid number:", x)
    else
      print ("NaN is converted to:", x)
    end
  end

  if test_module == 'fleece' then
    print ("Fleece (0.3.1) is known to freeze on +/-Inf")
  else
    r, x = pcall(encode, { math.huge }) -- +Inf
    if not r then
      print ("encoding +Inf raises an error:", x)
    else
      r = dkdecode(x)
      if not r then
        print ("+Inf isn't converted into valid JSON:", x)
      else
        print ("+Inf is converted to:", x)
      end
    end

    r, x = pcall(encode, { -math.huge }) -- -Inf
    if not r then
      print ("encoding -Inf raises an error:", x)
    else
      r = dkdecode(x)
      if not r then
        print ("-Inf isn't converted into valid JSON:", x)
      else
        print ("-Inf is converted to:", x)
      end
    end
  end
end

if not decode then
  print ("No decode method")
else
  local x, r

  x = decode[=[ ["\u0000"] ]=]
  if x[1] ~= "\000" then
    print ("\\u0000 isn't decoded correctly")
  end

  x = decode[=[ ["\u20AC"] ]=]
  if x[1] ~= "\226\130\172" then
    print ("\\u20AC isn't decoded correctly")
  end

  x = decode[=[ ["\uD834\uDD1E"] ]=]
  if x[1] ~= "\240\157\132\158" then
    print ("\\uD834\\uDD1E isn't decoded correctly")
  end

  r, x = pcall(decode, [=[
{"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x":
{"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x":
{"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x":
{"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x":
"deep down"
    }    }    }    }    }     }    }    }    }    }     }    }    }    }    }
    }    }    }    }    }     }    }    }    }    }     }    }    }    }    }
    }    }    }    }    }     }    }    }    }    }     }    }    }    }    }
    }    }    }    }    }     }    }    }    }    }     }    }    }    }    }
]=])

  if not r then
    print ("decoding a deep nested table raises an error:", x)
  else
    local i = 0
    while type(x) == 'table' do
      i = i + 1
      x = x.x
    end
    if i ~= 60 or x ~= "deep down" then
      print ("deep nested table isn't decoded correctly")
    end
  end

  if test_module == 'cmj-json' then
    print ("decoding a big array takes ages (or forever?) on cmj-json")
  else
    r, x = pcall(decode, "["..("0,"):rep(100000).."0]")
    if not r then
      print ("decoding a big array raises an error:", x)
    else
      if type(x) ~= 'table' or #x ~= 100001 then
        print ("big array isn't decoded correctly")
      end
    end
  end

  r, x = pcall(decode, "{}")
  if not r then
    print ("decoding an empty object raises an error:", x)
  end

  r, x = pcall(decode, "[]")
  if not r then
    print ("decoding an empty array raises an error:", x)
  end

  -- special tests for dkjson:
  if test_module == 'dkjson' then
    x = dkdecode[=[ [{"x":0}] ]=]
    if getmetatable(x).__jsontype ~= 'array' then
      print ("<metatable>.__jsontype ~= array")
    end
    if getmetatable(x[1]).__jsontype ~= 'object' then
      print ("<metatable>.__jsontype ~= object")
    end
  end
end

if encode and opt == "refcycle" then
  local a = {}
  a.a = a
  print ("Trying a reference cycle...")
  encode(a)
end

if encode and (opt or ""):sub(1,3) == "esc" then

local strchar, strbyte, strformat = string.char, string.byte, string.format
local floor = math.floor

local function unichar (value)
  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar (value)
  elseif value <= 0x07ff then
    return strchar (0xc0 + floor(value/0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar (0xe0 + floor(value/0x1000),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar (0xf0 + floor(value/0x40000),
                    0x80 + (floor(value/0x1000) % 0x40),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local escapecodes = {
  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
  ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t", ["/"] = "\\/"
}

local function escapeutf8 (uchar)
  local a, b, c, d = strbyte (uchar, 1, 4)
  a, b, c, d = a or 0, b or 0, c or 0, d or 0
  if a <= 0x7f then
    value = a
  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
    value = (a - 0xc0) * 0x40 + b - 0x80
  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
  else
    return ""
  end
  if value <= 0xffff then
    return strformat ("\\u%.4x", value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
    return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)
  else
    return ""
  end
end

  local x,xe

  local t = {}
  local esc = {}
  local escerr = {}
  local range
  if opt == "esc_full" then range = 0x10ffff
  elseif opt == "esc_asc" then range = 0x7f
  else range = 0xffff end

  for i = 0,range do
    t[1] = unichar(i)
    xe = encode(t)
    x = string.match(xe, "^%s*%[%s*%\"(.*)%\"%s*%]%s*$")
    if type(x) ~= 'string' then
      escerr[i] = xe
    elseif string.lower(x) == escapeutf8(t[1]) then
      esc[i] = 'u'
    elseif x == escapecodes[t[1]] then
      esc[i] = 'c'
    elseif x:sub(1,1) == "\\" then
      print ("Invalid escape code for "..i..":", x)
    end
  end
  do
    local i = 0
    while i <= range do
      local first
      while i <= range and not esc[i] do i = i + 1 end
      if not esc[i] then break end
      first = i
      while esc[i] do i = i + 1 end
      if i-1 > first then
        print ("Escaped from "..first.." to "..i-1)
      else
        print ("Escaped "..first)
      end
    end
  end
  do
    local i = 0
    while i <= range do
      local first
      while i <= range and not escerr[i] do i = i + 1 end
      if not escerr[i] then break end
      first = i
      while escerr[i] do i = i + 1 end
      if i-1 > first then
        print ("Errors while escaping from "..first.." to "..i-1)
      else
        print ("Errors while escaping "..first)
      end
    end
  end

end

-- Copyright (C) 2011 David Heiko Kolf
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
-- BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE. 


