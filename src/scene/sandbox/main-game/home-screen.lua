local Component = require 'modules.component'
local fileSystem = require 'modules.file-system'
local Color = require 'modules.color'
local Gui = require 'components.gui.gui'
local GuiTextInput = require 'components.gui.gui-text-input'
local GuiButton = require 'components.gui.gui-button'
local GuiText = require 'components.gui.gui-text'
local MenuList = require 'components.menu-list'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local config = require 'config.config'
local tick = require 'utils.tick'
local StarField = require 'components.star-field'
local Camera = require 'components.camera'

local MainGameHomeScene = {
  group = groups.gui,
  menuX = 300,
  menuY = 40
}

function MainGameHomeScene.init(self)
  Camera:setPosition(0, 0, 0)
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, Color.DARK_GRAY)
  msgBus.on(msgBus.KEY_PRESSED, function(ev)
    local isToggleDevMode = ev.hasModifier and ev.key == '.'
    if isToggleDevMode then
      local userSettingsState = require 'config.user-settings.state'
      userSettingsState.set(function(settings)
        settings.isDevelopment = not settings.isDevelopment
        return settings
      end)
    end
  end)

  self.starField = StarField.create({
    speed = {3, 15},
    size = {1, 2},
    emissionRate = 400,
    particleBaseColor = {Color.rgba255(244, 66, 155)},
    preWarm = 0,
  }):setParent(self)
  self.initialMousePosition = {
    x = love.mouse.getX(),
    y = love.mouse.getY()
  }

  local parent = self
  self.guiTextTitleLayer = GuiText.create({
    font = require 'components.font'.secondaryLarge.font
  }):setParent(self)
  self.guiTextLayer = GuiText.create({
    font = require 'components.font'.primary.font
  }):setParent(self)
end

function MainGameHomeScene.update(self)
  local mx, my = love.mouse.getX(), love.mouse.getY()
  local dx, dy = self.initialMousePosition.x - mx, self.initialMousePosition.y - my
  local adjustment = 0.005
  self.starField:setPosition(dx * adjustment, dy * adjustment)
end

local function renderTitle(self)
  self.guiTextTitleLayer:add(
    config.gameTitle,
    Color.SKY_BLUE,
    self.menuX,
    self.menuY - 20
  )
  local screenWidth, screenHeight = love.graphics.getDimensions()
  self.guiTextLayer:add(
    config.version,
    Color.WHITE,
    5,
    (screenHeight / config.scale) - 14
  )
end

function MainGameHomeScene.draw(self)
  renderTitle(self)
end

return Component.createFactory(MainGameHomeScene)