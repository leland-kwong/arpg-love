local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local SkillTreeEditor = require 'scene.skill-tree-editor.editor'
local SkillTree = require 'components.skill-tree'

local nodeValueOptions = {
  [1] = {
    name = 'attack speed',
    value = 1
  },
  [2] = {
    name = 'bonus damage',
    value = 0.2
  },
  [3] = {
    name = 'lightning rod',
    value = 'lightning damage'
  }
}

local Scene = {}

function Scene.init(self)
  SkillTreeEditor.create(self.initialProps)

  Component.create({
    init = function(self)
      local Gui = require 'components.gui.gui'
      local GuiText = require 'components.gui.gui-text'
      local config = require 'config.config'
      local Enum = require 'utils.enum'
      local modes = Enum({
        'EDIT',
        'DEMO'
      })
      local editorMode = modes.EDIT
      local guiTextRegular = GuiText.create({
        font = require 'components.font'.primary.font
      })
      Gui.create({
        type = Gui.types.INTERACT,
        x = 200,
        y = love.graphics.getHeight() / config.scale - 50,
        onClick = function()
          editorMode = (editorMode == modes.EDIT) and modes.DEMO or modes.EDIT

          if modes.DEMO == editorMode then
            SkillTree.create({
              id = 'skillTree'
            })
          else
            local skillTree = Component.get('skillTree')
            if skillTree then
              skillTree:delete(true)
            end
          end
        end,
        onUpdate = function(self)
          self.width, self.height = guiTextRegular.getTextSize(editorMode, guiTextRegular.font)
        end,
        draw = function(self)
          local Color = require 'modules.color'
          guiTextRegular:add(editorMode, Color.WHITE, self.x, self.y)
        end
      })
    end
  })
end

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Component.createFactory(Scene),
      props = {
        nodeValueOptions = nodeValueOptions,
        nodes = SkillTreeEditor.loadState()
      }
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})