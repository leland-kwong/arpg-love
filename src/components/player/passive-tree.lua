local Component = require 'modules.component'
local Color = require 'modules.color'
local config = require 'config.config'
local MenuManager = require 'modules.menu-manager'

local PassiveTree = {}

local rootDir = 'passive-tree-states'

function PassiveTree.getState(saveDir)
  local fs = require 'modules.file-system'
  return fs.loadSaveFile(rootDir, saveDir)
end

function PassiveTree.toggle()
  if Component.get('passiveSkillsTree') then
    MenuManager.clearAll()
    return
  end

  local gameState = require 'main.global-state'.gameState
  local SkillTreeEditor = require 'components.skill-tree-editor'
  local fs = require 'modules.file-system'
  local saveDir = gameState:getId()
  local nodesFromSavedState, ok = PassiveTree.getState(saveDir)
  local actualPointsRemaining = 0
  local editor = SkillTreeEditor.create({
    id = 'passiveSkillsTree',
    editorMode = 'PLAY_READ_ONLY',
    nodes = ok and nodesFromSavedState or nil,
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