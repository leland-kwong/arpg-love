local tileBitmasking = require 'utils.tilemap-bitmask'
local Grid = require 'utils.grid'

local json = require 'lua_modules.json'
local Animation = require 'modules.animation'

local lastModifiedCache = {}
local function hasFileChanged(path)
  local lastModified = lastModifiedCache[path]
  local info = love.filesystem.getInfo(path)
  local newModTime = info and info.modtime
  lastModifiedCache[path] = newModTime
  return newModTime and (lastModified ~= newModTime)
end

local spriteAtlas = love.graphics.newImage('built/sprite.png')
local spriteData = json.decode(
  love.filesystem.read('built/sprite.json')
)

local AnimationFactory = Animation(spriteData, spriteAtlas, 2)

local grid = {
  {0, 0, 0, 0, 0, 0, 0, 0, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 0, 0, 0, 0, 1, 1, 0,},
  {0, 1, 0, 1, 1, 1, 1, 1, 0,},
  {0, 1, 0, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 0, 1, 0, 1, 0,},
  {0, 1, 0, 0, 0, 0, 0, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 0, 0, 0, 0, 0, 0, 0, 0,},
}

local newGrid = {}
tileBitmasking.iterateGrid(grid, function(v, x, y)
  Grid.set(newGrid, x, y, v)
end, 0)

local Component = require 'modules.component'
Component.create({
  id = 'tile-map-test',
  init = function(self)
    Component.addToGroup(self, 'gui')
  end,

  update = function(self)
  end,

  draw = function(self)
    love.graphics.scale(2)
    love.graphics.clear(0,0,0)
    love.graphics.setColor(1,1,1)

    local gridSize = 16

    Grid.forEach(grid, function(v, x, y)
      local tile = AnimationFactory:newStaticSprite('floor-1')
      tile:draw(
        (x - 1) * gridSize,
        (y - 1) * gridSize
      )
    end)

    Grid.forEach(newGrid, function(v, x, y)
      local tile = AnimationFactory:newStaticSprite('map-'..v)
      tile:draw((x - 1) * gridSize, (y - 1) * gridSize)
    end)
  end,

  drawOrder = function()
    return math.pow(10, 10)
  end
})