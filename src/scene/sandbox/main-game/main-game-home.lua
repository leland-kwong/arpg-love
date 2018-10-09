local Component = require 'modules.component'
local fileSystem = require 'modules.file-system'
local Color = require 'modules.color'
local f = require 'utils.functional'
local Gui = require 'components.gui.gui'
local GuiTextInput = require 'components.gui.gui-text-input'
local GuiText = require 'components.gui.gui-text'
local MenuList = require 'components.menu-list'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local HomeBase = require 'scene.home-base'
local config = require 'config.config'
local tick = require 'utils.tick'

local MainGameHomeScene = {
  group = groups.gui,
  menuX = 300,
  menuY = 40
}

local NewGameDialogBlueprint = {
  group = groups.gui,
  x = 300,
  y = 100
}

function NewGameDialogBlueprint.init(self)
  local textLayer = GuiText.create({
    font = require 'components.font'.secondary.font
  })

  self.textInput = GuiTextInput.create({
    x = self.x,
    y = self.y,
    w = 150,
    h = 20,
    textLayer = textLayer,
    placeholderText = 'your name',
    onKeyPress = function(self, ev)
      if ev.key == 'return' then
        consoleLog(ev.key, os.clock())
      end

    -- msgBus.send(
    --   msgBus.SCENE_STACK_REPLACE,
    --   {
    --     scene = HomeBase,
    --     props = {
    --       isNewGame = true
    --     }
    --   }
    -- )
    end
  }):setParent(self)
  Gui.setFocus(self.textInput)
end

local NewGameDialog = Component.createFactory(NewGameDialogBlueprint)

local function NewGameButton(parent)
  local w, h = GuiText.getTextSize('New Game', parent.guiTextLayer.font)
  local padding = 10
  local actualW, actualH = w + padding, h + padding
  return Gui.create({
    x = parent.menuX,
    y = parent.menuY + 150,
    w = actualW,
    h = actualH,
    type = Gui.types.BUTTON,
    onClick = function(self)
      local CreateStore = require 'components.state.state'
      msgBus.send(msgBus.GAME_STATE_SET, CreateStore())
      msgBus.send(
        msgBus.SCENE_STACK_PUSH,
        {
          scene = NewGameDialog
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
      parent.guiTextLayer:add('New game', Color.WHITE, self.x + padding/2, self.y + padding/2)
    end
  }):setParent(parent)
end

function MainGameHomeScene.init(self)
  msgBus.send(msgBus.NEW_GAME)
  local parent = self
  self.guiTextTitleLayer = GuiText.create({
    font = require 'components.font'.secondaryLarge.font
  }):setParent(self)
  self.guiTextLayer = GuiText.create({
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
          local CreateStore = require 'components.state.state'
          local store = CreateStore()
          local loadedState = fileSystem.loadSaveFile(fileName)
          -- FIXME: we currently update the store after creating it since some parts of the game
          -- check if there was a state change to trigger events at load time. If we create the store
          -- with the loaded state, then the previous state and new state will be the same.
          store:replaceState(loadedState)
          msgBus.send(
            msgBus.GAME_STATE_SET,
            store
          )
          msgBus.send(
            msgBus.SCENE_STACK_REPLACE,
            {
              scene = HomeBase
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