local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local font = require 'components.font'
local MenuList = require 'components.menu-list'
local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local config = require 'config.config'
local objectUtils = require 'utils.object-utils'
local bitser = require 'modules.bitser'

local guiTextBodyLayer = GuiText.create({
  font = font.primary.font
})

local titleFont = font.secondary.font
local guiTextTitleLayer = GuiText.create({
  font = titleFont
})

local Sandbox = {
  group = groups.gui,
  drawOrder = function()
    return 4
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

local function loadScene(name, path)
  if not path then
    print('no scene to load')
    return
  end
  local scene = require(path)
  msgBusMainMenu.send(msgBusMainMenu.SCENE_SWITCH, { scene = scene })
  setState({
    activeScene = name,
    activeScenePath = path
  })
end

local function drawOrder(self)
  return 11
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

local function menuOptionSceneLoad(name, path)
  return {
    name = name,
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
  menuOptionSceneLoad(
    'main game sandbox',
    'scene.sandbox.main-game.main-game-test'
  ),
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
  {
    name = 'exit game',
    value = function()
      love.event.quit()
    end
  }
}

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
        drawOrder = drawOrder
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

  msgBusMainMenu.subscribe(function(msgType, msgValue)
    if self:isDeleted() then
      return msgBusMainMenu.CLEANUP
    end

    if msgBusMainMenu.TOGGLE_MAIN_MENU == msgType then
      DebugMenu(not state.menuOpened)
    end
  end)
end

function Sandbox.draw()
  if state.menuOpened then
    guiTextTitleLayer:add('Sandbox scenes', Color.WHITE, menuX, menuY)
    -- background
    local w, h = love.graphics.getWidth() / config.scaleFactor, love.graphics.getHeight() / config.scaleFactor
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle('fill', 0, 0, w, h)
  end
end

return Component.createFactory(Sandbox)