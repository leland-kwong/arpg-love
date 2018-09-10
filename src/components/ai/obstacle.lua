local Math = require 'utils.math'
local Obstacle = {}

local obstacles = {}

function Obstacle:new(x, y, size)
	local obstacle = {
		x = x,
		y = y,
		size = size
	}
	setmetatable(obstacle, self)
	self.__index = self
	table.insert(obstacles, obstacle)
	return obstacle
end

function Obstacle:getNearest(x, y)
	local nearestDist = math.huge
	local nearestObstacle = nil

	for i=1, #obstacles do
		local o = obstacles[i]
		local dist = Math.dist(x, y, o.x, o.y) - o.size * 0.5
		if dist <= nearestDist then
			nearestDist = dist
			nearestObstacle = o
		end
	end

	return nearestObstacle, nearestDist
end

return Obstacle