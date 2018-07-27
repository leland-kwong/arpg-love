local floor, sqrt, pow = math.floor, math.sqrt, math.pow

local math_utils = {}

function math_utils.round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return floor(num * mult + 0.5) / mult
end

function math_utils.dist(x1, y1, x2, y2)
	local a = pow(x2 - x1, 2)
	local b = pow(y2 - y1, 2)
	return sqrt(a + b)
end

return math_utils