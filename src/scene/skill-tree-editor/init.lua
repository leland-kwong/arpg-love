local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local SkillTreeEditor = require 'scene.skill-tree-editor.editor'

local nodeValueOptions = {
  [1] = {
    name = 'attack speed',
    value = 1
  },
  [2] = {
    name = 'bonus damage',
    value = 0.2
  }
}

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    local io = require 'io'
    local savedState = nil
    for line in io.lines(SkillTreeEditor.pathToSave) do
      savedState = (savedState or '')..line
    end

    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = SkillTreeEditor,
      props = {
        nodeValueOptions = nodeValueOptions,
        nodes = savedState and loadstring(savedState)()
      }
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})