local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local SkillTreeEditor = require 'scene.skill-tree-editor.editor'
local Color = require 'modules.color'

local nodeValueOptions = {
  [1] = {
    name = 'attack speed',
    value = 1,
    image = 'gui-skill-tree_node_speed-up',
    description = function(self)
      return '+'..self.value..'% attack speed'
    end
  },
  [2] = {
    name = 'bonus damage',
    value = 0.2,
    image = 'gui-skill-tree_node_damage-up',
    description = function(self)
      return '+'..self.value..'% damage'
    end
  },
  [3] = {
    name = 'lightning rod',
    value = 0.1,
    type = 'keystone',
    image = 'gui-skill-tree_node_lightning',
    description = function(self)
      return '+'..(self.value * 100)..'% chance lightning damage'
    end
  },
  [4] = {
    name = 'battle suit',
    value = 0,
    type = 'dummyNode',
    description = function()
      return 'Battle suit'
    end
  }
}

local Scene = {}

function Scene.init(self)
  SkillTreeEditor.create(self.initialProps)
end

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Component.createFactory(Scene),
      props = {
        nodeValueOptions = nodeValueOptions,
        defaultNodeImage = 'gui-skill-tree_node_background',
        defaultNodeDescription = 'not implemented yet',
        nodes = SkillTreeEditor.loadState(),
        colors = {
          nodeConnection = {
            outer = Color.SKY_BLUE,
            outerNonSelectable = Color.MED_DARK_GRAY,
            inner = {Color.multiplyAlpha(Color.DARK_GRAY, 0.7)}
          }
        }
      }
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})