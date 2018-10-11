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
local Enum = require 'utils.enum'

local menuModes = Enum({
  'NORMAL',
  'DELETE_GAME'
})

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
  return GuiButton.create({
    text = 'New Game',
    textLayer = parent.guiTextLayer,
    x = parent.menuX,
    y = parent.menuY + 250,
    padding = 5,
    onClick = function(self)
      msgBus.send(
        msgBus.SCENE_STACK_PUSH,
        {
          scene = NewGameDialog
        }
      )
      parent:delete(true)
    end,
    onUpdate = function(self)
      self.hidden = parent.state.menuMode == menuModes.DELETE_GAME
    end
  }):setParent(parent)
end

local function DeleteGameButton(parent, anchorEntity)
  return GuiButton.create({
    textLayer = parent.guiTextLayer,
    x = x,
    y = y,
    padding = 5,
    onClick = function()
      -- toggle modes
      local mode = parent.state.menuMode == menuModes.NORMAL and
        menuModes.DELETE_GAME or
        menuModes.NORMAL
      parent.state.menuMode = mode
    end,
    onUpdate = function(self)
      self.text = parent.state.menuMode == 'DELETE_GAME' and '< Back' or 'Delete game'
      self.x, self.y = anchorEntity.x + anchorEntity.w + 5, anchorEntity.y
    end
  }):setParent(parent)
end

local function getMenuOptions(parent)
  return f.map(fileSystem.listSavedFiles('saved-states'), function(fileData)
    local meta = fileData.metadata
    local dateObject = os.date('*t', meta.lastSaved)
    local extract = require 'utils.object-utils.extract'
    local month, day, year = extract(dateObject, 'month', 'day', 'year')
    local saveDateHumanized = month .. '-' .. day .. '-' .. year
    return {
      name = {
        Color.WHITE,
        meta.displayName..'\n',

        Color.LIGHT_GRAY,
        'last saved: '..saveDateHumanized
      },
      value = function()
        if parent.state.menuMode == menuModes.DELETE_GAME then
          fileSystem.deleteFile('saved-states', fileData.id)
            :next(function()
              parent.state.needsUpdate = true
            end, function(err)
              print('delete error')
            end)
        -- load game
        else
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
        end
      end,
    }
  end)
end

function MainGameHomeScene.init(self)
  self.state = {
    menuMode = menuModes.NORMAL,
    needsUpdate = true,
  }

  msgBus.send(msgBus.SET_BACKGROUND_COLOR, Color.DARK_GRAY)

  local parent = self
  self.guiTextTitleLayer = GuiText.create({
    font = require 'components.font'.secondaryLarge.font
  }):setParent(self)
  self.guiTextLayer = GuiText.create({
    font = require 'components.font'.primary.font
  }):setParent(self)

  -- saved games list
  self.list = MenuList.create({
    x = self.menuX,
    y = self.menuY,
    width = 125,
    options = {},
    onSelect = function(name, value)
      value()
    end
  }):setParent(parent)

  local newGameBtn = NewGameButton(parent)
  DeleteGameButton(parent, newGameBtn)
end

function MainGameHomeScene.update(self)
  if self.state.needsUpdate then
    self.list.options = getMenuOptions(self)
  end
  self.state.needsUpdate = false
end

local function renderTitle(self)
  self.guiTextTitleLayer:add(
    config.gameTitle,
    Color.SKY_BLUE,
    self.menuX,
    self.menuY - 20
  )
end

function MainGameHomeScene.draw(self)
  renderTitle(self)

  if self.state.menuMode == menuModes.DELETE_GAME then
    self.guiTextLayer:addf(
      {
        Color.YELLOW,
        'click a game to delete it',
      },
      300,
      'left',
      self.menuX,
      self.menuY + 235
    )
  end
end

return Component.createFactory(MainGameHomeScene)