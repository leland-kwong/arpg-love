local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local font = require 'components.font'
local MenuList = require 'components.menu-list'
local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local config = require 'config.config'
local objectUtils = require 'utils.object-utils'
local bitser = require 'modules.bitser'
local memoize = require 'utils.memoize'
local F = require 'utils.functional'

local function getMenuTabsPosition()
  return 15, 60
end

local drawOrder = function()
  return require 'modules.draw-orders'.MainMenu
end

local guiTextBodyLayer = GuiText.create({
  font = font.primary.font,
  drawOrder = drawOrder
})

local Sandbox = {
  id = 'mainMenu',
  group = groups.gui,
  drawOrder = function()
    return drawOrder() - 1
  end
}

local state = {
  menuOpened = false
}

local function setState(nextState)
  objectUtils.assign(state, nextState)
end

local function loadScene(path)
  if not path then
    print('no scene to load')
    return
  end
  local scene = require(path)
  msgBus.send(msgBus.SCENE_STACK_REPLACE, {
    scene = scene
  })
end

local function menuOptionSceneLoad(props)
  return {
    name = props.name,
    value = function()
      loadScene(props.path)
    end
  }
end

local menuOptionQuitGame = {
  name = 'Exit',
  value = function()
    love.event.quit()
  end,
  onSelectSoundEnabled = false
}

msgBus.on(msgBus.SETTINGS_MENU_TOGGLE, function()
  local activeMenu = Component.get('SettingsMenu')
  if activeMenu then
    activeMenu:delete(true)
  else
    local camera = require 'components.camera'
    -- create settings menu
    local SettingsMenu = require 'scene.settings-menu'
    local menuTabs = Component.get('MainMenuTabs')
    local x, y = menuTabs.x + menuTabs.width + 24,
      menuTabs.y
    local width, height = 240, love.graphics.getHeight() / camera.scale - y - 20
    local menu = SettingsMenu.create({
      x = x,
      y = y,
      width = width,
      height = height
    })
  end
end)

local menuOptionHomeScreen = {
  name = 'Title Screen',
  id = 'titleScreen',
  value = function()
    local HomeScreen = require 'scene.sandbox.main-game.home-screen'
    msgBus.send(msgBus.SCENE_STACK_REPLACE, {
      scene = HomeScreen
    })
    msgBus.send(msgBus.GAME_UNLOADED)
    msgBus.send(msgBus.TOGGLE_MAIN_MENU, false)
    msgBus.send(msgBus.TOGGLE_MAIN_MENU, true)
  end
}

local menuOptionSettingsMenu = {
  name = 'Settings',
  value = function()
    -- dont close it if it's already open
    if Component.get('SettingsMenu') then
      return
    end
    msgBus.send(msgBus.SETTINGS_MENU_TOGGLE)
  end
}

local menuOptionPlayGameMenu = {
  name = 'Play Game',
  value = function()
    -- dont close it if it's already open
    if Component.get('PlayGameMenu') then
      return
    end
    msgBus.send(msgBus.PLAY_GAME_MENU_TOGGLE)
  end
}

local menuOptionNewsPanel = {
  name = 'Patch notes',
  value = function()
    -- dont close it if it's already open
    if Component.get('newsDialog') then
      return
    end
    msgBus.send(msgBus.LATEST_NEWS_TOGGLE)
  end
}

msgBus.on(msgBus.LATEST_NEWS_TOGGLE, function()
  local ref = Component.get('newsDialog')
  if ref then
    ref:delete(true)
  else
    local camera = require 'components.camera'
    local LatestNews = require 'scene.latest-news'
    local menuTabs = Component.get('MainMenuTabs')
    local x, y = menuTabs.x + menuTabs.width + 24,
      menuTabs.y
    local width, height = 240, love.graphics.getHeight() / camera.scale - y - 20
    LatestNews.create({
      x = x,
      y = y,
      width = width,
      height = height
    })
    -- set selected tab
    Component.get('MainMenuTabs').value = menuOptionNewsPanel.value
  end
end)

msgBus.on(msgBus.PLAY_GAME_MENU_TOGGLE, function()
  local activeMenu = Component.get('PlayGameMenu')
  if activeMenu then
    activeMenu:delete(true)
  else
    -- set selected tab
    Component.get('MainMenuTabs').value = menuOptionPlayGameMenu.value

    -- create menu
    local PlayGameMenu = require 'scene.play-game-menu'
    local menuTabs = Component.get('MainMenuTabs')
    local menu = PlayGameMenu.create({
      x = menuTabs.x + menuTabs.width + 24,
      y = menuTabs.y,
    })
  end
end)

local sceneOptionsNormal = {
  menuOptionPlayGameMenu,
  menuOptionSettingsMenu,
  menuOptionHomeScreen,
  menuOptionNewsPanel
}

local sceneOptionsDebug = F.concat(sceneOptionsNormal, {
  menuOptionQuitGame
})

table.insert(sceneOptionsNormal, menuOptionQuitGame)

msgBus.on(msgBus.MENU_ITEM_ADD, function(menuOption)
  table.insert(sceneOptionsDebug, #sceneOptionsDebug - 1, menuOption)
end)

msgBus.on(msgBus.MENU_ITEM_REMOVE, function(menuOption)
  local options = sceneOptionsDebug
  for i=1, #options do
    local option= options[i]
    if option == menuOption then
      table.remove(options, i)
    end
  end
end)

require 'scene.skill-tree-editor'

function Sandbox.init(self)
  self.activeSceneMenu = nil

  local function DebugMenu(enabled)
    if enabled then
      local MenuManager = require 'modules.menu-manager'
      MenuManager.clearAll()
      local x, y = getMenuTabsPosition()
      self.activeSceneMenu = MenuList.create({
        id = 'MainMenuTabs',
        x = x,
        y = y,
        width = 120,
        options = {},
        onSelect = function(name, value)
          value()
        end,
        drawOrder = function()
          return drawOrder() + 2
        end
      })
    elseif self.activeSceneMenu then
      self.activeSceneMenu:delete(true)
      self.activeSceneMenu = nil
    end
    setState({ menuOpened = enabled })
  end

  menuOptionHomeScreen.value()

  self.listeners = {
    msgBus.on(msgBus.TOGGLE_MAIN_MENU, function(enabled)
      local MenuManager = require 'modules.menu-manager'
      if (enabled ~= nil) then
        MenuManager.clearAll()
        DebugMenu(enabled)
      else
        MenuManager.clearAll()
        DebugMenu(not state.menuOpened)
      end
      return state.menuOpened
    end, 1)
  }

  DebugMenu(true)
end

local getNextMenuOptions = memoize(function(isDev, isTitleScreen)
  local options = isDev and
    sceneOptionsDebug or
    sceneOptionsNormal
  return isTitleScreen and
    F.filter(options, function(o)
      return (o.id ~= 'titleScreen')
    end) or
    options
end)

function Sandbox.update(self)
  if state.menuOpened then
    Component.addToGroup(self.activeSceneMenu, 'guiDrawBox')
  else
    Component.removeFromGroup(self.activeSceneMenu, 'guiDrawBox')
  end
  if self.activeSceneMenu then
    local isTitleScreen = Component.get('HomeScreen') ~= nil
    self.activeSceneMenu.options = getNextMenuOptions(config.isDevelopment, isTitleScreen)
  end
end

function Sandbox.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(Sandbox)