local Component = require 'modules.component'
local fileSystem = require 'modules.file-system'
local Color = require 'modules.color'
local f = require 'utils.functional'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local MenuList = require 'components.menu-list'
local groups = require 'components.groups'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local SceneMain = require 'scene.scene-main'
local config = require 'config.config'
local tick = require 'utils.tick'

local MainGameHomeScene = {
  group = groups.gui,
  menuX = 300,
  menuY = 40
}

local function NewGameButton(parent)
  local w, h = GuiText.getTextSize('New Game', parent.guiTextButtonLayer.font)
  local padding = 10
  local actualW, actualH = w + padding, h + padding
  return Gui.create({
    x = parent.menuX,
    y = parent.menuY + 150,
    w = actualW,
    h = actualH,
    type = Gui.types.BUTTON,
    onClick = function(self)
      msgBusMainMenu.send(
        msgBusMainMenu.SCENE_SWITCH,
        {
          scene = SceneMain
        }
      )
      parent:delete(true)
    end,
    draw = function(self)
      love.graphics.setColor(Color.PRIMARY)
      love.graphics.rectangle(
        'fill',
        self.x,
        self.y,
        self.w,
        self.h
      )
      parent.guiTextButtonLayer:add('New game', Color.WHITE, self.x + padding/2, self.y + padding/2)
    end
  }):setParent(parent)
end

function MainGameHomeScene.init(self)
  local parent = self
  self.guiTextTitleLayer = GuiText.create({
    font = require 'components.font'.secondaryLarge.font
  }):setParent(self)
  self.guiTextButtonLayer = GuiText.create({
    font = require 'components.font'.secondary.font
  }):setParent(self)

  -- saved games list
  MenuList.create({
    x = self.menuX,
    y = self.menuY,
    width = 125,
    options = f.map(fileSystem.listSavedFiles(), function(fileName)
      return {
        name = fileName,
        value = function()
          msgBusMainMenu.send(
            msgBusMainMenu.SCENE_SWITCH,
            {
              scene = SceneMain,
              props = {
                initialGameState = fileSystem.loadSaveFile(fileName)
              }
            }
          )
          parent:delete(true)
        end,
      }
    end),
    onSelect = function(name, value)
      value()
    end
  }):setParent(parent)

  NewGameButton(parent)
end

function MainGameHomeScene.draw(self)
  self.guiTextTitleLayer:add(
    config.gameTitle,
    Color.SKY_BLUE,
    self.menuX,
    self.menuY - 20
  )
end

return Component.createFactory(MainGameHomeScene)