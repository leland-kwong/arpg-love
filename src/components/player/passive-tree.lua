local Component = require 'modules.component'
local Color = require 'modules.color'
local config = require 'config.config'
local MenuManager = require 'modules.menu-manager'
local SkillTreeEditor = require 'components.skill-tree-editor'
local msgBus = require 'components.msg-bus'
local memoize = require 'utils.memoize'

local onHitModifiers = {}

msgBus.on(msgBus.CHARACTER_HIT, function(msg)
  for _,handler in pairs(onHitModifiers) do
    handler(msg)
  end
  return msg
end)

local modifierHandlers = {
  lightningRod = function(nodeId, data, modifiers)
    onHitModifiers[nodeId] = function(hitMsg)
      consoleLog('trigger lightning', data.value.value, Time())
    end
    return modifiers
  end,
  dummyNode = function(_, _, modifiers)
    return modifiers
  end,
  statModifier = function(nodeId, data, modifiers)
    local dataType = data.value.type
    local currentValue = (modifiers[dataType] or 0)
    modifiers[dataType] = currentValue + data.value.value
    return modifiers
  end
}

local PassiveTree = {}

local rootDir = 'passive-tree-states'

function PassiveTree.getState(saveDir)
  local fs = require 'modules.file-system'
  local result, ok = fs.loadSaveFile(rootDir, saveDir)
  return ok and result or nil
end

local calcModifiers = memoize(function(treeData)
  onHitModifiers = {}

  local nodeData = SkillTreeEditor.parseTreeData(treeData)
  local modifiers = {}
  for nodeId,data in pairs(nodeData) do
    local dataType = data.value.type
    local modifierFunc = modifierHandlers[dataType] or
      modifierHandlers.statModifier
    modifierFunc(nodeId, data, modifiers)
  end
  return modifiers
end)

function PassiveTree.calcModifiers()
  local gameState = require 'main.global-state'.gameState
  local saveDir = gameState:getId()
  local treeData = PassiveTree.getState(saveDir)
  return calcModifiers(treeData)
end

function PassiveTree.toggle()
  if Component.get('passiveSkillsTree') then
    MenuManager.clearAll()
    return
  end

  local gameState = require 'main.global-state'.gameState
  local fs = require 'modules.file-system'
  local saveDir = gameState:getId()
  local nodesFromSavedState = PassiveTree.getState(saveDir)
  local actualPointsRemaining = 0
  local editor = SkillTreeEditor.create({
    id = 'passiveSkillsTree',
    editorMode = 'PLAY_READ_ONLY',
    nodes = nodesFromSavedState,
    onChange = function(self)
      local gameState = require 'main.global-state'.gameState
      local totalSkillPointsAvailable = gameState:get().level
      actualPointsRemaining = totalSkillPointsAvailable
      for _,data in pairs(self.nodes) do
        if data.selected then
          actualPointsRemaining = actualPointsRemaining - 1
        end
      end
      self.editorMode = actualPointsRemaining > 0 and
        'PLAY' or
        'PLAY_UNSELECT_ONLY'
    end,
    onSerialize = function(serializedString, serialized)
      fs.saveFile(rootDir, saveDir, serialized)
        :next(function()
          msgBus.send(msgBus.PLAYER_STATS_NEW_MODIFIERS)
        end)
    end
  }):setParent(
    Component.get('HUD')
  )
  Component.create({
    init = function(self)
      Component.addToGroup(self, 'gui')
    end,
    draw = function(self)
      local font = require 'components.font'.primary.font
      love.graphics.setColor(1,1,1)
      love.graphics.setFont(font)
      local text = {
        Color.WHITE,
        actualPointsRemaining,
        Color.WHITE,
        ' points left',
      }
      local GuiText = require 'components.gui.gui-text'
      local Position = require 'utils.position'
      local textWidth, textHeight = GuiText.getTextSize(text, font)
      local vWidth, vHeight = love.graphics.getWidth()/config.scale,
        love.graphics.getHeight()/config.scale
      local x = Position.boxCenterOffset(textWidth, textHeight, vWidth, vHeight)
      love.graphics.printf(
        text,
        x,
        20,
        200
      )
    end,
    drawOrder = function()
      return editor:drawOrder() + 1
    end
  }):setParent(editor)
  local msgBusMainMenu = require 'components.msg-bus-main-menu'
  msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  MenuManager.clearAll()
  MenuManager.push(editor)
end

return PassiveTree