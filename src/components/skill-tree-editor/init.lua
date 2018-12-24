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
    backgroundImage = 'gui-skill-tree_node_background',
    description = function(self)
      return '+'..(self.value.value * 100)..'% attack speed'
    end
  },
  [2] = {
    name = 'bonus damage',
    value = {
      type = 'attackPower',
      value = 0.02
    },
    image = 'gui-skill-tree_node_damage-up',
    backgroundImage = 'gui-skill-tree_node_background',
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
    backgroundImage = 'gui-skill-tree_node_background',
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
    backgroundImage = 'gui-skill-tree_node_background',
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
    backgroundImage = 'gui-skill-tree_node_background',
    description = function(self)
      return '+'..(self.value.bonus * 100)..'% attack power for each 1% of health missing'
    end
  },
  [7] = {
    name = 'extra health',
    value = {
      type = 'maxHealth',
      value = 0.01
    },
    image = 'gui-skill-tree_node_max-health',
    backgroundImage = 'gui-skill-tree_node_background',
    description = function(self)
      return '+'..(self.value.value * 100)..'% maximum health'
    end
  },
  [8] = {
    name = 'extra energy',
    value = {
      type = 'maxEnergy',
      value = 0.01
    },
    image = 'gui-skill-tree_node_max-energy',
    backgroundImage = 'gui-skill-tree_node_background',
    description = function(self)
      return '+'..(self.value.value * 100)..'% maximum energy'
    end
  },
  [9] = {
    name = 'extra health and energy',
    value = {
      type = 'maxHealthEnergy',
      bonusHealth = 0.01,
      bonusEnergy = 0.01,
    },
    image = 'gui-skill-tree_node_max-health-energy',
    backgroundImage = 'gui-skill-tree_node_background',
    description = function(self)
      return '+'..(self.value.bonusHealth * 100)..'% maximum health\n+'..(self.value.bonusEnergy * 100)..'% maximum energy'
    end
  }
}

local EditorWithDefaults = Object.assign(SkillTreeEditor, {
  nodeValueOptions = nodeValueOptions,
  defaultNodeImage = 'gui-skill-tree_node_background',
  defaultNodeDescription = 'not implemented yet',
  colors = {
    nodeConnection = {
      inner = {Color.rgba255(217,217,217)},
      innerNonSelectable = {Color.multiplyAlpha(Color.MED_GRAY, 0.1)},
      outerNonSelectable = {Color.multiplyAlpha(Color.MED_GRAY, 0)},
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