local Component = require 'modules.component'
local Color = require 'modules.color'
local config = require 'config.config'
local MenuManager = require 'modules.menu-manager'
local SkillTreeEditor = require 'components.skill-tree-editor'
local msgBus = require 'components.msg-bus'
local memoize = require 'utils.memoize'

local onHitModifiers = {}
local updateModifiers = {}

msgBus.on(msgBus.CHARACTER_HIT, function(msg)
  if msg.itemSource then
    for _,handler in pairs(onHitModifiers) do
      handler(msg)
    end
  end
  return msg
end, 2)

msgBus.on(msgBus.UPDATE, function(dt)
  for _,handler in pairs(updateModifiers) do
    handler(dt)
  end
end)

local modifierHandlers = {
  lightningRod = function(nodeId, data, modifiers)
    onHitModifiers[nodeId] = function(hitMsg)
      msgBus.send(msgBus.CHARACTER_HIT, {
        parent = hitMsg.parent,
        duration = 0.5,
        modifiers = {
          shocked = 1
        },
        source = 'INITIATE_SHOCK'
      })
      local multiplier = data.value.value
      hitMsg.lightningDamage = hitMsg.lightningDamage + (multiplier * hitMsg.damage)
    end
    return modifiers
  end,
  bloodRage = function(nodeId, data, modifiers)
    Component.get('PLAYER'):addFunctionalMod('percentDamage', function()
      local gameState = require 'main.global-state'.gameState:get()
      local currentMods = gameState.statModifiers
      local percentHealthMissing = 1 - gameState.health / gameState.maxHealth
      return data.value.bonus * percentHealthMissing * 100
    end)
    return modifiers
  end,
  heavyStrike = function(nodeId, data, modifiers)
    local hitCount = 0
    local hitSources = {}
    onHitModifiers[nodeId] = function(hitMsg)
      local isNewSource = not hitSources[hitMsg.source]
      if isNewSource then
        hitCount = hitCount + 1
        if hitCount > 3 then
          hitCount = 1
          hitSources = {}
        end
        hitSources[hitMsg.source] = true
      end
      local isBigHit = hitCount >= 3
      if isBigHit then
        local percentBonusDamage = data.value.value
        hitMsg.criticalChance = 1
        hitMsg.criticalMultiplier = (hitMsg.criticalMultiplier or 0) + percentBonusDamage
      end
    end
    local uid = require 'utils.uid'
    local iconId = uid()
    updateModifiers[nodeId] = function(dt)
      Component.addToGroup(iconId, 'hudStatusIcons', {
        text = hitCount,
        icon = 'gui-skill-tree_node_heavy-strike'
      })
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

local calcModifiers = function(treeData)
  onHitModifiers = {}
  updateModifiers = {}

  local nodeData = SkillTreeEditor.parseTreeData(treeData)
  local modifiers = {}
  for nodeId,data in pairs(nodeData) do
    local dataType = data.value.type
    local modifierFunc = modifierHandlers[dataType] or
      modifierHandlers.statModifier
    modifierFunc(nodeId, data, modifiers)
  end
  return modifiers
end

function PassiveTree.calcModifiers()
  local gameState = require 'main.global-state'.gameState
  local saveDir = gameState:getId()
  local treeData = PassiveTree.getState(saveDir)
  return calcModifiers(treeData or {})
end

local getUnusedSkillPoints = memoize(function(treeData, totalSkillPointsAvailable)
  local nodeData = SkillTreeEditor.parseTreeData(treeData)
  local unusedSkillPoints = totalSkillPointsAvailable
  for _ in pairs(nodeData) do
    unusedSkillPoints = unusedSkillPoints - 1
  end
  return unusedSkillPoints
end)

function PassiveTree.getUnusedSkillPoints(treeData)
  local gameState = require 'main.global-state'.gameState
  local saveDir = gameState:getId()
  treeData = treeData or PassiveTree.getState(saveDir)
  local gameState = require 'main.global-state'.gameState
  -- start out with zero skill points at level 1
  local totalSkillPointsAvailable = gameState:get().level - 1
  return getUnusedSkillPoints(treeData or {}, totalSkillPointsAvailable)
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
  local editor = SkillTreeEditor.create({
    id = 'passiveSkillsTree',
    editorMode = 'PLAY_READ_ONLY',
    nodes = nodesFromSavedState,
    --[[
      NOTE: we need to update editor mode during both `onChange` and `onSerialize`
      since onSerialize is async which means there could be new changes that have
      not been saved yet.
    ]]
    onChange = function(self)
      self.editorMode = PassiveTree.getUnusedSkillPoints() > 0 and
        'PLAY' or
        'PLAY_UNSELECT_ONLY'
    end,
    onSerialize = function(self, serializedString, serialized)
      self.editorMode = PassiveTree.getUnusedSkillPoints(serialized) > 0 and
        'PLAY' or
        'PLAY_UNSELECT_ONLY'
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
        PassiveTree.getUnusedSkillPoints(),
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