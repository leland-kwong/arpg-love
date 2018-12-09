local tileBitmasking = require 'utils.tilemap-bitmask'
local Grid = require 'utils.grid'
local msgBus = require 'components.msg-bus'

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
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0,},
  {0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0,},
  {0, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0,},
  {0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0,},
  {0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
}
state = state or {
  scale = 2
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
    self.listeners = {
      msgBus.on(msgBus.MOUSE_WHEEL_MOVED, function(ev)
        local Math = require 'utils.math'
        local dy = ev[2]
        state.scale = Math.clamp(state.scale + dy, 1, 10)
      end)
    }
  end,

  draw = function(self)
    love.graphics.origin()
    love.graphics.scale(state.scale)
    love.graphics.clear(0,0,0)

    local gridSize = 16

    love.graphics.setColor(1,1,1)
    Grid.forEach(grid, function(v, x, y)
      local tile = AnimationFactory:newStaticSprite('floor-1')
      tile:draw(
        (x - 1) * gridSize,
        (y - 1) * gridSize
      )
    end)

    Grid.forEach(newGrid, function(v, x, y)
      local actualX, actualY = (x - 1) * gridSize, (y) * gridSize
      local tileBase = AnimationFactory:newStaticSprite('map-base-'..v)
      local ox, oy = tileBase:getSourceOffset()
      love.graphics.setColor(0,0,0,0.25)
      tileBase:draw(actualX, actualY + 7, 0, 1, 1, ox, oy)
      love.graphics.setColor(1,1,1)
      tileBase:draw(actualX, actualY, 0, 1, 1, ox, oy)
    end)

    Grid.forEach(newGrid, function(v, x, y)
      local actualX, actualY = (x - 1) * gridSize, (y) * gridSize
      love.graphics.setColor(1,1,1)
      local tileCap = AnimationFactory:newStaticSprite('map-'..v)
      local ox, oy = tileCap:getSourceOffset()
      tileCap:draw(actualX, actualY - 16, 0, 1, 1, ox, oy)
    end)
  end,

  drawOrder = function()
    return math.pow(10, 10)
  end,

  final = function(self)
    msgBus.off(self.listeners)
  end
})