local increment = 0
local function uid()
	-- increment
	increment = increment + 1
	return tostring(increment)
end

return uid