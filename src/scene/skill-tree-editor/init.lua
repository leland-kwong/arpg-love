local SkillTreeEditor = require 'components.skill-tree-editor'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'

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

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    local pathToSave = love.filesystem.getSourceBaseDirectory()..'/src/scene/skill-tree-editor/serialized.lua'

    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = SkillTreeEditor,
      props = {
        nodes = loadState(pathToSave),
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
      }
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})