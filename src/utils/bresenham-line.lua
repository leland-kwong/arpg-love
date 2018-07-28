-- FIXME: certain param combinations can cause an infinite loop
local maxTries = 1000
local abs = math.abs

-- OPTIMIZE: if the line is one of the 8 cardinal directions, then we should just draw a straight path 
local function bline(x0, y0, x1, y1, callback, initialCallbackValue) 
	local dx = abs(x1-x0)
	local dy = abs(y1-y0)
	local sx = (x0 < x1) and 1 or -1
	local sy = (y0 < y1) and 1 or -1
	local err = dx-dy	

	local tryCount = 0
	while true do
		tryCount = tryCount + 1
		if tryCount > maxTries then
			return error('bresenham line tried too many times -'..x0..","..y0..","..x1..","..y1)
		end

		local shouldBreak = callback(initialCallbackValue, x0, y0) == false;
		if shouldBreak then
			return
		end

		if ((x0==x1) and (y0==y1)) then
			return
		end

		local e2 = 2 *err;
		if (e2 >-dy) then 
			err = err - dy
			x0  = x0 + sx
		end
		if (e2 < dx) then 
			err = err + dx
			y0  = y0 + sy
		end
	end
end

return bline