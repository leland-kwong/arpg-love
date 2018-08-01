local makeGrid = require("utils.make-grid")
local iterateGrid = require("utils.iterate-grid")
local cloneGrid = require("utils.clone-grid")
local printGrid = require("utils.print-grid")
local floodFill = require("utils.flood-fill")
local socket = require 'socket'

local EXIT = 'E'

-- navigates a grid orthogonally from a start point to an end point
local function navigateGrid(grid, x1, y1, x2, y2, callback)
	local dx = x2 - x1
	local dy = y2 - y1
	local directionX = dx == 0 and 0 or (dx < 0 and -1 or 1)
	local directionY = dy == 0 and 0 or (dy < 0 and -1 or 1)
	local i = -1
	local y = y1
	local x = x1
	local dist = dx ~= 0 and math.abs(dx) or math.abs(dy)
	while i < dist do
		local v = grid[y][x]
		callback(v, x, y)
		x = x + directionX
		y = y + directionY
		i = i + 1
	end
end

-- makes a random entrance starting from a point in the room
local availableDirections = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}} -- array to get a random direction from (left,right,up,down)
local function makeEntrance(grid, x1, y1, roomSize)
	local exitCount = 0
	local directions = {unpack(availableDirections)}
	local exitPositions = {}
	while (exitCount < 1) and (#directions > 0) do
		local randomDirection = math.random(1, #directions)

		-- set initial coordinates to center of room
		local x2, y2 = x1, y1

		-- continue until a wall is hit
		while true do
			local isOutOfBounds = y2 == 1 or y2 == #grid or x2 == 1 or x2 == #grid[1]
			if isOutOfBounds then
				break
			else
				local cellValue = grid[y2][x2]

				local dirX = directions[randomDirection][1]
				local dirY = directions[randomDirection][2]
				local nextX = x2 + dirX
				local nextY = y2 + dirY

				local isWall = cellValue == 0
				-- create an exit
				if isWall then
					exitCount = exitCount + 1
					local e1, e2 = {y2,x2}, {nextY,nextX}
					grid[y2][x2] = EXIT
					grid[nextY][nextX] = EXIT

					-- widen entrance
					local isXAxis = dirX ~= 0
					local maxWidenBy = math.floor(roomSize / 3)
					-- FIXME: maxWidenBy is currently at 4 due to floodfill stack overflow issues
					local widenBy = math.random(1, maxWidenBy > 4 and 4 or maxWidenBy)
					if isXAxis then
						if roomSize > 2 then
							navigateGrid(grid, x2, y2-widenBy, x2, y2+widenBy, function(_, x, y)
								grid[y][x] = EXIT
								-- the wall is 2 units thick
								grid[y][nextX] = EXIT
							end)
						else
							-- widen down
							grid[y2 + 1][x2] = EXIT
							grid[nextY + 1][nextX] = EXIT
						end
					else
						if roomSize > 2 then
							navigateGrid(grid, x2-widenBy, y2, x2+widenBy, y2, function(_, x, y)
								grid[y][x] = EXIT
								-- the wall is 2 units thick
								grid[nextY][x] = EXIT
							end)
						else
							-- widen right
							grid[y2][x2 + 1] = EXIT
							grid[nextY][nextX + 1] = EXIT
						end
					end

					break
				end

				-- set next position
				x2 = nextX
				y2 = nextY
			end
		end

		table.remove(directions, randomDirection)
	end
	return exitPositions
end

local function isValidDungeon(map)
	local isValidDungeon = false

	local walkableCells = 0
	iterateGrid(map, function(v)
		if v == 1 then
			walkableCells = walkableCells + 1
		end
	end)

	local newC = 'F'
	local floodedCells = 0
	local floodMap = cloneGrid(map)
	floodFill(floodMap, 3, 3, 1, newC, function(x, y)
		if floodMap[y][x] == newC then
			floodedCells = floodedCells + 1
		end
	end)

	return walkableCells == floodedCells
end

local function buildRooms(mapSize, roomSize, tryCount)
	local ms, rs = mapSize, roomSize
	local walkable = 1
	local wall = 0

	local ars = roomSize + 2 -- adjustedRoomSize
	local roomCount = mapSize
	local mSize = ars * roomCount -- map size
	local map = makeGrid(mSize, mSize)
	local roomDefinition = makeGrid(ars, ars)
	-- center of room relative to room
	local cx = math.ceil(#roomDefinition / 2)
	local cy = math.ceil(#roomDefinition[1] / 2)
	local roomCenters = {}

	local y = 1
	while y < mSize do
		local x = 1
		while x < mSize do

			-- translate room cell definition to map
			iterateGrid(roomDefinition, function(_,x2,y2)
				local yEdge = (y + y2 - 1)
				local xEdge = (x + x2 - 1)
				local isEdge = yEdge == 1 or xEdge == 1 or yEdge == mSize or xEdge == mSize
				local isWall = y2 == 1 or y2 == ars or x2 == 1 or x2 == ars
				local v = isWall and 0 or 1
				if isEdge then
					v = 2
				end

				-- set cell definition relative to map
				local a,b = y + y2 - 1, x + x2 - 1
				map[a][b] = v
			end)

			table.insert(roomCenters, {cx + x - 1, cy + y - 1})

			x = x + ars
		end
		y = y + ars
	end

	for i=1, #roomCenters do
		local x,y = unpack(roomCenters[i])
		makeEntrance(map, x, y, roomSize)
	end

	return map
end

local function createMap(mapSize, roomSize)
	local done = false
	local map = nil
	local tryCount = 0
	local t = socket.gettime()

	while not done do
		map = buildRooms(mapSize, roomSize)

		-- transform map cells to 0 and 1 (these correspond to walkable and unwalkable values)
		for y=1, #map do
			for x=1, #map do
				local isEdge = map[y][x] == 2
				if isEdge then
					map[y][x] = 0
				end
				local isExit = map[y][x] == EXIT
				if isExit then
					map[y][x] = 1
				end
			end
		end

		done = isValidDungeon(map)
		tryCount = tryCount + 1
	end

	return {
		grid = map,
		tryCount = tryCount,
		buildTime = (socket.gettime() - t) * 1000
	}
end

--[[
local map = createMap(4, 4)
printGrid(map.grid, ' ', function(v)
	if v == 0 then
		return 'x'
	end
	return v == 1 and ' ' or v
end)
print(map.tryCount, map.buildTime)
--]]

return createMap