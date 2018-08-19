local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Component = require 'modules.component'
local groups = require 'components.groups'
local f = require 'utils.functional'
local objectUtils = require 'utils.object-utils'
local font = require 'components.font'
local Color = require 'modules.color'
local Position = require 'utils.position'
local config = require 'config'
local bitser = require 'modules.bitser'

local SandboxSceneSelection = {
  x = 200,
  y = 20,
  group = groups.gui,
  -- table of scene paths that we can require
  scenes = {
    sceneName = 'scene_path'
  }
}

local itemFont = font.primary.font
local titleFont = font.secondary.font
local guiTextBodyLayer = GuiText.create({
  font = itemFont
})
local guiTextTitleLayer = GuiText.create({
  font = titleFont
})

local stateFile = 'debug_scene_state'
local state = {
  activeScene = nil
}

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
  scene.create()
  setState({ activeScene = name })
end

function SandboxSceneSelection.init(self)
  local errorFree, loadedState = pcall(function() return bitser.loadLoveFile(stateFile) end)
  state = (errorFree and loadedState) or state

  local scenePath = self.scenes[state.activeScene]
  loadScene(state.activeScene, scenePath)

  local menuX = self.x
  local menuY = self.y
  local sceneNames = f.keys(self.scenes)
  local startYOffset = 10
  local menuWidth = math.max(
    unpack(
      f.map(sceneNames, function(name)
        return GuiText.getTextSize(name, itemFont)
      end)
    )
  )

  -- menu option gui nodes
  local menuOptions = f.map(sceneNames, function(name, i)
    local scenePath = self.scenes[name]
    local textW, textH = GuiText.getTextSize(scenePath, itemFont)
    local lineHeight = 1.8
    local h = (textH * lineHeight)
    return Gui.create({
      x = menuX,
      y = i * h + menuY + startYOffset,
      w = menuWidth,
      h = h,
      type = Gui.types.BUTTON,
      onClick = function()
        loadScene(name, scenePath)
      end,
      draw = function(self)
        if self.hovered then
          local sidePadding = 5
          love.graphics.setColor(1,1,1,0.5)
          local w = self.w + (sidePadding * 2)
          love.graphics.rectangle('fill', self.x - sidePadding, self.y - self.h/4, w, self.h)
        end
        guiTextBodyLayer:add(name, Color.WHITE, self.x, self.y)
      end
    })
  end)
end

function SandboxSceneSelection.draw(self)
  guiTextTitleLayer:add('Sandbox scenes', Color.WHITE, self.x, self.y)
end

return Component.createFactory(SandboxSceneSelection)