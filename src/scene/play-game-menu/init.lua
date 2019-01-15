local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local GuiButton = require 'components.gui.gui-button'
local GuiTextInput = require 'components.gui.gui-text-input'
local MenuList = require 'components.menu-list'
local msgBus = require 'components.msg-bus'
local msgBus = require 'components.msg-bus'
local Enum = require 'utils.enum'
local Db = require 'modules.database'
local HomeBase = require 'scene.home-base'
local Color = require 'modules.color'
local f = require 'utils.functional'
local MenuManager = require 'modules.menu-manager'

local PlayGameMenu = {
  id = 'PlayGameMenu',
  x = 300,
  y = 40,
  -- padding = 10
}

local menuModes = Enum({
  'NORMAL',
  'DELETE_GAME'
})

local NewGameDialogBlueprint = {
  group = Component.groups.gui,
  x = 300,
  y = 100
}

function NewGameDialogBlueprint.init(self)
  local parent = self
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
    self:delete(true)
  end

  local camera = require 'components.camera'
  local screenWidth, screenHeight = camera:getSize()
  local width = 250
  local textInput = GuiTextInput.create({
    x = math.floor(screenWidth/2 - width/2),
    y = self.y,
    w = width,
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
        parent.onNewGameEnter()
      end
    end
  }):setParent(self)

  GuiButton.create({
    padding = 8,
    textLayer = textLayer,
    text = 'START GAME',
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
    text = 'NEW GAME',
    textLayer = parent.guiTextLayer,
    x = parent.innerX,
    y = parent.innerY + 250,
    padding = 5,
    onClick = function(self)
      local HomeScreen = require('scene.sandbox.main-game.home-screen')
      msgBus.send(msgBus.SCENE_STACK_REPLACE, {
        scene = HomeScreen
      })
      NewGameDialog.create({
        onNewGameEnter = function()
          parent:delete(true)
        end
      })
      msgBus.send(msgBus.TOGGLE_MAIN_MENU, false)
    end,
    onUpdate = function(self)
      self.hidden = parent.state.menuMode == menuModes.DELETE_GAME
    end
  }):setParent(parent)
end

local function DeleteGameButton(parent, anchorEntity)
  return GuiButton.create({
    textLayer = parent.guiTextLayer,
    padding = 5,
    onClick = function()
      -- toggle modes
      local mode = parent.state.menuMode == menuModes.NORMAL and
        menuModes.DELETE_GAME or
        menuModes.NORMAL
      parent.state.menuMode = mode
    end,
    onUpdate = function(self)
      self.text = parent.state.menuMode == 'DELETE_GAME' and '< BACK' or 'DELETE GAME'
      self.x, self.y = anchorEntity.x + anchorEntity.w + 5, anchorEntity.y
    end
  }):setParent(parent)
end

local function getMenuOptions(parent)
  local db = Db.load('saved-states')
  local hasChanges = db.changeCount ~= parent.previousChangeCount or
    parent.state.previousMenuMode ~= parent.state.menuMode
  if (hasChanges) then
    parent.previousChangeCount = db.changeCount
    parent.state.previousMenuMode = parent.state.menuMode

    local function filterGameStats(key)
      -- game stat files do not have a '/' in them
      return string.find(key, '%/') == nil
    end
    local files = f.keys(db:keyIterator(filterGameStats))
    parent.previousFilesForDisplay = f.map(files, function(file)
      local data = db:get(file)
      local meta = data.metadata
      local dateObject = os.date('*t', meta.lastSaved)
      local extract = require 'utils.object-utils.extract'
      local month, day, year = extract(dateObject, 'month', 'day', 'year')
      local saveDateHumanized = month .. '-' .. day .. '-' .. year
      local name = {
        Color.WHITE,
        meta.displayName..'\n',

        Color.LIGHT_GRAY,
        'last played: '..saveDateHumanized
      }

      if menuModes.DELETE_GAME == parent.state.menuMode then
        table.insert(name, #name + 1, Color.RED)
        table.insert(name, #name + 1, '\nDELETE')
      end

      return {
        name = name,
        value = function()
          if parent.state.menuMode == menuModes.DELETE_GAME then
            local PassiveTree = require 'components.player.passive-tree'
            PassiveTree.deleteState(file)
              :next(nil, function(err)
                print(err)
              end)
            Db.load('saved-states'):delete(file)
              :next(nil, function(err)
                print(err)
              end)
          -- load game
          else
            local CreateStore = require 'components.state.state'
            local loadedState = Db.load('saved-states'):get(file).data
            msgBus.send(
              msgBus.NEW_GAME,
              {
                scene = HomeBase,
                props = loadedState
              }
            )
            msgBus.send(msgBus.TOGGLE_MAIN_MENU, false)
            parent:delete(true)
          end
        end,
      }
    end)
  end
  return parent.previousFilesForDisplay or {}
end

function PlayGameMenu.init(self)
  self.innerX = self.x
  self.innerY = self.y

  Component.addToGroup(self, 'gui')
  MenuManager.clearAll()
  MenuManager.push(self)

  self.state = {
    menuMode = menuModes.NORMAL,
    needsUpdate = true,
  }

  self.guiTextLayer = GuiText.create({
    font = require 'components.font'.primary.font
  }):setParent(self)

  -- saved games list
  self.list = MenuList.create({
    x = self.innerX,
    y = self.innerY,
    width = 125,
    options = getMenuOptions(self),
    onSelect = function(name, value)
      value()
    end,
    drawOrder = function()
      return 2
    end,
  }):setParent(self)

  self.newGameBtn = NewGameButton(self)
  DeleteGameButton(self, self.newGameBtn)
end

function PlayGameMenu.update(self)
  self.list.options = getMenuOptions(self)
  self.width = self.list.width
  self.height = self.newGameBtn.y - self.innerY + self.newGameBtn.h
end

function PlayGameMenu.draw(self)
  local drawBox = require 'components.gui.utils.draw-box'
  drawBox(self)

  if self.state.menuMode == menuModes.DELETE_GAME then
    self.guiTextLayer:addf(
      {
        Color.YELLOW,
        'click a game to delete it',
      },
      300,
      'left',
      self.x,
      self.y + 235
    )
  end
end

function PlayGameMenu.draworder()
  return 1
end

return Component.createFactory(PlayGameMenu)