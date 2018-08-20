local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local font = require 'components.font'
local SceneMenu = require 'scene.scene-menu'
local Component = require 'modules.component'
local groups = require 'components.groups'
local config = require 'config'
local objectUtils = require 'utils.object-utils'
local bitser = require 'modules.bitser'

local guiTextBodyLayer = GuiText.create({
  font = font.primary.font
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
  if loadedScene then
    loadedScene:delete(true)
  end
  loadedScene = scene.create()
  setState({ activeScene = name })
end

local function drawOrder(self)
  return 11
end

local function DebugMenuToggleButton(onToggle)
  local buttonText = 'debug'
  local buttonWidth, buttonHeight = GuiText.getTextSize(buttonText, guiTextBodyLayer.font)
  local screenOffset = 10
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

local scenes = {
  ['main game'] = 'scene.sandbox.main-game.main-game-test',
  ['sprite positioning'] = 'scene.sandbox.sprite-positioning',
  ai = 'scene.sandbox.ai.test-scene',
  gui = 'scene.sandbox.gui.test-scene',
  ['particle fx'] = 'scene.sandbox.particle-fx.particle-test',
}

function Sandbox.init()
  local activeSceneMenu = nil

  local function DebugMenu(enabled)
    if enabled then
      activeSceneMenu = SceneMenu.create({
        scenes = scenes,
        onSelect = function(name, path)
          loadScene(name, path)
          DebugMenu(false)
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

  local scenePath = scenes[state.activeScene]
  loadScene(state.activeScene, scenePath)

  -- -- load menu if no active scene exists
  if not state.activeScene then
    DebugMenu(true)
  end

  DebugMenuToggleButton(function()
    DebugMenu(not state.menuOpened)
  end)
end

function Sandbox.draw()
  if state.menuOpened then
    -- background
    local w, h = love.graphics.getWidth() / config.scaleFactor, love.graphics.getHeight() / config.scaleFactor
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle('fill', 0, 0, w, h)
  end
end

return Component.createFactory(Sandbox)