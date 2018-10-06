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

local stateFile = 'debug_scene_state'
local state = {
  activeScene = nil,
  activeScenePath = nil,
  menuOpened = false
}
-- reference to the loaded scene so we can cleanup when loading a new one
local loadedScene = nil

local function setState(nextState)
  objectUtils.assign(state, nextState)
  bitser.dumpLoveFile(stateFile, state)
end

local function loadScene(name, path, sceneProps)
  if not path then
    print('no scene to load')
    return
  end
  local scene = require(path)
  msgBus.send(msgBus.SCENE_STACK_PUSH, {
    scene = scene,
    props = sceneProps
  })
  setState({
    activeScene = name,
    activeScenePath = path
  })
end

local function DebugMenuToggleButton(onToggle)
  local buttonText = 'debug'
  local buttonWidth, buttonHeight = GuiText.getTextSize(buttonText, guiTextBodyLayer.font)
  local screenOffset = 5
  local screenEastEdge = love.graphics.getWidth() / config.scaleFactor
  local screenSouthEdge = love.graphics.getHeight() / config.scaleFactor
  return Gui.create({
    type = Gui.types.BUTTON,
    x = screenOffset,
    y = screenSouthEdge - screenOffset - buttonHeight,
    w = buttonWidth,
    h = buttonHeight,
    onClick = function()
      onToggle()
    end,
    draw = function(self)
      guiTextBodyLayer:add(buttonText, Color.WHITE, self.x, self.y)
    end,
    drawOrder = drawOrder
  })
end

local function menuOptionSceneLoad(name, path, props)
  return {
    name = name,
    props = props,
    value = function()
      loadScene(name, path)
    end
  }
end

local sceneOptions = {
  menuOptionSceneLoad(
    'main game home screen',
    'scene.sandbox.main-game.main-game-home'
  ),
  {
    name = 'main game sandbox',
    value = function()
      local msgBus = require 'components.msg-bus'
      local CreateStore = require 'components.state.state'
      msgBus.send(msgBus.GAME_STATE_SET, CreateStore(nil, {id = 'test-state'}))
      loadScene('main game sandbox', 'scene.sandbox.main-game.main-game-test')
    end
  },
  menuOptionSceneLoad(
    'sprite positioning',
    'scene.sandbox.sprite-positioning'
  ),
  menuOptionSceneLoad(
    'ai',
    'scene.sandbox.ai.test-scene'
  ),
  menuOptionSceneLoad(
    'gui',
    'scene.sandbox.gui.test-scene'
  ),
  menuOptionSceneLoad(
    'particle fx',
    'scene.sandbox.particle-fx.particle-test'
  ),
  menuOptionSceneLoad(
    'ground flame fx',
    'scene.sandbox.particle-fx.ground-flame-test'
  ),
  {
    name = 'exit game',
    value = function()
      love.event.quit()
    end
  }
}

msgBusMainMenu.on(msgBusMainMenu.MENU_ITEM_ADD, function(menuOption)
  table.insert(sceneOptions, 1, menuOption)
end)

msgBusMainMenu.on(msgBusMainMenu.MENU_ITEM_REMOVE, function(menuOption)
  for i=1, #sceneOptions do
    local option= sceneOptions[i]
    if option == menuOption then
      table.remove(sceneOptions, i)
    end
  end
end)

require 'scene.light-test'
require 'scene.font-test'
require 'scene.tooltip-test'

local menuX, menuY = 200, 20

function Sandbox.init(self)
  local activeSceneMenu = nil

  local function DebugMenu(enabled)
    if enabled then
      activeSceneMenu = MenuList.create({
        x = menuX,
        y = menuY,
        options = sceneOptions,
        onSelect = function(name, value)
          DebugMenu(false)
          value()
        end,
        drawOrder = function()
          return drawOrder() + 2
        end
      })
    elseif activeSceneMenu then
      activeSceneMenu:delete(true)
      activeSceneMenu = nil
    end
    setState({ menuOpened = enabled })
end

  local errorFree, loadedState = pcall(function() return bitser.loadLoveFile(stateFile) end)
  state = (errorFree and loadedState) or state

  DebugMenu(state.menuOpened)

  -- load last active scene
  loadScene(state.activeScene, state.activeScenePath)

  -- -- load menu if no active scene exists
  if not state.activeScene then
    DebugMenu(true)
  end

  DebugMenuToggleButton(function()
    DebugMenu(not state.menuOpened)
  end)

  self.listeners = {
    msgBusMainMenu.on(msgBusMainMenu.TOGGLE_MAIN_MENU, function()
      DebugMenu(not state.menuOpened)
    end)
  }
end

function Sandbox.draw()
  if state.menuOpened then
    guiTextTitleLayer:add('Sandbox scenes', Color.WHITE, menuX, menuY)
    -- background
    local w, h = love.graphics.getWidth() / config.scaleFactor, love.graphics.getHeight() / config.scaleFactor
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle('fill', 0, 0, w, h)
  end
end

function Sandbox.final(self)
  msgBusMainMenu.off(self.listeners)
end

return Component.createFactory(Sandbox)