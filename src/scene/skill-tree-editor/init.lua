local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local SkillTreeEditor = require 'scene.skill-tree-editor.editor'
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

local Scene = {}

function Scene.init(self)
  SkillTreeEditor.create(self.initialProps)
end

local function sortKeys(val)
  if type(val) ~= 'table' then
    return val
  end

  local newTable = {}
  local keys = {}
  for k in pairs(val) do
    table.insert(keys, k)
  end
  table.sort(keys)

  for i=1, #keys do
    local key = keys[i]
    newTable[key] = sortKeys(val[key])
  end

  return newTable
end

local function loadState(pathToSave)
  local io = require 'io'
  local savedState = nil
  for line in io.lines(pathToSave) do
    savedState = (savedState or '')..line
  end

  -- IMPORTANT: In lua, key insertion order affects the order of serialization. So we should sort the keys to make sure it is deterministic.
  return sortKeys(
    savedState and loadstring(savedState)() or {}
  )
end

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    local sourceDirectory = love.filesystem.getSourceBaseDirectory()
    local pathToSave = sourceDirectory..'/src/scene/skill-tree-editor/serialized.lua'

    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Component.createFactory(Scene),
      props = {
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
        serialize = function(self)
          local ser = require 'utils.ser'
          local serializedTree = {}
          for nodeId in pairs(self.nodes) do
            local node = Component.get(nodeId)
            serializedTree[nodeId] = node:serialize()
          end

          --[[
            Love's `love.filesystem.write` doesn't support writing to files in the source directory,
            therefore we must use the `io` module.
          ]]
          local io = require 'io'
          local f = assert(io.open(pathToSave, 'w'))
          local success, message = f:write(
            ser(serializedTree)
          )
          if success then
            f:close()
            msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
              title = '[SKILL TREE] state saved',
            })
          else
            error(message)
          end
        end
      }
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})