local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local SkillTreeEditor = require 'components.skill-tree-editor.editor'
local Color = require 'modules.color'
local Object = require 'utils.object-utils'

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
      type = 'lightningRod',
      value = 0.1
    },
    type = 'keystone',
    image = 'gui-skill-tree_node_lightning',
    description = function(self)
      return '+'..(self.value.value * 100)..'% damage as lightning damage'
    end
  },
  [4] = {
    name = 'battle suit',
    value = {
      value = 0,
      type = 'dummyNode',
    },
    readOnly = true,
    description = function()
      return 'Battle suit'
    end
  },
  [5] = {
    name = 'heavy strike',
    value = {
      type = 'heavyStrike',
      value = 0.5
    },
    image = 'gui-skill-tree_node_heavy-strike',
    description = function(self)
      return 'every third hit deals +'..(self.value.value * 100)..'% bonus damage'
    end
  },
  [6] = {
    name = 'blood rage',
    value = {
      type = 'bloodRage',
      -- bonuse per percentage of health missing
      bonus = 0.005,
    },
    image = 'gui-skill-tree_node_blood-rage',
    description = function(self)
      return 'gain '..(self.value.bonus * 100)..'% damage for each 1% of missing health'
    end
  }
}

local EditorWithDefaults = Object.assign(SkillTreeEditor, {
  nodeValueOptions = nodeValueOptions,
  defaultNodeImage = 'gui-skill-tree_node_background',
  defaultNodeDescription = 'not implemented yet',
  colors = {
    nodeConnection = {
      inner = Color.SKY_BLUE,
      innerNonSelectable = {Color.multiplyAlpha(Color.SKY_BLUE, 0.1)},
      outerNonSelectable = {Color.multiplyAlpha(Color.SKY_BLUE, 0)},
      outer = {Color.multiplyAlpha(Color.SKY_BLUE, 0.2)}
    }
  },
  parseTreeData = function(treeData)
    local parsedData = {}
    for nodeId,node in pairs(treeData) do
      local nodeValue = node.nodeValue
      local nodeData = nodeValueOptions[nodeValue]
      if node.selected and (not nodeData.readOnly) then
        parsedData[nodeId] = nodeData
      end
    end
    return parsedData
  end
})

return Component.createFactory(EditorWithDefaults)