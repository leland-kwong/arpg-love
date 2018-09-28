local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'

local LightTest = {
  group = groups.all
}

local function addLight(self, x, y, color, radius)
  local Light = require("shadows.Light")
  local newLight = Light:new(self.newLightWorld, radius)
  newLight:SetColor(unpack(color))
  -- Set the light's position
  newLight:SetPosition(x, y)
  return newLight
end

function LightTest.init(self)
  local LightWorld = require("shadows.LightWorld")
  local Light = require("shadows.Light")
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {1,1,1})
  self.newLightWorld = LightWorld:new()
  self.newLightWorld:SetColor(0.2*255,0.2*255,0.2*255)
  -- Light:new(self.newLightWorld, 800)
  --   :SetPosition(200, 400)
  --   :SetColor(255, 255, 255, 255)

  self.playerLight = Light:new(self.newLightWorld, 800)
    :SetPosition(1200, 400)
    :SetColor(206, 66, 244, 255)

  local Player = require 'components.player'
  self.playerRef = Player.create({
    x = 0,
    y = 0
  })
end

function LightTest.update(self)
  self.newLightWorld:Update()
  local camera = require 'components.camera'
  local x, y = camera:getPosition()
  self.newLightWorld:SetPosition(x * 2, y * 2)

  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  self.playerLight:SetPosition(
    self.playerRef.x * 2 + w/2,
    self.playerRef.y * 2 + h/2
  )
end

function LightTest.draw(self)
  love.graphics.push()
  self.newLightWorld:Draw()
  love.graphics.pop()
end

function LightTest.drawOrder()
  return math.pow(10, 10)
end

local Factory = Component.createFactory(LightTest)

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'lighting test',
  value = function()
    msgBusMainMenu.send(msgBusMainMenu.SCENE_STACK_PUSH, {
      scene = Factory
    })
  end
})