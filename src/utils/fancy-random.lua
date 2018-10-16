-- NOTE: built-in math.random() is faster for integer ranges
-- random number generator that supports decimal ranges
local socket = require 'socket'
math.randomseed(socket.gettime())

local function hasDecimal(v)
  return v % 1 > 0
end

local mult = 100000
local divisor = 1/mult
local function rollValue(minVal, maxVal, decimalPlaces)
  assert(minVal <= maxVal, 'minVal should be less than or equal to max')
  if hasDecimal(minVal) or hasDecimal(maxVal) then
    local result = math.random(
      minVal * mult,
      maxVal * mult
    )
    result = result * divisor
    if decimalPlaces then
      return tonumber(string.format('%0.'..decimalPlaces..'f', result))
    end
    return result
  end
  return math.random(minVal, maxVal)
end

return rollValue