local Component = require 'modules.component'
local fileSystem = require 'modules.file-system'
local Color = require 'modules.color'
local f = require 'utils.functional'
local GuiText = require 'components.gui.gui-text'
local MenuList = require 'components.menu-list'
local groups = require 'components.groups'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local SceneMain = require 'scene.scene-main'
local config = require 'config'
local tick = require 'utils.tick'

local MainGameHomeScene = {
  group = groups.gui,
  menuX = 300,
  menuY = 40
}

function MainGameHomeScene.init(self)
  local parent = self
  self.guiTextTitleLayer = GuiText.create({
    font = require 'components.font'.secondaryLarge.font
  }):setParent(self)

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