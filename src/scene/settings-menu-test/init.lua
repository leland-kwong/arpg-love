local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'

local SettingsMenuTest = {}

function SettingsMenuTest.init()
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {0.4,0.4,0.4})
  local Position = require 'utils.position'
  local SettingsMenu = require 'components.settings-menu'
  local vWidth, vHeight = love.graphics.getDimensions()
  local width, height = 240, 400
  local x = Position.boxCenterOffset(width, height, vWidth/2, vHeight/2)
  SettingsMenu.create({
    x = x,
    y = 60,
    width = width,
    height = height
  })
end

local Scene = Component.createFactory(SettingsMenuTest)

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'settings menu test',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_REPLACE, {
      scene = Scene
    })
  end
})