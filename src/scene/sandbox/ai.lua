local groups = require 'components.groups'
local pprint = require 'utils.pprint'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local pathfinder = require 'utils.search-path'
local iterateGrid = require 'utils.iterate-grid'

local AiTest = {}

local grid = {
  {1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1},
  {1,1,1,0,0,1,1},
  {1,1,1,1,0,1,1},
  {1,1,1,1,0,1,1},
  {1,1,1,1,1,1,1},
}

local OBSTACLE = 0

function AiTest.init()

end

function AiTest.draw()
  local tileSize = 16
  iterateGrid(grid, function(v, x, y)
    if v == OBSTACLE then
      love.graphics.setColor(1,1,1,1)
      love.graphics.rectangle(
        'fill',
        x * tileSize,
        y * tileSize,
        tileSize,
        tileSize
      )
    end
  end)
end

return groups.debug.createFactory(AiTest)
