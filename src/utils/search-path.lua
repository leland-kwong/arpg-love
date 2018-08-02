local pathfinder = require("modules.jumper.index")
local smoothen_path = require("utils.smoothen-path")
local memoize = require("utils.memoize")
local lru = require "utils.lru"
--local printGrid = require "utils.print-grid"

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

local cache = lru.new(400)
local sep = "_"
--[[

Optimize:
If the distance isn't long (only a few tiles away) we can first try a direct path using
ray casting via bresenham line algorithm. The assumption is the character is close enough
to the destination where the likelihood of obstacles is small.

]]--
local HEURISTIC = pathfinder.Heuristics.EUCLIDIAN
local FINDER_NAME = "JPS"
local function search_path(self, map, start_grid_pt, end_grid_pt, walkable)
	-- Define start and goal locations coordinates
	local startx, starty = unpack(start_grid_pt)
	local endx, endy = unpack(end_grid_pt)
	local cacheKey = startx..sep..starty..sep..endx..sep..endy
	local fromCache = cache:get(cacheKey)

	if fromCache then
		return fromCache
	end

	local notMoving = (startx == endx) and (starty == endy)
	if notMoving then
		return nil
	end

	-- Creates a grid object
	local grid = makeGrid(map)
	local path = Pathfinder(grid, FINDER_NAME, walkable)
		:setHeuristic(HEURISTIC)
		-- Calculates the path, and its length
		:getPath(startx, starty, endx, endy)

	if path == nil then
		return nil
	end

	local compressedPath = normalizePath(path:filter()._nodes)
	--[[
		TODO: optimize to lazily smoothen the path via iterators.
	]]--
	local result = smoothen_path(map, compressedPath, walkable)
	cache:set(cacheKey, result)
	return result
end

return search_path