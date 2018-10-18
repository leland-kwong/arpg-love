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

local MainGameHomeScene = {
  group = groups.gui,
  menuX = 300,
  menuY = 40
}

function MainGameHomeScene.init(self)
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

  local parent = self
  self.guiTextTitleLayer = GuiText.create({
    font = require 'components.font'.secondaryLarge.font
  }):setParent(self)
  self.guiTextLayer = GuiText.create({
    font = require 'components.font'.primary.font
  }):setParent(self)
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