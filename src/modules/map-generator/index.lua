-- [original algorithm](https://medium.freecodecamp.org/how-to-make-your-own-procedural-dungeon-map-generator-using-the-random-walk-algorithm-e0085c8aa9a)

local makeGrid = require("utils.make-grid")
local printGrid = require("utils.print-grid")
local adjacentRoomsAlgorithm = require("modules.map-generator.adjacent-rooms.index")

local fi = 1 -- first index of array

local Map = {
	WALKABLE = function(v)
		return v and v.walkable
	end
}

-- widens the map by increasing everything by a factor of the tunnel width
function Map.widen(map, tunnelWidth)
	local rows, cols = #map, #map[1]
	local w = tunnelWidth
	local newMap = makeGrid(rows * w, cols * w)
	for y=1, #map do
		for x=1, #map[y] do
			local v = map[y][x]
			local x0,y0 = x * w, y * w
			for i=y0 - w + 1, y0 do
				for j=x0 - w + 1, x0 do
					newMap[i][j] =v
				end
			end
		end
	end

	return newMap
end

function Map.createBasicLabrynth(dimensions, maxNumOfTunnels, maxTunnelLength, emptyValue, fillValue)
	local bw = 1 -- map outer border width
	local maxTunnels = maxNumOfTunnels -- max number of tunnels possible
	local maxLength = maxTunnelLength -- max length each tunnel can have
	local map = makeGrid(dimensions, dimensions, emptyValue) -- create a 2d array full of 1's
	local currentRow = math.random(1 + bw, dimensions - bw) -- our current row - start at a random spot
	local currentColumn = math.random(1 + bw, dimensions - bw) -- our current column - start at a random spot
	local directions = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}} -- array to get a random direction from (left,right,up,down)
	local lastDirection = nil -- save the last direction we went
	local randomDirection = nil-- next turn/direction - holds a value from directions
	local mapArea = dimensions * dimensions

	local function getLastDirection(index)
		if lastDirection then
			return lastDirection[index]
		end
		-- return an arbitrary number that isn't 1, -1 or 0 since those are the direction values
		return -9999
	end

	local function makeTunnel()
		-- lets get a random direction - until it is a perpendicular to our lastDirection
		-- if the last direction = left or right,
		-- then our new direction has to be up or down,
		-- and vice versa
		repeat
			randomDirection = directions[math.random(1, #directions)]
		until not ((randomDirection[fi] == -getLastDirection(fi) and randomDirection[fi+1] == -getLastDirection(fi+1)) or (randomDirection[fi] == getLastDirection(fi) and randomDirection[fi+1] == getLastDirection(fi+1)))

		local randomLength = math.random(1, maxLength) --length the next tunnel will be (max of maxLength)
		local tunnelLength = 0; --current length of tunnel being created

		-- lets loop until our tunnel is long enough or until we hit an edge
		local isOutOfMap = false
		while (tunnelLength < randomLength) and (not isOutOfMap) do

			local boundary = fi + bw
			--loop will end if it is going out of the map
			isOutOfMap = (((currentRow <= boundary) and (randomDirection[fi] == -1)) or
			((currentColumn <= boundary) and (randomDirection[fi+1] == -1)) or
			((currentRow >= dimensions - boundary) and (randomDirection[fi] == 1)) or
			((currentColumn >= dimensions - boundary) and (randomDirection[fi+1] == 1)))

			if not isOutOfMap then
				map[currentRow][currentColumn] = fillValue --set the value of the index in map to fillValue (a tunnel, making it one longer)
				currentRow = currentRow + randomDirection[fi] --add the value from randomDirection to row and col (-1, 0, or 1) to update our location
				currentColumn = currentColumn + randomDirection[fi+1]
				tunnelLength = tunnelLength + 1 --the tunnel is now one longer, so lets increment that variable
			end
		end
		return tunnelLength
	end

	-- lets create some tunnels - while maxTunnels, dimensions, and maxLength  is greater than 0.
	while (maxTunnels > 0) and (dimensions > 0) and (maxLength > 0) do
		local tunnelLength = makeTunnel()
		if tunnelLength > 0 then -- update our variables unless our last loop broke before we made any part of a tunnel
			lastDirection = randomDirection --set lastDirection, so we can remember what way we went
			maxTunnels = maxTunnels - 1 -- we created a whole tunnel so lets decrement how many we have left to create
		end
	end

	return map
end

Map.createAdjacentRooms = adjacentRoomsAlgorithm

function Map.debug(dimensions, maxNumOfTunnels, maxTunnelLength, emptyValue, fillValue)
	local map = Map.createBasicLabryinth(dimensions, maxNumOfTunnels, maxTunnelLength, emptyValue, fillValue)
	printGrid(map, '', function(v)
		if v == 0 then
			return '_'
		end
		return v
	end)
end

return Map