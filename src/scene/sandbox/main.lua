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

local menuInputContext = 'MainMenu'

local drawOrder = function()
  return 1000
end

local guiTextBodyLayer = GuiText.create({
  font = font.primary.font,
  drawOrder = drawOrder
})

local titleFont = font.secondary.font
local guiTextTitleLayer = GuiText.create({
  font = titleFont,
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
    path = 'scene.sandbox.main-game.main-game-home'
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

local menuOptionSettingsMenu = {
  name = 'settings',
  value = function()
    local Position = require 'utils.position'
    local SettingsMenu = require 'scene.settings-menu'
    local vWidth, vHeight = love.graphics.getDimensions()
    local width, height = 240, 400
    local x = Position.boxCenterOffset(width, height, vWidth/2, vHeight/2)
    local menu = SettingsMenu.create({
      x = x,
      y = 60,
      width = width,
      height = height
    })
  end
}

local sceneOptionsNormal = {
  menuOptionSceneLoad(scenes.mainGameHome),
  menuOptionSettingsMenu,
  menuOptionQuitGame
}

local sceneOptionsDebug = {
  menuOptionSceneLoad(scenes.mainGameHome),
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

local function getMenuPosition()
  return 200, 20
end

local function closeMenuButton(props)
  local textContent = {
    Color.WHITE,
    'CLOSE'
  }
  local x, y = getMenuPosition()
  return Gui.create({
    x = x + 300,
    y = y,
    type = Gui.types.BUTTON,
    inputContext = menuInputContext,
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
  local InputContext = require 'modules.input-context'

  -- Wildcard context to match anything
  InputContext.set('any')

  local activeSceneMenu = nil

  local function DebugMenu(enabled)
    if enabled then
      InputContext.set(menuInputContext)
      local x, y = getMenuPosition()
      activeSceneMenu = MenuList.create({
        x = x,
        y = y,
        inputContext = menuInputContext,
        options = config.isDevelopment and sceneOptionsDebug or sceneOptionsNormal,
        onSelect = function(name, value)
          DebugMenu(false)
          value()
        end,
        drawOrder = function()
          return drawOrder() + 2
        end,
        final = function()
          InputContext.set('any')
        end
      })

      closeMenuButton({
        onClick = function()
          DebugMenu(false)
        end
      }):setParent(activeSceneMenu)
    elseif activeSceneMenu then
      activeSceneMenu:delete(true)
      activeSceneMenu = nil
    end
    setState({ menuOpened = enabled })
  end

  -- load last active scene
  loadScene(state.activeScenePath)

  self.listeners = {
    msgBusMainMenu.on(msgBusMainMenu.TOGGLE_MAIN_MENU, function()
      local MenuManager = require 'modules.menu-manager'
      if MenuManager.hasItems() then
        MenuManager.clearAll()
        return
      end

      DebugMenu(not state.menuOpened)
      return state.menuOpened
    end, 1)
  }
end

function Sandbox.draw()
  if state.menuOpened then
    local x, y = getMenuPosition()
    guiTextTitleLayer:add(config.gameTitle, Color.WHITE, x, y)
    -- background
    local w, h = love.graphics.getWidth() / config.scaleFactor, love.graphics.getHeight() / config.scaleFactor
    love.graphics.setColor(0,0,0,0.9)
    love.graphics.rectangle('fill', 0, 0, w, h)
  end
end

function Sandbox.final(self)
  msgBusMainMenu.off(self.listeners)
end

return Component.createFactory(Sandbox)