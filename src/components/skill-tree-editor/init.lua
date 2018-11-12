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

local function loadState(pathToSave)
  local io = require 'io'
  local savedState = nil
  for line in io.lines(pathToSave) do
    savedState = (savedState or '')..line
  end

  -- IMPORTANT: In lua, key insertion order affects the order of serialization. So we should sort the keys to make sure it is deterministic.
  return (
    savedState and loadstring(savedState)() or {}
  )
end

return Component.createFactory({
  init = function(self)
    local Object = require 'utils.object-utils'
    local pathToSave = self.pathToSave or
      love.filesystem.getSourceBaseDirectory()..'/src/scene/skill-tree-editor/serialized.lua'

    SkillTreeEditor.create(Object.assign({
      nodeValueOptions = nodeValueOptions,
      defaultNodeImage = 'gui-skill-tree_node_background',
      defaultNodeDescription = 'not implemented yet',
      nodes = loadState(pathToSave),
      colors = {
        nodeConnection = {
          outer = Color.SKY_BLUE,
          outerNonSelectable = Color.MED_DARK_GRAY,
          inner = {Color.multiplyAlpha(Color.DARK_GRAY, 0.7)}
        }
      },
      onSerialize = function(serializedTreeAsString)
        local io = require 'io'
        local f = assert(io.open(pathToSave, 'w'))
        local success, message = f:write(serializedTreeAsString)
        f:close()
        if success then
          msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
            title = '[SKILL TREE] state saved',
          })
        else
          error(message)
        end
      end
    }, self.initialProps)):setParent(self)
  end
})