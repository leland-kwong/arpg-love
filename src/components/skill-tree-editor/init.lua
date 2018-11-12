local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local SkillTreeEditor = require 'components.skill-tree-editor.editor'
local Color = require 'modules.color'

local nodeValueOptions = {
  [1] = {
    name = 'attack speed',
    value = {
      type = 'attackTimeReduction',
      value = 0.01
    },
    image = 'gui-skill-tree_node_speed-up',
    description = function(self)
      return '+'..(self.value.value * 100)..'% attack speed'
    end
  },
  [2] = {
    name = 'bonus damage',
    value = {
      type = 'percentDamage',
      value = 0.02
    },
    image = 'gui-skill-tree_node_damage-up',
    description = function(self)
      return '+'..(self.value.value * 100)..'% damage'
    end
  },
  [3] = {
    name = 'lightning rod',
    value = {
      type = 'lightningDamage',
      value = 0.1
    },
    type = 'keystone',
    image = 'gui-skill-tree_node_lightning',
    description = function(self)
      return '+'..(self.value.value * 100)..'% chance lightning damage'
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

return Component.createFactory({
  init = function(self)
    local Object = require 'utils.object-utils'

    SkillTreeEditor.create(Object.assign({
      nodeValueOptions = nodeValueOptions,
      defaultNodeImage = 'gui-skill-tree_node_background',
      defaultNodeDescription = 'not implemented yet',
      nodes = self.nodes,
      colors = {
        nodeConnection = {
          outer = Color.SKY_BLUE,
          outerNonSelectable = Color.MED_DARK_GRAY,
          inner = {Color.multiplyAlpha(Color.DARK_GRAY, 0.7)}
        }
      },
      onSerialize = self.onSerialize
    }, self.initialProps)):setParent(self)
  end
})