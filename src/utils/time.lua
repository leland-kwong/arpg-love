local socket = require 'socket'

function getTime()
  return socket.gettime() * 1000
end

function toMinutes(seconds)
  return seconds/60
end

function toHours(seconds)
  return toMinutes(seconds)/60
end

function toDays(seconds)
  return toHours(seconds)/24
end

local Time = {
  __call = getTime,
  toMinutes = toMinutes,
  toHours = toHours,
  toDays = toDays
}
Time.__index = Time
return setmetatable(Time, Time)