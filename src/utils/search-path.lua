local pathfinder = require("modules.jumper.index")
local smoothen_path = require("utils.smoothen-path")
local memoize = require("utils.memoize")
local lru = require "utils.lru"
local pprint = require 'utils.pprint'
--local printGrid = require "utils.print-grid"

local pathFindersByGrid = {}

local makeGrid = memoize(function (mapGrid)
	return Grid(mapGrid)
end)

local function normalizePath(path)
	for i=1, #path do
		local v = path[i]
		-- remap values to array indices so we can access the data like an array
		v[1] = v._x
		v[2] = v._y
	end
	return path
end

--[[

Optimize:
If the distance isn't long (only a few tiles away) we can first try a direct path using
ray casting via bresenham line algorithm. The assumption is the character is close enough
to the destination where the likelihood of obstacles is small.

]]--
local HEURISTIC = pathfinder.Heuristics.EUCLIDIAN
local MODE = 'ORTHOGONAL'
local FINDER_NAME = "JPS"
local TYPE_NUMBER = 'number'
local errorMessages = {
	walkable = 'walkable value must be a number'
}
local function search_path(map, startX, startY, endX, endY, walkable, clearance)
	assert(type(walkable) == TYPE_NUMBER, errorMessages.walkable)
	local notMoving = (startX == endX) and (startY == endY)
	if notMoving then
		return nil
	end

	-- Creates a grid object
	local grid = makeGrid(map)

	local finder = pathFindersByGrid[grid] or
		Pathfinder(grid, FINDER_NAME, walkable)
			:setHeuristic(HEURISTIC)
			:setMode(MODE)
			:annotateGrid()

	pathFindersByGrid[grid] = finder

	-- Calculates the path, and its length
	local path = finder:getPath(startX, startY, endX, endY, clearance)

	if path == nil then
		return nil
	end

	--[[
		TODO: optimize to lazily smoothen the path via iterators.
	]]--
	-- local result = smoothen_path(map, compressedPath, walkable)
	return path:filter()._nodes
end

return search_path