local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local font = require 'components.font'
local MenuList = require 'components.menu-list'
local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local config = require 'config.config'
local objectUtils = require 'utils.object-utils'
local bitser = require 'modules.bitser'

local function getMenuTabsPosition()
  return 200, 60
end

local drawOrder = function()
  return 1000
end

local guiTextBodyLayer = GuiText.create({
  font = font.primary.font,
  drawOrder = drawOrder
})

local Sandbox = {
  group = groups.gui,
  drawOrder = function()
    return drawOrder() - 1
  end
}

local scenes = {
  mainGameHome = {
    name = 'main game home screen',
    path = 'scene.sandbox.main-game.home-screen'
  },
  playGameMenu = {
    name = 'play game',
    path = 'scene.play-game-menu'
  },
  settingsMenu = {
    name = 'settings',
    path = 'scene.settings-menu'
  },
  aiTest = {
    name = 'ai',
    path = 'scene.sandbox.ai.test-scene'
  },
  guiTest = {
    name = 'gui',
    path = 'scene.sandbox.gui.test-scene'
  },
  particleTest = {
    name = 'particle fx',
    path = 'scene.sandbox.particle-fx.particle-test'
  },
  groundFlameTest = {
    name = 'ground flame fx',
    path = 'scene.sandbox.particle-fx.ground-flame-test'
  }
}

local state = {
  activeScenePath = scenes.mainGameHome.path,
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
  name = 'exit game',
  value = function()
    love.event.quit()
  end
}

msgBus.SETTINGS_MENU_TOGGLE = 'SETTINGS_MENU_TOGGLE'
msgBus.on(msgBus.SETTINGS_MENU_TOGGLE, function()
  local activeMenu = Component.get('SettingsMenu')
  if activeMenu then
    activeMenu:delete(true)
  else
    -- create settings menu
    local SettingsMenu = require 'scene.settings-menu'
    local width, height = 240, 400
    local menuTabs = Component.get('MainMenuTabs')
    local menu = SettingsMenu.create({
      x = menuTabs.x + menuTabs.width + 2,
      y = menuTabs.y,
      width = width,
      height = height
    })
  end
end)

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

msgBus.PLAY_GAME_MENU_TOGGLE = 'PLAY_GAME_MENU_TOGGLE'
msgBus.on(msgBus.PLAY_GAME_MENU_TOGGLE, function()
  local activeMenu = Component.get('PlayGameMenu')
  if activeMenu then
    activeMenu:delete(true)
  else
    -- create settings menu
    local PlayGameMenu = require 'scene.play-game-menu'
    local menuTabs = Component.get('MainMenuTabs')
    local menu = PlayGameMenu.create({
      x = menuTabs.x + menuTabs.width + 2,
      y = menuTabs.y,
    })
  end
end)

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

local sceneOptionsNormal = {
  menuOptionPlayGameMenu,
  menuOptionSettingsMenu,
  menuOptionSceneLoad(scenes.mainGameHome),
  menuOptionQuitGame
}

local sceneOptionsDebug = {
  menuOptionPlayGameMenu,
  menuOptionSettingsMenu,
  {
    name = 'main game sandbox',
    value = function()
      local msgBus = require 'components.msg-bus'
      local Scene = require 'scene.sandbox.main-game.main-game-test'
      msgBus.send(msgBus.NEW_GAME, {
        scene = Scene,
        props = {
          __stateId = 'test-state',
          characterName = 'test character'
        }
      })
    end
  },
  menuOptionSceneLoad(scenes.mainGameHome),
  menuOptionSceneLoad(scenes.aiTest),
  menuOptionSceneLoad(scenes.guiTest),
  menuOptionSceneLoad(scenes.particleTest),
  menuOptionSceneLoad(scenes.groundFlameTest),
  menuOptionQuitGame,
}

msgBusMainMenu.on(msgBusMainMenu.MENU_ITEM_ADD, function(menuOption)
  table.insert(sceneOptionsDebug, #sceneOptionsDebug - 1, menuOption)
end)

msgBusMainMenu.on(msgBusMainMenu.MENU_ITEM_REMOVE, function(menuOption)
  local options = sceneOptionsDebug
  for i=1, #options do
    local option= options[i]
    if option == menuOption then
      table.remove(options, i)
    end
  end
end)

require 'scene.light-test'
require 'scene.font-test'
require 'scene.tooltip-test'

local function closeMenuButton(props)
  local textContent = {
    Color.WHITE,
    'CLOSE'
  }
  local x, y = getMenuTabsPosition()
  return Gui.create({
    x = x + 400,
    y = y,
    type = Gui.types.BUTTON,
    onClick = props.onClick,
    onUpdate = function(self)
      local w, h = GuiText.getTextSize(textContent, guiTextBodyLayer.font)
      self.w, self.h = w, h
    end,
    draw = function(self)
      guiTextBodyLayer:addf(
        textContent,
        self.w,
        'left',
        self.x,
        self.y
      )
    end
  })
end

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
        width = 150,
        options = config.isDevelopment and sceneOptionsDebug or sceneOptionsNormal,
        onSelect = function(name, value)
          value()
        end,
        drawOrder = function()
          return drawOrder() + 2
        end
      })
      msgBus.send(msgBus.PLAY_GAME_MENU_TOGGLE)

      closeMenuButton({
        onClick = function()
          MenuManager.clearAll()
          DebugMenu(false)
        end
      }):setParent(self.activeSceneMenu)
    elseif self.activeSceneMenu then
      self.activeSceneMenu:delete(true)
      self.activeSceneMenu = nil
    end
    setState({ menuOpened = enabled })
  end

  -- load last active scene
  loadScene(state.activeScenePath)

  self.listeners = {
    msgBusMainMenu.on(msgBusMainMenu.TOGGLE_MAIN_MENU, function(enabled)
      if (enabled ~= nil) then
        local MenuManager = require 'modules.menu-manager'
        MenuManager.clearAll()
        DebugMenu(enabled)
      else
        DebugMenu(not state.menuOpened)
      end
      return state.menuOpened
    end, 1)
  }

  DebugMenu(true)
end

function Sandbox.update(self)
  if state.menuOpened then
    Component.addToGroup(self.activeSceneMenu, 'guiDrawBox')
  else
    Component.removeFromGroup(self.activeSceneMenu, 'guiDrawBox')
  end
end

function Sandbox.final(self)
  msgBusMainMenu.off(self.listeners)
end

return Component.createFactory(Sandbox)