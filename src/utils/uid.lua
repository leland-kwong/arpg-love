local socket = require 'socket'
math.randomseed(socket.gettime())

local random = math.random

local function toHex(number)
	return string.format('%x', number)
end

local seed = toHex(socket.gettime() * 10000)
local increment = 0
local function uid()
	local newId = seed.."_"..increment
	-- increment
	increment = increment + 1
	return newId
end

return uid