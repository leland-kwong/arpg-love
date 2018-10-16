local loadImage = require 'modules.load-image'
local lightBlurImg = loadImage('built/images/light-blur.png')
local imageHeight = lightBlurImg:getHeight()
local scaleAdjustment = imageHeight / 100
local Vec2 = require 'modules.brinevector'

local defaultLightColor = {1,1,1}
local defaultAmbientColor = {0.4,0.4,0.4,0.1}

local LightWorld = {}
LightWorld.__index = LightWorld

function LightWorld:new(width, height)
  local canvas = love.graphics.newCanvas(width, height)

  return setmetatable({
    canvas = canvas,
    preDrawCanvas = preDrawCanvas,
    position = Vec2(0, 0),
    ambientColor = defaultAmbientColor,
    lights = {}
  }, self)
end

function LightWorld:addLight(x, y, radius, color)
  table.insert(self.lights, {x, y, radius, color})
  return self
end

function LightWorld:setAmbientColor(color)
  self.ambientColor = color

  return self
end

function LightWorld:setPosition(x, y)
  self.position.x = x
  self.position.y = y

  return self
end

function drawLights(self)
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.push()
  love.graphics.origin()
  love.graphics.translate(self.position.x, self.position.y)
  love.graphics.setBlendMode('add', 'alphamultiply')
  love.graphics.setCanvas(self.canvas)

  for i=1, #self.lights do
    local light = self.lights[i]
    local x, y, radius, color = light[1], light[2], light[3], light[4]
    local lightSize = (radius * 2 * scaleAdjustment) / imageHeight
    local offset = (radius * 2 * scaleAdjustment) / 2

    love.graphics.setColor(color or defaultLightColor)
    love.graphics.draw(lightBlurImg, x - offset, y - offset, 0, lightSize, lightSize)
  end
  self.lights = {}

  love.graphics.setCanvas()
  love.graphics.setBlendMode(oBlendMode)
  love.graphics.pop()
end

function LightWorld:draw()
  drawLights(self)

  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setColor(1,1,1)
  love.graphics.setBlendMode('multiply', 'premultiplied')
  love.graphics.draw(self.canvas)

  -- reset canvas
  love.graphics.setBlendMode(oBlendMode)
  love.graphics.setCanvas(self.canvas)
  love.graphics.setBlendMode('alpha', 'alphamultiply')
  love.graphics.clear(self.ambientColor)
  love.graphics.setCanvas()

  return self
end

return LightWorld