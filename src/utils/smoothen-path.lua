--[[
interpolates points that have a slope that isn"t 45 degrees using the Bresenham line algorithm. This allows us to generate a path that feels a bit more natural by skipping intermediate points when possible.
]]--

local hasObstaclePoints = require("utils.path-obstacles")
local table = table

--[[
	Reduces a path so that if a direct line can be reached between two points, then all
	points in between are filtered out. This allows us to have more in-between directions
	that go beyond the 8-direction.
]]--
local function smoothen_path(grid, path, walkable)
	local path_count = #path
	local index = 2
	local isDirectPath = index >= path_count
	if isDirectPath then
		return path
	end

	local newPath = {
		path[1]
	}
	while (index < path_count) do
		local pt1 = newPath[#newPath] -- start with most recently inserted pt in new path
		local pt2 = path[index]
		local ptMaybeSkip = path[index + 1]
		local canSkip = not hasObstaclePoints(grid, pt1, ptMaybeSkip, walkable)

		if not canSkip then
			table.insert(newPath, pt2)
		end

		index = index + 1

		if index == path_count then
			local endPt = path[path_count]
			table.insert(newPath, endPt)
		end
	end
	return newPath
end

return smoothen_path