local tileBitmasking = require 'utils.tilemap-bitmask'
local Grid = require 'utils.grid'

local function debugGrid(grid)
  local printGrid = require('utils.print-grid')
	printGrid(grid, '', function(v)
		if v == 0 then
			return '__'
		end
		return '_'..v
	end)
end

local grid = {
  {0, 0, 0, 0, 0, 0, 0, 0, 0,},
  {0, 1, 1, 1, 0, 0, 0, 0, 0,},
  {0, 1, 0, 1, 1, 1, 1, 0, 0,},
  {0, 1, 0, 1, 0, 1, 0, 0, 0,},
  {0, 1, 0, 1, 1, 1, 0, 0, 0,},
  {0, 1, 1, 1, 0, 1, 0, 0, 0,},
  {0, 0, 0, 0, 0, 0, 0, 0, 0,},
}

local newGrid = {}
tileBitmasking.iterateGrid(grid, function(v, x, y)
  Grid.set(newGrid, x, y, v)
end, 0)

-- debugGrid(newGrid)

local Component = require 'modules.component'
Component.create({
  id = 'tile-map-test',
  init = function(self)
    Component.addToGroup(self, 'gui')
  end,

  draw = function(self)
    love.graphics.clear(0.6,0.6,0.6)
    love.graphics.setColor(1,1,1)
    local gridSize = 16
    Grid.forEach(newGrid, function(v, x, y)
      local AnimationFactory = require 'components.animation-factory'
      local tile = AnimationFactory:newStaticSprite('map-'..v)
      tile:draw(x * gridSize, y * gridSize)
    end)
  end,

  drawOrder = function()
    return math.pow(10, 10)
  end
})