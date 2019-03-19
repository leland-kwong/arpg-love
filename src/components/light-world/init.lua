local Component = require 'modules.component'
local loadImage = require 'modules.load-image'
local lightBlurImg = loadImage('built/images/light-blur.png')
local imageHeight = lightBlurImg:getHeight()
local scaleAdjustment = imageHeight / 100
local config = require 'config.config'
local Color = require 'modules.color'

local defaultLightColor = {1,1,1}

local LightWorld = {
  ambientColor = {1,1,1,1}
}

function LightWorld.init(self)
  self.canvas = love.graphics.newCanvas(4096, 4096)
  self.lights = {}
end

function LightWorld.addLight(self, x, y, radius, color, opacity)
  table.insert(self.lights, {x, y, radius, (color or defaultLightColor), (opacity or 1)})
  return self
end

function LightWorld.setAmbientColor(self, color)
  self.ambientColor = color

  return self
end

function drawLights(self)
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear(self.ambientColor)
  love.graphics.setBlendMode('add', 'alphamultiply')

  for i=1, #self.lights do
    local light = self.lights[i]
    local x, y, radius, color, opacity = light[1], light[2], light[3], light[4], light[5]
    local diameter = radius * 2

    love.graphics.setColor(Color.multiplyAlpha(color or defaultLightColor, opacity))
    local scale = diameter / 100
    love.graphics.draw(lightBlurImg, x, y, 0, scale, scale, 200, 200)
  end
  self.lights = {}

  love.graphics.setCanvas()
  love.graphics.setBlendMode(oBlendMode)
end

function LightWorld.draw(self)
  drawLights(self)

  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setColor(1,1,1)
  love.graphics.setBlendMode('multiply', 'premultiplied')

  love.graphics.push()
  love.graphics.origin()
  love.graphics.draw(self.canvas)
  love.graphics.pop()

  love.graphics.setBlendMode(oBlendMode)
end

return Component.createFactory(LightWorld)