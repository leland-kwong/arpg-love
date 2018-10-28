local Component = require 'modules.component'
local loadImage = require 'modules.load-image'
local lightBlurImg = loadImage('built/images/light-blur.png')
local imageHeight = lightBlurImg:getHeight()
local scaleAdjustment = imageHeight / 100
local config = require 'config.config'

local defaultLightColor = {1,1,1}

local LightWorld = {
  ambientColor = {1,1,1,1}
}

function LightWorld.init(self)
  local width, height = self.width, self.height
  self.canvas = love.graphics.newCanvas(width * 2, height)
  self.lights = {}
end

function LightWorld.addLight(self, x, y, radius, color)
  table.insert(self.lights, {x, y, radius, color or defaultLightColor})
  return self
end

function LightWorld.setAmbientColor(self, color)
  self.ambientColor = color

  return self
end

function drawLights(self)
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.push()
  love.graphics.origin()
  love.graphics.translate(self.x, self.y)
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear(self.ambientColor)
  love.graphics.setBlendMode('add', 'alphamultiply')

  for i=1, #self.lights do
    local light = self.lights[i]
    local x, y, radius, color = light[1], light[2], light[3], light[4]
    local diameter = radius * 2
    local lightSize = (diameter * scaleAdjustment) / imageHeight
    local offset = (diameter * scaleAdjustment) / config.scale

    love.graphics.setColor(color or defaultLightColor)
    love.graphics.draw(lightBlurImg, x - offset, y - offset, 0, lightSize, lightSize)
  end
  self.lights = {}

  love.graphics.setCanvas()
  love.graphics.setBlendMode(oBlendMode)
  love.graphics.pop()
end

function LightWorld.draw(self)
  love.graphics.push()
  love.graphics.origin()
  love.graphics.scale(config.scale)

  drawLights(self)

  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setColor(1,1,1)
  love.graphics.setBlendMode('multiply', 'premultiplied')
  love.graphics.draw(self.canvas)

  love.graphics.setBlendMode(oBlendMode)
  love.graphics.pop()
end

return Component.createFactory(LightWorld)