local Component = require 'modules.component'
local fileSystem = require 'modules.file-system'
local Color = require 'modules.color'
local f = require 'utils.functional'
local Gui = require 'components.gui.gui'
local GuiTextInput = require 'components.gui.gui-text-input'
local GuiButton = require 'components.gui.gui-button'
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
  local state = {
    isValid = false,
    characterName = ''
  }

  local textLayer = GuiText.create({
    font = require 'components.font'.secondary.font
  })
  Component.addToGroup(textLayer:getId(), 'gameWorld', textLayer)

  local function startNewGame()
    if (not state.isValid) then
      return
    end

    msgBus.send(msgBus.NEW_GAME, {
      scene = HomeBase,
      props = {
        isNewGame = true,
        characterName = state.characterName
      }
    })
  end

  local textInput = GuiTextInput.create({
    x = self.x,
    y = self.y,
    w = 250,
    padding = 8,
    textLayer = textLayer,
    placeholderText = "what is your name?",
    onUpdate = function(self)
      state.characterName = self.text
      state.isValid = #self.text > 0
    end,
    onKeyPress = function(self, ev)
      local isSubmitEvent = ev.key == 'return'
      if isSubmitEvent then
        -- create new game
        startNewGame()
      end
    end
  }):setParent(self)

  GuiButton.create({
    padding = 8,
    textLayer = textLayer,
    text = 'start game',
    onClick = function()
      startNewGame()
    end,
    onUpdate = function(self)
      self:setDrawDisabled(not state.isValid)
      self.x = textInput.x + textInput.w - self.w
      self.y = textInput.y + textInput.h + 1
    end
  }):setParent(self)

  Gui.setFocus(textInput)
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
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, Color.DARK_GRAY)

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
    options = f.map(fileSystem.listSavedFiles('saved-states'), function(fileData)
      local meta = fileData.metadata
      return {
        name = {
          Color.WHITE,
          meta.displayName..'\n',

          Color.LIGHT_GRAY,
          meta.lastSaved
        },
        value = function()
          local CreateStore = require 'components.state.state'
          local loadedState = fileSystem.loadSaveFile('saved-states', fileData.id)
          msgBus.send(
            msgBus.NEW_GAME,
            {
              scene = HomeBase,
              props = loadedState
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