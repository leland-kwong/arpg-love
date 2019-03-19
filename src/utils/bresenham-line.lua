-- FIXME: certain param combinations can cause an infinite loop
local maxTries = 1000
local abs = math.abs

local DONE = 'DONE'
-- OPTIMIZE: if the line is one of the 8 cardinal directions, then we should just draw a straight path
local function bline(x0, y0, x1, y1, callback, initialCallbackValue)
	local dx = abs(x1 - x0)
	local dy = abs(y1 - y0)
	local signX = (x0 < x1) and 1 or -1
	local signY = (y0 < y1) and 1 or -1
	local err = dx - dy

	local result, done
	local i = 0
	while true do
		i = i + 1
		if i > maxTries then
			return error('bresenham line tried too many times -'..x0..","..y0..","..x1..","..y1)
		end

		result, done = callback(initialCallbackValue, x0, y0, i, DONE)
		local isEndOfLine = ((x0 == x1) and (y0 == y1))
		if done == DONE or isEndOfLine then
			return result
		end

		local e2 = 2 * err;
		if (e2 > -dy) then
			err = err - dy
			x0  = x0 + signX
		end
		if (e2 < dx) then
			err = err + dx
			y0  = y0 + signY
		end
	end

	return result
end

return bline