local Component = require 'modules.component'
local SkillTreeEditor = require 'components.skill-tree-editor'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'

local skillTreeId = 'passiveSkillsTree'

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

local function editorModesToggleButtons()
  local buttons = {}
  local modes = {'PLAY', 'PLAY_READ_ONLY', 'EDIT'}
  local F = require 'utils.functional'
  F.forEach(modes, function(mode, index)
    Component.create({
      init = function(self)
        local Gui = require 'components.gui.gui'
        local GuiText = require 'components.gui.gui-text'
        local config = require 'config.config'
        local guiTextRegular = GuiText.create({
          font = require 'components.font'.primary.font
        })
        local button = Gui.create({
          type = Gui.types.INTERACT,
          x = 0,
          y = love.graphics.getHeight() / config.scale - 50,
          onClick = function()
            Component.get(skillTreeId).editorMode = mode
          end,
          onUpdate = function(self)
            self.width, self.height = guiTextRegular.getTextSize(mode, guiTextRegular.font)

            local previousButton = buttons[index - 1]
            local btnMargin = 10
            local xPosition = (previousButton and (previousButton.x + previousButton.w + btnMargin) or 200)
            self.x = xPosition
          end,
          draw = function(self)
            local Color = require 'modules.color'
            local isSelected = Component.get(skillTreeId).editorMode == mode
            local color = isSelected and Color.WHITE or Color.MED_GRAY
            guiTextRegular:add(mode, color, self.x, self.y)
          end
        })
        table.insert(buttons, button)
      end
    }):setParent(Component.get(skillTreeId))
  end)
end

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    local pathToSave = love.filesystem.getSourceBaseDirectory()..'/src/scene/skill-tree-editor/serialized.lua'

    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = SkillTreeEditor,
      props = {
        id = skillTreeId,
        editorMode = 'EDIT',
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

    editorModesToggleButtons()
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})