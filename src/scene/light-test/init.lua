local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBus = require 'components.msg-bus'
local LightWorld = require 'components.light-world'
local camera = require 'components.camera'

local LightTest = {
  group = groups.all
}

function LightTest.init(self)
  local width, height = love.graphics.getDimensions()
  self.lw = LightWorld:create({
    width = width,
    height = height
  })
    :setAmbientColor({0.4,0.4,0.4,0.1})
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {1,1,1})
  local Player = require 'components.player'
  self.playerRef = Player.create({
    autoSave = false,
    x = 0,
    y = 0
  })
end

function LightTest.update(self)
  local cameraTranslateX, cameraTranslateY = camera:getPosition()
  local tx, ty = self.playerRef:getPosition()
  self.lw:setPosition(-cameraTranslateX, -cameraTranslateY)

  local cWidth, cHeight = camera:getSize()
  self.lw:addLight(
    tx + cWidth/2, ty + cHeight/2,
    50,
    {0,1,0,0.5}
  )

  self.lw:addLight(
    600,
    0,
    50,
    {1,0,0}
  )

  self.lw:addLight(
    800,
    400,
    50,
    {1,0,0}
  )
end

function LightTest.draw(self)
  love.graphics.push()
  love.graphics.origin()
  love.graphics.scale(2)
  self.lw:draw()
  love.graphics.pop()
end

function LightTest.drawOrder()
  return math.pow(10, 10)
end

local Factory = Component.createFactory(LightTest)

msgBus.send(msgBus.MENU_ITEM_ADD, {
  name = 'lighting test',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Factory
    })
  end
})