-- load up user settings on game start
local userSettingsState = require 'config.user-settings.state'
userSettingsState.load()

local Component = require 'modules.component'
local drawOrders = require 'modules.draw-orders'
local LightWorld = require('components.light-world')
local camera = require 'components.camera'
local msgBus = require 'components.msg-bus'
require 'modules.auto-visibility'
require 'components.status-icons'
require 'main.onload.news-dialog'

local width, height = love.graphics.getDimensions()

local newLightWorld = LightWorld.create({
  id = 'lightWorld',
  group = Component.groups.all,
  width = width,
  height = height,
  drawOrder = function()
    return drawOrders.LightWorldDraw
  end
})

msgBus.on(msgBus.UPDATE, function()
  local cameraTranslateX, cameraTranslateY = camera:getPosition()
  local cWidth, cHeight = camera:getSize()
  newLightWorld:setPosition(-cameraTranslateX + cWidth/2, -cameraTranslateY + cHeight/2)
end)