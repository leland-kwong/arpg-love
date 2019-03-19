local floor, sqrt, pow, min, max = math.floor, math.sqrt, math.pow, math.min, math.max

local M = {}

function M.round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return floor(num * mult + 0.5) / mult
end

function M.dist(x1, y1, x2, y2)
	local a = x2 - x1
	local b = y2 - y1
	return sqrt(a*a + b*b)
end

function M.normalizeVector(a, b)
	local c = sqrt(a*a + b*b)
  -- dividing by zero returns a NAN value, so we should coerce to zero
  if c == 0 then
	return 0.0, 0.0
  else
    return a/c, b/c
  end
end

function M.clamp(v, min, max)
	if (v < min) then
		return min
	end
	if (v > max) then
		return max
	end
	return v
end

function M.sign(v)
	if v == 0 then
		return 0
	end
	return v > 0 and 1 or -1
end

function M.calcPulse(freq, time)
  return 0.5 * math.sin(freq * time) + 0.5
end

function M.isRectangleWithinRadius(circleX, circleY, circleR, rectX, rectY, rectWidth, rectHeight)
  local nearestX, nearestY = M.nearestBoxPoint(circleX, circleY, rectX, rectY, rectWidth, rectHeight)
  return circleR >= M.dist(circleX, circleY, nearestX, nearestY)
end

-- returns the point on a rectangle closest to the provided point
function M.nearestBoxPoint(x1, y1, rectX, rectY, rectWidth, rectHeight)
	local nearestX = max(rectX, min(x1, rectX + rectWidth))
	local nearestY = max(rectY, min(y1, rectY + rectHeight))
	return nearestX, nearestY
end

function M.randomSign()
	return math.random(0, 1) == 0 and 1 or -1
end

return M