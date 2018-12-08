local Component = require 'modules.component'
local loadImage = require 'modules.load-image'
local Color = require 'modules.color'
local config = require 'config.config'
local Console = require 'modules.console.console'

local StarField = {
  speed = {5, 50},
  sizes = {1, 2, 3},
  x = 0,
  y = 0,
  width = 4096,
  height = 3000,
  direction = 0,
  emissionRate = 1000,
  updateRate = 1, -- [INT] Updates the system every {x} frames. Larger values means less frequent updates
  particleLifeTime = {3, 10},
  drawColor = {1,1,1,1},
  particleBaseColor = Color.PURPLE,
  frameCount = 0,
  preWarm = 120, -- number of frames to pre warm
}

function StarField.init(self)
  Component.addToGroup(self, 'firstLayer')
  Component.addToGroup(self, 'gameWorld')

  local color = self.particleBaseColor
  self.particleColors = {
    {color[1], color[2], color[3], 1},
    {1, 1, 1, 1},
    {Color.rgba255(211, 91, 255)}
  }


  self.canvas = love.graphics.newCanvas(self.width, self.height)
  love.graphics.push()
  love.graphics.origin()
  love.graphics.scale(1)
  love.graphics.setCanvas(self.canvas)
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.setColor(self.drawColor)

  local AnimationFactory = require 'components.animation-factory'
  local animation = AnimationFactory:newStaticSprite('pixel-white-1x1')
  for i=1, 5000 do
    local x, y = math.random(0, 4096), math.random(0, 3000)
    local size = math.random(1, 2)
    local colorIndex = math.random(1, #self.particleColors)
    love.graphics.setColor(
      Color.multiplyAlpha(
        self.particleColors[colorIndex],
        math.random(50, 100) / 100
      )
    )
    animation:draw(x, y, 0, size, size)
  end

  love.graphics.setBlendMode(oBlendMode)
  love.graphics.setCanvas()
  love.graphics.pop()
end

function StarField.draw(self)
  local camera = require 'components.camera'
  local x, y = camera:getPosition()
  local ox, oy = x * 0.04, y * 0.04
  love.graphics.push()
  love.graphics.translate(-400 - ox, -200 - oy)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(self.canvas)
  love.graphics.pop()
end

function StarField.drawOrder()
  return 1
end

return Component.createFactory(StarField)